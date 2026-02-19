package api

import (
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/auth"
	"github.com/openflix/openflix-server/internal/library"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/openflix/openflix-server/internal/transcode"
	"gorm.io/gorm"
)

// Server identity - used by clients to identify this server
var (
	machineIdentifier = uuid.New().String()
	serverVersion     = "1.0.0"
	serverName        = "OpenFlix Server"
)

// ============ Server Info Handlers ============

func (s *Server) getServerInfo(c *gin.Context) {
	hostname, _ := os.Hostname()

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":              0,
			"machineIdentifier": machineIdentifier,
			"version":           serverVersion,
			"friendlyName":      serverName,
			"platform":          runtime.GOOS,
			"platformVersion":   runtime.Version(),
			"myPlex":            false,
			"myPlexMappingState": "unknown",
			"myPlexSigninState": "none",
			"transcoderActiveVideoSessions": 0,
		},
	})
	_ = hostname
}

func (s *Server) getServerIdentity(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":              0,
			"machineIdentifier": machineIdentifier,
			"version":           serverVersion,
			"friendlyName":      serverName,
		},
	})
}

func (s *Server) getServerPrefs(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size": 0,
			"Setting": []gin.H{
				{"id": "FriendlyName", "value": serverName},
				{"id": "MachineIdentifier", "value": machineIdentifier},
			},
		},
	})
}

// getServerStatus returns comprehensive server status for the dashboard
func (s *Server) getServerStatus(c *gin.Context) {
	hostname, _ := os.Hostname()

	// Count active sessions
	var sessionCount int64
	s.db.Model(&models.PlaybackSession{}).Where("state = ?", "playing").Count(&sessionCount)

	// Count libraries
	var libraryCount int64
	s.db.Model(&models.Library{}).Count(&libraryCount)

	// Count media items
	var movieCount, showCount, episodeCount int64
	s.db.Model(&models.MediaItem{}).Where("type = ?", "movie").Count(&movieCount)
	s.db.Model(&models.MediaItem{}).Where("type = ?", "show").Count(&showCount)
	s.db.Model(&models.MediaItem{}).Where("type = ?", "episode").Count(&episodeCount)

	// Count channels
	var channelCount int64
	s.db.Model(&models.Channel{}).Count(&channelCount)

	// DVR stats
	var scheduledRecordings, activeRecordings, completedRecordings int64
	s.db.Model(&models.Recording{}).Where("status = ?", "scheduled").Count(&scheduledRecordings)
	s.db.Model(&models.Recording{}).Where("status = ?", "recording").Count(&activeRecordings)
	s.db.Model(&models.Recording{}).Where("status = ?", "completed").Count(&completedRecordings)

	// Timeshift buffer status
	var timeshiftChannels []uint
	if s.timeshiftBuffer != nil {
		// Get list of channels being buffered
		var channels []models.Channel
		s.db.Find(&channels)
		for _, ch := range channels {
			if s.timeshiftBuffer.IsBuffering(ch.ID) {
				timeshiftChannels = append(timeshiftChannels, ch.ID)
			}
		}
	}

	// System info
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	c.JSON(http.StatusOK, gin.H{
		"server": gin.H{
			"name":              serverName,
			"version":           serverVersion,
			"hostname":          hostname,
			"machineIdentifier": machineIdentifier,
			"platform":          runtime.GOOS,
			"arch":              runtime.GOARCH,
			"goVersion":         runtime.Version(),
			"uptime":            time.Since(serverStartTime).String(),
		},
		"sessions": gin.H{
			"active": sessionCount,
		},
		"libraries": gin.H{
			"count":    libraryCount,
			"movies":   movieCount,
			"shows":    showCount,
			"episodes": episodeCount,
		},
		"livetv": gin.H{
			"channels":          channelCount,
			"timeshiftChannels": len(timeshiftChannels),
			"timeshiftEnabled":  s.timeshiftBuffer != nil,
		},
		"dvr": gin.H{
			"scheduled":        scheduledRecordings,
			"recording":        activeRecordings,
			"completed":        completedRecordings,
			"commercialDetect": s.recorder != nil && s.recorder.IsCommercialDetectionEnabled(),
		},
		"system": gin.H{
			"goroutines":   runtime.NumGoroutine(),
			"memAllocMB":   m.Alloc / 1024 / 1024,
			"memTotalMB":   m.TotalAlloc / 1024 / 1024,
			"numCPU":       runtime.NumCPU(),
		},
		"logging": gin.H{
			"level": s.config.Logging.Level,
			"json":  s.config.Logging.JSON,
		},
		"transcode": s.getTranscodeStatusInfo(),
	})
}

// getTranscodeStatusInfo returns transcoding status for the dashboard
func (s *Server) getTranscodeStatusInfo() gin.H {
	if s.transcoder == nil {
		return gin.H{
			"enabled":   false,
			"hwAccel":   "none",
			"available": false,
		}
	}

	hwInfo := transcode.DetectHardwareInfo(s.config.Transcode.FFmpegPath)

	return gin.H{
		"enabled":         true,
		"hwAccel":         s.transcoder.GetHardwareAccel(),
		"hwName":          hwInfo.Name,
		"gpuInfo":         hwInfo.GPUInfo,
		"activeSessions":  s.transcoder.GetActiveSessions(),
		"maxSessions":     s.config.Transcode.MaxSessions,
		"supportsHevc":    hwInfo.SupportsHEVC,
		"supportsAv1":     hwInfo.SupportsAV1,
		"maxResolution":   hwInfo.MaxResolution,
		"recommendedMode": hwInfo.RecommendedMode,
	}
}

// getTranscodeInfo returns detailed transcoding capabilities
func (s *Server) getTranscodeInfo(c *gin.Context) {
	hwInfo := transcode.DetectHardwareInfo(s.config.Transcode.FFmpegPath)

	transcodeEnabled := s.transcoder != nil
	activeSessions := 0
	var sessions []map[string]interface{}

	if s.transcoder != nil {
		activeSessions = s.transcoder.GetActiveSessions()
		sessions = s.transcoder.GetSessionInfo()
	}

	c.JSON(http.StatusOK, gin.H{
		"config": gin.H{
			"enabled":     transcodeEnabled,
			"ffmpegPath":  s.config.Transcode.FFmpegPath,
			"hwAccel":     s.config.Transcode.HardwareAccel,
			"tempDir":     s.config.Transcode.TempDir,
			"maxSessions": s.config.Transcode.MaxSessions,
		},
		"hardware": gin.H{
			"available":       hwInfo.Available,
			"type":            hwInfo.Type,
			"name":            hwInfo.Name,
			"gpuInfo":         hwInfo.GPUInfo,
			"encoders":        hwInfo.Encoders,
			"decoders":        hwInfo.Decoders,
			"supportsHevc":    hwInfo.SupportsHEVC,
			"supportsAv1":     hwInfo.SupportsAV1,
			"maxResolution":   hwInfo.MaxResolution,
			"recommendedMode": hwInfo.RecommendedMode,
			"detectedGpus":    hwInfo.DetectedGPUs,
			"missingSupport":  hwInfo.MissingSupport,
		},
		"sessions": gin.H{
			"active":  activeSessions,
			"max":     s.config.Transcode.MaxSessions,
			"details": sessions,
		},
		"playbackModes": []gin.H{
			{
				"id":          "direct_play",
				"name":        "Direct Play",
				"description": "Client plays original file directly. Best quality, no server load. Requires client support for the codec.",
			},
			{
				"id":          "direct_stream",
				"name":        "Direct Stream",
				"description": "Server remuxes without transcoding. Low server load. Audio/video unchanged.",
			},
			{
				"id":          "server_transcode",
				"name":        "Server Transcode",
				"description": "Server transcodes to compatible format. Works with any client but uses server resources.",
			},
		},
	})
}

// Track server start time for uptime
var serverStartTime = time.Now()

// ============ Logs Handlers ============

// getLogs returns recent log entries
func (s *Server) getLogs(c *gin.Context) {
	lines := 500 // Default to last 500 lines
	if l := c.Query("lines"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 5000 {
			lines = parsed
		}
	}

	logLines, err := logger.ReadLogFile(lines)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read logs: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"lines":   logLines,
		"count":   len(logLines),
		"path":    logger.GetLogFilePath(),
		"level":   s.config.Logging.Level,
	})
}

// clearLogs clears the log file
func (s *Server) clearLogs(c *gin.Context) {
	if err := logger.ClearLogFile(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to clear logs: " + err.Error()})
		return
	}

	logger.Info("Logs cleared by admin")
	c.JSON(http.StatusOK, gin.H{"message": "Logs cleared"})
}

// ============ Client Logs Handlers ============

// ClientLogEntry represents a log entry from a client app
type ClientLogEntry struct {
	Timestamp   string `json:"timestamp"`
	Level       string `json:"level"`
	Message     string `json:"message"`
	Error       string `json:"error,omitempty"`
	StackTrace  string `json:"stackTrace,omitempty"`
}

// ClientLogSubmission represents a batch of logs from a client
type ClientLogSubmission struct {
	DeviceInfo  map[string]interface{} `json:"deviceInfo"`
	AppVersion  string                 `json:"appVersion"`
	Platform    string                 `json:"platform"`
	Logs        []ClientLogEntry       `json:"logs"`
	SubmittedAt time.Time              `json:"submittedAt"`
	Username    string                 `json:"username"`
}

// In-memory storage for client logs (limited to last 100 submissions)
var clientLogStore = struct {
	submissions []ClientLogSubmission
	maxSize     int
}{
	submissions: make([]ClientLogSubmission, 0),
	maxSize:     100,
}

// submitClientLogs receives logs from client apps for troubleshooting
func (s *Server) submitClientLogs(c *gin.Context) {
	var req struct {
		DeviceInfo map[string]interface{} `json:"deviceInfo"`
		AppVersion string                 `json:"appVersion"`
		Platform   string                 `json:"platform"`
		Logs       []ClientLogEntry       `json:"logs"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	// Get username from token
	username := ""
	if user, exists := c.Get("user"); exists {
		if u, ok := user.(map[string]interface{}); ok {
			if name, ok := u["username"].(string); ok {
				username = name
			}
		}
	}

	submission := ClientLogSubmission{
		DeviceInfo:  req.DeviceInfo,
		AppVersion:  req.AppVersion,
		Platform:    req.Platform,
		Logs:        req.Logs,
		SubmittedAt: time.Now(),
		Username:    username,
	}

	// Add to store (circular buffer)
	clientLogStore.submissions = append(clientLogStore.submissions, submission)
	if len(clientLogStore.submissions) > clientLogStore.maxSize {
		clientLogStore.submissions = clientLogStore.submissions[1:]
	}

	logger.Infof("Received %d client logs from %s (%s/%s)", len(req.Logs), username, req.Platform, req.AppVersion)

	c.JSON(http.StatusOK, gin.H{
		"message": "Logs received",
		"count":   len(req.Logs),
	})
}

// getClientLogs returns all stored client log submissions
func (s *Server) getClientLogs(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"submissions": clientLogStore.submissions,
		"count":       len(clientLogStore.submissions),
	})
}

// clearClientLogs clears all stored client logs
func (s *Server) clearClientLogs(c *gin.Context) {
	clientLogStore.submissions = make([]ClientLogSubmission, 0)
	logger.Info("Client logs cleared by admin")
	c.JSON(http.StatusOK, gin.H{"message": "Client logs cleared"})
}

// ============ Auth Handlers ============

func (s *Server) register(c *gin.Context) {
	// Check if signup is allowed
	if !s.config.Auth.AllowSignup {
		// Check if there are any users - allow first user regardless
		users, _ := s.authService.GetAllUsers()
		if len(users) > 0 {
			c.JSON(http.StatusForbidden, gin.H{"error": "Registration is disabled"})
			return
		}
	}

	var input auth.RegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := s.authService.Register(input)
	if err != nil {
		if errors.Is(err, auth.ErrUserExists) {
			c.JSON(http.StatusConflict, gin.H{"error": "Username or email already exists"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, response)
}

func (s *Server) login(c *gin.Context) {
	var input auth.LoginInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := s.authService.Login(input)
	if err != nil {
		if errors.Is(err, auth.ErrInvalidCredentials) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid username or password"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, response)
}

func (s *Server) logout(c *gin.Context) {
	// JWT tokens are stateless, so just return success
	// In production, you might want to add token to a blacklist
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Admin User Management ============

func (s *Server) adminListUsers(c *gin.Context) {
	users, err := s.authService.GetAllUsers()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	userList := make([]gin.H, len(users))
	for i, user := range users {
		// Get profile count
		profiles, _ := s.authService.GetUserProfiles(user.ID)

		userList[i] = gin.H{
			"id":           user.ID,
			"uuid":         user.UUID,
			"username":     user.Username,
			"email":        user.Email,
			"title":        user.DisplayName,
			"thumb":        user.Thumb,
			"admin":        user.IsAdmin,
			"restricted":   user.IsRestricted,
			"profileCount": len(profiles),
			"createdAt":    user.CreatedAt,
		}
	}

	c.JSON(http.StatusOK, gin.H{"users": userList})
}

func (s *Server) adminDeleteUser(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	// Don't allow deleting yourself
	currentUserID, _ := c.Get("userID")
	if uint(id) == currentUserID.(uint) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot delete your own account"})
		return
	}

	if err := s.authService.DeleteUser(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) adminGetUserProfiles(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID"})
		return
	}

	profiles, err := s.authService.GetUserProfiles(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	profileList := make([]gin.H, len(profiles))
	for i, p := range profiles {
		profileList[i] = gin.H{
			"id":    p.ID,
			"uuid":  p.UUID,
			"name":  p.Name,
			"thumb": p.Thumb,
			"isKid": p.IsKid,
		}
	}

	c.JSON(http.StatusOK, gin.H{"profiles": profileList})
}

func (s *Server) getCurrentUser(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	user, err := s.authService.GetUserByID(userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       user.ID,
		"uuid":     user.UUID,
		"username": user.Username,
		"email":    user.Email,
		"title":    user.DisplayName,
		"thumb":    user.Thumb,
		"admin":    user.IsAdmin,
	})
}

func (s *Server) updateCurrentUser(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	var input auth.UpdateUserInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := s.authService.UpdateUser(userID.(uint), input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       user.ID,
		"uuid":     user.UUID,
		"username": user.Username,
		"email":    user.Email,
		"title":    user.DisplayName,
		"thumb":    user.Thumb,
		"admin":    user.IsAdmin,
	})
}

func (s *Server) changePassword(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	var input struct {
		OldPassword string `json:"oldPassword" binding:"required"`
		NewPassword string `json:"newPassword" binding:"required,min=6"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := s.authService.UpdatePassword(userID.(uint), input.OldPassword, input.NewPassword)
	if err != nil {
		if errors.Is(err, auth.ErrInvalidCredentials) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Current password is incorrect"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Profile Handlers ============

func (s *Server) getProfiles(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profiles, err := s.authService.GetUserProfiles(userID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	profileList := make([]gin.H, len(profiles))
	for i, p := range profiles {
		profileList[i] = gin.H{
			"id":    p.ID,
			"uuid":  p.UUID,
			"name":  p.Name,
			"thumb": p.Thumb,
			"isKid": p.IsKid,
		}
	}

	c.JSON(http.StatusOK, gin.H{"profiles": profileList})
}

func (s *Server) createProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	var input auth.CreateProfileInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, err := s.authService.CreateProfile(userID.(uint), input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":    profile.ID,
		"uuid":  profile.UUID,
		"name":  profile.Name,
		"thumb": profile.Thumb,
		"isKid": profile.IsKid,
	})
}

func (s *Server) getProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid profile ID"})
		return
	}

	profile, err := s.authService.GetProfile(uint(profileID), userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":    profile.ID,
		"uuid":  profile.UUID,
		"name":  profile.Name,
		"thumb": profile.Thumb,
		"isKid": profile.IsKid,
	})
}

func (s *Server) updateProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid profile ID"})
		return
	}

	var input auth.UpdateProfileInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	profile, err := s.authService.UpdateProfile(uint(profileID), userID.(uint), input)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":    profile.ID,
		"uuid":  profile.UUID,
		"name":  profile.Name,
		"thumb": profile.Thumb,
		"isKid": profile.IsKid,
	})
}

