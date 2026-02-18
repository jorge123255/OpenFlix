package api

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// SkipMarker represents a skip marker returned to the player
type SkipMarker struct {
	Type      string  `json:"type"`      // intro, outro, credits, commercial
	StartTime float64 `json:"startTime"` // seconds from beginning
	EndTime   float64 `json:"endTime"`   // seconds from beginning
	Action    string  `json:"action"`    // "skip" (auto-skip) or "prompt" (show button)
}

// SkipSettings represents a user's skip preferences
type SkipSettings struct {
	SkipIntroBehavior   string `json:"skipIntroBehavior"`   // auto_skip, show_button, disabled
	SkipCreditsBehavior string `json:"skipCreditsBehavior"` // auto_skip, show_button, disabled
	SkipOutroBehavior   string `json:"skipOutroBehavior"`   // auto_skip, show_button, disabled
	SkipButtonDuration  int    `json:"skipButtonDuration"`  // seconds to show skip button
}

// Default skip settings
var defaultSkipSettings = SkipSettings{
	SkipIntroBehavior:   "show_button",
	SkipCreditsBehavior: "show_button",
	SkipOutroBehavior:   "disabled",
	SkipButtonDuration:  10,
}

// Valid behavior values for skip settings
var validSkipBehaviors = map[string]bool{
	"auto_skip":   true,
	"show_button": true,
	"disabled":    true,
}

// getSkipMarkers returns all skip markers (intro/outro/credits) for a DVR file.
// GET /api/playback/:fileId/markers
func (s *Server) getSkipMarkers(c *gin.Context) {
	fileIDStr := c.Param("fileId")
	fileID, err := strconv.ParseUint(fileIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	// Verify file exists
	var file models.DVRFile
	if err := s.db.First(&file, fileID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	// Get detected segments for this file
	var segments []models.DetectedSegment
	if err := s.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&segments).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query segments"})
		return
	}

	// Get user skip settings to determine action per segment type
	userID, _ := c.Get("userID")
	settings := s.getUserSkipSettings(userID)

	// Convert segments to skip markers
	markers := make([]SkipMarker, 0, len(segments))
	for _, seg := range segments {
		action := s.resolveSkipAction(seg.Type, settings)
		if action == "" {
			// disabled - don't include this marker
			continue
		}
		markers = append(markers, SkipMarker{
			Type:      seg.Type,
			StartTime: seg.StartTime,
			EndTime:   seg.EndTime,
			Action:    action,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"fileId":             fileID,
		"markers":            markers,
		"skipButtonDuration": settings.SkipButtonDuration,
	})
}

// getLibrarySkipMarkers returns skip markers for a library media item.
// GET /api/playback/:mediaId/markers/library
// Looks up MediaFile -> finds associated DVRFile -> checks for detected segments.
func (s *Server) getLibrarySkipMarkers(c *gin.Context) {
	mediaIDStr := c.Param("mediaId")
	mediaID, err := strconv.ParseUint(mediaIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid media ID"})
		return
	}

	// Get media files for this media item
	var mediaFiles []models.MediaFile
	if err := s.db.Where("media_item_id = ?", mediaID).Find(&mediaFiles).Error; err != nil || len(mediaFiles) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "No media files found for this item"})
		return
	}

	// Try to find detected segments via DVRFile matching by file path
	userID, _ := c.Get("userID")
	settings := s.getUserSkipSettings(userID)

	type FileMarkers struct {
		FileID  uint         `json:"fileId"`
		Markers []SkipMarker `json:"markers"`
	}

	result := make([]FileMarkers, 0)

	for _, mf := range mediaFiles {
		// Look for a DVRFile with a matching file path
		var dvrFile models.DVRFile
		if err := s.db.Where("file_path = ?", mf.FilePath).First(&dvrFile).Error; err != nil {
			// No DVR file match for this media file - check by media file ID directly
			// Some segments may be stored against the media file ID
			var segments []models.DetectedSegment
			s.db.Where("file_id = ?", mf.ID).Order("start_time ASC").Find(&segments)
			if len(segments) > 0 {
				markers := s.segmentsToMarkers(segments, settings)
				if len(markers) > 0 {
					result = append(result, FileMarkers{
						FileID:  mf.ID,
						Markers: markers,
					})
				}
			}
			continue
		}

		// Found DVR file - get its segments
		var segments []models.DetectedSegment
		s.db.Where("file_id = ?", dvrFile.ID).Order("start_time ASC").Find(&segments)
		if len(segments) > 0 {
			markers := s.segmentsToMarkers(segments, settings)
			if len(markers) > 0 {
				result = append(result, FileMarkers{
					FileID:  mf.ID,
					Markers: markers,
				})
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"mediaId":            mediaID,
		"files":              result,
		"skipButtonDuration": settings.SkipButtonDuration,
	})
}

