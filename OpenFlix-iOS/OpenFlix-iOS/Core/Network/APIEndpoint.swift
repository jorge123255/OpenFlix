import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}

enum APIEndpoint {
    // MARK: - Auth
    case login(username: String, password: String)
    case register(name: String, email: String, password: String)
    case logout
    case getUser
    case updateUser(name: String?, email: String?)
    case changePassword(currentPassword: String, newPassword: String)

    // MARK: - Plex-Compat Auth
    case getPlexUser
    case getResources
    case getHomeUsers
    case switchProfile(uuid: String, pin: String?)

    // MARK: - Profiles
    case getProfiles
    case createProfile(name: String, isKid: Bool, pin: String?)
    case getProfile(id: String)
    case updateProfile(id: String, name: String?, isKid: Bool?, pin: String?)
    case deleteProfile(id: String)

    // MARK: - Parental Controls
    case setParentalPin(pin: String)
    case verifyParentalPin(pin: String)
    case getParentalSettings
    case updateParentalSettings(enabled: Bool, rating: String?, pin: String?)

    // MARK: - Server Status
    case getServerStatus
    case getDashboard
    case getHealthCheck
    case getSystemStatus
    case getTranscodeInfo

    // MARK: - Search
    case search(query: String, limit: Int?)

    // MARK: - Client Settings
    case getClientSettings
    case getGlobalClientSettings
    case updateGlobalClientSettings(settings: [String: Any])
    case deleteGlobalClientSetting(key: String)

    // MARK: - Logs
    case getServerLogs
    case clearServerLogs
    case submitClientLogs(entries: [[String: Any]])
    case getClientLogs
    case clearClientLogs

    // MARK: - Library
    case getLibrarySections
    case getLibraryItems(sectionId: String, start: Int?, size: Int?, sort: String?, filters: [String: String]?)
    case getLibraryFilters(sectionId: String)
    case getLibrarySorts(sectionId: String)
    case getLibraryCollections(sectionId: String)
    case getLibraryFolder(sectionId: String)
    case refreshLibrarySection(sectionId: String)
    case getSectionRecentlyAdded(sectionId: String)
    case getSectionNewest(sectionId: String)

    // MARK: - Media
    case getMediaDetails(key: String)
    case getMediaChildren(key: String)
    case getRecentlyAdded
    case getOnDeck
    case setMetadataPrefs(key: String, prefs: [String: Any])

    // MARK: - Images
    case getThumb(key: String, thumbId: String)
    case getSimpleThumb(key: String)
    case getArt(key: String, artId: String)
    case getSimpleArt(key: String)

    // MARK: - Stream Selection
    case selectStreams(partId: String, audioStreamId: Int?, subtitleStreamId: Int?)

    // MARK: - Hubs
    case getHubs(sectionId: String)
    case getStreamingServices(sectionId: String?)
    case getAllStreamingServices
    case searchHubs(query: String)
    case getTrending
    case getPopularMovies
    case getPopularTV
    case getTopRatedMovies

    // MARK: - Playback & Watch State
    case getPlaybackURL(path: String, directPlay: Bool)
    case updateProgress(key: String, time: Int, state: String)
    case scrobble(key: String)
    case unscrobble(key: String)
    case timeline(ratingKey: String, state: String, time: Int, duration: Int)
    case removeFromContinueWatching(ratingKey: String)
    case getServerPrefs

    // MARK: - Sessions
    case getSessions
    case startSession(mediaId: String)
    case updateSession(id: String, state: String?, position: Int?)
    case stopSession(id: String)

    // MARK: - Playlists (Plex-style)
    case getPlaylists
    case createPlaylist(name: String)
    case getPlaylist(id: String)
    case getPlaylistItems(id: String)
    case addToPlaylist(id: String, mediaIds: [String])
    case removeFromPlaylist(id: String, itemId: String)
    case movePlaylistItem(id: String, itemId: String, newIndex: Int)
    case clearPlaylist(id: String)
    case deletePlaylist(id: String)

    // MARK: - Playlists (Admin API)
    case getAdminPlaylists
    case createAdminPlaylist(title: String, description: String?)
    case getAdminPlaylist(id: String)
    case updateAdminPlaylist(id: String, title: String?, description: String?)
    case deleteAdminPlaylist(id: String)
    case addAdminPlaylistItems(id: String, itemIds: [String])
    case removeAdminPlaylistItem(id: String, itemId: String)
    case reorderAdminPlaylistItems(id: String, itemIds: [String])

    // MARK: - Personal Sections
    case getPersonalSections
    case createPersonalSection(title: String, type: String, smart: Bool?, filter: String?)
    case previewSmartFilter(filter: String)
    case getAvailableGenres
    case getPersonalSection(id: String)
    case updatePersonalSection(id: String, title: String?, filter: String?)
    case deletePersonalSection(id: String)
    case addToPersonalSection(id: String, itemIds: [String])
    case removeFromPersonalSection(id: String, itemId: String)
    case reorderPersonalSection(id: String, itemIds: [String])

    // MARK: - Watchlist
    case getWatchlist
    case addToWatchlist(mediaId: String)
    case removeFromWatchlist(mediaId: String)

    // MARK: - Collections
    case getCollections(sectionId: String)
    case getCollectionItems(id: String)
    case createCollection(sectionId: String, name: String)
    case addToCollection(id: String, mediaIds: [String])
    case removeFromCollection(id: String, itemId: String)
    case deleteCollection(id: String)

    // MARK: - Live TV Channels
    case getChannels
    case getChannel(id: String)
    case updateChannel(id: String, name: String?, number: String?, enabled: Bool?, group: String?, logo: String?)
    case bulkMapChannels(mappings: [[String: Any]])
    case autoDetectEPGMappings
    case mapChannelNumbers(sourceId: String)
    case removeEPGMapping(channelId: String)
    case getEPGSuggestions(channelId: String)
    case toggleFavorite(channelId: String)
    case refreshChannelEPG(channelId: String)
    case getChannelStream(id: String)

    // MARK: - Channel Groups
    case getChannelGroups
    case createChannelGroup(name: String, channelIds: [String])
    case updateChannelGroup(id: String, name: String?, enabled: Bool?)
    case deleteChannelGroup(id: String)
    case addChannelToGroup(groupId: String, channelId: String, priority: Int)
    case updateGroupMemberPriority(groupId: String, channelId: String, priority: Int)
    case removeChannelFromGroup(groupId: String, channelId: String)
    case autoDetectDuplicates
    case getChannelGroupStream(id: String)

    // MARK: - Guide
    case getGuide(start: String?, end: String?)
    case getChannelGuide(channelId: String, start: String?, end: String?)
    case getNowPlaying

    // MARK: - M3U Sources
    case getM3USources
    case addM3USource(name: String, url: String, epgUrl: String?)
    case updateM3USource(id: String, name: String?, url: String?, epgUrl: String?, enabled: Bool?)
    case deleteM3USource(id: String)
    case refreshM3USource(id: String)
    case importVOD(sourceId: String, libraryId: String)
    case importSeries(sourceId: String, libraryId: String)

    // MARK: - Xtream Sources
    case getXtreamSources
    case getXtreamSource(id: String)
    case addXtreamSource(name: String, serverUrl: String, username: String, password: String)
    case updateXtreamSource(id: String, name: String?, enabled: Bool?, importLive: Bool?, importVod: Bool?, importSeries: Bool?)
    case deleteXtreamSource(id: String)
    case testXtreamSource(id: String)
    case refreshXtreamSource(id: String)
    case parseXtreamFromM3U(url: String)
    case getXtreamCategories(sourceId: String)
    case getXtreamStreams(sourceId: String)
    case importXtreamVOD(sourceId: String)
    case importXtreamSeries(sourceId: String)
    case importAllXtream(sourceId: String)
    case proxyXtreamM3U8(url: String)

    // MARK: - EPG Sources
    case getEPGSources
    case previewEPGSource(url: String, type: String)
    case addEPGSource(name: String, url: String?, type: String, tvguideProviderId: String?, tvguideZipCode: String?, tvguideDays: Int?)
    case updateEPGSource(id: String, name: String?, url: String?, enabled: Bool?)
    case deleteEPGSource(id: String)
    case refreshEPGSource(id: String)
    case discoverTVGuideProviders(zip: String)

    // MARK: - EPG Management
    case getEPGStats
    case refreshAllEPG
    case getEPGPrograms(channelId: String?, date: String?)
    case getEPGChannels
    case getEPGSchedulerStatus
    case forceEPGRefresh
    case getGuideCacheStats
    case invalidateGuideCache
    case getEPGConflicts
    case resolveEPGDuplicates
    case resolveEPGOverlaps
    case cleanupEPG
    case cleanupLiveTVDatabase
    case getEPGSourceHealth
    case fetchEPGWithFallback(sourceId: String)
    case resetEPGSourceHealth(id: String)
    case discoverGracenoteProviders(zip: String)

    // MARK: - Catch-up / Timeshift / Archive
    case getCatchupPrograms(channelId: String)
    case getStartover(channelId: String)
    case getTimeshiftStream(channelId: String)
    case startTimeshift(channelId: String)
    case stopTimeshift(channelId: String)
    case getArchive(channelId: String)
    case enableArchive(channelId: String, days: Int)
    case disableArchive(channelId: String)
    case getArchiveStatus
    case getArchiveStream(archiveId: String)

    // MARK: - Live TV Exports
    case exportM3U
    case exportXMLTV
    case exportLineupJSON

    // MARK: - On Later
    case getOnLaterAll
    case getOnLaterTVShows
    case getOnLaterMovies
    case getOnLaterSports(league: String?, team: String?)
    case getOnLaterKids
    case getOnLaterNews
    case getOnLaterPremieres
    case getOnLaterTonight
    case getOnLaterWeek
    case searchOnLater(query: String)
    case getOnLaterByChannel(channelId: String)
    case getOnLaterStats
    case getOnLaterHoliday
    case getOnLaterHalloween
    case getOnLaterSeasonal(event: String?)
    case enrichEPG(programIds: [String])
    case getOnLaterLeagues
    case getOnLaterTeams(league: String)
    case searchOnLaterTeams(query: String)

    // MARK: - Team Pass
    case getTeamPasses
    case createTeamPass(teamName: String, league: String, channelIds: [String]?, prePadding: Int?, postPadding: Int?)
    case getTeamPass(id: String)
    case updateTeamPass(id: String, teamName: String?, channelIds: [String]?, prePadding: Int?, postPadding: Int?, enabled: Bool?)
    case deleteTeamPass(id: String)
    case getTeamPassUpcoming(id: String)
    case toggleTeamPass(id: String)
    case getTeamPassStats
    case processTeamPasses
    case searchTeams(query: String)
    case getLeagues
    case getTeamsInLeague(league: String)

    // MARK: - DVR Recordings
    case getRecordings(status: String?)
    case scheduleRecording(channelId: String, startTime: String, endTime: String, title: String)
    case recordFromProgram(channelId: String, programId: String)
    case getRecordingStats
    case getRecordingsManager
    case bulkRecordingAction(action: String, recordingIds: [String])
    case getRecording(id: String)
    case updateRecording(id: String, updates: [String: Any])
    case matchRecording(id: String, tmdbId: String, type: String)
    case deleteRecording(id: String)
    case stopRecording(id: String)
    case updateRecordingPriority(id: String, priority: Int)

