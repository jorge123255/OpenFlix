package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// getTLSStatus returns the current remote TLS access state.
// GET /api/remote-access
func (s *Server) getTLSStatus(c *gin.Context) {
	if s.tlsManager == nil {
		c.JSON(http.StatusOK, gin.H{
			"enabled": false,
			"hasCert": false,
			"domain":  "",
			"url":     "",
		})
		return
	}
	status := s.tlsManager.GetStatus()
	c.JSON(http.StatusOK, status)
}

// postTLSEnable enables or disables remote HTTPS access.
// POST /api/remote-access/enable  body: { "enabled": true/false }
func (s *Server) postTLSEnable(c *gin.Context) {
	var body struct {
		Enabled bool `json:"enabled"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid JSON"})
		return
	}

	if s.tlsManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "remote access not configured — set OPENFLIX_CLOUD_REGISTRY_URL"})
		return
	}

	if body.Enabled {
		if err := s.tlsManager.Enable(c.Request.Context()); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		s.setSetting("remote_access_enabled", "true")
	} else {
		s.tlsManager.Disable()
		s.setSetting("remote_access_enabled", "false")
	}
	s.refreshCloudRegistryExternalURL()

	status := s.tlsManager.GetStatus()
	c.JSON(http.StatusOK, status)
}
