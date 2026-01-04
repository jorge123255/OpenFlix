package livetv

import (
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// TunerSession represents an active tuner session for a channel
type TunerSession struct {
	ChannelID    uint      `json:"channelId"`
	ChannelName  string    `json:"channelName"`
	StreamURL    string    `json:"streamUrl"`
	StartTime    time.Time `json:"startTime"`
	Viewers      []Viewer  `json:"viewers"`
	IsPrimary    bool      `json:"isPrimary"` // First viewer who started the stream
	mutex        sync.RWMutex
}

// Viewer represents a client watching a channel
type Viewer struct {
	UserID      uint      `json:"userId"`
	SessionID   string    `json:"sessionId"`
	DeviceName  string    `json:"deviceName"`
	DeviceType  string    `json:"deviceType"` // tv, mobile, desktop
	JoinedAt    time.Time `json:"joinedAt"`
	IsPrimary   bool      `json:"isPrimary"`
}

// TunerSharingManager manages shared tuner sessions
type TunerSharingManager struct {
	db           *gorm.DB
	sessions     map[uint]*TunerSession // keyed by channel ID
	mutex        sync.RWMutex
	maxTuners    int // 0 = unlimited
	cleanupStop  chan struct{}
}

// TunerSharingConfig configures the tuner sharing manager
type TunerSharingConfig struct {
	MaxTuners        int           // Maximum concurrent tuners (0 = unlimited)
	SessionTimeout   time.Duration // How long before an inactive session expires
	EnableSharing    bool          // Whether to allow stream sharing
}

// TunerStatus represents the current tuner status
type TunerStatus struct {
	ActiveTuners    int              `json:"activeTuners"`
	MaxTuners       int              `json:"maxTuners"` // 0 = unlimited
	TunersAvailable int              `json:"tunersAvailable"` // -1 = unlimited
	Sessions        []*SessionInfo   `json:"sessions"`
	SharingEnabled  bool             `json:"sharingEnabled"`
}

// SessionInfo is a summary of a tuner session for API responses
type SessionInfo struct {
	ChannelID    uint      `json:"channelId"`
	ChannelName  string    `json:"channelName"`
	ViewerCount  int       `json:"viewerCount"`
	StartTime    time.Time `json:"startTime"`
	Duration     int       `json:"duration"` // seconds
}

// JoinResult represents the result of joining a channel
type JoinResult struct {
	Success       bool   `json:"success"`
	StreamURL     string `json:"streamUrl"`
	IsShared      bool   `json:"isShared"`      // True if sharing with another viewer
	ViewerCount   int    `json:"viewerCount"`
	TunerUsed     bool   `json:"tunerUsed"`     // True if this required a new tuner
	Error         string `json:"error,omitempty"`
}

// NewTunerSharingManager creates a new tuner sharing manager
func NewTunerSharingManager(db *gorm.DB, config TunerSharingConfig) *TunerSharingManager {
	tsm := &TunerSharingManager{
		db:          db,
		sessions:    make(map[uint]*TunerSession),
		maxTuners:   config.MaxTuners,
		cleanupStop: make(chan struct{}),
	}

	// Start cleanup routine
	go tsm.cleanupLoop(config.SessionTimeout)

	logger.Log.WithFields(map[string]interface{}{
		"max_tuners":      config.MaxTuners,
		"sharing_enabled": config.EnableSharing,
	}).Info("Tuner sharing manager initialized")

	return tsm
}

// JoinChannel attempts to join a channel, sharing a tuner if possible
func (tsm *TunerSharingManager) JoinChannel(channelID uint, userID uint, sessionID, deviceName, deviceType string) (*JoinResult, error) {
	tsm.mutex.Lock()
	defer tsm.mutex.Unlock()

	// Check if there's already an active session for this channel
	if session, exists := tsm.sessions[channelID]; exists {
		// Add this viewer to the existing session
		session.mutex.Lock()
		viewer := Viewer{
			UserID:     userID,
			SessionID:  sessionID,
			DeviceName: deviceName,
			DeviceType: deviceType,
			JoinedAt:   time.Now(),
			IsPrimary:  false,
		}
		session.Viewers = append(session.Viewers, viewer)
		viewerCount := len(session.Viewers)
		streamURL := session.StreamURL
		session.mutex.Unlock()

		logger.Log.WithFields(map[string]interface{}{
			"channel_id":   channelID,
			"user_id":      userID,
			"session_id":   sessionID,
			"viewer_count": viewerCount,
		}).Info("Viewer joined shared tuner session")

		return &JoinResult{
			Success:     true,
			StreamURL:   streamURL,
			IsShared:    true,
			ViewerCount: viewerCount,
			TunerUsed:   false,
		}, nil
	}

	// No existing session - need to create a new one
	// Check if we have tuners available
	if tsm.maxTuners > 0 && len(tsm.sessions) >= tsm.maxTuners {
		return &JoinResult{
			Success: false,
			Error:   "No tuners available. All tuners are in use.",
		}, nil
	}

	// Get channel info
	var channel models.Channel
	if err := tsm.db.First(&channel, channelID).Error; err != nil {
		return &JoinResult{
			Success: false,
			Error:   "Channel not found",
		}, nil
	}

	// Create new session
	session := &TunerSession{
		ChannelID:   channelID,
		ChannelName: channel.Name,
		StreamURL:   channel.StreamURL,
		StartTime:   time.Now(),
		IsPrimary:   true,
		Viewers: []Viewer{
			{
				UserID:     userID,
				SessionID:  sessionID,
				DeviceName: deviceName,
				DeviceType: deviceType,
				JoinedAt:   time.Now(),
				IsPrimary:  true,
			},
		},
	}

	tsm.sessions[channelID] = session

	logger.Log.WithFields(map[string]interface{}{
		"channel_id":   channelID,
		"channel_name": channel.Name,
		"user_id":      userID,
		"session_id":   sessionID,
		"active_tuners": len(tsm.sessions),
	}).Info("Created new tuner session")

	return &JoinResult{
		Success:     true,
		StreamURL:   channel.StreamURL,
		IsShared:    false,
		ViewerCount: 1,
		TunerUsed:   true,
	}, nil
}

// LeaveChannel removes a viewer from a channel session
func (tsm *TunerSharingManager) LeaveChannel(channelID uint, sessionID string) {
	tsm.mutex.Lock()
	defer tsm.mutex.Unlock()

	session, exists := tsm.sessions[channelID]
	if !exists {
		return
	}

	session.mutex.Lock()
	// Remove the viewer
	for i, viewer := range session.Viewers {
		if viewer.SessionID == sessionID {
			session.Viewers = append(session.Viewers[:i], session.Viewers[i+1:]...)
			break
		}
	}
	viewerCount := len(session.Viewers)
	session.mutex.Unlock()

	logger.Log.WithFields(map[string]interface{}{
		"channel_id":   channelID,
		"session_id":   sessionID,
		"viewers_left": viewerCount,
	}).Info("Viewer left tuner session")

	// If no viewers left, close the session
	if viewerCount == 0 {
		delete(tsm.sessions, channelID)
		logger.Log.WithField("channel_id", channelID).Info("Closed tuner session - no viewers remaining")
	}
}

// GetTunerStatus returns the current tuner status
func (tsm *TunerSharingManager) GetTunerStatus() *TunerStatus {
	tsm.mutex.RLock()
	defer tsm.mutex.RUnlock()

	sessions := make([]*SessionInfo, 0, len(tsm.sessions))
	for _, session := range tsm.sessions {
		session.mutex.RLock()
		sessions = append(sessions, &SessionInfo{
			ChannelID:   session.ChannelID,
			ChannelName: session.ChannelName,
			ViewerCount: len(session.Viewers),
			StartTime:   session.StartTime,
			Duration:    int(time.Since(session.StartTime).Seconds()),
		})
		session.mutex.RUnlock()
	}

	tunersAvailable := -1 // unlimited
	if tsm.maxTuners > 0 {
		tunersAvailable = tsm.maxTuners - len(tsm.sessions)
		if tunersAvailable < 0 {
			tunersAvailable = 0
		}
	}

	return &TunerStatus{
		ActiveTuners:    len(tsm.sessions),
		MaxTuners:       tsm.maxTuners,
		TunersAvailable: tunersAvailable,
		Sessions:        sessions,
		SharingEnabled:  true,
	}
}

// GetSessionViewers returns the viewers for a specific channel
func (tsm *TunerSharingManager) GetSessionViewers(channelID uint) []Viewer {
	tsm.mutex.RLock()
	session, exists := tsm.sessions[channelID]
	tsm.mutex.RUnlock()

	if !exists {
		return nil
	}

	session.mutex.RLock()
	viewers := make([]Viewer, len(session.Viewers))
	copy(viewers, session.Viewers)
	session.mutex.RUnlock()

	return viewers
}

// IsChannelActive returns whether a channel has active viewers
func (tsm *TunerSharingManager) IsChannelActive(channelID uint) bool {
	tsm.mutex.RLock()
	defer tsm.mutex.RUnlock()
	_, exists := tsm.sessions[channelID]
	return exists
}

// GetActiveChannels returns a list of channel IDs with active sessions
func (tsm *TunerSharingManager) GetActiveChannels() []uint {
	tsm.mutex.RLock()
	defer tsm.mutex.RUnlock()

	channels := make([]uint, 0, len(tsm.sessions))
	for channelID := range tsm.sessions {
		channels = append(channels, channelID)
	}
	return channels
}

// UpdateHeartbeat updates the last activity time for a viewer
func (tsm *TunerSharingManager) UpdateHeartbeat(channelID uint, sessionID string) {
	tsm.mutex.RLock()
	session, exists := tsm.sessions[channelID]
	tsm.mutex.RUnlock()

	if !exists {
		return
	}

	session.mutex.Lock()
	for i := range session.Viewers {
		if session.Viewers[i].SessionID == sessionID {
			session.Viewers[i].JoinedAt = time.Now() // Reuse JoinedAt as last activity
			break
		}
	}
	session.mutex.Unlock()
}

// cleanupLoop periodically removes stale sessions
func (tsm *TunerSharingManager) cleanupLoop(timeout time.Duration) {
	if timeout <= 0 {
		timeout = 5 * time.Minute
	}

	ticker := time.NewTicker(1 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			tsm.cleanupStaleSessions(timeout)
		case <-tsm.cleanupStop:
			return
		}
	}
}

