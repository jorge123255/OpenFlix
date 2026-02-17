package speedtest

import (
	"crypto/rand"
	"io"
	"os"
	"runtime"
	"sync"
	"time"
)

// SpeedTest manages speed test sessions between client and server.
type SpeedTest struct {
	sessions map[string]*TestSession
	mu       sync.RWMutex
}

// TestSession represents a single speed test session.
type TestSession struct {
	ID            string    `json:"id"`
	StartedAt     time.Time `json:"startedAt"`
	DownloadMbps  float64   `json:"downloadMbps"`
	UploadMbps    float64   `json:"uploadMbps"`
	LatencyMs     float64   `json:"latencyMs"`
	BytesSent     int64     `json:"bytesSent"`
	BytesReceived int64     `json:"bytesReceived"`
	Duration      float64   `json:"durationSeconds"`
	Status        string    `json:"status"` // running, completed
}

// TestResults wraps session results with server metadata.
type TestResults struct {
	Session    *TestSession `json:"session"`
	ServerInfo ServerInfo   `json:"serverInfo"`
}

// ServerInfo describes the server running the speed test.
type ServerInfo struct {
	Hostname string `json:"hostname"`
	Platform string `json:"platform"`
	CPUCount int    `json:"cpuCount"`
}

// New creates a new SpeedTest manager.
func New() *SpeedTest {
	return &SpeedTest{
		sessions: make(map[string]*TestSession),
	}
}

// GenerateDownloadData returns an io.Reader that produces `size` bytes of
// random data suitable for a download speed test.
func (st *SpeedTest) GenerateDownloadData(size int64) io.Reader {
	return io.LimitReader(rand.Reader, size)
}

// StartUploadTest creates a new test session in "running" state and returns it.
func (st *SpeedTest) StartUploadTest(sessionID string) *TestSession {
	session := &TestSession{
		ID:        sessionID,
		StartedAt: time.Now(),
		Status:    "running",
	}

	st.mu.Lock()
	st.sessions[sessionID] = session
	st.mu.Unlock()

	return session
}

// RecordUpload records bytes received during an upload test and finalizes the
// session with computed speed metrics.
func (st *SpeedTest) RecordUpload(sessionID string, bytesReceived int64) {
	st.mu.Lock()
	defer st.mu.Unlock()

	session, ok := st.sessions[sessionID]
	if !ok {
		return
	}

	elapsed := time.Since(session.StartedAt).Seconds()
	if elapsed <= 0 {
		elapsed = 0.001 // prevent division by zero
	}

	session.BytesReceived = bytesReceived
	session.Duration = elapsed
	session.UploadMbps = float64(bytesReceived) * 8.0 / (elapsed * 1_000_000)
	session.Status = "completed"
}

// GetResults returns the test results for a given session, including server
// information. Returns nil if the session does not exist.
func (st *SpeedTest) GetResults(sessionID string) *TestResults {
	st.mu.RLock()
	session, ok := st.sessions[sessionID]
	st.mu.RUnlock()

	if !ok {
		return nil
	}

	hostname, _ := os.Hostname()
	return &TestResults{
		Session: session,
		ServerInfo: ServerInfo{
			Hostname: hostname,
			Platform: runtime.GOOS,
			CPUCount: runtime.NumCPU(),
		},
	}
}

// CleanupOldSessions removes sessions older than the given maximum age.
// This can be called periodically to prevent unbounded memory growth.
func (st *SpeedTest) CleanupOldSessions(maxAge time.Duration) {
	st.mu.Lock()
	defer st.mu.Unlock()

	cutoff := time.Now().Add(-maxAge)
	for id, session := range st.sessions {
		if session.StartedAt.Before(cutoff) {
			delete(st.sessions, id)
		}
	}
}
