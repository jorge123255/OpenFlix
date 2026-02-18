package api

import (
	"net/http"
	"strconv"
	"strings"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/openflix/openflix-server/internal/playback"
)

// clientCapabilitiesStore stores client capabilities in memory
// In production, you might want to persist this to Redis or a database
var (
	clientCapabilities = make(map[string]*playback.ClientCapabilities)
	clientCapMutex     sync.RWMutex
)

// registerClientCapabilities registers a client's playback capabilities
func (s *Server) registerClientCapabilities(c *gin.Context) {
	var caps playback.ClientCapabilities
	if err := c.ShouldBindJSON(&caps); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if caps.DeviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device ID is required"})
		return
	}

	// Store capabilities
	clientCapMutex.Lock()
	clientCapabilities[caps.DeviceID] = &caps
	clientCapMutex.Unlock()

	c.JSON(http.StatusOK, gin.H{
		"message":  "Capabilities registered",
		"deviceId": caps.DeviceID,
	})
}

// getClientCapabilities returns stored capabilities for a device
func (s *Server) getClientCapabilities(c *gin.Context) {
	deviceID := c.Param("deviceId")
	if deviceID == "" {
		deviceID = c.Query("X-Device-ID")
	}

	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Device ID is required"})
		return
	}

	clientCapMutex.RLock()
	caps, exists := clientCapabilities[deviceID]
	clientCapMutex.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "No capabilities registered for device"})
		return
	}

	c.JSON(http.StatusOK, caps)
}

// getDefaultCapabilities returns default capabilities for a platform
func (s *Server) getDefaultCapabilities(c *gin.Context) {
	platform := c.DefaultQuery("platform", "unknown")
	caps := playback.DefaultClientCapabilities(platform)
	c.JSON(http.StatusOK, caps)
}

// getPlaybackDecision returns the optimal playback mode for a media file
func (s *Server) getPlaybackDecision(c *gin.Context) {
	// Get media file ID
	fileIDStr := c.Param("fileId")
	fileID, err := strconv.ParseUint(fileIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	// Get the media file with streams
	var file models.MediaFile
	if err := s.db.Preload("Streams").First(&file, fileID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media file not found"})
		return
	}

	// Get client capabilities - from stored or request body or default
	var caps *playback.ClientCapabilities

	// Try to get from stored capabilities first
	deviceID := c.GetHeader("X-Device-ID")
	if deviceID != "" {
		clientCapMutex.RLock()
		caps = clientCapabilities[deviceID]
		clientCapMutex.RUnlock()
	}

	// If not found, try parsing from request body
	if caps == nil {
		var reqCaps playback.ClientCapabilities
		if err := c.ShouldBindJSON(&reqCaps); err == nil && len(reqCaps.VideoCodecs) > 0 {
			caps = &reqCaps
		}
	}

	// If still not found, use platform defaults
	if caps == nil {
		platform := c.DefaultQuery("platform", c.GetHeader("X-Device-Platform"))
		if platform == "" {
			platform = "unknown"
		}
		caps = playback.DefaultClientCapabilities(platform)
	}

	// Build media info from file
	mediaInfo := &playback.MediaInfo{
		Container:    file.Container,
		VideoCodec:   normalizeCodec(file.VideoCodec),
		VideoProfile: file.VideoProfile,
		AudioCodec:   normalizeCodec(file.AudioCodec),
		Width:        file.Width,
		Height:       file.Height,
		Bitrate:      file.Bitrate / 1000, // Convert to kbps
	}

	// Check for HDR/DV in video streams
	for _, stream := range file.Streams {
		if stream.StreamType == 1 { // Video stream
			if strings.Contains(strings.ToLower(stream.Title), "hdr") ||
				strings.Contains(strings.ToLower(stream.DisplayTitle), "hdr") {
				mediaInfo.HasHDR = true
			}
			if strings.Contains(strings.ToLower(stream.Title), "dolby vision") ||
				strings.Contains(strings.ToLower(stream.DisplayTitle), "dv") {
				mediaInfo.HasDolbyVision = true
			}
		}
		if stream.StreamType == 2 { // Audio stream
			if strings.Contains(strings.ToLower(stream.Codec), "truehd") &&
				strings.Contains(strings.ToLower(stream.Title), "atmos") {
				mediaInfo.HasAtmos = true
			}
		}
	}

	// Get the decision
	decision := playback.DecidePlayback(mediaInfo, caps)

	// Build response with additional context
	response := gin.H{
		"decision": decision,
		"mediaInfo": gin.H{
			"container":      mediaInfo.Container,
			"videoCodec":     mediaInfo.VideoCodec,
			"audioCodec":     mediaInfo.AudioCodec,
			"resolution":     formatResolution(mediaInfo.Width, mediaInfo.Height),
			"bitrate":        mediaInfo.Bitrate,
			"hasHDR":         mediaInfo.HasHDR,
			"hasDolbyVision": mediaInfo.HasDolbyVision,
			"hasAtmos":       mediaInfo.HasAtmos,
		},
		"clientCapabilities": gin.H{
			"platform":      caps.Platform,
			"maxResolution": caps.MaxResolution,
			"videoCodecs":   caps.VideoCodecs,
			"audioCodecs":   caps.AudioCodecs,
		},
		"playbackUrl": buildPlaybackUrl(file.ID, decision),
	}

	// If the client supports DASH and transcoding is needed, also offer a DASH URL
	if decision.Mode == playback.ModeTranscode && isDASHCapable(caps.Containers) {
		response["dashUrl"] = buildDASHPlaybackUrl(file.ID, decision.SuggestedResolution)
	}

	// Include bandwidth-based quality recommendation if available
	if deviceID != "" && s.bandwidthManager != nil {
		estimatedBW := s.bandwidthManager.GetEstimatedBandwidth(deviceID)
		if estimatedBW > 0 {
			response["estimatedBandwidth"] = estimatedBW
			response["recommendedQuality"] = s.bandwidthManager.GetRecommendedQuality(deviceID)
		}
	}

	// Include skip markers if available for this file
	userID, _ := c.Get("userID")
	if markers := s.getSkipMarkersForFile(file.ID, userID); len(markers) > 0 {
		settings := s.getUserSkipSettings(userID)
		response["markers"] = markers
		response["skipButtonDuration"] = settings.SkipButtonDuration
	}

	c.JSON(http.StatusOK, response)
}

// getMediaPlaybackOptions returns all playback options for a media item
func (s *Server) getMediaPlaybackOptions(c *gin.Context) {
	// Get media item ID
	mediaIDStr := c.Param("mediaId")
	mediaID, err := strconv.ParseUint(mediaIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid media ID"})
		return
	}

	// Get all media files for this item
	var files []models.MediaFile
	if err := s.db.Where("media_item_id = ?", mediaID).Preload("Streams").Find(&files).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No files found"})
		return
	}

	// Get client capabilities
	var caps *playback.ClientCapabilities
	deviceID := c.GetHeader("X-Device-ID")
	if deviceID != "" {
		clientCapMutex.RLock()
		caps = clientCapabilities[deviceID]
		clientCapMutex.RUnlock()
	}
	if caps == nil {
		platform := c.DefaultQuery("platform", c.GetHeader("X-Device-Platform"))
		caps = playback.DefaultClientCapabilities(platform)
	}

	// Analyze each file
	options := make([]gin.H, len(files))
	for i, file := range files {
		mediaInfo := &playback.MediaInfo{
			Container:    file.Container,
			VideoCodec:   normalizeCodec(file.VideoCodec),
			VideoProfile: file.VideoProfile,
			AudioCodec:   normalizeCodec(file.AudioCodec),
			Width:        file.Width,
			Height:       file.Height,
			Bitrate:      file.Bitrate / 1000,
		}

		decision := playback.DecidePlayback(mediaInfo, caps)

		options[i] = gin.H{
			"fileId":     file.ID,
			"resolution": formatResolution(file.Width, file.Height),
			"codec":      file.VideoCodec,
			"container":  file.Container,
			"bitrate":    file.Bitrate,
			"decision":   decision,
			"playbackUrl": buildPlaybackUrl(file.ID, decision),
		}
	}

	// Sort by preference: direct_play first, then direct_stream, then transcode
	// (Already in a reasonable order based on file listing)

	c.JSON(http.StatusOK, gin.H{
		"mediaId": mediaID,
		"options": options,
		"clientPlatform": caps.Platform,
	})
}

