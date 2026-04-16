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
#if os(tvOS)
        TVTeamPassDashboardView()
#else
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
#endif
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

#if os(tvOS)
private struct TVTeamPassDashboardView: View {
    private let api = OpenFlixAPI.shared
    @State private var teamsByLeague: [String: [ESPNTeam]] = [:]
    @State private var favoriteTeamNextGames: [String: ESPNGame] = [:]
    @State private var liveGames: [String: [ESPNGame]] = [:]
    @State private var selectedLeague: ESPNService.League? = nil
    @State private var isLoading = true
    @State private var showManageFavorites = false
    @State private var selectedChannel: Channel?
    @State private var selectedTeamContext: TVSelectedTeamContext?
    @StateObject private var broadcastService = BroadcastChannelService.shared
    @StateObject private var liveTVViewModel = LiveTVViewModel()
    @StateObject private var dvrViewModel = DVRViewModel()
    @AppStorage("favoriteTeamKeys") private var favoriteTeamKeysData: Data = Data()

    private let leagues: [ESPNService.League] = [.nfl, .nba, .mlb, .nhl, .mls]
    private let background = Color(red: 8/255, green: 10/255, blue: 24/255)

    private var favoriteTeamKeys: Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: favoriteTeamKeysData)) ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                teamPassHeroBanner
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                leagueFilterRow

                if isLoading {
                    ProgressView("Loading teams...")
                        .tint(.white)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    if !allLiveGames.isEmpty && selectedLeague == nil {
                        TVLiveGamesSection(
                            games: allLiveGames,
                            broadcastService: broadcastService,
                            onOpenTeam: { team, league in
                                selectedTeamContext = TVSelectedTeamContext(team: team, league: league)
                            },
                            onWatch: { selectedChannel = $0 }
                        )
                    }

                    if !favoriteTeamsWithLeague.isEmpty && selectedLeague == nil {
                        favoritesSection
                    }

                    ForEach(leaguesToShow, id: \.rawValue) { league in
                        if let teams = teamsByLeague[league.displayName], !teams.isEmpty {
                            tvLeagueSection(league: league, teams: teams)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
        }
        .background(background.ignoresSafeArea())
        .task {
            async let channelsTask: Void = liveTVViewModel.loadChannels()
            async let guideTask: Void = liveTVViewModel.loadGuide()
            await loadAllData()
            _ = await (channelsTask, guideTask)
        }
        .refreshable { await loadAllData() }
        .sheet(isPresented: $showManageFavorites) {
            TVManageFavoritesSheet(
                favoriteTeams: favoriteTeamsWithLeague,
                onRemove: { team, league in toggleFavorite(team, league: league) }
            )
        }
        .sheet(item: $selectedTeamContext) { context in
            TVTeamDetailSheet(
                team: context.team,
                league: context.league,
                broadcastService: broadcastService,
                isFavorite: isFavorite(league: context.league, teamId: context.team.id),
                onToggleFavorite: { toggleFavorite(context.team, league: context.league) },
                onWatch: { selectedChannel = $0 }
            )
        }
        .fullScreenCover(item: $selectedChannel) { channel in
            TVLiveChannelPlayerView(
                initialChannel: channel,
                initialStreamURL: channel.preferredPlaybackURL,
                viewModel: liveTVViewModel
            )
            .id(channel.id)  // stable identity prevents SwiftUI recreating VLC
            .environmentObject(dvrViewModel)
        }
    }

    private var leaguesToShow: [ESPNService.League] {
        selectedLeague.map { [$0] } ?? leagues
    }

    private var favoriteTeamsWithLeague: [(team: ESPNTeam, league: ESPNService.League)] {
        var result: [(team: ESPNTeam, league: ESPNService.League)] = []
        var seen = Set<String>()
        for league in leagues {
            guard let teams = teamsByLeague[league.displayName] else { continue }
            for team in teams {
                let key = teamKey(league: league, teamId: team.id)
                if favoriteTeamKeys.contains(key), seen.insert(key).inserted {
                    result.append((team, league))
                }
            }
        }
        return result
    }

    private var allLiveGames: [(league: ESPNService.League, game: ESPNGame)] {
        leagues.compactMap { league in
            liveGames[league.displayName]?.map { (league: league, game: $0) }
        }
        .flatMap { $0 }
        .filter { $0.game.isLive }
        .sorted { ($0.game.gameDate ?? .distantFuture) < ($1.game.gameDate ?? .distantFuture) }
    }

    // MARK: - tvOS Hero Banner

    private var teamPassHeroBanner: some View {
        let teamCount  = favoriteTeamsWithLeague.count
        let leagueCount = Set(favoriteTeamsWithLeague.map { $0.league.rawValue }).count

        return ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.18, blue: 0.52),
                    Color(red: 0.04, green: 0.08, blue: 0.24)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            Image(systemName: "sportscourt")
                .font(.system(size: 200, weight: .light))
                .foregroundStyle(.white.opacity(0.07))
                .offset(x: 380, y: -10)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(red: 0.25, green: 0.55, blue: 1.0))
                        .frame(width: 8, height: 8)
                    Text("TEAM PASS")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(2)
                }
                Text("Team Pass")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                if teamCount > 0 {
                    Text("\(teamCount) favorite team\(teamCount == 1 ? "" : "s") across \(leagueCount) league\(leagueCount == 1 ? "" : "s")")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                } else {
                    Text("Follow your teams and never miss a game")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
            .padding(28)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var leagueFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                TVLeagueChip(title: "All", isSelected: selectedLeague == nil) {
                    selectedLeague = nil
                }
                ForEach(leagues, id: \.rawValue) { league in
                    TVLeagueChip(title: "\(league.emoji) \(league.displayName)", isSelected: selectedLeague == league) {
                        selectedLeague = league
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .focusSection()
        .padding(.bottom, 4)
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\u{2B50} My Teams")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showManageFavorites = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.pencil")
                        Text("Manage")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                #if os(tvOS)
                .buttonStyle(.card)
                #endif
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(Array(favoriteTeamsWithLeague.enumerated()), id: \.offset) { _, item in
                        TVFavoriteTeamDashboardCard(
                            team: item.team,
                            league: item.league,
                            nextGame: favoriteTeamNextGames[teamKey(league: item.league, teamId: item.team.id)],
                            liveGame: liveGame(for: item.team.id),
                            broadcastService: broadcastService,
                            onTap: {
                                selectedTeamContext = TVSelectedTeamContext(team: item.team, league: item.league)
                            },
                            onWatch: { selectedChannel = $0 },
                            onRemove: { toggleFavorite(item.team, league: item.league) }
                        )
                    }
                }
                .padding(.horizontal, 24)
            }
            .focusSection()
        }
    }

    private func tvLeagueSection(league: ESPNService.League, teams: [ESPNTeam]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(league.emoji) \(league.displayName)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Text("(\(teams.count) teams)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                if let liveCount = liveGames[league.displayName]?.filter({ $0.isLive }).count, liveCount > 0 {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("\(liveCount) LIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                    }
                    .padding(.leading, 8)
                }
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(teams) { team in
                        TVLeagueTeamCard(
                            team: team,
                            isFavorite: isFavorite(league: league, teamId: team.id),
                            onTap: {
                                selectedTeamContext = TVSelectedTeamContext(team: team, league: league)
                            },
                            onFavorite: { toggleFavorite(team, league: league) }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
            .focusSection()
        }
    }

    private func teamKey(league: ESPNService.League, teamId: String) -> String {
        "\(league.rawValue):\(teamId)"
    }

    private func isFavorite(league: ESPNService.League, teamId: String) -> Bool {
        favoriteTeamKeys.contains(teamKey(league: league, teamId: teamId))
    }

    private func toggleFavorite(_ team: ESPNTeam, league: ESPNService.League) {
        let key = teamKey(league: league, teamId: team.id)
        var keys = favoriteTeamKeys
        let isRemoving = keys.contains(key)
        if isRemoving {
            keys.remove(key)
        } else {
            keys.insert(key)
        }
        if let encoded = try? JSONEncoder().encode(keys) {
            favoriteTeamKeysData = encoded
        }

        Task {
            let api = OpenFlixAPI.shared
            if isRemoving {
                if let passesResponse = try? await api.getTeamPasses(),
                   let matchingPass = passesResponse.teamPasses.first(where: {
                       $0.teamName.localizedCaseInsensitiveCompare(team.displayName) == .orderedSame
                   }) {
                    try? await api.deleteTeamPass(id: String(matchingPass.id))
                }
            } else {
                _ = try? await api.createTeamPass(teamName: team.displayName, league: league.rawValue)
            }
            await loadAllData()
        }
    }

    private func liveGame(for teamId: String) -> ESPNGame? {
        for games in liveGames.values {
            if let match = games.first(where: { game in
                guard game.isLive else { return false }
                return game.homeTeam?.team.id == teamId || game.awayTeam?.team.id == teamId
            }) {
                return match
            }
        }
        return nil
    }

    private func loadAllData() async {
        isLoading = true
        defer { isLoading = false }

        await withTaskGroup(of: Void.self) { group in
            for league in leagues {
                group.addTask {
                    if let teams = try? await ESPNService.shared.fetchTeams(league: league) {
                        await MainActor.run {
                            teamsByLeague[league.displayName] = teams.sorted { $0.displayName < $1.displayName }
                        }
                    }
                }
            }

            group.addTask {
                let scores = await ESPNService.shared.fetchAllLiveScores()
                await MainActor.run {
                    liveGames = scores
                }
            }
        }

        await syncFavoritesFromServer()

        let favorites = await MainActor.run { favoriteTeamsWithLeague }
        if favorites.isEmpty {
            favoriteTeamNextGames = [:]
        } else {
            var nextGames: [String: ESPNGame] = [:]
            let now = Date()
            await withTaskGroup(of: (String, ESPNGame?).self) { group in
                for item in favorites {
                    let key = teamKey(league: item.league, teamId: item.team.id)
                    group.addTask {
                        let schedule = try? await ESPNService.shared.fetchTeamSchedule(league: item.league, teamId: item.team.id)
                        let nextGame = schedule?
                            .filter { game in
                                guard let date = game.gameDate else { return false }
                                return date >= now && !game.isCompleted
                            }
                            .sorted { ($0.gameDate ?? .distantFuture) < ($1.gameDate ?? .distantFuture) }
                            .first
                        return (key, nextGame)
                    }
                }
                for await (key, game) in group {
                    if let game {
                        nextGames[key] = game
                    }
                }
            }
            favoriteTeamNextGames = nextGames
        }

        if !broadcastService.isLoaded {
            await broadcastService.loadChannels()
        }
    }

    private func syncFavoritesFromServer() async {
        guard let passesResponse = try? await api.getTeamPasses() else { return }

        var syncedKeys = Set<String>()
        for pass in passesResponse.teamPasses where pass.enabled ?? true {
            guard let league = leagues.first(where: {
                $0.rawValue.caseInsensitiveCompare(pass.league) == .orderedSame ||
                $0.displayName.caseInsensitiveCompare(pass.league) == .orderedSame
            }) else { continue }
            guard let teams = teamsByLeague[league.displayName] else { continue }

            if let matchedTeam = teams.first(where: {
                $0.displayName.caseInsensitiveCompare(pass.teamName) == .orderedSame ||
                $0.abbreviation.caseInsensitiveCompare(pass.teamName) == .orderedSame
            }) {
                syncedKeys.insert(teamKey(league: league, teamId: matchedTeam.id))
            }
        }

        if let encoded = try? JSONEncoder().encode(syncedKeys) {
            await MainActor.run {
                favoriteTeamKeysData = encoded
            }
        }
    }
}

