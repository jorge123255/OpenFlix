package ddns

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// Provider identifies the DDNS service provider.
type Provider string

const (
	ProviderNoIP       Provider = "noip"
	ProviderDuckDNS    Provider = "duckdns"
	ProviderCloudflare Provider = "cloudflare"
	ProviderCustom     Provider = "custom"
)

// Config holds the DDNS configuration.
type Config struct {
	Enabled        bool     `json:"enabled"`
	Provider       Provider `json:"provider"`
	Hostname       string   `json:"hostname"`
	Username       string   `json:"username,omitempty"`        // No-IP
	Password       string   `json:"password,omitempty"`        // No-IP
	Token          string   `json:"token,omitempty"`           // DuckDNS / Cloudflare
	ZoneID         string   `json:"zone_id,omitempty"`         // Cloudflare
	RecordID       string   `json:"record_id,omitempty"`       // Cloudflare (auto-resolved if empty)
	Proxied        bool     `json:"proxied,omitempty"`         // Cloudflare
	CustomURL      string   `json:"custom_url,omitempty"`      // Custom provider URL with {IP} placeholder
	UpdateInterval int      `json:"update_interval,omitempty"` // seconds, default 300 (5 min)
}

// Status reports the current state of the DDNS client.
type Status struct {
	Enabled        bool      `json:"enabled"`
	Provider       Provider  `json:"provider"`
	Hostname       string    `json:"hostname"`
	CurrentIP      string    `json:"current_ip"`
	LastUpdate     time.Time `json:"last_update"`
	LastError      string    `json:"last_error,omitempty"`
	UpdateCount    int       `json:"update_count"`
	Running        bool      `json:"running"`
	UpdateInterval int       `json:"update_interval"`
}

// ipServices lists public IP detection endpoints in priority order.
var ipServices = []string{
	"https://api.ipify.org",
	"https://ifconfig.me/ip",
	"https://icanhazip.com",
}

// Client manages dynamic DNS updates.
type Client struct {
	mu          sync.RWMutex
	config      Config
	currentIP   string
	lastUpdate  time.Time
	lastError   string
	updateCount int
	running     bool
	cancel      context.CancelFunc
	httpClient  *http.Client
}

// New creates a new DDNS client.
func New() *Client {
	return &Client{
		httpClient: &http.Client{Timeout: 15 * time.Second},
	}
}

// Configure applies a new configuration and restarts the update loop if enabled.
func (c *Client) Configure(cfg Config) {
	c.mu.Lock()
	defer c.mu.Unlock()

	// Stop existing loop if running
	if c.cancel != nil {
		c.cancel()
		c.cancel = nil
		c.running = false
	}

	if cfg.UpdateInterval <= 0 {
		cfg.UpdateInterval = 300 // 5 minutes default
	}

	c.config = cfg
	c.lastError = ""

	if cfg.Enabled {
		c.startLocked()
	}
}

// Stop stops the periodic update loop.
func (c *Client) Stop() {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.cancel != nil {
		c.cancel()
		c.cancel = nil
		c.running = false
	}
}

// Disable stops the client and clears the configuration.
func (c *Client) Disable() {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.cancel != nil {
		c.cancel()
		c.cancel = nil
	}
	c.config = Config{}
	c.running = false
	c.currentIP = ""
	c.lastError = ""
}

// ForceUpdate triggers an immediate DNS update regardless of whether the IP has changed.
func (c *Client) ForceUpdate() error {
	c.mu.RLock()
	cfg := c.config
	c.mu.RUnlock()

	if !cfg.Enabled {
		return fmt.Errorf("DDNS is not enabled")
	}

	ip, err := c.detectPublicIP()
	if err != nil {
		c.setError(fmt.Sprintf("IP detection failed: %v", err))
		return err
	}

	err = c.updateDNS(cfg, ip)
	if err != nil {
		c.setError(fmt.Sprintf("DNS update failed: %v", err))
		return err
	}

	c.mu.Lock()
	c.currentIP = ip
	c.lastUpdate = time.Now()
	c.lastError = ""
	c.updateCount++
	c.mu.Unlock()

	logger.Infof("DDNS force update successful: %s -> %s", cfg.Hostname, ip)
	return nil
}

// TestConfig tests a configuration without saving it.
func (c *Client) TestConfig(cfg Config) error {
	ip, err := c.detectPublicIP()
	if err != nil {
		return fmt.Errorf("IP detection failed: %w", err)
	}

	err = c.updateDNS(cfg, ip)
	if err != nil {
		return fmt.Errorf("DNS update failed: %w", err)
	}

	return nil
}

