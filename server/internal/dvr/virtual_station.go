package dvr

import (
	"fmt"
	"math/rand"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// segmentDuration is the HLS segment length in seconds.
const segmentDuration = 6.0

// playlistEntry represents a single file in a virtual station playlist.
type playlistEntry struct {
	File     models.DVRFile
	Duration float64 // seconds
}

// NowPlayingInfo describes what is currently playing on a virtual station.
type NowPlayingInfo struct {
	StationID   uint    `json:"stationId"`
	StationName string  `json:"stationName"`
	FileID      uint    `json:"fileId"`
	Title       string  `json:"title"`
	Position    float64 `json:"position"`
	Duration    float64 `json:"duration"`
	NextTitle   string  `json:"nextTitle,omitempty"`
}

// stationState tracks the current playback position for a virtual station.
type stationState struct {
	station    *models.VirtualStation
	playlist   []playlistEntry
	currentIdx int
	// currentOffset is the seconds into the current file when the station was
	// started or the playlist was last resolved.  Combined with startedAt it
	// lets us derive the live playback position at any point in time.
	currentOffset float64
	startedAt     time.Time
	baseDir       string // reserved for future on-disk segment cache
}

// VirtualStationPlayer manages playback state for virtual stations.
type VirtualStationPlayer struct {
	db         *gorm.DB
	ffmpegPath string
	mu         sync.RWMutex
	stations   map[uint]*stationState
}

// NewVirtualStationPlayer creates a new VirtualStationPlayer.
func NewVirtualStationPlayer(db *gorm.DB, ffmpegPath string) *VirtualStationPlayer {
	return &VirtualStationPlayer{
		db:         db,
		ffmpegPath: ffmpegPath,
		stations:   make(map[uint]*stationState),
	}
}

// ---------- public API ----------

// GetPlaylist returns an HLS master playlist (M3U8) for the given station.
// It loads the station from the database, resolves files, and builds a
// continuous playlist with #EXT-X-DISCONTINUITY markers between files.
func (vsp *VirtualStationPlayer) GetPlaylist(stationID uint) (string, error) {
	state, err := vsp.ensureState(stationID)
	if err != nil {
		return "", err
	}

	vsp.mu.RLock()
	defer vsp.mu.RUnlock()

	if len(state.playlist) == 0 {
		return "", fmt.Errorf("virtual station %d has no files", stationID)
	}

	var b strings.Builder
	b.WriteString("#EXTM3U\n")
	b.WriteString("#EXT-X-VERSION:3\n")

	// EXT-X-TARGETDURATION must be >= the maximum segment duration.
	// Since all segments are segmentDuration (6s) except possibly the
	// last segment of each file (which is shorter), segmentDuration is
	// the correct target duration.
	targetDur := int(segmentDuration) + 1
	b.WriteString(fmt.Sprintf("#EXT-X-TARGETDURATION:%d\n", targetDur))
	b.WriteString("#EXT-X-MEDIA-SEQUENCE:0\n")

	for fileIdx, pe := range state.playlist {
		if fileIdx > 0 {
			b.WriteString("#EXT-X-DISCONTINUITY\n")
		}
		numSegs := segmentsForDuration(pe.Duration)
		for segIdx := 0; segIdx < numSegs; segIdx++ {
			segDur := segmentDuration
			remaining := pe.Duration - float64(segIdx)*segmentDuration
			if remaining < segDur {
				segDur = remaining
			}
			if segDur <= 0 {
				segDur = segmentDuration
			}
			b.WriteString(fmt.Sprintf("#EXTINF:%.3f,%s\n", segDur, pe.File.Title))
			b.WriteString(fmt.Sprintf("segment/%d/%d\n", fileIdx, segIdx))
		}
	}

	if !state.station.Loop {
		b.WriteString("#EXT-X-ENDLIST\n")
	}

	return b.String(), nil
}

// GetMediaPlaylist returns an HLS media playlist focused on the current
// playback position.  It emits segments around the "now" position so that a
// player joining mid-stream can start near live.
func (vsp *VirtualStationPlayer) GetMediaPlaylist(stationID uint) (string, error) {
	state, err := vsp.ensureState(stationID)
	if err != nil {
		return "", err
	}

	vsp.mu.RLock()
	defer vsp.mu.RUnlock()

	if len(state.playlist) == 0 {
		return "", fmt.Errorf("virtual station %d has no files", stationID)
	}

	fileIdx, offset := vsp.currentPosition(state)

	// Determine which segment the current offset falls into.
	curSeg := int(offset / segmentDuration)
	pe := state.playlist[fileIdx]
	totalSegs := segmentsForDuration(pe.Duration)
	if curSeg >= totalSegs {
		curSeg = totalSegs - 1
	}
	if curSeg < 0 {
		curSeg = 0
	}

	// Emit a window of segments: a few behind the current position plus some
	// look-ahead.  We cap at 30 segments (about 3 minutes).
	windowBehind := 3
	windowAhead := 10
	startSeg := curSeg - windowBehind
	if startSeg < 0 {
		startSeg = 0
	}
	endSeg := curSeg + windowAhead
	if endSeg > totalSegs {
		endSeg = totalSegs
	}

	var b strings.Builder
	b.WriteString("#EXTM3U\n")
	b.WriteString("#EXT-X-VERSION:3\n")
	b.WriteString(fmt.Sprintf("#EXT-X-TARGETDURATION:%d\n", int(segmentDuration)+1))
	b.WriteString(fmt.Sprintf("#EXT-X-MEDIA-SEQUENCE:%d\n", startSeg))

	for segIdx := startSeg; segIdx < endSeg; segIdx++ {
		segDur := segmentDuration
		remaining := pe.Duration - float64(segIdx)*segmentDuration
		if remaining < segDur {
			segDur = remaining
		}
		if segDur <= 0 {
			segDur = segmentDuration
		}
		b.WriteString(fmt.Sprintf("#EXTINF:%.3f,%s\n", segDur, pe.File.Title))
		b.WriteString(fmt.Sprintf("segment/%d/%d\n", fileIdx, segIdx))
	}

	// If there are more files after this one (or if looping), do NOT end the
	// list so the player keeps polling for new segments.
	if !state.station.Loop && fileIdx == len(state.playlist)-1 && endSeg >= totalSegs {
		b.WriteString("#EXT-X-ENDLIST\n")
	}

	return b.String(), nil
}

// GetSegmentPath returns the source file path, start time within the file,
// and segment duration for a specific segment.  The caller (HTTP handler) uses
// this to serve the segment via ffmpeg or direct file serving.
func (vsp *VirtualStationPlayer) GetSegmentPath(stationID uint, fileIdx, segIdx int) (filePath string, startTime float64, duration float64, err error) {
	state, stateErr := vsp.ensureState(stationID)
	if stateErr != nil {
		return "", 0, 0, stateErr
	}

	vsp.mu.RLock()
	defer vsp.mu.RUnlock()

	if len(state.playlist) == 0 {
		return "", 0, 0, fmt.Errorf("virtual station %d has no files", stationID)
	}

	// Resolve fileIdx (may wrap around if looping).
	resolvedIdx := fileIdx
	if state.station.Loop && len(state.playlist) > 0 {
		resolvedIdx = fileIdx % len(state.playlist)
	}
	if resolvedIdx < 0 || resolvedIdx >= len(state.playlist) {
		return "", 0, 0, fmt.Errorf("file index %d out of range (playlist has %d files)", fileIdx, len(state.playlist))
	}

	pe := state.playlist[resolvedIdx]
	totalSegs := segmentsForDuration(pe.Duration)
	if segIdx < 0 || segIdx >= totalSegs {
		return "", 0, 0, fmt.Errorf("segment index %d out of range (file has %d segments)", segIdx, totalSegs)
	}

	startTime = float64(segIdx) * segmentDuration
	duration = segmentDuration
	remaining := pe.Duration - startTime
	if remaining < duration {
		duration = remaining
	}
	if duration <= 0 {
		duration = segmentDuration
	}

	return pe.File.FilePath, startTime, duration, nil
}

// GetNowPlaying returns information about what is currently playing on the
// given station.
func (vsp *VirtualStationPlayer) GetNowPlaying(stationID uint) (*NowPlayingInfo, error) {
	state, err := vsp.ensureState(stationID)
	if err != nil {
		return nil, err
	}

	vsp.mu.RLock()
	defer vsp.mu.RUnlock()

	if len(state.playlist) == 0 {
		return nil, fmt.Errorf("virtual station %d has no files", stationID)
	}

	fileIdx, offset := vsp.currentPosition(state)
	pe := state.playlist[fileIdx]

	info := &NowPlayingInfo{
		StationID:   stationID,
		StationName: state.station.Name,
		FileID:      pe.File.ID,
		Title:       pe.File.Title,
		Position:    offset,
		Duration:    pe.Duration,
	}

	// Determine next title.
	nextIdx := fileIdx + 1
	if state.station.Loop && len(state.playlist) > 0 {
		nextIdx = nextIdx % len(state.playlist)
	}
	if nextIdx >= 0 && nextIdx < len(state.playlist) && nextIdx != fileIdx {
		info.NextTitle = state.playlist[nextIdx].File.Title
	}

	return info, nil
}

// Stop removes the playback state for a station.
func (vsp *VirtualStationPlayer) Stop(stationID uint) {
	vsp.mu.Lock()
	defer vsp.mu.Unlock()
	delete(vsp.stations, stationID)
	logger.Infof("Virtual station %d stopped", stationID)
}

// ---------- internal helpers ----------

// ensureState lazily initialises (or refreshes) the playback state for a
// station.  It loads the station from the database and resolves files.
func (vsp *VirtualStationPlayer) ensureState(stationID uint) (*stationState, error) {
	vsp.mu.Lock()
	defer vsp.mu.Unlock()

	if st, ok := vsp.stations[stationID]; ok {
		return st, nil
	}

	// Load station from DB.
	var station models.VirtualStation
	if err := vsp.db.First(&station, stationID).Error; err != nil {
		return nil, fmt.Errorf("virtual station %d not found: %w", stationID, err)
	}

	if !station.Enabled {
		return nil, fmt.Errorf("virtual station %d is disabled", stationID)
	}

	playlist, err := vsp.resolveFiles(&station)
	if err != nil {
		return nil, fmt.Errorf("failed to resolve files for station %d: %w", stationID, err)
	}
	if len(playlist) == 0 {
		return nil, fmt.Errorf("virtual station %d has no files", stationID)
	}

	st := &stationState{
		station:    &station,
		playlist:   playlist,
		currentIdx: 0,
		startedAt:  time.Now(),
	}
	vsp.stations[stationID] = st

	logger.Infof("Virtual station %d (%s) started with %d files", stationID, station.Name, len(playlist))
	return st, nil
}

// resolveFiles loads the DVRFile records for a VirtualStation.  It handles
// both SmartRule-based queries and manual FileIDs, then applies sort, shuffle,
// and limit settings.
func (vsp *VirtualStationPlayer) resolveFiles(station *models.VirtualStation) ([]playlistEntry, error) {
	var files []models.DVRFile

	// Smart rule evaluation.
	if station.SmartRule != "" {
		conditions, err := ParseQuery(station.SmartRule)
		if err != nil {
			logger.Warnf("Virtual station %d: invalid smart rule: %v", station.ID, err)
		} else if len(conditions) > 0 {
			var allFiles []models.DVRFile
			vsp.db.Where("completed = ? AND deleted = ?", true, false).Find(&allFiles)
			for i := range allFiles {
				if matchFileConditions(conditions, &allFiles[i]) {
					files = append(files, allFiles[i])
				}
			}
		}
	}

	// Manual file IDs.
	if station.FileIDs != "" {
		ids := parseFileIDList(station.FileIDs)
		if len(ids) > 0 {
			var manualFiles []models.DVRFile
			vsp.db.Where("id IN ? AND deleted = ?", ids, false).Find(&manualFiles)
			files = append(files, manualFiles...)
		}
	}

	// Deduplicate by ID.
	files = deduplicateByID(files)

	// Sort.
	files = applySortOrder(files, station.Sort, station.Order)

	// Shuffle (applied after sort if requested).
	if station.Shuffle {
		rng := rand.New(rand.NewSource(time.Now().UnixNano()))
		rng.Shuffle(len(files), func(i, j int) {
			files[i], files[j] = files[j], files[i]
		})
	}

	// Limit.
	if station.Limit > 0 && len(files) > station.Limit {
		files = files[:station.Limit]
	}

	// Convert to playlist entries with durations.
	entries := make([]playlistEntry, 0, len(files))
	for _, f := range files {
		dur := float64(f.Duration)
		if dur <= 0 {
			dur = 3600 // default 1 hour if unknown
		}
		entries = append(entries, playlistEntry{
			File:     f,
			Duration: dur,
		})
	}

	return entries, nil
}

// currentPosition calculates the current file index and offset (in seconds)
// based on elapsed time since the station started.
func (vsp *VirtualStationPlayer) currentPosition(state *stationState) (fileIdx int, offset float64) {
	if len(state.playlist) == 0 {
		return 0, 0
	}

	// Calculate total playlist duration.
	var totalDur float64
	for _, pe := range state.playlist {
		totalDur += pe.Duration
	}
	if totalDur <= 0 {
		return 0, 0
	}

	elapsed := time.Since(state.startedAt).Seconds() + state.currentOffset

	// If looping, wrap elapsed time around the total duration.
	if state.station.Loop {
		elapsed = modFloat(elapsed, totalDur)
	} else {
		// Clamp to end of playlist.
		if elapsed >= totalDur {
			lastIdx := len(state.playlist) - 1
			return lastIdx, state.playlist[lastIdx].Duration
		}
	}

	// Walk through the playlist to find which file we're in.
	var cumulative float64
	for i, pe := range state.playlist {
		if elapsed < cumulative+pe.Duration {
			return i, elapsed - cumulative
		}
		cumulative += pe.Duration
	}

	// Should not reach here, but return last file at end.
	lastIdx := len(state.playlist) - 1
	return lastIdx, state.playlist[lastIdx].Duration
}

// ---------- utility functions ----------

// segmentsForDuration returns the number of HLS segments needed for the given
// duration.
func segmentsForDuration(duration float64) int {
	if duration <= 0 {
		return 1
	}
	n := int(duration / segmentDuration)
	if modFloat(duration, segmentDuration) > 0.001 {
		n++
	}
	if n < 1 {
		n = 1
	}
	return n
}

// modFloat returns x mod y for float64 values.
func modFloat(x, y float64) float64 {
	if y <= 0 {
		return x
	}
	return x - float64(int(x/y))*y
}

// parseFileIDList splits a comma-separated ID string into a uint slice.
func parseFileIDList(s string) []uint {
	parts := strings.Split(s, ",")
	var ids []uint
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if id, err := strconv.ParseUint(p, 10, 32); err == nil {
			ids = append(ids, uint(id))
		}
	}
	return ids
}

