import SwiftUI
import Charts

// MARK: - Watch Stats View

struct WatchStatsView: View {
    @StateObject private var viewModel = WatchStatsViewModel()
    @State private var selectedPeriod: StatsPeriod = .week

    private let bg     = Color(red: 17/255,  green: 12/255,  blue: 33/255)
    private let card   = Color.white.opacity(0.07)
    private let accent = Color(red: 97/255,  green: 56/255,  blue: 245/255)

    enum StatsPeriod: String, CaseIterable {
        case today = "Today"
        case week  = "Week"
        case month = "Month"
        case year  = "Year"
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        statsContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Watch Stats")
        #if !os(tvOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .onAppear { viewModel.loadStats(for: selectedPeriod) }
        .onChange(of: selectedPeriod) { viewModel.loadStats(for: $0) }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: selectedPeriod == period ? .bold : .medium))
                        .foregroundColor(selectedPeriod == period ? .white : .gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? accent : Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Stats Content

    private var statsContent: some View {
        VStack(spacing: 16) {
            // Top 4 stat cards (2x2 grid)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                miniStatCard(
                    title: "Recorded",
                    value: viewModel.stats.totalWatchTimeFormatted,
                    subtitle: "\(viewModel.stats.programsCompleted) completed",
                    icon: "clock.fill",
                    color: accent
                )
                miniStatCard(
                    title: "Recordings",
                    value: "\(viewModel.stats.programsWatched)",
                    subtitle: "\(viewModel.stats.programsCompleted) finished",
                    icon: "play.rectangle.fill",
                    color: Color(red: 0.6, green: 0.3, blue: 1.0)
                )
                miniStatCard(
                    title: "Channels",
                    value: "\(viewModel.stats.uniqueChannels)",
                    subtitle: viewModel.stats.favoriteChannel.map { "Top: \($0)" } ?? "—",
                    icon: "tv.fill",
                    color: Color(red: 0.1, green: 0.75, blue: 0.55)
                )
                miniStatCard(
                    title: "Storage",
                    value: viewModel.stats.storageFormatted,
                    subtitle: "\(viewModel.stats.liveWatchTime) streaming now",
                    icon: "internaldrive.fill",
                    color: Color(red: 0.9, green: 0.25, blue: 0.25)
                )
            }

            // Watch Time Chart
            watchTimeChart

            // Genre breakdown
            if !viewModel.stats.genreBreakdown.isEmpty {
                genreCard
            }

            // Top Channels
            if !viewModel.stats.topChannels.isEmpty {
                rankCard(title: "Top Channels") {
                    ForEach(Array(viewModel.stats.topChannels.enumerated()), id: \.element.id) { i, ch in
                        channelRankRow(rank: i + 1, channel: ch)
                        if i < viewModel.stats.topChannels.count - 1 {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }

            // Most Watched
            if !viewModel.stats.topShows.isEmpty {
                rankCard(title: "Most Watched") {
                    ForEach(Array(viewModel.stats.topShows.enumerated()), id: \.element.id) { i, show in
                        showRankRow(rank: i + 1, show: show)
                        if i < viewModel.stats.topShows.count - 1 {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }

            // Recent Activity
            if !viewModel.stats.recentActivity.isEmpty {
                rankCard(title: "Recent Activity") {
                    ForEach(viewModel.stats.recentActivity) { activity in
                        HStack(spacing: 12) {
                            Image(systemName: activity.icon)
                                .foregroundColor(activity.iconColor)
                                .frame(width: 20)
                            Text(activity.description)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Spacer()
                            Text(activity.timeAgo)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    // MARK: - Mini Stat Card

    private func miniStatCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(color.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
    }

    // MARK: - Watch Time Chart

    private var watchTimeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watch Time")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)

            if #available(iOS 16.0, *) {
                Chart(viewModel.stats.dailyWatchTime) { day in
                    BarMark(
                        x: .value("Day", day.label),
                        y: .value("Hours", day.hours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accent, Color(red: 0.6, green: 0.3, blue: 1.0)],
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.gray.opacity(0.2))
                        AxisValueLabel().foregroundStyle(Color.gray)
                    }
                }
                .frame(height: 160)
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    let maxH = viewModel.stats.dailyWatchTime.map(\.hours).max() ?? 1
                    ForEach(viewModel.stats.dailyWatchTime) { day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accent)
                                .frame(height: day.hours / maxH * 120)
                            Text(day.label)
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
    }

    // MARK: - Genre Card

    private var genreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Genre")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)

            ForEach(viewModel.stats.genreBreakdown) { genre in
                VStack(spacing: 6) {
                    HStack {
                        Circle()
                            .fill(genre.color)
                            .frame(width: 10, height: 10)
                        Text(genre.name)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(genre.percentage)%")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(genre.color)
                                .frame(width: geo.size.width * CGFloat(genre.percentage) / 100)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
    }

    // MARK: - Rank Cards

    private func rankCard<Content: View>(title: String, @ViewBuilder rows: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            rows()
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
    }

    private func channelRankRow(rank: Int, channel: ChannelStats) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 22)

            AsyncImage(url: URL(string: channel.logoUrl ?? "")) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(channel.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text(channel.watchTimeFormatted)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func showRankRow(rank: Int, show: ShowStats) -> some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(red: 0.6, green: 0.3, blue: 1.0))
                .frame(width: 22)

            AsyncImage(url: URL(string: show.thumbnailUrl ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 30)
            .clipped()
            .cornerRadius(4)

            VStack(alignment: .leading, spacing: 2) {
                Text(show.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("\(show.episodesWatched) episodes")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(accent)
            Text("Loading your stats...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// MARK: - Stat Card (kept for compatibility)

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            Text(value).font(.system(size: 28, weight: .bold)).foregroundColor(.white)
            Text(title).font(.subheadline).foregroundColor(.gray)
            Text(subtitle).font(.caption).foregroundColor(color)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }
}

// MARK: - Models

struct WatchStats {
    var totalWatchTime: Int = 0      // minutes
    var programsWatched: Int = 0     // total recordings
    var programsCompleted: Int = 0   // completed recordings
    var uniqueChannels: Int = 0
    var favoriteChannel: String?
    var liveWatchTime: Int = 0       // active sessions count
    var storageMB: Int = 0
    var dailyWatchTime: [DayWatchTime] = []
    var genreBreakdown: [GenreStats] = []
    var topChannels: [ChannelStats] = []
    var topShows: [ShowStats] = []
    var recentActivity: [ActivityItem] = []

    var totalWatchTimeFormatted: String {
        let h = totalWatchTime / 60; let m = totalWatchTime % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    var liveWatchTimeFormatted: String { "\(liveWatchTime)" }
    var livePercentage: Int { liveWatchTime }
    var storageFormatted: String {
        if storageMB == 0 { return "—" }
        if storageMB >= 1024 { return String(format: "%.1f GB", Double(storageMB) / 1024) }
        return "\(storageMB) MB"
    }
    var watchTimeChange: String { "" }
}

struct DayWatchTime: Identifiable {
    let id = UUID()
    let label: String
    let hours: Double
}

struct GenreStats: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Int
    let color: Color
}

struct ChannelStats: Identifiable {
    let id: String
    let name: String
    let logoUrl: String?
    let watchTimeMinutes: Int
    var watchTimeFormatted: String {
        let h = watchTimeMinutes / 60; let m = watchTimeMinutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

struct ShowStats: Identifiable {
    let id: String
    let title: String
    let thumbnailUrl: String?
    let episodesWatched: Int
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let description: String
    let timeAgo: String
}

// MARK: - ViewModel

@MainActor
class WatchStatsViewModel: ObservableObject {
    @Published var stats = WatchStats()
    @Published var isLoading = false
    @Published var error: String?

    private let iso = ISO8601DateFormatter()

    func loadStats(for period: WatchStatsView.StatsPeriod) {
        isLoading = true
        error = nil
        Task {
            await fetchStats(for: period)
            isLoading = false
        }
    }

    private func fetchStats(for period: WatchStatsView.StatsPeriod) async {
        // Fetch in parallel
        async let recordingStatsTask = try? OpenFlixAPI.shared.getRecordingStats()
        async let recordingsTask     = try? OpenFlixAPI.shared.getRecordings(status: "completed")
        async let sessionsTask       = try? OpenFlixAPI.shared.getSessions()

        let recordingStats = await recordingStatsTask
        let recordingsResp = await recordingsTask
        let sessionsResp   = await sessionsTask

        let recordings = recordingsResp?.allRecordings ?? []
        let activeSessions = sessionsResp?.MediaContainer.Metadata?.count ?? 0

        // Filter recordings to the selected period
        let cutoff = cutoffDate(for: period)
        let periodRecordings = recordings.filter { rec in
            guard let start = rec.startDate else { return true }
            return start >= cutoff
        }

        // Top channels from recordings in period
        var channelMinutes: [String: (name: String, logo: String?, minutes: Int)] = [:]
        for rec in periodRecordings {
            guard let ch = rec.channelName else { continue }
            let mins = (rec.duration ?? 0) / 60_000  // ms → minutes
            let existing = channelMinutes[ch] ?? (name: ch, logo: rec.channelLogo, minutes: 0)
            channelMinutes[ch] = (name: ch, logo: rec.channelLogo ?? existing.logo, minutes: existing.minutes + mins)
        }
        let topChannels = channelMinutes.values
            .sorted { $0.minutes > $1.minutes }
            .prefix(5)
            .map { ChannelStats(id: $0.name, name: $0.name, logoUrl: $0.logo, watchTimeMinutes: $0.minutes) }

        // Recent activity from recordings (last 8)
        let recent = periodRecordings
            .sorted { ($0.startDate ?? .distantPast) > ($1.startDate ?? .distantPast) }
            .prefix(8)
        let recentActivity = recent.map { rec -> ActivityItem in
            let icon = rec.isMovie == true ? "film.fill" : "play.rectangle.fill"
            let color = Color(red: 0.6, green: 0.3, blue: 1.0)
            let ago = rec.startDate.map { timeAgo($0) } ?? ""
            return ActivityItem(icon: icon, iconColor: color, description: rec.safeTitle, timeAgo: ago)
        }

        // Daily recording hours for chart (last 7 days / 30 days depending on period)
        let dailyWatchTime = buildDailyWatchTime(from: periodRecordings, period: period)

        // Totals
        let totalMins = periodRecordings.reduce(0) { $0 + ($1.duration ?? 0) / 60_000 }
        let uniqueChannels = Set(periodRecordings.compactMap(\.channelName)).count
        let favoriteChannel = channelMinutes.values.max(by: { $0.minutes < $1.minutes })?.name
        let totalRecordings = recordingStats?.total ?? periodRecordings.count
        let completed = recordingStats?.completed ?? periodRecordings.count
        let storageMB = (recordingStats?.totalSize ?? 0) / (1024 * 1024)

        stats = WatchStats(
            totalWatchTime: totalMins,
            programsWatched: totalRecordings,
            programsCompleted: completed,
            uniqueChannels: uniqueChannels,
            favoriteChannel: favoriteChannel,
            liveWatchTime: activeSessions,  // repurposed: active session count
            storageMB: storageMB,
            dailyWatchTime: dailyWatchTime,
            genreBreakdown: [],
            topChannels: Array(topChannels),
            topShows: [],
            recentActivity: Array(recentActivity)
        )
    }

    private func cutoffDate(for period: WatchStatsView.StatsPeriod) -> Date {
        let cal = Calendar.current
        switch period {
        case .today: return cal.startOfDay(for: Date())
        case .week:  return cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        case .month: return cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        case .year:  return cal.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        }
    }

    private func buildDailyWatchTime(from recordings: [RecordingDTO], period: WatchStatsView.StatsPeriod) -> [DayWatchTime] {
        let cal = Calendar.current
        var dayMap: [Date: Double] = [:]

        for rec in recordings {
            guard let date = rec.startDate else { continue }
            let day = cal.startOfDay(for: date)
            let hours = Double(rec.duration ?? 0) / 3_600_000.0
            dayMap[day, default: 0] += hours
        }

        let dayCount: Int
        let labelFmt = DateFormatter()
        switch period {
        case .today:
            return []
        case .week:
            dayCount = 7; labelFmt.dateFormat = "EEE"
        case .month:
            dayCount = 30; labelFmt.dateFormat = "d"
        case .year:
            dayCount = 12; labelFmt.dateFormat = "MMM"
        }

        return (0..<dayCount).compactMap { i -> DayWatchTime? in
            guard let date = Calendar.current.date(byAdding: .day, value: -(dayCount - 1 - i), to: Calendar.current.startOfDay(for: Date())) else { return nil }
            let hours = dayMap[date] ?? 0
            return DayWatchTime(label: labelFmt.string(from: date), hours: hours)
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }
}
