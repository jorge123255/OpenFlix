import SwiftUI
import AVKit

// MARK: - Live TV View (Main Entry Point)

struct LiveTVView: View {
    @StateObject private var viewModel = LiveTVViewModel()
    @State private var showPlayer = false
    @State private var streamURL: URL?
    @State private var selectedChannelForPlayback: Channel?

    var body: some View {
        ZStack {
            EPGTheme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.channels.isEmpty {
                LoadingView(message: "Loading guide...")
            } else if let error = viewModel.error {
                ErrorView(message: error) {
                    Task { await viewModel.loadChannels() }
                }
            } else if viewModel.channels.isEmpty {
                EmptyStateView(
                    icon: "play.tv",
                    title: "No Channels",
                    message: "Add M3U or Xtream sources in Settings to get started."
                )
            } else {
                EPGGridView(
                    viewModel: viewModel,
                    onChannelSelect: { channel in
                        playChannel(channel)
                    },
                    onProgramSelect: { program, channel in
                        playChannel(channel)
                    }
                )
            }
        }
        .task {
            await viewModel.loadChannels()
            await viewModel.loadGuide()
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let url = streamURL, let channel = selectedChannelForPlayback {
                LiveTVPlayerView(
                    channel: channel,
                    streamURL: url,
                    viewModel: viewModel
                )
            }
        }
    }

