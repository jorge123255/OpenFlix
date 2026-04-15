import Foundation

private enum LiveTVDateParsers {
    static let iso8601Fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return iso8601Fractional.date(from: value) ?? iso8601.date(from: value)
    }

    static func parseDateOnly(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}

// MARK: - Channels

struct ChannelsResponse: Codable {
    let channels: [ChannelDTO]?

    var allChannels: [ChannelDTO] {
        channels ?? []
    }
}

struct ChannelDTO: Codable {
    let idValue: StringOrInt?
    let channelId: String?       // EPG/guide channel ID (key in programs map)
    let tvgId: String?           // EPG channel ID - used as key in programs map
    let number: Int?
    let name: String?
    let title: String?
    let callsign: String?
    let logo: String?
    let thumb: String?
    let art: String?
    let sourceId: StringOrInt?
    let sourceName: String?
    let sourceType: String?
    let providerId: String?
    let providerName: String?
    let accountId: StringOrInt?
    let accountName: String?
    let accountIndex: Int?
    let streamUrl: String?
    let playUrl: String?
    let hlsUrl: String?
    let browserHlsUrl: String?
    let playable: Bool?
    let drm: Bool?
    let enabled: Bool?
    let hd: Bool?
    let isFavorite: Bool?
    let group: String?
    let category: String?
    let archiveEnabled: Bool?
    let archiveDays: Int?
    let nowPlaying: ProgramDTO?
    let nextProgram: ProgramDTO?

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case channelId, tvgId
        case number, name, title, callsign, logo, thumb, art
        case sourceId, sourceName, sourceType, providerId, providerName
        case accountId, accountName, accountIndex
        case streamUrl, playUrl, hlsUrl, browserHlsUrl, playable, drm, enabled, hd, isFavorite
        case group, category, archiveEnabled, archiveDays
        case nowPlaying, nextProgram
    }

    var safeId: String { idValue?.stringValue ?? "" }
    var safeName: String { name ?? title ?? "Unknown Channel" }

    // Normalize empty strings to nil
    var channelIdOrNil: String? {
        let id = channelId?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (id?.isEmpty == true) ? nil : id
    }
    var tvgIdOrNil: String? {
        let id = tvgId?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (id?.isEmpty == true) ? nil : id
    }

    // EPG ID for program lookup - try channelId, tvgId, then id
    var epgId: String { channelIdOrNil ?? tvgIdOrNil ?? idValue?.stringValue ?? "" }
}

// MARK: - Program Deduplication Key

struct ProgramDedupeKey: Hashable {
    let id: String
    let start: String
    let end: String
    let startTime: Int
    let endTime: Int
    let title: String

    init(_ program: ProgramDTO) {
        self.id = program.safeId
        self.start = program.start ?? ""
        self.end = program.end ?? ""
        self.startTime = program.startTime ?? 0
        self.endTime = program.endTime ?? 0
        self.title = program.safeTitle
    }
}

// MARK: - Programs

