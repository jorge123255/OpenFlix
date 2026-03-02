package api

import (
	"crypto/rand"
	"math/big"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

const (
	claimTokenLength = 4
	claimTokenExpiry = 10 * time.Minute
	claimTokenChars  = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // no I/O/0/1 to avoid confusion
)

// claimTokenStore holds the current claim token and its expiry.
type claimTokenStore struct {
	mu      sync.RWMutex
	token   string
	expires time.Time
}

var claimStore = &claimTokenStore{}

// generateClaimToken creates a random 4-character claim code.
func generateClaimToken() (string, error) {
	result := make([]byte, claimTokenLength)
	for i := range result {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(claimTokenChars))))
		if err != nil {
			return "", err
		}
		result[i] = claimTokenChars[n.Int64()]
	}
	return string(result), nil
}

// postClaimToken generates a new claim token (admin only).
// POST /api/claim-token
func (s *Server) postClaimToken(c *gin.Context) {
	token, err := generateClaimToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate claim token"})
		return
	}

	claimStore.mu.Lock()
	claimStore.token = token
	claimStore.expires = time.Now().Add(claimTokenExpiry)
	claimStore.mu.Unlock()

	// If we have a cloud registry client, update its claim token
	if s.cloudRegistry != nil {
		s.cloudRegistry.SetClaimToken(token)
	}

	c.JSON(http.StatusOK, gin.H{
		"token":   token,
		"expires": claimStore.expires,
	})
}

// getClaimToken returns the current claim token if valid.
// GET /api/claim-token
func (s *Server) getClaimToken(c *gin.Context) {
	claimStore.mu.RLock()
	defer claimStore.mu.RUnlock()

	if claimStore.token == "" || time.Now().After(claimStore.expires) {
		c.JSON(http.StatusOK, gin.H{
			"token":   nil,
			"active":  false,
			"message": "No active claim token. Generate one with POST /api/claim-token",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token":     claimStore.token,
		"active":    true,
		"expires":   claimStore.expires,
		"expiresIn": time.Until(claimStore.expires).Seconds(),
	})
}

// GetCurrentClaimToken returns the current valid claim token (for cloud registry).
func GetCurrentClaimToken() string {
	claimStore.mu.RLock()
	defer claimStore.mu.RUnlock()

	if claimStore.token == "" || time.Now().After(claimStore.expires) {
		return ""
	}
	return claimStore.token
}
