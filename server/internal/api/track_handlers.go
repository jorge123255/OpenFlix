package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/openflix/openflix-server/internal/transcode"
)

// ---- response DTOs ----

// trackInfoResponse is the JSON shape returned by the tracks endpoint.
type trackInfoResponse struct {
	MediaID    uint                `json:"mediaId"`
	FileID     uint                `json:"fileId"`
	FilePath   string              `json:"filePath"`
	Video      []trackStreamDTO    `json:"video"`
	Audio      []trackStreamDTO    `json:"audio"`
	Subtitle   []trackStreamDTO    `json:"subtitle"`
	Selected   selectedTracksDTO   `json:"selected"`
}

type trackStreamDTO struct {
	Index     int    `json:"index"`
	CodecName string `json:"codecName"`
	Language  string `json:"language,omitempty"`
	Title     string `json:"title,omitempty"`
	Channels  int    `json:"channels,omitempty"`
	Default   bool   `json:"default"`
	Forced    bool   `json:"forced"`
	BitRate   string `json:"bitRate,omitempty"`
	Width     int    `json:"width,omitempty"`
	Height    int    `json:"height,omitempty"`
	Selected  bool   `json:"selected"`
}

type selectedTracksDTO struct {
	AudioIndex    *int `json:"audioIndex"`
	SubtitleIndex *int `json:"subtitleIndex"`
}

// trackSelectRequest is the body for PUT /tracks/select.
type trackSelectRequest struct {
	AudioIndex    *int `json:"audioIndex"`
	SubtitleIndex *int `json:"subtitleIndex"`
}

// trackPreferencesDTO represents a user's persistent track preferences.
type trackPreferencesDTO struct {
	DefaultAudioLanguage    string `json:"defaultAudioLanguage"`
	DefaultSubtitleLanguage string `json:"defaultSubtitleLanguage"`
	AutoSelectAudio         bool   `json:"autoSelectAudio"`
	AutoSelectSubtitle      int    `json:"autoSelectSubtitle"` // 0=off, 1=auto, 2=forced, 3=always
}

// ---- handlers ----

// getMediaTracks probes the underlying file and returns all available tracks.
// GET /api/playback/:mediaId/tracks
func (s *Server) getMediaTracks(c *gin.Context) {
	mediaID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid media ID"})
		return
	}

	// Look up the media item and its first media file
	var mediaItem models.MediaItem
	if err := s.db.Preload("MediaFiles.Streams").First(&mediaItem, mediaID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	if len(mediaItem.MediaFiles) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "No media files associated with this item"})
		return
	}

	mediaFile := mediaItem.MediaFiles[0]
	filePath := mediaFile.FilePath

	// Derive ffprobe path from configured ffmpeg path
	ffprobePath := transcode.FFprobePath(s.config.Transcode.FFmpegPath)

	// Run ffprobe
	probeResult, err := transcode.ProbeFile(ffprobePath, filePath)
	if err != nil {
		logger.Warnf("ffprobe failed for media %d: %v", mediaID, err)
		// Fall back to database-stored stream info
		resp := buildTrackResponseFromDB(uint(mediaID), &mediaFile)
		c.JSON(http.StatusOK, resp)
		return
	}

	// Build response from probe result, merging DB selection state
	resp := buildTrackResponseFromProbe(uint(mediaID), &mediaFile, probeResult)
	c.JSON(http.StatusOK, resp)
}

