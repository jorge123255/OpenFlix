import Foundation

// MARK: - Disney Explore DTOs
//
// Raw shape proxied through OpenFlix from Disney's Explore service. Used
// by both the Disney+ section in Library AND by the Disney hub embedded
// in the ESPN tab (when hub.hasDisneyHub == true). Do not flatten or
// invent client-only fields — render directly from this shape.

// MARK: Top-level responses

struct DXGlobalNavResponse: Codable {
    let data: DXGlobalNavEnvelope?
}

struct DXGlobalNavEnvelope: Codable {
    let nav: DXNav?
}

struct DXNav: Codable {
    let children: [DXNavChild]?
}

struct DXNavChild: Codable, Identifiable {
    let id: String?
    let children: [DXNavLeaf]?
    let visuals: DXVisuals?
    let action: DXAction?

    enum CodingKeys: String, CodingKey { case id, children, visuals, action }
}

struct DXNavLeaf: Codable, Identifiable {
    let action: DXAction?
    let browse: DXBrowseInfo?
    let visuals: DXVisuals?

    /// Stable id derived from any available field — Disney sometimes
    /// returns leaves without an explicit id.
    var id: String {
        action?.slug ?? browse?.deeplinkId ?? visuals?.displayText ?? UUID().uuidString
    }
}

struct DXBrowseInfo: Codable {
    let deeplinkId: String?
    let infoBlock: String?
    let pageId: String?
}

struct DXAction: Codable {
    let slug: String?
    let type: String?              // "systemBrowse"
    let infoBlock: String?
    let visuals: DXVisuals?
}

// MARK: Page / Set responses

/// `GET /disney/explore/page/:pageId` and `GET /disney/explore/search`.
struct DXPageResponse: Codable {
    let data: DXPageEnvelope?
    let success: Bool?
}

struct DXPageEnvelope: Codable {
    let page: DXPage?
}

/// `GET /disney/explore/set/:setId`.
struct DXSetResponse: Codable {
    let data: DXSetEnvelope?
    let success: Bool?
}

struct DXSetEnvelope: Codable {
    let set: DXContainer?
}

/// `GET /disney/explore/deeplink?refId=…&refIdType=…`.
struct DXDeeplinkResponse: Codable {
    let data: DXDeeplinkEnvelope?
    let success: Bool?
}

struct DXDeeplinkEnvelope: Codable {
    let deeplink: DXDeeplink?
}

struct DXDeeplink: Codable {
    let actions: [DXDeeplinkAction]?
}

struct DXDeeplinkAction: Codable {
    let pageId: String?
    let entityId: String?
    let setId: String?
    let resourceId: String?
    let mediaId: String?
    let deeplinkId: String?
    let refId: String?
    let refIdType: String?
    let pageType: String?     // "page", "entity", etc.
    let actionType: String?
}

// MARK: Page / container shape

struct DXPage: Codable, Identifiable {
    let id: String?
    let pageId: String?
    let title: String?
    let style: String?
    let pageStyle: String?
    let containers: [DXContainer]?
    let visuals: DXVisuals?

    enum CodingKeys: String, CodingKey {
        case id, pageId, title, style, pageStyle, containers, visuals
    }
}

struct DXContainer: Codable, Identifiable {
    let id: String
    let title: String?
    let type: String?
    let style: String?
    let layout: String?
    let pagination: DXPagination?
    let items: [DXItem]?

    // Resolution context — top-level on the container in addition to
    // being nested under params/request. Server populates one or both
    // depending on container origin; preserve both.
    let entityId: String?
    let entityType: String?
    let pageId: String?
    let setId: String?
    let pageStyle: String?
    let setStyle: String?
    let layoutId: String?
    let pageResolutionId: String?
    let setResolutionId: String?
    let skipEligibilityCheck: DXFlexibleBool?
    let limit: Int?
    let offset: Int?

    let visuals: DXVisuals?
    let target: DXTarget?
    let browseTarget: DXBrowseTarget?
    let request: DXRequestContext?

    /// Best-effort title for shelf headers.
    var displayTitle: String? {
        title ?? visuals?.displayText ?? visuals?.title
    }
}

