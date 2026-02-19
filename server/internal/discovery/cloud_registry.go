package discovery

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
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
	registryURL string
	serverInfo  ServerInfo
	claimToken  string
	client      *http.Client
	ctx         context.Context
	cancel      context.CancelFunc
}

// CloudRegistration is the payload sent to the cloud registry.
type CloudRegistration struct {
	MachineID      string   `json:"machineId"`
	Name           string   `json:"name"`
	Version        string   `json:"version"`
	Port           int      `json:"port"`
	LocalAddresses []string `json:"localAddresses"`
	ClaimToken     string   `json:"claimToken,omitempty"`
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
	c.claimToken = token
}

func (c *CloudRegistryClient) register() {
	payload := CloudRegistration{
		MachineID:      c.serverInfo.MachineID,
		Name:           c.serverInfo.Name,
		Version:        c.serverInfo.Version,
		Port:           c.serverInfo.Port,
		LocalAddresses: c.serverInfo.LocalAddresses,
		ClaimToken:     c.claimToken,
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
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		logger.Debugf("Cloud registry: heartbeat returned status %d", resp.StatusCode)
		return
	}

	var result CloudRegistrationResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		logger.Debugf("Cloud registry: failed to decode response: %v", err)
		return
	}

	logger.Debugf("Cloud registry: registered (publicIp=%s)", result.PublicIP)
}
