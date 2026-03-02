// Package jobq provides a background job queue system with typed workers,
// priority ordering, retry with exponential backoff, scheduling, and
// idle-only execution support. Modeled after Channels DVR's jobq system.
package jobq

import (
	"container/heap"
	"context"
	"fmt"
	"math"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/openflix/openflix-server/internal/logger"
)

// JobStatus represents the current state of a job.
type JobStatus string

const (
	StatusPending   JobStatus = "pending"
	StatusRunning   JobStatus = "running"
	StatusCompleted JobStatus = "completed"
	StatusFailed    JobStatus = "failed"
	StatusCancelled JobStatus = "cancelled"
)

// JobFunc is the handler function executed for a job. The context is cancelled
// when the job is cancelled or the queue is shutting down.
type JobFunc func(ctx context.Context, job *Job) error

// WorkerConfig defines the configuration for a named worker type.
type WorkerConfig struct {
	Name        string        // Unique worker name
	Concurrency int           // Max concurrent jobs for this worker (min 1)
	IdleOnly    bool          // Only run when the system is idle
	MaxRetries  int           // Max retry attempts (0 = no retries)
	RetryDelay  time.Duration // Base delay between retries (exponential backoff)
}

// Job represents an individual unit of work submitted to the queue.
type Job struct {
	ID          string      `json:"id"`
	WorkerName  string      `json:"worker_name"`
	Priority    int         `json:"priority"`
	Payload     interface{} `json:"payload"`
	Status      JobStatus   `json:"status"`
	CreatedAt   time.Time   `json:"created_at"`
	StartedAt   *time.Time  `json:"started_at,omitempty"`
	CompletedAt *time.Time  `json:"completed_at,omitempty"`
	RetryCount  int         `json:"retry_count"`
	MaxRetries  int         `json:"max_retries"`
	LastError   string      `json:"last_error,omitempty"`
	ScheduleAt  *time.Time  `json:"schedule_at,omitempty"`

	cancel context.CancelFunc // cancellation function for running jobs
}

// QueueStats holds aggregate statistics about the job queue.
type QueueStats struct {
	TotalJobs     int            `json:"total_jobs"`
	PendingJobs   int            `json:"pending_jobs"`
	RunningJobs   int            `json:"running_jobs"`
	CompletedJobs int            `json:"completed_jobs"`
	FailedJobs    int            `json:"failed_jobs"`
	CancelledJobs int            `json:"cancelled_jobs"`
	WorkerStats   map[string]int `json:"worker_stats"` // running count per worker
}

// JobOption is a functional option for configuring a job at submission time.
type JobOption func(*Job)

// WithPriority sets the priority of a job. Higher values are processed first.
func WithPriority(p int) JobOption {
	return func(j *Job) {
		j.Priority = p
	}
}

// WithScheduleAt schedules a job to run at or after the given time.
func WithScheduleAt(t time.Time) JobOption {
	return func(j *Job) {
		j.ScheduleAt = &t
	}
}

// WithID sets a specific ID for the job instead of generating one.
func WithID(id string) JobOption {
	return func(j *Job) {
		j.ID = id
	}
}

// worker holds the internal state for a registered worker type.
type worker struct {
	config  WorkerConfig
	handler JobFunc
	jobs    priorityQueue // min-heap ordered by negative priority (highest first)
	notify  chan struct{} // signals the dispatcher that new work is available
	running int          // number of currently running jobs for this worker
}

// JobQueue is the main queue manager. It coordinates workers, dispatchers,
// and the lifecycle of all submitted jobs.
type JobQueue struct {
	mu      sync.Mutex
	workers map[string]*worker
	allJobs map[string]*Job // all jobs by ID for status lookups

	idle     bool          // whether the system is currently idle
	idleCh   chan struct{} // closed when system becomes idle, recreated when busy
	idleMu   sync.RWMutex

	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup

	started bool
}

