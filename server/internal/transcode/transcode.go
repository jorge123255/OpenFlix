package transcode

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

// Hardware acceleration types
const (
	HWAccelNone         = "none"
	HWAccelNVENC        = "nvenc"        // NVIDIA
	HWAccelQSV          = "qsv"          // Intel Quick Sync
	HWAccelVAAPI        = "vaapi"        // Linux VA-API
	HWAccelVideoToolbox = "videotoolbox" // macOS
)

// Quality presets
const (
	QualityOriginal = "original"
	Quality1080p    = "1080"
	Quality720p     = "720"
	Quality480p     = "480"
	Quality360p     = "360"
)

// Transcoder manages video transcoding sessions
type Transcoder struct {
	ffmpegPath  string
	tempDir     string
	hwAccel     string
	maxSessions int
	sessions    map[string]*Session
	mutex       sync.RWMutex
	cleanupStop chan struct{}
}

// Session represents an active transcoding session
type Session struct {
	ID         string
	FileID     uint
	FilePath   string
	OutputDir  string
	Quality    string
	Offset     int64
	Process    *exec.Cmd
	Done       chan struct{}
	Error      error
	StartTime  time.Time
	LastAccess time.Time
}

// NewTranscoder creates a new transcoder instance
func NewTranscoder(ffmpegPath, tempDir, hwAccel string, maxSessions int) *Transcoder {
	// Resolve ffmpeg path
	if ffmpegPath == "" {
		if path, err := exec.LookPath("ffmpeg"); err == nil {
			ffmpegPath = path
		} else {
			ffmpegPath = "ffmpeg"
		}
	}

	// Create temp directory
	os.MkdirAll(tempDir, 0755)

	if maxSessions <= 0 {
		maxSessions = 3
	}

	t := &Transcoder{
		ffmpegPath:  ffmpegPath,
		tempDir:     tempDir,
		hwAccel:     hwAccel,
		maxSessions: maxSessions,
		sessions:    make(map[string]*Session),
		cleanupStop: make(chan struct{}),
	}

	// Start cleanup goroutine
	go t.cleanupLoop()

	return t
}

// DetectHardwareAccel detects available hardware acceleration
func DetectHardwareAccel(ffmpegPath string) string {
	if ffmpegPath == "" {
		ffmpegPath = "ffmpeg"
	}

	// Get available encoders
	cmd := exec.Command(ffmpegPath, "-hide_banner", "-encoders")
	output, err := cmd.Output()
	if err != nil {
		return HWAccelNone
	}

	encoders := string(output)

	// Detect actual hardware present
	hasNvidiaHW := detectNvidiaHardware()
	hasIntelHW := detectIntelHardware()
	hasAMDHW := detectAMDHardware()

	// Check platform-specific hardware encoders
	switch runtime.GOOS {
	case "darwin":
		// macOS - check for VideoToolbox
		if strings.Contains(encoders, "h264_videotoolbox") {
			return HWAccelVideoToolbox
		}
	case "linux":
		// Linux - check NVIDIA first (requires actual hardware)
		if hasNvidiaHW && strings.Contains(encoders, "h264_nvenc") {
			return HWAccelNVENC
		}
		// Intel QSV (requires actual Intel hardware)
		if hasIntelHW && strings.Contains(encoders, "h264_qsv") {
			return HWAccelQSV
		}
		// AMD/Generic VA-API
		if (hasAMDHW || detectVAAPIAvailable()) && strings.Contains(encoders, "h264_vaapi") {
			return HWAccelVAAPI
		}
	case "windows":
		// Windows - check NVIDIA first (requires actual hardware)
		if hasNvidiaHW && strings.Contains(encoders, "h264_nvenc") {
			return HWAccelNVENC
		}
		if hasIntelHW && strings.Contains(encoders, "h264_qsv") {
			return HWAccelQSV
		}
	}

	return HWAccelNone
}

// StartSession starts a new transcoding session
func (t *Transcoder) StartSession(fileID uint, filePath string, offset int64, quality string) (*Session, error) {
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

	t.sessions[sessionID] = session
	t.mutex.Unlock()

	// Start transcoding in background
	go t.runTranscode(session)

	return session, nil
}

// GetSession returns a session by ID
func (t *Transcoder) GetSession(sessionID string) *Session {
	t.mutex.RLock()
	defer t.mutex.RUnlock()
	return t.sessions[sessionID]
}

