package com.openflix.presentation.components

import android.graphics.PixelFormat
import android.view.SurfaceView
import android.view.WindowManager
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import com.openflix.player.MpvPlayer
import timber.log.Timber

/**
 * Composable wrapper for mpv video rendering surface.
 * This creates a SurfaceView and attaches it to the MpvPlayer for video output.
 * The MpvPlayer's surfaceCreated callback handles waiting for initialization.
 * Detects display output mode and requests appropriate resolution for best upscaling.
 */
@Composable
fun MpvVideoSurface(
    player: MpvPlayer,
    modifier: Modifier = Modifier,
    force4K: Boolean = true  // Default to 4K on capable devices
) {
    val context = LocalContext.current

    val surfaceView = remember(force4K) {
        SurfaceView(context).apply {
            // Request hardware acceleration and optimal pixel format
            holder.setFormat(PixelFormat.TRANSLUCENT)

            // Detect actual display output mode
            val windowManager = context.getSystemService(android.content.Context.WINDOW_SERVICE) as WindowManager
            val displayMode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                windowManager.defaultDisplay.mode
            } else null

            val physicalWidth = displayMode?.physicalWidth ?: 0
            val physicalHeight = displayMode?.physicalHeight ?: 0

            Timber.d("Display mode: ${physicalWidth}x${physicalHeight}")
            Timber.d("Device: ${android.os.Build.MANUFACTURER} ${android.os.Build.MODEL}")

            // Check if display is actually outputting 4K
            val isDisplay4K = physicalWidth >= 3840 && physicalHeight >= 2160

            // Known 4K-capable devices (fallback if display mode detection fails)
            val is4KCapableDevice = android.os.Build.MODEL.contains("SHIELD", ignoreCase = true) ||
                    android.os.Build.MANUFACTURER.contains("NVIDIA", ignoreCase = true) ||
                    android.os.Build.MODEL.contains("Mi Box", ignoreCase = true) ||
                    android.os.Build.MODEL.contains("Chromecast", ignoreCase = true) ||
                    android.os.Build.MODEL.contains("Onn", ignoreCase = true)

            when {
                // Display is confirmed 4K and user wants 4K
                isDisplay4K && force4K -> {
                    holder.setFixedSize(3840, 2160)
                    Timber.d("Using 4K surface: 3840x2160 (display confirmed 4K)")
                }
                // Known 4K device but can't confirm display mode, use 4K if requested
                is4KCapableDevice && force4K -> {
                    holder.setFixedSize(3840, 2160)
                    Timber.d("Using 4K surface: 3840x2160 (4K-capable device)")
                }
                // Default to 1080p
                else -> {
                    holder.setFixedSize(1920, 1080)
                    Timber.d("Using 1080p surface: 1920x1080")
                }
            }
        }
    }

    // Attach surface immediately - the SurfaceHolder.Callback in MpvPlayer
    // will handle waiting for initialization in surfaceCreated
    DisposableEffect(player, surfaceView) {
        player.attachSurface(surfaceView)
        onDispose {
            // Surface cleanup is handled by the SurfaceHolder callback
        }
    }

    AndroidView(
        factory = { surfaceView },
        modifier = modifier
    )
}
