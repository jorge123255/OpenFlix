package metadata

import (
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// Scheduler handles automatic metadata fetching for items missing metadata
type Scheduler struct {
	db        *gorm.DB
	tmdb      *TMDBAgent
	interval  time.Duration
	running   bool
	stopChan  chan struct{}
	mu        sync.Mutex
}

// NewScheduler creates a new metadata scheduler
func NewScheduler(db *gorm.DB, tmdb *TMDBAgent, intervalMinutes int) *Scheduler {
	if intervalMinutes < 1 {
		intervalMinutes = 5 // Default to 5 minutes
	}
	return &Scheduler{
		db:       db,
		tmdb:     tmdb,
		interval: time.Duration(intervalMinutes) * time.Minute,
		stopChan: make(chan struct{}),
	}
}

// Start begins the automatic metadata fetch scheduler
func (s *Scheduler) Start() {
	s.mu.Lock()
	if s.running {
		s.mu.Unlock()
		return
	}
	s.running = true
	s.mu.Unlock()

	logger.Info("Metadata auto-refresh scheduler started")

	// Run immediately on start
	go s.refreshMissingMetadata()

	// Then run on interval
	go func() {
		ticker := time.NewTicker(s.interval)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				s.refreshMissingMetadata()
			case <-s.stopChan:
				logger.Info("Metadata scheduler stopped")
				return
			}
		}
	}()
}

// Stop stops the scheduler
func (s *Scheduler) Stop() {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.running {
		close(s.stopChan)
		s.running = false
	}
}

// refreshMissingMetadata finds and updates items without metadata
func (s *Scheduler) refreshMissingMetadata() {
	if s.tmdb == nil || !s.tmdb.IsConfigured() {
		return
	}

	// Find movies and shows without summary/description - indicates missing metadata
	// VOD items may have posters from Xtream but lack descriptions
	var items []models.MediaItem
	s.db.Where("type IN ? AND (summary IS NULL OR summary = '')", []string{"movie", "show"}).
		Order("added_at DESC").
		Limit(50). // Process 50 at a time to avoid overloading
		Find(&items)

	if len(items) == 0 {
		return
	}

	logger.Infof("Auto-fetching metadata for %d items", len(items))

	for _, item := range items {
		itemCopy := item
		if itemCopy.Type == "movie" {
			if err := s.tmdb.UpdateMovieMetadata(&itemCopy); err != nil {
				logger.Debugf("Failed to fetch metadata for movie %s: %v", itemCopy.Title, err)
			}
		} else if itemCopy.Type == "show" {
			if err := s.tmdb.UpdateShowMetadata(&itemCopy); err != nil {
				logger.Debugf("Failed to fetch metadata for show %s: %v", itemCopy.Title, err)
			}
		}
		// Small delay between requests to be nice to TMDB API
		time.Sleep(250 * time.Millisecond)
	}
}

// SetTMDBAgent updates the TMDB agent (useful when API key changes)
func (s *Scheduler) SetTMDBAgent(tmdb *TMDBAgent) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.tmdb = tmdb
}