// UpdateLastAccess updates the last access time for a session
func (t *Transcoder) UpdateLastAccess(sessionID string) {
	t.mutex.Lock()
	defer t.mutex.Unlock()
	if session, exists := t.sessions[sessionID]; exists {
		session.LastAccess = time.Now()
	}
}

// GetPlaylistPath returns the HLS playlist path for a session
func (t *Transcoder) GetPlaylistPath(sessionID string) string {
	return filepath.Join(t.tempDir, sessionID, "playlist.m3u8")
}

// GetSegmentPath returns a segment file path for a session
func (t *Transcoder) GetSegmentPath(sessionID, segment string) string {
	return filepath.Join(t.tempDir, sessionID, segment)
}

// StopSession stops a transcoding session
func (t *Transcoder) StopSession(sessionID string) {
	t.mutex.Lock()
	session, exists := t.sessions[sessionID]
	if !exists {
		t.mutex.Unlock()
		return
	}
	delete(t.sessions, sessionID)
	t.mutex.Unlock()

	// Kill process
	if session.Process != nil && session.Process.Process != nil {
		session.Process.Process.Kill()
	}

	// Cleanup files
	os.RemoveAll(session.OutputDir)
}

// Stop stops the transcoder and all sessions
func (t *Transcoder) Stop() {
	close(t.cleanupStop)

	t.mutex.Lock()
	defer t.mutex.Unlock()

	for id, session := range t.sessions {
		if session.Process != nil && session.Process.Process != nil {
			session.Process.Process.Kill()
		}
		os.RemoveAll(session.OutputDir)
		delete(t.sessions, id)
	}
}

// runTranscode runs the actual FFmpeg transcoding
func (t *Transcoder) runTranscode(session *Session) {
	defer close(session.Done)

	playlistPath := filepath.Join(session.OutputDir, "playlist.m3u8")
	segmentPattern := filepath.Join(session.OutputDir, "segment%05d.ts")

	// Build FFmpeg arguments
	args := t.buildFFmpegArgs(session, playlistPath, segmentPattern)

	// Create command
	session.Process = exec.Command(t.ffmpegPath, args...)

	// Capture stderr for debugging
	session.Process.Stderr = os.Stderr

	// Run transcoding
	if err := session.Process.Run(); err != nil {
		// Check if it was killed intentionally
		select {
		case <-t.cleanupStop:
			return
		default:
			session.Error = err
		}
	}
}

// buildFFmpegArgs builds FFmpeg arguments based on settings
func (t *Transcoder) buildFFmpegArgs(session *Session, playlistPath, segmentPattern string) []string {
	args := []string{
		"-y",
		"-hide_banner",
		"-loglevel", "warning",
	}

	// Add hardware acceleration input options
	args = append(args, t.getHWAccelInputArgs()...)

	// Seek to offset if specified
	if session.Offset > 0 {
		args = append(args, "-ss", strconv.FormatInt(session.Offset/1000, 10))
	}

	// Input file
	args = append(args, "-i", session.FilePath)

	// Video encoding
	args = append(args, t.getVideoEncodingArgs(session.Quality)...)

	// Audio encoding (AAC for compatibility)
	args = append(args,
		"-c:a", "aac",
		"-b:a", "192k",
		"-ac", "2",
	)

	// HLS output options
	args = append(args,
		"-f", "hls",
		"-hls_time", "4",
		"-hls_list_size", "0",
		"-hls_segment_filename", segmentPattern,
		"-hls_flags", "independent_segments",
		playlistPath,
	)

	return args
}

// getHWAccelInputArgs returns hardware acceleration input arguments
func (t *Transcoder) getHWAccelInputArgs() []string {
	switch t.hwAccel {
	case HWAccelNVENC:
		return []string{"-hwaccel", "cuda", "-hwaccel_output_format", "cuda"}
	case HWAccelQSV:
		return []string{"-hwaccel", "qsv", "-hwaccel_output_format", "qsv"}
	case HWAccelVAAPI:
		return []string{"-hwaccel", "vaapi", "-hwaccel_output_format", "vaapi", "-vaapi_device", "/dev/dri/renderD128"}
	case HWAccelVideoToolbox:
		return []string{"-hwaccel", "videotoolbox"}
	default:
		return []string{}
	}
}

