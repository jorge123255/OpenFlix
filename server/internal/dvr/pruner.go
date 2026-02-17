package dvr

import (
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"golang.org/x/sys/unix"
	"gorm.io/gorm"
)

// PrunerConfig holds configuration for the automatic recording pruner
type PrunerConfig struct {
	MaxDiskUsagePercent float64       `json:"maxDiskUsagePercent"` // Delete old recordings when disk usage exceeds this (default 90%)
	MinFreeSpaceGB      int           `json:"minFreeSpaceGB"`      // Ensure at least this many GB are free (default 50)
	CheckInterval       time.Duration `json:"checkInterval"`       // How often to check disk usage (default 1h)
	RecordingsDir       string        `json:"recordingsDir"`       // Path to recordings directory
	Enabled             bool          `json:"enabled"`             // Whether auto-pruning is enabled
}

// DefaultPrunerConfig returns a PrunerConfig with sensible defaults
func DefaultPrunerConfig() PrunerConfig {
	return PrunerConfig{
		MaxDiskUsagePercent: 90,
		MinFreeSpaceGB:      50,
		CheckInterval:       1 * time.Hour,
		Enabled:             false,
	}
}

// PrunerStatus represents the current state of the pruner
type PrunerStatus struct {
	Enabled          bool      `json:"enabled"`
	LastRun          time.Time `json:"lastRun"`
	NextRun          time.Time `json:"nextRun"`
	FilesPruned      int       `json:"filesPruned"`
	TotalFilesPruned int       `json:"totalFilesPruned"`
	DiskUsagePercent float64   `json:"diskUsagePercent"`
	FreeSpaceGB      float64   `json:"freeSpaceGB"`
	IsRunning        bool      `json:"isRunning"`
}

// Pruner automatically deletes old recordings when disk space is low
type Pruner struct {
	db     *gorm.DB
	config PrunerConfig

	mu               sync.RWMutex
	stopCh           chan struct{}
	running          bool
	lastRun          time.Time
	nextRun          time.Time
	lastFilesPruned  int
	totalFilesPruned int
	diskUsagePercent float64
	freeSpaceGB      float64
}

// NewPruner creates a new Pruner with the given database and configuration
func NewPruner(db *gorm.DB, cfg PrunerConfig) *Pruner {
	// Apply defaults for zero values
	if cfg.MaxDiskUsagePercent <= 0 {
		cfg.MaxDiskUsagePercent = 90
	}
	if cfg.MinFreeSpaceGB <= 0 {
		cfg.MinFreeSpaceGB = 50
	}
	if cfg.CheckInterval <= 0 {
		cfg.CheckInterval = 1 * time.Hour
	}

	return &Pruner{
		db:     db,
		config: cfg,
		stopCh: make(chan struct{}),
	}
}

// Start begins the background pruning goroutine that checks disk usage periodically
func (p *Pruner) Start() {
	if !p.config.Enabled {
		logger.Info("Auto-pruner is disabled")
		return
	}

	p.mu.Lock()
	if p.running {
		p.mu.Unlock()
		logger.Warn("Auto-pruner is already running")
		return
	}
	p.running = true
	p.nextRun = time.Now().Add(p.config.CheckInterval)
	p.mu.Unlock()

	logger.WithFields(map[string]interface{}{
		"maxDiskUsage":  fmt.Sprintf("%.0f%%", p.config.MaxDiskUsagePercent),
		"minFreeSpace":  fmt.Sprintf("%dGB", p.config.MinFreeSpaceGB),
		"checkInterval": p.config.CheckInterval.String(),
	}).Info("Auto-pruner started")

	go p.loop()
}

// Stop shuts down the background pruning goroutine
func (p *Pruner) Stop() {
	p.mu.Lock()
	defer p.mu.Unlock()

	if !p.running {
		return
	}
	p.running = false
	close(p.stopCh)
	logger.Info("Auto-pruner stopped")
}

