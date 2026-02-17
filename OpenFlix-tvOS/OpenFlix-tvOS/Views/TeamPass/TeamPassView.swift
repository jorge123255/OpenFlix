import SwiftUI

// MARK: - Team Pass View
/// Follow your favorite sports teams. See all upcoming games and live matches.
/// One-tap access to any game involving your teams.

struct TeamPassView: View {
    @StateObject private var viewModel = TeamPassViewModel()
    @State private var selectedFilter: TeamFilter = .all
    @FocusState private var focusedGame: String?
    
    enum TeamFilter: String, CaseIterable {
        case all = "All Sports"
        case nfl = "NFL"
        case nba = "NBA"
        case mlb = "MLB"
        case nhl = "NHL"
        case soccer = "Soccer"
        case college = "College"
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "1a2810"), Color(hex: "0d0d0d")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Sport filter
                sportFilter
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.games.isEmpty {
                    emptyView
                } else {
                    gamesContent
                }
            }
        }
        .onAppear {
            viewModel.loadGames()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Team Pass")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your teams, all in one place")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Teams count
            if !viewModel.favoriteTeams.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text("\(viewModel.favoriteTeams.count) Teams")
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
            }
            
            // Sports icon
            Image(systemName: "sportscourt")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "10B981"), Color(hex: "34D399")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.horizontal, 48)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
    
    // MARK: - Sport Filter
    
    private var sportFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TeamFilter.allCases, id: \.self) { filter in
                    SportPill(
                        title: filter.rawValue,
                        icon: iconForFilter(filter),
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal, 48)
        }
        .padding(.bottom, 24)
    }
    
    private func iconForFilter(_ filter: TeamFilter) -> String {
        switch filter {
        case .all: return "sportscourt"
        case .nfl: return "football"
        case .nba: return "basketball"
        case .mlb: return "baseball"
        case .nhl: return "hockey.puck"
        case .soccer: return "soccerball"
        case .college: return "graduationcap"
        }
    }
    
    // MARK: - Games Content
    
    private var gamesContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Live Now section
                if !liveGames.isEmpty {
                    GameSection(
                        title: "Live Now",
                        icon: "dot.radiowaves.left.and.right",
                        iconColor: Color(hex: "EF4444"),
                        games: liveGames,
                        onGameTap: { viewModel.watchGame($0) }
                    )
                }
                
                // Starting Soon section
                if !soonGames.isEmpty {
                    GameSection(
                        title: "Starting Soon",
                        icon: "clock",
                        iconColor: Color(hex: "F59E0B"),
                        games: soonGames,
                        onGameTap: { viewModel.watchGame($0) }
                    )
                }
                
                // Upcoming Today section
                if !todayGames.isEmpty {
                    GameSection(
                        title: "Today",
                        icon: "calendar",
                        iconColor: Color(hex: "3B82F6"),
                        games: todayGames,
                        onGameTap: { viewModel.watchGame($0) }
                    )
                }
                
                // This Week section
                if !weekGames.isEmpty {
                    GameSection(
                        title: "This Week",
                        icon: "calendar.badge.clock",
                        iconColor: Color(hex: "8B5CF6"),
                        games: weekGames,
                        onGameTap: { viewModel.watchGame($0) }
                    )
                }
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 48)
        }
    }
    
    private var filteredGames: [SportsGame] {
        guard selectedFilter != .all else { return viewModel.games }
        return viewModel.games.filter { $0.sport.lowercased() == selectedFilter.rawValue.lowercased() }
    }
    
    private var liveGames: [SportsGame] {
        filteredGames.filter { $0.isLive }
    }
    
    private var soonGames: [SportsGame] {
        let now = Date()
        let soon = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        return filteredGames.filter { !$0.isLive && $0.startTime <= soon && $0.startTime > now }
    }
    
    private var todayGames: [SportsGame] {
        let now = Date()
        let soon = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        return filteredGames.filter { 
            !$0.isLive && 
            $0.startTime > soon && 
            Calendar.current.isDateInToday($0.startTime)
        }
    }
    
    private var weekGames: [SportsGame] {
        filteredGames.filter { 
            !$0.isLive && 
            !Calendar.current.isDateInToday($0.startTime)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "10B981"))
            
            Text("Loading games...")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Games Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Add your favorite teams to see their games here")
                .foregroundColor(.gray)
            
            Button("Add Teams") {
                viewModel.showTeamPicker = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "10B981"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sport Pill

struct SportPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "10B981") : Color.white.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game Section

