package dvr

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// ChapterDetector detects scene-change-based chapter markers in DVR recordings
// using ffprobe's scene detection filter, and merges them with existing
// commercial/skip segment data.
type ChapterDetector struct {
	db         *gorm.DB
	ffprobePath string
	ffmpegPath  string
}

// NewChapterDetector creates a new ChapterDetector. If ffprobePath or
// ffmpegPath are empty, it attempts to find the binaries on the system PATH.
func NewChapterDetector(db *gorm.DB, ffprobePath, ffmpegPath string) *ChapterDetector {
	if ffprobePath == "" {
		if path, err := exec.LookPath("ffprobe"); err == nil {
			ffprobePath = path
		}
	}
	if ffmpegPath == "" {
		if path, err := exec.LookPath("ffmpeg"); err == nil {
			ffmpegPath = path
		}
	}

	if ffprobePath != "" {
		logger.Infof("Chapter detector initialized with ffprobe: %s", ffprobePath)
	} else {
		logger.Warn("Chapter detector: ffprobe not found, scene detection will be unavailable")
	}

	return &ChapterDetector{
		db:          db,
		ffprobePath: ffprobePath,
		ffmpegPath:  ffmpegPath,
	}
}

// DetectChapters runs ffprobe with scene detection on the given file and
// returns a list of ChapterMarker records representing scene changes.
// The scene detection threshold (0.4) is tuned for broadcast TV recordings
// where scene transitions tend to be sharp cuts.
func (cd *ChapterDetector) DetectChapters(ctx context.Context, filePath string) ([]models.ChapterMarker, error) {
	if cd.ffprobePath == "" {
		return nil, fmt.Errorf("ffprobe not available for chapter detection")
	}

	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return nil, fmt.Errorf("file not found: %s", filePath)
	}

	logger.Infof("Running scene detection on: %s", filePath)

	// Use ffprobe with the select filter to detect scene changes.
	// The scene score threshold of 0.4 catches major scene transitions
	// while filtering out minor lighting changes.
	args := []string{
		"-v", "quiet",
		"-select_streams", "v:0",
		"-show_entries", "frame=pts_time,pkt_pts_time",
		"-of", "csv=p=0",
		"-f", "lavfi",
		fmt.Sprintf("movie=%s,select=gt(scene\\,0.4)", escapeFilterPath(filePath)),
	}

	cmd := exec.CommandContext(ctx, cd.ffprobePath, args...)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		// If the lavfi approach fails, try an alternative method using ffmpeg
		return cd.detectChaptersFallback(ctx, filePath)
	}

	return cd.parseSceneTimestamps(stdout.String()), nil
}

// detectChaptersFallback uses ffmpeg showinfo filter as an alternative scene
// detection method when the ffprobe lavfi approach is not supported.
func (cd *ChapterDetector) detectChaptersFallback(ctx context.Context, filePath string) ([]models.ChapterMarker, error) {
	if cd.ffmpegPath == "" {
		return nil, fmt.Errorf("neither ffprobe lavfi nor ffmpeg available for scene detection")
	}

	args := []string{
		"-i", filePath,
		"-vf", "select=gt(scene\\,0.4),showinfo",
		"-vsync", "vfr",
		"-f", "null",
		"-",
	}

	cmd := exec.CommandContext(ctx, cd.ffmpegPath, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		// ffmpeg returns non-zero for -f null; check if we got usable output
		if len(output) == 0 {
			return nil, fmt.Errorf("ffmpeg scene detection failed: %w", err)
		}
	}

	return cd.parseShowInfoTimestamps(string(output)), nil
}

// parseSceneTimestamps parses the CSV output from ffprobe scene detection.
// Each line contains: pts_time,pkt_pts_time
func (cd *ChapterDetector) parseSceneTimestamps(output string) []models.ChapterMarker {
	var markers []models.ChapterMarker
	re := regexp.MustCompile(`(\d+\.?\d*)`)

	lines := splitLines(output)
	for i, line := range lines {
		if line == "" {
			continue
		}

		match := re.FindString(line)
		if match == "" {
			continue
		}

		ts, err := strconv.ParseFloat(match, 64)
		if err != nil {
			continue
		}

		markers = append(markers, models.ChapterMarker{
			Title:        fmt.Sprintf("Scene %d", i+1),
			StartTime:    ts,
			EndTime:      ts, // will be refined by mergeEndTimes
			Type:         "scene",
			AutoDetected: true,
		})
	}

	// Refine end times: each chapter's end is the next chapter's start
	cd.refineEndTimes(markers)

	return markers
}

