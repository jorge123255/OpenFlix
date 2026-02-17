package providers

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/openflix/openflix-server/internal/logger"
)

// PlutoTV provides access to Pluto TV's free ad-supported streaming channels and EPG data.
type PlutoTV struct {
	client    *http.Client
	channels  []PlutoChannel
	mu        sync.RWMutex
	lastFetch time.Time
	cacheTTL  time.Duration
}

// PlutoChannel represents a Pluto TV live channel.
type PlutoChannel struct {
	ID            string `json:"_id"`
	Name          string `json:"name"`
	Number        int    `json:"number"`
	Summary       string `json:"summary,omitempty"`
	Slug          string `json:"slug"`
	Category      string `json:"category"`
	Logo          string `json:"logo,omitempty"`
	ColorLogo     string `json:"colorLogoPNG,omitempty"`
	Thumbnail     string `json:"thumbnail,omitempty"`
	FeaturedImage string `json:"featuredImage,omitempty"`
	IsStitched    bool   `json:"isStitched"`
	StreamURL     string `json:"-"` // Derived from stitcher
}

// PlutoProgram represents a single program airing on a Pluto TV channel.
type PlutoProgram struct {
	ID          string        `json:"_id"`
	Title       string        `json:"title"`
	Description string        `json:"description,omitempty"`
	Start       time.Time     `json:"start"`
	Stop        time.Time     `json:"stop"`
	Duration    int           `json:"duration"` // milliseconds
	Episode     *PlutoEpisode `json:"episode,omitempty"`
	LiveID      string        `json:"liveID,omitempty"`
}

// PlutoEpisode holds episode-level metadata for a Pluto TV program.
type PlutoEpisode struct {
	ID          string       `json:"_id"`
	Name        string       `json:"name"`
	Number      int          `json:"number"`
	Description string       `json:"description,omitempty"`
	Series      *PlutoSeries `json:"series,omitempty"`
	Poster      string       `json:"poster,omitempty"`
	Thumbnail   string       `json:"thumbnail,omitempty"`
	Rating      string       `json:"rating,omitempty"`
	Genre       string       `json:"genre,omitempty"`
}

// PlutoSeries holds series-level metadata for a Pluto TV episode.
type PlutoSeries struct {
	ID   string `json:"_id"`
	Name string `json:"name"`
	Type string `json:"type"`
}

// PlutoTimeline pairs a channel with its program schedule.
type PlutoTimeline struct {
	Channel  PlutoChannel   `json:"channel"`
	Programs []PlutoProgram `json:"timelines"`
}

// plutoBootResponse is the top-level response from the Pluto TV boot API.
type plutoBootResponse struct {
	Channels []plutoBootChannel `json:"channels"`
}

// plutoBootChannel extends PlutoChannel with the stitched stream info returned by the boot API.
type plutoBootChannel struct {
	PlutoChannel
	Stitched struct {
		URLs []struct {
			Type string `json:"type"`
			URL  string `json:"url"`
		} `json:"urls"`
	} `json:"stitched"`
}

// plutoGuideResponse is the response shape for the timelines API.
type plutoGuideResponse struct {
	Data []plutoTimelineEntry `json:"data"`
}

// plutoTimelineEntry represents one channel's timeline from the guide API.
type plutoTimelineEntry struct {
	ChannelID string         `json:"channelId"`
	Timelines []PlutoProgram `json:"timelines"`
}

// NewPlutoTV creates a new PlutoTV client with a 30-minute cache TTL.
func NewPlutoTV() *PlutoTV {
	return &PlutoTV{
		client: &http.Client{
			Timeout: 30 * time.Second,
		},
		cacheTTL: 30 * time.Minute,
	}
}

// GetChannels fetches the full list of Pluto TV channels, using a local cache to avoid
// hitting the upstream API on every call.
func (p *PlutoTV) GetChannels(ctx context.Context) ([]PlutoChannel, error) {
	p.mu.RLock()
	if len(p.channels) > 0 && time.Since(p.lastFetch) < p.cacheTTL {
		channels := make([]PlutoChannel, len(p.channels))
		copy(channels, p.channels)
		p.mu.RUnlock()
		return channels, nil
	}
	p.mu.RUnlock()

	return p.fetchChannels(ctx)
}

