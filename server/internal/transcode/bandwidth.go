package transcode

import (
	"sync"
	"time"
)

// Quality threshold constants (bits per second)
const (
	Threshold1080p = 15_000_000 // >15 Mbps => 1080p
	Threshold720p  = 8_000_000  // >8 Mbps  => 720p
	Threshold480p  = 3_000_000  // >3 Mbps  => 480p
	// Below 3 Mbps => 360p

	maxSamples           = 10
	staleClientTimeout   = 30 * time.Minute
	cleanupInterval      = 5 * time.Minute
)

// RecommendedQuality is a named quality tier returned by the bandwidth manager.
type RecommendedQuality string

const (
	Quality1080pBW RecommendedQuality = "1080p"
	Quality720pBW  RecommendedQuality = "720p"
	Quality480pBW  RecommendedQuality = "480p"
	Quality360pBW  RecommendedQuality = "360p"
)

// ClientBandwidthStats holds per-client bandwidth tracking data.
type ClientBandwidthStats struct {
	ClientID          string             `json:"clientId"`
	Samples           []float64          `json:"samples"`           // last N bandwidth samples in bps
	AverageBandwidth  float64            `json:"averageBandwidth"`  // moving average in bps
	RecommendedQuality RecommendedQuality `json:"recommendedQuality"`
	ManualCap         float64            `json:"manualCap"`         // manual bandwidth cap in bps, 0 = no cap
	LastReport        time.Time          `json:"lastReport"`
	TotalReports      int64              `json:"totalReports"`
}

// ServerBandwidthStats contains aggregate server bandwidth information.
type ServerBandwidthStats struct {
	TotalClients       int     `json:"totalClients"`
	ActiveClients      int     `json:"activeClients"`
	TotalBandwidthUsed float64 `json:"totalBandwidthUsed"` // sum of all client averages in bps
	ServerLimit        float64 `json:"serverLimit"`        // server-wide bandwidth limit in bps, 0 = unlimited
	LimitUtilization   float64 `json:"limitUtilization"`   // 0.0-1.0 utilization ratio
}

// BandwidthManager tracks per-client bandwidth and provides adaptive quality recommendations.
type BandwidthManager struct {
	mu          sync.RWMutex
	clients     map[string]*ClientBandwidthStats
	serverLimit float64 // server-wide bandwidth limit in bps, 0 = unlimited
	stopCh      chan struct{}
}

// NewBandwidthManager creates and starts a new BandwidthManager.
func NewBandwidthManager() *BandwidthManager {
	bm := &BandwidthManager{
		clients: make(map[string]*ClientBandwidthStats),
		stopCh:  make(chan struct{}),
	}
	go bm.cleanupLoop()
	return bm
}

// ReportBandwidth records a new bandwidth measurement for a client.
// bandwidthBps is the measured bandwidth in bits per second.
func (bm *BandwidthManager) ReportBandwidth(clientID string, bandwidthBps float64) *ClientBandwidthStats {
	bm.mu.Lock()
	defer bm.mu.Unlock()

	stats, exists := bm.clients[clientID]
	if !exists {
		stats = &ClientBandwidthStats{
			ClientID: clientID,
			Samples:  make([]float64, 0, maxSamples),
		}
		bm.clients[clientID] = stats
	}

	// Append sample, keeping only the last maxSamples
	stats.Samples = append(stats.Samples, bandwidthBps)
	if len(stats.Samples) > maxSamples {
		stats.Samples = stats.Samples[len(stats.Samples)-maxSamples:]
	}

	stats.LastReport = time.Now()
	stats.TotalReports++

	// Recalculate moving average
	stats.AverageBandwidth = movingAverage(stats.Samples)

	// Determine effective bandwidth (respect manual cap)
	effectiveBW := stats.AverageBandwidth
	if stats.ManualCap > 0 && effectiveBW > stats.ManualCap {
		effectiveBW = stats.ManualCap
	}

	// Apply server limit proportionally if we are near capacity
	if bm.serverLimit > 0 {
		totalUsed := bm.totalBandwidthUsedLocked()
		if totalUsed > bm.serverLimit {
			ratio := bm.serverLimit / totalUsed
			effectiveBW *= ratio
		}
	}

	stats.RecommendedQuality = qualityForBandwidth(effectiveBW)

	return stats.snapshot()
}

// GetClientStats returns the current bandwidth stats for a specific client.
func (bm *BandwidthManager) GetClientStats(clientID string) *ClientBandwidthStats {
	bm.mu.RLock()
	defer bm.mu.RUnlock()

	stats, exists := bm.clients[clientID]
	if !exists {
		return nil
	}
	return stats.snapshot()
}

// SetClientCap sets a manual bandwidth cap for a client.
// capBps is the cap in bits per second. 0 removes the cap.
func (bm *BandwidthManager) SetClientCap(clientID string, capBps float64) *ClientBandwidthStats {
	bm.mu.Lock()
	defer bm.mu.Unlock()

	stats, exists := bm.clients[clientID]
	if !exists {
		stats = &ClientBandwidthStats{
			ClientID:   clientID,
			Samples:    make([]float64, 0, maxSamples),
			LastReport: time.Now(),
		}
		bm.clients[clientID] = stats
	}

	stats.ManualCap = capBps

	// Recalculate recommended quality with the new cap
	effectiveBW := stats.AverageBandwidth
	if capBps > 0 && effectiveBW > capBps {
		effectiveBW = capBps
	}
	stats.RecommendedQuality = qualityForBandwidth(effectiveBW)

	return stats.snapshot()
}

