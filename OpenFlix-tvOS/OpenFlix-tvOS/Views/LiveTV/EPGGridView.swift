import SwiftUI

// MARK: - EPG Grid View
// Full-featured electronic program guide with proper Tivimate-style layout

struct EPGGridView: View {
    @ObservedObject var viewModel: LiveTVViewModel
    let onChannelSelect: (Channel) -> Void
    let onProgramSelect: (Program, Channel) -> Void

    @State private var horizontalScrollOffset: CGFloat = 0
    @State private var verticalScrollOffset: CGFloat = 0
    @State private var showProgramDetail: Bool = false
    @State private var selectedProgram: Program?
    @State private var selectedChannelForDetail: Channel?

    // Focus management - track if category tabs should have focus
    @State private var focusOnCategoryTabs: Bool = false

    // Layout constants
    private let channelColumnWidth = EPGTheme.Dimensions.channelColumnWidth
    private let timeSlotWidth = EPGTheme.Dimensions.timeSlotWidth
    private let rowHeight = EPGTheme.Dimensions.rowHeight
    private let headerHeight = EPGTheme.Dimensions.headerHeight

    var body: some View {
        VStack(spacing: 0) {
            // Category filter bar with focus binding
            CategoryTabsWithFocus(
                categories: viewModel.availableGroups,
                selectedCategory: $viewModel.selectedGroup,
                shouldFocus: $focusOnCategoryTabs,
                onFavoritesSelected: {
                    // Filter to favorites only
                },
                onNavigateDown: {
                    // User pressed down from category tabs, return focus to grid
                    focusOnCategoryTabs = false
                }
            )

            // EPG Grid - Fixed header row + scrollable content
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Fixed header row (corner + time slots)
                    headerRow(screenWidth: geometry.size.width)

                    // Single vertical ScrollView for both channels and programs
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredGuide) { channelWithPrograms in
                                epgRow(for: channelWithPrograms, screenWidth: geometry.size.width)
                            }
                        }
                    }
                }
            }
            .onMoveCommand { direction in
                if direction == .up {
                    // Intercept UP and move focus to category tabs
                    focusOnCategoryTabs = true
                }
            }
        }
        .background(EPGTheme.background)
        .sheet(isPresented: $showProgramDetail) {
            if let program = selectedProgram, let channel = selectedChannelForDetail {
                ProgramDetailSheet(
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

    // MARK: - Header Row (Fixed at top)

    private func headerRow(screenWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Corner cell
            cornerCell

            // Time header (horizontally scrollable)
            ScrollView(.horizontal, showsIndicators: false) {
                EPGTimeHeader(
                    timeSlots: timeSlots,
                    timeSlotWidth: timeSlotWidth,
                    headerHeight: headerHeight,
                    scrollOffset: horizontalScrollOffset
                )
            }
        }
    }

    private var cornerCell: some View {
        VStack {
            Text("CHANNELS")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(EPGTheme.textMuted)

            Text("\(filteredGuide.count)")
                .font(.system(size: 16))
                .foregroundColor(EPGTheme.textSecondary)
        }
        .frame(width: channelColumnWidth, height: headerHeight)
        .background(EPGTheme.surface)
        .overlay(
            Rectangle()
                .fill(EPGTheme.background)
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - EPG Row (Channel + Programs together)

    private func epgRow(for channelWithPrograms: ChannelWithPrograms, screenWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            // Channel cell (fixed on left)
            EPGChannelCell(
                channel: channelWithPrograms.channel,
                height: rowHeight
            ) {
                onChannelSelect(channelWithPrograms.channel)
            }
            .frame(width: channelColumnWidth)
            .background(EPGTheme.surface)

            // Program row (horizontally scrollable)
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    programRow(for: channelWithPrograms)

                    // Now line for this row
                    EPGNowLine(
                        timeSlots: timeSlots,
                        timeSlotWidth: timeSlotWidth,
                        totalHeight: rowHeight,
                        scrollOffset: horizontalScrollOffset
                    )
                }
            }
        }
        .frame(height: rowHeight)
        .overlay(
            Rectangle()
                .fill(EPGTheme.background.opacity(0.5))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Program Row

    private func programRow(for channelWithPrograms: ChannelWithPrograms) -> some View {
        HStack(spacing: 0) {
            ForEach(visiblePrograms(for: channelWithPrograms)) { program in
                let width = programWidth(for: program)

                EPGProgramCell(
                    program: program,
                    channel: channelWithPrograms.channel,
                    width: width,
                    height: rowHeight
                ) {
                    // Long press shows detail, tap plays channel
                    onChannelSelect(channelWithPrograms.channel)
                }
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
                            // Schedule recording
                        } label: {
                            Label("Record", systemImage: "record.circle")
                        }
                    }
                }
            }

            // Fill remaining space to ensure proper width for time slots
            Spacer(minLength: CGFloat(timeSlots.count) * timeSlotWidth)
        }
        .frame(height: rowHeight)
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

        // Start 30 minutes before current time slot
        var startOfHour = calendar.date(from: calendar.dateComponents([.year, .month, .day, .hour], from: now))!
        let minute = calendar.component(.minute, from: now)
        if minute >= 30 {
            startOfHour = calendar.date(byAdding: .minute, value: 30, to: startOfHour)!
        }
        // Go back 30 minutes
        startOfHour = calendar.date(byAdding: .minute, value: -30, to: startOfHour)!

        // Generate 6 hours worth of slots
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
            // Show program if it overlaps with the visible time range
            program.endTime > firstSlot && program.startTime < endTime
        }
    }

    private func programWidth(for program: Program) -> CGFloat {
        let durationMinutes = program.endTime.timeIntervalSince(program.startTime) / 60.0
        let width = CGFloat(durationMinutes / 30.0) * timeSlotWidth
        return max(width, 80) // Minimum width for readability
    }
}

// MARK: - Program Detail Sheet

struct ProgramDetailSheet: View {
    let program: Program
    let channel: Channel
    let onPlay: () -> Void
    let onRecord: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            EPGTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(EPGTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Spacer()

                ProgramDetailCard(
                    program: program,
                    channel: channel,
                    onPlay: onPlay,
                    onRecord: onRecord
                )
                .frame(maxWidth: 700)

                Spacer()
            }
        }
    }
}

#Preview {
    let viewModel = LiveTVViewModel()

    return EPGGridView(
        viewModel: viewModel,
        onChannelSelect: { _ in },
        onProgramSelect: { _, _ in }
    )
}
