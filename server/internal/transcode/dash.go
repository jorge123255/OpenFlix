package transcode

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

// DASHSession extends Session for DASH output
type DASHSession struct {
	*Session
	ManifestPath string
	MultiBitrate bool
}

// DASHQuality defines bitrate targets for DASH representations
type DASHQuality struct {
	Name         string
	Width        int
	Height       int
	VideoBitrate string
	AudioBitrate string
}

// DASH quality presets
var dashQualities = map[string]DASHQuality{
	Quality1080p: {Name: "1080p", Width: 1920, Height: 1080, VideoBitrate: "8M", AudioBitrate: "192k"},
	Quality720p:  {Name: "720p", Width: 1280, Height: 720, VideoBitrate: "5M", AudioBitrate: "128k"},
	Quality480p:  {Name: "480p", Width: 854, Height: 480, VideoBitrate: "2500k", AudioBitrate: "128k"},
	Quality360p:  {Name: "360p", Width: 640, Height: 360, VideoBitrate: "1M", AudioBitrate: "96k"},
}

// StartDASH begins a DASH transcoding session for a single quality level
func (t *Transcoder) StartDASH(fileID uint, filePath, quality string, offset int64) (*DASHSession, error) {
	t.mutex.Lock()

	// Check max sessions
	if len(t.sessions) >= t.maxSessions {
		t.mutex.Unlock()
		return nil, fmt.Errorf("maximum number of transcode sessions reached (%d)", t.maxSessions)
	}

	// Generate session ID
	sessionID := uuid.New().String()

	// Create session output directory
	outputDir := filepath.Join(t.tempDir, sessionID)
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		t.mutex.Unlock()
		return nil, fmt.Errorf("failed to create session directory: %w", err)
	}

	session := &Session{
		ID:         sessionID,
		FileID:     fileID,
		FilePath:   filePath,
		OutputDir:  outputDir,
		Quality:    quality,
		Offset:     offset,
		Done:       make(chan struct{}),
		StartTime:  time.Now(),
		LastAccess: time.Now(),
	}

	manifestPath := filepath.Join(outputDir, "manifest.mpd")

	dashSession := &DASHSession{
		Session:      session,
		ManifestPath: manifestPath,
		MultiBitrate: false,
	}

	t.sessions[sessionID] = session
	t.mutex.Unlock()

	// Start transcoding in background
	go t.runDASHTranscode(dashSession)

	return dashSession, nil
}

// StartMultiBitrateDASH creates a multi-bitrate DASH stream with multiple representations.
// This is the key advantage of DASH over HLS: adaptive bitrate in a single manifest.
// Creates representations for 360p, 480p, 720p, and 1080p (based on source resolution).
func (t *Transcoder) StartMultiBitrateDASH(fileID uint, filePath string, offset int64) (*DASHSession, error) {
	t.mutex.Lock()

	if len(t.sessions) >= t.maxSessions {
		t.mutex.Unlock()
		return nil, fmt.Errorf("maximum number of transcode sessions reached (%d)", t.maxSessions)
	}

	sessionID := uuid.New().String()

	outputDir := filepath.Join(t.tempDir, sessionID)
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		t.mutex.Unlock()
		return nil, fmt.Errorf("failed to create session directory: %w", err)
	}

	session := &Session{
		ID:         sessionID,
		FileID:     fileID,
		FilePath:   filePath,
		OutputDir:  outputDir,
		Quality:    "auto",
		Offset:     offset,
		Done:       make(chan struct{}),
		StartTime:  time.Now(),
		LastAccess: time.Now(),
	}

	manifestPath := filepath.Join(outputDir, "manifest.mpd")

	dashSession := &DASHSession{
		Session:      session,
		ManifestPath: manifestPath,
		MultiBitrate: true,
	}

	t.sessions[sessionID] = session
	t.mutex.Unlock()

	go t.runMultiBitrateDASHTranscode(dashSession)

	return dashSession, nil
}

