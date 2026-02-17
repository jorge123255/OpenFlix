package com.openflix.presentation.screens.teampass

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.OnLaterItem
import com.openflix.domain.model.SportsTeam
import com.openflix.domain.model.TeamPass
import com.openflix.domain.model.TeamPassStats
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class TeamPassViewModel @Inject constructor(
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TeamPassUiState())
    val uiState: StateFlow<TeamPassUiState> = _uiState.asStateFlow()

    private val _selectedLeague = MutableStateFlow("NFL")
    val selectedLeague: StateFlow<String> = _selectedLeague.asStateFlow()

    private val _selectedTeamPass = MutableStateFlow<TeamPass?>(null)
    val selectedTeamPass: StateFlow<TeamPass?> = _selectedTeamPass.asStateFlow()

    init {
        loadTeamPasses()
        loadStats()
    }

    fun loadTeamPasses() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = liveTVRepository.getTeamPasses()

            result.fold(
                onSuccess = { passes ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            teamPasses = passes
                        )
                    }
                    Timber.d("Loaded ${passes.size} team passes")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load team passes")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load team passes"
                        )
                    }
                }
            )
        }
    }

    private fun loadStats() {
        viewModelScope.launch {
            val result = liveTVRepository.getTeamPassStats()
            result.fold(
                onSuccess = { stats ->
                    _uiState.update { it.copy(stats = stats) }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load team pass stats")
                }
            )
        }
    }

    fun selectLeague(league: String) {
        _selectedLeague.value = league
        loadTeamsForLeague(league)
    }

    fun loadTeamsForLeague(league: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingTeams = true) }

            val result = liveTVRepository.getLeagueTeams(league)

            result.fold(
                onSuccess = { teams ->
                    _uiState.update {
                        it.copy(
                            isLoadingTeams = false,
                            teams = teams
                        )
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load teams for $league")
                    _uiState.update { it.copy(isLoadingTeams = false) }
                }
            )
        }
    }

    fun searchTeams(query: String) {
        if (query.length < 2) {
            _uiState.update { it.copy(searchResults = emptyList()) }
            return
        }

        viewModelScope.launch {
            val result = liveTVRepository.searchSportsTeams(query)
            result.fold(
                onSuccess = { teams ->
                    _uiState.update { it.copy(searchResults = teams) }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to search teams: $query")
                }
            )
        }
    }

    fun createTeamPass(
        teamName: String,
        league: String,
        prePadding: Int = 5,
        postPadding: Int = 60,
        keepCount: Int = 0
    ) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }

            val result = liveTVRepository.createTeamPass(
                teamName = teamName,
                league = league,
                prePadding = prePadding,
                postPadding = postPadding,
                keepCount = keepCount
            )

            result.fold(
                onSuccess = { pass ->
                    _uiState.update {
                        it.copy(
                            isSaving = false,
                            teamPasses = it.teamPasses + pass,
                            showAddDialog = false
                        )
                    }
                    loadStats()
                    Timber.d("Created team pass for ${pass.teamName}")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to create team pass")
                    _uiState.update {
                        it.copy(
                            isSaving = false,
                            error = error.message
                        )
                    }
                }
            )
        }
    }

    fun deleteTeamPass(id: Long) {
        viewModelScope.launch {
            val result = liveTVRepository.deleteTeamPass(id)

            result.fold(
                onSuccess = {
                    _uiState.update {
                        it.copy(teamPasses = it.teamPasses.filter { pass -> pass.id != id })
                    }
                    loadStats()
                    Timber.d("Deleted team pass: $id")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to delete team pass: $id")
                }
            )
        }
    }

    fun toggleTeamPass(id: Long) {
        viewModelScope.launch {
            val result = liveTVRepository.toggleTeamPass(id)

            result.fold(
                onSuccess = { updatedPass ->
                    _uiState.update {
                        it.copy(
                            teamPasses = it.teamPasses.map { pass ->
                                if (pass.id == id) updatedPass else pass
                            }
                        )
                    }
                    loadStats()
                    Timber.d("Toggled team pass: $id")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to toggle team pass: $id")
                }
            )
        }
    }

    fun selectTeamPassForDetails(pass: TeamPass) {
        _selectedTeamPass.value = pass
        loadUpcomingGames(pass.id)
    }

    fun clearSelectedTeamPass() {
        _selectedTeamPass.value = null
        _uiState.update { it.copy(upcomingGames = emptyList()) }
    }

    private fun loadUpcomingGames(teamPassId: Long) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingGames = true) }

            val result = liveTVRepository.getTeamPassUpcoming(teamPassId)

            result.fold(
                onSuccess = { games ->
                    _uiState.update {
                        it.copy(
                            isLoadingGames = false,
                            upcomingGames = games
                        )
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load upcoming games")
                    _uiState.update { it.copy(isLoadingGames = false) }
                }
            )
        }
    }

    fun showAddDialog() {
        _uiState.update { it.copy(showAddDialog = true) }
        loadTeamsForLeague(_selectedLeague.value)
    }

    fun hideAddDialog() {
        _uiState.update { it.copy(showAddDialog = false, searchResults = emptyList()) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class TeamPassUiState(
    val isLoading: Boolean = false,
    val isLoadingTeams: Boolean = false,
    val isLoadingGames: Boolean = false,
    val isSaving: Boolean = false,
    val teamPasses: List<TeamPass> = emptyList(),
    val teams: List<SportsTeam> = emptyList(),
    val searchResults: List<SportsTeam> = emptyList(),
    val upcomingGames: List<OnLaterItem> = emptyList(),
    val stats: TeamPassStats? = null,
    val showAddDialog: Boolean = false,
    val error: String? = null
)