// parseShowInfoTimestamps extracts timestamps from ffmpeg showinfo filter output.
// showinfo output format: [Parsed_showinfo_1 @ 0x...] n:  0 pts: 12345 pts_time:123.456 ...
func (cd *ChapterDetector) parseShowInfoTimestamps(output string) []models.ChapterMarker {
	var markers []models.ChapterMarker
	re := regexp.MustCompile(`pts_time:\s*(\d+\.?\d*)`)

	matches := re.FindAllStringSubmatch(output, -1)
	for i, match := range matches {
		if len(match) < 2 {
			continue
		}

		ts, err := strconv.ParseFloat(match[1], 64)
		if err != nil {
			continue
		}

		markers = append(markers, models.ChapterMarker{
			Title:        fmt.Sprintf("Scene %d", i+1),
			StartTime:    ts,
			EndTime:      ts,
			Type:         "scene",
			AutoDetected: true,
		})
	}

	cd.refineEndTimes(markers)

	return markers
}

// refineEndTimes updates the EndTime of each marker to be the start of the
// next marker. The last marker's EndTime is left as its StartTime (will be
// set to the file duration when saved).
func (cd *ChapterDetector) refineEndTimes(markers []models.ChapterMarker) {
	// Sort by start time first
	sort.Slice(markers, func(i, j int) bool {
		return markers[i].StartTime < markers[j].StartTime
	})

	for i := 0; i < len(markers)-1; i++ {
		markers[i].EndTime = markers[i+1].StartTime
	}
}

// MergeWithExisting loads existing DetectedSegment and CommercialSegment
// records for the given file and merges them with the auto-detected scene
// chapters. Existing segments (intro, outro, credits, commercial) take
// priority and replace overlapping scene markers.
func (cd *ChapterDetector) MergeWithExisting(fileID uint, detected []models.ChapterMarker) []models.ChapterMarker {
	// Load existing detected segments (intro, outro, credits)
	var detectedSegments []models.DetectedSegment
	cd.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&detectedSegments)

	// Load existing commercial segments
	var commercials []models.CommercialSegment
	cd.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&commercials)

	// Convert existing segments to chapter markers
	var existing []models.ChapterMarker
	for _, seg := range detectedSegments {
		existing = append(existing, models.ChapterMarker{
			FileID:       fileID,
			Title:        segmentTypeTitle(seg.Type),
			StartTime:    seg.StartTime,
			EndTime:      seg.EndTime,
			Type:         seg.Type,
			AutoDetected: true,
		})
	}
	for _, com := range commercials {
		existing = append(existing, models.ChapterMarker{
			FileID:       fileID,
			Title:        "Commercial Break",
			StartTime:    com.StartTime,
			EndTime:      com.EndTime,
			Type:         "commercial",
			AutoDetected: true,
		})
	}

	if len(existing) == 0 {
		// No existing segments; use scene chapters as-is
		for i := range detected {
			detected[i].FileID = fileID
		}
		return detected
	}

	// Remove scene markers that overlap with existing segments (existing
	// segments are more semantically meaningful)
	var merged []models.ChapterMarker
	merged = append(merged, existing...)

	for _, scene := range detected {
		overlaps := false
		for _, ex := range existing {
			// Check if the scene marker falls within an existing segment
			if scene.StartTime >= ex.StartTime-2.0 && scene.StartTime <= ex.EndTime+2.0 {
				overlaps = true
				break
			}
		}
		if !overlaps {
			scene.FileID = fileID
			merged = append(merged, scene)
		}
	}

	// Sort by start time
	sort.Slice(merged, func(i, j int) bool {
		return merged[i].StartTime < merged[j].StartTime
	})

	return merged
}

// SaveChapters persists chapter markers for a file, replacing any previously
// auto-detected chapters while preserving manual ones.
func (cd *ChapterDetector) SaveChapters(fileID uint, chapters []models.ChapterMarker) error {
	// Delete existing auto-detected chapters for this file
	if err := cd.db.Where("file_id = ? AND auto_detected = ?", fileID, true).
		Delete(&models.ChapterMarker{}).Error; err != nil {
		return fmt.Errorf("failed to clear old chapters: %w", err)
	}

	// Save new chapters
	for i := range chapters {
		chapters[i].FileID = fileID
		if err := cd.db.Create(&chapters[i]).Error; err != nil {
			logger.Warnf("Failed to save chapter marker for file %d: %v", fileID, err)
		}
	}

	logger.Infof("Saved %d chapter markers for file %d", len(chapters), fileID)
	return nil
}

