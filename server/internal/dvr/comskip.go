package dvr

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// ComskipDetector handles commercial detection.
// Primary: ONNX neural model via Python script.
// Fallback: legacy comskip binary (EDL parsing).
type ComskipDetector struct {
	db          *gorm.DB
	comskipPath string // legacy binary path (may be empty)
	iniPath     string
	enabled     bool

	// ONNX model fields
	onnxEnabled bool
	pythonPath  string
	scriptPath  string
	modelPath   string
	scalerPath  string
}

// onnxSegment matches the JSON output from commercial_detect.py
type onnxSegment struct {
	Start      float64 `json:"start"`
	End        float64 `json:"end"`
	Confidence float64 `json:"confidence"`
	Label      string  `json:"label"`
}

type onnxResult struct {
	Segments       []onnxSegment `json:"segments"`
	Duration       float64       `json:"duration"`
	ProcessingTime float64       `json:"processing_time"`
	Error          string        `json:"error,omitempty"`
}

// NewComskipDetector creates a new commercial detector.
// It auto-detects the ONNX model and Python, falling back to the comskip binary.
func NewComskipDetector(db *gorm.DB, comskipPath, iniPath string) *ComskipDetector {
	d := &ComskipDetector{
		db:          db,
		comskipPath: comskipPath,
		iniPath:     iniPath,
	}

	// --- Try ONNX model first ---
	// Data dir is /data inside the container (mounted from appdata/openflix)
	dataDir := "/data"
	if v := os.Getenv("OPENFLIX_DATA_DIR"); v != "" {
		dataDir = v
	}

	scriptPath := filepath.Join(dataDir, "models", "commercial_detect.py")
	// Prefer v5 model; fall back to v4 if not present
	modelPath := filepath.Join(dataDir, "models", "commercial_skip_v5.onnx")
	scalerPath := filepath.Join(dataDir, "models", "scaler_v5.pkl")
	if !fileExists(modelPath) {
		modelPath = filepath.Join(dataDir, "models", "commercial_skip.onnx")
	}
	if !fileExists(scalerPath) {
		scalerPath = filepath.Join(dataDir, "models", "scaler.pkl")
	}

	pythonPath, _ := exec.LookPath("python3")
	if pythonPath == "" {
		pythonPath, _ = exec.LookPath("python")
	}

	if pythonPath != "" && fileExists(scriptPath) && fileExists(modelPath) && fileExists(scalerPath) {
		d.onnxEnabled = true
		d.pythonPath = pythonPath
		d.scriptPath = scriptPath
		d.modelPath = modelPath
		d.scalerPath = scalerPath
		d.enabled = true
		log.Printf("ONNX commercial detection enabled (model: %s, scaler: %s)", modelPath, scalerPath)
		return d
	}

	// --- Fall back to legacy comskip binary ---
	if comskipPath == "" {
		if path, err := exec.LookPath("comskip"); err == nil {
			comskipPath = path
			d.comskipPath = comskipPath
		}
	}

	if comskipPath != "" && fileExists(comskipPath) {
		d.enabled = true
		log.Printf("Legacy comskip binary enabled: %s", comskipPath)
	} else {
		log.Printf("Commercial detection unavailable (no ONNX model and no comskip binary)")
	}

	return d
}

// IsEnabled returns whether any commercial detection is available
func (c *ComskipDetector) IsEnabled() bool {
	return c.enabled
}

// IsONNX returns true if the ONNX model is being used
func (c *ComskipDetector) IsONNX() bool {
	return c.onnxEnabled
}

// DetectCommercials runs commercial detection on a recording and stores the results
func (c *ComskipDetector) DetectCommercials(recording *models.Recording) error {
	if !c.enabled {
		return fmt.Errorf("commercial detection not available")
	}

	if recording.FilePath == "" {
		return fmt.Errorf("recording has no file path")
	}

	if !fileExists(recording.FilePath) {
		return fmt.Errorf("recording file not found: %s", recording.FilePath)
	}

	// Clear any existing segments for this recording
	c.db.Where("recording_id = ?", recording.ID).Delete(&models.CommercialSegment{})

	var segments []models.CommercialSegment
	var err error

	if c.onnxEnabled {
		segments, err = c.detectWithONNX(recording)
	} else {
		segments, err = c.detectWithComskip(recording)
	}

	if err != nil {
		return err
	}

	// Store segments in database
	for i := range segments {
		segments[i].RecordingID = recording.ID
		if err := c.db.Create(&segments[i]).Error; err != nil {
			log.Printf("Failed to save commercial segment: %v", err)
		}
	}

	log.Printf("Detected %d commercial segments in recording %d (ONNX=%v)", len(segments), recording.ID, c.onnxEnabled)
	return nil
}

