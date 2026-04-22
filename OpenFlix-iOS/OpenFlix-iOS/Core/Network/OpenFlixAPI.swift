import Foundation
#if canImport(UIKit)
import UIKit
#endif

actor OpenFlixAPI {
    static let shared = OpenFlixAPI()
    private var serverURL: URL?
    private var token: String?
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    private let snakeCaseDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    /// Stable device identifier used for device registration and X-Device-ID header
    nonisolated let deviceId: String = {
        // Use a stable UUID stored in UserDefaults to avoid actor-isolation issues with UIDevice
        let key = "openflix_device_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }()

    func configure(serverURL: String, token: String? = nil) {
        self.serverURL = URL(string: serverURL)
        self.token = token
    }

    func configure(serverURL: URL, token: String? = nil) {
        self.serverURL = serverURL
        self.token = token
    }

    func setToken(_ token: String?) { self.token = token }
    func getServerURL() -> URL? { return serverURL }

    // MARK: - Generic Request
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let serverURL = serverURL else { throw NetworkError.invalidURL }
        var components = URLComponents(url: serverURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
        components?.queryItems = endpoint.queryItems
        guard let url = components?.url else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.requestTimeout
        NSLog("API REQUEST: %@ %@ token=%@", endpoint.method.rawValue, url.absoluteString, token != nil ? "YES(\(token!.prefix(8))...)" : "NIL")
        if let token = token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        if endpoint.method == .POST || endpoint.method == .PUT || endpoint.method == .PATCH {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = endpoint.body
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.noData }
        switch httpResponse.statusCode {
        case 200...299: break
        case 401: throw NetworkError.unauthorized
        case 404: throw NetworkError.notFound
        case 429: throw NetworkError.rateLimited
        default: throw NetworkError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        do { return try snakeCaseDecoder.decode(T.self, from: data) }
        catch let snakeError {
            do { return try decoder.decode(T.self, from: data) }
            catch let plainError {
                // Log both decoder failures so console diagnostics
                // pinpoint the failing path; throw the structured
                // .decodingError(error) so NetworkError's pretty
                // printer surfaces it in the user-visible message.
                NSLog("DECODE FAIL %@: %@", String(describing: T.self), String(describing: plainError))
                NSLog("DECODE FAIL %@ snake-case attempt: %@", String(describing: T.self), String(describing: snakeError))
                throw NetworkError.decodingError(plainError)
            }
        }
    }

    func requestVoid(_ endpoint: APIEndpoint) async throws {
        guard let serverURL = serverURL else { throw NetworkError.invalidURL }
        var components = URLComponents(url: serverURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
        components?.queryItems = endpoint.queryItems
        guard let url = components?.url else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        if let token = token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.setValue(deviceId, forHTTPHeaderField: "X-Device-ID")
        if endpoint.method == .POST || endpoint.method == .PUT || endpoint.method == .PATCH {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = endpoint.body
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.noData }
        switch httpResponse.statusCode {
        case 200...299: return
        case 401: throw NetworkError.unauthorized
        case 404: throw NetworkError.notFound
        case 429: throw NetworkError.rateLimited
        default: throw NetworkError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    func requestData(_ endpoint: APIEndpoint) async throws -> Data {
        guard let serverURL = serverURL else { throw NetworkError.invalidURL }
        var components = URLComponents(url: serverURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
        components?.queryItems = endpoint.queryItems
        guard let url = components?.url else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        if let token = token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.noData }
        switch httpResponse.statusCode {
        case 200...299: return data
        case 401: throw NetworkError.unauthorized
        case 404: throw NetworkError.notFound
        default: throw NetworkError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    func buildURL(for endpoint: APIEndpoint) -> URL? {
        guard let serverURL = serverURL else { return nil }
        var components = URLComponents(url: serverURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)
        components?.queryItems = endpoint.queryItems
        if let token = token {
            var items = components?.queryItems ?? []
            items.append(URLQueryItem(name: "X-Plex-Token", value: token))
            components?.queryItems = items
        }
        return components?.url
    }

    func buildURL(path: String) -> URL? {
        guard let serverURL = serverURL else { return nil }
        var components = URLComponents(url: serverURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if let token = token {
            components?.queryItems = [URLQueryItem(name: "X-Plex-Token", value: token)]
        }
        return components?.url
    }

    // MARK: - Auth
    func login(username: String, password: String) async throws -> AuthResponse {
        try await request(.login(username: username, password: password))
    }
    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        try await request(.register(name: name, email: email, password: password))
    }
    func logout() async throws { try await requestVoid(.logout) }
    func getUser() async throws -> UserDTO { try await request(.getUser) }
    func updateUser(name: String? = nil, email: String? = nil) async throws -> UserDTO {
        try await request(.updateUser(name: name, email: email))
    }
    func changePassword(currentPassword: String, newPassword: String) async throws {
        try await requestVoid(.changePassword(currentPassword: currentPassword, newPassword: newPassword))
    }

    // MARK: - Profiles
    func getProfiles() async throws -> [ProfileDTO] { try await request(.getProfiles) }
    func getHomeUsers() async throws -> HomeUsersResponse { try await request(.getHomeUsers) }
    func switchProfile(uuid: String, pin: String? = nil) async throws -> SwitchProfileResponse {
        try await request(.switchProfile(uuid: uuid, pin: pin))
    }
    func createProfile(name: String, isKid: Bool = false, pin: String? = nil) async throws -> ProfileDTO {
        try await request(.createProfile(name: name, isKid: isKid, pin: pin))
    }
    func deleteProfile(id: String) async throws { try await requestVoid(.deleteProfile(id: id)) }

    // MARK: - Parental Controls
    func setParentalPin(pin: String) async throws { try await requestVoid(.setParentalPin(pin: pin)) }
    func verifyParentalPin(pin: String) async throws -> SuccessResponse {
        try await request(.verifyParentalPin(pin: pin))
    }
    func getParentalSettings() async throws -> ParentalSettingsResponse {
        try await request(.getParentalSettings)
    }
    func updateParentalSettings(enabled: Bool, rating: String? = nil, pin: String? = nil) async throws {
        try await requestVoid(.updateParentalSettings(enabled: enabled, rating: rating, pin: pin))
    }

    // MARK: - Library
    func getLibrarySections() async throws -> LibrarySectionsResponse { try await request(.getLibrarySections) }
    func getLibraryItems(sectionId: String, start: Int? = nil, size: Int? = nil, sort: String? = nil, filters: [String: String]? = nil) async throws -> MediaContainerResponse {
        try await request(.getLibraryItems(sectionId: sectionId, start: start, size: size, sort: sort, filters: filters))
    }
    func getLibraryFilters(sectionId: String) async throws -> FiltersResponse { try await request(.getLibraryFilters(sectionId: sectionId)) }
    func getLibrarySorts(sectionId: String) async throws -> SortsResponse { try await request(.getLibrarySorts(sectionId: sectionId)) }
    func getMediaDetails(key: String) async throws -> MediaContainerResponse { try await request(.getMediaDetails(key: key)) }
    func getMediaChildren(key: String) async throws -> MediaContainerResponse { try await request(.getMediaChildren(key: key)) }
    func getRecentlyAdded() async throws -> MediaContainerResponse { try await request(.getRecentlyAdded) }
    func getOnDeck() async throws -> MediaContainerResponse { try await request(.getOnDeck) }
    func getSectionRecentlyAdded(sectionId: String) async throws -> MediaContainerResponse { try await request(.getSectionRecentlyAdded(sectionId: sectionId)) }
    func refreshLibrarySection(sectionId: String) async throws { try await requestVoid(.refreshLibrarySection(sectionId: sectionId)) }

    // MARK: - Hubs
    func getHubs(sectionId: String) async throws -> HubsResponse { try await request(.getHubs(sectionId: sectionId)) }
    func getStreamingServices(sectionId: String? = nil) async throws -> StreamingServicesResponse {
        try await request(.getStreamingServices(sectionId: sectionId))
    }
    func getTrending() async throws -> HubsResponse { try await request(.getTrending) }
    func getPopularMovies() async throws -> HubsResponse { try await request(.getPopularMovies) }
    func getPopularTV() async throws -> HubsResponse { try await request(.getPopularTV) }
    func getTopRatedMovies() async throws -> HubsResponse { try await request(.getTopRatedMovies) }

    // MARK: - Search
    func search(query: String, limit: Int? = nil) async throws -> SearchResponse {
        try await request(.search(query: query, limit: limit))
    }

    // MARK: - Playback
    func getPlaybackURL(path: String, directPlay: Bool = true) async throws -> PlaybackURLResponse {
        try await request(.getPlaybackURL(path: path, directPlay: directPlay))
    }
    func updateProgress(key: String, time: Int, state: String) async throws {
        try await requestVoid(.updateProgress(key: key, time: time, state: state))
    }
    func scrobble(key: String) async throws { try await requestVoid(.scrobble(key: key)) }
    func unscrobble(key: String) async throws { try await requestVoid(.unscrobble(key: key)) }
    func timeline(ratingKey: String, state: String, time: Int, duration: Int) async throws {
        try await requestVoid(.timeline(ratingKey: ratingKey, state: state, time: time, duration: duration))
    }
    func removeFromContinueWatching(ratingKey: String) async throws {
        try await requestVoid(.removeFromContinueWatching(ratingKey: ratingKey))
    }

    // MARK: - Sessions
    func getSessions() async throws -> SessionsResponse { try await request(.getSessions) }
    func startSession(mediaId: String) async throws { try await requestVoid(.startSession(mediaId: mediaId)) }
    func updateSession(id: String, state: String? = nil, position: Int? = nil) async throws {
        try await requestVoid(.updateSession(id: id, state: state, position: position))
    }
    func stopSession(id: String) async throws { try await requestVoid(.stopSession(id: id)) }

    // MARK: - Playlists
    func getPlaylists() async throws -> PlaylistsResponse { try await request(.getPlaylists) }
    func createPlaylist(name: String) async throws -> PlaylistDTO { try await request(.createPlaylist(name: name)) }
    func getPlaylist(id: String) async throws -> PlaylistDTO { try await request(.getPlaylist(id: id)) }
    func getPlaylistItems(id: String) async throws -> PlaylistItemsResponse { try await request(.getPlaylistItems(id: id)) }
    func addToPlaylist(id: String, mediaIds: [String]) async throws { try await requestVoid(.addToPlaylist(id: id, mediaIds: mediaIds)) }
    func removeFromPlaylist(id: String, itemId: String) async throws { try await requestVoid(.removeFromPlaylist(id: id, itemId: itemId)) }
    func deletePlaylist(id: String) async throws { try await requestVoid(.deletePlaylist(id: id)) }

    // MARK: - Personal Sections
    func getPersonalSections() async throws -> PersonalSectionsResponse { try await request(.getPersonalSections) }
    func createPersonalSection(title: String, type: String, smart: Bool = false, filter: String? = nil) async throws -> PersonalSectionDTO {
        try await request(.createPersonalSection(title: title, type: type, smart: smart, filter: filter))
    }
    func deletePersonalSection(id: String) async throws { try await requestVoid(.deletePersonalSection(id: id)) }
    func getAvailableGenres() async throws -> GenresListResponse { try await request(.getAvailableGenres) }

    // MARK: - Watchlist
    func getWatchlist() async throws -> WatchlistResponse { try await request(.getWatchlist) }
    func addToWatchlist(mediaId: String) async throws { try await requestVoid(.addToWatchlist(mediaId: mediaId)) }
    func removeFromWatchlist(mediaId: String) async throws { try await requestVoid(.removeFromWatchlist(mediaId: mediaId)) }

    // MARK: - Collections
    func getCollections(sectionId: String) async throws -> CollectionsResponse { try await request(.getCollections(sectionId: sectionId)) }
    func getCollectionItems(id: String) async throws -> MediaContainerResponse { try await request(.getCollectionItems(id: id)) }
    func deleteCollection(id: String) async throws { try await requestVoid(.deleteCollection(id: id)) }

    // MARK: - Live TV Channels
    func getChannels() async throws -> ChannelsResponse { try await request(.getChannels) }
    func getChannel(id: String) async throws -> ChannelDTO { try await request(.getChannel(id: id)) }
    func updateChannel(id: String, name: String? = nil, number: String? = nil, enabled: Bool? = nil, group: String? = nil, logo: String? = nil) async throws {
        try await requestVoid(.updateChannel(id: id, name: name, number: number, enabled: enabled, group: group, logo: logo))
    }
    func toggleFavorite(channelId: String) async throws { try await requestVoid(.toggleFavorite(channelId: channelId)) }
    func getChannelStream(id: String) async throws -> ChannelStreamResponse { try await request(.getChannelStream(id: id)) }
    func channelStreamURL(id: String) -> URL? { buildURL(for: .getChannelStream(id: id)) }
    func autoDetectEPGMappings() async throws { try await requestVoid(.autoDetectEPGMappings) }

    // MARK: - Channel Groups
    func getChannelGroups() async throws -> ChannelGroupsResponse { try await request(.getChannelGroups) }
    func createChannelGroup(name: String, channelIds: [String]) async throws { try await requestVoid(.createChannelGroup(name: name, channelIds: channelIds)) }
    func deleteChannelGroup(id: String) async throws { try await requestVoid(.deleteChannelGroup(id: id)) }
    func autoDetectDuplicates() async throws { try await requestVoid(.autoDetectDuplicates) }
    func getChannelGroupStream(id: String) async throws -> ChannelStreamResponse { try await request(.getChannelGroupStream(id: id)) }

    // MARK: - Guide
    func getGuide(start: String? = nil, end: String? = nil) async throws -> GuideResponse { try await request(.getGuide(start: start, end: end)) }
    func getChannelGuide(channelId: String, start: String? = nil, end: String? = nil) async throws -> GuideResponse {
        try await request(.getChannelGuide(channelId: channelId, start: start, end: end))
    }
    func getNowPlaying() async throws -> NowPlayingResponse { try await request(.getNowPlaying) }
    func getActiveTunerBackend() async throws -> TunerBackend { try await request(.getActiveTunerBackend) }
    func getDirectvLibrary(accountId: String) async throws -> DirectvLibraryResponse {
        try await request(.getDirectvLibrary(accountId: accountId))
    }
    func createDirectvRecording(accountId: String, request payload: DirectvRecordRequest) async throws -> DirectvBookingResponse {
        try await request(.createDirectvRecording(accountId: accountId, request: payload))
    }
    func createDirectvSeriesRecording(accountId: String, request payload: DirectvRecordRequest) async throws -> DirectvBookingResponse {
        try await request(.createDirectvSeriesRecording(accountId: accountId, request: payload))
    }
    func getDirectvRecordStatus(accountId: String, query: DirectvRecordStatusQuery) async throws -> DirectvRecordStatus {
        try await request(.getDirectvRecordStatus(accountId: accountId, query: query))
    }
    func startDirectvDownload(accountId: String, recordId: String) async throws -> DirectvDownloadStartResponse {
        try await request(.startDirectvDownload(accountId: accountId, recordId: recordId))
    }
    func getDirectvDownloads() async throws -> [ExternalDownloadJob] {
        try await request(.getDirectvDownloads)
    }
    func getDirectvDownloadJob(jobId: String) async throws -> ExternalDownloadJob {
        try await request(.getDirectvDownloadJob(jobId: jobId))
    }
    func directvDownloadFileURL(jobId: String) -> URL? {
        buildURL(for: .getDirectvDownloadFile(jobId: jobId))
    }
    func getDirectvSeriesRules(accountId: String) async throws -> [DirectvSeriesRule] {
        try await request(.getDirectvSeriesRules(accountId: accountId))
    }
    func updateDirectvSeriesRule(accountId: String, ruleId: String, enabled: Bool) async throws {
        try await requestVoid(.updateDirectvSeriesRule(accountId: accountId, ruleId: ruleId, enabled: enabled))
    }
    func deleteDirectvSeriesRule(accountId: String, ruleId: String) async throws {
        try await requestVoid(.deleteDirectvSeriesRule(accountId: accountId, ruleId: ruleId))
    }
    func cancelDirectvRecording(accountId: String, recordId: String) async throws {
        try await requestVoid(.cancelDirectvRecording(accountId: accountId, recordId: recordId))
    }
    func deleteDirectvRecording(accountId: String, recordId: String) async throws {
        try await requestVoid(.deleteDirectvRecording(accountId: accountId, recordId: recordId))
    }
    func getSlingLibrary(accountId: String) async throws -> SlingLibraryResponse {
        try await request(.getSlingLibrary(accountId: accountId))
    }
    func getSlingRecordings(accountId: String) async throws -> SlingRecordingListResponse {
        try await request(.getSlingRecordings(accountId: accountId))
    }
    func createSlingRecording(accountId: String, request payload: SlingRecordRequest) async throws -> SlingBookingResponse {
        try await request(.createSlingRecording(accountId: accountId, request: payload))
    }
    func deleteSlingRecording(accountId: String, recordId: String) async throws {
        try await requestVoid(.deleteSlingRecording(accountId: accountId, recordId: recordId))
    }
    func getSlingSeriesRules(accountId: String) async throws -> SlingSeriesRuleListResponse {
        try await request(.getSlingSeriesRules(accountId: accountId))
    }
    func createSlingSeriesRule(accountId: String, request payload: SlingSeriesRuleRequest) async throws -> SlingBookingResponse {
        try await request(.createSlingSeriesRule(accountId: accountId, request: payload))
    }
    func getFrndlyLibrary() async throws -> FrndlyLibraryResponse {
        try await request(.getFrndlyLibrary)
    }
    func getFrndlyRecordings() async throws -> FrndlyRecordingListResponse {
        try await request(.getFrndlyRecordings)
    }
    func createFrndlyRecording(request payload: FrndlyPathRequest) async throws -> FrndlyBookingResponse {
        try await request(.createFrndlyRecording(request: payload))
    }
    func deleteFrndlyRecording(recordId: String) async throws {
        try await requestVoid(.deleteFrndlyRecording(recordId: recordId))
    }
    func startFrndlyDownload(recordId: String) async throws -> FrndlyDownloadResponse {
        try await request(.startFrndlyDownload(recordId: recordId))
    }
    func getFrndlyDownloadJob(jobId: String) async throws -> FrndlyDownloadJob {
        try await request(.getFrndlyDownloadJob(jobId: jobId))
    }
    func frndlyDownloadFileURL(jobId: String) -> URL? {
        buildURL(for: .getFrndlyDownloadFile(jobId: jobId))
    }
    func getFrndlySeriesRules() async throws -> FrndlySeriesRuleListResponse {
        try await request(.getFrndlySeriesRules)
    }
    func createFrndlySeriesRule(request payload: FrndlyPathRequest) async throws -> FrndlyBookingResponse {
        try await request(.createFrndlySeriesRule(request: payload))
    }
    func getFrndlyUpcomingRecordings() async throws -> [ProviderRecordingItem] {
        try await request(.getFrndlyUpcomingRecordings)
    }
    func getFrndlyRecordingPlaybackAuth(recordId: String) async throws -> FrndlyPlaybackAuthResponse {
        try await request(.getFrndlyRecordingPlaybackAuth(recordId: recordId))
    }

    // MARK: - Sources
    func getM3USources() async throws -> M3USourcesResponse { try await request(.getM3USources) }
    func addM3USource(name: String, url: String, epgUrl: String? = nil) async throws -> M3USourceDTO {
        try await request(.addM3USource(name: name, url: url, epgUrl: epgUrl))
    }
    func deleteM3USource(id: String) async throws { try await requestVoid(.deleteM3USource(id: id)) }
    func refreshM3USource(id: String) async throws { try await requestVoid(.refreshM3USource(id: id)) }
    func getXtreamSources() async throws -> XtreamSourcesResponse { try await request(.getXtreamSources) }
    func addXtreamSource(name: String, serverUrl: String, username: String, password: String) async throws -> XtreamSourceDTO {
        try await request(.addXtreamSource(name: name, serverUrl: serverUrl, username: username, password: password))
    }
    func deleteXtreamSource(id: String) async throws { try await requestVoid(.deleteXtreamSource(id: id)) }
    func getEPGSources() async throws -> EPGSourcesResponse { try await request(.getEPGSources) }
    func addEPGSource(name: String, url: String?, type: String, tvguideProviderId: String? = nil, tvguideZipCode: String? = nil, tvguideDays: Int? = nil) async throws { try await requestVoid(.addEPGSource(name: name, url: url, type: type, tvguideProviderId: tvguideProviderId, tvguideZipCode: tvguideZipCode, tvguideDays: tvguideDays)) }
    func deleteEPGSource(id: String) async throws { try await requestVoid(.deleteEPGSource(id: id)) }
    func refreshEPGSource(id: String) async throws { try await requestVoid(.refreshEPGSource(id: id)) }

    // MARK: - EPG Management
    func getEPGStats() async throws -> EPGStatsResponse { try await request(.getEPGStats) }
    func refreshAllEPG() async throws { try await requestVoid(.refreshAllEPG) }
    func getEPGSchedulerStatus() async throws -> EPGSchedulerStatusResponse { try await request(.getEPGSchedulerStatus) }
    func getGuideCacheStats() async throws -> GuideCacheStatsResponse { try await request(.getGuideCacheStats) }
    func invalidateGuideCache() async throws { try await requestVoid(.invalidateGuideCache) }
    func getEPGSourceHealth() async throws -> EPGSourceHealthResponse { try await request(.getEPGSourceHealth) }

    // MARK: - Catch-up / Timeshift / Archive
    func getCatchupPrograms(channelId: String) async throws -> CatchUpResponse { try await request(.getCatchupPrograms(channelId: channelId)) }
    func startTimeshift(channelId: String) async throws { try await requestVoid(.startTimeshift(channelId: channelId)) }
    func stopTimeshift(channelId: String) async throws { try await requestVoid(.stopTimeshift(channelId: channelId)) }
    func timeshiftStreamURL(channelId: String) -> URL? { buildURL(for: .getTimeshiftStream(channelId: channelId)) }
    func enableArchive(channelId: String, days: Int) async throws { try await requestVoid(.enableArchive(channelId: channelId, days: days)) }
    func disableArchive(channelId: String) async throws { try await requestVoid(.disableArchive(channelId: channelId)) }
    func getArchiveStatus() async throws -> ArchiveStatusResponse { try await request(.getArchiveStatus) }
    func archiveStreamURL(archiveId: String) -> URL? { buildURL(for: .getArchiveStream(archiveId: archiveId)) }

    // MARK: - On Later
    func getOnLaterAll() async throws -> OnLaterResponse { try await request(.getOnLaterAll) }
    func getOnLaterMovies() async throws -> OnLaterResponse { try await request(.getOnLaterMovies) }
    func getOnLaterSports(league: String? = nil, team: String? = nil) async throws -> OnLaterResponse {
        try await request(.getOnLaterSports(league: league, team: team))
    }
    func getOnLaterKids() async throws -> OnLaterResponse { try await request(.getOnLaterKids) }
    func getOnLaterNews() async throws -> OnLaterResponse { try await request(.getOnLaterNews) }
    func getOnLaterPremieres() async throws -> OnLaterResponse { try await request(.getOnLaterPremieres) }
    func getOnLaterTonight() async throws -> OnLaterResponse { try await request(.getOnLaterTonight) }
    func getOnLaterWeek() async throws -> OnLaterResponse { try await request(.getOnLaterWeek) }
    func getOnLaterStats() async throws -> OnLaterStatsResponse { try await request(.getOnLaterStats) }
    func getOnLaterHoliday() async throws -> OnLaterResponse { try await request(.getOnLaterHoliday) }
    func getOnLaterHalloween() async throws -> OnLaterResponse { try await request(.getOnLaterHalloween) }
    func getOnLaterSeasonal(event: String? = nil) async throws -> OnLaterResponse {
        try await request(.getOnLaterSeasonal(event: event))
    }
    /// Generic On Later endpoint loader — maps category endpoint string to API call
    func getOnLater(endpoint: String) async throws -> OnLaterResponse {
        switch endpoint {
        case "movies":   return try await getOnLaterMovies()
        case "sports":   return try await getOnLaterSports()
        case "kids":     return try await getOnLaterKids()
        case "news":     return try await getOnLaterNews()
        case "holiday":  return try await getOnLaterHoliday()
        case "halloween": return try await getOnLaterHalloween()
        case "seasonal": return try await getOnLaterSeasonal()
        default:         return try await getOnLaterAll()
        }
    }

    // MARK: - Team Pass
    func getTeamPasses() async throws -> TeamPassesResponse { try await request(.getTeamPasses) }
    func createTeamPass(teamName: String, league: String, channelIds: [String]? = nil, prePadding: Int? = nil, postPadding: Int? = nil) async throws -> TeamPassDTO {
        try await request(.createTeamPass(teamName: teamName, league: league, channelIds: channelIds, prePadding: prePadding, postPadding: postPadding))
    }
    func deleteTeamPass(id: String) async throws { try await requestVoid(.deleteTeamPass(id: id)) }
    func toggleTeamPass(id: String) async throws { try await requestVoid(.toggleTeamPass(id: id)) }
    func getTeamPassUpcoming(id: String) async throws -> TeamPassUpcomingResponse { try await request(.getTeamPassUpcoming(id: id)) }
    func searchTeams(query: String) async throws -> TeamsResponse { try await request(.searchTeams(query: query)) }
    func getLeagues() async throws -> LeaguesResponse { try await request(.getLeagues) }

    // MARK: - DVR Recordings
    func getRecordings(status: String? = nil) async throws -> RecordingsResponse { try await request(.getRecordings(status: status)) }
    func getRecording(id: String) async throws -> RecordingDTO { try await request(.getRecording(id: id)) }
    func scheduleRecording(channelId: String, startTime: String, endTime: String, title: String) async throws -> RecordingDTO {
        try await request(.scheduleRecording(channelId: channelId, startTime: startTime, endTime: endTime, title: title))
    }
    func recordFromProgram(channelId: String, programId: String) async throws -> RecordingDTO {
        try await request(.recordFromProgram(channelId: channelId, programId: programId))
    }
    func bookRecordingFromProgram(request payload: ProgramBookingRequest) async throws -> ProgramBookingResponse {
        try await request(.bookRecordingFromProgram(request: payload))
    }
    func previewProgramBooking(request payload: ProgramBookingRequest) async throws -> ProgramBookingPreviewResponse {
        try await request(.previewProgramBooking(request: payload))
    }
    func getDVRCapabilities() async throws -> DVRCapabilitiesResponse {
        try await request(.getDVRCapabilities)
    }

    // MARK: - ESPN (DVR-Tuner authoritative, OpenFlix-proxied)

    /// `GET /api/tuner-backends/active/espn/hub`
    /// Returns linearChannels (always), disneyHub (Disney page or null),
    /// hasDisneyHub. There is no flattened "rails / featuredItem" model —
    /// render linearChannels directly, and feed disneyHub into the shared
    /// Disney page renderer when present.
    func espnHub() async throws -> ESPNHubResponse {
        try await request(.espnHub)
    }

    /// Build the URL for `/api/tuner-backends/active/espn/play/stream`.
    /// The endpoint serves raw MPEG-TS — there's no JSON to parse. The
    /// client just constructs the URL with all browse-derived context as
    /// query params and hands it to VLC.
    func espnPlayStreamURL(params: [URLQueryItem]) -> URL? {
        buildURL(for: .espnPlayStream(params: params))
    }

    /// Build the URL for `/api/tuner-backends/active/stream/:channelId`.
    /// Used for ESPN linear channels from the hub. Returns raw MPEG-TS;
    /// hand directly to VLC.
    func tunerActiveStreamURL(channelId: String) -> URL? {
        buildURL(for: .tunerActiveStream(channelId: channelId))
    }

    /// Admin-style action: ask the server to refresh ESPN EPG / token.
    /// Useful as a recovery path when the upstream returns auth.expired.
    func espnRefreshEPG() async throws { try await requestVoid(.espnRefreshEPG) }

    // MARK: - Disney Explore (DVR-Tuner authoritative, OpenFlix-proxied)

    func disneyGlobalNav() async throws -> DXGlobalNavResponse {
        try await request(.disneyGlobalNav)
    }
    func disneyDeeplink(refId: String, refIdType: String) async throws -> DXDeeplinkResponse {
        try await request(.disneyDeeplink(refId: refId, refIdType: refIdType))
    }
    func disneyPage(pageId: String, params: [URLQueryItem]) async throws -> DXPageResponse {
        try await request(.disneyPage(pageId: pageId, params: params))
    }
    func disneySet(setId: String, params: [URLQueryItem]) async throws -> DXSetResponse {
        try await request(.disneySet(setId: setId, params: params))
    }
    func disneySearch(query: String) async throws -> DXPageResponse {
        try await request(.disneySearch(query: query))
    }
    func disneyPlayerExperience(mediaId: String) async throws -> DXPlayerExperienceResponse {
        try await request(.disneyPlayerExperience(mediaId: mediaId))
    }
    func deleteRecording(id: String) async throws { try await requestVoid(.deleteRecording(id: id)) }
    func getRecordingStats() async throws -> RecordingStatsResponse { try await request(.getRecordingStats) }
    func getRecordingStream(id: String) async throws -> RecordingStreamResponse { try await request(.getRecordingStream(id: id)) }
    func updateRecordingProgress(id: String, time: Int) async throws { try await requestVoid(.updateRecordingProgress(id: id, time: time)) }
    func toggleRecordingWatched(id: String) async throws { try await requestVoid(.toggleRecordingWatched(id: id)) }
    func toggleRecordingFavorite(id: String) async throws { try await requestVoid(.toggleRecordingFavorite(id: id)) }
    func toggleRecordingKeep(id: String) async throws { try await requestVoid(.toggleRecordingKeep(id: id)) }
    func trashRecording(id: String) async throws { try await requestVoid(.trashRecording(id: id)) }
    func recordingStreamURL(id: String) -> URL? { buildURL(for: .getRecordingStream(id: id)) }
    func recordingHLSURL(id: String) -> URL? { buildURL(for: .getRecordingHLS(id: id)) }

    // MARK: - DVR Series Rules
    func getSeriesRules() async throws -> SeriesRulesResponse { try await request(.getSeriesRules) }
    func createSeriesRule(title: String, channelId: String? = nil, prePadding: Int? = nil, postPadding: Int? = nil, keepCount: Int? = nil) async throws -> SeriesRuleDTO {
        try await request(.createSeriesRule(title: title, channelId: channelId, prePadding: prePadding, postPadding: postPadding, keepCount: keepCount))
    }
    func updateSeriesRule(id: String, enabled: Bool? = nil, prePadding: Int? = nil, postPadding: Int? = nil, keepCount: Int? = nil) async throws {
        try await requestVoid(.updateSeriesRule(id: id, enabled: enabled, prePadding: prePadding, postPadding: postPadding, keepCount: keepCount))
    }
    func deleteSeriesRule(id: String) async throws { try await requestVoid(.deleteSeriesRule(id: id)) }
    func pauseDVRPass(id: String) async throws { try await requestVoid(.pauseDVRPass(id: id)) }
    func resumeDVRPass(id: String) async throws { try await requestVoid(.resumeDVRPass(id: id)) }

    // MARK: - DVR Conflicts
    func getConflicts() async throws -> ConflictsResponse { try await request(.getConflicts) }

    // MARK: - DVR Commercials
    func getCommercials(recordingId: String) async throws -> [CommercialDTO] { try await request(.getCommercials(recordingId: recordingId)) }
    func detectCommercials(recordingId: String) async throws { try await requestVoid(.detectCommercials(recordingId: recordingId)) }
    func getCommercialStatus() async throws -> CommercialStatusResponse { try await request(.getCommercialStatus) }

    // MARK: - DVR Settings
    func getDiskUsage() async throws -> DiskUsageResponse { try await request(.getDiskUsage) }
    func getQualityPresets() async throws -> QualityPresetsResponse { try await request(.getQualityPresets) }
    func getDVRSettings() async throws -> DVRSettingsResponse { try await request(.getDVRSettings) }
    func updateDVRSettings(settings: [String: Any]) async throws { try await requestVoid(.updateDVRSettings(settings: settings)) }
    func getDVRPasses() async throws -> DVRPassesResponse { try await request(.getDVRPasses) }
    func getDVRSchedule() async throws -> DVRScheduleResponse { try await request(.getDVRSchedule) }
    func getDVRCalendar() async throws -> DVRCalendarResponse { try await request(.getDVRCalendar) }
    func getDVRLabels() async throws -> DVRLabelsResponse { try await request(.getDVRLabels) }

    // MARK: - DVR V2 Jobs
    func getV2Jobs() async throws -> V2JobsResponse { try await request(.getV2Jobs) }
    func getV2Job(id: String) async throws -> V2JobDTO { try await request(.getV2Job(id: id)) }
    func deleteV2Job(id: String) async throws { try await requestVoid(.deleteV2Job(id: id)) }
    func cancelV2Job(id: String) async throws { try await requestVoid(.cancelV2Job(id: id)) }

    // MARK: - DVR V2 Files
    func getV2Files() async throws -> V2FilesResponse { try await request(.getV2Files) }
    func getV2File(id: String) async throws -> V2FileDTO { try await request(.getV2File(id: id)) }
    func deleteV2File(id: String) async throws { try await requestVoid(.deleteV2File(id: id)) }
    func v2FileStreamURL(id: String) -> URL? { buildURL(for: .streamV2File(id: id)) }
    func lockV2File(id: String) async throws { try await requestVoid(.lockV2File(id: id)) }
    func unlockV2File(id: String) async throws { try await requestVoid(.unlockV2File(id: id)) }
    func stripAds(fileId: String) async throws { try await requestVoid(.stripAds(fileId: fileId)) }

    // MARK: - DVR V2 Groups
    func getV2Groups() async throws -> V2GroupsResponse { try await request(.getV2Groups) }
    func getV2Group(id: String) async throws -> V2GroupDTO { try await request(.getV2Group(id: id)) }
    func getV2UpNext() async throws -> V2UpNextResponse { try await request(.getV2UpNext) }

    // MARK: - DVR V2 Rules
    func getV2Rules() async throws -> V2RulesResponse { try await request(.getV2Rules) }
    func deleteV2Rule(id: String) async throws { try await requestVoid(.deleteV2Rule(id: id)) }

    // MARK: - DVR V2 Collections & Virtual Stations
    func getV2Collections() async throws -> V2CollectionsResponse { try await request(.getV2Collections) }
    func getVirtualStations() async throws -> VirtualStationsResponse { try await request(.getVirtualStations) }
    func virtualStationStreamURL(id: String) -> URL? { buildURL(for: .streamVirtualStation(id: id)) }
    func getChannelCollections() async throws -> ChannelCollectionsResponse { try await request(.getChannelCollections) }

    // MARK: - DVR V2 Trash
    func getV2Trash() async throws -> V2TrashResponse { try await request(.getV2Trash) }
    func restoreFromTrash(id: String) async throws { try await requestVoid(.restoreFromTrash(id: id)) }
    func emptyTrash() async throws { try await requestVoid(.emptyTrash) }

    // MARK: - DVR V2 Chapters
    func getChapters(fileId: String) async throws -> V2ChaptersResponse { try await request(.getChapters(fileId: fileId)) }
    func detectChapters(fileId: String) async throws { try await requestVoid(.detectChapters(fileId: fileId)) }

    // MARK: - Playback Decision
    func getPlaybackDecision(fileId: String) async throws -> PlaybackDecisionResponse { try await request(.getPlaybackDecision(fileId: fileId)) }
    func getPlaybackOptions(mediaId: String) async throws -> PlaybackOptionsResponse { try await request(.getPlaybackOptions(mediaId: mediaId)) }
    func getSkipMarkers(id: String) async throws -> SkipMarkersResponse { try await request(.getSkipMarkers(id: id)) }
    func getSkipSettings() async throws -> SkipSettingsResponse { try await request(.getSkipSettings) }
    func getMediaTracks(id: String) async throws -> MediaTracksResponse { try await request(.getMediaTracks(id: id)) }
    func getTrackPreferences() async throws -> TrackPreferencesResponse { try await request(.getTrackPreferences) }
    func getSpeedPresets() async throws -> SpeedPresetsResponse { try await request(.getSpeedPresets) }

    // MARK: - Remote Access
    func getConnectionInfo() async throws -> ConnectionInfoResponse { try await request(.getConnectionInfo) }
    func getRemoteAccessStatus() async throws -> RemoteAccessStatusResponse { try await request(.getRemoteAccessStatus) }
    func enableRemoteAccess() async throws { try await requestVoid(.enableRemoteAccess) }
    func disableRemoteAccess() async throws { try await requestVoid(.disableRemoteAccess) }
    func getRemoteAccessHealth() async throws -> RemoteAccessHealthResponse { try await request(.getRemoteAccessHealth) }

    // MARK: - Notifications
    func getNotificationConfig() async throws -> NotificationConfigResponse { try await request(.getNotificationConfig) }
    func testNotification(type: String, destination: String) async throws { try await requestVoid(.testNotification(type: type, destination: destination)) }
    func getNotificationHistory() async throws -> NotificationHistoryResponse { try await request(.getNotificationHistory) }

    // MARK: - DDNS
    func getDDNSStatus() async throws -> DDNSStatusResponse { try await request(.getDDNSStatus) }
    func configureDDNS(provider: String, hostname: String, username: String? = nil, password: String? = nil) async throws {
        try await requestVoid(.configureDDNS(provider: provider, hostname: hostname, username: username, password: password))
    }
    func disableDDNS() async throws { try await requestVoid(.disableDDNS) }

    // MARK: - Speed Test
    func pingSpeedTest() async throws -> SpeedTestPingResponse { try await request(.pingSpeedTest) }
    func downloadSpeedTest() async throws -> SpeedTestDownloadResponse { try await request(.downloadSpeedTest) }

    // MARK: - Stream Health
    func getHealthStreams() async throws -> HealthStreamsResponse { try await request(.getHealthStreams) }
    func getHealthAlerts() async throws -> HealthAlertsResponse { try await request(.getHealthAlerts) }
    func getHealthSummary() async throws -> HealthSummaryResponse { try await request(.getHealthSummary) }

    // MARK: - Tuners
    func getTuners() async throws -> TunersResponse { try await request(.getTuners) }
    func addTuner(url: String, name: String) async throws { try await requestVoid(.addTuner(url: url, name: name)) }
    func discoverTuners() async throws -> TunerDiscoveryResponse { try await request(.discoverTuners) }
    func removeTuner(id: String) async throws { try await requestVoid(.removeTuner(id: id)) }
    func getTunerLineup(id: String) async throws -> TunerLineupResponse { try await request(.getTunerLineup(id: id)) }

    // MARK: - Bookmarks & Clips
    func getBookmarks() async throws -> BookmarksResponse { try await request(.getBookmarks) }
    func createBookmark(mediaId: String, time: Double, title: String? = nil, description: String? = nil) async throws -> BookmarkDTO {
        try await request(.createBookmark(mediaId: mediaId, time: time, title: title, description: description))
    }
    func deleteBookmark(id: String) async throws { try await requestVoid(.deleteBookmark(id: id)) }
    func getClips() async throws -> ClipsResponse { try await request(.getClips) }
    func createClip(mediaId: String, startTime: Double, endTime: Double, title: String? = nil) async throws -> ClipDTO {
        try await request(.createClip(mediaId: mediaId, startTime: startTime, endTime: endTime, title: title))
    }
    func deleteClip(id: String) async throws { try await requestVoid(.deleteClip(id: id)) }
    func clipDownloadURL(id: String) -> URL? { buildURL(for: .downloadClip(id: id)) }
    func clipStreamURL(id: String) -> URL? { buildURL(for: .streamClip(id: id)) }

    // MARK: - Offline Downloads
    func requestOfflineDownload(mediaId: String, quality: String? = nil) async throws -> OfflineDownloadDTO {
        try await request(.requestOfflineDownload(mediaId: mediaId, quality: quality))
    }
    func getOfflineDownloads() async throws -> OfflineDownloadsResponse { try await request(.getOfflineDownloads) }
    func deleteOfflineDownload(id: String) async throws { try await requestVoid(.deleteOfflineDownload(id: id)) }
    func getOfflineSettings() async throws -> OfflineSettingsResponse { try await request(.getOfflineSettings) }

    // MARK: - Subtitles
    func searchSubtitles(query: String? = nil, lang: String? = nil, mediaId: String? = nil) async throws -> SubtitleSearchResponse {
        try await request(.searchSubtitles(query: query, lang: lang, mediaId: mediaId))
    }
    func getSubtitleConfig() async throws -> SubtitleConfigResponse { try await request(.getSubtitleConfig) }
    func getSubtitlesForMedia(mediaId: String) async throws -> MediaSubtitlesResponse { try await request(.getSubtitlesForMedia(mediaId: mediaId)) }

    // MARK: - VOD
    func getVODProviders() async throws -> VODProvidersResponse { try await request(.getVODProviders) }
    func getVODMovies(provider: String) async throws -> VODMoviesResponse { try await request(.getVODMovies(provider: provider)) }
    func getVODShows(provider: String) async throws -> VODShowsResponse { try await request(.getVODShows(provider: provider)) }
    func getVODQueue() async throws -> VODQueueResponse { try await request(.getVODQueue) }

    // MARK: - Admin
    func getAdminLibraries() async throws -> AdminLibrariesResponse { try await request(.getAdminLibraries) }
    func createAdminLibrary(name: String, type: String, paths: [String]) async throws -> AdminLibraryDTO {
        try await request(.createAdminLibrary(name: name, type: type, paths: paths))
    }
    func deleteAdminLibrary(id: String) async throws { try await requestVoid(.deleteAdminLibrary(id: id)) }
    func scanLibrary(libraryId: String) async throws { try await requestVoid(.scanLibrary(libraryId: libraryId)) }
    func getAdminSettings() async throws -> AdminSettingsResponse { try await request(.getAdminSettings) }
    func updateAdminSettings(settings: [String: Any]) async throws { try await requestVoid(.updateAdminSettings(settings: settings)) }
    func createBackup() async throws -> BackupDTO { try await request(.createBackup) }
    func listBackups() async throws -> BackupsResponse { try await request(.listBackups) }
    func restoreBackup(filename: String) async throws { try await requestVoid(.restoreBackup(filename: filename)) }
    func getUpdaterStatus() async throws -> UpdaterStatusResponse { try await request(.getUpdaterStatus) }
    func checkForUpdates() async throws -> UpdaterStatusResponse { try await request(.checkForUpdates) }
    func applyUpdate() async throws { try await requestVoid(.applyUpdate) }
    func getScheduledTasks() async throws -> ScheduledTasksResponse { try await request(.getScheduledTasks) }
    func triggerScheduledTask(id: String) async throws { try await requestVoid(.triggerScheduledTask(id: id)) }
    func browseFilesystem(path: String) async throws -> FilesystemBrowseResponse { try await request(.browseFilesystem(path: path)) }

    // MARK: - Server & Device
    func getServerInfo() async throws -> ServerInfoDTO { try await request(.getServerInfo) }
    func getCapabilities() async throws -> ServerCapabilitiesDTO { try await request(.getCapabilities) }
    func getIdentity() async throws -> ServerInfoDTO { try await request(.getIdentity) }
    func getServerStatus() async throws -> ServerStatusResponse { try await request(.getServerStatus) }
    func getDashboard() async throws -> DashboardResponse { try await request(.getDashboard) }
    func getClientSettings() async throws -> ServerSettingsResponse { try await request(.getClientSettings) }
    func getServerSettings() async throws -> ServerSettingsResponse { try await request(.getClientSettings) }
    func registerDevice(deviceId: String, platform: String, appVersion: String, deviceModel: String, osVersion: String) async throws {
        try await requestVoid(.registerDevice(deviceId: deviceId, platform: platform, appVersion: appVersion, deviceModel: deviceModel, osVersion: osVersion))
    }
    func getMyDeviceSettings() async throws -> DeviceSettingsResponse { try await request(.getMyDeviceSettings) }

    /// Checks if this device is registered with the server; if not, registers it.
    func ensureDeviceRegistered() async {
        do {
            // Try to fetch device settings - returns 404 if not registered
            let _: DeviceSettingsResponse = try await request(.getMyDeviceSettings)
        } catch {
            // Not registered (404 or any error) - register now
            #if canImport(UIKit)
            let model = await UIDevice.current.model
            let os = await UIDevice.current.systemName + " " + UIDevice.current.systemVersion
            #else
            let model = "Unknown"
            let os = "Unknown"
            #endif
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            try? await registerDevice(deviceId: deviceId, platform: "ios", appVersion: version, deviceModel: model, osVersion: os)
        }
    }

    // MARK: - Logs
    func submitClientLogs(entries: [[String: Any]]) async throws { try await requestVoid(.submitClientLogs(entries: entries)) }
    func getClientLogs() async throws -> [ClientLogEntry] { try await request(.getClientLogs) }
    func clearClientLogs() async throws { try await requestVoid(.clearClientLogs) }

    // MARK: - Health
    func healthCheck() async throws -> HealthCheckResponse { try await request(.getHealthCheck) }
    func getSystemStatus() async throws -> SystemStatusResponse { try await request(.getSystemStatus) }

    // MARK: - Instant Switch (Prebuffer)
    func instantSwitchStatus() async throws -> InstantSwitchStatusResponse { try await request(.instantSwitchStatus) }
    func instantSwitchChannel(channelId: String) async throws -> InstantSwitchResponse { try await request(.instantSwitchChannel(channelId: channelId)) }
    func instantSwitchPredictions(channelId: String? = nil, count: Int? = nil) async throws -> InstantSwitchPredictionsResponse {
        try await request(.instantSwitchPredictions(channelId: channelId, count: count))
    }
    func instantSwitchCached() async throws -> InstantSwitchCachedResponse { try await request(.instantSwitchCached) }
    func instantSwitchStreamURL(channelId: String) -> URL? { buildURL(for: .instantSwitchStream(channelId: channelId)) }

    // MARK: - Live Now
    func getLiveTVOnNow() async throws -> LiveTVOnNowResponse { try await request(.getLiveTVOnNow) }

    // MARK: - Stream URL Builders
    func mediaFileStreamURL(partId: String) -> URL? { buildURL(for: .streamMediaFile(partId: partId)) }
    func hlsTranscodeURL(path: String, session: String? = nil) -> URL? { buildURL(for: .startHLSTranscode(path: path, session: session)) }
    func offlineStreamURL(id: String) -> URL? { buildURL(for: .streamOfflineContent(id: id)) }
}
