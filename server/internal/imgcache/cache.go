package imgcache

import (
	"crypto/sha256"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// CacheStats holds statistics about the image cache
type CacheStats struct {
	Hits      int64  `json:"hits"`
	Misses    int64  `json:"misses"`
	SizeBytes int64  `json:"sizeBytes"`
	SizeMB    float64 `json:"sizeMB"`
	FileCount int    `json:"fileCount"`
	MaxSizeMB int64  `json:"maxSizeMB"`
}

// ImageCache provides a disk-backed cache for remote images with an HTTP proxy interface
type ImageCache struct {
	cacheDir   string
	maxSizeMB  int64
	httpClient *http.Client
	mu         sync.RWMutex

	hits   int64
	misses int64
}

// NewImageCache creates a new ImageCache that stores images in the given directory.
// maxSizeMB sets the maximum total cache size in megabytes.
func NewImageCache(cacheDir string, maxSizeMB int64) *ImageCache {
	// Ensure cache directory exists
	if err := os.MkdirAll(cacheDir, 0755); err != nil {
		logger.WithError(err).Errorf("Failed to create image cache directory: %s", cacheDir)
	}

	if maxSizeMB <= 0 {
		maxSizeMB = 500 // Default 500MB
	}

	ic := &ImageCache{
		cacheDir:  cacheDir,
		maxSizeMB: maxSizeMB,
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
			Transport: &http.Transport{
				MaxIdleConnsPerHost: 10,
				IdleConnTimeout:     30 * time.Second,
			},
		},
	}

	logger.WithFields(map[string]interface{}{
		"cacheDir":  cacheDir,
		"maxSizeMB": maxSizeMB,
	}).Info("Image cache initialized")

	return ic
}

// Get retrieves an image by URL. It checks the disk cache first (using a SHA256
// hash of the URL as the filename), and falls back to fetching from the remote
// server. Returns the image bytes, content-type, and any error.
func (ic *ImageCache) Get(url string) ([]byte, string, error) {
	if url == "" {
		return nil, "", fmt.Errorf("empty URL")
	}

	cacheKey := ic.hashURL(url)
	dataPath := filepath.Join(ic.cacheDir, cacheKey)
	metaPath := dataPath + ".meta"

	// Try to serve from disk cache
	ic.mu.RLock()
	data, err := os.ReadFile(dataPath)
	if err == nil {
		contentType := ic.readMeta(metaPath)
		if contentType == "" {
			contentType = "image/jpeg" // Sensible default
		}
		ic.mu.RUnlock()
		atomic.AddInt64(&ic.hits, 1)

		// Touch the file to update access time for LRU-style pruning
		now := time.Now()
		os.Chtimes(dataPath, now, now)

		return data, contentType, nil
	}
	ic.mu.RUnlock()

	// Cache miss - fetch from remote
	atomic.AddInt64(&ic.misses, 1)

	resp, err := ic.httpClient.Get(url)
	if err != nil {
		return nil, "", fmt.Errorf("failed to fetch image from %s: %w", url, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, "", fmt.Errorf("remote returned status %d for %s", resp.StatusCode, url)
	}

	// Read the response body with a size limit (20MB max per image)
	const maxImageSize = 20 * 1024 * 1024
	limitedReader := io.LimitReader(resp.Body, maxImageSize)
	data, err = io.ReadAll(limitedReader)
	if err != nil {
		return nil, "", fmt.Errorf("failed to read image from %s: %w", url, err)
	}

	if len(data) == 0 {
		return nil, "", fmt.Errorf("empty response from %s", url)
	}

	contentType := resp.Header.Get("Content-Type")
	if contentType == "" {
		contentType = detectContentType(data)
	}

	// Store in cache asynchronously to avoid blocking the response
	go func() {
		ic.mu.Lock()
		defer ic.mu.Unlock()

		if writeErr := os.WriteFile(dataPath, data, 0644); writeErr != nil {
			logger.WithError(writeErr).Debug("Failed to write image to cache")
			return
		}

		ic.writeMeta(metaPath, contentType)
	}()

	return data, contentType, nil
}

// ServeHTTP implements the http.Handler interface, serving cached images.
// It expects a ?url= query parameter with the URL of the image to proxy.
func (ic *ImageCache) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	imageURL := r.URL.Query().Get("url")
	if imageURL == "" {
		http.Error(w, "Missing 'url' query parameter", http.StatusBadRequest)
		return
	}

	data, contentType, err := ic.Get(imageURL)
	if err != nil {
		logger.WithError(err).Debug("Image cache fetch failed")
		http.Error(w, "Failed to fetch image", http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "public, max-age=86400") // Cache for 24 hours
	w.Header().Set("Content-Length", fmt.Sprintf("%d", len(data)))
	w.WriteHeader(http.StatusOK)
	w.Write(data)
}

// Prune removes the oldest files when the cache exceeds maxSizeMB.
// Files are sorted by modification time (oldest first) and removed until
// the total cache size is within the limit.
func (ic *ImageCache) Prune() error {
	ic.mu.Lock()
	defer ic.mu.Unlock()

	type fileEntry struct {
		path    string
		size    int64
		modTime time.Time
	}

	var entries []fileEntry
	var totalSize int64

	err := filepath.Walk(ic.cacheDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip files we cannot read
		}
		if info.IsDir() {
			return nil
		}
		// Skip .meta files from size calculation but include them for deletion
		if strings.HasSuffix(path, ".meta") {
			return nil
		}
		entries = append(entries, fileEntry{
			path:    path,
			size:    info.Size(),
			modTime: info.ModTime(),
		})
		totalSize += info.Size()
		return nil
	})
	if err != nil {
		return fmt.Errorf("failed to walk cache directory: %w", err)
	}

	maxBytes := ic.maxSizeMB * 1024 * 1024
	if totalSize <= maxBytes {
		return nil // Within limits
	}

	// Sort by modification time, oldest first
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].modTime.Before(entries[j].modTime)
	})

	removed := 0
	for _, entry := range entries {
		if totalSize <= maxBytes {
			break
		}

		// Remove the data file
		if removeErr := os.Remove(entry.path); removeErr != nil {
			logger.WithError(removeErr).WithField("path", entry.path).Debug("Failed to remove cached image")
			continue
		}

		// Also remove companion .meta file
		metaPath := entry.path + ".meta"
		os.Remove(metaPath) // Ignore error for meta file

		totalSize -= entry.size
		removed++
	}

	if removed > 0 {
		logger.WithFields(map[string]interface{}{
			"filesRemoved":  removed,
			"remainingSize": fmt.Sprintf("%.1fMB", float64(totalSize)/(1024*1024)),
		}).Info("Image cache pruned")
	}

	return nil
}

