import Foundation
import AVKit
import Combine

/// Layout options for multiview
enum MultiviewLayout: String, CaseIterable {
    case single = "single"
    case twoByOne = "2x1"      // Side by side
    case oneByTwo = "1x2"      // Stacked
    case threeGrid = "2+1"     // 2 top, 1 bottom
    case twoByTwo = "2x2"      // 4 quadrants

    var maxSlots: Int {
        switch self {
        case .single: return 1
        case .twoByOne, .oneByTwo: return 2
        case .threeGrid: return 3
        case .twoByTwo: return 4
        }
    }

    var icon: String {
        switch self {
        case .single: return "rectangle"
        case .twoByOne: return "rectangle.split.2x1"
        case .oneByTwo: return "rectangle.split.1x2"
        case .threeGrid: return "rectangle.split.2x2"
        case .twoByTwo: return "rectangle.split.2x2.fill"
        }
    }
}

/// DVR state for a multiview slot
struct SlotDVRState {
    var isPaused: Bool = false
    var isLive: Bool = true
    var liveOffsetSecs: Int = 0
    var playbackSpeed: Float = 1.0
    var bufferSecs: Int = 1800 // 30 minutes default
}

/// Represents one slot in the multiview grid
struct MultiviewSlot: Identifiable {
    let id = UUID()
    var index: Int
    var channel: Channel
    var player: AVPlayer?
    var isReady: Bool = false
    var isMuted: Bool = true
    var isTimeshifted: Bool = false
    var timeshiftProgramTitle: String?
    var isBuffering: Bool = false
    var dvrState: SlotDVRState = SlotDVRState()
}

@MainActor
class MultiviewViewModel: ObservableObject {
    private let liveTVRepository = LiveTVRepository()

    @Published var slots: [MultiviewSlot] = []
    @Published var allChannels: [Channel] = []
    @Published var layout: MultiviewLayout = .twoByOne
    @Published var focusedSlotIndex: Int = 0
    @Published var showControls: Bool = true
    @Published var channelPickerSlotIndex: Int? = nil
    @Published var isLoading = false
    @Published var error: String?

    private var controlsHideTask: Task<Void, Never>?

    // MARK: - Initialization