struct ProgramDTO: Codable {
    let idValue: StringOrInt?
    let title: String?
    let subtitle: String?
    let description: String?
    let start: String?        // ISO timestamp
    let end: String?          // ISO timestamp
    let startTime: Int?       // Unix timestamp
    let endTime: Int?         // Unix timestamp
    let duration: Int?        // Duration in minutes
    let icon: String?
    let art: String?
    let rating: String?
    let parentalRating: String?
    let category: String?
    let isNew: Bool?
    let isLive: Bool?
    let isPremiere: Bool?
    let isFinale: Bool?
    let isRepeat: Bool?
    let repeatFlag: Bool?
    let isSports: Bool?
    let isMovie: Bool?
    let isNews: Bool?
    let isKids: Bool?
    let hasCC: Bool?
    let genres: [String]?
    let seasonNumber: Int?
    let episodeNumber: Int?
    let teams: String?
    let league: String?
    let originalAirDate: String?
    let releaseYear: Int?
    let network: String?
    let callSign: String?
    let resourceId: StringOrInt?
    let canonicalId: StringOrInt?
    let seriesId: StringOrInt?
    let providerChannelId: String?
    let slingChannelId: String?
    let slingItemId: String?
    let slingFranchiseId: String?
    let hasRecording: Bool?
    let recordingId: StringOrInt?

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case title, subtitle, description, start, end
        case startTime, endTime, duration, icon, art, rating, parentalRating, category
        case isNew, isLive, isPremiere, isFinale, isRepeat, isSports, isMovie, isNews, isKids
        case repeatFlag = "repeat"
        case hasCC, genres, seasonNumber, episodeNumber
        case originalAirDate, releaseYear, network, callSign
        case teams, league, resourceId, canonicalId, seriesId
        case providerChannelId, slingChannelId, slingItemId, slingFranchiseId
        case hasRecording, recordingId
    }

    var safeId: String { idValue?.stringValue ?? "" }
    var safeTitle: String { title ?? "Unknown Program" }

    var startDate: Date? {
        if let start = start {
            return LiveTVDateParsers.parse(start)
        }
        if let startTime = startTime {
            return Date(timeIntervalSince1970: TimeInterval(startTime))
        }
        return nil
    }

    var endDate: Date? {
        if let end = end {
            return LiveTVDateParsers.parse(end)
        }
        if let endTime = endTime {
            return Date(timeIntervalSince1970: TimeInterval(endTime))
        }
        return nil
    }

    var resolvedIsRepeat: Bool {
        if let isRepeat { return isRepeat }
        if let repeatFlag { return repeatFlag }
        guard let originalAirDate = LiveTVDateParsers.parseDateOnly(originalAirDate),
              let startDate else { return false }
        return !Calendar.current.isDate(originalAirDate, inSameDayAs: startDate)
    }
}

// MARK: - Guide

struct GuideResponse: Decodable {
    let channels: [ChannelDTO]?  // Basic channel info
    let programs: [String: [ProgramDTO]]?  // Programs map keyed by channel ID
    let start: String?
    let end: String?

    enum CodingKeys: String, CodingKey {
        case channels
        case programs
        case programsByChannel = "programsByChannel"
        case programsByChannelSnake = "programs_by_channel"
        case programsMap = "programs_map"
        case start
        case end
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channels = try? container.decode([ChannelDTO].self, forKey: .channels)
        start = try? container.decode(String.self, forKey: .start)
        end = try? container.decode(String.self, forKey: .end)

        var mergedPrograms: [String: [ProgramDTO]] = [:]

        if let directPrograms = try? container.decode([String: [ProgramDTO]].self, forKey: .programs) {
            Self.mergeProgramsMap(into: &mergedPrograms, from: directPrograms)
        }
        if let directPrograms = try? container.decode([String: [ProgramDTO]].self, forKey: .programsByChannel) {
            Self.mergeProgramsMap(into: &mergedPrograms, from: directPrograms)
        }
        if let directPrograms = try? container.decode([String: [ProgramDTO]].self, forKey: .programsByChannelSnake) {
            Self.mergeProgramsMap(into: &mergedPrograms, from: directPrograms)
        }
        if let directPrograms = try? container.decode([String: [ProgramDTO]].self, forKey: .programsMap) {
            Self.mergeProgramsMap(into: &mergedPrograms, from: directPrograms)
        }

        if let channelsWithPrograms = try? container.decode([ChannelWithProgramsDTO].self, forKey: .channels) {
            for channel in channelsWithPrograms where !channel.allPrograms.isEmpty {
                if !channel.safeId.isEmpty {
                    mergedPrograms[channel.safeId] = Self.mergeProgramLists(
                        mergedPrograms[channel.safeId] ?? [],
                        channel.allPrograms
                    )
                }
                if let number = channel.number {
                    let numberKey = String(number)
                    mergedPrograms[numberKey] = Self.mergeProgramLists(
                        mergedPrograms[numberKey] ?? [],
                        channel.allPrograms
                    )
                }
            }
        }

        programs = mergedPrograms.isEmpty ? nil : mergedPrograms
    }

    var allChannels: [ChannelDTO] {
        channels ?? []
    }

    /// Get programs for a specific channel
    func programsForChannel(id: String) -> [ProgramDTO] {
        programs?[id] ?? []
    }

