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
	"gorm.io/gorm"
)

// ============ DVR Recordings ============

// getRecordings returns all recordings for the user
func (s *Server) getRecordings(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")

	// Admins see all recordings, users see their own and system (user_id=0) recordings
	var query *gorm.DB
	if isAdmin {
		query = s.db.Model(&models.Recording{})
	} else {
		query = s.db.Where("user_id IN ?", []uint{userID, 0})
	}

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
		Category    string    `json:"category"`
		EpisodeNum  string    `json:"episodeNum"`
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
		Category:    req.Category,
		EpisodeNum:  req.EpisodeNum,
		ChannelName: channel.Name,
		ChannelLogo: channel.Logo,
	}

	if err := s.db.Create(&recording).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create recording"})
		return
	}

	// Enrich recording with TMDB metadata in background
	if s.dvrEnricher != nil {
		go func() {
			if err := s.dvrEnricher.EnrichRecording(&recording); err != nil {
				logger.WithError(err).WithField("recordingId", recording.ID).Warn("Failed to enrich recording")
			}
		}()
	}

	c.JSON(http.StatusCreated, recording)
}

// recordFromProgram creates a recording from an EPG program
func (s *Server) recordFromProgram(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		ChannelID    uint `json:"channelId" binding:"required"`
		ProgramID    uint `json:"programId" binding:"required"`
		SeriesRecord bool `json:"seriesRecord"`
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

	// Get the program
	var program models.Program
	if err := s.db.First(&program, req.ProgramID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Program not found"})
		return
	}

	// Check for conflicts before creating
	var conflicts []models.Recording
	s.db.Where("user_id = ? AND status IN ? AND start_time < ? AND end_time > ?",
		userID, []string{"scheduled", "recording"}, program.End, program.Start).Find(&conflicts)

	// Create the recording with program metadata
	recording := models.Recording{
		UserID:       userID,
		ChannelID:    req.ChannelID,
		ProgramID:    &req.ProgramID,
		Title:        program.Title,
		Subtitle:     program.Subtitle,
		Description:  program.Description,
		StartTime:    program.Start,
		EndTime:      program.End,
		Status:       "scheduled",
		SeriesRecord: req.SeriesRecord,
		Category:     program.Category,
		EpisodeNum:   program.EpisodeNum,
		Thumb:        program.Icon,        // Use program icon as initial thumb
		Art:          program.Art,         // Use program art if available
		ChannelName:  channel.Name,
		ChannelLogo:  channel.Logo,
		IsMovie:      program.IsMovie,
	}

	if err := s.db.Create(&recording).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create recording"})
		return
	}

	// Enrich recording with TMDB metadata in background (to get higher quality artwork)
	if s.dvrEnricher != nil {
		go func() {
			if err := s.dvrEnricher.EnrichRecording(&recording); err != nil {
				logger.WithError(err).WithField("recordingId", recording.ID).Warn("Failed to enrich recording")
			}
		}()
	}

	// If series recording is requested, schedule future episodes
	if req.SeriesRecord && program.Title != "" {
		go s.scheduleFutureSeriesRecordings(userID, channel.ChannelID, program.Title, recording.ID)
	}

	// Include conflict information in response
	response := gin.H{
		"id":           recording.ID,
		"title":        recording.Title,
		"subtitle":     recording.Subtitle,
		"description":  recording.Description,
		"channelId":    recording.ChannelID,
		"channelName":  recording.ChannelName,
		"startTime":    recording.StartTime,
		"endTime":      recording.EndTime,
		"status":       recording.Status,
		"seriesRecord": recording.SeriesRecord,
		"thumb":        recording.Thumb,
		"art":          recording.Art,
		"hasConflict":  len(conflicts) > 0,
		"conflicts":    conflicts,
	}

	c.JSON(http.StatusCreated, response)
}

