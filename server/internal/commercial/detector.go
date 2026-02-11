package commercial

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

// CommercialDetector handles automatic commercial detection and skipping
type CommercialDetector struct {
	mu            sync.RWMutex
	detections    map[string]*CommercialData // recordingID -> data
	liveDetectors map[string]*LiveDetector   // channelID -> detector
	Config        DetectorConfig
}

// CommercialData holds detected commercials for a recording
type CommercialData struct {
	RecordingID   string            `json:"recording_id"`
	Duration      float64           `json:"duration"`       // total video duration
	Commercials   []CommercialBreak `json:"commercials"`
	DetectedAt    time.Time         `json:"detected_at"`
	Method        string            `json:"method"`         // "comskip", "ai", "hybrid"
	Confidence    float64           `json:"confidence"`     // 0-1
	UserCorrected bool              `json:"user_corrected"` // user made edits
}

// CommercialBreak represents a single commercial break
type CommercialBreak struct {
	StartTime  float64 `json:"start_time"`  // seconds from start
	EndTime    float64 `json:"end_time"`
	Duration   float64 `json:"duration"`
	Confidence float64 `json:"confidence"`
	Skipped    bool    `json:"skipped"`     // was auto-skipped
	UserMarked bool    `json:"user_marked"` // manually marked by user
}

// DetectorConfig configuration for detection
type DetectorConfig struct {
	// Detection methods
	UseComskip       bool    `json:"use_comskip"`
	UseBlackFrame    bool    `json:"use_black_frame"`
	UseAudioAnalysis bool    `json:"use_audio_analysis"`
	UseLogoDetection bool    `json:"use_logo_detection"`

	// Thresholds
	BlackFrameThreshold float64 `json:"black_frame_threshold"` // 0-1, lower = darker
	SilenceThreshold    float64 `json:"silence_threshold"`     // dB
	MinCommercialLength float64 `json:"min_commercial_length"` // seconds
	MaxCommercialLength float64 `json:"max_commercial_length"` // seconds
	MinBreakGap         float64 `json:"min_break_gap"`         // seconds between breaks

	// Auto-skip settings
	AutoSkipEnabled     bool    `json:"auto_skip_enabled"`
	AutoSkipDelay       float64 `json:"auto_skip_delay"`       // seconds to show "skipping..." UI
	ConfidenceThreshold float64 `json:"confidence_threshold"` // min confidence for auto-skip

	// Paths
	ComskipPath string `json:"comskip_path"`
	ComskipIni  string `json:"comskip_ini"`
	FFmpegPath  string `json:"ffmpeg_path"`
}

// DefaultDetectorConfig returns sensible defaults
func DefaultDetectorConfig() DetectorConfig {
	return DetectorConfig{
		UseComskip:          true,
		UseBlackFrame:       true,
		UseAudioAnalysis:    true,
		UseLogoDetection:    false, // requires ML model
		BlackFrameThreshold: 0.05,
		SilenceThreshold:    -50,
		MinCommercialLength: 15,
		MaxCommercialLength: 300,
		MinBreakGap:         60,
		AutoSkipEnabled:     true,
		AutoSkipDelay:       3.0,
		ConfidenceThreshold: 0.8,
		ComskipPath:         "/usr/local/bin/comskip",
		ComskipIni:          "/config/comskip.ini",
		FFmpegPath:          "/usr/local/bin/ffmpeg",
	}
}

// NewCommercialDetector creates a new detector
func NewCommercialDetector(config DetectorConfig) *CommercialDetector {
	return &CommercialDetector{
		detections:    make(map[string]*CommercialData),
		liveDetectors: make(map[string]*LiveDetector),
		Config:        config,
	}
}

