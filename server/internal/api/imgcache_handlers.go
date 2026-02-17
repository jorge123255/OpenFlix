package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/imgcache"
	"github.com/openflix/openflix-server/internal/logger"
)

// imageCache is a package-level variable that can be set by the server initialization.
// This avoids modifying the Server struct directly, allowing the field to be wired in later.
// When server.go is updated, it can either set this variable or add an imageCache field to Server.
var imageCache *imgcache.ImageCache

// SetImageCache sets the package-level image cache instance used by the proxy handler.
// Call this during server initialization after creating the ImageCache.
func SetImageCache(ic *imgcache.ImageCache) {
	imageCache = ic
}

// proxyImage proxies and caches external artwork images.
// GET /api/images/proxy?url=...
// If no image cache is configured, it falls back to a direct redirect.
func (s *Server) proxyImage(c *gin.Context) {
	imageURL := c.Query("url")
	if imageURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing 'url' query parameter"})
		return
	}

	// If image cache is not configured, redirect directly
	if imageCache == nil {
		c.Redirect(http.StatusTemporaryRedirect, imageURL)
		return
	}

	data, contentType, err := imageCache.Get(imageURL)
	if err != nil {
		logger.WithError(err).WithField("url", imageURL).Debug("Image proxy fetch failed")
		// Fall back to redirect on error
		c.Redirect(http.StatusTemporaryRedirect, imageURL)
		return
	}

	c.Header("Content-Type", contentType)
	c.Header("Cache-Control", "public, max-age=86400")
	c.Data(http.StatusOK, contentType, data)
}

// getImageCacheStats returns statistics about the image cache.
// GET /api/images/stats
func (s *Server) getImageCacheStats(c *gin.Context) {
	if imageCache == nil {
		c.JSON(http.StatusOK, gin.H{
			"enabled": false,
			"message": "Image cache not configured",
		})
		return
	}

	stats := imageCache.Stats()
	c.JSON(http.StatusOK, gin.H{
		"enabled":   true,
		"hits":      stats.Hits,
		"misses":    stats.Misses,
		"sizeBytes": stats.SizeBytes,
		"sizeMB":    stats.SizeMB,
		"fileCount": stats.FileCount,
		"maxSizeMB": stats.MaxSizeMB,
	})
}

// pruneImageCache manually triggers a prune of the image cache.
// POST /api/images/prune
func (s *Server) pruneImageCache(c *gin.Context) {
	if imageCache == nil {
		c.JSON(http.StatusOK, gin.H{
			"message": "Image cache not configured",
		})
		return
	}

	if err := imageCache.Prune(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to prune image cache: " + err.Error()})
		return
	}

	stats := imageCache.Stats()
	c.JSON(http.StatusOK, gin.H{
		"message":   "Image cache pruned",
		"sizeMB":    stats.SizeMB,
		"fileCount": stats.FileCount,
	})
}
