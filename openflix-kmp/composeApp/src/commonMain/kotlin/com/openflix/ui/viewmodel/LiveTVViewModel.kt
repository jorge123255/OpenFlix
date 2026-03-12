package com.openflix.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.domain.model.currentTimeMs
import kotlinx.coroutines.async
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

data class GuideDay(
    val label: String,       // "Today", "Tomorrow", "Thu", "Fri", etc.
    val dateLabel: String,   // "Feb 26", "Feb 27", etc.
    val startSec: Long,      // 6am local epoch seconds
    val endSec: Long         // 6am next day epoch seconds
)

data class LiveTVUiState(
    val isLoading: Boolean = true,
    val isGuideLoading: Boolean = false,
    val error: String? = null,
    val channels: List<Channel> = emptyList(),
    val guide: List<ChannelWithPrograms> = emptyList(),
    val selectedFilter: ChannelFilter = ChannelFilter.ALL,
    val guideDays: List<GuideDay> = emptyList(),
    val selectedDayIndex: Int = 0
)

class LiveTVViewModel(
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(LiveTVUiState())
    val uiState: StateFlow<LiveTVUiState> = _uiState.asStateFlow()

    fun loadChannels() {
        // Skip reload if data already loaded
        if (_uiState.value.channels.isNotEmpty()) return

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val channels = liveTVRepository.loadChannels()
                val days = buildGuideDays()
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    channels = channels,
                    guideDays = days,
                    selectedDayIndex = 0
                )
                // Load today's guide
                loadGuideForDay(0)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message ?: "Failed to load channels")
            }
        }
    }

    fun ensureGuideLoaded() {
        if (_uiState.value.channels.isEmpty()) {
            loadChannels() // This also loads guide for day 0
        } else {
            // Channels loaded — ensure guide days exist and guide is loaded
            if (_uiState.value.guideDays.isEmpty()) {
                _uiState.value = _uiState.value.copy(guideDays = buildGuideDays(), selectedDayIndex = 0)
            }
            if (_uiState.value.guide.isEmpty() && !_uiState.value.isGuideLoading) {
                viewModelScope.launch {
                    loadGuideForDay(_uiState.value.selectedDayIndex)
                }
            }
        }
    }

    fun selectGuideDay(index: Int) {
        if (index == _uiState.value.selectedDayIndex) return
        // Keep old guide visible while loading new day (don't clear guide)
        _uiState.value = _uiState.value.copy(selectedDayIndex = index, isGuideLoading = true)
        viewModelScope.launch {
            loadGuideForDay(index)
        }
    }

    private suspend fun loadGuideForDay(dayIndex: Int) {
        val days = _uiState.value.guideDays
        if (dayIndex !in days.indices) return
        val day = days[dayIndex]

        _uiState.value = _uiState.value.copy(isGuideLoading = true)
        try {
            // Server clamps to 8h max, so split day into 3 requests (6am-2pm, 2pm-10pm, 10pm-6am)
            val mid1 = day.startSec + 8 * 3600
            val mid2 = day.startSec + 16 * 3600

            val scope = kotlinx.coroutines.coroutineScope {
                val part1 = async { runCatching { liveTVRepository.loadGuide(day.startSec, mid1) }.getOrDefault(emptyList()) }
                val part2 = async { runCatching { liveTVRepository.loadGuide(mid1, mid2) }.getOrDefault(emptyList()) }
                val part3 = async { runCatching { liveTVRepository.loadGuide(mid2, day.endSec) }.getOrDefault(emptyList()) }

                mergeGuideResults(part1.await(), part2.await(), part3.await())
            }

            _uiState.value = _uiState.value.copy(isGuideLoading = false, guide = scope)
        } catch (_: Exception) {
            _uiState.value = _uiState.value.copy(isGuideLoading = false)
        }
    }

    private fun mergeGuideResults(
        vararg parts: List<ChannelWithPrograms>
    ): List<ChannelWithPrograms> {
        // Merge by channel — combine programs from all parts, deduplicate by program ID
        val merged = mutableMapOf<String, MutableList<Program>>()
        val channelMap = mutableMapOf<String, Channel>()

        for (part in parts) {
            for (cwp in part) {
                if (cwp.channel.id !in channelMap) channelMap[cwp.channel.id] = cwp.channel
                merged.getOrPut(cwp.channel.id) { mutableListOf() }.addAll(cwp.programs)
            }
        }

        return channelMap.map { (id, channel) ->
            val programs = merged[id]
                ?.distinctBy { it.id }
                ?.sortedBy { it.startTimeMs }
                ?: emptyList()
            ChannelWithPrograms(channel, programs)
        }
    }

    private fun buildGuideDays(): List<GuideDay> {
        // Build 7 days starting from today
        val nowMs = currentTimeMs()
        val nowSec = nowMs / 1000

        // Find start of today at 6am local
        // We approximate by using the current time's day boundary
        // Server times are in UTC but the guide times come through as-is
        val daySeconds = 24 * 3600L
        val todayStartSec = (nowSec / daySeconds) * daySeconds + 6 * 3600 // ~6am UTC

        // If it's before 6am, use yesterday's 6am as "today"
        val adjustedStart = if (nowSec < todayStartSec) todayStartSec - daySeconds else todayStartSec

        val dayNames = listOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
        val monthNames = listOf("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

        return (0 until 14).map { i ->
            val startSec = adjustedStart + i * daySeconds
            val endSec = startSec + daySeconds

            // Calculate day of week and date from epoch
            // Jan 1 1970 was Thursday (index 4)
            val dayOfEpoch = (startSec / daySeconds).toInt()
            val dayOfWeek = ((dayOfEpoch + 4) % 7).let { if (it < 0) it + 7 else it }

            // Approximate month/day (good enough for display)
            val dayNum = approximateDayOfMonth(startSec)
            val monthIdx = approximateMonth(startSec)

            val label = when (i) {
                0 -> "Today"
                1 -> "Tomorrow"
                else -> dayNames[dayOfWeek]
            }
            val dateLabel = "${monthNames[monthIdx]} $dayNum"

            GuideDay(label = label, dateLabel = dateLabel, startSec = startSec, endSec = endSec)
        }
    }

    // Simple epoch-to-date approximation (UTC)
    private fun approximateMonth(epochSec: Long): Int {
        val days = (epochSec / 86400).toInt()
        // Days since epoch -> rough month calculation
        var y = 1970; var d = days
        while (true) {
            val diy = if (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) 366 else 365
            if (d < diy) break; d -= diy; y++
        }
        val leap = y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)
        val monthDays = intArrayOf(31, if (leap) 29 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
        var m = 0; while (m < 12 && d >= monthDays[m]) { d -= monthDays[m]; m++ }
        return m
    }

    private fun approximateDayOfMonth(epochSec: Long): Int {
        val days = (epochSec / 86400).toInt()
        var y = 1970; var d = days
        while (true) {
            val diy = if (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) 366 else 365
            if (d < diy) break; d -= diy; y++
        }
        val leap = y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)
        val monthDays = intArrayOf(31, if (leap) 29 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
        var m = 0; while (m < 12 && d >= monthDays[m]) { d -= monthDays[m]; m++ }
        return d + 1
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
        // Clear cached data so loadChannels() doesn't skip
        _uiState.value = _uiState.value.copy(channels = emptyList(), guide = emptyList())
        loadChannels()
    }
}