// DetectCommercials analyzes a recording for commercials
func (cd *CommercialDetector) DetectCommercials(ctx context.Context, recordingID, videoPath string) (*CommercialData, error) {
	cd.mu.Lock()
	defer cd.mu.Unlock()

	// Check if already detected
	if data, exists := cd.detections[recordingID]; exists {
		return data, nil
	}

	var allBreaks []CommercialBreak
	var methods []string

	// Method 1: Comskip (industry standard)
	if cd.Config.UseComskip {
		breaks, err := cd.runComskip(ctx, videoPath)
		if err == nil && len(breaks) > 0 {
			allBreaks = append(allBreaks, breaks...)
			methods = append(methods, "comskip")
		}
	}

	// Method 2: Black frame detection
	if cd.Config.UseBlackFrame {
		breaks, err := cd.detectBlackFrames(ctx, videoPath)
		if err == nil && len(breaks) > 0 {
			allBreaks = cd.mergeBreaks(allBreaks, breaks)
			methods = append(methods, "blackframe")
		}
	}

	// Method 3: Audio analysis
	if cd.Config.UseAudioAnalysis {
		breaks, err := cd.analyzeAudio(ctx, videoPath)
		if err == nil && len(breaks) > 0 {
			allBreaks = cd.mergeBreaks(allBreaks, breaks)
			methods = append(methods, "audio")
		}
	}

	// Calculate confidence based on method agreement
	allBreaks = cd.calculateConfidence(allBreaks)

	// Get video duration
	duration := cd.getVideoDuration(ctx, videoPath)

	method := "hybrid"
	if len(methods) == 1 {
		method = methods[0]
	}

	data := &CommercialData{
		RecordingID: recordingID,
		Duration:    duration,
		Commercials: allBreaks,
		DetectedAt:  time.Now(),
		Method:      method,
		Confidence:  cd.overallConfidence(allBreaks),
	}

	cd.detections[recordingID] = data
	return data, nil
}

// runComskip runs the comskip tool
func (cd *CommercialDetector) runComskip(ctx context.Context, videoPath string) ([]CommercialBreak, error) {
	args := []string{
		"--ini=" + cd.Config.ComskipIni,
		"--output=/tmp",
		"--quiet",
		videoPath,
	}

	cmd := exec.CommandContext(ctx, cd.Config.ComskipPath, args...)
	if err := cmd.Run(); err != nil {
		return nil, err
	}

	// Parse comskip output (EDL or TXT file)
	return cd.parseComskipOutput(videoPath)
}

// parseComskipOutput reads comskip's EDL file
func (cd *CommercialDetector) parseComskipOutput(videoPath string) ([]CommercialBreak, error) {
	// Comskip creates .edl file next to video or in output dir
	edlPath := videoPath[:len(videoPath)-4] + ".edl"

	data, err := os.ReadFile(edlPath)
	if err != nil {
		// Try /tmp directory
		edlPath = "/tmp/" + videoPath[strings.LastIndex(videoPath, "/")+1:len(videoPath)-4] + ".edl"
		data, err = os.ReadFile(edlPath)
		if err != nil {
			return nil, err
		}
	}

	var breaks []CommercialBreak
	// Parse EDL format: start_time    end_time    type(0=cut,1=mute,2=scene,3=commercial)
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		var start, end float64
		var breakType int
		if _, err := fmt.Sscanf(line, "%f\t%f\t%d", &start, &end, &breakType); err == nil {
			if breakType == 0 || breakType == 3 { // cut or commercial
				breaks = append(breaks, CommercialBreak{
					StartTime:  start,
					EndTime:    end,
					Duration:   end - start,
					Confidence: 0.7, // comskip baseline confidence
				})
			}
		}
	}

	return breaks, nil
}

// detectBlackFrames finds black frames using ffmpeg
func (cd *CommercialDetector) detectBlackFrames(ctx context.Context, videoPath string) ([]CommercialBreak, error) {
	// ffmpeg -i video.ts -vf "blackdetect=d=0.5:pix_th=0.05" -f null -
	args := []string{
		"-i", videoPath,
		"-vf", fmt.Sprintf("blackdetect=d=0.5:pix_th=%.2f", cd.Config.BlackFrameThreshold),
		"-f", "null",
		"-",
	}

	cmd := exec.CommandContext(ctx, cd.Config.FFmpegPath, args...)
	output, _ := cmd.CombinedOutput() // ffmpeg outputs to stderr

	return cd.parseBlackDetectOutput(string(output))
}

// parseBlackDetectOutput parses ffmpeg blackdetect output
func (cd *CommercialDetector) parseBlackDetectOutput(output string) ([]CommercialBreak, error) {
	var blacks []struct {
		start, end float64
	}

	// Parse: [blackdetect @ 0x...] black_start:120.5 black_end:121.0 black_duration:0.5
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		if !strings.Contains(line, "blackdetect") {
			continue
		}

		var start, end float64
		if _, err := fmt.Sscanf(line, "%*[^:]:%*[^:]black_start:%f black_end:%f", &start, &end); err == nil {
			blacks = append(blacks, struct{ start, end float64 }{start, end})
		}
	}

	// Convert black frame sequences into commercial breaks
	var breaks []CommercialBreak

	for i := 0; i < len(blacks)-1; i++ {
		duration := blacks[i+1].start - blacks[i].end
		if duration >= cd.Config.MinCommercialLength && duration <= cd.Config.MaxCommercialLength {
			breaks = append(breaks, CommercialBreak{
				StartTime:  blacks[i].end,
				EndTime:    blacks[i+1].start,
				Duration:   duration,
				Confidence: 0.5, // black frame alone is less confident
			})
		}
	}

	return breaks, nil
}

