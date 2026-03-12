package api

import (
	"crypto/rand"
	"math/big"
	"net/http"
	"os"
	"path/filepath"
	"sync"

	"github.com/gin-gonic/gin"
)

// persistClaimTokenFile writes the token to the standard persistent paths so it
// survives container restarts after an admin-initiated rotation.
func persistClaimTokenFile(token string) {
	paths := []string{
		"/data/claim-token",
		filepath.Join(os.Getenv("HOME"), ".openflix", "claim-token"),
	}
	for _, path := range paths {
		dir := filepath.Dir(path)
		if err := os.MkdirAll(dir, 0755); err != nil {
			continue
		}
		if err := os.WriteFile(path, []byte(token), 0644); err == nil {
			return
		}
	}
}

const (
	claimTokenLength = 4
	claimTokenChars  = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // no I/O/0/1 to avoid confusion
)

// claimTokenStore holds the current permanent claim token.
type claimTokenStore struct {
	mu    sync.RWMutex
	token string
}

var claimStore = &claimTokenStore{}

// InitClaimToken loads the persistent token (from config) into the in-memory store
// at startup so it is immediately available without any manual action.
func InitClaimToken(token string) {
	if token == "" {
		return
	}
	claimStore.mu.Lock()
	claimStore.token = token
	claimStore.mu.Unlock()
}

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

// postClaimToken rotates the claim token (admin only).
// POST /api/claim-token
func (s *Server) postClaimToken(c *gin.Context) {
	token, err := generateClaimToken()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate claim token"})
		return
	}

	claimStore.mu.Lock()
	claimStore.token = token
	claimStore.mu.Unlock()

	// Persist so the rotated token survives restarts.
	persistClaimTokenFile(token)

	if s.cloudRegistry != nil {
		s.cloudRegistry.SetClaimToken(token)
		s.cloudRegistry.RegisterNow()
	}

	c.JSON(http.StatusOK, gin.H{"token": token})
}

// getClaimToken returns the current claim token.
// GET /api/claim-token
func (s *Server) getClaimToken(c *gin.Context) {
	claimStore.mu.RLock()
	token := claimStore.token
	claimStore.mu.RUnlock()

	if token == "" {
		c.JSON(http.StatusOK, gin.H{"token": nil, "active": false})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": token, "active": true})
}

// GetCurrentClaimToken returns the current claim token (for cloud registry).
func GetCurrentClaimToken() string {
	claimStore.mu.RLock()
	defer claimStore.mu.RUnlock()
	return claimStore.token
}
