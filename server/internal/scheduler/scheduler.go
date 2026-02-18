// Package scheduler provides a cron-style task scheduling system with
// support for 5-field cron expressions (minute, hour, day, month, weekday),
// manual triggering, per-task enable/disable, execution history, and
// configurable timeouts.
package scheduler

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// TaskFunc is the function executed when a scheduled task fires.
// It receives a context that is cancelled when the task times out
// or the scheduler shuts down.
type TaskFunc func(ctx context.Context) error

// TaskStatus represents the current state of a task.
type TaskStatus string

const (
	TaskStatusIdle    TaskStatus = "idle"
	TaskStatusRunning TaskStatus = "running"
)

// TaskRunResult records the outcome of a single task execution.
type TaskRunResult struct {
	StartedAt  time.Time  `json:"startedAt"`
	FinishedAt time.Time  `json:"finishedAt"`
	Duration   string     `json:"duration"`
	Success    bool       `json:"success"`
	Error      string     `json:"error,omitempty"`
	Trigger    string     `json:"trigger"` // "scheduled" or "manual"
}

// TaskConfig holds the configurable properties of a scheduled task.
type TaskConfig struct {
	Schedule string `json:"schedule"` // cron expression (5 fields)
	Enabled  bool   `json:"enabled"`
	Timeout  int    `json:"timeout"` // seconds; 0 = no timeout
}

// TaskInfo provides a read-only snapshot of a task's current state.
type TaskInfo struct {
	ID          string          `json:"id"`
	Name        string          `json:"name"`
	Description string          `json:"description"`
	Schedule    string          `json:"schedule"`
	Enabled     bool            `json:"enabled"`
	Timeout     int             `json:"timeout"`
	Status      TaskStatus      `json:"status"`
	LastRun     *time.Time      `json:"lastRun"`
	NextRun     *time.Time      `json:"nextRun"`
	LastResult  *TaskRunResult  `json:"lastResult,omitempty"`
	RunCount    int             `json:"runCount"`
	FailCount   int             `json:"failCount"`
	History     []TaskRunResult `json:"history,omitempty"`
}

// task is the internal representation of a scheduled task.
type task struct {
	id          string
	name        string
	description string
	schedule    string // cron expression
	enabled     bool
	timeout     time.Duration
	handler     TaskFunc
	status      TaskStatus
	history     []TaskRunResult // most recent first, capped at maxHistory
	runCount    int
	failCount   int
	cancel      context.CancelFunc // cancels a running execution
}

const maxHistory = 50

// TaskScheduler manages a collection of scheduled tasks.
type TaskScheduler struct {
	mu      sync.Mutex
	tasks   map[string]*task
	order   []string // insertion order for consistent listing
	ctx     context.Context
	cancel  context.CancelFunc
	wg      sync.WaitGroup
	started bool
}

// NewTaskScheduler creates a new scheduler. Call Start() to begin executing tasks.
func NewTaskScheduler() *TaskScheduler {
	ctx, cancel := context.WithCancel(context.Background())
	return &TaskScheduler{
		tasks:  make(map[string]*task),
		ctx:    ctx,
		cancel: cancel,
	}
}

// RegisterTask adds a task to the scheduler. Must be called before Start().
// schedule is a 5-field cron expression: minute hour day month weekday.
func (ts *TaskScheduler) RegisterTask(id, name, description, schedule string, timeout time.Duration, handler TaskFunc) {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	if _, exists := ts.tasks[id]; exists {
		logger.Warnf("[scheduler] task %q already registered, skipping", id)
		return
	}

	ts.tasks[id] = &task{
		id:          id,
		name:        name,
		description: description,
		schedule:    schedule,
		enabled:     true,
		timeout:     timeout,
		handler:     handler,
		status:      TaskStatusIdle,
		history:     make([]TaskRunResult, 0, maxHistory),
	}
	ts.order = append(ts.order, id)

	logger.Infof("[scheduler] registered task %q (%s) schedule=%s", id, name, schedule)
}

