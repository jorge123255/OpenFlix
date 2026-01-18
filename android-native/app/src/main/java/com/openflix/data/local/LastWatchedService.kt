package com.openflix.data.local

import android.content.Context
import android.content.SharedPreferences
import com.openflix.domain.model.Channel
import com.openflix.domain.model.Program
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Service for storing and retrieving the last watched Live TV channel.
 * Used by the docked player to auto-play the last watched content.
 */
@Singleton
class LastWatchedService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }

    /**
     * Get the last watched channel, if any
     */
    fun getLastWatchedChannel(): Channel? {
        return try {
            val channelJson = prefs.getString(KEY_LAST_CHANNEL, null) ?: return null
            val stored = json.decodeFromString<StoredChannel>(channelJson)
            stored.toChannel()
        } catch (e: Exception) {
            Timber.e(e, "Failed to get last watched channel")
            null
        }
    }

    /**
     * Set the last watched channel (also adds to recent channels)
     */
    fun setLastWatchedChannel(channel: Channel) {
        try {
            val stored = StoredChannel.fromChannel(channel)
            val channelJson = json.encodeToString(stored)
            prefs.edit()
                .putString(KEY_LAST_CHANNEL, channelJson)
                .putLong(KEY_LAST_WATCHED_TIME, System.currentTimeMillis())
                .apply()
            Timber.d("Saved last watched channel: ${channel.name}")

            // Also add to recent channels
            addRecentChannel(channel)
        } catch (e: Exception) {
            Timber.e(e, "Failed to save last watched channel")
        }
    }

    /**
     * Clear the last watched channel
     */
    fun clearLastWatchedChannel() {
        prefs.edit()
            .remove(KEY_LAST_CHANNEL)
            .remove(KEY_LAST_WATCHED_TIME)
            .apply()
    }

    /**
     * Get timestamp when the channel was last watched
     */
    fun getLastWatchedTime(): Long {
        return prefs.getLong(KEY_LAST_WATCHED_TIME, 0L)
    }

    // ============ Recent Channels ============

    /**
     * Add a channel to recent channels list (max 10, most recent first)
     */
    fun addRecentChannel(channel: Channel) {
        try {
            val recentIds = getRecentChannelIds().toMutableList()

            // Remove if already exists (will be re-added at front)
            recentIds.remove(channel.id)

            // Add at front
            recentIds.add(0, channel.id)

            // Keep only last MAX_RECENT_CHANNELS
            val trimmed = recentIds.take(MAX_RECENT_CHANNELS)

            // Save IDs
            prefs.edit()
                .putString(KEY_RECENT_CHANNEL_IDS, trimmed.joinToString(","))
                .apply()

            // Also store the channel data for quick access
            val stored = StoredChannel.fromChannel(channel)
            val channelJson = json.encodeToString(stored)
            prefs.edit()
                .putString("${KEY_RECENT_CHANNEL_PREFIX}${channel.id}", channelJson)
                .apply()

            Timber.d("Added recent channel: ${channel.name} (${trimmed.size} total)")
        } catch (e: Exception) {
            Timber.e(e, "Failed to add recent channel")
        }
    }

    /**
     * Get list of recent channel IDs (most recent first)
     */
    fun getRecentChannelIds(): List<String> {
        val idsString = prefs.getString(KEY_RECENT_CHANNEL_IDS, null) ?: return emptyList()
        return idsString.split(",").filter { it.isNotBlank() }
    }

    /**
     * Get recent channels with stored data
     */
    fun getRecentChannels(): List<Channel> {
        return try {
            getRecentChannelIds().mapNotNull { id ->
                val channelJson = prefs.getString("${KEY_RECENT_CHANNEL_PREFIX}$id", null)
                    ?: return@mapNotNull null
                val stored = json.decodeFromString<StoredChannel>(channelJson)
                stored.toChannel()
            }
        } catch (e: Exception) {
            Timber.e(e, "Failed to get recent channels")
            emptyList()
        }
    }

    /**
     * Clear all recent channels
     */
    fun clearRecentChannels() {
        val ids = getRecentChannelIds()
        prefs.edit().apply {
            remove(KEY_RECENT_CHANNEL_IDS)
            ids.forEach { id ->
                remove("${KEY_RECENT_CHANNEL_PREFIX}$id")
            }
            apply()
        }
    }

    /**
     * Check if docked player is enabled in settings
     */
    fun isDockedPlayerEnabled(): Boolean {
        return prefs.getBoolean(KEY_DOCKED_PLAYER_ENABLED, true)
    }

    /**
     * Set docked player enabled state
     */
    fun setDockedPlayerEnabled(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_DOCKED_PLAYER_ENABLED, enabled).apply()
    }

    companion object {
        private const val PREFS_NAME = "last_watched_prefs"
        private const val KEY_LAST_CHANNEL = "last_channel"
        private const val KEY_LAST_WATCHED_TIME = "last_watched_time"
        private const val KEY_DOCKED_PLAYER_ENABLED = "docked_player_enabled"
        private const val KEY_RECENT_CHANNEL_IDS = "recent_channel_ids"
        private const val KEY_RECENT_CHANNEL_PREFIX = "recent_channel_"
        private const val MAX_RECENT_CHANNELS = 10
    }
}

