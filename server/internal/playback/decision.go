package playback

import (
	"strings"
)

// PlaybackMode represents the type of playback
type PlaybackMode string

const (
	ModeDirectPlay   PlaybackMode = "direct_play"
	ModeDirectStream PlaybackMode = "direct_stream"
	ModeTranscode    PlaybackMode = "transcode"
)

// ClientCapabilities represents what a client device can play
type ClientCapabilities struct {
	// Device info
	DeviceID   string `json:"deviceId"`
	DeviceName string `json:"deviceName"`
	Platform   string `json:"platform"` // android, ios, web, tv, desktop

	// Video codec support
	VideoCodecs []string `json:"videoCodecs"` // h264, hevc, vp9, av1
	VideoProfiles map[string][]string `json:"videoProfiles"` // codec -> profiles (main, high, etc)
	MaxResolution string `json:"maxResolution"` // 4k, 1080p, 720p

	// Audio codec support
	AudioCodecs []string `json:"audioCodecs"` // aac, ac3, eac3, dts, truehd

	// Container support
	Containers []string `json:"containers"` // mp4, mkv, webm, hls

	// Subtitle support
	SubtitleFormats []string `json:"subtitleFormats"` // srt, ass, vtt, pgs

	// Network/bandwidth
	MaxBitrate int `json:"maxBitrate"` // kbps, 0 = unlimited

	// Feature flags
	SupportsHDR       bool `json:"supportsHdr"`
	SupportsAtmos     bool `json:"supportsAtmos"`
	SupportsDolbyVision bool `json:"supportsDolbyVision"`
}

// MediaInfo represents the source file info for playback decisions
type MediaInfo struct {
	Container     string
	VideoCodec    string
	VideoProfile  string
	AudioCodec    string
	Width         int
	Height        int
	Bitrate       int // kbps
	HasHDR        bool
	HasDolbyVision bool
	HasAtmos      bool
	SubtitleCodec string // embedded subtitle format
}

// PlaybackDecision contains the decision and reasoning
type PlaybackDecision struct {
	Mode            PlaybackMode `json:"mode"`
	Reason          string       `json:"reason"`
	TranscodeReason string       `json:"transcodeReason,omitempty"`

	// What needs to change for each mode
	VideoDecision   string `json:"videoDecision"`   // copy, transcode
	AudioDecision   string `json:"audioDecision"`   // copy, transcode
	ContainerChange bool   `json:"containerChange"` // need to remux

	// Recommended settings for transcode
	SuggestedCodec      string `json:"suggestedCodec,omitempty"`
	SuggestedResolution string `json:"suggestedResolution,omitempty"`
	SuggestedBitrate    int    `json:"suggestedBitrate,omitempty"`
}

