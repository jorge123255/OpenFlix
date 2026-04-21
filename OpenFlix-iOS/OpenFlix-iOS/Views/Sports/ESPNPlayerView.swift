import SwiftUI
import AVFoundation

extension Notification.Name {
    /// Posted by `ESPNPlayerView` when the user taps Prev/Next event.
    /// `userInfo["itemId"]` carries the sibling's id so the detail view
    /// can swap and re-present.
    static let espnPlayerJumpToItem = Notification.Name("espnPlayerJumpToItem")
}
#if !targetEnvironment(simulator) && os(iOS)
import MobileVLCKit
#elseif !targetEnvironment(simulator) && os(tvOS)
import TVVLCKit
#endif

// MARK: - ESPN Player
//
// Dedicated playback surface for ESPN events. Built on the existing
// `VLCPlayerView` pipeline (same reliability work as Live TV) but with
// ESPN-specific chrome: server-defined `Watch Live` / `Start Over` mode
// switching, ±10s skip, auto-hiding controls, multi-view, and Liquid
// Glass on iOS 26. Live TV's player is intentionally not reused — this
// player has no channel-up/down or OpenFlix DVR concept.

struct ESPNPlayerView: View {
    let item: ESPNItem
    let container: ESPNContainer?
    @ObservedObject var repo: ESPNRepository
    var initialMode: String?    // nil = live; "startover" = from beginning
    let onClose: () -> Void

    @StateObject private var vlcPlayer = VLCPlayerViewModel()
    @State private var currentMode: String?
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?
    @State private var resolveError: String?
    @State private var showMultiview = false
    @State private var showStreamInfo = false
    /// Wall-clock seconds elapsed since the player view appeared — used
    /// to drive the "live progress" bar against the event's known
    /// startTime/endTime when available.
    @State private var nowTick: Date = Date()
    /// When VLC last ENTERED a buffering state. Used to detect long
    /// stalls and force a reconnect.
    @State private var bufferStartedAt: Date?
    @State private var stallRecoveries: Int = 0



    init(item: ESPNItem, container: ESPNContainer?, repo: ESPNRepository, initialMode: String? = nil, onClose: @escaping () -> Void) {
        self.item = item
        self.container = container
        self.repo = repo
        self.initialMode = initialMode
        self.onClose = onClose
        _currentMode = State(initialValue: initialMode)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VLCPlayerView(viewModel: vlcPlayer)
                .ignoresSafeArea()

            // Subtle vignette so any chrome reads against bright video.
            LinearGradient(
                colors: [Color.black.opacity(0.35), .clear, .clear, Color.black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .opacity(showControls ? 1 : 0)
            .animation(.easeInOut(duration: 0.25), value: showControls)

            // Tap-anywhere toggle
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.22)) { showControls.toggle() }
                    if showControls { scheduleAutoHide() }
                }

            if vlcPlayer.isLoading || (vlcPlayer.isBuffering && !vlcPlayer.isPlaying) {
                bufferingHUD
            }

            if let error = vlcPlayer.error ?? resolveError {
                errorOverlay(error)
            }

            if showControls {
                controlsOverlay
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        #if os(iOS)
        .statusBarHidden(true)
        #endif
        .task {
            // Suspend the hub's 45s browse polling while the player is
            // active — playback takes priority and a refresh mid-stream
            // can race with reconnect logic.
            repo.beginPlayback()
            await play(mode: currentMode)
            scheduleAutoHide()
        }
        .task {
            // Slow ticker — drives the live progress bar + stream-info HUD
            // and re-pings VLC for codec/channel info (it populates a few
            // seconds after playback begins, not immediately).
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                nowTick = Date()
                if vlcPlayer.isPlaying {
                    vlcPlayer.extractStreamInfo()
                }
            }
        }
        .task(id: vlcPlayer.isBuffering) {
            await stallWatchdog()
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
        .fullScreenCover(isPresented: $showMultiview) {
            ESPNMultiviewView(
                primaryItem: item,
                primaryContainer: container,
                repo: repo,
                onClose: { showMultiview = false }
            )
        }
    }

