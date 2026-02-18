package health

import (
	"math"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// StreamMetrics holds the raw metrics reported by a player for a single stream.
type StreamMetrics struct {
	StreamID    string  `json:"streamId"`
	ChannelID   string  `json:"channelId,omitempty"`
	ChannelName string  `json:"channelName,omitempty"`
	ClientID    string  `json:"clientId,omitempty"`
	UserID      string  `json:"userId,omitempty"`
	Codec       string  `json:"codec,omitempty"`
	Resolution  string  `json:"resolution,omitempty"`
	BitrateKbps float64 `json:"bitrateKbps"`      // instantaneous bitrate
	ErrorCount  int     `json:"errorCount"`        // packet/segment errors
	Underruns   int     `json:"underruns"`         // buffer underruns
	LatencyMs   float64 `json:"latencyMs"`         // stream latency
	DroppedFps  float64 `json:"droppedFps"`        // dropped frames per second
}

// StreamHealth represents the computed health state of a single stream.
type StreamHealth struct {
	StreamID        string    `json:"streamId"`
	ChannelID       string    `json:"channelId,omitempty"`
	ChannelName     string    `json:"channelName,omitempty"`
	ClientID        string    `json:"clientId,omitempty"`
	UserID          string    `json:"userId,omitempty"`
	Codec           string    `json:"codec,omitempty"`
	Resolution      string    `json:"resolution,omitempty"`
	HealthScore     int       `json:"healthScore"` // 0-100
	AvgBitrateKbps  float64   `json:"avgBitrateKbps"`
	TotalErrors     int       `json:"totalErrors"`
	TotalUnderruns  int       `json:"totalUnderruns"`
	AvgLatencyMs    float64   `json:"avgLatencyMs"`
	DroppedFps      float64   `json:"droppedFps"`
	ConnectedAt     time.Time `json:"connectedAt"`
	LastReportAt    time.Time `json:"lastReportAt"`
	DurationSeconds float64   `json:"durationSeconds"`
	ReportCount     int       `json:"reportCount"`
}

// ChannelHealth represents the aggregate health for all viewers on a channel.
type ChannelHealth struct {
	ChannelID       string  `json:"channelId"`
	ChannelName     string  `json:"channelName,omitempty"`
	ActiveViewers   int     `json:"activeViewers"`
	AvgHealthScore  int     `json:"avgHealthScore"`
	MinHealthScore  int     `json:"minHealthScore"`
	MaxHealthScore  int     `json:"maxHealthScore"`
	AvgBitrateKbps  float64 `json:"avgBitrateKbps"`
	TotalErrors     int     `json:"totalErrors"`
	TotalUnderruns  int     `json:"totalUnderruns"`
	AvgLatencyMs    float64 `json:"avgLatencyMs"`
}

// HealthSnapshot stores a point-in-time health reading for history.
type HealthSnapshot struct {
	Timestamp      time.Time `json:"timestamp"`
	HealthScore    int       `json:"healthScore"`
	ActiveViewers  int       `json:"activeViewers"`
	AvgBitrateKbps float64  `json:"avgBitrateKbps"`
	TotalErrors    int       `json:"totalErrors"`
	AvgLatencyMs   float64  `json:"avgLatencyMs"`
}

// HealthAlert represents a health issue that crossed a threshold.
type HealthAlert struct {
	ID         string    `json:"id"`
	StreamID   string    `json:"streamId"`
	ChannelID  string    `json:"channelId,omitempty"`
	Level      string    `json:"level"` // "warning" or "critical"
	Message    string    `json:"message"`
	HealthScore int      `json:"healthScore"`
	CreatedAt  time.Time `json:"createdAt"`
}

// AlertThresholds defines configurable alert thresholds.
type AlertThresholds struct {
	WarningScore  int     // health score below this triggers a warning (default 50)
	CriticalScore int     // health score below this triggers a critical alert (default 25)
	MaxLatencyMs  float64 // latency above this triggers a warning (default 5000)
	MaxErrorRate  float64 // errors per report above this triggers a warning (default 10)
}

// DefaultAlertThresholds returns sensible defaults.
func DefaultAlertThresholds() AlertThresholds {
	return AlertThresholds{
		WarningScore:  50,
		CriticalScore: 25,
		MaxLatencyMs:  5000,
		MaxErrorRate:  10,
	}
}

// streamState holds all internal tracking state for a single stream.
type streamState struct {
	health         StreamHealth
	bitrateSamples []bitratePoint // rolling window for bitrate averaging
	latencySamples []float64      // recent latency samples
}

type bitratePoint struct {
	timestamp time.Time
	kbps      float64
}

// StreamHealthMonitor is the central monitor that tracks per-stream and
// per-channel health with in-memory storage. All methods are thread-safe.
type StreamHealthMonitor struct {
	mu              sync.RWMutex
	streams         map[string]*streamState            // streamID -> state
	channelHistory  map[string][]HealthSnapshot         // channelID -> last 1 hour of per-minute snapshots
	alerts          []HealthAlert                        // current alerts
	thresholds      AlertThresholds
	stopCh          chan struct{}
	stopped         bool

	// configuration
	bitrateWindowSec int           // rolling window for bitrate averaging
	staleTimeout     time.Duration // no data for this long = stale
	historyDuration  time.Duration // how long to keep history
	cleanupInterval  time.Duration // how often to run cleanup
	snapshotInterval time.Duration // how often to take channel snapshots
}

// NewStreamHealthMonitor creates a new monitor with sensible defaults.
func NewStreamHealthMonitor() *StreamHealthMonitor {
	return &StreamHealthMonitor{
		streams:          make(map[string]*streamState),
		channelHistory:   make(map[string][]HealthSnapshot),
		alerts:           make([]HealthAlert, 0),
		thresholds:       DefaultAlertThresholds(),
		stopCh:           make(chan struct{}),
		bitrateWindowSec: 10,
		staleTimeout:     5 * time.Minute,
		historyDuration:  1 * time.Hour,
		cleanupInterval:  1 * time.Minute,
		snapshotInterval: 1 * time.Minute,
	}
}

// SetThresholds updates alert thresholds.
func (m *StreamHealthMonitor) SetThresholds(t AlertThresholds) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.thresholds = t
}

