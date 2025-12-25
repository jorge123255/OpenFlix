package api

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/epg/gracenote"
	"github.com/openflix/openflix-server/internal/livetv"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Live TV Sources ============

// getLiveTVSources returns all M3U sources
func (s *Server) getLiveTVSources(c *gin.Context) {
	var sources []models.M3USource
	if err := s.db.Find(&sources).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch sources"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"sources": sources})
}

// addLiveTVSource adds a new M3U source
func (s *Server) addLiveTVSource(c *gin.Context) {
	var req struct {
		Name   string `json:"name" binding:"required"`
		URL    string `json:"url" binding:"required"`
		EPGUrl string `json:"epgUrl"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	source := models.M3USource{
		Name:    req.Name,
		URL:     req.URL,
		EPGUrl:  req.EPGUrl,
		Enabled: true,
	}

	if err := s.db.Create(&source).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create source"})
		return
	}

	// Fetch and parse M3U in background
	go func() {
		parser := livetv.NewM3UParser(s.db)
		if err := parser.RefreshSource(&source); err != nil {
			// Log error but don't fail
			println("Failed to refresh source:", err.Error())
		}

		// Also fetch EPG if URL provided
		if source.EPGUrl != "" {
			epgParser := livetv.NewEPGParser(s.db)
			if err := epgParser.RefreshEPG(&source); err != nil {
				println("Failed to refresh EPG:", err.Error())
			}
		}
	}()

	c.JSON(http.StatusCreated, source)
}

// updateLiveTVSource updates an M3U source
func (s *Server) updateLiveTVSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	var source models.M3USource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source not found"})
		return
	}

	var req struct {
		Name    string `json:"name"`
		URL     string `json:"url"`
		EPGUrl  string `json:"epgUrl"`
		Enabled *bool  `json:"enabled"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Name != "" {
		source.Name = req.Name
	}
	if req.URL != "" {
		source.URL = req.URL
	}
	if req.EPGUrl != "" {
		source.EPGUrl = req.EPGUrl
	}
	if req.Enabled != nil {
		source.Enabled = *req.Enabled
	}

	if err := s.db.Save(&source).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update source"})
		return
	}

	c.JSON(http.StatusOK, source)
}

// deleteLiveTVSource deletes an M3U source and its channels
func (s *Server) deleteLiveTVSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	// Delete channels first
	s.db.Where("m3_u_source_id = ?", id).Delete(&models.Channel{})

	// Delete source
	if err := s.db.Delete(&models.M3USource{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete source"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Source deleted"})
}

