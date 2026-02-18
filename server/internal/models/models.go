package models

import (
	"time"

	"gorm.io/gorm"
)

// User represents a user account
type User struct {
	ID           uint           `gorm:"primaryKey" json:"id"`
	UUID         string         `gorm:"uniqueIndex;size:36" json:"uuid"`
	Username     string         `gorm:"uniqueIndex;size:100" json:"username"`
	Email        string         `gorm:"uniqueIndex;size:255" json:"email,omitempty"`
	PasswordHash string         `gorm:"size:255" json:"-"`
	DisplayName  string         `gorm:"size:100" json:"title"`
	Thumb        string         `gorm:"size:500" json:"thumb,omitempty"`
	IsAdmin      bool           `gorm:"default:false" json:"admin"`
	IsRestricted bool           `gorm:"default:false" json:"restricted"`
	HasPassword  bool           `gorm:"default:true" json:"hasPassword"`
	PIN          string         `gorm:"size:10" json:"-"`
	CreatedAt    time.Time      `json:"createdAt"`
	UpdatedAt    time.Time      `json:"updatedAt"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	Profiles     []UserProfile  `gorm:"foreignKey:UserID" json:"profiles,omitempty"`
	WatchHistory []WatchHistory `gorm:"foreignKey:UserID" json:"-"`
}

// UserProfile represents a user profile (for family/multi-profile support)
type UserProfile struct {
	ID                      uint   `gorm:"primaryKey" json:"id"`
	UserID                  uint   `gorm:"index" json:"userId"`
	UUID                    string `gorm:"uniqueIndex;size:36" json:"uuid"`
	Name                    string `gorm:"size:100" json:"name"`
	Thumb                   string `gorm:"size:500" json:"thumb,omitempty"`
	IsKid                   bool   `gorm:"default:false" json:"isKid"`
	MaxRating               string `gorm:"size:20" json:"maxRating,omitempty"`
	DefaultAudioLanguage    string `gorm:"size:10" json:"defaultAudioLanguage,omitempty"`
	DefaultSubtitleLanguage string `gorm:"size:10" json:"defaultSubtitleLanguage,omitempty"`
	AutoSelectAudio         bool   `gorm:"default:true" json:"autoSelectAudio"`
	AutoSelectSubtitle      int    `gorm:"default:1" json:"autoSelectSubtitle"`
	CreatedAt               time.Time
	UpdatedAt               time.Time
}

// Library represents a media library (Movies, TV Shows, Music, etc.)
type Library struct {
	ID         uint           `gorm:"primaryKey" json:"key"`
	UUID       string         `gorm:"uniqueIndex;size:36" json:"uuid"`
	Title      string         `gorm:"size:255" json:"title"`
	Type       string         `gorm:"size:50;index" json:"type"` // movie, show, artist, photo
	Agent      string         `gorm:"size:100" json:"agent,omitempty"`
	Scanner    string         `gorm:"size:100" json:"scanner,omitempty"`
	Language   string         `gorm:"size:10" json:"language,omitempty"`
	Paths      []LibraryPath  `gorm:"foreignKey:LibraryID" json:"locations,omitempty"`
	Hidden     bool           `gorm:"default:false" json:"hidden"`
	CreatedAt  time.Time      `json:"createdAt"`
	UpdatedAt  time.Time      `json:"updatedAt"`
	ScannedAt  *time.Time     `json:"scannedAt,omitempty"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`
}

// LibraryPath represents a filesystem path for a library
type LibraryPath struct {
	ID        uint   `gorm:"primaryKey" json:"id"`
	LibraryID uint   `gorm:"index" json:"libraryId"`
	Path      string `gorm:"size:1000" json:"path"`
}

// MediaItem represents any media item (movie, show, season, episode, track)
type MediaItem struct {
	ID               uint           `gorm:"primaryKey" json:"ratingKey"`
	UUID             string         `gorm:"uniqueIndex;size:36" json:"guid"`
	LibraryID        uint           `gorm:"index" json:"librarySectionID"`
	Type             string         `gorm:"size:50;index" json:"type"` // movie, show, season, episode, artist, album, track
	Title            string         `gorm:"size:500" json:"title"`
	OriginalTitle    string         `gorm:"size:500" json:"originalTitle,omitempty"`
	SortTitle        string         `gorm:"size:500;index" json:"titleSort,omitempty"`
	Studio           string         `gorm:"size:255" json:"studio,omitempty"`
	ContentRating    string         `gorm:"size:20" json:"contentRating,omitempty"`
	Summary          string         `gorm:"type:text" json:"summary,omitempty"`
	Tagline          string         `gorm:"size:500" json:"tagline,omitempty"`
	Rating           float64        `json:"rating,omitempty"`
	AudienceRating   float64        `json:"audienceRating,omitempty"`
	Year             int            `gorm:"index" json:"year,omitempty"`
	Duration         int64          `json:"duration,omitempty"` // milliseconds
	Thumb            string         `gorm:"size:500" json:"thumb,omitempty"`
	Art              string         `gorm:"size:500" json:"art,omitempty"`

	// Provider tracking (for VOD content)
	ProviderType       string `gorm:"size:20;index" json:"providerType,omitempty"`        // local, m3u, xtream
	ProviderSourceID   *uint  `gorm:"index" json:"providerSourceId,omitempty"`            // XtreamSource or M3USource ID
	ProviderName       string `gorm:"size:255" json:"providerName,omitempty"`             // Source name for display
	StreamURL          string `gorm:"size:2000" json:"streamUrl,omitempty"`               // Remote stream URL for VOD
	XtreamVODID        *int   `gorm:"index" json:"xtreamVodId,omitempty"`                 // Xtream VOD stream ID
	XtreamSeriesID     *int   `gorm:"index" json:"xtreamSeriesId,omitempty"`              // Xtream series ID
	XtreamCategoryID       string `gorm:"size:50;index" json:"xtreamCategoryId,omitempty"`            // Xtream category ID (e.g., "p8_28")
	XtreamCategoryName     string `gorm:"size:255;index" json:"xtreamCategoryName,omitempty"`         // Xtream category name (e.g., "Action")
	XtreamParentCategoryID string `gorm:"size:50;index" json:"xtreamParentCategoryId,omitempty"`      // Parent category ID (e.g., "p8" for Netflix)
	XtreamParentCategory   string `gorm:"size:255;index" json:"xtreamParentCategory,omitempty"`       // Parent category name (e.g., "Netflix")

	// M3U VOD tracking
	M3USourceID  *uint  `gorm:"column:m3u_source_id;index" json:"m3uSourceId,omitempty"`         // M3U source ID for VOD
	M3UVODID     string `gorm:"column:m3u_vod_id;size:50;index" json:"m3uVodId,omitempty"`    // Hash of stream URL for movies
	M3USeriesID  string `gorm:"column:m3u_series_id;size:50;index" json:"m3uSeriesId,omitempty"` // Hash of series name for shows
	M3UEpisodeID string `gorm:"column:m3u_episode_id;size:50;index" json:"m3uEpisodeId,omitempty"` // Hash of stream URL for episodes

	// Hierarchy (for episodes/seasons)
	ParentID            *uint  `gorm:"index" json:"parentRatingKey,omitempty"`
	GrandparentID       *uint  `gorm:"index" json:"grandparentRatingKey,omitempty"`
	Index               int    `json:"index,omitempty"`        // Episode number or track number
	ParentIndex         int    `json:"parentIndex,omitempty"`  // Season number
	ParentTitle         string `gorm:"size:255" json:"parentTitle,omitempty"`
	GrandparentTitle    string `gorm:"size:255" json:"grandparentTitle,omitempty"`
	ParentThumb         string `gorm:"size:500" json:"parentThumb,omitempty"`
	GrandparentThumb    string `gorm:"size:500" json:"grandparentThumb,omitempty"`
	GrandparentArt      string `gorm:"size:500" json:"grandparentArt,omitempty"`

	// Counters
	LeafCount       int `json:"leafCount,omitempty"`       // Total episodes/tracks
	ViewedLeafCount int `json:"viewedLeafCount,omitempty"` // Watched episodes
	ChildCount      int `json:"childCount,omitempty"`      // Children count

	// Timestamps
	OriginallyAvailableAt *time.Time     `json:"originallyAvailableAt,omitempty"`
	AddedAt               time.Time      `gorm:"index" json:"addedAt"`
	UpdatedAt             time.Time      `json:"updatedAt"`
	DeletedAt             gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	MediaFiles []MediaFile `gorm:"foreignKey:MediaItemID" json:"Media,omitempty"`
	Genres     []Genre     `gorm:"many2many:media_genres" json:"Genre,omitempty"`
	Cast       []CastMember `gorm:"foreignKey:MediaItemID" json:"Role,omitempty"`
}

// MediaFile represents a physical media file or remote stream
type MediaFile struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	MediaItemID uint   `gorm:"index" json:"mediaItemId"`
	FilePath    string `gorm:"size:2000;uniqueIndex" json:"file"`
	FileSize    int64  `json:"size"`
	FileModTime time.Time `json:"fileModTime"` // File modification time on disk
	Container   string `gorm:"size:20" json:"container"`
	Duration    int64  `json:"duration"` // milliseconds
	Bitrate     int    `json:"bitrate"`
	Width       int    `json:"width"`
	Height      int    `json:"height"`
	AspectRatio float64 `json:"aspectRatio"`
	VideoCodec  string `gorm:"size:50" json:"videoCodec"`
	VideoProfile string `gorm:"size:50" json:"videoProfile,omitempty"`
	VideoFrameRate string `gorm:"size:20" json:"videoFrameRate,omitempty"`
	AudioCodec  string `gorm:"size:50" json:"audioCodec"`
	AudioChannels int   `json:"audioChannels"`

	// Remote stream support (for VOD)
	IsRemote        bool   `gorm:"default:false" json:"isRemote"`                   // True for VOD streams
	RemoteURL       string `gorm:"size:2000" json:"remoteUrl,omitempty"`            // Stream URL
	RemoteExtension string `gorm:"size:20" json:"remoteExtension,omitempty"`        // File extension (mp4, mkv, etc.)

	// Streams
	Streams []MediaStream `gorm:"foreignKey:MediaFileID" json:"Part,omitempty"`

	CreatedAt time.Time
	UpdatedAt time.Time
}

// MediaStream represents an audio/subtitle/video stream
type MediaStream struct {
	ID           uint   `gorm:"primaryKey" json:"id"`
	MediaFileID  uint   `gorm:"index" json:"mediaFileId"`
	StreamType   int    `json:"streamType"` // 1=video, 2=audio, 3=subtitle
	Index        int    `json:"index"`
	Codec        string `gorm:"size:50" json:"codec"`
	Language     string `gorm:"size:100" json:"language,omitempty"`
	LanguageCode string `gorm:"size:10" json:"languageCode,omitempty"`
	Title        string `gorm:"size:255" json:"title,omitempty"`
	DisplayTitle string `gorm:"size:255" json:"displayTitle,omitempty"`
	Selected     bool   `json:"selected"`
	Default      bool   `json:"default"`
	Forced       bool   `json:"forced"`

	// Video specific
	Width        int     `json:"width,omitempty"`
	Height       int     `json:"height,omitempty"`
	BitDepth     int     `json:"bitDepth,omitempty"`
	ColorSpace   string  `gorm:"size:50" json:"colorSpace,omitempty"`
	FrameRate    float64 `json:"frameRate,omitempty"`

	// Audio specific
	Channels     int    `json:"channels,omitempty"`
	ChannelLayout string `gorm:"size:50" json:"audioChannelLayout,omitempty"`
	SamplingRate int    `json:"samplingRate,omitempty"`

	// Subtitle specific
	Key          string `gorm:"size:500" json:"key,omitempty"` // Path for external subtitles
}

// Genre represents a genre tag
type Genre struct {
	ID   uint   `gorm:"primaryKey" json:"id"`
	Tag  string `gorm:"uniqueIndex;size:100" json:"tag"`
}

// CastMember represents a cast/crew member
type CastMember struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	MediaItemID uint   `gorm:"index" json:"mediaItemId"`
	Tag         string `gorm:"size:255" json:"tag"` // Person name
	Role        string `gorm:"size:255" json:"role,omitempty"`
	Thumb       string `gorm:"size:500" json:"thumb,omitempty"`
	Order       int    `json:"order"`
}

// WatchHistory tracks what users have watched
type WatchHistory struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"index:idx_watch_user_profile;index:idx_watch_user_item" json:"userId"`
	ProfileID   uint      `gorm:"index:idx_watch_user_profile" json:"profileId"`
	MediaItemID uint      `gorm:"index:idx_watch_user_item" json:"ratingKey"`
	ViewOffset  int64     `json:"viewOffset"` // milliseconds
	ViewCount   int       `json:"viewCount"`
	LastViewedAt time.Time `gorm:"index" json:"lastViewedAt"`
	Completed   bool      `gorm:"index" json:"completed"`
	UpdatedAt   time.Time
}

