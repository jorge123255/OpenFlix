package com.openflix.domain.model

enum class MediaType(val value: String) {
    MOVIE("movie"),
    SHOW("show"),
    SEASON("season"),
    EPISODE("episode"),
    ARTIST("artist"),
    ALBUM("album"),
    TRACK("track"),
    PHOTO("photo");

    val displayName: String get() = when (this) {
        MOVIE -> "Movie"
        SHOW -> "TV Show"
        SEASON -> "Season"
        EPISODE -> "Episode"
        ARTIST -> "Artist"
        ALBUM -> "Album"
        TRACK -> "Track"
        PHOTO -> "Photo"
    }

    companion object {
        fun fromValue(value: String): MediaType =
            entries.firstOrNull { it.value == value } ?: MOVIE
    }
}

data class MediaItem(
    val id: Int,
    val key: String,
    val guid: String? = null,
    val type: MediaType,
    val title: String,
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
    val addedAt: Long? = null,
    val originallyAvailableAt: String? = null,
    val leafCount: Int? = null,
    val viewedLeafCount: Int? = null,
    val childCount: Int? = null,
    val index: Int? = null,
    val parentIndex: Int? = null,
    val parentRatingKey: Int? = null,
    val parentTitle: String? = null,
    val grandparentRatingKey: Int? = null,
    val grandparentTitle: String? = null,
    val grandparentThumb: String? = null,
    val genres: List<String> = emptyList(),
    val roles: List<CastMember> = emptyList(),
    val directors: List<String> = emptyList(),
    val writers: List<String> = emptyList(),
    val countries: List<String> = emptyList(),
    val mediaVersions: List<MediaVersion> = emptyList()
) {
    val progressPercent: Double get() {
        val d = duration ?: return 0.0
        val o = viewOffset ?: return 0.0
        if (d <= 0) return 0.0
        return o.toDouble() / d.toDouble()
    }

    val progress: Double get() = progressPercent

    val remainingDuration: Int? get() {
        val d = duration ?: return null
        val o = viewOffset ?: 0
        return maxOf(0, d - o)
    }

    val isWatched: Boolean get() = (viewCount ?: 0) > 0

    val isInProgress: Boolean get() {
        val o = viewOffset ?: return false
        if (o <= 0) return false
        return progressPercent < 0.9
    }

    val episodeLabel: String? get() {
        if (type != MediaType.EPISODE) return null
        val s = parentIndex ?: return null
        val e = index ?: return null
        return "S$s E$e"
    }

    val fullTitle: String get() = when (type) {
        MediaType.EPISODE -> {
            val showTitle = grandparentTitle ?: parentTitle
            val label = episodeLabel
            if (showTitle != null && label != null) "$showTitle - $label - $title"
            else title
        }
        MediaType.SEASON -> {
            val showTitle = parentTitle
            if (showTitle != null) "$showTitle - Season ${index ?: 0}"
            else title
        }
        else -> title
    }

    val bestThumb: String? get() = when (type) {
        MediaType.EPISODE -> thumb ?: grandparentThumb
        else -> thumb
    }

    val primaryStream: MediaStream? get() =
        mediaVersions.firstOrNull()?.parts?.firstOrNull()?.streams?.firstOrNull { it.type == StreamType.VIDEO }

    val resolution: String? get() {
        val stream = primaryStream
        if (stream != null) {
            val h = stream.height
            if (h != null) {
                return when {
                    h >= 2160 -> "4K"
                    h >= 1080 -> "1080p"
                    h >= 720 -> "720p"
                    else -> "${h}p"
                }
            }
        }
        return mediaVersions.firstOrNull()?.resolution
    }

    val audioChannels: String? get() {
        val ch = mediaVersions.firstOrNull()?.audioChannels ?: return null
        return when (ch) {
            8 -> "7.1"
            6 -> "5.1"
            2 -> "Stereo"
            1 -> "Mono"
            else -> "$ch ch"
        }
    }
}

data class CastMember(
    val id: Int? = null,
    val name: String,
    val role: String? = null,
    val thumb: String? = null
)

data class MediaVersion(
    val id: Int,
    val duration: Int? = null,
    val bitrate: Int? = null,
    val width: Int? = null,
    val height: Int? = null,
    val audioChannels: Int? = null,
    val audioCodec: String? = null,
    val videoCodec: String? = null,
    val resolution: String? = null,
    val container: String? = null,
    val parts: List<MediaPart> = emptyList()
)

data class MediaPart(
    val id: Int,
    val key: String,
    val duration: Int? = null,
    val file: String? = null,
    val size: Long? = null,
    val container: String? = null,
    val streams: List<MediaStream> = emptyList()
)

enum class StreamType(val value: Int) {
    VIDEO(1), AUDIO(2), SUBTITLE(3);
    companion object {
        fun fromValue(value: Int): StreamType = entries.firstOrNull { it.value == value } ?: VIDEO
    }
}

data class MediaStream(
    val id: Int,
    val type: StreamType,
    val codec: String? = null,
    val index: Int? = null,
    val language: String? = null,
    val languageCode: String? = null,
    val displayTitle: String? = null,
    val selected: Boolean = false,
    val forced: Boolean = false,
    val isDefault: Boolean = false,
    val title: String? = null,
    val width: Int? = null,
    val height: Int? = null,
    val bitrate: Int? = null,
    val frameRate: Double? = null,
    val channels: Int? = null,
    val samplingRate: Int? = null
)
