package livetv

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// segmentPattern matches segment files to extract their index
var segmentIndexPattern = regexp.MustCompile(`segment_(\d+)\.ts$`)

// TimeShiftConfig configures the time-shift buffer
type TimeShiftConfig struct {
	FFmpegPath    string
	BufferDir     string
	BufferHours   int // How many hours of content to keep
	SegmentLength int // Segment length in seconds
}

// TimeShiftBuffer manages live TV buffering for catch-up TV
type TimeShiftBuffer struct {
	db            *gorm.DB
	config        TimeShiftConfig
	activeBuffers map[uint]*ChannelBuffer
	mutex         sync.RWMutex
	cleanupStop   chan struct{}
}

// ChannelBuffer represents an active buffer for a channel
type ChannelBuffer struct {
	ChannelID   uint
	Process     *exec.Cmd
	StartTime   time.Time
	BufferDir   string
	SegmentList []string
	mutex       sync.Mutex
}

// TimeShiftSegment represents a buffered segment
type TimeShiftSegment struct {
	Index     int       `json:"index"`
	StartTime time.Time `json:"startTime"`
	Duration  float64   `json:"duration"`
	Path      string    `json:"path"`
}

// CatchUpProgram represents a program available for catch-up
type CatchUpProgram struct {
	ChannelID   uint      `json:"channelId"`
	ProgramID   string    `json:"programId"`
	Title       string    `json:"title"`
	StartTime   time.Time `json:"startTime"`
	EndTime     time.Time `json:"endTime"`
	Duration    int       `json:"duration"` // seconds
	Description string    `json:"description,omitempty"`
	Thumb       string    `json:"thumb,omitempty"`
	Available   bool      `json:"available"`
}

// NewTimeShiftBuffer creates a new time-shift buffer manager
func NewTimeShiftBuffer(db *gorm.DB, config TimeShiftConfig) *TimeShiftBuffer {
	if config.FFmpegPath == "" {
		if path, err := exec.LookPath("ffmpeg"); err == nil {
			config.FFmpegPath = path
		} else {
			config.FFmpegPath = "ffmpeg"
		}
	}

	if config.BufferHours <= 0 {
		config.BufferHours = 4 // Default 4 hours
	}

	if config.SegmentLength <= 0 {
		config.SegmentLength = 6 // 6 second segments
	}

	os.MkdirAll(config.BufferDir, 0755)

	tsb := &TimeShiftBuffer{
		db:            db,
		config:        config,
		activeBuffers: make(map[uint]*ChannelBuffer),
		cleanupStop:   make(chan struct{}),
	}

	// Clean up any orphaned buffer directories from previous runs
	tsb.cleanupOrphanedBuffers()

	// Start cleanup routine
	go tsb.cleanupLoop()

	return tsb
}

// cleanupOrphanedBuffers removes buffer directories that don't have an active process
func (tsb *TimeShiftBuffer) cleanupOrphanedBuffers() {
	entries, err := os.ReadDir(tsb.config.BufferDir)
	if err != nil {
		logger.Log.WithField("error", err).Warn("Failed to read buffer directory for orphan cleanup")
		return
	}

	for _, entry := range entries {
		if entry.IsDir() && strings.HasPrefix(entry.Name(), "channel_") {
			dirPath := filepath.Join(tsb.config.BufferDir, entry.Name())
			// Remove orphaned directory
			if err := os.RemoveAll(dirPath); err != nil {
				logger.Log.WithFields(map[string]interface{}{
					"directory": dirPath,
					"error":     err,
				}).Warn("Failed to cleanup orphaned buffer directory")
			} else {
				logger.Log.WithField("directory", entry.Name()).Info("Cleaned up orphaned buffer directory")
			}
		}
	}
}

