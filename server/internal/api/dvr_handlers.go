package api

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ DVR Recordings ============

// getRecordings returns all recordings for the user
func (s *Server) getRecordings(c *gin.Context) {
	userID := c.GetUint("userID")

	query := s.db.Where("user_id = ?", userID)

	// Filter by status
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	var recordings []models.Recording
	if err := query.Order("start_time DESC").Find(&recordings).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch recordings"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"recordings": recordings})
}

// scheduleRecording creates a new recording
func (s *Server) scheduleRecording(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		ChannelID   uint      `json:"channelId" binding:"required"`
		ProgramID   *uint     `json:"programId"`
		Title       string    `json:"title" binding:"required"`
		Description string    `json:"description"`
		StartTime   time.Time `json:"startTime" binding:"required"`
		EndTime     time.Time `json:"endTime" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate channel exists
	var channel models.Channel
	if err := s.db.First(&channel, req.ChannelID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Channel not found"})
		return
	}

	recording := models.Recording{
		UserID:      userID,
		ChannelID:   req.ChannelID,
		ProgramID:   req.ProgramID,
		Title:       req.Title,
		Description: req.Description,
		StartTime:   req.StartTime,
		EndTime:     req.EndTime,
		Status:      "scheduled",
	}

	if err := s.db.Create(&recording).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create recording"})
		return
	}

	c.JSON(http.StatusCreated, recording)
}

// getRecording returns a single recording
func (s *Server) getRecording(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	var recording models.Recording
	if err := s.db.Where("user_id = ?", userID).First(&recording, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	c.JSON(http.StatusOK, recording)
}

// deleteRecording deletes a recording
func (s *Server) deleteRecording(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	var recording models.Recording
	if err := s.db.Where("user_id = ?", userID).First(&recording, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	// If recording is in progress, we'd need to stop it
	// For now, just mark as cancelled if scheduled, or delete if completed/failed
	if recording.Status == "recording" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot delete recording in progress"})
		return
	}

	if err := s.db.Delete(&recording).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete recording"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Recording deleted"})
}

// ============ Series Rules ============

// getSeriesRules returns all series recording rules for the user
func (s *Server) getSeriesRules(c *gin.Context) {
	userID := c.GetUint("userID")

	var rules []models.SeriesRule
	if err := s.db.Where("user_id = ?", userID).Find(&rules).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch series rules"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"rules": rules})
}

// createSeriesRule creates a new series recording rule
func (s *Server) createSeriesRule(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		Title       string `json:"title" binding:"required"`
		ChannelID   *uint  `json:"channelId"`
		Keywords    string `json:"keywords"`
		TimeSlot    string `json:"timeSlot"`
		DaysOfWeek  string `json:"daysOfWeek"`
		KeepCount   int    `json:"keepCount"`
		PrePadding  int    `json:"prePadding"`
		PostPadding int    `json:"postPadding"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	rule := models.SeriesRule{
		UserID:      userID,
		Title:       req.Title,
		ChannelID:   req.ChannelID,
		Keywords:    req.Keywords,
		TimeSlot:    req.TimeSlot,
		DaysOfWeek:  req.DaysOfWeek,
		KeepCount:   req.KeepCount,
		PrePadding:  req.PrePadding,
		PostPadding: req.PostPadding,
		Enabled:     true,
	}

	if err := s.db.Create(&rule).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create series rule"})
		return
	}

	c.JSON(http.StatusCreated, rule)
}