// NewJobQueue creates a new job queue. Call Start() to begin processing.
func NewJobQueue() *JobQueue {
	ctx, cancel := context.WithCancel(context.Background())
	jq := &JobQueue{
		workers: make(map[string]*worker),
		allJobs: make(map[string]*Job),
		idleCh:  make(chan struct{}),
		ctx:     ctx,
		cancel:  cancel,
	}
	return jq
}

// RegisterWorker registers a named worker type with its handler. Must be
// called before Start(). Panics if a worker with the same name is already
// registered.
func (jq *JobQueue) RegisterWorker(config WorkerConfig, handler JobFunc) {
	jq.mu.Lock()
	defer jq.mu.Unlock()

	if jq.started {
		panic("jobq: cannot register worker after Start()")
	}

	if _, exists := jq.workers[config.Name]; exists {
		panic(fmt.Sprintf("jobq: worker %q already registered", config.Name))
	}

	if config.Concurrency < 1 {
		config.Concurrency = 1
	}

	if config.RetryDelay <= 0 {
		config.RetryDelay = time.Second
	}

	w := &worker{
		config:  config,
		handler: handler,
		jobs:    make(priorityQueue, 0),
		notify:  make(chan struct{}, 1),
	}
	heap.Init(&w.jobs)
	jq.workers[config.Name] = w

	logger.Infof("[jobq] registered worker %q (concurrency=%d, idle_only=%v, max_retries=%d)",
		config.Name, config.Concurrency, config.IdleOnly, config.MaxRetries)
}

// Submit adds a new job to the queue. Returns the job ID. If a job with the
// given WithID already exists, the submission is silently ignored and the
// existing ID is returned.
func (jq *JobQueue) Submit(workerName string, payload interface{}, opts ...JobOption) string {
	jq.mu.Lock()
	defer jq.mu.Unlock()

	w, ok := jq.workers[workerName]
	if !ok {
		logger.Errorf("[jobq] unknown worker %q, dropping job", workerName)
		return ""
	}

	job := &Job{
		ID:         uuid.New().String(),
		WorkerName: workerName,
		Payload:    payload,
		Status:     StatusPending,
		CreatedAt:  time.Now(),
		MaxRetries: w.config.MaxRetries,
	}

	for _, opt := range opts {
		opt(job)
	}

	// Deduplicate by ID if caller specified one.
	if existing, exists := jq.allJobs[job.ID]; exists {
		if existing.Status == StatusPending || existing.Status == StatusRunning {
			logger.Debugf("[jobq] job %s already exists (status=%s), skipping", job.ID, existing.Status)
			return existing.ID
		}
		// Allow resubmission of completed/failed/cancelled jobs with the same ID.
	}

	jq.allJobs[job.ID] = job

	heap.Push(&w.jobs, &jobEntry{job: job})

	// Signal the dispatcher.
	select {
	case w.notify <- struct{}{}:
	default:
	}

	logger.Debugf("[jobq] submitted job %s to worker %q (priority=%d)", job.ID, workerName, job.Priority)
	return job.ID
}

// Cancel cancels a pending or running job. Pending jobs are removed from the
// queue. Running jobs have their context cancelled.
func (jq *JobQueue) Cancel(jobID string) {
	jq.mu.Lock()
	defer jq.mu.Unlock()

	job, ok := jq.allJobs[jobID]
	if !ok {
		return
	}

	switch job.Status {
	case StatusPending:
		job.Status = StatusCancelled
		now := time.Now()
		job.CompletedAt = &now
		logger.Infof("[jobq] cancelled pending job %s", jobID)
	case StatusRunning:
		if job.cancel != nil {
			job.cancel()
		}
		job.Status = StatusCancelled
		now := time.Now()
		job.CompletedAt = &now
		logger.Infof("[jobq] cancelled running job %s", jobID)
	}
}

