package notify

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/smtp"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/logger"
)

// ChannelType identifies a notification channel.
type ChannelType string

const (
	ChannelDiscord ChannelType = "discord"
	ChannelSlack   ChannelType = "slack"
	ChannelEmail   ChannelType = "email"
	ChannelWebhook ChannelType = "webhook"
)

// ChannelConfig holds settings for a single notification channel.
type ChannelConfig struct {
	Enabled bool        `json:"enabled"`
	Type    ChannelType `json:"type"`

	// Discord / Slack / Custom webhook
	WebhookURL string `json:"webhookUrl,omitempty"`

	// Email (SMTP)
	SMTPHost     string `json:"smtpHost,omitempty"`
	SMTPPort     int    `json:"smtpPort,omitempty"`
	SMTPUser     string `json:"smtpUser,omitempty"`
	SMTPPass     string `json:"smtpPass,omitempty"`
	SMTPTLS      bool   `json:"smtpTls,omitempty"`
	EmailFrom    string `json:"emailFrom,omitempty"`
	EmailTo      string `json:"emailTo,omitempty"` // comma-separated
}

// Config is the top-level notification configuration persisted as JSON.
type Config struct {
	Channels     map[ChannelType]*ChannelConfig `json:"channels"`
	EnabledEvents map[string]bool               `json:"enabledEvents"` // event type -> enabled
}

// DefaultConfig returns a Config with all channels disabled and all
// supported event types enabled.
func DefaultConfig() Config {
	return Config{
		Channels: map[ChannelType]*ChannelConfig{
			ChannelDiscord: {Type: ChannelDiscord},
			ChannelSlack:   {Type: ChannelSlack},
			ChannelEmail:   {Type: ChannelEmail},
			ChannelWebhook: {Type: ChannelWebhook},
		},
		EnabledEvents: map[string]bool{
			"recording_started":   true,
			"recording_completed": true,
			"recording_failed":    true,
			"rule_triggered":      true,
			"conflict_detected":   true,
			"disk_space_low":      true,
			"update_available":    true,
		},
	}
}

// SupportedEvents returns the list of event types that can be configured.
func SupportedEvents() []string {
	return []string{
		"recording_started",
		"recording_completed",
		"recording_failed",
		"rule_triggered",
		"conflict_detected",
		"disk_space_low",
		"update_available",
	}
}

// HistoryEntry records a sent notification.
type HistoryEntry struct {
	ID        int         `json:"id"`
	Timestamp time.Time   `json:"timestamp"`
	EventType string      `json:"eventType"`
	Channel   ChannelType `json:"channel"`
	Title     string      `json:"title"`
	Success   bool        `json:"success"`
	Error     string      `json:"error,omitempty"`
}

// NotificationManager subscribes to the DVR EventBus and dispatches
// notifications through the configured channels.
type NotificationManager struct {
	mu       sync.RWMutex
	config   Config
	history  []HistoryEntry
	historyID int

	// Rate-limiting: per-event-type last-send timestamp
	rateMu    sync.Mutex
	lastSent  map[string]time.Time
	rateLimit time.Duration

	eventBus *dvr.EventBus
	stopCh   chan struct{}
	client   *http.Client
}

