package api

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// settingsKey used to persist the auto-update configuration in the settings
// table as a JSON blob.
const autoUpdateConfigKey = "auto_update_config"

// autoUpdateConfigRequest is the JSON body accepted by PUT /api/updates/auto-config.
type autoUpdateConfigRequest struct {
	CheckIntervalMinutes int  `json:"check_interval_minutes"`
	AutoApply            bool `json:"auto_apply"`
	MaintenanceStartHour int  `json:"maintenance_start_hour"`
	MaintenanceEndHour   int  `json:"maintenance_end_hour"`
}

// autoUpdateConfigResponse is the JSON body returned by GET /api/updates/auto-config.
type autoUpdateConfigResponse struct {
	CheckIntervalMinutes int       `json:"check_interval_minutes"`
	AutoApply            bool      `json:"auto_apply"`
	MaintenanceStartHour int       `json:"maintenance_start_hour"`
	MaintenanceEndHour   int       `json:"maintenance_end_hour"`
	LastAutoCheck        time.Time `json:"last_auto_check"`
	NextScheduledCheck   time.Time `json:"next_scheduled_check"`
	Running              bool      `json:"running"`
}

// autoUpdateScheduleResponse is the JSON body returned by GET /api/updates/schedule.
type autoUpdateScheduleResponse struct {
	AutoCheckRunning   bool      `json:"auto_check_running"`
	LastAutoCheck      time.Time `json:"last_auto_check"`
	NextScheduledCheck time.Time `json:"next_scheduled_check"`
	AutoApply          bool      `json:"auto_apply"`
	MaintenanceWindow  struct {
		Enabled   bool `json:"enabled"`
		StartHour int  `json:"start_hour"`
		EndHour   int  `json:"end_hour"`
	} `json:"maintenance_window"`
	UpdateStatus interface{} `json:"update_status"`
}

// ---------------------------------------------------------------------------
// GET /api/updates/auto-config
// ---------------------------------------------------------------------------

func (s *Server) getAutoUpdateConfig(c *gin.Context) {
	if s.updater == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Updater is not enabled"})
		return
	}

	cfg := s.updater.GetAutoUpdateConfig()
	minutes := int(cfg.CheckInterval.Minutes())
	if minutes <= 0 {
		minutes = 360 // default 6 hours
	}

	c.JSON(http.StatusOK, autoUpdateConfigResponse{
		CheckIntervalMinutes: minutes,
		AutoApply:            cfg.AutoApply,
		MaintenanceStartHour: cfg.MaintenanceWindow.StartHour,
		MaintenanceEndHour:   cfg.MaintenanceWindow.EndHour,
		LastAutoCheck:        cfg.LastAutoCheck,
		NextScheduledCheck:   cfg.NextScheduledCheck,
		Running:              s.updater.IsAutoCheckRunning(),
	})
}

// ---------------------------------------------------------------------------
// PUT /api/updates/auto-config
// ---------------------------------------------------------------------------

func (s *Server) putAutoUpdateConfig(c *gin.Context) {
	if s.updater == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Updater is not enabled"})
		return
	}

	var req autoUpdateConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Validate interval (minimum 10 minutes).
	if req.CheckIntervalMinutes < 10 {
		req.CheckIntervalMinutes = 10
	}

	// Validate hours.
	clampHour := func(h int) int {
		if h < 0 {
			return 0
		}
		if h > 23 {
			return 23
		}
		return h
	}
	req.MaintenanceStartHour = clampHour(req.MaintenanceStartHour)
	req.MaintenanceEndHour = clampHour(req.MaintenanceEndHour)

	interval := time.Duration(req.CheckIntervalMinutes) * time.Minute

	// Apply to the in-memory updater.
	s.updater.SetAutoApply(req.AutoApply)
	s.updater.SetMaintenanceWindow(req.MaintenanceStartHour, req.MaintenanceEndHour)

	// (Re)start the auto-checker with the new interval. Stop first if
	// already running so the new interval takes effect immediately.
	if s.updater.IsAutoCheckRunning() {
		s.updater.StopAutoCheck()
	}
	s.updater.StartAutoCheck(interval)

	// Persist to the settings table.
	s.saveAutoUpdateConfig(req)

	logger.Infof("Auto-update config updated: interval=%dm, autoApply=%v, window=%02d:00-%02d:00",
		req.CheckIntervalMinutes, req.AutoApply,
		req.MaintenanceStartHour, req.MaintenanceEndHour)

	// Return the effective config.
	cfg := s.updater.GetAutoUpdateConfig()
	c.JSON(http.StatusOK, autoUpdateConfigResponse{
		CheckIntervalMinutes: req.CheckIntervalMinutes,
		AutoApply:            cfg.AutoApply,
		MaintenanceStartHour: cfg.MaintenanceWindow.StartHour,
		MaintenanceEndHour:   cfg.MaintenanceWindow.EndHour,
		LastAutoCheck:        cfg.LastAutoCheck,
		NextScheduledCheck:   cfg.NextScheduledCheck,
		Running:              s.updater.IsAutoCheckRunning(),
	})
}

