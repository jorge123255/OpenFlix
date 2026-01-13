package livetv

import (
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/metadata"
	"github.com/openflix/openflix-server/internal/models"
	log "github.com/sirupsen/logrus"
	"gorm.io/gorm"
)

const (
	tmdbImageURL = "https://image.tmdb.org/t/p"
)

// EPGEnricher enriches EPG programs with TMDB artwork
type EPGEnricher struct {
	db        *gorm.DB
	tmdb      *metadata.TMDBAgent
	cache     map[string]string // title -> poster URL cache
	cacheMu   sync.RWMutex
	rateLimit chan struct{} // Rate limiter for TMDB API
	stopCh    chan struct{} // Stop channel for background enrichment
	running   bool
	runningMu sync.Mutex
}

// NewEPGEnricher creates a new EPG enricher
func NewEPGEnricher(db *gorm.DB, tmdb *metadata.TMDBAgent) *EPGEnricher {
	return &EPGEnricher{
		db:        db,
		tmdb:      tmdb,
		cache:     make(map[string]string),
		rateLimit: make(chan struct{}, 5), // Max 5 concurrent requests
		stopCh:    make(chan struct{}),
	}
}

// EnrichPrograms enriches programs in a time range with TMDB artwork
func (e *EPGEnricher) EnrichPrograms(start, end time.Time, limit int) (int, error) {
	if e.tmdb == nil || !e.tmdb.IsConfigured() {
		return 0, fmt.Errorf("TMDB not configured")
	}

	// Find programs without artwork in the time range
	var programs []models.Program
	query := e.db.Where("start >= ? AND start < ? AND (icon IS NULL OR icon = '')", start, end).
		Order("start ASC")

	if limit > 0 {
		query = query.Limit(limit)
	}

	if err := query.Find(&programs).Error; err != nil {
		return 0, err
	}

	log.WithField("count", len(programs)).Info("Found programs to enrich")

	enriched := 0
	for _, p := range programs {
		if err := e.enrichProgram(&p); err != nil {
			log.WithError(err).WithField("title", p.Title).Debug("Failed to enrich program")
			continue
		}
		enriched++

		// Rate limiting - small delay between requests
		time.Sleep(100 * time.Millisecond)
	}

	return enriched, nil
}

// enrichProgram enriches a single program with TMDB artwork
func (e *EPGEnricher) enrichProgram(p *models.Program) error {
	// Skip sports, news, and content that won't be in TMDB
	if p.IsSports || p.IsNews {
		return nil
	}

	// Generate cache key from title (normalized)
	cacheKey := e.normalizeTitle(p.Title)

	// Check cache first
	e.cacheMu.RLock()
	if cachedURL, ok := e.cache[cacheKey]; ok {
		e.cacheMu.RUnlock()
		if cachedURL != "" {
			return e.updateProgramArtwork(p, cachedURL, "")
		}
		return nil // Cache says no result
	}
	e.cacheMu.RUnlock()

	// Rate limit
	e.rateLimit <- struct{}{}
	defer func() { <-e.rateLimit }()

	var posterURL, backdropURL string

	if p.IsMovie {
		// Search for movie
		result, err := e.tmdb.SearchMovie(p.Title, 0)
		if err != nil {
			e.cacheResult(cacheKey, "") // Cache the miss
			return err
		}

		if result.PosterPath != "" {
			posterURL = fmt.Sprintf("%s/w300%s", tmdbImageURL, result.PosterPath)
		}
		if result.BackdropPath != "" {
			backdropURL = fmt.Sprintf("%s/w780%s", tmdbImageURL, result.BackdropPath)
		}
	} else {
		// Search for TV show
		result, err := e.tmdb.SearchTV(p.Title, 0)
		if err != nil {
			e.cacheResult(cacheKey, "") // Cache the miss
			return err
		}

		if result.PosterPath != "" {
			posterURL = fmt.Sprintf("%s/w300%s", tmdbImageURL, result.PosterPath)
		}
		if result.BackdropPath != "" {
			backdropURL = fmt.Sprintf("%s/w780%s", tmdbImageURL, result.BackdropPath)
		}
	}

	// Cache the result
	e.cacheResult(cacheKey, posterURL)

	if posterURL == "" && backdropURL == "" {
		return nil
	}

	return e.updateProgramArtwork(p, posterURL, backdropURL)
}

