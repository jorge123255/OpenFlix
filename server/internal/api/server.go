package api

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/auth"
	"github.com/openflix/openflix-server/internal/commercial"
	"github.com/openflix/openflix-server/internal/config"
	"github.com/openflix/openflix-server/internal/ddns"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/health"
	"github.com/openflix/openflix-server/internal/instant"
	"github.com/openflix/openflix-server/internal/jobq"
	"github.com/openflix/openflix-server/internal/library"
	"github.com/openflix/openflix-server/internal/livetv"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/metadata"
	"github.com/openflix/openflix-server/internal/models"
	"github.com/openflix/openflix-server/internal/multiview"
	"github.com/openflix/openflix-server/internal/notify"
	"github.com/openflix/openflix-server/internal/scheduler"
	"github.com/openflix/openflix-server/internal/search"
	"github.com/openflix/openflix-server/internal/sports"
	"github.com/openflix/openflix-server/internal/subtitles"
	"github.com/openflix/openflix-server/internal/transcode"
	"github.com/openflix/openflix-server/internal/updater"
	limiter "github.com/ulule/limiter/v3"
	mgin "github.com/ulule/limiter/v3/drivers/middleware/gin"
	"github.com/ulule/limiter/v3/drivers/store/memory"
	"gorm.io/gorm"
)

// Server represents the API server
type Server struct {
	config            *config.Config
	db                *gorm.DB
	router            *gin.Engine
	authService       *auth.Service
	libraryService    *library.Service
	scanner           *library.Scanner
	transcoder        *transcode.Transcoder
	recorder          *dvr.Recorder
	epgService        *EPGService
	epgScheduler      *livetv.EPGScheduler
	guideCache        *livetv.GuideCache
	timeshiftBuffer   *livetv.TimeShiftBuffer
	archiveManager    *livetv.ArchiveManager
	metadataScheduler *metadata.Scheduler
	epgEnricher       *livetv.EPGEnricher
	dvrEnricher       *dvr.Enricher
	remoteAccess       *livetv.RemoteAccessManager
	prebuffer          *instant.PrebufferManager
	multiviewManager   *multiview.MultiviewManager
	searchEngine       *search.SearchEngine
	updater            *updater.Updater
	jobQueue           *jobq.JobQueue
	clipManager        *dvr.ClipManager
	bandwidthManager   *transcode.BandwidthManager
	ddnsClient         *ddns.Client
	notifyManager      *notify.NotificationManager
	healthMonitor      *health.StreamHealthMonitor
	taskScheduler      *scheduler.TaskScheduler
	subtitleManager    *subtitles.SubtitleManager
}

// NewServer creates a new API server
func NewServer(cfg *config.Config, db *gorm.DB) *Server {
	dataDir := cfg.GetDataDir()
	scanner := library.NewScanner(db)

	// Initialize TMDB agent and metadata scheduler if API key is configured
	var metadataScheduler *metadata.Scheduler
	var epgEnricher *livetv.EPGEnricher
	var dvrEnricher *dvr.Enricher
	if cfg.Library.TMDBApiKey != "" {
		tmdbAgent := metadata.NewTMDBAgent(cfg.Library.TMDBApiKey, db, dataDir)
		scanner.SetTMDBAgent(tmdbAgent)
		logger.Info("TMDB metadata agent enabled")

		// Start automatic metadata scheduler (checks every 2 minutes)
		metadataScheduler = metadata.NewScheduler(db, tmdbAgent, 2)
		metadataScheduler.Start()
		logger.Info("Metadata auto-refresh enabled (every 2 minutes)")

		// Initialize EPG enricher for program artwork
		epgEnricher = livetv.NewEPGEnricher(db, tmdbAgent)
		logger.Info("EPG artwork enrichment enabled")

		// Initialize DVR enricher for recording metadata
		dvrEnricher = dvr.NewEnricher(db, tmdbAgent)
		logger.Info("DVR metadata enrichment enabled")
	}

	// Initialize transcoder
	var transcoder *transcode.Transcoder
	if cfg.Transcode.Enabled {
		hwAccel := cfg.Transcode.HardwareAccel
		if hwAccel == "auto" {
			hwAccel = transcode.DetectHardwareAccel(cfg.Transcode.FFmpegPath)
			logger.Infof("Auto-detected hardware acceleration: %s", hwAccel)
		}
		transcoder = transcode.NewTranscoder(
			cfg.Transcode.FFmpegPath,
			cfg.Transcode.TempDir,
			hwAccel,
			cfg.Transcode.MaxSessions,
		)
		logger.Info("Transcoding enabled")
	}

	// Initialize DVR recorder with commercial detection
	var recorder *dvr.Recorder
	if cfg.DVR.Enabled {
		recorder = dvr.NewRecorder(db, dvr.RecorderConfig{
			FFmpegPath:       cfg.Transcode.FFmpegPath,
			RecordingsDir:    cfg.DVR.RecordingDir,
			ComskipPath:      cfg.DVR.ComskipPath,
			ComskipINIPath:   cfg.DVR.ComskipINIPath,
			CommercialDetect: cfg.DVR.CommercialDetect,
		})
		logger.Info("DVR recording enabled")
		if cfg.DVR.CommercialDetect {
			logger.Info("Commercial detection enabled")
		}
	}

	// Initialize EPG service
	epgService := NewEPGService()

	// Initialize EPG scheduler for automatic refresh
	epgScheduler := livetv.NewEPGScheduler(db, livetv.EPGSchedulerConfig{
		RefreshInterval: cfg.LiveTV.EPGInterval,
		Enabled:         cfg.LiveTV.Enabled,
	})
	if cfg.LiveTV.Enabled && cfg.LiveTV.EPGInterval > 0 {
		logger.Infof("EPG auto-refresh enabled (every %d hours)", cfg.LiveTV.EPGInterval)
	}

	// Initialize guide cache for EPG queries (5 minute TTL, 1000 max entries)
	guideCache := livetv.NewGuideCache(5*time.Minute, 1000)
	logger.Info("Guide cache initialized (5m TTL)")

	// Initialize TimeShift buffer for catch-up TV
	timeshiftBuffer := livetv.NewTimeShiftBuffer(db, livetv.TimeShiftConfig{
		FFmpegPath:    cfg.Transcode.FFmpegPath,
		BufferDir:     filepath.Join(dataDir, "timeshift"),
		BufferHours:   4, // Keep 4 hours of buffer
		SegmentLength: 6, // 6 second segments
	})
	logger.Info("TimeShift buffer initialized for catch-up TV")

	// Initialize Archive Manager for continuous catch-up recording
	archiveManager := livetv.NewArchiveManager(db, livetv.ArchiveConfig{
		FFmpegPath:     cfg.Transcode.FFmpegPath,
		ArchiveDir:     filepath.Join(dataDir, "archive"),
		SegmentLength:  6,  // 6 second segments
		CleanupMinutes: 30, // Cleanup every 30 minutes
		MaxDays:        7,  // Maximum 7 days archive
	})
	archiveManager.Start()
	logger.Info("Archive Manager initialized for catch-up TV")

	// Initialize Remote Access Manager for Tailscale
	remoteAccess := livetv.NewRemoteAccessManager(livetv.TailscaleConfig{
		Enabled:  true,
		Hostname: "openflix",
		Port:     cfg.Server.Port,
	})
	logger.Info("Remote Access Manager initialized")

	// Initialize Instant Switch Prebuffer Manager
	prebuffer := instant.NewPrebufferManager(6, 500, dataDir)
	logger.Info("Instant Switch Prebuffer Manager initialized")

	// Initialize full-text search engine
	var searchEngine *search.SearchEngine
	if se, err := search.NewSearchEngine(db, dataDir); err != nil {
		logger.Warnf("Failed to initialize search engine: %v", err)
	} else {
		searchEngine = se
		logger.Info("Full-text search engine initialized")
	}

	// Initialize background job queue
	jobQueue := jobq.NewJobQueue()

	// Initialize clip manager for bookmarks & clips
	clipsDir := filepath.Join(dataDir, "clips")
	clipManager := dvr.NewClipManager(db, clipsDir)
	logger.Info("Clip manager initialized")

	// Initialize bandwidth manager for adaptive bitrate streaming
	bandwidthManager := transcode.NewBandwidthManager()
	logger.Info("Bandwidth manager initialized")

	// Initialize notification manager (subscribes to DVR event bus)
	var notifyManager *notify.NotificationManager
	if recorder != nil {
		if eb := recorder.GetEventBus(); eb != nil {
			notifyManager = notify.NewNotificationManager(eb)
			notifyManager.Start()
			logger.Info("Notification manager initialized")
		}
	}

	// Initialize stream health monitor
	healthMonitor := health.NewStreamHealthMonitor()
	healthMonitor.StartBackgroundTasks()

	// Initialize DDNS client
	ddnsClient := ddns.New()
	logger.Info("DDNS client initialized")

	// Initialize self-updater
	appUpdater := updater.New(updater.Config{
		DataDir:        dataDir,
		CurrentVersion: "1.0.0", // Set at build time via ldflags
	})

	// Initialize task scheduler with default tasks
	taskSched := scheduler.NewTaskScheduler()
	taskSched.RegisterTask("epg_refresh", "EPG Refresh", "Refresh EPG data from all sources", "0 */6 * * *", 30*time.Minute, func(ctx context.Context) error {
		logger.Info("[scheduler:epg_refresh] refreshing EPG data")
		// Trigger EPG refresh via the EPG scheduler
		if epgScheduler != nil {
			epgScheduler.ForceRefresh()
		}
		return nil
	})
	taskSched.RegisterTask("library_scan", "Library Scan", "Scan library paths for new media", "0 * * * *", 30*time.Minute, func(ctx context.Context) error {
		logger.Info("[scheduler:library_scan] scanning libraries for new media")
		var libs []models.Library
		db.Preload("Paths").Find(&libs)
		for i := range libs {
			if _, err := scanner.ScanLibrary(&libs[i]); err != nil {
				logger.Warnf("[scheduler:library_scan] failed to scan library %d: %v", libs[i].ID, err)
			}
		}
		return nil
	})
	taskSched.RegisterTask("backup_db", "Database Backup", "Create a backup of the database", "0 3 * * *", 10*time.Minute, func(ctx context.Context) error {
		logger.Info("[scheduler:backup_db] creating database backup")
		backupDir := filepath.Join(dataDir, "backups")
		if err := os.MkdirAll(backupDir, 0755); err != nil {
			return fmt.Errorf("failed to create backup dir: %w", err)
		}
		timestamp := time.Now().Format("20060102-150405")
		backupPath := filepath.Join(backupDir, fmt.Sprintf("openflix-auto-%s.db", timestamp))
		sqlDB, err := db.DB()
		if err != nil {
			return fmt.Errorf("failed to get db connection: %w", err)
		}
		vacuumSQL := fmt.Sprintf("VACUUM INTO '%s'", backupPath)
		if _, err := sqlDB.Exec(vacuumSQL); err != nil {
			return fmt.Errorf("VACUUM INTO failed: %w", err)
		}
		logger.Infof("[scheduler:backup_db] backup created: %s", backupPath)
		return nil
	})
	taskSched.RegisterTask("prune_recordings", "Prune Recordings", "Clean up old recordings per retention rules", "0 4 * * *", 15*time.Minute, func(ctx context.Context) error {
		logger.Info("[scheduler:prune_recordings] checking recordings for cleanup")
		// Delete recordings that are failed and older than 7 days
		cutoff := time.Now().AddDate(0, 0, -7)
		result := db.Where("status = ? AND updated_at < ?", "failed", cutoff).Delete(&models.Recording{})
		if result.RowsAffected > 0 {
			logger.Infof("[scheduler:prune_recordings] cleaned up %d failed recordings", result.RowsAffected)
		}
		return nil
	})
	taskSched.RegisterTask("subtitle_search", "Subtitle Search", "Search subtitles for media missing them", "0 2 * * *", 30*time.Minute, func(ctx context.Context) error {
		logger.Info("[scheduler:subtitle_search] checking for media missing subtitles")
		// Placeholder: count media without subtitles
		var count int64
		db.Model(&models.MediaItem{}).Where("type IN ? AND subtitle_path = ''", []string{"movie", "episode"}).Count(&count)
		if count > 0 {
			logger.Infof("[scheduler:subtitle_search] found %d items without subtitles", count)
		}
		return nil
	})
	taskSched.RegisterTask("cleanup_sessions", "Cleanup Sessions", "Clean expired playback sessions", "*/30 * * * *", 5*time.Minute, func(ctx context.Context) error {
		// Delete sessions not updated in the last 2 hours
		cutoff := time.Now().Add(-2 * time.Hour)
		result := db.Where("updated_at < ?", cutoff).Delete(&models.PlaybackSession{})
		if result.RowsAffected > 0 {
			logger.Infof("[scheduler:cleanup_sessions] cleaned up %d stale sessions", result.RowsAffected)
		}
		return nil
	})
	taskSched.RegisterTask("health_check", "Health Check", "System health check", "*/5 * * * *", 2*time.Minute, func(ctx context.Context) error {
		// Check database connectivity
		sqlDB, err := db.DB()
		if err != nil {
			return fmt.Errorf("database connection error: %w", err)
		}
		if err := sqlDB.PingContext(ctx); err != nil {
			return fmt.Errorf("database ping failed: %w", err)
		}
		return nil
	})

	s := &Server{
		config:            cfg,
		db:                db,
		authService:       auth.NewService(db, cfg.Auth.JWTSecret, cfg.Auth.TokenExpiry),
		libraryService:    library.NewService(db, dataDir),
		scanner:           scanner,
		transcoder:        transcoder,
		recorder:          recorder,
		epgService:        epgService,
		epgScheduler:      epgScheduler,
		guideCache:        guideCache,
		timeshiftBuffer:   timeshiftBuffer,
		archiveManager:    archiveManager,
		metadataScheduler: metadataScheduler,
		epgEnricher:       epgEnricher,
		dvrEnricher:       dvrEnricher,
		remoteAccess:      remoteAccess,
		prebuffer:         prebuffer,
		searchEngine:      searchEngine,
		updater:           appUpdater,
		jobQueue:          jobQueue,
		clipManager:        clipManager,
		bandwidthManager:   bandwidthManager,
		ddnsClient:         ddnsClient,
		notifyManager:      notifyManager,
		healthMonitor:      healthMonitor,
		taskScheduler:      taskSched,
	}
	s.setupRouter()

	// Wire enricher/grouper/upnext into recorder for post-processing
	if recorder != nil && dvrEnricher != nil {
		recorder.SetEnricher(dvrEnricher)
	}

	// Start background EPG enrichment if TMDB is configured
	if epgEnricher != nil {
		epgEnricher.StartBackgroundEnrichment()
	}

	// Start background job queue
	jobQueue.Start()

	// Start self-updater background checker
	appUpdater.Start()

	// Restore persisted auto-update configuration (if any)
	s.restoreAutoUpdateConfig()

	// Restore persisted DDNS configuration (if any)
	s.loadDDNSConfig()

	// Restore persisted notification configuration (if any)
	s.loadNotificationConfig()

	// Load persisted scheduler configuration and start scheduler
	s.loadSchedulerConfig()
	taskSched.Start()
	logger.Info("Task scheduler started")

	// Load subtitle configuration and initialize SubtitleManager
	s.loadSubtitleConfig()

	// Kick off initial search index build in background
	if searchEngine != nil {
		go func() {
			if err := searchEngine.RebuildIndex(); err != nil {
				logger.Warnf("Initial search index build failed: %v", err)
			}
		}()
	}

	return s
}

