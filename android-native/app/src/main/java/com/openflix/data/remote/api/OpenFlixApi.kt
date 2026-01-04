package com.openflix.data.remote.api

import com.openflix.data.remote.dto.*
import retrofit2.Response
import retrofit2.http.*

/**
 * OpenFlix Server API interface.
 * Matches the Go backend endpoints.
 */
interface OpenFlixApi {

    // === Authentication ===

    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): Response<AuthResponse>

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): Response<AuthResponse>

    @POST("auth/logout")
    suspend fun logout(): Response<Unit>

    @GET("auth/user")
    suspend fun getCurrentUser(): Response<UserDto>

    @PUT("auth/user")
    suspend fun updateUser(@Body request: UpdateUserRequest): Response<UserDto>

    @PUT("auth/user/password")
    suspend fun changePassword(@Body request: ChangePasswordRequest): Response<Unit>

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
    suspend fun updateProgress(@Body request: ProgressUpdateRequest): Response<Unit>

    @DELETE(":/unscrobble")
    suspend fun unscrobble(@Query("key") mediaId: String): Response<Unit>

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

    // === DVR ===

    @GET("dvr/recordings")
    suspend fun getDVRRecordings(): Response<RecordingsResponse>

    @GET("dvr/scheduled")
    suspend fun getScheduledRecordings(): Response<ScheduledRecordingsResponse>

    @POST("dvr/record")
    suspend fun scheduleRecording(@Body request: RecordRequest): Response<RecordingDto>

    @DELETE("dvr/recordings/{id}")
    suspend fun deleteRecording(@Path("id") recordingId: String): Response<Unit>

    @GET("dvr/recordings/{id}/stream")
    suspend fun getRecordingStreamUrl(@Path("id") recordingId: String): Response<StreamResponse>

    // === Search ===

    @GET("search")
    suspend fun globalSearch(
        @Query("query") query: String,
        @Query("limit") limit: Int = 50
    ): Response<SearchResponse>

    // === Playlists ===

    @GET("playlists")
    suspend fun getPlaylists(): Response<List<PlaylistDto>>

    @GET("playlists/{id}")
    suspend fun getPlaylist(@Path("id") playlistId: String): Response<PlaylistDto>

    @GET("playlists/{id}/items")
    suspend fun getPlaylistItems(@Path("id") playlistId: String): Response<MediaListResponse>

    // === Watchlist ===

    @GET("watchlist")
    suspend fun getWatchlist(): Response<MediaListResponse>

    @POST("watchlist/{mediaId}")
    suspend fun addToWatchlist(@Path("mediaId") mediaId: String): Response<Unit>

    @DELETE("watchlist/{mediaId}")
    suspend fun removeFromWatchlist(@Path("mediaId") mediaId: String): Response<Unit>

    // === Client Logs ===

    @POST("api/client-logs")
    suspend fun submitClientLogs(@Body logs: List<ClientLogEntry>): Response<Unit>

    @GET("api/client-logs")
    suspend fun getClientLogs(): Response<List<ClientLogEntry>>

    // === Server Info ===

    @GET("server/info")
    suspend fun getServerInfo(): Response<ServerInfoDto>

    @GET("server/capabilities")
    suspend fun getServerCapabilities(): Response<ServerCapabilitiesDto>
}
