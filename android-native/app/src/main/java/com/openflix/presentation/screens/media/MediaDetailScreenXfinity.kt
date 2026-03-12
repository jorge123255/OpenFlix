package com.openflix.presentation.screens.media

import androidx.compose.runtime.Composable

@Composable
fun MediaDetailScreenXfinity(
    mediaId: String,
    onBack: () -> Unit = {},
    onPlayMedia: (String, Long?) -> Unit = { _, _ -> }
) {
    MediaDetailScreen(
        mediaId = mediaId,
        onBack = onBack,
        onPlayMedia = onPlayMedia,
        onNavigateToSeason = { _, _ -> }
    )
}
