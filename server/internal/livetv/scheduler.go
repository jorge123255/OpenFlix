package livetv

import (
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// EPGScheduler manages automatic EPG refresh
type EPGScheduler struct {
	db              *gorm.DB
	refreshInterval time.Duration
	stopChan        chan struct{}
	running         bool
	mutex           sync.RWMutex
	lastRefresh     time.Time
	refreshCount    int
	errorCount      int
}

// EPGSchedulerConfig holds configuration for the EPG scheduler
type EPGSchedulerConfig struct {
	RefreshInterval int // hours between refreshes (default: 6)
	Enabled         bool
}

// NewEPGScheduler creates a new EPG scheduler
func NewEPGScheduler(db *gorm.DB, config EPGSchedulerConfig) *EPGScheduler {
	interval := time.Duration(config.RefreshInterval) * time.Hour
	if interval < time.Hour {
		interval = 6 * time.Hour // Default to 6 hours
	}

	s := &EPGScheduler{
		db:              db,
		refreshInterval: interval,
		stopChan:        make(chan struct{}),
	}

	if config.Enabled {
		s.Start()
	}

	return s
}

// Start starts the EPG scheduler
func (s *EPGScheduler) Start() {
	s.mutex.Lock()
	if s.running {
		s.mutex.Unlock()
		return
	}
	s.running = true
	s.stopChan = make(chan struct{})
	s.mutex.Unlock()

	go s.scheduleLoop()
	logger.Log.Infof("EPG scheduler started (refresh every %v)", s.refreshInterval)
}

// Stop stops the EPG scheduler
func (s *EPGScheduler) Stop() {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	if !s.running {
		return
	}

	close(s.stopChan)
	s.running = false
	logger.Log.Info("EPG scheduler stopped")
}

// IsRunning returns whether the scheduler is running
func (s *EPGScheduler) IsRunning() bool {
	s.mutex.RLock()
	defer s.mutex.RUnlock()
	return s.running
}

// GetStatus returns scheduler status
func (s *EPGScheduler) GetStatus() map[string]interface{} {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	nextRefresh := s.lastRefresh.Add(s.refreshInterval)
	if s.lastRefresh.IsZero() {
		nextRefresh = time.Now().Add(s.refreshInterval)
	}

	return map[string]interface{}{
		"running":         s.running,
		"refreshInterval": s.refreshInterval.String(),
		"lastRefresh":     s.lastRefresh,
		"nextRefresh":     nextRefresh,
		"refreshCount":    s.refreshCount,
		"errorCount":      s.errorCount,
	}
}

// ForceRefresh triggers an immediate EPG refresh
func (s *EPGScheduler) ForceRefresh() {
	go s.refreshAllEPGSources()
}

// scheduleLoop is the main scheduler loop
func (s *EPGScheduler) scheduleLoop() {
	// Delay initial check to allow server to start up and handle requests
	// Run the initial stale check after 2 minutes to not block startup
	go func() {
		time.Sleep(2 * time.Minute)
		s.checkAndRefreshStale()
	}()

	ticker := time.NewTicker(s.refreshInterval)
	defer ticker.Stop()

	for {
		select {
		case <-s.stopChan:
			return
		case <-ticker.C:
			s.refreshAllEPGSources()
		}
	}
}

// checkAndRefreshStale checks for stale EPG sources and refreshes them
func (s *EPGScheduler) checkAndRefreshStale() {
	staleThreshold := time.Now().Add(-s.refreshInterval)

	var staleSources []models.EPGSource
	s.db.Where("enabled = ? AND (last_fetched IS NULL OR last_fetched < ?)", true, staleThreshold).
		Find(&staleSources)

	if len(staleSources) > 0 {
		logger.Log.Infof("Found %d stale EPG sources, refreshing...", len(staleSources))
		for _, source := range staleSources {
			s.refreshEPGSource(&source)
		}
	}

	// Also check M3U sources with EPG URLs
	var staleM3USources []models.M3USource
	s.db.Where("enabled = ? AND epg_url != '' AND (last_fetched IS NULL OR last_fetched < ?)", true, staleThreshold).
		Find(&staleM3USources)

	if len(staleM3USources) > 0 {
		logger.Log.Infof("Found %d stale M3U sources with EPG, refreshing...", len(staleM3USources))
		for _, source := range staleM3USources {
			s.refreshM3USourceEPG(&source)
		}
	}
}

// refreshAllEPGSources refreshes all enabled EPG sources
func (s *EPGScheduler) refreshAllEPGSources() {
	s.mutex.Lock()
	s.lastRefresh = time.Now()
	s.mutex.Unlock()

	logger.Log.Info("Starting scheduled EPG refresh")

	// Refresh standalone EPG sources
	var epgSources []models.EPGSource
	s.db.Where("enabled = ?", true).Find(&epgSources)

	for _, source := range epgSources {
		s.refreshEPGSource(&source)
	}

	// Refresh M3U sources with EPG URLs
	var m3uSources []models.M3USource
	s.db.Where("enabled = ? AND epg_url != ''", true).Find(&m3uSources)

	for _, source := range m3uSources {
		s.refreshM3USourceEPG(&source)
	}

	logger.Log.Infof("Scheduled EPG refresh completed: %d EPG sources, %d M3U sources", len(epgSources), len(m3uSources))
}

// refreshEPGSource refreshes a single EPG source
func (s *EPGScheduler) refreshEPGSource(source *models.EPGSource) {
	logger.Log.Debugf("Refreshing EPG source: %s (ID: %d)", source.Name, source.ID)

	var err error

	switch source.ProviderType {
	case "xmltv":
		if source.URL != "" {
			parser := NewEPGParser(s.db)
			err = parser.RefreshEPGSource(source)
		}
	case "gracenote":
		// Refresh Gracenote source using browser client
		if source.GracenoteAffiliate != "" && source.GracenotePostalCode != "" {
			logger.Log.Infof("Refreshing Gracenote source %s via browser", source.Name)
			err = s.refreshGracenoteSource(source)
		} else {
			logger.Log.Debugf("Skipping Gracenote source %s (missing affiliate or postal code)", source.Name)
			return
		}
	}

	if err != nil {
		s.mutex.Lock()
		s.errorCount++
		s.mutex.Unlock()

		source.LastError = err.Error()
		s.db.Save(source)
		logger.Log.Warnf("Failed to refresh EPG source %s: %v", source.Name, err)
		return
	}

	s.mutex.Lock()
	s.refreshCount++
	s.mutex.Unlock()

	// Count programs for this source
	var programCount int64
	s.db.Model(&models.Program{}).Count(&programCount)

	now := time.Now()
	source.LastFetched = &now
	source.LastError = ""
	source.ProgramCount = int(programCount)
	s.db.Save(source)

	logger.Log.Infof("Refreshed EPG source %s", source.Name)
}

// refreshGracenoteSource refreshes a Gracenote EPG source
func (s *EPGScheduler) refreshGracenoteSource(source *models.EPGSource) error {
	// Use the EPGParser which already has Gracenote support via ImportProgramsFromGracenote
	parser := NewEPGParser(s.db)
	return parser.RefreshEPGSource(source)
}

// refreshM3USourceEPG refreshes EPG for an M3U source
func (s *EPGScheduler) refreshM3USourceEPG(source *models.M3USource) {
	if source.EPGUrl == "" {
		return
	}

	logger.Log.Debugf("Refreshing EPG for M3U source: %s (ID: %d)", source.Name, source.ID)

	parser := NewEPGParser(s.db)
	err := parser.RefreshEPG(source)

	if err != nil {
		s.mutex.Lock()
		s.errorCount++
		s.mutex.Unlock()
		logger.Log.Warnf("Failed to refresh EPG for M3U source %s: %v", source.Name, err)
		return
	}

	s.mutex.Lock()
	s.refreshCount++
	s.mutex.Unlock()

	now := time.Now()
	source.LastFetched = &now
	s.db.Save(source)

	logger.Log.Infof("Refreshed EPG for M3U source %s", source.Name)
}
