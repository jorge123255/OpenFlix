package livetv

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"os/exec"
	"runtime"
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// RemoteAccessStatus represents the current remote access status
type RemoteAccessStatus struct {
	Enabled       bool     `json:"enabled"`
	Status        string   `json:"status"` // connected, disconnected, connecting, error
	TailscaleIP   string   `json:"tailscaleIp,omitempty"`
	TailscaleURL  string   `json:"tailscaleUrl,omitempty"`
	Hostname      string   `json:"hostname,omitempty"`
	LocalIP       string   `json:"localIp,omitempty"`
	ExternalURL   string   `json:"externalUrl,omitempty"`
	Error         string   `json:"error,omitempty"`
	LastChecked   time.Time `json:"lastChecked"`
}

// TailscaleConfig holds Tailscale configuration
type TailscaleConfig struct {
	Enabled   bool   `json:"enabled"`
	AuthKey   string `json:"authKey,omitempty"` // For automated auth
	Hostname  string `json:"hostname,omitempty"`
	Port      int    `json:"port"`
}

// RemoteAccessManager manages remote access through Tailscale
type RemoteAccessManager struct {
	config TailscaleConfig
	status RemoteAccessStatus
}

// NewRemoteAccessManager creates a new remote access manager
func NewRemoteAccessManager(config TailscaleConfig) *RemoteAccessManager {
	ram := &RemoteAccessManager{
		config: config,
		status: RemoteAccessStatus{
			Enabled: config.Enabled,
			Status:  "unknown",
		},
	}

	// Check initial status
	ram.RefreshStatus()

	return ram
}

// RefreshStatus updates the remote access status
func (ram *RemoteAccessManager) RefreshStatus() *RemoteAccessStatus {
	ram.status.LastChecked = time.Now()
	ram.status.LocalIP = getLocalIP()

	// Check if Tailscale is installed
	tailscalePath, err := exec.LookPath("tailscale")
	if err != nil {
		ram.status.Enabled = false
		ram.status.Status = "not_installed"
		ram.status.Error = "Tailscale is not installed"
		return &ram.status
	}

	// Check Tailscale status
	cmd := exec.Command(tailscalePath, "status", "--json")
	output, err := cmd.Output()
	if err != nil {
		ram.status.Status = "disconnected"
		ram.status.Error = "Tailscale not connected"
		return &ram.status
	}

	// Parse JSON status
	var tailscaleStatus struct {
		BackendState string `json:"BackendState"`
		Self         struct {
			DNSName    string   `json:"DNSName"`
			TailscaleIPs []string `json:"TailscaleIPs"`
			HostName   string   `json:"HostName"`
			Online     bool     `json:"Online"`
		} `json:"Self"`
		TailnetName string `json:"CurrentTailnet,omitempty"`
	}

	if err := json.Unmarshal(output, &tailscaleStatus); err != nil {
		ram.status.Status = "error"
		ram.status.Error = "Failed to parse Tailscale status"
		return &ram.status
	}

	// Check connection state
	switch tailscaleStatus.BackendState {
	case "Running":
		ram.status.Status = "connected"
		ram.status.Error = ""
	case "Starting":
		ram.status.Status = "connecting"
	case "Stopped":
		ram.status.Status = "disconnected"
	case "NeedsLogin":
		ram.status.Status = "needs_login"
		ram.status.Error = "Tailscale requires authentication"
	default:
		ram.status.Status = tailscaleStatus.BackendState
	}

	// Get Tailscale IP
	if len(tailscaleStatus.Self.TailscaleIPs) > 0 {
		ram.status.TailscaleIP = tailscaleStatus.Self.TailscaleIPs[0]
	}

	// Get hostname
	ram.status.Hostname = tailscaleStatus.Self.HostName
	if tailscaleStatus.Self.DNSName != "" {
		// Remove trailing dot
		dnsName := strings.TrimSuffix(tailscaleStatus.Self.DNSName, ".")
		ram.status.TailscaleURL = fmt.Sprintf("http://%s:%d", dnsName, ram.config.Port)
	}

	// Build external URL
	if ram.status.TailscaleIP != "" {
		ram.status.ExternalURL = fmt.Sprintf("http://%s:%d", ram.status.TailscaleIP, ram.config.Port)
	}

	ram.status.Enabled = ram.status.Status == "connected"

	logger.Log.WithFields(map[string]interface{}{
		"status":       ram.status.Status,
		"tailscale_ip": ram.status.TailscaleIP,
		"hostname":     ram.status.Hostname,
	}).Debug("Remote access status refreshed")

	return &ram.status
}

