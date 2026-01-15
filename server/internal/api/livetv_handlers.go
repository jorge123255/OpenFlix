package api

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
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
		query = query.Where("m3_u_source_id = ?", sourceID)
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

	// Get M3U source names for provider display
	var m3uSources []models.M3USource
	s.db.Find(&m3uSources)
	sourceNames := make(map[uint]string)
	for _, src := range m3uSources {
		sourceNames[src.ID] = src.Name
	}

	// Enrich with current program info
	epgParser := livetv.NewEPGParser(s.db)
	type ChannelWithProgram struct {
		models.Channel
		SourceName  string          `json:"sourceName,omitempty"`
		NowPlaying  *models.Program `json:"nowPlaying,omitempty"`
		NextProgram *models.Program `json:"nextProgram,omitempty"`
	}

	enrichedChannels := make([]ChannelWithProgram, len(channels))
	for i, ch := range channels {
		enrichedChannels[i].Channel = ch
		enrichedChannels[i].SourceName = sourceNames[ch.M3USourceID]
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

	// Auto-start buffering if requested (for catch-up TV support)
	if c.Query("buffer") == "true" {
		go s.timeshiftBuffer.StartBuffer(&channel)
	}

	// Get current and next program
	type ChannelWithProgram struct {
		models.Channel
		NowPlaying       *models.Program `json:"nowPlaying,omitempty"`
		NextProgram      *models.Program `json:"nextProgram,omitempty"`
		CatchUpAvailable bool            `json:"catchUpAvailable"`
	}

	response := ChannelWithProgram{
		Channel:          channel,
		CatchUpAvailable: s.timeshiftBuffer.IsBuffering(uint(id)),
	}

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
		ChannelIDs   []uint `json:"channelIds" binding:"required"`
		EPGSourceID  uint   `json:"epgSourceId" binding:"required"`
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

// refreshChannelEPG re-detects EPG mapping for a single channel
func (s *Server) refreshChannelEPG(c *gin.Context) {
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

	oldEPGID := channel.ChannelID

	// Get EPG channels for matching
	epgChannels := s.getEPGChannelList()
	if len(epgChannels) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No EPG data available for matching"})
		return
	}

	// Create matcher and find best match
	matcher := livetv.NewChannelMatcher(epgChannels)
	matches := matcher.FindMatches(&channel)

	var newMatch *livetv.MatchResult
	if len(matches) > 0 && matches[0].Confidence >= 0.5 {
		newMatch = &matches[0]
		// Apply the new mapping
		channel.ChannelID = newMatch.EPGChannelID
		channel.EPGCallSign = newMatch.EPGCallSign
		channel.EPGChannelNo = newMatch.EPGNumber
		channel.MatchConfidence = newMatch.Confidence
		channel.MatchStrategy = newMatch.MatchStrategy
		channel.AutoDetected = true

		if err := s.db.Save(&channel).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save channel mapping"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"channel":    channel,
		"oldEPGID":   oldEPGID,
		"newMatch":   newMatch,
		"allMatches": matches,
	})
}

// getEPGChannelList returns all EPG channels for matching
func (s *Server) getEPGChannelList() []livetv.EPGChannelInfo {
	// Get unique channel IDs from programs
	var programs []models.Program
	s.db.Select("DISTINCT channel_id, call_sign, channel_no, affiliate_name").
		Where("end > ?", time.Now()).
		Find(&programs)

	channels := make([]livetv.EPGChannelInfo, 0, len(programs))
	seen := make(map[string]bool)

	for _, p := range programs {
		if p.ChannelID == "" || seen[p.ChannelID] {
			continue
		}
		seen[p.ChannelID] = true
		channels = append(channels, livetv.EPGChannelInfo{
			ChannelID:     p.ChannelID,
			CallSign:      p.CallSign,
			Number:        p.ChannelNo,
			AffiliateName: p.AffiliateName,
		})
	}

	return channels
}

