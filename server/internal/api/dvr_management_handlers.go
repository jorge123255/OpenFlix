package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ DVR Management Endpoints (Passes, Schedule, Calendar) ============

// rawJSON converts a stored condition string to json.RawMessage (nil if empty).
func rawJSON(s string) json.RawMessage {
	if s == "" {
		return nil
	}
	return json.RawMessage(s)
}

// PassResponse represents a unified recording pass (series rule or team pass).
// Field names are PascalCase to match Channels DVR's API format.
type PassResponse struct {
	ID    uint   `json:"ID"`
	Type  string `json:"Type"` // "series" or "team"
	Name  string `json:"Name"`
	Image string `json:"Image,omitempty"`

	Paused   bool `json:"Paused"`
	Rerecord bool `json:"Rerecord"`

	// Keep settings: "" = all, "unwatched" = unwatched/+N, "last" = last N
	KeepOnly string `json:"KeepOnly"`
	KeepNum  int    `json:"KeepNum"`

	// Padding in seconds
	PaddingStart int `json:"PaddingStart"`
	PaddingEnd   int `json:"PaddingEnd"`

	// Filter conditions — JSON objects {"FieldName": value}
	EQ json.RawMessage `json:"EQ,omitempty"`
	NE json.RawMessage `json:"NE,omitempty"`
	IN json.RawMessage `json:"IN,omitempty"`
	NI json.RawMessage `json:"NI,omitempty"`
	GT json.RawMessage `json:"GT,omitempty"`
	LT json.RawMessage `json:"LT,omitempty"`

	Limit   int `json:"Limit"`
	Priority int `json:"Priority"`
	NumJobs  int `json:"NumJobs"`

	UpdatedAt time.Time `json:"UpdatedAt"`

	// Team-specific fields
	TeamName string `json:"TeamName,omitempty"`
	League   string `json:"League,omitempty"`

	// Tracker info (populated when a TMDB tracker exists for this pass)
	Tracker *ShowTrackerInfo `json:"Tracker,omitempty"`
}

// getDVRPasses returns all series rules + team passes as unified "passes"
// GET /dvr/passes
func (s *Server) getDVRPasses(c *gin.Context) {
	userID := c.GetUint("userID")

	// Fetch series rules
	var seriesRules []models.SeriesRule
	if err := s.db.Where("user_id = ?", userID).Find(&seriesRules).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch series rules"})
		return
	}

	// Fetch team passes
	var teamPasses []models.TeamPass
	if err := s.db.Where("user_id = ?", userID).Find(&teamPasses).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch team passes"})
		return
	}

	// Build unified pass list
	passes := make([]PassResponse, 0, len(seriesRules)+len(teamPasses))

	for _, rule := range seriesRules {
		var numJobs int64
		s.db.Model(&models.Recording{}).Where("series_rule_id = ? AND user_id = ?", rule.ID, userID).Count(&numJobs)

		pass := PassResponse{
			ID:           rule.ID,
			Type:         "series",
			Name:         rule.Name,
			Image:        rule.Image,
			Paused:       rule.Paused,
			Rerecord:     rule.Rerecord,
			KeepOnly:     rule.KeepOnly,
			KeepNum:      rule.KeepNum,
			PaddingStart: rule.PaddingStart,
			PaddingEnd:   rule.PaddingEnd,
			EQ:           rawJSON(rule.EQ),
			NE:           rawJSON(rule.NE),
			IN:           rawJSON(rule.IN),
			NI:           rawJSON(rule.NI),
			GT:           rawJSON(rule.GT),
			LT:           rawJSON(rule.LT),
			Limit:        rule.Limit,
			Priority:     rule.Priority,
			NumJobs:      int(numJobs),
			UpdatedAt:    rule.UpdatedAt,
		}
		passes = append(passes, pass)
	}

	for _, tp := range teamPasses {
		var numJobs int64
		s.db.Model(&models.Recording{}).Where("title LIKE ? AND user_id = ?", "%"+tp.TeamName+"%", userID).Count(&numJobs)

		pass := PassResponse{
			ID:           tp.ID,
			Type:         "team",
			Name:         tp.TeamName + " (" + tp.League + ")",
			Paused:       !tp.Enabled,
			KeepNum:      tp.KeepCount,
			PaddingStart: tp.PrePadding * 60, // TeamPass stores minutes, convert to seconds
			PaddingEnd:   tp.PostPadding * 60,
			Priority:     tp.Priority,
			NumJobs:      int(numJobs),
			UpdatedAt:    tp.UpdatedAt,
			TeamName:     tp.TeamName,
			League:       tp.League,
		}
		passes = append(passes, pass)
	}

	// Attach tracker info: fetch all trackers for user, index by DVRRuleID
	var trackers []models.ShowTracker
	if err := s.db.Where("user_id = ? AND dvr_rule_id IS NOT NULL", userID).Find(&trackers).Error; err == nil {
		trackerByRule := make(map[uint]*models.ShowTracker, len(trackers))
		for i := range trackers {
			if trackers[i].DVRRuleID != nil {
				trackerByRule[*trackers[i].DVRRuleID] = &trackers[i]
			}
		}
		for i := range passes {
			if t, ok := trackerByRule[passes[i].ID]; ok {
				passes[i].Tracker = &ShowTrackerInfo{
					TMDBId:             t.TMDBId,
					NextSeasonNumber:   t.NextSeasonNumber,
					NextEpisodeAirDate: t.NextEpisodeAirDate,
					PosterURL:          t.PosterURL,
				}
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"passes": passes})
}

