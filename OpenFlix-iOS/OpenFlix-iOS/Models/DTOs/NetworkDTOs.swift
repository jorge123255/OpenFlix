import Foundation

// MARK: - Remote Access
struct ConnectionInfoResponse: Codable {
    let localUrl: String?; let remoteUrl: String?; let tailscaleIp: String?
    let isRemote: Bool?; let connected: Bool?
}
struct RemoteAccessStatusResponse: Codable {
    let enabled: Bool; let connected: Bool; let tailscaleIp: String?
    let hostname: String?; let loginUrl: String?; let lastSeen: String?
}
struct RemoteAccessHealthResponse: Codable {
    let status: String; let latency: Int?; let lastCheck: String?
}
struct RemoteAccessInstallInfoResponse: Codable {
    let installed: Bool; let version: String?; let instructions: String?
}

// MARK: - DDNS
struct DDNSStatusResponse: Codable {
    let enabled: Bool; let provider: String?; let hostname: String?
    let currentIp: String?; let lastUpdate: String?; let status: String?
}
struct DDNSConfigRequest: Codable {
    let provider: String; let hostname: String
    let username: String?; let password: String?
}

// MARK: - Notifications
struct NotificationConfigResponse: Codable { let config: NotificationConfigDTO }
struct NotificationConfigDTO: Codable {
    let webhookUrl: String?; let webhookEnabled: Bool?
    let emailEnabled: Bool?; let emailTo: String?
    let pushEnabled: Bool?; let events: [String]?
}
struct NotificationHistoryResponse: Codable { let notifications: [NotificationDTO] }
struct NotificationDTO: Codable {
    let id: StringOrInt; let type: String; let title: String
    let message: String; let sentAt: String; let status: String
}

// MARK: - Speed Test
struct SpeedTestPingResponse: Codable { let latency: Double }
struct SpeedTestDownloadResponse: Codable { let speed: Double; let bytes: Int64; let duration: Double }
struct SpeedTestUploadResponse: Codable { let speed: Double; let bytes: Int64; let duration: Double }
struct SpeedTestResultsResponse: Codable {
    let id: String; let downloadSpeed: Double; let uploadSpeed: Double
    let latency: Double; let timestamp: String
}

// MARK: - Stream Health
struct HealthStreamsResponse: Codable { let streams: [HealthStreamDTO] }
struct HealthStreamDTO: Codable {
    let id: StringOrInt; let channelId: StringOrInt?; let channelName: String?
    let status: String; let quality: Double?; let buffering: Double?
    let errors: Int?; let uptime: Int?; let lastCheck: String?
}
struct HealthChannelsResponse: Codable { let channels: [HealthChannelDTO] }
struct HealthChannelDTO: Codable {
    let channelId: StringOrInt; let channelName: String; let reliability: Double?
    let avgQuality: Double?; let totalErrors: Int?
}
struct ChannelHealthHistoryResponse: Codable { let history: [HealthHistoryEntryDTO] }
struct HealthHistoryEntryDTO: Codable {
    let timestamp: String; let quality: Double?; let buffering: Double?; let errors: Int?
}
struct HealthAlertsResponse: Codable { let alerts: [HealthAlertDTO] }
struct HealthAlertDTO: Codable {
    let id: StringOrInt; let type: String; let severity: String
    let message: String; let channelId: StringOrInt?; let timestamp: String
    let resolved: Bool?
}
struct HealthSummaryResponse: Codable {
    let totalStreams: Int; let healthyStreams: Int; let degradedStreams: Int
    let failedStreams: Int; let activeAlerts: Int; let avgQuality: Double?
}

// MARK: - Tuners / HDHR
struct TunersResponse: Codable { let tuners: [TunerDTO] }
struct TunerDTO: Codable {
    let id: StringOrInt; let name: String; let url: String?
    let model: String?; let deviceId: String?; let channelCount: Int?
    let tunerCount: Int?; let status: String?
}
struct TunerLineupResponse: Codable { let channels: [TunerChannelDTO] }
struct TunerChannelDTO: Codable {
    let number: String; let name: String; let url: String?; let hd: Bool?
}
struct TunerStatusResponse: Codable {
    let online: Bool; let activeTuners: Int; let totalTuners: Int
    let channels: [String]?
}
struct TunerDiscoveryResponse: Codable { let discovered: [DiscoveredTunerDTO] }
struct DiscoveredTunerDTO: Codable {
    let url: String; let name: String; let model: String?; let deviceId: String?
}

