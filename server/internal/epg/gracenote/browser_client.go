package gracenote

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"strconv"
	"sync"
	"time"

	"github.com/chromedp/cdproto/cdp"
	"github.com/chromedp/cdproto/network"
	"github.com/chromedp/chromedp"
)

// BrowserClient uses headless browser to get real cookies from Gracenote
type BrowserClient struct {
	config     Config
	httpClient *http.Client
	cookies    []*http.Cookie
	cookieMu   sync.RWMutex
	lastWarmup time.Time
}

// NewBrowserClient creates a client that uses browser automation
func NewBrowserClient(config Config) *BrowserClient {
	if config.Timeout == 0 {
		config.Timeout = 30 * time.Second
	}
	if config.UserAgent == "" {
		config.UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
	}

	jar, _ := cookiejar.New(nil)

	return &BrowserClient{
		config: config,
		httpClient: &http.Client{
			Timeout: config.Timeout,
			Jar:     jar,
		},
		cookies: make([]*http.Cookie, 0),
	}
}

// warmupWithBrowser visits Gracenote with headless Chrome to get real cookies
func (c *BrowserClient) warmupWithBrowser(ctx context.Context, affiliateID string) error {
	c.cookieMu.Lock()
	defer c.cookieMu.Unlock()

	// Check if we warmed up recently (within last hour)
	if time.Since(c.lastWarmup) < 1*time.Hour && len(c.cookies) > 0 {
		return nil
	}

	fmt.Println("🌐 Warming up Gracenote session with headless browser...")

	// Create chromedp context with options to avoid bot detection
	opts := append(chromedp.DefaultExecAllocatorOptions[:],
		chromedp.Flag("headless", true),
		chromedp.Flag("disable-blink-features", "AutomationControlled"),
		chromedp.Flag("disable-extensions", true),
		chromedp.UserAgent(c.config.UserAgent),
	)
	allocCtx, allocCancel := chromedp.NewExecAllocator(ctx, opts...)
	defer allocCancel()

	taskCtx, cancel := chromedp.NewContext(allocCtx)
	defer cancel()

	// Set timeout
	taskCtx, cancel = context.WithTimeout(taskCtx, 30*time.Second)
	defer cancel()

	// Visit the main page to get cookies
	targetURL := fmt.Sprintf("%s/grid-affiliates.html?aid=%s", c.config.BaseURL, affiliateID)
	fmt.Printf("🔗 Navigating to: %s\n", targetURL)

	var chromeCookies []*network.Cookie
	err := chromedp.Run(taskCtx,
		chromedp.Navigate(targetURL),
		chromedp.Sleep(5*time.Second), // Wait longer for page to fully load
		chromedp.ActionFunc(func(ctx context.Context) error {
			// Get all cookies using network domain
			cookies, err := network.GetCookies().Do(cdp.WithExecutor(ctx, chromedp.FromContext(ctx).Target))
			if err != nil {
				fmt.Printf("❌ Failed to get cookies: %v\n", err)
				return err
			}
			chromeCookies = cookies
			fmt.Printf("📊 Retrieved %d cookies from browser\n", len(cookies))
			return nil
		}),
	)

	if err != nil {
		return fmt.Errorf("browser warmup failed: %w", err)
	}

	// Warn if no cookies were obtained
	if len(chromeCookies) == 0 {
		fmt.Println("⚠️  Warning: No cookies obtained from browser, requests may fail")
	}

	// Convert chromedp cookies to http.Cookie
	var cookies []*http.Cookie
	parsedURL, _ := url.Parse(c.config.BaseURL)
	for _, cc := range chromeCookies {
		cookie := &http.Cookie{
			Name:     cc.Name,
			Value:    cc.Value,
			Path:     cc.Path,
			Domain:   cc.Domain,
			Expires:  time.Unix(int64(cc.Expires), 0),
			Secure:   cc.Secure,
			HttpOnly: cc.HTTPOnly,
		}
		cookies = append(cookies, cookie)
	}

	// Set cookies in jar
	c.httpClient.Jar.SetCookies(parsedURL, cookies)

	c.cookies = cookies
	c.lastWarmup = time.Now()
	fmt.Printf("✅ Got %d cookies from browser\n", len(cookies))
	return nil
}

// GetAffiliateProperties fetches affiliate configuration
func (c *BrowserClient) GetAffiliateProperties(ctx context.Context, affiliateID, languageCode string) (*AffiliateProperties, error) {
	// Warm up with browser first
	if err := c.warmupWithBrowser(ctx, affiliateID); err != nil {
		fmt.Printf("Warning: browser warmup failed: %v\n", err)
		// Continue anyway, might work
	}

	reqURL := fmt.Sprintf("%s/gapzap_webapi/api/affiliates/getaffiliatesprop/%s/%s",
		c.config.BaseURL, affiliateID, languageCode)

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("User-Agent", c.config.UserAgent)
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Referer", c.config.BaseURL+"/")
	req.Header.Set("Origin", c.config.BaseURL)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("unexpected status code: %d, body: %s", resp.StatusCode, string(body))
	}

	var props AffiliateProperties
	if err := json.NewDecoder(resp.Body).Decode(&props); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &props, nil
}

