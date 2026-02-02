import Foundation

actor OpenFlixAPI {
    static let shared = OpenFlixAPI()

    private var baseURL: URL?
    private var authToken: String?
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60  // Increased for stream startup
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        // Don't use snake_case conversion - server uses mixed casing (PascalCase for MediaContainer, etc.)

        self.encoder = JSONEncoder()
    }

    func configure(serverURL: URL, token: String?) {
        self.baseURL = serverURL
        self.authToken = token
    }

    func setToken(_ token: String?) {
        self.authToken = token
    }

    var isConfigured: Bool {
        baseURL != nil
    }

    var hasToken: Bool {
        authToken != nil
    }

    // MARK: - Generic Request

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let baseURL = baseURL else {
            throw NetworkError.invalidURL
        }

        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = endpoint.queryItems

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("OpenFlix-tvOS/1.0", forHTTPHeaderField: "User-Agent")

        if let body = endpoint.body {
            request.httpBody = body
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                // Debug: Log raw response for guide endpoints
                if endpoint.path.contains("guide") || endpoint.path.contains("livetv") {
                    let preview = String(data: data.prefix(2000), encoding: .utf8) ?? "N/A"
                    NSLog("OPENFLIX API [%@]: %@", endpoint.path, preview)
                }
                return try decoder.decode(T.self, from: data)
            } catch let decodingError {
                // Debug: Log decode errors
                let preview = String(data: data.prefix(2000), encoding: .utf8) ?? "N/A"
                NSLog("OPENFLIX ERROR: Failed to decode %@: %@", endpoint.path, decodingError.localizedDescription)
                NSLog("OPENFLIX ERROR Detail: %@", String(describing: decodingError))
                NSLog("OPENFLIX Response: %@", preview)
                throw NetworkError.decodingError(decodingError)
            }
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimited
        default:
            let message = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(httpResponse.statusCode, message)
        }
    }

    // Request that returns Void (for endpoints that don't return data)
    func requestVoid(_ endpoint: APIEndpoint) async throws {
        guard let baseURL = baseURL else {
            throw NetworkError.invalidURL
        }

        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = endpoint.queryItems

        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("OpenFlix-tvOS/1.0", forHTTPHeaderField: "User-Agent")

        if let body = endpoint.body {
            request.httpBody = body
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimited
        default:
            let message = String(data: data, encoding: .utf8)
            throw NetworkError.serverError(httpResponse.statusCode, message)
        }
    }

    // MARK: - Auth Convenience Methods

    func login(username: String, password: String) async throws -> AuthResponse {
        try await request(.login(username: username, password: password))
    }

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        try await request(.register(name: name, email: email, password: password))
    }

    func logout() async throws {
        try await requestVoid(.logout)
    }

    func getUser() async throws -> UserDTO {
        try await request(.getUser)
    }

    // MARK: - Profile Convenience Methods

    func getProfiles() async throws -> [ProfileDTO] {
        try await request(.getProfiles)
    }

    func getHomeUsers() async throws -> HomeUsersResponse {
        try await request(.getHomeUsers)
    }

    func switchProfile(uuid: String, pin: String?) async throws -> SwitchProfileResponse {
        try await request(.switchProfile(uuid: uuid, pin: pin))
    }

    // MARK: - Library Convenience Methods

    func getLibrarySections() async throws -> LibrarySectionsResponse {
        try await request(.getLibrarySections)
    }

    func getLibraryItems(sectionId: Int, start: Int? = nil, size: Int? = nil, sort: String? = nil, filters: [String: String]? = nil) async throws -> MediaContainerResponse {
        try await request(.getLibraryItems(sectionId: sectionId, start: start, size: size, sort: sort, filters: filters))
    }

    func getMediaDetails(key: Int) async throws -> MediaContainerResponse {
        try await request(.getMediaDetails(key: key))
    }

    func getMediaChildren(key: Int) async throws -> MediaContainerResponse {
        try await request(.getMediaChildren(key: key))
    }

    func getRecentlyAdded() async throws -> MediaContainerResponse {
        try await request(.getRecentlyAdded)
    }

    func getOnDeck() async throws -> MediaContainerResponse {
        try await request(.getOnDeck)
    }

    // MARK: - Hubs Convenience Methods

    func getHubs(sectionId: Int) async throws -> HubsResponse {
        try await request(.getHubs(sectionId: sectionId))
    }

    func getStreamingServices(sectionId: Int? = nil) async throws -> StreamingServicesResponse {
        try await request(.getStreamingServices(sectionId: sectionId))
    }

    // MARK: - Search

    func search(query: String, limit: Int? = 50) async throws -> SearchResponse {
        try await request(.search(query: query, limit: limit))
    }

    // MARK: - Playback

    func getPlaybackURL(path: String, directPlay: Bool = true) async throws -> PlaybackURLResponse {
        try await request(.getPlaybackURL(path: path, directPlay: directPlay))
    }

    func updateProgress(key: Int, time: Int, state: String? = nil) async throws {
        try await requestVoid(.updateProgress(key: key, time: time, state: state))
    }

    func scrobble(key: Int) async throws {
        try await requestVoid(.scrobble(key: key))
    }

    func unscrobble(key: Int) async throws {
        try await requestVoid(.unscrobble(key: key))
    }

    // MARK: - Live TV

    func getChannels() async throws -> ChannelsResponse {
        try await request(.getChannels)
    }

    func getChannelStream(id: String) async throws -> ChannelStreamResponse {
        try await request(.getChannelStream(id: id))
    }

    func getGuide(start: Date? = nil, end: Date? = nil) async throws -> GuideResponse {
        try await request(.getGuide(start: start, end: end))
    }

    func getNowPlaying() async throws -> NowPlayingResponse {
        try await request(.getNowPlaying)
    }

    func toggleFavorite(channelId: String) async throws {
        try await requestVoid(.toggleFavorite(channelId: channelId))
    }

    // MARK: - DVR

    func getRecordings(status: String? = nil) async throws -> RecordingsResponse {
        try await request(.getRecordings(status: status))
    }

    func getRecording(id: Int) async throws -> RecordingDTO {
        try await request(.getRecording(id: id))
    }

    func scheduleRecording(channelId: String, startTime: Date, endTime: Date, title: String) async throws -> RecordingDTO {
        try await request(.scheduleRecording(channelId: channelId, startTime: startTime, endTime: endTime, title: title))
    }

    func recordFromProgram(channelId: String, programId: String) async throws -> RecordingDTO {
        try await request(.recordFromProgram(channelId: channelId, programId: programId))
    }

    func deleteRecording(id: Int) async throws {
        try await requestVoid(.deleteRecording(id: id))
    }

    func getRecordingStream(id: Int) async throws -> RecordingStreamResponse {
        try await request(.getRecordingStream(id: id))
    }

    // MARK: - Sources

    func getM3USources() async throws -> M3USourcesResponse {
        try await request(.getM3USources)
    }

    func addM3USource(name: String, url: String, epgUrl: String? = nil) async throws -> M3USourceDTO {
        try await request(.addM3USource(name: name, url: url, epgUrl: epgUrl))
    }

    func deleteM3USource(id: Int) async throws {
        try await requestVoid(.deleteM3USource(id: id))
    }

    func refreshM3USource(id: Int) async throws {
        try await requestVoid(.refreshM3USource(id: id))
    }

    func getXtreamSources() async throws -> XtreamSourcesResponse {
        try await request(.getXtreamSources)
    }

    func addXtreamSource(name: String, serverUrl: String, username: String, password: String) async throws -> XtreamSourceDTO {
        try await request(.addXtreamSource(name: name, serverUrl: serverUrl, username: username, password: password))
    }

    func deleteXtreamSource(id: Int) async throws {
        try await requestVoid(.deleteXtreamSource(id: id))
    }

    // MARK: - Watchlist

    func getWatchlist() async throws -> WatchlistResponse {
        try await request(.getWatchlist)
    }

    func addToWatchlist(mediaId: Int) async throws {
        try await requestVoid(.addToWatchlist(mediaId: mediaId))
    }

    func removeFromWatchlist(mediaId: Int) async throws {
        try await requestVoid(.removeFromWatchlist(mediaId: mediaId))
    }

    // MARK: - Playlists

    func getPlaylists() async throws -> PlaylistsResponse {
        try await request(.getPlaylists)
    }

    func createPlaylist(name: String) async throws -> PlaylistDTO {
        try await request(.createPlaylist(name: name))
    }

    func getPlaylistItems(id: Int) async throws -> PlaylistItemsResponse {
        try await request(.getPlaylistItems(id: id))
    }

    func addToPlaylist(id: Int, mediaIds: [Int]) async throws {
        try await requestVoid(.addToPlaylist(id: id, mediaIds: mediaIds))
    }

    func deletePlaylist(id: Int) async throws {
        try await requestVoid(.deletePlaylist(id: id))
    }

    // MARK: - Server Info

    func getServerInfo() async throws -> ServerInfoDTO {
        try await request(.getServerInfo)
    }

    func getCapabilities() async throws -> ServerCapabilitiesDTO {
        try await request(.getCapabilities)
    }
}
