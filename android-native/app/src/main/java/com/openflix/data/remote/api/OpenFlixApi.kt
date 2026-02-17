package com.openflix.data.remote.api

import com.openflix.data.remote.dto.*
import retrofit2.Response
import retrofit2.http.*

/**
 * OpenFlix Server API interface.
 * Matches the Go backend endpoints.
 */
interface OpenFlixApi {

    // === Health Check ===

    @GET("health")
    suspend fun healthCheck(): Response<Map<String, Any>>

    // === Authentication ===

    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>

    @POST("auth/logout")
    suspend fun logout(): Response<Void>

    @GET("auth/user")
    suspend fun getCurrentUser(): Response<UserDto>

    @PUT("auth/user")
    suspend fun updateUser(@Body request: UpdateUserRequest): Response<UserDto>

    @PUT("auth/user/password")
    suspend fun changePassword(@Body request: ChangePasswordRequest): Response<Void>

    // === Profiles / Home Users ===

    @GET("api/v2/home/users")
    suspend fun getHomeUsers(): Response<HomeUsersResponse>

    @POST("api/v2/home/users/{uuid}/switch")
    suspend fun switchUser(
        @Path("uuid") userUuid: String,
        @Query("pin") pin: String? = null
    ): Response<SwitchUserResponse>

    // === Libraries (Plex-compatible) ===

    @GET("library/sections")
    suspend fun getLibraries(): Response<LibrarySectionsResponse>

    @GET("library/sections/{id}/all")
    suspend fun getAllLibraryMedia(
        @Path("id") libraryId: String,
        @Query("sort") sort: String? = null,
        @Query("type") type: Int? = null,
        @Query("X-Plex-Container-Start") start: Int? = null,
        @Query("X-Plex-Container-Size") size: Int? = null
    ): Response<MediaContainerResponse>

    @GET("library/sections/{id}/firstCharacter")
    suspend fun getLibraryFirstCharacter(@Path("id") libraryId: String): Response<MediaContainerResponse>

    @GET("library/metadata/{id}")
    suspend fun getMetadata(@Path("id") metadataId: String): Response<MediaContainerResponse>

    @GET("library/metadata/{id}/children")
    suspend fun getMetadataChildren(@Path("id") metadataId: String): Response<MediaContainerResponse>

    // === Home / Discover ===

    @GET("library/sections")
    suspend fun getHomeContent(): Response<LibrarySectionsResponse>

    // === Hubs (Recommendations) ===

    @GET("hubs/sections/{id}")
    suspend fun getLibraryHubs(@Path("id") libraryId: String): Response<HubsResponse>

    @GET("hubs/sections/{id}/streaming-services")
    suspend fun getLibraryStreamingServices(@Path("id") libraryId: String): Response<HubsResponse>

    @GET("hubs/home/streaming-services")
    suspend fun getAllStreamingServices(): Response<HubsResponse>

    // === Media ===

    @GET("media/{id}")
    suspend fun getMediaItem(@Path("id") mediaId: String): Response<MediaItemDto>

    @GET("media/{id}/children")
    suspend fun getMediaChildren(@Path("id") mediaId: String): Response<MediaListResponse>

    @GET("media/{id}/related")
    suspend fun getRelatedMedia(@Path("id") mediaId: String): Response<MediaListResponse>

    @GET("shows/{id}/seasons")
    suspend fun getShowSeasons(@Path("id") showId: String): Response<List<SeasonDto>>

    @GET("seasons/{id}/episodes")
    suspend fun getSeasonEpisodes(@Path("id") seasonId: String): Response<List<EpisodeDto>>

    // === Playback ===

    @GET("video/:/transcode/universal/start")
    suspend fun getPlaybackUrl(
        @Query("path") path: String,
        @Query("mediaIndex") mediaIndex: Int = 0,
        @Query("partIndex") partIndex: Int = 0,
        @Query("protocol") protocol: String = "hls",
        @Query("directPlay") directPlay: Boolean = true,
        @Query("directStream") directStream: Boolean = true
    ): Response<PlaybackResponse>

    @PUT(":/progress")
    suspend fun updateProgress(@Body request: ProgressUpdateRequest): Response<Void>

    // Mark content as watched (scrobble)
    @GET("scrobble")
    suspend fun scrobble(@Query("key") mediaId: String): Response<Void>

