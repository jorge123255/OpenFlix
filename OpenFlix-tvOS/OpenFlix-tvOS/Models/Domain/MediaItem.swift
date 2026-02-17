import Foundation

// MARK: - Media Type

enum MediaType: String, Codable {
    case movie
    case show
    case season
    case episode
    case artist
    case album
    case track
    case photo

    var displayName: String {
        switch self {
        case .movie: return "Movie"
        case .show: return "TV Show"
        case .season: return "Season"
        case .episode: return "Episode"
        case .artist: return "Artist"
        case .album: return "Album"
        case .track: return "Track"
        case .photo: return "Photo"
        }
    }
}

// MARK: - Media Item

struct MediaItem: Identifiable, Hashable {
    let id: Int
    let key: String
    let guid: String?               // Plex GUID for external ID matching (e.g., "tmdb://12345")
    let type: MediaType
    let title: String
    let originalTitle: String?
    let tagline: String?
    let summary: String?
    let thumb: String?
    let art: String?
    let banner: String?
    let year: Int?
    let duration: Int?              // milliseconds
    let viewOffset: Int?            // milliseconds
    let viewCount: Int?
    let contentRating: String?
    let audienceRating: Double?
    let rating: Double?
    let studio: String?
    let addedAt: Date?
    let originallyAvailableAt: String?

    // TV Show specific
    let leafCount: Int?             // total episodes
    let viewedLeafCount: Int?       // watched episodes
    let childCount: Int?            // season count

    // Episode/Season specific
    let index: Int?                 // episode/season number
    let parentIndex: Int?           // season number for episodes
    let parentRatingKey: Int?
    let parentTitle: String?
    let grandparentRatingKey: Int?
    let grandparentTitle: String?
    let grandparentThumb: String?

    // Metadata
    let genres: [String]
    let roles: [CastMember]
    let directors: [String]
    let writers: [String]
    let countries: [String]

    // Media versions
    let mediaVersions: [MediaVersion]

    // MARK: - Computed Properties

    var durationFormatted: String {
        guard let duration = duration else { return "" }
        return String.formatDuration(milliseconds: duration)
    }

    var progressPercent: Double {
        guard let duration = duration, let offset = viewOffset, duration > 0 else { return 0 }
        return Double(offset) / Double(duration)
    }

    var progress: Double {
        progressPercent
    }

    var remainingDuration: Int? {
        guard let duration = duration else { return nil }
        let offset = viewOffset ?? 0
        return max(0, duration - offset)
    }

    var isWatched: Bool {
        (viewCount ?? 0) > 0
    }

    var isInProgress: Bool {
        guard let offset = viewOffset, offset > 0 else { return false }
        return progressPercent < 0.9
    }

    var isRecentlyAdded: Bool {
        guard let addedAt = addedAt else { return false }
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return addedAt > sevenDaysAgo
    }

    var episodeLabel: String? {
        guard type == .episode,
              let seasonNum = parentIndex,
              let episodeNum = index else { return nil }
        return "S\(seasonNum) E\(episodeNum)"
    }

    var fullTitle: String {
        switch type {
        case .episode:
            if let showTitle = grandparentTitle ?? parentTitle, let label = episodeLabel {
                return "\(showTitle) - \(label) - \(title)"
            }
            return title
        case .season:
            if let showTitle = parentTitle {
                return "\(showTitle) - Season \(index ?? 0)"
            }
            return title
        default:
            return title
        }
    }

    var bestThumb: String? {
        switch type {
        case .episode:
            return thumb ?? grandparentThumb
        default:
            return thumb
        }
    }

    var primaryStream: MediaStream? {
        mediaVersions.first?.parts.first?.streams.first { $0.type == .video }
    }

    var resolution: String? {
        if let stream = primaryStream {
            if let height = stream.height {
                if height >= 2160 { return "4K" }
                if height >= 1080 { return "1080p" }
                if height >= 720 { return "720p" }
                return "\(height)p"
            }
        }
        return mediaVersions.first?.resolution
    }

