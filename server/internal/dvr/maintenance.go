package dvr

import (
	"time"

	"gorm.io/gorm"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
)

// MaintenanceConfig holds settings for database maintenance
type MaintenanceConfig struct {
	// How often to run maintenance (default: 6 hours)
	Interval time.Duration
	// Delete failed/cancelled jobs older than this (default: 7 days)
	PurgeFailedAfter time.Duration
	// Delete old programs (EPG data) older than this (default: 14 days)
	PurgeEPGAfter time.Duration
}

// DefaultMaintenanceConfig returns sensible defaults
func DefaultMaintenanceConfig() MaintenanceConfig {
	return MaintenanceConfig{
		Interval:         6 * time.Hour,
		PurgeFailedAfter: 7 * 24 * time.Hour,
		PurgeEPGAfter:    14 * 24 * time.Hour,
	}
}

// StartMaintenance runs periodic database cleanup
func StartMaintenance(db *gorm.DB, cfg MaintenanceConfig) {
	go func() {
		// Run once at startup after a delay
		time.Sleep(5 * time.Minute)
		runMaintenance(db, cfg)

		ticker := time.NewTicker(cfg.Interval)
		defer ticker.Stop()

		for range ticker.C {
			runMaintenance(db, cfg)
		}
	}()
	logger.Log.Info("Database maintenance scheduler started")
}

func runMaintenance(db *gorm.DB, cfg MaintenanceConfig) {
	logger.Log.Info("Running database maintenance...")
	start := time.Now()

	// 1. Purge old failed/cancelled DVR jobs
	failedCutoff := time.Now().Add(-cfg.PurgeFailedAfter)
	result := db.Where("status IN ? AND updated_at < ?", []string{"failed", "cancelled"}, failedCutoff).
		Delete(&models.DVRJob{})
	if result.RowsAffected > 0 {
		logger.Log.Infof("Purged %d old failed/cancelled DVR jobs", result.RowsAffected)
	}

	// 2. Purge old EPG programs (past airings)
	epgCutoff := time.Now().Add(-cfg.PurgeEPGAfter)
	result = db.Where("end < ?", epgCutoff).Delete(&models.Program{})
	if result.RowsAffected > 0 {
		logger.Log.Infof("Purged %d old EPG programs", result.RowsAffected)
	}

	// 3. Clean orphaned recordings (no file, not scheduled)
	result = db.Where("status = ? AND file_path = '' AND start_time < ?", "completed", time.Now().Add(-24*time.Hour)).
		Delete(&models.Recording{})
	if result.RowsAffected > 0 {
		logger.Log.Infof("Purged %d orphaned recordings", result.RowsAffected)
	}

	// 4. VACUUM database (SQLite only)
	db.Exec("VACUUM")

	logger.Log.Infof("Database maintenance completed in %v", time.Since(start))
}