// Playlist represents a user playlist
type Playlist struct {
	ID           uint           `gorm:"primaryKey" json:"ratingKey"`
	UUID         string         `gorm:"uniqueIndex;size:36" json:"guid"`
	UserID       uint           `gorm:"index" json:"userId"`
	Title        string         `gorm:"size:255" json:"title"`
	Summary      string         `gorm:"type:text" json:"summary,omitempty"`
	PlaylistType string         `gorm:"size:20" json:"playlistType"` // video, audio, photo
	Smart        bool           `gorm:"default:false" json:"smart"`
	Composite    string         `gorm:"size:500" json:"composite,omitempty"`
	Duration     int64          `json:"duration,omitempty"`
	LeafCount    int            `json:"leafCount"`
	AddedAt      time.Time      `json:"addedAt"`
	UpdatedAt    time.Time      `json:"updatedAt"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`

	Items []PlaylistItem `gorm:"foreignKey:PlaylistID" json:"-"`
}

// PlaylistItem represents an item in a playlist
type PlaylistItem struct {
	ID          uint `gorm:"primaryKey" json:"playlistItemID"`
	PlaylistID  uint `gorm:"index" json:"playlistId"`
	MediaItemID uint `gorm:"index" json:"ratingKey"`
	Order       int  `json:"order"`
}

