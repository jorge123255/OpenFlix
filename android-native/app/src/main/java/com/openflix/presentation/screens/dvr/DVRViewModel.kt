package com.openflix.presentation.screens.dvr

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.DVRRepository
import com.openflix.domain.model.Recording
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class DVRViewModel @Inject constructor(
    private val dvrRepository: DVRRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(DVRUiState())
    val uiState: StateFlow<DVRUiState> = _uiState.asStateFlow()

    fun loadRecordings() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = dvrRepository.getRecordings()

            result.fold(
                onSuccess = { recordings ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            recordings = recordings.sortedByDescending { r -> r.startTime }
                        )
                    }
                    Timber.d("Loaded ${recordings.size} recordings")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load recordings")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load recordings"
                        )
                    }
                }
            )
        }
    }

    fun deleteRecording(recordingId: String) {
        viewModelScope.launch {
            val result = dvrRepository.deleteRecording(recordingId)

            result.fold(
                onSuccess = {
                    // Remove from list
                    _uiState.update { state ->
                        state.copy(
                            recordings = state.recordings.filter { it.id != recordingId }
                        )
                    }
                    Timber.d("Deleted recording: $recordingId")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to delete recording")
                }
            )
        }
    }
}

data class DVRUiState(
    val isLoading: Boolean = false,
    val recordings: List<Recording> = emptyList(),
    val error: String? = null
)