    // Mark content as unwatched (unscrobble)
    @GET("unscrobble")
    suspend fun unscrobble(@Query("key") mediaId: String): Response<Void>

    // Update playback timeline (progress with state)
    @POST("timeline")
    suspend fun updateTimeline(
        @Query("ratingKey") ratingKey: String,
        @Query("time") time: Long,
        @Query("duration") duration: Long? = null,
        @Query("state") state: String = "playing"
    ): Response<Void>

    // === Live TV ===

    @GET("livetv/channels")
    suspend fun getLiveTVChannels(): Response<ChannelsResponse>

    @GET("livetv/guide")
    suspend fun getLiveTVGuide(
        @Query("start") start: Long? = null,
        @Query("end") end: Long? = null
    ): Response<GuideResponse>

    @GET("livetv/epg")
    suspend fun getEPG(
        @Query("channels") channelIds: String? = null,
        @Query("start") start: Long? = null,
        @Query("end") end: Long? = null
    ): Response<EPGResponse>

    @GET("livetv/channels/{id}/stream")
    suspend fun getChannelStreamUrl(@Path("id") channelId: String): Response<StreamResponse>

    @PATCH("livetv/channels/{id}")
    suspend fun updateChannel(
        @Path("id") channelId: String,
        @Body request: UpdateChannelRequest
    ): Response<ChannelDto>

    // === Time-Shift / Catch-Up TV ===

    @GET("livetv/channels/{id}/catchup")
    suspend fun getCatchUpPrograms(@Path("id") channelId: String): Response<CatchUpResponse>

    @GET("livetv/channels/{id}/startover")
    suspend fun getStartOverInfo(@Path("id") channelId: String): Response<StartOverInfoDto>

    @GET("livetv/timeshift/{id}/stream.m3u8")
    suspend fun getTimeshiftStream(
        @Path("id") channelId: String,
        @Query("start") startOffset: Int? = null  // seconds to offset from live
    ): Response<okhttp3.ResponseBody>

    @POST("livetv/timeshift/{id}/start")
    suspend fun startTimeshiftBuffer(@Path("id") channelId: String): Response<TimeshiftBufferResponse>

    @POST("livetv/timeshift/{id}/stop")
    suspend fun stopTimeshiftBuffer(@Path("id") channelId: String): Response<TimeshiftBufferResponse>

    // === Archive / Catch-up (Server-side Recording) ===

    @GET("livetv/channels/{id}/archive")
    suspend fun getArchivedPrograms(
        @Path("id") channelId: String,
        @Query("limit") limit: Int? = null
    ): Response<ArchivedProgramsResponse>

    @POST("livetv/channels/{id}/archive/enable")
    suspend fun enableChannelArchive(
        @Path("id") channelId: String,
        @Body request: EnableArchiveRequest
    ): Response<EnableArchiveResponse>

    @POST("livetv/channels/{id}/archive/disable")
    suspend fun disableChannelArchive(@Path("id") channelId: String): Response<DisableArchiveResponse>

    @GET("livetv/archive/status")
    suspend fun getArchiveStatus(): Response<ArchiveStatusResponse>

    // === M3U Sources ===

    @GET("livetv/sources")
    suspend fun getM3USources(): Response<M3USourcesResponse>

    @POST("livetv/sources")
    suspend fun createM3USource(@Body request: CreateM3USourceRequest): Response<M3USourceDto>

    @PUT("livetv/sources/{id}")
    suspend fun updateM3USource(
        @Path("id") id: Int,
        @Body request: UpdateM3USourceRequest
    ): Response<M3USourceDto>

    @DELETE("livetv/sources/{id}")
    suspend fun deleteM3USource(@Path("id") id: Int): Response<Void>

    @POST("livetv/sources/{id}/refresh")
    suspend fun refreshM3USource(@Path("id") id: Int): Response<Void>

    @POST("livetv/sources/{id}/import-vod")
    suspend fun importM3UVOD(@Path("id") id: Int): Response<ImportResultDto>

    @POST("livetv/sources/{id}/import-series")
    suspend fun importM3USeries(@Path("id") id: Int): Response<ImportStatusDto>

    // === Xtream Sources ===

    @GET("livetv/xtream/sources")
    suspend fun getXtreamSources(): Response<XtreamSourcesResponse>

