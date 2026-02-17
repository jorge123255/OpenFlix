import Foundation

// MARK: - M3U Source

struct M3USource: Identifiable, Hashable {
    let id: Int
    let name: String
    let url: String
    let epgUrl: String?
    let enabled: Bool
    let lastFetched: Date?
    let importVod: Bool
    let importSeries: Bool
    let vodLibraryId: Int?
    let seriesLibraryId: Int?
    let channelCount: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: M3USource, rhs: M3USource) -> Bool {
        lhs.id == rhs.id
    }
}

extension M3USourceDTO {
    func toDomain() -> M3USource {
        M3USource(
            id: id,
            name: name,
            url: url,
            epgUrl: epgUrl,
            enabled: enabled ?? true,
            lastFetched: lastFetched != nil ? ISO8601DateFormatter().date(from: lastFetched!) : nil,
            importVod: importVod ?? false,
            importSeries: importSeries ?? false,
            vodLibraryId: vodLibraryId,
            seriesLibraryId: seriesLibraryId,
            channelCount: channelCount ?? 0
        )
    }
}

// MARK: - Xtream Source

struct XtreamSource: Identifiable, Hashable {
    let id: Int
    let name: String
    let serverUrl: String
    let username: String
    let enabled: Bool
    let importLive: Bool
    let importVod: Bool
    let importSeries: Bool
    let vodLibraryId: Int?
    let seriesLibraryId: Int?
    let channelCount: Int
    let vodCount: Int
    let seriesCount: Int
    let lastFetched: Date?
    let expirationDate: Date?
    let createdAt: Date?

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < Date()
    }

    var expiresInDays: Int? {
        guard let expiration = expirationDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day
        return days
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: XtreamSource, rhs: XtreamSource) -> Bool {
        lhs.id == rhs.id
    }
}

extension XtreamSourceDTO {
    func toDomain() -> XtreamSource {
        XtreamSource(
            id: id,
            name: name,
            serverUrl: serverUrl,
            username: username,
            enabled: enabled ?? true,
            importLive: importLive ?? true,
            importVod: importVod ?? false,
            importSeries: importSeries ?? false,
            vodLibraryId: vodLibraryId,
            seriesLibraryId: seriesLibraryId,
            channelCount: channelCount ?? 0,
            vodCount: vodCount ?? 0,
            seriesCount: seriesCount ?? 0,
            lastFetched: lastFetched != nil ? ISO8601DateFormatter().date(from: lastFetched!) : nil,
            expirationDate: expirationDate != nil ? ISO8601DateFormatter().date(from: expirationDate!) : nil,
            createdAt: createdAt != nil ? ISO8601DateFormatter().date(from: createdAt!) : nil
        )
    }
}

// MARK: - EPG Source

struct EPGSource: Identifiable, Hashable {
    let id: Int
    let name: String
    let url: String
    let type: EPGSourceType
    let enabled: Bool
    let lastFetched: Date?
    let channelCount: Int
    let programCount: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: EPGSource, rhs: EPGSource) -> Bool {
        lhs.id == rhs.id
    }
}

enum EPGSourceType: String, Codable {
    case xmltv
    case gracenote

    var displayName: String {
        switch self {
        case .xmltv: return "XMLTV"
        case .gracenote: return "Gracenote"
        }
    }
}

extension EPGSourceDTO {
    func toDomain() -> EPGSource {
        EPGSource(
            id: id,
            name: name,
            url: url,
            type: EPGSourceType(rawValue: type) ?? .xmltv,
            enabled: enabled ?? true,
            lastFetched: lastFetched != nil ? ISO8601DateFormatter().date(from: lastFetched!) : nil,
            channelCount: channelCount ?? 0,
            programCount: programCount ?? 0
        )
    }
}

// MARK: - Server Capabilities

struct ServerCapabilities {
    let liveTV: Bool
    let dvr: Bool
    let transcoding: Bool
    let offlineDownloads: Bool
    let multiUser: Bool
    let watchParty: Bool
    let epgSources: [String]
}

extension ServerCapabilitiesDTO {
    func toDomain() -> ServerCapabilities {
        ServerCapabilities(
            liveTV: liveTV ?? false,
            dvr: dvr ?? false,
            transcoding: transcoding ?? false,
            offlineDownloads: offlineDownloads ?? false,
            multiUser: multiUser ?? false,
            watchParty: watchParty ?? false,
            epgSources: epgSources ?? []
        )
    }
}

// MARK: - Server Info

struct ServerInfo {
    let name: String
    let version: String
    let platform: String
    let machineIdentifier: String
    let isOwner: Bool
    let transcoderActive: Bool
}

extension ServerInfoDTO {
    func toDomain() -> ServerInfo {
        ServerInfo(
            name: name ?? "OpenFlix Server",
            version: version ?? "Unknown",
            platform: platform ?? "Unknown",
            machineIdentifier: machineIdentifier ?? UUID().uuidString,
            isOwner: owner ?? false,
            transcoderActive: transcoderActive ?? false
        )
    }
}
