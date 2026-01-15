package dvr

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// Recorder manages DVR recording sessions
type Recorder struct {
	db               *gorm.DB
	ffmpegPath       string
	recordingsDir    string
	activeRecords    map[uint]*RecordingSession
	mutex            sync.RWMutex
	schedulerStop    chan struct{}
	comskip          *ComskipDetector
	commercialDetect bool
}

// RecordingSession represents an active recording
type RecordingSession struct {
	Recording   *models.Recording
	Process     *exec.Cmd
	Done        chan struct{}
	Error       error
	ErrorOutput string // Captured stderr from FFmpeg
}

// RecorderConfig holds configuration for the DVR recorder
type RecorderConfig struct {
	FFmpegPath       string
	RecordingsDir    string
	ComskipPath      string
	ComskipINIPath   string
	CommercialDetect bool
}

// NewRecorder creates a new DVR recorder
func NewRecorder(db *gorm.DB, config RecorderConfig) *Recorder {
	ffmpegPath := config.FFmpegPath
	if ffmpegPath == "" {
		if path, err := exec.LookPath("ffmpeg"); err == nil {
			ffmpegPath = path
		} else {
			ffmpegPath = "ffmpeg"
		}
	}

	os.MkdirAll(config.RecordingsDir, 0755)

	// Initialize Comskip detector
	comskip := NewComskipDetector(db, config.ComskipPath, config.ComskipINIPath)

	r := &Recorder{
		db:               db,
		ffmpegPath:       ffmpegPath,
		recordingsDir:    config.RecordingsDir,
		activeRecords:    make(map[uint]*RecordingSession),
		schedulerStop:    make(chan struct{}),
		comskip:          comskip,
		commercialDetect: config.CommercialDetect && comskip.IsEnabled(),
	}

	// Start scheduler
	go r.scheduleLoop()

	return r
}

// NewRecorderSimple creates a recorder with minimal config (for backwards compatibility)
func NewRecorderSimple(db *gorm.DB, ffmpegPath, recordingsDir string) *Recorder {
	return NewRecorder(db, RecorderConfig{
		FFmpegPath:       ffmpegPath,
		RecordingsDir:    recordingsDir,
		CommercialDetect: true, // Enable by default if comskip is found
	})
}

// Stop stops the recorder and all active recordings
func (r *Recorder) Stop() {
	close(r.schedulerStop)

	r.mutex.Lock()
	defer r.mutex.Unlock()

	for _, session := range r.activeRecords {
		if session.Process != nil && session.Process.Process != nil {
			session.Process.Process.Kill()
		}
	}
}

// scheduleLoop checks for recordings that need to start
func (r *Recorder) scheduleLoop() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-r.schedulerStop:
			return
		case <-ticker.C:
			r.checkScheduledRecordings()
			r.processSeriesRules()
			r.processTeamPassesInternal()
		}
	}
}

// checkScheduledRecordings starts recordings that are due
func (r *Recorder) checkScheduledRecordings() {
	// Use UTC for database queries since times are stored in UTC
	now := time.Now().UTC()

	var recordings []models.Recording
	r.db.Where("status = ? AND start_time <= ?", "scheduled", now).Find(&recordings)

	for _, rec := range recordings {
		recording := rec // Create copy for goroutine
		if recording.EndTime.Before(now) {
			// Recording window passed, mark as failed
			recording.Status = "failed"
			r.db.Save(&recording)
			continue
		}

		// Start recording
		go r.startRecording(&recording)
	}

	// Check for recordings that should have ended
	r.mutex.RLock()
	for id, session := range r.activeRecords {
		if session.Recording.EndTime.Before(now) {
			go r.stopRecording(id)
		}
	}
	r.mutex.RUnlock()
}

