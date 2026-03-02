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
			DisplayName:     req.Platform + " Device",
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

		if device.DisplayName == " Device" || device.DisplayName == "" {
			device.DisplayName = "Unknown Device"
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
