package com.openflix.domain.model

data class Program(
    val id: String,
    val title: String,
    val subtitle: String? = null,
    val description: String? = null,
    val startTimeMs: Long,
    val endTimeMs: Long,
    val duration: Int,
    val icon: String? = null,
    val art: String? = null,
    val rating: String? = null,
    val category: String? = null,
    val isNew: Boolean = false,
    val isLive: Boolean = false,
    val isPremiere: Boolean = false,
    val isFinale: Boolean = false,
    val isSports: Boolean = false,
    val isKids: Boolean = false,
    val teams: String? = null,
    val league: String? = null,
    val hasRecording: Boolean = false,
    val recordingId: String? = null
) {
    val isCurrentlyAiring: Boolean get() {
        val now = currentTimeMs()
        return startTimeMs <= now && endTimeMs > now
    }

    val hasStarted: Boolean get() = currentTimeMs() >= startTimeMs

    val hasEnded: Boolean get() = currentTimeMs() >= endTimeMs

    val progress: Double get() {
        if (!isCurrentlyAiring) return if (hasEnded) 1.0 else 0.0
        val total = (endTimeMs - startTimeMs).toDouble()
        val elapsed = (currentTimeMs() - startTimeMs).toDouble()
        return (elapsed / total).coerceIn(0.0, 1.0)
    }

    val remainingMinutes: Int get() {
        if (hasEnded) return 0
        return ((endTimeMs - currentTimeMs()) / 60000).toInt()
    }

    val fullTitle: String get() {
        if (!subtitle.isNullOrEmpty()) return "$title: $subtitle"
        return title
    }

    val badges: List<String> get() {
        val result = mutableListOf<String>()
        if (isNew) result.add("NEW")
        if (isLive) result.add("LIVE")
        if (isPremiere) result.add("PREMIERE")
        if (isFinale) result.add("FINALE")
        if (hasRecording) result.add("REC")
        return result
    }
}
