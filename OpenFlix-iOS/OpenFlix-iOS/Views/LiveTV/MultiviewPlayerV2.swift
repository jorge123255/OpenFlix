import SwiftUI

// MARK: - Multiview Layout

enum MultiviewLayout: CaseIterable {
    case side      // 2 side by side
    case stacked   // 2 top/bottom
    case quad      // 2×2 four screens

    var icon: String {
        switch self {
        case .side:    return "rectangle.split.2x1"
        case .stacked: return "rectangle.split.1x2"
        case .quad:    return "rectangle.split.2x2"
        }
    }

    var label: String {
        switch self {
        case .side:    return "Side by Side"
        case .stacked: return "Stacked"
        case .quad:    return "Quad"
        }
    }

    var shortLabel: String {
        switch self {
        case .side:    return "Side"
        case .stacked: return "Stack"
        case .quad:    return "Quad"
        }
    }

    var slotCount: Int {
        switch self {
        case .side, .stacked: return 2
        case .quad:           return 4
        }
    }
}

// MARK: - Multiview

struct MultiviewPlayerV2: View {
    let initialChannel: Channel
    let viewModel: LiveTVViewModel
    let onDismiss: () -> Void
    let onFullScreen: (Channel) -> Void

    @AppStorage("multiviewOnboardingSeen") private var onboardingSeen = false

    @State private var layout: MultiviewLayout = .side
    @State private var slots: [MultiviewSlot] = []
    @State private var audioSlot: Int = 0
    @State private var showPicker = false
    @State private var pickerSlot = 0
    @State private var showHUD = true
    @State private var hudTimer: Timer?
    @State private var showOnboarding = false
    @State private var allMuted = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                playerGrid(geo: geo)

                if showHUD {
                    hud
                        .transition(.opacity)
                }