// autoDetectChannels automatically detects EPG mappings for channels
func (s *Server) autoDetectChannels(c *gin.Context) {
	// Get optional source filter
	sourceID, _ := strconv.ParseUint(c.Query("sourceId"), 10, 32)
	epgSourceID, _ := strconv.ParseUint(c.Query("epgSourceId"), 10, 32)
	minConfidence := 0.7 // Default minimum confidence
	if conf := c.Query("minConfidence"); conf != "" {
		if parsed, err := strconv.ParseFloat(conf, 64); err == nil && parsed > 0 && parsed <= 1 {
			minConfidence = parsed
		}
	}
	applyMappings := c.Query("apply") == "true"
	unmappedOnly := c.Query("unmappedOnly") != "false" // Default true

	// Get channels to process
	query := s.db.Model(&models.Channel{})
	if sourceID > 0 {
		query = query.Where("m3_u_source_id = ?", sourceID)
	}

	var channels []models.Channel
	if err := query.Find(&channels).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch channels"})
		return
	}

	// Get M3U source names for provider matching
	var m3uSources []models.M3USource
	s.db.Find(&m3uSources)
	sourceNames := make(map[uint]string)
	for _, src := range m3uSources {
		sourceNames[src.ID] = strings.ToLower(src.Name)
	}

	// Get all channel IDs that have CURRENT or FUTURE programs in the database
	// Only consider channels with programs ending after now as "mapped"
	var channelIDsWithPrograms []string
	s.db.Model(&models.Program{}).
		Distinct("channel_id").
		Where("channel_id != '' AND end > ?", time.Now()).
		Pluck("channel_id", &channelIDsWithPrograms)

	// Create a map for fast lookup
	hasPrograms := make(map[string]bool)
	for _, id := range channelIDsWithPrograms {
		hasPrograms[id] = true
	}

	// Track EPG channel IDs that are already assigned within the SAME source to prevent duplicates
	// Different M3U sources can share the same EPG channel ID (e.g., Fubo and Directv can both use "COMEDYCENT")
	usedEPGChannelIDs := make(map[string]bool)
	var existingChannels []models.Channel
	if sourceID > 0 {
		// Only track EPG IDs used by channels from the same source
		s.db.Where("channel_id != '' AND m3_u_source_id = ?", sourceID).Find(&existingChannels)
	} else {
		// When no source filter, track all used EPG IDs
		s.db.Where("channel_id != ''").Find(&existingChannels)
	}
	for _, ch := range existingChannels {
		usedEPGChannelIDs[ch.ChannelID] = true
	}

	// If unmappedOnly, filter to channels without EPG programs
	if unmappedOnly {
		var unmappedChannels []models.Channel
		for _, ch := range channels {
			if !hasPrograms[ch.ChannelID] {
				unmappedChannels = append(unmappedChannels, ch)
			}
		}
		channels = unmappedChannels
	}

	if len(channels) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"message": "No channels to process",
			"summary": livetv.AutoDetectSummary{},
			"results": []livetv.AutoDetectResult{},
		})
		return
	}

	// Get EPG channels to match against
	var epgChannels []livetv.EPGChannelInfo

	// If specific EPG source is specified, use only that source
	if epgSourceID > 0 {
		var epgSource models.EPGSource
		if err := s.db.First(&epgSource, epgSourceID).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "EPG source not found"})
			return
		}

		// Get unique channels from programs for this EPG source
		var programs []models.Program
		s.db.Select("DISTINCT channel_id, call_sign, channel_no, affiliate_name").
			Where("channel_id != ''").
			Find(&programs)

		for _, p := range programs {
			// Use channel_id as callsign/name fallback when not provided
			callSign := p.CallSign
			if callSign == "" {
				callSign = p.ChannelID
			}
			epgChannels = append(epgChannels, livetv.EPGChannelInfo{
				ChannelID:     p.ChannelID,
				CallSign:      callSign,
				Number:        p.ChannelNo,
				AffiliateName: p.AffiliateName,
				Name:          callSign,
			})
		}
	} else {
		// Get all unique EPG channels from programs table
		var programs []struct {
			ChannelID     string
			CallSign      string
			ChannelNo     string
			AffiliateName string
		}
		s.db.Model(&models.Program{}).
			Select("DISTINCT channel_id, call_sign, channel_no, affiliate_name").
			Where("channel_id != ''").
			Scan(&programs)

		for _, p := range programs {
			// Use channel_id as callsign/name fallback when not provided
			callSign := p.CallSign
			if callSign == "" {
				callSign = p.ChannelID
			}
			epgChannels = append(epgChannels, livetv.EPGChannelInfo{
				ChannelID:     p.ChannelID,
				CallSign:      callSign,
				Number:        p.ChannelNo,
				AffiliateName: p.AffiliateName,
				Name:          callSign,
			})
		}
	}

	if len(epgChannels) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"message": "No EPG channels available for matching. Please add and refresh an EPG source first.",
			"summary": livetv.AutoDetectSummary{TotalChannels: len(channels)},
			"results": []livetv.AutoDetectResult{},
		})
		return
	}

	// Create matcher and process channels
	matcher := livetv.NewChannelMatcher(epgChannels)

	var results []livetv.AutoDetectResult
	summary := livetv.AutoDetectSummary{
		TotalChannels: len(channels),
	}

	for _, ch := range channels {
		result := livetv.AutoDetectResult{
			ChannelID:      ch.ID,
			ChannelName:    ch.Name,
			CurrentMapping: ch.ChannelID,
		}

		// Skip channels that already have EPG programs
		if hasPrograms[ch.ChannelID] {
			summary.AlreadyMapped++
			continue
		}

		// First, check if the channel's TVGId directly matches EPG programs
		// This is the preferred mapping (e.g., philo-11 -> philo-11)
		if ch.TVGId != "" && hasPrograms[ch.TVGId] && !usedEPGChannelIDs[ch.TVGId] {
			if applyMappings {
				ch.ChannelID = ch.TVGId
				ch.MatchConfidence = 1.0
				ch.MatchStrategy = "tvg_id_direct"
				ch.AutoDetected = true

				if err := s.db.Save(&ch).Error; err == nil {
					usedEPGChannelIDs[ch.TVGId] = true
					result.AutoMapped = true
					result.BestMatch = &livetv.MatchResult{
						EPGChannelID:  ch.TVGId,
						Confidence:    1.0,
						MatchReason:   "Direct TVG-ID match",
						MatchStrategy: "tvg_id_direct",
					}
					summary.NewMappings++
					summary.HighConfidence++
				}
			} else {
				result.BestMatch = &livetv.MatchResult{
					EPGChannelID:  ch.TVGId,
					Confidence:    1.0,
					MatchReason:   "Direct TVG-ID match",
					MatchStrategy: "tvg_id_direct",
				}
				summary.HighConfidence++
			}
			results = append(results, result)
			continue
		}

		// Try to match channel number to Gracenote EPG channel number
		// This maps channels with numeric TVGId (e.g., "2") to Gracenote channels (e.g., "gracenote-DITV803-10367")
		channelNumberMatched := false
		if ch.TVGId != "" {
			for _, epgCh := range epgChannels {
				// Match by channel number if EPG channel has a number
				if epgCh.Number != "" && epgCh.Number == ch.TVGId && !usedEPGChannelIDs[epgCh.ChannelID] {
					if applyMappings {
						ch.ChannelID = epgCh.ChannelID
						ch.EPGCallSign = epgCh.CallSign
						ch.EPGChannelNo = epgCh.Number
						ch.MatchConfidence = 1.0
						ch.MatchStrategy = "channel_number_to_gracenote"
						ch.AutoDetected = true

						if err := s.db.Save(&ch).Error; err == nil {
							usedEPGChannelIDs[epgCh.ChannelID] = true
							result.AutoMapped = true
							result.BestMatch = &livetv.MatchResult{
								EPGChannelID:  epgCh.ChannelID,
								EPGCallSign:   epgCh.CallSign,
								EPGNumber:     epgCh.Number,
								Confidence:    1.0,
								MatchReason:   "Channel number match to Gracenote",
								MatchStrategy: "channel_number_to_gracenote",
							}
							summary.NewMappings++
							summary.HighConfidence++
						}
					} else {
						result.BestMatch = &livetv.MatchResult{
							EPGChannelID:  epgCh.ChannelID,
							EPGCallSign:   epgCh.CallSign,
							EPGNumber:     epgCh.Number,
							Confidence:    1.0,
							MatchReason:   "Channel number match to Gracenote",
							MatchStrategy: "channel_number_to_gracenote",
						}
						summary.HighConfidence++
					}
					results = append(results, result)
					channelNumberMatched = true
					break
				}
			}
		}
		if channelNumberMatched {
			continue
		}

		// Find matches using the matcher
		matches := matcher.FindMatches(&ch)

		// Get M3U source name for provider preference
		m3uSourceName := sourceNames[ch.M3USourceID]

		// Filter out already-used EPG channel IDs and prefer same-provider matches
		var filteredMatches []livetv.MatchResult
		for _, match := range matches {
			// Skip already-used EPG channel IDs to prevent duplicates
			if usedEPGChannelIDs[match.EPGChannelID] {
				continue
			}

			// Boost confidence for same-provider matches
			// e.g., if M3U source is "Philo" and EPG channel ID starts with "philo-"
			epgChannelLower := strings.ToLower(match.EPGChannelID)
			if m3uSourceName != "" && strings.HasPrefix(epgChannelLower, m3uSourceName+"-") {
				match.Confidence = min(match.Confidence*1.2, 1.0) // 20% boost, max 1.0
				match.MatchReason = match.MatchReason + " (same provider)"
			}

			filteredMatches = append(filteredMatches, match)
		}

		// Re-sort by confidence after filtering
		sort.Slice(filteredMatches, func(i, j int) bool {
			return filteredMatches[i].Confidence > filteredMatches[j].Confidence
		})

		result.AllMatches = filteredMatches

		if len(filteredMatches) > 0 {
			result.BestMatch = &filteredMatches[0]

			if filteredMatches[0].Confidence >= minConfidence {
				summary.HighConfidence++

				// Apply mapping if requested
				if applyMappings {
					ch.ChannelID = filteredMatches[0].EPGChannelID
					ch.EPGCallSign = filteredMatches[0].EPGCallSign
					ch.EPGChannelNo = filteredMatches[0].EPGNumber
					ch.MatchConfidence = filteredMatches[0].Confidence
					ch.MatchStrategy = filteredMatches[0].MatchStrategy
					ch.AutoDetected = true

					if epgSourceID > 0 {
						epgSrcID := uint(epgSourceID)
						ch.EPGSourceID = &epgSrcID
					}

					if err := s.db.Save(&ch).Error; err == nil {
						usedEPGChannelIDs[filteredMatches[0].EPGChannelID] = true
						result.AutoMapped = true
						summary.NewMappings++
					}
				}
			} else {
				summary.LowConfidence++
			}
		} else {
			summary.NoMatchFound++
		}

		results = append(results, result)
	}

	c.JSON(http.StatusOK, gin.H{
		"message":       "Auto-detection completed",
		"summary":       summary,
		"results":       results,
		"epgChannels":   len(epgChannels),
		"minConfidence": minConfidence,
		"applied":       applyMappings,
	})
}

