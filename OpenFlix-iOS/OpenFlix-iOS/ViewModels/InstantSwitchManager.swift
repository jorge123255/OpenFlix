import Foundation
import AVKit
import os.log

private let logger = Logger(subsystem: "com.openflix.tvos", category: "InstantSwitch")

/// Manages pre-buffering of adjacent channels for instant channel switching
/// Similar to Tivimate's "Instant Switch" feature
@MainActor
class InstantSwitchManager: ObservableObject {

    // MARK: - Types

    struct BufferedChannel {
        let channel: Channel
        let player: AVPlayer
        let playerItem: AVPlayerItem
        var isReady: Bool = false
        var error: Error?
    }

    // MARK: - Published Properties

    @Published private(set) var bufferPlayers: [String: BufferedChannel] = [:]
    @Published private(set) var isPreloading = false

    // MARK: - Configuration

    private let maxBufferCount = 2  // Buffer previous and next channels
    private let preloadDelay: UInt64 = 500_000_000  // 500ms delay before starting preload

    // MARK: - Private Properties

    private var preloadTask: Task<Void, Never>?
    private var statusObservers: [String: NSKeyValueObservation] = [:]
    private var currentChannelId: String?

    // MARK: - Initialization

    init() {
        logger.info("InstantSwitchManager initialized")
    }

    deinit {
        // Note: cleanup() should be called before deallocation
    }

    // MARK: - Public Methods

    /// Preload adjacent channels after the main channel starts playing
    /// - Parameters:
    ///   - current: The currently playing channel
    ///   - channels: All available channels in display order
    func preloadAdjacentChannels(current: Channel, channels: [Channel]) {
        preloadTask?.cancel()

        currentChannelId = current.id

        // Clean up any existing buffers not adjacent to new channel
        cleanupNonAdjacentBuffers(current: current, channels: channels)

        preloadTask = Task {
            // Wait a bit for main player to stabilize
            try? await Task.sleep(nanoseconds: preloadDelay)
            guard !Task.isCancelled else { return }

            await performPreload(current: current, channels: channels)
        }
    }

    /// Get a pre-buffered player for a channel if available and ready
    /// - Parameter channel: The channel to get the player for
    /// - Returns: AVPlayer if pre-buffered and ready, nil otherwise
    func getPreloadedPlayer(for channel: Channel) -> AVPlayer? {
        guard let buffered = bufferPlayers[channel.id],
              buffered.isReady else {
            return nil
        }

        logger.info("Using pre-buffered player for channel: \(channel.name)")
        return buffered.player
    }

    /// Check if a channel is pre-buffered and ready
    /// - Parameter channel: The channel to check
    /// - Returns: True if the channel is ready for instant switch
    func isChannelReady(_ channel: Channel) -> Bool {
        return bufferPlayers[channel.id]?.isReady ?? false
    }

    /// Remove a specific channel from the buffer (e.g., when switching to it)
    /// - Parameter channel: The channel to remove from buffer
    func removeFromBuffer(_ channel: Channel) {
        cleanupBuffer(for: channel.id)
    }

    /// Get the buffered channel IDs
    var bufferedChannelIds: Set<String> {
        Set(bufferPlayers.filter { $0.value.isReady }.keys)
    }

    /// Clean up all buffers and cancel preloading
    func cleanup() {
        preloadTask?.cancel()
        preloadTask = nil

        // Clean up all status observers
        statusObservers.values.forEach { $0.invalidate() }
        statusObservers.removeAll()

        // Clean up all buffered players
        for (id, buffered) in bufferPlayers {
            buffered.player.pause()
            buffered.player.replaceCurrentItem(with: nil)
            logger.debug("Cleaned up buffer for channel: \(id)")
        }
        bufferPlayers.removeAll()

        currentChannelId = nil
        isPreloading = false
    }

    // MARK: - Private Methods

    private func performPreload(current: Channel, channels: [Channel]) async {
        guard let currentIndex = channels.firstIndex(where: { $0.id == current.id }) else {
            return
        }

        isPreloading = true

        // Get adjacent channels
        var adjacentChannels: [Channel] = []

        // Previous channel
        let prevIndex = (currentIndex - 1 + channels.count) % channels.count
        if prevIndex != currentIndex {
            adjacentChannels.append(channels[prevIndex])
        }

        // Next channel
        let nextIndex = (currentIndex + 1) % channels.count
        if nextIndex != currentIndex && nextIndex != prevIndex {
            adjacentChannels.append(channels[nextIndex])
        }

        logger.info("Preloading \(adjacentChannels.count) adjacent channels")

        // Preload each adjacent channel
        for channel in adjacentChannels {
            guard !Task.isCancelled else { break }

            // Skip if already buffered
            if bufferPlayers[channel.id] != nil {
                logger.debug("Channel already buffered: \(channel.name)")
                continue
            }

            await preloadChannel(channel)
        }

        isPreloading = false
    }

    private func preloadChannel(_ channel: Channel) async {
        guard let urlString = channel.streamUrl,
              let url = URL(string: urlString) else {
            logger.warning("No stream URL for channel: \(channel.name)")
            return
        }

        logger.info("Starting preload for channel: \(channel.name)")

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)

        // Configure for low-bandwidth pre-buffering
        playerItem.preferredForwardBufferDuration = 5  // Only buffer 5 seconds
        player.automaticallyWaitsToMinimizeStalling = false

        // Store in buffer
        var buffered = BufferedChannel(
            channel: channel,
            player: player,
            playerItem: playerItem,
            isReady: false
        )
        bufferPlayers[channel.id] = buffered

        // Observe player item status
        let observer = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self = self else { return }

                switch item.status {
                case .readyToPlay:
                    logger.info("Channel pre-buffered and ready: \(channel.name)")
                    if var existing = self.bufferPlayers[channel.id] {
                        existing.isReady = true
                        self.bufferPlayers[channel.id] = existing
                    }

                case .failed:
                    logger.error("Failed to preload channel: \(channel.name) - \(item.error?.localizedDescription ?? "unknown")")
                    if var existing = self.bufferPlayers[channel.id] {
                        existing.error = item.error
                        self.bufferPlayers[channel.id] = existing
                    }

                default:
                    break
                }
            }
        }
        statusObservers[channel.id] = observer

        // Start loading (paused)
        player.pause()
    }

    private func cleanupNonAdjacentBuffers(current: Channel, channels: [Channel]) {
        guard let currentIndex = channels.firstIndex(where: { $0.id == current.id }) else {
            return
        }

        // Calculate adjacent channel IDs
        let prevIndex = (currentIndex - 1 + channels.count) % channels.count
        let nextIndex = (currentIndex + 1) % channels.count

        let adjacentIds = Set([
            current.id,
            channels[prevIndex].id,
            channels[nextIndex].id
        ])

        // Remove buffers that are no longer adjacent
        let toRemove = bufferPlayers.keys.filter { !adjacentIds.contains($0) }
        for channelId in toRemove {
            cleanupBuffer(for: channelId)
        }
    }

    private func cleanupBuffer(for channelId: String) {
        guard let buffered = bufferPlayers[channelId] else { return }

        // Remove observer
        statusObservers[channelId]?.invalidate()
        statusObservers.removeValue(forKey: channelId)

        // Stop and cleanup player
        buffered.player.pause()
        buffered.player.replaceCurrentItem(with: nil)

        // Remove from buffer
        bufferPlayers.removeValue(forKey: channelId)

        logger.debug("Removed buffer for channel: \(channelId)")
    }
}
