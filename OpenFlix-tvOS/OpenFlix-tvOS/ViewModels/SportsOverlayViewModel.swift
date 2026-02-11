import Foundation
import Combine

/// Live game data from ESPN
struct LiveGame: Codable, Identifiable {
    let id: String
    let sport: String
    let league: String
    let status: String
    let homeTeam: Team
    let awayTeam: Team
    let homeScore: Int
    let awayScore: Int
    let period: String
    let clock: String
    let startTime: Date?
    let lastUpdated: Date?
    let isClose: Bool
    let isRedZone: Bool
    let possession: String?
    let broadcastInfo: String?

    enum CodingKeys: String, CodingKey {
        case id, sport, league, status
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case homeScore = "home_score"
        case awayScore = "away_score"
        case period, clock
        case startTime = "start_time"
        case lastUpdated = "last_updated"
        case isClose = "is_close"
        case isRedZone = "is_red_zone"
        case possession
        case broadcastInfo = "broadcast_info"
    }

    var isLive: Bool {
        status == "live"
    }

    var displayScore: String {
        "\(awayTeam.code) \(awayScore) - \(homeScore) \(homeTeam.code)"
    }

    var shortDisplay: String {
        "\(awayTeam.code) \(awayScore)-\(homeScore) \(homeTeam.code)"
    }
}

struct Team: Codable {
    let code: String
    let name: String
    let fullName: String?
    let logo: String?
    let record: String?
    let rank: Int?
    let conference: String?

    enum CodingKeys: String, CodingKey {
        case code, name
        case fullName = "full_name"
        case logo, record, rank, conference
    }
}

struct OverlayData: Codable {
    let games: [LiveGame]
    let lastUpdated: Date?
    let favoriteCount: Int

    enum CodingKeys: String, CodingKey {
        case games
        case lastUpdated = "last_updated"
        case favoriteCount = "favorite_count"
    }
}

@MainActor
class SportsOverlayViewModel: ObservableObject {
    @Published var games: [LiveGame] = []
    @Published var isLoading = false
    @Published var isVisible = false
    @Published var favoriteTeams: [String] = []
    @Published var error: String?

    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 30 // Update every 30s

    init() {
        loadFavorites()
    }

    // MARK: - Public API

    func startUpdates() {
        fetchScores()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.fetchScores()
            }
        }
    }

    func stopUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func toggleVisibility() {
        isVisible.toggle()
        if isVisible {
            startUpdates()
        } else {
            stopUpdates()
        }
    }

    func setFavorites(_ teams: [String]) {
        favoriteTeams = teams
        saveFavorites()
        updateFavoritesOnServer()
    }

    func addFavorite(_ teamCode: String) {
        if !favoriteTeams.contains(teamCode) {
            favoriteTeams.append(teamCode)
            saveFavorites()
            updateFavoritesOnServer()
        }
    }

    func removeFavorite(_ teamCode: String) {
        favoriteTeams.removeAll { $0 == teamCode }
        saveFavorites()
        updateFavoritesOnServer()
    }

    // MARK: - API Calls

    private func fetchScores() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                let overlay = try await fetchOverlayData()
                self.games = overlay.games
                self.error = nil
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func fetchOverlayData() async throws -> OverlayData {
        guard let serverURL = UserDefaults.standard.string(forKey: "serverURL"),
              let url = URL(string: "\(serverURL)/api/sports/overlay?max=5") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, _) = try await URLSession.shared.data(for: request)

        struct Response: Codable {
            let success: Bool
            let overlay: OverlayData
        }

        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.overlay
    }

    private func updateFavoritesOnServer() {
        Task {
            guard let serverURL = UserDefaults.standard.string(forKey: "serverURL"),
                  let url = URL(string: "\(serverURL)/api/sports/favorites") else {
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let token = UserDefaults.standard.string(forKey: "authToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let body = ["teams": favoriteTeams]
            request.httpBody = try? JSONEncoder().encode(body)

            _ = try? await URLSession.shared.data(for: request)
        }
    }

    // MARK: - Persistence

    private func saveFavorites() {
        UserDefaults.standard.set(favoriteTeams, forKey: "sportsOverlayFavorites")
    }

    private func loadFavorites() {
        favoriteTeams = UserDefaults.standard.stringArray(forKey: "sportsOverlayFavorites") ?? []
    }
}
