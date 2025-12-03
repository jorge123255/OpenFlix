package livetv

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/openflix/openflix-server/internal/models"
	"gorm.io/gorm"
)

// M3UParser parses M3U playlists
type M3UParser struct {
	db *gorm.DB
}

// NewM3UParser creates a new M3U parser
func NewM3UParser(db *gorm.DB) *M3UParser {
	return &M3UParser{db: db}
}

// ParsedChannel represents a channel parsed from M3U
type ParsedChannel struct {
	Name     string
	Number   int
	Logo     string
	Group    string
	StreamURL string
	TVGId    string
	TVGName  string
}

// ParseM3U parses an M3U playlist from a URL or content
func (p *M3UParser) ParseM3U(content string) ([]ParsedChannel, error) {
	var channels []ParsedChannel

	scanner := bufio.NewScanner(strings.NewReader(content))
	var currentChannel *ParsedChannel

	// Regex patterns for parsing EXTINF line
	tvgIdPattern := regexp.MustCompile(`tvg-id="([^"]*)"`)
	tvgNamePattern := regexp.MustCompile(`tvg-name="([^"]*)"`)
	tvgLogoPattern := regexp.MustCompile(`tvg-logo="([^"]*)"`)
	groupTitlePattern := regexp.MustCompile(`group-title="([^"]*)"`)
	channelNumPattern := regexp.MustCompile(`tvg-chno="(\d+)"`)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		if strings.HasPrefix(line, "#EXTINF:") {
			currentChannel = &ParsedChannel{}

			// Extract TVG-ID
			if matches := tvgIdPattern.FindStringSubmatch(line); len(matches) > 1 {
				currentChannel.TVGId = matches[1]
			}

			// Extract TVG-Name
			if matches := tvgNamePattern.FindStringSubmatch(line); len(matches) > 1 {
				currentChannel.TVGName = matches[1]
			}

			// Extract logo
			if matches := tvgLogoPattern.FindStringSubmatch(line); len(matches) > 1 {
				currentChannel.Logo = matches[1]
			}

			// Extract group
			if matches := groupTitlePattern.FindStringSubmatch(line); len(matches) > 1 {
				currentChannel.Group = matches[1]
			}

			// Extract channel number
			if matches := channelNumPattern.FindStringSubmatch(line); len(matches) > 1 {
				currentChannel.Number, _ = strconv.Atoi(matches[1])
			}

			// Extract channel name (last part after the comma)
			if idx := strings.LastIndex(line, ","); idx != -1 {
				currentChannel.Name = strings.TrimSpace(line[idx+1:])
			}

		} else if currentChannel != nil && !strings.HasPrefix(line, "#") && line != "" {
			// This is the stream URL
			currentChannel.StreamURL = line
			channels = append(channels, *currentChannel)
			currentChannel = nil
		}
	}

	return channels, scanner.Err()
}

// FetchAndParseM3U fetches an M3U from URL and parses it
func (p *M3UParser) FetchAndParseM3U(url string) ([]ParsedChannel, error) {
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch M3U: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch M3U: status %d", resp.StatusCode)
	}

	content, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read M3U: %w", err)
	}

	return p.ParseM3U(string(content))
}

// ImportChannels imports parsed channels into the database
func (p *M3UParser) ImportChannels(sourceID uint, channels []ParsedChannel) (int, int, error) {
	added := 0
	updated := 0

	// Track seen channels in this import to handle duplicates within the M3U
	seen := make(map[string]bool)

	for i, ch := range channels {
		// Generate channel number if not provided
		number := ch.Number
		if number == 0 {
			number = i + 1
		}

		// Create a unique key for deduplication
		// Use stream URL + name as the key since TVGId might be empty or duplicated
		uniqueKey := fmt.Sprintf("%s|%s|%d", ch.StreamURL, ch.Name, sourceID)
		if seen[uniqueKey] {
			continue // Skip duplicate within this import
		}
		seen[uniqueKey] = true

		// Check if channel already exists - use stream_url + name as unique identifier
		var existing models.Channel
		result := p.db.Where("m3_u_source_id = ? AND stream_url = ? AND name = ?",
			sourceID, ch.StreamURL, ch.Name).First(&existing)

		if result.Error == nil {
			// Update existing
			existing.Logo = ch.Logo
			existing.Group = ch.Group
			existing.Number = number
			if ch.TVGId != "" {
				existing.ChannelID = ch.TVGId
			}
			p.db.Save(&existing)
			updated++
		} else {
			// Create new
			channel := models.Channel{
				M3USourceID: sourceID,
				ChannelID:   ch.TVGId,
				Name:        ch.Name,
				Logo:        ch.Logo,
				Group:       ch.Group,
				Number:      number,
				StreamURL:   ch.StreamURL,
				Enabled:     true,
			}
			p.db.Create(&channel)
			added++
		}
	}

	return added, updated, nil
}

// RefreshSource refreshes channels from an M3U source
func (p *M3UParser) RefreshSource(source *models.M3USource) error {
	channels, err := p.FetchAndParseM3U(source.URL)
	if err != nil {
		return err
	}

	_, _, err = p.ImportChannels(source.ID, channels)
	if err != nil {
		return err
	}

	// Update source metadata
	now := time.Now()
	source.LastFetched = &now

	return p.db.Save(source).Error
}
