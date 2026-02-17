package api

import (
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/livetv"
	"github.com/openflix/openflix-server/internal/models"
	log "github.com/sirupsen/logrus"
)

// TeamPassRequest is the request body for creating/updating a team pass
type TeamPassRequest struct {
	TeamName        string `json:"teamName" binding:"required"`
	League          string `json:"league" binding:"required"`
	ChannelIDs      string `json:"channelIds,omitempty"`
	PrePadding      int    `json:"prePadding"`
	PostPadding     int    `json:"postPadding"`
	RecordPreGame   bool   `json:"recordPreGame"`
	RecordPostGame  bool   `json:"recordPostGame"`
	PreGameMinutes  int    `json:"preGameMinutes"`
	PostGameMinutes int    `json:"postGameMinutes"`
	KeepCount       int    `json:"keepCount"`
	Priority        int    `json:"priority"`
	Enabled         bool   `json:"enabled"`
}

// TeamPassResponse is the response for a team pass with upcoming games
type TeamPassResponse struct {
	TeamPass      models.TeamPass `json:"teamPass"`
	UpcomingGames []OnLaterItem   `json:"upcomingGames,omitempty"`
}

// handleListTeamPasses returns all team passes for the current user
// GET /api/teampass
func (s *Server) handleListTeamPasses(c *gin.Context) {
	userID, _ := c.Get("userID")

	var teamPasses []models.TeamPass
	s.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&teamPasses)

	// Enrich with upcoming games count and logo URL
	type TeamPassWithCount struct {
		models.TeamPass
		UpcomingCount int    `json:"upcomingCount"`
		LogoURL       string `json:"logoUrl,omitempty"`
	}

	result := make([]TeamPassWithCount, len(teamPasses))
	now := time.Now()
	end := now.Add(7 * 24 * time.Hour)

	for i, tp := range teamPasses {
		result[i].TeamPass = tp

		// Look up team to get logo URL
		team := livetv.FindTeamByName(tp.TeamName)
		if team != nil {
			result[i].LogoURL = team.GetLogoURL()
			log.WithFields(log.Fields{
				"teamName": tp.TeamName,
				"logoUrl":  result[i].LogoURL,
			}).Debug("Found team logo URL")
		} else {
			log.WithField("teamName", tp.TeamName).Warn("Team not found for logo lookup")
		}

		// Count upcoming games for this team
		var count int64
		query := s.db.Model(&models.Program{}).
			Where("is_sports = ? AND start >= ? AND start < ?", true, now, end)

		// Match team name or aliases in teams field only (not title)
		searchTerms := buildTeamSearchTerms(tp.TeamName, tp.TeamAliases)
		if len(searchTerms) > 0 {
			teamConditions := make([]string, len(searchTerms))
			teamArgs := make([]interface{}, len(searchTerms))
			for j, term := range searchTerms {
				teamConditions[j] = "teams LIKE ?"
				teamArgs[j] = "%" + term + "%"
			}
			query = query.Where(strings.Join(teamConditions, " OR "), teamArgs...)
		}

		if tp.League != "" {
			query = query.Where("league = ?", tp.League)
		}

		query.Count(&count)
		result[i].UpcomingCount = int(count)
	}

	c.JSON(http.StatusOK, gin.H{"teamPasses": result})
}

// handleGetTeamPass returns a specific team pass with upcoming games
// GET /api/teampass/:id
func (s *Server) handleGetTeamPass(c *gin.Context) {
	id := c.Param("id")
	userID, _ := c.Get("userID")

	var teamPass models.TeamPass
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&teamPass).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Team pass not found"})
		return
	}

	// Get upcoming games
	upcomingGames := s.getUpcomingGamesForTeamPass(&teamPass)

	c.JSON(http.StatusOK, TeamPassResponse{
		TeamPass:      teamPass,
		UpcomingGames: upcomingGames,
	})
}

