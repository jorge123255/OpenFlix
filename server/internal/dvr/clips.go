package dvr

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// ClipManager handles bookmark management and clip extraction
type ClipManager struct {
	db         *gorm.DB
	ffmpegPath string
	clipsDir   string
}

// NewClipManager creates a new ClipManager
func NewClipManager(db *gorm.DB, clipsDir string) *ClipManager {
	ffmpegPath, err := exec.LookPath("ffmpeg")
	if err != nil {
		ffmpegPath = "ffmpeg" // fallback, hope it's on PATH at runtime
		logger.Warnf("ffmpeg not found on PATH, using default: %s", ffmpegPath)
	}

	// Ensure clips directory exists
	if err := os.MkdirAll(clipsDir, 0755); err != nil {
		logger.Errorf("Failed to create clips directory %s: %v", clipsDir, err)
	}

	// Ensure thumbnails subdirectory exists
	thumbDir := filepath.Join(clipsDir, "thumbnails")
	if err := os.MkdirAll(thumbDir, 0755); err != nil {
		logger.Errorf("Failed to create thumbnails directory %s: %v", thumbDir, err)
	}

	return &ClipManager{
		db:         db,
		ffmpegPath: ffmpegPath,
		clipsDir:   clipsDir,
	}
}

// GenerateThumbnail creates a thumbnail image at a specific timestamp using ffmpeg.
// Returns the path to the generated thumbnail file.
func (cm *ClipManager) GenerateThumbnail(ctx context.Context, filePath string, timestamp float64) (string, error) {
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return "", fmt.Errorf("source file not found: %s", filePath)
	}

	thumbDir := filepath.Join(cm.clipsDir, "thumbnails")
	thumbFilename := fmt.Sprintf("thumb_%d_%d.jpg", time.Now().UnixNano(), int(timestamp*1000))
	thumbPath := filepath.Join(thumbDir, thumbFilename)

	ts := fmt.Sprintf("%.3f", timestamp)

	args := []string{
		"-ss", ts,
		"-i", filePath,
		"-vframes", "1",
		"-q:v", "2",
		"-y",
		thumbPath,
	}

	cmd := exec.CommandContext(ctx, cm.ffmpegPath, args...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("ffmpeg thumbnail failed: %v, stderr: %s", err, stderr.String())
	}

	// Verify the file was created
	if _, err := os.Stat(thumbPath); os.IsNotExist(err) {
		return "", fmt.Errorf("thumbnail file was not created")
	}

	logger.Infof("Generated thumbnail at %s for timestamp %.1fs", thumbPath, timestamp)
	return thumbPath, nil
}

