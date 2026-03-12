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
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.player.LoadState
import com.openflix.player.MpvPlayer
import com.openflix.presentation.components.MpvVideoSurface
import com.openflix.presentation.components.player.TabletPlayerControls
import com.openflix.presentation.theme.OpenFlixColors
import com.openflix.util.LocalDeviceType
import kotlinx.coroutines.delay

/**
 * Full-screen video player for movies and TV shows.
 */
@Composable
fun VideoPlayerScreen(
    mediaId: String,
    fileId: Long? = null,
    onBack: () -> Unit,
    mpvPlayer: MpvPlayer,
    viewModel: VideoPlayerViewModel = hiltViewModel()
) {
    val deviceType = LocalDeviceType.current

    val uiState by viewModel.uiState.collectAsState()
    val playerState by mpvPlayer.playerState.collectAsState()
    val isPlaying by mpvPlayer.isPlaying.collectAsState()
    val position by mpvPlayer.position.collectAsState()
    val duration by mpvPlayer.duration.collectAsState()

    // Initialize player and load media
    LaunchedEffect(mediaId, fileId) {
        mpvPlayer.initialize()
        viewModel.loadMedia(mediaId, fileId)
    }

    // Start playback when we have the URL AND surface is attached
    LaunchedEffect(uiState.streamUrl) {
        uiState.streamUrl?.let { url ->
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

    // Handle back press
    BackHandler {
        viewModel.saveProgress(position)
        mpvPlayer.stop()
        onBack()
    }

    if (deviceType.isTabletOrPhone) {
        TabletVideoPlayer(
            uiState = uiState,
            playerState = playerState,
            isPlaying = isPlaying,
            position = position,
            duration = duration,
            mpvPlayer = mpvPlayer,
            viewModel = viewModel,
            onBack = onBack
        )
    } else {
        TVVideoPlayer(
            uiState = uiState,
            playerState = playerState,
            isPlaying = isPlaying,
            position = position,
            duration = duration,
            mpvPlayer = mpvPlayer,
            viewModel = viewModel,
            onBack = onBack
        )
    }
}

// === Tablet-optimized VOD Player (touch controls, matching iOS) ===

@Composable
private fun TabletVideoPlayer(
    uiState: VideoPlayerUiState,
    playerState: com.openflix.player.PlayerState,
    isPlaying: Boolean,
    position: Long,
    duration: Long,
    mpvPlayer: MpvPlayer,
    viewModel: VideoPlayerViewModel,
    onBack: () -> Unit
) {
    var aspectRatioIndex by remember { mutableIntStateOf(0) }
    val aspectRatios = remember { listOf("-1", "16:9", "4:3", "2.35:1") }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
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
                TabletLoadingSpinner()
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
                    androidx.compose.material3.Text(
                        text = "Playback Error",
                        fontSize = 20.sp,
                        fontWeight = androidx.compose.ui.text.font.FontWeight.Bold,
                        color = OpenFlixColors.Error
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    androidx.compose.material3.Text(
                        text = uiState.error ?: playerState.error ?: "Unknown error",
                        fontSize = 16.sp,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            }
        }

        // Tablet player controls (touch-friendly, matching iOS)
        if (uiState.mediaInfo != null) {
            TabletPlayerControls(
                title = uiState.mediaInfo?.title ?: "",
                subtitle = uiState.mediaInfo?.subtitle,
                isPlaying = isPlaying,
                position = position,
                duration = duration,
                isLive = false,
                isMuted = playerState.isMuted,
                playbackSpeed = playerState.playbackSpeed,
                onPlayPause = { mpvPlayer.togglePlayPause() },
                onSeekTo = { mpvPlayer.seekTo(it) },
                onSeekRelative = { seconds -> mpvPlayer.seekRelative(seconds) },
                onBack = {
                    viewModel.saveProgress(position)
                    mpvPlayer.stop()
                    onBack()
                },
                onToggleMute = { mpvPlayer.toggleMute() },
                onCyclePlaybackSpeed = {
                    val speeds = listOf(0.5f, 0.75f, 1.0f, 1.25f, 1.5f, 2.0f)
                    val currentIndex = speeds.indexOfFirst {
                        kotlin.math.abs(it - playerState.playbackSpeed) < 0.01f
                    }.takeIf { it >= 0 } ?: 2
                    val nextSpeed = speeds[(currentIndex + 1) % speeds.size]
                    mpvPlayer.setPlaybackSpeed(nextSpeed)
                },
                onCycleAspectRatio = {
                    aspectRatioIndex = (aspectRatioIndex + 1) % aspectRatios.size
                    mpvPlayer.setAspectRatio(aspectRatios[aspectRatioIndex])
                },
                onCycleAudioTrack = { mpvPlayer.cycleAudioTrack() },
                onCycleSubtitleTrack = { mpvPlayer.cycleSubtitleTrack() }
            )
        }
    }
}

// === TV-optimized VOD Player (D-pad/focus controls) ===

@Composable
private fun TVVideoPlayer(
    uiState: VideoPlayerUiState,
    playerState: com.openflix.player.PlayerState,
    isPlaying: Boolean,
    position: Long,
    duration: Long,
    mpvPlayer: MpvPlayer,
    viewModel: VideoPlayerViewModel,
    onBack: () -> Unit
) {
    var showOverlay by remember { mutableStateOf(true) }
    val focusRequester = remember { FocusRequester() }

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
                        Key.MediaStop -> {
                            viewModel.saveProgress(position)
                            mpvPlayer.stop()
                            onBack()
                            true
                        }
                        Key(android.view.KeyEvent.KEYCODE_CAPTIONS.toLong()),
                        Key(android.view.KeyEvent.KEYCODE_PROG_YELLOW.toLong()) -> {
                            mpvPlayer.cycleSubtitleTrack()
                            true
                        }
                        Key(android.view.KeyEvent.KEYCODE_PROG_GREEN.toLong()) -> {
                            mpvPlayer.cycleAudioTrack()
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

        // Playback overlay (TV)
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
                Button(
                    onClick = onBack,
                    colors = ButtonDefaults.colors(
                        containerColor = OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
                    )
                ) {
                    Text("Back")
                }

                Spacer(modifier = Modifier.width(24.dp))

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

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Button(
                        onClick = { onSeek(maxOf(0, position - 10000)) },
                        colors = ButtonDefaults.colors(
                            containerColor = OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
                        )
                    ) {
                        Text("-10s")
                    }

                    Spacer(modifier = Modifier.width(24.dp))

                    Button(
                        onClick = onPlayPause,
                        colors = ButtonDefaults.colors(
                            containerColor = OpenFlixColors.Primary
                        )
                    ) {
                        Text(if (isPlaying) "Pause" else "Play")
                    }

                    Spacer(modifier = Modifier.width(24.dp))

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
private fun TabletLoadingSpinner() {
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
