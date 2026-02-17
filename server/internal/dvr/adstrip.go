package dvr

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// AdStripper handles removing detected commercial segments from DVR recordings.
type AdStripper struct {
	db         *gorm.DB
	ffmpegPath string
}

// NewAdStripper creates a new AdStripper instance.
func NewAdStripper(db *gorm.DB, ffmpegPath string) *AdStripper {
	if ffmpegPath == "" {
		if path, err := exec.LookPath("ffmpeg"); err == nil {
			ffmpegPath = path
		} else {
			ffmpegPath = "ffmpeg"
		}
	}
	return &AdStripper{
		db:         db,
		ffmpegPath: ffmpegPath,
	}
}

// contentSegment represents a non-commercial segment to keep.
type contentSegment struct {
	Start float64
	End   float64
}

// StripAds removes commercials from a DVRFile by re-encoding with select filters.
// This is slower but produces a clean output with properly re-timed streams.
func (a *AdStripper) StripAds(ctx context.Context, fileID uint) (string, error) {
	return a.strip(ctx, fileID, false)
}

// StripAdsStreamCopy removes commercials using the concat demuxer with stream copy.
// This is much faster since it avoids re-encoding, but may have minor glitches
// at segment boundaries depending on the source codec.
func (a *AdStripper) StripAdsStreamCopy(ctx context.Context, fileID uint) (string, error) {
	return a.strip(ctx, fileID, true)
}

// strip is the shared implementation for both modes.
func (a *AdStripper) strip(ctx context.Context, fileID uint, streamCopy bool) (string, error) {
	// Load DVRFile
	var file models.DVRFile
	if err := a.db.First(&file, fileID).Error; err != nil {
		return "", fmt.Errorf("DVR file not found: %w", err)
	}

	if file.FilePath == "" {
		return "", fmt.Errorf("DVR file has no file path")
	}
	if _, err := os.Stat(file.FilePath); os.IsNotExist(err) {
		return "", fmt.Errorf("DVR file does not exist on disk: %s", file.FilePath)
	}

	// Mark as running
	mode := "copy"
	if !streamCopy {
		mode = "reencode"
	}
	a.db.Model(&file).Updates(map[string]interface{}{
		"ad_strip_status": "running",
		"ad_strip_mode":   mode,
		"ad_strip_error":  "",
	})

	// Load commercial segments for this file
	segments, err := a.loadCommercialSegments(fileID, file)
	if err != nil {
		a.setStripError(&file, fmt.Sprintf("failed to load commercial segments: %v", err))
		return "", err
	}

	if len(segments) == 0 {
		a.setStripError(&file, "no commercial segments found for this file")
		return "", fmt.Errorf("no commercial segments found for file %d", fileID)
	}

	// Get file duration (used to define the last content segment)
	duration := a.getFileDuration(ctx, file.FilePath)
	if duration <= 0 {
		// Fall back to file's stored duration (in seconds)
		duration = float64(file.Duration)
	}
	if duration <= 0 {
		a.setStripError(&file, "could not determine file duration")
		return "", fmt.Errorf("could not determine duration of file %d", fileID)
	}

	// Build content segments (the parts to keep)
	content := buildContentSegments(segments, duration)
	if len(content) == 0 {
		a.setStripError(&file, "no content segments remain after stripping commercials")
		return "", fmt.Errorf("no content segments remain for file %d", fileID)
	}

	logger.Log.WithFields(map[string]interface{}{
		"file_id":          fileID,
		"commercial_count": len(segments),
		"content_segments": len(content),
		"mode":             mode,
	}).Info("Starting ad stripping")

	// Build output file path
	ext := filepath.Ext(file.FilePath)
	basePath := strings.TrimSuffix(file.FilePath, ext)
	outputPath := basePath + "_clean" + ext
	tempPath := outputPath + ".tmp"

	var stripErr error
	if streamCopy {
		stripErr = a.runStreamCopy(ctx, file.FilePath, tempPath, content)
	} else {
		stripErr = a.runReencode(ctx, file.FilePath, tempPath, segments)
	}

	if stripErr != nil {
		os.Remove(tempPath)
		a.setStripError(&file, fmt.Sprintf("ffmpeg failed: %v", stripErr))
		return "", fmt.Errorf("ad stripping failed: %w", stripErr)
	}

	// Verify the temp file was created and has content
	tempInfo, err := os.Stat(tempPath)
	if err != nil || tempInfo.Size() == 0 {
		os.Remove(tempPath)
		a.setStripError(&file, "output file is empty or missing after ffmpeg")
		return "", fmt.Errorf("output file is empty or missing")
	}

	// Rename temp to final output
	if err := os.Rename(tempPath, outputPath); err != nil {
		os.Remove(tempPath)
		a.setStripError(&file, fmt.Sprintf("failed to rename output file: %v", err))
		return "", fmt.Errorf("failed to rename output: %w", err)
	}

	// Get the output file size
	outputInfo, _ := os.Stat(outputPath)
	newSize := int64(0)
	if outputInfo != nil {
		newSize = outputInfo.Size()
	}

	// Update the DVRFile record: save original path as backup, point to clean file
	updates := map[string]interface{}{
		"ads_stripped":       true,
		"ad_strip_status":   "completed",
		"ad_strip_mode":     mode,
		"ad_strip_error":    "",
		"original_file_path": file.FilePath,
		"original_file_size": file.FileSize,
		"file_path":          outputPath,
		"file_size":          newSize,
	}
	if err := a.db.Model(&file).Updates(updates).Error; err != nil {
		logger.Log.WithFields(map[string]interface{}{
			"file_id": fileID,
			"error":   err.Error(),
		}).Error("Failed to update DVR file after ad stripping")
		return outputPath, fmt.Errorf("ad stripping succeeded but DB update failed: %w", err)
	}

	logger.Log.WithFields(map[string]interface{}{
		"file_id":       fileID,
		"original_size": file.FileSize,
		"new_size":      newSize,
		"output_path":   outputPath,
		"mode":          mode,
	}).Info("Ad stripping completed successfully")

	return outputPath, nil
}