// ---------------------------------------------------------------------------
// GET /api/updates/schedule
// ---------------------------------------------------------------------------

func (s *Server) getAutoUpdateSchedule(c *gin.Context) {
	if s.updater == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Updater is not enabled"})
		return
	}

	cfg := s.updater.GetAutoUpdateConfig()
	status := s.updater.GetStatus()

	resp := autoUpdateScheduleResponse{
		AutoCheckRunning:   s.updater.IsAutoCheckRunning(),
		LastAutoCheck:      cfg.LastAutoCheck,
		NextScheduledCheck: cfg.NextScheduledCheck,
		AutoApply:          cfg.AutoApply,
		UpdateStatus:       status,
	}
	resp.MaintenanceWindow.StartHour = cfg.MaintenanceWindow.StartHour
	resp.MaintenanceWindow.EndHour = cfg.MaintenanceWindow.EndHour
	resp.MaintenanceWindow.Enabled = !(cfg.MaintenanceWindow.StartHour == 0 && cfg.MaintenanceWindow.EndHour == 0)

	c.JSON(http.StatusOK, resp)
}

// ---------------------------------------------------------------------------
// POST /api/updates/check-now
// ---------------------------------------------------------------------------

func (s *Server) triggerAutoUpdateCheck(c *gin.Context) {
	if s.updater == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Updater is not enabled"})
		return
	}

	info, err := s.updater.CheckForUpdate()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	status := s.updater.GetStatus()

	if info == nil {
		c.JSON(http.StatusOK, gin.H{
			"update_available": false,
			"message":          "Already up to date",
			"status":           status,
		})
		return
	}

	// If auto-apply is enabled, kick off download + apply in a goroutine so
	// the API responds immediately.
	cfg := s.updater.GetAutoUpdateConfig()
	if cfg.AutoApply {
		go func() {
			binPath, dlErr := s.updater.DownloadUpdate(*info)
			if dlErr != nil {
				logger.Errorf("check-now: download failed: %v", dlErr)
				return
			}
			logger.Infof("check-now: applying update %s from %s", info.Version, binPath)
			if applyErr := s.updater.ApplyUpdate(binPath); applyErr != nil {
				logger.Errorf("check-now: apply failed: %v", applyErr)
			}
		}()
	}

	c.JSON(http.StatusOK, gin.H{
		"update_available": true,
		"version":          info.Version,
		"release_notes":    info.ReleaseNotes,
		"release_date":     info.ReleaseDate,
		"auto_applying":    cfg.AutoApply,
		"status":           status,
	})
}

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------

// saveAutoUpdateConfig marshals the request to JSON and stores it in the
// settings table.
func (s *Server) saveAutoUpdateConfig(req autoUpdateConfigRequest) {
	data, err := json.Marshal(req)
	if err != nil {
		logger.Warnf("Failed to marshal auto-update config: %v", err)
		return
	}
	setting := models.Setting{Key: autoUpdateConfigKey, Value: string(data)}
	s.db.Where("key = ?", autoUpdateConfigKey).Assign(setting).FirstOrCreate(&setting)
}

// loadAutoUpdateConfig reads the persisted auto-update config from the
// settings table. It returns false if no config is stored.
func (s *Server) loadAutoUpdateConfig() (autoUpdateConfigRequest, bool) {
	var setting models.Setting
	if err := s.db.Where("key = ?", autoUpdateConfigKey).First(&setting).Error; err != nil {
		return autoUpdateConfigRequest{}, false
	}
	var req autoUpdateConfigRequest
	if err := json.Unmarshal([]byte(setting.Value), &req); err != nil {
		logger.Warnf("Failed to unmarshal auto-update config from DB: %v", err)
		return autoUpdateConfigRequest{}, false
	}
	return req, true
}

// restoreAutoUpdateConfig is called during server startup to restore the
// persisted auto-update configuration and (re)start the auto-checker.
func (s *Server) restoreAutoUpdateConfig() {
	if s.updater == nil {
		return
	}

	req, ok := s.loadAutoUpdateConfig()
	if !ok {
		return
	}

	interval := time.Duration(req.CheckIntervalMinutes) * time.Minute
	if interval < 10*time.Minute {
		interval = 6 * time.Hour
	}

	s.updater.SetAutoApply(req.AutoApply)
	s.updater.SetMaintenanceWindow(req.MaintenanceStartHour, req.MaintenanceEndHour)
	s.updater.StartAutoCheck(interval)

	logger.Infof("Restored auto-update config: interval=%s, autoApply=%v, window=%02d:00-%02d:00",
		interval, req.AutoApply, req.MaintenanceStartHour, req.MaintenanceEndHour)
}
