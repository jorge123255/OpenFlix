package com.openflix.ui.player

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

@Composable
expect fun VideoSurface(
    player: PlatformPlayer,
    modifier: Modifier = Modifier
)
