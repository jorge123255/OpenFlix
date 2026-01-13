package livetv

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// interfaceToInt converts an interface{} (which could be int, float64, or string) to int
func interfaceToInt(v interface{}) int {
	if v == nil {
		return 0
	}
	switch val := v.(type) {
	case float64:
		return int(val)
	case int:
		return val
	case int64:
		return int(val)
	case string:
		i, _ := strconv.Atoi(val)
		return i
	default:
		return 0
	}
}

// interfaceToString converts an interface{} to string
func interfaceToString(v interface{}) string {
	if v == nil {
		return ""
	}
	switch val := v.(type) {
	case string:
		return val
	case float64:
		return fmt.Sprintf("%.0f", val)
	case int:
		return strconv.Itoa(val)
	default:
		return fmt.Sprintf("%v", val)
	}
}

// XtreamClient handles Xtream Codes API operations
type XtreamClient struct {
	db         *gorm.DB
	httpClient *http.Client
}

// NewXtreamClient creates a new Xtream client
func NewXtreamClient(db *gorm.DB) *XtreamClient {
	return &XtreamClient{
		db: db,
		httpClient: &http.Client{
			Timeout: 5 * time.Minute, // Large VOD catalogs need more time
		},
	}
}

// ========== Xtream API Response Types ==========

// XtreamAuthResponse represents the authentication response from Xtream API
type XtreamAuthResponse struct {
	UserInfo   XtreamUserInfo   `json:"user_info"`
	ServerInfo XtreamServerInfo `json:"server_info"`
}

// XtreamUserInfo contains user account information
// Note: Some Xtream providers return numbers instead of strings for certain fields
type XtreamUserInfo struct {
	Username             string      `json:"username"`
	Password             string      `json:"password"`
	Message              string      `json:"message"`
	Auth                 interface{} `json:"auth"`
	Status               string      `json:"status"`
	ExpDate              interface{} `json:"exp_date"`
	IsTrial              interface{} `json:"is_trial"`
	ActiveCons           interface{} `json:"active_cons"`
	CreatedAt            interface{} `json:"created_at"`
	MaxConnections       interface{} `json:"max_connections"`
	AllowedOutputFormats []string    `json:"allowed_output_formats"`
}

// XtreamServerInfo contains server information
// Note: Some Xtream providers return numbers instead of strings for port fields
type XtreamServerInfo struct {
	URL            string      `json:"url"`
	Port           interface{} `json:"port"`
	HTTPSPort      interface{} `json:"https_port"`
	ServerProtocol string      `json:"server_protocol"`
	RTMPPort       interface{} `json:"rtmp_port"`
	Timezone       string      `json:"timezone"`
	TimestampNow   interface{} `json:"timestamp_now"`
	TimeNow        string      `json:"time_now"`
}

// XtreamCategory represents a category (live, VOD, or series)
// Note: ParentID uses interface{} because Xtream providers return inconsistent types (string or int)
type XtreamCategory struct {
	CategoryID   string      `json:"category_id"`
	CategoryName string      `json:"category_name"`
	ParentID     interface{} `json:"parent_id"`
}

// XtreamLiveStream represents a live TV stream
// Note: Many fields use interface{} because Xtream providers return inconsistent types
type XtreamLiveStream struct {
	Num               interface{} `json:"num"`
	Name              string      `json:"name"`
	StreamType        string      `json:"stream_type"`
	StreamID          interface{} `json:"stream_id"`
	StreamIcon        string      `json:"stream_icon"`
	EPGChannelID      string      `json:"epg_channel_id"`
	Added             interface{} `json:"added"`
	IsAdult           interface{} `json:"is_adult"`
	CategoryID        interface{} `json:"category_id"`
	CustomSid         string      `json:"custom_sid"`
	TVArchive         interface{} `json:"tv_archive"`
	DirectSource      string      `json:"direct_source"`
	TVArchiveDuration interface{} `json:"tv_archive_duration"`
}

// XtreamVODStream represents a VOD item
// Note: Many fields use interface{} because Xtream providers return inconsistent types
type XtreamVODStream struct {
	Num                interface{} `json:"num"`
	Name               string      `json:"name"`
	StreamType         string      `json:"stream_type"`
	StreamID           interface{} `json:"stream_id"`
	StreamIcon         string      `json:"stream_icon"`
	Rating             interface{} `json:"rating"`
	Rating5Based       interface{} `json:"rating_5based"`
	Added              interface{} `json:"added"`
	IsAdult            interface{} `json:"is_adult"`
	CategoryID         interface{} `json:"category_id"`
	ContainerExtension string      `json:"container_extension"`
	CustomSid          string      `json:"custom_sid"`
	DirectSource       string      `json:"direct_source"`
}

