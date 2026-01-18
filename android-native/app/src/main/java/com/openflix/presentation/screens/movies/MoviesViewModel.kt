package com.openflix.presentation.screens.movies

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
class MoviesViewModel @Inject constructor(
    private val mediaRepository: MediaRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(MoviesUiState())
    val uiState: StateFlow<MoviesUiState> = _uiState.asStateFlow()

    fun loadMovies() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = mediaRepository.getHomeHubs()

            result.fold(
                onSuccess = { hubs ->
                    // Filter hubs to only include those with movies
                    val movieHubs = hubs.filter { hub ->
                        hub.items.isNotEmpty() && hub.items.first().type == MediaType.MOVIE
                    }.filterNot { hub ->
                        // Exclude continue watching (handled separately)
                        hub.hubKey?.contains("ondeck", ignoreCase = true) == true ||
                        hub.hubKey?.contains("continue", ignoreCase = true) == true
                    }

                    // Get continue watching movies
                    val continueWatching = hubs
                        .filter { hub ->
                            hub.hubKey?.contains("ondeck", ignoreCase = true) == true ||
                            hub.hubKey?.contains("continue", ignoreCase = true) == true
                        }
                        .flatMap { it.items }
                        .filter { it.type == MediaType.MOVIE }

                    // Find featured movie
                    val featuredItem = movieHubs
                        .firstOrNull { it.promoted || it.style == "hero" }
                        ?.items?.firstOrNull()
                        ?: movieHubs.firstOrNull()?.items?.firstOrNull()

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            hubs = movieHubs,
                            continueWatching = continueWatching,
                            featuredItem = featuredItem
                        )
                    }
                    Timber.d("Loaded ${movieHubs.size} movie hubs")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load movies")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load movies"
                        )
                    }
                }
            )
        }
    }

    fun refresh() {
        loadMovies()
    }
}

data class MoviesUiState(
    val isLoading: Boolean = false,
    val hubs: List<Hub> = emptyList(),
    val continueWatching: List<MediaItem> = emptyList(),
    val featuredItem: MediaItem? = null,
    val error: String? = null
)