// handleCreateTeamPass creates a new team pass
// POST /api/teampass
func (s *Server) handleCreateTeamPass(c *gin.Context) {
	userID, _ := c.Get("userID")

	var req TeamPassRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Look up team to get aliases
	team := livetv.FindTeamByName(req.TeamName)
	aliases := ""
	if team != nil {
		aliases = strings.Join(team.Aliases, ",")
	}

	// Set default padding for sports (games run long)
	if req.PostPadding == 0 {
		req.PostPadding = 60 // 60 minutes extra for overtime
	}
	if req.PrePadding == 0 {
		req.PrePadding = 5 // 5 minutes before
	}

	// Set default pre/post game search windows
	preGameMinutes := req.PreGameMinutes
	if preGameMinutes <= 0 {
		preGameMinutes = 30
	}
	postGameMinutes := req.PostGameMinutes
	if postGameMinutes <= 0 {
		postGameMinutes = 60
	}

	teamPass := models.TeamPass{
		UserID:          userID.(uint),
		TeamName:        req.TeamName,
		TeamAliases:     aliases,
		League:          req.League,
		ChannelIDs:      req.ChannelIDs,
		PrePadding:      req.PrePadding,
		PostPadding:     req.PostPadding,
		RecordPreGame:   req.RecordPreGame,
		RecordPostGame:  req.RecordPostGame,
		PreGameMinutes:  preGameMinutes,
		PostGameMinutes: postGameMinutes,
		KeepCount:       req.KeepCount,
		Priority:        req.Priority,
		Enabled:         true,
	}

	if err := s.db.Create(&teamPass).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create team pass"})
		return
	}

	c.JSON(http.StatusCreated, teamPass)
}

// handleUpdateTeamPass updates an existing team pass
// PUT /api/teampass/:id
func (s *Server) handleUpdateTeamPass(c *gin.Context) {
	id := c.Param("id")
	userID, _ := c.Get("userID")

	var teamPass models.TeamPass
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&teamPass).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Team pass not found"})
		return
	}

	var req TeamPassRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Look up team to get aliases
	team := livetv.FindTeamByName(req.TeamName)
	if team != nil {
		teamPass.TeamAliases = strings.Join(team.Aliases, ",")
	}

	teamPass.TeamName = req.TeamName
	teamPass.League = req.League
	teamPass.ChannelIDs = req.ChannelIDs
	teamPass.PrePadding = req.PrePadding
	teamPass.PostPadding = req.PostPadding
	teamPass.RecordPreGame = req.RecordPreGame
	teamPass.RecordPostGame = req.RecordPostGame
	if req.PreGameMinutes > 0 {
		teamPass.PreGameMinutes = req.PreGameMinutes
	}
	if req.PostGameMinutes > 0 {
		teamPass.PostGameMinutes = req.PostGameMinutes
	}
	teamPass.KeepCount = req.KeepCount
	teamPass.Priority = req.Priority
	teamPass.Enabled = req.Enabled

	if err := s.db.Save(&teamPass).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update team pass"})
		return
	}

	c.JSON(http.StatusOK, teamPass)
}

// handleDeleteTeamPass deletes a team pass
// DELETE /api/teampass/:id
func (s *Server) handleDeleteTeamPass(c *gin.Context) {
	id := c.Param("id")
	userID, _ := c.Get("userID")

	var teamPass models.TeamPass
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&teamPass).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Team pass not found"})
		return
	}

	if err := s.db.Delete(&teamPass).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete team pass"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Team pass deleted"})
}

// handleGetTeamPassUpcoming returns upcoming games for a team pass
// GET /api/teampass/:id/upcoming
func (s *Server) handleGetTeamPassUpcoming(c *gin.Context) {
	id := c.Param("id")
	userID, _ := c.Get("userID")

	var teamPass models.TeamPass
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&teamPass).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Team pass not found"})
		return
	}

	upcomingGames := s.getUpcomingGamesForTeamPass(&teamPass)

	c.JSON(http.StatusOK, gin.H{
		"teamPass": teamPass,
		"games":    upcomingGames,
	})
}