private struct TVSelectedTeamContext: Identifiable {
    let team: ESPNTeam
    let league: ESPNService.League

    var id: String { "\(league.rawValue):\(team.id)" }
}

private struct TVLeagueChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color(hex: "6138f5") : Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        #if os(tvOS)
        .buttonStyle(TVLeagueChipButtonStyle(isSelected: isSelected))
        #endif
    }
}

#if os(tvOS)
/// Focus-aware ButtonStyle for TVLeagueChip on tvOS.
/// Inner View pattern ensures @Environment(\.isFocused) resolves against the
/// Button's real focus state rather than a stale ancestor value.
private struct TVLeagueChipButtonStyle: ButtonStyle {
    let isSelected: Bool
    func makeBody(configuration: Configuration) -> some View {
        Inner(configuration: configuration, isSelected: isSelected)
    }
    private struct Inner: View {
        let configuration: ButtonStyle.Configuration
        let isSelected: Bool
        @Environment(\.isFocused) private var isFocused
        var body: some View {
            configuration.label
                .overlay(
                    Capsule()
                        .stroke(isFocused ? Color.white.opacity(0.9) : Color.clear, lineWidth: 2)
                )
                .scaleEffect(configuration.isPressed ? 0.95 : (isFocused ? 1.08 : 1.0))
                .shadow(color: isFocused ? Color(hex: "6138f5").opacity(0.5) : .clear, radius: 14, y: 6)
                .animation(.easeInOut(duration: 0.18), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .contentShape(Capsule())
        }
    }
}
#endif

private struct TVFavoriteTeamDashboardCard: View {
    let team: ESPNTeam
    let league: ESPNService.League
    let nextGame: ESPNGame?
    let liveGame: ESPNGame?
    let broadcastService: BroadcastChannelService
    let onTap: () -> Void
    let onWatch: (Channel) -> Void
    let onRemove: () -> Void

