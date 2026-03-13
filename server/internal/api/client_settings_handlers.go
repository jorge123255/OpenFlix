package api

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Device Management Handlers ============

// listDevices returns all registered client devices (admin only)
func (s *Server) listDevices(c *gin.Context) {
	var devices []models.ClientDevice
	if err := s.db.Order("last_seen DESC").Find(&devices).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch devices"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"devices": devices})
}

// getDevice returns a single device by ID (admin only)
func (s *Server) getDevice(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid device ID"})
		return
	}

	var device models.ClientDevice
	if err := s.db.First(&device, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
		return
	}

	c.JSON(http.StatusOK, device)
}

// updateDevice updates device settings (admin only)
func (s *Server) updateDevice(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid device ID"})
		return
	}

	var device models.ClientDevice
	if err := s.db.First(&device, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
		return
	}

	var req struct {
		DisplayName         *string `json:"displayName"`
		KioskMode           *bool   `json:"kioskMode"`
		KidsOnlyMode        *bool   `json:"kidsOnlyMode"`
		MaxRating           *string `json:"maxRating"`
		DefaultQuality      *string `json:"defaultQuality"`
		MaxBitrate          *int    `json:"maxBitrate"`
		StartupSection      *string `json:"startupSection"`
		Theme               *string `json:"theme"`
		EnableDVR           *bool   `json:"enableDVR"`
		EnableLiveTV        *bool   `json:"enableLiveTV"`
		EnableDownloads     *bool   `json:"enableDownloads"`
		ChannelCollectionID *uint   `json:"channelCollectionId"`
		SidebarSections     *string `json:"sidebarSections"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Apply only provided fields
	if req.DisplayName != nil {
		device.DisplayName = *req.DisplayName
	}
	if req.KioskMode != nil {
		device.KioskMode = *req.KioskMode
	}
	if req.KidsOnlyMode != nil {
		device.KidsOnlyMode = *req.KidsOnlyMode
	}
	if req.MaxRating != nil {
		device.MaxRating = *req.MaxRating
	}
	if req.DefaultQuality != nil {
		device.DefaultQuality = *req.DefaultQuality
	}
	if req.MaxBitrate != nil {
		device.MaxBitrate = *req.MaxBitrate
	}
	if req.StartupSection != nil {
		device.StartupSection = *req.StartupSection
	}
	if req.Theme != nil {
		device.Theme = *req.Theme
	}
	if req.EnableDVR != nil {
		device.EnableDVR = *req.EnableDVR
	}
	if req.EnableLiveTV != nil {
		device.EnableLiveTV = *req.EnableLiveTV
	}
	if req.EnableDownloads != nil {
		device.EnableDownloads = *req.EnableDownloads
	}
	if req.ChannelCollectionID != nil {
		device.ChannelCollectionID = *req.ChannelCollectionID
	}
	if req.SidebarSections != nil {
		device.SidebarSections = *req.SidebarSections
	}

	if err := s.db.Save(&device).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update device"})
		return
	}

	c.JSON(http.StatusOK, device)
}

// deleteDevice removes a registered device (admin only)
func (s *Server) deleteDevice(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid device ID"})
		return
	}

	result := s.db.Delete(&models.ClientDevice{}, id)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete device"})
		return
	}
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Device removed"})
}

// registerDevice registers or updates a client device heartbeat (any authenticated user)
func (s *Server) registerDevice(c *gin.Context) {
	var req struct {
		DeviceID    string `json:"deviceId" binding:"required"`
		Platform    string `json:"platform"`
		AppVersion  string `json:"appVersion"`
		DeviceModel string `json:"deviceModel"`
		OSVersion   string `json:"osVersion"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "deviceId is required"})
		return
	}

	// Determine connection type from request headers
	connectionType := "local"
	if c.GetHeader("X-Forwarded-For") != "" || c.GetHeader("Via") != "" {
		connectionType = "remote"
	}

	var device models.ClientDevice
	result := s.db.Where("device_id = ?", req.DeviceID).First(&device)

	if result.Error != nil {
		// Device does not exist, create with sensible defaults
		device = models.ClientDevice{
			DeviceID:        req.DeviceID,
			DisplayName:     smartDeviceName(req.DeviceModel, req.Platform),
			Platform:        req.Platform,
			LastSeen:        time.Now(),
			IPAddress:       c.ClientIP(),
			AppVersion:      req.AppVersion,
			DeviceModel:     req.DeviceModel,
			OSVersion:       req.OSVersion,
			ConnectionType:  connectionType,
			KioskMode:       false,
			KidsOnlyMode:    false,
			MaxRating:       "",
			DefaultQuality:  "original",
			MaxBitrate:      0,
			StartupSection:  "home",
			Theme:           "dark",
			SidebarSections: "home,livetv,dvr,movies,shows,kids,sports,search",
			EnableDVR:       true,
			EnableLiveTV:    true,
			EnableDownloads: true,
		}

		if err := s.db.Create(&device).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to register device"})
			return
		}
	} else {
		// Update heartbeat fields
		device.LastSeen = time.Now()
		device.IPAddress = c.ClientIP()
		device.ConnectionType = connectionType
		if req.AppVersion != "" {
			device.AppVersion = req.AppVersion
		}
		if req.Platform != "" {
			device.Platform = req.Platform
		}
		if req.DeviceModel != "" {
			device.DeviceModel = req.DeviceModel
		}
		if req.OSVersion != "" {
			device.OSVersion = req.OSVersion
		}

		if err := s.db.Save(&device).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update device"})
			return
		}
	}

	c.JSON(http.StatusOK, device)
}