// analyzeAudio finds audio patterns indicating commercials
func (cd *CommercialDetector) analyzeAudio(ctx context.Context, videoPath string) ([]CommercialBreak, error) {
	// ffmpeg silencedetect
	args := []string{
		"-i", videoPath,
		"-af", fmt.Sprintf("silencedetect=noise=%.0fdB:d=0.5", cd.Config.SilenceThreshold),
		"-f", "null",
		"-",
	}

	cmd := exec.CommandContext(ctx, cd.Config.FFmpegPath, args...)
	output, _ := cmd.CombinedOutput()

	return cd.parseSilenceOutput(string(output))
}

// parseSilenceOutput parses ffmpeg silencedetect output
func (cd *CommercialDetector) parseSilenceOutput(output string) ([]CommercialBreak, error) {
	var silences []struct {
		start, end float64
	}

	// Parse: [silencedetect @ 0x...] silence_start: 120.5
	//        [silencedetect @ 0x...] silence_end: 121.0 | silence_duration: 0.5
	lines := strings.Split(output, "\n")
	var currentStart float64 = -1

	for _, line := range lines {
		if strings.Contains(line, "silence_start") {
			fmt.Sscanf(line, "%*[^:]: %f", &currentStart)
		} else if strings.Contains(line, "silence_end") && currentStart >= 0 {
			var end float64
			fmt.Sscanf(line, "%*[^:]: %f", &end)
			silences = append(silences, struct{ start, end float64 }{currentStart, end})
			currentStart = -1
		}
	}

	// Group silences into potential commercial breaks
	var breaks []CommercialBreak
	for i := 0; i < len(silences)-1; i++ {
		duration := silences[i+1].start - silences[i].end
		if duration >= cd.Config.MinCommercialLength && duration <= cd.Config.MaxCommercialLength {
			breaks = append(breaks, CommercialBreak{
				StartTime:  silences[i].end,
				EndTime:    silences[i+1].start,
				Duration:   duration,
				Confidence: 0.4, // audio alone is least confident
			})
		}
	}

	return breaks, nil
}

// mergeBreaks merges breaks from different detection methods
func (cd *CommercialDetector) mergeBreaks(existing, new []CommercialBreak) []CommercialBreak {
	for _, n := range new {
		merged := false
		for i, e := range existing {
			// Check overlap
			if n.StartTime < e.EndTime && n.EndTime > e.StartTime {
				// Merge: take wider range, boost confidence
				existing[i].StartTime = minFloat(e.StartTime, n.StartTime)
				existing[i].EndTime = maxFloat(e.EndTime, n.EndTime)
				existing[i].Duration = existing[i].EndTime - existing[i].StartTime
				existing[i].Confidence = minFloat(1.0, e.Confidence+0.2) // boost
				merged = true
				break
			}
		}
		if !merged {
			existing = append(existing, n)
		}
	}
	return existing
}

// calculateConfidence adjusts confidence based on signals
func (cd *CommercialDetector) calculateConfidence(breaks []CommercialBreak) []CommercialBreak {
	for i := range breaks {
		// Boost confidence for typical commercial lengths
		dur := breaks[i].Duration
		if dur >= 15 && dur <= 60 {
			breaks[i].Confidence = minFloat(1.0, breaks[i].Confidence+0.1)
		}
		// Standard break lengths: 30s, 60s, 90s, 120s
		if dur == 30 || dur == 60 || dur == 90 || dur == 120 {
			breaks[i].Confidence = minFloat(1.0, breaks[i].Confidence+0.1)
		}
	}
	return breaks
}

// overallConfidence calculates overall detection confidence
func (cd *CommercialDetector) overallConfidence(breaks []CommercialBreak) float64 {
	if len(breaks) == 0 {
		return 0
	}

	var sum float64
	for _, b := range breaks {
		sum += b.Confidence
	}
	return sum / float64(len(breaks))
}

// getVideoDuration gets video duration using ffprobe
func (cd *CommercialDetector) getVideoDuration(ctx context.Context, videoPath string) float64 {
	cmd := exec.CommandContext(ctx, "ffprobe",
		"-v", "quiet",
		"-show_entries", "format=duration",
		"-of", "json",
		videoPath,
	)

	output, err := cmd.Output()
	if err != nil {
		return 0
	}

	var result struct {
		Format struct {
			Duration string `json:"duration"`
		} `json:"format"`
	}

	if err := json.Unmarshal(output, &result); err != nil {
		return 0
	}

	var duration float64
	fmt.Sscanf(result.Format.Duration, "%f", &duration)
	return duration
}

