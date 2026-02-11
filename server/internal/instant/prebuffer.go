package instant

import (
	"context"
	"io"
	"net/http"
	"sync"
	"time"
)

// StreamURLResolver resolves channel IDs to stream URLs
type StreamURLResolver func(channelID string) string

// AdjacentChannelResolver gets adjacent channels for a given channel
type AdjacentChannelResolver func(channelID string) []string

// PrebufferManager maintains background streams for instant channel switching
type PrebufferManager struct {
	mu                sync.RWMutex
	activeChannel     string
	cachedStreams     map[string]*CachedStream
	favorites         []string
	recentChannels    []string
	maxCached         int
	maxMemoryMB       int
	client            *http.Client
	predictor         *ChannelPredictor
	ctx               context.Context
	cancel            context.CancelFunc
	streamURLResolver StreamURLResolver
	adjacentResolver  AdjacentChannelResolver
}

// CachedStream holds a pre-buffered stream ready for instant playback
type CachedStream struct {
	ChannelID  string
	StreamURL  string
	Buffer     *RingBuffer
	LastAccess time.Time
	IsLive     bool
	cancel     context.CancelFunc
	mu         sync.RWMutex
}

// NewPrebufferManager creates a new pre-buffer manager
func NewPrebufferManager(maxCached, maxMemoryMB int, dataDir string) *PrebufferManager {
	ctx, cancel := context.WithCancel(context.Background())

	pm := &PrebufferManager{
		cachedStreams:  make(map[string]*CachedStream),
		recentChannels: make([]string, 0, 10),
		maxCached:      maxCached,   // typically 5-6 streams
		maxMemoryMB:    maxMemoryMB, // typically 500MB
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
		predictor: NewChannelPredictor(dataDir),
		ctx:       ctx,
		cancel:    cancel,
	}

	// Start background maintenance
	go pm.maintenanceLoop()

	return pm
}

// SetStreamURLResolver sets the function to resolve channel IDs to stream URLs
func (pm *PrebufferManager) SetStreamURLResolver(resolver StreamURLResolver) {
	pm.mu.Lock()
	defer pm.mu.Unlock()
	pm.streamURLResolver = resolver
}

// SetAdjacentChannelResolver sets the function to get adjacent channels
func (pm *PrebufferManager) SetAdjacentChannelResolver(resolver AdjacentChannelResolver) {
	pm.mu.Lock()
	defer pm.mu.Unlock()
	pm.adjacentResolver = resolver
}

// SetActiveChannel updates the current channel and triggers pre-buffering
func (pm *PrebufferManager) SetActiveChannel(channelID string) {
	pm.mu.Lock()
	defer pm.mu.Unlock()

	// Track channel switch for prediction
	if pm.activeChannel != "" {
		pm.predictor.RecordSwitch(pm.activeChannel, channelID)
	}

	pm.activeChannel = channelID

	// Update recent channels (keep last 5)
	pm.addToRecent(channelID)

	// Trigger pre-buffering in background
	go pm.updatePrebuffer()
}

// GetCachedStream returns a pre-buffered stream if available
func (pm *PrebufferManager) GetCachedStream(channelID string) (*CachedStream, bool) {
	pm.mu.RLock()
	defer pm.mu.RUnlock()

	stream, exists := pm.cachedStreams[channelID]
	if exists && stream.IsLive && stream.Buffer.Len() > 0 {
		stream.LastAccess = time.Now()
		return stream, true
	}
	return nil, false
}

// SetFavorites updates the list of favorite channels to keep warm
func (pm *PrebufferManager) SetFavorites(channelIDs []string) {
	pm.mu.Lock()
	pm.favorites = channelIDs
	pm.mu.Unlock()

	go pm.updatePrebuffer()
}

// updatePrebuffer determines which channels to pre-buffer
func (pm *PrebufferManager) updatePrebuffer() {
	pm.mu.Lock()
	defer pm.mu.Unlock()

	// Build priority list of channels to cache
	toCache := make(map[string]int) // channelID -> priority

	// Priority 1: Adjacent channels (if we know channel numbers)
	if pm.activeChannel != "" && pm.adjacentResolver != nil {
		adjacent := pm.adjacentResolver(pm.activeChannel)
		for _, ch := range adjacent {
			toCache[ch] = 100
		}
	}

	// Priority 2: Predicted next channels
	if pm.activeChannel != "" {
		predicted := pm.predictor.PredictNext(pm.activeChannel, 3)
		for i, ch := range predicted {
			if _, exists := toCache[ch]; !exists {
				toCache[ch] = 80 - (i * 10)
			}
		}
	}

	// Priority 3: Recent channels
	for i, ch := range pm.recentChannels {
		if ch != pm.activeChannel {
			if _, exists := toCache[ch]; !exists {
				toCache[ch] = 60 - (i * 5)
			}
		}
	}

	// Priority 4: Favorites
	for i, ch := range pm.favorites {
		if _, exists := toCache[ch]; !exists {
			toCache[ch] = 40 - (i * 5)
		}
	}

	// Sort by priority and limit to maxCached
	selected := pm.selectTopChannels(toCache, pm.maxCached)

	// Stop streams that are no longer needed
	for channelID, stream := range pm.cachedStreams {
		if !contains(selected, channelID) && channelID != pm.activeChannel {
			stream.Stop()
			delete(pm.cachedStreams, channelID)
		}
	}

	// Start new streams
	for _, channelID := range selected {
		if _, exists := pm.cachedStreams[channelID]; !exists {
			pm.startPrebuffer(channelID)
		}
	}
}

