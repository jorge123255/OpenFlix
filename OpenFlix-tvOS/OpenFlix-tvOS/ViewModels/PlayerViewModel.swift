import Foundation
import AVKit
import Combine
import os.log

private let logger = Logger(subsystem: "com.openflix.tvos", category: "Player")

// MARK: - Stream Info (matching Android)

struct StreamInfo {
    let videoWidth: Int?
    let videoHeight: Int?
    let videoCodec: String?
    let videoFrameRate: Float?
    let videoBitrate: Int?
    let audioCodec: String?
    let audioChannels: Int?
    let audioSampleRate: Int?
    let audioBitrate: Int?

    var resolution: String? {
        guard let w = videoWidth, let h = videoHeight else { return nil }
        return "\(w)x\(h)"
    }

    var resolutionLabel: String? {
        guard let h = videoHeight else { return nil }
        switch h {
        case 2160...: return "4K"
        case 1080...: return "1080p"
        case 720...: return "720p"
        case 480...: return "480p"
        default: return "\(h)p"
        }
    }

    var audioChannelsLabel: String? {
        guard let ch = audioChannels else { return nil }
        switch ch {
        case 1: return "Mono"
        case 2: return "Stereo"
        case 6: return "5.1"
        case 8: return "7.1"
        default: return "\(ch)ch"
        }
    }

    var videoBitrateLabel: String? {
        guard let br = videoBitrate else { return nil }
        if br >= 1_000_000 { return "\(br / 1_000_000) Mbps" }
        if br >= 1_000 { return "\(br / 1_000) Kbps" }
        return "\(br) bps"
    }
}

// MARK: - Track Info

struct TrackInfo: Identifiable {
    let id: Int
    let label: String
    let language: String?
    let isSelected: Bool
}

// MARK: - Aspect Ratio Mode

enum AspectRatioMode: String, CaseIterable {
    case fit = "Fit"           // Letterbox, maintain aspect (default)
    case fill = "Fill"         // Crop to fill
    case zoom = "Zoom"         // Zoom to fill (1.33x)
    case ratio16x9 = "16:9"    // Force 16:9
    case ratio4x3 = "4:3"      // Force 4:3
    case stretch = "Stretch"   // Stretch to fill

    var icon: String {
        switch self {
        case .fit: return "rectangle.arrowtriangle.2.inward"
        case .fill: return "rectangle.arrowtriangle.2.outward"
        case .zoom: return "plus.magnifyingglass"
        case .ratio16x9: return "rectangle.ratio.16.to.9"
        case .ratio4x3: return "rectangle.ratio.4.to.3"
        case .stretch: return "arrow.left.and.right"
        }
    }

    var videoGravity: AVLayerVideoGravity {
        switch self {
        case .fit: return .resizeAspect
        case .fill, .zoom, .stretch: return .resizeAspectFill
        case .ratio16x9, .ratio4x3: return .resizeAspect
        }
    }

    var transform: CGAffineTransform {
        switch self {
        case .zoom: return CGAffineTransform(scaleX: 1.33, y: 1.33)
        case .stretch: return CGAffineTransform(scaleX: 1.33, y: 1.0) // Stretch horizontally
        default: return .identity
        }
    }
}

// MARK: - Sleep Timer Option

enum SleepTimerOption: Int, CaseIterable {
    case off = 0
    case min15 = 15
    case min30 = 30
    case min45 = 45
    case min60 = 60
    case min90 = 90
    case min120 = 120

    var label: String {
        self == .off ? "Off" : "\(rawValue) min"
    }

    var seconds: Int {
        rawValue * 60
    }
}

@MainActor
class PlayerViewModel: ObservableObject {
    private let mediaRepository = MediaRepository()

    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var isLoading = true
    @Published var showControls = true
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var bufferedTime: Double = 0
    @Published var error: String?

    @Published var currentMediaItem: MediaItem?
    @Published var availableSubtitles: [MediaStream] = []
    @Published var availableAudioTracks: [MediaStream] = []
    @Published var selectedSubtitle: MediaStream?
    @Published var selectedAudioTrack: MediaStream?