    private static func mergeProgramsMap(into base: inout [String: [ProgramDTO]], from newMap: [String: [ProgramDTO]]) {
        for (key, values) in newMap {
            base[key] = mergeProgramLists(base[key] ?? [], values)
        }
    }

    private static func mergeProgramLists(_ lhs: [ProgramDTO], _ rhs: [ProgramDTO]) -> [ProgramDTO] {
        var result: [ProgramDTO] = []
        var seen = Set<ProgramDedupeKey>()

        for program in (lhs + rhs) {
            let key = ProgramDedupeKey(program)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(program)
        }

        return result.sorted {
            let lhsDate = $0.startDate ?? Date.distantPast
            let rhsDate = $1.startDate ?? Date.distantPast
            if lhsDate != rhsDate { return lhsDate < rhsDate }
            return $0.safeTitle < $1.safeTitle
        }
    }
}

struct ChannelWithProgramsDTO: Codable {
    let idValue: StringOrInt?
    let number: Int?
    let name: String?
    let logo: String?
    let programs: [ProgramDTO]?

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case number, name, logo, programs
    }

    var safeId: String { idValue?.stringValue ?? "" }
    var safeName: String { name ?? "Unknown" }
    var allPrograms: [ProgramDTO] { programs ?? [] }
}

// MARK: - Now Playing

struct NowPlayingResponse: Codable {
    let channels: [ChannelNowPlayingDTO]?
}

struct ChannelNowPlayingDTO: Codable {
    let channelId: String?
    let channelName: String?
    let channelLogo: String?
    let program: ProgramDTO?

    var safeChannelId: String { channelId ?? "" }
    var safeChannelName: String { channelName ?? "Unknown" }
}

// MARK: - Channel Stream

struct ChannelStreamResponse: Codable {
    let url: String
    let format: String?
}

// MARK: - Sources

struct M3USourcesResponse: Codable {
    let sources: [M3USourceDTO]
}

struct M3USourceDTO: Codable {
    let id: Int
    let name: String
    let url: String
    let epgUrl: String?
    let enabled: Bool?
    let lastFetched: String?
    let importVod: Bool?
    let importSeries: Bool?
    let vodLibraryId: Int?
    let seriesLibraryId: Int?
    let channelCount: Int?
}

struct XtreamSourcesResponse: Codable {
    let sources: [XtreamSourceDTO]
}

struct XtreamSourceDTO: Codable {
    let id: Int
    let name: String
    let serverUrl: String
    let username: String
    let enabled: Bool?
    let importLive: Bool?
    let importVod: Bool?
    let importSeries: Bool?
    let vodLibraryId: Int?
    let seriesLibraryId: Int?
    let channelCount: Int?
    let vodCount: Int?
    let seriesCount: Int?
    let lastFetched: String?
    let expirationDate: String?
    let createdAt: String?
}

// MARK: - EPG Sources

struct EPGSourcesResponse: Codable {
    let sources: [EPGSourceDTO]
}

struct EPGSourceDTO: Codable {
    let id: Int
    let name: String
    let url: String?
    let providerType: String?   // "xmltv", "gracenote", or "tvguide"
    let type: String?           // Legacy alias
    let enabled: Bool?
    let lastFetched: String?
    let channelCount: Int?
    let programCount: Int?
    // TVGuide-specific
    let tvguideProviderId: String?
    let tvguideZipCode: String?
    let tvguideDays: Int?

    /// Resolved type — prefers providerType, falls back to type
    var resolvedType: String {
        providerType ?? type ?? "xmltv"
    }
}

// MARK: - Live TV On Now

struct LiveTVOnNowResponse: Decodable {
    let channels: [ChannelDTO]?
}

// MARK: - TVGuide Provider Discovery

struct TVGuideProvidersResponse: Codable {
    let zipCode: String
    let count: Int
    let providers: [TVGuideProviderDTO]

    enum CodingKeys: String, CodingKey {
        case zipCode = "zipCode"
        case count, providers
    }
}

struct TVGuideProviderDTO: Codable, Identifiable {
    let id: Int64
    let name: String
    let type: String
    let city: String?
    let state: String?

    var displayName: String {
        if let city = city, let state = state {
            return "\(name) • \(city), \(state)"
        }
        return name
    }
}

