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
    
    // Focus
    @FocusState private var focusedSection: EPGSection?
    
    enum EPGSection: Hashable {
        case quickNav
        case categories
        case grid
    }
    
    // Layout constants
    private let channelColumnWidth: CGFloat = 260
    private let timeSlotWidth: CGFloat = 320
    private let rowHeight: CGFloat = 100
    private let headerHeight: CGFloat = 50
    
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
                        onSearch: { /* show search */ }
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
                        // Schedule recording
                    },
                    onDismiss: {
                        showProgramDetail = false
                    }
                )
            }
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
                                onChannelSelect(channelWithPrograms.channel)
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
                                    // Record
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

struct ModernProgramDetailSheet: View {
    let program: Program
    let channel: Channel
    let onPlay: () -> Void
    let onRecord: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with artwork
                        headerSection
                        
                        // Description
                        if let description = program.description {
                            Text(description)
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(5)
                        }
                        
                        // Metadata grid
                        metadataSection
                        
                        // Action buttons
                        actionButtons
                    }
                    .padding(40)
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 24) {
            // Program art placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [EPGTheme.categoryColor(for: program.category), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 120)
                .overlay(
                    Image(systemName: program.isSports ? "sportscourt" : "tv")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                )
            
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(program.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                // Subtitle
                if let subtitle = program.subtitle {
                    Text(subtitle)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Channel and time
                HStack(spacing: 12) {
                    Text(channel.name)
                        .foregroundColor(EPGTheme.accent)
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text(program.timeRangeFormatted)
                        .foregroundColor(.white.opacity(0.7))
                }
                .font(.system(size: 16))
                
                // Badges
                HStack(spacing: 8) {
                    ForEach(program.badges, id: \.self) { badge in
                        Text(badge)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(EPGTheme.accent)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if program.isCurrentlyAiring {
                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    EPGProgressBar(progress: program.progress, height: 8)
                    
                    HStack {
                        Text("\(Int(program.progress * 100))% complete")
                        Spacer()
                        Text("\(program.remainingMinutes) min remaining")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Info grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let rating = program.rating {
                    metadataItem(label: "Rating", value: rating)
                }
                
                metadataItem(label: "Duration", value: "\(program.duration) min")
                
                if let category = program.category {
                    metadataItem(label: "Category", value: category)
                }
                
                if program.isSports, let teams = program.teams {
                    metadataItem(label: "Teams", value: teams)
                }
                
                if program.isSports, let league = program.league {
                    metadataItem(label: "League", value: league)
                }
            }
        }
    }
    
    private func metadataItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            // Play button
            Button(action: onPlay) {
                HStack {
                    Image(systemName: "play.fill")
                    Text(program.isCurrentlyAiring ? "Watch Live" : "Watch")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // Record button
            if !program.hasRecording && !program.hasEnded {
                Button(action: onRecord) {
                    HStack {
                        Image(systemName: "record.circle")
                        Text("Record")
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    EPGGridViewModern(
        viewModel: LiveTVViewModel(),
        onChannelSelect: { _ in },
        onProgramSelect: { _, _ in }
    )
}