// pauseDVRPass pauses a pass (series rule or team pass)
// PUT /dvr/passes/:id/pause
func (s *Server) pauseDVRPass(c *gin.Context) {
	s.toggleDVRPass(c, false)
}

// resumeDVRPass resumes a pass (series rule or team pass)
// PUT /dvr/passes/:id/resume
func (s *Server) resumeDVRPass(c *gin.Context) {
	s.toggleDVRPass(c, true)
}

func (s *Server) toggleDVRPass(c *gin.Context, enabled bool) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid pass ID"})
		return
	}

	passType := c.Query("type")
	if passType == "" {
		passType = "series"
	}

	if passType == "series" {
		var rule models.SeriesRule
		if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&rule).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Series rule not found"})
			return
		}
		rule.Paused = !enabled
		if err := s.db.Save(&rule).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update series rule"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"ID": rule.ID, "Type": "series", "Paused": rule.Paused})
	} else if passType == "team" {
		var tp models.TeamPass
		if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&tp).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Team pass not found"})
			return
		}
		tp.Enabled = enabled
		if err := s.db.Save(&tp).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update team pass"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"ID": tp.ID, "Type": "team", "Paused": !tp.Enabled})
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid pass type"})
	}
}

// showSearchResult is the response shape for GET /dvr/show-search
type showSearchResult struct {
	TMDBId    *int             `json:"tmdbId,omitempty"`
	Title     string           `json:"title"`
	Overview  string           `json:"overview,omitempty"`
	Year      int              `json:"year,omitempty"`
	MediaType string           `json:"mediaType,omitempty"`
	PosterURL string           `json:"posterUrl,omitempty"`
	NextAiring *showNextAiring `json:"nextAiring,omitempty"`
}

type showNextAiring struct {
	Start       time.Time `json:"start"`
	ChannelName string    `json:"channelName"`
}

// normalizeQuery strips all non-alphanumeric characters and lowercases,
// so "chicagopd" matches "Chicago P.D." and "marvels" matches "The Marvel's".
func normalizeQuery(s string) string {
	return strings.Map(func(r rune) rune {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
			return r
		}
		return -1
	}, strings.ToLower(s))
}

