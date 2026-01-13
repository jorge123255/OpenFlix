package livetv

import (
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/openflix/openflix-server/internal/models"
)

// networkAliases maps network identifiers to their common name variations
// Used for matching channel names to EPG callsigns
var networkAliases = map[string][]string{
	// Major broadcast networks
	"NBC":       {"NBC", "NATIONAL BROADCASTING", "WNBC", "KNBC"},
	"CBS":       {"CBS", "COLUMBIA BROADCASTING", "WCBS", "KCBS", "CBSHD"},
	"ABC":       {"ABC", "AMERICAN BROADCASTING", "WABC", "KABC"},
	"FOX":       {"FOX", "KTTV", "WNYW", "FOXHD"},
	"PBS":       {"PBS", "PUBLIC BROADCASTING", "WNET", "KCET", "WTTW"},
	"CW":        {"CW", "THE CW", "CWNETWORK", "CWHD"},

	// Sports networks
	"ESPN":        {"ESPN", "ESPNHD"},
	"ESPN2":       {"ESPN2", "ESPN 2", "ESPN2HD"},
	"ESPNU":       {"ESPNU", "ESPNUHD"},
	"ESPNEWS":     {"ESPNEWS", "ESPN NEWS"},
	"FOXSPORTS1":  {"FS1", "FOX SPORTS 1", "FOXSPORT1", "FS1HD"},
	"FOXSPORTS2":  {"FS2", "FOX SPORTS 2", "FOXSPORT2", "FS2HD"},
	"NBCSPORTS":   {"NBCSN", "NBC SPORTS", "NBCSPORT", "NBC SPORTS NETWORK"},
	"CBSSPORTS":   {"CBS SPORTS", "CBSSN", "CBSSPORTS", "CBS SPORTS NETWORK"},
	"MLBNETWORK":  {"MLB NETWORK", "MLBN", "MLBHD", "MLBNETWORK"},
	"NBANETWORK":  {"NBA TV", "NBATV", "NBAHD"},
	"NHLNETWORK":  {"NHL NETWORK", "NHLHD", "NHLNETWORK"},
	"GOLFCHANNEL": {"GOLF CHANNEL", "GOLF", "GOLFHD"},
	"TENNIS":      {"TENNIS CHANNEL", "TENNIS", "TENNISHD", "TENNISCHAN"},
	"BTN":         {"BIG TEN NETWORK", "BTN", "BIGTENNETW"},
	"SECNETWORK":  {"SEC NETWORK", "SECN", "SECHD", "SECNETWORK"},
	"ACCNETWORK":  {"ACC NETWORK", "ACCN", "ACCNETWORK"},
	"BEINSPORTS":  {"BEIN SPORTS", "BEINSPORTS", "BEIN"},

	// News networks
	"CNN":        {"CNN", "CABLE NEWS NETWORK", "CNNHD"},
	"MSNBC":      {"MSNBC", "MSNBCHD"},
	"FOXNEWS":    {"FOX NEWS", "FOXNEWS", "FNCHD", "FOX NEWS CHANNEL", "FOXNEWSCHA"},
	"CNBC":       {"CNBC", "CNBCHD"},
	"BLOOMBERG":  {"BLOOMBERG", "BLOOMBERGT", "BLOOMBERG TV"},
	"NEWSMAX":    {"NEWSMAX", "NEWSMAXHD"},
	"NEWSNATION": {"NEWSNATION", "NEWS NATION"},
	"CSPAN":      {"C-SPAN", "CSPAN"},
	"HLN":        {"HLN", "HEADLINE NEWS", "HLNHD"},

	// Entertainment networks
	"HBO":            {"HBO", "HOME BOX OFFICE", "HBOHD"},
	"SHOWTIME":       {"SHOWTIME", "SHO", "SHOWHD"},
	"STARZ":          {"STARZ", "STARZHD"},
	"CINEMAX":        {"CINEMAX", "MAX", "CINEMAXHD"},
	"AMC":            {"AMC", "AMCHD", "AMCSTR"},
	"FX":             {"FX", "FXHD"},
	"FXX":            {"FXX", "FXXHD"},
	"FXM":            {"FXM", "FX MOVIES", "FX MOVIE CHANNEL"},
	"TNT":            {"TNT", "TNTHD"},
	"TBS":            {"TBS", "TBSHD"},
	"USA":            {"USA", "USA NETWORK", "USAHD", "USAN"},
	"SYFY":           {"SYFY", "SCI-FI", "SCIFI", "SYFYHD"},
	"BRAVO":          {"BRAVO", "BRAVOHD", "BVO"},
	"E!":             {"E!", "EENTERTAIN", "EHD"},
	"OXYGEN":         {"OXYGEN", "OXG", "OXYGEN TRUE CRIME"},
	"TVLAND":         {"TV LAND", "TVLAND", "TVLNDHD"},
	"POP":            {"POP", "POP TV"},
	"PARAMOUNT":      {"PARAMOUNT NETWORK", "PARHD", "PARAMOUNTN"},
	"COMEDYCENTRAL":  {"COMEDY CENTRAL", "CC", "CCHD", "COMEDYCENT"},
	"MTV":            {"MTV", "MTVHD"},
	"MTV2":           {"MTV2", "MTV2HD"},
	"VH1":            {"VH1", "VH1HD"},
	"CMT":            {"CMT", "COUNTRY MUSIC", "CMTHD"},
	"BET":            {"BET", "BETHD"},
	"BETHER":         {"BET HER", "BETHER"},
	"LOGO":           {"LOGO", "LOGOHD"},
	"FREEFORM":       {"FREEFORM", "FREFMHD", "ABC FAMILY"},
	"IFC":            {"IFC", "IFCHD"},
	"SUNDANCE":       {"SUNDANCE", "SUNDANCETV"},
	"TCM":            {"TCM", "TURNER CLASSIC MOVIES"},
	"REELZ":          {"REELZ", "REELZCHANNEL"},

	// Kids networks
	"DISNEY":      {"DISNEY CHANNEL", "DISN", "DISNEYCHAN"},
	"DISNEYJR":    {"DISNEY JUNIOR", "DJCHHD", "DISNEYJUNI"},
	"DISNEYXD":    {"DISNEY XD", "DXDHD", "DISNEYXD"},
	"NICKELODEON": {"NICKELODEON", "NICK", "NIKHD", "NICKELODEO"},
	"NICKJR":      {"NICK JR", "NICK JR.", "NICKJR", "NICJRHD"},
	"NICKTOONS":   {"NICKTOONS", "NIKTON"},
	"TEENNICK":    {"TEENNICK", "TNCKHD"},
	"CARTOON":     {"CARTOON NETWORK", "CN", "CARTOONHD"},
	"BOOMERANG":   {"BOOMERANG", "BOOMHD"},

	// Lifestyle networks
	"HGTV":     {"HGTV", "HOME & GARDEN", "HGTVD", "HGTVHD"},
	"FOOD":     {"FOOD NETWORK", "FOOD", "FOODHD"},
	"COOKING":  {"COOKING CHANNEL", "COOKHD"},
	"TRAVEL":   {"TRAVEL CHANNEL", "TRAVEL", "TRAVHD"},
	"TLC":      {"TLC", "THE LEARNING CHANNEL", "TLCHD"},
	"OWN":      {"OWN", "OPRAH", "OWNHD"},
	"LIFETIME": {"LIFETIME", "LIF", "LIFEHD"},
	"LMN":      {"LMN", "LIFETIME MOVIE NETWORK"},
	"HALLMARK": {"HALLMARK CHANNEL", "HALL", "HALLHD", "HALLMARKCH"},
	"WETV":     {"WE TV", "WETV"},
	"MAGNOLIA": {"MAGNOLIA NETWORK", "MAGNHD", "DIY"},

	// Documentary networks
	"DISCOVERY":   {"DISCOVERY", "DISCOVERY CHANNEL", "DISC", "DSCHD"},
	"HISTORY":     {"HISTORY", "HIST", "HISTORYHD", "HISTORY CHANNEL"},
	"NATGEO":      {"NATIONAL GEOGRAPHIC", "NAT GEO", "NGCHD", "NATIONALGE"},
	"NATGEOWILD":  {"NAT GEO WILD", "NGWIHD", "NATIONAL GEOGRAPHIC WILD"},
	"ANIMAL":      {"ANIMAL PLANET", "APL", "APLHD"},
	"SCIENCE":     {"SCIENCE CHANNEL", "SCIENCE", "SCIHD"},
	"A&E":         {"A&E", "A AND E", "ARTS", "AEHD", "AESTR"},
	"ID":          {"INVESTIGATION DISCOVERY", "ID", "IDHD"},
	"DESTINATION": {"DESTINATION AMERICA", "DESTHD"},
	"SMITHSONIAN": {"SMITHSONIAN CHANNEL", "SMITH", "SMITHSONIA"},
	"FYI":         {"FYI", "FYIHD"},
}

