package livetv

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"sort"
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
	currentHeaders := make(map[string]string)

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
			currentHeaders = make(map[string]string)

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

		} else if currentChannel != nil && strings.HasPrefix(line, "#EXTVLCOPT:") {
			// VLC-specific per-channel options that often include required HTTP headers.
			// Common forms:
			//   #EXTVLCOPT:http-user-agent=...
			//   #EXTVLCOPT:http-referrer=...
			//   #EXTVLCOPT:http-origin=...
			//   #EXTVLCOPT:http-cookie=...
			//   #EXTVLCOPT:http-header=Header: Value
			opt := strings.TrimPrefix(line, "#EXTVLCOPT:")
			eq := strings.Index(opt, "=")
			if eq > 0 {
				key := strings.TrimSpace(opt[:eq])
				value := strings.TrimSpace(opt[eq+1:])
				switch strings.ToLower(key) {
				case "http-user-agent":
					if value != "" {
						currentHeaders["User-Agent"] = value
					}
				case "http-referrer":
					if value != "" {
						currentHeaders["Referer"] = value
					}
				case "http-origin":
					if value != "" {
						currentHeaders["Origin"] = value
					}
				case "http-cookie":
					if value != "" {
						currentHeaders["Cookie"] = value
					}
				case "http-header":
					// Expect "Header-Name: value"
					if idx := strings.Index(value, ":"); idx > 0 {
						h := strings.TrimSpace(value[:idx])
						hv := strings.TrimSpace(value[idx+1:])
						if h != "" && hv != "" {
							currentHeaders[h] = hv
						}
					}
				}
			}
		} else if currentChannel != nil && !strings.HasPrefix(line, "#") && line != "" {
			// This is the stream URL
			streamURL := line
			if len(currentHeaders) > 0 {
				// Append as VLC-style pipe header syntax so clients can forward headers:
				//   url|Header=Value&Header2=Value2
				keys := make([]string, 0, len(currentHeaders))
				for k := range currentHeaders {
					keys = append(keys, k)
				}
				sort.Strings(keys)
				pairs := make([]string, 0, len(currentHeaders))
				for _, k := range keys {
					pairs = append(pairs, url.QueryEscape(k)+"="+url.QueryEscape(currentHeaders[k]))
				}
				if strings.Contains(streamURL, "|") {
					streamURL = streamURL + "&" + strings.Join(pairs, "&")
				} else {
					streamURL = streamURL + "|" + strings.Join(pairs, "&")
				}
			}
			currentChannel.StreamURL = normalizeStreamURL(streamURL)
			channels = append(channels, *currentChannel)
			currentChannel = nil
		}
	}

	return channels, scanner.Err()
}

