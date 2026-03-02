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

struct ModernProgramDetailSheet: View {
    let program: Program
    let channel: Channel
    let onPlay: () -> Void
    let onRecord: () -> Void
    let onCreatePass: (SeriesPassOptions) -> Void
    let onDismiss: () -> Void

    @State private var showRecordConfirmation = false
    @State private var showRecordOptions = false
    @State private var showSeriesPass = false

    private let darkBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Thumbnail + title side by side
                        programHeader

                        // Duration + time + channel
                        HStack(spacing: 6) {
                            Text("\(program.duration) min")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text(program.startTimeFormatted)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text(channel.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(accentPurple)
                        }

                        // Badge pills
                        HStack(spacing: 6) {
                            ForEach(program.badges, id: \.self) { badge in
                                XfinityBadgePill(badge, color: accentPurple)
                            }
                            if let rating = program.rating, !rating.isEmpty {
                                XfinityBadgePill(rating, color: Color.white.opacity(0.15))
                            }
                            if let category = program.category, !category.isEmpty {
                                XfinityBadgePill(category, color: Color.white.opacity(0.15))
                            }
                        }

                        // Description
                        if let desc = program.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Progress (if currently airing)
                        if program.isCurrentlyAiring {
                            VStack(alignment: .leading, spacing: 4) {
                                ProgressView(value: program.progress)
                                    .tint(accentPurple)
                                HStack {
                                    Text("\(Int(program.progress * 100))% complete")
                                    Spacer()
                                    Text("\(program.remainingMinutes) min remaining")
                                }
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            }
                        }

                        // Sports metadata
                        if program.isSports {
                            if let teams = program.teams {
                                detailRow("Teams", value: teams)
                            }
                            if let league = program.league {
                                detailRow("League", value: league)
                            }
                        }
                    }
                    .padding(20)
                }

                // Bottom action buttons: Watch, Record, Pass
                HStack(spacing: 12) {
                    Button(action: onPlay) {
                        Label("Watch", systemImage: "tv")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    if !program.hasRecording && !program.hasEnded {
                        Button { showRecordConfirmation = true } label: {
                            Label("Record", systemImage: "record.circle")
                                .font(.system(size: 15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button { showSeriesPass = true } label: {
                        Label("Pass", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(darkBg)
            }
        }
        .confirmationDialog("Record", isPresented: $showRecordConfirmation, titleVisibility: .visible) {
            Button("Record") { onRecord() }
            Button("Record with Options") { showRecordOptions = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showRecordOptions) {
            RecordWithOptionsSheet(
                program: program,
                channel: channel,
                onRecord: { paddingEnd in
                    showRecordOptions = false
                    onRecord()
                },
                onDismiss: { showRecordOptions = false }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSeriesPass) {
            SeriesPassSheet(
                program: program,
                channel: channel,
                onCreate: { options in
                    showSeriesPass = false
                    onCreatePass(options)
                },
                onDismiss: { showSeriesPass = false }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var programHeader: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                if let art = program.art ?? program.icon {
                    AuthenticatedImage(path: art, systemPlaceholder: program.isSports ? "sportscourt" : "tv")
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [EPGTheme.categoryColor(for: program.category), .black.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: program.isSports ? "sportscourt" : "tv")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.4))
                        )
                }
            }
            .frame(width: 160, height: 90)
            .clipped()
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(program.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                if let subtitle = program.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }

                Text(shortDate(program.startTime))
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.gray).frame(width: 80, alignment: .leading)
            Text(value).foregroundColor(.white.opacity(0.9))
        }
        .font(.system(size: 13))
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Series Pass Options
struct SeriesPassOptions {
    var recordMode: RecordMode = .newEpisodes
    var keepMode: KeepMode = .allRecordings
    var startRecording: PaddingOption = .onTime
    var endRecording: PaddingOption = .onTime
    var channelMode: ChannelMode = .anyChannel

    enum RecordMode: String, CaseIterable {
        case newEpisodes = "New Episodes"
        case allEpisodes = "All Episodes"
    }

    enum KeepMode: String, CaseIterable {
        case allRecordings = "All recordings"
        case keep1 = "1 day"
        case keep2 = "2 days"
        case keep3 = "3 days"
        case keep5 = "5 days"
        case keep7 = "7 days"
        case keep10 = "10 days"
        case afterWatch = "After I watch, delete"

        var keepCount: Int {
            switch self {
            case .allRecordings: return 0
            case .keep1: return 1
            case .keep2: return 2
            case .keep3: return 3
            case .keep5: return 5
            case .keep7: return 7
            case .keep10: return 10
            case .afterWatch: return -1
            }
        }
    }

    enum PaddingOption: String, CaseIterable {
        case onTime = "On Time"
        case early1 = "1 min early"
        case early5 = "5 min early"
        case early15 = "15 min early"
        case late5 = "5 min late"
        case late15 = "15 min late"
        case late30 = "30 min late"
        case late60 = "1 hr late"

        var seconds: Int {
            switch self {
            case .onTime: return 0
            case .early1: return 60
            case .early5: return 300
            case .early15: return 900
            case .late5: return 300
            case .late15: return 900
            case .late30: return 1800
            case .late60: return 3600
            }
        }

        static var startOptions: [PaddingOption] { [.onTime, .early1, .early5, .early15] }
        static var endOptions: [PaddingOption] { [.onTime, .late5, .late15, .late30, .late60] }
    }

    enum ChannelMode: String, CaseIterable {
        case anyChannel = "Any Channel"
        case thisChannel = "This Channel"
    }
}

// MARK: - Record with Options Sheet
struct RecordWithOptionsSheet: View {
    let program: Program
    let channel: Channel
    let onRecord: (Int) -> Void  // padding end seconds
    let onDismiss: () -> Void

    @State private var endPadding: SeriesPassOptions.PaddingOption = .onTime

    private let darkBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Program artwork (wider)
                        ZStack {
                            if let art = program.art ?? program.icon {
                                AuthenticatedImage(path: art, systemPlaceholder: "tv")
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(
                                        colors: [EPGTheme.categoryColor(for: program.category), .black.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .overlay(
                                        Image(systemName: "tv")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.4))
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(10)

                        // Title
                        Text(program.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        // Date + episode
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shortDate(program.startTime))
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.8))
                            if let subtitle = program.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }

                        // End padding picker
                        HStack {
                            Text("End")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Picker("End", selection: $endPadding) {
                                ForEach(SeriesPassOptions.PaddingOption.endOptions, id: \.self) { opt in
                                    Text(opt.rawValue).tag(opt)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accentPurple)
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(10)
                    }
                    .padding(20)
                }

                // Record button
                Button { onRecord(endPadding.seconds) } label: {
                    Label("Record", systemImage: "clock")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(accentPurple.opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Series Pass Sheet
struct SeriesPassSheet: View {
    let program: Program
    let channel: Channel
    let onCreate: (SeriesPassOptions) -> Void
    let onDismiss: () -> Void

    @State private var options = SeriesPassOptions()

    private let darkBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let rowBg = Color.white.opacity(0.06)

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Title
                VStack(spacing: 4) {
                    Text("Series Pass")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Text(program.title)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 1) {
                        // Record mode
                        optionRow("Record") {
                            Picker("Record", selection: $options.recordMode) {
                                ForEach(SeriesPassOptions.RecordMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accentPurple)
                        }

                        // Keep
                        optionRow("Keep") {
                            Picker("Keep", selection: $options.keepMode) {
                                ForEach(SeriesPassOptions.KeepMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accentPurple)
                        }

                        // Start Recording
                        optionRow("Start Recording") {
                            Picker("Start", selection: $options.startRecording) {
                                ForEach(SeriesPassOptions.PaddingOption.startOptions, id: \.self) { opt in
                                    Text(opt.rawValue).tag(opt)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accentPurple)
                        }

                        // End Recording
                        optionRow("End Recording") {
                            Picker("End", selection: $options.endRecording) {
                                ForEach(SeriesPassOptions.PaddingOption.endOptions, id: \.self) { opt in
                                    Text(opt.rawValue).tag(opt)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(accentPurple)
                        }

                        // Channel Number
                        optionRow("Channel Number") {
                            Picker("Channel", selection: $options.channelMode) {
                                Text("Any Channel").tag(SeriesPassOptions.ChannelMode.anyChannel)
                                Text(channel.name).tag(SeriesPassOptions.ChannelMode.thisChannel)
                            }
                            .pickerStyle(.menu)
                            .tint(accentPurple)
                        }
                    }
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }

                // Create Pass button
                Button { onCreate(options) } label: {
                    Label("Create Pass", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .background(accentPurple.opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
    }

    @ViewBuilder
    private func optionRow<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(rowBg)
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