// processSeriesRules checks series rules and creates recordings
func (r *Recorder) processSeriesRules() {
	var rules []models.SeriesRule
	r.db.Where("enabled = ?", true).Find(&rules)

	// Use UTC for database queries since times are stored in UTC
	now := time.Now().UTC()

	for _, rule := range rules {
		// Find matching programs in the next 24 hours
		var programs []models.Program
		query := r.db.Where("start > ? AND start < ?", now, now.Add(24*time.Hour))

		if rule.ChannelID != nil {
			// Get channel's EPG ID
			var channel models.Channel
			if r.db.First(&channel, *rule.ChannelID).Error == nil {
				query = query.Where("channel_id = ?", channel.ChannelID)
			}
		}

		if rule.Keywords != "" {
			query = query.Where("title LIKE ?", "%"+rule.Keywords+"%")
		}

		query.Find(&programs)

		for _, prog := range programs {
			// Check if recording already exists
			var existing models.Recording
			if r.db.Where("program_id = ? AND user_id = ?", prog.ID, rule.UserID).First(&existing).Error == nil {
				continue // Already scheduled
			}

			// Find channel by EPG ID
			var channel models.Channel
			if r.db.Where("channel_id = ?", prog.ChannelID).First(&channel).Error != nil {
				continue
			}

			// Apply padding
			startTime := prog.Start.Add(-time.Duration(rule.PrePadding) * time.Minute)
			endTime := prog.End.Add(time.Duration(rule.PostPadding) * time.Minute)

			recording := models.Recording{
				UserID:       rule.UserID,
				ChannelID:    channel.ID,
				ProgramID:    &prog.ID,
				Title:        prog.Title,
				Description:  prog.Description,
				StartTime:    startTime,
				EndTime:      endTime,
				Status:       "scheduled",
				SeriesRuleID: &rule.ID,
			}

			r.db.Create(&recording)
		}

		// Clean up old recordings if KeepCount is set
		if rule.KeepCount > 0 {
			var recordings []models.Recording
			r.db.Where("series_rule_id = ? AND status = ?", rule.ID, "completed").
				Order("start_time DESC").
				Offset(rule.KeepCount).
				Find(&recordings)

			for _, rec := range recordings {
				// Delete file
				if rec.FilePath != "" {
					os.Remove(rec.FilePath)
				}
				r.db.Delete(&rec)
			}
		}
	}
}

// processTeamPassesInternal is the internal team pass processing (called by scheduler)
func (r *Recorder) processTeamPassesInternal() int {
	return r.processTeamPassesForUser(0) // 0 means all users
}

// ProcessTeamPasses is the public interface for processing team passes
// Returns the number of recordings scheduled
func (r *Recorder) ProcessTeamPasses() int {
	return r.processTeamPassesInternal()
}

// processTeamPassesForUser processes team passes for a specific user (0 = all users)
func (r *Recorder) processTeamPassesForUser(userID uint) int {
	var teamPasses []models.TeamPass
	query := r.db.Where("enabled = ?", true)
	if userID > 0 {
		query = query.Where("user_id = ?", userID)
	}
	query.Find(&teamPasses)

	// Use UTC for database queries since times are stored in UTC
	now := time.Now().UTC()
	scheduledCount := 0

	for _, tp := range teamPasses {
		// Find matching sports programs in the next 7 days
		var programs []models.Program
		query := r.db.Where("is_sports = ? AND start > ? AND start < ?", true, now, now.Add(7*24*time.Hour))

		// Match team name in teams field or title
		teamSearch := tp.TeamName
		query = query.Where("teams LIKE ? OR title LIKE ?", "%"+teamSearch+"%", "%"+teamSearch+"%")

		// Match league if specified
		if tp.League != "" {
			query = query.Where("league = ?", tp.League)
		}

		// Filter by channels if specified
		if tp.ChannelIDs != "" {
			channelIDs := strings.Split(tp.ChannelIDs, ",")
			query = query.Where("channel_id IN ?", channelIDs)
		}

		query.Find(&programs)

		for _, prog := range programs {
			// Check if recording already exists for this program
			var existing models.Recording
			if r.db.Where("program_id = ? AND user_id = ?", prog.ID, tp.UserID).First(&existing).Error == nil {
				continue // Already scheduled
			}

			// Find channel by EPG ID
			var channel models.Channel
			if r.db.Where("channel_id = ?", prog.ChannelID).First(&channel).Error != nil {
				continue
			}

			// Apply padding
			startTime := prog.Start.Add(-time.Duration(tp.PrePadding) * time.Minute)
			endTime := prog.End.Add(time.Duration(tp.PostPadding) * time.Minute)

			// Check for conflicts with other recordings
			var conflict models.Recording
			if r.db.Where("user_id = ? AND status IN ? AND start_time < ? AND end_time > ?",
				tp.UserID, []string{"scheduled", "recording"}, endTime, startTime).First(&conflict).Error == nil {
				// There's a conflict - skip for now (could add priority-based conflict resolution)
				logger.Log.Warnf("Team pass conflict: %s overlaps with %s", prog.Title, conflict.Title)
				continue
			}

			recording := models.Recording{
				UserID:       tp.UserID,
				ChannelID:    channel.ID,
				ProgramID:    &prog.ID,
				Title:        prog.Title,
				Description:  prog.Description,
				StartTime:    startTime,
				EndTime:      endTime,
				Status:       "scheduled",
				Category:     "Sports",
				SeriesRecord: true, // Mark as auto-recorded
			}

			if err := r.db.Create(&recording).Error; err != nil {
				logger.Log.Errorf("Failed to create team pass recording: %v", err)
				continue
			}

			logger.Log.Infof("Team pass scheduled recording: %s on %s at %s",
				prog.Title, channel.Name, prog.Start.Format("2006-01-02 15:04"))
			scheduledCount++
		}

		// Clean up old recordings if KeepCount is set
		if tp.KeepCount > 0 {
			// Get recordings from this team pass that are completed
			var recordings []models.Recording
			r.db.Where("user_id = ? AND category = ? AND status = ?",
				tp.UserID, "Sports", "completed").
				Where("title LIKE ?", "%"+tp.TeamName+"%").
				Order("start_time DESC").
				Offset(tp.KeepCount).
				Find(&recordings)

			for _, rec := range recordings {
				if rec.FilePath != "" {
					os.Remove(rec.FilePath)
				}
				r.db.Delete(&rec)
			}
		}
	}

	return scheduledCount
}