// GenerateMPD returns the MPD manifest content for a session
func (t *Transcoder) GenerateMPD(sessionID string) ([]byte, error) {
	t.mutex.RLock()
	session, exists := t.sessions[sessionID]
	t.mutex.RUnlock()

	if !exists {
		return nil, fmt.Errorf("session not found: %s", sessionID)
	}

	manifestPath := filepath.Join(session.OutputDir, "manifest.mpd")

	// Wait for manifest to be available (with timeout)
	timeout := time.After(30 * time.Second)
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-timeout:
			return nil, fmt.Errorf("manifest generation timed out")
		case <-ticker.C:
			if data, err := os.ReadFile(manifestPath); err == nil && len(data) > 0 {
				return data, nil
			}
		case <-session.Done:
			if session.Error != nil {
				return nil, fmt.Errorf("transcode failed: %w", session.Error)
			}
			// Final check after process completes
			if data, err := os.ReadFile(manifestPath); err == nil {
				return data, nil
			}
			return nil, fmt.Errorf("manifest not found after transcode completed")
		}
	}
}

// GetDASHSegment returns the file path of a DASH segment (init or media segment)
func (t *Transcoder) GetDASHSegment(sessionID, segmentName string) (string, error) {
	t.mutex.RLock()
	session, exists := t.sessions[sessionID]
	t.mutex.RUnlock()

	if !exists {
		return "", fmt.Errorf("session not found: %s", sessionID)
	}

	// Update last access time
	t.UpdateLastAccess(sessionID)

	// Sanitize segment name to prevent directory traversal
	segmentName = filepath.Base(segmentName)
	segmentPath := filepath.Join(session.OutputDir, segmentName)

	// Wait for segment to be available (with timeout)
	timeout := time.After(30 * time.Second)
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-timeout:
			return "", fmt.Errorf("segment not available: %s", segmentName)
		case <-ticker.C:
			if info, err := os.Stat(segmentPath); err == nil && info.Size() > 0 {
				return segmentPath, nil
			}
		case <-session.Done:
			if session.Error != nil {
				return "", fmt.Errorf("transcode failed: %w", session.Error)
			}
			// Final check
			if _, err := os.Stat(segmentPath); err == nil {
				return segmentPath, nil
			}
			return "", fmt.Errorf("segment not found: %s", segmentName)
		}
	}
}

// GetDASHManifestPath returns the MPD manifest path for a session
func (t *Transcoder) GetDASHManifestPath(sessionID string) string {
	return filepath.Join(t.tempDir, sessionID, "manifest.mpd")
}

// runDASHTranscode runs FFmpeg for single-quality DASH transcoding
func (t *Transcoder) runDASHTranscode(ds *DASHSession) {
	defer close(ds.Done)

	args := t.buildDASHFFmpegArgs(ds)

	ds.Process = exec.Command(t.ffmpegPath, args...)
	ds.Process.Stderr = os.Stderr

	if err := ds.Process.Run(); err != nil {
		select {
		case <-t.cleanupStop:
			return
		default:
			ds.Error = err
		}
	}
}

// runMultiBitrateDASHTranscode runs FFmpeg for multi-bitrate DASH transcoding
func (t *Transcoder) runMultiBitrateDASHTranscode(ds *DASHSession) {
	defer close(ds.Done)

	args := t.buildMultiBitrateDASHFFmpegArgs(ds)

	ds.Process = exec.Command(t.ffmpegPath, args...)
	ds.Process.Stderr = os.Stderr

	if err := ds.Process.Run(); err != nil {
		select {
		case <-t.cleanupStop:
			return
		default:
			ds.Error = err
		}
	}
}

// buildDASHFFmpegArgs builds FFmpeg arguments for single-quality DASH output
func (t *Transcoder) buildDASHFFmpegArgs(ds *DASHSession) []string {
	args := []string{
		"-y",
		"-hide_banner",
		"-loglevel", "warning",
	}

	// Add hardware acceleration input options
	args = append(args, t.getHWAccelInputArgs()...)

	// Seek to offset if specified
	if ds.Offset > 0 {
		args = append(args, "-ss", strconv.FormatInt(ds.Offset/1000, 10))
	}

	// Input file
	args = append(args, "-i", ds.FilePath)

	// Map streams
	args = append(args, "-map", "0:v:0", "-map", "0:a:0?")

	// Video encoding
	args = append(args, t.getDASHVideoArgs(ds.Quality)...)

	// Audio encoding
	args = append(args, t.getDASHAudioArgs(ds.Quality)...)

	// DASH output options
	args = append(args,
		"-f", "dash",
		"-seg_duration", "4",
		"-window_size", "0",
		"-use_timeline", "1",
		"-use_template", "1",
		"-init_seg_name", "init-$RepresentationID$.m4s",
		"-media_seg_name", "seg-$RepresentationID$-$Number%05d$.m4s",
		"-adaptation_sets", "id=0,streams=v id=1,streams=a",
		ds.ManifestPath,
	)

	return args
}