    private var teamColor: Color { Color(hex: team.primaryColor) }
    private var displayGame: ESPNGame? { liveGame ?? nextGame }
    private var opponent: ESPNCompetitor? {
        guard let game = displayGame else { return nil }
        return game.homeTeam?.team.id == team.id ? game.awayTeam : game.homeTeam
    }
    private var watchChannel: Channel? {
        guard let game = displayGame, let broadcast = game.broadcast else { return nil }
        return broadcastService.findChannel(forBroadcast: broadcast)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Left: team logo
                TVTeamLogoBadge(team: team, size: 72, backgroundColor: teamColor)

                // Center: team info + game
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(team.displayName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text(league.emoji)
                            .font(.system(size: 16))
                    }

                    if let liveGame {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red)
                        }
                        HStack(spacing: 10) {
                            Text("\(liveGame.awayTeam?.team.abbreviation ?? "AWY") \(liveGame.awayTeam?.scoreDisplay ?? "-")")
                            Text("•")
                            Text("\(liveGame.homeTeam?.team.abbreviation ?? "HOM") \(liveGame.homeTeam?.scoreDisplay ?? "-")")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    } else if let nextGame {
                        Text("Next: \(nextGame.homeTeam?.team.id == team.id ? "vs" : "@") \(opponent?.team.displayName ?? "TBD")")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            if let date = nextGame.gameDate {
                                Text(date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                            }
                            if let broadcast = nextGame.broadcast {
                                Text("\u{2022}")
                                Text(broadcast)
                                    .foregroundColor(watchChannel != nil ? Color(hex: "6138f5") : .white.opacity(0.7))
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("No upcoming games")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // Right: watch button or chevron
                if liveGame != nil && watchChannel != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text("Watch")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(20)
            .frame(width: 540, alignment: .leading)
        }
        #if os(tvOS)
        .buttonStyle(TVFavoriteTeamCardButtonStyle(teamColor: teamColor))
        #endif
        .contextMenu {
            Button("Remove", role: .destructive) { onRemove() }
        }
    }
}

#if os(tvOS)
/// Focus-aware ButtonStyle for TVFavoriteTeamDashboardCard on tvOS.
/// Inner View pattern ensures @Environment(\.isFocused) resolves against the
/// Button's real focus state rather than a stale ancestor value.
private struct TVFavoriteTeamCardButtonStyle: ButtonStyle {
    let teamColor: Color
    func makeBody(configuration: Configuration) -> some View {
        Inner(configuration: configuration, teamColor: teamColor)
    }
    private struct Inner: View {
        let configuration: ButtonStyle.Configuration
        let teamColor: Color
        @Environment(\.isFocused) private var isFocused
        var body: some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    isFocused ? teamColor.opacity(0.28) : teamColor.opacity(0.15),
                                    Color.black.opacity(isFocused ? 0.30 : 0.22)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isFocused ? teamColor.opacity(0.55) : teamColor.opacity(0.20), lineWidth: isFocused ? 2.5 : 1)
                )
                .scaleEffect(configuration.isPressed ? 0.97 : (isFocused ? 1.04 : 1.0))
                .shadow(color: isFocused ? teamColor.opacity(0.35) : .clear, radius: 22, y: 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .contentShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
#endif

private struct TVLeagueTeamCard: View {
    let team: ESPNTeam
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    TVTeamLogoBadge(team: team, size: 96, backgroundColor: Color(hex: team.primaryColor))
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isFavorite ? Color.yellow : Color.white.opacity(0.5))
                        .padding(5)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
                Text(team.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 180)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        #if os(tvOS)
        .buttonStyle(TVLeagueTeamCardButtonStyle())
        #endif
        .contextMenu {
            Button(isFavorite ? "Remove Favorite" : "Add Favorite") { onFavorite() }
        }
    }
}

#if os(tvOS)
/// Focus-aware ButtonStyle for TVLeagueTeamCard on tvOS.
/// Inner View pattern ensures @Environment(\.isFocused) resolves against the
/// Button's real focus state rather than a stale ancestor value.
private struct TVLeagueTeamCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Inner(configuration: configuration)
    }
    private struct Inner: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isFocused) private var isFocused
        var body: some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isFocused ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isFocused ? Color(hex: "8b6bff").opacity(0.95) : Color.white.opacity(0.06),
                            lineWidth: isFocused ? 2.5 : 1
                        )
                )
                .scaleEffect(configuration.isPressed ? 0.97 : (isFocused ? 1.07 : 1.0))
                .shadow(color: isFocused ? Color(hex: "8b6bff").opacity(0.38) : .clear, radius: 22, y: 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .contentShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}
