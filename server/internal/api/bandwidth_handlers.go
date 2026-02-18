package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// bandwidthReportRequest is the payload for POST /api/playback/bandwidth.
type bandwidthReportRequest struct {
	ClientID     string  `json:"clientId" binding:"required"`
	BandwidthBps float64 `json:"bandwidthBps" binding:"required"`
}

// reportBandwidth handles POST /api/playback/bandwidth.
// Clients report their measured bandwidth so the server can recommend an
// adaptive quality tier.
func (s *Server) reportBandwidth(c *gin.Context) {
	var req bandwidthReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: clientId and bandwidthBps are required"})
		return
	}

	if req.BandwidthBps <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "bandwidthBps must be positive"})
		return
	}

	stats := s.bandwidthManager.ReportBandwidth(req.ClientID, req.BandwidthBps)

	c.JSON(http.StatusOK, gin.H{
		"clientId":           stats.ClientID,
		"averageBandwidth":   stats.AverageBandwidth,
		"recommendedQuality": stats.RecommendedQuality,
		"sampleCount":        len(stats.Samples),
		"totalReports":       stats.TotalReports,
	})
}

// getClientBandwidth handles GET /api/playback/bandwidth/:clientId.
// Returns the current bandwidth stats for a specific client.
func (s *Server) getClientBandwidth(c *gin.Context) {
	clientID := c.Param("clientId")
	if clientID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "clientId is required"})
		return
	}

	stats := s.bandwidthManager.GetClientStats(clientID)
	if stats == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No bandwidth data for client"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"clientId":           stats.ClientID,
		"samples":            stats.Samples,
		"averageBandwidth":   stats.AverageBandwidth,
		"recommendedQuality": stats.RecommendedQuality,
		"manualCap":          stats.ManualCap,
		"lastReport":         stats.LastReport,
		"totalReports":       stats.TotalReports,
	})
}

// setClientBandwidthCap handles PUT /api/playback/bandwidth/:clientId/cap.
// Sets a manual bandwidth cap for a specific client.
type bandwidthCapRequest struct {
	CapBps float64 `json:"capBps"` // 0 means remove the cap
}

func (s *Server) setClientBandwidthCap(c *gin.Context) {
	clientID := c.Param("clientId")
	if clientID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "clientId is required"})
		return
	}

	var req bandwidthCapRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if req.CapBps < 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "capBps must be non-negative"})
		return
	}

	stats := s.bandwidthManager.SetClientCap(clientID, req.CapBps)

	c.JSON(http.StatusOK, gin.H{
		"clientId":           stats.ClientID,
		"manualCap":          stats.ManualCap,
		"averageBandwidth":   stats.AverageBandwidth,
		"recommendedQuality": stats.RecommendedQuality,
	})
}

// getServerBandwidth handles GET /api/playback/bandwidth/server.
// Returns aggregate server bandwidth statistics. Admin only.
func (s *Server) getServerBandwidth(c *gin.Context) {
	stats := s.bandwidthManager.GetServerStats()

	c.JSON(http.StatusOK, gin.H{
		"totalClients":       stats.TotalClients,
		"activeClients":      stats.ActiveClients,
		"totalBandwidthUsed": stats.TotalBandwidthUsed,
		"serverLimit":        stats.ServerLimit,
		"limitUtilization":   stats.LimitUtilization,
	})
}

// setServerBandwidthLimit handles PUT /api/playback/bandwidth/server/limit.
// Sets the server-wide bandwidth limit. Admin only.
type serverLimitRequest struct {
	LimitBps float64 `json:"limitBps"` // 0 means unlimited
}

func (s *Server) setServerBandwidthLimit(c *gin.Context) {
	var req serverLimitRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
		return
	}

	if req.LimitBps < 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "limitBps must be non-negative"})
		return
	}

	s.bandwidthManager.SetServerLimit(req.LimitBps)

	stats := s.bandwidthManager.GetServerStats()

	c.JSON(http.StatusOK, gin.H{
		"serverLimit":        stats.ServerLimit,
		"totalBandwidthUsed": stats.TotalBandwidthUsed,
		"limitUtilization":   stats.LimitUtilization,
		"message":            "Server bandwidth limit updated",
	})
}