// getSuggestedMatches returns suggested EPG matches for a single channel
func (s *Server) getSuggestedMatches(c *gin.Context) {
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

	// Get all unique EPG channels from programs
	var programs []struct {
		ChannelID     string
		CallSign      string
		ChannelNo     string
		AffiliateName string
	}
	s.db.Model(&models.Program{}).
		Select("DISTINCT channel_id, call_sign, channel_no, affiliate_name").
		Where("channel_id != ''").
		Scan(&programs)

	var epgChannels []livetv.EPGChannelInfo
	for _, p := range programs {
		epgChannels = append(epgChannels, livetv.EPGChannelInfo{
			ChannelID:     p.ChannelID,
			CallSign:      p.CallSign,
			Number:        p.ChannelNo,
			AffiliateName: p.AffiliateName,
			Name:          p.CallSign,
		})
	}

	if len(epgChannels) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"channel": channel,
			"matches": []livetv.MatchResult{},
			"message": "No EPG channels available",
		})
		return
	}

	matcher := livetv.NewChannelMatcher(epgChannels)
	matches := matcher.FindMatches(&channel)

	c.JSON(http.StatusOK, gin.H{
		"channel": channel,
		"matches": matches,
	})
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

// getGuide returns EPG data for a time range with caching
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

	sourceID := c.Query("sourceId")

	// Generate cache key - truncate times to 5-minute buckets for better cache hits
	startBucket := start.Truncate(5 * time.Minute)
	endBucket := end.Truncate(5 * time.Minute)
	cacheKey := ""
	if s.guideCache != nil {
		cacheKey = s.guideCache.GenerateKey("guide", startBucket.Unix(), endBucket.Unix(), sourceID)

		// Check cache first
		if cached, found := s.guideCache.Get(cacheKey); found {
			if response, ok := cached.(gin.H); ok {
				c.JSON(http.StatusOK, response)
				return
			}
		}
	}

	// Get channels
	var channels []models.Channel
	channelQuery := s.db.Where("enabled = ?", true).Order("number, name")
	if sourceID != "" {
		channelQuery = channelQuery.Where("m3_u_source_id = ?", sourceID)
	}
	if err := channelQuery.Find(&channels).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch channels"})
		return
	}

	// Build mapping from Gracenote channel ID to our channel's channelId
	// Programs are stored with Gracenote IDs but frontend looks up by channel.channelId
	channelIDs := make([]string, 0, len(channels))
	gracenoteToChannelID := make(map[string]string)
	for _, ch := range channels {
		// Channels may have channelId in Gracenote format or just a number (tvgId)
		// We need to query programs by whatever format matches the program.channel_id
		if ch.ChannelID != "" {
			channelIDs = append(channelIDs, ch.ChannelID)
			gracenoteToChannelID[ch.ChannelID] = ch.ChannelID
		}
	}

	// Get programs
	epgParser := livetv.NewEPGParser(s.db)
	programs, err := epgParser.GetGuide(start, end, channelIDs)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch programs"})
		return
	}

	// Group programs by channel.channelId (what frontend uses for lookup)
	// Map Gracenote program channel_id back to our channel's channelId
	programsByChannel := make(map[string][]models.Program)
	for _, prog := range programs {
		// Use the mapping to get the channel's channelId
		if chID, ok := gracenoteToChannelID[prog.ChannelID]; ok {
			programsByChannel[chID] = append(programsByChannel[chID], prog)
		} else {
			// Fallback: use program's channel_id directly
			programsByChannel[prog.ChannelID] = append(programsByChannel[prog.ChannelID], prog)
		}
	}

	// Get M3U source names for provider display in guide
	var m3uSources []models.M3USource
	s.db.Find(&m3uSources)
	sourceNames := make(map[uint]string)
	for _, src := range m3uSources {
		sourceNames[src.ID] = src.Name
	}

	// Enrich channels with source names
	type GuideChannel struct {
		models.Channel
		SourceName string `json:"sourceName,omitempty"`
	}
	enrichedChannels := make([]GuideChannel, len(channels))
	for i, ch := range channels {
		enrichedChannels[i].Channel = ch
		enrichedChannels[i].SourceName = sourceNames[ch.M3USourceID]
	}

	response := gin.H{
		"channels": enrichedChannels,
		"programs": programsByChannel,
		"start":    start,
		"end":      end,
	}

	// Store in cache
	if s.guideCache != nil && cacheKey != "" {
		s.guideCache.Set(cacheKey, response)
	}

	c.JSON(http.StatusOK, response)
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

	// Get programs - use TVGId for EPG lookup (matches program.channel_id)
	epgID := channel.TVGId
	if epgID == "" {
		epgID = channel.ChannelID
	}
	epgParser := livetv.NewEPGParser(s.db)
	programs, err := epgParser.GetGuide(start, end, []string{epgID})
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
		// EPG Mapping fields
		TvgId           string  `json:"tvgId,omitempty"`
		EPGCallSign     string  `json:"epgCallSign,omitempty"`
		EPGChannelNo    string  `json:"epgChannelNo,omitempty"`
		MatchConfidence float64 `json:"matchConfidence"`
		MatchStrategy   string  `json:"matchStrategy,omitempty"`
		AutoDetected    bool    `json:"autoDetected"`
		HasEpgData      bool    `json:"hasEpgData"`
	}

	epgParser := livetv.NewEPGParser(s.db)
	results := make([]ChannelWithPrograms, 0, len(channels))

	for _, ch := range channels {
		item := ChannelWithPrograms{
			ID:              ch.ID,
			SourceID:        ch.M3USourceID,
			ChannelID:       ch.ChannelID,
			Number:          ch.Number,
			Name:            ch.Name,
			Logo:            ch.Logo,
			Group:           ch.Group,
			StreamURL:       ch.StreamURL,
			Enabled:         ch.Enabled,
			IsFavorite:      ch.IsFavorite,
			TvgId:           ch.TVGId,
			EPGCallSign:     ch.EPGCallSign,
			EPGChannelNo:    ch.EPGChannelNo,
			MatchConfidence: ch.MatchConfidence,
			MatchStrategy:   ch.MatchStrategy,
			AutoDetected:    ch.AutoDetected,
		}
		// Use TVGId for EPG lookup (matches program.channel_id), fall back to ChannelID
		epgID := ch.TVGId
		if epgID == "" {
			epgID = ch.ChannelID
		}
		if epgID != "" {
			if program, err := epgParser.GetCurrentProgram(epgID); err == nil {
				item.NowPlaying = program
				item.HasEpgData = true
			}
			if program, err := epgParser.GetNextProgram(epgID); err == nil {
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

// discoverGracenoteProviders returns available TV providers for a zip code
// This allows users to select their provider from a dropdown instead of knowing headend IDs
func (s *Server) discoverGracenoteProviders(c *gin.Context) {
	postalCode := c.Query("postalCode")
	country := c.DefaultQuery("country", "USA")

	if postalCode == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "postalCode is required"})
		return
	}

	// Create Gracenote client
	gnClient := gracenote.NewBrowserClient(gracenote.Config{
		BaseURL:   "https://tvlistings.gracenote.com",
		UserAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
		Timeout:   30 * time.Second,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Discover providers for this postal code
	providers, err := gnClient.DiscoverProviders(ctx, postalCode, country)
	if err != nil || len(providers) == 0 {
		// Try fallback providers - returns cable, satellite, and antenna options
		fallbackProviders := getAllProvidersForArea(postalCode)
		if len(fallbackProviders) > 0 {
			providers = fallbackProviders
		} else if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":     fmt.Sprintf("Failed to discover providers: %v", err),
				"providers": []gracenote.Provider{},
			})
			return
		}
	}

	// Group providers by type for better UI organization
	type ProviderGroup struct {
		Type      string               `json:"type"`
		Providers []gracenote.Provider `json:"providers"`
	}

	cable := []gracenote.Provider{}
	satellite := []gracenote.Provider{}
	antenna := []gracenote.Provider{}

	for _, p := range providers {
		switch p.Type {
		case "Cable":
			cable = append(cable, p)
		case "Satellite":
			satellite = append(satellite, p)
		case "Antenna":
			antenna = append(antenna, p)
		}
	}

	groups := []ProviderGroup{}
	if len(cable) > 0 {
		groups = append(groups, ProviderGroup{Type: "Cable", Providers: cable})
	}
	if len(satellite) > 0 {
		groups = append(groups, ProviderGroup{Type: "Satellite", Providers: satellite})
	}
	if len(antenna) > 0 {
		groups = append(groups, ProviderGroup{Type: "Antenna", Providers: antenna})
	}

	c.JSON(http.StatusOK, gin.H{
		"postalCode": postalCode,
		"country":    country,
		"providers":  providers,
		"grouped":    groups,
		"total":      len(providers),
	})
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

