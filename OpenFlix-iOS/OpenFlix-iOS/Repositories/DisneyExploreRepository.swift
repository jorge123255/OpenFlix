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
    func loadSet(_ container: DXContainer, force: Bool = false) async {
        let setId = container.id
        if loadingSets.contains(setId) { return }
        if !force, setById[setId] != nil { return }
        loadingSets.insert(setId)
        defer { loadingSets.remove(setId) }
        do {
            let params = setQueryItems(for: container)
            let response = try await api.disneySet(setId: setId, params: params)
            if let set = response.data?.set {
                setById[setId] = set
                setErrors[setId] = nil
            }
        } catch {
            setErrors[setId] = error.localizedDescription
        }
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
