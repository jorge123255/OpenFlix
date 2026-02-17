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
	diskConfig       DiskSpaceConfig
	eventBus         *EventBus
	enricher         *Enricher
	grouper          *Grouper
	upnext           *UpNextManager
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
	DiskQuotaGB      float64
	LowSpaceGB       float64
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
		diskConfig: DiskSpaceConfig{
			QuotaGB:    config.DiskQuotaGB,
			LowSpaceGB: config.LowSpaceGB,
		},
		eventBus: NewEventBus(),
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

// SetEnricher sets the TMDB enricher for DVR file metadata
func (r *Recorder) SetEnricher(e *Enricher) {
	r.enricher = e
	r.grouper = NewGrouper(r.db)
	r.upnext = NewUpNextManager(r.db)
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
			r.processRules()
		}
	}
}

// checkScheduledRecordings starts recordings that are due
func (r *Recorder) checkScheduledRecordings() {
	// Use UTC for database queries since times are stored in UTC
	now := time.Now().UTC()

	// Auto-retry failed recordings still within their time window
	r.retryFailedRecordings(now)

	var recordings []models.Recording
	r.db.Where("status = ? AND start_time <= ?", "scheduled", now).Find(&recordings)

	// Also check dvr_jobs table for scheduled jobs that should start
	r.checkScheduledDVRJobs(now)

	// Separate expired vs valid recordings
	var validRecordings []models.Recording
	for _, rec := range recordings {
		if rec.EndTime.Before(now) {
			// Recording window passed, mark as failed
			rec.Status = "failed"
			rec.LastError = "recording window passed before recording could start"
			r.db.Save(&rec)
			r.syncRecordingToDVR(&rec)
			continue
		}
		validRecordings = append(validRecordings, rec)
	}

	// Resolve conflicts - only start recordings that win priority
	recordingsToStart := r.ResolveConflictsAtRecordingTime(validRecordings)

	for _, rec := range recordingsToStart {
		recording := rec // Create copy for goroutine
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

			if err := r.db.Create(&recording).Error; err == nil {
				// Dual-write: sync new scheduled recording to DVR v2 tables
				r.syncRecordingToDVR(&recording)
			}
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

			// Dual-write: sync new scheduled recording to DVR v2 tables
			r.syncRecordingToDVR(&recording)

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

// processRules evaluates all enabled DVRRules against upcoming programs and creates DVRJobs.
// This is the unified replacement for processSeriesRules + processTeamPassesForUser.
func (r *Recorder) processRules() {
	var rules []models.DVRRule
	r.db.Where("enabled = ? AND paused = ?", true, false).Find(&rules)
	if len(rules) == 0 {
		return
	}

	now := time.Now().UTC()

	// Load all upcoming programs (next 7 days) once for all rules
	var programs []models.Program
	r.db.Where("start > ? AND start < ?", now, now.Add(7*24*time.Hour)).Find(&programs)
	if len(programs) == 0 {
		return
	}

	totalScheduled := 0

	for _, rule := range rules {
		matched := MatchProgramsForRule(programs, &rule)
		if len(matched) == 0 {
			continue
		}

		scheduled := 0
		for _, prog := range matched {
			// Check if a DVRJob already exists for this program+user
			var existingJob models.DVRJob
			if r.db.Where("program_id = ? AND user_id = ? AND status IN ?",
				prog.ID, rule.UserID, []string{"scheduled", "recording", "completed"}).
				First(&existingJob).Error == nil {
				continue // Already scheduled/recorded
			}

			// Also check legacy recordings
			var existingRec models.Recording
			if r.db.Where("program_id = ? AND user_id = ?", prog.ID, rule.UserID).
				First(&existingRec).Error == nil {
				continue
			}

			// Check duplicates policy
			if rule.Duplicates == "skip" {
				var dup models.DVRJob
				if r.db.Where("user_id = ? AND title = ? AND status = ?",
					rule.UserID, prog.Title, "completed").
					First(&dup).Error == nil {
					continue // Already recorded this title
				}
			}

			// Check concurrent job limit
			if rule.Limit > 0 {
				var activeCount int64
				r.db.Model(&models.DVRJob{}).
					Where("rule_id = ? AND status IN ?", rule.ID, []string{"scheduled", "recording"}).
					Count(&activeCount)
				if int(activeCount) >= rule.Limit {
					continue
				}
			}

			// Find channel by EPG channel_id
			var channel models.Channel
			if r.db.Where("channel_id = ?", prog.ChannelID).First(&channel).Error != nil {
				continue
			}

			// Apply padding
			startTime := prog.Start.Add(-time.Duration(rule.PaddingStart) * time.Second)
			endTime := prog.End.Add(time.Duration(rule.PaddingEnd) * time.Second)

			// Check for conflicts
			var conflict models.DVRJob
			if r.db.Where("user_id = ? AND status IN ? AND start_time < ? AND end_time > ?",
				rule.UserID, []string{"scheduled", "recording"}, endTime, startTime).
				First(&conflict).Error == nil {
				// Resolve by priority
				if conflict.Priority >= rule.Priority {
					continue // Existing job has higher or equal priority
				}
				// Cancel lower priority conflict
				conflict.Status = "cancelled"
				conflict.LastError = "cancelled by higher priority rule"
				r.db.Save(&conflict)
			}

			ruleID := rule.ID
			progID := prog.ID
			job := models.DVRJob{
				UserID:      rule.UserID,
				RuleID:      &ruleID,
				ChannelID:   channel.ID,
				ProgramID:   &progID,
				Title:       prog.Title,
				Subtitle:    prog.Subtitle,
				Description: prog.Description,
				StartTime:   startTime,
				EndTime:     endTime,
				Status:      "scheduled",
				Priority:    rule.Priority,
				QualityPreset: rule.QualityPreset,
				PaddingStart: rule.PaddingStart,
				PaddingEnd:   rule.PaddingEnd,
				ChannelName: channel.Name,
				ChannelLogo: channel.Logo,
				Category:    prog.Category,
				EpisodeNum:  prog.EpisodeNum,
				IsMovie:     prog.IsMovie,
				IsSports:    prog.IsSports,
			}

			if err := r.db.Create(&job).Error; err != nil {
				logger.Log.WithFields(map[string]interface{}{
					"rule_id": rule.ID,
					"program": prog.Title,
					"error":   err.Error(),
				}).Warn("Failed to create DVR job from rule")
				continue
			}

			r.eventBus.Publish(DVREvent{
				Type:   EventJobCreated,
				JobID:  job.ID,
				RuleID: rule.ID,
				Title:  job.Title,
			})

			// Also create a legacy Recording so the existing pipeline picks it up
			recording := models.Recording{
				UserID:       rule.UserID,
				ChannelID:    channel.ID,
				ProgramID:    &progID,
				Title:        prog.Title,
				Subtitle:     prog.Subtitle,
				Description:  prog.Description,
				StartTime:    startTime,
				EndTime:      endTime,
				Status:       "scheduled",
				Category:     prog.Category,
				EpisodeNum:   prog.EpisodeNum,
				IsMovie:      prog.IsMovie,
				SeriesRecord: true,
				Priority:     rule.Priority,
				QualityPreset: rule.QualityPreset,
			}
			if err := r.db.Create(&recording).Error; err == nil {
				// Link them
				legacyID := recording.ID
				job.LegacyRecordingID = &legacyID
				r.db.Save(&job)
			}

			scheduled++
			logger.Log.WithFields(map[string]interface{}{
				"rule":    rule.Name,
				"program": prog.Title,
				"channel": channel.Name,
				"start":   prog.Start.Format("2006-01-02 15:04"),
			}).Info("Rule scheduled recording")
		}

		// Enforce KeepNum - delete oldest completed recordings beyond the limit
		if rule.KeepNum > 0 {
			var oldJobs []models.DVRJob
			r.db.Where("rule_id = ? AND status = ?", rule.ID, "completed").
				Order("start_time DESC").
				Offset(rule.KeepNum).
				Find(&oldJobs)

			for _, oldJob := range oldJobs {
				if oldJob.FileID != nil {
					var file models.DVRFile
					if r.db.First(&file, *oldJob.FileID).Error == nil {
						file.Deleted = true
						r.db.Save(&file)
						if file.FilePath != "" {
							os.Remove(file.FilePath)
						}
					}
				}
				oldJob.Status = "cancelled"
				oldJob.LastError = "removed by KeepNum limit"
				r.db.Save(&oldJob)
			}
		}

		totalScheduled += scheduled
	}

	if totalScheduled > 0 {
		logger.Log.WithField("scheduled", totalScheduled).Info("DVR rules processed")
	}

	r.eventBus.Publish(DVREvent{
		Type:    EventProcessorDone,
		Message: fmt.Sprintf("Processed %d rules, scheduled %d jobs", len(rules), totalScheduled),
		Data:    map[string]any{"rulesProcessed": len(rules), "jobsScheduled": totalScheduled},
	})
}

// getFailoverURLs returns stream URLs for a channel, including ChannelGroup members sorted by priority.
// The primary channel URL is always first, followed by group members.
func (r *Recorder) getFailoverURLs(channelID uint) []string {
	var channel models.Channel
	if err := r.db.First(&channel, channelID).Error; err != nil {
		return nil
	}

	urls := []string{channel.StreamURL}

	// Check if this channel belongs to any ChannelGroup
	var members []models.ChannelGroupMember
	r.db.Where("channel_id = ?", channelID).Find(&members)

	for _, member := range members {
		// Get all members of the same group, sorted by priority
		var groupMembers []models.ChannelGroupMember
		r.db.Where("channel_group_id = ? AND channel_id != ?", member.ChannelGroupID, channelID).
			Order("priority ASC").Find(&groupMembers)

		for _, gm := range groupMembers {
			var ch models.Channel
			if r.db.First(&ch, gm.ChannelID).Error == nil && ch.StreamURL != "" {
				urls = append(urls, ch.StreamURL)
			}
		}
	}

	return urls
}

// buildFFmpegArgs builds FFmpeg command arguments based on recording quality preset
func (r *Recorder) buildFFmpegArgs(streamURL string, duration time.Duration, outputPath string, recording *models.Recording) []string {
	args := []string{
		"-y",
		"-hide_banner",
		"-loglevel", "warning",
		"-i", streamURL,
		"-t", fmt.Sprintf("%d", int(duration.Seconds())),
	}

	preset := recording.QualityPreset
	if preset == "" {
		preset = "original"
	}

	switch preset {
	case "high":
		args = append(args, "-c:v", "libx264", "-preset", "veryfast", "-b:v", "8M", "-c:a", "aac", "-b:a", "192k")
	case "medium":
		args = append(args, "-c:v", "libx264", "-preset", "veryfast", "-b:v", "4M", "-c:a", "aac", "-b:a", "128k")
	case "low":
		args = append(args, "-c:v", "libx264", "-preset", "veryfast", "-b:v", "2M", "-c:a", "aac", "-b:a", "96k")
	default: // "original"
		args = append(args, "-c", "copy")
	}

	args = append(args, outputPath)
	return args
}

// GetEventBus returns the event bus for WebSocket subscriptions
func (r *Recorder) GetEventBus() *EventBus {
	return r.eventBus
}

// startRecording starts a recording
func (r *Recorder) startRecording(recording *models.Recording) error {
	// Check disk space before starting
	canRecord, reason := CanStartRecording(r.recordingsDir, r.diskConfig)
	if !canRecord {
		recording.Status = "failed"
		recording.LastError = reason
		r.db.Save(recording)
		r.syncRecordingToDVR(recording)
		logger.Log.WithFields(map[string]interface{}{
			"recording_id": recording.ID,
			"reason":       reason,
		}).Error("Cannot start recording: insufficient disk space")
		if r.eventBus != nil {
			r.eventBus.Publish(DVREvent{
				Type:        EventDiskSpaceLow,
				RecordingID: recording.ID,
				Title:       recording.Title,
				Message:     reason,
			})
		}
		return fmt.Errorf("insufficient disk space: %s", reason)
	}

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
		recording.LastError = fmt.Sprintf("channel not found: %v", err)
		r.db.Save(recording)
		r.syncRecordingToDVR(recording)
		return fmt.Errorf("channel not found: %w", err)
	}

	// Verify/refresh EPG metadata at actual recording start time
	r.verifyRecordingMetadata(recording, &channel)

	// Get failover URLs (primary + group members)
	r.mutex.Unlock() // Release lock during network I/O
	failoverURLs := r.getFailoverURLs(recording.ChannelID)
	if len(failoverURLs) == 0 {
		failoverURLs = []string{channel.StreamURL}
	}

	// Validate the primary stream first
	validation := r.ValidateStream(failoverURLs[0])
	r.mutex.Lock()

	// If primary fails, try failover URLs
	activeStreamURL := failoverURLs[0]
	if !validation.Valid && len(failoverURLs) > 1 {
		r.mutex.Unlock()
		for _, url := range failoverURLs[1:] {
			validation = r.ValidateStream(url)
			if validation.Valid {
				activeStreamURL = url
				logger.Log.WithFields(map[string]interface{}{
					"recording_id":   recording.ID,
					"failover_url":   url,
				}).Info("Using failover stream URL for recording")
				break
			}
		}
		r.mutex.Lock()
	}

	if !validation.Valid {
		r.mutex.Unlock()
		recording.Status = "failed"
		recording.LastError = fmt.Sprintf("all stream URLs failed validation: %s", validation.Error)
		r.db.Save(recording)
		r.syncRecordingToDVR(recording)
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
		recording.LastError = "recording end time already passed"
		r.db.Save(recording)
		r.syncRecordingToDVR(recording)
		return fmt.Errorf("recording end time already passed")
	}

	// Build FFmpeg command with quality preset support
	args := r.buildFFmpegArgs(activeStreamURL, duration, outputPath, recording)
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

	// Dual-write: sync to DVR v2 tables
	r.syncRecordingToDVR(recording)

	// Start FFmpeg with retry logic for transient stream errors
	// Use failover URLs for retries
	ffmpegPath := r.ffmpegPath

	go func() {
		defer close(session.Done)

		maxRetries := 3
		retryDelay := 5 * time.Second
		urlIndex := 0
		// Find which URL we started with
		for i, u := range failoverURLs {
			if u == activeStreamURL {
				urlIndex = i
				break
			}
		}

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

			// Try next failover URL on each retry
			urlIndex = (urlIndex + 1) % len(failoverURLs)
			retryURL := failoverURLs[urlIndex]

			logger.Log.WithFields(map[string]interface{}{
				"recording_id": recording.ID,
				"retry_url":    retryURL,
				"url_index":    urlIndex,
			}).Info("Retrying with failover URL")

			// Recreate FFmpeg command for retry with updated duration
			stderr.Reset()
			newDuration := recording.EndTime.Sub(time.Now())
			if newDuration <= 0 {
				logger.Log.WithField("recording_id", recording.ID).Error("Recording end time passed during retry")
				break
			}

			retryArgs := r.buildFFmpegArgs(retryURL, newDuration, outputPath, recording)
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
		errMsg := session.Error.Error()
		if session.ErrorOutput != "" {
			errMsg = session.ErrorOutput
		}
		recording.LastError = errMsg
	} else {
		recording.Status = "completed"
		// Get file size
		if info, err := os.Stat(recording.FilePath); err == nil {
			recording.FileSize = info.Size()
		}
	}

	r.db.Save(&recording)

	// Dual-write: sync to DVR v2 tables (creates DVRFile if completed)
	r.syncRecordingToDVR(&recording)

	// Post-process recording to fix A/V sync, then run commercial detection
	if recording.Status == "completed" {
		go r.postProcessRecording(&recording)
	}
}

// retryFailedRecordings finds failed recordings still within their time window and retries them
func (r *Recorder) retryFailedRecordings(now time.Time) {
	var failedRecordings []models.Recording
	r.db.Where("status = ? AND end_time > ? AND retry_count < max_retries", "failed", now).
		Find(&failedRecordings)

	for _, rec := range failedRecordings {
		rec.RetryCount++
		rec.Status = "scheduled"
		r.db.Save(&rec)

		logger.Log.WithFields(map[string]interface{}{
			"recording_id": rec.ID,
			"title":        rec.Title,
			"retry_count":  rec.RetryCount,
			"max_retries":  rec.MaxRetries,
			"last_error":   rec.LastError,
		}).Info("Auto-retrying failed recording")
	}
}

// postProcessRecording remuxes the recording to fix A/V sync issues from IPTV streams
func (r *Recorder) postProcessRecording(recording *models.Recording) {
	logger.Log.WithField("recording_id", recording.ID).Info("Post-processing recording: converting to MP4 for better compatibility")

	// Output to MP4 format for better Android hardware decoding compatibility
	// Android's MediaCodec has much better support for MP4 than MPEG-TS
	originalPath := recording.FilePath
	mp4Path := strings.TrimSuffix(originalPath, filepath.Ext(originalPath)) + ".mp4"
	tempFile := mp4Path + ".tmp"

	// Use ffmpeg to convert TS to MP4 with timestamp regeneration
	// This fixes A/V sync issues and ensures Android compatibility
	cmd := exec.Command(r.ffmpegPath,
		"-fflags", "+genpts+igndts",    // Regenerate PTS, ignore bad DTS
		"-i", originalPath,
		"-map", "0:v:0",                // First video stream
		"-map", "0:a:0?",               // First audio stream (optional)
		"-c", "copy",                   // Copy codecs (fast remux, no transcode)
		"-f", "mp4",
		"-movflags", "+faststart",      // Move moov atom to start for streaming
		"-y",                           // Overwrite output
		tempFile,
	)

	output, err := cmd.CombinedOutput()
	if err != nil {
		logger.Log.WithFields(map[string]interface{}{
			"recording_id": recording.ID,
			"error":        err.Error(),
			"output":       string(output),
		}).Warn("Failed to convert recording to MP4, keeping original TS file")
		// Clean up temp file if it exists
		os.Remove(tempFile)
	} else {
		// Rename temp to final MP4
		if err := os.Rename(tempFile, mp4Path); err != nil {
			logger.Log.WithError(err).Warn("Failed to rename temp file to MP4")
			os.Remove(tempFile)
		} else {
			// Update recording with new file path
			recording.FilePath = mp4Path
			if info, err := os.Stat(mp4Path); err == nil {
				recording.FileSize = info.Size()
			}
			if err := r.db.Save(recording).Error; err != nil {
				logger.Log.WithError(err).Warn("Failed to update recording path in database")
			} else {
				// Remove original TS file after successful conversion
				if err := os.Remove(originalPath); err != nil {
					logger.Log.WithError(err).Warn("Failed to remove original TS file")
				}
				logger.Log.WithFields(map[string]interface{}{
					"recording_id": recording.ID,
					"new_path":     mp4Path,
				}).Info("Recording converted to MP4 successfully")
			}
		}
	}

	// Run commercial detection after post-processing
	if r.commercialDetect {
		r.runCommercialDetection(recording)
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

// ReprocessRecording remuxes an existing recording to fix A/V sync issues
func (r *Recorder) ReprocessRecording(recordingID uint) error {
	var recording models.Recording
	if err := r.db.First(&recording, recordingID).Error; err != nil {
		return err
	}

	if recording.Status != "completed" {
		return fmt.Errorf("recording is not completed")
	}

	// Run post-processing asynchronously
	go r.postProcessRecording(&recording)
	return nil
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
	if err := r.db.Save(&recording).Error; err != nil {
		return err
	}

	// Dual-write: sync cancellation to DVR v2 tables
	r.syncRecordingToDVR(&recording)
	return nil
}

// ========== DVR v2 Dual-Write Methods ==========

// syncRecordingToDVR creates or updates DVRJob (and optionally DVRFile) entries
// to mirror the legacy Recording model. This is the dual-write bridge for safe migration.
func (r *Recorder) syncRecordingToDVR(recording *models.Recording) {
	if recording == nil || recording.ID == 0 {
		return
	}

	// Look up existing DVRJob linked to this legacy recording
	var job models.DVRJob
	err := r.db.Where("legacy_recording_id = ?", recording.ID).First(&job).Error
	jobExists := err == nil

	// Fetch channel info for cached metadata
	var channelName, channelLogo string
	var channel models.Channel
	if r.db.First(&channel, recording.ChannelID).Error == nil {
		channelName = channel.Name
		channelLogo = channel.Logo
	}

	if !jobExists {
		// Create new DVRJob
		job = models.DVRJob{
			UserID:            recording.UserID,
			ChannelID:         recording.ChannelID,
			ProgramID:         recording.ProgramID,
			Title:             recording.Title,
			Subtitle:          recording.Subtitle,
			Description:       recording.Description,
			StartTime:         recording.StartTime,
			EndTime:           recording.EndTime,
			Status:            recording.Status,
			Priority:          recording.Priority,
			QualityPreset:     recording.QualityPreset,
			TargetBitrate:     recording.TargetBitrate,
			RetryCount:        recording.RetryCount,
			MaxRetries:        recording.MaxRetries,
			LastError:         recording.LastError,
			Cancelled:         recording.Status == "cancelled",
			ChannelName:       channelName,
			ChannelLogo:       channelLogo,
			Category:          recording.Category,
			EpisodeNum:        recording.EpisodeNum,
			IsMovie:           recording.IsMovie,
			SeriesRecord:      recording.SeriesRecord,
			SeriesParentID:    recording.SeriesParentID,
			ConflictGroupID:   recording.ConflictGroupID,
			LegacyRecordingID: &recording.ID,
		}

		if err := r.db.Create(&job).Error; err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"recording_id": recording.ID,
				"error":        err.Error(),
			}).Warn("Failed to create DVRJob for recording (dual-write)")
			return
		}

		logger.Log.WithFields(map[string]interface{}{
			"recording_id": recording.ID,
			"dvr_job_id":   job.ID,
			"status":       job.Status,
		}).Debug("Created DVRJob from legacy recording")
	} else {
		// Update existing DVRJob
		job.Status = recording.Status
		job.Title = recording.Title
		job.Subtitle = recording.Subtitle
		job.Description = recording.Description
		job.StartTime = recording.StartTime
		job.EndTime = recording.EndTime
		job.Priority = recording.Priority
		job.RetryCount = recording.RetryCount
		job.LastError = recording.LastError
		job.Cancelled = recording.Status == "cancelled"
		job.ChannelName = channelName
		job.ChannelLogo = channelLogo
		job.Category = recording.Category
		job.EpisodeNum = recording.EpisodeNum
		job.IsMovie = recording.IsMovie

		if err := r.db.Save(&job).Error; err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"recording_id": recording.ID,
				"dvr_job_id":   job.ID,
				"error":        err.Error(),
			}).Warn("Failed to update DVRJob for recording (dual-write)")
			return
		}

		logger.Log.WithFields(map[string]interface{}{
			"recording_id": recording.ID,
			"dvr_job_id":   job.ID,
			"status":       job.Status,
		}).Debug("Updated DVRJob from legacy recording")
	}

	// Create DVRFile when recording is completed successfully
	if recording.Status == "completed" && recording.FilePath != "" {
		r.createDVRFileFromRecording(recording, &job)
	}
}

