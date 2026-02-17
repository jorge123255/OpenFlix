package com.openflix.domain.model

/**
 * Core media domain models
 */

enum class MediaType {
    MOVIE,
    SHOW,
    SEASON,
    EPISODE,
    CLIP,
    PLAYLIST,
    UNKNOWN;

    companion object {
        fun fromString(type: String?): MediaType {
            return when (type?.lowercase()) {
                "movie" -> MOVIE
                "show" -> SHOW
                "season" -> SEASON
                "episode" -> EPISODE
                "clip" -> CLIP
                "playlist" -> PLAYLIST
                else -> UNKNOWN
            }
        }
    }
}

data class MediaItem(
    val id: String,
    val key: String?,
    val ratingKey: String?,
    val type: MediaType,
    val title: String,
    val originalTitle: String?,
    val tagline: String?,
    val summary: String?,
    val thumb: String?,
    val art: String?,
    val banner: String?,
    val year: Int?,
    val duration: Long?,  // milliseconds
    val viewOffset: Long?,  // watch progress in milliseconds
    val viewCount: Int?,
    val addedAt: Long?,
    val contentRating: String?,
    val rating: Double?,
    val audienceRating: Double?,
    val studio: String?,
    val genres: List<String>,
    val directors: List<String>,
    val writers: List<String>,
    val cast: List<CastMember>,
    val librarySectionId: String?,
    val librarySectionTitle: String?,

    // For TV shows/episodes
    val parentRatingKey: String?,
    val parentTitle: String?,
    val grandparentRatingKey: String?,
    val grandparentTitle: String?,
    val grandparentThumb: String?,
    val grandparentArt: String?,
    val index: Int?,  // episode/season number
    val parentIndex: Int?,  // season number for episodes
    val leafCount: Int?,  // episode count
    val viewedLeafCount: Int?,
    val childCount: Int?  // season count for shows
)

data class CastMember(
    val name: String,
    val role: String?,
    val thumb: String?
)

// Extension properties for MediaItem
val MediaItem.isWatched: Boolean
    get() = viewCount != null && viewCount > 0

val MediaItem.watchProgress: Float
    get() {
        val offset = viewOffset ?: 0L
        val total = duration ?: 1L
        return if (total > 0) (offset.toFloat() / total.toFloat()).coerceIn(0f, 1f) else 0f
    }

val MediaItem.displayTitle: String
    get() = when (type) {
        MediaType.EPISODE -> "$grandparentTitle - S${parentIndex}E$index - $title"
        else -> title
    }

val MediaItem.posterUrl: String?
    get() = when (type) {
        MediaType.EPISODE -> grandparentThumb ?: thumb
        else -> thumb
    }

val MediaItem.backdropUrl: String?
    get() = art ?: grandparentArt

data class Hub(
    val id: String,
    val key: String?,
    val hubKey: String?,
    val type: String,
    val hubType: String?,
    val title: String,
    val style: String?,
    val promoted: Boolean,
    val size: Int,
    val more: Boolean,
    val items: List<MediaItem>,
    val context: String? = null  // e.g., "hub.streamingService", "hub.genre"
)

data class Library(
    val id: String,
    val key: String?,
    val title: String,
    val type: String,
    val thumb: String?,
    val art: String?,
    val itemCount: Int?
)

data class Season(
    val id: String,
    val ratingKey: String?,
    val title: String,
    val index: Int,
    val thumb: String?,
    val leafCount: Int?,
    val viewedLeafCount: Int?,
    val parentRatingKey: String?
) {
    val isFullyWatched: Boolean
        get() = leafCount != null && viewedLeafCount != null && viewedLeafCount >= leafCount
}

data class Episode(
    val id: String,
    val ratingKey: String?,
    val title: String,
    val index: Int,
    val parentIndex: Int?,
    val summary: String?,
    val thumb: String?,
    val duration: Long?,
    val viewOffset: Long?,
    val originallyAvailableAt: String?,
    val parentRatingKey: String?,
    val grandparentRatingKey: String?
) {
    val displayTitle: String
        get() = "S${parentIndex}E$index - $title"

    val watchProgress: Float
        get() {
            val offset = viewOffset ?: 0L
            val total = duration ?: 1L
            return if (total > 0) (offset.toFloat() / total.toFloat()).coerceIn(0f, 1f) else 0f
        }
}

data class Playlist(
    val id: String,
    val key: String?,
    val title: String,
    val summary: String?,
    val thumb: String?,
    val composite: String?,
    val duration: Long?,
    val leafCount: Int?,
    val playlistType: String?,
    val smart: Boolean?,
    val items: List<MediaItem> = emptyList()
)

data class Chapter(
    val id: String?,
    val index: Int,
    val title: String?,
    val startTime: Long,  // milliseconds
    val endTime: Long?,
    val thumb: String?
)

data class IntroMarker(
    val start: Long,  // milliseconds
    val end: Long,
    val type: String?  // intro, credits
)

data class MediaVersion(
    val id: String?,
    val duration: Long?,
    val bitrate: Int?,
    val width: Int?,
    val height: Int?,
    val audioChannels: Int?,
    val audioCodec: String?,
    val videoCodec: String?,
    val videoResolution: String?,
    val container: String?
) {
    val displayName: String
        get() = buildString {
            videoResolution?.let { append(it) }
            if (audioChannels != null && audioChannels > 2) {
                append(" • ${audioChannels}ch")
            }
            videoCodec?.let { append(" • $it") }
        }.ifEmpty { "Default" }
}

data class MediaStream(
    val id: String?,
    val streamType: StreamType,
    val index: Int?,
    val codec: String?,
    val language: String?,
    val languageCode: String?,
    val title: String?,
    val displayTitle: String?,
    val selected: Boolean?,
    val default: Boolean?,
    val forced: Boolean?,

    // Video specific
    val width: Int?,
    val height: Int?,

    // Audio specific
    val channels: Int?
)

enum class StreamType {
    VIDEO,
    AUDIO,
    SUBTITLE,
    UNKNOWN;

    companion object {
        fun fromInt(type: Int?): StreamType {
            return when (type) {
                1 -> VIDEO
                2 -> AUDIO
                3 -> SUBTITLE
                else -> UNKNOWN
            }
        }
    }
}