// StartBackgroundTasks starts the cleanup and snapshot goroutines.
// It should be called once after creating the monitor.
func (m *StreamHealthMonitor) StartBackgroundTasks() {
	go m.cleanupLoop()
	go m.snapshotLoop()
	logger.Info("Stream health monitor started")
}

// Stop signals background goroutines to exit.
func (m *StreamHealthMonitor) Stop() {
	m.mu.Lock()
	defer m.mu.Unlock()
	if !m.stopped {
		m.stopped = true
		close(m.stopCh)
		logger.Info("Stream health monitor stopped")
	}
}

// ReportMetrics records a new metrics report from a player.
func (m *StreamHealthMonitor) ReportMetrics(metrics StreamMetrics) StreamHealth {
	m.mu.Lock()
	defer m.mu.Unlock()

	now := time.Now()

	state, exists := m.streams[metrics.StreamID]
	if !exists {
		state = &streamState{
			health: StreamHealth{
				StreamID:    metrics.StreamID,
				ChannelID:   metrics.ChannelID,
				ChannelName: metrics.ChannelName,
				ClientID:    metrics.ClientID,
				UserID:      metrics.UserID,
				ConnectedAt: now,
			},
			bitrateSamples: make([]bitratePoint, 0, 64),
			latencySamples: make([]float64, 0, 64),
		}
		m.streams[metrics.StreamID] = state
	}

	// Update metadata (may change over time)
	if metrics.ChannelID != "" {
		state.health.ChannelID = metrics.ChannelID
	}
	if metrics.ChannelName != "" {
		state.health.ChannelName = metrics.ChannelName
	}
	if metrics.ClientID != "" {
		state.health.ClientID = metrics.ClientID
	}
	if metrics.UserID != "" {
		state.health.UserID = metrics.UserID
	}
	if metrics.Codec != "" {
		state.health.Codec = metrics.Codec
	}
	if metrics.Resolution != "" {
		state.health.Resolution = metrics.Resolution
	}

	// Add bitrate sample and trim window
	state.bitrateSamples = append(state.bitrateSamples, bitratePoint{
		timestamp: now,
		kbps:      metrics.BitrateKbps,
	})
	cutoff := now.Add(-time.Duration(m.bitrateWindowSec) * time.Second)
	trimIdx := 0
	for trimIdx < len(state.bitrateSamples) && state.bitrateSamples[trimIdx].timestamp.Before(cutoff) {
		trimIdx++
	}
	if trimIdx > 0 {
		state.bitrateSamples = state.bitrateSamples[trimIdx:]
	}

	// Compute rolling average bitrate
	var sum float64
	for _, bp := range state.bitrateSamples {
		sum += bp.kbps
	}
	if len(state.bitrateSamples) > 0 {
		state.health.AvgBitrateKbps = sum / float64(len(state.bitrateSamples))
	}

	// Accumulate errors and underruns
	state.health.TotalErrors += metrics.ErrorCount
	state.health.TotalUnderruns += metrics.Underruns

	// Track latency (keep last 30 samples)
	state.latencySamples = append(state.latencySamples, metrics.LatencyMs)
	if len(state.latencySamples) > 30 {
		state.latencySamples = state.latencySamples[len(state.latencySamples)-30:]
	}
	var latSum float64
	for _, l := range state.latencySamples {
		latSum += l
	}
	state.health.AvgLatencyMs = latSum / float64(len(state.latencySamples))

	// Dropped FPS
	state.health.DroppedFps = metrics.DroppedFps

	// Update timestamps and counters
	state.health.LastReportAt = now
	state.health.DurationSeconds = now.Sub(state.health.ConnectedAt).Seconds()
	state.health.ReportCount++

	// Compute health score
	state.health.HealthScore = m.computeHealthScore(state)

	// Check for alerts
	m.checkAlerts(state.health)

	return state.health
}