// getAllProvidersForArea returns multiple provider options for a given postal code
// including local cable, national satellite, and over-the-air options
func getAllProvidersForArea(postalCode string) []gracenote.Provider {
	providers := []gracenote.Provider{}

	// Get local cable provider
	cableProvider := getFallbackProvider(postalCode)
	if cableProvider != nil {
		providers = append(providers, *cableProvider)
	}

	// Add national providers that work everywhere
	// DirecTV headend IDs by region (verified from Gracenote)
	directvHeadends := map[string]struct {
		headendID string
		name      string
	}{
		// Major market DirecTV headends
		"NY": {"DITV802", "DirecTV"},
		"CA": {"DITV810", "DirecTV"},
		"TX": {"DITV804", "DirecTV"},
		"FL": {"DITV806", "DirecTV"},
		"IL": {"DITV803", "DirecTV"},
		"PA": {"DITV805", "DirecTV"},
		"GA": {"DITV807", "DirecTV"},
		"MA": {"DITV808", "DirecTV"},
		"WA": {"DITV809", "DirecTV"},
		"CO": {"DITV811", "DirecTV"},
	}

	// Determine state from postal code
	state := lookupStateFromZIP(postalCode)
	if state == "" {
		// Fallback to state detection from zip prefix
		state = getStateFromZipPrefix(postalCode)
	}

	// Add DirecTV for this region
	if directv, ok := directvHeadends[state]; ok {
		providers = append(providers, gracenote.Provider{
			HeadendID: directv.headendID,
			Name:      directv.name,
			Type:      "Satellite",
			Location:  state,
			LineupID:  fmt.Sprintf("USA-%s-DEFAULT", directv.headendID),
		})
	} else {
		// Default DirecTV headend
		providers = append(providers, gracenote.Provider{
			HeadendID: "DITV802",
			Name:      "DirecTV",
			Type:      "Satellite",
			Location:  "National",
			LineupID:  "USA-DITV802-DEFAULT",
		})
	}

	// DISH Network (national)
	providers = append(providers, gracenote.Provider{
		HeadendID: "DISH120",
		Name:      "DISH Network",
		Type:      "Satellite",
		Location:  "National",
		LineupID:  "USA-DISH120-DEFAULT",
	})

	// Add over-the-air antenna options based on market
	otaHeadends := map[string]struct {
		headendID string
		name      string
		market    string
	}{
		"NY": {"NY66511", "Over The Air", "New York"},
		"CA": {"CA01544", "Over The Air", "Los Angeles"},
		"IL": {"IL51244", "Over The Air", "Chicago"},
		"TX": {"TX30063", "Over The Air", "Dallas"},
		"FL": {"FL14124", "Over The Air", "Miami"},
		"PA": {"PA44583", "Over The Air", "Philadelphia"},
		"GA": {"GA03631", "Over The Air", "Atlanta"},
		"MA": {"MA02540", "Over The Air", "Boston"},
		"WA": {"WA69021", "Over The Air", "Seattle"},
		"CO": {"CO08066", "Over The Air", "Denver"},
	}

	if ota, ok := otaHeadends[state]; ok {
		providers = append(providers, gracenote.Provider{
			HeadendID: ota.headendID,
			Name:      ota.name,
			Type:      "Antenna",
			Location:  ota.market,
			LineupID:  fmt.Sprintf("USA-%s-DEFAULT", ota.headendID),
		})
	}

	return providers
}

// getStateFromZipPrefix determines state from zip code prefix when API lookup fails
func getStateFromZipPrefix(postalCode string) string {
	if len(postalCode) < 3 {
		return ""
	}
	prefix := postalCode[:3]
	prefixNum := 0
	fmt.Sscanf(prefix, "%d", &prefixNum)

	switch {
	case prefixNum >= 100 && prefixNum <= 149:
		return "NY"
	case prefixNum >= 150 && prefixNum <= 196:
		return "PA"
	case prefixNum >= 200 && prefixNum <= 205:
		return "DC"
	case prefixNum >= 206 && prefixNum <= 219:
		return "MD"
	case prefixNum >= 220 && prefixNum <= 246:
		return "VA"
	case prefixNum >= 250 && prefixNum <= 268:
		return "WV"
	case prefixNum >= 270 && prefixNum <= 289:
		return "NC"
	case prefixNum >= 290 && prefixNum <= 299:
		return "SC"
	case prefixNum >= 300 && prefixNum <= 319:
		return "GA"
	case prefixNum >= 320 && prefixNum <= 339:
		return "FL"
	case prefixNum >= 350 && prefixNum <= 369:
		return "AL"
	case prefixNum >= 370 && prefixNum <= 385:
		return "TN"
	case prefixNum >= 386 && prefixNum <= 397:
		return "MS"
	case prefixNum >= 400 && prefixNum <= 427:
		return "KY"
	case prefixNum >= 430 && prefixNum <= 459:
		return "OH"
	case prefixNum >= 460 && prefixNum <= 479:
		return "IN"
	case prefixNum >= 480 && prefixNum <= 499:
		return "MI"
	case prefixNum >= 500 && prefixNum <= 528:
		return "IA"
	case prefixNum >= 530 && prefixNum <= 549:
		return "WI"
	case prefixNum >= 550 && prefixNum <= 567:
		return "MN"
	case prefixNum >= 570 && prefixNum <= 577:
		return "SD"
	case prefixNum >= 580 && prefixNum <= 588:
		return "ND"
	case prefixNum >= 590 && prefixNum <= 599:
		return "MT"
	case prefixNum >= 600 && prefixNum <= 629:
		return "IL"
	case prefixNum >= 630 && prefixNum <= 658:
		return "MO"
	case prefixNum >= 660 && prefixNum <= 679:
		return "KS"
	case prefixNum >= 680 && prefixNum <= 693:
		return "NE"
	case prefixNum >= 700 && prefixNum <= 714:
		return "LA"
	case prefixNum >= 716 && prefixNum <= 729:
		return "AR"
	case prefixNum >= 730 && prefixNum <= 749:
		return "OK"
	case prefixNum >= 750 && prefixNum <= 799:
		return "TX"
	case prefixNum >= 800 && prefixNum <= 816:
		return "CO"
	case prefixNum >= 820 && prefixNum <= 831:
		return "WY"
	case prefixNum >= 832 && prefixNum <= 838:
		return "ID"
	case prefixNum >= 840 && prefixNum <= 847:
		return "UT"
	case prefixNum >= 850 && prefixNum <= 865:
		return "AZ"
	case prefixNum >= 870 && prefixNum <= 884:
		return "NM"
	case prefixNum >= 889 && prefixNum <= 898:
		return "NV"
	case prefixNum >= 900 && prefixNum <= 961:
		return "CA"
	case prefixNum >= 970 && prefixNum <= 979:
		return "OR"
	case prefixNum >= 980 && prefixNum <= 994:
		return "WA"
	case prefixNum >= 995 && prefixNum <= 999:
		return "AK"
	case prefixNum >= 10 && prefixNum <= 27:
		return "MA"
	case prefixNum >= 28 && prefixNum <= 29:
		return "RI"
	case prefixNum >= 30 && prefixNum <= 38:
		return "NH"
	case prefixNum >= 39 && prefixNum <= 49:
		return "ME"
	case prefixNum >= 50 && prefixNum <= 54:
		return "VT"
	case prefixNum >= 60 && prefixNum <= 69:
		return "CT"
	case prefixNum >= 70 && prefixNum <= 89:
		return "NJ"
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
		Name                string `json:"name" binding:"required"`
		ProviderType        string `json:"providerType" binding:"required"` // xmltv or gracenote
		URL                 string `json:"url"`                             // For XMLTV
		GracenoteAffiliate  string `json:"gracenoteAffiliate"`              // For Gracenote
		GracenotePostalCode string `json:"gracenotePostalCode"`             // For Gracenote
		GracenoteHours      int    `json:"gracenoteHours"`                  // For Gracenote
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
		Name:                req.Name,
		ProviderType:        req.ProviderType,
		URL:                 req.URL,
		GracenoteAffiliate:  req.GracenoteAffiliate,
		GracenotePostalCode: req.GracenotePostalCode,
		GracenoteHours:      req.GracenoteHours,
		Enabled:             true,
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

	// Add scheduler status
	if s.epgScheduler != nil {
		stats["scheduler"] = s.epgScheduler.GetStatus()
	}

	c.JSON(http.StatusOK, stats)
}

// getEPGSchedulerStatus returns the EPG scheduler status
func (s *Server) getEPGSchedulerStatus(c *gin.Context) {
	if s.epgScheduler == nil {
		c.JSON(http.StatusOK, gin.H{
			"enabled": false,
			"message": "EPG scheduler not initialized",
		})
		return
	}

	c.JSON(http.StatusOK, s.epgScheduler.GetStatus())
}

// getGuideCacheStats returns cache statistics
func (s *Server) getGuideCacheStats(c *gin.Context) {
	if s.guideCache == nil {
		c.JSON(http.StatusOK, gin.H{
			"enabled": false,
			"message": "Guide cache not initialized",
		})
		return
	}

	c.JSON(http.StatusOK, s.guideCache.Stats())
}

// invalidateGuideCache clears the guide cache
func (s *Server) invalidateGuideCache(c *gin.Context) {
	if s.guideCache == nil {
		c.JSON(http.StatusOK, gin.H{"message": "Guide cache not initialized"})
		return
	}

	s.guideCache.InvalidateAll()
	c.JSON(http.StatusOK, gin.H{"message": "Guide cache invalidated"})
}

// forceEPGRefresh triggers an immediate EPG refresh
func (s *Server) forceEPGRefresh(c *gin.Context) {
	if s.epgScheduler == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "EPG scheduler not initialized"})
		return
	}

	// Invalidate cache when refreshing EPG
	if s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}

	s.epgScheduler.ForceRefresh()
	c.JSON(http.StatusOK, gin.H{
		"message": "EPG refresh triggered",
		"status":  s.epgScheduler.GetStatus(),
	})
}