                if showOnboarding {
                    multiviewOnboarding
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showHUD)
            .animation(.easeInOut(duration: 0.25), value: showOnboarding)
        }
        .ignoresSafeArea()
        .onAppear {
            setupSlots()
            if !onboardingSeen {
                // Brief delay so the grid is visible behind the overlay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showOnboarding = true
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            ChannelPickerSheet(
                channels: viewModel.channels,
                current: slots[safe: pickerSlot]?.channel,
                onSelect: { replaceChannel($0, inSlot: pickerSlot) }
            )
        }
    }

    // MARK: - Grid

    @ViewBuilder
    private func playerGrid(geo: GeometryProxy) -> some View {
        ZStack(alignment: .topLeading) {
            Color.black

            ForEach(0..<4, id: \.self) { index in
                let frame = slotFrame(index: index, in: geo)
                let visible = isSlotVisible(index)

                Group {
                    if index < slots.count {
                        slotView(index, frame.size)
                    } else {
                        ZStack {
                            Color(white: 0.08)
                            ProgressView().tint(Color(white: 0.5))
                        }
                        .frame(width: frame.width, height: frame.height)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .position(x: frame.midX, y: frame.midY)
                .opacity(visible ? 1 : 0)
                .allowsHitTesting(visible)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: layout)
    }

    private func isSlotVisible(_ index: Int) -> Bool {
        switch layout {
        case .side, .stacked: return index < 2
        case .quad:           return true
        }
    }

    /// Returns the CGRect (in the full-screen ZStack coordinate space) for a given slot index.
    private func slotFrame(index: Int, in geo: GeometryProxy) -> CGRect {
        let w = geo.size.width
        let h = geo.size.height
        let gap: CGFloat = 3
        let isPortrait = h > w
        // In portrait, pin grid just below the HUD (safe area top + button row ≈ 140pt)
        let portraitTop: CGFloat = geo.safeAreaInsets.top + 88

        switch layout {
        case .side:
            let cw = (w - gap) / 2
            let ch: CGFloat = isPortrait ? cw * (9.0 / 16.0) : h
            // Portrait: center the row in the available space below the HUD
            let yOff: CGFloat = isPortrait ? portraitTop + (h - portraitTop - ch) / 2 : 0
            let xOff: CGFloat = index == 0 ? 0 : cw + gap
            return CGRect(x: xOff, y: yOff, width: cw, height: ch)

        case .stacked:
            let ch: CGFloat = isPortrait ? w * (9.0 / 16.0) : (h - gap) / 2
            let yOff: CGFloat = isPortrait ? portraitTop : 0
            let rowY: CGFloat = index == 0 ? yOff : yOff + ch + gap
            return CGRect(x: 0, y: rowY, width: w, height: ch)

        case .quad:
            let cw = (w - gap) / 2
            let ch: CGFloat = isPortrait ? cw * (9.0 / 16.0) : (h - gap) / 2
            let totalH = 2 * ch + gap
            // Portrait: center the 2×2 grid in the available space below the HUD
            let yOff: CGFloat = isPortrait ? portraitTop + (h - portraitTop - totalH) / 2 : 0
            let col = CGFloat(index % 2)
            let row = CGFloat(index / 2)
            return CGRect(
                x: col * (cw + gap),
                y: yOff + row * (ch + gap),
                width: cw, height: ch
            )
        }
    }

    @ViewBuilder
    private func slotView(_ index: Int, _ size: CGSize) -> some View {
        let slot = slots[index]
        let isAudio = audioSlot == index

        ZStack(alignment: .bottom) {
            VLCPlayerView(viewModel: slot.playerVM)
                .frame(width: size.width, height: size.height)
                .clipped()
                .allowsHitTesting(false)
                .onAppear { startSlot(slot, index: index) }

            // Audio border glow
            if isAudio {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.85), lineWidth: 2)
                    .frame(width: size.width, height: size.height)
                    .allowsHitTesting(false)
            }

            // Info strip
            infoStrip(slot: slot, index: index, isAudio: isAudio, compact: size.width < 250)
                .allowsHitTesting(false)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        // Single tap → switch audio focus
        .onTapGesture {
            switchAudio(to: index)
            UISelectionFeedbackGenerator().selectionChanged()
            bumpHUD()
        }
        // Double-tap → fullscreen (simultaneous keeps single tap instant)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                cleanupPlayers()
                onFullScreen(slot.channel)
            }
        )
        // Long press → open channel picker
        .onLongPressGesture(minimumDuration: 0.5) {
            pickerSlot = index
            showPicker = true
            bumpHUD()
        }
    }

    private func startSlot(_ slot: MultiviewSlot, index: Int) {
        guard !slot.hasStarted else { return }
        slot.hasStarted = true
        // Stagger per index so VLC has a settled frame for each drawable
        let delay = 0.1 + Double(index) * 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if let url = URL(string: slot.channel.streamUrl ?? "") {
                slot.playerVM.play(url: url)
            }
        }
    }

    // MARK: - Info Strip

    private func infoStrip(slot: MultiviewSlot, index: Int, isAudio: Bool, compact: Bool) -> some View {
        HStack(spacing: 6) {
            // Logo
            AuthenticatedImage(path: slot.channel.logo, systemPlaceholder: "tv")
                .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                .cornerRadius(4)

            if !compact {
                VStack(alignment: .leading, spacing: 0) {
                    Text(slot.channel.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if let prog = slot.channel.nowPlaying {
                        Text(prog.title)
                            .font(.system(size: 9))
                            .foregroundColor(Color(white: 0.65))
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)

            // Audio badge
            Image(systemName: isAudio ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: compact ? 9 : 10, weight: .semibold))
                .foregroundColor(isAudio ? .white : Color(white: 0.5))
        }
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 5 : 7)
        .background(.ultraThinMaterial)
    }

    // MARK: - HUD

    private var hud: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack(spacing: 0) {
                // Close button
                Button {
                    cleanupPlayers()
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)

                // Mute all toggle
                Button {
                    toggleMuteAll()
                    bumpHUD()
                } label: {
                    Image(systemName: allMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(allMuted ? .orange : .white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)

                Spacer()

                // Layout picker — segmented pill
                layoutPicker

                Spacer()

                // Hint badge
                Text("Tap: audio  ·  Hold: change  ·  2× fullscreen")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(white: 0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 54)   // clear Dynamic Island / notch
            .padding(.bottom, 20)
            .background(
                LinearGradient(
                    colors: [Color.black.opacity(0.55), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )

            Spacer()
                .allowsHitTesting(false)
        }
    }

    // MARK: - First-Launch Onboarding Overlay

    private var multiviewOnboarding: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { dismissOnboarding() }

            VStack(spacing: 0) {
                // Title
                Text("Multiview Controls")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 6)

                Text("Here's how to control each screen")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.65))
                    .padding(.bottom, 28)

                // Gesture rows
                VStack(spacing: 16) {
                    onboardingRow(icon: "hand.point.up.left.fill",  color: .white,
                                  gesture: "Tap",         desc: "Switch audio to that screen")
                    onboardingRow(icon: "hand.point.up.left",       color: Color(white: 0.7),
                                  gesture: "Hold",        desc: "Change the channel in that slot")
                    onboardingRow(icon: "arrow.up.left.and.arrow.down.right", color: .blue,
                                  gesture: "Double tap",  desc: "Open that channel fullscreen")
                    onboardingRow(icon: "xmark.circle.fill",        color: .red,
                                  gesture: "X button",   desc: "Close multiview, resume original")
                }
                .padding(.bottom, 32)

                Button {
                    dismissOnboarding()
                } label: {
                    Text("Got it")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 36)
        }
    }

    private func onboardingRow(icon: String, color: Color, gesture: String, desc: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(gesture)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.6))
            }
            Spacer()
        }
    }

    private func dismissOnboarding() {
        withAnimation { showOnboarding = false }
        onboardingSeen = true
    }

    private var layoutPicker: some View {
        HStack(spacing: 2) {
            ForEach(MultiviewLayout.allCases, id: \.label) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        switchLayout(to: option)
                    }
                    bumpHUD()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: option.icon)
                            .font(.system(size: 13, weight: .medium))
                        if layout == option {
                            Text(option.shortLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                                .transition(.opacity.combined(with: .scale(scale: 0.85)))
                        }
                    }
                    .foregroundColor(layout == option ? .black : Color(white: 0.7))
                    .padding(.horizontal, layout == option ? 12 : 10)
                    .padding(.vertical, 8)
                    .background(
                        layout == option
                            ? AnyShapeStyle(Color.white)
                            : AnyShapeStyle(.ultraThinMaterial),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: layout)
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Setup & Helpers

    private func setupSlots() {
        let channels = viewModel.channels
        guard !channels.isEmpty else { return }

        // Pick 4 consecutive channels starting at initialChannel's position in the list
        let startIdx = channels.firstIndex(where: { $0.id == initialChannel.id }) ?? 0
        let picks: [Channel] = (0..<4).map { i in
            channels[(startIdx + i) % channels.count]
        }

        slots = picks.enumerated().map { i, ch in
            let vm = VLCPlayerViewModel()
            if i > 0 { setVolume(vm, 0) }
            return MultiviewSlot(channel: ch, playerVM: vm)
        }
        // play() is triggered by VLCPlayerView.onAppear after layout settles

        audioSlot = 0
        bumpHUD()
    }

    private func switchLayout(to newLayout: MultiviewLayout) {
        layout = newLayout
    }

    private func replaceChannel(_ channel: Channel, inSlot index: Int) {
        guard index < slots.count else { return }
        slots[index].playerVM.stop()
        slots[index].channel = channel
        slots[index].hasStarted = true  // prevent onAppear double-start on re-render
        if let url = URL(string: channel.streamUrl ?? "") {
            slots[index].playerVM.play(url: url)
        }
        setVolume(slots[index].playerVM, Int32(audioSlot == index ? 100 : 0))
    }

    private func switchAudio(to index: Int) {
        allMuted = false
        audioSlot = index
        for i in 0..<slots.count {
            setVolume(slots[i].playerVM, Int32(i == index ? 100 : 0))
        }
    }

    private func toggleMuteAll() {
        allMuted.toggle()
        for i in 0..<slots.count {
            setVolume(slots[i].playerVM, allMuted ? 0 : Int32(i == audioSlot ? 100 : 0))
        }
    }

    /// Set volume on a VLC media player (no-op on simulator where VLCKit is stripped)
    private func setVolume(_ player: VLCPlayerViewModel, _ volume: Int32) {
        #if !targetEnvironment(simulator)
        player.mediaPlayer.audio?.volume = volume
        #endif
    }

    private func cleanupPlayers() {
        slots.forEach { $0.playerVM.stop() }
    }

    private func bumpHUD() {
        withAnimation { showHUD = true }
        hudTimer?.invalidate()
        hudTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
            withAnimation { showHUD = false }
        }
    }
}

// MARK: - Slot Model

class MultiviewSlot: Identifiable {
    let id = UUID()
    var channel: Channel
    let playerVM: VLCPlayerViewModel
    var hasStarted = false

    init(channel: Channel, playerVM: VLCPlayerViewModel) {
        self.channel = channel
        self.playerVM = playerVM
    }
}

// MARK: - Channel Picker Sheet

struct ChannelPickerSheet: View {
    let channels: [Channel]
    let current: Channel?
    let onSelect: (Channel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var filtered: [Channel] {
        search.isEmpty ? channels : channels.filter {
            $0.name.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationView {
            List(filtered) { channel in
                Button {
                    onSelect(channel)
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        AuthenticatedImage(path: channel.logo, systemPlaceholder: "tv")
                            .frame(width: 44, height: 44)
                            .cornerRadius(8)
                            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                if let num = channel.number {
                                    Text(String(num))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                Text(channel.name)
                                    .font(.system(size: 15, weight: .medium))
                            }
                            if let prog = channel.nowPlaying {
                                Text(prog.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if channel.id == current?.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .searchable(text: $search, prompt: "Search channels")
            .navigationTitle("Choose Channel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
