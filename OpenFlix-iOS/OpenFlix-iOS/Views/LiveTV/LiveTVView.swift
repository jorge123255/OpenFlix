import SwiftUI
import AVKit
#if !targetEnvironment(simulator)
import MobileVLCKit
#endif

#if !os(tvOS)
extension Notification.Name {
    static let sidecarToggle = Notification.Name("sidecarToggle")
}
#endif

// MARK: - Live TV View (Main Entry Point)

struct LiveTVView: View {
    @StateObject private var viewModel = LiveTVViewModel()
    @StateObject private var dvrViewModel = DVRViewModel()
    @State private var showPlayer = false
    @State private var streamURL: URL?
    @State private var selectedChannelForPlayback: Channel?
    
    // Feature navigation
    @State private var showCatchup = false
    @State private var showOnLater = false
    @State private var showTeamPass = false
    @State private var showChannelGroups = false
    @State private var showFullGuide = false

    var body: some View {
        NavigationStack {
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
                    #if os(tvOS)
                    TVOSLiveBrowserView(
                        viewModel: viewModel,
                        dvrViewModel: dvrViewModel,
                        onPlayChannel: playChannel,
                        onOpenGuide: { showFullGuide = true },
                        onOpenCatchup: { showCatchup = true },
                        onOpenOnLater: { showOnLater = true },
                        onOpenTeamPass: { showTeamPass = true },
                        onOpenChannelGroups: { showChannelGroups = true }
                    )
                    #else
                    if viewModel.isGuideLoading && !viewModel.didLoadGuide {
                        LoadingView(message: "Loading guide data...")
                    } else {
                    EPGGuideView(
                        viewModel: viewModel,
                        onChannelSelect: { channel in
                            playChannel(channel)
                        }
                    )
                    }
                    #endif
                }
            }
            #if !os(tvOS)
            .navigationTitle("Live TV")
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if !os(tvOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showCatchup = true } label: {
                            Label("Catch Up", systemImage: "clock.arrow.circlepath")
                        }
                        Button { showOnLater = true } label: {
                            Label("On Later", systemImage: "clock.badge.checkmark")
                        }
                        Button { showTeamPass = true } label: {
                            Label("Team Pass", systemImage: "sportscourt")
                        }
                        Button { showChannelGroups = true } label: {
                            Label("Channel Groups", systemImage: "rectangle.stack")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
                #endif
            }
            .navigationDestination(isPresented: $showCatchup) {
                CatchupView()
            }
            .navigationDestination(isPresented: $showOnLater) {
                OnLaterView()
            }
            .navigationDestination(isPresented: $showTeamPass) {
                TeamPassView()
            }
            .navigationDestination(isPresented: $showChannelGroups) {
                ChannelGroupsView()
            }
            .navigationDestination(isPresented: $showFullGuide) {
                EPGGuideView(
                    viewModel: viewModel,
                    onChannelSelect: { channel in
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
            if let channel = selectedChannelForPlayback {
                #if os(tvOS)
                TVLiveChannelPlayerView(
                    initialChannel: channel,
                    initialStreamURL: streamURL,
                    viewModel: viewModel
                )
                .environmentObject(dvrViewModel)
                #else
                if let url = streamURL {
                    LiveTVPlayerView(
                        channel: channel,
                        streamURL: url,
                        viewModel: viewModel
                    )
                    .environmentObject(dvrViewModel)
                }
                #endif
            }
        }
    }

    private func playChannel(_ channel: Channel) {
        if let url = channel.preferredPlaybackURL {
            viewModel.selectChannel(channel)
            selectedChannelForPlayback = channel
            streamURL = url
            showPlayer = true
            return
        }

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

#if os(tvOS)
struct TVLiveChannelPlayerView: View {
    @State private var channel: Channel
    let initialStreamURL: URL?
    @ObservedObject var viewModel: LiveTVViewModel

    @StateObject private var vlcPlayer = VLCPlayerViewModel()
    @StateObject private var dvrRepository = DVRRepository()
    @StateObject private var liveTVRepository = LiveTVRepository()
    @Environment(\.dismiss) private var dismiss

    @State private var showControls = true
    @State private var controlsHideTask: Task<Void, Never>?
    @State private var showSleepPicker = false
    @State private var showRecordOptions = false
    @State private var toastMessage: String?
    @State private var toastIcon: String?
    @State private var userPaused = false
    @State private var behindLive = false
    @State private var nowPlaying: Program?
    @State private var upNext: Program?
    @State private var epgRefreshTask: Task<Void, Never>?
    @State private var previousChannel: Channel?
    @State private var showChannelBanner = false
    @State private var channelBannerTask: Task<Void, Never>?
    @State private var showMultiview = false
    @State private var multiviewPickedChannel: Channel?

    init(initialChannel: Channel, initialStreamURL: URL?, viewModel: LiveTVViewModel) {
        self._channel = State(initialValue: initialChannel)
        self.initialStreamURL = initialStreamURL
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VLCPlayerView(viewModel: vlcPlayer)
                .ignoresSafeArea()

            if vlcPlayer.isLoading && !showControls {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.6)
                        .tint(.white)
                    Text("Loading \(channel.name)...")
                        .foregroundColor(.white)
                }
            }

            if let error = vlcPlayer.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Playback Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }

            if showControls {
                TVLiveChannelControlsOverlay(
                    channel: channel,
                    vlcPlayer: vlcPlayer,
                    userPaused: userPaused,
                    behindLive: behindLive,
                    nowPlaying: nowPlaying,
                    upNext: upNext,
                    dvrRepository: dvrRepository,
                    onDismiss: {
                        vlcPlayer.stop()
                        dismiss()
                    },
                    onTogglePlayPause: {
                        if userPaused {
                            vlcPlayer.mediaPlayer.play()
                            userPaused = false
                        } else {
                            vlcPlayer.pause()
                            userPaused = true
                            behindLive = true
                        }
                        scheduleAutoHide()
                    },
                    onSeekForward: {
                        seekLive(seconds: 10)
                        behindLive = true
                        scheduleAutoHide()
                    },
                    onSeekBackward: {
                        seekLive(seconds: -10)
                        behindLive = true
                        scheduleAutoHide()
                    },
                    onGoLive: {
                        Task { await reloadCurrentChannel() }
                    },
                    onChannelUp: { switchChannel(direction: .up) },
                    onChannelDown: { switchChannel(direction: .down) },
                    onPreviousChannel: previousChannel != nil ? { switchToPreviousChannel() } : nil,
                    onRecord: {
                        if nowPlaying != nil {
                            showRecordOptions = true
                        } else {
                            showToast(message: "No program info available", icon: "exclamationmark.circle")
                        }
                    },
                    onShowSleepPicker: { showSleepPicker = true },
                    onMultiview: {
                        vlcPlayer.stop()
                        showMultiview = true
                    },
                    onShowToast: { message, icon in
                        showToast(message: message, icon: icon)
                    },
                    onInteraction: {
                        scheduleAutoHide()
                    }
                )
                .transition(.opacity)
            }

            if showChannelBanner {
                VStack {
                    Spacer()
                    channelBannerView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(9)
            }

            if let message = toastMessage {
                VStack {
                    HStack(spacing: 8) {
                        if let icon = toastIcon {
                            Image(systemName: icon)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Text(message)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(20)
                    .padding(.top, 60)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .onAppear {
            playCurrentChannel(with: initialStreamURL)
            viewModel.selectChannel(channel)
            scheduleAutoHide()
            loadEPGInfo()
            startEPGRefresh()
            notifyInstantSwitch(channelId: channel.id)
        }
        .onDisappear {
            vlcPlayer.stop()
            controlsHideTask?.cancel()
            epgRefreshTask?.cancel()
            channelBannerTask?.cancel()
        }
        .fullScreenCover(isPresented: $showMultiview, onDismiss: {
            if let picked = multiviewPickedChannel {
                multiviewPickedChannel = nil
                switchToChannel(picked)
            } else {
                Task { await reloadCurrentChannel() }
            }
        }) {
            MultiviewPlayerV2(
                initialChannel: channel,
                viewModel: viewModel,
                onDismiss: { showMultiview = false },
                onFullScreen: { picked in
                    multiviewPickedChannel = picked
                    showMultiview = false
                }
            )
        }
        .sheet(isPresented: $showSleepPicker) {
            TVSleepTimerPickerSheet(vlcPlayer: vlcPlayer) { option in
                showToast(message: option == .off ? "Sleep Timer Off" : "Sleep Timer: \(option.label)", icon: "moon.fill")
            }
        }
        .sheet(isPresented: $showRecordOptions) {
            if let program = nowPlaying {
                TVRecordOptionsSheet(
                    program: program,
                    channel: channel,
                    dvrRepository: dvrRepository,
                    onDone: { message in
                        showRecordOptions = false
                        showToast(message: message, icon: "record.circle.fill")
                    }
                )
            }
        }
        .focusable()
        .onPlayPauseCommand {
            if !showControls {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showControls = true
                }
                scheduleAutoHide()
            } else {
                if userPaused {
                    vlcPlayer.mediaPlayer.play()
                    userPaused = false
                } else {
                    vlcPlayer.pause()
                    userPaused = true
                    behindLive = true
                }
                scheduleAutoHide()
            }
        }
        .onMoveCommand { direction in
            if showControls { return }
            switch direction {
            case .up:
                switchChannel(direction: .up)
            case .down:
                switchChannel(direction: .down)
            case .left:
                switchToPreviousChannel()
            case .right:
                showControls = true
                scheduleAutoHide()
            @unknown default:
                break
            }
        }
        .onExitCommand {
            if showSleepPicker {
                showSleepPicker = false
            } else if showControls {
                vlcPlayer.stop()
                dismiss()
            } else {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showControls = true
                }
                scheduleAutoHide()
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                showControls.toggle()
            }
            if showControls {
                scheduleAutoHide()
            }
        }
    }

    private enum ChannelDirection { case up, down }

    private var channels: [Channel] { viewModel.displayedChannels }

    private func playCurrentChannel(with preferredURL: URL? = nil) {
        if let preferredURL {
            vlcPlayer.play(url: preferredURL)
            return
        }
        if let url = liveTVRepository.getStreamURL(for: channel) {
            vlcPlayer.play(url: url)
            return
        }
        Task {
            if let url = try? await viewModel.getChannelStream(channel) {
                vlcPlayer.play(url: url)
            }
        }
    }

    private func reloadCurrentChannel() async {
        userPaused = false
        behindLive = false
        if let url = liveTVRepository.getStreamURL(for: channel) {
            vlcPlayer.play(url: url)
        } else if let url = try? await viewModel.getChannelStream(channel) {
            vlcPlayer.play(url: url)
        }
        scheduleAutoHide()
    }

    private func seekLive(seconds: Int32) {
        if vlcPlayer.duration > 0 {
            if seconds > 0 { vlcPlayer.skipForward() } else { vlcPlayer.skipBackward() }
        } else if userPaused {
            vlcPlayer.mediaPlayer.play()
            vlcPlayer.mediaPlayer.jumpForward(seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                vlcPlayer.pause()
            }
        } else {
            vlcPlayer.mediaPlayer.jumpForward(seconds)
        }
    }

    private func switchChannel(direction: ChannelDirection) {
        guard channels.count > 1 else { return }
        guard let currentIndex = channels.firstIndex(where: { $0.id == channel.id }) else { return }
        let newIndex: Int
        switch direction {
        case .up:
            newIndex = (currentIndex + 1) % channels.count
        case .down:
            newIndex = (currentIndex - 1 + channels.count) % channels.count
        }
        switchToChannel(channels[newIndex])
    }

    private func switchToPreviousChannel() {
        guard let previousChannel else { return }
        switchToChannel(previousChannel)
    }

    private func switchToChannel(_ newChannel: Channel) {
        let oldChannel = channel
        vlcPlayer.stop()
        previousChannel = oldChannel
        channel = newChannel
        viewModel.selectChannel(newChannel)
        userPaused = false
        behindLive = false
        playCurrentChannel()
        loadEPGInfo()
        showChannelBannerOverlay()
        notifyInstantSwitch(channelId: newChannel.id)
        scheduleAutoHide()
    }

    private func notifyInstantSwitch(channelId: String) {
        Task {
            _ = try? await OpenFlixAPI.shared.instantSwitchChannel(channelId: channelId)
        }
    }

    private var channelBannerView: some View {
        HStack(spacing: 14) {
            if let logo = channel.logo {
                AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    if let number = channel.number {
                        Text("\(number)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Text(channel.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                if let program = nowPlaying {
                    HStack(spacing: 6) {
                        Text(program.title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)

                        if !program.timeRangeFormatted.isEmpty {
                            Text("·")
                                .foregroundColor(.white.opacity(0.5))
                            Text(program.timeRangeFormatted)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 3)
                            Rectangle()
                                .fill(Color.purple)
                                .frame(width: geo.size.width * program.progress, height: 3)
                        }
                        .cornerRadius(1.5)
                    }
                    .frame(height: 3)
                }

                if let next = upNext {
                    Text("Up Next: \(next.title)")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.85), Color.black.opacity(0.7)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .cornerRadius(12)
    }

    private func showChannelBannerOverlay() {
        channelBannerTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            showChannelBanner = true
        }
        channelBannerTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showChannelBanner = false
                }
            }
        }
    }

    private func loadEPGInfo() {
        if let cwp = viewModel.guide.first(where: { $0.channel.id == channel.id }) {
            nowPlaying = cwp.currentProgram
            upNext = cwp.upcomingPrograms.first
        } else {
            nowPlaying = channel.nowPlaying
            upNext = channel.nextProgram
        }
    }

    private func startEPGRefresh() {
        epgRefreshTask?.cancel()
        epgRefreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                if !Task.isCancelled {
                    loadEPGInfo()
                }
            }
        }
    }

    private func scheduleAutoHide() {
        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showControls = false
                }
            }
        }
    }

    private func showToast(message: String, icon: String?) {
        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = message
            toastIcon = icon
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                toastMessage = nil
                toastIcon = nil
            }
        }
    }
}