func (s *Server) deleteProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid profile ID"})
		return
	}

	err = s.authService.DeleteProfile(uint(profileID), userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) switchProfile(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Not authenticated"})
		return
	}

	profileID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid profile ID"})
		return
	}

	user, err := s.authService.GetUserByID(userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	token, err := s.authService.SwitchProfile(user, uint(profileID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"authToken": token})
}

// Plex-compatible auth endpoints

func (s *Server) createPin(c *gin.Context) {
	// Generate a PIN for authentication
	pin := s.authService.CreatePIN()
	c.JSON(http.StatusCreated, gin.H{
		"id":        pin.ID,
		"code":      pin.Code,
		"product":   "OpenFlix",
		"expiresAt": pin.ExpiresAt.Format(time.RFC3339),
		"authToken": pin.Token,
	})
}

func (s *Server) checkPin(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid PIN ID"})
		return
	}

	pin := s.authService.GetPIN(id)
	if pin == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "PIN not found"})
		return
	}

	if time.Now().After(pin.ExpiresAt) {
		c.JSON(http.StatusGone, gin.H{"error": "PIN expired"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":        pin.ID,
		"code":      pin.Code,
		"authToken": pin.Token, // Will be nil until claimed
	})
}

func (s *Server) getUser(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		// Return a default user for unauthenticated requests (dev mode)
		c.JSON(http.StatusOK, gin.H{
			"id":       0,
			"uuid":     uuid.New().String(),
			"username": "guest",
			"email":    "",
			"thumb":    "",
			"authToken": c.GetString("token"),
			"subscription": gin.H{
				"active": true,
			},
		})
		return
	}

	user, err := s.authService.GetUserByID(userID.(uint))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       user.ID,
		"uuid":     user.UUID,
		"username": user.Username,
		"email":    user.Email,
		"thumb":    user.Thumb,
		"authToken": c.GetString("token"),
		"subscription": gin.H{
			"active": true,
		},
	})
}

func (s *Server) getResources(c *gin.Context) {
	// Return this server as a resource
	c.JSON(http.StatusOK, []gin.H{
		{
			"name":             serverName,
			"product":          "OpenFlix Media Server",
			"productVersion":   serverVersion,
			"platform":         runtime.GOOS,
			"clientIdentifier": machineIdentifier,
			"accessToken":      c.GetString("token"),
			"provides":         "server",
			"owned":            true,
			"presence":         true,
			"connections": []gin.H{
				{
					"protocol": "http",
					"address":  s.config.Server.Host,
					"port":     s.config.Server.Port,
					"uri":      "http://" + s.config.Server.Host + ":32400",
					"local":    true,
					"relay":    false,
				},
			},
		},
	})
}

func (s *Server) getHomeUsers(c *gin.Context) {
	users, err := s.authService.GetAllUsers()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	userList := make([]gin.H, len(users))
	for i, user := range users {
		userList[i] = gin.H{
			"id":          user.ID,
			"uuid":        user.UUID,
			"title":       user.DisplayName,
			"username":    user.Username,
			"thumb":       user.Thumb,
			"hasPassword": user.HasPassword,
			"restricted":  user.IsRestricted,
			"admin":       user.IsAdmin,
			"guest":       false,
			"protected":   user.HasPassword,
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"id":    1,
		"name":  "OpenFlix Home",
		"users": userList,
	})
}

func (s *Server) switchUser(c *gin.Context) {
	userUUID := c.Param("uuid")

	// Get the user by UUID
	user, err := s.authService.GetUserByUUID(userUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Check if PIN is required
	pin := c.Query("pin")
	if user.HasPassword && user.PIN != "" && pin != user.PIN {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "PIN required"})
		return
	}

	// Generate new token for this user
	input := auth.LoginInput{
		Username: user.Username,
		Password: "", // Skip password check for user switch
	}
	_ = input // We'll generate token directly

	// For now, generate a simple token (in production, use proper auth flow)
	token, err := s.authService.SwitchProfile(user, 0)
	if err != nil {
		// Generate token using internal method
		c.JSON(http.StatusOK, gin.H{
			"authToken": "openflix-switch-" + userUUID,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"authToken": token,
	})
}

// ============ Library Handlers ============

func (s *Server) getLibrarySections(c *gin.Context) {
	libraries, err := s.libraryService.GetAllLibraries()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	sections := make([]gin.H, len(libraries))
	for i, lib := range libraries {
		// Get item count for this library
		count := s.libraryService.GetMediaItemCount(lib.ID)

		sections[i] = gin.H{
			"key":       strconv.Itoa(int(lib.ID)),
			"title":     lib.Title,
			"type":      lib.Type,
			"agent":     lib.Agent,
			"scanner":   lib.Scanner,
			"language":  lib.Language,
			"uuid":      lib.UUID,
			"updatedAt": lib.UpdatedAt.Unix(),
			"createdAt": lib.CreatedAt.Unix(),
			"count":     count,
		}
		if lib.ScannedAt != nil {
			sections[i]["scannedAt"] = lib.ScannedAt.Unix()
		}
	}
	s.respondWithDirectory(c, sections, len(sections))
}

func (s *Server) getLibraryContent(c *gin.Context) {
	libraryID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	offset, limit := s.getPaginationParams(c)

	// Get the library to determine its type
	lib, err := s.libraryService.GetLibrary(uint(libraryID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
		return
	}

	// Determine what type of items to fetch based on library type
	var itemTypes []string
	switch lib.Type {
	case "movie":
		itemTypes = []string{"movie"}
	case "show":
		itemTypes = []string{"show"} // For shows, return top-level shows
	default:
		itemTypes = []string{lib.Type}
	}

	// Get total count
	var totalCount int64
	s.db.Model(&models.MediaItem{}).
		Where("library_id = ? AND type IN ?", libraryID, itemTypes).
		Count(&totalCount)

	// Get paginated items
	var items []models.MediaItem
	query := s.db.Where("library_id = ? AND type IN ?", libraryID, itemTypes).
		Preload("MediaFiles").
		Preload("Genres").
		Order("sort_title ASC").
		Offset(offset).
		Limit(limit)

	if err := query.Find(&items).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Convert to Plex-compatible format
	metadata := make([]gin.H, len(items))
	for i, item := range items {
		metadata[i] = s.mediaItemToMetadata(&item, lib)
	}

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":             len(metadata),
			"totalSize":        totalCount,
			"offset":           offset,
			"librarySectionID": libraryID,
			"Metadata":         metadata,
		},
	})
}

func (s *Server) getLibraryFilters(c *gin.Context) {
	filters := []gin.H{
		{"filter": "genre", "filterType": "string", "title": "Genre"},
		{"filter": "year", "filterType": "integer", "title": "Year"},
		{"filter": "contentRating", "filterType": "string", "title": "Content Rating"},
		{"filter": "resolution", "filterType": "string", "title": "Resolution"},
	}
	s.respondWithDirectory(c, filters, len(filters))
}

func (s *Server) getLibrarySorts(c *gin.Context) {
	sorts := []gin.H{
		{"key": "titleSort", "title": "Title"},
		{"key": "addedAt:desc", "title": "Date Added"},
		{"key": "year:desc", "title": "Release Date"},
		{"key": "rating:desc", "title": "Rating"},
	}
	s.respondWithDirectory(c, sorts, len(sorts))
}

func (s *Server) getLibraryCollections(c *gin.Context) {
	libraryID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	// Get user collections from database
	var collections []models.Collection
	s.db.Where("library_id = ?", libraryID).Find(&collections)

	// Convert to response format
	result := make([]gin.H, len(collections))
	for i, col := range collections {
		result[i] = gin.H{
			"ratingKey":        col.ID,
			"key":              fmt.Sprintf("/library/collections/%d/children", col.ID),
			"guid":             col.UUID,
			"type":             "collection",
			"title":            col.Title,
			"summary":          col.Summary,
			"thumb":            col.Thumb,
			"art":              col.Art,
			"childCount":       col.ChildCount,
			"librarySectionID": col.LibraryID,
			"addedAt":          col.AddedAt.Unix(),
			"updatedAt":        col.UpdatedAt.Unix(),
		}
	}

	s.respondWithMediaContainer(c, result, len(result), len(result), 0)
}

func (s *Server) refreshLibrary(c *gin.Context) {
	libraryID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	lib, err := s.libraryService.GetLibrary(uint(libraryID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
		return
	}

	// Trigger scan in background
	go func() {
		s.scanner.ScanLibrary(lib)
	}()

	c.JSON(http.StatusOK, gin.H{"status": "scanning"})
}

// getLibraryFolders returns the folder structure for a library
func (s *Server) getLibraryFolders(c *gin.Context) {
	libraryID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	// Get library
	var lib models.Library
	if err := s.db.First(&lib, libraryID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
		return
	}

	// Get optional parent path from query
	parentPath := c.Query("parent")

	// Get library paths
	var paths []models.LibraryPath
	s.db.Where("library_id = ?", libraryID).Find(&paths)

	if parentPath == "" {
		// Return root folders (library paths)
		folders := make([]gin.H, 0, len(paths))
		for _, path := range paths {
			folders = append(folders, gin.H{
				"key":   fmt.Sprintf("/library/sections/%d/folder?parent=%s", libraryID, path.Path),
				"title": filepath.Base(path.Path),
				"path":  path.Path,
				"type":  "folder",
			})
		}
		s.respondWithMediaContainer(c, folders, len(folders), 0, 0)
		return
	}

	// Validate that the parent path is within a library path
	isValidPath := false
	for _, path := range paths {
		if strings.HasPrefix(parentPath, path.Path) {
			isValidPath = true
			break
		}
	}
	if !isValidPath {
		c.JSON(http.StatusForbidden, gin.H{"error": "Path not in library"})
		return
	}

	// Read directory contents
	entries, err := os.ReadDir(parentPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read directory"})
		return
	}

	// Build folder list
	items := make([]gin.H, 0)
	for _, entry := range entries {
		fullPath := filepath.Join(parentPath, entry.Name())

		if entry.IsDir() {
			// It's a folder
			items = append(items, gin.H{
				"key":   fmt.Sprintf("/library/sections/%d/folder?parent=%s", libraryID, fullPath),
				"title": entry.Name(),
				"path":  fullPath,
				"type":  "folder",
			})
		} else {
			// Check if it's a media file that's in our database
			ext := strings.ToLower(filepath.Ext(entry.Name()))
			videoExts := map[string]bool{
				".mp4": true, ".mkv": true, ".avi": true, ".mov": true,
				".wmv": true, ".flv": true, ".webm": true, ".m4v": true,
				".mpg": true, ".mpeg": true, ".ts": true, ".m2ts": true,
			}

			if videoExts[ext] {
				// Look up the media file in database
				var mediaFile models.MediaFile
				if err := s.db.Where("file_path = ?", fullPath).First(&mediaFile).Error; err == nil {
					// Found in database, include media item info
					var item models.MediaItem
					if err := s.db.First(&item, mediaFile.MediaItemID).Error; err == nil {
						items = append(items, gin.H{
							"ratingKey": item.ID,
							"key":       fmt.Sprintf("/library/metadata/%d", item.ID),
							"title":     item.Title,
							"path":      fullPath,
							"type":      item.Type,
							"thumb":     item.Thumb,
							"duration":  item.Duration,
							"year":      item.Year,
						})
					}
				} else {
					// Not in database, show as unmatched file
					items = append(items, gin.H{
						"title": entry.Name(),
						"path":  fullPath,
						"type":  "file",
					})
				}
			}
		}
	}

	s.respondWithMediaContainer(c, items, len(items), 0, 0)
}

func (s *Server) getLibraryHubs(c *gin.Context) {
	libraryID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	// Get library info
	var lib models.Library
	if err := s.db.First(&lib, libraryID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
		return
	}

	// Get user ID for personalized content
	userID, _ := c.Get("userID")
	profileID := c.GetUint("profileID")

	hubs := []gin.H{}

	// Limit items per hub
	hubLimit := 20

	// 1. Continue Watching Hub (for movies and episodes)
	continueWatchingItems := s.getContinueWatchingItems(uint(libraryID), userID, profileID, hubLimit)
	if len(continueWatchingItems) > 0 {
		hubs = append(hubs, gin.H{
			"key":           fmt.Sprintf("/hubs/sections/%d/continueWatching", libraryID),
			"hubIdentifier": "continueWatching",
			"type":          lib.Type,
			"title":         "Continue Watching",
			"size":          len(continueWatchingItems),
			"more":          len(continueWatchingItems) >= hubLimit,
			"style":         "shelf",
			"promoted":      true,
			"Metadata":      continueWatchingItems,
		})
	}

	// 2. Recently Added Hub
	recentlyAddedItems := s.getRecentlyAddedItems(uint(libraryID), lib.Type, hubLimit)
	if len(recentlyAddedItems) > 0 {
		hubs = append(hubs, gin.H{
			"key":           fmt.Sprintf("/hubs/sections/%d/recentlyAdded", libraryID),
			"hubIdentifier": "recentlyAdded",
			"type":          lib.Type,
			"title":         "Recently Added",
			"size":          len(recentlyAddedItems),
			"more":          len(recentlyAddedItems) >= hubLimit,
			"style":         "shelf",
			"Metadata":      recentlyAddedItems,
		})
	}

	// 3. Unwatched Hub (only for movie libraries and shows)
	unwatchedItems := s.getUnwatchedItems(uint(libraryID), lib.Type, userID, profileID, hubLimit)
	if len(unwatchedItems) > 0 {
		hubTitle := "Unwatched"
		if lib.Type == "show" {
			hubTitle = "Unwatched Shows"
		}
		hubs = append(hubs, gin.H{
			"key":           fmt.Sprintf("/hubs/sections/%d/unwatched", libraryID),
			"hubIdentifier": "unwatched",
			"type":          lib.Type,
			"title":         hubTitle,
			"size":          len(unwatchedItems),
			"more":          len(unwatchedItems) >= hubLimit,
			"style":         "shelf",
			"Metadata":      unwatchedItems,
		})
	}

	// 4. Recently Released (based on release date, not added date)
	if lib.Type == "movie" || lib.Type == "show" {
		recentlyReleasedItems := s.getRecentlyReleasedItems(uint(libraryID), lib.Type, hubLimit)
		if len(recentlyReleasedItems) > 0 {
			hubs = append(hubs, gin.H{
				"key":           fmt.Sprintf("/hubs/sections/%d/recentlyReleased", libraryID),
				"hubIdentifier": "recentlyReleased",
				"type":          lib.Type,
				"title":         "Recently Released",
				"size":          len(recentlyReleasedItems),
				"more":          len(recentlyReleasedItems) >= hubLimit,
				"style":         "shelf",
				"Metadata":      recentlyReleasedItems,
			})
		}
	}

	// 5. Top Rated Hub
	topRatedItems := s.getTopRatedItems(uint(libraryID), lib.Type, hubLimit)
	if len(topRatedItems) > 0 {
		hubs = append(hubs, gin.H{
			"key":           fmt.Sprintf("/hubs/sections/%d/topRated", libraryID),
			"hubIdentifier": "topRated",
			"type":          lib.Type,
			"title":         "Top Rated",
			"size":          len(topRatedItems),
			"more":          len(topRatedItems) >= hubLimit,
			"style":         "shelf",
			"Metadata":      topRatedItems,
		})
	}

	// 6. Streaming Service Hubs (Netflix, Disney+, etc.) - get top 8
	serviceHubs := s.getStreamingServiceHubs(uint(libraryID), lib.Type, hubLimit, 8)
	hubs = append(hubs, serviceHubs...)

	// 7. By Genre Hubs (get top 3 genres)
	genreHubs := s.getGenreHubs(uint(libraryID), lib.Type, hubLimit, 3)
	hubs = append(hubs, genreHubs...)

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":             len(hubs),
			"librarySectionID": libraryID,
			"Hub":              hubs,
		},
	})
}

// Smart Collection Helper Functions

