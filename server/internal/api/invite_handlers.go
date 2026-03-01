package api

import (
	"crypto/rand"
	"math/big"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/auth"
)

const (
	inviteTokenLength = 8
	inviteTokenExpiry = 7 * 24 * time.Hour // 7 days
	inviteTokenChars  = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
)

// inviteEntry holds a pending invite.
type inviteEntry struct {
	token     string
	createdBy uint
	expiresAt time.Time
}

// inviteStore holds active invites in memory (survives restarts via re-generation).
type inviteStore struct {
	mu      sync.RWMutex
	invites map[string]*inviteEntry // token → entry
}

var invites = &inviteStore{invites: make(map[string]*inviteEntry)}

func generateInviteToken() (string, error) {
	result := make([]byte, inviteTokenLength)
	for i := range result {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(inviteTokenChars))))
		if err != nil {
			return "", err
		}
		result[i] = inviteTokenChars[n.Int64()]
	}
	return string(result), nil
}

// POST /api/invite — generate an invite token (admin only)
func (s *Server) createInvite(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	token, err := generateInviteToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate invite"})
		return
	}

	entry := &inviteEntry{
		token:     token,
		createdBy: userID,
		expiresAt: time.Now().Add(inviteTokenExpiry),
	}

	invites.mu.Lock()
	invites.invites[token] = entry
	invites.mu.Unlock()

	// Push updated invite list to cloud registry immediately
	s.syncInvitesToRegistry()

	// Build deep link: openflix://invite/MACHINEID/TOKEN
	machineID := s.config.Server.MachineID
	deepLink := "openflix://invite/" + machineID + "/" + token

	c.JSON(http.StatusOK, gin.H{
		"token":     token,
		"deepLink":  deepLink,
		"machineId": machineID,
		"expiresAt": entry.expiresAt,
		"expiresIn": inviteTokenExpiry.Seconds(),
	})
}

// GET /api/invite/:token — validate invite and return server info (public, no auth)
func (s *Server) validateInvite(c *gin.Context) {
	token := c.Param("token")

	invites.mu.RLock()
	entry, ok := invites.invites[token]
	invites.mu.RUnlock()

	if !ok || time.Now().After(entry.expiresAt) {
		c.JSON(http.StatusNotFound, gin.H{"error": "invite not found or expired"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"valid":     true,
		"serverName": s.config.Server.Name,
		"machineId": s.config.Server.MachineID,
		"expiresAt": entry.expiresAt,
	})
}

// POST /api/invite/:token/accept — register a new user via invite
func (s *Server) acceptInvite(c *gin.Context) {
	token := c.Param("token")

	invites.mu.RLock()
	entry, ok := invites.invites[token]
	invites.mu.RUnlock()

	if !ok || time.Now().After(entry.expiresAt) {
		c.JSON(http.StatusNotFound, gin.H{"error": "invite not found or expired"})
		return
	}

	var input auth.RegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	response, err := s.authService.Register(input)
	if err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "username or email already exists"})
		return
	}

	// Consume the invite (single use)
	invites.mu.Lock()
	delete(invites.invites, token)
	invites.mu.Unlock()

	// Update cloud registry with remaining invite tokens
	s.syncInvitesToRegistry()

	c.JSON(http.StatusCreated, gin.H{
		"authToken": response.Token,
		"user":      response.User,
		"machineId": s.config.Server.MachineID,
	})
}

// syncInvitesToRegistry pushes active invite tokens to the cloud registry heartbeat.
func (s *Server) syncInvitesToRegistry() {
	if s.cloudRegistry == nil {
		return
	}
	invites.mu.RLock()
	tokens := make([]string, 0, len(invites.invites))
	now := time.Now()
	for t, e := range invites.invites {
		if now.Before(e.expiresAt) {
			tokens = append(tokens, t)
		}
	}
	invites.mu.RUnlock()
	s.cloudRegistry.SetInviteTokens(tokens)
}
