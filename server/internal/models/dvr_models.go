package models

import (
	"time"

	"gorm.io/gorm"
)

// ========== Channels DVR-Style Models ==========

// DVRJob represents a scheduled or active recording (equivalent to Channels DVR's Job)
type DVRJob struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	UserID    uint      `gorm:"index" json:"userId"`
	RuleID    *uint     `gorm:"index" json:"ruleId,omitempty"`
	ChannelID uint      `gorm:"index" json:"channelId"`
	ProgramID *uint     `gorm:"index" json:"programId,omitempty"`
	Title     string    `gorm:"size:500" json:"title"`
	Subtitle  string    `gorm:"size:500" json:"subtitle,omitempty"`
	Description string  `gorm:"type:text" json:"description,omitempty"`
	StartTime time.Time `gorm:"index" json:"startTime"`
	EndTime   time.Time `json:"endTime"`
	Status    string    `gorm:"size:20;index" json:"status"` // scheduled, recording, completed, failed, cancelled, conflict

	// Priority and quality
	Priority      int    `gorm:"default:50" json:"priority"`                          // 0-100
	QualityPreset string `gorm:"size:20;default:original" json:"qualityPreset,omitempty"` // original, high, medium, low
	TargetBitrate int    `gorm:"default:0" json:"targetBitrate,omitempty"`

	// Padding (seconds)
	PaddingStart int `gorm:"default:0" json:"paddingStart"`
	PaddingEnd   int `gorm:"default:0" json:"paddingEnd"`

	// Retry handling
	RetryCount   int        `gorm:"default:0" json:"retryCount"`
	MaxRetries   int        `gorm:"default:3" json:"maxRetries"`
	RetryTimeout *time.Time `json:"retryTimeout,omitempty"`
	LastError    string     `gorm:"size:2000" json:"lastError,omitempty"`
	Cancelled    bool       `gorm:"default:false" json:"cancelled"`

	// Cached metadata for display (avoid JOINs for listing)
	ChannelName string `gorm:"size:200" json:"channelName,omitempty"`
	ChannelLogo string `gorm:"size:500" json:"channelLogo,omitempty"`
	Category    string `gorm:"size:100" json:"category,omitempty"`
	EpisodeNum  string `gorm:"size:50" json:"episodeNum,omitempty"`
	IsMovie     bool   `gorm:"default:false" json:"isMovie"`
	IsSports    bool   `gorm:"default:false" json:"isSports"`

	// Series recording
	SeriesRecord   bool  `gorm:"default:false" json:"seriesRecord"`
	SeriesParentID *uint `gorm:"index" json:"seriesParentId,omitempty"`

	// Duplicate detection
	IsDuplicate        bool  `gorm:"default:false" json:"isDuplicate"`
	DuplicateOfID      *uint `gorm:"index" json:"duplicateOfId,omitempty"`
	AcceptedDuplicate  bool  `gorm:"default:false" json:"acceptedDuplicate"`

	// Conflict grouping
	ConflictGroupID *uint `gorm:"index" json:"conflictGroupId,omitempty"`

	// Result - points to DVRFile when recording is completed
	FileID *uint `gorm:"index" json:"fileId,omitempty"`

	// Legacy link for migration tracking
	LegacyRecordingID *uint `gorm:"index" json:"-"`

	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

func (DVRJob) TableName() string { return "dvr_jobs" }

