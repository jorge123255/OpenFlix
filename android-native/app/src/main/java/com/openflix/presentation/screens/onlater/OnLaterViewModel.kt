package com.openflix.presentation.screens.onlater

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.DVRRepository
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.OnLaterCategory
import com.openflix.domain.model.OnLaterItem
import com.openflix.domain.model.OnLaterStats
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class OnLaterViewModel @Inject constructor(
    private val liveTVRepository: LiveTVRepository,
    private val dvrRepository: DVRRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(OnLaterUiState())
    val uiState: StateFlow<OnLaterUiState> = _uiState.asStateFlow()

    private val _selectedCategory = MutableStateFlow(OnLaterCategory.TONIGHT)
    val selectedCategory: StateFlow<OnLaterCategory> = _selectedCategory.asStateFlow()

    private val _selectedLeague = MutableStateFlow<String?>(null)
    val selectedLeague: StateFlow<String?> = _selectedLeague.asStateFlow()

    private val _recordingProgramId = MutableStateFlow<Long?>(null)
    val recordingProgramId: StateFlow<Long?> = _recordingProgramId.asStateFlow()

    init {
        loadStats()
        loadLeagues()
    }

    private fun loadStats() {
        viewModelScope.launch {
            val result = liveTVRepository.getOnLaterStats()
            result.fold(
                onSuccess = { stats ->
                    _uiState.update { it.copy(stats = stats) }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load On Later stats")
                }
            )
        }
    }

    private fun loadLeagues() {
        viewModelScope.launch {
            val result = liveTVRepository.getOnLaterLeagues()
            result.fold(
                onSuccess = { leagues ->
                    _uiState.update { it.copy(leagues = leagues) }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load leagues")
                }
            )
        }
    }

    fun selectCategory(category: OnLaterCategory) {
        _selectedCategory.value = category
        _selectedLeague.value = null
        loadCategory(category)
    }

    fun selectLeague(league: String?) {
        _selectedLeague.value = league
        loadCategory(OnLaterCategory.SPORTS, league)
    }

    fun loadCategory(category: OnLaterCategory, league: String? = null) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = when (category) {
                OnLaterCategory.TONIGHT -> liveTVRepository.getOnLaterTonight()
                OnLaterCategory.MOVIES -> liveTVRepository.getOnLaterMovies()
                OnLaterCategory.SPORTS -> liveTVRepository.getOnLaterSports(league = league)
                OnLaterCategory.KIDS -> liveTVRepository.getOnLaterKids()
                OnLaterCategory.NEWS -> liveTVRepository.getOnLaterNews()
                OnLaterCategory.PREMIERES -> liveTVRepository.getOnLaterPremieres()
                OnLaterCategory.WEEK -> liveTVRepository.getOnLaterWeek()
            }

            result.fold(
                onSuccess = { items ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            items = items
                        )
                    }
                    Timber.d("Loaded ${items.size} ${category.name} items")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load ${category.name}")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load content"
                        )
                    }
                }
            )
        }
    }

    fun search(query: String) {
        if (query.length < 3) {
            _uiState.update { it.copy(searchResults = emptyList()) }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isSearching = true) }

            val result = liveTVRepository.searchOnLater(query)

            result.fold(
                onSuccess = { items ->
                    _uiState.update {
                        it.copy(
                            isSearching = false,
                            searchResults = items
                        )
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to search On Later: $query")
                    _uiState.update {
                        it.copy(isSearching = false)
                    }
                }
            )
        }
    }

    fun clearSearch() {
        _uiState.update { it.copy(searchResults = emptyList()) }
    }

    fun recordProgram(item: OnLaterItem, seriesRecord: Boolean = false) {
        val program = item.program
        val channel = item.channel ?: return

        // Don't re-record if already has a recording
        if (item.hasRecording) return

        viewModelScope.launch {
            _recordingProgramId.value = program.id

            val result = dvrRepository.scheduleRecording(
                channelId = channel.id.toString(),
                programId = program.id.toString(),
                startTime = program.start,
                endTime = program.start + (program.durationMinutes * 60),
                type = if (seriesRecord) "series" else "single"
            )

            result.fold(
                onSuccess = { recording ->
                    Timber.d("Recording scheduled: ${recording.title} (series: $seriesRecord)")
                    // Update the item in the list to show it has a recording
                    _uiState.update { state ->
                        state.copy(
                            items = state.items.map { existingItem ->
                                if (existingItem.program.id == program.id) {
                                    existingItem.copy(hasRecording = true, recordingId = recording.id.toLongOrNull())
                                } else {
                                    existingItem
                                }
                            }
                        )
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to schedule recording for ${program.title}")
                    _uiState.update {
                        it.copy(error = "Failed to schedule recording: ${error.message}")
                    }
                }
            )

            _recordingProgramId.value = null
        }
    }
}

data class OnLaterUiState(
    val isLoading: Boolean = false,
    val isSearching: Boolean = false,
    val items: List<OnLaterItem> = emptyList(),
    val searchResults: List<OnLaterItem> = emptyList(),
    val stats: OnLaterStats? = null,
    val leagues: List<String> = emptyList(),
    val error: String? = null
)
