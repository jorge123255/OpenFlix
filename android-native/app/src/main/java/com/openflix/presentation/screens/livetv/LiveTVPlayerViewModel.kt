package com.openflix.presentation.screens.livetv

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.local.PreferencesManager
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import com.openflix.domain.model.Program
import com.openflix.domain.model.StartOverInfo
import com.openflix.domain.model.TimeShiftMode
import com.openflix.player.LoadState
import com.openflix.player.MpvPlayer
import com.openflix.player.PlayerController
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for LiveTV player screen.
 * Manages channel switching, stream loading, and player state.
 */
@HiltViewModel
class LiveTVPlayerViewModel @Inject constructor(
    private val repository: LiveTVRepository,
    private val playerController: PlayerController,
    private val mpvPlayer: MpvPlayer,
    private val preferencesManager: PreferencesManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(LiveTVPlayerUiState())
    val uiState: StateFlow<LiveTVPlayerUiState> = _uiState.asStateFlow()

    // Expose player states
    val isPlaying: StateFlow<Boolean> = playerController.isPlaying
    val playerState = playerController.playerState

    private var allChannels: List<Channel> = emptyList()
    private var currentChannelIndex: Int = 0
    private var previousChannelIndex: Int = -1  // For "Previous Channel" feature
    private var timeshiftUpdateJob: Job? = null
    private var sleepTimerJob: Job? = null
    private var liveStreamUrl: String? = null  // Store the original live URL

    init {
        // Initialize mpv player
        mpvPlayer.initialize()

        // Observe player state
        viewModelScope.launch {
            playerController.playerState.collect { state ->
                _uiState.update { it.copy(
                    isLoading = state.loadState == LoadState.LOADING,
                    isBuffering = state.loadState == LoadState.LOADING,
                    error = state.error,
                    isMuted = state.isMuted
                )}
            }
        }

        // Observe favorite channels
        viewModelScope.launch {
            preferencesManager.favoriteChannelIds.collect { favoriteIds ->
                _uiState.update { it.copy(favoriteChannelIds = favoriteIds) }
            }
        }
    }

    fun loadChannelsAndPlay(channelId: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            repository.getChannels().fold(
                onSuccess = { channels ->
                    allChannels = channels.filter { !it.hidden }
                    currentChannelIndex = channels.indexOfFirst { it.id == channelId }
                        .takeIf { it >= 0 } ?: 0

                    val channel = if (currentChannelIndex in channels.indices) {
                        channels[currentChannelIndex]
                    } else {
                        channels.firstOrNull()
                    }

                    if (channel != null) {
                        _uiState.update { it.copy(
                            channels = channels,
                            currentChannel = channel,
                            isLoading = false
                        )}
                        playChannel(channel)
                    } else {
                        _uiState.update { it.copy(
                            isLoading = false,
                            error = "No channels available"
                        )}
                    }
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load channels")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load channels"
                    )}
                }
            )
        }
    }

    private fun playChannel(channel: Channel) {
        viewModelScope.launch {
            _uiState.update { it.copy(
                isLoading = true,
                error = null,
                // Reset time-shift state when changing channels
                timeShiftMode = TimeShiftMode.LIVE,
                timeShiftOffset = 0,
                isPaused = false,
                isStartOverAvailable = false,
                startOverInfo = null
            )}

            // Use streamUrl directly from channel data
            val streamUrl = channel.streamUrl
            if (streamUrl.isNullOrBlank()) {
                Timber.e("No stream URL for channel: ${channel.id} (${channel.name})")
                _uiState.update { it.copy(
                    isLoading = false,
                    error = "No stream URL available for this channel"
                )}
                return@launch
            }

            // Store the live URL for later use
            liveStreamUrl = streamUrl

            Timber.d("Playing channel: ${channel.name} - $streamUrl")
            playerController.playMedia(
                mediaId = channel.id,
                url = streamUrl
            )
            _uiState.update { it.copy(
                currentChannel = channel,
                isLoading = false
            )}

            // Check if start over is available for this channel
            checkStartOverAvailability()

            // Fetch upcoming programs for Mini EPG
            fetchUpcomingPrograms()

            // Auto-start timeshift buffer for the channel
            startTimeshift()
        }
    }

    fun channelUp() {
        if (allChannels.isEmpty()) return
        currentChannelIndex = (currentChannelIndex - 1 + allChannels.size) % allChannels.size
        playChannel(allChannels[currentChannelIndex])
    }

    fun channelDown() {
        if (allChannels.isEmpty()) return
        currentChannelIndex = (currentChannelIndex + 1) % allChannels.size
        playChannel(allChannels[currentChannelIndex])
    }

    fun switchToChannel(channel: Channel) {
        val index = allChannels.indexOfFirst { it.id == channel.id }
        if (index >= 0) {
            // Store previous channel before switching
            previousChannelIndex = currentChannelIndex
            currentChannelIndex = index
            playChannel(channel)
        }
    }

    /**
     * Switch back to the previously watched channel (like Last/Recall on remotes)
     */
    fun previousChannel() {
        if (previousChannelIndex >= 0 && previousChannelIndex != currentChannelIndex) {
            val prevChannel = allChannels.getOrNull(previousChannelIndex)
            if (prevChannel != null) {
                val tempCurrent = currentChannelIndex
                currentChannelIndex = previousChannelIndex
                previousChannelIndex = tempCurrent
                playChannel(prevChannel)
            }
        }
    }

    // ============ Aspect Ratio Controls ============

    /**
     * Cycle through aspect ratio modes
     */
    fun cycleAspectRatio() {
        val currentMode = _uiState.value.aspectRatioMode
        val modes = AspectRatioMode.entries.toTypedArray()
        val nextIndex = (modes.indexOf(currentMode) + 1) % modes.size
        val nextMode = modes[nextIndex]

        _uiState.update { it.copy(aspectRatioMode = nextMode) }

        // Apply aspect ratio to player using mpv video-aspect-override property
        // Values: "no" (auto), "16:9", "4:3", or a decimal ratio
        when (nextMode) {
            AspectRatioMode.FIT -> mpvPlayer.setAspectRatio("no") // Auto - respect source aspect
            AspectRatioMode.FILL -> mpvPlayer.setAspectRatio("-1") // Stretch to window
            AspectRatioMode.ZOOM -> mpvPlayer.setAspectRatio("2.35:1") // Crop to cinematic
            AspectRatioMode.RATIO_16_9 -> mpvPlayer.setAspectRatio("16:9")
            AspectRatioMode.RATIO_4_3 -> mpvPlayer.setAspectRatio("4:3")
            AspectRatioMode.STRETCH -> mpvPlayer.setAspectRatio("-1") // Stretch to window aspect
        }

        Timber.d("Aspect ratio changed to: $nextMode")
    }

    // ============ Quick Track Switching (Tivimate feature) ============

    /**
     * Cycle to the next audio track and show feedback
     */
    fun cycleAudioTrack() {
        viewModelScope.launch {
            val track = mpvPlayer.cycleAudioTrack()
            val message = if (track != null) {
                "Audio: ${track.title}"
            } else {
                "Audio: Default"
            }
            _uiState.update { it.copy(audioTrackMessage = message) }

            // Clear message after 2 seconds
            delay(2000)
            _uiState.update { it.copy(audioTrackMessage = null) }
        }
    }

    /**
     * Cycle to the next subtitle track and show feedback
     */
    fun cycleSubtitleTrack() {
        viewModelScope.launch {
            val track = mpvPlayer.cycleSubtitleTrack()
            val message = if (track != null) {
                "Subtitles: ${track.title}"
            } else {
                "Subtitles: Off"
            }
            _uiState.update { it.copy(subtitleTrackMessage = message) }

            // Clear message after 2 seconds
            delay(2000)
            _uiState.update { it.copy(subtitleTrackMessage = null) }
        }
    }

    fun switchToChannelByNumber(channelNumber: Int) {
        val channel = allChannels.find {
            it.number?.toIntOrNull() == channelNumber
        }
        if (channel != null) {
            switchToChannel(channel)
        }
    }

    fun getNextChannels(count: Int = 5): List<Channel> {
        if (allChannels.isEmpty()) return emptyList()
        return (1..count).mapNotNull { offset ->
            val index = (currentChannelIndex + offset) % allChannels.size
            allChannels.getOrNull(index)
        }
    }

    fun getPreviousChannels(count: Int = 5): List<Channel> {
        if (allChannels.isEmpty()) return emptyList()
        return (1..count).mapNotNull { offset ->
            val index = (currentChannelIndex - offset + allChannels.size) % allChannels.size
            allChannels.getOrNull(index)
        }.reversed()
    }

    fun togglePlayPause() {
        playerController.togglePlayPause()
    }

    fun setVolume(volume: Int) {
        playerController.setVolume(volume)
        _uiState.update { it.copy(volume = volume) }
    }

    fun toggleMute() {
        playerController.toggleMute()
    }

    fun toggleFavorite(channelId: String) {
        viewModelScope.launch {
            preferencesManager.toggleFavoriteChannel(channelId)
        }
    }

    fun toggleFavoritesFilter() {
        _uiState.update { it.copy(showFavoritesOnly = !it.showFavoritesOnly) }
    }

    fun isChannelFavorite(channelId: String): Boolean {
        return channelId in _uiState.value.favoriteChannelIds
    }

    fun getFilteredChannels(): List<Channel> {
        val state = _uiState.value
        return if (state.showFavoritesOnly) {
            state.channels.filter { it.id in state.favoriteChannelIds }
        } else {
            state.channels
        }
    }

    // ============ Time-Shift Controls ============

    /**
     * Start timeshift buffering for the current channel.
     * This enables pause/rewind functionality.
     */
    fun startTimeshift() {
        val channel = _uiState.value.currentChannel ?: return
        viewModelScope.launch {
            repository.startTimeshiftBuffer(channel.id).fold(
                onSuccess = {
                    Timber.d("Started timeshift buffer for channel: ${channel.name}")
                    _uiState.update { it.copy(isTimeshiftAvailable = true) }
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to start timeshift buffer")
                }
            )
        }
    }

    /**
     * Check if Start Over is available for the current channel/program
     */
    fun checkStartOverAvailability() {
        val channel = _uiState.value.currentChannel ?: return
        viewModelScope.launch {
            repository.getStartOverInfo(channel.id).fold(
                onSuccess = { info ->
                    _uiState.update { it.copy(
                        startOverInfo = info,
                        isStartOverAvailable = info.available
                    )}
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to check start over availability")
                    _uiState.update { it.copy(isStartOverAvailable = false) }
                }
            )
        }
    }

    /**
     * Fetch upcoming programs for the current channel (for Mini EPG)
     */
    fun fetchUpcomingPrograms() {
        val channel = _uiState.value.currentChannel ?: return
        viewModelScope.launch {
            // Get EPG for the next 4 hours
            val now = System.currentTimeMillis() / 1000
            val fourHoursLater = now + (4 * 60 * 60)

            repository.getEPG(
                channelIds = listOf(channel.id),
                startTime = now,
                endTime = fourHoursLater
            ).fold(
                onSuccess = { epgData ->
                    val programs = epgData.channels
                        .find { it.id == channel.id }
                        ?.programs
                        ?.sortedBy { it.startTime }
                        ?: emptyList()

                    _uiState.update { it.copy(upcomingPrograms = programs) }
                    Timber.d("Loaded ${programs.size} upcoming programs for ${channel.name}")
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to fetch upcoming programs")
                }
            )
        }
    }

    /**
     * Start over the current program from the beginning
     */
    fun startOver() {
        val channel = _uiState.value.currentChannel ?: return
        val startOverInfo = _uiState.value.startOverInfo ?: return

        if (!startOverInfo.available || startOverInfo.streamUrl.isNullOrBlank()) {
            Timber.w("Start over not available for this channel")
            return
        }

        viewModelScope.launch {
            Timber.d("Starting over program: ${startOverInfo.programTitle}")
            _uiState.update { it.copy(
                timeShiftMode = TimeShiftMode.START_OVER,
                timeShiftOffset = startOverInfo.secondsIntoProgram
            )}

            playerController.playMedia(
                mediaId = "${channel.id}_startover",
                url = startOverInfo.streamUrl
            )
        }
    }

    /**
     * Toggle pause/play for time-shifted playback
     */
    fun togglePause() {
        val state = _uiState.value

        if (state.timeShiftMode == TimeShiftMode.LIVE) {
            // First pause - switch to time-shifted mode
            playerController.togglePlayPause()
            if (!playerController.isPlaying.value) {
                _uiState.update { it.copy(
                    timeShiftMode = TimeShiftMode.TIME_SHIFTED,
                    isPaused = true
                )}
            }
        } else {
            // Already time-shifted, just toggle play/pause
            playerController.togglePlayPause()
            _uiState.update { it.copy(isPaused = !playerController.isPlaying.value) }
        }
    }

    /**
     * Seek backwards by the given number of seconds
     */
    fun seekBack(seconds: Int = 10) {
        val currentOffset = _uiState.value.timeShiftOffset
        val newOffset = currentOffset + seconds

        _uiState.update { it.copy(
            timeShiftMode = TimeShiftMode.TIME_SHIFTED,
            timeShiftOffset = newOffset
        )}

        // Seek in the player using relative seek
        playerController.seekBackward(seconds)

        Timber.d("Seeking back $seconds seconds, new offset: $newOffset")
    }

    /**
     * Seek forward by the given number of seconds
     */
    fun seekForward(seconds: Int = 10) {
        val currentOffset = _uiState.value.timeShiftOffset
        val newOffset = (currentOffset - seconds).coerceAtLeast(0)

        if (newOffset == 0L) {
            // Back to live
            goLive()
        } else {
            _uiState.update { it.copy(
                timeShiftMode = TimeShiftMode.TIME_SHIFTED,
                timeShiftOffset = newOffset
            )}

            playerController.seekForward(seconds)
        }

        Timber.d("Seeking forward $seconds seconds, new offset: $newOffset")
    }

    /**
     * Jump back to live playback
     */
    fun goLive() {
        val channel = _uiState.value.currentChannel ?: return

        Timber.d("Going back to live")
        _uiState.update { it.copy(
            timeShiftMode = TimeShiftMode.LIVE,
            timeShiftOffset = 0,
            isPaused = false
        )}

        // Play the original live stream
        liveStreamUrl?.let { url ->
            playerController.playMedia(
                mediaId = channel.id,
                url = url
            )
        }
    }

    /**
     * Seek to a specific position (for scrubber)
     */
    fun seekToPosition(positionMs: Long) {
        playerController.seekTo(positionMs)

        // Calculate offset from live
        val durationMs = playerController.duration.value
        val offsetMs = durationMs - positionMs
        val offsetSeconds = (offsetMs / 1000).coerceAtLeast(0)

        _uiState.update { it.copy(
            timeShiftMode = if (offsetSeconds > 5) TimeShiftMode.TIME_SHIFTED else TimeShiftMode.LIVE,
            timeShiftOffset = offsetSeconds
        )}
    }

    // ============ Sleep Timer (Tivimate feature) ============

    /**
     * Available sleep timer durations
     */
    val sleepTimerOptions = listOf(15, 30, 45, 60, 90, 120) // minutes

    /**
     * Toggle sleep timer picker visibility
     */
    fun toggleSleepTimerPicker() {
        _uiState.update { it.copy(showSleepTimerPicker = !it.showSleepTimerPicker) }
    }

    /**
     * Set sleep timer for the specified duration
     */
    fun setSleepTimer(minutes: Int) {
        // Cancel existing timer
        sleepTimerJob?.cancel()

        _uiState.update { it.copy(
            sleepTimerMinutesRemaining = minutes,
            showSleepTimerPicker = false
        )}

        Timber.d("Sleep timer set for $minutes minutes")

        // Start countdown
        sleepTimerJob = viewModelScope.launch {
            var remaining = minutes
            while (remaining > 0) {
                delay(60_000) // 1 minute
                remaining--
                _uiState.update { it.copy(sleepTimerMinutesRemaining = remaining) }
                Timber.d("Sleep timer: $remaining minutes remaining")
            }

            // Timer expired - stop playback
            Timber.d("Sleep timer expired - stopping playback")
            playerController.stop()
            _uiState.update { it.copy(sleepTimerMinutesRemaining = null) }
        }
    }

    /**
     * Cancel the active sleep timer
     */
    fun cancelSleepTimer() {
        sleepTimerJob?.cancel()
        sleepTimerJob = null
        _uiState.update { it.copy(
            sleepTimerMinutesRemaining = null,
            showSleepTimerPicker = false
        )}
        Timber.d("Sleep timer cancelled")
    }

    /**
     * Get formatted display of remaining time
     */
    fun getSleepTimerDisplay(): String {
        val minutes = _uiState.value.sleepTimerMinutesRemaining ?: return ""
        val hours = minutes / 60
        val mins = minutes % 60
        return if (hours > 0) {
            "${hours}h ${mins}m"
        } else {
            "${mins}m"
        }
    }

    // ============ Channel Search (Tivimate feature) ============

    /**
     * Toggle channel search overlay
     */
    fun toggleChannelSearch() {
        val newState = !_uiState.value.showChannelSearch
        _uiState.update { it.copy(
            showChannelSearch = newState,
            channelSearchQuery = if (newState) "" else it.channelSearchQuery,
            filteredChannels = if (newState) allChannels else emptyList()
        )}
    }

    /**
     * Update search query and filter channels
     */
    fun updateSearchQuery(query: String) {
        val filtered = if (query.isBlank()) {
            allChannels
        } else {
            allChannels.filter { channel ->
                channel.name.contains(query, ignoreCase = true) ||
                channel.number?.contains(query) == true ||
                channel.callsign?.contains(query, ignoreCase = true) == true ||
                channel.group?.contains(query, ignoreCase = true) == true
            }
        }

        _uiState.update { it.copy(
            channelSearchQuery = query,
            filteredChannels = filtered
        )}
    }

    /**
     * Select channel from search results
     */
    fun selectSearchResult(channel: Channel) {
        switchToChannel(channel)
        _uiState.update { it.copy(
            showChannelSearch = false,
            channelSearchQuery = ""
        )}
    }

    /**
     * Close channel search
     */
    fun closeChannelSearch() {
        _uiState.update { it.copy(
            showChannelSearch = false,
            channelSearchQuery = ""
        )}
    }

    override fun onCleared() {
        super.onCleared()
        timeshiftUpdateJob?.cancel()
        sleepTimerJob?.cancel()
        playerController.stop()
    }
}