    // MARK: - DVR Commercials
    case getCommercials(recordingId: String)
    case detectCommercials(recordingId: String)
    case reprocessRecording(recordingId: String)
    case exportEDL(recordingId: String)
    case getCommercialStatus

    // MARK: - DVR Playback
    case getRecordingStream(id: String)
    case streamRecordingDirect(id: String)
    case getRecordingHLS(id: String)
    case getRecordingDASH(id: String)
    case updateRecordingProgress(id: String, time: Int)
    case toggleRecordingWatched(id: String)
    case toggleRecordingFavorite(id: String)
    case toggleRecordingKeep(id: String)
    case trashRecording(id: String)
    case validateStream(url: String)

    // MARK: - DVR Series Rules
    case getSeriesRules
    case createSeriesRule(title: String, channelId: String?, prePadding: Int?, postPadding: Int?, keepCount: Int?)
    case updateSeriesRule(id: String, enabled: Bool?, prePadding: Int?, postPadding: Int?, keepCount: Int?)
    case deleteSeriesRule(id: String)

    // MARK: - DVR Conflicts
    case getConflicts
    case checkConflict(recordingId: String)
    case resolveConflict(conflictId: String, keepRecordingIds: [String])

    // MARK: - DVR Settings & Management
    case getDiskUsage
    case getQualityPresets
    case getDVRSettings
    case updateDVRSettings(settings: [String: Any])
    case getDVRPasses
    case pauseDVRPass(id: String)
    case resumeDVRPass(id: String)
    case getDVRSchedule
    case getDVRCalendar
    case getDVRLabels
    case bulkLabelAction(action: String, labels: [String], recordingIds: [String])
    case getFilesByLabel(label: String)
    case setRecordingLabels(id: String, labels: [String])

    // MARK: - DVR V2 Jobs
    case getV2Jobs
    case getV2Job(id: String)
    case createV2Job(params: [String: Any])
    case updateV2Job(id: String, params: [String: Any])
    case deleteV2Job(id: String)
    case cancelV2Job(id: String)

    // MARK: - DVR V2 Files
    case getV2Files
    case getV2LockedFiles
    case getV2File(id: String)
    case updateV2File(id: String, params: [String: Any])
    case deleteV2File(id: String)
    case streamV2File(id: String)
    case getV2FileDASH(id: String)
    case updateV2FileState(id: String, watched: Bool?, position: Int?, favorited: Bool?)
    case setV2FileLabels(id: String, labels: [String])
    case lockV2File(id: String)
    case unlockV2File(id: String)
    case exportV2FileEDL(id: String)
    case stripAds(fileId: String)
    case getStripAdsStatus(fileId: String)
    case undoStripAds(fileId: String)
    case regroupV2File(id: String)

    // MARK: - DVR V2 File Upload
    case uploadV2File
    case importV2File(path: String)
    case bulkImportV2Files(paths: [String])
    case getUploadProgress(id: String)

    // MARK: - DVR V2 Groups
    case getV2Groups
    case getV2Group(id: String)
    case deleteV2Group(id: String)
    case updateV2GroupState(id: String, params: [String: Any])
    case regroupV2Files

    // MARK: - DVR V2 Rules
    case getV2Rules
    case getV2Rule(id: String)
    case createV2Rule(params: [String: Any])
    case updateV2Rule(id: String, params: [String: Any])
    case deleteV2Rule(id: String)
    case previewV2Rule(query: [String: Any])
    case previewExistingV2Rule(id: String)

    // MARK: - DVR V2 Duplicates
    case getV2Duplicates
    case checkV2Duplicate(title: String, startTime: String)
    case getV2DuplicateStats
    case overrideV2Duplicate(jobId: String)

    // MARK: - DVR V2 Up Next
    case getV2UpNext

    // MARK: - DVR V2 Virtual Stations
    case getVirtualStations
    case getVirtualStation(id: String)
    case createVirtualStation(params: [String: Any])
    case updateVirtualStation(id: String, params: [String: Any])
    case deleteVirtualStation(id: String)
    case streamVirtualStation(id: String)

    // MARK: - DVR V2 Collections
    case getV2Collections
    case getV2Collection(id: String)
    case createV2Collection(params: [String: Any])
    case updateV2Collection(id: String, params: [String: Any])
    case deleteV2Collection(id: String)
    case getV2CollectionItems(id: String)

    // MARK: - DVR V2 Trash
    case getV2Trash
    case restoreFromTrash(id: String)
    case emptyTrash
    case permanentlyDelete(id: String)

    // MARK: - DVR V2 Channel Collections
    case getChannelCollections
    case createChannelCollection(params: [String: Any])
    case previewChannelCollectionRules(rules: [String: Any])
    case getChannelCollectionGroups
    case getChannelCollectionSources
    case getChannelCollection(id: String)
    case updateChannelCollection(id: String, params: [String: Any])
    case deleteChannelCollection(id: String)
    case exportChannelCollectionM3U(id: String)

    // MARK: - DVR V2 Conflicts
    case getV2Conflicts
    case getV2ConflictAlternatives(jobId: String)
    case resolveV2Conflict(jobId: String, params: [String: Any])
    case autoResolveV2Conflicts

    // MARK: - DVR V2 Chapters
    case getChapters(fileId: String)
    case addChapter(fileId: String, title: String, startTime: Double, endTime: Double, type: String?)
    case updateChapter(fileId: String, chapterId: String, params: [String: Any])
    case deleteChapter(fileId: String, chapterId: String)
    case detectChapters(fileId: String)

    // MARK: - Media Streaming
    case streamMediaFile(partId: String)
    case startHLSTranscode(path: String, session: String?)
    case startDASHTranscode(path: String, session: String?)

    // MARK: - Playback Decision API
    case registerClientCapabilities(deviceId: String, capabilities: [String: Any])
    case getClientCapabilities(deviceId: String)
    case getDefaultCapabilities
    case getPlaybackDecision(fileId: String)
    case postPlaybackDecision(fileId: String, capabilities: [String: Any])
    case getPlaybackOptions(mediaId: String)
    case reportBandwidth(clientId: String, downloadSpeed: Int64, uploadSpeed: Int64)
    case getServerBandwidth
    case setServerBandwidthLimit(limit: Int64)
    case getClientBandwidth(clientId: String)
    case setClientBandwidthCap(clientId: String, cap: Int64)
    case getSkipMarkers(id: String)
    case getLibrarySkipMarkers(id: String)
    case reportSkip(id: String, type: String, timestamp: Double)
    case getSkipSettings
    case updateSkipSettings(settings: [String: Any])
    case getMediaTracks(id: String)
    case selectTracks(id: String, audioId: Int?, subtitleId: Int?)
    case getTrackPreferences
    case updateTrackPreferences(prefs: [String: Any])
    case getSpeedPresets
    case setPlaybackSpeed(speed: Double)
    case getSessionSpeed(sessionId: String)
    case setSessionSpeed(sessionId: String, speed: Double)
    case getFrameRate(id: String)
    case getFrameRateSettings
    case updateFrameRateSettings(settings: [String: Any])

    // MARK: - VOD
    case getVODProviders
    case getVODMovies(provider: String)
    case getVODShows(provider: String)
    case getVODGenres(provider: String)
    case getVODMovieDetails(provider: String, id: String)
    case getVODShowDetails(provider: String, id: String)
    case startVODDownload(provider: String, mediaId: String, quality: String?)
    case getVODQueue
    case cancelVODDownload(id: String)
    case testVODConnection

    // MARK: - Remote Access
    case getConnectionInfo
    case getRemoteAccessStatus
    case enableRemoteAccess
    case disableRemoteAccess
    case getRemoteAccessHealth
    case getRemoteAccessInstallInfo
    case getRemoteAccessLoginURL

    // MARK: - Notifications
    case getNotificationConfig
    case updateNotificationConfig(config: [String: Any])
    case testNotification(type: String, destination: String)
    case getNotificationHistory

    // MARK: - DDNS
    case getDDNSStatus
    case configureDDNS(provider: String, hostname: String, username: String?, password: String?)
    case testDDNS
    case forceUpdateDDNS
    case disableDDNS

    // MARK: - Speed Test
    case pingSpeedTest
    case downloadSpeedTest
    case uploadSpeedTest
    case getSpeedTestResults(id: String)

    // MARK: - Stream Health
    case getHealthStreams
    case getStreamHealth(id: String)
    case reportStreamHealth(id: String, quality: Double?, buffering: Double?, errors: Int?)
    case getHealthChannels
    case getChannelHealthHistory(id: String)
    case getHealthAlerts
    case getHealthSummary

    // MARK: - Tuners / HDHR
    case getTuners
    case addTuner(url: String, name: String)
    case discoverTuners
    case removeTuner(id: String)
    case getTunerLineup(id: String)
    case getTunerStatus(id: String)
    case importTunerChannels(id: String)
    case scanTunerChannels(id: String)

    // MARK: - Bookmarks & Clips
    case getBookmarks
    case createBookmark(mediaId: String, time: Double, title: String?, description: String?)
    case getBookmark(id: String)
    case updateBookmark(id: String, title: String?, description: String?)
    case deleteBookmark(id: String)
    case getClips
    case createClip(mediaId: String, startTime: Double, endTime: Double, title: String?)
    case getClip(id: String)
    case deleteClip(id: String)
    case downloadClip(id: String)
    case streamClip(id: String)

    // MARK: - Offline Downloads
    case requestOfflineDownload(mediaId: String, quality: String?)
    case getOfflineDownloads
    case streamOfflineContent(id: String)
    case updateOfflineProgress(id: String, time: Int)
    case syncOfflineWatchState(id: String, watched: Bool, position: Int?)
    case deleteOfflineDownload(id: String)
    case getOfflineSettings
    case updateOfflineSettings(settings: [String: Any])

    // MARK: - Subtitles
    case searchSubtitles(query: String?, lang: String?, mediaId: String?)
    case downloadSubtitle(subtitleId: String, mediaId: String, lang: String)
    case getSubtitleConfig
    case updateSubtitleConfig(config: [String: Any])
    case getSubtitlesForMedia(mediaId: String)
    case deleteSubtitle(mediaId: String, lang: String)

    // MARK: - Scheduled Tasks
    case getScheduledTasks
    case getScheduledTask(id: String)
    case updateScheduledTask(id: String, enabled: Bool?, schedule: String?)
    case triggerScheduledTask(id: String)
    case getSchedulerHistory

    // MARK: - Admin Libraries
    case getAdminLibraries
    case createAdminLibrary(name: String, type: String, paths: [String])
    case getAdminLibrary(id: String)
    case updateAdminLibrary(id: String, name: String?, scanInterval: Int?)
    case deleteAdminLibrary(id: String)
    case addLibraryPath(libraryId: String, path: String)
    case removeLibraryPath(libraryId: String, pathId: String)
    case scanLibrary(libraryId: String)
    case getLibraryStats(libraryId: String)
    case browseFilesystem(path: String)

    // MARK: - Admin Settings
    case getAdminSettings
    case updateAdminSettings(settings: [String: Any])

    // MARK: - Admin Backups
    case createBackup
    case listBackups
    case downloadBackup(filename: String)
    case deleteBackup(filename: String)
    case restoreBackup(filename: String)

    // MARK: - Admin Search
    case reindexSearch
    case getSearchStats

    // MARK: - Admin Updater
    case getUpdaterStatus
    case checkForUpdates
    case applyUpdate