// ExtractClip extracts a video clip from startTime to endTime.
// It updates the clip record in the database with the result.
func (cm *ClipManager) ExtractClip(ctx context.Context, clip *models.Clip, sourcePath string) error {
	if _, err := os.Stat(sourcePath); os.IsNotExist(err) {
		return fmt.Errorf("source file not found: %s", sourcePath)
	}

	// Update status to processing
	cm.db.Model(clip).Updates(map[string]interface{}{
		"status": "processing",
	})

	// Build output filename
	ext := clip.Format
	if ext == "" {
		ext = "mp4"
	}
	outFilename := fmt.Sprintf("clip_%d_%d.%s", clip.ID, time.Now().Unix(), ext)
	outPath := filepath.Join(cm.clipsDir, outFilename)

	startTS := fmt.Sprintf("%.3f", clip.StartTime)
	endTS := fmt.Sprintf("%.3f", clip.EndTime)

	var args []string

	switch ext {
	case "gif":
		// GIF output: scaled down, 10fps
		args = []string{
			"-ss", startTS,
			"-to", endTS,
			"-i", sourcePath,
			"-vf", "fps=10,scale=480:-1:flags=lanczos",
			"-y",
			outPath,
		}
	case "webm":
		// WebM output: VP9 encoding
		args = []string{
			"-ss", startTS,
			"-to", endTS,
			"-i", sourcePath,
			"-c:v", "libvpx-vp9",
			"-crf", "30",
			"-b:v", "0",
			"-c:a", "libopus",
			"-y",
			outPath,
		}
	default:
		// MP4 output: stream copy for speed, with faststart for streaming
		args = []string{
			"-ss", startTS,
			"-to", endTS,
			"-i", sourcePath,
			"-c", "copy",
			"-movflags", "+faststart",
			"-y",
			outPath,
		}
	}

	cmd := exec.CommandContext(ctx, cm.ffmpegPath, args...)
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	logger.Infof("Extracting clip %d: %s [%.1f - %.1f] -> %s", clip.ID, sourcePath, clip.StartTime, clip.EndTime, outPath)

	if err := cmd.Run(); err != nil {
		errMsg := fmt.Sprintf("ffmpeg clip extraction failed: %v, stderr: %s", err, stderr.String())
		logger.Errorf("Clip %d extraction failed: %s", clip.ID, errMsg)

		// Truncate error message for DB storage
		if len(errMsg) > 2000 {
			errMsg = errMsg[:2000]
		}

		cm.db.Model(clip).Updates(map[string]interface{}{
			"status": "failed",
			"error":  errMsg,
		})
		return fmt.Errorf("%s", errMsg)
	}

	// Get file size
	fi, err := os.Stat(outPath)
	if err != nil {
		errMsg := fmt.Sprintf("clip file not found after extraction: %v", err)
		cm.db.Model(clip).Updates(map[string]interface{}{
			"status": "failed",
			"error":  errMsg,
		})
		return fmt.Errorf("%s", errMsg)
	}

	// Update clip record with results
	duration := clip.EndTime - clip.StartTime
	cm.db.Model(clip).Updates(map[string]interface{}{
		"status":    "ready",
		"file_path": outPath,
		"file_size": fi.Size(),
		"duration":  duration,
		"error":     "",
	})

	logger.Infof("Clip %d extraction complete: %s (%.1f MB)", clip.ID, outPath, float64(fi.Size())/(1024*1024))
	return nil
}

// GetSourcePath resolves the source file path from a bookmark or clip's references.
// It checks FileID (DVRFile), RecordingID (legacy Recording), and MediaItemID (library media) in order.
func (cm *ClipManager) GetSourcePath(fileID, recordingID, mediaItemID *uint) (string, error) {
	// Try DVRFile first
	if fileID != nil && *fileID > 0 {
		var file models.DVRFile
		if err := cm.db.First(&file, *fileID).Error; err != nil {
			return "", fmt.Errorf("DVR file %d not found: %w", *fileID, err)
		}
		if file.FilePath == "" {
			return "", fmt.Errorf("DVR file %d has no file path", *fileID)
		}
		return file.FilePath, nil
	}

	// Try legacy Recording
	if recordingID != nil && *recordingID > 0 {
		var recording models.Recording
		if err := cm.db.First(&recording, *recordingID).Error; err != nil {
			return "", fmt.Errorf("recording %d not found: %w", *recordingID, err)
		}
		if recording.FilePath == "" {
			return "", fmt.Errorf("recording %d has no file path", *recordingID)
		}
		return recording.FilePath, nil
	}

	// Try MediaItem -> MediaFile
	if mediaItemID != nil && *mediaItemID > 0 {
		var mediaFile models.MediaFile
		if err := cm.db.Where("media_item_id = ?", *mediaItemID).First(&mediaFile).Error; err != nil {
			return "", fmt.Errorf("media file for item %d not found: %w", *mediaItemID, err)
		}
		if mediaFile.FilePath == "" {
			return "", fmt.Errorf("media file for item %d has no file path", *mediaItemID)
		}
		return mediaFile.FilePath, nil
	}

	return "", fmt.Errorf("no source reference provided (fileId, recordingId, or mediaItemId required)")
}