// getVideoEncodingArgs returns video encoding arguments based on quality and hw accel
func (t *Transcoder) getVideoEncodingArgs(quality string) []string {
	// Get resolution and bitrate for quality
	width, height, bitrate := getQualitySettings(quality)

	// Build video filter for scaling if needed
	var scaleFilter string
	if quality != QualityOriginal {
		scaleFilter = fmt.Sprintf("scale=%d:%d", width, height)
	}

	switch t.hwAccel {
	case HWAccelNVENC:
		args := []string{"-c:v", "h264_nvenc", "-preset", "p4", "-tune", "ll", "-b:v", bitrate}
		if scaleFilter != "" {
			args = append(args, "-vf", fmt.Sprintf("scale_cuda=%d:%d", width, height))
		}
		return args

	case HWAccelQSV:
		args := []string{"-c:v", "h264_qsv", "-preset", "faster", "-b:v", bitrate}
		if scaleFilter != "" {
			args = append(args, "-vf", fmt.Sprintf("scale_qsv=%d:%d", width, height))
		}
		return args

	case HWAccelVAAPI:
		args := []string{"-c:v", "h264_vaapi", "-b:v", bitrate}
		if scaleFilter != "" {
			args = append(args, "-vf", fmt.Sprintf("scale_vaapi=%d:%d,format=nv12|vaapi,hwupload", width, height))
		}
		return args

	case HWAccelVideoToolbox:
		args := []string{"-c:v", "h264_videotoolbox", "-b:v", bitrate, "-realtime", "true"}
		if scaleFilter != "" {
			args = append(args, "-vf", scaleFilter)
		}
		return args

	default:
		// Software encoding with libx264
		args := []string{"-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-maxrate", bitrate, "-bufsize", bitrate}
		if scaleFilter != "" {
			args = append(args, "-vf", scaleFilter)
		}
		return args
	}
}

// getQualitySettings returns width, height, and bitrate for a quality preset
func getQualitySettings(quality string) (width, height int, bitrate string) {
	switch quality {
	case Quality1080p:
		return 1920, 1080, "8M"
	case Quality720p:
		return 1280, 720, "4M"
	case Quality480p:
		return 854, 480, "2M"
	case Quality360p:
		return 640, 360, "1M"
	default: // original or unknown
		return 0, 0, "10M"
	}
}

// cleanupLoop periodically cleans up stale sessions
func (t *Transcoder) cleanupLoop() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-t.cleanupStop:
			return
		case <-ticker.C:
			t.cleanupStaleSessions()
		}
	}
}

// cleanupStaleSessions removes sessions that haven't been accessed recently
func (t *Transcoder) cleanupStaleSessions() {
	t.mutex.Lock()
	defer t.mutex.Unlock()

	staleThreshold := 5 * time.Minute
	now := time.Now()

	for id, session := range t.sessions {
		if now.Sub(session.LastAccess) > staleThreshold {
			// Kill process if running
			if session.Process != nil && session.Process.Process != nil {
				session.Process.Process.Kill()
			}
			// Remove files
			os.RemoveAll(session.OutputDir)
			delete(t.sessions, id)
			fmt.Printf("Cleaned up stale transcode session: %s\n", id)
		}
	}
}

// GetActiveSessions returns the number of active sessions
func (t *Transcoder) GetActiveSessions() int {
	t.mutex.RLock()
	defer t.mutex.RUnlock()
	return len(t.sessions)
}

// GetSessionInfo returns information about active sessions (for monitoring)
func (t *Transcoder) GetSessionInfo() []map[string]interface{} {
	t.mutex.RLock()
	defer t.mutex.RUnlock()

	info := make([]map[string]interface{}, 0, len(t.sessions))
	for _, session := range t.sessions {
		info = append(info, map[string]interface{}{
			"id":         session.ID,
			"fileId":     session.FileID,
			"quality":    session.Quality,
			"startTime":  session.StartTime,
			"lastAccess": session.LastAccess,
		})
	}
	return info
}

// HardwareInfo contains detailed hardware acceleration information
type HardwareInfo struct {
	Available       bool     `json:"available"`
	Type            string   `json:"type"`
	Name            string   `json:"name"`
	Encoders        []string `json:"encoders"`
	Decoders        []string `json:"decoders"`
	GPUInfo         string   `json:"gpuInfo,omitempty"`
	SupportsHEVC    bool     `json:"supportsHevc"`
	SupportsAV1     bool     `json:"supportsAv1"`
	MaxResolution   string   `json:"maxResolution,omitempty"`
	RecommendedMode string   `json:"recommendedMode"`
	DetectedGPUs    []string `json:"detectedGpus,omitempty"`    // GPUs detected via lspci
	MissingSupport  string   `json:"missingSupport,omitempty"` // What's missing for HW accel
}