struct GameSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let games: [SportsGame]
    let onGameTap: (SportsGame) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("(\(games.count))")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            // Games row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(games) { game in
                        GameCard(game: game, onTap: { onGameTap(game) })
                    }
                }
            }
        }
    }
}

// MARK: - Game Card

struct GameCard: View {
    let game: SportsGame
    let onTap: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Teams matchup
                HStack(spacing: 16) {
                    TeamBadge(name: game.awayTeam, logo: game.awayTeamLogo)
                    
                    VStack(spacing: 4) {
                        if game.isLive {
                            Text("\(game.awayScore ?? 0) - \(game.homeScore ?? 0)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(game.gameTime ?? "LIVE")
                                .font(.caption)
                                .foregroundColor(Color(hex: "EF4444"))
                        } else {
                            Text("@")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            Text(game.startTimeFormatted)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    TeamBadge(name: game.homeTeam, logo: game.homeTeamLogo)
                }
                
                // Channel info
                HStack(spacing: 8) {
                    if let channel = game.channelName {
                        Image(systemName: "tv")
                            .font(.caption)
                        Text(channel)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Text(game.sport)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                .foregroundColor(.gray)
            }
            .padding(20)
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isFocused ? 0.15 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        game.isLive ? Color(hex: "EF4444") : (isFocused ? Color(hex: "10B981") : Color.clear),
                        lineWidth: game.isLive ? 2 : 3
                    )
            )
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
    }
}

// MARK: - Team Badge

struct TeamBadge: View {
    let name: String
    let logo: String?
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: logo ?? "")) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(name.prefix(2)).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            
            Text(name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 80)
    }
}

// MARK: - Models

struct SportsGame: Identifiable {
    let id: String
    let sport: String
    let homeTeam: String
    let awayTeam: String
    let homeTeamLogo: String?
    let awayTeamLogo: String?
    let startTime: Date
    var isLive: Bool = false
    var homeScore: Int?
    var awayScore: Int?
    var gameTime: String?
    let channelId: String?
    let channelName: String?
    
    var startTimeFormatted: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(startTime) {
            formatter.dateFormat = "h:mm a"
        } else {
            formatter.dateFormat = "E h:mm a"
        }
        return formatter.string(from: startTime)
    }
}

struct FavoriteTeam: Identifiable {
    let id: String
    let name: String
    let sport: String
    let logo: String?
}

// MARK: - ViewModel

@MainActor
class TeamPassViewModel: ObservableObject {
    @Published var games: [SportsGame] = []
    @Published var favoriteTeams: [FavoriteTeam] = []
    @Published var isLoading = false
    @Published var showTeamPicker = false
    @Published var error: String?
    
    func loadGames() {
        isLoading = true
        Task {
            // TODO: Fetch from API
            try? await Task.sleep(nanoseconds: 500_000_000)
            isLoading = false
        }
    }
    
    func watchGame(_ game: SportsGame) {
        // TODO: Navigate to live TV player
        print("Watching: \(game.awayTeam) @ \(game.homeTeam)")
    }
    
    func addTeam(_ team: FavoriteTeam) {
        favoriteTeams.append(team)
    }
    
    func removeTeam(_ team: FavoriteTeam) {
        favoriteTeams.removeAll { $0.id == team.id }
    }
}

#Preview {
    TeamPassView()
}