    var audioChannels: String? {
        if let channels = mediaVersions.first?.audioChannels {
            switch channels {
            case 8: return "7.1"
            case 6: return "5.1"
            case 2: return "Stereo"
            case 1: return "Mono"
            default: return "\(channels) ch"
            }
        }
        return nil
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Cast Member

struct CastMember: Identifiable, Hashable {
    let id: Int?
    let name: String
    let role: String?
    let thumb: String?
}

// MARK: - Media Version

struct MediaVersion: Identifiable {
    let id: Int
    let duration: Int?
    let bitrate: Int?
    let width: Int?
    let height: Int?
    let audioChannels: Int?
    let audioCodec: String?
    let videoCodec: String?
    let resolution: String?
    let container: String?
    let parts: [MediaPart]
}

struct MediaPart: Identifiable {
    let id: Int
    let key: String
    let duration: Int?
    let file: String?
    let size: Int?
    let container: String?
    let streams: [MediaStream]
}

// MARK: - Media Stream

enum StreamType: Int {
    case video = 1
    case audio = 2
    case subtitle = 3
}

struct MediaStream: Identifiable {
    let id: Int
    let type: StreamType
    let codec: String?
    let index: Int?
    let language: String?
    let languageCode: String?
    let displayTitle: String?
    let selected: Bool
    let forced: Bool
    let isDefault: Bool
    let title: String?
    // Video
    let width: Int?
    let height: Int?
    let bitrate: Int?
    let frameRate: Double?
    // Audio
    let channels: Int?
    let samplingRate: Int?
}

// MARK: - DTO to Domain Mapping

extension MediaItemDTO {
    func toDomain() -> MediaItem {
        MediaItem(
            id: ratingKeyInt,
            key: safeKey,
            guid: guid,
            type: MediaType(rawValue: safeType) ?? .movie,
            title: safeTitle,
            originalTitle: originalTitle,
            tagline: tagline,
            summary: summary,
            thumb: thumb,
            art: art,
            banner: banner,
            year: year,
            duration: duration,
            viewOffset: viewOffset,
            viewCount: viewCount,
            contentRating: contentRating,
            audienceRating: audienceRating,
            rating: rating,
            studio: studio,
            addedAt: addedAt != nil ? Date(timeIntervalSince1970: TimeInterval(addedAt!)) : nil,
            originallyAvailableAt: originallyAvailableAt,
            leafCount: leafCount,
            viewedLeafCount: viewedLeafCount,
            childCount: childCount,
            index: index,
            parentIndex: parentIndex,
            parentRatingKey: parentRatingKey?.intValue,
            parentTitle: parentTitle,
            grandparentRatingKey: grandparentRatingKey?.intValue,
            grandparentTitle: grandparentTitle,
            grandparentThumb: grandparentThumb,
            genres: Genre?.map { $0.tag } ?? [],
            roles: Role?.map { CastMember(id: $0.id, name: $0.tag, role: $0.role, thumb: $0.thumb) } ?? [],
            directors: Director?.map { $0.tag } ?? [],
            writers: Writer?.map { $0.tag } ?? [],
            countries: Country?.map { $0.tag } ?? [],
            mediaVersions: Media?.map { $0.toDomain() } ?? []
        )
    }
}

extension MediaVersionDTO {
    func toDomain() -> MediaVersion {
        MediaVersion(
            id: safeId,
            duration: duration,
            bitrate: bitrate,
            width: width,
            height: height,
            audioChannels: audioChannels,
            audioCodec: audioCodec,
            videoCodec: videoCodec,
            resolution: videoResolution,
            container: container,
            parts: Part?.map { $0.toDomain() } ?? []
        )
    }
}

extension MediaPartDTO {
    func toDomain() -> MediaPart {
        MediaPart(
            id: safeId,
            key: safeKey,
            duration: duration,
            file: file,
            size: size,
            container: container,
            streams: Stream?.map { $0.toDomain() } ?? []
        )
    }
}

extension StreamDTO {
    func toDomain() -> MediaStream {
        MediaStream(
            id: safeId,
            type: StreamType(rawValue: safeStreamType) ?? .video,
            codec: codec,
            index: index,
            language: language,
            languageCode: languageCode,
            displayTitle: displayTitle,
            selected: selected ?? false,
            forced: forced ?? false,
            isDefault: `default` ?? false,
            title: title,
            width: width,
            height: height,
            bitrate: bitrate,
            frameRate: frameRate,
            channels: channels,
            samplingRate: samplingRate
        )
    }
}
