package com.openflix.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Media-related DTOs
 */

data class MediaItemDto(
    @SerializedName("ratingKey") val ratingKey: Int?,  // Plex uses integer ratingKey as primary ID
    @SerializedName("key") val key: String?,
    @SerializedName("guid") val guid: String?,
    @SerializedName("type") val type: String = "unknown",  // movie, show, season, episode, clip
    @SerializedName("title") val title: String = "",
    @SerializedName("originalTitle") val originalTitle: String?,
    @SerializedName("tagline") val tagline: String?,
    @SerializedName("summary") val summary: String?,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("art") val art: String?,
    @SerializedName("banner") val banner: String?,
    @SerializedName("year") val year: Int?,
    @SerializedName("duration") val duration: Long?,  // milliseconds
    @SerializedName("viewOffset") val viewOffset: Long?,  // watch progress in milliseconds
    @SerializedName("viewCount") val viewCount: Int?,
    @SerializedName("addedAt") val addedAt: Long?,
    @SerializedName("updatedAt") val updatedAt: Long?,
    @SerializedName("originallyAvailableAt") val originallyAvailableAt: String?,
    @SerializedName("contentRating") val contentRating: String?,
    @SerializedName("rating") val rating: Double?,
    @SerializedName("audienceRating") val audienceRating: Double?,
    @SerializedName("studio") val studio: String?,
    @SerializedName("Genre") val genres: List<GenreDto>?,
    @SerializedName("Director") val directors: List<PersonDto>?,
    @SerializedName("Writer") val writers: List<PersonDto>?,
    @SerializedName("Role") val roles: List<RoleDto>?,
    @SerializedName("Media") val media: List<MediaVersionDto>?,
    @SerializedName("librarySectionID") val librarySectionId: Int?,
    @SerializedName("librarySectionTitle") val librarySectionTitle: String?,

    // For TV shows
    @SerializedName("parentRatingKey") val parentRatingKey: Int?,
    @SerializedName("parentTitle") val parentTitle: String?,
    @SerializedName("parentThumb") val parentThumb: String?,
    @SerializedName("grandparentRatingKey") val grandparentRatingKey: Int?,
    @SerializedName("grandparentTitle") val grandparentTitle: String?,
    @SerializedName("grandparentThumb") val grandparentThumb: String?,
    @SerializedName("grandparentArt") val grandparentArt: String?,
    @SerializedName("index") val index: Int?,  // episode/season number
    @SerializedName("parentIndex") val parentIndex: Int?,  // season number for episodes
    @SerializedName("leafCount") val leafCount: Int?,  // episode count
    @SerializedName("viewedLeafCount") val viewedLeafCount: Int?,
    @SerializedName("childCount") val childCount: Int?  // season count for shows
) {
    // Helper to get ID as string (uses ratingKey)
    val id: String get() = ratingKey?.toString() ?: guid ?: ""
}

data class MediaVersionDto(
    @SerializedName("id") val id: String?,
    @SerializedName("duration") val duration: Long?,
    @SerializedName("bitrate") val bitrate: Int?,
    @SerializedName("width") val width: Int?,
    @SerializedName("height") val height: Int?,
    @SerializedName("aspect_ratio") val aspectRatio: Double?,
    @SerializedName("audio_channels") val audioChannels: Int?,
    @SerializedName("audio_codec") val audioCodec: String?,
    @SerializedName("video_codec") val videoCodec: String?,
    @SerializedName("video_resolution") val videoResolution: String?,
    @SerializedName("container") val container: String?,
    @SerializedName("video_frame_rate") val videoFrameRate: String?,
    @SerializedName("video_profile") val videoProfile: String?,
    @SerializedName("Part") val part: List<MediaPartDto>?
)

data class MediaPartDto(
    @SerializedName("id") val id: String?,
    @SerializedName("key") val key: String?,
    @SerializedName("duration") val duration: Long?,
    @SerializedName("file") val file: String?,
    @SerializedName("size") val size: Long?,
    @SerializedName("container") val container: String?,
    @SerializedName("streams") val streams: List<MediaStreamDto>?
)

data class MediaStreamDto(
    @SerializedName("id") val id: String?,
    @SerializedName("stream_type") val streamType: Int?,  // 1=video, 2=audio, 3=subtitle
    @SerializedName("index") val index: Int?,
    @SerializedName("codec") val codec: String?,
    @SerializedName("language") val language: String?,
    @SerializedName("language_code") val languageCode: String?,
    @SerializedName("title") val title: String?,
    @SerializedName("display_title") val displayTitle: String?,
    @SerializedName("selected") val selected: Boolean?,
    @SerializedName("default") val default: Boolean?,
    @SerializedName("forced") val forced: Boolean?,

    // Video specific
    @SerializedName("width") val width: Int?,
    @SerializedName("height") val height: Int?,
    @SerializedName("bit_depth") val bitDepth: Int?,
    @SerializedName("frame_rate") val frameRate: Double?,

    // Audio specific
    @SerializedName("channels") val channels: Int?,
    @SerializedName("sampling_rate") val samplingRate: Int?
)

data class GenreDto(
    @SerializedName("id") val id: String?,
    @SerializedName("tag") val tag: String
)

