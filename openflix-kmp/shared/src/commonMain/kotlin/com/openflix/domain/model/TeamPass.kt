package com.openflix.domain.model

data class TeamPass(
    val id: Int,
    val teamName: String,
    val teamAliases: List<String> = emptyList(),
    val league: String,
    val channelIds: List<String> = emptyList(),
    val prePadding: Int = 5,
    val postPadding: Int = 60,
    val keepCount: Int = 0,
    val priority: Int = 0,
    val enabled: Boolean = true,
    val upcomingCount: Int = 0,
    val logoUrl: String? = null
) {
    val displayName: String get() = "$teamName ($league)"
}

data class Team(
    val name: String,
    val aliases: List<String> = emptyList(),
    val logo: String? = null
)

data class OnLaterStats(
    val movies: Int = 0,
    val sports: Int = 0,
    val kids: Int = 0,
    val news: Int = 0,
    val premieres: Int = 0
) {
    val total: Int get() = movies + sports + kids + news + premieres
}

data class OnLaterProgram(
    val channelId: String,
    val channelName: String,
    val channelLogo: String? = null,
    val channelNumber: Int? = null,
    val program: Program
) {
    val id: String get() = "$channelId-${program.id}"
}
