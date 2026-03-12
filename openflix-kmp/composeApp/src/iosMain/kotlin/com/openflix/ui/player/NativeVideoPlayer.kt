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
import platform.Foundation.NSNotificationCenter
import platform.Foundation.NSNotificationName
import platform.Foundation.NSURL
import platform.UIKit.*
import platform.darwin.NSObject

/**
 * Presents a native full-screen AVPlayerViewController.
 * Bypasses Compose's Metal rendering to ensure video displays correctly.
 */
@OptIn(ExperimentalForeignApi::class)
object NativeVideoPlayer {

    private var playerVC: AVPlayerViewController? = null

    // Signals when the native player has been dismissed
    private val _dismissed = MutableStateFlow(false)
    val dismissed: StateFlow<Boolean> = _dismissed.asStateFlow()

    @Suppress("DEPRECATION")
    fun present(url: String, title: String = "") {
        _dismissed.value = false
        val nsUrl = NSURL.URLWithString(url) ?: return

        // Configure audio session
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

        // Find root view controller
        val rootVC = UIApplication.sharedApplication.keyWindow?.rootViewController ?: return

        // Walk to the topmost presented controller
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

    /**
     * Called by PlatformPlayer periodically to check if the native player was dismissed
     * by the user (via the Done button in AVPlayerViewController).
     */
    fun checkIfDismissed(): Boolean {
        val vc = playerVC ?: return false
        // If the VC is no longer being presented, the user dismissed it
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