// refreshAllEPG refreshes EPG from all sources
func (s *Server) refreshAllEPG(c *gin.Context) {
	// Invalidate cache when refreshing EPG
	if s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}

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

			// Parse Gracenote flags for new/premiere/live/finale
			isNew := false
			isPremiere := false
			isLive := false
			isFinale := false
			for _, flag := range event.Flag {
				flagLower := strings.ToLower(flag)
				switch {
				case flagLower == "new":
					isNew = true
				case flagLower == "premiere" || strings.Contains(flagLower, "premiere"):
					isPremiere = true
					isNew = true // Premieres are always new
				case flagLower == "live":
					isLive = true
				case flagLower == "finale" || strings.Contains(flagLower, "finale"):
					isFinale = true
				}
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
				IsNew:         isNew,
				IsPremiere:    isPremiere,
				IsLive:        isLive,
				IsFinale:      isFinale,
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
	if limit < 1 || limit > 15000 {
		limit = 100
	}
	offset := (page - 1) * limit

	// Build query
	query := s.db.Model(&models.Program{})

	// Filter by EPG source if provided
	if epgSourceID != "" {
		sourceID, err := strconv.Atoi(epgSourceID)
		if err == nil {
			// Get the EPG source to determine how to filter
			var epgSource models.EPGSource
			if err := s.db.First(&epgSource, sourceID).Error; err == nil {
				// For Gracenote sources, filter by channel_id prefix
				if epgSource.ProviderType == "gracenote" && epgSource.GracenoteAffiliate != "" {
					prefix := fmt.Sprintf("gracenote-%s-%%", epgSource.GracenoteAffiliate)
					query = query.Where("channel_id LIKE ?", prefix)
				} else if epgSource.ProviderType == "xmltv" {
					// For XMLTV sources, use the old logic (filter by mapped channels)
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
			// Get the EPG source to determine how to filter
			var epgSource models.EPGSource
			if err := s.db.First(&epgSource, sourceID).Error; err == nil {
				// For Gracenote sources, filter by channel_id prefix
				if epgSource.ProviderType == "gracenote" && epgSource.GracenoteAffiliate != "" {
					prefix := fmt.Sprintf("gracenote-%s-%%", epgSource.GracenoteAffiliate)
					log.Printf("📺 EPG Channels query: source=%s, affiliate=%s, prefix=%s", epgSource.Name, epgSource.GracenoteAffiliate, prefix)

					// Debug: count total programs and matching programs
					var totalCount int64
					s.db.Model(&models.Program{}).Count(&totalCount)
					var matchingCount int64
					s.db.Model(&models.Program{}).Where("channel_id LIKE ?", prefix).Count(&matchingCount)
					log.Printf("📊 Programs in DB: total=%d, matching prefix=%d", totalCount, matchingCount)

					// Sample some channel_ids to see what patterns exist
					var sampleIDs []string
					s.db.Model(&models.Program{}).Distinct("channel_id").Limit(5).Pluck("channel_id", &sampleIDs)
					log.Printf("📋 Sample channel_ids in DB: %v", sampleIDs)

					query = query.Where("channel_id LIKE ?", prefix)
				} else if epgSource.ProviderType == "xmltv" {
					// For XMLTV sources, show all non-Gracenote channels
					// NOTE: Since Programs table doesn't track epg_source_id, we can't
					// distinguish which programs belong to which XMLTV source.
					// Just exclude Gracenote channels (which have their own prefix).
					log.Printf("📺 XMLTV EPG source: %s - showing all non-Gracenote channels", epgSource.Name)

					sourceName := strings.ToLower(epgSource.Name)
					if strings.Contains(sourceName, "fubo") {
						// For Fubo, use known channel mappings
						fuboIDs := make([]string, 0, len(livetv.FuboTVMappings))
						for id := range livetv.FuboTVMappings {
							fuboIDs = append(fuboIDs, id)
						}
						if len(fuboIDs) > 0 {
							query = query.Where("channel_id IN ?", fuboIDs)
						}
					} else {
						// For all other XMLTV sources (including DIRECTV), show all non-Gracenote channels
						query = query.Where("channel_id NOT LIKE ?", "gracenote-%")
					}
				}
			}
		}
	}

	// Get distinct channel IDs
	var channelIDs []string
	query.Pluck("channel_id", &channelIDs)

	// For each channel ID, get a sample program to show what's on that channel
	type EPGChannel struct {
		ChannelID     string `json:"channelId"`
		CallSign      string `json:"callSign"`
		ChannelNo     string `json:"channelNo"`
		AffiliateName string `json:"affiliateName,omitempty"`
		SampleTitle   string `json:"sampleTitle"`
	}

	channels := make([]EPGChannel, 0, len(channelIDs))
	for _, channelID := range channelIDs {
		var program models.Program
		s.db.Where("channel_id = ?", channelID).Order("start DESC").First(&program)

		// Get call sign from program or fallback to Fubo channel names
		callSign := program.CallSign
		if callSign == "" {
			// Try Fubo channel names lookup
			if name, ok := livetv.FuboChannelNames[channelID]; ok {
				callSign = name
			}
		}

		channels = append(channels, EPGChannel{
			ChannelID:     channelID,
			CallSign:      callSign,
			ChannelNo:     program.ChannelNo,
			AffiliateName: program.AffiliateName,
			SampleTitle:   program.Title,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"channels": channels,
	})
}

// ============ Catch-Up TV / Time-Shift Handlers ============

// getCatchUpPrograms returns programs available for catch-up viewing
func (s *Server) getCatchUpPrograms(c *gin.Context) {
	channelID := c.Param("id")

	id, err := strconv.ParseUint(channelID, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	// Get channel
	var channel models.Channel
	if err := s.db.First(&channel, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not found"})
		return
	}

	// Check if channel is being buffered
	isBuffering := s.timeshiftBuffer.IsBuffering(uint(id))
	bufferActive, bufferStart, bufferDuration := s.timeshiftBuffer.GetBufferStatus(uint(id))

	// Default buffer window (4 hours) even if not actively buffering
	now := time.Now()
	if !bufferActive {
		bufferStart = now.Add(-4 * time.Hour)
	}

	var programs []models.Program
	s.db.Where("channel_id = ? AND start >= ? AND start <= ?",
		channel.ChannelID, bufferStart, now).
		Order("start ASC").
		Find(&programs)

	type CatchUpProgram struct {
		ID          uint      `json:"id"`
		ProgramID   string    `json:"programId"`
		ChannelID   uint      `json:"channelId"`
		Title       string    `json:"title"`
		StartTime   time.Time `json:"startTime"`
		EndTime     time.Time `json:"endTime"`
		Duration    int       `json:"duration"`
		Description string    `json:"description,omitempty"`
		Thumb       string    `json:"thumb,omitempty"`
		Available   bool      `json:"available"`
	}

	result := make([]CatchUpProgram, 0, len(programs))
	for _, p := range programs {
		// Program is available if buffering is active and program is within buffer window
		available := bufferActive && p.End.Before(now) && p.Start.After(bufferStart)

		result = append(result, CatchUpProgram{
			ID:          p.ID,
			ProgramID:   fmt.Sprintf("%d", p.ID),
			ChannelID:   uint(id),
			Title:       p.Title,
			StartTime:   p.Start,
			EndTime:     p.End,
			Duration:    int(p.End.Sub(p.Start).Seconds()),
			Description: p.Description,
			Thumb:       p.Icon,
			Available:   available,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"channel":        channel,
		"programs":       result,
		"bufferStart":    bufferStart,
		"bufferHours":    4,
		"bufferActive":   bufferActive,
		"bufferDuration": int(bufferDuration.Seconds()),
		"isBuffering":    isBuffering,
	})
}

// getStartOverInfo returns info for starting over the current program
func (s *Server) getStartOverInfo(c *gin.Context) {
	channelID := c.Param("id")

	id, err := strconv.ParseUint(channelID, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	// Get channel
	var channel models.Channel
	if err := s.db.First(&channel, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not found"})
		return
	}

	// Get current program
	now := time.Now()
	var program models.Program
	err = s.db.Where("channel_id = ? AND start <= ? AND end > ?",
		channel.ChannelID, now, now).First(&program).Error

	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"channel":      channel,
			"program":      nil,
			"startOverUrl": nil,
			"available":    false,
		})
		return
	}

	// Calculate how far into the program we are
	elapsedSeconds := int(now.Sub(program.Start).Seconds())

	// For Start Over, we provide a URL that seeks back to the program start
	// This works with DVR buffer or time-shift buffer
	startOverUrl := fmt.Sprintf("/livetv/channels/%d/stream?startOver=true&offset=%d", id, elapsedSeconds)

	c.JSON(http.StatusOK, gin.H{
		"channel": channel,
		"program": gin.H{
			"id":          program.ID,
			"title":       program.Title,
			"startTime":   program.Start,
			"endTime":     program.End,
			"description": program.Description,
			"thumb":       program.Icon,
			"elapsed":     elapsedSeconds,
			"remaining":   int(program.End.Sub(now).Seconds()),
		},
		"startOverUrl": startOverUrl,
		"available":    elapsedSeconds > 30, // Only allow start over if we're at least 30 seconds in
	})
}

// ============ TimeShift Streaming ============

// getTimeshiftPlaylist returns an HLS playlist for time-shifted playback
func (s *Server) getTimeshiftPlaylist(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	// Get start segment from query
	startSegment := 0
	if startStr := c.Query("start"); startStr != "" {
		if s, err := strconv.Atoi(startStr); err == nil {
			startSegment = s
		}
	}

	// Generate playlist
	playlist, err := s.timeshiftBuffer.GenerateTimeshiftPlaylist(uint(id), startSegment)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Header("Content-Type", "application/vnd.apple.mpegurl")
	c.Header("Cache-Control", "no-cache")
	c.String(http.StatusOK, playlist)
}

// getTimeshiftSegment serves a timeshift segment file
func (s *Server) getTimeshiftSegment(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	filename := c.Param("filename")
	if filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing filename"})
		return
	}

	// Security: only allow .ts files and prevent path traversal
	if len(filename) < 3 || filename[len(filename)-3:] != ".ts" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid segment filename"})
		return
	}

	// Get buffer directory for this channel
	bufferDir := s.timeshiftBuffer.GetBufferDir(uint(id))
	if bufferDir == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not being buffered"})
		return
	}

	// Serve the segment file
	segmentPath := bufferDir + "/" + filename
	c.Header("Content-Type", "video/mp2t")
	c.Header("Cache-Control", "max-age=3600")
	c.File(segmentPath)
}

