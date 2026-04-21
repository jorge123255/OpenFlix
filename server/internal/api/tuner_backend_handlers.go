package api

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime"
	"net"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/openflix/openflix-server/internal/tuner"
	"gorm.io/gorm"
)

func normalizeProviderAccountPathID(raw string) string {
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return ""
	}
	if strings.HasPrefix(trimmed, "account-") {
		trimmed = strings.TrimPrefix(trimmed, "account-")
	}
	return trimmed
}

type espnPlaybackModeResponse struct {
	Label string `json:"label,omitempty"`
	Type  string `json:"type,omitempty"`
}

type espnPlaybackInfoResponse struct {
	ResourceID        string                     `json:"resourceId,omitempty"`
	DeeplinkID        string                     `json:"deeplinkId,omitempty"`
	SupportsLive      bool                       `json:"supportsLive,omitempty"`
	SupportsStartover bool                       `json:"supportsStartover,omitempty"`
	SupportsReplay    bool                       `json:"supportsReplay,omitempty"`
	Modes             []espnPlaybackModeResponse `json:"modes,omitempty"`
}

type espnArtworkResponse struct {
	Background178URL     string `json:"background178Url,omitempty"`
	Thumbnail178URL      string `json:"thumbnail178Url,omitempty"`
	Tile178URL           string `json:"tile178Url,omitempty"`
	TitleTreatment178URL string `json:"titleTreatment178Url,omitempty"`
}

type espnBrowseActionTargetResponse struct {
	BrowseID   string `json:"browseId,omitempty"`
	DeeplinkID string `json:"deeplinkId,omitempty"`
	PageID     string `json:"pageId,omitempty"`
	SetID      string `json:"setId,omitempty"`
}

type espnBrowseActionsResponse struct {
	Browse *espnBrowseActionTargetResponse `json:"browse,omitempty"`
}

type espnBrowseItemResponse struct {
	ID          string                     `json:"id,omitempty"`
	Title       string                     `json:"title,omitempty"`
	Subtitle    string                     `json:"subtitle,omitempty"`
	Description string                     `json:"description,omitempty"`
	ImageURL    string                     `json:"imageUrl,omitempty"`
	Artwork     *espnArtworkResponse       `json:"artwork,omitempty"`
	State       string                     `json:"state,omitempty"`
	Live        bool                       `json:"live,omitempty"`
	Upcoming    bool                       `json:"upcoming,omitempty"`
	StartTime   string                     `json:"startTime,omitempty"`
	EndTime     string                     `json:"endTime,omitempty"`
	Playback    *espnPlaybackInfoResponse  `json:"playback,omitempty"`
	Actions     *espnBrowseActionsResponse `json:"actions,omitempty"`
	Badges      []string                   `json:"badges,omitempty"`
	League      string                     `json:"league,omitempty"`
	Sport       string                     `json:"sport,omitempty"`
	Type        string                     `json:"type,omitempty"`
	Success     bool                       `json:"success,omitempty"`
}

type espnContainerParamsResponse struct {
	LayoutID             string `json:"layoutId,omitempty"`
	PageID               string `json:"pageId,omitempty"`
	PageResolutionID     string `json:"pageResolutionId,omitempty"`
	PageStyle            string `json:"pageStyle,omitempty"`
	SetResolutionID      string `json:"setResolutionId,omitempty"`
	SetStyle             string `json:"setStyle,omitempty"`
	SkipEligibilityCheck string `json:"skipEligibilityCheck,omitempty"`
}

type espnBrowseContainerResponse struct {
	ID     string                       `json:"id,omitempty"`
	Title  string                       `json:"title,omitempty"`
	Type   string                       `json:"type,omitempty"`
	Layout string                       `json:"layout,omitempty"`
	Style  string                       `json:"style,omitempty"`
	Items  []espnBrowseItemResponse     `json:"items,omitempty"`
	Params *espnContainerParamsResponse `json:"params,omitempty"`
}

type espnBrowseResponse struct {
	Success    bool                          `json:"success,omitempty"`
	Title      string                        `json:"title,omitempty"`
	PageID     string                        `json:"pageId,omitempty"`
	Style      string                        `json:"style,omitempty"`
	Containers []espnBrowseContainerResponse `json:"containers,omitempty"`
}

type espnSetResponse struct {
	Success   bool                         `json:"success,omitempty"`
	Container *espnBrowseContainerResponse `json:"container,omitempty"`
}

type espnNormalizedPlayContext struct {
	ResourceID       string `json:"resourceId,omitempty"`
	ItemID           string `json:"itemId,omitempty"`
	DeeplinkID       string `json:"deeplinkId,omitempty"`
	SetID            string `json:"setId,omitempty"`
	PageID           string `json:"pageId,omitempty"`
	LayoutID         string `json:"layoutId,omitempty"`
	PageResolutionID string `json:"pageResolutionId,omitempty"`
	SetResolutionID  string `json:"setResolutionId,omitempty"`
	PageStyle        string `json:"pageStyle,omitempty"`
	SetStyle         string `json:"setStyle,omitempty"`
}

type espnNormalizedItemResponse struct {
	ID          string                    `json:"id,omitempty"`
	Title       string                    `json:"title,omitempty"`
	Subtitle    string                    `json:"subtitle,omitempty"`
	Description string                    `json:"description,omitempty"`
	ImageURL    string                    `json:"imageUrl,omitempty"`
	Artwork     *espnArtworkResponse      `json:"artwork,omitempty"`
	State       string                    `json:"state,omitempty"`
	Live        bool                      `json:"live,omitempty"`
	Upcoming    bool                      `json:"upcoming,omitempty"`
	StartTime   string                    `json:"startTime,omitempty"`
	EndTime     string                    `json:"endTime,omitempty"`
	Playback    *espnPlaybackInfoResponse `json:"playback,omitempty"`
	Badges      []string                  `json:"badges,omitempty"`
	League      string                    `json:"league,omitempty"`
	Sport       string                    `json:"sport,omitempty"`
	Type        string                    `json:"type,omitempty"`
	PlayContext espnNormalizedPlayContext `json:"playContext"`
	MatchScore  int                       `json:"matchScore,omitempty"`
}

type espnNormalizedRailResponse struct {
	ID     string                       `json:"id,omitempty"`
	Title  string                       `json:"title,omitempty"`
	Type   string                       `json:"type,omitempty"`
	Layout string                       `json:"layout,omitempty"`
	Style  string                       `json:"style,omitempty"`
	Params *espnContainerParamsResponse `json:"params,omitempty"`
	Items  []espnNormalizedItemResponse `json:"items,omitempty"`
}

type espnHubResponse struct {
	Success      bool                         `json:"success"`
	Title        string                       `json:"title,omitempty"`
	PageID       string                       `json:"pageId,omitempty"`
	Style        string                       `json:"style,omitempty"`
	FocusQuery   string                       `json:"focusQuery,omitempty"`
	FeaturedItem *espnNormalizedItemResponse  `json:"featuredItem,omitempty"`
	Rails        []espnNormalizedRailResponse `json:"rails"`
}

type directvImportRequest struct {
	Title           string   `json:"title"`
	Subtitle        string   `json:"subtitle"`
	Description     string   `json:"description"`
	Summary         string   `json:"summary"`
	ChannelName     string   `json:"channelName"`
	ChannelLogo     string   `json:"channelLogo"`
	StartTime       string   `json:"startTime"`
	EndTime         string   `json:"endTime"`
	SourceType      string   `json:"sourceType"`
	SourceName      string   `json:"sourceName"`
	ProviderID      string   `json:"providerId"`
	ProviderName    string   `json:"providerName"`
	AccountID       string   `json:"accountId"`
	AccountName     string   `json:"accountName"`
	AccountIndex    int      `json:"accountIndex"`
	RecordID        string   `json:"recordId"`
	ResourceID      string   `json:"resourceId"`
	CanonicalID     string   `json:"canonicalId"`
	SeriesID        string   `json:"seriesId"`
	EpisodeNum      string   `json:"episodeNum"`
	SeasonNumber    *int     `json:"seasonNumber"`
	EpisodeNumber   *int     `json:"episodeNumber"`
	Genres          []string `json:"genres"`
	ContentRating   string   `json:"contentRating"`
	OriginalAirDate string   `json:"originalAirDate"`
	Year            *int     `json:"year"`
	IsMovie         bool     `json:"isMovie"`
	Rating          *float64 `json:"rating"`
	CleanupUpstream bool     `json:"cleanupUpstream"`
}

type tunerBackendRecordResponse struct {
	ID              uint                    `json:"id"`
	BackendID       string                  `json:"backendId"`
	Name            string                  `json:"name"`
	Type            string                  `json:"type"`
	Host            string                  `json:"host"`
	Port            int                     `json:"port"`
	BaseURL         string                  `json:"baseUrl"`
	Version         string                  `json:"version,omitempty"`
	MachineID       string                  `json:"machineId,omitempty"`
	Healthy         bool                    `json:"healthy"`
	Active          bool                    `json:"active"`
	Source          string                  `json:"source"`
	Endpoints       map[string]string       `json:"endpoints,omitempty"`
	Providers       []tuner.BackendProvider `json:"providers,omitempty"`
	LastSeenAt      *time.Time              `json:"lastSeenAt,omitempty"`
	LastConnectedAt *time.Time              `json:"lastConnectedAt,omitempty"`
	LastCheckedAt   *time.Time              `json:"lastCheckedAt,omitempty"`
	LastError       string                  `json:"lastError,omitempty"`
	CreatedAt       time.Time               `json:"createdAt"`
	UpdatedAt       time.Time               `json:"updatedAt"`
}

func (s *Server) listTunerBackends(c *gin.Context) {
	var backends []models.TunerBackend
	if err := s.db.Order("active DESC, updated_at DESC").Find(&backends).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch tuner backends"})
		return
	}

	ctx, cancel := context.WithTimeout(c.Request.Context(), 5*time.Second)
	defer cancel()
	responses := make([]tunerBackendRecordResponse, 0, len(backends))
	for i := range backends {
		refreshed, _ := s.refreshTunerBackendHealth(ctx, &backends[i])
		responses = append(responses, s.serializeTunerBackend(*refreshed))
	}

	c.JSON(http.StatusOK, gin.H{"backends": responses, "count": len(responses)})
}

func (s *Server) discoverTunerBackends(c *gin.Context) {
	client := tuner.NewBackendDiscoveryClient()
	ctx, cancel := context.WithTimeout(c.Request.Context(), 8*time.Second)
	defer cancel()
	found, err := client.Discover(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Discovery failed", "message": err.Error()})
		return
	}

	responses := make([]tunerBackendRecordResponse, 0, len(found))
	for _, backend := range found {
		row, err := s.upsertTunerBackend(backend, "discovered", false, false)
		if err != nil {
			logger.Warnf("failed to persist discovered tuner backend %s: %v", backend.BaseURL, err)
			continue
		}
		responses = append(responses, s.serializeTunerBackend(*row))
	}
	c.JSON(http.StatusOK, gin.H{"discovered": responses, "count": len(responses)})
}