/**
 * Aspect ratio modes for video playback (like Tivimate)
 */
enum class AspectRatioMode(val displayName: String) {
    FIT("Fit"),           // Auto - maintain aspect, letterbox if needed
    FILL("Fill"),         // Stretch to fill, may crop
    ZOOM("Zoom"),         // Crop to fill, maintain aspect
    RATIO_16_9("16:9"),   // Force 16:9
    RATIO_4_3("4:3"),     // Force 4:3
    STRETCH("Stretch")    // Stretch to fill, ignore aspect
}

data class LiveTVPlayerUiState(
    val channels: List<Channel> = emptyList(),
    val currentChannel: Channel? = null,
    val isLoading: Boolean = false,
    val isBuffering: Boolean = false,
    val error: String? = null,
    val showOverlay: Boolean = true,
    val favoriteChannelIds: Set<String> = emptySet(),
    val showFavoritesOnly: Boolean = false,
    val isMuted: Boolean = false,
    val volume: Int = 100,
    // Time-shift state
    val timeShiftMode: TimeShiftMode = TimeShiftMode.LIVE,
    val timeShiftOffset: Long = 0,  // Seconds behind live
    val isTimeshiftAvailable: Boolean = false,
    val isStartOverAvailable: Boolean = false,
    val startOverInfo: StartOverInfo? = null,
    val isPaused: Boolean = false,
    // Aspect ratio
    val aspectRatioMode: AspectRatioMode = AspectRatioMode.FIT,
    // Mini EPG - upcoming programs for current channel
    val upcomingPrograms: List<Program> = emptyList(),
    // Track quick switch feedback
    val audioTrackMessage: String? = null,
    val subtitleTrackMessage: String? = null,
    // Sleep timer
    val sleepTimerMinutesRemaining: Int? = null,
    val showSleepTimerPicker: Boolean = false,
    // Channel search
    val showChannelSearch: Boolean = false,
    val channelSearchQuery: String = "",
    val filteredChannels: List<Channel> = emptyList()
) {
    val isLive: Boolean get() = timeShiftMode == TimeShiftMode.LIVE
    val isTimeShifted: Boolean get() = timeShiftMode != TimeShiftMode.LIVE

    val timeShiftOffsetDisplay: String get() {
        if (timeShiftOffset <= 0) return ""
        val minutes = timeShiftOffset / 60
        val seconds = timeShiftOffset % 60
        return if (minutes > 0) {
            "-${minutes}m ${seconds}s"
        } else {
            "-${seconds}s"
        }
    }
}