// MatchResult represents a potential EPG match for a channel
type MatchResult struct {
	EPGChannelID  string  `json:"epgChannelId"`
	EPGCallSign   string  `json:"epgCallSign"`
	EPGName       string  `json:"epgName"`
	EPGNumber     string  `json:"epgNumber"`
	Confidence    float64 `json:"confidence"`
	MatchReason   string  `json:"matchReason"`
	MatchStrategy string  `json:"matchStrategy"`
}

// ChannelMatcher handles automatic EPG channel matching
type ChannelMatcher struct {
	epgChannels []EPGChannelInfo
}

// EPGChannelInfo represents an EPG channel for matching
type EPGChannelInfo struct {
	ChannelID     string
	CallSign      string
	Name          string
	Number        string
	AffiliateName string
}

// NewChannelMatcher creates a new channel matcher with EPG channel data
func NewChannelMatcher(epgChannels []EPGChannelInfo) *ChannelMatcher {
	return &ChannelMatcher{
		epgChannels: epgChannels,
	}
}

// FindMatches finds potential EPG matches for an M3U channel
func (m *ChannelMatcher) FindMatches(channel *models.Channel) []MatchResult {
	var results []MatchResult

	for _, epg := range m.epgChannels {
		result := m.scoreMatch(channel, epg)
		if result.Confidence > 0.3 { // Only include matches with >30% confidence
			results = append(results, result)
		}
	}

	// Sort by confidence descending
	sort.Slice(results, func(i, j int) bool {
		return results[i].Confidence > results[j].Confidence
	})

	// Return top 5 matches
	if len(results) > 5 {
		results = results[:5]
	}

	return results
}

