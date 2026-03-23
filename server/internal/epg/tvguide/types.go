package tvguide

import (
	"fmt"
	"time"
)

// ── Airing Attribute Bitmask ────────────────────────────────────────────────
// Bit 19 (0x80000) = valid schedule entry (always set)
// Lower 8 bits are flags:
const (
	FlagLive     = 0x01 // Live broadcast
	FlagLiveAlt  = 0x02 // Live (sports variant)
	FlagNew      = 0x04 // New episode / first airing
	FlagSports   = 0x08 // Sports event
	FlagCC       = 0x10 // Closed captioning / HD
)

// Category IDs from TVGuide
const (
	CategoryMovie         = 1
	CategorySports        = 2
	CategoryKids          = 3
	CategoryNews          = 4
	CategoryEntertainment = 5
)

// CategoryNames maps TVGuide category IDs to names
var CategoryNames = map[int]string{
	CategoryMovie:         "Movie",
	CategorySports:        "Sports",
	CategoryKids:          "Kids",
	CategoryNews:          "News",
	CategoryEntertainment: "Entertainment",
}

// ── API Response Types ──────────────────────────────────────────────────────

// ProviderResponse is the response from the provider lookup endpoint
type ProviderResponse struct {
	Data ProviderData `json:"data"`
}

// ProviderData contains the list of providers
type ProviderData struct {
	Items []Provider `json:"items"`
}

// Provider represents a TV service provider (cable, streaming, antenna, etc.)
type Provider struct {
	ID       int64  `json:"id"`
	Name     string `json:"name"`
	Type     string `json:"type"`     // cable, satellite, vMVPD (streaming), broadcast
	City     string `json:"city"`
	State    string `json:"state"`
	LegacyID int64  `json:"legacyId"`
}

// IDString returns the provider ID as a string (for use in API calls and storage)
func (p Provider) IDString() string {
	return fmt.Sprintf("%d", p.ID)
}

// ScheduleResponse is the response from the schedule/listings endpoint
type ScheduleResponse struct {
	Data ScheduleData `json:"data"`
}

// ScheduleData contains the channel listings
type ScheduleData struct {
	Items []ChannelSchedule `json:"items"`
}

// ChannelSchedule represents a channel and its program schedule
type ChannelSchedule struct {
	Channel          ChannelInfo       `json:"channel"`
	ProgramSchedules []ProgramSchedule `json:"programSchedules"`
}

// ChannelInfo contains channel metadata
type ChannelInfo struct {
	SourceID        int64        `json:"sourceId"`
	Name            string       `json:"name"`            // Call sign (e.g., WLS-DT)
	FullName        string       `json:"fullName"`        // Full name with location
	Number          string       `json:"number"`          // Channel number
	NetworkName     *string      `json:"networkName"`     // Network (ABC, CBS, etc.)
	NetworkID       int          `json:"networkId"`
	Logo            string       `json:"logo"`            // Logo path (relative to ImageBaseURL)
	LegacySourceID  interface{}  `json:"legacySourceId"`  // Can be null
}

// ImageRef contains image metadata
type ImageRef struct {
	ID           string    `json:"id"`
	BucketType   string    `json:"bucketType"`
	BucketPath   string    `json:"bucketPath"`
	Width        int       `json:"width"`
	Height       int       `json:"height"`
	ImageType    ImageType `json:"imageType"`
}

// ImageType describes the kind of image
type ImageType struct {
	TypeID       int    `json:"typeId"`
	TypeName     string `json:"typeName"` // showcard, poster art, etc.
}

// ProgramSchedule represents a scheduled airing
type ProgramSchedule struct {
	ProgramID      int    `json:"programId"`
	Title          string `json:"title"`
	StartTime      int64  `json:"startTime"` // Unix epoch
	EndTime        int64  `json:"endTime"`   // Unix epoch
	AiringAttrib   int    `json:"airingAttrib"`
	CatID          int    `json:"catId"`
	Rating         string `json:"rating,omitempty"`
	ProgramDetails interface{}   `json:"programDetails,omitempty"` // 1 = has details available
}

// ProgramDetailResponse is the response from the program details endpoint
type ProgramDetailResponse struct {
	Data ProgramDetailData `json:"data"`
}

// ProgramDetailData contains the program detail item
type ProgramDetailData struct {
	Item ProgramDetail `json:"item"`
}

// ProgramDetail contains full program metadata
type ProgramDetail struct {
	ID              int           `json:"id"`
	Name            string        `json:"name"`
	Title           string        `json:"title"`
	Description     string        `json:"description,omitempty"`
	EpisodeTitle    string        `json:"episodeTitle,omitempty"`
	SeasonNumber    int           `json:"seasonNumber,omitempty"`
	EpisodeNumber   int           `json:"episodeNumber,omitempty"`
	EpisodeAirDate  string        `json:"episodeAirDate,omitempty"` // "/Date(epoch)/"
	ReleaseYear     int           `json:"releaseYear,omitempty"`
	TVRating        string        `json:"tvRating,omitempty"`
	Rating          interface{}   `json:"rating,omitempty"` // Can be null
	CategoryID      int           `json:"categoryId,omitempty"`
	IsSportsEvent   bool          `json:"isSportsEvent"`
	Slug            string        `json:"slug,omitempty"`
	Type            string        `json:"type,omitempty"` // "show", "movie", "episode"
	TypeID          int           `json:"typeId,omitempty"`
	Images          []ImageRef    `json:"images,omitempty"`
	Genres          []Genre       `json:"genres,omitempty"`
	Video           *VideoRef     `json:"video,omitempty"`
}

// Genre represents a genre classification
type Genre struct {
	ID     int      `json:"id"`
	Name   string   `json:"name"`
	Genres []string `json:"genres,omitempty"` // Sub-genres
}

// VideoRef contains trailer/clip reference
type VideoRef struct {
	VideoID   int    `json:"videoId"`
	Title     string `json:"title,omitempty"`
	URL       string `json:"url,omitempty"`
	Duration  int    `json:"duration,omitempty"`
}

// ── Helper Types ────────────────────────────────────────────────────────────

// AiringFlags decoded from the airingAttrib bitmask
type AiringFlags struct {
	IsNew    bool
	IsLive   bool
	IsSports bool
	HasCC    bool
}

// DecodeAiringFlags decodes the airingAttrib bitmask into structured flags
func DecodeAiringFlags(attrib int) AiringFlags {
	flags := attrib & 0xFF
	return AiringFlags{
		IsNew:    flags&FlagNew != 0,
		IsLive:   flags&(FlagLive|FlagLiveAlt) != 0,
		IsSports: flags&FlagSports != 0,
		HasCC:    flags&FlagCC != 0,
	}
}

// ImageBaseURL is the base URL for TVGuide images
const ImageBaseURL = "https://www.tvguide.com/a/img/catalog"

// FullImageURL returns the complete URL for an image
func FullImageURL(bucketPath string) string {
	if bucketPath == "" {
		return ""
	}
	return ImageBaseURL + bucketPath
}

// ProviderConfig holds settings for a TVGuide EPG source
type ProviderConfig struct {
	ProviderID string
	ZipCode    string
	Hours      int // Hours of data to fetch (max ~336 = 14 days)
	FetchDetails bool // Whether to fetch full program details (slower)
}

// FetchResult contains the result of a TVGuide EPG fetch
type FetchResult struct {
	Channels  []ChannelSchedule
	FetchedAt time.Time
	Duration  time.Duration
}
