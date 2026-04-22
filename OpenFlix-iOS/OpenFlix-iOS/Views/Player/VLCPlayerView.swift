import SwiftUI
#if !targetEnvironment(simulator) && os(iOS)
import MobileVLCKit
#elseif !targetEnvironment(simulator) && os(tvOS)
import TVVLCKit
#endif

#if targetEnvironment(simulator)
// MARK: - Simulator stubs (MobileVLCKit not available on simulator)
class VLCVideoView: UIView {}
struct VLCStreamInfo {
    var videoWidth = 0; var videoHeight = 0
    var videoCodec: String? = nil; var audioCodec: String? = nil
    var audioBitrate = 0; var videoBitrate = 0
    var resolutionLabel: String? = nil
    var audioChannels: Int? = nil
    var audioChannelsLabel: String? { nil }
}
class VLCMediaPlayer: NSObject {
    func play() {}
    func stop() {}
    func pause() {}
    func jumpForward(_ seconds: Int32) {}
    func jumpBackward(_ seconds: Int32) {}
}
@MainActor
class VLCPlayerViewModel: NSObject, ObservableObject {
    private func print(_ items: Any...) {
        let message = items.map { String(describing: $0) }.joined(separator: " ")
        NSLog("%@", message)
    }
    let mediaPlayer = VLCMediaPlayer()
    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var hasReachedPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var streamInfo: VLCStreamInfo?
    @Published var isMuted = false
    @Published var aspectRatioMode: AspectRatioMode = .fit
    @Published var showAspectRatioLabel = false
    @Published var sleepTimerOption: SleepTimerOption = .off
    @Published var sleepTimerRemaining: Int = 0
    @Published var audioTracks: [(index: Int32, name: String)] = []
    @Published var subtitleTracks: [(index: Int32, name: String)] = []
    @Published var selectedAudioTrack: Int32 = -1
    @Published var selectedSubtitleTrack: Int32 = -1
    var sleepTimerLabel: String { "Off" }
    // Simulator stub: TVVLCKit can't render video in the tvOS simulator, but
    // we still flip isLoading so the player overlay shows its loading state
    // and surfaces an error after a few seconds — that way the UI is
    // testable in the sim even though playback itself requires hardware.
        func play(url: URL) {
            NSLog("VLCPlayerViewModel: play called with URL: %@", url.absoluteString)
            NSLog(
                "VLCPlayerViewModel: URL details scheme=%@ host=%@ port=%@ isFile=%@",
                url.scheme ?? "nil",
                url.host ?? "nil",
                url.port.map { String($0) } ?? "nil",
                url.isFileURL ? "true" : "false"
            )
        isLoading = true
        isBuffering = true
        error = nil
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard isLoading else { return }
            isLoading = false
            isBuffering = false
            error = "VLC video playback is not available in the iOS/tvOS simulator. Install on a real device to play streams."
        }
    }
    func pause() {}
    func stop() { isLoading = false; isBuffering = false; isPlaying = false; error = nil }
    func toggleMute() {}
    func togglePlayPause() {}
    func seek(to seconds: Double) {}
    func seekRelative(seconds: Double) {}
    func skipForward() {}
    func skipBackward() {}
    func setVolume(_ volume: Int32) {}
    func loadTracks() {}
    func selectAudioTrack(_ index: Int32) {}
    func selectSubtitleTrack(_ index: Int32) {}
    func disableSubtitles() {}
    @discardableResult func cycleAudioTrack() -> String? { nil }
    @discardableResult func cycleSubtitleTrack() -> String? { nil }
    func attachDrawable(_ view: UIView) {}
    @discardableResult func cycleAspectRatio() -> AspectRatioMode { .fit }
    func setSleepTimer(_ option: SleepTimerOption) {}
    func retry() {}
    func extractStreamInfo() {}
}
struct VLCPlayerView: UIViewRepresentable {
    @ObservedObject var viewModel: VLCPlayerViewModel
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.clipsToBounds = true
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.clipsToBounds = true
    }
}
#else
// MARK: - VLC Player UIView (renders video)