// DVRFile represents a completed recording on disk (equivalent to Channels DVR's File)
type DVRFile struct {
	ID      uint  `gorm:"primaryKey" json:"id"`
	JobID   *uint `gorm:"index" json:"jobId,omitempty"`
	GroupID *uint `gorm:"index" json:"groupId,omitempty"`

	// File info
	Title       string `gorm:"size:500" json:"title"`
	Subtitle    string `gorm:"size:500" json:"subtitle,omitempty"`
	Description string `gorm:"type:text" json:"description,omitempty"`
	Summary     string `gorm:"type:text" json:"summary,omitempty"`
	FilePath    string `gorm:"size:2000;uniqueIndex" json:"filePath"`
	FileSize    int64  `json:"fileSize"`
	Duration    int    `json:"duration,omitempty"`                   // seconds
	VideoURL    string `gorm:"size:2000" json:"videoUrl,omitempty"` // for remote/stream links
	Container   string `gorm:"size:20" json:"container,omitempty"`  // mp4, ts, mkv

	// Processing state (Channels DVR style booleans)
	Processed bool `gorm:"default:false" json:"processed"`
	Completed bool `gorm:"default:true" json:"completed"`
	Deleted   bool `gorm:"default:false;index" json:"deleted"`
	Cancelled bool `gorm:"default:false" json:"cancelled"`

	// TMDB Metadata
	Thumb           string     `gorm:"size:500" json:"thumb,omitempty"`
	Art             string     `gorm:"size:500" json:"art,omitempty"`
	SeasonNumber    *int       `json:"seasonNumber,omitempty"`
	EpisodeNumber   *int       `json:"episodeNumber,omitempty"`
	EpisodeNum      string     `gorm:"size:50" json:"episodeNum,omitempty"`
	Genres          string     `gorm:"size:500" json:"genres,omitempty"`
	ContentRating   string     `gorm:"size:20" json:"contentRating,omitempty"`
	Year            *int       `json:"year,omitempty"`
	OriginalAirDate *time.Time `json:"originalAirDate,omitempty"`
	TMDBId          *int       `json:"tmdbId,omitempty"`
	IsMovie         bool       `gorm:"default:false" json:"isMovie"`
	Rating          *float64   `json:"rating,omitempty"`

	// Channel info (cached from recording)
	ChannelName string `gorm:"size:200" json:"channelName,omitempty"`
	ChannelLogo string `gorm:"size:500" json:"channelLogo,omitempty"`
	Category    string `gorm:"size:100" json:"category,omitempty"`

	// Labels and extras (Channels DVR concept)
	Labels string `gorm:"size:500" json:"labels,omitempty"` // Comma-separated
	Extras string `gorm:"type:text" json:"extras,omitempty"` // JSON array of extras

	// Recording timestamps
	AiredAt    *time.Time `json:"airedAt,omitempty"`    // When the program originally aired
	RecordedAt *time.Time `json:"recordedAt,omitempty"` // When the recording was captured

	// Ad stripping state
	AdsStripped      bool   `gorm:"default:false" json:"adsStripped"`
	AdStripStatus    string `gorm:"size:20" json:"adStripStatus,omitempty"`      // pending, running, completed, failed
	AdStripError     string `gorm:"size:2000" json:"adStripError,omitempty"`
	AdStripMode      string `gorm:"size:20" json:"adStripMode,omitempty"`        // copy, reencode
	OriginalFilePath string `gorm:"size:2000" json:"originalFilePath,omitempty"` // backup of pre-strip file
	OriginalFileSize int64  `json:"originalFileSize,omitempty"`

	// Legacy link for migration tracking
	LegacyRecordingID *uint `gorm:"index" json:"-"`

	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	Commercials      []CommercialSegment `gorm:"foreignKey:FileID" json:"commercials,omitempty"`
	DetectedSegments []DetectedSegment   `gorm:"foreignKey:FileID" json:"detectedSegments,omitempty"`
}

func (DVRFile) TableName() string { return "dvr_files" }

// DetectedSegment represents an intro/outro/credits segment detected in a file
type DetectedSegment struct {
	ID        uint    `gorm:"primaryKey" json:"id"`
	FileID    uint    `gorm:"index" json:"fileId"`
	Type      string  `gorm:"size:20;index" json:"type"` // intro, outro, credits, commercial
	StartTime float64 `json:"startTime"`                 // seconds from beginning
	EndTime   float64 `json:"endTime"`                   // seconds from beginning
	CreatedAt time.Time
}

// SkipEvent records when a user skips a segment (for analytics/tuning)
type SkipEvent struct {
	ID          uint      `gorm:"primaryKey" json:"id"`
	UserID      uint      `gorm:"index" json:"userId"`
	FileID      uint      `gorm:"index" json:"fileId"`
	SegmentType string    `gorm:"size:20;index" json:"segmentType"` // intro, outro, credits, commercial
	SkippedAt   time.Time `gorm:"index" json:"skippedAt"`
}

func (SkipEvent) TableName() string { return "skip_events" }

// DVRGroup represents a show/series grouping of recordings (equivalent to Channels DVR's Group)
type DVRGroup struct {
	ID            uint   `gorm:"primaryKey" json:"id"`
	Title         string `gorm:"size:500;index" json:"title"`
	SortTitle     string `gorm:"size:500" json:"sortTitle,omitempty"`
	Description   string `gorm:"type:text" json:"description,omitempty"`
	Thumb         string `gorm:"size:500" json:"thumb,omitempty"`
	Art           string `gorm:"size:500" json:"art,omitempty"`
	Categories    string `gorm:"size:500" json:"categories,omitempty"` // Comma-separated
	Genres        string `gorm:"size:500" json:"genres,omitempty"`
	Cast          string `gorm:"type:text" json:"cast,omitempty"` // JSON array
	ContentRating string `gorm:"size:20" json:"contentRating,omitempty"`
	Year          *int   `json:"year,omitempty"`
	TMDBId        *int   `json:"tmdbId,omitempty"`
	TMDBType      string `gorm:"size:10" json:"tmdbType,omitempty"` // movie, tv
	FileCount     int    `gorm:"default:0" json:"fileCount"`

	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	Files []DVRFile `gorm:"foreignKey:GroupID" json:"files,omitempty"`
}

