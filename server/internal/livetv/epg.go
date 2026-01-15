package livetv

import (
	"compress/gzip"
	"context"
	"encoding/xml"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/epg/gracenote"
	"github.com/openflix/openflix-server/internal/logger"
	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// EPGParser parses XMLTV EPG data
type EPGParser struct {
	db         *gorm.DB
	classifier *ContentClassifier
}

// NewEPGParser creates a new EPG parser
func NewEPGParser(db *gorm.DB) *EPGParser {
	return &EPGParser{
		db:         db,
		classifier: NewContentClassifier(),
	}
}

// XMLTV represents the root element of an XMLTV file
type XMLTV struct {
	XMLName    xml.Name         `xml:"tv"`
	Channels   []XMLTVChannel   `xml:"channel"`
	Programmes []XMLTVProgramme `xml:"programme"`
}

// XMLTVChannel represents a channel in XMLTV
type XMLTVChannel struct {
	ID          string        `xml:"id,attr"`
	DisplayName []XMLTVLang   `xml:"display-name"`
	Icon        *XMLTVIcon    `xml:"icon"`
}

// XMLTVProgramme represents a programme in XMLTV
type XMLTVProgramme struct {
	Start           string           `xml:"start,attr"`
	Stop            string           `xml:"stop,attr"`
	Channel         string           `xml:"channel,attr"`
	Title           []XMLTVLang      `xml:"title"`
	SubTitle        []XMLTVLang      `xml:"sub-title"`
	Desc            []XMLTVLang      `xml:"desc"`
	Category        []XMLTVLang      `xml:"category"`
	Icon            *XMLTVIcon       `xml:"icon"`
	EpisodeNum      []XMLTVEpNum     `xml:"episode-num"`
	New             *struct{}        `xml:"new"`              // Empty element indicates new episode
	Premiere        *XMLTVPremiere   `xml:"premiere"`         // Premiere indicator
	PreviouslyShown *XMLTVPrevShown  `xml:"previously-shown"` // Rerun indicator
	Live            *struct{}        `xml:"live"`             // Live broadcast
	Rating          []XMLTVRating    `xml:"rating"`           // Content rating
	Date            string           `xml:"date"`             // Original air date (YYYY or YYYYMMDD)
}

// XMLTVPremiere represents a premiere element
type XMLTVPremiere struct {
	Value string `xml:",chardata"` // Optional text like "Series Premiere"
}

// XMLTVPrevShown represents a previously-shown element
type XMLTVPrevShown struct {
	Start   string `xml:"start,attr"`   // Original air date
	Channel string `xml:"channel,attr"` // Original channel
}

// XMLTVRating represents a content rating
type XMLTVRating struct {
	System string `xml:"system,attr"`
	Value  string `xml:"value"`
}

// XMLTVLang represents a localized string
type XMLTVLang struct {
	Lang  string `xml:"lang,attr"`
	Value string `xml:",chardata"`
}

// XMLTVIcon represents an icon
type XMLTVIcon struct {
	Src string `xml:"src,attr"`
}

// XMLTVEpNum represents episode numbering
type XMLTVEpNum struct {
	System string `xml:"system,attr"`
	Value  string `xml:",chardata"`
}

// ParseXMLTV parses XMLTV content
func (p *EPGParser) ParseXMLTV(content []byte) (*XMLTV, error) {
	var xmltv XMLTV
	if err := xml.Unmarshal(content, &xmltv); err != nil {
		return nil, fmt.Errorf("failed to parse XMLTV: %w", err)
	}
	return &xmltv, nil
}

// EPGFetchResult contains the result of a conditional EPG fetch
type EPGFetchResult struct {
	XMLTV        *XMLTV
	NotModified  bool   // True if server returned 304 Not Modified
	ETag         string // New ETag from response
	LastModified string // New Last-Modified from response
}

// FetchAndParseEPG fetches and parses EPG from URL (without conditional request support)
func (p *EPGParser) FetchAndParseEPG(url string) (*XMLTV, error) {
	result, err := p.FetchAndParseEPGConditional(url, "", "")
	if err != nil {
		return nil, err
	}
	return result.XMLTV, nil
}

// FetchAndParseEPGConditional fetches EPG with conditional request support (ETag/Last-Modified)
// If the content hasn't changed (304 response), returns NotModified=true with nil XMLTV
func (p *EPGParser) FetchAndParseEPGConditional(url, etag, lastModified string) (*EPGFetchResult, error) {
	client := &http.Client{Timeout: 120 * time.Second}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Add conditional request headers if we have cached values
	if etag != "" {
		req.Header.Set("If-None-Match", etag)
	}
	if lastModified != "" {
		req.Header.Set("If-Modified-Since", lastModified)
	}

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch EPG: %w", err)
	}
	defer resp.Body.Close()

	// Check for 304 Not Modified
	if resp.StatusCode == http.StatusNotModified {
		return &EPGFetchResult{
			NotModified:  true,
			ETag:         etag,         // Keep existing values
			LastModified: lastModified,
		}, nil
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch EPG: status %d", resp.StatusCode)
	}

	var reader io.Reader = resp.Body

	// Handle gzip compression
	if strings.HasSuffix(url, ".gz") || resp.Header.Get("Content-Encoding") == "gzip" {
		gzReader, err := gzip.NewReader(resp.Body)
		if err != nil {
			return nil, fmt.Errorf("failed to decompress EPG: %w", err)
		}
		defer gzReader.Close()
		reader = gzReader
	}

	content, err := io.ReadAll(reader)
	if err != nil {
		return nil, fmt.Errorf("failed to read EPG: %w", err)
	}

	xmltv, err := p.ParseXMLTV(content)
	if err != nil {
		return nil, err
	}

	return &EPGFetchResult{
		XMLTV:        xmltv,
		NotModified:  false,
		ETag:         resp.Header.Get("ETag"),
		LastModified: resp.Header.Get("Last-Modified"),
	}, nil
}