// computeHealthScore produces a 0-100 score from the current stream state.
// Weights:
//   - Bitrate stability: 30%  (penalize if < 500 kbps or highly variable)
//   - Error rate:        25%  (errors per report)
//   - Underrun rate:     20%  (underruns per report)
//   - Latency:           15%  (penalize high latency)
//   - Dropped frames:    10%
func (m *StreamHealthMonitor) computeHealthScore(state *streamState) int {
	h := state.health

	// --- Bitrate component (0-30) ---
	bitrateScore := 30.0
	if h.AvgBitrateKbps < 100 {
		bitrateScore = 0
	} else if h.AvgBitrateKbps < 500 {
		bitrateScore = 15.0 * (h.AvgBitrateKbps / 500.0)
	}
	// Penalize high bitrate variance
	if len(state.bitrateSamples) > 2 {
		mean := h.AvgBitrateKbps
		var varianceSum float64
		for _, bp := range state.bitrateSamples {
			diff := bp.kbps - mean
			varianceSum += diff * diff
		}
		stddev := math.Sqrt(varianceSum / float64(len(state.bitrateSamples)))
		if mean > 0 {
			cv := stddev / mean // coefficient of variation
			if cv > 0.5 {
				bitrateScore *= 0.5 // major instability
			} else if cv > 0.2 {
				bitrateScore *= 0.75
			}
		}
	}

	// --- Error component (0-25) ---
	errorScore := 25.0
	if h.ReportCount > 0 {
		errorRate := float64(h.TotalErrors) / float64(h.ReportCount)
		if errorRate > 10 {
			errorScore = 0
		} else if errorRate > 0 {
			errorScore = 25.0 * (1.0 - (errorRate / 10.0))
		}
	}

	// --- Underrun component (0-20) ---
	underrunScore := 20.0
	if h.ReportCount > 0 {
		underrunRate := float64(h.TotalUnderruns) / float64(h.ReportCount)
		if underrunRate > 5 {
			underrunScore = 0
		} else if underrunRate > 0 {
			underrunScore = 20.0 * (1.0 - (underrunRate / 5.0))
		}
	}

	// --- Latency component (0-15) ---
	latencyScore := 15.0
	if h.AvgLatencyMs > 10000 {
		latencyScore = 0
	} else if h.AvgLatencyMs > 1000 {
		latencyScore = 15.0 * (1.0 - ((h.AvgLatencyMs - 1000) / 9000.0))
	}

	// --- Dropped frames component (0-10) ---
	droppedScore := 10.0
	if h.DroppedFps > 10 {
		droppedScore = 0
	} else if h.DroppedFps > 0 {
		droppedScore = 10.0 * (1.0 - (h.DroppedFps / 10.0))
	}

	total := bitrateScore + errorScore + underrunScore + latencyScore + droppedScore
	score := int(math.Round(total))
	if score < 0 {
		score = 0
	}
	if score > 100 {
		score = 100
	}
	return score
}

