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

// archiveSegmentPattern matches segment files to extract their index
var archiveSegmentPattern = regexp.MustCompile(`segment_(\d+)\.ts$`)

// ArchiveConfig configures the archive manager
type ArchiveConfig struct {
	FFmpegPath     string
	ArchiveDir     string
	SegmentLength  int  // Segment length in seconds (default 6)
	CleanupMinutes int  // How often to run cleanup (default 30)
	MaxDays        int  // Maximum archive days allowed (default 7)
}

// ArchiveManager manages continuous recording for catch-up TV
type ArchiveManager struct {
	db            *gorm.DB
	config        ArchiveConfig
	activeRecords map[uint]*ChannelArchive
	mutex         sync.RWMutex
	stopChan      chan struct{}
	wg            sync.WaitGroup
}

// ChannelArchive represents an active archive recording for a channel
type ChannelArchive struct {
	ChannelID     uint
	ChannelName   string
	Process       *exec.Cmd
	StartTime     time.Time
	ArchiveDir    string
	SegmentLength int
	RetentionDays int
	mutex         sync.Mutex
}

// NewArchiveManager creates a new archive manager
func NewArchiveManager(db *gorm.DB, config ArchiveConfig) *ArchiveManager {
	if config.FFmpegPath == "" {
		if path, err := exec.LookPath("ffmpeg"); err == nil {
			config.FFmpegPath = path
		} else {
			config.FFmpegPath = "ffmpeg"
		}
	}

	if config.SegmentLength <= 0 {
		config.SegmentLength = 6 // 6 second segments
	}

	if config.CleanupMinutes <= 0 {
		config.CleanupMinutes = 30 // Cleanup every 30 minutes
	}

	if config.MaxDays <= 0 {
		config.MaxDays = 7 // Max 7 days archive
	}

	os.MkdirAll(config.ArchiveDir, 0755)

	am := &ArchiveManager{
		db:            db,
		config:        config,
		activeRecords: make(map[uint]*ChannelArchive),
		stopChan:      make(chan struct{}),
	}

	return am
}

// Start starts the archive manager
func (am *ArchiveManager) Start() {
	logger.Log.Info("Starting Archive Manager")

	// Start recording for channels with archive enabled
	am.syncArchiveChannels()

	// Start background tasks
	am.wg.Add(2)
	go am.syncLoop()
	go am.cleanupLoop()
}

// Stop stops all archive recordings
func (am *ArchiveManager) Stop() {
	logger.Log.Info("Stopping Archive Manager")
	close(am.stopChan)

	am.mutex.Lock()
	for channelID, archive := range am.activeRecords {
		if archive.Process != nil && archive.Process.Process != nil {
			archive.Process.Process.Kill()
		}
		delete(am.activeRecords, channelID)
	}
	am.mutex.Unlock()

	am.wg.Wait()
	logger.Log.Info("Archive Manager stopped")
}

// syncLoop periodically syncs archive channels with database
func (am *ArchiveManager) syncLoop() {
	defer am.wg.Done()
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			am.syncArchiveChannels()
		case <-am.stopChan:
			return
		}
	}
}

// syncArchiveChannels syncs active recordings with database settings
func (am *ArchiveManager) syncArchiveChannels() {
	// Get all channels with archive enabled
	var channels []models.Channel
	am.db.Where("archive_enabled = ? AND enabled = ?", true, true).Find(&channels)

	am.mutex.Lock()
	defer am.mutex.Unlock()

	// Build set of channel IDs that should be recording
	shouldRecord := make(map[uint]models.Channel)
	for _, ch := range channels {
		shouldRecord[ch.ID] = ch
	}

	// Stop recording channels that no longer need it
	for channelID := range am.activeRecords {
		if _, exists := shouldRecord[channelID]; !exists {
			am.stopRecordingLocked(channelID)
		}
	}

	// Start recording channels that need it
	for channelID, channel := range shouldRecord {
		if _, exists := am.activeRecords[channelID]; !exists {
			am.startRecordingLocked(&channel)
		}
	}
}