// buildMultiBitrateDASHFFmpegArgs builds FFmpeg arguments for multi-bitrate DASH output
func (t *Transcoder) buildMultiBitrateDASHFFmpegArgs(ds *DASHSession) []string {
	args := []string{
		"-y",
		"-hide_banner",
		"-loglevel", "warning",
	}

	// Add hardware acceleration input options (only for software encoding in multi-bitrate)
	// For HW-accelerated multi-bitrate, we skip HW accel input to avoid conflicts
	if t.hwAccel == HWAccelNone {
		// No special input args needed
	} else {
		args = append(args, t.getHWAccelInputArgs()...)
	}

	// Seek to offset if specified
	if ds.Offset > 0 {
		args = append(args, "-ss", strconv.FormatInt(ds.Offset/1000, 10))
	}

	// Input file
	args = append(args, "-i", ds.FilePath)

	// Map multiple output streams for each quality level
	// Output 0: 1080p, Output 1: 720p, Output 2: 480p, Output 3: 360p
	qualities := []string{Quality1080p, Quality720p, Quality480p, Quality360p}

	// Create map entries for each quality plus one shared audio
	for range qualities {
		args = append(args, "-map", "0:v:0")
	}
	args = append(args, "-map", "0:a:0?")

	// Build adaptation sets string
	var videoStreamIndices []string
	for i, q := range qualities {
		dq := dashQualities[q]

		// Video encoding for each output stream
		videoCodec, videoArgs := t.getDASHHWVideoCodecAndArgs(q)

		args = append(args, fmt.Sprintf("-c:v:%d", i), videoCodec)
		for _, a := range videoArgs {
			args = append(args, a)
		}
		args = append(args, fmt.Sprintf("-b:v:%d", i), dq.VideoBitrate)

		// Apply scaling filter per stream
		if t.hwAccel == HWAccelNone {
			args = append(args, fmt.Sprintf("-filter:v:%d", i),
				fmt.Sprintf("scale=%d:%d", dq.Width, dq.Height))
		} else {
			scaleFilter := t.getHWScaleFilter(dq.Width, dq.Height)
			if scaleFilter != "" {
				args = append(args, fmt.Sprintf("-filter:v:%d", i), scaleFilter)
			}
		}

		videoStreamIndices = append(videoStreamIndices, strconv.Itoa(i))
	}

	// Audio encoding (single audio stream shared across all representations)
	audioStreamIdx := len(qualities)
	args = append(args,
		fmt.Sprintf("-c:a:%d", 0), "aac",
		fmt.Sprintf("-b:a:%d", 0), "128k",
		fmt.Sprintf("-ac:%d", 0), "2",
	)

	// Build adaptation_sets
	videoStreams := strings.Join(videoStreamIndices, ",")
	adaptationSets := fmt.Sprintf("id=0,streams=%s id=1,streams=%d", videoStreams, audioStreamIdx)

	// DASH output options
	args = append(args,
		"-f", "dash",
		"-seg_duration", "4",
		"-window_size", "0",
		"-use_timeline", "1",
		"-use_template", "1",
		"-init_seg_name", "init-$RepresentationID$.m4s",
		"-media_seg_name", "seg-$RepresentationID$-$Number%05d$.m4s",
		"-adaptation_sets", adaptationSets,
		ds.ManifestPath,
	)

	return args
}