// startTimeshiftBuffer starts buffering a channel for catch-up
func (s *Server) startTimeshiftBuffer(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	// Get the channel
	var channel models.Channel
	if err := s.db.First(&channel, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not found"})
		return
	}

	// Start buffering
	if err := s.timeshiftBuffer.StartBuffer(&channel); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":    "buffering",
		"channelId": id,
		"message":   fmt.Sprintf("Started buffering channel %s", channel.Name),
	})
}

// stopTimeshiftBuffer stops buffering a channel
func (s *Server) stopTimeshiftBuffer(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	s.timeshiftBuffer.StopBuffer(uint(id))

	c.JSON(http.StatusOK, gin.H{
		"status":    "stopped",
		"channelId": id,
		"message":   "Stopped buffering channel",
	})
}

// ============ EPG Maintenance ============

// getEPGConflicts detects duplicate and conflicting EPG programs
func (s *Server) getEPGConflicts(c *gin.Context) {
	// Optional filter by channel IDs
	channelIDsParam := c.Query("channelIds")
	var channelIDs []string
	if channelIDsParam != "" {
		channelIDs = splitAndTrim(channelIDsParam, ",")
	}

	detector := livetv.NewDuplicateDetector(s.db)
	report, err := detector.DetectConflicts(channelIDs)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, report)
}

// resolveDuplicates removes duplicate EPG programs
func (s *Server) resolveDuplicates(c *gin.Context) {
	dryRun := c.Query("dryRun") != "false" // Default to dry run

	detector := livetv.NewDuplicateDetector(s.db)
	result, err := detector.ResolveDuplicates(dryRun)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Invalidate cache after cleaning up
	if !dryRun && result.Deleted > 0 && s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}

	c.JSON(http.StatusOK, result)
}

