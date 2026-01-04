package com.openflix.presentation.screens.livetv

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class ChannelLogoEditorViewModel @Inject constructor(
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ChannelLogoEditorUiState())
    val uiState: StateFlow<ChannelLogoEditorUiState> = _uiState.asStateFlow()

    init {
        loadChannels()
    }

    private fun loadChannels() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            liveTVRepository.getChannels()
                .onSuccess { channels ->
                    _uiState.update {
                        it.copy(
                            channels = channels,
                            filteredChannels = channels,
                            isLoading = false
                        )
                    }
                }
                .onFailure { error ->
                    Timber.e(error, "Failed to load channels")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message
                        )
                    }
                }
        }
    }

    fun searchChannels(query: String) {
        _uiState.update { state ->
            val filtered = if (query.isBlank()) {
                state.channels
            } else {
                state.channels.filter { channel ->
                    channel.name.contains(query, ignoreCase = true) ||
                    channel.number?.contains(query, ignoreCase = true) == true ||
                    channel.callsign?.contains(query, ignoreCase = true) == true
                }
            }
            state.copy(searchQuery = query, filteredChannels = filtered)
        }
    }

    fun selectChannel(channel: Channel) {
        _uiState.update {
            it.copy(
                selectedChannel = channel,
                customLogoUrl = channel.logo ?: "",
                showLogoEditor = true
            )
        }
    }

    fun dismissLogoEditor() {
        _uiState.update {
            it.copy(
                selectedChannel = null,
                customLogoUrl = "",
                showLogoEditor = false
            )
        }
    }

    fun setCustomLogoUrl(url: String) {
        _uiState.update { it.copy(customLogoUrl = url) }
    }

    fun saveChannelLogo() {
        val channel = _uiState.value.selectedChannel ?: return
        val logoUrl = _uiState.value.customLogoUrl

        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }

            liveTVRepository.updateChannelLogo(channel.id, logoUrl)
                .onSuccess { updatedChannel ->
                    Timber.d("Channel logo updated: ${updatedChannel.name}")
                    // Update the channel in the list
                    _uiState.update { state ->
                        val updatedChannels = state.channels.map {
                            if (it.id == updatedChannel.id) updatedChannel else it
                        }
                        state.copy(
                            channels = updatedChannels,
                            filteredChannels = if (state.searchQuery.isBlank()) {
                                updatedChannels
                            } else {
                                updatedChannels.filter { ch ->
                                    ch.name.contains(state.searchQuery, ignoreCase = true)
                                }
                            },
                            isSaving = false,
                            showLogoEditor = false,
                            selectedChannel = null,
                            customLogoUrl = ""
                        )
                    }
                }
                .onFailure { error ->
                    Timber.e(error, "Failed to update channel logo")
                    _uiState.update {
                        it.copy(
                            isSaving = false,
                            error = error.message
                        )
                    }
                }
        }
    }

    fun resetChannelLogo() {
        // Reset to empty logo (will use default)
        _uiState.update { it.copy(customLogoUrl = "") }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class ChannelLogoEditorUiState(
    val channels: List<Channel> = emptyList(),
    val filteredChannels: List<Channel> = emptyList(),
    val searchQuery: String = "",
    val selectedChannel: Channel? = null,
    val customLogoUrl: String = "",
    val showLogoEditor: Boolean = false,
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val error: String? = null
)