func (s *Server) addTunerBackend(c *gin.Context) {
	var req struct {
		Host     string `json:"host"`
		Port     int    `json:"port"`
		BaseURL  string `json:"baseUrl"`
		Name     string `json:"name"`
		Activate *bool  `json:"activate"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON body"})
		return
	}

	input := strings.TrimSpace(req.BaseURL)
	if input == "" && strings.TrimSpace(req.Host) != "" {
		host := strings.TrimSpace(req.Host)
		if strings.Contains(host, "://") {
			input = host
		} else if req.Port > 0 {
			input = fmt.Sprintf("http://%s:%d", host, req.Port)
		} else {
			input = host
		}
	}
	if input == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "host or baseUrl is required"})
		return
	}

	client := tuner.NewBackendDiscoveryClient()
	ctx, cancel := context.WithTimeout(c.Request.Context(), 8*time.Second)
	defer cancel()

	validated, err := client.Probe(ctx, input)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to validate tuner backend", "message": err.Error()})
		return
	}
	if req.Name != "" {
		validated.Name = req.Name
	}

	activate := req.Activate == nil || *req.Activate
	if !activate {
		row, saveErr := s.upsertTunerBackend(*validated, "manual", false, false)
		if saveErr != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save tuner backend", "message": saveErr.Error()})
			return
		}
		c.JSON(http.StatusCreated, gin.H{"backend": s.serializeTunerBackend(*row), "validated": true, "connected": false})
		return
	}

	connected, err := client.Connect(ctx, validated.BaseURL, nil)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to connect tuner backend", "message": err.Error()})
		return
	}
	if req.Name != "" {
		connected.Name = req.Name
	}
	row, saveErr := s.upsertTunerBackend(*connected, "manual", true, true)
	if saveErr != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save tuner backend", "message": saveErr.Error()})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"backend": s.serializeTunerBackend(*row), "validated": true, "connected": true})
}

func (s *Server) getActiveTunerBackend(c *gin.Context) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}

	healthCtx, healthCancel := context.WithTimeout(c.Request.Context(), 3*time.Second)
	backend, _ = s.refreshTunerBackendHealth(healthCtx, backend)
	healthCancel()

	enrichCtx, enrichCancel := context.WithTimeout(c.Request.Context(), 12*time.Second)
	defer enrichCancel()
	if enriched, enrichErr := s.enrichActiveBackendProviders(enrichCtx, backend); enrichErr == nil {
		backend = enriched
	} else {
		logger.Warnf("active tuner backend provider enrichment failed: %v", enrichErr)
	}
	c.JSON(http.StatusOK, gin.H{"backend": s.serializeTunerBackend(*backend)})
}

func (s *Server) selectTunerBackend(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Backend ID is required"})
		return
	}

	var existing models.TunerBackend
	if err := s.db.Where("backend_id = ?", id).First(&existing).Error; err != nil {
		status := http.StatusInternalServerError
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		c.JSON(status, gin.H{"error": "Failed to select tuner backend", "message": err.Error()})
		return
	}

	client := tuner.NewBackendDiscoveryClient()
	ctx, cancel := context.WithTimeout(c.Request.Context(), 8*time.Second)
	defer cancel()
	connected, err := client.Connect(ctx, existing.BaseURL, nil)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to connect tuner backend", "message": err.Error()})
		return
	}
	if existing.Name != "" {
		connected.Name = existing.Name
	}
	row, saveErr := s.upsertTunerBackend(*connected, existing.Source, true, true)
	if saveErr != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to select tuner backend", "message": saveErr.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"backend": s.serializeTunerBackend(*row), "message": "Active tuner backend updated"})
}

func (s *Server) removeTunerBackend(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Backend ID is required"})
		return
	}

	var existing models.TunerBackend
	if err := s.db.Where("backend_id = ?", id).First(&existing).Error; err != nil {
		status := http.StatusInternalServerError
		if errors.Is(err, gorm.ErrRecordNotFound) {
			status = http.StatusNotFound
		}
		c.JSON(status, gin.H{"error": "Tuner backend not found"})
		return
	}

	res := s.db.Delete(&existing)
	if res.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete tuner backend", "message": res.Error.Error()})
		return
	}
	if res.RowsAffected == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "Tuner backend not found"})
		return
	}

	// Clear live TV caches so active-backend-derived channels and guide rows disappear immediately.
	if s.guideCache != nil {
		s.guideCache.InvalidateAll()
	}

	c.JSON(http.StatusOK, gin.H{
		"message":      "Tuner backend removed",
		"backendId":    existing.BackendID,
		"wasActive":    existing.Active,
		"baseUrl":      existing.BaseURL,
		"channelsGone": existing.Active,
	})
}

func (s *Server) proxyActiveTunerBackendProviders(c *gin.Context) {
	s.proxyActiveTunerBackendJSON(c, []string{"providers"}, "")
}

func (s *Server) proxyActiveTunerBackendLineup(c *gin.Context) {
	s.proxyActiveTunerBackendJSON(c, []string{"channels", "lineup"}, "")
}

func (s *Server) proxyActiveTunerBackendGuide(c *gin.Context) {
	s.proxyActiveTunerBackendJSON(c, []string{"guide"}, "")
}

func (s *Server) proxyActiveTunerBackendDVR(c *gin.Context) {
	s.proxyActiveTunerBackendJSON(c, []string{"dvr"}, "")
}

func (s *Server) proxyActiveTunerBackendStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSON(c, []string{"status"}, "/api/tuner/status")
}

func (s *Server) proxyActiveTunerBackendTunerStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSON(c, []string{"tunerStatus", "status"}, "/api/tuner/status")
}

func (s *Server) getActiveTunerBackendConfig(c *gin.Context) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}
	client := tuner.NewBackendDiscoveryClient()
	var payload any
	if err := client.FetchJSON(c.Request.Context(), backend.BaseURL, s.endpointFor(*backend, []string{"tunerConfig", "config"}, "/api/tuner/config"), c.Request.URL.Query(), &payload); err != nil {
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch tuner backend config", "message": err.Error()})
		return
	}
	s.markTunerBackendHealthy(backend)
	c.JSON(http.StatusOK, payload)
}

func (s *Server) getActiveTunerBackendProviderTokenStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/token-status", nil)
}

func (s *Server) getActiveTunerBackendTVEPlaylist(c *gin.Context) {
	s.proxyActiveTunerBackendTVEPlaylistAtPath(c, fmt.Sprintf("/tve/%s/playlist.m3u", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendTVEEPG(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, fmt.Sprintf("/tve/%s/epg.xml", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendTVEEPGStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/tve/%s/epg/status", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) postActiveTunerBackendTVEEPGRefresh(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/tve/%s/epg/refresh", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendTVECombinedPlaylist(c *gin.Context) {
	s.proxyActiveTunerBackendTVEPlaylistAtPath(c, "/tve/combined/playlist.m3u")
}

func (s *Server) getActiveTunerBackendTVECombinedEPG(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, "/tve/combined/epg.xml")
}

func (s *Server) getActiveTunerBackendTVEDirectvChannels(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/tve/directv/channels", nil)
}

func (s *Server) getActiveTunerBackendTVEPhiloChannels(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/tve/philo/channels", nil)
}

func (s *Server) getActiveTunerBackendTVEFuboNonDRMPlaylist(c *gin.Context) {
	s.proxyActiveTunerBackendTVEPlaylistAtPath(c, "/tve/fubo/nondrm.m3u")
}

func (s *Server) getActiveTunerBackendTVEFuboDRMStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/tve/fubo/drm-status", nil)
}

func (s *Server) postActiveTunerBackendTVEFuboDRMScan(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/tve/fubo/drm-scan")
}

func (s *Server) getActiveTunerBackendTVEFuboDebugAPI(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, fmt.Sprintf("/tve/fubo/debug-api/%s", url.PathEscape(strings.TrimSpace(c.Param("channelId")))))
}

func (s *Server) getActiveTunerBackendTVEFuboTestAPIStream(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, fmt.Sprintf("/tve/fubo/test-api-stream/%s", url.PathEscape(strings.TrimSpace(c.Param("channelId")))))
}

func (s *Server) getActiveTunerBackendTVEFuboTestDRM(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, fmt.Sprintf("/tve/fubo/test-drm/%s", url.PathEscape(strings.TrimSpace(c.Param("channelId")))))
}

func (s *Server) getActiveTunerBackendTVEFuboTestPlay(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, fmt.Sprintf("/tve/fubo/test-play/%s", url.PathEscape(strings.TrimSpace(c.Param("channelId")))))
}

func (s *Server) getActiveTunerBackendTVEAccountPlaylist(c *gin.Context) {
	s.proxyActiveTunerBackendTVEPlaylistAtPath(c, fmt.Sprintf("/tve/%s/accounts/%s/playlist.m3u", url.PathEscape(strings.TrimSpace(c.Param("providerId"))), url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) getActiveTunerBackendTVEAccountEPG(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, fmt.Sprintf("/tve/%s/accounts/%s/epg.xml", url.PathEscape(strings.TrimSpace(c.Param("providerId"))), url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) getActiveTunerBackendSwaggerJSON(c *gin.Context) {
	s.proxyActiveTunerBackendFileAtPath(c, "/api/swagger.json")
}

func (s *Server) getActiveTunerBackendStream(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, fmt.Sprintf("/stream/%s", url.PathEscape(strings.TrimSpace(c.Param("channelId")))))
}

func (s *Server) getActiveTunerBackendSwaggerDocs(c *gin.Context) {
	const activeBackendSwaggerUIHTML = `<!DOCTYPE html>
<html>
<head>
  <title>OpenFlix Active DVR-Tuner API Documentation</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: '/api/tuner-backends/active/swagger.json',
      dom_id: '#swagger-ui'
    });
  </script>
