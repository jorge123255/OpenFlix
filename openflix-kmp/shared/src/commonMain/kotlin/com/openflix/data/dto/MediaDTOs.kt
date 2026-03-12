package com.openflix.data.dto

import com.openflix.domain.model.*
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class LibrarySectionsResponse(val MediaContainer: LibrarySectionsContainer? = null)

@Serializable
data class LibrarySectionsContainer(
    val size: Int? = null,
    val Directory: List<LibrarySectionDTO>? = null,
    val directories: List<LibrarySectionDTO>? = null
) {
    val allDirectories: List<LibrarySectionDTO> get() = Directory ?: directories ?: emptyList()
}

@Serializable
data class LibrarySectionDTO(
    val key: String,
    val type: String,
    val title: String,
    val agent: String? = null,
    val scanner: String? = null,
    val language: String? = null,
    val uuid: String? = null,
    val updatedAt: Int? = null,
    val scannedAt: Int? = null,
    val createdAt: Int? = null,
    val hidden: Int? = null,
    val count: Int? = null
) {
    val id: Int get() = key.toIntOrNull() ?: 0

    fun toDomain() = LibrarySection(
        id = id, key = key,
        type = LibrarySectionType.fromValue(type),
        title = title, agent = agent, scanner = scanner, language = language, uuid = uuid,
        updatedAt = updatedAt?.toLong()?.times(1000),
        scannedAt = scannedAt?.toLong()?.times(1000),
        hidden = (hidden ?: 0) == 1
    )
}

@Serializable
data class MediaContainerResponse(val MediaContainer: MediaContainer? = null)

@Serializable
data class MediaContainer(
    val size: Int? = null,
    val totalSize: Int? = null,
    val offset: Int? = null,
    val allowSync: Boolean? = null,
    val identifier: String? = null,
    val librarySectionID: Int? = null,
    val librarySectionTitle: String? = null,
    val librarySectionUUID: String? = null,
    val Metadata: List<MediaItemDTO>? = null,
    val Hub: List<HubDTO>? = null,
    val Directory: List<LibrarySectionDTO>? = null
)

@Serializable
data class MediaItemDTO(
    @SerialName("ratingKey") val ratingKeyValue: StringOrInt? = null,
    val key: String? = null,
    val guid: String? = null,
    val type: String? = null,
    val title: String? = null,
    val originalTitle: String? = null,
    val tagline: String? = null,
    val summary: String? = null,
    val thumb: String? = null,
    val art: String? = null,
    val banner: String? = null,
    val year: Int? = null,
    val duration: Int? = null,
    val viewOffset: Int? = null,
    val viewCount: Int? = null,
    val contentRating: String? = null,
    val audienceRating: Double? = null,
    val rating: Double? = null,
    val studio: String? = null,
    val addedAt: Int? = null,
    val updatedAt: Int? = null,
    val originallyAvailableAt: String? = null,
    val leafCount: Int? = null,
    val viewedLeafCount: Int? = null,
    val childCount: Int? = null,
    val index: Int? = null,
    val parentIndex: Int? = null,
    val parentRatingKey: StringOrInt? = null,
    val parentTitle: String? = null,
    val parentThumb: String? = null,
    val grandparentRatingKey: StringOrInt? = null,
    val grandparentTitle: String? = null,
    val grandparentThumb: String? = null,
    val grandparentArt: String? = null,
    val librarySectionID: Int? = null,
    val librarySectionTitle: String? = null,
    val Genre: List<GenreDTO>? = null,
    val Role: List<RoleDTO>? = null,
    val Director: List<DirectorDTO>? = null,
    val Writer: List<WriterDTO>? = null,
    val Country: List<CountryDTO>? = null,
    val Media: List<MediaVersionDTO>? = null,
    val streamUrl: String? = null
) {
    val ratingKeyInt: Int get() = ratingKeyValue?.intValue ?: 0
    val safeTitle: String get() = title ?: "Unknown"
    val safeType: String get() = type ?: "unknown"
    val safeKey: String get() = key ?: ""

    fun toDomain() = MediaItem(
        id = ratingKeyInt, key = safeKey, guid = guid,
        type = MediaType.fromValue(safeType),
        title = safeTitle, originalTitle = originalTitle, tagline = tagline, summary = summary,
        thumb = thumb, art = art, banner = banner, year = year,
        duration = duration, viewOffset = viewOffset, viewCount = viewCount,
        contentRating = contentRating, audienceRating = audienceRating, rating = rating,
        studio = studio,
        addedAt = addedAt?.toLong()?.times(1000),
        originallyAvailableAt = originallyAvailableAt,
        leafCount = leafCount, viewedLeafCount = viewedLeafCount, childCount = childCount,
        index = index, parentIndex = parentIndex,
        parentRatingKey = parentRatingKey?.intValue,
        parentTitle = parentTitle,
        grandparentRatingKey = grandparentRatingKey?.intValue,
        grandparentTitle = grandparentTitle, grandparentThumb = grandparentThumb,
        genres = Genre?.map { it.tag } ?: emptyList(),
        roles = Role?.map { CastMember(it.id, it.tag, it.role, it.thumb) } ?: emptyList(),
        directors = Director?.map { it.tag } ?: emptyList(),
        writers = Writer?.map { it.tag } ?: emptyList(),
        countries = Country?.map { it.tag } ?: emptyList(),
        mediaVersions = Media?.map { it.toDomain() } ?: emptyList()
    )
}

