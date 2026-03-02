package api

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/logger"
)

// virtualStationPlayerMu guards lazy initialisation of the package-level player.
var virtualStationPlayerMu sync.Mutex

// virtualStationPlayerInstance is a lazily-initialised singleton.  Because
// we cannot add fields to the existing Server struct, we store the player at
// package level and initialise it on first use.
var virtualStationPlayerInstance *dvr.VirtualStationPlayer

// getOrCreateVirtualStationPlayer returns the singleton VirtualStationPlayer,
// creating it on first call using the server's DB and ffmpeg path.
func (s *Server) getOrCreateVirtualStationPlayer() *dvr.VirtualStationPlayer {
	virtualStationPlayerMu.Lock()
	defer virtualStationPlayerMu.Unlock()

	if virtualStationPlayerInstance != nil {
		return virtualStationPlayerInstance
	}

	ffmpegPath := s.config.Transcode.FFmpegPath
	if ffmpegPath == "" {
		ffmpegPath = "ffmpeg"
	}
	virtualStationPlayerInstance = dvr.NewVirtualStationPlayer(s.db, ffmpegPath)
	logger.Info("Virtual station player initialised")
	return virtualStationPlayerInstance
}

// streamVirtualStationHLS returns an HLS master playlist for a virtual station.
// Intended for: GET /dvr/v2/virtual-stations/:id/stream.m3u8
func (s *Server) streamVirtualStationHLS(c *gin.Context) {
	player := s.getOrCreateVirtualStationPlayer()
	if player == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Virtual station player not available"})
		return
	}

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid station ID"})
		return
	}

	playlist, err := player.GetPlaylist(uint(id))
	if err != nil {
		logger.Warnf("Virtual station %d playlist error: %v", id, err)
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Header("Content-Type", "application/vnd.apple.mpegurl")
	c.Header("Cache-Control", "no-cache")
	c.String(http.StatusOK, playlist)
}

// getVirtualStationSegment serves a single HLS segment from the virtual station.
// Intended for: GET /dvr/v2/virtual-stations/:id/segment/:fileIdx/:segIdx
//
// It resolves the segment to a file path and time range, then extracts the
// segment via ffmpeg and streams it as MPEG-TS.
func (s *Server) getVirtualStationSegment(c *gin.Context) {
	player := s.getOrCreateVirtualStationPlayer()
	if player == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Virtual station player not available"})
		return
	}

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid station ID"})
		return
	}

	fileIdx, err := strconv.Atoi(c.Param("fileIdx"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file index"})
		return
	}

	segIdx, err := strconv.Atoi(c.Param("segIdx"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid segment index"})
		return
	}

	filePath, startTime, duration, segErr := player.GetSegmentPath(uint(id), fileIdx, segIdx)
	if segErr != nil {
		logger.Warnf("Virtual station %d segment %d/%d error: %v", id, fileIdx, segIdx, segErr)
		c.JSON(http.StatusNotFound, gin.H{"error": segErr.Error()})
		return
	}

	if filePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "No file path for segment"})
		return
	}

	// Verify the file exists on disk.
	if _, statErr := os.Stat(filePath); os.IsNotExist(statErr) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source file not found on disk"})
		return
	}

	ffmpegPath := s.config.Transcode.FFmpegPath
	if ffmpegPath == "" {
		ffmpegPath = "ffmpeg"
	}

	serveVirtualStationSegment(c, ffmpegPath, filePath, startTime, duration)
}

// getVirtualStationNowPlaying returns information about the currently playing
// item on a virtual station.
// Intended for: GET /dvr/v2/virtual-stations/:id/now-playing
func (s *Server) getVirtualStationNowPlaying(c *gin.Context) {
	player := s.getOrCreateVirtualStationPlayer()
	if player == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Virtual station player not available"})
		return
	}

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid station ID"})
		return
	}

	info, npErr := player.GetNowPlaying(uint(id))
	if npErr != nil {
		logger.Warnf("Virtual station %d now-playing error: %v", id, npErr)
		c.JSON(http.StatusNotFound, gin.H{"error": npErr.Error()})
		return
	}

	c.JSON(http.StatusOK, info)
}

// ---------- helpers ----------

// serveVirtualStationSegment uses ffmpeg to extract a segment from a source
// file and streams it as MPEG-TS to the HTTP response.
func serveVirtualStationSegment(c *gin.Context, ffmpegPath, filePath string, startTime, duration float64) {
	startStr := fmt.Sprintf("%.3f", startTime)
	durationStr := fmt.Sprintf("%.3f", duration)

	// Determine if the source is already MPEG-TS; if so we can use stream
	// copy which is much faster.  For other containers (mp4, mkv) we still
	// use stream copy but the muxer handles the repackaging.
	ext := strings.ToLower(filePath)
	codec := "copy"
	_ = ext // codec is always copy; container detection is for future use

	args := []string{
		"-hide_banner",
		"-loglevel", "error",
		"-ss", startStr,
		"-t", durationStr,
		"-i", filePath,
		"-c", codec,
		"-f", "mpegts",
		"-avoid_negative_ts", "make_zero",
		"pipe:1",
	}

	cmd := exec.Command(ffmpegPath, args...)
	cmd.Stderr = nil // discard stderr

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		logger.Errorf("ffmpeg stdout pipe error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create ffmpeg pipe"})
		return
	}

	if err := cmd.Start(); err != nil {
		logger.Errorf("ffmpeg start error for segment: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to start ffmpeg"})
		return
	}

	c.Header("Content-Type", "video/mp2t")
	c.Header("Cache-Control", "no-cache")
	c.Status(http.StatusOK)

	// Stream ffmpeg output to the HTTP client.
	buf := make([]byte, 32*1024)
	for {
		n, readErr := stdout.Read(buf)
		if n > 0 {
			if _, writeErr := c.Writer.Write(buf[:n]); writeErr != nil {
				// Client disconnected; kill ffmpeg.
				_ = cmd.Process.Kill()
				break
			}
			c.Writer.Flush()
		}
		if readErr != nil {
			break
		}
	}

	// Wait for ffmpeg to finish (ignore error since client may have disconnected).
	_ = cmd.Wait()
}
