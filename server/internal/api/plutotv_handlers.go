package api

import (
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/openflix/openflix-server/internal/providers"
)

// Package-level singleton for the PlutoTV client.
var plutoInstance *providers.PlutoTV
var plutoOnce sync.Once

func getPlutoTV() *providers.PlutoTV {
	plutoOnce.Do(func() {
		plutoInstance = providers.NewPlutoTV()
	})
	return plutoInstance
}

// getPlutoChannels handles GET /api/providers/pluto/channels
// Returns all available Pluto TV channels with logos and category info.
func (s *Server) getPlutoChannels(c *gin.Context) {
	pluto := getPlutoTV()

	channels, err := pluto.GetChannels(c.Request.Context())
	if err != nil {
		logger.Errorf("Failed to fetch Pluto TV channels: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch Pluto TV channels"})
		return
	}

	// Optional category filter
	category := c.Query("category")
	if category != "" {
		filtered := make([]providers.PlutoChannel, 0)
		for _, ch := range channels {
			if strings.EqualFold(ch.Category, category) {
				filtered = append(filtered, ch)
			}
		}
		channels = filtered
	}

	c.JSON(http.StatusOK, gin.H{
		"channels": channels,
		"total":    len(channels),
	})
}

// getPlutoGuide handles GET /api/providers/pluto/guide?hours=4
// Returns the current program guide for the specified number of hours.
func (s *Server) getPlutoGuide(c *gin.Context) {
	pluto := getPlutoTV()

	hours := 4
	if h := c.Query("hours"); h != "" {
		if parsed, err := strconv.Atoi(h); err == nil && parsed > 0 && parsed <= 48 {
			hours = parsed
		}
	}

	now := time.Now().UTC()
	start := now.Add(-30 * time.Minute) // Include currently-airing programs
	stop := now.Add(time.Duration(hours) * time.Hour)

	timelines, err := pluto.GetGuide(c.Request.Context(), start, stop)
	if err != nil {
		logger.Errorf("Failed to fetch Pluto TV guide: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch Pluto TV guide"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"timelines": timelines,
		"total":     len(timelines),
		"start":     start,
		"stop":      stop,
	})
}

// getPlutoCategories handles GET /api/providers/pluto/categories
// Returns a list of unique channel categories.
func (s *Server) getPlutoCategories(c *gin.Context) {
	pluto := getPlutoTV()

	categories, err := pluto.GetCategories(c.Request.Context())
	if err != nil {
		logger.Errorf("Failed to fetch Pluto TV categories: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch Pluto TV categories"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"categories": categories,
		"total":      len(categories),
	})
}

// searchPlutoChannels handles GET /api/providers/pluto/search?q=...
// Searches channels by name, category, or slug.
func (s *Server) searchPlutoChannels(c *gin.Context) {
	pluto := getPlutoTV()

	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Query parameter 'q' is required"})
		return
	}

	// Ensure channels are loaded before searching
	if _, err := pluto.GetChannels(c.Request.Context()); err != nil {
		logger.Errorf("Failed to load Pluto TV channels for search: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load Pluto TV channels"})
		return
	}

	results := pluto.SearchChannels(query)

	c.JSON(http.StatusOK, gin.H{
		"channels": results,
		"total":    len(results),
		"query":    query,
	})
}

// importPlutoChannels handles POST /api/providers/pluto/import
// Imports selected Pluto TV channels into the LiveTV channel database.
// Request body: { "channelIds": ["id1", "id2", ...] }
func (s *Server) importPlutoChannels(c *gin.Context) {
	pluto := getPlutoTV()

	var req struct {
		ChannelIDs []string `json:"channelIds" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: channelIds array is required"})
		return
	}

	if len(req.ChannelIDs) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "At least one channel ID is required"})
		return
	}

	// Fetch all channels so we can look up the requested IDs
	channels, err := pluto.GetChannels(c.Request.Context())
	if err != nil {
		logger.Errorf("Failed to fetch Pluto TV channels for import: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch Pluto TV channels"})
		return
	}

	channelMap := make(map[string]providers.PlutoChannel, len(channels))
	for _, ch := range channels {
		channelMap[ch.ID] = ch
	}

	imported := 0
	skipped := 0
	var errors []string

	for _, id := range req.ChannelIDs {
		plutoChannel, ok := channelMap[id]
		if !ok {
			errors = append(errors, "channel not found: "+id)
			continue
		}

		// Check if a channel with this stream URL already exists
		var existing models.Channel
		result := s.db.Where("stream_url = ?", plutoChannel.StreamURL).First(&existing)
		if result.Error == nil {
			skipped++
			continue
		}

		logo := plutoChannel.ColorLogo
		if logo == "" {
			logo = plutoChannel.Logo
		}

		channel := models.Channel{
			ChannelID:  "pluto-" + plutoChannel.ID,
			Number:     plutoChannel.Number,
			Name:       plutoChannel.Name,
			Logo:       logo,
			Group:      "Pluto TV - " + plutoChannel.Category,
			StreamURL:  plutoChannel.StreamURL,
			Enabled:    true,
			SourceType: "pluto",
			SourceName: "Pluto TV",
			TVGId:      "pluto-" + plutoChannel.ID,
		}

		if err := s.db.Create(&channel).Error; err != nil {
			logger.Errorf("Failed to import Pluto TV channel %s: %v", plutoChannel.Name, err)
			errors = append(errors, "failed to import "+plutoChannel.Name+": "+err.Error())
			continue
		}

		imported++
	}

	logger.Infof("Pluto TV import: %d imported, %d skipped, %d errors", imported, skipped, len(errors))

	c.JSON(http.StatusOK, gin.H{
		"imported": imported,
		"skipped":  skipped,
		"errors":   errors,
		"total":    len(req.ChannelIDs),
	})
}

// exportPlutoM3U handles GET /api/providers/pluto/export.m3u
// Exports all Pluto TV channels as an M3U playlist file.
func (s *Server) exportPlutoM3U(c *gin.Context) {
	pluto := getPlutoTV()

	m3u, err := pluto.ToM3U(c.Request.Context())
	if err != nil {
		logger.Errorf("Failed to export Pluto TV M3U: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate M3U playlist"})
		return
	}

	c.Header("Content-Type", "application/x-mpegurl")
	c.Header("Content-Disposition", "attachment; filename=plutotv.m3u")
	c.String(http.StatusOK, m3u)
}

// exportPlutoXMLTV handles GET /api/providers/pluto/export.xmltv
// Exports the Pluto TV EPG as XMLTV-formatted XML.
func (s *Server) exportPlutoXMLTV(c *gin.Context) {
	pluto := getPlutoTV()

	hours := 4
	if h := c.Query("hours"); h != "" {
		if parsed, err := strconv.Atoi(h); err == nil && parsed > 0 && parsed <= 48 {
			hours = parsed
		}
	}

	xmltv, err := pluto.ToXMLTV(c.Request.Context(), hours)
	if err != nil {
		logger.Errorf("Failed to export Pluto TV XMLTV: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate XMLTV guide"})
		return
	}

	c.Header("Content-Type", "application/xml")
	c.Header("Content-Disposition", "attachment; filename=plutotv.xmltv")
	c.String(http.StatusOK, xmltv)
}