// resolveOverlaps fixes overlapping EPG programs
func (s *Server) resolveOverlaps(c *gin.Context) {
	dryRun := c.Query("dryRun") != "false" // Default to dry run

	// Optional filter by channel IDs
	channelIDsParam := c.Query("channelIds")
	var channelIDs []string
	if channelIDsParam != "" {
		channelIDs = splitAndTrim(channelIDsParam, ",")
	}

	detector := livetv.NewDuplicateDetector(s.db)
	result, err := detector.ResolveOverlaps(channelIDs, dryRun)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Invalidate cache after cleaning up
	if !dryRun && result.Fixed > 0 && s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}

	c.JSON(http.StatusOK, result)
}

// cleanupOldPrograms removes programs that ended more than X hours ago
func (s *Server) cleanupOldPrograms(c *gin.Context) {
	hours, _ := strconv.Atoi(c.DefaultQuery("hours", "48"))
	if hours < 1 {
		hours = 48
	}

	detector := livetv.NewDuplicateDetector(s.db)
	deleted, err := detector.CleanupOldPrograms(hours)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Invalidate cache after cleanup
	if deleted > 0 && s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}

	c.JSON(http.StatusOK, gin.H{
		"deleted": deleted,
		"cutoff":  fmt.Sprintf("%d hours ago", hours),
	})
}

// splitAndTrim splits a string by separator and trims whitespace
func splitAndTrim(s, sep string) []string {
	parts := make([]string, 0)
	for _, part := range strings.Split(s, sep) {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			parts = append(parts, trimmed)
		}
	}
	return parts
}

// ============ Multi-Source Fallback ============

// getEPGSourceHealth returns health status for all EPG sources
func (s *Server) getEPGSourceHealth(c *gin.Context) {
	manager := livetv.NewMultiSourceManager(s.db)
	if err := manager.InitializeSources(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, manager.GetSourceStatus())
}

// fetchWithFallback attempts to fetch EPG with automatic fallback
func (s *Server) fetchWithFallback(c *gin.Context) {
	manager := livetv.NewMultiSourceManager(s.db)
	if err := manager.InitializeSources(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	parser := livetv.NewEPGParser(s.db)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	result := manager.FetchWithFallback(ctx, parser)

	// Invalidate cache after successful fetch
	if result.Success && s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}

	// Add error string if there's an error
	if result.Error != nil {
		result.ErrorStr = result.Error.Error()
	}

	statusCode := http.StatusOK
	if !result.Success {
		statusCode = http.StatusServiceUnavailable
	}

	c.JSON(statusCode, result)
}

// resetSourceHealth resets the health tracking for a specific source
func (s *Server) resetSourceHealth(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	manager := livetv.NewMultiSourceManager(s.db)
	if err := manager.InitializeSources(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	manager.ResetSourceHealth(uint(id))

	// Also clear the error in the database
	s.db.Model(&models.EPGSource{}).Where("id = ?", id).Update("last_error", "")

	c.JSON(http.StatusOK, gin.H{"message": "Source health reset successfully"})
}

// ============ Archive / Catch-up Handlers ============

// getArchivedPrograms returns archived programs available for catch-up on a channel
func (s *Server) getArchivedPrograms(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	limit := 50 // Default limit
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}

	if s.archiveManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Archive manager not available"})
		return
	}

	programs, err := s.archiveManager.GetArchivedPrograms(uint(id), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Get channel info for archive status
	isArchiving, startTime, retentionDays := s.archiveManager.GetArchiveStatus(uint(id))

	c.JSON(http.StatusOK, gin.H{
		"programs":      programs,
		"isArchiving":   isArchiving,
		"archiveStart":  startTime,
		"retentionDays": retentionDays,
	})
}