// createDVRFileFromRecording creates a DVRFile entry from a completed Recording
func (r *Recorder) createDVRFileFromRecording(recording *models.Recording, job *models.DVRJob) {
	// Check if a DVRFile already exists for this recording
	var existingFile models.DVRFile
	if r.db.Where("legacy_recording_id = ?", recording.ID).First(&existingFile).Error == nil {
		// File already exists, update it
		existingFile.FilePath = recording.FilePath
		existingFile.FileSize = recording.FileSize
		existingFile.Completed = true
		if err := r.db.Save(&existingFile).Error; err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"recording_id": recording.ID,
				"dvr_file_id":  existingFile.ID,
				"error":        err.Error(),
			}).Warn("Failed to update DVRFile (dual-write)")
		}
		// Link job to file
		if job != nil && (job.FileID == nil || *job.FileID != existingFile.ID) {
			job.FileID = &existingFile.ID
			r.db.Save(job)
		}
		return
	}

	// Determine container format from file extension
	container := "ts"
	ext := filepath.Ext(recording.FilePath)
	switch ext {
	case ".mp4":
		container = "mp4"
	case ".mkv":
		container = "mkv"
	case ".ts":
		container = "ts"
	}

	now := time.Now()
	dvrFile := models.DVRFile{
		JobID:             &job.ID,
		Title:             recording.Title,
		Subtitle:          recording.Subtitle,
		Description:       recording.Description,
		Summary:           recording.Summary,
		FilePath:          recording.FilePath,
		FileSize:          recording.FileSize,
		Container:         container,
		Completed:         true,
		Processed:         false,
		Thumb:             recording.Thumb,
		Art:               recording.Art,
		SeasonNumber:      recording.SeasonNumber,
		EpisodeNumber:     recording.EpisodeNumber,
		EpisodeNum:        recording.EpisodeNum,
		Genres:            recording.Genres,
		ContentRating:     recording.ContentRating,
		Year:              recording.Year,
		OriginalAirDate:   recording.OriginalAirDate,
		TMDBId:            recording.TMDBId,
		IsMovie:           recording.IsMovie,
		Rating:            recording.Rating,
		ChannelName:       recording.ChannelName,
		ChannelLogo:       recording.ChannelLogo,
		Category:          recording.Category,
		AiredAt:           &recording.StartTime,
		RecordedAt:        &now,
		LegacyRecordingID: &recording.ID,
	}

	if recording.Duration != nil {
		dvrFile.Duration = *recording.Duration * 60 // Convert minutes to seconds
	}

	if err := r.db.Create(&dvrFile).Error; err != nil {
		logger.Log.WithFields(map[string]interface{}{
			"recording_id": recording.ID,
			"error":        err.Error(),
		}).Warn("Failed to create DVRFile for recording (dual-write)")
		return
	}

	// Link the job to the file
	job.FileID = &dvrFile.ID
	r.db.Save(job)

	logger.Log.WithFields(map[string]interface{}{
		"recording_id": recording.ID,
		"dvr_job_id":   job.ID,
		"dvr_file_id":  dvrFile.ID,
		"file_path":    dvrFile.FilePath,
	}).Info("Created DVRFile from completed recording (dual-write)")

	r.eventBus.Publish(DVREvent{
		Type:   EventFileCreated,
		FileID: dvrFile.ID,
		JobID:  job.ID,
		Title:  dvrFile.Title,
	})

	r.eventBus.Publish(DVREvent{
		Type:  EventJobComplete,
		JobID: job.ID,
		Title: job.Title,
	})

	// Post-creation: enrich, group, and initialize watch state
	r.postProcessDVRFile(&dvrFile)
}