// GetStatus returns the current DDNS status.
func (c *Client) GetStatus() Status {
	c.mu.RLock()
	defer c.mu.RUnlock()

	return Status{
		Enabled:        c.config.Enabled,
		Provider:       c.config.Provider,
		Hostname:       c.config.Hostname,
		CurrentIP:      c.currentIP,
		LastUpdate:     c.lastUpdate,
		LastError:      c.lastError,
		UpdateCount:    c.updateCount,
		Running:        c.running,
		UpdateInterval: c.config.UpdateInterval,
	}
}

// GetConfig returns the current configuration.
func (c *Client) GetConfig() Config {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.config
}

// startLocked starts the update loop. Must be called with c.mu held.
func (c *Client) startLocked() {
	ctx, cancel := context.WithCancel(context.Background())
	c.cancel = cancel
	c.running = true

	interval := time.Duration(c.config.UpdateInterval) * time.Second
	cfg := c.config

	go func() {
		// Initial update immediately
		c.runUpdate(cfg)

		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				// Re-read config in case it changed
				c.mu.RLock()
				currentCfg := c.config
				c.mu.RUnlock()
				c.runUpdate(currentCfg)
			}
		}
	}()

	logger.Infof("DDNS update loop started (provider=%s, hostname=%s, interval=%ds)",
		cfg.Provider, cfg.Hostname, cfg.UpdateInterval)
}

// runUpdate performs a single update cycle.
func (c *Client) runUpdate(cfg Config) {
	ip, err := c.detectPublicIP()
	if err != nil {
		c.setError(fmt.Sprintf("IP detection failed: %v", err))
		logger.Warnf("DDNS IP detection failed: %v", err)
		return
	}

	// Skip if IP hasn't changed
	c.mu.RLock()
	previousIP := c.currentIP
	c.mu.RUnlock()

	if ip == previousIP && previousIP != "" {
		return
	}

	err = c.updateDNS(cfg, ip)
	if err != nil {
		c.setError(fmt.Sprintf("DNS update failed: %v", err))
		logger.Warnf("DDNS update failed for %s: %v", cfg.Hostname, err)
		return
	}

	c.mu.Lock()
	c.currentIP = ip
	c.lastUpdate = time.Now()
	c.lastError = ""
	c.updateCount++
	c.mu.Unlock()

	logger.Infof("DDNS updated: %s -> %s (was %s)", cfg.Hostname, ip, previousIP)
}

// setError stores a last-error string.
func (c *Client) setError(msg string) {
	c.mu.Lock()
	c.lastError = msg
	c.mu.Unlock()
}

// detectPublicIP tries multiple services to determine the public IP.
func (c *Client) detectPublicIP() (string, error) {
	for _, svc := range ipServices {
		ip, err := c.fetchIP(svc)
		if err == nil && ip != "" {
			return ip, nil
		}
	}
	return "", fmt.Errorf("all IP detection services failed")
}

// fetchIP queries a single IP-echo service.
func (c *Client) fetchIP(url string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "OpenFlix-DDNS/1.0")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("HTTP %d from %s", resp.StatusCode, url)
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, 64))
	if err != nil {
		return "", err
	}

	ip := strings.TrimSpace(string(body))
	if ip == "" {
		return "", fmt.Errorf("empty response from %s", url)
	}
	return ip, nil
}

// updateDNS dispatches the DNS update to the configured provider.
func (c *Client) updateDNS(cfg Config, ip string) error {
	switch cfg.Provider {
	case ProviderNoIP:
		return c.updateNoIP(cfg, ip)
	case ProviderDuckDNS:
		return c.updateDuckDNS(cfg, ip)
	case ProviderCloudflare:
		return c.updateCloudflare(cfg, ip)
	case ProviderCustom:
		return c.updateCustom(cfg, ip)
	default:
		return fmt.Errorf("unknown DDNS provider: %s", cfg.Provider)
	}
}

// updateNoIP updates DNS via the No-IP DUC protocol.
// https://www.noip.com/integrate/request
func (c *Client) updateNoIP(cfg Config, ip string) error {
	url := fmt.Sprintf("https://dynupdate.no-ip.com/nic/update?hostname=%s&myip=%s", cfg.Hostname, ip)

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return err
	}
	req.SetBasicAuth(cfg.Username, cfg.Password)
	req.Header.Set("User-Agent", "OpenFlix-DDNS/1.0 admin@openflix.stream")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("No-IP request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 256))
	result := strings.TrimSpace(string(body))

	// No-IP returns "good <ip>" or "nochg <ip>" on success
	if strings.HasPrefix(result, "good") || strings.HasPrefix(result, "nochg") {
		return nil
	}

	return fmt.Errorf("No-IP error: %s", result)
}