// startRecordingLocked starts recording a channel (must hold mutex)
func (am *ArchiveManager) startRecordingLocked(channel *models.Channel) {
	archiveDir := filepath.Join(am.config.ArchiveDir, fmt.Sprintf("channel_%d", channel.ID))
	os.MkdirAll(archiveDir, 0755)

	playlistPath := filepath.Join(archiveDir, "live.m3u8")
	segmentPattern := filepath.Join(archiveDir, "segment_%08d.ts")

	// FFmpeg command for continuous HLS recording
	args := []string{
		"-reconnect", "1",
		"-reconnect_streamed", "1",
		"-reconnect_delay_max", "30",
		"-i", channel.StreamURL,
		"-c", "copy",
		"-f", "hls",
		"-hls_time", strconv.Itoa(am.config.SegmentLength),
		"-hls_list_size", "0", // Keep all segments in playlist
		"-hls_flags", "append_list+omit_endlist",
		"-hls_segment_filename", segmentPattern,
		playlistPath,
	}

	cmd := exec.Command(am.config.FFmpegPath, args...)
	cmd.Dir = archiveDir

	if err := cmd.Start(); err != nil {
		logger.Log.WithFields(map[string]interface{}{
			"channel_id":   channel.ID,
			"channel_name": channel.Name,
			"error":        err,
		}).Error("Failed to start archive recording")
		return
	}

	retentionDays := channel.ArchiveDays
	if retentionDays <= 0 {
		retentionDays = 7
	}
	if retentionDays > am.config.MaxDays {
		retentionDays = am.config.MaxDays
	}

	archive := &ChannelArchive{
		ChannelID:     channel.ID,
		ChannelName:   channel.Name,
		Process:       cmd,
		StartTime:     time.Now(),
		ArchiveDir:    archiveDir,
		SegmentLength: am.config.SegmentLength,
		RetentionDays: retentionDays,
	}

	am.activeRecords[channel.ID] = archive

	// Monitor process
	go func(channelID uint) {
		err := cmd.Wait()
		am.mutex.Lock()
		delete(am.activeRecords, channelID)
		am.mutex.Unlock()

		if err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"channel_id": channelID,
				"error":      err,
			}).Warn("Archive recording process exited with error, will restart on next sync")
		}
	}(channel.ID)

	logger.Log.WithFields(map[string]interface{}{
		"channel_id":     channel.ID,
		"channel_name":   channel.Name,
		"retention_days": retentionDays,
	}).Info("Started archive recording for channel")
}

// stopRecordingLocked stops recording a channel (must hold mutex)
func (am *ArchiveManager) stopRecordingLocked(channelID uint) {
	archive, exists := am.activeRecords[channelID]
	if !exists {
		return
	}

	if archive.Process != nil && archive.Process.Process != nil {
		archive.Process.Process.Kill()
	}
	delete(am.activeRecords, channelID)

	logger.Log.WithField("channel_id", channelID).Info("Stopped archive recording for channel")
}

// cleanupLoop periodically cleans up old archive segments
func (am *ArchiveManager) cleanupLoop() {
	defer am.wg.Done()
	ticker := time.NewTicker(time.Duration(am.config.CleanupMinutes) * time.Minute)
	defer ticker.Stop()

	// Run once at startup
	am.cleanupOldSegments()
	am.indexArchivedPrograms()

	for {
		select {
		case <-ticker.C:
			am.cleanupOldSegments()
			am.indexArchivedPrograms()
			am.cleanupExpiredArchivePrograms()
		case <-am.stopChan:
			return
		}
	}
}

// cleanupOldSegments removes segments older than retention period
func (am *ArchiveManager) cleanupOldSegments() {
	am.mutex.RLock()
	archives := make([]*ChannelArchive, 0, len(am.activeRecords))
	for _, a := range am.activeRecords {
		archives = append(archives, a)
	}
	am.mutex.RUnlock()

	for _, archive := range archives {
		am.cleanupChannelSegments(archive)
	}
}

// cleanupChannelSegments removes old segments for a specific channel
func (am *ArchiveManager) cleanupChannelSegments(archive *ChannelArchive) {
	segments, err := filepath.Glob(filepath.Join(archive.ArchiveDir, "segment_*.ts"))
	if err != nil {
		return
	}

	// Calculate cutoff time based on retention days
	cutoff := time.Now().Add(-time.Duration(archive.RetentionDays) * 24 * time.Hour)

	removedCount := 0
	for _, seg := range segments {
		info, err := os.Stat(seg)
		if err != nil {
			continue
		}

		if info.ModTime().Before(cutoff) {
			if err := os.Remove(seg); err == nil {
				removedCount++
			}
		}
	}

	if removedCount > 0 {
		logger.Log.WithFields(map[string]interface{}{
			"channel_id":       archive.ChannelID,
			"segments_removed": removedCount,
		}).Debug("Cleaned up old archive segments")
	}
}