// FindBestMatch returns the best match if confidence is high enough
func (m *ChannelMatcher) FindBestMatch(channel *models.Channel, minConfidence float64) *MatchResult {
	matches := m.FindMatches(channel)
	if len(matches) == 0 {
		return nil
	}
	if matches[0].Confidence >= minConfidence {
		return &matches[0]
	}
	return nil
}

// scoreMatch calculates a match score between an M3U channel and an EPG channel
func (m *ChannelMatcher) scoreMatch(channel *models.Channel, epg EPGChannelInfo) MatchResult {
	result := MatchResult{
		EPGChannelID: epg.ChannelID,
		EPGCallSign:  epg.CallSign,
		EPGName:      epg.Name,
		EPGNumber:    epg.Number,
		Confidence:   0,
	}

	var scores []struct {
		score    float64
		reason   string
		strategy string
	}

	// Strategy 0: FuboTV provider mapping (highest priority)
	// Check if channel ID matches a known FuboTV channel and maps to this EPG station
	if channel.ChannelID != "" {
		if mapping, ok := LookupFuboTVMapping(channel.ChannelID); ok && mapping.StationID != "" {
			// Check if this EPG channel's ID matches the Gracenote station ID
			if epg.ChannelID == mapping.StationID ||
				strings.HasSuffix(epg.ChannelID, "-"+mapping.StationID) ||
				strings.HasPrefix(epg.ChannelID, mapping.StationID+"-") {
				scores = append(scores, struct {
					score    float64
					reason   string
					strategy string
				}{1.0, "FuboTV mapping: " + mapping.Name, "provider_mapping"})
			}
		}
	}

	// Strategy 1: Exact TVG-ID match (highest confidence)
	if channel.ChannelID != "" && channel.ChannelID == epg.ChannelID {
		scores = append(scores, struct {
			score    float64
			reason   string
			strategy string
		}{1.0, "Exact EPG ID match", "tvg_id"})
	}

	// Strategy 2: Channel number match
	if epg.Number != "" {
		channelNum := extractChannelNumber(channel.Name)
		if channelNum != "" && channelNum == epg.Number {
			scores = append(scores, struct {
				score    float64
				reason   string
				strategy string
			}{0.9, "Channel number match: " + channelNum, "channel_number"})
		}
		// Also check if M3U channel number field matches
		if channel.Number > 0 && strconv.Itoa(channel.Number) == epg.Number {
			scores = append(scores, struct {
				score    float64
				reason   string
				strategy string
			}{0.85, "M3U channel number match", "m3u_number"})
		}
	}

	// Strategy 3: Call sign match
	if epg.CallSign != "" {
		callSignScore := matchCallSign(channel.Name, epg.CallSign)
		if callSignScore > 0.5 {
			scores = append(scores, struct {
				score    float64
				reason   string
				strategy string
			}{callSignScore, "Call sign match: " + epg.CallSign, "call_sign"})
		}
	}

	// Strategy 4: Network/affiliate name match
	if epg.AffiliateName != "" {
		networkScore := matchNetwork(channel.Name, channel.Group, epg.AffiliateName)
		if networkScore > 0.5 {
			scores = append(scores, struct {
				score    float64
				reason   string
				strategy string
			}{networkScore, "Network match: " + epg.AffiliateName, "network"})
		}
	}

	// Strategy 5: Fuzzy name matching
	nameScore := fuzzyNameMatch(channel.Name, epg.Name, epg.CallSign)
	if nameScore > 0.5 {
		scores = append(scores, struct {
			score    float64
			reason   string
			strategy string
		}{nameScore, "Name similarity match", "fuzzy_name"})
	}

	// Take the best score
	if len(scores) > 0 {
		best := scores[0]
		for _, s := range scores[1:] {
			if s.score > best.score {
				best = s
			}
		}
		result.Confidence = best.score
		result.MatchReason = best.reason
		result.MatchStrategy = best.strategy
	}

	return result
}