// MARK: - Bookmarks
struct BookmarksResponse: Codable { let bookmarks: [BookmarkDTO] }
struct BookmarkDTO: Codable {
    let id: StringOrInt; let mediaId: StringOrInt; let time: Double
    let title: String?; let description: String?; let thumb: String?
    let createdAt: String?
}

// MARK: - Clips
struct ClipsResponse: Codable { let clips: [ClipDTO] }
struct ClipDTO: Codable {
    let id: StringOrInt; let mediaId: StringOrInt; let title: String?
    let startTime: Double; let endTime: Double; let duration: Double?
    let filePath: String?; let fileSize: Int64?; let status: String?
    let createdAt: String?
}

// MARK: - Offline Downloads
struct OfflineDownloadsResponse: Codable { let downloads: [OfflineDownloadDTO] }
struct OfflineDownloadDTO: Codable {
    let id: StringOrInt; let mediaId: StringOrInt; let title: String
    let quality: String?; let status: String; let progress: Double?
    let fileSize: Int64?; let downloadedSize: Int64?
    let expiresAt: String?; let createdAt: String?
}
struct OfflineSettingsResponse: Codable { let settings: OfflineSettingsDTO }
struct OfflineSettingsDTO: Codable {
    let maxDownloads: Int?; let defaultQuality: String?
    let wifiOnly: Bool?; let autoDelete: Bool?; let storagePath: String?
}

// MARK: - Subtitles
struct SubtitleSearchResponse: Codable { let subtitles: [SubtitleResultDTO] }
struct SubtitleResultDTO: Codable {
    let id: String; let language: String; let languageCode: String
    let title: String?; let provider: String?; let rating: Double?
    let downloadCount: Int?
}
struct SubtitleConfigResponse: Codable { let config: SubtitleConfigDTO }
struct SubtitleConfigDTO: Codable {
    let openSubtitlesApiKey: String?; let autoDownload: Bool?
    let preferredLanguages: [String]?
}
struct MediaSubtitlesResponse: Codable { let subtitles: [MediaSubtitleDTO] }
struct MediaSubtitleDTO: Codable {
    let language: String; let languageCode: String; let filePath: String
    let forced: Bool?; let external: Bool?
}

// MARK: - VOD
struct VODProvidersResponse: Codable { let providers: [VODProviderDTO] }
struct VODProviderDTO: Codable {
    let id: String; let name: String; let logo: String?; let enabled: Bool?
}
struct VODMoviesResponse: Codable { let movies: [VODMovieDTO]; let total: Int? }
struct VODMovieDTO: Codable {
    let id: StringOrInt; let title: String; let year: Int?; let rating: Double?
    let thumb: String?; let description: String?; let genres: [String]?
    let streamUrl: String?
}
struct VODShowsResponse: Codable { let shows: [VODShowDTO]; let total: Int? }
struct VODShowDTO: Codable {
    let id: StringOrInt; let title: String; let year: Int?; let rating: Double?
    let thumb: String?; let description: String?; let genres: [String]?
    let seasonCount: Int?
}
struct VODGenresResponse: Codable { let genres: [String] }
struct VODQueueResponse: Codable { let downloads: [VODDownloadDTO] }
struct VODDownloadDTO: Codable {
    let id: StringOrInt; let title: String; let provider: String
    let status: String; let progress: Double?
}
struct VODConnectionTestResponse: Codable { let success: Bool; let message: String? }

// MARK: - Device Management
struct DevicesResponse: Codable { let devices: [DeviceDTO] }
struct DeviceDTO: Codable {
    let id: StringOrInt; let name: String; let platform: String?
    let version: String?; let lastSeen: String?; let ipAddress: String?
    let settings: [String: AnyCodable]?
}
struct DeviceSettingsResponse: Codable { let settings: [String: AnyCodable] }
struct DeviceRegistrationResponse: Codable {
    let deviceId: StringOrInt; let success: Bool
}

// MARK: - Personal Sections
struct PersonalSectionsResponse: Codable { let sections: [PersonalSectionDTO] }
struct PersonalSectionDTO: Codable {
    let id: StringOrInt; let title: String; let type: String
    let smart: Bool?; let filter: String?; let itemCount: Int?
    let thumb: String?
}
struct GenresListResponse: Codable { let genres: [String] }

// MARK: - Parental Controls
struct ParentalSettingsResponse: Codable { let settings: ParentalSettingsDTO }
struct ParentalSettingsDTO: Codable {
    let enabled: Bool; let pin: String?; let maxRating: String?
    let blockedChannels: [StringOrInt]?; let blockedCategories: [String]?
    let kidsModeEnabled: Bool?
}

