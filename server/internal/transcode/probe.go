package transcode

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
)

// StreamInfo represents a single stream from ffprobe output
type StreamInfo struct {
	Index     int    `json:"index"`
	CodecName string `json:"codec_name"`
	CodecType string `json:"codec_type"` // video, audio, subtitle
	Language  string `json:"language,omitempty"`
	Title     string `json:"title,omitempty"`
	Channels  int    `json:"channels,omitempty"`
	Default   bool   `json:"default"`
	Forced    bool   `json:"forced"`
	BitRate   string `json:"bit_rate,omitempty"`
	Width     int    `json:"width,omitempty"`
	Height    int    `json:"height,omitempty"`
}

// ProbeResult holds the parsed output of ffprobe
type ProbeResult struct {
	Streams []StreamInfo  `json:"streams"`
	Format  ProbeFormat   `json:"format"`
}

// ProbeFormat holds container-level format information
type ProbeFormat struct {
	Filename       string `json:"filename"`
	FormatName     string `json:"format_name"`
	FormatLongName string `json:"format_long_name"`
	Duration       string `json:"duration"`
	Size           string `json:"size"`
	BitRate        string `json:"bit_rate"`
}

// SubtitleMode controls subtitle auto-selection behaviour
type SubtitleMode int

const (
	SubtitleModeOff     SubtitleMode = 0 // No auto-select
	SubtitleModeAuto    SubtitleMode = 1 // Auto-select matching language
	SubtitleModeForced  SubtitleMode = 2 // Only forced subtitles
	SubtitleModeAlways  SubtitleMode = 3 // Always show matching
)

// ffprobeStream is the raw JSON structure from ffprobe
type ffprobeStream struct {
	Index         int               `json:"index"`
	CodecName     string            `json:"codec_name"`
	CodecType     string            `json:"codec_type"`
	Width         int               `json:"width,omitempty"`
	Height        int               `json:"height,omitempty"`
	Channels      int               `json:"channels,omitempty"`
	BitRate       string            `json:"bit_rate,omitempty"`
	Tags          map[string]string `json:"tags,omitempty"`
	Disposition   ffprobeDisp       `json:"disposition,omitempty"`
}

type ffprobeDisp struct {
	Default int `json:"default"`
	Forced  int `json:"forced"`
}

type ffprobeOutput struct {
	Streams []ffprobeStream `json:"streams"`
	Format  ProbeFormat     `json:"format"`
}

// FFprobePath derives the ffprobe binary path from an ffmpeg path.
// If ffmpegPath contains "ffmpeg", it replaces the last occurrence with "ffprobe".
// Otherwise it returns "ffprobe" and lets the system PATH resolve it.
func FFprobePath(ffmpegPath string) string {
	if ffmpegPath == "" {
		return "ffprobe"
	}

	dir := filepath.Dir(ffmpegPath)
	base := filepath.Base(ffmpegPath)

	// Replace "ffmpeg" in the binary name with "ffprobe"
	if idx := strings.LastIndex(base, "ffmpeg"); idx >= 0 {
		probe := base[:idx] + "ffprobe" + base[idx+len("ffmpeg"):]
		if dir == "." {
			return probe
		}
		return filepath.Join(dir, probe)
	}

	// Fallback: try plain "ffprobe"
	return "ffprobe"
}

// ProbeFile runs ffprobe on the given file and returns parsed stream/format info.
func ProbeFile(ffprobePath, filePath string) (*ProbeResult, error) {
	if ffprobePath == "" {
		ffprobePath = "ffprobe"
	}

	args := []string{
		"-v", "quiet",
		"-print_format", "json",
		"-show_streams",
		"-show_format",
		filePath,
	}

	cmd := exec.Command(ffprobePath, args...)
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("ffprobe failed for %s: %w", filePath, err)
	}

	var raw ffprobeOutput
	if err := json.Unmarshal(output, &raw); err != nil {
		return nil, fmt.Errorf("failed to parse ffprobe output: %w", err)
	}

	result := &ProbeResult{
		Format: raw.Format,
	}

	for _, s := range raw.Streams {
		si := StreamInfo{
			Index:     s.Index,
			CodecName: s.CodecName,
			CodecType: s.CodecType,
			Channels:  s.Channels,
			BitRate:   s.BitRate,
			Width:     s.Width,
			Height:    s.Height,
			Default:   s.Disposition.Default == 1,
			Forced:    s.Disposition.Forced == 1,
		}
		if s.Tags != nil {
			si.Language = s.Tags["language"]
			si.Title = s.Tags["title"]
		}
		result.Streams = append(result.Streams, si)
	}

	return result, nil
}