// postProcessDVRFile enriches a file with TMDB metadata, assigns it to a group,
// and initializes watch state for all profiles.
func (r *Recorder) postProcessDVRFile(file *models.DVRFile) {
	// Enrich with TMDB metadata
	if r.enricher != nil {
		if err := r.enricher.EnrichDVRFile(file); err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"dvr_file_id": file.ID,
				"error":       err.Error(),
			}).Warn("Failed to enrich DVRFile")
		}
	}

	// Auto-group the file
	if r.grouper != nil {
		if err := r.grouper.AssignFileToGroup(file); err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"dvr_file_id": file.ID,
				"error":       err.Error(),
			}).Warn("Failed to assign DVRFile to group")
		}

		// Enrich the group if we have one
		if file.GroupID != nil && r.enricher != nil {
			var group models.DVRGroup
			if r.db.First(&group, *file.GroupID).Error == nil {
				r.enricher.EnrichDVRGroup(&group)
				r.eventBus.Publish(DVREvent{
					Type:    EventGroupUpdated,
					GroupID: group.ID,
					Title:   group.Title,
				})
			}
		}
	}

	// Initialize watch state for all profiles
	if r.upnext != nil {
		r.upnext.InitializeFileStateForProfiles(file.ID)

		// Update group state if file was grouped
		if file.GroupID != nil {
			r.upnext.InitializeGroupStateForProfiles(*file.GroupID)
		}
	}
}