// fetchChannels performs the actual HTTP request against the Pluto TV boot API and
// populates the internal cache.
func (p *PlutoTV) fetchChannels(ctx context.Context) ([]PlutoChannel, error) {
	bootURL := "https://boot.pluto.tv/v4/start?appName=web&appVersion=9.9.0&deviceVersion=131.0.0&deviceModel=web&deviceMake=unknown&deviceType=web&clientID=68c1fbd1&clientModelNumber=1.0.0&serverSideAds=false"

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, bootURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Web) OpenFlix/1.0")
	req.Header.Set("Accept", "application/json")

	resp, err := p.client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch Pluto TV channels: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return nil, fmt.Errorf("Pluto TV API returned status %d: %s", resp.StatusCode, string(body))
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read Pluto TV response: %w", err)
	}

	var bootResp plutoBootResponse
	if err := json.Unmarshal(body, &bootResp); err != nil {
		return nil, fmt.Errorf("failed to parse Pluto TV channels: %w", err)
	}

	channels := make([]PlutoChannel, 0, len(bootResp.Channels))
	for _, bc := range bootResp.Channels {
		ch := bc.PlutoChannel

		// Extract the HLS stream URL from the stitched URLs
		for _, u := range bc.Stitched.URLs {
			if u.Type == "hls" {
				ch.StreamURL = u.URL
				break
			}
		}

		// If no HLS URL found, construct one from the channel ID
		if ch.StreamURL == "" {
			ch.StreamURL = fmt.Sprintf(
				"https://service-stitcher.clusters.pluto.tv/v2/stitch/hls/channel/%s/master.m3u8?deviceType=web&deviceMake=unknown&deviceModel=web&appName=web&appVersion=9.9.0&deviceDNT=0&userId=&advertisingId=&deviceId=unknown&deviceVersion=unknown&sid=unknown",
				ch.ID,
			)
		}

		// Prefer colorLogoPNG over generic logo
		if ch.ColorLogo != "" && ch.Logo == "" {
			ch.Logo = ch.ColorLogo
		}

		channels = append(channels, ch)
	}

	// Sort by channel number
	sort.Slice(channels, func(i, j int) bool {
		return channels[i].Number < channels[j].Number
	})

	p.mu.Lock()
	p.channels = channels
	p.lastFetch = time.Now()
	p.mu.Unlock()

	logger.Infof("Fetched %d Pluto TV channels", len(channels))
	return channels, nil
}

// GetGuide retrieves the program guide for the specified time range.
func (p *PlutoTV) GetGuide(ctx context.Context, start, stop time.Time) ([]PlutoTimeline, error) {
	// Ensure we have channels loaded
	channels, err := p.GetChannels(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to load channels for guide: %w", err)
	}

	// Build a channel lookup map
	channelMap := make(map[string]PlutoChannel, len(channels))
	channelIDs := make([]string, 0, len(channels))
	for _, ch := range channels {
		channelMap[ch.ID] = ch
		channelIDs = append(channelIDs, ch.ID)
	}

	// Fetch guide data in batches (API may limit the number of channel IDs per request)
	const batchSize = 50
	var allTimelines []PlutoTimeline

	for i := 0; i < len(channelIDs); i += batchSize {
		end := i + batchSize
		if end > len(channelIDs) {
			end = len(channelIDs)
		}
		batch := channelIDs[i:end]

		guideURL := fmt.Sprintf(
			"https://service-channels.clusters.pluto.tv/v2/guide/timelines?start=%s&stop=%s&channelIds=%s",
			start.UTC().Format(time.RFC3339),
			stop.UTC().Format(time.RFC3339),
			strings.Join(batch, ","),
		)

		req, err := http.NewRequestWithContext(ctx, http.MethodGet, guideURL, nil)
		if err != nil {
			return nil, fmt.Errorf("failed to create guide request: %w", err)
		}
		req.Header.Set("User-Agent", "Mozilla/5.0 (Web) OpenFlix/1.0")
		req.Header.Set("Accept", "application/json")

		resp, err := p.client.Do(req)
		if err != nil {
			logger.Warnf("Failed to fetch guide batch %d-%d: %v", i, end, err)
			continue
		}

		if resp.StatusCode != http.StatusOK {
			body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
			resp.Body.Close()
			logger.Warnf("Guide API returned status %d for batch %d-%d: %s", resp.StatusCode, i, end, string(body))
			continue
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			logger.Warnf("Failed to read guide response for batch %d-%d: %v", i, end, err)
			continue
		}

		var guideResp plutoGuideResponse
		if err := json.Unmarshal(body, &guideResp); err != nil {
			// The response might be a direct array of timeline entries
			var entries []plutoTimelineEntry
			if err2 := json.Unmarshal(body, &entries); err2 != nil {
				logger.Warnf("Failed to parse guide response for batch %d-%d: %v", i, end, err)
				continue
			}
			guideResp.Data = entries
		}

		for _, entry := range guideResp.Data {
			ch, ok := channelMap[entry.ChannelID]
			if !ok {
				continue
			}
			allTimelines = append(allTimelines, PlutoTimeline{
				Channel:  ch,
				Programs: entry.Timelines,
			})
		}
	}

	logger.Infof("Fetched guide for %d channels (%s to %s)", len(allTimelines),
		start.UTC().Format("15:04"), stop.UTC().Format("15:04"))
	return allTimelines, nil
}