// UndoStripAds restores the original recording by swapping the clean file with the backup.
func (a *AdStripper) UndoStripAds(ctx context.Context, fileID uint) error {
	var file models.DVRFile
	if err := a.db.First(&file, fileID).Error; err != nil {
		return fmt.Errorf("DVR file not found: %w", err)
	}

	if !file.AdsStripped || file.OriginalFilePath == "" {
		return fmt.Errorf("file %d has not been ad-stripped or original is not available", fileID)
	}

	// Verify original file still exists
	if _, err := os.Stat(file.OriginalFilePath); os.IsNotExist(err) {
		return fmt.Errorf("original file no longer exists: %s", file.OriginalFilePath)
	}

	// Remove the clean file (current FilePath)
	cleanPath := file.FilePath
	if cleanPath != file.OriginalFilePath {
		if err := os.Remove(cleanPath); err != nil && !os.IsNotExist(err) {
			logger.Log.WithFields(map[string]interface{}{
				"file_id":    fileID,
				"clean_path": cleanPath,
				"error":      err.Error(),
			}).Warn("Failed to remove clean file during undo")
		}
	}

	// Restore original file path and size
	updates := map[string]interface{}{
		"ads_stripped":       false,
		"ad_strip_status":   "",
		"ad_strip_mode":     "",
		"ad_strip_error":    "",
		"file_path":         file.OriginalFilePath,
		"file_size":         file.OriginalFileSize,
		"original_file_path": "",
		"original_file_size": int64(0),
	}
	if err := a.db.Model(&file).Updates(updates).Error; err != nil {
		return fmt.Errorf("failed to restore original file in database: %w", err)
	}

	logger.Log.WithFields(map[string]interface{}{
		"file_id":       fileID,
		"restored_path": file.OriginalFilePath,
	}).Info("Ad stripping undone, original file restored")

	return nil
}

// GetStripStatus returns the current ad-strip status for a file.
func (a *AdStripper) GetStripStatus(fileID uint) (map[string]interface{}, error) {
	var file models.DVRFile
	if err := a.db.First(&file, fileID).Error; err != nil {
		return nil, fmt.Errorf("DVR file not found: %w", err)
	}

	status := map[string]interface{}{
		"fileId":           file.ID,
		"adsStripped":      file.AdsStripped,
		"status":           file.AdStripStatus,
		"mode":             file.AdStripMode,
		"error":            file.AdStripError,
		"originalFilePath": file.OriginalFilePath,
		"originalFileSize": file.OriginalFileSize,
		"currentFilePath":  file.FilePath,
		"currentFileSize":  file.FileSize,
	}

	// Count commercial segments
	var segmentCount int64
	a.db.Model(&models.CommercialSegment{}).Where("file_id = ?", fileID).Count(&segmentCount)
	if segmentCount == 0 {
		a.db.Model(&models.CommercialSegment{}).Where("recording_id = ? AND file_id IS NULL", fileID).Count(&segmentCount)
	}
	var detectedCount int64
	a.db.Model(&models.DetectedSegment{}).Where("file_id = ? AND type = ?", fileID, "commercial").Count(&detectedCount)

	status["commercialSegments"] = segmentCount + detectedCount

	return status, nil
}