func (DVRGroup) TableName() string { return "dvr_groups" }

// FileState represents per-user watch state for a file (equivalent to Channels DVR's Profile.FileState)
type FileState struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	ProfileID    uint      `gorm:"uniqueIndex:idx_profile_file" json:"profileId"`
	FileID       uint      `gorm:"uniqueIndex:idx_profile_file" json:"fileId"`
	Watched      bool      `gorm:"default:false" json:"watched"`
	PlaybackTime int64     `json:"playbackTime"` // milliseconds
	Favorited    bool      `gorm:"default:false" json:"favorited"`
	PlayedAt     *time.Time `json:"playedAt,omitempty"`
	FavoritedAt  *time.Time `json:"favoritedAt,omitempty"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// GroupState represents per-user state for a group (equivalent to Channels DVR's Profile.GroupState)
type GroupState struct {
	ID            uint      `gorm:"primaryKey" json:"id"`
	ProfileID     uint      `gorm:"uniqueIndex:idx_profile_group" json:"profileId"`
	GroupID       uint      `gorm:"uniqueIndex:idx_profile_group" json:"groupId"`
	NumUnwatched  int       `gorm:"default:0" json:"numUnwatched"`
	UpNextFileID  *uint     `json:"upNextFileId,omitempty"` // FileID of next unwatched
	Favorited     bool      `gorm:"default:false" json:"favorited"`
	FavoritedAt   *time.Time `json:"favoritedAt,omitempty"`
	UpdatedAt     time.Time `json:"updatedAt"`
}

// DVRRule represents a recording rule with query DSL (equivalent to Channels DVR's Rule)
type DVRRule struct {
	ID     uint   `gorm:"primaryKey" json:"id"`
	UserID uint   `gorm:"index" json:"userId"`
	Name   string `gorm:"size:500" json:"name"`
	Image  string `gorm:"size:500" json:"image,omitempty"`

	// Query DSL - JSON array of conditions
	// e.g. [{"field":"title","op":"EQ","value":"Seinfeld"},{"field":"isNew","op":"EQ","value":"true"}]
	Query string `gorm:"type:text" json:"query"`

	// Recording behavior
	KeepOnly   bool   `gorm:"default:false" json:"keepOnly"` // Only keep matching, delete others
	KeepNum    int    `gorm:"default:0" json:"keepNum"`      // Max recordings to keep (0=unlimited)
	Rerecord   bool   `gorm:"default:false" json:"rerecord"` // Re-record deleted episodes
	Duplicates string `gorm:"size:20;default:skip" json:"duplicates"` // skip, record
	Limit      int    `gorm:"default:0" json:"limit"` // Max concurrent jobs (0=unlimited)

	// Padding (seconds)
	PaddingStart int `gorm:"default:0" json:"paddingStart"`
	PaddingEnd   int `gorm:"default:0" json:"paddingEnd"`

	// Pre/post show recording (for sports and event content)
	RecordPreShow   bool `gorm:"default:false" json:"recordPreShow"`   // Auto-detect related pre-show
	RecordPostShow  bool `gorm:"default:false" json:"recordPostShow"`  // Auto-detect related post-show
	PreShowMinutes  int  `gorm:"default:30" json:"preShowMinutes"`     // Max pre-show search window
	PostShowMinutes int  `gorm:"default:60" json:"postShowMinutes"`    // Max post-show search window

	// Priority and quality
	Priority      int    `gorm:"default:50" json:"priority"`
	QualityPreset string `gorm:"size:20;default:original" json:"qualityPreset"`

	Paused    bool      `gorm:"default:false" json:"paused"`
	Enabled   bool      `gorm:"default:true" json:"enabled"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`

	// Legacy link for migration tracking
	LegacySeriesRuleID *uint `gorm:"index" json:"-"`
	LegacyTeamPassID   *uint `gorm:"index" json:"-"`
}

func (DVRRule) TableName() string { return "dvr_rules" }

// RuleCondition represents a single condition in a Rule's query DSL
type RuleCondition struct {
	Field string `json:"field"` // title, channel, category, genre, isNew, isSports, isMovie, team, league, dayOfWeek, timeSlot, seriesId, contentRating
	Op    string `json:"op"`    // EQ, NE, GT, LT, IN, NI (not in), LIKE
	Value string `json:"value"`
}

// VirtualStation represents a custom virtual channel from library content
type VirtualStation struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	Name        string `gorm:"size:255" json:"name"`
	Number      int    `json:"number"`
	Logo        string `gorm:"size:2000" json:"logo,omitempty"`
	Art         string `gorm:"size:2000" json:"art,omitempty"`
	Description string `gorm:"type:text" json:"description,omitempty"`

	// Smart matching rule (same Query DSL as DVRRule)
	SmartRule string `gorm:"type:text" json:"smartRule,omitempty"`

	// Manual file list (for non-smart stations)
	FileIDs string `gorm:"type:text" json:"fileIds,omitempty"` // Comma-separated

	// Playback behavior
	Sort    string `gorm:"size:50" json:"sort,omitempty"`  // date, title, random
	Order   string `gorm:"size:10" json:"order,omitempty"` // asc, desc
	Shuffle bool   `gorm:"default:false" json:"shuffle"`
	Loop    bool   `gorm:"default:true" json:"loop"`
	Limit   int    `gorm:"default:0" json:"limit"` // Max items (0=unlimited)

	Enabled   bool      `gorm:"default:true" json:"enabled"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// DVRCollection represents a smart playlist of recordings