</body>
</html>`
	c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(activeBackendSwaggerUIHTML))
}

func (s *Server) getActiveTunerBackendVODProviders(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/vod/providers", nil)
}

func (s *Server) getActiveTunerBackendVODStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/vod/status", nil)
}

func (s *Server) saveActiveTunerBackendVODSettings(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/vod/settings")
}

func (s *Server) postActiveTunerBackendVODToggle(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/vod/toggle")
}

func (s *Server) postActiveTunerBackendVODProviderToggle(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/vod/providers/%s/toggle", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendVODProviderRefresh(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/vod/providers/%s/refresh", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendVODPriority(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/vod/priority", nil)
}

func (s *Server) saveActiveTunerBackendVODPriority(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPut, "/api/vod/priority")
}

func (s *Server) postActiveTunerBackendVODPriorityReset(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/vod/priority/reset")
}

func (s *Server) getActiveTunerBackendProviderPriority(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/priority", nil)
}

func (s *Server) saveActiveTunerBackendProviderPriority(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPut, "/api/providers/priority")
}

func (s *Server) postActiveTunerBackendProviderPriorityApply(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/priority/apply")
}

func (s *Server) getActiveTunerBackendProvider(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) getActiveTunerBackendProviderStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/status", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) getActiveTunerBackendProviderSettings(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/settings", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) saveActiveTunerBackendProviderSettings(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/settings", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendProviderCredentials(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/credentials", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) postActiveTunerBackendProviderToggle(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/toggle", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderRefresh(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/refresh", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendProviderRefreshInterval(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/refresh-interval", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) saveActiveTunerBackendProviderRefreshInterval(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPut, fmt.Sprintf("/api/providers/%s/refresh-interval", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendProviderAutoRefresh(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/auto-refresh", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) postActiveTunerBackendProviderAutoRefresh(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/auto-refresh", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderLogout(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/logout", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderRefreshToken(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/refresh-token", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderRefreshChannels(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/refresh-channels", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendYouTubeTVChannels(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/youtubetv/channels", nil)
}

func (s *Server) postActiveTunerBackendYouTubeTVCaptureCookies(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/youtubetv/capture-cookies")
}

func (s *Server) postActiveTunerBackendYouTubeTVRefreshEPG(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/youtubetv/refresh-epg")
}

func (s *Server) postActiveTunerBackendHuluRefreshEPG(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/hulu/refresh-epg")
}

func (s *Server) postActiveTunerBackendESPNRefreshEPG(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/espn/refresh-epg")
}

func (s *Server) getActiveTunerBackendESPNBrowse(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/espn/browse", nil)
}

func (s *Server) getActiveTunerBackendESPNBrowsePage(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/espn/browse/page/%s", url.PathEscape(strings.TrimSpace(c.Param("pageId")))), nil)
}

func (s *Server) getActiveTunerBackendESPNBrowseSet(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/espn/browse/set/%s", url.PathEscape(strings.TrimSpace(c.Param("setId")))), nil)
}

func (s *Server) getActiveTunerBackendESPNEvent(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/espn/events/%s", url.PathEscape(strings.TrimSpace(c.Param("itemId")))), nil)
}

func (s *Server) getActiveTunerBackendESPNItem(c *gin.Context) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}

	itemID := strings.TrimSpace(c.Param("itemId"))
	if itemID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "itemId is required"})
		return
	}

	client := tuner.NewBackendDiscoveryClient()
	ctx, cancel := context.WithTimeout(c.Request.Context(), 15*time.Second)
	defer cancel()

	var event espnBrowseItemResponse
	if err := client.FetchJSON(ctx, backend.BaseURL, fmt.Sprintf("/api/providers/espn/events/%s", url.PathEscape(itemID)), nil, &event); err != nil {
		hub, hubErr := s.buildESPNHubResponse(ctx, client, backend, strings.TrimSpace(c.Query("q")))
		if hubErr != nil {
			s.markTunerBackendError(backend, err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch ESPN item", "message": err.Error()})
			return
		}
		if item := findESPNNormalizedItem(itemID, hub.Rails); item != nil {
			s.markTunerBackendHealthy(backend)
			c.JSON(http.StatusOK, gin.H{
				"success": true,
				"source":  "hub-fallback",
				"item":    *item,
			})
			return
		}
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch ESPN item", "message": err.Error()})
		return
	}

	container := espnBrowseContainerResponse{
		ID:     strings.TrimSpace(c.Query("setId")),
		Layout: strings.TrimSpace(c.Query("layoutId")),
		Params: &espnContainerParamsResponse{
			PageID:           strings.TrimSpace(c.Query("pageId")),
			PageResolutionID: strings.TrimSpace(c.Query("pageResolutionId")),
			PageStyle:        strings.TrimSpace(c.Query("pageStyle")),
			SetResolutionID:  strings.TrimSpace(c.Query("setResolutionId")),
			SetStyle:         strings.TrimSpace(c.Query("setStyle")),
		},
	}
	if container.Params.PageID == "" &&
		container.Params.PageResolutionID == "" &&
		container.Params.PageStyle == "" &&
		container.Params.SetResolutionID == "" &&
		container.Params.SetStyle == "" &&
		container.Layout == "" &&
		container.ID == "" {
		container.Params = nil
	}

	normalized := buildESPNNormalizedItem(event, container, strings.TrimSpace(c.Query("q")))
	normalized.PlayContext.ItemID = espnFirstNonEmpty(normalized.PlayContext.ItemID, itemID)
	s.markTunerBackendHealthy(backend)
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"source":  "event",
		"item":    normalized,
	})
}

func (s *Server) getActiveTunerBackendESPNPlayStream(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, "/api/providers/espn/play/stream")
}

func normalizeESPNSearchText(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	if value == "" {
		return ""
	}
	var b strings.Builder
	lastSpace := false
	for _, r := range value {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') {
			b.WriteRune(r)
			lastSpace = false
			continue
		}
		if !lastSpace {
			b.WriteByte(' ')
			lastSpace = true
		}
	}
	return strings.TrimSpace(b.String())
}

func deriveESPNItemID(item espnBrowseItemResponse) string {
	for _, candidate := range []string{
		strings.TrimPrefix(strings.TrimSpace(item.Playback.GetDeeplinkID()), "entity-"),
		strings.TrimPrefix(strings.TrimSpace(item.Actions.GetBrowseDeeplinkID()), "entity-"),
		strings.TrimPrefix(strings.TrimSpace(item.ID), "entity-"),
	} {
		if candidate != "" {
			return candidate
		}
	}
	return ""
}

func scoreESPNItemMatch(query string, parts ...string) int {
	normalizedQuery := normalizeESPNSearchText(query)
	if normalizedQuery == "" {
		return 0
	}
	normalizedHaystack := normalizeESPNSearchText(strings.Join(parts, " "))
	if normalizedHaystack == "" {
		return 0
	}
	if normalizedHaystack == normalizedQuery {
		return 100
	}
	if strings.Contains(normalizedHaystack, normalizedQuery) {
		return 80
	}
	score := 0
	for _, term := range strings.Fields(normalizedQuery) {
		if strings.Contains(normalizedHaystack, term) {
			score += 12
		}
	}
	return score
}

func (p *espnPlaybackInfoResponse) GetDeeplinkID() string {
	if p == nil {
		return ""
	}
	return p.DeeplinkID
}

func (a *espnBrowseActionsResponse) GetBrowseDeeplinkID() string {
	if a == nil || a.Browse == nil {
		return ""
	}
	return a.Browse.DeeplinkID
}

func buildESPNNormalizedItem(item espnBrowseItemResponse, rail espnBrowseContainerResponse, query string) espnNormalizedItemResponse {
	return espnNormalizedItemResponse{
		ID:          item.ID,
		Title:       item.Title,
		Subtitle:    item.Subtitle,
		Description: item.Description,
		ImageURL:    item.ImageURL,
		Artwork:     item.Artwork,
		State:       item.State,
		Live:        item.Live,
		Upcoming:    item.Upcoming,
		StartTime:   item.StartTime,
		EndTime:     item.EndTime,
		Playback:    item.Playback,
		Badges:      item.Badges,
		League:      item.League,
		Sport:       item.Sport,
		Type:        item.Type,
		PlayContext: espnNormalizedPlayContext{
			ResourceID:       item.Playback.GetResourceID(),
			ItemID:           deriveESPNItemID(item),
			DeeplinkID:       espnFirstNonEmpty(item.Playback.GetDeeplinkID(), item.Actions.GetBrowseDeeplinkID()),
			SetID:            rail.ID,
			PageID:           rail.Params.GetPageID(),
			LayoutID:         rail.Params.GetLayoutID(),
			PageResolutionID: rail.Params.GetPageResolutionID(),
			SetResolutionID:  rail.Params.GetSetResolutionID(),
			PageStyle:        rail.Params.GetPageStyle(),
			SetStyle:         rail.Params.GetSetStyle(),
		},
		MatchScore: scoreESPNItemMatch(query, item.Title, item.Subtitle, item.Description, item.League, item.Sport),
	}
}

func findESPNNormalizedItem(itemID string, rails []espnNormalizedRailResponse) *espnNormalizedItemResponse {
	normalizedID := normalizeESPNItemLookupKey(itemID)
	if normalizedID == "" {
		return nil
	}
	for _, rail := range rails {
		for _, item := range rail.Items {
			for _, candidate := range []string{
				item.ID,
				item.PlayContext.ItemID,
				item.PlayContext.DeeplinkID,
				strings.TrimPrefix(item.PlayContext.DeeplinkID, "entity-"),
			} {
				if normalizeESPNItemLookupKey(candidate) == normalizedID {
					copy := item
					return &copy
				}
			}
		}
	}
	return nil
}

func normalizeESPNItemLookupKey(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return ""
	}
	value = strings.TrimPrefix(value, "entity-")
	return strings.ToLower(value)
}

func espnFirstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}

func (p *espnPlaybackInfoResponse) GetResourceID() string {
	if p == nil {
		return ""
	}
	return p.ResourceID
}

func (p *espnContainerParamsResponse) GetPageID() string {
	if p == nil {
		return ""
	}
	return p.PageID
}

func (p *espnContainerParamsResponse) GetLayoutID() string {
	if p == nil {
		return ""
	}
	return p.LayoutID
}

func (p *espnContainerParamsResponse) GetPageResolutionID() string {
	if p == nil {
		return ""
	}
	return p.PageResolutionID
}

func (p *espnContainerParamsResponse) GetSetResolutionID() string {
	if p == nil {
		return ""
	}
	return p.SetResolutionID
}

func (p *espnContainerParamsResponse) GetPageStyle() string {
	if p == nil {
		return ""
	}
	return p.PageStyle
}

func (p *espnContainerParamsResponse) GetSetStyle() string {
	if p == nil {
		return ""
	}
	return p.SetStyle
}

func (s *Server) getActiveTunerBackendESPNHub(c *gin.Context) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}

	client := tuner.NewBackendDiscoveryClient()
	ctx, cancel := context.WithTimeout(c.Request.Context(), 20*time.Second)
	defer cancel()

	hub, err := s.buildESPNHubResponse(ctx, client, backend, strings.TrimSpace(c.Query("q")))
	if err != nil {
		s.markTunerBackendError(backend, err)
		if strings.Contains(err.Error(), "browse page") {
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch ESPN browse page", "message": err.Error()})
			return
		}
		if strings.Contains(err.Error(), "browse set") {
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch ESPN browse set", "message": err.Error()})
			return
		}
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch ESPN browse", "message": err.Error()})
		return
	}

	s.markTunerBackendHealthy(backend)
	c.JSON(http.StatusOK, hub)
}

func (s *Server) buildESPNHubResponse(ctx context.Context, client *tuner.BackendDiscoveryClient, backend *models.TunerBackend, focusQuery string) (espnHubResponse, error) {
	var browse espnBrowseResponse
	if err := client.FetchJSON(ctx, backend.BaseURL, "/api/providers/espn/browse", nil, &browse); err != nil {
		return espnHubResponse{}, err
	}

	pageID := strings.TrimSpace(browse.PageID)
	var page espnBrowseResponse
	if pageID != "" {
		if err := client.FetchJSON(ctx, backend.BaseURL, fmt.Sprintf("/api/providers/espn/browse/page/%s", url.PathEscape(pageID)), nil, &page); err != nil {
			return espnHubResponse{}, fmt.Errorf("browse page: %w", err)
		}
	}

	containers := page.Containers
	if len(containers) == 0 {
		containers = browse.Containers
	}

	rails := make([]espnNormalizedRailResponse, 0, len(containers))
	var featured *espnNormalizedItemResponse
	bestScore := 0

	for _, container := range containers {
		if strings.TrimSpace(container.ID) == "" {
			continue
		}
		var set espnSetResponse
		if err := client.FetchJSON(ctx, backend.BaseURL, fmt.Sprintf("/api/providers/espn/browse/set/%s", url.PathEscape(container.ID)), nil, &set); err != nil {
			return espnHubResponse{}, fmt.Errorf("browse set: %w", err)
		}
		if set.Container == nil {
			continue
		}
		rail := espnNormalizedRailResponse{
			ID:     set.Container.ID,
			Title:  espnFirstNonEmpty(strings.TrimSpace(set.Container.Title), strings.TrimSpace(container.Title)),
			Type:   espnFirstNonEmpty(set.Container.Type, container.Type),
			Layout: espnFirstNonEmpty(set.Container.Layout, container.Layout),
			Style:  espnFirstNonEmpty(set.Container.Style, container.Style),
			Params: set.Container.Params,
		}
		if rail.Params == nil {
			rail.Params = container.Params
		}
		for _, item := range set.Container.Items {
			normalized := buildESPNNormalizedItem(item, *set.Container, focusQuery)
			rail.Items = append(rail.Items, normalized)
			if normalized.MatchScore > bestScore {
				copy := normalized
				featured = &copy
				bestScore = normalized.MatchScore
			}
		}
		if len(rail.Items) == 0 {
			continue
		}
		sort.SliceStable(rail.Items, func(i, j int) bool {
			return rail.Items[i].MatchScore > rail.Items[j].MatchScore
		})
		rails = append(rails, rail)
	}

	return espnHubResponse{
		Success:      true,
		Title:        espnFirstNonEmpty(page.Title, browse.Title),
		PageID:       espnFirstNonEmpty(page.PageID, browse.PageID),
		Style:        espnFirstNonEmpty(page.Style, browse.Style),
		FocusQuery:   focusQuery,
		FeaturedItem: featured,
		Rails:        rails,
	}, nil
}

func (s *Server) postActiveTunerBackendProviderLogin(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/login", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendProviderLoginStream(c *gin.Context) {
	s.proxyActiveTunerBackendFileAtPath(c, fmt.Sprintf("/api/providers/%s/login-stream", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderLoginStream(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/login-stream", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendProviderDeviceCode(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/device-code", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) postActiveTunerBackendProviderDeviceCode(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/device-code", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderDeviceCodeCancel(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/device-code/cancel", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendProviderDeviceCodePoll(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/device-code/poll/%s", url.PathEscape(strings.TrimSpace(c.Param("providerId"))), url.PathEscape(strings.TrimSpace(c.Param("code")))), nil)
}

func (s *Server) postActiveTunerBackendProviderDeviceCodePoll(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/device-code/poll", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderDeviceCodeValidate(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/device-code/validate", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderOTP(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/otp", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderOTPVerify(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/otp/verify", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendProviderActivate(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/activate", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) getActiveTunerBackendProviderActivatePoll(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/activate/poll/%s", url.PathEscape(strings.TrimSpace(c.Param("providerId"))), url.PathEscape(strings.TrimSpace(c.Param("code")))), nil)
}

func (s *Server) getActiveTunerBackendProviderTVCode(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/tv-code", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) getActiveTunerBackendProviderTVCodePoll(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/tv-code/poll/%s", url.PathEscape(strings.TrimSpace(c.Param("providerId"))), url.PathEscape(strings.TrimSpace(c.Param("journeyId")))), nil)
}

func (s *Server) postActiveTunerBackendProviderPoll(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/poll", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderBrowserLogin(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/browser-login", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendProviderBrowserLoginStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/%s/browser-login/status", url.PathEscape(strings.TrimSpace(c.Param("providerId")))), nil)
}

func (s *Server) postActiveTunerBackendProviderBrowserLoginAction(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/browser-login/action", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) postActiveTunerBackendProviderBrowserLoginCancel(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/%s/browser-login/cancel", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) getActiveTunerBackendProviderBrowserLoginScreenshot(c *gin.Context) {
	s.proxyActiveTunerBackendFileAtPath(c, fmt.Sprintf("/api/providers/%s/browser-login/screenshot", url.PathEscape(strings.TrimSpace(c.Param("providerId")))))
}

func (s *Server) saveActiveTunerBackendConfig(c *gin.Context) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}
	var body any
	raw, readErr := io.ReadAll(c.Request.Body)
	if readErr != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to read request body"})
		return
	}
	if len(strings.TrimSpace(string(raw))) > 0 {
		if err := json.Unmarshal(raw, &body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON body"})
			return
		}
	}

	client := tuner.NewBackendDiscoveryClient()
	var payload any
	if err := client.PostJSON(c.Request.Context(), backend.BaseURL, s.endpointFor(*backend, []string{"tunerConfig", "config"}, "/api/tuner/config"), body, &payload); err != nil {
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to save tuner backend config", "message": err.Error()})
		return
	}
	s.markTunerBackendHealthy(backend)
	c.JSON(http.StatusOK, payload)
}

func (s *Server) getActiveTunerBackendDirectvLibrary(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/library", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) getActiveTunerBackendSlingLibrary(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/sling/accounts/%s/library", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) listActiveTunerBackendSlingAccounts(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/sling/accounts", nil)
}

func (s *Server) createActiveTunerBackendSlingAccount(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/sling/accounts")
}

func (s *Server) getActiveTunerBackendSlingAccount(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/sling/accounts/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) updateActiveTunerBackendSlingAccount(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPut, fmt.Sprintf("/api/providers/sling/accounts/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) deleteActiveTunerBackendSlingAccount(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/sling/accounts/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) deleteActiveTunerBackendSlingAccountLogout(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/sling/accounts/%s/logout", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) getActiveTunerBackendFrndlyLibrary(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/frndlytv/library", nil)
}

func (s *Server) getActiveTunerBackendFrndlyRecordings(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/frndlytv/recordings", nil)
}

func (s *Server) getActiveTunerBackendFrndlyUpcomingRecordings(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/frndlytv/upcoming-recordings", nil)
}

func (s *Server) getActiveTunerBackendFrndlySeriesRules(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/frndlytv/series-rules", nil)
}

func (s *Server) getActiveTunerBackendFrndlyRecordingPlaybackAuth(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/frndlytv/recording-playback-auth", nil)
}

func (s *Server) postActiveTunerBackendFrndlyRecording(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/frndlytv/recordings")
}

func (s *Server) createActiveTunerBackendFrndlySeriesRule(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/frndlytv/series-rules")
}

func (s *Server) postActiveTunerBackendFrndlyRefreshEPG(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/frndlytv/refresh-epg")
}

func (s *Server) getActiveTunerBackendFrndlyRecording(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/frndlytv/recordings/%s", url.PathEscape(c.Param("recordId"))), nil)
}

func (s *Server) deleteActiveTunerBackendFrndlyRecording(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/frndlytv/recordings/%s", url.PathEscape(c.Param("recordId"))), nil)
}

func (s *Server) postActiveTunerBackendFrndlyDownload(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/frndlytv/recordings/%s/download", url.PathEscape(c.Param("recordId"))))
}

func (s *Server) getActiveTunerBackendFrndlyDownloadJob(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/frndlytv/downloads/%s", url.PathEscape(c.Param("jobId"))), nil)
}

func (s *Server) getActiveTunerBackendFrndlyDownloads(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/frndlytv/downloads", nil)
}

func (s *Server) postActiveTunerBackendFrndlyCancelDownload(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/frndlytv/downloads/%s/cancel", url.PathEscape(c.Param("jobId"))))
}

func (s *Server) getActiveTunerBackendSlingRecordings(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/sling/accounts/%s/recordings", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) getActiveTunerBackendSlingUpcomingRecordings(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/sling/accounts/%s/upcoming-recordings", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) getActiveTunerBackendSlingRecordingPlaybackAuth(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/sling/accounts/%s/recording-playback-auth", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) getActiveTunerBackendSlingRecording(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/sling/accounts/%s/recordings/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("recordId"))), nil)
}

func (s *Server) postActiveTunerBackendSlingRecording(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/sling/accounts/%s/recordings", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) deleteActiveTunerBackendSlingRecording(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/sling/accounts/%s/recordings/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("recordId"))), nil)
}

func (s *Server) postActiveTunerBackendSlingDownload(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/sling/accounts/%s/recordings/%s/download", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("recordId"))))
}

func (s *Server) listActiveTunerBackendSlingSeriesRules(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/sling/accounts/%s/series-rules", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) createActiveTunerBackendSlingSeriesRule(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/sling/accounts/%s/series-rules", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) getActiveTunerBackendSlingDownloads(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/sling/downloads", nil)
}

func (s *Server) getActiveTunerBackendSlingDownloadJob(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/sling/downloads/%s", url.PathEscape(c.Param("jobId"))), nil)
}

func (s *Server) deleteActiveTunerBackendSlingDownloadJob(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/sling/downloads/%s", url.PathEscape(c.Param("jobId"))), nil)
}

func (s *Server) postActiveTunerBackendSlingCancelDownload(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/sling/downloads/%s/cancel", url.PathEscape(c.Param("jobId"))))
}

func (s *Server) getActiveTunerBackendSlingDownloadFile(c *gin.Context) {
	s.proxyActiveTunerBackendFileAtPath(c, fmt.Sprintf("/api/providers/sling/downloads/%s/file", url.PathEscape(c.Param("jobId"))))
}

func (s *Server) getActiveTunerBackendDirectvAccount(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) listActiveTunerBackendDirectvAccounts(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/directv/accounts", nil)
}

func (s *Server) createActiveTunerBackendDirectvAccount(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/directv/accounts")
}

func (s *Server) getActiveTunerBackendDirectvAuth(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/directv/auth", nil)
}

func (s *Server) getActiveTunerBackendDirectvAccountLoginStream(c *gin.Context) {
	s.proxyActiveTunerBackendFileAtPath(c, fmt.Sprintf("/api/providers/directv/accounts/%s/login-stream", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) getActiveTunerBackendDirectvAccountCredentials(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/credentials", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) saveActiveTunerBackendDirectvAccountCredentials(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/credentials", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) deleteActiveTunerBackendDirectvAccountLogout(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/directv/accounts/%s/logout", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) postActiveTunerBackendDirectvRecord(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/record", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) postActiveTunerBackendDirectvRecordSeries(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/record-series", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) getActiveTunerBackendDirectvRecordStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/record-status", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) postActiveTunerBackendDirectvRecordStatusBulk(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/record-status/bulk", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) postActiveTunerBackendDirectvRecordCancel(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/record/cancel", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) postActiveTunerBackendDirectvRecordDelete(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/record/delete", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) getActiveTunerBackendDirectvPlayability(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/playability", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) postActiveTunerBackendDirectvPlayabilityCheck(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/playability/check", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) postActiveTunerBackendDirectvPlayabilityCheckBulk(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/playability/check-bulk", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) getActiveTunerBackendDirectvEPGStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/epg-status", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) postActiveTunerBackendDirectvRefreshEPG(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/refresh-epg", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) postActiveTunerBackendDirectvGlobalRefreshEPG(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/directv/refresh-epg")
}

func (s *Server) deleteActiveTunerBackendDirectvKeys(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/directv/accounts/%s/keys", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) getActiveTunerBackendDirectvRecordingPlaybackAuth(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/recording-playback-auth", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) getActiveTunerBackendDirectvRecordings(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/recordings", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) getActiveTunerBackendDirectvUpcomingRecordings(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/upcoming-recordings", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) postActiveTunerBackendDirectvCancelRecording(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/recordings/%s/cancel", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("recordId"))))
}

func (s *Server) getActiveTunerBackendDirectvRecording(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/recordings/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("recordId"))), nil)
}

func (s *Server) deleteActiveTunerBackendDirectvRecording(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/directv/accounts/%s/recordings/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("recordId"))), nil)
}

func (s *Server) postActiveTunerBackendDirectvDownload(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/recordings/%s/download", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("recordId"))))
}

func (s *Server) listActiveTunerBackendDirectvSeriesRules(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/series-rules", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))), nil)
}

func (s *Server) getActiveTunerBackendDirectvSeriesRule(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/accounts/%s/series-rules/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("seriesRuleId"))), nil)
}

func (s *Server) createActiveTunerBackendDirectvSeriesRule(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/accounts/%s/series-rules", url.PathEscape(normalizeProviderAccountPathID(c.Param("id")))))
}

func (s *Server) updateActiveTunerBackendDirectvSeriesRule(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPatch, fmt.Sprintf("/api/providers/directv/accounts/%s/series-rules/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("seriesRuleId"))))
}

func (s *Server) deleteActiveTunerBackendDirectvSeriesRule(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/directv/accounts/%s/series-rules/%s", url.PathEscape(normalizeProviderAccountPathID(c.Param("id"))), url.PathEscape(c.Param("seriesRuleId"))), nil)
}

func (s *Server) postActiveTunerBackendDirectvImportDownload(c *gin.Context) {
	if s.recorder == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "DVR recorder not available"})
		return
	}

	jobID := strings.TrimSpace(c.Param("jobId"))
	if jobID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Download job ID is required"})
		return
	}

	var req directvImportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON body", "message": err.Error()})
		return
	}

	userID := c.GetUint("userID")
	var existing models.Recording
	if err := s.db.Where("external_download_job_id = ?", jobID).First(&existing).Error; err == nil {
		c.JSON(http.StatusOK, gin.H{
			"imported":  true,
			"existing":  true,
			"recording": toRecordingResponse(existing, nil),
			"message":   "Download already imported",
		})
		return
	}

	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}

	client := tuner.NewBackendDiscoveryClient()
	var jobPayload map[string]any
	if err := client.FetchJSON(c.Request.Context(), backend.BaseURL, fmt.Sprintf("/api/providers/directv/downloads/%s", url.PathEscape(jobID)), nil, &jobPayload); err != nil {
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch DirecTV download job", "message": err.Error()})
		return
	}
	s.markTunerBackendHealthy(backend)

	jobStatus := strings.ToLower(firstNonEmpty(stringValue(jobPayload["status"]), stringValue(jobPayload["state"])))
	if jobStatus == "" {
		jobStatus = "unknown"
	}
	if jobStatus != "completed" {
		c.JSON(http.StatusConflict, gin.H{"error": "Download job is not completed", "status": jobStatus})
		return
	}

	recordingsDir := s.config.DVR.RecordingDir
	if recordingsDir == "" {
		recordingsDir = filepath.Join(s.config.GetDataDir(), "recordings")
	}
	if err := os.MkdirAll(recordingsDir, 0o755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to prepare recordings directory", "message": err.Error()})
		return
	}

	targetPath, fileSize, copyErr := s.copyDirectvDownloadToLocal(c.Request.Context(), backend, jobID, recordingsDir, req, jobPayload)
	if copyErr != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to import DirecTV download", "message": copyErr.Error()})
		return
	}

	startTime := parseDirectvImportTime(req.StartTime)
	endTime := parseDirectvImportTime(req.EndTime)
	if startTime.IsZero() {
		startTime = time.Now()
	}

	durationSeconds := getVideoDuration(targetPath)
	if endTime.IsZero() {
		if durationSeconds > 0 {
			endTime = startTime.Add(time.Duration(durationSeconds * float64(time.Second)))
		} else {
			endTime = startTime
		}
	}
	var durationMinutes *int
	if durationSeconds > 0 {
		mins := int(durationSeconds / 60)
		if mins <= 0 {
			mins = 1
		}
		durationMinutes = &mins
	}

	var originalAirDate *time.Time
	if parsed := parseDirectvImportTime(req.OriginalAirDate); !parsed.IsZero() {
		originalAirDate = &parsed
	}

	recording := models.Recording{
		UserID:                userID,
		Title:                 firstNonEmpty(req.Title, stringValue(jobPayload["title"]), fmt.Sprintf("DirecTV Download %s", jobID)),
		Subtitle:              req.Subtitle,
		Description:           req.Description,
		Summary:               req.Summary,
		StartTime:             startTime,
		EndTime:               endTime,
		Status:                "completed",
		FilePath:              targetPath,
		FileSize:              fileSize,
		Category:              stringValue(jobPayload["category"]),
		EpisodeNum:            firstNonEmpty(req.EpisodeNum, stringValue(jobPayload["episodeNum"])),
		SeasonNumber:          req.SeasonNumber,
		EpisodeNumber:         req.EpisodeNumber,
		Genres:                strings.Join(req.Genres, ", "),
		ContentRating:         req.ContentRating,
		Year:                  req.Year,
		Duration:              durationMinutes,
		OriginalAirDate:       originalAirDate,
		IsMovie:               req.IsMovie,
		Rating:                req.Rating,
		ChannelName:           req.ChannelName,
		ChannelLogo:           req.ChannelLogo,
		SourceType:            firstNonEmpty(req.SourceType, "external-tuner"),
		SourceName:            firstNonEmpty(req.SourceName, backend.Name),
		ProviderID:            req.ProviderID,
		ProviderName:          req.ProviderName,
		AccountID:             req.AccountID,
		AccountName:           req.AccountName,
		AccountIndex:          req.AccountIndex,
		ExternalRecordID:      firstNonEmpty(req.RecordID, stringValue(jobPayload["recordId"])),
		ExternalDownloadJobID: jobID,
	}

	if err := s.db.Create(&recording).Error; err != nil {
		_ = os.Remove(targetPath)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save imported recording", "message": err.Error()})
		return
	}

	var importWarning string
	if err := s.recorder.ImportCompletedRecording(&recording); err != nil {
		importWarning = fmt.Sprintf("Imported locally, but commercial detection failed: %v", err)
		s.db.Model(&recording).Update("last_error", importWarning)
	}

	cleanupResult := "skipped"
	cleanupMessage := ""
	if req.CleanupUpstream {
		if err := s.deleteActiveTunerBackendDirectvDownloadArtifact(c.Request.Context(), backend, jobID); err != nil {
			cleanupResult = "failed"
			cleanupMessage = err.Error()
		} else {
			cleanupResult = "deleted"
			cleanupMessage = "Upstream download artifact removed"
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"imported":  true,
		"recording": toRecordingResponse(recording, nil),
		"warning":   importWarning,
		"cleanup": gin.H{
			"result":  cleanupResult,
			"message": cleanupMessage,
		},
	})
}

func (s *Server) getActiveTunerBackendDirectvDownloads(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/directv/downloads", nil)
}

func (s *Server) getActiveTunerBackendDirectvDownloadJob(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/directv/downloads/%s", url.PathEscape(c.Param("jobId"))), nil)
}

func (s *Server) postActiveTunerBackendDirectvCancelDownload(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/directv/downloads/%s/cancel", url.PathEscape(c.Param("jobId"))))
}

func (s *Server) deleteActiveTunerBackendDirectvDownloadJob(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/directv/downloads/%s", url.PathEscape(c.Param("jobId"))), nil)
}

func (s *Server) getActiveTunerBackendDirectvDownloadFile(c *gin.Context) {
	s.proxyActiveTunerBackendFileAtPath(c, fmt.Sprintf("/api/providers/directv/downloads/%s/file", url.PathEscape(c.Param("jobId"))))
}

func (s *Server) getActiveTunerBackendFrndlyDownloadFile(c *gin.Context) {
	s.proxyActiveTunerBackendFileAtPath(c, fmt.Sprintf("/api/providers/frndlytv/downloads/%s/file", url.PathEscape(c.Param("jobId"))))
}

func (s *Server) getActiveTunerBackendDirectvTVEHealth(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/directv/tve-health", nil)
}

func (s *Server) getActiveTunerBackendFuboLibrary(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/fubo/library", nil)
}

func (s *Server) getActiveTunerBackendFuboRecordings(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/fubo/recordings", nil)
}

func (s *Server) postActiveTunerBackendFuboRecording(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/fubo/recordings")
}

func (s *Server) getActiveTunerBackendFuboRecording(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/fubo/recordings/%s", url.PathEscape(c.Param("recordId"))), nil)
}

func (s *Server) getActiveTunerBackendFuboUpcomingRecordings(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/fubo/upcoming-recordings", nil)
}

func (s *Server) getActiveTunerBackendFuboRecordingPlaybackAuth(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/fubo/recording-playback-auth", nil)
}

func (s *Server) postActiveTunerBackendFuboRefreshEPG(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, "/api/providers/fubo/refresh-epg")
}

func (s *Server) deleteActiveTunerBackendFuboRecording(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/fubo/recordings/%s", url.PathEscape(c.Param("recordId"))))
}

func (s *Server) postActiveTunerBackendFuboDownload(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/fubo/recordings/%s/download", url.PathEscape(c.Param("recordId"))))
}

func (s *Server) getActiveTunerBackendFuboDownloads(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/fubo/downloads", nil)
}

func (s *Server) getActiveTunerBackendFuboDownloadJob(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/fubo/downloads/%s", url.PathEscape(c.Param("jobId"))), nil)
}

func (s *Server) deleteActiveTunerBackendFuboDownloadJob(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodDelete, fmt.Sprintf("/api/providers/fubo/downloads/%s", url.PathEscape(c.Param("jobId"))), nil)
}

func (s *Server) postActiveTunerBackendFuboCancelDownload(c *gin.Context) {
	s.proxyActiveTunerBackendBodyJSONAtPath(c, http.MethodPost, fmt.Sprintf("/api/providers/fubo/downloads/%s/cancel", url.PathEscape(c.Param("jobId"))))
}

func (s *Server) getActiveTunerBackendFuboDownloadFile(c *gin.Context) {
	s.proxyActiveTunerBackendFileAtPath(c, fmt.Sprintf("/api/providers/fubo/downloads/%s/file", url.PathEscape(c.Param("jobId"))))
}

func (s *Server) proxyActiveTunerBackendFileAtPath(c *gin.Context, path string) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}
	client := tuner.NewBackendDiscoveryClient()
	targetURL, err := tuner.BuildEndpointURL(backend.BaseURL, path, c.Request.URL.Query())
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid upstream path", "message": err.Error()})
		return
	}
	req, err := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, targetURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upstream request"})
		return
	}
	resp, err := client.HTTPClient().Do(req)
	if err != nil {
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
		return
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
		err = fmt.Errorf("upstream returned HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
		return
	}
	s.markTunerBackendHealthy(backend)
	for _, header := range []string{"Content-Type", "Content-Length", "Content-Disposition", "Cache-Control"} {
		if value := resp.Header.Get(header); value != "" {
			c.Header(header, value)
		}
	}
	c.Status(resp.StatusCode)
	_, _ = io.Copy(c.Writer, resp.Body)
}

// streamProxyClient is a dedicated HTTP client for proxying live streams.
// Unlike the discovery client it has NO global request timeout — only dial
// and TLS-handshake limits — so the body can stream indefinitely.
var streamProxyClient = &http.Client{
	Transport: &http.Transport{
		DialContext: (&net.Dialer{
			Timeout:   10 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		TLSHandshakeTimeout:   10 * time.Second,
		ResponseHeaderTimeout: 30 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
		IdleConnTimeout:       90 * time.Second,
	},
}

func (s *Server) proxyActiveTunerBackendRawAtPath(c *gin.Context, method, path string) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}
	targetURL, err := tuner.BuildEndpointURL(backend.BaseURL, path, c.Request.URL.Query())
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid upstream path", "message": err.Error()})
		return
	}
	req, err := http.NewRequestWithContext(c.Request.Context(), method, targetURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upstream request"})
		return
	}
	resp, err := streamProxyClient.Do(req)
	if err != nil {
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
		return
	}
	defer resp.Body.Close()
	s.markTunerBackendHealthy(backend)
	for _, header := range []string{
		"Content-Type",
		"Content-Length",
		"Content-Disposition",
		"Cache-Control",
		"Location",
		"ETag",
	} {
		if value := resp.Header.Get(header); value != "" {
			c.Header(header, value)
		}
	}
	c.Status(resp.StatusCode)
	_, _ = io.Copy(c.Writer, resp.Body)
}

func (s *Server) proxyActiveTunerBackendTVEPlaylistAtPath(c *gin.Context, path string) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}
	client := tuner.NewBackendDiscoveryClient()
	targetURL, err := tuner.BuildEndpointURL(backend.BaseURL, path, c.Request.URL.Query())
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid upstream path", "message": err.Error()})
		return
	}
	req, err := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, targetURL, nil)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upstream request"})
		return
	}
	resp, err := client.HTTPClient().Do(req)
	if err != nil {
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
		return
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		err = fmt.Errorf("upstream returned HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
		return
	}
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to read upstream tuner backend", "message": err.Error()})
		return
	}
	s.markTunerBackendHealthy(backend)
	rewritten := rewriteActiveTunerBackendTVEPlaylist(body, backend.BaseURL, getBaseURL(c))
	for _, header := range []string{"Content-Disposition", "Cache-Control", "ETag"} {
		if value := resp.Header.Get(header); value != "" {
			c.Header(header, value)
		}
	}
	c.Data(resp.StatusCode, firstNonEmpty(resp.Header.Get("Content-Type"), "application/x-mpegurl; charset=utf-8"), []byte(rewritten))
}

func rewriteActiveTunerBackendTVEPlaylist(body []byte, backendBaseURL, publicBaseURL string) string {
	lines := strings.Split(string(body), "\n")
	backendURL, err := url.Parse(strings.TrimSpace(backendBaseURL))
	if err != nil {
		return string(body)
	}
	for i, line := range lines {
		if strings.Contains(line, `url-tvg="`) {
			lines[i] = rewriteTVEPlaylistAttributeURL(line, "url-tvg", backendURL, publicBaseURL)
		}
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}
		if rewritten, ok := rewriteTVEPlaylistLineURL(trimmed, backendURL, publicBaseURL); ok {
			lines[i] = rewritten
		}
	}
	return strings.Join(lines, "\n")
}