// DetectHardwareInfo returns detailed hardware acceleration information
func DetectHardwareInfo(ffmpegPath string) *HardwareInfo {
	if ffmpegPath == "" {
		ffmpegPath = "ffmpeg"
	}

	info := &HardwareInfo{
		Available:       false,
		Type:            HWAccelNone,
		Name:            "Software (CPU)",
		Encoders:        []string{"libx264", "libx265"},
		Decoders:        []string{"h264", "hevc"},
		RecommendedMode: "direct_play",
		DetectedGPUs:    []string{},
	}

	// Get available encoders
	cmd := exec.Command(ffmpegPath, "-hide_banner", "-encoders")
	output, err := cmd.Output()
	if err != nil {
		return info
	}
	encoders := string(output)

	// Get available decoders
	cmd = exec.Command(ffmpegPath, "-hide_banner", "-decoders")
	decoderOutput, _ := cmd.Output()
	decoders := string(decoderOutput)

	// Detect actual hardware present (not just ffmpeg support)
	hasNvidiaHW := detectNvidiaHardware()
	hasIntelHW := detectIntelHardware()
	hasAMDHW := detectAMDHardware()

	// Populate detected GPUs for display
	info.DetectedGPUs = detectAllGPUs()

	// Check platform-specific hardware
	switch runtime.GOOS {
	case "darwin":
		if strings.Contains(encoders, "h264_videotoolbox") {
			info.Available = true
			info.Type = HWAccelVideoToolbox
			info.Name = "Apple VideoToolbox"
			info.Encoders = []string{"h264_videotoolbox"}
			info.Decoders = []string{"h264", "hevc"}
			info.GPUInfo = detectMacGPU()
			info.MaxResolution = "4K"
			info.RecommendedMode = "server_transcode"

			if strings.Contains(encoders, "hevc_videotoolbox") {
				info.Encoders = append(info.Encoders, "hevc_videotoolbox")
				info.SupportsHEVC = true
			}
		}

	case "linux":
		// Check NVIDIA first (requires actual NVIDIA hardware)
		if hasNvidiaHW && strings.Contains(encoders, "h264_nvenc") {
			info.Available = true
			info.Type = HWAccelNVENC
			info.Name = "NVIDIA NVENC"
			info.Encoders = []string{"h264_nvenc"}
			info.GPUInfo = detectNvidiaGPU()
			info.MaxResolution = "8K"
			info.RecommendedMode = "server_transcode"

			if strings.Contains(encoders, "hevc_nvenc") {
				info.Encoders = append(info.Encoders, "hevc_nvenc")
				info.SupportsHEVC = true
			}
			if strings.Contains(encoders, "av1_nvenc") {
				info.Encoders = append(info.Encoders, "av1_nvenc")
				info.SupportsAV1 = true
			}

			// Check NVDEC decoders
			if strings.Contains(decoders, "h264_cuvid") {
				info.Decoders = []string{"h264_cuvid", "hevc_cuvid"}
			}
		} else if hasNvidiaHW && !strings.Contains(encoders, "h264_nvenc") {
			// NVIDIA hardware detected but ffmpeg doesn't have nvenc support
			info.GPUInfo = detectNvidiaGPU()
			info.MissingSupport = "NVIDIA GPU detected but FFmpeg lacks NVENC support. Use an FFmpeg build with NVENC or nvidia/cuda Docker image."
		} else if hasIntelHW && strings.Contains(encoders, "h264_qsv") {
			// Intel Quick Sync (requires actual Intel hardware)
			info.Available = true
			info.Type = HWAccelQSV
			info.Name = "Intel Quick Sync"
			info.Encoders = []string{"h264_qsv"}
			info.GPUInfo = detectIntelGPU()
			info.MaxResolution = "4K"
			info.RecommendedMode = "server_transcode"

			if strings.Contains(encoders, "hevc_qsv") {
				info.Encoders = append(info.Encoders, "hevc_qsv")
				info.SupportsHEVC = true
			}
			if strings.Contains(encoders, "av1_qsv") {
				info.Encoders = append(info.Encoders, "av1_qsv")
				info.SupportsAV1 = true
			}

			// Check QSV decoders
			if strings.Contains(decoders, "h264_qsv") {
				info.Decoders = []string{"h264_qsv", "hevc_qsv"}
			}
		} else if hasAMDHW && strings.Contains(encoders, "h264_vaapi") {
			// AMD VA-API
			info.Available = true
			info.Type = HWAccelVAAPI
			info.Name = "AMD VA-API"
			info.Encoders = []string{"h264_vaapi"}
			info.GPUInfo = detectAMDGPU()
			info.MaxResolution = "4K"
			info.RecommendedMode = "server_transcode"

			if strings.Contains(encoders, "hevc_vaapi") {
				info.Encoders = append(info.Encoders, "hevc_vaapi")
				info.SupportsHEVC = true
			}
			if strings.Contains(encoders, "av1_vaapi") {
				info.Encoders = append(info.Encoders, "av1_vaapi")
				info.SupportsAV1 = true
			}
		} else if hasAMDHW && !strings.Contains(encoders, "h264_vaapi") {
			// AMD hardware detected but ffmpeg doesn't have vaapi support
			info.GPUInfo = detectAMDGPU()
			info.MissingSupport = "AMD GPU detected but FFmpeg lacks VA-API support. Install FFmpeg with VA-API or mount /dev/dri."
		} else if strings.Contains(encoders, "h264_vaapi") && detectVAAPIAvailable() {
			// Generic VA-API fallback
			info.Available = true
			info.Type = HWAccelVAAPI
			info.Name = "VA-API"
			info.Encoders = []string{"h264_vaapi"}
			info.GPUInfo = detectVAAPIDevice()
			info.MaxResolution = "4K"
			info.RecommendedMode = "server_transcode"

			if strings.Contains(encoders, "hevc_vaapi") {
				info.Encoders = append(info.Encoders, "hevc_vaapi")
				info.SupportsHEVC = true
			}
		}

	case "windows":
		if hasNvidiaHW && strings.Contains(encoders, "h264_nvenc") {
			info.Available = true
			info.Type = HWAccelNVENC
			info.Name = "NVIDIA NVENC"
			info.Encoders = []string{"h264_nvenc"}
			info.GPUInfo = detectNvidiaGPU()
			info.MaxResolution = "8K"
			info.RecommendedMode = "server_transcode"

			if strings.Contains(encoders, "hevc_nvenc") {
				info.Encoders = append(info.Encoders, "hevc_nvenc")
				info.SupportsHEVC = true
			}
		} else if hasIntelHW && strings.Contains(encoders, "h264_qsv") {
			info.Available = true
			info.Type = HWAccelQSV
			info.Name = "Intel Quick Sync"
			info.Encoders = []string{"h264_qsv"}
			info.GPUInfo = detectIntelGPU()
			info.MaxResolution = "4K"
			info.RecommendedMode = "server_transcode"

			if strings.Contains(encoders, "hevc_qsv") {
				info.Encoders = append(info.Encoders, "hevc_qsv")
				info.SupportsHEVC = true
			}
		}
	}

	return info
}