    // MARK: - Admin Media
    case getAdminMedia(query: String?, type: String?)
    case updateAdminMedia(id: String, params: [String: Any])
    case refreshMediaMetadata(id: String)
    case refreshMissingMetadata
    case searchTMDB(query: String, type: String?)
    case applyMediaMatch(id: String, tmdbId: String, type: String)

    // MARK: - Auto-Update Config
    case getAutoUpdateConfig
    case setAutoUpdateConfig(enabled: Bool, schedule: String?)
    case getUpdateSchedule
    case checkForUpdatesNow

    // MARK: - Config Export/Import
    case exportConfig
    case importConfig
    case getConfigStats

    // MARK: - Device Management
    case registerDevice(deviceId: String, platform: String, appVersion: String, deviceModel: String, osVersion: String)
    case getMyDeviceSettings
    case listDevices
    case getDevice(id: String)
    case updateDevice(id: String, params: [String: Any])
    case deleteDevice(id: String)

    // MARK: - Guide Data
    case refreshGuideData
    case rebuildGuideData

    // MARK: - Server Identity
    case getServerRoot
    case getIdentity
    case getServerInfo
    case getCapabilities
    case healthCheckSimple

    // MARK: - Instant Switch (Prebuffer)
    case instantSwitchStatus
    case instantSwitchSetEnabled(enabled: Bool)
    case instantSwitchChannel(channelId: String)
    case instantSwitchFavorites
    case instantSwitchSetFavorites(channelIds: [String])
    case instantSwitchPredictions(channelId: String?, count: Int?)
    case instantSwitchCached
    case instantSwitchStream(channelId: String)

    // MARK: - Family Sharing / Invites
    case createInvite
    case getClaimToken
    case generateClaimToken

    // MARK: - Downloads
    case getAppDownloads
    case downloadApp(filename: String)