func rewriteTVEPlaylistAttributeURL(line, attr string, backendURL *url.URL, publicBaseURL string) string {
	pattern := attr + `="`
	start := strings.Index(line, pattern)
	if start == -1 {
		return line
	}
	valueStart := start + len(pattern)
	valueEnd := strings.Index(line[valueStart:], `"`)
	if valueEnd == -1 {
		return line
	}
	valueEnd += valueStart
	rewritten, ok := rewriteTVEPlaylistLineURL(line[valueStart:valueEnd], backendURL, publicBaseURL)
	if !ok {
		return line
	}
	return line[:valueStart] + rewritten + line[valueEnd:]
}

func rewriteTVEPlaylistLineURL(raw string, backendURL *url.URL, publicBaseURL string) (string, bool) {
	target, err := url.Parse(strings.TrimSpace(raw))
	if err != nil {
		return "", false
	}
	if target.Host == "" || !sameBackendHost(target, backendURL) {
		return "", false
	}
	switch {
	case strings.HasPrefix(target.Path, "/tve/") && strings.HasSuffix(target.Path, "/epg.xml"):
		target.Scheme = ""
		target.Host = ""
		return publicBaseURL + "/api/tuner-backends/active" + target.String(), true
	default:
		return "", false
	}
}

func sameBackendHost(target, backend *url.URL) bool {
	return strings.EqualFold(target.Host, backend.Host)
}

