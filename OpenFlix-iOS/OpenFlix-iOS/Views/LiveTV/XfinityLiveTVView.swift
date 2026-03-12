import SwiftUI

// Atomic context passed to the program detail sheet — prevents grey-screen race condition
private struct ProgramDetailContext: Identifiable {
    let id = UUID()
    let program: Program
    let channel: Channel
}

// MARK: - Xfinity-Style Live TV View (Simple List)

struct XfinityLiveTVView: View {
    @StateObject private var viewModel = LiveTVViewModel()
    @State private var selectedFilter: ChannelFilter = .all
    @State private var selectedChannel: Channel?
    @State private var viewingTime: Date = Date()
    @State private var programOffset: CGFloat = 0
    @State private var programDetail: ProgramDetailContext?
    @State private var recordingToast: String?
    @State private var showRecordingToast = false
    @State private var showSearch = false
    @State private var channelOrder: [String] = UserDefaults.standard.stringArray(forKey: "epg_channel_order") ?? []
    private let dvrRepository = DVRRepository()

    // Channels sorted by saved order, with unordered ones appended at end
    private func applyOrder(_ channels: [Channel]) -> [Channel] {
        guard !channelOrder.isEmpty else { return channels }
        var ordered: [Channel] = []
        for id in channelOrder {
            if let ch = channels.first(where: { $0.id == id }) { ordered.append(ch) }
        }
        let remaining = channels.filter { !channelOrder.contains($0.id) }
        return ordered + remaining
    }

    private func saveOrder(_ channels: [Channel]) {
        channelOrder = channels.map(\.id)
        UserDefaults.standard.set(channelOrder, forKey: "epg_channel_order")
    }

    enum ChannelFilter: String, CaseIterable {
        case all = "All channels"
        case favorites = "Favorites"
        case sports = "Sports"
        case news = "News"
        case movies = "Movies"
        case kids = "Kids"

        var shortLabel: String {
            switch self {
            case .all: return "All"
            case .favorites: return "Favorites"
            case .sports: return "Sports"
            case .news: return "News"
            case .movies: return "Movies"
            case .kids: return "Kids"
            }
        }

        var icon: String? {
            switch self {
            case .all: return nil
            case .favorites: return "star.fill"
            case .sports: return "sportscourt.fill"
            case .news: return "newspaper.fill"
            case .movies: return "film.fill"
            case .kids: return "figure.child"
            }
        }
    }
    
    // Xfinity colors
    private let bgColor = Color(red: 17/255, green: 12/255, blue: 33/255)
    private let accentPurple = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let cardBg = Color(red: 26/255, green: 20/255, blue: 46/255)
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar
            
            // Time header
            timeHeader
            
