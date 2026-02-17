package com.openflix.presentation.screens.dvr

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.local.ContentType
import com.openflix.data.local.WatchStatsService
import com.openflix.data.repository.DVRRepository
import com.openflix.domain.model.Commercial
import com.openflix.domain.model.Recording
import com.openflix.domain.model.RecordingStatus
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class DVRPlayerViewModel @Inject constructor(
    private val dvrRepository: DVRRepository,
    private val watchStatsService: WatchStatsService
) : ViewModel() {

    private val _uiState = MutableStateFlow(DVRPlayerUiState())
    val uiState: StateFlow<DVRPlayerUiState> = _uiState.asStateFlow()

    // Track which commercials have been auto-skipped to avoid repeated skipping
    private val skippedCommercials = mutableSetOf<Int>()

    private var currentRecordingId: String? = null

    fun loadRecording(recordingId: String, playbackMode: DVRPlaybackMode) {
        currentRecordingId = recordingId
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            // First, get recording details to check status and view offset
            val recordingsResult = dvrRepository.getRecordings()
            val recording = recordingsResult.getOrNull()?.find { it.id == recordingId }

            if (recording == null) {
                _uiState.update {
                    it.copy(isLoading = false, error = "Recording not found")
                }
                return@launch
            }

            val isLive = recording.status == RecordingStatus.RECORDING

            // Determine start position based on mode
            val startPosition = when (playbackMode) {
                DVRPlaybackMode.START -> 0L
                DVRPlaybackMode.LIVE -> {
                    // For live recordings, we want to start near the end
                    // The duration will be updated dynamically, but we signal "live" to the player
                    -1L // Signal to seek to end once loaded
                }
                DVRPlaybackMode.DEFAULT -> {
                    // For completed recordings, resume from last position
                    // For live recordings, start at beginning
                    if (isLive) 0L else (recording.viewOffset ?: 0L)
                }
            }

            _uiState.update {
                it.copy(
                    recording = recording,
                    isLiveRecording = isLive,
                    startPosition = if (startPosition >= 0) startPosition else 0L
                )
            }

            // Get stream URL
            val streamResult = dvrRepository.getRecordingStreamUrl(recordingId)
            streamResult.fold(
                onSuccess = { url ->
                    Timber.d("Got stream URL for recording $recordingId: $url")

                    // Start watch tracking for DVR recording
                    watchStatsService.startWatchSession(
                        contentId = recordingId,
                        contentType = ContentType.DVR_RECORDING,
                        title = recording.title
                    )

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            streamUrl = url,
                            // If mode is LIVE, we'll seek to end after playback starts
                            seekToLiveOnStart = playbackMode == DVRPlaybackMode.LIVE
                        )
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to get stream URL for recording $recordingId")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load recording"
                        )
                    }
                }
            )
        }
    }

    fun saveProgress(positionMs: Long) {
        val recordingId = currentRecordingId ?: return
        val recording = _uiState.value.recording ?: return

        // Don't save progress for live recordings (it doesn't make sense)
        if (_uiState.value.isLiveRecording) return

        // Save progress to server
        viewModelScope.launch {
            dvrRepository.updateRecordingProgress(recordingId, positionMs).fold(
                onSuccess = {
                    Timber.d("Saved progress for $recordingId: ${positionMs}ms")
                },
                onFailure = { error ->
                    Timber.w(error, "Failed to save progress for $recordingId")
                }
            )
        }
    }

    /**
     * Toggle auto-skip commercials setting
     */
    fun toggleAutoSkip() {
        _uiState.update { it.copy(autoSkipEnabled = !it.autoSkipEnabled) }
    }

    /**
     * Check if current position is in a commercial and return the commercial if so.
     * Returns null if not in a commercial.
     */
    fun getCurrentCommercial(positionMs: Long): CommercialInfo? {
        val commercials = _uiState.value.recording?.commercials ?: return null

        commercials.forEachIndexed { index, commercial ->
            if (positionMs >= commercial.start && positionMs < commercial.end) {
                return CommercialInfo(
                    index = index,
                    commercial = commercial,
                    remainingMs = commercial.end - positionMs
                )
            }
        }
        return null
    }

    /**
     * Get the end position of a commercial for skipping.
     * Marks the commercial as skipped to prevent repeated auto-skips.
     */
    fun getSkipPosition(commercialIndex: Int): Long? {
        val commercials = _uiState.value.recording?.commercials ?: return null
        if (commercialIndex >= commercials.size) return null

        skippedCommercials.add(commercialIndex)
        return commercials[commercialIndex].end
    }

    /**
     * Check if a commercial should be auto-skipped.
     * Returns true only if auto-skip is enabled and this commercial hasn't been skipped yet.
     */
    fun shouldAutoSkip(commercialIndex: Int): Boolean {
        return _uiState.value.autoSkipEnabled && commercialIndex !in skippedCommercials
    }

    /**
     * Reset skipped commercials tracking (e.g., when seeking backwards)
     */
    fun resetSkippedCommercials() {
        skippedCommercials.clear()
    }

    /**
     * Get chapter boundaries from commercial breaks.
     * Chapters are the content segments between commercials.
     * Returns list of start positions (ms) for each chapter.
     */
    fun getChapterBoundaries(): List<Long> {
        val commercials = _uiState.value.recording?.commercials ?: return emptyList()
        if (commercials.isEmpty()) return emptyList()

        val boundaries = mutableListOf(0L) // Start of recording
        for (commercial in commercials) {
            boundaries.add(commercial.end) // Start of content after each commercial
        }
        return boundaries
    }

    /**
     * Jump to the next chapter (content segment after next commercial).
     * Returns the position to seek to, or null if already at the last chapter.
     */
    fun getNextChapterPosition(currentPositionMs: Long): Long? {
        val boundaries = getChapterBoundaries()
        if (boundaries.isEmpty()) return null
        return boundaries.firstOrNull { it > currentPositionMs + 1000 } // 1s tolerance
    }

    /**
     * Jump to the previous chapter (start of current or previous content segment).
     * Returns the position to seek to, or null if at the beginning.
     */
    fun getPreviousChapterPosition(currentPositionMs: Long): Long? {
        val boundaries = getChapterBoundaries()
        if (boundaries.isEmpty()) return null
        // If we're more than 3 seconds into a chapter, go to its start
        // Otherwise, go to the previous chapter
        return boundaries.lastOrNull { it < currentPositionMs - 3000 }
    }

    override fun onCleared() {
        super.onCleared()
        watchStatsService.endWatchSession()
    }
}

/**
 * Information about the current commercial being played
 */
data class CommercialInfo(
    val index: Int,
    val commercial: Commercial,
    val remainingMs: Long
) {
    val remainingSeconds: Int
        get() = (remainingMs / 1000).toInt()
}

data class DVRPlayerUiState(
    val isLoading: Boolean = false,
    val recording: Recording? = null,
    val streamUrl: String? = null,
    val startPosition: Long = 0L,
    val isLiveRecording: Boolean = false,
    val seekToLiveOnStart: Boolean = false,
    val autoSkipEnabled: Boolean = true,  // Auto-skip commercials by default
    val error: String? = null
) {
    val commercials: List<Commercial>
        get() = recording?.commercials ?: emptyList()

    val hasCommercials: Boolean
        get() = commercials.isNotEmpty()
}
