package com.openflix.presentation.screens.playlist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.PlaylistRepository
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.Playlist
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class PlaylistsViewModel @Inject constructor(
    private val playlistRepository: PlaylistRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(PlaylistsUiState())
    val uiState: StateFlow<PlaylistsUiState> = _uiState.asStateFlow()

    init {
        loadPlaylists()
    }

    fun loadPlaylists() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            playlistRepository.getPlaylists().fold(
                onSuccess = { playlists ->
                    Timber.d("Loaded ${playlists.size} playlists")
                    _uiState.update { it.copy(
                        isLoading = false,
                        playlists = playlists,
                        error = null
                    )}
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load playlists")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load playlists"
                    )}
                }
            )
        }
    }

    fun selectPlaylist(playlist: Playlist) {
        viewModelScope.launch {
            _uiState.update { it.copy(
                selectedPlaylist = playlist,
                playlistItems = emptyList(),
                isLoadingItems = true
            )}

            playlistRepository.getPlaylistItems(playlist.id).fold(
                onSuccess = { items ->
                    Timber.d("Loaded ${items.size} items for playlist ${playlist.title}")
                    _uiState.update { it.copy(
                        playlistItems = items,
                        isLoadingItems = false
                    )}
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load playlist items")
                    _uiState.update { it.copy(
                        isLoadingItems = false,
                        error = e.message ?: "Failed to load playlist items"
                    )}
                }
            )
        }
    }

    fun clearSelection() {
        _uiState.update { it.copy(
            selectedPlaylist = null,
            playlistItems = emptyList()
        )}
    }
}

data class PlaylistsUiState(
    val isLoading: Boolean = false,
    val playlists: List<Playlist> = emptyList(),
    val selectedPlaylist: Playlist? = null,
    val playlistItems: List<MediaItem> = emptyList(),
    val isLoadingItems: Boolean = false,
    val error: String? = null
)
