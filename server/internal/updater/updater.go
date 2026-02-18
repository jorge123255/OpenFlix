package updater

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// AutoUpdateConfig holds the configuration for automatic background updates.
type AutoUpdateConfig struct {
	// CheckInterval is how often the auto-checker polls for updates.
	CheckInterval time.Duration `json:"check_interval"`

	// AutoApply controls whether discovered updates are automatically
	// downloaded and applied (with a restart) rather than just downloaded.
	AutoApply bool `json:"auto_apply"`

	// MaintenanceWindow restricts auto-apply to a specific hour range
	// (using 24-hour clock). A zero-value window (0,0) means no restriction.
	MaintenanceWindow MaintenanceWindow `json:"maintenance_window"`

	// LastAutoCheck records the last time the automatic checker ran.
	LastAutoCheck time.Time `json:"last_auto_check"`

	// NextScheduledCheck is the projected time of the next automatic check.
	NextScheduledCheck time.Time `json:"next_scheduled_check"`
}

// MaintenanceWindow defines a daily hour range during which auto-apply is
// permitted. StartHour and EndHour use 24-hour notation. If both are 0 the
// window is treated as disabled (auto-apply any time).
type MaintenanceWindow struct {
	StartHour int `json:"start_hour"` // 0-23
	EndHour   int `json:"end_hour"`   // 0-23
}

// UpdateInfo describes an available update fetched from the version endpoint.
type UpdateInfo struct {
	Version      string `json:"version"`
	URL          string `json:"url"`
	SHA256       string `json:"sha256"`
	ReleaseNotes string `json:"release_notes"`
	ReleaseDate  string `json:"release_date"`
}

// UpdateStatus represents the current state of the updater visible to API consumers.
type UpdateStatus struct {
	CurrentVersion  string    `json:"current_version"`
	LatestVersion   string    `json:"latest_version"`
	UpdateAvailable bool      `json:"update_available"`
	LastChecked     time.Time `json:"last_checked"`
	Downloading     bool      `json:"downloading"`
	Progress        float64   `json:"progress"` // 0.0 - 1.0
	Error           string    `json:"error,omitempty"`
}

// Config holds the updater configuration.
type Config struct {
	// CheckURL is the endpoint that returns UpdateInfo JSON.
	// Defaults to the OPENFLIX_UPDATE_URL env var, then falls back to the
	// GitHub releases latest endpoint.
	CheckURL string

	// CheckInterval controls how often the background goroutine polls for
	// updates. Zero means use the default of 6 hours.
	CheckInterval time.Duration

	// DataDir is the root directory where versioned binaries are stored
	// (e.g. ~/.openflix). A subdirectory "versions" is created underneath.
	DataDir string

	// CurrentVersion is the semver string baked into the running binary
	// at build time (e.g. "1.2.3").
	CurrentVersion string

	// BinaryName overrides the executable name used when constructing
	// download URLs and local paths. Defaults to "openflix-server".
	BinaryName string

	// MaxVersionsKept is the number of old version directories to retain
	// after a successful update. Defaults to 3.
	MaxVersionsKept int
}

// Updater implements the self-update lifecycle:
//
//	Start -> checkForUpdate -> downloadUpdate -> ApplyUpdate -> restart
type Updater struct {
	cfg Config

	mu       sync.RWMutex
	status   UpdateStatus
	stopChan chan struct{}
	running  bool

	// autoMu protects autoConfig and autoStop.
	autoMu     sync.RWMutex
	autoConfig AutoUpdateConfig
	autoStop   chan struct{}
	autoRunning bool

	// httpClient is reused across requests so callers can inject a custom
	// transport in tests.
	httpClient *http.Client
}

// defaultCheckURL is used when no URL is configured and OPENFLIX_UPDATE_URL
// is unset.
const defaultCheckURL = "https://api.github.com/repos/openflix/openflix-server/releases/latest"

