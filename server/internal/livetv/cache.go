package livetv

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// GuideCache provides caching for EPG guide queries
type GuideCache struct {
	cache    map[string]*cacheEntry
	mutex    sync.RWMutex
	ttl      time.Duration
	maxItems int
	hits     int64
	misses   int64
}

type cacheEntry struct {
	data      interface{}
	expiresAt time.Time
}

// NewGuideCache creates a new guide cache
func NewGuideCache(ttl time.Duration, maxItems int) *GuideCache {
	if ttl == 0 {
		ttl = 5 * time.Minute // Default 5 minute cache
	}
	if maxItems == 0 {
		maxItems = 1000
	}

	c := &GuideCache{
		cache:    make(map[string]*cacheEntry),
		ttl:      ttl,
		maxItems: maxItems,
	}

	// Start cleanup goroutine
	go c.cleanupLoop()

	return c
}

// Get retrieves an item from the cache
func (c *GuideCache) Get(key string) (interface{}, bool) {
	c.mutex.RLock()
	entry, exists := c.cache[key]
	c.mutex.RUnlock()

	if !exists {
		c.mutex.Lock()
		c.misses++
		c.mutex.Unlock()
		return nil, false
	}

	if time.Now().After(entry.expiresAt) {
		c.mutex.Lock()
		delete(c.cache, key)
		c.misses++
		c.mutex.Unlock()
		return nil, false
	}

	c.mutex.Lock()
	c.hits++
	c.mutex.Unlock()

	return entry.data, true
}

// Set stores an item in the cache
func (c *GuideCache) Set(key string, data interface{}) {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	// Evict oldest entries if at capacity
	if len(c.cache) >= c.maxItems {
		c.evictOldest()
	}

	c.cache[key] = &cacheEntry{
		data:      data,
		expiresAt: time.Now().Add(c.ttl),
	}
}

// Invalidate removes a specific key from the cache
func (c *GuideCache) Invalidate(key string) {
	c.mutex.Lock()
	defer c.mutex.Unlock()
	delete(c.cache, key)
}

// InvalidateAll clears the entire cache
func (c *GuideCache) InvalidateAll() {
	c.mutex.Lock()
	defer c.mutex.Unlock()
	c.cache = make(map[string]*cacheEntry)
	logger.Log.Debug("Guide cache invalidated")
}

// Stats returns cache statistics
func (c *GuideCache) Stats() map[string]interface{} {
	c.mutex.RLock()
	defer c.mutex.RUnlock()

	hitRate := float64(0)
	total := c.hits + c.misses
	if total > 0 {
		hitRate = float64(c.hits) / float64(total) * 100
	}

	return map[string]interface{}{
		"items":    len(c.cache),
		"maxItems": c.maxItems,
		"ttl":      c.ttl.String(),
		"hits":     c.hits,
		"misses":   c.misses,
		"hitRate":  hitRate,
	}
}

// GenerateKey creates a cache key from query parameters
func (c *GuideCache) GenerateKey(prefix string, params ...interface{}) string {
	data, _ := json.Marshal(params)
	hash := sha256.Sum256(data)
	return prefix + ":" + hex.EncodeToString(hash[:8])
}

// evictOldest removes the oldest 10% of entries
func (c *GuideCache) evictOldest() {
	toEvict := len(c.cache) / 10
	if toEvict < 1 {
		toEvict = 1
	}

	// Find oldest entries
	var oldest []string
	var oldestTime time.Time

	for key, entry := range c.cache {
		if oldestTime.IsZero() || entry.expiresAt.Before(oldestTime) {
			oldest = append([]string{key}, oldest...)
			oldestTime = entry.expiresAt
			if len(oldest) > toEvict {
				oldest = oldest[:toEvict]
			}
		}
	}

	for _, key := range oldest {
		delete(c.cache, key)
	}
}

// cleanupLoop periodically removes expired entries
func (c *GuideCache) cleanupLoop() {
	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		c.cleanup()
	}
}

// cleanup removes expired entries
func (c *GuideCache) cleanup() {
	c.mutex.Lock()
	defer c.mutex.Unlock()

	now := time.Now()
	expired := 0

	for key, entry := range c.cache {
		if now.After(entry.expiresAt) {
			delete(c.cache, key)
			expired++
		}
	}

	if expired > 0 {
		logger.Log.Debugf("Guide cache cleanup: removed %d expired entries", expired)
	}
}