// searchShowForPass handles GET /dvr/show-search?q=<query>&type=tv|movie
// Returns TMDB results enriched with next guide airing, or guide-only fallback.
func (s *Server) searchShowForPass(c *gin.Context) {
	q := strings.TrimSpace(c.Query("q"))
	if q == "" {
		c.JSON(http.StatusOK, []showSearchResult{})
		return
	}
	mediaType := c.Query("type")
	if mediaType == "" {
		mediaType = "tv"
	}

	// Normalized query: strip punctuation/spaces for fuzzy matching
	// e.g. "chicagopd" matches "Chicago P.D.", "greys" matches "Grey's Anatomy"
	normQ := normalizeQuery(q)

	now := time.Now().UTC()
	window14d := now.AddDate(0, 0, 14).Format("2006-01-02 15:04:05")
	nowStr := now.Format("2006-01-02 15:04:05")

	// Batch next-airing lookup: one query for all titles instead of N+1.
	batchNextAirings := func(titles []string) map[string]*showNextAiring {
		if len(titles) == 0 {
			return nil
		}
		type row struct {
			Title string
			Start string
			Name  string
		}
		lowerTitles := make([]string, len(titles))
		for i, t := range titles {
			lowerTitles[i] = strings.ToLower(t)
		}
		// Use a single query with IN clause bounded by a 14-day window so the
		// idx_programs_start index can prune the scan range first.
		var rows []row
		s.db.Raw(
			`SELECT p.title, MIN(datetime(p.start)) AS start, ch.name `+
				`FROM programs p `+
				`JOIN channels ch ON ch.channel_id = p.channel_id `+
				`WHERE p.start > ? AND p.start < ? AND LOWER(p.title) IN ? `+
				`GROUP BY LOWER(p.title)`,
			nowStr, window14d, lowerTitles,
		).Scan(&rows)
		m := make(map[string]*showNextAiring, len(rows))
		for _, r := range rows {
			t, _ := time.Parse("2006-01-02 15:04:05", r.Start)
			key := strings.ToLower(r.Title)
			m[key] = &showNextAiring{Start: t, ChannelName: r.Name}
		}
		return m
	}

	tmdbAgent := s.scanner.GetTMDBAgent()
	if tmdbAgent != nil && tmdbAgent.IsConfigured() {
		results := make([]showSearchResult, 0, 10)

		if mediaType == "movie" {
			movies, err := tmdbAgent.SearchMovieMulti(q, 0)
			if err == nil {
				titles := make([]string, len(movies))
				for i, m := range movies {
					titles[i] = m.Title
				}
				airings := batchNextAirings(titles)
				for _, m := range movies {
					year := 0
					if len(m.ReleaseDate) >= 4 {
						fmt.Sscanf(m.ReleaseDate[:4], "%d", &year)
					}
					posterURL := ""
					if m.PosterPath != "" {
						posterURL = "https://image.tmdb.org/t/p/w500" + m.PosterPath
					}
					id := m.ID
					results = append(results, showSearchResult{
						TMDBId:     &id,
						Title:      m.Title,
						Overview:   m.Overview,
						Year:       year,
						MediaType:  "movie",
						PosterURL:  posterURL,
						NextAiring: airings[strings.ToLower(m.Title)],
					})
				}
			}
		} else {
			shows, err := tmdbAgent.SearchTVMulti(q, 0)
			if err == nil {
				titles := make([]string, len(shows))
				for i, s := range shows {
					titles[i] = s.Name
				}
				airings := batchNextAirings(titles)
				for _, show := range shows {
					year := 0
					if len(show.FirstAirDate) >= 4 {
						fmt.Sscanf(show.FirstAirDate[:4], "%d", &year)
					}
					posterURL := ""
					if show.PosterPath != "" {
						posterURL = "https://image.tmdb.org/t/p/w500" + show.PosterPath
					}
					id := show.ID
					results = append(results, showSearchResult{
						TMDBId:     &id,
						Title:      show.Name,
						Overview:   show.Overview,
						Year:       year,
						MediaType:  "tv",
						PosterURL:  posterURL,
						NextAiring: airings[strings.ToLower(show.Name)],
					})
				}
			}
		}

		c.JSON(http.StatusOK, results)
		return
	}

	// Fallback: guide-only search (no TMDB key).
	// Bound by a 14-day window so the idx_programs_start index limits the scan,
	// then filter by title. Avoids full-table scan on the programs table.
	type guideRow struct {
		Title       string
		Description string
		Icon        string
		Start       string
		ChannelName string
	}
	var rows []guideRow
	s.db.Raw(
		`SELECT p.title, p.description, p.icon, datetime(MIN(p.start)) AS start, ch.name AS channel_name `+
			`FROM programs p `+
			`JOIN channels ch ON ch.channel_id = p.channel_id `+
			`WHERE p.start > ? AND p.start < ? AND LOWER(p.title) LIKE ? `+
			`GROUP BY LOWER(p.title) `+
			`ORDER BY start ASC `+
			`LIMIT 20`,
		nowStr, window14d, "%"+strings.ToLower(q)+"%",
	).Scan(&rows)

	// Also try normalized query if too few results
	if len(rows) < 5 && normQ != strings.ToLower(q) {
		var normRows []guideRow
		normExpr := `REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(p.title),' ',''),'.',''),',',''),'-',''),"'",''),':','')`
		s.db.Raw(
			`SELECT p.title, p.description, p.icon, datetime(MIN(p.start)) AS start, ch.name AS channel_name `+
				`FROM programs p `+
				`JOIN channels ch ON ch.channel_id = p.channel_id `+
				`WHERE p.start > ? AND p.start < ? AND `+normExpr+` LIKE ? `+
				`GROUP BY LOWER(p.title) `+
				`ORDER BY start ASC `+
				`LIMIT 20`,
			nowStr, window14d, "%"+normQ+"%",
		).Scan(&normRows)
		// Merge, dedup by title
		seen := make(map[string]bool, len(rows))
		for _, r := range rows {
			seen[strings.ToLower(r.Title)] = true
		}
		for _, r := range normRows {
			if !seen[strings.ToLower(r.Title)] {
				rows = append(rows, r)
			}
		}
	}

	results := make([]showSearchResult, 0, len(rows))
	for _, r := range rows {
		rCopy := r
		res := showSearchResult{
			Title:     rCopy.Title,
			Overview:  rCopy.Description,
			PosterURL: rCopy.Icon,
		}
		if rCopy.ChannelName != "" {
			t, _ := time.Parse("2006-01-02 15:04:05", rCopy.Start)
			res.NextAiring = &showNextAiring{Start: t, ChannelName: rCopy.ChannelName}
		}
		results = append(results, res)
	}
	c.JSON(http.StatusOK, results)
}