// indexArchivedPrograms creates ArchiveProgram entries from EPG data
func (am *ArchiveManager) indexArchivedPrograms() {
	am.mutex.RLock()
	channelIDs := make([]uint, 0, len(am.activeRecords))
	archiveMap := make(map[uint]*ChannelArchive)
	for id, archive := range am.activeRecords {
		channelIDs = append(channelIDs, id)
		archiveMap[id] = archive
	}
	am.mutex.RUnlock()

	if len(channelIDs) == 0 {
		return
	}

	// Get channels with their EPG channel IDs
	var channels []models.Channel
	am.db.Where("id IN ?", channelIDs).Find(&channels)

	for _, channel := range channels {
		am.indexChannelPrograms(&channel, archiveMap[channel.ID])
	}
}

// indexChannelPrograms indexes programs for a specific channel
func (am *ArchiveManager) indexChannelPrograms(channel *models.Channel, archive *ChannelArchive) {
	if channel.ChannelID == "" {
		return // No EPG mapping
	}

	// Get programs from the last N days that ended
	cutoff := time.Now().Add(-time.Duration(archive.RetentionDays) * 24 * time.Hour)
	now := time.Now()

	var programs []models.Program
	am.db.Where("channel_id = ? AND start >= ? AND end <= ?",
		channel.ChannelID, cutoff, now).
		Order("start ASC").
		Find(&programs)

	for _, prog := range programs {
		// Check if already indexed
		var existing models.ArchiveProgram
		err := am.db.Where("channel_id = ? AND start_time = ?", channel.ID, prog.Start).First(&existing).Error
		if err == nil {
			continue // Already exists
		}

		// Calculate segment indices
		archiveStart := archive.StartTime
		if archiveStart.After(prog.Start) {
			continue // Program started before archive recording
		}

		// Estimate segment indices based on time
		startOffset := int(prog.Start.Sub(archiveStart).Seconds())
		endOffset := int(prog.End.Sub(archiveStart).Seconds())

		startIdx := startOffset / archive.SegmentLength
		endIdx := endOffset / archive.SegmentLength

		// Verify segments exist
		if !am.verifySegmentsExist(archive.ArchiveDir, startIdx, endIdx) {
			continue
		}

		// Create archive program entry
		archiveProgram := models.ArchiveProgram{
			ChannelID:       channel.ID,
			ProgramID:       &prog.ID,
			Title:           prog.Title,
			Description:     prog.Description,
			StartTime:       prog.Start,
			EndTime:         prog.End,
			Duration:        int(prog.End.Sub(prog.Start).Seconds()),
			Icon:            prog.Icon,
			Category:        prog.Category,
			ArchiveDir:      archive.ArchiveDir,
			StartSegmentIdx: startIdx,
			EndSegmentIdx:   endIdx,
			SegmentDuration: archive.SegmentLength,
			Status:          "available",
			CreatedAt:       time.Now(),
			ExpiresAt:       time.Now().Add(time.Duration(archive.RetentionDays) * 24 * time.Hour),
		}

		if err := am.db.Create(&archiveProgram).Error; err != nil {
			logger.Log.WithFields(map[string]interface{}{
				"channel_id": channel.ID,
				"program":    prog.Title,
				"error":      err,
			}).Warn("Failed to create archive program entry")
		}
	}
}

// verifySegmentsExist checks if segment files exist for the given range
func (am *ArchiveManager) verifySegmentsExist(archiveDir string, startIdx, endIdx int) bool {
	// Just check first and last segment exist
	startSeg := filepath.Join(archiveDir, fmt.Sprintf("segment_%08d.ts", startIdx))
	endSeg := filepath.Join(archiveDir, fmt.Sprintf("segment_%08d.ts", endIdx))

	if _, err := os.Stat(startSeg); os.IsNotExist(err) {
		return false
	}
	if _, err := os.Stat(endSeg); os.IsNotExist(err) {
		return false
	}
	return true
}

// cleanupExpiredArchivePrograms removes expired archive program entries
func (am *ArchiveManager) cleanupExpiredArchivePrograms() {
	result := am.db.Where("expires_at < ?", time.Now()).Delete(&models.ArchiveProgram{})
	if result.RowsAffected > 0 {
		logger.Log.WithField("count", result.RowsAffected).Debug("Cleaned up expired archive programs")
	}
}

// GetArchivedPrograms returns archived programs for a channel
func (am *ArchiveManager) GetArchivedPrograms(channelID uint, limit int) ([]models.ArchiveProgram, error) {
	var programs []models.ArchiveProgram

	query := am.db.Where("channel_id = ? AND status = ?", channelID, "available").
		Order("start_time DESC")

	if limit > 0 {
		query = query.Limit(limit)
	}

	if err := query.Find(&programs).Error; err != nil {
		return nil, err
	}

	return programs, nil
}

