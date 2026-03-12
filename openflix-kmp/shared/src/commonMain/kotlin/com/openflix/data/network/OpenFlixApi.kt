package com.openflix.data.network

import com.openflix.data.dto.*
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

class OpenFlixApi {
    @PublishedApi internal var baseUrl: String? = null
    @PublishedApi internal var authToken: String? = null

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        coerceInputValues = true
        encodeDefaults = false
    }

    @PublishedApi internal val client = HttpClient {
        install(ContentNegotiation) {
            json(this@OpenFlixApi.json)
        }
        install(Logging) {
            level = LogLevel.HEADERS
            logger = Logger.SIMPLE
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 15_000
            connectTimeoutMillis = 10_000
        }
        defaultRequest {
            contentType(ContentType.Application.Json)
            accept(ContentType.Application.Json)
            header("User-Agent", "OpenFlix-KMP/1.0")
        }
    }

    fun configure(serverUrl: String, token: String?) {
        var url = serverUrl.trim().trimEnd('/')
        // Normalize: if user types just IP:port or IP, add http://
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            url = "http://$url"
        }
        this.baseUrl = url
        this.authToken = token
    }

    fun setToken(token: String?) {
        this.authToken = token
    }

    val isConfigured: Boolean get() = baseUrl != null
    val hasToken: Boolean get() = authToken != null

    // MARK: - Generic request methods

    suspend inline fun <reified T> get(path: String, queryParams: Map<String, String> = emptyMap()): T {
        return request(HttpMethod.Get, path, queryParams)
    }

    suspend inline fun <reified T> post(path: String, body: Any? = null): T {
        return request(HttpMethod.Post, path, body = body)
    }

    suspend inline fun <reified T> put(path: String, body: Any? = null): T {
        return request(HttpMethod.Put, path, body = body)
    }

    suspend fun delete(path: String) {
        requestVoid(HttpMethod.Delete, path)
    }

    suspend fun postVoid(path: String, body: Any? = null) {
        requestVoid(HttpMethod.Post, path, body = body)
    }

    suspend fun putVoid(path: String, body: Any? = null) {
        requestVoid(HttpMethod.Put, path, body = body)
    }

    suspend inline fun <reified T> request(
        method: HttpMethod,
        path: String,
        queryParams: Map<String, String> = emptyMap(),
        body: Any? = null
    ): T {
        val base = baseUrl ?: throw NetworkError.InvalidURL
        val response = client.request("$base$path") {
            this.method = method
            authToken?.let { header("Authorization", "Bearer $it") }
            queryParams.forEach { (key, value) -> parameter(key, value) }
            if (body != null) {
                setBody(body)
            }
        }
        return handleResponse(response)
    }

    suspend fun requestVoid(
        method: HttpMethod,
        path: String,
        queryParams: Map<String, String> = emptyMap(),
        body: Any? = null
    ) {
        val base = baseUrl ?: throw NetworkError.InvalidURL
        val response = client.request("$base$path") {
            this.method = method
            authToken?.let { header("Authorization", "Bearer $it") }
            queryParams.forEach { (key, value) -> parameter(key, value) }
            if (body != null) {
                setBody(body)
            }
        }
        handleVoidResponse(response)
    }

    @PublishedApi
    internal suspend inline fun <reified T> handleResponse(response: HttpResponse): T {
        when (response.status.value) {
            in 200..299 -> {
                return try {
                    response.body<T>()
                } catch (e: Exception) {
                    throw NetworkError.DecodingError(e)
                }
            }
            401 -> throw NetworkError.Unauthorized
            404 -> throw NetworkError.NotFound
            429 -> throw NetworkError.RateLimited
            else -> {
                val body = try { response.bodyAsText() } catch (_: Exception) { null }
                throw NetworkError.ServerError(response.status.value, body)
            }
        }
    }

    internal suspend fun handleVoidResponse(response: HttpResponse) {
        when (response.status.value) {
            in 200..299 -> return
            401 -> throw NetworkError.Unauthorized
            404 -> throw NetworkError.NotFound
            429 -> throw NetworkError.RateLimited
            else -> {
                val body = try { response.bodyAsText() } catch (_: Exception) { null }
                throw NetworkError.ServerError(response.status.value, body)
            }
        }
    }

    // MARK: - Auth
    suspend fun login(username: String, password: String): AuthResponse =
        post("/auth/login", mapOf("username" to username, "password" to password))

    suspend fun logout() = postVoid("/auth/logout")

    suspend fun getUser(): UserDTO = get("/auth/user")

    // MARK: - Profiles
    suspend fun getProfiles(): List<ProfileDTO> = get("/profiles")

    suspend fun getHomeUsers(): HomeUsersResponse = get("/api/v2/home/users")

    suspend fun switchProfile(uuid: String, pin: String?): SwitchProfileResponse =
        post("/api/v2/home/users/$uuid/switch", pin?.let { mapOf("pin" to it) })

    // MARK: - Library
    suspend fun getLibrarySections(): LibrarySectionsResponse = get("/library/sections")

    suspend fun getLibraryItems(
        sectionId: Int, start: Int? = null, size: Int? = null,
        sort: String? = null, filters: Map<String, String>? = null
    ): MediaContainerResponse {
        val params = buildMap {
            put("includeElements", "Genre")
            start?.let { put("X-Plex-Container-Start", it.toString()) }
            size?.let { put("X-Plex-Container-Size", it.toString()) }
            sort?.let { put("sort", it) }
            filters?.forEach { (k, v) -> put(k, v) }
        }
        return get("/library/sections/$sectionId/all", params)
    }

    suspend fun getMediaDetails(key: Int): MediaContainerResponse = get("/library/metadata/$key")

    suspend fun getMediaChildren(key: Int): MediaContainerResponse = get("/library/metadata/$key/children")

    suspend fun getRecentlyAdded(): MediaContainerResponse = get("/library/recentlyAdded")

    suspend fun getOnDeck(): MediaContainerResponse = get("/library/onDeck")

    // MARK: - Hubs
    suspend fun getHubs(sectionId: Int): HubsResponse = get("/hubs/sections/$sectionId")

    // MARK: - Search
    suspend fun search(query: String, limit: Int? = 50): SearchResponse =
        get("/hubs/search", buildMap {
            put("query", query)
            limit?.let { put("limit", it.toString()) }
        })

    // MARK: - Playback

    /**
     * Stream info returned by [getStreamInfo].
     */
    data class StreamInfo(val url: String, val container: String?)

    /**
     * Get stream info for a media item by its metadata key.
     * Returns the direct stream URL and container format.
     */
    suspend fun getStreamInfo(metadataKey: Int): StreamInfo {
        val response: MediaContainerResponse = get("/library/metadata/$metadataKey")
        val item = response.MediaContainer?.Metadata?.firstOrNull()
            ?: throw NetworkError.NotFound
        val base = baseUrl ?: throw NetworkError.InvalidURL

        val container = item.Media?.firstOrNull()?.container

        // 1. Try local media file (Part key)
        val partKey = item.Media?.firstOrNull()?.Part?.firstOrNull()?.key
        if (partKey != null) {
            return StreamInfo("$base$partKey", container)
        }

        // 2. Fall back to external stream URL (M3U/Xtream VOD)
        val stream = item.streamUrl
        if (!stream.isNullOrEmpty()) {
            return StreamInfo(stream, container)
        }

        throw NetworkError.NotFound
    }

    /**
     * Get direct stream URL for a media item by its metadata key.
     */
    suspend fun getStreamUrl(metadataKey: Int): String = getStreamInfo(metadataKey).url

    /**
     * Build an HLS transcode URL for a media item.
     * Used when the client can't play the file directly (e.g., MKV on iOS).
     */
    fun getTranscodeUrl(metadataKey: Int): String {
        val base = baseUrl ?: throw NetworkError.InvalidURL
        val tokenParam = authToken?.let { "&X-Plex-Token=$it" } ?: ""
        return "$base/video/-/transcode/universal/start.m3u8?key=$metadataKey&videoQuality=original$tokenParam"
    }

    @Deprecated("Use getStreamUrl instead", replaceWith = ReplaceWith("getStreamUrl(metadataKey)"))
    suspend fun getPlaybackURL(path: String, directPlay: Boolean = true): PlaybackURLResponse =
        get("/video/:/transcode/universal/start", mapOf(
            "path" to path,
            "directPlay" to if (directPlay) "1" else "0",
            "directStream" to "1",
            "protocol" to "hls"
        ))

    suspend fun updateProgress(key: Int, time: Int, state: String? = null) =
        putVoid("/:/progress", buildMap<String, Any> {
            put("key", key)
            put("time", time)
            state?.let { put("state", it) }
        })

    suspend fun scrobble(key: Int) = postVoid("/scrobble?key=$key")
    suspend fun unscrobble(key: Int) = postVoid("/unscrobble?key=$key")

    // MARK: - Live TV
    suspend fun getChannels(): ChannelsResponse = get("/livetv/channels")

    suspend fun getChannelStream(id: String): ChannelStreamResponse = get("/livetv/channels/$id/stream")

    suspend fun getGuide(startSec: Long? = null, endSec: Long? = null): GuideResponse =
        get("/livetv/guide", buildMap {
            startSec?.let { put("start", it.toString()) }
            endSec?.let { put("end", it.toString()) }
        })

    suspend fun getNowPlaying(): NowPlayingResponse = get("/livetv/now")

    suspend fun toggleFavorite(channelId: String) = postVoid("/livetv/channels/$channelId/favorite")

    // MARK: - DVR
    suspend fun getRecordings(status: String? = null): RecordingsResponse =
        get("/dvr/recordings", buildMap { status?.let { put("status", it) } })

    suspend fun getRecording(id: Int): RecordingDTO = get("/dvr/recordings/$id")

    suspend fun scheduleRecording(channelId: String, startTime: String, endTime: String, title: String): RecordingDTO =
        post("/dvr/recordings", mapOf(
            "channelId" to channelId, "startTime" to startTime,
            "endTime" to endTime, "title" to title
        ))

    suspend fun recordFromProgram(channelId: String, programId: String): RecordingDTO =
        post("/dvr/recordings/from-program", mapOf("channelId" to channelId, "programId" to programId))

    suspend fun deleteRecording(id: Int) = delete("/dvr/recordings/$id")

    suspend fun getRecordingStream(id: Int): RecordingStreamResponse = get("/dvr/recordings/$id/stream")

    // MARK: - Sources
    suspend fun getM3USources(): M3USourcesResponse = get("/livetv/sources")
    suspend fun addM3USource(name: String, url: String, epgUrl: String? = null): M3USourceDTO =
        post("/livetv/sources", buildMap {
            put("name", name); put("url", url)
            epgUrl?.let { put("epgUrl", it) }
        })
    suspend fun deleteM3USource(id: Int) = delete("/livetv/sources/$id")

    suspend fun getXtreamSources(): XtreamSourcesResponse = get("/livetv/xtream/sources")
    suspend fun deleteXtreamSource(id: Int) = delete("/livetv/xtream/sources/$id")

    suspend fun getEPGSources(): EPGSourcesResponse = get("/livetv/epg/sources")
    suspend fun deleteEPGSource(id: Int) = delete("/livetv/epg/sources/$id")

    // MARK: - Watchlist
    suspend fun getWatchlist(): WatchlistResponse = get("/watchlist")
    suspend fun addToWatchlist(mediaId: Int) = postVoid("/watchlist/$mediaId")
    suspend fun removeFromWatchlist(mediaId: Int) = delete("/watchlist/$mediaId")

    // MARK: - Playlists
    suspend fun getPlaylists(): PlaylistsResponse = get("/playlists")
    suspend fun createPlaylist(name: String): PlaylistDTO = post("/playlists", mapOf("name" to name))
    suspend fun getPlaylistItems(id: Int): PlaylistItemsResponse = get("/playlists/$id/items")
    suspend fun addToPlaylist(id: Int, mediaIds: List<Int>) = postVoid("/playlists/$id/items", mapOf("mediaIds" to mediaIds))
    suspend fun deletePlaylist(id: Int) = delete("/playlists/$id")

    // MARK: - On Later
    suspend fun getOnLaterStats(): OnLaterStatsResponseDTO = get("/api/onlater/stats")
    suspend fun getOnLaterMovies(): OnLaterResponse = get("/api/onlater/movies")
    suspend fun getOnLaterSports(league: String? = null, team: String? = null): OnLaterResponse =
        get("/api/onlater/sports", buildMap {
            league?.let { put("league", it) }
            team?.let { put("team", it) }
        })

    // MARK: - Team Pass
    suspend fun getTeamPasses(): TeamPassesResponse = get("/api/teampass")
    suspend fun deleteTeamPass(id: Int) = delete("/api/teampass/$id")

    // MARK: - Server
    suspend fun getServerInfo(): ServerInfoDTO = get("/server/info")

    /**
     * Quick connection test — hits /identity which always returns 200 if server is reachable.
     * Returns true if server responds, false otherwise.
     */
    suspend fun testConnection(): Boolean {
        val base = baseUrl ?: return false
        return try {
            val response = client.request("$base/identity") {
                method = HttpMethod.Get
                accept(ContentType.Application.Json)
            }
            response.status.value in 200..299
        } catch (_: Exception) {
            false
        }
    }
    suspend fun getCapabilities(): ServerCapabilitiesDTO = get("/server/capabilities")

    // MARK: - Series Rules
    suspend fun getSeriesRules(): SeriesRulesResponse = get("/dvr/rules")
    suspend fun deleteSeriesRule(id: Int) = delete("/dvr/rules/$id")
}
