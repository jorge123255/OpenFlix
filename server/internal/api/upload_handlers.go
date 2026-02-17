package api

import (
	"crypto/sha256"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// Maximum upload file size: 10 GB
const maxUploadSize = 10 << 30 // 10 * 1024 * 1024 * 1024

// Supported video file extensions for bulk import scanning.
var videoExtensions = map[string]bool{
	".mp4": true,
	".mkv": true,
	".ts":  true,
	".avi": true,
	".mov": true,
}

// uploadSessions tracks in-progress chunked uploads.
var uploadSessions = struct {
	sync.RWMutex
	sessions map[string]*uploadSession
}{sessions: make(map[string]*uploadSession)}

type uploadSession struct {
	ID           string    `json:"id"`
	Filename     string    `json:"filename"`
	TotalSize    int64     `json:"totalSize"`
	UploadedSize int64     `json:"uploadedSize"`
	Status       string    `json:"status"` // uploading, processing, completed, failed
	CreatedAt    time.Time `json:"createdAt"`
	FilePath     string    `json:"filePath,omitempty"`
	Error        string    `json:"error,omitempty"`
}

// ---------- POST /dvr/v2/files/upload ----------

// uploadFile handles multipart file uploads and creates a DVRFile record.
// It supports both single-shot and chunked uploads (via Content-Range header).
func (s *Server) uploadFile(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxUploadSize)

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Failed to read uploaded file: %v", err)})
		return
	}
	defer file.Close()

	// Validate filename
	filename := filepath.Base(header.Filename)
	if filename == "." || filename == "/" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid filename"})
		return
	}

	// Determine destination directory
	destDir := s.config.DVR.RecordingDir
	if destDir == "" {
		destDir = filepath.Join(s.config.GetDataDir(), "recordings")
	}
	if err := os.MkdirAll(destDir, 0755); err != nil {
		logger.Errorf("Failed to create recordings directory: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create recordings directory"})
		return
	}

	destPath := filepath.Join(destDir, filename)

	// Handle Content-Range for chunked uploads
	contentRange := c.GetHeader("Content-Range")
	if contentRange != "" {
		s.handleChunkedUpload(c, file, destPath, filename, contentRange)
		return
	}

	// Single-shot upload: create a session for tracking
	sessionID := fmt.Sprintf("%x", sha256.Sum256([]byte(fmt.Sprintf("%s-%d", filename, time.Now().UnixNano()))))[:16]

	uploadSessions.Lock()
	uploadSessions.sessions[sessionID] = &uploadSession{
		ID:        sessionID,
		Filename:  filename,
		TotalSize: header.Size,
		Status:    "uploading",
		CreatedAt: time.Now(),
		FilePath:  destPath,
	}
	uploadSessions.Unlock()

	// Avoid overwriting existing files: append a timestamp if needed
	destPath = uniqueFilePath(destPath)

	outFile, err := os.Create(destPath)
	if err != nil {
		s.failUploadSession(sessionID, fmt.Sprintf("Failed to create file: %v", err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create destination file"})
		return
	}
	defer outFile.Close()

	hasher := sha256.New()
	written, err := io.Copy(io.MultiWriter(outFile, hasher), file)
	if err != nil {
		s.failUploadSession(sessionID, fmt.Sprintf("Failed to write file: %v", err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to write file"})
		return
	}

	// Update session
	uploadSessions.Lock()
	if sess, ok := uploadSessions.sessions[sessionID]; ok {
		sess.UploadedSize = written
		sess.Status = "processing"
		sess.FilePath = destPath
	}
	uploadSessions.Unlock()

	// Create DVRFile record
	title := c.PostForm("title")
	if title == "" {
		title = strings.TrimSuffix(filename, filepath.Ext(filename))
	}

	var groupID *uint
	if gidStr := c.PostForm("groupId"); gidStr != "" {
		if gid, err := strconv.ParseUint(gidStr, 10, 32); err == nil {
			g := uint(gid)
			groupID = &g
		}
	}

	ext := strings.TrimPrefix(filepath.Ext(filename), ".")
	now := time.Now()

	dvrFile := models.DVRFile{
		Title:       title,
		Description: c.PostForm("category"),
		FilePath:    destPath,
		FileSize:    written,
		Container:   ext,
		Completed:   true,
		Processed:   false,
		GroupID:     groupID,
		RecordedAt:  &now,
		Category:    c.PostForm("category"),
	}

	if err := s.db.Create(&dvrFile).Error; err != nil {
		s.failUploadSession(sessionID, fmt.Sprintf("Failed to create DB record: %v", err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create file record"})
		return
	}

	// Mark session completed
	uploadSessions.Lock()
	if sess, ok := uploadSessions.sessions[sessionID]; ok {
		sess.Status = "completed"
	}
	uploadSessions.Unlock()

	// Publish event
	s.publishDVREvent(dvr.DVREvent{
		Type:   dvr.EventFileCreated,
		FileID: dvrFile.ID,
		Title:  dvrFile.Title,
		Data: map[string]any{
			"source":   "upload",
			"fileSize": written,
			"checksum": fmt.Sprintf("%x", hasher.Sum(nil)),
		},
	})

	logger.Infof("File uploaded successfully: %s (%d bytes)", destPath, written)

	c.JSON(http.StatusCreated, gin.H{
		"file":      dvrFile,
		"sessionId": sessionID,
	})
}

// handleChunkedUpload processes a chunk of data identified by Content-Range.
func (s *Server) handleChunkedUpload(c *gin.Context, file io.Reader, destPath, filename, contentRange string) {
	// Parse Content-Range header: "bytes start-end/total"
	start, end, total, err := parseContentRange(contentRange)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid Content-Range: %v", err)})
		return
	}

	// Derive session ID from filename + total size (deterministic)
	sessionID := fmt.Sprintf("%x", sha256.Sum256([]byte(fmt.Sprintf("%s-%d", filename, total))))[:16]

	// Ensure session exists
	uploadSessions.Lock()
	sess, exists := uploadSessions.sessions[sessionID]
	if !exists {
		destPath = uniqueFilePath(destPath)
		sess = &uploadSession{
			ID:        sessionID,
			Filename:  filename,
			TotalSize: total,
			Status:    "uploading",
			CreatedAt: time.Now(),
			FilePath:  destPath,
		}
		uploadSessions.sessions[sessionID] = sess
	}
	destPath = sess.FilePath
	uploadSessions.Unlock()

	// Open file for writing at the correct offset
	outFile, err := os.OpenFile(destPath, os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		s.failUploadSession(sessionID, fmt.Sprintf("Failed to open file: %v", err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to open destination file"})
		return
	}
	defer outFile.Close()

	if _, err := outFile.Seek(start, io.SeekStart); err != nil {
		s.failUploadSession(sessionID, fmt.Sprintf("Failed to seek: %v", err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to seek in file"})
		return
	}

	written, err := io.Copy(outFile, file)
	if err != nil {
		s.failUploadSession(sessionID, fmt.Sprintf("Failed to write chunk: %v", err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to write chunk"})
		return
	}

	// Update session progress
	uploadSessions.Lock()
	if sess, ok := uploadSessions.sessions[sessionID]; ok {
		sess.UploadedSize = end + 1
	}
	uploadSessions.Unlock()

	logger.Infof("Chunk received for %s: bytes %d-%d/%d (%d written)", filename, start, end, total, written)

	// Check if upload is complete
	if end+1 >= total {
		// Upload complete, create DVRFile record
		s.finalizeChunkedUpload(c, sessionID, destPath, filename, total)
		return
	}

	c.JSON(http.StatusAccepted, gin.H{
		"sessionId":    sessionID,
		"uploadedSize": end + 1,
		"totalSize":    total,
		"status":       "uploading",
	})
}

// finalizeChunkedUpload creates the DVRFile record after all chunks have been received.
func (s *Server) finalizeChunkedUpload(c *gin.Context, sessionID, destPath, filename string, totalSize int64) {
	uploadSessions.Lock()
	if sess, ok := uploadSessions.sessions[sessionID]; ok {
		sess.Status = "processing"
	}
	uploadSessions.Unlock()

	title := c.PostForm("title")
	if title == "" {
		title = strings.TrimSuffix(filename, filepath.Ext(filename))
	}

	ext := strings.TrimPrefix(filepath.Ext(filename), ".")
	now := time.Now()

	dvrFile := models.DVRFile{
		Title:      title,
		FilePath:   destPath,
		FileSize:   totalSize,
		Container:  ext,
		Completed:  true,
		Processed:  false,
		RecordedAt: &now,
	}

	if err := s.db.Create(&dvrFile).Error; err != nil {
		s.failUploadSession(sessionID, fmt.Sprintf("Failed to create DB record: %v", err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create file record"})
		return
	}

	uploadSessions.Lock()
	if sess, ok := uploadSessions.sessions[sessionID]; ok {
		sess.Status = "completed"
	}
	uploadSessions.Unlock()

	s.publishDVREvent(dvr.DVREvent{
		Type:   dvr.EventFileCreated,
		FileID: dvrFile.ID,
		Title:  dvrFile.Title,
		Data:   map[string]any{"source": "chunked_upload", "fileSize": totalSize},
	})

	logger.Infof("Chunked upload completed: %s (%d bytes)", destPath, totalSize)

	c.JSON(http.StatusCreated, gin.H{
		"file":      dvrFile,
		"sessionId": sessionID,
	})
}

// ---------- POST /dvr/v2/files/import ----------

type importRequest struct {
	FilePath string `json:"filePath" binding:"required"`
	Title    string `json:"title"`
	GroupID  *uint  `json:"groupId"`
}

// importFromPath creates a DVRFile record pointing to an existing file on the server.
// No file copy is performed.
func (s *Server) importFromPath(c *gin.Context) {
	var req importRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request: %v", err)})
		return
	}

	// Security: resolve to absolute path and verify it exists
	absPath, err := filepath.Abs(req.FilePath)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file path"})
		return
	}

	info, err := os.Stat(absPath)
	if err != nil {
		if os.IsNotExist(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "File not found on server"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Cannot access file: %v", err)})
		}
		return
	}

	if info.IsDir() {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Path is a directory, not a file. Use /dvr/v2/files/import/bulk for directories."})
		return
	}

	title := req.Title
	if title == "" {
		title = strings.TrimSuffix(filepath.Base(absPath), filepath.Ext(absPath))
	}

	ext := strings.TrimPrefix(filepath.Ext(absPath), ".")
	now := time.Now()

	dvrFile := models.DVRFile{
		Title:      title,
		FilePath:   absPath,
		FileSize:   info.Size(),
		Container:  ext,
		Completed:  true,
		Processed:  false,
		GroupID:    req.GroupID,
		RecordedAt: &now,
	}

	// Optionally probe for duration with ffprobe
	if duration := probeFileDuration(absPath); duration > 0 {
		dvrFile.Duration = duration
	}

	if err := s.db.Create(&dvrFile).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create file record: %v", err)})
		return
	}

	s.publishDVREvent(dvr.DVREvent{
		Type:   dvr.EventFileCreated,
		FileID: dvrFile.ID,
		Title:  dvrFile.Title,
		Data:   map[string]any{"source": "import", "filePath": absPath},
	})

	logger.Infof("File imported: %s (%d bytes)", absPath, info.Size())

	c.JSON(http.StatusCreated, dvrFile)
}

// ---------- GET /dvr/v2/files/upload/:id/progress ----------

// getUploadProgress returns the progress of a chunked upload session.
func (s *Server) getUploadProgress(c *gin.Context) {
	sessionID := c.Param("id")

	uploadSessions.RLock()
	sess, exists := uploadSessions.sessions[sessionID]
	uploadSessions.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Upload session not found"})
		return
	}

	var percent float64
	if sess.TotalSize > 0 {
		percent = float64(sess.UploadedSize) / float64(sess.TotalSize) * 100
	}

	c.JSON(http.StatusOK, gin.H{
		"id":           sess.ID,
		"filename":     sess.Filename,
		"totalSize":    sess.TotalSize,
		"uploadedSize": sess.UploadedSize,
		"percent":      percent,
		"status":       sess.Status,
		"createdAt":    sess.CreatedAt,
		"error":        sess.Error,
	})
}

// ---------- POST /dvr/v2/files/import/bulk ----------

type bulkImportRequest struct {
	Directory  string `json:"directory" binding:"required"`
	Recursive  bool   `json:"recursive"`
	GroupTitle string `json:"groupTitle"`
}

type bulkImportResult struct {
	Imported []models.DVRFile `json:"imported"`
	Skipped  []string         `json:"skipped"`
	Errors   []string         `json:"errors"`
	GroupID  *uint            `json:"groupId,omitempty"`
}

// bulkImport scans a directory for video files and creates DVRFile records for each.
func (s *Server) bulkImport(c *gin.Context) {
	var req bulkImportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request: %v", err)})
		return
	}

	absDir, err := filepath.Abs(req.Directory)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid directory path"})
		return
	}

	info, err := os.Stat(absDir)
	if err != nil {
		if os.IsNotExist(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Directory not found"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Cannot access directory: %v", err)})
		}
		return
	}
	if !info.IsDir() {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Path is not a directory"})
		return
	}

	// Optionally create or find a DVRGroup
	var groupID *uint
	if req.GroupTitle != "" {
		var group models.DVRGroup
		result := s.db.Where("title = ?", req.GroupTitle).First(&group)
		if result.Error != nil {
			// Create a new group
			group = models.DVRGroup{
				Title: req.GroupTitle,
			}
			if err := s.db.Create(&group).Error; err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create group: %v", err)})
				return
			}
			s.publishDVREvent(dvr.DVREvent{
				Type:    dvr.EventGroupCreated,
				GroupID: group.ID,
				Title:   group.Title,
			})
		}
		groupID = &group.ID
	}

	result := bulkImportResult{
		GroupID: groupID,
	}

	// Collect video files
	var videoPaths []string
	walkFn := func(path string, d os.DirEntry, err error) error {
		if err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Error accessing %s: %v", path, err))
			return nil // Continue walking
		}

		// Skip directories in non-recursive mode (except the root)
		if d.IsDir() && path != absDir && !req.Recursive {
			return filepath.SkipDir
		}

		if d.IsDir() {
			return nil
		}

		ext := strings.ToLower(filepath.Ext(path))
		if videoExtensions[ext] {
			videoPaths = append(videoPaths, path)
		}
		return nil
	}

	if err := filepath.WalkDir(absDir, walkFn); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to scan directory: %v", err)})
		return
	}

	// Import each video file
	now := time.Now()
	for _, vPath := range videoPaths {
		// Check if file is already imported
		var existing models.DVRFile
		if s.db.Where("file_path = ?", vPath).First(&existing).Error == nil {
			result.Skipped = append(result.Skipped, vPath)
			continue
		}

		fInfo, err := os.Stat(vPath)
		if err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("Cannot stat %s: %v", vPath, err))
			continue
		}

		title := strings.TrimSuffix(filepath.Base(vPath), filepath.Ext(vPath))
		ext := strings.TrimPrefix(filepath.Ext(vPath), ".")

		dvrFile := models.DVRFile{
			Title:      title,
			FilePath:   vPath,
			FileSize:   fInfo.Size(),
			Container:  ext,
			Completed:  true,
			Processed:  false,
			GroupID:    groupID,
			RecordedAt: &now,
		}

		// Optionally probe for duration
		if duration := probeFileDuration(vPath); duration > 0 {
			dvrFile.Duration = duration
		}

		if err := s.db.Create(&dvrFile).Error; err != nil {
			result.Errors = append(result.Errors, fmt.Sprintf("DB error for %s: %v", vPath, err))
			continue
		}

		s.publishDVREvent(dvr.DVREvent{
			Type:   dvr.EventFileCreated,
			FileID: dvrFile.ID,
			Title:  dvrFile.Title,
			Data:   map[string]any{"source": "bulk_import"},
		})

		result.Imported = append(result.Imported, dvrFile)
	}

	// Update group file count if applicable
	if groupID != nil {
		s.db.Model(&models.DVRGroup{}).Where("id = ?", *groupID).
			Update("file_count", len(result.Imported))
	}

	logger.Infof("Bulk import from %s: %d imported, %d skipped, %d errors",
		absDir, len(result.Imported), len(result.Skipped), len(result.Errors))

	c.JSON(http.StatusOK, result)
}

