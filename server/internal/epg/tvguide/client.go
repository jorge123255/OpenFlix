package tvguide

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sync"
	"time"
)

const (
	baseURL       = "https://backend.tvguide.com/tvschedules/tvguide"
	defaultUA     = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
	maxDuration   = 312 * 60 // 13 days in minutes (API cap)
	defaultWorkers = 10
)

// Client handles requests to the TVGuide backend API
type Client struct {
	httpClient *http.Client
	userAgent  string
}

// NewClient creates a new TVGuide API client
func NewClient() *Client {
	return &Client{
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
		userAgent: defaultUA,
	}
}

// doRequest performs an HTTP GET with standard headers
func (c *Client) doRequest(ctx context.Context, url string) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("User-Agent", c.userAgent)
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("unexpected status %d: %s", resp.StatusCode, string(body[:min(len(body), 200)]))
	}

	return io.ReadAll(resp.Body)
}

// GetProvidersByZip returns available TV providers for a US zip code
func (c *Client) GetProvidersByZip(ctx context.Context, zipCode string) ([]Provider, error) {
	url := fmt.Sprintf("%s/serviceproviders/zipcode/%s/web", baseURL, zipCode)

	data, err := c.doRequest(ctx, url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch providers: %w", err)
	}

	var resp ProviderResponse
	if err := json.Unmarshal(data, &resp); err != nil {
		return nil, fmt.Errorf("failed to decode providers: %w", err)
	}

	return resp.Data.Items, nil
}

// GetSchedule fetches the channel schedule/listings for a provider
// durationMinutes is capped at maxDuration (~13 days)
func (c *Client) GetSchedule(ctx context.Context, providerID string, durationMinutes int) (*FetchResult, error) {
	startTime := time.Now()

	if durationMinutes > maxDuration {
		durationMinutes = maxDuration
	}
	if durationMinutes <= 0 {
		durationMinutes = 120 // default 2 hours
	}

	now := time.Now().Unix()
	url := fmt.Sprintf("%s/%s/web?start=%d&duration=%d", baseURL, providerID, now, durationMinutes)

	data, err := c.doRequest(ctx, url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch schedule: %w", err)
	}

	var resp ScheduleResponse
	if err := json.Unmarshal(data, &resp); err != nil {
		return nil, fmt.Errorf("failed to decode schedule: %w", err)
	}

	return &FetchResult{
		Channels:  resp.Data.Items,
		FetchedAt: time.Now(),
		Duration:  time.Since(startTime),
	}, nil
}

// GetProgramDetail fetches detailed info for a single program
func (c *Client) GetProgramDetail(ctx context.Context, programID int) (*ProgramDetail, error) {
	url := fmt.Sprintf("%s/programdetails/%d/web", baseURL, programID)

	data, err := c.doRequest(ctx, url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch program detail: %w", err)
	}

	var resp ProgramDetailResponse
	if err := json.Unmarshal(data, &resp); err != nil {
		return nil, fmt.Errorf("failed to decode program detail: %w", err)
	}

	return &resp.Data.Item, nil
}

// GetProgramDetails fetches details for multiple programs in parallel
// Returns a map of programID -> ProgramDetail
func (c *Client) GetProgramDetails(ctx context.Context, programIDs []int, workers int) map[int]*ProgramDetail {
	if workers <= 0 {
		workers = defaultWorkers
	}

	results := make(map[int]*ProgramDetail)
	var mu sync.Mutex
	sem := make(chan struct{}, workers)
	var wg sync.WaitGroup

	for _, pid := range programIDs {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()

			detail, err := c.GetProgramDetail(ctx, id)
			if err != nil {
				return // silently skip failures
			}

			mu.Lock()
			results[id] = detail
			mu.Unlock()
		}(pid)
	}

	wg.Wait()
	return results
}

// FetchFullListings fetches schedule + optionally enriches with program details
func (c *Client) FetchFullListings(ctx context.Context, config ProviderConfig) (*FetchResult, map[int]*ProgramDetail, error) {
	durationMinutes := config.Hours * 60
	if durationMinutes <= 0 {
		durationMinutes = 120
	}

	// Fetch schedule
	result, err := c.GetSchedule(ctx, config.ProviderID, durationMinutes)
	if err != nil {
		return nil, nil, err
	}

	// Optionally fetch program details
	var details map[int]*ProgramDetail
	if config.FetchDetails {
		// Collect unique program IDs
		seen := make(map[int]bool)
		var programIDs []int
		for _, ch := range result.Channels {
			for _, sched := range ch.ProgramSchedules {
				if !seen[sched.ProgramID] {
					seen[sched.ProgramID] = true
					programIDs = append(programIDs, sched.ProgramID)
				}
			}
		}

		details = c.GetProgramDetails(ctx, programIDs, defaultWorkers)
	}

	return result, details, nil
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
