package com.openflix.data.repository

import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.dto.MediaItemDto
import com.openflix.data.remote.dto.PlaylistDto
import com.openflix.domain.model.*
import kotlinx.coroutines.flow.first
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for playlist operations.
 */
@Singleton
class PlaylistRepository @Inject constructor(
    private val api: OpenFlixApi,
    private val preferencesManager: PreferencesManager
) {

    private suspend fun getServerBaseUrl(): String {
        return preferencesManager.serverUrl.first() ?: "http://127.0.0.1:32400"
    }

    private fun buildFullUrl(baseUrl: String, path: String?): String? {
        if (path == null) return null
        if (path.startsWith("http://") || path.startsWith("https://")) {
            return path
        }
        return baseUrl.trimEnd('/') + path
    }

    /**
     * Get all user playlists
     */
    suspend fun getPlaylists(): Result<List<Playlist>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getPlaylists()
            if (response.isSuccessful && response.body() != null) {
                val playlistDtos = response.body()!!.mediaContainer?.metadata ?: emptyList()
                val playlists = playlistDtos.map { it.toDomain(baseUrl) }
                Timber.d("Loaded ${playlists.size} playlists")
                Result.success(playlists)
            } else {
                Timber.w("Failed to get playlists: ${response.code()}")
                Result.failure(Exception("Failed to get playlists: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting playlists")
            Result.failure(e)
        }
    }

    /**
     * Get a specific playlist by ID
     */
    suspend fun getPlaylist(playlistId: String): Result<Playlist> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getPlaylist(playlistId)
            if (response.isSuccessful && response.body() != null) {
                val playlistDto = response.body()!!.mediaContainer?.metadata?.firstOrNull()
                if (playlistDto != null) {
                    val playlist = playlistDto.toDomain(baseUrl)
                    Timber.d("Loaded playlist: ${playlist.title}")
                    Result.success(playlist)
                } else {
                    Result.failure(Exception("Playlist not found"))
                }
            } else {
                Timber.w("Failed to get playlist: ${response.code()}")
                Result.failure(Exception("Failed to get playlist: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting playlist: $playlistId")
            Result.failure(e)
        }
    }

    /**
     * Get items in a playlist
     */
    suspend fun getPlaylistItems(playlistId: String): Result<List<MediaItem>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getPlaylistItems(playlistId)
            if (response.isSuccessful && response.body() != null) {
                val mediaItems = response.body()!!.mediaContainer?.metadata ?: emptyList()
                val items = mediaItems.map { it.toDomain(baseUrl) }
                Timber.d("Loaded ${items.size} items from playlist $playlistId")
                Result.success(items)
            } else {
                Timber.w("Failed to get playlist items: ${response.code()}")
                Result.failure(Exception("Failed to get playlist items: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting playlist items: $playlistId")
            Result.failure(e)
        }
    }

    private fun PlaylistDto.toDomain(baseUrl: String) = Playlist(
        id = id,
        key = key,
        title = title,
        summary = summary,
        thumb = buildFullUrl(baseUrl, thumb),
        composite = buildFullUrl(baseUrl, composite),
        duration = duration,
        leafCount = leafCount,
        playlistType = playlistType,
        smart = smart,
        items = emptyList()
    )

    private fun MediaItemDto.toDomain(baseUrl: String) = MediaItem(
        id = id,
        key = key,
        ratingKey = ratingKey?.toString(),
        type = MediaType.fromString(type),
        title = title,
        originalTitle = originalTitle,
        tagline = tagline,
        summary = summary,
        thumb = buildFullUrl(baseUrl, thumb),
        art = buildFullUrl(baseUrl, art),
        banner = buildFullUrl(baseUrl, banner),
        year = year,
        duration = duration,
        viewOffset = viewOffset,
        viewCount = viewCount,
        addedAt = addedAt,
        contentRating = contentRating,
        rating = rating,
        audienceRating = audienceRating,
        studio = studio,
        genres = genres?.map { it.tag } ?: emptyList(),
        directors = directors?.map { it.tag } ?: emptyList(),
        writers = writers?.map { it.tag } ?: emptyList(),
        cast = roles?.map { CastMember(name = it.tag, role = it.role, thumb = buildFullUrl(baseUrl, it.thumb)) } ?: emptyList(),
        librarySectionId = librarySectionId?.toString(),
        librarySectionTitle = librarySectionTitle,
        parentRatingKey = parentRatingKey?.toString(),
        parentTitle = parentTitle,
        grandparentRatingKey = grandparentRatingKey?.toString(),
        grandparentTitle = grandparentTitle,
        grandparentThumb = buildFullUrl(baseUrl, grandparentThumb),
        grandparentArt = buildFullUrl(baseUrl, grandparentArt),
        index = index,
        parentIndex = parentIndex,
        leafCount = leafCount,
        viewedLeafCount = viewedLeafCount,
        childCount = childCount
    )
}