func normalizeStreamURL(streamURL string) string {
	pipeIndex := strings.Index(streamURL, "|")
	if pipeIndex < 0 {
		return streamURL
	}

	base := streamURL[:pipeIndex]
	headerPart := streamURL[pipeIndex+1:]
	if strings.TrimSpace(headerPart) == "" {
		return base
	}

	// Parse header key/value pairs separated by '&'
	parsed := make([][2]string, 0)
	for _, seg := range strings.Split(headerPart, "&") {
		seg = strings.TrimSpace(seg)
		if seg == "" {
			continue
		}
		eq := strings.Index(seg, "=")
		if eq <= 0 {
			continue
		}
		rawKey := seg[:eq]
		rawVal := seg[eq+1:]
		key, err := url.QueryUnescape(rawKey)
		if err != nil {
			key = rawKey
		}
		val, err := url.QueryUnescape(rawVal)
		if err != nil {
			val = rawVal
		}
		key = strings.TrimSpace(key)
		val = strings.TrimSpace(val)
		if key == "" || val == "" {
			continue
		}
		parsed = append(parsed, [2]string{key, val})
	}

	if len(parsed) == 0 {
		return base
	}

	sort.Slice(parsed, func(i, j int) bool {
		if parsed[i][0] == parsed[j][0] {
			return parsed[i][1] < parsed[j][1]
		}
		return parsed[i][0] < parsed[j][0]
	})

	parts := make([]string, 0, len(parsed))
	for _, kv := range parsed {
		parts = append(parts, url.QueryEscape(kv[0])+"="+url.QueryEscape(kv[1]))
	}

	return base + "|" + strings.Join(parts, "&")
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

func (p *M3UParser) cleanupDuplicateChannels(sourceID uint) {
	type dupRow struct {
		KeepID    uint   `gorm:"column:keep_id"`
		StreamURL string `gorm:"column:stream_url"`
		Name      string `gorm:"column:name"`
	}

	var dups []dupRow
	// If older versions created duplicates (e.g., non-deterministic header ordering),
	// remove duplicates on refresh and keep the oldest row.
	p.db.
		Raw(
			`SELECT MIN(id) AS keep_id, stream_url, name
			 FROM channels
			 WHERE m3_u_source_id = ?
			 GROUP BY stream_url, name
			 HAVING COUNT(*) > 1`,
			sourceID,
		).
		Scan(&dups)

	for _, d := range dups {
		p.db.
			Where(
				"m3_u_source_id = ? AND stream_url = ? AND name = ? AND id <> ?",
				sourceID,
				d.StreamURL,
				d.Name,
				d.KeepID,
			).
			Delete(&models.Channel{})
	}
}

// ImportChannels imports parsed channels into the database
func (p *M3UParser) ImportChannels(sourceID uint, channels []ParsedChannel) (int, int, error) {
	added := 0
	updated := 0

	p.cleanupDuplicateChannels(sourceID)

	// Get all EPG channel IDs that have programs in the database for validation
	var epgChannelIDs []string
	p.db.Model(&models.Program{}).Distinct("channel_id").Where("channel_id != ''").Pluck("channel_id", &epgChannelIDs)
	validEPGChannels := make(map[string]bool)
	for _, id := range epgChannelIDs {
		validEPGChannels[id] = true
	}

	// Track seen channels in this import to handle duplicates within the M3U
	seen := make(map[string]bool)

	for i, ch := range channels {
		normalizedStreamURL := normalizeStreamURL(ch.StreamURL)
		ch.StreamURL = normalizedStreamURL

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
				existing.TVGId = ch.TVGId // Store original TVG-ID
				// Only set ChannelID from TVGId if:
				// 1. ChannelID is not already mapped
				// 2. TVGId matches a valid EPG channel (has programs)
				if existing.ChannelID == "" && validEPGChannels[ch.TVGId] {
					existing.ChannelID = ch.TVGId
				}
			}
			p.db.Save(&existing)
			updated++
		} else {
			// Create new
			channelID := ""
			// Only use TVGId as ChannelID if it matches a valid EPG channel
			if ch.TVGId != "" && validEPGChannels[ch.TVGId] {
				channelID = ch.TVGId
			}
			channel := models.Channel{
				M3USourceID: sourceID,
				TVGId:       ch.TVGId,   // Store original TVG-ID
				ChannelID:   channelID,  // Only set if TVGId matches EPG programs
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

// ChannelNumberMapping represents a mapping result between M3U and existing channels
type ChannelNumberMapping struct {
	M3UName          string `json:"m3uName"`
	M3UNumber        int    `json:"m3uNumber"`
	MatchedChannelID *uint  `json:"matchedChannelId,omitempty"`
	MatchedName      string `json:"matchedName,omitempty"`
	MatchType        string `json:"matchType"` // "tvg_id", "exact", "fuzzy", "none"
	Applied          bool   `json:"applied"`
	OldNumber        int    `json:"oldNumber,omitempty"`
}

// MapNumbersResult contains the results of channel number mapping
type MapNumbersResult struct {
	Matched   int                    `json:"matched"`
	Unmatched int                    `json:"unmatched"`
	Results   []ChannelNumberMapping `json:"results"`
}

// MapChannelNumbers maps channel numbers from an M3U to existing channels without importing streams
func (p *M3UParser) MapChannelNumbers(content string, preview bool) (*MapNumbersResult, error) {
	// Parse the M3U to get channel names and numbers
	parsedChannels, err := p.ParseM3U(content)
	if err != nil {
		return nil, fmt.Errorf("failed to parse M3U: %w", err)
	}

	// Get all existing channels
	var existingChannels []models.Channel
	if err := p.db.Find(&existingChannels).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch existing channels: %w", err)
	}

	// Build lookup maps for matching
	// 1. TVG-ID lookup (highest priority)
	tvgIdLookup := make(map[string]*models.Channel)
	// 2. Exact name lookup (case-insensitive)
	exactNameLookup := make(map[string]*models.Channel)
	// 3. Normalized name lookup for fuzzy matching
	normalizedNameLookup := make(map[string]*models.Channel)

	for i := range existingChannels {
		ch := &existingChannels[i]
		if ch.TVGId != "" {
			tvgIdLookup[strings.ToLower(ch.TVGId)] = ch
		}
		exactNameLookup[strings.ToLower(ch.Name)] = ch
		normalizedNameLookup[normalizeChannelName(ch.Name)] = ch
	}

	result := &MapNumbersResult{
		Results: make([]ChannelNumberMapping, 0, len(parsedChannels)),
	}

	for _, parsed := range parsedChannels {
		if parsed.Number == 0 {
			continue // Skip channels without numbers
		}

		mapping := ChannelNumberMapping{
			M3UName:   parsed.Name,
			M3UNumber: parsed.Number,
			MatchType: "none",
		}

		var matchedChannel *models.Channel

		// Priority 1: Match by TVG-ID
		if parsed.TVGId != "" {
			if ch, ok := tvgIdLookup[strings.ToLower(parsed.TVGId)]; ok {
				matchedChannel = ch
				mapping.MatchType = "tvg_id"
			}
		}

		// Priority 2: Exact name match (case-insensitive)
		if matchedChannel == nil {
			if ch, ok := exactNameLookup[strings.ToLower(parsed.Name)]; ok {
				matchedChannel = ch
				mapping.MatchType = "exact"
			}
		}

		// Priority 3: Fuzzy match (normalized name)
		if matchedChannel == nil {
			normalizedName := normalizeChannelName(parsed.Name)
			if ch, ok := normalizedNameLookup[normalizedName]; ok {
				matchedChannel = ch
				mapping.MatchType = "fuzzy"
			}
		}

		if matchedChannel != nil {
			mapping.MatchedChannelID = &matchedChannel.ID
			mapping.MatchedName = matchedChannel.Name
			mapping.OldNumber = matchedChannel.Number
			result.Matched++

			// Apply the mapping if not in preview mode
			if !preview && matchedChannel.Number != parsed.Number {
				matchedChannel.Number = parsed.Number
				if err := p.db.Save(matchedChannel).Error; err != nil {
					return nil, fmt.Errorf("failed to update channel %d: %w", matchedChannel.ID, err)
				}
				mapping.Applied = true
			}
		} else {
			result.Unmatched++
		}

		result.Results = append(result.Results, mapping)
	}

	return result, nil
}