// selectMediaTracks updates the selected audio/subtitle tracks for a media file.
// PUT /api/playback/:mediaId/tracks/select
func (s *Server) selectMediaTracks(c *gin.Context) {
	mediaID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid media ID"})
		return
	}

	var req trackSelectRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Look up the media item with files and streams
	var mediaItem models.MediaItem
	if err := s.db.Preload("MediaFiles.Streams").First(&mediaItem, mediaID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	if len(mediaItem.MediaFiles) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "No media files associated with this item"})
		return
	}

	mediaFile := &mediaItem.MediaFiles[0]

	// Update audio selection
	if req.AudioIndex != nil {
		for i := range mediaFile.Streams {
			if mediaFile.Streams[i].StreamType == 2 { // audio
				mediaFile.Streams[i].Selected = (mediaFile.Streams[i].Index == *req.AudioIndex)
				s.db.Save(&mediaFile.Streams[i])
			}
		}
	}

	// Update subtitle selection
	if req.SubtitleIndex != nil {
		for i := range mediaFile.Streams {
			if mediaFile.Streams[i].StreamType == 3 { // subtitle
				if *req.SubtitleIndex < 0 {
					// Negative index means disable subtitles
					mediaFile.Streams[i].Selected = false
				} else {
					mediaFile.Streams[i].Selected = (mediaFile.Streams[i].Index == *req.SubtitleIndex)
				}
				s.db.Save(&mediaFile.Streams[i])
			}
		}
	}

	logger.Infof("Track selection updated for media %d: audio=%v subtitle=%v",
		mediaID, req.AudioIndex, req.SubtitleIndex)

	c.JSON(http.StatusOK, gin.H{
		"message":       "Track selection updated",
		"mediaId":       mediaID,
		"audioIndex":    req.AudioIndex,
		"subtitleIndex": req.SubtitleIndex,
	})
}

// getTrackPreferences returns the current user's (or profile's) track preferences.
// GET /api/playback/track-preferences
func (s *Server) getTrackPreferences(c *gin.Context) {
	// Try profile-based preferences first
	profileIDStr := c.Query("profileId")
	if profileIDStr != "" {
		profileID, err := strconv.ParseUint(profileIDStr, 10, 64)
		if err == nil {
			var profile models.UserProfile
			if err := s.db.First(&profile, profileID).Error; err == nil {
				c.JSON(http.StatusOK, trackPreferencesDTO{
					DefaultAudioLanguage:    profile.DefaultAudioLanguage,
					DefaultSubtitleLanguage: profile.DefaultSubtitleLanguage,
					AutoSelectAudio:         profile.AutoSelectAudio,
					AutoSelectSubtitle:      profile.AutoSelectSubtitle,
				})
				return
			}
		}
	}

	// Fall back to user-level defaults
	userID, _ := c.Get("userID")
	uid, ok := userID.(uint)
	if !ok {
		c.JSON(http.StatusOK, trackPreferencesDTO{
			DefaultAudioLanguage:    "en",
			DefaultSubtitleLanguage: "",
			AutoSelectAudio:         true,
			AutoSelectSubtitle:      1,
		})
		return
	}

	// Check if user has any profiles with preferences
	var profile models.UserProfile
	if err := s.db.Where("user_id = ?", uid).Order("id ASC").First(&profile).Error; err == nil {
		c.JSON(http.StatusOK, trackPreferencesDTO{
			DefaultAudioLanguage:    profile.DefaultAudioLanguage,
			DefaultSubtitleLanguage: profile.DefaultSubtitleLanguage,
			AutoSelectAudio:         profile.AutoSelectAudio,
			AutoSelectSubtitle:      profile.AutoSelectSubtitle,
		})
		return
	}

	// Default response when no profile exists
	c.JSON(http.StatusOK, trackPreferencesDTO{
		DefaultAudioLanguage:    "en",
		DefaultSubtitleLanguage: "",
		AutoSelectAudio:         true,
		AutoSelectSubtitle:      1,
	})
}