    private func playChannel(_ channel: Channel) {
        NSLog("LiveTVView: Playing channel \(channel.name)")
        // Use stream URL directly from channel (like Android does)
        if let streamUrl = channel.streamUrl, let url = URL(string: streamUrl) {
            NSLog("LiveTVView: Using direct stream URL: \(streamUrl)")
            viewModel.selectChannel(channel)
            selectedChannelForPlayback = channel
            streamURL = url
            showPlayer = true
            return
        }
        NSLog("LiveTVView: No direct stream URL, fetching from API")

        // Fallback: Try API if no direct URL
        Task {
            do {
                let url = try await viewModel.getChannelStream(channel)
                viewModel.selectChannel(channel)
                selectedChannelForPlayback = channel
                streamURL = url
                showPlayer = true
            } catch let networkError as NetworkError {
                viewModel.error = networkError.errorDescription ?? "Failed to load stream"
            } catch {
                viewModel.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Live TV Player View

struct LiveTVPlayerView: View {
    let channel: Channel
    let streamURL: URL
    @ObservedObject var viewModel: LiveTVViewModel

    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var instantSwitchManager = InstantSwitchManager()
    @Environment(\.dismiss) var dismiss

    // UI State
    @State private var showOverlay = true
    @State private var showMiniEPG = false
    @State private var showChannelSurfing = false
    @State private var surfingChannel: Channel?
    @State private var surfingCountdown: Int = 0
    @State private var showStreamInfo = true
    @State private var showControls = false // Full controls panel
    @State private var showMultiview = false

    // Number pad entry
    @State private var channelNumberEntry: String = ""
    @State private var showChannelNumberEntry = false
    @State private var channelEntryTask: Task<Void, Never>?

    // Toast notification
    @State private var toastMessage: String?
    @State private var toastIcon: String?

    // Timers
    @State private var overlayHideTask: Task<Void, Never>?
    @State private var surfingTask: Task<Void, Never>?

    private let surfingDelay: Int = 3 // Seconds before auto-switching

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Video Player
            if let player = playerViewModel.player {
                AVPlayerViewRepresentable(
                    player: player,
                    aspectRatioMode: playerViewModel.aspectRatioMode
                )
                .ignoresSafeArea()
            }

            // Loading State
            if playerViewModel.isLoading {
                loadingOverlay
            }

            // Error State
            if let error = playerViewModel.error {
                errorOverlay(error)
            }

            // Channel Info Overlay (bottom)
            if showOverlay && playerViewModel.error == nil && !playerViewModel.isLoading {
                channelInfoOverlay
            }

            // Stream Info (top-right)
            if showOverlay && showStreamInfo && playerViewModel.streamInfo != nil {
                streamInfoOverlay
            }

            // Mini EPG Overlay
            if showMiniEPG {
                MiniEPGOverlay(
                    channels: viewModel.displayedChannels,
                    currentChannel: viewModel.selectedChannel ?? channel,
                    instantReadyChannels: instantSwitchManager.bufferedChannelIds,
                    onSelect: { newChannel in
                        showMiniEPG = false
                        changeChannel(to: newChannel)
                    },
                    onDismiss: { showMiniEPG = false }
                )
            }

            // Channel Surfing Overlay
            if showChannelSurfing, let surfing = surfingChannel {
                ChannelSurfingOverlay(
                    currentChannel: viewModel.selectedChannel ?? channel,
                    previewChannel: surfing,
                    countdown: surfingCountdown,
                    onConfirm: {
                        confirmChannelSwitch()
                    },
                    onCancel: {
                        cancelChannelSurfing()
                    }
                )
            }

            // Channel Number Entry Overlay
            if showChannelNumberEntry {
                channelNumberEntryOverlay
            }

            // Toast notification (outside of controls)
            if let message = toastMessage, !showControls {
                playerToastView(message: message, icon: toastIcon)
            }

            // Aspect ratio label (when cycling without controls)
            if playerViewModel.showAspectRatioLabel && !showControls {
                aspectRatioOverlay
            }

            // Full Controls Overlay (shown on select/tap)
            if showControls {
                LiveTVControlsOverlay(
                    playerViewModel: playerViewModel,
                    liveTVViewModel: viewModel,
                    channel: viewModel.selectedChannel ?? channel,
                    onClose: { dismiss() },
                    onGuide: {
                        showControls = false
                        showMiniEPG = true
                    },
                    onChannels: {
                        showControls = false
                        showMiniEPG = true
                    },
                    onPreviousChannel: {
                        handlePreviousChannel()
                    },
                    onToggleFavorite: {
                        handleToggleFavorite()
                    },
                    onMultiview: {
                        showControls = false
                        showMultiview = true
                    },
                    onDismiss: {
                        showControls = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showMultiview) {
            MultiviewView(
                initialChannelIds: [viewModel.selectedChannel?.id ?? channel.id],
                onBack: {
                    showMultiview = false
                },
                onFullScreen: { fullScreenChannel in
                    showMultiview = false
                    // Switch to the selected channel from multiview
                    changeChannel(to: fullScreenChannel)
                }
            )
        }
        .onAppear {
            Task {
                await playerViewModel.loadLiveChannel(url: streamURL)
                scheduleHideOverlay()

                // Start preloading adjacent channels
                instantSwitchManager.preloadAdjacentChannels(
                    current: channel,
                    channels: viewModel.displayedChannels
                )
            }
        }
        .onDisappear {
            playerViewModel.cleanup()
            instantSwitchManager.cleanup()
            overlayHideTask?.cancel()
            surfingTask?.cancel()
            channelEntryTask?.cancel()
        }
        .onPlayPauseCommand {
            // Show full controls on play/pause press (Space bar)
            if !showControls && !showMiniEPG && !showChannelSurfing {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = true
                }
            } else if showControls {
                playerViewModel.togglePlayPause()
            }
            showOverlayTemporarily()
        }
        .focusable()
        .onKeyPress(.return) {
            // Enter/Return key - show controls
            if !showControls && !showMiniEPG && !showChannelSurfing {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = true
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.space) {
            // Space key - also show controls
            if !showControls && !showMiniEPG && !showChannelSurfing {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = true
                }
                return .handled
            }
            return .ignored
        }
        // P key - Previous channel
        .onKeyPress("p") {
            handlePreviousChannel()
            return .handled
        }
        // A key - Cycle audio track
        .onKeyPress("a") {
            if let track = playerViewModel.cycleAudioTrack() {
                showPlayerToast("Audio: \(track.label)", icon: "speaker.wave.3")
            }
            return .handled
        }
        // S key - Cycle subtitles
        .onKeyPress("s") {
            if let track = playerViewModel.cycleSubtitleTrack() {
                showPlayerToast("Subtitles: \(track.label)", icon: "captions.bubble")
            } else {
                showPlayerToast("Subtitles Off", icon: "captions.bubble")
            }
            return .handled
        }
        // F key - Toggle favorite
        .onKeyPress("f") {
            handleToggleFavorite()
            if let ch = viewModel.selectedChannel {
                showPlayerToast(ch.isFavorite ? "Removed from Favorites" : "Added to Favorites",
                               icon: ch.isFavorite ? "heart" : "heart.fill")
            }
            return .handled
        }
        // R key - Cycle aspect ratio
        .onKeyPress("r") {
            let mode = playerViewModel.cycleAspectRatio()
            showPlayerToast(mode.rawValue, icon: mode.icon)
            return .handled
        }
        // M key - Launch multiview
        .onKeyPress("m") {
            if !showControls && !showMiniEPG && !showChannelSurfing && !showMultiview {
                showMultiview = true
            }
            return .handled
        }
        // Number keys 0-9 for direct channel entry
        .onKeyPress(characters: .decimalDigits) { press in
            handleNumberKeyPress(press.characters)
            return .handled
        }
        .onMoveCommand { direction in
            if showControls {
                // Let controls handle movement
                return
            }
            handleMoveCommand(direction)
        }
        .onExitCommand {
            handleExitCommand()
        }
        // Tap gesture to show/hide controls
        .gesture(
            TapGesture()
                .onEnded { _ in
                    if !showMiniEPG && !showChannelSurfing {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showControls.toggle()
                        }
                    }
                }
        )
    }

    // MARK: - Overlays

    private var loadingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(2)
                .tint(.white)
            Text("Loading \(channel.name)...")
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
    }

    private func errorOverlay(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text(error)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Button("Try Again") {
                    Task {
                        await playerViewModel.loadLiveChannel(url: streamURL)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
        )
    }

    private var channelInfoOverlay: some View {
        VStack {
            Spacer()

            HStack(alignment: .bottom, spacing: 24) {
                // Channel logo
                channelLogoView

                // Channel and program info
                channelInfoView

                Spacer()

                // Remote hints
                remoteHintsView
            }
            .padding(40)
            .background(EPGTheme.playerGradient)
        }
        .foregroundColor(.white)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var channelLogoView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))

            AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                .aspectRatio(contentMode: .fit)
                .padding(12)
        }
        .frame(width: 120, height: 80)
    }

