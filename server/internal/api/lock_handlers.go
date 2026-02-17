package api

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ DVR V2: Lock/Unlock Recordings ============

// lockFile sets the "Locked" label on a DVR file to protect it from auto-pruning.
// PUT /dvr/v2/files/:id/lock
func (s *Server) lockFile(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var file models.DVRFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	// Check if already locked
	if hasLockLabel(file.Labels) {
		c.JSON(http.StatusOK, gin.H{
			"message": "File is already locked",
			"file":    file,
		})
		return
	}

	// Add "Locked" to the labels
	file.Labels = addLabel(file.Labels, "Locked")
	if err := s.db.Save(&file).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to lock file"})
		return
	}

	logger.WithField("fileId", file.ID).Info("File locked")
	c.JSON(http.StatusOK, gin.H{
		"message": "File locked",
		"file":    file,
	})
}

// unlockFile removes the "Locked" label from a DVR file.
// DELETE /dvr/v2/files/:id/lock
func (s *Server) unlockFile(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	var file models.DVRFile
	if err := s.db.First(&file, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found"})
		return
	}

	// Check if it is actually locked
	if !hasLockLabel(file.Labels) {
		c.JSON(http.StatusOK, gin.H{
			"message": "File is not locked",
			"file":    file,
		})
		return
	}

	// Remove "Locked" from the labels
	file.Labels = removeLabel(file.Labels, "Locked")
	if err := s.db.Save(&file).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to unlock file"})
		return
	}

	logger.WithField("fileId", file.ID).Info("File unlocked")
	c.JSON(http.StatusOK, gin.H{
		"message": "File unlocked",
		"file":    file,
	})
}

// getLockedFiles returns all DVR files that have the "Locked" label.
// GET /dvr/v2/files/locked
func (s *Server) getLockedFiles(c *gin.Context) {
	var files []models.DVRFile
	if err := s.db.Where("labels LIKE ? AND deleted = ?", "%Locked%", false).
		Order("created_at DESC").
		Find(&files).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch locked files"})
		return
	}

	// Filter to ensure exact label match (not just substring)
	var locked []models.DVRFile
	for _, f := range files {
		if hasLockLabel(f.Labels) {
			locked = append(locked, f)
		}
	}

	if locked == nil {
		locked = []models.DVRFile{}
	}

	c.JSON(http.StatusOK, gin.H{
		"files":      locked,
		"totalCount": len(locked),
	})
}

// getPrunerStatus returns the current status of the auto-pruner.
// GET /admin/pruner/status
func (s *Server) getPrunerStatus(c *gin.Context) {
	// Pruner status will be wired in when server.go is updated
	c.JSON(http.StatusOK, gin.H{
		"enabled": false,
		"message": "Pruner not yet configured",
	})
}

// ============ Label Helpers ============

// hasLockLabel checks if the comma-separated labels string contains "Locked"
func hasLockLabel(labels string) bool {
	if labels == "" {
		return false
	}
	for _, l := range splitLabelString(labels) {
		if l == "Locked" {
			return true
		}
	}
	return false
}

// addLabel adds a label to a comma-separated labels string if not already present
func addLabel(labels, label string) string {
	existing := splitLabelString(labels)
	for _, l := range existing {
		if l == label {
			return labels // Already present
		}
	}
	if labels == "" {
		return label
	}
	return labels + "," + label
}

// removeLabel removes a label from a comma-separated labels string
func removeLabel(labels, label string) string {
	existing := splitLabelString(labels)
	var result []string
	for _, l := range existing {
		if l != label {
			result = append(result, l)
		}
	}
	return strings.Join(result, ",")
}

// splitLabelString splits a comma-separated labels string into trimmed individual labels
func splitLabelString(labels string) []string {
	if labels == "" {
		return nil
	}
	parts := strings.Split(labels, ",")
	var result []string
	for _, p := range parts {
		trimmed := strings.TrimSpace(p)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}
