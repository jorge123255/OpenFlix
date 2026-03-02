import Foundation

// MARK: - ESPN API Service
// Free public ESPN API for sports data

class ESPNService: ObservableObject {
    static let shared = ESPNService()
    
    private let baseURL = "https://site.api.espn.com/apis/site/v2/sports"
    
    // League mappings
    enum League: String, CaseIterable {
        case nfl = "football/nfl"
        case nba = "basketball/nba"
        case mlb = "baseball/mlb"
        case nhl = "hockey/nhl"
        case mls = "soccer/usa.1"
        case ncaaf = "football/college-football"
        case ncaab = "basketball/mens-college-basketball"
        
        var displayName: String {
            switch self {
            case .nfl: return "NFL"
            case .nba: return "NBA"
            case .mlb: return "MLB"
            case .nhl: return "NHL"
            case .mls: return "MLS"
            case .ncaaf: return "NCAAF"
            case .ncaab: return "NCAAB"
            }
        }
        
        var emoji: String {
            switch self {
            case .nfl, .ncaaf: return "🏈"
            case .nba, .ncaab: return "🏀"
            case .mlb: return "⚾"
            case .nhl: return "🏒"
            case .mls: return "⚽"
            }
        }
    }
    
    // MARK: - Fetch All Teams for a League
    
    func fetchTeams(league: League) async throws -> [ESPNTeam] {
        let url = URL(string: "\(baseURL)/\(league.rawValue)/teams?limit=100")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ESPNTeamsResponse.self, from: data)
        return response.sports.first?.leagues.first?.teams.map { $0.team } ?? []
    }
    
    // MARK: - Fetch Scoreboard (Live Games)
    
    func fetchScoreboard(league: League) async throws -> [ESPNGame] {
        let url = URL(string: "\(baseURL)/\(league.rawValue)/scoreboard")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ESPNScoreboardResponse.self, from: data)
        return response.events
    }
    
    // MARK: - Fetch Team Schedule
    
    func fetchTeamSchedule(league: League, teamId: String) async throws -> [ESPNGame] {
        let url = URL(string: "\(baseURL)/\(league.rawValue)/teams/\(teamId)/schedule")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ESPNScheduleResponse.self, from: data)
        return response.events
    }
    
    // MARK: - Fetch Team Details
    
    func fetchTeamDetails(league: League, teamId: String) async throws -> ESPNTeamDetails? {
        let url = URL(string: "\(baseURL)/\(league.rawValue)/teams/\(teamId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ESPNTeamDetailsResponse.self, from: data)
        return response.team
    }
    
    // MARK: - Fetch All Live Scores
    
    func fetchAllLiveScores() async -> [String: [ESPNGame]] {
        var results: [String: [ESPNGame]] = [:]
        
        await withTaskGroup(of: (League, [ESPNGame]?).self) { group in
            for league in [League.nfl, .nba, .mlb, .nhl, .mls] {
                group.addTask {
                    let games = try? await self.fetchScoreboard(league: league)
                    return (league, games)
                }
            }
            
            for await (league, games) in group {
                if let games = games, !games.isEmpty {
                    results[league.displayName] = games
                }
            }
        }
        
        return results
    }
}

// MARK: - ESPN API Response Models

struct ESPNTeamsResponse: Codable {
    let sports: [ESPNSport]
}

struct ESPNSport: Codable {
    let leagues: [ESPNLeague]
}

struct ESPNLeague: Codable {
    let teams: [ESPNTeamWrapper]
}

struct ESPNTeamWrapper: Codable {
    let team: ESPNTeam
}

struct ESPNTeam: Codable, Identifiable {
    let id: String
    let displayName: String
    let abbreviation: String
    let location: String?
    let logos: [ESPNLogo]?
    let color: String?
    let alternateColor: String?
    let links: [ESPNLink]?
    
    var logoURL: String? {
        logos?.first?.href
    }
    
    var primaryColor: String {
        color ?? "6138f5"
    }
}

struct ESPNLogo: Codable {
    let href: String
    let width: Int?
    let height: Int?
}

struct ESPNLink: Codable {
    let rel: [String]?
    let href: String
}

// MARK: - Scoreboard Response

struct ESPNScoreboardResponse: Codable {
    let events: [ESPNGame]
}

struct ESPNScheduleResponse: Codable {
    let events: [ESPNGame]
}

struct ESPNGame: Codable, Identifiable {
    let id: String
    let name: String
    let shortName: String?
    let date: String
    let status: ESPNGameStatus?
    let competitions: [ESPNCompetition]
    
    var homeTeam: ESPNCompetitor? {
        competitions.first?.competitors.first { $0.homeAway == "home" }
    }
    
