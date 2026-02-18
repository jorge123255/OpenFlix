package api

import (
	"fmt"
	"mime"
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

// ============ Offline Download Handlers ============

// requestOfflineDownload creates an offline download request for a media item
func (s *Server) requestOfflineDownload(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		MediaItemID uint   `json:"mediaItemId" binding:"required"`
		Quality     string `json:"quality"`
		DeviceID    string `json:"deviceId"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	// Default quality
	if req.Quality == "" {
		req.Quality = "original"
	}
	validQualities := map[string]bool{"original": true, "high": true, "medium": true, "low": true}
	if !validQualities[req.Quality] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid quality. Must be one of: original, high, medium, low"})
		return
	}

	// Default device ID
	if req.DeviceID == "" {
		req.DeviceID = "unknown"
	}

	// Look up the MediaItem
	var mediaItem models.MediaItem
	if err := s.db.Preload("MediaFiles").First(&mediaItem, req.MediaItemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	if len(mediaItem.MediaFiles) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "No media files available for this item"})
		return
	}

	// Pick the best media file (first one for now)
	mediaFile := mediaItem.MediaFiles[0]

	// Calculate estimated file size based on quality
	estimatedSize := mediaFile.FileSize
	switch req.Quality {
	case "high":
		estimatedSize = int64(float64(mediaFile.FileSize) * 0.7)
	case "medium":
		estimatedSize = int64(float64(mediaFile.FileSize) * 0.4)
	case "low":
		estimatedSize = int64(float64(mediaFile.FileSize) * 0.2)
	}

	// Read expiry days from settings, default 30
	expiryDays := 30
	var setting models.Setting
	if err := s.db.Where("key = ?", "offline_expiry_days").First(&setting).Error; err == nil {
		if days, err := strconv.Atoi(setting.Value); err == nil && days > 0 {
			expiryDays = days
		}
	}

	// Check max downloads per device
	maxDownloads := 25
	if err := s.db.Where("key = ?", "offline_max_downloads").First(&setting).Error; err == nil {
		if max, err := strconv.Atoi(setting.Value); err == nil && max > 0 {
			maxDownloads = max
		}
	}

	// Count existing active downloads for this device
	var activeCount int64
	s.db.Model(&models.OfflineDownload{}).
		Where("user_id = ? AND device_id = ? AND status IN ?", userID, req.DeviceID, []string{"pending", "downloading", "completed"}).
		Count(&activeCount)

	if int(activeCount) >= maxDownloads {
		c.JSON(http.StatusConflict, gin.H{
			"error":        fmt.Sprintf("Maximum downloads per device reached (%d)", maxDownloads),
			"maxDownloads": maxDownloads,
			"current":      activeCount,
		})
		return
	}

	download := models.OfflineDownload{
		UserID:      userID,
		DeviceID:    req.DeviceID,
		MediaItemID: req.MediaItemID,
		MediaFileID: mediaFile.ID,
		Title:       mediaItem.Title,
		Quality:     req.Quality,
		FileSize:    estimatedSize,
		Status:      "pending",
		Progress:    0,
		ExpiresAt:   time.Now().AddDate(0, 0, expiryDays),
	}

	if err := s.db.Create(&download).Error; err != nil {
		logger.Errorf("Failed to create offline download: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create download request"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":          download.ID,
		"downloadUrl": fmt.Sprintf("/api/offline/%d/stream", download.ID),
		"fileSize":    download.FileSize,
		"expiresAt":   download.ExpiresAt,
		"quality":     download.Quality,
		"title":       download.Title,
		"status":      download.Status,
	})
}

// listOfflineDownloads returns all offline downloads for the requesting user
func (s *Server) listOfflineDownloads(c *gin.Context) {
	userID := c.GetUint("userID")

	query := s.db.Where("user_id = ?", userID)

	// Filter by device
	if deviceID := c.Query("deviceId"); deviceID != "" {
		query = query.Where("device_id = ?", deviceID)
	}

	// Filter by status
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	query = query.Order("created_at DESC")

	var downloads []models.OfflineDownload
	if err := query.Find(&downloads).Error; err != nil {
		logger.Errorf("Failed to list offline downloads: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list downloads"})
		return
	}

	// Calculate totals
	var totalSize int64
	activeCount := 0
	for _, d := range downloads {
		totalSize += d.FileSize
		if d.Status == "pending" || d.Status == "downloading" || d.Status == "completed" {
			activeCount++
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"downloads":      downloads,
		"count":          len(downloads),
		"totalSize":      totalSize,
		"activeCount":    activeCount,
	})
}

// streamOfflineDownload serves the media file for an offline download
func (s *Server) streamOfflineDownload(c *gin.Context) {
	userID := c.GetUint("userID")

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid download ID"})
		return
	}

	var download models.OfflineDownload
	if err := s.db.First(&download, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Download not found"})
		return
	}

	// Verify ownership
	if download.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	// Check expiry
	if time.Now().After(download.ExpiresAt) {
		s.db.Model(&download).Update("status", "expired")
		c.JSON(http.StatusGone, gin.H{"error": "Download has expired"})
		return
	}

	// Get the media file
	var mediaFile models.MediaFile
	if err := s.db.First(&mediaFile, download.MediaFileID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media file not found"})
		return
	}

	// Handle remote files
	if mediaFile.IsRemote {
		// For remote streams, redirect to the remote URL
		if mediaFile.RemoteURL != "" {
			c.Redirect(http.StatusTemporaryRedirect, mediaFile.RemoteURL)
			return
		}
		c.JSON(http.StatusNotFound, gin.H{"error": "Remote stream URL not available"})
		return
	}

	// Check if local file exists
	if _, err := os.Stat(mediaFile.FilePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found on disk"})
		return
	}

	// Determine content type
	contentType := "video/mp4"
	ext := strings.ToLower(filepath.Ext(mediaFile.FilePath))
	if mimeType := mime.TypeByExtension(ext); mimeType != "" {
		contentType = mimeType
	} else {
		switch mediaFile.Container {
		case "mkv":
			contentType = "video/x-matroska"
		case "avi":
			contentType = "video/x-msvideo"
		case "mov":
			contentType = "video/quicktime"
		case "webm":
			contentType = "video/webm"
		case "ts", "m2ts":
			contentType = "video/mp2t"
		}
	}

	// Update status to downloading if still pending
	if download.Status == "pending" {
		s.db.Model(&download).Update("status", "downloading")
	}

	// Add note about transcoding for non-original quality
	if download.Quality != "original" {
		c.Header("X-Offline-Quality-Note", "Transcoded quality not yet available; serving original")
	}

	// Set headers for streaming with range support
	c.Header("Content-Type", contentType)
	c.Header("Accept-Ranges", "bytes")

	// Use http.ServeFile which handles Range requests automatically
	http.ServeFile(c.Writer, c.Request, mediaFile.FilePath)
}

// updateOfflineProgress updates the download progress from the client
func (s *Server) updateOfflineProgress(c *gin.Context) {
	userID := c.GetUint("userID")

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid download ID"})
		return
	}

	var download models.OfflineDownload
	if err := s.db.First(&download, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Download not found"})
		return
	}

	if download.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	var req struct {
		Progress float64 `json:"progress" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	if req.Progress < 0 || req.Progress > 1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Progress must be between 0.0 and 1.0"})
		return
	}

	updates := map[string]interface{}{
		"progress": req.Progress,
	}

	// Auto-set status based on progress
	if req.Progress >= 1.0 {
		updates["status"] = "completed"
	} else if req.Progress > 0 {
		updates["status"] = "downloading"
	}

	if err := s.db.Model(&download).Updates(updates).Error; err != nil {
		logger.Errorf("Failed to update offline progress: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update progress"})
		return
	}

	s.db.First(&download, id)
	c.JSON(http.StatusOK, gin.H{"download": download})
}