// passRequest is the shared request body for create/update pass endpoints.
// Field names are PascalCase to match Channels DVR's API format.
type passRequest struct {
	Type  string `json:"Type"` // "series" or "team"
	Name  string `json:"Name"`
	Image string `json:"Image"`

	Paused   bool `json:"Paused"`
	Rerecord bool `json:"Rerecord"`

	KeepOnly string `json:"KeepOnly"` // "" = all, "unwatched", "last"
	KeepNum  int    `json:"KeepNum"`

	PaddingStart int `json:"PaddingStart"` // seconds
	PaddingEnd   int `json:"PaddingEnd"`   // seconds

	EQ json.RawMessage `json:"EQ"`
	NE json.RawMessage `json:"NE"`
	IN json.RawMessage `json:"IN"`
	NI json.RawMessage `json:"NI"`
	GT json.RawMessage `json:"GT"`
	LT json.RawMessage `json:"LT"`

	Limit    int `json:"Limit"`
	Priority int `json:"Priority"`

	// TMDB tracking fields (set when creating from TMDB search)
	TMDBId    *int   `json:"TmdbId,omitempty"`
	MediaType string `json:"MediaType,omitempty"`

	// Team-specific
	TeamName string `json:"TeamName"`
	League   string `json:"League"`
}

// createDVRPass creates a new series rule or team pass
// POST /dvr/passes
func (s *Server) createDVRPass(c *gin.Context) {
	userID := c.GetUint("userID")

	var req passRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	if req.Type == "team" {
		tp := models.TeamPass{
			UserID:   userID,
			TeamName: req.TeamName,
			League:   req.League,
			Enabled:  true,
		}
		if err := s.db.Create(&tp).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create team pass"})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"ID": tp.ID, "Type": "team"})
		return
	}

	// Default: series rule
	rule := models.SeriesRule{
		UserID:       userID,
		Name:         req.Name,
		Image:        req.Image,
		Paused:       req.Paused,
		Rerecord:     req.Rerecord,
		KeepOnly:     req.KeepOnly,
		KeepNum:      req.KeepNum,
		PaddingStart: req.PaddingStart,
		PaddingEnd:   req.PaddingEnd,
		EQ:           string(req.EQ),
		NE:           string(req.NE),
		IN:           string(req.IN),
		NI:           string(req.NI),
		GT:           string(req.GT),
		LT:           string(req.LT),
		Limit:        req.Limit,
		Priority:     req.Priority,
	}
	if err := s.db.Create(&rule).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create series rule"})
		return
	}

	// If a TMDB ID was provided, upsert a show tracker so we can notify on new seasons
	if req.TMDBId != nil && *req.TMDBId > 0 {
		ruleID := rule.ID
		mediaType := req.MediaType
		if mediaType == "" {
			mediaType = "tv"
		}
		tracker := models.ShowTracker{
			UserID:    userID,
			DVRRuleID: &ruleID,
			TMDBId:    *req.TMDBId,
			MediaType: mediaType,
			ShowTitle: req.Name,
			PosterURL: req.Image,
		}
		// Use upsert: if tracker for (user_id, tmdb_id) already exists, update it
		s.db.Where(models.ShowTracker{UserID: userID, TMDBId: *req.TMDBId}).
			Assign(models.ShowTracker{DVRRuleID: &ruleID, ShowTitle: req.Name, PosterURL: req.Image}).
			FirstOrCreate(&tracker)
	}

	c.JSON(http.StatusCreated, gin.H{"ID": rule.ID, "Type": "series"})
}

