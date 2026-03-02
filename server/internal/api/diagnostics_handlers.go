package api

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Health Check / Troubleshooting ============

// HealthCheckResult represents a single health check result
type HealthCheckResult struct {
	Name    string `json:"name"`
	Status  string `json:"status"` // "ok", "warning", "error"
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

// HealthCheckResponse is the full response for the health check endpoint
type HealthCheckResponse struct {
	Timestamp string              `json:"timestamp"`
	Duration  string              `json:"duration"`
	Summary   string              `json:"summary"`
	Checks    []HealthCheckResult `json:"checks"`
}

// runHealthChecks executes all health checks concurrently
// GET /api/diagnostics/health-check
func (s *Server) runHealthChecks(c *gin.Context) {
	start := time.Now()

	checks := make([]HealthCheckResult, 14)
	var wg sync.WaitGroup
	wg.Add(14)

	// 1. DNS
	go func() {
		defer wg.Done()
		checks[0] = s.checkDNS()
	}()

	// 2. Internet Connectivity
	go func() {
		defer wg.Done()
		checks[1] = s.checkInternet()
	}()

	// 3. Local Time
	go func() {
		defer wg.Done()
		checks[2] = s.checkLocalTime()
	}()

	// 4. Chrome/Browser
	go func() {
		defer wg.Done()
		checks[3] = s.checkChrome()
	}()

	// 5. FFmpeg
	go func() {
		defer wg.Done()
		checks[4] = s.checkFFmpeg()
	}()

	// 6. Comskip
	go func() {
		defer wg.Done()
		checks[5] = s.checkComskip()
	}()

	// 7. Guide Provider
	go func() {
		defer wg.Done()
		checks[6] = s.checkGuideProvider()
	}()

	// 8. Network Interfaces
	go func() {
		defer wg.Done()
		checks[7] = s.checkNetworkInterfaces()
	}()

	// 9. Remote Access
	go func() {
		defer wg.Done()
		checks[8] = s.checkRemoteAccess()
	}()

	// 10. Recording Directory
	go func() {
		defer wg.Done()
		checks[9] = s.checkRecordingDirectory()
	}()

	// 11. Disk Permissions
	go func() {
		defer wg.Done()
		checks[10] = s.checkDiskPermissions()
	}()

	// 12. Disk Space
	go func() {
		defer wg.Done()
		checks[11] = s.checkDiskSpace()
	}()

	// 13. Database
	go func() {
		defer wg.Done()
		checks[12] = s.checkDatabase()
	}()

	// 14. DVR Status
	go func() {
		defer wg.Done()
		checks[13] = s.checkDVRStatus()
	}()

	wg.Wait()

	duration := time.Since(start)

	// Compute summary
	errorCount := 0
	warningCount := 0
	for _, ch := range checks {
		switch ch.Status {
		case "error":
			errorCount++
		case "warning":
			warningCount++
		}
	}

	summary := "All systems operational"
	if errorCount > 0 {
		summary = fmt.Sprintf("%d error(s) detected", errorCount)
	} else if warningCount > 0 {
		summary = fmt.Sprintf("%d warning(s) detected", warningCount)
	}

	c.JSON(http.StatusOK, HealthCheckResponse{
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Duration:  duration.String(),
		Summary:   summary,
		Checks:    checks,
	})
}

func (s *Server) checkDNS() HealthCheckResult {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	resolver := &net.Resolver{}
	addrs, err := resolver.LookupHost(ctx, "dns.google")
	if err != nil {
		return HealthCheckResult{
			Name:    "DNS",
			Status:  "error",
			Message: "DNS resolution failed",
			Details: err.Error(),
		}
	}
	return HealthCheckResult{
		Name:    "DNS",
		Status:  "ok",
		Message: "DNS resolution working",
		Details: fmt.Sprintf("Resolved dns.google to %s", strings.Join(addrs, ", ")),
	}
}

func (s *Server) checkInternet() HealthCheckResult {
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get("https://www.google.com/generate_204")
	if err != nil {
		return HealthCheckResult{
			Name:    "Internet Connectivity",
			Status:  "error",
			Message: "Cannot reach the internet",
			Details: err.Error(),
		}
	}
	resp.Body.Close()

	if resp.StatusCode == 204 || resp.StatusCode == 200 {
		return HealthCheckResult{
			Name:    "Internet Connectivity",
			Status:  "ok",
			Message: "Internet connection is working",
		}
	}
	return HealthCheckResult{
		Name:    "Internet Connectivity",
		Status:  "warning",
		Message: fmt.Sprintf("Unexpected response status: %d", resp.StatusCode),
	}
}

func (s *Server) checkLocalTime() HealthCheckResult {
	now := time.Now()
	tz := now.Location().String()

	if tz == "" || tz == "Local" {
		return HealthCheckResult{
			Name:    "Local Time",
			Status:  "warning",
			Message: "Timezone is set to 'Local' - consider setting TZ explicitly",
			Details: fmt.Sprintf("Current time: %s", now.Format(time.RFC3339)),
		}
	}

	return HealthCheckResult{
		Name:    "Local Time",
		Status:  "ok",
		Message: fmt.Sprintf("System clock OK, timezone: %s", tz),
		Details: fmt.Sprintf("Current time: %s", now.Format(time.RFC3339)),
	}
}

func (s *Server) checkChrome() HealthCheckResult {
	// Try common Chrome/Chromium binary names
	binaries := []string{"google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "chrome"}
	for _, bin := range binaries {
		path, err := exec.LookPath(bin)
		if err != nil {
			continue
		}
		// Get version
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		out, err := exec.CommandContext(ctx, path, "--version").CombinedOutput()
		cancel()
		version := strings.TrimSpace(string(out))
		if err != nil {
			version = "unknown"
		}
		return HealthCheckResult{
			Name:    "Chrome/Browser",
			Status:  "ok",
			Message: "Chrome is available",
			Details: fmt.Sprintf("Path: %s, Version: %s", path, version),
		}
	}
	return HealthCheckResult{
		Name:    "Chrome/Browser",
		Status:  "warning",
		Message: "Chrome/Chromium not found - EPG scraping may not work",
		Details: "Looked for: " + strings.Join(binaries, ", "),
	}
}

func (s *Server) checkFFmpeg() HealthCheckResult {
	ffmpegPath := s.config.Transcode.FFmpegPath
	if ffmpegPath == "" {
		ffmpegPath = "ffmpeg"
	}
	path, err := exec.LookPath(ffmpegPath)
	if err != nil {
		return HealthCheckResult{
			Name:    "FFmpeg",
			Status:  "error",
			Message: "FFmpeg not found",
			Details: fmt.Sprintf("Looked for: %s", ffmpegPath),
		}
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	out, err := exec.CommandContext(ctx, path, "-version").CombinedOutput()
	cancel()
	version := "unknown"
	if err == nil {
		lines := strings.Split(string(out), "\n")
		if len(lines) > 0 {
			version = strings.TrimSpace(lines[0])
		}
	}
	return HealthCheckResult{
		Name:    "FFmpeg",
		Status:  "ok",
		Message: "FFmpeg is available",
		Details: version,
	}
}

func (s *Server) checkComskip() HealthCheckResult {
	comskipPath := s.config.DVR.ComskipPath
	if comskipPath == "" {
		comskipPath = "comskip"
	}
	path, err := exec.LookPath(comskipPath)
	if err != nil {
		return HealthCheckResult{
			Name:    "Comskip",
			Status:  "warning",
			Message: "Comskip not found - commercial detection unavailable",
			Details: fmt.Sprintf("Looked for: %s", comskipPath),
		}
	}
	return HealthCheckResult{
		Name:    "Comskip",
		Status:  "ok",
		Message: "Comskip is available",
		Details: fmt.Sprintf("Path: %s", path),
	}
}

func (s *Server) checkGuideProvider() HealthCheckResult {
	// Check if any EPG sources exist
	var count int64
	s.db.Model(&models.EPGSource{}).Count(&count)
	if count == 0 {
		return HealthCheckResult{
			Name:    "Guide Provider",
			Status:  "warning",
			Message: "No EPG sources configured",
			Details: "Add an EPG source in Settings to get program guide data",
		}
	}

	// Check if we have recent program data
	var programCount int64
	now := time.Now()
	s.db.Model(&models.Program{}).Where("end_time > ?", now).Count(&programCount)
	if programCount == 0 {
		return HealthCheckResult{
			Name:    "Guide Provider",
			Status:  "warning",
			Message: fmt.Sprintf("%d EPG source(s) configured but no upcoming program data", count),
			Details: "Try refreshing the EPG data",
		}
	}

	return HealthCheckResult{
		Name:    "Guide Provider",
		Status:  "ok",
		Message: fmt.Sprintf("%d EPG source(s) with %d upcoming programs", count, programCount),
	}
}

func (s *Server) checkNetworkInterfaces() HealthCheckResult {
	ifaces, err := net.Interfaces()
	if err != nil {
		return HealthCheckResult{
			Name:    "Network Interfaces",
			Status:  "error",
			Message: "Failed to list network interfaces",
			Details: err.Error(),
		}
	}

	var details []string
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}
		addrStrs := make([]string, 0, len(addrs))
		for _, addr := range addrs {
			addrStrs = append(addrStrs, addr.String())
		}
		if len(addrStrs) > 0 {
			details = append(details, fmt.Sprintf("%s: %s", iface.Name, strings.Join(addrStrs, ", ")))
		}
	}

	if len(details) == 0 {
		return HealthCheckResult{
			Name:    "Network Interfaces",
			Status:  "warning",
			Message: "No active network interfaces found",
		}
	}

	return HealthCheckResult{
		Name:    "Network Interfaces",
		Status:  "ok",
		Message: fmt.Sprintf("%d active interface(s)", len(details)),
		Details: strings.Join(details, "; "),
	}
}

func (s *Server) checkRemoteAccess() HealthCheckResult {
	if s.remoteAccess == nil {
		return HealthCheckResult{
			Name:    "Remote Access",
			Status:  "warning",
			Message: "Remote access manager not initialized",
		}
	}

	status := s.remoteAccess.GetStatus()
	if !status.Enabled {
		return HealthCheckResult{
			Name:    "Remote Access",
			Status:  "warning",
			Message: "Remote access is not enabled",
			Details: "Enable Tailscale for secure remote access",
		}
	}

	if status.Status == "connected" {
		return HealthCheckResult{
			Name:    "Remote Access",
			Status:  "ok",
			Message: "Remote access is connected",
			Details: fmt.Sprintf("Tailscale IP: %s, URL: %s", status.TailscaleIP, status.TailscaleURL),
		}
	}

	return HealthCheckResult{
		Name:    "Remote Access",
		Status:  "warning",
		Message: fmt.Sprintf("Remote access enabled but status: %s", status.Status),
		Details: status.Error,
	}
}

func (s *Server) checkRecordingDirectory() HealthCheckResult {
	dir := s.config.DVR.RecordingDir
	if dir == "" {
		return HealthCheckResult{
			Name:    "Recording Directory",
			Status:  "warning",
			Message: "No recording directory configured",
		}
	}

	info, err := os.Stat(dir)
	if os.IsNotExist(err) {
		// Try to create it
		if mkErr := os.MkdirAll(dir, 0755); mkErr != nil {
			return HealthCheckResult{
				Name:    "Recording Directory",
				Status:  "error",
				Message: "Recording directory does not exist and cannot be created",
				Details: fmt.Sprintf("Path: %s, Error: %s", dir, mkErr.Error()),
			}
		}
		return HealthCheckResult{
			Name:    "Recording Directory",
			Status:  "ok",
			Message: "Recording directory created successfully",
			Details: fmt.Sprintf("Path: %s", dir),
		}
	}
	if err != nil {
		return HealthCheckResult{
			Name:    "Recording Directory",
			Status:  "error",
			Message: "Cannot access recording directory",
			Details: fmt.Sprintf("Path: %s, Error: %s", dir, err.Error()),
		}
	}
	if !info.IsDir() {
		return HealthCheckResult{
			Name:    "Recording Directory",
			Status:  "error",
			Message: "Recording path exists but is not a directory",
			Details: fmt.Sprintf("Path: %s", dir),
		}
	}

	// Test write
	testFile := filepath.Join(dir, ".openflix_write_test")
	if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
		return HealthCheckResult{
			Name:    "Recording Directory",
			Status:  "error",
			Message: "Recording directory is not writable",
			Details: fmt.Sprintf("Path: %s, Error: %s", dir, err.Error()),
		}
	}
	os.Remove(testFile)

	return HealthCheckResult{
		Name:    "Recording Directory",
		Status:  "ok",
		Message: "Recording directory exists and is writable",
		Details: fmt.Sprintf("Path: %s", dir),
	}
}

