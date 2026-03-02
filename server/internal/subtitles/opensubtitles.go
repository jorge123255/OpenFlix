package subtitles

import (
	"bytes"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

const (
	// OpenSubtitles REST API v1 base URL
	apiBaseURL = "https://api.opensubtitles.com/api/v1"

	// Rate limit: 40 requests per 10 seconds
	rateLimitRequests = 40
	rateLimitWindow   = 10 * time.Second

	// Hash block size for OpenSubtitles hash
	hashBlockSize = 65536 // 64KB
)

// Client is an HTTP client for the OpenSubtitles REST API v2.
type Client struct {
	apiKey     string
	token      string // JWT token from login (optional)
	httpClient *http.Client
	userAgent  string

	// Rate limiting
	mu           sync.Mutex
	requestTimes []time.Time
}

// NewClient creates a new OpenSubtitles API client.
func NewClient(apiKey string) *Client {
	return &Client{
		apiKey: apiKey,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		userAgent:    "OpenFlix v1.0.0",
		requestTimes: make([]time.Time, 0, rateLimitRequests),
	}
}

// SetAPIKey updates the API key.
func (c *Client) SetAPIKey(key string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.apiKey = key
}

// HasAPIKey returns true if an API key is configured.
func (c *Client) HasAPIKey() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.apiKey != ""
}

// waitForRateLimit blocks until a request slot is available.
func (c *Client) waitForRateLimit() {
	c.mu.Lock()
	defer c.mu.Unlock()

	now := time.Now()

	// Prune old timestamps outside the window
	cutoff := now.Add(-rateLimitWindow)
	pruned := c.requestTimes[:0]
	for _, t := range c.requestTimes {
		if t.After(cutoff) {
			pruned = append(pruned, t)
		}
	}
	c.requestTimes = pruned

	// If at the limit, wait until the oldest one expires
	if len(c.requestTimes) >= rateLimitRequests {
		oldest := c.requestTimes[0]
		waitDuration := oldest.Add(rateLimitWindow).Sub(now)
		if waitDuration > 0 {
			c.mu.Unlock()
			time.Sleep(waitDuration)
			c.mu.Lock()
			now = time.Now()
			// Re-prune after sleep
			cutoff = now.Add(-rateLimitWindow)
			pruned = c.requestTimes[:0]
			for _, t := range c.requestTimes {
				if t.After(cutoff) {
					pruned = append(pruned, t)
				}
			}
			c.requestTimes = pruned
		}
	}

	c.requestTimes = append(c.requestTimes, now)
}

// doRequest performs an HTTP request with rate limiting and auth headers.
func (c *Client) doRequest(method, endpoint string, body io.Reader) (*http.Response, error) {
	c.waitForRateLimit()

	reqURL := apiBaseURL + endpoint
	req, err := http.NewRequest(method, reqURL, body)
	if err != nil {
		return nil, fmt.Errorf("creating request: %w", err)
	}

	req.Header.Set("Api-Key", c.apiKey)
	req.Header.Set("User-Agent", c.userAgent)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("executing request: %w", err)
	}

	return resp, nil
}

// ========== API Response Types ==========

// SubtitleSearchResult represents a subtitle search result from the API.
type SubtitleSearchResult struct {
	ID         string                 `json:"id"`
	Type       string                 `json:"type"`
	Attributes SubtitleAttributes     `json:"attributes"`
}