            // Channel list
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            } else if filteredChannels.isEmpty {
                emptyState
            } else {
                channelList
            }
        }
        .background(bgColor.ignoresSafeArea())
        .navigationTitle(selectedFilter.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSearch) {
            EPGSearchView(
                viewModel: viewModel,
                isPresented: $showSearch,
                onChannelSelect: { channel in
                    showSearch = false
                    selectedChannel = channel
                },
                onProgramSelect: { program, channel in
                    showSearch = false
                    programDetail = ProgramDetailContext(program: program, channel: channel)
                }
            )
        }
        .sheet(item: $programDetail) { ctx in
            ModernProgramDetailSheet(
                program: ctx.program,
                channel: ctx.channel,
                onPlay: {
                    programDetail = nil
                    selectedChannel = ctx.channel
                },
                onRecord: {
                    programDetail = nil
                    recordProgram(ctx.program, channel: ctx.channel)
                },
                onCreatePass: { options in
                    programDetail = nil
                    createSeriesPass(ctx.program, channel: ctx.channel, options: options)
                },
                onDismiss: {
                    programDetail = nil
                }
            )
            .presentationDetents([.medium, .large])
            .presentationBackground(Color(red: 26/255, green: 20/255, blue: 46/255))
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
                    .animation(.easeInOut, value: showRecordingToast)
            }
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            LiveChannelPlayerView(
                channel: channel,
                viewModel: viewModel,
                channels: filteredChannels
            ) {
                selectedChannel = nil
            }
        }
        .task {
            await viewModel.loadChannels()
            await viewModel.loadGuide()
        }
        .refreshable {
            await viewModel.loadChannels()
            await viewModel.loadGuide()
        }
    }
    
    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Filter menu
                Menu {
                    ForEach(ChannelFilter.allCases, id: \.self) { filter in
                        Button {
                            selectedFilter = filter
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedFilter.rawValue)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(cardBg)
                    .cornerRadius(8)
                }

                Spacer()

                // Search button
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(cardBg)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // 7-day date strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(dateStripDays, id: \.self) { date in
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: viewingTime)
                        Button {
                            viewingTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
                            Task {
                                await viewModel.loadGuideForDate(date)
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(dayStripLabel(for: date))
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? .white : .gray)
                                    .multilineTextAlignment(.center)

                                Circle()
                                    .fill(hasProgramData(for: date) ? accentPurple : Color.clear)
                                    .frame(width: 6, height: 6)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? cardBg : Color.clear)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
    }

    private var dateStripDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (-1...5).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }

    private func dayStripLabel(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE\nd"
        return formatter.string(from: date)
    }

    private func hasProgramData(for date: Date) -> Bool {
        let start = Calendar.current.startOfDay(for: date)
        let end = start.addingTimeInterval(86400)
        return viewModel.guide.contains { cwp in
            cwp.programs.contains { $0.startTime >= start && $0.startTime < end }
        }
    }
    
    // MARK: - Time Header

    private var timeHeader: some View {
        HStack(spacing: 0) {
            // Channel column spacer
            Color.clear
                .frame(width: 140)

            // Back arrow
            Button {
                viewingTime = viewingTime.addingTimeInterval(-30 * 60)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28)
            }

            // Time slots
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(timeSlots, id: \.self) { slot in
                        Text(slot)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: (geo.size.width) / CGFloat(timeSlots.count), alignment: .leading)
                    }
                }
            }

            // Forward arrow
            Button {
                viewingTime = viewingTime.addingTimeInterval(30 * 60)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28)
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 16)
        .background(bgColor)
    }

    private var timeSlots: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"

        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: viewingTime)
        let roundedMinute = (minute / 30) * 30
        guard let startTime = calendar.date(bySettingHour: calendar.component(.hour, from: viewingTime),
                                            minute: roundedMinute,
                                            second: 0,
                                            of: viewingTime) else {
            return []
        }

        return (0..<4).map { i in
            formatter.string(from: startTime.addingTimeInterval(TimeInterval(i * 30 * 60))).lowercased()
        }
    }
    
    // MARK: - Channel List

    private var channelList: some View {
        List {
            ForEach(filteredChannels) { channel in
                XfinityChannelRow(
                    channel: channel,
                    programs: programsForChannel(channel),
                    viewingTime: viewingTime,
                    programOffset: programOffset,
                    accentColor: accentPurple,
                    onChannelTap: { selectedChannel = channel },
                    onProgramTap: { program in
                        programDetail = ProgramDetailContext(program: program, channel: channel)
                    }
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(bgColor)
                .listRowSeparatorTint(Color.white.opacity(0.08))
            }
            .onMove { from, to in
                var current = filteredChannels
                current.move(fromOffsets: from, toOffset: to)
                // Only persist order when on "All channels" — other filters are temporary views
                if selectedFilter == .all {
                    saveOrder(current)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
        // Horizontal swipe on the list to shift time window
        .simultaneousGesture(
            DragGesture(minimumDistance: 40, coordinateSpace: .local)
                .onChanged { value in
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height) * 1.5
                    guard isHorizontal else { return }
                    programOffset = value.translation.width * 0.4
                }
                .onEnded { value in
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height) * 1.5
                    guard isHorizontal, abs(value.translation.width) > 40 else {
                        withAnimation(.easeOut(duration: 0.2)) { programOffset = 0 }
                        return
                    }
                    let step: TimeInterval = 2 * 60 * 60
                    let screenWidth = UIScreen.main.bounds.width
                    let forward = value.translation.width < 0
                    withAnimation(.easeIn(duration: 0.18)) {
                        programOffset = forward ? -screenWidth : screenWidth
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        viewingTime = snapToBlock(viewingTime.addingTimeInterval(forward ? step : -step))
                        programOffset = forward ? screenWidth : -screenWidth
                        withAnimation(.easeOut(duration: 0.22)) { programOffset = 0 }
                    }
                }
        )
    }

    private func snapToBlock(_ date: Date) -> Date {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let snapped = (hour / 2) * 2
        return cal.date(bySettingHour: snapped, minute: 0, second: 0, of: date) ?? date
    }

    private var filteredChannels: [Channel] {
        let base: [Channel]
        switch selectedFilter {
        case .all:      base = viewModel.channels
        case .favorites: base = viewModel.channels.filter { $0.isFavorite }
        case .sports:   base = viewModel.channels.filter { $0.group?.lowercased().contains("sport") ?? false }
        case .news:     base = viewModel.channels.filter { $0.group?.lowercased().contains("news") ?? false }
        case .movies:   base = viewModel.channels.filter { $0.group?.lowercased().contains("movie") ?? false }
        case .kids:     base = viewModel.channels.filter { $0.group?.lowercased().contains("kid") ?? false }
        }
        return applyOrder(base)
    }
    
    private func programsForChannel(_ channel: Channel) -> [Program] {
        viewModel.guide.first { $0.channel.id == channel.id }?.programs ?? []
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No channels available")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Check your server connection")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - DVR Actions

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

// MARK: - Channel Row

struct XfinityChannelRow: View {
    let channel: Channel
    let programs: [Program]
    let viewingTime: Date
    var programOffset: CGFloat = 0
    let accentColor: Color
    let onChannelTap: () -> Void
    let onProgramTap: (Program) -> Void

    private let rowHeight: CGFloat = 90
    private let channelColWidth: CGFloat = 80

    private func programAtTime(_ time: Date) -> Program? {
        programs.first { $0.startTime <= time && $0.endTime > time }
    }

    private var currentProgram: Program? { programAtTime(viewingTime) }

    private var nextProgram: Program? {
        guard let current = currentProgram else {
            return programs.first { $0.startTime >= viewingTime }
        }
        return programs.first { $0.startTime >= current.endTime }
    }

    private var progress: Double {
        guard let program = currentProgram else { return 0 }
        let total = program.endTime.timeIntervalSince(program.startTime)
        let elapsed = viewingTime.timeIntervalSince(program.startTime)
        return min(max(elapsed / total, 0), 1)
    }

    private var categoryColor: Color {
        guard let p = currentProgram else { return accentColor }
        if p.isSports { return Color(red: 0.2, green: 0.6, blue: 1.0) }
        if p.category?.lowercased().contains("movie") == true { return Color(red: 0.9, green: 0.5, blue: 0.1) }
        if p.category?.lowercased().contains("news") == true { return Color(red: 0.9, green: 0.2, blue: 0.2) }
        if p.isKids { return Color(red: 0.3, green: 0.85, blue: 0.4) }
        return accentColor
    }

    var body: some View {
        HStack(spacing: 0) {
            // Channel column — taps to play
            Button(action: onChannelTap) {
                channelColumn
                    .frame(width: channelColWidth, height: rowHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Program cell — taps to show detail sheet
            Button {
                if let program = currentProgram { onProgramTap(program) } else { onChannelTap() }
            } label: {
                HStack(spacing: 0) {
                    richProgramCell(currentProgram, isNext: false)
                        .frame(maxWidth: .infinity)
                    richProgramCell(nextProgram, isNext: true)
                        .frame(maxWidth: .infinity)
                }
                .offset(x: programOffset)
                .clipped()
            }
            .buttonStyle(.plain)
            .clipped()
        }
        .frame(height: rowHeight)
        .clipped()
        .background(Color(red: 17/255, green: 12/255, blue: 33/255))
    }

    // MARK: - Channel Column

    private var channelColumn: some View {
        VStack(spacing: 6) {
            if let logo = channel.logo {
                AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 26)
            } else {
                Text(channel.name.prefix(4).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(width: 44)
            }
            if let number = channel.number {
                Text("\(number)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            if channel.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Rich Program Cell

    private func recordingAccent(_ program: Program?, isNext: Bool) -> Color? {
        guard let p = program, !isNext, p.hasRecording else { return nil }
        if p.isCurrentlyAiring { return Color.red }          // actively recording now
        if p.startTime > Date() { return Color.yellow }      // scheduled future recording
        return nil
    }

    @ViewBuilder
    private func richProgramCell(_ program: Program?, isNext: Bool) -> some View {
        let recColor = recordingAccent(program, isNext: isNext)
        let color = recColor ?? (isNext ? Color.gray.opacity(0.6) : categoryColor)

        ZStack(alignment: .bottomLeading) {
            // Artwork background
            if let art = program?.art {
                AuthenticatedImage(path: art, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fill)
                    .frame(width: nil, height: rowHeight)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(isNext ? 0.92 : 0.72)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .opacity(isNext ? 0.4 : 1.0)
            } else {
                LinearGradient(
                    colors: [color.opacity(isNext ? 0.06 : 0.18), Color.black.opacity(0.8)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }

            // Category stripe — left edge
            HStack(spacing: 0) {
                Rectangle()
                    .fill(color)
                    .frame(width: 3)
                Spacer()
            }

            // Content
            VStack(alignment: .leading, spacing: 3) {
                // Badges
                if let p = program, !isNext {
                    HStack(spacing: 4) {
                        if p.isLive {
                            liveBadge
                        }
                        if p.isNew {
                            badge("NEW", color: .green)
                        }
                        if p.isPremiere {
                            badge("PREMIERE", color: color)
                        }
                        if p.isFinale {
                            badge("FINALE", color: .orange)
                        }
                        if p.hasRecording {
                            recBadge
                        }
                    }
                }

                Spacer()

                // Title
                Text(program?.title ?? "No data")
                    .font(.system(size: isNext ? 12 : 14, weight: isNext ? .regular : .semibold))
                    .foregroundColor(isNext ? .gray : .white)
                    .lineLimit(2)
                    .shadow(color: isNext ? .clear : .black.opacity(0.6), radius: 2)

                // Time + duration
                if let p = program {
                    HStack(spacing: 4) {
                        if isNext {
                            Text(nextLabel(p))
                                .font(.system(size: 10))
                                .foregroundColor(.gray.opacity(0.7))
                        } else {
                            Text("\(p.duration)m")
                                .font(.system(size: 10))
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                }

                // Progress bar (current program only)
                if let _ = program, !isNext, progress > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 2)
                            Rectangle()
                                .fill(color)
                                .frame(width: geo.size.width * CGFloat(progress), height: 2)
                        }
                    }
                    .frame(height: 2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .padding(.leading, 3) // account for category stripe

            // Recording border: red top edge = recording now, yellow = scheduled
            if let rec = recColor {
                VStack(spacing: 0) {
                    rec.frame(height: 3)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(Rectangle())
    }

    private func nextLabel(_ p: Program) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return "Next \(formatter.string(from: p.startTime).lowercased())"
    }

    // MARK: - Badges

    private var liveBadge: some View {
        HStack(spacing: 3) {
            Circle().fill(Color.red).frame(width: 5, height: 5)
            Text("LIVE").font(.system(size: 8, weight: .black)).foregroundColor(.white)
        }
        .padding(.horizontal, 5).padding(.vertical, 2)
        .background(Color.red)
        .cornerRadius(3)
    }

    private var recBadge: some View {
        HStack(spacing: 2) {
            Circle().fill(Color.red).frame(width: 4, height: 4)
            Text("REC").font(.system(size: 8, weight: .bold)).foregroundColor(.red)
        }
        .padding(.horizontal, 5).padding(.vertical, 2)
        .background(Color.red.opacity(0.2))
        .cornerRadius(3)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(color)
            .cornerRadius(3)
    }
}

// MARK: - Live Channel Player (wrapper)

struct LiveChannelPlayerView: View {
    @State var channel: Channel
    @ObservedObject var viewModel: LiveTVViewModel
    let channels: [Channel]
    let onDismiss: () -> Void
    @StateObject private var vlcPlayer = VLCPlayerViewModel()
    @StateObject private var dvrRepository = DVRRepository()
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
    @State private var showVolumeSlider = false
    @State private var volumeLevel: Double = 100
    @State private var volumeHideTask: Task<Void, Never>?
    @State private var streamInfoExtracted = false
    @State private var previousChannel: Channel?
    @State private var showChannelBanner = false
    @State private var channelBannerTask: Task<Void, Never>?
    @State private var showMultiview = false
    @State private var multiviewPickedChannel: Channel?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let streamUrl = channel.streamUrl, let url = URL(string: streamUrl) {
                VLCPlayerView(viewModel: vlcPlayer)
                    .ignoresSafeArea()
            } else {
                VStack {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No stream available")
                        .foregroundColor(.white)
                }
            }

            // Loading state (only when controls hidden)
            if vlcPlayer.isLoading && !showControls {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading \(channel.name)...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            }

            // Error state
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

            // Tap to toggle controls
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if showVolumeSlider {
                        withAnimation { showVolumeSlider = false }
                        return
                    }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showControls.toggle()
                    }
                    if showControls {
                        scheduleAutoHide()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            if abs(vertical) > abs(horizontal) {
                                // Vertical swipe → channel change
                                if vertical < -50 {
                                    switchChannel(direction: .up)
                                } else if vertical > 50 {
                                    switchChannel(direction: .down)
                                }
                            } else if behindLive {
                                // Horizontal swipe → seek (only when behind live)
                                if horizontal > 50 {
                                    seekLive(seconds: 10)
                                    showToast(message: "+10s", icon: "goforward.10")
                                } else if horizontal < -50 {
                                    seekLive(seconds: -10)
                                    showToast(message: "-10s", icon: "gobackward.10")
                                }
                            }
                        }
                )

            // Controls overlay
            if showControls {
                LiveChannelControlsOverlay(
                    channel: channel,
                    vlcPlayer: vlcPlayer,
                    userPaused: userPaused,
                    behindLive: behindLive,
                    nowPlaying: nowPlaying,
                    upNext: upNext,
                    dvrRepository: dvrRepository,
                    showVolumeSlider: $showVolumeSlider,
                    volumeLevel: $volumeLevel,
                    onDismiss: {
                        vlcPlayer.stop()
                        onDismiss()
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
                    },
                    onSeekForward: {
                        scheduleAutoHide()
                        seekLive(seconds: 10)
                        behindLive = true
                    },
                    onSeekBackward: {
                        scheduleAutoHide()
                        seekLive(seconds: -10)
                        behindLive = true
                    },
                    onGoLive: {
                        if let streamUrl = channel.streamUrl, let url = URL(string: streamUrl) {
                            vlcPlayer.stop()
                            vlcPlayer.play(url: url)
                            userPaused = false
                            behindLive = false
                        }
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
                    onInteraction: { scheduleAutoHide() },
                    onVolumeChanged: { newVolume in
                        vlcPlayer.setVolume(Int32(newVolume))
                        scheduleVolumeHide()
                    }
                )
                .transition(.opacity)
            }

            // Channel banner (TV-style info bar on switch)
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

            // Toast notification
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
            if let streamUrl = channel.streamUrl, let url = URL(string: streamUrl) {
                vlcPlayer.play(url: url)
            }
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
            volumeHideTask?.cancel()
            channelBannerTask?.cancel()
        }
        .onChange(of: vlcPlayer.isPlaying) { playing in
            if playing && !streamInfoExtracted {
                // Extract stream info once playback starts
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    vlcPlayer.extractStreamInfo()
                    streamInfoExtracted = true
                }
            }
        }
        .sheet(isPresented: $showSleepPicker) {
            SleepTimerPickerSheet(vlcPlayer: vlcPlayer) { option in
                showToast(message: option == .off ? "Sleep Timer Off" : "Sleep Timer: \(option.label)", icon: "moon.fill")
            }
            .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showMultiview, onDismiss: {
            if let picked = multiviewPickedChannel {
                // Double-tap fullscreen: switch to the picked channel instead of resuming
                multiviewPickedChannel = nil
                switchToChannel(picked)
            } else {
                // Normal close: resume the channel that was playing before multiview
                if let url = URL(string: channel.streamUrl ?? "") {
                    vlcPlayer.play(url: url)
                }
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
        .sheet(isPresented: $showRecordOptions) {
            if let program = nowPlaying {
                RecordOptionsSheet(
                    program: program,
                    channel: channel,
                    dvrRepository: dvrRepository,
                    onDone: { message in
                        showRecordOptions = false
                        showToast(message: message, icon: "record.circle.fill")
                    }
                )
                .presentationDetents([.height(220)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Seek (works while paused)

    private func seekLive(seconds: Int32) {
        if vlcPlayer.duration > 0 {
            // VOD/recording: use standard seek
            if seconds > 0 { vlcPlayer.skipForward() } else { vlcPlayer.skipBackward() }
        } else if userPaused {
            // Live stream while paused: resume briefly, jump, re-pause
            vlcPlayer.mediaPlayer.play()
            vlcPlayer.mediaPlayer.jumpForward(seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                vlcPlayer.pause()
            }
        } else {
            // Live stream, playing: jump directly
            vlcPlayer.mediaPlayer.jumpForward(seconds)
        }
    }

    // MARK: - Channel Switching

    private enum ChannelDirection { case up, down }

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
        guard let prev = previousChannel else { return }
        switchToChannel(prev)
    }

    private func switchToChannel(_ newChannel: Channel) {
        let oldChannel = channel
        vlcPlayer.stop()
        streamInfoExtracted = false
        previousChannel = oldChannel
        channel = newChannel
        viewModel.selectChannel(newChannel)

        if let streamUrl = newChannel.streamUrl, let url = URL(string: streamUrl) {
            vlcPlayer.play(url: url)
        }

        userPaused = false
        behindLive = false
        loadEPGInfo()
        showChannelBannerOverlay()

        // Notify server for prebuffering adjacent channels
        notifyInstantSwitch(channelId: newChannel.id)
    }

    private func notifyInstantSwitch(channelId: String) {
        Task {
            let api = OpenFlixAPI.shared
            _ = try? await api.instantSwitchChannel(channelId: channelId)
        }
    }

    private var channelBannerView: some View {
        HStack(spacing: 14) {
            // Channel logo
            if let logo = channel.logo {
                AuthenticatedImage(path: logo, systemPlaceholder: "tv")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 4) {
                // Channel number + name
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

                // Now playing info
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

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 3)
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geo.size.width * program.progress, height: 3)
                        }
                        .cornerRadius(1.5)
                    }
                    .frame(height: 3)
                }

                // Up next
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

    // MARK: - EPG Info

    private func loadEPGInfo() {
        // Try from guide data first
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

    // MARK: - Recording

    private func recordCurrentProgram() {
        guard let program = nowPlaying else {
            showToast(message: "No program info available", icon: "exclamationmark.circle")
            return
        }
        Task {
            do {
                _ = try await dvrRepository.recordProgram(channelId: channel.id, programId: program.id)
                showToast(message: "Recording: \(program.title)", icon: "record.circle")
            } catch {
                showToast(message: "Record failed", icon: "exclamationmark.circle")
            }
        }
    }

    // MARK: - Helpers

    private func scheduleAutoHide() {
        controlsHideTask?.cancel()
        controlsHideTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showControls = false
                    showVolumeSlider = false
                }
            }
        }
    }

    private func scheduleVolumeHide() {
        volumeHideTask?.cancel()
        volumeHideTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !Task.isCancelled {
                withAnimation { showVolumeSlider = false }
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

// MARK: - Live Channel Controls Overlay (iPhone)

private struct LiveChannelControlsOverlay: View {
    let channel: Channel
    @ObservedObject var vlcPlayer: VLCPlayerViewModel
    let userPaused: Bool
    let behindLive: Bool
    let nowPlaying: Program?
    let upNext: Program?
    @ObservedObject var dvrRepository: DVRRepository
    @Binding var showVolumeSlider: Bool
    @Binding var volumeLevel: Double
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
    let onVolumeChanged: (Double) -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                // Center transport controls — always show seek ±10 buttons
                centerTransportControls

                Spacer()

                // Channels-style 3-panel info bar
                channelsInfoBar
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                // Seek bar (VOD only) or LIVE indicator
                seekBarOrLiveIndicator
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // Bottom toolbar
                bottomToolbar
                    .padding(.top, 12)
                    .padding(.bottom, 30)
            }

            // Volume slider overlay
            if showVolumeSlider {
                volumeSliderOverlay
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }

            Spacer()

            // Channel logo + info
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

            // Stream resolution badge
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

            // Mute button (tap = toggle, long press = volume slider)
            Image(systemName: vlcPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
                .onTapGesture {
                    onInteraction()
                    vlcPlayer.toggleMute()
                    onShowToast(vlcPlayer.isMuted ? "Muted" : "Unmuted", vlcPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    onInteraction()
                    withAnimation { showVolumeSlider.toggle() }
                }
        }
    }

    // MARK: - Now Playing Card

    // MARK: - Channels-Style Info Bar

    private var channelsInfoBar: some View {
        HStack(spacing: 0) {

            // LEFT — channel logo + number
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

            // CENTER — program artwork + title + description + time + progress
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
                        // Progress bar
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

            // RIGHT — Up Next
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

    private func nowPlayingCard(program: Program) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title + badges
            HStack(spacing: 6) {
                Text(program.fullTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                ForEach(program.badges, id: \.self) { badge in
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(badge == "LIVE" ? .red : badge == "REC" ? .red : .white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(badge == "LIVE" || badge == "REC" ? Color.red.opacity(0.3) : Color.white.opacity(0.2))
                        .cornerRadius(3)
                }
            }

            // Time range + category
            HStack(spacing: 8) {
                Text(program.timeRangeFormatted)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))

                if let category = program.category {
                    HStack(spacing: 3) {
                        Image(systemName: program.categoryIcon)
                            .font(.system(size: 10))
                        Text(category)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.white.opacity(0.5))
                }

                if let rating = program.rating, !rating.isEmpty {
                    Text(rating)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 3)
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geo.size.width * program.progress, height: 3)
                }
            }
            .frame(height: 3)

            // Up next
            if let next = upNext {
                Text("Up Next: \(next.fullTitle)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }

    // MARK: - Center Transport Controls

    private var centerTransportControls: some View {
        Group {
            if (vlcPlayer.isLoading || vlcPlayer.isBuffering) && !vlcPlayer.isPlaying && vlcPlayer.currentTime == 0 {
                ProgressView()
                    .scaleEffect(2.0)
                    .tint(.white)
                    .frame(width: 70, height: 70)
            } else {
                // Always show skip back / play-pause / skip forward
                HStack(spacing: 40) {
                    Button {
                        onInteraction()
                        onSeekBackward()
                    } label: {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                    }

                    Button {
                        onInteraction()
                        onTogglePlayPause()
                    } label: {
                        Image(systemName: (vlcPlayer.isPlaying && !userPaused) ? "pause.fill" : "play.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }

                    Button {
                        onInteraction()
                        onSeekForward()
                    } label: {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                    }
                }
            }
        }
    }

    // MARK: - Seek Bar / Live Indicator

    private var seekBarOrLiveIndicator: some View {
        Group {
            if vlcPlayer.duration > 0 {
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { vlcPlayer.currentTime },
                            set: { newValue in
                                onInteraction()
                                vlcPlayer.seek(to: newValue)
                            }
                        ),
                        in: 0...max(vlcPlayer.duration, 1)
                    )
                    .tint(.white)

                    HStack {
                        Text(formatTime(vlcPlayer.currentTime))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(formatTime(vlcPlayer.duration))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            } else {
                HStack(spacing: 6) {
                    if behindLive {
                        Button {
                            onInteraction()
                            onGoLive()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 12, weight: .bold))
                                Text("GO LIVE")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(14)
                        }
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
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 20) {
            // Channel down
            Button {
                onInteraction()
                onChannelDown()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20))
                    Text("CH-")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white)
            }

            // Channel up
            Button {
                onInteraction()
                onChannelUp()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 20))
                    Text("CH+")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white)
            }

            // Previous channel
            if let onPrev = onPreviousChannel {
                Button {
                    onInteraction()
                    onPrev()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.left")
                            .font(.system(size: 20))
                        Text("Prev")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                }
            }

            // Record
            Button {
                onInteraction()
                onRecord()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: nowPlaying?.hasRecording == true ? "record.circle.fill" : "record.circle")
                        .font(.system(size: 20))
                    Text("Record")
                        .font(.system(size: 10))
                }
                .foregroundColor(nowPlaying?.hasRecording == true ? .red : .white)
            }

            // Aspect ratio
            Button {
                onInteraction()
                let mode = vlcPlayer.cycleAspectRatio()
                onShowToast(mode.rawValue, mode.icon)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: vlcPlayer.aspectRatioMode.icon)
                        .font(.system(size: 20))
                    Text("Aspect")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white)
            }

            // Audio track
            Button {
                onInteraction()
                if let name = vlcPlayer.cycleAudioTrack() {
                    onShowToast("Audio: \(name)", "waveform")
                } else {
                    onShowToast("No audio tracks", "waveform")
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.system(size: 20))
                    Text("Audio")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white)
            }

            // Subtitles
            Button {
                onInteraction()
                if let name = vlcPlayer.cycleSubtitleTrack() {
                    onShowToast("Subtitles: \(name)", "captions.bubble")
                } else {
                    onShowToast("Subtitles Off", "captions.bubble")
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 20))
                    Text("Subs")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white)
            }

            // Multiview
            Button {
                onInteraction()
                onMultiview()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "rectangle.split.2x2")
                        .font(.system(size: 20))
                    Text("Multi")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white)
            }

            // Sleep timer
            Button {
                onInteraction()
                onShowSleepPicker()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: vlcPlayer.sleepTimerOption != .off ? "moon.fill" : "moon")
                        .font(.system(size: 20))
                    Text(vlcPlayer.sleepTimerOption != .off ? vlcPlayer.sleepTimerLabel : "Sleep")
                        .font(.system(size: 10))
                }
                .foregroundColor(vlcPlayer.sleepTimerOption != .off ? .cyan : .white)
            }
        }
    }

    // MARK: - Volume Slider Overlay

    private var volumeSliderOverlay: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Slider(value: $volumeLevel, in: 0...200, step: 5) { editing in
                    if !editing {
                        onVolumeChanged(volumeLevel)
                    }
                }
                .onChange(of: volumeLevel) { newValue in
                    onVolumeChanged(newValue)
                }
                .tint(.white)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text("\(Int(volumeLevel))%")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 45)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.85))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Helpers

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

