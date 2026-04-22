import SwiftUI
import AVFoundation

#if !targetEnvironment(simulator) && os(iOS)
import MobileVLCKit
#elseif !targetEnvironment(simulator) && os(tvOS)
import TVVLCKit
#endif

// MARK: - ESPN Player
//
// Single playback surface for the ESPN section. Two entry points:
//   1. `init(linear:)` — for linear ESPN channels from `hub.linearChannels`.
//      Resolves URL via `/api/tuner-backends/active/stream/:channelId`.
//   2. `init(event:container:initialMode:)` — for Disney-shaped playable
//      events inside `hub.disneyHub`. Resolves URL via
//      `/api/tuner-backends/active/espn/play/stream` with browse-derived
//      context. Supports `mode=startover`.
//
// Both use the shared `VLCPlayerView`/`VLCPlayerViewModel` plumbing.
// `repo.beginPlayback()` / `endPlayback()` keeps the hub poll suspended
// for the duration so a refresh doesn't race with reconnect logic.

struct ESPNPlayerView: View {
    enum Source {
        case linear(ESPNLinearChannel)
        case event(item: DXItem, container: DXContainer?)
    }

    let source: Source
    @ObservedObject var repo: ESPNRepository
    var initialMode: String?
    let onClose: () -> Void

    @StateObject private var vlcPlayer = VLCPlayerViewModel()
    @State private var currentMode: String?
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?
    @State private var resolveError: String?
    @State private var nowTick: Date = Date()

    private let accent = Color(red: 0.95, green: 0.18, blue: 0.18)

    // MARK: Convenience inits

    init(linear: ESPNLinearChannel, repo: ESPNRepository, onClose: @escaping () -> Void) {
        self.source = .linear(linear)
        self.repo = repo
        self.initialMode = nil
        self.onClose = onClose
        _currentMode = State(initialValue: nil)
    }

    init(event item: DXItem, container: DXContainer?, repo: ESPNRepository, initialMode: String? = nil, onClose: @escaping () -> Void) {
        self.source = .event(item: item, container: container)
        self.repo = repo
        self.initialMode = initialMode
        self.onClose = onClose
        _currentMode = State(initialValue: initialMode)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VLCPlayerView(viewModel: vlcPlayer)
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.black.opacity(0.35), .clear, .clear, Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .opacity(showControls ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: showControls)

            Color.clear
                .contentShape(Rectangle())
                .allowsHitTesting(!showControls)
                .onTapGesture {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        showControls = true
                    }
                    scheduleAutoHide()
                }

            if !vlcPlayer.hasReachedPlaying && (vlcPlayer.isLoading || vlcPlayer.isBuffering) {
                bufferingHUD
            }

            if let error = vlcPlayer.error ?? resolveError {
                errorOverlay(error)
            }

