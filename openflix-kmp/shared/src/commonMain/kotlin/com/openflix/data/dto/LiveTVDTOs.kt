package com.openflix.data.dto

import com.openflix.domain.model.*
import kotlinx.serialization.Serializable

@Serializable
data class ChannelsResponse(val channels: List<ChannelDTO>? = null) {
    val allChannels: List<ChannelDTO> get() = channels ?: emptyList()
}

@Serializable
data class ChannelDTO(
    val id: StringOrInt? = null,
    val channelId: String? = null,
    val tvgId: String? = null,
    val number: Int? = null,
    val name: String? = null,
    val title: String? = null,
    val callsign: String? = null,
    val logo: String? = null,
    val thumb: String? = null,
    val art: String? = null,
    val sourceId: StringOrInt? = null,
    val sourceName: String? = null,
    val streamUrl: String? = null,
    val enabled: Boolean? = null,
    val hd: Boolean? = null,
    val isFavorite: Boolean? = null,
    val group: String? = null,
    val category: String? = null,
    val archiveEnabled: Boolean? = null,
    val archiveDays: Int? = null,
    val nowPlaying: ProgramDTO? = null,
    val nextProgram: ProgramDTO? = null
) {
    val safeId: String get() = id?.stringValue ?: ""
    val safeName: String get() = name ?: title ?: "Unknown Channel"
    val epgId: String get() = channelId ?: tvgId ?: id?.stringValue ?: ""

    fun toDomain() = Channel(
        id = safeId,
        channelId = channelId ?: tvgId ?: "",
        number = number,
        name = safeName,
        logo = logo ?: thumb,
        sourceId = sourceId?.stringValue,
        sourceName = sourceName,
        streamUrl = streamUrl,
        enabled = enabled ?: true,
        isFavorite = isFavorite ?: false,
        group = group ?: category,
        archiveEnabled = archiveEnabled ?: false,
        archiveDays = archiveDays ?: 0,
        nowPlaying = nowPlaying?.toDomain(),
        nextProgram = nextProgram?.toDomain()
    )
}

@Serializable
data class ProgramDTO(
    val id: StringOrInt? = null,
    val title: String? = null,
    val subtitle: String? = null,
    val description: String? = null,
    val start: String? = null,
    val end: String? = null,
    val startTime: Long? = null,
    val endTime: Long? = null,
    val duration: Int? = null,
    val icon: String? = null,
    val art: String? = null,
    val rating: String? = null,
    val category: String? = null,
    val isNew: Boolean? = null,
    val isLive: Boolean? = null,
    val isPremiere: Boolean? = null,
    val isFinale: Boolean? = null,
    val isSports: Boolean? = null,
    val isKids: Boolean? = null,
    val teams: String? = null,
    val league: String? = null,
    val hasRecording: Boolean? = null,
    val recordingId: StringOrInt? = null
) {
    val safeId: String get() = id?.stringValue ?: ""
    val safeTitle: String get() = title ?: "Unknown Program"

    val startDateMs: Long? get() {
        if (startTime != null) return startTime * 1000
        start?.let { return parseIso8601(it) }
        return null
    }

    val endDateMs: Long? get() {
        if (endTime != null) return endTime * 1000
        end?.let { return parseIso8601(it) }
        return null
    }

    fun toDomain(): Program {
        val startMs = startDateMs ?: currentTimeMs()
        val dur = duration ?: 30
        val endMs = endDateMs ?: (startMs + dur * 60 * 1000L)
        val actualDuration = if (duration != null) duration else ((endMs - startMs) / 60000).toInt()

        return Program(
            id = safeId.ifEmpty { generateUuid() },
            title = safeTitle,
            subtitle = subtitle,
            description = description,
            startTimeMs = startMs,
            endTimeMs = endMs,
            duration = actualDuration,
            icon = icon,
            art = art,
            rating = rating,
            category = category,
            isNew = isNew ?: false,
            isLive = isLive ?: false,
            isPremiere = isPremiere ?: false,
            isFinale = isFinale ?: false,
            isSports = isSports ?: false,
            isKids = isKids ?: false,
            teams = teams,
            league = league,
            hasRecording = hasRecording ?: false,
            recordingId = recordingId?.stringValue
        )
    }
}

@Serializable
data class GuideResponse(
    val channels: List<ChannelDTO>? = null,
    val programs: Map<String, List<ProgramDTO>>? = null,
    val start: String? = null,
    val end: String? = null
) {
    val allChannels: List<ChannelDTO> get() = channels ?: emptyList()
    fun programsForChannel(id: String): List<ProgramDTO> = programs?.get(id) ?: emptyList()
}

@Serializable
data class ChannelStreamResponse(val url: String, val format: String? = null)

@Serializable
data class NowPlayingResponse(val channels: List<ChannelNowPlayingDTO>? = null)

@Serializable
data class ChannelNowPlayingDTO(
    val channelId: String? = null,
    val channelName: String? = null,
    val channelLogo: String? = null,
    val program: ProgramDTO? = null
)

// Sources
@Serializable
data class M3USourcesResponse(val sources: List<M3USourceDTO> = emptyList())

@Serializable
data class M3USourceDTO(
    val id: Int,
    val name: String,
    val url: String,
    val epgUrl: String? = null,
    val enabled: Boolean? = null,
    val lastFetched: String? = null,
    val importVod: Boolean? = null,
    val importSeries: Boolean? = null,
    val vodLibraryId: Int? = null,
    val seriesLibraryId: Int? = null,
    val channelCount: Int? = null
) {
    fun toDomain() = M3USource(
        id = id, name = name, url = url, epgUrl = epgUrl,
        enabled = enabled ?: true,
        lastFetched = lastFetched?.let { parseIso8601(it) },
        importVod = importVod ?: false,
        importSeries = importSeries ?: false,
        vodLibraryId = vodLibraryId,
        seriesLibraryId = seriesLibraryId,
        channelCount = channelCount ?: 0
    )
}

