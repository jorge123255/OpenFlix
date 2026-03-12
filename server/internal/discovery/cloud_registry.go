package discovery

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

const (
	cloudHeartbeatInterval = 60 * time.Second
	cloudRequestTimeout    = 10 * time.Second
)

// CloudRegistryClient periodically registers this server with a cloud discovery service,
// enabling remote clients to find the server by machineId or claim token.
type CloudRegistryClient struct {
	registryURL  string
	serverInfo   ServerInfo
	claimToken   string
	inviteTokens []string
	licenseKey   string
	externalURL  string
	lastPublicIP string
	lastSuccess  bool
	running      bool
	mu           sync.Mutex
	client       *http.Client
	ctx          context.Context
	cancel       context.CancelFunc
}

// CloudRegistration is the payload sent to the cloud registry.
type CloudRegistration struct {
	MachineID      string   `json:"machineId"`
	Name           string   `json:"name"`
	Version        string   `json:"version"`
	Port           int      `json:"port"`
	LocalAddresses []string `json:"localAddresses"`
	ClaimToken     string   `json:"claimToken,omitempty"`
	InviteTokens   []string `json:"inviteTokens,omitempty"`
	LicenseKey     string   `json:"licenseKey,omitempty"`
	ExternalURL    string   `json:"externalUrl,omitempty"`
}

// CloudRegistrationResponse is the response from the cloud registry.
type CloudRegistrationResponse struct {
	PublicIP   string `json:"publicIp"`
	Registered bool   `json:"registered"`
}

// NewCloudRegistryClient creates a new cloud registry client.
// Returns nil if registryURL is empty (cloud discovery disabled).
func NewCloudRegistryClient(registryURL string, serverInfo ServerInfo, claimToken string) *CloudRegistryClient {
	if registryURL == "" {
		return nil
	}

	return &CloudRegistryClient{
		registryURL: registryURL,
		serverInfo:  serverInfo,
		claimToken:  claimToken,
		client: &http.Client{
			Timeout: cloudRequestTimeout,
		},
	}
}

// Start begins the periodic heartbeat to the cloud registry.
func (c *CloudRegistryClient) Start() {
	c.mu.Lock()
	if c.running {
		c.mu.Unlock()
		return
	}
	c.running = true
	c.mu.Unlock()

	c.ctx, c.cancel = context.WithCancel(context.Background())

	// Register immediately on start
	go func() {
		c.register()

		ticker := time.NewTicker(cloudHeartbeatInterval)
		defer ticker.Stop()

		for {
			select {
			case <-c.ctx.Done():
				return
			case <-ticker.C:
				c.register()
			}
		}
	}()

	logger.Infof("Cloud registry client started (URL: %s)", c.registryURL)
}

// Stop stops the periodic heartbeat.
func (c *CloudRegistryClient) Stop() {
	c.mu.Lock()
	c.running = false
	c.mu.Unlock()
	if c.cancel != nil {
		c.cancel()
	}
	logger.Info("Cloud registry client stopped")
}

// SetClaimToken updates the claim token sent with heartbeats.
func (c *CloudRegistryClient) SetClaimToken(token string) {
	c.mu.Lock()
	c.claimToken = token
	c.mu.Unlock()
}

// SetInviteTokens updates the active invite tokens sent with heartbeats.
func (c *CloudRegistryClient) SetInviteTokens(tokens []string) {
	c.mu.Lock()
	c.inviteTokens = tokens
	c.mu.Unlock()
}

// SetLicenseKey updates the license key sent with heartbeats.
func (c *CloudRegistryClient) SetLicenseKey(key string) {
	c.mu.Lock()
	c.licenseKey = key
	c.mu.Unlock()
}

// UpdateMachineID updates the machine ID used in heartbeats.
// Call this after deriving a stable ID from the license key.
func (c *CloudRegistryClient) UpdateMachineID(id string) {
	c.mu.Lock()
	c.serverInfo.MachineID = id
	c.mu.Unlock()
}

// SetExternalURL updates the external URL sent with heartbeats.
// iOS clients will prefer this URL over publicIp:port when connecting remotely.
// Set to a cloudflared tunnel URL or custom domain for stable remote access.
func (c *CloudRegistryClient) SetExternalURL(url string) {
	c.mu.Lock()
	c.externalURL = url
	c.mu.Unlock()
}

// RegisterNow triggers an immediate heartbeat instead of waiting for the next tick.
func (c *CloudRegistryClient) RegisterNow() {
	c.register()
}

// CloudRegistryStatus holds the current cloud connection status.
type CloudRegistryStatus struct {
	Connected bool   `json:"connected"`
	PublicIP  string `json:"publicIp"`
}

// GetStatus returns the current connection status.
func (c *CloudRegistryClient) GetStatus() CloudRegistryStatus {
	c.mu.Lock()
	defer c.mu.Unlock()
	return CloudRegistryStatus{
		Connected: c.lastSuccess,
		PublicIP:  c.lastPublicIP,
	}
}

func (c *CloudRegistryClient) register() {
	c.mu.Lock()
	claimToken := c.claimToken
	licenseKey := c.licenseKey
	externalURL := c.externalURL
	inviteTokens := make([]string, len(c.inviteTokens))
	copy(inviteTokens, c.inviteTokens)
	ctx := c.ctx
	c.mu.Unlock()

	if ctx == nil {
		ctx = context.Background()
	}

	payload := CloudRegistration{
		MachineID:      c.serverInfo.MachineID,
		Name:           c.serverInfo.Name,
		Version:        c.serverInfo.Version,
		Port:           c.serverInfo.Port,
		LocalAddresses: c.serverInfo.LocalAddresses,
		ClaimToken:     claimToken,
		InviteTokens:   inviteTokens,
		LicenseKey:     licenseKey,
		ExternalURL:    externalURL,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		logger.Warnf("Cloud registry: failed to marshal payload: %v", err)
		return
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.registryURL+"/register", bytes.NewReader(body))
	if err != nil {
		logger.Warnf("Cloud registry: failed to create request: %v", err)
		return
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.client.Do(req)
	if err != nil {
		logger.Debugf("Cloud registry: heartbeat failed (cloud may be unavailable): %v", err)
		c.mu.Lock()
		c.lastSuccess = false
		c.mu.Unlock()
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		logger.Debugf("Cloud registry: heartbeat returned status %d", resp.StatusCode)
		c.mu.Lock()
		c.lastSuccess = false
		c.mu.Unlock()
		return
	}

	var result CloudRegistrationResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		logger.Debugf("Cloud registry: failed to decode response: %v", err)
		c.mu.Lock()
		c.lastSuccess = false
		c.mu.Unlock()
		return
	}

	c.mu.Lock()
	c.lastSuccess = result.Registered
	c.lastPublicIP = result.PublicIP
	c.mu.Unlock()

	logger.Debugf("Cloud registry: registered (publicIp=%s)", result.PublicIP)
}