// loadCommercialSegments loads all commercial segments for a DVRFile from both tables.
func (a *AdStripper) loadCommercialSegments(fileID uint, file models.DVRFile) ([]contentSegment, error) {
	type segment struct {
		Start float64
		End   float64
	}
	var commercials []segment

	// Load from CommercialSegment table (linked by FileID)
	var cs []models.CommercialSegment
	a.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&cs)
	for _, c := range cs {
		commercials = append(commercials, segment{Start: c.StartTime, End: c.EndTime})
	}

	// Also check by recording_id if file was created from a legacy recording
	if file.LegacyRecordingID != nil && len(cs) == 0 {
		var csLegacy []models.CommercialSegment
		a.db.Where("recording_id = ? AND file_id IS NULL", *file.LegacyRecordingID).Order("start_time ASC").Find(&csLegacy)
		for _, c := range csLegacy {
			commercials = append(commercials, segment{Start: c.StartTime, End: c.EndTime})
		}
	}

	// Load from DetectedSegment table (type = "commercial")
	var ds []models.DetectedSegment
	a.db.Where("file_id = ? AND type = ?", fileID, "commercial").Order("start_time ASC").Find(&ds)
	for _, d := range ds {
		commercials = append(commercials, segment{Start: d.StartTime, End: d.EndTime})
	}

	if len(commercials) == 0 {
		return nil, nil
	}

	// Sort by start time and merge overlapping segments
	sort.Slice(commercials, func(i, j int) bool {
		return commercials[i].Start < commercials[j].Start
	})

	// Merge overlapping commercial segments
	var merged []contentSegment
	current := contentSegment{Start: commercials[0].Start, End: commercials[0].End}
	for i := 1; i < len(commercials); i++ {
		if commercials[i].Start <= current.End {
			// Overlapping or adjacent - extend
			if commercials[i].End > current.End {
				current.End = commercials[i].End
			}
		} else {
			merged = append(merged, current)
			current = contentSegment{Start: commercials[i].Start, End: commercials[i].End}
		}
	}
	merged = append(merged, current)

	return merged, nil
}

// buildContentSegments builds the list of content (non-commercial) time ranges.
func buildContentSegments(commercials []contentSegment, totalDuration float64) []contentSegment {
	var content []contentSegment
	pos := 0.0

	for _, comm := range commercials {
		if comm.Start > pos {
			content = append(content, contentSegment{Start: pos, End: comm.Start})
		}
		pos = comm.End
	}

	// Add the final segment after the last commercial
	if pos < totalDuration {
		content = append(content, contentSegment{Start: pos, End: totalDuration})
	}

	return content
}

// runStreamCopy uses the concat demuxer with stream copy for fast ad removal.
// It splits the input into content segments and concatenates them.
func (a *AdStripper) runStreamCopy(ctx context.Context, inputPath, outputPath string, content []contentSegment) error {
	// Create a temporary directory for intermediate segment files
	tempDir, err := os.MkdirTemp("", "adstrip-*")
	if err != nil {
		return fmt.Errorf("failed to create temp directory: %w", err)
	}
	defer os.RemoveAll(tempDir)

	ext := filepath.Ext(inputPath)
	var segmentPaths []string

	// Extract each content segment as a separate file using stream copy
	for i, seg := range content {
		segPath := filepath.Join(tempDir, fmt.Sprintf("segment_%03d%s", i, ext))
		segmentPaths = append(segmentPaths, segPath)

		duration := seg.End - seg.Start
		args := []string{
			"-y",
			"-hide_banner",
			"-loglevel", "warning",
			"-ss", fmt.Sprintf("%.3f", seg.Start),
			"-i", inputPath,
			"-t", fmt.Sprintf("%.3f", duration),
			"-c", "copy",
			"-avoid_negative_ts", "make_zero",
			segPath,
		}

		cmd := exec.CommandContext(ctx, a.ffmpegPath, args...)
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("segment %d extraction failed: %w (output: %s)", i, err, string(output))
		}
	}

	// Create concat list file
	concatPath := filepath.Join(tempDir, "concat.txt")
	var concatContent strings.Builder
	for _, segPath := range segmentPaths {
		concatContent.WriteString(fmt.Sprintf("file '%s'\n", segPath))
	}
	if err := os.WriteFile(concatPath, []byte(concatContent.String()), 0644); err != nil {
		return fmt.Errorf("failed to write concat file: %w", err)
	}

	// Concatenate all segments using concat demuxer
	args := []string{
		"-y",
		"-hide_banner",
		"-loglevel", "warning",
		"-f", "concat",
		"-safe", "0",
		"-i", concatPath,
		"-c", "copy",
		outputPath,
	}

	cmd := exec.CommandContext(ctx, a.ffmpegPath, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("concat failed: %w (output: %s)", err, string(output))
	}

	return nil
}

