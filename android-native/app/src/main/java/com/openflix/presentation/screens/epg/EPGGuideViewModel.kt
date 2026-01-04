package com.openflix.presentation.screens.epg

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import java.util.Calendar
import javax.inject.Inject

/**
 * ViewModel for the EPG Guide screen.
 * Manages EPG data and navigation state.
 */
@HiltViewModel
class EPGGuideViewModel @Inject constructor(
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(EPGGuideUiState())
    val uiState: StateFlow<EPGGuideUiState> = _uiState.asStateFlow()

    // Hours to show in the guide (typically 6 hours)
    private val hoursToShow = 6

    init {
        loadGuideData()
    }

    fun loadGuideData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            // Calculate time range: 1 hour ago to 6 hours from now
            val now = System.currentTimeMillis() / 1000
            val startTime = now - 3600 // 1 hour ago
            val endTime = now + (hoursToShow * 3600) // 6 hours ahead

            liveTVRepository.getGuide(startTime, endTime)
                .onSuccess { guideData ->
                    // Extract categories
                    val categories = guideData
                        .mapNotNull { it.channel.group }
                        .filter { it.isNotBlank() }
                        .distinct()
                        .sorted()

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            channelsWithPrograms = guideData,
                            categories = listOf("All") + categories,
                            startTimeSeconds = startTime,
                            endTimeSeconds = endTime
                        )
                    }
                }
                .onFailure { e ->
                    Timber.e(e, "Failed to load EPG guide")
                    _uiState.update {
                        it.copy(isLoading = false, error = e.message)
                    }
                }
        }
    }

    fun setFocusedChannel(index: Int) {
        val state = _uiState.value
        val filteredChannels = getFilteredChannels()
        if (index in filteredChannels.indices) {
            _uiState.update {
                it.copy(focusedChannelIndex = index, focusedProgramIndex = 0)
            }
        }
    }

    fun setFocusedProgram(index: Int) {
        _uiState.update { it.copy(focusedProgramIndex = index) }
    }

    fun moveFocusUp() {
        val state = _uiState.value
        if (state.focusedChannelIndex > 0) {
            _uiState.update {
                it.copy(
                    focusedChannelIndex = it.focusedChannelIndex - 1,
                    focusedProgramIndex = 0
                )
            }
        }
    }

    fun moveFocusDown() {
        val state = _uiState.value
        val filteredChannels = getFilteredChannels()
        if (state.focusedChannelIndex < filteredChannels.size - 1) {
            _uiState.update {
                it.copy(
                    focusedChannelIndex = it.focusedChannelIndex + 1,
                    focusedProgramIndex = 0
                )
            }
        }
    }

    fun moveFocusLeft() {
        val state = _uiState.value
        if (state.focusedProgramIndex > 0) {
            _uiState.update { it.copy(focusedProgramIndex = it.focusedProgramIndex - 1) }
        }
    }

    fun moveFocusRight() {
        val state = _uiState.value
        val focusedChannel = getFocusedChannel()
        val programs = focusedChannel?.programs ?: emptyList()
        if (state.focusedProgramIndex < programs.size - 1) {
            _uiState.update { it.copy(focusedProgramIndex = it.focusedProgramIndex + 1) }
        }
    }

    fun setCategory(category: String) {
        _uiState.update {
            it.copy(
                selectedCategory = category,
                focusedChannelIndex = 0,
                focusedProgramIndex = 0
            )
        }
    }

    fun toggleFavoritesOnly() {
        _uiState.update {
            it.copy(
                showFavoritesOnly = !it.showFavoritesOnly,
                focusedChannelIndex = 0,
                focusedProgramIndex = 0
            )
        }
    }

    fun toggleSidebar() {
        _uiState.update { it.copy(sidebarExpanded = !it.sidebarExpanded) }
    }

    fun getFilteredChannels(): List<ChannelWithPrograms> {
        val state = _uiState.value
        var channels = state.channelsWithPrograms

        if (state.showFavoritesOnly) {
            channels = channels.filter { it.channel.favorite }
        }

        if (state.selectedCategory != "All") {
            channels = channels.filter { it.channel.group == state.selectedCategory }
        }

        return channels
    }

    fun getFocusedChannel(): ChannelWithPrograms? {
        val filtered = getFilteredChannels()
        val state = _uiState.value
        return filtered.getOrNull(state.focusedChannelIndex)
    }

    fun getFocusedProgram(): Program? {
        val channel = getFocusedChannel() ?: return null
        val state = _uiState.value
        return channel.programs.getOrNull(state.focusedProgramIndex)
    }

    fun scrollToNow() {
        // Reset program focus to current time
        _uiState.update { it.copy(focusedProgramIndex = 0, scrollToNow = true) }
    }

    fun clearScrollToNow() {
        _uiState.update { it.copy(scrollToNow = false) }
    }

    // ==================== Tivimate-style EPG Features ====================

    /**
     * Navigate to previous day's guide
     */
    fun previousDay() {
        val newOffset = _uiState.value.currentDateOffset - 1
        if (newOffset >= -7) { // Allow up to 7 days back
            _uiState.update { it.copy(currentDateOffset = newOffset) }
            loadGuideDataForDay(newOffset)
        }
    }

    /**
     * Navigate to next day's guide
     */
    fun nextDay() {
        val newOffset = _uiState.value.currentDateOffset + 1
        if (newOffset <= 7) { // Allow up to 7 days ahead
            _uiState.update { it.copy(currentDateOffset = newOffset) }
            loadGuideDataForDay(newOffset)
        }
    }

    /**
     * Go to today's guide
     */
    fun goToToday() {
        _uiState.update { it.copy(currentDateOffset = 0) }
        loadGuideDataForDay(0)
        scrollToNow()
    }

    /**
     * Jump to prime time (8:00 PM)
     */
    fun jumpToPrimeTime() {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 20) // 8 PM
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
        }

        val state = _uiState.value
        val primeTimeSeconds = calendar.timeInMillis / 1000
        val minutesFromStart = ((primeTimeSeconds - state.startTimeSeconds) / 60).toInt()

        _uiState.update { it.copy(scrollToTimeOffset = minutesFromStart) }
    }

    /**
     * Jump timeline by hours (+/- hours)
     */
    fun jumpTimelineByHours(hours: Int) {
        val state = _uiState.value
        val currentOffset = state.scrollToTimeOffset ?: 0
        val newOffset = (currentOffset + (hours * 60)).coerceIn(
            0,
            ((state.endTimeSeconds - state.startTimeSeconds) / 60).toInt()
        )
        _uiState.update { it.copy(scrollToTimeOffset = newOffset) }
    }

    fun clearTimelineScrollOffset() {
        _uiState.update { it.copy(scrollToTimeOffset = null) }
    }

    /**
     * Move focus up by a page (10 channels)
     */
    fun pageUp() {
        val state = _uiState.value
        val newIndex = (state.focusedChannelIndex - 10).coerceAtLeast(0)
        _uiState.update { it.copy(focusedChannelIndex = newIndex, focusedProgramIndex = 0) }
    }

    /**
     * Move focus down by a page (10 channels)
     */
    fun pageDown() {
        val state = _uiState.value
        val filteredChannels = getFilteredChannels()
        val newIndex = (state.focusedChannelIndex + 10).coerceAtMost(filteredChannels.size - 1)
        _uiState.update { it.copy(focusedChannelIndex = newIndex, focusedProgramIndex = 0) }
    }

    /**
     * Handle number key input for channel jump
     */
    fun appendChannelNumber(digit: Char) {
        val currentInput = _uiState.value.channelNumberInput
        val newInput = currentInput + digit
        _uiState.update { it.copy(channelNumberInput = newInput) }
    }

    /**
     * Jump to channel by number
     */
    fun jumpToChannelNumber() {
        val channelNumber = _uiState.value.channelNumberInput
        if (channelNumber.isNotEmpty()) {
            val filtered = getFilteredChannels()
            val index = filtered.indexOfFirst { it.channel.number == channelNumber }
            if (index >= 0) {
                _uiState.update {
                    it.copy(
                        focusedChannelIndex = index,
                        focusedProgramIndex = 0,
                        channelNumberInput = ""
                    )
                }
            } else {
                // Channel not found, just clear input
                _uiState.update { it.copy(channelNumberInput = "") }
            }
        }
    }

    fun clearChannelNumberInput() {
        _uiState.update { it.copy(channelNumberInput = "") }
    }

    /**
     * Show record dialog for focused program
     */
    fun showRecordDialog() {
        val program = getFocusedProgram()
        if (program != null) {
            _uiState.update {
                it.copy(showRecordDialog = true, selectedProgramForAction = program)
            }
        }
    }

    /**
     * Show reminder dialog for focused program
     */
    fun showReminderDialog() {
        val program = getFocusedProgram()
        if (program != null) {
            _uiState.update {
                it.copy(showReminderDialog = true, selectedProgramForAction = program)
            }
        }
    }

    fun dismissDialogs() {
        _uiState.update {
            it.copy(
                showRecordDialog = false,
                showReminderDialog = false,
                selectedProgramForAction = null
            )
        }
    }

    /**
     * Get the display date string for current view
     */
    fun getDisplayDateString(): String {
        val calendar = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, _uiState.value.currentDateOffset)
        }
        return when (_uiState.value.currentDateOffset) {
            -1 -> "Yesterday"
            0 -> "Today"
            1 -> "Tomorrow"
            else -> {
                val format = java.text.SimpleDateFormat("EEEE, MMM d", java.util.Locale.getDefault())
                format.format(calendar.time)
            }
        }
    }

    /**
     * Load guide data for a specific day offset
     */
    private fun loadGuideDataForDay(dayOffset: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val calendar = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, dayOffset)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
            }

            val startTime = calendar.timeInMillis / 1000
            val endTime = startTime + (24 * 3600) // Full day

            liveTVRepository.getGuide(startTime, endTime)
                .onSuccess { guideData ->
                    val categories = guideData
                        .mapNotNull { it.channel.group }
                        .filter { it.isNotBlank() }
                        .distinct()
                        .sorted()

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            channelsWithPrograms = guideData,
                            categories = listOf("All") + categories,
                            startTimeSeconds = startTime,
                            endTimeSeconds = endTime,
                            focusedChannelIndex = 0,
                            focusedProgramIndex = 0
                        )
                    }
                }
                .onFailure { e ->
                    Timber.e(e, "Failed to load EPG guide for day offset $dayOffset")
                    _uiState.update {
                        it.copy(isLoading = false, error = e.message)
                    }
                }
        }
    }
}