// GetStatus returns the current remote access status
func (ram *RemoteAccessManager) GetStatus() *RemoteAccessStatus {
	return &ram.status
}

// Enable enables Tailscale with optional auth key
func (ram *RemoteAccessManager) Enable(authKey string) error {
	tailscalePath, err := exec.LookPath("tailscale")
	if err != nil {
		return fmt.Errorf("tailscale is not installed")
	}

	args := []string{"up", "--accept-routes"}

	if authKey != "" {
		args = append(args, "--authkey="+authKey)
	}

	if ram.config.Hostname != "" {
		args = append(args, "--hostname="+ram.config.Hostname)
	}

	cmd := exec.Command(tailscalePath, args...)
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to enable Tailscale: %s - %s", err.Error(), string(output))
	}

	ram.RefreshStatus()
	return nil
}

// Disable disables Tailscale
func (ram *RemoteAccessManager) Disable() error {
	tailscalePath, err := exec.LookPath("tailscale")
	if err != nil {
		return fmt.Errorf("tailscale is not installed")
	}

	cmd := exec.Command(tailscalePath, "down")
	if output, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("failed to disable Tailscale: %s - %s", err.Error(), string(output))
	}

	ram.RefreshStatus()
	return nil
}

// GetLoginURL returns a login URL for interactive authentication
func (ram *RemoteAccessManager) GetLoginURL() (string, error) {
	tailscalePath, err := exec.LookPath("tailscale")
	if err != nil {
		return "", fmt.Errorf("tailscale is not installed")
	}

	cmd := exec.Command(tailscalePath, "up", "--qr")
	output, _ := cmd.CombinedOutput()

	// Parse output for login URL
	outputStr := string(output)
	for _, line := range strings.Split(outputStr, "\n") {
		if strings.Contains(line, "https://") {
			return strings.TrimSpace(line), nil
		}
	}

	return "", fmt.Errorf("could not get login URL")
}

// GetConnectionInfo returns connection information for the client
type ConnectionInfo struct {
	LocalURLs     []string `json:"localUrls"`
	TailscaleURL  string   `json:"tailscaleUrl,omitempty"`
	RecommendedURL string  `json:"recommendedUrl"`
	IsRemote      bool     `json:"isRemote"`
}

// GetConnectionInfo returns the best URL for a client to connect
func (ram *RemoteAccessManager) GetConnectionInfo(clientIP string) *ConnectionInfo {
	info := &ConnectionInfo{
		LocalURLs: []string{},
	}

	// Get local IPs
	addrs, err := net.InterfaceAddrs()
	if err == nil {
		for _, addr := range addrs {
			if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
				if ipnet.IP.To4() != nil {
					info.LocalURLs = append(info.LocalURLs,
						fmt.Sprintf("http://%s:%d", ipnet.IP.String(), ram.config.Port))
				}
			}
		}
	}

	// Add Tailscale URL
	if ram.status.TailscaleURL != "" {
		info.TailscaleURL = ram.status.TailscaleURL
	}

	// Determine if client is remote
	clientIsLocal := isPrivateIP(clientIP)
	info.IsRemote = !clientIsLocal

	// Recommend best URL
	if clientIsLocal && len(info.LocalURLs) > 0 {
		info.RecommendedURL = info.LocalURLs[0]
	} else if info.TailscaleURL != "" {
		info.RecommendedURL = info.TailscaleURL
	} else if len(info.LocalURLs) > 0 {
		info.RecommendedURL = info.LocalURLs[0]
	}

	return info
}

// getLocalIP returns the preferred local IP address
func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return ""
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return ""
}

// isPrivateIP checks if an IP address is private
func isPrivateIP(ip string) bool {
	parsedIP := net.ParseIP(ip)
	if parsedIP == nil {
		return false
	}

	// Check private ranges
	privateRanges := []string{
		"10.0.0.0/8",
		"172.16.0.0/12",
		"192.168.0.0/16",
		"127.0.0.0/8",
		"100.64.0.0/10", // Tailscale CGNAT range
	}

	for _, cidr := range privateRanges {
		_, network, err := net.ParseCIDR(cidr)
		if err == nil && network.Contains(parsedIP) {
			return true
		}
	}

	return false
}

