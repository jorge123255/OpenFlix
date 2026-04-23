import Foundation

// MARK: - Max (HBO Max) DTOs
//
// Max returns JSON:API: every payload has `data` + `included[]` and
// uses `relationships` to point at related entities by {type, id}
// pairs. The renderer walks these refs against an in-memory entity
// map. Mirrors what the OpenFlix web's MaxExplore.tsx does.

struct MXStatusResponse: Codable {
    let loggedIn: Bool?
    let tokenExpiry: String?
    let movies: Int?
    let shows: Int?
    let liveChannels: Int?
    let lastRefresh: String?
}

/// `GET /max/hub?inline=N` — top-level home page response plus a
/// pre-fetched bag of the first N collections so the first paint
/// has artwork without N extra round-trips.
struct MXHubResponse: Codable {
    let home: MXExploreResponse?
    let inlinedCollections: [String: MXExploreCollectionResponse]?
    let inlinedCount: Int?
    let generated: String?
}

/// JSON:API envelope returned by /max/explore/* routes.
struct MXExploreResponse: Codable {
    let data: MXEntity?
    let included: [MXEntity]?
    let meta: DXJSON?
}

/// JSON:API envelope returned specifically by /collection/:id —
/// same shape as MXExploreResponse but kept as its own type so
/// callsites read true to intent.
typealias MXExploreCollectionResponse = MXExploreResponse

struct MXEntity: Codable, Identifiable {
    let id: String?
    let type: String?
    let attributes: DXJSON?
    let relationships: [String: MXRelationship]?
    let meta: DXJSON?

    /// SwiftUI Identifiable id — combines type + id since two
    /// entities can share an id across types in JSON:API.
    var renderId: String { "\(type ?? "?"):\(id ?? UUID().uuidString)" }
}

struct MXRef: Codable, Hashable {
    let id: String?
    let type: String?

    var key: String? {
        guard let id, let type else { return nil }
        return "\(type):\(id)"
    }
}

struct MXRelationship: Codable {
    let data: MXRelationshipData?
}

/// Disney's JSON:API `relationships.<key>.data` may be a single
/// ref or an array of refs. Decode either form.
struct MXRelationshipData: Codable {
    let single: MXRef?
    let multiple: [MXRef]?

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let arr = try? c.decode([MXRef].self) {
            single = nil
            multiple = arr
            return
        }
        if let one = try? c.decode(MXRef.self) {
            single = one
            multiple = nil
            return
        }
        single = nil
        multiple = nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        if let multiple { try c.encode(multiple) }
        else if let single { try c.encode(single) }
        else { try c.encodeNil() }
    }

    var asArray: [MXRef] {
        if let multiple { return multiple }
        if let single { return [single] }
        return []
    }

    var first: MXRef? { multiple?.first ?? single }
}

// MARK: - Search

/// `GET /max/explore/search` returns either a flat array or a
/// JSON:API envelope depending on backend version. Decode the flat
/// form (what the web reads).
struct MXSearchResultsResponse: Codable {
    let results: [MXSearchResult]?

    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([MXSearchResult].self) {
            self.results = array
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try c.decodeIfPresent([MXSearchResult].self, forKey: .results)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(results, forKey: .results)
    }

    enum CodingKeys: String, CodingKey { case results }
}

struct MXSearchResult: Codable, Identifiable {
    let id: String?
    let type: String?
    let title: String?
    let description: String?
    let imageUrl: String?
    let editId: String?
    let releaseYear: Int?
    let packages: [String]?

    var renderId: String { (type ?? "?") + ":" + (id ?? UUID().uuidString) }
}

// MARK: - Entity walker
//
// Helpers that mirror the web's pickRelatedEntity / orderedCollectionIDs
// / entityImage logic — Max content URLs aren't on the entity itself,
// they live on related `images` entities under relationships.