// Start begins the scheduling loop. Each task gets its own goroutine.
func (ts *TaskScheduler) Start() {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	if ts.started {
		return
	}
	ts.started = true

	for _, id := range ts.order {
		t := ts.tasks[id]
		ts.wg.Add(1)
		go ts.taskLoop(t)
	}

	logger.Infof("[scheduler] started with %d tasks", len(ts.tasks))
}

// Stop gracefully shuts down the scheduler and waits for all running tasks.
func (ts *TaskScheduler) Stop() {
	logger.Info("[scheduler] shutting down...")
	ts.cancel()
	ts.wg.Wait()
	logger.Info("[scheduler] shutdown complete")
}

// TriggerTask manually triggers immediate execution of a task, regardless
// of its schedule or enabled state. Returns an error if the task is already
// running or does not exist.
func (ts *TaskScheduler) TriggerTask(id string) error {
	ts.mu.Lock()
	t, ok := ts.tasks[id]
	if !ok {
		ts.mu.Unlock()
		return fmt.Errorf("task %q not found", id)
	}
	if t.status == TaskStatusRunning {
		ts.mu.Unlock()
		return fmt.Errorf("task %q is already running", id)
	}
	ts.mu.Unlock()

	// Execute in a goroutine so the caller doesn't block.
	go ts.executeTask(t, "manual")
	return nil
}

// UpdateTaskConfig updates the schedule, enabled, and timeout for a task.
func (ts *TaskScheduler) UpdateTaskConfig(id string, cfg TaskConfig) error {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	t, ok := ts.tasks[id]
	if !ok {
		return fmt.Errorf("task %q not found", id)
	}

	// Validate the new schedule if provided.
	if cfg.Schedule != "" {
		if _, err := parseCron(cfg.Schedule); err != nil {
			return fmt.Errorf("invalid schedule %q: %w", cfg.Schedule, err)
		}
		t.schedule = cfg.Schedule
	}

	t.enabled = cfg.Enabled

	if cfg.Timeout >= 0 {
		t.timeout = time.Duration(cfg.Timeout) * time.Second
	}

	logger.Infof("[scheduler] updated task %q: schedule=%s enabled=%v timeout=%s",
		id, t.schedule, t.enabled, t.timeout)

	return nil
}

// GetTask returns a snapshot of a single task including its full history.
func (ts *TaskScheduler) GetTask(id string) (*TaskInfo, error) {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	t, ok := ts.tasks[id]
	if !ok {
		return nil, fmt.Errorf("task %q not found", id)
	}

	return ts.taskToInfo(t, true), nil
}

// ListTasks returns a snapshot of all tasks (without full history).
func (ts *TaskScheduler) ListTasks() []TaskInfo {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	result := make([]TaskInfo, 0, len(ts.order))
	for _, id := range ts.order {
		t := ts.tasks[id]
		result = append(result, *ts.taskToInfo(t, false))
	}
	return result
}

// RecentHistory returns the most recent N runs across all tasks, sorted
// by start time (most recent first).
func (ts *TaskScheduler) RecentHistory(limit int) []map[string]interface{} {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	// Collect all history entries with task info.
	type entry struct {
		taskID   string
		taskName string
		result   TaskRunResult
	}
	var all []entry
	for _, id := range ts.order {
		t := ts.tasks[id]
		for _, r := range t.history {
			all = append(all, entry{taskID: id, taskName: t.name, result: r})
		}
	}

	// Sort by start time descending.
	for i := 0; i < len(all); i++ {
		for j := i + 1; j < len(all); j++ {
			if all[j].result.StartedAt.After(all[i].result.StartedAt) {
				all[i], all[j] = all[j], all[i]
			}
		}
	}

	if limit > 0 && len(all) > limit {
		all = all[:limit]
	}

	result := make([]map[string]interface{}, len(all))
	for i, e := range all {
		result[i] = map[string]interface{}{
			"taskId":     e.taskID,
			"taskName":   e.taskName,
			"startedAt":  e.result.StartedAt,
			"finishedAt": e.result.FinishedAt,
			"duration":   e.result.Duration,
			"success":    e.result.Success,
			"error":      e.result.Error,
			"trigger":    e.result.Trigger,
		}
	}
	return result
}

