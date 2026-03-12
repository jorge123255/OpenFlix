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
        .navigationBarTitleDisplayMode(.large)
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
                    title: "Watch Time",
                    value: viewModel.stats.totalWatchTimeFormatted,
                    subtitle: viewModel.stats.watchTimeChange,
                    icon: "clock.fill",
                    color: accent
                )
                miniStatCard(
                    title: "Programs",
                    value: "\(viewModel.stats.programsWatched)",
                    subtitle: "\(viewModel.stats.programsCompleted) completed",
                    icon: "play.rectangle.fill",
                    color: Color(red: 0.6, green: 0.3, blue: 1.0)
                )
                miniStatCard(
                    title: "Channels",
                    value: "\(viewModel.stats.uniqueChannels)",
                    subtitle: viewModel.stats.favoriteChannel.map { "Fav: \($0)" } ?? "—",
                    icon: "tv.fill",
                    color: Color(red: 0.1, green: 0.75, blue: 0.55)
                )
                miniStatCard(
                    title: "Live TV",
                    value: viewModel.stats.liveWatchTimeFormatted,
                    subtitle: "\(viewModel.stats.livePercentage)% of total",
                    icon: "dot.radiowaves.left.and.right",
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
    var totalWatchTime: Int = 0
    var programsWatched: Int = 0
    var programsCompleted: Int = 0
    var uniqueChannels: Int = 0
    var favoriteChannel: String?
    var liveWatchTime: Int = 0
    var dailyWatchTime: [DayWatchTime] = []
    var genreBreakdown: [GenreStats] = []
    var topChannels: [ChannelStats] = []
    var topShows: [ShowStats] = []
    var recentActivity: [ActivityItem] = []

    var totalWatchTimeFormatted: String {
        let h = totalWatchTime / 60; let m = totalWatchTime % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    var liveWatchTimeFormatted: String {
        let h = liveWatchTime / 60; let m = liveWatchTime % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    var livePercentage: Int {
        guard totalWatchTime > 0 else { return 0 }
        return Int(Double(liveWatchTime) / Double(totalWatchTime) * 100)
    }
    var watchTimeChange: String { "+12% vs last period" }
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

    func loadStats(for period: WatchStatsView.StatsPeriod) {
        isLoading = true
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            stats = WatchStats(
                totalWatchTime: 1247,
                programsWatched: 42,
                programsCompleted: 28,
                uniqueChannels: 15,
                favoriteChannel: "ESPN",
                liveWatchTime: 480,
                dailyWatchTime: [
                    DayWatchTime(label: "Mon", hours: 2.5),
                    DayWatchTime(label: "Tue", hours: 1.8),
                    DayWatchTime(label: "Wed", hours: 3.2),
                    DayWatchTime(label: "Thu", hours: 2.0),
                    DayWatchTime(label: "Fri", hours: 4.5),
                    DayWatchTime(label: "Sat", hours: 5.0),
                    DayWatchTime(label: "Sun", hours: 3.8)
                ],
                genreBreakdown: [
                    GenreStats(name: "Sports",  percentage: 35, color: Color(red: 0.1, green: 0.75, blue: 0.55)),
                    GenreStats(name: "Drama",   percentage: 25, color: Color(red: 0.6, green: 0.3,  blue: 1.0)),
                    GenreStats(name: "News",    percentage: 20, color: Color(red: 0.23, green: 0.51, blue: 0.96)),
                    GenreStats(name: "Comedy",  percentage: 12, color: Color(red: 0.96, green: 0.62, blue: 0.04)),
                    GenreStats(name: "Other",   percentage: 8,  color: Color(red: 0.42, green: 0.45, blue: 0.5))
                ],
                topChannels: [],
                topShows: [],
                recentActivity: [
                    ActivityItem(icon: "play.fill",  iconColor: Color(red: 0.1, green: 0.75, blue: 0.55), description: "Watched NFL Game",       timeAgo: "2h ago"),
                    ActivityItem(icon: "tv.fill",    iconColor: Color(red: 0.23, green: 0.51, blue: 0.96), description: "Tuned to CNN",           timeAgo: "4h ago"),
                    ActivityItem(icon: "film.fill",  iconColor: Color(red: 0.6, green: 0.3, blue: 1.0),   description: "Finished Breaking Bad S5", timeAgo: "Yesterday")
                ]
            )
            isLoading = false
        }
    }
}