@Serializable
data class XtreamSourcesResponse(val sources: List<XtreamSourceDTO> = emptyList())

@Serializable
data class XtreamSourceDTO(
    val id: Int,
    val name: String,
    val serverUrl: String,
    val username: String,
    val enabled: Boolean? = null,
    val importLive: Boolean? = null,
    val importVod: Boolean? = null,
    val importSeries: Boolean? = null,
    val vodLibraryId: Int? = null,
    val seriesLibraryId: Int? = null,
    val channelCount: Int? = null,
    val vodCount: Int? = null,
    val seriesCount: Int? = null,
    val lastFetched: String? = null,
    val expirationDate: String? = null,
    val createdAt: String? = null
) {
    fun toDomain() = XtreamSource(
        id = id, name = name, serverUrl = serverUrl, username = username,
        enabled = enabled ?: true,
        importLive = importLive ?: true,
        importVod = importVod ?: false,
        importSeries = importSeries ?: false,
        vodLibraryId = vodLibraryId, seriesLibraryId = seriesLibraryId,
        channelCount = channelCount ?: 0, vodCount = vodCount ?: 0, seriesCount = seriesCount ?: 0,
        lastFetched = lastFetched?.let { parseIso8601(it) },
        expirationDate = expirationDate?.let { parseIso8601(it) },
        createdAt = createdAt?.let { parseIso8601(it) }
    )
}

@Serializable
data class EPGSourcesResponse(val sources: List<EPGSourceDTO> = emptyList())

@Serializable
data class EPGSourceDTO(
    val id: Int,
    val name: String,
    val url: String,
    val type: String,
    val enabled: Boolean? = null,
    val lastFetched: String? = null,
    val channelCount: Int? = null,
    val programCount: Int? = null
) {
    fun toDomain() = EPGSource(
        id = id, name = name, url = url,
        type = EPGSourceType.fromValue(type),
        enabled = enabled ?: true,
        lastFetched = lastFetched?.let { parseIso8601(it) },
        channelCount = channelCount ?: 0,
        programCount = programCount ?: 0
    )
}

// Channel Groups
@Serializable
data class ChannelGroupsResponse(val groups: List<ChannelGroupDTO> = emptyList())

@Serializable
data class ChannelGroupDTO(
    val id: Int,
    val name: String,
    val enabled: Boolean? = null,
    val members: List<ChannelGroupMemberDTO>? = null
) {
    fun toDomain() = ChannelGroup(
        id = id, name = name, enabled = enabled ?: true,
        members = members?.map { ChannelGroupMember(it.channelId, it.priority, it.channelName) } ?: emptyList()
    )
}

@Serializable
data class ChannelGroupMemberDTO(
    val channelId: String,
    val priority: Int,
    val channelName: String? = null
)

// On Later
@Serializable
data class OnLaterStatsResponseDTO(
    val movies: Int = 0,
    val sports: Int = 0,
    val kids: Int = 0,
    val news: Int = 0,
    val premieres: Int = 0
) {
    fun toDomain() = OnLaterStats(movies, sports, kids, news, premieres)
}

@Serializable
data class OnLaterResponse(val programs: List<OnLaterProgramDTO> = emptyList())

@Serializable
data class OnLaterProgramDTO(
    val channelId: String,
    val channelName: String,
    val channelLogo: String? = null,
    val channelNumber: Int? = null,
    val program: ProgramDTO
) {
    fun toDomain() = OnLaterProgram(
        channelId = channelId, channelName = channelName,
        channelLogo = channelLogo, channelNumber = channelNumber,
        program = program.toDomain()
    )
}

// Team Pass
@Serializable
data class TeamPassesResponse(val teamPasses: List<TeamPassDTO> = emptyList())

@Serializable
data class TeamPassDTO(
    val id: Int,
    val userId: Int? = null,
    val teamName: String,
    val teamAliases: String? = null,
    val league: String,
    val channelIds: String? = null,
    val prePadding: Int? = null,
    val postPadding: Int? = null,
    val keepCount: Int? = null,
    val priority: Int? = null,
    val enabled: Boolean? = null,
    val upcomingCount: Int? = null,
    val logoUrl: String? = null
) {
    fun toDomain() = TeamPass(
        id = id, teamName = teamName,
        teamAliases = teamAliases?.split(",")?.map { it.trim() } ?: emptyList(),
        league = league,
        channelIds = channelIds?.split(",")?.map { it.trim() } ?: emptyList(),
        prePadding = prePadding ?: 5, postPadding = postPadding ?: 60,
        keepCount = keepCount ?: 0, priority = priority ?: 0,
        enabled = enabled ?: true, upcomingCount = upcomingCount ?: 0,
        logoUrl = logoUrl
    )
}

@Serializable
data class LeaguesResponse(val leagues: List<String> = emptyList())

@Serializable
data class TeamsResponse(val teams: List<TeamDTO> = emptyList())

@Serializable
data class TeamDTO(
    val name: String,
    val aliases: List<String>? = null,
    val logo: String? = null
) {
    fun toDomain() = Team(name, aliases ?: emptyList(), logo)
}

// Utility
internal expect fun parseIso8601(value: String): Long?
internal expect fun generateUuid(): String