    // MARK: Controls overlay
    //
    // Layout (Hulu/ABC-style):
    //   ┌─────────────────────────────────────────────┐
    //   │ ESPN logo                          ⋯ menu   │  ← compact top bar
    //   │                                             │
    //   │     |◀  ⟲15   ⏯ (big)   15⟳   ▶|           │  ← center transport
    //   │                                             │
    //   │                                             │
    //   │ Date · League · Sport                       │
    //   │ EVENT TITLE (huge)                          │
    //   │ 34:58 ━━━━●━━━━━━━━━━━━━━━━━━ 1:00:00  ⛶  │  ← progress + fullscreen
    //   └─────────────────────────────────────────────┘

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

    /// Top: Close · ESPN wordmark only. All other actions moved to bottom.
    private var topBar: some View {
        HStack(spacing: 12) {
            iconButton(systemName: "xmark", label: "Close", size: 18, action: onClose)

            espnWordmark

            Spacer()
        }
    }

    private var espnWordmark: some View {
        HStack(spacing: 6) {
            Text("ESPN")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    OpenFlixColors.accent.opacity(0.35),
                    in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                )
            if let league = item.league, !league.isEmpty {
                Text(league.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    /// Center row: prev event |◀ · skip back 15 ⟲15 · big play/pause ·
    /// skip forward 15 15⟳ · next event ▶|.
    private var centerTransport: some View {
        HStack(spacing: 28) {
            transportIcon(systemName: "backward.end.fill", size: 22, enabled: previousItem != nil) {
                if let prev = previousItem { jumpToItem(prev) }
            }
            transportIcon(systemName: "gobackward.15", size: 32) {
                vlcPlayer.mediaPlayer.jumpBackward(15)
            }
            transportIcon(
                systemName: vlcPlayer.isPlaying ? "pause.fill" : "play.fill",
                size: 38,
                primary: true
            ) {
                vlcPlayer.togglePlayPause()
            }
            transportIcon(systemName: "goforward.15", size: 32) {
                vlcPlayer.mediaPlayer.jumpForward(15)
            }
            transportIcon(systemName: "forward.end.fill", size: 22, enabled: nextItem != nil) {
                if let next = nextItem { jumpToItem(next) }
            }
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }


    /// Bottom block: optional Stream Info HUD · date+league line · big
    /// title · progress bar with inline LIVE marker · fullscreen toggle.
    private var bottomStack: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Stream info chips row (toggled via More button)
            if showStreamInfo {
                HStack(spacing: 8) {
                    ForEach(streamInfoChips, id: \.label) { chip in
                        HStack(spacing: 4) {
                            Text(chip.label)
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundStyle(.white.opacity(0.55))
                            Text(chip.value)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        #if os(iOS)
                        .openFlixGlassRegular(in: Capsule(), tint: Color.white.opacity(0.08))
                        #else
                        .background(Color.black.opacity(0.55), in: Capsule())
                        #endif
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }

            if let summary = topSubtitle {
                Text(summary)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
            }

            Text(item.title ?? "ESPN")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .shadow(color: .black.opacity(0.5), radius: 6, y: 2)

            HStack(alignment: .center, spacing: 12) {
                Text(elapsedLabel.isEmpty ? "0:00" : elapsedLabel)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(minWidth: 48, alignment: .leading)

                progressTrack(progress: liveProgress)

                Text(remainingLabel.isEmpty ? "—" : remainingLabel)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(minWidth: 56, alignment: .trailing)

                // Bottom action buttons: aspect, multi-view, more
                HStack(spacing: 10) {
                    #if os(iOS)
                    iconButton(systemName: "arrow.up.left.and.arrow.down.right", label: "Aspect", size: 16) {
                        _ = vlcPlayer.cycleAspectRatio()
                    }
                    #endif

                    if item.supportsStartover {
                        if currentMode == "startover" {
                            iconButton(systemName: "dot.radiowaves.left.and.right", label: "Watch Live", size: 16) {
                                Task { await play(mode: nil) }
                            }
                        } else {
                            iconButton(systemName: "arrow.counterclockwise", label: "Start Over", size: 16) {
                                Task { await play(mode: "startover") }
                            }
                        }
                    }

                    iconButton(systemName: "rectangle.split.2x2.fill", label: "Multi-view", size: 16) {
                        showMultiview = true
                    }

                    iconButton(systemName: "ellipsis", label: "More", size: 16) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showStreamInfo.toggle()
                        }
                    }
                }
            }
        }
    }

    private func progressTrack(progress: Double?) -> some View {
        GeometryReader { geo in
            let p = CGFloat(min(max(progress ?? 0, 0), 1))
            let dotX = geo.size.width * p
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 3)
                if progress != nil {
                    Capsule()
                        .fill(Color.white)
                        .frame(width: dotX, height: 3)

                    // Glass capsule badge centered above playhead
                    Text(currentMode == "startover" ? "START OVER" : "LIVE")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(currentMode == "startover" ? .white.opacity(0.9) : .black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        #if os(iOS)
                        .openFlixGlassRegular(in: Capsule(), tint: Color.white.opacity(0.15))
                        #else
                        .background(Color.black.opacity(0.55), in: Capsule())
                        #endif
                        .offset(x: max(min(dotX - 20, geo.size.width - 50), 0), y: -18)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .shadow(color: Color.white.opacity(0.4), radius: 6)
                        .offset(x: dotX - 5)
                }
            }
        }
        .frame(height: 14)
    }

    private func transportIcon(systemName: String, size: CGFloat, primary: Bool = false, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: { if enabled { action(); scheduleAutoHide() } }) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(enabled ? Color.white : Color.white.opacity(0.3))
                .frame(width: primary ? 88 : 64, height: primary ? 88 : 64)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(color: primary ? Color.white.opacity(0.08) : .clear, radius: 14, y: 5)
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: primary ? 44 : 32))
        .disabled(!enabled)
    }

    // MARK: Sibling navigation
    //
    // Previous/next event navigation walks the items in the source
    // container in their server-supplied order. Skips items that aren't
    // playable (no resourceId / upcoming).

    private var siblingItems: [ESPNItem] {
        guard let container,
              let items = repo.setItems[container.id] ?? container.items
        else { return [] }
        return items.filter { $0.playback?.resourceId != nil && !$0.isUpcoming }
    }

    private var currentSiblingIndex: Int? {
        siblingItems.firstIndex { $0.id == item.id }
    }

    private var previousItem: ESPNItem? {
        guard let i = currentSiblingIndex, i > 0 else { return nil }
        return siblingItems[i - 1]
    }

    private var nextItem: ESPNItem? {
        guard let i = currentSiblingIndex, i + 1 < siblingItems.count else { return nil }
        return siblingItems[i + 1]
    }

    private func jumpToItem(_ next: ESPNItem) {
        // Re-present this view with the sibling. Cleanest path: close
        // and let the caller's binding open the new one. Since the
        // detail view is the one driving presentation, we publish the
        // sibling via NotificationCenter — the hub picks it up and
        // re-presents the player on the new item.
        NotificationCenter.default.post(
            name: .espnPlayerJumpToItem,
            object: nil,
            userInfo: ["itemId": next.id]
        )
        onClose()
    }

    private func iconButton(systemName: String, label: String, size: CGFloat = 22, action: @escaping () -> Void) -> some View {
        Button(action: { action(); scheduleAutoHide() }) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size + 22, height: size + 22)
                #if os(iOS)
                .openFlixGlassRegular(in: Circle())
                #else
                .background(Color.black.opacity(0.55), in: Circle())
                #endif
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: (size + 22) / 2))
        .accessibilityLabel(label)
    }

    private func pillButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: { action(); scheduleAutoHide() }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            #if os(iOS)
            .openFlixGlassRegular(in: Capsule(), tint: Color.red.opacity(0.45))
            #else
            .background(Color.red.opacity(0.85), in: Capsule())
            #endif
        }
        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
    }

    // MARK: State

    private var currentBadge: String? {
        if currentMode == "startover" { return "FROM BEGINNING" }
        if item.isLive { return "LIVE" }
        return nil
    }

    private var badgeColor: Color {
        if currentMode == "startover" { return Color.white.opacity(0.25) }
        return Color.red
    }

    /// Subtitle under the title in the top glass card. Prefers
    /// "league · sport" when both are present, else item.subtitle, else
    /// the announced air time.
    private var topSubtitle: String? {
        let parts = [item.league, item.sport].compactMap { $0 }.filter { !$0.isEmpty }
        if !parts.isEmpty { return parts.joined(separator: " · ") }
        if let s = item.subtitle, !s.isEmpty, s != item.title { return s }
        return item.startTime
    }

    private struct StreamInfoChip { let label: String; let value: String }

    /// What the iOS stream-info HUD shows: resolution, video codec, audio
    /// codec (e.g. EAC3 5.1). Falls back to "—" if VLC hasn't reported a
    /// value yet. VLC populates these from the actual stream once at
    /// least one frame has been decoded.
    private var streamInfoChips: [StreamInfoChip] {
        let info = vlcPlayer.streamInfo
        let res: String = {
            if let label = info?.resolutionLabel { return label }
            if let w = info?.videoWidth, let h = info?.videoHeight, w > 0 && h > 0 {
                return "\(w)x\(h)"
            }
            return "—"
        }()
        let video = info?.videoCodec?.uppercased() ?? "—"
        let audio: String = {
            guard let codec = info?.audioCodec, !codec.isEmpty else { return "—" }
            // EAC3 5.1 / AC3 Stereo / AAC Stereo / etc. — channel layout
            // comes from VLC's tracksInformation audio-channels field.
            if let layout = info?.audioChannelsLabel {
                return "\(codec.uppercased()) \(layout)"
            }
            return codec.uppercased()
        }()
        return [
            StreamInfoChip(label: "RESOLUTION", value: res),
            StreamInfoChip(label: "VIDEO", value: video),
            StreamInfoChip(label: "AUDIO", value: audio)
        ]
    }

    /// 0–1 progress against the event's startTime/endTime. Nil when those
    /// aren't known.
    private var liveProgress: Double? {
        guard let start = item.startTimeDate else { return nil }
        let endDate: Date = {
            if let endStr = item.endTime,
               let parsed = ISO8601DateFormatter().date(from: endStr) {
                return parsed
            }
            // No end → assume 3h window so the bar still tracks live.
            return start.addingTimeInterval(3 * 3600)
        }()
        let total = endDate.timeIntervalSince(start)
        guard total > 0 else { return nil }
        let elapsed = nowTick.timeIntervalSince(start)
        return elapsed / total
    }

    private var elapsedLabel: String {
        guard let start = item.startTimeDate else { return "" }
        return formatDuration(max(0, nowTick.timeIntervalSince(start)))
    }

    private var remainingLabel: String {
        guard let start = item.startTimeDate else { return "" }
        let endDate: Date = {
            if let endStr = item.endTime,
               let parsed = ISO8601DateFormatter().date(from: endStr) {
                return parsed
            }
            return start.addingTimeInterval(3 * 3600)
        }()
        let remaining = endDate.timeIntervalSince(nowTick)
        if remaining <= 0 { return "ENDED" }
        return "-" + formatDuration(remaining)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    /// Glass spinner shown while the stream is initially buffering or
    /// recovering from a stall. Includes a tiny status message + stall
    /// counter so the user knows the player is actively retrying.
    private var bufferingHUD: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.3)
                .tint(.white)
            Text(bufferingMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            if stallRecoveries > 0 {
                Text("Reconnecting (\(stallRecoveries))…")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        #if os(iOS)
        .openFlixGlassRegular(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        #else
        .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        #endif
    }

    private var bufferingMessage: String {
        if !vlcPlayer.isPlaying && vlcPlayer.isLoading { return "Loading stream…" }
        if vlcPlayer.isBuffering { return "Buffering…" }
        return "Connecting…"
    }

    private func play(mode: String?) async {
        do {
            let url = try await repo.playbackURL(for: item, in: container, mode: mode)
            currentMode = mode
            resolveError = nil
            stallRecoveries = 0
            bufferStartedAt = nil
            vlcPlayer.play(url: url)
        } catch {
            resolveError = error.localizedDescription
        }
    }

    /// Watchdog that runs whenever the player ENTERS buffering. If we
    /// stay buffering for >8 seconds without ever reaching playing, or
    /// playback drops to stopped without user intent, re-resolve the URL
    /// and tell VLC to try again. ESPN's HLS feed can drop transiently
    /// when Disney rotates the manifest or auth refreshes; this keeps
    /// playback resilient.
    @MainActor
    private func stallWatchdog() async {
        guard vlcPlayer.isBuffering else {
            bufferStartedAt = nil
            return
        }
        bufferStartedAt = Date()
        try? await Task.sleep(nanoseconds: 8_000_000_000)
        // Still in the same buffer cycle?
        guard let started = bufferStartedAt,
              Date().timeIntervalSince(started) >= 8,
              vlcPlayer.isBuffering else { return }
        guard stallRecoveries < 3 else { return }
        stallRecoveries += 1
        await play(mode: currentMode)
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

    private func errorOverlay(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Playback unavailable")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(msg)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            Button("Close", action: onClose)
                .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 999))
                .padding(.top, 6)
        }
    }
}

