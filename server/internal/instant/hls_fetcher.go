package instant

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
)

// HLSFetcher handles fetching and parsing HLS streams for pre-buffering
type HLSFetcher struct {
	client       *http.Client
	mu           sync.RWMutex
	lastPlaylist string
	lastSegments []HLSSegment
	mediaSeq     int
}

// HLSSegment represents a single HLS segment
type HLSSegment struct {
	URL       string
	Duration  float64
	Sequence  int
	ByteRange *ByteRange
}

// ByteRange for byte-range requests
type ByteRange struct {
	Length int64
	Offset int64
}

// NewHLSFetcher creates a new HLS fetcher
func NewHLSFetcher() *HLSFetcher {
	return &HLSFetcher{
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// FetchPlaylist fetches and parses an HLS playlist
func (hf *HLSFetcher) FetchPlaylist(ctx context.Context, playlistURL string) ([]HLSSegment, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", playlistURL, nil)
	if err != nil {
		return nil, err
	}

	resp, err := hf.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("playlist fetch failed: %d", resp.StatusCode)
	}

	baseURL, _ := url.Parse(playlistURL)
	segments, mediaSeq := hf.parsePlaylist(resp.Body, baseURL)

	hf.mu.Lock()
	hf.lastPlaylist = playlistURL
	hf.lastSegments = segments
	hf.mediaSeq = mediaSeq
	hf.mu.Unlock()

	return segments, nil
}

// parsePlaylist parses an M3U8 playlist
func (hf *HLSFetcher) parsePlaylist(reader io.Reader, baseURL *url.URL) ([]HLSSegment, int) {
	var segments []HLSSegment
	var currentDuration float64
	var currentByteRange *ByteRange
	mediaSeq := 0
	sequence := 0

	scanner := bufio.NewScanner(reader)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		if strings.HasPrefix(line, "#EXT-X-MEDIA-SEQUENCE:") {
			mediaSeq, _ = strconv.Atoi(strings.TrimPrefix(line, "#EXT-X-MEDIA-SEQUENCE:"))
			sequence = mediaSeq
		} else if strings.HasPrefix(line, "#EXTINF:") {
			// Parse duration: #EXTINF:6.006,
			parts := strings.Split(strings.TrimPrefix(line, "#EXTINF:"), ",")
			if len(parts) > 0 {
				currentDuration, _ = strconv.ParseFloat(parts[0], 64)
			}
		} else if strings.HasPrefix(line, "#EXT-X-BYTERANGE:") {
			// Parse byte range: #EXT-X-BYTERANGE:188892@0
			rangeStr := strings.TrimPrefix(line, "#EXT-X-BYTERANGE:")
			parts := strings.Split(rangeStr, "@")
			if len(parts) >= 1 {
				length, _ := strconv.ParseInt(parts[0], 10, 64)
				var offset int64
				if len(parts) >= 2 {
					offset, _ = strconv.ParseInt(parts[1], 10, 64)
				}
				currentByteRange = &ByteRange{Length: length, Offset: offset}
			}
		} else if !strings.HasPrefix(line, "#") && line != "" {
			// This is a segment URL
			segURL := line
			if !strings.HasPrefix(segURL, "http") {
				// Relative URL
				segParsed, err := url.Parse(segURL)
				if err == nil {
					segURL = baseURL.ResolveReference(segParsed).String()
				}
			}

			segments = append(segments, HLSSegment{
				URL:       segURL,
				Duration:  currentDuration,
				Sequence:  sequence,
				ByteRange: currentByteRange,
			})

			sequence++
			currentDuration = 0
			currentByteRange = nil
		}
	}

	return segments, mediaSeq
}

