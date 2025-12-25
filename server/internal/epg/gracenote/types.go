package gracenote

import "time"

// GridResponse represents the response from the Gracenote grid API
type GridResponse struct {
	Channels []Channel `json:"channels"`
}

// Channel represents a TV channel with its programming schedule
type Channel struct {
	CallSign      string  `json:"callSign"`
	AffiliateName string  `json:"affiliateName"`
	ChannelID     string  `json:"channelId"`
	ChannelNo     string  `json:"channelNo"`
	Thumbnail     string  `json:"thumbnail"`
	Events        []Event `json:"events"`
}

// Event represents a scheduled program on a channel
type Event struct {
	Duration  string   `json:"duration"`
	StartTime string   `json:"startTime"`
	EndTime   string   `json:"endTime"`
	Thumbnail string   `json:"thumbnail"`
	Program   Program  `json:"program"`
	Flag      []string `json:"flag"`
	Tags      []string `json:"tags"`
}

// Program represents details about a TV program
type Program struct {
	Title        string `json:"title"`
	ID           string `json:"id"`
	TmsID        string `json:"tmsId"`
	ShortDesc    string `json:"shortDesc"`
	SeriesID     string `json:"seriesId"`
	EpisodeTitle string `json:"episodeTitle,omitempty"`
}

// AffiliateProperties represents the configuration for an affiliate/provider
type AffiliateProperties struct {
	DefaultPostalCode string `json:"defaultpostalcode"`
	DefaultHeadend    string `json:"defaultheadend"`
	DefaultCountry    string `json:"defaultcountry"`
	HeadendName       string `json:"headendname"`
	Device            string `json:"device"`
	LineupID          string `json:"lineupId,omitempty"`
}

// ListingsParams holds parameters for fetching TV listings
type ListingsParams struct {
	LineupID     string
	HeadendID    string
	Country      string
	PostalCode   string
	Timezone     string
	Time         int64 // Unix timestamp
	Timespan     int   // Hours to fetch
	Device       string
	UserID       string
	AffiliateID  string
	LanguageCode string
}

// CacheStats represents cache statistics
type CacheStats struct {
	Entries   int       `json:"entries"`
	LastClean time.Time `json:"last_clean"`
}

// Provider represents a TV provider (cable, satellite, antenna) for a postal code
type Provider struct {
	HeadendID          string `json:"headendId"`
	Name               string `json:"name"`
	Type               string `json:"type"` // Cable, Satellite, Antenna
	Location           string `json:"location"`
	LineupID           string `json:"lineupId,omitempty"`
	FallbackPostalCode string `json:"fallbackPostalCode,omitempty"` // Used when user's ZIP isn't in Gracenote's DB
}

// ProviderResponse represents the API response for provider discovery
type ProviderResponse struct {
	Cable     []ProviderEntry `json:"Cable"`
	Satellite []ProviderEntry `json:"Satellite"`
	Antenna   []ProviderEntry `json:"Antenna"`
}

// ProviderEntry represents a single provider entry from the API
type ProviderEntry struct {
	ID       string `json:"Id"`
	Name     string `json:"Name"`
	Location string `json:"Location"`
	Type     string `json:"Type"`
}