// updateDVRPass updates an existing series rule or team pass
// PUT /dvr/passes/:id
func (s *Server) updateDVRPass(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid pass ID"})
		return
	}

	var req passRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	passType := req.Type
	if passType == "" {
		passType = c.Query("type")
	}
	if passType == "" {
		passType = "series"
	}

	if passType == "team" {
		var tp models.TeamPass
		if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&tp).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Team pass not found"})
			return
		}
		if req.TeamName != "" {
			tp.TeamName = req.TeamName
		}
		if req.League != "" {
			tp.League = req.League
		}
		if err := s.db.Save(&tp).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update team pass"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"ID": tp.ID, "Type": "team"})
		return
	}

	var rule models.SeriesRule
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&rule).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Series rule not found"})
		return
	}
	if req.Name != "" {
		rule.Name = req.Name
	}
	rule.Image = req.Image
	rule.Paused = req.Paused
	rule.Rerecord = req.Rerecord
	rule.KeepOnly = req.KeepOnly
	rule.KeepNum = req.KeepNum
	rule.PaddingStart = req.PaddingStart
	rule.PaddingEnd = req.PaddingEnd
	rule.EQ = string(req.EQ)
	rule.NE = string(req.NE)
	rule.IN = string(req.IN)
	rule.NI = string(req.NI)
	rule.GT = string(req.GT)
	rule.LT = string(req.LT)
	rule.Limit = req.Limit
	rule.Priority = req.Priority
	if err := s.db.Save(&rule).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update series rule"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ID": rule.ID, "Type": "series"})
}

// deleteDVRPass deletes a series rule or team pass
// DELETE /dvr/passes/:id
func (s *Server) deleteDVRPass(c *gin.Context) {
	userID := c.GetUint("userID")
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid pass ID"})
		return
	}
	passType := c.Query("type")
	if passType == "" {
		passType = "series"
	}
	if passType == "team" {
		if err := s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.TeamPass{}).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete team pass"})
			return
		}
	} else {
		if err := s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.SeriesRule{}).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete series rule"})
			return
		}
	}
	c.JSON(http.StatusOK, gin.H{"deleted": true})
}

// ScheduleItem represents a scheduled recording job for the schedule view
type ScheduleItem struct {
	ID          uint      `json:"id"`
	Title       string    `json:"title"`
	Subtitle    string    `json:"subtitle,omitempty"`
	ChannelName string    `json:"channelName,omitempty"`
	ChannelLogo string    `json:"channelLogo,omitempty"`
	StartTime   time.Time `json:"startTime"`
	EndTime     time.Time `json:"endTime"`
	Status      string    `json:"status"` // scheduled, recording, conflict
	Priority    int       `json:"priority"`
	Category    string    `json:"category,omitempty"`
	EpisodeNum  string    `json:"episodeNum,omitempty"`
	Thumb       string    `json:"thumb,omitempty"`
	Art         string    `json:"art,omitempty"`
	IsMovie     bool      `json:"isMovie"`
	Day         string    `json:"day"` // date string for grouping (YYYY-MM-DD)
}

