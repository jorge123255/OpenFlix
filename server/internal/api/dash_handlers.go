package api

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/openflix/openflix-server/internal/transcode"
)

// dashSessions stores DASH-specific session metadata alongside the base session
// in the Transcoder. This is initialized lazily on first use.
var dashSessions = transcode.NewDASHSessionStore()

// ============ DASH Transcode Handlers ============

// dashStart starts a DASH transcoding session and returns the MPD manifest.
// GET /video/-/transcode/dash/start.mpd
// Query params: path (media path), fileID, quality (1080/720/480/360/original/auto), offset
func (s *Server) dashStart(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	// Get the file path - either a direct path or a media key reference
	filePath := c.Query("path")
	fileIDStr := c.Query("fileID")
	quality := c.DefaultQuery("quality", "original")
	offset, _ := strconv.ParseInt(c.Query("offset"), 10, 64)

	var fileID uint
	var resolvedPath string

	if fileIDStr != "" {
		// Resolve by file ID
		fid, err := strconv.ParseUint(fileIDStr, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid fileID"})
			return
		}
		fileID = uint(fid)

		var file models.MediaFile
		if err := s.db.First(&file, fileID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Media file not found"})
			return
		}
		resolvedPath = file.FilePath
	} else if filePath != "" {
		// Parse media key from path (e.g., /library/metadata/123)
		parts := strings.Split(filePath, "/")
		var mediaKey int
		for i, p := range parts {
			if p == "metadata" && i+1 < len(parts) {
				mediaKey, _ = strconv.Atoi(parts[i+1])
				break
			}
		}

		if mediaKey == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid path"})
			return
		}

		var item models.MediaItem
		if err := s.db.First(&item, mediaKey).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Media not found"})
			return
		}

		var file models.MediaFile
		if err := s.db.Where("media_item_id = ?", mediaKey).First(&file).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "No media file found"})
			return
		}
		fileID = file.ID
		resolvedPath = file.FilePath
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Either path or fileID is required"})
		return
	}

	// Verify file exists on disk
	if _, err := os.Stat(resolvedPath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media file not found on disk"})
		return
	}

	var dashSession *transcode.DASHSession
	var err error

	if quality == "auto" {
		// Multi-bitrate adaptive DASH
		dashSession, err = s.transcoder.StartMultiBitrateDASH(fileID, resolvedPath, offset)
	} else {
		// Single quality DASH
		dashSession, err = s.transcoder.StartDASH(fileID, resolvedPath, quality, offset)
	}

	if err != nil {
		logger.Errorf("Failed to start DASH transcode: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Store DASH session metadata
	dashSessions.Put(dashSession.ID, dashSession)

	logger.Infof("DASH transcode started: session=%s quality=%s fileID=%d", dashSession.ID, quality, fileID)

	// Wait for FFmpeg to produce the initial manifest
	time.Sleep(1 * time.Second)

	// Read and return the MPD manifest
	mpdData, err := s.transcoder.GenerateMPD(dashSession.ID)
	if err != nil {
		logger.Errorf("Failed to generate MPD manifest: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate manifest: " + err.Error()})
		return
	}

	// Rewrite segment URLs to include the session ID path
	// FFmpeg generates relative URLs; we make them point to our segment endpoint
	manifest := string(mpdData)
	manifest = rewriteDASHManifestURLs(manifest, dashSession.ID)

	c.Header("Content-Type", "application/dash+xml")
	c.Header("Cache-Control", "no-cache")
	c.String(http.StatusOK, manifest)
}

// dashSegment serves a DASH segment (init or media) for a session.
// GET /video/-/transcode/dash/session/:sessionId/:segment
func (s *Server) dashSegment(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	sessionID := c.Param("sessionId")
	segmentName := c.Param("segment")

	// Validate session exists
	session := s.transcoder.GetSession(sessionID)
	if session == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	// Get segment path with wait
	segmentPath, err := s.transcoder.GetDASHSegment(sessionID, segmentName)
	if err != nil {
		logger.Errorf("DASH segment not available: session=%s segment=%s err=%v", sessionID, segmentName, err)
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	// Determine content type based on segment name
	contentType := "video/mp4"
	if strings.HasSuffix(segmentName, ".mpd") {
		contentType = "application/dash+xml"
	}

	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "no-cache")
	c.File(segmentPath)
}

// dashManifest re-fetches the MPD manifest for a session.
// GET /video/-/transcode/dash/session/:sessionId/manifest.mpd
func (s *Server) dashManifest(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	sessionID := c.Param("sessionId")

	session := s.transcoder.GetSession(sessionID)
	if session == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	s.transcoder.UpdateLastAccess(sessionID)

	manifestPath := s.transcoder.GetDASHManifestPath(sessionID)
	data, err := os.ReadFile(manifestPath)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Manifest not found"})
		return
	}

	// Rewrite URLs for client consumption
	manifest := rewriteDASHManifestURLs(string(data), sessionID)

	c.Header("Content-Type", "application/dash+xml")
	c.Header("Cache-Control", "no-cache")
	c.String(http.StatusOK, manifest)
}

