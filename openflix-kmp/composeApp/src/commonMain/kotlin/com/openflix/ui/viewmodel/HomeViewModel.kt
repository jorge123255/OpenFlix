package com.openflix.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.DVRRepository
import com.openflix.data.repository.LiveTVRepository
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.*
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class ForYouHeroItem(
    val id: String,
    val title: String,
    val subtitle: String?,
    val posterPath: String?,
    val artPath: String?,
    val badge: String?,
    val mediaId: String?,
    val channelId: String?
)

data class HomeUiState(
    val isLoading: Boolean = true,
    val hasLoaded: Boolean = false,
    val error: String? = null,
    val heroItems: List<ForYouHeroItem> = emptyList(),
    val continueWatching: List<MediaItem> = emptyList(),
    val movies: List<MediaItem> = emptyList(),
    val tvShows: List<MediaItem> = emptyList(),
    val channels: List<Channel> = emptyList(),
    val recentRecordings: List<Recording> = emptyList(),
    val recentlyAdded: List<MediaItem> = emptyList(),
    val rows: List<MediaRow> = emptyList()
)

data class MediaRow(val title: String, val items: List<MediaItem>)

class HomeViewModel(
    private val mediaRepository: MediaRepository,
    private val liveTVRepository: LiveTVRepository,
    private val dvrRepository: DVRRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    fun loadHome() {
        // Skip reload if data already loaded
        if (_uiState.value.hasLoaded && !_uiState.value.isLoading) return

        viewModelScope.launch {
            _uiState.value = HomeUiState(isLoading = true)
            try {
                // Load all data sources in parallel
                val onDeckDeferred = async { runCatching { mediaRepository.getOnDeck() }.getOrDefault(emptyList()) }
                val recentDeferred = async { runCatching { mediaRepository.getRecentlyAdded() }.getOrDefault(emptyList()) }
                val sectionsDeferred = async { runCatching { mediaRepository.getLibrarySections() }.getOrDefault(emptyList()) }
                val channelsDeferred = async { runCatching { liveTVRepository.loadChannels() }.getOrDefault(emptyList()) }
                val recordingsDeferred = async { runCatching { dvrRepository.loadRecordings() }.getOrDefault(emptyList()) }

                val onDeck = onDeckDeferred.await()
                val recentlyAdded = recentDeferred.await()
                val channels = channelsDeferred.await()
                val recordings = recordingsDeferred.await()
                    .filter { it.status == RecordingStatus.COMPLETED }
                    .take(10)

                // Continue watching: items that are in progress
                val continueWatching = onDeck.filter { it.isInProgress }

                // Show initial data immediately while hubs load in background
                val channelHeroes = channels
                    .filter { ch ->
                        ch.nowPlaying != null &&
                            (ch.nowPlaying?.icon != null || ch.nowPlaying?.art != null)
                    }
                    .take(2)
                    .map { channel ->
                        ForYouHeroItem(
                            id = "channel_${channel.id}",
                            title = channel.nowPlaying!!.title,
                            subtitle = channel.name,
                            posterPath = channel.nowPlaying?.icon ?: channel.logo,
                            artPath = channel.nowPlaying?.art ?: channel.nowPlaying?.icon,
                            badge = "LIVE",
                            mediaId = null,
                            channelId = channel.id
                        )
                    }

                _uiState.value = HomeUiState(
                    isLoading = false,
                    hasLoaded = true,
                    heroItems = channelHeroes,
                    continueWatching = continueWatching,
                    channels = channels,
                    recentRecordings = recordings,
                    recentlyAdded = recentlyAdded.take(20),
                    rows = emptyList()
                )

                // Now load hubs in background — UI is already visible
                val sections = sectionsDeferred.await()
                val allHubItems = mutableListOf<MediaItem>()
                val rows = mutableListOf<MediaRow>()
                for (section in sections.take(4)) {
                    try {
                        val hubs = mediaRepository.getHubs(section.id)
                        for (hub in hubs.take(2)) {
                            if (hub.items.isNotEmpty()) {
                                rows.add(MediaRow(hub.title, hub.items))
                                allHubItems.addAll(hub.items)
                            }
                        }
                    } catch (_: Exception) { }
                }

                // Extract movies (deduplicated by title+year)
                val movieItems = (allHubItems + recentlyAdded)
                    .filter { it.type == MediaType.MOVIE }
                    .distinctBy { "${it.title.lowercase()}_${it.year ?: ""}" }
                    .take(15)

                // Extract TV shows (deduplicated by show name)
                val tvShowItems = (allHubItems + recentlyAdded)
                    .filter { it.type == MediaType.SHOW || it.type == MediaType.EPISODE }
                    .distinctBy { (it.grandparentTitle ?: it.title).lowercase() }
                    .take(15)

                // Update hero with movie heroes too
                val movieHeroes = movieItems
                    .filter { it.thumb != null || it.art != null }
                    .take(3)
                    .map { item ->
                        ForYouHeroItem(
                            id = "movie_${item.id}",
                            title = item.title,
                            subtitle = item.year?.toString(),
                            posterPath = item.thumb,
                            artPath = item.art ?: item.thumb,
                            badge = "MOVIE",
                            mediaId = item.id.toString(),
                            channelId = null
                        )
                    }

                val heroItems = (movieHeroes + channelHeroes).take(5)

                _uiState.value = _uiState.value.copy(
                    heroItems = heroItems,
                    movies = movieItems,
                    tvShows = tvShowItems,
                    rows = rows
                )
            } catch (e: Exception) {
                if (_uiState.value.isLoading) {
                    _uiState.value = HomeUiState(isLoading = false, hasLoaded = true, error = e.message ?: "Failed to load")
                }
            }
        }
    }

    fun refresh() {
        // Clear cached data so loadHome() doesn't skip
        _uiState.value = HomeUiState(isLoading = true, hasLoaded = false)
        loadHome()
    }
}
