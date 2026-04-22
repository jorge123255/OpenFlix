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

/// Recursive Disney nav node. Disney's nav tree mixes containers
/// (`type == "globalNav"` / `"subNav"`) with leaf entries that carry
/// browse / action / target fields. A single Codable handles both;
/// `DXNav.walkTabs()` traverses recursively the same way the web does
/// (server/web/src/pages/DisneyExplore.tsx navTabs).
struct DXNavChild: Codable, Identifiable {
    let id: String?
    let type: String?
    let children: [DXNavChild]?
    let visuals: DXVisuals?
    let action: DXAction?
    let browse: DXBrowseInfo?
    let target: DXTarget?
    let browseTarget: DXBrowseTarget?

    enum CodingKeys: String, CodingKey {
        case id, type, children, visuals, action, browse, target, browseTarget
    }
}

struct DXBrowseInfo: Codable {
    let deeplinkId: String?
    let infoBlock: String?
    let pageId: String?
    let setId: String?
    let entityId: String?
    let entityType: String?
}

struct DXAction: Codable {
    let slug: String?
    let type: String?              // "systemBrowse"
    let infoBlock: String?
    let visuals: DXVisuals?
    let pageId: String?
    let deeplinkId: String?
    let setId: String?
    let entityId: String?
    let entityType: String?
}

// MARK: Disney nav tabs walker
//
// Mirror of the web's navTabs() in DisneyExplore.tsx. Walks the
// recursive nav tree, descending into globalNav / subNav containers,
// extracting (label, target) pairs for leaf entries with a usable
// browse target. Skips Search / Settings labels. Dedupes by
// label+target.

struct DXNavTab: Identifiable, Hashable {
    let id: String
    let label: String
    let pageId: String?
    let setId: String?
    let entityId: String?
    let entityType: String?
    let deeplinkId: String?

    var asTarget: DXTarget {
        DXTarget(
            type: nil, scope: nil, id: nil,
            setId: setId, pageId: pageId,
            entityId: entityId, entityType: entityType,
            layoutId: nil, pageResolutionId: nil, setResolutionId: nil,
            pageStyle: nil, setStyle: nil,
            skipEligibilityCheck: nil, limit: nil, offset: nil,
            label: label,
            refId: deeplinkId, refIdType: deeplinkId == nil ? nil : "deeplinkId"
        )
    }
}

extension DXNav {
    func walkTabs() -> [DXNavTab] {
        var tabs: [DXNavTab] = []
        var seen = Set<String>()

        func mergeTarget(from node: DXNavChild) -> (label: String, pageId: String?, setId: String?, entityId: String?, entityType: String?, deeplinkId: String?)? {
            // Web order: browse → action → target → browseTarget.
            let candidates: [(pageId: String?, setId: String?, entityId: String?, entityType: String?, deeplinkId: String?)] = [
                (node.browse?.pageId, node.browse?.setId, node.browse?.entityId, node.browse?.entityType, node.browse?.deeplinkId),
                (node.action?.pageId, node.action?.setId, node.action?.entityId, node.action?.entityType, node.action?.deeplinkId),
                (node.target?.pageId, node.target?.setId, node.target?.entityId, node.target?.entityType, node.target?.refId),
                (node.browseTarget?.pageId, node.browseTarget?.setId, node.browseTarget?.entityId, node.browseTarget?.entityType, node.browseTarget?.refId),
            ]
            for c in candidates {
                if c.pageId != nil || c.setId != nil || c.entityId != nil || c.deeplinkId != nil {
                    let label = node.visuals?.displayText
                        ?? node.action?.visuals?.displayText
                        ?? node.visuals?.title
                        ?? ""
                    return (label, c.pageId, c.setId, c.entityId, c.entityType, c.deeplinkId)
                }
            }
            return nil
        }

        func visit(_ node: DXNavChild) {
            let nodeType = node.type?.lowercased() ?? ""
            if nodeType == "subnav" {
                node.children?.forEach { visit($0) }
                return
            }
            guard let merged = mergeTarget(from: node) else { return }
            let labelLower = merged.label.lowercased()
            guard !merged.label.isEmpty else { return }
            guard !["search", "settings"].contains(labelLower) else { return }

            let targetKey = merged.pageId ?? merged.deeplinkId ?? merged.entityId ?? merged.setId ?? (node.id ?? "")
            let dedupKey = "\(labelLower):\(targetKey)"
            guard seen.insert(dedupKey).inserted else { return }

            tabs.append(DXNavTab(
                id: node.id ?? dedupKey,
                label: merged.label,
                pageId: merged.pageId,
                setId: merged.setId,
                entityId: merged.entityId,
                entityType: merged.entityType,
                deeplinkId: merged.deeplinkId
            ))
        }

        for root in children ?? [] {
            if (root.type?.lowercased() ?? "") == "globalnav" {
                root.children?.forEach { visit($0) }
            } else {
                visit(root)
            }
        }
        return tabs
    }

