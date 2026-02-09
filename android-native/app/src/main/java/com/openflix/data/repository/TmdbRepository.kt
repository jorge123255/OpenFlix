package com.openflix.data.repository

import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.TmdbApi
import com.openflix.data.remote.dto.TmdbVideoDto
import com.openflix.domain.model.TrailerInfo
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for TMDB API operations.
 * Handles fetching trailers, metadata enrichment, and caching.
 */
@Singleton
class TmdbRepository @Inject constructor(
    private val tmdbApi: TmdbApi,
    private val preferencesManager: PreferencesManager
) {
    // In-memory cache for trailers (mediaId -> TrailerInfo)
    private val trailerCache = mutableMapOf<String, TrailerInfo?>()
    private val cacheMutex = Mutex()

    // In-memory cache for TMDB IDs (mediaId -> tmdbId)
    private val tmdbIdCache = mutableMapOf<String, Int?>()

    companion object {
        private const val TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p/"
        private const val BACKDROP_SIZE = "w1280"
        private const val POSTER_SIZE = "w500"
    }

    /**
     * Get trailer for a movie by its TMDB ID or Plex GUID
     */
    suspend fun getMovieTrailer(
        mediaId: String,
        tmdbId: Int? = null,
        plexGuid: String? = null,
        title: String? = null,
        year: Int? = null
    ): TrailerInfo? {
        // Check cache first
        cacheMutex.withLock {
            if (trailerCache.containsKey(mediaId)) {
                return trailerCache[mediaId]
            }
        }

        val apiKey = getApiKey() ?: run {
            Timber.w("TMDB API key not configured")
            return null
        }

        // Resolve TMDB ID
        val resolvedTmdbId = tmdbId
            ?: extractTmdbIdFromGuid(plexGuid)
            ?: searchForTmdbId(apiKey, title, year, isMovie = true)

        if (resolvedTmdbId == null) {
            Timber.d("Could not resolve TMDB ID for: $title")
            cacheMutex.withLock { trailerCache[mediaId] = null }
            return null
        }

        return try {
            val response = tmdbApi.getMovieVideos(resolvedTmdbId, apiKey)
            if (response.isSuccessful && response.body() != null) {
                val trailer = findBestTrailer(response.body()!!.results)
                val trailerInfo = trailer?.let { video ->
                    TrailerInfo(
                        youtubeKey = video.key,
                        name = video.name,
                        type = video.type,
                        isOfficial = video.official ?: false
                    )
                }
                cacheMutex.withLock { trailerCache[mediaId] = trailerInfo }
                trailerInfo
            } else {
                Timber.w("Failed to fetch movie videos: ${response.code()}")
                cacheMutex.withLock { trailerCache[mediaId] = null }
                null
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching movie trailer")
            cacheMutex.withLock { trailerCache[mediaId] = null }
            null
        }
    }

    /**
     * Get trailer for a TV show by its TMDB ID or Plex GUID
     */
    suspend fun getTVTrailer(
        mediaId: String,
        tmdbId: Int? = null,
        plexGuid: String? = null,
        title: String? = null,
        year: Int? = null
    ): TrailerInfo? {
        // Check cache first
        cacheMutex.withLock {
            if (trailerCache.containsKey(mediaId)) {
                return trailerCache[mediaId]
            }
        }

        val apiKey = getApiKey() ?: run {
            Timber.w("TMDB API key not configured")
            return null
        }

        // Resolve TMDB ID
        val resolvedTmdbId = tmdbId
            ?: extractTmdbIdFromGuid(plexGuid)
            ?: searchForTmdbId(apiKey, title, year, isMovie = false)

        if (resolvedTmdbId == null) {
            Timber.d("Could not resolve TMDB ID for TV show: $title")
            cacheMutex.withLock { trailerCache[mediaId] = null }
            return null
        }

        return try {
            val response = tmdbApi.getTVVideos(resolvedTmdbId, apiKey)
            if (response.isSuccessful && response.body() != null) {
                val trailer = findBestTrailer(response.body()!!.results)
                val trailerInfo = trailer?.let { video ->
                    TrailerInfo(
                        youtubeKey = video.key,
                        name = video.name,
                        type = video.type,
                        isOfficial = video.official ?: false
                    )
                }
                cacheMutex.withLock { trailerCache[mediaId] = trailerInfo }
                trailerInfo
            } else {
                Timber.w("Failed to fetch TV videos: ${response.code()}")
                cacheMutex.withLock { trailerCache[mediaId] = null }
                null
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching TV trailer")
            cacheMutex.withLock { trailerCache[mediaId] = null }
            null
        }
    }

    /**
     * Get TMDB backdrop URL for a movie/show
     */
    suspend fun getBackdropUrl(
        tmdbId: Int? = null,
        plexGuid: String? = null,
        title: String? = null,
        year: Int? = null,
        isMovie: Boolean = true
    ): String? {
        val apiKey = getApiKey() ?: return null

        val resolvedTmdbId = tmdbId
            ?: extractTmdbIdFromGuid(plexGuid)
            ?: searchForTmdbId(apiKey, title, year, isMovie)
            ?: return null

        return try {
            if (isMovie) {
                val response = tmdbApi.getMovieDetails(resolvedTmdbId, apiKey)
                if (response.isSuccessful) {
                    response.body()?.backdropPath?.let { "$TMDB_IMAGE_BASE_URL$BACKDROP_SIZE$it" }
                } else null
            } else {
                val response = tmdbApi.getTVDetails(resolvedTmdbId, apiKey)
                if (response.isSuccessful) {
                    response.body()?.backdropPath?.let { "$TMDB_IMAGE_BASE_URL$BACKDROP_SIZE$it" }
                } else null
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching backdrop")
            null
        }
    }

    /**
     * Extract TMDB ID from Plex GUID format.
     * Supports formats like:
     * - tmdb://12345
     * - com.plexapp.agents.themoviedb://12345
     * - plex://movie/5d776bc4705e5b001e3e0c3d (requires lookup)
     */
    private fun extractTmdbIdFromGuid(guid: String?): Int? {
        if (guid == null) return null

        // Direct TMDB reference: tmdb://12345
        if (guid.startsWith("tmdb://")) {
            return guid.removePrefix("tmdb://").split("?").firstOrNull()?.toIntOrNull()
        }

        // Legacy Plex TMDB agent: com.plexapp.agents.themoviedb://12345
        if (guid.contains("themoviedb://")) {
            val match = Regex("themoviedb://([0-9]+)").find(guid)
            return match?.groupValues?.get(1)?.toIntOrNull()
        }

        // TVDB format - would need separate handling
        if (guid.contains("thetvdb://") || guid.startsWith("tvdb://")) {
            Timber.d("TVDB GUID detected, TMDB lookup would be needed: $guid")
            return null
        }

        return null
    }

    /**
     * Search TMDB for a movie/show by title and year
     */
    private suspend fun searchForTmdbId(
        apiKey: String,
        title: String?,
        year: Int?,
        isMovie: Boolean
    ): Int? {
        if (title.isNullOrBlank()) return null

        // Check ID cache
        val cacheKey = "$title|$year|$isMovie"
        tmdbIdCache[cacheKey]?.let { return it }

        return try {
            if (isMovie) {
                val response = tmdbApi.searchMovie(apiKey, title, year)
                if (response.isSuccessful) {
                    val id = response.body()?.results?.firstOrNull()?.id
                    tmdbIdCache[cacheKey] = id
                    id
                } else null
            } else {
                val response = tmdbApi.searchTV(apiKey, title, year)
                if (response.isSuccessful) {
                    val id = response.body()?.results?.firstOrNull()?.id
                    tmdbIdCache[cacheKey] = id
                    id
                } else null
            }
        } catch (e: Exception) {
            Timber.e(e, "Error searching TMDB")
            null
        }
    }

    /**
     * Find the best trailer from a list of videos.
     * Prefers: official trailers > trailers > teasers > other
     * Filters to YouTube only
     */
    private fun findBestTrailer(videos: List<TmdbVideoDto>): TmdbVideoDto? {
        // Only consider YouTube videos
        val youtubeVideos = videos.filter { it.site.equals("YouTube", ignoreCase = true) }

        if (youtubeVideos.isEmpty()) return null

        // Priority: Official Trailer > Trailer > Teaser > Clip > Featurette
        val priority = listOf("Trailer", "Teaser", "Clip", "Featurette")

        // First, try to find official trailers
        for (type in priority) {
            val official = youtubeVideos.find {
                it.type.equals(type, ignoreCase = true) && it.official == true
            }
            if (official != null) return official
        }

        // Then try any trailer
        for (type in priority) {
            val video = youtubeVideos.find { it.type.equals(type, ignoreCase = true) }
            if (video != null) return video
        }

        // Fallback to first available
        return youtubeVideos.firstOrNull()
    }

    /**
     * Get the TMDB API key from preferences
     */
    private suspend fun getApiKey(): String? {
        return preferencesManager.tmdbApiKey.first()?.takeIf { it.isNotBlank() }
    }

    /**
     * Clear all caches
     */
    suspend fun clearCache() {
        cacheMutex.withLock {
            trailerCache.clear()
            tmdbIdCache.clear()
        }
    }

    /**
     * Build full TMDB image URL
     */
    fun buildImageUrl(path: String?, size: String = BACKDROP_SIZE): String? {
        return path?.let { "$TMDB_IMAGE_BASE_URL$size$it" }
    }
}
