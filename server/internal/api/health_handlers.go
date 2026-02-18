package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/health"
)

// ============ Stream Health Monitoring Handlers ============

// getHealthStreams returns all active streams with health scores.
//
// GET /api/health/streams
func (s *Server) getHealthStreams(c *gin.Context) {
	streams := s.healthMonitor.GetAllStreams()
	c.JSON(http.StatusOK, gin.H{
		"streams": streams,
		"total":   len(streams),
	})
}

// getHealthStream returns detailed health for a specific stream.
//
// GET /api/health/streams/:id
func (s *Server) getHealthStream(c *gin.Context) {
	streamID := c.Param("id")
	if streamID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "stream id is required"})
		return
	}

	stream := s.healthMonitor.GetStreamHealth(streamID)
	if stream == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "stream not found"})
		return
	}

	c.JSON(http.StatusOK, stream)
}

// getHealthChannels returns per-channel aggregate health.
//
// GET /api/health/channels
func (s *Server) getHealthChannels(c *gin.Context) {
	channels := s.healthMonitor.GetChannelHealth()
	c.JSON(http.StatusOK, gin.H{
		"channels": channels,
		"total":    len(channels),
	})
}

// getHealthChannelHistory returns the last 1 hour of per-minute health
// snapshots for a specific channel.
//
// GET /api/health/channels/:id/history
func (s *Server) getHealthChannelHistory(c *gin.Context) {
	channelID := c.Param("id")
	if channelID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "channel id is required"})
		return
	}

	history := s.healthMonitor.GetChannelHistory(channelID)
	c.JSON(http.StatusOK, gin.H{
		"channelId": channelID,
		"history":   history,
		"total":     len(history),
	})
}

// reportStreamHealth accepts a metrics report from a player/client.
//
// POST /api/health/streams/:id/report
func (s *Server) reportStreamHealth(c *gin.Context) {
	streamID := c.Param("id")
	if streamID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "stream id is required"})
		return
	}

	var metrics health.StreamMetrics
	if err := c.ShouldBindJSON(&metrics); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Override stream ID from URL path
	metrics.StreamID = streamID

	// Populate user ID from auth context if available
	if userUUID, exists := c.Get("userUUID"); exists {
		if uid, ok := userUUID.(string); ok && metrics.UserID == "" {
			metrics.UserID = uid
		}
	}

	result := s.healthMonitor.ReportMetrics(metrics)

	c.JSON(http.StatusOK, gin.H{
		"streamId":    result.StreamID,
		"healthScore": result.HealthScore,
		"avgBitrate":  result.AvgBitrateKbps,
		"avgLatency":  result.AvgLatencyMs,
		"reportCount": result.ReportCount,
	})
}

// getHealthAlerts returns current health alerts.
//
// GET /api/health/alerts
func (s *Server) getHealthAlerts(c *gin.Context) {
	alerts := s.healthMonitor.GetAlerts()
	c.JSON(http.StatusOK, gin.H{
		"alerts": alerts,
		"total":  len(alerts),
	})
}

// getHealthSummary returns an overall system health summary.
//
// GET /api/health/summary
func (s *Server) getHealthSummary(c *gin.Context) {
	summary := s.healthMonitor.GetSummary()
	c.JSON(http.StatusOK, summary)
}