// refreshLiveTVSource refreshes channels from an M3U source
func (s *Server) refreshLiveTVSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	var source models.M3USource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source not found"})
		return
	}

	parser := livetv.NewM3UParser(s.db)
	if err := parser.RefreshSource(&source); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to refresh source: " + err.Error()})
		return
	}

	// Also refresh EPG if URL provided
	if source.EPGUrl != "" {
		epgParser := livetv.NewEPGParser(s.db)
		if err := epgParser.RefreshEPG(&source); err != nil {
			// Log but don't fail the request
			println("Failed to refresh EPG:", err.Error())
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Source refreshed"})
}

// ============ Channels ============

// getChannels returns all channels, optionally filtered
func (s *Server) getChannels(c *gin.Context) {
	query := s.db.Model(&models.Channel{})

	// Filter by source
	if sourceID := c.Query("sourceId"); sourceID != "" {
		query = query.Where("m3u_source_id = ?", sourceID)
	}

	// Filter by group
	if group := c.Query("group"); group != "" {
		query = query.Where("group = ?", group)
	}

	// Filter by enabled
	if enabled := c.Query("enabled"); enabled != "" {
		query = query.Where("enabled = ?", enabled == "true")
	}

	var channels []models.Channel
	if err := query.Order("number, name").Find(&channels).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch channels"})
		return
	}

	// Enrich with current program info
	epgParser := livetv.NewEPGParser(s.db)
	type ChannelWithProgram struct {
		models.Channel
		NowPlaying  *models.Program `json:"nowPlaying,omitempty"`
		NextProgram *models.Program `json:"nextProgram,omitempty"`
	}

	enrichedChannels := make([]ChannelWithProgram, len(channels))
	for i, ch := range channels {
		enrichedChannels[i].Channel = ch
		if ch.ChannelID != "" {
			if program, err := epgParser.GetCurrentProgram(ch.ChannelID); err == nil {
				enrichedChannels[i].NowPlaying = program
			}
			if program, err := epgParser.GetNextProgram(ch.ChannelID); err == nil {
				enrichedChannels[i].NextProgram = program
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"channels": enrichedChannels})
}

// getChannel returns a single channel with EPG info
func (s *Server) getChannel(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	var channel models.Channel
	if err := s.db.First(&channel, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not found"})
		return
	}

	// Get current and next program
	type ChannelWithProgram struct {
		models.Channel
		NowPlaying  *models.Program `json:"nowPlaying,omitempty"`
		NextProgram *models.Program `json:"nextProgram,omitempty"`
	}

	response := ChannelWithProgram{Channel: channel}
	if channel.ChannelID != "" {
		epgParser := livetv.NewEPGParser(s.db)
		if program, err := epgParser.GetCurrentProgram(channel.ChannelID); err == nil {
			response.NowPlaying = program
		}
		if program, err := epgParser.GetNextProgram(channel.ChannelID); err == nil {
			response.NextProgram = program
		}
	}

	c.JSON(http.StatusOK, response)
}

// updateChannel updates a channel (enable/disable, rename, renumber)
func (s *Server) updateChannel(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	var channel models.Channel
	if err := s.db.First(&channel, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not found"})
		return
	}

	var req struct {
		Name        string `json:"name"`
		Number      *int   `json:"number"`
		Logo        string `json:"logo"`
		Group       string `json:"group"`
		Enabled     *bool  `json:"enabled"`
		EPGSourceID *uint  `json:"epgSourceId"`
		ChannelID   string `json:"channelId"` // EPG channel ID for mapping
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Name != "" {
		channel.Name = req.Name
	}
	if req.Number != nil {
		channel.Number = *req.Number
	}
	if req.Logo != "" {
		channel.Logo = req.Logo
	}
	if req.Group != "" {
		channel.Group = req.Group
	}
	if req.Enabled != nil {
		channel.Enabled = *req.Enabled
	}
	if req.EPGSourceID != nil {
		channel.EPGSourceID = req.EPGSourceID
	}
	if req.ChannelID != "" {
		channel.ChannelID = req.ChannelID
	}

	if err := s.db.Save(&channel).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update channel"})
		return
	}

	c.JSON(http.StatusOK, channel)
}

// bulkMapChannels maps multiple M3U channels to the same EPG channel
func (s *Server) bulkMapChannels(c *gin.Context) {
	var req struct {
		ChannelIDs  []uint `json:"channelIds" binding:"required"`
		EPGSourceID uint   `json:"epgSourceId" binding:"required"`
		EPGChannelID string `json:"epgChannelId" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Update all channels in a transaction
	tx := s.db.Begin()
	updated := 0
	for _, channelID := range req.ChannelIDs {
		var channel models.Channel
		if err := tx.First(&channel, channelID).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusNotFound, gin.H{"error": fmt.Sprintf("Channel %d not found", channelID)})
			return
		}

		channel.EPGSourceID = &req.EPGSourceID
		channel.ChannelID = req.EPGChannelID

		if err := tx.Save(&channel).Error; err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update channels"})
			return
		}
		updated++
	}

	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to commit transaction"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": fmt.Sprintf("Successfully mapped %d channels", updated),
		"updated": updated,
	})
}

// unmapChannel removes EPG mapping from a channel
func (s *Server) unmapChannel(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	var channel models.Channel
	if err := s.db.First(&channel, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not found"})
		return
	}

	// Clear EPG mapping
	channel.EPGSourceID = nil
	channel.ChannelID = ""

	if err := s.db.Save(&channel).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unmap channel"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Channel unmapped successfully"})
}

// toggleChannelFavorite toggles the favorite status of a channel
func (s *Server) toggleChannelFavorite(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	var channel models.Channel
	if err := s.db.First(&channel, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not found"})
		return
	}

	// Toggle favorite status
	channel.IsFavorite = !channel.IsFavorite

	if err := s.db.Save(&channel).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update channel"})
		return
	}

	c.JSON(http.StatusOK, channel)
}

// ============ EPG Guide ============

// getGuide returns EPG data for a time range
func (s *Server) getGuide(c *gin.Context) {
	// Parse time range (defaults to next 24 hours)
	now := time.Now()
	start := now
	end := now.Add(24 * time.Hour)

	if startStr := c.Query("start"); startStr != "" {
		if t, err := time.Parse(time.RFC3339, startStr); err == nil {
			start = t
		}
	}
	if endStr := c.Query("end"); endStr != "" {
		if t, err := time.Parse(time.RFC3339, endStr); err == nil {
			end = t
		}
	}

	// Get channels
	var channels []models.Channel
	channelQuery := s.db.Where("enabled = ?", true).Order("number, name")
	if sourceID := c.Query("sourceId"); sourceID != "" {
		channelQuery = channelQuery.Where("m3u_source_id = ?", sourceID)
	}
	if err := channelQuery.Find(&channels).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch channels"})
		return
	}

	// Get channel IDs for EPG query
	channelIDs := make([]string, 0, len(channels))
	for _, ch := range channels {
		if ch.ChannelID != "" {
			channelIDs = append(channelIDs, ch.ChannelID)
		}
	}

	// Get programs
	epgParser := livetv.NewEPGParser(s.db)
	programs, err := epgParser.GetGuide(start, end, channelIDs)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch programs"})
		return
	}

	// Group programs by channel
	programsByChannel := make(map[string][]models.Program)
	for _, prog := range programs {
		programsByChannel[prog.ChannelID] = append(programsByChannel[prog.ChannelID], prog)
	}

	c.JSON(http.StatusOK, gin.H{
		"channels":          channels,
		"programs":          programsByChannel,
		"start":             start,
		"end":               end,
	})
}

// getChannelGuide returns EPG for a single channel
func (s *Server) getChannelGuide(c *gin.Context) {
	channelID := c.Param("channelId")

	// Parse time range
	now := time.Now()
	start := now
	end := now.Add(24 * time.Hour)

	if startStr := c.Query("start"); startStr != "" {
		if t, err := time.Parse(time.RFC3339, startStr); err == nil {
			start = t
		}
	}
	if endStr := c.Query("end"); endStr != "" {
		if t, err := time.Parse(time.RFC3339, endStr); err == nil {
			end = t
		}
	}

	// Get channel
	var channel models.Channel
	if err := s.db.First(&channel, channelID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not found"})
		return
	}

	// Get programs
	epgParser := livetv.NewEPGParser(s.db)
	programs, err := epgParser.GetGuide(start, end, []string{channel.ChannelID})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch programs"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"channel":  channel,
		"programs": programs,
		"start":    start,
		"end":      end,
	})
}

// getWhatsOnNow returns what's currently playing on all channels
func (s *Server) getWhatsOnNow(c *gin.Context) {
	// Get enabled channels
	var channels []models.Channel
	if err := s.db.Where("enabled = ?", true).Order("number, name").Find(&channels).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch channels"})
		return
	}

	// Flat structure that Flutter expects
	type ChannelWithPrograms struct {
		ID          uint            `json:"id"`
		SourceID    uint            `json:"sourceId"`
		ChannelID   string          `json:"channelId"`
		Number      int             `json:"number"`
		Name        string          `json:"name"`
		Logo        string          `json:"logo,omitempty"`
		Group       string          `json:"group,omitempty"`
		StreamURL   string          `json:"streamUrl"`
		Enabled     bool            `json:"enabled"`
		IsFavorite  bool            `json:"isFavorite"`
		NowPlaying  *models.Program `json:"nowPlaying,omitempty"`
		NextProgram *models.Program `json:"nextProgram,omitempty"`
	}

	epgParser := livetv.NewEPGParser(s.db)
	results := make([]ChannelWithPrograms, 0, len(channels))

	for _, ch := range channels {
		item := ChannelWithPrograms{
			ID:         ch.ID,
			SourceID:   ch.M3USourceID,
			ChannelID:  ch.ChannelID,
			Number:     ch.Number,
			Name:       ch.Name,
			Logo:       ch.Logo,
			Group:      ch.Group,
			StreamURL:  ch.StreamURL,
			Enabled:    ch.Enabled,
			IsFavorite: ch.IsFavorite,
		}
		if ch.ChannelID != "" {
			if program, err := epgParser.GetCurrentProgram(ch.ChannelID); err == nil {
				item.NowPlaying = program
			}
			if program, err := epgParser.GetNextProgram(ch.ChannelID); err == nil {
				item.NextProgram = program
			}
		}
		results = append(results, item)
	}

	c.JSON(http.StatusOK, gin.H{"channels": results})
}

// ============ EPG Sources ============

// getEPGSources returns all standalone EPG sources
func (s *Server) getEPGSources(c *gin.Context) {
	var sources []models.EPGSource
	if err := s.db.Find(&sources).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch EPG sources"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"sources": sources})
}

// previewEPGSource previews channels available from Gracenote for a postal code
func (s *Server) previewEPGSource(c *gin.Context) {
	var req struct {
		PostalCode string `json:"postalCode" binding:"required"`
		Affiliate  string `json:"affiliate"` // Optional: provider headend ID
		Hours      int    `json:"hours"`     // Optional: defaults to 6
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Set default hours
	if req.Hours == 0 {
		req.Hours = 6
	}

	// Create Gracenote client
	gnClient := gracenote.NewBrowserClient(gracenote.Config{
		BaseURL:   "https://tvlistings.gracenote.com",
		UserAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
		Timeout:   30 * time.Second,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	// Discover providers for this postal code
	providers, err := gnClient.DiscoverProviders(ctx, req.PostalCode, "USA")
	if err != nil || len(providers) == 0 {
		// Fallback to known headend IDs for major markets
		fallbackProvider := getFallbackProvider(req.PostalCode)
		if fallbackProvider == nil {
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to discover providers: %v", err)})
			} else {
				c.JSON(http.StatusBadRequest, gin.H{"error": "No providers found for this postal code. Try a different ZIP code or check if your location is supported."})
			}
			return
		}
		providers = []gracenote.Provider{*fallbackProvider}
	}

	// Use the first provider (prioritized: Cable > Satellite > Antenna)
	// Or use the specified affiliate if provided
	var selectedProvider gracenote.Provider
	if req.Affiliate != "" {
		// Find provider by headend ID
		for _, p := range providers {
			if p.HeadendID == req.Affiliate {
				selectedProvider = p
				break
			}
		}
		if selectedProvider.HeadendID == "" {
			// Affiliate not found, use first provider
			selectedProvider = providers[0]
		}
	} else {
		selectedProvider = providers[0]
	}

	// Build providers list for frontend
	type ProviderInfo struct {
		HeadendID string `json:"headendId"`
		Name      string `json:"name"`
		Type      string `json:"type"`
		Location  string `json:"location"`
	}
	var providerInfos []ProviderInfo
	for _, p := range providers {
		providerInfos = append(providerInfos, ProviderInfo{
			HeadendID: p.HeadendID,
			Name:      p.Name,
			Type:      p.Type,
			Location:  p.Location,
		})
	}

	// Determine which postal code to use for the API
	// If using a fallback provider with a different region, use the fallback postal code
	apiPostalCode := req.PostalCode
	if selectedProvider.FallbackPostalCode != "" {
		apiPostalCode = selectedProvider.FallbackPostalCode
		fmt.Printf("Using fallback postal code %s (user entered %s) for headend %s\n",
			apiPostalCode, req.PostalCode, selectedProvider.HeadendID)
	}

	// Fetch listings for the selected provider
	gridResp, err := gnClient.GetListingsForProvider(ctx, selectedProvider, apiPostalCode, "USA", req.Hours)
	if err != nil {
		// If API fails, still return provider info so user can add the source
		// The actual EPG fetch might work later with proper cookies
		fmt.Printf("Warning: Gracenote API failed for %s: %v (returning provider info anyway)\n", req.PostalCode, err)
		c.JSON(http.StatusOK, gin.H{
			"affiliate":          selectedProvider.HeadendID,
			"affiliateName":      selectedProvider.Name,
			"postalCode":         req.PostalCode,
			"totalChannels":      0,
			"previewChannels":    []interface{}{},
			"totalPrograms":      0,
			"availableProviders": providerInfos,
			"previewUnavailable": true,
			"message":            "Channel preview unavailable, but you can still add this EPG source. Guide data will be fetched when you refresh.",
		})
		return
	}

	// Build preview response with sample channels
	type ChannelPreview struct {
		ChannelID     string `json:"channelId"`
		CallSign      string `json:"callSign"`
		ChannelNo     string `json:"channelNo"`
		AffiliateName string `json:"affiliateName"`
		ProgramCount  int    `json:"programCount"`
	}

	var channelPreviews []ChannelPreview
	maxPreview := 30 // Show first 30 channels as preview

	for i, channel := range gridResp.Channels {
		if i >= maxPreview {
			break
		}
		channelPreviews = append(channelPreviews, ChannelPreview{
			ChannelID:     channel.ChannelID,
			CallSign:      channel.CallSign,
			ChannelNo:     channel.ChannelNo,
			AffiliateName: channel.AffiliateName,
			ProgramCount:  len(channel.Events),
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"affiliate":          selectedProvider.HeadendID,
		"affiliateName":      selectedProvider.Name,
		"postalCode":         req.PostalCode,
		"totalChannels":      len(gridResp.Channels),
		"previewChannels":    channelPreviews,
		"totalPrograms":      getTotalPrograms(gridResp),
		"availableProviders": providerInfos,
	})
}

// getFallbackProvider returns a known provider for major markets when discovery fails
func getFallbackProvider(postalCode string) *gracenote.Provider {
	if len(postalCode) < 3 {
		return nil
	}

	zipPrefix := postalCode[:3]

	// Known headend IDs for major US markets
	// These were discovered by observing Gracenote's actual API responses
	marketHeadends := map[string]struct {
		headendID string
		name      string
		location  string
	}{
		// New York metro area (100-104, 106-119)
		"100": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"101": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"102": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"103": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"104": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"106": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"107": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"108": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"109": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"110": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"111": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"112": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"113": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"114": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"115": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"116": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"117": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"118": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},
		"119": {"NY31519", "Charter Spectrum Southern Manhattan - Digital", "New York"},

		// Los Angeles area (900-935) - CA04956 verified from Gracenote
		"900": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"901": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"902": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"903": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"904": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"905": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"906": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"907": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"908": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"910": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"911": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"912": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"913": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"914": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"915": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"917": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},
		"918": {"CA04956", "Charter Spectrum - Digital", "Los Angeles"},

		// Chicago area (600-609) - IL54437 verified from Gracenote
		"600": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},
		"601": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},
		"602": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},
		"603": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},
		"604": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},
		"605": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},
		"606": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},
		"607": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},
		"608": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},
		"609": {"IL54437", "Xfinity Chicago - Digital", "Chicago"},

		// Seattle area (980-984) - WA63873 verified from Gracenote
		"980": {"WA63873", "Xfinity King County - Digital", "Seattle"},
		"981": {"WA63873", "Xfinity King County - Digital", "Seattle"},
		"982": {"WA63873", "Xfinity King County - Digital", "Seattle"},
		"983": {"WA63873", "Xfinity King County - Digital", "Seattle"},
		"984": {"WA63873", "Xfinity King County - Digital", "Seattle"},

		// San Francisco area (940-949)
		"940": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},
		"941": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},
		"942": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},
		"943": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},
		"944": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},
		"945": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},
		"946": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},
		"947": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},
		"948": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},
		"949": {"CA57858", "Comcast San Francisco - Digital", "San Francisco"},

		// Boston area (010-027) - MA20483 verified from Gracenote
		"010": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"011": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"012": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"013": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"014": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"015": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"016": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"017": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"018": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"019": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"020": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"021": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"022": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"023": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"024": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"025": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"026": {"MA20483", "Xfinity Boston - Digital", "Boston"},
		"027": {"MA20483", "Xfinity Boston - Digital", "Boston"},

		// Dallas area (750-759) - TX42822 verified from Gracenote
		"750": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},
		"751": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},
		"752": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},
		"753": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},
		"754": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},
		"755": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},
		"756": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},
		"757": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},
		"758": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},
		"759": {"TX42822", "Charter Spectrum North TX - Digital", "Dallas"},

		// Houston area (770-779)
		"770": {"TX60143", "Comcast Houston - Digital", "Houston"},
		"771": {"TX60143", "Comcast Houston - Digital", "Houston"},
		"772": {"TX60143", "Comcast Houston - Digital", "Houston"},
		"773": {"TX60143", "Comcast Houston - Digital", "Houston"},
		"774": {"TX60143", "Comcast Houston - Digital", "Houston"},
		"775": {"TX60143", "Comcast Houston - Digital", "Houston"},
		"776": {"TX60143", "Comcast Houston - Digital", "Houston"},
		"777": {"TX60143", "Comcast Houston - Digital", "Houston"},
		"778": {"TX60143", "Comcast Houston - Digital", "Houston"},
		"779": {"TX60143", "Comcast Houston - Digital", "Houston"},

		// Phoenix area (850-853, 855-857, 859-860)
		"850": {"AZ51008", "Cox Phoenix - Digital", "Phoenix"},
		"851": {"AZ51008", "Cox Phoenix - Digital", "Phoenix"},
		"852": {"AZ51008", "Cox Phoenix - Digital", "Phoenix"},
		"853": {"AZ51008", "Cox Phoenix - Digital", "Phoenix"},
		"855": {"AZ51008", "Cox Phoenix - Digital", "Phoenix"},
		"856": {"AZ51008", "Cox Phoenix - Digital", "Phoenix"},
		"857": {"AZ51008", "Cox Phoenix - Digital", "Phoenix"},
		"859": {"AZ51008", "Cox Phoenix - Digital", "Phoenix"},
		"860": {"AZ51008", "Cox Phoenix - Digital", "Phoenix"},

		// Philadelphia area (190-196) - PA37745 verified from Gracenote
		"190": {"PA37745", "Xfinity Center City - Digital", "Philadelphia"},
		"191": {"PA37745", "Xfinity Center City - Digital", "Philadelphia"},
		"192": {"PA37745", "Xfinity Center City - Digital", "Philadelphia"},
		"193": {"PA37745", "Xfinity Center City - Digital", "Philadelphia"},
		"194": {"PA37745", "Xfinity Center City - Digital", "Philadelphia"},
		"195": {"PA37745", "Xfinity Center City - Digital", "Philadelphia"},
		"196": {"PA37745", "Xfinity Center City - Digital", "Philadelphia"},

		// Miami area (330-334) - FL67353 verified from Gracenote
		"330": {"FL67353", "AT&T U-verse TV - Digital", "Miami"},
		"331": {"FL67353", "AT&T U-verse TV - Digital", "Miami"},
		"332": {"FL67353", "AT&T U-verse TV - Digital", "Miami"},
		"333": {"FL67353", "AT&T U-verse TV - Digital", "Miami"},
		"334": {"FL67353", "AT&T U-verse TV - Digital", "Miami"},

		// Atlanta area (300-311) - GA67745 verified from Gracenote
		"300": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"301": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"302": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"303": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"304": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"305": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"306": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"307": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"308": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"309": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"310": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},
		"311": {"GA67745", "Xfinity Atlanta - Digital", "Atlanta"},

		// Denver area (800-816) - CO05539 verified from Gracenote
		"800": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"801": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"802": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"803": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"804": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"805": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"806": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"807": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"808": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"809": {"CO05539", "Xfinity Denver - Digital", "Denver"},
		"810": {"CO05539", "Xfinity Denver - Digital", "Denver"},

		// Detroit area (480-489)
		"480": {"MI58145", "Comcast Detroit - Digital", "Detroit"},
		"481": {"MI58145", "Comcast Detroit - Digital", "Detroit"},
		"482": {"MI58145", "Comcast Detroit - Digital", "Detroit"},
		"483": {"MI58145", "Comcast Detroit - Digital", "Detroit"},
		"484": {"MI58145", "Comcast Detroit - Digital", "Detroit"},
		"485": {"MI58145", "Comcast Detroit - Digital", "Detroit"},
		"486": {"MI58145", "Comcast Detroit - Digital", "Detroit"},
		"487": {"MI58145", "Comcast Detroit - Digital", "Detroit"},
		"488": {"MI58145", "Comcast Detroit - Digital", "Detroit"},
		"489": {"MI58145", "Comcast Detroit - Digital", "Detroit"},

		// Washington DC area (200-205)
		"200": {"DC50162", "Comcast Washington DC - Digital", "Washington DC"},
		"201": {"DC50162", "Comcast Washington DC - Digital", "Washington DC"},
		"202": {"DC50162", "Comcast Washington DC - Digital", "Washington DC"},
		"203": {"DC50162", "Comcast Washington DC - Digital", "Washington DC"},
		"204": {"DC50162", "Comcast Washington DC - Digital", "Washington DC"},
		"205": {"DC50162", "Comcast Washington DC - Digital", "Washington DC"},
	}

	if market, ok := marketHeadends[zipPrefix]; ok {
		return &gracenote.Provider{
			HeadendID: market.headendID,
			Name:      market.name,
			Type:      "Cable",
			Location:  market.location,
			LineupID:  fmt.Sprintf("USA-%s-DEFAULT", market.headendID),
		}
	}

	// If no specific market found, try to look up state and use state default
	state := lookupStateFromZIP(postalCode)
	if state != "" {
		if stateDefault, ok := getStateDefaultHeadend(state); ok {
			return &gracenote.Provider{
				HeadendID:          stateDefault.headendID,
				Name:               stateDefault.name,
				Type:               "Cable",
				Location:           stateDefault.location,
				LineupID:           fmt.Sprintf("USA-%s-DEFAULT", stateDefault.headendID),
				FallbackPostalCode: stateDefault.fallbackPostalCode, // Use matching postal code for this headend
			}
		}
	}

	return nil
}

// zipCodeResponse represents the response from zippopotam.us API
type zipCodeResponse struct {
	Places []struct {
		PlaceName         string `json:"place name"`
		StateAbbreviation string `json:"state abbreviation"`
	} `json:"places"`
}

// lookupStateFromZIP uses the free zippopotam.us API to get state from ZIP code
func lookupStateFromZIP(postalCode string) string {
	url := fmt.Sprintf("https://api.zippopotam.us/us/%s", postalCode)

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return ""
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return ""
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return ""
	}

	var zipResp zipCodeResponse
	if err := json.Unmarshal(body, &zipResp); err != nil {
		return ""
	}

	if len(zipResp.Places) > 0 {
		return zipResp.Places[0].StateAbbreviation
	}

	return ""
}

// stateHeadend holds info for a state's default headend
type stateHeadend struct {
	headendID          string
	name               string
	location           string
	fallbackPostalCode string // Postal code that works with this headend
}

// getStateDefaultHeadend returns the default headend for a state
// Uses verified regional headend IDs discovered from Gracenote API.
// Each state maps to the nearest major market for better local channel coverage.
func getStateDefaultHeadend(state string) (stateHeadend, bool) {
	// Regional headend mappings with verified IDs from Gracenote
	stateDefaults := map[string]stateHeadend{
		// New York area (NY31519 - Charter Spectrum Southern Manhattan)
		"NJ": {"NY31519", "Charter Spectrum", "New York", "10001"},
		"NY": {"NY31519", "Charter Spectrum", "New York", "10001"},

		// Boston area (MA20483 - Xfinity Boston)
		"CT": {"MA20483", "Xfinity Boston", "Boston", "02108"},
		"MA": {"MA20483", "Xfinity Boston", "Boston", "02108"},
		"ME": {"MA20483", "Xfinity Boston", "Boston", "02108"},
		"NH": {"MA20483", "Xfinity Boston", "Boston", "02108"},
		"RI": {"MA20483", "Xfinity Boston", "Boston", "02108"},
		"VT": {"MA20483", "Xfinity Boston", "Boston", "02108"},

		// Philadelphia area (PA37745 - Xfinity Center City)
		"DE": {"PA37745", "Xfinity Philadelphia", "Philadelphia", "19103"},
		"MD": {"PA37745", "Xfinity Philadelphia", "Philadelphia", "19103"},
		"PA": {"PA37745", "Xfinity Philadelphia", "Philadelphia", "19103"},
		"DC": {"PA37745", "Xfinity Philadelphia", "Philadelphia", "19103"},

		// Atlanta area (GA67745 - Xfinity Atlanta)
		"AL": {"GA67745", "Xfinity Atlanta", "Atlanta", "30301"},
		"GA": {"GA67745", "Xfinity Atlanta", "Atlanta", "30301"},
		"KY": {"GA67745", "Xfinity Atlanta", "Atlanta", "30301"},
		"MS": {"GA67745", "Xfinity Atlanta", "Atlanta", "30301"},
		"NC": {"GA67745", "Xfinity Atlanta", "Atlanta", "30301"},
		"SC": {"GA67745", "Xfinity Atlanta", "Atlanta", "30301"},
		"TN": {"GA67745", "Xfinity Atlanta", "Atlanta", "30301"},
		"VA": {"GA67745", "Xfinity Atlanta", "Atlanta", "30301"},
		"WV": {"GA67745", "Xfinity Atlanta", "Atlanta", "30301"},

		// Miami area (FL67353 - AT&T U-verse Miami)
		"FL": {"FL67353", "AT&T U-verse", "Miami", "33101"},
		"PR": {"FL67353", "AT&T U-verse", "Miami", "33101"},
		"VI": {"FL67353", "AT&T U-verse", "Miami", "33101"},

		// Chicago area (IL54437 - Xfinity Chicago)
		"IL": {"IL54437", "Xfinity Chicago", "Chicago", "60601"},
		"IN": {"IL54437", "Xfinity Chicago", "Chicago", "60601"},
		"IA": {"IL54437", "Xfinity Chicago", "Chicago", "60601"},
		"MI": {"IL54437", "Xfinity Chicago", "Chicago", "60601"},
		"OH": {"IL54437", "Xfinity Chicago", "Chicago", "60601"},
		"WI": {"IL54437", "Xfinity Chicago", "Chicago", "60601"},

		// Minneapolis area (MN22623 - Xfinity Minneapolis)
		"MN": {"MN22623", "Xfinity Minneapolis", "Minneapolis", "55401"},
		"ND": {"MN22623", "Xfinity Minneapolis", "Minneapolis", "55401"},
		"SD": {"MN22623", "Xfinity Minneapolis", "Minneapolis", "55401"},
		"NE": {"MN22623", "Xfinity Minneapolis", "Minneapolis", "55401"},

		// Dallas area (TX42822 - Charter Spectrum North TX)
		"AR": {"TX42822", "Charter Spectrum", "Dallas", "75201"},
		"KS": {"TX42822", "Charter Spectrum", "Dallas", "75201"},
		"LA": {"TX42822", "Charter Spectrum", "Dallas", "75201"},
		"MO": {"TX42822", "Charter Spectrum", "Dallas", "75201"},
		"OK": {"TX42822", "Charter Spectrum", "Dallas", "75201"},
		"TX": {"TX42822", "Charter Spectrum", "Dallas", "75201"},

		// Denver area (CO05539 - Xfinity Denver)
		"CO": {"CO05539", "Xfinity Denver", "Denver", "80201"},
		"MT": {"CO05539", "Xfinity Denver", "Denver", "80201"},
		"NM": {"CO05539", "Xfinity Denver", "Denver", "80201"},
		"UT": {"CO05539", "Xfinity Denver", "Denver", "80201"},
		"WY": {"CO05539", "Xfinity Denver", "Denver", "80201"},

		// Seattle area (WA63873 - Xfinity King County)
		"AK": {"WA63873", "Xfinity Seattle", "Seattle", "98101"},
		"ID": {"WA63873", "Xfinity Seattle", "Seattle", "98101"},
		"OR": {"WA63873", "Xfinity Seattle", "Seattle", "98101"},
		"WA": {"WA63873", "Xfinity Seattle", "Seattle", "98101"},

		// Los Angeles area (CA04956 - Charter Spectrum)
		"AZ": {"CA04956", "Charter Spectrum", "Los Angeles", "90001"},
		"CA": {"CA04956", "Charter Spectrum", "Los Angeles", "90001"},
		"HI": {"CA04956", "Charter Spectrum", "Los Angeles", "90001"},
		"NV": {"CA04956", "Charter Spectrum", "Los Angeles", "90001"},
	}

	if headend, ok := stateDefaults[state]; ok {
		return headend, true
	}

	return stateHeadend{}, false
}

// autoDetectAffiliate attempts to detect affiliate ID from postal code (deprecated - use getFallbackProvider)
func autoDetectAffiliate(postalCode string) string {
	provider := getFallbackProvider(postalCode)
	if provider != nil {
		return provider.HeadendID
	}
	return ""
}

// getTotalPrograms counts total programs across all channels
func getTotalPrograms(gridResp *gracenote.GridResponse) int {
	total := 0
	for _, channel := range gridResp.Channels {
		total += len(channel.Events)
	}
	return total
}

// addEPGSource adds a new standalone EPG source
func (s *Server) addEPGSource(c *gin.Context) {
	var req struct {
		Name                 string `json:"name" binding:"required"`
		ProviderType         string `json:"providerType" binding:"required"` // xmltv or gracenote
		URL                  string `json:"url"`                             // For XMLTV
		GracenoteAffiliate   string `json:"gracenoteAffiliate"`              // For Gracenote
		GracenotePostalCode  string `json:"gracenotePostalCode"`             // For Gracenote
		GracenoteHours       int    `json:"gracenoteHours"`                  // For Gracenote
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate provider type
	if req.ProviderType != "xmltv" && req.ProviderType != "gracenote" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "providerType must be 'xmltv' or 'gracenote'"})
		return
	}

	// Validate required fields based on provider type
	if req.ProviderType == "xmltv" && req.URL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "URL is required for XMLTV provider"})
		return
	}
	if req.ProviderType == "gracenote" && req.GracenoteAffiliate == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "gracenoteAffiliate is required for Gracenote provider"})
		return
	}

	// Set default hours for Gracenote
	if req.ProviderType == "gracenote" && req.GracenoteHours == 0 {
		req.GracenoteHours = 6
	}

	source := models.EPGSource{
		Name:                 req.Name,
		ProviderType:         req.ProviderType,
		URL:                  req.URL,
		GracenoteAffiliate:   req.GracenoteAffiliate,
		GracenotePostalCode:  req.GracenotePostalCode,
		GracenoteHours:       req.GracenoteHours,
		Enabled:              true,
	}

	if err := s.db.Create(&source).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create EPG source"})
		return
	}

	// Fetch and parse EPG in background
	go func() {
		if err := s.refreshEPGSourceInternal(&source); err != nil {
			println("Failed to refresh EPG source:", err.Error())
		}
	}()

	c.JSON(http.StatusCreated, source)
}

// updateEPGSource updates an EPG source
func (s *Server) updateEPGSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EPG source ID"})
		return
	}

	var source models.EPGSource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "EPG source not found"})
		return
	}

	var req struct {
		Name                string `json:"name"`
		URL                 string `json:"url"`
		GracenoteAffiliate  string `json:"gracenoteAffiliate"`
		GracenotePostalCode string `json:"gracenotePostalCode"`
		GracenoteHours      *int   `json:"gracenoteHours"`
		Enabled             *bool  `json:"enabled"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Name != "" {
		source.Name = req.Name
	}
	if req.URL != "" {
		source.URL = req.URL
	}
	if req.GracenoteAffiliate != "" {
		source.GracenoteAffiliate = req.GracenoteAffiliate
	}
	if req.GracenotePostalCode != "" {
		source.GracenotePostalCode = req.GracenotePostalCode
	}
	if req.GracenoteHours != nil {
		source.GracenoteHours = *req.GracenoteHours
	}
	if req.Enabled != nil {
		source.Enabled = *req.Enabled
	}

	if err := s.db.Save(&source).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update EPG source"})
		return
	}

	c.JSON(http.StatusOK, source)
}

// deleteEPGSource deletes an EPG source
func (s *Server) deleteEPGSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EPG source ID"})
		return
	}

	if err := s.db.Delete(&models.EPGSource{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete EPG source"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "EPG source deleted"})
}

// refreshEPGSource refreshes programs from an EPG source
func (s *Server) refreshEPGSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EPG source ID"})
		return
	}

	var source models.EPGSource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "EPG source not found"})
		return
	}

	if err := s.refreshEPGSourceInternal(&source); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to refresh EPG: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      "EPG refreshed",
		"programCount": source.ProgramCount,
		"channelCount": source.ChannelCount,
	})
}