    private var channelInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Channel number and name
            HStack(spacing: 12) {
                if let number = channel.number {
                    Text("\(number)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(EPGTheme.accent)
                }
                Text(channel.name)
                    .font(.system(size: 28, weight: .bold))
            }

            // Current program
            if let program = viewModel.selectedChannel?.nowPlaying ?? channel.nowPlaying {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Text(program.title)
                            .font(.system(size: 22, weight: .medium))

                        if program.isLive {
                            LiveIndicator()
                        }
                    }

                    HStack(spacing: 12) {
                        Text(program.timeRangeFormatted)
                            .font(.system(size: 18))
                            .foregroundColor(EPGTheme.textSecondary)

                        if let rating = program.rating {
                            Text(rating)
                                .font(.system(size: 16))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    // Progress bar
                    EPGProgressBar(progress: program.progress, height: 5)
                        .frame(maxWidth: 400)
                }
            }
        }
    }

    private var remoteHintsView: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.up")
                Image(systemName: "chevron.down")
            }
            Text("CH")
                .font(.system(size: 16, weight: .medium))

            Spacer().frame(height: 8)

            Text("Menu")
                .font(.system(size: 14))
                .foregroundColor(EPGTheme.textMuted)
            Text("Guide")
                .font(.system(size: 12))
                .foregroundColor(EPGTheme.textMuted)
        }
        .foregroundColor(EPGTheme.textSecondary)
        .padding(.leading, 20)
    }

    private var streamInfoOverlay: some View {
        VStack {
            HStack {
                Spacer()
                StreamInfoOverlay(streamInfo: playerViewModel.streamInfo)
                    .padding(24)
            }
            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Input Handling

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        showOverlayTemporarily()

        switch direction {
        case .up:
            startChannelSurfing(direction: .previous)
        case .down:
            startChannelSurfing(direction: .next)
        case .left, .right:
            // Could be used for seeking in DVR/catchup mode
            break
        @unknown default:
            break
        }
    }

    private func handleExitCommand() {
        if showControls {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls = false
            }
        } else if showMiniEPG {
            showMiniEPG = false
        } else if showChannelSurfing {
            cancelChannelSurfing()
        } else if showOverlay {
            // Toggle mini EPG on menu press when overlay is showing
            showMiniEPG = true
        } else {
            dismiss()
        }
    }

    // MARK: - Channel Surfing

    private func startChannelSurfing(direction: ChannelDirection) {
        let newChannel: Channel?
        switch direction {
        case .next:
            newChannel = viewModel.nextChannel()
        case .previous:
            newChannel = viewModel.previousChannel()
        }

        guard let channel = newChannel else { return }

        // Cancel existing surfing task
        surfingTask?.cancel()

        surfingChannel = channel
        surfingCountdown = surfingDelay
        showChannelSurfing = true

        // Start countdown
        surfingTask = Task {
            for remaining in stride(from: surfingDelay, through: 0, by: -1) {
                if Task.isCancelled { return }
                surfingCountdown = remaining
                if remaining > 0 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
            if !Task.isCancelled {
                await MainActor.run {
                    confirmChannelSwitch()
                }
            }
        }
    }

    private func confirmChannelSwitch() {
        guard let newChannel = surfingChannel else { return }
        surfingTask?.cancel()
        showChannelSurfing = false
        changeChannel(to: newChannel)
    }

    private func cancelChannelSurfing() {
        surfingTask?.cancel()
        surfingChannel = nil
        showChannelSurfing = false
    }

    private func changeChannel(to newChannel: Channel) {
        Task {
            viewModel.selectChannel(newChannel)

            // Load the channel normally - instant switch pre-buffering helps with faster start
            // but we still go through PlayerViewModel for proper state management
            let isPreBuffered = instantSwitchManager.isChannelReady(newChannel)
            if isPreBuffered {
                instantSwitchManager.removeFromBuffer(newChannel)
                showPlayerToast("INSTANT", icon: "bolt.fill")
            }

            if let urlString = newChannel.streamUrl, let url = URL(string: urlString) {
                await playerViewModel.loadLiveChannel(url: url)
            } else if let url = try? await viewModel.getChannelStream(newChannel) {
                await playerViewModel.loadLiveChannel(url: url)
            }

            // Start preloading new adjacent channels
            instantSwitchManager.preloadAdjacentChannels(
                current: newChannel,
                channels: viewModel.displayedChannels
            )
        }
    }

    // MARK: - Previous Channel Toggle

    private func handlePreviousChannel() {
        guard let prevChannel = viewModel.togglePreviousChannel() else { return }
        showControls = false
        changeChannel(to: prevChannel)
    }

    // MARK: - Toggle Favorite

    private func handleToggleFavorite() {
        guard let currentChannel = viewModel.selectedChannel else { return }
        Task {
            await viewModel.toggleFavorite(currentChannel)
        }
    }

    // MARK: - Number Pad Entry

    private func handleNumberKeyPress(_ characters: String) {
        channelEntryTask?.cancel()

        channelNumberEntry += characters
        showChannelNumberEntry = true

        // Auto-switch after 2 seconds or when 3+ digits entered
        channelEntryTask = Task {
            let delay = channelNumberEntry.count >= 3 ? 500_000_000 : 2_000_000_000
            try? await Task.sleep(nanoseconds: UInt64(delay))

            if !Task.isCancelled {
                await MainActor.run {
                    switchToChannelNumber()
                }
            }
        }
    }

    private func switchToChannelNumber() {
        guard let number = Int(channelNumberEntry),
              let targetChannel = viewModel.displayedChannels.first(where: { $0.number == number }) else {
            // Channel not found
            showPlayerToast("Channel \(channelNumberEntry) not found", icon: "xmark.circle")
            channelNumberEntry = ""
            showChannelNumberEntry = false
            return
        }

        showChannelNumberEntry = false
        channelNumberEntry = ""
        changeChannel(to: targetChannel)
    }

    private func cancelChannelNumberEntry() {
        channelEntryTask?.cancel()
        channelNumberEntry = ""
        showChannelNumberEntry = false
    }

    // MARK: - Toast Helper

    private func showPlayerToast(_ message: String, icon: String? = nil) {
        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = message
            toastIcon = icon
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    toastMessage = nil
                    toastIcon = nil
                }
            }
        }
    }

    // MARK: - Overlay Views

    private var channelNumberEntryOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 12) {
                    Text("Go to Channel")
                        .font(.system(size: 18))
                        .foregroundColor(EPGTheme.textSecondary)

                    Text(channelNumberEntry)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text("Press Back to cancel")
                        .font(.system(size: 14))
                        .foregroundColor(EPGTheme.textMuted)
                }
                .padding(40)
                .background(Color.black.opacity(0.9))
                .cornerRadius(20)
                .padding(60)
            }
        }
        .transition(.opacity.combined(with: .scale))
        .onExitCommand {
            cancelChannelNumberEntry()
        }
    }

    private func playerToastView(message: String, icon: String?) -> some View {
        VStack {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                }
                Text(message)
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .padding(.top, 80)

            Spacer()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var aspectRatioOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: playerViewModel.aspectRatioMode.icon)
                        .font(.system(size: 32))
                    Text(playerViewModel.aspectRatioMode.rawValue)
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                .padding(40)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Overlay Management

    private func showOverlayTemporarily() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showOverlay = true
        }
        scheduleHideOverlay()
    }

    private func scheduleHideOverlay() {
        overlayHideTask?.cancel()
        overlayHideTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOverlay = false
                    }
                }
            }
        }
    }
}

