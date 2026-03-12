package com.openflix.ui.player

import kotlinx.coroutines.flow.StateFlow

expect class PlatformPlayer {
    fun play(url: String, title: String = "", isLive: Boolean = false)
    fun pause()
    fun resume()
    fun stop()
    fun release()
    fun seekTo(positionMs: Long)
    fun seekRelative(deltaMs: Long)
    fun setSpeed(speed: Float)

    val isPlaying: StateFlow<Boolean>
    val isBuffering: StateFlow<Boolean>
    val position: StateFlow<Long>
    val duration: StateFlow<Long>
    val error: StateFlow<String?>
    val videoResolution: StateFlow<String>
}
