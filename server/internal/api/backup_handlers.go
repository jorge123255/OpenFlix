package api

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/logger"
)

// ============ Admin: Database Backup & Restore ============

// createBackup creates a backup of the SQLite database using VACUUM INTO
func (s *Server) createBackup(c *gin.Context) {
	backupDir := filepath.Join(s.config.GetDataDir(), "backups")
	if err := os.MkdirAll(backupDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create backup directory: %v", err)})
		return
	}

	timestamp := time.Now().Format("20060102-150405")
	backupFilename := fmt.Sprintf("openflix-backup-%s.db", timestamp)
	backupPath := filepath.Join(backupDir, backupFilename)

	// Use VACUUM INTO for a safe, consistent SQLite backup
	vacuumSQL := fmt.Sprintf("VACUUM INTO '%s'", backupPath)
	sqlDB, err := s.db.DB()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to access database connection"})
		return
	}

	if _, err := sqlDB.Exec(vacuumSQL); err != nil {
		// Fall back to file copy if VACUUM INTO is not supported
		logger.WithError(err).Warn("VACUUM INTO failed, falling back to file copy")

		srcPath := s.config.Database.DSN
		if copyErr := copyFile(srcPath, backupPath); copyErr != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create backup: %v", copyErr)})
			return
		}
	}

	// Get backup file info
	info, err := os.Stat(backupPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Backup created but failed to read file info"})
		return
	}

	logger.WithField("backup", backupFilename).Info("Database backup created")
	c.JSON(http.StatusCreated, gin.H{
		"message":       "Backup created successfully",
		"filename":      backupFilename,
		"size":          info.Size(),
		"sizeFormatted": formatBackupSize(info.Size()),
		"createdAt":     info.ModTime(),
	})
}

// listBackups lists all available database backups with size and date
func (s *Server) listBackups(c *gin.Context) {
	backupDir := filepath.Join(s.config.GetDataDir(), "backups")

	entries, err := os.ReadDir(backupDir)
	if err != nil {
		if os.IsNotExist(err) {
			c.JSON(http.StatusOK, gin.H{"backups": []interface{}{}, "totalCount": 0})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to list backups"})
		return
	}

	type BackupInfo struct {
		Filename      string    `json:"filename"`
		Size          int64     `json:"size"`
		SizeFormatted string    `json:"sizeFormatted"`
		CreatedAt     time.Time `json:"createdAt"`
	}

	backups := make([]BackupInfo, 0)
	var totalSize int64

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if !strings.HasSuffix(name, ".db") {
			continue
		}

		info, err := entry.Info()
		if err != nil {
			continue
		}

		totalSize += info.Size()
		backups = append(backups, BackupInfo{
			Filename:      name,
			Size:          info.Size(),
			SizeFormatted: formatBackupSize(info.Size()),
			CreatedAt:     info.ModTime(),
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"backups":            backups,
		"totalCount":         len(backups),
		"totalSize":          totalSize,
		"totalSizeFormatted": formatBackupSize(totalSize),
	})
}

// downloadBackup downloads a backup file
func (s *Server) downloadBackup(c *gin.Context) {
	filename := c.Param("filename")
	if filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Filename is required"})
		return
	}

	// Sanitize filename to prevent directory traversal
	filename = filepath.Base(filename)
	if !strings.HasSuffix(filename, ".db") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid backup filename"})
		return
	}

	backupPath := filepath.Join(s.config.GetDataDir(), "backups", filename)

	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Backup not found"})
		return
	}

	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", filename))
	c.Header("Content-Type", "application/octet-stream")
	c.File(backupPath)
}

// deleteBackup deletes a backup file
func (s *Server) deleteBackup(c *gin.Context) {
	filename := c.Param("filename")
	if filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Filename is required"})
		return
	}

	// Sanitize filename to prevent directory traversal
	filename = filepath.Base(filename)
	if !strings.HasSuffix(filename, ".db") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid backup filename"})
		return
	}

	backupPath := filepath.Join(s.config.GetDataDir(), "backups", filename)

	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Backup not found"})
		return
	}

	if err := os.Remove(backupPath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to delete backup: %v", err)})
		return
	}

	logger.WithField("backup", filename).Info("Database backup deleted")
	c.JSON(http.StatusOK, gin.H{"message": "Backup deleted", "filename": filename})
}

// restoreBackup restores the database from a backup file
func (s *Server) restoreBackup(c *gin.Context) {
	filename := c.Param("filename")
	if filename == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Filename is required"})
		return
	}

	// Sanitize filename to prevent directory traversal
	filename = filepath.Base(filename)
	if !strings.HasSuffix(filename, ".db") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid backup filename"})
		return
	}

	backupPath := filepath.Join(s.config.GetDataDir(), "backups", filename)

	if _, err := os.Stat(backupPath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"error": "Backup not found"})
		return
	}

	dbPath := s.config.Database.DSN

	// Create a safety backup of the current database before restoring
	safetyBackupPath := dbPath + ".pre-restore-" + time.Now().Format("20060102-150405")
	if err := copyFile(dbPath, safetyBackupPath); err != nil {
		logger.WithError(err).Warn("Failed to create safety backup before restore")
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create safety backup of current database"})
		return
	}

	// Copy the backup over the current database
	if err := copyFile(backupPath, dbPath); err != nil {
		// Attempt to restore from safety backup
		logger.WithError(err).Error("Failed to restore from backup, attempting rollback")
		if rollbackErr := copyFile(safetyBackupPath, dbPath); rollbackErr != nil {
			logger.WithError(rollbackErr).Error("Failed to rollback after failed restore")
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to restore from backup: %v", err)})
		return
	}

	logger.WithField("backup", filename).Warn("Database restored from backup - server restart recommended")
	c.JSON(http.StatusOK, gin.H{
		"message":      "Database restored from backup. A server restart is recommended to ensure all connections use the restored data.",
		"filename":     filename,
		"safetyBackup": filepath.Base(safetyBackupPath),
	})
}

// copyFile copies a file from src to dst
func copyFile(src, dst string) error {
	srcFile, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("failed to open source file: %w", err)
	}
	defer srcFile.Close()

	dstFile, err := os.Create(dst)
	if err != nil {
		return fmt.Errorf("failed to create destination file: %w", err)
	}
	defer dstFile.Close()

	if _, err := io.Copy(dstFile, srcFile); err != nil {
		return fmt.Errorf("failed to copy file: %w", err)
	}

	return dstFile.Sync()
}

// formatBackupSize formats bytes to a human-readable string
func formatBackupSize(bytes int64) string {
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
