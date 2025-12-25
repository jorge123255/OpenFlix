package gracenote

import (
	"encoding/json"
	"sync"
	"time"
)

// cacheEntry represents a single cache entry with expiration
type cacheEntry struct {
	data      []byte
	expiresAt time.Time
}

// Cache provides in-memory caching for EPG data
type Cache struct {
	mu      sync.RWMutex
	entries map[string]*cacheEntry
	ttl     time.Duration
	lastClean time.Time
}

// NewCache creates a new cache with the specified TTL
func NewCache(ttl time.Duration) *Cache {
	c := &Cache{
		entries:   make(map[string]*cacheEntry),
		ttl:       ttl,
		lastClean: time.Now(),
	}

	// Start cleanup goroutine
	go c.cleanupLoop()

	return c
}

// Get retrieves a value from the cache and unmarshals it into v
func (c *Cache) Get(key string, v interface{}) (bool, error) {
	c.mu.RLock()
	entry, exists := c.entries[key]
	c.mu.RUnlock()

	if !exists {
		return false, nil
	}

	// Check if expired
	if time.Now().After(entry.expiresAt) {
		c.mu.Lock()
		delete(c.entries, key)
		c.mu.Unlock()
		return false, nil
	}

	// Unmarshal data
	if err := json.Unmarshal(entry.data, v); err != nil {
		return false, err
	}

	return true, nil
}

// Set stores a value in the cache
func (c *Cache) Set(key string, v interface{}) error {
	// Marshal data
	data, err := json.Marshal(v)
	if err != nil {
		return err
	}

	c.mu.Lock()
	c.entries[key] = &cacheEntry{
		data:      data,
		expiresAt: time.Now().Add(c.ttl),
	}
	c.mu.Unlock()

	return nil
}

// Clear removes all entries from the cache
func (c *Cache) Clear() {
	c.mu.Lock()
	c.entries = make(map[string]*cacheEntry)
	c.mu.Unlock()
}

// Stats returns cache statistics
func (c *Cache) Stats() CacheStats {
	c.mu.RLock()
	defer c.mu.RUnlock()

	return CacheStats{
		Entries:   len(c.entries),
		LastClean: c.lastClean,
	}
}

// cleanupLoop periodically removes expired entries
func (c *Cache) cleanupLoop() {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for range ticker.C {
		c.cleanup()
	}
}

// cleanup removes expired entries
func (c *Cache) cleanup() {
	now := time.Now()
	c.mu.Lock()
	defer c.mu.Unlock()

	for key, entry := range c.entries {
		if now.After(entry.expiresAt) {
			delete(c.entries, key)
		}
	}

	c.lastClean = now
}
