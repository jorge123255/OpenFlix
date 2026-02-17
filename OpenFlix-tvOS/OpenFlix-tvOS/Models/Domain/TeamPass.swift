import Foundation

// MARK: - Team Pass

struct TeamPass: Identifiable, Hashable {
    let id: Int
    let teamName: String
    let teamAliases: [String]
    let league: String
    let channelIds: [String]
    let prePadding: Int
    let postPadding: Int
    let keepCount: Int
    let priority: Int
    let enabled: Bool
    let upcomingCount: Int
    let logoUrl: String?

    var displayName: String {
        "\(teamName) (\(league))"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TeamPass, rhs: TeamPass) -> Bool {
        lhs.id == rhs.id
    }
}

extension TeamPassDTO {
    func toDomain() -> TeamPass {
        TeamPass(
            id: id,
            teamName: teamName,
            teamAliases: teamAliases?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } ?? [],
            league: league,
            channelIds: channelIds?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } ?? [],
            prePadding: prePadding ?? 5,
            postPadding: postPadding ?? 60,
            keepCount: keepCount ?? 0,
            priority: priority ?? 0,
            enabled: enabled ?? true,
            upcomingCount: upcomingCount ?? 0,
            logoUrl: logoUrl
        )
    }
}

// MARK: - Team

struct Team: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let aliases: [String]
    let logo: String?

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: Team, rhs: Team) -> Bool {
        lhs.name == rhs.name
    }
}

extension TeamDTO {
    func toDomain() -> Team {
        Team(
            name: name,
            aliases: aliases ?? [],
            logo: logo
        )
    }
}

// MARK: - On Later Stats

struct OnLaterStats {
    let movies: Int
    let sports: Int
    let kids: Int
    let news: Int
    let premieres: Int

    var total: Int {
        movies + sports + kids + news + premieres
    }
}

extension OnLaterStatsResponse {
    func toDomain() -> OnLaterStats {
        OnLaterStats(
            movies: movies,
            sports: sports,
            kids: kids,
            news: news,
            premieres: premieres
        )
    }
}

// MARK: - On Later Program

struct OnLaterProgram: Identifiable {
    var id: String { "\(channelId)-\(program.id)" }
    let channelId: String
    let channelName: String
    let channelLogo: String?
    let channelNumber: Int?
    let program: Program
}

extension OnLaterProgramDTO {
    func toDomain() -> OnLaterProgram {
        OnLaterProgram(
            channelId: channelId,
            channelName: channelName,
            channelLogo: channelLogo,
            channelNumber: channelNumber,
            program: program.toDomain()
        )
    }
}