private struct TVLiveChannelControlsOverlay: View {
    let channel: Channel
    @ObservedObject var vlcPlayer: VLCPlayerViewModel
    let userPaused: Bool
    let behindLive: Bool
    let nowPlaying: Program?
    let upNext: Program?
    @ObservedObject var dvrRepository: DVRRepository
    let onDismiss: () -> Void
    let onTogglePlayPause: () -> Void
    let onSeekForward: () -> Void
    let onSeekBackward: () -> Void
    let onGoLive: () -> Void
    let onChannelUp: () -> Void
    let onChannelDown: () -> Void
    let onPreviousChannel: (() -> Void)?
    let onRecord: () -> Void
    let onShowSleepPicker: () -> Void
    let onMultiview: () -> Void
    let onShowToast: (String, String?) -> Void
    let onInteraction: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.48)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                Spacer()

                centerTransportControls

                Spacer()

                channelsInfoBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                seekBarOrLiveIndicator
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                bottomToolbar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                onInteraction()
                onDismiss()
            }) {
                TVPlayerCircleChrome(
                    icon: "xmark",
                    iconColor: .white,
                    size: 42
                )
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()

            Spacer()

            HStack(spacing: 8) {
                AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(spacing: 1) {
                    Text(channel.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if let number = channel.number {
                        Text("CH \(number)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            if let label = vlcPlayer.streamInfo?.resolutionLabel {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.25))
                    .cornerRadius(4)
            }

            Spacer()

            Button(action: {
                onInteraction()
                vlcPlayer.toggleMute()
                onShowToast(vlcPlayer.isMuted ? "Muted" : "Unmuted", vlcPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            }) {
                TVPlayerCircleChrome(
                    icon: vlcPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                    iconColor: .white,
                    size: 42
                )
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
        }
    }

    private var channelsInfoBar: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                if let number = channel.number {
                    Text("CH \(number)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(width: 70)

            Divider()
                .background(Color.white.opacity(0.2))
                .frame(height: 60)

            HStack(spacing: 10) {
                if let art = nowPlaying?.art ?? nowPlaying?.icon {
                    AuthenticatedImage(path: art, systemPlaceholder: "photo")
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .clipped()
                }

                VStack(alignment: .leading, spacing: 3) {
                    if let program = nowPlaying {
                        Text(program.fullTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if let desc = program.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(2)
                        }
                        Text(program.timeRangeFormatted)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.2)).frame(height: 3)
                                Capsule().fill(Color.purple).frame(width: geo.size.width * program.progress, height: 3)
                            }
                        }
                        .frame(height: 3)
                    } else {
                        Text(channel.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text("No program info")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)

            if let next = upNext {
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text("UP NEXT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.purple)
                    if let art = next.art ?? next.icon {
                        AuthenticatedImage(path: art, systemPlaceholder: "photo")
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .clipped()
                    }
                    Text(next.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .frame(width: 80)
                .padding(.leading, 8)
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var centerTransportControls: some View {
        Group {
            if (vlcPlayer.isLoading || vlcPlayer.isBuffering) && !vlcPlayer.isPlaying && vlcPlayer.currentTime == 0 {
                ProgressView()
                    .scaleEffect(2.0)
                    .tint(.white)
                    .frame(width: 70, height: 70)
            } else {
                HStack(spacing: 40) {
                    overlayIconButton("gobackward.10") {
                        onInteraction()
                        onSeekBackward()
                    }

                    Button {
                        onInteraction()
                        onTogglePlayPause()
                    } label: {
                        TVPlayerPrimaryTransportButton(
                            icon: (vlcPlayer.isPlaying && !userPaused) ? "pause.fill" : "play.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()

                    overlayIconButton("goforward.10") {
                        onInteraction()
                        onSeekForward()
                    }
                }
            }
        }
    }

    private var seekBarOrLiveIndicator: some View {
        HStack(spacing: 6) {
            if behindLive {
                Button {
                    onInteraction()
                    onGoLive()
                } label: {
                    TVPlayerPillChrome(
                        icon: "arrow.counterclockwise",
                        label: "GO LIVE",
                        foregroundColor: .white,
                        backgroundColor: Color.red
                    )
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            } else {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
            }

            Spacer()

            Text(formatTime(vlcPlayer.currentTime))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            overlayToolbarButton(icon: "chevron.down", label: "CH-") {
                onInteraction()
                onChannelDown()
            }
            overlayToolbarButton(icon: "chevron.up", label: "CH+") {
                onInteraction()
                onChannelUp()
            }

            if let onPreviousChannel {
                overlayToolbarButton(icon: "arrow.uturn.left", label: "Prev") {
                    onInteraction()
                    onPreviousChannel()
                }
            }

            overlayToolbarButton(icon: nowPlaying?.hasRecording == true ? "record.circle.fill" : "record.circle", label: "Record", tint: nowPlaying?.hasRecording == true ? .red : .white) {
                onInteraction()
                onRecord()
            }

            overlayToolbarButton(icon: vlcPlayer.aspectRatioMode.icon, label: "Aspect") {
                onInteraction()
                let mode = vlcPlayer.cycleAspectRatio()
                onShowToast(mode.rawValue, mode.icon)
            }

            overlayToolbarButton(icon: "waveform", label: "Audio") {
                onInteraction()
                if let name = vlcPlayer.cycleAudioTrack() {
                    onShowToast("Audio: \(name)", "waveform")
                } else {
                    onShowToast("No audio tracks", "waveform")
                }
            }

            overlayToolbarButton(icon: "captions.bubble", label: "Subs") {
                onInteraction()
                if let name = vlcPlayer.cycleSubtitleTrack() {
                    onShowToast("Subtitles: \(name)", "captions.bubble")
                } else {
                    onShowToast("Subtitles Off", "captions.bubble")
                }
            }

            overlayToolbarButton(icon: "rectangle.split.2x2", label: "Multi") {
                onInteraction()
                onMultiview()
            }

            overlayToolbarButton(icon: vlcPlayer.sleepTimerOption != .off ? "moon.fill" : "moon", label: vlcPlayer.sleepTimerOption != .off ? vlcPlayer.sleepTimerLabel : "Sleep", tint: vlcPlayer.sleepTimerOption != .off ? .cyan : .white) {
                onInteraction()
                onShowSleepPicker()
            }
        }
    }

    private func overlayIconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            TVPlayerCircleChrome(
                icon: icon,
                iconColor: .white,
                size: 50,
                iconSize: 28
            )
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
    }

    private func overlayToolbarButton(icon: String, label: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            TVPlayerToolbarChrome(
                icon: icon,
                label: label,
                tint: tint
            )
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
    }

    private func formatTime(_ seconds: Double) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

private struct TVPlayerCircleChrome: View {
    let icon: String
    let iconColor: Color
    let size: CGFloat
    var iconSize: CGFloat = 18
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundColor(iconColor)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isFocused ? Color.white.opacity(0.20) : Color.white.opacity(0.12))
            )
            .overlay(
                Circle()
                    .stroke(isFocused ? Color.white.opacity(0.55) : Color.white.opacity(0.12), lineWidth: isFocused ? 2 : 1)
            )
            .scaleEffect(isFocused ? 1.03 : 1.0)
            .shadow(color: isFocused ? Color.white.opacity(0.08) : .clear, radius: 8, y: 2)
    }
}

private struct TVPlayerPrimaryTransportButton: View {
    let icon: String
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 30, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: 78, height: 78)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isFocused
                                ? [Color.white.opacity(0.24), Color.white.opacity(0.18)]
                                : [Color.white.opacity(0.16), Color.white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                Circle()
                    .stroke(isFocused ? Color.white.opacity(0.62) : Color.white.opacity(0.14), lineWidth: isFocused ? 2 : 1)
            )
            .scaleEffect(isFocused ? 1.035 : 1.0)
            .shadow(color: isFocused ? Color.white.opacity(0.10) : .clear, radius: 10, y: 3)
    }
}

private struct TVPlayerPillChrome: View {
    let icon: String
    let label: String
    let foregroundColor: Color
    let backgroundColor: Color
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
            Text(label)
                .font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(foregroundColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(backgroundColor.opacity(isFocused ? 1.0 : 0.92))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isFocused ? Color.white.opacity(0.45) : .clear, lineWidth: 1.5)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
    }
}

private struct TVPlayerToolbarChrome: View {
    let icon: String
    let label: String
    let tint: Color
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
            Text(label)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(tint)
        .frame(minWidth: 64)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isFocused ? Color.white.opacity(0.16) : Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isFocused ? Color.white.opacity(0.45) : Color.white.opacity(0.08), lineWidth: isFocused ? 1.5 : 1)
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .shadow(color: isFocused ? Color.white.opacity(0.08) : .clear, radius: 8, y: 2)
    }
}

private struct TVSleepTimerPickerSheet: View {
    @ObservedObject var vlcPlayer: VLCPlayerViewModel
    let onSelect: (SleepTimerOption) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(SleepTimerOption.allCases, id: \.rawValue) { option in
                    Button {
                        vlcPlayer.setSleepTimer(option)
                        onSelect(option)
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.label)
                                .foregroundColor(.primary)
                            Spacer()
                            if vlcPlayer.sleepTimerOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sleep Timer")
        }
    }
}

private struct TVRecordOptionsSheet: View {
    let program: Program
    let channel: Channel
    let dvrRepository: DVRRepository
    let onDone: (String) -> Void

    @State private var isWorking = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(program.title)
                    .font(.headline)
                if let subtitle = program.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Button("Record This Episode") {
                guard !isWorking else { return }
                isWorking = true
                Task {
                    do {
                        try await dvrRepository.recordProgram(channel: channel, program: program)
                        onDone("Recording: \(program.title)")
                    } catch {
                        onDone("Record failed")
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Create Series Pass") {
                guard !isWorking else { return }
                isWorking = true
                Task {
                    do {
                        try await dvrRepository.createSeriesPass(channel: channel, program: program)
                        onDone("Series Pass Created")
                    } catch {
                        onDone("Series Pass Failed")
                    }
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(32)
        .frame(width: 560)
    }
}

/// Gates arrow/select events so they only reach the guide when no overlay is presented.
/// Attaching `.onMoveCommand` unconditionally steals focus events from child views, which is
/// why the detail card's Watch/Record/Pass buttons couldn't receive arrow keys.
private struct GuideInputModifier: ViewModifier {
    let isActive: Bool
    let onMove: (MoveCommandDirection) -> Void
    let onSelect: () -> Void

    func body(content: Content) -> some View {
        if isActive {
            content
                .onMoveCommand { onMove($0) }
                .onKeyPress(.return) { onSelect(); return .handled }
        } else {
            content
        }
    }
}

private struct TVOSLiveBrowserView: View {
    private enum GuideFocusTarget {
        case channels
        case programs
    }

    @ObservedObject var viewModel: LiveTVViewModel
    @ObservedObject var dvrViewModel: DVRViewModel
    let onPlayChannel: (Channel) -> Void
    let onOpenGuide: () -> Void
    let onOpenCatchup: () -> Void
    let onOpenOnLater: () -> Void
    let onOpenTeamPass: () -> Void
    let onOpenChannelGroups: () -> Void

    @State private var selectedChannelId: String?
    @State private var selectedProgramIdByChannel: [String: String] = [:]
    @State private var guideWindowStartDate: Date?
    @State private var presentedProgram: Program?
    @State private var presentedProgramChannel: Channel?
    @State private var presentedProgramActionState: ProgramDVRActionState = .fallback()
    @State private var previewChannelId: String?
    @State private var guideFocusTarget: GuideFocusTarget = .channels

    private let shellBackground = Color(red: 13/255, green: 15/255, blue: 28/255)
    private let panelBackground = Color(red: 22/255, green: 24/255, blue: 42/255)
    private let panelBackgroundSoft = Color(red: 18/255, green: 20/255, blue: 36/255)
    private let accent = Color(red: 123/255, green: 82/255, blue: 1.0)
    private let accentSoft = Color(red: 87/255, green: 62/255, blue: 158/255)
    private let progressColor = Color(red: 0.96, green: 0.12, blue: 0.50) // Pluto-style hot pink
    private let nowLineColor = Color(red: 0.96, green: 0.12, blue: 0.50)
    private let channelColumnWidth: CGFloat = 150
    private let rowHeight: CGFloat = 76
    private let timeHeaderHeight: CGFloat = 24
    private let guideWindowMinutes: CGFloat = 120
    private let guidePageStepMinutes: CGFloat = 60

    private var guideRows: [ChannelWithPrograms] {
        if !viewModel.guide.isEmpty {
            return viewModel.guide
        }
        if !viewModel.didLoadGuide {
            return []
        }
        return viewModel.displayedChannels.map { ChannelWithPrograms(channel: $0, programs: []) }
    }

    private var selectedRow: ChannelWithPrograms? {
        if let selectedChannelId,
           let row = guideRowsById[selectedChannelId] {
            return row
        }
        if let selected = viewModel.selectedChannel,
           let row = guideRowsById[selected.id] {
            return row
        }
        return guideRows.first
    }

    private var selectedProgram: Program? {
        guard let row = selectedRow else { return nil }
        if let selectedProgramId = selectedProgramIdByChannel[row.channel.id],
           let program = row.programs.first(where: { $0.id == selectedProgramId }) {
            return program
        }
        return row.currentProgram ?? row.channel.nowPlaying ?? row.programs.first
    }

    private var guideRowsById: [String: ChannelWithPrograms] {
        Dictionary(uniqueKeysWithValues: guideRows.map { ($0.channel.id, $0) })
    }

    private var previewRow: ChannelWithPrograms? {
        if let previewChannelId,
           let row = guideRowsById[previewChannelId] {
            return row
        }
        return selectedRow
    }

    private var liveHighlights: [(channel: Channel, program: Program)] {
        guideRows.compactMap { row in
            guard let program = row.currentProgram ?? row.channel.nowPlaying else { return nil }
            return (row.channel, program)
        }
        .sorted { lhs, rhs in
            if lhs.program.isSports != rhs.program.isSports {
                return lhs.program.isSports && !rhs.program.isSports
            }
            return lhs.program.startTime < rhs.program.startTime
        }
        .prefix(8)
        .map { $0 }
    }

    private var defaultRoundedWindowStart: Date {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        let minute = components.minute ?? 0
        let roundedMinute = minute < 30 ? 0 : 30
        let roundedNow = calendar.date(
            from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: components.hour,
                minute: roundedMinute
            )
        ) ?? now
        return calendar.date(byAdding: .minute, value: -30, to: roundedNow) ?? roundedNow
    }

    private var roundedWindowStart: Date {
        guideWindowStartDate ?? defaultRoundedWindowStart
    }

    private var windowEnd: Date {
        roundedWindowStart.addingTimeInterval(TimeInterval(guideWindowMinutes * 60))
    }

    private var latestGuideEnd: Date {
        guideRows
            .flatMap(\.programs)
            .map(\.endTime)
            .max() ?? windowEnd
    }

    private var canPageBackward: Bool {
        roundedWindowStart > defaultRoundedWindowStart
    }

    private var canPageForward: Bool {
        windowEnd < latestGuideEnd
    }

    private var visibleTimeRangeLabel: String {
        "\(Self.heroWindowDateFormatter.string(from: roundedWindowStart)) - \(Self.heroWindowTimeFormatter.string(from: windowEnd))"
    }

    private func sourceSummary(for channel: Channel?) -> String? {
        guard let channel else { return nil }
        var parts: [String] = []

        if let providerName = channel.providerName, !providerName.isEmpty {
            parts.append(providerName)
        } else if let sourceName = channel.sourceName, !sourceName.isEmpty {
            parts.append(sourceName)
        }

        if let accountName = channel.accountName, !accountName.isEmpty {
            parts.append(accountName)
        } else if let accountIndex = channel.accountIndex {
            parts.append("Account \(accountIndex)")
        }

        if let sourceType = channel.sourceType, !sourceType.isEmpty {
            parts.append(sourceType.capitalized)
        }

        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    private func recordingRouteLabel(for channel: Channel, program: Program) -> String {
        let account = viewModel.providerAccount(for: channel)
        switch RecordingStrategyResolver.resolve(channel: channel, program: program, account: account) {
        case .directvCloud:
            return "Cloud DVR"
        case .sling:
            return "Sling DVR"
        case .unavailable:
            return "No DVR"
        case .local:
            if account?.resolvedUIMode == .receiver {
                return "Receiver DVR"
            }
            return "OpenFlix Local DVR"
        }
    }

    private var visibleRows: [ChannelWithPrograms] {
        guideRows
    }

    var body: some View {
        Group {
            if guideRows.isEmpty && viewModel.isGuideLoading {
                VStack(alignment: .leading, spacing: 1) {
                    guideHero
                    timeHeader
                    guideLoadingMatrix
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    guideHero
                    timeHeader
                    guideMatrix
                }
                .onAppear {
                    if guideWindowStartDate == nil {
                        guideWindowStartDate = defaultRoundedWindowStart
                    }
                    if selectedChannelId == nil {
                        let initialId = viewModel.selectedChannel?.id ?? visibleRows.first?.channel.id
                        selectedChannelId = initialId
                    }
                    if previewChannelId == nil {
                        previewChannelId = selectedChannelId
                    }
                    ensureSelectionState()
                    guideFocusTarget = .channels
                }
                .onReceive(NotificationCenter.default.publisher(for: .tvContentRequestFocus)) { _ in
                    ensureSelectionState()
                    guideFocusTarget = .channels
                }
                .onChange(of: visibleRows.map(\.channel.id).joined(separator: "|")) { _, _ in
                    let rows = visibleRows
                    if selectedChannelId == nil || !rows.contains(where: { $0.channel.id == selectedChannelId }) {
                        let initialId = viewModel.selectedChannel?.id ?? rows.first?.channel.id
                        selectedChannelId = initialId
                    }
                    if previewChannelId == nil || !rows.contains(where: { $0.channel.id == previewChannelId }) {
                        previewChannelId = selectedChannelId
                    }
                    ensureSelectionState()
                }
                .onChange(of: viewModel.guide.count) { _, _ in
                    if guideWindowStartDate == nil {
                        guideWindowStartDate = defaultRoundedWindowStart
                    }
                    ensureSelectionState()
                }
            }
        }
        .padding(.horizontal, 34)
        .padding(.top, 0)
        .padding(.bottom, 4)
        .background(shellBackground)
        .fullScreenCover(isPresented: Binding(
            get: { presentedProgram != nil && presentedProgramChannel != nil },
            set: { newValue in
                if !newValue {
                    presentedProgram = nil
                    presentedProgramChannel = nil
                }
            }
        )) {
            if let program = presentedProgram, let channel = presentedProgramChannel {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()

                    TVGuideProgramSheet(
                        dvrViewModel: dvrViewModel,
                        channel: channel,
                        program: program,
                        accent: accent,
                        sourceSummary: sourceSummary(for: channel),
                        initialActionState: presentedProgramActionState,
                        onWatch: {
                            presentedProgram = nil
                            presentedProgramChannel = nil
                            onPlayChannel(channel)
                        },
                        onClose: {
                            presentedProgram = nil
                            presentedProgramChannel = nil
                        }
                    )
                    .frame(maxWidth: 820)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.35), radius: 28, y: 16)
                    .padding(.horizontal, 80)
                }
                .background(.clear)
                .onExitCommand {
                    presentedProgram = nil
                    presentedProgramChannel = nil
                }
            }
        }
        .focusable(presentedProgram == nil)
        .focusEffectDisabled()
        .modifier(GuideInputModifier(
            isActive: presentedProgram == nil,
            onMove: handleDirectionalNavigation,
            onSelect: handlePrimarySelect
        ))
    }

    private var guideFeatureChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                TVGuideFeatureChip(
                    title: "Catch Up",
                    icon: "clock.arrow.circlepath",
                    accent: accent,
                    action: onOpenCatchup
                )

                TVGuideFeatureChip(
                    title: "On Later",
                    icon: "clock.badge.checkmark",
                    accent: accent,
                    action: onOpenOnLater
                )

                TVGuideFeatureChip(
                    title: "Team Pass",
                    icon: "sportscourt",
                    accent: accent,
                    action: onOpenTeamPass
                )

                TVGuideFeatureChip(
                    title: "Groups",
                    icon: "square.grid.2x2.fill",
                    accent: accent,
                    action: onOpenChannelGroups
                )
            }
            .padding(.vertical, 2)
            .padding(.trailing, 8)
        }
        .frame(height: 34)
    }

    private var guideHero: some View {
        let channel = previewRow?.channel
        let previewProgram = previewRow?.currentProgram ?? channel?.nowPlaying
        let heroProgram = selectedProgram ?? previewProgram

        return HStack(alignment: .center, spacing: 14) {
                TVGuideLivePreviewCard(
                    channel: channel,
                    program: previewProgram,
                    viewModel: viewModel,
                    accent: accent,
                    compact: true
                )
                    .frame(width: 252, height: 142)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("Guide")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Today")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(accent)

                        Text(Self.heroTimeFormatter.string(from: Date()))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))

                        Text("\(visibleRows.count) live")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    HStack(spacing: 8) {
                        if let channel {
                            Text(channel.number.map { "\($0) \(channel.name)" } ?? channel.name)
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(accent)
                                .lineLimit(1)
                        }

                        if let heroProgram {
                            Text(heroProgram.timeRangeFormatted)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white.opacity(0.66))
                                .lineLimit(1)
                        }
                    }

                    if let sourceSummary = sourceSummary(for: channel) {
                        Text(sourceSummary)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(1)
                    }

                    Text(heroProgram?.title ?? "Select a channel to browse what’s live now.")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(heroProgram?.subtitle.orEmpty.isEmpty == false ? heroProgram?.subtitle ?? "" : "Browse channels and move right into the grid.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)

                    Text(visibleTimeRangeLabel)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(
                    LinearGradient(
                        colors: [panelBackground, accentSoft.opacity(0.52)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var guideLoadingMatrix: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(panelBackground.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
            )
            .overlay {
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { _ in
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.055))
                                .frame(width: channelColumnWidth, height: rowHeight)

                            Rectangle()
                                .fill(panelBackgroundSoft.opacity(0.35))
                                .frame(height: rowHeight)
                                .overlay(alignment: .leading) {
                                    HStack(spacing: 0) {
                                        ForEach(0..<4, id: \.self) { index in
                                            Rectangle()
                                                .fill(Color.white.opacity(index == 0 ? 0 : 0.04))
                                                .frame(width: 1)
                                                .frame(maxHeight: .infinity)
                                            Spacer(minLength: 0)
                                        }
                                    }
                                }
                        }
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color.white.opacity(0.035))
                                .frame(height: 1)
                        }
                    }
                }
                .overlay {
                    VStack(spacing: 10) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.15)
                        Text("Loading guide data...")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 14))
                }
            }
    }

    private var timeHeader: some View {
        HStack(spacing: 3) {
            Color.clear
                .frame(width: channelColumnWidth, height: timeHeaderHeight)

            GeometryReader { proxy in
                let width = proxy.size.width
                let slotWidth = width / 4

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(panelBackgroundSoft.opacity(0.82))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                        )

                    HStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { index in
                            let slotDate = roundedWindowStart.addingTimeInterval(TimeInterval(index * 30 * 60))
                            VStack(spacing: 2) {
                                Text(Self.timeSlotFormatter.string(from: slotDate))
                                    .font(.system(size: 10, weight: index.isMultiple(of: 2) ? .bold : .medium, design: .rounded))
                                    .foregroundStyle(index.isMultiple(of: 2) ? .white : .white.opacity(0.65))
                            }
                            .frame(width: slotWidth, height: timeHeaderHeight)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(index == 0 ? 0 : 0.035))
                                    .frame(width: 1)
                            }
                        }
                    }

                    if let nowOffset = nowIndicatorOffset(totalWidth: width) {
                        Rectangle()
                            .fill(nowLineColor)
                            .frame(width: 2, height: timeHeaderHeight - 4)
                            .offset(x: nowOffset, y: 2)
                    }
                }
            }
            .frame(height: timeHeaderHeight)
        }
    }
    private var guideMatrix: some View {
        TVGuideMatrix(
            rows: visibleRows,
            selectedChannelId: selectedChannelId,
            selectedProgramIdByChannel: selectedProgramIdByChannel,
            accent: accent,
            nowLineColor: nowLineColor,
            panelBackground: panelBackground,
            panelBackgroundSoft: panelBackgroundSoft,
            channelColumnWidth: channelColumnWidth,
            rowHeight: rowHeight,
            windowStart: roundedWindowStart,
            windowEnd: windowEnd,
            guideWindowMinutes: guideWindowMinutes,
            onSelectChannel: { channel in
                selectChannel(channel)
            },
            onSelectProgram: { channel, program in
                selectedProgramIdByChannel[channel.id] = program.id
                selectChannel(channel)
                presentProgram(program, channel: channel)
            },
            onFocusProgram: { channel, program in
                selectedProgramIdByChannel[channel.id] = program.id
                selectChannel(channel)
            },
            nowIndicatorOffset: { width in
                nowIndicatorOffset(totalWidth: width)
            }
        )
        .frame(maxHeight: .infinity)
        .focusSection()
        .onMoveCommand { direction in
            switch direction {
            case .right:
                guard let selectedProgram else { return }
                if selectedProgram.endTime >= windowEnd.addingTimeInterval(-15 * 60) {
                    shiftGuideWindow(by: guidePageStepMinutes)
                }
            case .left:
                guard let selectedProgram else { return }
                if selectedProgram.startTime <= roundedWindowStart.addingTimeInterval(15 * 60) {
                    shiftGuideWindow(by: -guidePageStepMinutes)
                }
            default:
                break
            }
        }
    }

    private func shiftGuideWindow(by minutes: CGFloat) {
        guard minutes != 0 else { return }
        let baseStart = defaultRoundedWindowStart
        let minStart = baseStart
        let maxStart = max(
            baseStart,
            latestGuideEnd.addingTimeInterval(-TimeInterval(guideWindowMinutes * 60))
        )

        let candidate = roundedWindowStart.addingTimeInterval(TimeInterval(minutes * 60))
        let clamped = min(max(candidate, minStart), maxStart)
        guard clamped != roundedWindowStart else { return }

        guideWindowStartDate = clamped

        if let row = selectedRow {
            let nextVisible = row.programs.first {
                $0.endTime > clamped && $0.startTime < clamped.addingTimeInterval(TimeInterval(guideWindowMinutes * 60))
            }
            if let nextVisible {
                selectedProgramIdByChannel[row.channel.id] = nextVisible.id
            }
        }

        // Auto-extend guide data if paging near the end of loaded data
        let newWindowEnd = clamped.addingTimeInterval(TimeInterval(guideWindowMinutes * 60))
        if newWindowEnd > latestGuideEnd.addingTimeInterval(-3600) {
            Task {
                await viewModel.extendGuideIfNeeded(pastDate: newWindowEnd.addingTimeInterval(7200))
            }
        }

        ensureSelectionState()
    }

    private func selectChannel(_ channel: Channel) {
        selectedChannelId = channel.id
        viewModel.selectChannel(channel)
        if selectedProgramIdByChannel[channel.id] == nil {
            let row = guideRowsById[channel.id]
            let preferred = row?.currentProgram?.id
                ?? channel.nowPlaying?.id
                ?? row?.programs.first?.id
            selectedProgramIdByChannel[channel.id] = preferred
        }
    }

    private func ensureSelectionState() {
        guard let channel = selectedRow?.channel ?? guideRows.first?.channel else { return }
        if selectedChannelId != channel.id {
            selectedChannelId = channel.id
        }
        if previewChannelId == nil {
            previewChannelId = channel.id
        }
        if selectedProgramIdByChannel[channel.id] == nil {
            let preferredProgramId =
                selectedRow?.currentProgram?.id
                ?? channel.nowPlaying?.id
                ?? guideRowsById[channel.id]?.programs.first?.id
            selectedProgramIdByChannel[channel.id] = preferredProgramId
        }
    }

    private func handleDirectionalNavigation(_ direction: MoveCommandDirection) {
        ensureSelectionState()

        switch direction {
        case .up:
            guideFocusTarget = .channels
            moveChannelSelection(by: -1)
        case .down:
            guideFocusTarget = .channels
            moveChannelSelection(by: 1)
        case .left:
            if guideFocusTarget == .programs {
                moveProgramSelection(by: -1)
            } else {
                guideFocusTarget = .channels
            }
        case .right:
            guideFocusTarget = .programs
            moveProgramSelection(by: 1)
        default:
            break
        }
    }

    private func handlePrimarySelect() {
        ensureSelectionState()

        if guideFocusTarget == .channels, let channel = selectedRow?.channel {
            previewChannelId = channel.id
            return
        }

        if let channel = selectedRow?.channel, let program = selectedProgram {
            selectedProgramIdByChannel[channel.id] = program.id
            presentProgram(program, channel: channel)
        } else if let channel = selectedRow?.channel {
            onPlayChannel(channel)
        }
    }

    private func moveChannelSelection(by offset: Int) {
        let rows = guideRows
        guard !rows.isEmpty else { return }
        let currentIndex = rows.firstIndex(where: { $0.channel.id == selectedChannelId }) ?? 0
        let nextIndex = min(max(currentIndex + offset, 0), rows.count - 1)
        let nextChannel = rows[nextIndex].channel
        selectChannel(nextChannel)
    }

    private func moveProgramSelection(by offset: Int) {
        guard let row = selectedRow else { return }
        let programs = row.programs
            .filter { $0.endTime > $0.startTime && $0.endTime > roundedWindowStart && $0.startTime < windowEnd }
            .sorted { $0.startTime < $1.startTime }

        guard !programs.isEmpty else {
            if offset < 0, canPageBackward {
                shiftGuideWindow(by: -guidePageStepMinutes)
            } else if offset > 0, canPageForward {
                shiftGuideWindow(by: guidePageStepMinutes)
            }
            return
        }

        let currentIndex = programs.firstIndex(where: { $0.id == selectedProgramIdByChannel[row.channel.id] }) ?? 0
        let proposedIndex = currentIndex + offset

        if proposedIndex < 0 {
            selectedProgramIdByChannel[row.channel.id] = programs[0].id
            guideFocusTarget = .channels
            return
        }

        if proposedIndex >= programs.count {
            if canPageForward {
                shiftGuideWindow(by: guidePageStepMinutes)
            } else {
                selectedProgramIdByChannel[row.channel.id] = programs[programs.count - 1].id
            }
            return
        }

        selectedProgramIdByChannel[row.channel.id] = programs[proposedIndex].id
    }

    private func presentProgram(_ program: Program, channel: Channel) {
        presentedProgram = program
        presentedProgramChannel = channel
        presentedProgramActionState = .fallback(routeLabel: recordingRouteLabel(for: channel, program: program))
        Task {
            let actionState = await dvrViewModel.programActionState(channel: channel, program: program)
            await MainActor.run {
                guard presentedProgram?.id == program.id, presentedProgramChannel?.id == channel.id else { return }
                presentedProgramActionState = actionState
            }
        }
    }

    private func nowIndicatorOffset(totalWidth: CGFloat) -> CGFloat? {
        let now = Date()
        guard now >= roundedWindowStart && now <= windowEnd else { return nil }
        let elapsedMinutes = CGFloat(now.timeIntervalSince(roundedWindowStart) / 60)
        return min(max(elapsedMinutes / guideWindowMinutes * totalWidth, 0), totalWidth)
    }

    private static let heroTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let heroWindowDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE h:mm a"
        return formatter
    }()

    private static let heroWindowTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private static let timeSlotFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }()
}