// reportSkip records that a user skipped a segment (for analytics/tuning).
// POST /api/playback/:fileId/skip
func (s *Server) reportSkip(c *gin.Context) {
	fileIDStr := c.Param("fileId")
	fileID, err := strconv.ParseUint(fileIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var req struct {
		SegmentType string `json:"segmentType" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: segmentType is required"})
		return
	}

	// Validate segment type
	validTypes := map[string]bool{"intro": true, "outro": true, "credits": true, "commercial": true}
	if !validTypes[req.SegmentType] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid segment type. Must be one of: intro, outro, credits, commercial"})
		return
	}

	userID, _ := c.Get("userID")
	uid, _ := userID.(uint)

	event := models.SkipEvent{
		UserID:      uid,
		FileID:      uint(fileID),
		SegmentType: req.SegmentType,
		SkippedAt:   time.Now(),
	}

	if err := s.db.Create(&event).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to record skip event"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Skip event recorded",
		"eventId": event.ID,
	})
}

// getSkipSettings returns the user's skip preferences.
// GET /api/playback/skip-settings
func (s *Server) getSkipSettings(c *gin.Context) {
	userID, _ := c.Get("userID")
	settings := s.getUserSkipSettings(userID)

	c.JSON(http.StatusOK, settings)
}

// updateSkipSettings updates the user's skip preferences.
// PUT /api/playback/skip-settings
func (s *Server) updateSkipSettings(c *gin.Context) {
	var req SkipSettings
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	userID, _ := c.Get("userID")
	uid, _ := userID.(uint)
	prefix := fmt.Sprintf("user:%d:", uid)

	// Validate and save each field if provided
	if req.SkipIntroBehavior != "" {
		if !validSkipBehaviors[req.SkipIntroBehavior] {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid skipIntroBehavior. Must be one of: auto_skip, show_button, disabled"})
			return
		}
		s.setSetting(prefix+"skip_intro_behavior", req.SkipIntroBehavior)
	}

	if req.SkipCreditsBehavior != "" {
		if !validSkipBehaviors[req.SkipCreditsBehavior] {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid skipCreditsBehavior. Must be one of: auto_skip, show_button, disabled"})
			return
		}
		s.setSetting(prefix+"skip_credits_behavior", req.SkipCreditsBehavior)
	}

	if req.SkipOutroBehavior != "" {
		if !validSkipBehaviors[req.SkipOutroBehavior] {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid skipOutroBehavior. Must be one of: auto_skip, show_button, disabled"})
			return
		}
		s.setSetting(prefix+"skip_outro_behavior", req.SkipOutroBehavior)
	}

	if req.SkipButtonDuration > 0 {
		if req.SkipButtonDuration < 1 || req.SkipButtonDuration > 60 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "skipButtonDuration must be between 1 and 60 seconds"})
			return
		}
		s.setSetting(prefix+"skip_button_duration", strconv.Itoa(req.SkipButtonDuration))
	}

	// Return the updated settings
	updatedSettings := s.getUserSkipSettings(userID)
	c.JSON(http.StatusOK, gin.H{
		"message":  "Skip settings updated",
		"settings": updatedSettings,
	})
}

// getUserSkipSettings retrieves skip preferences for a specific user from the settings table.
func (s *Server) getUserSkipSettings(userID interface{}) SkipSettings {
	uid, _ := userID.(uint)
	prefix := fmt.Sprintf("user:%d:", uid)

	settings := defaultSkipSettings

	// Read each setting with fallback to defaults
	if v := s.getSettingString(prefix+"skip_intro_behavior", ""); v != "" {
		settings.SkipIntroBehavior = v
	}
	if v := s.getSettingString(prefix+"skip_credits_behavior", ""); v != "" {
		settings.SkipCreditsBehavior = v
	}
	if v := s.getSettingString(prefix+"skip_outro_behavior", ""); v != "" {
		settings.SkipOutroBehavior = v
	}
	if v := s.getSettingInt(prefix+"skip_button_duration", 0); v > 0 {
		settings.SkipButtonDuration = v
	}

	return settings
}

// getSettingString reads a string setting from the database.
func (s *Server) getSettingString(key string, defaultVal string) string {
	var setting models.Setting
	if err := s.db.Where("key = ?", key).First(&setting).Error; err != nil {
		return defaultVal
	}
	return setting.Value
}

// resolveSkipAction determines the action ("skip", "prompt", or "") for a segment type
// based on the user's skip settings.
func (s *Server) resolveSkipAction(segmentType string, settings SkipSettings) string {
	var behavior string

	switch segmentType {
	case "intro":
		behavior = settings.SkipIntroBehavior
	case "credits":
		behavior = settings.SkipCreditsBehavior
	case "outro":
		behavior = settings.SkipOutroBehavior
	case "commercial":
		// Commercials always use auto-skip when detected
		return "skip"
	default:
		return "prompt"
	}

	switch behavior {
	case "auto_skip":
		return "skip"
	case "show_button":
		return "prompt"
	case "disabled":
		return ""
	default:
		return "prompt"
	}
}

// segmentsToMarkers converts DetectedSegment slice to SkipMarker slice, filtering by user settings.
func (s *Server) segmentsToMarkers(segments []models.DetectedSegment, settings SkipSettings) []SkipMarker {
	markers := make([]SkipMarker, 0, len(segments))
	for _, seg := range segments {
		action := s.resolveSkipAction(seg.Type, settings)
		if action == "" {
			continue
		}
		markers = append(markers, SkipMarker{
			Type:      seg.Type,
			StartTime: seg.StartTime,
			EndTime:   seg.EndTime,
			Action:    action,
		})
	}
	return markers
}

// getSkipMarkersForFile is a helper that returns skip markers for a given file ID.
// Used by the playback decision endpoint to embed markers in its response.
func (s *Server) getSkipMarkersForFile(fileID uint, userID interface{}) []SkipMarker {
	var segments []models.DetectedSegment
	if err := s.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&segments).Error; err != nil {
		return nil
	}

	if len(segments) == 0 {
		return nil
	}

	settings := s.getUserSkipSettings(userID)
	return s.segmentsToMarkers(segments, settings)
}
