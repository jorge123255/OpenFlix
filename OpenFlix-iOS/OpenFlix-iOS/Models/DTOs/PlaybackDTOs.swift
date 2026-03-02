import Foundation

// MARK: - Playback Capabilities
struct ClientCapabilitiesDTO: Codable {
    let deviceId: String; let directPlay: Bool?; let directStream: Bool?
    let transcodeVideo: Bool?; let transcodeAudio: Bool?
    let maxVideoBitrate: Int?; let maxAudioChannels: Int?
    let videoCodecs: [String]?; let audioCodecs: [String]?
    let containers: [String]?; let subtitleFormats: [String]?
}
struct DefaultCapabilitiesResponse: Codable { let capabilities: ClientCapabilitiesDTO }

// MARK: - Playback Decision
struct PlaybackDecisionResponse: Codable {
    let decision: String
    let url: String; let protocolType: String?
    let videoDecision: String?; let audioDecision: String?
    let subtitleDecision: String?
    let transcodeUrl: String?; let directPlayUrl: String?
    let container: String?; let videoCodec: String?; let audioCodec: String?
    let videoBitrate: Int?; let audioBitrate: Int?; let width: Int?; let height: Int?
    enum CodingKeys: String, CodingKey {
        case decision, url, protocolType = "protocol"
        case videoDecision, audioDecision, subtitleDecision
        case transcodeUrl, directPlayUrl
        case container, videoCodec, audioCodec
        case videoBitrate, audioBitrate, width, height
    }
}

struct PlaybackOptionsResponse: Codable {
    let options: [PlaybackOptionDTO]
}
struct PlaybackOptionDTO: Codable {
    let type: String; let label: String; let url: String
    let bitrate: Int?; let resolution: String?; let codec: String?
}

// MARK: - Bandwidth
struct BandwidthReportResponse: Codable { let success: Bool }
struct ServerBandwidthResponse: Codable {
    let currentUsage: Int64; let limit: Int64?; let clientCount: Int
    let clients: [ClientBandwidthDTO]?
}
struct ClientBandwidthDTO: Codable {
    let clientId: String; let deviceName: String?
    let downloadSpeed: Int64?; let uploadSpeed: Int64?; let cap: Int64?
    let lastReported: String?
}

// MARK: - Skip Markers
struct SkipMarkersResponse: Codable { let markers: [SkipMarkerDTO] }
struct SkipMarkerDTO: Codable {
    let id: StringOrInt?; let type: String
    let startTime: Double; let endTime: Double; let source: String?
}
struct SkipSettingsResponse: Codable { let settings: SkipSettingsDTO }
struct SkipSettingsDTO: Codable {
    let autoSkipIntro: Bool?; let autoSkipCredits: Bool?; let autoSkipCommercials: Bool?
    let showSkipButton: Bool?; let skipButtonDuration: Int?
}

// MARK: - Audio/Subtitle Tracks
struct MediaTracksResponse: Codable { let tracks: [MediaTrackDTO] }
struct MediaTrackDTO: Codable {
    let id: Int; let type: String
    let codec: String?; let language: String?; let languageCode: String?
    let displayTitle: String?; let selected: Bool?; let forced: Bool?
    let isDefault: Bool?; let channels: Int?; let bitrate: Int?
    enum CodingKeys: String, CodingKey {
        case id, type, codec, language, languageCode, displayTitle
        case selected, forced, isDefault = "default", channels, bitrate
    }
}

struct TrackPreferencesResponse: Codable { let preferences: TrackPreferencesDTO }
struct TrackPreferencesDTO: Codable {
    let preferredAudioLanguage: String?; let preferredSubtitleLanguage: String?
    let autoSelectSubtitles: Bool?; let forceSubtitles: Bool?
    let preferOriginalAudio: Bool?
}

// MARK: - Playback Speed
struct SpeedPresetsResponse: Codable { let presets: [Double] }
struct SessionSpeedResponse: Codable { let speed: Double }

// MARK: - Frame Rate
struct FrameRateResponse: Codable {
    let frameRate: Double; let scanType: String?; let isHDR: Bool?
}
struct FrameRateSettingsResponse: Codable { let settings: FrameRateSettingsDTO }
struct FrameRateSettingsDTO: Codable {
    let matchFrameRate: Bool?; let matchDynamicRange: Bool?
    let preferredFrameRate: Double?
}
