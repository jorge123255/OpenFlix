package dvr

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
	"time"

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
	Recording *models.Recording
	Process   *exec.Cmd
	Done      chan struct{}
	Error     error
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
		}
	}
}

// checkScheduledRecordings starts recordings that are due
func (r *Recorder) checkScheduledRecordings() {
	now := time.Now()

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

	now := time.Now()

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

	session := &RecordingSession{
		Recording: recording,
		Process:   exec.Command(r.ffmpegPath, args...),
		Done:      make(chan struct{}),
	}

	r.activeRecords[recording.ID] = session
	r.mutex.Unlock()

	// Update recording status
	recording.Status = "recording"
	recording.FilePath = outputPath
	r.db.Save(recording)

	// Start FFmpeg
	go func() {
		defer close(session.Done)
		session.Error = session.Process.Run()
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
		fmt.Printf("Commercial detection failed for recording %d: %v\n", recording.ID, err)
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