// checkAlerts evaluates thresholds and appends new alerts if warranted.
// Must be called with m.mu held.
func (m *StreamHealthMonitor) checkAlerts(h StreamHealth) {
	now := time.Now()

	if h.HealthScore < m.thresholds.CriticalScore {
		m.alerts = append(m.alerts, HealthAlert{
			ID:          h.StreamID + "-crit-" + now.Format("150405"),
			StreamID:    h.StreamID,
			ChannelID:   h.ChannelID,
			Level:       "critical",
			Message:     "Stream health is critically low",
			HealthScore: h.HealthScore,
			CreatedAt:   now,
		})
	} else if h.HealthScore < m.thresholds.WarningScore {
		m.alerts = append(m.alerts, HealthAlert{
			ID:          h.StreamID + "-warn-" + now.Format("150405"),
			StreamID:    h.StreamID,
			ChannelID:   h.ChannelID,
			Level:       "warning",
			Message:     "Stream health is degraded",
			HealthScore: h.HealthScore,
			CreatedAt:   now,
		})
	}

	if h.AvgLatencyMs > m.thresholds.MaxLatencyMs {
		m.alerts = append(m.alerts, HealthAlert{
			ID:          h.StreamID + "-lat-" + now.Format("150405"),
			StreamID:    h.StreamID,
			ChannelID:   h.ChannelID,
			Level:       "warning",
			Message:     "Stream latency is high",
			HealthScore: h.HealthScore,
			CreatedAt:   now,
		})
	}

	// Keep only the last 500 alerts to bound memory
	if len(m.alerts) > 500 {
		m.alerts = m.alerts[len(m.alerts)-500:]
	}
}

// GetStreamHealth returns the health state for a single stream.
func (m *StreamHealthMonitor) GetStreamHealth(streamID string) *StreamHealth {
	m.mu.RLock()
	defer m.mu.RUnlock()

	state, ok := m.streams[streamID]
	if !ok {
		return nil
	}
	h := state.health
	h.DurationSeconds = time.Since(h.ConnectedAt).Seconds()
	return &h
}

// GetAllStreams returns a snapshot of all active streams.
func (m *StreamHealthMonitor) GetAllStreams() []StreamHealth {
	m.mu.RLock()
	defer m.mu.RUnlock()

	now := time.Now()
	result := make([]StreamHealth, 0, len(m.streams))
	for _, state := range m.streams {
		h := state.health
		h.DurationSeconds = now.Sub(h.ConnectedAt).Seconds()
		result = append(result, h)
	}
	return result
}