// updateTrackPreferences updates the current user's (or profile's) track preferences.
// PUT /api/playback/track-preferences
func (s *Server) updateTrackPreferences(c *gin.Context) {
	var req trackPreferencesDTO
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Validate subtitle mode
	if req.AutoSelectSubtitle < 0 || req.AutoSelectSubtitle > 3 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "autoSelectSubtitle must be 0-3"})
		return
	}

	// Determine target profile
	profileIDStr := c.Query("profileId")
	if profileIDStr != "" {
		profileID, err := strconv.ParseUint(profileIDStr, 10, 64)
		if err == nil {
			var profile models.UserProfile
			if err := s.db.First(&profile, profileID).Error; err == nil {
				profile.DefaultAudioLanguage = req.DefaultAudioLanguage
				profile.DefaultSubtitleLanguage = req.DefaultSubtitleLanguage
				profile.AutoSelectAudio = req.AutoSelectAudio
				profile.AutoSelectSubtitle = req.AutoSelectSubtitle
				s.db.Save(&profile)

				logger.Infof("Track preferences updated for profile %d", profileID)
				c.JSON(http.StatusOK, gin.H{
					"message": "Track preferences updated",
					"profile": req,
				})
				return
			}
		}
	}

	// Fall back to updating first profile for user
	userID, _ := c.Get("userID")
	uid, ok := userID.(uint)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "User not identified"})
		return
	}

	var profile models.UserProfile
	if err := s.db.Where("user_id = ?", uid).Order("id ASC").First(&profile).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No profile found for user"})
		return
	}

	profile.DefaultAudioLanguage = req.DefaultAudioLanguage
	profile.DefaultSubtitleLanguage = req.DefaultSubtitleLanguage
	profile.AutoSelectAudio = req.AutoSelectAudio
	profile.AutoSelectSubtitle = req.AutoSelectSubtitle
	s.db.Save(&profile)

	logger.Infof("Track preferences updated for user %d profile %d", uid, profile.ID)
	c.JSON(http.StatusOK, gin.H{
		"message": "Track preferences updated",
		"profile": req,
	})
}

// ---- helpers ----

// buildTrackResponseFromProbe creates the response from ffprobe data,
// merging the "selected" state from the database streams.
func buildTrackResponseFromProbe(mediaID uint, mf *models.MediaFile, probe *transcode.ProbeResult) trackInfoResponse {
	// Build a map of DB stream selections by index for fast lookup
	dbSelected := make(map[int]bool)
	for _, s := range mf.Streams {
		if s.Selected {
			dbSelected[s.Index] = true
		}
	}

	var video, audio, subtitle []trackStreamDTO
	var selAudio, selSub *int

	for _, s := range probe.Streams {
		dto := trackStreamDTO{
			Index:     s.Index,
			CodecName: s.CodecName,
			Language:  s.Language,
			Title:     s.Title,
			Channels:  s.Channels,
			Default:   s.Default,
			Forced:    s.Forced,
			BitRate:   s.BitRate,
			Width:     s.Width,
			Height:    s.Height,
			Selected:  dbSelected[s.Index],
		}

		switch s.CodecType {
		case "video":
			video = append(video, dto)
		case "audio":
			audio = append(audio, dto)
			if dto.Selected {
				idx := s.Index
				selAudio = &idx
			}
		case "subtitle":
			subtitle = append(subtitle, dto)
			if dto.Selected {
				idx := s.Index
				selSub = &idx
			}
		}
	}

	return trackInfoResponse{
		MediaID:  mediaID,
		FileID:   mf.ID,
		FilePath: mf.FilePath,
		Video:    video,
		Audio:    audio,
		Subtitle: subtitle,
		Selected: selectedTracksDTO{
			AudioIndex:    selAudio,
			SubtitleIndex: selSub,
		},
	}
}

// buildTrackResponseFromDB creates the response purely from database MediaStream records
// (used as fallback when ffprobe is unavailable).
func buildTrackResponseFromDB(mediaID uint, mf *models.MediaFile) trackInfoResponse {
	var video, audio, subtitle []trackStreamDTO
	var selAudio, selSub *int

	for _, s := range mf.Streams {
		dto := trackStreamDTO{
			Index:     s.Index,
			CodecName: s.Codec,
			Language:  s.Language,
			Title:     s.Title,
			Channels:  s.Channels,
			Default:   s.Default,
			Forced:    s.Forced,
			Width:     s.Width,
			Height:    s.Height,
			Selected:  s.Selected,
		}

		switch s.StreamType {
		case 1: // video
			video = append(video, dto)
		case 2: // audio
			audio = append(audio, dto)
			if dto.Selected {
				idx := s.Index
				selAudio = &idx
			}
		case 3: // subtitle
			subtitle = append(subtitle, dto)
			if dto.Selected {
				idx := s.Index
				selSub = &idx
			}
		}
	}

	return trackInfoResponse{
		MediaID:  mediaID,
		FileID:   mf.ID,
		FilePath: mf.FilePath,
		Video:    video,
		Audio:    audio,
		Subtitle: subtitle,
		Selected: selectedTracksDTO{
			AudioIndex:    selAudio,
			SubtitleIndex: selSub,
		},
	}
}
