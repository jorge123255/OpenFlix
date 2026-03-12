import SwiftUI

// MARK: - Modern EPG Grid View
// Channels DVR-inspired design with glass effects and smooth animations

struct EPGGridViewModern: View {
    @ObservedObject var viewModel: LiveTVViewModel
    let onChannelSelect: (Channel) -> Void
    let onProgramSelect: (Program, Channel) -> Void
    
    // State
    @State private var horizontalScrollOffset: CGFloat = 0
    @State private var showProgramDetail = false
    @State private var selectedProgram: Program?
    @State private var selectedChannelForDetail: Channel?
    @State private var showMiniPlayer = true
    @State private var showQuickNav = true
    @State private var recordingToast: String?
    @State private var showRecordingToast = false
    @State private var showGuideSearch = false

    private let dvrRepository = DVRRepository()
    
    // Focus
    @FocusState private var focusedSection: EPGSection?
    
    enum EPGSection: Hashable {
        case quickNav
        case categories
        case grid
    }
    
    // Layout constants - optimized for iPhone
    private let channelColumnWidth: CGFloat = 80
    private let timeSlotWidth: CGFloat = 150
    private let rowHeight: CGFloat = 70
    private let headerHeight: CGFloat = 40
    
    var body: some View {
        ZStack {
            // Background
            EPGTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Quick Navigation Bar
                if showQuickNav {
                    EPGQuickNavBar(
                        onJumpToNow: scrollToNow,
                        onJumpToPrimetime: scrollToPrimetime,
                        onShowCategories: { /* toggle filter */ },
                        onMyTeams: { /* show my teams */ },
                        onSearch: { showGuideSearch = true }
                    )
                    .focused($focusedSection, equals: .quickNav)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Category tabs
                ModernCategoryTabs(
                    categories: viewModel.availableGroups,
                    selectedCategory: $viewModel.selectedGroup
                )
                .focused($focusedSection, equals: .categories)
                
                // Main EPG Grid
                GeometryReader { geometry in
                    ZStack(alignment: .topTrailing) {
                        mainGrid(screenWidth: geometry.size.width)
                        
                        // Mini player overlay (top-right)
                        if showMiniPlayer, let currentChannel = viewModel.selectedChannel {
                            NowPlayingMiniCard(
                                channel: currentChannel,
                                program: currentChannel.nowPlaying,
                                onTap: {
                                    onChannelSelect(currentChannel)
                                }
                            )
                            .padding(20)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                }
                .focused($focusedSection, equals: .grid)
            }
            
            // Now line indicator (vertical)
            nowLineOverlay
        }
        .animation(.spring(response: 0.4), value: showQuickNav)
        .animation(.spring(response: 0.4), value: showMiniPlayer)
        .sheet(isPresented: $showProgramDetail) {
            if let program = selectedProgram, let channel = selectedChannelForDetail {
                ModernProgramDetailSheet(
                    program: program,
                    channel: channel,
                    onPlay: {
                        showProgramDetail = false
                        onChannelSelect(channel)
                    },
                    onRecord: {
                        showProgramDetail = false
                        recordProgram(program, channel: channel)
                    },
                    onCreatePass: { options in
                        showProgramDetail = false
                        createSeriesPass(program, channel: channel, options: options)
                    },
                    onDismiss: {
                        showProgramDetail = false
                    }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .overlay(alignment: .top) {
            if showRecordingToast, let message = recordingToast {
                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.9))
                    .cornerRadius(8)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showRecordingToast)
        .sheet(isPresented: $showGuideSearch) {
            EPGSearchView(
                viewModel: viewModel,
                isPresented: $showGuideSearch,
                onChannelSelect: onChannelSelect,
                onProgramSelect: { program, channel in
                    selectedProgram = program
                    selectedChannelForDetail = channel
                    showProgramDetail = true
                }
            )
        }
    }
    
    // MARK: - Main Grid
    
    private func mainGrid(screenWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Fixed header row
            headerRow(screenWidth: screenWidth)
            
            // Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(filteredGuide) { channelWithPrograms in
                        epgRow(for: channelWithPrograms, screenWidth: screenWidth)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Row
    
    private func headerRow(screenWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Corner cell with channel count
            cornerCell
            
            // Time slots
            ScrollView(.horizontal, showsIndicators: false) {
                EPGTimeHeaderModern(
                    timeSlots: timeSlots,
                    timeSlotWidth: timeSlotWidth,
                    headerHeight: headerHeight
                )
            }
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.8))
        )
    }
    
    private var cornerCell: some View {
        VStack(spacing: 2) {
            Image(systemName: "tv")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(EPGTheme.accent)
            
            Text("\(filteredGuide.count) CH")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(EPGTheme.textSecondary)
        }
        .frame(width: channelColumnWidth, height: headerHeight)
        .background(EPGTheme.surface.opacity(0.95))
    }
    
    // MARK: - EPG Row
    
    private func epgRow(for channelWithPrograms: ChannelWithPrograms, screenWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Channel cell
            EPGChannelCellModern(
                channel: channelWithPrograms.channel,
                height: rowHeight,
                isPlaying: viewModel.selectedChannel?.id == channelWithPrograms.channel.id,
                onSelect: {
                    onChannelSelect(channelWithPrograms.channel)
                }
            )
            .frame(width: channelColumnWidth)
            .background(EPGTheme.surface.opacity(0.7))
            
            // Programs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(visiblePrograms(for: channelWithPrograms)) { program in
                        let width = programWidth(for: program)
                        
                        EPGProgramCellModern(
                            program: program,
                            channel: channelWithPrograms.channel,
                            width: width,
                            height: rowHeight - 4,
                            onSelect: {
                                selectedProgram = program
                                selectedChannelForDetail = channelWithPrograms.channel
                                showProgramDetail = true
                            }
                        )
                        .contextMenu {
                            Button {
                                selectedProgram = program
                                selectedChannelForDetail = channelWithPrograms.channel
                                showProgramDetail = true
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }

                            Button {
                                onChannelSelect(channelWithPrograms.channel)
                            } label: {
                                Label("Watch Now", systemImage: "play.fill")
                            }

                            if !program.hasRecording && !program.hasEnded {
                                Button {
                                    recordProgram(program, channel: channelWithPrograms.channel)
                                } label: {
                                    Label("Record", systemImage: "record.circle")
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: CGFloat(timeSlots.count) * timeSlotWidth)
                }
                .padding(.vertical, 2)
            }
        }
        .frame(height: rowHeight)
    }
    
    // MARK: - Now Line Overlay
    
    @ViewBuilder
    private var nowLineOverlay: some View {
        GeometryReader { geometry in
            let now = Date()
            let xOffset = calculateNowLineOffset()
            
            if xOffset > channelColumnWidth && xOffset < geometry.size.width {
                VStack(spacing: 0) {
                    // Triangle marker at top
                    Triangle()
                        .fill(Color.red)
                        .frame(width: 12, height: 8)
                    
                    // Vertical line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                }
                .offset(x: xOffset - 1)
                .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var filteredGuide: [ChannelWithPrograms] {
        guard let selectedGroup = viewModel.selectedGroup else {
            return viewModel.guide
        }
        return viewModel.guide.filter { $0.channel.group == selectedGroup }
    }
    
    private var timeSlots: [Date] {
        let calendar = Calendar.current
        let now = Date()
        
        var startOfHour = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: now))!
        let minute = calendar.component(.minute, from: now)
        if minute >= 30 {
            startOfHour = calendar.date(byAdding: .minute, value: 30, to: startOfHour)!
        }
        startOfHour = calendar.date(byAdding: .minute, value: -30, to: startOfHour)!
        
        return (0..<12).compactMap { i in
            calendar.date(byAdding: .minute, value: i * 30, to: startOfHour)
        }
    }
    
    private func visiblePrograms(for channelWithPrograms: ChannelWithPrograms) -> [Program] {
        guard let firstSlot = timeSlots.first,
              let lastSlot = timeSlots.last else {
            return channelWithPrograms.programs
        }
        
        let endTime = Calendar.current.date(byAdding: .minute, value: 30, to: lastSlot) ?? lastSlot
        
        return channelWithPrograms.programs.filter { program in
            program.endTime > firstSlot && program.startTime < endTime
        }
    }
    
    private func programWidth(for program: Program) -> CGFloat {
        let durationMinutes = program.endTime.timeIntervalSince(program.startTime) / 60.0
        let width = CGFloat(durationMinutes / 30.0) * timeSlotWidth
        return max(width, 100)
    }
    
    private func calculateNowLineOffset() -> CGFloat {
        guard let firstSlot = timeSlots.first else { return 0 }
        let now = Date()
        let minutesSinceStart = now.timeIntervalSince(firstSlot) / 60.0
        return channelColumnWidth + CGFloat(minutesSinceStart / 30.0) * timeSlotWidth
    }
    
    private func scrollToNow() {
        // Would scroll horizontally to current time
    }
    
    private func scrollToPrimetime() {
        // Would scroll to 8pm (primetime)
    }

    private func recordProgram(_ program: Program, channel: Channel) {
        Task {
            do {
                _ = try await dvrRepository.recordProgram(channelId: channel.id, programId: program.id)
                recordingToast = "Recording: \(program.title)"
                showRecordingToast = true
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showRecordingToast = false
            } catch {
                recordingToast = "Record failed: \(error.localizedDescription)"
                showRecordingToast = true
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showRecordingToast = false
            }
        }
    }

    private func createSeriesPass(_ program: Program, channel: Channel, options: SeriesPassOptions) {
        Task {
            do {
                let channelId = options.channelMode == .thisChannel ? channel.id : nil
                try await dvrRepository.createSeriesRule(
                    title: program.title,
                    channelId: channelId,
                    prePadding: options.startRecording.seconds,
                    postPadding: options.endRecording.seconds,
                    keepCount: options.keepMode.keepCount
                )
                recordingToast = "Series Pass created: \(program.title)"
                showRecordingToast = true
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showRecordingToast = false
            } catch {
                recordingToast = "Pass failed: \(error.localizedDescription)"
                showRecordingToast = true
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                showRecordingToast = false
            }
        }
    }
}

// MARK: - Modern Category Tabs

struct ModernCategoryTabs: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All Channels
                categoryTab(title: "All Channels", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                
                // Favorites
                categoryTab(title: "⭐ Favorites", isSelected: false) {
                    // Filter to favorites
                }
                
                // Categories
                ForEach(categories, id: \.self) { category in
                    categoryTab(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial.opacity(0.3))
    }
    
    private func categoryTab(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? EPGTheme.accent : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modern Program Detail Sheet