// deduplicateByID removes duplicate DVRFile entries by their ID.
func deduplicateByID(files []models.DVRFile) []models.DVRFile {
	seen := make(map[uint]bool, len(files))
	result := make([]models.DVRFile, 0, len(files))
	for _, f := range files {
		if !seen[f.ID] {
			seen[f.ID] = true
			result = append(result, f)
		}
	}
	return result
}

// applySortOrder sorts files by the given criteria.
func applySortOrder(files []models.DVRFile, sortBy, order string) []models.DVRFile {
	if len(files) <= 1 {
		return files
	}

	switch strings.ToLower(sortBy) {
	case "title":
		sort.Slice(files, func(i, j int) bool {
			return strings.ToLower(files[i].Title) < strings.ToLower(files[j].Title)
		})
	case "date":
		sort.Slice(files, func(i, j int) bool {
			return files[i].CreatedAt.Before(files[j].CreatedAt)
		})
	case "duration":
		sort.Slice(files, func(i, j int) bool {
			return files[i].Duration < files[j].Duration
		})
	case "episode":
		sort.Slice(files, func(i, j int) bool {
			si := safeDeref(files[i].SeasonNumber)*1000 + safeDeref(files[i].EpisodeNumber)
			sj := safeDeref(files[j].SeasonNumber)*1000 + safeDeref(files[j].EpisodeNumber)
			return si < sj
		})
	case "random":
		rng := rand.New(rand.NewSource(time.Now().UnixNano()))
		rng.Shuffle(len(files), func(i, j int) {
			files[i], files[j] = files[j], files[i]
		})
		return files // no need to reverse for random
	}

	if strings.ToLower(order) == "desc" {
		for i, j := 0, len(files)-1; i < j; i, j = i+1, j-1 {
			files[i], files[j] = files[j], files[i]
		}
	}

	return files
}

