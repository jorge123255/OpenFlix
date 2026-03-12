package com.openflix.ui.player

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import platform.AVFAudio.AVAudioSession
import platform.AVFAudio.AVAudioSessionCategoryPlayback
import platform.AVFAudio.AVAudioSessionModeMoviePlayback
import platform.AVFAudio.setActive
import platform.AVFoundation.*
import platform.AVKit.AVPlayerViewController
import platform.Foundation.NSURL
import platform.UIKit.*

/**
 * Separate native player for Live TV on iOS.
 * Completely independent from NativeVideoPlayer (which is for movies/recordings).
 * Uses the same AVPlayerViewController mechanism but has its own state.
 */
@OptIn(ExperimentalForeignApi::class)
object NativeLiveTVPlayer {

    private var playerVC: AVPlayerViewController? = null

    private val _dismissed = MutableStateFlow(false)
    val dismissed: StateFlow<Boolean> = _dismissed.asStateFlow()

    @Suppress("DEPRECATION")
    fun present(url: String, title: String = "") {
        _dismissed.value = false
        val nsUrl = NSURL.URLWithString(url) ?: return

        try {
            val session = AVAudioSession.sharedInstance()
            session.setCategory(AVAudioSessionCategoryPlayback, AVAudioSessionModeMoviePlayback, options = 0u, error = null)
            session.setActive(true, null)
        } catch (_: Exception) {}

        val asset = AVURLAsset(uRL = nsUrl, options = null)
        val playerItem = AVPlayerItem(asset = asset)
        val player = AVPlayer(playerItem = playerItem)

        val vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        playerVC = vc

        val rootVC = UIApplication.sharedApplication.keyWindow?.rootViewController ?: return
        var topVC: UIViewController = rootVC
        while (topVC.presentedViewController != null) {
            topVC = topVC.presentedViewController!!
        }

        topVC.presentViewController(vc, animated = true) {
            player.play()
        }
    }

    fun dismiss() {
        val vc = playerVC ?: return
        vc.player?.pause()
        vc.player = null
        vc.dismissViewControllerAnimated(true) {
            _dismissed.value = true
        }
        playerVC = null
    }

    fun checkIfDismissed(): Boolean {
        val vc = playerVC ?: return false
        if (vc.presentingViewController == null && vc.view.window == null) {
            playerVC?.player?.pause()
            playerVC?.player = null
            playerVC = null
            _dismissed.value = true
            return true
        }
        return false
    }
}