// handleToggleTeamPass enables/disables a team pass
// PUT /api/teampass/:id/toggle
func (s *Server) handleToggleTeamPass(c *gin.Context) {
	id := c.Param("id")
	userID, _ := c.Get("userID")

	var teamPass models.TeamPass
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&teamPass).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Team pass not found"})
		return
	}

	teamPass.Enabled = !teamPass.Enabled

	if err := s.db.Save(&teamPass).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to toggle team pass"})
		return
	}

	c.JSON(http.StatusOK, teamPass)
}

// handleSearchSportsTeams searches for sports teams by name
// GET /api/teampass/teams/search
func (s *Server) handleSearchSportsTeams(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "query parameter 'q' is required"})
		return
	}

	teams := livetv.SearchTeams(query)

	type TeamResult struct {
		Name     string   `json:"name"`
		City     string   `json:"city"`
		Nickname string   `json:"nickname"`
		League   string   `json:"league"`
		Aliases  []string `json:"aliases"`
		LogoURL  string   `json:"logoUrl,omitempty"`
	}

	result := make([]TeamResult, len(teams))
	for i, t := range teams {
		result[i] = TeamResult{
			Name:     t.Name,
			City:     t.City,
			Nickname: t.Nickname,
			League:   t.League,
			Aliases:  t.Aliases,
			LogoURL:  t.GetLogoURL(),
		}
	}

	c.JSON(http.StatusOK, gin.H{"teams": result})
}

// handleGetSportsLeagues returns all available sports leagues
// GET /api/teampass/leagues
func (s *Server) handleGetSportsLeagues(c *gin.Context) {
	leagues := livetv.GetAllLeagues()
	c.JSON(http.StatusOK, gin.H{"leagues": leagues})
}

// handleGetLeagueTeams returns all teams for a specific league
// GET /api/teampass/leagues/:league/teams
func (s *Server) handleGetLeagueTeams(c *gin.Context) {
	league := c.Param("league")
	teams := livetv.GetTeamsByLeague(league)

	type TeamResult struct {
		Name     string   `json:"name"`
		City     string   `json:"city"`
		Nickname string   `json:"nickname"`
		Aliases  []string `json:"aliases"`
		LogoURL  string   `json:"logoUrl,omitempty"`
	}

	result := make([]TeamResult, len(teams))
	for i, t := range teams {
		result[i] = TeamResult{
			Name:     t.Name,
			City:     t.City,
			Nickname: t.Nickname,
			Aliases:  t.Aliases,
			LogoURL:  t.GetLogoURL(),
		}
	}

	c.JSON(http.StatusOK, gin.H{"teams": result, "league": league})
}

// handleProcessTeamPasses manually triggers team pass processing
// POST /api/teampass/process
func (s *Server) handleProcessTeamPasses(c *gin.Context) {
	if s.recorder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "DVR recorder not enabled"})
		return
	}

	// Process team passes
	scheduled := s.recorder.ProcessTeamPasses()

	c.JSON(http.StatusOK, gin.H{
		"message":   "Team passes processed",
		"scheduled": scheduled,
	})
}

