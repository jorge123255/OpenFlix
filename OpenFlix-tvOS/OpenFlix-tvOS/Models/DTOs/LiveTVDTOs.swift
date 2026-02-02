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
        case tvgId
        case number, name, title, callsign, logo, thumb, art
        case sourceId, sourceName, streamUrl, enabled, hd, isFavorite
        case group, category, archiveEnabled, archiveDays
        case nowPlaying, nextProgram
    }

    var safeId: String { idValue?.stringValue ?? "" }
    var safeName: String { name ?? title ?? "Unknown Channel" }

    // EPG ID for program lookup - try tvgId first, then id
    var epgId: String { tvgId ?? idValue?.stringValue ?? "" }
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

struct GuideResponse: Codable {
    let channels: [ChannelDTO]?  // Basic channel info
    let programs: [String: [ProgramDTO]]?  // Programs map keyed by channel ID
    let start: String?
    let end: String?

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
    let url: String
    let type: String    // "xmltv" or "gracenote"
    let enabled: Bool?
    let lastFetched: String?
    let channelCount: Int?
    let programCount: Int?
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
    let movies: Int
    let sports: Int
    let kids: Int
    let news: Int
    let premieres: Int
}

struct OnLaterResponse: Codable {
    let programs: [OnLaterProgramDTO]
}

struct OnLaterProgramDTO: Codable {
    let channelId: String
    let channelName: String
    let channelLogo: String?
    let channelNumber: Int?
    let program: ProgramDTO
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
