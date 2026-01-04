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
    val thumb: String?,
    val art: String?,
    val channelId: String?,
    val channelName: String?,
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
    val commercials: List<Commercial>
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
}

enum class RecordingStatus {
    RECORDING,
    COMPLETED,
    FAILED,
    PENDING,
    UNKNOWN;

    companion object {
        fun fromString(status: String?): RecordingStatus {
            return when (status?.lowercase()) {
                "recording" -> RECORDING
                "completed" -> COMPLETED
                "failed" -> FAILED
                "pending" -> PENDING
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