// refreshEPGSourceInternal handles refresh for both XMLTV and Gracenote providers
func (s *Server) refreshEPGSourceInternal(source *models.EPGSource) error {
	var err error
	if source.ProviderType == "gracenote" {
		err = s.refreshGracenoteEPG(source)
	} else {
		// Default to XMLTV
		epgParser := livetv.NewEPGParser(s.db)
		err = epgParser.RefreshEPGSource(source)
	}

	// Update error state
	if err != nil {
		source.LastError = err.Error()
		s.db.Save(source)
		return err
	}

	// Clear error on success
	source.LastError = ""
	s.db.Save(source)
	return nil
}

// getEPGStats returns statistics about EPG data
func (s *Server) getEPGStats(c *gin.Context) {
	epgParser := livetv.NewEPGParser(s.db)
	stats, err := epgParser.GetEPGStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get EPG stats"})
		return
	}

	// Add source counts
	var m3uSourceCount, epgSourceCount int64
	s.db.Model(&models.M3USource{}).Count(&m3uSourceCount)
	s.db.Model(&models.EPGSource{}).Count(&epgSourceCount)

	stats["m3uSources"] = m3uSourceCount
	stats["epgSources"] = epgSourceCount

	c.JSON(http.StatusOK, stats)
}

// refreshAllEPG refreshes EPG from all sources
func (s *Server) refreshAllEPG(c *gin.Context) {
	epgParser := livetv.NewEPGParser(s.db)
	errors := []string{}
	refreshed := 0

	// Refresh from M3U sources with EPG URLs
	var m3uSources []models.M3USource
	s.db.Where("epg_url != '' AND enabled = ?", true).Find(&m3uSources)
	for _, source := range m3uSources {
		if err := epgParser.RefreshEPG(&source); err != nil {
			errors = append(errors, "M3U source "+source.Name+": "+err.Error())
		} else {
			refreshed++
		}
	}

	// Refresh from standalone EPG sources
	var epgSources []models.EPGSource
	s.db.Where("enabled = ?", true).Find(&epgSources)
	for _, source := range epgSources {
		if err := s.refreshEPGSourceInternal(&source); err != nil {
			errors = append(errors, "EPG source "+source.Name+": "+err.Error())
		} else {
			refreshed++
		}
	}

	response := gin.H{
		"message":   "EPG refresh complete",
		"refreshed": refreshed,
	}
	if len(errors) > 0 {
		response["errors"] = errors
	}

	c.JSON(http.StatusOK, response)
}

