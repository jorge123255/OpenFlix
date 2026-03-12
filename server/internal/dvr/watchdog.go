package dvr

import (
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// ffprobeGetDuration runs ffprobe on filePath and returns the duration in seconds.
// Returns 0 on any error.
func ffprobeGetDuration(ffprobePath string, filePath string) float64 {
	cmd := exec.Command(ffprobePath,
		"-v", "quiet",
		"-show_entries", "format=duration",
		"-of", "csv=p=0",
		filePath,
	)
	out, err := cmd.Output()
	if err != nil {
		return 0
	}
	s := strings.TrimSpace(string(out))
	if s == "" {
		return 0
	}
	val, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0
	}
	return val
}

// ffprobePath returns the path to the ffprobe binary by replacing "ffmpeg" with "ffprobe"
// in the recorder's ffmpegPath, falling back to /usr/local/bin/ffprobe.
func (r *Recorder) ffprobePath() string {
	if strings.Contains(r.ffmpegPath, "ffmpeg") {
		candidate := strings.Replace(r.ffmpegPath, "ffmpeg", "ffprobe", 1)
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}
	return "/usr/local/bin/ffprobe"
}

// checkRecordingIntegrity uses ffprobe to verify the actual duration of the output file
// against the expected recording window. If the file is significantly shorter than expected
// (< 80% and gap > 60s), the recording is marked as degraded in the database.
func (r *Recorder) checkRecordingIntegrity(recording *models.Recording, filePath string) {
	expectedSec := recording.EndTime.Sub(recording.StartTime).Seconds()
	if expectedSec <= 0 {
		return
	}

	actualSec := ffprobeGetDuration(r.ffprobePath(), filePath)
	if actualSec <= 0 {
		// ffprobe failed — skip integrity check rather than false-positive
		logger.Log.WithField("recording_id", recording.ID).Debug("ffprobe returned 0 duration, skipping integrity check")
		return
	}

	gap := expectedSec - actualSec
	ratio := actualSec / expectedSec

	logger.Log.WithFields(map[string]interface{}{
		"recording_id": recording.ID,
		"expected_sec": expectedSec,
		"actual_sec":   actualSec,
		"gap_sec":      gap,
		"ratio":        ratio,
	}).Debug("Recording integrity check")

	if ratio < 0.80 && gap > 60 {
		recording.Degraded = true
		recording.ActualDurationSec = actualSec
		recording.LastError = "recording appears truncated: actual duration is less than 80% of expected"
		if err := r.db.Save(recording).Error; err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"recording_id": recording.ID,
				"error":        err.Error(),
			}).Warn("Failed to mark recording as degraded")
		} else {
			logger.Log.WithFields(map[string]interface{}{
				"recording_id": recording.ID,
				"expected_sec": expectedSec,
				"actual_sec":   actualSec,
				"gap_sec":      gap,
			}).Warn("Recording marked degraded: duration below 80% of expected")
		}
	}
}

// scheduleGapFillRecording searches for an upcoming airing of the same show within
// 7 days and schedules a replacement recording if one is found and not already covered.
func (r *Recorder) scheduleGapFillRecording(recording *models.Recording) {
	now := time.Now().UTC()
	windowEnd := now.Add(7 * 24 * time.Hour)

	var candidates []models.Program
	r.db.Where("title = ? AND start > ? AND start < ?", recording.Title, now, windowEnd).
		Order("start ASC").Find(&candidates)

	for _, prog := range candidates {
		// Skip the same start time
		if prog.Start.Equal(recording.StartTime) {
			continue
		}

		// Check if a recording or DVR job already covers this slot
		var existingRec models.Recording
		if r.db.Where("title = ? AND start_time = ? AND user_id = ?",
			recording.Title, prog.Start, recording.UserID).
			First(&existingRec).Error == nil {
			continue
		}
		var existingJob models.DVRJob
		if r.db.Where("title = ? AND start_time = ? AND user_id = ?",
			recording.Title, prog.Start, recording.UserID).
			First(&existingJob).Error == nil {
			continue
		}

		// Find channel
		var channel models.Channel
		if r.db.Where("channel_id = ?", prog.ChannelID).First(&channel).Error != nil {
			continue
		}

		// Create replacement recording
		replacement := models.Recording{
			UserID:       recording.UserID,
			ChannelID:    channel.ID,
			ProgramID:    &prog.ID,
			Title:        recording.Title,
			Description:  recording.Description,
			StartTime:    prog.Start,
			EndTime:      prog.End,
			Status:       "scheduled",
			SeriesRuleID: recording.SeriesRuleID,
			Category:     recording.Category,
			Priority:     recording.Priority,
			QualityPreset: recording.QualityPreset,
		}

		if err := r.db.Create(&replacement).Error; err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"recording_id":    recording.ID,
				"replacement_err": err.Error(),
			}).Warn("Gap fill: failed to create replacement recording")
			continue
		}

		r.syncRecordingToDVR(&replacement)

		logger.Log.WithFields(map[string]interface{}{
			"original_id":     recording.ID,
			"replacement_id":  replacement.ID,
			"title":           recording.Title,
			"new_start":       prog.Start.Format("2006-01-02 15:04"),
			"channel":         channel.Name,
		}).Info("Gap fill: scheduled replacement recording for degraded recording")

		return // Only schedule one replacement
	}

	logger.Log.WithFields(map[string]interface{}{
		"recording_id": recording.ID,
		"title":        recording.Title,
	}).Info("Gap fill: no alternative airing found within 7 days")
}

// runStreamWatchdog monitors an active ffmpeg recording session by watching the
// output file's size every 10 seconds. If the file size has not changed for
// 3 consecutive checks (30 seconds), it kills the ffmpeg process to trigger
// the retry/failure handling path.
func (r *Recorder) runStreamWatchdog(session *RecordingSession, outputPath string) {
	ticker := time.NewTicker(10 * time.Second)
	defer ticker.Stop()

	var stuckCount int

	for {
		select {
		case <-session.WatchdogStop:
			return
		case <-session.Done:
			return
		case <-ticker.C:
			info, err := os.Stat(outputPath)
			if err != nil {
				// File not yet created or already removed — reset counter
				stuckCount = 0
				continue
			}

			currentSize := info.Size()
			if currentSize == session.LastFileSize {
				stuckCount++
				logger.Log.WithFields(map[string]interface{}{
					"recording_id": session.Recording.ID,
					"file_size":    currentSize,
					"stuck_count":  stuckCount,
				}).Warn("Stream watchdog: file size unchanged")

				if stuckCount >= 3 {
					// Stream appears frozen — kill ffmpeg
					if session.Process != nil && session.Process.Process != nil {
						logger.Log.WithFields(map[string]interface{}{
							"recording_id": session.Recording.ID,
							"file_size":    currentSize,
						}).Error("Stream watchdog: killing stalled ffmpeg process")
						session.Process.Process.Kill()
					}
					stuckCount = 0
				}
			} else {
				stuckCount = 0
				session.LastFileSize = currentSize
			}
		}
	}
}
