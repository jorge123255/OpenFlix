package com.openflix.player

import android.content.Context
import android.view.SurfaceView
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Singleton ExoPlayer for Live TV playback.
 * Designed to be shared between guide preview and fullscreen player.
 * Uses ExoPlayer for better HLS support and easy surface switching.
 */
@Singleton
@OptIn(UnstableApi::class)
class LiveTVPlayer @Inject constructor(
    private val context: Context
) {
    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null
    private var currentSurfaceView: SurfaceView? = null

    // Playback state
    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying.asStateFlow()

    private val _isBuffering = MutableStateFlow(false)
    val isBuffering: StateFlow<Boolean> = _isBuffering.asStateFlow()

    private val _isMuted = MutableStateFlow(false)
    val isMuted: StateFlow<Boolean> = _isMuted.asStateFlow()

    private val _isPaused = MutableStateFlow(false)
    val isPaused: StateFlow<Boolean> = _isPaused.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private val _currentUrl = MutableStateFlow<String?>(null)
    val currentUrl: StateFlow<String?> = _currentUrl.asStateFlow()

    // Track info
    private val _audioTracks = MutableStateFlow<List<TrackInfo>>(emptyList())
    val audioTracks: StateFlow<List<TrackInfo>> = _audioTracks.asStateFlow()

    private val _subtitleTracks = MutableStateFlow<List<TrackInfo>>(emptyList())
    val subtitleTracks: StateFlow<List<TrackInfo>> = _subtitleTracks.asStateFlow()

    private val _selectedAudioTrack = MutableStateFlow<Int?>(null)
    val selectedAudioTrack: StateFlow<Int?> = _selectedAudioTrack.asStateFlow()

    private val _selectedSubtitleTrack = MutableStateFlow<Int?>(null)
    val selectedSubtitleTrack: StateFlow<Int?> = _selectedSubtitleTrack.asStateFlow()

    // Position for time-shift
    private val _position = MutableStateFlow(0L)
    val position: StateFlow<Long> = _position.asStateFlow()

    private val _duration = MutableStateFlow(0L)
    val duration: StateFlow<Long> = _duration.asStateFlow()

    private val _isLive = MutableStateFlow(true)
    val isLive: StateFlow<Boolean> = _isLive.asStateFlow()

    // Stream info
    private val _streamInfo = MutableStateFlow<StreamInfo?>(null)
    val streamInfo: StateFlow<StreamInfo?> = _streamInfo.asStateFlow()

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
                    _isPlaying.value = !_isPaused.value
                    _isBuffering.value = false
                    updateTracks()
                }
                Player.STATE_ENDED -> {
                    _isPlaying.value = false
                    _isBuffering.value = false
                }
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            _isPlaying.value = isPlaying
            _isPaused.value = !isPlaying && exoPlayer?.playbackState == Player.STATE_READY
        }

        override fun onTracksChanged(tracks: Tracks) {
            updateTracks()
        }

        override fun onPlayerError(error: PlaybackException) {
            Timber.e(error, "LiveTVPlayer error: ${error.errorCodeName}")
            _error.value = error.message ?: error.errorCodeName
            _isPlaying.value = false
            _isBuffering.value = false
        }
    }

    fun initialize() {
        if (exoPlayer != null) return

        trackSelector = DefaultTrackSelector(context).apply {
            setParameters(buildUponParameters()
                .setMaxVideoSizeSd() // Start with SD, can upgrade
                .setPreferredAudioLanguage("en")
            )
        }

        exoPlayer = ExoPlayer.Builder(context)
            .setTrackSelector(trackSelector!!)
            .setMediaSourceFactory(DefaultMediaSourceFactory(context))
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(C.USAGE_MEDIA)
                    .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
                    .build(),
                true // Handle audio focus
            )
            .build()
            .apply {
                addListener(playerListener)
                playWhenReady = true
            }

        Timber.d("LiveTVPlayer initialized")
    }

    /**
     * Attach a surface view for video output.
     * Can be called multiple times to switch surfaces (preview <-> fullscreen).
     */
    fun setSurfaceView(surfaceView: SurfaceView?) {
        currentSurfaceView = surfaceView
        exoPlayer?.setVideoSurfaceView(surfaceView)
        Timber.d("LiveTVPlayer surface set: ${surfaceView != null}")
    }

    /**
     * Get the underlying ExoPlayer for direct PlayerView integration
     */
    fun getPlayer(): ExoPlayer? = exoPlayer

    fun play(url: String) {
        val player = exoPlayer ?: run {
            initialize()
            exoPlayer
        } ?: return

        // If same URL is already playing, don't reload
        if (_currentUrl.value == url && _isPlaying.value) {
            Timber.d("Already playing: $url")
            return
        }

        _error.value = null
        _isBuffering.value = true
        _currentUrl.value = url
        _isLive.value = true

        try {
            val mediaItem = MediaItem.Builder()
                .setUri(url)
                .setLiveConfiguration(
                    MediaItem.LiveConfiguration.Builder()
                        .setMaxPlaybackSpeed(1.02f)
                        .build()
                )
                .build()

            player.setMediaItem(mediaItem)
            player.prepare()
            player.play()
            _isPaused.value = false
            Timber.d("LiveTVPlayer playing: $url")
        } catch (e: Exception) {
            Timber.e(e, "Failed to play")
            _error.value = e.message
        }
    }

    fun stop() {
        exoPlayer?.stop()
        _isPlaying.value = false
        _currentUrl.value = null
    }

    fun pause() {
        exoPlayer?.pause()
        _isPaused.value = true
        _isLive.value = false
    }

    fun resume() {
        exoPlayer?.play()
        _isPaused.value = false
    }

    fun togglePlayPause() {
        if (_isPaused.value) resume() else pause()
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

    fun seekTo(positionMs: Long) {
        exoPlayer?.seekTo(positionMs)
        _isLive.value = false
    }

    fun seekRelative(deltaMs: Long) {
        val player = exoPlayer ?: return
        val newPosition = (player.currentPosition + deltaMs).coerceAtLeast(0)
        player.seekTo(newPosition)
        _isLive.value = false
    }

    fun seekBack10() = seekRelative(-10_000)
    fun seekForward10() = seekRelative(10_000)

    fun goLive() {
        exoPlayer?.seekToDefaultPosition()
        _isLive.value = true
        if (_isPaused.value) resume()
    }

    /**
     * Select an audio track by index
     */
    fun selectAudioTrack(index: Int) {
        val player = exoPlayer ?: return
        val tracks = player.currentTracks

        var audioTrackIndex = 0
        for (group in tracks.groups) {
            if (group.type == C.TRACK_TYPE_AUDIO) {
                if (audioTrackIndex == index) {
                    val override = TrackSelectionOverride(group.mediaTrackGroup, 0)
                    player.trackSelectionParameters = player.trackSelectionParameters
                        .buildUpon()
                        .setOverrideForType(override)
                        .build()
                    _selectedAudioTrack.value = index
                    Timber.d("Selected audio track: $index")
                    return
                }
                audioTrackIndex++
            }
        }
    }

    /**
     * Select a subtitle track by index, or -1 to disable
     */
    fun selectSubtitleTrack(index: Int) {
        val player = exoPlayer ?: return

        if (index < 0) {
            // Disable subtitles
            player.trackSelectionParameters = player.trackSelectionParameters
                .buildUpon()
                .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
                .build()
            _selectedSubtitleTrack.value = null
            Timber.d("Subtitles disabled")
            return
        }

        val tracks = player.currentTracks
        var subtitleTrackIndex = 0

        player.trackSelectionParameters = player.trackSelectionParameters
            .buildUpon()
            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
            .build()

        for (group in tracks.groups) {
            if (group.type == C.TRACK_TYPE_TEXT) {
                if (subtitleTrackIndex == index) {
                    val override = TrackSelectionOverride(group.mediaTrackGroup, 0)
                    player.trackSelectionParameters = player.trackSelectionParameters
                        .buildUpon()
                        .setOverrideForType(override)
                        .build()
                    _selectedSubtitleTrack.value = index
                    Timber.d("Selected subtitle track: $index")
                    return
                }
                subtitleTrackIndex++
            }
        }
    }

    /**
     * Cycle to next audio track
     */
    fun cycleAudioTrack(): TrackInfo? {
        val tracks = _audioTracks.value
        if (tracks.isEmpty()) return null

        val currentIndex = _selectedAudioTrack.value ?: 0
        val nextIndex = (currentIndex + 1) % tracks.size
        selectAudioTrack(nextIndex)
        return tracks.getOrNull(nextIndex)
    }

    /**
     * Cycle to next subtitle track (including off)
     */
    fun cycleSubtitleTrack(): TrackInfo? {
        val tracks = _subtitleTracks.value
        val currentIndex = _selectedSubtitleTrack.value

        val nextIndex = when {
            currentIndex == null -> if (tracks.isNotEmpty()) 0 else return null
            currentIndex >= tracks.size - 1 -> -1 // Turn off
            else -> currentIndex + 1
        }

        selectSubtitleTrack(nextIndex)
        return if (nextIndex >= 0) tracks.getOrNull(nextIndex) else null
    }

    private fun updateTracks() {
        val player = exoPlayer ?: return
        val tracks = player.currentTracks

        val audioList = mutableListOf<TrackInfo>()
        val subtitleList = mutableListOf<TrackInfo>()

        var audioIndex = 0
        var subtitleIndex = 0

        // Stream info variables
        var videoWidth: Int? = null
        var videoHeight: Int? = null
        var videoCodec: String? = null
        var videoFrameRate: Float? = null
        var videoBitrate: Int? = null
        var audioCodec: String? = null
        var audioChannels: Int? = null
        var audioSampleRate: Int? = null
        var audioBitrate: Int? = null

        for (group in tracks.groups) {
            when (group.type) {
                C.TRACK_TYPE_VIDEO -> {
                    for (i in 0 until group.length) {
                        if (group.isTrackSelected(i)) {
                            val format = group.getTrackFormat(i)
                            videoWidth = format.width.takeIf { it != Format.NO_VALUE }
                            videoHeight = format.height.takeIf { it != Format.NO_VALUE }
                            videoCodec = format.codecs ?: format.sampleMimeType?.substringAfter("/")
                            videoFrameRate = format.frameRate.takeIf { it != Format.NO_VALUE.toFloat() }
                            videoBitrate = format.bitrate.takeIf { it != Format.NO_VALUE }
                        }
                    }
                }
                C.TRACK_TYPE_AUDIO -> {
                    for (i in 0 until group.length) {
                        val format = group.getTrackFormat(i)
                        val isSelected = group.isTrackSelected(i)
                        audioList.add(TrackInfo(
                            index = audioIndex,
                            label = format.label ?: format.language?.uppercase() ?: "Track ${audioIndex + 1}",
                            language = format.language,
                            isSelected = isSelected
                        ))
                        if (isSelected) {
                            _selectedAudioTrack.value = audioIndex
                            audioCodec = format.codecs ?: format.sampleMimeType?.substringAfter("/")
                            audioChannels = format.channelCount.takeIf { it != Format.NO_VALUE }
                            audioSampleRate = format.sampleRate.takeIf { it != Format.NO_VALUE }
                            audioBitrate = format.bitrate.takeIf { it != Format.NO_VALUE }
                        }
                    }
                    audioIndex++
                }
                C.TRACK_TYPE_TEXT -> {
                    for (i in 0 until group.length) {
                        val format = group.getTrackFormat(i)
                        val isSelected = group.isTrackSelected(i)
                        subtitleList.add(TrackInfo(
                            index = subtitleIndex,
                            label = format.label ?: format.language?.uppercase() ?: "Track ${subtitleIndex + 1}",
                            language = format.language,
                            isSelected = isSelected
                        ))
                        if (isSelected) _selectedSubtitleTrack.value = subtitleIndex
                    }
                    subtitleIndex++
                }
            }
        }

        _audioTracks.value = audioList
        _subtitleTracks.value = subtitleList

        // Update stream info
        _streamInfo.value = StreamInfo(
            videoWidth = videoWidth,
            videoHeight = videoHeight,
            videoCodec = videoCodec,
            videoFrameRate = videoFrameRate,
            videoBitrate = videoBitrate,
            audioCodec = audioCodec,
            audioChannels = audioChannels,
            audioSampleRate = audioSampleRate,
            audioBitrate = audioBitrate
        )

        Timber.d("Tracks updated: ${audioList.size} audio, ${subtitleList.size} subtitle, video: ${videoWidth}x${videoHeight}")
    }

    fun release() {
        exoPlayer?.removeListener(playerListener)
        exoPlayer?.release()
        exoPlayer = null
        trackSelector = null
        currentSurfaceView = null
        _currentUrl.value = null
        Timber.d("LiveTVPlayer released")
    }
}

