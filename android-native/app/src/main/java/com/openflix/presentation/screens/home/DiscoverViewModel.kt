package com.openflix.presentation.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.DVRRepository
import com.openflix.data.repository.LiveTVRepository
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.Channel
import com.openflix.domain.model.Hub
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.Recording
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class DiscoverViewModel @Inject constructor(
    private val mediaRepository: MediaRepository,
    private val liveTVRepository: LiveTVRepository,
    private val dvrRepository: DVRRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(DiscoverUiState())
    val uiState: StateFlow<DiscoverUiState> = _uiState.asStateFlow()

    fun loadHomeContent() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            // Load all data sources in parallel
            val hubsDeferred = async { mediaRepository.getHomeHubs() }
            val streamingDeferred = async { mediaRepository.getStreamingServiceHubs() }
            val channelsDeferred = async { liveTVRepository.getChannels() }
            val recordingsDeferred = async { dvrRepository.getRecordings() }

            val hubsResult = hubsDeferred.await()
            val streamingResult = streamingDeferred.await()
            val channelsResult = channelsDeferred.await()
            val recordingsResult = recordingsDeferred.await()

            hubsResult.fold(
                onSuccess = { hubs ->
                    // Get streaming services
                    val streamingHubs = streamingResult.getOrDefault(emptyList())
                    val channels = channelsResult.getOrDefault(emptyList()).filter { !it.hidden }
                    val recordings = recordingsResult.getOrDefault(emptyList())
                        .sortedByDescending { it.startTime }
                        .take(10)

                    // Extract continue watching from on-deck hub if available
                    val continueWatching = hubs.find {
                        it.title.equals("On Deck", ignoreCase = true) ||
                            it.title.equals("Continue Watching", ignoreCase = true)
                    }?.items ?: emptyList()

                    // Find a featured item from the first hub or promoted hub
                    val featuredItem = hubs
                        .firstOrNull { it.promoted || it.style == "hero" }
                        ?.items?.firstOrNull()
                        ?: hubs.firstOrNull()?.items?.firstOrNull()

                    // Extract movies (deduplicated by title+year, matching iOS)
                    val movieItems = hubs
                        .flatMap { it.items }
                        .filter { it.type == MediaType.MOVIE }
                        .distinctBy { "${it.title.lowercase()}_${it.year ?: ""}" }
                        .take(15)

                    // Extract TV shows (deduplicated by show name, matching iOS)
                    val tvShowItems = hubs
                        .flatMap { it.items }
                        .filter { it.type == MediaType.SHOW || it.type == MediaType.EPISODE }
                        .distinctBy { (it.grandparentTitle ?: it.title).lowercase() }
                        .take(15)

                    // Build hero items: movies first, then live channels (matching iOS order)
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
                                mediaId = item.id,
                                channelId = null
                            )
                        }

                    val channelHeroes = channels
                        .filter { ch ->
                            ch.nowPlaying != null &&
                                (ch.nowPlaying.thumb != null || ch.nowPlaying.art != null)
                        }
                        .take(2)
                        .map { channel ->
                            ForYouHeroItem(
                                id = "channel_${channel.id}",
                                title = channel.nowPlaying!!.title,
                                subtitle = channel.name,
                                posterPath = channel.nowPlaying.thumb ?: channel.logo,
                                artPath = channel.nowPlaying.art ?: channel.nowPlaying.thumb,
                                badge = "LIVE",
                                mediaId = null,
                                channelId = channel.id
                            )
                        }

                    val heroItems = (movieHeroes + channelHeroes).take(5)

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            hubs = hubs,
                            streamingServiceHubs = streamingHubs,
                            featuredItem = featuredItem,
                            continueWatching = continueWatching,
                            channels = channels,
                            recentRecordings = recordings,
                            movies = movieItems,
                            tvShows = tvShowItems,
                            heroItems = heroItems
                        )
                    }
                    Timber.d("Loaded ${hubs.size} hubs, ${movieItems.size} movies, ${tvShowItems.size} shows, ${heroItems.size} heroes")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load home content")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load content"
                        )
                    }
                }
            )
        }
    }

    fun refresh() {
        loadHomeContent()
    }

    /**
     * Load channels for mini guide
     */
    fun loadChannels(onLoaded: (List<Channel>) -> Unit) {
        viewModelScope.launch {
            liveTVRepository.getChannels().fold(
                onSuccess = { channels ->
                    Timber.d("Loaded ${channels.size} channels for mini guide")
                    onLoaded(channels.filter { !it.hidden })
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load channels")
                    onLoaded(emptyList())
                }
            )
        }
    }
}

data class DiscoverUiState(
    val isLoading: Boolean = false,
    val hubs: List<Hub> = emptyList(),
    val streamingServiceHubs: List<Hub> = emptyList(),
    val featuredItem: MediaItem? = null,
    val continueWatching: List<MediaItem> = emptyList(),
    val channels: List<Channel> = emptyList(),
    val recentRecordings: List<Recording> = emptyList(),
    val movies: List<MediaItem> = emptyList(),
    val tvShows: List<MediaItem> = emptyList(),
    val heroItems: List<ForYouHeroItem> = emptyList(),
    val error: String? = null
)

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
