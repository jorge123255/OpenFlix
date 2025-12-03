package api

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
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
	s.db.Where("m3u_source_id = ?", id).Delete(&models.Channel{})

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
		Name    string `json:"name"`
		Number  *int   `json:"number"`
		Logo    string `json:"logo"`
		Group   string `json:"group"`
		Enabled *bool  `json:"enabled"`
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

	type NowPlaying struct {
		Channel     models.Channel  `json:"channel"`
		NowPlaying  *models.Program `json:"nowPlaying,omitempty"`
		NextProgram *models.Program `json:"nextProgram,omitempty"`
	}

	epgParser := livetv.NewEPGParser(s.db)
	results := make([]NowPlaying, 0, len(channels))

	for _, ch := range channels {
		item := NowPlaying{Channel: ch}
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

// addEPGSource adds a new standalone EPG source
func (s *Server) addEPGSource(c *gin.Context) {
	var req struct {
		Name string `json:"name" binding:"required"`
		URL  string `json:"url" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	source := models.EPGSource{
		Name:    req.Name,
		URL:     req.URL,
		Enabled: true,
	}

	if err := s.db.Create(&source).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create EPG source"})
		return
	}

	// Fetch and parse EPG in background
	go func() {
		epgParser := livetv.NewEPGParser(s.db)
		if err := epgParser.RefreshEPGSource(&source); err != nil {
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
		Name    string `json:"name"`
		URL     string `json:"url"`
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

	epgParser := livetv.NewEPGParser(s.db)
	if err := epgParser.RefreshEPGSource(&source); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to refresh EPG: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      "EPG refreshed",
		"programCount": source.ProgramCount,
		"channelCount": source.ChannelCount,
	})
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
		if err := epgParser.RefreshEPGSource(&source); err != nil {
			errors = append(errors, "EPG source "+source.Name+": "+err.Error())
		} else {
			refreshed++
		}
	}

	response := gin.H{
		"message":  "EPG refresh complete",
		"refreshed": refreshed,
	}
	if len(errors) > 0 {
		response["errors"] = errors
	}

	c.JSON(http.StatusOK, response)
}
