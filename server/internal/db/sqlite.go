package db

import (
	"fmt"
	"strings"

	"gorm.io/gorm"
)

func isSQLite(db *gorm.DB) bool {
	return db != nil && db.Dialector != nil && db.Dialector.Name() == "sqlite"
}

func configureSQLitePragmas(db *gorm.DB) {
	if !isSQLite(db) {
		return
	}

	db.Exec("PRAGMA journal_mode=WAL")
	db.Exec("PRAGMA busy_timeout=5000")
	db.Exec("PRAGMA wal_autocheckpoint=200")
	db.Exec("PRAGMA foreign_keys=ON")
}

// CheckpointSQLite requests a WAL checkpoint for SQLite databases.
// PASSIVE is safe for public deployments because it avoids blocking readers.
func CheckpointSQLite(db *gorm.DB, mode string) error {
	if !isSQLite(db) {
		return nil
	}

	mode = strings.ToUpper(strings.TrimSpace(mode))
	switch mode {
	case "", "PASSIVE", "FULL", "RESTART", "TRUNCATE":
	default:
		return fmt.Errorf("unsupported sqlite checkpoint mode %q", mode)
	}
	if mode == "" {
		mode = "PASSIVE"
	}

	return db.Exec("PRAGMA wal_checkpoint(" + mode + ")").Error
}
