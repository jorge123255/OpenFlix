package api

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/livetv"
	"github.com/openflix/openflix-server/internal/models"
	log "github.com/sirupsen/logrus"
)

// OnLaterItem represents a program with its channel info
type OnLaterItem struct {
	Program      models.Program `json:"program"`
	Channel      *models.Channel `json:"channel,omitempty"`
	HasRecording bool           `json:"hasRecording"`
	RecordingID  *uint          `json:"recordingId,omitempty"`
}

// OnLaterResponse is the response for on later queries
type OnLaterResponse struct {
	Items       []OnLaterItem `json:"items"`
	TotalCount  int           `json:"totalCount"`
	StartTime   time.Time     `json:"startTime"`
	EndTime     time.Time     `json:"endTime"`
}

// handleGetOnLaterAll returns all upcoming programs
// GET /api/onlater/all
func (s *Server) handleGetOnLaterAll(c *gin.Context) {
	start, end := s.getOnLaterTimeRange(c)

	var programs []models.Program
	s.db.Where("start >= ? AND start < ?", start, end).
		Order("start ASC").
		Limit(500).
		Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetOnLaterTVShows returns upcoming TV shows (not movies, sports, kids, or news)
// GET /api/onlater/tvshows
func (s *Server) handleGetOnLaterTVShows(c *gin.Context) {
	start, end := s.getOnLaterTimeRange(c)

	var programs []models.Program
	s.db.Where("is_movie = ? AND is_sports = ? AND is_kids = ? AND is_news = ? AND start >= ? AND start < ?",
		false, false, false, false, start, end).
		Order("start ASC").
		Limit(200).
		Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetOnLaterMovies returns upcoming movies
// GET /api/onlater/movies
func (s *Server) handleGetOnLaterMovies(c *gin.Context) {
	start, end := s.getOnLaterTimeRange(c)

	var programs []models.Program
	s.db.Where("is_movie = ? AND start >= ? AND start < ?", true, start, end).
		Order("start ASC").
		Limit(100).
		Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetOnLaterSports returns upcoming sports content
// GET /api/onlater/sports
func (s *Server) handleGetOnLaterSports(c *gin.Context) {
	start, end := s.getOnLaterTimeRange(c)
	league := c.Query("league")
	team := c.Query("team")

	query := s.db.Where("is_sports = ? AND start >= ? AND start < ?", true, start, end)

	if league != "" {
		query = query.Where("league = ?", league)
	}

	if team != "" {
		query = query.Where("teams LIKE ?", "%"+team+"%")
	}

	var programs []models.Program
	query.Order("start ASC").Limit(100).Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetOnLaterKids returns upcoming kids content
// GET /api/onlater/kids
func (s *Server) handleGetOnLaterKids(c *gin.Context) {
	start, end := s.getOnLaterTimeRange(c)

	var programs []models.Program
	s.db.Where("is_kids = ? AND start >= ? AND start < ?", true, start, end).
		Order("start ASC").
		Limit(100).
		Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetOnLaterNews returns upcoming news content
// GET /api/onlater/news
func (s *Server) handleGetOnLaterNews(c *gin.Context) {
	start, end := s.getOnLaterTimeRange(c)

	var programs []models.Program
	s.db.Where("is_news = ? AND start >= ? AND start < ?", true, start, end).
		Order("start ASC").
		Limit(100).
		Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetOnLaterPremieres returns upcoming premieres and new episodes
// GET /api/onlater/premieres
func (s *Server) handleGetOnLaterPremieres(c *gin.Context) {
	start, end := s.getOnLaterTimeRange(c)

	var programs []models.Program
	s.db.Where("(is_premiere = ? OR is_new = ?) AND start >= ? AND start < ?", true, true, start, end).
		Order("start ASC").
		Limit(100).
		Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetOnLaterTonight returns everything on tonight (6pm - 2am)
// GET /api/onlater/tonight
func (s *Server) handleGetOnLaterTonight(c *gin.Context) {
	now := time.Now()

	// Start at 6pm today (or now if past 6pm)
	start := time.Date(now.Year(), now.Month(), now.Day(), 18, 0, 0, 0, now.Location())
	if now.After(start) {
		start = now
	}

	// End at 2am tomorrow
	end := time.Date(now.Year(), now.Month(), now.Day()+1, 2, 0, 0, 0, now.Location())

	var programs []models.Program
	s.db.Where("start >= ? AND start < ?", start, end).
		Order("start ASC").
		Limit(200).
		Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetOnLaterWeek returns the full week's programming
// GET /api/onlater/week
func (s *Server) handleGetOnLaterWeek(c *gin.Context) {
	now := time.Now()
	start := now
	end := now.Add(7 * 24 * time.Hour)

	category := c.Query("category")

	query := s.db.Where("start >= ? AND start < ?", start, end)

	// Filter by category if specified
	switch category {
	case "movies":
		query = query.Where("is_movie = ?", true)
	case "sports":
		query = query.Where("is_sports = ?", true)
	case "kids":
		query = query.Where("is_kids = ?", true)
	case "news":
		query = query.Where("is_news = ?", true)
	case "premieres":
		query = query.Where("is_premiere = ? OR is_new = ?", true, true)
	}

	var programs []models.Program
	query.Order("start ASC").Limit(500).Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleSearchOnLater searches upcoming content
// GET /api/onlater/search
func (s *Server) handleSearchOnLater(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter 'q' is required"})
		return
	}

	start, end := s.getOnLaterTimeRange(c)

	var programs []models.Program
	s.db.Where("(title LIKE ? OR description LIKE ?) AND start >= ? AND start < ?",
		"%"+query+"%", "%"+query+"%", start, end).
		Order("start ASC").
		Limit(100).
		Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetOnLaterByChannel returns upcoming content for a specific channel
// GET /api/onlater/channels/:id
func (s *Server) handleGetOnLaterByChannel(c *gin.Context) {
	channelID := c.Param("id")
	start, end := s.getOnLaterTimeRange(c)

	var programs []models.Program
	s.db.Where("channel_id = ? AND start >= ? AND start < ?", channelID, start, end).
		Order("start ASC").
		Limit(100).
		Find(&programs)

	items := s.enrichOnLaterItems(programs)
	c.JSON(http.StatusOK, OnLaterResponse{
		Items:      items,
		TotalCount: len(items),
		StartTime:  start,
		EndTime:    end,
	})
}

// handleGetLeagues returns available sports leagues
// GET /api/onlater/leagues
func (s *Server) handleGetLeagues(c *gin.Context) {
	leagues := livetv.GetAllLeagues()
	c.JSON(http.StatusOK, gin.H{"leagues": leagues})
}

// handleGetTeamsByLeague returns teams for a specific league
// GET /api/onlater/teams/:league
func (s *Server) handleGetTeamsByLeague(c *gin.Context) {
	league := c.Param("league")
	teams := livetv.GetTeamsByLeague(league)

	// Convert to simpler response format
	type TeamInfo struct {
		Name     string   `json:"name"`
		City     string   `json:"city"`
		Nickname string   `json:"nickname"`
		Aliases  []string `json:"aliases"`
	}

	result := make([]TeamInfo, len(teams))
	for i, t := range teams {
		result[i] = TeamInfo{
			Name:     t.Name,
			City:     t.City,
			Nickname: t.Nickname,
			Aliases:  t.Aliases,
		}
	}

	c.JSON(http.StatusOK, gin.H{"teams": result, "league": league})
}

// handleSearchTeams searches for sports teams
// GET /api/onlater/teams/search
func (s *Server) handleSearchTeams(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter 'q' is required"})
		return
	}

	teams := livetv.SearchTeams(query)

	type TeamInfo struct {
		Name     string   `json:"name"`
		City     string   `json:"city"`
		Nickname string   `json:"nickname"`
		League   string   `json:"league"`
		Aliases  []string `json:"aliases"`
	}

	result := make([]TeamInfo, len(teams))
	for i, t := range teams {
		result[i] = TeamInfo{
			Name:     t.Name,
			City:     t.City,
			Nickname: t.Nickname,
			League:   t.League,
			Aliases:  t.Aliases,
		}
	}

	c.JSON(http.StatusOK, gin.H{"teams": result})
}

// handleGetOnLaterStats returns statistics about upcoming content
// GET /api/onlater/stats
func (s *Server) handleGetOnLaterStats(c *gin.Context) {
	now := time.Now()
	end := now.Add(7 * 24 * time.Hour)

	var allCount, tvshowsCount, movieCount, sportsCount, kidsCount, newsCount, premiereCount int64

	s.db.Model(&models.Program{}).Where("start >= ? AND start < ?", now, end).Count(&allCount)
	s.db.Model(&models.Program{}).Where("is_movie = ? AND is_sports = ? AND is_kids = ? AND is_news = ? AND start >= ? AND start < ?", false, false, false, false, now, end).Count(&tvshowsCount)
	s.db.Model(&models.Program{}).Where("is_movie = ? AND start >= ? AND start < ?", true, now, end).Count(&movieCount)
	s.db.Model(&models.Program{}).Where("is_sports = ? AND start >= ? AND start < ?", true, now, end).Count(&sportsCount)
	s.db.Model(&models.Program{}).Where("is_kids = ? AND start >= ? AND start < ?", true, now, end).Count(&kidsCount)
	s.db.Model(&models.Program{}).Where("is_news = ? AND start >= ? AND start < ?", true, now, end).Count(&newsCount)
	s.db.Model(&models.Program{}).Where("(is_premiere = ? OR is_new = ?) AND start >= ? AND start < ?", true, true, now, end).Count(&premiereCount)

	c.JSON(http.StatusOK, gin.H{
		"all":       allCount,
		"tvshows":   tvshowsCount,
		"movies":    movieCount,
		"sports":    sportsCount,
		"kids":      kidsCount,
		"news":      newsCount,
		"premieres": premiereCount,
		"startTime": now,
		"endTime":   end,
	})
}

// getOnLaterTimeRange parses start/end from query params or uses defaults
func (s *Server) getOnLaterTimeRange(c *gin.Context) (time.Time, time.Time) {
	now := time.Now()
	start := now
	end := now.Add(24 * time.Hour) // Default to 24 hours

	if startStr := c.Query("start"); startStr != "" {
		if ts, err := strconv.ParseInt(startStr, 10, 64); err == nil {
			start = time.Unix(ts, 0)
		} else if t, err := time.Parse(time.RFC3339, startStr); err == nil {
			start = t
		}
	}

	if endStr := c.Query("end"); endStr != "" {
		if ts, err := strconv.ParseInt(endStr, 10, 64); err == nil {
			end = time.Unix(ts, 0)
		} else if t, err := time.Parse(time.RFC3339, endStr); err == nil {
			end = t
		}
	}

	// Check for hours parameter
	if hoursStr := c.Query("hours"); hoursStr != "" {
		if hours, err := strconv.Atoi(hoursStr); err == nil && hours > 0 {
			end = start.Add(time.Duration(hours) * time.Hour)
		}
	}

	return start, end
}

// enrichOnLaterItems adds channel and recording info to programs
func (s *Server) enrichOnLaterItems(programs []models.Program) []OnLaterItem {
	items := make([]OnLaterItem, 0, len(programs))

	// Get all channel IDs
	channelIDs := make([]string, 0, len(programs))
	for _, p := range programs {
		channelIDs = append(channelIDs, p.ChannelID)
	}

	// Batch fetch channels
	var channels []models.Channel
	if len(channelIDs) > 0 {
		s.db.Where("channel_id IN ?", channelIDs).Find(&channels)
	}
	channelMap := make(map[string]*models.Channel)
	for i := range channels {
		channelMap[channels[i].ChannelID] = &channels[i]
	}

	// Check for recordings
	programIDs := make([]uint, 0, len(programs))
	for _, p := range programs {
		programIDs = append(programIDs, p.ID)
	}

	var recordings []models.Recording
	if len(programIDs) > 0 {
		s.db.Where("program_id IN ?", programIDs).Find(&recordings)
	}
	recordingMap := make(map[uint]uint)
	for _, r := range recordings {
		if r.ProgramID != nil {
			recordingMap[*r.ProgramID] = r.ID
		}
	}

	for _, p := range programs {
		item := OnLaterItem{
			Program: p,
			Channel: channelMap[p.ChannelID],
		}

		if recID, ok := recordingMap[p.ID]; ok {
			item.HasRecording = true
			item.RecordingID = &recID
		}

		items = append(items, item)
	}

	return items
}

// handleEnrichEPG triggers EPG artwork enrichment from TMDB
// POST /api/onlater/enrich
func (s *Server) handleEnrichEPG(c *gin.Context) {
	if s.epgEnricher == nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "TMDB not configured. Set tmdb_api_key in settings to enable artwork enrichment.",
		})
		return
	}

	// Get limit from query param (default 100)
	limit := 100
	if l := c.Query("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
			if limit > 500 {
				limit = 500 // Cap at 500 to avoid rate limiting
			}
		}
	}

	// Enrich programs in the next 7 days
	start := time.Now()
	end := start.Add(7 * 24 * time.Hour)

	// Run enrichment in background
	go func() {
		enriched, err := s.epgEnricher.EnrichPrograms(start, end, limit)
		if err != nil {
			log.WithError(err).Error("EPG enrichment failed")
		} else {
			log.WithField("enriched", enriched).Info("EPG enrichment completed")
		}
	}()

	c.JSON(http.StatusOK, gin.H{
		"message": "EPG enrichment started",
		"limit":   limit,
	})
}
