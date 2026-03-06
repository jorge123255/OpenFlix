package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

const tmdbImageBaseURL = "https://image.tmdb.org/t/p/w500"

type tmdbShowSearchResponse struct {
	Results []tmdbShowSearchItem `json:"results"`
}

type tmdbShowSearchItem struct {
	ID           int     `json:"id"`
	Name         string  `json:"name"`
	Overview     string  `json:"overview"`
	PosterPath   string  `json:"poster_path"`
	FirstAirDate string  `json:"first_air_date"`
	VoteAverage  float64 `json:"vote_average"`
}

type tmdbNetwork struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type tmdbShowDetailsResponse struct {
	ID              int           `json:"id"`
	Name            string        `json:"name"`
	Status          string        `json:"status"`
	NumberOfSeasons int           `json:"number_of_seasons"`
	Networks        []tmdbNetwork `json:"networks"`
}

type showMatchedChannel struct {
	ChannelID     string `json:"channel_id"`
	ChannelName   string `json:"channel_name"`
	ChannelNumber int    `json:"channel_number"`
	ChannelLogo   string `json:"channel_logo"`
}

type tmdbShowResult struct {
	TMDBID          int                  `json:"tmdb_id"`
	Title           string               `json:"title"`
	Overview        string               `json:"overview"`
	PosterPath      string               `json:"poster_path"`
	FirstAirDate    string               `json:"first_air_date"`
	VoteAverage     float64              `json:"vote_average"`
	Status          string               `json:"status"`
	NumberOfSeasons int                  `json:"number_of_seasons"`
	Networks        []tmdbNetwork        `json:"networks"`
	MatchedChannels []showMatchedChannel `json:"matched_channels"`
}

// handleShowSearch handles GET /api/shows/search?q=<query>
func (s *Server) handleShowSearch(c *gin.Context) {
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Query parameter q is required"})
		return
	}

	if s.config.Library.TMDBApiKey == "" {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "TMDB API key not configured"})
		return
	}

	searchURL := fmt.Sprintf("https://api.themoviedb.org/3/search/tv?api_key=%s&query=%s",
		s.config.Library.TMDBApiKey, url.QueryEscape(query))

	resp, err := http.Get(searchURL)
	if err != nil {
		logger.Errorf("show search: TMDB search failed: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search TMDB"})
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		logger.Errorf("show search: TMDB search returned status %d", resp.StatusCode)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search TMDB"})
		return
	}

	var tmdbResp tmdbShowSearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&tmdbResp); err != nil {
		logger.Errorf("show search: failed to parse TMDB response: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse TMDB response"})
		return
	}

	var channels []models.Channel
	if err := s.db.Where("enabled = ?", true).Find(&channels).Error; err != nil {
		logger.Errorf("show search: failed to load channels: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load channel lineup"})
		return
	}

	// Fetch TMDB details concurrently for all results
	results := make([]tmdbShowResult, len(tmdbResp.Results))
	var wg sync.WaitGroup
	var mu sync.Mutex
	var fetchErr error

	for i, item := range tmdbResp.Results {
		wg.Add(1)
		go func(idx int, it tmdbShowSearchItem) {
			defer wg.Done()

			details, err := s.fetchTMDBShowDetails(it.ID)
			if err != nil {
				logger.Errorf("show search: failed to fetch TMDB details for %d: %v", it.ID, err)
				mu.Lock()
				if fetchErr == nil {
					fetchErr = err
				}
				mu.Unlock()
				return
			}

			poster := ""
			if it.PosterPath != "" {
				poster = tmdbImageBaseURL + it.PosterPath
			}

			results[idx] = tmdbShowResult{
				TMDBID:          it.ID,
				Title:           it.Name,
				Overview:        it.Overview,
				PosterPath:      poster,
				FirstAirDate:    it.FirstAirDate,
				VoteAverage:     it.VoteAverage,
				Status:          details.Status,
				NumberOfSeasons: details.NumberOfSeasons,
				Networks:        details.Networks,
				MatchedChannels: matchNetworksToChannels(details.Networks, channels),
			}
		}(i, item)
	}
	wg.Wait()

	if fetchErr != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch TMDB show details"})
		return
	}

	// Filter out empty results (from failed fetches)
	filtered := make([]tmdbShowResult, 0, len(results))
	for _, r := range results {
		if r.TMDBID != 0 {
			filtered = append(filtered, r)
		}
	}

	c.JSON(http.StatusOK, gin.H{"results": filtered})
}