enum MXEntityMap {
    /// Build a map<entityKey, entity> from the JSON:API response —
    /// includes both `data` and every `included[]` entry.
    static func build(_ response: MXExploreResponse?) -> [String: MXEntity] {
        var map: [String: MXEntity] = [:]
        if let d = response?.data, let key = MXRef(id: d.id, type: d.type).key {
            map[key] = d
        }
        for entity in response?.included ?? [] {
            if let key = MXRef(id: entity.id, type: entity.type).key {
                map[key] = entity
            }
        }
        return map
    }

    /// Walk a single relationship key on an entity and return all
    /// referenced entities present in the map (in declared order).
    static func related(_ entity: MXEntity?, key: String, in map: [String: MXEntity]) -> [MXEntity] {
        guard let refs = entity?.relationships?[key]?.data?.asArray else { return [] }
        return refs.compactMap { ref in
            guard let k = ref.key else { return nil }
            return map[k]
        }
    }

    /// Convenience for single-cardinality relationships.
    static func relatedFirst(_ entity: MXEntity?, key: String, in map: [String: MXEntity]) -> MXEntity? {
        related(entity, key: key, in: map).first
    }

    /// String attribute getter — handles the DXJSON tree decode.
    static func attrString(_ entity: MXEntity?, _ key: String) -> String? {
        guard let dict = entity?.attributes?.value as? [String: Any] else { return nil }
        if let s = dict[key] as? String, !s.isEmpty { return s }
        return nil
    }

    static func attrInt(_ entity: MXEntity?, _ key: String) -> Int? {
        guard let dict = entity?.attributes?.value as? [String: Any] else { return nil }
        if let i = dict[key] as? Int { return i }
        if let d = dict[key] as? Double { return Int(d) }
        if let s = dict[key] as? String { return Int(s) }
        return nil
    }

    static func attrDict(_ entity: MXEntity?, _ key: String) -> [String: Any]? {
        guard let dict = entity?.attributes?.value as? [String: Any] else { return nil }
        return dict[key] as? [String: Any]
    }

    // MARK: Common attribute getters

    static func entityTitle(_ entity: MXEntity?) -> String {
        attrString(entity, "name")
            ?? attrString(entity, "title")
            ?? attrString(entity, "originalName")
            ?? "Untitled"
    }

    static func entityDescription(_ entity: MXEntity?) -> String? {
        attrString(entity, "longDescription") ?? attrString(entity, "description")
    }

    static func entityReleaseYear(_ entity: MXEntity?) -> String? {
        if let y = attrInt(entity, "releaseYear") { return String(y) }
        let date = attrString(entity, "premiereDate")
            ?? attrString(entity, "airDate")
            ?? attrString(entity, "firstAvailableDate")
        guard let date else { return nil }
        return String(date.prefix(4))
    }

    /// Pick the best image URL for an entity. `immersive=true`
    /// prefers landscape/hero kinds; otherwise prefers tile kinds.
    /// Walks `entity.relationships.images` against the entity map.
    /// Max image entities expose the URL under `src`; other shapes
    /// may use `url` — read whichever is present.
    static func entityImage(_ entity: MXEntity?, in map: [String: MXEntity], immersive: Bool) -> String? {
        let images = related(entity, key: "images", in: map)
        let candidates = images.compactMap { (img) -> (kind: String, url: String)? in
            let url = attrString(img, "src") ?? attrString(img, "url")
            guard let url, !url.isEmpty else { return nil }
            let kind = attrString(img, "kind") ?? attrString(img, "name") ?? ""
            return (kind, url)
        }
        guard !candidates.isEmpty else { return nil }
        // Heroes want a wide background image (no logo). Tiles want
        // a card poster. Logo-only kinds (anything containing
        // "logo") are ranked last so they don't accidentally win
        // when no preferred kind matches.
        let heroKinds = ["tileburnedinbackdrop", "default-wide", "key-art-wide", "keyart-wide", "default_16_9", "16x9", "banner", "background", "hero"]
        let standardKinds = ["tile", "boxart", "key-art-vertical", "default-vertical", "key-art", "keyart", "poster", "default-wide", "16x9"]
        let preferred = immersive ? heroKinds : standardKinds
        let scored: [(score: Int, url: String)] = candidates.map { c in
            let lower = c.kind.lowercased()
            // Penalize logo-only assets — they read as watermarks
            // on cards instead of artwork.
            if lower.contains("logo") { return (Int.max - 1, c.url) }
            let idx = preferred.firstIndex { lower.contains($0) } ?? (Int.max - 100)
            return (idx, c.url)
        }
        return scored.min { $0.score < $1.score }?.url ?? candidates.first?.url
    }