// updateDuckDNS updates DNS via the DuckDNS API.
// https://www.duckdns.org/spec.jsp
func (c *Client) updateDuckDNS(cfg Config, ip string) error {
	// DuckDNS hostname should be just the subdomain (without .duckdns.org)
	hostname := strings.TrimSuffix(cfg.Hostname, ".duckdns.org")

	url := fmt.Sprintf("https://www.duckdns.org/update?domains=%s&token=%s&ip=%s", hostname, cfg.Token, ip)

	resp, err := c.httpClient.Get(url)
	if err != nil {
		return fmt.Errorf("DuckDNS request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 64))
	result := strings.TrimSpace(string(body))

	if result == "OK" {
		return nil
	}

	return fmt.Errorf("DuckDNS error: %s", result)
}

// cloudflareRecord is used to parse Cloudflare DNS record responses.
type cloudflareRecord struct {
	ID      string `json:"id"`
	Name    string `json:"name"`
	Type    string `json:"type"`
	Content string `json:"content"`
}

// cloudflareListResponse represents the Cloudflare list DNS records response.
type cloudflareListResponse struct {
	Success bool               `json:"success"`
	Result  []cloudflareRecord `json:"result"`
	Errors  []struct {
		Message string `json:"message"`
	} `json:"errors"`
}

// cloudflareUpdateResponse represents the Cloudflare update DNS record response.
type cloudflareUpdateResponse struct {
	Success bool `json:"success"`
	Errors  []struct {
		Message string `json:"message"`
	} `json:"errors"`
}

// updateCloudflare updates DNS via the Cloudflare API.
// https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-update-dns-record
func (c *Client) updateCloudflare(cfg Config, ip string) error {
	if cfg.ZoneID == "" {
		return fmt.Errorf("Cloudflare zone_id is required")
	}

	recordID := cfg.RecordID

	// If no record ID provided, look it up by hostname
	if recordID == "" {
		var err error
		recordID, err = c.cloudflareResolveRecord(cfg)
		if err != nil {
			return fmt.Errorf("failed to resolve Cloudflare record: %w", err)
		}
	}

	url := fmt.Sprintf("https://api.cloudflare.com/client/v4/zones/%s/dns_records/%s", cfg.ZoneID, recordID)

	payload := fmt.Sprintf(`{"type":"A","name":"%s","content":"%s","ttl":1,"proxied":%t}`,
		cfg.Hostname, ip, cfg.Proxied)

	req, err := http.NewRequest(http.MethodPut, url, strings.NewReader(payload))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+cfg.Token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("Cloudflare request failed: %w", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))

	var cfResp cloudflareUpdateResponse
	if err := json.Unmarshal(body, &cfResp); err != nil {
		return fmt.Errorf("Cloudflare response parse error: %w", err)
	}

	if !cfResp.Success {
		errMsg := "unknown error"
		if len(cfResp.Errors) > 0 {
			errMsg = cfResp.Errors[0].Message
		}
		return fmt.Errorf("Cloudflare error: %s", errMsg)
	}

	return nil
}

// cloudflareResolveRecord looks up the DNS record ID for the given hostname.
func (c *Client) cloudflareResolveRecord(cfg Config) (string, error) {
	url := fmt.Sprintf("https://api.cloudflare.com/client/v4/zones/%s/dns_records?type=A&name=%s",
		cfg.ZoneID, cfg.Hostname)

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("Authorization", "Bearer "+cfg.Token)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(io.LimitReader(resp.Body, 8192))

	var cfResp cloudflareListResponse
	if err := json.Unmarshal(body, &cfResp); err != nil {
		return "", fmt.Errorf("parse error: %w", err)
	}

	if !cfResp.Success {
		errMsg := "unknown error"
		if len(cfResp.Errors) > 0 {
			errMsg = cfResp.Errors[0].Message
		}
		return "", fmt.Errorf("Cloudflare error: %s", errMsg)
	}

	if len(cfResp.Result) == 0 {
		return "", fmt.Errorf("no A record found for %s", cfg.Hostname)
	}

	return cfResp.Result[0].ID, nil
}

// updateCustom sends a GET request to a custom URL with {IP} replaced.
func (c *Client) updateCustom(cfg Config, ip string) error {
	if cfg.CustomURL == "" {
		return fmt.Errorf("custom_url is required for custom provider")
	}

	url := strings.ReplaceAll(cfg.CustomURL, "{IP}", ip)

	resp, err := c.httpClient.Get(url)
	if err != nil {
		return fmt.Errorf("custom DDNS request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 256))
		return fmt.Errorf("custom DDNS error: HTTP %d - %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}

	return nil
}

// ConfigToJSON serialises the config for storage.
func ConfigToJSON(cfg Config) (string, error) {
	b, err := json.Marshal(cfg)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

// ConfigFromJSON deserialises the config from storage.
func ConfigFromJSON(data string) (Config, error) {
	var cfg Config
	if data == "" {
		return cfg, nil
	}
	err := json.Unmarshal([]byte(data), &cfg)
	return cfg, err
}