// startRecording starts a recording
func (r *Recorder) startRecording(recording *models.Recording) error {
	r.mutex.Lock()

	// Check if already recording
	if _, exists := r.activeRecords[recording.ID]; exists {
		r.mutex.Unlock()
		return nil
	}

	// Get channel
	var channel models.Channel
	if err := r.db.First(&channel, recording.ChannelID).Error; err != nil {
		r.mutex.Unlock()
		recording.Status = "failed"
		r.db.Save(recording)
		return fmt.Errorf("channel not found: %w", err)
	}

	// Verify/refresh EPG metadata at actual recording start time
	r.verifyRecordingMetadata(recording, &channel)

	// Validate stream before starting
	r.mutex.Unlock() // Release lock during validation (network I/O)
	validation := r.ValidateStream(channel.StreamURL)
	r.mutex.Lock()

	if !validation.Valid {
		r.mutex.Unlock()
		recording.Status = "failed"
		r.db.Save(recording)
		logger.Log.WithFields(map[string]interface{}{
			"recording_id": recording.ID,
			"channel_id":   channel.ID,
			"stream_url":   channel.StreamURL,
			"error":        validation.Error,
		}).Error("Stream validation failed before recording")
		return fmt.Errorf("stream validation failed: %s", validation.Error)
	}

	logger.Log.WithFields(map[string]interface{}{
		"recording_id":    recording.ID,
		"channel_id":      channel.ID,
		"validation_ms":   validation.Duration,
		"is_hls":          validation.IsHLS,
	}).Info("Stream validated successfully, starting recording")

	// Create output file path
	timestamp := recording.StartTime.Format("2006-01-02_15-04-05")
	safeTitle := sanitizeFilename(recording.Title)
	filename := fmt.Sprintf("%s_%s.ts", safeTitle, timestamp)
	outputPath := filepath.Join(r.recordingsDir, filename)

	// Calculate duration
	duration := recording.EndTime.Sub(time.Now())
	if duration <= 0 {
		r.mutex.Unlock()
		recording.Status = "failed"
		r.db.Save(recording)
		return fmt.Errorf("recording end time already passed")
	}

	// Build FFmpeg command
	args := []string{
		"-y",
		"-hide_banner",
		"-loglevel", "warning",
		"-i", channel.StreamURL,
		"-t", fmt.Sprintf("%d", int(duration.Seconds())),
		"-c", "copy", // Copy streams without re-encoding
		outputPath,
	}

	cmd := exec.Command(r.ffmpegPath, args...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	session := &RecordingSession{
		Recording: recording,
		Process:   cmd,
		Done:      make(chan struct{}),
	}

	r.activeRecords[recording.ID] = session
	r.mutex.Unlock()

	// Update recording status
	recording.Status = "recording"
	recording.FilePath = outputPath
	r.db.Save(recording)

	// Start FFmpeg with retry logic for transient stream errors
	// Capture values needed in goroutine
	streamURL := channel.StreamURL
	ffmpegPath := r.ffmpegPath

	go func() {
		defer close(session.Done)

		maxRetries := 3
		retryDelay := 5 * time.Second

		for attempt := 1; attempt <= maxRetries; attempt++ {
			session.Error = session.Process.Run()
			session.ErrorOutput = stderr.String()

			if session.Error == nil {
				// Success
				break
			}

			// Check if error is retryable (transient stream issues)
			isTransientError := strings.Contains(session.ErrorOutput, "Invalid data found") ||
				strings.Contains(session.ErrorOutput, "Connection refused") ||
				strings.Contains(session.ErrorOutput, "Connection reset") ||
				strings.Contains(session.ErrorOutput, "Server returned")

			// Check if we have enough time left to retry
			timeRemaining := recording.EndTime.Sub(time.Now())

			if !isTransientError || attempt >= maxRetries || timeRemaining < retryDelay*2 {
				logger.Log.WithFields(map[string]interface{}{
					"recording_id":  recording.ID,
					"error":         session.Error.Error(),
					"ffmpeg_output": session.ErrorOutput,
					"attempt":       attempt,
				}).Error("FFmpeg recording failed")
				break
			}

			// Log retry attempt
			logger.Log.WithFields(map[string]interface{}{
				"recording_id":   recording.ID,
				"error":          session.Error.Error(),
				"attempt":        attempt,
				"retry_in":       retryDelay.String(),
				"time_remaining": timeRemaining.String(),
			}).Warn("FFmpeg failed with transient error, retrying...")

			// Wait before retry
			time.Sleep(retryDelay)

			// Recreate FFmpeg command for retry with updated duration
			stderr.Reset()
			newDuration := recording.EndTime.Sub(time.Now())
			if newDuration <= 0 {
				logger.Log.WithField("recording_id", recording.ID).Error("Recording end time passed during retry")
				break
			}

			retryArgs := []string{
				"-y",
				"-hide_banner",
				"-loglevel", "warning",
				"-i", streamURL,
				"-t", fmt.Sprintf("%d", int(newDuration.Seconds())),
				"-c", "copy",
				outputPath,
			}
			cmd := exec.Command(ffmpegPath, retryArgs...)
			cmd.Stderr = &stderr
			session.Process = cmd
		}

		r.onRecordingComplete(recording.ID)
	}()

	return nil
}

// stopRecording stops an active recording
func (r *Recorder) stopRecording(recordingID uint) {
	r.mutex.Lock()
	session, exists := r.activeRecords[recordingID]
	if !exists {
		r.mutex.Unlock()
		return
	}
	delete(r.activeRecords, recordingID)
	r.mutex.Unlock()

	if session.Process != nil && session.Process.Process != nil {
		// Send SIGINT for graceful shutdown
		session.Process.Process.Signal(os.Interrupt)

		// Wait a bit then force kill
		select {
		case <-session.Done:
		case <-time.After(5 * time.Second):
			session.Process.Process.Kill()
		}
	}
}

// onRecordingComplete handles recording completion
func (r *Recorder) onRecordingComplete(recordingID uint) {
	r.mutex.Lock()
	session, exists := r.activeRecords[recordingID]
	if exists {
		delete(r.activeRecords, recordingID)
	}
	r.mutex.Unlock()

	var recording models.Recording
	if err := r.db.First(&recording, recordingID).Error; err != nil {
		return
	}

	if session != nil && session.Error != nil {
		recording.Status = "failed"
	} else {
		recording.Status = "completed"
		// Get file size
		if info, err := os.Stat(recording.FilePath); err == nil {
			recording.FileSize = info.Size()
		}
	}

	r.db.Save(&recording)

	// Run commercial detection asynchronously if enabled
	if r.commercialDetect && recording.Status == "completed" {
		go r.runCommercialDetection(&recording)
	}
}

// runCommercialDetection runs Comskip on a completed recording
func (r *Recorder) runCommercialDetection(recording *models.Recording) {
	if r.comskip == nil {
		return
	}

	if err := r.comskip.DetectCommercials(recording); err != nil {
		// Log but don't fail - commercial detection is optional
		logger.Log.WithFields(map[string]interface{}{
			"recording_id": recording.ID,
			"error":        err.Error(),
		}).Warn("Commercial detection failed for recording")
	}
}

// GetCommercialSegments returns commercial segments for a recording
func (r *Recorder) GetCommercialSegments(recordingID uint) ([]models.CommercialSegment, error) {
	if r.comskip == nil {
		return nil, fmt.Errorf("commercial detection not available")
	}
	return r.comskip.GetCommercialSegments(recordingID)
}

// RerunCommercialDetection re-runs commercial detection on an existing recording
func (r *Recorder) RerunCommercialDetection(recordingID uint) error {
	var recording models.Recording
	if err := r.db.First(&recording, recordingID).Error; err != nil {
		return err
	}

	if recording.Status != "completed" {
		return fmt.Errorf("recording is not completed")
	}

	// Delete existing segments
	if r.comskip != nil {
		r.comskip.DeleteCommercialSegments(recordingID)
	}

	// Run detection
	go r.runCommercialDetection(&recording)
	return nil
}

// IsCommercialDetectionEnabled returns whether commercial detection is available
func (r *Recorder) IsCommercialDetectionEnabled() bool {
	return r.commercialDetect
}

// GetActiveRecordings returns currently active recordings
func (r *Recorder) GetActiveRecordings() []*models.Recording {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	recordings := make([]*models.Recording, 0, len(r.activeRecords))
	for _, session := range r.activeRecords {
		recordings = append(recordings, session.Recording)
	}
	return recordings
}

// CancelRecording cancels a scheduled recording
func (r *Recorder) CancelRecording(recordingID uint) error {
	// Check if recording is active
	r.mutex.RLock()
	if _, exists := r.activeRecords[recordingID]; exists {
		r.mutex.RUnlock()
		r.stopRecording(recordingID)
	} else {
		r.mutex.RUnlock()
	}

	// Update status
	var recording models.Recording
	if err := r.db.First(&recording, recordingID).Error; err != nil {
		return err
	}

	recording.Status = "cancelled"
	return r.db.Save(&recording).Error
}

// sanitizeFilename removes invalid characters from filename
func sanitizeFilename(name string) string {
	invalid := []rune{'/', '\\', ':', '*', '?', '"', '<', '>', '|'}
	result := []rune(name)
	for i, r := range result {
		for _, inv := range invalid {
			if r == inv {
				result[i] = '_'
				break
			}
		}
	}
	// Limit length
	if len(result) > 100 {
		result = result[:100]
	}
	return string(result)
}

// StreamValidationResult contains the result of stream validation
type StreamValidationResult struct {
	Valid       bool   `json:"valid"`
	StatusCode  int    `json:"statusCode,omitempty"`
	ContentType string `json:"contentType,omitempty"`
	Error       string `json:"error,omitempty"`
	IsHLS       bool   `json:"isHLS"`
	Duration    int64  `json:"validationDuration"` // milliseconds
}

// ValidateStream checks if a stream URL is accessible and valid
func (r *Recorder) ValidateStream(streamURL string) StreamValidationResult {
	start := time.Now()
	result := StreamValidationResult{}

	// Create context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Determine if HLS stream
	result.IsHLS = strings.Contains(streamURL, ".m3u8") || strings.Contains(streamURL, "m3u8")

	// Create HTTP client with timeout
	client := &http.Client{
		Timeout: 10 * time.Second,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return fmt.Errorf("too many redirects")
			}
			return nil
		},
	}

	// Create request
	req, err := http.NewRequestWithContext(ctx, "GET", streamURL, nil)
	if err != nil {
		result.Error = fmt.Sprintf("failed to create request: %v", err)
		result.Duration = time.Since(start).Milliseconds()
		return result
	}

	// Set user agent to avoid blocks
	req.Header.Set("User-Agent", "OpenFlix/1.0 DVR")

	// Make request
	resp, err := client.Do(req)
	if err != nil {
		result.Error = fmt.Sprintf("stream unreachable: %v", err)
		result.Duration = time.Since(start).Milliseconds()
		return result
	}
	defer resp.Body.Close()

	result.StatusCode = resp.StatusCode
	result.ContentType = resp.Header.Get("Content-Type")

	// Check status code
	if resp.StatusCode < 200 || resp.StatusCode >= 400 {
		result.Error = fmt.Sprintf("stream returned status %d", resp.StatusCode)
		result.Duration = time.Since(start).Milliseconds()
		return result
	}

	// For HLS streams, validate the playlist content
	if result.IsHLS {
		body, err := io.ReadAll(io.LimitReader(resp.Body, 1024*1024)) // Limit to 1MB
		if err != nil {
			result.Error = fmt.Sprintf("failed to read playlist: %v", err)
			result.Duration = time.Since(start).Milliseconds()
			return result
		}

		content := string(body)
		// Check for valid HLS markers
		if !strings.Contains(content, "#EXTM3U") {
			result.Error = "invalid HLS playlist: missing #EXTM3U header"
			result.Duration = time.Since(start).Milliseconds()
			return result
		}

		// Check for either master playlist or media playlist indicators
		isValidPlaylist := strings.Contains(content, "#EXTINF") ||
			strings.Contains(content, "#EXT-X-STREAM-INF") ||
			strings.Contains(content, "#EXT-X-MEDIA")

		if !isValidPlaylist {
			result.Error = "invalid HLS playlist: no valid segments or streams found"
			result.Duration = time.Since(start).Milliseconds()
			return result
		}
	}

	result.Valid = true
	result.Duration = time.Since(start).Milliseconds()
	return result
}

