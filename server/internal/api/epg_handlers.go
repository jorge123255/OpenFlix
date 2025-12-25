package api

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/epg/gracenote"
)

// EPGService handles EPG (Electronic Program Guide) requests
type EPGService struct {
	gracenoteClient *gracenote.Client
	cache           *gracenote.Cache
}

// NewEPGService creates a new EPG service
func NewEPGService() *EPGService {
	// Initialize Gracenote client
	gnClient := gracenote.NewClient(gracenote.Config{
		BaseURL:   "https://tvlistings.gracenote.com",
		UserAgent: "Mozilla/5.0 (compatible; Plezy/1.0)",
		Timeout:   30 * time.Second,
	})

	// Initialize cache (1 hour TTL)
	cache := gracenote.NewCache(1 * time.Hour)

	return &EPGService{
		gracenoteClient: gnClient,
		cache:           cache,
	}
}

// RegisterRoutes registers EPG API routes
func (s *EPGService) RegisterRoutes(r *gin.Engine) {
	epg := r.Group("/api/epg")
	{
		// Get EPG grid for affiliate
		epg.GET("/grid", s.handleGetGrid)

		// Get affiliate properties
		epg.GET("/affiliates/:aid/properties", s.handleGetAffiliateProperties)

		// Clear EPG cache (admin)
		epg.POST("/cache/clear", s.handleClearCache)

		// Get cache stats
		epg.GET("/cache/stats", s.handleCacheStats)
	}
}

// handleGetGrid returns TV listings grid
// GET /api/epg/grid?affiliate=orbebb&postalCode=60172&hours=6
func (s *EPGService) handleGetGrid(c *gin.Context) {
	// Parse query parameters
	affiliateID := c.Query("affiliate")
	postalCode := c.Query("postalCode")
	hoursStr := c.Query("hours")

	if affiliateID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing 'affiliate' parameter"})
		return
	}

	// Parse hours (default to 6)
	hours := 6
	if hoursStr != "" {
		if h, err := strconv.Atoi(hoursStr); err == nil && h > 0 {
			hours = h
		}
	}

	// Check cache first
	cacheKey := affiliateID + "_" + postalCode + "_" + strconv.Itoa(hours)
	var gridResp *gracenote.GridResponse
	cached, err := s.cache.Get(cacheKey, &gridResp)
	if err == nil && cached {
		// Return cached data
		c.Header("X-Cache", "HIT")
		c.JSON(http.StatusOK, gin.H{
			"channels": gridResp.Channels,
			"cached":   true,
		})
		return
	}

	// Fetch from Gracenote
	gridResp, err = s.gracenoteClient.GetListingsForAffiliate(c.Request.Context(), affiliateID, postalCode, hours)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Cache the result
	s.cache.Set(cacheKey, gridResp)

	// Return response
	c.Header("X-Cache", "MISS")
	c.JSON(http.StatusOK, gin.H{
		"channels": gridResp.Channels,
		"cached":   false,
	})
}

// handleGetAffiliateProperties returns affiliate/provider configuration
// GET /api/epg/affiliates/{aid}/properties
func (s *EPGService) handleGetAffiliateProperties(c *gin.Context) {
	affiliateID := c.Param("aid")

	if affiliateID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing affiliate ID"})
		return
	}

	props, err := s.gracenoteClient.GetAffiliateProperties(c.Request.Context(), affiliateID, "en-us")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, props)
}

// handleClearCache clears the EPG cache
// POST /api/epg/cache/clear
func (s *EPGService) handleClearCache(c *gin.Context) {
	s.cache.Clear()
	c.JSON(http.StatusOK, gin.H{"message": "Cache cleared successfully"})
}

// handleCacheStats returns cache statistics
// GET /api/epg/cache/stats
func (s *EPGService) handleCacheStats(c *gin.Context) {
	stats := s.cache.Stats()
	c.JSON(http.StatusOK, stats)
}