// getDASHVideoArgs returns ffmpeg video encoding arguments for DASH at a given quality
func (t *Transcoder) getDASHVideoArgs(quality string) []string {
	dq, ok := dashQualities[quality]
	if !ok {
		// Original quality: no scaling, reasonable bitrate
		switch t.hwAccel {
		case HWAccelNVENC:
			return []string{"-c:v", "h264_nvenc", "-preset", "p4", "-b:v", "10M"}
		case HWAccelQSV:
			return []string{"-c:v", "h264_qsv", "-preset", "faster", "-b:v", "10M"}
		case HWAccelVAAPI:
			return []string{"-c:v", "h264_vaapi", "-b:v", "10M"}
		case HWAccelVideoToolbox:
			return []string{"-c:v", "h264_videotoolbox", "-b:v", "10M"}
		default:
			return []string{"-c:v", "libx264", "-preset", "fast", "-crf", "23"}
		}
	}

	switch t.hwAccel {
	case HWAccelNVENC:
		return []string{
			"-c:v", "h264_nvenc",
			"-preset", "p4",
			"-b:v", dq.VideoBitrate,
			"-vf", fmt.Sprintf("scale_cuda=%d:%d", dq.Width, dq.Height),
		}
	case HWAccelQSV:
		return []string{
			"-c:v", "h264_qsv",
			"-preset", "faster",
			"-b:v", dq.VideoBitrate,
			"-vf", fmt.Sprintf("scale_qsv=%d:%d", dq.Width, dq.Height),
		}
	case HWAccelVAAPI:
		return []string{
			"-c:v", "h264_vaapi",
			"-b:v", dq.VideoBitrate,
			"-vf", fmt.Sprintf("scale_vaapi=%d:%d,format=nv12|vaapi,hwupload", dq.Width, dq.Height),
		}
	case HWAccelVideoToolbox:
		return []string{
			"-c:v", "h264_videotoolbox",
			"-b:v", dq.VideoBitrate,
			"-vf", fmt.Sprintf("scale=%d:%d", dq.Width, dq.Height),
		}
	default:
		return []string{
			"-c:v", "libx264",
			"-preset", "fast",
			"-b:v", dq.VideoBitrate,
			"-maxrate", dq.VideoBitrate,
			"-bufsize", dq.VideoBitrate,
			"-vf", fmt.Sprintf("scale=%d:%d", dq.Width, dq.Height),
		}
	}
}

// getDASHAudioArgs returns ffmpeg audio encoding arguments for DASH
func (t *Transcoder) getDASHAudioArgs(quality string) []string {
	audioBitrate := "128k"
	if dq, ok := dashQualities[quality]; ok {
		audioBitrate = dq.AudioBitrate
	}

	return []string{
		"-c:a", "aac",
		"-b:a", audioBitrate,
		"-ac", "2",
	}
}

// getDASHHWVideoCodecAndArgs returns the codec name and extra args for HW-accelerated DASH encoding.
// This is used by multi-bitrate where we need to set codec per stream.
func (t *Transcoder) getDASHHWVideoCodecAndArgs(quality string) (string, []string) {
	switch t.hwAccel {
	case HWAccelNVENC:
		return "h264_nvenc", []string{"-preset", "p4"}
	case HWAccelQSV:
		return "h264_qsv", []string{"-preset", "faster"}
	case HWAccelVAAPI:
		return "h264_vaapi", nil
	case HWAccelVideoToolbox:
		return "h264_videotoolbox", nil
	default:
		return "libx264", []string{"-preset", "fast"}
	}
}

// getHWScaleFilter returns the hardware-specific scale filter string
func (t *Transcoder) getHWScaleFilter(width, height int) string {
	switch t.hwAccel {
	case HWAccelNVENC:
		return fmt.Sprintf("scale_cuda=%d:%d", width, height)
	case HWAccelQSV:
		return fmt.Sprintf("scale_qsv=%d:%d", width, height)
	case HWAccelVAAPI:
		return fmt.Sprintf("scale_vaapi=%d:%d,format=nv12|vaapi,hwupload", width, height)
	case HWAccelVideoToolbox:
		return fmt.Sprintf("scale=%d:%d", width, height)
	default:
		return fmt.Sprintf("scale=%d:%d", width, height)
	}
}

// DASHSessionStore provides thread-safe storage for DASHSession metadata
// that the Transcoder's base session map does not hold (ManifestPath, MultiBitrate flag).
type DASHSessionStore struct {
	sessions map[string]*DASHSession
	mu       sync.RWMutex
}

// NewDASHSessionStore creates a new store for DASH session metadata
func NewDASHSessionStore() *DASHSessionStore {
	return &DASHSessionStore{
		sessions: make(map[string]*DASHSession),
	}
}

// Put stores a DASH session
func (ds *DASHSessionStore) Put(id string, session *DASHSession) {
	ds.mu.Lock()
	defer ds.mu.Unlock()
	ds.sessions[id] = session
}

// Get retrieves a DASH session
func (ds *DASHSessionStore) Get(id string) (*DASHSession, bool) {
	ds.mu.RLock()
	defer ds.mu.RUnlock()
	s, ok := ds.sessions[id]
	return s, ok
}

// Delete removes a DASH session
func (ds *DASHSessionStore) Delete(id string) {
	ds.mu.Lock()
	defer ds.mu.Unlock()
	delete(ds.sessions, id)
}