// GetInstallInstructions returns OS-specific Tailscale installation instructions
func GetInstallInstructions() map[string]string {
	instructions := map[string]string{
		"download_url": "https://tailscale.com/download",
	}

	switch runtime.GOOS {
	case "darwin":
		instructions["platform"] = "macOS"
		instructions["command"] = "brew install tailscale"
		instructions["app_store"] = "https://apps.apple.com/us/app/tailscale/id1475387142"
	case "linux":
		instructions["platform"] = "Linux"
		instructions["command"] = "curl -fsSL https://tailscale.com/install.sh | sh"
	case "windows":
		instructions["platform"] = "Windows"
		instructions["command"] = "Download from https://tailscale.com/download/windows"
	}

	return instructions
}

// HealthCheck performs a health check for remote access
func (ram *RemoteAccessManager) HealthCheck() map[string]interface{} {
	result := map[string]interface{}{
		"tailscale_installed": false,
		"tailscale_connected": false,
		"tailscale_ip":        "",
		"local_ip":            getLocalIP(),
		"port":                ram.config.Port,
	}

	// Check if Tailscale is installed
	tailscalePath, err := exec.LookPath("tailscale")
	if err == nil {
		result["tailscale_installed"] = true
		result["tailscale_path"] = tailscalePath

		// Check if connected
		ram.RefreshStatus()
		if ram.status.Status == "connected" {
			result["tailscale_connected"] = true
			result["tailscale_ip"] = ram.status.TailscaleIP
			result["tailscale_url"] = ram.status.TailscaleURL
		}
	}

	// Test local connectivity
	localAddr := fmt.Sprintf("127.0.0.1:%d", ram.config.Port)
	conn, err := net.DialTimeout("tcp", localAddr, 2*time.Second)
	if err == nil {
		conn.Close()
		result["local_reachable"] = true
	} else {
		result["local_reachable"] = false
	}

	// Test Tailscale connectivity if available
	if ram.status.TailscaleIP != "" {
		tailscaleAddr := fmt.Sprintf("%s:%d", ram.status.TailscaleIP, ram.config.Port)
		conn, err := net.DialTimeout("tcp", tailscaleAddr, 5*time.Second)
		if err == nil {
			conn.Close()
			result["tailscale_reachable"] = true
		} else {
			result["tailscale_reachable"] = false
		}
	}

	return result
}

// API helpers for remote access endpoints
type RemoteAccessAPI struct {
	Manager *RemoteAccessManager
}

// HandleStatus returns the remote access status as JSON
func (api *RemoteAccessAPI) HandleStatus(w http.ResponseWriter, r *http.Request) {
	status := api.Manager.RefreshStatus()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

// HandleEnable enables Tailscale
func (api *RemoteAccessAPI) HandleEnable(w http.ResponseWriter, r *http.Request) {
	var req struct {
		AuthKey string `json:"authKey"`
	}
	json.NewDecoder(r.Body).Decode(&req)

	if err := api.Manager.Enable(req.AuthKey); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(api.Manager.GetStatus())
}

// HandleDisable disables Tailscale
func (api *RemoteAccessAPI) HandleDisable(w http.ResponseWriter, r *http.Request) {
	if err := api.Manager.Disable(); err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(api.Manager.GetStatus())
}

// HandleHealth returns health check information
func (api *RemoteAccessAPI) HandleHealth(w http.ResponseWriter, r *http.Request) {
	health := api.Manager.HealthCheck()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(health)
}

// HandleInstallInfo returns installation instructions
func (api *RemoteAccessAPI) HandleInstallInfo(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(GetInstallInstructions())
}

// HandleConnectionInfo returns the best connection URL for the client
func (api *RemoteAccessAPI) HandleConnectionInfo(w http.ResponseWriter, r *http.Request) {
	clientIP := r.RemoteAddr
	if colonIndex := strings.LastIndex(clientIP, ":"); colonIndex != -1 {
		clientIP = clientIP[:colonIndex]
	}
	// Remove brackets for IPv6
	clientIP = strings.Trim(clientIP, "[]")

	info := api.Manager.GetConnectionInfo(clientIP)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(info)
}