// GetAllConfigs returns a map of task ID -> TaskConfig for serialization.
func (ts *TaskScheduler) GetAllConfigs() map[string]TaskConfig {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	configs := make(map[string]TaskConfig, len(ts.tasks))
	for id, t := range ts.tasks {
		configs[id] = TaskConfig{
			Schedule: t.schedule,
			Enabled:  t.enabled,
			Timeout:  int(t.timeout.Seconds()),
		}
	}
	return configs
}

// ApplyConfigs applies persisted configs to the registered tasks.
func (ts *TaskScheduler) ApplyConfigs(configs map[string]TaskConfig) {
	ts.mu.Lock()
	defer ts.mu.Unlock()

	for id, cfg := range configs {
		t, ok := ts.tasks[id]
		if !ok {
			continue // task no longer exists, skip
		}

		if cfg.Schedule != "" {
			if _, err := parseCron(cfg.Schedule); err == nil {
				t.schedule = cfg.Schedule
			} else {
				logger.Warnf("[scheduler] ignoring invalid persisted schedule for %q: %s", id, cfg.Schedule)
			}
		}

		t.enabled = cfg.Enabled

		if cfg.Timeout >= 0 {
			t.timeout = time.Duration(cfg.Timeout) * time.Second
		}
	}

	logger.Infof("[scheduler] applied %d persisted task configs", len(configs))
}

// --- Internal ---

// taskToInfo converts an internal task to a TaskInfo snapshot.
// If includeHistory is true, the full history is included.
func (ts *TaskScheduler) taskToInfo(t *task, includeHistory bool) *TaskInfo {
	info := &TaskInfo{
		ID:          t.id,
		Name:        t.name,
		Description: t.description,
		Schedule:    t.schedule,
		Enabled:     t.enabled,
		Timeout:     int(t.timeout.Seconds()),
		Status:      t.status,
		RunCount:    t.runCount,
		FailCount:   t.failCount,
	}

	if len(t.history) > 0 {
		last := t.history[0] // most recent first
		info.LastResult = &last
		info.LastRun = &last.StartedAt
	}

	// Calculate next run time.
	if t.enabled {
		if fields, err := parseCron(t.schedule); err == nil {
			next := nextCronTime(time.Now(), fields)
			info.NextRun = &next
		}
	}

	if includeHistory {
		info.History = make([]TaskRunResult, len(t.history))
		copy(info.History, t.history)
	}

	return info
}

// taskLoop is the main loop for a single task. It sleeps until the next
// scheduled time, then executes the task.
func (ts *TaskScheduler) taskLoop(t *task) {
	defer ts.wg.Done()

	for {
		ts.mu.Lock()
		enabled := t.enabled
		schedule := t.schedule
		ts.mu.Unlock()

		if !enabled {
			// Disabled task: just wait a bit and check again.
			select {
			case <-ts.ctx.Done():
				return
			case <-time.After(10 * time.Second):
				continue
			}
		}

		fields, err := parseCron(schedule)
		if err != nil {
			logger.Errorf("[scheduler] task %q has invalid schedule %q: %v", t.id, schedule, err)
			select {
			case <-ts.ctx.Done():
				return
			case <-time.After(60 * time.Second):
				continue
			}
		}

		now := time.Now()
		next := nextCronTime(now, fields)
		sleepDuration := next.Sub(now)

		select {
		case <-ts.ctx.Done():
			return
		case <-time.After(sleepDuration):
			// Check if still enabled (config may have changed while sleeping).
			ts.mu.Lock()
			stillEnabled := t.enabled
			ts.mu.Unlock()

			if stillEnabled {
				ts.executeTask(t, "scheduled")
			}
		}
	}
}