// GetStatus returns a snapshot of a job's current state. Returns nil if
// the job does not exist.
func (jq *JobQueue) GetStatus(jobID string) *Job {
	jq.mu.Lock()
	defer jq.mu.Unlock()

	job, ok := jq.allJobs[jobID]
	if !ok {
		return nil
	}

	// Return a copy to avoid races.
	cp := *job
	cp.cancel = nil
	return &cp
}

// ListJobs returns all jobs matching the given worker name and status.
// Pass an empty workerName to match all workers. Pass an empty status
// to match all statuses.
func (jq *JobQueue) ListJobs(workerName string, status JobStatus) []*Job {
	jq.mu.Lock()
	defer jq.mu.Unlock()

	var result []*Job
	for _, job := range jq.allJobs {
		if workerName != "" && job.WorkerName != workerName {
			continue
		}
		if status != "" && job.Status != status {
			continue
		}
		cp := *job
		cp.cancel = nil
		result = append(result, &cp)
	}
	return result
}

// Start begins processing jobs. Launches one dispatcher goroutine per
// registered worker.
func (jq *JobQueue) Start() {
	jq.mu.Lock()
	defer jq.mu.Unlock()

	if jq.started {
		return
	}
	jq.started = true

	for name, w := range jq.workers {
		jq.wg.Add(1)
		go jq.dispatcher(name, w)
	}

	// Start a periodic scheduler that wakes dispatchers for scheduled jobs.
	jq.wg.Add(1)
	go jq.scheduler()

	logger.Infof("[jobq] started with %d workers", len(jq.workers))
}

// Stop gracefully shuts down the queue. Waits for running jobs to finish
// or be cancelled. Blocks until all dispatcher goroutines exit.
func (jq *JobQueue) Stop() {
	logger.Info("[jobq] shutting down...")
	jq.cancel()
	jq.wg.Wait()
	logger.Info("[jobq] shutdown complete")
}

// SetIdle notifies the queue whether the system is currently idle (no active
// user sessions). Idle-only workers will only dispatch jobs when idle is true.
func (jq *JobQueue) SetIdle(idle bool) {
	jq.idleMu.Lock()
	defer jq.idleMu.Unlock()

	if jq.idle == idle {
		return
	}

	jq.idle = idle

	if idle {
		logger.Debug("[jobq] system is now idle")
		// Close the channel to unblock all idle waiters.
		close(jq.idleCh)
	} else {
		logger.Debug("[jobq] system is now busy")
		// Create a new channel for future idle waits.
		jq.idleCh = make(chan struct{})
	}

	// Wake all workers so idle-only workers can start/stop.
	jq.mu.Lock()
	for _, w := range jq.workers {
		select {
		case w.notify <- struct{}{}:
		default:
		}
	}
	jq.mu.Unlock()
}

// isIdle returns the current idle state and channel.
func (jq *JobQueue) isIdle() (bool, <-chan struct{}) {
	jq.idleMu.RLock()
	defer jq.idleMu.RUnlock()
	return jq.idle, jq.idleCh
}

// Stats returns aggregate statistics about the queue.
func (jq *JobQueue) Stats() QueueStats {
	jq.mu.Lock()
	defer jq.mu.Unlock()

	stats := QueueStats{
		WorkerStats: make(map[string]int),
	}

	for _, job := range jq.allJobs {
		stats.TotalJobs++
		switch job.Status {
		case StatusPending:
			stats.PendingJobs++
		case StatusRunning:
			stats.RunningJobs++
		case StatusCompleted:
			stats.CompletedJobs++
		case StatusFailed:
			stats.FailedJobs++
		case StatusCancelled:
			stats.CancelledJobs++
		}
	}

	for name, w := range jq.workers {
		stats.WorkerStats[name] = w.running
	}

	return stats
}