// Stats returns current cache statistics including hit/miss counts, size on disk,
// and file count.
func (ic *ImageCache) Stats() CacheStats {
	ic.mu.RLock()
	defer ic.mu.RUnlock()

	var sizeBytes int64
	var fileCount int

	filepath.Walk(ic.cacheDir, func(path string, info os.FileInfo, err error) error {
		if err != nil || info.IsDir() {
			return nil
		}
		if !strings.HasSuffix(path, ".meta") {
			sizeBytes += info.Size()
			fileCount++
		}
		return nil
	})

	return CacheStats{
		Hits:      atomic.LoadInt64(&ic.hits),
		Misses:    atomic.LoadInt64(&ic.misses),
		SizeBytes: sizeBytes,
		SizeMB:    float64(sizeBytes) / (1024 * 1024),
		FileCount: fileCount,
		MaxSizeMB: ic.maxSizeMB,
	}
}

// hashURL returns a SHA256 hex digest of the given URL, used as the cache key filename
func (ic *ImageCache) hashURL(url string) string {
	h := sha256.Sum256([]byte(url))
	return fmt.Sprintf("%x", h)
}

// readMeta reads the content-type from a companion .meta file
func (ic *ImageCache) readMeta(metaPath string) string {
	data, err := os.ReadFile(metaPath)
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(data))
}

// writeMeta writes the content-type to a companion .meta file
func (ic *ImageCache) writeMeta(metaPath, contentType string) {
	os.WriteFile(metaPath, []byte(contentType), 0644)
}

// detectContentType attempts to determine the MIME type from the first bytes of data
func detectContentType(data []byte) string {
	if len(data) == 0 {
		return "application/octet-stream"
	}

	// Check common image magic bytes
	if len(data) >= 8 {
		// PNG: 89 50 4E 47
		if data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
			return "image/png"
		}
		// JPEG: FF D8 FF
		if data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
			return "image/jpeg"
		}
		// GIF: 47 49 46 38
		if data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x38 {
			return "image/gif"
		}
		// WebP: RIFF....WEBP
		if data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46 &&
			len(data) >= 12 && data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50 {
			return "image/webp"
		}
	}

	// Check for SVG (text-based)
	prefix := strings.ToLower(string(data[:min(len(data), 256)]))
	if strings.Contains(prefix, "<svg") {
		return "image/svg+xml"
	}

	return "image/jpeg" // Default fallback
}

// min returns the smaller of two ints
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
