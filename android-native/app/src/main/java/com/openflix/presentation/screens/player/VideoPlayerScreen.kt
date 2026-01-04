package com.openflix.presentation.screens.player

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.*
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.player.LoadState
import com.openflix.player.MpvPlayer
import com.openflix.presentation.components.MpvVideoSurface
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay

/**
 * Full-screen video player for movies and TV shows.
 */
@Composable
fun VideoPlayerScreen(
    mediaId: String,
    onBack: () -> Unit,
    mpvPlayer: MpvPlayer,
    viewModel: VideoPlayerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val playerState by mpvPlayer.playerState.collectAsState()
    val isPlaying by mpvPlayer.isPlaying.collectAsState()
    val position by mpvPlayer.position.collectAsState()
    val duration by mpvPlayer.duration.collectAsState()

    // Overlay visibility
    var showOverlay by remember { mutableStateOf(true) }
    val focusRequester = remember { FocusRequester() }

    // Initialize player and load media
    LaunchedEffect(mediaId) {
        // Initialize mpv first (safe to call multiple times)
        mpvPlayer.initialize()
        // Then load media info
        viewModel.loadMedia(mediaId)
    }

    // Start playback when we have the URL AND surface is attached
    LaunchedEffect(uiState.streamUrl) {
        uiState.streamUrl?.let { url ->
            // Wait for surface to be attached (max 5 seconds)
            var attempts = 0
            while (!mpvPlayer.isSurfaceAttached && attempts < 100) {
                delay(50)
                attempts++
            }
            if (mpvPlayer.isSurfaceAttached) {
                mpvPlayer.play(url, uiState.startPosition)
            } else {
                timber.log.Timber.e("Surface not attached after 5s, cannot play")
            }
        }
    }

    // Auto-hide overlay
    LaunchedEffect(showOverlay) {
        if (showOverlay && isPlaying) {
            delay(5000)
            showOverlay = false
        }
    }

    // Request focus on launch
    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    // Handle back press
    BackHandler {
        // Save progress before exiting
        viewModel.saveProgress(position)
        mpvPlayer.stop()
        onBack()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .focusRequester(focusRequester)
            .focusable()
            .onKeyEvent { event ->
                if (event.type == KeyEventType.KeyDown) {
                    when (event.key) {
                        Key.DirectionCenter, Key.Enter -> {
                            if (showOverlay) {
                                mpvPlayer.togglePlayPause()
                            } else {
                                showOverlay = true
                            }
                            true
                        }
                        Key.DirectionLeft -> {
                            if (showOverlay) {
                                mpvPlayer.seekRelative(-10)
                            } else {
                                showOverlay = true
                            }
                            true
                        }
                        Key.DirectionRight -> {
                            if (showOverlay) {
                                mpvPlayer.seekRelative(10)
                            } else {
                                showOverlay = true
                            }
                            true
                        }
                        Key.DirectionUp, Key.DirectionDown -> {
                            showOverlay = true
                            true
                        }
                        Key.MediaPlayPause -> {
                            mpvPlayer.togglePlayPause()
                            true
                        }
                        Key.MediaPlay -> {
                            mpvPlayer.resume()
                            true
                        }
                        Key.MediaPause -> {
                            mpvPlayer.pause()
                            true
                        }
                        Key.MediaRewind -> {
                            mpvPlayer.seekRelative(-30)
                            true
                        }
                        Key.MediaFastForward -> {
                            mpvPlayer.seekRelative(30)
                            true
                        }
                        Key.Back, Key.Escape -> {
                            if (showOverlay) {
                                showOverlay = false
                            } else {
                                viewModel.saveProgress(position)
                                mpvPlayer.stop()
                                onBack()
                            }
                            true
                        }
                        else -> false
                    }
                } else {
                    false
                }
            }
    ) {
        // Video Surface
        MpvVideoSurface(
            player = mpvPlayer,
            modifier = Modifier.fillMaxSize()
        )

        // Loading indicator
        if (playerState.loadState == LoadState.LOADING || uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                PlayerLoadingSpinner()
            }
        }

        // Error display
        if (uiState.error != null || playerState.error != null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.8f)),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "Playback Error",
                        style = MaterialTheme.typography.headlineMedium,
                        color = OpenFlixColors.Error
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = uiState.error ?: playerState.error ?: "Unknown error",
                        style = MaterialTheme.typography.bodyLarge,
                        color = OpenFlixColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Button(onClick = onBack) {
                        Text("Go Back")
                    }
                }
            }
        }

        // Playback overlay
        AnimatedVisibility(
            visible = showOverlay && uiState.mediaInfo != null,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            PlayerOverlay(
                title = uiState.mediaInfo?.title ?: "",
                subtitle = uiState.mediaInfo?.subtitle,
                posterUrl = uiState.mediaInfo?.posterUrl,
                position = position,
                duration = duration,
                isPlaying = isPlaying,
                onPlayPause = { mpvPlayer.togglePlayPause() },
                onSeek = { mpvPlayer.seekTo(it) },
                onBack = {
                    viewModel.saveProgress(position)
                    mpvPlayer.stop()
                    onBack()
                }
            )
        }
    }
}

