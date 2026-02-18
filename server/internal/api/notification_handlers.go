package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/notify"
)

const notificationSettingKey = "notification_config"

// getNotificationConfig returns the current notification configuration.
// GET /api/notifications/config
func (s *Server) getNotificationConfig(c *gin.Context) {
	if s.notifyManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Notification system not available"})
		return
	}

	cfg := s.notifyManager.GetConfig()
	c.JSON(http.StatusOK, gin.H{
		"config":          cfg,
		"supportedEvents": notify.SupportedEvents(),
	})
}

// putNotificationConfig saves the notification configuration.
// PUT /api/notifications/config
func (s *Server) putNotificationConfig(c *gin.Context) {
	if s.notifyManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Notification system not available"})
		return
	}

	var cfg notify.Config
	if err := c.ShouldBindJSON(&cfg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Persist to database
	jsonStr, err := notify.ConfigToJSON(cfg)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to serialise config"})
		return
	}
	s.setSetting(notificationSettingKey, jsonStr)

	// Apply to running manager
	s.notifyManager.SetConfig(cfg)

	logger.Info("Notification configuration updated")

	c.JSON(http.StatusOK, gin.H{
		"message": "Notification configuration saved",
		"config":  cfg,
	})
}

// testNotification sends a test notification through all enabled channels.
// POST /api/notifications/test
func (s *Server) testNotification(c *gin.Context) {
	if s.notifyManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Notification system not available"})
		return
	}

	results := s.notifyManager.SendTestNotification()

	allSuccess := true
	for _, r := range results {
		if !r.Success {
			allSuccess = false
			break
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": allSuccess,
		"results": results,
	})
}

// getNotificationHistory returns recent notification history.
// GET /api/notifications/history
func (s *Server) getNotificationHistory(c *gin.Context) {
	if s.notifyManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Notification system not available"})
		return
	}

	history := s.notifyManager.GetHistory()
	c.JSON(http.StatusOK, gin.H{
		"history": history,
		"total":   len(history),
	})
}

// loadNotificationConfig reads the persisted notification config from the
// settings table and applies it to the manager. Called during server startup.
func (s *Server) loadNotificationConfig() {
	if s.notifyManager == nil {
		return
	}

	jsonStr := s.getSettingString(notificationSettingKey, "")
	if jsonStr == "" {
		return
	}

	cfg, err := notify.ConfigFromJSON(jsonStr)
	if err != nil {
		logger.Warnf("Failed to parse stored notification config: %v", err)
		return
	}

	s.notifyManager.SetConfig(cfg)
	logger.Info("Notification configuration restored from settings")
}