func (s *Server) getActiveTunerBackendMLBSchedule(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/mlb/schedule", nil)
}

func (s *Server) getActiveTunerBackendMLBHighlights(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/mlb/highlights/%s", url.PathEscape(strings.TrimSpace(c.Param("gamePk")))), nil)
}

func (s *Server) getActiveTunerBackendMLBAudioTracks(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/mlb/audio-tracks/%s", url.PathEscape(strings.TrimSpace(c.Param("gamePk")))), nil)
}

func (s *Server) getActiveTunerBackendMLBSkipMarkers(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/mlb/skip-markers/%s", url.PathEscape(strings.TrimSpace(c.Param("gamePk")))), nil)
}

func (s *Server) getActiveTunerBackendMLBEntitlements(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/mlb/entitlements", nil)
}

func (s *Server) getActiveTunerBackendMLBTokenStatus(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, "/api/providers/mlb/token-status", nil)
}

func (s *Server) getActiveTunerBackendMLBBlackouts(c *gin.Context) {
	s.proxyActiveTunerBackendJSONAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/mlb/blackouts/%s", url.PathEscape(strings.TrimSpace(c.Param("mediaId")))), nil)
}

func (s *Server) getActiveTunerBackendMLBCatchup(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, fmt.Sprintf("/api/providers/mlb/catchup/%s", url.PathEscape(strings.TrimSpace(c.Param("channelId")))))
}

