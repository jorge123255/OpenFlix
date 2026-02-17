import Foundation

// MARK: - DVR Recordings

struct RecordingsResponse: Codable {
    let recordings: [RecordingDTO]?

    var allRecordings: [RecordingDTO] {
        recordings ?? []
    }
}

struct ScheduledRecordingsResponse: Codable {
    let scheduled: [RecordingDTO]?

    var allScheduled: [RecordingDTO] {
        scheduled ?? []
    }
}

struct RecordingDTO: Codable {
    let idValue: StringOrInt?
    let title: String?
    let subtitle: String?
    let description: String?
    let summary: String?
    let thumb: String?
    let art: String?
    let channelId: StringOrInt?
    let channelName: String?
    let channelLogo: String?
    let startTime: String?
    let endTime: String?
    let duration: Int?          // milliseconds
    let status: String?         // scheduled, recording, completed, failed
    let filePath: String?
    let fileSize: Int?
    let seasonNumber: Int?
    let episodeNumber: Int?
    let seriesRecord: Bool?
    let seriesRuleId: Int?
    let genres: String?
    let contentRating: String?
    let year: Int?
    let rating: Double?
    let isMovie: Bool?
    let viewOffset: Int?        // milliseconds
    let commercials: [CommercialDTO]?
    let priority: Int?
    let programId: StringOrInt?
    let seriesId: StringOrInt?
    let category: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case title, subtitle, description, summary, thumb, art
        case channelId, channelName, channelLogo
        case startTime, endTime, duration, status, filePath, fileSize
        case seasonNumber, episodeNumber, seriesRecord, seriesRuleId
        case genres, contentRating, year, rating, isMovie
        case viewOffset, commercials, priority, programId, seriesId
        case category, createdAt, updatedAt
    }

    var safeId: Int { idValue?.intValue ?? 0 }
    var safeTitle: String { title ?? "Unknown Recording" }
    var safeStatus: String { status ?? "unknown" }

    var startDate: Date? {
        guard let startTime = startTime else { return nil }
        return ISO8601DateFormatter().date(from: startTime)
    }

    var endDate: Date? {
        guard let endTime = endTime else { return nil }
        return ISO8601DateFormatter().date(from: endTime)
    }
}

struct CommercialDTO: Codable {
    let start: Int      // milliseconds
    let end: Int        // milliseconds
}

struct RecordingStreamResponse: Codable {
    let url: String
    let format: String?
}

struct RecordingStatsResponse: Codable {
    let total: Int
    let scheduled: Int
    let recording: Int
    let completed: Int
    let failed: Int
    let totalSize: Int?         // bytes
}

// MARK: - Series Rules

struct SeriesRulesResponse: Codable {
    let rules: [SeriesRuleDTO]
}

struct SeriesRuleDTO: Codable {
    let idValue: StringOrInt
    let title: String?
    let channelId: StringOrInt?
    let enabled: Bool?
    let prePadding: Int?
    let postPadding: Int?
    let keepCount: Int?
    let recordingCount: Int?

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case title, channelId, enabled, prePadding, postPadding, keepCount, recordingCount
    }

    var safeId: Int { idValue.intValue }
    var safeTitle: String { title ?? "Series Rule" }
}

// MARK: - DVR Conflicts

struct ConflictsResponse: Codable {
    let conflicts: [ConflictDTO]
}

struct ConflictDTO: Codable {
    let id: Int
    let recordings: [RecordingDTO]
    let startTime: String
    let endTime: String
}

// MARK: - Watchlist

struct WatchlistResponse: Codable {
    let items: [WatchlistItemDTO]?
    let MediaContainer: MediaContainer?  // Alternative format

    var allItems: [WatchlistItemDTO] {
        items ?? []
    }
}

struct WatchlistItemDTO: Codable {
    let id: Int?
    let mediaId: Int?
    let addedAt: String?
    let media: MediaItemDTO?

    var safeId: Int { id ?? 0 }
    var safeMediaId: Int { mediaId ?? 0 }
}

// MARK: - Playlists

struct PlaylistsResponse: Codable {
    let playlists: [PlaylistDTO]?
    let MediaContainer: PlaylistsContainer?  // Alternative format

