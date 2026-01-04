package com.openflix.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Live TV and EPG-related DTOs
 */

data class ChannelDto(
    @SerializedName("id") val id: String,
    @SerializedName("channelId") val uuid: String?,  // Maps to channelId from server
    @SerializedName("number") val number: Int?,  // Server sends int
    @SerializedName("name") val name: String,
    @SerializedName("title") val title: String?,
    @SerializedName("callsign") val callsign: String?,
    @SerializedName("logo") val logo: String?,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("art") val art: String?,
    @SerializedName("sourceId") val source: String?,
    @SerializedName("sourceName") val sourceName: String?,  // Provider name from M3U source
    @SerializedName("hd") val hd: Boolean?,
    @SerializedName("isFavorite") val favorite: Boolean?,
    @SerializedName("enabled") val enabled: Boolean?,  // Server uses enabled, not hidden
    @SerializedName("group") val group: String?,
    @SerializedName("category") val category: String?,
    @SerializedName("tuner_host") val tunerHost: String?,
    @SerializedName("streamUrl") val streamUrl: String?,

    // Current program info - matches server field names
    @SerializedName("nowPlaying") val nowPlaying: ProgramDto?,
    @SerializedName("nextProgram") val upNext: ProgramDto?,  // Server uses nextProgram

    // Archive/catch-up settings
    @SerializedName("archiveEnabled") val archiveEnabled: Boolean?,
    @SerializedName("archiveDays") val archiveDays: Int?
) {
    // Convenience property for hidden (inverse of enabled)
    val hidden: Boolean get() = enabled == false
}

data class ProgramDto(
    @SerializedName("id") val id: String?,
    @SerializedName("title") val title: String,
    @SerializedName("subtitle") val subtitle: String?,
    @SerializedName("description") val description: String?,
    @SerializedName("start") val startIso: String?,  // ISO timestamp from server
    @SerializedName("end") val endIso: String?,  // ISO timestamp from server
    @SerializedName("duration") val duration: Long?,  // minutes
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("art") val art: String?,
    @SerializedName("rating") val rating: String?,
    @SerializedName("genres") val genres: List<String>?,
    @SerializedName("category") val category: String?,  // e.g., "TVShow", "Movie"
    @SerializedName("episode_title") val episodeTitle: String?,
    @SerializedName("season_number") val seasonNumber: Int?,
    @SerializedName("episode_number") val episodeNumber: Int?,
    @SerializedName("original_air_date") val originalAirDate: String?,
    @SerializedName("is_new") val isNew: Boolean?,
    @SerializedName("is_live") val isLive: Boolean?,
    @SerializedName("is_premiere") val isPremiere: Boolean?,
    @SerializedName("is_finale") val isFinale: Boolean?,
    @SerializedName("is_repeat") val isRepeat: Boolean?,
    @SerializedName("is_movie") val isMovie: Boolean?,
    @SerializedName("is_sports") val isSports: Boolean?,
    @SerializedName("is_kids") val isKids: Boolean?,
    @SerializedName("has_recording") val hasRecording: Boolean?,
    @SerializedName("recording_id") val recordingId: String?,
    @SerializedName("series_id") val seriesId: String?,
    @SerializedName("program_id") val programId: String?,
    @SerializedName("gracenote_id") val gracenoteId: String?
) {
    // Parse ISO timestamp to Unix seconds
    val startTime: Long
        get() = parseIsoTimestamp(startIso)

    val endTime: Long
        get() = parseIsoTimestamp(endIso)

    companion object {
        private fun parseIsoTimestamp(iso: String?): Long {
            if (iso.isNullOrBlank()) return 0L
            return try {
                java.time.Instant.parse(iso).epochSecond
            } catch (e: Exception) {
                0L
            }
        }
    }
}

data class GuideResponse(
    @SerializedName("channels") val channels: List<ChannelDto>,
    @SerializedName("programs") val programs: Map<String, List<ProgramDto>>?,  // Keyed by channel ID
    @SerializedName("start") val start: String?,  // ISO timestamp
    @SerializedName("end") val end: String?
)

