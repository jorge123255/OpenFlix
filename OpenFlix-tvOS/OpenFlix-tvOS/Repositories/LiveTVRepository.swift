import Foundation

@MainActor
class LiveTVRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published var channels: [Channel] = []
    @Published var favoriteChannels: [Channel] = []

    // MARK: - Channels

    func loadChannels() async throws {
        let response = try await api.getChannels()
        channels = response.allChannels.map { $0.toDomain() }.filter { $0.enabled }
        updateFavorites()
    }

    func getChannel(id: String) -> Channel? {
        channels.first { $0.id == id }
    }

    func getChannelStream(id: String) async throws -> URL {
        // First try to get the stream URL from the cached channel data (like Android does)
        if let channel = channels.first(where: { $0.id == id }),
           let streamUrl = channel.streamUrl,
           let url = URL(string: streamUrl) {
            return url
        }

        // Fallback: Try the API endpoint (proxied stream)
        // Note: This returns the proxied stream URL through our server
        let response = try await api.getChannelStream(id: id)
        guard let url = URL(string: response.url) else {
            throw NetworkError.invalidURL
        }
        return url
    }

    /// Get stream URL for a channel directly from the channel data
    func getStreamURL(for channel: Channel) -> URL? {
        guard let streamUrl = channel.streamUrl else { return nil }
        return URL(string: streamUrl)
    }

    func toggleFavorite(channel: Channel) async throws {
        try await api.toggleFavorite(channelId: channel.id)

        // Update local state
        if let index = channels.firstIndex(where: { $0.id == channel.id }) {
            var updatedChannel = channels[index]
            updatedChannel = Channel(
                id: updatedChannel.id,
                number: updatedChannel.number,
                name: updatedChannel.name,
                logo: updatedChannel.logo,
                sourceId: updatedChannel.sourceId,
                sourceName: updatedChannel.sourceName,
                streamUrl: updatedChannel.streamUrl,
                enabled: updatedChannel.enabled,
                isFavorite: !updatedChannel.isFavorite,
                group: updatedChannel.group,
                archiveEnabled: updatedChannel.archiveEnabled,
                archiveDays: updatedChannel.archiveDays,
                nowPlaying: updatedChannel.nowPlaying,
                nextProgram: updatedChannel.nextProgram
            )
            channels[index] = updatedChannel
        }
        updateFavorites()
    }

    private func updateFavorites() {
        favoriteChannels = channels.filter { $0.isFavorite }
    }

    // MARK: - Channel Groups

    func getChannelsByGroup() -> [String: [Channel]] {
        var groups: [String: [Channel]] = [:]
        for channel in channels {
            let group = channel.group ?? "Uncategorized"
            if groups[group] == nil {
                groups[group] = []
            }
            groups[group]?.append(channel)
        }
        // Sort channels within each group by number
        for (key, value) in groups {
            groups[key] = value.sorted { $0.sortKey < $1.sortKey }
        }
        return groups
    }

    // MARK: - EPG / Guide

    // Debug info from last guide load
    var lastGuideDebug: String = ""

    func getGuide(start: Date? = nil, end: Date? = nil) async throws -> [ChannelWithPrograms] {
        let response = try await api.getGuide(start: start, end: end)

        // Build debug info - show epgId vs id to diagnose program lookup
        let programsMapCount = response.programs?.count ?? 0
        let programsMapKeys = response.programs?.keys.prefix(3).joined(separator: ", ") ?? "none"
        let firstChannel = response.allChannels.first
        let firstEpgId = firstChannel?.epgId ?? "none"
        let firstId = firstChannel?.safeId ?? "none"
        let firstChannelLogo = firstChannel?.logo ?? "nil"
        lastGuideDebug = "MapKeys:\(programsMapCount) [\(programsMapKeys)] | epg:'\(firstEpgId)' id:'\(firstId)' logo:\(firstChannelLogo)"

        var result: [ChannelWithPrograms] = []

        // The guide endpoint returns:
        // - channels: basic channel info (ChannelDTO)
        // - programs: map of tvgId (EPG channel ID) -> [ProgramDTO]
        for channelDTO in response.allChannels {
            let channel = Channel(
                id: channelDTO.safeId,
                number: channelDTO.number,
                name: channelDTO.safeName,
                logo: channelDTO.logo ?? channelDTO.thumb,
                sourceId: channelDTO.sourceId?.stringValue,
                sourceName: channelDTO.sourceName,
                streamUrl: channelDTO.streamUrl,
                enabled: channelDTO.enabled ?? true,
                isFavorite: channelDTO.isFavorite ?? false,
                group: channelDTO.group ?? channelDTO.category,
                archiveEnabled: channelDTO.archiveEnabled ?? false,
                archiveDays: channelDTO.archiveDays ?? 0,
                nowPlaying: channelDTO.nowPlaying?.toDomain(),
                nextProgram: channelDTO.nextProgram?.toDomain()
            )

            // Get programs from the programs map using EPG ID (tvgId), then fall back to database id
            var programs = response.programsForChannel(id: channelDTO.epgId).map { $0.toDomain() }

            // If no programs found with epgId, try with the database id
            if programs.isEmpty && channelDTO.tvgId != nil {
                programs = response.programsForChannel(id: channelDTO.safeId).map { $0.toDomain() }
            }

            result.append(ChannelWithPrograms(channel: channel, programs: programs))
        }

        // If guide response was empty, fall back to using existing channels with empty programs
        if result.isEmpty && !channels.isEmpty {
            result = channels.map { ChannelWithPrograms(channel: $0, programs: []) }
        }

        return result
    }

    func getChannelGuide(channelId: String, start: Date? = nil, end: Date? = nil) async throws -> [Program] {
        // Uses the channel-specific guide endpoint
        let response: GuideResponse = try await api.request(.getChannelGuide(channelId: channelId, start: start, end: end))
        // Programs are in the programs map keyed by channel ID
        return response.programsForChannel(id: channelId).map { $0.toDomain() }
    }

    func getNowPlaying() async throws -> [(channel: Channel, program: Program?)] {
        let response = try await api.getNowPlaying()
        return (response.channels ?? []).compactMap { dto in
            let channel = Channel(
                id: dto.safeChannelId,
                number: nil,
                name: dto.safeChannelName,
                logo: dto.channelLogo,
                sourceId: nil,
                sourceName: nil,
                streamUrl: nil,
                enabled: true,
                isFavorite: false,
                group: nil,
                archiveEnabled: false,
                archiveDays: 0,
                nowPlaying: nil,
                nextProgram: nil
            )
            return (channel, dto.program?.toDomain())
        }
    }

    // MARK: - Sorting & Filtering

    func sortedChannels(by sort: ChannelSortOption) -> [Channel] {
        switch sort {
        case .number:
            return channels.sorted { $0.sortKey < $1.sortKey }
        case .name:
            return channels.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .favorites, .favorite:
            return channels.sorted { ($0.isFavorite ? 0 : 1) < ($1.isFavorite ? 0 : 1) }
        case .recent:
            // Sort by recently watched (for now just use number sort)
            return channels.sorted { $0.sortKey < $1.sortKey }
        }
    }

    func filteredChannels(group: String?) -> [Channel] {
        guard let group = group else { return channels }
        return channels.filter { $0.group == group }
    }

    // MARK: - Start Over / Timeshift

    func getStartOverInfo(channelId: String) async throws -> StartOverInfo {
        let response: StartOverInfoResponse = try await api.request(.getStartover(channelId: channelId))
        return response.info
    }
}

enum ChannelSortOption: String, CaseIterable {
    case number = "Number"
    case name = "Name"
    case favorites = "Favorites"
    case favorite = "Favorite"
    case recent = "Recent"
}