// Run starts the HTTP server
func (s *Server) Run() error {
	addr := fmt.Sprintf("%s:%d", s.config.Server.Host, s.config.Server.Port)
	return s.router.Run(addr)
}

// reinitializeTMDBAgent creates or updates the TMDB agent with a new API key
func (s *Server) reinitializeTMDBAgent() {
	if s.config.Library.TMDBApiKey != "" {
		dataDir := s.config.GetDataDir()
		tmdbAgent := metadata.NewTMDBAgent(s.config.Library.TMDBApiKey, s.db, dataDir)
		s.scanner.SetTMDBAgent(tmdbAgent)

		// Update or start metadata scheduler
		if s.metadataScheduler != nil {
			s.metadataScheduler.SetTMDBAgent(tmdbAgent)
		} else {
			s.metadataScheduler = metadata.NewScheduler(s.db, tmdbAgent, 2)
			s.metadataScheduler.Start()
		}

		// Stop old enricher if running
		if s.epgEnricher != nil {
			s.epgEnricher.StopBackgroundEnrichment()
		}

		// Initialize and start EPG enricher for program artwork
		s.epgEnricher = livetv.NewEPGEnricher(s.db, tmdbAgent)
		s.epgEnricher.StartBackgroundEnrichment()
		logger.Info("TMDB metadata agent re-initialized with new API key")
		logger.Info("EPG artwork enrichment enabled")
	} else {
		s.scanner.SetTMDBAgent(nil)
		if s.metadataScheduler != nil {
			s.metadataScheduler.SetTMDBAgent(nil)
		}
		if s.epgEnricher != nil {
			s.epgEnricher.StopBackgroundEnrichment()
		}
		s.epgEnricher = nil
		logger.Info("TMDB metadata agent disabled (no API key)")
	}
}