// detectNvidiaGPU tries to get NVIDIA GPU info
func detectNvidiaGPU() string {
	cmd := exec.Command("nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader,nounits")
	output, err := cmd.Output()
	if err != nil {
		return "NVIDIA GPU (details unavailable)"
	}
	parts := strings.Split(strings.TrimSpace(string(output)), ", ")
	if len(parts) >= 2 {
		return fmt.Sprintf("%s (%s MB VRAM)", parts[0], parts[1])
	}
	return strings.TrimSpace(string(output))
}

// detectIntelGPU tries to get Intel GPU info
func detectIntelGPU() string {
	// Try lspci on Linux
	cmd := exec.Command("lspci")
	output, err := cmd.Output()
	if err != nil {
		return "Intel GPU"
	}
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(strings.ToLower(line), "vga") && strings.Contains(strings.ToLower(line), "intel") {
			// Extract GPU name
			parts := strings.SplitN(line, ": ", 2)
			if len(parts) == 2 {
				return strings.TrimSpace(parts[1])
			}
		}
	}
	return "Intel Integrated Graphics"
}

// detectMacGPU tries to get Mac GPU info
func detectMacGPU() string {
	cmd := exec.Command("system_profiler", "SPDisplaysDataType")
	output, err := cmd.Output()
	if err != nil {
		return "Apple GPU"
	}
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, "Chipset Model:") || strings.Contains(line, "Chip Model:") {
			parts := strings.SplitN(line, ": ", 2)
			if len(parts) == 2 {
				return strings.TrimSpace(parts[1])
			}
		}
	}
	return "Apple Silicon/GPU"
}

