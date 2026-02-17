import SwiftUI
import AVKit

// MARK: - Multiview V2 - Simplified Controls
/// Navigation is SEPARATE from channel changing:
/// - D-pad: Move between slots
/// - Click/OK: Open channel picker
/// - Play/Pause remote: Toggle audio slot
/// - Menu: Exit

struct MultiviewPlayerV2: View {
    @StateObject private var viewModel = MultiviewViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedSlot: Int?
    
    let initialChannelIds: [String]
    let onFullScreen: (Channel) -> Void
    
    // UI State
    @State private var showControls = true
    @State private var showChannelPicker = false
    @State private var pickerSlotIndex = 0
    @State private var swapMode = false
    @State private var swapSourceSlot = -1
    @State private var controlsTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Main grid
                multiviewGrid(geometry: geometry)
                
                // Help bar (top)
                if showControls && !showChannelPicker {
                    VStack {
                        helpBar
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Layout indicator (bottom-left)
                if showControls && !showChannelPicker {
                    VStack {
                        Spacer()
                        HStack {
                            layoutIndicator
                            Spacer()
                        }
                        .padding(40)
                    }
                }
                
                // Channel picker overlay
                if showChannelPicker {
                    channelPickerOverlay
                }
            }
            .onAppear {
                viewModel.initialize(with: initialChannelIds)
                focusedSlot = 0
                resetControlsTimer()
            }
            .onChange(of: focusedSlot) { _ in
                resetControlsTimer()
            }
            .onExitCommand {
                if showChannelPicker {
                    showChannelPicker = false
                } else if swapMode {
                    swapMode = false
                    swapSourceSlot = -1
                } else {
                    dismiss()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showControls)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: focusedSlot)
    }
    
    // MARK: - Grid Layout
    
    @ViewBuilder
    private func multiviewGrid(geometry: GeometryProxy) -> some View {
        let layout = viewModel.layout
        let slots = viewModel.slots
        
        switch layout {
        case .single:
            if let slot = slots.first {
                slotView(slot: slot, index: 0, size: geometry.size)
            }
            
        case .twoByOne:
            HStack(spacing: 6) {
                ForEach(Array(slots.prefix(2).enumerated()), id: \.offset) { index, slot in
                    slotView(slot: slot, index: index, size: CGSize(
                        width: (geometry.size.width - 6) / 2,
                        height: geometry.size.height
                    ))
                }
            }
            
        case .oneByTwo:
            VStack(spacing: 6) {
                ForEach(Array(slots.prefix(2).enumerated()), id: \.offset) { index, slot in
                    slotView(slot: slot, index: index, size: CGSize(
                        width: geometry.size.width,
                        height: (geometry.size.height - 6) / 2
                    ))
                }
            }
            
        case .threeGrid:
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(Array(slots.prefix(2).enumerated()), id: \.offset) { index, slot in
                        slotView(slot: slot, index: index, size: CGSize(
                            width: (geometry.size.width - 6) / 2,
                            height: (geometry.size.height - 6) / 2
                        ))
                    }
                }
                if slots.count > 2 {
                    slotView(slot: slots[2], index: 2, size: CGSize(
                        width: geometry.size.width,
                        height: (geometry.size.height - 6) / 2
                    ))
                }
            }
            
