package com.openflix.presentation.screens.livetv

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.remote.dto.UpdateChannelRequest
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
                editName = channel.name,
                editNumber = channel.number ?: "",
                editLogoUrl = channel.logo ?: "",
                editGroup = channel.group ?: "",
                showEditor = true
            )
        }
    }

    fun dismissEditor() {
        _uiState.update {
            it.copy(
                selectedChannel = null,
                editName = "",
                editNumber = "",
                editLogoUrl = "",
                editGroup = "",
                showEditor = false
            )
        }
    }

    // Legacy method for backward compatibility
    fun dismissLogoEditor() = dismissEditor()

    fun setEditName(name: String) {
        _uiState.update { it.copy(editName = name) }
    }

    fun setEditNumber(number: String) {
        _uiState.update { it.copy(editNumber = number) }
    }

    fun setEditLogoUrl(url: String) {
        _uiState.update { it.copy(editLogoUrl = url) }
    }

    fun setEditGroup(group: String) {
        _uiState.update { it.copy(editGroup = group) }
    }

    // Legacy method for backward compatibility
    fun setCustomLogoUrl(url: String) = setEditLogoUrl(url)

    fun saveChannel() {
        val channel = _uiState.value.selectedChannel ?: return
        val state = _uiState.value

        viewModelScope.launch {
            _uiState.update { it.copy(isSaving = true) }

            // Build the update request with changed fields
            val numberInt = state.editNumber.toIntOrNull()
            val request = UpdateChannelRequest(
                name = if (state.editName != channel.name && state.editName.isNotBlank()) state.editName else null,
                number = if (state.editNumber != (channel.number ?: "") && numberInt != null) numberInt else null,
                logo = if (state.editLogoUrl != (channel.logo ?: "")) state.editLogoUrl else null,
                group = if (state.editGroup != (channel.group ?: "")) state.editGroup else null
            )

            liveTVRepository.updateChannel(channel.id, request)
                .onSuccess { updatedChannel ->
                    Timber.d("Channel updated: ${updatedChannel.name}")
                    // Update the channel in the list
                    _uiState.update { currentState ->
                        val updatedChannels = currentState.channels.map {
                            if (it.id == updatedChannel.id) updatedChannel else it
                        }
                        currentState.copy(
                            channels = updatedChannels,
                            filteredChannels = if (currentState.searchQuery.isBlank()) {
                                updatedChannels
                            } else {
                                updatedChannels.filter { ch ->
                                    ch.name.contains(currentState.searchQuery, ignoreCase = true)
                                }
                            },
                            isSaving = false,
                            showEditor = false,
                            selectedChannel = null,
                            editName = "",
                            editNumber = "",
                            editLogoUrl = "",
                            editGroup = ""
                        )
                    }
                }
                .onFailure { error ->
                    Timber.e(error, "Failed to update channel")
                    _uiState.update {
                        it.copy(
                            isSaving = false,
                            error = error.message
                        )
                    }
                }
        }
    }

    // Legacy method for backward compatibility
    fun saveChannelLogo() = saveChannel()

    fun resetFields() {
        val channel = _uiState.value.selectedChannel ?: return
        _uiState.update {
            it.copy(
                editName = channel.name,
                editNumber = channel.number ?: "",
                editLogoUrl = channel.logo ?: "",
                editGroup = channel.group ?: ""
            )
        }
    }

    // Legacy method for backward compatibility
    fun resetChannelLogo() {
        _uiState.update { it.copy(editLogoUrl = "") }
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
    // Edit fields
    val editName: String = "",
    val editNumber: String = "",
    val editLogoUrl: String = "",
    val editGroup: String = "",
    val showEditor: Boolean = false,
    val isLoading: Boolean = false,
    val isSaving: Boolean = false,
    val error: String? = null,
    // Legacy aliases for backward compatibility
    val customLogoUrl: String = "",
    val showLogoEditor: Boolean = false
) {
    // Sync legacy fields with new fields
    fun withSyncedLegacyFields() = copy(
        customLogoUrl = editLogoUrl,
        showLogoEditor = showEditor
    )
}