// detectVAAPIDevice tries to get VA-API device info
func detectVAAPIDevice() string {
	cmd := exec.Command("vainfo")
	output, err := cmd.Output()
	if err != nil {
		return "VA-API Device"
	}
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, "Driver version:") {
			return strings.TrimSpace(strings.TrimPrefix(line, "Driver version:"))
		}
	}
	return "VA-API Compatible Device"
}

// detectNvidiaHardware checks if NVIDIA GPU hardware is present
func detectNvidiaHardware() bool {
	// Try nvidia-smi first (most reliable)
	cmd := exec.Command("nvidia-smi", "-L")
	if err := cmd.Run(); err == nil {
		return true
	}

	// Fallback: check lspci for NVIDIA
	cmd = exec.Command("lspci")
	output, err := cmd.Output()
	if err != nil {
		return false
	}
	lines := strings.Split(strings.ToLower(string(output)), "\n")
	for _, line := range lines {
		if strings.Contains(line, "nvidia") && (strings.Contains(line, "vga") || strings.Contains(line, "3d")) {
			return true
		}
	}
	return false
}

// detectIntelHardware checks if Intel GPU hardware is present
func detectIntelHardware() bool {
	cmd := exec.Command("lspci")
	output, err := cmd.Output()
	if err != nil {
		return false
	}
	lines := strings.Split(strings.ToLower(string(output)), "\n")
	for _, line := range lines {
		if strings.Contains(line, "intel") && (strings.Contains(line, "vga") || strings.Contains(line, "display")) {
			return true
		}
	}
	return false
}

// detectAMDHardware checks if AMD GPU hardware is present
func detectAMDHardware() bool {
	cmd := exec.Command("lspci")
	output, err := cmd.Output()
	if err != nil {
		return false
	}
	lines := strings.Split(strings.ToLower(string(output)), "\n")
	for _, line := range lines {
		if (strings.Contains(line, "amd") || strings.Contains(line, "radeon") || strings.Contains(line, "advanced micro devices")) &&
			(strings.Contains(line, "vga") || strings.Contains(line, "display") || strings.Contains(line, "3d")) {
			return true
		}
	}
	return false
}

// detectAMDGPU tries to get AMD GPU info
func detectAMDGPU() string {
	cmd := exec.Command("lspci")
	output, err := cmd.Output()
	if err != nil {
		return "AMD GPU"
	}
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		lower := strings.ToLower(line)
		if (strings.Contains(lower, "amd") || strings.Contains(lower, "radeon") || strings.Contains(lower, "advanced micro devices")) &&
			(strings.Contains(lower, "vga") || strings.Contains(lower, "display") || strings.Contains(lower, "3d")) {
			// Extract GPU name
			parts := strings.SplitN(line, ": ", 2)
			if len(parts) == 2 {
				return strings.TrimSpace(parts[1])
			}
		}
	}
	return "AMD GPU"
}

// detectVAAPIAvailable checks if VA-API device is accessible
func detectVAAPIAvailable() bool {
	// Check if the render device exists
	if _, err := os.Stat("/dev/dri/renderD128"); err == nil {
		return true
	}
	// Try running vainfo
	cmd := exec.Command("vainfo")
	return cmd.Run() == nil
}

// detectAllGPUs returns a list of all detected GPU names
func detectAllGPUs() []string {
	var gpus []string

	cmd := exec.Command("lspci")
	output, err := cmd.Output()
	if err != nil {
		return gpus
	}

	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		lower := strings.ToLower(line)
		if strings.Contains(lower, "vga") || strings.Contains(lower, "3d") || strings.Contains(lower, "display") {
			// Extract GPU name
			parts := strings.SplitN(line, ": ", 2)
			if len(parts) == 2 {
				gpus = append(gpus, strings.TrimSpace(parts[1]))
			}
		}
	}

	return gpus
}

// GetHardwareAccel returns the current hardware acceleration type
func (t *Transcoder) GetHardwareAccel() string {
	return t.hwAccel
}