func (s *Server) getContinueWatchingItems(libraryID uint, userID interface{}, profileID uint, limit int) []gin.H {
	if userID == nil {
		return []gin.H{}
	}

	var items []models.MediaItem
	// Get items that have been partially watched (viewOffset > 0 and not completed)
	query := s.db.Model(&models.MediaItem{}).
		Select("media_items.*").
		Joins("JOIN watch_histories ON watch_histories.media_item_id = media_items.id").
		Where("media_items.library_id = ?", libraryID).
		Where("watch_histories.user_id = ?", userID).
		Where("watch_histories.completed = ?", false).
		Where("watch_histories.view_offset > ?", 0).
		Where("media_items.type IN (?)", []string{"movie", "episode"}).
		Order("watch_histories.last_viewed_at DESC").
		Limit(limit)

	if profileID > 0 {
		query = query.Where("watch_histories.profile_id = ?", profileID)
	}

	query.Find(&items)

	// Get library for metadata
	var lib models.Library
	s.db.First(&lib, libraryID)

	result := make([]gin.H, len(items))
	for i, item := range items {
		result[i] = s.mediaItemToMetadata(&item, &lib)
		// Add view offset
		var history models.WatchHistory
		s.db.Where("media_item_id = ? AND user_id = ?", item.ID, userID).First(&history)
		result[i]["viewOffset"] = history.ViewOffset
	}
	return result
}

func (s *Server) getRecentlyAddedItems(libraryID uint, libType string, limit int) []gin.H {
	var items []models.MediaItem

	// For TV shows, get recently added shows (not episodes)
	itemType := libType
	if libType == "show" {
		itemType = "show"
	}

	s.db.Preload("Genres").
		Where("library_id = ? AND type = ?", libraryID, itemType).
		Order("added_at DESC").
		Limit(limit).
		Find(&items)

	var lib models.Library
	s.db.First(&lib, libraryID)

	result := make([]gin.H, len(items))
	for i, item := range items {
		result[i] = s.mediaItemToMetadata(&item, &lib)
	}
	return result
}

func (s *Server) getUnwatchedItems(libraryID uint, libType string, userID interface{}, profileID uint, limit int) []gin.H {
	var items []models.MediaItem

	itemType := libType
	if libType == "show" {
		itemType = "show"
	}

	query := s.db.Preload("Genres").
		Where("library_id = ? AND type = ?", libraryID, itemType)

	// Filter out watched items if user is logged in
	if userID != nil {
		subQuery := s.db.Model(&models.WatchHistory{}).
			Select("media_item_id").
			Where("user_id = ? AND completed = ?", userID, true)
		if profileID > 0 {
			subQuery = subQuery.Where("profile_id = ?", profileID)
		}
		query = query.Where("id NOT IN (?)", subQuery)
	}

	query.Order("added_at DESC").Limit(limit).Find(&items)

	var lib models.Library
	s.db.First(&lib, libraryID)

	result := make([]gin.H, len(items))
	for i, item := range items {
		result[i] = s.mediaItemToMetadata(&item, &lib)
	}
	return result
}

func (s *Server) getRecentlyReleasedItems(libraryID uint, libType string, limit int) []gin.H {
	var items []models.MediaItem

	itemType := libType
	if libType == "show" {
		itemType = "show"
	}

	// Get items released in the last 6 months
	sixMonthsAgo := time.Now().AddDate(0, -6, 0)

	s.db.Preload("Genres").
		Where("library_id = ? AND type = ? AND originally_available_at > ?", libraryID, itemType, sixMonthsAgo).
		Order("originally_available_at DESC").
		Limit(limit).
		Find(&items)

	var lib models.Library
	s.db.First(&lib, libraryID)

	result := make([]gin.H, len(items))
	for i, item := range items {
		result[i] = s.mediaItemToMetadata(&item, &lib)
	}
	return result
}

func (s *Server) getTopRatedItems(libraryID uint, libType string, limit int) []gin.H {
	var items []models.MediaItem

	itemType := libType
	if libType == "show" {
		itemType = "show"
	}

	s.db.Preload("Genres").
		Where("library_id = ? AND type = ? AND rating > ?", libraryID, itemType, 7.0).
		Order("rating DESC").
		Limit(limit).
		Find(&items)

	var lib models.Library
	s.db.First(&lib, libraryID)

	result := make([]gin.H, len(items))
	for i, item := range items {
		result[i] = s.mediaItemToMetadata(&item, &lib)
	}
	return result
}

func (s *Server) getGenreHubs(libraryID uint, libType string, itemLimit int, genreLimit int) []gin.H {
	itemType := libType
	if libType == "show" {
		itemType = "show"
	}

	// Get the most popular genres in this library
	var genreStats []struct {
		GenreID uint
		Tag     string
		Count   int64
	}

	s.db.Model(&models.Genre{}).
		Select("genres.id as genre_id, genres.tag, COUNT(*) as count").
		Joins("JOIN media_genres ON media_genres.genre_id = genres.id").
		Joins("JOIN media_items ON media_items.id = media_genres.media_item_id").
		Where("media_items.library_id = ? AND media_items.type = ?", libraryID, itemType).
		Group("genres.id, genres.tag").
		Order("count DESC").
		Limit(genreLimit).
		Scan(&genreStats)

	var lib models.Library
	s.db.First(&lib, libraryID)

	hubs := []gin.H{}

	for _, gs := range genreStats {
		var items []models.MediaItem
		s.db.Preload("Genres").
			Joins("JOIN media_genres ON media_genres.media_item_id = media_items.id").
			Where("media_items.library_id = ? AND media_items.type = ? AND media_genres.genre_id = ?",
				libraryID, itemType, gs.GenreID).
			Order("rating DESC, added_at DESC").
			Limit(itemLimit).
			Find(&items)

		if len(items) > 0 {
			metadata := make([]gin.H, len(items))
			for i, item := range items {
				metadata[i] = s.mediaItemToMetadata(&item, &lib)
			}

			hubs = append(hubs, gin.H{
				"key":           fmt.Sprintf("/hubs/sections/%d/genre/%d", libraryID, gs.GenreID),
				"hubIdentifier": fmt.Sprintf("genre.%d", gs.GenreID),
				"type":          libType,
				"title":         gs.Tag,
				"context":       "hub.genre",
				"size":          len(items),
				"more":          len(items) >= itemLimit,
				"style":         "shelf",
				"Metadata":      metadata,
			})
		}
	}

	return hubs
}

// getStreamingServices returns streaming service hubs for a specific library
func (s *Server) getStreamingServices(c *gin.Context) {
	libraryID, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	var lib models.Library
	if err := s.db.First(&lib, libraryID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
		return
	}

	hubLimit := 20
	serviceLimit := 20 // Get more services
	serviceHubs := s.getStreamingServiceHubs(uint(libraryID), lib.Type, hubLimit, serviceLimit)

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":             len(serviceHubs),
			"librarySectionID": libraryID,
			"Hub":              serviceHubs,
		},
	})
}

// getAllStreamingServices returns streaming service hubs from all libraries
func (s *Server) getAllStreamingServices(c *gin.Context) {
	// Get all libraries
	var libraries []models.Library
	s.db.Where("type IN (?)", []string{"movie", "show"}).Find(&libraries)

	allHubs := []gin.H{}
	hubLimit := 20
	serviceLimit := 10 // Top 10 per library

	for _, lib := range libraries {
		serviceHubs := s.getStreamingServiceHubs(lib.ID, lib.Type, hubLimit, serviceLimit)
		allHubs = append(allHubs, serviceHubs...)
	}

	// Deduplicate by service name (merge items from same service across libraries)
	mergedHubs := make(map[string]gin.H)
	for _, hub := range allHubs {
		title := hub["title"].(string)
		if existing, ok := mergedHubs[title]; ok {
			// Merge metadata from both hubs
			existingMeta := existing["Metadata"].([]gin.H)
			newMeta := hub["Metadata"].([]gin.H)
			existing["Metadata"] = append(existingMeta, newMeta...)
			existing["size"] = len(existing["Metadata"].([]gin.H))
		} else {
			mergedHubs[title] = hub
		}
	}

	// Convert back to slice
	finalHubs := make([]gin.H, 0, len(mergedHubs))
	for _, hub := range mergedHubs {
		finalHubs = append(finalHubs, hub)
	}

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size": len(finalHubs),
			"Hub":  finalHubs,
		},
	})
}

// getStreamingServiceHubs returns hubs for streaming services (Netflix, Disney+, etc.)
func (s *Server) getStreamingServiceHubs(libraryID uint, libType string, itemLimit int, serviceLimit int) []gin.H {
	itemType := libType
	if libType == "show" {
		itemType = "show"
	}

	// Get distinct parent categories (streaming services) with item counts
	var serviceStats []struct {
		ParentCategoryID string
		ParentCategory   string
		Count            int64
	}

	s.db.Model(&models.MediaItem{}).
		Select("xtream_parent_category_id as parent_category_id, xtream_parent_category as parent_category, COUNT(*) as count").
		Where("library_id = ? AND type = ? AND xtream_parent_category != ''", libraryID, itemType).
		Group("xtream_parent_category_id, xtream_parent_category").
		Order("count DESC").
		Limit(serviceLimit).
		Scan(&serviceStats)

	var lib models.Library
	s.db.First(&lib, libraryID)

	hubs := []gin.H{}

	for _, ss := range serviceStats {
		if ss.ParentCategory == "" || ss.ParentCategory == "All Movies" || ss.ParentCategory == "All Series" {
			continue // Skip generic categories
		}

		var items []models.MediaItem
		s.db.Preload("Genres").
			Where("library_id = ? AND type = ? AND xtream_parent_category_id = ?",
				libraryID, itemType, ss.ParentCategoryID).
			Order("rating DESC, added_at DESC").
			Limit(itemLimit).
			Find(&items)

		if len(items) > 0 {
			metadata := make([]gin.H, len(items))
			for i, item := range items {
				metadata[i] = s.mediaItemToMetadata(&item, &lib)
			}

			hubs = append(hubs, gin.H{
				"key":           fmt.Sprintf("/hubs/sections/%d/service/%s", libraryID, ss.ParentCategoryID),
				"hubIdentifier": fmt.Sprintf("service.%s", ss.ParentCategoryID),
				"type":          libType,
				"title":         ss.ParentCategory,
				"context":       "hub.streamingService",
				"size":          len(items),
				"more":          len(items) >= itemLimit,
				"style":         "shelf",
				"Metadata":      metadata,
			})
		}
	}

	return hubs
}

// ============ Helper Functions ============

// mediaItemToMetadata converts a MediaItem to Plex-compatible metadata format
func (s *Server) mediaItemToMetadata(item *models.MediaItem, lib *models.Library) gin.H {
	metadata := gin.H{
		"ratingKey":        item.ID,
		"key":              fmt.Sprintf("/library/metadata/%d", item.ID),
		"guid":             item.UUID,
		"type":             item.Type,
		"title":            item.Title,
		"librarySectionID": item.LibraryID,
		"addedAt":          item.AddedAt.Unix(),
		"updatedAt":        item.UpdatedAt.Unix(),
	}

	// Add optional fields if present
	if item.OriginalTitle != "" {
		metadata["originalTitle"] = item.OriginalTitle
	}
	if item.SortTitle != "" {
		metadata["titleSort"] = item.SortTitle
	}
	if item.Summary != "" {
		metadata["summary"] = item.Summary
	}
	if item.Tagline != "" {
		metadata["tagline"] = item.Tagline
	}
	if item.ContentRating != "" {
		metadata["contentRating"] = item.ContentRating
	}
	if item.Studio != "" {
		metadata["studio"] = item.Studio
	}
	if item.Year > 0 {
		metadata["year"] = item.Year
	}
	if item.Duration > 0 {
		metadata["duration"] = item.Duration
	}
	if item.Rating > 0 {
		metadata["rating"] = item.Rating
	}
	if item.AudienceRating > 0 {
		metadata["audienceRating"] = item.AudienceRating
	}
	if item.Thumb != "" {
		metadata["thumb"] = item.Thumb
	} else {
		// Generate placeholder thumb URL
		metadata["thumb"] = fmt.Sprintf("/library/metadata/%d/thumb", item.ID)
	}
	if item.Art != "" {
		metadata["art"] = item.Art
	}

	// Add hierarchy info for episodes/seasons
	if item.ParentID != nil {
		metadata["parentRatingKey"] = *item.ParentID
		metadata["parentKey"] = fmt.Sprintf("/library/metadata/%d", *item.ParentID)
	}
	if item.GrandparentID != nil {
		metadata["grandparentRatingKey"] = *item.GrandparentID
		metadata["grandparentKey"] = fmt.Sprintf("/library/metadata/%d", *item.GrandparentID)
	}
	if item.Index > 0 {
		metadata["index"] = item.Index
	}
	if item.ParentIndex > 0 {
		metadata["parentIndex"] = item.ParentIndex
	}
	if item.ParentTitle != "" {
		metadata["parentTitle"] = item.ParentTitle
	}
	if item.GrandparentTitle != "" {
		metadata["grandparentTitle"] = item.GrandparentTitle
	}
	if item.ParentThumb != "" {
		metadata["parentThumb"] = item.ParentThumb
	}
	if item.GrandparentThumb != "" {
		metadata["grandparentThumb"] = item.GrandparentThumb
	}

	// Add child/leaf counts for shows/seasons
	if item.ChildCount > 0 {
		metadata["childCount"] = item.ChildCount
	}
	if item.LeafCount > 0 {
		metadata["leafCount"] = item.LeafCount
	}
	if item.ViewedLeafCount > 0 {
		metadata["viewedLeafCount"] = item.ViewedLeafCount
	}

	// Add genres
	if len(item.Genres) > 0 {
		genres := make([]gin.H, len(item.Genres))
		for i, genre := range item.Genres {
			genres[i] = gin.H{"tag": genre.Tag}
		}
		metadata["Genre"] = genres
	}

	// Add cast, directors, writers
	if len(item.Cast) > 0 {
		var directors, writers, roles []gin.H
		for _, cast := range item.Cast {
			entry := gin.H{
				"tag":   cast.Tag,
				"role":  cast.Role,
				"thumb": cast.Thumb,
			}
			switch cast.Role {
			case "Director":
				directors = append(directors, gin.H{"tag": cast.Tag, "thumb": cast.Thumb})
			case "Writer", "Screenplay", "Story":
				writers = append(writers, gin.H{"tag": cast.Tag, "thumb": cast.Thumb})
			default:
				// Regular cast member (actor)
				roles = append(roles, entry)
			}
		}
		if len(directors) > 0 {
			metadata["Director"] = directors
		}
		if len(writers) > 0 {
			metadata["Writer"] = writers
		}
		if len(roles) > 0 {
			metadata["Role"] = roles
		}
	}

	// Add media files
	if len(item.MediaFiles) > 0 {
		media := make([]gin.H, len(item.MediaFiles))
		for i, file := range item.MediaFiles {
			media[i] = gin.H{
				"id":         file.ID,
				"duration":   file.Duration,
				"bitrate":    file.Bitrate,
				"width":      file.Width,
				"height":     file.Height,
				"container":  file.Container,
				"videoCodec": file.VideoCodec,
				"audioCodec": file.AudioCodec,
				"Part": []gin.H{
					{
						"id":        file.ID,
						"key":       fmt.Sprintf("/library/parts/%d/file", file.ID),
						"duration":  file.Duration,
						"file":      file.FilePath,
						"size":      file.FileSize,
						"container": file.Container,
					},
				},
			}
		}
		metadata["Media"] = media
	}

	return metadata
}

// ============ Metadata Handlers ============

func (s *Server) getMetadata(c *gin.Context) {
	key, err := strconv.ParseUint(c.Param("key"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid metadata key"})
		return
	}

	var item models.MediaItem
	if err := s.db.Preload("MediaFiles").Preload("Genres").Preload("Cast").First(&item, key).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	lib, _ := s.libraryService.GetLibrary(item.LibraryID)

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":     1,
			"Metadata": []gin.H{s.mediaItemToMetadata(&item, lib)},
		},
	})
}

