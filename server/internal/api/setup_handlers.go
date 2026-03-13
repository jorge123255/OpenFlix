package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// GET /api/setup/status - check if initial setup is needed
func (s *Server) getSetupStatus(c *gin.Context) {
	// Check if any tuners exist
	var tunerCount int64
	s.db.Model(&models.TunerDevice{}).Count(&tunerCount)

	// Check if any library sources exist
	var sourceCount int64
	s.db.Model(&models.LibrarySource{}).Count(&sourceCount)

	// Check if setup was explicitly completed (stored in settings)
	var setting models.Setting
	setupComplete := false
	if s.db.Where("key = ?", "setup_complete").First(&setting).Error == nil {
		setupComplete = setting.Value == "true"
	}

	// Needs setup if: no tuners AND no sources AND not explicitly completed
	needsSetup := tunerCount == 0 && sourceCount == 0 && !setupComplete

	c.JSON(http.StatusOK, gin.H{
		"needsSetup":    needsSetup,
		"tunerCount":    tunerCount,
		"sourceCount":   sourceCount,
		"setupComplete": setupComplete,
	})
}

// POST /api/setup/complete - mark setup as complete
func (s *Server) markSetupComplete(c *gin.Context) {
	setting := models.Setting{
		Key:   "setup_complete",
		Value: "true",
	}
	s.db.Where("key = ?", "setup_complete").Assign(setting).FirstOrCreate(&setting)
	c.JSON(http.StatusOK, gin.H{"success": true})
}
