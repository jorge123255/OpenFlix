package com.openflix.presentation.screens.livetv

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelGroup
import com.openflix.domain.model.DuplicateGroup
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class ChannelGroupsViewModel @Inject constructor(
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ChannelGroupsUiState())
    val uiState: StateFlow<ChannelGroupsUiState> = _uiState.asStateFlow()

    init {
        loadChannelGroups()
        loadChannels()
    }

    fun loadChannelGroups() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = liveTVRepository.getChannelGroups()

            result.fold(
                onSuccess = { groups ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            groups = groups
                        )
                    }
                    Timber.d("Loaded ${groups.size} channel groups")
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load channel groups")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error.message ?: "Failed to load channel groups"
                        )
                    }
                }
            )
        }
    }

    private fun loadChannels() {
        viewModelScope.launch {
            val result = liveTVRepository.getChannels()
            result.fold(
                onSuccess = { channels ->
                    _uiState.update {
                        it.copy(availableChannels = channels.filterNot { c -> c.hidden })
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to load channels for group management")
                }
            )
        }
    }

    fun createGroup(name: String, displayNumber: Int, logo: String? = null, channelId: String? = null) {
        viewModelScope.launch {
            _uiState.update { it.copy(isCreating = true) }

            val result = liveTVRepository.createChannelGroup(
                name = name,
                displayNumber = displayNumber,
                logo = logo,
                channelId = channelId
            )

            result.fold(
                onSuccess = { group ->
                    Timber.d("Created channel group: ${group.name}")
                    _uiState.update { it.copy(isCreating = false) }
                    loadChannelGroups()
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to create channel group")
                    _uiState.update {
                        it.copy(
                            isCreating = false,
                            error = error.message ?: "Failed to create group"
                        )
                    }
                }
            )
        }
    }

    fun updateGroup(
        groupId: Int,
        name: String? = null,
        displayNumber: Int? = null,
        logo: String? = null,
        channelId: String? = null,
        enabled: Boolean? = null
    ) {
        viewModelScope.launch {
            val result = liveTVRepository.updateChannelGroup(
                groupId = groupId,
                name = name,
                displayNumber = displayNumber,
                logo = logo,
                channelId = channelId,
                enabled = enabled
            )

            result.fold(
                onSuccess = { group ->
                    Timber.d("Updated channel group: ${group.name}")
                    loadChannelGroups()
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to update channel group")
                    _uiState.update {
                        it.copy(error = error.message ?: "Failed to update group")
                    }
                }
            )
        }
    }

    fun deleteGroup(groupId: Int) {
        viewModelScope.launch {
            val result = liveTVRepository.deleteChannelGroup(groupId)

            result.fold(
                onSuccess = {
                    Timber.d("Deleted channel group: $groupId")
                    loadChannelGroups()
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to delete channel group")
                    _uiState.update {
                        it.copy(error = error.message ?: "Failed to delete group")
                    }
                }
            )
        }
    }

    fun addChannelToGroup(groupId: Int, channelId: Int, priority: Int = 0) {
        viewModelScope.launch {
            val result = liveTVRepository.addChannelToGroup(groupId, channelId, priority)

            result.fold(
                onSuccess = { member ->
                    Timber.d("Added channel $channelId to group $groupId with priority $priority")
                    loadChannelGroups()
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to add channel to group")
                    _uiState.update {
                        it.copy(error = error.message ?: "Failed to add channel")
                    }
                }
            )
        }
    }

    fun updateMemberPriority(groupId: Int, channelId: Int, priority: Int) {
        viewModelScope.launch {
            val result = liveTVRepository.updateGroupMemberPriority(groupId, channelId, priority)

            result.fold(
                onSuccess = { member ->
                    Timber.d("Updated priority for channel $channelId in group $groupId to $priority")
                    loadChannelGroups()
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to update member priority")
                    _uiState.update {
                        it.copy(error = error.message ?: "Failed to update priority")
                    }
                }
            )
        }
    }

    fun removeChannelFromGroup(groupId: Int, channelId: Int) {
        viewModelScope.launch {
            val result = liveTVRepository.removeChannelFromGroup(groupId, channelId)

            result.fold(
                onSuccess = {
                    Timber.d("Removed channel $channelId from group $groupId")
                    loadChannelGroups()
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to remove channel from group")
                    _uiState.update {
                        it.copy(error = error.message ?: "Failed to remove channel")
                    }
                }
            )
        }
    }

    fun autoDetectDuplicates() {
        viewModelScope.launch {
            _uiState.update { it.copy(isDetecting = true) }

            val result = liveTVRepository.autoDetectDuplicates()

            result.fold(
                onSuccess = { duplicates ->
                    Timber.d("Detected ${duplicates.size} duplicate groups")
                    _uiState.update {
                        it.copy(
                            isDetecting = false,
                            detectedDuplicates = duplicates,
                            showDuplicatesDialog = duplicates.isNotEmpty()
                        )
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to auto-detect duplicates")
                    _uiState.update {
                        it.copy(
                            isDetecting = false,
                            error = error.message ?: "Failed to detect duplicates"
                        )
                    }
                }
            )
        }
    }

    fun createGroupFromDuplicate(duplicate: DuplicateGroup) {
        viewModelScope.launch {
            // Create the group first
            val createResult = liveTVRepository.createChannelGroup(
                name = duplicate.name,
                displayNumber = 0  // Will be assigned by server or can be set later
            )

            createResult.fold(
                onSuccess = { group ->
                    Timber.d("Created group from duplicate: ${group.name}")

                    // Add all channels to the group with priorities
                    duplicate.channels.forEachIndexed { index, channel ->
                        val channelIdInt = channel.id.toIntOrNull()
                        if (channelIdInt != null) {
                            liveTVRepository.addChannelToGroup(group.id, channelIdInt, index)
                        }
                    }

                    // Refresh the list
                    loadChannelGroups()

                    // Remove this duplicate from the detected list
                    _uiState.update { state ->
                        val remaining = state.detectedDuplicates.filter { it.name != duplicate.name }
                        state.copy(
                            detectedDuplicates = remaining,
                            showDuplicatesDialog = remaining.isNotEmpty()
                        )
                    }
                },
                onFailure = { error ->
                    Timber.e(error, "Failed to create group from duplicate")
                    _uiState.update {
                        it.copy(error = error.message ?: "Failed to create group")
                    }
                }
            )
        }
    }

    fun dismissDuplicatesDialog() {
        _uiState.update { it.copy(showDuplicatesDialog = false, detectedDuplicates = emptyList()) }
    }

    fun selectGroup(group: ChannelGroup?) {
        _uiState.update { it.copy(selectedGroup = group) }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun moveMemberUp(groupId: Int, channelId: Int, currentPriority: Int) {
        if (currentPriority > 0) {
            updateMemberPriority(groupId, channelId, currentPriority - 1)
        }
    }

    fun moveMemberDown(groupId: Int, channelId: Int, currentPriority: Int) {
        updateMemberPriority(groupId, channelId, currentPriority + 1)
    }
}

data class ChannelGroupsUiState(
    val isLoading: Boolean = false,
    val isCreating: Boolean = false,
    val isDetecting: Boolean = false,
    val groups: List<ChannelGroup> = emptyList(),
    val availableChannels: List<Channel> = emptyList(),
    val selectedGroup: ChannelGroup? = null,
    val detectedDuplicates: List<DuplicateGroup> = emptyList(),
    val showDuplicatesDialog: Boolean = false,
    val error: String? = null
)