// MARK: - Channel Direction

enum ChannelDirection {
    case next
    case previous
}

// MARK: - Live TV Controls Overlay

struct LiveTVControlsOverlay: View {
    @ObservedObject var playerViewModel: PlayerViewModel
    @ObservedObject var liveTVViewModel: LiveTVViewModel
    let channel: Channel
    var onClose: () -> Void
    var onGuide: () -> Void
    var onChannels: () -> Void
    var onPreviousChannel: () -> Void
    var onToggleFavorite: () -> Void
    var onMultiview: () -> Void
    var onDismiss: () -> Void

    @FocusState private var focusedControl: LiveTVControl?
    @State private var showSleepTimerPicker = false
    @State private var toastMessage: String?
    @State private var toastIcon: String?

    enum LiveTVControl: Hashable {
        case close, streamInfo, mute
        case skipBack, playPause, skipForward
        case favorite, previousChannel, aspectRatio, sleepTimer, audio, subtitles, multiview
        case guide, channels
    }

    var body: some View {
        ZStack {
            // Semi-transparent background - no tap gesture to avoid blocking focus
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 48)
                    .padding(.top, 40)

                Spacer()

                // Channel Info Card
                channelInfoCard
                    .padding(.horizontal, 80)

                Spacer().frame(height: 40)

                // Playback Controls
                playbackControls

                Spacer().frame(height: 40)

                // Action Buttons Row
                actionButtonsRow
                    .padding(.horizontal, 80)

                Spacer()

                // Bottom Bar
                bottomBar
                    .padding(.horizontal, 48)
                    .padding(.bottom, 40)
            }