func (s *Server) getMetadataChildren(c *gin.Context) {
	key, err := strconv.ParseUint(c.Param("key"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid metadata key"})
		return
	}

	// Get the parent item
	var parent models.MediaItem
	if err := s.db.First(&parent, key).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	lib, _ := s.libraryService.GetLibrary(parent.LibraryID)

	// Get children (seasons for shows, episodes for seasons)
	var children []models.MediaItem
	if err := s.db.Where("parent_id = ?", key).
		Preload("MediaFiles").
		Order("`index` ASC").
		Find(&children).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	metadata := make([]gin.H, len(children))
	for i, child := range children {
		// Add parent info to each child
		child.ParentTitle = parent.Title
		if parent.Type == "season" {
			child.ParentIndex = parent.Index
			// Get grandparent (show) info
			if parent.ParentID != nil {
				var show models.MediaItem
				if err := s.db.First(&show, parent.ParentID).Error; err == nil {
					child.GrandparentTitle = show.Title
					child.GrandparentThumb = show.Thumb
				}
			}
		}
		metadata[i] = s.mediaItemToMetadata(&child, lib)
	}

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size":                  len(metadata),
			"key":                   fmt.Sprintf("/library/metadata/%d/children", key),
			"parentRatingKey":       parent.ID,
			"parentTitle":           parent.Title,
			"parentYear":            parent.Year,
			"librarySectionID":      parent.LibraryID,
			"Metadata":              metadata,
		},
	})
}

