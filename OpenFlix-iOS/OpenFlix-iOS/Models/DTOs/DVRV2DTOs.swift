import Foundation

// MARK: - DVR V2 Jobs
struct V2JobsResponse: Codable { let jobs: [V2JobDTO] }
struct V2JobDTO: Codable {
    let id: StringOrInt; let userId: Int?; let ruleId: StringOrInt?; let channelId: StringOrInt?
    let programId: StringOrInt?; let title: String; let subtitle: String?; let description: String?
    let startTime: String; let endTime: String; let status: String
    let priority: Int?; let qualityPreset: String?; let paddingStart: Int?; let paddingEnd: Int?
    let retryCount: Int?; let maxRetries: Int?; let lastError: String?; let cancelled: Bool?
    let channelName: String?; let channelLogo: String?; let category: String?
    let isMovie: Bool?; let isSports: Bool?; let fileId: StringOrInt?
    let createdAt: String?; let updatedAt: String?
}

// MARK: - DVR V2 Files
struct V2FilesResponse: Codable { let files: [V2FileDTO] }
struct V2FileDTO: Codable {
    let id: StringOrInt; let jobId: StringOrInt?; let groupId: StringOrInt?
    let title: String; let subtitle: String?; let description: String?; let summary: String?
    let filePath: String?; let fileSize: Int64?; let duration: Int?; let videoURL: String?
    let container: String?; let processed: Bool?; let completed: Bool?; let deleted: Bool?
    let thumb: String?; let art: String?; let seasonNumber: Int?; let episodeNumber: Int?
    let genres: String?; let contentRating: String?; let year: Int?
    let tmdbId: String?; let isMovie: Bool?; let rating: Double?; let originalAirDate: String?
    let labels: String?; let extras: String?; let locked: Bool?
    let createdAt: String?; let updatedAt: String?
    let commercials: [CommercialSegmentDTO]?; let detectedSegments: [DetectedSegmentDTO]?
}

struct DetectedSegmentDTO: Codable {
    let id: StringOrInt?; let fileId: StringOrInt?
    let type: String; let startTime: Double; let endTime: Double
}

struct CommercialSegmentDTO: Codable {
    let start: Double; let end: Double
}

// MARK: - DVR V2 Groups
struct V2GroupsResponse: Codable { let groups: [V2GroupDTO] }
struct V2GroupDTO: Codable {
    let id: StringOrInt; let title: String; let sortTitle: String?
    let description: String?; let thumb: String?; let art: String?
    let categories: String?; let genres: String?; let cast: String?
    let contentRating: String?; let year: Int?
    let tmdbId: String?; let tmdbType: String?; let fileCount: Int?
    let files: [V2FileDTO]?
}

struct V2GroupStateRequest: Codable {
    let numUnwatched: Int?; let upNextCursor: StringOrInt?
}

// MARK: - DVR V2 Rules
struct V2RulesResponse: Codable { let rules: [V2RuleDTO] }
struct V2RuleDTO: Codable {
    let id: StringOrInt; let userId: Int?; let name: String; let image: String?
    let query: String?; let keepOnly: Bool?; let keepNum: Int?
    let rerecord: Bool?; let duplicates: String?; let limit: Int?
    let paddingStart: Int?; let paddingEnd: Int?; let priority: Int?
    let qualityPreset: String?; let enabled: Bool?
    let createdAt: String?; let updatedAt: String?
}

struct V2RulePreviewResponse: Codable {
    let matchingPrograms: [V2RuleMatchDTO]?; let count: Int?
}
struct V2RuleMatchDTO: Codable {
    let title: String; let channelName: String?; let startTime: String?; let endTime: String?
}

// MARK: - DVR V2 Duplicates
struct V2DuplicatesResponse: Codable { let duplicates: [V2DuplicateDTO] }
struct V2DuplicateDTO: Codable {
    let jobId: StringOrInt; let title: String; let existingFileId: StringOrInt?
    let reason: String?
}
struct V2DuplicateStatsDTO: Codable {
    let total: Int; let prevented: Int; let overridden: Int
}

// MARK: - DVR V2 Up Next
struct V2UpNextResponse: Codable { let items: [V2UpNextItemDTO] }
struct V2UpNextItemDTO: Codable {
    let file: V2FileDTO; let group: V2GroupDTO?; let progress: Double?
}

// MARK: - DVR V2 Virtual Stations
struct VirtualStationsResponse: Codable { let stations: [VirtualStationDTO] }
struct VirtualStationDTO: Codable {
    let id: StringOrInt; let name: String; let number: String?; let logo: String?
    let description: String?; let smartRule: String?; let fileIds: [StringOrInt]?
    let shuffle: Bool?; let loop: Bool?; let enabled: Bool?
    let createdAt: String?; let updatedAt: String?
}