// extractChannelNumber extracts a channel number from a channel name
// Examples: "NBC 5", "Channel 7", "CBS 2 HD" -> "5", "7", "2"
func extractChannelNumber(name string) string {
	name = strings.ToUpper(name)

	// Pattern 1: "Network Number" (e.g., "NBC 5", "CBS 2")
	networkPattern := regexp.MustCompile(`\b(NBC|CBS|ABC|FOX|PBS|CW|WB)\s*(\d+)`)
	if matches := networkPattern.FindStringSubmatch(name); len(matches) > 2 {
		return matches[2]
	}

	// Pattern 2: "Channel N" or "Ch N"
	channelPattern := regexp.MustCompile(`\b(?:CHANNEL|CH\.?)\s*(\d+)`)
	if matches := channelPattern.FindStringSubmatch(name); len(matches) > 1 {
		return matches[1]
	}

	// Pattern 3: Leading number with separator (e.g., "5 NBC", "7 - ABC")
	leadingPattern := regexp.MustCompile(`^(\d+)\s*[-\s]\s*\w`)
	if matches := leadingPattern.FindStringSubmatch(name); len(matches) > 1 {
		return matches[1]
	}

	// Pattern 4: Number at end after network (e.g., "WMAQ-TV 5")
	trailingPattern := regexp.MustCompile(`\b(\d+)\s*$`)
	if matches := trailingPattern.FindStringSubmatch(strings.TrimSuffix(strings.TrimSuffix(name, "HD"), " ")); len(matches) > 1 {
		return matches[1]
	}

	return ""
}

// matchCallSign checks if a call sign appears in the channel name
func matchCallSign(channelName, callSign string) float64 {
	channelName = strings.ToUpper(channelName)
	callSign = strings.ToUpper(callSign)

	// Exact match
	if strings.Contains(channelName, callSign) {
		return 0.95
	}

	// Match without -TV suffix (e.g., "WMAQ" matches "WMAQ-TV")
	callSignBase := strings.TrimSuffix(callSign, "-TV")
	callSignBase = strings.TrimSuffix(callSignBase, "TV")
	if callSignBase != callSign && strings.Contains(channelName, callSignBase) {
		return 0.9
	}

	// Match first 3-4 letters of call sign
	if len(callSign) >= 4 {
		prefix := callSign[:4]
		if strings.Contains(channelName, prefix) {
			return 0.75
		}
	}

	// Check if callSign is in network aliases and channel name contains any alias
	// This handles cases like "COMEDYCENT" matching "Comedy Central HD"
	for _, aliases := range networkAliases {
		callSignInAliases := false
		for _, alias := range aliases {
			if alias == callSign || strings.Contains(callSign, alias) || strings.Contains(alias, callSign) {
				callSignInAliases = true
				break
			}
		}
		if callSignInAliases {
			// Check if channel name contains any alias from this network
			for _, alias := range aliases {
				if strings.Contains(channelName, alias) {
					return 0.85
				}
			}
		}
	}

	return 0
}

// matchNetwork checks if a network name appears in the channel name or group
func matchNetwork(channelName, group, networkName string) float64 {
	channelName = strings.ToUpper(channelName)
	group = strings.ToUpper(group)
	networkName = strings.ToUpper(networkName)

	// Normalize network name
	networkNorm := strings.ReplaceAll(networkName, " ", "")
	networkNorm = strings.ReplaceAll(networkNorm, "-", "")

	// Check for network in channel name
	checkIn := func(text string) float64 {
		if strings.Contains(text, networkName) {
			return 0.85
		}
		if strings.Contains(text, networkNorm) {
			return 0.8
		}
		// Check aliases
		for key, aliases := range networkAliases {
			if strings.Contains(networkName, key) {
				for _, alias := range aliases {
					if strings.Contains(text, alias) {
						return 0.75
					}
				}
			}
		}
		return 0
	}

	// Check channel name first, then group
	if score := checkIn(channelName); score > 0 {
		return score
	}
	if score := checkIn(group); score > 0 {
		return score * 0.9 // Slightly lower confidence for group match
	}

	return 0
}

