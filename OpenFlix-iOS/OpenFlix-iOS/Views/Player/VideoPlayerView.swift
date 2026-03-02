import SwiftUI
import AVKit

// MARK: - Video Player View
// Apple TV-style video player with custom controls overlay

struct VideoPlayerView: View {
    let mediaItem: MediaItem?
    var liveChannelURL: URL?
    var recordingURL: URL?
    var startPosition: Int?
    var commercials: [Commercial] = []
    var recordingDurationMs: Int = 0

    @StateObject private var viewModel = PlayerViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var showContentRating = true
    @State private var contentRatingDismissed = false

    var body: some View {
        ZStack {
            // Video Player
            if let player = viewModel.player {
                AVPlayerViewRepresentable(
                    player: player,
                    aspectRatioMode: viewModel.aspectRatioMode
                )
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showControls.toggle()
                    if viewModel.showControls {
                        viewModel.showControlsTemporarily()
                    }
                }
            } else {
                Color.black
                    .ignoresSafeArea()
            }

            // Content rating notice (shown briefly at start)
            if showContentRating && !contentRatingDismissed, let rating = mediaItem?.contentRating {
                ContentRatingNotice(rating: rating) {
                    withAnimation {
                        contentRatingDismissed = true
                    }
                }
                .onAppear {
                    // Auto-dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            contentRatingDismissed = true
                        }
                    }
                }
            }

            // Loading
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(.white)
            }

            // Error
            if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)

                    Text(error)
                        .foregroundColor(.white)

                    Button("Close", action: { dismiss() })
                        .buttonStyle(.bordered)
                }
            }

            // Commercial skip button (shown when in a commercial and auto-skip is off)
            if viewModel.isInCommercial && !viewModel.commercialSkipEnabled {
                CommercialSkipButton {
                    viewModel.skipCurrentCommercial()
                }
            }

            // Skip Intro / Skip Credits button
            if viewModel.showSkipButton {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            viewModel.skipActiveMarker()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text(viewModel.skipButtonLabel)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 48)
                        .padding(.bottom, 80)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .animation(.easeInOut(duration: 0.3), value: viewModel.showSkipButton)
            }

            // Controls overlay - Apple TV style
            if viewModel.showControls && !viewModel.isLoading && contentRatingDismissed {
                AppleTVPlayerControlsOverlay(
                    viewModel: viewModel,
                    commercials: commercials,
                    recordingDurationMs: recordingDurationMs,
                    isRecording: recordingURL != nil
                ) {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadContent()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        #if os(tvOS)
        .onPlayPauseCommand {
            viewModel.togglePlayPause()
        }
        .onMoveCommand { direction in
            handleMove(direction)
        }
        .onExitCommand {
            if viewModel.showControls {
                viewModel.showControls = false
            } else {
                dismiss()
            }
        }
        #endif
    }

    private func loadContent() {
        // If no content rating, skip the rating gate so controls can appear
        if mediaItem?.contentRating == nil {
            contentRatingDismissed = true
        }
        Task {
            if let item = mediaItem {
                await viewModel.loadMedia(item)
            } else if let url = liveChannelURL {
                await viewModel.loadLiveChannel(url: url)
            } else if let url = recordingURL {
                viewModel.setCommercials(commercials)
                await viewModel.loadRecording(url: url, startPosition: startPosition)
            }
        }
    }

    #if os(tvOS)
    private func handleMove(_ direction: MoveCommandDirection) {
        viewModel.showControlsTemporarily()

        switch direction {
        case .left:
            viewModel.skipBackward()
        case .right:
            viewModel.skipForward()
        case .up, .down:
            break
        @unknown default:
            break
        }
    }
    #endif
}

// MARK: - AV Player View Representable