// startPrebuffer begins background buffering for a channel
func (pm *PrebufferManager) startPrebuffer(channelID string) {
	if pm.streamURLResolver == nil {
		return
	}

	// Get stream URL for channel
	streamURL := pm.streamURLResolver(channelID)
	if streamURL == "" {
		return
	}

	ctx, cancel := context.WithCancel(pm.ctx)

	stream := &CachedStream{
		ChannelID:  channelID,
		StreamURL:  streamURL,
		Buffer:     NewRingBuffer(10 * 1024 * 1024), // 10MB per stream
		LastAccess: time.Now(),
		IsLive:     true,
		cancel:     cancel,
	}

	pm.cachedStreams[channelID] = stream

	// Start background fetching
	go stream.fetchLoop(ctx, pm.client)
}

// addToRecent adds a channel to recent list
func (pm *PrebufferManager) addToRecent(channelID string) {
	// Remove if already in list
	for i, ch := range pm.recentChannels {
		if ch == channelID {
			pm.recentChannels = append(pm.recentChannels[:i], pm.recentChannels[i+1:]...)
			break
		}
	}

	// Add to front
	pm.recentChannels = append([]string{channelID}, pm.recentChannels...)

	// Trim to 10
	if len(pm.recentChannels) > 10 {
		pm.recentChannels = pm.recentChannels[:10]
	}
}

// selectTopChannels returns top N channels by priority
func (pm *PrebufferManager) selectTopChannels(priorities map[string]int, n int) []string {
	type kv struct {
		k string
		v int
	}

	var sorted []kv
	for k, v := range priorities {
		sorted = append(sorted, kv{k, v})
	}

	// Sort by priority descending
	for i := 0; i < len(sorted)-1; i++ {
		for j := i + 1; j < len(sorted); j++ {
			if sorted[j].v > sorted[i].v {
				sorted[i], sorted[j] = sorted[j], sorted[i]
			}
		}
	}

	result := make([]string, 0, n)
	for i := 0; i < len(sorted) && i < n; i++ {
		result = append(result, sorted[i].k)
	}

	return result
}

// maintenanceLoop periodically cleans up stale streams
func (pm *PrebufferManager) maintenanceLoop() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-pm.ctx.Done():
			return
		case <-ticker.C:
			pm.cleanup()
		}
	}
}

// cleanup removes stale streams
func (pm *PrebufferManager) cleanup() {
	pm.mu.Lock()
	defer pm.mu.Unlock()

	staleThreshold := time.Now().Add(-5 * time.Minute)

	for channelID, stream := range pm.cachedStreams {
		if channelID != pm.activeChannel && stream.LastAccess.Before(staleThreshold) {
			stream.Stop()
			delete(pm.cachedStreams, channelID)
		}
	}
}

// Stop shuts down the pre-buffer manager
func (pm *PrebufferManager) Stop() {
	pm.cancel()

	pm.mu.Lock()
	defer pm.mu.Unlock()

	for _, stream := range pm.cachedStreams {
		stream.Stop()
	}
	pm.cachedStreams = make(map[string]*CachedStream)
}

// Stats returns current pre-buffer statistics
func (pm *PrebufferManager) Stats() map[string]interface{} {
	pm.mu.RLock()
	defer pm.mu.RUnlock()

	streams := make([]map[string]interface{}, 0)
	totalMemory := 0

	for _, stream := range pm.cachedStreams {
		bufLen := stream.Buffer.Len()
		totalMemory += bufLen
		streams = append(streams, map[string]interface{}{
			"channel_id":  stream.ChannelID,
			"buffer_size": bufLen,
			"is_live":     stream.IsLive,
			"last_access": stream.LastAccess,
		})
	}

	return map[string]interface{}{
		"active_channel":  pm.activeChannel,
		"cached_streams":  len(pm.cachedStreams),
		"total_memory_mb": totalMemory / (1024 * 1024),
		"streams":         streams,
		"recent_channels": pm.recentChannels,
	}
}

// CachedStream methods

// Stop halts the stream fetching
func (cs *CachedStream) Stop() {
	cs.mu.Lock()
	defer cs.mu.Unlock()

	cs.IsLive = false
	if cs.cancel != nil {
		cs.cancel()
	}
}

// fetchLoop continuously fetches stream data
func (cs *CachedStream) fetchLoop(ctx context.Context, client *http.Client) {
	fetcher := NewHLSFetcher()
	lastSequence := 0

	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			segments, err := fetcher.FetchPlaylist(ctx, cs.StreamURL)
			if err != nil {
				continue
			}

			for _, seg := range segments {
				if seg.Sequence > lastSequence {
					data, err := fetcher.FetchSegment(ctx, seg)
					if err != nil {
						continue
					}

					cs.Buffer.WriteSegment(
						seg.URL,
						data,
						time.Now().Unix(),
						seg.Duration,
					)
					lastSequence = seg.Sequence
				}
			}
		}
	}
}

// Read implements io.Reader for the cached stream
func (cs *CachedStream) Read(p []byte) (n int, err error) {
	cs.mu.RLock()
	defer cs.mu.RUnlock()

	if !cs.IsLive {
		return 0, io.EOF
	}

	return cs.Buffer.Read(p)
}

// Helper function
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
