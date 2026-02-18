package api

import (
	"fmt"
	"os"

	"golang.org/x/sys/unix"
)

type diskUsageResult struct {
	Total uint64
	Used  uint64
	Free  uint64
}

// getDiskUsage returns disk usage statistics for the given path
func getDiskUsage(path string) (*diskUsageResult, error) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return nil, fmt.Errorf("path does not exist: %s", path)
	}

	var stat unix.Statfs_t
	if err := unix.Statfs(path, &stat); err != nil {
		return nil, fmt.Errorf("statfs failed: %w", err)
	}

	total := stat.Blocks * uint64(stat.Bsize)
	free := stat.Bavail * uint64(stat.Bsize)
	used := total - free

	return &diskUsageResult{
		Total: total,
		Used:  used,
		Free:  free,
	}, nil
}
