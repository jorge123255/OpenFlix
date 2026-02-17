package com.openflix.presentation.screens.watchstats

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.local.ContentType
import com.openflix.data.local.DailyStat
import com.openflix.data.local.MostWatchedItem
import com.openflix.data.local.WatchHistoryItem
import com.openflix.data.local.WatchStatsService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

/**
 * ViewModel for the Watch Stats screen.
 * Provides viewing statistics and history data.
 */
@HiltViewModel
class WatchStatsViewModel @Inject constructor(
    private val watchStatsService: WatchStatsService
) : ViewModel() {

    private val _uiState = MutableStateFlow(WatchStatsUiState())
    val uiState: StateFlow<WatchStatsUiState> = _uiState.asStateFlow()

    init {
        loadStats()
    }

    fun loadStats() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            try {
                val totalMinutes = watchStatsService.getTotalWatchTime()
                val todayMinutes = watchStatsService.getTodayWatchTime()
                val weekMinutes = watchStatsService.getWeekWatchTime()
                val monthMinutes = watchStatsService.getMonthWatchTime()
                val averageDaily = watchStatsService.getAverageDailyWatchTime()
                val contentTypeStats = watchStatsService.getContentTypeStats()
                val dailyStats = watchStatsService.getDailyStatsForDays(14)
                val watchHistory = watchStatsService.getWatchHistory(20)
                val mostWatched = watchStatsService.getMostWatched(10)
                val favoriteType = watchStatsService.getFavoriteContentType()
                val totalContent = watchStatsService.getTotalContentWatched()

                _uiState.update {
                    it.copy(
                        isLoading = false,
                        totalWatchTime = totalMinutes,
                        todayWatchTime = todayMinutes,
                        weekWatchTime = weekMinutes,
                        monthWatchTime = monthMinutes,
                        averageDailyTime = averageDaily,
                        contentTypeStats = contentTypeStats,
                        dailyStats = dailyStats,
                        watchHistory = watchHistory,
                        mostWatched = mostWatched,
                        favoriteContentType = favoriteType,
                        totalContentWatched = totalContent
                    )
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load stats"
                    )
                }
            }
        }
    }

    fun clearAllStats() {
        viewModelScope.launch {
            watchStatsService.clearAllStats()
            loadStats()
        }
    }

    fun refresh() {
        loadStats()
    }
}

/**
 * UI state for Watch Stats screen
 */
data class WatchStatsUiState(
    val isLoading: Boolean = false,
    val error: String? = null,
    val totalWatchTime: Long = 0,
    val todayWatchTime: Int = 0,
    val weekWatchTime: Int = 0,
    val monthWatchTime: Int = 0,
    val averageDailyTime: Int = 0,
    val contentTypeStats: Map<ContentType, Int> = emptyMap(),
    val dailyStats: List<DailyStat> = emptyList(),
    val watchHistory: List<WatchHistoryItem> = emptyList(),
    val mostWatched: List<MostWatchedItem> = emptyList(),
    val favoriteContentType: ContentType? = null,
    val totalContentWatched: Int = 0
) {
    /**
     * Format minutes as human readable string
     */
    fun formatTime(minutes: Int): String {
        return when {
            minutes < 60 -> "${minutes}m"
            minutes < 1440 -> "${minutes / 60}h ${minutes % 60}m"
            else -> "${minutes / 1440}d ${(minutes % 1440) / 60}h"
        }
    }

    fun formatTime(minutes: Long): String = formatTime(minutes.toInt())

    /**
     * Get the maximum daily stat value for chart scaling
     */
    val maxDailyMinutes: Int
        get() = dailyStats.maxOfOrNull { it.minutes } ?: 1
}