// MARK: - ESPN Multi-view
//
// 2-up by default, can grow to 3 or 4 slots. The slot that has audio is
// indicated by a "speaker.wave.2.fill" badge; tap any slot to switch
// audio to it; tap the speaker badge to mute. Tap an empty slot to add a
// stream from the picker.

struct ESPNMultiviewView: View {
    let primaryItem: ESPNItem
    let primaryContainer: ESPNContainer?
    @ObservedObject var repo: ESPNRepository
    let onClose: () -> Void

    @State private var slots: [Slot]
    @State private var audioSlotIndex: Int = 0
    @State private var pickerSlotIndex: Int?

    init(primaryItem: ESPNItem, primaryContainer: ESPNContainer?, repo: ESPNRepository, onClose: @escaping () -> Void) {
        self.primaryItem = primaryItem
        self.primaryContainer = primaryContainer
        self.repo = repo
        self.onClose = onClose
        _slots = State(initialValue: [
            Slot(item: primaryItem, container: primaryContainer),
            Slot(item: nil, container: nil)
        ])
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let layout = layoutFor(slotCount: slots.count, in: geo.size)
                ZStack {
                    ForEach(Array(slots.enumerated()), id: \.offset) { idx, slot in
                        ESPNMultiviewSlot(
                            slot: slot,
                            isAudio: idx == audioSlotIndex,
                            repo: repo,
                            onTapAudio: { audioSlotIndex = idx },
                            onChange: { pickerSlotIndex = idx }
                        )
                        .frame(width: layout[idx].width, height: layout[idx].height)
                        .position(x: layout[idx].midX, y: layout[idx].midY)
                    }
                }
            }
            .ignoresSafeArea()