// Collection represents a collection of media items
type Collection struct {
	ID          uint           `gorm:"primaryKey" json:"ratingKey"`
	UUID        string         `gorm:"uniqueIndex;size:36" json:"guid"`
	LibraryID   uint           `gorm:"index" json:"librarySectionID"`
	Title       string         `gorm:"size:255" json:"title"`
	Summary     string         `gorm:"type:text" json:"summary,omitempty"`
	Thumb       string         `gorm:"size:500" json:"thumb,omitempty"`
	Art         string         `gorm:"size:500" json:"art,omitempty"`
	ChildCount  int            `json:"childCount"`
	AddedAt     time.Time      `json:"addedAt"`
	UpdatedAt   time.Time      `json:"updatedAt"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`

	Items []CollectionItem `gorm:"foreignKey:CollectionID" json:"-"`
}

// CollectionItem represents an item in a collection
type CollectionItem struct {
	ID           uint `gorm:"primaryKey" json:"id"`
	CollectionID uint `gorm:"index" json:"collectionId"`
	MediaItemID  uint `gorm:"index" json:"ratingKey"`
}

// WatchlistItem represents an item in a user's watchlist
type WatchlistItem struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"uniqueIndex:idx_watchlist_user_item" json:"userId"`
	MediaItemID uint      `gorm:"uniqueIndex:idx_watchlist_user_item" json:"ratingKey"`
	AddedAt     time.Time `json:"addedAt"`
}

// ========== Live TV Models ==========

// M3USource represents an M3U playlist source
type M3USource struct {
	ID          uint       `gorm:"primaryKey" json:"id"`
	Name        string     `gorm:"size:255" json:"name"`
	URL         string     `gorm:"size:2000" json:"url"`
	EPGUrl      string     `gorm:"size:2000" json:"epgUrl,omitempty"`
	Enabled     bool       `gorm:"default:true" json:"enabled"`
	LastFetched *time.Time `json:"lastFetched,omitempty"`
	// HTTP caching headers for conditional EPG requests
	EPGETag         string `gorm:"size:255" json:"epgETag,omitempty"`
	EPGLastModified string `gorm:"size:100" json:"epgLastModified,omitempty"`
	// VOD import settings
	ImportVOD       bool  `gorm:"default:false" json:"importVod"`
	ImportSeries    bool  `gorm:"default:false" json:"importSeries"`
	VODLibraryID    *uint `json:"vodLibraryId,omitempty"`
	SeriesLibraryID *uint `json:"seriesLibraryId,omitempty"`
	CreatedAt       time.Time `json:"createdAt"`
	UpdatedAt       time.Time `json:"updatedAt"`
}

// XtreamSource represents an Xtream Codes API source
type XtreamSource struct {
	ID             uint       `gorm:"primaryKey" json:"id"`
	Name           string     `gorm:"size:255" json:"name"`
	ServerURL      string     `gorm:"size:2000" json:"serverUrl"`       // Base server URL (http://server:port)
	Username       string     `gorm:"size:255" json:"username"`
	Password       string     `gorm:"size:255" json:"-"`                // Not exposed in JSON
	Enabled        bool       `gorm:"default:true" json:"enabled"`
	LastFetched    *time.Time `json:"lastFetched,omitempty"`
	LastError      string     `gorm:"type:text" json:"lastError,omitempty"`
	ExpirationDate *time.Time `json:"expirationDate,omitempty"`         // From Xtream auth response
	MaxConnections int        `json:"maxConnections,omitempty"`
	ActiveConns    int        `json:"activeConns,omitempty"`
	// Import settings
	ImportLive      bool  `gorm:"default:true" json:"importLive"`
	ImportVOD       bool  `gorm:"default:false" json:"importVod"`
	ImportSeries    bool  `gorm:"default:false" json:"importSeries"`
	VODLibraryID    *uint `json:"vodLibraryId,omitempty"`              // Target movie library
	SeriesLibraryID *uint `json:"seriesLibraryId,omitempty"`           // Target TV library
	// Stats
	ChannelCount int `json:"channelCount"`
	VODCount     int `json:"vodCount"`
	SeriesCount  int `json:"seriesCount"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// EPGSource represents a standalone XMLTV EPG source
