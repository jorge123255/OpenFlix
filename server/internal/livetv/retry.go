package livetv

import (
	"context"
	"fmt"
	"math"
	"math/rand"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// RetryConfig holds configuration for retry behavior
type RetryConfig struct {
	MaxAttempts     int           // Maximum number of attempts (default: 3)
	InitialDelay    time.Duration // Initial delay between retries (default: 1s)
	MaxDelay        time.Duration // Maximum delay between retries (default: 30s)
	BackoffFactor   float64       // Multiplier for exponential backoff (default: 2.0)
	Jitter          bool          // Add random jitter to delays (default: true)
	RetryableErrors []string      // Error substrings that are retryable
}

// DefaultRetryConfig returns the default retry configuration
func DefaultRetryConfig() RetryConfig {
	return RetryConfig{
		MaxAttempts:   3,
		InitialDelay:  1 * time.Second,
		MaxDelay:      30 * time.Second,
		BackoffFactor: 2.0,
		Jitter:        true,
		RetryableErrors: []string{
			"timeout",
			"connection refused",
			"connection reset",
			"no such host",
			"temporary failure",
			"too many requests",
			"service unavailable",
			"bad gateway",
			"gateway timeout",
			"EOF",
			"i/o timeout",
		},
	}
}

// RetryResult holds the result of a retry operation
type RetryResult struct {
	Success      bool          `json:"success"`
	Attempts     int           `json:"attempts"`
	TotalTime    time.Duration `json:"totalTime"`
	LastError    error         `json:"-"`
	LastErrorStr string        `json:"lastError,omitempty"`
}

// Retrier handles retry logic for EPG operations
type Retrier struct {
	config RetryConfig
}

// NewRetrier creates a new Retrier with the given configuration
func NewRetrier(config RetryConfig) *Retrier {
	if config.MaxAttempts < 1 {
		config.MaxAttempts = 3
	}
	if config.InitialDelay == 0 {
		config.InitialDelay = 1 * time.Second
	}
	if config.MaxDelay == 0 {
		config.MaxDelay = 30 * time.Second
	}
	if config.BackoffFactor == 0 {
		config.BackoffFactor = 2.0
	}

	return &Retrier{config: config}
}

// Do executes the given function with retry logic
func (r *Retrier) Do(ctx context.Context, operation string, fn func() error) RetryResult {
	result := RetryResult{
		Success: false,
	}
	startTime := time.Now()

	for attempt := 1; attempt <= r.config.MaxAttempts; attempt++ {
		result.Attempts = attempt

		// Check context before attempting
		select {
		case <-ctx.Done():
			result.LastError = ctx.Err()
			result.LastErrorStr = ctx.Err().Error()
			result.TotalTime = time.Since(startTime)
			return result
		default:
		}

		// Execute the operation
		err := fn()
		if err == nil {
			result.Success = true
			result.TotalTime = time.Since(startTime)
			if attempt > 1 {
				logger.Log.Infof("EPG %s succeeded on attempt %d", operation, attempt)
			}
			return result
		}

		result.LastError = err
		result.LastErrorStr = err.Error()

		// Check if we should retry
		if attempt >= r.config.MaxAttempts {
			logger.Log.Warnf("EPG %s failed after %d attempts: %v", operation, attempt, err)
			break
		}

		if !r.isRetryable(err) {
			logger.Log.Warnf("EPG %s failed with non-retryable error: %v", operation, err)
			break
		}

		// Calculate delay with exponential backoff
		delay := r.calculateDelay(attempt)
		logger.Log.Debugf("EPG %s attempt %d failed, retrying in %v: %v", operation, attempt, delay, err)

		// Wait before retry
		select {
		case <-ctx.Done():
			result.LastError = ctx.Err()
			result.LastErrorStr = ctx.Err().Error()
			result.TotalTime = time.Since(startTime)
			return result
		case <-time.After(delay):
			// Continue to next attempt
		}
	}

	result.TotalTime = time.Since(startTime)
	return result
}

// isRetryable checks if an error is retryable
func (r *Retrier) isRetryable(err error) bool {
	if err == nil {
		return false
	}

	errStr := err.Error()
	for _, retryable := range r.config.RetryableErrors {
		if containsIgnoreCase(errStr, retryable) {
			return true
		}
	}

	return false
}

// calculateDelay calculates the delay for the next retry attempt
func (r *Retrier) calculateDelay(attempt int) time.Duration {
	// Exponential backoff: initialDelay * backoffFactor^(attempt-1)
	delay := float64(r.config.InitialDelay) * math.Pow(r.config.BackoffFactor, float64(attempt-1))

	// Add jitter (±25% of delay)
	if r.config.Jitter {
		jitterFactor := 0.75 + rand.Float64()*0.5 // 0.75 to 1.25
		delay *= jitterFactor
	}

	// Cap at max delay
	if delay > float64(r.config.MaxDelay) {
		delay = float64(r.config.MaxDelay)
	}

	return time.Duration(delay)
}

// containsIgnoreCase checks if s contains substr (case-insensitive)
func containsIgnoreCase(s, substr string) bool {
	sLower := []byte(s)
	substrLower := []byte(substr)

	// Simple lowercase conversion for ASCII
	for i := range sLower {
		if sLower[i] >= 'A' && sLower[i] <= 'Z' {
			sLower[i] += 'a' - 'A'
		}
	}
	for i := range substrLower {
		if substrLower[i] >= 'A' && substrLower[i] <= 'Z' {
			substrLower[i] += 'a' - 'A'
		}
	}

	return containsBytes(sLower, substrLower)
}

// containsBytes checks if s contains substr
func containsBytes(s, substr []byte) bool {
	if len(substr) == 0 {
		return true
	}
	if len(s) < len(substr) {
		return false
	}

	for i := 0; i <= len(s)-len(substr); i++ {
		match := true
		for j := 0; j < len(substr); j++ {
			if s[i+j] != substr[j] {
				match = false
				break
			}
		}
		if match {
			return true
		}
	}
	return false
}

// EPGFetchWithRetry wraps an EPG fetch operation with retry logic
func EPGFetchWithRetry(ctx context.Context, operation string, fn func() error) error {
	retrier := NewRetrier(DefaultRetryConfig())
	result := retrier.Do(ctx, operation, fn)

	if !result.Success {
		return fmt.Errorf("%s failed after %d attempts (took %v): %w",
			operation, result.Attempts, result.TotalTime, result.LastError)
	}

	return nil
}

// FetchStats tracks fetch statistics for monitoring
type FetchStats struct {
	TotalFetches     int64         `json:"totalFetches"`
	SuccessfulFetches int64        `json:"successfulFetches"`
	FailedFetches    int64         `json:"failedFetches"`
	TotalRetries     int64         `json:"totalRetries"`
	AverageDuration  time.Duration `json:"averageDuration"`
	LastFetchTime    time.Time     `json:"lastFetchTime"`
	LastError        string        `json:"lastError,omitempty"`
}

// RecordFetch records a fetch operation result
func (fs *FetchStats) RecordFetch(result RetryResult) {
	fs.TotalFetches++
	fs.LastFetchTime = time.Now()

	if result.Success {
		fs.SuccessfulFetches++
	} else {
		fs.FailedFetches++
		fs.LastError = result.LastErrorStr
	}

	// Track retries (attempts - 1 for successful, all attempts for failed)
	if result.Attempts > 1 {
		fs.TotalRetries += int64(result.Attempts - 1)
	}

	// Update average duration (simple moving average)
	if fs.TotalFetches == 1 {
		fs.AverageDuration = result.TotalTime
	} else {
		fs.AverageDuration = (fs.AverageDuration*time.Duration(fs.TotalFetches-1) + result.TotalTime) / time.Duration(fs.TotalFetches)
	}
}

// GetSuccessRate returns the success rate as a percentage
func (fs *FetchStats) GetSuccessRate() float64 {
	if fs.TotalFetches == 0 {
		return 0
	}
	return float64(fs.SuccessfulFetches) / float64(fs.TotalFetches) * 100
}
