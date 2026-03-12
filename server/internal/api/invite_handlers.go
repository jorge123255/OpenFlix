package api

import (
	"crypto/rand"
	"math/big"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/auth"
	"github.com/openflix/openflix-server/internal/models"
)

const (
	inviteTokenLength = 8
	inviteTokenExpiry = 7 * 24 * time.Hour // 7 days
	inviteTokenChars  = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
)

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

	entry := models.InviteToken{
		Token:     strings.ToUpper(token),
		CreatedBy: userID,
		ExpiresAt: time.Now().Add(inviteTokenExpiry),
	}

	if err := s.db.Create(&entry).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to persist invite"})
		return
	}

	// Push updated invite list to cloud registry immediately
	s.syncInvitesToRegistry()

	// Build deep link: openflix://invite/MACHINEID/TOKEN
	machineID := s.config.Server.MachineID
	deepLink := "openflix://invite/" + machineID + "/" + token

	c.JSON(http.StatusOK, gin.H{
		"token":     token,
		"deepLink":  deepLink,
		"machineId": machineID,
		"expiresAt": entry.ExpiresAt,
		"expiresIn": inviteTokenExpiry.Seconds(),
	})
}

// GET /api/invite/:token — validate invite and return server info (public, no auth)
func (s *Server) validateInvite(c *gin.Context) {
	entry, err := s.findActiveInvite(c.Param("token"))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "invite not found or expired"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"valid":      true,
		"serverName": s.config.Server.Name,
		"machineId":  s.config.Server.MachineID,
		"expiresAt":  entry.ExpiresAt,
	})
}

// POST /api/invite/:token/accept — register a new user via invite
func (s *Server) acceptInvite(c *gin.Context) {
	entry, err := s.findActiveInvite(c.Param("token"))
	if err != nil {
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
	usedAt := time.Now()
	if err := s.db.Model(entry).Update("used_at", usedAt).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to consume invite"})
		return
	}

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
	now := time.Now()
	var inviteRows []models.InviteToken
	if err := s.db.
		Where("used_at IS NULL AND expires_at > ?", now).
		Find(&inviteRows).Error; err != nil {
		return
	}

	tokens := make([]string, 0, len(inviteRows))
	for _, row := range inviteRows {
		tokens = append(tokens, row.Token)
	}
	s.cloudRegistry.SetInviteTokens(tokens)
	s.cloudRegistry.RegisterNow()
}

func (s *Server) findActiveInvite(token string) (*models.InviteToken, error) {
	var invite models.InviteToken
	err := s.db.
		Where("token = ? AND used_at IS NULL AND expires_at > ?", strings.ToUpper(token), time.Now()).
		First(&invite).Error
	if err != nil {
		return nil, err
	}
	return &invite, nil
}
