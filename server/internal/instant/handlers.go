package instant

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// InstantSwitchHandlers provides HTTP handlers for the instant switch feature
type InstantSwitchHandlers struct {
	prebuffer *PrebufferManager
}

// NewInstantSwitchHandlers creates handlers with a prebuffer manager
func NewInstantSwitchHandlers(pm *PrebufferManager) *InstantSwitchHandlers {
	return &InstantSwitchHandlers{prebuffer: pm}
}

// RegisterRoutes registers all instant switch API routes with Gin
func (h *InstantSwitchHandlers) RegisterRoutes(rg *gin.RouterGroup) {
	rg.GET("/status", h.handleStatus)
	rg.POST("/enabled", h.handleSetEnabled)
	rg.POST("/switch", h.handleSwitch)
	rg.GET("/favorites", h.handleGetFavorites)
	rg.POST("/favorites", h.handleSetFavorites)
	rg.GET("/predictions", h.handlePredictions)
	rg.GET("/cached", h.handleCached)
	rg.GET("/stream/:channelId", h.handleCachedStream)
}

// handleStatus returns prebuffer status
func (h *InstantSwitchHandlers) handleStatus(c *gin.Context) {
	stats := h.prebuffer.Stats()

	// Add predictor stats
	if h.prebuffer.predictor != nil {
		stats["predictor"] = h.prebuffer.predictor.Stats()
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    stats,
	})
}

// handleSetEnabled enables or disables instant switch
func (h *InstantSwitchHandlers) handleSetEnabled(c *gin.Context) {
	var req struct {
		Enabled bool `json:"enabled"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	h.prebuffer.SetEnabled(req.Enabled)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"enabled": h.prebuffer.IsEnabled(),
		"message": func() string {
			if req.Enabled {
				return "Instant switch enabled"
			}
			return "Instant switch disabled"
		}(),
	})
}

// handleSwitch notifies prebuffer of channel switch
func (h *InstantSwitchHandlers) handleSwitch(c *gin.Context) {
	var req struct {
		ChannelID string `json:"channel_id"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if req.ChannelID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "channel_id required"})
		return
	}

	// Check if we have a cached stream
	cached, hasCached := h.prebuffer.GetCachedStream(req.ChannelID)

	// Update prebuffer (triggers background caching of adjacent channels)
	h.prebuffer.SetActiveChannel(req.ChannelID)

	response := gin.H{
		"success":    true,
		"channel_id": req.ChannelID,
		"instant":    hasCached,
	}

	if hasCached && cached != nil {
		response["buffered_bytes"] = cached.Buffer.Len()
		response["buffered_duration"] = cached.Buffer.BufferedDuration()
		response["stream_url"] = "/api/instant/stream/" + req.ChannelID
	}

	c.JSON(http.StatusOK, response)
}

// handleGetFavorites returns favorite channels
func (h *InstantSwitchHandlers) handleGetFavorites(c *gin.Context) {
	h.prebuffer.mu.RLock()
	favorites := h.prebuffer.favorites
	h.prebuffer.mu.RUnlock()

	c.JSON(http.StatusOK, gin.H{
		"success":   true,
		"favorites": favorites,
	})
}

// handleSetFavorites sets favorite channels
func (h *InstantSwitchHandlers) handleSetFavorites(c *gin.Context) {
	var req struct {
		Favorites []string `json:"favorites"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	h.prebuffer.SetFavorites(req.Favorites)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Favorites updated",
		"count":   len(req.Favorites),
	})
}

// handlePredictions returns predicted next channels
func (h *InstantSwitchHandlers) handlePredictions(c *gin.Context) {
	channelID := c.Query("channel_id")
	countStr := c.Query("count")

	count := 5
	if countStr != "" {
		if cnt, err := strconv.Atoi(countStr); err == nil && cnt > 0 && cnt <= 20 {
			count = cnt
		}
	}

	var predictions []string
	if channelID != "" {
		predictions = h.prebuffer.predictor.PredictNext(channelID, count)
	} else {
		predictions = h.prebuffer.predictor.GetPopularChannels(count)
	}

	c.JSON(http.StatusOK, gin.H{
		"success":     true,
		"channel_id":  channelID,
		"predictions": predictions,
	})
}

// handleCached returns list of cached channels
func (h *InstantSwitchHandlers) handleCached(c *gin.Context) {
	h.prebuffer.mu.RLock()
	cached := make([]map[string]interface{}, 0)
	for channelID, stream := range h.prebuffer.cachedStreams {
		cached = append(cached, map[string]interface{}{
			"channel_id":        channelID,
			"buffered_bytes":    stream.Buffer.Len(),
			"buffered_duration": stream.Buffer.BufferedDuration(),
			"is_live":           stream.IsLive,
			"last_access":       stream.LastAccess,
		})
	}
	h.prebuffer.mu.RUnlock()

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"cached":  cached,
		"count":   len(cached),
	})
}

// handleCachedStream serves a cached stream
func (h *InstantSwitchHandlers) handleCachedStream(c *gin.Context) {
	channelID := c.Param("channelId")
	if channelID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "channel_id required"})
		return
	}

	stream, exists := h.prebuffer.GetCachedStream(channelID)
	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Channel not cached"})
		return
	}

	// Get all buffered data for instant start
	data := stream.Buffer.GetAllData()
	if data == nil {
		c.Status(http.StatusNoContent)
		return
	}

	// Return as transport stream
	c.Header("Content-Type", "video/mp2t")
	c.Header("Content-Length", strconv.Itoa(len(data)))
	c.Header("X-Buffered-Duration", strconv.FormatFloat(stream.Buffer.BufferedDuration(), 'f', 2, 64))
	c.Header("X-Instant-Switch", "true")

	c.Data(http.StatusOK, "video/mp2t", data)
}