// parseGracenoteTime parses Gracenote time string (Unix timestamp as string or ISO format)
func parseGracenoteTime(timeStr string) (time.Time, error) {
	if timeStr == "" {
		return time.Time{}, fmt.Errorf("empty time string")
	}

	// Try parsing as ISO 8601 / RFC3339 (Gracenote format)
	if t, err := time.Parse(time.RFC3339, timeStr); err == nil {
		return t, nil
	}

	// Try parsing as Unix timestamp
	var unixTime int64
	if _, err := fmt.Sscanf(timeStr, "%d", &unixTime); err == nil && unixTime > 1000000000 {
		// Sanity check: timestamp should be after year 2001 (> 1 billion seconds)
		return time.Unix(unixTime, 0), nil
	}

	// Try other common formats
	formats := []string{
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05",
		time.RFC1123,
	}
	for _, format := range formats {
		if t, err := time.Parse(format, timeStr); err == nil {
			return t, nil
		}
	}

	return time.Time{}, fmt.Errorf("unable to parse time: %s", timeStr)
}

// refreshGracenoteEPG fetches EPG data from Gracenote and saves to database
func (s *Server) refreshGracenoteEPG(source *models.EPGSource) error {
	// Create Gracenote client
	gnClient := gracenote.NewBrowserClient(gracenote.Config{
		BaseURL:   "https://tvlistings.gracenote.com",
		UserAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
		Timeout:   30 * time.Second,
	})

	// Fetch listings
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	gridResp, err := gnClient.GetListingsForAffiliate(ctx, source.GracenoteAffiliate, source.GracenotePostalCode, source.GracenoteHours)
	if err != nil {
		return fmt.Errorf("failed to fetch Gracenote data: %w", err)
	}

	// Convert Gracenote data to Program models
	var programs []models.Program
	channelSet := make(map[string]bool)
	parseErrors := 0

	fmt.Printf("📺 Processing %d channels from Gracenote\n", len(gridResp.Channels))

	for i, channel := range gridResp.Channels {
		channelID := fmt.Sprintf("gracenote-%s-%s", source.GracenoteAffiliate, channel.ChannelID)
		channelSet[channelID] = true

		// Debug: log first event's time format
		if i == 0 && len(channel.Events) > 0 {
			fmt.Printf("📅 Sample time format - StartTime: %q, EndTime: %q\n",
				channel.Events[0].StartTime, channel.Events[0].EndTime)
		}

		for _, event := range channel.Events {
			// Parse start and end times
			startTime, err := parseGracenoteTime(event.StartTime)
			if err != nil {
				parseErrors++
				if parseErrors <= 3 {
					fmt.Printf("⚠️  Time parse error for %s: %v (input: %s)\n", event.Program.Title, err, event.StartTime)
				}
				continue // Skip programs with invalid times
			}
			endTime, err := parseGracenoteTime(event.EndTime)
			if err != nil {
				parseErrors++
				if parseErrors <= 3 {
					fmt.Printf("⚠️  End time parse error for %s: %v (input: %s)\n", event.Program.Title, err, event.EndTime)
				}
				continue
			}

			// Debug first parsed time
			if i == 0 && len(programs) == 0 {
				fmt.Printf("🕐 DEBUG: First program time - Start: %v, End: %v\n", startTime, endTime)
			}

			program := models.Program{
				ChannelID:     channelID,
				CallSign:      channel.CallSign,
				ChannelNo:     channel.ChannelNo,
				AffiliateName: channel.AffiliateName,
				Title:         event.Program.Title,
				Description:   event.Program.ShortDesc,
				Start:         startTime,
				End:           endTime,
				Icon:          event.Thumbnail,
			}

			// Add episode info if available
			if event.Program.EpisodeTitle != "" {
				program.EpisodeNum = event.Program.EpisodeTitle
			}

			programs = append(programs, program)
		}
	}

	if parseErrors > 0 {
		fmt.Printf("⚠️  Skipped %d programs due to time parsing errors\n", parseErrors)
	}
	fmt.Printf("✅ Successfully parsed %d programs from %d channels\n", len(programs), len(channelSet))

	// Delete old programs for these channels
	channelIDs := make([]string, 0, len(channelSet))
	for channelID := range channelSet {
		channelIDs = append(channelIDs, channelID)
	}
	s.db.Where("channel_id IN ?", channelIDs).Delete(&models.Program{})

	// Bulk insert new programs
	if len(programs) > 0 {
		// Insert in batches to avoid overwhelming the database
		batchSize := 500
		for i := 0; i < len(programs); i += batchSize {
			end := i + batchSize
			if end > len(programs) {
				end = len(programs)
			}
			if err := s.db.Create(programs[i:end]).Error; err != nil {
				return fmt.Errorf("failed to save programs: %w", err)
			}
		}
	}

	// Update source stats
	now := time.Now()
	source.LastFetched = &now
	source.ProgramCount = len(programs)
	source.ChannelCount = len(channelSet)
	if err := s.db.Save(source).Error; err != nil {
		return fmt.Errorf("failed to update source stats: %w", err)
	}

	return nil
}