// GetChannelHealth returns aggregate health for all viewers on each channel.
func (m *StreamHealthMonitor) GetChannelHealth() []ChannelHealth {
	m.mu.RLock()
	defer m.mu.RUnlock()

	// Group streams by channel
	channels := make(map[string]*ChannelHealth)
	for _, state := range m.streams {
		h := state.health
		chID := h.ChannelID
		if chID == "" {
			chID = "unknown"
		}
		ch, ok := channels[chID]
		if !ok {
			ch = &ChannelHealth{
				ChannelID:      chID,
				ChannelName:    h.ChannelName,
				MinHealthScore: 100,
				MaxHealthScore: 0,
			}
			channels[chID] = ch
		}
		ch.ActiveViewers++
		ch.TotalErrors += h.TotalErrors
		ch.TotalUnderruns += h.TotalUnderruns
		ch.AvgBitrateKbps += h.AvgBitrateKbps
		ch.AvgLatencyMs += h.AvgLatencyMs
		ch.AvgHealthScore += h.HealthScore
		if h.HealthScore < ch.MinHealthScore {
			ch.MinHealthScore = h.HealthScore
		}
		if h.HealthScore > ch.MaxHealthScore {
			ch.MaxHealthScore = h.HealthScore
		}
	}

	result := make([]ChannelHealth, 0, len(channels))
	for _, ch := range channels {
		if ch.ActiveViewers > 0 {
			ch.AvgBitrateKbps /= float64(ch.ActiveViewers)
			ch.AvgLatencyMs /= float64(ch.ActiveViewers)
			ch.AvgHealthScore /= ch.ActiveViewers
		}
		result = append(result, *ch)
	}
	return result
}

// GetChannelHistory returns the last 1 hour of per-minute snapshots for a channel.
func (m *StreamHealthMonitor) GetChannelHistory(channelID string) []HealthSnapshot {
	m.mu.RLock()
	defer m.mu.RUnlock()

	history, ok := m.channelHistory[channelID]
	if !ok {
		return []HealthSnapshot{}
	}
	// Return a copy
	out := make([]HealthSnapshot, len(history))
	copy(out, history)
	return out
}

// GetAlerts returns all current alerts (last 500).
func (m *StreamHealthMonitor) GetAlerts() []HealthAlert {
	m.mu.RLock()
	defer m.mu.RUnlock()

	// Return only alerts from the last hour
	cutoff := time.Now().Add(-1 * time.Hour)
	result := make([]HealthAlert, 0, len(m.alerts))
	for _, a := range m.alerts {
		if a.CreatedAt.After(cutoff) {
			result = append(result, a)
		}
	}
	return result
}

// GetSummary returns an overall system health summary.
func (m *StreamHealthMonitor) GetSummary() map[string]interface{} {
	m.mu.RLock()
	defer m.mu.RUnlock()

	totalStreams := len(m.streams)
	var totalScore int
	for _, state := range m.streams {
		totalScore += state.health.HealthScore
	}
	avgScore := 0
	if totalStreams > 0 {
		avgScore = totalScore / totalStreams
	}

	// Count recent alerts
	cutoff := time.Now().Add(-1 * time.Hour)
	alertCount := 0
	warningCount := 0
	criticalCount := 0
	for _, a := range m.alerts {
		if a.CreatedAt.After(cutoff) {
			alertCount++
			switch a.Level {
			case "warning":
				warningCount++
			case "critical":
				criticalCount++
			}
		}
	}

	channels := make(map[string]bool)
	for _, state := range m.streams {
		if state.health.ChannelID != "" {
			channels[state.health.ChannelID] = true
		}
	}

	return map[string]interface{}{
		"totalStreams":     totalStreams,
		"totalChannels":   len(channels),
		"avgHealthScore":  avgScore,
		"alertCount":      alertCount,
		"warningCount":    warningCount,
		"criticalCount":   criticalCount,
		"monitorUptime":   time.Now().Format(time.RFC3339),
	}
}