// dispatcher is the main loop for a single worker type. It picks jobs from
// the worker's priority queue and executes them, respecting concurrency
// limits, idle-only mode, and scheduling.
func (jq *JobQueue) dispatcher(name string, w *worker) {
	defer jq.wg.Done()
	logger.Debugf("[jobq] dispatcher started for worker %q", name)

	// sem limits concurrency for this worker.
	sem := make(chan struct{}, w.config.Concurrency)

	for {
		select {
		case <-jq.ctx.Done():
			logger.Debugf("[jobq] dispatcher %q stopping", name)
			// Drain the semaphore to wait for running jobs.
			for i := 0; i < w.config.Concurrency; i++ {
				sem <- struct{}{}
			}
			return

		case <-w.notify:
			// Process all ready jobs up to the concurrency limit.
			jq.processReady(name, w, sem)
		}
	}
}

// processReady attempts to dispatch all ready jobs for a worker.
func (jq *JobQueue) processReady(name string, w *worker, sem chan struct{}) {
	for {
		select {
		case <-jq.ctx.Done():
			return
		default:
		}

		// If this is an idle-only worker, check idle state.
		if w.config.IdleOnly {
			idle, idleCh := jq.isIdle()
			if !idle {
				// Wait for idle or shutdown, then re-notify.
				go func() {
					select {
					case <-idleCh:
					case <-jq.ctx.Done():
						return
					}
					select {
					case w.notify <- struct{}{}:
					default:
					}
				}()
				return
			}
		}

		// Try to acquire a concurrency slot (non-blocking).
		select {
		case sem <- struct{}{}:
		default:
			// At capacity. Will be re-notified when a job completes.
			return
		}

		// Pop the next ready job.
		job := jq.popReady(w)
		if job == nil {
			// No ready jobs, release the slot.
			<-sem
			return
		}

		// Launch the job.
		jq.wg.Add(1)
		go func(j *Job) {
			defer jq.wg.Done()
			defer func() {
				<-sem
				// After completing, try to process more jobs.
				select {
				case w.notify <- struct{}{}:
				default:
				}
			}()
			jq.executeJob(w, j)
		}(job)
	}
}

// popReady finds and removes the highest-priority ready job from the
// worker's queue. Returns nil if no jobs are ready.
func (jq *JobQueue) popReady(w *worker) *Job {
	jq.mu.Lock()
	defer jq.mu.Unlock()

	now := time.Now()

	// Scan for the first ready job (heap is ordered by priority, but we
	// need to skip scheduled jobs that aren't ready yet and cancelled jobs).
	for w.jobs.Len() > 0 {
		entry := heap.Pop(&w.jobs).(*jobEntry)
		job := entry.job

		// Skip cancelled jobs.
		if job.Status == StatusCancelled {
			continue
		}

		// Check schedule time.
		if job.ScheduleAt != nil && job.ScheduleAt.After(now) {
			// Not ready yet, push it back.
			heap.Push(&w.jobs, entry)
			return nil
		}

		// Mark as running.
		job.Status = StatusRunning
		startTime := now
		job.StartedAt = &startTime
		w.running++

		return job
	}

	return nil
}

