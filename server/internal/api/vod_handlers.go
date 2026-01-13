package api

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// VOD API Models

// VODProvider represents a streaming provider
type VODProvider struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
	Logo        string `json:"logo,omitempty"`
}

// VODMovie represents a movie from the VOD API
type VODMovie struct {
	ID          string   `json:"id"`
	Type        string   `json:"type,omitempty"`
	Title       string   `json:"title"`
	Description string   `json:"description,omitempty"`
	Year        string   `json:"year,omitempty"`
	Runtime     string   `json:"runtime,omitempty"`
	Rating      string   `json:"rating,omitempty"`
	Genres      []string `json:"genres,omitempty"`
	Poster      string   `json:"poster,omitempty"`
	Category    string   `json:"category,omitempty"`
	DownloadURL string   `json:"downloadUrl,omitempty"`
}

// VODShow represents a TV show from the VOD API
type VODShow struct {
	ID          string   `json:"id"`
	Type        string   `json:"type,omitempty"`
	Title       string   `json:"title"`
	Description string   `json:"description,omitempty"`
	Year        string   `json:"year,omitempty"`
	Rating      string   `json:"rating,omitempty"`
	Genres      []string `json:"genres,omitempty"`
	Poster      string   `json:"poster,omitempty"`
	Category    string   `json:"category,omitempty"`
	SeasonCount int      `json:"seasonCount,omitempty"`
}

// VODSeason represents a season of a TV show
type VODSeason struct {
	SeasonNumber int          `json:"seasonNumber"`
	Episodes     []VODEpisode `json:"episodes,omitempty"`
}

// VODEpisode represents an episode from the VOD API
type VODEpisode struct {
	ID            string `json:"id"`
	EpisodeNumber int    `json:"episodeNumber,omitempty"`
	Title         string `json:"title"`
	Description   string `json:"description,omitempty"`
	Runtime       string `json:"runtime,omitempty"`
	DownloadURL   string `json:"downloadUrl,omitempty"`
}

// VODShowDetails represents detailed show info with seasons
type VODShowDetails struct {
	VODShow
	Seasons []VODSeason `json:"seasons,omitempty"`
}

// VODDownloadRequest represents a download request
type VODDownloadRequest struct {
	ContentID  string `json:"contentId" binding:"required"`
	Type       string `json:"type" binding:"required"` // movie or episode
	OutputPath string `json:"outputPath,omitempty"`    // Server will set this based on library
}

// VODDownloadItem represents an item in the download queue
type VODDownloadItem struct {
	ID        string  `json:"id"`
	ContentID string  `json:"contentId"`
	Title     string  `json:"title"`
	Provider  string  `json:"provider"`
	Status    string  `json:"status"` // queued, downloading, completed, failed
	Progress  float64 `json:"progress"`
	FilePath  string  `json:"filePath,omitempty"`
	Error     string  `json:"error,omitempty"`
}

// VODDownloadQueue represents the download queue response
type VODDownloadQueue struct {
	Items []VODDownloadItem `json:"items"`
}

// ============ VOD Proxy Handlers ============

// getVODAPIURL returns the configured VOD API URL
func (s *Server) getVODAPIURL() string {
	return s.config.VOD.APIURL
}

// proxyVODRequest makes a request to the external VOD API
func (s *Server) proxyVODRequest(method, path string, body io.Reader) (*http.Response, error) {
	apiURL := s.getVODAPIURL()
	if apiURL == "" {
		return nil, fmt.Errorf("VOD API URL not configured")
	}

	// Ensure the URL doesn't have a trailing slash
	apiURL = strings.TrimRight(apiURL, "/")

	fullURL := apiURL + path

	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	req, err := http.NewRequest(method, fullURL, body)
	if err != nil {
		return nil, err
	}

	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	return client.Do(req)
}