func (s *Server) checkDiskPermissions() HealthCheckResult {
	dataDir := s.config.GetDataDir()
	dirs := map[string]string{
		"Data":      dataDir,
		"Transcode": s.config.Transcode.TempDir,
	}

	var errors []string
	var ok []string
	for label, dir := range dirs {
		if dir == "" {
			continue
		}
		testFile := filepath.Join(dir, ".openflix_perm_test")
		if err := os.MkdirAll(dir, 0755); err != nil {
			errors = append(errors, fmt.Sprintf("%s (%s): cannot create directory - %s", label, dir, err.Error()))
			continue
		}
		if err := os.WriteFile(testFile, []byte("test"), 0644); err != nil {
			errors = append(errors, fmt.Sprintf("%s (%s): not writable - %s", label, dir, err.Error()))
			continue
		}
		os.Remove(testFile)
		ok = append(ok, fmt.Sprintf("%s (%s)", label, dir))
	}

	if len(errors) > 0 {
		return HealthCheckResult{
			Name:    "Disk Permissions",
			Status:  "error",
			Message: fmt.Sprintf("%d directory permission error(s)", len(errors)),
			Details: strings.Join(errors, "; "),
		}
	}

	return HealthCheckResult{
		Name:    "Disk Permissions",
		Status:  "ok",
		Message: "All directories are writable",
		Details: strings.Join(ok, "; "),
	}
}

