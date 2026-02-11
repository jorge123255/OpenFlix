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
 * ViewModel for the Multiview screen.
 * Manages multiple player slots for watching 2-4 channels simultaneously.
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

        // If no initial channels provided, use first few channels
        val channelsToUse = initialChannels.ifEmpty {
            channels.take(2)
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

        val layout = when (slots.size) {
            1 -> MultiviewLayout.SINGLE
            2 -> MultiviewLayout.TWO_BY_ONE
            3 -> MultiviewLayout.THREE_GRID
            else -> MultiviewLayout.TWO_BY_TWO
        }

        _uiState.update {
            it.copy(
                slots = slots,
                layout = layout,
                focusedSlotIndex = 0
            )
        }

        Timber.d("Multiview initialized with ${slots.size} slots")
    }

    fun getPlayer(slotIndex: Int): MultiviewPlayer? = players[slotIndex]

    fun setFocusedSlot(index: Int) {
        _uiState.update { it.copy(focusedSlotIndex = index) }
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

        // Update player with new channel
        players[slotIndex]?.apply {
            newChannel.streamUrl?.let { url -> play(url) }
        }

        // Update slot in state
        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(channel = newChannel, isReady = false)

        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Changed slot $slotIndex to channel: ${newChannel.name}")
    }

    fun addSlot() {
        val state = _uiState.value
        if (state.slots.size >= 4) return

        // Find a channel not already in a slot
        val usedIds = state.slots.map { it.channel.id }.toSet()
        val newChannel = state.allChannels.find { it.id !in usedIds }
            ?: state.allChannels.firstOrNull()
            ?: return

        val newIndex = state.slots.size
        val player = MultiviewPlayer(context).also { it.initialize() }
        players[newIndex] = player
        newChannel.streamUrl?.let { url -> player.play(url) }

        val newSlot = MultiviewSlot(
            index = newIndex,
            channel = newChannel,
            isReady = false
        )

        val updatedSlots = state.slots + newSlot
        val newLayout = when (updatedSlots.size) {
            2 -> MultiviewLayout.TWO_BY_ONE
            3 -> MultiviewLayout.THREE_GRID
            4 -> MultiviewLayout.TWO_BY_TWO
            else -> state.layout
        }

        _uiState.update {
            it.copy(slots = updatedSlots, layout = newLayout)
        }
        Timber.d("Added slot $newIndex with channel: ${newChannel.name}")
    }

    fun removeSlot(slotIndex: Int) {
        val state = _uiState.value
        if (state.slots.size <= 1) return
        if (slotIndex >= state.slots.size) return

        // Release player
        players[slotIndex]?.release()
        players.remove(slotIndex)

        // Reindex remaining players
        val remainingPlayers = mutableMapOf<Int, MultiviewPlayer>()
        var newIndex = 0
        players.forEach { (oldIndex, player) ->
            if (oldIndex != slotIndex) {
                remainingPlayers[newIndex] = player
                newIndex++
            }
        }
        players.clear()
        players.putAll(remainingPlayers)

        // Update slots
        val updatedSlots = state.slots.filterIndexed { index, _ -> index != slotIndex }
            .mapIndexed { index, slot -> slot.copy(index = index) }

        val newLayout = when (updatedSlots.size) {
            1 -> MultiviewLayout.SINGLE
            2 -> MultiviewLayout.TWO_BY_ONE
            3 -> MultiviewLayout.THREE_GRID
            else -> MultiviewLayout.TWO_BY_TWO
        }

        val newFocusedIndex = state.focusedSlotIndex.coerceAtMost(updatedSlots.size - 1)

        _uiState.update {
            it.copy(
                slots = updatedSlots,
                layout = newLayout,
                focusedSlotIndex = newFocusedIndex
            )
        }
        Timber.d("Removed slot $slotIndex")
    }

    fun toggleMuteOnSlot(slotIndex: Int) {
        players[slotIndex]?.toggleMute()

        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return
        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(isMuted = players[slotIndex]?.isMuted?.value ?: true)

        _uiState.update { it.copy(slots = updatedSlots) }
    }

    fun cycleLayout() {
        val state = _uiState.value
        val layouts = MultiviewLayout.entries
        val currentIndex = layouts.indexOf(state.layout)
        val nextIndex = (currentIndex + 1) % layouts.size

        _uiState.update { it.copy(layout = layouts[nextIndex]) }
    }

    fun swapChannel(slotIndex: Int, newChannel: Channel) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        // Update player
        players[slotIndex]?.apply {
            newChannel.streamUrl?.let { url -> play(url) }
        }

        // Update slot
        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(channel = newChannel, isReady = false)

        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Swapped slot $slotIndex to channel: ${newChannel.name}")
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

    /**
     * Start over the current program in a slot from the beginning.
     * Uses the server's timeshift buffer to seek back to program start.
     */
    fun startOverSlot(slotIndex: Int) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        viewModelScope.launch {
            liveTVRepository.getStartOverInfo(slot.channel.id)
                .onSuccess { startOverInfo ->
                    if (startOverInfo.available && !startOverInfo.streamUrl.isNullOrBlank()) {
                        // Play the start-over stream URL
                        players[slotIndex]?.apply {
                            play(startOverInfo.streamUrl)
                        }

                        // Update slot state to show it's timeshifted
                        val updatedSlots = state.slots.toMutableList()
                        updatedSlots[slotIndex] = slot.copy(
                            isTimeshifted = true,
                            timeshiftProgramTitle = startOverInfo.programTitle
                        )
                        _uiState.update { it.copy(slots = updatedSlots) }

                        Timber.d("Started over program '${startOverInfo.programTitle}' in slot $slotIndex")
                    } else {
                        Timber.w("Start over not available for channel: ${slot.channel.name}")
                    }
                }
                .onFailure { e ->
                    Timber.e(e, "Failed to get start over info for slot $slotIndex")
                }
        }
    }

    /**
     * Go back to live for a timeshifted slot.
     */
    fun goLiveSlot(slotIndex: Int) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        // Switch back to live stream
        players[slotIndex]?.apply {
            slot.channel.streamUrl?.let { url -> play(url) }
        }

        // Update slot state
        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(
            isTimeshifted = false,
            timeshiftProgramTitle = null
        )
        _uiState.update { it.copy(slots = updatedSlots) }

        Timber.d("Went live in slot $slotIndex")
    }

    /**
     * Swap channels between two slots.
     */
    fun swapSlots(sourceIndex: Int, targetIndex: Int) {
        val state = _uiState.value
        val sourceSlot = state.slots.getOrNull(sourceIndex) ?: return
        val targetSlot = state.slots.getOrNull(targetIndex) ?: return

        if (sourceIndex == targetIndex) return

        // Swap the streams in the players
        players[sourceIndex]?.apply {
            targetSlot.channel.streamUrl?.let { url -> play(url) }
        }
        players[targetIndex]?.apply {
            sourceSlot.channel.streamUrl?.let { url -> play(url) }
        }

        // Swap the channels in slots
        val updatedSlots = state.slots.toMutableList()
        updatedSlots[sourceIndex] = sourceSlot.copy(
            channel = targetSlot.channel,
            isReady = false,
            isTimeshifted = false
        )
        updatedSlots[targetIndex] = targetSlot.copy(
            channel = sourceSlot.channel,
            isReady = false,
            isTimeshifted = false
        )

        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Swapped slots $sourceIndex and $targetIndex")
    }

    /**
     * Set audio to a specific slot (mute all others).
     */
    fun setAudioSlot(slotIndex: Int) {
        val state = _uiState.value
        if (slotIndex >= state.slots.size) return

        // Mute all players except the target
        players.forEach { (index, player) ->
            if (index == slotIndex) {
                player.unmute()
            } else {
                player.mute()
            }
        }

        // Update slot mute states
        val updatedSlots = state.slots.mapIndexed { index, slot ->
            slot.copy(isMuted = index != slotIndex)
        }

        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Set audio to slot $slotIndex")
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
    val layout: MultiviewLayout = MultiviewLayout.TWO_BY_ONE,
    val focusedSlotIndex: Int = 0,
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
    TWO_BY_ONE,    // Side by side
    ONE_BY_TWO,    // Stacked
    THREE_GRID,    // 2 top, 1 bottom
    TWO_BY_TWO     // 2x2 grid
}
