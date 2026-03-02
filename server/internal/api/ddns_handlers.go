package api

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/ddns"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

const ddnsSettingKey = "ddns_config"

// getDDNSStatus returns the current DDNS client status.
// GET /api/ddns/status
func (s *Server) getDDNSStatus(c *gin.Context) {
	status := s.ddnsClient.GetStatus()
	c.JSON(http.StatusOK, gin.H{
		"status": status,
	})
}

// configureDDNS applies a new DDNS configuration, persists it, and starts the update loop.
// PUT /api/ddns/configure
func (s *Server) configureDDNS(c *gin.Context) {
	var cfg ddns.Config
	if err := c.ShouldBindJSON(&cfg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate required fields per provider
	if err := validateDDNSConfig(cfg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Persist to database
	jsonStr, err := ddns.ConfigToJSON(cfg)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to serialise config"})
		return
	}
	s.setSetting(ddnsSettingKey, jsonStr)

	// Apply to running client
	s.ddnsClient.Configure(cfg)

	logger.Infof("DDNS configured: provider=%s, hostname=%s", cfg.Provider, cfg.Hostname)

	c.JSON(http.StatusOK, gin.H{
		"message": "DDNS configured successfully",
		"status":  s.ddnsClient.GetStatus(),
	})
}

// testDDNS tests a DDNS configuration without saving it.
// POST /api/ddns/test
func (s *Server) testDDNS(c *gin.Context) {
	var cfg ddns.Config
	if err := c.ShouldBindJSON(&cfg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := validateDDNSConfig(cfg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := s.ddnsClient.TestConfig(cfg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "DDNS test successful",
	})
}

// forceUpdateDDNS triggers an immediate DNS update.
// POST /api/ddns/update
func (s *Server) forceUpdateDDNS(c *gin.Context) {
	if err := s.ddnsClient.ForceUpdate(); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "DNS update triggered",
		"status":  s.ddnsClient.GetStatus(),
	})
}

// disableDDNS stops the DDNS client and removes the stored configuration.
// DELETE /api/ddns/disable
func (s *Server) disableDDNS(c *gin.Context) {
	s.ddnsClient.Disable()

	// Remove from database
	s.db.Where("key = ?", ddnsSettingKey).Delete(&models.Setting{})

	logger.Info("DDNS disabled and configuration removed")

	c.JSON(http.StatusOK, gin.H{
		"message": "DDNS disabled",
	})
}

// loadDDNSConfig reads the persisted DDNS configuration from the settings table
// and applies it to the client. Called during server startup.
func (s *Server) loadDDNSConfig() {
	jsonStr := s.getSettingString(ddnsSettingKey, "")
	if jsonStr == "" {
		return
	}

	cfg, err := ddns.ConfigFromJSON(jsonStr)
	if err != nil {
		logger.Warnf("Failed to parse stored DDNS config: %v", err)
		return
	}

	if cfg.Enabled {
		s.ddnsClient.Configure(cfg)
		logger.Infof("DDNS restored from settings: provider=%s, hostname=%s", cfg.Provider, cfg.Hostname)
	}
}

// validateDDNSConfig checks that the required fields are present for the chosen provider.
func validateDDNSConfig(cfg ddns.Config) error {
	if cfg.Provider == "" {
		return fmt.Errorf("provider is required")
	}
	if cfg.Hostname == "" && cfg.Provider != ddns.ProviderCustom {
		return fmt.Errorf("hostname is required")
	}

	switch cfg.Provider {
	case ddns.ProviderNoIP:
		if cfg.Username == "" || cfg.Password == "" {
			return fmt.Errorf("username and password are required for No-IP")
		}
	case ddns.ProviderDuckDNS:
		if cfg.Token == "" {
			return fmt.Errorf("token is required for DuckDNS")
		}
	case ddns.ProviderCloudflare:
		if cfg.Token == "" {
			return fmt.Errorf("token (API token) is required for Cloudflare")
		}
		if cfg.ZoneID == "" {
			return fmt.Errorf("zone_id is required for Cloudflare")
		}
	case ddns.ProviderCustom:
		if cfg.CustomURL == "" {
			return fmt.Errorf("custom_url is required for custom provider")
		}
	default:
		return fmt.Errorf("unsupported provider: %s", cfg.Provider)
	}

	return nil
}
