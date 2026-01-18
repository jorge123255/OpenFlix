package com.openflix.presentation.screens.catchup

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.ArchiveProgram
import com.openflix.domain.model.ArchivedProgramsInfo
import com.openflix.domain.model.Channel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for the Catch-up TV screen.
 * Manages channels with archive/catch-up enabled and their available programs.
 */
@HiltViewModel
class CatchupViewModel @Inject constructor(
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CatchupUiState())
    val uiState: StateFlow<CatchupUiState> = _uiState.asStateFlow()

    init {
        loadCatchupChannels()
    }

    /**
     * Load all channels that have catch-up/archive enabled
     */
    fun loadCatchupChannels() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = liveTVRepository.getChannels()

            result.fold(
                onSuccess = { channels ->
                    // Filter to only channels with archive enabled
                    val catchupChannels = channels.filter { it.archiveEnabled }
                    Timber.d("Found ${catchupChannels.size} channels with catch-up enabled")

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            channels = catchupChannels
                        )
                    }

                    // Auto-select first channel if available
                    if (catchupChannels.isNotEmpty() && _uiState.value.selectedChannel == null) {
                        selectChannel(catchupChannels.first())
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load channels")
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
     * Select a channel and load its archived programs
     */
    fun selectChannel(channel: Channel) {
        _uiState.update {
            it.copy(
                selectedChannel = channel,
                archivedPrograms = emptyList(),
                isLoadingPrograms = true
            )
        }

        viewModelScope.launch {
            val result = liveTVRepository.getArchivedPrograms(channel.id)

            result.fold(
                onSuccess = { info ->
                    Timber.d("Loaded ${info.programs.size} archived programs for ${channel.name}")
                    _uiState.update {
                        it.copy(
                            isLoadingPrograms = false,
                            archivedPrograms = info.programs.filter { p -> p.isAvailable },
                            archiveInfo = info
                        )
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load archived programs")
                    _uiState.update {
                        it.copy(
                            isLoadingPrograms = false,
                            archivedPrograms = emptyList()
                        )
                    }
                }
            )
        }
    }

    /**
     * Filter programs by date
     */
    fun filterByDate(dayOffset: Int) {
        _uiState.update { it.copy(selectedDayOffset = dayOffset) }
    }

    /**
     * Get programs filtered by selected day
     */
    fun getFilteredPrograms(): List<ArchiveProgram> {
        val state = _uiState.value
        val now = System.currentTimeMillis() / 1000
        val dayStart = now - (state.selectedDayOffset * 24 * 3600) - (now % 86400)
        val dayEnd = dayStart + 86400

        return state.archivedPrograms.filter { program ->
            program.startTime >= dayStart && program.startTime < dayEnd
        }.sortedByDescending { it.startTime }
    }

    /**
     * Refresh data
     */
    fun refresh() {
        loadCatchupChannels()
        _uiState.value.selectedChannel?.let { selectChannel(it) }
    }
}

/**
 * UI state for Catch-up screen
 */
data class CatchupUiState(
    val isLoading: Boolean = false,
    val isLoadingPrograms: Boolean = false,
    val error: String? = null,
    val channels: List<Channel> = emptyList(),
    val selectedChannel: Channel? = null,
    val archivedPrograms: List<ArchiveProgram> = emptyList(),
    val archiveInfo: ArchivedProgramsInfo? = null,
    val selectedDayOffset: Int = 0  // 0 = today, 1 = yesterday, etc.
) {
    val hasChannels: Boolean
        get() = channels.isNotEmpty()

    val retentionDays: Int
        get() = archiveInfo?.retentionDays ?: 7

    val dayOptions: List<DayOption>
        get() = (0 until retentionDays).map { offset ->
            DayOption(
                offset = offset,
                label = when (offset) {
                    0 -> "Today"
                    1 -> "Yesterday"
                    else -> "$offset days ago"
                }
            )
        }
}

data class DayOption(
    val offset: Int,
    val label: String
)
