package com.openflix.domain.model

/**
 * Represents trailer information from TMDB.
 */
data class TrailerInfo(
    val youtubeKey: String,
    val name: String,
    val type: String = "Trailer",
    val backdropUrl: String? = null,
    val isOfficial: Boolean = false
) {
    /**
     * URL for YouTube video thumbnail (high quality)
     */
    val thumbnailUrl: String
        get() = "https://img.youtube.com/vi/$youtubeKey/maxresdefault.jpg"

    /**
     * URL for YouTube video thumbnail (medium quality fallback)
     */
    val thumbnailUrlMq: String
        get() = "https://img.youtube.com/vi/$youtubeKey/mqdefault.jpg"

    /**
     * Full YouTube watch URL
     */
    val youtubeWatchUrl: String
        get() = "https://www.youtube.com/watch?v=$youtubeKey"

    /**
     * YouTube embed URL (for WebView playback)
     */
    val youtubeEmbedUrl: String
        get() = "https://www.youtube.com/embed/$youtubeKey?autoplay=1&rel=0"
}

/**
 * Genre hub data for organizing content by genre
 */
data class GenreHub(
    val genre: String,
    val items: List<MediaItem>
)
