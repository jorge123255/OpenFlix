package com.openflix.data.repository

import com.openflix.data.network.OpenFlixApi
import com.openflix.domain.model.*

class MediaRepository(private val api: OpenFlixApi) {

    suspend fun getLibrarySections(): List<LibrarySection> {
        val response = api.getLibrarySections()
        return response.MediaContainer?.allDirectories?.map { it.toDomain() } ?: emptyList()
    }

    suspend fun getLibraryItems(
        sectionId: Int, start: Int? = null, size: Int? = null,
        sort: String? = null, filters: Map<String, String>? = null
    ): List<MediaItem> {
        val response = api.getLibraryItems(sectionId, start, size, sort, filters)
        return response.MediaContainer?.Metadata?.map { it.toDomain() } ?: emptyList()
    }

    suspend fun getMediaDetails(key: Int): MediaItem? {
        val response = api.getMediaDetails(key)
        return response.MediaContainer?.Metadata?.firstOrNull()?.toDomain()
    }

    suspend fun getMediaChildren(key: Int): List<MediaItem> {
        val response = api.getMediaChildren(key)
        return response.MediaContainer?.Metadata?.map { it.toDomain() } ?: emptyList()
    }

    suspend fun getRecentlyAdded(): List<MediaItem> {
        val response = api.getRecentlyAdded()
        return response.MediaContainer?.Metadata?.map { it.toDomain() } ?: emptyList()
    }

    suspend fun getOnDeck(): List<MediaItem> {
        val response = api.getOnDeck()
        return response.MediaContainer?.Metadata?.map { it.toDomain() } ?: emptyList()
    }

    suspend fun getHubs(sectionId: Int): List<Hub> {
        val response = api.getHubs(sectionId)
        return response.MediaContainer?.Hub?.map { it.toDomain() } ?: emptyList()
    }

    suspend fun search(query: String, limit: Int? = 50): List<MediaItem> {
        val response = api.search(query, limit)
        return response.MediaContainer?.Hub?.flatMap { hub ->
            hub.Metadata?.map { it.toDomain() } ?: emptyList()
        } ?: emptyList()
    }

    suspend fun getPlaybackURL(path: String, directPlay: Boolean = true): String {
        return api.getPlaybackURL(path, directPlay).url
    }

    suspend fun updateProgress(key: Int, time: Int, state: String? = null) {
        api.updateProgress(key, time, state)
    }

    suspend fun markWatched(key: Int) {
        api.scrobble(key)
    }

    suspend fun markUnwatched(key: Int) {
        api.unscrobble(key)
    }
}
