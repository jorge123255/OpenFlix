package dvr

import (
	"sort"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// ConflictResolver detects and resolves DVR scheduling conflicts by finding
// alternative airings, applying priority-based resolution, and rescheduling
// jobs to non-conflicting time slots.
type ConflictResolver struct {
	db *gorm.DB
}

// NewConflictResolver creates a new ConflictResolver.
func NewConflictResolver(db *gorm.DB) *ConflictResolver {
	return &ConflictResolver{db: db}
}

// JobConflictGroup describes a set of overlapping DVR jobs that exceed the
// available tuner capacity.
type JobConflictGroup struct {
	GroupID      uint             `json:"groupId"`
	Jobs         []models.DVRJob  `json:"jobs"`
	TimeSlotStart time.Time       `json:"timeSlotStart"`
	TimeSlotEnd   time.Time       `json:"timeSlotEnd"`
	TunerCount   int              `json:"tunerCount"`
	Overflow     int              `json:"overflow"` // how many jobs exceed tuner count
	Suggestions  []ConflictSuggestion `json:"suggestions,omitempty"`
}

// ConflictSuggestion proposes a resolution for a single job in a conflict.
type ConflictSuggestion struct {
	JobID       uint              `json:"jobId"`
	Action      string            `json:"action"` // "reschedule", "cancel", "keep"
	Reason      string            `json:"reason"`
	Alternative *AlternativeAiring `json:"alternative,omitempty"`
}

// AlternativeAiring represents a different broadcast of the same program
// that could be recorded instead.
type AlternativeAiring struct {
	ProgramID   uint      `json:"programId"`
	ChannelID   string    `json:"channelId"`
	ChannelName string    `json:"channelName,omitempty"`
	Title       string    `json:"title"`
	Subtitle    string    `json:"subtitle,omitempty"`
	Start       time.Time `json:"start"`
	End         time.Time `json:"end"`
	HasConflict bool      `json:"hasConflict"` // whether this alternative also conflicts
}

// ResolveResult reports what happened when a conflict was resolved.
type ResolveResult struct {
	Resolved    bool   `json:"resolved"`
	Action      string `json:"action"` // "rescheduled", "cancelled", "kept"
	JobID       uint   `json:"jobId"`
	Message     string `json:"message"`
	NewJobID    *uint  `json:"newJobId,omitempty"` // if rescheduled to a new job
}

// AutoResolveResult reports the outcome of auto-resolving all conflicts.
type AutoResolveResult struct {
	TotalConflicts int             `json:"totalConflicts"`
	Resolved       int             `json:"resolved"`
	Remaining      int             `json:"remaining"`
	Actions        []ResolveResult `json:"actions"`
}

// getTunerCount reads the configured max concurrent recordings from the
// settings table. Returns 2 as a default if nothing is configured.
func (cr *ConflictResolver) getTunerCount() int {
	var setting models.Setting
	if err := cr.db.Where("key = ?", "dvr_max_concurrent").First(&setting).Error; err != nil {
		return 2 // sensible default
	}
	val := 0
	for _, ch := range setting.Value {
		if ch >= '0' && ch <= '9' {
			val = val*10 + int(ch-'0')
		}
	}
	if val <= 0 {
		return 2
	}
	return val
}

// ResolveConflicts scans all scheduled DVR jobs and returns the set of
// conflict groups where more jobs overlap than tuners are available.
func (cr *ConflictResolver) ResolveConflicts(userID uint) ([]JobConflictGroup, error) {
	tunerCount := cr.getTunerCount()

	var jobs []models.DVRJob
	if err := cr.db.Where("status IN ? AND cancelled = false", []string{"scheduled", "conflict"}).
		Order("start_time ASC").Find(&jobs).Error; err != nil {
		return nil, err
	}

	// If userID > 0, filter to that user.
	if userID > 0 {
		filtered := jobs[:0]
		for _, j := range jobs {
			if j.UserID == userID {
				filtered = append(filtered, j)
			}
		}
		jobs = filtered
	}

	if len(jobs) == 0 {
		return nil, nil
	}

	// Build conflict groups using a sweep-line approach.
	conflicts := cr.findConflictGroups(jobs, tunerCount)

	// Attach suggestions to each conflict.
	for i := range conflicts {
		suggestions, err := cr.GetConflictSuggestions(&conflicts[i])
		if err != nil {
			logger.Warnf("conflict_resolver: failed to get suggestions for group %d: %v", conflicts[i].GroupID, err)
			continue
		}
		conflicts[i].Suggestions = suggestions
	}

	return conflicts, nil
}

// findConflictGroups uses an interval sweep to group overlapping jobs.
// A conflict group exists when more simultaneous jobs exist than tunerCount.
func (cr *ConflictResolver) findConflictGroups(jobs []models.DVRJob, tunerCount int) []JobConflictGroup {
	type event struct {
		t     time.Time
		start bool
		job   *models.DVRJob
	}

	events := make([]event, 0, len(jobs)*2)
	for i := range jobs {
		events = append(events,
			event{t: jobs[i].StartTime, start: true, job: &jobs[i]},
			event{t: jobs[i].EndTime, start: false, job: &jobs[i]},
		)
	}
	sort.Slice(events, func(i, j int) bool {
		if events[i].t.Equal(events[j].t) {
			// Ends before starts at the same instant.
			return !events[i].start && events[j].start
		}
		return events[i].t.Before(events[j].t)
	})

	// Track which jobs are currently active.
	active := make(map[uint]*models.DVRJob)
	var conflicts []JobConflictGroup
	groupCounter := uint(1)
	seen := make(map[uint]bool) // jobs already placed in a conflict group

	for _, ev := range events {
		if ev.start {
			active[ev.job.ID] = ev.job
		} else {
			delete(active, ev.job.ID)
		}

		if len(active) > tunerCount {
			// Collect all currently active jobs not already in a group.
			var groupJobs []models.DVRJob
			var earliest, latest time.Time
			first := true
			for _, aj := range active {
				if seen[aj.ID] {
					continue
				}
				groupJobs = append(groupJobs, *aj)
				if first || aj.StartTime.Before(earliest) {
					earliest = aj.StartTime
				}
				if first || aj.EndTime.After(latest) {
					latest = aj.EndTime
				}
				first = false
			}

			if len(groupJobs) > tunerCount {
				// Sort by priority descending.
				sort.Slice(groupJobs, func(i, j int) bool {
					return groupJobs[i].Priority > groupJobs[j].Priority
				})
				for k := range groupJobs {
					seen[groupJobs[k].ID] = true
				}
				conflicts = append(conflicts, JobConflictGroup{
					GroupID:       groupCounter,
					Jobs:          groupJobs,
					TimeSlotStart: earliest,
					TimeSlotEnd:   latest,
					TunerCount:    tunerCount,
					Overflow:      len(groupJobs) - tunerCount,
				})
				groupCounter++
			}
		}
	}

	return conflicts
}

// FindAlternativeAirings searches the programs table for other broadcasts
// of the same show (matched by title + subtitle) within +/- 7 days on any
// channel/time. The caller can then offer these as reschedule targets.
func (cr *ConflictResolver) FindAlternativeAirings(job *models.DVRJob) ([]AlternativeAiring, error) {
	windowStart := job.StartTime.Add(-7 * 24 * time.Hour)
	windowEnd := job.StartTime.Add(7 * 24 * time.Hour)

	// Resolve the channel's EPG string ID from the channels table so we can
	// exclude the original airing from results (programs.channel_id is a string).
	var origChannelEPGID string
	var ch models.Channel
	if err := cr.db.First(&ch, job.ChannelID).Error; err == nil {
		origChannelEPGID = ch.ChannelID
	}

	query := cr.db.Model(&models.Program{}).
		Where("title = ? AND start >= ? AND start <= ?", job.Title, windowStart, windowEnd).
		Where("NOT (channel_id = ? AND start = ?)", origChannelEPGID, job.StartTime) // exclude the original

	// If the job has a subtitle, require it to match for episode-level precision.
	if job.Subtitle != "" {
		query = query.Where("subtitle = ?", job.Subtitle)
	}

	query = query.Order("start ASC").Limit(20)

	var programs []models.Program
	if err := query.Find(&programs).Error; err != nil {
		return nil, err
	}

	// For each candidate, resolve channel name and check whether it also
	// conflicts with existing scheduled jobs.
	scheduledJobs, _ := cr.getScheduledJobs(job.UserID)

	alternatives := make([]AlternativeAiring, 0, len(programs))
	for _, p := range programs {
		alt := AlternativeAiring{
			ProgramID: p.ID,
			ChannelID: p.ChannelID,
			Title:     p.Title,
			Subtitle:  p.Subtitle,
			Start:     p.Start,
			End:       p.End,
		}

		// Resolve channel name.
		var ch models.Channel
		if err := cr.db.Where("channel_id = ?", p.ChannelID).First(&ch).Error; err == nil {
			alt.ChannelName = ch.Name
		}

		// Check if the alternative itself conflicts.
		alt.HasConflict = cr.wouldConflict(p.Start, p.End, scheduledJobs, job.ID)

		alternatives = append(alternatives, alt)
	}

	return alternatives, nil
}

// getScheduledJobs fetches all scheduled/conflict DVR jobs for a user.
func (cr *ConflictResolver) getScheduledJobs(userID uint) ([]models.DVRJob, error) {
	var jobs []models.DVRJob
	query := cr.db.Where("status IN ? AND cancelled = false", []string{"scheduled", "conflict", "recording"})
	if userID > 0 {
		query = query.Where("user_id = ?", userID)
	}
	err := query.Find(&jobs).Error
	return jobs, err
}

// wouldConflict checks whether a proposed time range would overlap with
// more jobs than tuners allow, excluding a specific job ID.
func (cr *ConflictResolver) wouldConflict(start, end time.Time, existing []models.DVRJob, excludeID uint) bool {
	tunerCount := cr.getTunerCount()
	overlapping := 0
	for _, j := range existing {
		if j.ID == excludeID {
			continue
		}
		if j.StartTime.Before(end) && start.Before(j.EndTime) {
			overlapping++
		}
	}
	return overlapping >= tunerCount
}

// GetConflictSuggestions generates resolution suggestions for a conflict
// group. It favours keeping higher-priority jobs and rescheduling or
// cancelling lower-priority ones.
func (cr *ConflictResolver) GetConflictSuggestions(conflict *JobConflictGroup) ([]ConflictSuggestion, error) {
	if len(conflict.Jobs) == 0 {
		return nil, nil
	}

	// Jobs are already sorted by priority desc (from findConflictGroups).
	suggestions := make([]ConflictSuggestion, 0, len(conflict.Jobs))

	// The top tunerCount jobs are kept; the rest need resolution.
	for i, job := range conflict.Jobs {
		if i < conflict.TunerCount {
			suggestions = append(suggestions, ConflictSuggestion{
				JobID:  job.ID,
				Action: "keep",
				Reason: "Higher priority; fits within tuner capacity",
			})
			continue
		}

		// Try to find an alternative airing for the overflow job.
		alts, err := cr.FindAlternativeAirings(&job)
		if err != nil {
			logger.Warnf("conflict_resolver: error finding alternatives for job %d: %v", job.ID, err)
		}

		// Pick the first non-conflicting alternative.
		var bestAlt *AlternativeAiring
		for j := range alts {
			if !alts[j].HasConflict {
				bestAlt = &alts[j]
				break
			}
		}

		if bestAlt != nil {
			suggestions = append(suggestions, ConflictSuggestion{
				JobID:       job.ID,
				Action:      "reschedule",
				Reason:      "Lower priority; alternative airing available",
				Alternative: bestAlt,
			})
		} else {
			suggestions = append(suggestions, ConflictSuggestion{
				JobID:  job.ID,
				Action: "cancel",
				Reason: "Lower priority; no conflict-free alternative found",
			})
		}
	}

	return suggestions, nil
}

// ResolveJob applies a specific resolution action to a job in a conflict.
func (cr *ConflictResolver) ResolveJob(jobID uint, action string, alternativeProgramID *uint) (*ResolveResult, error) {
	var job models.DVRJob
	if err := cr.db.First(&job, jobID).Error; err != nil {
		return nil, err
	}

	switch action {
	case "cancel":
		if err := cr.db.Model(&job).Updates(map[string]interface{}{
			"status":    "cancelled",
			"cancelled": true,
		}).Error; err != nil {
			return nil, err
		}
		logger.Infof("conflict_resolver: cancelled job %d (%s)", job.ID, job.Title)
		return &ResolveResult{
			Resolved: true,
			Action:   "cancelled",
			JobID:    job.ID,
			Message:  "Job cancelled due to conflict",
		}, nil

	case "reschedule":
		if alternativeProgramID == nil {
			return &ResolveResult{
				Resolved: false,
				Action:   "reschedule",
				JobID:    job.ID,
				Message:  "No alternative program specified",
			}, nil
		}

		var program models.Program
		if err := cr.db.First(&program, *alternativeProgramID).Error; err != nil {
			return &ResolveResult{
				Resolved: false,
				Action:   "reschedule",
				JobID:    job.ID,
				Message:  "Alternative program not found",
			}, nil
		}

		// Resolve channel DB ID from ChannelID string.
		var channel models.Channel
		channelDBID := job.ChannelID
		if err := cr.db.Where("channel_id = ?", program.ChannelID).First(&channel).Error; err == nil {
			channelDBID = channel.ID
		}

		// Create a new job for the alternative airing.
		newJob := models.DVRJob{
			UserID:        job.UserID,
			RuleID:        job.RuleID,
			ChannelID:     channelDBID,
			ProgramID:     &program.ID,
			Title:         program.Title,
			Subtitle:      program.Subtitle,
			Description:   program.Description,
			StartTime:     program.Start,
			EndTime:       program.End,
			Status:        "scheduled",
			Priority:      job.Priority,
			QualityPreset: job.QualityPreset,
			PaddingStart:  job.PaddingStart,
			PaddingEnd:    job.PaddingEnd,
			MaxRetries:    job.MaxRetries,
			ChannelName:   channel.Name,
			ChannelLogo:   channel.Logo,
			Category:      program.Category,
			EpisodeNum:    program.EpisodeNum,
			IsMovie:       program.IsMovie,
			IsSports:      program.IsSports,
			SeriesRecord:  job.SeriesRecord,
		}

		if err := cr.db.Create(&newJob).Error; err != nil {
			return nil, err
		}

		// Cancel the old job.
		cr.db.Model(&job).Updates(map[string]interface{}{
			"status":    "cancelled",
			"cancelled": true,
		})

		logger.Infof("conflict_resolver: rescheduled job %d -> new job %d (%s on ch %v at %s)",
			job.ID, newJob.ID, newJob.Title, newJob.ChannelID, newJob.StartTime.Format(time.RFC3339))

		return &ResolveResult{
			Resolved: true,
			Action:   "rescheduled",
			JobID:    job.ID,
			Message:  "Job rescheduled to alternative airing",
			NewJobID: &newJob.ID,
		}, nil

	case "keep":
		return &ResolveResult{
			Resolved: true,
			Action:   "kept",
			JobID:    job.ID,
			Message:  "Job kept as-is (higher priority)",
		}, nil

	default:
		return &ResolveResult{
			Resolved: false,
			Action:   action,
			JobID:    job.ID,
			Message:  "Unknown action: " + action,
		}, nil
	}
}

// AutoResolve attempts to automatically resolve all conflicts by applying
// the generated suggestions: keep high-priority jobs, reschedule or cancel
// overflow jobs.
func (cr *ConflictResolver) AutoResolve(userID uint) (*AutoResolveResult, error) {
	conflicts, err := cr.ResolveConflicts(userID)
	if err != nil {
		return nil, err
	}

	result := &AutoResolveResult{
		TotalConflicts: len(conflicts),
	}

	for _, conflict := range conflicts {
		for _, suggestion := range conflict.Suggestions {
			if suggestion.Action == "keep" {
				result.Actions = append(result.Actions, ResolveResult{
					Resolved: true,
					Action:   "kept",
					JobID:    suggestion.JobID,
					Message:  suggestion.Reason,
				})
				continue
			}

			var altID *uint
			if suggestion.Alternative != nil {
				altID = &suggestion.Alternative.ProgramID
			}

			res, err := cr.ResolveJob(suggestion.JobID, suggestion.Action, altID)
			if err != nil {
				logger.Warnf("conflict_resolver: auto-resolve failed for job %d: %v", suggestion.JobID, err)
				result.Actions = append(result.Actions, ResolveResult{
					Resolved: false,
					Action:   suggestion.Action,
					JobID:    suggestion.JobID,
					Message:  err.Error(),
				})
				continue
			}
			result.Actions = append(result.Actions, *res)
			if res.Resolved {
				result.Resolved++
			}
		}
	}

	// Recount remaining conflicts after resolution.
	remaining, _ := cr.ResolveConflicts(userID)
	result.Remaining = len(remaining)

	return result, nil
}