// scheduleFutureSeriesRecordings finds and schedules future episodes of a series
func (s *Server) scheduleFutureSeriesRecordings(userID uint, channelID string, seriesTitle string, parentRecordingID uint) {
	// Find future programs with the same title on this channel
	var futurePrograms []models.Program
	s.db.Where("channel_id = ? AND title = ? AND start > ?", channelID, seriesTitle, time.Now()).
		Order("start ASC").
		Limit(20). // Limit to prevent excessive recordings
		Find(&futurePrograms)

	for _, prog := range futurePrograms {
		// Check if this program is already scheduled
		var existingCount int64
		s.db.Model(&models.Recording{}).
			Where("user_id = ? AND channel_id = ? AND start_time = ?", userID, prog.ChannelID, prog.Start).
			Count(&existingCount)

		if existingCount > 0 {
			continue // Skip already scheduled
		}

		programID := prog.ID
		recording := models.Recording{
			UserID:            userID,
			ChannelID:         0, // Will need to look up by channel ID
			ProgramID:         &programID,
			Title:             prog.Title,
			Description:       prog.Description,
			StartTime:         prog.Start,
			EndTime:           prog.End,
			Status:            "scheduled",
			SeriesRecord:      true,
			SeriesParentID:    &parentRecordingID,
			Category:          prog.Category,
			EpisodeNum:        prog.EpisodeNum,
		}

		// Get the channel ID
		var channel models.Channel
		if s.db.Where("channel_id = ?", channelID).First(&channel).Error == nil {
			recording.ChannelID = channel.ID
			s.db.Create(&recording)
		}
	}
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
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	var recording models.Recording
	// Admins can delete any recording, regular users can only delete their own or system (user_id=0) recordings
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id IN ?", []uint{userID, 0})
	}
	if err := query.First(&recording).Error; err != nil {
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

// getActiveRecordingStats returns real-time stats for active recordings
func (s *Server) getActiveRecordingStats(c *gin.Context) {
	userID := c.GetUint("userID")

	// Get all recording-status recordings
	var recordings []models.Recording
	if err := s.db.Where("user_id = ? AND status = ?", userID, "recording").Find(&recordings).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch recordings"})
		return
	}

	type RecordingStats struct {
		ID                uint    `json:"id"`
		Title             string  `json:"title"`
		FilePath          string  `json:"filePath,omitempty"`
		FileSize          int64   `json:"fileSize"`
		FileSizeFormatted string  `json:"fileSizeFormatted"`
		ElapsedSeconds    int64   `json:"elapsedSeconds"`
		ElapsedFormatted  string  `json:"elapsedFormatted"`
		TotalSeconds      int64   `json:"totalSeconds"`
		RemainingSeconds  int64   `json:"remainingSeconds"`
		ProgressPercent   float64 `json:"progressPercent"`
		Bitrate           string  `json:"bitrate,omitempty"`
		IsHealthy         bool    `json:"isHealthy"`
		IsFailed          bool    `json:"isFailed"`          // Recording appears to have failed
		FailureReason     string  `json:"failureReason,omitempty"`
	}

	stats := make([]RecordingStats, 0, len(recordings))
	now := time.Now()
	var staleRecordingIDs []uint

	for _, rec := range recordings {
		elapsed := now.Sub(rec.StartTime)
		total := rec.EndTime.Sub(rec.StartTime)
		remaining := rec.EndTime.Sub(now)
		if remaining < 0 {
			remaining = 0
		}

		progress := 0.0
		if total.Seconds() > 0 {
			progress = (elapsed.Seconds() / total.Seconds()) * 100
			if progress > 100 {
				progress = 100
			}
		}

		// Get file size if file exists
		var fileSize int64
		var bitrate string
		isHealthy := false
		fileExists := false
		if rec.FilePath != "" {
			if info, err := os.Stat(rec.FilePath); err == nil {
				fileExists = true
				fileSize = info.Size()
				isHealthy = fileSize > 0 && info.ModTime().After(now.Add(-30*time.Second)) // File modified in last 30s

				// Calculate bitrate (bits per second)
				if elapsed.Seconds() > 0 {
					bps := float64(fileSize*8) / elapsed.Seconds()
					if bps > 1000000 {
						bitrate = fmt.Sprintf("%.1f Mbps", bps/1000000)
					} else if bps > 1000 {
						bitrate = fmt.Sprintf("%.0f Kbps", bps/1000)
					}
				}
			}
		}

		// Detect failed/stale recordings
		isFailed := false
		failureReason := ""

		// Recording is past its end time
		isPastEndTime := now.After(rec.EndTime)

		// Check if file is stale (not modified in last 2 minutes)
		var lastModified time.Time
		fileIsStale := false
		if fileExists {
			if info, err := os.Stat(rec.FilePath); err == nil {
				lastModified = info.ModTime()
				fileIsStale = lastModified.Before(now.Add(-2 * time.Minute))
			}
		}

		if isPastEndTime {
			if !fileExists || fileSize == 0 {
				// Past end time with no file = definitely failed
				isFailed = true
				failureReason = "Recording ended with no file captured"
				staleRecordingIDs = append(staleRecordingIDs, rec.ID)
			} else if fileSize < 1024*1024 { // Less than 1MB
				// Past end time with tiny file = likely failed
				isFailed = true
				failureReason = "Recording ended with incomplete file"
				staleRecordingIDs = append(staleRecordingIDs, rec.ID)
			}
		} else if elapsed.Seconds() > 300 && fileSize == 0 { // 5 minutes in with no file
			isFailed = true
			failureReason = "No data captured after 5 minutes"
		} else if fileExists && fileIsStale && elapsed.Seconds() > 300 {
			// File exists but hasn't been written to in 2+ minutes = recording stopped
			isFailed = true
			failureReason = fmt.Sprintf("Recording stopped - no data written since %s", lastModified.Format("3:04 PM"))
			staleRecordingIDs = append(staleRecordingIDs, rec.ID)
		}

		stat := RecordingStats{
			ID:                rec.ID,
			Title:             rec.Title,
			FileSize:          fileSize,
			FileSizeFormatted: formatBytes(fileSize),
			ElapsedSeconds:    int64(elapsed.Seconds()),
			ElapsedFormatted:  formatDuration(int64(elapsed.Seconds())),
			TotalSeconds:      int64(total.Seconds()),
			RemainingSeconds:  int64(remaining.Seconds()),
			ProgressPercent:   progress,
			Bitrate:           bitrate,
			IsHealthy:         isHealthy,
			IsFailed:          isFailed,
			FailureReason:     failureReason,
		}
		stats = append(stats, stat)
	}

	// Auto-mark stale recordings as failed in the database
	if len(staleRecordingIDs) > 0 {
		s.db.Model(&models.Recording{}).Where("id IN ?", staleRecordingIDs).Update("status", "failed")
	}

	// Count only active (non-failed) recordings
	activeCount := 0
	for _, stat := range stats {
		if !stat.IsFailed {
			activeCount++
		}
	}

	c.JSON(http.StatusOK, gin.H{"stats": stats, "activeCount": activeCount})
}