class VLCVideoView: UIView {
    override class var layerClass: AnyClass {
        return CALayer.self
    }

    // Fired the first time bounds becomes non-zero. iPhone defers
    // mediaPlayer.drawable assignment until then so VLC's GL surface
    // initializes at a real size — attaching at (0,0,0,0) leaves the
    // decoder unable to produce frames (videoSize stays (0,0)), the
    // stream loops in BUFFERING, then VideoToolbox tears the session
    // down off the main thread (the doResetBuffers main-thread
    // violation). Apple TV uses a different code path that pre-attaches
    // in init, so this only matters on iPhone.
    var onReady: ((UIView) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let onReady, bounds.width > 0, bounds.height > 0 else { return }
        self.onReady = nil
        onReady(self)
    }
}

// MARK: - VLC Player Wrapper (SwiftUI)

/// A SwiftUI view that uses VLCKit to play any stream format
/// (MPEG-TS, DASH, HLS, RTSP, MKV, etc.)
struct VLCPlayerView: UIViewRepresentable {
    @ObservedObject var viewModel: VLCPlayerViewModel

    func makeUIView(context: Context) -> VLCVideoView {
        #if os(tvOS)
        // tvOS only: reuse the ViewModel's stable backing view. Recreating
        // the VLCVideoView on every makeUIView call caused TVVLCKit to
        // rebuild GL buffers on a background thread → main-thread layer
        // violation + buffering/retry loop with a black screen on Apple TV.
        viewModel.videoView.backgroundColor = .black
        if viewModel.mediaPlayer.drawable as? UIView !== viewModel.videoView {
            viewModel.attachDrawable(viewModel.videoView)
        }
        return viewModel.videoView
        #else
        let view = VLCVideoView()
        view.backgroundColor = .black
        view.onReady = { [weak viewModel] readyView in
            viewModel?.attachDrawable(readyView)
        }
        return view
        #endif
    }

    func updateUIView(_ uiView: VLCVideoView, context: Context) {
        #if os(tvOS)
        if viewModel.mediaPlayer.drawable as? UIView !== uiView {
            viewModel.attachDrawable(uiView)
        }
        #else
        // Re-attach only if the view is laid out and the drawable doesn't
        // match. Skipping when frame is still zero prevents binding GL to
        // a zero-sized surface during the initial mount.
        guard uiView.bounds.width > 0, uiView.bounds.height > 0 else { return }
        if viewModel.mediaPlayer.drawable as? UIView !== uiView {
            viewModel.attachDrawable(uiView)
        }
        #endif
    }
}

// MARK: - VLC Player ViewModel

@MainActor
class VLCPlayerViewModel: NSObject, ObservableObject {
    let mediaPlayer = VLCMediaPlayer()

    #if os(tvOS)
    /// tvOS-only stable backing UIView for VLC's GL surface. iPhone keeps
    /// the original "fresh VLCVideoView per makeUIView" behavior — that's
    /// what's been working on TestFlight.
    let videoView = VLCVideoView()
    #endif

    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var isLoading = true
    @Published var error: String?
    /// Flips true the first time VLC reaches PLAYING for the current
    /// URL. Reset on every play(url:). UI uses this to gate the buffering
    /// HUD: brief mid-stream rebuffers shouldn't put the spinner back —
    /// only the initial "we haven't seen video yet" state should.
    @Published var hasReachedPlaying = false
    @Published var currentTime: Double = 0    // seconds
    @Published var duration: Double = 0       // seconds
    @Published var streamInfo: VLCStreamInfo?

    // Player features
    @Published var isMuted = false

    // Aspect Ratio
    @Published var aspectRatioMode: AspectRatioMode = .fit
    @Published var showAspectRatioLabel = false

