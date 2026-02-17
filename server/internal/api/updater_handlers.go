package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
)

// ============ Admin: Self-Update System ============

// getUpdateStatus returns the current state of the updater
func (s *Server) getUpdateStatus(c *gin.Context) {
	if s.updater == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Updater is not enabled"})
		return
	}
	c.JSON(http.StatusOK, s.updater.GetStatus())
}

// checkForUpdate triggers a manual update check
func (s *Server) checkForUpdate(c *gin.Context) {
	if s.updater == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Updater is not enabled"})
		return
	}

	info, err := s.updater.CheckForUpdate()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	if info == nil {
		c.JSON(http.StatusOK, gin.H{
			"updateAvailable": false,
			"message":         "Already up to date",
			"status":          s.updater.GetStatus(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"updateAvailable": true,
		"version":         info.Version,
		"releaseNotes":    info.ReleaseNotes,
		"releaseDate":     info.ReleaseDate,
		"status":          s.updater.GetStatus(),
	})
}

// applyUpdate applies a previously downloaded update
func (s *Server) applyUpdate(c *gin.Context) {
	if s.updater == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Updater is not enabled"})
		return
	}

	binPath := s.updater.LatestDownloadedBinary()
	if binPath == "" {
		c.JSON(http.StatusNotFound, gin.H{
			"error": "No downloaded update available to apply",
		})
		return
	}

	logger.Infof("Applying update from %s (requested via API)", binPath)

	if err := s.updater.ApplyUpdate(binPath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	// If we reach here, either the server is restarting or we're in Docker
	c.JSON(http.StatusOK, gin.H{
		"message": "Update applied. Server is restarting.",
	})
}