    // MARK: - Path
    var path: String {
        switch self {
        // Auth
        case .login: return "/auth/login"
        case .register: return "/auth/register"
        case .logout: return "/auth/logout"
        case .getUser: return "/auth/user"
        case .updateUser: return "/auth/user"
        case .changePassword: return "/auth/password"
        case .getPlexUser: return "/api/v2/user"
        case .getResources: return "/api/v2/resources"
        case .getHomeUsers: return "/api/v2/home/users"
        case .switchProfile(let uuid, _): return "/api/v2/home/users/\(uuid)/switch"
        // Profiles
        case .getProfiles: return "/profiles"
        case .createProfile: return "/profiles"
        case .getProfile(let id): return "/profiles/\(id)"
        case .updateProfile(let id, _, _, _): return "/profiles/\(id)"
        case .deleteProfile(let id): return "/profiles/\(id)"
        // Parental
        case .setParentalPin: return "/api/parental/pin"
        case .verifyParentalPin: return "/api/parental/verify"
        case .getParentalSettings: return "/api/parental/settings"
        case .updateParentalSettings: return "/api/parental/settings"
        // Server Status
        case .getServerStatus: return "/api/status"
        case .getDashboard: return "/api/dashboard"
        case .getHealthCheck: return "/api/diagnostics/health-check"
        case .getSystemStatus: return "/api/system/status"
        case .getTranscodeInfo: return "/api/transcode"
        // Search
        case .search: return "/api/search"
        // Client Settings
        case .getClientSettings: return "/api/client/settings"
        case .getGlobalClientSettings: return "/api/client-settings"
        case .updateGlobalClientSettings: return "/api/client-settings"
        case .deleteGlobalClientSetting(let key): return "/api/client-settings/\(key)"
        // Logs
        case .getServerLogs: return "/api/logs"
        case .clearServerLogs: return "/api/logs"
        case .submitClientLogs: return "/api/client-logs"
        case .getClientLogs: return "/api/client-logs"
        case .clearClientLogs: return "/api/client-logs"
        // Library
        case .getLibrarySections: return "/library/sections"
        case .getLibraryItems(let id, _, _, _, _): return "/library/sections/\(id)/all"
        case .getLibraryFilters(let id): return "/library/sections/\(id)/filters"
        case .getLibrarySorts(let id): return "/library/sections/\(id)/sorts"
        case .getLibraryCollections(let id): return "/library/sections/\(id)/collections"
        case .getLibraryFolder(let id): return "/library/sections/\(id)/folder"
        case .refreshLibrarySection(let id): return "/library/sections/\(id)/refresh"
        case .getSectionRecentlyAdded(let id): return "/library/sections/\(id)/recentlyAdded"
        case .getSectionNewest(let id): return "/library/sections/\(id)/newest"
        // Media
        case .getMediaDetails(let key): return "/library/metadata/\(key)"
        case .getMediaChildren(let key): return "/library/metadata/\(key)/children"
        case .getRecentlyAdded: return "/library/recentlyAdded"
        case .getOnDeck: return "/library/onDeck"
        case .setMetadataPrefs(let key, _): return "/library/metadata/\(key)/prefs"
        // Images
        case .getThumb(let key, let thumbId): return "/library/metadata/\(key)/thumb/\(thumbId)"
        case .getSimpleThumb(let key): return "/library/metadata/\(key)/thumb"
        case .getArt(let key, let artId): return "/library/metadata/\(key)/art/\(artId)"
        case .getSimpleArt(let key): return "/library/metadata/\(key)/art"
        // Stream Selection
        case .selectStreams(let partId, _, _): return "/library/parts/\(partId)"
        // Hubs
        case .getHubs(let id): return "/hubs/sections/\(id)"
        case .getStreamingServices(let id): return id != nil ? "/hubs/sections/\(id!)/streaming-services" : "/hubs/home/streaming-services"
        case .getAllStreamingServices: return "/hubs/home/streaming-services"
        case .searchHubs: return "/hubs/search"
        case .getTrending: return "/hubs/trending"
        case .getPopularMovies: return "/hubs/popular/movies"
        case .getPopularTV: return "/hubs/popular/tv"
        case .getTopRatedMovies: return "/hubs/top-rated/movies"
        // Playback
        case .getPlaybackURL: return "/video/:/transcode/universal/start"
        case .updateProgress: return "/:/progress"
        case .scrobble: return "/scrobble"
        case .unscrobble: return "/unscrobble"
        case .timeline: return "/timeline"
        case .removeFromContinueWatching: return "/actions/removeFromContinueWatching"
        case .getServerPrefs: return "/-/prefs"
        // Sessions
        case .getSessions: return "/status/sessions"
        case .startSession: return "/sessions"
        case .updateSession(let id, _, _): return "/sessions/\(id)"
        case .stopSession(let id): return "/sessions/\(id)"
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
        // Admin Playlists
        case .getAdminPlaylists: return "/api/playlists"
        case .createAdminPlaylist: return "/api/playlists"
        case .getAdminPlaylist(let id): return "/api/playlists/\(id)"
        case .updateAdminPlaylist(let id, _, _): return "/api/playlists/\(id)"
        case .deleteAdminPlaylist(let id): return "/api/playlists/\(id)"
        case .addAdminPlaylistItems(let id, _): return "/api/playlists/\(id)/items"
        case .removeAdminPlaylistItem(let id, let itemId): return "/api/playlists/\(id)/items/\(itemId)"
        case .reorderAdminPlaylistItems(let id, _): return "/api/playlists/\(id)/items/reorder"
        // Personal Sections
        case .getPersonalSections: return "/api/sections"
        case .createPersonalSection: return "/api/sections"
        case .previewSmartFilter: return "/api/sections/preview"
        case .getAvailableGenres: return "/api/sections/genres"
        case .getPersonalSection(let id): return "/api/sections/\(id)"
        case .updatePersonalSection(let id, _, _): return "/api/sections/\(id)"
        case .deletePersonalSection(let id): return "/api/sections/\(id)"
        case .addToPersonalSection(let id, _): return "/api/sections/\(id)/items"
        case .removeFromPersonalSection(let id, let itemId): return "/api/sections/\(id)/items/\(itemId)"
        case .reorderPersonalSection(let id, _): return "/api/sections/\(id)/reorder"
        // Watchlist
        case .getWatchlist: return "/watchlist"
        case .addToWatchlist(let id): return "/watchlist/\(id)"
        case .removeFromWatchlist(let id): return "/watchlist/\(id)"
        // Collections
        case .getCollections(let id): return "/library/sections/\(id)/collections"
        case .getCollectionItems(let id): return "/library/collections/\(id)/children"
        case .createCollection: return "/library/collections"
        case .addToCollection(let id, _): return "/library/collections/\(id)/items"
        case .removeFromCollection(let id, let itemId): return "/library/collections/\(id)/items/\(itemId)"
        case .deleteCollection(let id): return "/library/collections/\(id)"
        // Live TV Channels
        case .getChannels: return "/livetv/channels"
        case .getChannel(let id): return "/livetv/channels/\(id)"
        case .updateChannel(let id, _, _, _, _, _): return "/livetv/channels/\(id)"
        case .bulkMapChannels: return "/livetv/channels/bulk-map"
        case .autoDetectEPGMappings: return "/livetv/channels/auto-detect"
        case .mapChannelNumbers: return "/livetv/channels/map-numbers-from-m3u"
        case .removeEPGMapping(let id): return "/livetv/channels/\(id)/epg-mapping"
        case .getEPGSuggestions(let id): return "/livetv/channels/\(id)/suggestions"
        case .toggleFavorite(let id): return "/livetv/channels/\(id)/favorite"
        case .refreshChannelEPG(let id): return "/livetv/channels/\(id)/refresh-epg"
        case .getChannelStream(let id): return "/livetv/channels/\(id)/stream"
        // Channel Groups
        case .getChannelGroups: return "/livetv/channel-groups"
        case .createChannelGroup: return "/livetv/channel-groups"
        case .updateChannelGroup(let id, _, _): return "/livetv/channel-groups/\(id)"
        case .deleteChannelGroup(let id): return "/livetv/channel-groups/\(id)"
        case .addChannelToGroup(let id, _, _): return "/livetv/channel-groups/\(id)/members"
        case .updateGroupMemberPriority(let id, let chId, _): return "/livetv/channel-groups/\(id)/members/\(chId)"
        case .removeChannelFromGroup(let id, let chId): return "/livetv/channel-groups/\(id)/members/\(chId)"
        case .autoDetectDuplicates: return "/livetv/channel-groups/auto-detect"
        case .getChannelGroupStream(let id): return "/livetv/channel-groups/\(id)/stream"
        // Guide
        case .getGuide: return "/livetv/guide"
        case .getChannelGuide(let id, _, _): return "/livetv/guide/\(id)"
        case .getNowPlaying: return "/livetv/now"
        // M3U Sources
        case .getM3USources: return "/livetv/sources"
        case .addM3USource: return "/livetv/sources"
        case .updateM3USource(let id, _, _, _, _): return "/livetv/sources/\(id)"
        case .deleteM3USource(let id): return "/livetv/sources/\(id)"
        case .refreshM3USource(let id): return "/livetv/sources/\(id)/refresh"
        case .importVOD(let id, _): return "/livetv/sources/\(id)/import-vod"
        case .importSeries(let id, _): return "/livetv/sources/\(id)/import-series"
        // Xtream Sources
        case .getXtreamSources: return "/livetv/xtream/sources"
        case .getXtreamSource(let id): return "/livetv/xtream/sources/\(id)"
        case .addXtreamSource: return "/livetv/xtream/sources"
        case .updateXtreamSource(let id, _, _, _, _, _): return "/livetv/xtream/sources/\(id)"
        case .deleteXtreamSource(let id): return "/livetv/xtream/sources/\(id)"
        case .testXtreamSource(let id): return "/livetv/xtream/sources/\(id)/test"
        case .refreshXtreamSource(let id): return "/livetv/xtream/sources/\(id)/refresh"
        case .parseXtreamFromM3U: return "/livetv/xtream/parse-m3u"
        case .getXtreamCategories(let id): return "/livetv/xtream/sources/\(id)/categories"
        case .getXtreamStreams(let id): return "/livetv/xtream/sources/\(id)/streams"
        case .importXtreamVOD(let id): return "/livetv/xtream/sources/\(id)/import-vod"
        case .importXtreamSeries(let id): return "/livetv/xtream/sources/\(id)/import-series"
        case .importAllXtream(let id): return "/livetv/xtream/sources/\(id)/import-all"
        case .proxyXtreamM3U8: return "/livetv/xtream/proxy"
        // EPG Sources
        case .getEPGSources: return "/livetv/epg/sources"
        case .previewEPGSource: return "/livetv/epg/sources/preview"
        case .addEPGSource: return "/livetv/epg/sources"
        case .updateEPGSource(let id, _, _, _): return "/livetv/epg/sources/\(id)"
        case .deleteEPGSource(let id): return "/livetv/epg/sources/\(id)"
        case .refreshEPGSource(let id): return "/livetv/epg/sources/\(id)/refresh"
        // EPG Management
        case .getEPGStats: return "/livetv/epg/stats"
        case .refreshAllEPG: return "/livetv/epg/refresh"
        case .getEPGPrograms: return "/livetv/epg/programs"
        case .getEPGChannels: return "/livetv/epg/channels"
        case .getEPGSchedulerStatus: return "/livetv/epg/scheduler"
        case .forceEPGRefresh: return "/livetv/epg/scheduler/refresh"
        case .getGuideCacheStats: return "/livetv/guide/cache/stats"
        case .invalidateGuideCache: return "/livetv/guide/cache/invalidate"
        case .getEPGConflicts: return "/livetv/epg/conflicts"
        case .resolveEPGDuplicates: return "/livetv/epg/duplicates/resolve"
        case .resolveEPGOverlaps: return "/livetv/epg/overlaps/resolve"
        case .cleanupEPG: return "/livetv/epg/cleanup"
        case .cleanupLiveTVDatabase: return "/livetv/cleanup-database"
        case .getEPGSourceHealth: return "/livetv/epg/sources/health"
        case .fetchEPGWithFallback: return "/livetv/epg/sources/fetch-fallback"
        case .resetEPGSourceHealth(let id): return "/livetv/epg/sources/\(id)/reset-health"
        case .discoverGracenoteProviders: return "/livetv/gracenote/providers"
        case .discoverTVGuideProviders: return "/livetv/epg/tvguide/providers"
        // Catchup / Timeshift / Archive
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
        // Exports
        case .exportM3U: return "/livetv/export.m3u"
        case .exportXMLTV: return "/livetv/export.xml"
        case .exportLineupJSON: return "/livetv/lineup.json"
        // On Later
        case .getOnLaterAll: return "/api/onlater/all"
        case .getOnLaterTVShows: return "/api/onlater/tvshows"
        case .getOnLaterMovies: return "/api/onlater/movies"
        case .getOnLaterSports: return "/api/onlater/sports"
        case .getOnLaterKids: return "/api/onlater/kids"
        case .getOnLaterNews: return "/api/onlater/news"
        case .getOnLaterPremieres: return "/api/onlater/premieres"
        case .getOnLaterTonight: return "/api/onlater/tonight"
        case .getOnLaterWeek: return "/api/onlater/week"
        case .searchOnLater: return "/api/onlater/search"
        case .getOnLaterByChannel(let id): return "/api/onlater/channels/\(id)"
        case .getOnLaterStats: return "/api/onlater/stats"
        case .getOnLaterHoliday: return "/api/onlater/holiday"
        case .getOnLaterHalloween: return "/api/onlater/halloween"
        case .getOnLaterSeasonal(let event):
            if let e = event { return "/api/onlater/seasonal?event=\(e)" }
            return "/api/onlater/seasonal"
        case .enrichEPG: return "/api/onlater/enrich"
        case .getOnLaterLeagues: return "/api/onlater/leagues"
        case .getOnLaterTeams(let league): return "/api/onlater/teams/\(league)"
        case .searchOnLaterTeams: return "/api/onlater/teams/search"
        // Team Pass
        case .getTeamPasses: return "/api/teampass"
        case .createTeamPass: return "/api/teampass"
        case .getTeamPass(let id): return "/api/teampass/\(id)"
        case .updateTeamPass(let id, _, _, _, _, _): return "/api/teampass/\(id)"
        case .deleteTeamPass(let id): return "/api/teampass/\(id)"
        case .getTeamPassUpcoming(let id): return "/api/teampass/\(id)/upcoming"
        case .toggleTeamPass(let id): return "/api/teampass/\(id)/toggle"
        case .getTeamPassStats: return "/api/teampass/stats"
        case .processTeamPasses: return "/api/teampass/process"
        case .searchTeams: return "/api/teampass/teams/search"
        case .getLeagues: return "/api/teampass/leagues"
        case .getTeamsInLeague(let league): return "/api/teampass/leagues/\(league)/teams"
        // DVR Recordings
        case .getRecordings: return "/dvr/recordings"
        case .scheduleRecording: return "/dvr/recordings"
        case .recordFromProgram: return "/dvr/recordings/from-program"
        case .getRecordingStats: return "/dvr/recordings/stats"
        case .getRecordingsManager: return "/dvr/recordings/manager"
        case .bulkRecordingAction: return "/dvr/recordings/bulk"
        case .getRecording(let id): return "/dvr/recordings/\(id)"
        case .updateRecording(let id, _): return "/dvr/recordings/\(id)"
        case .matchRecording(let id, _, _): return "/dvr/recordings/\(id)/match"
        case .deleteRecording(let id): return "/dvr/recordings/\(id)"
        case .stopRecording(let id): return "/dvr/recordings/\(id)/stop"
        case .updateRecordingPriority(let id, _): return "/dvr/recordings/\(id)/priority"
        // DVR Commercials
        case .getCommercials(let id): return "/dvr/recordings/\(id)/commercials"
        case .detectCommercials(let id): return "/dvr/recordings/\(id)/commercials/detect"
        case .reprocessRecording(let id): return "/dvr/recordings/\(id)/reprocess"
        case .exportEDL(let id): return "/dvr/recordings/\(id)/export.edl"
        case .getCommercialStatus: return "/dvr/commercials/status"
        // DVR Playback
        case .getRecordingStream(let id): return "/dvr/recordings/\(id)/stream"
        case .streamRecordingDirect(let id): return "/dvr/stream/\(id)"
        case .getRecordingHLS(let id): return "/dvr/recordings/\(id)/hls/master.m3u8"
        case .getRecordingDASH(let id): return "/dvr/recordings/\(id)/dash/manifest.mpd"
        case .updateRecordingProgress(let id, _): return "/dvr/recordings/\(id)/progress"
        case .toggleRecordingWatched(let id): return "/dvr/recordings/\(id)/watched"
        case .toggleRecordingFavorite(let id): return "/dvr/recordings/\(id)/favorite"
        case .toggleRecordingKeep(let id): return "/dvr/recordings/\(id)/keep"
        case .trashRecording(let id): return "/dvr/recordings/\(id)/trash"
        case .validateStream: return "/dvr/validate-stream"
        // DVR Series Rules — GET list from /dvr/passes (returns PassResponse with "passes" key + PascalCase fields)
        case .getSeriesRules: return "/dvr/passes"
        case .createSeriesRule: return "/dvr/passes"
        case .updateSeriesRule(let id, _, _, _, _): return "/dvr/passes/\(id)"
        case .deleteSeriesRule(let id): return "/dvr/passes/\(id)"
        // DVR Conflicts
        case .getConflicts: return "/dvr/conflicts"
        case .checkConflict: return "/dvr/conflicts/check"
        case .resolveConflict: return "/dvr/conflicts/resolve"
        // DVR Settings
        case .getDiskUsage: return "/dvr/disk-usage"
        case .getQualityPresets: return "/dvr/quality-presets"
        case .getDVRSettings: return "/dvr/settings"
        case .updateDVRSettings: return "/dvr/settings"
        case .getDVRPasses: return "/dvr/passes"
        case .pauseDVRPass(let id): return "/dvr/passes/\(id)/pause"
        case .resumeDVRPass(let id): return "/dvr/passes/\(id)/resume"
        case .getDVRSchedule: return "/dvr/schedule"
        case .getDVRCalendar: return "/dvr/calendar"
        case .getDVRLabels: return "/dvr/labels"
        case .bulkLabelAction: return "/dvr/labels/bulk"
        case .getFilesByLabel(let label): return "/dvr/labels/\(label)/files"
        case .setRecordingLabels(let id, _): return "/dvr/recordings/\(id)/labels"
        // DVR V2 Jobs
        case .getV2Jobs: return "/dvr/v2/jobs"
        case .getV2Job(let id): return "/dvr/v2/jobs/\(id)"
        case .createV2Job: return "/dvr/v2/jobs"
        case .updateV2Job(let id, _): return "/dvr/v2/jobs/\(id)"
        case .deleteV2Job(let id): return "/dvr/v2/jobs/\(id)"
        case .cancelV2Job(let id): return "/dvr/v2/jobs/\(id)/cancel"
        // DVR V2 Files
        case .getV2Files: return "/dvr/v2/files"
        case .getV2LockedFiles: return "/dvr/v2/files/locked"
        case .getV2File(let id): return "/dvr/v2/files/\(id)"
        case .updateV2File(let id, _): return "/dvr/v2/files/\(id)"
        case .deleteV2File(let id): return "/dvr/v2/files/\(id)"
        case .streamV2File(let id): return "/dvr/v2/files/\(id)/stream"
        case .getV2FileDASH(let id): return "/dvr/v2/files/\(id)/dash/manifest.mpd"
        case .updateV2FileState(let id, _, _, _): return "/dvr/v2/files/\(id)/state"
        case .setV2FileLabels(let id, _): return "/dvr/v2/files/\(id)/labels"
        case .lockV2File(let id): return "/dvr/v2/files/\(id)/lock"
        case .unlockV2File(let id): return "/dvr/v2/files/\(id)/lock"
        case .exportV2FileEDL(let id): return "/dvr/v2/files/\(id)/export.edl"
        case .stripAds(let id): return "/dvr/v2/files/\(id)/strip-ads"
        case .getStripAdsStatus(let id): return "/dvr/v2/files/\(id)/strip-ads/status"
        case .undoStripAds(let id): return "/dvr/v2/files/\(id)/strip-ads/undo"
        case .regroupV2File(let id): return "/dvr/v2/files/\(id)/regroup"
        // DVR V2 File Upload
        case .uploadV2File: return "/dvr/v2/files/upload"
        case .importV2File: return "/dvr/v2/files/import"
        case .bulkImportV2Files: return "/dvr/v2/files/import/bulk"
        case .getUploadProgress(let id): return "/dvr/v2/files/upload/\(id)/progress"
        // DVR V2 Groups
        case .getV2Groups: return "/dvr/v2/groups"
        case .getV2Group(let id): return "/dvr/v2/groups/\(id)"
        case .deleteV2Group(let id): return "/dvr/v2/groups/\(id)"
        case .updateV2GroupState(let id, _): return "/dvr/v2/groups/\(id)/state"
        case .regroupV2Files: return "/dvr/v2/groups/regroup"
        // DVR V2 Rules
        case .getV2Rules: return "/dvr/v2/rules"
        case .getV2Rule(let id): return "/dvr/v2/rules/\(id)"
        case .createV2Rule: return "/dvr/v2/rules"
        case .updateV2Rule(let id, _): return "/dvr/v2/rules/\(id)"
        case .deleteV2Rule(let id): return "/dvr/v2/rules/\(id)"
        case .previewV2Rule: return "/dvr/v2/rules/preview"
        case .previewExistingV2Rule(let id): return "/dvr/v2/rules/\(id)/preview"
        // DVR V2 Duplicates
        case .getV2Duplicates: return "/dvr/v2/duplicates"
        case .checkV2Duplicate: return "/dvr/v2/duplicates/check"
        case .getV2DuplicateStats: return "/dvr/v2/duplicates/stats"
        case .overrideV2Duplicate(let id): return "/dvr/v2/duplicates/\(id)/override"
        // DVR V2 Up Next
        case .getV2UpNext: return "/dvr/v2/upnext"
        // DVR V2 Virtual Stations
        case .getVirtualStations: return "/dvr/v2/virtual-stations"
        case .getVirtualStation(let id): return "/dvr/v2/virtual-stations/\(id)"
        case .createVirtualStation: return "/dvr/v2/virtual-stations"
        case .updateVirtualStation(let id, _): return "/dvr/v2/virtual-stations/\(id)"
        case .deleteVirtualStation(let id): return "/dvr/v2/virtual-stations/\(id)"
        case .streamVirtualStation(let id): return "/dvr/v2/virtual-stations/\(id)/stream.m3u8"
        // DVR V2 Collections
        case .getV2Collections: return "/dvr/v2/collections"
        case .getV2Collection(let id): return "/dvr/v2/collections/\(id)"
        case .createV2Collection: return "/dvr/v2/collections"
        case .updateV2Collection(let id, _): return "/dvr/v2/collections/\(id)"
        case .deleteV2Collection(let id): return "/dvr/v2/collections/\(id)"
        case .getV2CollectionItems(let id): return "/dvr/v2/collections/\(id)/items"
        // DVR V2 Trash
        case .getV2Trash: return "/dvr/v2/trash"
        case .restoreFromTrash(let id): return "/dvr/v2/trash/\(id)/restore"
        case .emptyTrash: return "/dvr/v2/trash"
        case .permanentlyDelete(let id): return "/dvr/v2/trash/\(id)"
        // DVR V2 Channel Collections
        case .getChannelCollections: return "/dvr/v2/channel-collections"
        case .createChannelCollection: return "/dvr/v2/channel-collections"
        case .previewChannelCollectionRules: return "/dvr/v2/channel-collection-rules/preview"
        case .getChannelCollectionGroups: return "/dvr/v2/channel-collection-meta/groups"
        case .getChannelCollectionSources: return "/dvr/v2/channel-collection-meta/sources"
        case .getChannelCollection(let id): return "/dvr/v2/channel-collections/\(id)"
        case .updateChannelCollection(let id, _): return "/dvr/v2/channel-collections/\(id)"
        case .deleteChannelCollection(let id): return "/dvr/v2/channel-collections/\(id)"
        case .exportChannelCollectionM3U(let id): return "/dvr/v2/channel-collections/\(id)/export.m3u"
        // DVR V2 Conflicts
        case .getV2Conflicts: return "/dvr/v2/conflicts"
        case .getV2ConflictAlternatives(let id): return "/dvr/v2/conflicts/\(id)/alternatives"
        case .resolveV2Conflict(let id, _): return "/dvr/v2/conflicts/\(id)/resolve"
        case .autoResolveV2Conflicts: return "/dvr/v2/conflicts/auto-resolve"
        // DVR V2 Chapters
        case .getChapters(let id): return "/dvr/v2/files/\(id)/chapters"
        case .addChapter(let id, _, _, _, _): return "/dvr/v2/files/\(id)/chapters"
        case .updateChapter(let fId, let cId, _): return "/dvr/v2/files/\(fId)/chapters/\(cId)"
        case .deleteChapter(let fId, let cId): return "/dvr/v2/files/\(fId)/chapters/\(cId)"
        case .detectChapters(let id): return "/dvr/v2/files/\(id)/chapters/detect"
        // Media Streaming
        case .streamMediaFile(let id): return "/library/parts/\(id)/file"
        case .startHLSTranscode: return "/video/-/transcode/universal/start.m3u8"
        case .startDASHTranscode: return "/video/-/transcode/dash/start.mpd"
        // Playback Decision API
        case .registerClientCapabilities: return "/api/playback/capabilities"
        case .getClientCapabilities(let id): return "/api/playback/capabilities/\(id)"
        case .getDefaultCapabilities: return "/api/playback/capabilities/defaults"
        case .getPlaybackDecision(let id): return "/api/playback/decide/\(id)"
        case .postPlaybackDecision(let id, _): return "/api/playback/decide/\(id)"
        case .getPlaybackOptions(let id): return "/api/playback/options/\(id)"
        case .reportBandwidth: return "/api/playback/bandwidth"
        case .getServerBandwidth: return "/api/playback/bandwidth/server"
        case .setServerBandwidthLimit: return "/api/playback/bandwidth/server/limit"
        case .getClientBandwidth(let id): return "/api/playback/bandwidth/\(id)"
        case .setClientBandwidthCap(let id, _): return "/api/playback/bandwidth/\(id)/cap"
        case .getSkipMarkers(let id): return "/api/playback/\(id)/markers"
        case .getLibrarySkipMarkers(let id): return "/api/playback/\(id)/markers/library"
        case .reportSkip(let id, _, _): return "/api/playback/\(id)/skip"
        case .getSkipSettings: return "/api/playback/skip-settings"
        case .updateSkipSettings: return "/api/playback/skip-settings"
        case .getMediaTracks(let id): return "/api/playback/\(id)/tracks"
        case .selectTracks(let id, _, _): return "/api/playback/\(id)/tracks/select"
        case .getTrackPreferences: return "/api/playback/track-preferences"
        case .updateTrackPreferences: return "/api/playback/track-preferences"
        case .getSpeedPresets: return "/api/playback/speed-presets"
        case .setPlaybackSpeed: return "/api/playback/speed"
        case .getSessionSpeed(let id): return "/api/playback/sessions/\(id)/speed"
        case .setSessionSpeed(let id, _): return "/api/playback/sessions/\(id)/speed"
        case .getFrameRate(let id): return "/api/playback/\(id)/framerate"
        case .getFrameRateSettings: return "/api/playback/framerate-settings"
        case .updateFrameRateSettings: return "/api/playback/framerate-settings"
        // VOD
        case .getVODProviders: return "/api/vod/providers"
        case .getVODMovies(let p): return "/api/vod/\(p)/movies"
        case .getVODShows(let p): return "/api/vod/\(p)/shows"
        case .getVODGenres(let p): return "/api/vod/\(p)/genres"
        case .getVODMovieDetails(let p, let id): return "/api/vod/\(p)/movie/\(id)"
        case .getVODShowDetails(let p, let id): return "/api/vod/\(p)/show/\(id)"
        case .startVODDownload(let p, _, _): return "/api/vod/\(p)/download"
        case .getVODQueue: return "/api/vod/queue"
        case .cancelVODDownload(let id): return "/api/vod/queue/\(id)"
        case .testVODConnection: return "/api/vod/test-connection"
        // Remote Access
        case .getConnectionInfo: return "/remote-access/connection-info"
        case .getRemoteAccessStatus: return "/remote-access/status"
        case .enableRemoteAccess: return "/remote-access/enable"
        case .disableRemoteAccess: return "/remote-access/disable"
        case .getRemoteAccessHealth: return "/remote-access/health"
        case .getRemoteAccessInstallInfo: return "/remote-access/install-info"
        case .getRemoteAccessLoginURL: return "/remote-access/login-url"
        // Notifications
        case .getNotificationConfig: return "/api/notifications/config"
        case .updateNotificationConfig: return "/api/notifications/config"
        case .testNotification: return "/api/notifications/test"
        case .getNotificationHistory: return "/api/notifications/history"
        // DDNS
        case .getDDNSStatus: return "/api/ddns/status"
        case .configureDDNS: return "/api/ddns/configure"
        case .testDDNS: return "/api/ddns/test"
        case .forceUpdateDDNS: return "/api/ddns/update"
        case .disableDDNS: return "/api/ddns/disable"
        // Speed Test
        case .pingSpeedTest: return "/api/speedtest/ping"
        case .downloadSpeedTest: return "/api/speedtest/download"
        case .uploadSpeedTest: return "/api/speedtest/upload"
        case .getSpeedTestResults(let id): return "/api/speedtest/results/\(id)"
        // Stream Health
        case .getHealthStreams: return "/api/health/streams"
        case .getStreamHealth(let id): return "/api/health/streams/\(id)"
        case .reportStreamHealth(let id, _, _, _): return "/api/health/streams/\(id)/report"
        case .getHealthChannels: return "/api/health/channels"
        case .getChannelHealthHistory(let id): return "/api/health/channels/\(id)/history"
        case .getHealthAlerts: return "/api/health/alerts"
        case .getHealthSummary: return "/api/health/summary"
        // Tuners
        case .getTuners: return "/api/tuners"
        case .addTuner: return "/api/tuners"
        case .discoverTuners: return "/api/tuners/discover"
        case .removeTuner(let id): return "/api/tuners/\(id)"
        case .getTunerLineup(let id): return "/api/tuners/\(id)/lineup"
        case .getTunerStatus(let id): return "/api/tuners/\(id)/status"
        case .importTunerChannels(let id): return "/api/tuners/\(id)/import"
        case .scanTunerChannels(let id): return "/api/tuners/\(id)/scan"
        // Bookmarks
        case .getBookmarks: return "/api/bookmarks"
        case .createBookmark: return "/api/bookmarks"
        case .getBookmark(let id): return "/api/bookmarks/\(id)"
        case .updateBookmark(let id, _, _): return "/api/bookmarks/\(id)"
        case .deleteBookmark(let id): return "/api/bookmarks/\(id)"
        // Clips
        case .getClips: return "/api/clips"
        case .createClip: return "/api/clips"
        case .getClip(let id): return "/api/clips/\(id)"
        case .deleteClip(let id): return "/api/clips/\(id)"
        case .downloadClip(let id): return "/api/clips/\(id)/download"
        case .streamClip(let id): return "/api/clips/\(id)/stream"
        // Offline
        case .requestOfflineDownload: return "/api/offline/request"
        case .getOfflineDownloads: return "/api/offline/downloads"
        case .streamOfflineContent(let id): return "/api/offline/\(id)/stream"
        case .updateOfflineProgress(let id, _): return "/api/offline/\(id)/progress"
        case .syncOfflineWatchState(let id, _, _): return "/api/offline/\(id)/watch-state"
        case .deleteOfflineDownload(let id): return "/api/offline/\(id)"
        case .getOfflineSettings: return "/api/offline/settings"
        case .updateOfflineSettings: return "/api/offline/settings"
        // Subtitles
        case .searchSubtitles: return "/api/subtitles/search"
        case .downloadSubtitle: return "/api/subtitles/download"
        case .getSubtitleConfig: return "/api/subtitles/config"
        case .updateSubtitleConfig: return "/api/subtitles/config"
        case .getSubtitlesForMedia(let id): return "/api/subtitles/\(id)"
        case .deleteSubtitle(let id, let lang): return "/api/subtitles/\(id)/\(lang)"
        // Scheduled Tasks
        case .getScheduledTasks: return "/api/scheduler/tasks"
        case .getScheduledTask(let id): return "/api/scheduler/tasks/\(id)"
        case .updateScheduledTask(let id, _, _): return "/api/scheduler/tasks/\(id)"
        case .triggerScheduledTask(let id): return "/api/scheduler/tasks/\(id)/run"
        case .getSchedulerHistory: return "/api/scheduler/history"
        // Admin Libraries
        case .getAdminLibraries: return "/admin/libraries"
        case .createAdminLibrary: return "/admin/libraries"
        case .getAdminLibrary(let id): return "/admin/libraries/\(id)"
        case .updateAdminLibrary(let id, _, _): return "/admin/libraries/\(id)"
        case .deleteAdminLibrary(let id): return "/admin/libraries/\(id)"
        case .addLibraryPath(let id, _): return "/admin/libraries/\(id)/paths"
        case .removeLibraryPath(let id, let pId): return "/admin/libraries/\(id)/paths/\(pId)"
        case .scanLibrary(let id): return "/admin/libraries/\(id)/scan"
        case .getLibraryStats(let id): return "/admin/libraries/\(id)/stats"
        case .browseFilesystem: return "/admin/filesystem/browse"
        // Admin Settings
        case .getAdminSettings: return "/admin/settings"
        case .updateAdminSettings: return "/admin/settings"
        // Admin Backups
        case .createBackup: return "/admin/backups"
        case .listBackups: return "/admin/backups"
        case .downloadBackup(let f): return "/admin/backups/\(f)/download"
        case .deleteBackup(let f): return "/admin/backups/\(f)"
        case .restoreBackup(let f): return "/admin/backups/\(f)/restore"
        // Admin Search
        case .reindexSearch: return "/admin/search/reindex"
        case .getSearchStats: return "/admin/search/stats"
        // Admin Updater
        case .getUpdaterStatus: return "/admin/updater/status"
        case .checkForUpdates: return "/admin/updater/check"
        case .applyUpdate: return "/admin/updater/apply"
        // Admin Media
        case .getAdminMedia: return "/admin/media"
        case .updateAdminMedia(let id, _): return "/admin/media/\(id)"
        case .refreshMediaMetadata(let id): return "/admin/media/\(id)/refresh"
        case .refreshMissingMetadata: return "/admin/media/refresh-missing"
        case .searchTMDB: return "/admin/media/search-tmdb"
        case .applyMediaMatch(let id, _, _): return "/admin/media/\(id)/match"
        // Auto-Update
        case .getAutoUpdateConfig: return "/api/updates/auto-config"
        case .setAutoUpdateConfig: return "/api/updates/auto-config"
        case .getUpdateSchedule: return "/api/updates/schedule"
        case .checkForUpdatesNow: return "/api/updates/check-now"
        // Config
        case .exportConfig: return "/config/export"
        case .importConfig: return "/config/import"
        case .getConfigStats: return "/config/stats"
        // Device Management
        case .registerDevice: return "/api/devices/register"
        case .getMyDeviceSettings: return "/api/devices/my-settings"
        case .listDevices: return "/api/devices"
        case .getDevice(let id): return "/api/devices/\(id)"
        case .updateDevice(let id, _): return "/api/devices/\(id)"
        case .deleteDevice(let id): return "/api/devices/\(id)"
        // Guide Data
        case .refreshGuideData: return "/api/guide/refresh"
        case .rebuildGuideData: return "/api/guide/rebuild"
        // Server
        case .getServerRoot: return "/"
        case .getIdentity: return "/identity"
        case .getServerInfo: return "/server/info"
        case .getCapabilities: return "/server/capabilities"
        case .healthCheckSimple: return "/health"
        // Instant Switch
        case .instantSwitchStatus: return "/api/instant/status"
        case .instantSwitchSetEnabled: return "/api/instant/enabled"
        case .instantSwitchChannel: return "/api/instant/switch"
        case .instantSwitchFavorites: return "/api/instant/favorites"
        case .instantSwitchSetFavorites: return "/api/instant/favorites"
        case .instantSwitchPredictions: return "/api/instant/predictions"
        case .instantSwitchCached: return "/api/instant/cached"
        case .instantSwitchStream(let id): return "/api/instant/stream/\(id)"
        // Downloads
        case .createInvite: return "/api/invite"
        case .getClaimToken: return "/api/claim-token"
        case .generateClaimToken: return "/api/claim-token"
        case .getAppDownloads: return "/downloads"
        case .downloadApp(let f): return "/downloads/\(f)"
        }
    }