// XtreamVODInfo represents detailed VOD information
type XtreamVODInfo struct {
	Info struct {
		MovieImage     string  `json:"movie_image"`
		TMDBId         string  `json:"tmdb_id"`
		Plot           string  `json:"plot"`
		Cast           string  `json:"cast"`
		Duration       string  `json:"duration"`
		Director       string  `json:"director"`
		Genre          string  `json:"genre"`
		ReleaseDate    string  `json:"releasedate"`
		Rating         string  `json:"rating"`
		BackdropPath   []string `json:"backdrop_path"`
		YoutubeTrailer string  `json:"youtube_trailer"`
		DurationSecs   int     `json:"duration_secs"`
		Bitrate        int     `json:"bitrate"`
		Video          struct {
			Codec  string `json:"codec"`
			Width  int    `json:"width"`
			Height int    `json:"height"`
		} `json:"video"`
		Audio struct {
			Codec    string `json:"codec"`
			Channels int    `json:"channels"`
		} `json:"audio"`
	} `json:"info"`
	MovieData XtreamVODStream `json:"movie_data"`
}

// XtreamSeries represents a series
// Note: Many fields use interface{} because Xtream providers return inconsistent types
type XtreamSeries struct {
	Num            interface{} `json:"num"`
	Name           string      `json:"name"`
	SeriesID       interface{} `json:"series_id"`
	Cover          string      `json:"cover"`
	Plot           string      `json:"plot"`
	Cast           string      `json:"cast"`
	Director       string      `json:"director"`
	Genre          string      `json:"genre"`
	ReleaseDate    string      `json:"releaseDate"`
	LastModified   interface{} `json:"last_modified"`
	Rating         interface{} `json:"rating"`
	Rating5Based   interface{} `json:"rating_5based"`
	BackdropPath   interface{} `json:"backdrop_path"`
	YoutubeTrailer string      `json:"youtube_trailer"`
	TMDBId         interface{} `json:"tmdb_id"`
	CategoryID     interface{} `json:"category_id"`
}

// XtreamSeriesInfo represents detailed series information
type XtreamSeriesInfo struct {
	Seasons  []XtreamSeason            `json:"seasons"`
	Info     XtreamSeriesInfoDetails   `json:"info"`
	Episodes map[string][]XtreamEpisode `json:"episodes"`
}

// XtreamSeason represents a season
type XtreamSeason struct {
	AirDate      string `json:"air_date"`
	EpisodeCount int    `json:"episode_count"`
	ID           int    `json:"id"`
	Name         string `json:"name"`
	Overview     string `json:"overview"`
	SeasonNumber int    `json:"season_number"`
	Cover        string `json:"cover"`
	CoverBig     string `json:"cover_big"`
}

// XtreamSeriesInfoDetails represents series details
type XtreamSeriesInfoDetails struct {
	Name           string   `json:"name"`
	Cover          string   `json:"cover"`
	Plot           string   `json:"plot"`
	Cast           string   `json:"cast"`
	Director       string   `json:"director"`
	Genre          string   `json:"genre"`
	ReleaseDate    string   `json:"releaseDate"`
	LastModified   string   `json:"last_modified"`
	Rating         string   `json:"rating"`
	Rating5Based   float64  `json:"rating_5based"`
	BackdropPath   []string `json:"backdrop_path"`
	YoutubeTrailer string   `json:"youtube_trailer"`
	TMDBId         string   `json:"tmdb_id"`
	CategoryID     string   `json:"category_id"`
}

// XtreamEpisode represents an episode
// Note: Added uses interface{} because Xtream providers return inconsistent types (string or number)
type XtreamEpisode struct {
	ID                 string `json:"id"`
	EpisodeNum         int    `json:"episode_num"`
	Title              string `json:"title"`
	ContainerExtension string `json:"container_extension"`
	Info               struct {
		TMDBId       string `json:"tmdb_id"`
		ReleaseDate  string `json:"releasedate"`
		Plot         string `json:"plot"`
		Duration     string `json:"duration"`
		DurationSecs int    `json:"duration_secs"`
		Bitrate      int    `json:"bitrate"`
		MovieImage   string `json:"movie_image"`
		Video        struct {
			Codec  string `json:"codec"`
			Width  int    `json:"width"`
			Height int    `json:"height"`
		} `json:"video"`
		Audio struct {
			Codec    string `json:"codec"`
			Channels int    `json:"channels"`
		} `json:"audio"`
	} `json:"info"`
	Added        interface{} `json:"added"`
	Season       int         `json:"season"`
	DirectSource string      `json:"direct_source"`
}