type EPGSource struct {
	ID            uint       `gorm:"primaryKey" json:"id"`
	Name          string     `gorm:"size:255" json:"name"`
	ProviderType  string     `gorm:"size:50;default:xmltv" json:"providerType"` // xmltv or gracenote

	// XMLTV settings
	URL           string     `gorm:"size:2000" json:"url,omitempty"`

	// Gracenote settings
	GracenoteAffiliate   string `gorm:"size:50" json:"gracenoteAffiliate,omitempty"`   // e.g., orbebb
	GracenotePostalCode  string `gorm:"size:20" json:"gracenotePostalCode,omitempty"`  // ZIP code
	GracenoteHours       int    `gorm:"default:6" json:"gracenoteHours,omitempty"`     // Hours to fetch

	Enabled       bool       `gorm:"default:true" json:"enabled"`
	Priority      int        `gorm:"default:0" json:"priority"` // Lower is higher priority for fallback
	LastFetched   *time.Time `json:"lastFetched,omitempty"`
	LastError     string     `gorm:"type:text" json:"lastError,omitempty"`
	ProgramCount  int        `json:"programCount"`
	ChannelCount  int        `json:"channelCount"`
	// HTTP caching headers for conditional requests
	ETag         string `gorm:"size:255" json:"eTag,omitempty"`
	LastModified string `gorm:"size:100" json:"lastModified,omitempty"`
	CreatedAt     time.Time  `json:"createdAt"`
	UpdatedAt     time.Time  `json:"updatedAt"`
}

// Channel represents a Live TV channel
type Channel struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	M3USourceID uint   `gorm:"index" json:"sourceId"`
	EPGSourceID *uint  `gorm:"index" json:"epgSourceId,omitempty"` // Assigned EPG source
	ChannelID   string `gorm:"size:255;index" json:"channelId"` // EPG channel ID
	Number      int    `gorm:"index" json:"number"`
	Name        string `gorm:"size:255" json:"name"`
	Logo        string `gorm:"size:2000" json:"logo,omitempty"`
	Group       string `gorm:"size:255;index" json:"group,omitempty"`
	StreamURL   string `gorm:"size:2000" json:"streamUrl"`
	Enabled     bool   `gorm:"default:true" json:"enabled"`
	IsFavorite  bool   `gorm:"default:false" json:"isFavorite"`

	// Source tracking (for provider display)
	SourceType string `gorm:"size:20;default:m3u" json:"sourceType"` // m3u or xtream
	SourceName string `gorm:"size:255" json:"sourceName,omitempty"`  // Name of the source for display

	// Xtream-specific fields
	XtreamSourceID   *uint `gorm:"index" json:"xtreamSourceId,omitempty"`   // Alternative to M3USourceID
	XtreamStreamID   *int  `json:"xtreamStreamId,omitempty"`                 // Xtream stream ID
	XtreamCategoryID *int  `json:"xtreamCategoryId,omitempty"`               // Xtream category ID

	// Auto-detection fields
	TVGId           string  `gorm:"size:255;index" json:"tvgId,omitempty"`         // Original tvg-id from M3U
	EPGCallSign     string  `gorm:"size:50" json:"epgCallSign,omitempty"`          // Matched EPG call sign
	EPGChannelNo    string  `gorm:"size:20" json:"epgChannelNo,omitempty"`         // Matched EPG channel number
	EPGAffiliate    string  `gorm:"size:100" json:"epgAffiliate,omitempty"`        // Matched EPG network/affiliate
	MatchConfidence float64 `gorm:"default:0" json:"matchConfidence"`              // Auto-detection confidence (0-1)
	MatchStrategy   string  `gorm:"size:50" json:"matchStrategy,omitempty"`        // How match was made
	AutoDetected    bool    `gorm:"default:false" json:"autoDetected"`             // Was this auto-detected?

	// Archive/Catch-up settings
	ArchiveEnabled bool `gorm:"default:false" json:"archiveEnabled"` // Enable continuous recording for catch-up
	ArchiveDays    int  `gorm:"default:7" json:"archiveDays"`        // How many days to keep archived content

	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// ChannelGroup represents a logical channel with multiple stream sources for failover
