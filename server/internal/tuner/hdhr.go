package tuner

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// HDHomeRunDevice represents a discovered HDHomeRun tuner device.
type HDHomeRunDevice struct {
	DeviceID        string `json:"deviceId"`
	LocalIP         string `json:"localIp"`
	BaseURL         string `json:"baseUrl"`
	ModelNumber     string `json:"modelNumber"`
	FirmwareName    string `json:"firmwareName"`
	FirmwareVersion string `json:"firmwareVersion"`
	TunerCount      int    `json:"tunerCount"`
	DeviceAuth      string `json:"deviceAuth,omitempty"`
	LineupURL       string `json:"lineupUrl"`
	Priority        int    `json:"priority"`
}

// HDHomeRunChannel represents a single channel in the tuner lineup.
type HDHomeRunChannel struct {
	GuideNumber string `json:"GuideNumber"`
	GuideName   string `json:"GuideName"`
	VideoCodec  string `json:"VideoCodec,omitempty"`
	AudioCodec  string `json:"AudioCodec,omitempty"`
	HD          int    `json:"HD,omitempty"`
	URL         string `json:"URL"`
	Favorite    int    `json:"Favorite,omitempty"`
	DRM         int    `json:"DRM,omitempty"`
}

// HDHomeRunStatus represents the status of a single tuner on the device.
type HDHomeRunStatus struct {
	Resource              string  `json:"Resource"`
	VctNumber             string  `json:"VctNumber"`
	VctName               string  `json:"VctName"`
	Frequency             int     `json:"Frequency"`
	SignalStrengthPercent int     `json:"SignalStrengthPercent"`
	SymbolQualityPercent  int     `json:"SymbolQualityPercent"`
	StreamingRate         float64 `json:"StreamingRate"`
	TargetIP              string  `json:"TargetIP,omitempty"`
}

// TunerManager manages the lifecycle of HDHomeRun tuner devices.
type TunerManager struct {
	devices map[string]*HDHomeRunDevice
	mu      sync.RWMutex
	client  *http.Client
	db      *gorm.DB

	// Scheduled refresh
	stopCh   chan struct{}
	stopOnce sync.Once
}

// discoverJSON is the JSON structure returned by /discover.json on the device.
type discoverJSON struct {
	FriendlyName    string `json:"FriendlyName"`
	ModelNumber     string `json:"ModelNumber"`
	FirmwareName    string `json:"FirmwareName"`
	FirmwareVersion string `json:"FirmwareVersion"`
	DeviceID        string `json:"DeviceID"`
	DeviceAuth      string `json:"DeviceAuth"`
	BaseURL         string `json:"BaseURL"`
	LineupURL       string `json:"LineupURL"`
	TunerCount      int    `json:"TunerCount"`
}

// NewTunerManager creates a new TunerManager with sensible HTTP client defaults.
// Pass a non-nil db to enable persistence across restarts.
func NewTunerManager(db *gorm.DB) *TunerManager {
	tm := &TunerManager{
		devices: make(map[string]*HDHomeRunDevice),
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
		db: db,
	}
	if db != nil {
		tm.loadFromDB()
	}
	return tm
}

// loadFromDB restores previously saved tuner devices from the database.
func (tm *TunerManager) loadFromDB() {
	var rows []models.TunerDevice
	if err := tm.db.Find(&rows).Error; err != nil {
		logger.Warnf("TunerManager: failed to load saved devices: %v", err)
		return
	}
	for _, row := range rows {
		dev := &HDHomeRunDevice{
			DeviceID:        row.DeviceID,
			BaseURL:         row.BaseURL,
			LocalIP:         row.LocalIP,
			ModelNumber:     row.ModelNumber,
			FirmwareName:    row.FirmwareName,
			FirmwareVersion: row.FirmwareVersion,
			TunerCount:      row.TunerCount,
			DeviceAuth:      row.DeviceAuth,
			LineupURL:       row.LineupURL,
			Priority:        row.Priority,
		}
		tm.devices[dev.DeviceID] = dev
	}
	if len(rows) > 0 {
		logger.Infof("TunerManager: restored %d device(s) from database", len(rows))
	}
}

// saveToDB upserts a device record (called with tm.mu held or after storing in map).
func (tm *TunerManager) saveToDB(dev *HDHomeRunDevice) {
	if tm.db == nil {
		return
	}
	row := models.TunerDevice{
		DeviceID:        dev.DeviceID,
		BaseURL:         dev.BaseURL,
		LocalIP:         dev.LocalIP,
		ModelNumber:     dev.ModelNumber,
		FirmwareName:    dev.FirmwareName,
		FirmwareVersion: dev.FirmwareVersion,
		TunerCount:      dev.TunerCount,
		DeviceAuth:      dev.DeviceAuth,
		LineupURL:       dev.LineupURL,
		Priority:        dev.Priority,
	}
	if err := tm.db.Where(models.TunerDevice{DeviceID: dev.DeviceID}).Assign(row).FirstOrCreate(&row).Error; err != nil {
		logger.Warnf("TunerManager: failed to persist device %s: %v", dev.DeviceID, err)
	}
}