// NewNotificationManager creates a manager but does not start listening yet.
func NewNotificationManager(eventBus *dvr.EventBus) *NotificationManager {
	return &NotificationManager{
		config:    DefaultConfig(),
		history:   make([]HistoryEntry, 0, 100),
		lastSent:  make(map[string]time.Time),
		rateLimit: 60 * time.Second,
		eventBus:  eventBus,
		stopCh:    make(chan struct{}),
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

// SetConfig replaces the running configuration.
func (m *NotificationManager) SetConfig(cfg Config) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.config = cfg
}

// GetConfig returns a copy of the current configuration.
func (m *NotificationManager) GetConfig() Config {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.config
}

// GetHistory returns up to the last 100 notification history entries.
func (m *NotificationManager) GetHistory() []HistoryEntry {
	m.mu.RLock()
	defer m.mu.RUnlock()
	out := make([]HistoryEntry, len(m.history))
	copy(out, m.history)
	return out
}

// Start begins listening on the EventBus. Call in its own goroutine.
func (m *NotificationManager) Start() {
	if m.eventBus == nil {
		logger.Warn("NotificationManager: no EventBus available, not starting")
		return
	}

	const subscriberID = "notification-manager"
	ch := m.eventBus.Subscribe(subscriberID)

	go func() {
		defer m.eventBus.Unsubscribe(subscriberID)
		for {
			select {
			case <-m.stopCh:
				return
			case raw, ok := <-ch:
				if !ok {
					return
				}
				m.handleEvent(raw)
			}
		}
	}()

	logger.Info("NotificationManager started")
}

// Stop terminates the event listener.
func (m *NotificationManager) Stop() {
	close(m.stopCh)
}

// SendTestNotification sends a test event through all enabled channels.
func (m *NotificationManager) SendTestNotification() []HistoryEntry {
	evt := dvr.DVREvent{
		Type:    dvr.DVREventType("test"),
		Title:   "OpenFlix Test Notification",
		Message: "This is a test notification from your OpenFlix server.",
		Timestamp: time.Now(),
	}

	var results []HistoryEntry

	m.mu.RLock()
	cfg := m.config
	m.mu.RUnlock()

	for chType, chCfg := range cfg.Channels {
		if !chCfg.Enabled {
			continue
		}
		entry := m.dispatch(chType, chCfg, evt)
		results = append(results, entry)
	}

	return results
}

// handleEvent is called for each raw event from the EventBus.
func (m *NotificationManager) handleEvent(raw []byte) {
	var evt dvr.DVREvent
	if err := json.Unmarshal(raw, &evt); err != nil {
		logger.WithError(err).Warn("NotificationManager: failed to unmarshal event")
		return
	}

	eventType := string(evt.Type)

	m.mu.RLock()
	cfg := m.config
	m.mu.RUnlock()

	// Check if this event type is enabled for notifications
	if enabled, ok := cfg.EnabledEvents[eventType]; !ok || !enabled {
		return
	}

	// Rate limit: max 1 notification per event type per rateLimit period
	if !m.checkRateLimit(eventType) {
		return
	}

	for chType, chCfg := range cfg.Channels {
		if !chCfg.Enabled {
			continue
		}
		m.dispatch(chType, chCfg, evt)
	}
}

// checkRateLimit returns true if we are allowed to send for this event type.
func (m *NotificationManager) checkRateLimit(eventType string) bool {
	m.rateMu.Lock()
	defer m.rateMu.Unlock()

	if last, ok := m.lastSent[eventType]; ok {
		if time.Since(last) < m.rateLimit {
			return false
		}
	}
	m.lastSent[eventType] = time.Now()
	return true
}

// dispatch sends a single notification through the given channel and records history.
func (m *NotificationManager) dispatch(chType ChannelType, chCfg *ChannelConfig, evt dvr.DVREvent) HistoryEntry {
	title := formatTitle(evt)
	var err error

	switch chType {
	case ChannelDiscord:
		err = m.sendDiscord(chCfg, evt, title)
	case ChannelSlack:
		err = m.sendSlack(chCfg, evt, title)
	case ChannelEmail:
		err = m.sendEmail(chCfg, evt, title)
	case ChannelWebhook:
		err = m.sendWebhook(chCfg, evt)
	default:
		err = fmt.Errorf("unknown channel type: %s", chType)
	}

	entry := HistoryEntry{
		Timestamp: time.Now(),
		EventType: string(evt.Type),
		Channel:   chType,
		Title:     title,
		Success:   err == nil,
	}
	if err != nil {
		entry.Error = err.Error()
		logger.WithError(err).WithField("channel", chType).Warn("NotificationManager: dispatch failed")
	}

	m.recordHistory(entry)
	return entry
}

// recordHistory appends to the ring buffer (max 100).
func (m *NotificationManager) recordHistory(entry HistoryEntry) {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.historyID++
	entry.ID = m.historyID

	m.history = append(m.history, entry)
	if len(m.history) > 100 {
		m.history = m.history[len(m.history)-100:]
	}
}

// ===== Discord =====

func (m *NotificationManager) sendDiscord(cfg *ChannelConfig, evt dvr.DVREvent, title string) error {
	if cfg.WebhookURL == "" {
		return fmt.Errorf("discord webhook URL is empty")
	}

	color := discordColor(evt)
	description := formatDescription(evt)

	payload := map[string]interface{}{
		"embeds": []map[string]interface{}{
			{
				"title":       title,
				"description": description,
				"color":       color,
				"timestamp":   evt.Timestamp.Format(time.RFC3339),
				"footer": map[string]string{
					"text": "OpenFlix DVR",
				},
				"fields": discordFields(evt),
			},
		},
	}

	return m.postJSON(cfg.WebhookURL, payload)
}

func discordColor(evt dvr.DVREvent) int {
	switch evt.Type {
	case dvr.EventRecordingCompleted:
		return 0x00FF00 // green
	case dvr.EventRecordingFailed:
		return 0xFF0000 // red
	case dvr.EventRecordingStarted:
		return 0x3498DB // blue
	case dvr.EventDiskSpaceLow:
		return 0xFF9900 // orange
	case dvr.EventConflictDetected:
		return 0xFFFF00 // yellow
	case dvr.EventRuleTriggered:
		return 0x9B59B6 // purple
	default:
		return 0x95A5A6 // grey
	}
}

func discordFields(evt dvr.DVREvent) []map[string]interface{} {
	var fields []map[string]interface{}
	if evt.ChannelName != "" {
		fields = append(fields, map[string]interface{}{
			"name":   "Channel",
			"value":  evt.ChannelName,
			"inline": true,
		})
	}
	if evt.StartTime != nil {
		fields = append(fields, map[string]interface{}{
			"name":   "Start",
			"value":  evt.StartTime.Format("Jan 2, 3:04 PM"),
			"inline": true,
		})
	}
	if evt.Message != "" {
		fields = append(fields, map[string]interface{}{
			"name":   "Details",
			"value":  evt.Message,
			"inline": false,
		})
	}
	return fields
}

// ===== Slack =====

func (m *NotificationManager) sendSlack(cfg *ChannelConfig, evt dvr.DVREvent, title string) error {
	if cfg.WebhookURL == "" {
		return fmt.Errorf("slack webhook URL is empty")
	}

	description := formatDescription(evt)

	var sectionFields []map[string]interface{}
	if evt.ChannelName != "" {
		sectionFields = append(sectionFields, map[string]interface{}{
			"type": "mrkdwn",
			"text": fmt.Sprintf("*Channel:* %s", evt.ChannelName),
		})
	}
	if evt.StartTime != nil {
		sectionFields = append(sectionFields, map[string]interface{}{
			"type": "mrkdwn",
			"text": fmt.Sprintf("*Start:* %s", evt.StartTime.Format("Jan 2, 3:04 PM")),
		})
	}

	blocks := []map[string]interface{}{
		{
			"type": "header",
			"text": map[string]string{
				"type": "plain_text",
				"text": title,
			},
		},
		{
			"type": "section",
			"text": map[string]string{
				"type": "mrkdwn",
				"text": description,
			},
		},
	}

	if len(sectionFields) > 0 {
		blocks = append(blocks, map[string]interface{}{
			"type":   "section",
			"fields": sectionFields,
		})
	}

	if evt.Message != "" {
		blocks = append(blocks, map[string]interface{}{
			"type": "context",
			"elements": []map[string]string{
				{
					"type": "mrkdwn",
					"text": evt.Message,
				},
			},
		})
	}

	payload := map[string]interface{}{
		"blocks": blocks,
	}

	return m.postJSON(cfg.WebhookURL, payload)
}

// ===== Email =====

func (m *NotificationManager) sendEmail(cfg *ChannelConfig, evt dvr.DVREvent, title string) error {
	if cfg.SMTPHost == "" {
		return fmt.Errorf("SMTP host is empty")
	}
	if cfg.EmailFrom == "" || cfg.EmailTo == "" {
		return fmt.Errorf("email from/to is empty")
	}

	recipients := strings.Split(cfg.EmailTo, ",")
	for i := range recipients {
		recipients[i] = strings.TrimSpace(recipients[i])
	}

	body := formatEmailBody(evt)

	msg := fmt.Sprintf("From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n%s",
		cfg.EmailFrom,
		strings.Join(recipients, ", "),
		title,
		body,
	)

	addr := fmt.Sprintf("%s:%d", cfg.SMTPHost, cfg.SMTPPort)

	var auth smtp.Auth
	if cfg.SMTPUser != "" {
		auth = smtp.PlainAuth("", cfg.SMTPUser, cfg.SMTPPass, cfg.SMTPHost)
	}

	if cfg.SMTPTLS {
		return m.sendEmailTLS(addr, cfg, auth, cfg.EmailFrom, recipients, []byte(msg))
	}

	return smtp.SendMail(addr, auth, cfg.EmailFrom, recipients, []byte(msg))
}

func (m *NotificationManager) sendEmailTLS(addr string, cfg *ChannelConfig, auth smtp.Auth, from string, to []string, msg []byte) error {
	tlsConfig := &tls.Config{
		ServerName: cfg.SMTPHost,
	}

	conn, err := tls.Dial("tcp", addr, tlsConfig)
	if err != nil {
		return fmt.Errorf("TLS dial failed: %w", err)
	}

	host, _, _ := net.SplitHostPort(addr)
	client, err := smtp.NewClient(conn, host)
	if err != nil {
		conn.Close()
		return fmt.Errorf("SMTP client creation failed: %w", err)
	}
	defer client.Close()

	if auth != nil {
		if err := client.Auth(auth); err != nil {
			return fmt.Errorf("SMTP auth failed: %w", err)
		}
	}

	if err := client.Mail(from); err != nil {
		return fmt.Errorf("SMTP MAIL FROM failed: %w", err)
	}
	for _, addr := range to {
		if err := client.Rcpt(addr); err != nil {
			return fmt.Errorf("SMTP RCPT TO failed: %w", err)
		}
	}

	w, err := client.Data()
	if err != nil {
		return fmt.Errorf("SMTP DATA failed: %w", err)
	}
	if _, err := w.Write(msg); err != nil {
		return fmt.Errorf("SMTP write failed: %w", err)
	}
	if err := w.Close(); err != nil {
		return fmt.Errorf("SMTP close failed: %w", err)
	}

	return client.Quit()
}

// ===== Custom Webhook =====

func (m *NotificationManager) sendWebhook(cfg *ChannelConfig, evt dvr.DVREvent) error {
	if cfg.WebhookURL == "" {
		return fmt.Errorf("webhook URL is empty")
	}

	payload := map[string]interface{}{
		"event":     string(evt.Type),
		"title":     evt.Title,
		"message":   evt.Message,
		"channel":   evt.ChannelName,
		"timestamp": evt.Timestamp.Format(time.RFC3339),
	}
	if evt.RecordingID != 0 {
		payload["recordingId"] = evt.RecordingID
	}
	if evt.JobID != 0 {
		payload["jobId"] = evt.JobID
	}
	if evt.RuleID != 0 {
		payload["ruleId"] = evt.RuleID
	}
	if evt.StartTime != nil {
		payload["startTime"] = evt.StartTime.Format(time.RFC3339)
	}
	if evt.EndTime != nil {
		payload["endTime"] = evt.EndTime.Format(time.RFC3339)
	}
	if evt.Data != nil {
		payload["data"] = evt.Data
	}

	return m.postJSON(cfg.WebhookURL, payload)
}

// ===== Helpers =====

func (m *NotificationManager) postJSON(url string, payload interface{}) error {
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal payload: %w", err)
	}

	req, err := http.NewRequest(http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := m.client.Do(req)
	if err != nil {
		return fmt.Errorf("HTTP request: %w", err)
	}
	defer resp.Body.Close()
	io.Copy(io.Discard, resp.Body)

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("HTTP %d from %s", resp.StatusCode, url)
	}

	return nil
}

