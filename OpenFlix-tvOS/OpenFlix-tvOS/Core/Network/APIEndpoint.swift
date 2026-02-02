import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum APIEndpoint {
    // MARK: - Authentication
    case login(username: String, password: String)
    case register(name: String, email: String, password: String)
    case logout
    case getUser
    case updateUser(name: String?, email: String?)
    case changePassword(currentPassword: String, newPassword: String)

    // MARK: - Profiles
    case getProfiles
    case getHomeUsers
    case switchProfile(uuid: String, pin: String?)
    case createProfile(name: String, isKid: Bool, pin: String?)
    case updateProfile(id: Int, name: String?, isKid: Bool?, pin: String?)
    case deleteProfile(id: Int)

    // MARK: - Library Sections
    case getLibrarySections
    case getLibraryItems(sectionId: Int, start: Int?, size: Int?, sort: String?, filters: [String: String]?)
    case getLibraryFilters(sectionId: Int)
    case getLibrarySorts(sectionId: Int)
    case getLibraryCollections(sectionId: Int)

    // MARK: - Media
    case getMediaDetails(key: Int)
    case getMediaChildren(key: Int)
    case getRecentlyAdded
    case getOnDeck

    // MARK: - Hubs
    case getHubs(sectionId: Int)
    case getStreamingServices(sectionId: Int?)
    case getTrending
    case getPopularMovies
    case getPopularTV
    case getTopRatedMovies

    // MARK: - Search
    case search(query: String, limit: Int?)

    // MARK: - Playback
    case getPlaybackURL(path: String, directPlay: Bool)
    case updateProgress(key: Int, time: Int, state: String?)
    case scrobble(key: Int)
    case unscrobble(key: Int)
    case timeline(ratingKey: Int, state: String, time: Int, duration: Int)

    // MARK: - Sessions
    case getSessions
    case startSession(mediaId: Int)
    case updateSession(id: String, state: String, position: Int)
    case stopSession(id: String)

    // MARK: - Live TV Channels
    case getChannels
    case getChannel(id: String)
    case updateChannel(id: String, name: String?, number: Int?, enabled: Bool?, group: String?)
    case toggleFavorite(channelId: String)
    case getChannelStream(id: String)

    // MARK: - EPG / Guide
    case getGuide(start: Date?, end: Date?)
    case getChannelGuide(channelId: String, start: Date?, end: Date?)
    case getNowPlaying

    // MARK: - Live TV Sources
    case getM3USources
    case addM3USource(name: String, url: String, epgUrl: String?)
    case updateM3USource(id: Int, name: String?, url: String?, epgUrl: String?, enabled: Bool?)
    case deleteM3USource(id: Int)
    case refreshM3USource(id: Int)
    case importVOD(sourceId: Int, libraryId: Int?)
    case importSeries(sourceId: Int, libraryId: Int?)

    // MARK: - Xtream Sources
    case getXtreamSources
    case getXtreamSource(id: Int)
    case addXtreamSource(name: String, serverUrl: String, username: String, password: String)
    case updateXtreamSource(id: Int, name: String?, enabled: Bool?, importLive: Bool?, importVod: Bool?, importSeries: Bool?)
    case deleteXtreamSource(id: Int)
    case testXtreamSource(id: Int)
    case refreshXtreamSource(id: Int)

    // MARK: - EPG Sources
    case getEPGSources
    case previewEPGSource(url: String, type: String)
    case addEPGSource(name: String, url: String, type: String)
    case updateEPGSource(id: Int, name: String?, url: String?, enabled: Bool?)
    case deleteEPGSource(id: Int)
    case refreshEPGSource(id: Int)

    // MARK: - Channel Groups
    case getChannelGroups
    case createChannelGroup(name: String, channelIds: [String])
    case updateChannelGroup(id: Int, name: String?, enabled: Bool?)
    case deleteChannelGroup(id: Int)
    case addChannelToGroup(groupId: Int, channelId: String, priority: Int)
    case removeChannelFromGroup(groupId: Int, channelId: String)
    case autoDetectDuplicates
    case getChannelGroupStream(id: Int)

    // MARK: - DVR Recordings
    case getRecordings(status: String?)
    case getRecording(id: Int)
    case scheduleRecording(channelId: String, startTime: Date, endTime: Date, title: String)
    case recordFromProgram(channelId: String, programId: String)
    case deleteRecording(id: Int)
    case updateRecordingPriority(id: Int, priority: Int)
    case getRecordingStats
    case getRecordingStream(id: Int)
    case updateRecordingProgress(id: Int, time: Int)

    // MARK: - DVR Series Rules
    case getSeriesRules
    case createSeriesRule(title: String, channelId: String?, prePadding: Int, postPadding: Int, keepCount: Int)
    case updateSeriesRule(id: Int, enabled: Bool?, prePadding: Int?, postPadding: Int?, keepCount: Int?)
    case deleteSeriesRule(id: Int)

    // MARK: - DVR Conflicts
    case getConflicts
    case checkConflict(recordingId: Int)
    case resolveConflict(conflictId: Int, keepRecordingIds: [Int])

    // MARK: - Commercial Detection
    case getCommercials(recordingId: Int)
    case detectCommercials(recordingId: Int)
    case reprocessRecording(recordingId: Int)

    // MARK: - Catch-up / Time-shift / Archive
    case getCatchupPrograms(channelId: String)
    case getStartover(channelId: String)
    case getTimeshiftStream(channelId: String)
    case startTimeshift(channelId: String)
    case stopTimeshift(channelId: String)
    case getArchive(channelId: String)
    case enableArchive(channelId: String, days: Int)
    case disableArchive(channelId: String)
    case getArchiveStatus
    case getArchiveStream(archiveId: Int)

    // MARK: - On Later
    case getOnLaterStats
    case getOnLaterMovies
    case getOnLaterSports(league: String?, team: String?)
    case getOnLaterKids
    case getOnLaterNews
    case getOnLaterPremieres
    case getOnLaterTonight
    case getOnLaterWeek
    case searchOnLater(query: String)

    // MARK: - Team Pass
    case getTeamPasses
    case getTeamPass(id: Int)
    case createTeamPass(teamName: String, league: String, channelIds: [String]?, prePadding: Int, postPadding: Int)
    case updateTeamPass(id: Int, teamName: String?, channelIds: [String]?, prePadding: Int?, postPadding: Int?, enabled: Bool?)
    case deleteTeamPass(id: Int)
    case getTeamPassUpcoming(id: Int)
    case toggleTeamPass(id: Int)
    case getTeamPassStats
    case searchTeams(query: String)
    case getLeagues
    case getTeamsInLeague(league: String)

    // MARK: - Playlists
    case getPlaylists
    case createPlaylist(name: String)
    case getPlaylist(id: Int)
    case getPlaylistItems(id: Int)
    case addToPlaylist(id: Int, mediaIds: [Int])
    case removeFromPlaylist(id: Int, itemId: Int)
    case movePlaylistItem(id: Int, itemId: Int, newIndex: Int)
    case clearPlaylist(id: Int)
    case deletePlaylist(id: Int)

    // MARK: - Watchlist
    case getWatchlist
    case addToWatchlist(mediaId: Int)
    case removeFromWatchlist(mediaId: Int)

    // MARK: - Collections
    case getCollections(sectionId: Int)
    case getCollectionItems(id: Int)
    case createCollection(sectionId: Int, name: String)
    case addToCollection(id: Int, mediaIds: [Int])
    case removeFromCollection(id: Int, itemId: Int)
    case deleteCollection(id: Int)

    // MARK: - Server
    case getServerInfo
    case getCapabilities
    case getIdentity

    // MARK: - Client Logs
    case submitLogs(entries: [[String: Any]])
    case getLogs
    case clearLogs

    // MARK: - Path & Method
    var path: String {
        switch self {
        // Auth
        case .login: return "/auth/login"
        case .register: return "/auth/register"
        case .logout: return "/auth/logout"
        case .getUser: return "/auth/user"
        case .updateUser: return "/auth/user"
        case .changePassword: return "/auth/user/password"

        // Profiles
        case .getProfiles: return "/profiles"
        case .getHomeUsers: return "/api/v2/home/users"
        case .switchProfile(let uuid, _): return "/api/v2/home/users/\(uuid)/switch"
        case .createProfile: return "/profiles"
        case .updateProfile(let id, _, _, _): return "/profiles/\(id)"
        case .deleteProfile(let id): return "/profiles/\(id)"

        // Library
        case .getLibrarySections: return "/library/sections"
        case .getLibraryItems(let sectionId, _, _, _, _): return "/library/sections/\(sectionId)/all"
        case .getLibraryFilters(let sectionId): return "/library/sections/\(sectionId)/filters"
        case .getLibrarySorts(let sectionId): return "/library/sections/\(sectionId)/sorts"
        case .getLibraryCollections(let sectionId): return "/library/sections/\(sectionId)/collections"

        // Media
        case .getMediaDetails(let key): return "/library/metadata/\(key)"
        case .getMediaChildren(let key): return "/library/metadata/\(key)/children"
        case .getRecentlyAdded: return "/library/recentlyAdded"
        case .getOnDeck: return "/library/onDeck"

        // Hubs
        case .getHubs(let sectionId): return "/hubs/sections/\(sectionId)"
        case .getStreamingServices(let sectionId):
            if let id = sectionId { return "/hubs/sections/\(id)/streaming-services" }
            return "/hubs/home/streaming-services"
        case .getTrending: return "/hubs/trending"
        case .getPopularMovies: return "/hubs/popular/movies"
        case .getPopularTV: return "/hubs/popular/tv"
        case .getTopRatedMovies: return "/hubs/top-rated/movies"

        // Search
        case .search: return "/hubs/search"

        // Playback
        case .getPlaybackURL: return "/video/:/transcode/universal/start"
        case .updateProgress: return "/:/progress"
        case .scrobble(let key): return "/scrobble?key=\(key)"
        case .unscrobble(let key): return "/unscrobble?key=\(key)"
        case .timeline: return "/timeline"

        // Sessions
        case .getSessions: return "/status/sessions"
        case .startSession: return "/sessions"
        case .updateSession(let id, _, _): return "/sessions/\(id)"
        case .stopSession(let id): return "/sessions/\(id)"

        // Live TV Channels
        case .getChannels: return "/livetv/channels"
        case .getChannel(let id): return "/livetv/channels/\(id)"
        case .updateChannel(let id, _, _, _, _): return "/livetv/channels/\(id)"
        case .toggleFavorite(let channelId): return "/livetv/channels/\(channelId)/favorite"
        case .getChannelStream(let id): return "/livetv/channels/\(id)/stream"

        // EPG
        case .getGuide: return "/livetv/guide"
        case .getChannelGuide(let channelId, _, _): return "/livetv/guide/\(channelId)"
        case .getNowPlaying: return "/livetv/now"

        // M3U Sources
        case .getM3USources: return "/livetv/sources"
        case .addM3USource: return "/livetv/sources"
        case .updateM3USource(let id, _, _, _, _): return "/livetv/sources/\(id)"
        case .deleteM3USource(let id): return "/livetv/sources/\(id)"
        case .refreshM3USource(let id): return "/livetv/sources/\(id)/refresh"
        case .importVOD(let sourceId, _): return "/livetv/sources/\(sourceId)/import-vod"
        case .importSeries(let sourceId, _): return "/livetv/sources/\(sourceId)/import-series"

        // Xtream Sources
        case .getXtreamSources: return "/livetv/xtream/sources"
        case .getXtreamSource(let id): return "/livetv/xtream/sources/\(id)"
        case .addXtreamSource: return "/livetv/xtream/sources"
        case .updateXtreamSource(let id, _, _, _, _, _): return "/livetv/xtream/sources/\(id)"
        case .deleteXtreamSource(let id): return "/livetv/xtream/sources/\(id)"
        case .testXtreamSource(let id): return "/livetv/xtream/sources/\(id)/test"
        case .refreshXtreamSource(let id): return "/livetv/xtream/sources/\(id)/refresh"

        // EPG Sources
        case .getEPGSources: return "/livetv/epg/sources"
        case .previewEPGSource: return "/livetv/epg/sources/preview"
        case .addEPGSource: return "/livetv/epg/sources"
        case .updateEPGSource(let id, _, _, _): return "/livetv/epg/sources/\(id)"
        case .deleteEPGSource(let id): return "/livetv/epg/sources/\(id)"
        case .refreshEPGSource(let id): return "/livetv/epg/sources/\(id)/refresh"

        // Channel Groups
        case .getChannelGroups: return "/livetv/channel-groups"
        case .createChannelGroup: return "/livetv/channel-groups"
        case .updateChannelGroup(let id, _, _): return "/livetv/channel-groups/\(id)"
        case .deleteChannelGroup(let id): return "/livetv/channel-groups/\(id)"
        case .addChannelToGroup(let groupId, _, _): return "/livetv/channel-groups/\(groupId)/members"
        case .removeChannelFromGroup(let groupId, let channelId): return "/livetv/channel-groups/\(groupId)/members/\(channelId)"
        case .autoDetectDuplicates: return "/livetv/channel-groups/auto-detect"
        case .getChannelGroupStream(let id): return "/livetv/channel-groups/\(id)/stream"

        // DVR Recordings
        case .getRecordings: return "/dvr/recordings"
        case .getRecording(let id): return "/dvr/recordings/\(id)"
        case .scheduleRecording: return "/dvr/recordings"
        case .recordFromProgram: return "/dvr/recordings/from-program"
        case .deleteRecording(let id): return "/dvr/recordings/\(id)"
        case .updateRecordingPriority(let id, _): return "/dvr/recordings/\(id)/priority"
        case .getRecordingStats: return "/dvr/recordings/stats"
        case .getRecordingStream(let id): return "/dvr/recordings/\(id)/stream"
        case .updateRecordingProgress(let id, _): return "/dvr/recordings/\(id)/progress"

        // Series Rules
        case .getSeriesRules: return "/dvr/rules"
        case .createSeriesRule: return "/dvr/rules"
        case .updateSeriesRule(let id, _, _, _, _): return "/dvr/rules/\(id)"
        case .deleteSeriesRule(let id): return "/dvr/rules/\(id)"

        // Conflicts
        case .getConflicts: return "/dvr/conflicts"
        case .checkConflict(let id): return "/dvr/conflicts/check"
        case .resolveConflict: return "/dvr/conflicts/resolve"

        // Commercials
        case .getCommercials(let id): return "/dvr/recordings/\(id)/commercials"
        case .detectCommercials(let id): return "/dvr/recordings/\(id)/commercials/detect"
        case .reprocessRecording(let id): return "/dvr/recordings/\(id)/reprocess"

        // Catch-up / Archive
        case .getCatchupPrograms(let id): return "/livetv/channels/\(id)/catchup"
        case .getStartover(let id): return "/livetv/channels/\(id)/startover"
        case .getTimeshiftStream(let id): return "/livetv/timeshift/\(id)/stream.m3u8"
        case .startTimeshift(let id): return "/livetv/timeshift/\(id)/start"
        case .stopTimeshift(let id): return "/livetv/timeshift/\(id)/stop"
        case .getArchive(let id): return "/livetv/channels/\(id)/archive"
        case .enableArchive(let id, _): return "/livetv/channels/\(id)/archive/enable"
        case .disableArchive(let id): return "/livetv/channels/\(id)/archive/disable"
        case .getArchiveStatus: return "/livetv/archive/status"
        case .getArchiveStream(let id): return "/livetv/archive/\(id)/stream.m3u8"

        // On Later
        case .getOnLaterStats: return "/api/onlater/stats"
        case .getOnLaterMovies: return "/api/onlater/movies"
        case .getOnLaterSports: return "/api/onlater/sports"
        case .getOnLaterKids: return "/api/onlater/kids"
        case .getOnLaterNews: return "/api/onlater/news"
        case .getOnLaterPremieres: return "/api/onlater/premieres"
        case .getOnLaterTonight: return "/api/onlater/tonight"
        case .getOnLaterWeek: return "/api/onlater/week"
        case .searchOnLater: return "/api/onlater/search"

        // Team Pass
        case .getTeamPasses: return "/api/teampass"
        case .getTeamPass(let id): return "/api/teampass/\(id)"
        case .createTeamPass: return "/api/teampass"
        case .updateTeamPass(let id, _, _, _, _, _): return "/api/teampass/\(id)"
        case .deleteTeamPass(let id): return "/api/teampass/\(id)"
        case .getTeamPassUpcoming(let id): return "/api/teampass/\(id)/upcoming"
        case .toggleTeamPass(let id): return "/api/teampass/\(id)/toggle"
        case .getTeamPassStats: return "/api/teampass/stats"
        case .searchTeams: return "/api/teampass/teams/search"
        case .getLeagues: return "/api/teampass/leagues"
        case .getTeamsInLeague(let league): return "/api/teampass/leagues/\(league)/teams"

        // Playlists
        case .getPlaylists: return "/playlists"
        case .createPlaylist: return "/playlists"
        case .getPlaylist(let id): return "/playlists/\(id)"
        case .getPlaylistItems(let id): return "/playlists/\(id)/items"
        case .addToPlaylist(let id, _): return "/playlists/\(id)/items"
        case .removeFromPlaylist(let id, let itemId): return "/playlists/\(id)/items/\(itemId)"
        case .movePlaylistItem(let id, let itemId, _): return "/playlists/\(id)/items/\(itemId)/move"
        case .clearPlaylist(let id): return "/playlists/\(id)/items"
        case .deletePlaylist(let id): return "/playlists/\(id)"

        // Watchlist
        case .getWatchlist: return "/watchlist"
        case .addToWatchlist(let mediaId): return "/watchlist/\(mediaId)"
        case .removeFromWatchlist(let mediaId): return "/watchlist/\(mediaId)"

        // Collections
        case .getCollections(let sectionId): return "/library/sections/\(sectionId)/collections"
        case .getCollectionItems(let id): return "/library/collections/\(id)/children"
        case .createCollection: return "/library/collections"
        case .addToCollection(let id, _): return "/library/collections/\(id)/items"
        case .removeFromCollection(let id, let itemId): return "/library/collections/\(id)/items/\(itemId)"
        case .deleteCollection(let id): return "/library/collections/\(id)"

        // Server
        case .getServerInfo: return "/server/info"
        case .getCapabilities: return "/server/capabilities"
        case .getIdentity: return "/identity"

        // Client Logs
        case .submitLogs: return "/api/client-logs"
        case .getLogs: return "/api/client-logs"
        case .clearLogs: return "/api/client-logs"
        }
    }

    var method: HTTPMethod {
        switch self {
        // POST
        case .login, .register, .logout,
             .switchProfile,
             .createProfile,
             .startSession,
             .toggleFavorite,
             .addM3USource, .refreshM3USource, .importVOD, .importSeries,
             .addXtreamSource, .testXtreamSource, .refreshXtreamSource,
             .previewEPGSource, .addEPGSource, .refreshEPGSource,
             .createChannelGroup, .addChannelToGroup, .autoDetectDuplicates,
             .scheduleRecording, .recordFromProgram,
             .createSeriesRule,
             .checkConflict, .resolveConflict,
             .detectCommercials, .reprocessRecording,
             .startTimeshift, .stopTimeshift,
             .enableArchive, .disableArchive,
             .createTeamPass, .toggleTeamPass,
             .createPlaylist, .addToPlaylist,
             .addToWatchlist,
             .createCollection, .addToCollection,
             .timeline,
             .submitLogs:
            return .post

        // PUT
        case .updateUser, .changePassword,
             .updateProfile,
             .updateChannel,
             .updateM3USource,
             .updateXtreamSource,
             .updateEPGSource,
             .updateChannelGroup,
             .updateRecordingPriority, .updateRecordingProgress,
             .updateSeriesRule,
             .updateTeamPass,
             .movePlaylistItem,
             .updateSession,
             .updateProgress:
            return .put

        // DELETE
        case .deleteProfile,
             .deleteM3USource,
             .deleteXtreamSource,
             .deleteEPGSource,
             .deleteChannelGroup, .removeChannelFromGroup,
             .deleteRecording,
             .deleteSeriesRule,
             .deleteTeamPass,
             .removeFromPlaylist, .clearPlaylist, .deletePlaylist,
             .removeFromWatchlist,
             .removeFromCollection, .deleteCollection,
             .stopSession,
             .clearLogs:
            return .delete

        // GET (default)
        default:
            return .get
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .getLibraryItems(_, let start, let size, let sort, let filters):
            var items: [URLQueryItem] = []
            if let start = start { items.append(URLQueryItem(name: "X-Plex-Container-Start", value: "\(start)")) }
            if let size = size { items.append(URLQueryItem(name: "X-Plex-Container-Size", value: "\(size)")) }
            if let sort = sort { items.append(URLQueryItem(name: "sort", value: sort)) }
            if let filters = filters {
                for (key, value) in filters {
                    items.append(URLQueryItem(name: key, value: value))
                }
            }
            return items.isEmpty ? nil : items

        case .search(let query, let limit):
            var items = [URLQueryItem(name: "query", value: query)]
            if let limit = limit { items.append(URLQueryItem(name: "limit", value: "\(limit)")) }
            return items

        case .getPlaybackURL(let path, let directPlay):
            return [
                URLQueryItem(name: "path", value: path),
                URLQueryItem(name: "directPlay", value: directPlay ? "1" : "0"),
                URLQueryItem(name: "directStream", value: "1"),
                URLQueryItem(name: "protocol", value: "hls")
            ]

        case .getGuide(let start, let end):
            var items: [URLQueryItem] = []
            // Server expects Unix timestamps, not ISO 8601
            if let start = start { items.append(URLQueryItem(name: "start", value: "\(Int(start.timeIntervalSince1970))")) }
            if let end = end { items.append(URLQueryItem(name: "end", value: "\(Int(end.timeIntervalSince1970))")) }
            return items.isEmpty ? nil : items

        case .getChannelGuide(_, let start, let end):
            var items: [URLQueryItem] = []
            // Server expects Unix timestamps, not ISO 8601
            if let start = start { items.append(URLQueryItem(name: "start", value: "\(Int(start.timeIntervalSince1970))")) }
            if let end = end { items.append(URLQueryItem(name: "end", value: "\(Int(end.timeIntervalSince1970))")) }
            return items.isEmpty ? nil : items

        case .getRecordings(let status):
            if let status = status {
                return [URLQueryItem(name: "status", value: status)]
            }
            return nil

        case .enableArchive(_, let days):
            return [URLQueryItem(name: "days", value: "\(days)")]

        case .getOnLaterSports(let league, let team):
            var items: [URLQueryItem] = []
            if let league = league { items.append(URLQueryItem(name: "league", value: league)) }
            if let team = team { items.append(URLQueryItem(name: "team", value: team)) }
            return items.isEmpty ? nil : items

        case .searchOnLater(let query):
            return [URLQueryItem(name: "q", value: query)]

        case .searchTeams(let query):
            return [URLQueryItem(name: "q", value: query)]

        default:
            return nil
        }
    }

    var body: Data? {
        let encoder = JSONEncoder()

        switch self {
        case .login(let username, let password):
            return try? encoder.encode(["username": username, "password": password])

        case .register(let name, let email, let password):
            return try? encoder.encode(["name": name, "email": email, "password": password])

        case .switchProfile(_, let pin):
            if let pin = pin {
                return try? encoder.encode(["pin": pin])
            }
            return nil

        case .createProfile(let name, let isKid, let pin):
            var dict: [String: Any] = ["name": name, "isKid": isKid]
            if let pin = pin { dict["pin"] = pin }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .updateProfile(_, let name, let isKid, let pin):
            var dict: [String: Any] = [:]
            if let name = name { dict["name"] = name }
            if let isKid = isKid { dict["isKid"] = isKid }
            if let pin = pin { dict["pin"] = pin }
            return dict.isEmpty ? nil : try? JSONSerialization.data(withJSONObject: dict)

        case .updateUser(let name, let email):
            var dict: [String: String] = [:]
            if let name = name { dict["name"] = name }
            if let email = email { dict["email"] = email }
            return dict.isEmpty ? nil : try? encoder.encode(dict)

        case .changePassword(let currentPassword, let newPassword):
            return try? encoder.encode(["currentPassword": currentPassword, "newPassword": newPassword])

        case .updateChannel(_, let name, let number, let enabled, let group):
            var dict: [String: Any] = [:]
            if let name = name { dict["name"] = name }
            if let number = number { dict["number"] = number }
            if let enabled = enabled { dict["enabled"] = enabled }
            if let group = group { dict["group"] = group }
            return dict.isEmpty ? nil : try? JSONSerialization.data(withJSONObject: dict)

        case .addM3USource(let name, let url, let epgUrl):
            var dict: [String: String] = ["name": name, "url": url]
            if let epgUrl = epgUrl { dict["epgUrl"] = epgUrl }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .updateM3USource(_, let name, let url, let epgUrl, let enabled):
            var dict: [String: Any] = [:]
            if let name = name { dict["name"] = name }
            if let url = url { dict["url"] = url }
            if let epgUrl = epgUrl { dict["epgUrl"] = epgUrl }
            if let enabled = enabled { dict["enabled"] = enabled }
            return dict.isEmpty ? nil : try? JSONSerialization.data(withJSONObject: dict)

        case .addXtreamSource(let name, let serverUrl, let username, let password):
            return try? JSONSerialization.data(withJSONObject: [
                "name": name,
                "serverUrl": serverUrl,
                "username": username,
                "password": password
            ])

        case .updateXtreamSource(_, let name, let enabled, let importLive, let importVod, let importSeries):
            var dict: [String: Any] = [:]
            if let name = name { dict["name"] = name }
            if let enabled = enabled { dict["enabled"] = enabled }
            if let importLive = importLive { dict["importLive"] = importLive }
            if let importVod = importVod { dict["importVod"] = importVod }
            if let importSeries = importSeries { dict["importSeries"] = importSeries }
            return dict.isEmpty ? nil : try? JSONSerialization.data(withJSONObject: dict)

        case .addEPGSource(let name, let url, let type):
            return try? JSONSerialization.data(withJSONObject: ["name": name, "url": url, "type": type])

        case .createChannelGroup(let name, let channelIds):
            return try? JSONSerialization.data(withJSONObject: ["name": name, "channelIds": channelIds])

        case .addChannelToGroup(_, let channelId, let priority):
            return try? JSONSerialization.data(withJSONObject: ["channelId": channelId, "priority": priority])

        case .scheduleRecording(let channelId, let startTime, let endTime, let title):
            let formatter = ISO8601DateFormatter()
            return try? JSONSerialization.data(withJSONObject: [
                "channelId": channelId,
                "startTime": formatter.string(from: startTime),
                "endTime": formatter.string(from: endTime),
                "title": title
            ])

        case .recordFromProgram(let channelId, let programId):
            return try? JSONSerialization.data(withJSONObject: ["channelId": channelId, "programId": programId])

        case .updateRecordingPriority(_, let priority):
            return try? JSONSerialization.data(withJSONObject: ["priority": priority])

        case .updateRecordingProgress(_, let time):
            return try? JSONSerialization.data(withJSONObject: ["time": time])

        case .createSeriesRule(let title, let channelId, let prePadding, let postPadding, let keepCount):
            var dict: [String: Any] = [
                "title": title,
                "prePadding": prePadding,
                "postPadding": postPadding,
                "keepCount": keepCount
            ]
            if let channelId = channelId { dict["channelId"] = channelId }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .resolveConflict(let conflictId, let keepRecordingIds):
            return try? JSONSerialization.data(withJSONObject: [
                "conflictId": conflictId,
                "keepRecordingIds": keepRecordingIds
            ])

        case .createTeamPass(let teamName, let league, let channelIds, let prePadding, let postPadding):
            var dict: [String: Any] = [
                "teamName": teamName,
                "league": league,
                "prePadding": prePadding,
                "postPadding": postPadding
            ]
            if let channelIds = channelIds { dict["channelIds"] = channelIds }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .createPlaylist(let name):
            return try? encoder.encode(["name": name])

        case .addToPlaylist(_, let mediaIds):
            return try? JSONSerialization.data(withJSONObject: ["mediaIds": mediaIds])

        case .movePlaylistItem(_, _, let newIndex):
            return try? JSONSerialization.data(withJSONObject: ["newIndex": newIndex])

        case .createCollection(let sectionId, let name):
            return try? JSONSerialization.data(withJSONObject: ["sectionId": sectionId, "name": name])

        case .addToCollection(_, let mediaIds):
            return try? JSONSerialization.data(withJSONObject: ["mediaIds": mediaIds])

        case .startSession(let mediaId):
            return try? JSONSerialization.data(withJSONObject: ["mediaId": mediaId])

        case .updateSession(_, let state, let position):
            return try? JSONSerialization.data(withJSONObject: ["state": state, "position": position])

        case .updateProgress(let key, let time, let state):
            var dict: [String: Any] = ["key": key, "time": time]
            if let state = state { dict["state"] = state }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .timeline(let ratingKey, let state, let time, let duration):
            return try? JSONSerialization.data(withJSONObject: [
                "ratingKey": ratingKey,
                "state": state,
                "time": time,
                "duration": duration
            ])

        case .submitLogs(let entries):
            return try? JSONSerialization.data(withJSONObject: ["entries": entries])

        case .importVOD(_, let libraryId):
            if let libraryId = libraryId {
                return try? JSONSerialization.data(withJSONObject: ["libraryId": libraryId])
            }
            return nil

        case .importSeries(_, let libraryId):
            if let libraryId = libraryId {
                return try? JSONSerialization.data(withJSONObject: ["libraryId": libraryId])
            }
            return nil

        default:
            return nil
        }
    }
}