// loop is the main background loop that periodically checks and prunes
func (p *Pruner) loop() {
	// Run an initial check shortly after startup
	timer := time.NewTimer(30 * time.Second)
	defer timer.Stop()

	for {
		select {
		case <-timer.C:
			pruned, err := p.CheckAndPrune()
			if err != nil {
				logger.WithError(err).Error("Auto-pruner check failed")
			} else if pruned > 0 {
				logger.Infof("Auto-pruner removed %d old recording(s)", pruned)
			}

			p.mu.Lock()
			p.nextRun = time.Now().Add(p.config.CheckInterval)
			p.mu.Unlock()

			timer.Reset(p.config.CheckInterval)

		case <-p.stopCh:
			return
		}
	}
}

// CheckAndPrune checks current disk usage and prunes old recordings if thresholds
// are exceeded. It returns the number of files pruned and any error encountered.
// Files with "Locked" in their Labels field are never pruned.
// Files are deleted oldest-first (by RecordedAt or CreatedAt).
func (p *Pruner) CheckAndPrune() (int, error) {
	p.mu.Lock()
	p.lastRun = time.Now()
	p.mu.Unlock()

	recordingsDir := p.config.RecordingsDir
	if recordingsDir == "" {
		return 0, fmt.Errorf("recordings directory not configured")
	}

	// Get current disk usage
	usagePercent, freeGB, err := p.getDiskStats(recordingsDir)
	if err != nil {
		return 0, fmt.Errorf("failed to get disk stats: %w", err)
	}

	p.mu.Lock()
	p.diskUsagePercent = usagePercent
	p.freeSpaceGB = freeGB
	p.mu.Unlock()

	// Check if pruning is needed
	needsPrune := usagePercent > p.config.MaxDiskUsagePercent || freeGB < float64(p.config.MinFreeSpaceGB)
	if !needsPrune {
		logger.WithFields(map[string]interface{}{
			"diskUsage": fmt.Sprintf("%.1f%%", usagePercent),
			"freeSpace": fmt.Sprintf("%.1fGB", freeGB),
		}).Debug("Disk space OK, no pruning needed")
		return 0, nil
	}

	logger.WithFields(map[string]interface{}{
		"diskUsage":     fmt.Sprintf("%.1f%%", usagePercent),
		"freeSpace":     fmt.Sprintf("%.1fGB", freeGB),
		"maxDiskUsage":  fmt.Sprintf("%.0f%%", p.config.MaxDiskUsagePercent),
		"minFreeSpace":  fmt.Sprintf("%dGB", p.config.MinFreeSpaceGB),
	}).Warn("Disk space low, starting auto-prune")

	// Query eligible files: not locked, not already deleted, ordered by oldest first
	var files []models.DVRFile
	if err := p.db.
		Where("deleted = ? AND completed = ?", false, true).
		Where("labels NOT LIKE ? OR labels IS NULL OR labels = ''", "%Locked%").
		Order("COALESCE(recorded_at, created_at) ASC").
		Find(&files).Error; err != nil {
		return 0, fmt.Errorf("failed to query DVR files: %w", err)
	}

	if len(files) == 0 {
		logger.Warn("No eligible files to prune (all files may be locked)")
		return 0, nil
	}

	pruned := 0
	for _, file := range files {
		// Re-check disk stats after each deletion
		usagePercent, freeGB, err = p.getDiskStats(recordingsDir)
		if err != nil {
			logger.WithError(err).Warn("Failed to re-check disk stats during pruning")
			break
		}

		// Stop pruning once we are within thresholds
		if usagePercent <= p.config.MaxDiskUsagePercent && freeGB >= float64(p.config.MinFreeSpaceGB) {
			break
		}

		// Skip files that have "Locked" in labels (double-check)
		if hasLabel(file.Labels, "Locked") {
			continue
		}

		// Soft-delete the file record (trash-style)
		logger.WithFields(map[string]interface{}{
			"fileId":   file.ID,
			"title":    file.Title,
			"filePath": file.FilePath,
			"fileSize": file.FileSize,
		}).Info("Auto-pruner deleting old recording")

		file.Deleted = true
		if err := p.db.Save(&file).Error; err != nil {
			logger.WithError(err).WithField("fileId", file.ID).Error("Failed to mark file as deleted")
			continue
		}

		// Remove the physical file from disk
		if file.FilePath != "" {
			if _, statErr := os.Stat(file.FilePath); statErr == nil {
				if removeErr := os.Remove(file.FilePath); removeErr != nil {
					logger.WithError(removeErr).WithField("filePath", file.FilePath).Warn("Failed to remove file from disk")
				}
			}
		}

		pruned++
	}

	// Update final disk stats
	usagePercent, freeGB, _ = p.getDiskStats(recordingsDir)

	p.mu.Lock()
	p.lastFilesPruned = pruned
	p.totalFilesPruned += pruned
	p.diskUsagePercent = usagePercent
	p.freeSpaceGB = freeGB
	p.mu.Unlock()

	if pruned > 0 {
		logger.WithFields(map[string]interface{}{
			"filesPruned": pruned,
			"diskUsage":   fmt.Sprintf("%.1f%%", usagePercent),
			"freeSpace":   fmt.Sprintf("%.1fGB", freeGB),
		}).Info("Auto-prune completed")
	}

	return pruned, nil
}