// New creates an Updater with the given configuration. It does not start the
// background checker -- call Start() for that.
func New(cfg Config) *Updater {
	if cfg.CheckURL == "" {
		if envURL := os.Getenv("OPENFLIX_UPDATE_URL"); envURL != "" {
			cfg.CheckURL = envURL
		} else {
			cfg.CheckURL = defaultCheckURL
		}
	}
	if cfg.CheckInterval <= 0 {
		cfg.CheckInterval = 6 * time.Hour
	}
	if cfg.BinaryName == "" {
		cfg.BinaryName = "openflix-server"
	}
	if cfg.MaxVersionsKept <= 0 {
		cfg.MaxVersionsKept = 3
	}

	return &Updater{
		cfg: cfg,
		status: UpdateStatus{
			CurrentVersion: cfg.CurrentVersion,
		},
		stopChan: make(chan struct{}),
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// ---------------------------------------------------------------------------
// Lifecycle
// ---------------------------------------------------------------------------

// Start launches the background update-checker goroutine. It is safe to call
// multiple times; subsequent calls are no-ops while the checker is running.
func (u *Updater) Start() {
	u.mu.Lock()
	if u.running {
		u.mu.Unlock()
		return
	}
	u.running = true
	u.stopChan = make(chan struct{})
	u.mu.Unlock()

	logger.Infof("Update checker started (interval=%s, url=%s)", u.cfg.CheckInterval, u.cfg.CheckURL)

	go u.loop()
}

// Stop signals the background goroutine to exit and blocks briefly to let it
// wind down.
func (u *Updater) Stop() {
	u.mu.Lock()
	defer u.mu.Unlock()

	if !u.running {
		return
	}
	close(u.stopChan)
	u.running = false
	logger.Info("Update checker stopped")
}

// loop is the main ticker loop executed in a dedicated goroutine.
func (u *Updater) loop() {
	// Perform the first check after a short startup delay so the rest of
	// the server can finish initialising.
	select {
	case <-time.After(30 * time.Second):
		u.checkAndLog()
	case <-u.stopChan:
		return
	}

	ticker := time.NewTicker(u.cfg.CheckInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			u.checkAndLog()
		case <-u.stopChan:
			return
		}
	}
}

// checkAndLog runs a single check cycle, logging errors rather than
// propagating them (this is the fire-and-forget path used by the ticker).
func (u *Updater) checkAndLog() {
	info, err := u.CheckForUpdate()
	if err != nil {
		logger.Warnf("Update check failed: %v", err)
		u.mu.Lock()
		u.status.Error = err.Error()
		u.mu.Unlock()
		return
	}
	if info == nil {
		logger.Infof("No update available (current=%s)", u.cfg.CurrentVersion)
		return
	}

	logger.Infof("Update available: %s -> %s", u.cfg.CurrentVersion, info.Version)

	// Auto-download but do NOT auto-apply. The operator can trigger
	// ApplyUpdate via the API when they are ready for a restart.
	binPath, err := u.DownloadUpdate(*info)
	if err != nil {
		logger.Errorf("Failed to download update %s: %v", info.Version, err)
		u.mu.Lock()
		u.status.Error = fmt.Sprintf("download failed: %v", err)
		u.mu.Unlock()
		return
	}

	logger.Infof("Update %s downloaded to %s -- awaiting apply", info.Version, binPath)
}

// ---------------------------------------------------------------------------
// CheckForUpdate
// ---------------------------------------------------------------------------

// CheckForUpdate contacts the configured version endpoint and returns an
// *UpdateInfo when a newer version is available, or nil when the server is
// already up to date.
func (u *Updater) CheckForUpdate() (*UpdateInfo, error) {
	req, err := http.NewRequest(http.MethodGet, u.cfg.CheckURL, nil)
	if err != nil {
		return nil, fmt.Errorf("build request: %w", err)
	}
	req.Header.Set("User-Agent", fmt.Sprintf("OpenFlix-Server/%s", u.cfg.CurrentVersion))
	req.Header.Set("Accept", "application/json")

	resp, err := u.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("fetch update info: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("update endpoint returned HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20)) // 1 MiB limit
	if err != nil {
		return nil, fmt.Errorf("read response: %w", err)
	}

	info, err := u.parseUpdateResponse(body)
	if err != nil {
		return nil, err
	}

	now := time.Now()

	u.mu.Lock()
	u.status.LastChecked = now
	u.status.LatestVersion = info.Version
	u.status.UpdateAvailable = u.isNewer(info.Version)
	u.status.Error = ""
	u.mu.Unlock()

	if !u.isNewer(info.Version) {
		return nil, nil
	}

	return info, nil
}