    func loadChannels() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await liveTVRepository.loadChannels()
            allChannels = liveTVRepository.channels
        } catch {
            self.error = error.localizedDescription
        }
    }

    func initializeSlots(initialChannelIds: [String] = []) {
        guard !allChannels.isEmpty else { return }

        // Find initial channels or use first few
        var channelsToUse: [Channel] = []

        for id in initialChannelIds {
            if let channel = allChannels.first(where: { $0.id == id }) {
                channelsToUse.append(channel)
            }
        }

        // If no initial channels, use first 2
        if channelsToUse.isEmpty {
            channelsToUse = Array(allChannels.prefix(2))
        }

        // Create slots
        slots = channelsToUse.enumerated().map { index, channel in
            var slot = MultiviewSlot(index: index, channel: channel)
            slot.player = createPlayer(for: channel)
            return slot
        }

        // Set layout based on slot count
        layout = layoutForSlotCount(slots.count)

        // Start playing
        for i in slots.indices {
            startPlaying(slot: i)
        }
    }

    // MARK: - Player Management

    private func createPlayer(for channel: Channel) -> AVPlayer? {
        guard let streamUrl = channel.streamUrl, let url = URL(string: streamUrl) else {
            return nil
        }

        let player = AVPlayer(url: url)
        player.isMuted = true // Start muted
        return player
    }

    private func startPlaying(slot index: Int) {
        guard index < slots.count else { return }
        slots[index].player?.play()
        slots[index].isReady = true
    }

    func getPlayer(for slotIndex: Int) -> AVPlayer? {
        guard slotIndex < slots.count else { return nil }
        return slots[slotIndex].player
    }

    // MARK: - Focus Management

    func setFocusedSlot(_ index: Int) {
        guard index >= 0 && index < slots.count else { return }
        focusedSlotIndex = index
    }

    // MARK: - Channel Surfing

    func changeChannelInSlot(_ slotIndex: Int, direction: Int) {
        guard slotIndex < slots.count else { return }

        let currentChannel = slots[slotIndex].channel
        guard let currentIndex = allChannels.firstIndex(where: { $0.id == currentChannel.id }) else { return }

        var newIndex = currentIndex + direction
        if newIndex < 0 { newIndex = allChannels.count - 1 }
        if newIndex >= allChannels.count { newIndex = 0 }

        let newChannel = allChannels[newIndex]
        swapChannel(slotIndex, newChannel: newChannel)
    }

    func swapChannel(_ slotIndex: Int, newChannel: Channel) {
        guard slotIndex < slots.count else { return }

        // Stop old player
        slots[slotIndex].player?.pause()

        // Create new player
        slots[slotIndex].channel = newChannel
        slots[slotIndex].player = createPlayer(for: newChannel)
        slots[slotIndex].isReady = false
        slots[slotIndex].isTimeshifted = false
        slots[slotIndex].timeshiftProgramTitle = nil

        // Start playing
        startPlaying(slot: slotIndex)
    }

    // MARK: - Slot Management

    func addSlot() {
        guard slots.count < 4 else { return }

        // Find a channel not already in use
        let usedChannelIds = Set(slots.map { $0.channel.id })
        guard let newChannel = allChannels.first(where: { !usedChannelIds.contains($0.id) }) ?? allChannels.first else {
            return
        }

        var slot = MultiviewSlot(index: slots.count, channel: newChannel)
        slot.player = createPlayer(for: newChannel)
        slots.append(slot)

        // Update layout
        layout = layoutForSlotCount(slots.count)

        // Start playing
        startPlaying(slot: slots.count - 1)
    }

    func removeSlot(_ slotIndex: Int) {
        guard slots.count > 1, slotIndex < slots.count else { return }

        // Stop and release player
        slots[slotIndex].player?.pause()
        slots[slotIndex].player = nil

        // Remove slot
        slots.remove(at: slotIndex)

        // Reindex remaining slots
        for i in slots.indices {
            slots[i].index = i
        }

        // Update layout
        layout = layoutForSlotCount(slots.count)

        // Adjust focus if needed
        if focusedSlotIndex >= slots.count {
            focusedSlotIndex = slots.count - 1
        }
    }

    // MARK: - Audio Control

    func toggleMuteOnSlot(_ slotIndex: Int) {
        guard slotIndex < slots.count else { return }

        let currentlyMuted = slots[slotIndex].isMuted

        // If unmuting this slot, mute all others first
        if currentlyMuted {
            for i in slots.indices {
                slots[i].isMuted = true
                slots[i].player?.isMuted = true
            }
        }

        // Toggle this slot
        slots[slotIndex].isMuted = !currentlyMuted
        slots[slotIndex].player?.isMuted = !currentlyMuted
    }

    func setAudioFocus(_ slotIndex: Int) {
        guard slotIndex < slots.count else { return }

        // Mute all slots
        for i in slots.indices {
            slots[i].isMuted = true
            slots[i].player?.isMuted = true
        }

        // Unmute focused slot
        slots[slotIndex].isMuted = false
        slots[slotIndex].player?.isMuted = false
    }

    // MARK: - Layout Control

    func cycleLayout() {
        let layouts = MultiviewLayout.allCases.filter { $0.maxSlots >= slots.count }
        guard let currentIndex = layouts.firstIndex(of: layout) else {
            layout = layouts.first ?? .twoByOne
            return
        }

        let nextIndex = (currentIndex + 1) % layouts.count
        layout = layouts[nextIndex]
    }

    private func layoutForSlotCount(_ count: Int) -> MultiviewLayout {
        switch count {
        case 1: return .single
        case 2: return .twoByOne
        case 3: return .threeGrid
        default: return .twoByTwo
        }
    }

    // MARK: - Timeshift / Start Over

    func startOverSlot(_ slotIndex: Int) async {
        guard slotIndex < slots.count else { return }

        let channel = slots[slotIndex].channel

        do {
            let startOverInfo = try await liveTVRepository.getStartOverInfo(channelId: channel.id)

            if startOverInfo.available, let streamUrlString = startOverInfo.streamUrl,
               let url = URL(string: streamUrlString) {
                // Stop current player
                slots[slotIndex].player?.pause()

                // Create new player with timeshift URL
                slots[slotIndex].player = AVPlayer(url: url)
                slots[slotIndex].isTimeshifted = true
                slots[slotIndex].timeshiftProgramTitle = startOverInfo.programTitle

                // Start playing
                slots[slotIndex].player?.play()
                slots[slotIndex].player?.isMuted = slots[slotIndex].isMuted
            }
        } catch {
            // Silently fail
        }
    }

    func goLiveSlot(_ slotIndex: Int) {
        guard slotIndex < slots.count else { return }

        let channel = slots[slotIndex].channel

        // Stop current player
        slots[slotIndex].player?.pause()

        // Create new player with live URL
        slots[slotIndex].player = createPlayer(for: channel)
        slots[slotIndex].isTimeshifted = false
        slots[slotIndex].timeshiftProgramTitle = nil

        // Start playing
        startPlaying(slot: slotIndex)
    }

    // MARK: - Controls Visibility

    func showControlsTemporarily() {
        showControls = true
        scheduleHideControls()
    }

    func hideControlsNow() {
        showControls = false
    }

    private func scheduleHideControls() {
        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000) // 8 seconds
            if !Task.isCancelled {
                showControls = false
            }
        }
    }

    // MARK: - Channel Picker

    func showChannelPicker(for slotIndex: Int) {
        channelPickerSlotIndex = slotIndex
    }

    func hideChannelPicker() {
        channelPickerSlotIndex = nil
    }

    // MARK: - DVR Controls (Key Differentiator vs Channels DVR!)

    /// Pause a specific slot - Channels DVR CAN'T do this!
    func pauseSlot(_ slotIndex: Int) {
        guard slotIndex < slots.count else { return }
        slots[slotIndex].player?.pause()
        slots[slotIndex].dvrState.isPaused = true
        slots[slotIndex].dvrState.isLive = false
    }

    /// Resume a paused slot
    func resumeSlot(_ slotIndex: Int) {
        guard slotIndex < slots.count else { return }
        slots[slotIndex].player?.play()
        slots[slotIndex].dvrState.isPaused = false
    }

    /// Toggle pause on a slot
    func togglePauseSlot(_ slotIndex: Int) {
        guard slotIndex < slots.count else { return }
        if slots[slotIndex].dvrState.isPaused {
            resumeSlot(slotIndex)
        } else {
            pauseSlot(slotIndex)
        }
    }

    /// Rewind a slot by seconds - Channels DVR CAN'T do this!
    func rewindSlot(_ slotIndex: Int, seconds: Double = 15) {
        guard slotIndex < slots.count,
              let player = slots[slotIndex].player else { return }

        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTimeMakeWithSeconds(seconds, preferredTimescale: 600))
        player.seek(to: newTime)

        slots[slotIndex].dvrState.isLive = false
        slots[slotIndex].dvrState.liveOffsetSecs += Int(seconds)
    }

    /// Fast forward a slot
    func fastForwardSlot(_ slotIndex: Int, seconds: Double = 15) {
        guard slotIndex < slots.count,
              let player = slots[slotIndex].player else { return }

        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTimeMakeWithSeconds(seconds, preferredTimescale: 600))
        player.seek(to: newTime)

        slots[slotIndex].dvrState.liveOffsetSecs = max(0, slots[slotIndex].dvrState.liveOffsetSecs - Int(seconds))
        if slots[slotIndex].dvrState.liveOffsetSecs == 0 {
            slots[slotIndex].dvrState.isLive = true
        }
    }

    /// Jump a slot back to live
    func jumpToLiveSlot(_ slotIndex: Int) {
        guard slotIndex < slots.count,
              let player = slots[slotIndex].player,
              let duration = player.currentItem?.duration else { return }

        player.seek(to: duration)
        slots[slotIndex].dvrState.isLive = true
        slots[slotIndex].dvrState.liveOffsetSecs = 0
        slots[slotIndex].dvrState.isPaused = false
        player.play()
    }

    /// PAUSE ALL streams - one button convenience!
    func pauseAll() {
        for i in slots.indices {
            pauseSlot(i)
        }
    }

    /// RESUME ALL streams
    func resumeAll() {
        for i in slots.indices {
            resumeSlot(i)
        }
    }

    /// JUMP ALL TO LIVE - sync all streams to live
    func jumpAllToLive() {
        for i in slots.indices {
            jumpToLiveSlot(i)
        }
    }

    /// SYNC all streams - align timestamps
    func syncAllStreams() {
        // Find the stream that's furthest behind live
        var maxOffset = 0
        for slot in slots {
            if slot.dvrState.liveOffsetSecs > maxOffset {
                maxOffset = slot.dvrState.liveOffsetSecs
            }
        }

        // Rewind all streams to match
        for i in slots.indices {
            let currentOffset = slots[i].dvrState.liveOffsetSecs
            if currentOffset < maxOffset {
                let rewindAmount = Double(maxOffset - currentOffset)
                rewindSlot(i, seconds: rewindAmount)
            }
        }
    }

    /// Check if any slot is paused
    var anySlotPaused: Bool {
        slots.contains { $0.dvrState.isPaused }
    }

    /// Check if all slots are live
    var allSlotsLive: Bool {
        slots.allSatisfy { $0.dvrState.isLive }
    }

    // MARK: - Cleanup

    func cleanup() {
        controlsHideTask?.cancel()

        for slot in slots {
            slot.player?.pause()
        }
        slots.removeAll()
    }
}
