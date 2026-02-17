package dvr

import (
	"encoding/json"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// DVREventType represents the type of DVR event
type DVREventType string

const (
	EventRecordingStarting  DVREventType = "recording_starting"   // 5 min before
	EventRecordingStarted   DVREventType = "recording_started"
	EventRecordingCompleted DVREventType = "recording_completed"
	EventRecordingFailed    DVREventType = "recording_failed"
	EventDiskSpaceLow       DVREventType = "disk_space_low"
	EventConflictDetected   DVREventType = "conflict_detected"
)

// DVREvent represents a DVR system event
type DVREvent struct {
	Type        DVREventType   `json:"type"`
	RecordingID uint           `json:"recordingId,omitempty"`
	Title       string         `json:"title,omitempty"`
	ChannelName string         `json:"channelName,omitempty"`
	StartTime   *time.Time     `json:"startTime,omitempty"`
	EndTime     *time.Time     `json:"endTime,omitempty"`
	Message     string         `json:"message,omitempty"`
	Timestamp   time.Time      `json:"timestamp"`
	Data        map[string]any `json:"data,omitempty"`
}

// EventBus manages DVR event subscribers
type EventBus struct {
	subscribers map[string]chan []byte
	mutex       sync.RWMutex
}

// NewEventBus creates a new event bus
func NewEventBus() *EventBus {
	return &EventBus{
		subscribers: make(map[string]chan []byte),
	}
}

// Subscribe adds a new subscriber and returns its channel and ID
func (eb *EventBus) Subscribe(id string) chan []byte {
	eb.mutex.Lock()
	defer eb.mutex.Unlock()

	ch := make(chan []byte, 10) // Buffer 10 events
	eb.subscribers[id] = ch
	return ch
}

// Unsubscribe removes a subscriber
func (eb *EventBus) Unsubscribe(id string) {
	eb.mutex.Lock()
	defer eb.mutex.Unlock()

	if ch, exists := eb.subscribers[id]; exists {
		close(ch)
		delete(eb.subscribers, id)
	}
}

// Publish sends an event to all subscribers
func (eb *EventBus) Publish(event DVREvent) {
	event.Timestamp = time.Now()

	data, err := json.Marshal(event)
	if err != nil {
		logger.Log.WithError(err).Error("Failed to marshal DVR event")
		return
	}

	eb.mutex.RLock()
	defer eb.mutex.RUnlock()

	for id, ch := range eb.subscribers {
		select {
		case ch <- data:
		default:
			logger.Log.WithField("subscriber", id).Warn("DVR event subscriber channel full, dropping event")
		}
	}
}

// SubscriberCount returns the number of active subscribers
func (eb *EventBus) SubscriberCount() int {
	eb.mutex.RLock()
	defer eb.mutex.RUnlock()
	return len(eb.subscribers)
}
