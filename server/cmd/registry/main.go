// Cloud registry microservice for OpenFlix remote discovery.
// Deploy to Fly.io (or any host) at discover.openflix.app.
//
// API:
//   POST /register                  — server heartbeat (TTL 90s)
//   GET  /servers?machineId={id}    — app reconnects to known server
//   GET  /servers?token={4-char}    — app pairs via claim code
//
// Admin API (requires Authorization: Bearer <ADMIN_SECRET>):
//   GET    /admin                — web-based license management UI
//   POST   /admin/licenses       — create a new license key
//   DELETE /admin/licenses/:key  — deactivate a license key
//   PATCH  /admin/licenses/:key  — update expiry date
//   GET    /admin/licenses       — list all licenses
package main

import (
	"crypto/rand"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	_ "github.com/lib/pq"
)

const (
	entryTTL          = 90 * time.Second
	cleanupInterval   = 30 * time.Second
	maxLocalAddresses = 10
)

// db is the global Postgres connection. nil when DATABASE_URL is unset (dev mode).
var db *sql.DB

// adminSecret is the bearer token required for /admin/* endpoints.
var adminSecret string

// ServerEntry stores a registered server's info.
type ServerEntry struct {
	MachineID      string    `json:"machineId"`
	Name           string    `json:"name"`
	Version        string    `json:"version"`
	Port           int       `json:"port"`
	LocalAddresses []string  `json:"localAddresses"`
	PublicIP       string    `json:"publicIp"`
	ExternalURL    string    `json:"externalUrl,omitempty"` // cloudflared tunnel or custom domain
	ClaimToken     string    `json:"-"` // not exposed in lookup responses
	InviteTokens   []string  `json:"-"` // active invite tokens from this server
	ExpiresAt      time.Time `json:"-"`
}

// serverResponse is the shape returned to iOS clients.
type serverResponse struct {
	MachineID      string   `json:"machineId"`
	Name           string   `json:"name"`
	Version        string   `json:"version"`
	Port           int      `json:"port"`
	PublicIP       string   `json:"publicIp"`
	LocalAddresses []string `json:"localAddresses"`
	ExternalURL    string   `json:"externalUrl,omitempty"`
}

// registerPayload is what the home server sends on heartbeat.
type registerPayload struct {
	MachineID      string   `json:"machineId"`
	Name           string   `json:"name"`
	Version        string   `json:"version"`
	Port           int      `json:"port"`
	LocalAddresses []string `json:"localAddresses"`
	ClaimToken     string   `json:"claimToken,omitempty"`
	InviteTokens   []string `json:"inviteTokens,omitempty"`
	LicenseKey     string   `json:"licenseKey,omitempty"`
	ExternalURL    string   `json:"externalUrl,omitempty"`
}

// store is the in-memory registry.
type store struct {
	mu       sync.RWMutex
	byID     map[string]*ServerEntry // machineId → entry
	byToken  map[string]string       // claimToken → machineId
	byInvite map[string]string       // inviteToken → machineId
}

func newStore() *store {
	return &store{
		byID:     make(map[string]*ServerEntry),
		byToken:  make(map[string]string),
		byInvite: make(map[string]string),
	}
}

func (s *store) upsert(entry *ServerEntry) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Remove old claim token mapping if changed
	if old, exists := s.byID[entry.MachineID]; exists && old.ClaimToken != "" && old.ClaimToken != entry.ClaimToken {
		delete(s.byToken, old.ClaimToken)
	}

	// Remove old invite token mappings no longer present
	if old, exists := s.byID[entry.MachineID]; exists {
		newSet := make(map[string]bool, len(entry.InviteTokens))
		for _, t := range entry.InviteTokens {
			newSet[strings.ToUpper(t)] = true
		}
		for _, t := range old.InviteTokens {
			if !newSet[strings.ToUpper(t)] {
				delete(s.byInvite, strings.ToUpper(t))
			}
		}
	}

	s.byID[entry.MachineID] = entry
	if entry.ClaimToken != "" {
		s.byToken[strings.ToUpper(entry.ClaimToken)] = entry.MachineID
	}
	for _, t := range entry.InviteTokens {
		s.byInvite[strings.ToUpper(t)] = entry.MachineID
	}
}

func (s *store) lookupByID(machineID string) *ServerEntry {
	s.mu.RLock()
	defer s.mu.RUnlock()
	e := s.byID[machineID]
	if e != nil && time.Now().After(e.ExpiresAt) {
		return nil
	}
	return e
}

