package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Device-User (Family Sharing) Handlers ============

// getDeviceUsers returns all users assigned to a device
func (s *Server) getDeviceUsers(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid device ID"})
		return
	}

	// Verify device exists
	var device models.ClientDevice
	if err := s.db.First(&device, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
		return
	}

	var deviceUsers []models.DeviceUser
	if err := s.db.Where("device_id = ?", id).Preload("User").Find(&deviceUsers).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch device users"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"users": deviceUsers})
}

// assignDeviceUsers assigns one or more users to a device (replaces existing assignments)
func (s *Server) assignDeviceUsers(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid device ID"})
		return
	}

	var req struct {
		UserIDs []uint `json:"userIds" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "userIds array is required"})
		return
	}

	// Verify device exists
	var device models.ClientDevice
	if err := s.db.First(&device, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
		return
	}

	// Verify all users exist
	if len(req.UserIDs) > 0 {
		var count int64
		s.db.Model(&models.User{}).Where("id IN ?", req.UserIDs).Count(&count)
		if count != int64(len(req.UserIDs)) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "One or more user IDs are invalid"})
			return
		}
	}

	// Delete existing assignments and replace
	tx := s.db.Begin()
	if err := tx.Where("device_id = ?", id).Delete(&models.DeviceUser{}).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update device assignments"})
		return
	}

	for _, uid := range req.UserIDs {
		du := models.DeviceUser{DeviceID: uint(id), UserID: uid}
		if err := tx.Create(&du).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to assign user to device"})
			return
		}
	}
	tx.Commit()

	// Return updated assignments with user info
	var deviceUsers []models.DeviceUser
	s.db.Where("device_id = ?", id).Preload("User").Find(&deviceUsers)

	// Apply first assigned user's restrictions to device if any users assigned
	if len(deviceUsers) > 0 && deviceUsers[0].User != nil {
		user := deviceUsers[0].User
		if user.IsRestricted {
			device.KidsOnlyMode = true
		}
		s.db.Save(&device)
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Device users updated",
		"users":   deviceUsers,
	})
}

// removeDeviceUser removes a specific user from a device
func (s *Server) removeDeviceUser(c *gin.Context) {
	deviceID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid device ID"})
		return
	}
	userID, err := strconv.ParseUint(c.Param("userId"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	result := s.db.Where("device_id = ? AND user_id = ?", deviceID, userID).Delete(&models.DeviceUser{})
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to remove user from device"})
		return
	}
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not assigned to this device"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "User removed from device"})
}

// listDevicesWithUsers returns all devices with their assigned users
func (s *Server) listDevicesWithUsers(c *gin.Context) {
	var devices []models.ClientDevice
	if err := s.db.Order("last_seen DESC").Preload("AssignedUsers.User").Find(&devices).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch devices"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"devices": devices})
}