// GetServerStats returns aggregate server bandwidth statistics.
func (bm *BandwidthManager) GetServerStats() *ServerBandwidthStats {
	bm.mu.RLock()
	defer bm.mu.RUnlock()

	now := time.Now()
	totalBW := 0.0
	activeCount := 0

	for _, stats := range bm.clients {
		totalBW += stats.AverageBandwidth
		if now.Sub(stats.LastReport) < staleClientTimeout {
			activeCount++
		}
	}

	serverStats := &ServerBandwidthStats{
		TotalClients:       len(bm.clients),
		ActiveClients:      activeCount,
		TotalBandwidthUsed: totalBW,
		ServerLimit:        bm.serverLimit,
	}

	if bm.serverLimit > 0 && totalBW > 0 {
		serverStats.LimitUtilization = totalBW / bm.serverLimit
		if serverStats.LimitUtilization > 1.0 {
			serverStats.LimitUtilization = 1.0
		}
	}

	return serverStats
}

// SetServerLimit sets the server-wide bandwidth limit.
// limitBps is the limit in bits per second. 0 means unlimited.
func (bm *BandwidthManager) SetServerLimit(limitBps float64) {
	bm.mu.Lock()
	defer bm.mu.Unlock()
	bm.serverLimit = limitBps
}

// GetServerLimit returns the current server-wide bandwidth limit.
func (bm *BandwidthManager) GetServerLimit() float64 {
	bm.mu.RLock()
	defer bm.mu.RUnlock()
	return bm.serverLimit
}

// GetRecommendedQuality returns the recommended quality for a client based on
// the most recent bandwidth data. Returns Quality360pBW if the client is unknown.
func (bm *BandwidthManager) GetRecommendedQuality(clientID string) RecommendedQuality {
	bm.mu.RLock()
	defer bm.mu.RUnlock()

	stats, exists := bm.clients[clientID]
	if !exists || stats.AverageBandwidth == 0 {
		return Quality360pBW
	}
	return stats.RecommendedQuality
}

// GetEstimatedBandwidth returns the estimated bandwidth for a client in bps.
// Returns 0 if the client is unknown.
func (bm *BandwidthManager) GetEstimatedBandwidth(clientID string) float64 {
	bm.mu.RLock()
	defer bm.mu.RUnlock()

	stats, exists := bm.clients[clientID]
	if !exists {
		return 0
	}
	return stats.AverageBandwidth
}

// Stop shuts down the bandwidth manager's background cleanup goroutine.
func (bm *BandwidthManager) Stop() {
	close(bm.stopCh)
}

// cleanupLoop runs periodically to remove stale clients.
func (bm *BandwidthManager) cleanupLoop() {
	ticker := time.NewTicker(cleanupInterval)
	defer ticker.Stop()

	for {
		select {
		case <-bm.stopCh:
			return
		case <-ticker.C:
			bm.cleanupStaleClients()
		}
	}
}

// cleanupStaleClients removes clients that have not reported in over staleClientTimeout.
func (bm *BandwidthManager) cleanupStaleClients() {
	bm.mu.Lock()
	defer bm.mu.Unlock()

	now := time.Now()
	for id, stats := range bm.clients {
		if now.Sub(stats.LastReport) > staleClientTimeout {
			delete(bm.clients, id)
		}
	}
}

// totalBandwidthUsedLocked calculates total bandwidth used across all clients.
// Must be called with bm.mu held.
func (bm *BandwidthManager) totalBandwidthUsedLocked() float64 {
	total := 0.0
	for _, stats := range bm.clients {
		total += stats.AverageBandwidth
	}
	return total
}

// qualityForBandwidth returns the recommended quality tier for a given bandwidth in bps.
func qualityForBandwidth(bps float64) RecommendedQuality {
	switch {
	case bps > Threshold1080p:
		return Quality1080pBW
	case bps > Threshold720p:
		return Quality720pBW
	case bps > Threshold480p:
		return Quality480pBW
	default:
		return Quality360pBW
	}
}

// movingAverage calculates the arithmetic mean of the samples.
func movingAverage(samples []float64) float64 {
	if len(samples) == 0 {
		return 0
	}
	sum := 0.0
	for _, s := range samples {
		sum += s
	}
	return sum / float64(len(samples))
}

// snapshot returns a copy of the stats safe for use outside the lock.
func (s *ClientBandwidthStats) snapshot() *ClientBandwidthStats {
	samplesCopy := make([]float64, len(s.Samples))
	copy(samplesCopy, s.Samples)
	return &ClientBandwidthStats{
		ClientID:           s.ClientID,
		Samples:            samplesCopy,
		AverageBandwidth:   s.AverageBandwidth,
		RecommendedQuality: s.RecommendedQuality,
		ManualCap:          s.ManualCap,
		LastReport:         s.LastReport,
		TotalReports:       s.TotalReports,
	}
}