private struct TVGuideMatrix: View {
    let rows: [ChannelWithPrograms]
    let selectedChannelId: String?
    let selectedProgramIdByChannel: [String: String]
    let accent: Color
    let nowLineColor: Color
    let panelBackground: Color
    let panelBackgroundSoft: Color
    let channelColumnWidth: CGFloat
    let rowHeight: CGFloat
    let windowStart: Date
    let windowEnd: Date
    let guideWindowMinutes: CGFloat
    let onSelectChannel: (Channel) -> Void
    let onSelectProgram: (Channel, Program) -> Void
    let onFocusProgram: (Channel, Program) -> Void
    let nowIndicatorOffset: (CGFloat) -> CGFloat?

    private var displayRows: [ChannelWithPrograms] {
        rows
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(displayRows) { row in
                        TVGuideMatrixRow(
                            row: row,
                            selectedChannelId: selectedChannelId,
                            selectedProgramId: selectedChannelId == row.channel.id ? selectedProgramIdByChannel[row.channel.id] : nil,
                            accent: accent,
                            panelBackgroundSoft: panelBackgroundSoft,
                            channelColumnWidth: channelColumnWidth,
                            rowHeight: rowHeight,
                            windowStart: windowStart,
                            windowEnd: windowEnd,
                            guideWindowMinutes: guideWindowMinutes,
                            onSelectChannel: onSelectChannel,
                            onSelectProgram: onSelectProgram,
                            onFocusProgram: onFocusProgram
                        )
                        .id(row.channel.id)
                    }
                }
            }
            .background(matrixBackground)
            .overlay {
                GeometryReader { geo in
                    let programAreaWidth = max(geo.size.width - channelColumnWidth, 0)

                    if let offset = nowIndicatorOffset(programAreaWidth) {
                        Rectangle()
                            .fill(nowLineColor)
                            .frame(width: 2, height: geo.size.height)
                            .offset(x: channelColumnWidth + offset, y: 0)
                            .allowsHitTesting(false)
                    }
                }
            }
            .onChange(of: selectedChannelId) { _, newValue in
                guard let newValue else { return }
                withAnimation(.easeInOut(duration: 0.22)) {
                    proxy.scrollTo(newValue, anchor: .top)
                }
            }
        }
    }

    private var matrixBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(panelBackground.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
            )
    }
}