// parseUpdateResponse attempts to parse the response body. It supports both a
// flat UpdateInfo object and a GitHub-style release response (tag_name,
// assets, body).
func (u *Updater) parseUpdateResponse(data []byte) (*UpdateInfo, error) {
	// First try the simple/direct format.
	var direct UpdateInfo
	if err := json.Unmarshal(data, &direct); err == nil && direct.Version != "" {
		return &direct, nil
	}

	// Fall back to GitHub Releases API format.
	var gh struct {
		TagName     string `json:"tag_name"`
		Body        string `json:"body"`
		PublishedAt string `json:"published_at"`
		Assets      []struct {
			Name               string `json:"name"`
			BrowserDownloadURL string `json:"browser_download_url"`
		} `json:"assets"`
	}
	if err := json.Unmarshal(data, &gh); err != nil {
		return nil, fmt.Errorf("parse update response: %w", err)
	}
	if gh.TagName == "" {
		return nil, errors.New("update response missing version/tag_name")
	}

	info := &UpdateInfo{
		Version:      strings.TrimPrefix(gh.TagName, "v"),
		ReleaseNotes: gh.Body,
		ReleaseDate:  gh.PublishedAt,
	}

	// Try to locate a matching binary asset for this OS/arch.
	wantSuffix := fmt.Sprintf("%s-%s", runtime.GOOS, runtime.GOARCH)
	for _, asset := range gh.Assets {
		if strings.Contains(asset.Name, wantSuffix) && !strings.HasSuffix(asset.Name, ".sha256") {
			info.URL = asset.BrowserDownloadURL
		}
		if strings.Contains(asset.Name, wantSuffix) && strings.HasSuffix(asset.Name, ".sha256") {
			// Fetch the checksum file inline (it is tiny).
			if sum, err := u.fetchChecksumFile(asset.BrowserDownloadURL); err == nil {
				info.SHA256 = sum
			}
		}
	}

	if info.URL == "" {
		return nil, fmt.Errorf("no binary asset found for %s/%s in release %s", runtime.GOOS, runtime.GOARCH, info.Version)
	}

	return info, nil
}

// fetchChecksumFile downloads a small checksum file and returns the hex digest
// (first whitespace-delimited field).
func (u *Updater) fetchChecksumFile(url string) (string, error) {
	resp, err := u.httpClient.Get(url)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if err != nil {
		return "", err
	}

	fields := strings.Fields(strings.TrimSpace(string(body)))
	if len(fields) == 0 {
		return "", errors.New("empty checksum file")
	}
	return fields[0], nil
}

// isNewer returns true when remoteVersion is strictly newer than the running
// version. Both values are expected to be semver-ish strings (e.g. "1.2.3").
// A simple lexicographic comparison is used after normalising to dotted
// segments -- this is intentionally kept dependency-free.
func (u *Updater) isNewer(remoteVersion string) bool {
	remote := strings.TrimPrefix(remoteVersion, "v")
	local := strings.TrimPrefix(u.cfg.CurrentVersion, "v")

	if remote == "" || local == "" {
		return false
	}
	if remote == local {
		return false
	}

	rp := strings.Split(remote, ".")
	lp := strings.Split(local, ".")

	// Pad to equal length.
	for len(rp) < len(lp) {
		rp = append(rp, "0")
	}
	for len(lp) < len(rp) {
		lp = append(lp, "0")
	}

	for i := range rp {
		ri := parseSegment(rp[i])
		li := parseSegment(lp[i])
		if ri > li {
			return true
		}
		if ri < li {
			return false
		}
	}
	return false
}

