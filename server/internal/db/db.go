package db

import (
	"fmt"
	"log"

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
		// Add WAL mode for better concurrent read access during EPG updates
		dsn := cfg.DSN
		if dsn != "" && dsn != ":memory:" {
			dsn = dsn + "?_journal_mode=WAL&_busy_timeout=5000"
		}
		dialector = sqlite.Open(dsn)
	case "postgres":
		dialector = postgres.Open(cfg.DSN)
	default:
		return nil, fmt.Errorf("unsupported database driver: %s", cfg.Driver)
	}

	db, err := gorm.Open(dialector, &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	configureSQLitePragmas(db)

	return db, nil
}

// Migrate runs database migrations
func Migrate(db *gorm.DB) error {
	err := db.AutoMigrate(
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
		&models.WatchlistItem{},

		// Tuner Devices
		&models.TunerDevice{},

		// Live TV
		&models.M3USource{},
		&models.XtreamSource{},
		&models.EPGSource{},
		&models.Channel{},
		&models.ChannelGroup{},
		&models.ChannelGroupMember{},
		&models.Program{},

		// DVR (legacy - kept for backward compatibility)
		&models.Recording{},
		&models.SeriesRule{},
		&models.TeamPass{},
		&models.CommercialSegment{},
		&models.RecordingWatchProgress{},

		// DVR v2 (Channels DVR-style)
		&models.DVRJob{},
		&models.DVRFile{},
		&models.DetectedSegment{},
		&models.SkipEvent{},
		&models.DVRGroup{},
		&models.FileState{},
		&models.GroupState{},
		&models.DVRRule{},
		&models.VirtualStation{},
		&models.DVRCollection{},
		&models.ChannelCollection{},

		// Archive/Catch-up
		&models.ArchiveProgram{},

		// Bookmarks & Clips
		&models.Bookmark{},
		&models.Clip{},

		// Chapter Markers
		&models.ChapterMarker{},

		// Play Queues
		&models.PlayQueue{},
		&models.PlayQueueItem{},

		// Playback Sessions
		&models.PlaybackSession{},

		// Settings
		&models.Setting{},
		&models.InviteToken{},

		// Client Devices
		&models.ClientDevice{},

		// Offline Downloads
		&models.OfflineDownload{},

		// Personal Sections
		&models.PersonalSection{},
		&models.PersonalSectionItem{},

		// Show Trackers (new season notifications)
		&models.ShowTracker{},
	)
	if err != nil {
		return err
	}

	// Run data migrations
	if err := MigrateRecordingsToDVR(db); err != nil {
		log.Printf("Warning: DVR migration had issues: %v", err)
	}

	ensureCriticalIndexes(db)

	// Ensure performance indexes exist (idempotent — IF NOT EXISTS).
	// Run in background so startup isn't blocked on slow NAS-backed SQLite.
	go ensureIndexes(db)

	return nil
}

// ensureIndexes creates indexes that GORM's AutoMigrate doesn't handle well,
// particularly for text search patterns on large tables like programs.
func ensureIndexes(db *gorm.DB) {
	indexes := []string{
		// Programs: title search (LIKE '%query%' still can't use B-tree, but
		// this index helps exact/prefix lookups and ORDER BY start)
		`CREATE INDEX IF NOT EXISTS idx_programs_title_lower ON programs (LOWER(title))`,
		`CREATE INDEX IF NOT EXISTS idx_programs_start ON programs (start)`,
		`CREATE INDEX IF NOT EXISTS idx_programs_end ON programs ("end")`,
		// DVR jobs: watchdog query (orphaned jobs with legacy_recording_id set)
		`CREATE INDEX IF NOT EXISTS idx_dvr_jobs_status_legacy ON dvr_jobs (status, legacy_recording_id)`,
	}
	for _, idx := range indexes {
		if err := db.Exec(idx).Error; err != nil {
			log.Printf("Warning: failed to create index: %v", err)
		}
	}
}

func ensureCriticalIndexes(db *gorm.DB) {
	if err := dedupeProgramsForUpsert(db); err != nil {
		log.Printf("Warning: failed to dedupe programs before creating unique index: %v", err)
	}
	if err := db.Exec(
		`CREATE UNIQUE INDEX IF NOT EXISTS idx_programs_channel_start_unique ON programs (channel_id, start)`,
	).Error; err != nil {
		log.Printf("Warning: failed to create unique programs index: %v", err)
	}
	if err := db.Exec(`DROP INDEX IF EXISTS idx_programs_channel_start`).Error; err != nil {
		log.Printf("Warning: failed to drop redundant programs index: %v", err)
	}
}

func dedupeProgramsForUpsert(db *gorm.DB) error {
	return db.Exec(`
		DELETE FROM programs
		WHERE id IN (
			SELECT older.id
			FROM programs AS older
			JOIN programs AS newer
				ON older.channel_id = newer.channel_id
				AND older.start = newer.start
				AND older.id < newer.id
		)
	`).Error
}
