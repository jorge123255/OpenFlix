package api

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
)

// AppDownload represents an available app for download
type AppDownload struct {
	Name        string `json:"name"`
	Filename    string `json:"filename"`
	Platform    string `json:"platform"`
	Version     string `json:"version"`
	Size        int64  `json:"size"`
	Description string `json:"description"`
	DownloadURL string `json:"downloadUrl"`
}

// getAvailableDownloads returns a list of available app downloads
func (s *Server) getAvailableDownloads(c *gin.Context) {
	downloadsDir := filepath.Join(filepath.Dir(os.Args[0]), "downloads")

	// Check if downloads directory exists
	if _, err := os.Stat(downloadsDir); os.IsNotExist(err) {
		c.JSON(http.StatusOK, gin.H{
			"downloads": []AppDownload{},
			"message":   "No downloads available",
		})
		return
	}

	// Read all files in the downloads directory
	files, err := os.ReadDir(downloadsDir)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read downloads directory"})
		return
	}

	downloads := []AppDownload{}
	baseURL := getBaseURL(c)

	for _, file := range files {
		if file.IsDir() {
			continue
		}

		filename := file.Name()
		info, err := file.Info()
		if err != nil {
			continue
		}

		// Determine platform and app info from filename
		app := AppDownload{
			Filename:    filename,
			Size:        info.Size(),
			DownloadURL: baseURL + "/downloads/" + filename,
		}

		// Parse filename to determine platform
		lowerName := strings.ToLower(filename)
		switch {
		case strings.HasSuffix(lowerName, ".apk"):
			app.Platform = "android"
			if strings.Contains(lowerName, "tv") || strings.Contains(lowerName, "androidtv") {
				app.Platform = "android-tv"
				app.Name = "OpenFlix for Android TV"
				app.Description = "Stream your media on Android TV, Google TV, Fire TV, and other Android TV devices"
			} else {
				app.Name = "OpenFlix for Android"
				app.Description = "Stream your media on Android phones and tablets"
			}
		case strings.HasSuffix(lowerName, ".ipa"):
			app.Platform = "ios"
			app.Name = "OpenFlix for iOS"
			app.Description = "Stream your media on iPhone and iPad"
		case strings.HasSuffix(lowerName, ".dmg"):
			app.Platform = "macos"
			app.Name = "OpenFlix for macOS"
			app.Description = "Stream your media on Mac"
		case strings.HasSuffix(lowerName, ".exe") || strings.HasSuffix(lowerName, ".msi"):
			app.Platform = "windows"
			app.Name = "OpenFlix for Windows"
			app.Description = "Stream your media on Windows PC"
		case strings.HasSuffix(lowerName, ".deb") || strings.HasSuffix(lowerName, ".appimage"):
			app.Platform = "linux"
			app.Name = "OpenFlix for Linux"
			app.Description = "Stream your media on Linux"
		default:
			app.Platform = "unknown"
			app.Name = filename
			app.Description = "OpenFlix app"
		}

		// Extract version from filename if present (e.g., OpenFlix-1.0.0.apk)
		app.Version = extractVersion(filename)

		downloads = append(downloads, app)
	}

	c.JSON(http.StatusOK, gin.H{
		"downloads": downloads,
		"count":     len(downloads),
	})
}

// downloadApp serves an app file for download
func (s *Server) downloadApp(c *gin.Context) {
	filename := c.Param("filename")

	// Sanitize filename to prevent directory traversal
	filename = filepath.Base(filename)
	if filename == "." || filename == ".." {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid filename"})
		return
	}

	downloadsDir := filepath.Join(filepath.Dir(os.Args[0]), "downloads")
	filePath := filepath.Join(downloadsDir, filename)

	// Check if file exists
	info, err := os.Stat(filePath)
	if os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to access file"})
		return
	}
	if info.IsDir() {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file"})
		return
	}

	// Set appropriate content type based on file extension
	contentType := "application/octet-stream"
	ext := strings.ToLower(filepath.Ext(filename))
	switch ext {
	case ".apk":
		contentType = "application/vnd.android.package-archive"
	case ".ipa":
		contentType = "application/octet-stream"
	case ".dmg":
		contentType = "application/x-apple-diskimage"
	case ".exe":
		contentType = "application/x-msdownload"
	case ".msi":
		contentType = "application/x-msi"
	case ".deb":
		contentType = "application/vnd.debian.binary-package"
	case ".appimage":
		contentType = "application/x-executable"
	}

	c.Header("Content-Description", "File Transfer")
	c.Header("Content-Transfer-Encoding", "binary")
	c.Header("Content-Disposition", "attachment; filename="+filename)
	c.Header("Content-Type", contentType)
	c.File(filePath)
}

// getBaseURL returns the base URL for the server
func getBaseURL(c *gin.Context) string {
	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	// Check for X-Forwarded-Proto header (for reverse proxy)
	if proto := c.GetHeader("X-Forwarded-Proto"); proto != "" {
		scheme = proto
	}
	return scheme + "://" + c.Request.Host
}

// extractVersion attempts to extract a version number from a filename
func extractVersion(filename string) string {
	// Remove extension
	name := strings.TrimSuffix(filename, filepath.Ext(filename))

	// Common patterns: OpenFlix-1.0.0, OpenFlix_v1.0.0, etc.
	parts := strings.FieldsFunc(name, func(r rune) bool {
		return r == '-' || r == '_'
	})

	for _, part := range parts {
		// Check if this part looks like a version number
		if len(part) > 0 {
			// Check for patterns like "1.0.0", "v1.0.0", "1.0"
			cleaned := strings.TrimPrefix(part, "v")
			cleaned = strings.TrimPrefix(cleaned, "V")
			if len(cleaned) > 0 && (cleaned[0] >= '0' && cleaned[0] <= '9') {
				// Looks like a version number
				return cleaned
			}
		}
	}

	return "1.0.0" // Default version
}
