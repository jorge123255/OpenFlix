package com.openflix.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.MediaItem
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class SearchUiState(
    val query: String = "",
    val isLoading: Boolean = false,
    val results: List<MediaItem> = emptyList(),
    val groupedResults: Map<String, List<MediaItem>> = emptyMap(),
    val selectedGenre: String? = null
)

class SearchViewModel(
    private val mediaRepository: MediaRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    private var searchJob: Job? = null

    fun updateQuery(query: String) {
        _uiState.value = _uiState.value.copy(query = query, selectedGenre = null)
        searchJob?.cancel()
        if (query.isBlank()) {
            _uiState.value = _uiState.value.copy(results = emptyList(), groupedResults = emptyMap())
            return
        }
        searchJob = viewModelScope.launch {
            delay(300) // debounce
            performSearch(query)
        }
    }

    fun searchByGenre(genre: String) {
        _uiState.value = _uiState.value.copy(selectedGenre = genre, query = "")
        viewModelScope.launch {
            performSearch(genre)
        }
    }

    private suspend fun performSearch(query: String) {
        _uiState.value = _uiState.value.copy(isLoading = true)
        try {
            val results = mediaRepository.search(query)
            val grouped = results.groupBy { it.type.name }.mapKeys { (key, _) ->
                when (key) {
                    "MOVIE" -> "Movies"
                    "SHOW" -> "TV Shows"
                    "EPISODE" -> "Episodes"
                    "SEASON" -> "Seasons"
                    else -> key
                }
            }
            _uiState.value = _uiState.value.copy(
                isLoading = false,
                results = results,
                groupedResults = grouped
            )
        } catch (e: Exception) {
            _uiState.value = _uiState.value.copy(isLoading = false, results = emptyList(), groupedResults = emptyMap())
        }
    }
}