// parseSegment converts a version segment to an integer for comparison. Non-
// numeric suffixes (e.g. "3-beta") are stripped.
func parseSegment(s string) int {
	// Strip anything after a dash or letter.
	clean := strings.Builder{}
	for _, c := range s {
		if c >= '0' && c <= '9' {
			clean.WriteRune(c)
		} else {
			break
		}
	}
	n := 0
	for _, c := range clean.String() {
		n = n*10 + int(c-'0')
	}
	return n
}

// ---------------------------------------------------------------------------
// DownloadUpdate
// ---------------------------------------------------------------------------

// DownloadUpdate fetches the binary at info.URL, writes it to a versioned
// directory under DataDir, and verifies the SHA256 checksum when provided.
// It returns the absolute path to the downloaded binary.
func (u *Updater) DownloadUpdate(info UpdateInfo) (string, error) {
	if info.URL == "" {
		return "", errors.New("update info has no download URL")
	}

	u.mu.Lock()
	u.status.Downloading = true
	u.status.Progress = 0
	u.status.Error = ""
	u.mu.Unlock()

	defer func() {
		u.mu.Lock()
		u.status.Downloading = false
		u.mu.Unlock()
	}()

	// Prepare the versioned directory: <DataDir>/versions/<version>/
	versionDir := filepath.Join(u.cfg.DataDir, "versions", info.Version)
	if err := os.MkdirAll(versionDir, 0755); err != nil {
		return "", fmt.Errorf("create version dir: %w", err)
	}

	destPath := filepath.Join(versionDir, u.cfg.BinaryName)

	// If the file already exists and checksum matches, skip the download.
	if info.SHA256 != "" {
		if ok, _ := verifyChecksum(destPath, info.SHA256); ok {
			logger.Infof("Binary for %s already exists and checksum matches, skipping download", info.Version)
			u.mu.Lock()
			u.status.Progress = 1.0
			u.mu.Unlock()
			return destPath, nil
		}
	}

	logger.Infof("Downloading update %s from %s", info.Version, info.URL)

	req, err := http.NewRequest(http.MethodGet, info.URL, nil)
	if err != nil {
		return "", fmt.Errorf("build download request: %w", err)
	}
	req.Header.Set("User-Agent", fmt.Sprintf("OpenFlix-Server/%s", u.cfg.CurrentVersion))

	// Use a longer timeout for the download itself.
	dlClient := &http.Client{Timeout: 30 * time.Minute}
	resp, err := dlClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("download: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("download returned HTTP %d", resp.StatusCode)
	}

	totalBytes := resp.ContentLength // may be -1

	// Write to a temporary file first, then rename for atomicity.
	tmpPath := destPath + ".tmp"
	out, err := os.OpenFile(tmpPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0755)
	if err != nil {
		return "", fmt.Errorf("create temp file: %w", err)
	}

	hasher := sha256.New()
	writer := io.MultiWriter(out, hasher)

	var written int64
	buf := make([]byte, 256*1024) // 256 KiB chunks
	for {
		n, readErr := resp.Body.Read(buf)
		if n > 0 {
			if _, wErr := writer.Write(buf[:n]); wErr != nil {
				out.Close()
				os.Remove(tmpPath)
				return "", fmt.Errorf("write: %w", wErr)
			}
			written += int64(n)

			if totalBytes > 0 {
				u.mu.Lock()
				u.status.Progress = float64(written) / float64(totalBytes)
				u.mu.Unlock()
			}
		}
		if readErr != nil {
			if readErr == io.EOF {
				break
			}
			out.Close()
			os.Remove(tmpPath)
			return "", fmt.Errorf("read body: %w", readErr)
		}
	}
	out.Close()

	// Verify checksum.
	gotSum := hex.EncodeToString(hasher.Sum(nil))
	if info.SHA256 != "" {
		wantSum := strings.ToLower(strings.TrimSpace(info.SHA256))
		if gotSum != wantSum {
			os.Remove(tmpPath)
			return "", fmt.Errorf("checksum mismatch: got %s, want %s", gotSum, wantSum)
		}
		logger.Infof("SHA256 checksum verified for %s", info.Version)
	} else {
		logger.Warnf("No SHA256 checksum provided for %s, skipping verification (got %s)", info.Version, gotSum)
	}

	// Atomic rename.
	if err := os.Rename(tmpPath, destPath); err != nil {
		os.Remove(tmpPath)
		return "", fmt.Errorf("rename temp to final: %w", err)
	}

	// Ensure executable.
	if err := os.Chmod(destPath, 0755); err != nil {
		logger.Warnf("Failed to chmod downloaded binary: %v", err)
	}

	u.mu.Lock()
	u.status.Progress = 1.0
	u.mu.Unlock()

	logger.Infof("Update %s downloaded successfully (%d bytes)", info.Version, written)

	return destPath, nil
}