#endif

private struct TVTeamLogoBadge: View {
    let team: ESPNTeam
    let size: CGFloat
    let backgroundColor: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            if let logoUrl = team.logoURL, let url = URL(string: logoUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Text(team.abbreviation)
                        .font(.system(size: size * 0.22, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: size * 0.56, height: size * 0.56)
            } else {
                Text(team.abbreviation)
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

private struct TVLiveGamesSection: View {
    let games: [(league: ESPNService.League, game: ESPNGame)]
    let broadcastService: BroadcastChannelService
    let onOpenTeam: (ESPNTeam, ESPNService.League) -> Void
    let onWatch: (Channel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("LIVE NOW")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.red)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(games.enumerated()), id: \.offset) { _, item in
                        TVLiveGameCard(
                            league: item.league,
                            game: item.game,
                            channel: broadcastService.findChannel(forBroadcast: item.game.broadcast),
                            onOpenTeam: onOpenTeam,
                            onWatch: onWatch
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
            .focusSection()
        }
    }
}

private struct TVLiveGameCard: View {
    let league: ESPNService.League
    let game: ESPNGame
    let channel: Channel?
    let onOpenTeam: (ESPNTeam, ESPNService.League) -> Void
    let onWatch: (Channel) -> Void

    var body: some View {
        Button {
            if let team = game.homeTeam?.team.asESPNTeam {
                onOpenTeam(team, league)
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(league.emoji) \(league.displayName)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.72))
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text(game.statusDetail ?? "LIVE")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.red)
                }

                VStack(alignment: .leading, spacing: 6) {
                    scoreRow(for: game.awayTeam)
                    scoreRow(for: game.homeTeam)
                }

                if let channel {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Watch \(channel.displayName)")
                            .lineLimit(1)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "6138f5"))
                    .padding(.top, 2)
                }
            }
            .padding(18)
            .frame(width: 320, alignment: .leading)
        }
        #if os(tvOS)
        .buttonStyle(TVLiveGameCardButtonStyle())
        #endif
        .contextMenu {
            if let channel {
                Button("Watch") { onWatch(channel) }
            }
            if let team = game.homeTeam?.team.asESPNTeam {
                Button("Open Team") { onOpenTeam(team, league) }
            }
        }
    }

    private func scoreRow(for competitor: ESPNCompetitor?) -> some View {
        HStack(spacing: 10) {
            // Team logo
            if let logo = competitor?.team.logo, let url = URL(string: logo) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Circle().fill(Color.white.opacity(0.1))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(competitor?.team.abbreviation ?? "?")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            Text(competitor?.team.abbreviation ?? "TBD")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Text(competitor?.scoreDisplay ?? "-")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#if os(tvOS)
/// Focus-aware ButtonStyle for TVLiveGameCard on tvOS.
/// Inner View pattern ensures @Environment(\.isFocused) resolves against the
/// Button's real focus state rather than a stale ancestor value.
private struct TVLiveGameCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Inner(configuration: configuration)
    }
    private struct Inner: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isFocused) private var isFocused
        var body: some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isFocused ? Color(hex: "8b6bff").opacity(0.10) : Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isFocused ? Color.white.opacity(0.45) : Color.white.opacity(0.06),
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .scaleEffect(configuration.isPressed ? 0.97 : (isFocused ? 1.04 : 1.0))
                .shadow(color: isFocused ? Color(hex: "8b6bff").opacity(0.35) : .clear, radius: 22, y: 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
                .contentShape(RoundedRectangle(cornerRadius: 18))
        }
    }
}
#endif

