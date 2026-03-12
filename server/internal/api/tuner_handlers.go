package api

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/openflix/openflix-server/internal/tuner"
	"gorm.io/gorm"
)

// Package-level singleton for the tuner manager so that handlers can share
// state without modifying the Server struct.
var tunerMgr *tuner.TunerManager
var tunerOnce sync.Once

func getTunerManager(db *gorm.DB) *tuner.TunerManager {
	tunerOnce.Do(func() {
		tunerMgr = tuner.NewTunerManager(db)
	})
	return tunerMgr
}

// ============ Tuner Handlers ============

// discoverTuners scans the local network for HDHomeRun devices.
// POST /api/tuners/discover
func (s *Server) discoverTuners(c *gin.Context) {
	mgr := getTunerManager(s.db)

	ctx, cancel := context.WithTimeout(c.Request.Context(), 10*time.Second)
	defer cancel()

	devices, err := mgr.Discover(ctx)
	if err != nil {
		logger.Errorf("Tuner discovery failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Discovery failed",
			"message": err.Error(),
		})
		return
	}

	// Auto-import channels for each discovered device. Running importChannelsForDevice
	// on an existing device is safe — it inserts new channels and updates codec fields
	// on existing ones without duplicating anything.
	for _, dev := range devices {
		imported, skipped, err := s.importChannelsForDevice(dev.DeviceID)
		if err != nil {
			logger.Warnf("Auto-import failed for device %s: %v", dev.DeviceID, err)
		} else {
			logger.Infof("Auto-imported %d channels from discovered device %s (%d skipped/updated)", imported, dev.DeviceID, skipped)
		}
	}

	// Map to the shape iOS expects: { discovered: [{ url, name, model, deviceId }] }
	type discoveredItem struct {
		URL      string `json:"url"`
		Name     string `json:"name"`
		Model    string `json:"model,omitempty"`
		DeviceID string `json:"deviceId,omitempty"`
	}
	items := make([]discoveredItem, 0, len(devices))
	for _, d := range devices {
		name := d.ModelNumber
		if name == "" {
			name = d.DeviceID
		}
		items = append(items, discoveredItem{
			URL:      d.BaseURL,
			Name:     name,
			Model:    d.ModelNumber,
			DeviceID: d.DeviceID,
		})
	}
	c.JSON(http.StatusOK, gin.H{"discovered": items})
}

// getTuners returns all currently known tuner devices.
// GET /api/tuners
func (s *Server) getTuners(c *gin.Context) {
	mgr := getTunerManager(s.db)
	devices := mgr.GetDevices()

	c.JSON(http.StatusOK, gin.H{
		"devices": devices,
		"count":   len(devices),
	})
}