    // MARK: - Method
    var method: HTTPMethod {
        switch self {
        case .login, .register, .logout, .switchProfile,
             .createProfile, .setParentalPin, .verifyParentalPin,
             .submitClientLogs, .startSession,
             .createPlaylist, .addToPlaylist,
             .createAdminPlaylist, .addAdminPlaylistItems,
             .createPersonalSection, .previewSmartFilter, .addToPersonalSection,
             .addToWatchlist, .createCollection, .addToCollection,
             .bulkMapChannels, .autoDetectEPGMappings, .mapChannelNumbers,
             .toggleFavorite, .refreshChannelEPG,
             .createChannelGroup, .addChannelToGroup, .autoDetectDuplicates,
             .addM3USource, .refreshM3USource, .importVOD, .importSeries,
             .addXtreamSource, .testXtreamSource, .refreshXtreamSource,
             .parseXtreamFromM3U, .importXtreamVOD, .importXtreamSeries, .importAllXtream,
             .previewEPGSource, .addEPGSource, .refreshEPGSource,
             .refreshAllEPG, .forceEPGRefresh, .invalidateGuideCache,
             .resolveEPGDuplicates, .resolveEPGOverlaps, .cleanupEPG, .cleanupLiveTVDatabase,
             .fetchEPGWithFallback, .resetEPGSourceHealth,
             .startTimeshift, .stopTimeshift,
             .enableArchive, .disableArchive,
             .enrichEPG,
             .createTeamPass, .toggleTeamPass, .processTeamPasses,
             .scheduleRecording, .recordFromProgram, .bulkRecordingAction, .matchRecording,
             .detectCommercials, .reprocessRecording,
             .checkConflict, .resolveConflict,
             .bulkLabelAction,
             .createV2Job, .cancelV2Job,
             .uploadV2File, .importV2File, .bulkImportV2Files,
             .regroupV2Files,
             .createV2Rule, .previewV2Rule,
             .overrideV2Duplicate,
             .createVirtualStation,
             .createV2Collection,
             .restoreFromTrash,
             .createChannelCollection, .previewChannelCollectionRules,
             .resolveV2Conflict, .autoResolveV2Conflicts,
             .addChapter, .detectChapters,
             .stripAds, .undoStripAds, .regroupV2File,
             .registerClientCapabilities, .postPlaybackDecision, .reportBandwidth, .reportSkip,
             .startVODDownload,
             .enableRemoteAccess, .disableRemoteAccess,
             .updateNotificationConfig, .testNotification,
             .configureDDNS, .testDDNS, .forceUpdateDDNS,
             .uploadSpeedTest,
             .reportStreamHealth,
             .addTuner, .discoverTuners, .importTunerChannels, .scanTunerChannels,
             .createBookmark, .createClip,
             .requestOfflineDownload,
             .downloadSubtitle,
             .triggerScheduledTask,
             .createAdminLibrary, .addLibraryPath, .scanLibrary,
             .createBackup, .restoreBackup,
             .reindexSearch,
             .checkForUpdates, .applyUpdate,
             .refreshMediaMetadata, .refreshMissingMetadata, .applyMediaMatch,
             .checkForUpdatesNow,
             .importConfig,
             .registerDevice,
             .refreshGuideData, .rebuildGuideData,
             .timeline,
             .instantSwitchSetEnabled, .instantSwitchChannel, .instantSwitchSetFavorites,
             .createInvite, .generateClaimToken,
             .stopRecording:
            return .POST

        case .updateUser, .changePassword, .updateProfile,
             .updateParentalSettings,
             .updateGlobalClientSettings,
             .setMetadataPrefs, .selectStreams,
             .updateProgress,
             .removeFromContinueWatching,
             .updateSession,
             .movePlaylistItem,
             .updateAdminPlaylist, .reorderAdminPlaylistItems,
             .updatePersonalSection, .reorderPersonalSection,
             .updateChannel,
             .updateChannelGroup, .updateGroupMemberPriority,
             .updateM3USource, .updateXtreamSource, .updateEPGSource,
             .updateTeamPass,
             .updateRecording, .updateRecordingPriority, .updateRecordingProgress,
             .toggleRecordingWatched, .toggleRecordingFavorite, .toggleRecordingKeep,
             .updateDVRSettings,
             .pauseDVRPass, .resumeDVRPass,
             .setRecordingLabels,
             .updateV2Job, .updateV2File,
             .updateV2FileState, .setV2FileLabels, .lockV2File,
             .updateV2GroupState,
             .updateV2Rule,
             .updateVirtualStation, .updateV2Collection,
             .updateChannelCollection,
             .updateChapter,
             .selectTracks, .updateTrackPreferences,
             .setPlaybackSpeed, .setSessionSpeed,
             .updateSkipSettings, .updateFrameRateSettings,
             .setServerBandwidthLimit, .setClientBandwidthCap,
             .updateNotificationConfig,
             .updateBookmark,
             .updateOfflineProgress, .syncOfflineWatchState, .updateOfflineSettings,
             .updateSubtitleConfig,
             .updateScheduledTask,
             .updateAdminLibrary, .updateAdminSettings,
             .updateAdminMedia,
             .setAutoUpdateConfig,
             .updateDevice:
            return .PUT

        case .deleteProfile,
             .deleteGlobalClientSetting,
             .clearServerLogs, .clearClientLogs,
             .removeFromPlaylist, .clearPlaylist, .deletePlaylist,
             .deleteAdminPlaylist, .removeAdminPlaylistItem,
             .deletePersonalSection, .removeFromPersonalSection,
             .removeFromWatchlist,
             .removeFromCollection, .deleteCollection,
             .removeEPGMapping,
             .deleteChannelGroup, .removeChannelFromGroup,
             .deleteM3USource, .deleteXtreamSource, .deleteEPGSource,
             .deleteTeamPass,
             .deleteRecording, .trashRecording,
             .deleteSeriesRule,
             .deleteV2Job, .deleteV2File, .unlockV2File,
             .deleteV2Group,
             .deleteV2Rule,
             .deleteVirtualStation, .deleteV2Collection,
             .emptyTrash, .permanentlyDelete,
             .deleteChannelCollection,
             .deleteChapter,
             .cancelVODDownload,
             .disableDDNS,
             .removeTuner,
             .deleteBookmark, .deleteClip,
             .deleteOfflineDownload,
             .deleteSubtitle,
             .deleteAdminLibrary, .removeLibraryPath,
             .deleteBackup,
             .deleteDevice,
             .stopSession:
            return .DELETE

        default:
            return .GET
        }
    }