            // Toast notification
            if let message = toastMessage {
                toastView(message: message, icon: toastIcon)
            }

            // Aspect ratio label
            if playerViewModel.showAspectRatioLabel {
                aspectRatioLabel
            }

            // Sleep timer picker
            if showSleepTimerPicker {
                sleepTimerPickerView
            }
        }
        .onAppear {
            focusedControl = .playPause
        }
        .onExitCommand {
            if showSleepTimerPicker {
                showSleepTimerPicker = false
            } else {
                onDismiss()
            }
        }
        .animation(.easeInOut(duration: 0.15), value: focusedControl)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 20) {
            // Close button
            controlButton(
                icon: "xmark",
                control: .close,
                action: onClose
            )

            Spacer()

            // Stream info button
            if let streamInfo = playerViewModel.streamInfo {
                Button(action: {}) {
                    HStack(spacing: 8) {
                        if let res = streamInfo.resolutionLabel {
                            Text(res)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(EPGTheme.resolutionColor(height: streamInfo.videoHeight))
                        }
                        if let codec = streamInfo.videoCodec {
                            Text(codec)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                }
                .buttonStyle(.card)
                .focused($focusedControl, equals: .streamInfo)
                .scaleEffect(focusedControl == .streamInfo ? 1.05 : 1.0)
            }

            // Sleep timer indicator
            if playerViewModel.sleepTimerRemaining > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "moon.zzz.fill")
                    Text(playerViewModel.sleepTimerLabel)
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
            }

            // Mute button
            controlButton(
                icon: playerViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                control: .mute,
                iconColor: playerViewModel.isMuted ? .red : .white,
                action: {
                    playerViewModel.toggleMute()
                    showToast(playerViewModel.isMuted ? "Muted" : "Unmuted",
                              icon: playerViewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
            )
        }
    }

    // MARK: - Channel Info Card

    private var channelInfoCard: some View {
        HStack(spacing: 24) {
            // Channel logo
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.6))
                AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .padding(12)
            }
            .frame(width: 100, height: 70)

            // Channel info
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    if let number = channel.number {
                        Text("\(number)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(EPGTheme.accent)
                    }
                    Text(channel.name)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }

                if let program = channel.nowPlaying {
                    HStack(spacing: 10) {
                        Text(program.title)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))

                        if program.isLive {
                            LiveIndicator()
                        }
                    }

                    HStack(spacing: 12) {
                        Text(program.timeRangeFormatted)
                            .font(.system(size: 16))
                            .foregroundColor(EPGTheme.textSecondary)

                        EPGProgressBar(progress: program.progress, height: 5)
                            .frame(width: 200)

                        Text("\(Int(program.progress * 100))%")
                            .font(.system(size: 14))
                            .foregroundColor(EPGTheme.textMuted)
                    }
                }
            }

            Spacer()

            // Favorite indicator
            if channel.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 60) {
            // Skip back 10s
            controlButton(
                icon: "gobackward.10",
                control: .skipBack,
                size: 60,
                iconSize: 30,
                action: {
                    playerViewModel.skipBackward()
                    showToast("-10s", icon: "gobackward.10")
                }
            )

            // Play/Pause
            Button(action: { playerViewModel.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(EPGTheme.accent.opacity(0.3))
                        .frame(width: 100, height: 100)

                    Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.card)
            .focused($focusedControl, equals: .playPause)

            // Skip forward 10s
            controlButton(
                icon: "goforward.10",
                control: .skipForward,
                size: 60,
                iconSize: 30,
                action: {
                    playerViewModel.skipForward()
                    showToast("+10s", icon: "goforward.10")
                }
            )
        }
    }

    // MARK: - Action Buttons Row

    private var actionButtonsRow: some View {
        HStack(spacing: 16) {
            // Favorite
            actionButton(
                icon: channel.isFavorite ? "heart.fill" : "heart",
                label: "Favorite",
                control: .favorite,
                iconColor: channel.isFavorite ? .red : .white,
                action: {
                    onToggleFavorite()
                    showToast(channel.isFavorite ? "Removed from Favorites" : "Added to Favorites",
                              icon: channel.isFavorite ? "heart" : "heart.fill")
                }
            )

            // Previous Channel
            actionButton(
                icon: "arrow.uturn.left",
                label: "Previous",
                control: .previousChannel,
                isEnabled: liveTVViewModel.lastViewedChannel != nil,
                action: {
                    onPreviousChannel()
                }
            )

            // Aspect Ratio
            actionButton(
                icon: playerViewModel.aspectRatioMode.icon,
                label: playerViewModel.aspectRatioMode.rawValue,
                control: .aspectRatio,
                action: {
                    let mode = playerViewModel.cycleAspectRatio()
                    showToast(mode.rawValue, icon: mode.icon)
                }
            )

            // Sleep Timer
            actionButton(
                icon: "moon.zzz",
                label: playerViewModel.sleepTimerRemaining > 0 ? playerViewModel.sleepTimerLabel : "Sleep",
                control: .sleepTimer,
                iconColor: playerViewModel.sleepTimerRemaining > 0 ? .orange : .white,
                action: {
                    showSleepTimerPicker = true
                }
            )

            // Audio Track
            actionButton(
                icon: "speaker.wave.3",
                label: "Audio",
                control: .audio,
                action: {
                    if let track = playerViewModel.cycleAudioTrack() {
                        showToast("Audio: \(track.label)", icon: "speaker.wave.3")
                    }
                }
            )

            // Subtitles
            actionButton(
                icon: "captions.bubble",
                label: "Subtitles",
                control: .subtitles,
                action: {
                    if let track = playerViewModel.cycleSubtitleTrack() {
                        showToast("Subtitles: \(track.label)", icon: "captions.bubble")
                    } else {
                        showToast("Subtitles Off", icon: "captions.bubble")
                    }
                }
            )

            // Multiview
            actionButton(
                icon: "rectangle.split.2x2",
                label: "Multiview",
                control: .multiview,
                action: {
                    onMultiview()
                }
            )
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 24) {
            // Guide button
            Button(action: onGuide) {
                Label("Guide", systemImage: "list.bullet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(EPGTheme.accent.opacity(0.3))
                    .cornerRadius(10)
            }
            .buttonStyle(.card)
            .focused($focusedControl, equals: .guide)

            Spacer()

            // Keyboard hints
            HStack(spacing: 20) {
                keyboardHint(key: "P", action: "Previous")
                keyboardHint(key: "F", action: "Favorite")
                keyboardHint(key: "R", action: "Aspect")
                keyboardHint(key: "M", action: "Multiview")
            }
            .foregroundColor(EPGTheme.textMuted)

            Spacer()

            // Channels button
            Button(action: onChannels) {
                Label("Channels", systemImage: "square.grid.2x2")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
            }
            .buttonStyle(.card)
            .focused($focusedControl, equals: .channels)
        }
    }

    // MARK: - Helper Views

    private func controlButton(
        icon: String,
        control: LiveTVControl,
        size: CGFloat = 50,
        iconSize: CGFloat = 20,
        iconColor: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundColor(iconColor)
                .frame(width: size, height: size)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
        .buttonStyle(.card)
        .focused($focusedControl, equals: control)
    }

    private func actionButton(
        icon: String,
        label: String,
        control: LiveTVControl,
        iconColor: Color = .white,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isEnabled ? iconColor : .gray)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isEnabled ? .white : .gray)
            }
            .frame(width: 80, height: 70)
            .background(Color.white.opacity(isEnabled ? 0.15 : 0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.card)
        .disabled(!isEnabled)
        .focused($focusedControl, equals: control)
    }

    private func keyboardHint(key: String, action: String) -> some View {
        HStack(spacing: 6) {
            Text(key)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.2))
                .cornerRadius(4)
            Text(action)
                .font(.system(size: 14))
        }
    }

    private func toastView(message: String, icon: String?) -> some View {
        VStack {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                }
                Text(message)
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.8))
            .cornerRadius(12)
            .padding(.top, 120)

            Spacer()
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var aspectRatioLabel: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: playerViewModel.aspectRatioMode.icon)
                        .font(.system(size: 32))
                    Text(playerViewModel.aspectRatioMode.rawValue)
                        .font(.system(size: 20, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                .padding(40)
            }
        }
        .transition(.opacity)
    }

    private var sleepTimerPickerView: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 24) {
                Text("Sleep Timer")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 16) {
                    ForEach(SleepTimerOption.allCases, id: \.self) { option in
                        Button(action: {
                            playerViewModel.setSleepTimer(option)
                            showSleepTimerPicker = false
                            if option != .off {
                                showToast("Sleep in \(option.label)", icon: "moon.zzz")
                            } else {
                                showToast("Sleep Timer Off", icon: "moon.zzz")
                            }
                        }) {
                            Text(option.label)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 120, height: 60)
                                .background(
                                    option == playerViewModel.sleepTimerOption
                                        ? EPGTheme.accent.opacity(0.5)
                                        : Color.white.opacity(0.2)
                                )
                                .cornerRadius(12)
                        }
                        .buttonStyle(.card)
                    }
                }
                .padding(.horizontal, 60)

                Button("Cancel") {
                    showSleepTimerPicker = false
                }
                .buttonStyle(.card)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 16)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Toast Helper

    private func showToast(_ message: String, icon: String? = nil) {
        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = message
            toastIcon = icon
        }

        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    toastMessage = nil
                    toastIcon = nil
                }
            }
        }
    }
}