// DefaultClientCapabilities returns sensible defaults for common platforms
func DefaultClientCapabilities(platform string) *ClientCapabilities {
	switch strings.ToLower(platform) {
	case "android", "android_tv":
		return &ClientCapabilities{
			Platform:      platform,
			VideoCodecs:   []string{"h264", "hevc", "vp9"},
			VideoProfiles: map[string][]string{
				"h264": {"baseline", "main", "high"},
				"hevc": {"main", "main10"},
			},
			MaxResolution: "4k",
			AudioCodecs:   []string{"aac", "ac3", "eac3", "mp3", "flac", "opus"},
			Containers:    []string{"mp4", "mkv", "webm", "hls"},
			SubtitleFormats: []string{"srt", "ass", "vtt"},
			SupportsHDR:   true,
		}
	case "ios", "tvos", "macos":
		return &ClientCapabilities{
			Platform:      platform,
			VideoCodecs:   []string{"h264", "hevc"},
			VideoProfiles: map[string][]string{
				"h264": {"baseline", "main", "high"},
				"hevc": {"main", "main10"},
			},
			MaxResolution: "4k",
			AudioCodecs:   []string{"aac", "ac3", "eac3", "mp3", "flac"},
			Containers:    []string{"mp4", "mov", "hls"},
			SubtitleFormats: []string{"srt", "vtt"},
			SupportsHDR:   true,
			SupportsDolbyVision: true,
		}
	case "web", "browser":
		return &ClientCapabilities{
			Platform:      platform,
			VideoCodecs:   []string{"h264", "vp9"},
			VideoProfiles: map[string][]string{
				"h264": {"baseline", "main", "high"},
			},
			MaxResolution: "1080p",
			AudioCodecs:   []string{"aac", "mp3", "opus"},
			Containers:    []string{"mp4", "webm", "hls"},
			SubtitleFormats: []string{"vtt"},
		}
	case "roku":
		return &ClientCapabilities{
			Platform:      platform,
			VideoCodecs:   []string{"h264", "hevc"},
			VideoProfiles: map[string][]string{
				"h264": {"main", "high"},
				"hevc": {"main", "main10"},
			},
			MaxResolution: "4k",
			AudioCodecs:   []string{"aac", "ac3", "eac3"},
			Containers:    []string{"mp4", "mkv", "hls"},
			SubtitleFormats: []string{"srt", "vtt"},
			SupportsHDR:   true,
		}
	case "fire_tv":
		return &ClientCapabilities{
			Platform:      platform,
			VideoCodecs:   []string{"h264", "hevc", "vp9", "av1"},
			VideoProfiles: map[string][]string{
				"h264": {"baseline", "main", "high"},
				"hevc": {"main", "main10"},
			},
			MaxResolution: "4k",
			AudioCodecs:   []string{"aac", "ac3", "eac3", "dts"},
			Containers:    []string{"mp4", "mkv", "webm", "hls"},
			SubtitleFormats: []string{"srt", "ass", "vtt"},
			SupportsHDR:   true,
			SupportsAtmos: true,
		}
	default:
		// Conservative defaults - assume basic H.264 support
		return &ClientCapabilities{
			Platform:      platform,
			VideoCodecs:   []string{"h264"},
			VideoProfiles: map[string][]string{
				"h264": {"baseline", "main", "high"},
			},
			MaxResolution: "1080p",
			AudioCodecs:   []string{"aac", "mp3"},
			Containers:    []string{"mp4", "hls"},
			SubtitleFormats: []string{"srt", "vtt"},
		}
	}
}

// DecidePlayback analyzes the source file against client capabilities
// and returns the best playback mode
func DecidePlayback(media *MediaInfo, client *ClientCapabilities) *PlaybackDecision {
	decision := &PlaybackDecision{
		Mode:          ModeDirectPlay,
		VideoDecision: "copy",
		AudioDecision: "copy",
	}

	// Check video codec compatibility
	videoNeedsTranscode := !containsIgnoreCase(client.VideoCodecs, media.VideoCodec)

	// Check video profile compatibility
	if !videoNeedsTranscode && media.VideoProfile != "" {
		profiles, hasProfiles := client.VideoProfiles[strings.ToLower(media.VideoCodec)]
		if hasProfiles && !containsIgnoreCase(profiles, media.VideoProfile) {
			videoNeedsTranscode = true
		}
	}

	// Check resolution
	maxWidth, maxHeight := parseResolution(client.MaxResolution)
	resolutionTooHigh := media.Width > maxWidth || media.Height > maxHeight

	// Check bitrate
	bitrateTooHigh := client.MaxBitrate > 0 && media.Bitrate > client.MaxBitrate

	// Check audio codec compatibility
	audioNeedsTranscode := !containsIgnoreCase(client.AudioCodecs, media.AudioCodec)

	// Check container compatibility
	containerSupported := containsIgnoreCase(client.Containers, media.Container)

	// Check HDR compatibility
	hdrIncompatible := media.HasHDR && !client.SupportsHDR
	dvIncompatible := media.HasDolbyVision && !client.SupportsDolbyVision

	// Make decision based on compatibility checks
	if videoNeedsTranscode || resolutionTooHigh || bitrateTooHigh || hdrIncompatible || dvIncompatible {
		decision.Mode = ModeTranscode
		decision.VideoDecision = "transcode"
		decision.Reason = "Video requires transcoding"

		// Build transcode reason
		reasons := []string{}
		if videoNeedsTranscode {
			reasons = append(reasons, "unsupported video codec ("+media.VideoCodec+")")
		}
		if resolutionTooHigh {
			reasons = append(reasons, "resolution too high")
		}
		if bitrateTooHigh {
			reasons = append(reasons, "bitrate too high")
		}
		if hdrIncompatible {
			reasons = append(reasons, "HDR not supported")
		}
		if dvIncompatible {
			reasons = append(reasons, "Dolby Vision not supported")
		}
		decision.TranscodeReason = strings.Join(reasons, ", ")

		// Suggest transcode settings
		decision.SuggestedCodec = suggestVideoCodec(client)
		decision.SuggestedResolution = suggestResolution(media, client)
		decision.SuggestedBitrate = suggestBitrate(media, client, decision.SuggestedResolution)

	} else if audioNeedsTranscode {
		// Video is OK but audio needs transcode
		decision.Mode = ModeTranscode
		decision.AudioDecision = "transcode"
		decision.Reason = "Audio requires transcoding"
		decision.TranscodeReason = "unsupported audio codec (" + media.AudioCodec + ")"

	} else if !containerSupported {
		// Both video and audio are OK but container needs remux
		decision.Mode = ModeDirectStream
		decision.ContainerChange = true
		decision.Reason = "Container remux required"

	} else {
		// Everything is compatible - direct play!
		decision.Mode = ModeDirectPlay
		decision.Reason = "All codecs and container supported"
	}

	return decision
}