// GetChapters returns all chapter markers for a file, ordered by start time.
func (cd *ChapterDetector) GetChapters(fileID uint) ([]models.ChapterMarker, error) {
	var chapters []models.ChapterMarker
	err := cd.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&chapters).Error
	return chapters, err
}

// GenerateThumbnail extracts a thumbnail image at the specified timestamp
// using ffmpeg. Returns the path to the generated JPEG file.
func (cd *ChapterDetector) GenerateThumbnail(ctx context.Context, filePath string, timestamp float64, outputPath string) error {
	if cd.ffmpegPath == "" {
		return fmt.Errorf("ffmpeg not available for thumbnail generation")
	}

	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return fmt.Errorf("source file not found: %s", filePath)
	}

	// Ensure the output directory exists
	if err := os.MkdirAll(filepath.Dir(outputPath), 0755); err != nil {
		return fmt.Errorf("failed to create thumbnail directory: %w", err)
	}

	ts := fmt.Sprintf("%.3f", timestamp)

	args := []string{
		"-ss", ts,
		"-i", filePath,
		"-vframes", "1",
		"-q:v", "2",
		"-vf", "scale=320:-1",
		"-y",
		outputPath,
	}

	cmd := exec.CommandContext(ctx, cd.ffmpegPath, args...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("ffmpeg thumbnail failed: %v, stderr: %s", err, stderr.String())
	}

	if _, err := os.Stat(outputPath); os.IsNotExist(err) {
		return fmt.Errorf("thumbnail file was not created at %s", outputPath)
	}

	return nil
}

// GenerateChapterThumbnails generates thumbnail images for all chapter
// markers in the list, storing them in the given directory.
func (cd *ChapterDetector) GenerateChapterThumbnails(ctx context.Context, filePath string, chapters []models.ChapterMarker, thumbDir string) {
	if cd.ffmpegPath == "" {
		logger.Warn("ffmpeg not available, skipping chapter thumbnail generation")
		return
	}

	if err := os.MkdirAll(thumbDir, 0755); err != nil {
		logger.Errorf("Failed to create chapter thumbnails directory: %v", err)
		return
	}

	for i := range chapters {
		select {
		case <-ctx.Done():
			return
		default:
		}

		if chapters[i].Thumbnail != "" {
			continue // already has a thumbnail
		}

		thumbFilename := fmt.Sprintf("chapter_%d_%d_%d.jpg",
			chapters[i].FileID, i, time.Now().UnixNano())
		thumbPath := filepath.Join(thumbDir, thumbFilename)

		if err := cd.GenerateThumbnail(ctx, filePath, chapters[i].StartTime, thumbPath); err != nil {
			logger.Warnf("Failed to generate thumbnail for chapter %d at %.1fs: %v",
				i, chapters[i].StartTime, err)
			continue
		}

		chapters[i].Thumbnail = thumbPath

		// Update in DB if the chapter has been persisted
		if chapters[i].ID > 0 {
			cd.db.Model(&chapters[i]).Update("thumbnail", thumbPath)
		}
	}
}

// segmentTypeTitle returns a human-readable title for a segment type.
func segmentTypeTitle(segType string) string {
	switch segType {
	case "intro":
		return "Intro"
	case "outro":
		return "Outro"
	case "credits":
		return "Credits"
	case "commercial":
		return "Commercial Break"
	default:
		return "Segment"
	}
}

// escapeFilterPath escapes special characters in a file path for use in
// ffmpeg/ffprobe filter expressions.
func escapeFilterPath(path string) string {
	// In lavfi filter graphs, colons, single quotes, and backslashes
	// need escaping.
	r := regexp.MustCompile(`([\\':])`)
	return r.ReplaceAllString(path, `\\$1`)
}

// splitLines splits a string into lines, handling both \n and \r\n.
func splitLines(s string) []string {
	var lines []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' {
			line := s[start:i]
			if len(line) > 0 && line[len(line)-1] == '\r' {
				line = line[:len(line)-1]
			}
			lines = append(lines, line)
			start = i + 1
		}
	}
	if start < len(s) {
		lines = append(lines, s[start:])
	}
	return lines
}
