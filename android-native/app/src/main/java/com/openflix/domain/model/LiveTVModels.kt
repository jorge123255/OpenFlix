package com.openflix.domain.model

/**
 * Live TV and EPG domain models
 */

data class Channel(
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
    val sourceName: String?,  // Provider name (e.g., "Fubo", "YouTube TV")
    val hd: Boolean,
    val favorite: Boolean,
    val hidden: Boolean,
    val group: String?,
    val category: String?,
    val streamUrl: String?,
    val nowPlaying: Program?,
    val upNext: Program?,
    val archiveEnabled: Boolean = false,  // Whether catch-up is enabled for this channel
    val archiveDays: Int = 7              // How many days of catch-up are available
) {
    val displayName: String
        get() = if (!number.isNullOrBlank()) "$number - $name" else name

    val logoUrl: String?
        get() = logo ?: thumb

    // Provider display name with fallback
    val providerName: String
        get() = sourceName ?: group ?: "Unknown"
}

/**
 * Represents a group of channels from different providers for failover streaming.
 * When the primary channel stream fails, the system automatically tries the next channel.
 */
data class ChannelGroup(
    val id: Int,
    val name: String,
    val displayNumber: Int,
    val logo: String?,
    val channelId: String?,  // EPG channel ID for mapping
    val enabled: Boolean,
    val members: List<ChannelGroupMember>,
    val createdAt: Long?,
    val updatedAt: Long?
) {
    val memberCount: Int
        get() = members.size

    val primaryChannel: ChannelGroupMember?
        get() = members.minByOrNull { it.priority }

    val displayName: String
        get() = if (displayNumber > 0) "$displayNumber - $name" else name

    val sortedMembers: List<ChannelGroupMember>
        get() = members.sortedBy { it.priority }
}

/**
 * Represents a detected duplicate channel group from auto-detection.
 */
data class DuplicateGroup(
    val name: String,
    val channels: List<Channel>
)

/**
 * Represents a channel member within a channel group, with priority for failover ordering.
 */
data class ChannelGroupMember(
    val id: Int,
    val channelGroupId: Int,
    val channelId: Int,
    val priority: Int,  // 0 = highest priority (primary)
    val createdAt: Long?,
    val channel: Channel?  // Optional channel details
) {
    val isPrimary: Boolean
        get() = priority == 0
}

data class Program(
    val id: String?,
    val title: String,
    val subtitle: String?,
    val description: String?,
    val startTime: Long,  // Unix timestamp in seconds
    val endTime: Long,
    val duration: Long?,  // minutes
    val thumb: String?,
    val art: String?,
    val rating: String?,
    val genres: List<String>,
    val episodeTitle: String?,
    val seasonNumber: Int?,
    val episodeNumber: Int?,
    val originalAirDate: String?,
    val isNew: Boolean,
    val isLive: Boolean,
    val isPremiere: Boolean,
    val isFinale: Boolean,
    val isRepeat: Boolean,
    val isMovie: Boolean,
    val isSports: Boolean,
    val isKids: Boolean,
    val hasRecording: Boolean,
    val recordingId: String?,
    val seriesId: String?,
    val programId: String?,
    val gracenoteId: String?
) {
    val durationMs: Long
        get() = (endTime - startTime) * 1000

    val progress: Float
        get() {
            val now = System.currentTimeMillis() / 1000
            if (now < startTime) return 0f
            if (now > endTime) return 1f
            return ((now - startTime).toFloat() / (endTime - startTime).toFloat()).coerceIn(0f, 1f)
        }

    val isAiring: Boolean
        get() {
            val now = System.currentTimeMillis() / 1000
            return now in startTime..endTime
        }

    val isPast: Boolean
        get() {
            val now = System.currentTimeMillis() / 1000
            return now > endTime
        }

    val displayTitle: String
        get() = if (!episodeTitle.isNullOrBlank()) "$title: $episodeTitle" else title

    val episodeInfo: String?
        get() = if (seasonNumber != null && episodeNumber != null) {
            "S${seasonNumber}E${episodeNumber}"
        } else null

    val badges: List<ProgramBadge>
        get() = buildList {
            if (isNew) add(ProgramBadge.NEW)
            if (isLive) add(ProgramBadge.LIVE)
            if (isPremiere) add(ProgramBadge.PREMIERE)
            if (isFinale) add(ProgramBadge.FINALE)
            if (isSports) add(ProgramBadge.SPORTS)
            if (isMovie) add(ProgramBadge.MOVIE)
            if (hasRecording) add(ProgramBadge.RECORDING)
        }
}

enum class ProgramBadge {
    NEW,
    LIVE,
    PREMIERE,
    FINALE,
    SPORTS,
    MOVIE,
    RECORDING,
    CATCHUP  // Past program available for catch-up playback
}

data class ChannelWithPrograms(
    val channel: Channel,
    val programs: List<Program>
)