    @GET("livetv/xtream/sources/{id}")
    suspend fun getXtreamSource(@Path("id") id: Int): Response<XtreamSourceDto>

    @POST("livetv/xtream/sources")
    suspend fun createXtreamSource(@Body request: CreateXtreamSourceRequest): Response<XtreamSourceDto>

    @PUT("livetv/xtream/sources/{id}")
    suspend fun updateXtreamSource(
        @Path("id") id: Int,
        @Body request: UpdateXtreamSourceRequest
    ): Response<XtreamSourceDto>

    @DELETE("livetv/xtream/sources/{id}")
    suspend fun deleteXtreamSource(@Path("id") id: Int): Response<Void>

    @POST("livetv/xtream/sources/{id}/test")
    suspend fun testXtreamSource(@Path("id") id: Int): Response<TestSourceResponse>

    @POST("livetv/xtream/sources/{id}/refresh")
    suspend fun refreshXtreamSource(@Path("id") id: Int): Response<Void>

    @POST("livetv/xtream/sources/{id}/import-vod")
    suspend fun importXtreamVOD(@Path("id") id: Int): Response<ImportResultDto>

    @POST("livetv/xtream/sources/{id}/import-series")
    suspend fun importXtreamSeries(@Path("id") id: Int): Response<ImportResultDto>

    // === Channel Groups (Failover) ===

    @GET("livetv/channel-groups")
    suspend fun getChannelGroups(): Response<ChannelGroupsResponse>

    @POST("livetv/channel-groups")
    suspend fun createChannelGroup(@Body request: CreateChannelGroupRequest): Response<ChannelGroupDto>

    @PUT("livetv/channel-groups/{id}")
    suspend fun updateChannelGroup(
        @Path("id") groupId: Int,
        @Body request: UpdateChannelGroupRequest
    ): Response<ChannelGroupDto>

    @DELETE("livetv/channel-groups/{id}")
    suspend fun deleteChannelGroup(@Path("id") groupId: Int): Response<Void>

    @POST("livetv/channel-groups/{id}/members")
    suspend fun addChannelToGroup(
        @Path("id") groupId: Int,
        @Body request: AddGroupMemberRequest
    ): Response<ChannelGroupMemberDto>

    @PUT("livetv/channel-groups/{id}/members/{channelId}")
    suspend fun updateGroupMemberPriority(
        @Path("id") groupId: Int,
        @Path("channelId") channelId: Int,
        @Body request: UpdateGroupMemberPriorityRequest
    ): Response<ChannelGroupMemberDto>

    @DELETE("livetv/channel-groups/{id}/members/{channelId}")
    suspend fun removeChannelFromGroup(
        @Path("id") groupId: Int,
        @Path("channelId") channelId: Int
    ): Response<Void>

    @POST("livetv/channel-groups/auto-detect")
    suspend fun autoDetectDuplicates(): Response<AutoDetectDuplicatesResponse>

    @GET("livetv/channel-groups/{id}/stream")
    suspend fun getChannelGroupStreamUrl(@Path("id") groupId: Int): Response<StreamResponse>

    // === DVR ===

    @GET("dvr/recordings")
    suspend fun getDVRRecordings(): Response<RecordingsResponse>

    @GET("dvr/scheduled")
    suspend fun getScheduledRecordings(): Response<ScheduledRecordingsResponse>

    @POST("dvr/record")
    suspend fun scheduleRecording(@Body request: RecordRequest): Response<RecordingDto>

    @DELETE("dvr/recordings/{id}")
    suspend fun deleteRecording(@Path("id") recordingId: String): Response<Void>

    @GET("dvr/stream/{id}")
    suspend fun getRecordingStreamUrl(@Path("id") recordingId: String): Response<StreamResponse>

    @GET("dvr/conflicts")
    suspend fun getRecordingConflicts(): Response<ConflictsResponse>

    @POST("dvr/conflicts/resolve")
    suspend fun resolveConflict(@Body request: ResolveConflictRequest): Response<Void>

    @GET("dvr/recordings/stats")
    suspend fun getRecordingStats(): Response<RecordingStatsResponse>

    @PUT("dvr/recordings/{id}/progress")
    suspend fun updateRecordingProgress(
        @Path("id") recordingId: String,
        @Body request: UpdateRecordingProgressRequest
    ): Response<Void>

