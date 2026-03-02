package com.openflix.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

enum class ChannelFilter(val label: String) {
    ALL("All channels"),
    FAVORITES("Favorites"),
    SPORTS("Sports"),
    NEWS("News"),
    MOVIES("Movies"),
    KIDS("Kids")
}

data class LiveTVUiState(
    val isLoading: Boolean = true,
    val error: String? = null,
    val channels: List<Channel> = emptyList(),
    val guide: List<ChannelWithPrograms> = emptyList(),
    val selectedFilter: ChannelFilter = ChannelFilter.ALL
)

class LiveTVViewModel(
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(LiveTVUiState())
    val uiState: StateFlow<LiveTVUiState> = _uiState.asStateFlow()

    fun loadChannels() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val channels = liveTVRepository.loadChannels()
                _uiState.value = _uiState.value.copy(isLoading = false, channels = channels)
                // Also load guide data
                loadGuide()
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message ?: "Failed to load channels")
            }
        }
    }

    private suspend fun loadGuide() {
        try {
            val guide = liveTVRepository.loadGuide()
            _uiState.value = _uiState.value.copy(guide = guide)
        } catch (_: Exception) {
            // Guide is optional — channels still work without it
        }
    }

    fun setFilter(filter: ChannelFilter) {
        _uiState.value = _uiState.value.copy(selectedFilter = filter)
    }

    fun filteredChannels(): List<Channel> {
        val state = _uiState.value
        return when (state.selectedFilter) {
            ChannelFilter.ALL -> state.channels
            ChannelFilter.FAVORITES -> state.channels.filter { it.isFavorite }
            ChannelFilter.SPORTS -> state.channels.filter { it.group?.lowercase()?.contains("sport") == true }
            ChannelFilter.NEWS -> state.channels.filter { it.group?.lowercase()?.contains("news") == true }
            ChannelFilter.MOVIES -> state.channels.filter { it.group?.lowercase()?.contains("movie") == true }
            ChannelFilter.KIDS -> state.channels.filter { it.group?.lowercase()?.contains("kid") == true }
        }
    }

    fun programsForChannel(channelId: String): List<Program> {
        return _uiState.value.guide.firstOrNull { it.channel.id == channelId }?.programs ?: emptyList()
    }

    fun currentProgram(channelId: String): Program? {
        return _uiState.value.guide.firstOrNull { it.channel.id == channelId }?.currentProgram
    }

    fun nextProgram(channelId: String): Program? {
        val programs = programsForChannel(channelId)
        val current = currentProgram(channelId) ?: return programs.firstOrNull()
        return programs.firstOrNull { it.startTimeMs >= current.endTimeMs }
    }

    fun refresh() {
        loadChannels()
    }
}
