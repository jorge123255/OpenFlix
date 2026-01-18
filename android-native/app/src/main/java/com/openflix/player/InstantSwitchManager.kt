package com.openflix.player

import android.content.Context
import android.view.SurfaceView
import dagger.hilt.android.qualifiers.ApplicationContext
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import com.openflix.domain.model.Channel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages instant channel switching by pre-buffering adjacent channels.
 *
 * This provides Channels DVR-style instant switching by:
 * 1. Maintaining a pool of 3 ExoPlayer instances (main + 2 buffers)
 * 2. Pre-buffering the next and previous channels in the background
 * 3. Instantly swapping players when switching to a pre-buffered channel
 * 4. Falling back to normal playback for non-adjacent channels
 */
@Singleton
@OptIn(UnstableApi::class)
class InstantSwitchManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val BUFFER_COUNT = 2 // Number of adjacent channels to pre-buffer (up and down)
        private const val PREBUFFER_DELAY_MS = 500L // Delay before starting pre-buffer
    }

    // Player pool
    private val playerPool = mutableMapOf<String, BufferedPlayer>() // channelId -> player
    private var activePlayer: BufferedPlayer? = null
    private var currentSurfaceView: SurfaceView? = null

    // Channel list for navigation
    private var channels: List<Channel> = emptyList()
    private var currentChannelIndex: Int = 0

    // State flows
    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _isBuffering = MutableStateFlow(false)
    val isBuffering: StateFlow<Boolean> = _isBuffering.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _isMuted = MutableStateFlow(false)
    val isMuted: StateFlow<Boolean> = _isMuted.asStateFlow()

    private val _instantSwitchReady = MutableStateFlow(false)
    val instantSwitchReady: StateFlow<Boolean> = _instantSwitchReady.asStateFlow()

    // Pre-buffer state for UI feedback
    private val _preBufferedChannels = MutableStateFlow<Set<String>>(emptySet())
    val preBufferedChannels: StateFlow<Set<String>> = _preBufferedChannels.asStateFlow()

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var preBufferJob: Job? = null

    /**
     * Set the full channel list for navigation
     */
    fun setChannels(channelList: List<Channel>) {
        channels = channelList
        Timber.d("InstantSwitchManager: Set ${channelList.size} channels")
    }

    /**
     * Set the surface view for video output
     */
    fun setSurfaceView(surfaceView: SurfaceView?) {
        currentSurfaceView = surfaceView
        activePlayer?.player?.setVideoSurfaceView(surfaceView)
        Timber.d("InstantSwitchManager: Surface set: ${surfaceView != null}")
    }

    /**
     * Get the active ExoPlayer instance
     */
    fun getActivePlayer(): ExoPlayer? = activePlayer?.player

    /**
     * Play a channel - uses pre-buffered player if available, otherwise creates new one
     */
    fun playChannel(channel: Channel): Boolean {
        val streamUrl = channel.streamUrl
        if (streamUrl.isNullOrBlank()) {
            Timber.e("No stream URL for channel: ${channel.id}")
            _error.value = "No stream URL available"
            return false
        }

        // Update current index
        currentChannelIndex = channels.indexOfFirst { it.id == channel.id }.takeIf { it >= 0 } ?: 0

        // Check if we have this channel pre-buffered
        val existingPlayer = playerPool[channel.id]
        if (existingPlayer != null && existingPlayer.isReady) {
            Timber.d("Instant switch to pre-buffered channel: ${channel.name}")
            switchToPlayer(existingPlayer, channel)
            return true
        }

        // No pre-buffered player, create new one
        Timber.d("Normal switch to channel: ${channel.name}")
        val newPlayer = createPlayer(channel.id, streamUrl, isMain = true)
        switchToPlayer(newPlayer, channel)
        return false
    }

    /**
     * Check if a channel switch would be instant
     */
    fun isInstantSwitchAvailable(channelId: String): Boolean {
        return playerPool[channelId]?.isReady == true
    }

    /**
     * Switch to the next channel (channel down)
     */
    fun channelDown(): Channel? {
        if (channels.isEmpty()) return null
        currentChannelIndex = (currentChannelIndex + 1) % channels.size
        val nextChannel = channels[currentChannelIndex]
        playChannel(nextChannel)
        return nextChannel
    }

    /**
     * Switch to the previous channel (channel up)
     */
    fun channelUp(): Channel? {
        if (channels.isEmpty()) return null
        currentChannelIndex = (currentChannelIndex - 1 + channels.size) % channels.size
        val prevChannel = channels[currentChannelIndex]
        playChannel(prevChannel)
        return prevChannel
    }

    /**
     * Switch to a specific channel by index
     */
    fun switchToChannelByIndex(index: Int): Channel? {
        if (index !in channels.indices) return null
        currentChannelIndex = index
        val channel = channels[index]
        playChannel(channel)
        return channel
    }

    private fun switchToPlayer(newPlayer: BufferedPlayer, channel: Channel) {
        // Pause old player (keep it for potential back-switch)
        activePlayer?.let { oldPlayer ->
            oldPlayer.player.volume = 0f
            oldPlayer.player.pause()
        }

        // Activate new player
        activePlayer = newPlayer
        newPlayer.player.setVideoSurfaceView(currentSurfaceView)
        newPlayer.player.volume = if (_isMuted.value) 0f else 1f
        newPlayer.player.play()

        _isPlaying.value = true
        _isBuffering.value = !newPlayer.isReady
        _error.value = null

        // Start pre-buffering adjacent channels
        startPreBuffering()

        Timber.d("Switched to channel: ${channel.name}")
    }

    private fun startPreBuffering() {
        preBufferJob?.cancel()
        preBufferJob = scope.launch {
            delay(PREBUFFER_DELAY_MS) // Small delay to let main player stabilize

            val adjacentChannels = getAdjacentChannels()
            val currentlyBuffered = mutableSetOf<String>()

            // Clean up players that are no longer adjacent
            val channelsToKeep = adjacentChannels.map { it.id }.toSet() +
                (activePlayer?.channelId?.let { setOf(it) } ?: emptySet())

            playerPool.keys.toList().forEach { channelId ->
                if (channelId !in channelsToKeep) {
                    Timber.d("Releasing non-adjacent buffer: $channelId")
                    playerPool.remove(channelId)?.release()
                }
            }

            // Pre-buffer adjacent channels
            for (channel in adjacentChannels) {
                if (playerPool.containsKey(channel.id)) {
                    if (playerPool[channel.id]?.isReady == true) {
                        currentlyBuffered.add(channel.id)
                    }
                    continue // Already buffering
                }

                val streamUrl = channel.streamUrl
                if (streamUrl.isNullOrBlank()) continue

                Timber.d("Pre-buffering channel: ${channel.name}")
                createPlayer(channel.id, streamUrl, isMain = false)

                // Small delay between starting buffers to avoid overwhelming network
                delay(100)
            }

            _preBufferedChannels.value = currentlyBuffered
            _instantSwitchReady.value = currentlyBuffered.isNotEmpty()
        }
    }

    private fun getAdjacentChannels(): List<Channel> {
        if (channels.isEmpty()) return emptyList()

        val adjacent = mutableListOf<Channel>()

        // Get channels above (channel up)
        for (i in 1..BUFFER_COUNT) {
            val index = (currentChannelIndex - i + channels.size) % channels.size
            if (index != currentChannelIndex) {
                adjacent.add(channels[index])
            }
        }

        // Get channels below (channel down)
        for (i in 1..BUFFER_COUNT) {
            val index = (currentChannelIndex + i) % channels.size
            if (index != currentChannelIndex) {
                adjacent.add(channels[index])
            }
        }

        return adjacent
    }

    private fun createPlayer(channelId: String, streamUrl: String, isMain: Boolean): BufferedPlayer {
        val trackSelector = DefaultTrackSelector(context).apply {
            setParameters(buildUponParameters()
                // Use lower quality for pre-buffer to save bandwidth
                .apply {
                    if (!isMain) {
                        setMaxVideoSizeSd()
                        setMaxVideoBitrate(2_000_000) // 2 Mbps max for buffer
                    }
                }
                .setPreferredAudioLanguage("en")
            )
        }

        val httpDataSourceFactory = DefaultHttpDataSource.Factory()
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(15_000)
            .setReadTimeoutMs(15_000)
            .setUserAgent("OpenFlix/1.0 (Android TV)")

        val mediaSourceFactory = DefaultMediaSourceFactory(context)
            .setDataSourceFactory(httpDataSourceFactory)

        val player = ExoPlayer.Builder(context)
            .setTrackSelector(trackSelector)
            .setMediaSourceFactory(mediaSourceFactory)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
                    .build(),
                isMain // Only handle audio focus for main player
            )
            .build()

        val bufferedPlayer = BufferedPlayer(
            channelId = channelId,
            player = player,
            streamUrl = streamUrl
        )

        // Set up listener
        player.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                when (playbackState) {
                    Player.STATE_READY -> {
                        bufferedPlayer.isReady = true
                        if (bufferedPlayer == activePlayer) {
                            _isBuffering.value = false
                            _isPlaying.value = true
                        }
                        // Update pre-buffered set
                        if (!isMain) {
                            _preBufferedChannels.value = _preBufferedChannels.value + channelId
                            _instantSwitchReady.value = true
                        }
                        Timber.d("Player ready: $channelId (main=$isMain)")
                    }
                    Player.STATE_BUFFERING -> {
                        if (bufferedPlayer == activePlayer) {
                            _isBuffering.value = true
                        }
                    }
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                Timber.e(error, "Player error for $channelId: ${error.errorCodeName}")
                if (bufferedPlayer == activePlayer) {
                    _error.value = error.message ?: error.errorCodeName
                }
                // Remove failed buffer
                if (!isMain) {
                    playerPool.remove(channelId)
                    bufferedPlayer.release()
                }
            }
        })

        // Determine MIME type
        val mimeType = when {
            streamUrl.contains(".m3u8", ignoreCase = true) -> MimeTypes.APPLICATION_M3U8
            streamUrl.contains(".ts", ignoreCase = true) -> MimeTypes.VIDEO_MP2T
            streamUrl.contains(".mpd", ignoreCase = true) -> MimeTypes.APPLICATION_MPD
            else -> null
        }

        val mediaItemBuilder = MediaItem.Builder()
            .setUri(streamUrl)
            .setLiveConfiguration(
                MediaItem.LiveConfiguration.Builder()
                    .setMaxPlaybackSpeed(1.02f)
                    .build()
            )

        if (mimeType != null) {
            mediaItemBuilder.setMimeType(mimeType)
        }

        player.setMediaItem(mediaItemBuilder.build())
        player.prepare()

        // Pre-buffer players start muted and paused after buffering
        if (!isMain) {
            player.volume = 0f
            player.playWhenReady = false
        } else {
            player.playWhenReady = true
        }

        playerPool[channelId] = bufferedPlayer
        return bufferedPlayer
    }

    fun toggleMute() {
        _isMuted.value = !_isMuted.value
        activePlayer?.player?.volume = if (_isMuted.value) 0f else 1f
    }

    fun setMuted(muted: Boolean) {
        _isMuted.value = muted
        activePlayer?.player?.volume = if (muted) 0f else 1f
    }

    fun pause() {
        activePlayer?.player?.pause()
        _isPlaying.value = false
    }

    fun resume() {
        activePlayer?.player?.play()
        _isPlaying.value = true
    }

    fun stop() {
        activePlayer?.player?.stop()
        _isPlaying.value = false
    }

    /**
     * Release all resources
     */
    fun release() {
        preBufferJob?.cancel()
        scope.cancel()

        playerPool.values.forEach { it.release() }
        playerPool.clear()
        activePlayer = null

        _isPlaying.value = false
        _isBuffering.value = false
        _preBufferedChannels.value = emptySet()
        _instantSwitchReady.value = false

        Timber.d("InstantSwitchManager released")
    }

    /**
     * Get stats for debugging
     */
    fun getStats(): InstantSwitchStats {
        return InstantSwitchStats(
            totalBufferedPlayers = playerPool.size,
            readyPlayers = playerPool.values.count { it.isReady },
            activeChannelId = activePlayer?.channelId,
            preBufferedChannelIds = playerPool.filter { it.value.isReady }.keys.toList()
        )
    }

    private inner class BufferedPlayer(
        val channelId: String,
        val player: ExoPlayer,
        val streamUrl: String,
        var isReady: Boolean = false
    ) {
        fun release() {
            player.release()
        }
    }
}

data class InstantSwitchStats(
    val totalBufferedPlayers: Int,
    val readyPlayers: Int,
    val activeChannelId: String?,
    val preBufferedChannelIds: List<String>
)
