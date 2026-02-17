import SwiftUI
import Charts

// MARK: - Watch Stats View
/// Detailed viewing statistics and insights.
/// Track watch time, favorite channels, genres, and viewing patterns.

struct WatchStatsView: View {
    @StateObject private var viewModel = WatchStatsViewModel()
    @State private var selectedPeriod: StatsPeriod = .week
    
    enum StatsPeriod: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0f172a"), Color(hex: "0d0d0d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    header
                    
                    // Period selector
                    periodSelector
                    
                    // Stats content
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        statsContent
                    }
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            viewModel.loadStats(for: selectedPeriod)
        }
        .onChange(of: selectedPeriod) { newPeriod in
            viewModel.loadStats(for: newPeriod)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Watch Stats")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your viewing insights")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Chart icon
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "06B6D4"), Color(hex: "22D3EE")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.top, 32)
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 12) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 16, weight: selectedPeriod == period ? .bold : .medium))
                        .foregroundColor(selectedPeriod == period ? .black : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedPeriod == period ? Color(hex: "06B6D4") : Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Stats Content
    
    private var statsContent: some View {
        VStack(spacing: 32) {
            // Top stats cards
            topStatsCards
            
            // Charts row
            HStack(spacing: 24) {
                watchTimeChart
                genreBreakdown
            }
            
            // Bottom sections
            HStack(alignment: .top, spacing: 24) {
                topChannels
                topShows
                recentActivity
            }
        }
    }
    
    // MARK: - Top Stats Cards
    
    private var topStatsCards: some View {
        HStack(spacing: 24) {
            StatCard(
                title: "Total Watch Time",
                value: viewModel.stats.totalWatchTimeFormatted,
                subtitle: viewModel.stats.watchTimeChange,
                icon: "clock.fill",
                color: Color(hex: "06B6D4")
            )
            
            StatCard(
                title: "Programs Watched",
                value: "\(viewModel.stats.programsWatched)",
                subtitle: "\(viewModel.stats.programsCompleted) completed",
                icon: "play.rectangle.fill",
                color: Color(hex: "8B5CF6")
            )
            
            StatCard(
                title: "Channels Used",
                value: "\(viewModel.stats.uniqueChannels)",
                subtitle: "Favorite: \(viewModel.stats.favoriteChannel ?? "N/A")",
                icon: "tv.fill",
                color: Color(hex: "10B981")
            )
            
            StatCard(
                title: "Live TV",
                value: viewModel.stats.liveWatchTimeFormatted,
                subtitle: "\(viewModel.stats.livePercentage)% of total",
                icon: "dot.radiowaves.left.and.right",
                color: Color(hex: "EF4444")
            )
        }
    }
    
    // MARK: - Watch Time Chart
    
    private var watchTimeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Watch Time")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if #available(tvOS 16.0, *) {
                Chart(viewModel.stats.dailyWatchTime) { day in
                    BarMark(
                        x: .value("Day", day.label),
                        y: .value("Hours", day.hours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "06B6D4"), Color(hex: "8B5CF6")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(Color.gray)
                    }
                }
                .frame(height: 200)
            } else {
                // Fallback for older tvOS
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(viewModel.stats.dailyWatchTime) { day in
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "06B6D4"), Color(hex: "8B5CF6")],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: CGFloat(day.hours) * 20)
                            
                            Text(day.label)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Genre Breakdown
    
    private var genreBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Genre")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(viewModel.stats.genreBreakdown) { genre in
                    HStack {
                        Circle()
                            .fill(genre.color)
                            .frame(width: 12, height: 12)
                        
                        Text(genre.name)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(genre.percentage)%")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(genre.color)
                                .frame(width: geo.size.width * CGFloat(genre.percentage) / 100)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .frame(width: 350)
    }
    
    // MARK: - Top Channels
    
    private var topChannels: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Channels")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(Array(viewModel.stats.topChannels.enumerated()), id: \.element.id) { index, channel in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(Color(hex: "06B6D4"))
                            .frame(width: 24)
                        
                        AsyncImage(url: URL(string: channel.logoUrl ?? "")) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(channel.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text(channel.watchTimeFormatted)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Top Shows
    
    private var topShows: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most Watched")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(Array(viewModel.stats.topShows.enumerated()), id: \.element.id) { index, show in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundColor(Color(hex: "8B5CF6"))
                            .frame(width: 24)
                        
                        AsyncImage(url: URL(string: show.thumbnailUrl ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 56, height: 32)
                        .clipped()
                        .cornerRadius(4)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(show.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text("\(show.episodesWatched) episodes")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Recent Activity
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(viewModel.stats.recentActivity) { activity in
                    HStack(spacing: 12) {
                        Image(systemName: activity.icon)
                            .foregroundColor(activity.iconColor)
                            .frame(width: 20)
                        
                        Text(activity.description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(activity.timeAgo)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "06B6D4"))
            
            Text("Loading your stats...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(color)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
    }
}

// MARK: - Models

struct WatchStats {
    var totalWatchTime: Int = 0 // minutes
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
        let hours = totalWatchTime / 60
        let mins = totalWatchTime % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
    
    var liveWatchTimeFormatted: String {
        let hours = liveWatchTime / 60
        let mins = liveWatchTime % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
    
    var livePercentage: Int {
        guard totalWatchTime > 0 else { return 0 }
        return Int((Double(liveWatchTime) / Double(totalWatchTime)) * 100)
    }
    
    var watchTimeChange: String {
        return "+12% from last week" // TODO: Calculate actual change
    }
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
        let hours = watchTimeMinutes / 60
        let mins = watchTimeMinutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
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
    
    func loadStats(for period: WatchStatsView.StatsPeriod) {
        isLoading = true
        Task {
            // TODO: Fetch from API
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Sample data
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
                    GenreStats(name: "Sports", percentage: 35, color: Color(hex: "10B981")),
                    GenreStats(name: "Drama", percentage: 25, color: Color(hex: "8B5CF6")),
                    GenreStats(name: "News", percentage: 20, color: Color(hex: "3B82F6")),
                    GenreStats(name: "Comedy", percentage: 12, color: Color(hex: "F59E0B")),
                    GenreStats(name: "Other", percentage: 8, color: Color(hex: "6B7280"))
                ],
                topChannels: [],
                topShows: [],
                recentActivity: [
                    ActivityItem(icon: "play.fill", iconColor: Color(hex: "10B981"), description: "Watched NFL Game", timeAgo: "2h ago"),
                    ActivityItem(icon: "tv.fill", iconColor: Color(hex: "3B82F6"), description: "Tuned to CNN", timeAgo: "4h ago"),
                    ActivityItem(icon: "film.fill", iconColor: Color(hex: "8B5CF6"), description: "Finished Breaking Bad S5", timeAgo: "Yesterday")
                ]
            )
            
            isLoading = false
        }
    }
}

#Preview {
    WatchStatsView()
}
