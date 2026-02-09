package com.openflix.presentation.screens.tvshows

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.MediaRepository
import com.openflix.data.repository.TmdbRepository
import com.openflix.domain.model.GenreHub
import com.openflix.domain.model.Hub
import com.openflix.domain.model.MediaItem
import com.openflix.domain.model.MediaType
import com.openflix.domain.model.TrailerInfo
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class TVShowsViewModel @Inject constructor(
    private val mediaRepository: MediaRepository,
    private val tmdbRepository: TmdbRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TVShowsUiState())
    val uiState: StateFlow<TVShowsUiState> = _uiState.asStateFlow()

    companion object {
        private const val FEATURED_ITEMS_COUNT = 8
        private const val MIN_GENRE_ITEMS = 3
        private const val MAX_GENRE_HUBS = 8
    }

    fun loadTVShows() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = mediaRepository.getHomeHubs()

            result.fold(
                onSuccess = { hubs ->
                    // Filter hubs to only include those with shows or episodes
                    val showHubs = hubs.filter { hub ->
                        hub.items.isNotEmpty() &&
                        (hub.items.first().type == MediaType.SHOW ||
                         hub.items.first().type == MediaType.EPISODE ||
                         hub.items.first().type == MediaType.SEASON)
                    }.filterNot { hub ->
                        // Exclude continue watching (handled separately)
                        hub.hubKey?.contains("ondeck", ignoreCase = true) == true ||
                        hub.hubKey?.contains("continue", ignoreCase = true) == true
                    }

                    // Get continue watching episodes
                    val continueWatching = hubs
                        .filter { hub ->
                            hub.hubKey?.contains("ondeck", ignoreCase = true) == true ||
                            hub.hubKey?.contains("continue", ignoreCase = true) == true
                        }
                        .flatMap { it.items }
                        .filter { it.type == MediaType.EPISODE }

                    // Collect all shows for featured and genre hubs
                    val allShows = showHubs
                        .flatMap { it.items }
                        .filter { it.type == MediaType.SHOW }
                        .distinctBy { it.id }

                    // Select featured items (prioritize promoted hubs, then recent/popular)
                    val featuredItems = selectFeaturedItems(showHubs, allShows)

                    // Generate genre hubs
                    val genreHubs = generateGenreHubs(allShows)

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            hubs = showHubs,
                            continueWatching = continueWatching,
                            featuredItems = featuredItems,
                            currentFeaturedIndex = 0,
                            genreHubs = genreHubs
                        )
                    }

                    Timber.d("Loaded ${showHubs.size} TV show hubs, ${featuredItems.size} featured, ${genreHubs.size} genre hubs")

                    // Load trailers for featured items in background
                    loadTrailersForFeaturedItems(featuredItems)
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load TV shows")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load TV shows"
                        )
                    }
                }
            )
        }
    }

    /**
     * Select featured items for the hero carousel.
     * Prioritizes:
     * 1. Items from promoted hubs
     * 2. Recently added items
     * 3. Popular/highly rated items
     */
    private fun selectFeaturedItems(hubs: List<Hub>, allShows: List<MediaItem>): List<MediaItem> {
        val featured = mutableListOf<MediaItem>()
        val usedIds = mutableSetOf<String>()

        // First, add items from promoted hubs
        hubs.filter { it.promoted || it.style == "hero" }
            .flatMap { it.items }
            .filter { it.type == MediaType.SHOW }
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
            val candidates = allShows
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
                    val trailer = tmdbRepository.getTVTrailer(
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

            Timber.d("Loaded ${trailers.size} trailers for featured TV shows")
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
        loadTVShows()
    }
}

data class TVShowsUiState(
    val isLoading: Boolean = false,
    val hubs: List<Hub> = emptyList(),
    val continueWatching: List<MediaItem> = emptyList(),
    val featuredItems: List<MediaItem> = emptyList(),
    val currentFeaturedIndex: Int = 0,
    val trailers: Map<String, TrailerInfo> = emptyMap(),
    val genreHubs: List<GenreHub> = emptyList(),
    val error: String? = null
) {
    // Backwards compatibility - return first featured item
    val featuredItem: MediaItem?
        get() = featuredItems.getOrNull(currentFeaturedIndex)
}