func (s *Server) getActiveTunerBackendMLBHLSProxyMaster(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, "/api/providers/mlb/hls-proxy/master")
}

func (s *Server) getActiveTunerBackendMLBHLSProxyPlaylist(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, "/api/providers/mlb/hls-proxy/playlist")
}

func (s *Server) getActiveTunerBackendMLBHLSProxySegment(c *gin.Context) {
	s.proxyActiveTunerBackendRawAtPath(c, http.MethodGet, "/api/providers/mlb/hls-proxy/segment")
}

func parseDirectvImportTime(raw string) time.Time {
	value := strings.TrimSpace(raw)
	if value == "" {
		return time.Time{}
	}
	if parsed, err := time.Parse(time.RFC3339, value); err == nil {
		return parsed
	}
	return time.Time{}
}

func sanitizeImportFileName(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return "directv-recording"
	}
	replacer := strings.NewReplacer(
		"/", "-",
		"\\", "-",
		":", "-",
		"*", "",
		"?", "",
		"\"", "",
		"<", "",
		">", "",
		"|", "",
	)
	value = replacer.Replace(value)
	value = strings.Join(strings.Fields(value), " ")
	if value == "" {
		return "directv-recording"
	}
	return value
}

func inferImportExtension(header http.Header, jobID string) string {
	if disposition := header.Get("Content-Disposition"); disposition != "" {
		if _, params, err := mime.ParseMediaType(disposition); err == nil {
			if filename := params["filename"]; filename != "" {
				if ext := filepath.Ext(filename); ext != "" {
					return ext
				}
			}
		}
	}
	if ext := filepath.Ext(jobID); ext != "" {
		return ext
	}
	switch header.Get("Content-Type") {
	case "video/mp4":
		return ".mp4"
	case "video/x-matroska":
		return ".mkv"
	default:
		return ".mp4"
	}
}

func (s *Server) copyDirectvDownloadToLocal(ctx context.Context, backend *models.TunerBackend, jobID, recordingsDir string, req directvImportRequest, jobPayload map[string]any) (string, int64, error) {
	client := tuner.NewBackendDiscoveryClient()
	targetURL, err := tuner.BuildEndpointURL(backend.BaseURL, fmt.Sprintf("/api/providers/directv/downloads/%s/file", url.PathEscape(jobID)), nil)
	if err != nil {
		return "", 0, err
	}
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodGet, targetURL, nil)
	if err != nil {
		return "", 0, err
	}
	resp, err := client.HTTPClient().Do(httpReq)
	if err != nil {
		return "", 0, err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
		return "", 0, fmt.Errorf("upstream returned HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	fileName := sanitizeImportFileName(firstNonEmpty(req.Title, stringValue(jobPayload["title"])))
	if req.Subtitle != "" {
		fileName = fmt.Sprintf("%s - %s", fileName, sanitizeImportFileName(req.Subtitle))
	}
	if req.SeasonNumber != nil && req.EpisodeNumber != nil {
		fileName = fmt.Sprintf("%s - S%02dE%02d", fileName, *req.SeasonNumber, *req.EpisodeNumber)
	}
	fileName = strings.TrimSpace(fileName) + inferImportExtension(resp.Header, jobID)
	targetPath := filepath.Join(recordingsDir, fileName)
	if _, err := os.Stat(targetPath); err == nil {
		base := strings.TrimSuffix(fileName, filepath.Ext(fileName))
		targetPath = filepath.Join(recordingsDir, fmt.Sprintf("%s-%d%s", base, time.Now().Unix(), filepath.Ext(fileName)))
	}
	tempPath := targetPath + ".partial"

	out, err := os.Create(tempPath)
	if err != nil {
		return "", 0, err
	}
	bytesWritten, copyErr := io.Copy(out, resp.Body)
	closeErr := out.Close()
	if copyErr != nil {
		_ = os.Remove(tempPath)
		return "", 0, copyErr
	}
	if closeErr != nil {
		_ = os.Remove(tempPath)
		return "", 0, closeErr
	}
	if err := os.Rename(tempPath, targetPath); err != nil {
		_ = os.Remove(tempPath)
		return "", 0, err
	}
	return targetPath, bytesWritten, nil
}

func (s *Server) deleteActiveTunerBackendDirectvDownloadArtifact(ctx context.Context, backend *models.TunerBackend, jobID string) error {
	client := tuner.NewBackendDiscoveryClient()
	targetURL, err := tuner.BuildEndpointURL(backend.BaseURL, fmt.Sprintf("/api/providers/directv/downloads/%s", url.PathEscape(jobID)), nil)
	if err != nil {
		return err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, targetURL, nil)
	if err != nil {
		return err
	}
	resp, err := client.HTTPClient().Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
		return fmt.Errorf("upstream returned HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	return nil
}

func (s *Server) proxyActiveTunerBackendJSON(c *gin.Context, endpointKeys []string, fallback string) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}
	if payload, ok, err := s.fetchFromBackend(c.Request.Context(), backend, endpointKeys, fallback, c.Request.URL.Query()); err != nil {
		logger.Warnf("tuner backend proxy failed: %v", err)
		s.markTunerBackendError(backend, err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
		return
	} else if !ok {
		c.JSON(http.StatusNotFound, gin.H{"error": "Selected tuner backend does not expose this endpoint"})
		return
	} else {
		s.markTunerBackendHealthy(backend)
		c.JSON(http.StatusOK, payload)
	}
}

func (s *Server) proxyActiveTunerBackendJSONAtPath(c *gin.Context, method, path string, body any) {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active tuner backend configured"})
		return
	}
	client := tuner.NewBackendDiscoveryClient()
	var payload any
	switch method {
	case http.MethodGet:
		if err := client.FetchJSON(c.Request.Context(), backend.BaseURL, path, c.Request.URL.Query(), &payload); err != nil {
			s.markTunerBackendError(backend, err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
			return
		}
	case http.MethodPost:
		if err := client.PostJSON(c.Request.Context(), backend.BaseURL, path, body, &payload); err != nil {
			s.markTunerBackendError(backend, err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
			return
		}
	case http.MethodPatch:
		targetURL, err := tuner.BuildEndpointURL(backend.BaseURL, path, c.Request.URL.Query())
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid upstream path", "message": err.Error()})
			return
		}
		rawBody, err := json.Marshal(body)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid upstream body", "message": err.Error()})
			return
		}
		req, err := http.NewRequestWithContext(c.Request.Context(), http.MethodPatch, targetURL, strings.NewReader(string(rawBody)))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upstream request"})
			return
		}
		req.Header.Set("Content-Type", "application/json")
		resp, err := client.HTTPClient().Do(req)
		if err != nil {
			s.markTunerBackendError(backend, err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
			return
		}
		defer resp.Body.Close()
		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			body, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
			err = fmt.Errorf("upstream returned HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
			s.markTunerBackendError(backend, err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
			return
		}
		if decodeErr := json.NewDecoder(resp.Body).Decode(&payload); decodeErr != nil && decodeErr != io.EOF {
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to decode upstream response", "message": decodeErr.Error()})
			return
		}
	case http.MethodDelete:
		targetURL, err := tuner.BuildEndpointURL(backend.BaseURL, path, c.Request.URL.Query())
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid upstream path", "message": err.Error()})
			return
		}
		req, err := http.NewRequestWithContext(c.Request.Context(), http.MethodDelete, targetURL, nil)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create upstream request"})
			return
		}
		resp, err := client.HTTPClient().Do(req)
		if err != nil {
			s.markTunerBackendError(backend, err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
			return
		}
		defer resp.Body.Close()
		if resp.StatusCode < 200 || resp.StatusCode >= 300 {
			body, _ := io.ReadAll(io.LimitReader(resp.Body, 2048))
			err = fmt.Errorf("upstream returned HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
			s.markTunerBackendError(backend, err)
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": err.Error()})
			return
		}
		if decodeErr := json.NewDecoder(resp.Body).Decode(&payload); decodeErr != nil && decodeErr != io.EOF {
			c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to decode upstream response", "message": decodeErr.Error()})
			return
		}
	default:
		c.JSON(http.StatusMethodNotAllowed, gin.H{"error": "Unsupported method"})
		return
	}
	s.markTunerBackendHealthy(backend)
	c.JSON(http.StatusOK, payload)
}

func (s *Server) proxyActiveTunerBackendBodyJSONAtPath(c *gin.Context, method, path string) {
	var body any
	raw, readErr := io.ReadAll(c.Request.Body)
	if readErr != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to read request body"})
		return
	}
	if trimmed := strings.TrimSpace(string(raw)); trimmed != "" {
		if err := json.Unmarshal(raw, &body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON body"})
			return
		}
	}
	s.proxyActiveTunerBackendJSONAtPath(c, method, path, body)
}

