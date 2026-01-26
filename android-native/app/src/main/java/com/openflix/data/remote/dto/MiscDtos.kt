package com.openflix.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Miscellaneous DTOs for hubs, libraries, playlists, etc.
 */

data class LibraryDto(
    @SerializedName("id") val id: String,
    @SerializedName("key") val key: String?,
    @SerializedName("title") val title: String,
    @SerializedName("type") val type: String,  // movie, show, artist, photo
    @SerializedName("agent") val agent: String?,
    @SerializedName("scanner") val scanner: String?,
    @SerializedName("language") val language: String?,
    @SerializedName("uuid") val uuid: String?,
    @SerializedName("updated_at") val updatedAt: Long?,
    @SerializedName("scanned_at") val scannedAt: Long?,
    @SerializedName("content_changed_at") val contentChangedAt: Long?,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("art") val art: String?,
    @SerializedName("item_count") val itemCount: Int?
)

data class HubDto(
    @SerializedName("id") val id: String,
    @SerializedName("key") val key: String?,
    @SerializedName("hub_key") val hubKey: String?,
    @SerializedName("type") val type: String,  // mixed, movie, show, episode, clip
    @SerializedName("hub_type") val hubType: String?,
    @SerializedName("title") val title: String,
    @SerializedName("style") val style: String?,  // hero, shelf, carousel
    @SerializedName("promoted") val promoted: Boolean?,
    @SerializedName("size") val size: Int?,
    @SerializedName("more") val more: Boolean?,
    @SerializedName("items") val items: List<MediaItemDto>?
)

// Playlist response wrapper for Plex-compatible MediaContainer
data class PlaylistsResponse(
    @SerializedName("MediaContainer") val mediaContainer: PlaylistsContainer?
)

data class PlaylistsContainer(
    @SerializedName("size") val size: Int?,
    @SerializedName("Metadata") val metadata: List<PlaylistDto>?
)

data class PlaylistDto(
    @SerializedName("ratingKey") val id: String,
    @SerializedName("key") val key: String?,
    @SerializedName("guid") val guid: String?,
    @SerializedName("type") val type: String?,
    @SerializedName("title") val title: String,
    @SerializedName("summary") val summary: String?,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("composite") val composite: String?,
    @SerializedName("duration") val duration: Long?,
    @SerializedName("leafCount") val leafCount: Int?,
    @SerializedName("playlistType") val playlistType: String?,
    @SerializedName("smart") val smart: Boolean?,
    @SerializedName("addedAt") val addedAt: Long?,
    @SerializedName("updatedAt") val updatedAt: Long?
)

data class ServerInfoDto(
    @SerializedName("name") val name: String?,
    @SerializedName("version") val version: String?,
    @SerializedName("platform") val platform: String?,
    @SerializedName("machine_identifier") val machineIdentifier: String?,
    @SerializedName("owner") val owner: Boolean?,
    @SerializedName("transcoder_active") val transcoderActive: Boolean?
)

data class ServerCapabilitiesDto(
    @SerializedName("live_tv") val liveTV: Boolean?,
    @SerializedName("dvr") val dvr: Boolean?,
    @SerializedName("transcoding") val transcoding: Boolean?,
    @SerializedName("offline_downloads") val offlineDownloads: Boolean?,
    @SerializedName("multi_user") val multiUser: Boolean?,
    @SerializedName("watch_party") val watchParty: Boolean?,
    @SerializedName("epg_sources") val epgSources: List<String>?
)

data class ClientLogEntry(
    @SerializedName("timestamp") val timestamp: Long,
    @SerializedName("level") val level: String,  // debug, info, warning, error
    @SerializedName("message") val message: String,
    @SerializedName("tag") val tag: String?,
    @SerializedName("device") val device: String?,
    @SerializedName("app_version") val appVersion: String?,
    @SerializedName("stack_trace") val stackTrace: String?
)

data class ProfileDto(
    @SerializedName("id") val id: String,
    @SerializedName("name") val name: String,
    @SerializedName("avatar") val avatar: String?,
    @SerializedName("is_kid") val isKid: Boolean?,
    @SerializedName("pin") val pin: String?,
    @SerializedName("created_at") val createdAt: Long?,
    @SerializedName("updated_at") val updatedAt: Long?
)

data class FilterDto(
    @SerializedName("key") val key: String,
    @SerializedName("type") val type: String,
    @SerializedName("title") val title: String,
    @SerializedName("values") val values: List<FilterValueDto>?
)

data class FilterValueDto(
    @SerializedName("key") val key: String,
    @SerializedName("title") val title: String,
    @SerializedName("active") val active: Boolean?
)

data class SortDto(
    @SerializedName("key") val key: String,
    @SerializedName("title") val title: String,
    @SerializedName("default") val default: Boolean?,
    @SerializedName("default_direction") val defaultDirection: String?  // asc, desc
)

data class ChapterDto(
    @SerializedName("id") val id: String?,
    @SerializedName("index") val index: Int,
    @SerializedName("title") val title: String?,
    @SerializedName("start_time") val startTime: Long,  // milliseconds
    @SerializedName("end_time") val endTime: Long?,
    @SerializedName("thumb") val thumb: String?
)

data class IntroMarkerDto(
    @SerializedName("start") val start: Long,  // milliseconds
    @SerializedName("end") val end: Long,
    @SerializedName("type") val type: String?  // intro, credits
)