// executeJob runs a single job with its handler, handling panics, retries,
// and status updates.
func (jq *JobQueue) executeJob(w *worker, job *Job) {
	ctx, cancel := context.WithCancel(jq.ctx)
	defer cancel()

	// Store the cancel func on the job so Cancel() can use it.
	jq.mu.Lock()
	job.cancel = cancel
	jq.mu.Unlock()

	logger.Infof("[jobq] running job %s (worker=%s, attempt=%d/%d)",
		job.ID, job.WorkerName, job.RetryCount+1, job.MaxRetries+1)

	// Execute with panic recovery.
	err := jq.safeExecute(ctx, w.handler, job)

	jq.mu.Lock()
	defer jq.mu.Unlock()

	w.running--
	job.cancel = nil

	// If the job was cancelled while running, keep the cancelled status.
	if job.Status == StatusCancelled {
		return
	}

	if err != nil {
		job.LastError = err.Error()

		if job.RetryCount < job.MaxRetries {
			// Schedule a retry with exponential backoff.
			job.RetryCount++
			delay := w.config.RetryDelay * time.Duration(math.Pow(2, float64(job.RetryCount-1)))
			retryAt := time.Now().Add(delay)
			job.ScheduleAt = &retryAt
			job.Status = StatusPending
			job.StartedAt = nil

			heap.Push(&w.jobs, &jobEntry{job: job})

			logger.Warnf("[jobq] job %s failed (attempt %d/%d), retrying in %s: %v",
				job.ID, job.RetryCount, job.MaxRetries+1, delay, err)

			// Schedule a wake-up for the retry time.
			go func() {
				timer := time.NewTimer(delay)
				defer timer.Stop()
				select {
				case <-timer.C:
					select {
					case w.notify <- struct{}{}:
					default:
					}
				case <-jq.ctx.Done():
				}
			}()
		} else {
			// Max retries exhausted.
			job.Status = StatusFailed
			now := time.Now()
			job.CompletedAt = &now

			logger.Errorf("[jobq] job %s failed permanently after %d attempts: %v",
				job.ID, job.RetryCount+1, err)
		}
	} else {
		job.Status = StatusCompleted
		now := time.Now()
		job.CompletedAt = &now

		logger.Infof("[jobq] job %s completed successfully", job.ID)
	}
}

// safeExecute runs the handler with panic recovery.
func (jq *JobQueue) safeExecute(ctx context.Context, handler JobFunc, job *Job) (err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("panic: %v", r)
		}
	}()
	return handler(ctx, job)
}

// scheduler periodically checks for scheduled jobs that have become ready
// and wakes up the appropriate dispatchers.
func (jq *JobQueue) scheduler() {
	defer jq.wg.Done()

	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-jq.ctx.Done():
			return
		case <-ticker.C:
			jq.wakeScheduled()
		}
	}
}

// wakeScheduled checks each worker for scheduled jobs that are now ready
// and sends a notify signal if any are found.
func (jq *JobQueue) wakeScheduled() {
	jq.mu.Lock()
	defer jq.mu.Unlock()

	now := time.Now()

	for _, w := range jq.workers {
		if w.jobs.Len() == 0 {
			continue
		}

		// Peek at the top job. Since cancelled/completed jobs may still
		// be in the heap, just wake the dispatcher and let it sort things out.
		top := w.jobs[0].job
		if top.ScheduleAt != nil && top.ScheduleAt.After(now) {
			continue
		}

		select {
		case w.notify <- struct{}{}:
		default:
		}
	}
}

// --- Priority Queue (heap) implementation ---

// jobEntry wraps a Job for use in the priority queue heap.
type jobEntry struct {
	job   *Job
	index int // index in the heap, maintained by heap.Interface
}

// priorityQueue implements heap.Interface for job entries.
// Jobs are ordered by priority (highest first), then by creation time
// (oldest first) as a tiebreaker.
type priorityQueue []*jobEntry

func (pq priorityQueue) Len() int { return len(pq) }

func (pq priorityQueue) Less(i, j int) bool {
	// Higher priority first.
	if pq[i].job.Priority != pq[j].job.Priority {
		return pq[i].job.Priority > pq[j].job.Priority
	}
	// Same priority: older jobs first (FIFO within priority).
	return pq[i].job.CreatedAt.Before(pq[j].job.CreatedAt)
}

func (pq priorityQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
	pq[i].index = i
	pq[j].index = j
}

func (pq *priorityQueue) Push(x interface{}) {
	entry := x.(*jobEntry)
	entry.index = len(*pq)
	*pq = append(*pq, entry)
}

func (pq *priorityQueue) Pop() interface{} {
	old := *pq
	n := len(old)
	entry := old[n-1]
	old[n-1] = nil // avoid memory leak
	entry.index = -1
	*pq = old[:n-1]
	return entry
}