// detectWithONNX calls commercial_detect.py and parses its JSON output
func (c *ComskipDetector) detectWithONNX(recording *models.Recording) ([]models.CommercialSegment, error) {
	log.Printf("Running ONNX commercial detection on: %s", recording.FilePath)

	cmd := exec.Command(c.pythonPath,
		c.scriptPath,
		"--model", c.modelPath,
		"--scaler", c.scalerPath,
		"--input", recording.FilePath,
		"--output-json",
	)

	out, err := cmd.Output()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			return nil, fmt.Errorf("ONNX detection failed: %s", string(exitErr.Stderr))
		}
		return nil, fmt.Errorf("ONNX detection failed: %w", err)
	}

	// The script prints progress lines to stdout before the JSON object.
	// Find the last line starting with '{' and use that as the JSON payload.
	// Also replace NaN (invalid JSON) with null before parsing.
	jsonLine := ""
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "{") {
			jsonLine = line
		}
	}
	if jsonLine == "" {
		return nil, fmt.Errorf("no JSON found in ONNX output")
	}
	jsonLine = strings.ReplaceAll(jsonLine, ": NaN", ": null")
	jsonLine = strings.ReplaceAll(jsonLine, ":NaN", ":null")

	var result onnxResult
	if err := json.Unmarshal([]byte(jsonLine), &result); err != nil {
		return nil, fmt.Errorf("failed to parse ONNX output: %w", err)
	}

	if result.Error != "" {
		return nil, fmt.Errorf("ONNX model error: %s", result.Error)
	}

	// Only keep commercial segments (not content)
	var segments []models.CommercialSegment
	for _, seg := range result.Segments {
		if seg.Label != "commercial" {
			continue
		}
		segments = append(segments, models.CommercialSegment{
			StartTime: seg.Start,
			EndTime:   seg.End,
			Duration:  seg.End - seg.Start,
		})
	}

	log.Printf("ONNX detection complete: %d commercial breaks found in %.0fs (processing took %.1fs)",
		len(segments), result.Duration, result.ProcessingTime)

	return segments, nil
}

// detectWithComskip uses the legacy comskip binary
func (c *ComskipDetector) detectWithComskip(recording *models.Recording) ([]models.CommercialSegment, error) {
	log.Printf("Running comskip on: %s", recording.FilePath)

	args := []string{}
	if c.iniPath != "" && fileExists(c.iniPath) {
		args = append(args, "--ini="+c.iniPath)
	}
	args = append(args, "--output="+filepath.Dir(recording.FilePath))
	args = append(args, recording.FilePath)

	cmd := exec.Command(c.comskipPath, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Comskip error: %v, output: %s", err, string(output))
		// comskip sometimes exits non-zero but still produces output — continue
	}

	edlPath := strings.TrimSuffix(recording.FilePath, filepath.Ext(recording.FilePath)) + ".edl"
	segments, err := parseEDL(edlPath)
	if err != nil {
		txtPath := strings.TrimSuffix(recording.FilePath, filepath.Ext(recording.FilePath)) + ".txt"
		segments, err = parseComskipTxt(txtPath)
		if err != nil {
			return nil, fmt.Errorf("failed to parse comskip output: %w", err)
		}
	}

	cleanupComskipFiles(recording.FilePath)
	return segments, nil
}

// parseEDL parses an EDL (Edit Decision List) file
// Format: start_time end_time action
// Action: 0=cut, 3=commercial break
func parseEDL(path string) ([]models.CommercialSegment, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var segments []models.CommercialSegment
	for _, line := range strings.Split(string(data), "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.Fields(line)
		if len(parts) < 3 {
			continue
		}

		var start, end float64
		var action int
		if _, err := fmt.Sscan(parts[0], &start); err != nil {
			continue
		}
		if _, err := fmt.Sscan(parts[1], &end); err != nil {
			continue
		}
		if _, err := fmt.Sscan(parts[2], &action); err != nil {
			continue
		}

		if action == 0 || action == 3 {
			segments = append(segments, models.CommercialSegment{
				StartTime: start,
				EndTime:   end,
				Duration:  end - start,
			})
		}
	}

	return segments, nil
}

// parseComskipTxt parses a Comskip TXT file (frame-based format)
func parseComskipTxt(path string) ([]models.CommercialSegment, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var segments []models.CommercialSegment
	frameRate := 29.97

	lines := strings.Split(string(data), "\n")
	for i, line := range lines {
		line = strings.TrimSpace(line)
		if i == 0 {
			if strings.Contains(line, "FRAMES AT") {
				parts := strings.Split(line, "FRAMES AT")
				if len(parts) >= 2 {
					var fps float64
					if _, err := fmt.Sscan(strings.TrimSpace(parts[1]), &fps); err == nil {
						frameRate = fps
					}
				}
			}
			continue
		}
		if line == "" || !strings.Contains(line, "\t") {
			continue
		}
		parts := strings.Split(line, "\t")
		if len(parts) < 2 {
			continue
		}
		var startFrame, endFrame int
		if _, err := fmt.Sscan(strings.TrimSpace(parts[0]), &startFrame); err != nil {
			continue
		}
		if _, err := fmt.Sscan(strings.TrimSpace(parts[1]), &endFrame); err != nil {
			continue
		}
		start := float64(startFrame) / frameRate
		end := float64(endFrame) / frameRate
		segments = append(segments, models.CommercialSegment{
			StartTime: start,
			EndTime:   end,
			Duration:  end - start,
		})
	}

	return segments, nil
}

// cleanupComskipFiles removes intermediate comskip files
func cleanupComskipFiles(videoPath string) {
	base := strings.TrimSuffix(videoPath, filepath.Ext(videoPath))
	for _, ext := range []string{".txt", ".log", ".logo.txt", ".ffmeta"} {
		os.Remove(base + ext)
	}
}

// GetCommercialSegments retrieves commercial segments for a recording
func (c *ComskipDetector) GetCommercialSegments(recordingID uint) ([]models.CommercialSegment, error) {
	var segments []models.CommercialSegment
	err := c.db.Where("recording_id = ?", recordingID).Order("start_time").Find(&segments).Error
	return segments, err
}

// DeleteCommercialSegments removes all commercial segments for a recording
func (c *ComskipDetector) DeleteCommercialSegments(recordingID uint) error {
	return c.db.Where("recording_id = ?", recordingID).Delete(&models.CommercialSegment{}).Error
}

// fileExists checks if a file exists
func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