func (s *Server) checkDiskSpace() HealthCheckResult {
	dataDir := s.config.GetDataDir()
	recDir := s.config.DVR.RecordingDir

	dirs := map[string]string{
		"Data": dataDir,
	}
	if recDir != "" && recDir != dataDir {
		dirs["Recordings"] = recDir
	}

	var details []string
	status := "ok"
	for label, dir := range dirs {
		usage, err := getDiskUsage(dir)
		if err != nil {
			details = append(details, fmt.Sprintf("%s: unable to check (%s)", label, err.Error()))
			continue
		}
		pctUsed := 0.0
		if usage.Total > 0 {
			pctUsed = float64(usage.Used) / float64(usage.Total) * 100
		}
		freeGB := float64(usage.Free) / (1024 * 1024 * 1024)
		details = append(details, fmt.Sprintf("%s: %.1f GB free (%.0f%% used)", label, freeGB, pctUsed))

		if freeGB < 1.0 {
			status = "error"
		} else if freeGB < 5.0 && status != "error" {
			status = "warning"
		}
	}

	msg := "Sufficient disk space available"
	if status == "error" {
		msg = "Critically low disk space"
	} else if status == "warning" {
		msg = "Disk space is running low"
	}

	return HealthCheckResult{
		Name:    "Disk Space",
		Status:  status,
		Message: msg,
		Details: strings.Join(details, "; "),
	}
}

