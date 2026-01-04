package com.openflix.presentation.screens.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.MediaItem
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class SearchViewModel @Inject constructor(
    private val mediaRepository: MediaRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SearchUiState())
    val uiState: StateFlow<SearchUiState> = _uiState.asStateFlow()

    private var searchJob: Job? = null

    fun updateQuery(query: String) {
        _uiState.update { it.copy(query = query) }

        // Debounce search
        searchJob?.cancel()
        searchJob = viewModelScope.launch {
            delay(300) // Debounce
            if (query.length >= 2) {
                search(query)
            } else {
                _uiState.update { it.copy(results = emptyList(), isLoading = false) }
            }
        }
    }

    private suspend fun search(query: String) {
        _uiState.update { it.copy(isLoading = true) }

        val result = mediaRepository.search(query)

        result.fold(
            onSuccess = { items ->
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        results = items
                    )
                }
                Timber.d("Found ${items.size} results for: $query")
            },
            onFailure = { error ->
                Timber.e(error, "Search failed")
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        results = emptyList()
                    )
                }
            }
        )
    }

    fun clearSearch() {
        _uiState.update { SearchUiState() }
    }
}

data class SearchUiState(
    val query: String = "",
    val isLoading: Boolean = false,
    val results: List<MediaItem> = emptyList()
)