// verifyChecksum checks a file against an expected hex-encoded SHA256 digest.
func verifyChecksum(path, expected string) (bool, error) {
	f, err := os.Open(path)
	if err != nil {
		return false, err
	}
	defer f.Close()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return false, err
	}

	got := hex.EncodeToString(h.Sum(nil))
	return got == strings.ToLower(strings.TrimSpace(expected)), nil
}

// ---------------------------------------------------------------------------
// ApplyUpdate
// ---------------------------------------------------------------------------

// ApplyUpdate performs a symlink-swap of the running binary and then restarts
// the process. The sequence is:
//
//  1. Determine the path of the currently running executable.
//  2. If the current path is a symlink, resolve its parent directory to find
//     the "link location". Otherwise use the executable path directly.
//  3. Create a new symlink: <link location>.new -> newBinaryPath
//  4. Atomically rename <link location>.new over <link location>.
//  5. Re-exec the process (unless running inside Docker).
//
// This function does NOT return on success (the process is replaced).
func (u *Updater) ApplyUpdate(newBinaryPath string) error {
	if newBinaryPath == "" {
		return errors.New("no binary path provided")
	}

	// Sanity check: the new binary must exist and be executable.
	fi, err := os.Stat(newBinaryPath)
	if err != nil {
		return fmt.Errorf("stat new binary: %w", err)
	}
	if fi.IsDir() {
		return errors.New("new binary path is a directory")
	}
	if fi.Mode()&0111 == 0 {
		return errors.New("new binary is not executable")
	}

	currentExe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("determine running executable: %w", err)
	}
	currentExe, err = filepath.EvalSymlinks(currentExe)
	if err != nil {
		return fmt.Errorf("resolve symlinks: %w", err)
	}

	// The link target: either the running binary itself or the symlink
	// that points at it.
	linkPath := currentExe

	logger.Infof("Applying update: %s -> %s", linkPath, newBinaryPath)

	// Atomic symlink swap:
	//   1. Create linkPath.new -> newBinaryPath
	//   2. Rename linkPath.new -> linkPath
	tmpLink := linkPath + ".new"
	os.Remove(tmpLink) // ignore error; may not exist

	if err := os.Symlink(newBinaryPath, tmpLink); err != nil {
		// If symlinking is not supported (e.g. some file systems), fall
		// back to a direct copy.
		logger.Warnf("Symlink failed, falling back to copy: %v", err)
		if err := copyFile(newBinaryPath, linkPath); err != nil {
			return fmt.Errorf("copy new binary: %w", err)
		}
	} else {
		if err := os.Rename(tmpLink, linkPath); err != nil {
			os.Remove(tmpLink)
			return fmt.Errorf("atomic rename: %w", err)
		}
	}

	logger.Info("Binary replaced successfully")

	// Clean up old versions after a successful swap.
	u.CleanupOldVersions()

	// Restart unless we are inside a Docker container.
	if isDocker() {
		logger.Info("Running inside Docker, skipping automatic restart. The container should be restarted externally.")
		return nil
	}

	return u.performRestart()
}

