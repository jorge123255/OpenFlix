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
 * Supports failover to alternate sources when playback fails.
 */
@HiltViewModel
class VideoPlayerViewModel @Inject constructor(
    private val repository: MediaRepository,
    private val watchStatsService: WatchStatsService
) : ViewModel() {

    private val _uiState = MutableStateFlow(VideoPlayerUiState())
    val uiState: StateFlow<VideoPlayerUiState> = _uiState.asStateFlow()

    // Track current playback position and duration for sync
    private var currentPositionMs: Long = 0L
    private var totalDurationMs: Long = 0L

    // Failover support
    private var allSourceIds: List<String> = emptyList()
    private var currentSourceIndex: Int = 0
    private var failedSources: MutableSet<String> = mutableSetOf()

    /**
     * Load media with optional alternate sources for failover
     */
    fun loadMedia(mediaId: String, alternateSources: List<String> = emptyList()) {
        // Set up source list for failover
        allSourceIds = listOf(mediaId) + alternateSources
        currentSourceIndex = 0
        failedSources.clear()

        loadCurrentSource()
    }

    private fun loadCurrentSource() {
        val mediaId = allSourceIds.getOrNull(currentSourceIndex)
        if (mediaId == null) {
            _uiState.update { it.copy(
                isLoading = false,
                error = "All sources failed to play"
            )}
            return
        }

        loadMediaInternal(mediaId)
    }

    private fun loadMediaInternal(mediaId: String) {
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
                                startPosition = mediaItem.viewOffset ?: 0L,
                                sourceInfo = currentSourceInfo,
                                hasMoreSources = hasMoreSources
                            )}
                        },
                        onFailure = { e ->
                            Timber.e(e, "Failed to get playback URL for source $mediaId")
                            handleSourceFailure(mediaId, e.message ?: "Failed to get playback URL")
                        }
                    )
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load media: $mediaId")
                    handleSourceFailure(mediaId, e.message ?: "Failed to load media")
                }
            )
        }
    }

    /**
     * Handle source failure - try next source if available
     */
    private fun handleSourceFailure(failedId: String, error: String) {
        failedSources.add(failedId)

        if (tryNextSource()) {
            Timber.d("Source $failedId failed, trying next source...")
        } else {
            // All sources exhausted
            _uiState.update { it.copy(
                isLoading = false,
                error = if (allSourceIds.size > 1) {
                    "All ${allSourceIds.size} sources failed to play"
                } else {
                    error
                }
            )}
        }
    }

    /**
     * Try the next available source. Returns true if there's another source to try.
     */
    fun tryNextSource(): Boolean {
        currentSourceIndex++
        while (currentSourceIndex < allSourceIds.size) {
            val nextId = allSourceIds[currentSourceIndex]
            if (nextId !in failedSources) {
                Timber.d("Trying alternate source ${currentSourceIndex + 1}/${allSourceIds.size}: $nextId")
                loadCurrentSource()
                return true
            }
            currentSourceIndex++
        }
        return false
    }

    /**
     * Called when playback fails (e.g., stream error)
     * Attempts to failover to the next source
     */
    fun onPlaybackError(error: String) {
        val currentId = allSourceIds.getOrNull(currentSourceIndex) ?: return
        Timber.e("Playback error on source $currentId: $error")
        handleSourceFailure(currentId, error)
    }

    /** Check if there are more sources to try */
    val hasMoreSources: Boolean
        get() = currentSourceIndex < allSourceIds.size - 1

    /** Get current source info for display */
    val currentSourceInfo: String
        get() = if (allSourceIds.size > 1) {
            "Source ${currentSourceIndex + 1} of ${allSourceIds.size}"
        } else ""

    /**
     * Update playback position and duration, and periodically sync to server
     */
    fun updatePlaybackState(positionMs: Long, durationMs: Long) {
        currentPositionMs = positionMs
        totalDurationMs = durationMs
    }

    /**
     * Save progress to server (called periodically during playback)
     */
    fun saveProgress(positionMs: Long, durationMs: Long? = null) {
        val mediaId = _uiState.value.mediaInfo?.id ?: return
        currentPositionMs = positionMs
        durationMs?.let { totalDurationMs = it }

        viewModelScope.launch {
            repository.updateProgress(mediaId, positionMs, durationMs ?: totalDurationMs).fold(
                onSuccess = {
                    Timber.d("Progress saved: $positionMs ms / $totalDurationMs ms")
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to save progress")
                    // Error is now handled by retry mechanism in repository
                }
            )
        }
    }

    /**
     * Mark the current media as watched (scrobble)
     */
    fun markAsWatched() {
        val mediaId = _uiState.value.mediaInfo?.id ?: return
        viewModelScope.launch {
            repository.markAsWatched(mediaId).fold(
                onSuccess = {
                    Timber.d("Marked as watched: $mediaId")
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to mark as watched")
                }
            )
        }
    }

    /**
     * End the watch session and sync final state to server
     */
    fun endWatchSession() {
        watchStatsService.endWatchSession(currentPositionMs, totalDurationMs)
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
    val startPosition: Long = 0L,
    val sourceInfo: String = "",
    val hasMoreSources: Boolean = false
)

data class MediaInfo(
    val id: String,
    val title: String,
    val subtitle: String?,
    val posterUrl: String?,
    val backdropUrl: String?
)