// formatBytes formats bytes to human readable string
func formatBytes(bytes int64) string {
	if bytes == 0 {
		return "0 B"
	}
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := int64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}

// formatDuration formats seconds to human readable duration
func formatDuration(seconds int64) string {
	if seconds < 60 {
		return fmt.Sprintf("%ds", seconds)
	}
	minutes := seconds / 60
	secs := seconds % 60
	if minutes < 60 {
		return fmt.Sprintf("%dm %ds", minutes, secs)
	}
	hours := minutes / 60
	mins := minutes % 60
	return fmt.Sprintf("%dh %dm", hours, mins)
}

// streamRecording streams a completed DVR recording file
func (s *Server) streamRecording(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	// Verify user owns this recording (admins can access any, users can access their own or system recordings)
	var recording models.Recording
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id IN ?", []uint{userID, 0})
	}
	if err := query.First(&recording).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	// Allow streaming completed and in-progress recordings
	if recording.Status != "completed" && recording.Status != "recording" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Recording is not available for playback"})
		return
	}

	if recording.FilePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording file not found"})
		return
	}

	// Serve the file
	c.File(recording.FilePath)
}

// getRecordingStreamUrl returns the stream URL for a recording (for web playback)
func (s *Server) getRecordingStreamUrl(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	// Verify user owns this recording (admins can access any, users can access their own or system recordings)
	var recording models.Recording
	query := s.db.Where("id = ?", id)
	if !isAdmin {
		query = query.Where("user_id IN ?", []uint{userID, 0})
	}
	if err := query.First(&recording).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	// Allow streaming completed and in-progress recordings
	if recording.Status != "completed" && recording.Status != "recording" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Recording is not available for playback"})
		return
	}

	if recording.FilePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording file not found"})
		return
	}

	// Return HLS URL for browser playback (browsers don't support raw .ts)
	streamUrl := fmt.Sprintf("/dvr/recordings/%d/hls/master.m3u8", recording.ID)
	c.JSON(http.StatusOK, gin.H{"url": streamUrl})
}