// GetStatus returns the current status of the pruner
func (p *Pruner) GetStatus() PrunerStatus {
	p.mu.RLock()
	defer p.mu.RUnlock()

	return PrunerStatus{
		Enabled:          p.config.Enabled,
		LastRun:          p.lastRun,
		NextRun:          p.nextRun,
		FilesPruned:      p.lastFilesPruned,
		TotalFilesPruned: p.totalFilesPruned,
		DiskUsagePercent: p.diskUsagePercent,
		FreeSpaceGB:      p.freeSpaceGB,
		IsRunning:        p.running,
	}
}

// getDiskStats returns the current disk usage percentage and free space in GB
// for the filesystem containing the given path
func (p *Pruner) getDiskStats(path string) (usagePercent float64, freeGB float64, err error) {
	// Ensure directory exists
	if mkdirErr := os.MkdirAll(path, 0755); mkdirErr != nil {
		return 0, 0, fmt.Errorf("failed to access path %s: %w", path, mkdirErr)
	}

	var stat unix.Statfs_t
	if err := unix.Statfs(path, &stat); err != nil {
		return 0, 0, fmt.Errorf("statfs failed for %s: %w", path, err)
	}

	totalBytes := stat.Blocks * uint64(stat.Bsize)
	freeBytes := stat.Bavail * uint64(stat.Bsize) // Available to non-root users
	usedBytes := totalBytes - freeBytes

	if totalBytes == 0 {
		return 0, 0, fmt.Errorf("filesystem reports 0 total bytes")
	}

	usagePercent = (float64(usedBytes) / float64(totalBytes)) * 100.0
	freeGB = float64(freeBytes) / (1024 * 1024 * 1024)

	return usagePercent, freeGB, nil
}

// hasLabel checks if a comma-separated labels string contains a specific label
func hasLabel(labels, label string) bool {
	if labels == "" {
		return false
	}
	for _, l := range splitLabels(labels) {
		if l == label {
			return true
		}
	}
	return false
}

// splitLabels splits a comma-separated labels string into individual labels,
// trimming whitespace from each
func splitLabels(labels string) []string {
	if labels == "" {
		return nil
	}
	var result []string
	start := 0
	for i := 0; i <= len(labels); i++ {
		if i == len(labels) || labels[i] == ',' {
			l := labels[start:i]
			// Trim spaces
			for len(l) > 0 && l[0] == ' ' {
				l = l[1:]
			}
			for len(l) > 0 && l[len(l)-1] == ' ' {
				l = l[:len(l)-1]
			}
			if len(l) > 0 {
				result = append(result, l)
			}
			start = i + 1
		}
	}
	return result
}
