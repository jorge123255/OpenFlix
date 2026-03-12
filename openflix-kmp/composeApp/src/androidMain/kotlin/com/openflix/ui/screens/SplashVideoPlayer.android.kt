package com.openflix.ui.screens

import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.openflix.R

@androidx.annotation.OptIn(androidx.media3.common.util.UnstableApi::class)
@Composable
actual fun SplashVideoPlayer(
    onVideoEnd: () -> Unit,
    onFadeOutAudio: () -> Unit
) {
    val context = LocalContext.current

    val isTV = remember {
        val uiModeManager = context.getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
    }

    val videoUri = remember {
        val resId = if (isTV) R.raw.splash_video_landscape else R.raw.splash_video
        Uri.parse("android.resource://${context.packageName}/$resId")
    }

    val handler = remember { Handler(Looper.getMainLooper()) }
    var fadeRunnable by remember { mutableStateOf<Runnable?>(null) }

    val exoPlayer = remember {
        ExoPlayer.Builder(context)
            .build()
            .apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(C.USAGE_MEDIA)
                        .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
                        .build(),
                    false
                )
                volume = 1.0f
                setMediaItem(MediaItem.fromUri(videoUri))
                playWhenReady = true
                prepare()
            }
    }

    DisposableEffect(exoPlayer) {
        val listener = object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                if (playbackState == Player.STATE_ENDED) {
                    onVideoEnd()
                }
            }
        }
        exoPlayer.addListener(listener)

        // Audio fade-out: start fading 1.5s before end
        val fadeChecker = object : Runnable {
            override fun run() {
                if (exoPlayer.duration > 0 && exoPlayer.currentPosition > 0) {
                    val remaining = exoPlayer.duration - exoPlayer.currentPosition
                    if (remaining in 1..1500) {
                        // Fade volume proportionally over last 1.5s
                        val vol = (remaining.toFloat() / 1500f).coerceIn(0f, 1f)
                        exoPlayer.volume = vol
                    }
                }
                handler.postDelayed(this, 50)
            }
        }
        fadeRunnable = fadeChecker
        handler.postDelayed(fadeChecker, 1000) // Start checking after 1s

        onDispose {
            fadeRunnable?.let { handler.removeCallbacks(it) }
            exoPlayer.removeListener(listener)
            exoPlayer.release()
        }
    }

    AndroidView(
        factory = { ctx ->
            PlayerView(ctx).apply {
                player = exoPlayer
                useController = false
                resizeMode = if (isTV) {
                    AspectRatioFrameLayout.RESIZE_MODE_FIT
                } else {
                    AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                }
                setBackgroundColor(android.graphics.Color.BLACK)
            }
        },
        modifier = Modifier.fillMaxSize()
    )
}
