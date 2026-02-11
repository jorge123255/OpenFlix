package instant

import (
	"encoding/json"
	"os"
	"sort"
	"sync"
	"time"
)

// ChannelPredictor learns channel switching patterns to pre-buffer likely next channels
type ChannelPredictor struct {
	mu          sync.RWMutex
	transitions map[string]map[string]int // from -> to -> count
	timeSlots   map[int]map[string]int    // hour -> channel -> count
	lastSave    time.Time
	savePath    string
}

// NewChannelPredictor creates a new predictor
func NewChannelPredictor(dataDir string) *ChannelPredictor {
	cp := &ChannelPredictor{
		transitions: make(map[string]map[string]int),
		timeSlots:   make(map[int]map[string]int),
		savePath:    dataDir + "/channel_patterns.json",
	}

	// Try to load existing patterns
	cp.load()

	return cp
}

// RecordSwitch records a channel switch for learning
func (cp *ChannelPredictor) RecordSwitch(fromChannel, toChannel string) {
	cp.mu.Lock()
	defer cp.mu.Unlock()

	// Record transition
	if cp.transitions[fromChannel] == nil {
		cp.transitions[fromChannel] = make(map[string]int)
	}
	cp.transitions[fromChannel][toChannel]++

	// Record time-based pattern
	hour := time.Now().Hour()
	if cp.timeSlots[hour] == nil {
		cp.timeSlots[hour] = make(map[string]int)
	}
	cp.timeSlots[hour][toChannel]++

	// Save periodically (every 5 minutes)
	if time.Since(cp.lastSave) > 5*time.Minute {
		go cp.save()
		cp.lastSave = time.Now()
	}
}

// PredictNext returns the most likely next channels from current channel
func (cp *ChannelPredictor) PredictNext(currentChannel string, count int) []string {
	cp.mu.RLock()
	defer cp.mu.RUnlock()

	// Combine transition-based and time-based predictions
	scores := make(map[string]float64)

	// Weight 1: Direct transitions from current channel (highest weight)
	if transitions, ok := cp.transitions[currentChannel]; ok {
		total := 0
		for _, c := range transitions {
			total += c
		}
		for ch, c := range transitions {
			scores[ch] += float64(c) / float64(total) * 100
		}
	}

	// Weight 2: Time-based patterns (what's popular at this hour)
	hour := time.Now().Hour()
	if hourlyChannels, ok := cp.timeSlots[hour]; ok {
		total := 0
		for _, c := range hourlyChannels {
			total += c
		}
		for ch, c := range hourlyChannels {
			scores[ch] += float64(c) / float64(total) * 30
		}
	}

	// Weight 3: Adjacent hours (lighter weight)
	for _, h := range []int{(hour + 23) % 24, (hour + 1) % 24} {
		if hourlyChannels, ok := cp.timeSlots[h]; ok {
			total := 0
			for _, c := range hourlyChannels {
				total += c
			}
			for ch, c := range hourlyChannels {
				scores[ch] += float64(c) / float64(total) * 10
			}
		}
	}

	// Don't predict current channel
	delete(scores, currentChannel)

	// Sort by score
	type channelScore struct {
		channel string
		score   float64
	}

	var sorted []channelScore
	for ch, score := range scores {
		sorted = append(sorted, channelScore{ch, score})
	}

	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].score > sorted[j].score
	})

	// Return top N
	result := make([]string, 0, count)
	for i := 0; i < len(sorted) && i < count; i++ {
		result = append(result, sorted[i].channel)
	}

	return result
}

// GetPopularChannels returns most watched channels for current time
func (cp *ChannelPredictor) GetPopularChannels(count int) []string {
	cp.mu.RLock()
	defer cp.mu.RUnlock()

	hour := time.Now().Hour()

	// Aggregate current hour and adjacent hours
	scores := make(map[string]int)

	for _, h := range []int{(hour + 23) % 24, hour, (hour + 1) % 24} {
		weight := 1
		if h == hour {
			weight = 3 // Current hour weighted 3x
		}
		if hourlyChannels, ok := cp.timeSlots[h]; ok {
			for ch, c := range hourlyChannels {
				scores[ch] += c * weight
			}
		}
	}

	// Sort by score
	type channelScore struct {
		channel string
		score   int
	}

	var sorted []channelScore
	for ch, score := range scores {
		sorted = append(sorted, channelScore{ch, score})
	}

	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].score > sorted[j].score
	})

	// Return top N
	result := make([]string, 0, count)
	for i := 0; i < len(sorted) && i < count; i++ {
		result = append(result, sorted[i].channel)
	}

	return result
}

// GetTransitionProbability returns likelihood of switching from A to B
func (cp *ChannelPredictor) GetTransitionProbability(from, to string) float64 {
	cp.mu.RLock()
	defer cp.mu.RUnlock()

	if transitions, ok := cp.transitions[from]; ok {
		total := 0
		for _, c := range transitions {
			total += c
		}
		if count, ok := transitions[to]; ok {
			return float64(count) / float64(total)
		}
	}

	return 0
}

// patternData is the JSON structure for saving/loading
type patternData struct {
	Transitions map[string]map[string]int `json:"transitions"`
	TimeSlots   map[int]map[string]int    `json:"time_slots"`
	UpdatedAt   time.Time                 `json:"updated_at"`
}

// save persists patterns to disk
func (cp *ChannelPredictor) save() error {
	cp.mu.RLock()
	data := patternData{
		Transitions: cp.transitions,
		TimeSlots:   cp.timeSlots,
		UpdatedAt:   time.Now(),
	}
	cp.mu.RUnlock()

	jsonData, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(cp.savePath, jsonData, 0644)
}

// load restores patterns from disk
func (cp *ChannelPredictor) load() error {
	data, err := os.ReadFile(cp.savePath)
	if err != nil {
		return err // File might not exist yet, that's OK
	}

	var pd patternData
	if err := json.Unmarshal(data, &pd); err != nil {
		return err
	}

	cp.mu.Lock()
	defer cp.mu.Unlock()

	cp.transitions = pd.Transitions
	cp.timeSlots = pd.TimeSlots

	return nil
}

// Clear resets all learned patterns
func (cp *ChannelPredictor) Clear() {
	cp.mu.Lock()
	defer cp.mu.Unlock()

	cp.transitions = make(map[string]map[string]int)
	cp.timeSlots = make(map[int]map[string]int)

	// Remove saved file
	os.Remove(cp.savePath)
}

// Stats returns predictor statistics
func (cp *ChannelPredictor) Stats() map[string]interface{} {
	cp.mu.RLock()
	defer cp.mu.RUnlock()

	totalTransitions := 0
	for _, tos := range cp.transitions {
		for _, count := range tos {
			totalTransitions += count
		}
	}

	return map[string]interface{}{
		"unique_channels":    len(cp.transitions),
		"total_transitions":  totalTransitions,
		"hours_with_data":    len(cp.timeSlots),
		"popular_now":        cp.GetPopularChannels(5),
	}
}

// Debug returns detailed transition data for debugging
func (cp *ChannelPredictor) Debug() map[string]interface{} {
	cp.mu.RLock()
	defer cp.mu.RUnlock()

	return map[string]interface{}{
		"transitions": cp.transitions,
		"time_slots":  cp.timeSlots,
	}
}
