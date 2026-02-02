import Foundation

// MARK: - Channel

struct Channel: Identifiable, Hashable {
    let id: String
    let number: Int?
    let name: String
    let logo: String?
    let sourceId: String?
    let sourceName: String?
    let streamUrl: String?
    let enabled: Bool
    let isFavorite: Bool
    let group: String?
    let archiveEnabled: Bool
    let archiveDays: Int
    var nowPlaying: Program?
    var nextProgram: Program?

    // MARK: - Computed Properties

    var displayNumber: String {
        if let number = number {
            return "\(number)"
        }
        return ""
    }

    var displayName: String {
        if let number = number {
            return "\(number) - \(name)"
        }
        return name
    }

    var isHD: Bool {
        name.uppercased().contains("HD") ||
        name.uppercased().contains("FHD") ||
        name.uppercased().contains("4K") ||
        name.uppercased().contains("UHD")
    }

    var sortKey: Double {
        Double(number ?? Int.max)
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Channel, rhs: Channel) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DTO Mapping

extension ChannelDTO {
    func toDomain() -> Channel {
        Channel(
            id: safeId,
            number: number,
            name: safeName,
            logo: logo ?? thumb,
            sourceId: sourceId?.stringValue,
            sourceName: sourceName,
            streamUrl: streamUrl,
            enabled: enabled ?? true,
            isFavorite: isFavorite ?? false,
            group: group ?? category,
            archiveEnabled: archiveEnabled ?? false,
            archiveDays: archiveDays ?? 0,
            nowPlaying: nowPlaying?.toDomain(),
            nextProgram: nextProgram?.toDomain()
        )
    }
}

// MARK: - Channel Group

struct ChannelGroup: Identifiable {
    let id: Int
    let name: String
    let enabled: Bool
    let members: [ChannelGroupMember]
}

struct ChannelGroupMember: Identifiable {
    var id: String { channelId }
    let channelId: String
    let priority: Int
    let channelName: String?
}

extension ChannelGroupDTO {
    func toDomain() -> ChannelGroup {
        ChannelGroup(
            id: id,
            name: name,
            enabled: enabled ?? true,
            members: members?.map { ChannelGroupMember(channelId: $0.channelId, priority: $0.priority, channelName: $0.channelName) } ?? []
        )
    }
}