type ChannelGroup struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	Name          string    `gorm:"size:255;uniqueIndex" json:"name"`
	DisplayNumber int       `json:"displayNumber"`
	Logo          string    `gorm:"size:2000" json:"logo,omitempty"`
	ChannelID     string    `gorm:"size:255" json:"channelId"` // EPG mapping
	Enabled       bool      `gorm:"default:true" json:"enabled"`
	CreatedAt     time.Time `json:"createdAt"`
	UpdatedAt     time.Time `json:"updatedAt"`

	Members []ChannelGroupMember `gorm:"foreignKey:ChannelGroupID" json:"members,omitempty"`
}

// ChannelGroupMember links a channel to a group with priority for failover
type ChannelGroupMember struct {
	ID             uint      `gorm:"primaryKey" json:"id"`
	ChannelGroupID uint      `gorm:"index;uniqueIndex:idx_group_channel" json:"channelGroupId"`
	ChannelID      uint      `gorm:"index;uniqueIndex:idx_group_channel" json:"channelId"`
	Priority       int       `gorm:"default:0" json:"priority"` // 0 = highest priority
	CreatedAt      time.Time `json:"createdAt"`

	Channel Channel `gorm:"foreignKey:ChannelID" json:"channel,omitempty"`
}

// Program represents an EPG program entry
type Program struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	ChannelID     string    `gorm:"size:255;index:idx_program_channel_time" json:"channelId"`
	CallSign      string    `gorm:"size:50" json:"callSign,omitempty"`      // Station call letters (e.g., "WMAQ", "WBBM")
	ChannelNo     string    `gorm:"size:20" json:"channelNo,omitempty"`     // Channel number (e.g., "5", "7.1")
	AffiliateName string    `gorm:"size:100" json:"affiliateName,omitempty"` // Network name (e.g., "NBC", "CBS")
	Title         string    `gorm:"size:500;index" json:"title"`
	Subtitle      string    `gorm:"size:500" json:"subtitle,omitempty"`     // Episode title
	Description   string    `gorm:"type:text" json:"description,omitempty"`
	Start         time.Time `gorm:"index:idx_program_channel_time;index:idx_program_time_range" json:"start"`
	End           time.Time `gorm:"index:idx_program_time_range" json:"end"`
	Icon          string    `gorm:"size:2000" json:"icon,omitempty"`
	Art           string    `gorm:"size:2000" json:"art,omitempty"`
	Category      string    `gorm:"size:100;index" json:"category,omitempty"`
	EpisodeNum    string    `gorm:"size:50" json:"episodeNum,omitempty"`
	SeasonNumber  int       `json:"seasonNumber,omitempty"`
	EpisodeNumber int       `json:"episodeNumber,omitempty"`
	Rating        string    `gorm:"size:20" json:"rating,omitempty"`        // TV-PG, TV-14, etc.

	// Content classification flags
	IsMovie     bool `gorm:"default:false;index" json:"isMovie"`
	IsSports    bool `gorm:"default:false;index" json:"isSports"`
	IsKids      bool `gorm:"default:false;index" json:"isKids"`
	IsNews      bool `gorm:"default:false;index" json:"isNews"`
	IsPremiere  bool `gorm:"default:false" json:"isPremiere"`
	IsNew       bool `gorm:"default:false" json:"isNew"`
	IsLive      bool `gorm:"default:false" json:"isLive"`
	IsFinale    bool `gorm:"default:false" json:"isFinale"`

	// Sports-specific fields
	Teams  string `gorm:"size:500" json:"teams,omitempty"`  // Comma-separated team names
	League string `gorm:"size:50" json:"league,omitempty"`  // NFL, NBA, MLB, NHL, MLS, etc.

	// External IDs
	SeriesID    string `gorm:"size:100" json:"seriesId,omitempty"`
	ProgramID   string `gorm:"size:100" json:"programId,omitempty"`
	GracenoteID string `gorm:"size:100" json:"gracenoteId,omitempty"`

	CreatedAt time.Time
}

// ========== DVR Models ==========