/**
 * Serializable version of Channel for storage
 */
@Serializable
private data class StoredChannel(
    val id: String,
    val uuid: String?,
    val number: String?,
    val name: String,
    val title: String?,
    val callsign: String?,
    val logo: String?,
    val thumb: String?,
    val art: String?,
    val source: String?,
    val sourceName: String?,
    val hd: Boolean,
    val favorite: Boolean,
    val hidden: Boolean,
    val group: String?,
    val category: String?,
    val streamUrl: String?,
    val nowPlayingTitle: String?,
    val nowPlayingStartTime: Long?,
    val nowPlayingEndTime: Long?
) {
    fun toChannel(): Channel {
        val nowPlaying = if (nowPlayingTitle != null && nowPlayingStartTime != null && nowPlayingEndTime != null) {
            Program(
                id = null,
                title = nowPlayingTitle,
                subtitle = null,
                description = null,
                startTime = nowPlayingStartTime,
                endTime = nowPlayingEndTime,
                duration = null,
                thumb = null,
                art = null,
                rating = null,
                genres = emptyList(),
                episodeTitle = null,
                seasonNumber = null,
                episodeNumber = null,
                originalAirDate = null,
                isNew = false,
                isLive = true,
                isPremiere = false,
                isFinale = false,
                isRepeat = false,
                isMovie = false,
                isSports = false,
                isKids = false,
                hasRecording = false,
                recordingId = null,
                seriesId = null,
                programId = null,
                gracenoteId = null
            )
        } else null

        return Channel(
            id = id,
            uuid = uuid,
            number = number,
            name = name,
            title = title,
            callsign = callsign,
            logo = logo,
            thumb = thumb,
            art = art,
            source = source,
            sourceName = sourceName,
            hd = hd,
            favorite = favorite,
            hidden = hidden,
            group = group,
            category = category,
            streamUrl = streamUrl,
            nowPlaying = nowPlaying,
            upNext = null
        )
    }

    companion object {
        fun fromChannel(channel: Channel) = StoredChannel(
            id = channel.id,
            uuid = channel.uuid,
            number = channel.number,
            name = channel.name,
            title = channel.title,
            callsign = channel.callsign,
            logo = channel.logo,
            thumb = channel.thumb,
            art = channel.art,
            source = channel.source,
            sourceName = channel.sourceName,
            hd = channel.hd,
            favorite = channel.favorite,
            hidden = channel.hidden,
            group = channel.group,
            category = channel.category,
            streamUrl = channel.streamUrl,
            nowPlayingTitle = channel.nowPlaying?.title,
            nowPlayingStartTime = channel.nowPlaying?.startTime,
            nowPlayingEndTime = channel.nowPlaying?.endTime
        )
    }
}