// getEPGPrograms fetches EPG programs with pagination and optional filtering
func (s *Server) getEPGPrograms(c *gin.Context) {
	// Parse query parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "100"))
	epgSourceID := c.Query("epgSourceId")
	channelID := c.Query("channelId")

	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 500 {
		limit = 100
	}
	offset := (page - 1) * limit

	// Build query
	query := s.db.Model(&models.Program{})

	// Filter by EPG source if provided (via channel relationship)
	if epgSourceID != "" {
		sourceID, err := strconv.Atoi(epgSourceID)
		if err == nil {
			// Get channels for this EPG source
			var channels []models.Channel
			s.db.Where("epg_source_id = ?", sourceID).Find(&channels)
			if len(channels) > 0 {
				channelIDs := make([]string, len(channels))
				for i, ch := range channels {
					channelIDs[i] = ch.ChannelID
				}
				query = query.Where("channel_id IN ?", channelIDs)
			}
		}
	}

	// Filter by specific channel if provided
	if channelID != "" {
		query = query.Where("channel_id = ?", channelID)
	}

	// Get total count
	var total int64
	query.Count(&total)

	// Fetch programs with pagination
	var programs []models.Program
	query.Order("start DESC").Limit(limit).Offset(offset).Find(&programs)

	// Fetch channel names for these programs
	channelIDs := make([]string, 0)
	for _, p := range programs {
		channelIDs = append(channelIDs, p.ChannelID)
	}

	var channels []models.Channel
	s.db.Where("channel_id IN ?", channelIDs).Find(&channels)

	// Create a map of channel names
	channelNames := make(map[string]string)
	for _, ch := range channels {
		channelNames[ch.ChannelID] = ch.Name
	}

	// Enrich programs with channel names
	type ProgramResponse struct {
		models.Program
		ChannelName string `json:"channelName"`
	}

	response := make([]ProgramResponse, len(programs))
	for i, p := range programs {
		response[i] = ProgramResponse{
			Program:     p,
			ChannelName: channelNames[p.ChannelID],
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"programs": response,
		"total":    total,
		"page":     page,
		"limit":    limit,
		"pages":    (total + int64(limit) - 1) / int64(limit),
	})
}