// Recording represents a DVR recording
type Recording struct {
	ID             uint       `gorm:"primaryKey" json:"id"`
	UserID         uint       `gorm:"index" json:"userId"`
	ChannelID      uint       `gorm:"index" json:"channelId"`
	ProgramID      *uint      `gorm:"index" json:"programId,omitempty"`
	Title          string     `gorm:"size:500" json:"title"`
	Subtitle       string     `gorm:"size:500" json:"subtitle,omitempty"`       // Episode title
	Description    string     `gorm:"type:text" json:"description,omitempty"`
	Summary        string     `gorm:"type:text" json:"summary,omitempty"`       // Full synopsis from TMDB
	StartTime      time.Time  `json:"startTime"`
	EndTime        time.Time  `json:"endTime"`
	Status         string     `gorm:"size:20;index" json:"status"` // scheduled, recording, completed, failed
	FilePath       string     `gorm:"size:2000" json:"filePath,omitempty"`
	FileSize       int64      `json:"fileSize,omitempty"`
	SeriesRuleID   *uint      `gorm:"index" json:"seriesRuleId,omitempty"`
	SeriesRecord   bool       `gorm:"default:false" json:"seriesRecord"`
	SeriesParentID *uint      `gorm:"index" json:"seriesParentId,omitempty"`
	Category       string     `gorm:"size:100" json:"category,omitempty"`
	EpisodeNum     string     `gorm:"size:50" json:"episodeNum,omitempty"`
	// Metadata fields from TMDB
	Thumb           string     `gorm:"size:500" json:"thumb,omitempty"`          // Poster URL
	Art             string     `gorm:"size:500" json:"art,omitempty"`            // Backdrop URL
	SeasonNumber    *int       `json:"seasonNumber,omitempty"`
	EpisodeNumber   *int       `json:"episodeNumber,omitempty"`
	Genres          string     `gorm:"size:500" json:"genres,omitempty"`         // Comma-separated
	ContentRating   string     `gorm:"size:20" json:"contentRating,omitempty"`   // TV-MA, PG-13, etc.
	Year            *int       `json:"year,omitempty"`
	Duration        *int       `json:"duration,omitempty"`                       // Runtime in minutes
	OriginalAirDate *time.Time `json:"originalAirDate,omitempty"`
	TMDBId          *int       `json:"tmdbId,omitempty"`
	IsMovie         bool       `gorm:"default:false" json:"isMovie"`
	Rating          *float64   `json:"rating,omitempty"`                         // TMDB rating
	ChannelName     string     `gorm:"size:200" json:"channelName,omitempty"`    // Cached channel name
	ChannelLogo     string     `gorm:"size:500" json:"channelLogo,omitempty"`    // Cached channel logo
	ViewOffset      *int64     `json:"viewOffset,omitempty"`                     // Watch progress in ms
	// File browser state
	IsWatched       bool       `gorm:"default:false" json:"isWatched"`            // Marked as watched
	IsFavorite      bool       `gorm:"default:false" json:"isFavorite"`           // Marked as favorite
	KeepForever     bool       `gorm:"default:false" json:"keepForever"`          // Keep forever (skip auto-delete)
	IsDeleted       bool       `gorm:"default:false;index" json:"isDeleted"`      // Soft-deleted (trash)
	DeletedAt       *time.Time `json:"deletedAt,omitempty"`                       // When it was trashed
	ContentType     string     `gorm:"size:20;default:show" json:"contentType"`   // show, movie, video, image, unmatched
	VideoCodec      string     `gorm:"size:50" json:"videoCodec,omitempty"`       // h264, hevc, etc.
	AudioCodec      string     `gorm:"size:50" json:"audioCodec,omitempty"`       // aac, ac3, eac3, etc.
	VideoResolution string     `gorm:"size:20" json:"videoResolution,omitempty"`  // 1080i, 720p, 480i, etc.
	HasCC           bool       `gorm:"default:false" json:"hasCC"`                // Has closed captions
	HasDVS          bool       `gorm:"default:false" json:"hasDVS"`               // Has descriptive audio
	// Retry handling
	RetryCount int    `gorm:"default:0" json:"retryCount"`
	MaxRetries int    `gorm:"default:3" json:"maxRetries"`
	LastError  string `gorm:"size:2000" json:"lastError,omitempty"`
	// Quality preset
	QualityPreset string `gorm:"size:20;default:original" json:"qualityPreset,omitempty"` // original, high, medium, low
	TargetBitrate int    `gorm:"default:0" json:"targetBitrate,omitempty"`                // bps, 0 = copy
	// Conflict handling
	Priority        int        `gorm:"default:50" json:"priority"`               // 0-100, higher = more important
	ConflictGroupID *uint      `gorm:"index" json:"conflictGroupId,omitempty"`   // Groups conflicting recordings
	CreatedAt       time.Time  `json:"createdAt"`
	UpdatedAt       time.Time  `json:"updatedAt"`

	// Commercial segments (preloaded for Android app)
	Commercials []CommercialSegment `gorm:"foreignKey:RecordingID" json:"commercials,omitempty"`
}

// SeriesRule represents a series recording rule
type SeriesRule struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"index" json:"userId"`
	Title       string    `gorm:"size:500" json:"title"`
	ChannelID   *uint     `gorm:"index" json:"channelId,omitempty"` // nil = any channel
	Keywords    string    `gorm:"size:500" json:"keywords,omitempty"`
	TimeSlot    string    `gorm:"size:20" json:"timeSlot,omitempty"`   // e.g., "20:00"
	DaysOfWeek  string    `gorm:"size:20" json:"daysOfWeek,omitempty"` // e.g., "1,2,3,4,5"
	KeepCount   int       `gorm:"default:0" json:"keepCount"`          // 0 = keep all
	PrePadding  int       `json:"prePadding"`                          // minutes
	PostPadding int       `json:"postPadding"`                         // minutes
	Enabled     bool      `gorm:"default:true" json:"enabled"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// TeamPass represents an auto-recording rule for sports teams