// getDVRSchedule returns upcoming scheduled recording jobs sorted by start time, grouped by day
// GET /dvr/schedule
func (s *Server) getDVRSchedule(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")

	now := time.Now()

	var recordings []models.Recording
	query := s.db.Where("status IN ? AND end_time >= ?", []string{"scheduled", "recording"}, now)
	if !isAdmin {
		query = query.Where("user_id IN ?", []uint{userID, 0})
	}
	if err := query.Order("start_time ASC").Find(&recordings).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch schedule"})
		return
	}

	// Detect conflicts (overlapping recordings)
	conflictIDs := make(map[uint]bool)
	for i := 0; i < len(recordings); i++ {
		for j := i + 1; j < len(recordings); j++ {
			if recordings[i].StartTime.Before(recordings[j].EndTime) && recordings[j].StartTime.Before(recordings[i].EndTime) {
				conflictIDs[recordings[i].ID] = true
				conflictIDs[recordings[j].ID] = true
			}
		}
	}

	items := make([]ScheduleItem, 0, len(recordings))
	for _, rec := range recordings {
		status := rec.Status
		if conflictIDs[rec.ID] && status == "scheduled" {
			status = "conflict"
		}

		items = append(items, ScheduleItem{
			ID:          rec.ID,
			Title:       rec.Title,
			Subtitle:    rec.Subtitle,
			ChannelName: rec.ChannelName,
			ChannelLogo: rec.ChannelLogo,
			StartTime:   rec.StartTime,
			EndTime:     rec.EndTime,
			Status:      status,
			Priority:    rec.Priority,
			Category:    rec.Category,
			EpisodeNum:  rec.EpisodeNum,
			Thumb:       rec.Thumb,
			Art:         rec.Art,
			IsMovie:     rec.IsMovie,
			Day:         rec.StartTime.Format("2006-01-02"),
		})
	}

	c.JSON(http.StatusOK, gin.H{"schedule": items, "totalCount": len(items)})
}

// CalendarItem represents a recording for the calendar view
type CalendarItem struct {
	ID          uint      `json:"id"`
	Title       string    `json:"title"`
	ChannelName string    `json:"channelName,omitempty"`
	StartTime   time.Time `json:"startTime"`
	EndTime     time.Time `json:"endTime"`
	Status      string    `json:"status"` // scheduled, recording, completed
	Day         string    `json:"day"`    // YYYY-MM-DD
}

// getDVRCalendar returns a week of scheduled recordings for the calendar view
// GET /dvr/calendar?date=2026-02-15
func (s *Server) getDVRCalendar(c *gin.Context) {
	userID := c.GetUint("userID")
	isAdmin := c.GetBool("isAdmin")

	// Parse the anchor date (defaults to today)
	dateStr := c.Query("date")
	var anchorDate time.Time
	if dateStr != "" {
		var err error
		anchorDate, err = time.Parse("2006-01-02", dateStr)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format, use YYYY-MM-DD"})
			return
		}
	} else {
		anchorDate = time.Now()
	}

	// Calculate the week range (Sunday to Saturday containing the anchor date)
	weekday := int(anchorDate.Weekday())
	weekStart := anchorDate.AddDate(0, 0, -weekday)
	weekStart = time.Date(weekStart.Year(), weekStart.Month(), weekStart.Day(), 0, 0, 0, 0, anchorDate.Location())
	weekEnd := weekStart.AddDate(0, 0, 7)

	// Fetch recordings in range
	var recordings []models.Recording
	query := s.db.Where("start_time < ? AND end_time > ? AND status IN ?", weekEnd, weekStart, []string{"scheduled", "recording", "completed"})
	if !isAdmin {
		query = query.Where("user_id IN ?", []uint{userID, 0})
	}
	if err := query.Order("start_time ASC").Find(&recordings).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch calendar data"})
		return
	}

	items := make([]CalendarItem, 0, len(recordings))
	for _, rec := range recordings {
		items = append(items, CalendarItem{
			ID:          rec.ID,
			Title:       rec.Title,
			ChannelName: rec.ChannelName,
			StartTime:   rec.StartTime,
			EndTime:     rec.EndTime,
			Status:      rec.Status,
			Day:         rec.StartTime.Format("2006-01-02"),
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"items":     items,
		"weekStart": weekStart.Format("2006-01-02"),
		"weekEnd":   weekEnd.Format("2006-01-02"),
	})
}

