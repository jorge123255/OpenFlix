package com.openflix.data.repository

import com.openflix.data.network.OpenFlixApi
import com.openflix.domain.model.WatchlistItem
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class WatchlistRepository(private val api: OpenFlixApi) {
    private val _items = MutableStateFlow<List<WatchlistItem>>(emptyList())
    val items: StateFlow<List<WatchlistItem>> = _items.asStateFlow()

    private val _watchlistIds = MutableStateFlow<Set<Int>>(emptySet())
    val watchlistIds: StateFlow<Set<Int>> = _watchlistIds.asStateFlow()

    suspend fun loadWatchlist(): List<WatchlistItem> {
        val response = api.getWatchlist()
        val list = response.allItems.map { it.toDomain() }
        _items.value = list
        _watchlistIds.value = list.map { it.mediaId }.toSet()
        return list
    }

    suspend fun addToWatchlist(mediaId: Int) {
        api.addToWatchlist(mediaId)
        _watchlistIds.value = _watchlistIds.value + mediaId
    }

    suspend fun removeFromWatchlist(mediaId: Int) {
        api.removeFromWatchlist(mediaId)
        _watchlistIds.value = _watchlistIds.value - mediaId
        _items.value = _items.value.filter { it.mediaId != mediaId }
    }

    suspend fun toggleWatchlist(mediaId: Int) {
        if (_watchlistIds.value.contains(mediaId)) {
            removeFromWatchlist(mediaId)
        } else {
            addToWatchlist(mediaId)
        }
    }

    fun isInWatchlist(mediaId: Int): Boolean = _watchlistIds.value.contains(mediaId)
}
