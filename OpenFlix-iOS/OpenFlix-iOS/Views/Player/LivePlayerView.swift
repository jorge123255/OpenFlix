import SwiftUI
import AVKit

struct LivePlayerView: View {
    let channel: Channel
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: LivePlayerViewModel
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var showMultiview = false
    
    init(channel: Channel) {
        self.channel = channel
        self._viewModel = StateObject(wrappedValue: LivePlayerViewModel(channel: channel))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()
                
                // Video player
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onTapGesture {
                            toggleControls()
                        }
                        .gesture(
                            DragGesture(minimumDistance: 50)
                                .onEnded { value in
                                    handleSwipe(value)
                                }
                        )
                } else {
                    // Loading state
                    VStack(spacing: XfinitySpacing.p4) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Loading \(channel.name)...")
                            .font(XfinityTypography.callout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Controls overlay
                if showControls {
                    PlayerControlsOverlay(
                        channel: channel,
                        viewModel: viewModel,
                        onClose: { dismiss() },
                        showMultiview: $showMultiview
                    )
                    .transition(.opacity)
                }
                
                // Error state
                if let error = viewModel.error {
                    ErrorOverlay(
                        message: error,
                        onRetry: { viewModel.play(channel: channel) },
                        onClose: { dismiss() }
                    )
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear {
            viewModel.play(channel: channel)
            startControlsTimer()
        }
        .onDisappear {
            viewModel.stop()
        }
        .fullScreenCover(isPresented: $showMultiview) {
            MultiviewPlayerV2(
                initialChannel: channel,
                viewModel: LiveTVViewModel(),
                onDismiss: { showMultiview = false },
                onFullScreen: { _ in showMultiview = false }
            )
        }
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
        if showControls {
            startControlsTimer()
        }
    }
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func handleSwipe(_ value: DragGesture.Value) {
        let verticalMovement = value.translation.height
        let horizontalMovement = value.translation.width
        
        if abs(verticalMovement) > abs(horizontalMovement) {
            // Vertical swipe
            if verticalMovement > 0 {
                // Swipe down - close or previous channel
                if value.startLocation.y < 100 {
                    dismiss()
                } else {
                    viewModel.previousChannel()
                }
            } else {
                // Swipe up - next channel
                viewModel.nextChannel()
            }
        }
    }
}

// MARK: - Player Controls Overlay
struct PlayerControlsOverlay: View {
    let channel: Channel
    @ObservedObject var viewModel: LivePlayerViewModel
    let onClose: () -> Void
    @Binding var showMultiview: Bool
    
    var body: some View {
        ZStack {
            // Gradient backgrounds
            VStack {
                // Top gradient
                LinearGradient(
                    colors: [Color.black.opacity(0.8), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                
                Spacer()
                
                // Bottom gradient
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
            }
            .ignoresSafeArea()
            
            VStack {
                // Top bar
                TopControlBar(
                    channel: channel,
                    onClose: onClose
                )
                
                Spacer()
                
                // Center controls
                CenterPlaybackControls(viewModel: viewModel)
                
                Spacer()
                
                // Bottom bar
                BottomControlBar(
                    channel: channel,
                    viewModel: viewModel,
                    showMultiview: $showMultiview
                )
            }
            .padding()
        }
    }
}

// MARK: - Top Control Bar
struct TopControlBar: View {
    let channel: Channel
    let onClose: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            // Close button
            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Channel info
            HStack(spacing: XfinitySpacing.p3) {
                // Channel logo
                if let logoURL = channel.logo, let url = URL(string: logoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fit)
                        default:
                            EmptyView()
                        }
                    }
                    .frame(width: 50, height: 35)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        // Live badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(XfinityColors.live)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(XfinityTypography.captionBold)
                                .foregroundColor(XfinityColors.live)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(4)
                        
                        if let number = channel.number {
                            Text("CH \(number)")
                                .font(XfinityTypography.captionBold)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Text(channel.name)
                        .font(XfinityTypography.bodyBold)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Cast button
            Button {
                // AirPlay/Cast
            } label: {
                Image(systemName: "airplayvideo")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .padding(12)
            }
        }
    }
}

// MARK: - Center Playback Controls
struct CenterPlaybackControls: View {
    @ObservedObject var viewModel: LivePlayerViewModel
    
    var body: some View {
        HStack(spacing: XfinitySpacing.p8) {
            // Previous channel
            Button {
                viewModel.previousChannel()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            .rotationEffect(.degrees(-90))
            
            // Play/Pause
            Button {
                viewModel.togglePlayPause()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            // Next channel
            Button {
                viewModel.nextChannel()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Bottom Control Bar (Channels-style Now Playing)
struct BottomControlBar: View {
    let channel: Channel
    @ObservedObject var viewModel: LivePlayerViewModel
    @Binding var showMultiview: Bool

    private var nowPlaying: Program? { viewModel.currentChannel?.nowPlaying ?? channel.nowPlaying }
    private var upNext: Program? { viewModel.currentChannel?.nextProgram ?? channel.nextProgram }
    private var activeChannel: Channel { viewModel.currentChannel ?? channel }

    var body: some View {
        VStack(spacing: 0) {
            // ── Now Playing info bar ──
            HStack(alignment: .center, spacing: 12) {
                // Channel logo + number
                VStack(spacing: 4) {
                    if let logoStr = activeChannel.logo, let url = artworkURL(logoStr) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fit)
                            } else {
                                channelPlaceholder
                            }
                        }
                        .frame(width: 48, height: 36)
                    } else {
                        channelPlaceholder
                    }

                    if let num = activeChannel.number {
                        Text("\(num)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(width: 56)

                // Program artwork thumbnail
                if let program = nowPlaying, let artStr = program.art ?? program.icon,
                   let url = artworkURL(artStr) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            artPlaceholder
                        }
                    }
                    .frame(width: 80, height: 56)
                    .cornerRadius(6)
                    .clipped()
                } else {
                    artPlaceholder
                }

                // Title + description
                VStack(alignment: .leading, spacing: 3) {
                    if let program = nowPlaying {
                        Text(program.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if let subtitle = program.subtitle ?? program.description {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(2)
                        }

                        // Time range
                        Text(program.timeRangeFormatted)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text(activeChannel.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Up Next
                if let next = upNext {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(upNextCountdown(next))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        if let artStr = next.art ?? next.icon, let url = artworkURL(artStr) {
                            AsyncImage(url: url) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    smallArtPlaceholder
                                }
                            }
                            .frame(width: 56, height: 40)
                            .cornerRadius(4)
                            .clipped()
                        } else {
                            smallArtPlaceholder
                        }

                        Text(next.title)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .frame(width: 70)
                    }
                    .frame(width: 76)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // ── Progress bar ──
            if let program = nowPlaying {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Color.white.opacity(0.15)
                        Color.purple
                            .frame(width: geo.size.width * program.progress)
                    }
                }
                .frame(height: 3)
                .cornerRadius(1.5)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }

            // ── Quick action buttons ──
            HStack(spacing: 0) {
                QuickActionButton(icon: "heart", label: "Favorite") {}
                QuickActionButton(icon: "record.circle", label: "Record") {}
                QuickActionButton(icon: "list.bullet", label: "Guide") {}
                QuickActionButton(icon: "info.circle", label: "Info") {}
                Spacer()
                QuickActionButton(icon: "rectangle.split.2x2", label: "Multi") {
                    showMultiview = true
                }
                QuickActionButton(icon: "pip", label: "PiP") {}
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Helpers

    private func artworkURL(_ path: String) -> URL? {
        if path.hasPrefix("http") { return URL(string: path) }
        guard let base = UserDefaults.standard.serverURL else { return nil }
        return base.appendingPathComponent(path)
    }

    private func upNextCountdown(_ program: Program) -> String {
        let mins = Int(program.startTime.timeIntervalSince(Date()) / 60)
        if mins <= 0 { return "Up next" }
        if mins < 60 { return "In \(mins) min..." }
        return "In \(mins / 60)h \(mins % 60)m..."
    }

    private var channelPlaceholder: some View {
        Text(activeChannel.name.prefix(3).uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white.opacity(0.5))
            .frame(width: 48, height: 36)
            .background(Color.white.opacity(0.1))
            .cornerRadius(4)
    }

    private var artPlaceholder: some View {
        Image(systemName: "tv")
            .font(.system(size: 20))
            .foregroundColor(.white.opacity(0.3))
            .frame(width: 80, height: 56)
            .background(Color.white.opacity(0.08))
            .cornerRadius(6)
    }

    private var smallArtPlaceholder: some View {
        Image(systemName: "tv")
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.3))
            .frame(width: 56, height: 40)
            .background(Color.white.opacity(0.08))
            .cornerRadius(4)
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(XfinityTypography.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Error Overlay
struct ErrorOverlay: View {
    let message: String
    let onRetry: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack(spacing: XfinitySpacing.p6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(XfinityColors.warning)
                
                Text("Playback Error")
                    .font(XfinityTypography.title2)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(XfinityTypography.callout)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: XfinitySpacing.p4) {
                    Button("Close") {
                        onClose()
                    }
                    .buttonStyle(XfinityOutlineButtonStyle())
                    
                    Button("Retry") {
                        onRetry()
                    }
                    .buttonStyle(XfinityPrimaryButtonStyle())
                }
            }
        }
    }
}

// MARK: - Live Player ViewModel
@MainActor
class LivePlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var error: String?
    @Published var currentChannel: Channel?
    
    private let liveTVRepository = LiveTVRepository()
    private var allChannels: [Channel] = []
    private var currentIndex: Int = 0
    
    init(channel: Channel) {
        self.currentChannel = channel
        loadChannels()
    }
    
    private func loadChannels() {
        Task {
            do {
                try await liveTVRepository.loadChannels()
                let channels = liveTVRepository.channels
                await MainActor.run {
                    self.allChannels = channels
                    if let current = currentChannel,
                       let index = channels.firstIndex(where: { $0.id == current.id }) {
                        self.currentIndex = index
                    }
                }
            } catch {
                print("Failed to load channels: \(error)")
            }
        }
    }
    
    func play(channel: Channel) {
        currentChannel = channel
        error = nil
        isBuffering = true

        guard let url = liveTVRepository.getStreamURL(for: channel) else {
            error = "Invalid stream URL"
            return
        }

        // Create player
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
        isPlaying = true
        isBuffering = false
    }
    
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    func nextChannel() {
        guard !allChannels.isEmpty else { return }
        currentIndex = (currentIndex + 1) % allChannels.count
        let nextChannel = allChannels[currentIndex]
        play(channel: nextChannel)
    }
    
    func previousChannel() {
        guard !allChannels.isEmpty else { return }
        currentIndex = currentIndex > 0 ? currentIndex - 1 : allChannels.count - 1
        let prevChannel = allChannels[currentIndex]
        play(channel: prevChannel)
    }
}
