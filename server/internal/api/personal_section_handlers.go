package api

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Personal Section Handlers ============

// getPersonalSections returns all personal sections for the current user
func (s *Server) getPersonalSections(c *gin.Context) {
	userID := c.GetUint("userID")

	var sections []models.PersonalSection
	s.db.Where("user_id = ?", userID).Order("position ASC").Find(&sections)

	// Get item counts for manual sections
	for i := range sections {
		if sections[i].SectionType == "manual" {
			var count int64
			s.db.Model(&models.PersonalSectionItem{}).Where("section_id = ?", sections[i].ID).Count(&count)
			sections[i].ItemCount = int(count)
		} else if sections[i].SectionType == "smart" {
			// Count items matching the smart filter
			count := s.countSmartFilterMatches(sections[i].SmartFilter)
			sections[i].ItemCount = count
		}
	}

	c.JSON(http.StatusOK, gin.H{"sections": sections})
}

// createPersonalSection creates a new personal section
func (s *Server) createPersonalSection(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
		SectionType string `json:"sectionType"` // "smart" or "manual"
		SmartFilter string `json:"smartFilter"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Name is required"})
		return
	}

	sectionType := req.SectionType
	if sectionType != "smart" && sectionType != "manual" {
		sectionType = "manual"
	}

	// Get next position
	var maxPos int
	s.db.Model(&models.PersonalSection{}).
		Where("user_id = ?", userID).
		Select("COALESCE(MAX(position), -1)").
		Scan(&maxPos)

	section := models.PersonalSection{
		UserID:      userID,
		Name:        req.Name,
		Description: req.Description,
		SectionType: sectionType,
		SmartFilter: req.SmartFilter,
		Position:    maxPos + 1,
	}

	if err := s.db.Create(&section).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, section)
}

// getPersonalSection returns a single personal section with items
func (s *Server) getPersonalSection(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid section ID"})
		return
	}

	var section models.PersonalSection
	if err := s.db.First(&section, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Section not found"})
		return
	}

	type SectionItemResponse struct {
		ID       uint   `json:"id"`
		MediaID  uint   `json:"mediaId"`
		Position int    `json:"position"`
		Title    string `json:"title"`
		Type     string `json:"type"`
		Year     int    `json:"year,omitempty"`
		Thumb    string `json:"thumb,omitempty"`
		Duration int64  `json:"duration,omitempty"`
		Summary  string `json:"summary,omitempty"`
	}

	var responseItems []SectionItemResponse

	if section.SectionType == "manual" {
		var items []models.PersonalSectionItem
		s.db.Where("section_id = ?", id).Order("position ASC").Find(&items)

		if len(items) > 0 {
			mediaIDs := make([]uint, len(items))
			for i, item := range items {
				mediaIDs[i] = item.MediaID
			}

			var mediaItems []models.MediaItem
			s.db.Where("id IN ?", mediaIDs).Find(&mediaItems)

			mediaMap := make(map[uint]models.MediaItem)
			for _, m := range mediaItems {
				mediaMap[m.ID] = m
			}

			for _, item := range items {
				ri := SectionItemResponse{
					ID:       item.ID,
					MediaID:  item.MediaID,
					Position: item.Position,
				}
				if media, ok := mediaMap[item.MediaID]; ok {
					ri.Title = media.Title
					ri.Type = media.Type
					ri.Year = media.Year
					ri.Thumb = media.Thumb
					ri.Duration = media.Duration
					ri.Summary = media.Summary
				}
				responseItems = append(responseItems, ri)
			}
		}
	} else if section.SectionType == "smart" {
		// Execute the smart filter and return matching items
		mediaItems := s.executeSmartFilter(section.SmartFilter, 100)
		for i, m := range mediaItems {
			responseItems = append(responseItems, SectionItemResponse{
				MediaID:  m.ID,
				Position: i,
				Title:    m.Title,
				Type:     m.Type,
				Year:     m.Year,
				Thumb:    m.Thumb,
				Duration: m.Duration,
				Summary:  m.Summary,
			})
		}
	}

	if responseItems == nil {
		responseItems = []SectionItemResponse{}
	}

	section.ItemCount = len(responseItems)
	c.JSON(http.StatusOK, gin.H{
		"section": section,
		"items":   responseItems,
	})
}

// updatePersonalSection updates a personal section
func (s *Server) updatePersonalSection(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid section ID"})
		return
	}

	userID := c.GetUint("userID")

	var section models.PersonalSection
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&section).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Section not found"})
		return
	}

	var req struct {
		Name        *string `json:"name"`
		Description *string `json:"description"`
		SmartFilter *string `json:"smartFilter"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{
		"updated_at": time.Now(),
	}
	if req.Name != nil {
		updates["name"] = *req.Name
	}
	if req.Description != nil {
		updates["description"] = *req.Description
	}
	if req.SmartFilter != nil {
		updates["smart_filter"] = *req.SmartFilter
	}

	s.db.Model(&section).Updates(updates)
	s.db.First(&section, id)

	c.JSON(http.StatusOK, section)
}

