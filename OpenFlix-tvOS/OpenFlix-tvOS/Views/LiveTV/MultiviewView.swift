import SwiftUI
import AVKit

// MARK: - Multiview Colors

private struct MultiviewColors {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.06)
    static let surface = Color(red: 0.1, green: 0.1, blue: 0.14)
    static let surfaceLight = Color(red: 0.16, green: 0.16, blue: 0.22)
    static let accent = Color(red: 0.0, green: 0.85, blue: 1.0)
    static let accentGlow = Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.3)
    static let accentRed = Color(red: 1.0, green: 0.23, blue: 0.36)
    static let accentGreen = Color(red: 0.06, green: 0.73, blue: 0.51)
    static let accentGold = Color(red: 1.0, green: 0.72, blue: 0.0)
    static let accentPurple = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textMuted = Color(white: 0.44)
    static let focusBorder = Color(red: 0.0, green: 0.85, blue: 1.0)
}

// MARK: - Multiview View

struct MultiviewView: View {
    let initialChannelIds: [String]
    let onBack: () -> Void
    let onFullScreen: (Channel) -> Void

    @StateObject private var viewModel = MultiviewViewModel()
    @FocusState private var focusedElement: FocusableElement?

    enum FocusableElement: Hashable {
        case slot(Int)
        case actionButton(Int)
    }

    var body: some View {
        ZStack {
            MultiviewColors.background
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if viewModel.slots.isEmpty {
                Text("No channels available")
                    .foregroundColor(MultiviewColors.textSecondary)
            } else {
                VStack(spacing: 0) {
                    // Main grid
                    multiviewGrid
                        .padding(.horizontal, 48)
                        .padding(.top, 48)

                    Spacer()

                    // Bottom action bar
                    if viewModel.showControls {
                        actionBar
                            .padding(.horizontal, 48)
                            .padding(.bottom, 48)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }

            // Channel picker overlay
            if let slotIndex = viewModel.channelPickerSlotIndex {
                channelPickerOverlay(for: slotIndex)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadChannels()
                viewModel.initializeSlots(initialChannelIds: initialChannelIds)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .onExitCommand {
            if viewModel.channelPickerSlotIndex != nil {
                viewModel.hideChannelPicker()
            } else {
                onBack()
            }
        }
        .onMoveCommand { direction in
            handleMoveCommand(direction)
        }
        .onPlayPauseCommand {
            // Toggle pause on focused slot (DVR feature!)
            viewModel.togglePauseSlot(viewModel.focusedSlotIndex)
        }
        .focusable()
        // P key - Pause/Resume ALL streams
        .onKeyPress("p") {
            if viewModel.anySlotPaused {
                viewModel.resumeAll()
            } else {
                viewModel.pauseAll()
            }
            return .handled
        }
        // L key - Jump all to LIVE
        .onKeyPress("l") {
            viewModel.jumpAllToLive()
            return .handled
        }
        // S key - SYNC all streams
        .onKeyPress("s") {
            viewModel.syncAllStreams()
            return .handled
        }
        // Left arrow - Rewind focused slot
        .onKeyPress(.leftArrow) {
            viewModel.rewindSlot(viewModel.focusedSlotIndex, seconds: 15)
            return .handled
        }
        // Right arrow - Forward focused slot
        .onKeyPress(.rightArrow) {
            viewModel.fastForwardSlot(viewModel.focusedSlotIndex, seconds: 15)
            return .handled
        }
        // M key - Toggle mute (audio focus)
        .onKeyPress("m") {
            viewModel.toggleMuteOnSlot(viewModel.focusedSlotIndex)
            return .handled
        }
    }

    // MARK: - Grid Layout

    @ViewBuilder
    private var multiviewGrid: some View {
        switch viewModel.layout {
        case .single:
            if let slot = viewModel.slots.first {
                slotView(slot, isFocused: viewModel.focusedSlotIndex == 0)
            }

        case .twoByOne:
            HStack(spacing: 8) {
                ForEach(viewModel.slots.prefix(2)) { slot in
                    slotView(slot, isFocused: viewModel.focusedSlotIndex == slot.index)
                }
            }

        case .oneByTwo:
            VStack(spacing: 8) {
                ForEach(viewModel.slots.prefix(2)) { slot in
                    slotView(slot, isFocused: viewModel.focusedSlotIndex == slot.index)
                }
            }

        case .threeGrid:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(viewModel.slots.prefix(2)) { slot in
                        slotView(slot, isFocused: viewModel.focusedSlotIndex == slot.index)
                    }
                }
                if viewModel.slots.count > 2 {
                    slotView(viewModel.slots[2], isFocused: viewModel.focusedSlotIndex == 2)
                }
            }

        case .twoByTwo:
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(viewModel.slots.prefix(2)) { slot in
                        slotView(slot, isFocused: viewModel.focusedSlotIndex == slot.index)
                    }
                }
                HStack(spacing: 8) {
                    ForEach(viewModel.slots.dropFirst(2).prefix(2)) { slot in
                        slotView(slot, isFocused: viewModel.focusedSlotIndex == slot.index)
                    }
                }
            }
        }
    }

