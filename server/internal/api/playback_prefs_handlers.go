package api

import (
	"fmt"
	"math"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Playback Speed Control ============

// speedPresets defines the available playback speed options.
var speedPresets = []float64{0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0}

// isValidSpeed checks whether a speed value is within the accepted range.
func isValidSpeed(speed float64) bool {
	return speed >= 0.25 && speed <= 4.0
}

// getSpeedPresets returns available playback speed presets along with
// the default speed and the current user's preferred speed.
// GET /api/playback/speed-presets
func (s *Server) getSpeedPresets(c *gin.Context) {
	userID, _ := c.Get("userID")
	uid, _ := userID.(uint)

	// Read user-preferred speed from settings table
	userPreferred := s.getSettingFloat(fmt.Sprintf("user:%d:playback_speed", uid), 1.0)

	c.JSON(http.StatusOK, gin.H{
		"presets":       speedPresets,
		"default":       1.0,
		"userPreferred": userPreferred,
	})
}

// setPlaybackSpeed stores the preferred playback speed for the current user.
// PUT /api/playback/speed
func (s *Server) setPlaybackSpeed(c *gin.Context) {
	var req struct {
		Speed float64 `json:"speed" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: speed is required"})
		return
	}

	if !isValidSpeed(req.Speed) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Speed must be between 0.25 and 4.0"})
		return
	}

	userID, _ := c.Get("userID")
	uid, _ := userID.(uint)

	key := fmt.Sprintf("user:%d:playback_speed", uid)
	s.setSetting(key, fmt.Sprintf("%.2f", req.Speed))

	logger.Infof("Playback speed preference set to %.2f for user %d", req.Speed, uid)

	c.JSON(http.StatusOK, gin.H{
		"message": "Playback speed preference updated",
		"speed":   req.Speed,
	})
}

// getSessionSpeed returns the current playback speed for a session.
// GET /api/playback/sessions/:sessionId/speed
func (s *Server) getSessionSpeed(c *gin.Context) {
	sessionID := c.Param("sessionId")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Session ID is required"})
		return
	}

	var session models.PlaybackSession
	if err := s.db.Where("id = ?", sessionID).First(&session).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	speed := session.PlaybackSpeed
	if speed == 0 {
		speed = 1.0
	}

	c.JSON(http.StatusOK, gin.H{
		"sessionId": sessionID,
		"speed":     speed,
	})
}

// setSessionSpeed updates the playback speed for an active session.
// PUT /api/playback/sessions/:sessionId/speed
func (s *Server) setSessionSpeed(c *gin.Context) {
	sessionID := c.Param("sessionId")
	if sessionID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Session ID is required"})
		return
	}

	var req struct {
		Speed float64 `json:"speed" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: speed is required"})
		return
	}

	if !isValidSpeed(req.Speed) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Speed must be between 0.25 and 4.0"})
		return
	}

	var session models.PlaybackSession
	if err := s.db.Where("id = ?", sessionID).First(&session).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Session not found"})
		return
	}

	session.PlaybackSpeed = req.Speed
	if err := s.db.Save(&session).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update session speed"})
		return
	}

	logger.Infof("Session %s speed updated to %.2f", sessionID, req.Speed)

	c.JSON(http.StatusOK, gin.H{
		"message":   "Session speed updated",
		"sessionId": sessionID,
		"speed":     req.Speed,
	})
}

// ============ Frame Rate Matching ============

// frameRateInfo describes the frame rate characteristics of a media item.
type frameRateInfo struct {
	MediaID            uint               `json:"mediaId"`
	VideoFrameRate     float64            `json:"videoFrameRate"`
	ScanType           string             `json:"scanType"`
	RecommendedRefresh string             `json:"recommended_refresh"`
	IsFilm             bool               `json:"is_film"`
	IsInterlaced       bool               `json:"is_interlaced"`
	Hints              frameRateHints     `json:"hints"`
}

type frameRateHints struct {
	AppleTV   string `json:"apple_tv"`
	AndroidTV string `json:"android_tv"`
	FireTV    string `json:"fire_tv"`
}

// getMediaFrameRate returns frame rate information for a media item so that
// clients can match their display refresh rate accordingly.
// GET /api/playback/:id/framerate
func (s *Server) getMediaFrameRate(c *gin.Context) {
	mediaIDStr := c.Param("id")
	mediaID, err := strconv.ParseUint(mediaIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid media ID"})
		return
	}

	// Look up the media item with its files and streams
	var mediaItem models.MediaItem
	if err := s.db.Preload("MediaFiles.Streams").First(&mediaItem, mediaID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	if len(mediaItem.MediaFiles) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "No media files associated with this item"})
		return
	}

	// Use the primary (first) media file
	mediaFile := mediaItem.MediaFiles[0]

	// Find the video stream
	var videoFrameRate float64
	var scanType string = "progressive"
	var isInterlaced bool

	for _, stream := range mediaFile.Streams {
		if stream.StreamType == 1 { // video
			videoFrameRate = stream.FrameRate
			break
		}
	}

	// If no frame rate from stream metadata, try to parse from MediaFile's VideoFrameRate field
	if videoFrameRate == 0 && mediaFile.VideoFrameRate != "" {
		videoFrameRate = parseFrameRate(mediaFile.VideoFrameRate)
		// Check for interlaced content indicated by the frame rate string
		if containsInterlacedHint(mediaFile.VideoFrameRate) {
			isInterlaced = true
			scanType = "interlaced"
		}
	}

	// Determine content category
	isFilm := isFilmFrameRate(videoFrameRate)

	// Determine recommended display refresh rate
	recommendedRefresh := getRecommendedRefresh(videoFrameRate)

	// Build platform-specific hints
	hints := frameRateHints{
		AppleTV:   "match_content",
		AndroidTV: "seamless_refresh_rate",
		FireTV:    "match_original_frame_rate",
	}

	c.JSON(http.StatusOK, frameRateInfo{
		MediaID:            uint(mediaID),
		VideoFrameRate:     videoFrameRate,
		ScanType:           scanType,
		RecommendedRefresh: recommendedRefresh,
		IsFilm:             isFilm,
		IsInterlaced:       isInterlaced,
		Hints:              hints,
	})
}

