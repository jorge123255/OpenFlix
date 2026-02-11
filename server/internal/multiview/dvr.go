package multiview

import (
	"sync"
	"time"
)

// MultiviewDVR adds pause/rewind/DVR capabilities to multiview streams
// This is our KEY DIFFERENTIATOR vs Channels DVR which has NO DVR in multiview!
type MultiviewDVR struct {
	mu        sync.RWMutex
	buffers   map[string]*StreamTimeshift
	maxBuffer time.Duration
}

// StreamTimeshift holds a timeshifted buffer for one stream
type StreamTimeshift struct {
	ChannelID     string
	BufferSizeMB  int
	IsLive        bool
	LiveOffset    time.Duration
	PausedAt      *time.Time
	PlaybackSpeed float64
	mu            sync.RWMutex
}

// StreamState represents current playback state
type StreamState struct {
	ChannelID      string  `json:"channel_id"`
	IsLive         bool    `json:"is_live"`
	IsPaused       bool    `json:"is_paused"`
	LiveOffsetSecs int     `json:"live_offset_secs"`
	PlaybackSpeed  float64 `json:"playback_speed"`
	BufferSecs     int     `json:"buffer_secs"`
}

// NewMultiviewDVR creates a DVR manager for multiview
func NewMultiviewDVR(maxBufferMinutes int) *MultiviewDVR {
	return &MultiviewDVR{
		buffers:   make(map[string]*StreamTimeshift),
		maxBuffer: time.Duration(maxBufferMinutes) * time.Minute,
	}
}

// AddStream starts DVR buffering for a stream in multiview
func (md *MultiviewDVR) AddStream(channelID string, bufferSizeMB int) *StreamTimeshift {
	md.mu.Lock()
	defer md.mu.Unlock()

	ts := &StreamTimeshift{
		ChannelID:     channelID,
		BufferSizeMB:  bufferSizeMB,
		IsLive:        true,
		LiveOffset:    0,
		PlaybackSpeed: 1.0,
	}

	md.buffers[channelID] = ts
	return ts
}

// RemoveStream stops DVR buffering for a stream
func (md *MultiviewDVR) RemoveStream(channelID string) {
	md.mu.Lock()
	defer md.mu.Unlock()
	delete(md.buffers, channelID)
}

// Pause pauses a specific stream in multiview
func (md *MultiviewDVR) Pause(channelID string) error {
	md.mu.RLock()
	ts, ok := md.buffers[channelID]
	md.mu.RUnlock()

	if !ok {
		return nil
	}

	ts.mu.Lock()
	defer ts.mu.Unlock()

	now := time.Now()
	ts.PausedAt = &now
	ts.IsLive = false
	return nil
}

// Resume resumes a paused stream
func (md *MultiviewDVR) Resume(channelID string) error {
	md.mu.RLock()
	ts, ok := md.buffers[channelID]
	md.mu.RUnlock()

	if !ok {
		return nil
	}

	ts.mu.Lock()
	defer ts.mu.Unlock()

	if ts.PausedAt != nil {
		ts.LiveOffset += time.Since(*ts.PausedAt)
		ts.PausedAt = nil
	}
	return nil
}

// Rewind rewinds a stream by specified seconds
func (md *MultiviewDVR) Rewind(channelID string, seconds int) error {
	md.mu.RLock()
	ts, ok := md.buffers[channelID]
	md.mu.RUnlock()

	if !ok {
		return nil
	}

	ts.mu.Lock()
	defer ts.mu.Unlock()

	ts.LiveOffset += time.Duration(seconds) * time.Second
	ts.IsLive = false

	if ts.LiveOffset > md.maxBuffer {
		ts.LiveOffset = md.maxBuffer
	}
	return nil
}

// FastForward fast-forwards toward live
func (md *MultiviewDVR) FastForward(channelID string, seconds int) error {
	md.mu.RLock()
	ts, ok := md.buffers[channelID]
	md.mu.RUnlock()

	if !ok {
		return nil
	}

	ts.mu.Lock()
	defer ts.mu.Unlock()

	ts.LiveOffset -= time.Duration(seconds) * time.Second
	if ts.LiveOffset <= 0 {
		ts.LiveOffset = 0
		ts.IsLive = true
	}
	return nil
}