func formatTitle(evt dvr.DVREvent) string {
	prefix := eventLabel(string(evt.Type))
	if evt.Title != "" {
		return fmt.Sprintf("[%s] %s", prefix, evt.Title)
	}
	return fmt.Sprintf("[%s]", prefix)
}

func formatDescription(evt dvr.DVREvent) string {
	parts := []string{eventLabel(string(evt.Type))}
	if evt.Title != "" {
		parts = append(parts, fmt.Sprintf("**%s**", evt.Title))
	}
	if evt.Message != "" {
		parts = append(parts, evt.Message)
	}
	return strings.Join(parts, "\n")
}

func formatEmailBody(evt dvr.DVREvent) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Event: %s\n", eventLabel(string(evt.Type))))
	if evt.Title != "" {
		sb.WriteString(fmt.Sprintf("Title: %s\n", evt.Title))
	}
	if evt.ChannelName != "" {
		sb.WriteString(fmt.Sprintf("Channel: %s\n", evt.ChannelName))
	}
	if evt.StartTime != nil {
		sb.WriteString(fmt.Sprintf("Start: %s\n", evt.StartTime.Format(time.RFC1123)))
	}
	if evt.EndTime != nil {
		sb.WriteString(fmt.Sprintf("End: %s\n", evt.EndTime.Format(time.RFC1123)))
	}
	if evt.Message != "" {
		sb.WriteString(fmt.Sprintf("\nDetails:\n%s\n", evt.Message))
	}
	sb.WriteString(fmt.Sprintf("\nTimestamp: %s\n", evt.Timestamp.Format(time.RFC1123)))
	sb.WriteString("\n-- \nSent by OpenFlix DVR\n")
	return sb.String()
}

func eventLabel(eventType string) string {
	switch eventType {
	case "recording_started":
		return "Recording Started"
	case "recording_completed":
		return "Recording Completed"
	case "recording_failed":
		return "Recording Failed"
	case "rule_triggered":
		return "Rule Triggered"
	case "conflict_detected":
		return "Conflict Detected"
	case "disk_space_low":
		return "Disk Space Low"
	case "update_available":
		return "Update Available"
	case "test":
		return "Test Notification"
	default:
		return strings.ReplaceAll(eventType, "_", " ")
	}
}

// ConfigToJSON serialises Config to a JSON string.
func ConfigToJSON(cfg Config) (string, error) {
	data, err := json.Marshal(cfg)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

// ConfigFromJSON deserialises a JSON string to Config.
func ConfigFromJSON(s string) (Config, error) {
	var cfg Config
	if err := json.Unmarshal([]byte(s), &cfg); err != nil {
		return DefaultConfig(), err
	}
	return cfg, nil
}
