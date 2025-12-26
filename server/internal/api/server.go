package api

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/openflix/openflix-server/internal/auth"
	"github.com/openflix/openflix-server/internal/config"
	"github.com/openflix/openflix-server/internal/dvr"
	"github.com/openflix/openflix-server/internal/library"
	"github.com/openflix/openflix-server/internal/metadata"
	"github.com/openflix/openflix-server/internal/transcode"
	"gorm.io/gorm"
)

// Server represents the API server
type Server struct {
	config         *config.Config
	db             *gorm.DB
	router         *gin.Engine
	authService    *auth.Service
	libraryService *library.Service
	scanner        *library.Scanner
	transcoder     *transcode.Transcoder
	recorder       *dvr.Recorder
	epgService     *EPGService
}

// NewServer creates a new API server
func NewServer(cfg *config.Config, db *gorm.DB) *Server {
	dataDir := cfg.GetDataDir()
	scanner := library.NewScanner(db)

	// Initialize TMDB agent if API key is configured
	if cfg.Library.TMDBApiKey != "" {
		tmdbAgent := metadata.NewTMDBAgent(cfg.Library.TMDBApiKey, db, dataDir)
		scanner.SetTMDBAgent(tmdbAgent)
		fmt.Println("TMDB metadata agent enabled")
	}

	// Initialize transcoder
	var transcoder *transcode.Transcoder
	if cfg.Transcode.Enabled {
		hwAccel := cfg.Transcode.HardwareAccel
		if hwAccel == "auto" {
			hwAccel = transcode.DetectHardwareAccel(cfg.Transcode.FFmpegPath)
			fmt.Printf("Auto-detected hardware acceleration: %s\n", hwAccel)
		}
		transcoder = transcode.NewTranscoder(
			cfg.Transcode.FFmpegPath,
			cfg.Transcode.TempDir,
			hwAccel,
			cfg.Transcode.MaxSessions,
		)
		fmt.Println("Transcoding enabled")
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
		fmt.Println("DVR recording enabled")
		if cfg.DVR.CommercialDetect {
			fmt.Println("Commercial detection enabled")
		}
	}

	// Initialize EPG service
	epgService := NewEPGService()

	s := &Server{
		config:         cfg,
		db:             db,
		authService:    auth.NewService(db, cfg.Auth.JWTSecret, cfg.Auth.TokenExpiry),
		libraryService: library.NewService(db, dataDir),
		scanner:        scanner,
		transcoder:     transcoder,
		recorder:       recorder,
		epgService:     epgService,
	}
	s.setupRouter()
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
		fmt.Println("TMDB metadata agent re-initialized with new API key")
	} else {
		s.scanner.SetTMDBAgent(nil)
		fmt.Println("TMDB metadata agent disabled (no API key)")
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

	// Web Admin UI
	s.setupWebUI(r)

	// Server identity (Plex-compatible)
	r.GET("/", s.getServerInfo)
	r.GET("/identity", s.getServerIdentity)

	// ============ Auth API ============
	// Simplified auth (not Plex.tv dependent)
	auth := r.Group("/auth")
	{
		auth.POST("/register", s.register)
		auth.POST("/login", s.login)
		auth.POST("/logout", s.authRequired(), s.logout)
		auth.GET("/user", s.authRequired(), s.getCurrentUser)
		auth.PUT("/user", s.authRequired(), s.updateCurrentUser)
		auth.PUT("/user/password", s.authRequired(), s.changePassword)
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
		hubs.GET("/search", s.search)
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
		livetv.POST("/channels/bulk-map", s.bulkMapChannels)      // Bulk map multiple channels
		livetv.DELETE("/channels/:id/epg-mapping", s.unmapChannel) // Remove EPG mapping
		livetv.POST("/channels/:id/favorite", s.toggleChannelFavorite)

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
	}

	// ============ DVR API ============
	dvrGroup := r.Group("/dvr")
	dvrGroup.Use(s.authRequired())
	{
		// Recordings
		dvrGroup.GET("/recordings", s.getRecordings)
		dvrGroup.POST("/recordings", s.scheduleRecording)
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
	}

	// ============ Gracenote EPG API ============
	s.epgService.RegisterRoutes(r)

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

	// Images
	r.GET("/library/metadata/:key/thumb/:thumbId", s.getThumb)
	r.GET("/library/metadata/:key/art/:artId", s.getArt)

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

		fmt.Printf("[%s] %s %s %d %v\n",
			time.Now().Format("2006-01-02 15:04:05"),
			c.Request.Method,
			path,
			status,
			latency,
		)
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