// setMetadataPrefs sets audio/subtitle preferences for a media item
func (s *Server) setMetadataPrefs(c *gin.Context) {
	key := c.Param("key")

	// Parse the rating key (media item ID)
	id, err := strconv.ParseUint(key, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	// Get media item
	var item models.MediaItem
	if err := s.db.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media not found"})
		return
	}

	// Get the media file(s) for this item
	var files []models.MediaFile
	if err := s.db.Where("media_item_id = ?", item.ID).Find(&files).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get media files"})
		return
	}

	// Apply preferences from query params
	audioStreamID := c.Query("audioStreamID")
	subtitleStreamID := c.Query("subtitleStreamID")

	for _, file := range files {
		// Reset all stream selections for this file
		s.db.Model(&models.MediaStream{}).
			Where("media_file_id = ?", file.ID).
			Update("selected", false)

		// Select the requested audio stream
		if audioStreamID != "" {
			if streamID, err := strconv.ParseUint(audioStreamID, 10, 32); err == nil {
				s.db.Model(&models.MediaStream{}).
					Where("id = ? AND media_file_id = ? AND stream_type = 2", streamID, file.ID).
					Update("selected", true)
			}
		}

		// Select the requested subtitle stream (0 means none)
		if subtitleStreamID != "" && subtitleStreamID != "0" {
			if streamID, err := strconv.ParseUint(subtitleStreamID, 10, 32); err == nil {
				s.db.Model(&models.MediaStream{}).
					Where("id = ? AND media_file_id = ? AND stream_type = 3", streamID, file.ID).
					Update("selected", true)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// selectStreams selects audio/subtitle streams for a media file (part)
func (s *Server) selectStreams(c *gin.Context) {
	partID := c.Param("id")

	id, err := strconv.ParseUint(partID, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid part ID"})
		return
	}

	// Get the media file
	var file models.MediaFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media file not found"})
		return
	}

	// Parse stream selection from query params
	audioStreamID := c.Query("audioStreamID")
	subtitleStreamID := c.Query("subtitleStreamID")
	allParts := c.Query("allParts") == "1" // Apply to all parts of this media item

	// Get all files to update (either just this one or all parts)
	var files []models.MediaFile
	if allParts {
		s.db.Where("media_item_id = ?", file.MediaItemID).Find(&files)
	} else {
		files = []models.MediaFile{file}
	}

	for _, f := range files {
		// Reset audio selections for this file
		if audioStreamID != "" {
			s.db.Model(&models.MediaStream{}).
				Where("media_file_id = ? AND stream_type = 2", f.ID).
				Update("selected", false)

			// Select the requested audio stream
			if streamID, err := strconv.ParseUint(audioStreamID, 10, 32); err == nil {
				s.db.Model(&models.MediaStream{}).
					Where("id = ? AND media_file_id = ?", streamID, f.ID).
					Update("selected", true)
			}
		}

		// Reset subtitle selections
		if subtitleStreamID != "" {
			s.db.Model(&models.MediaStream{}).
				Where("media_file_id = ? AND stream_type = 3", f.ID).
				Update("selected", false)

			// Select the requested subtitle stream (0 means disable subtitles)
			if subtitleStreamID != "0" {
				if streamID, err := strconv.ParseUint(subtitleStreamID, 10, 32); err == nil {
					s.db.Model(&models.MediaStream{}).
						Where("id = ? AND media_file_id = ?", streamID, f.ID).
						Update("selected", true)
				}
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Browsing Handlers ============

func (s *Server) getRecentlyAdded(c *gin.Context) {
	offset, limit := s.getPaginationParams(c)
	if limit > 100 {
		limit = 100
	}

	// Get recently added movies and episodes (not shows/seasons which are containers)
	var items []models.MediaItem
	if err := s.db.Where("type IN ?", []string{"movie", "episode"}).
		Preload("MediaFiles").
		Order("added_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&items).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	metadata := make([]gin.H, len(items))
	for i, item := range items {
		lib, _ := s.libraryService.GetLibrary(item.LibraryID)
		metadata[i] = s.mediaItemToMetadata(&item, lib)
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), 0, offset)
}

func (s *Server) getOnDeck(c *gin.Context) {
	userID := c.GetUint("userID")

	// Get items with progress that are not completed
	var histories []models.WatchHistory
	s.db.Where("user_id = ? AND completed = ? AND view_offset > 0", userID, false).
		Order("last_viewed_at DESC").
		Limit(20).
		Find(&histories)

	if len(histories) == 0 {
		s.respondWithMediaContainer(c, []gin.H{}, 0, 0, 0)
		return
	}

	// Get the media item IDs
	itemIDs := make([]uint, len(histories))
	historyMap := make(map[uint]models.WatchHistory)
	for i, h := range histories {
		itemIDs[i] = h.MediaItemID
		historyMap[h.MediaItemID] = h
	}

	// Fetch the media items
	var items []models.MediaItem
	s.db.Preload("Files").Where("id IN ?", itemIDs).Find(&items)

	// Build response with view offset
	metadata := make([]gin.H, 0, len(items))
	for _, item := range items {
		var lib models.Library
		s.db.First(&lib, item.LibraryID)

		m := s.mediaItemToMetadata(&item, &lib)
		// Add view offset from history
		if h, ok := historyMap[item.ID]; ok {
			m["viewOffset"] = h.ViewOffset
		}
		metadata = append(metadata, m)
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), len(metadata), 0)
}

func (s *Server) search(c *gin.Context) {
	query := c.Query("query")
	if query == "" {
		c.JSON(http.StatusOK, gin.H{
			"MediaContainer": gin.H{
				"size": 0,
				"Hub":  []gin.H{},
			},
		})
		return
	}

	// Get limit parameter (default 10)
	limit := 10
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}

	// Search pattern for LIKE queries
	searchPattern := "%" + strings.ToLower(query) + "%"

	// Search for movies
	var movies []models.MediaItem
	s.db.Preload("Genres").
		Where("type = ? AND (LOWER(title) LIKE ? OR LOWER(original_title) LIKE ? OR LOWER(summary) LIKE ?)",
			"movie", searchPattern, searchPattern, searchPattern).
		Limit(limit).
		Find(&movies)

	// Search for TV shows
	var shows []models.MediaItem
	s.db.Preload("Genres").
		Where("type = ? AND (LOWER(title) LIKE ? OR LOWER(original_title) LIKE ? OR LOWER(summary) LIKE ?)",
			"show", searchPattern, searchPattern, searchPattern).
		Limit(limit).
		Find(&shows)

	// Build hubs (grouped results by type)
	hubs := []gin.H{}

	// Movie hub
	if len(movies) > 0 {
		movieMetadata := make([]gin.H, len(movies))
		for i, movie := range movies {
			var lib models.Library
			s.db.First(&lib, movie.LibraryID)
			movieMetadata[i] = s.mediaItemToMetadata(&movie, &lib)
		}
		hubs = append(hubs, gin.H{
			"type":          "movie",
			"hubIdentifier": "movie",
			"title":         "Movies",
			"size":          len(movies),
			"Metadata":      movieMetadata,
		})
	}

	// TV Shows hub
	if len(shows) > 0 {
		showMetadata := make([]gin.H, len(shows))
		for i, show := range shows {
			var lib models.Library
			s.db.First(&lib, show.LibraryID)
			showMetadata[i] = s.mediaItemToMetadata(&show, &lib)
		}
		hubs = append(hubs, gin.H{
			"type":          "show",
			"hubIdentifier": "show",
			"title":         "TV Shows",
			"size":          len(shows),
			"Metadata":      showMetadata,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"MediaContainer": gin.H{
			"size": len(movies) + len(shows),
			"Hub":  hubs,
		},
	})
}

// ============ Playback Handlers ============

func (s *Server) markWatched(c *gin.Context) {
	keyStr := c.Query("key")
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	userID := c.GetUint("userID")

	// Get or create watch history
	var history models.WatchHistory
	result := s.db.Where("user_id = ? AND media_item_id = ?", userID, key).First(&history)

	if result.Error != nil {
		// Create new history
		history = models.WatchHistory{
			UserID:       userID,
			MediaItemID:  uint(key),
			ViewCount:    1,
			LastViewedAt: time.Now(),
			Completed:    true,
		}
		s.db.Create(&history)
	} else {
		// Update existing
		s.db.Model(&history).Updates(map[string]interface{}{
			"view_count":     history.ViewCount + 1,
			"last_viewed_at": time.Now(),
			"completed":      true,
			"view_offset":    0, // Reset offset since it's complete
		})
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) markUnwatched(c *gin.Context) {
	keyStr := c.Query("key")
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	userID := c.GetUint("userID")

	// Delete watch history
	s.db.Where("user_id = ? AND media_item_id = ?", userID, key).Delete(&models.WatchHistory{})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) updateTimeline(c *gin.Context) {
	keyStr := c.Query("ratingKey")
	if keyStr == "" {
		keyStr = c.Query("key")
	}
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	// Get time/offset from query params
	timeStr := c.Query("time")
	offset, _ := strconv.ParseInt(timeStr, 10, 64)

	// Get duration for calculating completion
	durationStr := c.Query("duration")
	duration, _ := strconv.ParseInt(durationStr, 10, 64)

	// Check if state is stopped or playing
	state := c.Query("state")

	userID := c.GetUint("userID")

	// Determine if completed (watched 90% or more)
	completed := false
	if duration > 0 && offset > 0 {
		progress := float64(offset) / float64(duration)
		completed = progress >= 0.9
	}

	// Get or create watch history
	var history models.WatchHistory
	result := s.db.Where("user_id = ? AND media_item_id = ?", userID, key).First(&history)

	if result.Error != nil {
		// Create new history
		history = models.WatchHistory{
			UserID:       userID,
			MediaItemID:  uint(key),
			ViewOffset:   offset,
			ViewCount:    0,
			LastViewedAt: time.Now(),
			Completed:    completed,
		}
		s.db.Create(&history)
	} else {
		updates := map[string]interface{}{
			"view_offset":    offset,
			"last_viewed_at": time.Now(),
		}
		if completed && !history.Completed {
			updates["completed"] = true
			updates["view_count"] = history.ViewCount + 1
		}
		s.db.Model(&history).Updates(updates)
	}

	// If stopped and completed, increment view count
	if state == "stopped" && completed {
		s.db.Model(&history).Update("view_count", history.ViewCount+1)
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) removeFromContinueWatching(c *gin.Context) {
	keyStr := c.Query("ratingKey")
	if keyStr == "" {
		keyStr = c.Query("key")
	}
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	userID := c.GetUint("userID")

	// Mark as completed to remove from continue watching
	s.db.Model(&models.WatchHistory{}).
		Where("user_id = ? AND media_item_id = ?", userID, key).
		Updates(map[string]interface{}{
			"completed":   true,
			"view_offset": 0,
		})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// getSessions returns active playback sessions
func (s *Server) getSessions(c *gin.Context) {
	// Clean up stale sessions (inactive for more than 5 minutes)
	cutoff := time.Now().Add(-5 * time.Minute)
	s.db.Where("last_active_at < ? OR state = 'stopped'", cutoff).Delete(&models.PlaybackSession{})

	// Get active sessions with related data
	var sessions []models.PlaybackSession
	s.db.Where("state != 'stopped'").
		Order("started_at DESC").
		Find(&sessions)

	// Build response with enriched data
	metadata := make([]gin.H, 0, len(sessions))
	for _, session := range sessions {
		// Get user info
		var user models.User
		s.db.First(&user, session.UserID)

		// Get media item info
		var item models.MediaItem
		s.db.First(&item, session.MediaItemID)

		// Get media file info
		var file models.MediaFile
		s.db.First(&file, session.MediaFileID)

		sessionData := gin.H{
			"sessionKey":    session.ID,
			"ratingKey":     session.MediaItemID,
			"key":           fmt.Sprintf("/library/metadata/%d", session.MediaItemID),
			"title":         item.Title,
			"type":          item.Type,
			"thumb":         item.Thumb,
			"viewOffset":    session.ViewOffset,
			"duration":      session.Duration,
			"User": gin.H{
				"id":    user.ID,
				"title": user.DisplayName,
				"thumb": user.Thumb,
			},
			"Player": gin.H{
				"title":    session.ClientName,
				"platform": session.ClientPlatform,
				"address":  session.ClientAddress,
				"state":    session.State,
			},
		}

		// Add transcoding info if applicable
		if session.Transcoding {
			sessionData["TranscodeSession"] = gin.H{
				"key":     session.TranscodeSession,
				"quality": session.Quality,
			}
		}

		// Add video stream info if available
		if file.Width > 0 {
			sessionData["Media"] = []gin.H{{
				"width":      file.Width,
				"height":     file.Height,
				"videoCodec": file.VideoCodec,
				"audioCodec": file.AudioCodec,
				"container":  file.Container,
				"duration":   file.Duration,
			}}
		}

		metadata = append(metadata, sessionData)
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), 0, 0)
}

// startSession starts or updates a playback session
func (s *Server) startSession(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		RatingKey      uint   `json:"ratingKey"`
		MediaFileID    uint   `json:"mediaFileId"`
		ViewOffset     int64  `json:"viewOffset"`
		State          string `json:"state"`
		ClientName     string `json:"clientName"`
		ClientPlatform string `json:"clientPlatform"`
		Transcoding    bool   `json:"transcoding"`
		TranscodeKey   string `json:"transcodeKey"`
		Quality        string `json:"quality"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get media item duration
	var item models.MediaItem
	if err := s.db.First(&item, req.RatingKey).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media not found"})
		return
	}

	sessionID := uuid.New().String()
	session := models.PlaybackSession{
		ID:               sessionID,
		UserID:           userID,
		MediaItemID:      req.RatingKey,
		MediaFileID:      req.MediaFileID,
		State:            "playing",
		ViewOffset:       req.ViewOffset,
		Duration:         item.Duration,
		Progress:         float64(req.ViewOffset) / float64(item.Duration),
		Transcoding:      req.Transcoding,
		TranscodeSession: req.TranscodeKey,
		Quality:          req.Quality,
		ClientName:       req.ClientName,
		ClientPlatform:   req.ClientPlatform,
		ClientAddress:    c.ClientIP(),
		StartedAt:        time.Now(),
		LastActiveAt:     time.Now(),
	}

	if req.State != "" {
		session.State = req.State
	}

	if err := s.db.Create(&session).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create session"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"sessionKey": sessionID,
		"status":     "ok",
	})
}

// updateSession updates a playback session state
func (s *Server) updateSession(c *gin.Context) {
	sessionID := c.Param("id")

	var req struct {
		ViewOffset int64  `json:"viewOffset"`
		State      string `json:"state"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var session models.PlaybackSession
	if err := s.db.First(&session, "id = ?", sessionID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	updates := map[string]interface{}{
		"last_active_at": time.Now(),
	}

	if req.ViewOffset > 0 {
		updates["view_offset"] = req.ViewOffset
		if session.Duration > 0 {
			updates["progress"] = float64(req.ViewOffset) / float64(session.Duration)
		}
	}

	if req.State != "" {
		updates["state"] = req.State
	}

	s.db.Model(&session).Updates(updates)

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// stopSession stops a playback session
func (s *Server) stopSession(c *gin.Context) {
	sessionID := c.Param("id")

	result := s.db.Delete(&models.PlaybackSession{}, "id = ?", sessionID)
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Playlist Handlers ============

func (s *Server) getPlaylists(c *gin.Context) {
	userID := c.GetUint("userID")

	var playlists []models.Playlist
	s.db.Where("user_id = ?", userID).Find(&playlists)

	metadata := make([]gin.H, len(playlists))
	for i, p := range playlists {
		metadata[i] = gin.H{
			"ratingKey":    p.ID,
			"key":          fmt.Sprintf("/playlists/%d/items", p.ID),
			"guid":         p.UUID,
			"type":         "playlist",
			"title":        p.Title,
			"summary":      p.Summary,
			"playlistType": p.PlaylistType,
			"smart":        p.Smart,
			"leafCount":    p.LeafCount,
			"duration":     p.Duration,
			"addedAt":      p.AddedAt.Unix(),
			"updatedAt":    p.UpdatedAt.Unix(),
		}
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), len(metadata), 0)
}

func (s *Server) createPlaylist(c *gin.Context) {
	userID := c.GetUint("userID")

	title := c.Query("title")
	if title == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Title is required"})
		return
	}

	playlistType := c.Query("type")
	if playlistType == "" {
		playlistType = "video"
	}

	playlist := models.Playlist{
		UUID:         uuid.New().String(),
		UserID:       userID,
		Title:        title,
		PlaylistType: playlistType,
		AddedAt:      time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := s.db.Create(&playlist).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// If items provided, add them
	if uri := c.Query("uri"); uri != "" {
		// Parse server://uuid/com.plexapp.plugins.library/library/metadata/123
		// or just the key number
		parts := strings.Split(uri, "/")
		if len(parts) > 0 {
			keyStr := parts[len(parts)-1]
			if key, err := strconv.Atoi(keyStr); err == nil {
				item := models.PlaylistItem{
					PlaylistID:  playlist.ID,
					MediaItemID: uint(key),
					Order:       0,
				}
				s.db.Create(&item)
				playlist.LeafCount = 1
				s.db.Save(&playlist)
			}
		}
	}

	c.JSON(http.StatusCreated, gin.H{
		"MediaContainer": gin.H{
			"size": 1,
			"Metadata": []gin.H{{
				"ratingKey":    playlist.ID,
				"key":          fmt.Sprintf("/playlists/%d/items", playlist.ID),
				"guid":         playlist.UUID,
				"type":         "playlist",
				"title":        playlist.Title,
				"playlistType": playlist.PlaylistType,
				"leafCount":    playlist.LeafCount,
			}},
		},
	})
}

func (s *Server) getPlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	var playlist models.Playlist
	if err := s.db.First(&playlist, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Playlist not found"})
		return
	}

	metadata := []gin.H{{
		"ratingKey":    playlist.ID,
		"key":          fmt.Sprintf("/playlists/%d/items", playlist.ID),
		"guid":         playlist.UUID,
		"type":         "playlist",
		"title":        playlist.Title,
		"summary":      playlist.Summary,
		"playlistType": playlist.PlaylistType,
		"smart":        playlist.Smart,
		"leafCount":    playlist.LeafCount,
		"duration":     playlist.Duration,
		"addedAt":      playlist.AddedAt.Unix(),
		"updatedAt":    playlist.UpdatedAt.Unix(),
	}}

	s.respondWithMediaContainer(c, metadata, 1, 1, 0)
}

func (s *Server) getPlaylistItems(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	var items []models.PlaylistItem
	s.db.Where("playlist_id = ?", id).Order("`order` ASC").Find(&items)

	if len(items) == 0 {
		s.respondWithMediaContainer(c, []gin.H{}, 0, 0, 0)
		return
	}

	// Get media item IDs
	itemIDs := make([]uint, len(items))
	for i, item := range items {
		itemIDs[i] = item.MediaItemID
	}

	// Fetch media items
	var mediaItems []models.MediaItem
	s.db.Preload("Files").Where("id IN ?", itemIDs).Find(&mediaItems)

	// Build map for lookup
	mediaMap := make(map[uint]models.MediaItem)
	for _, m := range mediaItems {
		mediaMap[m.ID] = m
	}

	// Build response
	metadata := make([]gin.H, 0, len(items))
	for _, item := range items {
		if mi, ok := mediaMap[item.MediaItemID]; ok {
			var lib models.Library
			s.db.First(&lib, mi.LibraryID)
			m := s.mediaItemToMetadata(&mi, &lib)
			m["playlistItemID"] = item.ID
			metadata = append(metadata, m)
		}
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), len(metadata), 0)
}

func (s *Server) addToPlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	uri := c.Query("uri")
	if uri == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "URI is required"})
		return
	}

	// Parse the key from URI
	parts := strings.Split(uri, "/")
	keyStr := parts[len(parts)-1]
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid URI"})
		return
	}

	// Get current max order
	var maxOrder int
	s.db.Model(&models.PlaylistItem{}).Where("playlist_id = ?", id).Select("COALESCE(MAX(`order`), -1)").Scan(&maxOrder)

	// Create playlist item
	item := models.PlaylistItem{
		PlaylistID:  uint(id),
		MediaItemID: uint(key),
		Order:       maxOrder + 1,
	}
	s.db.Create(&item)

	// Update playlist counts
	var playlist models.Playlist
	s.db.First(&playlist, id)
	s.db.Model(&playlist).Updates(map[string]interface{}{
		"leaf_count": playlist.LeafCount + 1,
		"updated_at": time.Now(),
	})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) removeFromPlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	itemIDStr := c.Param("itemId")
	itemID, err := strconv.Atoi(itemIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	s.db.Delete(&models.PlaylistItem{}, itemID)

	// Update playlist counts
	var playlist models.Playlist
	s.db.First(&playlist, id)
	if playlist.LeafCount > 0 {
		s.db.Model(&playlist).Updates(map[string]interface{}{
			"leaf_count": playlist.LeafCount - 1,
			"updated_at": time.Now(),
		})
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) movePlaylistItem(c *gin.Context) {
	itemIDStr := c.Param("itemId")
	itemID, err := strconv.Atoi(itemIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	afterStr := c.Query("after")
	afterID, _ := strconv.Atoi(afterStr)

	var item models.PlaylistItem
	if err := s.db.First(&item, itemID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	// Get the order of the item after which to place
	newOrder := 0
	if afterID > 0 {
		var afterItem models.PlaylistItem
		if err := s.db.First(&afterItem, afterID).Error; err == nil {
			newOrder = afterItem.Order + 1
		}
	}

	// Update orders
	s.db.Model(&models.PlaylistItem{}).
		Where("playlist_id = ? AND `order` >= ?", item.PlaylistID, newOrder).
		Update("order", gorm.Expr("`order` + 1"))

	s.db.Model(&item).Update("order", newOrder)

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) clearPlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	s.db.Where("playlist_id = ?", id).Delete(&models.PlaylistItem{})

	// Update playlist
	s.db.Model(&models.Playlist{}).Where("id = ?", id).Updates(map[string]interface{}{
		"leaf_count": 0,
		"duration":   0,
		"updated_at": time.Now(),
	})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) deletePlaylist(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	userID := c.GetUint("userID")

	// Delete items first
	s.db.Where("playlist_id = ?", id).Delete(&models.PlaylistItem{})

	// Delete playlist (soft delete)
	s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Playlist{})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Watchlist Handlers ============

func (s *Server) getWatchlist(c *gin.Context) {
	userID := c.GetUint("userID")

	var items []models.WatchlistItem
	s.db.Where("user_id = ?", userID).Order("added_at DESC").Find(&items)

	if len(items) == 0 {
		s.respondWithMediaContainer(c, []gin.H{}, 0, 0, 0)
		return
	}

	// Get media item IDs
	itemIDs := make([]uint, len(items))
	for i, item := range items {
		itemIDs[i] = item.MediaItemID
	}

	// Fetch media items
	var mediaItems []models.MediaItem
	s.db.Where("id IN ?", itemIDs).Find(&mediaItems)

	// Create a map for quick lookup
	mediaMap := make(map[uint]models.MediaItem)
	for _, m := range mediaItems {
		mediaMap[m.ID] = m
	}

	// Build response in watchlist order
	metadata := make([]gin.H, 0, len(items))
	for _, item := range items {
		if m, ok := mediaMap[item.MediaItemID]; ok {
			metadata = append(metadata, gin.H{
				"ratingKey":     m.ID,
				"key":           fmt.Sprintf("/library/metadata/%d", m.ID),
				"guid":          m.UUID,
				"type":          m.Type,
				"title":         m.Title,
				"summary":       m.Summary,
				"thumb":         m.Thumb,
				"art":           m.Art,
				"year":          m.Year,
				"duration":      m.Duration,
				"addedAt":       item.AddedAt.Unix(),
				"contentRating": m.ContentRating,
			})
		}
	}

	s.respondWithMediaContainer(c, metadata, len(metadata), len(metadata), 0)
}

func (s *Server) addToWatchlist(c *gin.Context) {
	userID := c.GetUint("userID")

	mediaIDStr := c.Param("mediaId")
	mediaID, err := strconv.Atoi(mediaIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid media ID"})
		return
	}

	// Check if media item exists
	var mediaItem models.MediaItem
	if err := s.db.First(&mediaItem, mediaID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	// Check if already in watchlist
	var existing models.WatchlistItem
	if err := s.db.Where("user_id = ? AND media_item_id = ?", userID, mediaID).First(&existing).Error; err == nil {
		c.JSON(http.StatusOK, gin.H{"status": "already in watchlist"})
		return
	}

	// Add to watchlist
	item := models.WatchlistItem{
		UserID:      userID,
		MediaItemID: uint(mediaID),
		AddedAt:     time.Now(),
	}

	if err := s.db.Create(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"status": "ok"})
}

func (s *Server) removeFromWatchlist(c *gin.Context) {
	userID := c.GetUint("userID")

	mediaIDStr := c.Param("mediaId")
	mediaID, err := strconv.Atoi(mediaIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid media ID"})
		return
	}

	result := s.db.Where("user_id = ? AND media_item_id = ?", userID, mediaID).Delete(&models.WatchlistItem{})
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": result.Error.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// ============ Media Streaming Handlers ============

func (s *Server) streamMedia(c *gin.Context) {
	partIDStr := c.Param("partId")
	partID, err := strconv.Atoi(partIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid part ID"})
		return
	}

	// Get the media file
	var file models.MediaFile
	if err := s.db.First(&file, partID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media file not found"})
		return
	}

	// Check if this is a remote/Xtream VOD stream
	if strings.HasPrefix(file.FilePath, "xtream://") {
		s.streamXtreamVOD(c, &file)
		return
	}

	// Check if this is an M3U VOD stream
	if strings.HasPrefix(file.FilePath, "m3u://") {
		s.streamM3UVOD(c, &file)
		return
	}

	// Check if file exists on disk for local files
	if _, err := os.Stat(file.FilePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found on disk"})
		return
	}

	// Determine content type based on container
	contentType := "video/mp4"
	switch file.Container {
	case "mkv":
		contentType = "video/x-matroska"
	case "avi":
		contentType = "video/x-msvideo"
	case "mov":
		contentType = "video/quicktime"
	case "webm":
		contentType = "video/webm"
	case "ts", "m2ts":
		contentType = "video/mp2t"
	}

	// Set headers for streaming
	c.Header("Content-Type", contentType)
	c.Header("Accept-Ranges", "bytes")

	// Serve file with range request support
	c.File(file.FilePath)
}

// streamXtreamVOD proxies VOD/Series content from an Xtream source
func (s *Server) streamXtreamVOD(c *gin.Context, file *models.MediaFile) {
	// Parse the xtream:// URL format:
	// VOD: xtream://vod/{sourceID}/{streamID}.{ext}
	// Series: xtream://series/{sourceID}/{streamID}.{ext}
	var path string
	var urlType string // "movie" or "series"

	if strings.HasPrefix(file.FilePath, "xtream://vod/") {
		path = strings.TrimPrefix(file.FilePath, "xtream://vod/")
		urlType = "movie"
	} else if strings.HasPrefix(file.FilePath, "xtream://series/") {
		path = strings.TrimPrefix(file.FilePath, "xtream://series/")
		urlType = "series"
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid Xtream URL format"})
		return
	}

	parts := strings.SplitN(path, "/", 2)
	if len(parts) != 2 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid Xtream VOD path"})
		return
	}

	sourceIDStr := parts[0]
	streamFile := parts[1] // e.g., "600583.mp4" or "66732_1_1.mp4"

	sourceID, err := strconv.Atoi(sourceIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid Xtream source ID"})
		return
	}

	// Get the Xtream source
	var source models.XtreamSource
	if err := s.db.First(&source, sourceID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Xtream source not found"})
		return
	}

	// Extract stream ID and extension
	dotIdx := strings.LastIndex(streamFile, ".")
	if dotIdx == -1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid stream file format"})
		return
	}
	streamID := streamFile[:dotIdx]
	ext := streamFile[dotIdx+1:]

	// Build the actual VOD/Series URL:
	// VOD: http://server:port/movie/username/password/streamID.ext
	// Series: http://server:port/series/username/password/streamID.ext
	vodURL := fmt.Sprintf("%s/%s/%s/%s/%s.%s",
		strings.TrimSuffix(source.ServerURL, "/"),
		urlType,
		source.Username,
		source.Password,
		streamID,
		ext,
	)

	log.Printf("Proxying Xtream VOD: %s", vodURL)

	// Create HTTP request to fetch the VOD stream
	req, err := http.NewRequestWithContext(c.Request.Context(), "GET", vodURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
		return
	}

	// Forward range header if present
	if rangeHeader := c.GetHeader("Range"); rangeHeader != "" {
		req.Header.Set("Range", rangeHeader)
	}

	// Forward user-agent
	req.Header.Set("User-Agent", "OpenFlix/1.0")

	client := &http.Client{
		Timeout: 0, // No timeout for streaming
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			// Follow up to 10 redirects
			if len(via) >= 10 {
				return fmt.Errorf("too many redirects")
			}
			return nil
		},
	}

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Error fetching Xtream VOD: %v", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch VOD stream"})
		return
	}
	defer resp.Body.Close()

	// Get the base URL from the Xtream source for rewriting relative URLs
	remoteBase := strings.TrimSuffix(source.ServerURL, "/")

	// Build our proxy base URL for routing all M3U8/segment requests
	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	proxyBaseURL := fmt.Sprintf("%s://%s/livetv/xtream/proxy", scheme, c.Request.Host)

	// Check if response is an M3U8 playlist that needs URL rewriting
	contentType := resp.Header.Get("Content-Type")
	isM3U8 := strings.Contains(contentType, "mpegurl") ||
		strings.Contains(contentType, "x-mpegURL") ||
		strings.HasSuffix(vodURL, ".m3u8")

	if isM3U8 && resp.StatusCode == http.StatusOK {
		// Read the M3U8 content
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Printf("Error reading M3U8: %v", err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to read M3U8"})
			return
		}

		// Rewrite all URLs to go through our proxy
		content := rewriteM3U8ForProxy(string(body), remoteBase, proxyBaseURL)

		log.Printf("✅ Rewrote VOD M3U8 playlist - all URLs now routed through proxy: %s", proxyBaseURL)

		c.Header("Content-Type", "application/vnd.apple.mpegurl")
		c.Header("Content-Length", strconv.Itoa(len(content)))
		c.Header("Access-Control-Allow-Origin", "*")
		c.Status(http.StatusOK)
		c.Writer.WriteString(content)
		return
	}

	// Forward response headers for non-M3U8 content
	c.Header("Content-Type", contentType)
	if contentLength := resp.Header.Get("Content-Length"); contentLength != "" {
		c.Header("Content-Length", contentLength)
	}
	if contentRange := resp.Header.Get("Content-Range"); contentRange != "" {
		c.Header("Content-Range", contentRange)
	}
	c.Header("Accept-Ranges", "bytes")

	// Set appropriate status code
	c.Status(resp.StatusCode)

	// Stream the response body
	io.Copy(c.Writer, resp.Body)
}

