import Foundation

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
    let streamUrl: String?
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
        case sourceId, sourceName, streamUrl, enabled, hd, isFavorite
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
    let category: String?
    let isNew: Bool?
    let isLive: Bool?
    let isPremiere: Bool?
    let isFinale: Bool?
    let isSports: Bool?
    let isKids: Bool?
    let teams: String?
    let league: String?
    let hasRecording: Bool?
    let recordingId: StringOrInt?

    enum CodingKeys: String, CodingKey {
        case idValue = "id"
        case title, subtitle, description, start, end
        case startTime, endTime, duration, icon, art, rating, category
        case isNew, isLive, isPremiere, isFinale, isSports, isKids
        case teams, league, hasRecording, recordingId
    }

    var safeId: String { idValue?.stringValue ?? "" }
    var safeTitle: String { title ?? "Unknown Program" }

    var startDate: Date? {
        if let start = start {
            return ISO8601DateFormatter().date(from: start)
        }
        if let startTime = startTime {
            return Date(timeIntervalSince1970: TimeInterval(startTime))
        }
        return nil
    }

    var endDate: Date? {
        if let end = end {
            return ISO8601DateFormatter().date(from: end)
        }
        if let endTime = endTime {
            return Date(timeIntervalSince1970: TimeInterval(endTime))
        }
        return nil
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

        var programsValue = try? container.decode([String: [ProgramDTO]].self, forKey: .programs)
        if programsValue == nil || programsValue?.isEmpty == true {
            programsValue = (try? container.decode([String: [ProgramDTO]].self, forKey: .programsByChannel)) ?? programsValue
        }
        if programsValue == nil || programsValue?.isEmpty == true {
            programsValue = (try? container.decode([String: [ProgramDTO]].self, forKey: .programsByChannelSnake)) ?? programsValue
        }
        if programsValue == nil || programsValue?.isEmpty == true {
            programsValue = (try? container.decode([String: [ProgramDTO]].self, forKey: .programsMap)) ?? programsValue
        }

        if programsValue == nil || programsValue?.isEmpty == true,
           let channelsWithPrograms = try? container.decode([ChannelWithProgramsDTO].self, forKey: .channels) {
            var map: [String: [ProgramDTO]] = [:]
            for channel in channelsWithPrograms {
                let key: String
                if !channel.safeId.isEmpty {
                    key = channel.safeId
                } else if let number = channel.number {
                    key = String(number)
                } else {
                    continue
                }
                if !channel.allPrograms.isEmpty {
                    map[key] = channel.allPrograms
                }
            }
            if !map.isEmpty {
                programsValue = map
            }
        }

        programs = programsValue
    }

    var allChannels: [ChannelDTO] {
        channels ?? []
    }

    /// Get programs for a specific channel
    func programsForChannel(id: String) -> [ProgramDTO] {
        programs?[id] ?? []
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