@Composable
private fun PlayerOverlay(
    title: String,
    subtitle: String?,
    posterUrl: String?,
    position: Long,
    duration: Long,
    isPlaying: Boolean,
    onPlayPause: () -> Unit,
    onSeek: (Long) -> Unit,
    onBack: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        // Top gradient with title
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Black.copy(alpha = 0.8f), Color.Transparent)
                    )
                )
                .padding(24.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top
            ) {
                // Back button
                Button(
                    onClick = onBack,
                    colors = ButtonDefaults.colors(
                        containerColor = OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
                    )
                ) {
                    Text("Back")
                }

                Spacer(modifier = Modifier.width(24.dp))

                // Poster
                if (posterUrl != null) {
                    AsyncImage(
                        model = posterUrl,
                        contentDescription = null,
                        modifier = Modifier
                            .height(100.dp)
                            .aspectRatio(2f / 3f)
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                }

                // Title
                Column {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.headlineMedium,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    if (subtitle != null) {
                        Text(
                            text = subtitle,
                            style = MaterialTheme.typography.bodyLarge,
                            color = OpenFlixColors.TextSecondary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
            }
        }

        // Bottom controls
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(Color.Transparent, Color.Black.copy(alpha = 0.8f))
                    )
                )
                .padding(24.dp)
        ) {
            Column {
                // Progress bar
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = formatTime(position),
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White
                    )

                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .padding(horizontal = 16.dp)
                            .height(4.dp)
                            .background(Color.White.copy(alpha = 0.3f), MaterialTheme.shapes.small)
                    ) {
                        val progress = if (duration > 0) position.toFloat() / duration else 0f
                        Box(
                            modifier = Modifier
                                .fillMaxHeight()
                                .fillMaxWidth(progress)
                                .background(OpenFlixColors.Primary, MaterialTheme.shapes.small)
                        )
                    }

                    Text(
                        text = formatTime(duration),
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Playback controls
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Rewind 10s
                    Button(
                        onClick = { onSeek(maxOf(0, position - 10000)) },
                        colors = ButtonDefaults.colors(
                            containerColor = OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
                        )
                    ) {
                        Text("-10s")
                    }

                    Spacer(modifier = Modifier.width(24.dp))

                    // Play/Pause
                    Button(
                        onClick = onPlayPause,
                        colors = ButtonDefaults.colors(
                            containerColor = OpenFlixColors.Primary
                        )
                    ) {
                        Text(if (isPlaying) "Pause" else "Play")
                    }

                    Spacer(modifier = Modifier.width(24.dp))

                    // Forward 10s
                    Button(
                        onClick = { onSeek(minOf(duration, position + 10000)) },
                        colors = ButtonDefaults.colors(
                            containerColor = OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
                        )
                    ) {
                        Text("+10s")
                    }
                }
            }
        }
    }
}

@Composable
private fun PlayerLoadingSpinner() {
    androidx.compose.foundation.Canvas(
        modifier = Modifier.size(64.dp)
    ) {
        drawCircle(
            color = Color.White.copy(alpha = 0.3f),
            radius = size.minDimension / 2,
            style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4.dp.toPx())
        )
    }
}

private fun formatTime(millis: Long): String {
    val totalSeconds = millis / 1000
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return if (hours > 0) {
        "%d:%02d:%02d".format(hours, minutes, seconds)
    } else {
        "%d:%02d".format(minutes, seconds)
    }
}