// streamM3UVOD proxies VOD/Series content from an M3U source
func (s *Server) streamM3UVOD(c *gin.Context, file *models.MediaFile) {
	// For M3U VOD, the RemoteURL field contains the actual stream URL
	if file.RemoteURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No remote URL for M3U VOD"})
		return
	}

	log.Printf("Proxying M3U VOD: %s", file.RemoteURL)

	// Create HTTP request to fetch the VOD stream
	req, err := http.NewRequestWithContext(c.Request.Context(), "GET", file.RemoteURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
		return
	}

	// Forward range header if present
	if rangeHeader := c.GetHeader("Range"); rangeHeader != "" {
		req.Header.Set("Range", rangeHeader)
	}

	// Forward user-agent
	req.Header.Set("User-Agent", "OpenFlix/1.0")

	client := &http.Client{
		Timeout: 0, // No timeout for streaming
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return fmt.Errorf("too many redirects")
			}
			return nil
		},
	}

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Error fetching M3U VOD: %v", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch VOD stream"})
		return
	}
	defer resp.Body.Close()

	// Forward response headers
	contentType := resp.Header.Get("Content-Type")
	if contentType == "" {
		// Default to mp4 if no content type
		contentType = "video/mp4"
	}
	c.Header("Content-Type", contentType)
	if contentLength := resp.Header.Get("Content-Length"); contentLength != "" {
		c.Header("Content-Length", contentLength)
	}
	if contentRange := resp.Header.Get("Content-Range"); contentRange != "" {
		c.Header("Content-Range", contentRange)
	}
	c.Header("Accept-Ranges", "bytes")

	// Set appropriate status code
	c.Status(resp.StatusCode)

	// Stream the response body
	io.Copy(c.Writer, resp.Body)
}

// rewriteM3U8URIs rewrites relative URIs in M3U8 attributes to absolute URLs
func rewriteM3U8URIs(content, baseURL string) string {
	// Match URI="..." attributes and rewrite relative paths
	// Example: URI="/proxy-m3u8/..." -> URI="http://server/proxy-m3u8/..."

	// Simple approach: replace URI="/ with URI="baseURL/
	result := strings.ReplaceAll(content, `URI="/`, `URI="`+baseURL+`/`)

	return result
}

// rewriteM3U8ForProxy rewrites all URLs in M3U8 content to go through our proxy
func rewriteM3U8ForProxy(content, remoteBase, proxyBaseURL string) string {
	lines := strings.Split(content, "\n")
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		// Skip comment lines and empty lines
		if strings.HasPrefix(trimmed, "#") || trimmed == "" {
			// But check for URI= attributes in comment lines (e.g., EXT-X-KEY)
			if strings.Contains(trimmed, "URI=\"") {
				// Rewrite URI="..." to go through our proxy
				lines[i] = rewriteURIAttribute(line, remoteBase, proxyBaseURL)
			}
			continue
		}

		// Handle different URL formats
		var fullURL string
		if strings.HasPrefix(trimmed, "http://") || strings.HasPrefix(trimmed, "https://") {
			// Already absolute URL
			fullURL = trimmed
		} else if strings.HasPrefix(trimmed, "/") {
			// Relative to server root
			fullURL = remoteBase + trimmed
		} else {
			// Relative to current path - just use as is with remote base
			fullURL = remoteBase + "/" + trimmed
		}

		// Route through our proxy with URL encoding
		lines[i] = proxyBaseURL + "?url=" + url.QueryEscape(fullURL)
	}

	return strings.Join(lines, "\n")
}

// rewriteURIAttribute rewrites URI="..." attributes in M3U8 tags
func rewriteURIAttribute(line, remoteBase, proxyBaseURL string) string {
	// Find URI="..." and rewrite it
	uriIdx := strings.Index(line, `URI="`)
	if uriIdx == -1 {
		return line
	}

	// Find the closing quote
	startIdx := uriIdx + 5 // After URI="
	endIdx := strings.Index(line[startIdx:], `"`)
	if endIdx == -1 {
		return line
	}
	endIdx += startIdx

	uri := line[startIdx:endIdx]

	// Make absolute URL
	var fullURL string
	if strings.HasPrefix(uri, "http://") || strings.HasPrefix(uri, "https://") {
		fullURL = uri
	} else if strings.HasPrefix(uri, "/") {
		fullURL = remoteBase + uri
	} else {
		fullURL = remoteBase + "/" + uri
	}

	// Route through proxy with URL encoding
	proxyURL := proxyBaseURL + "?url=" + url.QueryEscape(fullURL)

	return line[:startIdx] + proxyURL + line[endIdx:]
}

// proxyXtreamM3U8 proxies M3U8 content from Xtream servers and rewrites URLs
func (s *Server) proxyXtreamM3U8(c *gin.Context) {
	targetURL := c.Query("url")
	if targetURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "URL parameter required"})
		return
	}

	log.Printf("🔄 Proxying M3U8/segment: %s", targetURL)

	// Parse the URL to get the base
	parsedURL, err := http.NewRequest("GET", targetURL, nil)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid URL"})
		return
	}

	// Get base URL for rewriting relative paths
	remoteBase := parsedURL.URL.Scheme + "://" + parsedURL.URL.Host

	// Build our proxy base URL
	scheme := "http"
	if c.Request.TLS != nil {
		scheme = "https"
	}
	proxyBaseURL := fmt.Sprintf("%s://%s/livetv/xtream/proxy", scheme, c.Request.Host)

	// Create HTTP request
	req, err := http.NewRequestWithContext(c.Request.Context(), "GET", targetURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
		return
	}

	// Forward range header if present
	if rangeHeader := c.GetHeader("Range"); rangeHeader != "" {
		req.Header.Set("Range", rangeHeader)
	}
	req.Header.Set("User-Agent", "OpenFlix/1.0")

	client := &http.Client{
		Timeout: 30 * time.Second,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return fmt.Errorf("too many redirects")
			}
			return nil
		},
	}

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Error fetching from Xtream: %v", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch content"})
		return
	}
	defer resp.Body.Close()

	// Check if this is an M3U8 playlist
	contentType := resp.Header.Get("Content-Type")
	isM3U8 := strings.Contains(contentType, "mpegurl") ||
		strings.Contains(contentType, "x-mpegURL") ||
		strings.HasSuffix(targetURL, ".m3u8")

	if isM3U8 && resp.StatusCode == http.StatusOK {
		// Read and rewrite M3U8 content
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Printf("Error reading M3U8: %v", err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to read M3U8"})
			return
		}

		content := rewriteM3U8ForProxy(string(body), remoteBase, proxyBaseURL)

		log.Printf("✅ Rewrote M3U8 with proxy base: %s", proxyBaseURL)

		c.Header("Content-Type", "application/vnd.apple.mpegurl")
		c.Header("Content-Length", strconv.Itoa(len(content)))
		c.Header("Access-Control-Allow-Origin", "*")
		c.Status(http.StatusOK)
		c.Writer.WriteString(content)
		return
	}

	// For non-M3U8 content (segments), just proxy through
	contentLength := resp.Header.Get("Content-Length")
	displayURL := targetURL
	if len(displayURL) > 100 {
		displayURL = displayURL[:100] + "..."
	}
	log.Printf("📦 Proxying segment: %s (type=%s, size=%s)", displayURL, contentType, contentLength)

	c.Header("Content-Type", contentType)
	if contentLength != "" {
		c.Header("Content-Length", contentLength)
	}
	if contentRange := resp.Header.Get("Content-Range"); contentRange != "" {
		c.Header("Content-Range", contentRange)
	}
	c.Header("Accept-Ranges", "bytes")
	c.Header("Access-Control-Allow-Origin", "*")
	c.Status(resp.StatusCode)

	written, err := io.Copy(c.Writer, resp.Body)
	if err != nil {
		log.Printf("❌ Error copying segment data: %v", err)
	} else {
		log.Printf("✅ Segment delivered: %d bytes", written)
	}
}

func (s *Server) transcodeStart(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	// Get parameters
	path := c.Query("path")
	if path == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Path is required"})
		return
	}

	// Parse media key from path (e.g., /library/metadata/123)
	parts := strings.Split(path, "/")
	var mediaKey int
	for i, p := range parts {
		if p == "metadata" && i+1 < len(parts) {
			mediaKey, _ = strconv.Atoi(parts[i+1])
			break
		}
	}

	if mediaKey == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid path"})
		return
	}

	// Get media item
	var item models.MediaItem
	if err := s.db.First(&item, mediaKey).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media not found"})
		return
	}

	// Get media file
	var file models.MediaFile
	if err := s.db.Where("media_item_id = ?", mediaKey).First(&file).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No media file found"})
		return
	}

	// Get quality/offset parameters
	offset, _ := strconv.ParseInt(c.Query("offset"), 10, 64)
	quality := c.DefaultQuery("videoQuality", "original")

	// Start transcode session
	session, err := s.transcoder.StartSession(file.ID, file.FilePath, offset, quality)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Wait a moment for transcoding to start and generate initial segment
	time.Sleep(500 * time.Millisecond)

	// Return HLS playlist
	playlistPath := s.transcoder.GetPlaylistPath(session.ID)
	c.Header("Content-Type", "application/vnd.apple.mpegurl")
	c.File(playlistPath)
}

func (s *Server) transcodeSegment(c *gin.Context) {
	if s.transcoder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Transcoding not enabled"})
		return
	}

	sessionID := c.Param("sessionId")
	segment := c.Param("segment")

	// Validate session
	session := s.transcoder.GetSession(sessionID)
	if session == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	// Update last access time
	s.transcoder.UpdateLastAccess(sessionID)

	// Get segment path
	segmentPath := s.transcoder.GetSegmentPath(sessionID, segment)

	// Wait for segment to be available (with timeout)
	timeout := time.After(30 * time.Second)
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-timeout:
			c.JSON(http.StatusRequestTimeout, gin.H{"error": "Segment not available"})
			return
		case <-ticker.C:
			if _, err := os.Stat(segmentPath); err == nil {
				c.Header("Content-Type", "video/mp2t")
				c.File(segmentPath)
				return
			}
		case <-session.Done:
			if session.Error != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Transcode failed"})
				return
			}
			// Check one more time
			if _, err := os.Stat(segmentPath); err == nil {
				c.Header("Content-Type", "video/mp2t")
				c.File(segmentPath)
				return
			}
			c.JSON(http.StatusNotFound, gin.H{"error": "Segment not found"})
			return
		}
	}
}

// getThumbSimple handles /library/metadata/:key/thumb (without thumbId)
func (s *Server) getThumbSimple(c *gin.Context) {
	s.getThumb(c)
}

// getArtSimple handles /library/metadata/:key/art (without artId)
func (s *Server) getArtSimple(c *gin.Context) {
	s.getArt(c)
}

func (s *Server) getThumb(c *gin.Context) {
	keyStr := c.Param("key")
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	// Get media item
	var item models.MediaItem
	if err := s.db.First(&item, key).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	// If no thumb URL, try to generate a placeholder or return 404
	if item.Thumb == "" {
		// Return a placeholder image or 404
		c.JSON(http.StatusNotFound, gin.H{"error": "No poster available"})
		return
	}

	// Check if we have a local copy
	dataDir := s.config.GetDataDir()
	localPath := filepath.Join(dataDir, "metadata", "posters", fmt.Sprintf("%d.jpg", item.ID))

	if _, err := os.Stat(localPath); err == nil {
		// Serve local file
		c.Header("Cache-Control", "public, max-age=86400")
		c.File(localPath)
		return
	}

	// Redirect to TMDB URL
	// Convert relative TMDB path to full URL if needed
	posterURL := item.Thumb
	if strings.HasPrefix(posterURL, "/") {
		posterURL = "https://image.tmdb.org/t/p/w500" + posterURL
	}

	c.Redirect(http.StatusTemporaryRedirect, posterURL)
}

func (s *Server) getArt(c *gin.Context) {
	keyStr := c.Param("key")
	key, err := strconv.Atoi(keyStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid key"})
		return
	}

	// Get media item
	var item models.MediaItem
	if err := s.db.First(&item, key).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	// If no art URL, return 404
	if item.Art == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "No art available"})
		return
	}

	// Check if we have a local copy
	dataDir := s.config.GetDataDir()
	localPath := filepath.Join(dataDir, "metadata", "backdrops", fmt.Sprintf("%d.jpg", item.ID))

	if _, err := os.Stat(localPath); err == nil {
		// Serve local file
		c.Header("Cache-Control", "public, max-age=86400")
		c.File(localPath)
		return
	}

	// Redirect to TMDB URL
	// Convert relative TMDB path to full URL if needed
	artURL := item.Art
	if strings.HasPrefix(artURL, "/") {
		artURL = "https://image.tmdb.org/t/p/original" + artURL
	}

	c.Redirect(http.StatusTemporaryRedirect, artURL)
}

// ============ Admin Library Management Handlers ============

func (s *Server) adminGetLibraries(c *gin.Context) {
	libraries, err := s.libraryService.GetAllLibraries()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	result := make([]gin.H, len(libraries))
	for i, lib := range libraries {
		paths := make([]gin.H, len(lib.Paths))
		for j, p := range lib.Paths {
			paths[j] = gin.H{"id": p.ID, "path": p.Path}
		}

		result[i] = gin.H{
			"id":        lib.ID,
			"uuid":      lib.UUID,
			"title":     lib.Title,
			"type":      lib.Type,
			"agent":     lib.Agent,
			"scanner":   lib.Scanner,
			"language":  lib.Language,
			"hidden":    lib.Hidden,
			"paths":     paths,
			"itemCount": s.libraryService.GetMediaItemCount(lib.ID),
			"createdAt": lib.CreatedAt.Unix(),
			"updatedAt": lib.UpdatedAt.Unix(),
		}
		if lib.ScannedAt != nil {
			result[i]["scannedAt"] = lib.ScannedAt.Unix()
		}
	}

	c.JSON(http.StatusOK, gin.H{"libraries": result})
}

func (s *Server) adminCreateLibrary(c *gin.Context) {
	var input library.CreateLibraryInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	lib, err := s.libraryService.CreateLibrary(input)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	paths := make([]gin.H, len(lib.Paths))
	for i, p := range lib.Paths {
		paths[i] = gin.H{"id": p.ID, "path": p.Path}
	}

	c.JSON(http.StatusCreated, gin.H{
		"id":       lib.ID,
		"uuid":     lib.UUID,
		"title":    lib.Title,
		"type":     lib.Type,
		"agent":    lib.Agent,
		"scanner":  lib.Scanner,
		"language": lib.Language,
		"paths":    paths,
	})
}

func (s *Server) adminGetLibrary(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	lib, err := s.libraryService.GetLibrary(uint(id))
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	paths := make([]gin.H, len(lib.Paths))
	for i, p := range lib.Paths {
		paths[i] = gin.H{"id": p.ID, "path": p.Path}
	}

	c.JSON(http.StatusOK, gin.H{
		"id":        lib.ID,
		"uuid":      lib.UUID,
		"title":     lib.Title,
		"type":      lib.Type,
		"agent":     lib.Agent,
		"scanner":   lib.Scanner,
		"language":  lib.Language,
		"hidden":    lib.Hidden,
		"paths":     paths,
		"itemCount": s.libraryService.GetMediaItemCount(lib.ID),
	})
}

func (s *Server) adminUpdateLibrary(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	var input library.UpdateLibraryInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	lib, err := s.libraryService.UpdateLibrary(uint(id), input)
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"id":       lib.ID,
		"uuid":     lib.UUID,
		"title":    lib.Title,
		"type":     lib.Type,
		"language": lib.Language,
		"hidden":   lib.Hidden,
	})
}