// ValidateChannelStream validates the stream URL for a specific channel
func (r *Recorder) ValidateChannelStream(channelID uint) (StreamValidationResult, error) {
	var channel models.Channel
	if err := r.db.First(&channel, channelID).Error; err != nil {
		return StreamValidationResult{Error: "channel not found"}, err
	}

	if channel.StreamURL == "" {
		return StreamValidationResult{Error: "channel has no stream URL"}, fmt.Errorf("no stream URL")
	}

	return r.ValidateStream(channel.StreamURL), nil
}

// verifyRecordingMetadata checks EPG at recording start and updates metadata if needed
// This helps catch EPG mismatches by re-checking what's actually on at start time
func (r *Recorder) verifyRecordingMetadata(recording *models.Recording, channel *models.Channel) {
	now := time.Now()

	// Find the current program on this channel from EPG
	var currentProgram models.Program
	err := r.db.Where("channel_id = ? AND start <= ? AND end > ?",
		channel.ChannelID, now, now).First(&currentProgram).Error

	if err != nil {
		logger.Log.WithFields(map[string]interface{}{
			"recording_id": recording.ID,
			"channel_id":   channel.ID,
			"channel_name": channel.Name,
			"epg_id":       channel.ChannelID,
		}).Warn("No EPG program found for channel at recording start time")
		return
	}

	// Log the EPG match for debugging
	logger.Log.WithFields(map[string]interface{}{
		"recording_id":    recording.ID,
		"scheduled_title": recording.Title,
		"current_program": currentProgram.Title,
		"channel_name":    channel.Name,
		"epg_channel_id":  channel.ChannelID,
		"program_start":   currentProgram.Start,
		"program_end":     currentProgram.End,
	}).Info("EPG verification at recording start")

	// If the current program title differs significantly from scheduled, update it
	// This catches EPG mismatches where wrong metadata was used
	if recording.Title != currentProgram.Title {
		logger.Log.WithFields(map[string]interface{}{
			"recording_id": recording.ID,
			"old_title":    recording.Title,
			"new_title":    currentProgram.Title,
		}).Warn("Recording title mismatch detected - updating from current EPG")

		// Update recording metadata from current program
		recording.Title = currentProgram.Title
		recording.Description = currentProgram.Description
		recording.Category = currentProgram.Category
		recording.EpisodeNum = currentProgram.EpisodeNum

		// Update program reference
		recording.ProgramID = &currentProgram.ID

		r.db.Save(recording)
	}
}

