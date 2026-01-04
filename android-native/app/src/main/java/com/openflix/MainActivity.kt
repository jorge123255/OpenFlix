package com.openflix

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.Rational
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.openflix.player.LiveTVPlayer
import com.openflix.player.MpvPlayer
import com.openflix.presentation.navigation.OpenFlixNavHost
import com.openflix.presentation.theme.OpenFlixTheme
import dagger.hilt.android.AndroidEntryPoint
import timber.log.Timber
import javax.inject.Inject

/**
 * CompositionLocal for PiP state
 */
val LocalPipState = compositionLocalOf { PipState() }

data class PipState(
    val isInPipMode: Boolean = false,
    val canEnterPip: Boolean = false
)

/**
 * Main entry point Activity for OpenFlix.
 * Hosts the Compose navigation and handles TV-specific setup.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var mpvPlayer: MpvPlayer

    @Inject
    lateinit var liveTVPlayer: LiveTVPlayer

    // PiP state
    private var pipState by mutableStateOf(PipState())
    private var isInPlayerScreen by mutableStateOf(false)

    override fun onCreate(savedInstanceState: Bundle?) {
        // Install splash screen before super.onCreate()
        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)

        Timber.d("MainActivity onCreate")

        // Configure immersive mode for TV
        setupImmersiveMode()

        setContent {
            OpenFlixTheme {
                CompositionLocalProvider(LocalPipState provides pipState) {
                    OpenFlixNavHost(
                        mpvPlayer = mpvPlayer,
                        liveTVPlayer = liveTVPlayer,
                        onPlayerScreenChanged = { isInPlayer ->
                            isInPlayerScreen = isInPlayer
                            pipState = pipState.copy(canEnterPip = isInPlayer)
                        }
                    )
                }
            }
        }
    }

    /**
     * Called when user leaves the activity (presses Home)
     */
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Check if either player is playing for PiP
        if (isInPlayerScreen && (mpvPlayer.isPlaying.value || liveTVPlayer.isPlaying.value)) {
            enterPipMode()
        }
    }

    /**
     * Enter Picture-in-Picture mode
     */
    fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(16, 9))
                    .build()
                enterPictureInPictureMode(params)
                Timber.d("Entering PiP mode")
            } catch (e: Exception) {
                Timber.e(e, "Failed to enter PiP mode")
            }
        }
    }

    /**
     * Called when PiP mode changes
     */
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipState = pipState.copy(isInPipMode = isInPictureInPictureMode)
        Timber.d("PiP mode changed: $isInPictureInPictureMode")

        if (!isInPictureInPictureMode) {
            // Returned from PiP to fullscreen
            setupImmersiveMode()
        }
    }

    /**
     * Sets up full-screen immersive mode for TV experience
     */
    private fun setupImmersiveMode() {
        WindowCompat.setDecorFitsSystemWindows(window, false)

        val controller = WindowInsetsControllerCompat(window, window.decorView)
        controller.hide(WindowInsetsCompat.Type.systemBars())
        controller.systemBarsBehavior =
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
    }

    override fun onResume() {
        super.onResume()
        // Re-apply immersive mode on resume (only if not in PiP)
        if (!pipState.isInPipMode) {
            setupImmersiveMode()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mpvPlayer.release()
        liveTVPlayer.release()
    }
}