// syncOfflineWatchState syncs the watch state from the client back to the server
func (s *Server) syncOfflineWatchState(c *gin.Context) {
	userID := c.GetUint("userID")

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid download ID"})
		return
	}

	var download models.OfflineDownload
	if err := s.db.First(&download, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Download not found"})
		return
	}

	if download.UserID != userID {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	var req struct {
		WatchedPosition int64 `json:"watchedPosition"`
		Watched         bool  `json:"watched"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	// Update the offline download's watch state
	if err := s.db.Model(&download).Updates(map[string]interface{}{
		"watched_position": req.WatchedPosition,
		"watched":          req.Watched,
	}).Error; err != nil {
		logger.Errorf("Failed to sync offline watch state: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to sync watch state"})
		return
	}

	// Also sync back to the server's main WatchHistory
	var watchHistory models.WatchHistory
	result := s.db.Where("user_id = ? AND media_item_id = ?", userID, download.MediaItemID).First(&watchHistory)
	if result.Error != nil {
		// Create new watch history entry
		watchHistory = models.WatchHistory{
			UserID:       userID,
			MediaItemID:  download.MediaItemID,
			ViewOffset:   req.WatchedPosition,
			Completed:    req.Watched,
			LastViewedAt: time.Now(),
			ViewCount:    1,
		}
		s.db.Create(&watchHistory)
	} else {
		// Update existing watch history
		updates := map[string]interface{}{
			"view_offset":   req.WatchedPosition,
			"completed":     req.Watched,
			"last_viewed_at": time.Now(),
		}
		if req.Watched {
			updates["view_count"] = watchHistory.ViewCount + 1
		}
		s.db.Model(&watchHistory).Updates(updates)
	}

	s.db.First(&download, id)
	c.JSON(http.StatusOK, gin.H{
		"download": download,
		"message":  "Watch state synced",
	})
}

// deleteOfflineDownload removes or cancels an offline download
func (s *Server) deleteOfflineDownload(c *gin.Context) {
	userID := c.GetUint("userID")

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid download ID"})
		return
	}

	var download models.OfflineDownload
	if err := s.db.First(&download, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Download not found"})
		return
	}

	// Allow owner or admin to delete
	isAdmin, _ := c.Get("isAdmin")
	if download.UserID != userID && !(isAdmin != nil && isAdmin.(bool)) {
		c.JSON(http.StatusForbidden, gin.H{"error": "Access denied"})
		return
	}

	if err := s.db.Delete(&download).Error; err != nil {
		logger.Errorf("Failed to delete offline download %d: %v", id, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete download"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Download deleted"})
}

// getOfflineSettings returns the current offline download settings
func (s *Server) getOfflineSettings(c *gin.Context) {
	maxDownloads := 25
	expiryDays := 30
	allowedQualities := []string{"original", "high", "medium", "low"}

	var setting models.Setting
	if err := s.db.Where("key = ?", "offline_max_downloads").First(&setting).Error; err == nil {
		if max, err := strconv.Atoi(setting.Value); err == nil && max > 0 {
			maxDownloads = max
		}
	}
	if err := s.db.Where("key = ?", "offline_expiry_days").First(&setting).Error; err == nil {
		if days, err := strconv.Atoi(setting.Value); err == nil && days > 0 {
			expiryDays = days
		}
	}
	if err := s.db.Where("key = ?", "offline_allowed_qualities").First(&setting).Error; err == nil && setting.Value != "" {
		allowedQualities = strings.Split(setting.Value, ",")
	}

	c.JSON(http.StatusOK, gin.H{
		"maxDownloads":     maxDownloads,
		"expiryDays":       expiryDays,
		"allowedQualities": allowedQualities,
	})
}

// updateOfflineSettings updates the offline download settings (admin only)
func (s *Server) updateOfflineSettings(c *gin.Context) {
	var req struct {
		MaxDownloads     *int      `json:"maxDownloads"`
		ExpiryDays       *int      `json:"expiryDays"`
		AllowedQualities []string  `json:"allowedQualities"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	if req.MaxDownloads != nil {
		if *req.MaxDownloads < 1 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "maxDownloads must be at least 1"})
			return
		}
		s.db.Where("key = ?", "offline_max_downloads").Assign(models.Setting{
			Key: "offline_max_downloads", Value: strconv.Itoa(*req.MaxDownloads),
		}).FirstOrCreate(&models.Setting{})
	}

	if req.ExpiryDays != nil {
		if *req.ExpiryDays < 1 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "expiryDays must be at least 1"})
			return
		}
		s.db.Where("key = ?", "offline_expiry_days").Assign(models.Setting{
			Key: "offline_expiry_days", Value: strconv.Itoa(*req.ExpiryDays),
		}).FirstOrCreate(&models.Setting{})
	}

	if len(req.AllowedQualities) > 0 {
		validOptions := map[string]bool{"original": true, "high": true, "medium": true, "low": true}
		for _, q := range req.AllowedQualities {
			if !validOptions[q] {
				c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid quality: %s", q)})
				return
			}
		}
		s.db.Where("key = ?", "offline_allowed_qualities").Assign(models.Setting{
			Key: "offline_allowed_qualities", Value: strings.Join(req.AllowedQualities, ","),
		}).FirstOrCreate(&models.Setting{})
	}

	// Return updated settings
	s.getOfflineSettings(c)
}