// StartBuffer starts buffering a channel
func (tsb *TimeShiftBuffer) StartBuffer(channel *models.Channel) error {
	tsb.mutex.Lock()
	defer tsb.mutex.Unlock()

	// Check if already buffering
	if _, exists := tsb.activeBuffers[channel.ID]; exists {
		return nil // Already buffering
	}

	// Create channel buffer directory
	bufferDir := filepath.Join(tsb.config.BufferDir, fmt.Sprintf("channel_%d", channel.ID))
	os.MkdirAll(bufferDir, 0755)

	// Build FFmpeg command for HLS segmenting
	playlistPath := filepath.Join(bufferDir, "live.m3u8")
	segmentPattern := filepath.Join(bufferDir, "segment_%05d.ts")

	// FFmpeg command to create HLS segments from live stream
	args := []string{
		"-i", channel.StreamURL,
		"-c", "copy",
		"-f", "hls",
		"-hls_time", strconv.Itoa(tsb.config.SegmentLength),
		"-hls_list_size", "0", // Keep all segments
		"-hls_flags", "delete_segments+append_list",
		"-hls_segment_filename", segmentPattern,
		playlistPath,
	}

	cmd := exec.Command(tsb.config.FFmpegPath, args...)
	cmd.Dir = bufferDir

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("failed to start buffer: %w", err)
	}

	buffer := &ChannelBuffer{
		ChannelID: channel.ID,
		Process:   cmd,
		StartTime: time.Now(),
		BufferDir: bufferDir,
	}

	tsb.activeBuffers[channel.ID] = buffer

	// Monitor process in background
	go func() {
		err := cmd.Wait()
		tsb.mutex.Lock()
		delete(tsb.activeBuffers, channel.ID)
		tsb.mutex.Unlock()
		if err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"channel_id": channel.ID,
				"error":      err,
			}).Warn("Time-shift buffer process exited with error")
		}
	}()

	logger.Log.WithFields(map[string]interface{}{
		"channel_id":   channel.ID,
		"channel_name": channel.Name,
		"buffer_dir":   bufferDir,
	}).Info("Started time-shift buffer for channel")
	return nil
}

// StopBuffer stops buffering a channel and cleans up its files
func (tsb *TimeShiftBuffer) StopBuffer(channelID uint) {
	tsb.mutex.Lock()

	buffer, exists := tsb.activeBuffers[channelID]
	if !exists {
		tsb.mutex.Unlock()
		return
	}

	bufferDir := buffer.BufferDir
	if buffer.Process != nil && buffer.Process.Process != nil {
		buffer.Process.Process.Kill()
	}
	delete(tsb.activeBuffers, channelID)
	tsb.mutex.Unlock()

	// Clean up buffer directory after stopping
	if bufferDir != "" {
		if err := os.RemoveAll(bufferDir); err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"channel_id": channelID,
				"directory":  bufferDir,
				"error":      err,
			}).Warn("Failed to cleanup buffer directory after stopping")
		} else {
			logger.Log.WithFields(map[string]interface{}{
				"channel_id": channelID,
				"directory":  bufferDir,
			}).Debug("Cleaned up buffer directory after stopping")
		}
	}

	logger.Log.WithField("channel_id", channelID).Info("Stopped time-shift buffer for channel")
}

// GetBufferStatus returns the buffer status for a channel
func (tsb *TimeShiftBuffer) GetBufferStatus(channelID uint) (bool, time.Time, time.Duration) {
	tsb.mutex.RLock()
	defer tsb.mutex.RUnlock()

	buffer, exists := tsb.activeBuffers[channelID]
	if !exists {
		return false, time.Time{}, 0
	}

	duration := time.Since(buffer.StartTime)
	maxDuration := time.Duration(tsb.config.BufferHours) * time.Hour
	if duration > maxDuration {
		duration = maxDuration
	}

	return true, buffer.StartTime, duration
}

// GetTimeShiftURL returns a URL for time-shifted playback
func (tsb *TimeShiftBuffer) GetTimeShiftURL(channelID uint, offsetSeconds int) (string, error) {
	tsb.mutex.RLock()
	_, exists := tsb.activeBuffers[channelID]
	tsb.mutex.RUnlock()

	if !exists {
		return "", fmt.Errorf("channel %d is not being buffered", channelID)
	}

	// Calculate which segment to start from
	segmentIndex := offsetSeconds / tsb.config.SegmentLength

	// Return playlist URL with start offset
	return fmt.Sprintf("/livetv/timeshift/%d/stream.m3u8?start=%d", channelID, segmentIndex), nil
}

