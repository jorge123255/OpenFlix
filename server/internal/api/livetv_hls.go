package api

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// hlsSegmentTargetBytes is the target size for each HLS segment.
// At 4 Mbps (typical live TV), 512 KB ≈ ~1 second.
// Smaller segments mean VLC gets fresh data more frequently and is less
// likely to stall waiting for the next chunk.
const (
	hlsSegmentTargetBytes = 512 * 1024 // 512 KB (~1s at 4 Mbps, ~0.5s at 8 Mbps)
	hlsRingSize           = 16         // keep 16 segments in memory
	hlsTargetDuration     = 3          // EXT-X-TARGETDURATION in seconds
	hlsSegmentDuration    = "1.0"      // EXTINF value (approximate)
	hlsReadySegments      = 1          // serve after first segment is ready
)

// hlsSegment holds a single TS segment.
type hlsSegment struct {
	data []byte
	seq  int
}

// hlsSession manages the background MPEG-TS → HLS segmenter for one channel.
type hlsSession struct {
	mu       sync.RWMutex
	ring     [hlsRingSize]*hlsSegment
	writeIdx int // next write position (absolute)
	minSeq   int // lowest seq# currently in ring
	maxSeq   int // highest seq# currently in ring (-1 if empty)

	readyCh  chan struct{}
	doneOnce sync.Once
	cancel   context.CancelFunc
	active   bool
}

var (
	hlsSessions   = make(map[uint]*hlsSession)
	hlsSessionsMu sync.RWMutex
)

// getOrStartHLSSession returns an existing session or starts a new one.
func getOrStartHLSSession(channelID uint, streamURL string) *hlsSession {
	hlsSessionsMu.Lock()
	defer hlsSessionsMu.Unlock()

	if sess, ok := hlsSessions[channelID]; ok {
		sess.mu.RLock()
		active := sess.active
		sess.mu.RUnlock()
		if active {
			return sess
		}
	}

	ctx, cancel := context.WithCancel(context.Background())
	sess := &hlsSession{
		readyCh: make(chan struct{}),
		cancel:  cancel,
		active:  true,
		maxSeq:  -1,
	}
	hlsSessions[channelID] = sess
	go sess.run(ctx, streamURL)
	return sess
}

func (s *hlsSession) run(ctx context.Context, streamURL string) {
	defer func() {
		s.mu.Lock()
		s.active = false
		s.mu.Unlock()
	}()

	client := &http.Client{Timeout: 0}

	for {
		if ctx.Err() != nil {
			return
		}

		req, err := http.NewRequestWithContext(ctx, "GET", streamURL, nil)
		if err != nil {
			return
		}

		resp, err := client.Do(req)
		if err != nil {
			time.Sleep(2 * time.Second)
			continue
		}

		s.readIntoSegments(resp, ctx)
		resp.Body.Close()

		if ctx.Err() != nil {
			return
		}
		time.Sleep(500 * time.Millisecond)
	}
}

func (s *hlsSession) readIntoSegments(resp *http.Response, ctx context.Context) {
	buf := make([]byte, 0, hlsSegmentTargetBytes+32*1024)
	tmp := make([]byte, 32*1024)

	for {
		if ctx.Err() != nil {
			return
		}

		n, err := resp.Body.Read(tmp)
		if n > 0 {
			buf = append(buf, tmp[:n]...)

			if len(buf) >= hlsSegmentTargetBytes {
				// Cut at 188-byte TS packet boundary
				aligned := (len(buf) / 188) * 188
				if aligned == 0 {
					aligned = len(buf)
				}
				seg := make([]byte, aligned)
				copy(seg, buf[:aligned])
				buf = buf[aligned:]
				s.addSegment(seg)
			}
		}
		if err != nil {
			return
		}
	}
}

func (s *hlsSession) addSegment(data []byte) {
	s.mu.Lock()
	seq := s.writeIdx
	s.ring[seq%hlsRingSize] = &hlsSegment{data: data, seq: seq}
	s.writeIdx++
	s.maxSeq = seq
	if s.writeIdx > hlsRingSize {
		s.minSeq = s.writeIdx - hlsRingSize
	}
	count := s.writeIdx
	s.mu.Unlock()

	if count >= hlsReadySegments {
		s.doneOnce.Do(func() { close(s.readyCh) })
	}
}