// updateSeriesRule updates a series recording rule
func (s *Server) updateSeriesRule(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}

	var rule models.SeriesRule
	if err := s.db.Where("user_id = ?", userID).First(&rule, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Series rule not found"})
		return
	}

	var req struct {
		Title       string `json:"title"`
		ChannelID   *uint  `json:"channelId"`
		Keywords    string `json:"keywords"`
		TimeSlot    string `json:"timeSlot"`
		DaysOfWeek  string `json:"daysOfWeek"`
		KeepCount   *int   `json:"keepCount"`
		PrePadding  *int   `json:"prePadding"`
		PostPadding *int   `json:"postPadding"`
		Enabled     *bool  `json:"enabled"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Title != "" {
		rule.Title = req.Title
	}
	if req.ChannelID != nil {
		rule.ChannelID = req.ChannelID
	}
	if req.Keywords != "" {
		rule.Keywords = req.Keywords
	}
	if req.TimeSlot != "" {
		rule.TimeSlot = req.TimeSlot
	}
	if req.DaysOfWeek != "" {
		rule.DaysOfWeek = req.DaysOfWeek
	}
	if req.KeepCount != nil {
		rule.KeepCount = *req.KeepCount
	}
	if req.PrePadding != nil {
		rule.PrePadding = *req.PrePadding
	}
	if req.PostPadding != nil {
		rule.PostPadding = *req.PostPadding
	}
	if req.Enabled != nil {
		rule.Enabled = *req.Enabled
	}

	if err := s.db.Save(&rule).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update series rule"})
		return
	}

	c.JSON(http.StatusOK, rule)
}

// deleteSeriesRule deletes a series recording rule
func (s *Server) deleteSeriesRule(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid rule ID"})
		return
	}

	var rule models.SeriesRule
	if err := s.db.Where("user_id = ?", userID).First(&rule, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Series rule not found"})
		return
	}

	if err := s.db.Delete(&rule).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete series rule"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Series rule deleted"})
}

// ============ Commercial Detection ============

// getCommercialSegments returns commercial segments for a recording
func (s *Server) getCommercialSegments(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	// Verify user owns this recording
	var recording models.Recording
	if err := s.db.Where("user_id = ?", userID).First(&recording, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	// Get commercial segments
	var segments []models.CommercialSegment
	if err := s.db.Where("recording_id = ?", id).Order("start_time").Find(&segments).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch commercial segments"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"recordingId":       id,
		"segments":          segments,
		"totalCommercials":  len(segments),
		"commercialSeconds": calculateTotalCommercialTime(segments),
	})
}

// rerunCommercialDetection triggers commercial detection on an existing recording
func (s *Server) rerunCommercialDetection(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	// Verify user owns this recording
	var recording models.Recording
	if err := s.db.Where("user_id = ?", userID).First(&recording, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	if recording.Status != "completed" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Recording must be completed to run commercial detection"})
		return
	}

	// Check if recorder has commercial detection enabled
	if s.recorder == nil || !s.recorder.IsCommercialDetectionEnabled() {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Commercial detection is not available"})
		return
	}

	// Delete existing segments and rerun
	s.db.Where("recording_id = ?", id).Delete(&models.CommercialSegment{})

	// Trigger detection asynchronously
	if err := s.recorder.RerunCommercialDetection(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusAccepted, gin.H{
		"message":     "Commercial detection started",
		"recordingId": id,
	})
}

// getCommercialDetectionStatus returns whether commercial detection is available
func (s *Server) getCommercialDetectionStatus(c *gin.Context) {
	enabled := s.recorder != nil && s.recorder.IsCommercialDetectionEnabled()

	c.JSON(http.StatusOK, gin.H{
		"enabled": enabled,
	})
}

// calculateTotalCommercialTime sums up the duration of all commercial segments
func calculateTotalCommercialTime(segments []models.CommercialSegment) float64 {
	var total float64
	for _, seg := range segments {
		total += seg.Duration
	}
	return total
}

// streamRecording streams a completed DVR recording file
func (s *Server) streamRecording(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	// Verify user owns this recording
	var recording models.Recording
	if err := s.db.Where("user_id = ?", userID).First(&recording, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	if recording.Status != "completed" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Recording is not completed"})
		return
	}

	if recording.FilePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording file not found"})
		return
	}

	// Serve the file
	c.File(recording.FilePath)
}