// GetCatchUpPrograms returns programs available for catch-up on a channel
func (tsb *TimeShiftBuffer) GetCatchUpPrograms(channelID uint, channelEPGID string) ([]CatchUpProgram, error) {
	tsb.mutex.RLock()
	buf, exists := tsb.activeBuffers[channelID]
	tsb.mutex.RUnlock()

	if !exists {
		return nil, fmt.Errorf("channel %d is not being buffered", channelID)
	}

	// Get EPG programs that fall within the buffer window
	bufferStart := buf.StartTime
	now := time.Now()

	var programs []models.Program
	tsb.db.Where("channel_id = ? AND start_time >= ? AND start_time <= ?",
		channelEPGID, bufferStart, now).
		Order("start_time ASC").
		Find(&programs)

	result := make([]CatchUpProgram, 0, len(programs))
	for _, p := range programs {
		// Check if the entire program is in the buffer
		available := p.Start.After(bufferStart) || p.Start.Equal(bufferStart)

		result = append(result, CatchUpProgram{
			ChannelID:   channelID,
			ProgramID:   fmt.Sprintf("%d", p.ID),
			Title:       p.Title,
			StartTime:   p.Start,
			EndTime:     p.End,
			Duration:    int(p.End.Sub(p.Start).Seconds()),
			Description: p.Description,
			Thumb:       p.Icon,
			Available:   available,
		})
	}

	return result, nil
}

// GetStartOverURL returns a URL to start watching the current program from the beginning
func (tsb *TimeShiftBuffer) GetStartOverURL(channelID uint, channelEPGID string) (string, error) {
	// Get the current program
	var program models.Program
	now := time.Now()

	err := tsb.db.Where("channel_id = ? AND start <= ? AND end > ?",
		channelEPGID, now, now).First(&program).Error

	if err != nil {
		return "", fmt.Errorf("no current program found: %w", err)
	}

	// Calculate offset from start of program
	tsb.mutex.RLock()
	buf, exists := tsb.activeBuffers[channelID]
	tsb.mutex.RUnlock()

	if !exists {
		return "", fmt.Errorf("channel %d is not being buffered", channelID)
	}

	// Calculate how many seconds back the program started
	programStart := program.Start
	if programStart.Before(buf.StartTime) {
		// Program started before buffer, start from buffer beginning
		programStart = buf.StartTime
	}

	offsetSeconds := int(now.Sub(programStart).Seconds())

	return tsb.GetTimeShiftURL(channelID, offsetSeconds)
}

// GenerateTimeshiftPlaylist generates an M3U8 playlist for timeshift playback
func (tsb *TimeShiftBuffer) GenerateTimeshiftPlaylist(channelID uint, startSegment int) (string, error) {
	tsb.mutex.RLock()
	buffer, exists := tsb.activeBuffers[channelID]
	tsb.mutex.RUnlock()

	if !exists {
		return "", fmt.Errorf("channel %d is not being buffered", channelID)
	}

	// List available segments
	segments, err := filepath.Glob(filepath.Join(buffer.BufferDir, "segment_*.ts"))
	if err != nil {
		return "", err
	}

	sort.Strings(segments)

	// Filter segments from startSegment onwards
	var playlist strings.Builder
	playlist.WriteString("#EXTM3U\n")
	playlist.WriteString(fmt.Sprintf("#EXT-X-TARGETDURATION:%d\n", tsb.config.SegmentLength))
	playlist.WriteString(fmt.Sprintf("#EXT-X-MEDIA-SEQUENCE:%d\n", startSegment))

	for i, seg := range segments {
		if i >= startSegment {
			playlist.WriteString(fmt.Sprintf("#EXTINF:%d.0,\n", tsb.config.SegmentLength))
			playlist.WriteString(fmt.Sprintf("/livetv/timeshift/%d/segment/%s\n",
				channelID, filepath.Base(seg)))
		}
	}

	return playlist.String(), nil
}

