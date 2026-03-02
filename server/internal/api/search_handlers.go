package api

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/search"
)

// handleUniversalSearch handles GET /api/search
// Query parameters:
//   - q:      search query string (required)
//   - type:   comma-separated document types to filter by (file, group, media, channel, program)
//   - limit:  maximum number of results (default 25, max 200)
//   - offset: pagination offset (default 0)
func (s *Server) handleUniversalSearch(c *gin.Context) {
	if s.searchEngine == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Search engine is not initialized",
		})
		return
	}

	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Query parameter 'q' is required",
		})
		return
	}

	// Parse optional type filter.
	var types []string
	if typeParam := c.Query("type"); typeParam != "" {
		for _, t := range strings.Split(typeParam, ",") {
			t = strings.TrimSpace(t)
			switch t {
			case search.DocTypeFile, search.DocTypeGroup, search.DocTypeMedia, search.DocTypeChannel, search.DocTypeProgram:
				types = append(types, t)
			default:
				c.JSON(http.StatusBadRequest, gin.H{
					"error": "Invalid type filter: " + t,
					"valid": []string{search.DocTypeFile, search.DocTypeGroup, search.DocTypeMedia, search.DocTypeChannel, search.DocTypeProgram},
				})
				return
			}
		}
	}

	limit := 25
	if l := c.Query("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	offset := 0
	if o := c.Query("offset"); o != "" {
		if parsed, err := strconv.Atoi(o); err == nil && parsed >= 0 {
			offset = parsed
		}
	}

	results, err := s.searchEngine.Search(query, types, limit, offset)
	if err != nil {
		logger.Errorf("search: query failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Search query failed",
		})
		return
	}

	c.JSON(http.StatusOK, results)
}

// handleSearchReindex handles POST /admin/search/reindex
// Triggers a full rebuild of the search index from the database.
// This endpoint is restricted to admin users.
func (s *Server) handleSearchReindex(c *gin.Context) {
	if s.searchEngine == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Search engine is not initialized",
		})
		return
	}

	// Run reindex in the background so the request returns immediately.
	go func() {
		if err := s.searchEngine.RebuildIndex(); err != nil {
			logger.Errorf("search: reindex failed: %v", err)
		}
	}()

	c.JSON(http.StatusAccepted, gin.H{
		"message": "Search reindex started in background",
	})
}

// handleSearchStats handles GET /admin/search/stats
// Returns statistics about the search index.
// This endpoint is restricted to admin users.
func (s *Server) handleSearchStats(c *gin.Context) {
	if s.searchEngine == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error": "Search engine is not initialized",
		})
		return
	}

	stats := s.searchEngine.IndexStats()
	c.JSON(http.StatusOK, stats)
}
