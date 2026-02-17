package com.openflix.player

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.SurfaceHolder
import android.view.SurfaceView
import com.openflix.data.repository.SettingsRepository
import dev.jdtech.mpv.MPVLib
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Wrapper around mpv (libmpv) video player.
 */
@Singleton
class MpvPlayer @Inject constructor(
    private val context: Context,
    private val settingsRepository: SettingsRepository
) : MPVLib.EventObserver {

    private var _initialized = false
    val isInitialized: Boolean get() = _initialized
    private var _surfaceAttached = false
    val isSurfaceAttached: Boolean get() = _surfaceAttached

    // Player state
    private val _playerState = MutableStateFlow(PlayerState())
    val playerState: StateFlow<PlayerState> = _playerState.asStateFlow()

    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _position = MutableStateFlow(0L)
    val position: StateFlow<Long> = _position.asStateFlow()

    private val _duration = MutableStateFlow(0L)
    val duration: StateFlow<Long> = _duration.asStateFlow()

    private val _bufferedPosition = MutableStateFlow(0L)
    val bufferedPosition: StateFlow<Long> = _bufferedPosition.asStateFlow()

    private val _tracks = MutableStateFlow(PlayerTracks())
    val tracks: StateFlow<PlayerTracks> = _tracks.asStateFlow()

    /**
     * Initialize the mpv player with default options.
     * Matches the approach used in the working Flutter app.
     */
    fun initialize() {
        if (_initialized) return

        try {
            // Read settings synchronously at init time
            val videoQuality = runBlocking { settingsRepository.videoQuality.first() }
            val sharpening = runBlocking { settingsRepository.sharpening.first() }
            val debandEnabled = runBlocking { settingsRepository.debandEnabled.first() }
            val audioUpmix = runBlocking { settingsRepository.audioUpmix.first() }
            val hardwareDecoding = runBlocking { settingsRepository.hardwareDecoding.first() }

            Timber.d("Initializing mpv with settings: quality=$videoQuality, sharpening=$sharpening, deband=$debandEnabled, audioUpmix=$audioUpmix, hwdec=$hardwareDecoding")

            Timber.d("Creating mpv context...")
            // Use applicationContext like Flutter does
            MPVLib.create(context.applicationContext)

            // Core options - same as Flutter
            Timber.d("Setting mpv options...")
            MPVLib.setOptionString("vo", "gpu")
            MPVLib.setOptionString("gpu-context", "android")
            MPVLib.setOptionString("ao", "audiotrack")

            // Audio upmixing - upscale stereo to 5.1 surround (if enabled)
            if (audioUpmix) {
                MPVLib.setOptionString("audio-channels", "5.1")  // Force 5.1 output (upmix stereo)
                MPVLib.setOptionString("audio-normalize-downmix", "yes")  // Normalize volume levels
                Timber.d("Audio upmix to 5.1 enabled")
            } else {
                MPVLib.setOptionString("audio-channels", "auto-safe")
                Timber.d("Audio upmix disabled - using native channels")
            }

            // Enable hardware decoding for smooth playback
            if (hardwareDecoding) {
                // Use "auto" instead of "auto-safe" for better codec support
                MPVLib.setOptionString("hwdec", "auto")
                // Allow copy-back if needed for compatibility
                MPVLib.setOptionString("hwdec-codecs", "all")
            } else {
                MPVLib.setOptionString("hwdec", "no")
            }

            // Detect device capability for performance tuning
            val model = android.os.Build.MODEL.uppercase()
            val manufacturer = android.os.Build.MANUFACTURER.uppercase()

            val isHighEndDevice = model.contains("SHIELD") ||
                    manufacturer.contains("NVIDIA") ||
                    model.contains("CHROMECAST") ||
                    model.contains("APPLE TV") ||
                    model.contains("FIRE TV CUBE")  // Fire TV Cube is powerful

            // Budget devices that need aggressive optimization
            val isBudgetDevice = model.contains("RT_G2") ||
                    model.contains("RT-G2") ||  // Also check with hyphen
                    model.contains("SEI") ||  // Many budget SEI boxes
                    model.contains("YYJ") ||  // YYJ chipset boxes
                    manufacturer.contains("AMLOGIC") ||
                    model.contains("MECOOL") ||
                    model.contains("X96") ||
                    model.contains("T95") ||
                    model.contains("H96")

            Timber.d("Device detection: model=$model, manufacturer=$manufacturer, isHighEnd=$isHighEndDevice, isBudget=$isBudgetDevice")

            // Determine effective quality mode
            // Budget devices ALWAYS use fast mode, regardless of settings
            val effectiveQuality = when {
                isBudgetDevice -> "fast"  // Force fast on budget devices
                videoQuality == "high" -> if (isHighEndDevice) "high" else "fast"
                videoQuality == "fast" -> "fast"
                else -> if (isHighEndDevice) "high" else "fast"  // "auto" mode
            }

            Timber.d("Effective quality: $effectiveQuality (setting=$videoQuality)")

            if (effectiveQuality == "high") {
                // High-quality upscaling for powerful devices (Shield TV, etc.)
                MPVLib.setOptionString("scale", "ewa_lanczossharp")
                MPVLib.setOptionString("cscale", "ewa_lanczossharp")
                MPVLib.setOptionString("dscale", "mitchell")
                MPVLib.setOptionString("correct-downscaling", "yes")
                MPVLib.setOptionString("linear-downscaling", "yes")
                MPVLib.setOptionString("sigmoid-upscaling", "yes")

                // Apply sharpening from settings
                MPVLib.setOptionString("sharpen", sharpening.toString())
                Timber.d("Sharpening set to: $sharpening")

                // Apply deband from settings
                if (debandEnabled) {
                    MPVLib.setOptionString("deband", "yes")
                    MPVLib.setOptionString("deband-iterations", "2")
                    MPVLib.setOptionString("deband-threshold", "35")
                    MPVLib.setOptionString("deband-range", "20")
                    MPVLib.setOptionString("deband-grain", "5")
                    Timber.d("Deband filter enabled")
                } else {
                    MPVLib.setOptionString("deband", "no")
                    Timber.d("Deband filter disabled")
                }
            } else {
                // Fast mode for budget devices - prioritize smooth playback
                MPVLib.setOptionString("profile", "fast")
                MPVLib.setOptionString("scale", "bilinear")
                MPVLib.setOptionString("cscale", "bilinear")
                MPVLib.setOptionString("dscale", "bilinear")
                MPVLib.setOptionString("deband", "no")
                MPVLib.setOptionString("sharpen", "0")

                // Extra optimizations for budget devices
                if (isBudgetDevice) {
                    MPVLib.setOptionString("vd-lavc-threads", "4")  // Limit decoder threads
                    MPVLib.setOptionString("video-output-levels", "limited")
                    MPVLib.setOptionString("opengl-pbo", "no")  // Disable PBO for stability
                    MPVLib.setOptionString("gpu-dumb-mode", "yes")  // Simplest GPU path
                    MPVLib.setOptionString("fbo-format", "rgba8")  // Simple FBO format
                    // Force mediacodec with copy-back for stability
                    MPVLib.setOptionString("hwdec", "mediacodec-copy")
                    Timber.d("Using aggressive fast profile for budget device")
                } else {
                    Timber.d("Using fast profile for smooth playback")
                }
            }

            // HLS/Live streaming optimizations - tuned for device capability
            if (isBudgetDevice) {
                // Budget devices: smaller buffers to reduce memory pressure
                MPVLib.setOptionString("demuxer-max-bytes", "50MiB")
                MPVLib.setOptionString("demuxer-max-back-bytes", "25MiB")
                MPVLib.setOptionString("cache-secs", "15")  // 15 seconds cache
                MPVLib.setOptionString("stream-buffer-size", "2MiB")
                MPVLib.setOptionString("hls-bitrate", "no")  // Let HLS adaptive choose
            } else {
                // High-end devices: larger buffers
                MPVLib.setOptionString("demuxer-max-bytes", "150MiB")
                MPVLib.setOptionString("demuxer-max-back-bytes", "75MiB")
                MPVLib.setOptionString("cache-secs", "30")  // 30 seconds of cache
                MPVLib.setOptionString("stream-buffer-size", "4MiB")
                MPVLib.setOptionString("hls-bitrate", "max")
            }
            MPVLib.setOptionString("cache", "yes")
            MPVLib.setOptionString("cache-pause-wait", "3")  // Wait 3 secs before pausing on underrun

            // Network/stream tuning for slow providers
            MPVLib.setOptionString("network-timeout", "30")  // 30 second timeout

            // Audio buffer to prevent underruns - critical for budget devices
            MPVLib.setOptionString("audio-buffer", "1.0")  // 1 second audio buffer
            MPVLib.setOptionString("audio-wait-open", "0.5")  // Wait for audio device

            // GPU render queue for smooth playback
            MPVLib.setOptionString("swapchain-depth", "3")  // Render ahead for smooth frames

            // Sync options - tolerate A/V desync on slow devices
            MPVLib.setOptionString("video-sync", "audio")  // Sync video to audio
            MPVLib.setOptionString("video-latency-hacks", "yes")  // Reduce latency
            MPVLib.setOptionString("interpolation", "no")  // Disable for performance
            MPVLib.setOptionString("framedrop", "vo")  // Drop frames at display level if needed

            Timber.d("HLS streaming options configured")

            // Initialize mpv
            Timber.d("Calling MPVLib.init()...")
            MPVLib.init()

            // Register observer AFTER init
            MPVLib.addObserver(this)

            // Observe properties for position/duration updates
            MPVLib.observeProperty("time-pos", MPVLib.MPV_FORMAT_DOUBLE)
            MPVLib.observeProperty("duration", MPVLib.MPV_FORMAT_DOUBLE)
            MPVLib.observeProperty("pause", MPVLib.MPV_FORMAT_FLAG)
            MPVLib.observeProperty("mute", MPVLib.MPV_FORMAT_FLAG)

            _initialized = true
            Timber.d("mpv player initialized successfully")
        } catch (e: Exception) {
            Timber.e(e, "Failed to initialize mpv player")
            _playerState.value = _playerState.value.copy(
                loadState = LoadState.ERROR,
                error = "Failed to init mpv: ${e.message}"
            )
        }
    }

    /**
     * Attach a SurfaceView for video rendering
     */
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingSurfaceHolder: SurfaceHolder? = null

    fun attachSurface(surfaceView: SurfaceView) {
        surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) {
                Timber.d("surfaceCreated called, initialized=$_initialized")
                if (!_initialized) {
                    // Store the holder and retry after a delay
                    pendingSurfaceHolder = holder
                    retryAttachSurface(holder, 0)
                    return
                }
                doAttachSurface(holder)
            }

            private fun retryAttachSurface(holder: SurfaceHolder, attempt: Int) {
                if (attempt >= 100) { // 5 seconds max
                    Timber.e("Cannot attach surface - mpv not initialized after 5s")
                    return
                }
                mainHandler.postDelayed({
                    if (_initialized) {
                        doAttachSurface(holder)
                    } else {
                        retryAttachSurface(holder, attempt + 1)
                    }
                }, 50)
            }

            private fun doAttachSurface(holder: SurfaceHolder) {
                try {
                    MPVLib.attachSurface(holder.surface)
                    MPVLib.setOptionString("force-window", "yes")
                    _surfaceAttached = true
                    pendingSurfaceHolder = null
                    Timber.d("Surface attached successfully")
                } catch (e: Exception) {
                    Timber.e(e, "Failed to attach surface")
                }
            }

            override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
                if (_initialized && _surfaceAttached) {
                    try {
                        MPVLib.setPropertyString("android-surface-size", "${width}x${height}")
                    } catch (e: Exception) {
                        Timber.e(e, "Failed to set surface size")
                    }
                }
            }

            override fun surfaceDestroyed(holder: SurfaceHolder) {
                if (_surfaceAttached) {
                    try {
                        MPVLib.setOptionString("force-window", "no")
                        MPVLib.detachSurface()
                        _surfaceAttached = false
                        Timber.d("Surface detached")
                    } catch (e: Exception) {
                        Timber.e(e, "Failed to detach surface")
                    }
                }
            }
        })
    }

    /**
     * Load and play a media file/URL
     */
    fun play(url: String, startPosition: Long = 0) {
        if (!_initialized) {
            Timber.e("Cannot play - mpv not initialized")
            _playerState.value = _playerState.value.copy(
                loadState = LoadState.ERROR,
                error = "Player not initialized"
            )
            return
        }

        try {
            Timber.d("Loading media: $url")
            MPVLib.command(arrayOf("loadfile", url))

            if (startPosition > 0) {
                MPVLib.setPropertyDouble("time-pos", startPosition / 1000.0)
            }

            _playerState.value = _playerState.value.copy(
                loadState = LoadState.LOADING,
                currentUrl = url
            )
        } catch (e: Exception) {
            Timber.e(e, "Failed to play: $url")
            _playerState.value = _playerState.value.copy(
                loadState = LoadState.ERROR,
                error = e.message
            )
        }
    }

    fun resume() {
        if (_initialized) MPVLib.setPropertyBoolean("pause", false)
    }

    fun pause() {
        if (_initialized) MPVLib.setPropertyBoolean("pause", true)
    }

    fun togglePlayPause() {
        if (!_initialized) return
        val paused = MPVLib.getPropertyBoolean("pause") ?: true
        MPVLib.setPropertyBoolean("pause", !paused)
    }

    fun stop() {
        if (_initialized) MPVLib.command(arrayOf("stop"))
        _playerState.value = PlayerState()
    }

    fun seekTo(positionMs: Long) {
        if (_initialized) MPVLib.setPropertyDouble("time-pos", positionMs / 1000.0)
    }

    fun seekRelative(seconds: Int) {
        if (_initialized) MPVLib.command(arrayOf("seek", seconds.toString(), "relative"))
    }

    fun setPlaybackSpeed(speed: Float) {
        if (_initialized) {
            val clampedSpeed = speed.coerceIn(0.5f, 3.0f)
            MPVLib.setPropertyDouble("speed", clampedSpeed.toDouble())
            _playerState.value = _playerState.value.copy(playbackSpeed = clampedSpeed)
        }
    }

    fun setVolume(volume: Int) {
        if (_initialized) {
            val clampedVolume = volume.coerceIn(0, 100)
            MPVLib.setPropertyInt("volume", clampedVolume)
            _playerState.value = _playerState.value.copy(volume = clampedVolume)
        }
    }

    fun toggleMute() {
        if (!_initialized) return
        val muted = MPVLib.getPropertyBoolean("mute") ?: false
        MPVLib.setPropertyBoolean("mute", !muted)
        _playerState.value = _playerState.value.copy(isMuted = !muted)
    }

    fun setMuted(muted: Boolean) {
        if (!_initialized) return
        MPVLib.setPropertyBoolean("mute", muted)
        _playerState.value = _playerState.value.copy(isMuted = muted)
    }

    fun setAudioTrack(trackId: Int) {
        if (_initialized) {
            MPVLib.setPropertyInt("aid", trackId)
            refreshTracks()
        }
    }

    fun setSubtitleTrack(trackId: Int) {
        if (_initialized) {
            MPVLib.setPropertyInt("sid", trackId)
            refreshTracks()
        }
    }

    /**
     * Cycle to the next audio track
     * Returns the new track info (id, name) or null if no tracks
     */
    fun cycleAudioTrack(): Track? {
        if (!_initialized) return null

        refreshTracks()
        val currentTracks = _tracks.value.audioTracks
        if (currentTracks.isEmpty()) return null

        val currentId = MPVLib.getPropertyInt("aid") ?: 1
        val currentIndex = currentTracks.indexOfFirst { it.id == currentId }
        val nextIndex = (currentIndex + 1) % currentTracks.size
        val nextTrack = currentTracks[nextIndex]

        setAudioTrack(nextTrack.id)
        Timber.d("Cycled audio track to: ${nextTrack.title} (id=${nextTrack.id})")
        return nextTrack
    }

    /**
     * Cycle to the next subtitle track (including "Off")
     * Returns the new track info or null for off
     */
    fun cycleSubtitleTrack(): Track? {
        if (!_initialized) return null

        refreshTracks()
        val currentTracks = _tracks.value.subtitleTracks
        val currentId = MPVLib.getPropertyInt("sid") ?: 0

        // Create list with "Off" option (id=0)
        val offTrack = Track(id = 0, title = "Off", language = "", selected = currentId == 0)
        val allOptions = listOf(offTrack) + currentTracks

        val currentIndex = allOptions.indexOfFirst { it.id == currentId }.takeIf { it >= 0 } ?: 0
        val nextIndex = (currentIndex + 1) % allOptions.size
        val nextTrack = allOptions[nextIndex]

        MPVLib.setPropertyInt("sid", nextTrack.id)
        refreshTracks()

        Timber.d("Cycled subtitle track to: ${nextTrack.title} (id=${nextTrack.id})")
        return if (nextTrack.id == 0) null else nextTrack
    }

    /**
     * Get current audio track info
     */
    fun getCurrentAudioTrack(): Track? {
        if (!_initialized) return null
        refreshTracks()
        val currentId = MPVLib.getPropertyInt("aid") ?: return null
        return _tracks.value.audioTracks.find { it.id == currentId }
    }

    /**
     * Get current subtitle track info (null = off)
     */
    fun getCurrentSubtitleTrack(): Track? {
        if (!_initialized) return null
        refreshTracks()
        val currentId = MPVLib.getPropertyInt("sid") ?: return null
        if (currentId == 0) return null
        return _tracks.value.subtitleTracks.find { it.id == currentId }
    }

    /**
     * Refresh track list from mpv
     */
    fun refreshTracks() {
        if (!_initialized) return

        try {
            val trackCount = MPVLib.getPropertyInt("track-list/count") ?: 0
            val audioTracks = mutableListOf<Track>()
            val subtitleTracks = mutableListOf<Track>()

            val currentAid = MPVLib.getPropertyInt("aid") ?: 0
            val currentSid = MPVLib.getPropertyInt("sid") ?: 0

            for (i in 0 until trackCount) {
                val type = MPVLib.getPropertyString("track-list/$i/type") ?: continue
                val id = MPVLib.getPropertyInt("track-list/$i/id") ?: continue
                val title = MPVLib.getPropertyString("track-list/$i/title") ?: ""
                val lang = MPVLib.getPropertyString("track-list/$i/lang") ?: ""

                val displayName = when {
                    title.isNotBlank() -> title
                    lang.isNotBlank() -> lang.uppercase()
                    else -> "Track $id"
                }

                when (type) {
                    "audio" -> audioTracks.add(Track(
                        id = id,
                        title = displayName,
                        language = lang,
                        selected = id == currentAid
                    ))
                    "sub" -> subtitleTracks.add(Track(
                        id = id,
                        title = displayName,
                        language = lang,
                        selected = id == currentSid
                    ))
                }
            }

            _tracks.value = PlayerTracks(
                audioTracks = audioTracks,
                subtitleTracks = subtitleTracks
            )

            Timber.d("Refreshed tracks: ${audioTracks.size} audio, ${subtitleTracks.size} subtitle")
        } catch (e: Exception) {
            Timber.e(e, "Failed to refresh tracks")
        }
    }

    fun setSubtitleDelay(seconds: Double) {
        if (_initialized) MPVLib.setPropertyDouble("sub-delay", seconds)
    }

    fun setAudioDelay(seconds: Double) {
        if (_initialized) MPVLib.setPropertyDouble("audio-delay", seconds)
    }

    fun setAspectRatio(ratio: String) {
        if (_initialized) MPVLib.setPropertyString("video-aspect-override", ratio)
    }

    /**
     * Update sharpening at runtime
     */
    fun setSharpening(value: Float) {
        if (_initialized) {
            val clamped = value.coerceIn(0f, 1f)
            MPVLib.setPropertyString("sharpen", clamped.toString())
            Timber.d("Sharpening updated to: $clamped")
        }
    }

    /**
     * Update deband filter at runtime
     */
    fun setDebandEnabled(enabled: Boolean) {
        if (_initialized) {
            MPVLib.setPropertyString("deband", if (enabled) "yes" else "no")
            Timber.d("Deband ${if (enabled) "enabled" else "disabled"}")
        }
    }

    fun release() {
        if (_initialized) {
            try {
                MPVLib.removeObserver(this)
                MPVLib.destroy()
            } catch (e: Exception) {
                Timber.e(e, "Error releasing mpv")
            }
            _initialized = false
            _surfaceAttached = false
            Timber.d("mpv player released")
        }
    }

    // MPVLib.EventObserver implementation
    override fun eventProperty(property: String) {}

    override fun eventProperty(property: String, value: Long) {
        when (property) {
            "time-pos" -> _position.value = value * 1000
            "duration" -> _duration.value = value * 1000
        }
    }

    override fun eventProperty(property: String, value: Double) {
        when (property) {
            "time-pos" -> _position.value = (value * 1000).toLong()
            "duration" -> _duration.value = (value * 1000).toLong()
        }
    }

    override fun eventProperty(property: String, value: Boolean) {
        when (property) {
            "pause" -> _isPlaying.value = !value
            "mute" -> _playerState.value = _playerState.value.copy(isMuted = value)
        }
    }

    override fun eventProperty(property: String, value: String) {}

    override fun event(eventId: Int) {
        when (eventId) {
            MPVLib.MPV_EVENT_FILE_LOADED -> {
                _playerState.value = _playerState.value.copy(loadState = LoadState.LOADED)
                Timber.d("Media loaded")
            }
            MPVLib.MPV_EVENT_PLAYBACK_RESTART -> {
                _playerState.value = _playerState.value.copy(loadState = LoadState.PLAYING)
                _isPlaying.value = true
                Timber.d("Playback started")
            }
            MPVLib.MPV_EVENT_END_FILE -> {
                _playerState.value = _playerState.value.copy(loadState = LoadState.ENDED)
                Timber.d("Playback ended")
            }
        }
    }
}

data class PlayerState(
    val loadState: LoadState = LoadState.IDLE,
    val currentUrl: String? = null,
    val playbackSpeed: Float = 1.0f,
    val volume: Int = 100,
    val isMuted: Boolean = false,
    val error: String? = null
)

enum class LoadState {
    IDLE,
    LOADING,
    LOADED,
    PLAYING,
    ENDED,
    ERROR
}

data class PlayerTracks(
    val audioTracks: List<Track> = emptyList(),
    val subtitleTracks: List<Track> = emptyList()
)

data class Track(
    val id: Int,
    val title: String,
    val language: String,
    val selected: Boolean
)