// ============ DVR DASH Handlers ============

// getRecordingDASHManifest generates and serves a DASH MPD manifest for a DVR recording.
// GET /dvr/recordings/:id/dash/manifest.mpd
func (s *Server) getRecordingDASHManifest(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	var recording models.Recording
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id IN ?", []uint{userID, 0})
	}
	if err := query.First(&recording).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	if recording.Status != "completed" && recording.Status != "recording" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Recording is not available for playback"})
		return
	}

	if recording.FilePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording file not found"})
		return
	}

	if _, err := os.Stat(recording.FilePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording file not found on disk"})
		return
	}

	quality := c.DefaultQuery("quality", "original")

	// Start a DASH transcode session for this recording
	dashSession, err := s.transcoder.StartDASH(uint(id), recording.FilePath, quality, 0)
	if err != nil {
		logger.Errorf("Failed to start DASH transcode for recording %d: %v", id, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	dashSessions.Put(dashSession.ID, dashSession)
	logger.Infof("DASH transcode started for recording %d: session=%s", id, dashSession.ID)

	time.Sleep(1 * time.Second)

	mpdData, err := s.transcoder.GenerateMPD(dashSession.ID)
	if err != nil {
		logger.Errorf("Failed to generate MPD for recording %d: %v", id, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate manifest"})
		return
	}

	// Rewrite URLs to point to the recording segment endpoint
	manifest := string(mpdData)
	manifest = rewriteDASHManifestURLsForDVR(manifest, fmt.Sprintf("/dvr/recordings/%d/dash", id), dashSession.ID)

	c.Header("Content-Type", "application/dash+xml")
	c.Header("Cache-Control", "no-cache")
	// Pass session ID to the client via a custom header so it can fetch segments
	c.Header("X-Dash-Session-Id", dashSession.ID)
	c.String(http.StatusOK, manifest)
}

// getRecordingDASHSegment serves a DASH segment for a DVR recording.
// GET /dvr/recordings/:id/dash/:segment
func (s *Server) getRecordingDASHSegment(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	segmentName := c.Param("segment")
	sessionID := c.Query("session")

	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Session ID required (pass as ?session=...)"})
		return
	}

	session := s.transcoder.GetSession(sessionID)
	if session == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	segmentPath, err := s.transcoder.GetDASHSegment(sessionID, segmentName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Header("Content-Type", "video/mp4")
	c.Header("Cache-Control", "no-cache")
	c.File(segmentPath)
}

// getFileDASHManifest generates and serves a DASH MPD manifest for a DVR V2 file.
// GET /dvr/v2/files/:id/dash/manifest.mpd
func (s *Server) getFileDASHManifest(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var file models.DVRFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	if file.Deleted {
		c.JSON(http.StatusGone, gin.H{"error": "File has been deleted"})
		return
	}

	if file.FilePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "No file path available"})
		return
	}

	if _, err := os.Stat(file.FilePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found on disk"})
		return
	}

	quality := c.DefaultQuery("quality", "original")

	dashSession, err := s.transcoder.StartDASH(uint(id), file.FilePath, quality, 0)
	if err != nil {
		logger.Errorf("Failed to start DASH transcode for DVR file %d: %v", id, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	dashSessions.Put(dashSession.ID, dashSession)
	logger.Infof("DASH transcode started for DVR file %d: session=%s", id, dashSession.ID)

	time.Sleep(1 * time.Second)

	mpdData, err := s.transcoder.GenerateMPD(dashSession.ID)
	if err != nil {
		logger.Errorf("Failed to generate MPD for DVR file %d: %v", id, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate manifest"})
		return
	}

	manifest := string(mpdData)
	manifest = rewriteDASHManifestURLsForDVR(manifest, fmt.Sprintf("/dvr/v2/files/%d/dash", id), dashSession.ID)

	c.Header("Content-Type", "application/dash+xml")
	c.Header("Cache-Control", "no-cache")
	c.Header("X-Dash-Session-Id", dashSession.ID)
	c.String(http.StatusOK, manifest)
}

// getFileDASHSegment serves a DASH segment for a DVR V2 file.
// GET /dvr/v2/files/:id/dash/:segment
func (s *Server) getFileDASHSegment(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	segmentName := c.Param("segment")
	sessionID := c.Query("session")

	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Session ID required (pass as ?session=...)"})
		return
	}

	session := s.transcoder.GetSession(sessionID)
	if session == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	segmentPath, err := s.transcoder.GetDASHSegment(sessionID, segmentName)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Header("Content-Type", "video/mp4")
	c.Header("Cache-Control", "no-cache")
	c.File(segmentPath)
}

// ============ DASH Manifest URL Rewriting ============

// rewriteDASHManifestURLs rewrites segment URLs in the MPD manifest to route through
// the DASH segment endpoint. FFmpeg generates relative file names like "init-0.m4s"
// and "seg-0-00001.m4s"; we rewrite them to full API paths.
func rewriteDASHManifestURLs(manifest, sessionID string) string {
	// Replace initialization="init-$RepresentationID$.m4s" with full path
	// and media="seg-$RepresentationID$-$Number%05d$.m4s" with full path
	basePath := fmt.Sprintf("/video/-/transcode/dash/session/%s/", sessionID)

	// Replace initialization attribute values
	manifest = replaceSegmentAttr(manifest, "initialization", basePath)
	// Replace media attribute values
	manifest = replaceSegmentAttr(manifest, "media", basePath)

	return manifest
}

// rewriteDASHManifestURLsForDVR rewrites segment URLs for DVR DASH endpoints
func rewriteDASHManifestURLsForDVR(manifest, basePath, sessionID string) string {
	// For DVR endpoints, segments are served at basePath/:segment?session=sessionID
	prefix := fmt.Sprintf("%s/", basePath)
	suffix := fmt.Sprintf("?session=%s", sessionID)

	// Replace initialization and media attributes with full DVR paths
	manifest = replaceSegmentAttrWithSuffix(manifest, "initialization", prefix, suffix)
	manifest = replaceSegmentAttrWithSuffix(manifest, "media", prefix, suffix)

	return manifest
}

// replaceSegmentAttr replaces the value of an XML attribute to prepend a base path.
// For example: initialization="init-0.m4s" becomes initialization="/video/-/transcode/dash/session/abc/init-0.m4s"
func replaceSegmentAttr(manifest, attrName, basePath string) string {
	searchPrefix := attrName + `="`
	result := manifest
	for {
		idx := strings.Index(result, searchPrefix)
		if idx == -1 {
			break
		}

		attrStart := idx + len(searchPrefix)
		attrEnd := strings.Index(result[attrStart:], `"`)
		if attrEnd == -1 {
			break
		}
		attrEnd += attrStart

		attrValue := result[attrStart:attrEnd]

		// Only rewrite if the value is a relative path (not already an absolute URL)
		if !strings.HasPrefix(attrValue, "/") && !strings.HasPrefix(attrValue, "http") {
			newValue := basePath + attrValue
			result = result[:attrStart] + newValue + result[attrEnd:]
		} else {
			// Skip this occurrence to avoid infinite loop
			// Move past this attribute
			result = result[:attrStart] + result[attrStart:]
			break
		}
	}
	return result
}

// replaceSegmentAttrWithSuffix replaces the value of an XML attribute to prepend a base path
// and append a query string suffix.
func replaceSegmentAttrWithSuffix(manifest, attrName, basePath, suffix string) string {
	searchPrefix := attrName + `="`
	result := manifest
	for {
		idx := strings.Index(result, searchPrefix)
		if idx == -1 {
			break
		}

		attrStart := idx + len(searchPrefix)
		attrEnd := strings.Index(result[attrStart:], `"`)
		if attrEnd == -1 {
			break
		}
		attrEnd += attrStart

		attrValue := result[attrStart:attrEnd]

		if !strings.HasPrefix(attrValue, "/") && !strings.HasPrefix(attrValue, "http") {
			newValue := basePath + attrValue + suffix
			result = result[:attrStart] + newValue + result[attrEnd:]
		} else {
			break
		}
	}
	return result
}

// ============ DVR DASH On-Demand Segment Generation ============

// generateDASHSegmentOnDemand uses FFmpeg to generate a single fragmented MP4 segment
// from a recording file at a specific time offset. This is used when a full DASH
// transcode session is not needed (e.g., for on-demand segment serving).
func generateDASHSegmentOnDemand(filePath string, startTime, duration float64) ([]byte, error) {
	cmd := exec.Command("ffmpeg",
		"-ss", fmt.Sprintf("%.3f", startTime),
		"-i", filePath,
		"-t", fmt.Sprintf("%.3f", duration),
		"-map", "0:v:0",
		"-map", "0:a:0?",
		"-c:v", "libx264",
		"-preset", "ultrafast",
		"-c:a", "aac",
		"-b:a", "128k",
		"-movflags", "frag_keyframe+empty_moov+default_base_moof",
		"-f", "mp4",
		"-",
	)

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to generate DASH segment: %w", err)
	}
	return output, nil
}

// ============ Playback Decision DASH Support ============

// buildDASHPlaybackUrl constructs a DASH playback URL for a file ID
func buildDASHPlaybackUrl(fileID uint, quality string) string {
	url := "/video/-/transcode/dash/start.mpd?fileID=" + strconv.FormatUint(uint64(fileID), 10)
	if quality != "" {
		url += "&quality=" + quality
	}
	return url
}

// isDASHCapable checks if a client supports DASH playback based on its capabilities
func isDASHCapable(containers []string) bool {
	for _, c := range containers {
		lower := strings.ToLower(c)
		if lower == "dash" || lower == "mpd" || lower == "mp4" {
			return true
		}
	}
	return false
}