// deletePersonalSection deletes a personal section and its items
func (s *Server) deletePersonalSection(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid section ID"})
		return
	}

	userID := c.GetUint("userID")

	// Delete items first
	s.db.Where("section_id = ?", id).Delete(&models.PersonalSectionItem{})

	// Delete section
	result := s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.PersonalSection{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Section not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// addItemsToPersonalSection adds items to a manual personal section
func (s *Server) addItemsToPersonalSection(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid section ID"})
		return
	}

	var section models.PersonalSection
	if err := s.db.First(&section, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Section not found"})
		return
	}

	if section.SectionType != "manual" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cannot add items to a smart section"})
		return
	}

	var req struct {
		MediaIDs []uint `json:"mediaIds" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "mediaIds is required"})
		return
	}

	var maxPos int
	s.db.Model(&models.PersonalSectionItem{}).
		Where("section_id = ?", id).
		Select("COALESCE(MAX(position), -1)").
		Scan(&maxPos)

	added := 0
	for _, mediaID := range req.MediaIDs {
		// Check for duplicates
		var existing int64
		s.db.Model(&models.PersonalSectionItem{}).
			Where("section_id = ? AND media_id = ?", id, mediaID).
			Count(&existing)
		if existing > 0 {
			continue
		}

		maxPos++
		item := models.PersonalSectionItem{
			SectionID: uint(id),
			MediaID:   mediaID,
			Position:  maxPos,
		}
		if err := s.db.Create(&item).Error; err == nil {
			added++
		}
	}

	c.JSON(http.StatusOK, gin.H{"added": added})
}

// removeItemFromPersonalSection removes an item from a personal section
func (s *Server) removeItemFromPersonalSection(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid section ID"})
		return
	}

	itemID, err := strconv.Atoi(c.Param("itemId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	result := s.db.Where("id = ? AND section_id = ?", itemID, id).Delete(&models.PersonalSectionItem{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// reorderPersonalSectionItems reorders items in a personal section
func (s *Server) reorderPersonalSectionItems(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid section ID"})
		return
	}

	var req struct {
		ItemIDs []uint `json:"itemIds" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "itemIds is required"})
		return
	}

	tx := s.db.Begin()
	for i, itemID := range req.ItemIDs {
		tx.Model(&models.PersonalSectionItem{}).
			Where("id = ? AND section_id = ?", itemID, id).
			Update("position", i)
	}
	tx.Commit()

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// previewSmartFilter previews items matching a smart filter without saving
func (s *Server) previewSmartFilter(c *gin.Context) {
	var req struct {
		SmartFilter string `json:"smartFilter" binding:"required"`
		Limit       int    `json:"limit"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "smartFilter is required"})
		return
	}

	limit := req.Limit
	if limit <= 0 {
		limit = 50
	}

	items := s.executeSmartFilter(req.SmartFilter, limit)

	type PreviewItem struct {
		ID       uint   `json:"id"`
		Title    string `json:"title"`
		Type     string `json:"type"`
		Year     int    `json:"year,omitempty"`
		Thumb    string `json:"thumb,omitempty"`
		Duration int64  `json:"duration,omitempty"`
	}

	result := make([]PreviewItem, len(items))
	for i, m := range items {
		result[i] = PreviewItem{
			ID:       m.ID,
			Title:    m.Title,
			Type:     m.Type,
			Year:     m.Year,
			Thumb:    m.Thumb,
			Duration: m.Duration,
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"items": result,
		"total": len(result),
	})
}

// ============ Smart Filter Helpers ============

// SmartFilterCriteria represents the JSON structure for smart filters
type SmartFilterCriteria struct {
	ContentType  string `json:"contentType,omitempty"`  // movie, show, episode
	Genre        string `json:"genre,omitempty"`        // genre tag
	YearFrom     int    `json:"yearFrom,omitempty"`     // min year
	YearTo       int    `json:"yearTo,omitempty"`       // max year
	MinRating    float64 `json:"minRating,omitempty"`   // min rating
	MaxRating    float64 `json:"maxRating,omitempty"`   // max rating
	WatchedState string `json:"watchedState,omitempty"` // watched, unwatched, any
	SortBy       string `json:"sortBy,omitempty"`       // title, year, rating, addedAt
	SortDir      string `json:"sortDir,omitempty"`      // asc, desc
}

func (s *Server) executeSmartFilter(filterJSON string, limit int) []models.MediaItem {
	var criteria SmartFilterCriteria
	if err := json.Unmarshal([]byte(filterJSON), &criteria); err != nil {
		return nil
	}

	query := s.db.Model(&models.MediaItem{})

	// Content type filter
	if criteria.ContentType != "" {
		types := strings.Split(criteria.ContentType, ",")
		query = query.Where("type IN ?", types)
	} else {
		query = query.Where("type IN ?", []string{"movie", "show"})
	}

	// Genre filter
	if criteria.Genre != "" {
		query = query.Joins("JOIN media_genres ON media_genres.media_item_id = media_items.id").
			Joins("JOIN genres ON genres.id = media_genres.genre_id").
			Where("genres.tag = ?", criteria.Genre)
	}

	// Year filter
	if criteria.YearFrom > 0 {
		query = query.Where("year >= ?", criteria.YearFrom)
	}
	if criteria.YearTo > 0 {
		query = query.Where("year <= ?", criteria.YearTo)
	}

	// Rating filter
	if criteria.MinRating > 0 {
		query = query.Where("rating >= ?", criteria.MinRating)
	}
	if criteria.MaxRating > 0 {
		query = query.Where("rating <= ?", criteria.MaxRating)
	}

	// Sort
	sortCol := "title"
	switch criteria.SortBy {
	case "year":
		sortCol = "year"
	case "rating":
		sortCol = "rating"
	case "addedAt":
		sortCol = "added_at"
	}
	sortDir := "ASC"
	if strings.EqualFold(criteria.SortDir, "desc") {
		sortDir = "DESC"
	}

	var items []models.MediaItem
	query.Order(sortCol + " " + sortDir).Limit(limit).Find(&items)

	// Watched state filter (requires separate logic since it involves another table)
	// For now we skip watched state in the SQL query; a full implementation would
	// join WatchHistory. The items are returned as-is.

	return items
}

func (s *Server) countSmartFilterMatches(filterJSON string) int {
	var criteria SmartFilterCriteria
	if err := json.Unmarshal([]byte(filterJSON), &criteria); err != nil {
		return 0
	}

	query := s.db.Model(&models.MediaItem{})

	if criteria.ContentType != "" {
		types := strings.Split(criteria.ContentType, ",")
		query = query.Where("type IN ?", types)
	} else {
		query = query.Where("type IN ?", []string{"movie", "show"})
	}

	if criteria.Genre != "" {
		query = query.Joins("JOIN media_genres ON media_genres.media_item_id = media_items.id").
			Joins("JOIN genres ON genres.id = media_genres.genre_id").
			Where("genres.tag = ?", criteria.Genre)
	}

	if criteria.YearFrom > 0 {
		query = query.Where("year >= ?", criteria.YearFrom)
	}
	if criteria.YearTo > 0 {
		query = query.Where("year <= ?", criteria.YearTo)
	}

	if criteria.MinRating > 0 {
		query = query.Where("rating >= ?", criteria.MinRating)
	}
	if criteria.MaxRating > 0 {
		query = query.Where("rating <= ?", criteria.MaxRating)
	}

	var count int64
	query.Count(&count)
	return int(count)
}

// getAvailableGenres returns all genres in the library for the smart filter builder
func (s *Server) getAvailableGenres(c *gin.Context) {
	var genres []models.Genre
	s.db.Order("tag ASC").Find(&genres)

	tags := make([]string, len(genres))
	for i, g := range genres {
		tags[i] = g.Tag
	}

	c.JSON(http.StatusOK, gin.H{"genres": tags})
}