// getVODProviders returns available VOD providers
func (s *Server) getVODProviders(c *gin.Context) {
	resp, err := s.proxyVODRequest("GET", "/vod/api/providers", nil)
	if err != nil {
		logger.Errorf("Failed to fetch VOD providers: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "VOD service unavailable: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": string(body)})
		return
	}

	// External API returns {"providers": [...]}
	var response struct {
		Providers []VODProvider `json:"providers"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse response"})
		return
	}

	c.JSON(http.StatusOK, response.Providers)
}

// getVODMovies returns movies for a provider
func (s *Server) getVODMovies(c *gin.Context) {
	provider := c.Param("provider")

	resp, err := s.proxyVODRequest("GET", fmt.Sprintf("/vod/api/%s/movies", provider), nil)
	if err != nil {
		logger.Errorf("Failed to fetch VOD movies: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "VOD service unavailable: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": string(body)})
		return
	}

	// External API returns {"provider": "...", "movies": [...]}
	var response struct {
		Provider string     `json:"provider"`
		Movies   []VODMovie `json:"movies"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse response"})
		return
	}

	c.JSON(http.StatusOK, response.Movies)
}

// getVODShows returns TV shows for a provider
func (s *Server) getVODShows(c *gin.Context) {
	provider := c.Param("provider")

	resp, err := s.proxyVODRequest("GET", fmt.Sprintf("/vod/api/%s/shows", provider), nil)
	if err != nil {
		logger.Errorf("Failed to fetch VOD shows: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "VOD service unavailable: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": string(body)})
		return
	}

	// External API returns {"provider": "...", "shows": [...]}
	var response struct {
		Provider string    `json:"provider"`
		Shows    []VODShow `json:"shows"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse response"})
		return
	}

	c.JSON(http.StatusOK, response.Shows)
}

// getVODGenres returns genres for a provider
func (s *Server) getVODGenres(c *gin.Context) {
	provider := c.Param("provider")

	resp, err := s.proxyVODRequest("GET", fmt.Sprintf("/vod/api/%s/genres", provider), nil)
	if err != nil {
		logger.Errorf("Failed to fetch VOD genres: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "VOD service unavailable: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": string(body)})
		return
	}

	// External API returns {"provider": "...", "genres": [...]}
	var response struct {
		Provider string   `json:"provider"`
		Genres   []string `json:"genres"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse response"})
		return
	}

	c.JSON(http.StatusOK, response.Genres)
}

// getVODMovie returns movie details
func (s *Server) getVODMovie(c *gin.Context) {
	provider := c.Param("provider")
	id := c.Param("id")

	resp, err := s.proxyVODRequest("GET", fmt.Sprintf("/vod/api/%s/movie/%s", provider, id), nil)
	if err != nil {
		logger.Errorf("Failed to fetch VOD movie: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "VOD service unavailable: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": string(body)})
		return
	}

	var movie VODMovie
	if err := json.NewDecoder(resp.Body).Decode(&movie); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse response"})
		return
	}

	c.JSON(http.StatusOK, movie)
}

// getVODShow returns show details with seasons and episodes
func (s *Server) getVODShow(c *gin.Context) {
	provider := c.Param("provider")
	id := c.Param("id")

	resp, err := s.proxyVODRequest("GET", fmt.Sprintf("/vod/api/%s/show/%s", provider, id), nil)
	if err != nil {
		logger.Errorf("Failed to fetch VOD show: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "VOD service unavailable: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": string(body)})
		return
	}

	var show VODShowDetails
	if err := json.NewDecoder(resp.Body).Decode(&show); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse response"})
		return
	}

	c.JSON(http.StatusOK, show)
}

// startVODDownload starts a download with the appropriate output path
func (s *Server) startVODDownload(c *gin.Context) {
	provider := c.Param("provider")

	var input VODDownloadRequest
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Determine output path based on content type
	outputPath, err := s.getVODOutputPath(input.Type)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Create request body with output path
	downloadReq := map[string]interface{}{
		"contentId":  input.ContentID,
		"type":       input.Type,
		"outputPath": outputPath,
	}
	reqBody, _ := json.Marshal(downloadReq)

	resp, err := s.proxyVODRequest("POST", fmt.Sprintf("/vod/api/%s/download/%s", provider, input.ContentID), strings.NewReader(string(reqBody)))
	if err != nil {
		logger.Errorf("Failed to start VOD download: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "VOD service unavailable: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusAccepted {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": string(body)})
		return
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse response"})
		return
	}

	c.JSON(http.StatusOK, result)
}

// getVODOutputPath returns the library path for VOD downloads based on content type
func (s *Server) getVODOutputPath(contentType string) (string, error) {
	var libraryType string
	if contentType == "movie" {
		libraryType = "movie"
	} else if contentType == "episode" {
		libraryType = "show"
	} else {
		return "", fmt.Errorf("invalid content type: %s (must be 'movie' or 'episode')", contentType)
	}

	// Find a library with matching type
	var library models.Library
	if err := s.db.Preload("Paths").Where("type = ?", libraryType).First(&library).Error; err != nil {
		return "", fmt.Errorf("no %s library configured", libraryType)
	}

	if len(library.Paths) == 0 {
		return "", fmt.Errorf("no paths configured for %s library", libraryType)
	}

	return library.Paths[0].Path, nil
}

// getVODQueue returns the download queue
func (s *Server) getVODQueue(c *gin.Context) {
	// Aggregate queues from all providers
	resp, err := s.proxyVODRequest("GET", "/vod/api/queue", nil)
	if err != nil {
		logger.Errorf("Failed to fetch VOD queue: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "VOD service unavailable: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": string(body)})
		return
	}

	var queue VODDownloadQueue
	if err := json.NewDecoder(resp.Body).Decode(&queue); err != nil {
		// Try to decode as array directly
		resp2, _ := s.proxyVODRequest("GET", "/vod/api/queue", nil)
		defer resp2.Body.Close()
		var items []VODDownloadItem
		if err := json.NewDecoder(resp2.Body).Decode(&items); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse response"})
			return
		}
		queue.Items = items
	}

	c.JSON(http.StatusOK, queue)
}

// cancelVODDownload cancels a download
func (s *Server) cancelVODDownload(c *gin.Context) {
	id := c.Param("id")

	resp, err := s.proxyVODRequest("DELETE", fmt.Sprintf("/vod/api/queue/%s", id), nil)
	if err != nil {
		logger.Errorf("Failed to cancel VOD download: %v", err)
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "VOD service unavailable: " + err.Error()})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(resp.StatusCode, gin.H{"error": string(body)})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Download cancelled"})
}

// testVODConnection tests connectivity to the VOD API
func (s *Server) testVODConnection(c *gin.Context) {
	// Allow testing with a URL from query param (for testing before saving)
	apiURL := c.Query("url")
	if apiURL == "" {
		apiURL = s.getVODAPIURL()
	}
	if apiURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"connected": false,
			"error":     "VOD API URL not configured",
		})
		return
	}

	// Make direct request to the provided URL
	apiURL = strings.TrimRight(apiURL, "/")
	fullURL := apiURL + "/vod/api/providers"

	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	resp, err := client.Get(fullURL)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"connected": false,
			"error":     err.Error(),
		})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		c.JSON(http.StatusOK, gin.H{
			"connected": false,
			"error":     fmt.Sprintf("API returned status %d: %s", resp.StatusCode, string(body)),
		})
		return
	}

	// External API returns {"providers": [...]}
	var response struct {
		Providers []VODProvider `json:"providers"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"connected": false,
			"error":     "Failed to parse API response",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"connected":     true,
		"providerCount": len(response.Providers),
		"providers":     response.Providers,
	})
}
