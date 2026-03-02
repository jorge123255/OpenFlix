import SwiftUI

private struct EPGScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { value = nextValue() }
}

// MARK: - Exact Channels APK colors
private extension Color {
    static let epgBg      = Color(red: 0.098, green: 0.071, blue: 0.133) // #191222 background
    static let epgCellBg  = Color(red: 0.184, green: 0.122, blue: 0.286) // #2f1f49 muted_dark_purple
    static let epgCellNow = Color(red: 0.251, green: 0.141, blue: 0.424) // #40246c purple (airing now)
    static let epgAccent  = Color(red: 0.608, green: 0.247, blue: 1.000) // #9b3fff tint
    static let epgText    = Color(red: 0.839, green: 0.753, blue: 0.976) // #d6c0f9 extra_light_purple
    static let epgTextDim = Color(red: 0.580, green: 0.498, blue: 0.698) // #947fb2 guide_subtitle
    static let epgSep     = Color(red: 0.098, green: 0.071, blue: 0.133) // same as bg (border color)
}

struct EPGGuideView: View {
    @ObservedObject var viewModel: LiveTVViewModel
    @Environment(\.dismiss) var dismiss
    var onChannelSelect: ((Channel) -> Void)? = nil

    @State private var guide: [ChannelWithPrograms] = []
    @State private var isLoading = true
    @State private var scrollOffset: CGPoint = .zero
    @State private var selectedProgram: Program?
    @State private var selectedChannel: Channel?

    // Paged horizontal swiping
    @State private var currentPage: Int = 0
    @State private var dragOffset: CGFloat = 0
    private let hoursPerPage: CGFloat = 2
    private var pageWidth: CGFloat { hourWidth * hoursPerPage }  // 400pt per page
    private var totalPages: Int { Int(24 / hoursPerPage) }       // 12 pages
    private var currentPageOffset: CGFloat {
        -CGFloat(currentPage) * pageWidth + dragOffset
    }

    // Channels-app style dimensions
    private let chanWidth: CGFloat = 90   // wide enough for logo + name
    private let rowHeight: CGFloat = 56   // slightly taller rows
    private let timeBarH:  CGFloat = 30   // taller time bar
    private let cellBorder: CGFloat = 2   // guide_cell_border stroke
    private let hourWidth: CGFloat = 200  // wider so 30-min slots are readable

    private var pps: CGFloat { hourWidth / 3600 }
    private var totalW: CGFloat { hourWidth * 24 }
    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    private var nowX: CGFloat {
        CGFloat(Date().timeIntervalSince(today)) * pps
    }

    var body: some View {
        content
            .task { await loadGuide() }
            .sheet(item: $selectedProgram) { program in
                ProgramDetailView(program: program, channelName: selectedChannel?.name) {
                    selectedProgram = nil
                }
                .presentationDetents([.medium])
            }
    }