            if showControls {
                controlsOverlay
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        )
                    )
            }
        }
        #if os(iOS)
        .statusBarHidden(true)
        #endif
        .task {
            repo.beginPlayback()
            await play(mode: currentMode)
            scheduleAutoHide()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                nowTick = Date()
                if vlcPlayer.isPlaying {
                    vlcPlayer.extractStreamInfo()
                }
            }
        }
        .onDisappear {
            vlcPlayer.stop()
            hideTask?.cancel()
            repo.endPlayback()
        }
        #if os(tvOS)
        .onPlayPauseCommand { vlcPlayer.togglePlayPause(); scheduleAutoHide() }
        .onExitCommand { onClose() }
        #endif
    }

    // MARK: Source-derived display

    private var sourceTitle: String {
        switch source {
        case .linear(let channel): return channel.name
        case .event(let item, _): return item.displayTitle ?? "ESPN"
        }
    }

    private var sourceSubtitle: String? {
        switch source {
        case .linear(let channel):
            if let n = channel.number { return "Channel \(n)" }
            return nil
        case .event(let item, _):
            let parts = [item.league, item.sport].compactMap { $0 }.filter { !$0.isEmpty }
            if !parts.isEmpty { return parts.joined(separator: " · ") }
            return item.displaySubtitle
        }
    }

    private var supportsStartover: Bool {
        if case .event(let item, _) = source { return item.supportsStartover }
        return false
    }

    private var sourceIsLive: Bool {
        switch source {
        case .linear: return true
        case .event(let item, _): return item.isLive
        }
    }

    private var liveProgress: Double? {
        guard case .event(let item, _) = source, let start = item.startTimeDate else { return nil }
        let endDate: Date = {
            if let endStr = item.endTime, let parsed = ISO8601DateFormatter().date(from: endStr) {
                return parsed
            }
            return start.addingTimeInterval(3 * 3600)
        }()
        let total = endDate.timeIntervalSince(start)
        guard total > 0 else { return nil }
        return nowTick.timeIntervalSince(start) / total
    }

    // MARK: Controls overlay

    private var controlsOverlay: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 18)
                .padding(.top, 22)
            Spacer()
            centerTransport
            Spacer()
            bottomStack
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            iconButton(systemName: "xmark", action: onClose)
            espnWordmark
            Spacer()
            if supportsStartover {
                if currentMode == "startover" {
                    pillButton(title: "Watch Live", icon: "dot.radiowaves.left.and.right") {
                        Task { await play(mode: nil) }
                    }
                } else {
                    pillButton(title: "Start Over", icon: "arrow.counterclockwise") {
                        Task { await play(mode: "startover") }
                    }
                }
            }
        }
    }

    private var espnWordmark: some View {
        HStack(spacing: 6) {
            Text("ESPN")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(accent, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            if case .event(let item, _) = source, let league = item.league, !league.isEmpty {
                Text(league.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    private var centerTransport: some View {
        HStack(spacing: 36) {
            transportIcon(systemName: "gobackward.15") {
                vlcPlayer.mediaPlayer.jumpBackward(15)
            }
            transportIcon(
                systemName: vlcPlayer.isPlaying ? "pause.fill" : "play.fill",
                size: 46,
                primary: true
            ) {
                vlcPlayer.togglePlayPause()
            }
            transportIcon(systemName: "goforward.15") {
                vlcPlayer.mediaPlayer.jumpForward(15)
            }
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }

    private var bottomStack: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let summary = sourceSubtitle {
                Text(summary)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }
            Text(sourceTitle)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .shadow(color: .black.opacity(0.5), radius: 6, y: 2)
            HStack(alignment: .center, spacing: 12) {
                if sourceIsLive {
                    Circle().fill(accent).frame(width: 8, height: 8)
                    Text(currentMode == "startover" ? "FROM BEGINNING" : "LIVE")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                        .tracking(1.5)
                }
                if let progress = liveProgress {
                    progressTrack(progress: progress)
                }
                Spacer()
                #if os(iOS)
                iconButton(systemName: "arrow.up.left.and.arrow.down.right") {
                    _ = vlcPlayer.cycleAspectRatio()
                }
                #endif
            }
        }
    }

    private func progressTrack(progress: Double) -> some View {
        GeometryReader { geo in
            let p = CGFloat(min(max(progress, 0), 1))
            let dotX = geo.size.width * p
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.18)).frame(height: 3)
                Capsule().fill(accent).frame(width: dotX, height: 3)
                Circle().fill(accent).frame(width: 11, height: 11).offset(x: dotX - 5.5)
            }
        }
        .frame(height: 11)
    }

    private func transportIcon(systemName: String, size: CGFloat = 28, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: { action(); scheduleAutoHide() }) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: primary ? 76 : 52, height: primary ? 76 : 52)
                .background(
                    Circle().fill(primary ? accent : Color.white.opacity(0.06))
                )
                .shadow(color: primary ? accent.opacity(0.55) : .clear, radius: 14, y: 5)
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: primary ? 38 : 26))
    }

    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: { action(); scheduleAutoHide() }) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.black.opacity(0.55), in: Circle())
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 20))
    }

    private func pillButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: { action(); scheduleAutoHide() }) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .bold))
                Text(title).font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(accent.opacity(0.85), in: Capsule())
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
    }

    // MARK: Buffering / error / play

    private var bufferingHUD: some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.3).tint(.white)
            Text(bufferingMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 22).padding(.vertical, 16)
        .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var bufferingMessage: String {
        if !vlcPlayer.isPlaying && vlcPlayer.isLoading { return "Loading stream…" }
        if vlcPlayer.isBuffering { return "Buffering…" }
        return "Connecting…"
    }

    private func errorOverlay(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40)).foregroundStyle(.orange)
            Text("Playback unavailable")
                .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            Text(msg)
                .font(.system(size: 13)).foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center).padding(.horizontal, 30)
            Button("Close", action: onClose)
                .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
                .padding(.top, 6)
        }
    }

    private func play(mode: String?) async {
        let url: URL?
        switch source {
        case .linear(let channel):
            url = await repo.linearStreamURL(for: channel)
        case .event(let item, let container):
            url = await repo.eventStreamURL(for: item, in: container, mode: mode)
        }
        guard let url else {
            resolveError = "No playable URL for this item."
            return
        }
        currentMode = mode
        resolveError = nil
        vlcPlayer.play(url: url)
    }

    private func scheduleAutoHide() {
        hideTask?.cancel()
        hideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.25)) { showControls = false }
            }
        }
    }
}
