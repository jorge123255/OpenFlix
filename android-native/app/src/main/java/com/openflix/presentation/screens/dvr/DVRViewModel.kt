package com.openflix.presentation.screens.dvr

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.DVRRepository
import com.openflix.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

enum class DVRSortOrder {
    DATE_DESC, DATE_ASC, TITLE_ASC, TITLE_DESC, SIZE_DESC
}

enum class DVRViewMode {
    LIST, GROUPED
}

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

    // ============ Series Rules ============

    fun loadSeriesRules() {
        viewModelScope.launch {
            val result = dvrRepository.getSeriesRules()
            result.fold(
                onSuccess = { rules ->
                    _uiState.update { it.copy(seriesRules = rules) }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load series rules")
                }
            )
        }
    }

    fun toggleSeriesRule(ruleId: Long, enabled: Boolean) {
        viewModelScope.launch {
            val result = dvrRepository.updateSeriesRule(ruleId, enabled = enabled)
            result.fold(
                onSuccess = { updatedRule ->
                    _uiState.update { state ->
                        state.copy(
                            seriesRules = state.seriesRules.map {
                                if (it.id == ruleId) updatedRule else it
                            }
                        )
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to toggle series rule")
                }
            )
        }
    }

    fun deleteSeriesRule(ruleId: Long) {
        viewModelScope.launch {
            val result = dvrRepository.deleteSeriesRule(ruleId)
            result.fold(
                onSuccess = {
                    _uiState.update { state ->
                        state.copy(seriesRules = state.seriesRules.filter { it.id != ruleId })
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to delete series rule")
                }
            )
        }
    }

    // ============ Conflicts ============

    fun loadConflicts() {
        viewModelScope.launch {
            val result = dvrRepository.getConflicts()
            result.fold(
                onSuccess = { conflictsData ->
                    _uiState.update { it.copy(conflicts = conflictsData) }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load conflicts")
                }
            )
        }
    }

    fun resolveConflict(keepId: Long, cancelId: Long) {
        viewModelScope.launch {
            val result = dvrRepository.resolveConflict(keepId, cancelId)
            result.fold(
                onSuccess = {
                    // Reload conflicts and recordings
                    loadConflicts()
                    loadRecordings()
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to resolve conflict")
                }
            )
        }
    }

    // ============ Search & Filter ============

    fun updateSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
    }

    fun updateSortOrder(order: DVRSortOrder) {
        _uiState.update { it.copy(sortOrder = order) }
    }

    fun updateViewMode(mode: DVRViewMode) {
        _uiState.update { it.copy(viewMode = mode) }
    }

    // ============ Bulk Delete ============

    fun toggleSelectionMode() {
        _uiState.update {
            if (it.selectionMode) {
                it.copy(selectionMode = false, selectedIds = emptySet())
            } else {
                it.copy(selectionMode = true)
            }
        }
    }

    fun toggleSelection(recordingId: String) {
        _uiState.update { state ->
            val newSelection = if (recordingId in state.selectedIds) {
                state.selectedIds - recordingId
            } else {
                state.selectedIds + recordingId
            }
            state.copy(selectedIds = newSelection)
        }
    }

    fun deleteSelected() {
        val idsToDelete = _uiState.value.selectedIds.toList()
        viewModelScope.launch {
            for (id in idsToDelete) {
                dvrRepository.deleteRecording(id)
            }
            _uiState.update { state ->
                state.copy(
                    recordings = state.recordings.filter { it.id !in idsToDelete },
                    selectedIds = emptySet(),
                    selectionMode = false
                )
            }
        }
    }

    // ============ Disk Usage ============

    fun loadDiskUsage() {
        viewModelScope.launch {
            val result = dvrRepository.getDiskUsage()
            result.fold(
                onSuccess = { usage ->
                    _uiState.update { it.copy(diskUsage = usage) }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load disk usage")
                }
            )
        }
    }

    // ============ Stats Polling ============

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
    val seriesRules: List<SeriesRule> = emptyList(),
    val conflicts: ConflictsData? = null,
    val diskUsage: DiskUsage? = null,
    val searchQuery: String = "",
    val sortOrder: DVRSortOrder = DVRSortOrder.DATE_DESC,
    val viewMode: DVRViewMode = DVRViewMode.LIST,
    val selectionMode: Boolean = false,
    val selectedIds: Set<String> = emptySet(),
    val error: String? = null
) {
    // Filtered and sorted recordings
    val filteredRecordings: List<Recording>
        get() {
            var result = recordings
            // Apply search filter
            if (searchQuery.isNotBlank()) {
                val query = searchQuery.lowercase()
                result = result.filter {
                    it.title.lowercase().contains(query) ||
                    (it.description?.lowercase()?.contains(query) == true) ||
                    (it.channelName?.lowercase()?.contains(query) == true)
                }
            }
            // Apply sort
            result = when (sortOrder) {
                DVRSortOrder.DATE_DESC -> result.sortedByDescending { it.startTime }
                DVRSortOrder.DATE_ASC -> result.sortedBy { it.startTime }
                DVRSortOrder.TITLE_ASC -> result.sortedBy { it.title.lowercase() }
                DVRSortOrder.TITLE_DESC -> result.sortedByDescending { it.title.lowercase() }
                DVRSortOrder.SIZE_DESC -> result.sortedByDescending { it.fileSize ?: 0 }
            }
            return result
        }

    // Recordings grouped by series title
    val groupedRecordings: Map<String, List<Recording>>
        get() = filteredRecordings
            .filter { it.status == RecordingStatus.COMPLETED }
            .groupBy { it.title }
            .toSortedMap()
}