            // Header
            HStack(spacing: 10) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        #if os(iOS)
                        .openFlixGlassRegular(in: Circle())
                        #else
                        .background(Color.black.opacity(0.55), in: Circle())
                        #endif
                }
                .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 22))

                Text("Multi-view")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    #if os(iOS)
                    .openFlixGlassRegular(in: Capsule())
                    #else
                    .background(Color.black.opacity(0.55), in: Capsule())
                    #endif

                Spacer()

                Picker("Layout", selection: Binding(
                    get: { slots.count },
                    set: { resize(to: $0) }
                )) {
                    Text("2-up").tag(2)
                    Text("3-up").tag(3)
                    Text("4-up").tag(4)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
                .tint(.white)
            }
            .padding(18)
        }
        .sheet(item: Binding(
            get: { pickerSlotIndex.map { SlotIndex(value: $0) } },
            set: { pickerSlotIndex = $0?.value }
        )) { slot in
            ESPNStreamPickerSheet(
                repo: repo,
                onPick: { item, container in
                    slots[slot.value] = Slot(item: item, container: container)
                    pickerSlotIndex = nil
                },
                onCancel: { pickerSlotIndex = nil }
            )
        }
        .onAppear { repo.beginPlayback() }
        .onDisappear { repo.endPlayback() }
    }

    private func resize(to count: Int) {
        let clamped = max(2, min(count, 4))
        if clamped > slots.count {
            slots.append(contentsOf: (slots.count..<clamped).map { _ in Slot(item: nil, container: nil) })
        } else if clamped < slots.count {
            slots = Array(slots.prefix(clamped))
            if audioSlotIndex >= clamped { audioSlotIndex = 0 }
        }
    }

    /// Compute slot rects for `slotCount` in a screen of `size`.
    private func layoutFor(slotCount: Int, in size: CGSize) -> [CGRect] {
        switch slotCount {
        case 2:
            // Side-by-side
            let w = size.width / 2
            return [
                CGRect(x: 0, y: 0, width: w, height: size.height),
                CGRect(x: w, y: 0, width: w, height: size.height)
            ]
        case 3:
            // Big left, two stacked right
            let leftW = size.width * 0.6
            let rightW = size.width - leftW
            let rightH = size.height / 2
            return [
                CGRect(x: 0, y: 0, width: leftW, height: size.height),
                CGRect(x: leftW, y: 0, width: rightW, height: rightH),
                CGRect(x: leftW, y: rightH, width: rightW, height: rightH)
            ]
        case 4:
            // 2x2
            let w = size.width / 2
            let h = size.height / 2
            return [
                CGRect(x: 0, y: 0, width: w, height: h),
                CGRect(x: w, y: 0, width: w, height: h),
                CGRect(x: 0, y: h, width: w, height: h),
                CGRect(x: w, y: h, width: w, height: h)
            ]
        default:
            return []
        }
    }

    struct Slot {
        var item: ESPNItem?
        var container: ESPNContainer?
    }
}