// setupRouter configures all routes
func (s *Server) setupRouter() {
	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(s.loggerMiddleware())
	r.Use(s.corsMiddleware())

	// Health check
	r.GET("/health", s.healthCheck)

	// App Downloads (public - no auth required)
	r.GET("/downloads", s.getAvailableDownloads)
	r.GET("/downloads/:filename", s.downloadApp)

	// Web Admin UI
	s.setupWebUI(r)

	// Server identity (Plex-compatible)
	r.GET("/", s.getServerInfo)
	r.GET("/identity", s.getServerIdentity)
	r.GET("/api/status", s.authRequired(), s.getServerStatus)
	r.GET("/api/dashboard", s.authRequired(), s.getDashboardData)

	// Diagnostics & System Status API (admin only)
	r.GET("/api/diagnostics/health-check", s.authRequired(), s.adminRequired(), s.runHealthChecks)
	r.GET("/api/system/status", s.authRequired(), s.adminRequired(), s.getSystemStatus)

	// Logs API (admin only)
	r.GET("/api/logs", s.authRequired(), s.adminRequired(), s.getLogs)
	r.DELETE("/api/logs", s.authRequired(), s.adminRequired(), s.clearLogs)

	// Client logs API (any authenticated user can submit, admin can view)
	r.POST("/api/client-logs", s.authRequired(), s.submitClientLogs)
	r.GET("/api/client-logs", s.authRequired(), s.adminRequired(), s.getClientLogs)
	r.DELETE("/api/client-logs", s.authRequired(), s.adminRequired(), s.clearClientLogs)

	// Transcoding API (admin only)
	r.GET("/api/transcode", s.authRequired(), s.adminRequired(), s.getTranscodeInfo)

	// ============ Auth API ============
	// Rate limiter for auth endpoints: 10 requests per minute per IP
	rate, _ := limiter.NewRateFromFormatted("10-M")
	authLimiterStore := memory.NewStore()
	authLimiter := mgin.NewMiddleware(limiter.New(authLimiterStore, rate))

	// Simplified auth (not Plex.tv dependent)
	authGroup := r.Group("/auth")
	{
		// Apply stricter rate limiting to login/register to prevent brute force
		authGroup.POST("/register", authLimiter, s.register)
		authGroup.POST("/login", authLimiter, s.login)
		authGroup.POST("/logout", s.authRequired(), s.logout)
		authGroup.GET("/user", s.authRequired(), s.getCurrentUser)
		authGroup.PUT("/user", s.authRequired(), s.updateCurrentUser)
		authGroup.PUT("/user/password", s.authRequired(), authLimiter, s.changePassword)
	}

	// ============ User Profiles API ============
	profiles := r.Group("/profiles")
	profiles.Use(s.authRequired())
	{
		profiles.GET("", s.getProfiles)
		profiles.POST("", s.createProfile)
		profiles.GET("/:id", s.getProfile)
		profiles.PUT("/:id", s.updateProfile)
		profiles.DELETE("/:id", s.deleteProfile)
		profiles.POST("/:id/switch", s.switchProfile)
	}

	// ============ Parental Controls API ============
	parentalGroup := r.Group("/api/parental")
	parentalGroup.Use(s.authRequired())
	{
		parentalGroup.PUT("/pin", s.setParentalPIN)
		parentalGroup.POST("/verify", s.verifyParentalPIN)
		parentalGroup.GET("/settings", s.getParentalSettings)
		parentalGroup.PUT("/settings", s.updateParentalSettings)
	}

	// Plex-compatible auth endpoints (for client compatibility)
	r.POST("/api/v2/pins", s.createPin)
	r.GET("/api/v2/pins/:id", s.checkPin)
	r.GET("/api/v2/user", s.authRequired(), s.getUser)
	r.GET("/api/v2/resources", s.authRequired(), s.getResources)
	r.GET("/api/v2/home/users", s.authRequired(), s.getHomeUsers)
	r.POST("/api/v2/home/users/:uuid/switch", s.authRequired(), s.switchUser)

	// ============ Universal Search API ============
	r.GET("/api/search", s.authRequired(), s.handleUniversalSearch)

	// ============ Client Settings API (authenticated but not admin) ============
	// This endpoint provides settings needed by client apps (TMDB API key for trailers, etc.)
	r.GET("/api/client/settings", s.authRequired(), s.getClientSettings)

	// ============ Admin Library Management API ============
	admin := r.Group("/admin")
	admin.Use(s.authRequired(), s.adminRequired())
	{
		// Library management (admin only)
		admin.GET("/libraries", s.adminGetLibraries)
		admin.POST("/libraries", s.adminCreateLibrary)
		admin.GET("/libraries/:id", s.adminGetLibrary)
		admin.PUT("/libraries/:id", s.adminUpdateLibrary)
		admin.DELETE("/libraries/:id", s.adminDeleteLibrary)
		admin.POST("/libraries/:id/paths", s.adminAddLibraryPath)
		admin.DELETE("/libraries/:id/paths/:pathId", s.adminRemoveLibraryPath)
		admin.POST("/libraries/:id/scan", s.adminScanLibrary)
		admin.GET("/libraries/:id/stats", s.adminGetLibraryStats)

		// Filesystem browser (admin only)
		admin.GET("/filesystem/browse", s.adminBrowseFilesystem)

		// Server settings (admin only)
		admin.GET("/settings", s.adminGetSettings)
		admin.PUT("/settings", s.adminUpdateSettings)

		// Database Backups (admin only)
		admin.POST("/backups", s.createBackup)
		admin.GET("/backups", s.listBackups)
		admin.GET("/backups/:filename/download", s.downloadBackup)
		admin.DELETE("/backups/:filename", s.deleteBackup)
		admin.POST("/backups/:filename/restore", s.restoreBackup)

		// Search Engine (admin only)
		admin.POST("/search/reindex", s.handleSearchReindex)
		admin.GET("/search/stats", s.handleSearchStats)

		// Self-Update (admin only)
		admin.GET("/updater/status", s.getUpdateStatus)
		admin.POST("/updater/check", s.checkForUpdate)
		admin.POST("/updater/apply", s.applyUpdate)

		// Media management (admin only)
		admin.GET("/media", s.adminGetMedia)
		admin.PUT("/media/:id", s.adminUpdateMedia)
		admin.POST("/media/:id/refresh", s.adminRefreshMediaMetadata)
		admin.POST("/media/refresh-missing", s.adminRefreshAllMissingMetadata)
		admin.GET("/media/search-tmdb", s.adminSearchTMDB)
		admin.POST("/media/:id/match", s.adminApplyMediaMatch)

		// User management (admin only)
		admin.GET("/users", s.adminListUsers)
		admin.DELETE("/users/:id", s.adminDeleteUser)
		admin.GET("/users/:id/profiles", s.adminGetUserProfiles)
	}

	// ============ Auto-Update API (admin only) ============
	updatesGroup := r.Group("/api/updates")
	updatesGroup.Use(s.authRequired(), s.adminRequired())
	{
		updatesGroup.GET("/auto-config", s.getAutoUpdateConfig)
		updatesGroup.PUT("/auto-config", s.putAutoUpdateConfig)
		updatesGroup.GET("/schedule", s.getAutoUpdateSchedule)
		updatesGroup.POST("/check-now", s.triggerAutoUpdateCheck)
	}

	// ============ Library API ============
	libraryGroup := r.Group("/library")
	libraryGroup.Use(s.authRequired(), s.parentalControlMiddleware())
	{
		// Sections
		libraryGroup.GET("/sections", s.getLibrarySections)
		libraryGroup.GET("/sections/:id/all", s.getLibraryContent)
		libraryGroup.GET("/sections/:id/filters", s.getLibraryFilters)
		libraryGroup.GET("/sections/:id/sorts", s.getLibrarySorts)
		libraryGroup.GET("/sections/:id/collections", s.getLibraryCollections)
		libraryGroup.GET("/sections/:id/refresh", s.refreshLibrary)
		libraryGroup.GET("/sections/:id/folder", s.getLibraryFolders)

		// Metadata
		libraryGroup.GET("/metadata/:key", s.getMetadata)
		libraryGroup.GET("/metadata/:key/children", s.getMetadataChildren)
		libraryGroup.PUT("/metadata/:key/prefs", s.setMetadataPrefs)

		// Parts (for stream selection)
		libraryGroup.PUT("/parts/:id", s.selectStreams)

		// Browsing
		libraryGroup.GET("/recentlyAdded", s.getRecentlyAdded)
		libraryGroup.GET("/onDeck", s.getOnDeck)

	}

	// ============ Hubs API (Recommendations) ============
	hubs := r.Group("/hubs")
	hubs.Use(s.authRequired())
	{
		hubs.GET("/sections/:id", s.getLibraryHubs)
		hubs.GET("/sections/:id/streaming-services", s.getStreamingServices)
		hubs.GET("/home/streaming-services", s.getAllStreamingServices)
		hubs.GET("/search", s.search)

		// TMDB trending/popular endpoints
		hubs.GET("/trending", s.getTrending)
		hubs.GET("/popular/movies", s.getPopularMovies)
		hubs.GET("/popular/tv", s.getPopularTV)
		hubs.GET("/top-rated/movies", s.getTopRatedMovies)
	}

	// ============ Playback API ============
	// Watch status - Plex uses /:/scrobble but Gin doesn't support that
	// We use /-/ as an alternative and handle both in a custom way
	plex := r.Group("/-")
	plex.Use(s.authRequired())
	{
		plex.GET("/scrobble", s.markWatched)
		plex.GET("/unscrobble", s.markUnwatched)
		plex.POST("/timeline", s.updateTimeline)
	}

	// Also support query-based approach for Plex compatibility
	r.GET("/scrobble", s.authRequired(), s.markWatched)
	r.GET("/unscrobble", s.authRequired(), s.markUnwatched)
	r.POST("/timeline", s.authRequired(), s.updateTimeline)

	// Remove from continue watching
	r.PUT("/actions/removeFromContinueWatching", s.authRequired(), s.removeFromContinueWatching)

	// Sessions
	r.GET("/status/sessions", s.authRequired(), s.getSessions)
	r.POST("/sessions", s.authRequired(), s.startSession)
	r.PUT("/sessions/:id", s.authRequired(), s.updateSession)
	r.DELETE("/sessions/:id", s.authRequired(), s.stopSession)

	// ============ Playlists API ============
	playlists := r.Group("/playlists")
	playlists.Use(s.authRequired())
	{
		playlists.GET("", s.getPlaylists)
		playlists.POST("", s.createPlaylist)
		playlists.GET("/:id", s.getPlaylist)
		playlists.GET("/:id/items", s.getPlaylistItems)
		playlists.PUT("/:id/items", s.addToPlaylist)
		playlists.DELETE("/:id/items/:itemId", s.removeFromPlaylist)
		playlists.PUT("/:id/items/:itemId/move", s.movePlaylistItem)
		playlists.DELETE("/:id/items", s.clearPlaylist)
		playlists.DELETE("/:id", s.deletePlaylist)
	}

	// ============ Admin Playlists API (Web UI) ============
	adminPlaylists := r.Group("/api/playlists")
	adminPlaylists.Use(s.authRequired())
	{
		adminPlaylists.GET("", s.getAdminPlaylists)
		adminPlaylists.POST("", s.createAdminPlaylist)
		adminPlaylists.GET("/:id", s.getAdminPlaylist)
		adminPlaylists.PUT("/:id", s.updateAdminPlaylist)
		adminPlaylists.DELETE("/:id", s.deleteAdminPlaylist)
		adminPlaylists.POST("/:id/items", s.addItemsToAdminPlaylist)
		adminPlaylists.DELETE("/:id/items/:itemId", s.removeItemFromAdminPlaylist)
		adminPlaylists.PUT("/:id/items/reorder", s.reorderAdminPlaylistItems)
	}

	// ============ Personal Sections API ============
	personalSections := r.Group("/api/sections")
	personalSections.Use(s.authRequired())
	{
		personalSections.GET("", s.getPersonalSections)
		personalSections.POST("", s.createPersonalSection)
		personalSections.POST("/preview", s.previewSmartFilter)  // Must be before /:id
		personalSections.GET("/genres", s.getAvailableGenres)    // Must be before /:id
		personalSections.GET("/:id", s.getPersonalSection)
		personalSections.PUT("/:id", s.updatePersonalSection)
		personalSections.DELETE("/:id", s.deletePersonalSection)
		personalSections.POST("/:id/items", s.addItemsToPersonalSection)
		personalSections.DELETE("/:id/items/:itemId", s.removeItemFromPersonalSection)
		personalSections.PUT("/:id/reorder", s.reorderPersonalSectionItems)
	}

	// ============ Watchlist API ============
	watchlist := r.Group("/watchlist")
	watchlist.Use(s.authRequired())
	{
		watchlist.GET("", s.getWatchlist)
		watchlist.POST("/:mediaId", s.addToWatchlist)
		watchlist.DELETE("/:mediaId", s.removeFromWatchlist)
	}

	// ============ Live TV API ============
	// Public endpoints for external integrations (Channels DVR, etc.)
	livetvPublic := r.Group("/livetv")
	{
		livetvPublic.GET("/export.m3u", s.exportChannelsM3U)      // M3U playlist with tvc-guide-stationid
		livetvPublic.GET("/export.xml", s.exportEPGXMLTV)         // XMLTV EPG guide data
		livetvPublic.GET("/lineup.json", s.exportChannelsLineup)  // JSON lineup
	}

	livetv := r.Group("/livetv")
	livetv.Use(s.authRequired())
	{
		// Sources (M3U playlists)
		livetv.GET("/sources", s.getLiveTVSources)
		livetv.POST("/sources", s.addLiveTVSource)
		livetv.PUT("/sources/:id", s.updateLiveTVSource)
		livetv.DELETE("/sources/:id", s.deleteLiveTVSource)
		livetv.POST("/sources/:id/refresh", s.refreshLiveTVSource)
		// M3U VOD/Series import
		livetv.POST("/sources/:id/import-vod", s.importM3UVOD)
		livetv.POST("/sources/:id/import-series", s.importM3USeries)

		// Channels
		livetv.GET("/channels", s.getChannels)
		livetv.GET("/channels/:id", s.getChannel)
		livetv.PUT("/channels/:id", s.updateChannel)
		livetv.POST("/channels/bulk-map", s.bulkMapChannels)         // Bulk map multiple channels
		livetv.POST("/channels/auto-detect", s.autoDetectChannels)   // Auto-detect EPG mappings
		livetv.POST("/channels/map-numbers", s.mapChannelNumbersFromM3U) // Map channel numbers from M3U
		livetv.DELETE("/channels/:id/epg-mapping", s.unmapChannel) // Remove EPG mapping
		livetv.GET("/channels/:id/suggestions", s.getSuggestedMatches) // Get suggested EPG matches
		livetv.POST("/channels/:id/favorite", s.toggleChannelFavorite)
		livetv.POST("/channels/:id/refresh-epg", s.refreshChannelEPG) // Refresh EPG mapping
		livetv.GET("/channels/:id/stream", s.proxyChannelStream)        // Proxy channel stream for web playback
		livetv.GET("/channels/:id/hls-segment", s.proxyHLSSegment)    // Proxy HLS segments for web playback

		// Channel Groups (Failover)
		livetv.GET("/channel-groups", s.getChannelGroups)
		livetv.POST("/channel-groups", s.createChannelGroup)
		livetv.PUT("/channel-groups/:id", s.updateChannelGroup)
		livetv.DELETE("/channel-groups/:id", s.deleteChannelGroup)
		livetv.POST("/channel-groups/:id/members", s.addChannelToGroup)
		livetv.PUT("/channel-groups/:id/members/:channelId", s.updateGroupMemberPriority)
		livetv.DELETE("/channel-groups/:id/members/:channelId", s.removeChannelFromGroup)
		livetv.POST("/channel-groups/auto-detect", s.autoDetectDuplicates)
		livetv.GET("/channel-groups/:id/stream", s.proxyChannelGroupStream) // Failover stream

		// Guide (EPG)
		livetv.GET("/guide", s.getGuide)
		livetv.GET("/guide/:channelId", s.getChannelGuide)
		livetv.GET("/now", s.getWhatsOnNow)

		// EPG Sources (standalone XMLTV sources)
		livetv.GET("/epg/sources", s.getEPGSources)
		livetv.POST("/epg/sources/preview", s.previewEPGSource) // Preview before adding
		livetv.POST("/epg/sources", s.addEPGSource)
		livetv.PUT("/epg/sources/:id", s.updateEPGSource)
		livetv.DELETE("/epg/sources/:id", s.deleteEPGSource)
		livetv.POST("/epg/sources/:id/refresh", s.refreshEPGSource)

		// EPG management
		livetv.GET("/epg/stats", s.getEPGStats)
		livetv.POST("/epg/refresh", s.refreshAllEPG)
		livetv.GET("/epg/programs", s.getEPGPrograms)
		livetv.GET("/epg/channels", s.getEPGChannels)

		// EPG Scheduler
		livetv.GET("/epg/scheduler", s.getEPGSchedulerStatus)
		livetv.POST("/epg/scheduler/refresh", s.forceEPGRefresh)

		// Guide Cache
		livetv.GET("/guide/cache/stats", s.getGuideCacheStats)
		livetv.POST("/guide/cache/invalidate", s.invalidateGuideCache)

		// EPG Maintenance (duplicate/conflict detection)
		livetv.GET("/epg/conflicts", s.getEPGConflicts)
		livetv.POST("/epg/duplicates/resolve", s.resolveDuplicates)
		livetv.POST("/epg/overlaps/resolve", s.resolveOverlaps)
		livetv.POST("/epg/cleanup", s.cleanupOldPrograms)

		// Database maintenance
		livetv.POST("/cleanup-database", s.cleanupDatabase)

		// Multi-Source Fallback
		livetv.GET("/epg/sources/health", s.getEPGSourceHealth)
		livetv.POST("/epg/sources/fetch-fallback", s.fetchWithFallback)
		livetv.POST("/epg/sources/:id/reset-health", s.resetSourceHealth)

		// Gracenote provider discovery by zip code
		livetv.GET("/gracenote/providers", s.discoverGracenoteProviders)

		// Catch-up TV / Start Over
		livetv.GET("/channels/:id/catchup", s.getCatchUpPrograms)
		livetv.GET("/channels/:id/startover", s.getStartOverInfo)

		// TimeShift streaming
		livetv.GET("/timeshift/:id/stream.m3u8", s.getTimeshiftPlaylist)
		livetv.GET("/timeshift/:id/segment/:filename", s.getTimeshiftSegment)
		livetv.POST("/timeshift/:id/start", s.startTimeshiftBuffer)
		livetv.POST("/timeshift/:id/stop", s.stopTimeshiftBuffer)

		// Archive / Catch-up (server-side recording)
		livetv.GET("/channels/:id/archive", s.getArchivedPrograms)
		livetv.POST("/channels/:id/archive/enable", s.enableChannelArchive)
		livetv.POST("/channels/:id/archive/disable", s.disableChannelArchive)
		livetv.GET("/archive/:id/stream.m3u8", s.getArchivePlaylist)
		livetv.GET("/archive/:id/segment/:filename", s.getArchiveSegment)
		livetv.GET("/archive/status", s.getArchiveStatus)

		// Xtream Codes API sources
		livetv.GET("/xtream/sources", s.listXtreamSources)
		livetv.GET("/xtream/sources/:id", s.getXtreamSource)
		livetv.POST("/xtream/sources", s.createXtreamSource)
		livetv.PUT("/xtream/sources/:id", s.updateXtreamSource)
		livetv.DELETE("/xtream/sources/:id", s.deleteXtreamSource)
		livetv.POST("/xtream/sources/:id/test", s.testXtreamSource)
		livetv.POST("/xtream/sources/:id/refresh", s.refreshXtreamSource)
		livetv.POST("/xtream/parse-m3u", s.parseXtreamFromM3U)
		livetv.GET("/xtream/sources/:id/categories", s.getXtreamCategories)
		livetv.GET("/xtream/sources/:id/streams", s.getXtreamStreams)
		// VOD/Series import
		livetv.POST("/xtream/sources/:id/import-vod", s.importXtreamVOD)
		livetv.POST("/xtream/sources/:id/import-series", s.importXtreamSeries)
		livetv.POST("/xtream/sources/:id/import-all", s.importAllXtreamContent)
		// M3U8 proxy for Xtream VOD (handles nested playlists)
		livetv.GET("/xtream/proxy", s.proxyXtreamM3U8)
	}

	// ============ DVR API ============
	dvrGroup := r.Group("/dvr")
	dvrGroup.Use(s.authRequired())
	{
		// Recordings
		dvrGroup.GET("/recordings", s.getRecordings)
		dvrGroup.POST("/recordings", s.scheduleRecording)
		dvrGroup.POST("/recordings/from-program", s.recordFromProgram)
		dvrGroup.GET("/recordings/stats", s.getActiveRecordingStats) // Must be before :id route
		dvrGroup.GET("/recordings/manager", s.getRecordingsManager)  // Must be before :id route
		dvrGroup.POST("/recordings/bulk", s.bulkRecordingAction)     // Must be before :id route
		dvrGroup.GET("/recordings/:id", s.getRecording)
		dvrGroup.PUT("/recordings/:id", s.updateRecording)
		dvrGroup.POST("/recordings/:id/match", s.applyRecordingMatch)
		dvrGroup.DELETE("/recordings/:id", s.deleteRecording)
		dvrGroup.PUT("/recordings/:id/priority", s.updateRecordingPriority)

		// Series Rules
		dvrGroup.GET("/rules", s.getSeriesRules)
		dvrGroup.POST("/rules", s.createSeriesRule)
		dvrGroup.PUT("/rules/:id", s.updateSeriesRule)
		dvrGroup.DELETE("/rules/:id", s.deleteSeriesRule)

		// Commercial Detection
		dvrGroup.GET("/commercials/status", s.getCommercialDetectionStatus)
		dvrGroup.GET("/recordings/:id/commercials", s.getCommercialSegments)
		dvrGroup.POST("/recordings/:id/commercials/detect", s.rerunCommercialDetection)
		dvrGroup.POST("/recordings/:id/reprocess", s.reprocessRecording)

		// EDL Export (Edit Decision List for commercial skip in external players)
		dvrGroup.GET("/recordings/:id/export.edl", s.exportRecordingEDL)

		// Recording Playback
		dvrGroup.GET("/stream/:id", s.streamRecording)
		dvrGroup.GET("/recordings/:id/stream", s.getRecordingStreamUrl)
		dvrGroup.GET("/recordings/:id/hls/master.m3u8", s.getRecordingHLSPlaylist)
		dvrGroup.GET("/recordings/:id/hls/:segment", s.getRecordingHLSSegment)
		dvrGroup.GET("/recordings/:id/dash/manifest.mpd", s.getRecordingDASHManifest)
		dvrGroup.GET("/recordings/:id/dash/:segment", s.getRecordingDASHSegment)
		dvrGroup.PUT("/recordings/:id/progress", s.updateRecordingProgress)

		// Recordings Manager (file browser UI) - :id routes
		dvrGroup.PUT("/recordings/:id/watched", s.toggleRecordingWatched)
		dvrGroup.PUT("/recordings/:id/favorite", s.toggleRecordingFavorite)
		dvrGroup.PUT("/recordings/:id/keep", s.toggleRecordingKeep)
		dvrGroup.DELETE("/recordings/:id/trash", s.trashRecording)

		// Stream Validation (validates stream before scheduling)
		dvrGroup.GET("/validate-stream", s.validateRecordingStream)

		// Conflict Detection
		dvrGroup.GET("/conflicts", s.getRecordingConflicts)
		dvrGroup.POST("/conflicts/check", s.checkRecordingConflict)
		dvrGroup.POST("/conflicts/resolve", s.resolveConflict)

		// Disk Usage & Quality
		dvrGroup.GET("/disk-usage", s.getDiskUsage)
		dvrGroup.GET("/quality-presets", s.getQualityPresets)

		// DVR Settings
		dvrGroup.GET("/settings", s.getDVRSettings)
		dvrGroup.PUT("/settings", s.updateDVRSettings)

		// DVR Management (Passes, Schedule, Calendar)
		dvrGroup.GET("/passes", s.getDVRPasses)
		dvrGroup.PUT("/passes/:id/pause", s.pauseDVRPass)
		dvrGroup.PUT("/passes/:id/resume", s.resumeDVRPass)
		dvrGroup.GET("/schedule", s.getDVRSchedule)
		dvrGroup.GET("/calendar", s.getDVRCalendar)

		// Labels / Tags management
		dvrGroup.GET("/labels", s.getLabels)
		dvrGroup.POST("/labels/bulk", s.bulkLabelAction)
		dvrGroup.GET("/labels/:label/files", s.getFilesByLabel)
		dvrGroup.PUT("/recordings/:id/labels", s.setRecordingLabels)

		// DVR V2 (Channels DVR-style)
		dvrV2 := dvrGroup.Group("/v2")
		{
			// Jobs
			dvrV2.GET("/jobs", s.getJobs)
			dvrV2.GET("/jobs/:id", s.getJob)
			dvrV2.POST("/jobs", s.createJob)
			dvrV2.PUT("/jobs/:id", s.updateJob)
			dvrV2.DELETE("/jobs/:id", s.deleteJob)
			dvrV2.POST("/jobs/:id/cancel", s.cancelJob)

			// Files
			dvrV2.GET("/files", s.getFiles)
			dvrV2.GET("/files/locked", s.getLockedFiles)
			dvrV2.GET("/files/:id", s.getFile)
			dvrV2.PUT("/files/:id", s.updateFile)
			dvrV2.DELETE("/files/:id", s.deleteFile)
			dvrV2.GET("/files/:id/stream", s.streamFile)
			dvrV2.GET("/files/:id/dash/manifest.mpd", s.getFileDASHManifest)
			dvrV2.GET("/files/:id/dash/:segment", s.getFileDASHSegment)
			dvrV2.PUT("/files/:id/state", s.updateFileState)
			dvrV2.PUT("/files/:id/labels", s.setFileLabels)
			dvrV2.PUT("/files/:id/lock", s.lockFile)
			dvrV2.DELETE("/files/:id/lock", s.unlockFile)

			// EDL Export (Edit Decision List for external players)
			dvrV2.GET("/files/:id/export.edl", s.exportFileEDL)

			// Groups
			dvrV2.GET("/groups", s.getGroups)
			dvrV2.GET("/groups/:id", s.getGroup)
			dvrV2.DELETE("/groups/:id", s.deleteGroup)
			dvrV2.PUT("/groups/:id/state", s.updateGroupState)
			dvrV2.POST("/groups/regroup", s.groupUngroupedFiles)

			// Rules
			dvrV2.GET("/rules", s.getRules)
			dvrV2.GET("/rules/:id", s.getRule)
			dvrV2.POST("/rules", s.createRule)
			dvrV2.PUT("/rules/:id", s.updateRule)
			dvrV2.DELETE("/rules/:id", s.deleteRule)
			dvrV2.POST("/rules/preview", s.previewRule)
			dvrV2.GET("/rules/:id/preview", s.previewExistingRule)

			// Duplicate Detection
			dvrV2.GET("/duplicates", s.getDuplicates)
			dvrV2.GET("/duplicates/check", s.checkDuplicate)
			dvrV2.GET("/duplicates/stats", s.getDuplicateStats)
			dvrV2.POST("/duplicates/:jobId/override", s.overrideDuplicate)

			// Watch state
			dvrV2.GET("/upnext", s.getUpNext)

			// File management
			dvrV2.POST("/files/:id/regroup", s.regroupFile)

			// Virtual Stations
			dvrV2.GET("/virtual-stations", s.getVirtualStations)
			dvrV2.GET("/virtual-stations/:id", s.getVirtualStation)
			dvrV2.POST("/virtual-stations", s.createVirtualStation)
			dvrV2.PUT("/virtual-stations/:id", s.updateVirtualStation)
			dvrV2.DELETE("/virtual-stations/:id", s.deleteVirtualStation)
			dvrV2.GET("/virtual-stations/:id/stream.m3u8", s.streamVirtualStation)

			// Collections (smart playlists)
			dvrV2.GET("/collections", s.getDVRCollections)
			dvrV2.GET("/collections/:id", s.getDVRCollection)
			dvrV2.POST("/collections", s.createDVRCollection)
			dvrV2.PUT("/collections/:id", s.updateDVRCollection)
			dvrV2.DELETE("/collections/:id", s.deleteDVRCollection)
			dvrV2.GET("/collections/:id/items", s.getDVRCollectionItems)

			// Trash / Recycle Bin
			dvrV2.GET("/trash", s.getTrash)
			dvrV2.POST("/trash/:id/restore", s.restoreFromTrash)
			dvrV2.DELETE("/trash", s.emptyTrash)
			dvrV2.DELETE("/trash/:id", s.permanentlyDelete)

			// File Upload / Import
			dvrV2.POST("/files/upload", s.uploadFile)
			dvrV2.POST("/files/import", s.importFromPath)
			dvrV2.POST("/files/import/bulk", s.bulkImport)
			dvrV2.GET("/files/upload/:id/progress", s.getUploadProgress)

			// WebSocket event stream
			dvrV2.GET("/events", s.dvrEvents)

			// Ad Stripping
			dvrV2.POST("/files/:id/strip-ads", s.stripAds)
			dvrV2.GET("/files/:id/strip-ads/status", s.getStripAdsStatus)
			dvrV2.POST("/files/:id/strip-ads/undo", s.undoStripAds)

			// Channel Collections (custom lineups)
			dvrV2.GET("/channel-collections", s.getChannelCollections)
			dvrV2.POST("/channel-collections", s.createChannelCollection)
			dvrV2.POST("/channel-collection-rules/preview", s.previewSmartRules)
			dvrV2.GET("/channel-collection-meta/groups", s.channelCollectionGroups)
			dvrV2.GET("/channel-collection-meta/sources", s.channelCollectionSources)
			dvrV2.GET("/channel-collections/:id", s.getChannelCollection)
			dvrV2.PUT("/channel-collections/:id", s.updateChannelCollection)
			dvrV2.DELETE("/channel-collections/:id", s.deleteChannelCollection)
			dvrV2.GET("/channel-collections/:id/export.m3u", s.exportChannelCollectionM3U)

			// Conflict Resolution
			dvrV2.GET("/conflicts", s.getV2Conflicts)
			dvrV2.GET("/conflicts/:jobId/alternatives", s.getV2ConflictAlternatives)
			dvrV2.POST("/conflicts/:jobId/resolve", s.resolveV2Conflict)
			dvrV2.POST("/conflicts/auto-resolve", s.autoResolveV2Conflicts)

			// Chapter Markers
			dvrV2.GET("/files/:id/chapters", s.getFileChapters)
			dvrV2.POST("/files/:id/chapters", s.addFileChapter)
			dvrV2.PUT("/files/:id/chapters/:chapterId", s.updateFileChapter)
			dvrV2.DELETE("/files/:id/chapters/:chapterId", s.deleteFileChapter)
			dvrV2.POST("/files/:id/chapters/detect", s.detectFileChapters)
		}
	}

	// ============ VOD API (Video On Demand Downloads) ============
	vodGroup := r.Group("/api/vod")
	vodGroup.Use(s.authRequired())
	{
		// Providers
		vodGroup.GET("/providers", s.getVODProviders)

		// Content browsing
		vodGroup.GET("/:provider/movies", s.getVODMovies)
		vodGroup.GET("/:provider/shows", s.getVODShows)
		vodGroup.GET("/:provider/genres", s.getVODGenres)
		vodGroup.GET("/:provider/movie/:id", s.getVODMovie)
		vodGroup.GET("/:provider/show/:id", s.getVODShow)

		// Download management
		vodGroup.POST("/:provider/download", s.startVODDownload)
		vodGroup.GET("/queue", s.getVODQueue)
		vodGroup.DELETE("/queue/:id", s.cancelVODDownload)

		// Connection test
		vodGroup.GET("/test-connection", s.testVODConnection)
	}

	// ============ On Later API (Browse upcoming content) ============
	onlater := r.Group("/api/onlater")
	onlater.Use(s.authRequired())
	{
		onlater.GET("/all", s.handleGetOnLaterAll)
		onlater.GET("/tvshows", s.handleGetOnLaterTVShows)
		onlater.GET("/movies", s.handleGetOnLaterMovies)
		onlater.GET("/sports", s.handleGetOnLaterSports)
		onlater.GET("/kids", s.handleGetOnLaterKids)
		onlater.GET("/news", s.handleGetOnLaterNews)
		onlater.GET("/premieres", s.handleGetOnLaterPremieres)
		onlater.GET("/tonight", s.handleGetOnLaterTonight)
		onlater.GET("/week", s.handleGetOnLaterWeek)
		onlater.GET("/search", s.handleSearchOnLater)
		onlater.GET("/channels/:id", s.handleGetOnLaterByChannel)
		onlater.GET("/stats", s.handleGetOnLaterStats)

		// EPG enrichment
		onlater.POST("/enrich", s.handleEnrichEPG)

		// Sports teams
		onlater.GET("/leagues", s.handleGetLeagues)
		onlater.GET("/teams/:league", s.handleGetTeamsByLeague)
		onlater.GET("/teams/search", s.handleSearchTeams)
	}

	// ============ Team Pass API (Auto-record sports teams) ============
	teampass := r.Group("/api/teampass")
	teampass.Use(s.authRequired())
	{
		teampass.GET("", s.handleListTeamPasses)
		teampass.POST("", s.handleCreateTeamPass)
		teampass.GET("/:id", s.handleGetTeamPass)
		teampass.PUT("/:id", s.handleUpdateTeamPass)
		teampass.DELETE("/:id", s.handleDeleteTeamPass)
		teampass.GET("/:id/upcoming", s.handleGetTeamPassUpcoming)
		teampass.PUT("/:id/toggle", s.handleToggleTeamPass)

		// Stats and processing
		teampass.GET("/stats", s.handleGetTeamPassStats)
		teampass.POST("/process", s.handleProcessTeamPasses)

		// Team search
		teampass.GET("/teams/search", s.handleSearchSportsTeams)
		teampass.GET("/leagues", s.handleGetSportsLeagues)
		teampass.GET("/leagues/:league/teams", s.handleGetLeagueTeams)
	}

	// ============ Remote Access API ============
	remoteAccess := r.Group("/remote-access")
	remoteAccess.Use(s.authRequired())
	{
		// Connection info (any authenticated user)
		remoteAccess.GET("/connection-info", s.getRemoteConnectionInfo)

		// Admin-only endpoints
		remoteAccess.GET("/status", s.adminRequired(), s.getRemoteAccessStatus)
		remoteAccess.POST("/enable", s.adminRequired(), s.enableRemoteAccess)
		remoteAccess.POST("/disable", s.adminRequired(), s.disableRemoteAccess)
		remoteAccess.GET("/health", s.adminRequired(), s.getRemoteAccessHealth)
		remoteAccess.GET("/install-info", s.adminRequired(), s.getRemoteAccessInstallInfo)
		remoteAccess.GET("/login-url", s.adminRequired(), s.getRemoteAccessLoginUrl)
	}

	// ============ Notifications API ============
	notifyGroup := r.Group("/api/notifications")
	notifyGroup.Use(s.authRequired(), s.adminRequired())
	{
		notifyGroup.GET("/config", s.getNotificationConfig)
		notifyGroup.PUT("/config", s.putNotificationConfig)
		notifyGroup.POST("/test", s.testNotification)
		notifyGroup.GET("/history", s.getNotificationHistory)
	}

	// ============ Dynamic DNS API ============
	ddnsGroup := r.Group("/api/ddns")
	ddnsGroup.Use(s.authRequired(), s.adminRequired())
	{
		ddnsGroup.GET("/status", s.getDDNSStatus)
		ddnsGroup.PUT("/configure", s.configureDDNS)
		ddnsGroup.POST("/test", s.testDDNS)
		ddnsGroup.POST("/update", s.forceUpdateDDNS)
		ddnsGroup.DELETE("/disable", s.disableDDNS)
	}

	// ============ Instant Switch API ============
	instantSwitch := r.Group("/api/instant")
	instantSwitch.Use(s.authRequired())
	{
		instantHandlers := instant.NewInstantSwitchHandlers(s.prebuffer)
		instantHandlers.RegisterRoutes(instantSwitch)
	}

	// ============ Multiview API ============
	// KEY DIFFERENTIATOR: Full DVR support in multiview (pause/rewind/sync)
	// Channels DVR has NO DVR in multiview - we beat them here!
	multiviewGroup := r.Group("/api/multiview")
	multiviewGroup.Use(s.authRequired())
	{
		// Initialize multiview manager with DVR support
		if s.multiviewManager == nil {
			s.multiviewManager = multiview.NewMultiviewManager(6, nil) // 6 streams max
		}
		multiview.RegisterRoutes(multiviewGroup, s.multiviewManager)
	}

	// ============ Sports Scores Overlay API ============
	// Live scores from ESPN (FREE, no API key needed!)
	// Favorites pinned to top, updates every 30s
	sportsGroup := r.Group("/api/sports")
	sportsGroup.Use(s.authRequired())
	{
		sportsManager := sports.SetupSportsScores()
		sports.RegisterRoutes(sportsGroup, sportsManager)
	}

	// ============ Commercial Skip AI API ============
	// Hybrid detection: comskip + black frames + audio analysis
	// Auto-skip with "Skipping in 3...2...1..." UI
	commercialGroup := r.Group("/api/commercial")
	commercialGroup.Use(s.authRequired())
	{
		commercialDetector := commercial.SetupCommercialSkip()
		commercial.RegisterRoutes(commercialGroup, commercialDetector)
	}

	// ============ Gracenote EPG API ============
	s.epgService.RegisterRoutes(r)

	// ============ Watch Party API ============
	s.RegisterWatchPartyRoutes(r)

	// ============ Speed Test API ============
	speedtestGroup := r.Group("/api/speedtest")
	speedtestGroup.Use(s.authRequired())
	{
		speedtestGroup.GET("/ping", s.speedTestPing)
		speedtestGroup.GET("/download", s.speedTestDownload)
		speedtestGroup.POST("/upload", s.speedTestUpload)
		speedtestGroup.GET("/results/:id", s.speedTestResults)
	}

	// ============ Stream Health Monitoring API ============
	healthGroup := r.Group("/api/health")
	healthGroup.Use(s.authRequired())
	{
		healthGroup.GET("/streams", s.getHealthStreams)
		healthGroup.GET("/streams/:id", s.getHealthStream)
		healthGroup.POST("/streams/:id/report", s.reportStreamHealth)
		healthGroup.GET("/channels", s.getHealthChannels)
		healthGroup.GET("/channels/:id/history", s.getHealthChannelHistory)

		// Admin-only endpoints
		healthGroup.GET("/alerts", s.adminRequired(), s.getHealthAlerts)
		healthGroup.GET("/summary", s.adminRequired(), s.getHealthSummary)
	}

	// ============ Tuner API (HDHR) ============
	tunerGroup := r.Group("/api/tuners")
	tunerGroup.Use(s.authRequired())
	{
		tunerGroup.GET("", s.getTuners)
		tunerGroup.POST("", s.addTuner)
		tunerGroup.POST("/discover", s.discoverTuners)
		tunerGroup.DELETE("/:id", s.removeTuner)
		tunerGroup.GET("/:id/lineup", s.getTunerLineup)
		tunerGroup.GET("/:id/status", s.getTunerStatus)
		tunerGroup.POST("/:id/import", s.importTunerChannels)
		tunerGroup.POST("/:id/scan", s.scanTunerChannels)
	}

	// ============ Bookmarks & Clips API ============
	bookmarkGroup := r.Group("/api/bookmarks")
	bookmarkGroup.Use(s.authRequired())
	{
		bookmarkGroup.GET("", s.listBookmarks)
		bookmarkGroup.POST("", s.createBookmark)
		bookmarkGroup.GET("/:id", s.getBookmark)
		bookmarkGroup.PUT("/:id", s.updateBookmark)
		bookmarkGroup.DELETE("/:id", s.deleteBookmark)
	}

	clipGroup := r.Group("/api/clips")
	clipGroup.Use(s.authRequired())
	{
		clipGroup.GET("", s.listClips)
		clipGroup.POST("", s.createClip)
		clipGroup.GET("/:id", s.getClip)
		clipGroup.DELETE("/:id", s.deleteClip)
		clipGroup.GET("/:id/download", s.downloadClip)
		clipGroup.GET("/:id/stream", s.streamClip)
	}

	// ============ Offline Downloads API ============
	offline := r.Group("/api/offline")
	offline.Use(s.authRequired())
	{
		offline.POST("/request", s.requestOfflineDownload)
		offline.GET("/downloads", s.listOfflineDownloads)
		offline.GET("/:id/stream", s.streamOfflineDownload)
		offline.PUT("/:id/progress", s.updateOfflineProgress)
		offline.PUT("/:id/watch-state", s.syncOfflineWatchState)
		offline.DELETE("/:id", s.deleteOfflineDownload)
		offline.GET("/settings", s.getOfflineSettings)
		offline.PUT("/settings", s.adminRequired(), s.updateOfflineSettings)
	}

	// ============ Server Preferences ============
	// Plex uses /:/prefs - we use /-/prefs
	plex.GET("/prefs", s.getServerPrefs)
	r.GET("/prefs", s.authRequired(), s.getServerPrefs)

	// ============ Configuration Export/Import ============
	configGroup := r.Group("/config")
	configGroup.Use(s.authRequired())
	{
		configGroup.GET("/export", s.exportConfig)
		configGroup.POST("/import", s.importConfig)
		configGroup.GET("/stats", s.getConfigStats)
	}

	// ============ Media Streaming ============
	// Direct file access
	r.GET("/library/parts/:partId/file", s.authRequired(), s.streamMedia)
	r.GET("/library/parts/:partId/file.:ext", s.authRequired(), s.streamMedia)

	// Transcode - using /video/-/transcode instead of /video/:/transcode
	r.GET("/video/-/transcode/universal/start.m3u8", s.authRequired(), s.transcodeStart)
	r.GET("/video/-/transcode/universal/session/:sessionId/:segment", s.authRequired(), s.transcodeSegment)
	// Alternative routes
	r.GET("/transcode/universal/start.m3u8", s.authRequired(), s.transcodeStart)
	r.GET("/transcode/universal/session/:sessionId/:segment", s.authRequired(), s.transcodeSegment)

	// DASH Transcode
	r.GET("/video/-/transcode/dash/start.mpd", s.authRequired(), s.dashStart)
	r.GET("/video/-/transcode/dash/session/:sessionId/:segment", s.authRequired(), s.dashSegment)
	r.GET("/video/-/transcode/dash/session/:sessionId/manifest.mpd", s.authRequired(), s.dashManifest)

	// ============ Playback Decision API ============
	// Smart playback mode selection
	playbackAPI := r.Group("/api/playback")
	playbackAPI.Use(s.authRequired())
	{
		// Client capabilities
		playbackAPI.POST("/capabilities", s.registerClientCapabilities)
		playbackAPI.GET("/capabilities/:deviceId", s.getClientCapabilities)
		playbackAPI.GET("/capabilities/defaults", s.getDefaultCapabilities)

		// Playback decisions
		playbackAPI.GET("/decide/:fileId", s.getPlaybackDecision)
		playbackAPI.POST("/decide/:fileId", s.getPlaybackDecision) // POST with capabilities in body
		playbackAPI.GET("/options/:mediaId", s.getMediaPlaybackOptions)

		// Bandwidth management (adaptive bitrate)
		playbackAPI.POST("/bandwidth", s.reportBandwidth)
		playbackAPI.GET("/bandwidth/server", s.adminRequired(), s.getServerBandwidth)
		playbackAPI.PUT("/bandwidth/server/limit", s.adminRequired(), s.setServerBandwidthLimit)
		playbackAPI.GET("/bandwidth/:clientId", s.getClientBandwidth)
		playbackAPI.PUT("/bandwidth/:clientId/cap", s.setClientBandwidthCap)

		// Skip markers and settings
		playbackAPI.GET("/:id/markers", s.getSkipMarkers)
		playbackAPI.GET("/:id/markers/library", s.getLibrarySkipMarkers)
		playbackAPI.POST("/:id/skip", s.reportSkip)
		playbackAPI.GET("/skip-settings", s.getSkipSettings)
		playbackAPI.PUT("/skip-settings", s.updateSkipSettings)

		// Audio/Subtitle track selection
		playbackAPI.GET("/:id/tracks", s.getMediaTracks)
		playbackAPI.PUT("/:id/tracks/select", s.selectMediaTracks)
		playbackAPI.GET("/track-preferences", s.getTrackPreferences)
		playbackAPI.PUT("/track-preferences", s.updateTrackPreferences)

		// Playback speed
		playbackAPI.GET("/speed-presets", s.getSpeedPresets)
		playbackAPI.PUT("/speed", s.setPlaybackSpeed)
		playbackAPI.GET("/sessions/:sessionId/speed", s.getSessionSpeed)
		playbackAPI.PUT("/sessions/:sessionId/speed", s.setSessionSpeed)

		// Frame rate matching
		playbackAPI.GET("/:id/framerate", s.getMediaFrameRate)
		playbackAPI.GET("/framerate-settings", s.getFrameRateSettings)
		playbackAPI.PUT("/framerate-settings", s.adminRequired(), s.updateFrameRateSettings)
	}

	// ============ Scheduled Tasks API (admin only) ============
	schedulerGroup := r.Group("/api/scheduler")
	schedulerGroup.Use(s.authRequired(), s.adminRequired())
	{
		schedulerGroup.GET("/tasks", s.listScheduledTasks)
		schedulerGroup.GET("/tasks/:id", s.getScheduledTask)
		schedulerGroup.PUT("/tasks/:id", s.updateScheduledTask)
		schedulerGroup.POST("/tasks/:id/run", s.triggerScheduledTask)
		schedulerGroup.GET("/history", s.getSchedulerHistory)
	}

	// ============ Subtitles API (OpenSubtitles) ============
	subtitleGroup := r.Group("/api/subtitles")
	subtitleGroup.Use(s.authRequired())
	{
		subtitleGroup.GET("/search", s.searchSubtitles)
		subtitleGroup.POST("/download", s.downloadSubtitle)
		subtitleGroup.GET("/config", s.getSubtitleConfig)
		subtitleGroup.PUT("/config", s.adminRequired(), s.updateSubtitleConfig)
		subtitleGroup.GET("/:mediaId", s.getSubtitlesForMedia)
		subtitleGroup.DELETE("/:mediaId/:lang", s.deleteSubtitle)
	}

	// ============ Guide Data API (admin only) ============
	guideAdmin := r.Group("/api/guide")
	guideAdmin.Use(s.authRequired(), s.adminRequired())
	{
		guideAdmin.POST("/refresh", s.refreshGuideData)
		guideAdmin.POST("/rebuild", s.rebuildGuideData)
	}

	// ============ Global Client Settings API (admin only) ============
	clientSettingsAdmin := r.Group("/api/client-settings")
	clientSettingsAdmin.Use(s.authRequired(), s.adminRequired())
	{
		clientSettingsAdmin.GET("", s.getGlobalClientSettings)
		clientSettingsAdmin.PUT("", s.updateGlobalClientSettings)
		clientSettingsAdmin.DELETE("/:key", s.deleteGlobalClientSetting)
	}

	// ============ Device Management API ============
	// Authenticated (any user) endpoints
	devices := r.Group("/api/devices")
	devices.Use(s.authRequired())
	{
		devices.POST("/register", s.registerDevice)
		devices.GET("/my-settings", s.getMyDeviceSettings)
	}
	// Admin-only endpoints
	adminDevices := r.Group("/api/devices")
	adminDevices.Use(s.authRequired(), s.adminRequired())
	{
		adminDevices.GET("", s.listDevices)
		adminDevices.GET("/:id", s.getDevice)
		adminDevices.PUT("/:id", s.updateDevice)
		adminDevices.DELETE("/:id", s.deleteDevice)
	}

	// Images - support both /thumb/:id and /thumb (simple)
	r.GET("/library/metadata/:key/thumb/:thumbId", s.getThumb)
	r.GET("/library/metadata/:key/thumb", s.getThumbSimple)
	r.GET("/library/metadata/:key/art/:artId", s.getArt)
	r.GET("/library/metadata/:key/art", s.getArtSimple)

	// ============ API Documentation ============
	s.registerSwaggerRoutes(r)

	s.router = r
}

