package com.openflix.ui.player

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color

/**
 * On iOS, video playback uses native AVPlayerViewController presented modally.
 * This composable is just a black placeholder — the actual video renders natively
 * on top of the Compose layer via NativeVideoPlayer.
 */
@Composable
actual fun VideoSurface(
    player: PlatformPlayer,
    modifier: Modifier
) {
    // Black background placeholder — native player renders on top
    Box(modifier = modifier.background(Color.Black))
}
