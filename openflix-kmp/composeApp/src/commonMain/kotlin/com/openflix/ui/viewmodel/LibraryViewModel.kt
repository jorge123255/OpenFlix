package com.openflix.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.DVRRepository
import com.openflix.data.repository.WatchlistRepository
import com.openflix.domain.model.Recording
import com.openflix.domain.model.WatchlistItem
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class LibraryUiState(
    val isLoading: Boolean = true,
    val recordings: List<Recording> = emptyList(),
    val watchlist: List<WatchlistItem> = emptyList(),
    val error: String? = null
)

class LibraryViewModel(
    private val dvrRepository: DVRRepository,
    private val watchlistRepository: WatchlistRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow(LibraryUiState())
    val uiState: StateFlow<LibraryUiState> = _uiState.asStateFlow()

    fun loadRecordings() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val recordings = dvrRepository.loadRecordings()
                _uiState.value = _uiState.value.copy(isLoading = false, recordings = recordings)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.message)
            }
        }
    }

    fun loadWatchlist() {
        viewModelScope.launch {
            try {
                val items = watchlistRepository.loadWatchlist()
                _uiState.value = _uiState.value.copy(watchlist = items)
            } catch (_: Exception) { }
        }
    }

    fun deleteRecording(id: Int) {
        viewModelScope.launch {
            try {
                dvrRepository.deleteRecording(id)
                _uiState.value = _uiState.value.copy(
                    recordings = _uiState.value.recordings.filter { it.id != id }
                )
            } catch (_: Exception) { }
        }
    }
}