struct DXPagination: Codable {
    let currentOffset: Int?
    let hasMore: Bool?
    let hasPrev: Bool?
    let totalCount: Int?
}

/// Disney sometimes returns booleans as `"true"`/`"false"` strings.
struct DXFlexibleBool: Codable {
    let value: Bool
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { value = b; return }
        if let s = try? c.decode(String.self) {
            value = (s.lowercased() == "true")
            return
        }
        value = false
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(value)
    }
}

// MARK: Items

struct DXItem: Codable, Identifiable {
    var id: String { rawId ?? deeplinkId ?? pageId ?? "\(visuals?.title ?? "?"):\(startTime ?? "")" }

    let rawId: String?
    let type: String?
    let sectionType: String?

    // Display
    let visuals: DXVisuals?
    let badges: [String]?
    let imageId: String?
    let imageUrl: String?
    let artwork: DXArtwork?

    // Navigation
    let pageId: String?
    let deeplinkId: String?
    let setId: String?
    let browseId: String?
    let target: DXTarget?
    let browseTarget: DXBrowseTarget?

    // Sport-event metadata (only present on sports event items)
    let title: String?
    let subtitle: String?
    let description: String?
    let sport: String?
    let league: String?

    // Live-state
    let live: Bool?
    let upcoming: Bool?
    let state: String?
    let playbackMode: String?
    let startTime: String?
    let endTime: String?
    let elapsedMs: Int?
    let runtimeMs: Int?

    // Playback context (event items only)
    let playback: DXPlayback?

    enum CodingKeys: String, CodingKey {
        case rawId = "id"
        case type, sectionType
        case visuals, badges, imageId, imageUrl, artwork
        case pageId, deeplinkId, setId, browseId, target, browseTarget
        case title, subtitle, description, sport, league
        case live, upcoming, state, playbackMode, startTime, endTime, elapsedMs, runtimeMs
        case playback
    }

    var displayTitle: String? { visuals?.title ?? visuals?.displayText ?? title }
    var displaySubtitle: String? { visuals?.subtitle ?? subtitle }

    var isLive: Bool {
        if state?.lowercased() == "live" || live == true { return true }
        return badges?.contains { $0.lowercased().contains("live") } ?? false
    }
    var isUpcoming: Bool {
        if state?.lowercased() == "upcoming" || upcoming == true { return true }
        return badges?.contains { $0.lowercased().contains("upcoming") } ?? false
    }
    var isPlayable: Bool { !isUpcoming && playback?.resourceId != nil }
    var supportsLive: Bool { playback?.supportsLive ?? isLive }
    var supportsStartover: Bool { playback?.supportsStartover ?? false }
    var supportsReplay: Bool { playback?.supportsReplay ?? false }

    /// Server-provided URL only — never invent from imageId.
    var bestImageURL: String? {
        if let imageUrl, !imageUrl.isEmpty { return imageUrl }
        if let v = visuals?.artwork?.bestImageURL, !v.isEmpty { return v }
        return artwork?.bestImageURL
    }

    var startTimeDate: Date? {
        guard let startTime else { return nil }
        return ISO8601DateFormatter().date(from: startTime) ??
            ISO8601DateFormatter._dxFractional.date(from: startTime)
    }
}

private extension ISO8601DateFormatter {
    static let _dxFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

// MARK: Visuals / artwork

struct DXVisuals: Codable {
    let title: String?
    let subtitle: String?
    let displayText: String?
    let metastringParts: DXMetaParts?
    let artwork: DXArtwork?
    let description: DXDescription?
}

struct DXMetaParts: Codable {
    let releaseYearRange: DXReleaseYear?
    let runtime: DXRuntime?
    let ratingInfo: DXRatingInfo?
}

struct DXReleaseYear: Codable { let startYear: Int? }
struct DXRuntime: Codable { let runtimeMs: Int? }
struct DXRatingInfo: Codable {
    let advisories: [String]?
    let rating: DXRating?
}
struct DXRating: Codable { let text: String?; let value: String? }

struct DXDescription: Codable {
    let full: String?
    let medium: String?
    let brief: String?
}

struct DXArtwork: Codable {
    // Disney returns artwork keyed by aspect ratio. Pick whichever the
    // backend handed us — never invent a URL from imageId.
    let standard: DXArtworkVariant?
    let tile: DXArtworkVariant?
    let thumbnail: DXArtworkVariant?
    let background: DXArtworkVariant?
    let titleTreatment: DXArtworkVariant?
    let logo: DXArtworkVariant?