data class EPGData(
    val channels: List<EPGChannel>,
    val startTime: Long?,
    val endTime: Long?
)

data class EPGChannel(
    val id: String,
    val name: String,
    val number: String?,
    val logo: String?,
    val programs: List<Program>
)

// DVR Models

data class Recording(
    val id: String,
    val title: String,
    val subtitle: String?,
    val description: String?,
    val summary: String?,
    val thumb: String?,
    val art: String?,
    val channelId: String?,
    val channelName: String?,
    val channelLogo: String?,
    val startTime: Long,
    val endTime: Long,
    val duration: Long?,
    val filePath: String?,
    val fileSize: Long?,
    val status: RecordingStatus,
    val seasonNumber: Int?,
    val episodeNumber: Int?,
    val seriesId: String?,
    val programId: String?,
    val viewOffset: Long?,
    val commercials: List<Commercial>,
    val genres: String?,
    val contentRating: String?,
    val year: Int?,
    val rating: Double?,
    val isMovie: Boolean
) {
    val displayTitle: String
        get() = if (!subtitle.isNullOrBlank()) "$title - $subtitle" else title

    val episodeInfo: String?
        get() = if (seasonNumber != null && episodeNumber != null) {
            "S${seasonNumber}E${episodeNumber}"
        } else null

    val watchProgress: Float
        get() {
            val offset = viewOffset ?: 0L
            val total = duration ?: 1L
            return if (total > 0) (offset.toFloat() / total.toFloat()).coerceIn(0f, 1f) else 0f
        }

    val fileSizeDisplay: String
        get() {
            val size = fileSize ?: return ""
            return when {
                size >= 1_000_000_000 -> "%.1f GB".format(size / 1_000_000_000.0)
                size >= 1_000_000 -> "%.1f MB".format(size / 1_000_000.0)
                else -> "%.1f KB".format(size / 1_000.0)
            }
        }

    // Best available image for display
    val posterUrl: String?
        get() = thumb ?: art ?: channelLogo

    val backdropUrl: String?
        get() = art ?: thumb
}

enum class RecordingStatus {
    RECORDING,
    COMPLETED,
    FAILED,
    PENDING,
    SCHEDULED,
    CANCELLED,
    UNKNOWN;

    companion object {
        fun fromString(status: String?): RecordingStatus {
            return when (status?.lowercase()) {
                "recording" -> RECORDING
                "completed" -> COMPLETED
                "failed" -> FAILED
                "pending" -> PENDING
                "scheduled" -> SCHEDULED
                "cancelled" -> CANCELLED
                else -> UNKNOWN
            }
        }
    }
}

data class Commercial(
    val start: Long,  // milliseconds
    val end: Long
)

data class ScheduledRecording(
    val id: String,
    val title: String,
    val channelId: String?,
    val channelName: String?,
    val startTime: Long,
    val endTime: Long,
    val type: String?,  // single, series
    val seriesId: String?,
    val programId: String?,
    val status: String?
) {
    val isSeries: Boolean
        get() = type == "series"
}

// ============ DVR Conflicts ============

data class ConflictGroup(
    val recordings: List<Recording>
)

data class ConflictsData(
    val conflicts: List<ConflictGroup>,
    val hasConflicts: Boolean,
    val totalCount: Int
)

// ============ Live Recording Stats ============

data class RecordingStats(
    val id: Long,
    val title: String,
    val fileSize: Long,
    val fileSizeFormatted: String,
    val elapsedSeconds: Long,
    val elapsedFormatted: String,
    val totalSeconds: Long,
    val remainingSeconds: Long,
    val progressPercent: Double,
    val bitrate: String?,
    val isHealthy: Boolean,
    val isFailed: Boolean,
    val failureReason: String?
) {
    val progressFloat: Float
        get() = (progressPercent / 100.0).toFloat().coerceIn(0f, 1f)
}

data class RecordingStatsData(
    val stats: List<RecordingStats>,
    val activeCount: Int
) {
    fun getStatsForRecording(recordingId: String): RecordingStats? {
        return stats.find { it.id.toString() == recordingId }
    }
}

// ============ Time-Shift / Catch-Up TV Models ============

data class CatchUpProgram(
    val id: String,
    val programId: String,
    val channelId: String,
    val title: String,
    val startTime: Long,  // Unix timestamp
    val endTime: Long,
    val duration: Long,  // seconds
    val description: String?,
    val thumb: String?,
    val available: Boolean
) {
    val durationMinutes: Int
        get() = (duration / 60).toInt()

    val isRecent: Boolean
        get() {
            val hoursAgo = (System.currentTimeMillis() / 1000 - endTime) / 3600
            return hoursAgo < 2
        }
}

data class CatchUpInfo(
    val programs: List<CatchUpProgram>,
    val bufferStart: Long?,
    val bufferDuration: Long?,  // seconds
    val isBuffering: Boolean
) {
    val bufferHours: Int
        get() = ((bufferDuration ?: 0) / 3600).toInt()
}

