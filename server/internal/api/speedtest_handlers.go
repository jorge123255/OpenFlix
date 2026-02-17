package api

import (
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/speedtest"
)

// package-level speed test instance shared across handlers
var sharedSpeedTest = speedtest.New()

// speedTestPing responds with the server's current timestamp so clients can
// measure round-trip latency.
//
// GET /api/speedtest/ping
func (s *Server) speedTestPing(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"pong":      true,
		"timestamp": time.Now().UnixNano(),
		"serverTime": time.Now().UTC().Format(time.RFC3339Nano),
	})
}

// speedTestDownload streams random data for a download speed test.
// The client should time how long it takes to receive all bytes.
//
// GET /api/speedtest/download?size=10000000
//
// Query params:
//   - size: number of bytes to download (default 10 MB, max 100 MB)
func (s *Server) speedTestDownload(c *gin.Context) {
	const (
		defaultSize = 10_000_000  // 10 MB
		maxSize     = 100_000_000 // 100 MB
	)

	size := int64(defaultSize)
	if sizeStr := c.Query("size"); sizeStr != "" {
		parsed, err := strconv.ParseInt(sizeStr, 10, 64)
		if err != nil || parsed <= 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid size parameter"})
			return
		}
		size = parsed
	}

	if size > maxSize {
		size = maxSize
	}

	reader := sharedSpeedTest.GenerateDownloadData(size)

	c.Header("Content-Type", "application/octet-stream")
	c.Header("Content-Length", strconv.FormatInt(size, 10))
	c.Header("Cache-Control", "no-store")
	c.Header("X-Speedtest-Size", strconv.FormatInt(size, 10))

	c.Status(http.StatusOK)
	written, err := io.Copy(c.Writer, reader)
	if err != nil {
		// Client may have disconnected; that is expected.
		return
	}
	_ = written
}

// speedTestUpload accepts an upload payload, measures how long it takes to
// receive all the data, and returns the result.
//
// POST /api/speedtest/upload
func (s *Server) speedTestUpload(c *gin.Context) {
	sessionID := uuid.New().String()
	session := sharedSpeedTest.StartUploadTest(sessionID)

	// Read the entire request body, counting bytes
	bytesReceived, err := io.Copy(io.Discard, c.Request.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": fmt.Sprintf("failed to read upload data: %v", err),
		})
		return
	}

	sharedSpeedTest.RecordUpload(sessionID, bytesReceived)

	results := sharedSpeedTest.GetResults(sessionID)
	if results == nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "session not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":            session.ID,
		"bytesReceived": bytesReceived,
		"durationSeconds": results.Session.Duration,
		"uploadMbps":    results.Session.UploadMbps,
		"serverInfo":    results.ServerInfo,
	})
}

// speedTestResults returns the results for a previously completed test session.
//
// GET /api/speedtest/results/:id
func (s *Server) speedTestResults(c *gin.Context) {
	sessionID := c.Param("id")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "session id is required"})
		return
	}

	results := sharedSpeedTest.GetResults(sessionID)
	if results == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "session not found"})
		return
	}

	c.JSON(http.StatusOK, results)
}
