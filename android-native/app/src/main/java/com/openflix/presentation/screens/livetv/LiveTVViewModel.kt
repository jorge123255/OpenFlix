package com.openflix.presentation.screens.livetv

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class LiveTVViewModel @Inject constructor(
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(LiveTVUiState())
    val uiState: StateFlow<LiveTVUiState> = _uiState.asStateFlow()

    fun loadChannels() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = liveTVRepository.getChannels()

            result.fold(
                onSuccess = { channels ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            channels = channels.filterNot { c -> c.hidden }
                        )
                    }
                    Timber.d("Loaded ${channels.size} channels")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load channels")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load channels"
                        )
                    }
                }
            )
        }
    }

    fun filterByFavorites() {
        _uiState.update { state ->
            state.copy(
                channels = state.channels.filter { it.favorite }
            )
        }
    }

    fun filterByGroup(group: String) {
        _uiState.update { state ->
            state.copy(
                channels = state.channels.filter { it.group == group }
            )
        }
    }
}

data class LiveTVUiState(
    val isLoading: Boolean = false,
    val channels: List<Channel> = emptyList(),
    val error: String? = null,
    val selectedGroup: String? = null
)