// addTuner manually adds a tuner device by its base URL.
// POST /api/tuners
func (s *Server) addTuner(c *gin.Context) {
	var req struct {
		URL string `json:"url" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "URL is required"})
		return
	}

	mgr := getTunerManager(s.db)
	device, err := mgr.AddDevice(req.URL)
	if err != nil {
		logger.Errorf("Failed to add tuner at %s: %v", req.URL, err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Failed to add device",
			"message": err.Error(),
		})
		return
	}

	// Auto-import channels for the newly added device
	imported, skipped, err := s.importChannelsForDevice(device.DeviceID)
	if err != nil {
		logger.Warnf("Auto-import failed for device %s: %v", device.DeviceID, err)
	} else {
		logger.Infof("Auto-imported %d channels from added device %s (%d skipped)", imported, device.DeviceID, skipped)
	}

	c.JSON(http.StatusCreated, gin.H{
		"device":   device,
		"imported": imported,
		"skipped":  skipped,
	})
}

// removeTuner removes a known tuner device by its device ID.
// DELETE /api/tuners/:id
func (s *Server) removeTuner(c *gin.Context) {
	deviceID := c.Param("id")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device ID is required"})
		return
	}

	// Delete imported channels and their programs in a transaction first
	var channelsDeleted, programsDeleted int64
	channelIDPrefix := "hdhr-" + deviceID + "-%"
	_ = s.db.Transaction(func(tx *gorm.DB) error {
		var channelIDs []string
		tx.Model(&models.Channel{}).Where("channel_id LIKE ?", channelIDPrefix).Pluck("channel_id", &channelIDs)
		if len(channelIDs) > 0 {
			result := tx.Where("channel_id IN ?", channelIDs).Delete(&models.Program{})
			programsDeleted = result.RowsAffected
		}
		result := tx.Where("channel_id LIKE ?", channelIDPrefix).Delete(&models.Channel{})
		channelsDeleted = result.RowsAffected
		return nil
	})

	mgr := getTunerManager(s.db)
	mgr.RemoveDevice(deviceID)

	// Invalidate guide cache so deleted tuner channels disappear immediately.
	if s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}

	logger.Infof("Removed tuner %s: deleted %d channels, %d programs", deviceID, channelsDeleted, programsDeleted)
	c.JSON(http.StatusOK, gin.H{
		"message":         "Device removed",
		"channelsDeleted": channelsDeleted,
		"programsDeleted": programsDeleted,
	})
}

// updateTuner updates tuner settings such as priority.
// PUT /api/tuners/:id
func (s *Server) updateTuner(c *gin.Context) {
	deviceID := c.Param("id")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device ID is required"})
		return
	}

	var req struct {
		Priority *int `json:"priority"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON body"})
		return
	}
	if req.Priority == nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Priority is required"})
		return
	}

	mgr := getTunerManager(s.db)
	if err := mgr.SetPriority(deviceID, *req.Priority); err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "Device not found",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":  "Tuner updated",
		"deviceId": deviceID,
		"priority": *req.Priority,
	})
}

// getTunerLineup fetches the channel lineup from a tuner device.
// GET /api/tuners/:id/lineup
func (s *Server) getTunerLineup(c *gin.Context) {
	deviceID := c.Param("id")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device ID is required"})
		return
	}

	mgr := getTunerManager(s.db)
	channels, err := mgr.GetLineup(deviceID)
	if err != nil {
		logger.Errorf("Failed to get lineup for device %s: %v", deviceID, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to get lineup",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"channels": channels,
		"count":    len(channels),
	})
}

// getTunerStatus fetches the tuner status (active streams, signal strength, etc.).
// GET /api/tuners/:id/status
func (s *Server) getTunerStatus(c *gin.Context) {
	deviceID := c.Param("id")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device ID is required"})
		return
	}

	mgr := getTunerManager(s.db)
	statuses, err := mgr.GetTunerStatus(deviceID)
	if err != nil {
		logger.Errorf("Failed to get status for device %s: %v", deviceID, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to get tuner status",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"tuners": statuses,
		"count":  len(statuses),
	})
}

