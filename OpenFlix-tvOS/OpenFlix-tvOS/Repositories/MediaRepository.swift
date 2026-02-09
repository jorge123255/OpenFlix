import Foundation

@MainActor
class MediaRepository: ObservableObject {
    private let api = OpenFlixAPI.shared

    // MARK: - Library Sections

    func getLibrarySections() async throws -> [LibrarySection] {
        let response = try await api.getLibrarySections()
        return response.MediaContainer?.allDirectories.map { $0.toDomain() } ?? []
    }

    // MARK: - Library Items

    func getLibraryItems(
        sectionId: Int,
        start: Int? = nil,
        size: Int? = nil,
        sort: String? = nil,
        filters: [String: String]? = nil
    ) async throws -> (items: [MediaItem], totalSize: Int) {
        let response = try await api.getLibraryItems(
            sectionId: sectionId,
            start: start,
            size: size,
            sort: sort,
            filters: filters
        )
        let items = response.MediaContainer?.Metadata?.map { $0.toDomain() } ?? []
        let totalSize = response.MediaContainer?.totalSize ?? items.count
        return (items, totalSize)
    }

    // MARK: - Media Details

    func getMediaDetails(id: Int) async throws -> MediaItem {
        let response = try await api.getMediaDetails(key: id)
        guard let item = response.MediaContainer?.Metadata?.first else {
            throw NetworkError.notFound
        }
        return item.toDomain()
    }

    func getMediaChildren(id: Int) async throws -> [MediaItem] {
        let response = try await api.getMediaChildren(key: id)
        return response.MediaContainer?.Metadata?.map { $0.toDomain() } ?? []
    }

    // MARK: - Continue Watching / Recently Added

    func getRecentlyAdded() async throws -> [MediaItem] {
        let response = try await api.getRecentlyAdded()
        return response.MediaContainer?.Metadata?.map { $0.toDomain() } ?? []
    }

    func getOnDeck() async throws -> [MediaItem] {
        let response = try await api.getOnDeck()
        return response.MediaContainer?.Metadata?.map { $0.toDomain() } ?? []
    }

    /// Get recently added items for a specific library section
    func getSectionRecentlyAdded(sectionId: Int, limit: Int = 20) async throws -> [MediaItem] {
        // Use the standard library items endpoint with sort by addedAt
        // This is more reliable than a dedicated recentlyAdded endpoint
        let response = try await api.getLibraryItems(
            sectionId: sectionId,
            start: 0,
            size: limit,
            sort: "addedAt:desc",
            filters: nil
        )
        return response.MediaContainer?.Metadata?.map { $0.toDomain() } ?? []
    }

    /// Get on-deck items filtered by section type (movies only)
    func getSectionOnDeck(sectionId: Int) async throws -> [MediaItem] {
        // Plex doesn't have a section-specific onDeck endpoint,
        // so we get global onDeck and filter by type
        let response = try await api.getOnDeck()
        return response.MediaContainer?.Metadata?
            .filter { $0.type == "movie" }
            .map { $0.toDomain() } ?? []
    }

    // MARK: - Hubs

    func getHubs(sectionId: Int) async throws -> [Hub] {
        let response = try await api.getHubs(sectionId: sectionId)
        return response.MediaContainer?.Hub?.map { $0.toDomain() } ?? []
    }

    func getStreamingServices(sectionId: Int? = nil) async throws -> [StreamingServiceDTO] {
        let response = try await api.getStreamingServices(sectionId: sectionId)
        return response.MediaContainer?.Directory ?? []
    }

    // MARK: - Search

    func search(query: String) async throws -> [Hub] {
        let response = try await api.search(query: query, limit: 50)
        return response.MediaContainer?.Hub?.map { hub in
            Hub(
                key: nil,
                hubKey: nil,
                hubIdentifier: hub.safeType,
                type: hub.safeType,
                title: hub.safeTitle,
                size: hub.size ?? 0,
                more: false,
                style: nil,
                promoted: false,
                items: hub.Metadata?.map { $0.toDomain() } ?? []
            )
        } ?? []
    }

    // MARK: - Playback

    func getPlaybackURL(mediaItem: MediaItem, directPlay: Bool = true) async throws -> URL {
        guard let part = mediaItem.mediaVersions.first?.parts.first else {
            NSLog("MediaRepository: No media part found for item \(mediaItem.id)")
            throw NetworkError.notFound
        }

        // Build direct playback URL using the part key (same pattern as Android)
        guard let serverURL = UserDefaults.standard.serverURL else {
            NSLog("MediaRepository: No server URL configured")
            throw NetworkError.invalidURL
        }

        // The part.key is a relative path like "/library/parts/123/file.mp4"
        var playbackURL = serverURL.appendingPathComponent(part.key)

        // Add auth token as query parameter for authenticated playback
        if let token = KeychainHelper.shared.getToken() {
            var components = URLComponents(url: playbackURL, resolvingAgainstBaseURL: true)
            var queryItems = components?.queryItems ?? []
            queryItems.append(URLQueryItem(name: "X-Plex-Token", value: token))
            components?.queryItems = queryItems
            if let authenticatedURL = components?.url {
                playbackURL = authenticatedURL
            }
        }

        NSLog("MediaRepository: Playback URL = \(playbackURL.absoluteString)")

        return playbackURL
    }

    func updateProgress(mediaId: Int, timeMs: Int, state: String? = nil) async throws {
        try await api.updateProgress(key: mediaId, time: timeMs, state: state)
    }

    func markAsWatched(mediaId: Int) async throws {
        try await api.scrobble(key: mediaId)
    }

    func markAsUnwatched(mediaId: Int) async throws {
        try await api.unscrobble(key: mediaId)
    }
}