// MARK: - Sleep Timer Picker Sheet

private struct SleepTimerPickerSheet: View {
    @ObservedObject var vlcPlayer: VLCPlayerViewModel
    let onSelect: (SleepTimerOption) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Record Options Sheet

private struct RecordOptionsSheet: View {
    let program: Program
    let channel: Channel
    let dvrRepository: DVRRepository
    let onDone: (String) -> Void

    @State private var isWorking = false

    var body: some View {
        VStack(spacing: 0) {
            // Program title
            VStack(spacing: 4) {
                Text(program.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                if let subtitle = program.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            Divider()

            // Record once
            Button {
                guard !isWorking else { return }
                isWorking = true
                Task {
                    do {
                        _ = try await dvrRepository.recordProgram(channelId: channel.id, programId: program.id)
                        onDone("Recording: \(program.title)")
                    } catch {
                        onDone("Record failed")
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Record This Episode")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("Record just this airing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if isWorking {
                        ProgressView().tint(.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }

            Divider().padding(.leading, 66)

            // Series pass
            Button {
                guard !isWorking else { return }
                isWorking = true
                Task {
                    do {
                        try await dvrRepository.createSeriesRule(
                            title: program.title,
                            channelId: channel.id,
                            prePadding: 0,
                            postPadding: 300,
                            keepCount: 10
                        )
                        onDone("Series Pass: \(program.title)")
                    } catch {
                        onDone("Pass failed")
                    }
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "repeat.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.purple)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Create Series Pass")
                            .font(.body)
                            .foregroundColor(.primary)
                        Text("Record every episode automatically")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
        }
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    NavigationStack {
        XfinityLiveTVView()
    }
}