// updateProgramArtwork updates all programs with the same title
func (e *EPGEnricher) updateProgramArtwork(p *models.Program, icon, art string) error {
	updates := map[string]interface{}{}
	if icon != "" {
		updates["icon"] = icon
	}
	if art != "" {
		updates["art"] = art
	}

	if len(updates) == 0 {
		return nil
	}

	// Update ALL programs with this title (batch update)
	result := e.db.Model(&models.Program{}).
		Where("title = ? AND (icon IS NULL OR icon = '')", p.Title).
		Updates(updates)

	if result.Error != nil {
		return result.Error
	}

	if result.RowsAffected > 1 {
		log.WithFields(log.Fields{
			"title":   p.Title,
			"updated": result.RowsAffected,
		}).Debug("Batch updated programs with same title")
	}

	return nil
}

// normalizeTitle normalizes a title for caching
func (e *EPGEnricher) normalizeTitle(title string) string {
	// Remove common suffixes and prefixes
	title = strings.ToLower(title)
	title = strings.TrimSpace(title)

	// Remove year suffixes like "(2024)"
	if idx := strings.LastIndex(title, "("); idx > 0 {
		title = strings.TrimSpace(title[:idx])
	}

	// Remove "new:" prefix
	title = strings.TrimPrefix(title, "new: ")
	title = strings.TrimPrefix(title, "new:")

	return title
}

// cacheResult caches a TMDB lookup result
func (e *EPGEnricher) cacheResult(key, url string) {
	e.cacheMu.Lock()
	defer e.cacheMu.Unlock()
	e.cache[key] = url
}

// EnrichAllFuturePrograms enriches all future programs (background job)
func (e *EPGEnricher) EnrichAllFuturePrograms() {
	if e.tmdb == nil || !e.tmdb.IsConfigured() {
		log.Warn("TMDB not configured, skipping EPG enrichment")
		return
	}

	start := time.Now()
	end := start.Add(7 * 24 * time.Hour) // Next 7 days

	enriched, err := e.EnrichPrograms(start, end, 500) // Limit to 500 per run
	if err != nil {
		log.WithError(err).Error("Failed to enrich EPG programs")
		return
	}

	log.WithField("enriched", enriched).Info("EPG enrichment completed")
}

// StartBackgroundEnrichment starts a background goroutine that continuously enriches programs
func (e *EPGEnricher) StartBackgroundEnrichment() {
	e.runningMu.Lock()
	if e.running {
		e.runningMu.Unlock()
		return
	}
	e.running = true
	e.runningMu.Unlock()

	go func() {
		// Wait 30 seconds before starting (let other services initialize)
		time.Sleep(30 * time.Second)

		log.Info("Starting background EPG enrichment scheduler")

		// Run immediately on start
		e.runEnrichmentCycle()

		// Then run every 30 minutes
		ticker := time.NewTicker(30 * time.Minute)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				e.runEnrichmentCycle()
			case <-e.stopCh:
				log.Info("Stopping background EPG enrichment")
				return
			}
		}
	}()
}

// runEnrichmentCycle runs a single enrichment cycle
func (e *EPGEnricher) runEnrichmentCycle() {
	if e.tmdb == nil || !e.tmdb.IsConfigured() {
		return
	}

	start := time.Now()
	end := start.Add(7 * 24 * time.Hour)

	// Count unique titles without artwork
	var count int64
	e.db.Model(&models.Program{}).
		Where("start >= ? AND start < ? AND (icon IS NULL OR icon = '') AND is_sports = 0 AND is_news = 0", start, end).
		Distinct("title").
		Count(&count)

	if count == 0 {
		log.Debug("No programs need enrichment")
		return
	}

	log.WithField("unique_titles", count).Info("Starting EPG enrichment cycle")

	// Process up to 200 unique titles per cycle (each will batch update all programs with same title)
	enriched, err := e.EnrichPrograms(start, end, 200)
	if err != nil {
		log.WithError(err).Error("EPG enrichment cycle failed")
		return
	}

	log.WithField("enriched", enriched).Info("EPG enrichment cycle completed")
}

// StopBackgroundEnrichment stops the background enrichment
func (e *EPGEnricher) StopBackgroundEnrichment() {
	e.runningMu.Lock()
	defer e.runningMu.Unlock()
	if e.running {
		close(e.stopCh)
		e.running = false
	}
}

// GetCacheStats returns cache statistics
func (e *EPGEnricher) GetCacheStats() (size int, hits int) {
	e.cacheMu.RLock()
	defer e.cacheMu.RUnlock()
	return len(e.cache), 0
}