// MARK: - DVR V2 Collections
struct V2CollectionsResponse: Codable { let collections: [V2CollectionDTO] }
struct V2CollectionDTO: Codable {
    let id: StringOrInt; let title: String; let description: String?; let thumb: String?
    let smart: Bool?; let smartRule: String?
    let tmdbCollectionId: String?; let fileIds: [StringOrInt]?; let groupIds: [StringOrInt]?
    let itemCount: Int?
}
struct V2CollectionItemsResponse: Codable { let items: [V2FileDTO] }

// MARK: - DVR V2 Trash
struct V2TrashResponse: Codable { let items: [V2TrashItemDTO] }
struct V2TrashItemDTO: Codable {
    let id: StringOrInt; let title: String; let filePath: String?
    let fileSize: Int64?; let deletedAt: String?; let file: V2FileDTO?
}

// MARK: - DVR V2 Channel Collections
struct ChannelCollectionsResponse: Codable { let collections: [ChannelCollectionDTO] }
struct ChannelCollectionDTO: Codable {
    let id: StringOrInt; let name: String; let description: String?
    let channelIds: [StringOrInt]?; let virtualStationIds: [StringOrInt]?
    let rules: String?; let channelCount: Int?
}
struct ChannelCollectionGroupsResponse: Codable { let groups: [String] }
struct ChannelCollectionSourcesResponse: Codable { let sources: [String] }

// MARK: - DVR V2 Conflicts
struct V2ConflictsResponse: Codable { let conflicts: [V2ConflictDTO] }
struct V2ConflictDTO: Codable {
    let jobId: StringOrInt; let title: String; let startTime: String; let endTime: String
    let channelName: String?; let alternatives: [V2ConflictAlternativeDTO]?
}
struct V2ConflictAlternativeDTO: Codable {
    let channelId: StringOrInt; let channelName: String; let startTime: String; let endTime: String
}

// MARK: - DVR V2 Chapters
struct V2ChaptersResponse: Codable { let chapters: [V2ChapterDTO] }
struct V2ChapterDTO: Codable {
    let id: StringOrInt; let fileId: StringOrInt?; let title: String?
    let startTime: Double; let endTime: Double; let type: String?; let thumb: String?
}

// MARK: - DVR V2 File Upload
struct V2UploadProgressResponse: Codable {
    let id: StringOrInt; let progress: Double; let status: String
    let fileName: String?; let fileSize: Int64?
}

// MARK: - DVR V2 Events
struct V2EventDTO: Codable {
    let type: String; let data: String?; let timestamp: String?
}

// MARK: - Ad Stripping
struct StripAdsStatusResponse: Codable {
    let fileId: StringOrInt; let status: String; let progress: Double?
    let commercialsFound: Int?; let originalSize: Int64?; let newSize: Int64?
}

// MARK: - DVR Management
struct DVRPassesResponse: Codable { let passes: [DVRPassDTO] }
struct DVRPassDTO: Codable {
    let id: StringOrInt; let title: String; let type: String
    let enabled: Bool?; let paused: Bool?; let recordingCount: Int?
    let upcomingCount: Int?; let channelIds: [StringOrInt]?
}

struct DVRScheduleResponse: Codable { let entries: [DVRScheduleEntryDTO] }
struct DVRScheduleEntryDTO: Codable {
    let id: StringOrInt; let title: String; let channelName: String?
    let startTime: String; let endTime: String; let status: String
    let ruleId: StringOrInt?; let ruleName: String?
}

struct DVRCalendarResponse: Codable { let days: [DVRCalendarDayDTO] }
struct DVRCalendarDayDTO: Codable {
    let date: String; let recordings: [RecordingCalendarItemDTO]
}
struct RecordingCalendarItemDTO: Codable {
    let id: StringOrInt; let title: String; let startTime: String; let endTime: String
    let channelName: String?; let status: String
}

struct DiskUsageResponse: Codable {
    let totalSpace: Int64; let usedSpace: Int64; let freeSpace: Int64
    let recordingsSize: Int64; let recordingsCount: Int
}

struct QualityPresetsResponse: Codable { let presets: [QualityPresetDTO] }
struct QualityPresetDTO: Codable {
    let id: String; let name: String; let videoBitrate: Int?
    let audioBitrate: Int?; let resolution: String?
}

struct DVRSettingsResponse: Codable { let settings: DVRSettingsDTO }
struct DVRSettingsDTO: Codable {
    let storagePath: String?; let maxConcurrent: Int?; let prePadding: Int?
    let postPadding: Int?; let defaultQuality: String?; let autoCleanup: Bool?
    let keepDays: Int?; let commercialDetection: Bool?
}

struct DVRLabelsResponse: Codable { let labels: [String] }

struct RecordingsManagerResponse: Codable {
    let recordings: [RecordingDTO]?; let stats: RecordingStatsResponse?
    let groups: [RecordingGroupDTO]?
}
struct RecordingGroupDTO: Codable {
    let title: String; let count: Int; let recordings: [RecordingDTO]?
}

struct CommercialStatusResponse: Codable {
    let enabled: Bool; let processing: Int; let queued: Int; let completed: Int
}

struct ValidateStreamResponse: Codable {
    let valid: Bool; let format: String?; let resolution: String?; let error: String?
}


