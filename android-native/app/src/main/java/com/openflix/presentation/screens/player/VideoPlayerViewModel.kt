package com.openflix.presentation.screens.player

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.local.ContentType
import com.openflix.data.local.WatchStatsService
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.backdropUrl
import com.openflix.domain.model.posterUrl
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for the video player screen.
 * Handles loading media info and constructing playback URLs.
 */
@HiltViewModel
class VideoPlayerViewModel @Inject constructor(
    private val repository: MediaRepository,
    private val watchStatsService: WatchStatsService
) : ViewModel() {

    private val _uiState = MutableStateFlow(VideoPlayerUiState())
    val uiState: StateFlow<VideoPlayerUiState> = _uiState.asStateFlow()

    fun loadMedia(mediaId: String) {
        Timber.d("loadMedia called with mediaId: $mediaId")
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            Timber.d("Fetching media item for ID: $mediaId")
            repository.getMediaItem(mediaId).fold(
                onSuccess = { mediaItem ->
                    Timber.d("Loaded media: ${mediaItem.title}")

                    // Get playback URL
                    repository.getPlaybackUrl(mediaId).fold(
                        onSuccess = { url ->
                            Timber.d("Got playback URL: $url")

                            // Start watch tracking
                            val contentType = when (mediaItem.type) {
                                MediaType.MOVIE -> ContentType.MOVIE
                                MediaType.SHOW, MediaType.EPISODE -> ContentType.TV_SHOW
                                else -> ContentType.MOVIE
                            }
                            watchStatsService.startWatchSession(
                                contentId = mediaItem.id,
                                contentType = contentType,
                                title = mediaItem.title
                            )

                            _uiState.update { it.copy(
                                isLoading = false,
                                mediaInfo = MediaInfo(
                                    id = mediaItem.id,
                                    title = mediaItem.title,
                                    subtitle = mediaItem.tagline,
                                    posterUrl = mediaItem.posterUrl,
                                    backdropUrl = mediaItem.backdropUrl
                                ),
                                streamUrl = url,
                                startPosition = mediaItem.viewOffset ?: 0L
                            )}
                        },
                        onFailure = { e ->
                            Timber.e(e, "Failed to get playback URL")
                            _uiState.update { it.copy(
                                isLoading = false,
                                error = e.message ?: "Failed to get playback URL"
                            )}
                        }
                    )
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load media: $mediaId")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load media"
                    )}
                }
            )
        }
    }

    fun saveProgress(positionMs: Long) {
        val mediaId = _uiState.value.mediaInfo?.id ?: return
        viewModelScope.launch {
            repository.updateProgress(mediaId, positionMs).fold(
                onSuccess = {
                    Timber.d("Progress saved: $positionMs ms")
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to save progress")
                }
            )
        }
    }

    fun endWatchSession() {
        watchStatsService.endWatchSession()
    }

    override fun onCleared() {
        super.onCleared()
        endWatchSession()
    }
}

data class VideoPlayerUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val mediaInfo: MediaInfo? = null,
    val streamUrl: String? = null,
    val startPosition: Long = 0L
)

data class MediaInfo(
    val id: String,
    val title: String,
    val subtitle: String?,
    val posterUrl: String?,
    val backdropUrl: String?
)