// FilterStreamsByType returns streams matching the given codec type (video, audio, subtitle).
func FilterStreamsByType(streams []StreamInfo, codecType string) []StreamInfo {
	var out []StreamInfo
	for _, s := range streams {
		if s.CodecType == codecType {
			out = append(out, s)
		}
	}
	return out
}

// FindBestAudioTrack selects the best audio track based on preferred language.
// Preference order:
//  1. Default track matching preferred language
//  2. Any track matching preferred language (prefer highest channel count)
//  3. Default track of any language
//  4. First audio track
func FindBestAudioTrack(streams []StreamInfo, preferredLang string) *StreamInfo {
	audioStreams := FilterStreamsByType(streams, "audio")
	if len(audioStreams) == 0 {
		return nil
	}

	lang := strings.ToLower(strings.TrimSpace(preferredLang))

	// Pass 1: default track in preferred language
	if lang != "" {
		for i := range audioStreams {
			if audioStreams[i].Default && matchesLanguage(audioStreams[i].Language, lang) {
				return &audioStreams[i]
			}
		}
	}

	// Pass 2: any track in preferred language, prefer highest channel count
	if lang != "" {
		var best *StreamInfo
		for i := range audioStreams {
			if matchesLanguage(audioStreams[i].Language, lang) {
				if best == nil || audioStreams[i].Channels > best.Channels {
					best = &audioStreams[i]
				}
			}
		}
		if best != nil {
			return best
		}
	}

	// Pass 3: default track of any language
	for i := range audioStreams {
		if audioStreams[i].Default {
			return &audioStreams[i]
		}
	}

	// Pass 4: first audio track
	return &audioStreams[0]
}

// FindBestSubtitleTrack selects the best subtitle track based on language and mode.
// mode values:
//
//	0 (Off)    - return nil
//	1 (Auto)   - prefer matching language, skip forced-only
//	2 (Forced) - only forced subtitles in preferred language
//	3 (Always) - always select matching language subtitle
func FindBestSubtitleTrack(streams []StreamInfo, preferredLang string, mode SubtitleMode) *StreamInfo {
	if mode == SubtitleModeOff {
		return nil
	}

	subStreams := FilterStreamsByType(streams, "subtitle")
	if len(subStreams) == 0 {
		return nil
	}

	lang := strings.ToLower(strings.TrimSpace(preferredLang))

	switch mode {
	case SubtitleModeForced:
		// Only return forced subtitle in preferred language
		if lang != "" {
			for i := range subStreams {
				if subStreams[i].Forced && matchesLanguage(subStreams[i].Language, lang) {
					return &subStreams[i]
				}
			}
		}
		// Fallback: any forced subtitle
		for i := range subStreams {
			if subStreams[i].Forced {
				return &subStreams[i]
			}
		}
		return nil

	case SubtitleModeAuto:
		// Prefer non-forced matching language subtitle
		if lang != "" {
			for i := range subStreams {
				if matchesLanguage(subStreams[i].Language, lang) && !subStreams[i].Forced {
					return &subStreams[i]
				}
			}
			// Fallback to forced if nothing else matches
			for i := range subStreams {
				if matchesLanguage(subStreams[i].Language, lang) && subStreams[i].Forced {
					return &subStreams[i]
				}
			}
		}
		// If no language preference, return default subtitle
		for i := range subStreams {
			if subStreams[i].Default {
				return &subStreams[i]
			}
		}
		return nil

	case SubtitleModeAlways:
		// Always select matching language
		if lang != "" {
			for i := range subStreams {
				if matchesLanguage(subStreams[i].Language, lang) && !subStreams[i].Forced {
					return &subStreams[i]
				}
			}
			for i := range subStreams {
				if matchesLanguage(subStreams[i].Language, lang) {
					return &subStreams[i]
				}
			}
		}
		// Fallback: default or first subtitle
		for i := range subStreams {
			if subStreams[i].Default {
				return &subStreams[i]
			}
		}
		if len(subStreams) > 0 {
			return &subStreams[0]
		}
		return nil
	}

	return nil
}