func (s *Server) proxyIfActiveTunerBackend(c *gin.Context, endpointKeys []string, fallback string) bool {
	backend, err := s.loadActiveTunerBackend()
	if err != nil {
		return false
	}
	payload, ok, fetchErr := s.fetchFromBackend(c.Request.Context(), backend, endpointKeys, fallback, c.Request.URL.Query())
	if fetchErr != nil {
		logger.Warnf("active tuner backend request failed: %v", fetchErr)
		s.markTunerBackendError(backend, fetchErr)
		c.JSON(http.StatusBadGateway, gin.H{"error": "Failed to fetch upstream tuner backend", "message": fetchErr.Error()})
		return true
	}
	if !ok {
		return false
	}
	s.markTunerBackendHealthy(backend)
	c.JSON(http.StatusOK, payload)
	return true
}

func (s *Server) fetchFromBackend(ctx context.Context, backend *models.TunerBackend, endpointKeys []string, fallback string, query map[string][]string) (any, bool, error) {
	endpoint := s.endpointFor(*backend, endpointKeys, fallback)
	if endpoint == "" {
		return nil, false, nil
	}
	client := tuner.NewBackendDiscoveryClient()
	var payload any
	if err := client.FetchJSON(ctx, backend.BaseURL, endpoint, query, &payload); err != nil {
		return nil, true, err
	}
	return payload, true, nil
}

func (s *Server) loadActiveTunerBackend() (*models.TunerBackend, error) {
	var backend models.TunerBackend
	if err := s.db.Where("active = ?", true).First(&backend).Error; err != nil {
		return nil, err
	}
	return &backend, nil
}

func (s *Server) upsertTunerBackend(backend tuner.RemoteTunerBackend, source string, active bool, connected bool) (*models.TunerBackend, error) {
	row := models.TunerBackend{
		BackendID: backend.ID,
		Name:      backend.Name,
		Host:      backend.Host,
		Port:      backend.Port,
		BaseURL:   backend.BaseURL,
		Version:   backend.Version,
		Healthy:   backend.Healthy,
		Type:      firstNonEmpty(backend.Type, "dvr-tuner"),
		MachineID: backend.MachineID,
		Source:    firstNonEmpty(source, "manual"),
		LastError: "",
	}
	if row.Name == "" {
		row.Name = row.Host
	}
	if row.BackendID == "" {
		row.BackendID = firstNonEmpty(row.MachineID, row.Host, row.BaseURL)
	}
	if row.Port == 0 {
		row.Port = 7070
	}
	row.EndpointsJSON = mustJSON(backend.Endpoints)
	row.ProvidersJSON = mustJSON(backend.Providers)
	row.DiscoveryJSON = mustJSON(backend)
	now := time.Now()
	row.LastSeenAt = &now
	row.LastCheckedAt = &now
	if connected {
		row.LastConnectedAt = &now
	}

	if err := s.db.Transaction(func(tx *gorm.DB) error {
		var existing models.TunerBackend
		existingFound := tx.Where(
			"backend_id = ? OR base_url = ? OR (host = ? AND port = ?)",
			row.BackendID,
			row.BaseURL,
			row.Host,
			row.Port,
		).First(&existing).Error == nil
		if active {
			if err := tx.Model(&models.TunerBackend{}).Where("active = ?", true).Update("active", false).Error; err != nil {
				return err
			}
			row.Active = true
		} else if existingFound {
			row.Active = existing.Active
			if row.LastConnectedAt == nil {
				row.LastConnectedAt = existing.LastConnectedAt
			}
		}
		lookupBackendID := row.BackendID
		if existingFound && strings.TrimSpace(existing.BackendID) != "" {
			lookupBackendID = existing.BackendID
		}
		if err := tx.Where(models.TunerBackend{BackendID: lookupBackendID}).Assign(row).FirstOrCreate(&row).Error; err != nil {
			return err
		}
		return nil
	}); err != nil {
		return nil, err
	}
	return &row, nil
}

func (s *Server) refreshTunerBackendHealth(ctx context.Context, backend *models.TunerBackend) (*models.TunerBackend, error) {
	client := tuner.NewBackendDiscoveryClient()
	refreshed, err := client.Probe(ctx, backend.BaseURL)
	if err != nil {
		s.markTunerBackendError(backend, err)
		return backend, err
	}
	now := time.Now()
	updates := map[string]any{
		"name":            firstNonEmpty(refreshed.Name, backend.Name),
		"type":            firstNonEmpty(refreshed.Type, backend.Type, "dvr-tuner"),
		"host":            firstNonEmpty(refreshed.Host, backend.Host),
		"port":            maxInt(refreshed.Port, backend.Port, 7070),
		"base_url":        firstNonEmpty(refreshed.BaseURL, backend.BaseURL),
		"version":         firstNonEmpty(refreshed.Version, backend.Version),
		"machine_id":      firstNonEmpty(refreshed.MachineID, backend.MachineID),
		"endpoints_json":  mustJSON(refreshed.Endpoints),
		"providers_json":  mustJSON(refreshed.Providers),
		"discovery_json":  mustJSON(refreshed),
		"healthy":         true,
		"last_seen_at":    now,
		"last_checked_at": now,
		"last_error":      "",
	}
	if err := s.db.Model(&models.TunerBackend{}).Where("id = ?", backend.ID).Updates(updates).Error; err != nil {
		return backend, err
	}
	backend.Name = firstNonEmpty(refreshed.Name, backend.Name)
	backend.Type = firstNonEmpty(refreshed.Type, backend.Type, "dvr-tuner")
	backend.Host = firstNonEmpty(refreshed.Host, backend.Host)
	backend.Port = maxInt(refreshed.Port, backend.Port, 7070)
	backend.BaseURL = firstNonEmpty(refreshed.BaseURL, backend.BaseURL)
	backend.Version = firstNonEmpty(refreshed.Version, backend.Version)
	backend.MachineID = firstNonEmpty(refreshed.MachineID, backend.MachineID)
	backend.EndpointsJSON = mustJSON(refreshed.Endpoints)
	backend.ProvidersJSON = mustJSON(refreshed.Providers)
	backend.DiscoveryJSON = mustJSON(refreshed)
	backend.Healthy = true
	backend.LastSeenAt = &now
	backend.LastCheckedAt = &now
	backend.LastError = ""
	return backend, nil
}

func (s *Server) endpointFor(backend models.TunerBackend, keys []string, fallback string) string {
	endpoints := parseStringMap(backend.EndpointsJSON)
	for _, key := range keys {
		if value := strings.TrimSpace(endpoints[key]); value != "" {
			return value
		}
	}
	return strings.TrimSpace(fallback)
}

func (s *Server) serializeTunerBackend(row models.TunerBackend) tunerBackendRecordResponse {
	providers := annotateBackendProviders(parseProviders(row.ProvidersJSON), row.LastCheckedAt)
	return tunerBackendRecordResponse{
		ID:              row.ID,
		BackendID:       row.BackendID,
		Name:            row.Name,
		Type:            row.Type,
		Host:            row.Host,
		Port:            row.Port,
		BaseURL:         row.BaseURL,
		Version:         row.Version,
		MachineID:       row.MachineID,
		Healthy:         row.Healthy,
		Active:          row.Active,
		Source:          row.Source,
		Endpoints:       parseStringMap(row.EndpointsJSON),
		Providers:       providers,
		LastSeenAt:      row.LastSeenAt,
		LastConnectedAt: row.LastConnectedAt,
		LastCheckedAt:   row.LastCheckedAt,
		LastError:       row.LastError,
		CreatedAt:       row.CreatedAt,
		UpdatedAt:       row.UpdatedAt,
	}
}

func annotateBackendProviders(providers []tuner.BackendProvider, checkedAt *time.Time) []tuner.BackendProvider {
	if len(providers) == 0 {
		return []tuner.BackendProvider{}
	}
	annotated := make([]tuner.BackendProvider, len(providers))
	for i := range providers {
		provider := providers[i]
		provider.AuthStatusSource = providerAuthStatusSource(provider.ID)
		provider.AuthStatusCheckedAt = checkedAt
		provider.ManagementMode = providerManagementMode(provider.ID)
		if len(provider.Accounts) > 0 {
			accounts := make([]tuner.BackendProviderAccount, len(provider.Accounts))
			for j := range provider.Accounts {
				account := provider.Accounts[j]
				account.AuthStatusSource = provider.AuthStatusSource
				account.AuthStatusCheckedAt = checkedAt
				account.ManagementMode = provider.ManagementMode
				accounts[j] = account
			}
			provider.Accounts = accounts
		}
		annotated[i] = provider
	}
	return annotated
}

