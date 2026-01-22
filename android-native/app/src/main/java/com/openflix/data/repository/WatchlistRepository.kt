package com.openflix.data.repository

import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.dto.MediaItemDto
import com.openflix.domain.model.*
import kotlinx.coroutines.flow.first
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for watchlist operations.
 * Handles adding/removing items from user's watchlist.
 */
@Singleton
class WatchlistRepository @Inject constructor(
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
     * Get user's watchlist
     */
    suspend fun getWatchlist(): Result<List<MediaItem>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getWatchlist()
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain(baseUrl) }
                Timber.d("Loaded ${items.size} watchlist items")
                Result.success(items)
            } else {
                Timber.w("Failed to get watchlist: ${response.code()}")
                Result.failure(Exception("Failed to get watchlist: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting watchlist")
            Result.failure(e)
        }
    }

    /**
     * Add item to watchlist
     */
    suspend fun addToWatchlist(mediaId: String): Result<Unit> {
        return try {
            val response = api.addToWatchlist(mediaId)
            if (response.isSuccessful) {
                Timber.d("Added to watchlist: $mediaId")
                Result.success(Unit)
            } else {
                Timber.w("Failed to add to watchlist: ${response.code()}")
                Result.failure(Exception("Failed to add to watchlist: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error adding to watchlist: $mediaId")
            Result.failure(e)
        }
    }

    /**
     * Remove item from watchlist
     */
    suspend fun removeFromWatchlist(mediaId: String): Result<Unit> {
        return try {
            val response = api.removeFromWatchlist(mediaId)
            if (response.isSuccessful) {
                Timber.d("Removed from watchlist: $mediaId")
                Result.success(Unit)
            } else {
                Timber.w("Failed to remove from watchlist: ${response.code()}")
                Result.failure(Exception("Failed to remove from watchlist: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error removing from watchlist: $mediaId")
            Result.failure(e)
        }
    }

    /**
     * Check if item is in watchlist
     */
    suspend fun isInWatchlist(mediaId: String): Boolean {
        return try {
            val watchlist = getWatchlist().getOrNull() ?: emptyList()
            watchlist.any { it.id == mediaId }
        } catch (e: Exception) {
            Timber.e(e, "Error checking watchlist status: $mediaId")
            false
        }
    }

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