// ============ Middleware ============

func (s *Server) loggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path

		c.Next()

		latency := time.Since(start)
		status := c.Writer.Status()

		logger.WithFields(map[string]interface{}{
			"method":  c.Request.Method,
			"path":    path,
			"status":  status,
			"latency": latency,
			"ip":      c.ClientIP(),
		}).Debug("HTTP request")
	}
}

func (s *Server) corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization, X-Plex-Token, X-Plex-Client-Identifier, X-Plex-Product, X-Plex-Version, X-Plex-Platform, X-Device-ID, Range")
		c.Header("Access-Control-Expose-Headers", "Content-Range, Content-Length, Content-Type")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

func (s *Server) authRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check if local access is enabled and request is from localhost
		if s.config.Auth.AllowLocalAccess && s.isLocalRequest(c) {
			// Allow local access without authentication
			// Set default local user context
			c.Set("token", "local-access")
			c.Set("userID", uint(0))
			c.Set("userUUID", "local-user")
			c.Set("isAdmin", true) // Local users have full access
			c.Set("isLocalAccess", true)
			c.Next()
			return
		}

		// Check X-Plex-Token header (Plex-compatible)
		token := c.GetHeader("X-Plex-Token")
		if token == "" {
			// Also check query param
			token = c.Query("X-Plex-Token")
		}
		if token == "" {
			// Also check Authorization header
			authHeader := c.GetHeader("Authorization")
			if strings.HasPrefix(authHeader, "Bearer ") {
				token = strings.TrimPrefix(authHeader, "Bearer ")
			} else {
				token = authHeader
			}
		}

		if token == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
			c.Abort()
			return
		}

		// Validate token
		claims, err := s.authService.ValidateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		// Set user info in context
		c.Set("token", token)
		c.Set("claims", claims)
		c.Set("userID", claims.UserID)
		c.Set("userUUID", claims.UUID)
		c.Set("isAdmin", claims.IsAdmin)
		c.Next()
	}
}

