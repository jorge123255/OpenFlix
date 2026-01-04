package api

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/livetv"
	"github.com/openflix/openflix-server/internal/models"
)

// ========== VOD Import Handlers ==========

// importXtreamVOD imports VOD movies from an Xtream source
// POST /api/livetv/xtream/sources/:id/import-vod
func (s *Server) importXtreamVOD(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	importer := livetv.NewVODImporter(s.db)
	result, err := importer.ImportXtreamVOD(uint(id))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// importXtreamSeries imports TV series from an Xtream source
// POST /api/livetv/xtream/sources/:id/import-series
func (s *Server) importXtreamSeries(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	importer := livetv.NewVODImporter(s.db)
	result, err := importer.ImportXtreamSeries(uint(id))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// importAllXtreamContent imports channels, VOD, and series from an Xtream source
// POST /api/livetv/xtream/sources/:id/import-all
func (s *Server) importAllXtreamContent(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	var source models.XtreamSource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source not found"})
		return
	}

	results := gin.H{}

	// Import channels if enabled
	if source.ImportLive {
		client := livetv.NewXtreamClient(s.db)
		added, updated, err := client.ImportChannels(uint(id))
		if err != nil {
			results["channels"] = gin.H{"error": err.Error()}
		} else {
			results["channels"] = gin.H{"added": added, "updated": updated}
		}
	}

	// Import VOD if enabled
	if source.ImportVOD && source.VODLibraryID != nil {
		importer := livetv.NewVODImporter(s.db)
		vodResult, err := importer.ImportXtreamVOD(uint(id))
		if err != nil {
			results["vod"] = gin.H{"error": err.Error()}
		} else {
			results["vod"] = vodResult
		}
	}

	// Import series if enabled
	if source.ImportSeries && source.SeriesLibraryID != nil {
		importer := livetv.NewVODImporter(s.db)
		seriesResult, err := importer.ImportXtreamSeries(uint(id))
		if err != nil {
			results["series"] = gin.H{"error": err.Error()}
		} else {
			results["series"] = seriesResult
		}
	}

	c.JSON(http.StatusOK, results)
}

// ========== Xtream Source Handlers ==========

// listXtreamSources lists all Xtream sources
// GET /api/livetv/xtream/sources
func (s *Server) listXtreamSources(c *gin.Context) {
	var sources []models.XtreamSource
	if err := s.db.Find(&sources).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list sources"})
		return
	}

	// Don't expose passwords in list
	for i := range sources {
		sources[i].Password = ""
	}

	c.JSON(http.StatusOK, gin.H{"sources": sources})
}

// getXtreamSource gets a single Xtream source by ID
// GET /api/livetv/xtream/sources/:id
func (s *Server) getXtreamSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	var source models.XtreamSource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source not found"})
		return
	}

	// Don't expose password
	source.Password = ""

	c.JSON(http.StatusOK, source)
}

// createXtreamSource creates a new Xtream source
// POST /api/livetv/xtream/sources
func (s *Server) createXtreamSource(c *gin.Context) {
	var req struct {
		Name            string `json:"name" binding:"required"`
		ServerURL       string `json:"serverUrl" binding:"required"`
		Username        string `json:"username" binding:"required"`
		Password        string `json:"password" binding:"required"`
		Enabled         *bool  `json:"enabled"`
		ImportLive      *bool  `json:"importLive"`
		ImportVOD       *bool  `json:"importVod"`
		ImportSeries    *bool  `json:"importSeries"`
		VODLibraryID    *uint  `json:"vodLibraryId"`
		SeriesLibraryID *uint  `json:"seriesLibraryId"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	source := models.XtreamSource{
		Name:            req.Name,
		ServerURL:       req.ServerURL,
		Username:        req.Username,
		Password:        req.Password,
		Enabled:         true,
		ImportLive:      true,
		VODLibraryID:    req.VODLibraryID,
		SeriesLibraryID: req.SeriesLibraryID,
	}

	if req.Enabled != nil {
		source.Enabled = *req.Enabled
	}
	if req.ImportLive != nil {
		source.ImportLive = *req.ImportLive
	}
	if req.ImportVOD != nil {
		source.ImportVOD = *req.ImportVOD
	}
	if req.ImportSeries != nil {
		source.ImportSeries = *req.ImportSeries
	}

	// Test connection first
	client := livetv.NewXtreamClient(s.db)
	authResp, err := client.Authenticate(&source)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Authentication failed: " + err.Error()})
		return
	}

	// Update source with account info
	if authResp.UserInfo.MaxConnections != "" {
		if maxConns, err := strconv.Atoi(authResp.UserInfo.MaxConnections); err == nil {
			source.MaxConnections = maxConns
		}
	}
	if authResp.UserInfo.ActiveCons != "" {
		if activeConns, err := strconv.Atoi(authResp.UserInfo.ActiveCons); err == nil {
			source.ActiveConns = activeConns
		}
	}

	if err := s.db.Create(&source).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create source"})
		return
	}

	// Don't return password
	source.Password = ""

	c.JSON(http.StatusCreated, source)
}

// updateXtreamSource updates an existing Xtream source
// PUT /api/livetv/xtream/sources/:id
func (s *Server) updateXtreamSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	var source models.XtreamSource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source not found"})
		return
	}

	var req struct {
		Name            *string `json:"name"`
		ServerURL       *string `json:"serverUrl"`
		Username        *string `json:"username"`
		Password        *string `json:"password"`
		Enabled         *bool   `json:"enabled"`
		ImportLive      *bool   `json:"importLive"`
		ImportVOD       *bool   `json:"importVod"`
		ImportSeries    *bool   `json:"importSeries"`
		VODLibraryID    *uint   `json:"vodLibraryId"`
		SeriesLibraryID *uint   `json:"seriesLibraryId"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Name != nil {
		source.Name = *req.Name
	}
	if req.ServerURL != nil {
		source.ServerURL = *req.ServerURL
	}
	if req.Username != nil {
		source.Username = *req.Username
	}
	if req.Password != nil && *req.Password != "" {
		source.Password = *req.Password
	}
	if req.Enabled != nil {
		source.Enabled = *req.Enabled
	}
	if req.ImportLive != nil {
		source.ImportLive = *req.ImportLive
	}
	if req.ImportVOD != nil {
		source.ImportVOD = *req.ImportVOD
	}
	if req.ImportSeries != nil {
		source.ImportSeries = *req.ImportSeries
	}
	if req.VODLibraryID != nil {
		source.VODLibraryID = req.VODLibraryID
	}
	if req.SeriesLibraryID != nil {
		source.SeriesLibraryID = req.SeriesLibraryID
	}

	if err := s.db.Save(&source).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update source"})
		return
	}

	source.Password = ""
	c.JSON(http.StatusOK, source)
}