// deleteFromDB removes a device record from the database.
func (tm *TunerManager) deleteFromDB(deviceID string) {
	if tm.db == nil {
		return
	}
	if err := tm.db.Where("device_id = ?", deviceID).Delete(&models.TunerDevice{}).Error; err != nil {
		logger.Warnf("TunerManager: failed to delete device %s: %v", deviceID, err)
	}
}

// Discover scans the local network for HDHomeRun devices using UDP broadcast,
// SSDP, the SiliconDust cloud API, and HTTP probing on local subnets.
func (tm *TunerManager) Discover(ctx context.Context) ([]*HDHomeRunDevice, error) {
	logger.Info("Starting HDHomeRun device discovery")

	var (
		wg         sync.WaitGroup
		mu         sync.Mutex
		discovered []*HDHomeRunDevice
	)

	// Channel to collect discovered devices from all methods
	devCh := make(chan *HDHomeRunDevice, 64)

	// Collect results
	done := make(chan struct{})
	go func() {
		for dev := range devCh {
			mu.Lock()
			discovered = append(discovered, dev)
			mu.Unlock()
		}
		close(done)
	}()

	// UDP broadcast discovery
	wg.Add(1)
	go func() {
		defer wg.Done()
		devices, err := tm.discoverUDP(ctx)
		if err != nil {
			logger.Warnf("UDP discovery error: %v", err)
			return
		}
		for _, d := range devices {
			devCh <- d
		}
	}()

	// SSDP (UPnP M-SEARCH) discovery
	wg.Add(1)
	go func() {
		defer wg.Done()
		devices, err := tm.discoverSSDP(ctx)
		if err != nil {
			logger.Warnf("SSDP discovery error: %v", err)
			return
		}
		for _, d := range devices {
			devCh <- d
		}
	}()

	// SiliconDust cloud API — finds devices regardless of subnet.
	// HDHomeRun devices phone home to api.hdhomerun.com which knows their
	// IP address. This is the most reliable method for non-local networks.
	wg.Add(1)
	go func() {
		defer wg.Done()
		devices, err := tm.discoverCloud(ctx)
		if err != nil {
			logger.Debugf("Cloud discovery unavailable: %v", err)
			return
		}
		for _, d := range devices {
			devCh <- d
		}
	}()

	// HTTP discovery on local subnet (parallelized with semaphore)
	wg.Add(1)
	go func() {
		defer wg.Done()
		ips := localSubnetIPs()

		sem := make(chan struct{}, 50) // max 50 concurrent probes
		var probeWg sync.WaitGroup

		for _, ip := range ips {
			select {
			case <-ctx.Done():
				probeWg.Wait()
				return
			default:
			}

			probeWg.Add(1)
			sem <- struct{}{}
			go func(ip string) {
				defer probeWg.Done()
				defer func() { <-sem }()

				dev, err := tm.probeIP(ctx, ip)
				if err == nil && dev != nil {
					devCh <- dev
				}
			}(ip)
		}
		probeWg.Wait()
	}()

	wg.Wait()
	close(devCh)
	<-done

	// Deduplicate by DeviceID
	seen := make(map[string]bool)
	var unique []*HDHomeRunDevice
	for _, d := range discovered {
		if d.DeviceID != "" && !seen[d.DeviceID] {
			seen[d.DeviceID] = true
			unique = append(unique, d)
		}
	}

	// Store discovered devices and persist to database
	tm.mu.Lock()
	for _, d := range unique {
		if existing, ok := tm.devices[d.DeviceID]; ok && existing != nil {
			d.Priority = existing.Priority
		}
		tm.devices[d.DeviceID] = d
		tm.saveToDB(d) // Persist so tuners survive restarts
	}
	tm.mu.Unlock()

	sort.Slice(unique, func(i, j int) bool {
		return unique[i].DeviceID < unique[j].DeviceID
	})

	logger.Infof("HDHomeRun discovery complete: found %d device(s)", len(unique))
	return unique, nil
}

