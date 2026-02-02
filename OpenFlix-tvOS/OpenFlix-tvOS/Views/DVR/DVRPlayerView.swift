import SwiftUI
import AVKit

// MARK: - DVR Player View
// Player for recorded content with commercial skip

struct DVRPlayerView: View {
    let recording: Recording
    @StateObject private var playerViewModel = PlayerViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var showOverlay = true
    @State private var overlayHideTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Video Player
            if let player = playerViewModel.player {
                AVPlayerViewRepresentable(player: player)
                    .ignoresSafeArea()
            }

            // Loading
            if playerViewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(2)
                        .tint(.white)
                    Text("Loading recording...")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }

            // Error
            if let error = playerViewModel.error {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)

                    Text(error)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Button("Close") { dismiss() }
                        .buttonStyle(.bordered)
                }
            }

            // Controls overlay
            if showOverlay && !playerViewModel.isLoading && playerViewModel.error == nil {
                DVRControlsOverlay(
                    viewModel: playerViewModel,
                    recording: recording,
                    onClose: { dismiss() }
                )
            }
        }
        .onAppear {
            loadRecording()
        }
        .onDisappear {
            playerViewModel.cleanup()
            overlayHideTask?.cancel()
        }
        .onPlayPauseCommand {
            playerViewModel.togglePlayPause()
            showOverlayTemporarily()
        }
        .onMoveCommand { direction in
            handleMove(direction)
        }
        .onExitCommand {
            if showOverlay {
                withAnimation { showOverlay = false }
            } else {
                dismiss()
            }
        }
    }

    private func loadRecording() {
        guard let urlString = recording.streamUrl,
              let url = URL(string: urlString) else {
            playerViewModel.error = "Invalid recording URL"
            return
        }

        Task {
            await playerViewModel.loadRecording(
                url: url,
                startPosition: recording.viewOffset
            )
            scheduleHideOverlay()
        }
    }

    private func handleMove(_ direction: MoveCommandDirection) {
        showOverlayTemporarily()

        switch direction {
        case .left:
            playerViewModel.seekRelative(seconds: -10)
        case .right:
            playerViewModel.seekRelative(seconds: 10)
        default:
            break
        }
    }

    private func showOverlayTemporarily() {
        withAnimation { showOverlay = true }
        scheduleHideOverlay()
    }

    private func scheduleHideOverlay() {
        overlayHideTask?.cancel()
        overlayHideTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled && playerViewModel.isPlaying {
                await MainActor.run {
                    withAnimation { showOverlay = false }
                }
            }
        }
    }
}

// MARK: - DVR Controls Overlay

struct DVRControlsOverlay: View {
    @ObservedObject var viewModel: PlayerViewModel
    let recording: Recording
    let onClose: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.7), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)

                Spacer()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 250)
            }
            .ignoresSafeArea()

            VStack {
                // Top bar
                topBar
                    .padding(.top, 48)

                Spacer()

                // Center controls
                centerControls

                Spacer()

                // Bottom bar
                bottomBar
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 48)
        }
        .foregroundColor(.white)
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(recording.title)
                    .font(.system(size: 24, weight: .bold))

                HStack(spacing: 8) {
                    if let channel = recording.channelName {
                        Text(channel)
                            .foregroundColor(OpenFlixColors.primary)
                    }

                    if let date = recording.recordedAtFormatted {
                        Text("•")
                            .foregroundColor(OpenFlixColors.textTertiary)
                        Text(date)
                            .foregroundColor(OpenFlixColors.textSecondary)
                    }
                }
                .font(.system(size: 18))
            }
        }
    }

    private var centerControls: some View {
        HStack(spacing: 60) {
            // Skip back 30s
            Button(action: { viewModel.seekRelative(seconds: -30) }) {
                Image(systemName: "gobackward.30")
                    .font(.system(size: 44))
            }
            .buttonStyle(.plain)

            // Skip back 10s
            Button(action: { viewModel.seekRelative(seconds: -10) }) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 36))
            }
            .buttonStyle(.plain)

            // Play/Pause
            Button(action: { viewModel.togglePlayPause() }) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 70))
            }
            .buttonStyle(.plain)

            // Skip forward 10s
            Button(action: { viewModel.seekRelative(seconds: 10) }) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 36))
            }
            .buttonStyle(.plain)

            // Skip forward 30s
            Button(action: { viewModel.seekRelative(seconds: 30) }) {
                Image(systemName: "goforward.30")
                    .font(.system(size: 44))
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 16) {
            // Progress bar with commercial markers
            progressBar

            // Time labels
            HStack {
                Text(viewModel.currentTimeFormatted)
                    .font(.system(size: 18))

                Spacer()

                // Stream info
                if let info = viewModel.streamInfo, let res = info.resolutionLabel {
                    HStack(spacing: 8) {
                        Text(res)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(OpenFlixColors.primary)

                        if let codec = info.videoCodec {
                            Text(codec)
                                .font(.system(size: 14))
                                .foregroundColor(OpenFlixColors.textSecondary)
                        }
                    }
                }

                Spacer()

                Text(viewModel.remainingTimeFormatted)
                    .font(.system(size: 18))
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.white.opacity(0.3))

                // Commercial markers (if available)
                ForEach(recording.commercials, id: \.id) { commercial in
                    let startPosition = CGFloat(commercial.start) / CGFloat(max(recording.duration, 1))
                    let endPosition = CGFloat(commercial.end) / CGFloat(max(recording.duration, 1))
                    let width = (endPosition - startPosition) * geo.size.width

                    Rectangle()
                        .fill(Color.yellow.opacity(0.5))
                        .frame(width: width)
                        .offset(x: startPosition * geo.size.width)
                }

                // Progress
                Rectangle()
                    .fill(OpenFlixColors.primary)
                    .frame(width: geo.size.width * viewModel.progress)
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
        .frame(height: 8)
    }
}

// MARK: - Recording Extension for Player

extension Recording {
    var streamUrl: String? {
        // DVR recordings use the file path as stream URL
        // The server should provide the actual streaming endpoint
        filePath
    }

    var recordedAtFormatted: String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: startTime)
    }
}

#Preview {
    let recording = Recording(
        id: 1,
        title: "NFL Football: Chiefs vs Bills",
        subtitle: "Week 12",
        description: nil,
        thumb: nil,
        art: nil,
        channelId: "123",
        channelName: "ESPN",
        channelLogo: nil,
        startTime: Date().addingTimeInterval(-3600),
        endTime: Date(),
        duration: 3600000,
        status: .completed,
        filePath: nil,
        fileSize: nil,
        seasonNumber: nil,
        episodeNumber: nil,
        seriesRecord: false,
        seriesRuleId: nil,
        genres: [],
        contentRating: nil,
        year: nil,
        rating: nil,
        isMovie: false,
        viewOffset: nil,
        commercials: [],
        priority: 50
    )

    return DVRPlayerView(recording: recording)
}