    // Sleep Timer
    @Published var sleepTimerOption: SleepTimerOption = .off
    @Published var sleepTimerRemaining: Int = 0  // Seconds remaining
    private var sleepTimerTask: Task<Void, Never>?

    // Audio/Subtitle tracks
    @Published var audioTracks: [(index: Int32, name: String)] = []
    @Published var subtitleTracks: [(index: Int32, name: String)] = []
    @Published var selectedAudioTrack: Int32 = -1
    @Published var selectedSubtitleTrack: Int32 = -1

    private var timeUpdateTimer: Timer?
    private var currentURL: URL?

    /// iPhone only: a URL handed to play(url:) before the SwiftUI host
    /// view has been laid out. The drawable arrives via attachDrawable —
    /// that's where this gets consumed.
    private var pendingPlayURL: URL?

    override init() {
        super.init()
        mediaPlayer.delegate = self
        #if os(tvOS)
        // tvOS only: pre-attach VLC's drawable to the cached UIView so
        // play(url:) always has somewhere to render. iPhone uses the
        // original behavior — drawable is set when SwiftUI mounts the view.
        mediaPlayer.drawable = videoView
        #endif
    }

    deinit {
        timeUpdateTimer?.invalidate()
        mediaPlayer.stop()
    }

    // MARK: - Drawable

    func attachDrawable(_ view: UIView) {
        print("🎬 VLCPlayer.attachDrawable() - view: \(view), frame: \(view.frame)")
        // VLCKit manipulates UI layers when setting drawable — must be main thread.
        mediaPlayer.drawable = view
        flushPendingPlay()
    }

    @MainActor
    private func flushPendingPlay() {
        guard let url = pendingPlayURL else { return }
        pendingPlayURL = nil
        startMediaPlayback(url: url)
    }

    // MARK: - Playback

    func play(url: URL) {
        NSLog("VLC PLAY: url=\(url.absoluteString) scheme=\(url.scheme ?? "nil") host=\(url.host ?? "nil") port=\(url.port.map { String($0) } ?? "nil")")
        currentURL = url
        isLoading = true
        isBuffering = true
        error = nil

        // If the SwiftUI host view hasn't been laid out yet (drawable is
        // nil), queue the URL — attachDrawable will pick it up. Calling
        // mediaPlayer.play() against a nil drawable starts the decoder
        // bound to a phantom GL surface, leaves videoSize at (0,0), and
        // the stream loops in BUFFERING until VideoToolbox bails.
        guard mediaPlayer.drawable != nil else {
            NSLog("VLC PLAY: drawable not ready — queued")
            pendingPlayURL = url
            return
        }

        startMediaPlayback(url: url)
    }

    @MainActor
    private func startMediaPlayback(url: URL) {
        let media = VLCMedia(url: url)

        // Live MPEG-TS proxy → bigger network buffer so a tap-pause
        // actually holds for ~10s. VLC's default 1.5s drains instantly.
        // Stream-out feeds are non-seekable; this is the only way to
        // give the user a real pause window.
        media.addOptions([
            "network-caching": 10000,
            "live-caching": 10000,
            "file-caching": 10000,
            "clock-jitter": 0,
            "clock-synchro": 0,
        ])

        hasReachedPlaying = false
        pausedAt = nil
        mediaPlayer.media = media
        mediaPlayer.play()
        NSLog("VLC PLAY: mediaPlayer.play() invoked state=\(mediaPlayer.state.rawValue) drawable=\(mediaPlayer.drawable == nil ? "nil" : "set")")
        startTimeUpdates()
    }