    @POST("dvr/recordings/from-program")
    suspend fun recordFromProgram(@Body request: RecordFromProgramRequest): Response<RecordFromProgramResponse>

    // Series Rules
    @GET("dvr/rules")
    suspend fun getSeriesRules(): Response<SeriesRulesResponse>

    @POST("dvr/rules")
    suspend fun createSeriesRule(@Body request: CreateSeriesRuleRequest): Response<SeriesRuleDto>

    @PUT("dvr/rules/{id}")
    suspend fun updateSeriesRule(
        @Path("id") ruleId: Long,
        @Body request: UpdateSeriesRuleRequest
    ): Response<SeriesRuleDto>

    @DELETE("dvr/rules/{id}")
    suspend fun deleteSeriesRule(@Path("id") ruleId: Long): Response<Void>

    // Disk Usage
    @GET("dvr/disk-usage")
    suspend fun getDiskUsage(): Response<DiskUsageResponse>

    // === Search ===

    @GET("hubs/search")
    suspend fun globalSearch(
        @Query("query") query: String,
        @Query("limit") limit: Int = 50
    ): Response<SearchResponse>

    // === Playlists ===

    @GET("playlists")
    suspend fun getPlaylists(): Response<PlaylistsResponse>

    @GET("playlists/{id}")
    suspend fun getPlaylist(@Path("id") playlistId: String): Response<PlaylistsResponse>

    @GET("playlists/{id}/items")
    suspend fun getPlaylistItems(@Path("id") playlistId: String): Response<MediaContainerResponse>

    // === Watchlist ===

    @GET("watchlist")
    suspend fun getWatchlist(): Response<MediaContainerResponse>

    @POST("watchlist/{mediaId}")
    suspend fun addToWatchlist(@Path("mediaId") mediaId: String): Response<Void>

    @DELETE("watchlist/{mediaId}")
    suspend fun removeFromWatchlist(@Path("mediaId") mediaId: String): Response<Void>

    // === Client Logs ===

    @POST("api/client-logs")
    suspend fun submitClientLogs(@Body logs: List<ClientLogEntry>): Response<Void>

    @GET("api/client-logs")
    suspend fun getClientLogs(): Response<List<ClientLogEntry>>

    // === Server Info ===

    @GET("server/info")
    suspend fun getServerInfo(): Response<ServerInfoDto>

    @GET("server/capabilities")
    suspend fun getServerCapabilities(): Response<ServerCapabilitiesDto>

    @GET("api/client/settings")
    suspend fun getServerSettings(): Response<ServerSettingsResponse>

    // === On Later (Browse upcoming content) ===

    @GET("api/onlater/stats")
    suspend fun getOnLaterStats(): Response<OnLaterStatsDto>

    @GET("api/onlater/movies")
    suspend fun getOnLaterMovies(
        @Query("hours") hours: Int? = null
    ): Response<OnLaterResponse>

    @GET("api/onlater/sports")
    suspend fun getOnLaterSports(
        @Query("hours") hours: Int? = null,
        @Query("league") league: String? = null,
        @Query("team") team: String? = null
    ): Response<OnLaterResponse>

    @GET("api/onlater/kids")
    suspend fun getOnLaterKids(
        @Query("hours") hours: Int? = null
    ): Response<OnLaterResponse>

    @GET("api/onlater/news")
    suspend fun getOnLaterNews(
        @Query("hours") hours: Int? = null
    ): Response<OnLaterResponse>

    @GET("api/onlater/premieres")
    suspend fun getOnLaterPremieres(
        @Query("hours") hours: Int? = null
    ): Response<OnLaterResponse>

    @GET("api/onlater/tonight")
    suspend fun getOnLaterTonight(): Response<OnLaterResponse>

    @GET("api/onlater/week")
    suspend fun getOnLaterWeek(
        @Query("category") category: String? = null
    ): Response<OnLaterResponse>

    @GET("api/onlater/search")
    suspend fun searchOnLater(
        @Query("q") query: String
    ): Response<OnLaterResponse>

    @GET("api/onlater/leagues")
    suspend fun getOnLaterLeagues(): Response<LeaguesResponse>

    // === Team Pass ===

    @GET("api/teampass")
    suspend fun getTeamPasses(): Response<TeamPassListResponse>