// ImportPrograms imports EPG programs into the database
func (p *EPGParser) ImportPrograms(sourceID uint, xmltv *XMLTV) (int, error) {
	// Build channel map (tvg_id -> channel_id string for EPG matching)
	var channels []models.Channel
	p.db.Where("m3_u_source_id = ?", sourceID).Find(&channels)

	// Map EPG channel ID to our channel's ChannelID field
	channelMap := make(map[string]string)
	for _, ch := range channels {
		if ch.ChannelID != "" {
			channelMap[ch.ChannelID] = ch.ChannelID
		}
	}

	imported := 0
	now := time.Now()

	// Delete old programs (before today)
	p.db.Where("start < ?", now.Add(-24*time.Hour)).Delete(&models.Program{})

	for _, prog := range xmltv.Programmes {
		channelID, ok := channelMap[prog.Channel]
		if !ok {
			continue
		}

		start, err := parseXMLTVTime(prog.Start)
		if err != nil {
			continue
		}

		stop, err := parseXMLTVTime(prog.Stop)
		if err != nil {
			continue
		}

		// Skip programs in the past
		if stop.Before(now) {
			continue
		}

		// Get title
		title := ""
		if len(prog.Title) > 0 {
			title = prog.Title[0].Value
		}

		// Get description
		desc := ""
		if len(prog.Desc) > 0 {
			desc = prog.Desc[0].Value
		}

		// Get category
		category := ""
		if len(prog.Category) > 0 {
			category = prog.Category[0].Value
		}

		// Get episode number
		episodeNum := ""
		if len(prog.EpisodeNum) > 0 {
			episodeNum = prog.EpisodeNum[0].Value
		}

		// Get icon
		icon := ""
		if prog.Icon != nil {
			icon = prog.Icon.Src
		}

		// Get content rating
		rating := ""
		if len(prog.Rating) > 0 {
			rating = prog.Rating[0].Value
		}

		// Determine new/premiere/live status from XMLTV elements
		isNew := prog.New != nil                           // <new/> element present
		isPremiere := prog.Premiere != nil                 // <premiere/> element present
		isLive := prog.Live != nil                         // <live/> element present
		isRerun := prog.PreviouslyShown != nil             // <previously-shown/> means it's a rerun

		// If it's explicitly marked as previously-shown, it's NOT new (unless also marked new)
		if isRerun && !isNew && !isPremiere {
			isNew = false
		}

		// Check if program already exists
		var existing models.Program
		result := p.db.Where("channel_id = ? AND start = ?", channelID, start).First(&existing)

		if result.Error == nil {
			// Update existing
			existing.End = *stop
			existing.Title = title
			existing.Description = desc
			existing.Category = category
			existing.EpisodeNum = episodeNum
			existing.Icon = icon
			existing.Rating = rating
			existing.IsNew = isNew
			existing.IsPremiere = isPremiere
			existing.IsLive = isLive
			// Classify content
			p.classifier.ClassifyProgram(&existing)
			p.db.Save(&existing)
		} else {
			// Create new
			program := models.Program{
				ChannelID:   channelID,
				Start:       *start,
				End:         *stop,
				Title:       title,
				Description: desc,
				Category:    category,
				EpisodeNum:  episodeNum,
				Icon:        icon,
				Rating:      rating,
				IsNew:       isNew,
				IsPremiere:  isPremiere,
				IsLive:      isLive,
			}
			// Classify content
			p.classifier.ClassifyProgram(&program)
			p.db.Create(&program)
			imported++
		}
	}

	return imported, nil
}