// getEPGChannels returns a list of unique channels from EPG data for mapping
func (s *Server) getEPGChannels(c *gin.Context) {
	epgSourceID := c.Query("epgSourceId")

	// Build query to get distinct channel IDs
	query := s.db.Model(&models.Program{}).Select("DISTINCT channel_id")

	// Filter by EPG source if provided
	if epgSourceID != "" {
		sourceID, err := strconv.Atoi(epgSourceID)
		if err == nil {
			// Get channels for this EPG source
			var channels []models.Channel
			s.db.Where("epg_source_id = ?", sourceID).Find(&channels)
			if len(channels) > 0 {
				channelIDs := make([]string, len(channels))
				for i, ch := range channels {
					channelIDs[i] = ch.ChannelID
				}
				query = query.Where("channel_id IN ?", channelIDs)
			}
		}
	}

	// Get distinct channel IDs
	var channelIDs []string
	query.Pluck("channel_id", &channelIDs)

	// For each channel ID, get a sample program to show what's on that channel
	type EPGChannel struct {
		ChannelID   string `json:"channelId"`
		SampleTitle string `json:"sampleTitle"`
	}

	channels := make([]EPGChannel, 0, len(channelIDs))
	for _, channelID := range channelIDs {
		var program models.Program
		s.db.Where("channel_id = ?", channelID).Order("start DESC").First(&program)

		channels = append(channels, EPGChannel{
			ChannelID:   channelID,
			SampleTitle: program.Title,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"channels": channels,
	})
}
