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
func NewTunerManager() *TunerManager {
	return &TunerManager{
		devices: make(map[string]*HDHomeRunDevice),
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// Discover scans the local network for HDHomeRun devices using both UDP
// broadcast and HTTP probing on common subnet addresses.
func (tm *TunerManager) Discover(ctx context.Context) ([]*HDHomeRunDevice, error) {
	logger.Info("Starting HDHomeRun device discovery")

	var (
		wg         sync.WaitGroup
		mu         sync.Mutex
		discovered []*HDHomeRunDevice
	)

	// Channel to collect discovered devices from both methods
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

	// HTTP discovery on local subnet
	wg.Add(1)
	go func() {
		defer wg.Done()
		ips := localSubnetIPs()
		for _, ip := range ips {
			select {
			case <-ctx.Done():
				return
			default:
			}
			dev, err := tm.discoverHTTP(ctx, ip)
			if err == nil && dev != nil {
				devCh <- dev
			}
		}
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

	// Store discovered devices
	tm.mu.Lock()
	for _, d := range unique {
		tm.devices[d.DeviceID] = d
	}
	tm.mu.Unlock()

	sort.Slice(unique, func(i, j int) bool {
		return unique[i].DeviceID < unique[j].DeviceID
	})

	logger.Infof("HDHomeRun discovery complete: found %d device(s)", len(unique))
	return unique, nil
}

// AddDevice manually registers a device by its base URL (e.g. http://192.168.1.100).
// It fetches /discover.json to populate device metadata.
func (tm *TunerManager) AddDevice(baseURL string) (*HDHomeRunDevice, error) {
	baseURL = strings.TrimRight(baseURL, "/")
	discoverURL := baseURL + "/discover.json"

	resp, err := tm.client.Get(discoverURL)
	if err != nil {
		return nil, fmt.Errorf("failed to reach device at %s: %w", discoverURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("device returned HTTP %d from %s", resp.StatusCode, discoverURL)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response from %s: %w", discoverURL, err)
	}

	var info discoverJSON
	if err := json.Unmarshal(body, &info); err != nil {
		return nil, fmt.Errorf("invalid JSON from %s: %w", discoverURL, err)
	}

	dev := deviceFromDiscover(&info, baseURL)

	tm.mu.Lock()
	tm.devices[dev.DeviceID] = dev
	tm.mu.Unlock()

	logger.Infof("Added HDHomeRun device %s (%s) at %s", dev.DeviceID, dev.ModelNumber, dev.BaseURL)
	return dev, nil
}

// GetDevices returns all known devices sorted by DeviceID.
func (tm *TunerManager) GetDevices() []*HDHomeRunDevice {
	tm.mu.RLock()
	defer tm.mu.RUnlock()

	devices := make([]*HDHomeRunDevice, 0, len(tm.devices))
	for _, d := range tm.devices {
		devices = append(devices, d)
	}
	sort.Slice(devices, func(i, j int) bool {
		return devices[i].DeviceID < devices[j].DeviceID
	})
	return devices
}

// RemoveDevice removes a device by its DeviceID.
func (tm *TunerManager) RemoveDevice(deviceID string) {
	tm.mu.Lock()
	defer tm.mu.Unlock()
	delete(tm.devices, deviceID)
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
func (tm *TunerManager) GetTunerStatus(deviceID string) ([]HDHomeRunStatus, error) {
	dev, err := tm.getDevice(deviceID)
	if err != nil {
		return nil, err
	}

	statusURL := dev.BaseURL + "/status.json"

	resp, err := tm.client.Get(statusURL)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch tuner status from %s: %w", statusURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("status request returned HTTP %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read status response: %w", err)
	}

	var statuses []HDHomeRunStatus
	if err := json.Unmarshal(body, &statuses); err != nil {
		return nil, fmt.Errorf("failed to parse status JSON: %w", err)
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

// discoverHTTP attempts to discover a device at the given IP address by
// fetching /discover.json over HTTP.
func (tm *TunerManager) discoverHTTP(ctx context.Context, ip string) (*HDHomeRunDevice, error) {
	discoverURL := fmt.Sprintf("http://%s/discover.json", ip)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, discoverURL, nil)
	if err != nil {
		return nil, err
	}

	// Use a short timeout for probing
	client := &http.Client{Timeout: 2 * time.Second}
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
		baseURL = fmt.Sprintf("http://%s", ip)
	}

	return deviceFromDiscover(&info, baseURL), nil
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

			// For each local IP, probe a small range around it.
			// HDHomeRun devices are typically on .1 through .254 of the same /24.
			// We probe a limited set of common addresses to keep it fast.
			prefix := fmt.Sprintf("%d.%d.%d", ip4[0], ip4[1], ip4[2])
			for _, lastOctet := range commonDeviceOctets() {
				candidate := fmt.Sprintf("%s.%d", prefix, lastOctet)
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

// fallbackSubnetIPs returns probe targets when we can't determine the local
// subnet from interfaces.
func fallbackSubnetIPs() []string {
	var ips []string
	for _, lastOctet := range commonDeviceOctets() {
		ips = append(ips, fmt.Sprintf("192.168.1.%d", lastOctet))
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