// ========== URL Parsing ==========

// ParseCredentialsFromM3U extracts Xtream credentials from an M3U URL
// Supports formats like:
// - http://server:port/get.php?username=X&password=Y&type=m3u_plus
// - http://server:port/username/password/...
func (c *XtreamClient) ParseCredentialsFromM3U(m3uURL string) (*models.XtreamSource, error) {
	parsed, err := url.Parse(m3uURL)
	if err != nil {
		return nil, fmt.Errorf("invalid URL: %w", err)
	}

	source := &models.XtreamSource{
		Enabled:    true,
		ImportLive: true,
	}

	// Try to parse from query parameters (get.php style)
	if strings.Contains(parsed.Path, "get.php") || parsed.RawQuery != "" {
		query := parsed.Query()
		username := query.Get("username")
		password := query.Get("password")

		if username != "" && password != "" {
			source.ServerURL = fmt.Sprintf("%s://%s", parsed.Scheme, parsed.Host)
			source.Username = username
			source.Password = password
			source.Name = fmt.Sprintf("Xtream - %s", parsed.Host)
			return source, nil
		}
	}

	// Try to parse from path (http://server:port/username/password/...)
	pathParts := strings.Split(strings.Trim(parsed.Path, "/"), "/")
	if len(pathParts) >= 2 {
		// Check if it looks like username/password pattern
		// Usually the format is /get.php, /live/username/password, or /username/password
		for i := 0; i < len(pathParts)-1; i++ {
			if pathParts[i] != "get.php" && pathParts[i] != "live" && pathParts[i] != "movie" && pathParts[i] != "series" {
				source.ServerURL = fmt.Sprintf("%s://%s", parsed.Scheme, parsed.Host)
				source.Username = pathParts[i]
				source.Password = pathParts[i+1]
				source.Name = fmt.Sprintf("Xtream - %s", parsed.Host)
				return source, nil
			}
		}
	}

	return nil, fmt.Errorf("could not extract Xtream credentials from URL")
}

// ========== Authentication ==========