struct AVPlayerViewRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    var aspectRatioMode: AspectRatioMode = .fit
    var allowsPictureInPicture: Bool = true
    var showsPlaybackControls: Bool = false

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = showsPlaybackControls
        
        // Enable Picture-in-Picture
        controller.allowsPictureInPicturePlayback = allowsPictureInPicture
        
        // AirPlay is automatically available via AVPlayerViewController
        // The route picker button appears in system controls
        
        applyAspectRatio(to: controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        applyAspectRatio(to: uiViewController)
    }

    private func applyAspectRatio(to controller: AVPlayerViewController) {
        controller.videoGravity = aspectRatioMode.videoGravity

        // Apply transform for zoom/stretch modes
        if aspectRatioMode != .fit && aspectRatioMode != .fill {
            // For zoom and stretch, we need to apply a transform to the content view
            // Note: This is a simplified implementation. Full aspect ratio control
            // would require a custom AVPlayerLayer-based view.
            switch aspectRatioMode {
            case .zoom:
                controller.view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            case .stretch:
                controller.view.transform = CGAffineTransform(scaleX: 1.2, y: 1.0)
            case .ratio16x9:
                // Force 16:9 by adjusting the container
                controller.view.transform = .identity
            case .ratio4x3:
                // Force 4:3 by adjusting the container
                controller.view.transform = CGAffineTransform(scaleX: 0.75, y: 1.0)
            default:
                controller.view.transform = .identity
            }
        } else {
            controller.view.transform = .identity
        }
    }
}

// MARK: - Apple TV Style Player Controls Overlay

struct AppleTVPlayerControlsOverlay: View {
    @ObservedObject var viewModel: PlayerViewModel
    var commercials: [Commercial] = []
    var recordingDurationMs: Int = 0
    var isRecording: Bool = false
    var onClose: () -> Void

    @FocusState private var focusedControl: PlayerControl?
    @State private var scrubProgress: Double?

    enum PlayerControl: Hashable {
        case close, speed, airplay, mute
        case skipBack, playPause, skipForward
        case info, subtitles, audio
    }

