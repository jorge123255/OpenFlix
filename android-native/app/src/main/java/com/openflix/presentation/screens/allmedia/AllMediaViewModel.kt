package com.openflix.presentation.screens.allmedia

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.Library
import com.openflix.domain.model.MediaItem
import com.openflix.presentation.navigation.NavRoutes
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class AllMediaViewModel @Inject constructor(
    private val mediaRepository: MediaRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val libraryId: String = savedStateHandle[NavRoutes.ARG_LIBRARY_ID] ?: ""
    private val mediaType: String = savedStateHandle[NavRoutes.ARG_MEDIA_TYPE] ?: "movie"

    private val _uiState = MutableStateFlow(AllMediaUiState())
    val uiState: StateFlow<AllMediaUiState> = _uiState.asStateFlow()

    private var currentPage = 0
    private val pageSize = 50

    init {
        loadLibraries()
    }

    private fun loadLibraries() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = mediaRepository.getLibraries()
            result.fold(
                onSuccess = { libraries ->
                    // Filter by media type (movie or show)
                    val filteredLibraries = libraries.filter { lib ->
                        lib.type == mediaType
                    }

                    val title = when (mediaType) {
                        "movie" -> "Movies"
                        "show" -> "TV Shows"
                        else -> "Library"
                    }

                    _uiState.update {
                        it.copy(
                            libraries = filteredLibraries,
                            title = title,
                            totalCount = filteredLibraries.sumOf { lib -> lib.itemCount ?: 0 }
                        )
                    }

                    // Load items from all libraries of this type
                    loadAllItems()
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load libraries")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load libraries"
                        )
                    }
                }
            )
        }
    }

    private fun loadAllItems() {
        viewModelScope.launch {
            val libraries = _uiState.value.libraries
            val allItems = mutableListOf<MediaItem>()

            for (library in libraries) {
                val result = mediaRepository.getHubItems(
                    hubId = library.id,
                    start = 0,
                    size = pageSize
                )
                result.fold(
                    onSuccess = { items ->
                        allItems.addAll(items)
                    },
                    onFailure = { error ->
                        Timber.e(error, "Failed to load items from library ${library.id}")
                    }
                )
            }

            // Sort by title
            val sortedItems = when (_uiState.value.sortBy) {
                SortOption.TITLE -> allItems.sortedBy { it.title.lowercase() }
                SortOption.DATE_ADDED -> allItems.sortedByDescending { it.addedAt }
                SortOption.YEAR -> allItems.sortedByDescending { it.year }
                SortOption.RATING -> allItems.sortedByDescending { it.rating }
            }

            // Extract available genres, years, and content ratings for filters
            val genres = allItems.flatMap { it.genres }.distinct().sorted()
            val years = allItems.mapNotNull { it.year }.distinct().sortedDescending()
            val contentRatings = allItems.mapNotNull { it.contentRating }
                .distinct()
                .sortedBy { rating ->
                    // Sort by typical rating order
                    when (rating.uppercase()) {
                        "G" -> 0
                        "TV-G" -> 1
                        "PG" -> 2
                        "TV-PG" -> 3
                        "PG-13" -> 4
                        "TV-14" -> 5
                        "R" -> 6
                        "TV-MA" -> 7
                        "NC-17" -> 8
                        "NR", "NOT RATED", "UNRATED" -> 9
                        else -> 10
                    }
                }

            _uiState.update {
                it.copy(
                    isLoading = false,
                    items = sortedItems,
                    allItems = sortedItems,
                    availableGenres = genres,
                    availableYears = years,
                    availableContentRatings = contentRatings,
                    hasMore = allItems.size >= pageSize
                )
            }

            Timber.d("Loaded ${allItems.size} ${mediaType} items")
        }
    }

    fun loadMore() {
        if (_uiState.value.isLoadingMore || !_uiState.value.hasMore) return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingMore = true) }

            currentPage++
            val start = currentPage * pageSize
            val libraries = _uiState.value.libraries
            val newItems = mutableListOf<MediaItem>()

            for (library in libraries) {
                val result = mediaRepository.getHubItems(
                    hubId = library.id,
                    start = start,
                    size = pageSize
                )
                result.fold(
                    onSuccess = { items ->
                        newItems.addAll(items)
                    },
                    onFailure = { error ->
                        Timber.e(error, "Failed to load more items from library ${library.id}")
                    }
                )
            }

            _uiState.update {
                val updatedAllItems = it.allItems + newItems
                it.copy(
                    isLoadingMore = false,
                    items = updatedAllItems,
                    allItems = updatedAllItems,
                    hasMore = newItems.size >= pageSize
                )
            }
        }
    }

    fun setSortBy(sortOption: SortOption) {
        _uiState.update { state ->
            val itemsToSort = if (state.searchQuery.isBlank()) state.allItems else state.items
            val sortedItems = when (sortOption) {
                SortOption.TITLE -> itemsToSort.sortedBy { it.title.lowercase() }
                SortOption.DATE_ADDED -> itemsToSort.sortedByDescending { it.addedAt }
                SortOption.YEAR -> itemsToSort.sortedByDescending { it.year }
                SortOption.RATING -> itemsToSort.sortedByDescending { it.rating }
            }
            val sortedAllItems = when (sortOption) {
                SortOption.TITLE -> state.allItems.sortedBy { it.title.lowercase() }
                SortOption.DATE_ADDED -> state.allItems.sortedByDescending { it.addedAt }
                SortOption.YEAR -> state.allItems.sortedByDescending { it.year }
                SortOption.RATING -> state.allItems.sortedByDescending { it.rating }
            }
            state.copy(sortBy = sortOption, items = sortedItems, allItems = sortedAllItems)
        }
    }

    fun search(query: String) {
        _uiState.update { state ->
            state.copy(searchQuery = query, items = applyFilters(state.copy(searchQuery = query)))
        }
    }

    fun setGenreFilter(genre: String?) {
        _uiState.update { state ->
            state.copy(selectedGenre = genre, items = applyFilters(state.copy(selectedGenre = genre)))
        }
    }

    fun setYearFilter(year: Int?) {
        _uiState.update { state ->
            state.copy(selectedYear = year, items = applyFilters(state.copy(selectedYear = year)))
        }
    }

    fun setContentRatingFilter(contentRating: String?) {
        _uiState.update { state ->
            state.copy(selectedContentRating = contentRating, items = applyFilters(state.copy(selectedContentRating = contentRating)))
        }
    }

    fun clearFilters() {
        _uiState.update { state ->
            state.copy(
                searchQuery = "",
                selectedGenre = null,
                selectedYear = null,
                selectedContentRating = null,
                items = state.allItems
            )
        }
    }

    private fun applyFilters(state: AllMediaUiState): List<MediaItem> {
        var filtered = state.allItems

        // Apply search query
        if (state.searchQuery.isNotBlank()) {
            filtered = filtered.filter {
                it.title.contains(state.searchQuery, ignoreCase = true) ||
                it.summary?.contains(state.searchQuery, ignoreCase = true) == true
            }
        }

        // Apply genre filter
        state.selectedGenre?.let { genre ->
            filtered = filtered.filter { it.genres.contains(genre) }
        }

        // Apply year filter
        state.selectedYear?.let { year ->
            filtered = filtered.filter { it.year == year }
        }

        // Apply content rating filter
        state.selectedContentRating?.let { rating ->
            filtered = filtered.filter { it.contentRating == rating }
        }

        return filtered
    }

    fun refresh() {
        currentPage = 0
        loadLibraries()
    }
}

data class AllMediaUiState(
    val isLoading: Boolean = false,
    val isLoadingMore: Boolean = false,
    val items: List<MediaItem> = emptyList(),
    val allItems: List<MediaItem> = emptyList(), // Original unfiltered items
    val libraries: List<Library> = emptyList(),
    val title: String = "Library",
    val totalCount: Int = 0,
    val hasMore: Boolean = true,
    val sortBy: SortOption = SortOption.TITLE,
    val searchQuery: String = "",
    val selectedGenre: String? = null,
    val selectedYear: Int? = null,
    val selectedContentRating: String? = null,
    val availableGenres: List<String> = emptyList(),
    val availableYears: List<Int> = emptyList(),
    val availableContentRatings: List<String> = emptyList(),
    val error: String? = null
)

enum class SortOption {
    TITLE,
    DATE_ADDED,
    YEAR,
    RATING
}
