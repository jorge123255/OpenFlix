package api

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"golang.org/x/crypto/bcrypt"
)

// ========== Content Rating Hierarchies ==========

// tvRatingOrder defines the TV content rating hierarchy (US TV Parental Guidelines).
// Higher index = more restrictive.
var tvRatingOrder = map[string]int{
	"TV-Y":  0,
	"TV-Y7": 1,
	"TV-G":  2,
	"TV-PG": 3,
	"TV-14": 4,
	"TV-MA": 5,
}

// mpaaRatingOrder defines the MPAA movie content rating hierarchy.
// Higher index = more restrictive.
var mpaaRatingOrder = map[string]int{
	"G":     0,
	"PG":    1,
	"PG-13": 2,
	"R":     3,
	"NC-17": 4,
}

// RatingExceedsMax returns true if contentRating is more restrictive than maxRating.
// It handles both TV and MPAA rating systems. If the rating system is unknown or
// the content has no rating, it returns false (permissive by default for unrated content).
func RatingExceedsMax(contentRating, maxRating string) bool {
	if contentRating == "" || maxRating == "" {
		return false
	}

	upperContent := strings.ToUpper(strings.TrimSpace(contentRating))
	upperMax := strings.ToUpper(strings.TrimSpace(maxRating))

	// Check TV ratings
	contentTV, contentIsTV := tvRatingOrder[upperContent]
	maxTV, maxIsTV := tvRatingOrder[upperMax]
	if contentIsTV && maxIsTV {
		return contentTV > maxTV
	}

	// Check MPAA ratings
	contentMPAA, contentIsMPAA := mpaaRatingOrder[upperContent]
	maxMPAA, maxIsMPAA := mpaaRatingOrder[upperMax]
	if contentIsMPAA && maxIsMPAA {
		return contentMPAA > maxMPAA
	}

	// Cross-system comparison: map TV to approximate MPAA equivalents
	// TV-Y, TV-Y7, TV-G -> G; TV-PG -> PG; TV-14 -> PG-13; TV-MA -> R
	tvToMPAA := map[string]int{
		"TV-Y":  0, // G
		"TV-Y7": 0, // G
		"TV-G":  0, // G
		"TV-PG": 1, // PG
		"TV-14": 2, // PG-13
		"TV-MA": 3, // R
	}

	var contentLevel, maxLevel int
	var contentFound, maxFound bool

	if contentIsTV {
		contentLevel, contentFound = tvToMPAA[upperContent]
	} else if contentIsMPAA {
		contentLevel = contentMPAA
		contentFound = true
	}

	if maxIsTV {
		maxLevel, maxFound = tvToMPAA[upperMax]
	} else if maxIsMPAA {
		maxLevel = maxMPAA
		maxFound = true
	}

	if contentFound && maxFound {
		return contentLevel > maxLevel
	}

	// Unknown rating system - don't block
	return false
}

// ========== PIN Session Management ==========

// parentalPINSession tracks a verified PIN session with expiration.
type parentalPINSession struct {
	UserID    uint
	VerifiedAt time.Time
	ExpiresAt  time.Time
}

const parentalPINSessionTTL = 4 * time.Hour

var (
	parentalSessions   = make(map[string]*parentalPINSession) // key: auth token
	parentalSessionsMu sync.RWMutex
)

// createParentalSession creates a PIN-verified session for the given user/token.
func createParentalSession(token string, userID uint) {
	parentalSessionsMu.Lock()
	defer parentalSessionsMu.Unlock()

	now := time.Now()
	parentalSessions[token] = &parentalPINSession{
		UserID:     userID,
		VerifiedAt: now,
		ExpiresAt:  now.Add(parentalPINSessionTTL),
	}
}

// isParentalSessionValid checks if a PIN-verified session exists and hasn't expired.
func isParentalSessionValid(token string, userID uint) bool {
	parentalSessionsMu.RLock()
	defer parentalSessionsMu.RUnlock()

	session, exists := parentalSessions[token]
	if !exists {
		return false
	}
	if session.UserID != userID {
		return false
	}
	if time.Now().After(session.ExpiresAt) {
		// Expired - will be cleaned up lazily
		return false
	}
	return true
}

// cleanExpiredParentalSessions removes expired sessions. Called periodically.
func cleanExpiredParentalSessions() {
	parentalSessionsMu.Lock()
	defer parentalSessionsMu.Unlock()

	now := time.Now()
	for key, session := range parentalSessions {
		if now.After(session.ExpiresAt) {
			delete(parentalSessions, key)
		}
	}
}

func init() {
	// Background goroutine to clean expired parental PIN sessions every 30 minutes
	go func() {
		ticker := time.NewTicker(30 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			cleanExpiredParentalSessions()
		}
	}()
}

// ========== Request/Response Types ==========

type setPINRequest struct {
	CurrentPIN string `json:"currentPin,omitempty"` // Required when changing an existing PIN
	NewPIN     string `json:"newPin" binding:"required,min=4,max=10"`
}

type verifyPINRequest struct {
	PIN string `json:"pin" binding:"required"`
}

type parentalSettingsRequest struct {
	IsRestricted *bool  `json:"isRestricted,omitempty"`
	MaxRating    string `json:"maxRating,omitempty"`
	IsKid        *bool  `json:"isKid,omitempty"`
	ProfileID    *uint  `json:"profileId,omitempty"` // Target profile (admin can update others)
}

// ========== Handlers ==========

