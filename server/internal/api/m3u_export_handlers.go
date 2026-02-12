package api

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/livetv"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ M3U Export for Channels DVR ============

// exportChannelsM3U exports all channels as M3U playlist with tvc-guide-stationid
// GET /api/livetv/export.m3u
func (s *Server) exportChannelsM3U(c *gin.Context) {
	query := s.db.Model(&models.Channel{})

	// Default to enabled channels only
	enabledFilter := c.DefaultQuery("enabled", "true")
	if enabledFilter == "true" {
		query = query.Where("enabled = ?", true)
	} else if enabledFilter == "false" {
		query = query.Where("enabled = ?", false)
	}

	// Filter by group
	if group := c.Query("group"); group != "" {
		query = query.Where("`group` = ?", group)
	}

	// Filter favorites only
	if c.Query("favorites") == "true" {
		query = query.Where("is_favorite = ?", true)
	}

	var channels []models.Channel
	if err := query.Order("number, name").Find(&channels).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch channels"})
		return
	}

	// Get base URL for stream endpoints
	baseURL := getBaseURL(c)

	// Build M3U playlist
	var m3u strings.Builder
	m3u.WriteString("#EXTM3U\n")

	for _, ch := range channels {
		// Build EXTINF line with all attributes
		extinf := fmt.Sprintf("#EXTINF:-1")

		// TVG ID - use ChannelID or TVGId
		tvgID := ch.ChannelID
		if tvgID == "" {
			tvgID = ch.TVGId
		}
		if tvgID != "" {
			extinf += fmt.Sprintf(` tvg-id="%s"`, escapeM3UValue(tvgID))
		}

		// TVG name
		extinf += fmt.Sprintf(` tvg-name="%s"`, escapeM3UValue(ch.Name))

		// Channel number
		if ch.Number > 0 {
			extinf += fmt.Sprintf(` tvg-chno="%d"`, ch.Number)
		}

		// Logo
		if ch.Logo != "" {
			extinf += fmt.Sprintf(` tvg-logo="%s"`, escapeM3UValue(ch.Logo))
		}

		// Group
		if ch.Group != "" {
			extinf += fmt.Sprintf(` group-title="%s"`, escapeM3UValue(ch.Group))
		}

		// tvc-guide-stationid - THE KEY FOR CHANNELS DVR!
		// Try to get Gracenote station ID from our mappings
		stationID := getGracenoteStationID(ch)
		if stationID != "" {
			extinf += fmt.Sprintf(` tvc-guide-stationid="%s"`, stationID)
		}

		// End EXTINF line with channel name
		extinf += fmt.Sprintf(",%s\n", ch.Name)
		m3u.WriteString(extinf)

		// Stream URL
		streamURL := fmt.Sprintf("%s/api/livetv/channels/%d/stream.m3u8", baseURL, ch.ID)
		m3u.WriteString(streamURL + "\n")
	}

	c.Header("Content-Type", "audio/x-mpegurl")
	c.Header("Content-Disposition", "attachment; filename=\"channels.m3u\"")
	c.String(http.StatusOK, m3u.String())
}

// exportChannelsLineup exports channels as JSON lineup (HDHomeRun-compatible)
// GET /api/livetv/lineup.json
func (s *Server) exportChannelsLineup(c *gin.Context) {
	query := s.db.Model(&models.Channel{}).Where("enabled = ?", true)

	var channels []models.Channel
	if err := query.Order("number, name").Find(&channels).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch channels"})
		return
	}

	baseURL := getBaseURL(c)

	type LineupEntry struct {
		GuideNumber string `json:"GuideNumber"`
		GuideName   string `json:"GuideName"`
		URL         string `json:"URL"`
		StationID   string `json:"tvc-guide-stationid,omitempty"`
	}

	lineup := make([]LineupEntry, 0, len(channels))
	for _, ch := range channels {
		guideNumber := fmt.Sprintf("%d", ch.Number)
		if ch.Number == 0 {
			guideNumber = fmt.Sprintf("%d", ch.ID)
		}

		entry := LineupEntry{
			GuideNumber: guideNumber,
			GuideName:   ch.Name,
			URL:         fmt.Sprintf("%s/api/livetv/channels/%d/stream.m3u8", baseURL, ch.ID),
			StationID:   getGracenoteStationID(ch),
		}
		lineup = append(lineup, entry)
	}

	c.JSON(http.StatusOK, lineup)
}

// getGracenoteStationID attempts to find the Gracenote station ID for a channel
func getGracenoteStationID(ch models.Channel) string {
	// 1. Try looking up by the channel's provider ID (e.g., FuboTV channel ID)
	if ch.TVGId != "" {
		if mapping, ok := livetv.LookupFuboTVMapping(ch.TVGId); ok {
			return mapping.StationID
		}
	}

	// 2. Try looking up by call sign from EPG
	if ch.EPGCallSign != "" {
		if mapping, _, ok := livetv.LookupByCallSign(strings.ToUpper(ch.EPGCallSign)); ok {
			return mapping.StationID
		}
	}

	// 3. Try looking up by channel name
	if mapping, _, ok := livetv.LookupByName(ch.Name); ok {
		return mapping.StationID
	}

	// 4. If ChannelID looks like a Gracenote station ID (numeric), use it
	if ch.ChannelID != "" {
		// Gracenote IDs are numeric
		isNumeric := true
		for _, c := range ch.ChannelID {
			if c < '0' || c > '9' {
				isNumeric = false
				break
			}
		}
		if isNumeric && len(ch.ChannelID) >= 4 && len(ch.ChannelID) <= 7 {
			return ch.ChannelID
		}
	}

	return ""
}

// escapeM3UValue escapes quotes in M3U attribute values
func escapeM3UValue(s string) string {
	return strings.ReplaceAll(s, `"`, `\"`)
}