    // MARK: - Query Items
    var queryItems: [URLQueryItem]? {
        switch self {
        case .search(let query, let limit):
            var items = [URLQueryItem(name: "query", value: query)]
            if let limit = limit { items.append(URLQueryItem(name: "limit", value: "\(limit)")) }
            return items
        case .searchHubs(let query):
            return [URLQueryItem(name: "query", value: query)]
        case .getLibraryItems(_, let start, let size, let sort, let filters):
            var items: [URLQueryItem] = []
            if let s = start { items.append(URLQueryItem(name: "X-Plex-Container-Start", value: "\(s)")) }
            if let s = size { items.append(URLQueryItem(name: "X-Plex-Container-Size", value: "\(s)")) }
            if let s = sort { items.append(URLQueryItem(name: "sort", value: s)) }
            if let f = filters { for (k, v) in f { items.append(URLQueryItem(name: k, value: v)) } }
            return items.isEmpty ? nil : items
        case .getPlaybackURL(let path, let directPlay):
            return [
                URLQueryItem(name: "path", value: path),
                URLQueryItem(name: "directPlay", value: directPlay ? "1" : "0")
            ]
        case .updateProgress(let key, let time, let state):
            return [
                URLQueryItem(name: "key", value: key),
                URLQueryItem(name: "time", value: "\(time)"),
                URLQueryItem(name: "state", value: state)
            ]
        case .scrobble(let key), .unscrobble(let key):
            return [URLQueryItem(name: "key", value: key)]
        case .getGuide(let start, let end), .getChannelGuide(_, let start, let end):
            var items: [URLQueryItem] = []
            if let s = start { items.append(URLQueryItem(name: "start", value: s)) }
            if let e = end { items.append(URLQueryItem(name: "end", value: e)) }
            return items.isEmpty ? nil : items
        case .getRecordings(let status):
            if let s = status { return [URLQueryItem(name: "status", value: s)] }
            return nil
        case .getOnLaterSports(let league, let team):
            var items: [URLQueryItem] = []
            if let l = league { items.append(URLQueryItem(name: "league", value: l)) }
            if let t = team { items.append(URLQueryItem(name: "team", value: t)) }
            return items.isEmpty ? nil : items
        case .searchOnLater(let query), .searchOnLaterTeams(let query), .searchTeams(let query):
            return [URLQueryItem(name: "query", value: query)]
        case .validateStream(let url):
            return [URLQueryItem(name: "url", value: url)]
        case .proxyXtreamM3U8(let url):
            return [URLQueryItem(name: "url", value: url)]
        case .discoverGracenoteProviders(let zip):
            return [URLQueryItem(name: "zip", value: zip)]
        case .discoverTVGuideProviders(let zip):
            return [URLQueryItem(name: "zip", value: zip)]
        case .getEPGPrograms(let channelId, let date):
            var items: [URLQueryItem] = []
            if let c = channelId { items.append(URLQueryItem(name: "channelId", value: c)) }
            if let d = date { items.append(URLQueryItem(name: "date", value: d)) }
            return items.isEmpty ? nil : items
        case .checkV2Duplicate(let title, let startTime):
            return [URLQueryItem(name: "title", value: title), URLQueryItem(name: "startTime", value: startTime)]
        case .startHLSTranscode(let path, let session):
            var items = [URLQueryItem(name: "path", value: path)]
            if let s = session { items.append(URLQueryItem(name: "session", value: s)) }
            return items
        case .startDASHTranscode(let path, let session):
            var items = [URLQueryItem(name: "path", value: path)]
            if let s = session { items.append(URLQueryItem(name: "session", value: s)) }
            return items
        case .selectStreams(_, let audioId, let subtitleId):
            var items: [URLQueryItem] = []
            if let a = audioId { items.append(URLQueryItem(name: "audioStreamID", value: "\(a)")) }
            if let s = subtitleId { items.append(URLQueryItem(name: "subtitleStreamID", value: "\(s)")) }
            return items.isEmpty ? nil : items
        case .getAdminMedia(let query, let type):
            var items: [URLQueryItem] = []
            if let q = query { items.append(URLQueryItem(name: "query", value: q)) }
            if let t = type { items.append(URLQueryItem(name: "type", value: t)) }
            return items.isEmpty ? nil : items
        case .searchTMDB(let query, let type):
            var items = [URLQueryItem(name: "query", value: query)]
            if let t = type { items.append(URLQueryItem(name: "type", value: t)) }
            return items
        case .browseFilesystem(let path):
            return [URLQueryItem(name: "path", value: path)]
        case .searchSubtitles(let query, let lang, let mediaId):
            var items: [URLQueryItem] = []
            if let q = query { items.append(URLQueryItem(name: "query", value: q)) }
            if let l = lang { items.append(URLQueryItem(name: "lang", value: l)) }
            if let m = mediaId { items.append(URLQueryItem(name: "mediaId", value: m)) }
            return items.isEmpty ? nil : items
        case .mapChannelNumbers(let sourceId):
            return [URLQueryItem(name: "sourceId", value: sourceId)]
        case .removeFromContinueWatching(let ratingKey):
            return [URLQueryItem(name: "ratingKey", value: ratingKey)]
        case .instantSwitchPredictions(let channelId, let count):
            var items: [URLQueryItem] = []
            if let c = channelId { items.append(URLQueryItem(name: "channel_id", value: c)) }
            if let n = count { items.append(URLQueryItem(name: "count", value: "\(n)")) }
            return items.isEmpty ? nil : items
        default:
            return nil
        }
    }