func providerAuthStatusSource(providerID string) string {
	switch strings.ToLower(strings.TrimSpace(providerID)) {
	case "directv":
		return "verified"
	default:
		return "snapshot"
	}
}

func providerManagementMode(providerID string) string {
	switch strings.ToLower(strings.TrimSpace(providerID)) {
	case "directv":
		return "full"
	case "sling", "frndlytv", "frndly":
		return "partial"
	default:
		return "snapshot"
	}
}

func (s *Server) buildTunerConnectPayload() gin.H {
	return gin.H{
		"client": gin.H{
			"name":      s.config.Server.Name,
			"machineId": s.config.Server.MachineID,
			"type":      "openflix",
		},
	}
}

func (s *Server) markTunerBackendHealthy(backend *models.TunerBackend) {
	now := time.Now()
	backend.Healthy = true
	backend.LastSeenAt = &now
	backend.LastCheckedAt = &now
	backend.LastError = ""
	_ = s.db.Model(&models.TunerBackend{}).Where("id = ?", backend.ID).Updates(map[string]any{
		"healthy":         true,
		"last_seen_at":    now,
		"last_checked_at": now,
		"last_error":      "",
	}).Error
}

func (s *Server) markTunerBackendError(backend *models.TunerBackend, err error) {
	now := time.Now()
	backend.Healthy = false
	backend.LastCheckedAt = &now
	backend.LastError = err.Error()
	_ = s.db.Model(&models.TunerBackend{}).Where("id = ?", backend.ID).Updates(map[string]any{
		"healthy":         false,
		"last_checked_at": now,
		"last_error":      truncateString(err.Error(), 1000),
	}).Error
}

func parseStringMap(raw string) map[string]string {
	if strings.TrimSpace(raw) == "" {
		return map[string]string{}
	}
	var parsed map[string]string
	if err := json.Unmarshal([]byte(raw), &parsed); err != nil || parsed == nil {
		return map[string]string{}
	}
	return parsed
}

func parseProviders(raw string) []tuner.BackendProvider {
	if strings.TrimSpace(raw) == "" {
		return []tuner.BackendProvider{}
	}
	var parsed []tuner.BackendProvider
	if err := json.Unmarshal([]byte(raw), &parsed); err != nil {
		return []tuner.BackendProvider{}
	}
	return parsed
}

func (s *Server) enrichActiveBackendProviders(ctx context.Context, backend *models.TunerBackend) (*models.TunerBackend, error) {
	providers := parseProviders(backend.ProvidersJSON)
	if len(providers) == 0 {
		return backend, nil
	}

	client := tuner.NewBackendDiscoveryClient()
	changed := false
	for providerIndex := range providers {
		provider := &providers[providerIndex]
		switch provider.ID {
		case "directv":
			if s.enrichDirectvProviderAccounts(ctx, client, backend, provider) {
				changed = true
			}
		}
	}

	if !changed {
		return backend, nil
	}

	enriched := *backend
	enriched.ProvidersJSON = mustJSON(providers)
	return &enriched, nil
}

func (s *Server) enrichDirectvProviderAccounts(ctx context.Context, client *tuner.BackendDiscoveryClient, backend *models.TunerBackend, provider *tuner.BackendProvider) bool {
	changed := false
	provider.AuthStatusSource = "verified"
	provider.AuthStatusCheckedAt = backend.LastCheckedAt
	provider.ManagementMode = "full"
	for accountIndex := range provider.Accounts {
		account := &provider.Accounts[accountIndex]
		var detail map[string]any
		if err := client.FetchJSON(ctx, backend.BaseURL, fmt.Sprintf("/api/providers/directv/accounts/%s", normalizeProviderAccountPathID(account.AccountID)), nil, &detail); err != nil {
			logger.Warnf("directv account detail fetch failed for %s: %v", account.AccountID, err)
			continue
		}
		account.AccountType = firstNonEmpty(strings.TrimSpace(stringValue(detail["accountType"])), account.AccountType)
		account.RecordingMode = firstNonEmpty(strings.TrimSpace(stringValue(detail["recordingMode"])), account.RecordingMode)
		account.CloudDvrCapable = boolValue(detail["cloudDvrCapable"]) || account.CloudDvrCapable
		account.ReceiverDvrCapable = boolValue(detail["receiverDvrCapable"]) || account.ReceiverDvrCapable
		account.CapabilitySource = firstNonEmpty(stringValue(detail["capabilitySource"]), account.CapabilitySource)
		account.DVRState = firstNonEmpty(stringValue(detail["dvrState"]), account.DVRState)
		account.CDVREligibleReceiverID = firstNonEmpty(stringValue(detail["cdvrEligibleReceiverID"]), account.CDVREligibleReceiverID)
		account.CustomerType = firstNonEmpty(stringValue(detail["customerType"]), account.CustomerType)
		account.ServiceDomain = firstNonEmpty(stringValue(detail["serviceDomain"]), account.ServiceDomain)
		account.ProfileID = firstNonEmpty(stringValue(detail["profileId"]), account.ProfileID)
		account.AuthGroups = firstNonEmpty(stringValue(detail["authGroups"]), account.AuthGroups)
		account.PackageInfo = firstNonEmpty(stringValue(detail["packageInfo"]), account.PackageInfo)
		account.PackageIDs = firstNonEmptyStringSlice(extractStringSlice(detail["packageIds"]), account.PackageIDs)
		account.ShortPackageIDs = firstNonEmptyStringSlice(extractStringSlice(detail["shortPackageIds"]), account.ShortPackageIDs)
		account.DVRProfile = mergeDirectvDVRProfile(detail, account)

		uiMode := getDirectvBackendMode(detail, account)
		account.UIMode = uiMode
		account.CanRecord = directvCanRecord(account)
		account.CanSeriesRecord = directvCanSeriesRecord(account)
		account.CanDownload = directvCanDownload(account)
		canUseBackendDvr := directvUsesBackendDVR(account)
		account.CanCancel = canUseBackendDvr
		account.CanDelete = canUseBackendDvr
		account.CanManageSeries = canUseBackendDvr
		account.AuthStatusSource = "verified"
		account.AuthStatusCheckedAt = backend.LastCheckedAt
		account.ManagementMode = "full"
		changed = true
	}
	return changed
}

func mergeDirectvDVRProfile(detail map[string]any, account *tuner.BackendProviderAccount) tuner.BackendDVRProfile {
	profile := account.DVRProfile
	raw := mapField(detail, "dvrProfile")
	if len(raw) == 0 {
		return profile
	}
	profile.Type = firstNonEmpty(strings.TrimSpace(stringValue(raw["type"])), profile.Type)
	profile.Label = firstNonEmpty(strings.TrimSpace(stringValue(raw["label"])), profile.Label)
	if _, ok := raw["canRecord"]; ok {
		profile.CanRecord = boolValue(raw["canRecord"])
	}
	if _, ok := raw["canSeriesRecord"]; ok {
		profile.CanSeriesRecord = boolValue(raw["canSeriesRecord"])
	}
	if _, ok := raw["canDownload"]; ok {
		profile.CanDownload = boolValue(raw["canDownload"])
	}
	profile.PlaybackSource = firstNonEmpty(strings.TrimSpace(stringValue(raw["playbackSource"])), profile.PlaybackSource)
	return profile
}

func getDirectvBackendMode(detail map[string]any, account *tuner.BackendProviderAccount) string {
	if profile := mergeDirectvDVRProfile(detail, account); strings.TrimSpace(profile.Type) != "" {
		switch strings.ToLower(strings.TrimSpace(profile.Type)) {
		case "cloud", "hybrid":
			return "backend-dvr"
		case "receiver":
			return "receiver"
		case "none":
			return "none"
		}
	}
	recordingMode := strings.ToLower(strings.TrimSpace(firstNonEmpty(stringValue(detail["recordingMode"]), account.RecordingMode)))
	accountType := strings.ToLower(strings.TrimSpace(firstNonEmpty(stringValue(detail["accountType"]), account.AccountType)))
	cloudCapable := boolValue(detail["cloudDvrCapable"]) || account.CloudDvrCapable

	if recordingMode == "receiver" || accountType == "receiver_dvr" {
		return "receiver"
	}
	if recordingMode == "cloud" || recordingMode == "hybrid" || accountType == "ott_stream" || accountType == "hybrid_dvr" || cloudCapable {
		return "backend-dvr"
	}
	return "none"
}

func directvUsesBackendDVR(account *tuner.BackendProviderAccount) bool {
	if account == nil {
		return false
	}
	if profileType := strings.ToLower(strings.TrimSpace(account.DVRProfile.Type)); profileType != "" {
		return profileType == "cloud" || profileType == "hybrid"
	}
	return strings.EqualFold(strings.TrimSpace(account.UIMode), "backend-dvr")
}

func directvCanRecord(account *tuner.BackendProviderAccount) bool {
	if account == nil {
		return false
	}
	if profileType := strings.ToLower(strings.TrimSpace(account.DVRProfile.Type)); profileType != "" {
		switch profileType {
		case "cloud", "hybrid":
			return account.DVRProfile.CanRecord
		case "receiver", "none":
			return false
		}
	}
	return account.CanRecord || directvUsesBackendDVR(account)
}

func directvCanSeriesRecord(account *tuner.BackendProviderAccount) bool {
	if account == nil {
		return false
	}
	if profileType := strings.ToLower(strings.TrimSpace(account.DVRProfile.Type)); profileType != "" {
		switch profileType {
		case "cloud", "hybrid":
			return account.DVRProfile.CanSeriesRecord
		case "receiver", "none":
			return false
		}
	}
	return account.CanSeriesRecord || directvUsesBackendDVR(account)
}

func directvCanDownload(account *tuner.BackendProviderAccount) bool {
	if account == nil {
		return false
	}
	if profileType := strings.ToLower(strings.TrimSpace(account.DVRProfile.Type)); profileType != "" {
		switch profileType {
		case "cloud", "hybrid":
			return account.DVRProfile.CanDownload
		case "receiver", "none":
			return false
		}
	}
	return account.CanDownload || directvUsesBackendDVR(account)
}

func extractStringSlice(value any) []string {
	switch typed := value.(type) {
	case []string:
		return typed
	case []any:
		result := make([]string, 0, len(typed))
		for _, item := range typed {
			if v := strings.TrimSpace(stringValue(item)); v != "" {
				result = append(result, v)
			}
		}
		return result
	default:
		return nil
	}
}

func firstNonEmptyStringSlice(values ...[]string) []string {
	for _, value := range values {
		if len(value) > 0 {
			return value
		}
	}
	return nil
}

func mustJSON(value any) string {
	if value == nil {
		return ""
	}
	encoded, err := json.Marshal(value)
	if err != nil {
		return ""
	}
	return string(encoded)
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}

func truncateString(value string, max int) string {
	if len(value) <= max {
		return value
	}
	return value[:max]
}

func maxInt(values ...int) int {
	for _, value := range values {
		if value > 0 {
			return value
		}
	}
	return 0
}
