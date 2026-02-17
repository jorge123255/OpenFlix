package com.openflix.presentation.screens.media

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.Season
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class MediaDetailViewModel @Inject constructor(
    private val mediaRepository: MediaRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(MediaDetailUiState())
    val uiState: StateFlow<MediaDetailUiState> = _uiState.asStateFlow()

    fun loadMediaDetail(mediaId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val mediaResult = mediaRepository.getMediaItem(mediaId)

            mediaResult.fold(
                onSuccess = { mediaItem ->
                    _uiState.update { it.copy(mediaItem = mediaItem) }

                    // Load related content
                    loadRelatedContent(mediaId)

                    // Load seasons for TV shows
                    if (mediaItem.type == com.openflix.domain.model.MediaType.SHOW) {
                        loadSeasons(mediaId)
                    }

                    _uiState.update { it.copy(isLoading = false) }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load media detail")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load media"
                        )
                    }
                }
            )
        }
    }

    private fun loadRelatedContent(mediaId: String) {
        viewModelScope.launch {
            val result = mediaRepository.getRelatedMedia(mediaId)
            result.fold(
                onSuccess = { related ->
                    _uiState.update { it.copy(relatedItems = related) }
                },
                onFailure = { error ->
                    Timber.w(error, "Failed to load related content")
                }
            )
        }
    }

    private fun loadSeasons(showId: String) {
        viewModelScope.launch {
            val result = mediaRepository.getShowSeasons(showId)
            result.fold(
                onSuccess = { seasons ->
                    _uiState.update { it.copy(seasons = seasons) }
                },
                onFailure = { error ->
                    Timber.w(error, "Failed to load seasons")
                }
            )
        }
    }
}

data class MediaDetailUiState(
    val isLoading: Boolean = false,
    val mediaItem: MediaItem? = null,
    val seasons: List<Season> = emptyList(),
    val relatedItems: List<MediaItem> = emptyList(),
    val error: String? = null
)
