package com.openflix.data.local

import android.content.Context
import android.content.SharedPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import timber.log.Timber
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Service for tracking and storing watch statistics.
 * Tracks viewing time, content watched, and viewing habits.
 */
@Singleton
class WatchStatsService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    // ============ Watch Session Tracking ============

    private var currentSessionStart: Long = 0
    private var currentContentId: String? = null
    private var currentContentType: ContentType? = null
    private var currentContentTitle: String? = null

    /**
     * Start tracking a watch session
     */
    fun startWatchSession(
        contentId: String,
        contentType: ContentType,
        title: String
    ) {
        currentSessionStart = System.currentTimeMillis()
        currentContentId = contentId
        currentContentType = contentType
        currentContentTitle = title
        Timber.d("Started watch session: $title ($contentType)")
    }

    /**
     * End the current watch session and record stats
     */
    fun endWatchSession() {
        val contentId = currentContentId ?: return
        val contentType = currentContentType ?: return
        val title = currentContentTitle ?: return

        if (currentSessionStart == 0L) return

        val duration = System.currentTimeMillis() - currentSessionStart
        val durationMinutes = (duration / 60000).toInt()

        // Only record if watched for at least 1 minute
        if (durationMinutes >= 1) {
            recordWatchTime(contentId, contentType, title, durationMinutes)
            Timber.d("Ended watch session: $title, duration: $durationMinutes min")
        }

        // Reset session
        currentSessionStart = 0
        currentContentId = null
        currentContentType = null
        currentContentTitle = null
    }

    /**
     * Record watch time for content
     */
    private fun recordWatchTime(
        contentId: String,
        contentType: ContentType,
        title: String,
        minutes: Int
    ) {
        val today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)

        // Update total watch time
        val totalMinutes = prefs.getLong(KEY_TOTAL_WATCH_TIME, 0L) + minutes
        prefs.edit().putLong(KEY_TOTAL_WATCH_TIME, totalMinutes).apply()

        // Update daily watch time
        val dailyStats = getDailyStats().toMutableMap()
        dailyStats[today] = (dailyStats[today] ?: 0) + minutes
        saveDailyStats(dailyStats)

        // Update content type stats
        updateContentTypeStats(contentType, minutes)

        // Add to watch history
        addToHistory(contentId, contentType, title, minutes)

        // Update most watched
        updateMostWatched(contentId, contentType, title, minutes)
    }

    // ============ Statistics Retrieval ============

    /**
     * Get total watch time in minutes
     */
    fun getTotalWatchTime(): Long {
        return prefs.getLong(KEY_TOTAL_WATCH_TIME, 0L)
    }

    /**
     * Get watch time for today in minutes
     */
    fun getTodayWatchTime(): Int {
        val today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)
        return getDailyStats()[today] ?: 0
    }

    /**
     * Get watch time for this week in minutes
     */
    fun getWeekWatchTime(): Int {
        val dailyStats = getDailyStats()
        val today = LocalDate.now()
        var total = 0
        for (i in 0..6) {
            val date = today.minusDays(i.toLong()).format(DateTimeFormatter.ISO_LOCAL_DATE)
            total += dailyStats[date] ?: 0
        }
        return total
    }

    /**
     * Get watch time for this month in minutes
     */
    fun getMonthWatchTime(): Int {
        val dailyStats = getDailyStats()
        val today = LocalDate.now()
        var total = 0
        for (i in 0..29) {
            val date = today.minusDays(i.toLong()).format(DateTimeFormatter.ISO_LOCAL_DATE)
            total += dailyStats[date] ?: 0
        }
        return total
    }

    /**
     * Get daily stats for the last N days
     */
    fun getDailyStatsForDays(days: Int): List<DailyStat> {
        val dailyStats = getDailyStats()
        val today = LocalDate.now()
        return (0 until days).map { i ->
            val date = today.minusDays(i.toLong())
            val dateStr = date.format(DateTimeFormatter.ISO_LOCAL_DATE)
            DailyStat(
                date = dateStr,
                dayOfWeek = date.dayOfWeek.name.take(3),
                minutes = dailyStats[dateStr] ?: 0
            )
        }.reversed()
    }

    /**
     * Get stats by content type
     */
    fun getContentTypeStats(): Map<ContentType, Int> {
        return try {
            val statsJson = prefs.getString(KEY_CONTENT_TYPE_STATS, null) ?: return emptyMap()
            val stats = json.decodeFromString<Map<String, Int>>(statsJson)
            stats.mapKeys { ContentType.valueOf(it.key) }
        } catch (e: Exception) {
            Timber.e(e, "Failed to get content type stats")
            emptyMap()
        }
    }

    /**
     * Get recent watch history
     */
    fun getWatchHistory(limit: Int = 20): List<WatchHistoryItem> {
        return try {
            val historyJson = prefs.getString(KEY_WATCH_HISTORY, null) ?: return emptyList()
            val history = json.decodeFromString<List<WatchHistoryItem>>(historyJson)
            history.take(limit)
        } catch (e: Exception) {
            Timber.e(e, "Failed to get watch history")
            emptyList()
        }
    }

    /**
     * Get most watched content
     */
    fun getMostWatched(limit: Int = 10): List<MostWatchedItem> {
        return try {
            val mostWatchedJson = prefs.getString(KEY_MOST_WATCHED, null) ?: return emptyList()
            val mostWatched = json.decodeFromString<List<MostWatchedItem>>(mostWatchedJson)
            mostWatched.sortedByDescending { it.totalMinutes }.take(limit)
        } catch (e: Exception) {
            Timber.e(e, "Failed to get most watched")
            emptyList()
        }
    }

    /**
     * Get average daily watch time in minutes
     */
    fun getAverageDailyWatchTime(): Int {
        val dailyStats = getDailyStats()
        if (dailyStats.isEmpty()) return 0
        return dailyStats.values.sum() / dailyStats.size
    }

    /**
     * Get favorite content type
     */
    fun getFavoriteContentType(): ContentType? {
        val stats = getContentTypeStats()
        return stats.maxByOrNull { it.value }?.key
    }

    /**
     * Get total content count watched
     */
    fun getTotalContentWatched(): Int {
        return getMostWatched(Int.MAX_VALUE).size
    }

    // ============ Private Helpers ============

    private fun getDailyStats(): Map<String, Int> {
        return try {
            val statsJson = prefs.getString(KEY_DAILY_STATS, null) ?: return emptyMap()
            json.decodeFromString(statsJson)
        } catch (e: Exception) {
            Timber.e(e, "Failed to get daily stats")
            emptyMap()
        }
    }

    private fun saveDailyStats(stats: Map<String, Int>) {
        // Keep only last 90 days
        val cutoff = LocalDate.now().minusDays(90).format(DateTimeFormatter.ISO_LOCAL_DATE)
        val filtered = stats.filter { it.key >= cutoff }
        prefs.edit().putString(KEY_DAILY_STATS, json.encodeToString(filtered)).apply()
    }

    private fun updateContentTypeStats(contentType: ContentType, minutes: Int) {
        val stats = getContentTypeStats().toMutableMap()
        stats[contentType] = (stats[contentType] ?: 0) + minutes
        val statsMap = stats.mapKeys { it.key.name }
        prefs.edit().putString(KEY_CONTENT_TYPE_STATS, json.encodeToString(statsMap)).apply()
    }

    private fun addToHistory(
        contentId: String,
        contentType: ContentType,
        title: String,
        minutes: Int
    ) {
        val history = getWatchHistory(100).toMutableList()

        // Add new item at the beginning
        history.add(0, WatchHistoryItem(
            contentId = contentId,
            contentType = contentType,
            title = title,
            watchedAt = System.currentTimeMillis(),
            durationMinutes = minutes
        ))

        // Keep only last 100 items
        val trimmed = history.take(100)
        prefs.edit().putString(KEY_WATCH_HISTORY, json.encodeToString(trimmed)).apply()
    }

    private fun updateMostWatched(
        contentId: String,
        contentType: ContentType,
        title: String,
        minutes: Int
    ) {
        val mostWatched = getMostWatched(Int.MAX_VALUE).toMutableList()

        val existing = mostWatched.find { it.contentId == contentId }
        if (existing != null) {
            mostWatched.remove(existing)
            mostWatched.add(existing.copy(
                totalMinutes = existing.totalMinutes + minutes,
                watchCount = existing.watchCount + 1,
                lastWatched = System.currentTimeMillis()
            ))
        } else {
            mostWatched.add(MostWatchedItem(
                contentId = contentId,
                contentType = contentType,
                title = title,
                totalMinutes = minutes,
                watchCount = 1,
                lastWatched = System.currentTimeMillis()
            ))
        }

        prefs.edit().putString(KEY_MOST_WATCHED, json.encodeToString(mostWatched)).apply()
    }

    /**
     * Clear all watch stats (for testing or user request)
     */
    fun clearAllStats() {
        prefs.edit().clear().apply()
        Timber.d("Cleared all watch stats")
    }

    companion object {
        private const val PREFS_NAME = "watch_stats_prefs"
        private const val KEY_TOTAL_WATCH_TIME = "total_watch_time"
        private const val KEY_DAILY_STATS = "daily_stats"
        private const val KEY_CONTENT_TYPE_STATS = "content_type_stats"
        private const val KEY_WATCH_HISTORY = "watch_history"
        private const val KEY_MOST_WATCHED = "most_watched"
    }
}

/**
 * Types of content that can be watched
 */
enum class ContentType {
    MOVIE,
    TV_SHOW,
    LIVE_TV,
    DVR_RECORDING,
    SPORTS
}

/**
 * Daily watch statistics
 */
data class DailyStat(
    val date: String,
    val dayOfWeek: String,
    val minutes: Int
)

/**
 * Watch history item
 */
@Serializable
data class WatchHistoryItem(
    val contentId: String,
    val contentType: ContentType,
    val title: String,
    val watchedAt: Long,
    val durationMinutes: Int
)

/**
 * Most watched content item
 */
@Serializable
data class MostWatchedItem(
    val contentId: String,
    val contentType: ContentType,
    val title: String,
    val totalMinutes: Int,
    val watchCount: Int,
    val lastWatched: Long
)