    // Hub-shape aspect-ratio-suffixed keys (used by some endpoints).
    let tile178Url: String?
    let thumbnail178Url: String?
    let background178Url: String?
    let titleTreatment178Url: String?
    let brandBackground178Url: String?
    let logo100Url: String?
    let darkLogo100Url: String?

    var bestImageURL: String? {
        let candidates: [String?] = [
            background?.url, background178Url,
            tile?.url, tile178Url, thumbnail?.url, thumbnail178Url,
            standard?.url,
            titleTreatment?.url, titleTreatment178Url,
            logo?.url, logo100Url
        ]
        return candidates.compactMap { $0 }.first { !$0.isEmpty }
    }
}

struct DXArtworkVariant: Codable {
    let url: String?
    let aspectRatio: Double?
    let width: Int?
    let height: Int?
}

// MARK: Targets / navigation

struct DXTarget: Codable {
    let type: String?
    let scope: String?
    let id: String?
    let setId: String?
    let pageId: String?
    let entityId: String?
    let entityType: String?
    let layoutId: String?
    let pageResolutionId: String?
    let setResolutionId: String?
    let pageStyle: String?
    let setStyle: String?
    let skipEligibilityCheck: DXFlexibleBool?
    let limit: Int?
    let offset: Int?
    let label: String?
    let refId: String?
    let refIdType: String?

    var asQueryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        func add(_ name: String, _ value: String?) {
            if let value, !value.isEmpty {
                items.append(URLQueryItem(name: name, value: value))
            }
        }
        add("layoutId", layoutId)
        add("pageId", pageId)
        add("pageResolutionId", pageResolutionId)
        add("pageStyle", pageStyle)
        add("setResolutionId", setResolutionId)
        add("setStyle", setStyle)
        add("entityId", entityId)
        add("entityType", entityType)
        add("setId", setId)
        if let v = skipEligibilityCheck { add("skipEligibilityCheck", v.value ? "true" : "false") }
        if let limit { add("limit", "\(limit)") }
        if let offset { add("offset", "\(offset)") }
        return items
    }
}

/// Browse-target carries the same fields as a target but the server
/// emits both keys; treat the structures as identical.
typealias DXBrowseTarget = DXTarget

struct DXRequestContext: Codable {
    let entityId: String?
    let entityType: String?
    let layoutId: String?
    let pageId: String?
    let pageResolutionId: String?
    let pageStyle: String?
    let setId: String?
    let setResolutionId: String?
    let setStyle: String?
    let skipEligibilityCheck: DXFlexibleBool?
    let limit: Int?
    let offset: Int?
}

// MARK: Playback context

struct DXPlayback: Codable {
    let resourceId: String?
    let availId: String?
    let deeplinkId: String?
    let contentType: String?
    let internalTitle: String?
    let supportsLive: Bool?
    let supportsStartover: Bool?
    let supportsReplay: Bool?
    let modes: [DXPlaybackMode]?
}

struct DXPlaybackMode: Codable, Identifiable {
    let type: String?    // "from_live", "from_beginning"
    let label: String?
    var id: String { type ?? label ?? UUID().uuidString }
    var isStartover: Bool { type?.lowercased().contains("beginning") == true }
    var isLive: Bool { type?.lowercased().contains("live") == true }
}

// MARK: Player experience (diagnostic)

struct DXPlayerExperienceResponse: Codable {
    let data: DXPlayerExperienceEnvelope?
    let success: Bool?
}

struct DXPlayerExperienceEnvelope: Codable {
    let playerExperience: DXPlayerExperience?
}

struct DXPlayerExperience: Codable {
    let mediaId: String?
    let availId: String?
    let videoCodecs: [String]?
    let audioCodecs: [String]?
    let captions: [String]?
    let audioRenditions: [DXAudioRendition]?
}

struct DXAudioRendition: Codable {
    let language: String?
    let displayName: String?
    let codec: String?
    let channels: Int?
}