// SubtitleAttributes contains the subtitle attributes.
type SubtitleAttributes struct {
	SubtitleID      string          `json:"subtitle_id"`
	Language        string          `json:"language"`
	DownloadCount   int             `json:"download_count"`
	NewDownloadCount int            `json:"new_download_count"`
	HearingImpaired bool            `json:"hearing_impaired"`
	HD              bool            `json:"hd"`
	FPS             float64         `json:"fps"`
	Votes           int             `json:"votes"`
	Points          int             `json:"points"`
	Ratings         float64         `json:"ratings"`
	FromTrusted     bool            `json:"from_trusted"`
	ForeignPartsOnly bool           `json:"foreign_parts_only"`
	AITranslated    bool            `json:"ai_translated"`
	MachineTranslated bool          `json:"machine_translated"`
	UploadDate      string          `json:"upload_date"`
	Release         string          `json:"release"`
	Comments        string          `json:"comments"`
	LegacySubtitleID int            `json:"legacy_subtitle_id"`
	Uploader        *UploaderInfo   `json:"uploader"`
	FeatureDetails  *FeatureDetails `json:"feature_details"`
	URL             string          `json:"url"`
	RelatedLinks    []RelatedLink   `json:"related_links"`
	Files           []SubtitleFile  `json:"files"`
}

// UploaderInfo contains uploader information.
type UploaderInfo struct {
	UploaderID int    `json:"uploader_id"`
	Name       string `json:"name"`
	Rank       string `json:"rank"`
}

// FeatureDetails contains movie/show details.
type FeatureDetails struct {
	FeatureID   int    `json:"feature_id"`
	FeatureType string `json:"feature_type"`
	Year        int    `json:"year"`
	Title       string `json:"title"`
	MovieName   string `json:"movie_name"`
	IMDBID      int    `json:"imdb_id"`
	TMDBID      int    `json:"tmdb_id"`
	SeasonNumber  int  `json:"season_number"`
	EpisodeNumber int  `json:"episode_number"`
	ParentIMDBID  int  `json:"parent_imdb_id"`
	ParentTitle   string `json:"parent_title"`
	ParentTMDBID  int   `json:"parent_tmdb_id"`
	ParentFeatureID int `json:"parent_feature_id"`
}

// RelatedLink contains a related link.
type RelatedLink struct {
	Label  string `json:"label"`
	URL    string `json:"url"`
	ImgURL string `json:"img_url"`
}

// SubtitleFile contains information about a subtitle file.
type SubtitleFile struct {
	FileID   int    `json:"file_id"`
	CDID     int    `json:"cd_number"`
	FileName string `json:"file_name"`
}

// SearchResponse is the API search response.
type SearchResponse struct {
	TotalPages int                    `json:"total_pages"`
	TotalCount int                    `json:"total_count"`
	Page       int                    `json:"page"`
	Data       []SubtitleSearchResult `json:"data"`
}

// DownloadResponse is the API download response.
type DownloadResponse struct {
	Link         string `json:"link"`
	FileName     string `json:"file_name"`
	Requests     int    `json:"requests"`
	Remaining    int    `json:"remaining"`
	Message      string `json:"message"`
	ResetTime    string `json:"reset_time"`
	ResetTimeUTC string `json:"reset_time_utc"`
}

// ========== API Methods ==========

// SearchByTMDBID searches for subtitles by TMDB ID.
func (c *Client) SearchByTMDBID(tmdbID int, languages []string) (*SearchResponse, error) {
	params := url.Values{}
	params.Set("tmdb_id", fmt.Sprintf("%d", tmdbID))
	if len(languages) > 0 {
		params.Set("languages", strings.Join(languages, ","))
	}

	return c.search(params)
}

// SearchByHash searches for subtitles by OpenSubtitles file hash.
func (c *Client) SearchByHash(hash string, languages []string) (*SearchResponse, error) {
	params := url.Values{}
	params.Set("moviehash", hash)
	if len(languages) > 0 {
		params.Set("languages", strings.Join(languages, ","))
	}

	return c.search(params)
}

// SearchByTitle searches for subtitles by title and optionally year.
func (c *Client) SearchByTitle(title string, year int, languages []string) (*SearchResponse, error) {
	params := url.Values{}
	params.Set("query", title)
	if year > 0 {
		params.Set("year", fmt.Sprintf("%d", year))
	}
	if len(languages) > 0 {
		params.Set("languages", strings.Join(languages, ","))
	}

	return c.search(params)
}

