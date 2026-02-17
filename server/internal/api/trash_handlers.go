package api

import (
	"fmt"
	"net/http"
	"os"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// ============ DVR V2: Trash / Recycle Bin ============

// getTrash lists all soft-deleted DVR files with file size totals
func (s *Server) getTrash(c *gin.Context) {
	var files []models.DVRFile
	if err := s.db.Unscoped().Where("deleted = ?", true).Order("updated_at DESC").Find(&files).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch trash"})
		return
	}

	// Calculate total size of trashed files
	var totalSize int64
	for _, f := range files {
		totalSize += f.FileSize
	}

	c.JSON(http.StatusOK, gin.H{
		"files":              files,
		"totalCount":         len(files),
		"totalSize":          totalSize,
		"totalSizeFormatted": formatTrashSize(totalSize),
	})
}

// restoreFromTrash restores a soft-deleted DVR file by setting deleted=false
func (s *Server) restoreFromTrash(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	// Find the deleted file using Unscoped to include soft-deleted records
	var file models.DVRFile
	if err := s.db.Unscoped().Where("id = ? AND deleted = ?", id, true).First(&file).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found in trash"})
		return
	}

	// Restore the file by setting deleted=false and clearing DeletedAt
	if err := s.db.Unscoped().Model(&file).Updates(map[string]interface{}{
		"deleted":    false,
		"deleted_at": nil,
	}).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to restore file"})
		return
	}

	// Update group file count if the file belongs to a group
	if file.GroupID != nil {
		s.updateGroupFileCount(*file.GroupID)
	}

	logger.WithField("fileId", file.ID).Info("File restored from trash")
	c.JSON(http.StatusOK, gin.H{
		"message": "File restored from trash",
		"file":    file,
	})
}

// emptyTrash permanently deletes all trashed files from disk and database
func (s *Server) emptyTrash(c *gin.Context) {
	var files []models.DVRFile
	if err := s.db.Unscoped().Where("deleted = ?", true).Find(&files).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch trash"})
		return
	}

	if len(files) == 0 {
		c.JSON(http.StatusOK, gin.H{
			"message":      "Trash is already empty",
			"deletedCount": 0,
			"freedBytes":   int64(0),
		})
		return
	}

	var deletedCount int
	var freedBytes int64
	var errors []string

	for _, file := range files {
		// Remove file from disk if it exists
		if file.FilePath != "" {
			if info, statErr := os.Stat(file.FilePath); statErr == nil {
				freedBytes += info.Size()
				if removeErr := os.Remove(file.FilePath); removeErr != nil {
					logger.WithError(removeErr).WithField("filePath", file.FilePath).Warn("Failed to remove file from disk")
					errors = append(errors, fmt.Sprintf("Failed to remove %s: %v", file.FilePath, removeErr))
				}
			}
		}

		// Permanently delete from database
		if err := s.db.Unscoped().Delete(&file).Error; err != nil {
			logger.WithError(err).WithField("fileId", file.ID).Warn("Failed to permanently delete file from database")
			errors = append(errors, fmt.Sprintf("Failed to delete file %d from database: %v", file.ID, err))
			continue
		}
		deletedCount++
	}

	logger.WithField("deletedCount", deletedCount).Info("Trash emptied")

	result := gin.H{
		"message":            "Trash emptied",
		"deletedCount":       deletedCount,
		"freedBytes":         freedBytes,
		"freedSizeFormatted": formatTrashSize(freedBytes),
	}
	if len(errors) > 0 {
		result["errors"] = errors
	}

	c.JSON(http.StatusOK, result)
}

// permanentlyDelete permanently deletes a single file from trash (disk + database)
func (s *Server) permanentlyDelete(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid file ID"})
		return
	}

	// Find the deleted file
	var file models.DVRFile
	if err := s.db.Unscoped().Where("id = ? AND deleted = ?", id, true).First(&file).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "File not found in trash"})
		return
	}

	// Remove file from disk if it exists
	var freedBytes int64
	if file.FilePath != "" {
		if info, statErr := os.Stat(file.FilePath); statErr == nil {
			freedBytes = info.Size()
			if removeErr := os.Remove(file.FilePath); removeErr != nil {
				logger.WithError(removeErr).WithField("filePath", file.FilePath).Warn("Failed to remove file from disk")
			}
		}
	}

	// Permanently delete from database
	if err := s.db.Unscoped().Delete(&file).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to permanently delete file"})
		return
	}

	logger.WithField("fileId", file.ID).Info("File permanently deleted from trash")
	c.JSON(http.StatusOK, gin.H{
		"message":            "File permanently deleted",
		"freedBytes":         freedBytes,
		"freedSizeFormatted": formatTrashSize(freedBytes),
	})
}

// formatTrashSize formats bytes to a human-readable string
func formatTrashSize(bytes int64) string {
	if bytes == 0 {
		return "0 B"
	}
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := int64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}