@Serializable
data class GenreDTO(val id: Int? = null, val tag: String)
@Serializable
data class RoleDTO(val id: Int? = null, val tag: String, val role: String? = null, val thumb: String? = null)
@Serializable
data class DirectorDTO(val id: Int? = null, val tag: String)
@Serializable
data class WriterDTO(val id: Int? = null, val tag: String)
@Serializable
data class CountryDTO(val id: Int? = null, val tag: String)

@Serializable
data class MediaVersionDTO(
    val id: Int? = null,
    val duration: Int? = null,
    val bitrate: Int? = null,
    val width: Int? = null,
    val height: Int? = null,
    val aspectRatio: Double? = null,
    val audioChannels: Int? = null,
    val audioCodec: String? = null,
    val videoCodec: String? = null,
    val videoResolution: String? = null,
    val container: String? = null,
    val videoFrameRate: String? = null,
    val Part: List<MediaPartDTO>? = null
) {
    fun toDomain() = MediaVersion(
        id = id ?: 0, duration = duration, bitrate = bitrate,
        width = width, height = height, audioChannels = audioChannels,
        audioCodec = audioCodec, videoCodec = videoCodec,
        resolution = videoResolution, container = container,
        parts = Part?.map { it.toDomain() } ?: emptyList()
    )
}

@Serializable
data class MediaPartDTO(
    val id: Int? = null,
    val key: String? = null,
    val duration: Int? = null,
    val file: String? = null,
    val size: Long? = null,
    val container: String? = null,
    val Stream: List<StreamDTO>? = null
) {
    fun toDomain() = MediaPart(
        id = id ?: 0, key = key ?: "",
        duration = duration, file = file, size = size, container = container,
        streams = Stream?.map { it.toDomain() } ?: emptyList()
    )
}

@Serializable
data class StreamDTO(
    val id: Int? = null,
    val streamType: Int? = null,
    val codec: String? = null,
    val index: Int? = null,
    val language: String? = null,
    val languageCode: String? = null,
    val displayTitle: String? = null,
    val selected: Boolean? = null,
    val forced: Boolean? = null,
    val default: Boolean? = null,
    val title: String? = null,
    val width: Int? = null,
    val height: Int? = null,
    val bitrate: Int? = null,
    val frameRate: Double? = null,
    val channels: Int? = null,
    val samplingRate: Int? = null
) {
    fun toDomain() = MediaStream(
        id = id ?: 0,
        type = StreamType.fromValue(streamType ?: 1),
        codec = codec, index = index, language = language,
        languageCode = languageCode, displayTitle = displayTitle,
        selected = selected ?: false, forced = forced ?: false,
        isDefault = default ?: false, title = title,
        width = width, height = height, bitrate = bitrate, frameRate = frameRate,
        channels = channels, samplingRate = samplingRate
    )
}

// Hubs
@Serializable
data class HubsResponse(val MediaContainer: HubsContainer? = null)

@Serializable
data class HubsContainer(
    val size: Int? = null,
    val librarySectionID: Int? = null,
    val Hub: List<HubDTO>? = null
)

