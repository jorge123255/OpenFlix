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
)

// Package-level singleton for the tuner manager so that handlers can share
// state without modifying the Server struct.
var tunerMgr *tuner.TunerManager
var tunerOnce sync.Once

func getTunerManager() *tuner.TunerManager {
	tunerOnce.Do(func() {
		tunerMgr = tuner.NewTunerManager()
	})
	return tunerMgr
}

// ============ Tuner Handlers ============

// discoverTuners scans the local network for HDHomeRun devices.
// POST /api/tuners/discover
func (s *Server) discoverTuners(c *gin.Context) {
	mgr := getTunerManager()

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

	c.JSON(http.StatusOK, gin.H{
		"devices": devices,
		"count":   len(devices),
	})
}

// getTuners returns all currently known tuner devices.
// GET /api/tuners
func (s *Server) getTuners(c *gin.Context) {
	mgr := getTunerManager()
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

	mgr := getTunerManager()
	device, err := mgr.AddDevice(req.URL)
	if err != nil {
		logger.Errorf("Failed to add tuner at %s: %v", req.URL, err)
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "Failed to add device",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"device": device,
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

	mgr := getTunerManager()
	mgr.RemoveDevice(deviceID)

	c.JSON(http.StatusOK, gin.H{
		"message": "Device removed",
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

	mgr := getTunerManager()
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

	mgr := getTunerManager()
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

// importTunerChannels imports the channel lineup from an HDHomeRun device into
// the Live TV channels database as Channel records.
// POST /api/tuners/:id/import
func (s *Server) importTunerChannels(c *gin.Context) {
	deviceID := c.Param("id")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device ID is required"})
		return
	}

	mgr := getTunerManager()

	// Fetch the lineup from the device
	lineup, err := mgr.GetLineup(deviceID)
	if err != nil {
		logger.Errorf("Failed to get lineup for import from device %s: %v", deviceID, err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Failed to get lineup",
			"message": err.Error(),
		})
		return
	}

	if len(lineup) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"message":  "No channels found in lineup",
			"imported": 0,
			"skipped":  0,
		})
		return
	}

	// Get device info for source naming
	devices := mgr.GetDevices()
	var deviceName string
	for _, d := range devices {
		if d.DeviceID == deviceID {
			deviceName = d.ModelNumber
			if deviceName == "" {
				deviceName = d.DeviceID
			}
			break
		}
	}
	sourceName := "HDHomeRun " + deviceName

	imported := 0
	skipped := 0

	for _, ch := range lineup {
		// Skip DRM-protected channels
		if ch.DRM != 0 {
			skipped++
			continue
		}

		// Build the stream URL from the device
		streamURL := ch.URL
		if streamURL == "" {
			streamURL = mgr.GetStreamURL(deviceID, ch.GuideNumber)
		}

		// Parse the channel number
		channelNum, _ := strconv.Atoi(ch.GuideNumber)
		if channelNum == 0 {
			// Try parsing as float for sub-channels like "5.1"
			if f, err := strconv.ParseFloat(ch.GuideNumber, 64); err == nil {
				channelNum = int(f)
			}
		}

		// Check if this channel already exists (by stream URL or name + number)
		var existing models.Channel
		result := s.db.Where("stream_url = ?", streamURL).First(&existing)
		if result.Error == nil {
			// Channel already exists with this stream URL
			skipped++
			continue
		}

		// Determine HD status
		isHD := ch.HD == 1

		// Create the channel record
		channel := models.Channel{
			ChannelID:  fmt.Sprintf("hdhr-%s-%s", deviceID, ch.GuideNumber),
			Number:     channelNum,
			Name:       ch.GuideName,
			StreamURL:  streamURL,
			Enabled:    true,
			SourceType: "hdhr",
			SourceName: sourceName,
		}

		// Set the group based on HD status
		if isHD {
			channel.Group = "HD"
		} else {
			channel.Group = "SD"
		}

		if err := s.db.Create(&channel).Error; err != nil {
			logger.Warnf("Failed to import channel %s (%s): %v", ch.GuideNumber, ch.GuideName, err)
			skipped++
			continue
		}

		imported++
	}

	logger.Infof("Imported %d channels from HDHomeRun device %s (%d skipped)", imported, deviceID, skipped)

	c.JSON(http.StatusOK, gin.H{
		"message":  "Channel import complete",
		"imported": imported,
		"skipped":  skipped,
		"total":    len(lineup),
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

	mgr := getTunerManager()
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
