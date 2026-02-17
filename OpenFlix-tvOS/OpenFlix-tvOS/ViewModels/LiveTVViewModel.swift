import Foundation
import SwiftUI

@MainActor
class LiveTVViewModel: ObservableObject {
    private let liveTVRepository = LiveTVRepository()

    @Published var channels: [Channel] = []
    @Published var favoriteChannels: [Channel] = []
    @Published var selectedChannel: Channel?
    @Published var previousChannelId: String?  // For quick toggle between channels
    @Published var channelsByGroup: [String: [Channel]] = [:]
    @Published var availableGroups: [String] = []
    @Published var selectedGroup: String?
    @Published var sortOption: ChannelSortOption = .number
    @Published var isLoading = false
    @Published var error: String?

    // EPG
    @Published var guide: [ChannelWithPrograms] = []
    @Published var guideStartDate = Date()
    @Published var guideDays = 3
    @Published var debugInfo: String = ""

    // MARK: - Load Channels

    func loadChannels() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await liveTVRepository.loadChannels()
            channels = liveTVRepository.channels
            favoriteChannels = liveTVRepository.favoriteChannels

            channelsByGroup = liveTVRepository.getChannelsByGroup()
            availableGroups = Array(channelsByGroup.keys).sorted()

        } catch let networkError as NetworkError {
            error = networkError.errorDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refreshNowPlaying() async {
        do {
            let nowPlaying = try await liveTVRepository.getNowPlaying()

            // Update channel now playing info
            for (channel, program) in nowPlaying {
                if let index = channels.firstIndex(where: { $0.id == channel.id }) {
                    var updatedChannel = channels[index]
                    updatedChannel.nowPlaying = program
                    channels[index] = updatedChannel
                }
            }
        } catch {
            // Silently fail
        }
    }

    // MARK: - Channel Selection

    func selectChannel(_ channel: Channel) {
        // Save current channel as previous before switching
        if let current = selectedChannel, current.id != channel.id {
            previousChannelId = current.id
        }
        selectedChannel = channel
        UserDefaults.standard.lastChannelId = channel.id
    }

    /// Toggle between current and previous channel
    func togglePreviousChannel() -> Channel? {
        guard let prevId = previousChannelId,
              let prevChannel = channels.first(where: { $0.id == prevId }) else {
            return nil
        }

        // Swap: current becomes previous, previous becomes current
        let current = selectedChannel
        selectChannel(prevChannel)
        if let current = current {
            previousChannelId = current.id
        }
        return prevChannel
    }

    /// Get the last viewed channel (for previous channel toggle)
    var lastViewedChannel: Channel? {
        guard let prevId = previousChannelId else { return nil }
        return channels.first { $0.id == prevId }
    }

    func getChannelStream(_ channel: Channel) async throws -> URL {
        try await liveTVRepository.getChannelStream(id: channel.id)
    }

    // MARK: - Favorites

    func toggleFavorite(_ channel: Channel) async {
        do {
            try await liveTVRepository.toggleFavorite(channel: channel)
            channels = liveTVRepository.channels
            favoriteChannels = liveTVRepository.favoriteChannels
        } catch {
            // Silently fail
        }
    }

    // MARK: - EPG / Guide

    func loadGuide() async {
        do {
            let endDate = Calendar.current.date(byAdding: .day, value: guideDays, to: guideStartDate)
            guide = try await liveTVRepository.getGuide(start: guideStartDate, end: endDate)
            debugInfo = liveTVRepository.lastGuideDebug

            // Debug logging
            NSLog("GUIDE: Loaded %d channels", guide.count)
            for (index, cwp) in guide.prefix(3).enumerated() {
                NSLog("GUIDE: Channel[%d]: id=%@, name=%@, logo=%@, programs=%d", index, cwp.channel.id, cwp.channel.name, cwp.channel.logo ?? "nil", cwp.programs.count)
                if let firstProgram = cwp.programs.first {
                    NSLog("GUIDE:   First program: %@ @ %@", firstProgram.title, firstProgram.startTimeFormatted)
                }
            }
            NSLog("GUIDE: Loaded channels count: %d", channels.count)
            if let firstChannel = channels.first {
                NSLog("GUIDE: First channel: id=%@, logo=%@", firstChannel.id, firstChannel.logo ?? "nil")
            }

            // If guide returned channels without full info, merge with loaded channels
            if !channels.isEmpty {
                guide = guide.map { cwp in
                    // Find matching channel with full info (including logo)
                    if let fullChannel = channels.first(where: { $0.id == cwp.channel.id }) {
                        return ChannelWithPrograms(channel: fullChannel, programs: cwp.programs)
                    }
                    return cwp
                }
                NSLog("GUIDE: After merge, first channel logo: %@", guide.first?.channel.logo ?? "nil")
            }
        } catch let networkError as NetworkError {
            NSLog("GUIDE ERROR: %@", networkError.errorDescription ?? "unknown")
            // Fall back to using channels without program data
            if !channels.isEmpty {
                guide = channels.map { ChannelWithPrograms(channel: $0, programs: []) }
            }
        } catch {
            NSLog("GUIDE ERROR: %@", error.localizedDescription)
            // Fall back to using channels without program data
            if !channels.isEmpty {
                guide = channels.map { ChannelWithPrograms(channel: $0, programs: []) }
            }
        }
    }

    func loadChannelGuide(for channel: Channel) async -> [Program] {
        do {
            let endDate = Calendar.current.date(byAdding: .day, value: guideDays, to: guideStartDate)
            return try await liveTVRepository.getChannelGuide(channelId: channel.id, start: guideStartDate, end: endDate)
        } catch {
            return []
        }
    }

    // MARK: - Filtering & Sorting

    var displayedChannels: [Channel] {
        var result = channels

        // Filter by group
        if let group = selectedGroup {
            result = result.filter { $0.group == group }
        }

        // Sort
        result = liveTVRepository.sortedChannels(by: sortOption)

        return result
    }

    func filterByGroup(_ group: String?) {
        selectedGroup = group
    }

    func setSortOption(_ option: ChannelSortOption) {
        sortOption = option
    }

    // MARK: - Channel Surfing

    func nextChannel() -> Channel? {
        guard let current = selectedChannel,
              let currentIndex = displayedChannels.firstIndex(where: { $0.id == current.id }) else {
            return displayedChannels.first
        }

        let nextIndex = (currentIndex + 1) % displayedChannels.count
        return displayedChannels[nextIndex]
    }

    func previousChannel() -> Channel? {
        guard let current = selectedChannel,
              let currentIndex = displayedChannels.firstIndex(where: { $0.id == current.id }) else {
            return displayedChannels.last
        }

        let previousIndex = (currentIndex - 1 + displayedChannels.count) % displayedChannels.count
        return displayedChannels[previousIndex]
    }

    // MARK: - Last Watched

    func restoreLastChannel() -> Channel? {
        guard let lastId = UserDefaults.standard.lastChannelId else { return nil }
        return channels.first { $0.id == lastId }
    }
}
