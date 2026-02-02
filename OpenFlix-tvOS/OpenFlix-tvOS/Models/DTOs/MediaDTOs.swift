import Foundation

// MARK: - Library Sections

struct LibrarySectionsResponse: Codable {
    let MediaContainer: LibrarySectionsContainer?

    // Alternative key mapping for different server versions
    enum CodingKeys: String, CodingKey {
        case MediaContainer
    }
}

struct LibrarySectionsContainer: Codable {
    let size: Int?
    let Directory: [LibrarySectionDTO]?
    let directories: [LibrarySectionDTO]?

    // Support both key formats
    var allDirectories: [LibrarySectionDTO] {
        Directory ?? directories ?? []
    }
}

struct LibrarySectionDTO: Codable {
    let key: String
    let type: String
    let title: String
    let agent: String?
    let scanner: String?
    let language: String?
    let uuid: String?
    let updatedAt: Int?
    let scannedAt: Int?
    let createdAt: Int?
    let content: Bool?
    let directory: Bool?
    let contentChangedAt: Int?
    let hidden: Int?
    let count: Int?

    var id: Int {
        Int(key) ?? 0
    }
}

// MARK: - Media Container (Generic)

struct MediaContainerResponse: Codable {
    let MediaContainer: MediaContainer?
}

struct MediaContainer: Codable {
    let size: Int?
    let totalSize: Int?
    let offset: Int?
    let allowSync: Bool?
    let identifier: String?
    let librarySectionID: Int?
    let librarySectionTitle: String?
    let librarySectionUUID: String?
    let Metadata: [MediaItemDTO]?
    let Hub: [HubDTO]?
    let Directory: [LibrarySectionDTO]?
}

// MARK: - Media Item

struct MediaItemDTO: Codable {
    let ratingKeyValue: StringOrInt?
    let key: String?
    let guid: String?
    let type: String?
    let title: String?
    let originalTitle: String?
    let tagline: String?
    let summary: String?
    let thumb: String?
    let art: String?
    let banner: String?
    let year: Int?
    let duration: Int?
    let viewOffset: Int?
    let viewCount: Int?
    let contentRating: String?
    let audienceRating: Double?
    let rating: Double?
    let studio: String?
    let addedAt: Int?
    let updatedAt: Int?
    let originallyAvailableAt: String?
    let leafCount: Int?          // For shows: total episodes
    let viewedLeafCount: Int?    // For shows: watched episodes
    let childCount: Int?         // For shows: season count
    let index: Int?              // Season/episode number
    let parentIndex: Int?        // Season number for episodes
    let parentRatingKey: StringOrInt? // Parent media key
    let parentTitle: String?     // Parent title (show name for episodes)
    let parentThumb: String?
    let grandparentRatingKey: StringOrInt?
    let grandparentTitle: String?
    let grandparentThumb: String?
    let grandparentArt: String?
    let librarySectionID: Int?
    let librarySectionTitle: String?
    let Genre: [GenreDTO]?
    let Role: [RoleDTO]?
    let Director: [DirectorDTO]?
    let Writer: [WriterDTO]?
    let Country: [CountryDTO]?
    let Media: [MediaVersionDTO]?

    enum CodingKeys: String, CodingKey {
        case ratingKeyValue = "ratingKey"
        case key, guid, type, title, originalTitle, tagline, summary
        case thumb, art, banner, year, duration, viewOffset, viewCount
        case contentRating, audienceRating, rating, studio
        case addedAt, updatedAt, originallyAvailableAt
        case leafCount, viewedLeafCount, childCount
        case index, parentIndex, parentRatingKey, parentTitle, parentThumb
        case grandparentRatingKey, grandparentTitle, grandparentThumb, grandparentArt
        case librarySectionID, librarySectionTitle
        case Genre, Role, Director, Writer, Country, Media
    }

    // Computed properties with safe defaults
    var ratingKey: String? {
        ratingKeyValue?.stringValue
    }

    var ratingKeyInt: Int {
        ratingKeyValue?.intValue ?? 0
    }

    var safeTitle: String {
        title ?? "Unknown"
    }

    var safeType: String {
        type ?? "unknown"
    }

    var safeKey: String {
        key ?? ""
    }
}

// Helper type to handle fields that can be String or Int
enum StringOrInt: Codable {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.typeMismatch(StringOrInt.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Int"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }

    var stringValue: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        }
    }

    var intValue: Int {
        switch self {
        case .string(let value): return Int(value) ?? 0
        case .int(let value): return value
        }
    }
}

