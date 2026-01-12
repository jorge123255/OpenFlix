package api

import (
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/auth"
	"github.com/openflix/openflix-server/internal/config"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/library"
	"github.com/openflix/openflix-server/internal/livetv"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/metadata"
	"github.com/openflix/openflix-server/internal/transcode"
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
	}
	s.setupRouter()

	// Start background EPG enrichment if TMDB is configured
	if epgEnricher != nil {
		epgEnricher.StartBackgroundEnrichment()
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

	// Plex-compatible auth endpoints (for client compatibility)
	r.POST("/api/v2/pins", s.createPin)
	r.GET("/api/v2/pins/:id", s.checkPin)
	r.GET("/api/v2/user", s.authRequired(), s.getUser)
	r.GET("/api/v2/resources", s.authRequired(), s.getResources)
	r.GET("/api/v2/home/users", s.authRequired(), s.getHomeUsers)
	r.POST("/api/v2/home/users/:uuid/switch", s.authRequired(), s.switchUser)

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

		// Media management (admin only)
		admin.GET("/media", s.adminGetMedia)
		admin.PUT("/media/:id", s.adminUpdateMedia)
		admin.POST("/media/:id/refresh", s.adminRefreshMediaMetadata)
		admin.POST("/media/refresh-missing", s.adminRefreshAllMissingMetadata)
		admin.GET("/media/search-tmdb", s.adminSearchTMDB)
		admin.POST("/media/:id/match", s.adminApplyMediaMatch)
	}

	// ============ Library API ============
	libraryGroup := r.Group("/library")
	libraryGroup.Use(s.authRequired())
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

		// Collections
		libraryGroup.GET("/collections/:id/children", s.getCollectionItems)
		libraryGroup.POST("/collections", s.createCollection)
		libraryGroup.PUT("/collections/:id/items", s.addToCollection)
		libraryGroup.DELETE("/collections/:id/items/:itemId", s.removeFromCollection)
		libraryGroup.DELETE("/collections/:id", s.deleteCollection)
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

	// ============ Play Queues API ============
	playQueues := r.Group("/playQueues")
	playQueues.Use(s.authRequired())
	{
		playQueues.POST("", s.createPlayQueue)
		playQueues.GET("/:id", s.getPlayQueue)
		playQueues.PUT("/:id/shuffle", s.shufflePlayQueue)
		playQueues.DELETE("/:id/items", s.clearPlayQueue)
	}

	// ============ Live TV API ============
	livetv := r.Group("/livetv")
	livetv.Use(s.authRequired())
	{
		// Sources (M3U playlists)
		livetv.GET("/sources", s.getLiveTVSources)
		livetv.POST("/sources", s.addLiveTVSource)
		livetv.PUT("/sources/:id", s.updateLiveTVSource)
		livetv.DELETE("/sources/:id", s.deleteLiveTVSource)
		livetv.POST("/sources/:id/refresh", s.refreshLiveTVSource)

		// Channels
		livetv.GET("/channels", s.getChannels)
		livetv.GET("/channels/:id", s.getChannel)
		livetv.PUT("/channels/:id", s.updateChannel)
		livetv.POST("/channels/bulk-map", s.bulkMapChannels)       // Bulk map multiple channels
		livetv.POST("/channels/auto-detect", s.autoDetectChannels) // Auto-detect EPG mappings
		livetv.DELETE("/channels/:id/epg-mapping", s.unmapChannel) // Remove EPG mapping
		livetv.GET("/channels/:id/suggestions", s.getSuggestedMatches) // Get suggested EPG matches
		livetv.POST("/channels/:id/favorite", s.toggleChannelFavorite)
		livetv.POST("/channels/:id/refresh-epg", s.refreshChannelEPG) // Refresh EPG mapping

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
		dvrGroup.GET("/recordings/:id", s.getRecording)
		dvrGroup.DELETE("/recordings/:id", s.deleteRecording)

		// Series Rules
		dvrGroup.GET("/rules", s.getSeriesRules)
		dvrGroup.POST("/rules", s.createSeriesRule)
		dvrGroup.PUT("/rules/:id", s.updateSeriesRule)
		dvrGroup.DELETE("/rules/:id", s.deleteSeriesRule)

		// Commercial Detection
		dvrGroup.GET("/commercials/status", s.getCommercialDetectionStatus)
		dvrGroup.GET("/recordings/:id/commercials", s.getCommercialSegments)
		dvrGroup.POST("/recordings/:id/commercials/detect", s.rerunCommercialDetection)

		// Recording Playback
		dvrGroup.GET("/stream/:id", s.streamRecording)

		// Stream Validation (validates stream before scheduling)
		dvrGroup.GET("/validate-stream", s.validateRecordingStream)

		// Conflict Detection
		dvrGroup.GET("/conflicts", s.getRecordingConflicts)
		dvrGroup.POST("/conflicts/check", s.checkRecordingConflict)
		dvrGroup.POST("/conflicts/resolve", s.resolveConflict)
	}

	// ============ On Later API (Browse upcoming content) ============
	onlater := r.Group("/api/onlater")
	onlater.Use(s.authRequired())
	{
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

	// ============ Gracenote EPG API ============
	s.epgService.RegisterRoutes(r)

	// ============ Watch Party API ============
	s.RegisterWatchPartyRoutes(r)

	// ============ Server Preferences ============
	// Plex uses /:/prefs - we use /-/prefs
	plex.GET("/prefs", s.getServerPrefs)
	r.GET("/prefs", s.authRequired(), s.getServerPrefs)

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
	}

	// Images - support both /thumb/:id and /thumb (simple)
	r.GET("/library/metadata/:key/thumb/:thumbId", s.getThumb)
	r.GET("/library/metadata/:key/thumb", s.getThumbSimple)
	r.GET("/library/metadata/:key/art/:artId", s.getArt)
	r.GET("/library/metadata/:key/art", s.getArtSimple)

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
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization, X-Plex-Token, X-Plex-Client-Identifier, X-Plex-Product, X-Plex-Version, X-Plex-Platform")

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