    // MARK: - Body
    var body: Data? {
        switch self {
        case .login(let u, let p):
            return jsonBody(["username": u, "password": p])
        case .register(let n, let e, let p):
            return jsonBody(["name": n, "email": e, "password": p])
        case .switchProfile(_, let pin):
            if let p = pin { return jsonBody(["pin": p]) }
            return nil
        case .createProfile(let name, let isKid, let pin):
            var d: [String: Any] = ["name": name, "isKid": isKid]
            if let p = pin { d["pin"] = p }
            return jsonBody(d)
        case .updateProfile(_, let name, let isKid, let pin):
            var d: [String: Any] = [:]
            if let n = name { d["name"] = n }
            if let k = isKid { d["isKid"] = k }
            if let p = pin { d["pin"] = p }
            return d.isEmpty ? nil : jsonBody(d)
        case .updateUser(let name, let email):
            var d: [String: Any] = [:]
            if let n = name { d["name"] = n }
            if let e = email { d["email"] = e }
            return d.isEmpty ? nil : jsonBody(d)
        case .changePassword(let cur, let new):
            return jsonBody(["currentPassword": cur, "newPassword": new])
        case .setParentalPin(let pin):
            return jsonBody(["pin": pin])
        case .verifyParentalPin(let pin):
            return jsonBody(["pin": pin])
        case .updateParentalSettings(let enabled, let rating, let pin):
            var d: [String: Any] = ["enabled": enabled]
            if let r = rating { d["rating"] = r }
            if let p = pin { d["pin"] = p }
            return jsonBody(d)
        case .updateGlobalClientSettings(let s), .updateDVRSettings(let s), .updateAdminSettings(let s),
             .updateOfflineSettings(let s), .updateSubtitleConfig(let s), .updateNotificationConfig(let s),
             .updateSkipSettings(let s), .updateTrackPreferences(let s), .updateFrameRateSettings(let s):
            return jsonBody(s)
        case .submitClientLogs(let entries):
            return jsonBody(["entries": entries])
        case .startSession(let mediaId):
            return jsonBody(["mediaId": mediaId])
        case .updateSession(_, let state, let position):
            var d: [String: Any] = [:]
            if let s = state { d["state"] = s }
            if let p = position { d["position"] = p }
            return d.isEmpty ? nil : jsonBody(d)
        case .timeline(let ratingKey, let state, let time, let duration):
            return jsonBody(["ratingKey": ratingKey, "state": state, "time": time, "duration": duration])
        case .createPlaylist(let name):
            return jsonBody(["title": name])
        case .addToPlaylist(_, let ids):
            return jsonBody(["mediaIds": ids])
        case .movePlaylistItem(_, _, let idx):
            return jsonBody(["newIndex": idx])
        case .createAdminPlaylist(let title, let desc):
            var d: [String: Any] = ["title": title]
            if let ds = desc { d["description"] = ds }
            return jsonBody(d)
        case .updateAdminPlaylist(_, let title, let desc):
            var d: [String: Any] = [:]
            if let t = title { d["title"] = t }
            if let ds = desc { d["description"] = ds }
            return d.isEmpty ? nil : jsonBody(d)
        case .addAdminPlaylistItems(_, let ids):
            return jsonBody(["itemIds": ids])
        case .reorderAdminPlaylistItems(_, let ids):
            return jsonBody(["itemIds": ids])
        case .createPersonalSection(let title, let type, let smart, let filter):
            var d: [String: Any] = ["title": title, "type": type]
            if let s = smart { d["smart"] = s }
            if let f = filter { d["filter"] = f }
            return jsonBody(d)
        case .previewSmartFilter(let filter):
            return jsonBody(["filter": filter])
        case .updatePersonalSection(_, let title, let filter):
            var d: [String: Any] = [:]
            if let t = title { d["title"] = t }
            if let f = filter { d["filter"] = f }
            return d.isEmpty ? nil : jsonBody(d)
        case .addToPersonalSection(_, let ids):
            return jsonBody(["itemIds": ids])
        case .reorderPersonalSection(_, let ids):
            return jsonBody(["itemIds": ids])
        case .createCollection(let sectionId, let name):
            return jsonBody(["sectionId": sectionId, "name": name])
        case .addToCollection(_, let ids):
            return jsonBody(["mediaIds": ids])
        case .updateChannel(_, let name, let number, let enabled, let group, let logo):
            var d: [String: Any] = [:]
            if let n = name { d["name"] = n }
            if let num = number { d["number"] = num }
            if let e = enabled { d["enabled"] = e }
            if let g = group { d["group"] = g }
            if let l = logo { d["logo"] = l }
            return d.isEmpty ? nil : jsonBody(d)
        case .bulkMapChannels(let mappings):
            return jsonBody(["mappings": mappings])
        case .createChannelGroup(let name, let ids):
            return jsonBody(["name": name, "channelIds": ids])
        case .updateChannelGroup(_, let name, let enabled):
            var d: [String: Any] = [:]
            if let n = name { d["name"] = n }
            if let e = enabled { d["enabled"] = e }
            return d.isEmpty ? nil : jsonBody(d)
        case .addChannelToGroup(_, let chId, let priority):
            return jsonBody(["channelId": chId, "priority": priority])
        case .updateGroupMemberPriority(_, _, let priority):
            return jsonBody(["priority": priority])
        case .addM3USource(let name, let url, let epgUrl):
            var d: [String: Any] = ["name": name, "url": url]
            if let e = epgUrl { d["epgUrl"] = e }
            return jsonBody(d)
        case .updateM3USource(_, let name, let url, let epgUrl, let enabled):
            var d: [String: Any] = [:]
            if let n = name { d["name"] = n }
            if let u = url { d["url"] = u }
            if let e = epgUrl { d["epgUrl"] = e }
            if let en = enabled { d["enabled"] = en }
            return d.isEmpty ? nil : jsonBody(d)
        case .addXtreamSource(let name, let serverUrl, let username, let password):
            return jsonBody(["name": name, "serverUrl": serverUrl, "username": username, "password": password])
        case .updateXtreamSource(_, let name, let enabled, let importLive, let importVod, let importSeries):
            var d: [String: Any] = [:]
            if let n = name { d["name"] = n }
            if let e = enabled { d["enabled"] = e }
            if let l = importLive { d["importLive"] = l }
            if let v = importVod { d["importVod"] = v }
            if let s = importSeries { d["importSeries"] = s }
            return d.isEmpty ? nil : jsonBody(d)
        case .previewEPGSource(let url, let type):
            return jsonBody(["url": url, "type": type])
        case .addEPGSource(let name, let url, let type, let tvguideProviderId, let tvguideZipCode, let tvguideDays):
            var d: [String: Any] = ["name": name, "providerType": type]
            if let u = url { d["url"] = u }
            if let pid = tvguideProviderId { d["tvguideProviderId"] = pid }
            if let zip = tvguideZipCode { d["tvguideZipCode"] = zip }
            if let days = tvguideDays { d["tvguideDays"] = days }
            return jsonBody(d)
        case .updateEPGSource(_, let name, let url, let enabled):
            var d: [String: Any] = [:]
            if let n = name { d["name"] = n }
            if let u = url { d["url"] = u }
            if let e = enabled { d["enabled"] = e }
            return d.isEmpty ? nil : jsonBody(d)
        case .enableArchive(_, let days):
            return jsonBody(["days": days])
        case .enrichEPG(let ids):
            return jsonBody(["programIds": ids])
        case .createTeamPass(let teamName, let league, let channelIds, let prePadding, let postPadding):
            var d: [String: Any] = ["teamName": teamName, "league": league]
            if let c = channelIds { d["channelIds"] = c }
            if let p = prePadding { d["prePadding"] = p }
            if let p = postPadding { d["postPadding"] = p }
            return jsonBody(d)
        case .updateTeamPass(_, let teamName, let channelIds, let prePadding, let postPadding, let enabled):
            var d: [String: Any] = [:]
            if let t = teamName { d["teamName"] = t }
            if let c = channelIds { d["channelIds"] = c }
            if let p = prePadding { d["prePadding"] = p }
            if let p = postPadding { d["postPadding"] = p }
            if let e = enabled { d["enabled"] = e }
            return d.isEmpty ? nil : jsonBody(d)
        case .scheduleRecording(let channelId, let startTime, let endTime, let title):
            return jsonBody(["channelId": channelId, "startTime": startTime, "endTime": endTime, "title": title])
        case .recordFromProgram(let channelId, let programId):
            return jsonBody(["channelId": channelId, "programId": programId])
        case .bulkRecordingAction(let action, let ids):
            return jsonBody(["action": action, "recordingIds": ids])
        case .updateRecording(_, let updates):
            return jsonBody(updates)
        case .matchRecording(_, let tmdbId, let type):
            return jsonBody(["tmdbId": tmdbId, "type": type])
        case .updateRecordingPriority(_, let priority):
            return jsonBody(["priority": priority])
        case .updateRecordingProgress(_, let time):
            return jsonBody(["time": time])
        case .setRecordingLabels(_, let labels):
            return jsonBody(["labels": labels])
        case .resolveConflict(let conflictId, let keepIds):
            return jsonBody(["conflictId": conflictId, "keepRecordingIds": keepIds])
        case .checkConflict(let recordingId):
            return jsonBody(["recordingId": recordingId])
        case .bulkLabelAction(let action, let labels, let recordingIds):
            return jsonBody(["action": action, "labels": labels, "recordingIds": recordingIds])
        case .createV2Job(let p), .updateV2Job(_, let p), .updateV2File(_, let p),
             .updateV2GroupState(_, let p), .createV2Rule(let p), .updateV2Rule(_, let p),
             .previewV2Rule(let p), .createVirtualStation(let p), .updateVirtualStation(_, let p),
             .createV2Collection(let p), .updateV2Collection(_, let p),
             .createChannelCollection(let p), .updateChannelCollection(_, let p),
             .previewChannelCollectionRules(let p), .resolveV2Conflict(_, let p),
             .updateDevice(_, let p):
            return jsonBody(p)
        case .updateV2FileState(_, let watched, let position, let favorited):
            var d: [String: Any] = [:]
            if let w = watched { d["watched"] = w }
            if let p = position { d["position"] = p }
            if let f = favorited { d["favorited"] = f }
            return d.isEmpty ? nil : jsonBody(d)
        case .setV2FileLabels(_, let labels):
            return jsonBody(["labels": labels])
        case .importV2File(let path):
            return jsonBody(["path": path])
        case .bulkImportV2Files(let paths):
            return jsonBody(["paths": paths])
        case .addChapter(_, let title, let startTime, let endTime, let type):
            var d: [String: Any] = ["title": title, "startTime": startTime, "endTime": endTime]
            if let t = type { d["type"] = t }
            return jsonBody(d)
        case .updateChapter(_, _, let params):
            return jsonBody(params)
        case .registerClientCapabilities(let deviceId, let capabilities):
            var d = capabilities
            d["deviceId"] = deviceId
            return jsonBody(d)
        case .postPlaybackDecision(_, let capabilities):
            return jsonBody(capabilities)
        case .reportBandwidth(let clientId, let downloadSpeed, let uploadSpeed):
            return jsonBody(["clientId": clientId, "downloadSpeed": downloadSpeed, "uploadSpeed": uploadSpeed])
        case .setServerBandwidthLimit(let limit):
            return jsonBody(["limit": limit])
        case .setClientBandwidthCap(_, let cap):
            return jsonBody(["cap": cap])
        case .reportSkip(_, let type, let timestamp):
            return jsonBody(["type": type, "timestamp": timestamp])
        case .selectTracks(_, let audioId, let subtitleId):
            var d: [String: Any] = [:]
            if let a = audioId { d["audioStreamId"] = a }
            if let s = subtitleId { d["subtitleStreamId"] = s }
            return d.isEmpty ? nil : jsonBody(d)
        case .setPlaybackSpeed(let speed):
            return jsonBody(["speed": speed])
        case .setSessionSpeed(_, let speed):
            return jsonBody(["speed": speed])
        case .startVODDownload(_, let mediaId, let quality):
            var d: [String: Any] = ["mediaId": mediaId]
            if let q = quality { d["quality"] = q }
            return jsonBody(d)
        case .configureDDNS(let provider, let hostname, let username, let password):
            var d: [String: Any] = ["provider": provider, "hostname": hostname]
            if let u = username { d["username"] = u }
            if let p = password { d["password"] = p }
            return jsonBody(d)
        case .reportStreamHealth(_, let quality, let buffering, let errors):
            var d: [String: Any] = [:]
            if let q = quality { d["quality"] = q }
            if let b = buffering { d["buffering"] = b }
            if let e = errors { d["errors"] = e }
            return d.isEmpty ? nil : jsonBody(d)
        case .addTuner(let url, let name):
            return jsonBody(["url": url, "name": name])
        case .createBookmark(let mediaId, let time, let title, let description):
            var d: [String: Any] = ["mediaId": mediaId, "time": time]
            if let t = title { d["title"] = t }
            if let desc = description { d["description"] = desc }
            return jsonBody(d)
        case .updateBookmark(_, let title, let description):
            var d: [String: Any] = [:]
            if let t = title { d["title"] = t }
            if let desc = description { d["description"] = desc }
            return d.isEmpty ? nil : jsonBody(d)
        case .createClip(let mediaId, let startTime, let endTime, let title):
            var d: [String: Any] = ["mediaId": mediaId, "startTime": startTime, "endTime": endTime]
            if let t = title { d["title"] = t }
            return jsonBody(d)
        case .requestOfflineDownload(let mediaId, let quality):
            var d: [String: Any] = ["mediaId": mediaId]
            if let q = quality { d["quality"] = q }
            return jsonBody(d)
        case .updateOfflineProgress(_, let time):
            return jsonBody(["time": time])
        case .syncOfflineWatchState(_, let watched, let position):
            var d: [String: Any] = ["watched": watched]
            if let p = position { d["position"] = p }
            return jsonBody(d)
        case .downloadSubtitle(let subtitleId, let mediaId, let lang):
            return jsonBody(["subtitleId": subtitleId, "mediaId": mediaId, "lang": lang])
        case .updateScheduledTask(_, let enabled, let schedule):
            var d: [String: Any] = [:]
            if let e = enabled { d["enabled"] = e }
            if let s = schedule { d["schedule"] = s }
            return d.isEmpty ? nil : jsonBody(d)
        case .createAdminLibrary(let name, let type, let paths):
            return jsonBody(["name": name, "type": type, "paths": paths])
        case .updateAdminLibrary(_, let name, let scanInterval):
            var d: [String: Any] = [:]
            if let n = name { d["name"] = n }
            if let s = scanInterval { d["scanInterval"] = s }
            return d.isEmpty ? nil : jsonBody(d)
        case .addLibraryPath(_, let path):
            return jsonBody(["path": path])
        case .applyMediaMatch(_, let tmdbId, let type):
            return jsonBody(["tmdbId": tmdbId, "type": type])
        case .setAutoUpdateConfig(let enabled, let schedule):
            var d: [String: Any] = ["enabled": enabled]
            if let s = schedule { d["schedule"] = s }
            return jsonBody(d)
        case .registerDevice(let deviceId, let platform, let appVersion, let deviceModel, let osVersion):
            return jsonBody(["deviceId": deviceId, "platform": platform, "appVersion": appVersion, "deviceModel": deviceModel, "osVersion": osVersion])
        case .testNotification(let type, let destination):
            return jsonBody(["type": type, "destination": destination])
        case .setMetadataPrefs(_, let prefs):
            return jsonBody(prefs)
        case .createSeriesRule(let title, _, let prePadding, let postPadding, let keepCount):
            var d: [String: Any] = ["Name": title, "Type": "series"]
            if let p = prePadding { d["PaddingStart"] = p * 60 }  // UI uses minutes, server uses seconds
            if let p = postPadding { d["PaddingEnd"] = p * 60 }
            if let k = keepCount, k > 0 { d["KeepNum"] = k; d["KeepOnly"] = "last" }
            return jsonBody(d)
        case .updateSeriesRule(_, let enabled, let prePadding, let postPadding, let keepCount):
            var d: [String: Any] = [:]
            if let e = enabled { d["Paused"] = !e }
            if let p = prePadding { d["PaddingStart"] = p * 60 }
            if let p = postPadding { d["PaddingEnd"] = p * 60 }
            if let k = keepCount { d["KeepNum"] = k }
            return d.isEmpty ? nil : jsonBody(d)
        case .importVOD(_, let libraryId), .importSeries(_, let libraryId):
            return jsonBody(["libraryId": libraryId])
        case .parseXtreamFromM3U(let url):
            return jsonBody(["url": url])
        case .fetchEPGWithFallback(let sourceId):
            return jsonBody(["sourceId": sourceId])
        case .instantSwitchSetEnabled(let enabled):
            return jsonBody(["enabled": enabled])
        case .instantSwitchChannel(let channelId):
            return jsonBody(["channel_id": channelId])
        case .instantSwitchSetFavorites(let channelIds):
            return jsonBody(["favorites": channelIds])
        default:
            return nil
        }
    }

    // MARK: - Helpers
    private func jsonBody(_ dict: [String: Any]) -> Data? {
        try? JSONSerialization.data(withJSONObject: dict)
    }
}
