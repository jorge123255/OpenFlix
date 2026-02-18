package api

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ Admin Playlist Handlers (Web UI) ============

// getAdminPlaylists returns all playlists for the current user with item counts
func (s *Server) getAdminPlaylists(c *gin.Context) {
	userID := c.GetUint("userID")

	var playlists []models.Playlist
	s.db.Where("user_id = ?", userID).Order("updated_at DESC").Find(&playlists)

	// Get item counts for each playlist
	for i := range playlists {
		var count int64
		s.db.Model(&models.PlaylistItem{}).Where("playlist_id = ?", playlists[i].ID).Count(&count)
		playlists[i].LeafCount = int(count)
	}

	c.JSON(http.StatusOK, gin.H{"playlists": playlists})
}

// createAdminPlaylist creates a new playlist via JSON body
func (s *Server) createAdminPlaylist(c *gin.Context) {
	userID := c.GetUint("userID")

	var req struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Name is required"})
		return
	}

	playlist := models.Playlist{
		UUID:         uuid.New().String(),
		UserID:       userID,
		Title:        req.Name,
		Summary:      req.Description,
		PlaylistType: "video",
		AddedAt:      time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := s.db.Create(&playlist).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, playlist)
}

// getAdminPlaylist returns a single playlist with its items and joined media metadata
func (s *Server) getAdminPlaylist(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	var playlist models.Playlist
	if err := s.db.First(&playlist, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Playlist not found"})
		return
	}

	// Get items with media metadata
	var items []models.PlaylistItem
	s.db.Where("playlist_id = ?", id).Order("`order` ASC").Find(&items)

	if len(items) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"playlist": playlist,
			"items":    []interface{}{},
		})
		return
	}

	// Get media item IDs
	mediaIDs := make([]uint, len(items))
	for i, item := range items {
		mediaIDs[i] = item.MediaItemID
	}

	// Fetch media items
	var mediaItems []models.MediaItem
	s.db.Where("id IN ?", mediaIDs).Find(&mediaItems)

	mediaMap := make(map[uint]models.MediaItem)
	for _, m := range mediaItems {
		mediaMap[m.ID] = m
	}

	// Build response items with media info
	type PlaylistItemResponse struct {
		ID          uint   `json:"id"`
		PlaylistID  uint   `json:"playlistId"`
		MediaItemID uint   `json:"mediaId"`
		Order       int    `json:"position"`
		Title       string `json:"title"`
		Type        string `json:"type"`
		Year        int    `json:"year,omitempty"`
		Thumb       string `json:"thumb,omitempty"`
		Duration    int64  `json:"duration,omitempty"`
		Summary     string `json:"summary,omitempty"`
	}

	responseItems := make([]PlaylistItemResponse, 0, len(items))
	for _, item := range items {
		ri := PlaylistItemResponse{
			ID:          item.ID,
			PlaylistID:  item.PlaylistID,
			MediaItemID: item.MediaItemID,
			Order:       item.Order,
		}
		if media, ok := mediaMap[item.MediaItemID]; ok {
			ri.Title = media.Title
			ri.Type = media.Type
			ri.Year = media.Year
			ri.Thumb = media.Thumb
			ri.Duration = media.Duration
			ri.Summary = media.Summary
		}
		responseItems = append(responseItems, ri)
	}

	playlist.LeafCount = len(responseItems)
	c.JSON(http.StatusOK, gin.H{
		"playlist": playlist,
		"items":    responseItems,
	})
}

// updateAdminPlaylist updates a playlist's name and description
func (s *Server) updateAdminPlaylist(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	userID := c.GetUint("userID")

	var playlist models.Playlist
	if err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&playlist).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Playlist not found"})
		return
	}

	var req struct {
		Name        *string `json:"name"`
		Description *string `json:"description"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updates := map[string]interface{}{
		"updated_at": time.Now(),
	}
	if req.Name != nil {
		updates["title"] = *req.Name
	}
	if req.Description != nil {
		updates["summary"] = *req.Description
	}

	s.db.Model(&playlist).Updates(updates)
	s.db.First(&playlist, id)

	c.JSON(http.StatusOK, playlist)
}

// deleteAdminPlaylist deletes a playlist and all its items
func (s *Server) deleteAdminPlaylist(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	userID := c.GetUint("userID")

	// Delete items first
	s.db.Where("playlist_id = ?", id).Delete(&models.PlaylistItem{})

	// Delete playlist
	result := s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Playlist{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Playlist not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// addItemsToAdminPlaylist adds one or more media items to a playlist
func (s *Server) addItemsToAdminPlaylist(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	var playlist models.Playlist
	if err := s.db.First(&playlist, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Playlist not found"})
		return
	}

	var req struct {
		MediaIDs []uint `json:"mediaIds" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "mediaIds is required"})
		return
	}

	// Get current max order
	var maxOrder int
	s.db.Model(&models.PlaylistItem{}).
		Where("playlist_id = ?", id).
		Select("COALESCE(MAX(`order`), -1)").
		Scan(&maxOrder)

	added := 0
	for _, mediaID := range req.MediaIDs {
		// Verify media exists
		var count int64
		s.db.Model(&models.MediaItem{}).Where("id = ?", mediaID).Count(&count)
		if count == 0 {
			continue
		}

		maxOrder++
		item := models.PlaylistItem{
			PlaylistID:  uint(id),
			MediaItemID: mediaID,
			Order:       maxOrder,
		}
		if err := s.db.Create(&item).Error; err == nil {
			added++
		}
	}

	// Update playlist counts
	var totalCount int64
	s.db.Model(&models.PlaylistItem{}).Where("playlist_id = ?", id).Count(&totalCount)
	s.db.Model(&playlist).Updates(map[string]interface{}{
		"leaf_count": totalCount,
		"updated_at": time.Now(),
	})

	c.JSON(http.StatusOK, gin.H{"added": added})
}

// removeItemFromAdminPlaylist removes a specific item from a playlist
func (s *Server) removeItemFromAdminPlaylist(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
		return
	}

	itemID, err := strconv.Atoi(c.Param("itemId"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid item ID"})
		return
	}

	result := s.db.Where("id = ? AND playlist_id = ?", itemID, id).Delete(&models.PlaylistItem{})
	if result.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Item not found"})
		return
	}

	// Update playlist counts
	var totalCount int64
	s.db.Model(&models.PlaylistItem{}).Where("playlist_id = ?", id).Count(&totalCount)
	s.db.Model(&models.Playlist{}).Where("id = ?", id).Updates(map[string]interface{}{
		"leaf_count": totalCount,
		"updated_at": time.Now(),
	})

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

// reorderAdminPlaylistItems reorders items in a playlist
func (s *Server) reorderAdminPlaylistItems(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid playlist ID"})
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
		tx.Model(&models.PlaylistItem{}).
			Where("id = ? AND playlist_id = ?", itemID, id).
			Update("order", i)
	}
	tx.Commit()

	s.db.Model(&models.Playlist{}).Where("id = ?", id).Update("updated_at", time.Now())

	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}
