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

    // ==========================================================================
    // DVR Controls - Our KEY DIFFERENTIATOR vs Channels DVR!
    // Channels DVR CAN'T pause/rewind in multiview. We CAN!
    // ==========================================================================

    /**
     * Pause a specific slot - Channels DVR CAN'T do this!
     */
    fun pauseSlot(slotIndex: Int) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        players[slotIndex]?.pause()

        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(
            dvrState = slot.dvrState.copy(isPaused = true, isLive = false)
        )
        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Paused slot $slotIndex")
    }

    /**
     * Resume a paused slot
     */
    fun resumeSlot(slotIndex: Int) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        players[slotIndex]?.resume()

        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(
            dvrState = slot.dvrState.copy(isPaused = false)
        )
        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Resumed slot $slotIndex")
    }

    /**
     * Toggle pause on a slot
     */
    fun togglePauseSlot(slotIndex: Int) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return
        if (slot.dvrState.isPaused) {
            resumeSlot(slotIndex)
        } else {
            pauseSlot(slotIndex)
        }
    }

    /**
     * Rewind a slot by seconds - Channels DVR CAN'T do this!
     */
    fun rewindSlot(slotIndex: Int, seconds: Int = 15) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        players[slotIndex]?.seekBack(seconds)

        val newOffset = slot.dvrState.liveOffsetSecs + seconds
        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(
            dvrState = slot.dvrState.copy(isLive = false, liveOffsetSecs = newOffset)
        )
        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Rewound slot $slotIndex by $seconds seconds")
    }

    /**
     * Fast forward a slot
     */
    fun fastForwardSlot(slotIndex: Int, seconds: Int = 15) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        players[slotIndex]?.seekForward(seconds)

        val newOffset = (slot.dvrState.liveOffsetSecs - seconds).coerceAtLeast(0)
        val isNowLive = newOffset == 0
        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(
            dvrState = slot.dvrState.copy(isLive = isNowLive, liveOffsetSecs = newOffset)
        )
        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Fast-forwarded slot $slotIndex by $seconds seconds")
    }

    /**
     * Jump a slot back to live
     */
    fun jumpToLiveSlot(slotIndex: Int) {
        val state = _uiState.value
        val slot = state.slots.getOrNull(slotIndex) ?: return

        players[slotIndex]?.seekToLive()

        val updatedSlots = state.slots.toMutableList()
        updatedSlots[slotIndex] = slot.copy(
            dvrState = SlotDVRState(isLive = true)  // Reset to default live state
        )
        _uiState.update { it.copy(slots = updatedSlots) }
        Timber.d("Jumped slot $slotIndex to live")
    }

    /**
     * PAUSE ALL streams - one button convenience!
     */
    fun pauseAll() {
        _uiState.value.slots.forEachIndexed { index, _ ->
            pauseSlot(index)
        }
        Timber.d("Paused all slots")
    }

    /**
     * RESUME ALL streams
     */
    fun resumeAll() {
        _uiState.value.slots.forEachIndexed { index, _ ->
            resumeSlot(index)
        }
        Timber.d("Resumed all slots")
    }

    /**
     * JUMP ALL TO LIVE - sync all streams to live
     */
    fun jumpAllToLive() {
        _uiState.value.slots.forEachIndexed { index, _ ->
            jumpToLiveSlot(index)
        }
        Timber.d("Jumped all slots to live")
    }

    /**
     * SYNC all streams - align timestamps by rewinding all to match furthest behind
     */
    fun syncAllStreams() {
        val state = _uiState.value
        // Find the stream that's furthest behind live
        val maxOffset = state.slots.maxOfOrNull { it.dvrState.liveOffsetSecs } ?: 0

        // Rewind all streams to match
        state.slots.forEachIndexed { index, slot ->
            val currentOffset = slot.dvrState.liveOffsetSecs
            if (currentOffset < maxOffset) {
                val rewindAmount = maxOffset - currentOffset
                rewindSlot(index, rewindAmount)
            }
        }
        Timber.d("Synced all slots to offset $maxOffset seconds")
    }

    /**
     * Check if any slot is paused
     */
    val anySlotPaused: Boolean
        get() = _uiState.value.slots.any { it.dvrState.isPaused }

    /**
     * Check if all slots are live
     */
    val allSlotsLive: Boolean
        get() = _uiState.value.slots.all { it.dvrState.isLive }

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

/**
 * DVR state for a multiview slot - Our KEY DIFFERENTIATOR vs Channels DVR!
 * Channels DVR has NO pause/rewind in multiview. We do!
 */
data class SlotDVRState(
    val isPaused: Boolean = false,
    val isLive: Boolean = true,
    val liveOffsetSecs: Int = 0,
    val playbackSpeed: Float = 1.0f,
    val bufferSecs: Int = 1800  // 30 minutes default
)

data class MultiviewSlot(
    val index: Int,
    val channel: Channel,
    val isReady: Boolean = false,
    val isMuted: Boolean = true,
    val isTimeshifted: Boolean = false,
    val timeshiftProgramTitle: String? = null,
    val dvrState: SlotDVRState = SlotDVRState()
)

enum class MultiviewLayout {
    SINGLE,
    TWO_BY_ONE,    // Side by side
    ONE_BY_TWO,    // Stacked
    THREE_GRID,    // 2 top, 1 bottom
    TWO_BY_TWO     // 2x2 grid
}