func (s *hlsSession) waitReady(timeout time.Duration) bool {
	select {
	case <-s.readyCh:
		return true
	case <-time.After(timeout):
		return false
	}
}

func (s *hlsSession) manifest(baseURL, token string) string {
	s.mu.RLock()
	defer s.mu.RUnlock()

	tokenSuffix := ""
	if token != "" {
		tokenSuffix = "?X-Plex-Token=" + token
	}

	var b strings.Builder
	b.WriteString("#EXTM3U\n")
	b.WriteString("#EXT-X-VERSION:3\n")
	b.WriteString(fmt.Sprintf("#EXT-X-TARGETDURATION:%d\n", hlsTargetDuration))

	// Serve the 4 most recent segments — ~8s of live buffer.
	// Enough headroom for network jitter while still being close to live.
	const liveEdgeSegments = 4
	liveStart := s.maxSeq - liveEdgeSegments + 1
	if liveStart < s.minSeq {
		liveStart = s.minSeq
	}
	b.WriteString(fmt.Sprintf("#EXT-X-MEDIA-SEQUENCE:%d\n", liveStart))

	for seq := liveStart; seq <= s.maxSeq; seq++ {
		seg := s.ring[seq%hlsRingSize]
		if seg != nil && seg.seq == seq {
			b.WriteString(fmt.Sprintf("#EXTINF:%s,\n", hlsSegmentDuration))
			b.WriteString(fmt.Sprintf("%s/segment/%d.ts%s\n", baseURL, seq, tokenSuffix))
		}
	}

	return b.String()
}

func (s *hlsSession) segment(seq int) []byte {
	s.mu.RLock()
	defer s.mu.RUnlock()
	seg := s.ring[seq%hlsRingSize]
	if seg != nil && seg.seq == seq {
		return seg.data
	}
	return nil
}

// channelHLSManifest serves a live HLS manifest for a channel.
// GET /api/livetv/channels/:id/stream.m3u8
func (s *Server) channelHLSManifest(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid channel id"})
		return
	}

	var channel models.Channel
	if err := s.db.First(&channel, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "channel not found"})
		return
	}
	if channel.StreamURL == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "channel has no stream URL"})
		return
	}

	sess := getOrStartHLSSession(uint(id), channel.StreamURL)

	if !sess.waitReady(12 * time.Second) {
		c.JSON(http.StatusGatewayTimeout, gin.H{"error": "stream not ready — check upstream source"})
		return
	}

	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	baseURL := fmt.Sprintf("%s://%s/livetv/channels/%d", scheme, c.Request.Host, id)

	// Forward auth token into segment URLs so AVPlayer can fetch them remotely.
	token := c.Query("X-Plex-Token")
	if token == "" {
		authHeader := c.GetHeader("Authorization")
		if strings.HasPrefix(authHeader, "Bearer ") {
			token = strings.TrimPrefix(authHeader, "Bearer ")
		}
	}

	m3u8 := sess.manifest(baseURL, token)

	c.Header("Content-Type", "application/vnd.apple.mpegurl")
	c.Header("Cache-Control", "no-cache, no-store, must-revalidate")
	c.Header("Access-Control-Allow-Origin", "*")
	c.String(http.StatusOK, m3u8)
}

// channelHLSSegment serves a single TS segment.
// GET /api/livetv/channels/:id/segment/:seq
func (s *Server) channelHLSSegment(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid channel id"})
		return
	}

	seqStr := strings.TrimSuffix(c.Param("seq"), ".ts")
	seq, err := strconv.Atoi(seqStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid sequence"})
		return
	}

	hlsSessionsMu.RLock()
	sess := hlsSessions[uint(id)]
	hlsSessionsMu.RUnlock()

	if sess == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "no active session"})
		return
	}

	data := sess.segment(seq)
	if data == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "segment not available"})
		return
	}

	c.Header("Content-Type", "video/MP2T")
	c.Header("Cache-Control", "no-cache")
	c.Header("Access-Control-Allow-Origin", "*")
	c.Data(http.StatusOK, "video/MP2T", data)
}