// GetStreamURL returns the HLS stream URL for a given channel ID.
func (p *PlutoTV) GetStreamURL(channelID string) (string, error) {
	p.mu.RLock()
	defer p.mu.RUnlock()

	for _, ch := range p.channels {
		if ch.ID == channelID {
			if ch.StreamURL != "" {
				return ch.StreamURL, nil
			}
			// Construct a default URL
			return fmt.Sprintf(
				"https://service-stitcher.clusters.pluto.tv/v2/stitch/hls/channel/%s/master.m3u8?deviceType=web&deviceMake=unknown&deviceModel=web&appName=web&appVersion=9.9.0&deviceDNT=0&userId=&advertisingId=&deviceId=unknown&deviceVersion=unknown&sid=unknown",
				channelID,
			), nil
		}
	}

	return "", fmt.Errorf("channel %s not found", channelID)
}

// GetCategories returns a sorted, deduplicated list of channel categories.
func (p *PlutoTV) GetCategories(ctx context.Context) ([]string, error) {
	channels, err := p.GetChannels(ctx)
	if err != nil {
		return nil, err
	}

	categorySet := make(map[string]struct{})
	for _, ch := range channels {
		if ch.Category != "" {
			categorySet[ch.Category] = struct{}{}
		}
	}

	categories := make([]string, 0, len(categorySet))
	for cat := range categorySet {
		categories = append(categories, cat)
	}
	sort.Strings(categories)

	return categories, nil
}

// SearchChannels filters the cached channels by name or category (case-insensitive).
func (p *PlutoTV) SearchChannels(query string) []PlutoChannel {
	p.mu.RLock()
	defer p.mu.RUnlock()

	if query == "" {
		return nil
	}

	q := strings.ToLower(query)
	var results []PlutoChannel
	for _, ch := range p.channels {
		if strings.Contains(strings.ToLower(ch.Name), q) ||
			strings.Contains(strings.ToLower(ch.Category), q) ||
			strings.Contains(strings.ToLower(ch.Slug), q) {
			results = append(results, ch)
		}
	}

	return results
}

// ToM3U exports all Pluto TV channels as an M3U playlist string with tvg-id,
// tvg-name, tvg-logo, and group-title attributes.
func (p *PlutoTV) ToM3U(ctx context.Context) (string, error) {
	channels, err := p.GetChannels(ctx)
	if err != nil {
		return "", err
	}

	var b strings.Builder
	b.WriteString("#EXTM3U\n")

	for _, ch := range channels {
		logo := ch.ColorLogo
		if logo == "" {
			logo = ch.Logo
		}

		b.WriteString(fmt.Sprintf(
			"#EXTINF:-1 tvg-id=\"pluto-%s\" tvg-name=\"%s\" tvg-logo=\"%s\" tvg-chno=\"%d\" group-title=\"%s\",%s\n",
			ch.ID,
			escapeM3UField(ch.Name),
			escapeM3UField(logo),
			ch.Number,
			escapeM3UField(ch.Category),
			ch.Name,
		))
		b.WriteString(ch.StreamURL)
		b.WriteString("\n")
	}

	return b.String(), nil
}

