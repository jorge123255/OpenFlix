package com.openflix.presentation.screens.watchlist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.WatchlistRepository
import com.openflix.domain.model.MediaItem
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class WatchlistViewModel @Inject constructor(
    private val watchlistRepository: WatchlistRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(WatchlistUiState())
    val uiState: StateFlow<WatchlistUiState> = _uiState.asStateFlow()

    init {
        loadWatchlist()
    }

    fun loadWatchlist() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            watchlistRepository.getWatchlist().fold(
                onSuccess = { items ->
                    Timber.d("Loaded ${items.size} watchlist items")
                    _uiState.update { it.copy(
                        isLoading = false,
                        items = items,
                        error = null
                    )}
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load watchlist")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load watchlist"
                    )}
                }
            )
        }
    }

    fun removeFromWatchlist(mediaId: String) {
        viewModelScope.launch {
            // Optimistically remove from UI
            _uiState.update { state ->
                state.copy(items = state.items.filter { it.id != mediaId })
            }

            watchlistRepository.removeFromWatchlist(mediaId).fold(
                onSuccess = {
                    Timber.d("Removed from watchlist: $mediaId")
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to remove from watchlist: $mediaId")
                    // Reload on error
                    loadWatchlist()
                }
            )
        }
    }

    fun addToWatchlist(mediaId: String) {
        viewModelScope.launch {
            watchlistRepository.addToWatchlist(mediaId).fold(
                onSuccess = {
                    Timber.d("Added to watchlist: $mediaId")
                    loadWatchlist() // Reload to get updated list
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to add to watchlist: $mediaId")
                }
            )
        }
    }
}

data class WatchlistUiState(
    val isLoading: Boolean = false,
    val items: List<MediaItem> = emptyList(),
    val error: String? = null
)