func (s *Server) adminDeleteLibrary(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	err = s.libraryService.DeleteLibrary(uint(id))
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) adminAddLibraryPath(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	var input struct {
		Path string `json:"path" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = s.libraryService.AddPath(uint(id), input.Path)
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		if errors.Is(err, library.ErrInvalidPath) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid path - must be an absolute path to an existing directory"})
			return
		}
		if errors.Is(err, library.ErrPathExists) {
			c.JSON(http.StatusConflict, gin.H{"error": "Path already exists in library"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return updated library
	lib, _ := s.libraryService.GetLibrary(uint(id))
	paths := make([]gin.H, len(lib.Paths))
	for i, p := range lib.Paths {
		paths[i] = gin.H{"id": p.ID, "path": p.Path}
	}

	c.JSON(http.StatusOK, gin.H{"paths": paths})
}

func (s *Server) adminRemoveLibraryPath(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	pathId, err := strconv.ParseUint(c.Param("pathId"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid path ID"})
		return
	}

	err = s.libraryService.RemovePath(uint(id), uint(pathId))
	if err != nil {
		if errors.Is(err, library.ErrPathNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Path not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func (s *Server) adminScanLibrary(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	lib, err := s.libraryService.GetLibrary(uint(id))
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Run scan (this could be async in production)
	result, err := s.scanner.ScanLibrary(lib)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"libraryId":    result.LibraryID,
		"filesFound":   result.FilesFound,
		"filesAdded":   result.FilesAdded,
		"filesUpdated": result.FilesUpdated,
		"filesRemoved": result.FilesRemoved,
		"errors":       result.Errors,
	})
}

// adminGetLibraryStats returns statistics for a library
func (s *Server) adminGetLibraryStats(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid library ID"})
		return
	}

	lib, err := s.libraryService.GetLibrary(uint(id))
	if err != nil {
		if errors.Is(err, library.ErrLibraryNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Library not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Count items by type
	var movieCount, showCount, seasonCount, episodeCount int64
	s.db.Model(&models.MediaItem{}).Where("library_id = ? AND type = ?", lib.ID, "movie").Count(&movieCount)
	s.db.Model(&models.MediaItem{}).Where("library_id = ? AND type = ?", lib.ID, "show").Count(&showCount)
	s.db.Model(&models.MediaItem{}).Where("library_id = ? AND type = ?", lib.ID, "season").Count(&seasonCount)
	s.db.Model(&models.MediaItem{}).Where("library_id = ? AND type = ?", lib.ID, "episode").Count(&episodeCount)

	// Calculate total file size
	var totalSize int64
	s.db.Model(&models.MediaFile{}).
		Joins("JOIN media_items ON media_items.id = media_files.media_item_id").
		Where("media_items.library_id = ?", lib.ID).
		Select("COALESCE(SUM(media_files.file_size), 0)").
		Scan(&totalSize)

	// Count total files
	var fileCount int64
	s.db.Model(&models.MediaFile{}).
		Joins("JOIN media_items ON media_items.id = media_files.media_item_id").
		Where("media_items.library_id = ?", lib.ID).
		Count(&fileCount)

	// Calculate total duration
	var totalDuration int64
	s.db.Model(&models.MediaItem{}).
		Where("library_id = ? AND duration > 0", lib.ID).
		Select("COALESCE(SUM(duration), 0)").
		Scan(&totalDuration)

	c.JSON(http.StatusOK, gin.H{
		"libraryId":    lib.ID,
		"movieCount":   movieCount,
		"showCount":    showCount,
		"seasonCount":  seasonCount,
		"episodeCount": episodeCount,
		"fileCount":    fileCount,
		"totalSize":    totalSize,
		"totalDuration": totalDuration,
	})
}

// FileSystemEntry represents a file or directory in the filesystem
type FileSystemEntry struct {
	Name    string `json:"name"`
	Path    string `json:"path"`
	IsDir   bool   `json:"isDir"`
	Size    int64  `json:"size,omitempty"`
	ModTime int64  `json:"modTime,omitempty"`
}

// adminBrowseFilesystem lists directories for path selection
func (s *Server) adminBrowseFilesystem(c *gin.Context) {
	path := c.DefaultQuery("path", "")

	// If no path specified, return common root paths
	if path == "" {
		roots := getSystemRoots()
		c.JSON(http.StatusOK, gin.H{
			"path":    "/",
			"entries": roots,
		})
		return
	}

	// Clean and validate the path
	cleanPath := filepath.Clean(path)

	// Check if path exists
	info, err := os.Stat(cleanPath)
	if err != nil {
		if os.IsNotExist(err) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Path not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// If it's a file, return its parent directory
	if !info.IsDir() {
		cleanPath = filepath.Dir(cleanPath)
	}

	// Read directory contents
	entries, err := os.ReadDir(cleanPath)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Cannot access directory"})
		return
	}

	// Filter and format entries (directories only for path selection, but show files for context)
	result := make([]FileSystemEntry, 0, len(entries))
	for _, entry := range entries {
		// Skip hidden files/directories (starting with .)
		if strings.HasPrefix(entry.Name(), ".") {
			continue
		}

		entryPath := filepath.Join(cleanPath, entry.Name())
		fsEntry := FileSystemEntry{
			Name:  entry.Name(),
			Path:  entryPath,
			IsDir: entry.IsDir(),
		}

		// Get additional info for files
		if info, err := entry.Info(); err == nil {
			fsEntry.Size = info.Size()
			fsEntry.ModTime = info.ModTime().Unix()
		}

		result = append(result, fsEntry)
	}

	// Sort: directories first, then alphabetically
	sortFileEntries(result)

	// Get parent path
	parentPath := filepath.Dir(cleanPath)
	if parentPath == cleanPath {
		parentPath = "" // At root
	}

	c.JSON(http.StatusOK, gin.H{
		"path":       cleanPath,
		"parentPath": parentPath,
		"entries":    result,
	})
}

// getSystemRoots returns common root paths based on OS
func getSystemRoots() []FileSystemEntry {
	roots := []FileSystemEntry{}

	switch runtime.GOOS {
	case "darwin":
		// macOS
		homeDir, _ := os.UserHomeDir()
		roots = append(roots,
			FileSystemEntry{Name: "Root", Path: "/", IsDir: true},
			FileSystemEntry{Name: "Home", Path: homeDir, IsDir: true},
			FileSystemEntry{Name: "Volumes", Path: "/Volumes", IsDir: true},
		)
		// Check for common media locations
		if info, err := os.Stat("/Volumes"); err == nil && info.IsDir() {
			if entries, err := os.ReadDir("/Volumes"); err == nil {
				for _, e := range entries {
					if e.IsDir() && e.Name() != "Macintosh HD" {
						roots = append(roots, FileSystemEntry{
							Name:  e.Name(),
							Path:  filepath.Join("/Volumes", e.Name()),
							IsDir: true,
						})
					}
				}
			}
		}
	case "linux":
		homeDir, _ := os.UserHomeDir()
		roots = append(roots,
			FileSystemEntry{Name: "Root", Path: "/", IsDir: true},
			FileSystemEntry{Name: "Home", Path: homeDir, IsDir: true},
			FileSystemEntry{Name: "Media", Path: "/media", IsDir: true},
			FileSystemEntry{Name: "Mnt", Path: "/mnt", IsDir: true},
		)
	case "windows":
		// List available drives
		for _, drive := range "CDEFGHIJKLMNOPQRSTUVWXYZ" {
			drivePath := string(drive) + ":\\"
			if _, err := os.Stat(drivePath); err == nil {
				roots = append(roots, FileSystemEntry{
					Name:  string(drive) + ":",
					Path:  drivePath,
					IsDir: true,
				})
			}
		}
	}

	return roots
}

// sortFileEntries sorts entries: directories first, then by name
func sortFileEntries(entries []FileSystemEntry) {
	for i := 0; i < len(entries)-1; i++ {
		for j := i + 1; j < len(entries); j++ {
			// Directories come first
			if entries[j].IsDir && !entries[i].IsDir {
				entries[i], entries[j] = entries[j], entries[i]
			} else if entries[i].IsDir == entries[j].IsDir {
				// Same type, sort alphabetically (case-insensitive)
				if strings.ToLower(entries[j].Name) < strings.ToLower(entries[i].Name) {
					entries[i], entries[j] = entries[j], entries[i]
				}
			}
		}
	}
}

// ============ Admin Settings Handlers ============

// ServerSettings represents configurable server settings
type ServerSettings struct {
	// Metadata
	TMDBApiKey   string `json:"tmdb_api_key,omitempty"`
	TVDBApiKey   string `json:"tvdb_api_key,omitempty"`
	MetadataLang string `json:"metadata_lang,omitempty"`
	ScanInterval int    `json:"scan_interval,omitempty"`
	VODAPIURL    string `json:"vod_api_url,omitempty"`

	// Server
	ServerName string `json:"server_name,omitempty"`
	ServerPort int    `json:"server_port,omitempty"`
	LogLevel   string `json:"log_level,omitempty"`
	DataDir    string `json:"data_dir,omitempty"`

	// Transcoding
	HardwareAccel    string `json:"hardware_accel,omitempty"`
	MaxTranscode     int    `json:"max_transcode_sessions,omitempty"`
	TranscodeTempDir string `json:"transcode_temp_dir,omitempty"`
	DefaultVideoCodec string `json:"default_video_codec,omitempty"`
	DefaultAudioCodec string `json:"default_audio_codec,omitempty"`

	// Live TV
	LiveTVMaxStreams    int  `json:"livetv_max_streams,omitempty"`
	TimeshiftBufferHrs int  `json:"timeshift_buffer_hrs,omitempty"`
	EPGRefreshInterval int  `json:"epg_refresh_interval,omitempty"`
	ChannelSwitchBuffer int `json:"channel_switch_buffer,omitempty"`
	TunerSharing       bool `json:"tuner_sharing"`

	// DVR (extended)
	RecordingDir      string `json:"recording_dir,omitempty"`
	PrePadding        int    `json:"pre_padding,omitempty"`
	PostPadding       int    `json:"post_padding,omitempty"`
	CommercialDetect  bool   `json:"commercial_detect"`
	AutoDeleteDays    int    `json:"auto_delete_days,omitempty"`
	MaxRecordQuality  string `json:"max_record_quality,omitempty"`

	// Live TV & DVR (dedicated settings page)
	RecordingPrePadding  int    `json:"recording_pre_padding"`
	RecordingPostPadding int    `json:"recording_post_padding"`
	RecordingQuality     string `json:"recording_quality,omitempty"`
	KeepRule             string `json:"keep_rule,omitempty"`
	AutoDeleteWatched    bool   `json:"auto_delete_watched"`
	CommercialDetectionEnabled bool   `json:"commercial_detection_enabled"`
	CommercialDetectionMode    string `json:"commercial_detection_mode,omitempty"`
	AutoSkipCommercials        bool   `json:"auto_skip_commercials"`
	GuideRefreshInterval       int    `json:"guide_refresh_interval,omitempty"`
	GuideDataSource            string `json:"guide_data_source,omitempty"`
	DeinterlacingMode          string `json:"deinterlacing_mode,omitempty"`
	LiveTVBufferSize           string `json:"livetv_buffer_size,omitempty"`

	// Remote Access
	RemoteAccessEnabled bool   `json:"remote_access_enabled"`
	TailscaleStatus     string `json:"tailscale_status,omitempty"`
	ExternalURL         string `json:"external_url,omitempty"`

	// Playback Defaults
	DefaultPlaybackSpeed    string `json:"default_playback_speed,omitempty"`
	FrameRateMatchMode      string `json:"frame_rate_match_mode,omitempty"`
	DefaultSubtitleLanguage string `json:"default_subtitle_language,omitempty"`
	DefaultAudioLanguage    string `json:"default_audio_language,omitempty"`

	// Advanced: Transcoder
	TranscoderType      string `json:"transcoder_type,omitempty"`
	DeinterlacerMode    string `json:"deinterlacer_mode,omitempty"`
	LiveTVBufferSecs    int    `json:"livetv_buffer_secs,omitempty"`

	// Advanced: Web Player
	PlaybackQuality     string `json:"playback_quality,omitempty"`
	ClientBufferSecs    int    `json:"client_buffer_secs,omitempty"`

	// Advanced: Integrations
	EDLExport           bool   `json:"edl_export"`
	M3UChannelIDs       bool   `json:"m3u_channel_ids"`
	VLCLinks            bool   `json:"vlc_links"`
	HTTPLogging         bool   `json:"http_logging"`

	// Advanced: Experimental
	ExperimentalHDR     bool   `json:"experimental_hdr"`
	ExperimentalLowLatency bool `json:"experimental_low_latency"`
	ExperimentalAIMetadata bool `json:"experimental_ai_metadata"`
}

// getSettingStr reads a string setting from the database
func (s *Server) getSettingStr(key, defaultVal string) string {
	var setting models.Setting
	if err := s.db.Where("key = ?", key).First(&setting).Error; err != nil {
		return defaultVal
	}
	return setting.Value
}

// getSettingBool reads a boolean setting from the database
func (s *Server) getSettingBool(key string, defaultVal bool) bool {
	val := s.getSettingStr(key, "")
	if val == "" {
		return defaultVal
	}
	return val == "true" || val == "1"
}

func (s *Server) buildFullSettings() ServerSettings {
	// Determine tailscale status
	tailscaleStatus := "disconnected"
	if s.remoteAccess != nil {
		status := s.remoteAccess.GetStatus()
		if status.Status == "connected" {
			tailscaleStatus = "connected"
		} else if status.Status != "" {
			tailscaleStatus = status.Status
		}
	}

	return ServerSettings{
		// Metadata
		TMDBApiKey:   maskAPIKey(s.config.Library.TMDBApiKey),
		TVDBApiKey:   maskAPIKey(s.config.Library.TVDBApiKey),
		MetadataLang: s.config.Library.MetadataLang,
		ScanInterval: s.config.Library.ScanInterval,
		VODAPIURL:    s.config.VOD.APIURL,

		// Server
		ServerName: s.config.Server.Name,
		ServerPort: s.config.Server.Port,
		LogLevel:   s.config.Logging.Level,
		DataDir:    s.config.GetDataDir(),

		// Transcoding
		HardwareAccel:     s.config.Transcode.HardwareAccel,
		MaxTranscode:      s.config.Transcode.MaxSessions,
		TranscodeTempDir:  s.config.Transcode.TempDir,
		DefaultVideoCodec: s.getSettingStr("transcode_default_video_codec", "h264"),
		DefaultAudioCodec: s.getSettingStr("transcode_default_audio_codec", "aac"),

		// Live TV
		LiveTVMaxStreams:     s.getSettingInt("livetv_max_streams", 0),
		TimeshiftBufferHrs:  s.getSettingInt("livetv_timeshift_buffer_hrs", 4),
		EPGRefreshInterval:  s.config.LiveTV.EPGInterval,
		ChannelSwitchBuffer: s.getSettingInt("livetv_channel_switch_buffer", 3),
		TunerSharing:        s.getSettingBool("livetv_tuner_sharing", true),

		// DVR (extended)
		RecordingDir:     s.config.DVR.RecordingDir,
		PrePadding:       s.config.DVR.PrePadding,
		PostPadding:      s.config.DVR.PostPadding,
		CommercialDetect: s.config.DVR.CommercialDetect,
		AutoDeleteDays:   s.getSettingInt("dvr_auto_delete_days", 0),
		MaxRecordQuality: s.getSettingStr("dvr_max_record_quality", "original"),

		// Live TV & DVR (dedicated page)
		RecordingPrePadding:        s.getSettingInt("recording_pre_padding", 2),
		RecordingPostPadding:       s.getSettingInt("recording_post_padding", 5),
		RecordingQuality:           s.getSettingStr("recording_quality", "original"),
		KeepRule:                   s.getSettingStr("keep_rule", "all"),
		AutoDeleteWatched:          s.getSettingBool("auto_delete_watched", false),
		CommercialDetectionEnabled: s.getSettingBool("commercial_detection_enabled", false),
		CommercialDetectionMode:    s.getSettingStr("commercial_detection_mode", "comskip"),
		AutoSkipCommercials:        s.getSettingBool("auto_skip_commercials", false),
		GuideRefreshInterval:       s.getSettingInt("guide_refresh_interval", 12),
		GuideDataSource:            s.getSettingStr("guide_data_source", "xmltv"),
		DeinterlacingMode:          s.getSettingStr("deinterlacing_mode", "blend"),
		LiveTVBufferSize:           s.getSettingStr("livetv_buffer_size", "1min"),

		// Remote Access
		RemoteAccessEnabled: s.getSettingBool("remote_access_enabled", false),
		TailscaleStatus:     tailscaleStatus,
		ExternalURL:         s.getSettingStr("remote_external_url", ""),

		// Playback Defaults
		DefaultPlaybackSpeed:    s.getSettingStr("playback_default_speed", "1.0"),
		FrameRateMatchMode:      s.getSettingStr("playback_frame_rate_match", "auto"),
		DefaultSubtitleLanguage: s.getSettingStr("playback_default_subtitle_lang", ""),
		DefaultAudioLanguage:    s.getSettingStr("playback_default_audio_lang", "en"),

		// Advanced: Transcoder
		TranscoderType:   s.getSettingStr("advanced_transcoder_type", "software"),
		DeinterlacerMode: s.getSettingStr("advanced_deinterlacer_mode", "blend"),
		LiveTVBufferSecs: s.getSettingInt("advanced_livetv_buffer_secs", 8),

		// Advanced: Web Player
		PlaybackQuality:  s.getSettingStr("advanced_playback_quality", "original"),
		ClientBufferSecs: s.getSettingInt("advanced_client_buffer_secs", 5),

		// Advanced: Integrations
		EDLExport:     s.getSettingBool("advanced_edl_export", false),
		M3UChannelIDs: s.getSettingBool("advanced_m3u_channel_ids", false),
		VLCLinks:      s.getSettingBool("advanced_vlc_links", false),
		HTTPLogging:   s.getSettingBool("advanced_http_logging", false),

		// Advanced: Experimental
		ExperimentalHDR:        s.getSettingBool("advanced_experimental_hdr", false),
		ExperimentalLowLatency: s.getSettingBool("advanced_experimental_low_latency", false),
		ExperimentalAIMetadata: s.getSettingBool("advanced_experimental_ai_metadata", false),
	}
}

func (s *Server) adminGetSettings(c *gin.Context) {
	settings := s.buildFullSettings()
	c.JSON(http.StatusOK, gin.H{
		"settings": settings,
	})
}

// getClientSettings returns settings needed by client apps (with full API keys for TMDB lookups)
func (s *Server) getClientSettings(c *gin.Context) {
	settings := ServerSettings{
		TMDBApiKey:   s.config.Library.TMDBApiKey, // Full key for client-side TMDB API calls
		MetadataLang: s.config.Library.MetadataLang,
		VODAPIURL:    s.config.VOD.APIURL,
	}

	c.JSON(http.StatusOK, gin.H{
		"settings": settings,
	})
}

func (s *Server) adminUpdateSettings(c *gin.Context) {
	var input ServerSettings
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// ---- Metadata ----
	if input.TMDBApiKey != "" && !strings.HasPrefix(input.TMDBApiKey, "****") {
		s.config.Library.TMDBApiKey = input.TMDBApiKey
		s.reinitializeTMDBAgent()
	}
	if input.TVDBApiKey != "" && !strings.HasPrefix(input.TVDBApiKey, "****") {
		s.config.Library.TVDBApiKey = input.TVDBApiKey
	}
	if input.MetadataLang != "" {
		s.config.Library.MetadataLang = input.MetadataLang
	}
	if input.ScanInterval > 0 {
		s.config.Library.ScanInterval = input.ScanInterval
	}
	if input.VODAPIURL != "" || c.Request.ContentLength > 0 {
		s.config.VOD.APIURL = input.VODAPIURL
	}

	// ---- Server ----
	if input.ServerName != "" {
		s.config.Server.Name = input.ServerName
	}
	if input.ServerPort > 0 {
		s.config.Server.Port = input.ServerPort
	}
	if input.LogLevel != "" {
		s.config.Logging.Level = input.LogLevel
		logger.SetLevel(input.LogLevel)
	}

	// ---- Transcoding ----
	if input.HardwareAccel != "" {
		s.config.Transcode.HardwareAccel = input.HardwareAccel
	}
	if input.MaxTranscode > 0 {
		s.config.Transcode.MaxSessions = input.MaxTranscode
	}
	if input.TranscodeTempDir != "" {
		s.config.Transcode.TempDir = input.TranscodeTempDir
	}
	if input.DefaultVideoCodec != "" {
		s.setSetting("transcode_default_video_codec", input.DefaultVideoCodec)
	}
	if input.DefaultAudioCodec != "" {
		s.setSetting("transcode_default_audio_codec", input.DefaultAudioCodec)
	}

	// ---- Live TV ----
	if input.LiveTVMaxStreams >= 0 {
		s.setSetting("livetv_max_streams", fmt.Sprintf("%d", input.LiveTVMaxStreams))
	}
	if input.TimeshiftBufferHrs > 0 {
		s.setSetting("livetv_timeshift_buffer_hrs", fmt.Sprintf("%d", input.TimeshiftBufferHrs))
	}
	if input.EPGRefreshInterval > 0 {
		s.config.LiveTV.EPGInterval = input.EPGRefreshInterval
	}
	if input.ChannelSwitchBuffer > 0 {
		s.setSetting("livetv_channel_switch_buffer", fmt.Sprintf("%d", input.ChannelSwitchBuffer))
	}
	// Tuner sharing is a bool, always persist
	s.setSetting("livetv_tuner_sharing", fmt.Sprintf("%t", input.TunerSharing))

	// ---- DVR (extended) ----
	if input.RecordingDir != "" {
		s.config.DVR.RecordingDir = input.RecordingDir
	}
	if input.PrePadding >= 0 {
		s.config.DVR.PrePadding = input.PrePadding
	}
	if input.PostPadding >= 0 {
		s.config.DVR.PostPadding = input.PostPadding
	}
	s.config.DVR.CommercialDetect = input.CommercialDetect
	if input.AutoDeleteDays >= 0 {
		s.setSetting("dvr_auto_delete_days", fmt.Sprintf("%d", input.AutoDeleteDays))
	}
	if input.MaxRecordQuality != "" {
		s.setSetting("dvr_max_record_quality", input.MaxRecordQuality)
	}

	// ---- Live TV & DVR (dedicated page) ----
	s.setSetting("recording_pre_padding", fmt.Sprintf("%d", input.RecordingPrePadding))
	s.setSetting("recording_post_padding", fmt.Sprintf("%d", input.RecordingPostPadding))
	if input.RecordingQuality != "" {
		s.setSetting("recording_quality", input.RecordingQuality)
	}
	if input.KeepRule != "" {
		s.setSetting("keep_rule", input.KeepRule)
	}
	s.setSetting("auto_delete_watched", fmt.Sprintf("%t", input.AutoDeleteWatched))
	s.setSetting("commercial_detection_enabled", fmt.Sprintf("%t", input.CommercialDetectionEnabled))
	if input.CommercialDetectionMode != "" {
		s.setSetting("commercial_detection_mode", input.CommercialDetectionMode)
	}
	s.setSetting("auto_skip_commercials", fmt.Sprintf("%t", input.AutoSkipCommercials))
	if input.GuideRefreshInterval > 0 {
		s.setSetting("guide_refresh_interval", fmt.Sprintf("%d", input.GuideRefreshInterval))
	}
	if input.DeinterlacingMode != "" {
		s.setSetting("deinterlacing_mode", input.DeinterlacingMode)
	}
	if input.LiveTVBufferSize != "" {
		s.setSetting("livetv_buffer_size", input.LiveTVBufferSize)
	}

	// ---- Remote Access ----
	s.setSetting("remote_access_enabled", fmt.Sprintf("%t", input.RemoteAccessEnabled))
	if input.ExternalURL != "" {
		s.setSetting("remote_external_url", input.ExternalURL)
	}

	// ---- Playback Defaults ----
	if input.DefaultPlaybackSpeed != "" {
		s.setSetting("playback_default_speed", input.DefaultPlaybackSpeed)
	}
	if input.FrameRateMatchMode != "" {
		s.setSetting("playback_frame_rate_match", input.FrameRateMatchMode)
	}
	if input.DefaultSubtitleLanguage != "" {
		s.setSetting("playback_default_subtitle_lang", input.DefaultSubtitleLanguage)
	}
	if input.DefaultAudioLanguage != "" {
		s.setSetting("playback_default_audio_lang", input.DefaultAudioLanguage)
	}

	// ---- Advanced: Transcoder ----
	if input.TranscoderType != "" {
		s.setSetting("advanced_transcoder_type", input.TranscoderType)
	}
	if input.DeinterlacerMode != "" {
		s.setSetting("advanced_deinterlacer_mode", input.DeinterlacerMode)
	}
	if input.LiveTVBufferSecs > 0 {
		s.setSetting("advanced_livetv_buffer_secs", fmt.Sprintf("%d", input.LiveTVBufferSecs))
	}

	// ---- Advanced: Web Player ----
	if input.PlaybackQuality != "" {
		s.setSetting("advanced_playback_quality", input.PlaybackQuality)
	}
	if input.ClientBufferSecs > 0 {
		s.setSetting("advanced_client_buffer_secs", fmt.Sprintf("%d", input.ClientBufferSecs))
	}

	// ---- Advanced: Integrations ----
	s.setSetting("advanced_edl_export", fmt.Sprintf("%t", input.EDLExport))
	s.setSetting("advanced_m3u_channel_ids", fmt.Sprintf("%t", input.M3UChannelIDs))
	s.setSetting("advanced_vlc_links", fmt.Sprintf("%t", input.VLCLinks))
	s.setSetting("advanced_http_logging", fmt.Sprintf("%t", input.HTTPLogging))

	// ---- Advanced: Experimental ----
	s.setSetting("advanced_experimental_hdr", fmt.Sprintf("%t", input.ExperimentalHDR))
	s.setSetting("advanced_experimental_low_latency", fmt.Sprintf("%t", input.ExperimentalLowLatency))
	s.setSetting("advanced_experimental_ai_metadata", fmt.Sprintf("%t", input.ExperimentalAIMetadata))

	c.JSON(http.StatusOK, gin.H{
		"message":  "Settings updated successfully",
		"settings": s.buildFullSettings(),
	})
}

// maskAPIKey partially hides an API key for display
func maskAPIKey(key string) string {
	if key == "" {
		return ""
	}
	if len(key) <= 8 {
		return "****"
	}
	return key[:4] + "****" + key[len(key)-4:]
}

// ============ DVR Settings Handlers ============

// DVRSettings represents DVR-specific settings
type DVRSettings struct {
	MaxConcurrentRecordings int    `json:"maxConcurrentRecordings"` // 0 = unlimited
	DetectionMethod        string `json:"detection_method"`
	ComskipPath            string `json:"comskip_path"`
	Sensitivity            int    `json:"sensitivity"`
	AutoSkipBehavior       string `json:"auto_skip_behavior"`
	SkipPromptDuration     int    `json:"skip_prompt_duration"`
	Enabled                bool   `json:"enabled"`
	DetectionWorkers       int    `json:"detection_workers"`
	GenerateThumbnails     bool   `json:"generate_thumbnails"`
	ShareEdits             bool   `json:"share_edits"`
}

func (s *Server) getDVRSettings(c *gin.Context) {
	settings := DVRSettings{
		MaxConcurrentRecordings: s.getSettingInt("dvr_max_concurrent", 0),
		DetectionMethod:        s.getSettingStr("comskip_detection_method", "comskip"),
		ComskipPath:            s.getSettingStr("comskip_path", "/usr/bin/comskip"),
		Sensitivity:            s.getSettingInt("comskip_sensitivity", 50),
		AutoSkipBehavior:       s.getSettingStr("comskip_auto_skip_behavior", "show_prompt"),
		SkipPromptDuration:     s.getSettingInt("comskip_skip_prompt_duration", 5),
		Enabled:                s.getSettingBool("commercial_detection_enabled", false),
		DetectionWorkers:       s.getSettingInt("comskip_detection_workers", 2),
		GenerateThumbnails:     s.getSettingBool("comskip_generate_thumbnails", false),
		ShareEdits:             s.getSettingBool("comskip_share_edits", false),
	}

	c.JSON(http.StatusOK, gin.H{
		"settings": settings,
	})
}

func (s *Server) updateDVRSettings(c *gin.Context) {
	var input DVRSettings
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate
	if input.MaxConcurrentRecordings < 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "maxConcurrentRecordings must be >= 0 (0 = unlimited)"})
		return
	}
	if input.DetectionWorkers < 1 {
		input.DetectionWorkers = 1
	}
	if input.DetectionWorkers > 8 {
		input.DetectionWorkers = 8
	}
	if input.Sensitivity < 0 {
		input.Sensitivity = 0
	}
	if input.Sensitivity > 100 {
		input.Sensitivity = 100
	}
	if input.SkipPromptDuration < 1 {
		input.SkipPromptDuration = 1
	}
	if input.SkipPromptDuration > 30 {
		input.SkipPromptDuration = 30
	}

	// Save all settings to database
	s.setSetting("dvr_max_concurrent", fmt.Sprintf("%d", input.MaxConcurrentRecordings))
	s.setSetting("comskip_detection_method", input.DetectionMethod)
	s.setSetting("comskip_path", input.ComskipPath)
	s.setSetting("comskip_sensitivity", fmt.Sprintf("%d", input.Sensitivity))
	s.setSetting("comskip_auto_skip_behavior", input.AutoSkipBehavior)
	s.setSetting("comskip_skip_prompt_duration", fmt.Sprintf("%d", input.SkipPromptDuration))
	if input.Enabled {
		s.setSetting("commercial_detection_enabled", "true")
	} else {
		s.setSetting("commercial_detection_enabled", "false")
	}
	s.setSetting("comskip_detection_workers", fmt.Sprintf("%d", input.DetectionWorkers))
	if input.GenerateThumbnails {
		s.setSetting("comskip_generate_thumbnails", "true")
	} else {
		s.setSetting("comskip_generate_thumbnails", "false")
	}
	if input.ShareEdits {
		s.setSetting("comskip_share_edits", "true")
	} else {
		s.setSetting("comskip_share_edits", "false")
	}

	c.JSON(http.StatusOK, gin.H{
		"message":  "DVR settings updated",
		"settings": input,
	})
}

// getSettingInt reads an integer setting from the database
func (s *Server) getSettingInt(key string, defaultVal int) int {
	var setting models.Setting
	if err := s.db.Where("key = ?", key).First(&setting).Error; err != nil {
		return defaultVal
	}

	var value int
	if _, err := fmt.Sscanf(setting.Value, "%d", &value); err != nil {
		return defaultVal
	}
	return value
}

// setSetting saves a setting to the database
func (s *Server) setSetting(key, value string) {
	setting := models.Setting{Key: key, Value: value}
	s.db.Where("key = ?", key).Assign(setting).FirstOrCreate(&setting)
}

// ============ Guide Data Handlers ============

// refreshGuideData triggers a full guide data refresh (admin only)
func (s *Server) refreshGuideData(c *gin.Context) {
	if s.epgScheduler != nil {
		go s.epgScheduler.ForceRefresh()
	}
	// Also invalidate guide cache
	if s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}
	c.JSON(http.StatusOK, gin.H{
		"message": "Guide data refresh triggered",
		"status":  "refreshing",
	})
}

// rebuildGuideData triggers a full guide data rebuild (admin only)
func (s *Server) rebuildGuideData(c *gin.Context) {
	// Clear all cached guide data
	if s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}
	// Force a full refresh
	if s.epgScheduler != nil {
		go s.epgScheduler.ForceRefresh()
	}
	c.JSON(http.StatusOK, gin.H{
		"message": "Guide data rebuild triggered. All cached data has been cleared.",
		"status":  "rebuilding",
	})
}

// ============ Global Client Settings Handlers ============

// getGlobalClientSettings returns all global client setting overrides (admin only)
func (s *Server) getGlobalClientSettings(c *gin.Context) {
	var settings []models.Setting
	s.db.Where("key LIKE ?", "client_override_%").Find(&settings)

	overrides := make(map[string]string)
	for _, setting := range settings {
		// Strip the "client_override_" prefix for the key name
		key := strings.TrimPrefix(setting.Key, "client_override_")
		overrides[key] = setting.Value
	}

	c.JSON(http.StatusOK, gin.H{
		"overrides": overrides,
	})
}

// updateGlobalClientSettings sets or updates a global client setting override (admin only)
func (s *Server) updateGlobalClientSettings(c *gin.Context) {
	var req struct {
		Key   string `json:"key" binding:"required"`
		Value string `json:"value" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "key and value are required"})
		return
	}

	dbKey := "client_override_" + req.Key
	s.setSetting(dbKey, req.Value)

	c.JSON(http.StatusOK, gin.H{
		"message": "Client setting override saved",
		"key":     req.Key,
		"value":   req.Value,
	})
}

// deleteGlobalClientSetting removes a single global client setting override (admin only)
func (s *Server) deleteGlobalClientSetting(c *gin.Context) {
	key := c.Param("key")
	if key == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "key is required"})
		return
	}

	dbKey := "client_override_" + key
	result := s.db.Where("key = ?", dbKey).Delete(&models.Setting{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Override not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Override removed"})
}