// isLocalRequest checks if the request is from localhost or local network
func (s *Server) isLocalRequest(c *gin.Context) bool {
	clientIP := c.ClientIP()

	// Check for localhost addresses
	if clientIP == "127.0.0.1" || clientIP == "::1" || clientIP == "localhost" {
		return true
	}

	// Check for private network ranges
	if strings.HasPrefix(clientIP, "192.168.") ||
		strings.HasPrefix(clientIP, "10.") ||
		strings.HasPrefix(clientIP, "172.16.") ||
		strings.HasPrefix(clientIP, "172.17.") ||
		strings.HasPrefix(clientIP, "172.18.") ||
		strings.HasPrefix(clientIP, "172.19.") ||
		strings.HasPrefix(clientIP, "172.20.") ||
		strings.HasPrefix(clientIP, "172.21.") ||
		strings.HasPrefix(clientIP, "172.22.") ||
		strings.HasPrefix(clientIP, "172.23.") ||
		strings.HasPrefix(clientIP, "172.24.") ||
		strings.HasPrefix(clientIP, "172.25.") ||
		strings.HasPrefix(clientIP, "172.26.") ||
		strings.HasPrefix(clientIP, "172.27.") ||
		strings.HasPrefix(clientIP, "172.28.") ||
		strings.HasPrefix(clientIP, "172.29.") ||
		strings.HasPrefix(clientIP, "172.30.") ||
		strings.HasPrefix(clientIP, "172.31.") {
		return true
	}

	return false
}