private struct TVGuideMatrixRow: View {
    let row: ChannelWithPrograms
    let selectedChannelId: String?
    let selectedProgramId: String?
    let accent: Color
    let panelBackgroundSoft: Color
    let channelColumnWidth: CGFloat
    let rowHeight: CGFloat
    let windowStart: Date
    let windowEnd: Date
    let guideWindowMinutes: CGFloat
    let onSelectChannel: (Channel) -> Void
    let onSelectProgram: (Channel, Program) -> Void
    let onFocusProgram: (Channel, Program) -> Void
    
    private var isSelectedRow: Bool {
        selectedChannelId == row.channel.id
    }

    private var timelinePrograms: [Program] {
        let basePrograms = deduplicatedPrograms(row.programs)
        let overlappingCurrentProgram = [row.currentProgram ?? row.channel.nowPlaying]
            .compactMap { $0 }
            .filter { $0.endTime > $0.startTime }
            .filter { $0.endTime > windowStart && $0.startTime < windowEnd }

        return deduplicatedPrograms(basePrograms + overlappingCurrentProgram)
            .filter { $0.endTime > windowStart && $0.startTime < windowEnd }
            .sorted { $0.startTime < $1.startTime }
    }

    @ViewBuilder
    var body: some View {
        HStack(spacing: 0) {
            channelCell
            GeometryReader { proxy in
                TVGuideProgramTrack(
                    row: row,
                    programs: timelinePrograms,
                    selectedProgramId: selectedProgramId,
                    accent: accent,
                    panelBackgroundSoft: panelBackgroundSoft,
                    rowHeight: rowHeight,
                    width: proxy.size.width,
                    isSelectedRow: isSelectedRow,
                    windowStart: windowStart,
                    windowEnd: windowEnd,
                    guideWindowMinutes: guideWindowMinutes,
                    onSelectChannel: onSelectChannel,
                    onSelectProgram: onSelectProgram,
                    onFocusProgram: onFocusProgram
                )
            }
            .frame(height: rowHeight)
        }
        .frame(height: rowHeight)
        .background(rowBackground)
        .focusSection()
        .overlay(alignment: .top) {
            Rectangle()
                .fill(isSelectedRow ? accent.opacity(0.32) : Color.white.opacity(0.035))
                .frame(height: isSelectedRow ? 2 : 1)
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(isSelectedRow ? accent : Color.clear)
                .frame(width: isSelectedRow ? 4 : 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelectedRow ? accent.opacity(0.35) : Color.clear, lineWidth: 1.5)
        }
    }

