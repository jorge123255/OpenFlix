package upnp

import (
	"context"
	"fmt"
	"net"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

const (
	// UPnP lease is 1 hour; refresh at 45 minutes to stay ahead of expiry.
	leaseDuration = 3600 // seconds
	refreshEvery  = 45 * time.Minute
)

// Manager handles UPnP port mapping lifecycle: discovery, initial mapping,
// periodic renewal, and cleanup on shutdown.
type Manager struct {
	port        int
	description string

	mu         sync.Mutex
	externalIP string
	active     bool

	client *Client
	ctx    context.Context
	cancel context.CancelFunc
}

// NewManager creates a UPnP manager for the given server port.
func NewManager(port int) *Manager {
	return &Manager{
		port:        port,
		description: "OpenFlix",
	}
}

// Start begins UPnP discovery and port mapping in the background.
// The provided callback is called whenever the external IP changes.
func (m *Manager) Start(onExternalIP func(ip string)) {
	m.ctx, m.cancel = context.WithCancel(context.Background())
	go m.run(onExternalIP)
}

// Stop removes the port mapping and shuts down the manager.
func (m *Manager) Stop() {
	if m.cancel != nil {
		m.cancel()
	}
	m.mu.Lock()
	client := m.client
	active := m.active
	m.mu.Unlock()

	if client != nil && active {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = client.DeletePortMapping(ctx, m.port, "TCP")
	}
}

// ExternalIP returns the last known WAN IP, or empty string if not yet known.
func (m *Manager) ExternalIP() string {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.externalIP
}

func (m *Manager) run(onExternalIP func(ip string)) {
	m.attempt(onExternalIP)

	ticker := time.NewTicker(refreshEvery)
	defer ticker.Stop()

	for {
		select {
		case <-m.ctx.Done():
			return
		case <-ticker.C:
			m.attempt(onExternalIP)
		}
	}
}

func (m *Manager) attempt(onExternalIP func(ip string)) {
	m.mu.Lock()
	client := m.client
	m.mu.Unlock()

	if client == nil {
		var err error
		client, err = Discover()
		if err != nil {
			logger.Debugf("UPnP: IGD not available (%v) — remote access requires manual port forwarding or cloudflared tunnel", err)
			// Don't retry rapidly — UPnP absence is usually permanent (router doesn't support it).
			// The 45-minute ticker will try again periodically in case the router changes.
			return
		}
		logger.Infof("UPnP: IGD found (%s)", client.controlURL)
		m.mu.Lock()
		m.client = client
		m.mu.Unlock()
	}

	ctx, cancel := context.WithTimeout(m.ctx, 10*time.Second)
	defer cancel()

	wanIP, err := client.GetExternalIP(ctx)
	if err != nil {
		logger.Debugf("UPnP: GetExternalIP failed: %v — resetting client", err)
		m.mu.Lock()
		m.client = nil
		m.mu.Unlock()
		return
	}

	lanIP, err := getLANIP()
	if err != nil {
		logger.Debugf("UPnP: could not determine LAN IP: %v", err)
		return
	}

	err = client.AddPortMapping(ctx, m.port, m.port, lanIP, "TCP", m.description, leaseDuration)
	if err != nil {
		// Some routers reject if a stale mapping exists; delete then re-add.
		_ = client.DeletePortMapping(ctx, m.port, "TCP")
		err = client.AddPortMapping(ctx, m.port, m.port, lanIP, "TCP", m.description, leaseDuration)
		if err != nil {
			logger.Warnf("UPnP: AddPortMapping failed: %v", err)
			return
		}
	}

	m.mu.Lock()
	changed := m.externalIP != wanIP
	m.externalIP = wanIP
	m.active = true
	m.mu.Unlock()

	if changed {
		logger.Infof("UPnP: port %d mapped on router, WAN IP = %s", m.port, wanIP)
		if onExternalIP != nil {
			onExternalIP(wanIP)
		}
	}
}

// getLANIP returns the host's primary non-loopback IPv4 address.
func getLANIP() (string, error) {
	ifaces, err := net.Interfaces()
	if err != nil {
		return "", err
	}
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, _ := iface.Addrs()
		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			if ip == nil || ip.IsLoopback() {
				continue
			}
			if ip4 := ip.To4(); ip4 != nil {
				return fmt.Sprintf("%s", ip4), nil
			}
		}
	}
	return "", fmt.Errorf("no suitable LAN IP found")
}