// SearchByEpisode searches for subtitles for a TV episode by TMDB ID, season, and episode.
func (c *Client) SearchByEpisode(tmdbID, season, episode int, languages []string) (*SearchResponse, error) {
	params := url.Values{}
	params.Set("parent_tmdb_id", fmt.Sprintf("%d", tmdbID))
	params.Set("season_number", fmt.Sprintf("%d", season))
	params.Set("episode_number", fmt.Sprintf("%d", episode))
	if len(languages) > 0 {
		params.Set("languages", strings.Join(languages, ","))
	}

	return c.search(params)
}

func (c *Client) search(params url.Values) (*SearchResponse, error) {
	endpoint := "/subtitles?" + params.Encode()

	resp, err := c.doRequest("GET", endpoint, nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("search failed with status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	var result SearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("decoding search response: %w", err)
	}

	return &result, nil
}

// Download requests a download link for a subtitle file.
func (c *Client) Download(fileID int) (*DownloadResponse, error) {
	body := map[string]interface{}{
		"file_id": fileID,
	}
	bodyJSON, err := json.Marshal(body)
	if err != nil {
		return nil, fmt.Errorf("marshaling download request: %w", err)
	}

	resp, err := c.doRequest("POST", "/download", bytes.NewReader(bodyJSON))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("download request failed with status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	var result DownloadResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("decoding download response: %w", err)
	}

	return &result, nil
}

// DownloadFile downloads the actual subtitle file content from a download link.
func (c *Client) DownloadFile(downloadURL string) ([]byte, error) {
	resp, err := c.httpClient.Get(downloadURL)
	if err != nil {
		return nil, fmt.Errorf("downloading subtitle file: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("download file failed with status %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("reading subtitle file: %w", err)
	}

	return data, nil
}

// ========== OpenSubtitles Hash Algorithm ==========

// ComputeHash computes the OpenSubtitles hash for a file.
// The hash is computed from the first and last 64KB of the file combined with the file size.
func ComputeHash(filePath string) (string, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return "", fmt.Errorf("opening file for hash: %w", err)
	}
	defer f.Close()

	fi, err := f.Stat()
	if err != nil {
		return "", fmt.Errorf("stating file for hash: %w", err)
	}

	fileSize := fi.Size()
	if fileSize < hashBlockSize*2 {
		return "", fmt.Errorf("file too small for OpenSubtitles hash (need at least %d bytes, got %d)", hashBlockSize*2, fileSize)
	}

	hash := uint64(fileSize)

	// Read first 64KB
	buf := make([]byte, hashBlockSize)
	if _, err := io.ReadFull(f, buf); err != nil {
		return "", fmt.Errorf("reading first block: %w", err)
	}

	for i := 0; i < hashBlockSize/8; i++ {
		hash += binary.LittleEndian.Uint64(buf[i*8 : (i+1)*8])
	}

	// Read last 64KB
	if _, err := f.Seek(-hashBlockSize, io.SeekEnd); err != nil {
		return "", fmt.Errorf("seeking to last block: %w", err)
	}
	if _, err := io.ReadFull(f, buf); err != nil {
		return "", fmt.Errorf("reading last block: %w", err)
	}

	for i := 0; i < hashBlockSize/8; i++ {
		hash += binary.LittleEndian.Uint64(buf[i*8 : (i+1)*8])
	}

	return fmt.Sprintf("%016x", hash), nil
}

// ========== Login (optional, for higher rate limits) ==========

// Login authenticates with OpenSubtitles to get a JWT token.
// This is optional - API key alone is sufficient for basic usage.
func (c *Client) Login(username, password string) error {
	body := map[string]string{
		"username": username,
		"password": password,
	}
	bodyJSON, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("marshaling login request: %w", err)
	}

	resp, err := c.doRequest("POST", "/login", bytes.NewReader(bodyJSON))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("login failed with status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	var result struct {
		User  interface{} `json:"user"`
		Token string      `json:"token"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return fmt.Errorf("decoding login response: %w", err)
	}

	c.mu.Lock()
	c.token = result.Token
	c.mu.Unlock()

	logger.Info("OpenSubtitles login successful")
	return nil
}
