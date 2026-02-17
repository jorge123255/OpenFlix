import Foundation

// MARK: - Recording Status

enum RecordingStatus: String, Codable {
    case scheduled
    case recording
    case completed
    case failed

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .recording: return "Recording"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    var icon: String {
        switch self {
        case .scheduled: return "clock"
        case .recording: return "record.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.circle.fill"
        }
    }
}

// MARK: - Recording

struct Recording: Identifiable, Hashable {
    let id: Int
    let title: String
    let subtitle: String?
    let description: String?
    let thumb: String?
    let art: String?
    let channelId: String?
    let channelName: String?
    let channelLogo: String?
    let startTime: Date
    let endTime: Date
    let duration: Int               // milliseconds
    let status: RecordingStatus
    let filePath: String?
    let fileSize: Int?
    let seasonNumber: Int?
    let episodeNumber: Int?
    let seriesRecord: Bool
    let seriesRuleId: Int?
    let genres: [String]
    let contentRating: String?
    let year: Int?
    let rating: Double?
    let isMovie: Bool
    let viewOffset: Int?            // milliseconds
    let commercials: [Commercial]
    let priority: Int

    // MARK: - Computed Properties

    var durationFormatted: String {
        String.formatDuration(milliseconds: duration)
    }

    var fileSizeFormatted: String? {
        guard let size = fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var timeRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    var episodeLabel: String? {
        guard let season = seasonNumber, let episode = episodeNumber else { return nil }
        return "S\(season) E\(episode)"
    }

    var fullTitle: String {
        if let label = episodeLabel, let subtitle = subtitle {
            return "\(title) - \(label) - \(subtitle)"
        } else if let subtitle = subtitle {
            return "\(title): \(subtitle)"
        }
        return title
    }

    var progressPercent: Double {
        guard duration > 0, let offset = viewOffset else { return 0 }
        return Double(offset) / Double(duration)
    }

    var isInProgress: Bool {
        progressPercent > 0 && progressPercent < 0.9
    }

    var isUpcoming: Bool {
        status == .scheduled && startTime > Date()
    }

    var isCurrentlyRecording: Bool {
        status == .recording
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Recording, rhs: Recording) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Commercial

struct Commercial: Identifiable {
    var id: String { "\(start)-\(end)" }
    let start: Int          // milliseconds
    let end: Int            // milliseconds

    var duration: Int {
        end - start
    }

    var startSeconds: Int {
        start / 1000
    }

    var endSeconds: Int {
        end / 1000
    }
}

// MARK: - DTO Mapping

extension RecordingDTO {
    func toDomain() -> Recording {
        Recording(
            id: safeId,
            title: safeTitle,
            subtitle: subtitle,
            description: description ?? summary,
            thumb: thumb,
            art: art,
            channelId: channelId?.stringValue,
            channelName: channelName,
            channelLogo: channelLogo,
            startTime: startDate ?? Date(),
            endTime: endDate ?? Date(),
            duration: duration ?? 0,
            status: RecordingStatus(rawValue: safeStatus) ?? .scheduled,
            filePath: filePath,
            fileSize: fileSize,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            seriesRecord: seriesRecord ?? false,
            seriesRuleId: seriesRuleId,
            genres: genres?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } ?? [],
            contentRating: contentRating,
            year: year,
            rating: rating,
            isMovie: isMovie ?? false,
            viewOffset: viewOffset,
            commercials: commercials?.map { Commercial(start: $0.start, end: $0.end) } ?? [],
            priority: priority ?? 50
        )
    }
}

// MARK: - Series Rule

struct SeriesRule: Identifiable {
    let id: Int
    let title: String
    let channelId: String?
    let enabled: Bool
    let prePadding: Int
    let postPadding: Int
    let keepCount: Int
    let recordingCount: Int
}

extension SeriesRuleDTO {
    func toDomain() -> SeriesRule {
        SeriesRule(
            id: safeId,
            title: safeTitle,
            channelId: channelId?.stringValue,
            enabled: enabled ?? true,
            prePadding: prePadding ?? 0,
            postPadding: postPadding ?? 0,
            keepCount: keepCount ?? 0,
            recordingCount: recordingCount ?? 0
        )
    }
}
