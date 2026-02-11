package sports

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all sports score API routes with Gin
func RegisterRoutes(r *gin.RouterGroup, manager *SportsScoreManager) {
	r.GET("/scores", getScoresHandler(manager))
	r.GET("/overlay", getOverlayHandler(manager))
	r.GET("/favorites", getFavoritesHandler(manager))
	r.POST("/favorites", setFavoritesHandler(manager))
	r.POST("/alerts", addAlertHandler(manager))
	r.GET("/stats", getStatsHandler(manager))
}

// SetupSportsScores creates and starts the sports score manager
func SetupSportsScores() *SportsScoreManager {
	manager := NewSportsScoreManager()

	// Add ESPN as default provider (FREE, no API key needed!)
	manager.AddProvider(NewESPNProvider())

	// Start fetching every 30 seconds
	manager.Start(30 * time.Second)

	return manager
}

// getScoresHandler returns live scores
func getScoresHandler(m *SportsScoreManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		sport := c.DefaultQuery("sport", "all")
		games := m.GetLiveGames(sport)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"sport":   sport,
			"games":   games,
			"count":   len(games),
		})
	}
}

// getOverlayHandler returns data formatted for the overlay widget
func getOverlayHandler(m *SportsScoreManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.DefaultQuery("user_id", "default")
		maxGamesStr := c.DefaultQuery("max", "5")

		maxGames := 5
		if m, err := strconv.Atoi(maxGamesStr); err == nil && m > 0 && m <= 10 {
			maxGames = m
		}

		data := m.GetOverlayData(userID, maxGames)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"overlay": data,
		})
	}
}

// getFavoritesHandler returns user's favorite teams
func getFavoritesHandler(m *SportsScoreManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.DefaultQuery("user_id", "default")

		favorites := m.GetFavorites(userID)
		games := m.GetFavoriteGames(userID)

		c.JSON(http.StatusOK, gin.H{
			"success":   true,
			"favorites": favorites,
			"games":     games,
		})
	}
}

// setFavoritesHandler sets user's favorite teams
func setFavoritesHandler(m *SportsScoreManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.DefaultQuery("user_id", "default")

		var req struct {
			Teams []string `json:"teams"` // ["KC", "LAL", "NYY"]
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		m.SetFavorites(userID, req.Teams)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Favorites updated",
			"teams":   req.Teams,
		})
	}
}

// addAlertHandler adds a game alert
func addAlertHandler(m *SportsScoreManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.DefaultQuery("user_id", "default")

		var req struct {
			GameID    string `json:"game_id"`
			Type      string `json:"type"`      // close_game, game_start, game_end
			Threshold int    `json:"threshold"` // for close_game: point difference
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		if req.Threshold == 0 {
			req.Threshold = 7 // default: alert if within 7 points
		}

		m.AddAlert(userID, req.GameID, req.Type, req.Threshold)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Alert added",
			"alert": gin.H{
				"game_id":   req.GameID,
				"type":      req.Type,
				"threshold": req.Threshold,
			},
		})
	}
}

// getStatsHandler returns manager statistics
func getStatsHandler(m *SportsScoreManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"stats":   m.Stats(),
		})
	}
}