type TeamPass struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"index" json:"userId"`
	TeamName    string    `gorm:"size:200" json:"teamName"`            // Primary team name
	TeamAliases string    `gorm:"size:500" json:"teamAliases"`         // Comma-separated aliases
	League      string    `gorm:"size:50" json:"league"`               // NFL, NBA, MLB, NHL, MLS, etc.
	ChannelIDs  string    `gorm:"size:500" json:"channelIds,omitempty"` // Comma-separated channel IDs (empty = all)
	PrePadding  int       `gorm:"default:5" json:"prePadding"`         // Minutes before start
	PostPadding     int       `gorm:"default:60" json:"postPadding"`       // Minutes after end (games run long)
	RecordPreGame   bool      `gorm:"default:false" json:"recordPreGame"`  // Auto-detect and record pre-game show
	RecordPostGame  bool      `gorm:"default:false" json:"recordPostGame"` // Auto-detect and record post-game show
	PreGameMinutes  int       `gorm:"default:30" json:"preGameMinutes"`    // Max pre-game minutes to look for
	PostGameMinutes int       `gorm:"default:60" json:"postGameMinutes"`   // Max post-game minutes to look for
	KeepCount       int       `gorm:"default:0" json:"keepCount"`          // 0 = keep all
	Priority        int       `gorm:"default:0" json:"priority"`           // For conflict resolution
	Enabled         bool      `gorm:"default:true" json:"enabled"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// CommercialSegment represents a detected commercial segment in a recording
type CommercialSegment struct {
	ID          uint    `gorm:"primaryKey" json:"id"`
	RecordingID uint    `gorm:"index" json:"recordingId"`
	FileID      *uint   `gorm:"index" json:"fileId,omitempty"` // DVR v2 link
	StartTime   float64 `json:"startTime"`  // seconds from beginning
	EndTime     float64 `json:"endTime"`    // seconds from beginning
	Duration    float64 `json:"duration"`   // seconds
	CreatedAt   time.Time
}