    // Player features
    @Published var isMuted = false
    @Published var playbackSpeed: Float = 1.0
    @Published var availableSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    // Aspect Ratio
    @Published var aspectRatioMode: AspectRatioMode = .fit
    @Published var showAspectRatioLabel = false

    // Sleep Timer
    @Published var sleepTimerOption: SleepTimerOption = .off
    @Published var sleepTimerRemaining: Int = 0  // Seconds remaining
    private var sleepTimerTask: Task<Void, Never>?

    // Stream info (matching Android)
    @Published var streamInfo: StreamInfo?
    @Published var audioTracks: [TrackInfo] = []
    @Published var subtitleTracks: [TrackInfo] = []
    @Published var selectedAudioTrackIndex: Int?
    @Published var selectedSubtitleTrackIndex: Int?

    // Display info
    @Published var isDisplay4K = false
    @Published var displayResolution: String = "Unknown"

    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var errorObserver: NSKeyValueObservation?
    private var progressUpdateTask: Task<Void, Never>?
    private var controlsHideTask: Task<Void, Never>?

    private let progressUpdateInterval: TimeInterval = 10 // Update every 10 seconds

    init() {
        detectDisplayCapabilities()
    }

    nonisolated func cleanupOnDeinit() {
        // Note: Player cleanup is handled when cleanup() is called before dismissing the view
        // deinit only needs to cancel any remaining tasks
    }

    deinit {
        cleanupOnDeinit()
    }

    // MARK: - Load Media

    func loadMedia(_ item: MediaItem) async {
        currentMediaItem = item
        isLoading = true
        error = nil

        do {
            // If mediaVersions is empty, we need to fetch full details first
            var mediaToPlay = item
            if item.mediaVersions.isEmpty {
                logger.info(" Fetching full details for item \(item.id)")
                mediaToPlay = try await mediaRepository.getMediaDetails(id: item.id)
                currentMediaItem = mediaToPlay
            }

            // Verify we have playable media
            guard !mediaToPlay.mediaVersions.isEmpty else {
                error = "No playable media found"
                isLoading = false
                return
            }

            let url = try await mediaRepository.getPlaybackURL(mediaItem: mediaToPlay)
            await setupPlayer(url: url, startPosition: mediaToPlay.viewOffset ?? item.viewOffset)

            // Extract available streams
            if let version = mediaToPlay.mediaVersions.first,
               let part = version.parts.first {
                availableSubtitles = part.streams.filter { $0.type == .subtitle }
                availableAudioTracks = part.streams.filter { $0.type == .audio }
            }

        } catch let networkError as NetworkError {
            error = networkError.errorDescription
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func loadLiveChannel(url: URL) async {
        logger.info("Loading live channel URL: \(url.absoluteString)")
        isLoading = true
        error = nil
        await setupPlayer(url: url, startPosition: nil)
    }

    func loadRecording(url: URL, startPosition: Int?) async {
        isLoading = true
        error = nil
        await setupPlayer(url: url, startPosition: startPosition)
    }

    private func setupPlayer(url: URL, startPosition: Int?) async {
        logger.info("Setting up player with URL: \(url.absoluteString)")
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)

        // Configure for best quality on 4K displays
        if isDisplay4K {
            playerItem.preferredMaximumResolution = CGSize(width: 3840, height: 2160)
        }

        player = AVPlayer(playerItem: playerItem)
        logger.info("AVPlayer created")

        // Observe player status using newer async observation
        statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, change in
            logger.info("Player item status changed to: \(item.status.rawValue)")
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch item.status {
                case .readyToPlay:
                    logger.info("Ready to play, duration: \(item.duration.seconds)")
                    self.isLoading = false
                    self.duration = item.duration.seconds

                    // Extract stream info
                    Task {
                        await self.extractStreamInfo(from: item)
                    }

                    // Extract available tracks
                    self.extractTracks(from: item)

                    // Seek to start position if provided
                    if let position = startPosition, position > 0 {
                        let time = CMTime(value: CMTimeValue(position), timescale: 1000)
                        self.player?.seek(to: time)
                    }

                    self.play()
                    logger.info("Playback started")

                case .failed:
                    logger.error("Playback failed - \(item.error?.localizedDescription ?? "unknown error")")
                    self.isLoading = false
                    self.error = item.error?.localizedDescription ?? "Playback failed"

                default:
                    logger.info("Player status unknown: \(item.status.rawValue)")
                    break
                }
            }
        }