// performRestart replaces the current process with a fresh invocation of the
// (now-updated) binary, preserving arguments and environment.
func (u *Updater) performRestart() error {
	exe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("resolve executable for restart: %w", err)
	}

	// Resolve symlinks so we exec the actual binary.
	exe, err = filepath.EvalSymlinks(exe)
	if err != nil {
		return fmt.Errorf("resolve symlink for restart: %w", err)
	}

	logger.Infof("Restarting process: %s %v", exe, os.Args[1:])

	// On Unix we can use syscall.Exec to replace the process in-place.
	// On Windows this is not available, so we spawn a new process and exit.
	if runtime.GOOS != "windows" {
		return syscall.Exec(exe, append([]string{exe}, os.Args[1:]...), os.Environ())
	}

	// Windows fallback: start a new process and exit the current one.
	cmd := exec.Command(exe, os.Args[1:]...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	cmd.Env = os.Environ()

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("start new process: %w", err)
	}

	logger.Info("New process started, exiting current process")
	os.Exit(0)
	return nil // unreachable
}

// ---------------------------------------------------------------------------
// CleanupOldVersions
// ---------------------------------------------------------------------------

// CleanupOldVersions removes version directories older than the most recent
// MaxVersionsKept, excluding the currently running version.
func (u *Updater) CleanupOldVersions() {
	versionsDir := filepath.Join(u.cfg.DataDir, "versions")

	entries, err := os.ReadDir(versionsDir)
	if err != nil {
		logger.Warnf("Failed to read versions directory for cleanup: %v", err)
		return
	}

	type versionEntry struct {
		name    string
		modTime time.Time
	}

	var versions []versionEntry
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		info, err := e.Info()
		if err != nil {
			continue
		}
		versions = append(versions, versionEntry{
			name:    e.Name(),
			modTime: info.ModTime(),
		})
	}

	if len(versions) <= u.cfg.MaxVersionsKept {
		return
	}

	// Sort newest first by modification time.
	sort.Slice(versions, func(i, j int) bool {
		return versions[i].modTime.After(versions[j].modTime)
	})

	currentVer := strings.TrimPrefix(u.cfg.CurrentVersion, "v")
	removed := 0

	for i := u.cfg.MaxVersionsKept; i < len(versions); i++ {
		v := versions[i]

		// Never remove the currently running version.
		if v.name == currentVer || v.name == "v"+currentVer {
			continue
		}

		dir := filepath.Join(versionsDir, v.name)
		if err := os.RemoveAll(dir); err != nil {
			logger.Warnf("Failed to remove old version directory %s: %v", dir, err)
		} else {
			removed++
			logger.Infof("Cleaned up old version directory: %s", v.name)
		}
	}

	if removed > 0 {
		logger.Infof("Cleaned up %d old version(s)", removed)
	}
}

// ---------------------------------------------------------------------------
// GetStatus
// ---------------------------------------------------------------------------

// GetStatus returns a snapshot of the current update status. It is safe to
// call from any goroutine.
func (u *Updater) GetStatus() UpdateStatus {
	u.mu.RLock()
	defer u.mu.RUnlock()

	return UpdateStatus{
		CurrentVersion:  u.status.CurrentVersion,
		LatestVersion:   u.status.LatestVersion,
		UpdateAvailable: u.status.UpdateAvailable,
		LastChecked:     u.status.LastChecked,
		Downloading:     u.status.Downloading,
		Progress:        u.status.Progress,
		Error:           u.status.Error,
	}
}

// ---------------------------------------------------------------------------
// LatestDownloadedBinary
// ---------------------------------------------------------------------------

// LatestDownloadedBinary returns the path to the most recently downloaded
// binary that is newer than the current version, or empty string if none
// exists. This is useful for the API layer to call ApplyUpdate without
// re-downloading.
func (u *Updater) LatestDownloadedBinary() string {
	u.mu.RLock()
	latest := u.status.LatestVersion
	u.mu.RUnlock()

	if latest == "" || !u.isNewer(latest) {
		return ""
	}

	candidate := filepath.Join(u.cfg.DataDir, "versions", latest, u.cfg.BinaryName)
	if fi, err := os.Stat(candidate); err == nil && !fi.IsDir() {
		return candidate
	}

	return ""
}

