package api

import (
	"net/http"
	"os"
	"strings"
	"time"
	"unicode"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/config"
)

// ============ License Key Handlers ============

// licenseStatus returns the current validation state of a license key.
type licenseStatus struct {
	Key    string `json:"key"`
	Status string `json:"status"` // "valid", "invalid", "not_set"
	Masked string `json:"masked"`
}

// validateLicenseKey performs a basic format check.
// A valid key matches the pattern: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (UUID v4-like, hex + hyphens).
func validateLicenseKey(key string) bool {
	if key == "" {
		return false
	}
	// Accept any non-empty key that contains only hex chars and hyphens, length 36
	key = strings.TrimSpace(key)
	if len(key) != 36 {
		return false
	}
	parts := strings.Split(key, "-")
	if len(parts) != 5 {
		return false
	}
	expectedLengths := []int{8, 4, 4, 4, 12}
	for i, part := range parts {
		if len(part) != expectedLengths[i] {
			return false
		}
		for _, ch := range part {
			if !unicode.IsDigit(ch) && (ch < 'a' || ch > 'f') && (ch < 'A' || ch > 'F') {
				return false
			}
		}
	}
	return true
}

// maskLicenseKey returns the key with all but the last 4 chars replaced by asterisks.
func maskLicenseKey(key string) string {
	if len(key) <= 4 {
		return strings.Repeat("*", len(key))
	}
	return strings.Repeat("*", len(key)-4) + key[len(key)-4:]
}

// getLicenseStatus builds a licenseStatus from the current config.
func (s *Server) getLicenseStatus() licenseStatus {
	key := strings.TrimSpace(s.config.Server.LicenseKey)
	if key == "" {
		return licenseStatus{Key: "", Status: "not_set", Masked: ""}
	}
	status := "invalid"
	if validateLicenseKey(key) {
		status = "valid"
	}
	return licenseStatus{Key: key, Status: status, Masked: maskLicenseKey(key)}
}

// GET /api/admin/license
func (s *Server) getLicense(c *gin.Context) {
	ls := s.getLicenseStatus()
	c.JSON(http.StatusOK, ls)
}

// POST /api/admin/license
func (s *Server) saveLicense(c *gin.Context) {
	var body struct {
		Key string `json:"key"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	key := strings.TrimSpace(body.Key)

	// Persist to environment (in-memory for the running process)
	os.Setenv("OPENFLIX_LICENSE_KEY", key)

	// Persist to DB so it survives container restarts
	s.setSetting("license_key", key)

	// Update the live config
	s.config.Server.LicenseKey = key

	// Derive a stable machine ID from the license key so the server identity
	// survives container rebuilds and fresh installs.
	if key != "" {
		derived := config.DeriveServerID(key)
		s.config.Server.MachineID = derived
		if s.cloudRegistry != nil {
			s.cloudRegistry.UpdateMachineID(derived)
		}
	}

	// If cloud registry is running, update license key
	if s.cloudRegistry != nil {
		s.cloudRegistry.SetLicenseKey(key)
	}

	ls := s.getLicenseStatus()
	c.JSON(http.StatusOK, ls)
}

// ============ Remote Access Status Handler ============

// remoteAccessStatus is returned by GET /api/admin/remote-access
type remoteAccessStatus struct {
	Enabled        bool      `json:"enabled"`
	CloudConnected bool      `json:"cloudConnected"`
	CloudURL       string    `json:"cloudUrl"`
	PublicIP       string    `json:"publicIp"`
	ClaimToken     string    `json:"claimToken"`
	ClaimExpires   time.Time `json:"claimExpires"`
	ClaimActive    bool      `json:"claimActive"`
	MachineID      string    `json:"machineId"`
}

// GET /api/admin/remote-access
func (s *Server) getCloudRegistryStatus(c *gin.Context) {
	status := remoteAccessStatus{
		Enabled:   s.getSettingBool("remote_access_enabled", false),
		CloudURL:  s.config.Server.CloudRegistryURL,
		MachineID: s.config.Server.MachineID,
	}

	// Cloud registry status
	if s.cloudRegistry != nil {
		cs := s.cloudRegistry.GetStatus()
		status.CloudConnected = cs.Connected
		status.PublicIP = cs.PublicIP
	}

	// Claim token status
	claimStore.mu.RLock()
	if claimStore.token != "" && time.Now().Before(claimStore.expires) {
		status.ClaimToken = claimStore.token
		status.ClaimExpires = claimStore.expires
		status.ClaimActive = true
	}
	claimStore.mu.RUnlock()

	c.JSON(http.StatusOK, status)
}