    @ViewBuilder
    private var content: some View {
        if onChannelSelect != nil {
            // Embedded mode — no NavigationStack
            gridContent
        } else {
            // Sheet mode — wrap in NavigationStack
            NavigationStack {
                gridContent
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("TV Guide")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color.epgText)
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { dismiss() }
                                .foregroundColor(Color.epgAccent)
                        }
                    }
            }
        }
    }

    private var gridContent: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading guide...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.epgBg)
            } else if guide.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    title: "No Guide Data",
                    message: "EPG data is not available for your channels."
                )
                .background(Color.epgBg)
            } else {
                guideGrid
            }
        }
        .background(Color.epgBg.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            if !debugText.isEmpty {
                Text(debugText)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.yellow)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .padding(.top, 4)
                    .padding(.trailing, 4)
            }
        }
    }

    // MARK: - Guide Grid

    private var guideGrid: some View {
        GeometryReader { geo in
            let gridWidth = geo.size.width - chanWidth

            VStack(spacing: 0) {

                // ── Time ruler row (pinned) ──
                HStack(spacing: 0) {
                    // Corner
                    Color.epgBg.frame(width: chanWidth, height: timeBarH)

                    // Scrolling time labels — synced to page
                    timeRuler
                        .frame(width: totalW)
                        .offset(x: currentPageOffset)
                        .frame(width: gridWidth, height: timeBarH, alignment: .leading)
                        .clipped()
                }
                .background(Color.epgBg)
                .zIndex(2)

                // ── Body ──
                HStack(spacing: 0) {

                    // Pinned channel column
                    channelCol
                        .frame(width: chanWidth)
                        .offset(y: -scrollOffset.y)
                        .frame(height: geo.size.height - timeBarH, alignment: .top)
                        .clipped()
                        .background(Color.epgBg)
                        .zIndex(1)

                    // Vertical scroll + horizontal paged swipe
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            // Offset tracker (vertical only now)
                            GeometryReader { inner in
                                Color.clear.preference(
                                    key: EPGScrollOffsetKey.self,
                                    value: CGPoint(
                                        x: 0,
                                        y: -inner.frame(in: .named("epg")).minY
                                    )
                                )
                            }
                            .frame(width: 1, height: 1)

                            // Program rows
                            VStack(spacing: 0) {
                                ForEach(guide) { row in
                                    programRow(row)
                                        .frame(height: rowHeight)
                                }
                            }
                            .frame(width: totalW)
                            .offset(x: currentPageOffset)

                            // "Now" line
                            Rectangle()
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 2, height: rowHeight * CGFloat(guide.count))
                                .offset(x: nowX + currentPageOffset)
                                .zIndex(20)
                        }
                        .frame(width: gridWidth, alignment: .leading)
                        .clipped()
                    }
                    .coordinateSpace(name: "epg")
                    .onPreferenceChange(EPGScrollOffsetKey.self) { v in
                        DispatchQueue.main.async { scrollOffset = v }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                let velocity = value.predictedEndTranslation.width - value.translation.width
                                
                                withAnimation(.easeOut(duration: 0.3)) {
                                    if value.translation.width < -threshold || velocity < -100 {
                                        // Swipe left → next page
                                        currentPage = min(currentPage + 1, totalPages - 1)
                                    } else if value.translation.width > threshold || velocity > 100 {
                                        // Swipe right → previous page
                                        currentPage = max(currentPage - 1, 0)
                                    }
                                    dragOffset = 0
                                }
                            }
                    )
                    .frame(width: gridWidth)
                    .clipped()
                }
            }
            .onAppear {
                // Auto-snap to current time's 2-hour block
                let hourNow = Calendar.current.component(.hour, from: Date())
                let startPage = max(Int(CGFloat(hourNow) / hoursPerPage) - 1, 0)
                currentPage = min(startPage, totalPages - 1)
            }
        }
    }

    // MARK: - Time Ruler (APK: 11sp text, light purple)

    private var timeRuler: some View {
        ZStack(alignment: .topLeading) {
            Color.epgBg.frame(width: totalW, height: timeBarH)

            // 30-minute slots: 48 per day
            ForEach(0..<48, id: \.self) { slot in
                let hour   = slot / 2
                let minute = (slot % 2) * 30
                let x      = CGFloat(slot) * (hourWidth / 2)
                let d      = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: today)!
                let isHour = minute == 0

                // Tick mark — taller for hours
                Rectangle()
                    .fill(Color.epgCellBg)
                    .frame(width: 1, height: isHour ? timeBarH : timeBarH * 0.5)
                    .offset(x: x, y: isHour ? 0 : timeBarH * 0.5)

                // Label — show for every slot, slightly dimmer for half-hours
                Text(isHour ? Self.hourFmt.string(from: d) : Self.halfHourFmt.string(from: d))
                    .font(.system(size: isHour ? 11 : 10, weight: isHour ? .semibold : .regular))
                    .foregroundColor(isHour ? Color.epgText : Color.epgTextDim)
                    .offset(x: x + 4, y: 6)
            }

            // Now indicator in time ruler
            Rectangle()
                .fill(Color.red.opacity(0.9))
                .frame(width: 2, height: timeBarH)
                .offset(x: nowX)
        }
        .frame(width: totalW, height: timeBarH)
    }

    // MARK: - Channel Column (APK: 40x25 logo + 9sp number)

    private var channelCol: some View {
        VStack(spacing: 0) {
            ForEach(guide) { row in
                channelCell(row.channel)
                    .frame(width: chanWidth, height: rowHeight)
            }
        }
    }

    private func channelCell(_ ch: Channel) -> some View {
        HStack(spacing: 6) {
            // Logo or abbrev placeholder
            if let logo = ch.logo {
                AsyncImage(url: logoURL(logo)) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fit)
                    } else {
                        channelPlaceholder(ch)
                    }
                }
                .frame(width: 36, height: 24)
            } else {
                channelPlaceholder(ch)
                    .frame(width: 36, height: 24)
            }

            // Channel name + number stacked
            VStack(alignment: .leading, spacing: 1) {
                Text(ch.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color.epgText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let num = ch.number {
                    Text("\(num)")
                        .font(.system(size: 9))
                        .foregroundColor(Color.epgTextDim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 6)
        .frame(width: chanWidth, height: rowHeight)
        .background(Color.epgBg)
    }

    private func channelPlaceholder(_ ch: Channel) -> some View {
        Text(ch.name.prefix(3).uppercased())
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(Color.epgTextDim)
            .frame(width: 36, height: 24)
            .background(Color.epgCellBg.opacity(0.5))
            .cornerRadius(3)
    }

    // MARK: - Program Row

    private func programRow(_ channelRow: ChannelWithPrograms) -> some View {
        let startOfDay = today
        let endOfDay   = startOfDay.addingTimeInterval(86400)

        let visible = channelRow.programs.filter {
            $0.endTime > startOfDay && $0.startTime < endOfDay
        }

        return ZStack(alignment: .topLeading) {
            // Row bg (full width background)
            Color.epgBg.frame(width: totalW, height: rowHeight)

            ForEach(visible) { p in
                let cStart = max(p.startTime, startOfDay)
                let cEnd   = min(p.endTime, endOfDay)
                let xOff   = CGFloat(cStart.timeIntervalSince(startOfDay)) * pps
                let cellW  = max(CGFloat(cEnd.timeIntervalSince(cStart)) * pps, 4)

                programCell(p, width: cellW)
                    .offset(x: xOff)
                    .onTapGesture {
                        selectedChannel = channelRow.channel
                        if let onChannelSelect {
                            onChannelSelect(channelRow.channel)
                        } else {
                            selectedProgram = p
                        }
                    }
            }
        }
        .frame(width: totalW, height: rowHeight)
        .clipped()
    }

    // MARK: - Program Cell (APK: title only 14sp + 1dp progress bar at bottom)

    private func programCell(_ p: Program, width: CGFloat) -> some View {
        let isNow  = p.isCurrentlyAiring
        let isPast = p.hasEnded
        let bg     = isNow ? Color.epgCellNow : Color.epgCellBg

        // Progress through current program (0.0 – 1.0)
        let progress: Double = isNow ? {
            let total = p.endTime.timeIntervalSince(p.startTime)
            let elapsed = Date().timeIntervalSince(p.startTime)
            return total > 0 ? min(max(elapsed / total, 0), 1) : 0
        }() : (isPast ? 1.0 : 0.0)

        return ZStack(alignment: .bottomLeading) {
            // Cell background with 2dp inset (APK: stroke of background color)
            bg
                .padding(cellBorder)
                .background(Color.epgBg)

            // Title (14sp, extra_light_purple, vertically centered, 6dp padding)
            if width > 10 {
                Text(p.title)
                    .font(.system(size: 14))
                    .foregroundColor(isPast ? Color.epgTextDim : Color.epgText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.horizontal, 6 + cellBorder)
                    .padding(.vertical, cellBorder)
            }

            // 1dp progress bar at very bottom (APK: ProgressBar height=1dp, tint color)
            if isNow || isPast {
                GeometryReader { _ in
                    ZStack(alignment: .leading) {
                        Color.epgCellBg.opacity(0.4)
                            .frame(height: 2)
                        Color.epgAccent
                            .frame(width: max(CGFloat(progress) * (width - cellBorder * 2), 0), height: 2)
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, cellBorder)
                .padding(.bottom, cellBorder)
            }
        }
        .frame(width: width, height: rowHeight)
        .clipShape(Rectangle())
    }

    // MARK: - Helpers

    @State private var debugText: String = ""

    private func loadGuide() async {
        isLoading = true
        defer { isLoading = false }
        await viewModel.loadGuide()
        guide = viewModel.guide
        let totalPrograms = guide.reduce(0) { $0 + $1.programs.count }
        let firstChPrograms = guide.first?.programs.count ?? 0
        debugText = "ch:\(guide.count) p:\(totalPrograms) fp:\(firstChPrograms) | \(viewModel.debugInfo)"
        NSLog("EPG LOADED: %@", debugText)
    }

    private func logoURL(_ logo: String) -> URL? {
        if logo.hasPrefix("http") { return URL(string: logo) }
        guard let base = UserDefaults.standard.serverURL else { return nil }
        return base.appendingPathComponent(logo)
    }

    private static let hourFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h a"; return f
    }()

    private static let halfHourFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm"; return f
    }()
}

#Preview {
    EPGGuideView(viewModel: LiveTVViewModel())
}
