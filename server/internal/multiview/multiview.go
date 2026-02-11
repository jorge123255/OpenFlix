package multiview

import (
	"sync"
	"time"
)

// Layout types for multiview
type Layout string

const (
	LayoutPiP    Layout = "pip"
	LayoutSplit2 Layout = "split2"
	LayoutSplit3 Layout = "split3"
	LayoutSplit4 Layout = "split4"
	LayoutMosaic Layout = "mosaic"
)

// StreamSlot represents one stream in multiview
type StreamSlot struct {
	Index     int    `json:"index"`
	ChannelID string `json:"channel_id"`
	StreamURL string `json:"stream_url"`
	Active    bool   `json:"active"`
	AudioOn   bool   `json:"audio_on"`
}

// MultiviewSession represents an active multiview session
type MultiviewSession struct {
	ID        string       `json:"id"`
	UserID    string       `json:"user_id"`
	Layout    Layout       `json:"layout"`
	Slots     []StreamSlot `json:"slots"`
	CreatedAt time.Time    `json:"created_at"`
	UpdatedAt time.Time    `json:"updated_at"`
	mu        sync.RWMutex
}

// StreamGetter is a function that gets stream URL for a channel
type StreamGetter func(channelID string) (string, error)

// MultiviewManager manages multiview sessions
type MultiviewManager struct {
	sessions     map[string]*MultiviewSession
	dvr          *MultiviewDVR
	mu           sync.RWMutex
	maxStreams   int
	streamGetter StreamGetter
}

// NewMultiviewManager creates a new multiview manager
func NewMultiviewManager(maxStreams int, streamGetter StreamGetter) *MultiviewManager {
	return &MultiviewManager{
		sessions:     make(map[string]*MultiviewSession),
		dvr:          NewMultiviewDVR(30), // 30 minute buffer
		maxStreams:   maxStreams,
		streamGetter: streamGetter,
	}
}

// CreateSession creates a new multiview session
func (m *MultiviewManager) CreateSession(userID string) (*MultiviewSession, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	sessionID := generateSessionID()
	session := &MultiviewSession{
		ID:        sessionID,
		UserID:    userID,
		Layout:    LayoutSplit2,
		Slots:     make([]StreamSlot, 0),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	m.sessions[sessionID] = session
	return session, nil
}

// GetSession retrieves a session by ID
func (m *MultiviewManager) GetSession(sessionID string) *MultiviewSession {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.sessions[sessionID]
}

// DeleteSession removes a session
func (m *MultiviewManager) DeleteSession(sessionID string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if session, ok := m.sessions[sessionID]; ok {
		// Clean up DVR buffers for all slots
		for _, slot := range session.Slots {
			m.dvr.RemoveStream(slot.ChannelID)
		}
		delete(m.sessions, sessionID)
	}
}

// AddStream adds a stream to a session
func (m *MultiviewManager) AddStream(sessionID, channelID string) (*StreamSlot, error) {
	session := m.GetSession(sessionID)
	if session == nil {
		return nil, nil
	}

	session.mu.Lock()
	defer session.mu.Unlock()

	// Check max streams
	if len(session.Slots) >= m.maxStreams {
		return nil, nil
	}

	// Get stream URL
	streamURL := ""
	if m.streamGetter != nil {
		url, err := m.streamGetter(channelID)
		if err == nil {
			streamURL = url
		}
	}

	slot := StreamSlot{
		Index:     len(session.Slots),
		ChannelID: channelID,
		StreamURL: streamURL,
		Active:    true,
		AudioOn:   len(session.Slots) == 0, // First slot has audio
	}

	session.Slots = append(session.Slots, slot)
	session.UpdatedAt = time.Now()

	// Initialize DVR buffer for this stream
	m.dvr.AddStream(channelID, 64) // 64MB buffer per stream

	return &slot, nil
}

// RemoveStream removes a stream from a session
func (m *MultiviewManager) RemoveStream(sessionID, channelID string) {
	session := m.GetSession(sessionID)
	if session == nil {
		return
	}

	session.mu.Lock()
	defer session.mu.Unlock()

	newSlots := make([]StreamSlot, 0)
	for _, slot := range session.Slots {
		if slot.ChannelID != channelID {
			slot.Index = len(newSlots)
			newSlots = append(newSlots, slot)
		}
	}

	session.Slots = newSlots
	session.UpdatedAt = time.Now()

	// Remove DVR buffer
	m.dvr.RemoveStream(channelID)
}

// SetLayout changes the layout of a session
func (m *MultiviewManager) SetLayout(sessionID string, layout Layout) {
	session := m.GetSession(sessionID)
	if session == nil {
		return
	}

	session.mu.Lock()
	defer session.mu.Unlock()

	session.Layout = layout
	session.UpdatedAt = time.Now()
}

// SetAudioFocus sets which slot has audio
func (m *MultiviewManager) SetAudioFocus(sessionID string, slotIndex int) {
	session := m.GetSession(sessionID)
	if session == nil {
		return
	}

	session.mu.Lock()
	defer session.mu.Unlock()

	for i := range session.Slots {
		session.Slots[i].AudioOn = (i == slotIndex)
	}
	session.UpdatedAt = time.Now()
}

// SwapSlots swaps two slots in a session
func (m *MultiviewManager) SwapSlots(sessionID string, index1, index2 int) {
	session := m.GetSession(sessionID)
	if session == nil {
		return
	}

	session.mu.Lock()
	defer session.mu.Unlock()

	if index1 < 0 || index1 >= len(session.Slots) ||
		index2 < 0 || index2 >= len(session.Slots) {
		return
	}

	session.Slots[index1], session.Slots[index2] = session.Slots[index2], session.Slots[index1]
	session.Slots[index1].Index = index1
	session.Slots[index2].Index = index2
	session.UpdatedAt = time.Now()
}

// GetStats returns multiview statistics
func (m *MultiviewManager) GetStats() map[string]interface{} {
	m.mu.RLock()
	defer m.mu.RUnlock()

	totalStreams := 0
	for _, session := range m.sessions {
		totalStreams += len(session.Slots)
	}

	return map[string]interface{}{
		"active_sessions": len(m.sessions),
		"total_streams":   totalStreams,
		"max_streams":     m.maxStreams,
	}
}

// GetDVR returns the DVR manager
func (m *MultiviewManager) GetDVR() *MultiviewDVR {
	return m.dvr
}

// Helper to generate session IDs
func generateSessionID() string {
	return time.Now().Format("20060102150405") + "-" + randomString(8)
}

func randomString(n int) string {
	const letters = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, n)
	for i := range b {
		b[i] = letters[time.Now().UnixNano()%int64(len(letters))]
		time.Sleep(1 * time.Nanosecond)
	}
	return string(b)
}
