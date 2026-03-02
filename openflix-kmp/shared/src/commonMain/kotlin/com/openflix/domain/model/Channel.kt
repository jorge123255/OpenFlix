package com.openflix.domain.model

data class Channel(
    val id: String,
    val number: Int? = null,
    val name: String,
    val logo: String? = null,
    val sourceId: String? = null,
    val sourceName: String? = null,
    val streamUrl: String? = null,
    val enabled: Boolean = true,
    val isFavorite: Boolean = false,
    val group: String? = null,
    val archiveEnabled: Boolean = false,
    val archiveDays: Int = 0,
    var nowPlaying: Program? = null,
    var nextProgram: Program? = null
) {
    val displayNumber: String get() = number?.toString() ?: ""

    val displayName: String get() = if (number != null) "$number - $name" else name

    val isHD: Boolean get() {
        val upper = name.uppercase()
        return upper.contains("HD") || upper.contains("FHD") ||
               upper.contains("4K") || upper.contains("UHD")
    }

    val sortKey: Double get() = number?.toDouble() ?: Double.MAX_VALUE
}

data class ChannelGroup(
    val id: Int,
    val name: String,
    val enabled: Boolean = true,
    val members: List<ChannelGroupMember> = emptyList()
)

data class ChannelGroupMember(
    val channelId: String,
    val priority: Int,
    val channelName: String? = null
)

data class ChannelWithPrograms(
    val channel: Channel,
    val programs: List<Program> = emptyList()
) {
    val id: String get() = channel.id

    fun programAt(timestamp: Long): Program? {
        return programs.firstOrNull { it.startTimeMs <= timestamp && it.endTimeMs > timestamp }
    }

    val currentProgram: Program? get() = programAt(currentTimeMs())

    val upcomingPrograms: List<Program> get() {
        val now = currentTimeMs()
        return programs.filter { it.startTimeMs > now }.sortedBy { it.startTimeMs }
    }
}

expect fun currentTimeMs(): Long