// MARK: - Stream Info Overlay

struct StreamInfoOverlay: View {
    let streamInfo: StreamInfo?

    var body: some View {
        if let info = streamInfo {
            VStack(alignment: .trailing, spacing: 8) {
                // Resolution badge
                if let resLabel = info.resolutionLabel {
                    HStack(spacing: 6) {
                        if (info.videoHeight ?? 0) >= 1080 {
                            Image(systemName: (info.videoHeight ?? 0) >= 2160 ? "sparkles.tv" : "tv")
                                .font(.system(size: 16))
                        }
                        Text(resLabel)
                            .font(.system(size: 20, weight: .bold))
                    }
                    .foregroundColor(EPGTheme.resolutionColor(height: info.videoHeight))
                }

                // Technical details
                VStack(alignment: .trailing, spacing: 4) {
                    if let res = info.resolution {
                        Text(res)
                            .font(.system(size: 14))
                    }

                    if let codec = info.videoCodec {
                        Text(codec)
                            .font(.system(size: 12))
                    }

                    if let audioLabel = info.audioChannelsLabel {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 10))
                            Text(audioLabel)
                            if let audioCodec = info.audioCodec {
                                Text("• \(audioCodec)")
                            }
                        }
                        .font(.system(size: 12))
                    }

                    if let bitrate = info.videoBitrateLabel {
                        Text(bitrate)
                            .font(.system(size: 12))
                    }
                }
                .foregroundColor(EPGTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
            )
        }
    }
}