// MARK: - Guide Data
struct GuideRefreshResponse: Codable { let success: Bool; let message: String? }

// MARK: - Global Client Settings
struct GlobalClientSettingsResponse: Codable { let settings: [String: AnyCodable] }

// MARK: - Gracenote
struct GracenoteProvidersResponse: Codable { let providers: [GracenoteProviderDTO] }
struct GracenoteProviderDTO: Codable {
    let id: String; let name: String; let type: String?; let lineup: String?
}

// MARK: - EPG Management
struct EPGStatsResponse: Codable {
    let totalChannels: Int; let totalPrograms: Int; let sourcesCount: Int
    let lastUpdate: String?; let coverage: Double?
}
struct EPGSchedulerStatusResponse: Codable {
    let running: Bool; let lastRun: String?; let nextRun: String?; let interval: Int?
}
struct GuideCacheStatsResponse: Codable {
    let entries: Int; let size: Int64?; let hitRate: Double?; let lastInvalidated: String?
}
struct EPGConflictsResponseV2: Codable { let conflicts: [EPGConflictDTO] }
struct EPGConflictDTO: Codable {
    let channelId: StringOrInt; let programId: StringOrInt?
    let type: String; let description: String?
}
struct EPGSourceHealthResponse: Codable { let sources: [EPGSourceHealthDTO] }
struct EPGSourceHealthDTO: Codable {
    let id: StringOrInt; let name: String; let healthy: Bool
    let lastFetch: String?; let errorCount: Int?; let lastError: String?
}

// MARK: - Generic Success/Message Response
struct SuccessResponse: Codable {
    let success: Bool; let message: String?
}
struct MessageResponse: Codable {
    let message: String
}

// MARK: - Server Prefs (Plex-compat)
struct ServerPrefsResponse: Codable {
    let MediaContainer: ServerPrefsContainer?
}
struct ServerPrefsContainer: Codable {
    let size: Int?; let Setting: [ServerPrefDTO]?
}
struct ServerPrefDTO: Codable {
    let id: String; let label: String?; let value: String?; let type: String?
}

// MARK: - App Downloads
struct AppDownloadsResponse: Codable { let downloads: [AppDownloadDTO] }
struct AppDownloadDTO: Codable {
    let filename: String; let platform: String; let version: String; let size: Int64?
}

// MARK: - Lineup Export
struct LineupJSONResponse: Codable { let channels: [LineupChannelDTO] }
struct LineupChannelDTO: Codable {
    let number: String; let name: String; let logo: String?
    let url: String?; let hd: Bool?
}

// MARK: - Catch-up / Start Over
struct CatchUpResponse: Codable {
    let programs: [CatchUpProgramDTO]
    let isArchiving: Bool?
    let archiveStart: String?
    let retentionDays: Int?
    let bufferActive: Bool?
    let bufferStart: String?
}
struct CatchUpProgramDTO: Codable {
    let id: StringOrInt; let channelId: StringOrInt?
    let title: String; let startTime: String; let endTime: String
    let description: String?; let icon: String?; let streamUrl: String?
    let available: Bool?
}
struct StartOverInfoDTO: Codable {
    let available: Bool; let streamUrl: String?; let startTime: String?
}

// MARK: - EPG Programs/Channels
struct EPGProgramsResponse: Codable {
    let programs: [ProgramDTO]; let total: Int?
}
struct EPGChannelsListResponse: Codable {
    let channels: [EPGChannelListDTO]
}
struct EPGChannelListDTO: Codable {
    let id: StringOrInt; let name: String; let number: String?
    let logo: String?; let sourceId: StringOrInt?; let programCount: Int?
}

// MARK: - Commercial Detection
struct CommercialDetectionStatusResponse: Codable {
    let enabled: Bool; let processing: Int; let queued: Int; let completed: Int
}

// MARK: - Show Search (TMDB-first, for Create Pass)
struct ShowSearchResult: Codable, Identifiable {
    let tmdbId: Int?
    let title: String
    let overview: String?
    let year: Int?
    let mediaType: String?
    let posterUrl: String?
    let nextAiring: ShowNextAiring?

    var id: String { "\(tmdbId ?? 0)-\(title)" }
}

struct ShowNextAiring: Codable {
    let start: String
    let channelName: String?
}

// The endpoint returns a JSON array directly, but we wrap it for convenience
typealias ShowSearchResultsResponse = [ShowSearchResult]

// Tracker info embedded in pass listings
struct ShowTrackerInfo: Codable {
    let tmdbId: Int?
    let posterUrl: String?
    let nextSeasonNumber: Int?
    let nextEpisodeAirDate: String?
}