    // MARK: - Slot View

    @ViewBuilder
    private func slotView(_ slot: MultiviewSlot, isFocused: Bool) -> some View {
        ZStack {
            // Video player
            if let player = slot.player {
                VideoPlayer(player: player)
                    .disabled(true)
            } else {
                Rectangle()
                    .fill(MultiviewColors.surface)
            }

            // Focus border
            if isFocused {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MultiviewColors.focusBorder, lineWidth: 4)
            }

            // Info overlay
            if viewModel.showControls || isFocused {
                VStack {
                    Spacer()
                    slotInfoOverlay(slot)
                }
            }

            // Slot number badge
            VStack {
                HStack {
                    slotNumberBadge(slot.index + 1, isFocused: isFocused)
                    Spacer()
                }
                Spacer()
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .focusable()
        .focused($focusedElement, equals: .slot(slot.index))
        .onTapGesture {
            viewModel.setFocusedSlot(slot.index)
        }
    }

    private func slotInfoOverlay(_ slot: MultiviewSlot) -> some View {
        HStack {
            // Channel logo
            if let logoUrl = slot.channel.logo, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle().fill(MultiviewColors.surface)
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let number = slot.channel.number {
                        Text("\(number)")
                            .font(.headline)
                            .foregroundColor(MultiviewColors.accent)
                    }
                    Text(slot.channel.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                if let program = slot.channel.nowPlaying {
                    Text(program.title)
                        .font(.subheadline)
                        .foregroundColor(MultiviewColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Status badges
            HStack(spacing: 8) {
                // Audio indicator
                if !slot.isMuted {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(MultiviewColors.accentGreen)
                        .font(.caption)
                        .padding(6)
                        .background(MultiviewColors.accentGreen.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                // Paused indicator - DVR feature!
                if slot.dvrState.isPaused {
                    HStack(spacing: 4) {
                        Image(systemName: "pause.fill")
                        Text("PAUSED")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MultiviewColors.accentGold)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                // Time offset indicator (when behind live)
                if !slot.dvrState.isLive && slot.dvrState.liveOffsetSecs > 0 {
                    Text("-\(formatOffset(slot.dvrState.liveOffsetSecs))")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(MultiviewColors.accentPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                // Live/Start Over badge
                let statusText = slot.dvrState.isLive ? "LIVE" : (slot.isTimeshifted ? "START OVER" : "DVR")
                let statusColor = slot.dvrState.isLive ? MultiviewColors.accentRed : MultiviewColors.accentPurple
                Text(statusText)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func slotNumberBadge(_ number: Int, isFocused: Bool) -> some View {
        Text("\(number)")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(isFocused ? .black : .white)
            .frame(width: 32, height: 32)
            .background(isFocused ? MultiviewColors.accent : Color.black.opacity(0.7))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(isFocused ? Color.white : .clear, lineWidth: 2)
            )
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: 16) {
            // Hint text
            Text("D-Pad: Navigate  |  Play: Toggle Audio  |  Select: Fullscreen  |  P: Pause All")
                .font(.caption)
                .foregroundColor(MultiviewColors.textMuted)

            // Action buttons - two rows for DVR controls
            VStack(spacing: 12) {
                // Row 1: Navigation and layout
                HStack(spacing: 16) {
                    actionButton(icon: "arrow.left", label: "Back", color: MultiviewColors.textSecondary) {
                        onBack()
                    }

                    actionButton(icon: "arrow.up.left.and.arrow.down.right", label: "Fullscreen", color: MultiviewColors.accent) {
                        if let slot = viewModel.slots[safe: viewModel.focusedSlotIndex] {
                            onFullScreen(slot.channel)
                        }
                    }

                    actionButton(icon: viewModel.layout.icon, label: viewModel.layout.rawValue, color: MultiviewColors.textSecondary) {
                        viewModel.cycleLayout()
                    }

                    if viewModel.slots.count < 4 {
                        actionButton(icon: "plus", label: "Add", color: MultiviewColors.accentGreen) {
                            viewModel.addSlot()
                        }
                    }

                    if viewModel.slots.count > 1 {
                        actionButton(icon: "minus", label: "Remove", color: MultiviewColors.accentRed) {
                            viewModel.removeSlot(viewModel.focusedSlotIndex)
                        }
                    }

                    actionButton(icon: "arrow.left.arrow.right", label: "Swap", color: MultiviewColors.textSecondary) {
                        viewModel.showChannelPicker(for: viewModel.focusedSlotIndex)
                    }

                    let focusedSlot = viewModel.slots[safe: viewModel.focusedSlotIndex]
                    let isMuted = focusedSlot?.isMuted ?? true
                    actionButton(
                        icon: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                        label: isMuted ? "Unmute" : "Mute",
                        color: isMuted ? MultiviewColors.textSecondary : MultiviewColors.accentGreen
                    ) {
                        viewModel.toggleMuteOnSlot(viewModel.focusedSlotIndex)
                    }
                }

                // Row 2: DVR Controls - Our killer feature vs Channels DVR!
                HStack(spacing: 16) {
                    // Pause/Resume focused slot
                    let focusedSlot = viewModel.slots[safe: viewModel.focusedSlotIndex]
                    let isPaused = focusedSlot?.dvrState.isPaused ?? false

                    actionButton(
                        icon: isPaused ? "play.fill" : "pause.fill",
                        label: isPaused ? "Resume" : "Pause",
                        color: isPaused ? MultiviewColors.accentGreen : MultiviewColors.accentGold
                    ) {
                        viewModel.togglePauseSlot(viewModel.focusedSlotIndex)
                    }

                    // Rewind 15s
                    actionButton(icon: "gobackward.15", label: "-15s", color: MultiviewColors.textSecondary) {
                        viewModel.rewindSlot(viewModel.focusedSlotIndex, seconds: 15)
                    }

                    // Forward 15s
                    actionButton(icon: "goforward.15", label: "+15s", color: MultiviewColors.textSecondary) {
                        viewModel.fastForwardSlot(viewModel.focusedSlotIndex, seconds: 15)
                    }

                    // Jump to Live
                    let isLive = focusedSlot?.dvrState.isLive ?? true
                    actionButton(
                        icon: "antenna.radiowaves.left.and.right",
                        label: isLive ? "LIVE" : "Go Live",
                        color: isLive ? MultiviewColors.accentRed : MultiviewColors.accentGold
                    ) {
                        viewModel.jumpToLiveSlot(viewModel.focusedSlotIndex)
                    }

                    Divider()
                        .frame(height: 30)
                        .background(MultiviewColors.textMuted)

                    // PAUSE ALL - one button for everything!
                    actionButton(
                        icon: viewModel.anySlotPaused ? "play.circle.fill" : "pause.circle.fill",
                        label: viewModel.anySlotPaused ? "Play All" : "Pause All",
                        color: MultiviewColors.accentPurple
                    ) {
                        if viewModel.anySlotPaused {
                            viewModel.resumeAll()
                        } else {
                            viewModel.pauseAll()
                        }
                    }

                    // SYNC ALL - align all streams
                    actionButton(icon: "arrow.triangle.2.circlepath", label: "Sync All", color: MultiviewColors.accent) {
                        viewModel.syncAllStreams()
                    }

                    // LIVE ALL - jump all to live
                    actionButton(
                        icon: "livephoto",
                        label: "All Live",
                        color: viewModel.allSlotsLive ? MultiviewColors.textMuted : MultiviewColors.accentGold
                    ) {
                        viewModel.jumpAllToLive()
                    }
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(color)
            .frame(width: 80, height: 60)
            .background(MultiviewColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Channel Picker

    private func channelPickerOverlay(for slotIndex: Int) -> some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Select Channel")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.allChannels) { channel in
                            channelPickerRow(channel, isSelected: viewModel.slots[safe: slotIndex]?.channel.id == channel.id)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: 600, maxHeight: 500)
                .background(MultiviewColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button("Cancel") {
                    viewModel.hideChannelPicker()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func channelPickerRow(_ channel: Channel, isSelected: Bool) -> some View {
        Button {
            if let slotIndex = viewModel.channelPickerSlotIndex {
                viewModel.swapChannel(slotIndex, newChannel: channel)
            }
            viewModel.hideChannelPicker()
        } label: {
            HStack {
                // Channel logo
                if let logoUrl = channel.logo, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle().fill(MultiviewColors.surfaceLight)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading) {
                    HStack {
                        if let number = channel.number {
                            Text("\(number)")
                                .foregroundColor(MultiviewColors.accent)
                                .fontWeight(.bold)
                        }
                        Text(channel.name)
                            .foregroundColor(.white)
                    }

                    if let program = channel.nowPlaying {
                        Text(program.title)
                            .font(.caption)
                            .foregroundColor(MultiviewColors.textSecondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(MultiviewColors.accent)
                }
            }
            .padding(12)
            .background(isSelected ? MultiviewColors.accent.opacity(0.2) : MultiviewColors.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Navigation

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        viewModel.showControlsTemporarily()

        let currentSlot = viewModel.focusedSlotIndex
        let slotCount = viewModel.slots.count

        // 2x2 grid navigation
        let is2x2 = viewModel.layout == .twoByTwo && slotCount == 4
        let isThreeGrid = viewModel.layout == .threeGrid && slotCount >= 3

        switch direction {
        case .up:
            if is2x2 {
                if currentSlot >= 2 {
                    viewModel.setFocusedSlot(currentSlot - 2)
                } else {
                    viewModel.changeChannelInSlot(currentSlot, direction: -1)
                }
            } else if isThreeGrid && currentSlot == 2 {
                viewModel.setFocusedSlot(0)
            } else {
                viewModel.changeChannelInSlot(currentSlot, direction: -1)
            }

        case .down:
            if is2x2 {
                if currentSlot < 2 {
                    viewModel.setFocusedSlot(currentSlot + 2)
                } else {
                    viewModel.changeChannelInSlot(currentSlot, direction: 1)
                }
            } else if isThreeGrid && currentSlot < 2 {
                viewModel.setFocusedSlot(2)
            } else {
                viewModel.changeChannelInSlot(currentSlot, direction: 1)
            }

        case .left:
            if is2x2 {
                if currentSlot == 1 {
                    viewModel.setFocusedSlot(0)
                } else if currentSlot == 3 {
                    viewModel.setFocusedSlot(2)
                }
            } else if currentSlot > 0 {
                viewModel.setFocusedSlot(currentSlot - 1)
            }

        case .right:
            if is2x2 {
                if currentSlot == 0 {
                    viewModel.setFocusedSlot(1)
                } else if currentSlot == 2 {
                    viewModel.setFocusedSlot(3)
                }
            } else if currentSlot < slotCount - 1 {
                viewModel.setFocusedSlot(currentSlot + 1)
            }

        @unknown default:
            break
        }
    }

    // MARK: - Helpers

    /// Format time offset for display (e.g., "2:30" for 150 seconds)
    private func formatOffset(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        } else {
            return "\(secs)s"
        }
    }
}

// MARK: - Preview

#Preview {
    MultiviewView(
        initialChannelIds: [],
        onBack: {},
        onFullScreen: { _ in }
    )
}
