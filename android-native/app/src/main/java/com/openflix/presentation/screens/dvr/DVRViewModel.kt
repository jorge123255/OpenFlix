package com.openflix.presentation.screens.dvr

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.DVRRepository
import com.openflix.domain.model.Recording
import com.openflix.domain.model.RecordingStats
import com.openflix.domain.model.RecordingStatsData
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
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

    private var statsPollingJob: Job? = null

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

                    // Start polling for stats if there are active recordings
                    val hasActiveRecordings = recordings.any { it.status.name == "RECORDING" }
                    if (hasActiveRecordings) {
                        startStatsPolling()
                    }
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

    private fun startStatsPolling() {
        // Cancel any existing polling
        statsPollingJob?.cancel()

        statsPollingJob = viewModelScope.launch {
            while (true) {
                loadRecordingStats()
                delay(5000) // Poll every 5 seconds
            }
        }
    }

    fun stopStatsPolling() {
        statsPollingJob?.cancel()
        statsPollingJob = null
    }

    private suspend fun loadRecordingStats() {
        val result = dvrRepository.getRecordingStats()

        result.fold(
            onSuccess = { statsData ->
                _uiState.update { it.copy(recordingStats = statsData) }

                // If stats show failed recordings, refresh the recordings list
                val hasFailedRecordings = statsData.stats.any { it.isFailed }
                if (hasFailedRecordings) {
                    // Refresh recordings list to get updated statuses
                    loadRecordings()
                }

                // Stop polling if no more active recordings
                if (statsData.activeCount == 0) {
                    stopStatsPolling()
                }
            },
            onFailure = { error ->
                Timber.e(error, "Failed to load recording stats")
            }
        )
    }

    fun getStatsForRecording(recordingId: String): RecordingStats? {
        return _uiState.value.recordingStats?.getStatsForRecording(recordingId)
    }

    override fun onCleared() {
        super.onCleared()
        stopStatsPolling()
    }
}

data class DVRUiState(
    val isLoading: Boolean = false,
    val recordings: List<Recording> = emptyList(),
    val recordingStats: RecordingStatsData? = null,
    val error: String? = null
)
