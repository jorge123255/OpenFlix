package livetv

import (
	"compress/gzip"
	"encoding/xml"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// EPGParser parses XMLTV EPG data
type EPGParser struct {
	db *gorm.DB
}

// NewEPGParser creates a new EPG parser
func NewEPGParser(db *gorm.DB) *EPGParser {
	return &EPGParser{db: db}
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
	Start       string        `xml:"start,attr"`
	Stop        string        `xml:"stop,attr"`
	Channel     string        `xml:"channel,attr"`
	Title       []XMLTVLang   `xml:"title"`
	SubTitle    []XMLTVLang   `xml:"sub-title"`
	Desc        []XMLTVLang   `xml:"desc"`
	Category    []XMLTVLang   `xml:"category"`
	Icon        *XMLTVIcon    `xml:"icon"`
	EpisodeNum  []XMLTVEpNum  `xml:"episode-num"`
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

// FetchAndParseEPG fetches and parses EPG from URL
func (p *EPGParser) FetchAndParseEPG(url string) (*XMLTV, error) {
	client := &http.Client{Timeout: 60 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch EPG: %w", err)
	}
	defer resp.Body.Close()

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

	return p.ParseXMLTV(content)
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
			}
			p.db.Create(&program)
			imported++
		}
	}

	return imported, nil
}

// RefreshEPG refreshes EPG for a source
func (p *EPGParser) RefreshEPG(source *models.M3USource) error {
	if source.EPGUrl == "" {
		return nil
	}

	xmltv, err := p.FetchAndParseEPG(source.EPGUrl)
	if err != nil {
		return err
	}

	_, err = p.ImportPrograms(source.ID, xmltv)
	if err != nil {
		return err
	}

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
			p.db.Create(&program)
			imported++
		}
	}

	return imported, len(channelSet), nil
}

// RefreshEPGSource refreshes programs from a standalone EPG source
func (p *EPGParser) RefreshEPGSource(source *models.EPGSource) error {
	xmltv, err := p.FetchAndParseEPG(source.URL)
	if err != nil {
		return err
	}

	imported, channelCount, err := p.ImportProgramsFromEPGSource(source, xmltv)
	if err != nil {
		return err
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