func (s *store) lookupByToken(token string) *ServerEntry {
	s.mu.RLock()
	defer s.mu.RUnlock()
	mid, ok := s.byToken[strings.ToUpper(token)]
	if !ok {
		return nil
	}
	e := s.byID[mid]
	if e != nil && time.Now().After(e.ExpiresAt) {
		return nil
	}
	return e
}

func (s *store) lookupByInvite(token string) *ServerEntry {
	s.mu.RLock()
	defer s.mu.RUnlock()
	mid, ok := s.byInvite[strings.ToUpper(token)]
	if !ok {
		return nil
	}
	e := s.byID[mid]
	if e != nil && time.Now().After(e.ExpiresAt) {
		return nil
	}
	return e
}

func (s *store) cleanup() {
	s.mu.Lock()
	defer s.mu.Unlock()
	now := time.Now()
	for id, entry := range s.byID {
		if now.After(entry.ExpiresAt) {
			if entry.ClaimToken != "" {
				delete(s.byToken, entry.ClaimToken)
			}
			delete(s.byID, id)
		}
	}
}

// extractPublicIP gets the caller's real IP from standard proxy headers or RemoteAddr.
func extractPublicIP(r *http.Request) string {
	if ip := r.Header.Get("X-Forwarded-For"); ip != "" {
		// X-Forwarded-For can be a comma-separated list; take the first
		parts := strings.SplitN(ip, ",", 2)
		return strings.TrimSpace(parts[0])
	}
	if ip := r.Header.Get("X-Real-Ip"); ip != "" {
		return strings.TrimSpace(ip)
	}
	// Fall back to RemoteAddr (strip port)
	addr := r.RemoteAddr
	if idx := strings.LastIndex(addr, ":"); idx != -1 {
		addr = addr[:idx]
	}
	return strings.Trim(addr, "[]")
}

// generateUUID creates a random UUID v4 string using only crypto/rand.
func generateUUID() (string, error) {
	var uuid [16]byte
	if _, err := rand.Read(uuid[:]); err != nil {
		return "", err
	}
	// Set version 4 bits
	uuid[6] = (uuid[6] & 0x0f) | 0x40
	// Set variant bits
	uuid[8] = (uuid[8] & 0x3f) | 0x80
	return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x",
		uuid[0:4], uuid[4:6], uuid[6:8], uuid[8:10], uuid[10:16]), nil
}

// validateLicense checks the license key against the DB.
// Returns (valid bool, err error). If db is nil, always returns (true, nil).
func validateLicense(key string) (bool, error) {
	if db == nil {
		return true, nil
	}
	if strings.TrimSpace(key) == "" {
		return false, nil
	}

	var active bool
	var expiresAt sql.NullTime
	err := db.QueryRow(
		`SELECT active, expires_at FROM licenses WHERE key = $1`, key,
	).Scan(&active, &expiresAt)
	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	if !active {
		return false, nil
	}
	if expiresAt.Valid && time.Now().After(expiresAt.Time) {
		return false, nil
	}
	return true, nil
}

// requireAdmin is middleware that checks the Authorization: Bearer header.
func requireAdmin(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if adminSecret == "" {
			http.Error(w, "admin not configured", http.StatusForbidden)
			return
		}
		auth := r.Header.Get("Authorization")
		if !strings.HasPrefix(auth, "Bearer ") || strings.TrimPrefix(auth, "Bearer ") != adminSecret {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		next(w, r)
	}
}