// ---------------------------------------------------------------------------
// Auto-Update Background Checker
// ---------------------------------------------------------------------------

// StartAutoCheck launches a dedicated background goroutine that periodically
// checks for updates at the given interval. If an update is found and AutoApply
// is enabled (and the current time falls inside the maintenance window, if
// configured), the update is automatically downloaded and applied.
//
// Calling StartAutoCheck while the auto-checker is already running is a no-op.
// Pass 0 for interval to use the default of 6 hours.
func (u *Updater) StartAutoCheck(interval time.Duration) {
	if interval <= 0 {
		interval = 6 * time.Hour
	}

	u.autoMu.Lock()
	if u.autoRunning {
		u.autoMu.Unlock()
		return
	}
	u.autoConfig.CheckInterval = interval
	u.autoConfig.NextScheduledCheck = time.Now().Add(interval)
	u.autoStop = make(chan struct{})
	u.autoRunning = true
	u.autoMu.Unlock()

	logger.Infof("Auto-update checker started (interval=%s)", interval)
	go u.autoLoop(interval)
}

// StopAutoCheck stops the background auto-update goroutine. It is safe to
// call even if the auto-checker is not running.
func (u *Updater) StopAutoCheck() {
	u.autoMu.Lock()
	defer u.autoMu.Unlock()

	if !u.autoRunning {
		return
	}
	close(u.autoStop)
	u.autoRunning = false
	logger.Info("Auto-update checker stopped")
}

// SetAutoApply enables or disables automatic application of discovered
// updates. When enabled, the auto-checker will download the update and call
// ApplyUpdate (which triggers a restart) as soon as a newer version is found
// and the maintenance window allows it.
func (u *Updater) SetAutoApply(enabled bool) {
	u.autoMu.Lock()
	defer u.autoMu.Unlock()
	u.autoConfig.AutoApply = enabled
	logger.Infof("Auto-apply set to %v", enabled)
}

// SetMaintenanceWindow restricts automatic update application to a specific
// daily hour range (24-hour clock). For example, SetMaintenanceWindow(2, 5)
// means auto-apply only between 02:00 and 05:00. Setting both to 0 disables
// the window (auto-apply at any time).
func (u *Updater) SetMaintenanceWindow(startHour, endHour int) {
	if startHour < 0 {
		startHour = 0
	}
	if startHour > 23 {
		startHour = 23
	}
	if endHour < 0 {
		endHour = 0
	}
	if endHour > 23 {
		endHour = 23
	}

	u.autoMu.Lock()
	defer u.autoMu.Unlock()
	u.autoConfig.MaintenanceWindow = MaintenanceWindow{
		StartHour: startHour,
		EndHour:   endHour,
	}
	logger.Infof("Maintenance window set to %02d:00 - %02d:00", startHour, endHour)
}

// GetAutoUpdateConfig returns a snapshot of the current auto-update
// configuration. It is safe to call from any goroutine.
func (u *Updater) GetAutoUpdateConfig() AutoUpdateConfig {
	u.autoMu.RLock()
	defer u.autoMu.RUnlock()
	return u.autoConfig
}

// SetAutoUpdateConfig replaces the entire auto-update configuration. If the
// auto-checker is running and the interval changed, it will take effect on the
// next tick (a restart of the auto-checker is not required).
func (u *Updater) SetAutoUpdateConfig(cfg AutoUpdateConfig) {
	u.autoMu.Lock()
	defer u.autoMu.Unlock()
	u.autoConfig = cfg
}

// IsAutoCheckRunning reports whether the auto-update background goroutine is
// currently active.
func (u *Updater) IsAutoCheckRunning() bool {
	u.autoMu.RLock()
	defer u.autoMu.RUnlock()
	return u.autoRunning
}

