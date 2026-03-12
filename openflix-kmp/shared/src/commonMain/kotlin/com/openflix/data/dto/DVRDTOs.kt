package com.openflix.data.dto

import com.openflix.domain.model.*
import kotlinx.serialization.Serializable

@Serializable
data class RecordingsResponse(val recordings: List<RecordingDTO>? = null) {
    val allRecordings: List<RecordingDTO> get() = recordings ?: emptyList()
}

@Serializable
data class ScheduledRecordingsResponse(val scheduled: List<RecordingDTO>? = null) {
    val allScheduled: List<RecordingDTO> get() = scheduled ?: emptyList()
}

@Serializable
data class RecordingDTO(
    val id: StringOrInt? = null,
    val title: String? = null,
    val subtitle: String? = null,
    val description: String? = null,
    val summary: String? = null,
    val thumb: String? = null,
    val art: String? = null,
    val channelId: StringOrInt? = null,
    val channelName: String? = null,
    val channelLogo: String? = null,
    val startTime: String? = null,
    val endTime: String? = null,
    val duration: Int? = null,
    val status: String? = null,
    val filePath: String? = null,
    val fileSize: Int? = null,
    val seasonNumber: Int? = null,
    val episodeNumber: Int? = null,
    val seriesRecord: Boolean? = null,
    val seriesRuleId: Int? = null,
    val genres: String? = null,
    val contentRating: String? = null,
    val year: Int? = null,
    val rating: Double? = null,
    val isMovie: Boolean? = null,
    val viewOffset: Int? = null,
    val commercials: List<CommercialDTO>? = null,
    val priority: Int? = null,
    val programId: StringOrInt? = null,
    val seriesId: StringOrInt? = null,
    val category: String? = null,
    val createdAt: String? = null,
    val updatedAt: String? = null
) {
    val safeId: Int get() = id?.intValue ?: 0
    val safeTitle: String get() = title ?: "Unknown Recording"
    val safeStatus: String get() = status ?: "unknown"

    fun toDomain() = Recording(
        id = safeId, title = safeTitle, subtitle = subtitle,
        description = description ?: summary,
        thumb = thumb, art = art,
        channelId = channelId?.stringValue, channelName = channelName, channelLogo = channelLogo,
        startTimeMs = startTime?.let { parseIso8601(it) } ?: currentTimeMs(),
        endTimeMs = endTime?.let { parseIso8601(it) } ?: currentTimeMs(),
        duration = duration ?: 0,
        status = RecordingStatus.fromValue(safeStatus),
        filePath = filePath, fileSize = fileSize,
        seasonNumber = seasonNumber, episodeNumber = episodeNumber,
        seriesRecord = seriesRecord ?: false, seriesRuleId = seriesRuleId,
        genres = genres?.split(",")?.map { it.trim() } ?: emptyList(),
        contentRating = contentRating, year = year, rating = rating,
        isMovie = isMovie ?: false, viewOffset = viewOffset,
        commercials = commercials?.map { Commercial(it.start, it.end) } ?: emptyList(),
        priority = priority ?: 50
    )
}

@Serializable
data class CommercialDTO(val start: Int, val end: Int)

@Serializable
data class RecordingStreamResponse(val url: String, val format: String? = null)

@Serializable
data class RecordingStatsResponse(
    val total: Int = 0,
    val scheduled: Int = 0,
    val recording: Int = 0,
    val completed: Int = 0,
    val failed: Int = 0,
    val totalSize: Int? = null
)

@Serializable
data class SeriesRulesResponse(val rules: List<SeriesRuleDTO> = emptyList())

@Serializable
data class SeriesRuleDTO(
    val id: StringOrInt,
    val title: String? = null,
    val channelId: StringOrInt? = null,
    val enabled: Boolean? = null,
    val prePadding: Int? = null,
    val postPadding: Int? = null,
    val keepCount: Int? = null,
    val recordingCount: Int? = null
) {
    fun toDomain() = SeriesRule(
        id = id.intValue, title = title ?: "Series Rule",
        channelId = channelId?.stringValue,
        enabled = enabled ?: true,
        prePadding = prePadding ?: 0, postPadding = postPadding ?: 0,
        keepCount = keepCount ?: 0, recordingCount = recordingCount ?: 0
    )
}
