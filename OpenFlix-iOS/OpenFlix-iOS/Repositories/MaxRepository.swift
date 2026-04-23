import Foundation

/// HBO Max repository.
///
/// Backs the Max+ section in Browse on iPhone and the Max sidecar
/// destination on tvOS. Contract reminders:
///   - never call Max provider APIs directly; everything goes through
///     OpenFlix proxies.
///   - never reconstruct streams client-side; use ProviderPlaybackService
///     for playback (which calls /max/play and returns a streamUrl).
///   - hub returns home page + inlined collections; use the inline
///     bag first, lazy-load missing collections via /max/explore/collection/:id.
///   - no polling. Browse is user-driven.
@MainActor
final class MaxRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    @Published private(set) var status: MXStatusResponse?
    @Published private(set) var hub: MXHubResponse?
    @Published private(set) var lazyCollections: [String: MXExploreCollectionResponse] = [:]
    @Published private(set) var loadingCollections: Set<String> = []
    @Published private(set) var collectionErrors: [String: String] = [:]
    @Published var error: String?

    // MARK: - Status

    func loadStatus() async {
        do {
            status = try await api.maxStatus()
        } catch {
            // Status is informational; don't block hub on it.
        }
    }

    // MARK: - Hub

    func loadHub(force: Bool = false) async {
        if !force, hub != nil { return }
        do {
            hub = try await api.maxHub(inline: 8)
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Collection lazy load

    func collection(for id: String) -> MXExploreCollectionResponse? {
        if let inlined = hub?.inlinedCollections?[id] { return inlined }
        return lazyCollections[id]
    }

    func loadCollection(id: String, force: Bool = false) async {
        if loadingCollections.contains(id) { return }
        if !force, hub?.inlinedCollections?[id] != nil { return }
        if !force, lazyCollections[id] != nil { return }
        loadingCollections.insert(id)
        defer { loadingCollections.remove(id) }
        do {
            let response = try await api.maxExploreCollection(id: id, size: 50)
            lazyCollections[id] = response
            collectionErrors[id] = nil
        } catch {
            if Self.isCancellation(error) { return }
            collectionErrors[id] = error.localizedDescription
        }
    }

    // MARK: - Search

    func search(_ query: String) async throws -> [MXSearchResult] {
        let response = try await api.maxExploreSearch(q: query, size: 30)
        return response.results ?? []
    }

    // MARK: - Detail

    /// Try the uniform /max/detail/:id first, fall back to the
    /// /max/explore/content/:id JSON:API envelope when the uniform
    /// route isn't mounted on the server yet. Returns whatever
    /// shape resolves first; the caller handles either.
    func loadDetail(contentId: String) async throws -> ProviderDetailResponse? {
        do {
            return try await api.maxDetail(id: contentId)
        } catch {
            // Surface 404 / 5xx — caller decides whether to fall
            // back to the content envelope.
            return nil
        }
    }

    func loadContentEnvelope(contentId: String) async throws -> MXExploreResponse {
        try await api.maxExploreContent(id: contentId)
    }

    // MARK: - Helpers

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return (error as NSError).code == NSURLErrorCancelled
    }
}