data class EPGGuideUiState(
    val isLoading: Boolean = true,
    val error: String? = null,
    val channelsWithPrograms: List<ChannelWithPrograms> = emptyList(),
    val categories: List<String> = listOf("All"),
    val selectedCategory: String = "All",
    val showFavoritesOnly: Boolean = false,
    val sidebarExpanded: Boolean = true,
    val focusedChannelIndex: Int = 0,
    val focusedProgramIndex: Int = 0,
    val startTimeSeconds: Long = 0,
    val endTimeSeconds: Long = 0,
    val scrollToNow: Boolean = false,
    // New Tivimate-style features
    val currentDateOffset: Int = 0, // 0 = today, -1 = yesterday, 1 = tomorrow
    val channelNumberInput: String = "",
    val showRecordDialog: Boolean = false,
    val showReminderDialog: Boolean = false,
    val selectedProgramForAction: Program? = null,
    val scrollToTimeOffset: Int? = null // Offset in minutes from start to scroll to
)

/**
 * Genre-based colors for program blocks
 */
object EPGGenreColors {
    fun getColor(category: String?): Long {
        if (category.isNullOrBlank()) return 0xFF374151 // Gray
        val g = category.lowercase()
        return when {
            g.contains("sport") -> 0xFF10B981 // Emerald
            g.contains("news") -> 0xFF3B82F6 // Blue
            g.contains("movie") || g.contains("film") -> 0xFF8B5CF6 // Violet
            g.contains("series") || g.contains("drama") -> 0xFFF97316 // Orange
            g.contains("entertainment") -> 0xFFEC4899 // Pink
            g.contains("documentary") || g.contains("doc") -> 0xFF14B8A6 // Teal
            g.contains("kids") || g.contains("children") -> 0xFFF472B6 // Pink
            g.contains("music") -> 0xFFEF4444 // Red
            g.contains("comedy") -> 0xFFFBBF24 // Amber
            else -> 0xFF6366F1 // Indigo default
        }
    }
}
