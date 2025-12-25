package gracenote

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

// Config holds Gracenote client configuration
type Config struct {
	BaseURL   string
	UserAgent string
	Timeout   time.Duration
}

// Client handles requests to the Gracenote TV listings API
type Client struct {
	config     Config
	httpClient *http.Client
}

// NewClient creates a new Gracenote API client
func NewClient(config Config) *Client {
	if config.Timeout == 0 {
		config.Timeout = 30 * time.Second
	}
	if config.UserAgent == "" {
		config.UserAgent = "Mozilla/5.0 (compatible; Plezy/1.0)"
	}

	return &Client{
		config: config,
		httpClient: &http.Client{
			Timeout: config.Timeout,
		},
	}
}

// GetListingsForAffiliate fetches TV listings for a specific affiliate
func (c *Client) GetListingsForAffiliate(ctx context.Context, affiliateID, postalCode string, hours int) (*GridResponse, error) {
	// First, get affiliate properties to determine lineup details
	props, err := c.GetAffiliateProperties(ctx, affiliateID, "en-us")
	if err != nil {
		return nil, fmt.Errorf("failed to get affiliate properties: %w", err)
	}

	// Build lineup ID
	lineupID := fmt.Sprintf("%s-%s-DEFAULT", props.DefaultCountry, props.DefaultHeadend)
	if props.LineupID != "" {
		lineupID = props.LineupID
	}

	// Build query parameters
	params := url.Values{}
	params.Set("lineupId", lineupID)
	params.Set("headendId", props.DefaultHeadend)
	params.Set("country", props.DefaultCountry)
	params.Set("postalCode", postalCode)
	params.Set("time", strconv.FormatInt(time.Now().Unix(), 10))
	params.Set("timespan", strconv.Itoa(hours))
	params.Set("device", props.Device)
	params.Set("userId", "-")
	params.Set("aid", affiliateID)
	params.Set("languagecode", "en-us")

	// Build request URL
	reqURL := fmt.Sprintf("%s/api/grid?%s", c.config.BaseURL, params.Encode())

	// Create request
	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers (from Proxyman capture)
	req.Header.Set("User-Agent", c.config.UserAgent)
	req.Header.Set("Accept", "application/json, text/plain, */*")
	req.Header.Set("X-Requested-With", "XMLHttpRequest")
	req.Header.Set("Referer", "https://tvlistings.gracenote.com/")
	req.Header.Set("Origin", "https://tvlistings.gracenote.com")

	// Execute request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	// Parse response
	var gridResp GridResponse
	if err := json.NewDecoder(resp.Body).Decode(&gridResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &gridResp, nil
}

// GetAffiliateProperties fetches configuration for a specific affiliate
func (c *Client) GetAffiliateProperties(ctx context.Context, affiliateID, languageCode string) (*AffiliateProperties, error) {
	// Build request URL
	reqURL := fmt.Sprintf("%s/gapzap_webapi/api/affiliates/getaffiliatesprop/%s/%s",
		c.config.BaseURL, affiliateID, languageCode)

	// Create request
	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("User-Agent", c.config.UserAgent)
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Referer", "https://tvlistings.gracenote.com/")
	req.Header.Set("Origin", "https://tvlistings.gracenote.com")

	// Execute request
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	// Parse response
	var props AffiliateProperties
	if err := json.NewDecoder(resp.Body).Decode(&props); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &props, nil
}
