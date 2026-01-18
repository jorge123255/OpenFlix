package com.openflix.presentation.screens.tvshows

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.Hub
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class TVShowsViewModel @Inject constructor(
    private val mediaRepository: MediaRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TVShowsUiState())
    val uiState: StateFlow<TVShowsUiState> = _uiState.asStateFlow()

    fun loadTVShows() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = mediaRepository.getHomeHubs()

            result.fold(
                onSuccess = { hubs ->
                    // Filter hubs to only include those with shows or episodes
                    val showHubs = hubs.filter { hub ->
                        hub.items.isNotEmpty() &&
                        (hub.items.first().type == MediaType.SHOW ||
                         hub.items.first().type == MediaType.EPISODE ||
                         hub.items.first().type == MediaType.SEASON)
                    }.filterNot { hub ->
                        // Exclude continue watching (handled separately)
                        hub.hubKey?.contains("ondeck", ignoreCase = true) == true ||
                        hub.hubKey?.contains("continue", ignoreCase = true) == true
                    }

                    // Get continue watching episodes
                    val continueWatching = hubs
                        .filter { hub ->
                            hub.hubKey?.contains("ondeck", ignoreCase = true) == true ||
                            hub.hubKey?.contains("continue", ignoreCase = true) == true
                        }
                        .flatMap { it.items }
                        .filter { it.type == MediaType.EPISODE }

                    // Find featured show
                    val featuredItem = showHubs
                        .firstOrNull { it.promoted || it.style == "hero" }
                        ?.items?.firstOrNull()
                        ?: showHubs.firstOrNull()?.items?.firstOrNull()

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            hubs = showHubs,
                            continueWatching = continueWatching,
                            featuredItem = featuredItem
                        )
                    }
                    Timber.d("Loaded ${showHubs.size} TV show hubs")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load TV shows")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load TV shows"
                        )
                    }
                }
            )
        }
    }

    fun refresh() {
        loadTVShows()
    }
}

data class TVShowsUiState(
    val isLoading: Boolean = false,
    val hubs: List<Hub> = emptyList(),
    val continueWatching: List<MediaItem> = emptyList(),
    val featuredItem: MediaItem? = null,
    val error: String? = null
)
