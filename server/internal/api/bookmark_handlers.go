package api

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Bookmark Handlers ============

// listBookmarks returns all bookmarks for the current user, with optional filters
func (s *Server) listBookmarks(c *gin.Context) {
	userID := c.GetUint("userID")

	query := s.db.Where("user_id = ?", userID)

	// Filter by source reference
	if fileID := c.Query("fileId"); fileID != "" {
		if id, err := strconv.ParseUint(fileID, 10, 32); err == nil {
			query = query.Where("file_id = ?", id)
		}
	}
	if recordingID := c.Query("recordingId"); recordingID != "" {
		if id, err := strconv.ParseUint(recordingID, 10, 32); err == nil {
			query = query.Where("recording_id = ?", id)
		}
	}
	if mediaItemID := c.Query("mediaItemId"); mediaItemID != "" {
		if id, err := strconv.ParseUint(mediaItemID, 10, 32); err == nil {
			query = query.Where("media_item_id = ?", id)
		}
	}

	// Filter by tags
	if tags := c.Query("tags"); tags != "" {
		for _, tag := range strings.Split(tags, ",") {
			tag = strings.TrimSpace(tag)
			if tag != "" {
				query = query.Where("tags LIKE ?", "%"+tag+"%")
			}
		}
	}

	// Search by title or note
	if search := c.Query("search"); search != "" {
		query = query.Where("title LIKE ? OR note LIKE ?", "%"+search+"%", "%"+search+"%")
	}

	// Sorting
	sortBy := c.DefaultQuery("sort", "created_at")
	sortOrder := c.DefaultQuery("order", "desc")
	if sortOrder != "asc" && sortOrder != "desc" {
		sortOrder = "desc"
	}
	switch sortBy {
	case "title":
		query = query.Order("title " + sortOrder)
	case "timestamp":
		query = query.Order("timestamp " + sortOrder)
	default:
		query = query.Order("created_at " + sortOrder)
	}

	var bookmarks []models.Bookmark
	if err := query.Find(&bookmarks).Error; err != nil {
		logger.Errorf("Failed to list bookmarks: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list bookmarks"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"bookmarks": bookmarks,
		"count":     len(bookmarks),
	})
}

// createBookmark creates a new bookmark with optional auto-generated thumbnail
func (s *Server) createBookmark(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		FileID      *uint   `json:"fileId"`
		RecordingID *uint   `json:"recordingId"`
		MediaItemID *uint   `json:"mediaItemId"`
		Title       string  `json:"title" binding:"required"`
		Note        string  `json:"note"`
		Timestamp   float64 `json:"timestamp" binding:"required"`
		Tags        string  `json:"tags"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	// Validate at least one source reference
	if (req.FileID == nil || *req.FileID == 0) &&
		(req.RecordingID == nil || *req.RecordingID == 0) &&
		(req.MediaItemID == nil || *req.MediaItemID == 0) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "At least one of fileId, recordingId, or mediaItemId is required"})
		return
	}

	if req.Timestamp < 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Timestamp must be non-negative"})
		return
	}

	bookmark := models.Bookmark{
		UserID:      userID,
		FileID:      req.FileID,
		RecordingID: req.RecordingID,
		MediaItemID: req.MediaItemID,
		Title:       req.Title,
		Note:        req.Note,
		Timestamp:   req.Timestamp,
		Tags:        req.Tags,
	}

	if err := s.db.Create(&bookmark).Error; err != nil {
		logger.Errorf("Failed to create bookmark: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create bookmark"})
		return
	}

	// Auto-generate thumbnail in background if clipManager is available
	if s.clipManager != nil {
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()

			sourcePath, err := s.clipManager.GetSourcePath(req.FileID, req.RecordingID, req.MediaItemID)
			if err != nil {
				logger.Warnf("Cannot generate thumbnail for bookmark %d: %v", bookmark.ID, err)
				return
			}

			thumbPath, err := s.clipManager.GenerateThumbnail(ctx, sourcePath, req.Timestamp)
			if err != nil {
				logger.Warnf("Thumbnail generation failed for bookmark %d: %v", bookmark.ID, err)
				return
			}

			s.db.Model(&bookmark).Update("thumbnail", thumbPath)
			logger.Infof("Thumbnail generated for bookmark %d: %s", bookmark.ID, thumbPath)
		}()
	}

	c.JSON(http.StatusCreated, gin.H{"bookmark": bookmark})
}

// getBookmark returns a single bookmark by ID
func (s *Server) getBookmark(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid bookmark ID"})
		return
	}

	var bookmark models.Bookmark
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&bookmark).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Bookmark not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"bookmark": bookmark})
}

// updateBookmark updates an existing bookmark's title, note, or tags
func (s *Server) updateBookmark(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid bookmark ID"})
		return
	}

	var bookmark models.Bookmark
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&bookmark).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Bookmark not found"})
		return
	}

	var req struct {
		Title     *string  `json:"title"`
		Note      *string  `json:"note"`
		Tags      *string  `json:"tags"`
		Timestamp *float64 `json:"timestamp"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	updates := map[string]interface{}{}
	if req.Title != nil {
		updates["title"] = *req.Title
	}
	if req.Note != nil {
		updates["note"] = *req.Note
	}
	if req.Tags != nil {
		updates["tags"] = *req.Tags
	}
	if req.Timestamp != nil {
		if *req.Timestamp < 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Timestamp must be non-negative"})
			return
		}
		updates["timestamp"] = *req.Timestamp
	}

	if len(updates) == 0 {
		c.JSON(http.StatusOK, gin.H{"bookmark": bookmark})
		return
	}

	if err := s.db.Model(&bookmark).Updates(updates).Error; err != nil {
		logger.Errorf("Failed to update bookmark %d: %v", id, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update bookmark"})
		return
	}

	// Reload to get updated fields
	s.db.First(&bookmark, id)

	c.JSON(http.StatusOK, gin.H{"bookmark": bookmark})
}