// cleanupLoop periodically cleans up old segments
func (tsb *TimeShiftBuffer) cleanupLoop() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			tsb.cleanupOldSegments()
		case <-tsb.cleanupStop:
			return
		}
	}
}

// cleanupOldSegments removes segments older than the buffer window
// Uses segment index instead of modification time for more reliable cleanup
func (tsb *TimeShiftBuffer) cleanupOldSegments() {
	tsb.mutex.RLock()
	buffers := make([]*ChannelBuffer, 0, len(tsb.activeBuffers))
	for _, b := range tsb.activeBuffers {
		buffers = append(buffers, b)
	}
	tsb.mutex.RUnlock()

	// Calculate max segments to keep based on buffer hours and segment length
	maxSegments := (tsb.config.BufferHours * 3600) / tsb.config.SegmentLength

	for _, buffer := range buffers {
		segments, err := filepath.Glob(filepath.Join(buffer.BufferDir, "segment_*.ts"))
		if err != nil {
			continue
		}

		if len(segments) <= maxSegments {
			continue // No cleanup needed
		}

		// Extract segment indices and sort
		type segmentInfo struct {
			path  string
			index int
		}
		segmentList := make([]segmentInfo, 0, len(segments))

		for _, seg := range segments {
			matches := segmentIndexPattern.FindStringSubmatch(filepath.Base(seg))
			if len(matches) == 2 {
				if idx, err := strconv.Atoi(matches[1]); err == nil {
					segmentList = append(segmentList, segmentInfo{path: seg, index: idx})
				}
			}
		}

		// Sort by index ascending
		sort.Slice(segmentList, func(i, j int) bool {
			return segmentList[i].index < segmentList[j].index
		})

		// Remove oldest segments beyond max
		segmentsToRemove := len(segmentList) - maxSegments
		if segmentsToRemove > 0 {
			removedCount := 0
			for i := 0; i < segmentsToRemove; i++ {
				if err := os.Remove(segmentList[i].path); err == nil {
					removedCount++
				}
			}

			if removedCount > 0 {
				logger.Log.WithFields(map[string]interface{}{
					"channel_id":       buffer.ChannelID,
					"segments_removed": removedCount,
					"segments_kept":    len(segmentList) - removedCount,
				}).Debug("Cleaned up old timeshift segments")
			}
		}
	}
}

// Stop stops all buffers and cleanup
func (tsb *TimeShiftBuffer) Stop() {
	close(tsb.cleanupStop)

	tsb.mutex.Lock()
	// Collect buffer directories before clearing map
	dirsToCleanup := make([]string, 0, len(tsb.activeBuffers))
	for channelID, buffer := range tsb.activeBuffers {
		if buffer.Process != nil && buffer.Process.Process != nil {
			buffer.Process.Process.Kill()
		}
		if buffer.BufferDir != "" {
			dirsToCleanup = append(dirsToCleanup, buffer.BufferDir)
		}
		delete(tsb.activeBuffers, channelID)
	}
	tsb.mutex.Unlock()

	// Cleanup directories outside lock
	for _, dir := range dirsToCleanup {
		if err := os.RemoveAll(dir); err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"directory": dir,
				"error":     err,
			}).Warn("Failed to cleanup buffer directory on shutdown")
		}
	}

	logger.Log.Info("Stopped all time-shift buffers")
}

// IsBuffering returns whether a channel is being buffered
func (tsb *TimeShiftBuffer) IsBuffering(channelID uint) bool {
	tsb.mutex.RLock()
	defer tsb.mutex.RUnlock()
	_, exists := tsb.activeBuffers[channelID]
	return exists
}

// GetBufferDir returns the buffer directory for a channel, or empty string if not buffering
func (tsb *TimeShiftBuffer) GetBufferDir(channelID uint) string {
	tsb.mutex.RLock()
	defer tsb.mutex.RUnlock()
	if buffer, exists := tsb.activeBuffers[channelID]; exists {
		return buffer.BufferDir
	}
	return ""
}
