package com.openflix.domain.model

enum class LibrarySectionType(val value: String) {
    MOVIE("movie"),
    SHOW("show"),
    ARTIST("artist"),
    PHOTO("photo"),
    MIXED("mixed");

    val displayName: String get() = when (this) {
        MOVIE -> "Movies"
        SHOW -> "TV Shows"
        ARTIST -> "Music"
        PHOTO -> "Photos"
        MIXED -> "Mixed"
    }

    companion object {
        fun fromValue(value: String): LibrarySectionType =
            entries.firstOrNull { it.value == value } ?: MIXED
    }
}

data class LibrarySection(
    val id: Int,
    val key: String,
    val type: LibrarySectionType,
    val title: String,
    val agent: String? = null,
    val scanner: String? = null,
    val language: String? = null,
    val uuid: String? = null,
    val updatedAt: Long? = null,
    val scannedAt: Long? = null,
    val hidden: Boolean = false
)

data class Hub(
    val key: String? = null,
    val hubKey: String? = null,
    val hubIdentifier: String? = null,
    val type: String,
    val title: String,
    val size: Int = 0,
    val more: Boolean = false,
    val style: String? = null,
    val promoted: Boolean = false,
    val items: List<MediaItem> = emptyList()
) {
    val id: String get() = hubIdentifier ?: key ?: title
}

data class WatchlistItem(
    val id: Int,
    val mediaId: Int,
    val addedAt: Long,
    val media: MediaItem? = null
)

data class Playlist(
    val id: Int,
    val name: String,
    val itemCount: Int = 0,
    val duration: Int? = null,
    val thumb: String? = null,
    val createdAt: Long? = null,
    val updatedAt: Long? = null
)

data class PlaylistItem(
    val id: Int,
    val playlistId: Int,
    val mediaId: Int,
    val index: Int,
    val addedAt: Long? = null,
    val media: MediaItem? = null
)

data class MediaCollection(
    val id: Int,
    val key: String,
    val title: String,
    val summary: String? = null,
    val thumb: String? = null,
    val art: String? = null,
    val childCount: Int = 0,
    val addedAt: Long? = null,
    val updatedAt: Long? = null
)
