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

// MediaFile represents a physical media file
type MediaFile struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	MediaItemID uint   `gorm:"index" json:"mediaItemId"`
	FilePath    string `gorm:"size:2000" json:"file"`
	FileSize    int64  `json:"size"`
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
	UserID      uint      `gorm:"index" json:"userId"`
	ProfileID   uint      `gorm:"index" json:"profileId"`
	MediaItemID uint      `gorm:"index" json:"ratingKey"`
	ViewOffset  int64     `json:"viewOffset"` // milliseconds
	ViewCount   int       `json:"viewCount"`
	LastViewedAt time.Time `json:"lastViewedAt"`
	Completed   bool      `json:"completed"`
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

// ========== Live TV Models ==========

// M3USource represents an M3U playlist source
type M3USource struct {
	ID          uint       `gorm:"primaryKey" json:"id"`
	Name        string     `gorm:"size:255" json:"name"`
	URL         string     `gorm:"size:2000" json:"url"`
	EPGUrl      string     `gorm:"size:2000" json:"epgUrl,omitempty"`
	Enabled     bool       `gorm:"default:true" json:"enabled"`
	LastFetched *time.Time `json:"lastFetched,omitempty"`
	CreatedAt   time.Time  `json:"createdAt"`
	UpdatedAt   time.Time  `json:"updatedAt"`
}

// EPGSource represents a standalone XMLTV EPG source
type EPGSource struct {
	ID            uint       `gorm:"primaryKey" json:"id"`
	Name          string     `gorm:"size:255" json:"name"`
	URL           string     `gorm:"size:2000" json:"url"`
	Enabled       bool       `gorm:"default:true" json:"enabled"`
	LastFetched   *time.Time `json:"lastFetched,omitempty"`
	ProgramCount  int        `json:"programCount"`
	ChannelCount  int        `json:"channelCount"`
	CreatedAt     time.Time  `json:"createdAt"`
	UpdatedAt     time.Time  `json:"updatedAt"`
}

// Channel represents a Live TV channel
type Channel struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	M3USourceID uint   `gorm:"index" json:"sourceId"`
	ChannelID   string `gorm:"size:255;index" json:"channelId"` // EPG channel ID
	Number      int    `gorm:"index" json:"number"`
	Name        string `gorm:"size:255" json:"name"`
	Logo        string `gorm:"size:2000" json:"logo,omitempty"`
	Group       string `gorm:"size:255;index" json:"group,omitempty"`
	StreamURL   string `gorm:"size:2000" json:"streamUrl"`
	Enabled     bool   `gorm:"default:true" json:"enabled"`
	IsFavorite  bool   `gorm:"default:false" json:"isFavorite"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// Program represents an EPG program entry
type Program struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	ChannelID   string    `gorm:"size:255;index" json:"channelId"`
	Title       string    `gorm:"size:500" json:"title"`
	Description string    `gorm:"type:text" json:"description,omitempty"`
	Start       time.Time `gorm:"index" json:"start"`
	End         time.Time `gorm:"index" json:"end"`
	Icon        string    `gorm:"size:2000" json:"icon,omitempty"`
	Category    string    `gorm:"size:100" json:"category,omitempty"`
	EpisodeNum  string    `gorm:"size:50" json:"episodeNum,omitempty"`
	CreatedAt   time.Time
}

// ========== DVR Models ==========

// Recording represents a DVR recording
type Recording struct {
	ID          uint       `gorm:"primaryKey" json:"id"`
	UserID      uint       `gorm:"index" json:"userId"`
	ChannelID   uint       `gorm:"index" json:"channelId"`
	ProgramID   *uint      `gorm:"index" json:"programId,omitempty"`
	Title       string     `gorm:"size:500" json:"title"`
	Description string     `gorm:"type:text" json:"description,omitempty"`
	StartTime   time.Time  `json:"startTime"`
	EndTime     time.Time  `json:"endTime"`
	Status      string     `gorm:"size:20;index" json:"status"` // scheduled, recording, completed, failed
	FilePath    string     `gorm:"size:2000" json:"filePath,omitempty"`
	FileSize    int64      `json:"fileSize,omitempty"`
	SeriesRuleID *uint     `gorm:"index" json:"seriesRuleId,omitempty"`
	CreatedAt   time.Time  `json:"createdAt"`
	UpdatedAt   time.Time  `json:"updatedAt"`
}

// SeriesRule represents a series recording rule
type SeriesRule struct {
	ID           uint   `gorm:"primaryKey" json:"id"`
	UserID       uint   `gorm:"index" json:"userId"`
	Title        string `gorm:"size:500" json:"title"`
	ChannelID    *uint  `gorm:"index" json:"channelId,omitempty"` // nil = any channel
	Keywords     string `gorm:"size:500" json:"keywords,omitempty"`
	TimeSlot     string `gorm:"size:20" json:"timeSlot,omitempty"` // e.g., "20:00"
	DaysOfWeek   string `gorm:"size:20" json:"daysOfWeek,omitempty"` // e.g., "1,2,3,4,5"
	KeepCount    int    `gorm:"default:0" json:"keepCount"` // 0 = keep all
	PrePadding   int    `json:"prePadding"`   // minutes
	PostPadding  int    `json:"postPadding"`  // minutes
	Enabled      bool   `gorm:"default:true" json:"enabled"`
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// CommercialSegment represents a detected commercial segment in a recording
type CommercialSegment struct {
	ID          uint    `gorm:"primaryKey" json:"id"`
	RecordingID uint    `gorm:"index" json:"recordingId"`
	StartTime   float64 `json:"startTime"`  // seconds from beginning
	EndTime     float64 `json:"endTime"`    // seconds from beginning
	Duration    float64 `json:"duration"`   // seconds
	CreatedAt   time.Time
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