// RecordingWatchProgress tracks per-user watch progress for recordings
type RecordingWatchProgress struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"uniqueIndex:idx_user_recording" json:"userId"`
	RecordingID uint      `gorm:"uniqueIndex:idx_user_recording" json:"recordingId"`
	ViewOffset  int64     `json:"viewOffset"`  // Position in milliseconds
	UpdatedAt   time.Time `json:"updatedAt"`
}

// ========== Archive/Catch-up Models ==========

// ArchiveProgram represents an archived program available for catch-up playback
type ArchiveProgram struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	ChannelID   uint      `gorm:"index:idx_archive_channel_time" json:"channelId"`
	ProgramID   *uint     `gorm:"index" json:"programId,omitempty"` // Link to EPG Program if matched
	Title       string    `gorm:"size:500" json:"title"`
	Description string    `gorm:"type:text" json:"description,omitempty"`
	StartTime   time.Time `gorm:"index:idx_archive_channel_time" json:"startTime"`
	EndTime     time.Time `json:"endTime"`
	Duration    int       `json:"duration"` // seconds
	Icon        string    `gorm:"size:2000" json:"icon,omitempty"`
	Category    string    `gorm:"size:100" json:"category,omitempty"`

	// Archive storage info
	ArchiveDir       string `gorm:"size:2000" json:"archiveDir"`                // Directory containing segments
	StartSegmentIdx  int    `json:"startSegmentIdx"`                            // First segment index
	EndSegmentIdx    int    `json:"endSegmentIdx"`                              // Last segment index
	SegmentDuration  int    `json:"segmentDuration"`                            // Segment length in seconds
	Status           string `gorm:"size:20;default:available" json:"status"`    // available, recording, expired
	FileSize         int64  `json:"fileSize,omitempty"`                         // Approximate total size

	CreatedAt time.Time `json:"createdAt"`
	ExpiresAt time.Time `gorm:"index" json:"expiresAt"` // When this archive will be deleted
}

// ========== Play Queue Models ==========

// PlayQueue represents a play queue session
type PlayQueue struct {
	ID                 uint      `gorm:"primaryKey" json:"playQueueID"`
	UserID             uint      `gorm:"index" json:"userId"`
	SourceURI          string    `gorm:"size:1000" json:"playQueueSourceURI,omitempty"`
	SelectedItemID     *uint     `json:"playQueueSelectedItemID,omitempty"`
	SelectedItemOffset int64     `json:"playQueueSelectedItemOffset"`
	Shuffled           bool      `gorm:"default:false" json:"playQueueShuffled"`
	Version            int       `gorm:"default:1" json:"playQueueVersion"`
	CreatedAt          time.Time
	UpdatedAt          time.Time

	Items []PlayQueueItem `gorm:"foreignKey:PlayQueueID" json:"-"`
}

// PlayQueueItem represents an item in a play queue
type PlayQueueItem struct {
	ID          uint `gorm:"primaryKey" json:"playQueueItemID"`
	PlayQueueID uint `gorm:"index" json:"playQueueId"`
	MediaItemID uint `gorm:"index" json:"ratingKey"`
	Order       int  `json:"order"`
}

// ========== Playback Session Models ==========

// PlaybackSession represents an active playback session
type PlaybackSession struct {
	ID              string    `gorm:"primaryKey;size:36" json:"sessionKey"`
	UserID          uint      `gorm:"index" json:"userId"`
	ProfileID       *uint     `gorm:"index" json:"profileId,omitempty"`
	MediaItemID     uint      `gorm:"index" json:"ratingKey"`
	MediaFileID     uint      `json:"mediaFileId"`
	State           string    `gorm:"size:20;default:'playing'" json:"state"` // playing, paused, buffering, stopped
	ViewOffset      int64     `json:"viewOffset"`                              // Current position in ms
	Duration        int64     `json:"duration"`                                // Total duration in ms
	Progress        float64   `json:"progress"`                                // 0.0 - 1.0
	Transcoding     bool      `json:"transcoding"`
	TranscodeSession string   `gorm:"size:100" json:"transcodeSession,omitempty"`
	Quality         string    `gorm:"size:20" json:"quality,omitempty"`
	PlaybackSpeed   float64   `json:"playbackSpeed" gorm:"default:1.0"`
	ClientName      string    `gorm:"size:100" json:"player,omitempty"`
	ClientPlatform  string    `gorm:"size:50" json:"platform,omitempty"`
	ClientAddress   string    `gorm:"size:50" json:"address,omitempty"`
	StartedAt       time.Time `json:"startedAt"`
	LastActiveAt    time.Time `json:"lastActiveAt"`
	CreatedAt       time.Time
	UpdatedAt       time.Time

	// Relations (not loaded by default)
	User      *User      `gorm:"foreignKey:UserID" json:"-"`
	MediaItem *MediaItem `gorm:"foreignKey:MediaItemID" json:"-"`
}

// Setting stores application settings as key-value pairs
type Setting struct {
	Key       string `gorm:"primaryKey;size:100" json:"key"`
	Value     string `gorm:"type:text" json:"value"`
	CreatedAt time.Time
	UpdatedAt time.Time
}

// ========== Offline Download Models ==========

// OfflineDownload tracks a media item downloaded to a client device for offline viewing
type OfflineDownload struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	UserID      uint      `json:"userId" gorm:"index"`
	DeviceID    string    `json:"deviceId" gorm:"index"`  // client device identifier
	MediaItemID uint      `json:"mediaItemId"`
	MediaFileID uint      `json:"mediaFileId"`

	Title       string    `json:"title"`
	Quality     string    `json:"quality"`     // original, high, medium, low
	FileSize    int64     `json:"fileSize"`    // estimated size in bytes

	Status      string    `json:"status" gorm:"default:'pending'"` // pending, downloading, completed, expired, deleted
	Progress    float64   `json:"progress"`    // 0.0 - 1.0
	ExpiresAt   time.Time `json:"expiresAt"`   // when the download expires (e.g., 30 days)

	// Watch state sync
	WatchedPosition int64 `json:"watchedPosition"` // ms position synced back from device
	Watched         bool  `json:"watched"`

	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// ========== Client Device Management ==========

// ClientDevice represents a registered client device with server-managed settings
type ClientDevice struct {
	ID          uint      `json:"id" gorm:"primaryKey"`
	DeviceID    string    `json:"deviceId" gorm:"uniqueIndex;not null"` // unique device identifier from client
	DisplayName string    `json:"displayName"`                          // user-friendly name (e.g., "Living Room Apple TV")
	Platform    string    `json:"platform"`                             // apple_tv, android_tv, fire_tv, ios, android, web
	LastSeen    time.Time `json:"lastSeen"`
	IPAddress   string    `json:"ipAddress"`
	AppVersion  string    `json:"appVersion"`

	// Extended device info (populated from client registration)
	DeviceModel    string `json:"deviceModel"`                           // e.g., "Apple TV 4K (3rd gen)", "Pixel 7"
	OSVersion      string `json:"osVersion"`                             // e.g., "tvOS 17.2", "Android 14"
	ConnectionType string `json:"connectionType" gorm:"default:'local'"` // local, remote

	// Channel collection assignment
	ChannelCollectionID uint `json:"channelCollectionId"` // 0 means all channels

	// Server-controlled settings
	KioskMode    bool   `json:"kioskMode"`    // hide settings/admin on this device
	KidsOnlyMode bool   `json:"kidsOnlyMode"` // restrict to kids-rated content only
	MaxRating    string `json:"maxRating"`     // max content rating (G, PG, PG-13, R, etc.) - overrides user profile

	// Playback defaults for this device
	DefaultQuality string `json:"defaultQuality"` // original, high, medium, low
	MaxBitrate     int    `json:"maxBitrate"`      // max bitrate in kbps (0 = unlimited)

	// Display preferences
	StartupSection string `json:"startupSection"` // what section to show on launch (home, livetv, dvr, kids, sports)
	Theme          string `json:"theme"`           // dark, light, auto

	// Sidebar navigation visibility
	SidebarSections string `json:"sidebarSections"` // comma-separated: "home,livetv,dvr,movies,shows,kids,sports,search"

	// Feature toggles
	EnableDVR       bool `json:"enableDVR" gorm:"default:true"`
	EnableLiveTV    bool `json:"enableLiveTV" gorm:"default:true"`
	EnableDownloads bool `json:"enableDownloads" gorm:"default:true"`

	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// ========== Personal Section Models ==========

// PersonalSection represents a user-curated section for the client sidebar
type PersonalSection struct {
	ID          uint           `gorm:"primaryKey" json:"id"`
	UserID      uint           `gorm:"index" json:"userId"`
	Name        string         `gorm:"size:255" json:"name"`
	Description string         `gorm:"type:text" json:"description,omitempty"`
	SectionType string         `gorm:"size:20;default:manual" json:"sectionType"` // "smart" or "manual"
	SmartFilter string         `gorm:"type:text" json:"smartFilter,omitempty"`    // JSON filter criteria for smart sections
	Position    int            `json:"position"`
	ItemCount   int            `gorm:"-" json:"itemCount"`
	CreatedAt   time.Time      `json:"createdAt"`
	UpdatedAt   time.Time      `json:"updatedAt"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"-"`

	Items []PersonalSectionItem `gorm:"foreignKey:SectionID" json:"items,omitempty"`
}

// PersonalSectionItem represents an item in a personal section
type PersonalSectionItem struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	SectionID uint      `gorm:"index" json:"sectionId"`
	MediaID   uint      `gorm:"index" json:"mediaId"`
	Position  int       `json:"position"`
	CreatedAt time.Time `json:"createdAt"`
}