data class StartOverInfo(
    val available: Boolean,
    val streamUrl: String?,
    val programTitle: String?,
    val programSubtitle: String?,
    val programThumb: String?,
    val secondsIntoProgram: Long,
    val isBuffering: Boolean
) {
    val minutesIntoProgram: Int
        get() = (secondsIntoProgram / 60).toInt()
}

enum class TimeShiftMode {
    LIVE,           // Watching live stream
    TIME_SHIFTED,   // Paused or rewound
    START_OVER,     // Watching from program start
    CATCH_UP        // Watching past program
}

// ============ Archive / Catch-up Models ============

/**
 * Represents an archived program available for catch-up playback.
 */
data class ArchiveProgram(
    val id: Int,
    val channelId: Int,
    val programId: Int?,
    val title: String,
    val description: String?,
    val startTime: Long,  // Unix timestamp
    val endTime: Long,
    val duration: Int,  // seconds
    val icon: String?,
    val category: String?,
    val status: String,  // available, recording, expired
    val expiresAt: Long  // Unix timestamp
) {
    val durationMinutes: Int
        get() = duration / 60

    val isAvailable: Boolean
        get() = status == "available"

    val hoursUntilExpiry: Int
        get() = ((expiresAt - System.currentTimeMillis() / 1000) / 3600).toInt()
}

/**
 * Response containing archived programs for a channel.
 */
data class ArchivedProgramsInfo(
    val programs: List<ArchiveProgram>,
    val isArchiving: Boolean,
    val archiveStart: Long?,
    val retentionDays: Int
)

/**
 * Status of archive recording for a channel.
 */
data class ArchiveChannelStatus(
    val channelId: Int,
    val channelName: String,
    val isArchiving: Boolean,
    val archiveStart: Long?,
    val retentionDays: Int,
    val programCount: Int
)

/**
 * Overall archive status for all channels.
 */
data class ArchiveStatus(
    val channels: List<ArchiveChannelStatus>,
    val totalChannels: Int,
    val activeRecording: Int
)

// ============ On Later Models ============

/**
 * Program shown in On Later browse feature.
 */
data class OnLaterProgram(
    val id: Long,
    val channelId: String,
    val title: String,
    val subtitle: String?,
    val description: String?,
    val start: Long,  // Unix timestamp
    val end: Long,
    val icon: String?,
    val art: String?,
    val category: String?,
    val isMovie: Boolean,
    val isSports: Boolean,
    val isKids: Boolean,
    val isNews: Boolean,
    val isPremiere: Boolean,
    val isNew: Boolean,
    val isLive: Boolean,
    val teams: String?,
    val league: String?,
    val rating: String?
) {
    val durationMinutes: Int
        get() = ((end - start) / 60).toInt()

    val isUpcoming: Boolean
        get() = start > System.currentTimeMillis() / 1000
}

/**
 * Channel info for On Later display.
 */
data class OnLaterChannel(
    val id: Long,
    val name: String,
    val logo: String?,
    val number: Int
)

/**
 * Combined program and channel for On Later.
 */
data class OnLaterItem(
    val program: OnLaterProgram,
    val channel: OnLaterChannel?,
    val hasRecording: Boolean,
    val recordingId: Long?
)

/**
 * Statistics for On Later categories.
 */
data class OnLaterStats(
    val movies: Int,
    val sports: Int,
    val kids: Int,
    val news: Int,
    val premieres: Int
)

/**
 * Category types for On Later browsing.
 */
enum class OnLaterCategory {
    TONIGHT,
    MOVIES,
    SPORTS,
    KIDS,
    NEWS,
    PREMIERES,
    WEEK
}

// ============ Team Pass Models ============

/**
 * Team Pass for auto-recording sports games.
 */
data class TeamPass(
    val id: Long,
    val userId: Long,
    val teamName: String,
    val teamAliases: String?,
    val league: String,
    val channelIds: String?,
    val prePadding: Int,
    val postPadding: Int,
    val keepCount: Int,
    val priority: Int,
    val enabled: Boolean,
    val upcomingCount: Int?,
    val logoUrl: String?
)

/**
 * Statistics for Team Pass.
 */
data class TeamPassStats(
    val totalPasses: Int,
    val activePasses: Int,
    val upcomingGames: Int,
    val scheduledRecordings: Int
)

/**
 * Sports team for Team Pass selection.
 */
data class SportsTeam(
    val name: String,
    val city: String,
    val nickname: String,
    val league: String?,
    val aliases: List<String>,
    val logoUrl: String?
)

/**
 * Sports leagues.
 */
enum class SportsLeague(val displayName: String) {
    NFL("NFL"),
    NBA("NBA"),
    MLB("MLB"),
    NHL("NHL"),
    MLS("MLS")
}
