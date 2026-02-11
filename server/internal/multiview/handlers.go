package multiview

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all multiview API routes
func RegisterRoutes(r *gin.RouterGroup, manager *MultiviewManager) {
	// Session management
	r.GET("/sessions", getSessionsHandler(manager))
	r.POST("/sessions", createSessionHandler(manager))
	r.GET("/sessions/:id", getSessionHandler(manager))
	r.DELETE("/sessions/:id", deleteSessionHandler(manager))

	// Stream management
	r.POST("/sessions/:id/stream", addStreamHandler(manager))
	r.DELETE("/sessions/:id/stream/:channelId", removeStreamHandler(manager))

	// Layout and audio
	r.POST("/sessions/:id/layout", setLayoutHandler(manager))
	r.POST("/sessions/:id/audio", setAudioFocusHandler(manager))
	r.POST("/sessions/:id/swap", swapSlotsHandler(manager))

	// Stats
	r.GET("/stats", getStatsHandler(manager))

	// DVR controls
	dvr := r.Group("/dvr")
	{
		dvr.POST("/pause", pauseHandler(manager))
		dvr.POST("/resume", resumeHandler(manager))
		dvr.POST("/rewind", rewindHandler(manager))
		dvr.POST("/forward", forwardHandler(manager))
		dvr.POST("/live", jumpToLiveHandler(manager))
		dvr.POST("/speed", speedHandler(manager))
		dvr.GET("/state", stateHandler(manager))
		dvr.POST("/pause-all", pauseAllHandler(manager))
		dvr.POST("/resume-all", resumeAllHandler(manager))
		dvr.POST("/live-all", liveAllHandler(manager))
		dvr.POST("/sync", syncHandler(manager))
	}
}

// Session handlers
func getSessionsHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"success":  true,
			"sessions": m.sessions,
		})
	}
}

func createSessionHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			UserID string `json:"user_id"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		session, err := m.CreateSession(req.UserID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"session": session,
		})
	}
}

func getSessionHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID := c.Param("id")
		session := m.GetSession(sessionID)
		if session == nil {
			c.JSON(http.StatusNotFound, gin.H{"success": false, "error": "Session not found"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"session": session,
		})
	}
}

func deleteSessionHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID := c.Param("id")
		m.DeleteSession(sessionID)
		c.JSON(http.StatusOK, gin.H{"success": true})
	}
}

func addStreamHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID := c.Param("id")
		var req struct {
			ChannelID string `json:"channel_id"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		slot, err := m.AddStream(sessionID, req.ChannelID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"success": false, "error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"slot":    slot,
		})
	}
}

func removeStreamHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID := c.Param("id")
		channelID := c.Param("channelId")
		m.RemoveStream(sessionID, channelID)
		c.JSON(http.StatusOK, gin.H{"success": true})
	}
}

func setLayoutHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID := c.Param("id")
		var req struct {
			Layout string `json:"layout"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		m.SetLayout(sessionID, Layout(req.Layout))
		c.JSON(http.StatusOK, gin.H{"success": true, "layout": req.Layout})
	}
}

func setAudioFocusHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID := c.Param("id")
		var req struct {
			SlotIndex int `json:"slot_index"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		m.SetAudioFocus(sessionID, req.SlotIndex)
		c.JSON(http.StatusOK, gin.H{"success": true, "audio_slot": req.SlotIndex})
	}
}

func swapSlotsHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID := c.Param("id")
		var req struct {
			Index1 int `json:"index1"`
			Index2 int `json:"index2"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		m.SwapSlots(sessionID, req.Index1, req.Index2)
		c.JSON(http.StatusOK, gin.H{"success": true})
	}
}

func getStatsHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		stats := m.GetStats()
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"stats":   stats,
		})
	}
}

// DVR handlers
func pauseHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			ChannelID string `json:"channel_id"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		m.GetDVR().Pause(req.ChannelID)
		state := m.GetDVR().GetStreamState(req.ChannelID)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "paused",
			"state":   state,
		})
	}
}

func resumeHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			ChannelID string `json:"channel_id"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		m.GetDVR().Resume(req.ChannelID)
		state := m.GetDVR().GetStreamState(req.ChannelID)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "resumed",
			"state":   state,
		})
	}
}

func rewindHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			ChannelID string `json:"channel_id"`
			Seconds   int    `json:"seconds"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		if req.Seconds <= 0 {
			req.Seconds = 15
		}

		m.GetDVR().Rewind(req.ChannelID, req.Seconds)
		state := m.GetDVR().GetStreamState(req.ChannelID)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "rewound",
			"seconds": req.Seconds,
			"state":   state,
		})
	}
}

func forwardHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			ChannelID string `json:"channel_id"`
			Seconds   int    `json:"seconds"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		if req.Seconds <= 0 {
			req.Seconds = 15
		}

		m.GetDVR().FastForward(req.ChannelID, req.Seconds)
		state := m.GetDVR().GetStreamState(req.ChannelID)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "forwarded",
			"seconds": req.Seconds,
			"state":   state,
		})
	}
}

func jumpToLiveHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			ChannelID string `json:"channel_id"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		m.GetDVR().JumpToLive(req.ChannelID)
		state := m.GetDVR().GetStreamState(req.ChannelID)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "jumped_to_live",
			"state":   state,
		})
	}
}

func speedHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			ChannelID string  `json:"channel_id"`
			Speed     float64 `json:"speed"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"success": false, "error": "Invalid request"})
			return
		}

		m.GetDVR().SetPlaybackSpeed(req.ChannelID, req.Speed)
		state := m.GetDVR().GetStreamState(req.ChannelID)

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "speed_changed",
			"speed":   req.Speed,
			"state":   state,
		})
	}
}

func stateHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		channelID := c.Query("channel_id")

		if channelID != "" {
			state := m.GetDVR().GetStreamState(channelID)
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"state":   state,
			})
		} else {
			states := m.GetDVR().GetAllStates()
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"states":  states,
			})
		}
	}
}

func pauseAllHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		m.GetDVR().PauseAll()
		states := m.GetDVR().GetAllStates()

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "paused_all",
			"states":  states,
		})
	}
}

func resumeAllHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		m.GetDVR().ResumeAll()
		states := m.GetDVR().GetAllStates()

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "resumed_all",
			"states":  states,
		})
	}
}

func liveAllHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		m.GetDVR().JumpAllToLive()
		states := m.GetDVR().GetAllStates()

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "all_live",
			"states":  states,
		})
	}
}

func syncHandler(m *MultiviewManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			OffsetSeconds int `json:"offset_seconds"`
		}
		c.ShouldBindJSON(&req) // Optional

		m.GetDVR().SyncStreams(0) // Sync to live
		states := m.GetDVR().GetAllStates()

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"action":  "synced",
			"states":  states,
		})
	}
}