// autoLoop is the ticker goroutine for the auto-update checker.
func (u *Updater) autoLoop(interval time.Duration) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			u.autoCheckAndApply()

			// Update next scheduled check.
			u.autoMu.Lock()
			u.autoConfig.NextScheduledCheck = time.Now().Add(interval)
			u.autoMu.Unlock()

		case <-u.autoStop:
			return
		}
	}
}

// autoCheckAndApply performs a single auto-update cycle: check for an update,
// download it, and optionally apply it if AutoApply is enabled and the
// maintenance window permits.
func (u *Updater) autoCheckAndApply() {
	now := time.Now()

	u.autoMu.Lock()
	u.autoConfig.LastAutoCheck = now
	autoApply := u.autoConfig.AutoApply
	window := u.autoConfig.MaintenanceWindow
	u.autoMu.Unlock()

	info, err := u.CheckForUpdate()
	if err != nil {
		logger.Warnf("Auto-update check failed: %v", err)
		return
	}
	if info == nil {
		logger.Debugf("Auto-update: no update available")
		return
	}

	logger.Infof("Auto-update: update available %s -> %s", u.cfg.CurrentVersion, info.Version)

	binPath, err := u.DownloadUpdate(*info)
	if err != nil {
		logger.Errorf("Auto-update: download failed: %v", err)
		return
	}
	logger.Infof("Auto-update: downloaded %s to %s", info.Version, binPath)

	if !autoApply {
		logger.Info("Auto-update: auto-apply is disabled, update downloaded but not applied")
		return
	}

	if !u.isInMaintenanceWindow(now, window) {
		logger.Infof("Auto-update: outside maintenance window (%02d:00-%02d:00), deferring apply",
			window.StartHour, window.EndHour)
		return
	}

	logger.Infof("Auto-update: applying update %s", info.Version)
	if err := u.ApplyUpdate(binPath); err != nil {
		logger.Errorf("Auto-update: apply failed: %v", err)
	}
}

// isInMaintenanceWindow returns true if the given time falls within the
// maintenance window. A zero-value window (0,0) means "always allowed".
func (u *Updater) isInMaintenanceWindow(t time.Time, w MaintenanceWindow) bool {
	// Window disabled -- always allowed.
	if w.StartHour == 0 && w.EndHour == 0 {
		return true
	}

	hour := t.Hour()

	if w.StartHour <= w.EndHour {
		// Simple range, e.g. 2-5 means 02:00..04:59
		return hour >= w.StartHour && hour < w.EndHour
	}
	// Wrapping range, e.g. 22-4 means 22:00..03:59
	return hour >= w.StartHour || hour < w.EndHour
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// isDocker returns true when the process appears to be running inside a Docker
// container. It checks for /.dockerenv and the "docker" cgroup.
func isDocker() bool {
	// Primary check: /.dockerenv exists.
	if _, err := os.Stat("/.dockerenv"); err == nil {
		return true
	}

	// Secondary check: /proc/1/cgroup mentions "docker" or "containerd".
	if data, err := os.ReadFile("/proc/1/cgroup"); err == nil {
		s := string(data)
		if strings.Contains(s, "docker") || strings.Contains(s, "containerd") {
			return true
		}
	}

	// Tertiary check: /proc/self/mountinfo shows an overlay root (common
	// in Docker).
	if data, err := os.ReadFile("/proc/self/mountinfo"); err == nil {
		if strings.Contains(string(data), "overlay") && strings.Contains(string(data), "/docker/") {
			return true
		}
	}

	return false
}

// copyFile copies src to dst, preserving permissions. It writes to a temp file
// first and renames for atomicity.
func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	info, err := in.Stat()
	if err != nil {
		return err
	}

	tmp := dst + ".tmp"
	out, err := os.OpenFile(tmp, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, info.Mode())
	if err != nil {
		return err
	}

	if _, err := io.Copy(out, in); err != nil {
		out.Close()
		os.Remove(tmp)
		return err
	}
	out.Close()

	return os.Rename(tmp, dst)
}