// Helper functions

func normalizeCodec(codec string) string {
	codec = strings.ToLower(codec)

	// Normalize common codec names
	switch {
	case strings.Contains(codec, "h264") || strings.Contains(codec, "avc"):
		return "h264"
	case strings.Contains(codec, "h265") || strings.Contains(codec, "hevc"):
		return "hevc"
	case strings.Contains(codec, "vp9"):
		return "vp9"
	case strings.Contains(codec, "av1"):
		return "av1"
	case strings.Contains(codec, "aac"):
		return "aac"
	case strings.Contains(codec, "ac3") || strings.Contains(codec, "a52"):
		return "ac3"
	case strings.Contains(codec, "eac3") || strings.Contains(codec, "ec3"):
		return "eac3"
	case strings.Contains(codec, "dts"):
		return "dts"
	case strings.Contains(codec, "truehd"):
		return "truehd"
	case strings.Contains(codec, "flac"):
		return "flac"
	case strings.Contains(codec, "opus"):
		return "opus"
	case strings.Contains(codec, "mp3"):
		return "mp3"
	}
	return codec
}

func formatResolution(width, height int) string {
	if height >= 2160 {
		return "4K"
	} else if height >= 1440 {
		return "1440p"
	} else if height >= 1080 {
		return "1080p"
	} else if height >= 720 {
		return "720p"
	} else if height >= 480 {
		return "480p"
	}
	return "SD"
}

func buildPlaybackUrl(fileID uint, decision *playback.PlaybackDecision) string {
	switch decision.Mode {
	case playback.ModeDirectPlay:
		return "/library/parts/" + strconv.FormatUint(uint64(fileID), 10) + "/file"
	case playback.ModeDirectStream:
		return "/library/parts/" + strconv.FormatUint(uint64(fileID), 10) + "/file?directStream=1"
	case playback.ModeTranscode:
		return "/video/:/transcode/universal/start?fileId=" + strconv.FormatUint(uint64(fileID), 10)
	default:
		return "/library/parts/" + strconv.FormatUint(uint64(fileID), 10) + "/file"
	}
}