// MARK: - Channel Surfing Overlay

struct ChannelSurfingOverlay: View {
    let currentChannel: Channel
    let previewChannel: Channel
    let countdown: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 32) {
                // Current channel (dim)
                channelPreview(channel: currentChannel, isCurrent: true)
                    .opacity(0.5)

                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 40))
                    .foregroundColor(EPGTheme.accent)

                // Preview channel (bright)
                channelPreview(channel: previewChannel, isCurrent: false)

                // Countdown
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / 3.0)
                        .stroke(EPGTheme.accent, lineWidth: 4)
                        .rotationEffect(.degrees(-90))

                    Text("\(countdown)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 60, height: 60)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
            )

            // Hints
            HStack(spacing: 24) {
                Label("Select to switch now", systemImage: "hand.tap")
                Label("Back to cancel", systemImage: "arrow.uturn.backward")
            }
            .font(.system(size: 16))
            .foregroundColor(EPGTheme.textMuted)
            .padding(.top, 16)

            Spacer().frame(height: 80)
        }
        .foregroundColor(.white)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func channelPreview(channel: Channel, isCurrent: Bool) -> some View {
        VStack(spacing: 12) {
            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            }
            .frame(width: 100, height: 70)

            // Number and name
            VStack(spacing: 4) {
                if let number = channel.number {
                    Text("\(number)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(isCurrent ? .white : EPGTheme.accent)
                }
                Text(channel.name)
                    .font(.system(size: 18))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Mini EPG Overlay

struct MiniEPGOverlay: View {
    let channels: [Channel]
    let currentChannel: Channel
    var instantReadyChannels: Set<String> = []
    @State private var selectedIndex: Int = 0
    let onSelect: (Channel) -> Void
    let onDismiss: () -> Void

    @FocusState private var focusedIndex: Int?

    private var visibleChannels: [Channel] {
        guard let currentIndex = channels.firstIndex(where: { $0.id == currentChannel.id }) else {
            return Array(channels.prefix(7))
        }

        let start = max(0, currentIndex - 3)
        let end = min(channels.count, start + 7)
        return Array(channels[start..<end])
    }

    var body: some View {
        ZStack {
            // Dim background - no tap gesture to avoid blocking focus
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Title bar
                HStack {
                    Text("Quick Guide")
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                    Text("Press Back to close")
                        .font(.system(size: 18))
                        .foregroundColor(EPGTheme.textMuted)
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 20)

                Divider()
                    .background(EPGTheme.textMuted.opacity(0.3))

                // Channel list
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(visibleChannels.enumerated()), id: \.element.id) { index, channel in
                            MiniEPGChannelRow(
                                channel: channel,
                                isSelected: channel.id == currentChannel.id,
                                isFocused: focusedIndex == index,
                                isInstantReady: instantReadyChannels.contains(channel.id)
                            ) {
                                onSelect(channel)
                            }
                            .focused($focusedIndex, equals: index)
                        }
                    }
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                }
            }
        }
        .onAppear {
            // Focus current channel
            if let index = visibleChannels.firstIndex(where: { $0.id == currentChannel.id }) {
                focusedIndex = index
            }
        }
        .onExitCommand {
            onDismiss()
        }
    }
}

