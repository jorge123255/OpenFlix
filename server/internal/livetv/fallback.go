package livetv

import (
	"context"
	"fmt"
	"sort"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// MultiSourceManager manages multiple EPG sources with fallback capability
type MultiSourceManager struct {
	db           *gorm.DB
	sourceHealth map[uint]*SourceHealth
	mutex        sync.RWMutex
}

// SourceHealth tracks the health and reliability of an EPG source
type SourceHealth struct {
	SourceID      uint          `json:"sourceId"`
	SourceName    string        `json:"sourceName"`
	ProviderType  string        `json:"providerType"`
	Priority      int           `json:"priority"`      // Lower is higher priority
	IsHealthy     bool          `json:"isHealthy"`
	LastSuccess   time.Time     `json:"lastSuccess"`
	LastFailure   time.Time     `json:"lastFailure"`
	SuccessCount  int64         `json:"successCount"`
	FailureCount  int64         `json:"failureCount"`
	AvgLatency    time.Duration `json:"avgLatency"`
	ConsecutiveFails int        `json:"consecutiveFails"`
	LastError     string        `json:"lastError,omitempty"`
}

// NewMultiSourceManager creates a new multi-source manager
func NewMultiSourceManager(db *gorm.DB) *MultiSourceManager {
	return &MultiSourceManager{
		db:           db,
		sourceHealth: make(map[uint]*SourceHealth),
	}
}

// InitializeSources loads EPG sources and initializes health tracking
func (m *MultiSourceManager) InitializeSources() error {
	var sources []models.EPGSource
	if err := m.db.Where("enabled = ?", true).Find(&sources).Error; err != nil {
		return fmt.Errorf("failed to load EPG sources: %w", err)
	}

	m.mutex.Lock()
	defer m.mutex.Unlock()

	for i, source := range sources {
		m.sourceHealth[source.ID] = &SourceHealth{
			SourceID:     source.ID,
			SourceName:   source.Name,
			ProviderType: source.ProviderType,
			Priority:     source.Priority,
			IsHealthy:    source.LastError == "",
			LastSuccess:  getTimeFromPtr(source.LastFetched),
		}
		// Default priority based on provider type if not set
		if m.sourceHealth[source.ID].Priority == 0 {
			m.sourceHealth[source.ID].Priority = i + 1
		}
	}

	logger.Log.Infof("MultiSourceManager initialized with %d EPG sources", len(sources))
	return nil
}

// GetHealthySources returns sources sorted by priority, healthy first
func (m *MultiSourceManager) GetHealthySources() []*SourceHealth {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	sources := make([]*SourceHealth, 0, len(m.sourceHealth))
	for _, health := range m.sourceHealth {
		sources = append(sources, health)
	}

	// Sort by: healthy first, then by priority, then by success rate
	sort.Slice(sources, func(i, j int) bool {
		// Healthy sources first
		if sources[i].IsHealthy != sources[j].IsHealthy {
			return sources[i].IsHealthy
		}
		// Then by priority (lower is better)
		if sources[i].Priority != sources[j].Priority {
			return sources[i].Priority < sources[j].Priority
		}
		// Then by success rate
		iRate := m.getSuccessRate(sources[i])
		jRate := m.getSuccessRate(sources[j])
		return iRate > jRate
	})

	return sources
}

// getSuccessRate calculates success rate for a source
func (m *MultiSourceManager) getSuccessRate(health *SourceHealth) float64 {
	total := health.SuccessCount + health.FailureCount
	if total == 0 {
		return 1.0 // Assume good until proven otherwise
	}
	return float64(health.SuccessCount) / float64(total)
}

// RecordSuccess records a successful fetch from a source
func (m *MultiSourceManager) RecordSuccess(sourceID uint, latency time.Duration) {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	health, exists := m.sourceHealth[sourceID]
	if !exists {
		return
	}

	health.LastSuccess = time.Now()
	health.SuccessCount++
	health.ConsecutiveFails = 0
	health.IsHealthy = true
	health.LastError = ""

	// Update average latency
	if health.AvgLatency == 0 {
		health.AvgLatency = latency
	} else {
		health.AvgLatency = (health.AvgLatency + latency) / 2
	}

	// Update source in database
	m.db.Model(&models.EPGSource{}).Where("id = ?", sourceID).Update("last_error", "")
}

// RecordFailure records a failed fetch from a source
func (m *MultiSourceManager) RecordFailure(sourceID uint, err error) {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	health, exists := m.sourceHealth[sourceID]
	if !exists {
		return
	}

	health.LastFailure = time.Now()
	health.FailureCount++
	health.ConsecutiveFails++
	health.LastError = err.Error()

	// Mark unhealthy after 3 consecutive failures
	if health.ConsecutiveFails >= 3 {
		health.IsHealthy = false
		logger.Log.Warnf("EPG source %s marked unhealthy after %d consecutive failures",
			health.SourceName, health.ConsecutiveFails)
	}

	// Update source in database
	m.db.Model(&models.EPGSource{}).Where("id = ?", sourceID).Update("last_error", err.Error())
}

// FetchWithFallback attempts to fetch EPG data, falling back to alternative sources on failure
func (m *MultiSourceManager) FetchWithFallback(ctx context.Context, parser *EPGParser) *FallbackResult {
	result := &FallbackResult{
		Attempts: make([]FetchAttempt, 0),
	}

	sources := m.GetHealthySources()
	if len(sources) == 0 {
		result.Error = fmt.Errorf("no EPG sources available")
		return result
	}

	for _, health := range sources {
		// Skip unhealthy sources unless it's the only option
		if !health.IsHealthy && len(sources) > 1 {
			result.SkippedUnhealthy = append(result.SkippedUnhealthy, health.SourceName)
			continue
		}

		attempt := FetchAttempt{
			SourceID:   health.SourceID,
			SourceName: health.SourceName,
			StartTime:  time.Now(),
		}

		// Fetch source from database
		var source models.EPGSource
		if err := m.db.First(&source, health.SourceID).Error; err != nil {
			attempt.Error = err.Error()
			attempt.Duration = time.Since(attempt.StartTime)
			result.Attempts = append(result.Attempts, attempt)
			m.RecordFailure(health.SourceID, err)
			continue
		}

		// Attempt to refresh this source
		err := parser.RefreshEPGSource(&source)
		attempt.Duration = time.Since(attempt.StartTime)

		if err != nil {
			attempt.Error = err.Error()
			result.Attempts = append(result.Attempts, attempt)
			m.RecordFailure(health.SourceID, err)
			logger.Log.Warnf("EPG fetch failed for %s, trying fallback: %v", health.SourceName, err)
			continue
		}

		// Success!
		attempt.Success = true
		attempt.ProgramsImported = source.ProgramCount
		attempt.ChannelsImported = source.ChannelCount
		result.Attempts = append(result.Attempts, attempt)
		result.Success = true
		result.SuccessSource = health.SourceName

		m.RecordSuccess(health.SourceID, attempt.Duration)
		logger.Log.Infof("EPG fetch succeeded from %s: %d programs, %d channels",
			health.SourceName, source.ProgramCount, source.ChannelCount)
		break
	}

	if !result.Success {
		result.Error = fmt.Errorf("all EPG sources failed")
	}

	return result
}

// FallbackResult contains the result of a fallback fetch operation
type FallbackResult struct {
	Success          bool           `json:"success"`
	SuccessSource    string         `json:"successSource,omitempty"`
	Error            error          `json:"-"`
	ErrorStr         string         `json:"error,omitempty"`
	Attempts         []FetchAttempt `json:"attempts"`
	SkippedUnhealthy []string       `json:"skippedUnhealthy,omitempty"`
}

// FetchAttempt represents a single fetch attempt
type FetchAttempt struct {
	SourceID         uint          `json:"sourceId"`
	SourceName       string        `json:"sourceName"`
	StartTime        time.Time     `json:"startTime"`
	Duration         time.Duration `json:"duration"`
	Success          bool          `json:"success"`
	Error            string        `json:"error,omitempty"`
	ProgramsImported int           `json:"programsImported,omitempty"`
	ChannelsImported int           `json:"channelsImported,omitempty"`
}

// GetSourceHealth returns health info for all sources
func (m *MultiSourceManager) GetSourceHealth() map[uint]*SourceHealth {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	// Return a copy to avoid race conditions
	copy := make(map[uint]*SourceHealth)
	for k, v := range m.sourceHealth {
		healthCopy := *v
		copy[k] = &healthCopy
	}
	return copy
}

// GetSourceStatus returns a summary of source health
func (m *MultiSourceManager) GetSourceStatus() *SourceStatus {
	sources := m.GetHealthySources()

	status := &SourceStatus{
		TotalSources:   len(sources),
		Sources:        sources,
	}

	for _, s := range sources {
		if s.IsHealthy {
			status.HealthySources++
		} else {
			status.UnhealthySources++
		}
	}

	return status
}

// SourceStatus provides an overview of EPG source health
type SourceStatus struct {
	TotalSources     int             `json:"totalSources"`
	HealthySources   int             `json:"healthySources"`
	UnhealthySources int             `json:"unhealthySources"`
	Sources          []*SourceHealth `json:"sources"`
}

// ResetSourceHealth resets the health tracking for a source
func (m *MultiSourceManager) ResetSourceHealth(sourceID uint) {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	if health, exists := m.sourceHealth[sourceID]; exists {
		health.IsHealthy = true
		health.ConsecutiveFails = 0
		health.LastError = ""
		logger.Log.Infof("Reset health for EPG source %s", health.SourceName)
	}
}

// Helper function
func getTimeFromPtr(t *time.Time) time.Time {
	if t == nil {
		return time.Time{}
	}
	return *t
}
