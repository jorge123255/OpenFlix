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
            sectionId: String(sectionId),
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
        let response = try await api.getMediaDetails(key: String(id))
        guard let item = response.MediaContainer?.Metadata?.first else {
            throw NetworkError.notFound
        }
        return item.toDomain()
    }

    func getMediaChildren(id: Int) async throws -> [MediaItem] {
        let response = try await api.getMediaChildren(key: String(id))
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
        let response = try await api.getLibraryItems(
            sectionId: String(sectionId),
            start: 0,
            size: limit,
            sort: "addedAt:desc",
            filters: nil
        )
        return response.MediaContainer?.Metadata?.map { $0.toDomain() } ?? []
    }

    /// Get on-deck items filtered by section type (movies only)
    func getSectionOnDeck(sectionId: Int) async throws -> [MediaItem] {
        let response = try await api.getOnDeck()
        return response.MediaContainer?.Metadata?
            .filter { $0.type == "movie" }
            .map { $0.toDomain() } ?? []
    }

    // MARK: - Hubs

    func getHubs(sectionId: Int) async throws -> [Hub] {
        let response = try await api.getHubs(sectionId: String(sectionId))
        return response.MediaContainer?.Hub?.map { $0.toDomain() } ?? []
    }

    // MARK: - Home rails (On Later / Live Now)

    func getOnLaterTonight() async throws -> [OnLaterProgram] {
        let response = try await api.getOnLaterTonight()
        return response.allItems.map { $0.toDomain() }
    }

    func getOnLaterSports() async throws -> [OnLaterProgram] {
        let response = try await api.getOnLaterSports()
        return response.allItems.map { $0.toDomain() }
    }

    func getOnLaterTVShows() async throws -> [OnLaterProgram] {
        let response = try await api.getOnLater(endpoint: "/api/onlater/tvshows")
        return response.allItems.map { $0.toDomain() }
    }

    func getOnLaterMovies() async throws -> [OnLaterProgram] {
        let response = try await api.getOnLaterMovies()
        return response.allItems.map { $0.toDomain() }
    }

    func getOnLaterKids() async throws -> [OnLaterProgram] {
        let response = try await api.getOnLaterKids()
        return response.allItems.map { $0.toDomain() }
    }

    func getOnLaterNews() async throws -> [OnLaterProgram] {
        let response = try await api.getOnLaterNews()
        return response.allItems.map { $0.toDomain() }
    }

    func getLiveTVOnNow() async throws -> [(channel: Channel, program: Program?)] {
        let response = try await api.getLiveTVOnNow()
        return (response.channels ?? []).map { dto in
            let channel = dto.toDomain()
            return (channel: channel, program: channel.nowPlaying)
        }
    }

    func getStreamingServices(sectionId: Int? = nil) async throws -> [StreamingServiceDTO] {
        let response = try await api.getStreamingServices(sectionId: sectionId.map { String($0) })
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

    func getPlaybackURL(mediaItem: MediaItem, offset: Int? = nil) async throws -> URL {
        guard let serverURL = UserDefaults.standard.serverURL else {
            NSLog("MediaRepository: No server URL configured")
            throw NetworkError.invalidURL
        }

        // Use HLS transcode endpoint — server will remux or transcode as needed
        let transcodeURL = serverURL.appendingPathComponent("/video/-/transcode/universal/start.m3u8")
        guard var components = URLComponents(url: transcodeURL, resolvingAgainstBaseURL: true) else {
            throw NetworkError.invalidURL
        }

        var queryItems = [
            URLQueryItem(name: "path", value: "/library/metadata/\(mediaItem.id)"),
            URLQueryItem(name: "offset", value: String(offset ?? 0)),
            URLQueryItem(name: "videoQuality", value: "original"),
        ]

        if let token = KeychainHelper.shared.getToken() {
            queryItems.append(URLQueryItem(name: "X-Plex-Token", value: token))
        }

        components.queryItems = queryItems
        guard let playbackURL = components.url else {
            throw NetworkError.invalidURL
        }

        NSLog("MediaRepository: HLS Transcode URL = \(playbackURL.absoluteString)")

        return playbackURL
    }

    func updateProgress(mediaId: Int, timeMs: Int, state: String? = nil) async throws {
        try await api.updateProgress(key: String(mediaId), time: timeMs, state: state ?? "playing")
    }

    func markAsWatched(mediaId: Int) async throws {
        try await api.scrobble(key: String(mediaId))
    }

    func markAsUnwatched(mediaId: Int) async throws {
        try await api.unscrobble(key: String(mediaId))
    }
}