func (s *Server) checkDatabase() HealthCheckResult {
	sqlDB, err := s.db.DB()
	if err != nil {
		return HealthCheckResult{
			Name:    "Database",
			Status:  "error",
			Message: "Cannot get database connection",
			Details: err.Error(),
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	if err := sqlDB.PingContext(ctx); err != nil {
		return HealthCheckResult{
			Name:    "Database",
			Status:  "error",
			Message: "Database ping failed",
			Details: err.Error(),
		}
	}

	// Get database file size
	dbPath := s.config.Database.DSN
	var sizeDetail string
	if info, err := os.Stat(dbPath); err == nil {
		sizeMB := float64(info.Size()) / (1024 * 1024)
		sizeDetail = fmt.Sprintf("Size: %.1f MB", sizeMB)
	}

	return HealthCheckResult{
		Name:    "Database",
		Status:  "ok",
		Message: "Database is accessible and responsive",
		Details: sizeDetail,
	}
}

func (s *Server) checkDVRStatus() HealthCheckResult {
	if !s.config.DVR.Enabled {
		return HealthCheckResult{
			Name:    "DVR Status",
			Status:  "warning",
			Message: "DVR is disabled in configuration",
		}
	}

	if s.recorder == nil {
		return HealthCheckResult{
			Name:    "DVR Status",
			Status:  "error",
			Message: "DVR is enabled but recorder failed to initialize",
		}
	}

	var activeCount int64
	s.db.Model(&models.Recording{}).Where("status = ?", "recording").Count(&activeCount)

	var scheduledCount int64
	s.db.Model(&models.Recording{}).Where("status = ?", "scheduled").Count(&scheduledCount)

	details := fmt.Sprintf("%d active, %d scheduled", activeCount, scheduledCount)

	return HealthCheckResult{
		Name:    "DVR Status",
		Status:  "ok",
		Message: "DVR service is running",
		Details: details,
	}
}

// ============ System Status ============

// SystemStatusResponse is the full response for the system status endpoint
type SystemStatusResponse struct {
	Server     SystemStatusServer     `json:"server"`
	Resources  SystemStatusResources  `json:"resources"`
	Database   SystemStatusDatabase   `json:"database"`
	Components SystemStatusComponents `json:"components"`
}

type SystemStatusServer struct {
	Version  string `json:"version"`
	Uptime   string `json:"uptime"`
	UptimeSec int64  `json:"uptimeSec"`
	StartedAt string `json:"startedAt"`
	OS        string `json:"os"`
	Arch      string `json:"arch"`
	GoVersion string `json:"goVersion"`
	Hostname  string `json:"hostname"`
}

type DiskUsageInfo struct {
	Path    string  `json:"path"`
	Label   string  `json:"label"`
	Total   uint64  `json:"total"`
	Used    uint64  `json:"used"`
	Free    uint64  `json:"free"`
	Percent float64 `json:"percent"`
}

type SystemStatusResources struct {
	CPUCores    int             `json:"cpuCores"`
	MemUsedMB   uint64          `json:"memUsedMB"`
	MemTotalMB  uint64          `json:"memTotalMB"`
	MemPercent  float64         `json:"memPercent"`
	Goroutines  int             `json:"goroutines"`
	DiskUsage   []DiskUsageInfo `json:"diskUsage"`
}

type SystemStatusDatabase struct {
	SizeMB      float64 `json:"sizeMB"`
	Libraries   int64   `json:"libraries"`
	Channels    int64   `json:"channels"`
	Recordings  int64   `json:"recordings"`
	Passes      int64   `json:"passes"`
	Users       int64   `json:"users"`
	MediaItems  int64   `json:"mediaItems"`
	Programs    int64   `json:"programs"`
}

type SystemStatusComponents struct {
	FFmpegVersion  string `json:"ffmpegVersion"`
	ChromeVersion  string `json:"chromeVersion"`
	ComskipAvail   bool   `json:"comskipAvailable"`
	TranscodeHW    string `json:"transcodeHW"`
}

// getSystemStatus returns detailed system status information
// GET /api/system/status
func (s *Server) getSystemStatus(c *gin.Context) {
	hostname, _ := os.Hostname()

	// Server info
	uptime := time.Since(serverStartTime)
	server := SystemStatusServer{
		Version:   serverVersion,
		Uptime:    formatUptimeDuration(uptime),
		UptimeSec: int64(uptime.Seconds()),
		StartedAt: serverStartTime.UTC().Format(time.RFC3339),
		OS:        runtime.GOOS,
		Arch:      runtime.GOARCH,
		GoVersion: runtime.Version(),
		Hostname:  hostname,
	}

	// Resources
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	memUsedMB := m.Alloc / 1024 / 1024
	memTotalMB := m.Sys / 1024 / 1024
	memPercent := 0.0
	if memTotalMB > 0 {
		memPercent = float64(memUsedMB) / float64(memTotalMB) * 100
	}

	// Disk usage for relevant directories
	var diskUsage []DiskUsageInfo
	diskDirs := map[string]string{
		"Data":       s.config.GetDataDir(),
		"Recordings": s.config.DVR.RecordingDir,
		"Transcode":  s.config.Transcode.TempDir,
	}
	// Deduplicate paths
	seen := map[string]bool{}
	for label, dir := range diskDirs {
		if dir == "" || seen[dir] {
			continue
		}
		seen[dir] = true
		usage, err := getDiskUsage(dir)
		if err != nil {
			continue
		}
		pct := 0.0
		if usage.Total > 0 {
			pct = float64(usage.Used) / float64(usage.Total) * 100
		}
		diskUsage = append(diskUsage, DiskUsageInfo{
			Path:    dir,
			Label:   label,
			Total:   usage.Total,
			Used:    usage.Used,
			Free:    usage.Free,
			Percent: pct,
		})
	}

	resources := SystemStatusResources{
		CPUCores:   runtime.NumCPU(),
		MemUsedMB:  memUsedMB,
		MemTotalMB: memTotalMB,
		MemPercent: memPercent,
		Goroutines: runtime.NumGoroutine(),
		DiskUsage:  diskUsage,
	}

	// Database stats
	var libraryCount, channelCount, recordingCount, passCount, userCount, mediaItemCount, programCount int64
	s.db.Model(&models.Library{}).Count(&libraryCount)
	s.db.Model(&models.Channel{}).Count(&channelCount)
	s.db.Model(&models.Recording{}).Count(&recordingCount)
	s.db.Model(&models.SeriesRule{}).Count(&passCount)
	s.db.Model(&models.User{}).Count(&userCount)
	s.db.Model(&models.MediaItem{}).Count(&mediaItemCount)
	s.db.Model(&models.Program{}).Count(&programCount)

	dbSizeMB := 0.0
	if info, err := os.Stat(s.config.Database.DSN); err == nil {
		dbSizeMB = float64(info.Size()) / (1024 * 1024)
	}

	database := SystemStatusDatabase{
		SizeMB:     dbSizeMB,
		Libraries:  libraryCount,
		Channels:   channelCount,
		Recordings: recordingCount,
		Passes:     passCount,
		Users:      userCount,
		MediaItems: mediaItemCount,
		Programs:   programCount,
	}

	// Components
	ffmpegVersion := getCommandVersion(s.config.Transcode.FFmpegPath, "-version")
	chromeVersion := getChromeVersion()

	comskipPath := s.config.DVR.ComskipPath
	if comskipPath == "" {
		comskipPath = "comskip"
	}
	_, comskipErr := exec.LookPath(comskipPath)

	hwAccel := "none"
	if s.transcoder != nil {
		hwAccel = s.transcoder.GetHardwareAccel()
	}

	components := SystemStatusComponents{
		FFmpegVersion: ffmpegVersion,
		ChromeVersion: chromeVersion,
		ComskipAvail:  comskipErr == nil,
		TranscodeHW:   hwAccel,
	}

	c.JSON(http.StatusOK, SystemStatusResponse{
		Server:     server,
		Resources:  resources,
		Database:   database,
		Components: components,
	})
}

// ============ Helpers ============

func formatUptimeDuration(d time.Duration) string {
	days := int(d.Hours()) / 24
	hours := int(d.Hours()) % 24
	minutes := int(d.Minutes()) % 60

	if days > 0 {
		return fmt.Sprintf("%dd %dh %dm", days, hours, minutes)
	}
	if hours > 0 {
		return fmt.Sprintf("%dh %dm", hours, minutes)
	}
	return fmt.Sprintf("%dm", minutes)
}

func getCommandVersion(binPath string, flag string) string {
	if binPath == "" {
		binPath = "ffmpeg"
	}
	path, err := exec.LookPath(binPath)
	if err != nil {
		return "not found"
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	out, err := exec.CommandContext(ctx, path, flag).CombinedOutput()
	if err != nil {
		return "error"
	}
	lines := strings.Split(string(out), "\n")
	if len(lines) > 0 {
		return strings.TrimSpace(lines[0])
	}
	return "unknown"
}

func getChromeVersion() string {
	binaries := []string{"google-chrome", "google-chrome-stable", "chromium", "chromium-browser", "chrome"}
	for _, bin := range binaries {
		path, err := exec.LookPath(bin)
		if err != nil {
			continue
		}
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		out, err := exec.CommandContext(ctx, path, "--version").CombinedOutput()
		cancel()
		if err == nil {
			return strings.TrimSpace(string(out))
		}
	}
	return "not found"
}