    @GET("api/teampass/{id}")
    suspend fun getTeamPass(@Path("id") id: Long): Response<TeamPassWithGamesResponse>

    @POST("api/teampass")
    suspend fun createTeamPass(@Body request: TeamPassRequest): Response<TeamPassDto>

    @PUT("api/teampass/{id}")
    suspend fun updateTeamPass(
        @Path("id") id: Long,
        @Body request: TeamPassRequest
    ): Response<TeamPassDto>

    @DELETE("api/teampass/{id}")
    suspend fun deleteTeamPass(@Path("id") id: Long): Response<Void>

    @GET("api/teampass/{id}/upcoming")
    suspend fun getTeamPassUpcoming(@Path("id") id: Long): Response<TeamPassWithGamesResponse>

    @PUT("api/teampass/{id}/toggle")
    suspend fun toggleTeamPass(@Path("id") id: Long): Response<TeamPassDto>

    @GET("api/teampass/stats")
    suspend fun getTeamPassStats(): Response<TeamPassStatsDto>

    @GET("api/teampass/teams/search")
    suspend fun searchSportsTeams(@Query("q") query: String): Response<TeamsSearchResponse>

    @GET("api/teampass/leagues")
    suspend fun getSportsLeagues(): Response<SportsLeaguesResponse>

    @GET("api/teampass/leagues/{league}/teams")
    suspend fun getLeagueTeams(@Path("league") league: String): Response<LeagueTeamsResponse>

    @POST("api/teampass/process")
    suspend fun processTeamPasses(): Response<Void>

    // === Sports Scores ===

    @GET("api/sports/scores")
    suspend fun getSportsScores(
        @Query("league") league: String? = null,
        @Query("team") team: String? = null
    ): Response<SportsScoresResponse>

    @GET("api/sports/overlay/{channelId}")
    suspend fun getSportsOverlay(@Path("channelId") channelId: String): Response<SportsOverlayDto>

    @PUT("api/sports/favorites")
    suspend fun setSportsFavorites(@Body request: SportsFavoritesRequest): Response<Void>

    // === Commercial Skip ===

    @GET("api/commercials/{mediaId}")
    suspend fun getCommercials(@Path("mediaId") mediaId: String): Response<CommercialsResponse>

    @GET("api/commercials/{mediaId}/check")
    suspend fun checkCommercialPosition(
        @Path("mediaId") mediaId: String,
        @Query("position") positionMs: Long
    ): Response<CommercialCheckResponse>

    @POST("api/commercials/{mediaId}/detect")
    suspend fun detectCommercials(@Path("mediaId") mediaId: String): Response<CommercialsResponse>

    @POST("api/commercials/{mediaId}/mark")
    suspend fun markCommercial(
        @Path("mediaId") mediaId: String,
        @Body request: MarkCommercialRequest
    ): Response<CommercialDto>

    @DELETE("api/commercials/{mediaId}/{commercialId}")
    suspend fun unmarkCommercial(
        @Path("mediaId") mediaId: String,
        @Path("commercialId") commercialId: String
    ): Response<Void>

    // === Remote Access ===

    @GET("api/remote/connection")
    suspend fun getConnectionInfo(): Response<ConnectionInfoDto>

    @GET("api/remote/status")
    suspend fun getRemoteAccessStatus(): Response<RemoteAccessStatusDto>

    @POST("api/remote/enable")
    suspend fun enableRemoteAccess(): Response<RemoteAccessStatusDto>

    @POST("api/remote/disable")
    suspend fun disableRemoteAccess(): Response<Void>

    @GET("api/remote/health")
    suspend fun getRemoteAccessHealth(): Response<RemoteAccessHealthDto>

    @GET("api/remote/install-info")
    suspend fun getRemoteAccessInstallInfo(): Response<RemoteAccessInstallInfoDto>

    @GET("api/remote/login-url")
    suspend fun getRemoteAccessLoginUrl(): Response<RemoteAccessLoginUrlDto>

    @GET("api/remote/streaming-quality")
    suspend fun remoteStreamingQuality(): Response<RemoteStreamingQualityDto>

    @PUT("api/remote/streaming-quality")
    suspend fun setRemoteStreamingQuality(@Body request: SetStreamingQualityRequest): Response<Void>
}