    var allPlaylists: [PlaylistDTO] {
        playlists ?? []
    }
}

struct PlaylistsContainer: Codable {
    let Playlist: [PlaylistDTO]?
}

struct PlaylistDTO: Codable {
    let id: Int?
    let ratingKey: String?
    let name: String?
    let title: String?
    let itemCount: Int?
    let leafCount: Int?
    let duration: Int?          // total duration in milliseconds
    let thumb: String?
    let createdAt: String?
    let updatedAt: String?

    var safeId: Int { id ?? (Int(ratingKey ?? "0") ?? 0) }
    var safeName: String { name ?? title ?? "Playlist" }
}

struct PlaylistItemsResponse: Codable {
    let items: [PlaylistItemDTO]
}

struct PlaylistItemDTO: Codable {
    let id: Int
    let playlistId: Int
    let mediaId: Int
    let index: Int
    let addedAt: String?
    let media: MediaItemDTO?
}

// MARK: - Collections

struct CollectionsResponse: Codable {
    let MediaContainer: CollectionsContainer
}

struct CollectionsContainer: Codable {
    let Metadata: [CollectionDTO]?
}

struct CollectionDTO: Codable {
    let ratingKey: String
    let key: String
    let type: String
    let title: String
    let summary: String?
    let thumb: String?
    let art: String?
    let childCount: Int?
    let addedAt: Int?
    let updatedAt: Int?
}

// MARK: - Archive / Catch-up

struct ArchiveStatusResponse: Codable {
    let channels: [ArchiveChannelStatusDTO]
}

struct ArchiveChannelStatusDTO: Codable {
    let channelId: String
    let channelName: String
    let enabled: Bool
    let daysAvailable: Int
    let sizeBytes: Int?
    let programCount: Int?
}

struct ArchiveProgramsResponse: Codable {
    let programs: [ArchiveProgramDTO]
}

struct ArchiveProgramDTO: Codable {
    let id: Int
    let channelId: String
    let program: ProgramDTO
    let filePath: String?
    let fileSize: Int?
    let available: Bool
}

// MARK: - Sessions

struct SessionsResponse: Codable {
    let MediaContainer: SessionsContainer
}

struct SessionsContainer: Codable {
    let Metadata: [SessionDTO]?
}

struct SessionDTO: Codable {
    let sessionKey: String
    let ratingKey: String
    let title: String
    let type: String
    let viewOffset: Int?
    let duration: Int?
    let User: SessionUserDTO?
    let Player: SessionPlayerDTO?
    let TranscodeSession: TranscodeSessionDTO?
}

struct SessionUserDTO: Codable {
    let id: Int
    let title: String
    let thumb: String?
}

struct SessionPlayerDTO: Codable {
    let machineIdentifier: String
    let platform: String?
    let product: String?
    let title: String?
    let state: String?          // playing, paused, buffering
}

struct TranscodeSessionDTO: Codable {
    let key: String
    let throttled: Bool?
    let complete: Bool?
    let progress: Double?
    let speed: Double?
    let videoDecision: String?
    let audioDecision: String?
}

// MARK: - Client Logs

struct ClientLogEntry: Codable {
    let timestamp: Int
    let level: String           // debug, info, warning, error
    let message: String
    let tag: String?
    let device: String?
    let appVersion: String?
    let stackTrace: String?

    enum CodingKeys: String, CodingKey {
        case timestamp
        case level
        case message
        case tag
        case device
        case appVersion = "app_version"
        case stackTrace = "stack_trace"
    }
}

// MARK: - Server Settings

struct ServerSettingsResponse: Codable {
    let settings: ServerSettingsDTO
}

struct ServerSettingsDTO: Codable {
    let tmdbApiKey: String?
    let tvdbApiKey: String?
    let metadataLang: String?
    let scanInterval: Int?
    let vodApiUrl: String?

    enum CodingKeys: String, CodingKey {
        case tmdbApiKey = "tmdb_api_key"
        case tvdbApiKey = "tvdb_api_key"
        case metadataLang = "metadata_lang"
        case scanInterval = "scan_interval"
        case vodApiUrl = "vod_api_url"
    }
}
