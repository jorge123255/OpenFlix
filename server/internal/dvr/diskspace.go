package dvr

import (
	"fmt"
	"os"
	"path/filepath"

	"golang.org/x/sys/unix"
)

// DiskUsage represents disk space information for the DVR recordings directory
type DiskUsage struct {
	TotalBytes  uint64  `json:"totalBytes"`
	FreeBytes   uint64  `json:"freeBytes"`
	UsedByDVR   uint64  `json:"usedByDVR"`
	IsLow       bool    `json:"isLow"`       // Free space < lowSpaceThreshold
	IsCritical  bool    `json:"isCritical"`  // Free space < 1GB
	QuotaGB     float64 `json:"quotaGB"`     // Configured quota (0 = unlimited)
	LowSpaceGB  float64 `json:"lowSpaceGB"`  // Configured low-space threshold
}

// DiskSpaceConfig holds disk space management configuration
type DiskSpaceConfig struct {
	QuotaGB    float64 // 0 = unlimited
	LowSpaceGB float64 // Default 5GB
}

// GetDiskUsage returns current disk usage for the recordings directory
func GetDiskUsage(recordingsDir string, config DiskSpaceConfig) (*DiskUsage, error) {
	// Ensure directory exists
	if err := os.MkdirAll(recordingsDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to access recordings directory: %w", err)
	}

	// Get filesystem stats
	var stat unix.Statfs_t
	if err := unix.Statfs(recordingsDir, &stat); err != nil {
		return nil, fmt.Errorf("failed to get filesystem stats: %w", err)
	}

	totalBytes := stat.Blocks * uint64(stat.Bsize)
	freeBytes := stat.Bavail * uint64(stat.Bsize) // Available to non-root users

	// Calculate DVR usage by walking the recordings directory
	var usedByDVR uint64
	filepath.Walk(recordingsDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip files we can't read
		}
		if !info.IsDir() {
			usedByDVR += uint64(info.Size())
		}
		return nil
	})

	lowSpaceThreshold := config.LowSpaceGB
	if lowSpaceThreshold <= 0 {
		lowSpaceThreshold = 5.0 // Default 5GB
	}
	lowSpaceBytes := uint64(lowSpaceThreshold * 1024 * 1024 * 1024)
	criticalBytes := uint64(1 * 1024 * 1024 * 1024) // 1GB

	usage := &DiskUsage{
		TotalBytes: totalBytes,
		FreeBytes:  freeBytes,
		UsedByDVR:  usedByDVR,
		IsLow:      freeBytes < lowSpaceBytes,
		IsCritical: freeBytes < criticalBytes,
		QuotaGB:    config.QuotaGB,
		LowSpaceGB: lowSpaceThreshold,
	}

	return usage, nil
}

// CanStartRecording checks if there's enough disk space to start a new recording
func CanStartRecording(recordingsDir string, config DiskSpaceConfig) (bool, string) {
	usage, err := GetDiskUsage(recordingsDir, config)
	if err != nil {
		// If we can't check, allow the recording but log
		return true, ""
	}

	if usage.IsCritical {
		return false, fmt.Sprintf("critical disk space: only %.1f GB free", float64(usage.FreeBytes)/(1024*1024*1024))
	}

	// Check quota
	if config.QuotaGB > 0 {
		quotaBytes := uint64(config.QuotaGB * 1024 * 1024 * 1024)
		if usage.UsedByDVR >= quotaBytes {
			return false, fmt.Sprintf("DVR quota exceeded: using %.1f GB of %.1f GB quota",
				float64(usage.UsedByDVR)/(1024*1024*1024), config.QuotaGB)
		}
	}

	return true, ""
}