// RefreshEPG refreshes EPG for a source with retry logic and conditional request support
func (p *EPGParser) RefreshEPG(source *models.M3USource) error {
	if source.EPGUrl == "" {
		return nil
	}

	retrier := NewRetrier(DefaultRetryConfig())
	var fetchResult *EPGFetchResult

	// Fetch with retry, using conditional request headers
	result := retrier.Do(context.Background(), "fetch EPG for "+source.Name, func() error {
		var err error
		fetchResult, err = p.FetchAndParseEPGConditional(source.EPGUrl, source.EPGETag, source.EPGLastModified)
		return err
	})

	if !result.Success {
		return fmt.Errorf("failed to fetch EPG after %d attempts: %w", result.Attempts, result.LastError)
	}

	// If content hasn't changed (304 Not Modified), skip import
	if fetchResult.NotModified {
		logger.Log.Infof("EPG for %s not modified (304), skipping import", source.Name)
		return nil
	}

	// Update cache headers
	source.EPGETag = fetchResult.ETag
	source.EPGLastModified = fetchResult.LastModified
	p.db.Save(source)

	// Import programs (no retry needed for DB operations)
	imported, err := p.ImportPrograms(source.ID, fetchResult.XMLTV)
	if err != nil {
		return fmt.Errorf("failed to import programs: %w", err)
	}

	logger.Log.Infof("Imported %d programs for %s", imported, source.Name)
	return nil
}

// parseXMLTVTime parses XMLTV time format (YYYYMMDDHHmmss +HHMM)
func parseXMLTVTime(s string) (*time.Time, error) {
	// Remove any spaces and handle timezone
	s = strings.TrimSpace(s)

	// Try different formats
	formats := []string{
		"20060102150405 -0700",
		"20060102150405 +0700",
		"20060102150405",
	}

	for _, format := range formats {
		if t, err := time.Parse(format, s); err == nil {
			return &t, nil
		}
	}

	return nil, fmt.Errorf("unable to parse time: %s", s)
}

// GetCurrentProgram returns the currently playing program for a channel
func (p *EPGParser) GetCurrentProgram(channelID string) (*models.Program, error) {
	now := time.Now()
	var program models.Program
	err := p.db.Where("channel_id = ? AND start <= ? AND end > ?",
		channelID, now, now).First(&program).Error
	if err != nil {
		return nil, err
	}
	return &program, nil
}

// GetNextProgram returns the next program for a channel
func (p *EPGParser) GetNextProgram(channelID string) (*models.Program, error) {
	now := time.Now()
	var program models.Program
	err := p.db.Where("channel_id = ? AND start > ?", channelID, now).
		Order("start ASC").First(&program).Error
	if err != nil {
		return nil, err
	}
	return &program, nil
}

// GetGuide returns the EPG guide for a time range
func (p *EPGParser) GetGuide(start, end time.Time, channelIDs []string) ([]models.Program, error) {
	var programs []models.Program
	query := p.db.Where("start < ? AND end > ?", end, start)

	if len(channelIDs) > 0 {
		query = query.Where("channel_id IN ?", channelIDs)
	}

	err := query.Order("channel_id, start").Find(&programs).Error
	return programs, err
}