// GetArchivePlaylistURL generates a playlist URL for an archived program
func (am *ArchiveManager) GetArchivePlaylistURL(programID uint) (string, error) {
	var program models.ArchiveProgram
	if err := am.db.First(&program, programID).Error; err != nil {
		return "", fmt.Errorf("archive program not found: %w", err)
	}

	return fmt.Sprintf("/livetv/archive/%d/stream.m3u8", programID), nil
}

// GenerateArchivePlaylist generates an M3U8 playlist for an archived program
func (am *ArchiveManager) GenerateArchivePlaylist(programID uint) (string, error) {
	var program models.ArchiveProgram
	if err := am.db.First(&program, programID).Error; err != nil {
		return "", fmt.Errorf("archive program not found: %w", err)
	}

	// List available segments in range
	segments, err := am.getSegmentsInRange(program.ArchiveDir, program.StartSegmentIdx, program.EndSegmentIdx)
	if err != nil {
		return "", err
	}

	// Build M3U8 playlist
	var playlist strings.Builder
	playlist.WriteString("#EXTM3U\n")
	playlist.WriteString(fmt.Sprintf("#EXT-X-TARGETDURATION:%d\n", program.SegmentDuration))
	playlist.WriteString(fmt.Sprintf("#EXT-X-MEDIA-SEQUENCE:%d\n", program.StartSegmentIdx))

	for _, seg := range segments {
		playlist.WriteString(fmt.Sprintf("#EXTINF:%d.0,\n", program.SegmentDuration))
		playlist.WriteString(fmt.Sprintf("/livetv/archive/%d/segment/%s\n", programID, filepath.Base(seg)))
	}

	playlist.WriteString("#EXT-X-ENDLIST\n")

	return playlist.String(), nil
}

// getSegmentsInRange returns segment files within a range
func (am *ArchiveManager) getSegmentsInRange(archiveDir string, startIdx, endIdx int) ([]string, error) {
	allSegments, err := filepath.Glob(filepath.Join(archiveDir, "segment_*.ts"))
	if err != nil {
		return nil, err
	}

	var result []string
	for _, seg := range allSegments {
		matches := archiveSegmentPattern.FindStringSubmatch(filepath.Base(seg))
		if len(matches) == 2 {
			idx, err := strconv.Atoi(matches[1])
			if err != nil {
				continue
			}
			if idx >= startIdx && idx <= endIdx {
				result = append(result, seg)
			}
		}
	}

	sort.Strings(result)
	return result, nil
}

// GetSegmentPath returns the file path for a segment
func (am *ArchiveManager) GetSegmentPath(programID uint, segmentName string) (string, error) {
	var program models.ArchiveProgram
	if err := am.db.First(&program, programID).Error; err != nil {
		return "", fmt.Errorf("archive program not found: %w", err)
	}

	segPath := filepath.Join(program.ArchiveDir, segmentName)
	if _, err := os.Stat(segPath); os.IsNotExist(err) {
		return "", fmt.Errorf("segment not found")
	}

	return segPath, nil
}

// IsChannelArchiving returns whether a channel is being archived
func (am *ArchiveManager) IsChannelArchiving(channelID uint) bool {
	am.mutex.RLock()
	defer am.mutex.RUnlock()
	_, exists := am.activeRecords[channelID]
	return exists
}

// GetArchiveStatus returns archive status for a channel
func (am *ArchiveManager) GetArchiveStatus(channelID uint) (bool, time.Time, int) {
	am.mutex.RLock()
	defer am.mutex.RUnlock()

	archive, exists := am.activeRecords[channelID]
	if !exists {
		return false, time.Time{}, 0
	}

	return true, archive.StartTime, archive.RetentionDays
}

// EnableArchive enables archive for a channel
func (am *ArchiveManager) EnableArchive(channelID uint, days int) error {
	if days <= 0 {
		days = 7
	}
	if days > am.config.MaxDays {
		days = am.config.MaxDays
	}

	return am.db.Model(&models.Channel{}).Where("id = ?", channelID).Updates(map[string]interface{}{
		"archive_enabled": true,
		"archive_days":    days,
	}).Error
}

// DisableArchive disables archive for a channel
func (am *ArchiveManager) DisableArchive(channelID uint) error {
	return am.db.Model(&models.Channel{}).Where("id = ?", channelID).Update("archive_enabled", false).Error
}