    var awayTeam: ESPNCompetitor? {
        competitions.first?.competitors.first { $0.homeAway == "away" }
    }
    
    // Get status from competition if top-level is nil
    private var effectiveStatus: ESPNGameStatus? {
        status ?? competitions.first?.status
    }
    
    var isLive: Bool {
        effectiveStatus?.type.state == "in"
    }
    
    var isCompleted: Bool {
        effectiveStatus?.type.state == "post"
    }
    
    var isScheduled: Bool {
        effectiveStatus?.type.state == "pre"
    }
    
    var statusDetail: String? {
        effectiveStatus?.type.shortDetail
    }
    
    var gameDate: Date? {
        // ESPN returns dates without seconds (e.g., "2026-02-20T01:00Z")
        // ISO8601DateFormatter doesn't handle this, so use DateFormatter
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(identifier: "UTC")
        
        // Try without seconds first (ESPN format)
        df.dateFormat = "yyyy-MM-dd'T'HH:mmX"
        if let date = df.date(from: date) {
            return date
        }
        
        // Try with seconds
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssX"
        return df.date(from: date)
    }
    
    var broadcast: String? {
        // Try new format first (media.shortName)
        if let broadcasts = competitions.first?.broadcasts,
           let first = broadcasts.first(where: { $0.type?.shortName == "TV" }) ?? broadcasts.first {
            return first.media?.shortName
        }
        // Fallback to old format
        return competitions.first?.broadcasts?.first?.names?.first
    }
    
    var venue: String? {
        competitions.first?.venue?.fullName
    }
}

struct ESPNGameStatus: Codable {
    let type: ESPNStatusType
    let displayClock: String?
    let period: Int?
}

struct ESPNStatusType: Codable {
    let id: String
    let name: String
    let state: String  // "pre", "in", "post"
    let completed: Bool
    let description: String?
    let detail: String?
    let shortDetail: String?
}

struct ESPNCompetition: Codable {
    let competitors: [ESPNCompetitor]
    let broadcasts: [ESPNBroadcast]?
    let venue: ESPNVenue?
    let status: ESPNGameStatus?
}

struct ESPNCompetitor: Codable {
    let id: String
    let homeAway: String
    let score: ESPNScore?
    let team: ESPNCompetitorTeam
    let winner: Bool?
    
    var scoreDisplay: String? {
        score?.displayValue
    }
}

struct ESPNScore: Codable {
    let value: Double?
    let displayValue: String?
}

struct ESPNCompetitorTeam: Codable {
    let id: String
    let displayName: String
    let abbreviation: String
    let logo: String?
    let logos: [ESPNLogo]?
    let color: String?
    
    // Get logo from either field
    var logoURL: String? {
        logo ?? logos?.first?.href
    }
}

struct ESPNBroadcast: Codable {
    let names: [String]?
    let type: ESPNBroadcastType?
    let media: ESPNBroadcastMedia?
}

struct ESPNBroadcastType: Codable {
    let id: String?
    let shortName: String?
}

struct ESPNBroadcastMedia: Codable {
    let shortName: String?
}

struct ESPNVenue: Codable {
    let fullName: String?
    let city: String?
    let state: String?
}

// MARK: - Team Details Response

struct ESPNTeamDetailsResponse: Codable {
    let team: ESPNTeamDetails
}

struct ESPNTeamDetails: Codable {
    let id: String
    let displayName: String
    let abbreviation: String
    let location: String?
    let logos: [ESPNLogo]?
    let color: String?
    let record: ESPNTeamRecord?
    let franchise: ESPNFranchise?
    let standingSummary: String?
    
    var logoURL: String? { logos?.first?.href }
    var venueName: String? { franchise?.venue?.fullName }
    var venueCity: String? {
        if let city = franchise?.venue?.address?.city,
           let state = franchise?.venue?.address?.state {
            return "\(city), \(state)"
        }
        return franchise?.venue?.address?.city
    }
    var recordSummary: String? { record?.items?.first?.summary }
}

struct ESPNTeamRecord: Codable {
    let items: [ESPNRecordItem]?
}

struct ESPNRecordItem: Codable {
    let summary: String?
    let stats: [ESPNRecordStat]?
}

struct ESPNRecordStat: Codable {
    let name: String?
    let value: Double?
}

struct ESPNFranchise: Codable {
    let venue: ESPNDetailedVenue?
}

struct ESPNDetailedVenue: Codable {
    let id: String?
    let fullName: String?
    let shortName: String?
    let address: ESPNAddress?
    let grass: Bool?
    let indoor: Bool?
}

struct ESPNAddress: Codable {
    let city: String?
    let state: String?
}
