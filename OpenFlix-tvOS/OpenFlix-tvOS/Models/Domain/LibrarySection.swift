import Foundation

// MARK: - Library Section Type

enum LibrarySectionType: String, Codable {
    case movie
    case show
    case artist
    case photo
    case mixed

    var displayName: String {
        switch self {
        case .movie: return "Movies"
        case .show: return "TV Shows"
        case .artist: return "Music"
        case .photo: return "Photos"
        case .mixed: return "Mixed"
        }
    }

    var icon: String {
        switch self {
        case .movie: return "film"
        case .show: return "tv"
        case .artist: return "music.note"
        case .photo: return "photo"
        case .mixed: return "square.grid.2x2"
        }
    }
}

// MARK: - Library Section

struct LibrarySection: Identifiable, Hashable {
    let id: Int
    let key: String
    let type: LibrarySectionType
    let title: String
    let agent: String?
    let scanner: String?
    let language: String?
    let uuid: String?
    let updatedAt: Date?
    let scannedAt: Date?
    let hidden: Bool

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LibrarySection, rhs: LibrarySection) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - DTO Mapping

extension LibrarySectionDTO {
    func toDomain() -> LibrarySection {
        LibrarySection(
            id: id,
            key: key,
            type: LibrarySectionType(rawValue: type) ?? .mixed,
            title: title,
            agent: agent,
            scanner: scanner,
            language: language,
            uuid: uuid,
            updatedAt: updatedAt != nil ? Date(timeIntervalSince1970: TimeInterval(updatedAt!)) : nil,
            scannedAt: scannedAt != nil ? Date(timeIntervalSince1970: TimeInterval(scannedAt!)) : nil,
            hidden: (hidden ?? 0) == 1
        )
    }
}

// MARK: - Hub

struct Hub: Identifiable {
    var id: String { hubIdentifier ?? key ?? title }
    let key: String?
    let hubKey: String?
    let hubIdentifier: String?
    let type: String
    let title: String
    let size: Int
    let more: Bool
    let style: String?
    let promoted: Bool
    let items: [MediaItem]
}

extension HubDTO {
    func toDomain() -> Hub {
        Hub(
            key: key,
            hubKey: hubKey,
            hubIdentifier: hubIdentifier,
            type: safeType,
            title: safeTitle,
            size: size ?? 0,
            more: more ?? false,
            style: style,
            promoted: promoted ?? false,
            items: Metadata?.map { $0.toDomain() } ?? []
        )
    }
}

// MARK: - Watchlist Item

struct WatchlistItem: Identifiable {
    let id: Int
    let mediaId: Int
    let addedAt: Date
    let media: MediaItem?
}

extension WatchlistItemDTO {
    func toDomain() -> WatchlistItem {
        WatchlistItem(
            id: safeId,
            mediaId: safeMediaId,
            addedAt: addedAt != nil ? (ISO8601DateFormatter().date(from: addedAt!) ?? Date()) : Date(),
            media: media?.toDomain()
        )
    }
}

// MARK: - Playlist

struct Playlist: Identifiable {
    let id: Int
    let name: String
    let itemCount: Int
    let duration: Int?
    let thumb: String?
    let createdAt: Date?
    let updatedAt: Date?

    var durationFormatted: String? {
        guard let duration = duration else { return nil }
        return String.formatDuration(milliseconds: duration)
    }
}

extension PlaylistDTO {
    func toDomain() -> Playlist {
        Playlist(
            id: safeId,
            name: safeName,
            itemCount: itemCount ?? leafCount ?? 0,
            duration: duration,
            thumb: thumb,
            createdAt: createdAt != nil ? ISO8601DateFormatter().date(from: createdAt!) : nil,
            updatedAt: updatedAt != nil ? ISO8601DateFormatter().date(from: updatedAt!) : nil
        )
    }
}

// MARK: - Playlist Item

struct PlaylistItem: Identifiable {
    let id: Int
    let playlistId: Int
    let mediaId: Int
    let index: Int
    let addedAt: Date?
    let media: MediaItem?
}

extension PlaylistItemDTO {
    func toDomain() -> PlaylistItem {
        PlaylistItem(
            id: id,
            playlistId: playlistId,
            mediaId: mediaId,
            index: index,
            addedAt: addedAt != nil ? ISO8601DateFormatter().date(from: addedAt!) : nil,
            media: media?.toDomain()
        )
    }
}

// MARK: - Collection

struct Collection: Identifiable {
    let id: Int
    let key: String
    let title: String
    let summary: String?
    let thumb: String?
    let art: String?
    let childCount: Int
    let addedAt: Date?
    let updatedAt: Date?
}

extension CollectionDTO {
    func toDomain() -> Collection {
        Collection(
            id: Int(ratingKey) ?? 0,
            key: key,
            title: title,
            summary: summary,
            thumb: thumb,
            art: art,
            childCount: childCount ?? 0,
            addedAt: addedAt != nil ? Date(timeIntervalSince1970: TimeInterval(addedAt!)) : nil,
            updatedAt: updatedAt != nil ? Date(timeIntervalSince1970: TimeInterval(updatedAt!)) : nil
        )
    }
}