    /// Pick the initial tab the way the web does — prefer "Disney+",
    /// then "For You", then the first tab.
    func preferredInitialTab() -> DXNavTab? {
        let all = walkTabs()
        if let disney = all.first(where: { $0.label.lowercased() == "disney+" }) { return disney }
        if let foryou = all.first(where: { $0.label.lowercased() == "for you" }) { return foryou }
        return all.first
    }
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

    /// True when the page came back as a `details_*` view (Disney's
    /// shape for entity / VOD detail pages). When true, the renderer
    /// should use `pageHeroArtworkURL` for the top hero rather than
    /// pulling the first item out of a hero container.
    var isDetailPage: Bool {
        let s = (style ?? pageStyle ?? "").lowercased()
        return s.hasPrefix("details_")
    }

    /// Page-level hero artwork — only meaningful on detail pages.
    /// Mirrors the web's `pageArtwork()` candidate ordering.
    var pageHeroArtworkURL: String? {
        DisneyImageResolver.preferredArtworkURL(visuals?.artwork?.value,
                                                candidates: DisneyImageResolver.pageHeroCandidates)
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
    let artwork: DXJSON?

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

    /// Resolves to a renderable URL by walking the Disney artwork
    /// preference order (mirror of the web's `itemImage()`):
    /// imageUrl → visuals.imageUrl → visuals.artwork (ordered) →
    /// item.artwork (ordered). Logos / title treatments are excluded
    /// from the candidate list so cards don't get watermark-only art.
    /// imageId values resolve to BAMGrid compose URLs through
    /// DisneyImageResolver.disneyImageURL().
    var bestImageURL: String? {
        if let imageUrl, !imageUrl.isEmpty { return imageUrl }
        if let v = visuals?.imageUrl, !v.isEmpty { return v }
        if let v = DisneyImageResolver.preferredArtworkURL(visuals?.artwork?.value, candidates: DisneyImageResolver.itemCandidates) {
            return v
        }
        if let v = DisneyImageResolver.preferredArtworkURL(artwork?.value, candidates: DisneyImageResolver.itemCandidates) {
            return v
        }
        if let imageId, let v = DisneyImageResolver.disneyImageURL(imageId) {
            return v
        }
        return nil
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
//
// Disney's real artwork shape is a deeply nested dict keyed by
// category → kind → aspect-ratio → { imageId | url }. Static structs
// don't model that well (the aspect-ratio key is a dynamic string like
// "1.78" / "2.0"), so we decode artwork as a free-form JSON tree and
// walk it on demand via DisneyImageResolver. This matches what the
// OpenFlix web client does (server/web/src/pages/DisneyExplore.tsx).

struct DXVisuals: Codable {
    let title: String?
    let subtitle: String?
    let displayText: String?
    let imageUrl: String?
    let metastringParts: DXMetaParts?
    let artwork: DXJSON?
    let description: DXDescription?
}

struct DXMetaParts: Codable {
    let releaseYearRange: DXReleaseYear?
    let runtime: DXRuntime?
    let ratingInfo: DXRatingInfo?
}

struct DXReleaseYear: Codable { let startYear: Int?; let endYear: Int? }
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

/// Free-form JSON value used for artwork blobs whose shape varies.
/// Decoded eagerly into a Swift `Any` tree (Bool/Int/Double/String/
/// [Any]/[String:Any]/NSNull). Encoding is a no-op since we never
/// re-serialize it.
struct DXJSON: Codable {
    let value: Any?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else if let b = try? container.decode(Bool.self) {
            value = b
        } else if let i = try? container.decode(Int.self) {
            value = i
        } else if let d = try? container.decode(Double.self) {
            value = d
        } else if let s = try? container.decode(String.self) {
            value = s
        } else if let arr = try? container.decode([DXJSON].self) {
            value = arr.map { $0.value as Any }
        } else if let dict = try? container.decode([String: DXJSON].self) {
            value = dict.mapValues { $0.value as Any }
        } else {
            value = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

// MARK: Disney image resolver
//
// Mirrors the web's preferredArtworkURL / disneyImageURL logic in
// server/web/src/pages/DisneyExplore.tsx. Use ordered candidate paths
// keyed by category/kind/aspect-ratio. When an artwork node has only
// an `imageId` (no `url`), build the BAMGrid compose URL directly —
// skip RAW_* image IDs (those are internal raw assets, not deliverable).

enum DisneyImageResolver {
    /// Standard candidate order for tiles/cards/hero images. Mirrors
    /// the web's `itemImage()` ordering: hero bg → details bg →
    /// standard bg → collection bg → standard tile → partner tile →
    /// partner thumbnail → tile background. Logos / title treatments
    /// are intentionally NOT in this list — they make poor cards.
    static let itemCandidates: [(path: [String], width: Int)] = [
        (["hero", "background", "1.78"], 1400),
        (["details", "background", "1.78"], 1400),
        (["standard", "background", "1.78"], 1400),
        (["collection", "background", "1.78"], 1200),
        (["standard", "tile", "1.78"], 800),
        (["partner", "tile", "1.78"], 800),
        (["partner", "thumbnail", "1.78"], 800),
        (["tile", "background", "1.78"], 800),
    ]

    /// Page-level hero artwork for `details_*` style pages. Mirrors
    /// the web's `pageArtwork()` candidate list.
    static let pageHeroCandidates: [(path: [String], width: Int)] = [
        (["hero", "background", "1.78"], 1400),
        (["details", "background", "1.78"], 1400),
        (["standard", "background", "1.78"], 1400),
        (["collection", "background", "1.78"], 1200),
        (["partner", "background", "1.78"], 1200),
    ]

    /// Build a BAMGrid compose URL from an `imageId`. Skips RAW_*
    /// (internal asset IDs that don't deliver). Returns nil for empty
    /// or malformed input.
    static func disneyImageURL(_ imageId: String, width: Int = 1200) -> String? {
        let value = imageId.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty, !value.hasPrefix("RAW_") else { return nil }
        guard let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return "https://disney.images.edge.bamgrid.com/ripcut-delivery/v2/variant/disney/\(encoded)/compose?format=webp&width=\(width)"
    }

    /// Resolve a single artwork node into a usable URL string.
    /// Accepts: a String (already a URL), or a dict with `url`/
    /// `imageUrl`/`src` fields, or a dict with `imageId`. Skips
    /// non-HTTP strings since BAMGrid compose URLs are always HTTPS.
    static func artworkNodeURL(_ node: Any?, width: Int = 1200) -> String? {
        if let s = node as? String, s.hasPrefix("http") { return s }
        guard let dict = node as? [String: Any] else { return nil }
        for key in ["url", "imageUrl", "src"] {
            if let s = dict[key] as? String, s.hasPrefix("http") { return s }
        }
        if let imageId = dict["imageId"] as? String {
            return disneyImageURL(imageId, width: width)
        }
        return nil
    }

    /// Walk a path of dict keys into the artwork tree and resolve the
    /// terminal node. Returns nil if any segment is missing.
    static func artworkAtPath(_ node: Any?, _ path: [String], width: Int = 1200) -> String? {
        var current = node
        for segment in path {
            guard let dict = current as? [String: Any] else { return nil }
            current = dict[segment]
        }
        return artworkNodeURL(current, width: width)
    }

    /// Try each candidate path in order. Falls back to a recursive
    /// scan that returns the first resolvable URL anywhere in the
    /// tree (mirrors the web's `firstArtworkUrl`).
    static func preferredArtworkURL(_ node: Any?, candidates: [(path: [String], width: Int)]) -> String? {
        for c in candidates {
            if let url = artworkAtPath(node, c.path, width: c.width) { return url }
        }
        return firstArtworkURL(node)
    }

    /// Recursively scan the tree for the first node that resolves to
    /// a URL. Used as a last-ditch fallback; the candidate list above
    /// should cover the common cases.
    static func firstArtworkURL(_ node: Any?) -> String? {
        if let direct = artworkNodeURL(node) { return direct }
        if let dict = node as? [String: Any] {
            for value in dict.values {
                if let resolved = firstArtworkURL(value) { return resolved }
            }
        } else if let arr = node as? [Any] {
            for value in arr {
                if let resolved = firstArtworkURL(value) { return resolved }
            }
        }
        return nil
    }
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
