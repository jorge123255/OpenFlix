package dvr

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// ComskipDetector handles commercial detection using Comskip
type ComskipDetector struct {
	db           *gorm.DB
	comskipPath  string
	iniPath      string
	enabled      bool
}

// NewComskipDetector creates a new commercial detector
func NewComskipDetector(db *gorm.DB, comskipPath, iniPath string) *ComskipDetector {
	// Try to find comskip if not specified
	if comskipPath == "" {
		if path, err := exec.LookPath("comskip"); err == nil {
			comskipPath = path
		}
	}

	enabled := comskipPath != "" && fileExists(comskipPath)

	if enabled {
		log.Printf("Comskip commercial detection enabled: %s", comskipPath)
	} else {
		log.Printf("Comskip not found - commercial detection disabled")
	}

	return &ComskipDetector{
		db:          db,
		comskipPath: comskipPath,
		iniPath:     iniPath,
		enabled:     enabled,
	}
}

// IsEnabled returns whether Comskip is available
func (c *ComskipDetector) IsEnabled() bool {
	return c.enabled
}

// DetectCommercials runs Comskip on a recording and stores the results
func (c *ComskipDetector) DetectCommercials(recording *models.Recording) error {
	if !c.enabled {
		return fmt.Errorf("comskip not available")
	}

	if recording.FilePath == "" {
		return fmt.Errorf("recording has no file path")
	}

	if !fileExists(recording.FilePath) {
		return fmt.Errorf("recording file not found: %s", recording.FilePath)
	}

	log.Printf("Running Comskip commercial detection on: %s", recording.FilePath)

	// Build comskip command
	args := []string{}

	// Add INI file if specified
	if c.iniPath != "" && fileExists(c.iniPath) {
		args = append(args, "--ini="+c.iniPath)
	}

	// Output EDL file (Edit Decision List)
	args = append(args, "--output="+filepath.Dir(recording.FilePath))
	args = append(args, recording.FilePath)

	cmd := exec.Command(c.comskipPath, args...)
	output, err := cmd.CombinedOutput()

	if err != nil {
		log.Printf("Comskip error: %v, output: %s", err, string(output))
		// Don't return error - comskip sometimes exits non-zero but still produces output
	}

	// Parse the EDL file
	edlPath := strings.TrimSuffix(recording.FilePath, filepath.Ext(recording.FilePath)) + ".edl"
	segments, err := c.parseEDL(edlPath)
	if err != nil {
		// Try parsing TXT file as fallback
		txtPath := strings.TrimSuffix(recording.FilePath, filepath.Ext(recording.FilePath)) + ".txt"
		segments, err = c.parseComskipTxt(txtPath)
		if err != nil {
			return fmt.Errorf("failed to parse comskip output: %w", err)
		}
	}

	// Store segments in database
	for _, seg := range segments {
		seg.RecordingID = recording.ID
		if err := c.db.Create(&seg).Error; err != nil {
			log.Printf("Failed to save commercial segment: %v", err)
		}
	}

	log.Printf("Detected %d commercial segments in recording %d", len(segments), recording.ID)

	// Clean up comskip output files (keep only EDL for reference)
	c.cleanupComskipFiles(recording.FilePath)

	return nil
}

// parseEDL parses an EDL (Edit Decision List) file
// Format: start_time end_time action
// Action: 0=cut, 1=mute, 2=scene marker, 3=commercial break
func (c *ComskipDetector) parseEDL(path string) ([]models.CommercialSegment, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var segments []models.CommercialSegment
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		// Parse: start_time end_time action
		parts := strings.Fields(line)
		if len(parts) < 3 {
			continue
		}

		startTime, err := strconv.ParseFloat(parts[0], 64)
		if err != nil {
			continue
		}

		endTime, err := strconv.ParseFloat(parts[1], 64)
		if err != nil {
			continue
		}

		action, err := strconv.Atoi(parts[2])
		if err != nil {
			continue
		}

		// Action 0 = cut (commercial), 3 = commercial break
		if action == 0 || action == 3 {
			segments = append(segments, models.CommercialSegment{
				StartTime: startTime,
				EndTime:   endTime,
				Duration:  endTime - startTime,
			})
		}
	}

	return segments, scanner.Err()
}

// parseComskipTxt parses a Comskip TXT file (alternative format)
// Format: Frame start, Frame end
func (c *ComskipDetector) parseComskipTxt(path string) ([]models.CommercialSegment, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var segments []models.CommercialSegment
	scanner := bufio.NewScanner(file)

	// First line is header with video info
	// FILE PROCESSING COMPLETE  XXXX FRAMES AT XXXX
	var frameRate float64 = 29.97 // Default NTSC

	lineNum := 0
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		lineNum++

		if lineNum == 1 {
			// Try to extract frame rate from header
			if strings.Contains(line, "FRAMES AT") {
				parts := strings.Split(line, "FRAMES AT")
				if len(parts) >= 2 {
					if fps, err := strconv.ParseFloat(strings.TrimSpace(parts[1]), 64); err == nil {
						frameRate = fps
					}
				}
			}
			continue
		}

		if line == "" || !strings.Contains(line, "\t") {
			continue
		}

		// Parse: FrameStart\tFrameEnd
		parts := strings.Split(line, "\t")
		if len(parts) < 2 {
			continue
		}

		startFrame, err := strconv.Atoi(strings.TrimSpace(parts[0]))
		if err != nil {
			continue
		}

		endFrame, err := strconv.Atoi(strings.TrimSpace(parts[1]))
		if err != nil {
			continue
		}

		// Convert frames to seconds
		startTime := float64(startFrame) / frameRate
		endTime := float64(endFrame) / frameRate

		segments = append(segments, models.CommercialSegment{
			StartTime: startTime,
			EndTime:   endTime,
			Duration:  endTime - startTime,
		})
	}

	return segments, scanner.Err()
}

// cleanupComskipFiles removes intermediate Comskip files, keeping only EDL
func (c *ComskipDetector) cleanupComskipFiles(videoPath string) {
	basePath := strings.TrimSuffix(videoPath, filepath.Ext(videoPath))

	// Files to remove (keep .edl for reference)
	extensions := []string{".txt", ".log", ".logo.txt", ".ffmeta"}

	for _, ext := range extensions {
		path := basePath + ext
		if fileExists(path) {
			os.Remove(path)
		}
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

// GenerateDefaultINI creates a default Comskip INI configuration
func GenerateDefaultINI(path string) error {
	ini := `; OpenFlix Comskip Configuration
; Based on US broadcast TV defaults

[Main Settings]
detect_method=111
validate_silence=1
validate_uniform=1
validate_brightness=1

[Tuning]
max_avg_brightness=20
max_brightness=60
test_brightness=40
max_volume=500
non_uniformity=500

[Logo Detection]
logo_threshold=0.75
logo_filter=0

[Output]
output_edl=1
output_txt=0
output_vdr=0
output_ffmeta=0
output_chapters=0

[Scoring]
min_show_segment_length=250
max_commercial_size=240
min_commercial_size=4

[Padding]
padding=0
`
	return os.WriteFile(path, []byte(ini), 0644)
}