    private var channelCell: some View {
        TVGuideChannelCell(
            channel: row.channel,
            currentProgram: row.currentProgram ?? row.channel.nowPlaying,
            accent: accent,
            isSelected: selectedChannelId == row.channel.id,
            action: {
                onSelectChannel(row.channel)
            }
        )
        .frame(width: channelColumnWidth, height: rowHeight)
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isSelectedRow ? accent.opacity(0.10) : Color.white.opacity(0.01))
            .overlay {
                if isSelectedRow {
                    LinearGradient(
                        colors: [accent.opacity(0.12), Color.clear, accent.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
    }

    private func deduplicatedPrograms(_ programs: [Program]) -> [Program] {
        let sorted = programs
            .filter { $0.endTime > $0.startTime }
            .sorted {
                if $0.startTime != $1.startTime { return $0.startTime < $1.startTime }
                if $0.endTime != $1.endTime { return $0.endTime < $1.endTime }
                return $0.title < $1.title
            }

        var result: [Program] = []
        var seenKeys = Set<String>()

        for program in sorted {
            let slotKey = "\(Int(program.startTime.timeIntervalSince1970))-\(Int(program.endTime.timeIntervalSince1970))-\(normalizedProgramTitle(program.title))"
            if seenKeys.contains(slotKey) {
                continue
            }

            if let last = result.last, programsConflict(last, program) {
                if preferredProgram(program, over: last) {
                    result[result.count - 1] = program
                    seenKeys.insert(slotKey)
                }
                continue
            }

            result.append(program)
            seenKeys.insert(slotKey)
        }

        return result
    }

    private func programsConflict(_ lhs: Program, _ rhs: Program) -> Bool {
        let startDelta = abs(lhs.startTime.timeIntervalSince(rhs.startTime))
        let endDelta = abs(lhs.endTime.timeIntervalSince(rhs.endTime))
        let overlapping = lhs.startTime < rhs.endTime && rhs.startTime < lhs.endTime
        return overlapping && (startDelta < 60 || endDelta < 60)
    }

    private func preferredProgram(_ candidate: Program, over current: Program) -> Bool {
        let candidateScore =
            (candidate.isCurrentlyAiring ? 4 : 0) +
            (!candidate.subtitle.orEmpty.isEmpty ? 2 : 0) +
            (!candidate.description.orEmpty.isEmpty ? 1 : 0) +
            min(candidate.title.count, 40)

        let currentScore =
            (current.isCurrentlyAiring ? 4 : 0) +
            (!current.subtitle.orEmpty.isEmpty ? 2 : 0) +
            (!current.description.orEmpty.isEmpty ? 1 : 0) +
            min(current.title.count, 40)

        return candidateScore > currentScore
    }

    private func normalizedProgramTitle(_ title: String) -> String {
        title
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "", options: .regularExpression)
    }
}

private struct TVGuideProgramTrack: View {
    let row: ChannelWithPrograms
    let programs: [Program]
    let selectedProgramId: String?
    let accent: Color
    let panelBackgroundSoft: Color
    let rowHeight: CGFloat
    let width: CGFloat
    let isSelectedRow: Bool
    let windowStart: Date
    let windowEnd: Date
    let guideWindowMinutes: CGFloat
    let onSelectChannel: (Channel) -> Void
    let onSelectProgram: (Channel, Program) -> Void
    let onFocusProgram: (Channel, Program) -> Void
    private var minuteWidth: CGFloat {
        width / guideWindowMinutes
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(isSelectedRow ? accent.opacity(0.055) : panelBackgroundSoft.opacity(0.24))

            slotDividers

            if programs.isEmpty {
                Text("No guide data")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 12)
            } else {
                programCells
            }
        }
    }

    private var slotDividers: some View {
        let slotCount = max(Int(guideWindowMinutes / 30), 1)

        return ForEach(0..<slotCount, id: \.self) { index in
            Rectangle()
                .fill(Color.white.opacity(index == 0 ? 0 : 0.04))
                .frame(width: 1)
                .offset(x: CGFloat(index) * (width / CGFloat(slotCount)))
        }
    }

    private var programCells: some View {
        ForEach(Array(programs.enumerated()), id: \.element.id) { _, program in
            let clampedStart = max(program.startTime, windowStart)
            let clampedEnd = min(program.endTime, windowEnd)
            let xPos = CGFloat(clampedStart.timeIntervalSince(windowStart) / 60) * minuteWidth
            let durationWidth = CGFloat(clampedEnd.timeIntervalSince(clampedStart) / 60) * minuteWidth
            let cellWidth = max(durationWidth - 1, 28)

            TVGuideProgramCell(
                program: program,
                accent: accent,
                progressColor: accent,
                width: cellWidth,
                isSelected: selectedProgramId == program.id,
                action: {
                    onSelectProgram(row.channel, program)
                }
            )
            .offset(x: xPos + 0.5, y: 0)
        }
    }
}

private struct TVGuideLivePreviewCard: View {
    let channel: Channel?
    let program: Program?
    @ObservedObject var viewModel: LiveTVViewModel
    let accent: Color
    var compact: Bool = false

    @StateObject private var previewPlayer = TVGuidePreviewPlayerModel()
    @State private var loadedChannelId: String?
    @State private var loadTask: Task<Void, Never>?
    private var cornerRadius: CGFloat { compact ? 14 : 22 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            TVGuidePreviewCard(
                channel: channel,
                program: program,
                accent: accent,
                compact: compact
            )

            TVGuidePreviewPlayerSurface(player: previewPlayer.player)
                .opacity(previewPlayer.isReady ? 1 : 0)
                .allowsHitTesting(false)

            if previewPlayer.isReady {
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.84)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: compact ? 4 : 8) {
                    Text(compact ? "Preview" : "Live Preview")
                        .font(.system(size: compact ? 9 : 11, weight: .black))
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(.horizontal, compact ? 6 : 8)
                        .padding(.vertical, compact ? 3 : 5)
                        .background(Color.black.opacity(0.4), in: Capsule())

                    Spacer()

                    if !compact {
                        Text(program?.title ?? channel?.name ?? "Live TV")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }
                }
                .padding(compact ? 8 : 16)
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onChange(of: channel?.id) { _, _ in debouncedReload() }
        .onAppear { debouncedReload() }
        .onDisappear {
            loadTask?.cancel()
            previewPlayer.stop()
            loadedChannelId = nil
        }
    }

    private func debouncedReload() {
        guard let channel else {
            loadTask?.cancel()
            previewPlayer.stop()
            loadedChannelId = nil
            return
        }
        if channel.id == loadedChannelId { return }
        loadTask?.cancel()
        loadTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            if channel.id == loadedChannelId { return }

            previewPlayer.stop()

            let url: URL?
            do {
                url = try await viewModel.getChannelPreviewStream(channel)
            } catch {
                if Task.isCancelled { return }
                NSLog("PREVIEW STREAM ERROR for %@: %@", channel.id, String(describing: error))
                return
            }
            if Task.isCancelled { return }
            guard let url else { return }

            loadedChannelId = channel.id
            previewPlayer.play(url: url)
        }
    }
}

