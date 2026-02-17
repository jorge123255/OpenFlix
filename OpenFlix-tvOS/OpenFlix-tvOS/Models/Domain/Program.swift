import Foundation

// MARK: - Program

struct Program: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let description: String?
    let startTime: Date
    let endTime: Date
    let duration: Int              // minutes
    let icon: String?
    let art: String?
    let rating: String?
    let category: String?
    let isNew: Bool
    let isLive: Bool
    let isPremiere: Bool
    let isFinale: Bool
    let isSports: Bool
    let isKids: Bool
    let teams: String?
    let league: String?
    let hasRecording: Bool
    let recordingId: String?

    // MARK: - Computed Properties

    var isCurrentlyAiring: Bool {
        let now = Date()
        return startTime <= now && endTime > now
    }

    var hasStarted: Bool {
        Date() >= startTime
    }

    var hasEnded: Bool {
        Date() >= endTime
    }

    var progress: Double {
        guard isCurrentlyAiring else { return hasEnded ? 1.0 : 0.0 }
        let totalDuration = endTime.timeIntervalSince(startTime)
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1.0, max(0.0, elapsed / totalDuration))
    }

    var remainingMinutes: Int {
        guard !hasEnded else { return 0 }
        return Int(endTime.timeIntervalSince(Date()) / 60)
    }

    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    var startTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    var fullTitle: String {
        if let subtitle = subtitle, !subtitle.isEmpty {
            return "\(title): \(subtitle)"
        }
        return title
    }

    var badges: [String] {
        var result: [String] = []
        if isNew { result.append("NEW") }
        if isLive { result.append("LIVE") }
        if isPremiere { result.append("PREMIERE") }
        if isFinale { result.append("FINALE") }
        if hasRecording { result.append("REC") }
        return result
    }

    var categoryIcon: String {
        switch category?.lowercased() {
        case "movie": return "film"
        case "tvshow", "series": return "tv"
        case "sports": return "sportscourt"
        case "news": return "newspaper"
        case "kids", "children": return "figure.2.and.child.holdinghands"
        case "documentary": return "doc.text"
        case "music": return "music.note"
        default: return "play.rectangle"
        }
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Program, rhs: Program) -> Bool {
        lhs.id == rhs.id && lhs.startTime == rhs.startTime
    }
}

// MARK: - DTO Mapping

extension ProgramDTO {
    func toDomain() -> Program {
        let start = startDate ?? Date()
        let end = endDate ?? start.addingTimeInterval(TimeInterval((duration ?? 30) * 60))

        return Program(
            id: safeId.isEmpty ? UUID().uuidString : safeId,
            title: safeTitle,
            subtitle: subtitle,
            description: description,
            startTime: start,
            endTime: end,
            duration: duration ?? Int(end.timeIntervalSince(start) / 60),
            icon: icon,
            art: art,
            rating: rating,
            category: category,
            isNew: isNew ?? false,
            isLive: isLive ?? false,
            isPremiere: isPremiere ?? false,
            isFinale: isFinale ?? false,
            isSports: isSports ?? false,
            isKids: isKids ?? false,
            teams: teams,
            league: league,
            hasRecording: hasRecording ?? false,
            recordingId: recordingId?.stringValue
        )
    }
}

// MARK: - Channel with Programs (for EPG)

struct ChannelWithPrograms: Identifiable {
    var id: String { channel.id }
    let channel: Channel
    var programs: [Program]

    func program(at date: Date) -> Program? {
        programs.first { $0.startTime <= date && $0.endTime > date }
    }

    var currentProgram: Program? {
        program(at: Date())
    }

    var upcomingPrograms: [Program] {
        let now = Date()
        return programs.filter { $0.startTime > now }.sorted { $0.startTime < $1.startTime }
    }
}