private struct SlotIndex: Identifiable {
    let value: Int
    var id: Int { value }
}

// MARK: - Multi-view slot

private struct ESPNMultiviewSlot: View {
    let slot: ESPNMultiviewView.Slot
    let isAudio: Bool
    @ObservedObject var repo: ESPNRepository
    let onTapAudio: () -> Void
    let onChange: () -> Void

    @StateObject private var player = VLCPlayerViewModel()
    @State private var resolveError: String?

    var body: some View {
        ZStack {
            Color.black

            if slot.item != nil {
                VLCPlayerView(viewModel: player)
                    .allowsHitTesting(false)
            } else {
                Button(action: onChange) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 38, weight: .light))
                        Text("Add stream")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            // Bottom overlay: title + audio/change controls
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    if let title = slot.item?.title {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            #if os(iOS)
                            .openFlixGlass(in: Capsule())
                            #else
                            .background(Color.black.opacity(0.55), in: Capsule())
                            #endif
                    }

                    Spacer()

                    if slot.item != nil {
                        Button(action: onTapAudio) {
                            Image(systemName: isAudio ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isAudio ? Color.white : .white.opacity(0.45))
                                .frame(width: 28, height: 28)
                                #if os(iOS)
                                .openFlixGlass(in: Circle())
                                #else
                                .background(Color.black.opacity(0.55), in: Circle())
                                #endif
                        }
                        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 14))

