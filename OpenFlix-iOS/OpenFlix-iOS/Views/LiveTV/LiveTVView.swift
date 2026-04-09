import SwiftUI
import AVKit
#if !targetEnvironment(simulator)
import MobileVLCKit
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
            if let url = streamURL, let channel = selectedChannelForPlayback {
                LiveTVPlayerView(
                    channel: channel,
                    streamURL: url,
                    viewModel: viewModel
                )
                .environmentObject(dvrViewModel)
            }
        }
    }

    private func playChannel(_ channel: Channel) {
        // Use direct stream URL if available (same LAN), fall back to API
        if let streamUrl = channel.streamUrl, let url = URL(string: streamUrl) {
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
private struct TVOSLiveBrowserView: View {
    private enum HeroControl: Hashable {
        case earlier
        case later
        case watch
    }

    @ObservedObject var viewModel: LiveTVViewModel
    let onPlayChannel: (Channel) -> Void
    let onOpenGuide: () -> Void
    let onOpenCatchup: () -> Void
    let onOpenOnLater: () -> Void
    let onOpenTeamPass: () -> Void
    let onOpenChannelGroups: () -> Void

    @State private var selectedChannelId: String?
    @State private var selectedProgramIdByChannel: [String: String] = [:]
    @State private var guideWindowStartDate: Date?
    @FocusState private var focusedHeroControl: HeroControl?
    @Namespace private var heroFocusNamespace

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
           let row = guideRows.first(where: { $0.channel.id == selectedChannelId }) {
            return row
        }
        if let selected = viewModel.selectedChannel,
           let row = guideRows.first(where: { $0.channel.id == selected.id }) {
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

    private var visibleRows: [ChannelWithPrograms] {
        let active = guideRows.filter { row in
            row.programs.contains {
                $0.endTime > $0.startTime &&
                $0.endTime > roundedWindowStart &&
                $0.startTime < windowEnd
            }
        }
        return active.ifEmpty(guideRows)
    }

    var body: some View {
        Group {
            if guideRows.isEmpty && viewModel.isGuideLoading {
                VStack(alignment: .leading, spacing: 1) {
                    guideHero
                    guideControls
                        .disabled(true)
                        .opacity(0.6)
                    timeHeader
                    guideLoadingMatrix
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    guideHero
                    guideControls
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
                }
                .onChange(of: visibleRows.map(\.channel.id).joined(separator: "|")) { _, _ in
                    let rows = visibleRows
                    if selectedChannelId == nil || !rows.contains(where: { $0.channel.id == selectedChannelId }) {
                        let initialId = viewModel.selectedChannel?.id ?? rows.first?.channel.id
                        selectedChannelId = initialId
                    }
                }
                .onChange(of: viewModel.guide.count) { _, _ in
                    if guideWindowStartDate == nil {
                        guideWindowStartDate = defaultRoundedWindowStart
                    }
                }
            }
        }
        .padding(.horizontal, 34)
        .padding(.top, 0)
        .padding(.bottom, 4)
        .background(shellBackground)
    }

    private var guideHero: some View {
        let channel = selectedRow?.channel
        let program = selectedProgram ?? selectedRow?.currentProgram ?? channel?.nowPlaying

        return HStack(alignment: .center, spacing: 14) {
                TVGuideLivePreviewCard(
                    viewModel: viewModel,
                    channel: channel,
                    program: program,
                    accent: accent,
                    compact: true
                )
                    .frame(width: 276, height: 154)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("Guide")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Today")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(accent)

                        Text(Self.heroTimeFormatter.string(from: Date()))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))

                        Text("\(visibleRows.count) live")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    HStack(spacing: 8) {
                        if let channel {
                            Text(channel.number.map { "\($0) \(channel.name)" } ?? channel.name)
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(accent)
                                .lineLimit(1)
                        }

                        if let program {
                            Text(program.timeRangeFormatted)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.66))
                                .lineLimit(1)
                        }
                    }

                    Text(program?.title ?? "Select a channel to browse what’s live now.")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(program?.subtitle.orEmpty.isEmpty == false ? program?.subtitle ?? "" : "Browse channels and move right into the grid.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        Text(visibleTimeRangeLabel)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))

                        HStack(spacing: 10) {
                            TVGuideActionButton(title: "Earlier", icon: "chevron.left", accent: accent, style: .secondary) {
                                shiftGuideWindow(by: -guidePageStepMinutes)
                            }
                            .disabled(!canPageBackward)
                            .focused($focusedHeroControl, equals: .earlier)
                            .prefersDefaultFocus(true, in: heroFocusNamespace)

                            TVGuideActionButton(title: "Later", icon: "chevron.right", accent: accent, style: .secondary) {
                                shiftGuideWindow(by: guidePageStepMinutes)
                            }
                            .disabled(!canPageForward)
                            .focused($focusedHeroControl, equals: .later)

                            TVGuideActionButton(title: "Watch", icon: "play.fill", accent: accent, style: .primary) {
                                if let channel { onPlayChannel(channel) }
                            }
                            .focused($focusedHeroControl, equals: .watch)
                        }
                    }
                    .focusSection()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
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

    private var guideControls: some View {
        HStack(spacing: 6) {
            TVGuideFeatureChip(title: "Catch Up", icon: "clock.arrow.circlepath", accent: accent, action: onOpenCatchup)
            TVGuideFeatureChip(title: "On Later", icon: "calendar.badge.clock", accent: accent, action: onOpenOnLater)
            TVGuideFeatureChip(title: "Team Pass", icon: "sportscourt.fill", accent: accent, action: onOpenTeamPass)
            TVGuideFeatureChip(title: "Groups", icon: "square.grid.2x2.fill", accent: accent, action: onOpenChannelGroups)
        }
        .opacity(0.9)
        .focusSection()
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
                onPlayChannel(channel)
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
    }

    private func selectChannel(_ channel: Channel) {
        selectedChannelId = channel.id
        viewModel.selectChannel(channel)
        if selectedProgramIdByChannel[channel.id] == nil {
            let preferred = guideRows
                .first(where: { $0.channel.id == channel.id })?
                .currentProgram?.id
            ?? channel.nowPlaying?.id
            ?? guideRows.first(where: { $0.channel.id == channel.id })?.programs.first?.id
            selectedProgramIdByChannel[channel.id] = preferred
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
        let filtered = rows.filter { row in
            let validPrograms = row.programs
                .filter { $0.endTime > $0.startTime }
                .filter { $0.endTime > windowStart && $0.startTime < windowEnd }
            var seen = Set<String>()
            let unique = validPrograms.filter { p in
                let key = "\(Int(p.startTime.timeIntervalSince1970))-\(Int(p.endTime.timeIntervalSince1970))"
                return seen.insert(key).inserted
            }
            return !unique.isEmpty
        }

        return filtered
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(displayRows) { row in
                        TVGuideMatrixRow(
                            row: row,
                            selectedChannelId: selectedChannelId,
                            selectedProgramId: selectedProgramIdByChannel[row.channel.id],
                            accent: accent,
                            nowLineColor: nowLineColor,
                            panelBackgroundSoft: panelBackgroundSoft,
                            channelColumnWidth: channelColumnWidth,
                            rowHeight: rowHeight,
                            windowStart: windowStart,
                            windowEnd: windowEnd,
                            guideWindowMinutes: guideWindowMinutes,
                            onSelectChannel: onSelectChannel,
                            onSelectProgram: onSelectProgram,
                            onFocusProgram: onFocusProgram,
                            nowIndicatorOffset: nowIndicatorOffset
                        )
                        .id(row.channel.id)
                    }
                }
            }
            .background(matrixBackground)
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
    let nowLineColor: Color
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
    
    private var isSelectedRow: Bool {
        selectedChannelId == row.channel.id
    }

    private var timelinePrograms: [Program] {
        deduplicatedPrograms(row.programs)
            .filter { $0.endTime > windowStart && $0.startTime < windowEnd }
            .sorted { $0.startTime < $1.startTime }
    }

    @ViewBuilder
    var body: some View {
        if !timelinePrograms.isEmpty {
        HStack(spacing: 0) {
            channelCell
            GeometryReader { proxy in
                TVGuideProgramTrack(
                    row: row,
                    programs: timelinePrograms,
                    selectedProgramId: selectedProgramId,
                    accent: accent,
                    nowLineColor: nowLineColor,
                    panelBackgroundSoft: panelBackgroundSoft,
                    rowHeight: rowHeight,
                    width: proxy.size.width,
                    isSelectedRow: isSelectedRow,
                    windowStart: windowStart,
                    windowEnd: windowEnd,
                    guideWindowMinutes: guideWindowMinutes,
                    onSelectChannel: onSelectChannel,
                    onSelectProgram: onSelectProgram,
                    onFocusProgram: onFocusProgram,
                    nowIndicatorOffset: nowIndicatorOffset
                )
            }
            .frame(height: rowHeight)
        }
        .frame(height: rowHeight)
        .background(rowBackground)
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
        } // end if !timelinePrograms.isEmpty
    }

    private var channelCell: some View {
        TVGuideChannelCell(
            channel: row.channel,
            currentProgram: row.currentProgram ?? row.channel.nowPlaying,
            accent: accent,
            isSelected: selectedChannelId == row.channel.id,
            onFocus: {
                onSelectChannel(row.channel)
            },
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
    let nowLineColor: Color
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
    let nowIndicatorOffset: (CGFloat) -> CGFloat?

    private var minuteWidth: CGFloat {
        width / guideWindowMinutes
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(isSelectedRow ? accent.opacity(0.055) : panelBackgroundSoft.opacity(0.24))

            slotDividers

            if let offset = nowIndicatorOffset(width) {
                Rectangle()
                    .fill(nowLineColor)
                    .frame(width: 2, height: rowHeight - 2)
                    .offset(x: offset, y: 0)
            }

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
                onFocus: {
                    onFocusProgram(row.channel, program)
                },
                action: {
                    onSelectProgram(row.channel, program)
                }
            )
            .offset(x: xPos + 0.5, y: 0)
        }
    }
}

private struct TVGuideLivePreviewCard: View {
    @ObservedObject var viewModel: LiveTVViewModel
    let channel: Channel?
    let program: Program?
    let accent: Color
    var compact: Bool = false

    @State private var player: AVPlayer?
    @State private var previewError = false

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                .allowsHitTesting(false)
            } else {
                TVGuidePreviewCard(channel: channel, program: program, accent: accent, compact: compact)
            }

            if previewError {
                TVGuidePreviewCard(channel: channel, program: program, accent: accent, compact: compact)
                    .overlay {
                        LinearGradient(
                            colors: [Color.black.opacity(0.15), Color.black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : 22))
        .task(id: channel?.id) {
            await loadPreview()
        }
        .onDisappear {
            stopPreview()
        }
    }

    private func loadPreview() async {
        stopPreview()
        previewError = false

        guard let channel else { return }

        try? await Task.sleep(nanoseconds: 250_000_000)
        guard !Task.isCancelled else { return }

        let url: URL?
        if let streamUrl = channel.streamUrl, let directURL = URL(string: streamUrl) {
            url = directURL
        } else {
            url = try? await viewModel.getChannelStream(channel)
        }

        guard !Task.isCancelled, let url else {
            previewError = true
            return
        }

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.isMuted = true
        newPlayer.preventsDisplaySleepDuringVideoPlayback = false
        newPlayer.play()

        player = newPlayer

        // If preview never becomes playable, keep the artwork fallback visible.
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        guard !Task.isCancelled else { return }
        if item.status == .failed {
            previewError = true
            stopPreview()
        }
    }

    private func stopPreview() {
        player?.pause()
        player = nil
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

private struct TVGuideChannelCell: View {
    let channel: Channel
    let currentProgram: Program?
    let accent: Color
    let isSelected: Bool
    let onFocus: () -> Void
    let action: () -> Void
    @Environment(\.isFocused) private var isFocused

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
                (isFocused || isSelected) ? Color(red: 50/255, green: 45/255, blue: 85/255) : Color.white.opacity(0.03)
            )
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill((isFocused || isSelected) ? accent : Color.clear)
                    .frame(width: 4)
            }
            .overlay {
                Rectangle()
                    .stroke((isFocused || isSelected) ? Color.white.opacity(0.9) : Color.clear, lineWidth: 3)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
            }
            .scaleEffect(isFocused ? 1.01 : 1)
            .shadow(color: isFocused ? Color.white.opacity(0.16) : .clear, radius: 12, y: 6)
            .animation(.easeOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(TVNoGlowButtonStyle())
        .onChange(of: isFocused) { _, focused in
            guard focused else { return }
            onFocus()
        }
    }
}

private struct TVGuideProgramCell: View {
    let program: Program
    let accent: Color
    let progressColor: Color
    let width: CGFloat
    let isSelected: Bool
    let onFocus: () -> Void
    let action: () -> Void
    @Environment(\.isFocused) private var isFocused

    private var isUltraCompact: Bool { width < 56 }
    private var isCompact: Bool { width < 150 }
    private var cellHeight: CGFloat { 72 }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                if (isFocused || isSelected) && width >= 170, let imagePath = program.art ?? program.icon {
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
                                .foregroundStyle((isFocused || isSelected) ? .white.opacity(0.85) : .white.opacity(0.40))
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
            .scaleEffect(isHighlighted ? 1.04 : 1)
            .shadow(color: isHighlighted ? Color.white.opacity(0.18) : .clear, radius: 14, y: 4)
            .zIndex(isHighlighted ? 10 : 0)
            .animation(.easeOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(TVNoGlowButtonStyle())
        .onChange(of: isFocused) { _, focused in
            guard focused else { return }
            onFocus()
        }
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

    private var isHighlighted: Bool { isFocused || isSelected }

    private var backgroundFill: Color {
        if isHighlighted {
            return Color(red: 50/255, green: 45/255, blue: 85/255) // bright purple — unmistakable
        }
        if program.isCurrentlyAiring { return Color(red: 24/255, green: 26/255, blue: 48/255) }
        return Color(red: 20/255, green: 22/255, blue: 40/255)
    }

    private var borderColor: Color {
        if isHighlighted { return Color.white.opacity(0.92) }
        return Color.white.opacity(0.06)
    }

    private var borderWidth: CGFloat {
        isHighlighted ? 3 : 0.5
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
                    onToggleFavorite: {
                        handleToggleFavorite()
                    },
                    onRecord: {
                        guard let program = viewModel.selectedChannel?.nowPlaying ?? channel.nowPlaying else {
                            return
                        }
                        Task {
                            try? await dvrViewModel.recordProgram(channelId: channel.id, program: program)
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

            if let urlString = newChannel.streamUrl, let url = URL(string: urlString) {
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
    var onToggleFavorite: () -> Void
    var onRecord: () -> Void
    var onInfo: () -> Void
    var onPiP: () -> Void
    var onDismiss: () -> Void

    @FocusState private var focusedControl: LiveTVControl?
    @State private var showSleepTimerPicker = false
    @State private var toastMessage: String?
    @State private var toastIcon: String?

    enum LiveTVControl: Hashable {
        case close, streamInfo, mute
        case skipBack, playPause, skipForward
        case favorite, previousChannel, aspectRatio, sleepTimer, audio, subtitles
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
