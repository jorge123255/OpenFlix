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
	lastPublicIP string
	lastSuccess  bool
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
	inviteTokens := make([]string, len(c.inviteTokens))
	copy(inviteTokens, c.inviteTokens)
	c.mu.Unlock()

	payload := CloudRegistration{
		MachineID:      c.serverInfo.MachineID,
		Name:           c.serverInfo.Name,
		Version:        c.serverInfo.Version,
		Port:           c.serverInfo.Port,
		LocalAddresses: c.serverInfo.LocalAddresses,
		ClaimToken:     claimToken,
		InviteTokens:   inviteTokens,
		LicenseKey:     licenseKey,
	}

	body, err := json.Marshal(payload)
	if err != nil {
		logger.Warnf("Cloud registry: failed to marshal payload: %v", err)
		return
	}

	req, err := http.NewRequestWithContext(c.ctx, http.MethodPost, c.registryURL+"/register", bytes.NewReader(body))
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