@MainActor
private final class TVGuidePreviewPlayerModel: ObservableObject {
    let player = AVPlayer()
    @Published var isReady = false

    private var statusObservation: NSKeyValueObservation?
    private var currentURL: URL?

    init() {
        player.isMuted = true
        player.actionAtItemEnd = .pause
        player.preventsDisplaySleepDuringVideoPlayback = false
    }

    func play(url: URL) {
        if currentURL == url, player.currentItem != nil {
            player.play()
            return
        }

        stop(resetURL: false)
        currentURL = url

        let item = AVPlayerItem(url: url)
        statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isReady = true
                    self.player.play()
                case .failed:
                    self.isReady = false
                default:
                    break
                }
            }
        }

        player.replaceCurrentItem(with: item)
    }

    func stop(resetURL: Bool = true) {
        statusObservation?.invalidate()
        statusObservation = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        isReady = false
        if resetURL {
            currentURL = nil
        }
    }
}

private struct TVGuidePreviewPlayerSurface: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> TVGuidePreviewPlayerView {
        let view = TVGuidePreviewPlayerView()
        view.backgroundColor = .black
        view.clipsToBounds = true
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: TVGuidePreviewPlayerView, context: Context) {
        uiView.clipsToBounds = true
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = .resizeAspectFill
    }
}

private final class TVGuidePreviewPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        clipsToBounds = true
        layer.masksToBounds = true
    }
}

private struct TVGuidePreviewCard: View {
    let channel: Channel?
    let program: Program?
    let accent: Color
    var compact: Bool = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imagePath = program?.icon ?? program?.art ?? channel?.logo {
                AuthenticatedImage(paths: [imagePath], systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [accent.opacity(0.46), Color.black.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.84)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: compact ? 4 : 8) {
                Text(compact ? "Preview" : "Live Preview")
                    .font(.system(size: compact ? 9 : 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, compact ? 6 : 8)
                    .padding(.vertical, compact ? 3 : 5)
                    .background(Color.black.opacity(0.4), in: Capsule())

                Spacer()

                if !compact {
                    Text(program?.title ?? channel?.name ?? "Live TV")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
            }
            .padding(compact ? 8 : 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : 22))
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 14 : 22)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct TVGuideProgramSheet: View {
    @ObservedObject var dvrViewModel: DVRViewModel
    let channel: Channel
    let program: Program
    let accent: Color
    let sourceSummary: String?
    let initialActionState: ProgramDVRActionState
    let onWatch: () -> Void
    let onClose: () -> Void

    @FocusState private var focusedAction: Action?
    @State private var actionState: ProgramDVRActionState
    @State private var isActionLoading = false
    @State private var downloadStatusText: String?

    private enum Action: Hashable {
        case watch
        case record
        case pass
        case download
        case close
    }

    init(
        dvrViewModel: DVRViewModel,
        channel: Channel,
        program: Program,
        accent: Color,
        sourceSummary: String?,
        initialActionState: ProgramDVRActionState,
        onWatch: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        _dvrViewModel = ObservedObject(wrappedValue: dvrViewModel)
        self.channel = channel
        self.program = program
        self.accent = accent
        self.sourceSummary = sourceSummary
        self.initialActionState = initialActionState
        self.onWatch = onWatch
        self.onClose = onClose
        _actionState = State(initialValue: initialActionState)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 16/255, green: 12/255, blue: 28/255),
                    Color(red: 27/255, green: 20/255, blue: 46/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Capsule()
                        .fill(Color.white.opacity(0.24))
                        .frame(width: 62, height: 7)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(.white.opacity(0.72))
                            .frame(width: 46, height: 46)
                            .background(Color.white.opacity(0.14), in: Circle())
                    }
                    .buttonStyle(TVNoGlowButtonStyle())
                    .focused($focusedAction, equals: .close)
                    .overlay {
                        Circle()
                            .stroke(focusedAction == .close ? accent.opacity(0.7) : Color.clear, lineWidth: 2)
                            .padding(-2)
                    }
                    .scaleEffect(focusedAction == .close ? 1.06 : 1)
                    .animation(.easeOut(duration: 0.15), value: focusedAction == .close)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 14) {
                        programArtwork

                        VStack(alignment: .leading, spacing: 4) {
                            Text(program.title)
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(2)

                            if let subtitle = program.subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.72))
                                    .lineLimit(1)
                            }