// executeTask runs the task's handler with timeout and records the result.
func (ts *TaskScheduler) executeTask(t *task, trigger string) {
	ts.mu.Lock()
	if t.status == TaskStatusRunning {
		ts.mu.Unlock()
		return
	}
	t.status = TaskStatusRunning
	timeout := t.timeout
	ts.mu.Unlock()

	startedAt := time.Now()
	logger.Infof("[scheduler] executing task %q (trigger=%s)", t.id, trigger)

	var ctx context.Context
	var cancel context.CancelFunc
	if timeout > 0 {
		ctx, cancel = context.WithTimeout(ts.ctx, timeout)
	} else {
		ctx, cancel = context.WithCancel(ts.ctx)
	}

	ts.mu.Lock()
	t.cancel = cancel
	ts.mu.Unlock()

	// Execute with panic recovery.
	err := safeExecute(ctx, t.handler)
	cancel()

	finishedAt := time.Now()
	duration := finishedAt.Sub(startedAt)

	result := TaskRunResult{
		StartedAt:  startedAt,
		FinishedAt: finishedAt,
		Duration:   formatDuration(duration),
		Success:    err == nil,
		Trigger:    trigger,
	}
	if err != nil {
		result.Error = err.Error()
	}

	ts.mu.Lock()
	t.status = TaskStatusIdle
	t.cancel = nil
	t.runCount++
	if err != nil {
		t.failCount++
		logger.Warnf("[scheduler] task %q failed (took %s): %v", t.id, result.Duration, err)
	} else {
		logger.Infof("[scheduler] task %q completed (took %s)", t.id, result.Duration)
	}

	// Prepend to history (most recent first), cap at maxHistory.
	t.history = append([]TaskRunResult{result}, t.history...)
	if len(t.history) > maxHistory {
		t.history = t.history[:maxHistory]
	}
	ts.mu.Unlock()
}

// safeExecute runs the handler with panic recovery.
func safeExecute(ctx context.Context, handler TaskFunc) (err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("panic: %v", r)
		}
	}()
	return handler(ctx)
}

// formatDuration formats a duration into a human-readable string.
func formatDuration(d time.Duration) string {
	if d < time.Second {
		return fmt.Sprintf("%dms", d.Milliseconds())
	}
	if d < time.Minute {
		return fmt.Sprintf("%.1fs", d.Seconds())
	}
	mins := int(d.Minutes())
	secs := int(d.Seconds()) % 60
	if mins < 60 {
		return fmt.Sprintf("%dm%ds", mins, secs)
	}
	hours := mins / 60
	mins = mins % 60
	return fmt.Sprintf("%dh%dm", hours, mins)
}

// ============ Cron Expression Parser ============

// cronFields represents a parsed 5-field cron expression.
type cronFields struct {
	minutes  []int // 0-59
	hours    []int // 0-23
	days     []int // 1-31
	months   []int // 1-12
	weekdays []int // 0-6 (0=Sunday)
}

// parseCron parses a 5-field cron expression.
// Supports: exact values (5), wildcards (*), intervals (*/5), ranges (1-5), lists (1,3,5).
func parseCron(expr string) (*cronFields, error) {
	parts := strings.Fields(strings.TrimSpace(expr))
	if len(parts) != 5 {
		return nil, fmt.Errorf("expected 5 fields, got %d", len(parts))
	}

	minutes, err := parseField(parts[0], 0, 59)
	if err != nil {
		return nil, fmt.Errorf("minute field: %w", err)
	}

	hours, err := parseField(parts[1], 0, 23)
	if err != nil {
		return nil, fmt.Errorf("hour field: %w", err)
	}

	days, err := parseField(parts[2], 1, 31)
	if err != nil {
		return nil, fmt.Errorf("day field: %w", err)
	}

	months, err := parseField(parts[3], 1, 12)
	if err != nil {
		return nil, fmt.Errorf("month field: %w", err)
	}

	weekdays, err := parseField(parts[4], 0, 6)
	if err != nil {
		return nil, fmt.Errorf("weekday field: %w", err)
	}

	return &cronFields{
		minutes:  minutes,
		hours:    hours,
		days:     days,
		months:   months,
		weekdays: weekdays,
	}, nil
}