// ImportProgramsFromEPGSource imports programs from a standalone EPG source
func (p *EPGParser) ImportProgramsFromEPGSource(source *models.EPGSource, xmltv *XMLTV) (int, int, error) {
	imported := 0
	now := time.Now()

	// Delete old programs (before today)
	p.db.Where("start < ?", now.Add(-24*time.Hour)).Delete(&models.Program{})

	// Count unique channels in the EPG
	channelSet := make(map[string]bool)
	for _, ch := range xmltv.Channels {
		channelSet[ch.ID] = true
	}

	for _, prog := range xmltv.Programmes {
		start, err := parseXMLTVTime(prog.Start)
		if err != nil {
			continue
		}

		stop, err := parseXMLTVTime(prog.Stop)
		if err != nil {
			continue
		}

		// Skip programs in the past
		if stop.Before(now) {
			continue
		}

		// Get title
		title := ""
		if len(prog.Title) > 0 {
			title = prog.Title[0].Value
		}

		// Get description
		desc := ""
		if len(prog.Desc) > 0 {
			desc = prog.Desc[0].Value
		}

		// Get category
		category := ""
		if len(prog.Category) > 0 {
			category = prog.Category[0].Value
		}

		// Get episode number
		episodeNum := ""
		if len(prog.EpisodeNum) > 0 {
			episodeNum = prog.EpisodeNum[0].Value
		}

		// Get icon
		icon := ""
		if prog.Icon != nil {
			icon = prog.Icon.Src
		}

		// Check if program already exists
		var existing models.Program
		result := p.db.Where("channel_id = ? AND start = ?", prog.Channel, start).First(&existing)

		if result.Error == nil {
			// Update existing
			existing.End = *stop
			existing.Title = title
			existing.Description = desc
			existing.Category = category
			existing.EpisodeNum = episodeNum
			existing.Icon = icon
			// Classify content
			p.classifier.ClassifyProgram(&existing)
			p.db.Save(&existing)
		} else {
			// Create new
			program := models.Program{
				ChannelID:   prog.Channel,
				Start:       *start,
				End:         *stop,
				Title:       title,
				Description: desc,
				Category:    category,
				EpisodeNum:  episodeNum,
				Icon:        icon,
			}
			// Classify content
			p.classifier.ClassifyProgram(&program)
			p.db.Create(&program)
			imported++
		}
	}

	return imported, len(channelSet), nil
}

// ImportProgramsFromGracenote imports programs from Gracenote TV listings
func (p *EPGParser) ImportProgramsFromGracenote(source *models.EPGSource) (int, int, error) {
	imported := 0
	now := time.Now()

	// Create Gracenote client
	gnClient := gracenote.NewBrowserClient(gracenote.Config{
		BaseURL:   "https://tvlistings.gracenote.com",
		UserAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
		Timeout:   30 * time.Second,
	})

	// Fetch listings
	ctx := context.Background()
	gridResp, err := gnClient.GetListingsForAffiliate(
		ctx,
		source.GracenoteAffiliate,
		source.GracenotePostalCode,
		source.GracenoteHours,
	)
	if err != nil {
		return 0, 0, fmt.Errorf("failed to fetch Gracenote listings: %w", err)
	}

	// Count unique channels first to build the list
	channelSet := make(map[string]bool)
	for _, channel := range gridResp.Channels {
		channelID := fmt.Sprintf("gracenote-%s-%s", source.GracenoteAffiliate, channel.ChannelID)
		channelSet[channelID] = true
	}

	// Delete old programs only for THIS source's channels (not globally!)
	if len(channelSet) > 0 {
		channelIDs := make([]string, 0, len(channelSet))
		for chID := range channelSet {
			channelIDs = append(channelIDs, chID)
		}
		p.db.Where("channel_id IN ? AND start < ?", channelIDs, now.Add(-24*time.Hour)).Delete(&models.Program{})
	}

	// Process each channel and its programs
	for i, channel := range gridResp.Channels {
		channelID := fmt.Sprintf("gracenote-%s-%s", source.GracenoteAffiliate, channel.ChannelID)

		// Debug: print first channel to see what data we're getting
		if i == 0 {
			fmt.Printf("🔍 DEBUG - First channel data:\n")
			fmt.Printf("  ChannelID: %s\n", channel.ChannelID)
			fmt.Printf("  CallSign: '%s'\n", channel.CallSign)
			fmt.Printf("  ChannelNo: '%s'\n", channel.ChannelNo)
			fmt.Printf("  AffiliateName: '%s'\n", channel.AffiliateName)
			fmt.Printf("  Thumbnail: '%s'\n", channel.Thumbnail)
		}

		// Process each event/program
		for _, event := range channel.Events {
			// Parse start and end times
			start, err := time.Parse(time.RFC3339, event.StartTime)
			if err != nil {
				continue
			}

			end, err := time.Parse(time.RFC3339, event.EndTime)
			if err != nil {
				continue
			}

			// Skip programs in the past
			if end.Before(now) {
				continue
			}

			// Get category
			category := ""
			if len(event.Tags) > 0 {
				category = event.Tags[0]
			}

			// Get icon
			icon := event.Thumbnail
			if icon == "" && channel.Thumbnail != "" {
				icon = channel.Thumbnail
			}

			// Parse Gracenote flags for new/premiere/live/finale
			isNew := false
			isPremiere := false
			isLive := false
			isFinale := false
			for _, flag := range event.Flag {
				flagLower := strings.ToLower(flag)
				switch {
				case flagLower == "new":
					isNew = true
				case flagLower == "premiere" || strings.Contains(flagLower, "premiere"):
					isPremiere = true
					isNew = true // Premieres are always new
				case flagLower == "live":
					isLive = true
				case flagLower == "finale" || strings.Contains(flagLower, "finale"):
					isFinale = true
				}
			}

			// Check if program already exists
			var existing models.Program
			result := p.db.Where("channel_id = ? AND start = ?", channelID, start).First(&existing)

			if result.Error == nil {
				// Update existing
				existing.End = end
				existing.Title = event.Program.Title
				existing.Description = event.Program.ShortDesc
				existing.Category = category
				existing.Icon = icon
				existing.CallSign = channel.CallSign
				existing.ChannelNo = channel.ChannelNo
				existing.AffiliateName = channel.AffiliateName
				existing.IsNew = isNew
				existing.IsPremiere = isPremiere
				existing.IsLive = isLive
				existing.IsFinale = isFinale
				// Classify content
				p.classifier.ClassifyProgram(&existing)
				p.db.Save(&existing)
			} else {
				// Create new
				program := models.Program{
					ChannelID:     channelID,
					CallSign:      channel.CallSign,
					ChannelNo:     channel.ChannelNo,
					AffiliateName: channel.AffiliateName,
					Start:         start,
					End:           end,
					Title:         event.Program.Title,
					Description:   event.Program.ShortDesc,
					Category:      category,
					Icon:          icon,
					IsNew:         isNew,
					IsPremiere:    isPremiere,
					IsLive:        isLive,
					IsFinale:      isFinale,
				}
				// Classify content
				p.classifier.ClassifyProgram(&program)
				p.db.Create(&program)
				imported++
			}
		}
	}

	return imported, len(channelSet), nil
}