    /// Resolve the page entity referenced by the home route. Mirrors
    /// the web's pageEntity().
    static func pageEntity(_ home: MXExploreResponse?) -> MXEntity? {
        let map = build(home)
        guard let route = home?.data,
              let target = route.relationships?["target"]?.data?.first,
              let key = target.key else { return nil }
        return map[key]
    }

    /// Walk the home route → page → items[] → collection refs; return
    /// the ordered collection ids (deduped).
    static func orderedCollectionIds(_ hub: MXHubResponse?) -> [String] {
        let map = build(hub?.home)
        let page = pageEntity(hub?.home)
        var ids: [String] = []
        var seen = Set<String>()
        for itemRef in page?.relationships?["items"]?.data?.asArray ?? [] {
            guard let key = itemRef.key, let pageItem = map[key] else { continue }
            if let collectionRef = pageItem.relationships?["collection"]?.data?.first,
               let collectionId = collectionRef.id, !collectionId.isEmpty,
               !seen.contains(collectionId) {
                seen.insert(collectionId)
                ids.append(collectionId)
            }
        }
        return ids
    }

    /// Resolve a collection response from the inlined map first,
    /// falling back to the lazy-loaded map.
    static func collection(forId id: String,
                           hub: MXHubResponse?,
                           lazy: [String: MXExploreCollectionResponse]) -> MXExploreCollectionResponse? {
        if let inline = hub?.inlinedCollections?[id] { return inline }
        return lazy[id]
    }

    /// True when the collection is the page's hero (component.id ==
    /// "hero" or templateId == "immersive").
    static func isHeroCollection(_ entity: MXEntity?) -> Bool {
        guard let component = attrDict(entity, "component") else { return false }
        let cid = (component["id"] as? String)?.lowercased()
        let tid = (component["templateId"] as? String)?.lowercased()
        return cid == "hero" || tid == "immersive"
    }

    /// Items[] for a collection — returns the resolved content
    /// entities (show / movie / extra / video / season / etc.).
    /// Max wraps each tile in a `collectionItem` whose
    /// relationships.<contentType> points at the real entity (e.g.
    /// .show.data → {type:"show", id:"..."}). Walk a known list of
    /// content keys and use the first that resolves.
    static func collectionItems(_ response: MXExploreCollectionResponse?) -> [MXEntity] {
        let map = build(response)
        guard let collection = response?.data else { return [] }
        let contentKeys = ["target", "edit", "show", "movie", "extra",
                           "series", "video", "channel", "season", "page"]
        return related(collection, key: "items", in: map).compactMap { item in
            for key in contentKeys {
                if let resolved = relatedFirst(item, key: key, in: map) {
                    return resolved
                }
            }
            // If nothing resolves, surface the wrapper anyway —
            // entityTitle's fallback will at least show "Untitled"
            // rather than crashing.
            return item
        }
    }

    /// Best content id for a tile — used to navigate to detail and
    /// to start playback. Prefer `editId` attribute (Max's playable
    /// edit), fall back to entity id.
    static func contentId(_ entity: MXEntity?) -> String? {
        if let edit = attrString(entity, "editId"), !edit.isEmpty { return edit }
        return entity?.id
    }
}