// ShowTrackerInfo is returned with pass listings when tracker data is available
type ShowTrackerInfo struct {
	TMDBId             int    `json:"tmdbId,omitempty"`
	PosterURL          string `json:"posterUrl,omitempty"`
	NextSeasonNumber   int    `json:"nextSeasonNumber,omitempty"`
	NextEpisodeAirDate string `json:"nextEpisodeAirDate,omitempty"`
}

// getShowTrackers returns all tracked shows for the current user
// GET /dvr/trackers
func (s *Server) getShowTrackers(c *gin.Context) {
	userID := c.GetUint("userID")

	var trackers []models.ShowTracker
	if err := s.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&trackers).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch trackers"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"trackers": trackers})
}

// deleteShowTracker removes a show tracker by TMDB ID
// DELETE /dvr/trackers/:tmdbId
func (s *Server) deleteShowTracker(c *gin.Context) {
	userID := c.GetUint("userID")
	tmdbId, err := strconv.Atoi(c.Param("tmdbId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid TMDB ID"})
		return
	}

	if err := s.db.Where("user_id = ? AND tmdb_id = ?", userID, tmdbId).Delete(&models.ShowTracker{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete tracker"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"deleted": true})
}

// PassTestAiring is one matching guide airing returned by testDVRPass.
type PassTestAiring struct {
	ProgramID   uint      `json:"programId"`
	Title       string    `json:"title"`
	Subtitle    string    `json:"subtitle,omitempty"`
	ChannelID   string    `json:"channelId"`
	ChannelName string    `json:"channelName"`
	ChannelLogo string    `json:"channelLogo,omitempty"`
	Start       time.Time `json:"start"`
	End         time.Time `json:"end"`
	IsNew       bool      `json:"isNew"`
	IsSports    bool      `json:"isSports"`
	IsMovie     bool      `json:"isMovie"`
	EpisodeNum  string    `json:"episodeNum,omitempty"`
	Category    string    `json:"category,omitempty"`
}

// testDVRPass returns upcoming guide programs that match the provided pass conditions.
// POST /dvr/passes/test
func (s *Server) testDVRPass(c *gin.Context) {
	var req passRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	// Parse each condition map from JSON
	condMaps := map[string]map[string]json.RawMessage{}
	for op, raw := range map[string]json.RawMessage{
		"EQ": req.EQ, "NE": req.NE, "IN": req.IN, "NI": req.NI, "GT": req.GT, "LT": req.LT,
	} {
		if len(raw) == 0 {
			continue
		}
		var m map[string]json.RawMessage
		if err := json.Unmarshal(raw, &m); err == nil && len(m) > 0 {
			condMaps[op] = m
		}
	}

	if len(condMaps) == 0 {
		c.JSON(http.StatusOK, gin.H{"airings": []PassTestAiring{}, "count": 0})
		return
	}

	// Query programs in the next 14 days
	now := time.Now()
	horizon := now.Add(14 * 24 * time.Hour)
	var programs []models.Program
	if err := s.db.Where("start >= ? AND start <= ?", now, horizon).
		Order("start ASC").
		Limit(5000).
		Find(&programs).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to query guide"})
		return
	}

	// Build a channel lookup map for channel name + logo
	var channels []models.Channel
	s.db.Find(&channels)
	chanMap := make(map[string]models.Channel, len(channels))
	for _, ch := range channels {
		chanMap[ch.ChannelID] = ch
	}

	// Evaluate conditions against each program
	var matches []PassTestAiring
	for i := range programs {
		p := &programs[i]
		if matchesConditions(p, condMaps) {
			airing := PassTestAiring{
				ProgramID:  p.ID,
				Title:      p.Title,
				Subtitle:   p.Subtitle,
				ChannelID:  p.ChannelID,
				Start:      p.Start,
				End:        p.End,
				IsNew:      p.IsNew,
				IsSports:   p.IsSports,
				IsMovie:    p.IsMovie,
				EpisodeNum: p.EpisodeNum,
				Category:   p.Category,
			}
			if ch, ok := chanMap[p.ChannelID]; ok {
				airing.ChannelName = ch.Name
				airing.ChannelLogo = ch.Logo
			}
			matches = append(matches, airing)
			if len(matches) >= 100 {
				break
			}
		}
	}

	if matches == nil {
		matches = []PassTestAiring{}
	}
	c.JSON(http.StatusOK, gin.H{"airings": matches, "count": len(matches)})
}