// getFrameRateSettings returns global frame rate matching settings.
// GET /api/playback/framerate-settings
func (s *Server) getFrameRateSettings(c *gin.Context) {
	enabled := s.getSettingString("framerate_matching_enabled", "true") == "true"
	mode := s.getSettingString("framerate_matching_mode", "auto")

	supportedRates := []float64{23.976, 24, 25, 29.97, 30, 50, 59.94, 60}

	c.JSON(http.StatusOK, gin.H{
		"enabled":         enabled,
		"mode":            mode,
		"supported_rates": supportedRates,
	})
}

// updateFrameRateSettings updates global frame rate matching settings (admin only).
// PUT /api/playback/framerate-settings
func (s *Server) updateFrameRateSettings(c *gin.Context) {
	var req struct {
		Enabled *bool  `json:"enabled"`
		Mode    string `json:"mode"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if req.Enabled != nil {
		val := "false"
		if *req.Enabled {
			val = "true"
		}
		s.setSetting("framerate_matching_enabled", val)
	}

	if req.Mode != "" {
		validModes := map[string]bool{"auto": true, "always": true, "never": true}
		if !validModes[req.Mode] {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Mode must be one of: auto, always, never"})
			return
		}
		s.setSetting("framerate_matching_mode", req.Mode)
	}

	// Return the updated settings
	enabled := s.getSettingString("framerate_matching_enabled", "true") == "true"
	mode := s.getSettingString("framerate_matching_mode", "auto")

	logger.Infof("Frame rate matching settings updated: enabled=%v mode=%s", enabled, mode)

	c.JSON(http.StatusOK, gin.H{
		"message":         "Frame rate settings updated",
		"enabled":         enabled,
		"mode":            mode,
		"supported_rates": []float64{23.976, 24, 25, 29.97, 30, 50, 59.94, 60},
	})
}

// ============ Helpers ============

// getSettingFloat reads a float64 setting from the database.
func (s *Server) getSettingFloat(key string, defaultVal float64) float64 {
	var setting models.Setting
	if err := s.db.Where("key = ?", key).First(&setting).Error; err != nil {
		return defaultVal
	}
	val, err := strconv.ParseFloat(setting.Value, 64)
	if err != nil {
		return defaultVal
	}
	return val
}

// parseFrameRate converts a frame rate string (e.g. "23.976", "24p", "29.97i", "60")
// into a float64 value.
func parseFrameRate(fr string) float64 {
	// Strip trailing 'p' or 'i' indicators
	cleaned := fr
	if len(cleaned) > 0 {
		last := cleaned[len(cleaned)-1]
		if last == 'p' || last == 'i' || last == 'P' || last == 'I' {
			cleaned = cleaned[:len(cleaned)-1]
		}
	}

	val, err := strconv.ParseFloat(cleaned, 64)
	if err != nil {
		return 0
	}
	return val
}

// containsInterlacedHint checks whether a frame rate string indicates interlaced content.
func containsInterlacedHint(fr string) bool {
	if len(fr) == 0 {
		return false
	}
	last := fr[len(fr)-1]
	return last == 'i' || last == 'I'
}

// isFilmFrameRate returns true if the frame rate is close to cinematic frame rates
// (23.976 fps or 24 fps).
func isFilmFrameRate(fps float64) bool {
	return math.Abs(fps-23.976) < 0.05 || math.Abs(fps-24.0) < 0.05
}

// getRecommendedRefresh returns a human-readable recommended display refresh rate
// based on the video frame rate.
func getRecommendedRefresh(fps float64) string {
	if fps == 0 {
		return "60Hz"
	}

	// Film content: 23.976 / 24 fps
	if math.Abs(fps-23.976) < 0.05 || math.Abs(fps-24.0) < 0.05 {
		return "24Hz"
	}

	// PAL content: 25 fps
	if math.Abs(fps-25.0) < 0.05 {
		return "25Hz"
	}

	// NTSC content: 29.97 / 30 fps
	if math.Abs(fps-29.97) < 0.05 || math.Abs(fps-30.0) < 0.05 {
		return "30Hz"
	}

	// PAL high frame rate: 50 fps
	if math.Abs(fps-50.0) < 0.05 {
		return "50Hz"
	}

	// NTSC high frame rate / sports: 59.94 / 60 fps
	if math.Abs(fps-59.94) < 0.1 || math.Abs(fps-60.0) < 0.05 {
		return "60Hz"
	}

	// Default fallback
	return "60Hz"
}