// checkScheduledDVRJobs checks the dvr_jobs table for jobs that need to start.
// This handles jobs created directly via the v2 API (not via legacy Recording).
func (r *Recorder) checkScheduledDVRJobs(now time.Time) {
	var jobs []models.DVRJob
	r.db.Where("status = ? AND start_time <= ? AND legacy_recording_id IS NULL", "scheduled", now).Find(&jobs)

	for _, job := range jobs {
		if job.EndTime.Before(now) {
			// Job window passed, mark as failed
			job.Status = "failed"
			job.LastError = "recording window passed before recording could start"
			r.db.Save(&job)
			logger.Log.WithFields(map[string]interface{}{
				"dvr_job_id": job.ID,
				"title":      job.Title,
			}).Warn("DVR job window passed, marking as failed")
			continue
		}

		// Create a legacy Recording from this DVR job so the existing recording
		// pipeline can handle it. The syncRecordingToDVR call in startRecording
		// will link them back together.
		recording := models.Recording{
			UserID:        job.UserID,
			ChannelID:     job.ChannelID,
			ProgramID:     job.ProgramID,
			Title:         job.Title,
			Description:   job.Description,
			StartTime:     job.StartTime,
			EndTime:       job.EndTime,
			Status:        "scheduled",
			Priority:      job.Priority,
			QualityPreset: job.QualityPreset,
			TargetBitrate: job.TargetBitrate,
			Category:      job.Category,
			EpisodeNum:    job.EpisodeNum,
			SeriesRecord:  job.SeriesRecord,
			MaxRetries:    job.MaxRetries,
		}

		if err := r.db.Create(&recording).Error; err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"dvr_job_id": job.ID,
				"error":      err.Error(),
			}).Error("Failed to create legacy Recording from DVR job")
			continue
		}

		// Link the job to the legacy recording
		job.LegacyRecordingID = &recording.ID
		r.db.Save(&job)

		logger.Log.WithFields(map[string]interface{}{
			"dvr_job_id":   job.ID,
			"recording_id": recording.ID,
			"title":        job.Title,
		}).Info("Created legacy Recording from DVR job, starting recording")

		go r.startRecording(&recording)
	}
}