// deleteXtreamSource deletes an Xtream source
// DELETE /api/livetv/xtream/sources/:id
func (s *Server) deleteXtreamSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	// Delete associated channels
	if err := s.db.Where("xtream_source_id = ?", id).Delete(&models.Channel{}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete associated channels"})
		return
	}

	// Delete the source
	if err := s.db.Delete(&models.XtreamSource{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete source"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Source deleted"})
}

// testXtreamSource tests an Xtream source connection
// POST /api/livetv/xtream/sources/:id/test
func (s *Server) testXtreamSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	var source models.XtreamSource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source not found"})
		return
	}

	client := livetv.NewXtreamClient(s.db)
	authResp, err := client.Authenticate(&source)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"userInfo": gin.H{
			"username":       authResp.UserInfo.Username,
			"status":         authResp.UserInfo.Status,
			"expDate":        authResp.UserInfo.ExpDate,
			"maxConnections": authResp.UserInfo.MaxConnections,
			"activeConns":    authResp.UserInfo.ActiveCons,
		},
		"serverInfo": gin.H{
			"url":      authResp.ServerInfo.URL,
			"port":     authResp.ServerInfo.Port,
			"timezone": authResp.ServerInfo.Timezone,
		},
	})
}

// refreshXtreamSource refreshes channels from an Xtream source
// POST /api/livetv/xtream/sources/:id/refresh
func (s *Server) refreshXtreamSource(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	var source models.XtreamSource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source not found"})
		return
	}

	client := livetv.NewXtreamClient(s.db)
	added, updated, err := client.ImportChannels(uint(id))
	if err != nil {
		// Update last error
		source.LastError = err.Error()
		s.db.Save(&source)

		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"added":   added,
		"updated": updated,
		"total":   added + updated,
	})
}

// parseXtreamFromM3U parses Xtream credentials from an M3U URL
// POST /api/livetv/xtream/parse-m3u
func (s *Server) parseXtreamFromM3U(c *gin.Context) {
	var req struct {
		URL string `json:"url" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	client := livetv.NewXtreamClient(s.db)
	source, err := client.ParseCredentialsFromM3U(req.URL)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"error":   err.Error(),
		})
		return
	}

	// Test connection
	authResp, err := client.Authenticate(source)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"success":   false,
			"error":     "Credentials parsed but authentication failed: " + err.Error(),
			"serverUrl": source.ServerURL,
			"username":  source.Username,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success":   true,
		"serverUrl": source.ServerURL,
		"username":  source.Username,
		"name":      source.Name,
		"userInfo": gin.H{
			"status":         authResp.UserInfo.Status,
			"expDate":        authResp.UserInfo.ExpDate,
			"maxConnections": authResp.UserInfo.MaxConnections,
		},
	})
}

// getXtreamCategories gets categories from an Xtream source
// GET /api/livetv/xtream/sources/:id/categories
func (s *Server) getXtreamCategories(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	var source models.XtreamSource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source not found"})
		return
	}

	categoryType := c.DefaultQuery("type", "live")
	client := livetv.NewXtreamClient(s.db)

	var categories []livetv.XtreamCategory
	switch categoryType {
	case "live":
		categories, err = client.GetLiveCategories(&source)
	case "vod":
		categories, err = client.GetVODCategories(&source)
	case "series":
		categories, err = client.GetSeriesCategories(&source)
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid category type. Use: live, vod, or series"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"type":       categoryType,
		"categories": categories,
	})
}

// getXtreamStreams gets streams from an Xtream source
// GET /api/livetv/xtream/sources/:id/streams
func (s *Server) getXtreamStreams(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid source ID"})
		return
	}

	var source models.XtreamSource
	if err := s.db.First(&source, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Source not found"})
		return
	}

	streamType := c.DefaultQuery("type", "live")
	categoryID := c.Query("category_id")
	client := livetv.NewXtreamClient(s.db)

	switch streamType {
	case "live":
		streams, err := client.GetLiveStreams(&source, categoryID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"type":    "live",
			"streams": streams,
			"count":   len(streams),
		})

	case "vod":
		streams, err := client.GetVODStreams(&source, categoryID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"type":    "vod",
			"streams": streams,
			"count":   len(streams),
		})

	case "series":
		series, err := client.GetSeries(&source, categoryID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"type":   "series",
			"series": series,
			"count":  len(series),
		})

	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid stream type. Use: live, vod, or series"})
	}
}