// GetCommercials returns detected commercials for a recording
func (cd *CommercialDetector) GetCommercials(recordingID string) *CommercialData {
	cd.mu.RLock()
	defer cd.mu.RUnlock()
	return cd.detections[recordingID]
}

// ShouldSkip checks if current position should skip
func (cd *CommercialDetector) ShouldSkip(recordingID string, position float64) (bool, float64) {
	cd.mu.RLock()
	data := cd.detections[recordingID]
	cd.mu.RUnlock()

	if data == nil || !cd.Config.AutoSkipEnabled {
		return false, 0
	}

	for _, comm := range data.Commercials {
		if position >= comm.StartTime && position < comm.EndTime {
			if comm.Confidence >= cd.Config.ConfidenceThreshold {
				return true, comm.EndTime
			}
		}
	}

	return false, 0
}

// MarkAsCommercial allows user to mark a segment as commercial
func (cd *CommercialDetector) MarkAsCommercial(recordingID string, start, end float64) {
	cd.mu.Lock()
	defer cd.mu.Unlock()

	data := cd.detections[recordingID]
	if data == nil {
		data = &CommercialData{
			RecordingID: recordingID,
			Commercials: []CommercialBreak{},
			DetectedAt:  time.Now(),
			Method:      "manual",
		}
		cd.detections[recordingID] = data
	}

	data.Commercials = append(data.Commercials, CommercialBreak{
		StartTime:  start,
		EndTime:    end,
		Duration:   end - start,
		Confidence: 1.0,
		UserMarked: true,
	})
	data.UserCorrected = true
}

// MarkAsContent marks a segment as NOT a commercial (user correction)
func (cd *CommercialDetector) MarkAsContent(recordingID string, start, end float64) {
	cd.mu.Lock()
	defer cd.mu.Unlock()

	data := cd.detections[recordingID]
	if data == nil {
		return
	}

	// Remove or split commercials that overlap with this segment
	var newComms []CommercialBreak
	for _, comm := range data.Commercials {
		if comm.EndTime <= start || comm.StartTime >= end {
			// No overlap, keep as is
			newComms = append(newComms, comm)
		} else if comm.StartTime < start && comm.EndTime > end {
			// Split into two
			newComms = append(newComms, CommercialBreak{
				StartTime:  comm.StartTime,
				EndTime:    start,
				Duration:   start - comm.StartTime,
				Confidence: comm.Confidence,
			})
			newComms = append(newComms, CommercialBreak{
				StartTime:  end,
				EndTime:    comm.EndTime,
				Duration:   comm.EndTime - end,
				Confidence: comm.Confidence,
			})
		} else if comm.StartTime < start {
			// Trim end
			newComms = append(newComms, CommercialBreak{
				StartTime:  comm.StartTime,
				EndTime:    start,
				Duration:   start - comm.StartTime,
				Confidence: comm.Confidence,
			})
		} else if comm.EndTime > end {
			// Trim start
			newComms = append(newComms, CommercialBreak{
				StartTime:  end,
				EndTime:    comm.EndTime,
				Duration:   comm.EndTime - end,
				Confidence: comm.Confidence,
			})
		}
		// else: completely contained, remove it
	}

	data.Commercials = newComms
	data.UserCorrected = true
}

// GetStats returns detection statistics
func (cd *CommercialDetector) GetStats() map[string]interface{} {
	cd.mu.RLock()
	defer cd.mu.RUnlock()

	totalRecordings := len(cd.detections)
	var totalCommercials int
	var totalDuration float64
	var userCorrected int

	for _, data := range cd.detections {
		totalCommercials += len(data.Commercials)
		for _, c := range data.Commercials {
			totalDuration += c.Duration
		}
		if data.UserCorrected {
			userCorrected++
		}
	}

	return map[string]interface{}{
		"recordings_analyzed":         totalRecordings,
		"commercials_found":           totalCommercials,
		"total_commercial_time_hours": totalDuration / 3600,
		"user_corrected":              userCorrected,
		"auto_skip_enabled":           cd.Config.AutoSkipEnabled,
	}
}

// LiveDetector handles real-time commercial detection for live TV
type LiveDetector struct {
	ChannelID      string
	CurrentBreak   *CommercialBreak
	IsInCommercial bool
	LastCheck      time.Time
}

// Helper functions
func minFloat(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}

func maxFloat(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}