data class ChannelWithProgramsDto(
    @SerializedName("channel") val channel: ChannelDto,
    @SerializedName("programs") val programs: List<ProgramDto>
)

data class EPGResponse(
    @SerializedName("channels") val channels: List<EPGChannelDto>,
    @SerializedName("programs") val programs: Map<String, List<ProgramDto>>?,
    @SerializedName("start_time") val startTime: Long?,
    @SerializedName("end_time") val endTime: Long?
)

data class EPGChannelDto(
    @SerializedName("id") val id: String,
    @SerializedName("name") val name: String,
    @SerializedName("number") val number: String?,
    @SerializedName("logo") val logo: String?,
    @SerializedName("programs") val programs: List<ProgramDto>?
)

data class StreamResponse(
    @SerializedName("url") val url: String,
    @SerializedName("protocol") val protocol: String?,
    @SerializedName("format") val format: String?,
    @SerializedName("drm") val drm: DRMInfoDto?
)

// Wrapper response for channels list
data class ChannelsResponse(
    @SerializedName("channels") val channels: List<ChannelDto>
)

// Wrapper response for recordings list
data class RecordingsResponse(
    @SerializedName("recordings") val recordings: List<RecordingDto>
)

// Wrapper response for scheduled recordings list
data class ScheduledRecordingsResponse(
    @SerializedName("scheduled") val scheduled: List<ScheduledRecordingDto>?
)

data class DRMInfoDto(
    @SerializedName("type") val type: String?,  // widevine, playready, fairplay
    @SerializedName("license_url") val licenseUrl: String?,
    @SerializedName("headers") val headers: Map<String, String>?
)

// DVR-related DTOs
data class RecordingDto(
    @SerializedName("id") val id: String,
    @SerializedName("title") val title: String,
    @SerializedName("subtitle") val subtitle: String?,
    @SerializedName("description") val description: String?,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("art") val art: String?,
    @SerializedName("channel_id") val channelId: String?,
    @SerializedName("channel_name") val channelName: String?,
    @SerializedName("start_time") val startTime: Long,
    @SerializedName("end_time") val endTime: Long,
    @SerializedName("duration") val duration: Long?,
    @SerializedName("file_path") val filePath: String?,
    @SerializedName("file_size") val fileSize: Long?,
    @SerializedName("status") val status: String?,  // recording, completed, failed
    @SerializedName("season_number") val seasonNumber: Int?,
    @SerializedName("episode_number") val episodeNumber: Int?,
    @SerializedName("series_id") val seriesId: String?,
    @SerializedName("program_id") val programId: String?,
    @SerializedName("view_offset") val viewOffset: Long?,
    @SerializedName("commercials") val commercials: List<CommercialDto>?
)

data class CommercialDto(
    @SerializedName("start") val start: Long,  // milliseconds
    @SerializedName("end") val end: Long
)

data class ScheduledRecordingDto(
    @SerializedName("id") val id: String,
    @SerializedName("title") val title: String,
    @SerializedName("channel_id") val channelId: String?,
    @SerializedName("channel_name") val channelName: String?,
    @SerializedName("start_time") val startTime: Long,
    @SerializedName("end_time") val endTime: Long,
    @SerializedName("type") val type: String?,  // single, series
    @SerializedName("series_id") val seriesId: String?,
    @SerializedName("program_id") val programId: String?,
    @SerializedName("status") val status: String?  // pending, recording, conflict
)

data class RecordRequest(
    @SerializedName("channel_id") val channelId: String,
    @SerializedName("program_id") val programId: String?,
    @SerializedName("start_time") val startTime: Long?,
    @SerializedName("end_time") val endTime: Long?,
    @SerializedName("type") val type: String?,  // single, series
    @SerializedName("series_id") val seriesId: String?,
    @SerializedName("start_offset") val startOffset: Int?,  // minutes before
    @SerializedName("end_offset") val endOffset: Int?  // minutes after
)

// ============ Time-Shift / Catch-Up TV DTOs ============