// matchesConditions checks if a program satisfies all pass condition maps (AND logic).
// condMaps keys are op names ("EQ", "NE", "IN", "NI", "GT", "LT");
// values are maps of fieldName → raw JSON value.
func matchesConditions(p *models.Program, condMaps map[string]map[string]json.RawMessage) bool {
	for op, fields := range condMaps {
		for field, rawVal := range fields {
			// Decode the JSON value to a plain string (handles both "string" and number/bool)
			var condValue string
			// Try string first
			var s string
			if err := json.Unmarshal(rawVal, &s); err == nil {
				condValue = s
			} else {
				// Fall back to raw (number / bool)
				condValue = strings.Trim(string(rawVal), "\"")
			}
			fieldValue := passTestFieldValue(field, p)
			if !passTestOp(op, fieldValue, condValue, field) {
				return false
			}
		}
	}
	return true
}

// passTestFieldValue extracts the string value of a named field from a Program.
// Mirrors dvr/query.go getFieldValue but is local to avoid a cross-package import cycle.
func passTestFieldValue(field string, p *models.Program) string {
	switch strings.ToLower(field) {
	case "title":
		return p.Title
	case "subtitle", "episodetitle":
		return p.Subtitle
	case "channel":
		return p.ChannelID
	case "category", "genre", "categories", "genres":
		return p.Category
	case "isnew", "tags":
		// Channels DVR passes encode "New" as EQ.Tags="New"
		if strings.ToLower(field) == "tags" {
			if p.IsNew {
				return "New"
			}
			return ""
		}
		return fmt.Sprintf("%v", p.IsNew)
	case "issports":
		return fmt.Sprintf("%v", p.IsSports)
	case "ismovie":
		return fmt.Sprintf("%v", p.IsMovie)
	case "iskids":
		return fmt.Sprintf("%v", p.IsKids)
	case "isnews":
		return fmt.Sprintf("%v", p.IsNews)
	case "ispremiere":
		return fmt.Sprintf("%v", p.IsPremiere)
	case "islive":
		return fmt.Sprintf("%v", p.IsLive)
	case "isfinale":
		return fmt.Sprintf("%v", p.IsFinale)
	case "seriesid":
		return p.SeriesID
	case "episodenum":
		return p.EpisodeNum
	case "episodenumber":
		return fmt.Sprintf("%d", p.EpisodeNumber)
	case "seasonnumber":
		return fmt.Sprintf("%d", p.SeasonNumber)
	case "contentrating", "rating":
		return p.Rating
	case "description", "summary":
		return p.Description
	case "teams", "team":
		return p.Teams
	case "league":
		return p.League
	default:
		return ""
	}
}

// passTestOp applies a comparison operator for pass condition evaluation.
func passTestOp(op, fieldValue, condValue, field string) bool {
	op = strings.ToUpper(op)
	switch op {
	case "EQ":
		return strings.EqualFold(fieldValue, condValue)
	case "NE":
		return !strings.EqualFold(fieldValue, condValue)
	case "IN":
		// condValue may be a comma-separated list; check if fieldValue is contained
		parts := strings.Split(condValue, ",")
		for _, part := range parts {
			if strings.EqualFold(strings.TrimSpace(part), fieldValue) {
				return true
			}
			// substring match for team names
			if strings.ToLower(field) == "team" && strings.Contains(strings.ToLower(fieldValue), strings.ToLower(strings.TrimSpace(part))) {
				return true
			}
		}
		return false
	case "NI":
		parts := strings.Split(condValue, ",")
		for _, part := range parts {
			if strings.EqualFold(strings.TrimSpace(part), fieldValue) {
				return false
			}
		}
		return true
	case "GT":
		fv, err1 := strconv.ParseFloat(fieldValue, 64)
		cv, err2 := strconv.ParseFloat(condValue, 64)
		if err1 != nil || err2 != nil {
			return false
		}
		return fv > cv
	case "LT":
		fv, err1 := strconv.ParseFloat(fieldValue, 64)
		cv, err2 := strconv.ParseFloat(condValue, 64)
		if err1 != nil || err2 != nil {
			return false
		}
		return fv < cv
	default:
		return false
	}
}