        // Observe error
        errorObserver = playerItem.observe(\.error) { [weak self] item, _ in
            if let error = item.error {
                logger.info(" Player item error: \(error.localizedDescription)")
                Task { @MainActor in
                    self?.error = error.localizedDescription
                    self?.isLoading = false
                }
            }
        }

        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time.seconds
            }
        }

        // Start progress updates
        startProgressUpdates()

        // Also observe player itself for rate changes
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            logger.info(" Failed to play to end time")
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                logger.info(" Error: \(error.localizedDescription)")
                Task { @MainActor in
                    self?.error = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Display Detection

    private func detectDisplayCapabilities() {
        #if os(tvOS)
        // Check screen resolution
        let screen = UIScreen.main
        let bounds = screen.nativeBounds
        let scale = screen.nativeScale

        let width = Int(bounds.width)
        let height = Int(bounds.height)

        isDisplay4K = width >= 3840 || height >= 2160
        displayResolution = "\(width)x\(height)"

        NSLog("Display: \(displayResolution), scale: \(scale), is4K: \(isDisplay4K)")
        #endif
    }

    // MARK: - Stream Info Extraction

    private func extractStreamInfo(from playerItem: AVPlayerItem) async {
        let asset = playerItem.asset

        do {
            // Load video tracks
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)

            var videoWidth: Int?
            var videoHeight: Int?
            var videoCodec: String?
            var videoFrameRate: Float?
            var videoBitrate: Int?
            var audioCodec: String?
            var audioChannels: Int?
            var audioSampleRate: Int?
            var audioBitrate: Int?

            // Get video info
            if let videoTrack = videoTracks.first {
                let size = try await videoTrack.load(.naturalSize)
                videoWidth = Int(size.width)
                videoHeight = Int(size.height)
                videoFrameRate = try await videoTrack.load(.nominalFrameRate)

                // Get codec from format descriptions
                let formatDescriptions = try await videoTrack.load(.formatDescriptions)
                if let formatDesc = formatDescriptions.first {
                    let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDesc)
                    videoCodec = fourCCToString(mediaSubType)
                }

                videoBitrate = Int(try await videoTrack.load(.estimatedDataRate))
            }

            // Get audio info
            if let audioTrack = audioTracks.first {
                let formatDescriptions = try await audioTrack.load(.formatDescriptions)
                if let formatDesc = formatDescriptions.first {
                    let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDesc)
                    audioCodec = fourCCToString(mediaSubType)

                    if let streamBasicDesc = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) {
                        audioChannels = Int(streamBasicDesc.pointee.mChannelsPerFrame)
                        audioSampleRate = Int(streamBasicDesc.pointee.mSampleRate)
                    }
                }

                audioBitrate = Int(try await audioTrack.load(.estimatedDataRate))
            }

            streamInfo = StreamInfo(
                videoWidth: videoWidth,
                videoHeight: videoHeight,
                videoCodec: videoCodec,
                videoFrameRate: videoFrameRate,
                videoBitrate: videoBitrate,
                audioCodec: audioCodec,
                audioChannels: audioChannels,
                audioSampleRate: audioSampleRate,
                audioBitrate: audioBitrate
            )

            NSLog("Stream: \(streamInfo?.resolution ?? "unknown"), codec: \(streamInfo?.videoCodec ?? "unknown")")

        } catch {
            NSLog("Failed to extract stream info: \(error)")
        }
    }

    private func fourCCToString(_ code: FourCharCode) -> String {
        let bytes = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii) ?? "Unknown"
    }

    // MARK: - Track Extraction

    private func extractTracks(from playerItem: AVPlayerItem) {
        let asset = playerItem.asset

        // Audio tracks
        if let audioGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            audioTracks = audioGroup.options.enumerated().map { index, option in
                let label = option.displayName
                let language = option.locale?.identifier
                let isSelected = playerItem.currentMediaSelection.selectedMediaOption(in: audioGroup) == option
                return TrackInfo(id: index, label: label, language: language, isSelected: isSelected)
            }

            if let selected = audioTracks.first(where: { $0.isSelected }) {
                selectedAudioTrackIndex = selected.id
            }
        }

        // Subtitle tracks
        if let subtitleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            subtitleTracks = subtitleGroup.options.enumerated().map { index, option in
                let label = option.displayName
                let language = option.locale?.identifier
                let isSelected = playerItem.currentMediaSelection.selectedMediaOption(in: subtitleGroup) == option
                return TrackInfo(id: index, label: label, language: language, isSelected: isSelected)
            }

            if let selected = subtitleTracks.first(where: { $0.isSelected }) {
                selectedSubtitleTrackIndex = selected.id
            }
        }
    }

    // MARK: - Track Selection

    func selectAudioTrack(index: Int) {
        guard let playerItem = player?.currentItem,
              let audioGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .audible),
              index < audioGroup.options.count else { return }

        let option = audioGroup.options[index]
        playerItem.select(option, in: audioGroup)
        selectedAudioTrackIndex = index

        // Update track info
        audioTracks = audioTracks.map { track in
            TrackInfo(id: track.id, label: track.label, language: track.language, isSelected: track.id == index)
        }
    }

    func selectSubtitleTrack(index: Int?) {
        guard let playerItem = player?.currentItem,
              let subtitleGroup = playerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else { return }

        if let index = index, index < subtitleGroup.options.count {
            let option = subtitleGroup.options[index]
            playerItem.select(option, in: subtitleGroup)
            selectedSubtitleTrackIndex = index
        } else {
            // Disable subtitles
            playerItem.select(nil, in: subtitleGroup)
            selectedSubtitleTrackIndex = nil
        }

        // Update track info
        subtitleTracks = subtitleTracks.map { track in
            TrackInfo(id: track.id, label: track.label, language: track.language, isSelected: track.id == index)
        }
    }

    func cycleAudioTrack() -> TrackInfo? {
        guard !audioTracks.isEmpty else { return nil }
        let nextIndex = ((selectedAudioTrackIndex ?? -1) + 1) % audioTracks.count
        selectAudioTrack(index: nextIndex)
        return audioTracks[safe: nextIndex]
    }

    func cycleSubtitleTrack() -> TrackInfo? {
        if subtitleTracks.isEmpty { return nil }

        let nextIndex: Int?
        if let current = selectedSubtitleTrackIndex {
            if current >= subtitleTracks.count - 1 {
                nextIndex = nil // Turn off
            } else {
                nextIndex = current + 1
            }
        } else {
            nextIndex = 0 // Turn on first track
        }

        selectSubtitleTrack(index: nextIndex)
        return nextIndex.flatMap { subtitleTracks[safe: $0] }
    }

    // MARK: - Playback Controls

    func play() {
        player?.rate = playbackSpeed
        isPlaying = true
        scheduleHideControls()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        showControls = true
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

    func seekRelative(seconds: Double) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seek(to: newTime)
    }

    func skipForward() {
        seekRelative(seconds: 10)
    }

    func skipBackward() {
        seekRelative(seconds: -10)
    }

    // MARK: - Mute Control

    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        player?.isMuted = muted
    }

    // MARK: - Speed Control

    func setPlaybackSpeed(_ speed: Float) {
        playbackSpeed = speed
        player?.rate = isPlaying ? speed : 0
    }

    func cyclePlaybackSpeed() -> Float {
        guard let currentIndex = availableSpeeds.firstIndex(of: playbackSpeed) else {
            setPlaybackSpeed(1.0)
            return 1.0
        }
        let nextIndex = (currentIndex + 1) % availableSpeeds.count
        let nextSpeed = availableSpeeds[nextIndex]
        setPlaybackSpeed(nextSpeed)
        return nextSpeed
    }

    var playbackSpeedLabel: String {
        if playbackSpeed == 1.0 {
            return "1x"
        } else if playbackSpeed == floor(playbackSpeed) {
            return "\(Int(playbackSpeed))x"
        } else {
            return String(format: "%.2gx", playbackSpeed)
        }
    }

    // MARK: - Aspect Ratio Control

    func cycleAspectRatio() -> AspectRatioMode {
        let modes = AspectRatioMode.allCases
        guard let currentIndex = modes.firstIndex(of: aspectRatioMode) else {
            aspectRatioMode = .fit
            return .fit
        }
        let nextIndex = (currentIndex + 1) % modes.count
        aspectRatioMode = modes[nextIndex]

        // Show label briefly
        showAspectRatioLabel = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                showAspectRatioLabel = false
            }
        }

        return aspectRatioMode
    }

    func setAspectRatio(_ mode: AspectRatioMode) {
        aspectRatioMode = mode

        // Show label briefly
        showAspectRatioLabel = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                showAspectRatioLabel = false
            }
        }
    }

    // MARK: - Sleep Timer

    func setSleepTimer(_ option: SleepTimerOption) {
        sleepTimerTask?.cancel()
        sleepTimerOption = option

        if option == .off {
            sleepTimerRemaining = 0
            return
        }

        sleepTimerRemaining = option.seconds
        startSleepTimerCountdown()
    }

    func cancelSleepTimer() {
        sleepTimerTask?.cancel()
        sleepTimerOption = .off
        sleepTimerRemaining = 0
    }

    private func startSleepTimerCountdown() {
        sleepTimerTask = Task {
            while !Task.isCancelled && sleepTimerRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if !Task.isCancelled {
                    await MainActor.run {
                        sleepTimerRemaining -= 1
                        if sleepTimerRemaining <= 0 {
                            // Timer expired - stop playback
                            pause()
                            sleepTimerOption = .off
                        }
                    }
                }
            }
        }
    }

    var sleepTimerLabel: String {
        guard sleepTimerRemaining > 0 else { return "" }
        let minutes = sleepTimerRemaining / 60
        let seconds = sleepTimerRemaining % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "\(seconds)s"
        }
    }

    // MARK: - Controls Visibility

    func showControlsTemporarily() {
        showControls = true
        scheduleHideControls()
    }

    private func scheduleHideControls() {
        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            if !Task.isCancelled && isPlaying {
                showControls = false
            }
        }
    }

    // MARK: - Progress Updates

    private func startProgressUpdates() {
        progressUpdateTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(progressUpdateInterval * 1_000_000_000))
                await saveProgress()
            }
        }
    }

    private func saveProgress() async {
        guard let item = currentMediaItem,
              currentTime > 0 else { return }

        let timeMs = Int(currentTime * 1000)
        let state = isPlaying ? "playing" : "paused"

        try? await mediaRepository.updateProgress(mediaId: item.id, timeMs: timeMs, state: state)
    }

    // MARK: - Subtitle & Audio Selection

    func selectSubtitle(_ stream: MediaStream?) {
        selectedSubtitle = stream
        // Note: Actual subtitle switching would require player configuration
    }

    func selectAudioTrack(_ stream: MediaStream?) {
        selectedAudioTrack = stream
        // Note: Actual audio track switching would require player configuration
    }

    // MARK: - Cleanup

    func cleanup() {
        progressUpdateTask?.cancel()
        controlsHideTask?.cancel()
        sleepTimerTask?.cancel()

        // Save final progress
        Task {
            await saveProgress()
        }

        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        statusObserver?.invalidate()
        errorObserver?.invalidate()

        // Remove notification observers
        if let playerItem = player?.currentItem {
            NotificationCenter.default.removeObserver(self, name: AVPlayerItem.failedToPlayToEndTimeNotification, object: playerItem)
        }

        player?.pause()
        player = nil
    }

    // MARK: - Computed Properties

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var currentTimeFormatted: String {
        String.formatPlayerTime(seconds: Int(currentTime))
    }

    var durationFormatted: String {
        String.formatPlayerTime(seconds: Int(duration))
    }

    var remainingTimeFormatted: String {
        let remaining = max(0, duration - currentTime)
        return "-" + String.formatPlayerTime(seconds: Int(remaining))
    }
}
