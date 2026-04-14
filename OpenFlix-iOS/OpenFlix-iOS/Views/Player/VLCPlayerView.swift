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
}

// MARK: - VLC Player Wrapper (SwiftUI)

/// A SwiftUI view that uses VLCKit to play any stream format
/// (MPEG-TS, DASH, HLS, RTSP, MKV, etc.)
struct VLCPlayerView: UIViewRepresentable {
    @ObservedObject var viewModel: VLCPlayerViewModel

    func makeUIView(context: Context) -> VLCVideoView {
        let view = VLCVideoView()
        view.backgroundColor = .black
        viewModel.attachDrawable(view)
        return view
    }

    func updateUIView(_ uiView: VLCVideoView, context: Context) {
        // Re-attach if needed (e.g. after view recreation)
        if viewModel.mediaPlayer.drawable as? UIView !== uiView {
            viewModel.attachDrawable(uiView)
        }
    }
}

// MARK: - VLC Player ViewModel

@MainActor
class VLCPlayerViewModel: NSObject, ObservableObject {
    let mediaPlayer = VLCMediaPlayer()

    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var isLoading = true
    @Published var error: String?
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

    override init() {
        super.init()
        mediaPlayer.delegate = self
    }

    deinit {
        timeUpdateTimer?.invalidate()
        mediaPlayer.stop()
    }

    // MARK: - Drawable

    nonisolated func attachDrawable(_ view: UIView) {
        print("🎬 VLCPlayer.attachDrawable() - view: \(view), frame: \(view.frame)")
        mediaPlayer.drawable = view
    }

    // MARK: - Playback

    func play(url: URL) {
        NSLog("VLC PLAY: url=\(url.absoluteString) scheme=\(url.scheme ?? "nil") host=\(url.host ?? "nil") port=\(url.port.map { String($0) } ?? "nil")")
        currentURL = url
        isLoading = true
        isBuffering = true
        error = nil

        let media = VLCMedia(url: url)

        // Configure media options for live streaming
        media.addOptions([
            "network-caching": 1500,       // 1.5s network buffer
            "live-caching": 1500,
            "clock-jitter": 0,
            "clock-synchro": 0,
        ])

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
    }

    func pause() {
        mediaPlayer.pause()
    }

    func togglePlayPause() {
        if isPlaying {
            mediaPlayer.pause()
        } else {
            mediaPlayer.play()
            NSLog("VLC togglePlayPause: mediaPlayer.play() invoked state=\(mediaPlayer.state.rawValue)")
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
        let width = Int(videoSize.width)
        let height = Int(videoSize.height)

        streamInfo = VLCStreamInfo(
            videoWidth: width > 0 ? width : nil,
            videoHeight: height > 0 ? height : nil,
            videoCodec: nil, // VLC doesn't easily expose codec name
            audioCodec: nil
        )
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
                error = "VLC playback failed (state \(state.rawValue)). Stream URL may not be VLC-compatible."

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
}
#endif // !targetEnvironment(simulator)