// parseField parses a single cron field into a sorted list of values.
func parseField(field string, min, max int) ([]int, error) {
	var result []int

	// Split on commas for list support (e.g., "1,3,5")
	for _, part := range strings.Split(field, ",") {
		part = strings.TrimSpace(part)

		// Check for interval: */N or N-M/S
		if strings.Contains(part, "/") {
			pieces := strings.SplitN(part, "/", 2)
			step, err := strconv.Atoi(pieces[1])
			if err != nil || step <= 0 {
				return nil, fmt.Errorf("invalid step %q", pieces[1])
			}

			rangeStart, rangeEnd := min, max
			if pieces[0] != "*" {
				// Parse range before the step
				rangeStart, rangeEnd, err = parseRange(pieces[0], min, max)
				if err != nil {
					return nil, err
				}
			}

			for v := rangeStart; v <= rangeEnd; v += step {
				result = append(result, v)
			}
			continue
		}

		// Check for wildcard
		if part == "*" {
			for v := min; v <= max; v++ {
				result = append(result, v)
			}
			continue
		}

		// Check for range: N-M
		if strings.Contains(part, "-") {
			rangeStart, rangeEnd, err := parseRange(part, min, max)
			if err != nil {
				return nil, err
			}
			for v := rangeStart; v <= rangeEnd; v++ {
				result = append(result, v)
			}
			continue
		}

		// Single value
		v, err := strconv.Atoi(part)
		if err != nil {
			return nil, fmt.Errorf("invalid value %q", part)
		}
		if v < min || v > max {
			return nil, fmt.Errorf("value %d out of range [%d, %d]", v, min, max)
		}
		result = append(result, v)
	}

	if len(result) == 0 {
		return nil, fmt.Errorf("empty field")
	}

	return result, nil
}

// parseRange parses "N-M" into start and end values.
func parseRange(s string, min, max int) (int, int, error) {
	parts := strings.SplitN(s, "-", 2)
	if len(parts) != 2 {
		return 0, 0, fmt.Errorf("invalid range %q", s)
	}

	start, err := strconv.Atoi(parts[0])
	if err != nil {
		return 0, 0, fmt.Errorf("invalid range start %q", parts[0])
	}

	end, err := strconv.Atoi(parts[1])
	if err != nil {
		return 0, 0, fmt.Errorf("invalid range end %q", parts[1])
	}

	if start < min || end > max || start > end {
		return 0, 0, fmt.Errorf("range %d-%d out of bounds [%d, %d]", start, end, min, max)
	}

	return start, end, nil
}

// nextCronTime finds the next time after 'from' that matches the cron fields.
func nextCronTime(from time.Time, fields *cronFields) time.Time {
	// Start from the next minute boundary.
	t := from.Truncate(time.Minute).Add(time.Minute)

	// Search up to 2 years ahead (to handle edge cases).
	limit := t.Add(2 * 365 * 24 * time.Hour)

	for t.Before(limit) {
		if !contains(fields.months, int(t.Month())) {
			// Skip to next month.
			t = time.Date(t.Year(), t.Month()+1, 1, 0, 0, 0, 0, t.Location())
			continue
		}

		if !contains(fields.days, t.Day()) {
			// Skip to next day.
			t = time.Date(t.Year(), t.Month(), t.Day()+1, 0, 0, 0, 0, t.Location())
			continue
		}

		if !contains(fields.weekdays, int(t.Weekday())) {
			// Skip to next day.
			t = time.Date(t.Year(), t.Month(), t.Day()+1, 0, 0, 0, 0, t.Location())
			continue
		}

		if !contains(fields.hours, t.Hour()) {
			// Skip to next hour.
			t = time.Date(t.Year(), t.Month(), t.Day(), t.Hour()+1, 0, 0, 0, t.Location())
			continue
		}

		if !contains(fields.minutes, t.Minute()) {
			// Skip to next minute.
			t = t.Add(time.Minute)
			continue
		}

		return t
	}

	// Fallback: this should rarely happen with valid cron expressions.
	return from.Add(time.Hour)
}

// contains checks if a sorted slice contains a value.
func contains(s []int, v int) bool {
	for _, x := range s {
		if x == v {
			return true
		}
	}
	return false
}