data class PersonDto(
    @SerializedName("id") val id: String?,
    @SerializedName("tag") val tag: String,
    @SerializedName("thumb") val thumb: String?
)

data class RoleDto(
    @SerializedName("id") val id: String?,
    @SerializedName("tag") val tag: String,  // actor name
    @SerializedName("role") val role: String?,  // character name
    @SerializedName("thumb") val thumb: String?
)

data class MediaListResponse(
    @SerializedName("items") val items: List<MediaItemDto>,
    @SerializedName("total_size") val totalSize: Int?,
    @SerializedName("offset") val offset: Int?,
    @SerializedName("size") val size: Int?
)

data class SeasonDto(
    @SerializedName("id") val id: String,
    @SerializedName("rating_key") val ratingKey: String?,
    @SerializedName("title") val title: String,
    @SerializedName("index") val index: Int,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("leaf_count") val leafCount: Int?,
    @SerializedName("viewed_leaf_count") val viewedLeafCount: Int?,
    @SerializedName("parent_rating_key") val parentRatingKey: String?
)

data class EpisodeDto(
    @SerializedName("id") val id: String,
    @SerializedName("rating_key") val ratingKey: String?,
    @SerializedName("title") val title: String,
    @SerializedName("index") val index: Int,
    @SerializedName("parent_index") val parentIndex: Int?,
    @SerializedName("summary") val summary: String?,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("duration") val duration: Long?,
    @SerializedName("view_offset") val viewOffset: Long?,
    @SerializedName("originally_available_at") val originallyAvailableAt: String?,
    @SerializedName("parent_rating_key") val parentRatingKey: String?,
    @SerializedName("grandparent_rating_key") val grandparentRatingKey: String?
)

data class PlaybackResponse(
    @SerializedName("url") val url: String,
    @SerializedName("protocol") val protocol: String?,
    @SerializedName("direct_play") val directPlay: Boolean?,
    @SerializedName("transcoding") val transcoding: Boolean?
)

data class ProgressUpdateRequest(
    @SerializedName("key") val key: String,
    @SerializedName("time") val time: Long,  // milliseconds
    @SerializedName("duration") val duration: Long?,
    @SerializedName("state") val state: String?  // playing, paused, stopped
)

data class SearchResponse(
    @SerializedName("MediaContainer") val mediaContainer: SearchMediaContainer?
)

data class SearchMediaContainer(
    @SerializedName("Hub") val hubs: List<SearchHub>?
)

data class SearchHub(
    @SerializedName("type") val type: String?,
    @SerializedName("title") val title: String?,
    @SerializedName("Metadata") val metadata: List<MediaItemDto>?
)

// === Plex-compatible DTOs ===

/**
 * Response wrapper for Plex-compatible MediaContainer
 */
data class MediaContainerResponse(
    @SerializedName("MediaContainer") val mediaContainer: MediaContainer?
)

data class MediaContainer(
    @SerializedName("size") val size: Int?,
    @SerializedName("totalSize") val totalSize: Int?,
    @SerializedName("offset") val offset: Int?,
    @SerializedName("Metadata") val metadata: List<MediaItemDto>?,
    @SerializedName("Directory") val directory: List<DirectoryDto>?
)

/**
 * Library sections response
 */
data class LibrarySectionsResponse(
    @SerializedName("MediaContainer") val mediaContainer: LibrarySectionsContainer?
)

data class LibrarySectionsContainer(
    @SerializedName("size") val size: Int?,
    @SerializedName("Directory") val directories: List<LibrarySectionDto>?
)

data class LibrarySectionDto(
    @SerializedName("key") val key: String,
    @SerializedName("type") val type: String,  // movie, show
    @SerializedName("title") val title: String,
    @SerializedName("agent") val agent: String?,
    @SerializedName("scanner") val scanner: String?,
    @SerializedName("language") val language: String?,
    @SerializedName("uuid") val uuid: String?,
    @SerializedName("count") val count: Int?,
    @SerializedName("scannedAt") val scannedAt: Long?,
    @SerializedName("createdAt") val createdAt: Long?,
    @SerializedName("updatedAt") val updatedAt: Long?
)

data class DirectoryDto(
    @SerializedName("key") val key: String?,
    @SerializedName("title") val title: String?,
    @SerializedName("type") val type: String?
)

// === Hubs (Recommendations) DTOs ===

data class HubsResponse(
    @SerializedName("MediaContainer") val mediaContainer: HubsContainer?
)

data class HubsContainer(
    @SerializedName("size") val size: Int?,
    @SerializedName("librarySectionID") val librarySectionId: Int?,
    @SerializedName("Hub") val hubs: List<StreamingHubDto>?
)

data class StreamingHubDto(
    @SerializedName("key") val key: String?,
    @SerializedName("hubIdentifier") val hubIdentifier: String?,
    @SerializedName("type") val type: String?,
    @SerializedName("title") val title: String = "",
    @SerializedName("context") val context: String?,  // e.g., "hub.streamingService", "hub.genre"
    @SerializedName("size") val size: Int?,
    @SerializedName("more") val more: Boolean?,
    @SerializedName("style") val style: String?,
    @SerializedName("promoted") val promoted: Boolean?,
    @SerializedName("Metadata") val metadata: List<MediaItemDto>?
)
