package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// AdminMediaItem represents a media item for admin management
type AdminMediaItem struct {
	ID            uint    `json:"id"`
	UUID          string  `json:"uuid"`
	Type          string  `json:"type"`
	Title         string  `json:"title"`
	SortTitle     string  `json:"sort_title"`
	OriginalTitle string  `json:"original_title,omitempty"`
	Year          int     `json:"year,omitempty"`
	Thumb         string  `json:"thumb,omitempty"`
	Art           string  `json:"art,omitempty"`
	Summary       string  `json:"summary,omitempty"`
	Rating        float64 `json:"rating,omitempty"`
	ContentRating string  `json:"content_rating,omitempty"`
	Studio        string  `json:"studio,omitempty"`
	Duration      int64   `json:"duration,omitempty"`
	AddedAt       string  `json:"added_at"`
	UpdatedAt     string  `json:"updated_at"`
	LibraryID     uint    `json:"library_id"`
	LibraryName   string  `json:"library_name,omitempty"`
	TMDBID        string  `json:"tmdb_id,omitempty"`
	ChildCount    int     `json:"child_count,omitempty"`
}

// adminGetMedia returns a paginated list of media items for admin management
func (s *Server) adminGetMedia(c *gin.Context) {
	search := c.Query("search")
	mediaType := c.Query("type")
	libraryIDStr := c.Query("libraryId")
	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "50")

	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 50
	}

	// Build query
	query := s.db.Model(&models.MediaItem{}).
		Where("type IN ?", []string{"movie", "show"}).
		Order("added_at DESC")

	// Apply filters
	if search != "" {
		query = query.Where("title LIKE ? OR original_title LIKE ?", "%"+search+"%", "%"+search+"%")
	}
	if mediaType != "" {
		query = query.Where("type = ?", mediaType)
	}
	if libraryIDStr != "" {
		libraryID, _ := strconv.ParseUint(libraryIDStr, 10, 64)
		if libraryID > 0 {
			query = query.Where("library_id = ?", libraryID)
		}
	}

	// Get total count
	var total int64
	query.Count(&total)

	// Get paginated results
	var items []models.MediaItem
	offset := (page - 1) * pageSize
	query.Offset(offset).Limit(pageSize).Find(&items)

	// Get library names
	libraryNames := make(map[uint]string)
	var libraries []models.Library
	s.db.Find(&libraries)
	for _, lib := range libraries {
		libraryNames[lib.ID] = lib.Title
	}

	// Convert to response format
	responseItems := make([]AdminMediaItem, len(items))
	for i, item := range items {
		responseItems[i] = AdminMediaItem{
			ID:            item.ID,
			UUID:          item.UUID,
			Type:          item.Type,
			Title:         item.Title,
			SortTitle:     item.SortTitle,
			OriginalTitle: item.OriginalTitle,
			Year:          item.Year,
			Thumb:         item.Thumb,
			Art:           item.Art,
			Summary:       item.Summary,
			Rating:        item.Rating,
			ContentRating: item.ContentRating,
			Studio:        item.Studio,
			Duration:      item.Duration,
			AddedAt:       item.AddedAt.Format("2006-01-02T15:04:05Z"),
			UpdatedAt:     item.UpdatedAt.Format("2006-01-02T15:04:05Z"),
			LibraryID:     item.LibraryID,
			LibraryName:   libraryNames[item.LibraryID],
			TMDBID:        item.UUID, // Use UUID as identifier
			ChildCount:    item.ChildCount,
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"items":     responseItems,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// adminUpdateMedia updates a media item's metadata
func (s *Server) adminUpdateMedia(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var item models.MediaItem
	if err := s.db.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	var updates struct {
		Title         *string `json:"title"`
		SortTitle     *string `json:"sort_title"`
		Year          *int    `json:"year"`
		Summary       *string `json:"summary"`
		Studio        *string `json:"studio"`
		ContentRating *string `json:"content_rating"`
	}

	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Apply updates
	updateMap := make(map[string]interface{})
	if updates.Title != nil {
		updateMap["title"] = *updates.Title
	}
	if updates.SortTitle != nil {
		updateMap["sort_title"] = *updates.SortTitle
	}
	if updates.Year != nil {
		updateMap["year"] = *updates.Year
	}
	if updates.Summary != nil {
		updateMap["summary"] = *updates.Summary
	}
	if updates.Studio != nil {
		updateMap["studio"] = *updates.Studio
	}
	if updates.ContentRating != nil {
		updateMap["content_rating"] = *updates.ContentRating
	}

	if len(updateMap) > 0 {
		if err := s.db.Model(&item).Updates(updateMap).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update media item"})
			return
		}
	}

	// Reload and return updated item
	s.db.First(&item, id)
	c.JSON(http.StatusOK, AdminMediaItem{
		ID:            item.ID,
		UUID:          item.UUID,
		Type:          item.Type,
		Title:         item.Title,
		SortTitle:     item.SortTitle,
		OriginalTitle: item.OriginalTitle,
		Year:          item.Year,
		Thumb:         item.Thumb,
		Art:           item.Art,
		Summary:       item.Summary,
		Rating:        item.Rating,
		ContentRating: item.ContentRating,
		Studio:        item.Studio,
		Duration:      item.Duration,
		AddedAt:       item.AddedAt.Format("2006-01-02T15:04:05Z"),
		UpdatedAt:     item.UpdatedAt.Format("2006-01-02T15:04:05Z"),
		LibraryID:     item.LibraryID,
		TMDBID:        item.UUID,
		ChildCount:    item.ChildCount,
	})
}

// adminRefreshMediaMetadata refreshes metadata for a media item from TMDB
func (s *Server) adminRefreshMediaMetadata(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var item models.MediaItem
	if err := s.db.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	// Check if TMDB agent is available
	tmdbAgent := s.scanner.GetTMDBAgent()
	if tmdbAgent == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "TMDB agent not configured"})
		return
	}

	// Trigger metadata refresh
	go func() {
		if item.Type == "movie" {
			tmdbAgent.UpdateMovieMetadata(&item)
		} else if item.Type == "show" {
			tmdbAgent.UpdateShowMetadata(&item)
		}
	}()

	c.JSON(http.StatusOK, gin.H{"message": "Metadata refresh started"})
}