// RefreshEPGSource refreshes programs from a standalone EPG source with retry logic
func (p *EPGParser) RefreshEPGSource(source *models.EPGSource) error {
	var imported, channelCount int
	retrier := NewRetrier(DefaultRetryConfig())

	// Handle different provider types
	if source.ProviderType == "gracenote" {
		// Fetch Gracenote data with retry (no conditional request support for browser-based scraping)
		result := retrier.Do(context.Background(), "fetch Gracenote EPG for "+source.Name, func() error {
			var err error
			imported, channelCount, err = p.ImportProgramsFromGracenote(source)
			return err
		})

		if !result.Success {
			return fmt.Errorf("failed to fetch Gracenote EPG after %d attempts: %w", result.Attempts, result.LastError)
		}
	} else {
		// Default to XMLTV - fetch with retry and conditional request support
		var fetchResult *EPGFetchResult
		result := retrier.Do(context.Background(), "fetch XMLTV EPG for "+source.Name, func() error {
			var err error
			fetchResult, err = p.FetchAndParseEPGConditional(source.URL, source.ETag, source.LastModified)
			return err
		})

		if !result.Success {
			return fmt.Errorf("failed to fetch XMLTV after %d attempts: %w", result.Attempts, result.LastError)
		}

		// If content hasn't changed (304 Not Modified), skip import
		if fetchResult.NotModified {
			logger.Log.Infof("EPG source %s not modified (304), skipping import", source.Name)
			return nil
		}

		// Update cache headers
		source.ETag = fetchResult.ETag
		source.LastModified = fetchResult.LastModified

		var err error
		imported, channelCount, err = p.ImportProgramsFromEPGSource(source, fetchResult.XMLTV)
		if err != nil {
			return fmt.Errorf("failed to import programs: %w", err)
		}

		logger.Log.Infof("Imported %d programs from %d channels for %s", imported, channelCount, source.Name)
	}

	// Update source metadata
	now := time.Now()
	source.LastFetched = &now
	source.ProgramCount = imported
	source.ChannelCount = channelCount

	return p.db.Save(source).Error
}

// GetEPGStats returns statistics about EPG data
func (p *EPGParser) GetEPGStats() (map[string]interface{}, error) {
	var totalPrograms int64
	var futurePrograms int64
	var channelCount int64

	now := time.Now()

	p.db.Model(&models.Program{}).Count(&totalPrograms)
	p.db.Model(&models.Program{}).Where("end > ?", now).Count(&futurePrograms)
	p.db.Model(&models.Program{}).Distinct("channel_id").Count(&channelCount)

	// Get earliest and latest program times
	var earliestProgram, latestProgram models.Program
	p.db.Order("start ASC").First(&earliestProgram)
	p.db.Order("end DESC").First(&latestProgram)

	return map[string]interface{}{
		"totalPrograms":   totalPrograms,
		"futurePrograms":  futurePrograms,
		"channelsWithEPG": channelCount,
		"earliestProgram": earliestProgram.Start,
		"latestProgram":   latestProgram.End,
	}, nil
}