// DiscoverProviders finds available TV providers for a postal code
func (c *BrowserClient) DiscoverProviders(ctx context.Context, postalCode, country string) ([]Provider, error) {
	// Use a common affiliate ID that works everywhere
	affiliateID := "orbebb"

	// Warm up with browser first
	if err := c.warmupWithBrowser(ctx, affiliateID); err != nil {
		fmt.Printf("Warning: browser warmup failed: %v\n", err)
	}

	reqURL := fmt.Sprintf("%s/gapzap_webapi/api/Providers/getPostalCodeProviders/%s/%s/%s/en-us",
		c.config.BaseURL, country, postalCode, affiliateID)

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("User-Agent", c.config.UserAgent)
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Referer", c.config.BaseURL+"/")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("unexpected status code: %d, body: %s", resp.StatusCode, string(body))
	}

	var providerResp ProviderResponse
	if err := json.NewDecoder(resp.Body).Decode(&providerResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	// Convert to our Provider type, prioritizing Cable providers
	var providers []Provider
	for _, p := range providerResp.Cable {
		providers = append(providers, Provider{
			HeadendID: p.ID,
			Name:      p.Name,
			Type:      "Cable",
			Location:  p.Location,
			LineupID:  fmt.Sprintf("%s-%s-DEFAULT", country, p.ID),
		})
	}
	for _, p := range providerResp.Satellite {
		providers = append(providers, Provider{
			HeadendID: p.ID,
			Name:      p.Name,
			Type:      "Satellite",
			Location:  p.Location,
			LineupID:  fmt.Sprintf("%s-%s-DEFAULT", country, p.ID),
		})
	}
	for _, p := range providerResp.Antenna {
		providers = append(providers, Provider{
			HeadendID: p.ID,
			Name:      p.Name,
			Type:      "Antenna",
			Location:  p.Location,
			LineupID:  fmt.Sprintf("%s-%s-DEFAULT", country, p.ID),
		})
	}

	return providers, nil
}

// GetListingsForProvider fetches TV listings for a specific provider
func (c *BrowserClient) GetListingsForProvider(ctx context.Context, provider Provider, postalCode, country string, hours int) (*GridResponse, error) {
	// Use a common affiliate ID
	affiliateID := "orbebb"

	// Warm up with browser first
	if err := c.warmupWithBrowser(ctx, affiliateID); err != nil {
		fmt.Printf("Warning: browser warmup failed: %v\n", err)
	}

	// Build query parameters
	params := url.Values{}
	params.Set("lineupId", provider.LineupID)
	params.Set("headendId", provider.HeadendID)
	params.Set("country", country)
	params.Set("postalCode", postalCode)
	params.Set("time", strconv.FormatInt(time.Now().Unix(), 10))
	params.Set("timespan", strconv.Itoa(hours))
	params.Set("device", "X")
	params.Set("userId", "-")
	params.Set("aid", affiliateID)
	params.Set("languagecode", "en-us")
	params.Set("isOverride", "true")

	reqURL := fmt.Sprintf("%s/api/grid?%s", c.config.BaseURL, params.Encode())
	fmt.Printf("📡 Gracenote API request: headendId=%s, postalCode=%s, lineupId=%s\n",
		provider.HeadendID, postalCode, provider.LineupID)

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("User-Agent", c.config.UserAgent)
	req.Header.Set("Accept", "application/json, text/plain, */*")
	req.Header.Set("X-Requested-With", "XMLHttpRequest")
	req.Header.Set("Referer", c.config.BaseURL+"/")
	req.Header.Set("Origin", c.config.BaseURL)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("unexpected status code: %d, body: %s", resp.StatusCode, string(body))
	}

	var gridResp GridResponse
	if err := json.NewDecoder(resp.Body).Decode(&gridResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &gridResp, nil
}

// GetListingsForAffiliate fetches TV listings
func (c *BrowserClient) GetListingsForAffiliate(ctx context.Context, affiliateID, postalCode string, hours int) (*GridResponse, error) {
	// Get affiliate properties first
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

	reqURL := fmt.Sprintf("%s/api/grid?%s", c.config.BaseURL, params.Encode())

	req, err := http.NewRequestWithContext(ctx, "GET", reqURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("User-Agent", c.config.UserAgent)
	req.Header.Set("Accept", "application/json, text/plain, */*")
	req.Header.Set("X-Requested-With", "XMLHttpRequest")
	req.Header.Set("Referer", c.config.BaseURL+"/")
	req.Header.Set("Origin", c.config.BaseURL)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("unexpected status code: %d, body: %s", resp.StatusCode, string(body))
	}

	var gridResp GridResponse
	if err := json.NewDecoder(resp.Body).Decode(&gridResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &gridResp, nil
}