struct MiniEPGChannelRow: View {
    let channel: Channel
    let isSelected: Bool
    let isFocused: Bool
    var isInstantReady: Bool = false
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Number
                if let number = channel.number {
                    Text("\(number)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(EPGTheme.accent)
                        .frame(width: 50)
                }

                // Logo
                AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 36)

                // Name
                Text(channel.name)
                    .font(.system(size: 22, weight: isSelected ? .bold : .medium))
                    .foregroundColor(.white)

                // Instant switch badge
                if isInstantReady {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text("INSTANT")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
                }

                Spacer()

                // Now playing
                if let program = channel.nowPlaying {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(program.title)
                            .font(.system(size: 18))
                            .foregroundColor(EPGTheme.textSecondary)
                            .lineLimit(1)

                        if program.isCurrentlyAiring {
                            HStack(spacing: 8) {
                                EPGProgressBar(progress: program.progress, height: 3)
                                    .frame(width: 80)

                                Text("\(program.remainingMinutes)m")
                                    .font(.system(size: 14))
                                    .foregroundColor(EPGTheme.textMuted)
                            }
                        }
                    }
                }

                // Playing indicator
                if isSelected {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 20))
                        .foregroundColor(EPGTheme.accent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? EPGTheme.accent.opacity(0.2) : (isFocused ? EPGTheme.surfaceElevated : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? EPGTheme.accent : (isFocused ? .white.opacity(0.5) : .clear), lineWidth: 2)
            )
        }
        .buttonStyle(.card)
    }
}

// MARK: - Preview

#Preview {
    LiveTVView()
}
