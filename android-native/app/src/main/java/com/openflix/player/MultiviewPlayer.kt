package com.openflix.player

import android.content.Context
import android.view.SurfaceView
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import timber.log.Timber

/**
 * Lightweight ExoPlayer-based player for multiview slots.
 * Uses ExoPlayer instead of mpv for better multi-instance performance.
 */
@OptIn(UnstableApi::class)
class MultiviewPlayer(
    private val context: Context
) {
    private var exoPlayer: ExoPlayer? = null

    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _isBuffering = MutableStateFlow(false)
    val isBuffering: StateFlow<Boolean> = _isBuffering.asStateFlow()

    private val _isMuted = MutableStateFlow(true) // Muted by default in multiview
    val isMuted: StateFlow<Boolean> = _isMuted.asStateFlow()

    private val _isPaused = MutableStateFlow(false)
    val isPaused: StateFlow<Boolean> = _isPaused.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    // For calculating live offset
    val currentPositionMs: Long
        get() = exoPlayer?.currentPosition ?: 0L

    val durationMs: Long
        get() = exoPlayer?.duration ?: 0L

    val isLive: Boolean
        get() {
            val player = exoPlayer ?: return true
            val duration = player.duration
            val position = player.currentPosition
            // Consider live if within 10 seconds of duration
            return duration <= 0 || (duration - position) < 10_000
        }

    private val playerListener = object : Player.Listener {
        override fun onPlaybackStateChanged(playbackState: Int) {
            when (playbackState) {
                Player.STATE_IDLE -> {
                    _isPlaying.value = false
                    _isBuffering.value = false
                }
                Player.STATE_BUFFERING -> {
                    _isBuffering.value = true
                }
                Player.STATE_READY -> {
                    _isPlaying.value = true
                    _isBuffering.value = false
                }
                Player.STATE_ENDED -> {
                    _isPlaying.value = false
                    _isBuffering.value = false
                }
            }
        }

        override fun onPlayerError(error: PlaybackException) {
            Timber.e(error, "MultiviewPlayer error")
            _error.value = error.message
            _isPlaying.value = false
            _isBuffering.value = false
        }
    }

    fun initialize() {
        if (exoPlayer != null) return

        exoPlayer = ExoPlayer.Builder(context)
            .setMediaSourceFactory(DefaultMediaSourceFactory(context))
            .build()
            .apply {
                addListener(playerListener)
                playWhenReady = true
                volume = 0f // Start muted
            }

        Timber.d("MultiviewPlayer initialized")
    }

    fun setSurfaceView(surfaceView: SurfaceView) {
        exoPlayer?.setVideoSurfaceView(surfaceView)
    }

    fun play(url: String) {
        val player = exoPlayer ?: return
        _error.value = null
        _isBuffering.value = true

        try {
            val mediaItem = MediaItem.fromUri(url)
            player.setMediaItem(mediaItem)
            player.prepare()
            player.play()
            Timber.d("MultiviewPlayer playing: $url")
        } catch (e: Exception) {
            Timber.e(e, "Failed to play in MultiviewPlayer")
            _error.value = e.message
        }
    }

    fun stop() {
        exoPlayer?.stop()
        _isPlaying.value = false
    }

    fun toggleMute() {
        val player = exoPlayer ?: return
        val newMuted = !_isMuted.value
        _isMuted.value = newMuted
        player.volume = if (newMuted) 0f else 1f
    }

    fun setMuted(muted: Boolean) {
        val player = exoPlayer ?: return
        _isMuted.value = muted
        player.volume = if (muted) 0f else 1f
    }

    // DVR Controls - Key differentiator vs Channels DVR!
    fun pause() {
        val player = exoPlayer ?: return
        player.pause()
        _isPaused.value = true
        Timber.d("MultiviewPlayer paused")
    }

    fun resume() {
        val player = exoPlayer ?: return
        player.play()
        _isPaused.value = false
        Timber.d("MultiviewPlayer resumed")
    }

    fun togglePause() {
        if (_isPaused.value) resume() else pause()
    }

    fun seekBack(seconds: Int = 15) {
        val player = exoPlayer ?: return
        val newPosition = (player.currentPosition - (seconds * 1000L)).coerceAtLeast(0)
        player.seekTo(newPosition)
        Timber.d("MultiviewPlayer seeked back $seconds seconds")
    }

    fun seekForward(seconds: Int = 15) {
        val player = exoPlayer ?: return
        val newPosition = player.currentPosition + (seconds * 1000L)
        val duration = player.duration
        if (duration > 0) {
            player.seekTo(newPosition.coerceAtMost(duration))
        } else {
            player.seekTo(newPosition)
        }
        Timber.d("MultiviewPlayer seeked forward $seconds seconds")
    }

    fun seekToLive() {
        val player = exoPlayer ?: return
        val duration = player.duration
        if (duration > 0) {
            player.seekTo(duration)
        }
        player.play()
        _isPaused.value = false
        Timber.d("MultiviewPlayer jumped to live")
    }

    fun release() {
        exoPlayer?.removeListener(playerListener)
        exoPlayer?.release()
        exoPlayer = null
        Timber.d("MultiviewPlayer released")
    }
}