        case .twoByTwo:
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(Array(slots.prefix(2).enumerated()), id: \.offset) { index, slot in
                        slotView(slot: slot, index: index, size: CGSize(
                            width: (geometry.size.width - 6) / 2,
                            height: (geometry.size.height - 6) / 2
                        ))
                    }
                }
                HStack(spacing: 6) {
                    ForEach(Array(slots.dropFirst(2).prefix(2).enumerated()), id: \.offset) { index, slot in
                        let actualIndex = index + 2
                        slotView(slot: slot, index: actualIndex, size: CGSize(
                            width: (geometry.size.width - 6) / 2,
                            height: (geometry.size.height - 6) / 2
                        ))
                    }
                }
            }
        }
    }
    
    // MARK: - Slot View
    
    @ViewBuilder
    private func slotView(slot: MultiviewSlot, index: Int, size: CGSize) -> some View {
        let isFocused = focusedSlot == index
        let isSwapSource = swapMode && swapSourceSlot == index
        let isSwapTarget = swapMode && swapSourceSlot != index && isFocused
        
        ZStack {
            // Video player
            if let player = slot.player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(white: 0.1))
                    .overlay(loadingIndicator)
            }
            
            // Swap mode overlays
            if isSwapSource {
                Color.teal.opacity(0.25)
                Text("SOURCE")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.teal)
                    .cornerRadius(8)
            }
            
            if isSwapTarget {
                Text("SWAP HERE")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow)
                    .cornerRadius(8)
            }
            
            // Slot number badge (top-left)
            VStack {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isFocused ? Color.teal : Color.black.opacity(0.7))
                            .frame(width: 36, height: 36)
                        
                        Text("\(index + 1)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(isFocused ? .black : .white)
                    }
                    .padding(12)
                    Spacer()
                }
                Spacer()
            }
            
            // Audio indicator (top-right)
            if !slot.isMuted {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 12))
                            Text("AUDIO")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(4)
                        .padding(12)
                    }
                    Spacer()
                }
            }
            
            // Channel info (bottom)
            if showControls || isFocused {
                VStack {
                    Spacer()
                    channelInfoBar(slot: slot, index: index)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? Color.teal : (isSwapSource ? Color.teal : Color.clear),
                    lineWidth: isFocused || isSwapSource ? 4 : 0
                )
        )
        .scaleEffect(isFocused ? 1.0 : 0.98)
        .focusable()
        .focused($focusedSlot, equals: index)
        .onTapGesture {
            // Single tap = channel picker
            if swapMode {
                if swapSourceSlot != index {
                    viewModel.swapSlots(swapSourceSlot, index)
                }
                swapMode = false
                swapSourceSlot = -1
            } else {
                pickerSlotIndex = index
                showChannelPicker = true
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Long press = swap mode OR fullscreen
            if !swapMode {
                swapMode = true
                swapSourceSlot = index
            }
        }
    }
    
    // MARK: - Channel Info Bar
    
    @ViewBuilder
    private func channelInfoBar(slot: MultiviewSlot, index: Int) -> some View {
        HStack(spacing: 12) {
            // Logo
            if let logoUrl = slot.channel.logoUrl, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 44, height: 44)
                .cornerRadius(6)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                    Text(slot.channel.number ?? "\(index + 1)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            
            // Channel info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let number = slot.channel.number {
                        Text(number)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.teal)
                    }
                    Text(slot.channel.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                if let program = slot.channel.nowPlaying {
                    Text(program.title)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Live badge
            Text(slot.isTimeshifted ? "DVR" : "LIVE")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(slot.isTimeshifted ? Color.purple : Color.red)
                .cornerRadius(4)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Help Bar
    
    private var helpBar: some View {
        HStack(spacing: 24) {
            if swapMode {
                Text("🔄 SWAP MODE - Select target slot")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.teal)
            } else {
                helpItem(icon: "⬆⬇⬅➡", text: "Navigate", highlight: false)
                helpItem(icon: "Click", text: "Change Ch", highlight: true)
                helpItem(icon: "Long Press", text: "Swap", highlight: false)
                helpItem(icon: "Play/Pause", text: "Audio", highlight: false)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.85), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    @ViewBuilder
    private func helpItem(icon: String, text: String, highlight: Bool) -> some View {
        HStack(spacing: 6) {
            Text(icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(highlight ? .black : .white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(highlight ? Color.teal : Color.gray.opacity(0.4))
                .cornerRadius(4)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Layout Indicator
    
    private var layoutIndicator: some View {
        Button {
            viewModel.cycleLayout()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Text(viewModel.layout.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("L")
                    .font(.system(size: 10))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Channel Picker
    
    private var channelPickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Select Channel")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(viewModel.allChannels.count) channels")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                
                // Channel grid
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.allChannels) { channel in
                            channelRow(channel: channel)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                
                // Cancel button
                HStack {
                    Spacer()
                    Button("Cancel") {
                        showChannelPicker = false
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                }
                .padding(20)
            }
            .frame(maxWidth: 700, maxHeight: .infinity)
            .background(Color(white: 0.12))
            .cornerRadius(16)
            .padding(60)
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func channelRow(channel: Channel) -> some View {
        let currentChannel = viewModel.slots[safe: pickerSlotIndex]?.channel
        let isSelected = channel.id == currentChannel?.id
        
        Button {
            viewModel.setChannel(channel, forSlot: pickerSlotIndex)
            showChannelPicker = false
        } label: {
            HStack(spacing: 12) {
                // Logo
                if let logoUrl = channel.logoUrl, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 48, height: 48)
                    .cornerRadius(6)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 48, height: 48)
                        Image(systemName: "tv")
                            .foregroundColor(.gray)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        if let number = channel.number {
                            Text(number)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.teal)
                        }
                        Text(channel.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    if let program = channel.nowPlaying {
                        Text(program.title)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.teal)
                        .font(.system(size: 20))
                }
            }
            .padding(12)
            .background(isSelected ? Color.teal.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Loading Indicator
    
    private var loadingIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.teal)
                    .frame(width: 10, height: 10)
                    .opacity(0.3)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(i) * 0.15),
                        value: true
                    )
            }
        }
    }
    
    // MARK: - Timer

    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        showControls = true
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            withAnimation {
                showControls = false
            }
        }
    }
}