// importChannelsForDevice fetches the lineup from an HDHomeRun device and
// inserts new Channel records into the database. Returns imported/skipped counts.
func (s *Server) importChannelsForDevice(deviceID string) (imported, skipped int, err error) {
	mgr := getTunerManager(s.db)

	lineup, err := mgr.GetLineup(deviceID)
	if err != nil {
		return 0, 0, fmt.Errorf("get lineup: %w", err)
	}

	if len(lineup) == 0 {
		return 0, 0, nil
	}

	// Get device info for source naming
	var deviceName string
	for _, d := range mgr.GetDevices() {
		if d.DeviceID == deviceID {
			deviceName = d.ModelNumber
			if deviceName == "" {
				deviceName = d.DeviceID
			}
			break
		}
	}
	sourceName := "HDHomeRun " + deviceName

	for _, ch := range lineup {
		if ch.DRM != 0 {
			skipped++
			continue
		}

		streamURL := ch.URL
		if streamURL == "" {
			streamURL = mgr.GetStreamURL(deviceID, ch.GuideNumber)
		}

		channelNum, _ := strconv.Atoi(ch.GuideNumber)
		if channelNum == 0 {
			if f, ferr := strconv.ParseFloat(ch.GuideNumber, 64); ferr == nil {
				channelNum = int(f)
			}
		}

		group := "SD"
		if ch.HD == 1 {
			group = "HD"
		}

		channelID := fmt.Sprintf("hdhr-%s-%s", deviceID, ch.GuideNumber)

		// If the channel already exists, update its codec fields and move on.
		// Check multiple criteria to catch all cases:
		// 1. By hdhr channel_id (normal case — channel not yet remapped)
		// 2. By tvg_id (catches channels that were remapped to an EPG source; bulkMapChannels
		//    preserves the original hdhr-{deviceID}-{guideNumber} value in tvg_id)
		// 3. By stream_url (catches URL-only variations)
		// 4. By source_type=hdhr + name + number (last-resort fallback)
		var existing models.Channel
		found := s.db.Where("channel_id = ?", channelID).First(&existing).Error == nil
		if !found {
			found = s.db.Where("tvg_id = ?", channelID).First(&existing).Error == nil
		}
		if !found && streamURL != "" {
			found = s.db.Where("stream_url = ?", streamURL).First(&existing).Error == nil
		}
		if !found {
			// Also check by HDHomeRun source + channel number to catch any edge cases
			found = s.db.Where("source_type = ? AND number = ? AND name = ?", "hdhr", channelNum, ch.GuideName).First(&existing).Error == nil
		}
		if found {
			updates := map[string]interface{}{}
			if ch.VideoCodec != "" && existing.VideoCodec != ch.VideoCodec {
				updates["video_codec"] = ch.VideoCodec
			}
			if ch.AudioCodec != "" && existing.AudioCodec != ch.AudioCodec {
				updates["audio_codec"] = ch.AudioCodec
			}
			if len(updates) > 0 {
				s.db.Model(&existing).Updates(updates)
			}
			skipped++
			continue
		}

		channel := models.Channel{
			ChannelID:  channelID,
			Number:     channelNum,
			Name:       ch.GuideName,
			StreamURL:  streamURL,
			Enabled:    true,
			SourceType: "hdhr",
			SourceName: sourceName,
			Group:      group,
			VideoCodec: ch.VideoCodec,
			AudioCodec: ch.AudioCodec,
		}

		if createErr := s.db.Create(&channel).Error; createErr != nil {
			logger.Warnf("Failed to import channel %s (%s): %v", ch.GuideNumber, ch.GuideName, createErr)
			skipped++
			continue
		}
		imported++
	}

	return imported, skipped, nil
}

// importTunerChannels imports the channel lineup from an HDHomeRun device into
// the Live TV channels database as Channel records.
// POST /api/tuners/:id/import
func (s *Server) importTunerChannels(c *gin.Context) {
	deviceID := c.Param("id")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device ID is required"})
		return
	}

	imported, skipped, err := s.importChannelsForDevice(deviceID)
	if err != nil {
		logger.Errorf("Failed to import channels for device %s: %v", deviceID, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to get lineup",
			"message": err.Error(),
		})
		return
	}

	logger.Infof("Imported %d channels from HDHomeRun device %s (%d skipped)", imported, deviceID, skipped)

	c.JSON(http.StatusOK, gin.H{
		"message":  "Channel import complete",
		"imported": imported,
		"skipped":  skipped,
	})
}

