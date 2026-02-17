package dvr

import (
	"context"
	"fmt"
	"math"
	"os/exec"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"sync"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// SegmentDetector detects intro/outro/credits segments in DVR recordings
// using ffmpeg black frame detection, silence detection, and cross-episode
// pattern matching.
type SegmentDetector struct {
	db         *gorm.DB
	ffmpegPath string
	mu         sync.Mutex
	running    bool
}

// DetectionResult holds the results of segment detection for a single file.
type DetectionResult struct {
	FileID   uint          `json:"fileId"`
	Segments []SegmentInfo `json:"segments"`
	Duration float64       `json:"duration"`
	Error    string        `json:"error,omitempty"`
}

// SegmentInfo describes a detected segment with confidence metadata.
type SegmentInfo struct {
	Type       string  `json:"type"`
	StartTime  float64 `json:"startTime"`
	EndTime    float64 `json:"endTime"`
	Confidence float64 `json:"confidence"`
	Method     string  `json:"method"` // black_frames, silence, pattern, manual
}

// blackFrame represents a detected black frame from ffmpeg blackdetect.
type blackFrame struct {
	Time     float64
	Duration float64
}

// silentSegment represents a detected silent segment from ffmpeg silencedetect.
type silentSegment struct {
	Start    float64
	End      float64
	Duration float64
}

// timestampCluster groups a segment type with its timestamp for cross-episode
// pattern matching.
type timestampCluster struct {
	segType   string
	startTime float64
	endTime   float64
	count     int
}

// NewSegmentDetector creates a new SegmentDetector. If ffmpegPath is empty,
// it attempts to find ffmpeg on the system PATH.
func NewSegmentDetector(db *gorm.DB, ffmpegPath string) *SegmentDetector {
	if ffmpegPath == "" {
		if path, err := exec.LookPath("ffmpeg"); err == nil {
			ffmpegPath = path
		}
	}

	if ffmpegPath != "" {
		logger.Infof("Segment detector initialized with ffmpeg: %s", ffmpegPath)
	} else {
		logger.Warn("Segment detector: ffmpeg not found, detection will be unavailable")
	}

	return &SegmentDetector{
		db:         db,
		ffmpegPath: ffmpegPath,
	}
}

// DetectFile runs segment detection on a single DVR file. It performs black
// frame detection, silence detection, and boundary analysis to identify intro,
// outro, and credits segments.
func (sd *SegmentDetector) DetectFile(ctx context.Context, fileID uint) (*DetectionResult, error) {
	sd.mu.Lock()
	sd.running = true
	sd.mu.Unlock()
	defer func() {
		sd.mu.Lock()
		sd.running = false
		sd.mu.Unlock()
	}()

	if sd.ffmpegPath == "" {
		return nil, fmt.Errorf("ffmpeg not available for segment detection")
	}

	// Load the DVR file from database
	var file models.DVRFile
	if err := sd.db.First(&file, fileID).Error; err != nil {
		return nil, fmt.Errorf("file not found: %w", err)
	}

	if file.FilePath == "" {
		return nil, fmt.Errorf("file has no file path")
	}

	if !fileExists(file.FilePath) {
		return nil, fmt.Errorf("file not found on disk: %s", file.FilePath)
	}

	duration := float64(file.Duration)
	if duration <= 0 {
		duration = 3600 // default 1 hour if unknown
	}

	logger.Infof("Starting segment detection for file %d: %s", fileID, file.Title)

	result := &DetectionResult{
		FileID:   fileID,
		Duration: duration,
	}

	// Run black frame and silence detection in parallel
	type blackResult struct {
		frames []blackFrame
		err    error
	}
	type silenceResult struct {
		segments []silentSegment
		err      error
	}

	blackCh := make(chan blackResult, 1)
	silenceCh := make(chan silenceResult, 1)

	go func() {
		frames, err := sd.detectBlackFrames(ctx, file.FilePath)
		blackCh <- blackResult{frames, err}
	}()

	go func() {
		segments, err := sd.detectSilence(ctx, file.FilePath)
		silenceCh <- silenceResult{segments, err}
	}()

	// Collect results
	br := <-blackCh
	sr := <-silenceCh

	if br.err != nil {
		logger.Warnf("Black frame detection failed for file %d: %v", fileID, br.err)
	}
	if sr.err != nil {
		logger.Warnf("Silence detection failed for file %d: %v", fileID, sr.err)
	}

	// Both failed - return error
	if br.err != nil && sr.err != nil {
		result.Error = fmt.Sprintf("detection failed: black frames: %v; silence: %v", br.err, sr.err)
		return result, fmt.Errorf("all detection methods failed")
	}

	// Find segment boundaries
	segments := sd.findSegmentBoundaries(br.frames, sr.segments, duration)
	result.Segments = segments

	// Delete any existing segments for this file before saving new ones
	sd.db.Where("file_id = ?", fileID).Delete(&models.DetectedSegment{})

	// Save detected segments to database
	for _, seg := range segments {
		dbSeg := models.DetectedSegment{
			FileID:    fileID,
			Type:      seg.Type,
			StartTime: seg.StartTime,
			EndTime:   seg.EndTime,
		}
		if err := sd.db.Create(&dbSeg).Error; err != nil {
			logger.Warnf("Failed to save segment for file %d: %v", fileID, err)
		}
	}

	logger.Infof("Detected %d segments for file %d: %s", len(segments), fileID, file.Title)
	return result, nil
}

// DetectGroup runs segment detection on all files in a DVR group, then
// cross-references results across episodes to improve detection accuracy.
func (sd *SegmentDetector) DetectGroup(ctx context.Context, groupID uint) ([]DetectionResult, error) {
	sd.mu.Lock()
	sd.running = true
	sd.mu.Unlock()
	defer func() {
		sd.mu.Lock()
		sd.running = false
		sd.mu.Unlock()
	}()

	// Load group with files
	var group models.DVRGroup
	if err := sd.db.Preload("Files", "deleted = ?", false).First(&group, groupID).Error; err != nil {
		return nil, fmt.Errorf("group not found: %w", err)
	}

	if len(group.Files) == 0 {
		return nil, fmt.Errorf("group has no files")
	}

	logger.Infof("Starting group segment detection for group %d (%s): %d files",
		groupID, group.Title, len(group.Files))

	// Detect segments for each file individually
	allResults := make(map[uint][]SegmentInfo)
	var results []DetectionResult

	for _, file := range group.Files {
		select {
		case <-ctx.Done():
			return results, ctx.Err()
		default:
		}

		// Temporarily release the running flag for individual detection
		// since we handle it at the group level
		result, err := sd.detectFileInternal(ctx, file)
		if err != nil {
			logger.Warnf("Detection failed for file %d in group %d: %v", file.ID, groupID, err)
			results = append(results, DetectionResult{
				FileID: file.ID,
				Error:  err.Error(),
			})
			continue
		}

		allResults[file.ID] = result.Segments
		results = append(results, *result)
	}

	// Cross-reference segments across episodes if we have multiple files
	if len(allResults) >= 2 {
		refined := sd.crossReferenceGroup(allResults)

		// Update database and results with refined segments
		for i, r := range results {
			if refinedSegs, ok := refined[r.FileID]; ok {
				results[i].Segments = refinedSegs

				// Update database
				sd.db.Where("file_id = ?", r.FileID).Delete(&models.DetectedSegment{})
				for _, seg := range refinedSegs {
					dbSeg := models.DetectedSegment{
						FileID:    r.FileID,
						Type:      seg.Type,
						StartTime: seg.StartTime,
						EndTime:   seg.EndTime,
					}
					sd.db.Create(&dbSeg)
				}
			}
		}
	}

	logger.Infof("Group segment detection complete for group %d: processed %d files", groupID, len(results))
	return results, nil
}

// GetSegments returns all detected segments for a file, ordered by start time.
func (sd *SegmentDetector) GetSegments(fileID uint) ([]models.DetectedSegment, error) {
	var segments []models.DetectedSegment
	err := sd.db.Where("file_id = ?", fileID).Order("start_time ASC").Find(&segments).Error
	return segments, err
}

// DeleteSegments removes all detected segments for a file.
func (sd *SegmentDetector) DeleteSegments(fileID uint) error {
	return sd.db.Where("file_id = ?", fileID).Delete(&models.DetectedSegment{}).Error
}

// IsRunning returns whether the detector is currently processing.
func (sd *SegmentDetector) IsRunning() bool {
	sd.mu.Lock()
	defer sd.mu.Unlock()
	return sd.running
}

// detectFileInternal runs detection on a file without managing the running
// state lock. Used by DetectGroup to process multiple files.
func (sd *SegmentDetector) detectFileInternal(ctx context.Context, file models.DVRFile) (*DetectionResult, error) {
	if sd.ffmpegPath == "" {
		return nil, fmt.Errorf("ffmpeg not available")
	}

	if file.FilePath == "" || !fileExists(file.FilePath) {
		return nil, fmt.Errorf("file not accessible: %s", file.FilePath)
	}

	duration := float64(file.Duration)
	if duration <= 0 {
		duration = 3600
	}

	result := &DetectionResult{
		FileID:   file.ID,
		Duration: duration,
	}

	blacks, blackErr := sd.detectBlackFrames(ctx, file.FilePath)
	silences, silenceErr := sd.detectSilence(ctx, file.FilePath)

	if blackErr != nil && silenceErr != nil {
		return nil, fmt.Errorf("all detection methods failed")
	}

	segments := sd.findSegmentBoundaries(blacks, silences, duration)
	result.Segments = segments

	// Save to database
	sd.db.Where("file_id = ?", file.ID).Delete(&models.DetectedSegment{})
	for _, seg := range segments {
		dbSeg := models.DetectedSegment{
			FileID:    file.ID,
			Type:      seg.Type,
			StartTime: seg.StartTime,
			EndTime:   seg.EndTime,
		}
		sd.db.Create(&dbSeg)
	}

	return result, nil
}

// detectBlackFrames runs ffmpeg blackdetect on a file and parses the output
// for black frame timestamps and durations.
func (sd *SegmentDetector) detectBlackFrames(ctx context.Context, filePath string) ([]blackFrame, error) {
	args := []string{
		"-i", filePath,
		"-vf", "blackdetect=d=0.5:pix_th=0.10",
		"-an",
		"-f", "null",
		"-",
	}

	cmd := exec.CommandContext(ctx, sd.ffmpegPath, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		// ffmpeg returns non-zero for -f null, check if we got output
		if len(output) == 0 {
			return nil, fmt.Errorf("ffmpeg blackdetect failed: %w", err)
		}
	}

	return parseBlackFrames(string(output)), nil
}

// parseBlackFrames extracts black frame detections from ffmpeg stderr output.
// ffmpeg blackdetect output format:
//
//	[blackdetect @ 0x...] black_start:0 black_end:2.5 black_duration:2.5
func parseBlackFrames(output string) []blackFrame {
	var frames []blackFrame

	re := regexp.MustCompile(`black_start:(\d+\.?\d*)\s+black_end:(\d+\.?\d*)\s+black_duration:(\d+\.?\d*)`)
	matches := re.FindAllStringSubmatch(output, -1)

	for _, match := range matches {
		if len(match) < 4 {
			continue
		}

		startTime, err1 := strconv.ParseFloat(match[1], 64)
		duration, err2 := strconv.ParseFloat(match[3], 64)
		if err1 != nil || err2 != nil {
			continue
		}

		frames = append(frames, blackFrame{
			Time:     startTime,
			Duration: duration,
		})
	}

	return frames
}

// detectSilence runs ffmpeg silencedetect on a file and parses the output
// for silent segment timestamps and durations.
func (sd *SegmentDetector) detectSilence(ctx context.Context, filePath string) ([]silentSegment, error) {
	args := []string{
		"-i", filePath,
		"-af", "silencedetect=noise=-50dB:d=0.5",
		"-vn",
		"-f", "null",
		"-",
	}

	cmd := exec.CommandContext(ctx, sd.ffmpegPath, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		if len(output) == 0 {
			return nil, fmt.Errorf("ffmpeg silencedetect failed: %w", err)
		}
	}

	return parseSilence(string(output)), nil
}

// parseSilence extracts silence detections from ffmpeg stderr output.
// ffmpeg silencedetect output format:
//
//	[silencedetect @ 0x...] silence_start: 120.5
//	[silencedetect @ 0x...] silence_end: 123.0 | silence_duration: 2.5
func parseSilence(output string) []silentSegment {
	var segments []silentSegment

	startRe := regexp.MustCompile(`silence_start:\s*(\d+\.?\d*)`)
	endRe := regexp.MustCompile(`silence_end:\s*(\d+\.?\d*)\s*\|\s*silence_duration:\s*(\d+\.?\d*)`)

	lines := strings.Split(output, "\n")
	var pendingStart float64
	hasPending := false

	for _, line := range lines {
		if startMatch := startRe.FindStringSubmatch(line); len(startMatch) >= 2 {
			if start, err := strconv.ParseFloat(startMatch[1], 64); err == nil {
				pendingStart = start
				hasPending = true
			}
		}
		if endMatch := endRe.FindStringSubmatch(line); len(endMatch) >= 3 && hasPending {
			end, err1 := strconv.ParseFloat(endMatch[1], 64)
			dur, err2 := strconv.ParseFloat(endMatch[2], 64)
			if err1 == nil && err2 == nil {
				segments = append(segments, silentSegment{
					Start:    pendingStart,
					End:      end,
					Duration: dur,
				})
				hasPending = false
			}
		}
	}

	return segments
}

// findSegmentBoundaries analyzes black frames and silence to identify intro,
// credits, and outro boundaries. It looks for combined black+silence events
// in the first and last 5 minutes as transition points.
func (sd *SegmentDetector) findSegmentBoundaries(blacks []blackFrame, silences []silentSegment, duration float64) []SegmentInfo {
	var segments []SegmentInfo

	introWindow := math.Min(300.0, duration*0.15)  // first 5 min or 15% of duration
	creditsWindow := math.Min(300.0, duration*0.15) // last 5 min or 15% of duration
	creditsStart := duration - creditsWindow

	// Find transition points: locations where both black frames and silence
	// coincide, which are strong indicators of segment boundaries.
	type transitionPoint struct {
		time       float64
		confidence float64
		hasBlack   bool
		hasSilence bool
	}

	var introTransitions []transitionPoint
	var creditsTransitions []transitionPoint

	// Collect black frames in the intro and credits windows
	for _, bf := range blacks {
		if bf.Time < introWindow {
			tp := transitionPoint{time: bf.Time + bf.Duration, hasBlack: true, confidence: 0.5}
			// Check if there's a coinciding silence event (within 2 seconds)
			for _, s := range silences {
				if math.Abs(s.Start-bf.Time) < 2.0 || math.Abs(s.End-(bf.Time+bf.Duration)) < 2.0 {
					tp.hasSilence = true
					tp.confidence = 0.8
					break
				}
			}
			introTransitions = append(introTransitions, tp)
		}

		if bf.Time >= creditsStart {
			tp := transitionPoint{time: bf.Time, hasBlack: true, confidence: 0.5}
			for _, s := range silences {
				if math.Abs(s.Start-bf.Time) < 2.0 || math.Abs(s.End-(bf.Time+bf.Duration)) < 2.0 {
					tp.hasSilence = true
					tp.confidence = 0.8
					break
				}
			}
			creditsTransitions = append(creditsTransitions, tp)
		}
	}

	// Also check for silence-only transitions that might indicate boundaries
	for _, s := range silences {
		if s.Start < introWindow && s.Duration >= 1.0 {
			// Check if we already have a transition near this time
			found := false
			for _, t := range introTransitions {
				if math.Abs(t.time-s.End) < 3.0 {
					found = true
					break
				}
			}
			if !found {
				introTransitions = append(introTransitions, transitionPoint{
					time:       s.End,
					hasSilence: true,
					confidence: 0.4,
				})
			}
		}

		if s.Start >= creditsStart && s.Duration >= 1.0 {
			found := false
			for _, t := range creditsTransitions {
				if math.Abs(t.time-s.Start) < 3.0 {
					found = true
					break
				}
			}
			if !found {
				creditsTransitions = append(creditsTransitions, transitionPoint{
					time:       s.Start,
					hasSilence: true,
					confidence: 0.4,
				})
			}
		}
	}

	// Select the best intro boundary: prefer black+silence with highest
	// confidence, occurring after at least 15 seconds (typical minimum intro).
	if len(introTransitions) > 0 {
		sort.Slice(introTransitions, func(i, j int) bool {
			return introTransitions[i].confidence > introTransitions[j].confidence
		})

		for _, tp := range introTransitions {
			// Intro should be at least 15 seconds and no more than 4 minutes
			if tp.time >= 15.0 && tp.time <= 240.0 {
				segments = append(segments, SegmentInfo{
					Type:       "intro",
					StartTime:  0,
					EndTime:    tp.time,
					Confidence: tp.confidence,
					Method:     sd.transitionMethod(tp.hasBlack, tp.hasSilence),
				})
				break
			}
		}
	}

	// Select the best credits boundary
	if len(creditsTransitions) > 0 {
		sort.Slice(creditsTransitions, func(i, j int) bool {
			return creditsTransitions[i].confidence > creditsTransitions[j].confidence
		})

		for _, tp := range creditsTransitions {
			// Credits should start no earlier than 80% through the file
			if tp.time >= duration*0.80 {
				segments = append(segments, SegmentInfo{
					Type:       "credits",
					StartTime:  tp.time,
					EndTime:    duration,
					Confidence: tp.confidence,
					Method:     sd.transitionMethod(tp.hasBlack, tp.hasSilence),
				})
				break
			}
		}
	}

	// Look for outro: a segment between the main content end and credits start,
	// often indicated by a black frame/silence event in the last 10 minutes but
	// before credits.
	if len(segments) > 0 {
		var creditsStartTime float64
		for _, seg := range segments {
			if seg.Type == "credits" {
				creditsStartTime = seg.StartTime
				break
			}
		}

		if creditsStartTime > 0 {
			// Look for a transition point just before credits
			outroWindow := math.Max(creditsStartTime-300.0, duration*0.70)
			for _, bf := range blacks {
				bfEnd := bf.Time + bf.Duration
				if bfEnd > outroWindow && bfEnd < creditsStartTime-10.0 {
					// Check for coinciding silence
					confidence := 0.4
					method := "black_frames"
					for _, s := range silences {
						if math.Abs(s.Start-bf.Time) < 2.0 {
							confidence = 0.7
							method = "black_frames"
							break
						}
					}
					segments = append(segments, SegmentInfo{
						Type:       "outro",
						StartTime:  bf.Time,
						EndTime:    creditsStartTime,
						Confidence: confidence,
						Method:     method,
					})
					break
				}
			}
		}
	}

	// Sort segments by start time
	sort.Slice(segments, func(i, j int) bool {
		return segments[i].StartTime < segments[j].StartTime
	})

	return segments
}

// crossReferenceGroup compares detected segments across multiple episodes in
// a group to find common patterns. Segments that appear at similar timestamps
// across multiple episodes get boosted confidence.
func (sd *SegmentDetector) crossReferenceGroup(results map[uint][]SegmentInfo) map[uint][]SegmentInfo {
	if len(results) < 2 {
		return results
	}

	// Collect all intro and credits timestamps across episodes
	var introClusters []timestampCluster
	var creditsClusters []timestampCluster

	for _, segs := range results {
		for _, seg := range segs {
			switch seg.Type {
			case "intro":
				introClusters = append(introClusters, timestampCluster{
					segType:   "intro",
					startTime: seg.StartTime,
					endTime:   seg.EndTime,
					count:     1,
				})
			case "credits":
				creditsClusters = append(creditsClusters, timestampCluster{
					segType:   "credits",
					startTime: seg.StartTime,
					endTime:   seg.EndTime,
					count:     1,
				})
			}
		}
	}

	// Find the most common intro end time (within 5 second tolerance)
	bestIntroEnd := findDominantTimestamp(introClusters, len(results), true)
	// Find the most common credits start time
	bestCreditsStart := findDominantTimestamp(creditsClusters, len(results), false)

	episodeCount := float64(len(results))

	// Refine results: apply the common pattern to all episodes
	refined := make(map[uint][]SegmentInfo)

	for fileID, segs := range results {
		var refinedSegs []SegmentInfo
		hasIntro := false
		hasCredits := false

		for _, seg := range segs {
			switch seg.Type {
			case "intro":
				if bestIntroEnd > 0 && math.Abs(seg.EndTime-bestIntroEnd) < 10.0 {
					// This intro matches the common pattern - boost confidence
					matchRatio := float64(countNearTimestamps(introClusters, bestIntroEnd, 10.0, true)) / episodeCount
					seg.EndTime = bestIntroEnd
					seg.Confidence = math.Min(0.95, seg.Confidence+matchRatio*0.3)
					seg.Method = "pattern"
				}
				refinedSegs = append(refinedSegs, seg)
				hasIntro = true

			case "credits":
				if bestCreditsStart > 0 && math.Abs(seg.StartTime-bestCreditsStart) < 10.0 {
					matchRatio := float64(countNearTimestamps(creditsClusters, bestCreditsStart, 10.0, false)) / episodeCount
					seg.StartTime = bestCreditsStart
					seg.Confidence = math.Min(0.95, seg.Confidence+matchRatio*0.3)
					seg.Method = "pattern"
				}
				refinedSegs = append(refinedSegs, seg)
				hasCredits = true

			default:
				refinedSegs = append(refinedSegs, seg)
			}
		}

		// If this episode is missing a segment that the pattern predicts,
		// add it with lower confidence
		if !hasIntro && bestIntroEnd > 0 {
			matchCount := countNearTimestamps(introClusters, bestIntroEnd, 10.0, true)
			if float64(matchCount)/episodeCount >= 0.5 {
				refinedSegs = append(refinedSegs, SegmentInfo{
					Type:       "intro",
					StartTime:  0,
					EndTime:    bestIntroEnd,
					Confidence: float64(matchCount) / episodeCount * 0.7,
					Method:     "pattern",
				})
			}
		}

		if !hasCredits && bestCreditsStart > 0 {
			matchCount := countNearTimestamps(creditsClusters, bestCreditsStart, 10.0, false)
			duration := float64(0)
			// Get file duration from the existing segments
			for _, seg := range segs {
				if seg.EndTime > duration {
					duration = seg.EndTime
				}
			}
			if duration == 0 {
				// Look up the file's duration
				var file models.DVRFile
				if err := sd.db.First(&file, fileID).Error; err == nil {
					duration = float64(file.Duration)
				}
			}
			if duration > 0 && float64(matchCount)/episodeCount >= 0.5 {
				refinedSegs = append(refinedSegs, SegmentInfo{
					Type:       "credits",
					StartTime:  bestCreditsStart,
					EndTime:    duration,
					Confidence: float64(matchCount) / episodeCount * 0.7,
					Method:     "pattern",
				})
			}
		}

		// Sort by start time
		sort.Slice(refinedSegs, func(i, j int) bool {
			return refinedSegs[i].StartTime < refinedSegs[j].StartTime
		})

		refined[fileID] = refinedSegs
	}

	return refined
}

// transitionMethod returns a method string based on what detection signals
// were present at a transition point.
func (sd *SegmentDetector) transitionMethod(hasBlack, hasSilence bool) string {
	if hasBlack && hasSilence {
		return "black_frames"
	}
	if hasBlack {
		return "black_frames"
	}
	if hasSilence {
		return "silence"
	}
	return "black_frames"
}

// findDominantTimestamp finds the most common timestamp value in a cluster
// list within a tolerance window. If useEnd is true, it clusters on endTime;
// otherwise on startTime.
func findDominantTimestamp(clusters []timestampCluster, totalEpisodes int, useEnd bool) float64 {
	if len(clusters) == 0 {
		return 0
	}

	// Group timestamps that are within 5 seconds of each other
	const tolerance = 5.0
	type bucket struct {
		sum   float64
		count int
	}

	var buckets []bucket

	for _, c := range clusters {
		t := c.startTime
		if useEnd {
			t = c.endTime
		}

		found := false
		for i := range buckets {
			avg := buckets[i].sum / float64(buckets[i].count)
			if math.Abs(avg-t) < tolerance {
				buckets[i].sum += t
				buckets[i].count++
				found = true
				break
			}
		}
		if !found {
			buckets = append(buckets, bucket{sum: t, count: 1})
		}
	}

	// Find the bucket with the most entries
	bestIdx := 0
	for i, b := range buckets {
		if b.count > buckets[bestIdx].count {
			bestIdx = i
		}
	}

	// Only return if at least 2 episodes share the pattern
	if buckets[bestIdx].count >= 2 {
		return buckets[bestIdx].sum / float64(buckets[bestIdx].count)
	}

	return 0
}

// countNearTimestamps counts how many clusters have a timestamp near the
// given value within the tolerance window.
func countNearTimestamps(clusters []timestampCluster, target, tolerance float64, useEnd bool) int {
	count := 0
	for _, c := range clusters {
		t := c.startTime
		if useEnd {
			t = c.endTime
		}
		if math.Abs(t-target) < tolerance {
			count++
		}
	}
	return count
}
