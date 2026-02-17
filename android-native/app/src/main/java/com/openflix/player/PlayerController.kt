package com.openflix.player

import com.openflix.domain.model.Chapter
import com.openflix.domain.model.IntroMarker
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * High-level controller for video playback.
 * Wraps MpvPlayer and adds features like progress tracking, skip intro, etc.
 */
@Singleton
class PlayerController @Inject constructor(
    private val mpvPlayer: MpvPlayer
) {
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Playback state
    val isPlaying: StateFlow<Boolean> = mpvPlayer.isPlaying
    val position: StateFlow<Long> = mpvPlayer.position
    val duration: StateFlow<Long> = mpvPlayer.duration
    val bufferedPosition: StateFlow<Long> = mpvPlayer.bufferedPosition
    val playerState: StateFlow<PlayerState> = mpvPlayer.playerState
    val tracks: StateFlow<PlayerTracks> = mpvPlayer.tracks

    // Additional state
    private val _currentMediaId = MutableStateFlow<String?>(null)
    val currentMediaId: StateFlow<String?> = _currentMediaId.asStateFlow()

    private val _chapters = MutableStateFlow<List<Chapter>>(emptyList())
    val chapters: StateFlow<List<Chapter>> = _chapters.asStateFlow()

    private val _introMarker = MutableStateFlow<IntroMarker?>(null)
    val introMarker: StateFlow<IntroMarker?> = _introMarker.asStateFlow()

    private val _creditsMarker = MutableStateFlow<IntroMarker?>(null)
    val creditsMarker: StateFlow<IntroMarker?> = _creditsMarker.asStateFlow()

    private val _showSkipIntro = MutableStateFlow(false)
    val showSkipIntro: StateFlow<Boolean> = _showSkipIntro.asStateFlow()

    private val _showSkipCredits = MutableStateFlow(false)
    val showSkipCredits: StateFlow<Boolean> = _showSkipCredits.asStateFlow()

    // Sleep timer
    private var sleepTimerJob: Job? = null
    private val _sleepTimerRemaining = MutableStateFlow<Long?>(null)
    val sleepTimerRemaining: StateFlow<Long?> = _sleepTimerRemaining.asStateFlow()

    // Progress callback
    private var onProgressUpdate: ((mediaId: String, positionMs: Long, durationMs: Long) -> Unit)? = null

    init {
        // Monitor position for skip intro/credits buttons
        scope.launch {
            position.collect { pos ->
                checkIntroCreditsMarkers(pos)
            }
        }

        // Periodic progress updates
        scope.launch {
            while (true) {
                delay(10_000) // Every 10 seconds
                if (isPlaying.value) {
                    val mediaId = _currentMediaId.value
                    val pos = position.value
                    val dur = duration.value
                    if (mediaId != null && pos > 0) {
                        onProgressUpdate?.invoke(mediaId, pos, dur)
                    }
                }
            }
        }
    }

    /**
     * Play media with the given URL.
     * Waits for surface to be attached before starting playback.
     */
    fun playMedia(
        mediaId: String,
        url: String,
        startPosition: Long = 0,
        chapters: List<Chapter> = emptyList(),
        introMarker: IntroMarker? = null,
        creditsMarker: IntroMarker? = null
    ) {
        _currentMediaId.value = mediaId
        _chapters.value = chapters
        _introMarker.value = introMarker
        _creditsMarker.value = creditsMarker

        // Wait for surface to be attached before playing
        scope.launch {
            var attempts = 0
            while (!mpvPlayer.isSurfaceAttached && attempts < 100) {
                delay(50)
                attempts++
            }
            if (mpvPlayer.isSurfaceAttached) {
                mpvPlayer.play(url, startPosition)
                Timber.d("Playing media: $mediaId at position $startPosition")
            } else {
                Timber.e("Surface not attached after 5s, cannot play media: $mediaId")
            }
        }
    }

    /**
     * Resume playback
     */
    fun play() {
        mpvPlayer.resume()
    }

    /**
     * Pause playback
     */
    fun pause() {
        mpvPlayer.pause()
    }

    /**
     * Toggle play/pause
     */
    fun togglePlayPause() {
        mpvPlayer.togglePlayPause()
    }

    /**
     * Stop playback
     */
    fun stop() {
        mpvPlayer.stop()
        _currentMediaId.value = null
        _chapters.value = emptyList()
        _introMarker.value = null
        _creditsMarker.value = null
        cancelSleepTimer()
    }

    /**
     * Seek to position in milliseconds
     */
    fun seekTo(positionMs: Long) {
        mpvPlayer.seekTo(positionMs)
    }

    /**
     * Seek forward by seconds
     */
    fun seekForward(seconds: Int) {
        mpvPlayer.seekRelative(seconds)
    }

    /**
     * Seek backward by seconds
     */
    fun seekBackward(seconds: Int) {
        mpvPlayer.seekRelative(-seconds)
    }

    /**
     * Skip to intro end
     */
    fun skipIntro() {
        val intro = _introMarker.value ?: return
        mpvPlayer.seekTo(intro.end)
        _showSkipIntro.value = false
    }

    /**
     * Skip to credits end (usually triggers next episode)
     */
    fun skipCredits() {
        val credits = _creditsMarker.value ?: return
        mpvPlayer.seekTo(credits.end)
        _showSkipCredits.value = false
    }

    /**
     * Jump to chapter
     */
    fun seekToChapter(chapter: Chapter) {
        mpvPlayer.seekTo(chapter.startTime)
    }

    /**
     * Set playback speed
     */
    fun setPlaybackSpeed(speed: Float) {
        mpvPlayer.setPlaybackSpeed(speed)
    }

    /**
     * Set volume (0-100)
     */
    fun setVolume(volume: Int) {
        mpvPlayer.setVolume(volume)
    }

    /**
     * Toggle mute
     */
    fun toggleMute() {
        mpvPlayer.toggleMute()
    }

    /**
     * Select audio track
     */
    fun selectAudioTrack(trackId: Int) {
        mpvPlayer.setAudioTrack(trackId)
    }

    /**
     * Select subtitle track (0 to disable)
     */
    fun selectSubtitleTrack(trackId: Int) {
        mpvPlayer.setSubtitleTrack(trackId)
    }

    /**
     * Set subtitle delay in seconds
     */
    fun setSubtitleDelay(seconds: Double) {
        mpvPlayer.setSubtitleDelay(seconds)
    }

    /**
     * Set audio delay in seconds
     */
    fun setAudioDelay(seconds: Double) {
        mpvPlayer.setAudioDelay(seconds)
    }

    /**
     * Set aspect ratio
     */
    fun setAspectRatio(ratio: AspectRatio) {
        mpvPlayer.setAspectRatio(ratio.value)
    }

    /**
     * Start sleep timer (minutes)
     */
    fun startSleepTimer(minutes: Int) {
        cancelSleepTimer()

        val endTime = System.currentTimeMillis() + (minutes * 60 * 1000)

        sleepTimerJob = scope.launch {
            while (true) {
                val remaining = endTime - System.currentTimeMillis()
                if (remaining <= 0) {
                    pause()
                    _sleepTimerRemaining.value = null
                    break
                }
                _sleepTimerRemaining.value = remaining
                delay(1000)
            }
        }

        Timber.d("Sleep timer started: $minutes minutes")
    }

    /**
     * Cancel sleep timer
     */
    fun cancelSleepTimer() {
        sleepTimerJob?.cancel()
        sleepTimerJob = null
        _sleepTimerRemaining.value = null
    }

    /**
     * Set progress update callback
     */
    fun setProgressCallback(callback: (mediaId: String, positionMs: Long, durationMs: Long) -> Unit) {
        onProgressUpdate = callback
    }

    /**
     * Get current chapter based on position
     */
    fun getCurrentChapter(): Chapter? {
        val pos = position.value
        return chapters.value.findLast { it.startTime <= pos }
    }

    private fun checkIntroCreditsMarkers(positionMs: Long) {
        // Check intro marker
        val intro = _introMarker.value
        _showSkipIntro.value = intro != null &&
                positionMs >= intro.start &&
                positionMs < intro.end

        // Check credits marker
        val credits = _creditsMarker.value
        _showSkipCredits.value = credits != null &&
                positionMs >= credits.start &&
                positionMs < credits.end
    }

    fun release() {
        scope.cancel()
        mpvPlayer.release()
    }
}

enum class AspectRatio(val value: String, val displayName: String) {
    AUTO("-1", "Auto"),
    RATIO_16_9("16:9", "16:9"),
    RATIO_4_3("4:3", "4:3"),
    RATIO_21_9("21:9", "21:9"),
    FILL("100:100", "Fill"),
    ORIGINAL("-2", "Original")
}
