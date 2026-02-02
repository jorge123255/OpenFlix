import SwiftUI
import AVKit

// MARK: - Video Player View
// Apple TV-style video player with custom controls overlay

struct VideoPlayerView: View {
    let mediaItem: MediaItem?
    var liveChannelURL: URL?
    var recordingURL: URL?
    var startPosition: Int?

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

            // Controls overlay - Apple TV style
            if viewModel.showControls && !viewModel.isLoading && contentRatingDismissed {
                AppleTVPlayerControlsOverlay(viewModel: viewModel) {
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
    }

    private func loadContent() {
        Task {
            if let item = mediaItem {
                await viewModel.loadMedia(item)
            } else if let url = liveChannelURL {
                await viewModel.loadLiveChannel(url: url)
            } else if let url = recordingURL {
                await viewModel.loadRecording(url: url, startPosition: startPosition)
            }
        }
    }

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
}

// MARK: - AV Player View Representable

struct AVPlayerViewRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    var aspectRatioMode: AspectRatioMode = .fit

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
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
    var onClose: () -> Void

    @FocusState private var focusedControl: PlayerControl?

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
            // Close button (X in circle)
            Button(action: onClose) {
                Image(systemName: "xmark")
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
                Text(viewModel.currentTimeFormatted)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .monospacedDigit()

                // Progress bar with scrubber
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.3))

                        // Progress
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * viewModel.progress)

                        // Scrubber dot
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .offset(x: geometry.size.width * viewModel.progress - 8)
                    }
                }
                .frame(height: 6)

                Text(viewModel.remainingTimeFormatted)
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

// MARK: - Preview

#Preview {
    VideoPlayerView(mediaItem: nil)
}