// MARK: - Channel Groups

struct ChannelGroupsResponse: Codable {
    let groups: [ChannelGroupDTO]
}

struct ChannelGroupDTO: Codable {
    let id: Int
    let name: String
    let enabled: Bool?
    let members: [ChannelGroupMemberDTO]?
}

struct ChannelGroupMemberDTO: Codable {
    let channelId: String
    let priority: Int
    let channelName: String?
}

// MARK: - On Later

struct OnLaterStatsResponse: Codable {
    let all: Int?
    let movies: Int?
    let sports: Int?
    let kids: Int?
    let news: Int?
    let premieres: Int?
    let tvshows: Int?
}

struct OnLaterResponse: Codable {
    let items: [OnLaterProgramDTO]?
    let programs: [OnLaterProgramDTO]?  // fallback key
    let totalCount: Int?

    var allItems: [OnLaterProgramDTO] {
        items ?? programs ?? []
    }
}

struct OnLaterProgramDTO: Codable {
    let program: ProgramDTO
    let channel: ChannelDTO?
    let hasRecording: Bool?
    let recordingId: StringOrInt?
    // Legacy flattened fields
    let channelId: String?
    let channelName: String?
    let channelLogo: String?
    let channelNumber: Int?

    var safeChannelId: String { channel?.safeId ?? channelId ?? "" }
    var safeChannelName: String { channel?.safeName ?? channelName ?? "" }
    var safeChannelLogo: String? { channel?.logo ?? channel?.thumb ?? channelLogo }
}

// MARK: - Team Pass

struct TeamPassesResponse: Codable {
    let teamPasses: [TeamPassDTO]
}

struct TeamPassDTO: Codable {
    let id: Int
    let userId: Int?
    let teamName: String
    let teamAliases: String?
    let league: String
    let channelIds: String?
    let prePadding: Int?
    let postPadding: Int?
    let keepCount: Int?
    let priority: Int?
    let enabled: Bool?
    let upcomingCount: Int?
    let logoUrl: String?
}

struct TeamPassUpcomingResponse: Codable {
    let teamPass: TeamPassDTO?
    let games: [OnLaterProgramDTO]?

    var allGames: [OnLaterProgramDTO] {
        games ?? []
    }
}

struct LeaguesResponse: Codable {
    let leagues: [String]
}

struct TeamsResponse: Codable {
    let teams: [TeamDTO]
}

struct TeamDTO: Codable {
    let name: String
    let aliases: [String]?
    let logo: String?
}

// MARK: - Instant Switch (Prebuffer)

struct InstantSwitchStatusResponse: Codable {
    let success: Bool
    let data: InstantSwitchStatusData?
}

struct InstantSwitchStatusData: Codable {
    let enabled: Bool?
    let activeChannel: String?
    let cachedCount: Int?
    let maxStreams: Int?
    let maxMemory: Int?
}

struct InstantSwitchResponse: Codable {
    let success: Bool
    let channelId: String?
    let instant: Bool?
    let bufferedBytes: Int?
    let bufferedDuration: Double?
    let streamUrl: String?

    enum CodingKeys: String, CodingKey {
        case success
        case channelId = "channel_id"
        case instant
        case bufferedBytes = "buffered_bytes"
        case bufferedDuration = "buffered_duration"
        case streamUrl = "stream_url"
    }
}

struct InstantSwitchFavoritesResponse: Codable {
    let success: Bool
    let favorites: [String]?
}

struct InstantSwitchPredictionsResponse: Codable {
    let success: Bool
    let channelId: String?
    let predictions: [String]?

    enum CodingKeys: String, CodingKey {
        case success
        case channelId = "channel_id"
        case predictions
    }
}

struct InstantSwitchCachedResponse: Codable {
    let success: Bool
    let cached: [CachedStreamInfo]?
    let count: Int?
}

struct CachedStreamInfo: Codable {
    let channelId: String?
    let bufferedBytes: Int?
    let bufferedDuration: Double?
    let isLive: Bool?

    enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case bufferedBytes = "buffered_bytes"
        case bufferedDuration = "buffered_duration"
        case isLive = "is_live"
    }
}
