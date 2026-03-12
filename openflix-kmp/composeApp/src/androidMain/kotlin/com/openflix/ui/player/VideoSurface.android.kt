package com.openflix.ui.player

import android.view.SurfaceView
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView

@Composable
actual fun VideoSurface(
    player: PlatformPlayer,
    modifier: Modifier
) {
    DisposableEffect(player) {
        onDispose {
            player.detachSurface()
        }
    }

    AndroidView(
        factory = { context ->
            SurfaceView(context).also { surfaceView ->
                player.attachSurface(surfaceView)
            }
        },
        modifier = modifier
    )
}
