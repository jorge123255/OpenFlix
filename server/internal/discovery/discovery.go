package discovery

import (
	"encoding/json"
	"fmt"
	"net"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

const (
	DiscoveryPort     = 32412 // Port for UDP discovery (like Plex's GDM)
	BroadcastPort     = 32414 // Port for broadcast announcements
	MulticastAddr     = "239.0.0.250:32412"
	DiscoveryMagic    = "OPENFLIX_DISCOVER"
	ResponseMagic     = "OPENFLIX_SERVER"
	BroadcastInterval = 5 * time.Second
)

// ServerInfo contains information about the server for discovery
type ServerInfo struct {
	Name           string `json:"name"`
	Version        string `json:"version"`
	MachineID      string `json:"machineId"`
	Host           string `json:"host"`
	Port           int    `json:"port"`
	Protocol       string `json:"protocol"`
	LocalAddresses []string `json:"localAddresses"`
}

// DiscoveryService handles server discovery on the local network
type DiscoveryService struct {
	serverInfo ServerInfo
	running    bool
	stopChan   chan struct{}
}

// NewDiscoveryService creates a new discovery service
func NewDiscoveryService(name, version, machineID, host string, port int) *DiscoveryService {
	localAddrs := getLocalAddresses()

	return &DiscoveryService{
		serverInfo: ServerInfo{
			Name:           name,
			Version:        version,
			MachineID:      machineID,
			Host:           host,
			Port:           port,
			Protocol:       "http",
			LocalAddresses: localAddrs,
		},
		stopChan: make(chan struct{}),
	}
}

// Start begins the discovery service
func (d *DiscoveryService) Start() error {
	if d.running {
		return nil
	}

	d.running = true

	// Start UDP listener for discovery requests
	go d.listenForDiscoveryRequests()

	// Start periodic broadcast announcements
	go d.broadcastPresence()

	logger.Infof("Discovery service started on port %d", DiscoveryPort)
	return nil
}

// Stop stops the discovery service
func (d *DiscoveryService) Stop() {
	if !d.running {
		return
	}
	d.running = false
	close(d.stopChan)
	logger.Info("Discovery service stopped")
}

// listenForDiscoveryRequests listens for UDP discovery requests and responds
func (d *DiscoveryService) listenForDiscoveryRequests() {
	addr := net.UDPAddr{
		Port: DiscoveryPort,
		IP:   net.IPv4zero,
	}

	conn, err := net.ListenUDP("udp4", &addr)
	if err != nil {
		logger.Errorf("Failed to start discovery listener: %v", err)
		return
	}
	defer conn.Close()

	// Set read timeout to allow checking stop channel
	conn.SetReadDeadline(time.Now().Add(1 * time.Second))

	buffer := make([]byte, 1024)
	for d.running {
		select {
		case <-d.stopChan:
			return
		default:
			n, remoteAddr, err := conn.ReadFromUDP(buffer)
			if err != nil {
				if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
					conn.SetReadDeadline(time.Now().Add(1 * time.Second))
					continue
				}
				continue
			}

			message := string(buffer[:n])
			if message == DiscoveryMagic {
				logger.Debugf("Discovery request from %s", remoteAddr.String())
				d.sendResponse(conn, remoteAddr)
			}
		}
	}
}

// sendResponse sends server info back to the requesting client
func (d *DiscoveryService) sendResponse(conn *net.UDPConn, addr *net.UDPAddr) {
	response := struct {
		Magic  string     `json:"magic"`
		Server ServerInfo `json:"server"`
	}{
		Magic:  ResponseMagic,
		Server: d.serverInfo,
	}

	data, err := json.Marshal(response)
	if err != nil {
		logger.Errorf("Failed to marshal discovery response: %v", err)
		return
	}

	_, err = conn.WriteToUDP(data, addr)
	if err != nil {
		logger.Errorf("Failed to send discovery response: %v", err)
	}
}

// broadcastPresence periodically broadcasts the server's presence
func (d *DiscoveryService) broadcastPresence() {
	// Get broadcast address
	broadcastAddr, err := net.ResolveUDPAddr("udp4", fmt.Sprintf("255.255.255.255:%d", BroadcastPort))
	if err != nil {
		logger.Errorf("Failed to resolve broadcast address: %v", err)
		return
	}

	conn, err := net.DialUDP("udp4", nil, broadcastAddr)
	if err != nil {
		logger.Errorf("Failed to create broadcast socket: %v", err)
		return
	}
	defer conn.Close()

	ticker := time.NewTicker(BroadcastInterval)
	defer ticker.Stop()

	// Send initial broadcast
	d.sendBroadcast(conn)

	for {
		select {
		case <-d.stopChan:
			return
		case <-ticker.C:
			d.sendBroadcast(conn)
		}
	}
}

// sendBroadcast sends a broadcast packet announcing the server
func (d *DiscoveryService) sendBroadcast(conn *net.UDPConn) {
	announcement := struct {
		Magic  string     `json:"magic"`
		Server ServerInfo `json:"server"`
	}{
		Magic:  ResponseMagic,
		Server: d.serverInfo,
	}

	data, err := json.Marshal(announcement)
	if err != nil {
		logger.Errorf("Failed to marshal broadcast: %v", err)
		return
	}

	_, err = conn.Write(data)
	if err != nil {
		// Broadcast may fail on some networks, that's OK
		logger.Debugf("Broadcast send failed (may be blocked): %v", err)
	}
}

// getLocalAddresses returns all local IPv4 addresses
func getLocalAddresses() []string {
	var addresses []string

	interfaces, err := net.Interfaces()
	if err != nil {
		return addresses
	}

	for _, iface := range interfaces {
		// Skip loopback and down interfaces
		if iface.Flags&net.FlagLoopback != 0 || iface.Flags&net.FlagUp == 0 {
			continue
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}

			// Only include IPv4 addresses
			if ip == nil || ip.IsLoopback() || ip.To4() == nil {
				continue
			}

			addresses = append(addresses, ip.String())
		}
	}

	return addresses
}