// getRecordingHLSPlaylist generates an HLS playlist for a recording
func (s *Server) getRecordingHLSPlaylist(c *gin.Context) {
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

	// Check if file exists
	if _, err := os.Stat(recording.FilePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording file not found on disk"})
		return
	}

	// Get file duration using ffprobe
	duration := getVideoDuration(recording.FilePath)
	if duration <= 0 {
		duration = 3600 // Default 1 hour if we can't detect
	}

	// Generate HLS playlist
	segmentDuration := 10.0 // 10 second segments
	numSegments := int(duration/segmentDuration) + 1

	var playlist strings.Builder
	playlist.WriteString("#EXTM3U\n")
	playlist.WriteString("#EXT-X-VERSION:3\n")
	playlist.WriteString(fmt.Sprintf("#EXT-X-TARGETDURATION:%d\n", int(segmentDuration)+1))
	playlist.WriteString("#EXT-X-MEDIA-SEQUENCE:0\n")
	playlist.WriteString("#EXT-X-PLAYLIST-TYPE:VOD\n")

	for i := 0; i < numSegments; i++ {
		startTime := float64(i) * segmentDuration
		segDuration := segmentDuration
		if startTime+segDuration > duration {
			segDuration = duration - startTime
		}
		if segDuration <= 0 {
			break
		}
		playlist.WriteString(fmt.Sprintf("#EXTINF:%.3f,\n", segDuration))
		playlist.WriteString(fmt.Sprintf("segment_%d.ts?start=%.3f&duration=%.3f\n", i, startTime, segDuration))
	}
	playlist.WriteString("#EXT-X-ENDLIST\n")

	c.Header("Content-Type", "application/vnd.apple.mpegurl")
	c.Header("Cache-Control", "no-cache")
	c.String(http.StatusOK, playlist.String())
}

// getRecordingHLSSegment serves an HLS segment transcoded from the recording
func (s *Server) getRecordingHLSSegment(c *gin.Context) {
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

	if recording.FilePath == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording file not found"})
		return
	}

	startTime := c.Query("start")
	duration := c.Query("duration")

	if startTime == "" || duration == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing start or duration"})
		return
	}

	// Use ffmpeg to extract the segment - try copy first (fast remux), fallback to transcode
	// DVR recordings from IPTV are usually already H.264/AAC so copy should work
	cmd := exec.Command("ffmpeg",
		"-ss", startTime,
		"-i", recording.FilePath,
		"-t", duration,
		"-map", "0:v:0",         // First video stream
		"-map", "0:a:0?",        // First audio stream (optional, may not exist)
		"-c:v", "copy",          // Copy video codec (fast, no re-encode)
		"-c:a", "aac",           // Re-encode audio to ensure compatibility
		"-b:a", "128k",
		"-ac", "2",              // Stereo audio
		"-f", "mpegts",
		"-muxdelay", "0",
		"-muxpreload", "0",
		"-")

	output, err := cmd.Output()
	if err != nil {
		// Log the ffmpeg stderr for debugging
		if exitErr, ok := err.(*exec.ExitError); ok {
			logger.Log.WithField("stderr", string(exitErr.Stderr)).Error("FFmpeg failed")
		}
		logger.Log.WithError(err).Error("Failed to transcode segment")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to transcode segment"})
		return
	}

	c.Header("Content-Type", "video/mp2t")
	c.Header("Cache-Control", "max-age=3600")
	c.Data(http.StatusOK, "video/mp2t", output)
}

// getVideoDuration uses ffprobe to get video duration in seconds
func getVideoDuration(filePath string) float64 {
	cmd := exec.Command("ffprobe",
		"-v", "quiet",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		filePath)

	output, err := cmd.Output()
	if err != nil {
		return 0
	}

	duration, err := strconv.ParseFloat(strings.TrimSpace(string(output)), 64)
	if err != nil {
		return 0
	}

	return duration
}