@Serializable
data class HubDTO(
    val key: String? = null,
    val hubKey: String? = null,
    val type: String? = null,
    val hubIdentifier: String? = null,
    val title: String? = null,
    val context: String? = null,
    val size: Int? = null,
    val more: Boolean? = null,
    val style: String? = null,
    val promoted: Boolean? = null,
    val Metadata: List<MediaItemDTO>? = null
) {
    fun toDomain() = Hub(
        key = key, hubKey = hubKey, hubIdentifier = hubIdentifier,
        type = type ?: "unknown", title = title ?: "",
        size = size ?: 0, more = more ?: false, style = style,
        promoted = promoted ?: false,
        items = Metadata?.map { it.toDomain() } ?: emptyList()
    )
}

// Search
@Serializable
data class SearchResponse(val MediaContainer: SearchContainer? = null)

@Serializable
data class SearchContainer(val Hub: List<SearchHubDTO>? = null)

@Serializable
data class SearchHubDTO(
    val type: String? = null,
    val title: String? = null,
    val size: Int? = null,
    val Metadata: List<MediaItemDTO>? = null
)

// Playback
@Serializable
data class PlaybackURLResponse(
    val url: String,
    @SerialName("protocol") val protocol_: String? = null,
    @SerialName("direct_play") val directPlay: Boolean? = null,
    val transcoding: Boolean? = null
)

// Watchlist
@Serializable
data class WatchlistResponse(
    val items: List<WatchlistItemDTO>? = null,
    val MediaContainer: MediaContainer? = null
) {
    val allItems: List<WatchlistItemDTO> get() = items ?: emptyList()
}

@Serializable
data class WatchlistItemDTO(
    val id: Int? = null,
    val mediaId: Int? = null,
    val addedAt: String? = null,
    val media: MediaItemDTO? = null
) {
    fun toDomain() = WatchlistItem(
        id = id ?: 0, mediaId = mediaId ?: 0,
        addedAt = addedAt?.let { parseIso8601(it) } ?: currentTimeMs(),
        media = media?.toDomain()
    )
}

// Playlists
@Serializable
data class PlaylistsResponse(
    val playlists: List<PlaylistDTO>? = null,
    val MediaContainer: PlaylistsContainer? = null
) {
    val allPlaylists: List<PlaylistDTO> get() = playlists ?: emptyList()
}

@Serializable
data class PlaylistsContainer(val Playlist: List<PlaylistDTO>? = null)

@Serializable
data class PlaylistDTO(
    val id: Int? = null,
    val ratingKey: String? = null,
    val name: String? = null,
    val title: String? = null,
    val itemCount: Int? = null,
    val leafCount: Int? = null,
    val duration: Int? = null,
    val thumb: String? = null,
    val createdAt: String? = null,
    val updatedAt: String? = null
) {
    val safeId: Int get() = id ?: ratingKey?.toIntOrNull() ?: 0
    val safeName: String get() = name ?: title ?: "Playlist"

    fun toDomain() = Playlist(
        id = safeId, name = safeName,
        itemCount = itemCount ?: leafCount ?: 0,
        duration = duration, thumb = thumb,
        createdAt = createdAt?.let { parseIso8601(it) },
        updatedAt = updatedAt?.let { parseIso8601(it) }
    )
}

@Serializable
data class PlaylistItemsResponse(val items: List<PlaylistItemDTO> = emptyList())

@Serializable
data class PlaylistItemDTO(
    val id: Int,
    val playlistId: Int,
    val mediaId: Int,
    val index: Int,
    val addedAt: String? = null,
    val media: MediaItemDTO? = null
) {
    fun toDomain() = PlaylistItem(
        id = id, playlistId = playlistId, mediaId = mediaId, index = index,
        addedAt = addedAt?.let { parseIso8601(it) },
        media = media?.toDomain()
    )
}

// Collections
@Serializable
data class CollectionsResponse(val MediaContainer: CollectionsContainer)

@Serializable
data class CollectionsContainer(val Metadata: List<CollectionDTO>? = null)

@Serializable
data class CollectionDTO(
    val ratingKey: String,
    val key: String,
    val type: String,
    val title: String,
    val summary: String? = null,
    val thumb: String? = null,
    val art: String? = null,
    val childCount: Int? = null,
    val addedAt: Int? = null,
    val updatedAt: Int? = null
) {
    fun toDomain() = MediaCollection(
        id = ratingKey.toIntOrNull() ?: 0,
        key = key, title = title, summary = summary, thumb = thumb, art = art,
        childCount = childCount ?: 0,
        addedAt = addedAt?.toLong()?.times(1000),
        updatedAt = updatedAt?.toLong()?.times(1000)
    )
}
