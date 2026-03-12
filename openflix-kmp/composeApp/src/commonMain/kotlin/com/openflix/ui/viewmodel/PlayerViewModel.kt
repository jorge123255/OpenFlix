package com.openflix.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.network.OpenFlixApi
import com.openflix.ui.player.PlatformPlayer
import com.openflix.ui.util.platformSupportsMKV
import kotlinx.coroutines.isActive
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class PlayerUiState(
    val title: String = "",
    val subtitle: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
    val showOverlay: Boolean = true,
    val playbackSpeed: Float = 1.0f,
    val isLive: Boolean = false,
    val channelName: String = "",
    val channelNumber: String = "",
    val channelLogo: String = "",
    val channelId: String = "",
    val programTitle: String = "",
    val archiveEnabled: Boolean = false,
    val isSwitchingChannel: Boolean = false
)

class PlayerViewModel(
    private val api: OpenFlixApi,
    val player: PlatformPlayer
) : ViewModel() {

    private val _uiState = MutableStateFlow(PlayerUiState())
    val uiState: StateFlow<PlayerUiState> = _uiState.asStateFlow()

    private var overlayHideJob: Job? = null
    private var progressTrackingJob: Job? = null
    private var mediaKey: String? = null

    private val speedOptions = listOf(0.5f, 0.75f, 1.0f, 1.25f, 1.5f, 2.0f)

    fun loadMedia(key: String) {
        _uiState.update { it.copy(isLoading = true, error = null, isLive = false) }
        mediaKey = key

        viewModelScope.launch {
            try {
                // Try to load media details for title
                val mediaId = key.toIntOrNull()
                if (mediaId != null) {
                    try {
                        val response = api.getMediaDetails(mediaId)
                        val item = response.MediaContainer?.Metadata?.firstOrNull()
                        if (item != null) {
                            _uiState.update { it.copy(title = item.title ?: "", subtitle = item.year?.toString() ?: "") }
                        }
                    } catch (_: Exception) { }
                }

                val id = mediaId ?: key.toIntOrNull() ?: throw Exception("Invalid media key: $key")
                val streamInfo = api.getStreamInfo(id)

                // On platforms that don't support MKV (iOS), use server-side HLS transcoding
                val playUrl = if (!platformSupportsMKV && streamInfo.container?.lowercase() == "mkv") {
                    api.getTranscodeUrl(id)
                } else {
                    streamInfo.url
                }
                player.play(playUrl, _uiState.value.title)

                _uiState.update { it.copy(isLoading = false) }
                startProgressTracking()
                scheduleOverlayHide()
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoading = false, error = e.message ?: "Failed to load media") }
            }
        }
    }

    fun loadChannel(channelId: String, channelName: String = "", channelNumber: String = "", channelLogo: String = "", streamUrl: String = "", archiveEnabled: Boolean = false) {
        _uiState.update {
            it.copy(
                isLoading = true,
                error = null,
                isLive = true,
                channelId = channelId,
                channelName = channelName,
                channelNumber = channelNumber,
                channelLogo = channelLogo,
                title = channelName,
                archiveEnabled = archiveEnabled,
                isSwitchingChannel = false
            )
        }

        viewModelScope.launch {
            try {
                val url = if (streamUrl.isNotEmpty()) {
                    streamUrl
                } else {
                    api.getChannelStream(channelId).url
                }
                player.play(url, channelName, isLive = true)
                _uiState.update { it.copy(isLoading = false) }
                scheduleOverlayHide()
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoading = false, error = e.message ?: "Failed to load channel") }
            }
        }
    }

    fun switchChannel(channelId: String, channelName: String, channelNumber: String, channelLogo: String, streamUrl: String, archiveEnabled: Boolean) {
        player.stop()
        _uiState.update {
            it.copy(
                isSwitchingChannel = true,
                channelId = channelId,
                channelName = channelName,
                channelNumber = channelNumber,
                channelLogo = channelLogo,
                title = channelName,
                archiveEnabled = archiveEnabled,
                error = null
            )
        }
        viewModelScope.launch {
            try {
                val url = if (streamUrl.isNotEmpty()) {
                    streamUrl
                } else {
                    api.getChannelStream(channelId).url
                }
                player.play(url, channelName, isLive = true)
                _uiState.update { it.copy(isSwitchingChannel = false, showOverlay = true) }
                scheduleOverlayHide()
            } catch (e: Exception) {
                _uiState.update { it.copy(isSwitchingChannel = false, error = e.message ?: "Failed to switch channel") }
            }
        }
    }

    fun loadRecording(recordingKey: String) {
        _uiState.update { it.copy(isLoading = true, error = null, isLive = false) }
        mediaKey = null

        viewModelScope.launch {
            try {
                val recordingId = recordingKey.toIntOrNull() ?: 0
                val response = api.getRecordingStream(recordingId)
                player.play(response.url)
                _uiState.update { it.copy(isLoading = false) }
                scheduleOverlayHide()
            } catch (e: Exception) {
                _uiState.update { it.copy(isLoading = false, error = e.message ?: "Failed to load recording") }
            }
        }
    }

    fun togglePlayPause() {
        if (player.isPlaying.value) {
            player.pause()
        } else {
            player.resume()
        }
        showOverlayBriefly()
    }

    fun skipForward() {
        player.seekRelative(10_000)
        showOverlayBriefly()
    }

    fun skipBack() {
        player.seekRelative(-10_000)
        showOverlayBriefly()
    }

    fun seekTo(positionMs: Long) {
        player.seekTo(positionMs)
    }

    fun cycleSpeed() {
        val currentSpeed = _uiState.value.playbackSpeed
        val currentIndex = speedOptions.indexOf(currentSpeed)
        val nextIndex = if (currentIndex >= 0) (currentIndex + 1) % speedOptions.size else 2
        val newSpeed = speedOptions[nextIndex]
        player.setSpeed(newSpeed)
        _uiState.update { it.copy(playbackSpeed = newSpeed) }
    }

    fun toggleOverlay() {
        val showing = !_uiState.value.showOverlay
        _uiState.update { it.copy(showOverlay = showing) }
        if (showing) scheduleOverlayHide()
    }

    fun showOverlayBriefly() {
        _uiState.update { it.copy(showOverlay = true) }
        scheduleOverlayHide()
    }

    private fun scheduleOverlayHide() {
        overlayHideJob?.cancel()
        overlayHideJob = viewModelScope.launch {
            delay(5000)
            _uiState.update { it.copy(showOverlay = false) }
        }
    }

    private fun startProgressTracking() {
        progressTrackingJob?.cancel()
        progressTrackingJob = viewModelScope.launch {
            while (true) {
                delay(10_000)
                val key = mediaKey?.toIntOrNull() ?: continue
                val pos = player.position.value
                if (pos > 0) {
                    try {
                        api.updateProgress(key, (pos / 1000).toInt(), "playing")
                    } catch (_: Exception) { }
                }
            }
        }
    }

    fun saveProgress() {
        val key = mediaKey?.toIntOrNull() ?: return
        val pos = player.position.value
        if (pos > 0) {
            viewModelScope.launch {
                try {
                    api.updateProgress(key, (pos / 1000).toInt(), "stopped")
                } catch (_: Exception) { }
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        saveProgress()
        player.release()
    }
}