// Authenticate tests connection and retrieves account info
func (c *XtreamClient) Authenticate(source *models.XtreamSource) (*XtreamAuthResponse, error) {
	apiURL := c.buildAPIURL(source, "player_api.php", nil)

	resp, err := c.httpClient.Get(apiURL)
	if err != nil {
		return nil, fmt.Errorf("authentication request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("authentication failed with status: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var authResp XtreamAuthResponse
	if err := json.Unmarshal(body, &authResp); err != nil {
		return nil, fmt.Errorf("failed to parse auth response: %w", err)
	}

	// Check auth status - providers return this in different ways:
	// - Some return auth=1 (as int or float64)
	// - Some return status="Active" without auth field
	authOK := false
	switch v := authResp.UserInfo.Auth.(type) {
	case float64:
		authOK = v == 1
	case int:
		authOK = v == 1
	case string:
		authOK = v == "1"
	}

	// Also check status field - some providers use this instead of auth
	if !authOK && (authResp.UserInfo.Status == "Active" || authResp.UserInfo.Status == "active") {
		authOK = true
	}

	if !authOK {
		msg := authResp.UserInfo.Message
		if msg == "" {
			msg = "invalid credentials or account inactive"
		}
		return nil, fmt.Errorf("authentication failed: %s", msg)
	}

	return &authResp, nil
}

// ========== Live Streams ==========

// GetLiveCategories retrieves all live TV categories
func (c *XtreamClient) GetLiveCategories(source *models.XtreamSource) ([]XtreamCategory, error) {
	return c.getCategories(source, "get_live_categories")
}

// GetLiveStreams retrieves live streams, optionally filtered by category
func (c *XtreamClient) GetLiveStreams(source *models.XtreamSource, categoryID string) ([]XtreamLiveStream, error) {
	params := url.Values{}
	if categoryID != "" {
		params.Set("category_id", categoryID)
	}

	apiURL := c.buildAPIURL(source, "player_api.php", params)
	params.Set("action", "get_live_streams")

	resp, err := c.httpClient.Get(apiURL + "&action=get_live_streams")
	if err != nil {
		return nil, fmt.Errorf("failed to get live streams: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var streams []XtreamLiveStream
	if err := json.Unmarshal(body, &streams); err != nil {
		return nil, fmt.Errorf("failed to parse live streams: %w", err)
	}

	return streams, nil
}

// ========== VOD ==========

// GetVODCategories retrieves all VOD categories
func (c *XtreamClient) GetVODCategories(source *models.XtreamSource) ([]XtreamCategory, error) {
	return c.getCategories(source, "get_vod_categories")
}

// GetVODStreams retrieves VOD items, optionally filtered by category
func (c *XtreamClient) GetVODStreams(source *models.XtreamSource, categoryID string) ([]XtreamVODStream, error) {
	params := url.Values{}
	if categoryID != "" {
		params.Set("category_id", categoryID)
	}

	apiURL := c.buildAPIURL(source, "player_api.php", params)

	resp, err := c.httpClient.Get(apiURL + "&action=get_vod_streams")
	if err != nil {
		return nil, fmt.Errorf("failed to get VOD streams: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var streams []XtreamVODStream
	if err := json.Unmarshal(body, &streams); err != nil {
		return nil, fmt.Errorf("failed to parse VOD streams: %w", err)
	}

	return streams, nil
}

// GetVODInfo retrieves detailed information about a VOD item
func (c *XtreamClient) GetVODInfo(source *models.XtreamSource, vodID int) (*XtreamVODInfo, error) {
	params := url.Values{}
	params.Set("vod_id", strconv.Itoa(vodID))

	apiURL := c.buildAPIURL(source, "player_api.php", params)

	resp, err := c.httpClient.Get(apiURL + "&action=get_vod_info")
	if err != nil {
		return nil, fmt.Errorf("failed to get VOD info: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var info XtreamVODInfo
	if err := json.Unmarshal(body, &info); err != nil {
		return nil, fmt.Errorf("failed to parse VOD info: %w", err)
	}

	return &info, nil
}

// ========== Series ==========

// GetSeriesCategories retrieves all series categories
func (c *XtreamClient) GetSeriesCategories(source *models.XtreamSource) ([]XtreamCategory, error) {
	return c.getCategories(source, "get_series_categories")
}

// GetSeries retrieves series, optionally filtered by category
func (c *XtreamClient) GetSeries(source *models.XtreamSource, categoryID string) ([]XtreamSeries, error) {
	params := url.Values{}
	if categoryID != "" {
		params.Set("category_id", categoryID)
	}

	apiURL := c.buildAPIURL(source, "player_api.php", params)

	resp, err := c.httpClient.Get(apiURL + "&action=get_series")
	if err != nil {
		return nil, fmt.Errorf("failed to get series: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var series []XtreamSeries
	if err := json.Unmarshal(body, &series); err != nil {
		return nil, fmt.Errorf("failed to parse series: %w", err)
	}

	return series, nil
}

// GetSeriesInfo retrieves detailed information about a series
func (c *XtreamClient) GetSeriesInfo(source *models.XtreamSource, seriesID int) (*XtreamSeriesInfo, error) {
	params := url.Values{}
	params.Set("series_id", strconv.Itoa(seriesID))

	apiURL := c.buildAPIURL(source, "player_api.php", params)

	resp, err := c.httpClient.Get(apiURL + "&action=get_series_info")
	if err != nil {
		return nil, fmt.Errorf("failed to get series info: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var info XtreamSeriesInfo
	if err := json.Unmarshal(body, &info); err != nil {
		return nil, fmt.Errorf("failed to parse series info: %w", err)
	}

	return &info, nil
}

// ========== URL Builders ==========

// BuildLiveStreamURL constructs a live stream URL
func (c *XtreamClient) BuildLiveStreamURL(source *models.XtreamSource, streamID int) string {
	return fmt.Sprintf("%s/live/%s/%s/%d.ts",
		strings.TrimRight(source.ServerURL, "/"),
		source.Username,
		source.Password,
		streamID,
	)
}

// BuildVODStreamURL constructs a VOD stream URL
func (c *XtreamClient) BuildVODStreamURL(source *models.XtreamSource, streamID int, ext string) string {
	if ext == "" {
		ext = "mp4"
	}
	return fmt.Sprintf("%s/movie/%s/%s/%d.%s",
		strings.TrimRight(source.ServerURL, "/"),
		source.Username,
		source.Password,
		streamID,
		ext,
	)
}

// BuildSeriesStreamURL constructs a series episode stream URL
func (c *XtreamClient) BuildSeriesStreamURL(source *models.XtreamSource, streamID int, ext string) string {
	if ext == "" {
		ext = "mp4"
	}
	return fmt.Sprintf("%s/series/%s/%s/%d.%s",
		strings.TrimRight(source.ServerURL, "/"),
		source.Username,
		source.Password,
		streamID,
		ext,
	)
}

// ========== Channel Import ==========

// ImportChannels imports live TV channels from an Xtream source
func (c *XtreamClient) ImportChannels(sourceID uint) (added, updated int, err error) {
	var source models.XtreamSource
	if err := c.db.First(&source, sourceID).Error; err != nil {
		return 0, 0, fmt.Errorf("source not found: %w", err)
	}

	if !source.ImportLive {
		return 0, 0, nil
	}

	// Get all live streams
	streams, err := c.GetLiveStreams(&source, "")
	if err != nil {
		return 0, 0, fmt.Errorf("failed to get live streams: %w", err)
	}

	// Get categories for group names
	categories, err := c.GetLiveCategories(&source)
	if err != nil {
		log.Printf("Warning: failed to get categories: %v", err)
	}

	categoryMap := make(map[string]string)
	for _, cat := range categories {
		categoryMap[cat.CategoryID] = cat.CategoryName
	}

	for _, stream := range streams {
		// Convert interface{} types to proper types
		streamID := interfaceToInt(stream.StreamID)
		categoryIDStr := interfaceToString(stream.CategoryID)

		// Build stream URL
		streamURL := c.BuildLiveStreamURL(&source, streamID)

		// Check if channel already exists
		var existingChannel models.Channel
		err := c.db.Where("xtream_source_id = ? AND xtream_stream_id = ?", source.ID, streamID).
			First(&existingChannel).Error

		channel := models.Channel{
			Name:             stream.Name,
			Logo:             stream.StreamIcon,
			StreamURL:        streamURL,
			Enabled:          true,
			SourceType:       "xtream",
			SourceName:       source.Name,
			XtreamSourceID:   &source.ID,
			XtreamStreamID:   &streamID,
			ChannelID:        stream.EPGChannelID,
			TVGId:            stream.EPGChannelID,
		}

		// Set category/group
		if catName, ok := categoryMap[categoryIDStr]; ok {
			channel.Group = catName
		}
		if catID, err := strconv.Atoi(categoryIDStr); err == nil {
			channel.XtreamCategoryID = &catID
		}

		if err == gorm.ErrRecordNotFound {
			// Create new channel
			if err := c.db.Create(&channel).Error; err != nil {
				log.Printf("Failed to create channel %s: %v", stream.Name, err)
				continue
			}
			added++
		} else if err == nil {
			// Update existing channel
			channel.ID = existingChannel.ID
			channel.M3USourceID = existingChannel.M3USourceID // Preserve original M3U source
			channel.IsFavorite = existingChannel.IsFavorite
			channel.Enabled = existingChannel.Enabled

			if err := c.db.Save(&channel).Error; err != nil {
				log.Printf("Failed to update channel %s: %v", stream.Name, err)
				continue
			}
			updated++
		}
	}

	// Update source stats
	source.ChannelCount = added + updated
	source.LastFetched = timePtr(time.Now())
	c.db.Save(&source)

	return added, updated, nil
}

// ========== Helper Functions ==========

func (c *XtreamClient) buildAPIURL(source *models.XtreamSource, endpoint string, params url.Values) string {
	if params == nil {
		params = url.Values{}
	}
	params.Set("username", source.Username)
	params.Set("password", source.Password)

	return fmt.Sprintf("%s/%s?%s",
		strings.TrimRight(source.ServerURL, "/"),
		endpoint,
		params.Encode(),
	)
}

func (c *XtreamClient) getCategories(source *models.XtreamSource, action string) ([]XtreamCategory, error) {
	apiURL := c.buildAPIURL(source, "player_api.php", nil)

	resp, err := c.httpClient.Get(apiURL + "&action=" + action)
	if err != nil {
		return nil, fmt.Errorf("failed to get categories: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	var categories []XtreamCategory
	if err := json.Unmarshal(body, &categories); err != nil {
		return nil, fmt.Errorf("failed to parse categories: %w", err)
	}

	return categories, nil
}

func timePtr(t time.Time) *time.Time {
	return &t
}

// IsXtreamURL checks if a URL appears to be an Xtream Codes URL
func IsXtreamURL(urlStr string) bool {
	// Check for common Xtream URL patterns
	xtreamPatterns := []string{
		`get\.php\?.*username=.*password=`,
		`/live/[^/]+/[^/]+/`,
		`player_api\.php`,
	}

	for _, pattern := range xtreamPatterns {
		matched, _ := regexp.MatchString(pattern, urlStr)
		if matched {
			return true
		}
	}

	return false
}
