package com.openflix.presentation.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.MediaRepository
import com.openflix.domain.model.Hub
import com.openflix.domain.model.MediaItem
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class DiscoverViewModel @Inject constructor(
    private val mediaRepository: MediaRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(DiscoverUiState())
    val uiState: StateFlow<DiscoverUiState> = _uiState.asStateFlow()

    fun loadHomeContent() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = mediaRepository.getHomeHubs()

            result.fold(
                onSuccess = { hubs ->
                    // Find a featured item from the first hub or promoted hub
                    val featuredItem = hubs
                        .firstOrNull { it.promoted || it.style == "hero" }
                        ?.items?.firstOrNull()
                        ?: hubs.firstOrNull()?.items?.firstOrNull()

                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            hubs = hubs,
                            featuredItem = featuredItem
                        )
                    }
                    Timber.d("Loaded ${hubs.size} hubs")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load home content")
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

    fun refresh() {
        loadHomeContent()
    }
}

data class DiscoverUiState(
    val isLoading: Boolean = false,
    val hubs: List<Hub> = emptyList(),
    val featuredItem: MediaItem? = null,
    val error: String? = null
)