// deleteBookmark deletes a bookmark and its associated thumbnail
func (s *Server) deleteBookmark(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid bookmark ID"})
		return
	}

	var bookmark models.Bookmark
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&bookmark).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Bookmark not found"})
		return
	}

	// Delete thumbnail file if it exists
	if bookmark.Thumbnail != "" {
		if err := os.Remove(bookmark.Thumbnail); err != nil && !os.IsNotExist(err) {
			logger.Warnf("Failed to delete thumbnail for bookmark %d: %v", id, err)
		}
	}

	if err := s.db.Delete(&bookmark).Error; err != nil {
		logger.Errorf("Failed to delete bookmark %d: %v", id, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete bookmark"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Bookmark deleted"})
}

// ============ Clip Handlers ============

// listClips returns all clips for the current user
func (s *Server) listClips(c *gin.Context) {
	userID := c.GetUint("userID")

	query := s.db.Where("user_id = ?", userID)

	// Filter by status
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	// Filter by source reference
	if fileID := c.Query("fileId"); fileID != "" {
		if id, err := strconv.ParseUint(fileID, 10, 32); err == nil {
			query = query.Where("file_id = ?", id)
		}
	}
	if recordingID := c.Query("recordingId"); recordingID != "" {
		if id, err := strconv.ParseUint(recordingID, 10, 32); err == nil {
			query = query.Where("recording_id = ?", id)
		}
	}
	if mediaItemID := c.Query("mediaItemId"); mediaItemID != "" {
		if id, err := strconv.ParseUint(mediaItemID, 10, 32); err == nil {
			query = query.Where("media_item_id = ?", id)
		}
	}

	// Filter by format
	if format := c.Query("format"); format != "" {
		query = query.Where("format = ?", format)
	}

	// Sorting
	sortBy := c.DefaultQuery("sort", "created_at")
	sortOrder := c.DefaultQuery("order", "desc")
	if sortOrder != "asc" && sortOrder != "desc" {
		sortOrder = "desc"
	}
	switch sortBy {
	case "title":
		query = query.Order("title " + sortOrder)
	case "duration":
		query = query.Order("duration " + sortOrder)
	case "status":
		query = query.Order("status " + sortOrder)
	default:
		query = query.Order("created_at " + sortOrder)
	}

	var clips []models.Clip
	if err := query.Find(&clips).Error; err != nil {
		logger.Errorf("Failed to list clips: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list clips"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"clips": clips,
		"count": len(clips),
	})
}

