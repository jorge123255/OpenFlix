import Foundation

// MARK: - Admin Libraries
struct AdminLibrariesResponse: Codable { let libraries: [AdminLibraryDTO] }
struct AdminLibraryDTO: Codable {
    let id: StringOrInt; let name: String; let type: String
    let paths: [LibraryPathDTO]?; let scanInterval: Int?
    let agent: String?; let scanner: String?; let language: String?
    let itemCount: Int?; let lastScanned: String?
}
struct LibraryPathDTO: Codable {
    let id: StringOrInt; let path: String
}
struct LibraryStatsDTO: Codable {
    let itemCount: Int; let totalSize: Int64; let lastScanned: String?
    let byType: [String: Int]?
}

// MARK: - Filesystem Browser
struct FilesystemBrowseResponse: Codable { let entries: [FilesystemEntryDTO] }
struct FilesystemEntryDTO: Codable {
    let name: String; let path: String; let isDirectory: Bool; let size: Int64?
    let modifiedAt: String?
}

// MARK: - Admin Settings
struct AdminSettingsResponse: Codable { let settings: [String: AnyCodable] }

struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) { value = intVal }
        else if let doubleVal = try? container.decode(Double.self) { value = doubleVal }
        else if let boolVal = try? container.decode(Bool.self) { value = boolVal }
        else if let stringVal = try? container.decode(String.self) { value = stringVal }
        else if let arrayVal = try? container.decode([AnyCodable].self) { value = arrayVal.map { $0.value } }
        else if let dictVal = try? container.decode([String: AnyCodable].self) { value = dictVal.mapValues { $0.value } }
        else { value = NSNull() }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intVal as Int: try container.encode(intVal)
        case let doubleVal as Double: try container.encode(doubleVal)
        case let boolVal as Bool: try container.encode(boolVal)
        case let stringVal as String: try container.encode(stringVal)
        default: try container.encodeNil()
        }
    }
}

// MARK: - Database Backups
struct BackupsResponse: Codable { let backups: [BackupDTO] }
struct BackupDTO: Codable {
    let filename: String; let size: Int64; let createdAt: String
    let description: String?
}

// MARK: - Search Admin
struct SearchStatsResponse: Codable {
    let totalDocuments: Int; let indexSize: Int64; let lastIndexed: String?
}

// MARK: - Self-Update
struct UpdaterStatusResponse: Codable {
    let currentVersion: String; let latestVersion: String?
    let updateAvailable: Bool; let lastChecked: String?
    let downloading: Bool?; let progress: Double?
}

// MARK: - Admin Media
struct AdminMediaResponse: Codable { let media: [AdminMediaItemDTO]; let total: Int? }
struct AdminMediaItemDTO: Codable {
    let id: StringOrInt; let title: String; let type: String
    let year: Int?; let tmdbId: String?; let thumb: String?
    let matched: Bool?; let filePath: String?
}
struct AdminTMDBSearchResponse: Codable { let results: [AdminTMDBResultDTO] }
struct AdminTMDBResultDTO: Codable {
    let id: Int; let title: String?; let name: String?; let mediaType: String?
    let overview: String?; let posterPath: String?; let releaseDate: String?
    let voteAverage: Double?
    enum CodingKeys: String, CodingKey {
        case id, title, name, mediaType = "media_type"
        case overview, posterPath = "poster_path"
        case releaseDate = "release_date", voteAverage = "vote_average"
    }
}

// MARK: - Auto-Update Config
struct AutoUpdateConfigResponse: Codable { let config: AutoUpdateConfigDTO }
struct AutoUpdateConfigDTO: Codable {
    let enabled: Bool; let schedule: String?; let channel: String?
    let lastCheck: String?; let nextCheck: String?
}
struct UpdateScheduleResponse: Codable {
    let schedule: String; let nextRun: String?; let lastRun: String?
}

// MARK: - Scheduled Tasks
struct ScheduledTasksResponse: Codable { let tasks: [ScheduledTaskDTO] }
struct ScheduledTaskDTO: Codable {
    let id: StringOrInt; let name: String; let description: String?
    let schedule: String; let enabled: Bool; let lastRun: String?
    let nextRun: String?; let status: String?; let duration: Int?
}
struct SchedulerHistoryResponse: Codable { let history: [SchedulerHistoryEntryDTO] }
struct SchedulerHistoryEntryDTO: Codable {
    let taskId: StringOrInt; let taskName: String; let startedAt: String
    let completedAt: String?; let status: String; let duration: Int?; let error: String?
}

// MARK: - Diagnostics
struct HealthCheckResponse: Codable {
    let status: String; let checks: [HealthCheckItemDTO]?
}
struct HealthCheckItemDTO: Codable {
    let name: String; let status: String; let message: String?; let duration: Int?
}
struct SystemStatusResponse: Codable {
    let uptime: Int; let cpuUsage: Double?; let memoryUsage: Double?
    let diskUsage: Double?; let goroutines: Int?; let version: String
}

// MARK: - Dashboard
struct DashboardResponse: Codable {
    let activeSessions: Int?; let totalRecordings: Int?; let upcomingRecordings: Int?
    let channelCount: Int?; let libraryItemCount: Int?; let diskUsage: DiskUsageResponse?
    let recentActivity: [DashboardActivityDTO]?
}
struct DashboardActivityDTO: Codable {
    let type: String; let title: String; let timestamp: String; let details: String?
}

// MARK: - Server Status
struct ServerStatusResponse: Codable {
    let name: String; let version: String; let uptime: Int?
    let platform: String?; let machineIdentifier: String?
    let activeSessions: Int?; let transcoderActive: Bool?
}

// MARK: - Transcode Info
struct TranscodeInfoResponse: Codable {
    let active: Int; let sessions: [TranscodeSessionInfoDTO]?
}
struct TranscodeSessionInfoDTO: Codable {
    let sessionId: String; let mediaTitle: String?; let progress: Double?
    let speed: Double?; let videoDecision: String?; let audioDecision: String?
}

// MARK: - Config Export/Import
struct ConfigStatsResponse: Codable {
    let libraries: Int; let sources: Int; let rules: Int
    let channels: Int; let recordings: Int; let profiles: Int
}
