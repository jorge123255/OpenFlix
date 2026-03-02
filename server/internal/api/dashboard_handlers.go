package api

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// getDashboardData returns aggregated data for the dashboard home page
func (s *Server) getDashboardData(c *gin.Context) {
	userID := c.GetUint("userID")

	// ---- Up Next (items with progress, not completed) ----
	var histories []models.WatchHistory
	s.db.Where("user_id = ? AND completed = ? AND view_offset > 0", userID, false).
		Order("last_viewed_at DESC").
		Limit(20).
		Find(&histories)

	type UpNextItem struct {
		ID               uint   `json:"id"`
		Title            string `json:"title"`
		Type             string `json:"type"`
		Thumb            string `json:"thumb"`
		Art              string `json:"art"`
		Year             int    `json:"year,omitempty"`
		Duration         int64  `json:"duration,omitempty"`
		ViewOffset       int64  `json:"viewOffset"`
		GrandparentTitle string `json:"grandparentTitle,omitempty"`
		ParentIndex      int    `json:"parentIndex,omitempty"`
		Index            int    `json:"index,omitempty"`
		GrandparentThumb string `json:"grandparentThumb,omitempty"`
		ParentThumb      string `json:"parentThumb,omitempty"`
		Summary          string `json:"summary,omitempty"`
	}

	upNextItems := make([]UpNextItem, 0)
	if len(histories) > 0 {
		itemIDs := make([]uint, len(histories))
		historyMap := make(map[uint]models.WatchHistory)
		for i, h := range histories {
			itemIDs[i] = h.MediaItemID
			historyMap[h.MediaItemID] = h
		}

		var items []models.MediaItem
		s.db.Where("id IN ?", itemIDs).Find(&items)

		for _, item := range items {
			h, ok := historyMap[item.ID]
			if !ok {
				continue
			}
			upNextItems = append(upNextItems, UpNextItem{
				ID:               item.ID,
				Title:            item.Title,
				Type:             item.Type,
				Thumb:            item.Thumb,
				Art:              item.Art,
				Year:             item.Year,
				Duration:         item.Duration,
				ViewOffset:       h.ViewOffset,
				GrandparentTitle: item.GrandparentTitle,
				ParentIndex:      item.ParentIndex,
				Index:            item.Index,
				GrandparentThumb: item.GrandparentThumb,
				ParentThumb:      item.ParentThumb,
				Summary:          item.Summary,
			})
		}
	}

	// ---- Recently Updated Shows ----
	type RecentShow struct {
		ID         uint      `json:"id"`
		Title      string    `json:"title"`
		Thumb      string    `json:"thumb"`
		Art        string    `json:"art"`
		Year       int       `json:"year,omitempty"`
		ChildCount int       `json:"childCount,omitempty"`
		LeafCount  int       `json:"leafCount,omitempty"`
		UpdatedAt  time.Time `json:"updatedAt"`
		Summary    string    `json:"summary,omitempty"`
	}

	var shows []models.MediaItem
	s.db.Where("type = ?", "show").
		Order("updated_at DESC").
		Limit(20).
		Find(&shows)

	recentShows := make([]RecentShow, 0, len(shows))
	for _, show := range shows {
		recentShows = append(recentShows, RecentShow{
			ID:         show.ID,
			Title:      show.Title,
			Thumb:      show.Thumb,
			Art:        show.Art,
			Year:       show.Year,
			ChildCount: show.ChildCount,
			LeafCount:  show.LeafCount,
			UpdatedAt:  show.UpdatedAt,
			Summary:    show.Summary,
		})
	}

	// ---- Recently Added Movies ----
	type RecentMovie struct {
		ID      uint    `json:"id"`
		Title   string  `json:"title"`
		Thumb   string  `json:"thumb"`
		Art     string  `json:"art"`
		Year    int     `json:"year,omitempty"`
		Summary string  `json:"summary,omitempty"`
		Rating  float64 `json:"rating,omitempty"`
		Studio  string  `json:"studio,omitempty"`
	}

	var movies []models.MediaItem
	s.db.Where("type = ?", "movie").
		Order("added_at DESC").
		Limit(20).
		Find(&movies)

	recentMovies := make([]RecentMovie, 0, len(movies))
	for _, movie := range movies {
		recentMovies = append(recentMovies, RecentMovie{
			ID:      movie.ID,
			Title:   movie.Title,
			Thumb:   movie.Thumb,
			Art:     movie.Art,
			Year:    movie.Year,
			Summary: movie.Summary,
			Rating:  movie.Rating,
			Studio:  movie.Studio,
		})
	}

	// ---- Recently Recorded (completed DVR recordings) ----
	type RecentRecording struct {
		ID          uint   `json:"id"`
		Title       string `json:"title"`
		Thumb       string `json:"thumb"`
		Art         string `json:"art"`
		ChannelName string `json:"channelName,omitempty"`
		Duration    int    `json:"duration,omitempty"`
		Year        int    `json:"year,omitempty"`
		IsMovie     bool   `json:"isMovie,omitempty"`
	}

	var recordings []models.Recording
	s.db.Where("status = ?", "completed").
		Order("updated_at DESC").
		Limit(20).
		Find(&recordings)

	recentRecordings := make([]RecentRecording, 0, len(recordings))
	for _, rec := range recordings {
		dur := 0
		if rec.Duration != nil {
			dur = *rec.Duration
		}
		yr := 0
		if rec.Year != nil {
			yr = *rec.Year
		}
		recentRecordings = append(recentRecordings, RecentRecording{
			ID:          rec.ID,
			Title:       rec.Title,
			Thumb:       rec.Thumb,
			Art:         rec.Art,
			ChannelName: rec.ChannelName,
			Duration:    dur,
			Year:        yr,
			IsMovie:     rec.IsMovie,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"upNext":           upNextItems,
		"recentShows":      recentShows,
		"recentMovies":     recentMovies,
		"recentRecordings": recentRecordings,
	})
}
