package com.openflix.presentation.screens.livetv

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.domain.model.Channel
import com.openflix.data.repository.LiveTVRepository
import com.openflix.player.MultiviewPlayer
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for YouTube TV-style Multiview.
 *
 * Key behaviors:
 * - Audio follows focus: D-pad to a view = audio switches automatically
 * - Fullscreen toggle: OK press expands focused view, Back returns to grid
 * - Fixed 2x2 grid layout (no layout cycling)
 * - Channel picker on long-press only
 */
@HiltViewModel
class MultiviewViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val liveTVRepository: LiveTVRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(MultiviewUiState())
    val uiState: StateFlow<MultiviewUiState> = _uiState.asStateFlow()

    // Player instances for each slot
    private val players = mutableMapOf<Int, MultiviewPlayer>()

    init {
        loadChannels()
    }

    private fun loadChannels() {
        viewModelScope.launch {
            liveTVRepository.getChannels()
                .onSuccess { channels ->
                    _uiState.update { it.copy(allChannels = channels) }
                }
                .onFailure { e ->
                    Timber.e(e, "Failed to load channels for multiview")
                }
        }
    }

    fun initializeSlots(initialChannelIds: List<String>) {
        val channels = _uiState.value.allChannels
        if (channels.isEmpty()) {
            Timber.w("No channels available for multiview")
            return
        }

        val initialChannels = initialChannelIds.mapNotNull { id ->
            channels.find { it.id == id }
        }.take(4)

        // Default to 4 channels for YTTV-style 2x2 grid
        val channelsToUse = if (initialChannels.size >= 2) {
            initialChannels
        } else {
            channels.take(4)
        }

        val slots = channelsToUse.mapIndexed { index, channel ->
            val player = MultiviewPlayer(context).also { it.initialize() }
            players[index] = player
            channel.streamUrl?.let { url -> player.play(url) }

            MultiviewSlot(
                index = index,
                channel = channel,
                isReady = false
            )
        }

        // Set audio to first slot (audio follows focus, focus starts at 0)
        players[0]?.unmute()

        _uiState.update {
            it.copy(
                slots = slots,
                focusedSlotIndex = 0,
                audioSlotIndex = 0
            )
        }

        Timber.d("Multiview initialized with ${slots.size} slots (YTTV-style)")
    }

    fun getPlayer(slotIndex: Int): MultiviewPlayer? = players[slotIndex]

    /**
     * YTTV behavior: focus change = audio follows.
     * When D-pad moves to a slot, audio switches to it automatically.
     */
    fun setFocusedSlot(index: Int) {
        if (index == _uiState.value.focusedSlotIndex) return
        if (index >= _uiState.value.slots.size) return

        // Audio follows focus
        switchAudioToSlot(index)

        _uiState.update {
            it.copy(
                focusedSlotIndex = index,
                showOverlay = true
            )
        }
    }

    private fun switchAudioToSlot(slotIndex: Int) {
        players.forEach { (index, player) ->
            if (index == slotIndex) player.unmute() else player.mute()
        }
        _uiState.update { it.copy(audioSlotIndex = slotIndex) }
        Timber.d("Audio switched to slot $slotIndex")
    }

    /**
     * YTTV behavior: OK press = enter fullscreen for focused slot.
     */
    fun enterFullscreen() {
        val focused = _uiState.value.focusedSlotIndex
        _uiState.update {
            it.copy(
                isFullscreen = true,
                fullscreenSlotIndex = focused
            )
        }
        Timber.d("Entered fullscreen on slot $focused")
    }

    /**
     * YTTV behavior: Back from fullscreen = return to 2x2 grid.
     */
    fun exitFullscreen() {
        _uiState.update {
            it.copy(
                isFullscreen = false,
                fullscreenSlotIndex = null
            )
        }
        Timber.d("Exited fullscreen, back to grid")
    }

    fun changeChannelInSlot(slotIndex: Int, direction: Int) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return
        val allChannels = state.allChannels
        if (allChannels.isEmpty()) return

        val currentIndex = allChannels.indexOfFirst { it.id == slot.channel.id }
        var newIndex = currentIndex + direction
        if (newIndex < 0) newIndex = allChannels.size - 1
        if (newIndex >= allChannels.size) newIndex = 0

        val newChannel = allChannels[newIndex]

        players[slotIndex]?.apply {
            newChannel.streamUrl?.let { url -> play(url) }
        }

        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(channel = newChannel, isReady = false)

        _uiState.update { it.copy(slots = updatedSlots, showOverlay = true) }
        Timber.d("Changed slot $slotIndex to channel: ${newChannel.name}")
    }

    fun swapChannel(slotIndex: Int, newChannel: Channel) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        players[slotIndex]?.apply {
            newChannel.streamUrl?.let { url -> play(url) }
        }

        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(channel = newChannel, isReady = false)

        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Swapped slot $slotIndex to channel: ${newChannel.name}")
    }

    fun showOverlay() {
        _uiState.update { it.copy(showOverlay = true) }
    }

    fun hideOverlay() {
        _uiState.update { it.copy(showOverlay = false) }
    }

    fun showControls() {
        _uiState.update { it.copy(showControls = true) }
    }

    fun hideControls() {
        _uiState.update { it.copy(showControls = false) }
    }

    fun showChannelPicker(slotIndex: Int) {
        _uiState.update { it.copy(channelPickerSlotIndex = slotIndex) }
    }

    fun hideChannelPicker() {
        _uiState.update { it.copy(channelPickerSlotIndex = null) }
    }

    fun startOverSlot(slotIndex: Int) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        viewModelScope.launch {
            liveTVRepository.getStartOverInfo(slot.channel.id)
                .onSuccess { startOverInfo ->
                    if (startOverInfo.available && !startOverInfo.streamUrl.isNullOrBlank()) {
                        players[slotIndex]?.apply {
                            play(startOverInfo.streamUrl)
                        }

                        val updatedSlots = state.slots.toMutableList()
                        updatedSlots[slotIndex] = slot.copy(
                            isTimeshifted = true,
                            timeshiftProgramTitle = startOverInfo.programTitle
                        )
                        _uiState.update { it.copy(slots = updatedSlots) }
                        Timber.d("Started over program '${startOverInfo.programTitle}' in slot $slotIndex")
                    }
                }
                .onFailure { e ->
                    Timber.e(e, "Failed to get start over info for slot $slotIndex")
                }
        }
    }

    fun goLiveSlot(slotIndex: Int) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        players[slotIndex]?.apply {
            slot.channel.streamUrl?.let { url -> play(url) }
        }

        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(
            isTimeshifted = false,
            timeshiftProgramTitle = null
        )
        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Went live in slot $slotIndex")
    }

    override fun onCleared() {
        super.onCleared()
        players.values.forEach { it.release() }
        players.clear()
        Timber.d("MultiviewViewModel cleared, all players released")
    }
}

data class MultiviewUiState(
    val slots: List<MultiviewSlot> = emptyList(),
    val allChannels: List<Channel> = emptyList(),
    val focusedSlotIndex: Int = 0,
    val audioSlotIndex: Int = 0,
    val isFullscreen: Boolean = false,
    val fullscreenSlotIndex: Int? = null,
    val showOverlay: Boolean = true,
    val showControls: Boolean = true,
    val channelPickerSlotIndex: Int? = null
)

data class MultiviewSlot(
    val index: Int,
    val channel: Channel,
    val isReady: Boolean = false,
    val isMuted: Boolean = true,
    val isTimeshifted: Boolean = false,
    val timeshiftProgramTitle: String? = null
)

enum class MultiviewLayout {
    SINGLE,
    TWO_BY_ONE,
    ONE_BY_TWO,
    THREE_GRID,
    TWO_BY_TWO
}