                        Button(action: onChange) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                #if os(iOS)
                                .openFlixGlass(in: Circle())
                                #else
                                .background(Color.black.opacity(0.55), in: Circle())
                                #endif
                        }
                        .buttonStyle(OFFocusableButtonStyle(prominent: true, cornerRadius: 14))
                    }
                }
                .padding(8)
            }

            if let resolveError {
                Text(resolveError)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.orange)
                    .padding(8)
            }
        }
        .clipped()
        .task(id: slot.item?.id) {
            await loadPlayback()
        }
        .onChange(of: isAudio) { _, audio in
            #if !targetEnvironment(simulator)
            player.mediaPlayer.audio?.volume = audio ? 100 : 0
            #endif
        }
        .onDisappear {
            player.stop()
        }
    }

    private func loadPlayback() async {
        player.stop()
        guard let item = slot.item else { return }
        do {
            let url = try await repo.playbackURL(for: item, in: slot.container, mode: nil)
            player.play(url: url)
            #if !targetEnvironment(simulator)
            // Mute non-audio slots immediately on play.
            player.mediaPlayer.audio?.volume = isAudio ? 100 : 0
            #endif
            resolveError = nil
        } catch {
            resolveError = error.localizedDescription
        }
    }
}

// MARK: - Stream picker

private struct ESPNStreamPickerSheet: View {
    @ObservedObject var repo: ESPNRepository
    let onPick: (ESPNItem, ESPNContainer?) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if let containers = repo.hub?.containers {
                        ForEach(containers) { container in
                            if let items = repo.setItems[container.id], !items.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(container.title ?? "")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                                        ForEach(items) { item in
                                            if item.playback?.resourceId != nil && !item.isUpcoming {
                                                Button {
                                                    onPick(item, container)
                                                } label: {
                                                    pickerCard(item: item)
                                                }
                                                .buttonStyle(OFFocusableButtonStyle(cornerRadius: 10))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    } else {
                        ProgressView().padding(40)
                    }
                }
                .padding(.vertical, 12)
            }
            .navigationTitle("Pick a stream")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel", action: onCancel)
                }
                #endif
            }
        }
    }

    private func pickerCard(item: ESPNItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topLeading) {
                if let urlString = item.bestImageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        default: Color.gray.opacity(0.2)
                        }
                    }
                } else {
                    LinearGradient(colors: [.red.opacity(0.6), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
                if item.isLive {
                    Text("LIVE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red, in: Capsule())
                        .padding(5)
                }
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(item.title ?? "")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}