// handleShowAirings handles GET /api/shows/:tmdb_id/airings?channel_id=<id>
func (s *Server) handleShowAirings(c *gin.Context) {
	tmdbIDStr := c.Param("tmdb_id")
	channelID := c.Query("channel_id")

	if tmdbIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "TMDB ID is required"})
		return
	}
	if channelID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Query parameter channel_id is required"})
		return
	}
	if s.config.Library.TMDBApiKey == "" {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "TMDB API key not configured"})
		return
	}

	tmdbID, err := strconv.Atoi(tmdbIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid TMDB ID"})
		return
	}

	details, err := s.fetchTMDBShowDetails(tmdbID)
	if err != nil {
		logger.Errorf("show airings: failed to fetch TMDB details for %d: %v", tmdbID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch TMDB show details"})
		return
	}

	showTitle := strings.TrimSpace(details.Name)
	if showTitle == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "TMDB show title is empty"})
		return
	}

	now := time.Now().UTC()
	var programs []models.Program
	if err := s.db.
		Where("channel_id = ? AND start >= ? AND LOWER(title) LIKE ?",
			channelID, now, "%"+strings.ToLower(showTitle)+"%").
		Order("start ASC").
		Find(&programs).Error; err != nil {
		logger.Errorf("show airings: failed to query programs: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load program airings"})
		return
	}

	type airing struct {
		StartTime string `json:"start_time"`
		EndTime   string `json:"end_time"`
		Subtitle  string `json:"subtitle"`
		IsNew     bool   `json:"is_new"`
	}

	airings := make([]airing, 0, len(programs))
	for _, program := range programs {
		airings = append(airings, airing{
			StartTime: program.Start.Format(time.RFC3339),
			EndTime:   program.End.Format(time.RFC3339),
			Subtitle:  program.Subtitle,
			IsNew:     program.IsNew,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"show_title": details.Name,
		"channel_id": channelID,
		"airings":    airings,
	})
}

// fetchTMDBShowDetails fetches full show details (status, seasons, networks) from TMDB.
func (s *Server) fetchTMDBShowDetails(tmdbID int) (*tmdbShowDetailsResponse, error) {
	detailsURL := fmt.Sprintf("https://api.themoviedb.org/3/tv/%d?api_key=%s",
		tmdbID, s.config.Library.TMDBApiKey)
	resp, err := http.Get(detailsURL)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("tmdb returned status %d", resp.StatusCode)
	}

	var details tmdbShowDetailsResponse
	if err := json.NewDecoder(resp.Body).Decode(&details); err != nil {
		return nil, err
	}
	return &details, nil
}

// matchNetworksToChannels cross-references TMDB network names against the local channel lineup.
// Uses word-boundary matching to avoid false positives (e.g. "NBC" should not match "CNBC").
func matchNetworksToChannels(networks []tmdbNetwork, channels []models.Channel) []showMatchedChannel {
	matched := make([]showMatchedChannel, 0)
	seen := make(map[string]struct{})

	for _, network := range networks {
		networkName := strings.ToLower(strings.TrimSpace(network.Name))
		if networkName == "" {
			continue
		}
		for _, ch := range channels {
			chName := strings.ToLower(strings.TrimSpace(ch.Name))
			if chName == "" {
				continue
			}
			if matchesNetwork(chName, networkName) {
				key := ch.ChannelID
				if key == "" {
					key = strconv.FormatUint(uint64(ch.ID), 10)
				}
				if _, exists := seen[key]; exists {
					continue
				}
				seen[key] = struct{}{}
				matched = append(matched, showMatchedChannel{
					ChannelID:     key,
					ChannelName:   ch.Name,
					ChannelNumber: ch.Number,
					ChannelLogo:   ch.Logo,
				})
			}
		}
	}
	// Sort: prefer shorter channel names (more likely the primary affiliate)
	// and lower channel numbers
	sort.Slice(matched, func(i, j int) bool {
		// Prefer channels with just the network name (e.g. "NBC 5" over "NBC Sports Boston")
		iLen := len(matched[i].ChannelName)
		jLen := len(matched[j].ChannelName)
		if iLen != jLen {
			return iLen < jLen
		}
		return matched[i].ChannelNumber < matched[j].ChannelNumber
	})
	return matched
}

// matchesNetwork checks if a channel name matches a network name using word-boundary logic.
// "nbc" matches "NBC 5", "NBC Sports", "WMAQ NBC 5 Chicago" but NOT "CNBC".
func matchesNetwork(channelName, networkName string) bool {
	// Exact match
	if channelName == networkName {
		return true
	}
	// Check if network name appears as a word boundary in channel name
	idx := strings.Index(channelName, networkName)
	if idx == -1 {
		return false
	}
	// Check left boundary: must be start of string or preceded by non-alphanumeric
	if idx > 0 {
		prev := channelName[idx-1]
		if (prev >= 'a' && prev <= 'z') || (prev >= '0' && prev <= '9') {
			return false
		}
	}
	// Check right boundary: must be end of string or followed by non-alphanumeric
	endIdx := idx + len(networkName)
	if endIdx < len(channelName) {
		next := channelName[endIdx]
		if (next >= 'a' && next <= 'z') || (next >= '0' && next <= '9') {
			return false
		}
	}
	return true
}