// fuzzyNameMatch performs fuzzy matching between channel names
func fuzzyNameMatch(m3uName, epgName, epgCallSign string) float64 {
	m3uName = normalizeChannelName(m3uName)
	epgName = normalizeChannelName(epgName)

	if m3uName == "" || epgName == "" {
		return 0
	}

	// Check if one contains the other
	if strings.Contains(m3uName, epgName) || strings.Contains(epgName, m3uName) {
		return 0.8
	}

	// Calculate word overlap
	m3uWords := strings.Fields(m3uName)
	epgWords := strings.Fields(epgName)

	if len(m3uWords) == 0 || len(epgWords) == 0 {
		return 0
	}

	matches := 0
	for _, m3uWord := range m3uWords {
		for _, epgWord := range epgWords {
			if m3uWord == epgWord && len(m3uWord) > 2 {
				matches++
				break
			}
		}
	}

	// Also check if call sign words match
	if epgCallSign != "" {
		callSignNorm := normalizeChannelName(epgCallSign)
		for _, m3uWord := range m3uWords {
			if strings.Contains(callSignNorm, m3uWord) && len(m3uWord) > 2 {
				matches++
				break
			}
		}
	}

	if matches == 0 {
		return 0
	}

	// Score based on percentage of matching words
	totalWords := max(len(m3uWords), len(epgWords))
	return float64(matches) / float64(totalWords) * 0.7
}

// normalizeChannelName normalizes a channel name for comparison
func normalizeChannelName(name string) string {
	name = strings.ToUpper(name)

	// Remove common suffixes
	suffixes := []string{" HD", " SD", " FHD", " UHD", " 4K", " (HD)", " (SD)", "-HD", "-SD"}
	for _, suffix := range suffixes {
		name = strings.TrimSuffix(name, suffix)
	}

	// Remove special characters
	name = regexp.MustCompile(`[^A-Z0-9\s]`).ReplaceAllString(name, " ")

	// Normalize whitespace
	name = regexp.MustCompile(`\s+`).ReplaceAllString(name, " ")
	name = strings.TrimSpace(name)

	return name
}

// AutoDetectResult contains results from auto-detection
type AutoDetectResult struct {
	ChannelID      uint          `json:"channelId"`
	ChannelName    string        `json:"channelName"`
	CurrentMapping string        `json:"currentMapping,omitempty"`
	BestMatch      *MatchResult  `json:"bestMatch,omitempty"`
	AllMatches     []MatchResult `json:"allMatches,omitempty"`
	AutoMapped     bool          `json:"autoMapped"`
}

// AutoDetectSummary contains summary statistics from auto-detection
type AutoDetectSummary struct {
	TotalChannels   int `json:"totalChannels"`
	AlreadyMapped   int `json:"alreadyMapped"`
	NewMappings     int `json:"newMappings"`
	NoMatchFound    int `json:"noMatchFound"`
	LowConfidence   int `json:"lowConfidence"`
	HighConfidence  int `json:"highConfidence"`
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// FindProviderMapping looks up a direct provider mapping for a channel
// Returns the Gracenote station ID and mapping info if found
func FindProviderMapping(channelID string, channelName string) (*ProviderMapping, bool) {
	// Try direct FuboTV channel ID lookup first
	if channelID != "" {
		if mapping, ok := LookupFuboTVMapping(channelID); ok && mapping.StationID != "" {
			return mapping, true
		}
	}

	// Try looking up by call sign extracted from channel name
	// Common patterns: "ESPN HD", "FOXNEWS", "NBC 5"
	nameUpper := strings.ToUpper(channelName)
	// Remove common suffixes
	nameUpper = strings.TrimSuffix(nameUpper, " HD")
	nameUpper = strings.TrimSuffix(nameUpper, " SD")
	nameUpper = strings.TrimSuffix(nameUpper, " FHD")

	if mapping, _, ok := LookupByCallSign(nameUpper); ok && mapping.StationID != "" {
		return mapping, true
	}

	// Try name matching
	if mapping, _, ok := LookupByName(channelName); ok && mapping.StationID != "" {
		return mapping, true
	}

	return nil, false
}

// GetProviderMappingStats returns statistics about provider mappings
func GetProviderMappingStats() map[string]int {
	return map[string]int{
		"fubotvChannels": len(FuboTVMappings),
	}
}