func (s *Server) adminRequired() gin.HandlerFunc {
	return func(c *gin.Context) {
		isAdmin, exists := c.Get("isAdmin")
		if !exists || !isAdmin.(bool) {
			c.JSON(http.StatusForbidden, gin.H{"error": "Admin access required"})
			c.Abort()
			return
		}
		c.Next()
	}
}

// ============ Common Helpers ============

// MediaContainer wraps responses in Plex-compatible format
type MediaContainer struct {
	Size      int         `json:"size"`
	TotalSize int         `json:"totalSize,omitempty"`
	Offset    int         `json:"offset,omitempty"`
	Metadata  interface{} `json:"Metadata,omitempty"`
	Directory interface{} `json:"Directory,omitempty"`
	Hub       interface{} `json:"Hub,omitempty"`
}

func (s *Server) respondWithMediaContainer(c *gin.Context, data interface{}, size, totalSize, offset int) {
	container := gin.H{
		"MediaContainer": MediaContainer{
			Size:      size,
			TotalSize: totalSize,
			Offset:    offset,
			Metadata:  data,
		},
	}
	c.JSON(http.StatusOK, container)
}

func (s *Server) respondWithDirectory(c *gin.Context, data interface{}, size int) {
	container := gin.H{
		"MediaContainer": MediaContainer{
			Size:      size,
			Directory: data,
		},
	}
	c.JSON(http.StatusOK, container)
}

