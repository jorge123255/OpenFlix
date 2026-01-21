package com.openflix.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Live TV and EPG-related DTOs
 */

data class ChannelDto(
    @SerializedName("id") val id: String,
    @SerializedName("tvgId") val uuid: String?,  // Maps to tvgId from server (EPG channel ID)
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
    @SerializedName("icon") val thumb: String?,  // Server uses "icon" for poster
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
    @SerializedName("id") val id: Int,  // Server returns int
    @SerializedName("title") val title: String,
    @SerializedName("subtitle") val subtitle: String?,
    @SerializedName("description") val description: String?,
    @SerializedName("summary") val summary: String?,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("art") val art: String?,
    @SerializedName("channelId") val channelId: Int?,  // camelCase, server returns int
    @SerializedName("channelName") val channelName: String?,
    @SerializedName("channelLogo") val channelLogo: String?,
    @SerializedName("startTime") val startTime: String,  // ISO 8601 string
    @SerializedName("endTime") val endTime: String,  // ISO 8601 string
    @SerializedName("duration") val duration: Long?,
    @SerializedName("filePath") val filePath: String?,
    @SerializedName("fileSize") val fileSize: Long?,
    @SerializedName("status") val status: String?,  // scheduled, recording, completed, failed
    @SerializedName("seasonNumber") val seasonNumber: Int?,
    @SerializedName("episodeNumber") val episodeNumber: Int?,
    @SerializedName("seriesId") val seriesId: String?,
    @SerializedName("programId") val programId: Int?,  // Server returns int
    @SerializedName("viewOffset") val viewOffset: Long?,
    @SerializedName("commercials") val commercials: List<CommercialDto>?,
    @SerializedName("category") val category: String?,
    @SerializedName("episodeNum") val episodeNum: String?,
    @SerializedName("seriesRecord") val seriesRecord: Boolean?,
    @SerializedName("seriesRuleId") val seriesRuleId: Int?,
    @SerializedName("genres") val genres: String?,
    @SerializedName("contentRating") val contentRating: String?,
    @SerializedName("year") val year: Int?,
    @SerializedName("rating") val rating: Double?,
    @SerializedName("isMovie") val isMovie: Boolean?,
    @SerializedName("createdAt") val createdAt: String?,
    @SerializedName("updatedAt") val updatedAt: String?
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

// ============ On Later DTOs ============

data class OnLaterProgramDto(
    @SerializedName("id") val id: Long,
    @SerializedName("channelId") val channelId: String,
    @SerializedName("title") val title: String,
    @SerializedName("subtitle") val subtitle: String?,
    @SerializedName("description") val description: String?,
    @SerializedName("start") val start: String,
    @SerializedName("end") val end: String,
    @SerializedName("icon") val icon: String?,
    @SerializedName("art") val art: String?,
    @SerializedName("category") val category: String?,
    @SerializedName("isMovie") val isMovie: Boolean,
    @SerializedName("isSports") val isSports: Boolean,
    @SerializedName("isKids") val isKids: Boolean,
    @SerializedName("isNews") val isNews: Boolean,
    @SerializedName("isPremiere") val isPremiere: Boolean,
    @SerializedName("isNew") val isNew: Boolean,
    @SerializedName("isLive") val isLive: Boolean,
    @SerializedName("teams") val teams: String?,
    @SerializedName("league") val league: String?,
    @SerializedName("rating") val rating: String?
)

data class OnLaterChannelDto(
    @SerializedName("id") val id: Long,
    @SerializedName("name") val name: String,
    @SerializedName("logo") val logo: String?,
    @SerializedName("number") val number: Int
)

data class OnLaterItemDto(
    @SerializedName("program") val program: OnLaterProgramDto,
    @SerializedName("channel") val channel: OnLaterChannelDto?,
    @SerializedName("hasRecording") val hasRecording: Boolean,
    @SerializedName("recordingId") val recordingId: Long?
)

data class OnLaterResponse(
    @SerializedName("items") val items: List<OnLaterItemDto>,
    @SerializedName("totalCount") val totalCount: Int,
    @SerializedName("startTime") val startTime: String,
    @SerializedName("endTime") val endTime: String
)

data class OnLaterStatsDto(
    @SerializedName("movies") val movies: Int,
    @SerializedName("sports") val sports: Int,
    @SerializedName("kids") val kids: Int,
    @SerializedName("news") val news: Int,
    @SerializedName("premieres") val premieres: Int
)

data class LeaguesResponse(
    @SerializedName("leagues") val leagues: List<String>
)

// ============ Team Pass DTOs ============

data class TeamPassDto(
    @SerializedName("id") val id: Long,
    @SerializedName("userId") val userId: Long,
    @SerializedName("teamName") val teamName: String,
    @SerializedName("teamAliases") val teamAliases: String?,
    @SerializedName("league") val league: String,
    @SerializedName("channelIds") val channelIds: String?,
    @SerializedName("prePadding") val prePadding: Int,
    @SerializedName("postPadding") val postPadding: Int,
    @SerializedName("keepCount") val keepCount: Int,
    @SerializedName("priority") val priority: Int,
    @SerializedName("enabled") val enabled: Boolean,
    @SerializedName("createdAt") val createdAt: String?,
    @SerializedName("updatedAt") val updatedAt: String?,
    @SerializedName("upcomingCount") val upcomingCount: Int?,
    @SerializedName("logoUrl") val logoUrl: String?
)

data class TeamPassListResponse(
    @SerializedName("teamPasses") val teamPasses: List<TeamPassDto>
)

data class TeamPassRequest(
    @SerializedName("teamName") val teamName: String,
    @SerializedName("league") val league: String,
    @SerializedName("channelIds") val channelIds: String? = null,
    @SerializedName("prePadding") val prePadding: Int = 5,
    @SerializedName("postPadding") val postPadding: Int = 60,
    @SerializedName("keepCount") val keepCount: Int = 0,
    @SerializedName("priority") val priority: Int = 0,
    @SerializedName("enabled") val enabled: Boolean = true
)

data class TeamPassWithGamesResponse(
    @SerializedName("teamPass") val teamPass: TeamPassDto,
    @SerializedName("games") val games: List<OnLaterItemDto>?
)

data class TeamPassStatsDto(
    @SerializedName("totalPasses") val totalPasses: Int,
    @SerializedName("activePasses") val activePasses: Int,
    @SerializedName("upcomingGames") val upcomingGames: Int,
    @SerializedName("scheduledRecordings") val scheduledRecordings: Int
)

data class SportsTeamDto(
    @SerializedName("name") val name: String,
    @SerializedName("city") val city: String,
    @SerializedName("nickname") val nickname: String,
    @SerializedName("league") val league: String?,
    @SerializedName("aliases") val aliases: List<String>?,
    @SerializedName("logoUrl") val logoUrl: String?
)

data class TeamsSearchResponse(
    @SerializedName("teams") val teams: List<SportsTeamDto>
)

data class LeagueTeamsResponse(
    @SerializedName("teams") val teams: List<SportsTeamDto>,
    @SerializedName("league") val league: String
)

data class SportsLeaguesResponse(
    @SerializedName("leagues") val leagues: List<String>
)

// ============ DVR Conflict DTOs ============

data class ConflictGroupDto(
    @SerializedName("recordings") val recordings: List<RecordingDto>
)

data class ConflictsResponse(
    @SerializedName("conflicts") val conflicts: List<ConflictGroupDto>,
    @SerializedName("hasConflicts") val hasConflicts: Boolean,
    @SerializedName("totalCount") val totalCount: Int
)

data class ResolveConflictRequest(
    @SerializedName("keepRecordingId") val keepRecordingId: Long,
    @SerializedName("cancelRecordingId") val cancelRecordingId: Long
)

// Live Recording Stats DTOs
data class RecordingStatsResponse(
    @SerializedName("stats") val stats: List<RecordingStatsDto>,
    @SerializedName("activeCount") val activeCount: Int
)

data class RecordingStatsDto(
    @SerializedName("id") val id: Long,
    @SerializedName("title") val title: String,
    @SerializedName("fileSize") val fileSize: Long,
    @SerializedName("fileSizeFormatted") val fileSizeFormatted: String,
    @SerializedName("elapsedSeconds") val elapsedSeconds: Long,
    @SerializedName("elapsedFormatted") val elapsedFormatted: String,
    @SerializedName("totalSeconds") val totalSeconds: Long,
    @SerializedName("remainingSeconds") val remainingSeconds: Long,
    @SerializedName("progressPercent") val progressPercent: Double,
    @SerializedName("bitrate") val bitrate: String?,
    @SerializedName("isHealthy") val isHealthy: Boolean,
    @SerializedName("isFailed") val isFailed: Boolean,
    @SerializedName("failureReason") val failureReason: String?
)

// ============ Channel Groups (Failover) DTOs ============

/**
 * DTO for a channel group that supports failover between multiple sources.
 */
data class ChannelGroupDto(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("displayNumber") val displayNumber: Int,
    @SerializedName("logo") val logo: String?,
    @SerializedName("channelId") val channelId: String?,  // EPG channel ID
    @SerializedName("enabled") val enabled: Boolean,
    @SerializedName("createdAt") val createdAt: String?,
    @SerializedName("updatedAt") val updatedAt: String?,
    @SerializedName("members") val members: List<ChannelGroupMemberDto>?
)

/**
 * DTO for a channel member within a group with priority for failover.
 */
data class ChannelGroupMemberDto(
    @SerializedName("id") val id: Int,
    @SerializedName("channelGroupId") val channelGroupId: Int,
    @SerializedName("channelId") val channelId: Int,
    @SerializedName("priority") val priority: Int,
    @SerializedName("createdAt") val createdAt: String?,
    @SerializedName("channel") val channel: ChannelGroupChannelDto?
)

/**
 * Simplified channel info within a group member.
 */
data class ChannelGroupChannelDto(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("logo") val logo: String?,
    @SerializedName("sourceName") val sourceName: String?,
    @SerializedName("streamUrl") val streamUrl: String?
)

/**
 * Response wrapper for channel groups list.
 */
data class ChannelGroupsResponse(
    @SerializedName("groups") val groups: List<ChannelGroupDto>
)

/**
 * Request to create a channel group.
 */
data class CreateChannelGroupRequest(
    @SerializedName("name") val name: String,
    @SerializedName("displayNumber") val displayNumber: Int,
    @SerializedName("logo") val logo: String? = null,
    @SerializedName("channelId") val channelId: String? = null
)

/**
 * Request to update a channel group.
 */
data class UpdateChannelGroupRequest(
    @SerializedName("name") val name: String? = null,
    @SerializedName("displayNumber") val displayNumber: Int? = null,
    @SerializedName("logo") val logo: String? = null,
    @SerializedName("channelId") val channelId: String? = null,
    @SerializedName("enabled") val enabled: Boolean? = null
)

/**
 * Request to add a channel to a group.
 */
data class AddGroupMemberRequest(
    @SerializedName("channelId") val channelId: Int,
    @SerializedName("priority") val priority: Int = 0
)

/**
 * Request to update a group member's priority.
 */
data class UpdateGroupMemberPriorityRequest(
    @SerializedName("priority") val priority: Int
)

/**
 * Response for auto-detected duplicate channels.
 */
data class DuplicateGroupDto(
    @SerializedName("name") val name: String,
    @SerializedName("channels") val channels: List<ChannelDto>
)

/**
 * Response for auto-detect duplicates.
 */
data class AutoDetectDuplicatesResponse(
    @SerializedName("groups") val groups: List<DuplicateGroupDto>
)