// initDB opens the Postgres connection and creates the schema if needed.
func initDB(databaseURL string) error {
	var err error
	db, err = sql.Open("postgres", databaseURL)
	if err != nil {
		return fmt.Errorf("open db: %w", err)
	}
	if err = db.Ping(); err != nil {
		return fmt.Errorf("ping db: %w", err)
	}

	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS licenses (
		key        TEXT PRIMARY KEY,
		email      TEXT NOT NULL,
		created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
		expires_at TIMESTAMPTZ,
		active     BOOLEAN NOT NULL DEFAULT TRUE
	)`)
	if err != nil {
		return fmt.Errorf("create table: %w", err)
	}
	log.Println("DB connected and schema ready")
	return nil
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	adminSecret = os.Getenv("ADMIN_SECRET")

	// Resend email API key (optional — if unset, emails are skipped silently)
	resendAPIKey = os.Getenv("RESEND_API_KEY")
	if resendAPIKey == "" {
		log.Println("INFO: RESEND_API_KEY not set — email notifications disabled")
	}

	// Set up Postgres (optional — if unset, run in dev/open mode)
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Println("WARNING: DATABASE_URL not set — license validation disabled (dev/open mode)")
	} else {
		if err := initDB(databaseURL); err != nil {
			log.Fatalf("failed to connect to database: %v", err)
		}
	}

	registry := newStore()

	// Background cleanup goroutine
	go func() {
		ticker := time.NewTicker(cleanupInterval)
		defer ticker.Stop()
		for range ticker.C {
			registry.cleanup()
		}
	}()

	// Background license expiry email goroutine (runs every hour)
	go func() {
		ticker := time.NewTicker(1 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			if db == nil {
				continue
			}
			now := time.Now()

			// Query licenses expiring in the next 7 days (±1 hour window to avoid double-sends)
			warnFrom := now.Add(6*24*time.Hour + 23*time.Hour)
			warnTo := now.Add(7*24*time.Hour + 1*time.Hour)
			rows, err := db.Query(
				`SELECT key, email, expires_at FROM licenses
				 WHERE active = TRUE
				   AND expires_at >= $1
				   AND expires_at <= $2`,
				warnFrom, warnTo,
			)
			if err != nil {
				log.Printf("expiry warning query error: %v", err)
			} else {
				for rows.Next() {
					var key, email string
					var expiresAt time.Time
					if err := rows.Scan(&key, &email, &expiresAt); err != nil {
						log.Printf("expiry warning row scan error: %v", err)
						continue
					}
					go func(e, k string, t time.Time) {
						if err := sendLicenseExpiringEmail(e, k, t); err != nil {
							log.Printf("send expiry warning email error (key=%s): %v", k, err)
						} else {
							log.Printf("EXPIRY WARNING EMAIL SENT key=%s email=%s expiresAt=%s", k, e, t.Format(time.RFC3339))
						}
					}(email, key, expiresAt)
				}
				rows.Close()
			}

			// Query licenses that expired in the last hour
			expiredFrom := now.Add(-1 * time.Hour)
			expiredRows, err := db.Query(
				`SELECT key, email FROM licenses
				 WHERE active = TRUE
				   AND expires_at >= $1
				   AND expires_at < $2`,
				expiredFrom, now,
			)
			if err != nil {
				log.Printf("expired query error: %v", err)
			} else {
				for expiredRows.Next() {
					var key, email string
					if err := expiredRows.Scan(&key, &email); err != nil {
						log.Printf("expired row scan error: %v", err)
						continue
					}
					go func(e, k string) {
						if err := sendLicenseExpiredEmail(e, k); err != nil {
							log.Printf("send expired email error (key=%s): %v", k, err)
						} else {
							log.Printf("EXPIRED EMAIL SENT key=%s email=%s", k, e)
						}
					}(email, key)
				}
				expiredRows.Close()
			}
		}
	}()

	mux := http.NewServeMux()

	// POST /register — server heartbeat
	mux.HandleFunc("POST /register", func(w http.ResponseWriter, r *http.Request) {
		var payload registerPayload
		if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}
		if payload.MachineID == "" {
			http.Error(w, "machineId required", http.StatusBadRequest)
			return
		}
		if payload.Port == 0 {
			payload.Port = 32400
		}

		// License validation (skipped when db is nil)
		valid, err := validateLicense(payload.LicenseKey)
		if err != nil {
			log.Printf("license DB error: %v", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}
		if !valid {
			log.Printf("REGISTER REJECTED machineId=%s — invalid/missing/expired license key", payload.MachineID)
			http.Error(w, `{"error":"license key required","message":"A valid license key is required for cloud discovery. Visit openflix.io to purchase a license."}`, http.StatusPaymentRequired)
			return
		}

		// Truncate local addresses to a reasonable count
		addrs := payload.LocalAddresses
		if len(addrs) > maxLocalAddresses {
			addrs = addrs[:maxLocalAddresses]
		}

		publicIP := extractPublicIP(r)

		entry := &ServerEntry{
			MachineID:      payload.MachineID,
			Name:           payload.Name,
			Version:        payload.Version,
			Port:           payload.Port,
			LocalAddresses: addrs,
			PublicIP:       publicIP,
			ExternalURL:    payload.ExternalURL,
			ClaimToken:     strings.ToUpper(payload.ClaimToken),
			ExpiresAt:      time.Now().Add(entryTTL),
		}
		registry.upsert(entry)

		log.Printf("REGISTER machineId=%s publicIp=%s token=%s", payload.MachineID, publicIP, payload.ClaimToken)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{
			"registered": true,
			"publicIp":   publicIP,
		})
	})

	// GET /servers?machineId=... or ?token=...
	mux.HandleFunc("GET /servers", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		machineID := q.Get("machineId")
		token := q.Get("token")
		invite := q.Get("invite")

		var entry *ServerEntry
		switch {
		case machineID != "":
			entry = registry.lookupByID(machineID)
		case token != "":
			entry = registry.lookupByToken(token)
		case invite != "":
			entry = registry.lookupByInvite(invite)
		default:
			http.Error(w, "machineId, token, or invite required", http.StatusBadRequest)
			return
		}

		if entry == nil {
			http.Error(w, "server not found", http.StatusNotFound)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(serverResponse{
			MachineID:      entry.MachineID,
			Name:           entry.Name,
			Version:        entry.Version,
			Port:           entry.Port,
			PublicIP:       entry.PublicIP,
			LocalAddresses: entry.LocalAddresses,
			ExternalURL:    entry.ExternalURL,
		})
	})

	// Health check
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})

	// ─── Admin endpoints ────────────────────────────────────────────────────

	// POST /admin/licenses — create a new license key
	mux.HandleFunc("POST /admin/licenses", requireAdmin(func(w http.ResponseWriter, r *http.Request) {
		if db == nil {
			http.Error(w, "database not configured", http.StatusServiceUnavailable)
			return
		}
		var body struct {
			Email     string `json:"email"`
			ExpiresAt string `json:"expiresAt"` // RFC3339, optional
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}
		if body.Email == "" {
			http.Error(w, "email required", http.StatusBadRequest)
			return
		}

		key, err := generateUUID()
		if err != nil {
			log.Printf("generateUUID error: %v", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}

		var expiresAt *time.Time
		if body.ExpiresAt != "" {
			t, err := time.Parse(time.RFC3339, body.ExpiresAt)
			if err != nil {
				http.Error(w, "invalid expiresAt format (use RFC3339)", http.StatusBadRequest)
				return
			}
			expiresAt = &t
		}

		if expiresAt != nil {
			_, err = db.Exec(`INSERT INTO licenses (key, email, expires_at) VALUES ($1, $2, $3)`,
				key, body.Email, expiresAt)
		} else {
			_, err = db.Exec(`INSERT INTO licenses (key, email) VALUES ($1, $2)`,
				key, body.Email)
		}
		if err != nil {
			log.Printf("insert license error: %v", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}

		log.Printf("ADMIN CREATE LICENSE key=%s email=%s", key, body.Email)

		// Send license created email asynchronously
		go func(e, k string, exp *time.Time) {
			if err := sendLicenseCreatedEmail(e, k, exp); err != nil {
				log.Printf("send license created email error (key=%s): %v", k, err)
			} else {
				log.Printf("LICENSE CREATED EMAIL SENT key=%s email=%s", k, e)
			}
		}(body.Email, key, expiresAt)

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(map[string]string{
			"key":   key,
			"email": body.Email,
		})
	}))

	// DELETE /admin/licenses/{key} — deactivate a license key
	mux.HandleFunc("DELETE /admin/licenses/", requireAdmin(func(w http.ResponseWriter, r *http.Request) {
		if db == nil {
			http.Error(w, "database not configured", http.StatusServiceUnavailable)
			return
		}
		// Extract key from path: /admin/licenses/{key}
		key := strings.TrimPrefix(r.URL.Path, "/admin/licenses/")
		if key == "" {
			http.Error(w, "key required in path", http.StatusBadRequest)
			return
		}

		// Optional body with a revocation reason
		var body struct {
			Reason string `json:"reason"`
		}
		// Body is optional on DELETE; ignore decode errors
		if r.Body != nil && r.ContentLength != 0 {
			json.NewDecoder(r.Body).Decode(&body) //nolint:errcheck
		}

		// Look up email before deactivating so we can notify the customer
		var email string
		emailErr := db.QueryRow(`SELECT email FROM licenses WHERE key = $1`, key).Scan(&email)

		result, err := db.Exec(`UPDATE licenses SET active = FALSE WHERE key = $1`, key)
		if err != nil {
			log.Printf("deactivate license error: %v", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}
		n, _ := result.RowsAffected()
		if n == 0 {
			http.Error(w, "license not found", http.StatusNotFound)
			return
		}

		log.Printf("ADMIN DEACTIVATE LICENSE key=%s reason=%q", key, body.Reason)

		// Send revocation email asynchronously (only if we have the email address)
		if emailErr == nil && email != "" {
			go func(e, k, reason string) {
				if err := sendLicenseRevokedEmail(e, k, reason); err != nil {
					log.Printf("send license revoked email error (key=%s): %v", k, err)
				} else {
					log.Printf("LICENSE REVOKED EMAIL SENT key=%s email=%s", k, e)
				}
			}(email, key, body.Reason)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"deactivated": true, "key": key})
	}))

	// GET /admin — serve the web-based admin UI
	mux.HandleFunc("GET /admin", func(w http.ResponseWriter, r *http.Request) {
		if adminSecret == "" {
			http.Error(w, "admin UI not configured (ADMIN_SECRET not set)", http.StatusServiceUnavailable)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Header().Set("Cache-Control", "no-store")
		fmt.Fprint(w, adminHTML)
	})

	// PATCH /admin/licenses/{key} — update expiry date
	mux.HandleFunc("PATCH /admin/licenses/", requireAdmin(func(w http.ResponseWriter, r *http.Request) {
		if db == nil {
			http.Error(w, "database not configured", http.StatusServiceUnavailable)
			return
		}
		key := strings.TrimPrefix(r.URL.Path, "/admin/licenses/")
		if key == "" {
			http.Error(w, "key required in path", http.StatusBadRequest)
			return
		}

		var body struct {
			ExpiresAt string `json:"expiresAt"` // RFC3339, required
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}
		if body.ExpiresAt == "" {
			http.Error(w, "expiresAt required", http.StatusBadRequest)
			return
		}
		t, err := time.Parse(time.RFC3339, body.ExpiresAt)
		if err != nil {
			http.Error(w, "invalid expiresAt format (use RFC3339)", http.StatusBadRequest)
			return
		}

		result, err := db.Exec(`UPDATE licenses SET expires_at = $1, active = TRUE WHERE key = $2`, t, key)
		if err != nil {
			log.Printf("update license expiry error: %v", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}
		n, _ := result.RowsAffected()
		if n == 0 {
			http.Error(w, "license not found", http.StatusNotFound)
			return
		}

		log.Printf("ADMIN UPDATE EXPIRY key=%s expiresAt=%s (reactivated)", key, t.Format(time.RFC3339))
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"updated": true, "key": key, "expiresAt": t.Format(time.RFC3339), "active": true})
	}))

	// GET /admin/licenses — list all licenses
	mux.HandleFunc("GET /admin/licenses", requireAdmin(func(w http.ResponseWriter, r *http.Request) {
		if db == nil {
			http.Error(w, "database not configured", http.StatusServiceUnavailable)
			return
		}
		rows, err := db.Query(`SELECT key, email, created_at, expires_at, active FROM licenses ORDER BY created_at DESC`)
		if err != nil {
			log.Printf("list licenses error: %v", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		type licenseRow struct {
			Key       string  `json:"key"`
			Email     string  `json:"email"`
			CreatedAt string  `json:"createdAt"`
			ExpiresAt *string `json:"expiresAt"`
			Active    bool    `json:"active"`
		}
		var licenses []licenseRow
		for rows.Next() {
			var lr licenseRow
			var createdAt time.Time
			var expiresAt sql.NullTime
			if err := rows.Scan(&lr.Key, &lr.Email, &createdAt, &expiresAt, &lr.Active); err != nil {
				log.Printf("scan license error: %v", err)
				http.Error(w, "internal error", http.StatusInternalServerError)
				return
			}
			lr.CreatedAt = createdAt.Format(time.RFC3339)
			if expiresAt.Valid {
				s := expiresAt.Time.Format(time.RFC3339)
				lr.ExpiresAt = &s
			}
			licenses = append(licenses, lr)
		}
		if err := rows.Err(); err != nil {
			log.Printf("rows error: %v", err)
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}

		if licenses == nil {
			licenses = []licenseRow{}
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"licenses": licenses})
	}))

	log.Printf("OpenFlix cloud registry listening on :%s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