// FetchSegment downloads a single segment
func (hf *HLSFetcher) FetchSegment(ctx context.Context, segment HLSSegment) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", segment.URL, nil)
	if err != nil {
		return nil, err
	}

	// Add byte range header if specified
	if segment.ByteRange != nil {
		end := segment.ByteRange.Offset + segment.ByteRange.Length - 1
		req.Header.Set("Range", fmt.Sprintf("bytes=%d-%d", segment.ByteRange.Offset, end))
	}

	resp, err := hf.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusPartialContent {
		return nil, fmt.Errorf("segment fetch failed: %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}

// GetNewSegments returns segments newer than the given sequence number
func (hf *HLSFetcher) GetNewSegments(sinceSequence int) []HLSSegment {
	hf.mu.RLock()
	defer hf.mu.RUnlock()

	var newSegs []HLSSegment
	for _, seg := range hf.lastSegments {
		if seg.Sequence > sinceSequence {
			newSegs = append(newSegs, seg)
		}
	}
	return newSegs
}

// StreamBuffer continuously fetches and buffers an HLS stream
type StreamBuffer struct {
	playlistURL  string
	buffer       *RingBuffer
	fetcher      *HLSFetcher
	lastSequence int
	isRunning    bool
	mu           sync.RWMutex
	ctx          context.Context
	cancel       context.CancelFunc
	onNewSegment func(segment HLSSegment, data []byte)
}

// NewStreamBuffer creates a new stream buffer
func NewStreamBuffer(playlistURL string, bufferSize int) *StreamBuffer {
	ctx, cancel := context.WithCancel(context.Background())

	return &StreamBuffer{
		playlistURL: playlistURL,
		buffer:      NewRingBuffer(bufferSize),
		fetcher:     NewHLSFetcher(),
		ctx:         ctx,
		cancel:      cancel,
	}
}

// Start begins continuous buffering
func (sb *StreamBuffer) Start() {
	sb.mu.Lock()
	if sb.isRunning {
		sb.mu.Unlock()
		return
	}
	sb.isRunning = true
	sb.mu.Unlock()

	go sb.bufferLoop()
}

// Stop halts buffering
func (sb *StreamBuffer) Stop() {
	sb.mu.Lock()
	sb.isRunning = false
	sb.mu.Unlock()

	sb.cancel()
}

// bufferLoop continuously fetches new segments
func (sb *StreamBuffer) bufferLoop() {
	ticker := time.NewTicker(2 * time.Second) // HLS typically has 6s segments
	defer ticker.Stop()

	for {
		select {
		case <-sb.ctx.Done():
			return
		case <-ticker.C:
			sb.fetchNewSegments()
		}
	}
}

// fetchNewSegments fetches any new segments from the playlist
func (sb *StreamBuffer) fetchNewSegments() {
	segments, err := sb.fetcher.FetchPlaylist(sb.ctx, sb.playlistURL)
	if err != nil {
		return
	}

	sb.mu.Lock()
	lastSeq := sb.lastSequence
	sb.mu.Unlock()

	for _, seg := range segments {
		if seg.Sequence > lastSeq {
			data, err := sb.fetcher.FetchSegment(sb.ctx, seg)
			if err != nil {
				continue
			}

			// Write to buffer
			sb.buffer.WriteSegment(
				fmt.Sprintf("seg_%d", seg.Sequence),
				data,
				time.Now().Unix(),
				seg.Duration,
			)

			sb.mu.Lock()
			sb.lastSequence = seg.Sequence
			sb.mu.Unlock()

			// Callback if set
			if sb.onNewSegment != nil {
				sb.onNewSegment(seg, data)
			}
		}
	}
}

// GetBuffer returns the ring buffer
func (sb *StreamBuffer) GetBuffer() *RingBuffer {
	return sb.buffer
}

// GetBufferedDuration returns seconds of video buffered
func (sb *StreamBuffer) GetBufferedDuration() float64 {
	return sb.buffer.BufferedDuration()
}

// IsRunning returns whether buffering is active
func (sb *StreamBuffer) IsRunning() bool {
	sb.mu.RLock()
	defer sb.mu.RUnlock()
	return sb.isRunning
}

// SetNewSegmentCallback sets a callback for new segments
func (sb *StreamBuffer) SetNewSegmentCallback(fn func(segment HLSSegment, data []byte)) {
	sb.onNewSegment = fn
}

// Stats returns buffer statistics
func (sb *StreamBuffer) Stats() map[string]interface{} {
	sb.mu.RLock()
	defer sb.mu.RUnlock()

	return map[string]interface{}{
		"playlist_url":      sb.playlistURL,
		"is_running":        sb.isRunning,
		"last_sequence":     sb.lastSequence,
		"buffer_stats":      sb.buffer.Stats(),
		"buffered_duration": sb.buffer.BufferedDuration(),
	}
}