private struct TVTeamDetailSheet: View {
    let team: ESPNTeam
    let league: ESPNService.League
    let broadcastService: BroadcastChannelService
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onWatch: (Channel) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var schedule: [ESPNGame] = []
    @State private var teamDetails: ESPNTeamDetails?
    @State private var isLoading = true

    private var liveGame: ESPNGame? {
        schedule.first(where: { $0.isLive })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    actionRow
                    if let liveGame, let channel = broadcastService.findChannel(forBroadcast: liveGame.broadcast) {
                        liveGameBanner(game: liveGame, channel: channel)
                    }
                    if let details = teamDetails {
                        infoBlock(details: details)
                    }
                    scheduleBlock
                }
            }
            .background(Color(hex: "110c21").ignoresSafeArea())
            .navigationTitle(team.displayName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task { await loadData() }
    }

    private var header: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: team.primaryColor), Color(hex: team.primaryColor).opacity(0.3), Color(hex: "110c21")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 250)

            VStack(spacing: 12) {
                if let logoUrl = team.logoURL, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Circle().fill(Color.white.opacity(0.2))
                    }
                    .frame(width: 92, height: 92)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    TVTeamLogoBadge(team: team, size: 92, backgroundColor: .white)
                }

                Text(team.displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(league.displayName)
                    if let record = teamDetails?.recordSummary {
                        Text("•")
                        Text(record)
                            .fontWeight(.semibold)
                    }
                }
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.72))
            }
            .padding(.bottom, 22)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button(action: onToggleFavorite) {
                HStack {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                    Text(isFavorite ? "Following" : "Follow")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isFavorite ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isFavorite ? Color.yellow : Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            #if os(tvOS)
            .buttonStyle(.card)
            #endif
            if let nextGame = schedule.first(where: { $0.isScheduled || $0.isLive }),
               let channel = broadcastService.findChannel(forBroadcast: nextGame.broadcast) {
                Button {
                    onWatch(channel)
                } label: {
                    HStack {
                        Image(systemName: "tv")
                        Text(channel.displayName)
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "6138f5"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                #if os(tvOS)
                .buttonStyle(.card)
                #endif
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    private func infoBlock(details: ESPNTeamDetails) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Team Info")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            VStack(spacing: 10) {
                if let venue = details.venueName {
                    TVTeamInfoRow(label: "Venue", value: venue)
                }
                if let venueCity = details.venueCity {
                    TVTeamInfoRow(label: "Location", value: venueCity)
                }
                if let standing = details.standingSummary {
                    TVTeamInfoRow(label: "Standing", value: standing)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private var scheduleBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Schedule")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if !schedule.isEmpty {
                    Text("\(schedule.count) games")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else if schedule.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No upcoming games")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                let recentGames = schedule.filter { $0.isCompleted }
                let upcomingGames = schedule.filter { !$0.isCompleted }

                VStack(alignment: .leading, spacing: 12) {
                    if !recentGames.isEmpty {
                        Text("Recent Results")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                        VStack(spacing: 12) {
                            ForEach(recentGames) { game in
                                TVTeamScheduleRow(
                                    game: game,
                                    team: team,
                                    broadcastService: broadcastService,
                                    onWatch: onWatch
                                )
                            }
                        }
                    }

                    if !upcomingGames.isEmpty {
                        Text("Upcoming")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, recentGames.isEmpty ? 0 : 8)
                        VStack(spacing: 12) {
                            ForEach(upcomingGames) { game in
                                TVTeamScheduleRow(
                                    game: game,
                                    team: team,
                                    broadcastService: broadcastService,
                                    onWatch: onWatch
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    private func liveGameBanner(game: ESPNGame, channel: Channel) -> some View {
        Button {
            onWatch(channel)
        } label: {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.shortName ?? game.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("on \(channel.displayName)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                    Text("Watch")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(14)
            .background(Color.red.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.32), lineWidth: 1)
            )
        }
        #if os(tvOS)
        .buttonStyle(.card)
        #endif
    }

    private func loadData() async {
        async let detailsTask = try? ESPNService.shared.fetchTeamDetails(league: league, teamId: team.id)
        async let scheduleTask = try? ESPNService.shared.fetchTeamSchedule(league: league, teamId: team.id)
        teamDetails = await detailsTask
        if let games = await scheduleTask {
            let now = Date()
            let thirtyDaysAgo = now.addingTimeInterval(-30 * 24 * 3600)
            let recentPast = games
                .filter { game in
                    guard let gameDate = game.gameDate else { return false }
                    return gameDate < now && gameDate > thirtyDaysAgo
                }
                .sorted { ($0.gameDate ?? .distantPast) > ($1.gameDate ?? .distantPast) }
                .prefix(5)
            let upcoming = games
                .filter { game in
                    guard let gameDate = game.gameDate else { return false }
                    return gameDate >= now || game.isLive
                }
                .sorted { ($0.gameDate ?? .distantPast) < ($1.gameDate ?? .distantPast) }
                .prefix(10)
            schedule = Array(recentPast.reversed()) + Array(upcoming)
        } else {
            schedule = []
        }
        isLoading = false
    }
}

private struct TVTeamInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

private extension ESPNCompetitorTeam {
    var asESPNTeam: ESPNTeam {
        ESPNTeam(
            id: id,
            displayName: displayName,
            abbreviation: abbreviation,
            location: nil,
            logos: logos ?? (logoURL.map { [ESPNLogo(href: $0, width: nil, height: nil)] }),
            color: color,
            alternateColor: nil,
            links: nil
        )
    }
}

private struct TVTeamScheduleRow: View {
    let game: ESPNGame
    let team: ESPNTeam
    let broadcastService: BroadcastChannelService
    let onWatch: (Channel) -> Void

    @Environment(\.isFocused) private var isFocused

    private var opponent: ESPNCompetitor? {
        game.homeTeam?.team.id == team.id ? game.awayTeam : game.homeTeam
    }

    private var isHome: Bool {
        game.homeTeam?.team.id == team.id
    }

    private var matchingChannel: Channel? {
        broadcastService.findChannel(forBroadcast: game.broadcast)
    }

    var body: some View {
        Button {
            if let matchingChannel {
                onWatch(matchingChannel)
            }
        } label: {
            HStack(spacing: 14) {
                if let date = game.gameDate {
                    VStack(spacing: 2) {
                        Text(date.formatted(.dateTime.month(.abbreviated)))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Text(date.formatted(.dateTime.day()))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 45)
                }

                if let logo = opponent?.team.logo, let url = URL(string: logo) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                    }
                    .frame(width: 40, height: 40)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(isHome ? "vs" : "@") \(opponent?.team.displayName ?? "TBD")")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        if let date = game.gameDate {
                            Text(date.formatted(.dateTime.hour().minute()))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }

                        if let broadcast = game.broadcast {
                            Text("\u{2022}")
                                .foregroundColor(.gray)

                            HStack(spacing: 4) {
                                Text(broadcast)
                                    .font(.system(size: 12, weight: .medium))
                                if matchingChannel != nil {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                }
                            }
                            .foregroundColor(matchingChannel != nil ? Color(hex: "6138f5") : .gray)
                        } else {
                            Text("\u{2022}")
                                .foregroundColor(.gray)
                            Text("No channel")
                                .font(.system(size: 12))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                }

                Spacer()

                if game.isLive {
                    if matchingChannel != nil {
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("WATCH")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        HStack(spacing: 4) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("LIVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                } else if game.isCompleted {
                    if let home = game.homeTeam?.scoreDisplay, let away = game.awayTeam?.scoreDisplay {
                        VStack(spacing: 0) {
                            Text("FINAL")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.gray)
                            Text(isHome ? "\(home)-\(away)" : "\(away)-\(home)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("FINAL")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                } else if matchingChannel != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "6138f5"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(game.isLive && matchingChannel != nil ? Color.red.opacity(0.10) : (isFocused ? Color.white.opacity(0.08) : Color.white.opacity(0.05)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        game.isLive && matchingChannel != nil
                        ? Color.red.opacity(0.30)
                        : (isFocused ? Color.white.opacity(0.3) : Color.clear),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isFocused)
        }
        #if os(tvOS)
        .buttonStyle(.card)
        #endif
        .padding(.horizontal, 16)
    }
}

private struct TVManageFavoritesSheet: View {
    let favoriteTeams: [(team: ESPNTeam, league: ESPNService.League)]
    let onRemove: (ESPNTeam, ESPNService.League) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    Text("Manage My Teams")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "6138f5"))
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)

                if favoriteTeams.isEmpty {
                    Text("No favorite teams yet.")
                        .foregroundColor(.gray)
                        .padding(.vertical, 60)
                } else {
                    ForEach(favoriteTeams, id: \.team.id) { item in
                        HStack(spacing: 16) {
                            TVTeamLogoBadge(team: item.team, size: 50, backgroundColor: Color(hex: item.team.primaryColor))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.team.displayName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("\(item.league.emoji) \(item.league.displayName)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(role: .destructive) { onRemove(item.team, item.league) } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "minus.circle")
                                    Text("Remove")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            #if os(tvOS)
                            .buttonStyle(.card)
                            #endif
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
        .background(Color(red: 8/255, green: 10/255, blue: 24/255).ignoresSafeArea())
    }
}
#endif

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
    @Environment(\.isFocused) private var isFocused
    
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
    private let api = OpenFlixAPI.shared

    @Published var games: [SportsGame] = []
    @Published var favoriteTeams: [FavoriteTeam] = []
    @Published var isLoading = false
    @Published var showTeamPicker = false
    @Published var error: String?

    func loadGames() {
        isLoading = true
        error = nil
        Task {
            do {
                // Load team passes (user's followed teams)
                let passesResponse = try await api.getTeamPasses()
                favoriteTeams = passesResponse.teamPasses.map { dto in
                    FavoriteTeam(
                        id: String(dto.id),
                        name: dto.teamName,
                        sport: dto.league,
                        logo: dto.logoUrl
                    )
                }

                // Load upcoming games for each team pass concurrently
                var allGames: [SportsGame] = []
                await withTaskGroup(of: [SportsGame].self) { group in
                    for pass in passesResponse.teamPasses {
                        group.addTask { [api] in
                            do {
                                let upcoming = try await api.getTeamPassUpcoming(id: String(pass.id))
                                return upcoming.allGames.compactMap { item -> SportsGame? in
                                    guard let start = item.program.startDate else { return nil }
                                    let now = Date()
                                    let end = item.program.endDate ?? start.addingTimeInterval(3600)
                                    let isLive = start <= now && end > now
                                    // Parse teams from the program's teams field (format: "Team A vs Team B")
                                    let teams = item.program.teams?.components(separatedBy: " vs ") ?? [item.program.safeTitle, ""]
                                    let homeTeam = teams.count > 1 ? teams[1] : ""
                                    let awayTeam = teams.first ?? item.program.safeTitle
                                    return SportsGame(
                                        id: item.program.safeId.isEmpty ? "\(item.safeChannelId)-\(Int(start.timeIntervalSince1970))" : item.program.safeId,
                                        sport: item.program.league ?? pass.league,
                                        homeTeam: homeTeam,
                                        awayTeam: awayTeam,
                                        homeTeamLogo: nil,
                                        awayTeamLogo: nil,
                                        startTime: start,
                                        isLive: isLive,
                                        channelId: item.safeChannelId,
                                        channelName: item.safeChannelName
                                    )
                                }
                            } catch {
                                return []
                            }
                        }
                    }
                    for await teamGames in group {
                        allGames.append(contentsOf: teamGames)
                    }
                }

                // Sort by start time and deduplicate by id
                var seen = Set<String>()
                games = allGames
                    .sorted { $0.startTime < $1.startTime }
                    .filter { seen.insert($0.id).inserted }
            } catch {
                self.error = error.localizedDescription
            }
            isLoading = false
        }
    }

    func watchGame(_ game: SportsGame) {
        guard let channelId = game.channelId else { return }
        Task {
            if let url = await api.channelStreamURL(id: channelId) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("PlayLiveChannel"),
                    object: nil,
                    userInfo: ["url": url, "channelName": game.channelName ?? ""]
                )
            }
        }
    }

    func addTeam(_ team: FavoriteTeam) {
        Task {
            do {
                let _ = try await api.createTeamPass(teamName: team.name, league: team.sport)
                favoriteTeams.append(team)
                loadGames()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    func removeTeam(_ team: FavoriteTeam) {
        Task {
            do {
                try await api.deleteTeamPass(id: team.id)
                favoriteTeams.removeAll { $0.id == team.id }
                loadGames()
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

#Preview {
    TeamPassView()
}