                            Text(shortDate(program.startTime))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer(minLength: 0)
                    }

                    HStack(spacing: 8) {
                        Text("\(program.duration) min")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(program.startTimeFormatted)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.66))

                        Text(displayChannelBrand)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(accent)
                            .lineLimit(1)
                    }

                    if let sourceSummary, !sourceSummary.isEmpty {
                        Text("\(sourceSummary) • \(actionState.routeLabel)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    } else {
                        Text(actionState.routeLabel)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }

                    badgeRow

                    if let description = program.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.82))
                            .lineLimit(2)
                    }

                    if program.isCurrentlyAiring {
                        VStack(alignment: .leading, spacing: 6) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [accent.opacity(0.92), accent],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: max(geo.size.width * CGFloat(program.progress), 6), height: 4)
                                }
                            }
                            .frame(height: 4)

                            HStack {
                                Text("\(Int(program.progress * 100))% complete")
                                Spacer()
                                Text("\(program.remainingMinutes) min remaining")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.48))
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 14)

                HStack(spacing: 12) {
                    actionButton(title: "Watch", systemImage: "tv", action: onWatch, focused: .watch)
                    actionButton(
                        title: actionState.recordTitle,
                        systemImage: "record.circle",
                        action: runRecordAction,
                        focused: .record,
                        isEnabled: actionState.canRecord && !isActionLoading
                    )
                    if actionState.canDownload || downloadStatusText != nil {
                        actionButton(
                            title: downloadStatusText ?? actionState.downloadTitle,
                            systemImage: "arrow.down.circle",
                            action: runDownloadAction,
                            focused: .download,
                            isEnabled: actionState.canDownload && !isActionLoading
                        )
                    }
                    actionButton(
                        title: actionState.seriesTitle,
                        systemImage: "rectangle.portrait.and.arrow.right",
                        action: runSeriesAction,
                        focused: .pass,
                        isEnabled: actionState.canRecordSeries && !isActionLoading
                    )
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
                .focusSection()
            }
            .frame(maxWidth: 720, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear {
            focusedAction = .watch
        }
        .task(id: program.id) {
            actionState = await dvrViewModel.programActionState(channel: channel, program: program)
        }
    }

    private var programArtwork: some View {
        ZStack {
            if let imagePath = preferredProgramArtworkPath {
                AuthenticatedImage(paths: [imagePath], systemPlaceholder: program.isSports ? "sportscourt" : "tv")
                    .aspectRatio(contentMode: .fill)
            } else if let logoPath = channel.logo {
                // Flat dark panel with the channel logo centered — replaces the earlier
                // accent-gradient+circle treatment which dominated the compact card.
                Color.white.opacity(0.06)
                    .overlay {
                        AuthenticatedImage(paths: [logoPath], systemPlaceholder: program.isSports ? "sportscourt" : "tv")
                            .aspectRatio(contentMode: .fit)
                            .padding(22)
                    }
            } else {
                Color.white.opacity(0.06)
                    .overlay {
                        Image(systemName: program.isSports ? "sportscourt" : "tv")
                            .font(.system(size: 42, weight: .regular))
                            .foregroundStyle(.white.opacity(0.34))
                    }
            }
        }
        .frame(width: 150, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var preferredProgramArtworkPath: String? {
        // Prefer real program artwork (art/icon) in whatever form the server sends it.
        // The prior "skip anything containing 'logo'" filter was too aggressive and dropped
        // legitimate program thumbnails whose URLs happened to contain the word.
        [program.art, program.icon].compactMap { $0 }.first(where: { !$0.isEmpty })
    }

    @ViewBuilder
    private var badgeRow: some View {
        HStack(spacing: 8) {
            ForEach(program.badges, id: \.self) { badge in
                badgePill(badge, color: accent)
            }
            if let rating = program.rating, !rating.isEmpty {
                badgePill(rating, color: Color.white.opacity(0.14))
            }
            if let category = program.category, !category.isEmpty {
                badgePill(category, color: Color.white.opacity(0.14))
            }
        }
    }

    private func badgePill(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color, in: RoundedRectangle(cornerRadius: 7))
    }

    @ViewBuilder
    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void, focused: Action, isEnabled: Bool = true) -> some View {
        let button = Button(action: {
            guard isEnabled else { return }
            action()
        }) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(
                    isEnabled
                    ? (focusedAction == focused ? .white : .white.opacity(0.94))
                    : .white.opacity(0.34)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    (
                        isEnabled && focusedAction == focused
                        ? accent.opacity(0.20)
                        : Color.white.opacity(0.07)
                    ),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isEnabled && focusedAction == focused ? accent.opacity(0.62) : Color.white.opacity(0.08),
                            lineWidth: 1
                        )
                }
        }
        // TVNoGlowButtonStyle removes the tvOS system focus halo entirely so the accent-tinted
        // background/stroke below is the only focus indicator — the system white glow washed out
        // the button text otherwise.
        .buttonStyle(TVNoGlowButtonStyle())
        .disabled(!isEnabled)
        .focused($focusedAction, equals: focused)
        .shadow(color: isEnabled && focusedAction == focused ? accent.opacity(0.08) : .clear, radius: 4, y: 2)
        .scaleEffect(isEnabled && focusedAction == focused ? 1.04 : 1)
        .animation(.easeOut(duration: 0.15), value: focusedAction == focused)

        if focused == .watch {
            button.defaultFocus($focusedAction, .watch)
        } else {
            button
        }
    }

    private func runRecordAction() {
        guard actionState.canRecord, !isActionLoading else { return }
        isActionLoading = true
        Task {
            defer { isActionLoading = false }
            try? await dvrViewModel.recordProgram(channel: channel, program: program)
            actionState = await dvrViewModel.programActionState(channel: channel, program: program)
        }
    }

    private func runSeriesAction() {
        guard actionState.canRecordSeries, !isActionLoading else { return }
        isActionLoading = true
        Task {
            defer { isActionLoading = false }
            try? await dvrViewModel.createSeriesPass(channel: channel, program: program)
            actionState = await dvrViewModel.programActionState(channel: channel, program: program)
        }
    }

    private func runDownloadAction() {
        guard actionState.canDownload, !isActionLoading else { return }
        isActionLoading = true
        downloadStatusText = "Starting…"
        Task {
            defer { isActionLoading = false }
            if let job = try? await dvrViewModel.startDownload(channel: channel, program: program) {
                if let progress = job.progress {
                    downloadStatusText = "\(Int(progress * 100))%"
                } else {
                    downloadStatusText = job.status ?? "Queued"
                }
            } else {
                downloadStatusText = nil
            }
            actionState = await dvrViewModel.programActionState(channel: channel, program: program)
        }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private var displayChannelBrand: String {
        let base = channel.name
            .replacingOccurrences(of: #"^\s*A\d+\s+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+\d{2,}\s+[A-Z]{3,}.*$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?i)\s+HD$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return base.isEmpty ? channel.name : base
    }
}

private struct TVGuideChannelCell: View {
    let channel: Channel
    let currentProgram: Program?
    let accent: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                AuthenticatedImage(paths: [channel.logo], systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 68, height: 42)

                if let number = channel.number {
                    Text("\(number)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isSelected
                    ? Color(red: 44/255, green: 39/255, blue: 78/255)
                    : Color.white.opacity(0.012)
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(isSelected ? accent : Color.clear)
                    .frame(width: isSelected ? 6 : 0)
            }
            .overlay {
                Rectangle()
                    .stroke(isSelected ? Color.white.opacity(0.74) : Color.white.opacity(0.035), lineWidth: isSelected ? 2 : 0.8)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
            }
            .scaleEffect(isSelected ? 1.012 : 1)
            .shadow(color: isSelected ? Color.white.opacity(0.05) : .clear, radius: 8, y: 4)
            .animation(.easeOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(TVNoGlowButtonStyle())
        .focusEffectDisabled()
    }
}

private struct TVGuideProgramCell: View {
    let program: Program
    let accent: Color
    let progressColor: Color
    let width: CGFloat
    let isSelected: Bool
    let action: () -> Void

    private var isUltraCompact: Bool { width < 56 }
    private var isCompact: Bool { width < 150 }
    private var cellHeight: CGFloat { 72 }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                if isSelected && width >= 170, let imagePath = program.art ?? program.icon {
                    AuthenticatedImage(paths: [imagePath], systemPlaceholder: "play.rectangle")
                        .aspectRatio(contentMode: .fill)
                        .overlay {
                            LinearGradient(
                                colors: [Color.black.opacity(0.06), Color.black.opacity(0.50)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }

                // Left accent bar for currently-airing
                if program.isCurrentlyAiring && !isUltraCompact {
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(progressColor)
                            .frame(width: 3)
                        Spacer()
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    if isUltraCompact {
                        Circle()
                            .fill(program.isCurrentlyAiring ? progressColor : Color.white.opacity(0.36))
                            .frame(width: 5, height: 5)
                    } else {
                        Text(program.title)
                            .font(.system(size: titleSize, weight: .bold, design: .rounded))
                            .foregroundStyle(program.hasEnded ? .white.opacity(0.45) : .white)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        if !isCompact {
                            Text(timeDurationLabel)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(isSelected ? .white.opacity(0.85) : .white.opacity(0.40))
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.leading, (program.isCurrentlyAiring && !isUltraCompact) ? 12 : 10)
                .padding(.trailing, 8)
                .padding(.top, 8)
                .padding(.bottom, (program.isCurrentlyAiring || program.hasEnded) ? 14 : 8)

                // Progress bar at bottom — hot pink Pluto style
                if (program.isCurrentlyAiring || program.hasEnded) && !isUltraCompact {
                    EPGProgressBar(progress: program.progress, height: 4,
                                   foregroundColor: progressColor)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 4)
                }
            }
            .frame(width: width, height: cellHeight, alignment: .leading)
            .background(backgroundFill)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .scaleEffect(isHighlighted ? 1.012 : 1)
            .shadow(color: isHighlighted ? Color.white.opacity(0.04) : .clear, radius: 7, y: 3)
            .zIndex(isHighlighted ? 10 : 0)
            .animation(.easeOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(TVNoGlowButtonStyle())
        .focusEffectDisabled()
    }

    private var titleSize: CGFloat {
        if width > 300 { return 17 }
        if width > 200 { return 15 }
        if width > 120 { return 13 }
        return 10
    }

    private var timeDurationLabel: String {
        let startStr = Self.startTimeFmt.string(from: program.startTime)
        let mins = Int(program.endTime.timeIntervalSince(program.startTime) / 60)
        let durationStr: String
        if mins >= 60 && mins % 60 == 0 {
            durationStr = "\(mins / 60)h"
        } else if mins >= 60 {
            durationStr = "\(mins / 60)h \(mins % 60)m"
        } else {
            durationStr = "\(mins)m"
        }
        return "\(startStr) · \(durationStr)"
    }

    private static let startTimeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mma"
        return f
    }()

    private var isHighlighted: Bool { isSelected }

    private var backgroundFill: Color {
        if isHighlighted {
            return Color(red: 45/255, green: 40/255, blue: 79/255)
        }
        if program.isCurrentlyAiring { return Color(red: 24/255, green: 26/255, blue: 48/255) }
        return Color(red: 20/255, green: 22/255, blue: 40/255)
    }

    private var borderColor: Color {
        if isHighlighted { return Color.white.opacity(0.72) }
        return Color.white.opacity(0.03)
    }

    private var borderWidth: CGFloat {
        isHighlighted ? 2 : 0.8
    }
}

private struct TVGuideHighlightCard: View {
    let channel: Channel
    let program: Program
    let accent: Color
    let action: () -> Void
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(channel.number.map { "\($0) \(channel.name)" } ?? channel.name)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(accent)

                Text(program.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(program.timeRangeFormatted)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(16)
            .frame(width: 196, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isFocused ? accent.opacity(0.22) : panelBackgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isFocused ? Color.white.opacity(0.88) : Color.white.opacity(0.08), lineWidth: isFocused ? 2.5 : 1.5)
            )
            .scaleEffect(isFocused ? 1.03 : 1)
            .shadow(color: isFocused ? Color.white.opacity(0.15) : .clear, radius: 14, y: 8)
            .animation(.easeOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(TVNoGlowButtonStyle())
    }

    private var panelBackgroundFill: Color {
        Color.white.opacity(0.05)
    }
}

private struct TVGuideFeatureChip: View {
    let title: String
    let icon: String
    let accent: Color
    let action: () -> Void
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .black, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isFocused ? accent.opacity(0.22) : Color.white.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .stroke(isFocused ? Color.white.opacity(0.85) : Color.white.opacity(0.08), lineWidth: isFocused ? 2.25 : 1.5)
            )
            .scaleEffect(isFocused ? 1.02 : 1)
            .shadow(color: isFocused ? Color.white.opacity(0.12) : .clear, radius: 9, y: 4)
            .animation(.easeOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(TVNoGlowButtonStyle())
    }
}

private struct TVGuideActionButton: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    let icon: String
    let accent: Color
    let style: Style
    let action: () -> Void
    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(style == .primary && !isFocused ? .black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(backgroundFill)
            )
            .overlay(
                Capsule()
                    .stroke(
                        isFocused ? Color.white.opacity(0.88) : (style == .primary ? Color.clear : accent.opacity(0.75)),
                        lineWidth: isFocused ? 2.25 : 1.5
                    )
            )
            .scaleEffect(isFocused ? 1.02 : 1)
            .shadow(color: isFocused ? Color.white.opacity(0.12) : .clear, radius: 9, y: 4)
            .animation(.easeOut(duration: 0.18), value: isFocused)
        }
        .buttonStyle(TVNoGlowButtonStyle())
    }

    private var backgroundFill: Color {
        switch style {
        case .primary:
            return isFocused ? accent : .white
        case .secondary:
            return isFocused ? accent.opacity(0.26) : Color.white.opacity(0.06)
        }
    }
}

private extension Array {
    func ifEmpty(_ fallback: @autoclosure () -> [Element]) -> [Element] {
        isEmpty ? fallback() : self
    }
}

private extension Optional where Wrapped == String {
    var orEmpty: String { self ?? "" }
}
#endif

// MARK: - Live TV Player View

struct LiveTVPlayerView: View {
    let channel: Channel
    let streamURL: URL
    @ObservedObject var viewModel: LiveTVViewModel

    @StateObject private var vlcPlayer = VLCPlayerViewModel()
    @StateObject private var playerViewModel = PlayerViewModel()  // Kept for VOD/recordings
    @StateObject private var instantSwitchManager = InstantSwitchManager()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var dvrViewModel: DVRViewModel

    // UI State
    @State private var showOverlay = true
    @State private var showMiniEPG = false
    @State private var showChannelSurfing = false
    @State private var surfingChannel: Channel?
    @State private var surfingCountdown: Int = 0
    @State private var showStreamInfo = true
    @State private var showControls = true // Full controls panel

    // Number pad entry
    @State private var channelNumberEntry: String = ""
    @State private var showChannelNumberEntry = false
    @State private var channelEntryTask: Task<Void, Never>?
    @State private var showMultiview = false
    @State private var multiviewPickedChannel: Channel?

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

            // Video Player (VLC - plays MPEG-TS, DASH, HLS, and all formats)
            VLCPlayerView(viewModel: vlcPlayer)
                .ignoresSafeArea()