// matchesLanguage checks if a stream language matches the preferred language code.
// It handles ISO 639-1 (2-letter) and ISO 639-2 (3-letter) comparisons loosely.
func matchesLanguage(streamLang, preferredLang string) bool {
	if streamLang == "" || preferredLang == "" {
		return false
	}
	sl := strings.ToLower(strings.TrimSpace(streamLang))
	pl := strings.ToLower(strings.TrimSpace(preferredLang))

	if sl == pl {
		return true
	}

	// Common 2-letter to 3-letter mappings
	langMap := map[string][]string{
		"en":  {"eng", "en"},
		"eng": {"en", "eng"},
		"es":  {"spa", "es"},
		"spa": {"es", "spa"},
		"fr":  {"fre", "fra", "fr"},
		"fre": {"fr", "fra", "fre"},
		"fra": {"fr", "fre", "fra"},
		"de":  {"ger", "deu", "de"},
		"ger": {"de", "deu", "ger"},
		"deu": {"de", "ger", "deu"},
		"it":  {"ita", "it"},
		"ita": {"it", "ita"},
		"pt":  {"por", "pt"},
		"por": {"pt", "por"},
		"ru":  {"rus", "ru"},
		"rus": {"ru", "rus"},
		"ja":  {"jpn", "ja"},
		"jpn": {"ja", "jpn"},
		"ko":  {"kor", "ko"},
		"kor": {"ko", "kor"},
		"zh":  {"chi", "zho", "zh"},
		"chi": {"zh", "zho", "chi"},
		"zho": {"zh", "chi", "zho"},
		"ar":  {"ara", "ar"},
		"ara": {"ar", "ara"},
		"hi":  {"hin", "hi"},
		"hin": {"hi", "hin"},
		"nl":  {"dut", "nld", "nl"},
		"dut": {"nl", "nld", "dut"},
		"nld": {"nl", "dut", "nld"},
		"pl":  {"pol", "pl"},
		"pol": {"pl", "pol"},
		"sv":  {"swe", "sv"},
		"swe": {"sv", "swe"},
		"da":  {"dan", "da"},
		"dan": {"da", "dan"},
		"no":  {"nor", "nob", "nno", "no"},
		"nor": {"no", "nob", "nno", "nor"},
		"fi":  {"fin", "fi"},
		"fin": {"fi", "fin"},
		"tr":  {"tur", "tr"},
		"tur": {"tr", "tur"},
		"el":  {"gre", "ell", "el"},
		"gre": {"el", "ell", "gre"},
		"ell": {"el", "gre", "ell"},
		"he":  {"heb", "he"},
		"heb": {"he", "heb"},
		"th":  {"tha", "th"},
		"tha": {"th", "tha"},
		"vi":  {"vie", "vi"},
		"vie": {"vi", "vie"},
		"uk":  {"ukr", "uk"},
		"ukr": {"uk", "ukr"},
		"cs":  {"cze", "ces", "cs"},
		"cze": {"cs", "ces", "cze"},
		"ces": {"cs", "cze", "ces"},
		"ro":  {"rum", "ron", "ro"},
		"rum": {"ro", "ron", "rum"},
		"ron": {"ro", "rum", "ron"},
		"hu":  {"hun", "hu"},
		"hun": {"hu", "hun"},
	}

	if equivalents, ok := langMap[pl]; ok {
		for _, eq := range equivalents {
			if sl == eq {
				return true
			}
		}
	}

	// Prefix match: "en" matches "eng", etc.
	if strings.HasPrefix(sl, pl) || strings.HasPrefix(pl, sl) {
		return true
	}

	return false
}