// getMyDeviceSettings returns settings for the current device (any authenticated user)
func (s *Server) getMyDeviceSettings(c *gin.Context) {
	deviceID := c.GetHeader("X-Device-ID")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "X-Device-ID header is required"})
		return
	}

	var device models.ClientDevice
	if err := s.db.Where("device_id = ?", deviceID).First(&device).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Device not registered. Call POST /api/devices/register first."})
		return
	}

	// Build a restrictions summary
	restrictions := gin.H{
		"settingsHidden":   device.KioskMode,
		"kidsOnly":         device.KidsOnlyMode,
		"maxRating":        device.MaxRating,
		"dvrEnabled":       device.EnableDVR,
		"liveTVEnabled":    device.EnableLiveTV,
		"downloadsEnabled": device.EnableDownloads,
	}

	c.JSON(http.StatusOK, gin.H{
		"device":       device,
		"restrictions": restrictions,
	})
}

// smartDeviceName returns a human-friendly device name.
// It prefers the model string (e.g., "iPhone 17 Pro", "Apple TV 4K") over the generic platform label.
func smartDeviceName(deviceModel, platform string) string {
	if deviceModel != "" {
		return deviceModel
	}
	switch platform {
	case "apple_tv":
		return "Apple TV"
	case "android_tv":
		return "Android TV"
	case "fire_tv":
		return "Fire TV"
	case "ios":
		return "iPhone"
	case "android":
		return "Android Device"
	case "web":
		return "Web Browser"
	default:
		if platform != "" {
			return platform + " Device"
		}
		return "Unknown Device"
	}
}

// mergeDevices merges source device into target, preserving target settings and removing source.
// POST /api/devices/merge  body: {"targetId": 1, "sourceId": 2}
func (s *Server) mergeDevices(c *gin.Context) {
	var req struct {
		TargetID uint `json:"targetId" binding:"required"`
		SourceID uint `json:"sourceId" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "targetId and sourceId are required"})
		return
	}
	if req.TargetID == req.SourceID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "targetId and sourceId must be different"})
		return
	}

	var target, source models.ClientDevice
	if err := s.db.First(&target, req.TargetID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "target device not found"})
		return
	}
	if err := s.db.First(&source, req.SourceID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "source device not found"})
		return
	}

	// Keep the most recent LastSeen, merge device info from source if target is missing it
	if source.LastSeen.After(target.LastSeen) {
		target.LastSeen = source.LastSeen
		target.IPAddress = source.IPAddress
		target.ConnectionType = source.ConnectionType
		target.AppVersion = source.AppVersion
	}
	if target.DeviceModel == "" && source.DeviceModel != "" {
		target.DeviceModel = source.DeviceModel
	}
	if target.OSVersion == "" && source.OSVersion != "" {
		target.OSVersion = source.OSVersion
	}
	if target.Platform == "" && source.Platform != "" {
		target.Platform = source.Platform
	}

	if err := s.db.Save(&target).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update target device"})
		return
	}
	// Delete the source device
	if err := s.db.Delete(&models.ClientDevice{}, req.SourceID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete source device"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "devices merged",
		"device":  target,
	})
}

// findDeviceDuplicates returns groups of devices that are likely duplicates.
// Devices are grouped by (platform, device_model) and only groups with >1 device are returned.
// GET /api/devices/duplicates
func (s *Server) findDeviceDuplicates(c *gin.Context) {
	var devices []models.ClientDevice
	if err := s.db.Order("last_seen DESC").Find(&devices).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch devices"})
		return
	}

	type DuplicateGroup struct {
		Key     string               `json:"key"`
		Devices []models.ClientDevice `json:"devices"`
	}
	groups := map[string]*DuplicateGroup{}
	order := []string{}

	for _, d := range devices {
		model := d.DeviceModel
		if model == "" {
			model = "unknown"
		}
		key := d.Platform + "|" + model
		if _, ok := groups[key]; !ok {
			groups[key] = &DuplicateGroup{Key: key}
			order = append(order, key)
		}
		groups[key].Devices = append(groups[key].Devices, d)
	}

	var duplicateGroups []DuplicateGroup
	for _, k := range order {
		if len(groups[k].Devices) > 1 {
			duplicateGroups = append(duplicateGroups, *groups[k])
		}
	}
	if duplicateGroups == nil {
		duplicateGroups = []DuplicateGroup{}
	}

	c.JSON(http.StatusOK, gin.H{
		"duplicateGroups": duplicateGroups,
		"count":           len(duplicateGroups),
	})
}
