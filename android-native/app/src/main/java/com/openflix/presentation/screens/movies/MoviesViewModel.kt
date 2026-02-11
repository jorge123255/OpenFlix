package com.openflix.presentation.screens.movies

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.MediaRepository
import com.openflix.data.repository.TmdbRepository
import com.openflix.domain.model.DeduplicationKey
import com.openflix.domain.model.GenreHub
import com.openflix.domain.model.Hub
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaSource
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.MergedMediaItem
import com.openflix.domain.model.TrailerInfo
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class MoviesViewModel @Inject constructor(
    private val mediaRepository: MediaRepository,
    private val tmdbRepository: TmdbRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(MoviesUiState())
    val uiState: StateFlow<MoviesUiState> = _uiState.asStateFlow()

    companion object {
        private const val FEATURED_ITEMS_COUNT = 8
        private const val MIN_GENRE_ITEMS = 3
        private const val MAX_GENRE_HUBS = 8
    }

    fun loadMovies() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = mediaRepository.getHomeHubs()

            result.fold(
                onSuccess = { hubs ->
                    // Filter hubs to only include those with movies
                    val movieHubs = hubs.filter { hub ->
                        hub.items.isNotEmpty() && hub.items.first().type == MediaType.MOVIE
                    }.filterNot { hub ->
                        // Exclude continue watching (handled separately)
                        hub.hubKey?.contains("ondeck", ignoreCase = true) == true ||
                        hub.hubKey?.contains("continue", ignoreCase = true) == true
                    }

                    // Get continue watching movies
                    val continueWatching = hubs
                        .filter { hub ->
                            hub.hubKey?.contains("ondeck", ignoreCase = true) == true ||
                            hub.hubKey?.contains("continue", ignoreCase = true) == true
                        }
                        .flatMap { it.items }
                        .filter { it.type == MediaType.MOVIE }

                    // Collect all movies and deduplicate
                    val allMoviesRaw = movieHubs.flatMap { it.items }

                    // Deduplicate movies from multiple sources
                    val (deduplicatedMovies, mergedMap) = deduplicateMovies(allMoviesRaw)

                    // Select featured items (prioritize promoted hubs, then recent/popular)
                    val featuredItems = selectFeaturedItems(movieHubs, deduplicatedMovies)

                    // Generate genre hubs from deduplicated movies
                    val genreHubs = generateGenreHubs(deduplicatedMovies)

                    // Count duplicates found
                    val duplicatesFound = allMoviesRaw.size - deduplicatedMovies.size

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            hubs = movieHubs,
                            continueWatching = continueWatching,
                            featuredItems = featuredItems,
                            currentFeaturedIndex = 0,
                            genreHubs = genreHubs,
                            mergedItems = mergedMap
                        )
                    }

                    Timber.d("Loaded ${movieHubs.size} movie hubs, ${featuredItems.size} featured, ${genreHubs.size} genre hubs, merged $duplicatesFound duplicates")

                    // Load trailers for featured items in background
                    loadTrailersForFeaturedItems(featuredItems)
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load movies")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load movies"
                        )
                    }
                }
            )
        }
    }

    /**
     * Deduplicate movies by title and year.
     * Returns the deduplicated list and a map of primary ID to MergedMediaItem.
     * Only merges items from DIFFERENT libraries to avoid false positives.
     */
    private fun deduplicateMovies(movies: List<MediaItem>): Pair<List<MediaItem>, Map<String, MergedMediaItem>> {
        val deduplicatedList = mutableListOf<MediaItem>()
        val mergedMap = mutableMapOf<String, MergedMediaItem>()
        val processedIds = mutableSetOf<String>()

        // Sort by rating first so best items are processed first
        val sortedMovies = movies.sortedWith(
            compareByDescending<MediaItem> { it.rating ?: 0.0 }
                .thenByDescending { it.addedAt ?: 0L }
                .thenByDescending { it.summary?.length ?: 0 }
        )

        for (movie in sortedMovies) {
            if (movie.id in processedIds) continue

            val movieKey = DeduplicationKey.from(movie)

            // Find all potential duplicates (from DIFFERENT libraries only)
            val duplicates = sortedMovies.filter { other ->
                other.id !in processedIds &&
                other.id != movie.id &&
                other.librarySectionId != movie.librarySectionId &&  // Must be from different library
                movieKey.shouldMergeWith(DeduplicationKey.from(other))
            }

            // Mark all as processed
            processedIds.add(movie.id)
            duplicates.forEach { processedIds.add(it.id) }

            if (duplicates.isEmpty()) {
                deduplicatedList.add(movie)
            } else {
                // Create merged entry
                val alternates = duplicates.map { item ->
                    MediaSource(
                        id = item.id,
                        libraryId = item.librarySectionId,
                        libraryTitle = item.librarySectionTitle
                    )
                }

                deduplicatedList.add(movie)
                mergedMap[movie.id] = MergedMediaItem(
                    primary = movie,
                    alternateSources = alternates
                )

                Timber.d("Merged ${duplicates.size + 1} sources for '${movie.title}': ${movie.librarySectionTitle} + ${duplicates.map { it.librarySectionTitle }}")
            }
        }

        return Pair(deduplicatedList, mergedMap)
    }

    /**
     * Get alternate source IDs for a media item (for failover)
     */
    fun getAlternateSources(mediaId: String): List<String> {
        val merged = _uiState.value.mergedItems[mediaId]
        return merged?.alternateSources?.map { it.id } ?: emptyList()
    }

    /**
     * Select featured items for the hero carousel.
     * Prioritizes:
     * 1. Items from promoted hubs
     * 2. Recently added items
     * 3. Popular/highly rated items
     */
    private fun selectFeaturedItems(hubs: List<Hub>, allMovies: List<MediaItem>): List<MediaItem> {
        val featured = mutableListOf<MediaItem>()
        val usedIds = mutableSetOf<String>()

        // First, add items from promoted hubs
        hubs.filter { it.promoted || it.style == "hero" }
            .flatMap { it.items }
            .take(FEATURED_ITEMS_COUNT / 2)
            .forEach { item ->
                if (item.id !in usedIds) {
                    featured.add(item)
                    usedIds.add(item.id)
                }
            }

        // Fill remaining with recently added or high-rated items
        val remaining = FEATURED_ITEMS_COUNT - featured.size
        if (remaining > 0) {
            // Sort by addedAt (most recent first), then by rating
            val candidates = allMovies
                .filter { it.id !in usedIds }
                .sortedWith(compareByDescending<MediaItem> { it.addedAt ?: 0L }
                    .thenByDescending { it.rating ?: 0.0 })
                .take(remaining)

            featured.addAll(candidates)
        }

        return featured.take(FEATURED_ITEMS_COUNT)
    }

    /**
     * Generate genre-based content hubs.
     * Groups items by genre and returns top genres with most content.
     */
    private fun generateGenreHubs(allItems: List<MediaItem>): List<GenreHub> {
        // Group items by genre
        val genreMap = mutableMapOf<String, MutableList<MediaItem>>()

        allItems.forEach { item ->
            item.genres.forEach { genre ->
                genreMap.getOrPut(genre) { mutableListOf() }.add(item)
            }
        }

        // Filter genres with minimum items and sort by count
        return genreMap
            .filter { it.value.size >= MIN_GENRE_ITEMS }
            .entries
            .sortedByDescending { it.value.size }
            .take(MAX_GENRE_HUBS)
            .map { (genre, items) ->
                GenreHub(
                    genre = genre,
                    items = items.distinctBy { it.id }.take(20) // Limit items per genre
                )
            }
    }

    /**
     * Load trailers for featured items from TMDB
     */
    private fun loadTrailersForFeaturedItems(items: List<MediaItem>) {
        viewModelScope.launch {
            val trailers = mutableMapOf<String, TrailerInfo>()

            items.forEach { item ->
                try {
                    val trailer = tmdbRepository.getMovieTrailer(
                        mediaId = item.id,
                        plexGuid = item.key,
                        title = item.title,
                        year = item.year
                    )
                    if (trailer != null) {
                        trailers[item.id] = trailer
                        // Update state incrementally as trailers are loaded
                        _uiState.update { it.copy(trailers = trailers.toMap()) }
                    }
                } catch (e: Exception) {
                    Timber.w(e, "Failed to load trailer for ${item.title}")
                }
            }

            Timber.d("Loaded ${trailers.size} trailers for featured items")
        }
    }

    /**
     * Set the current featured index (for manual carousel control)
     */
    fun setFeaturedIndex(index: Int) {
        val items = _uiState.value.featuredItems
        if (index in items.indices) {
            _uiState.update { it.copy(currentFeaturedIndex = index) }
        }
    }

    fun refresh() {
        loadMovies()
    }
}

data class MoviesUiState(
    val isLoading: Boolean = false,
    val hubs: List<Hub> = emptyList(),
    val continueWatching: List<MediaItem> = emptyList(),
    val featuredItems: List<MediaItem> = emptyList(),
    val currentFeaturedIndex: Int = 0,
    val trailers: Map<String, TrailerInfo> = emptyMap(),
    val genreHubs: List<GenreHub> = emptyList(),
    val mergedItems: Map<String, MergedMediaItem> = emptyMap(),
    val error: String? = null
) {
    // Backwards compatibility - return first featured item
    val featuredItem: MediaItem?
        get() = featuredItems.getOrNull(currentFeaturedIndex)

    /** Get alternate sources for failover */
    fun getAlternateSources(mediaId: String): List<String> {
        return mergedItems[mediaId]?.alternateSources?.map { it.id } ?: emptyList()
    }
}