// scanTunerChannels starts a channel scan on the tuner device.
// POST /api/tuners/:id/scan
func (s *Server) scanTunerChannels(c *gin.Context) {
	deviceID := c.Param("id")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device ID is required"})
		return
	}

	mgr := getTunerManager(s.db)
	if err := mgr.ScanChannels(deviceID); err != nil {
		logger.Errorf("Failed to start channel scan on device %s: %v", deviceID, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to start channel scan",
			"message": err.Error(),
		})
		return
	}

	// Optionally return the initial scan status
	status, err := mgr.GetScanStatus(deviceID)
	if err != nil {
		// Scan started but we couldn't get initial status - still a success
		c.JSON(http.StatusOK, gin.H{
			"message": "Channel scan started",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Channel scan started",
		"status":  status,
	})
}

// TunerImportResult holds the result of a channel import from a tuner.
type TunerImportResult struct {
	Imported int
	Skipped  int
	Error    error
}

// importChannelsFromTuner is a standalone helper for the scheduler to import
// channels from a discovered HDHomeRun device. Unlike importChannelsForDevice,
// this does not require a Server instance.
func importChannelsFromTuner(db *gorm.DB, dev *tuner.HDHomeRunDevice) TunerImportResult {
	mgr := getTunerManager(db)

	lineup, err := mgr.GetLineup(dev.DeviceID)
	if err != nil {
		return TunerImportResult{Error: fmt.Errorf("get lineup: %w", err)}
	}

	if len(lineup) == 0 {
		return TunerImportResult{}
	}

	// Build source name for the device
	deviceName := dev.ModelNumber
	if deviceName == "" {
		deviceName = dev.DeviceID
	}
	sourceName := "HDHomeRun " + deviceName

	var imported, skipped int

	for _, ch := range lineup {
		if ch.DRM != 0 {
			skipped++
			continue
		}

		streamURL := ch.URL
		if streamURL == "" {
			streamURL = mgr.GetStreamURL(dev.DeviceID, ch.GuideNumber)
		}

		channelNum, _ := strconv.Atoi(ch.GuideNumber)
		if channelNum == 0 {
			if f, ferr := strconv.ParseFloat(ch.GuideNumber, 64); ferr == nil {
				channelNum = int(f)
			}
		}

		group := "SD"
		if ch.HD == 1 {
			group = "HD"
		}

		channelID := fmt.Sprintf("hdhr-%s-%s", dev.DeviceID, ch.GuideNumber)

		// Check if channel already exists (multiple criteria)
		var existing models.Channel
		found := db.Where("channel_id = ?", channelID).First(&existing).Error == nil
		if !found {
			found = db.Where("tvg_id = ?", channelID).First(&existing).Error == nil
		}
		if !found && streamURL != "" {
			found = db.Where("stream_url = ?", streamURL).First(&existing).Error == nil
		}
		if !found {
			found = db.Where("source_type = ? AND number = ? AND name = ?", "hdhr", channelNum, ch.GuideName).First(&existing).Error == nil
		}

		if found {
			// Update codec fields on existing channel
			updates := map[string]interface{}{}
			if ch.VideoCodec != "" && existing.VideoCodec != ch.VideoCodec {
				updates["video_codec"] = ch.VideoCodec
			}
			if ch.AudioCodec != "" && existing.AudioCodec != ch.AudioCodec {
				updates["audio_codec"] = ch.AudioCodec
			}
			if len(updates) > 0 {
				db.Model(&existing).Updates(updates)
			}
			skipped++
			continue
		}

		// Create new channel
		newCh := models.Channel{
			ChannelID:  channelID,
			Name:       ch.GuideName,
			Number:     channelNum,
			
			StreamURL:  streamURL,
			Group:      group,
			SourceName: sourceName,
			SourceType: "hdhr",
			TVGId:      channelID,
			VideoCodec: ch.VideoCodec,
			AudioCodec: ch.AudioCodec,
			
			Enabled:    true,
		}

		if err := db.Create(&newCh).Error; err != nil {
			logger.Warnf("importChannelsFromTuner: failed to create channel %s: %v", ch.GuideName, err)
			continue
		}
		imported++
	}

	return TunerImportResult{Imported: imported, Skipped: skipped}
}
