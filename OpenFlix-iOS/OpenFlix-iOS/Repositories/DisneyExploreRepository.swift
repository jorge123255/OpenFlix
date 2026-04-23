import Foundation

/// Disney Explore repository.
///
/// Fronts the OpenFlix-proxied Disney Explore service. Used by:
///   - the Disney+ section in Library (top-level browse)
///   - the Disney hub embedded in the ESPN tab (when present)
///   - any detail / search surfaces driven by deeplinks
///
/// Contract reminders:
///   - never call Disney directly; always go through OpenFlix.
///   - never derive playback URLs from imageId / browse links;
///     resolution is server-owned through deeplink + playerExperience.
///   - never invent flattened "rails" — use raw page/container/item.
///   - no polling. Disney browse is user-driven.
@MainActor
final class DisneyExploreRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published private(set) var nav: DXNav?
    @Published private(set) var pageById: [String: DXPage] = [:]
    @Published private(set) var setById: [String: DXContainer] = [:]
    @Published private(set) var loadingSets: Set<String> = []
    @Published private(set) var setErrors: [String: String] = [:]
    @Published var error: String?

    // MARK: - Global nav

    func loadGlobalNav() async {
        do {
            nav = try await api.disneyGlobalNav().data?.nav
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Deeplink → page resolution

    /// Resolves a deeplink to a concrete pageId/setId/entityId. Disney
    /// returns a list of actions; the first that yields a pageId wins
    /// (matches how the web hub picks them).
    func resolveDeeplink(refId: String, refIdType: String) async throws -> DXDeeplinkAction? {
        let response = try await api.disneyDeeplink(refId: refId, refIdType: refIdType)
        return response.data?.deeplink?.actions?.first
    }

    // MARK: - Page

    @discardableResult
    func loadPage(pageId: String, target: DXTarget? = nil, force: Bool = false) async throws -> DXPage? {
        if !force, let cached = pageById[pageId] { return cached }
        let params = target?.asQueryItems ?? []
        let response = try await api.disneyPage(pageId: pageId, params: params)
        if let page = response.data?.page {
            pageById[pageId] = page
            return page
        }
        return nil
    }

    // MARK: - Set (lazy shelf load)

    /// Loads a single set with full request context preserved from the
    /// owning container/target. Use this for the row-level lazy load when
    /// a container in a page response came back without populated items.
    /// Browse namespace — controls whether `loadSet` calls
    /// `/disney/explore/set/:id` (default) or `/espn/browse/set/:id`.
    /// ESPN browse pages share the Disney shape, so the renderer can
    /// be reused; only the lazy-load route differs.
    enum BrowseNamespace { case disney, espn }
    @Published var namespace: BrowseNamespace = .disney

    func loadSet(_ container: DXContainer, force: Bool = false) async {
        // Use the SwiftUI-stable `id` for cache keying so a row that
        // re-renders against the same container hits the cache, but
        // always hit the API with the real wire id (rawId / params.setId
        // / setId). Detail-page containers without any of those (e.g.
        // standard_episodic_style "seasons" / series_details) have no
        // /set endpoint to call — skip them silently.
        let cacheKey = container.id
        let apiSetId = container.rawId
            ?? container.setId
            ?? container.params?.setId
        if apiSetId == nil { return }
        if loadingSets.contains(cacheKey) { return }
        if !force, setById[cacheKey] != nil { return }
        loadingSets.insert(cacheKey)
        defer { loadingSets.remove(cacheKey) }
        do {
            let params = setQueryItems(for: container)
            let response: DXSetResponse
            switch namespace {
            case .disney: response = try await api.disneySet(setId: apiSetId!, params: params)
            case .espn:   response = try await api.espnBrowseSet(setId: apiSetId!, params: params)
            }
            if let set = response.data?.set {
                setById[cacheKey] = set
                setErrors[cacheKey] = nil
            }
        } catch {
            // Lazy rails get re-created/destroyed by LazyVStack as the
            // user scrolls; SwiftUI cancels the .task that owns the
            // load, which surfaces as URLError(.cancelled) /
            // CancellationError. Don't surface those to the user — the
            // load will retry naturally the next time the row appears.
            if Self.isCancellation(error) { return }
            setErrors[cacheKey] = error.localizedDescription
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return (error as NSError).code == NSURLErrorCancelled
    }

    /// Loads a set from a target (used when a tile target is set-scope).
    func loadSetFromTarget(_ target: DXTarget) async throws -> DXContainer? {
        guard let setId = target.setId ?? target.id, !setId.isEmpty else { return nil }
        let response = try await api.disneySet(setId: setId, params: target.asQueryItems)
        return response.data?.set
    }

    // MARK: - Search

    func search(query: String) async throws -> DXPage? {
        let response = try await api.disneySearch(query: query)
        return response.data?.page
    }

    // MARK: - Player experience (diagnostic only)

    func loadPlayerExperience(mediaId: String) async throws -> DXPlayerExperience? {
        let response = try await api.disneyPlayerExperience(mediaId: mediaId)
        return response.data?.playerExperience
    }

    // MARK: - Convenience: ESPN page resolved from globalNav
    //
    // Fallback path used by the ESPN tab when `hub.disneyHub` is null —
    // walks the Disney globalNav for an "ESPN" tab and loads its page
    // directly so the same Disney rails surface even when the linked
    // hub.disneyHub blob isn't included in the espn/hub response.

    @discardableResult
    func loadESPNPageFromGlobalNav() async throws -> DXPage? {
        if nav == nil {
            await loadGlobalNav()
        }
        let tabs = nav?.walkTabs() ?? []
        guard let espnTab = tabs.first(where: { $0.label.lowercased() == "espn" }) else {
            return nil
        }
        if let pageId = espnTab.pageId, !pageId.isEmpty {
            return try await loadPage(pageId: pageId, force: true)
        }
        let refId = espnTab.entityId ?? espnTab.deeplinkId
        let refIdType = espnTab.entityId != nil ? (espnTab.entityType ?? "entityId") : "deeplinkId"
        if let refId, !refId.isEmpty {
            let action = try await resolveDeeplink(refId: refId, refIdType: refIdType)
            if let pageId = action?.pageId, !pageId.isEmpty {
                return try await loadPage(pageId: pageId, force: true)
            }
        }
        return nil
    }

    // MARK: - Helpers

    /// Build the union of params + container top-level fields for a
    /// `/set/:setId` call. Either the params bag or the top-level
    /// fields may be authoritative depending on container origin —
    /// forward both.
    private func setQueryItems(for container: DXContainer) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        let already = Set<String>()
        var seen = already
        func add(_ name: String, _ value: String?) {
            guard !seen.contains(name), let value, !value.isEmpty else { return }
            items.append(URLQueryItem(name: name, value: value))
            seen.insert(name)
        }
        add("layoutId", container.layoutId)
        add("pageId", container.pageId)
        add("pageResolutionId", container.pageResolutionId)
        add("pageStyle", container.pageStyle)
        add("setResolutionId", container.setResolutionId)
        add("setStyle", container.setStyle)
        add("entityId", container.entityId)
        add("entityType", container.entityType)
        if let v = container.skipEligibilityCheck {
            add("skipEligibilityCheck", v.value ? "true" : "false")
        }
        if let limit = container.limit { add("limit", "\(limit)") }
        if let offset = container.offset { add("offset", "\(offset)") }
        return items
    }
}
