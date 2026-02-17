package com.openflix.presentation.screens.livetv

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for Channel Surfing mode.
 * Provides quick channel preview with auto-advancement through channels.
 */
@HiltViewModel
class ChannelSurfingViewModel @Inject constructor(
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ChannelSurfingUiState())
    val uiState: StateFlow<ChannelSurfingUiState> = _uiState.asStateFlow()

    private var autoAdvanceJob: Job? = null
    private var previewDelayJob: Job? = null

    companion object {
        const val PREVIEW_DELAY_MS = 800L  // Delay before starting preview
        const val AUTO_ADVANCE_INTERVAL_MS = 10000L  // 10 seconds per channel in auto mode
    }

    init {
        loadChannels()
    }

    private fun loadChannels() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = liveTVRepository.getChannels()

            result.fold(
                onSuccess = { channels ->
                    val visibleChannels = channels.filterNot { it.hidden }
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            channels = visibleChannels,
                            currentIndex = 0,
                            focusedChannel = visibleChannels.firstOrNull()
                        )
                    }
                    Timber.d("Channel Surfing: Loaded ${visibleChannels.size} channels")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load channels for surfing")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load channels"
                        )
                    }
                }
            )
        }
    }

    /**
     * Focus on a specific channel (updates preview after delay)
     */
    fun focusChannel(channel: Channel) {
        val channels = _uiState.value.channels
        val index = channels.indexOf(channel)
        if (index < 0) return

        // Cancel any pending preview
        previewDelayJob?.cancel()

        _uiState.update {
            it.copy(
                currentIndex = index,
                focusedChannel = channel,
                isPreviewLoading = true
            )
        }

        // Start preview after short delay (avoids rapid switching)
        previewDelayJob = viewModelScope.launch {
            delay(PREVIEW_DELAY_MS)
            _uiState.update {
                it.copy(
                    previewChannel = channel,
                    isPreviewLoading = false
                )
            }
        }
    }

    /**
     * Move to next channel
     */
    fun nextChannel() {
        val state = _uiState.value
        if (state.channels.isEmpty()) return

        val nextIndex = (state.currentIndex + 1) % state.channels.size
        focusChannel(state.channels[nextIndex])
    }

    /**
     * Move to previous channel
     */
    fun previousChannel() {
        val state = _uiState.value
        if (state.channels.isEmpty()) return

        val prevIndex = if (state.currentIndex <= 0) {
            state.channels.size - 1
        } else {
            state.currentIndex - 1
        }
        focusChannel(state.channels[prevIndex])
    }

    /**
     * Jump to channel by number
     */
    fun jumpToChannel(number: Int) {
        val channel = _uiState.value.channels.find {
            it.number?.toIntOrNull() == number
        }
        channel?.let { focusChannel(it) }
    }

    /**
     * Select current channel (go to full player)
     */
    fun selectCurrentChannel(): Channel? {
        stopAutoAdvance()
        return _uiState.value.focusedChannel
    }

    /**
     * Toggle auto-advance mode (channel surfing auto-plays through channels)
     */
    fun toggleAutoAdvance() {
        if (_uiState.value.isAutoAdvancing) {
            stopAutoAdvance()
        } else {
            startAutoAdvance()
        }
    }

    private fun startAutoAdvance() {
        _uiState.update { it.copy(isAutoAdvancing = true) }

        autoAdvanceJob = viewModelScope.launch {
            while (true) {
                delay(AUTO_ADVANCE_INTERVAL_MS)
                if (_uiState.value.isAutoAdvancing) {
                    nextChannel()
                } else {
                    break
                }
            }
        }
    }

    private fun stopAutoAdvance() {
        autoAdvanceJob?.cancel()
        autoAdvanceJob = null
        _uiState.update { it.copy(isAutoAdvancing = false) }
    }

    /**
     * Filter channels by favorites only
     */
    fun toggleFavoritesFilter() {
        _uiState.update { state ->
            val newShowFavoritesOnly = !state.showFavoritesOnly
            state.copy(showFavoritesOnly = newShowFavoritesOnly)
        }
    }

    /**
     * Get filtered channels based on current filter state
     */
    fun getFilteredChannels(): List<Channel> {
        val state = _uiState.value
        return if (state.showFavoritesOnly) {
            state.channels.filter { it.favorite }
        } else {
            state.channels
        }
    }

    /**
     * Set preview speed (how long to stay on each channel in auto mode)
     */
    fun setAutoAdvanceSpeed(intervalMs: Long) {
        // Could be expanded to support different speeds
    }

    override fun onCleared() {
        super.onCleared()
        stopAutoAdvance()
        previewDelayJob?.cancel()
    }
}

/**
 * UI state for Channel Surfing screen
 */
data class ChannelSurfingUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val channels: List<Channel> = emptyList(),
    val currentIndex: Int = 0,
    val focusedChannel: Channel? = null,
    val previewChannel: Channel? = null,  // Channel currently being previewed
    val isPreviewLoading: Boolean = false,
    val isAutoAdvancing: Boolean = false,
    val showFavoritesOnly: Boolean = false
) {
    val hasChannels: Boolean
        get() = channels.isNotEmpty()

    val channelCount: Int
        get() = channels.size

    val currentPosition: String
        get() = if (hasChannels) "${currentIndex + 1} / $channelCount" else ""
}