// AddDevice manually registers a device by its base URL or IP address.
// Accepts bare IPs (192.168.1.100), http:// URLs, and URLs with any port.
// If the initial URL fails, common HDHomeRun API ports (80, 5004, 7070, 8080)
// are tried on the same host automatically.
func (tm *TunerManager) AddDevice(input string) (*HDHomeRunDevice, error) {
	input = strings.TrimRight(strings.TrimSpace(input), "/")

	// Add scheme if missing so URL parsing works correctly.
	if !strings.HasPrefix(input, "http://") && !strings.HasPrefix(input, "https://") {
		input = "http://" + input
	}

	// Build a prioritized list of base URLs to try.
	// Always include the original URL first so explicit ports are honoured.
	candidates := []string{input}

	// Extract the bare IP and add all standard API ports as fallbacks.
	// This handles the common mistake of entering the streaming port (5004)
	// instead of the web API port (80).
	ip := extractHost(input)
	if ip != "" {
		for _, port := range []int{80, 5004, 7070, 8080} {
			candidate := fmt.Sprintf("http://%s:%d", ip, port)
			if candidate != input {
				candidates = append(candidates, candidate)
			}
		}
	}

	var lastErr error
	for _, baseURL := range candidates {
		dev, err := tm.tryFetchDevice(baseURL)
		if err == nil {
			tm.mu.Lock()
			tm.devices[dev.DeviceID] = dev
			tm.mu.Unlock()
			tm.saveToDB(dev)
			logger.Infof("Added HDHomeRun device %s (%s) at %s", dev.DeviceID, dev.ModelNumber, dev.BaseURL)
			return dev, nil
		}
		lastErr = err
		logger.Debugf("AddDevice: %s failed: %v", baseURL, err)
	}

	return nil, fmt.Errorf("no HDHomeRun device found at %s (tried ports 80/5004/7070/8080): %w", input, lastErr)
}

// tryFetchDevice attempts to fetch /discover.json from baseURL and return a device.
func (tm *TunerManager) tryFetchDevice(baseURL string) (*HDHomeRunDevice, error) {
	discoverURL := baseURL + "/discover.json"

	resp, err := tm.client.Get(discoverURL)
	if err != nil {
		return nil, fmt.Errorf("failed to reach %s: %w", discoverURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d from %s", resp.StatusCode, discoverURL)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response from %s: %w", discoverURL, err)
	}

	var info discoverJSON
	if err := json.Unmarshal(body, &info); err != nil {
		return nil, fmt.Errorf("invalid JSON from %s: %w", discoverURL, err)
	}

	if info.DeviceID == "" {
		return nil, fmt.Errorf("no DeviceID in response from %s", discoverURL)
	}

	return deviceFromDiscover(&info, baseURL), nil
}

// GetDevices returns all known devices sorted by Priority then DeviceID.
func (tm *TunerManager) GetDevices() []*HDHomeRunDevice {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	devices := make([]*HDHomeRunDevice, 0, len(tm.devices))
	for _, d := range tm.devices {
		devices = append(devices, d)
	}
	sort.Slice(devices, func(i, j int) bool {
		if devices[i].Priority != devices[j].Priority {
			return devices[i].Priority < devices[j].Priority
		}
		return devices[i].DeviceID < devices[j].DeviceID
	})
	return devices
}

// SetPriority updates the priority for a device by its DeviceID.
func (tm *TunerManager) SetPriority(deviceID string, priority int) error {
	tm.mu.Lock()
	defer tm.mu.Unlock()

	dev, ok := tm.devices[deviceID]
	if !ok || dev == nil {
		return fmt.Errorf("device %s not found", deviceID)
	}

	dev.Priority = priority
	tm.saveToDB(dev)
	return nil
}

// RemoveDevice removes a device by its DeviceID.
func (tm *TunerManager) RemoveDevice(deviceID string) {
	tm.mu.Lock()
	delete(tm.devices, deviceID)
	tm.mu.Unlock()
	tm.deleteFromDB(deviceID)
	logger.Infof("Removed HDHomeRun device %s", deviceID)
}

// GetLineup fetches the channel lineup from a device by its DeviceID.
func (tm *TunerManager) GetLineup(deviceID string) ([]HDHomeRunChannel, error) {
	dev, err := tm.getDevice(deviceID)
	if err != nil {
		return nil, err
	}

	lineupURL := dev.BaseURL + "/lineup.json"
	if dev.LineupURL != "" {
		lineupURL = dev.LineupURL
	}

	resp, err := tm.client.Get(lineupURL)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch lineup from %s: %w", lineupURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("lineup request returned HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read lineup response: %w", err)
	}

	var channels []HDHomeRunChannel
	if err := json.Unmarshal(body, &channels); err != nil {
		return nil, fmt.Errorf("failed to parse lineup JSON: %w", err)
	}

	return channels, nil
}

