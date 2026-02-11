package instant

import (
	"errors"
	"sync"
)

// RingBuffer is a thread-safe circular buffer for streaming data
type RingBuffer struct {
	mu       sync.RWMutex
	data     []byte
	size     int
	head     int // write position
	tail     int // read position
	count    int // bytes currently in buffer
	segments []SegmentInfo
}

// SegmentInfo tracks segment boundaries in the buffer
type SegmentInfo struct {
	ID        string
	Start     int
	Length    int
	Timestamp int64
	Duration  float64
}

var (
	ErrBufferFull  = errors.New("ring buffer is full")
	ErrBufferEmpty = errors.New("ring buffer is empty")
)

// NewRingBuffer creates a new ring buffer with specified size
func NewRingBuffer(size int) *RingBuffer {
	return &RingBuffer{
		data:     make([]byte, size),
		size:     size,
		segments: make([]SegmentInfo, 0, 20),
	}
}

// Write adds data to the buffer, overwriting oldest data if full
func (rb *RingBuffer) Write(p []byte) (n int, err error) {
	rb.mu.Lock()
	defer rb.mu.Unlock()

	for _, b := range p {
		rb.data[rb.head] = b
		rb.head = (rb.head + 1) % rb.size

		if rb.count < rb.size {
			rb.count++
		} else {
			// Buffer full, advance tail (overwrite oldest)
			rb.tail = (rb.tail + 1) % rb.size
			// Remove segments that got overwritten
			rb.pruneOverwrittenSegments()
		}
	}

	return len(p), nil
}

// WriteSegment writes a complete segment and tracks its position
func (rb *RingBuffer) WriteSegment(segmentID string, data []byte, timestamp int64, duration float64) error {
	rb.mu.Lock()
	defer rb.mu.Unlock()

	if len(data) > rb.size {
		return errors.New("segment larger than buffer")
	}

	// Make room if needed
	for rb.count+len(data) > rb.size {
		// Remove oldest byte
		rb.tail = (rb.tail + 1) % rb.size
		rb.count--
		rb.pruneOverwrittenSegments()
	}

	// Track segment start position
	segStart := rb.head

	// Write data
	for _, b := range data {
		rb.data[rb.head] = b
		rb.head = (rb.head + 1) % rb.size
		rb.count++
	}

	// Record segment info
	rb.segments = append(rb.segments, SegmentInfo{
		ID:        segmentID,
		Start:     segStart,
		Length:    len(data),
		Timestamp: timestamp,
		Duration:  duration,
	})

	// Keep max 50 segment records
	if len(rb.segments) > 50 {
		rb.segments = rb.segments[len(rb.segments)-50:]
	}

	return nil
}

// Read reads data from the buffer
func (rb *RingBuffer) Read(p []byte) (n int, err error) {
	rb.mu.Lock()
	defer rb.mu.Unlock()

	if rb.count == 0 {
		return 0, ErrBufferEmpty
	}

	toRead := len(p)
	if toRead > rb.count {
		toRead = rb.count
	}

	for i := 0; i < toRead; i++ {
		p[i] = rb.data[rb.tail]
		rb.tail = (rb.tail + 1) % rb.size
		rb.count--
	}

	return toRead, nil
}

// Peek reads data without consuming it
func (rb *RingBuffer) Peek(p []byte) (n int, err error) {
	rb.mu.RLock()
	defer rb.mu.RUnlock()

	if rb.count == 0 {
		return 0, ErrBufferEmpty
	}

	toRead := len(p)
	if toRead > rb.count {
		toRead = rb.count
	}

	pos := rb.tail
	for i := 0; i < toRead; i++ {
		p[i] = rb.data[pos]
		pos = (pos + 1) % rb.size
	}

	return toRead, nil
}

// ReadSegment reads a specific segment by ID
func (rb *RingBuffer) ReadSegment(segmentID string) ([]byte, bool) {
	rb.mu.RLock()
	defer rb.mu.RUnlock()

	for _, seg := range rb.segments {
		if seg.ID == segmentID {
			data := make([]byte, seg.Length)
			pos := seg.Start
			for i := 0; i < seg.Length; i++ {
				data[i] = rb.data[pos]
				pos = (pos + 1) % rb.size
			}
			return data, true
		}
	}

	return nil, false
}

// GetLatestSegments returns the most recent N segments
func (rb *RingBuffer) GetLatestSegments(n int) []SegmentInfo {
	rb.mu.RLock()
	defer rb.mu.RUnlock()

	if n > len(rb.segments) {
		n = len(rb.segments)
	}

	result := make([]SegmentInfo, n)
	copy(result, rb.segments[len(rb.segments)-n:])
	return result
}

// GetAllData returns all buffered data (for instant playback start)
func (rb *RingBuffer) GetAllData() []byte {
	rb.mu.RLock()
	defer rb.mu.RUnlock()

	if rb.count == 0 {
		return nil
	}

	data := make([]byte, rb.count)
	pos := rb.tail
	for i := 0; i < rb.count; i++ {
		data[i] = rb.data[pos]
		pos = (pos + 1) % rb.size
	}

	return data
}

// Len returns the number of bytes in the buffer
func (rb *RingBuffer) Len() int {
	rb.mu.RLock()
	defer rb.mu.RUnlock()
	return rb.count
}

// Cap returns the total capacity
func (rb *RingBuffer) Cap() int {
	return rb.size
}

// Clear empties the buffer
func (rb *RingBuffer) Clear() {
	rb.mu.Lock()
	defer rb.mu.Unlock()

	rb.head = 0
	rb.tail = 0
	rb.count = 0
	rb.segments = rb.segments[:0]
}

// BufferedDuration returns total duration of buffered content
func (rb *RingBuffer) BufferedDuration() float64 {
	rb.mu.RLock()
	defer rb.mu.RUnlock()

	var total float64
	for _, seg := range rb.segments {
		total += seg.Duration
	}
	return total
}

// pruneOverwrittenSegments removes segments that have been overwritten
func (rb *RingBuffer) pruneOverwrittenSegments() {
	// Remove segments whose data has been overwritten
	valid := make([]SegmentInfo, 0, len(rb.segments))

	for _, seg := range rb.segments {
		// Check if segment start is still within valid range
		if rb.isPositionValid(seg.Start, seg.Length) {
			valid = append(valid, seg)
		}
	}

	rb.segments = valid
}

// isPositionValid checks if a position range is still in the buffer
func (rb *RingBuffer) isPositionValid(start, length int) bool {
	// This is a simplified check - in practice need to handle wraparound
	// For now, check if the segment end hasn't been overwritten

	end := (start + length) % rb.size

	// If buffer hasn't wrapped, simple range check
	if rb.tail <= rb.head {
		return start >= rb.tail && end <= rb.head
	}

	// Buffer has wrapped - position is valid if in either segment
	return (start >= rb.tail) || (end <= rb.head)
}

// Stats returns buffer statistics
func (rb *RingBuffer) Stats() map[string]interface{} {
	rb.mu.RLock()
	defer rb.mu.RUnlock()

	return map[string]interface{}{
		"capacity":          rb.size,
		"used":              rb.count,
		"usage_percent":     float64(rb.count) / float64(rb.size) * 100,
		"segment_count":     len(rb.segments),
		"buffered_duration": rb.BufferedDuration(),
	}
}