// handleGetTeamPassStats returns statistics about team passes
// GET /api/teampass/stats
func (s *Server) handleGetTeamPassStats(c *gin.Context) {
	userID, _ := c.Get("userID")

	var totalPasses int64
	var activePasses int64
	s.db.Model(&models.TeamPass{}).Where("user_id = ?", userID).Count(&totalPasses)
	s.db.Model(&models.TeamPass{}).Where("user_id = ? AND enabled = ?", userID, true).Count(&activePasses)

	// Count upcoming games across all team passes
	now := time.Now()
	end := now.Add(7 * 24 * time.Hour)

	var upcomingGames int64
	var teamPasses []models.TeamPass
	s.db.Where("user_id = ? AND enabled = ?", userID, true).Find(&teamPasses)

	for _, tp := range teamPasses {
		var count int64
		searchTerms := buildTeamSearchTerms(tp.TeamName, tp.TeamAliases)
		query := s.db.Model(&models.Program{}).
			Where("is_sports = ? AND start >= ? AND start < ?", true, now, end)

		// Match team name or aliases in teams field only
		if len(searchTerms) > 0 {
			teamConditions := make([]string, len(searchTerms))
			teamArgs := make([]interface{}, len(searchTerms))
			for j, term := range searchTerms {
				teamConditions[j] = "teams LIKE ?"
				teamArgs[j] = "%" + term + "%"
			}
			query = query.Where(strings.Join(teamConditions, " OR "), teamArgs...)
		}

		if tp.League != "" {
			query = query.Where("league = ?", tp.League)
		}
		query.Count(&count)
		upcomingGames += count
	}

	// Count scheduled recordings from team passes
	var scheduledRecordings int64
	s.db.Model(&models.Recording{}).
		Where("status = ? AND series_rule_id IS NOT NULL", "scheduled").
		Count(&scheduledRecordings)

	c.JSON(http.StatusOK, gin.H{
		"totalPasses":         totalPasses,
		"activePasses":        activePasses,
		"upcomingGames":       upcomingGames,
		"scheduledRecordings": scheduledRecordings,
	})
}

// getUpcomingGamesForTeamPass finds upcoming games matching a team pass
func (s *Server) getUpcomingGamesForTeamPass(tp *models.TeamPass) []OnLaterItem {
	now := time.Now()
	end := now.Add(7 * 24 * time.Hour)

	var programs []models.Program

	// Build search terms from team name and aliases
	searchTerms := buildTeamSearchTerms(tp.TeamName, tp.TeamAliases)

	// Only search in teams field for actual games, not title (to avoid false positives)
	// Must be marked as sports content
	query := s.db.Where("is_sports = ? AND start >= ? AND start < ?", true, now, end)

	// Build OR conditions for each search term in teams field only
	if len(searchTerms) > 0 {
		teamConditions := make([]string, len(searchTerms))
		teamArgs := make([]interface{}, len(searchTerms))
		for i, term := range searchTerms {
			teamConditions[i] = "teams LIKE ?"
			teamArgs[i] = "%" + term + "%"
		}
		query = query.Where(strings.Join(teamConditions, " OR "), teamArgs...)
	}

	if tp.League != "" {
		query = query.Where("league = ?", tp.League)
	}

	// Filter by channels if specified
	if tp.ChannelIDs != "" {
		channelIDs := strings.Split(tp.ChannelIDs, ",")
		query = query.Where("channel_id IN ?", channelIDs)
	}

	query.Order("start ASC").Limit(50).Find(&programs)

	return s.enrichOnLaterItems(programs)
}

// buildTeamSearch creates a search term from team name and aliases (deprecated, use buildTeamSearchTerms)
func buildTeamSearch(teamName, aliases string) string {
	return teamName
}

// buildTeamSearchTerms returns all search terms for a team (name and aliases)
func buildTeamSearchTerms(teamName, aliases string) []string {
	terms := []string{teamName}

	// Add aliases if present
	if aliases != "" {
		for _, alias := range strings.Split(aliases, ",") {
			alias = strings.TrimSpace(alias)
			if alias != "" && len(alias) >= 3 { // Skip very short aliases to avoid false positives
				terms = append(terms, alias)
			}
		}
	}

	// Also add team nickname (last word of team name, e.g., "Bears" from "Chicago Bears")
	parts := strings.Fields(teamName)
	if len(parts) > 1 {
		nickname := parts[len(parts)-1]
		if len(nickname) >= 4 { // Only add if nickname is meaningful length
			terms = append(terms, nickname)
		}
	}

	return terms
}

// Helper to parse int from string with default
func parseIntWithDefault(s string, defaultVal int) int {
	if s == "" {
		return defaultVal
	}
	val, err := strconv.Atoi(s)
	if err != nil {
		return defaultVal
	}
	return val
}
