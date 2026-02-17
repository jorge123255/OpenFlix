package com.openflix.presentation.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.Channel
import com.openflix.domain.model.Hub
import com.openflix.domain.model.MediaItem
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class DiscoverViewModel @Inject constructor(
    private val mediaRepository: MediaRepository,
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(DiscoverUiState())
    val uiState: StateFlow<DiscoverUiState> = _uiState.asStateFlow()

    fun loadHomeContent() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            // Load library hubs and streaming services in parallel
            val hubsResult = mediaRepository.getHomeHubs()
            val streamingResult = mediaRepository.getStreamingServiceHubs()
            val channelsResult = liveTVRepository.getChannels()

            hubsResult.fold(
                onSuccess = { hubs ->
                    // Get streaming services
                    val streamingHubs = streamingResult.getOrDefault(emptyList())
                    val channels = channelsResult.getOrDefault(emptyList()).filter { !it.hidden }

                    // Extract continue watching from on-deck hub if available
                    val continueWatching = hubs.find { it.title.equals("On Deck", ignoreCase = true) ||
                            it.title.equals("Continue Watching", ignoreCase = true) }?.items ?: emptyList()

                    // Find a featured item from the first hub or promoted hub
                    val featuredItem = hubs
                        .firstOrNull { it.promoted || it.style == "hero" }
                        ?.items?.firstOrNull()
                        ?: hubs.firstOrNull()?.items?.firstOrNull()

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            hubs = hubs,
                            streamingServiceHubs = streamingHubs,
                            featuredItem = featuredItem,
                            continueWatching = continueWatching,
                            channels = channels
                        )
                    }
                    Timber.d("Loaded ${hubs.size} hubs and ${streamingHubs.size} streaming service hubs")
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
    val error: String? = null
)