// JumpToLive returns to live playback
func (md *MultiviewDVR) JumpToLive(channelID string) error {
	md.mu.RLock()
	ts, ok := md.buffers[channelID]
	md.mu.RUnlock()

	if !ok {
		return nil
	}

	ts.mu.Lock()
	defer ts.mu.Unlock()

	ts.LiveOffset = 0
	ts.IsLive = true
	ts.PausedAt = nil
	return nil
}

// SetPlaybackSpeed sets playback speed (0.5x, 1x, 1.5x, 2x)
func (md *MultiviewDVR) SetPlaybackSpeed(channelID string, speed float64) error {
	md.mu.RLock()
	ts, ok := md.buffers[channelID]
	md.mu.RUnlock()

	if !ok {
		return nil
	}

	ts.mu.Lock()
	defer ts.mu.Unlock()

	if speed < 0.5 {
		speed = 0.5
	}
	if speed > 4.0 {
		speed = 4.0
	}
	ts.PlaybackSpeed = speed
	return nil
}

// GetStreamState returns current state of a stream
func (md *MultiviewDVR) GetStreamState(channelID string) *StreamState {
	md.mu.RLock()
	ts, ok := md.buffers[channelID]
	md.mu.RUnlock()

	if !ok {
		return nil
	}

	ts.mu.RLock()
	defer ts.mu.RUnlock()

	isPaused := ts.PausedAt != nil
	bufferSecs := int(md.maxBuffer.Seconds())

	return &StreamState{
		ChannelID:      channelID,
		IsLive:         ts.IsLive,
		IsPaused:       isPaused,
		LiveOffsetSecs: int(ts.LiveOffset.Seconds()),
		PlaybackSpeed:  ts.PlaybackSpeed,
		BufferSecs:     bufferSecs,
	}
}

// GetAllStates returns state of all streams in multiview
func (md *MultiviewDVR) GetAllStates() map[string]*StreamState {
	md.mu.RLock()
	channels := make([]string, 0, len(md.buffers))
	for ch := range md.buffers {
		channels = append(channels, ch)
	}
	md.mu.RUnlock()

	states := make(map[string]*StreamState)
	for _, channelID := range channels {
		states[channelID] = md.GetStreamState(channelID)
	}
	return states
}

// PauseAll pauses all streams
func (md *MultiviewDVR) PauseAll() {
	md.mu.RLock()
	channels := make([]string, 0, len(md.buffers))
	for ch := range md.buffers {
		channels = append(channels, ch)
	}
	md.mu.RUnlock()

	for _, ch := range channels {
		md.Pause(ch)
	}
}

// ResumeAll resumes all streams
func (md *MultiviewDVR) ResumeAll() {
	md.mu.RLock()
	channels := make([]string, 0, len(md.buffers))
	for ch := range md.buffers {
		channels = append(channels, ch)
	}
	md.mu.RUnlock()

	for _, ch := range channels {
		md.Resume(ch)
	}
}

// JumpAllToLive returns all streams to live
func (md *MultiviewDVR) JumpAllToLive() {
	md.mu.RLock()
	channels := make([]string, 0, len(md.buffers))
	for ch := range md.buffers {
		channels = append(channels, ch)
	}
	md.mu.RUnlock()

	for _, ch := range channels {
		md.JumpToLive(ch)
	}
}

// SyncStreams synchronizes all streams to same timestamp
func (md *MultiviewDVR) SyncStreams(targetOffset time.Duration) {
	md.mu.RLock()
	defer md.mu.RUnlock()

	for _, ts := range md.buffers {
		ts.mu.Lock()
		ts.LiveOffset = targetOffset
		ts.IsLive = (targetOffset == 0)
		ts.mu.Unlock()
	}
}
