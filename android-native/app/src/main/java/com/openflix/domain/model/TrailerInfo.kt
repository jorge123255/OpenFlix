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

/**
 * Represents a media item with multiple source versions.
 * Used for deduplication - same show from different libraries/sources.
 */
data class MergedMediaItem(
    val primary: MediaItem,
    val alternateSources: List<MediaSource> = emptyList()
) {
    /** All available source IDs including primary */
    val allSourceIds: List<String>
        get() = listOf(primary.id) + alternateSources.map { it.id }

    /** Total number of sources */
    val sourceCount: Int
        get() = 1 + alternateSources.size

    /** Check if this item has multiple sources */
    val hasMultipleSources: Boolean
        get() = alternateSources.isNotEmpty()
}

/**
 * Represents an alternate source for a media item
 */
data class MediaSource(
    val id: String,
    val libraryId: String?,
    val libraryTitle: String?,
    val quality: String? = null // e.g., "4K", "1080p"
)

/**
 * Key for deduplicating media items.
 * Uses normalized title + year for matching, with conservative handling of null years.
 */
data class DeduplicationKey(
    val normalizedTitle: String,
    val year: Int?,
    val hasYear: Boolean  // Track if year was provided to avoid false matches
) {
    companion object {
        fun from(item: MediaItem): DeduplicationKey {
            return DeduplicationKey(
                normalizedTitle = normalizeTitle(item.title),
                year = item.year,
                hasYear = item.year != null
            )
        }

        private fun normalizeTitle(title: String): String {
            return title
                .lowercase()
                .replace(Regex("[^a-z0-9]"), "") // Remove non-alphanumeric
                .trim()
        }
    }

    /**
     * Check if two items should be considered duplicates.
     * More conservative when year is missing to avoid false merges.
     */
    fun shouldMergeWith(other: DeduplicationKey): Boolean {
        if (normalizedTitle != other.normalizedTitle) return false

        // If both have years, they must match
        if (hasYear && other.hasYear) {
            return year == other.year
        }

        // If one has year and one doesn't, require exact title match (already normalized)
        // and title must be long enough to be unique (at least 8 chars)
        return normalizedTitle.length >= 8
    }
}
