package com.openflix.ui.screens

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.interop.UIKitView
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.coroutines.delay
import platform.AVFAudio.AVAudioSession
import platform.AVFAudio.AVAudioSessionCategoryPlayback
import platform.AVFAudio.AVAudioSessionModeDefault
import platform.AVFAudio.setActive
import platform.AVFoundation.*
import platform.AVKit.AVPlayerViewController
import platform.CoreMedia.CMTimeGetSeconds
import platform.Foundation.*
import platform.UIKit.UIColor
import platform.UIKit.UIViewContentMode

@OptIn(ExperimentalForeignApi::class)
@Composable
actual fun SplashVideoPlayer(
    onVideoEnd: () -> Unit,
    onFadeOutAudio: () -> Unit
) {
    val player = remember {
        try {
            val session = AVAudioSession.sharedInstance()
            session.setCategory(AVAudioSessionCategoryPlayback, AVAudioSessionModeDefault, options = 0u, error = null)
            session.setActive(true, null)
        } catch (_: Exception) {}

        val url = NSBundle.mainBundle.URLForResource("splash_video", withExtension = "mp4")
        if (url != null) {
            val p = AVPlayer(uRL = url)
            p.volume = 1.0f
            p
        } else {
            println("SPLASH: splash_video.mp4 not found in bundle")
            null
        }
    }

    val playerViewController = remember {
        AVPlayerViewController().apply {
            showsPlaybackControls = false
            view.backgroundColor = UIColor.blackColor
            view.contentMode = UIViewContentMode.UIViewContentModeScaleAspectFill
        }
    }

    DisposableEffect(player) {
        val observer = player?.let { p ->
            NSNotificationCenter.defaultCenter.addObserverForName(
                name = AVPlayerItemDidPlayToEndTimeNotification,
                `object` = p.currentItem,
                queue = NSOperationQueue.mainQueue
            ) { _ ->
                onVideoEnd()
            }
        }

        onDispose {
            observer?.let { NSNotificationCenter.defaultCenter.removeObserver(it) }
            player?.pause()
            playerViewController.player = null
        }
    }

    // Audio fade-out in the last 1.5 seconds
    LaunchedEffect(player) {
        player?.play()

        if (player != null) {
            // Wait for duration to be known
            var duration = 0.0
            while (duration <= 0.0) {
                delay(200)
                val item = player.currentItem ?: break
                duration = CMTimeGetSeconds(item.duration)
                if (duration.isNaN()) duration = 0.0
            }

            if (duration > 2.0) {
                // Wait until 1.5s before end
                val fadeStart = duration - 1.5
                while (true) {
                    delay(50)
                    val currentTime = CMTimeGetSeconds(player.currentTime())
                    if (currentTime.isNaN()) continue
                    if (currentTime >= fadeStart) {
                        val remaining = duration - currentTime
                        val vol = (remaining / 1.5).coerceIn(0.0, 1.0).toFloat()
                        player.volume = vol
                        if (remaining <= 0.05) break
                    }
                }
            }
        }
    }

    if (player != null) {
        UIKitView(
            factory = {
                playerViewController.player = player
                playerViewController.showsPlaybackControls = false
                playerViewController.view.backgroundColor = UIColor.blackColor
                playerViewController.videoGravity = AVLayerVideoGravityResizeAspectFill
                playerViewController.view
            },
            update = { _ ->
                playerViewController.player = player
            },
            modifier = Modifier.fillMaxSize(),
            onRelease = {
                playerViewController.player = null
            }
        )
    } else {
        LaunchedEffect(Unit) { onVideoEnd() }
    }
}