// RemoveStream manually removes a stream (e.g., on disconnect).
func (m *StreamHealthMonitor) RemoveStream(streamID string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	delete(m.streams, streamID)
}

// cleanupLoop periodically removes stale streams (no data for staleTimeout).
func (m *StreamHealthMonitor) cleanupLoop() {
	ticker := time.NewTicker(m.cleanupInterval)
	defer ticker.Stop()

	for {
		select {
		case <-m.stopCh:
			return
		case <-ticker.C:
			m.cleanupStaleStreams()
		}
	}
}

func (m *StreamHealthMonitor) cleanupStaleStreams() {
	m.mu.Lock()
	defer m.mu.Unlock()

	now := time.Now()
	var removed int
	for id, state := range m.streams {
		if now.Sub(state.health.LastReportAt) > m.staleTimeout {
			delete(m.streams, id)
			removed++
		}
	}
	if removed > 0 {
		logger.Infof("Stream health monitor: cleaned up %d stale streams", removed)
	}

	// Trim old alerts
	cutoff := now.Add(-1 * time.Hour)
	newAlerts := make([]HealthAlert, 0, len(m.alerts))
	for _, a := range m.alerts {
		if a.CreatedAt.After(cutoff) {
			newAlerts = append(newAlerts, a)
		}
	}
	m.alerts = newAlerts
}

// snapshotLoop takes per-minute snapshots of channel health for history.
func (m *StreamHealthMonitor) snapshotLoop() {
	ticker := time.NewTicker(m.snapshotInterval)
	defer ticker.Stop()

	for {
		select {
		case <-m.stopCh:
			return
		case <-ticker.C:
			m.takeChannelSnapshots()
		}
	}
}

func (m *StreamHealthMonitor) takeChannelSnapshots() {
	m.mu.Lock()
	defer m.mu.Unlock()

	now := time.Now()
	cutoff := now.Add(-m.historyDuration)

	// Group streams by channel
	type channelAgg struct {
		viewers    int
		totalScore int
		totalBR    float64
		totalErr   int
		totalLat   float64
	}
	channels := make(map[string]*channelAgg)

	for _, state := range m.streams {
		chID := state.health.ChannelID
		if chID == "" {
			continue
		}
		agg, ok := channels[chID]
		if !ok {
			agg = &channelAgg{}
			channels[chID] = agg
		}
		agg.viewers++
		agg.totalScore += state.health.HealthScore
		agg.totalBR += state.health.AvgBitrateKbps
		agg.totalErr += state.health.TotalErrors
		agg.totalLat += state.health.AvgLatencyMs
	}

	for chID, agg := range channels {
		snapshot := HealthSnapshot{
			Timestamp:      now,
			ActiveViewers:  agg.viewers,
			TotalErrors:    agg.totalErr,
		}
		if agg.viewers > 0 {
			snapshot.HealthScore = agg.totalScore / agg.viewers
			snapshot.AvgBitrateKbps = agg.totalBR / float64(agg.viewers)
			snapshot.AvgLatencyMs = agg.totalLat / float64(agg.viewers)
		}

		history := m.channelHistory[chID]
		history = append(history, snapshot)

		// Trim to historyDuration
		trimIdx := 0
		for trimIdx < len(history) && history[trimIdx].Timestamp.Before(cutoff) {
			trimIdx++
		}
		if trimIdx > 0 {
			history = history[trimIdx:]
		}
		m.channelHistory[chID] = history
	}

	// Clean up history for channels with no active streams and old data
	for chID, history := range m.channelHistory {
		if len(history) == 0 {
			delete(m.channelHistory, chID)
			continue
		}
		// Trim old entries
		trimIdx := 0
		for trimIdx < len(history) && history[trimIdx].Timestamp.Before(cutoff) {
			trimIdx++
		}
		if trimIdx > 0 {
			history = history[trimIdx:]
		}
		if len(history) == 0 {
			delete(m.channelHistory, chID)
		} else {
			m.channelHistory[chID] = history
		}
	}
}