// cleanupStaleSessions removes viewers who haven't sent a heartbeat
func (tsm *TunerSharingManager) cleanupStaleSessions(timeout time.Duration) {
	tsm.mutex.Lock()
	defer tsm.mutex.Unlock()

	now := time.Now()
	channelsToRemove := []uint{}

	for channelID, session := range tsm.sessions {
		session.mutex.Lock()
		activeViewers := []Viewer{}
		for _, viewer := range session.Viewers {
			if now.Sub(viewer.JoinedAt) < timeout {
				activeViewers = append(activeViewers, viewer)
			} else {
				logger.Log.WithFields(map[string]interface{}{
					"channel_id": channelID,
					"session_id": viewer.SessionID,
					"user_id":    viewer.UserID,
				}).Debug("Removed stale viewer from tuner session")
			}
		}
		session.Viewers = activeViewers
		if len(session.Viewers) == 0 {
			channelsToRemove = append(channelsToRemove, channelID)
		}
		session.mutex.Unlock()
	}

	for _, channelID := range channelsToRemove {
		delete(tsm.sessions, channelID)
		logger.Log.WithField("channel_id", channelID).Info("Closed stale tuner session")
	}
}

// Stop stops the tuner sharing manager
func (tsm *TunerSharingManager) Stop() {
	close(tsm.cleanupStop)

	tsm.mutex.Lock()
	for channelID := range tsm.sessions {
		delete(tsm.sessions, channelID)
	}
	tsm.mutex.Unlock()

	logger.Log.Info("Tuner sharing manager stopped")
}