// ============ Helpers ============

// failUploadSession marks an upload session as failed with the given error message.
func (s *Server) failUploadSession(sessionID, errMsg string) {
	uploadSessions.Lock()
	defer uploadSessions.Unlock()
	if sess, ok := uploadSessions.sessions[sessionID]; ok {
		sess.Status = "failed"
		sess.Error = errMsg
	}
}

// uniqueFilePath returns a path that does not collide with existing files by
// appending a timestamp before the extension if needed.
func uniqueFilePath(path string) string {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return path
	}

	ext := filepath.Ext(path)
	base := strings.TrimSuffix(path, ext)
	stamp := time.Now().Format("20060102-150405")
	return fmt.Sprintf("%s_%s%s", base, stamp, ext)
}

// parseContentRange parses a Content-Range header of the form "bytes start-end/total".
func parseContentRange(header string) (start, end, total int64, err error) {
	// Expected format: "bytes 0-1023/10240" or "bytes 0-1023/*"
	header = strings.TrimPrefix(header, "bytes ")
	parts := strings.SplitN(header, "/", 2)
	if len(parts) != 2 {
		return 0, 0, 0, fmt.Errorf("malformed Content-Range: missing '/'")
	}

	rangeParts := strings.SplitN(parts[0], "-", 2)
	if len(rangeParts) != 2 {
		return 0, 0, 0, fmt.Errorf("malformed Content-Range: missing '-' in range")
	}

	start, err = strconv.ParseInt(strings.TrimSpace(rangeParts[0]), 10, 64)
	if err != nil {
		return 0, 0, 0, fmt.Errorf("invalid start byte: %v", err)
	}

	end, err = strconv.ParseInt(strings.TrimSpace(rangeParts[1]), 10, 64)
	if err != nil {
		return 0, 0, 0, fmt.Errorf("invalid end byte: %v", err)
	}

	totalStr := strings.TrimSpace(parts[1])
	if totalStr == "*" {
		total = -1 // Unknown total
	} else {
		total, err = strconv.ParseInt(totalStr, 10, 64)
		if err != nil {
			return 0, 0, 0, fmt.Errorf("invalid total: %v", err)
		}
	}

	return start, end, total, nil
}

// probeFileDuration attempts to get the duration of a video file using ffprobe.
// Returns duration in seconds, or 0 if probing fails.
func probeFileDuration(filePath string) int {
	ffprobeBin := "ffprobe"
	if path, err := exec.LookPath("ffprobe"); err == nil {
		ffprobeBin = path
	} else {
		return 0 // ffprobe not available
	}

	out, err := exec.Command(ffprobeBin,
		"-v", "quiet",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		filePath,
	).Output()
	if err != nil {
		return 0
	}

	durationStr := strings.TrimSpace(string(out))
	if durationStr == "" || durationStr == "N/A" {
		return 0
	}

	duration, err := strconv.ParseFloat(durationStr, 64)
	if err != nil {
		return 0
	}

	return int(duration)
}