// Helper functions

func containsIgnoreCase(slice []string, item string) bool {
	itemLower := strings.ToLower(item)
	for _, s := range slice {
		if strings.ToLower(s) == itemLower {
			return true
		}
	}
	return false
}

func parseResolution(res string) (width, height int) {
	switch strings.ToLower(res) {
	case "8k", "8192x4320":
		return 8192, 4320
	case "4k", "uhd", "2160p", "3840x2160":
		return 3840, 2160
	case "1440p", "2560x1440":
		return 2560, 1440
	case "1080p", "fhd", "1920x1080":
		return 1920, 1080
	case "720p", "hd", "1280x720":
		return 1280, 720
	case "480p", "sd", "854x480":
		return 854, 480
	case "360p", "640x360":
		return 640, 360
	default:
		return 1920, 1080 // Default to 1080p
	}
}

func suggestVideoCodec(client *ClientCapabilities) string {
	// Prefer H.264 for maximum compatibility
	if containsIgnoreCase(client.VideoCodecs, "h264") {
		return "h264"
	}
	// Then HEVC
	if containsIgnoreCase(client.VideoCodecs, "hevc") {
		return "hevc"
	}
	// Fallback
	if len(client.VideoCodecs) > 0 {
		return client.VideoCodecs[0]
	}
	return "h264"
}

func suggestResolution(media *MediaInfo, client *ClientCapabilities) string {
	maxWidth, maxHeight := parseResolution(client.MaxResolution)

	// If source is smaller than max, use source resolution
	if media.Width <= maxWidth && media.Height <= maxHeight {
		if media.Height >= 2160 {
			return "4k"
		} else if media.Height >= 1080 {
			return "1080p"
		} else if media.Height >= 720 {
			return "720p"
		}
		return "480p"
	}

	// Otherwise use client's max resolution
	return client.MaxResolution
}

func suggestBitrate(media *MediaInfo, client *ClientCapabilities, resolution string) int {
	// Base bitrate on resolution
	baseBitrate := 8000 // 8 Mbps default for 1080p
	switch resolution {
	case "4k", "2160p":
		baseBitrate = 25000
	case "1440p":
		baseBitrate = 15000
	case "1080p":
		baseBitrate = 8000
	case "720p":
		baseBitrate = 4000
	case "480p":
		baseBitrate = 2000
	case "360p":
		baseBitrate = 1000
	}

	// Don't exceed source bitrate
	if media.Bitrate > 0 && baseBitrate > media.Bitrate {
		baseBitrate = media.Bitrate
	}

	// Don't exceed client max bitrate
	if client.MaxBitrate > 0 && baseBitrate > client.MaxBitrate {
		baseBitrate = client.MaxBitrate
	}

	return baseBitrate
}

// QuickCheck performs a fast compatibility check without full analysis
// Returns true if direct play is likely possible
func QuickCheck(videoCodec, audioCodec, container string, client *ClientCapabilities) bool {
	return containsIgnoreCase(client.VideoCodecs, videoCodec) &&
		containsIgnoreCase(client.AudioCodecs, audioCodec) &&
		containsIgnoreCase(client.Containers, container)
}