data class TrackInfo(
    val index: Int,
    val label: String,
    val language: String?,
    val isSelected: Boolean
)

data class StreamInfo(
    val videoWidth: Int?,
    val videoHeight: Int?,
    val videoCodec: String?,
    val videoFrameRate: Float?,
    val videoBitrate: Int?,
    val audioCodec: String?,
    val audioChannels: Int?,
    val audioSampleRate: Int?,
    val audioBitrate: Int?
) {
    val resolution: String?
        get() = if (videoWidth != null && videoHeight != null) "${videoWidth}x${videoHeight}" else null

    val resolutionLabel: String?
        get() = when {
            videoHeight == null -> null
            videoHeight >= 2160 -> "4K"
            videoHeight >= 1080 -> "1080p"
            videoHeight >= 720 -> "720p"
            videoHeight >= 480 -> "480p"
            else -> "${videoHeight}p"
        }

    val audioChannelsLabel: String?
        get() = when (audioChannels) {
            1 -> "Mono"
            2 -> "Stereo"
            6 -> "5.1"
            8 -> "7.1"
            else -> audioChannels?.let { "${it}ch" }
        }

    val videoBitrateLabel: String?
        get() = videoBitrate?.let {
            when {
                it >= 1_000_000 -> "${it / 1_000_000} Mbps"
                it >= 1_000 -> "${it / 1_000} Kbps"
                else -> "$it bps"
            }
        }

    val audioBitrateLabel: String?
        get() = audioBitrate?.let {
            when {
                it >= 1_000 -> "${it / 1_000} Kbps"
                else -> "$it bps"
            }
        }
}
