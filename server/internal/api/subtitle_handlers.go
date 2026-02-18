package api

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/openflix/openflix-server/internal/subtitles"
)

const subtitleConfigKey = "subtitle_config"

// ========== Subtitle Search ==========

// GET /api/subtitles/search?mediaId=123 or ?title=Movie&year=2024&languages=en,fr
func (s *Server) searchSubtitles(c *gin.Context) {
	if s.subtitleManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Subtitle manager not initialized"})
		return
	}

	mediaIDStr := c.Query("mediaId")
	title := c.Query("title")
	yearStr := c.Query("year")
	langStr := c.Query("languages")

	var languages []string
	if langStr != "" {
		languages = subtitleSplitLanguages(langStr)
	}

	var result *subtitles.SearchResponse
	var err error

	if mediaIDStr != "" {
		mediaID, parseErr := strconv.ParseUint(mediaIDStr, 10, 64)
		if parseErr != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mediaId"})
			return
		}

		var mediaItem models.MediaItem
		if dbErr := s.db.Preload("MediaFiles").First(&mediaItem, uint(mediaID)).Error; dbErr != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
			return
		}

		result, err = s.subtitleManager.SearchForMedia(&mediaItem, languages)
	} else if title != "" {
		year := 0
		if yearStr != "" {
			year, _ = strconv.Atoi(yearStr)
		}
		result, err = s.subtitleManager.SearchByTitleYear(title, year, languages)
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Provide either mediaId or title parameter"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"totalCount": result.TotalCount,
		"totalPages": result.TotalPages,
		"page":       result.Page,
		"data":       result.Data,
	})
}

// ========== Subtitle Download ==========

// POST /api/subtitles/download
func (s *Server) downloadSubtitle(c *gin.Context) {
	if s.subtitleManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Subtitle manager not initialized"})
		return
	}

	var req struct {
		MediaItemID uint   `json:"mediaItemId" binding:"required"`
		FileID      int    `json:"fileId" binding:"required"`
		Language    string `json:"language" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	downloaded, err := s.subtitleManager.DownloadSubtitle(req.MediaItemID, req.FileID, req.Language)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":  true,
		"subtitle": downloaded,
	})
}

// ========== List Subtitles for Media ==========

// GET /api/subtitles/:mediaId
func (s *Server) getSubtitlesForMedia(c *gin.Context) {
	if s.subtitleManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Subtitle manager not initialized"})
		return
	}

	mediaID, err := strconv.ParseUint(c.Param("mediaId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mediaId"})
		return
	}

	localSubs, downloadedSubs, err := s.subtitleManager.GetSubtitlesForMedia(uint(mediaID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"local":      localSubs,
		"downloaded": downloadedSubs,
	})
}

// ========== Delete Subtitle ==========

// DELETE /api/subtitles/:mediaId/:lang
func (s *Server) deleteSubtitle(c *gin.Context) {
	if s.subtitleManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Subtitle manager not initialized"})
		return
	}

	mediaID, err := strconv.ParseUint(c.Param("mediaId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mediaId"})
		return
	}

	lang := c.Param("lang")
	if lang == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Language parameter required"})
		return
	}

	if err := s.subtitleManager.DeleteSubtitle(uint(mediaID), lang); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Subtitle deleted",
	})
}

// ========== Subtitle Config ==========

// GET /api/subtitles/config
func (s *Server) getSubtitleConfig(c *gin.Context) {
	if s.subtitleManager == nil {
		c.JSON(http.StatusOK, gin.H{
			"apiKeyConfigured": false,
			"autoDownload":     false,
			"languages":        []string{"en"},
		})
		return
	}

	cfg := s.subtitleManager.GetConfig()
	c.JSON(http.StatusOK, gin.H{
		"apiKeyConfigured": cfg.APIKey != "",
		"autoDownload":     cfg.AutoDownload,
		"languages":        cfg.Languages,
	})
}

// PUT /api/subtitles/config
func (s *Server) updateSubtitleConfig(c *gin.Context) {
	var req struct {
		APIKey       *string  `json:"apiKey"`
		AutoDownload *bool    `json:"autoDownload"`
		Languages    []string `json:"languages"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	// Load existing config
	cfg := subtitles.SubtitleConfig{
		Languages: []string{"en"},
	}
	if s.subtitleManager != nil {
		cfg = s.subtitleManager.GetConfig()
	}

	// Apply updates
	if req.APIKey != nil {
		cfg.APIKey = *req.APIKey
	}
	if req.AutoDownload != nil {
		cfg.AutoDownload = *req.AutoDownload
	}
	if req.Languages != nil {
		cfg.Languages = req.Languages
	}

	// Ensure at least one language
	if len(cfg.Languages) == 0 {
		cfg.Languages = []string{"en"}
	}

	// Save to database
	configJSON, err := json.Marshal(cfg)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to serialize config"})
		return
	}
	s.setSetting(subtitleConfigKey, string(configJSON))

	// Update or create manager
	if s.subtitleManager != nil {
		s.subtitleManager.UpdateConfig(cfg)
	} else {
		s.subtitleManager = subtitles.NewSubtitleManager(s.db, cfg)
	}

	logger.Info("Subtitle configuration updated")

	c.JSON(http.StatusOK, gin.H{
		"success":          true,
		"apiKeyConfigured": cfg.APIKey != "",
		"autoDownload":     cfg.AutoDownload,
		"languages":        cfg.Languages,
	})
}

// ========== Initialization ==========

// loadSubtitleConfig reads the persisted subtitle configuration from the settings table
// and initializes the SubtitleManager. Called during server startup.
func (s *Server) loadSubtitleConfig() {
	jsonStr := s.getSettingString(subtitleConfigKey, "")
	if jsonStr == "" {
		// No config saved yet - initialize with empty config
		s.subtitleManager = subtitles.NewSubtitleManager(s.db, subtitles.SubtitleConfig{
			Languages: []string{"en"},
		})
		return
	}

	var cfg subtitles.SubtitleConfig
	if err := json.Unmarshal([]byte(jsonStr), &cfg); err != nil {
		logger.Warnf("Failed to parse subtitle config: %v", err)
		s.subtitleManager = subtitles.NewSubtitleManager(s.db, subtitles.SubtitleConfig{
			Languages: []string{"en"},
		})
		return
	}

	s.subtitleManager = subtitles.NewSubtitleManager(s.db, cfg)

	if cfg.APIKey != "" {
		logger.Info("OpenSubtitles integration enabled")
	}
}

// ========== Helpers ==========

// subtitleSplitLanguages splits a comma-separated language string and trims whitespace.
func subtitleSplitLanguages(s string) []string {
	parts := make([]string, 0)
	for _, p := range strings.Split(s, ",") {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			parts = append(parts, trimmed)
		}
	}
	return parts
}