// ToXMLTV exports the Pluto TV EPG as XMLTV-formatted XML for the given number of
// hours from now.
func (p *PlutoTV) ToXMLTV(ctx context.Context, hours int) (string, error) {
	if hours <= 0 {
		hours = 4
	}
	if hours > 48 {
		hours = 48
	}

	now := time.Now().UTC()
	start := now.Add(-30 * time.Minute) // Include currently-airing programs
	stop := now.Add(time.Duration(hours) * time.Hour)

	timelines, err := p.GetGuide(ctx, start, stop)
	if err != nil {
		return "", err
	}

	var b strings.Builder
	b.WriteString(`<?xml version="1.0" encoding="UTF-8"?>`)
	b.WriteString("\n")
	b.WriteString(`<!DOCTYPE tv SYSTEM "xmltv.dtd">`)
	b.WriteString("\n")
	b.WriteString(`<tv source-info-name="Pluto TV" generator-info-name="OpenFlix">`)
	b.WriteString("\n")

	// Write channel definitions
	for _, tl := range timelines {
		ch := tl.Channel
		logo := ch.ColorLogo
		if logo == "" {
			logo = ch.Logo
		}

		b.WriteString(fmt.Sprintf(
			`  <channel id="pluto-%s">`+"\n"+
				`    <display-name>%s</display-name>`+"\n"+
				`    <display-name>%d</display-name>`+"\n",
			escapeXML(ch.ID),
			escapeXML(ch.Name),
			ch.Number,
		))
		if logo != "" {
			b.WriteString(fmt.Sprintf(`    <icon src="%s" />`+"\n", escapeXML(logo)))
		}
		b.WriteString("  </channel>\n")
	}

	// Write program entries
	xmlTimeFormat := "20060102150405 -0700"
	for _, tl := range timelines {
		for _, prog := range tl.Programs {
			startStr := prog.Start.UTC().Format(xmlTimeFormat)
			stopStr := prog.Stop.UTC().Format(xmlTimeFormat)

			b.WriteString(fmt.Sprintf(
				`  <programme start="%s" stop="%s" channel="pluto-%s">`+"\n",
				startStr, stopStr, escapeXML(tl.Channel.ID),
			))
			b.WriteString(fmt.Sprintf("    <title>%s</title>\n", escapeXML(prog.Title)))

			if prog.Description != "" {
				b.WriteString(fmt.Sprintf("    <desc>%s</desc>\n", escapeXML(prog.Description)))
			}

			if prog.Episode != nil {
				ep := prog.Episode
				if ep.Name != "" {
					b.WriteString(fmt.Sprintf("    <sub-title>%s</sub-title>\n", escapeXML(ep.Name)))
				}
				if ep.Poster != "" {
					b.WriteString(fmt.Sprintf(`    <icon src="%s" />`+"\n", escapeXML(ep.Poster)))
				} else if ep.Thumbnail != "" {
					b.WriteString(fmt.Sprintf(`    <icon src="%s" />`+"\n", escapeXML(ep.Thumbnail)))
				}
				if ep.Genre != "" {
					b.WriteString(fmt.Sprintf("    <category>%s</category>\n", escapeXML(ep.Genre)))
				}
				if ep.Rating != "" {
					b.WriteString(fmt.Sprintf("    <rating><value>%s</value></rating>\n", escapeXML(ep.Rating)))
				}
				if ep.Series != nil {
					b.WriteString(fmt.Sprintf("    <series-id>%s</series-id>\n", escapeXML(ep.Series.ID)))
				}
			}

			b.WriteString("  </programme>\n")
		}
	}

	b.WriteString("</tv>\n")
	return b.String(), nil
}

// escapeM3UField removes characters that would break M3U parsing.
func escapeM3UField(s string) string {
	s = strings.ReplaceAll(s, "\"", "'")
	s = strings.ReplaceAll(s, "\n", " ")
	s = strings.ReplaceAll(s, "\r", "")
	return s
}

// escapeXML performs basic XML entity escaping.
func escapeXML(s string) string {
	s = strings.ReplaceAll(s, "&", "&amp;")
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	s = strings.ReplaceAll(s, "\"", "&quot;")
	s = strings.ReplaceAll(s, "'", "&apos;")
	return s
}
