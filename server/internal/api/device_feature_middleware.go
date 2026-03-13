package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// deviceFeatureMiddleware returns a gin middleware that enforces device-level
// feature toggles (EnableDVR, EnableLiveTV, EnableDownloads).
//
// The device is identified by the X-Device-ID request header. If no header is
// present, the request is allowed through (device cannot be looked up). Admin
// users always bypass the check regardless of device flags.
//
// feature must be one of "dvr", "livetv", or "downloads".
func (s *Server) deviceFeatureMiddleware(feature string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Admin users bypass all device-feature restrictions
		if isAdmin, exists := c.Get("isAdmin"); exists {
			if admin, ok := isAdmin.(bool); ok && admin {
				c.Next()
				return
			}
		}

		deviceID := c.GetHeader("X-Device-ID")
		if deviceID == "" {
			// No device header — cannot enforce, allow through
			c.Next()
			return
		}

		var device models.ClientDevice
		if err := s.db.Where("device_id = ?", deviceID).First(&device).Error; err != nil {
			// Device not found in DB — allow through (unregistered device)
			c.Next()
			return
		}

		switch feature {
		case "dvr":
			if !device.EnableDVR {
				c.JSON(http.StatusForbidden, gin.H{"error": "DVR is disabled for this device"})
				c.Abort()
				return
			}
		case "livetv":
			if !device.EnableLiveTV {
				c.JSON(http.StatusForbidden, gin.H{"error": "Live TV is disabled for this device"})
				c.Abort()
				return
			}
		case "downloads":
			if !device.EnableDownloads {
				c.JSON(http.StatusForbidden, gin.H{"error": "Downloads are disabled for this device"})
				c.Abort()
				return
			}
		}

		c.Next()
	}
}