type DVRCollection struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	Title       string `gorm:"size:255" json:"title"`
	Description string `gorm:"type:text" json:"description,omitempty"`
	Thumb       string `gorm:"size:500" json:"thumb,omitempty"`

	// Smart matching
	Smart     bool   `gorm:"default:false" json:"smart"`
	SmartRule string `gorm:"type:text" json:"smartRule,omitempty"` // Query DSL

	// TMDB franchise integration
	TMDBCollectionID *int `json:"tmdbCollectionId,omitempty"`

	// Manual items for non-smart collections
	FileIDs  string `gorm:"type:text" json:"fileIds,omitempty"`  // Comma-separated
	GroupIDs string `gorm:"type:text" json:"groupIds,omitempty"` // Comma-separated

	// Display options
	Sort  string `gorm:"size:50" json:"sort,omitempty"`
	Order string `gorm:"size:10" json:"order,omitempty"`

	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// ChannelCollection represents a custom channel lineup
type ChannelCollection struct {
	ID          uint   `gorm:"primaryKey" json:"id"`
	Name        string `gorm:"size:255" json:"name"`
	Description string `gorm:"type:text" json:"description,omitempty"`

	// Channel list (ordered)
	ChannelIDs string `gorm:"type:text" json:"channelIds"` // Comma-separated, ordered

	// Include virtual stations
	VirtualStationIDs string `gorm:"type:text" json:"virtualStationIds,omitempty"` // Comma-separated

	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// ========== Bookmarks & Clips ==========

// Bookmark represents a saved moment in a recording or media file
type Bookmark struct {
	ID          uint    `gorm:"primaryKey" json:"id"`
	UserID      uint    `gorm:"index" json:"userId"`
	FileID      *uint   `gorm:"index" json:"fileId,omitempty"`      // DVRFile reference
	RecordingID *uint   `gorm:"index" json:"recordingId,omitempty"` // Legacy Recording reference
	MediaItemID *uint   `gorm:"index" json:"mediaItemId,omitempty"` // Library media reference
	Title       string  `gorm:"size:500" json:"title"`
	Note        string  `gorm:"type:text" json:"note,omitempty"`
	Timestamp   float64 `json:"timestamp"`                            // Position in seconds
	Thumbnail   string  `gorm:"size:2000" json:"thumbnail,omitempty"` // Auto-generated thumbnail path
	Tags        string  `gorm:"size:500" json:"tags,omitempty"`       // Comma-separated tags
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

// Clip represents an extracted video segment
type Clip struct {
	ID          uint    `gorm:"primaryKey" json:"id"`
	UserID      uint    `gorm:"index" json:"userId"`
	FileID      *uint   `gorm:"index" json:"fileId,omitempty"`
	RecordingID *uint   `gorm:"index" json:"recordingId,omitempty"`
	MediaItemID *uint   `gorm:"index" json:"mediaItemId,omitempty"`
	Title       string  `gorm:"size:500" json:"title"`
	Note        string  `gorm:"type:text" json:"note,omitempty"`
	StartTime   float64 `json:"startTime"`                              // seconds
	EndTime     float64 `json:"endTime"`                                // seconds
	Duration    float64 `json:"duration"`                               // seconds
	FilePath    string  `gorm:"size:2000" json:"filePath,omitempty"`    // Extracted clip file
	FileSize    int64   `json:"fileSize,omitempty"`
	Status      string  `gorm:"size:20;default:pending" json:"status"`  // pending, processing, ready, failed
	Format      string  `gorm:"size:10;default:mp4" json:"format"`      // mp4, gif, webm
	Error       string  `gorm:"size:2000" json:"error,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
}