            // Always-visible close button (top-left safe area)
            VStack {
                HStack {
                    Button {
                        vlcPlayer.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    Spacer()
                }
                Spacer()
            }

            // Loading State
            if vlcPlayer.isLoading {
                loadingOverlay
            }

            // Error State
            if let error = vlcPlayer.error {
                errorOverlay(error)
            }

            // Channel Info Overlay (bottom)
            if showOverlay && vlcPlayer.error == nil && !vlcPlayer.isLoading {
                channelInfoOverlay
            }

            // Stream Info (top-right)
            if showOverlay && showStreamInfo && vlcPlayer.streamInfo != nil {
                vlcStreamInfoOverlay
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
            // Note: aspect ratio label is managed by controls overlay

            // Full Controls Overlay (shown on select/tap)
            if showControls {
                LiveTVControlsOverlay(
                    vlcPlayer: vlcPlayer,
                    liveTVViewModel: viewModel,
                    channel: viewModel.selectedChannel ?? channel,
                    onClose: {
                        vlcPlayer.stop()
                        dismiss()
                    },
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
                    onChannelUp: {
                        handleNextChannel()
                    },
                    onChannelDown: {
                        handlePreviousChannel()
                    },
                    onToggleFavorite: {
                        handleToggleFavorite()
                    },
                    onRecord: {
                        guard let program = viewModel.selectedChannel?.nowPlaying ?? channel.nowPlaying else {
                            return
                        }
                        Task {
                            try? await dvrViewModel.recordProgram(channel: channel, program: program)
                            await MainActor.run {
                                showPlayerToast("Recording Scheduled", icon: "record.circle")
                            }
                        }
                    },
                    onInfo: {
                        showStreamInfo.toggle()
                    },
                    onPiP: {
                        showPlayerToast("PiP", icon: "pip")
                    },
                    onMultiview: {
                        showMultiview = true
                    },
                    onDismiss: {
                        showControls = false
                    }
                )
            }
        }
        .onAppear {
            print("🟢 LiveTVPlayerView.onAppear - URL: \(streamURL.absoluteString)")
            print("🟢 LiveTVPlayerView.onAppear - Channel: \(channel.name)")
            vlcPlayer.play(url: streamURL)
            scheduleHideOverlay()

            // Start preloading adjacent channels
            instantSwitchManager.preloadAdjacentChannels(
                current: channel,
                channels: viewModel.displayedChannels
            )
        }
        .onDisappear {
            vlcPlayer.stop()
            instantSwitchManager.cleanup()
            overlayHideTask?.cancel()
            surfingTask?.cancel()
            channelEntryTask?.cancel()
        }
        .fullScreenCover(isPresented: $showMultiview, onDismiss: {
            if let picked = multiviewPickedChannel {
                multiviewPickedChannel = nil
                changeChannel(to: picked)
            } else {
                let current = viewModel.selectedChannel ?? channel
                changeChannel(to: current)
            }
        }) {
            MultiviewPlayerV2(
                initialChannel: viewModel.selectedChannel ?? channel,
                viewModel: viewModel,
                onDismiss: { showMultiview = false },
                onFullScreen: { picked in
                    multiviewPickedChannel = picked
                    showMultiview = false
                }
            )
        }
        #if os(tvOS)
        .onPlayPauseCommand {
            // Show full controls on play/pause press (Space bar)
            if !showControls && !showMiniEPG && !showChannelSurfing {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showControls = true
                }
            } else if showControls {
                vlcPlayer.togglePlayPause()
            }
            showOverlayTemporarily()
        }
        #endif
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
        // A key - Cycle audio track (VLC)
        .onKeyPress("a") {
            let tracks = vlcPlayer.audioTracks
            if !tracks.isEmpty {
                let current = vlcPlayer.selectedAudioTrack
                if let idx = tracks.firstIndex(where: { $0.index == current }) {
                    let next = tracks[(idx + 1) % tracks.count]
                    vlcPlayer.selectAudioTrack(next.index)
                    showPlayerToast("Audio: \(next.name)", icon: "speaker.wave.3")
                }
            }
            return .handled
        }
        // S key - Cycle subtitles (VLC)
        .onKeyPress("s") {
            let tracks = vlcPlayer.subtitleTracks
            if vlcPlayer.selectedSubtitleTrack == -1 && !tracks.isEmpty {
                vlcPlayer.selectSubtitleTrack(tracks[0].index)
                showPlayerToast("Subtitles: \(tracks[0].name)", icon: "captions.bubble")
            } else if let idx = tracks.firstIndex(where: { $0.index == vlcPlayer.selectedSubtitleTrack }) {
                let nextIdx = idx + 1
                if nextIdx < tracks.count {
                    vlcPlayer.selectSubtitleTrack(tracks[nextIdx].index)
                    showPlayerToast("Subtitles: \(tracks[nextIdx].name)", icon: "captions.bubble")
                } else {
                    vlcPlayer.disableSubtitles()
                    showPlayerToast("Subtitles Off", icon: "captions.bubble")
                }
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
            // VLC aspect ratio cycling
            let ratios: [(String?, String)] = [(nil, "Default"), ("16:9", "16:9"), ("4:3", "4:3"), ("1:1", "1:1")]
            // Simple cycle through ratios
            showPlayerToast("Aspect Ratio", icon: "rectangle.arrowtriangle.2.inward")
            return .handled
        }
        // Number keys 0-9 for direct channel entry
        .onKeyPress(characters: .decimalDigits) { press in
            handleNumberKeyPress(press.characters)
            return .handled
        }
        #if os(tvOS)
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
        #endif
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
                    vlcPlayer.retry()
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

    private var vlcStreamInfoOverlay: some View {
        VStack {
            HStack {
                Spacer()
                if let info = vlcPlayer.streamInfo {
                    HStack(spacing: 8) {
                        if let res = info.resolutionLabel {
                            Text(res)
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(4)
                        }
                        if vlcPlayer.isBuffering {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(24)
                }
            }
            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Input Handling

    #if os(tvOS)
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
    #endif

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
            // Nothing to dismiss — open the sidecar drawer instead
            NotificationCenter.default.post(name: .sidecarToggle, object: nil)
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

            if let url = newChannel.preferredPlaybackURL {
                vlcPlayer.play(url: url)
            } else if let url = try? await viewModel.getChannelStream(newChannel) {
                vlcPlayer.play(url: url)
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

    private func handleNextChannel() {
        guard let nextChannel = viewModel.nextChannel() else { return }
        showControls = false
        changeChannel(to: nextChannel)
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
        #if os(tvOS)
        .onExitCommand {
            cancelChannelNumberEntry()
        }
        #endif
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
                    Image(systemName: vlcPlayer.aspectRatioMode.icon)
                        .font(.system(size: 32))
                    Text(vlcPlayer.aspectRatioMode.rawValue)
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
    @ObservedObject var vlcPlayer: VLCPlayerViewModel
    @ObservedObject var liveTVViewModel: LiveTVViewModel
    let channel: Channel
    var onClose: () -> Void
    var onGuide: () -> Void
    var onChannels: () -> Void
    var onPreviousChannel: () -> Void
    var onChannelUp: () -> Void
    var onChannelDown: () -> Void
    var onToggleFavorite: () -> Void
    var onRecord: () -> Void
    var onInfo: () -> Void
    var onPiP: () -> Void
    var onMultiview: () -> Void
    var onDismiss: () -> Void

    @FocusState private var focusedControl: LiveTVControl?
    @State private var showSleepTimerPicker = false
    @State private var toastMessage: String?
    @State private var toastIcon: String?

    enum LiveTVControl: Hashable {
        case close, streamInfo, mute
        case skipBack, playPause, skipForward
        case favorite, previousChannel, aspectRatio, sleepTimer, audio, subtitles
        case channelUp, channelDown, multiview
        case record, info, pip
        case quickGuide
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

                Spacer().frame(height: 20)

                // Quick Actions Row
                quickActionsRow
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
            if vlcPlayer.showAspectRatioLabel {
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
        #if os(tvOS)
        .onExitCommand {
            if showSleepTimerPicker {
                showSleepTimerPicker = false
            } else {
                onDismiss()
            }
        }
        #endif
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
            if let streamInfo = vlcPlayer.streamInfo {
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
            if vlcPlayer.sleepTimerRemaining > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "moon.zzz.fill")
                    Text(vlcPlayer.sleepTimerLabel)
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
                icon: vlcPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                control: .mute,
                iconColor: vlcPlayer.isMuted ? .red : .white,
                action: {
                    vlcPlayer.toggleMute()
                    showToast(vlcPlayer.isMuted ? "Muted" : "Unmuted",
                              icon: vlcPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
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
                    vlcPlayer.skipBackward()
                    showToast("-10s", icon: "gobackward.10")
                }
            )

            // Play/Pause
            Button(action: { vlcPlayer.togglePlayPause() }) {
                ZStack {
                    Circle()
                        .fill(EPGTheme.accent.opacity(0.3))
                        .frame(width: 100, height: 100)

                    Image(systemName: vlcPlayer.isPlaying ? "pause.fill" : "play.fill")
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
                    vlcPlayer.skipForward()
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
                icon: vlcPlayer.aspectRatioMode.icon,
                label: vlcPlayer.aspectRatioMode.rawValue,
                control: .aspectRatio,
                action: {
                    let mode = vlcPlayer.cycleAspectRatio()
                    showToast(mode.rawValue, icon: mode.icon)
                }
            )

            // Sleep Timer
            actionButton(
                icon: "moon.zzz",
                label: vlcPlayer.sleepTimerRemaining > 0 ? vlcPlayer.sleepTimerLabel : "Sleep",
                control: .sleepTimer,
                iconColor: vlcPlayer.sleepTimerRemaining > 0 ? .orange : .white,
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
                    if let trackName = vlcPlayer.cycleAudioTrack() {
                        showToast("Audio: \(trackName)", icon: "speaker.wave.3")
                    }
                }
            )

            // Subtitles
            actionButton(
                icon: "captions.bubble",
                label: "Subtitles",
                control: .subtitles,
                action: {
                    if let trackName = vlcPlayer.cycleSubtitleTrack() {
                        showToast("Subtitles: \(trackName)", icon: "captions.bubble")
                    } else {
                        showToast("Subtitles Off", icon: "captions.bubble")
                    }
                }
            )
        }
    }

    private var quickActionsRow: some View {
        HStack(spacing: 16) {
            // Record
            actionButton(
                icon: "record.circle",
                label: "Record",
                control: .record,
                action: {
                    onRecord()
                }
            )

            // Channel Up
            actionButton(
                icon: "chevron.up",
                label: "Up",
                control: .channelUp,
                action: {
                    onChannelUp()
                }
            )

            // Channel Down
            actionButton(
                icon: "chevron.down",
                label: "Down",
                control: .channelDown,
                action: {
                    onChannelDown()
                }
            )

            // Guide
            actionButton(
                icon: "list.bullet",
                label: "Guide",
                control: .quickGuide,
                action: {
                    onGuide()
                }
            )

            // Info
            actionButton(
                icon: "info.circle",
                label: "Info",
                control: .info,
                action: {
                    onInfo()
                    showToast("Info", icon: "info.circle")
                }
            )

            // PiP
            actionButton(
                icon: "pip",
                label: "PiP",
                control: .pip,
                action: {
                    onPiP()
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
                    Image(systemName: vlcPlayer.aspectRatioMode.icon)
                        .font(.system(size: 32))
                    Text(vlcPlayer.aspectRatioMode.rawValue)
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
                            vlcPlayer.setSleepTimer(option)
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
                                    option == vlcPlayer.sleepTimerOption
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
        #if os(tvOS)
        .onExitCommand {
            onDismiss()
        }
        #endif
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

// MARK: - Live TV Feature Bar

struct LiveTVFeatureBar: View {
    let onCatchup: () -> Void
    let onOnLater: () -> Void
    let onTeamPass: () -> Void
    let onChannelGroups: () -> Void
    let onMultiview: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                FeatureButton(
                    icon: "clock.arrow.circlepath",
                    title: "Catch Up",
                    color: Color(red: 0.55, green: 0.36, blue: 0.96),
                    action: onCatchup
                )
                
                FeatureButton(
                    icon: "clock.badge.checkmark",
                    title: "On Later",
                    color: Color(red: 0.23, green: 0.51, blue: 0.96),
                    action: onOnLater
                )
                
                FeatureButton(
                    icon: "sportscourt",
                    title: "Team Pass",
                    color: Color(red: 0.06, green: 0.73, blue: 0.51),
                    action: onTeamPass
                )
                
                FeatureButton(
                    icon: "rectangle.stack",
                    title: "Groups",
                    color: Color(red: 0.96, green: 0.62, blue: 0.04),
                    action: onChannelGroups
                )
                
                FeatureButton(
                    icon: "rectangle.split.2x2",
                    title: "Multiview",
                    color: Color(red: 0, green: 0.83, blue: 0.67),
                    action: onMultiview
                )
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 16)
        }
        .background(Color.black.opacity(0.3))
    }
}

struct FeatureButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @Environment(\.isFocused) private var isFocused
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isFocused ? .black : .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isFocused ? color : color.opacity(0.3))
            )
            .overlay(
                Capsule()
                    .stroke(color, lineWidth: isFocused ? 0 : 1)
            )
        }
        .buttonStyle(TVNoGlowButtonStyle())
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

/// Strips tvOS system focus chrome (white glow) — views handle their own focus styling
struct TVNoGlowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    LiveTVView()
}