data class CatchUpProgramDto(
    @SerializedName("id") val id: String,
    @SerializedName("programId") val programId: String,
    @SerializedName("channelId") val channelId: String,
    @SerializedName("title") val title: String,
    @SerializedName("startTime") val startTime: String,  // ISO timestamp
    @SerializedName("endTime") val endTime: String,
    @SerializedName("duration") val duration: Long,  // seconds
    @SerializedName("description") val description: String?,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("available") val available: Boolean
)

data class CatchUpResponse(
    @SerializedName("programs") val programs: List<CatchUpProgramDto>,
    @SerializedName("bufferStart") val bufferStart: String?,  // ISO timestamp
    @SerializedName("bufferDuration") val bufferDuration: Long?,  // seconds
    @SerializedName("isBuffering") val isBuffering: Boolean
)

data class StartOverInfoDto(
    @SerializedName("available") val available: Boolean,
    @SerializedName("streamUrl") val streamUrl: String?,
    @SerializedName("program") val program: StartOverProgramDto?,
    @SerializedName("secondsIntoProgram") val secondsIntoProgram: Long?,
    @SerializedName("isBuffering") val isBuffering: Boolean
)

data class StartOverProgramDto(
    @SerializedName("title") val title: String,
    @SerializedName("subtitle") val subtitle: String?,
    @SerializedName("startTime") val startTime: String,  // ISO timestamp
    @SerializedName("endTime") val endTime: String,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("description") val description: String?
)

data class TimeshiftBufferResponse(
    @SerializedName("status") val status: String,
    @SerializedName("channelId") val channelId: String,
    @SerializedName("message") val message: String?
)

// ============ Channel Update DTOs ============

data class UpdateChannelRequest(
    @SerializedName("name") val name: String? = null,
    @SerializedName("number") val number: Int? = null,
    @SerializedName("logo") val logo: String? = null,
    @SerializedName("group") val group: String? = null,
    @SerializedName("enabled") val enabled: Boolean? = null,
    @SerializedName("epgSourceId") val epgSourceId: Int? = null,
    @SerializedName("channelId") val channelId: String? = null  // EPG channel ID for mapping
)

// ============ Archive / Catch-up DTOs ============

data class ArchiveProgramDto(
    @SerializedName("id") val id: Int,
    @SerializedName("channelId") val channelId: Int,
    @SerializedName("programId") val programId: Int?,
    @SerializedName("title") val title: String,
    @SerializedName("description") val description: String?,
    @SerializedName("startTime") val startTime: String,  // ISO timestamp
    @SerializedName("endTime") val endTime: String,
    @SerializedName("duration") val duration: Int,  // seconds
    @SerializedName("icon") val icon: String?,
    @SerializedName("category") val category: String?,
    @SerializedName("status") val status: String,
    @SerializedName("expiresAt") val expiresAt: String  // ISO timestamp
)

data class ArchivedProgramsResponse(
    @SerializedName("programs") val programs: List<ArchiveProgramDto>,
    @SerializedName("isArchiving") val isArchiving: Boolean,
    @SerializedName("archiveStart") val archiveStart: String?,  // ISO timestamp
    @SerializedName("retentionDays") val retentionDays: Int
)

data class EnableArchiveRequest(
    @SerializedName("days") val days: Int = 7
)

data class EnableArchiveResponse(
    @SerializedName("message") val message: String,
    @SerializedName("channelId") val channelId: Int,
    @SerializedName("retentionDays") val retentionDays: Int
)

data class DisableArchiveResponse(
    @SerializedName("message") val message: String,
    @SerializedName("channelId") val channelId: Int
)

data class ArchiveChannelStatusDto(
    @SerializedName("channelId") val channelId: Int,
    @SerializedName("channelName") val channelName: String,
    @SerializedName("isArchiving") val isArchiving: Boolean,
    @SerializedName("archiveStart") val archiveStart: String?,  // ISO timestamp
    @SerializedName("retentionDays") val retentionDays: Int,
    @SerializedName("programCount") val programCount: Int
)

data class ArchiveStatusResponse(
    @SerializedName("channels") val channels: List<ArchiveChannelStatusDto>,
    @SerializedName("totalChannels") val totalChannels: Int,
    @SerializedName("activeRecording") val activeRecording: Int
)