// RefreshChannelEPGMapping re-detects EPG mapping for a channel
// Call this when EPG data seems mismatched
func (r *Recorder) RefreshChannelEPGMapping(channelID uint) error {
	var channel models.Channel
	if err := r.db.First(&channel, channelID).Error; err != nil {
		return fmt.Errorf("channel not found: %w", err)
	}

	// Log current mapping
	logger.Log.WithFields(map[string]interface{}{
		"channel_id":   channel.ID,
		"channel_name": channel.Name,
		"current_epg":  channel.ChannelID,
		"tvg_id":       channel.TVGId,
	}).Info("Refreshing EPG mapping for channel")

	// If channel has a TVG ID from M3U, try to use that
	if channel.TVGId != "" && channel.TVGId != channel.ChannelID {
		// Check if programs exist with this TVG ID
		var count int64
		r.db.Model(&models.Program{}).Where("channel_id = ?", channel.TVGId).Count(&count)
		if count > 0 {
			channel.ChannelID = channel.TVGId
			r.db.Save(&channel)
			logger.Log.WithFields(map[string]interface{}{
				"channel_id":  channel.ID,
				"new_epg_id":  channel.TVGId,
				"program_cnt": count,
			}).Info("Updated channel EPG mapping from TVG ID")
			return nil
		}
	}

	return nil
}