// getRecordingConflicts returns recordings that conflict with each other
func (s *Server) getRecordingConflicts(c *gin.Context) {
	userID := c.GetUint("userID")

	// Get all scheduled/upcoming recordings
	var recordings []models.Recording
	if err := s.db.Where("user_id = ? AND status IN ?", userID, []string{"scheduled", "recording"}).
		Order("start_time ASC").Find(&recordings).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch recordings"})
		return
	}

	// Find conflicts (overlapping recordings)
	conflicts := []ConflictGroup{}
	used := make(map[uint]bool)

	for i, rec1 := range recordings {
		if used[rec1.ID] {
			continue
		}

		group := ConflictGroup{
			Recordings: []models.Recording{rec1},
		}

		for j := i + 1; j < len(recordings); j++ {
			rec2 := recordings[j]
			if used[rec2.ID] {
				continue
			}

			// Check if they overlap
			if rec1.StartTime.Before(rec2.EndTime) && rec2.StartTime.Before(rec1.EndTime) {
				group.Recordings = append(group.Recordings, rec2)
				used[rec2.ID] = true
			}
		}

		if len(group.Recordings) > 1 {
			used[rec1.ID] = true
			conflicts = append(conflicts, group)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"conflicts":    conflicts,
		"hasConflicts": len(conflicts) > 0,
		"totalCount":   len(conflicts),
	})
}

// ConflictGroup represents a group of overlapping recordings
type ConflictGroup struct {
	Recordings []models.Recording `json:"recordings"`
}

// checkRecordingConflict checks if a new recording would conflict with existing ones
func (s *Server) checkRecordingConflict(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		StartTime time.Time `json:"startTime" binding:"required"`
		EndTime   time.Time `json:"endTime" binding:"required"`
		ExcludeID *uint     `json:"excludeId"` // Exclude an existing recording (for updates)
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Find overlapping recordings
	query := s.db.Where("user_id = ? AND status IN ? AND start_time < ? AND end_time > ?",
		userID, []string{"scheduled", "recording"}, req.EndTime, req.StartTime)

	if req.ExcludeID != nil {
		query = query.Where("id != ?", *req.ExcludeID)
	}

	var conflicts []models.Recording
	if err := query.Find(&conflicts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check conflicts"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"hasConflict":  len(conflicts) > 0,
		"conflictWith": conflicts,
	})
}

// resolveConflict resolves a recording conflict by cancelling one recording
func (s *Server) resolveConflict(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		KeepRecordingID   uint `json:"keepRecordingId" binding:"required"`
		CancelRecordingID uint `json:"cancelRecordingId" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Verify both recordings exist and belong to user
	var keepRec, cancelRec models.Recording
	if err := s.db.Where("user_id = ?", userID).First(&keepRec, req.KeepRecordingID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Keep recording not found"})
		return
	}
	if err := s.db.Where("user_id = ?", userID).First(&cancelRec, req.CancelRecordingID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Cancel recording not found"})
		return
	}

	// Can't cancel a recording that's in progress or completed
	if cancelRec.Status == "recording" || cancelRec.Status == "completed" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot cancel recording that is in progress or completed"})
		return
	}

	// Cancel the recording
	cancelRec.Status = "cancelled"
	if err := s.db.Save(&cancelRec).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to cancel recording"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":           "Conflict resolved",
		"keptRecording":     keepRec,
		"cancelledRecording": cancelRec,
	})
}

// validateRecordingStream validates a channel's stream before scheduling a recording
func (s *Server) validateRecordingStream(c *gin.Context) {
	// Can validate by channel ID or direct URL
	channelID := c.Query("channelId")
	streamURL := c.Query("url")

	if channelID == "" && streamURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Either channelId or url parameter required"})
		return
	}

	if s.recorder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "DVR recorder not available"})
		return
	}

	if channelID != "" {
		id, err := strconv.ParseUint(channelID, 10, 32)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
			return
		}

		result, err := s.recorder.ValidateChannelStream(uint(id))
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{
				"valid":   false,
				"error":   result.Error,
				"details": err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, result)
		return
	}

	// Validate direct URL
	result := s.recorder.ValidateStream(streamURL)
	c.JSON(http.StatusOK, result)
}

// updateRecordingProgress updates the playback position of a recording
func (s *Server) updateRecordingProgress(c *gin.Context) {
	userID := c.GetUint("userID")

	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid recording ID"})
		return
	}

	var req struct {
		ViewOffset int64 `json:"viewOffset"` // Position in milliseconds
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var recording models.Recording
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&recording).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Recording not found"})
		return
	}

	// Update the view offset
	recording.ViewOffset = &req.ViewOffset
	if err := s.db.Save(&recording).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update recording"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":         recording.ID,
		"viewOffset": recording.ViewOffset,
	})
}