// safeDeref safely dereferences an *int, returning 0 if nil.
func safeDeref(p *int) int {
	if p == nil {
		return 0
	}
	return *p
}

// matchFileConditions evaluates all query conditions against a DVRFile.
// All conditions must match (AND logic).
func matchFileConditions(conditions []models.RuleCondition, file *models.DVRFile) bool {
	for _, cond := range conditions {
		fieldValue := fileFieldValue(cond.Field, file)
		if !matchConditionOp(cond.Op, fieldValue, cond.Value) {
			return false
		}
	}
	return true
}

// fileFieldValue extracts the value of a field from a DVRFile.
func fileFieldValue(field string, f *models.DVRFile) string {
	switch strings.ToLower(field) {
	case "title":
		return f.Title
	case "subtitle":
		return f.Subtitle
	case "description", "summary":
		return f.Description
	case "genre", "genres":
		return f.Genres
	case "contentrating", "rating":
		return f.ContentRating
	case "category":
		return f.Category
	case "ismovie":
		return strconv.FormatBool(f.IsMovie)
	case "year":
		if f.Year != nil && *f.Year > 0 {
			return strconv.Itoa(*f.Year)
		}
		return ""
	case "season", "seasonnumber":
		if f.SeasonNumber != nil && *f.SeasonNumber > 0 {
			return strconv.Itoa(*f.SeasonNumber)
		}
		return ""
	case "episode", "episodenumber":
		if f.EpisodeNumber != nil && *f.EpisodeNumber > 0 {
			return strconv.Itoa(*f.EpisodeNumber)
		}
		return ""
	case "labels":
		return f.Labels
	case "channelname":
		return f.ChannelName
	default:
		return ""
	}
}