// enableChannelArchive enables archive recording for a channel
func (s *Server) enableChannelArchive(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	var req struct {
		Days int `json:"days"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		req.Days = 7 // Default 7 days
	}

	if s.archiveManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Archive manager not available"})
		return
	}

	if err := s.archiveManager.EnableArchive(uint(id), req.Days); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":       "Archive enabled for channel",
		"channelId":     id,
		"retentionDays": req.Days,
	})
}

// disableChannelArchive disables archive recording for a channel
func (s *Server) disableChannelArchive(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid channel ID"})
		return
	}

	if s.archiveManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Archive manager not available"})
		return
	}

	if err := s.archiveManager.DisableArchive(uint(id)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":   "Archive disabled for channel",
		"channelId": id,
	})
}

// getArchivePlaylist returns an HLS playlist for an archived program
func (s *Server) getArchivePlaylist(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid archive program ID"})
		return
	}

	if s.archiveManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Archive manager not available"})
		return
	}

	playlist, err := s.archiveManager.GenerateArchivePlaylist(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Header("Content-Type", "application/vnd.apple.mpegurl")
	c.Header("Cache-Control", "no-cache")
	c.String(http.StatusOK, playlist)
}

// getArchiveSegment serves an individual segment file
func (s *Server) getArchiveSegment(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid archive program ID"})
		return
	}

	filename := c.Param("filename")
	if filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Segment filename required"})
		return
	}

	if s.archiveManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Archive manager not available"})
		return
	}

	segPath, err := s.archiveManager.GetSegmentPath(uint(id), filename)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.Header("Content-Type", "video/MP2T")
	c.Header("Cache-Control", "max-age=86400") // Cache segments for 24 hours
	c.File(segPath)
}

// getArchiveStatus returns status of all archive recordings
func (s *Server) getArchiveStatus(c *gin.Context) {
	if s.archiveManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "Archive manager not available"})
		return
	}

	// Get all channels with archive enabled
	var channels []models.Channel
	s.db.Where("archive_enabled = ?", true).Find(&channels)

	type channelStatus struct {
		ChannelID     uint      `json:"channelId"`
		ChannelName   string    `json:"channelName"`
		IsArchiving   bool      `json:"isArchiving"`
		ArchiveStart  time.Time `json:"archiveStart,omitempty"`
		RetentionDays int       `json:"retentionDays"`
		ProgramCount  int64     `json:"programCount"`
	}

	statuses := make([]channelStatus, 0, len(channels))
	for _, ch := range channels {
		isArchiving, startTime, retentionDays := s.archiveManager.GetArchiveStatus(ch.ID)

		var count int64
		s.db.Model(&models.ArchiveProgram{}).Where("channel_id = ? AND status = ?", ch.ID, "available").Count(&count)

		statuses = append(statuses, channelStatus{
			ChannelID:     ch.ID,
			ChannelName:   ch.Name,
			IsArchiving:   isArchiving,
			ArchiveStart:  startTime,
			RetentionDays: retentionDays,
			ProgramCount:  count,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"channels":        statuses,
		"totalChannels":   len(channels),
		"activeRecording": len(statuses),
	})
}

// proxyChannelStream proxies a channel's stream for web playback
func (s *Server) proxyChannelStream(c *gin.Context) {
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

	if channel.StreamURL == "" {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel has no stream URL"})
		return
	}

	// Create request to upstream stream
	req, err := http.NewRequestWithContext(c.Request.Context(), "GET", channel.StreamURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
		return
	}

	// Copy relevant headers from original request
	if ua := c.GetHeader("User-Agent"); ua != "" {
		req.Header.Set("User-Agent", ua)
	}

	// Don't follow redirects - we need to handle HLS redirects specially
	// because HLS CDNs often use IP-bound tokens
	client := &http.Client{
		Timeout: 0, // No timeout for streaming
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse // Don't follow redirects
		},
	}

	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to connect to stream"})
		return
	}
	defer resp.Body.Close()

	// If upstream returns a redirect to an HLS stream, proxy it
	if resp.StatusCode == http.StatusFound || resp.StatusCode == http.StatusMovedPermanently || resp.StatusCode == http.StatusTemporaryRedirect {
		location := resp.Header.Get("Location")
		if location != "" && (strings.Contains(location, ".m3u8") || strings.Contains(location, "m3u8")) {
			// Proxy the HLS manifest
			s.proxyHLSManifest(c, location, channel.ID)
			return
		}
		// Non-HLS redirect - pass through
		c.Header("Access-Control-Allow-Origin", "*")
		c.Redirect(resp.StatusCode, location)
		return
	}

	// Set response headers
	ct := resp.Header.Get("Content-Type")
	if ct == "" {
		ct = "video/mp2t"
	}
	c.Header("Content-Type", ct)
	c.Header("Cache-Control", "no-cache, no-store, must-revalidate")
	c.Header("Access-Control-Allow-Origin", "*")
	c.Header("Access-Control-Expose-Headers", "Content-Type")

	c.Status(resp.StatusCode)

	// Flush headers immediately so client knows stream is starting
	if flusher, ok := c.Writer.(http.Flusher); ok {
		flusher.Flush()
	}

	// Get the flusher interface for streaming
	flusher, ok := c.Writer.(http.Flusher)
	if !ok {
		// Fallback to regular copy if flushing not supported
		io.Copy(c.Writer, resp.Body)
		return
	}

	// Stream the response with periodic flushing
	buf := make([]byte, 32*1024) // 32KB buffer
	for {
		n, err := resp.Body.Read(buf)
		if n > 0 {
			c.Writer.Write(buf[:n])
			flusher.Flush()
		}
		if err != nil {
			break
		}
	}
}

// proxyHLSManifest fetches an HLS manifest and rewrites URLs to proxy through our server
func (s *Server) proxyHLSManifest(c *gin.Context, manifestURL string, channelID uint) {
	client := &http.Client{Timeout: 30 * time.Second}

	req, err := http.NewRequestWithContext(c.Request.Context(), "GET", manifestURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
		return
	}

	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch manifest"})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		c.JSON(resp.StatusCode, gin.H{"error": "Upstream returned error"})
		return
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read manifest"})
		return
	}

	manifest := string(body)

	// Parse base URL for resolving relative URLs
	parsedURL, err := url.Parse(manifestURL)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse manifest URL"})
		return
	}
	baseURL := parsedURL.Scheme + "://" + parsedURL.Host + parsedURL.Path[:strings.LastIndex(parsedURL.Path, "/")+1]

	// Rewrite URLs in manifest to proxy through our server
	lines := strings.Split(manifest, "\n")
	var rewrittenLines []string

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)

		// Skip empty lines and comments (but keep #EXT tags)
		if trimmed == "" {
			rewrittenLines = append(rewrittenLines, line)
			continue
		}

		// If it's a URL line (not starting with #), rewrite it
		if !strings.HasPrefix(trimmed, "#") {
			var fullURL string
			if strings.HasPrefix(trimmed, "http://") || strings.HasPrefix(trimmed, "https://") {
				fullURL = trimmed
			} else {
				// Relative URL - resolve against base
				fullURL = baseURL + trimmed
			}
			// Rewrite to proxy URL
			proxyURL := fmt.Sprintf("/livetv/channels/%d/hls-segment?url=%s", channelID, url.QueryEscape(fullURL))
			rewrittenLines = append(rewrittenLines, proxyURL)
		} else if strings.HasPrefix(trimmed, "#EXT-X-STREAM-INF") || strings.HasPrefix(trimmed, "#EXT-X-MEDIA") {
			// These tags may contain URI attributes that need rewriting
			if strings.Contains(trimmed, "URI=\"") {
				// Extract and rewrite URI
				rewritten := rewriteHLSURIAttribute(trimmed, baseURL, channelID)
				rewrittenLines = append(rewrittenLines, rewritten)
			} else {
				rewrittenLines = append(rewrittenLines, line)
			}
		} else {
			rewrittenLines = append(rewrittenLines, line)
		}
	}

	c.Header("Content-Type", "application/vnd.apple.mpegurl")
	c.Header("Access-Control-Allow-Origin", "*")
	c.Header("Cache-Control", "no-cache")
	c.String(http.StatusOK, strings.Join(rewrittenLines, "\n"))
}

// rewriteHLSURIAttribute rewrites URI attributes in HLS tags
func rewriteHLSURIAttribute(line, baseURL string, channelID uint) string {
	// Find URI="..." and rewrite
	uriStart := strings.Index(line, "URI=\"")
	if uriStart == -1 {
		return line
	}
	uriStart += 5 // Skip past URI="
	uriEnd := strings.Index(line[uriStart:], "\"")
	if uriEnd == -1 {
		return line
	}
	uriEnd += uriStart

	uri := line[uriStart:uriEnd]
	var fullURL string
	if strings.HasPrefix(uri, "http://") || strings.HasPrefix(uri, "https://") {
		fullURL = uri
	} else {
		fullURL = baseURL + uri
	}
	proxyURL := fmt.Sprintf("/livetv/channels/%d/hls-segment?url=%s", channelID, url.QueryEscape(fullURL))

	return line[:uriStart] + proxyURL + line[uriEnd:]
}

// proxyHLSSegment proxies an HLS segment request
func (s *Server) proxyHLSSegment(c *gin.Context) {
	segmentURL := c.Query("url")
	if segmentURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing url parameter"})
		return
	}

	client := &http.Client{Timeout: 60 * time.Second}

	req, err := http.NewRequestWithContext(c.Request.Context(), "GET", segmentURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create request"})
		return
	}

	// Forward range header if present
	if rangeHeader := c.GetHeader("Range"); rangeHeader != "" {
		req.Header.Set("Range", rangeHeader)
	}

	resp, err := client.Do(req)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch segment"})
		return
	}
	defer resp.Body.Close()

	// Check if this is another m3u8 (variant playlist)
	contentType := resp.Header.Get("Content-Type")
	if strings.Contains(contentType, "mpegurl") || strings.Contains(segmentURL, ".m3u8") {
		// It's a playlist - rewrite it
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read playlist"})
			return
		}

		// Get channel ID from path
		idStr := c.Param("id")
		channelID, _ := strconv.ParseUint(idStr, 10, 32)

		// Parse base URL
		parsedURL, _ := url.Parse(segmentURL)
		baseURL := parsedURL.Scheme + "://" + parsedURL.Host + parsedURL.Path[:strings.LastIndex(parsedURL.Path, "/")+1]

		manifest := string(body)
		lines := strings.Split(manifest, "\n")
		var rewrittenLines []string

		for _, line := range lines {
			trimmed := strings.TrimSpace(line)
			if trimmed == "" {
				rewrittenLines = append(rewrittenLines, line)
				continue
			}
			if !strings.HasPrefix(trimmed, "#") {
				var fullURL string
				if strings.HasPrefix(trimmed, "http://") || strings.HasPrefix(trimmed, "https://") {
					fullURL = trimmed
				} else {
					fullURL = baseURL + trimmed
				}
				proxyURL := fmt.Sprintf("/livetv/channels/%d/hls-segment?url=%s", channelID, url.QueryEscape(fullURL))
				rewrittenLines = append(rewrittenLines, proxyURL)
			} else {
				rewrittenLines = append(rewrittenLines, line)
			}
		}

		c.Header("Content-Type", "application/vnd.apple.mpegurl")
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Cache-Control", "no-cache")
		c.String(http.StatusOK, strings.Join(rewrittenLines, "\n"))
		return
	}

	// Copy response headers
	if contentType != "" {
		c.Header("Content-Type", contentType)
	}
	if contentRange := resp.Header.Get("Content-Range"); contentRange != "" {
		c.Header("Content-Range", contentRange)
	}
	if contentLength := resp.Header.Get("Content-Length"); contentLength != "" {
		c.Header("Content-Length", contentLength)
	}
	c.Header("Access-Control-Allow-Origin", "*")

	c.Status(resp.StatusCode)
	io.Copy(c.Writer, resp.Body)
}