// setParentalPIN handles PUT /api/parental/pin
// Sets or changes the parental control PIN for the current user.
func (s *Server) setParentalPIN(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	var req setPINRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// If user already has a PIN, require current PIN to change it
	if user.PIN != "" {
		if req.CurrentPIN == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Current PIN is required to change PIN"})
			return
		}
		if err := bcrypt.CompareHashAndPassword([]byte(user.PIN), []byte(req.CurrentPIN)); err != nil {
			c.JSON(http.StatusForbidden, gin.H{"error": "Current PIN is incorrect"})
			return
		}
	}

	// Hash the new PIN
	hashedPIN, err := bcrypt.GenerateFromPassword([]byte(req.NewPIN), bcrypt.DefaultCost)
	if err != nil {
		logger.Errorf("Failed to hash parental PIN: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to set PIN"})
		return
	}

	if err := s.db.Model(&user).Update("pin", string(hashedPIN)).Error; err != nil {
		logger.Errorf("Failed to save parental PIN: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save PIN"})
		return
	}

	logger.Infof("Parental PIN set for user %d", user.ID)
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Parental PIN has been set",
	})
}

// verifyParentalPIN handles POST /api/parental/verify
// Verifies the parental PIN and creates a time-limited session that bypasses
// content restrictions for 4 hours.
func (s *Server) verifyParentalPIN(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	var req verifyPINRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	if user.PIN == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No parental PIN has been set"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PIN), []byte(req.PIN)); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "Incorrect PIN"})
		return
	}

	// Get the auth token from context to key the session
	token, _ := c.Get("token")
	tokenStr, _ := token.(string)
	if tokenStr == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not create PIN session"})
		return
	}

	createParentalSession(tokenStr, userID.(uint))

	expiresAt := time.Now().Add(parentalPINSessionTTL)
	logger.Infof("Parental PIN verified for user %d, session expires at %s", user.ID, expiresAt.Format(time.RFC3339))

	c.JSON(http.StatusOK, gin.H{
		"success":   true,
		"message":   "PIN verified",
		"expiresAt": expiresAt.Format(time.RFC3339),
		"ttlSeconds": int(parentalPINSessionTTL.Seconds()),
	})
}

// getParentalSettings handles GET /api/parental/settings
// Returns the current user's parental control settings and active profile restrictions.
func (s *Server) getParentalSettings(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	var user models.User
	if err := s.db.Preload("Profiles").First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	// Check if there's an active PIN session
	token, _ := c.Get("token")
	tokenStr, _ := token.(string)
	pinSessionActive := isParentalSessionValid(tokenStr, userID.(uint))

	// Build profile summaries
	profiles := make([]gin.H, 0, len(user.Profiles))
	for _, p := range user.Profiles {
		profiles = append(profiles, gin.H{
			"id":        p.ID,
			"name":      p.Name,
			"isKid":     p.IsKid,
			"maxRating": p.MaxRating,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"hasPIN":           user.PIN != "",
		"isRestricted":     user.IsRestricted,
		"pinSessionActive": pinSessionActive,
		"profiles":         profiles,
		"ratingOptions": gin.H{
			"tv":   []string{"TV-Y", "TV-Y7", "TV-G", "TV-PG", "TV-14", "TV-MA"},
			"mpaa": []string{"G", "PG", "PG-13", "R", "NC-17"},
		},
	})
}

// updateParentalSettings handles PUT /api/parental/settings
// Updates parental control settings for the user or a specific profile.
func (s *Server) updateParentalSettings(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	var req parentalSettingsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request: " + err.Error()})
		return
	}

	// Validate rating if provided
	if req.MaxRating != "" {
		upper := strings.ToUpper(strings.TrimSpace(req.MaxRating))
		_, isTVRating := tvRatingOrder[upper]
		_, isMPAARating := mpaaRatingOrder[upper]
		if !isTVRating && !isMPAARating {
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "Invalid rating. Must be one of: TV-Y, TV-Y7, TV-G, TV-PG, TV-14, TV-MA, G, PG, PG-13, R, NC-17",
			})
			return
		}
	}

	// If profileId is specified, update the profile
	if req.ProfileID != nil {
		var profile models.UserProfile
		if err := s.db.Where("id = ? AND user_id = ?", *req.ProfileID, userID).First(&profile).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Profile not found"})
			return
		}

		updates := make(map[string]interface{})
		if req.MaxRating != "" {
			updates["max_rating"] = strings.ToUpper(strings.TrimSpace(req.MaxRating))
		}
		if req.IsKid != nil {
			updates["is_kid"] = *req.IsKid
			// Kid profiles default to TV-PG if no rating is set
			if *req.IsKid && profile.MaxRating == "" && req.MaxRating == "" {
				updates["max_rating"] = "TV-PG"
			}
		}

		if len(updates) > 0 {
			if err := s.db.Model(&profile).Updates(updates).Error; err != nil {
				logger.Errorf("Failed to update profile parental settings: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update settings"})
				return
			}
		}

		// Reload profile
		s.db.First(&profile, profile.ID)

		logger.Infof("Parental settings updated for profile %d (user %d)", profile.ID, userID)
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"profile": gin.H{
				"id":        profile.ID,
				"name":      profile.Name,
				"isKid":     profile.IsKid,
				"maxRating": profile.MaxRating,
			},
		})
		return
	}

	// Otherwise update user-level settings
	var user models.User
	if err := s.db.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	updates := make(map[string]interface{})
	if req.IsRestricted != nil {
		updates["is_restricted"] = *req.IsRestricted
	}

	if len(updates) > 0 {
		if err := s.db.Model(&user).Updates(updates).Error; err != nil {
			logger.Errorf("Failed to update user parental settings: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update settings"})
			return
		}
	}

	logger.Infof("Parental settings updated for user %d", user.ID)
	c.JSON(http.StatusOK, gin.H{
		"success":      true,
		"isRestricted": user.IsRestricted,
	})
}
