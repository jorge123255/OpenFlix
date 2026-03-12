import SwiftUI

// MARK: - Sports Team Model
struct SportsTeam: Identifiable, Codable {
    let id: String
    let name: String
    let abbreviation: String
    let logo: String?
    let league: String
    let conference: String?
    let division: String?
    let venue: String?
    let city: String?
    let coach: String?
    let colors: [String]?
    
    var primaryColor: Color {
        guard let hex = colors?.first else { return Color(hex: "6138f5") }
        return Color(hex: hex)
    }
}

// MARK: - Team Page View
// Xfinity-style team detail page

struct TeamPageView: View {
    let team: SportsTeam
    @Environment(\.dismiss) private var dismiss
    @State private var upcomingGames: [UpcomingGame] = []
    @State private var isLoading = true
    @State private var isFavorite = false
    
    // Favorite teams persistence
    @AppStorage("favoriteTeams") private var favoriteTeamsData: Data = Data()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header with team colors
                teamHeader
                
                // Quick actions
                actionButtons
                
                // Team info
                teamInfoSection
                
                // Upcoming games
                upcomingGamesSection
                
                // Related content
                relatedContentSection
            }
        }
        .background(Color(hex: "110c21"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .white)
                }
            }
        }
        .onAppear {
            loadFavoriteStatus()
            loadUpcomingGames()
        }
    }
    
    // MARK: - Team Header
    
    private var teamHeader: some View {
        ZStack(alignment: .bottom) {
            // Gradient background
            LinearGradient(
                colors: [team.primaryColor, team.primaryColor.opacity(0.3), Color(hex: "110c21")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)
            
            VStack(spacing: 12) {
                // Team logo
                if let logoUrl = team.logo, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 100)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Team name
                Text(team.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // League / Conference
                HStack(spacing: 8) {
                    Text(team.league)
                        .font(.system(size: 14, weight: .medium))
                    if let conference = team.conference {
                        Text("•")
                        Text(conference)
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            ActionButton(title: "Watch", icon: "play.fill", isPrimary: true) {
                // TODO: Navigate to live game if available
            }
            
            ActionButton(title: isFavorite ? "Following" : "Follow", icon: isFavorite ? "checkmark" : "plus") {
                toggleFavorite()
            }
            
            ActionButton(title: "Schedule", icon: "calendar") {
                // TODO: Show full schedule
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
    
    // MARK: - Team Info Section
    
    private var teamInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Info")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if let coach = team.coach {
                    InfoRow(label: "Coach", value: coach)
                }
                if let venue = team.venue {
                    InfoRow(label: "Venue", value: venue)
                }
                if let city = team.city {
                    InfoRow(label: "Location", value: city)
                }
                if let division = team.division {
                    InfoRow(label: "Division", value: division)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    
    // MARK: - Upcoming Games
    
    private var upcomingGamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Upcoming Games")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {
                    // TODO: Full schedule view
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "6138f5"))
            }
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
                .padding(.vertical, 32)
            } else if upcomingGames.isEmpty {
                Text("No upcoming games scheduled")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .padding(.vertical, 24)
            } else {
                ForEach(upcomingGames) { game in
                    GameRow(game: game, team: team)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
    
    // MARK: - Related Content
    
    private var relatedContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Content")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4) { _ in
                        RelatedContentCard()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
    }
    
    // MARK: - Helpers
    
    private func loadFavoriteStatus() {
        if let decoded = try? JSONDecoder().decode([String].self, from: favoriteTeamsData) {
            isFavorite = decoded.contains(team.id)
        }
    }
    
    private func toggleFavorite() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        var favorites: [String] = []
        if let decoded = try? JSONDecoder().decode([String].self, from: favoriteTeamsData) {
            favorites = decoded
        }
        
        let isRemoving = isFavorite
        if isFavorite {
            favorites.removeAll { $0 == team.id }
        } else {
            favorites.append(team.id)
        }
        
        isFavorite.toggle()
        
        if let encoded = try? JSONEncoder().encode(favorites) {
            favoriteTeamsData = encoded
        }
        
        Task {
            let api = OpenFlixAPI.shared
            if isRemoving {
                if let passesResponse = try? await api.getTeamPasses(),
                   let matchingPass = passesResponse.teamPasses.first(where: {
                       $0.teamName.localizedCaseInsensitiveCompare(team.name) == .orderedSame
                   }) {
                    try? await api.deleteTeamPass(id: String(matchingPass.id))
                }
            } else {
                _ = try? await api.createTeamPass(teamName: team.name, league: team.league)
            }
            await MainActor.run {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    private func loadUpcomingGames() {
        let api = OpenFlixAPI.shared
        Task {
            do {
                // Search for a team pass matching this team, then fetch upcoming
                let passesResponse = try await api.getTeamPasses()
                if let matchingPass = passesResponse.teamPasses.first(where: {
                    $0.teamName.localizedCaseInsensitiveContains(team.name) ||
                    team.name.localizedCaseInsensitiveContains($0.teamName)
                }) {
                    let upcoming = try await api.getTeamPassUpcoming(id: String(matchingPass.id))
                    await MainActor.run {
                        upcomingGames = upcoming.allGames.compactMap { item -> UpcomingGame? in
                            guard let start = item.program.startDate else { return nil }
                            // Determine opponent from teams field
                            let teams = item.program.teams?.components(separatedBy: " vs ") ?? []
                            let opponent = teams.first(where: {
                                !$0.localizedCaseInsensitiveContains(team.name)
                            }) ?? item.program.safeTitle
                            let isHome = teams.count > 1 && teams[1].localizedCaseInsensitiveContains(team.name)
                            return UpcomingGame(
                                id: item.program.safeId.isEmpty ? "\(Int(start.timeIntervalSince1970))" : item.program.safeId,
                                opponent: opponent,
                                date: start,
                                isHome: isHome,
                                channel: item.safeChannelName.isEmpty ? nil : item.safeChannelName
                            )
                        }
                        isLoading = false
                    }
                } else {
                    // No team pass found, try On Later sports filtered by team name
                    let onLater = try await api.getOnLaterSports(team: team.name)
                    await MainActor.run {
                        upcomingGames = onLater.allItems.compactMap { item -> UpcomingGame? in
                            guard let start = item.program.startDate else { return nil }
                            let teams = item.program.teams?.components(separatedBy: " vs ") ?? []
                            let opponent = teams.first(where: {
                                !$0.localizedCaseInsensitiveContains(team.name)
                            }) ?? item.program.safeTitle
                            let isHome = teams.count > 1 && teams[1].localizedCaseInsensitiveContains(team.name)
                            return UpcomingGame(
                                id: item.program.safeId.isEmpty ? "\(Int(start.timeIntervalSince1970))" : item.program.safeId,
                                opponent: opponent,
                                date: start,
                                isHome: isHome,
                                channel: item.safeChannelName.isEmpty ? nil : item.safeChannelName
                            )
                        }
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Upcoming Game Model

struct UpcomingGame: Identifiable {
    let id: String
    let opponent: String
    let date: Date
    let isHome: Bool
    let channel: String?
}

// MARK: - Action Button

private struct ActionButton: View {
    let title: String
    let icon: String
    var isPrimary: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isPrimary ? .white : Color(hex: "6138f5"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isPrimary ? Color(hex: "6138f5") : Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Info Row

private struct InfoRow: View {
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

// MARK: - Game Row

private struct GameRow: View {
    let game: UpcomingGame
    let team: SportsTeam
    
    var body: some View {
        HStack(spacing: 16) {
            // Date
            VStack(spacing: 2) {
                Text(game.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(game.date.formatted(.dateTime.day()))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 50)
            
            // Game info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.isHome ? "vs \(game.opponent)" : "@ \(game.opponent)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(game.date.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    
                    if let channel = game.channel {
                        Text("•")
                            .foregroundColor(.gray)
                        Text(channel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "6138f5"))
                    }
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Related Content Card

private struct RelatedContentCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 160, height: 90)
                .overlay(
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                )
            
            Text("Highlights")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            
            Text("2 hours ago")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    NavigationStack {
        TeamPageView(team: SportsTeam(
            id: "bulls",
            name: "Chicago Bulls",
            abbreviation: "CHI",
            logo: nil,
            league: "NBA",
            conference: "Eastern",
            division: "Central",
            venue: "United Center",
            city: "Chicago, IL",
            coach: "Billy Donovan",
            colors: ["CE1141", "000000"]
        ))
    }
}
