package db

import (
	"fmt"

	"github.com/openflix/openflix-server/internal/config"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Initialize creates and returns a database connection
func Initialize(cfg config.DatabaseConfig) (*gorm.DB, error) {
	var dialector gorm.Dialector

	switch cfg.Driver {
	case "sqlite":
		dialector = sqlite.Open(cfg.DSN)
	case "postgres":
		dialector = postgres.Open(cfg.DSN)
	default:
		return nil, fmt.Errorf("unsupported database driver: %s", cfg.Driver)
	}

	db, err := gorm.Open(dialector, &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	return db, nil
}

// Migrate runs database migrations
func Migrate(db *gorm.DB) error {
	return db.AutoMigrate(
		// Users
		&models.User{},
		&models.UserProfile{},

		// Libraries
		&models.Library{},
		&models.LibraryPath{},

		// Media
		&models.MediaItem{},
		&models.MediaFile{},
		&models.MediaStream{},
		&models.Genre{},
		&models.CastMember{},

		// User activity
		&models.WatchHistory{},

		// Playlists & Collections
		&models.Playlist{},
		&models.PlaylistItem{},
		&models.Collection{},
		&models.CollectionItem{},

		// Live TV
		&models.M3USource{},
		&models.XtreamSource{},
		&models.EPGSource{},
		&models.Channel{},
		&models.Program{},

		// DVR
		&models.Recording{},
		&models.SeriesRule{},

		// Archive/Catch-up
		&models.ArchiveProgram{},

		// Play Queues
		&models.PlayQueue{},
		&models.PlayQueueItem{},

		// Playback Sessions
		&models.PlaybackSession{},
	)
}