    var body: some View {
        ZStack {
            // Tap area to show/hide controls
            Color.black.opacity(0.001)
                .onTapGesture {
                    viewModel.showControls.toggle()
                }

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.top, 48)
                    .padding(.horizontal, 48)

                Spacer()

                // Center controls - Large circular buttons
                centerControls

                Spacer()

                // Bottom info bar
                bottomInfoBar
                    .padding(.bottom, 48)
                    .padding(.horizontal, 48)
            }
        }
        .background(
            LinearGradient(
                colors: [.black.opacity(0.8), .clear, .clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 16) {
            // Close/Back button
            Button(action: onClose) {
                Image(systemName: isRecording ? "chevron.left" : "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .focused($focusedControl, equals: .close)
            .scaleEffect(focusedControl == .close ? 1.1 : 1.0)
            .overlay(
                Circle()
                    .stroke(focusedControl == .close ? Color.white : .clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.15), value: focusedControl)

            // Speed button
            Button(action: { _ = viewModel.cyclePlaybackSpeed() }) {
                Text(viewModel.playbackSpeedLabel)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .focused($focusedControl, equals: .speed)
            .scaleEffect(focusedControl == .speed ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: focusedControl)

            // AirPlay button (shows route picker)
            Button(action: {}) {
                Image(systemName: "airplayvideo")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .focused($focusedControl, equals: .airplay)
            .scaleEffect(focusedControl == .airplay ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: focusedControl)

            Spacer()

            // Stream info badge (if available)
            if let streamInfo = viewModel.streamInfo {
                HStack(spacing: 8) {
                    if let res = streamInfo.resolutionLabel {
                        Text(res)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                    }
                    if let codec = streamInfo.videoCodec {
                        Text(codec)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            Spacer().frame(width: 16)

            // Mute button (right side)
            Button(action: { viewModel.toggleMute() }) {
                Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.isMuted ? .red : .white)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .focused($focusedControl, equals: .mute)
            .scaleEffect(focusedControl == .mute ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: focusedControl)
        }
    }

    // MARK: - Center Controls

    private var centerControls: some View {
        HStack(spacing: 80) {
            // Skip back 10s
            Button(action: { viewModel.seekRelative(seconds: -10) }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 80, height: 80)

                    VStack(spacing: 2) {
                        Image(systemName: "gobackward")
                            .font(.system(size: 20, weight: .bold))
                        Text("10")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .focused($focusedControl, equals: .skipBack)
            .scaleEffect(focusedControl == .skipBack ? 1.15 : 1.0)
            .overlay(
                Circle()
                    .stroke(focusedControl == .skipBack ? Color.white : .clear, lineWidth: 3)
                    .frame(width: 80, height: 80)
            )
            .animation(.easeInOut(duration: 0.15), value: focusedControl)

            // Play/Pause - Large button
            Button(action: { viewModel.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 110, height: 110)

                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .focused($focusedControl, equals: .playPause)
            .scaleEffect(focusedControl == .playPause ? 1.1 : 1.0)
            .overlay(
                Circle()
                    .stroke(focusedControl == .playPause ? Color.white : .clear, lineWidth: 4)
                    .frame(width: 110, height: 110)
            )
            .animation(.easeInOut(duration: 0.15), value: focusedControl)

            // Skip forward 10s
            Button(action: { viewModel.seekRelative(seconds: 10) }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 80, height: 80)

                    VStack(spacing: 2) {
                        Image(systemName: "goforward")
                            .font(.system(size: 20, weight: .bold))
                        Text("10")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .focused($focusedControl, equals: .skipForward)
            .scaleEffect(focusedControl == .skipForward ? 1.15 : 1.0)
            .overlay(
                Circle()
                    .stroke(focusedControl == .skipForward ? Color.white : .clear, lineWidth: 3)
                    .frame(width: 80, height: 80)
            )
            .animation(.easeInOut(duration: 0.15), value: focusedControl)
        }
    }

    // MARK: - Bottom Info Bar

    private var bottomInfoBar: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Episode title (small)
                    if let item = viewModel.currentMediaItem {
                        if item.type == .episode, let episodeLabel = item.episodeLabel {
                            Text(episodeLabel)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        // Main title (large)
                        Text(item.type == .episode ? (item.grandparentTitle ?? item.title) : item.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // More options
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.4))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Progress bar
            HStack(spacing: 16) {
                Text(scrubTimeFormatted ?? viewModel.currentTimeFormatted)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .monospacedDigit()

                // Progress bar with scrubber, drag gesture, and commercial markers
                GeometryReader { geometry in
                    let displayProgress = scrubProgress ?? viewModel.progress
                    let isScrubbing = scrubProgress != nil

                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.3))

                        // Commercial markers (yellow segments on progress bar)
                        if !viewModel.commercials.isEmpty && viewModel.duration > 0 {
                            ForEach(viewModel.commercials) { commercial in
                                let startFrac = Double(commercial.start) / 1000.0 / viewModel.duration
                                let endFrac = Double(commercial.end) / 1000.0 / viewModel.duration
                                let width = max(2, (endFrac - startFrac) * geometry.size.width)

                                Rectangle()
                                    .fill(Color.yellow.opacity(0.6))
                                    .frame(width: width, height: 6)
                                    .offset(x: startFrac * geometry.size.width)
                            }
                        }

                        // Progress fill
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * displayProgress)

                        // Scrubber dot (enlarges during scrub)
                        Circle()
                            .fill(Color.white)
                            .frame(width: isScrubbing ? 24 : 16, height: isScrubbing ? 24 : 16)
                            .shadow(color: .black.opacity(0.3), radius: isScrubbing ? 4 : 2)
                            .offset(x: geometry.size.width * displayProgress - (isScrubbing ? 12 : 8))
                            .animation(.easeInOut(duration: 0.15), value: isScrubbing)
                    }
                    .frame(height: 6)
                    .padding(.vertical, 19)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let fraction = max(0, min(1, value.location.x / geometry.size.width))
                                scrubProgress = fraction
                                viewModel.showControlsTemporarily()
                            }
                            .onEnded { value in
                                let fraction = max(0, min(1, value.location.x / geometry.size.width))
                                viewModel.seek(to: fraction * viewModel.duration)
                                scrubProgress = nil
                            }
                    )
                }
                .frame(height: 44)

                Text(scrubRemainingFormatted ?? viewModel.remainingTimeFormatted)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }

            // Quick action buttons
            HStack(spacing: 20) {
                // Info button
                Button(action: {}) {
                    Label("Info", systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .focused($focusedControl, equals: .info)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(focusedControl == .info ? Color.white.opacity(0.2) : Color.black.opacity(0.3))
                .cornerRadius(8)

                // Subtitles button
                if !viewModel.subtitleTracks.isEmpty {
                    Button(action: {
                        if let track = viewModel.cycleSubtitleTrack() {
                            // Could show a toast with track name
                            print("Switched to subtitle: \(track.label)")
                        } else {
                            print("Subtitles off")
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "captions.bubble")
                            Text(subtitleButtonLabel)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .focused($focusedControl, equals: .subtitles)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(focusedControl == .subtitles ? Color.white.opacity(0.2) : Color.black.opacity(0.3))
                    .cornerRadius(8)
                }

                // Audio button
                if viewModel.audioTracks.count > 1 {
                    Button(action: {
                        if let track = viewModel.cycleAudioTrack() {
                            print("Switched to audio: \(track.label)")
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.3")
                            Text(audioButtonLabel)
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .focused($focusedControl, equals: .audio)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(focusedControl == .audio ? Color.white.opacity(0.2) : Color.black.opacity(0.3))
                    .cornerRadius(8)
                }

                Spacer()

                // Playback speed indicator
                if viewModel.playbackSpeed != 1.0 {
                    Text("Speed: \(viewModel.playbackSpeedLabel)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
    }

    private var scrubTimeFormatted: String? {
        guard let frac = scrubProgress else { return nil }
        let time = frac * viewModel.duration
        return String.formatPlayerTime(seconds: Int(time))
    }

    private var scrubRemainingFormatted: String? {
        guard let frac = scrubProgress else { return nil }
        let remaining = max(0, viewModel.duration - frac * viewModel.duration)
        return "-" + String.formatPlayerTime(seconds: Int(remaining))
    }

    private var subtitleButtonLabel: String {
        if let index = viewModel.selectedSubtitleTrackIndex,
           let track = viewModel.subtitleTracks[safe: index] {
            return track.label
        }
        return "Off"
    }

    private var audioButtonLabel: String {
        if let index = viewModel.selectedAudioTrackIndex,
           let track = viewModel.audioTracks[safe: index] {
            return track.label
        }
        return "Audio"
    }
}

// MARK: - Content Rating Notice

struct ContentRatingNotice: View {
    let rating: String
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Rating badge
                Text(rating)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    .cornerRadius(8)

                // Separator
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 2, height: 40)

                // Description
                Text(ratingDescription)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(32)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .onTapGesture {
            onDismiss?()
        }
    }

    private var ratingDescription: String {
        switch rating.uppercased() {
        case "TV-MA": return "Mature Audiences Only"
        case "TV-14": return "Parents Strongly Cautioned"
        case "TV-PG": return "Parental Guidance Suggested"
        case "TV-G": return "General Audience"
        case "TV-Y7": return "Directed to Older Children"
        case "TV-Y": return "All Children"
        case "R": return "Restricted - Under 17 Requires Accompanying Adult"
        case "PG-13": return "Parents Strongly Cautioned"
        case "PG": return "Parental Guidance Suggested"
        case "G": return "General Audiences"
        case "NC-17": return "No One 17 and Under Admitted"
        default: return "Content may not be suitable for all audiences"
        }
    }
}

// MARK: - Commercial Skip Button (with countdown auto-skip)

struct CommercialSkipButton: View {
    let onSkip: () -> Void
    var countdownSeconds: Int = 5

    @State private var appeared = false
    @State private var remaining: Int = 5
    @State private var timerTask: Task<Void, Never>?

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    timerTask?.cancel()
                    onSkip()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(remaining > 0 ? "Skip Ad (\(remaining))" : "Skip Ad")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.yellow)
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 48)
                .padding(.bottom, 120)
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : 50)
            }
        }
        .onAppear {
            remaining = countdownSeconds
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
            startCountdown()
        }
        .onDisappear {
            timerTask?.cancel()
        }
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private func startCountdown() {
        timerTask = Task {
            for i in stride(from: countdownSeconds, through: 1, by: -1) {
                if Task.isCancelled { return }
                remaining = i
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            if !Task.isCancelled {
                remaining = 0
                onSkip()
            }
        }
    }
}

// MARK: - VOD Player (M3U VOD URLs - plays any direct stream URL)

struct VODPlayerView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var showControls = true
    @State private var controlsTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                AVPlayerViewRepresentable(player: player, showsPlaybackControls: true)
                    .ignoresSafeArea()
            }

            if isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(.white)
            }

            // Close button overlay
            VStack {
                HStack {
                    Button {
                        player?.pause()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                    .padding(.top, 60)

                    Spacer()
                }
                Spacer()
            }
            .opacity(showControls ? 1 : 0)
        }
        .onTapGesture {
            withAnimation { showControls.toggle() }
            if showControls { scheduleHideControls() }
        }
        .onAppear { setupPlayer() }
        .onDisappear {
            player?.pause()
            controlsTask?.cancel()
        }
    }

    private func setupPlayer() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)

        let avPlayer = AVPlayer(url: url)
        player = avPlayer
        avPlayer.play()
        isLoading = false
        scheduleHideControls()

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: avPlayer.currentItem,
            queue: .main
        ) { _ in dismiss() }
    }

    private func scheduleHideControls() {
        controlsTask?.cancel()
        controlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                withAnimation { showControls = false }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VideoPlayerView(mediaItem: nil)
}