struct GenreDTO: Codable {
    let id: Int?
    let tag: String
}

struct RoleDTO: Codable {
    let id: Int?
    let tag: String
    let role: String?
    let thumb: String?
}

struct DirectorDTO: Codable {
    let id: Int?
    let tag: String
}

struct WriterDTO: Codable {
    let id: Int?
    let tag: String
}

struct CountryDTO: Codable {
    let id: Int?
    let tag: String
}

// MARK: - Media Versions & Streams

struct MediaVersionDTO: Codable {
    let id: Int?
    let duration: Int?
    let bitrate: Int?
    let width: Int?
    let height: Int?
    let aspectRatio: Double?
    let audioChannels: Int?
    let audioCodec: String?
    let videoCodec: String?
    let videoResolution: String?
    let container: String?
    let videoFrameRate: String?
    let Part: [MediaPartDTO]?

    var safeId: Int { id ?? 0 }
}

struct MediaPartDTO: Codable {
    let id: Int?
    let key: String?
    let duration: Int?
    let file: String?
    let size: Int?
    let container: String?
    let Stream: [StreamDTO]?

    var safeId: Int { id ?? 0 }
    var safeKey: String { key ?? "" }
}

struct StreamDTO: Codable {
    let id: Int?
    let streamType: Int?       // 1=video, 2=audio, 3=subtitle
    let codec: String?
    let index: Int?
    let language: String?
    let languageCode: String?
    let displayTitle: String?
    let selected: Bool?
    let forced: Bool?
    let `default`: Bool?
    let title: String?
    // Video-specific
    let width: Int?
    let height: Int?
    let bitrate: Int?
    let frameRate: Double?
    // Audio-specific
    let channels: Int?
    let samplingRate: Int?

    var safeId: Int { id ?? 0 }
    var safeStreamType: Int { streamType ?? 1 }
}

// MARK: - Hubs

struct HubsResponse: Codable {
    let MediaContainer: HubsContainer?
}

struct HubsContainer: Codable {
    let size: Int?
    let librarySectionID: Int?
    let Hub: [HubDTO]?
}

struct HubDTO: Codable {
    let key: String?
    let hubKey: String?
    let type: String?
    let hubIdentifier: String?
    let title: String?
    let context: String?
    let size: Int?
    let more: Bool?
    let style: String?
    let promoted: Bool?
    let Metadata: [MediaItemDTO]?

    var safeType: String { type ?? "unknown" }
    var safeTitle: String { title ?? "" }
}

// MARK: - Streaming Services

struct StreamingServicesResponse: Codable {
    let MediaContainer: StreamingServicesContainer?
}

struct StreamingServicesContainer: Codable {
    let Directory: [StreamingServiceDTO]?
}

struct StreamingServiceDTO: Codable {
    let key: String?
    let title: String?
    let thumb: String?

    var safeKey: String { key ?? "" }
    var safeTitle: String { title ?? "" }
}

// MARK: - Search

struct SearchResponse: Codable {
    let MediaContainer: SearchContainer?
}

struct SearchContainer: Codable {
    let Hub: [SearchHubDTO]?
}

struct SearchHubDTO: Codable {
    let type: String?
    let title: String?
    let size: Int?
    let Metadata: [MediaItemDTO]?

    var safeType: String { type ?? "unknown" }
    var safeTitle: String { title ?? "" }
}

// MARK: - Playback

struct PlaybackURLResponse: Codable {
    let url: String
    let `protocol`: String?
    let directPlay: Bool?
    let transcoding: Bool?

    enum CodingKeys: String, CodingKey {
        case url
        case `protocol`
        case directPlay = "direct_play"
        case transcoding
    }
}

// MARK: - Filters & Sorts

struct FiltersResponse: Codable {
    let MediaContainer: FiltersContainer
}

struct FiltersContainer: Codable {
    let filterTypes: [FilterTypeDTO]?

    enum CodingKeys: String, CodingKey {
        case filterTypes = "Type"
    }
}

struct FilterTypeDTO: Codable {
    let key: String
    let type: String
    let title: String
    let Filter: [FilterDTO]?
}

struct FilterDTO: Codable {
    let filter: String
    let filterType: String
    let title: String
    let type: String
}

struct SortsResponse: Codable {
    let MediaContainer: SortsContainer
}

struct SortsContainer: Codable {
    let FieldType: [SortFieldDTO]?
}

struct SortFieldDTO: Codable {
    let key: String
    let title: String
    let type: String?
}