// GetTunerStatus fetches the tuner status from a device by its DeviceID.
// Tries /status.json first (classic HDHomeRun), then falls back to /tuners
// (used by some software tuner devices like certain HDTC models).
func (tm *TunerManager) GetTunerStatus(deviceID string) ([]HDHomeRunStatus, error) {
	dev, err := tm.getDevice(deviceID)
	if err != nil {
		return nil, err
	}

	// --- Attempt 1: classic /status.json (array response) ---
	if statuses, err := tm.fetchStatusJSON(dev.BaseURL + "/status.json"); err == nil {
		return statuses, nil
	}

	// --- Attempt 2: /tuners endpoint used by software tuners ---
	// Response shape: {"numTuners": N, "tuners": [...HDHomeRunStatus...]}
	resp, err := tm.client.Get(dev.BaseURL + "/tuners")
	if err != nil {
		return nil, fmt.Errorf("tuner status unavailable: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("tuner status unavailable (HTTP %d)", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var wrapped struct {
		NumTuners int               `json:"numTuners"`
		Tuners    []HDHomeRunStatus `json:"tuners"`
	}
	if err := json.Unmarshal(body, &wrapped); err != nil {
		return nil, fmt.Errorf("failed to parse /tuners response: %w", err)
	}

	// If the device reported its tuner count but none are listed, build idle placeholders
	// so the UI can show the correct number of tuner slots.
	if len(wrapped.Tuners) == 0 && wrapped.NumTuners > 0 {
		tuners := make([]HDHomeRunStatus, wrapped.NumTuners)
		for i := range tuners {
			tuners[i] = HDHomeRunStatus{Resource: fmt.Sprintf("tuner%d", i)}
		}
		return tuners, nil
	}

	return wrapped.Tuners, nil
}

// fetchStatusJSON tries the classic /status.json endpoint (returns a JSON array).
func (tm *TunerManager) fetchStatusJSON(url string) ([]HDHomeRunStatus, error) {
	resp, err := tm.client.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var statuses []HDHomeRunStatus
	if err := json.Unmarshal(body, &statuses); err != nil {
		return nil, err
	}
	return statuses, nil
}

// GetStreamURL builds the direct HTTP streaming URL for a channel on the given device.
// HDHomeRun devices expose streams at http://<ip>:5004/auto/v<channel>.
func (tm *TunerManager) GetStreamURL(deviceID string, channelNumber string) string {
	tm.mu.RLock()
	dev, ok := tm.devices[deviceID]
	tm.mu.RUnlock()

	if !ok || dev == nil {
		return ""
	}

	// Extract the host (IP:port or just IP) from the BaseURL to build the stream URL.
	// BaseURL is typically http://192.168.1.100:80 or http://192.168.1.100
	ip := dev.LocalIP
	if ip == "" {
		// Try to extract from BaseURL
		ip = extractHost(dev.BaseURL)
	}

	return fmt.Sprintf("http://%s:5004/auto/v%s", ip, channelNumber)
}

// ScanChannels initiates a channel scan on the device.
func (tm *TunerManager) ScanChannels(deviceID string) error {
	dev, err := tm.getDevice(deviceID)
	if err != nil {
		return err
	}

	scanURL := dev.BaseURL + "/lineup.post?scan=start"

	resp, err := tm.client.Post(scanURL, "application/x-www-form-urlencoded", nil)
	if err != nil {
		return fmt.Errorf("failed to start channel scan on %s: %w", dev.DeviceID, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("channel scan request returned HTTP %d: %s", resp.StatusCode, string(body))
	}

	logger.Infof("Channel scan started on device %s", deviceID)
	return nil
}

// GetScanStatus returns the current channel scan status from the device.
func (tm *TunerManager) GetScanStatus(deviceID string) (map[string]interface{}, error) {
	dev, err := tm.getDevice(deviceID)
	if err != nil {
		return nil, err
	}

	statusURL := dev.BaseURL + "/lineup_status.json"

	resp, err := tm.client.Get(statusURL)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch scan status from %s: %w", statusURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("scan status request returned HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read scan status response: %w", err)
	}

	var result map[string]interface{}
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse scan status JSON: %w", err)
	}

	return result, nil
}

// ============ UDP Discovery ============