// runReencode uses video/audio select filters to skip commercials with re-encoding.
// Slower but produces a seamless output.
func (a *AdStripper) runReencode(ctx context.Context, inputPath, outputPath string, commercials []contentSegment) error {
	// Build the "not between" expressions for the select filter
	var conditions []string
	for _, comm := range commercials {
		conditions = append(conditions, fmt.Sprintf("between(t,%.3f,%.3f)", comm.Start, comm.End))
	}
	notExpr := fmt.Sprintf("not(%s)", strings.Join(conditions, "+"))

	vf := fmt.Sprintf("select='%s',setpts=N/FRAME_RATE/TB", notExpr)
	af := fmt.Sprintf("aselect='%s',asetpts=N/SR/TB", notExpr)

	args := []string{
		"-y",
		"-hide_banner",
		"-loglevel", "warning",
		"-i", inputPath,
		"-vf", vf,
		"-af", af,
		"-c:v", "libx264",
		"-preset", "veryfast",
		"-crf", "18",
		"-c:a", "aac",
		"-b:a", "192k",
		outputPath,
	}

	cmd := exec.CommandContext(ctx, a.ffmpegPath, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("re-encode failed: %w (output: %s)", err, string(output))
	}

	return nil
}

// getFileDuration uses ffprobe to get the duration of a media file in seconds.
func (a *AdStripper) getFileDuration(ctx context.Context, filePath string) float64 {
	ffprobePath := strings.TrimSuffix(a.ffmpegPath, "ffmpeg") + "ffprobe"
	if _, err := exec.LookPath(ffprobePath); err != nil {
		// Fallback: try system ffprobe
		if path, err := exec.LookPath("ffprobe"); err == nil {
			ffprobePath = path
		} else {
			return 0
		}
	}

	cmd := exec.CommandContext(ctx, ffprobePath,
		"-v", "quiet",
		"-show_entries", "format=duration",
		"-of", "default=noprint_wrappers=1:nokey=1",
		filePath,
	)

	output, err := cmd.Output()
	if err != nil {
		return 0
	}

	var duration float64
	if _, err := fmt.Sscanf(strings.TrimSpace(string(output)), "%f", &duration); err != nil {
		return 0
	}
	return duration
}

// setStripError updates the DVRFile with an error status.
func (a *AdStripper) setStripError(file *models.DVRFile, errMsg string) {
	a.db.Model(file).Updates(map[string]interface{}{
		"ad_strip_status": "failed",
		"ad_strip_error":  errMsg,
	})
}

// AutoStripEnabled checks the dvr settings to see if auto_strip_ads is enabled.
func (a *AdStripper) AutoStripEnabled() bool {
	var setting models.Setting
	if err := a.db.Where("key = ?", "auto_strip_ads").First(&setting).Error; err != nil {
		return false
	}
	return setting.Value == "true" || setting.Value == "1"
}

// AutoStripForFile runs ad stripping in the background for a completed DVR file.
// Called from the recorder post-processing pipeline.
func (a *AdStripper) AutoStripForFile(fileID uint) {
	logger.Log.WithField("file_id", fileID).Info("Auto-stripping ads from recording")

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Hour)
	defer cancel()

	// Use stream copy mode for auto-strip (much faster)
	outputPath, err := a.StripAdsStreamCopy(ctx, fileID)
	if err != nil {
		logger.Log.WithFields(map[string]interface{}{
			"file_id": fileID,
			"error":   err.Error(),
		}).Warn("Auto ad stripping failed")
		return
	}

	logger.Log.WithFields(map[string]interface{}{
		"file_id":     fileID,
		"output_path": outputPath,
	}).Info("Auto ad stripping completed")
}