// ========== DVR v2 Public API Methods ==========

// CreateJob creates a DVRJob directly (v2 API).
// The job will be picked up by the scheduler and a legacy Recording will be created
// automatically when it's time to start.
func (r *Recorder) CreateJob(job *models.DVRJob) error {
	if job.Status == "" {
		job.Status = "scheduled"
	}
	if job.MaxRetries == 0 {
		job.MaxRetries = 3
	}
	if job.Priority == 0 {
		job.Priority = 50
	}
	if job.QualityPreset == "" {
		job.QualityPreset = "original"
	}

	// Cache channel metadata
	var channel models.Channel
	if r.db.First(&channel, job.ChannelID).Error == nil {
		job.ChannelName = channel.Name
		job.ChannelLogo = channel.Logo
	}

	if err := r.db.Create(job).Error; err != nil {
		return fmt.Errorf("failed to create DVR job: %w", err)
	}

	logger.Log.WithFields(map[string]interface{}{
		"dvr_job_id": job.ID,
		"title":      job.Title,
		"channel_id": job.ChannelID,
		"start_time": job.StartTime,
		"end_time":   job.EndTime,
		"status":     job.Status,
	}).Info("Created DVR job via v2 API")

	return nil
}

// GetActiveJobs returns DVR jobs that are currently recording or scheduled
func (r *Recorder) GetActiveJobs() []*models.DVRJob {
	var jobs []*models.DVRJob
	r.db.Where("status IN ?", []string{"scheduled", "recording"}).
		Order("start_time ASC").
		Find(&jobs)
	return jobs
}