    func stop() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
        mediaPlayer.stop()
        isPlaying = false
        isLoading = false
        hasReachedPlaying = false
        pausedAt = nil
    }

    /// When the user paused. Used by togglePlayPause to decide between
    /// "resume from VLC's input buffer" (short pause, buffer still has
    /// data) and "reconnect from scratch" (long pause, buffer drained).
    private var pausedAt: Date?

    func pause() {
        pausedAt = Date()
        mediaPlayer.pause()
    }

    func togglePlayPause() {
        if isPlaying {
            pausedAt = Date()
            mediaPlayer.pause()
            return
        }
        // Resume. If we paused longer than the input buffer can hold, the
        // upstream connection will be dead — call play(url:) so we open a
        // fresh socket and reconnect at live edge. Otherwise just unpause
        // and let VLC drain its existing buffer.
        let pausedFor = pausedAt.map { Date().timeIntervalSince($0) } ?? 0
        let bufferSeconds: TimeInterval = 9   // a hair under network-caching=10s
        if pausedFor > bufferSeconds, let url = currentURL {
            NSLog("VLC togglePlayPause: paused \(Int(pausedFor))s — buffer drained, reconnecting")
            pausedAt = nil
            startMediaPlayback(url: url)
        } else {
            NSLog("VLC togglePlayPause: resume from buffer (paused \(Int(pausedFor))s)")
            pausedAt = nil
            mediaPlayer.play()
        }
    }

    func seek(to seconds: Double) {
        guard duration > 0 else { return }
        let position = Float(seconds / duration)
        mediaPlayer.position = max(0, min(1, position))
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

    // MARK: - Volume

    func setVolume(_ volume: Int32) {
        mediaPlayer.audio?.volume = volume
    }

    func toggleMute() {
        if let audio = mediaPlayer.audio {
            let newVolume: Int32 = audio.volume == 0 ? 100 : 0
            audio.volume = newVolume
            isMuted = newVolume == 0
        } else {
            isMuted.toggle()
        }
    }

    // MARK: - Track Selection

    func loadTracks() {
        // Audio tracks
        if let names = mediaPlayer.audioTrackNames as? [String],
           let indexes = mediaPlayer.audioTrackIndexes as? [NSNumber] {
            audioTracks = zip(indexes, names).map { (index: $0.int32Value, name: $1) }
            selectedAudioTrack = mediaPlayer.currentAudioTrackIndex
        }

        // Subtitle tracks
        if let names = mediaPlayer.videoSubTitlesNames as? [String],
           let indexes = mediaPlayer.videoSubTitlesIndexes as? [NSNumber] {
            subtitleTracks = zip(indexes, names).map { (index: $0.int32Value, name: $1) }
            selectedSubtitleTrack = mediaPlayer.currentVideoSubTitleIndex
        }
    }

    func selectAudioTrack(_ index: Int32) {
        mediaPlayer.currentAudioTrackIndex = index
        selectedAudioTrack = index
    }

    func selectSubtitleTrack(_ index: Int32) {
        mediaPlayer.currentVideoSubTitleIndex = index
        selectedSubtitleTrack = index
    }

    func disableSubtitles() {
        mediaPlayer.currentVideoSubTitleIndex = -1
        selectedSubtitleTrack = -1
    }

    func cycleAudioTrack() -> String? {
        guard !audioTracks.isEmpty else { return nil }
        let currentIndex = audioTracks.firstIndex(where: { $0.index == selectedAudioTrack }) ?? -1
        let nextIndex = (currentIndex + 1) % audioTracks.count
        let track = audioTracks[nextIndex]
        selectAudioTrack(track.index)
        return track.name
    }

    func cycleSubtitleTrack() -> String? {
        guard !subtitleTracks.isEmpty else { return nil }

        if selectedSubtitleTrack == -1 {
            let track = subtitleTracks[0]
            selectSubtitleTrack(track.index)
            return track.name
        }

        if let currentIndex = subtitleTracks.firstIndex(where: { $0.index == selectedSubtitleTrack }) {
            if currentIndex >= subtitleTracks.count - 1 {
                disableSubtitles()
                return nil
            }
            let track = subtitleTracks[currentIndex + 1]
            selectSubtitleTrack(track.index)
            return track.name
        }

        let track = subtitleTracks[0]
        selectSubtitleTrack(track.index)
        return track.name
    }

    // MARK: - Aspect Ratio

    func setAspectRatio(_ ratio: String?) {
        // VLC accepts: "1:1", "4:3", "16:9", "16:10", "2.21:1", "2.35:1", "2.39:1", "5:4", nil (default)
        if let ratio = ratio {
            mediaPlayer.videoAspectRatio = UnsafeMutablePointer<CChar>(mutating: (ratio as NSString).utf8String)
        } else {
            mediaPlayer.videoAspectRatio = nil
        }
    }

    func cycleAspectRatio() -> AspectRatioMode {
        let modes = AspectRatioMode.allCases
        guard let currentIndex = modes.firstIndex(of: aspectRatioMode) else {
            aspectRatioMode = .fit
            applyAspectRatio(mode: .fit)
            return .fit
        }
        let nextIndex = (currentIndex + 1) % modes.count
        let nextMode = modes[nextIndex]
        aspectRatioMode = nextMode
        applyAspectRatio(mode: nextMode)

        // Show label briefly
        showAspectRatioLabel = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                showAspectRatioLabel = false
            }
        }

        return nextMode
    }

    func applyAspectRatio(mode: AspectRatioMode) {
        switch mode {
        case .ratio16x9:
            setAspectRatio("16:9")
        case .ratio4x3:
            setAspectRatio("4:3")
        default:
            setAspectRatio(nil)
        }
    }

    // MARK: - Stream Info

    func extractStreamInfo() {
        guard let media = mediaPlayer.media else { return }

        let videoSize = mediaPlayer.videoSize
        var width = Int(videoSize.width)
        var height = Int(videoSize.height)
        var videoCodec: String?
        var audioCodec: String?
        var audioChannels: Int?

        // VLCMedia.tracksInformation gives an array of [String: Any]
        // dicts, one per track. We pull codec name + audio channel count
        // out of it. FourCC codes are converted to ASCII (e.g.
        // 0x65616333 → "eac3"), then uppercased for display.
        if let tracks = media.tracksInformation as? [[String: Any]] {
            for track in tracks {
                let typeKey = "VLCMediaTracksInformationType"
                let codecKey = "VLCMediaTracksInformationCodec"
                let widthKey = "VLCMediaTracksInformationVideoWidth"
                let heightKey = "VLCMediaTracksInformationVideoHeight"
                let channelsKey = "VLCMediaTracksInformationAudioChannelsNumber"

                let type = (track[typeKey] as? String)?.lowercased() ?? ""
                let codecFourCC = (track[codecKey] as? UInt32)
                    ?? UInt32(truncatingIfNeeded: (track[codecKey] as? UInt) ?? 0)
                let codecName = codecFourCC == 0 ? nil : Self.fourCCToString(codecFourCC)

                if type == "video" {
                    if width == 0, let w = track[widthKey] as? UInt { width = Int(w) }
                    if height == 0, let h = track[heightKey] as? UInt { height = Int(h) }
                    if videoCodec == nil { videoCodec = codecName }
                } else if type == "audio" {
                    if audioCodec == nil { audioCodec = codecName }
                    if audioChannels == nil, let ch = track[channelsKey] as? UInt {
                        audioChannels = Int(ch)
                    }
                }
            }
        }

        streamInfo = VLCStreamInfo(
            videoWidth: width > 0 ? width : nil,
            videoHeight: height > 0 ? height : nil,
            videoCodec: videoCodec,
            audioCodec: audioCodec,
            audioChannels: audioChannels
        )
    }

    /// Convert a VLC FourCC codec code (e.g. 0x65616333) to its ASCII
    /// representation ("eac3"). Returns nil for codes that aren't 4
    /// printable ASCII bytes.
    private static func fourCCToString(_ code: UInt32) -> String? {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]
        let chars = bytes.compactMap { byte -> Character? in
            // Accept printable ASCII; trim padding spaces.
            guard byte >= 0x20 && byte <= 0x7E else { return nil }
            return Character(UnicodeScalar(byte))
        }
        guard chars.count >= 3 else { return nil }
        return String(chars).trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Time Updates

    private func startTimeUpdates() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.mediaPlayer.isPlaying {
                    let timeValue = self.mediaPlayer.time.intValue
                    if timeValue > 0 {
                        self.currentTime = Double(timeValue) / 1000.0
                    }
                    let remainingValue = self.mediaPlayer.remainingTime?.intValue ?? 0
                    if remainingValue > 0 {
                        let total = Double(timeValue - remainingValue) / 1000.0
                        if total > 0 {
                            self.duration = total
                        }
                    }
                }
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
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !Task.isCancelled {
                    await MainActor.run {
                        sleepTimerRemaining -= 1
                        if sleepTimerRemaining <= 0 {
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

    // MARK: - Retry

    func retry() {
        guard let url = currentURL else { return }
        play(url: url)
    }
}

// MARK: - VLCMediaPlayerDelegate

extension VLCPlayerViewModel: VLCMediaPlayerDelegate {
    nonisolated func mediaPlayerStateChanged(_ aNotification: Notification) {
        Task { @MainActor in
            let state = mediaPlayer.state
            NSLog("VLC STATE: \(state.rawValue) isPlaying=\(mediaPlayer.isPlaying) url=\(currentURL?.absoluteString ?? "nil")")
            switch state {
            case .playing:
                NSLog("VLC STATE: PLAYING videoSize=\(mediaPlayer.videoSize)")
                isPlaying = true
                isBuffering = false
                isLoading = false
                hasReachedPlaying = true
                isMuted = (mediaPlayer.audio?.volume ?? 100) == 0
                loadTracks()
                extractStreamInfo()

            case .paused:
                NSLog("VLC STATE: PAUSED")
                isPlaying = false
                isBuffering = false

            case .buffering:
                NSLog("VLC STATE: BUFFERING")
                isBuffering = true
                isLoading = false

            case .ended:
                NSLog("VLC STATE: ENDED")
                isPlaying = false
                isBuffering = false

            case .error:
                NSLog("VLC STATE: ERROR url=\(currentURL?.absoluteString ?? "nil")")
                isPlaying = false
                isBuffering = false
                isLoading = false
                // Surface the URL on-screen so we can see what VLC is being
                // asked to play without needing remote logs. Strip if/when
                // playback is fixed.
                error = "VLC error (state \(state.rawValue))\nURL: \(currentURL?.absoluteString ?? "nil")"

            case .stopped:
                NSLog("VLC STATE: STOPPED")
                isPlaying = false
                isBuffering = false

            case .opening:
                NSLog("VLC STATE: OPENING")
                isLoading = true
                isBuffering = true

            @unknown default:
                NSLog("VLC STATE: UNKNOWN raw=\(state.rawValue)")
                break
            }
        }
    }

    nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
        // Time updates handled by timer for smoother UI
    }
}

// MARK: - VLC Stream Info

struct VLCStreamInfo {
    let videoWidth: Int?
    let videoHeight: Int?
    let videoCodec: String?
    let audioCodec: String?
    /// Channel count from the audio track (1 = mono, 2 = stereo, 6 = 5.1, 8 = 7.1).
    let audioChannels: Int?

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

    /// Human-readable channel layout suffix — "Mono" / "Stereo" / "5.1" / "7.1".
    var audioChannelsLabel: String? {
        switch audioChannels ?? 0 {
        case 1: return "Mono"
        case 2: return "Stereo"
        case 6: return "5.1"
        case 8: return "7.1"
        case let n where n > 0: return "\(n)ch"
        default: return nil
        }
    }
}
#endif // !targetEnvironment(simulator)