// adminRefreshAllMissingMetadata refreshes metadata for all items missing it
func (s *Server) adminRefreshAllMissingMetadata(c *gin.Context) {
	// Check if TMDB agent is available
	tmdbAgent := s.scanner.GetTMDBAgent()
	if tmdbAgent == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "TMDB agent not configured"})
		return
	}

	// Find all movies and shows without poster (thumb) - indicates missing metadata
	var items []models.MediaItem
	s.db.Where("type IN ? AND (thumb IS NULL OR thumb = '')", []string{"movie", "show"}).Find(&items)

	if len(items) == 0 {
		c.JSON(http.StatusOK, gin.H{"message": "No items with missing metadata found", "count": 0})
		return
	}

	// Process in background
	go func() {
		for _, item := range items {
			itemCopy := item
			if itemCopy.Type == "movie" {
				tmdbAgent.UpdateMovieMetadata(&itemCopy)
			} else if itemCopy.Type == "show" {
				tmdbAgent.UpdateShowMetadata(&itemCopy)
			}
		}
	}()

	c.JSON(http.StatusOK, gin.H{
		"message": fmt.Sprintf("Refreshing metadata for %d items", len(items)),
		"count":   len(items),
	})
}

// adminSearchTMDB searches TMDB for matching media
func (s *Server) adminSearchTMDB(c *gin.Context) {
	query := c.Query("query")
	mediaType := c.DefaultQuery("media_type", "movie")

	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Query is required"})
		return
	}

	// Check if TMDB API key is configured
	if s.config.Library.TMDBApiKey == "" {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "TMDB API key not configured"})
		return
	}

	// Search TMDB
	searchType := "movie"
	if mediaType == "tv" || mediaType == "show" {
		searchType = "tv"
	}

	url := fmt.Sprintf("https://api.themoviedb.org/3/search/%s?api_key=%s&query=%s",
		searchType, s.config.Library.TMDBApiKey, query)

	resp, err := http.Get(url)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search TMDB"})
		return
	}
	defer resp.Body.Close()

	var tmdbResponse struct {
		Results []struct {
			ID            int     `json:"id"`
			Title         string  `json:"title"`
			Name          string  `json:"name"`
			OriginalTitle string  `json:"original_title"`
			OriginalName  string  `json:"original_name"`
			ReleaseDate   string  `json:"release_date"`
			FirstAirDate  string  `json:"first_air_date"`
			Overview      string  `json:"overview"`
			PosterPath    string  `json:"poster_path"`
			VoteAverage   float64 `json:"vote_average"`
		} `json:"results"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&tmdbResponse); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse TMDB response"})
		return
	}

	// Convert to our response format
	results := make([]gin.H, 0, len(tmdbResponse.Results))
	for _, r := range tmdbResponse.Results {
		title := r.Title
		if title == "" {
			title = r.Name
		}
		originalTitle := r.OriginalTitle
		if originalTitle == "" {
			originalTitle = r.OriginalName
		}
		releaseDate := r.ReleaseDate
		if releaseDate == "" {
			releaseDate = r.FirstAirDate
		}

		results = append(results, gin.H{
			"id":             r.ID,
			"title":          title,
			"original_title": originalTitle,
			"release_date":   releaseDate,
			"first_air_date": r.FirstAirDate,
			"overview":       r.Overview,
			"poster_path":    r.PosterPath,
			"vote_average":   r.VoteAverage,
			"media_type":     searchType,
		})
	}

	c.JSON(http.StatusOK, gin.H{"results": results})
}

// adminApplyMediaMatch applies a TMDB match to a media item
func (s *Server) adminApplyMediaMatch(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	var item models.MediaItem
	if err := s.db.First(&item, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Media item not found"})
		return
	}

	var req struct {
		TMDBID    int    `json:"tmdb_id"`
		MediaType string `json:"media_type"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	// Update the item's UUID with the TMDB reference
	item.UUID = fmt.Sprintf("tmdb://%d", req.TMDBID)
	if err := s.db.Save(&item).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update media item"})
		return
	}

	// Trigger metadata refresh using TMDB agent
	tmdbAgent := s.scanner.GetTMDBAgent()
	if tmdbAgent != nil {
		go func() {
			if req.MediaType == "movie" || item.Type == "movie" {
				tmdbAgent.UpdateMovieMetadata(&item)
			} else {
				tmdbAgent.UpdateShowMetadata(&item)
			}
		}()
	}

	c.JSON(http.StatusOK, gin.H{"message": "Match applied, metadata refresh started"})
}
