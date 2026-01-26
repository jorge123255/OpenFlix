package com.openflix.presentation.screens.sources

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.SourceRepository
import com.openflix.domain.model.ImportResult
import com.openflix.domain.model.M3USource
import com.openflix.domain.model.XtreamSource
import com.openflix.domain.model.XtreamTestResult
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SourcesViewModel @Inject constructor(
    private val sourceRepository: SourceRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SourcesUiState())
    val uiState: StateFlow<SourcesUiState> = _uiState.asStateFlow()

    init {
        loadSources()
    }

    fun loadSources() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            // Load both M3U and Xtream sources in parallel
            val m3uResult = sourceRepository.getM3USources()
            val xtreamResult = sourceRepository.getXtreamSources()

            _uiState.update {
                it.copy(
                    isLoading = false,
                    m3uSources = m3uResult.getOrDefault(emptyList()),
                    xtreamSources = xtreamResult.getOrDefault(emptyList()),
                    error = m3uResult.exceptionOrNull()?.message
                        ?: xtreamResult.exceptionOrNull()?.message
                )
            }
        }
    }

    // === M3U Source Operations ===

    fun createM3USource(name: String, url: String, epgUrl: String?) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            sourceRepository.createM3USource(name, url, epgUrl)
                .onSuccess {
                    loadSources()
                    _uiState.update { it.copy(successMessage = "M3U source created successfully") }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, error = error.message) }
                }
        }
    }

    fun updateM3USource(
        id: Int,
        name: String? = null,
        url: String? = null,
        epgUrl: String? = null,
        enabled: Boolean? = null,
        importVod: Boolean? = null,
        importSeries: Boolean? = null,
        vodLibraryId: Int? = null,
        seriesLibraryId: Int? = null
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            sourceRepository.updateM3USource(
                id = id,
                name = name,
                url = url,
                epgUrl = epgUrl,
                enabled = enabled,
                importVod = importVod,
                importSeries = importSeries,
                vodLibraryId = vodLibraryId,
                seriesLibraryId = seriesLibraryId
            )
                .onSuccess {
                    loadSources()
                    _uiState.update { it.copy(successMessage = "M3U source updated successfully") }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, error = error.message) }
                }
        }
    }

    fun deleteM3USource(id: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            sourceRepository.deleteM3USource(id)
                .onSuccess {
                    loadSources()
                    _uiState.update { it.copy(successMessage = "M3U source deleted") }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, error = error.message) }
                }
        }
    }

    fun refreshM3USource(id: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true, error = null) }

            sourceRepository.refreshM3USource(id)
                .onSuccess {
                    loadSources()
                    _uiState.update { it.copy(isRefreshing = false, successMessage = "M3U source refreshed") }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isRefreshing = false, error = error.message) }
                }
        }
    }

    fun importM3UVOD(id: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isImporting = true, error = null) }

            sourceRepository.importM3UVOD(id)
                .onSuccess { result ->
                    loadSources()
                    _uiState.update {
                        it.copy(
                            isImporting = false,
                            importResult = result,
                            successMessage = "VOD import completed: ${result.added} added, ${result.updated} updated"
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isImporting = false, error = error.message) }
                }
        }
    }

    fun importM3USeries(id: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isImporting = true, error = null) }

            sourceRepository.importM3USeries(id)
                .onSuccess { message ->
                    loadSources()
                    _uiState.update {
                        it.copy(isImporting = false, successMessage = message)
                    }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isImporting = false, error = error.message) }
                }
        }
    }

    // === Xtream Source Operations ===

    fun createXtreamSource(
        name: String,
        serverUrl: String,
        username: String,
        password: String,
        importLive: Boolean = true,
        importVod: Boolean = false,
        importSeries: Boolean = false,
        vodLibraryId: Int? = null,
        seriesLibraryId: Int? = null
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            sourceRepository.createXtreamSource(
                name = name,
                serverUrl = serverUrl,
                username = username,
                password = password,
                importLive = importLive,
                importVod = importVod,
                importSeries = importSeries,
                vodLibraryId = vodLibraryId,
                seriesLibraryId = seriesLibraryId
            )
                .onSuccess {
                    loadSources()
                    _uiState.update { it.copy(successMessage = "Xtream source created successfully") }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, error = error.message) }
                }
        }
    }

    fun updateXtreamSource(
        id: Int,
        name: String? = null,
        serverUrl: String? = null,
        username: String? = null,
        password: String? = null,
        enabled: Boolean? = null,
        importLive: Boolean? = null,
        importVod: Boolean? = null,
        importSeries: Boolean? = null,
        vodLibraryId: Int? = null,
        seriesLibraryId: Int? = null
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            sourceRepository.updateXtreamSource(
                id = id,
                name = name,
                serverUrl = serverUrl,
                username = username,
                password = password,
                enabled = enabled,
                importLive = importLive,
                importVod = importVod,
                importSeries = importSeries,
                vodLibraryId = vodLibraryId,
                seriesLibraryId = seriesLibraryId
            )
                .onSuccess {
                    loadSources()
                    _uiState.update { it.copy(successMessage = "Xtream source updated successfully") }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, error = error.message) }
                }
        }
    }

    fun deleteXtreamSource(id: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            sourceRepository.deleteXtreamSource(id)
                .onSuccess {
                    loadSources()
                    _uiState.update { it.copy(successMessage = "Xtream source deleted") }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isLoading = false, error = error.message) }
                }
        }
    }

    fun testXtreamSource(id: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isTesting = true, error = null, testResult = null) }

            sourceRepository.testXtreamSource(id)
                .onSuccess { result ->
                    _uiState.update {
                        it.copy(
                            isTesting = false,
                            testResult = result,
                            successMessage = if (result.success) "Connection successful" else result.message
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isTesting = false, error = error.message) }
                }
        }
    }

    fun refreshXtreamSource(id: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true, error = null) }

            sourceRepository.refreshXtreamSource(id)
                .onSuccess {
                    loadSources()
                    _uiState.update { it.copy(isRefreshing = false, successMessage = "Xtream source refreshed") }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isRefreshing = false, error = error.message) }
                }
        }
    }

    fun importXtreamVOD(id: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isImporting = true, error = null) }

            sourceRepository.importXtreamVOD(id)
                .onSuccess { result ->
                    loadSources()
                    _uiState.update {
                        it.copy(
                            isImporting = false,
                            importResult = result,
                            successMessage = "VOD import completed: ${result.added} added, ${result.updated} updated"
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isImporting = false, error = error.message) }
                }
        }
    }

    fun importXtreamSeries(id: Int) {
        viewModelScope.launch {
            _uiState.update { it.copy(isImporting = true, error = null) }

            sourceRepository.importXtreamSeries(id)
                .onSuccess { result ->
                    loadSources()
                    _uiState.update {
                        it.copy(
                            isImporting = false,
                            importResult = result,
                            successMessage = "Series import completed: ${result.added} added, ${result.updated} updated"
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update { it.copy(isImporting = false, error = error.message) }
                }
        }
    }

    // === UI State Management ===

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun clearSuccessMessage() {
        _uiState.update { it.copy(successMessage = null) }
    }

    fun clearTestResult() {
        _uiState.update { it.copy(testResult = null) }
    }

    fun clearImportResult() {
        _uiState.update { it.copy(importResult = null) }
    }
}

data class SourcesUiState(
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val isTesting: Boolean = false,
    val isImporting: Boolean = false,
    val m3uSources: List<M3USource> = emptyList(),
    val xtreamSources: List<XtreamSource> = emptyList(),
    val testResult: XtreamTestResult? = null,
    val importResult: ImportResult? = null,
    val error: String? = null,
    val successMessage: String? = null
)