// discoverCloud queries the SiliconDust cloud API for registered HDHomeRun
// devices. This works even when the server is on a different subnet because
// HDHomeRun devices phone home to api.hdhomerun.com with their WAN IP.
// The API returns all devices last seen from the same public IP as the caller.
func (tm *TunerManager) discoverCloud(ctx context.Context) ([]*HDHomeRunDevice, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://api.hdhomerun.com/discover", nil)
	if err != nil {
		return nil, err
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("cloud API unreachable: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("cloud API returned HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	// The cloud API returns an array of device descriptors.
	var cloudDevices []struct {
		DeviceID    string `json:"DeviceID"`
		LocalIP     string `json:"LocalIP"`
		BaseURL     string `json:"BaseURL"`
		LineupURL   string `json:"LineupURL"`
		ModelNumber string `json:"ModelNumber"`
		FirmwareName    string `json:"FirmwareName"`
		FirmwareVersion string `json:"FirmwareVersion"`
		TunerCount  int    `json:"TunerCount"`
		DeviceAuth  string `json:"DeviceAuth"`
	}
	if err := json.Unmarshal(body, &cloudDevices); err != nil {
		return nil, fmt.Errorf("cloud API response parse error: %w", err)
	}

	var devices []*HDHomeRunDevice
	for _, cd := range cloudDevices {
		if cd.DeviceID == "" {
			continue
		}
		baseURL := cd.BaseURL
		if baseURL == "" && cd.LocalIP != "" {
			baseURL = "http://" + cd.LocalIP
		}
		lineupURL := cd.LineupURL
		if lineupURL == "" && baseURL != "" {
			lineupURL = baseURL + "/lineup.json"
		}
		dev := &HDHomeRunDevice{
			DeviceID:        cd.DeviceID,
			LocalIP:         extractHost(baseURL),
			BaseURL:         baseURL,
			ModelNumber:     cd.ModelNumber,
			FirmwareName:    cd.FirmwareName,
			FirmwareVersion: cd.FirmwareVersion,
			TunerCount:      cd.TunerCount,
			DeviceAuth:      cd.DeviceAuth,
			LineupURL:       lineupURL,
		}
		devices = append(devices, dev)
		logger.Infof("Cloud discovery found HDHomeRun device %s (%s) at %s", dev.DeviceID, dev.ModelNumber, dev.BaseURL)
	}
	return devices, nil
}

// discoverUDP sends a UDP broadcast discovery packet to find HDHomeRun devices
// on the local network. The HDHomeRun discovery protocol uses port 65001.
func (tm *TunerManager) discoverUDP(ctx context.Context) ([]*HDHomeRunDevice, error) {
	// Build the discovery request packet.
	// Format: 2-byte type (0x0002 = discover request), 2-byte payload length, payload, CRC32
	// Payload: device type tag (0x01) with value 0x00000001 (tuner),
	//          device ID tag (0x02) with value 0xFFFFFFFF (wildcard).
	packet := buildDiscoveryPacket()

	broadcastAddr := &net.UDPAddr{
		IP:   net.IPv4(255, 255, 255, 255),
		Port: 65001,
	}

	conn, err := net.ListenPacket("udp4", ":0")
	if err != nil {
		return nil, fmt.Errorf("failed to open UDP socket: %w", err)
	}
	defer conn.Close()

	// Set a read deadline based on context or default 3 seconds.
	deadline := time.Now().Add(3 * time.Second)
	if d, ok := ctx.Deadline(); ok && d.Before(deadline) {
		deadline = d
	}
	conn.SetReadDeadline(deadline)

	// Send broadcast
	if _, err := conn.WriteTo(packet, broadcastAddr); err != nil {
		return nil, fmt.Errorf("failed to send UDP broadcast: %w", err)
	}

	logger.Debug("Sent HDHomeRun UDP discovery broadcast")

	// Collect responses
	var devices []*HDHomeRunDevice
	buf := make([]byte, 4096)

	for {
		select {
		case <-ctx.Done():
			return devices, ctx.Err()
		default:
		}

		n, addr, err := conn.ReadFrom(buf)
		if err != nil {
			// Timeout or other error means we're done collecting
			if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
				break
			}
			break
		}

		if n < 4 {
			continue
		}

		dev := parseDiscoveryResponse(buf[:n], addr)
		if dev != nil {
			// Enrich with HTTP discovery to get full metadata
			httpDev, httpErr := tm.discoverHTTP(ctx, dev.LocalIP)
			if httpErr == nil && httpDev != nil {
				devices = append(devices, httpDev)
			} else {
				devices = append(devices, dev)
			}
		}
	}

	return devices, nil
}

// discoverHTTP attempts to discover a device at the given host (IP or IP:port)
// by fetching /discover.json over HTTP.
func (tm *TunerManager) discoverHTTP(ctx context.Context, host string) (*HDHomeRunDevice, error) {
	discoverURL := fmt.Sprintf("http://%s/discover.json", host)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, discoverURL, nil)
	if err != nil {
		return nil, err
	}

	// Short timeout — we're probing many hosts in parallel on LAN
	client := &http.Client{Timeout: 1 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("HTTP %d from %s", resp.StatusCode, discoverURL)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var info discoverJSON
	if err := json.Unmarshal(body, &info); err != nil {
		return nil, err
	}

	baseURL := info.BaseURL
	if baseURL == "" {
		baseURL = fmt.Sprintf("http://%s", host)
	}

	return deviceFromDiscover(&info, baseURL), nil
}

// hdhrProbePorts is the ordered list of ports to try when HTTP-probing for
// HDHomeRun-compatible devices. 80 is the HDHomeRun default; 5004 is used by
// some software tuners; 7070 and 8080 are common alternatives.
var hdhrProbePorts = []int{80, 5004, 7070, 8080}

// probeIP tries all ports in hdhrProbePorts concurrently and returns the first
// valid HDHomeRun device found, or an error if none respond.
func (tm *TunerManager) probeIP(ctx context.Context, ip string) (*HDHomeRunDevice, error) {
	type result struct {
		dev *HDHomeRunDevice
		err error
	}
	resultCh := make(chan result, len(hdhrProbePorts))

	for _, port := range hdhrProbePorts {
		host := fmt.Sprintf("%s:%d", ip, port)
		go func(h string) {
			dev, err := tm.discoverHTTP(ctx, h)
			resultCh <- result{dev, err}
		}(host)
	}

	for range hdhrProbePorts {
		r := <-resultCh
		if r.err == nil && r.dev != nil {
			return r.dev, nil
		}
	}
	return nil, fmt.Errorf("no HDHomeRun device at %s", ip)
}

// discoverSSDP sends a UPnP M-SEARCH multicast and enriches any HDHomeRun
// SSDP responses by fetching /discover.json from the reported LOCATION.
func (tm *TunerManager) discoverSSDP(ctx context.Context) ([]*HDHomeRunDevice, error) {
	mSearch := "M-SEARCH * HTTP/1.1\r\n" +
		"HOST: 239.255.255.250:1900\r\n" +
		"MAN: \"ssdp:discover\"\r\n" +
		"MX: 3\r\n" +
		"ST: ssdp:all\r\n" +
		"\r\n"

	mcastAddr, err := net.ResolveUDPAddr("udp4", "239.255.255.250:1900")
	if err != nil {
		return nil, fmt.Errorf("SSDP: resolve multicast addr: %w", err)
	}

	conn, err := net.ListenPacket("udp4", ":0")
	if err != nil {
		return nil, fmt.Errorf("SSDP: open UDP socket: %w", err)
	}
	defer conn.Close()

	deadline := time.Now().Add(4 * time.Second)
	if d, ok := ctx.Deadline(); ok && d.Before(deadline) {
		deadline = d
	}
	conn.SetReadDeadline(deadline)

	if _, err := conn.WriteTo([]byte(mSearch), mcastAddr); err != nil {
		return nil, fmt.Errorf("SSDP: send M-SEARCH: %w", err)
	}
	logger.Debug("Sent SSDP M-SEARCH multicast")

	var (
		devices []*HDHomeRunDevice
		seen    = make(map[string]bool)
	)
	buf := make([]byte, 4096)

	for {
		n, _, err := conn.ReadFrom(buf)
		if err != nil {
			break
		}

		location := parseSSDPLocation(string(buf[:n]))
		if location == "" || seen[location] {
			continue
		}
		seen[location] = true

		// Derive host:port from the LOCATION URL and probe /discover.json
		hostPort := hostPortFromURL(location)
		if hostPort == "" {
			continue
		}
		dev, err := tm.discoverHTTP(ctx, hostPort)
		if err == nil && dev != nil {
			logger.Infof("SSDP: found HDHomeRun device %s at %s", dev.DeviceID, dev.BaseURL)
			devices = append(devices, dev)
		}
	}

	return devices, nil
}

// parseSSDPLocation extracts the value of the LOCATION header from an SSDP response.
func parseSSDPLocation(response string) string {
	for _, line := range strings.Split(response, "\r\n") {
		if strings.HasPrefix(strings.ToUpper(line), "LOCATION:") {
			return strings.TrimSpace(line[9:])
		}
	}
	return ""
}

// hostPortFromURL extracts "host:port" from a URL like http://192.168.1.39:7070/device.xml.
// If the URL has no explicit port, the host alone is returned (port 80 implied).
func hostPortFromURL(rawURL string) string {
	s := rawURL
	if idx := strings.Index(s, "://"); idx >= 0 {
		s = s[idx+3:]
	}
	if idx := strings.Index(s, "/"); idx >= 0 {
		s = s[:idx]
	}
	return s // already "host" or "host:port"
}

// ============ Internal helpers ============

// getDevice looks up a device by ID; returns an error if not found.
func (tm *TunerManager) getDevice(deviceID string) (*HDHomeRunDevice, error) {
	tm.mu.RLock()
	dev, ok := tm.devices[deviceID]
	tm.mu.RUnlock()

	if !ok || dev == nil {
		return nil, fmt.Errorf("device %s not found", deviceID)
	}
	return dev, nil
}

// deviceFromDiscover converts the JSON discovery payload into an HDHomeRunDevice.
func deviceFromDiscover(info *discoverJSON, baseURL string) *HDHomeRunDevice {
	ip := extractHost(baseURL)

	lineupURL := info.LineupURL
	if lineupURL == "" {
		lineupURL = baseURL + "/lineup.json"
	}

	return &HDHomeRunDevice{
		DeviceID:        info.DeviceID,
		LocalIP:         ip,
		BaseURL:         strings.TrimRight(baseURL, "/"),
		ModelNumber:     info.ModelNumber,
		FirmwareName:    info.FirmwareName,
		FirmwareVersion: info.FirmwareVersion,
		TunerCount:      info.TunerCount,
		DeviceAuth:      info.DeviceAuth,
		LineupURL:       lineupURL,
	}
}

// extractHost pulls the host (without scheme/port) from a URL string.
func extractHost(rawURL string) string {
	// Remove scheme
	s := rawURL
	if idx := strings.Index(s, "://"); idx >= 0 {
		s = s[idx+3:]
	}
	// Remove path
	if idx := strings.Index(s, "/"); idx >= 0 {
		s = s[:idx]
	}
	// Remove port
	if idx := strings.LastIndex(s, ":"); idx >= 0 {
		s = s[:idx]
	}
	return s
}

// localSubnetIPs returns a set of IPs to probe on the local network.
// It inspects the machine's own network interfaces to determine subnets.
func localSubnetIPs() []string {
	var ips []string

	ifaces, err := net.Interfaces()
	if err != nil {
		// Fallback: try a common /24 on 192.168.1.x
		return fallbackSubnetIPs()
	}

	for _, iface := range ifaces {
		// Skip loopback and down interfaces
		if iface.Flags&net.FlagLoopback != 0 || iface.Flags&net.FlagUp == 0 {
			continue
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			ipNet, ok := addr.(*net.IPNet)
			if !ok {
				continue
			}

			ip4 := ipNet.IP.To4()
			if ip4 == nil {
				continue
			}

			// Skip loopback
			if ip4[0] == 127 {
				continue
			}

			// Scan the full /24 — parallel probing in Discover() keeps this fast.
			prefix := fmt.Sprintf("%d.%d.%d", ip4[0], ip4[1], ip4[2])
			for i := 1; i <= 254; i++ {
				candidate := fmt.Sprintf("%s.%d", prefix, i)
				if candidate != ip4.String() {
					ips = append(ips, candidate)
				}
			}
		}
	}

	if len(ips) == 0 {
		return fallbackSubnetIPs()
	}

	// Deduplicate
	seen := make(map[string]bool)
	var unique []string
	for _, ip := range ips {
		if !seen[ip] {
			seen[ip] = true
			unique = append(unique, ip)
		}
	}
	return unique
}

// commonDeviceOctets returns the last-octet values commonly assigned to
// infrastructure devices like tuners by routers (DHCP range start, .100-.110,
// low addresses, etc.). We keep the list small for speed.
func commonDeviceOctets() []int {
	return []int{
		1, 2, 3, 4, 5, 10, 50, 100, 101, 102, 103, 104, 105,
		106, 107, 108, 109, 110, 150, 200, 254,
	}
}

// fallbackSubnetIPs returns probe targets for the default 192.168.1.x /24
// when local interfaces cannot be enumerated.
func fallbackSubnetIPs() []string {
	ips := make([]string, 0, 254)
	for i := 1; i <= 254; i++ {
		ips = append(ips, fmt.Sprintf("192.168.1.%d", i))
	}
	return ips
}

// ============ HDHomeRun Discovery Protocol ============

// HDHomeRun discovery protocol constants.
const (
	hdhrTypeDiscoverReq  = 0x0002
	hdhrTypeDiscoverReply = 0x0003
	hdhrTagDeviceType    = 0x01
	hdhrTagDeviceID      = 0x02
	hdhrTagBaseURL       = 0x2A
	hdhrDeviceTypeTuner  = 0x00000001
	hdhrDeviceIDWildcard = 0xFFFFFFFF
)

// buildDiscoveryPacket constructs a valid HDHomeRun discovery request packet.
//
// Packet layout:
//   [2 bytes] Packet type (0x0002 = discover request)
//   [2 bytes] Payload length
//   Payload:
//     Tag 0x01 (device type):  [1 byte tag][1 byte length=4][4 bytes value=0x00000001]
//     Tag 0x02 (device ID):    [1 byte tag][1 byte length=4][4 bytes value=0xFFFFFFFF]
//   [4 bytes] CRC32 (appended at end)
func buildDiscoveryPacket() []byte {
	// Payload
	payload := []byte{
		// Tag: device type
		hdhrTagDeviceType,
		4, // length
		0x00, 0x00, 0x00, 0x01, // tuner
		// Tag: device ID (wildcard)
		hdhrTagDeviceID,
		4, // length
		0xFF, 0xFF, 0xFF, 0xFF,
	}

	// Header: type (2 bytes big-endian) + payload length (2 bytes big-endian)
	pkt := make([]byte, 0, 4+len(payload)+4)
	pkt = append(pkt, byte(hdhrTypeDiscoverReq>>8), byte(hdhrTypeDiscoverReq&0xFF))
	pkt = append(pkt, byte(len(payload)>>8), byte(len(payload)&0xFF))
	pkt = append(pkt, payload...)

	// Append CRC32 (HDHomeRun uses CRC32C / Castagnoli but for discovery
	// the devices also accept a simple CRC. We compute CRC32C.)
	crc := hdhrCRC32(pkt)
	pkt = append(pkt, byte(crc&0xFF), byte((crc>>8)&0xFF), byte((crc>>16)&0xFF), byte((crc>>24)&0xFF))

	return pkt
}

// hdhrCRC32 computes the CRC-32C (Castagnoli) used by the HDHomeRun protocol.
func hdhrCRC32(data []byte) uint32 {
	// CRC-32C polynomial: 0x1EDC6F41
	// We use a simple table-driven approach.
	crc := uint32(0xFFFFFFFF)
	for _, b := range data {
		crc ^= uint32(b)
		for i := 0; i < 8; i++ {
			if crc&1 != 0 {
				crc = (crc >> 1) ^ 0x82F63B78
			} else {
				crc >>= 1
			}
		}
	}
	return crc
}

// parseDiscoveryResponse attempts to extract device info from a UDP discovery
// reply packet. Returns nil if the packet is not a valid reply.
func parseDiscoveryResponse(data []byte, addr net.Addr) *HDHomeRunDevice {
	if len(data) < 8 {
		return nil
	}

	// Check packet type (first 2 bytes)
	pktType := uint16(data[0])<<8 | uint16(data[1])
	if pktType != hdhrTypeDiscoverReply {
		return nil
	}

	payloadLen := int(uint16(data[2])<<8 | uint16(data[3]))
	if len(data) < 4+payloadLen {
		return nil
	}

	payload := data[4 : 4+payloadLen]

	dev := &HDHomeRunDevice{}

	// Extract remote IP from the address
	if udpAddr, ok := addr.(*net.UDPAddr); ok {
		dev.LocalIP = udpAddr.IP.String()
		dev.BaseURL = fmt.Sprintf("http://%s", udpAddr.IP.String())
	}

	// Parse TLV tags from payload
	offset := 0
	for offset+2 <= len(payload) {
		tag := payload[offset]
		tagLen := int(payload[offset+1])
		offset += 2

		if offset+tagLen > len(payload) {
			break
		}

		value := payload[offset : offset+tagLen]
		offset += tagLen

		switch tag {
		case hdhrTagDeviceType:
			// Ignore - we already know it's a tuner
		case hdhrTagDeviceID:
			if tagLen == 4 {
				id := uint32(value[0])<<24 | uint32(value[1])<<16 | uint32(value[2])<<8 | uint32(value[3])
				dev.DeviceID = fmt.Sprintf("%08X", id)
			}
		case hdhrTagBaseURL:
			dev.BaseURL = string(value)
			dev.LocalIP = extractHost(dev.BaseURL)
		}
	}

	if dev.DeviceID == "" {
		return nil
	}

	return dev
}

// RefreshCallback is called after each scheduled tuner discovery with the
// list of discovered devices. Use this to trigger channel imports.
type RefreshCallback func(devices []*HDHomeRunDevice)

// StartScheduledRefresh begins a background goroutine that discovers tuners
// at the given interval. The callback is invoked after each successful discovery.
// Call StopScheduledRefresh to stop the goroutine gracefully.
func (tm *TunerManager) StartScheduledRefresh(interval time.Duration, callback RefreshCallback) {
	if interval < time.Minute {
		interval = time.Hour * 6 // Default: 6 hours
	}

	tm.stopCh = make(chan struct{})

	go func() {
		logger.Infof("TunerManager: scheduled refresh started (every %v)", interval)
		ticker := time.NewTicker(interval)
		defer ticker.Stop()

		for {
			select {
			case <-tm.stopCh:
				logger.Infof("TunerManager: scheduled refresh stopped")
				return
			case <-ticker.C:
				ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				devices, err := tm.Discover(ctx)
				cancel()

				if err != nil {
					logger.Warnf("TunerManager: scheduled refresh failed: %v", err)
					continue
				}

				logger.Infof("TunerManager: scheduled refresh found %d device(s)", len(devices))
				if callback != nil {
					callback(devices)
				}
			}
		}
	}()
}

// StopScheduledRefresh stops the background refresh goroutine.
func (tm *TunerManager) StopScheduledRefresh() {
	tm.stopOnce.Do(func() {
		if tm.stopCh != nil {
			close(tm.stopCh)
		}
	})
}