func (s *Server) getPaginationParams(c *gin.Context) (offset, limit int) {
	offset, _ = strconv.Atoi(c.Query("X-Plex-Container-Start"))
	limit, _ = strconv.Atoi(c.Query("X-Plex-Container-Size"))
	if limit <= 0 {
		limit = 50 // default
	}
	return
}

// ============ Health Check ============

func (s *Server) healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "ok",
		"time":   time.Now().Unix(),
	})
}

// ============ Remote Access Handlers ============

func (s *Server) getRemoteConnectionInfo(c *gin.Context) {
	clientIP := c.ClientIP()
	info := s.remoteAccess.GetConnectionInfo(clientIP)

	// Convert to DTO format expected by clients
	c.JSON(http.StatusOK, gin.H{
		"serverUrl":          info.RecommendedURL,
		"networkType":        s.detectNetworkType(clientIP),
		"isRemote":           info.IsRemote,
		"suggestedQuality":   s.getSuggestedQuality(info.IsRemote),
		"tailscaleAvailable": info.TailscaleURL != "",
	})
}

func (s *Server) getRemoteAccessStatus(c *gin.Context) {
	status := s.remoteAccess.RefreshStatus()

	c.JSON(http.StatusOK, gin.H{
		"enabled":           status.Enabled,
		"connected":         status.Status == "connected",
		"method":            "tailscale",
		"tailscaleIp":       status.TailscaleIP,
		"tailscaleHostname": status.Hostname,
		"magicDnsName":      status.TailscaleURL,
		"backendState":      status.Status,
		"loginUrl":          nil,
		"lastSeen":          status.LastChecked,
		"error":             status.Error,
	})
}

