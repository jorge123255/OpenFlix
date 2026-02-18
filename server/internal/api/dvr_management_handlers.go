package api

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ DVR Management Endpoints (Passes, Schedule, Calendar) ============

// PassResponse represents a unified recording pass (series rule or team pass)
type PassResponse struct {
	ID          uint      `json:"id"`
	Type        string    `json:"type"` // "series" or "team"
	Name        string    `json:"name"`
	Thumb       string    `json:"thumb,omitempty"`
	Enabled     bool      `json:"enabled"`
	KeepCount   int       `json:"keepCount"`
	Priority    int       `json:"priority"`
	PrePadding  int       `json:"prePadding"`
	PostPadding int       `json:"postPadding"`
	JobCount    int       `json:"jobCount"` // number of scheduled/completed recordings
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`

	// Series-specific fields
	Keywords   string `json:"keywords,omitempty"`
	ChannelID  *uint  `json:"channelId,omitempty"`
	TimeSlot   string `json:"timeSlot,omitempty"`
	DaysOfWeek string `json:"daysOfWeek,omitempty"`

	// Team-specific fields
	TeamName string `json:"teamName,omitempty"`
	League   string `json:"league,omitempty"`
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
		// Count recordings for this rule
		var jobCount int64
		s.db.Model(&models.Recording{}).Where("series_rule_id = ? OR (title LIKE ? AND user_id = ?)", rule.ID, "%"+rule.Title+"%", userID).Count(&jobCount)

		pass := PassResponse{
			ID:          rule.ID,
			Type:        "series",
			Name:        rule.Title,
			Enabled:     rule.Enabled,
			KeepCount:   rule.KeepCount,
			Priority:    0,
			PrePadding:  rule.PrePadding,
			PostPadding: rule.PostPadding,
			JobCount:    int(jobCount),
			CreatedAt:   rule.CreatedAt,
			UpdatedAt:   rule.UpdatedAt,
			Keywords:    rule.Keywords,
			ChannelID:   rule.ChannelID,
			TimeSlot:    rule.TimeSlot,
			DaysOfWeek:  rule.DaysOfWeek,
		}
		passes = append(passes, pass)
	}

	for _, tp := range teamPasses {
		// Count recordings for this team pass
		var jobCount int64
		s.db.Model(&models.Recording{}).Where("title LIKE ? AND user_id = ?", "%"+tp.TeamName+"%", userID).Count(&jobCount)

		pass := PassResponse{
			ID:          tp.ID,
			Type:        "team",
			Name:        tp.TeamName + " (" + tp.League + ")",
			Enabled:     tp.Enabled,
			KeepCount:   tp.KeepCount,
			Priority:    tp.Priority,
			PrePadding:  tp.PrePadding,
			PostPadding: tp.PostPadding,
			JobCount:    int(jobCount),
			CreatedAt:   tp.CreatedAt,
			UpdatedAt:   tp.UpdatedAt,
			TeamName:    tp.TeamName,
			League:      tp.League,
		}
		passes = append(passes, pass)
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
		rule.Enabled = enabled
		if err := s.db.Save(&rule).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update series rule"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"id": rule.ID, "type": "series", "enabled": rule.Enabled})
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
		c.JSON(http.StatusOK, gin.H{"id": tp.ID, "type": "team", "enabled": tp.Enabled})
	} else {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid pass type"})
	}
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
