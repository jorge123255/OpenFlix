package com.openflix.presentation.screens.livetv

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.ChannelWithPrograms
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for the EPG Guide screen.
 * Manages guide data loading and time navigation.
 */
@HiltViewModel
class LiveTVGuideViewModel @Inject constructor(
    private val repository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(LiveTVGuideUiState())
    val uiState: StateFlow<LiveTVGuideUiState> = _uiState.asStateFlow()

    private var baseStartTime: Long = 0
    private var baseEndTime: Long = 0

    fun loadGuide(startTime: Long, endTime: Long) {
        baseStartTime = startTime
        baseEndTime = endTime

        viewModelScope.launch {
            _uiState.update { it.copy(
                isLoading = true,
                error = null,
                visibleStartTime = startTime,
                visibleEndTime = endTime
            )}

            repository.getGuide(startTime, endTime).fold(
                onSuccess = { guide ->
                    Timber.d("Loaded ${guide.size} channels with programs")
                    _uiState.update { it.copy(
                        guide = guide,
                        isLoading = false
                    )}
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load guide")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load guide"
                    )}
                }
            )
        }
    }

    /**
     * Shift the visible time window by the specified number of minutes.
     * Positive values shift forward, negative values shift backward.
     */
    fun shiftTime(minutes: Int) {
        val shiftSeconds = minutes * 60L
        val newStartTime = _uiState.value.visibleStartTime + shiftSeconds
        val newEndTime = _uiState.value.visibleEndTime + shiftSeconds

        // Don't allow going too far in the past (more than 12 hours)
        val now = System.currentTimeMillis() / 1000
        val minStartTime = now - (12 * 60 * 60)
        if (newStartTime < minStartTime) return

        // Don't allow going too far in the future (more than 7 days)
        val maxEndTime = now + (7 * 24 * 60 * 60)
        if (newEndTime > maxEndTime) return

        // Reload guide with new time range
        loadGuide(newStartTime, newEndTime)
    }

    fun loadMoreChannels() {
        val currentCount = _uiState.value.displayedCount
        val totalCount = _uiState.value.guide.size
        if (currentCount < totalCount) {
            _uiState.update { it.copy(displayedCount = minOf(currentCount + 50, totalCount)) }
        }
    }

    fun getDisplayedGuide(): List<ChannelWithPrograms> {
        return _uiState.value.guide.take(_uiState.value.displayedCount)
    }
}

data class LiveTVGuideUiState(
    val guide: List<ChannelWithPrograms> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val visibleStartTime: Long = 0,
    val visibleEndTime: Long = 0,
    val displayedCount: Int = 50  // Only show first N channels initially
)