// matchConditionOp applies a query operator to compare field and condition values.
func matchConditionOp(op, fieldValue, condValue string) bool {
	switch strings.ToUpper(op) {
	case "EQ":
		return strings.EqualFold(fieldValue, condValue)
	case "NE":
		return !strings.EqualFold(fieldValue, condValue)
	case "LIKE":
		fv := strings.ToLower(fieldValue)
		cv := strings.ToLower(condValue)
		if strings.HasPrefix(cv, "%") && strings.HasSuffix(cv, "%") {
			return strings.Contains(fv, cv[1:len(cv)-1])
		}
		if strings.HasPrefix(cv, "%") {
			return strings.HasSuffix(fv, cv[1:])
		}
		if strings.HasSuffix(cv, "%") {
			return strings.HasPrefix(fv, cv[:len(cv)-1])
		}
		return strings.Contains(fv, cv)
	case "IN":
		parts := strings.Split(condValue, ",")
		for _, p := range parts {
			if strings.EqualFold(fieldValue, strings.TrimSpace(p)) {
				return true
			}
		}
		return false
	case "NI":
		parts := strings.Split(condValue, ",")
		for _, p := range parts {
			if strings.EqualFold(fieldValue, strings.TrimSpace(p)) {
				return false
			}
		}
		return true
	case "GT":
		fv, err1 := strconv.ParseFloat(fieldValue, 64)
		cv, err2 := strconv.ParseFloat(condValue, 64)
		if err1 == nil && err2 == nil {
			return fv > cv
		}
		return strings.ToLower(fieldValue) > strings.ToLower(condValue)
	case "LT":
		fv, err1 := strconv.ParseFloat(fieldValue, 64)
		cv, err2 := strconv.ParseFloat(condValue, 64)
		if err1 == nil && err2 == nil {
			return fv < cv
		}
		return strings.ToLower(fieldValue) < strings.ToLower(condValue)
	default:
		return false
	}
}
