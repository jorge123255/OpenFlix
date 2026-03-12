package com.openflix.domain.model

enum class RecordingStatus(val value: String) {
    SCHEDULED("scheduled"),
    RECORDING("recording"),
    COMPLETED("completed"),
    FAILED("failed");

    val displayName: String get() = when (this) {
        SCHEDULED -> "Scheduled"
        RECORDING -> "Recording"
        COMPLETED -> "Completed"
        FAILED -> "Failed"
    }

    companion object {
        fun fromValue(value: String): RecordingStatus =
            entries.firstOrNull { it.value == value } ?: SCHEDULED
    }
}

data class Recording(
    val id: Int,
    val title: String,
    val subtitle: String? = null,
    val description: String? = null,
    val thumb: String? = null,
    val art: String? = null,
    val channelId: String? = null,
    val channelName: String? = null,
    val channelLogo: String? = null,
    val startTimeMs: Long,
    val endTimeMs: Long,
    val duration: Int,
    val status: RecordingStatus,
    val filePath: String? = null,
    val fileSize: Int? = null,
    val seasonNumber: Int? = null,
    val episodeNumber: Int? = null,
    val seriesRecord: Boolean = false,
    val seriesRuleId: Int? = null,
    val genres: List<String> = emptyList(),
    val contentRating: String? = null,
    val year: Int? = null,
    val rating: Double? = null,
    val isMovie: Boolean = false,
    val viewOffset: Int? = null,
    val commercials: List<Commercial> = emptyList(),
    val priority: Int = 50
) {
    val episodeLabel: String? get() {
        val s = seasonNumber ?: return null
        val e = episodeNumber ?: return null
        return "S$s E$e"
    }

    val fullTitle: String get() {
        val label = episodeLabel
        return when {
            label != null && subtitle != null -> "$title - $label - $subtitle"
            subtitle != null -> "$title: $subtitle"
            else -> title
        }
    }

    val progressPercent: Double get() {
        if (duration <= 0) return 0.0
        val offset = viewOffset ?: return 0.0
        return offset.toDouble() / duration.toDouble()
    }

    val isInProgress: Boolean get() = progressPercent > 0 && progressPercent < 0.9

    val isUpcoming: Boolean get() = status == RecordingStatus.SCHEDULED && startTimeMs > currentTimeMs()

    val isCurrentlyRecording: Boolean get() = status == RecordingStatus.RECORDING
}

data class Commercial(
    val start: Int,
    val end: Int
) {
    val duration: Int get() = end - start
    val startSeconds: Int get() = start / 1000
    val endSeconds: Int get() = end / 1000
}

data class SeriesRule(
    val id: Int,
    val title: String,
    val channelId: String? = null,
    val enabled: Boolean = true,
    val prePadding: Int = 0,
    val postPadding: Int = 0,
    val keepCount: Int = 0,
    val recordingCount: Int = 0
)
