import Foundation
import SwiftUI
import os

@MainActor
class LiveTVViewModel: ObservableObject {
    private let liveTVRepository = LiveTVRepository()
    private let tunerBackendStore = TunerBackendStore.shared
    private static let logger = Logger(subsystem: "com.openflix.livetv", category: "Guide")

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
    @Published var guideStartDate = Calendar.current.startOfDay(for: Date())
    @Published var guideDays = 14
    @Published var debugInfo: String = ""
    @Published var isGuideLoading = false
    @Published var didLoadGuide = false
    @Published var liveRefreshTick: Int = 0
    @Published var activeTunerBackend: TunerBackend?
    private var guideCacheDate: Date?
    private var guideLoadedEnd: Date?
    private var liveRefreshTimer: Timer?

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

    func loadActiveTunerBackend() async {
        do {
            try await tunerBackendStore.load()
            activeTunerBackend = tunerBackendStore.activeBackend
        } catch {
            activeTunerBackend = nil
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

    func getChannelPreviewStream(_ channel: Channel) async throws -> URL {
        if let url = liveTVRepository.getPreviewURL(for: channel) {
            return url
        }
        return try await getChannelStream(channel)
    }

    func getChannelBrowserPreviewStream(_ channel: Channel) async throws -> URL {
        if let url = liveTVRepository.getBrowserPreviewURL(for: channel) {
            return url
        }
        return try await getChannelPreviewStream(channel)
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

    func loadGuide(force: Bool = false) async {
        // Skip if cached data is fresh (within 5 minutes)
        if !force, let cacheDate = guideCacheDate, !guide.isEmpty,
           Date().timeIntervalSince(cacheDate) < 300 {
            return
        }

        isGuideLoading = true
        defer { isGuideLoading = false }

        do {
            // Channels must be loaded first so programs can be matched to them
            if channels.isEmpty {
                try await liveTVRepository.loadChannels()
                channels = liveTVRepository.channels
            }

            if activeTunerBackend == nil {
                await loadActiveTunerBackend()
            }

            let endDate = Calendar.current.date(byAdding: .day, value: guideDays, to: guideStartDate)
            guide = try await liveTVRepository.getGuide(start: guideStartDate, end: endDate)
            guideCacheDate = Date()
            guideLoadedEnd = endDate
            debugInfo = liveTVRepository.lastGuideDebug
            didLoadGuide = true
            startLiveRefreshTimer()

            Self.logger.debug("GUIDE: Loaded \(self.guide.count) channels")
            for (index, cwp) in self.guide.prefix(3).enumerated() {
                Self.logger.debug("GUIDE: Channel[\(index)]: id=\(cwp.channel.id), name=\(cwp.channel.name), logo=\(cwp.channel.logo ?? "nil"), programs=\(cwp.programs.count)")
                if let firstProgram = cwp.programs.first {
                    Self.logger.debug("GUIDE:   First program: \(firstProgram.title) @ \(firstProgram.startTimeFormatted)")
                }
            }
            Self.logger.debug("GUIDE: Loaded channels count: \(self.channels.count)")
            if let firstChannel = self.channels.first {
                Self.logger.debug("GUIDE: First channel: id=\(firstChannel.id), logo=\(firstChannel.logo ?? "nil")")
            }

            // If guide returned channels without full info, merge with loaded channels
            if !channels.isEmpty {
                // Dictionary lookup keeps this O(n); a linear scan here is O(n²) and stalls the UI for thousands of channels.
                let channelsById = Dictionary(uniqueKeysWithValues: channels.map { ($0.id, $0) })
                guide = guide.map { cwp in
                    if let fullChannel = channelsById[cwp.channel.id] {
                        return ChannelWithPrograms(channel: fullChannel, programs: cwp.programs)
                    }
                    return cwp
                }
            }
        } catch let networkError as NetworkError {
            Self.logger.error("GUIDE ERROR: \(networkError.errorDescription ?? "unknown")")
            didLoadGuide = true
            // Fall back to using channels without program data
            if !channels.isEmpty {
                guide = channels.map { ChannelWithPrograms(channel: $0, programs: []) }
            }
        } catch {
            Self.logger.error("GUIDE ERROR: \(error.localizedDescription)")
            didLoadGuide = true
            // Fall back to using channels without program data
            if !channels.isEmpty {
                guide = channels.map { ChannelWithPrograms(channel: $0, programs: []) }
            }
        }
    }

    func loadGuideForDate(_ date: Date) async {
        guideStartDate = Calendar.current.startOfDay(for: date)
        guideDays = 14
        await loadGuide(force: true)
    }

    /// Extend guide data forward if the user pages past what's loaded
    func extendGuideIfNeeded(pastDate: Date) async {
        guard let loadedEnd = guideLoadedEnd, pastDate > loadedEnd else { return }
        // Extend by another day
        guideDays = max(guideDays, Int(ceil(pastDate.timeIntervalSince(guideStartDate) / 86400)) + 1)
        await loadGuide(force: true)
    }

    func loadChannelGuide(for channel: Channel) async -> [Program] {
        do {
            let endDate = Calendar.current.date(byAdding: .day, value: guideDays, to: guideStartDate)
            return try await liveTVRepository.getChannelGuide(channelId: channel.id, start: guideStartDate, end: endDate)
        } catch {
            return []
        }
    }

    func providerAccount(for channel: Channel) -> TunerBackendProviderAccount? {
        if activeTunerBackend == nil {
            activeTunerBackend = tunerBackendStore.activeBackend
        }
        return tunerBackendStore.providerAccount(for: channel)
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

    // MARK: - Live Refresh Timer

    private func startLiveRefreshTimer() {
        stopLiveRefreshTimer()
        liveRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.liveRefreshTick += 1
            }
        }
    }

    func stopLiveRefreshTimer() {
        liveRefreshTimer?.invalidate()
        liveRefreshTimer = nil
    }

    deinit {
        liveRefreshTimer?.invalidate()
        liveRefreshTimer = nil
    }
}