// CancelJob cancels a DVR job by ID. If there is a linked legacy recording
// that is actively recording, it will also be stopped.
func (r *Recorder) CancelJob(jobID uint) error {
	var job models.DVRJob
	if err := r.db.First(&job, jobID).Error; err != nil {
		return fmt.Errorf("DVR job not found: %w", err)
	}

	if job.Status == "completed" {
		return fmt.Errorf("cannot cancel a completed job")
	}
	if job.Status == "cancelled" {
		return nil // Already cancelled
	}

	// If there's a linked legacy recording, cancel it too
	if job.LegacyRecordingID != nil {
		r.mutex.RLock()
		_, isActive := r.activeRecords[*job.LegacyRecordingID]
		r.mutex.RUnlock()

		if isActive {
			r.stopRecording(*job.LegacyRecordingID)
		}

		var recording models.Recording
		if r.db.First(&recording, *job.LegacyRecordingID).Error == nil {
			recording.Status = "cancelled"
			r.db.Save(&recording)
		}
	}

	job.Status = "cancelled"
	job.Cancelled = true
	if err := r.db.Save(&job).Error; err != nil {
		return fmt.Errorf("failed to cancel DVR job: %w", err)
	}

	logger.Log.WithFields(map[string]interface{}{
		"dvr_job_id":          job.ID,
		"title":               job.Title,
		"legacy_recording_id": job.LegacyRecordingID,
	}).Info("Cancelled DVR job")

	return nil
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

// ConflictInfo represents information about a recording conflict
type ConflictInfo struct {
	Recording        *models.Recording   `json:"recording"`
	ConflictingWith  []*models.Recording `json:"conflictingWith"`
	WillBeRecorded   bool                `json:"willBeRecorded"`
	ConflictResolved bool                `json:"conflictResolved"`
}

// DefaultMaxConcurrentRecordings is the default maximum number of simultaneous recordings
// 0 means unlimited. This can be overridden via settings.
const DefaultMaxConcurrentRecordings = 0

// FindConflicts checks if a recording conflicts with existing scheduled recordings
func (r *Recorder) FindConflicts(recording *models.Recording) []*models.Recording {
	var conflicts []*models.Recording

	r.db.Where(
		"id != ? AND user_id = ? AND status IN ? AND start_time < ? AND end_time > ?",
		recording.ID,
		recording.UserID,
		[]string{"scheduled", "recording"},
		recording.EndTime,
		recording.StartTime,
	).Order("priority DESC, created_at ASC").Find(&conflicts)

	return conflicts
}

// FindConflictsForNewRecording checks for conflicts before creating a recording
func (r *Recorder) FindConflictsForNewRecording(userID uint, startTime, endTime time.Time, excludeID uint) []*models.Recording {
	var conflicts []*models.Recording

	query := r.db.Where(
		"user_id = ? AND status IN ? AND start_time < ? AND end_time > ?",
		userID,
		[]string{"scheduled", "recording"},
		endTime,
		startTime,
	)

	if excludeID > 0 {
		query = query.Where("id != ?", excludeID)
	}

	query.Order("priority DESC, created_at ASC").Find(&conflicts)

	return conflicts
}

// GetAllConflicts returns all scheduled recordings that have conflicts
func (r *Recorder) GetAllConflicts(userID uint) []ConflictInfo {
	var scheduled []models.Recording
	r.db.Where("user_id = ? AND status = ?", userID, "scheduled").
		Order("start_time ASC").Find(&scheduled)

	var conflictInfos []ConflictInfo
	processedPairs := make(map[string]bool)

	for i := range scheduled {
		recording := &scheduled[i]
		conflicts := r.FindConflicts(recording)

		if len(conflicts) == 0 {
			continue
		}

		// Create a unique key for this conflict group to avoid duplicates
		for _, conflict := range conflicts {
			pairKey := fmt.Sprintf("%d-%d", minUint(recording.ID, conflict.ID), maxUint(recording.ID, conflict.ID))
			if processedPairs[pairKey] {
				continue
			}
			processedPairs[pairKey] = true
		}

		// Determine if this recording will be recorded based on priority
		willBeRecorded := true
		for _, conflict := range conflicts {
			if conflict.Priority > recording.Priority {
				willBeRecorded = false
				break
			} else if conflict.Priority == recording.Priority && conflict.CreatedAt.Before(recording.CreatedAt) {
				willBeRecorded = false
				break
			}
		}

		conflictInfos = append(conflictInfos, ConflictInfo{
			Recording:       recording,
			ConflictingWith: conflicts,
			WillBeRecorded:  willBeRecorded,
		})
	}

	return conflictInfos
}

// ResolveConflictsAtRecordingTime handles conflicts when it's time to start recording
// Returns the recordings that should actually start
func (r *Recorder) ResolveConflictsAtRecordingTime(recordings []models.Recording) []models.Recording {
	// Get max concurrent from settings, default to unlimited (0)
	maxConcurrent := r.getMaxConcurrentRecordings()

	// 0 means unlimited - start all recordings
	if maxConcurrent == 0 || len(recordings) <= maxConcurrent {
		return recordings
	}

	// Sort by priority (desc), then by created_at (asc) for tie-breaking
	sortedRecordings := make([]models.Recording, len(recordings))
	copy(sortedRecordings, recordings)

	for i := 0; i < len(sortedRecordings)-1; i++ {
		for j := i + 1; j < len(sortedRecordings); j++ {
			// Higher priority wins
			if sortedRecordings[j].Priority > sortedRecordings[i].Priority {
				sortedRecordings[i], sortedRecordings[j] = sortedRecordings[j], sortedRecordings[i]
			} else if sortedRecordings[j].Priority == sortedRecordings[i].Priority {
				// Same priority: earlier created wins
				if sortedRecordings[j].CreatedAt.Before(sortedRecordings[i].CreatedAt) {
					sortedRecordings[i], sortedRecordings[j] = sortedRecordings[j], sortedRecordings[i]
				}
			}
		}
	}

	// Take only the top maxConcurrent
	winners := sortedRecordings[:maxConcurrent]
	losers := sortedRecordings[maxConcurrent:]

	// Mark losers as conflict-skipped
	for _, loser := range losers {
		loser.Status = "conflict"
		r.db.Save(&loser)
		logger.Log.WithFields(map[string]interface{}{
			"recording_id":      loser.ID,
			"title":             loser.Title,
			"priority":          loser.Priority,
			"conflicted_by":     winners[0].Title,
			"conflicted_by_pri": winners[0].Priority,
		}).Warn("Recording skipped due to conflict with higher priority recording")
	}

	return winners
}

// SetRecordingPriority updates the priority of a recording
func (r *Recorder) SetRecordingPriority(recordingID uint, priority int) error {
	if priority < 0 || priority > 100 {
		return fmt.Errorf("priority must be between 0 and 100")
	}

	var recording models.Recording
	if err := r.db.First(&recording, recordingID).Error; err != nil {
		return fmt.Errorf("recording not found: %w", err)
	}

	recording.Priority = priority
	return r.db.Save(&recording).Error
}

// getMaxConcurrentRecordings returns the max concurrent recordings setting
// Returns 0 for unlimited (default)
func (r *Recorder) getMaxConcurrentRecordings() int {
	var setting models.Setting
	if err := r.db.Where("key = ?", "dvr_max_concurrent").First(&setting).Error; err != nil {
		return DefaultMaxConcurrentRecordings // Default: unlimited
	}

	var value int
	if _, err := fmt.Sscanf(setting.Value, "%d", &value); err != nil {
		return DefaultMaxConcurrentRecordings
	}

	return value
}

// helper functions for min/max uint
func minUint(a, b uint) uint {
	if a < b {
		return a
	}
	return b
}

func maxUint(a, b uint) uint {
	if a > b {
		return a
	}
	return b
}