func (s *Server) enableRemoteAccess(c *gin.Context) {
	var req struct {
		AuthKey string `json:"authKey"`
	}
	c.BindJSON(&req)

	if err := s.remoteAccess.Enable(req.AuthKey); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": err.Error(),
		})
		return
	}

	status := s.remoteAccess.GetStatus()
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Remote access enabled",
		"status": gin.H{
			"enabled":           status.Enabled,
			"connected":         status.Status == "connected",
			"method":            "tailscale",
			"tailscaleIp":       status.TailscaleIP,
			"tailscaleHostname": status.Hostname,
			"magicDnsName":      status.TailscaleURL,
			"backendState":      status.Status,
			"loginUrl":          nil,
			"lastSeen":          status.LastChecked,
			"error":             status.Error,
		},
	})
}

func (s *Server) disableRemoteAccess(c *gin.Context) {
	if err := s.remoteAccess.Disable(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": err.Error(),
		})
		return
	}

	status := s.remoteAccess.GetStatus()
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "Remote access disabled",
		"status": gin.H{
			"enabled":           status.Enabled,
			"connected":         status.Status == "connected",
			"method":            "tailscale",
			"tailscaleIp":       status.TailscaleIP,
			"tailscaleHostname": status.Hostname,
			"magicDnsName":      status.TailscaleURL,
			"backendState":      status.Status,
			"loginUrl":          nil,
			"lastSeen":          status.LastChecked,
			"error":             status.Error,
		},
	})
}

func (s *Server) getRemoteAccessHealth(c *gin.Context) {
	health := s.remoteAccess.HealthCheck()

	c.JSON(http.StatusOK, gin.H{
		"healthy":  health["tailscale_connected"],
		"checks":   health,
		"warnings": []string{},
	})
}

func (s *Server) getRemoteAccessInstallInfo(c *gin.Context) {
	instructions := livetv.GetInstallInstructions()

	// Check if tailscale is installed
	_, installed := instructions["command"]

	c.JSON(http.StatusOK, gin.H{
		"isInstalled":      installed,
		"currentVersion":   nil,
		"installCommand":   instructions["command"],
		"configureCommand": "tailscale up --hostname=openflix",
		"docUrl":           instructions["download_url"],
	})
}

func (s *Server) getRemoteAccessLoginUrl(c *gin.Context) {
	url, err := s.remoteAccess.GetLoginURL()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"url":   nil,
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"url": url,
	})
}

// Helper functions for remote access
func (s *Server) detectNetworkType(clientIP string) string {
	if strings.HasPrefix(clientIP, "100.") {
		return "vpn" // Tailscale CGNAT range
	}
	if strings.HasPrefix(clientIP, "192.168.") ||
		strings.HasPrefix(clientIP, "10.") ||
		strings.HasPrefix(clientIP, "172.16.") ||
		clientIP == "127.0.0.1" {
		return "wifi"
	}
	return "cellular"
}

func (s *Server) getSuggestedQuality(isRemote bool) string {
	if isRemote {
		return "720p"
	}
	return "original"
}