// createClip creates a new clip and starts async extraction
func (s *Server) createClip(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		FileID      *uint   `json:"fileId"`
		RecordingID *uint   `json:"recordingId"`
		MediaItemID *uint   `json:"mediaItemId"`
		Title       string  `json:"title" binding:"required"`
		Note        string  `json:"note"`
		StartTime   float64 `json:"startTime" binding:"required"`
		EndTime     float64 `json:"endTime" binding:"required"`
		Format      string  `json:"format"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	// Validate at least one source reference
	if (req.FileID == nil || *req.FileID == 0) &&
		(req.RecordingID == nil || *req.RecordingID == 0) &&
		(req.MediaItemID == nil || *req.MediaItemID == 0) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "At least one of fileId, recordingId, or mediaItemId is required"})
		return
	}

	if req.StartTime < 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "StartTime must be non-negative"})
		return
	}
	if req.EndTime <= req.StartTime {
		c.JSON(http.StatusBadRequest, gin.H{"error": "EndTime must be greater than startTime"})
		return
	}

	// Validate format
	format := req.Format
	if format == "" {
		format = "mp4"
	}
	if format != "mp4" && format != "gif" && format != "webm" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Format must be mp4, gif, or webm"})
		return
	}

	// Check clipManager is available
	if s.clipManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Clip extraction is not available"})
		return
	}

	// Validate source path exists before creating the clip
	sourcePath, err := s.clipManager.GetSourcePath(req.FileID, req.RecordingID, req.MediaItemID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Source not found: " + err.Error()})
		return
	}

	if _, err := os.Stat(sourcePath); os.IsNotExist(err) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Source file not found on disk"})
		return
	}

	duration := req.EndTime - req.StartTime

	clip := models.Clip{
		UserID:      userID,
		FileID:      req.FileID,
		RecordingID: req.RecordingID,
		MediaItemID: req.MediaItemID,
		Title:       req.Title,
		Note:        req.Note,
		StartTime:   req.StartTime,
		EndTime:     req.EndTime,
		Duration:    duration,
		Format:      format,
		Status:      "pending",
	}

	if err := s.db.Create(&clip).Error; err != nil {
		logger.Errorf("Failed to create clip: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create clip"})
		return
	}

	// Start async extraction
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
		defer cancel()

		if err := s.clipManager.ExtractClip(ctx, &clip, sourcePath); err != nil {
			logger.Errorf("Clip %d extraction failed: %v", clip.ID, err)
		}
	}()

	// Return 202 Accepted - clip is being processed
	c.JSON(http.StatusAccepted, gin.H{
		"clip":    clip,
		"message": "Clip extraction started",
	})
}

// getClip returns a single clip by ID, including current status
func (s *Server) getClip(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid clip ID"})
		return
	}

	var clip models.Clip
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&clip).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Clip not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"clip": clip})
}

// deleteClip deletes a clip and its associated file on disk
func (s *Server) deleteClip(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid clip ID"})
		return
	}

	var clip models.Clip
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&clip).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Clip not found"})
		return
	}

	// Delete the clip file from disk if it exists
	if clip.FilePath != "" {
		if err := os.Remove(clip.FilePath); err != nil && !os.IsNotExist(err) {
			logger.Warnf("Failed to delete clip file %s: %v", clip.FilePath, err)
		} else if err == nil {
			logger.Infof("Deleted clip file: %s", clip.FilePath)
		}
	}

	if err := s.db.Delete(&clip).Error; err != nil {
		logger.Errorf("Failed to delete clip %d: %v", id, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete clip"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Clip deleted"})
}

// downloadClip serves the extracted clip file as a download
func (s *Server) downloadClip(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid clip ID"})
		return
	}

	var clip models.Clip
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&clip).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Clip not found"})
		return
	}

	if clip.Status != "ready" {
		c.JSON(http.StatusConflict, gin.H{
			"error":  fmt.Sprintf("Clip is not ready (status: %s)", clip.Status),
			"status": clip.Status,
		})
		return
	}

	if clip.FilePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Clip file path is empty"})
		return
	}

	if _, err := os.Stat(clip.FilePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Clip file not found on disk"})
		return
	}

	// Determine content type based on format
	contentType := "video/mp4"
	switch clip.Format {
	case "gif":
		contentType = "image/gif"
	case "webm":
		contentType = "video/webm"
	}

	filename := filepath.Base(clip.FilePath)
	c.Header("Content-Description", "File Transfer")
	c.Header("Content-Transfer-Encoding", "binary")
	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", contentType)
	c.File(clip.FilePath)
}

// streamClip streams the extracted clip file for playback
func (s *Server) streamClip(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid clip ID"})
		return
	}

	var clip models.Clip
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&clip).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Clip not found"})
		return
	}

	if clip.Status != "ready" {
		c.JSON(http.StatusConflict, gin.H{
			"error":  fmt.Sprintf("Clip is not ready (status: %s)", clip.Status),
			"status": clip.Status,
		})
		return
	}

	if clip.FilePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Clip file path is empty"})
		return
	}

	if _, err := os.Stat(clip.FilePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Clip file not found on disk"})
		return
	}

	// Serve the file with range support (for seeking)
	c.File(clip.FilePath)
}
