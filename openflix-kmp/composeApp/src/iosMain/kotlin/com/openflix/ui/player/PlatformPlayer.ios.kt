package com.openflix.ui.player

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.useContents
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import platform.AVFAudio.AVAudioSession
import platform.AVFAudio.AVAudioSessionCategoryPlayback
import platform.AVFAudio.AVAudioSessionModeMoviePlayback
import platform.AVFAudio.setActive
import platform.AVFoundation.*
import platform.CoreMedia.CMTimeMakeWithSeconds
import platform.CoreMedia.CMTimeGetSeconds
import platform.Foundation.*

@OptIn(ExperimentalForeignApi::class)
actual class PlatformPlayer {
    internal var avPlayer: AVPlayer? = null
    private var timeObserver: Any? = null
    private var statusObservation: Any? = null

    private val _isPlaying = MutableStateFlow(false)
    actual val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _isBuffering = MutableStateFlow(false)
    actual val isBuffering: StateFlow<Boolean> = _isBuffering.asStateFlow()

    private val _position = MutableStateFlow(0L)
    actual val position: StateFlow<Long> = _position.asStateFlow()

    private val _duration = MutableStateFlow(0L)
    actual val duration: StateFlow<Long> = _duration.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    actual val error: StateFlow<String?> = _error.asStateFlow()

    private val _videoResolution = MutableStateFlow("")
    actual val videoResolution: StateFlow<String> = _videoResolution.asStateFlow()

    private fun configureAudioSession() {
        try {
            val session = AVAudioSession.sharedInstance()
            session.setCategory(AVAudioSessionCategoryPlayback, AVAudioSessionModeMoviePlayback, options = 0u, error = null)
            session.setActive(true, null)
        } catch (e: Exception) {
            println("Failed to configure audio session: ${e.message}")
        }
    }

    private var lastIsLive = false

    actual fun play(url: String, title: String, isLive: Boolean) {
        _error.value = null
        _isBuffering.value = true
        release()

        lastIsLive = isLive
        if (isLive) {
            NativeLiveTVPlayer.present(url, title)
        } else {
            NativeVideoPlayer.present(url, title)
        }
        _isPlaying.value = true
        _isBuffering.value = false
    }

    actual fun pause() {
        avPlayer?.pause()
        _isPlaying.value = false
    }

    actual fun resume() {
        avPlayer?.play()
        _isPlaying.value = true
    }

    actual fun stop() {
        avPlayer?.pause()
        if (lastIsLive) NativeLiveTVPlayer.dismiss() else NativeVideoPlayer.dismiss()
        _isPlaying.value = false
    }

    actual fun release() {
        timeObserver?.let { observer ->
            avPlayer?.removeTimeObserver(observer)
        }
        timeObserver = null
        avPlayer?.pause()
        avPlayer = null
        if (lastIsLive) NativeLiveTVPlayer.dismiss() else NativeVideoPlayer.dismiss()
        _isPlaying.value = false
        _isBuffering.value = false
        _position.value = 0L
        _duration.value = 0L
        _videoResolution.value = ""
    }

    actual fun seekTo(positionMs: Long) {
        val time = CMTimeMakeWithSeconds(positionMs.toDouble() / 1000.0, 600)
        avPlayer?.seekToTime(time)
    }

    actual fun seekRelative(deltaMs: Long) {
        val currentMs = _position.value
        val newMs = (currentMs + deltaMs).coerceAtLeast(0)
        seekTo(newMs)
    }

    actual fun setSpeed(speed: Float) {
        avPlayer?.rate = speed
        if (speed > 0f) _isPlaying.value = true
    }
}
