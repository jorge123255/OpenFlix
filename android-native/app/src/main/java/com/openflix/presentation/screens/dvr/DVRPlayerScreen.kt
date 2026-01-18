package com.openflix.presentation.screens.dvr

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.*
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Commercial
import com.openflix.player.LoadState
import com.openflix.player.MpvPlayer
import com.openflix.presentation.components.MpvVideoSurface
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay

/**
 * Playback modes for DVR recordings.
 */
enum class DVRPlaybackMode {
    DEFAULT,    // Play from last position or start
    LIVE,       // Jump to live edge (for active recordings)
    START       // Play from beginning
}

/**
 * Full-screen player for DVR recordings.
 * Supports watching completed recordings and live recordings in progress.
 */
@Composable
fun DVRPlayerScreen(
    recordingId: String,
    playbackMode: DVRPlaybackMode = DVRPlaybackMode.DEFAULT,
    onBack: () -> Unit,
    mpvPlayer: MpvPlayer,
    viewModel: DVRPlayerViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val playerState by mpvPlayer.playerState.collectAsState()
    val isPlaying by mpvPlayer.isPlaying.collectAsState()
    val position by mpvPlayer.position.collectAsState()
    val duration by mpvPlayer.duration.collectAsState()

    // Overlay visibility
    var showOverlay by remember { mutableStateOf(true) }
    val focusRequester = remember { FocusRequester() }

    // Commercial skip state
    var currentCommercial by remember { mutableStateOf<CommercialInfo?>(null) }
    var showSkipButton by remember { mutableStateOf(false) }

    // Initialize player and load recording
    LaunchedEffect(recordingId, playbackMode) {
        mpvPlayer.initialize()
        viewModel.loadRecording(recordingId, playbackMode)
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

    // Seek to live (near end) for live mode
    LaunchedEffect(uiState.seekToLiveOnStart, duration) {
        if (uiState.seekToLiveOnStart && duration > 0) {
            // Seek to 10 seconds before the end to allow some buffer
            val livePosition = maxOf(0L, duration - 10000L)
            mpvPlayer.seekTo(livePosition)
        }
    }

    // Commercial detection and auto-skip
    LaunchedEffect(position, uiState.hasCommercials) {
        if (!uiState.hasCommercials) return@LaunchedEffect

        val commercial = viewModel.getCurrentCommercial(position)
        currentCommercial = commercial

        if (commercial != null) {
            showSkipButton = true

            // Auto-skip if enabled and not already skipped
            if (viewModel.shouldAutoSkip(commercial.index)) {
                // Small delay to show "Skipping..." briefly
                delay(500)
                viewModel.getSkipPosition(commercial.index)?.let { skipTo ->
                    mpvPlayer.seekTo(skipTo)
                }
            }
        } else {
            showSkipButton = false
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

        // Commercial skip button overlay (always visible during commercials if not auto-skipping)
        AnimatedVisibility(
            visible = showSkipButton && currentCommercial != null && !uiState.autoSkipEnabled,
            enter = slideInVertically { it } + fadeIn(),
            exit = slideOutVertically { it } + fadeOut(),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(32.dp)
        ) {
            CommercialSkipButton(
                remainingSeconds = currentCommercial?.remainingSeconds ?: 0,
                onSkip = {
                    currentCommercial?.let { commercial ->
                        viewModel.getSkipPosition(commercial.index)?.let { skipTo ->
                            mpvPlayer.seekTo(skipTo)
                        }
                    }
                }
            )
        }

        // Auto-skip indicator (brief flash when auto-skipping)
        AnimatedVisibility(
            visible = showSkipButton && currentCommercial != null && uiState.autoSkipEnabled,
            enter = fadeIn(),
            exit = fadeOut(),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(32.dp)
        ) {
            Box(
                modifier = Modifier
                    .background(OpenFlixColors.Primary, MaterialTheme.shapes.medium)
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Text(
                    text = "Skipping commercial...",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White
                )
            }
        }

        // Playback overlay
        AnimatedVisibility(
            visible = showOverlay && uiState.recording != null,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            DVRPlayerOverlay(
                title = uiState.recording?.displayTitle ?: "",
                subtitle = uiState.recording?.episodeInfo,
                channelName = uiState.recording?.channelName,
                thumbUrl = uiState.recording?.thumb,
                position = position,
                duration = duration,
                commercials = uiState.commercials,
                isPlaying = isPlaying,
                isLiveRecording = uiState.isLiveRecording,
                autoSkipEnabled = uiState.autoSkipEnabled,
                onPlayPause = { mpvPlayer.togglePlayPause() },
                onSeek = {
                    viewModel.resetSkippedCommercials()
                    mpvPlayer.seekTo(it)
                },
                onJumpToLive = {
                    // Jump to near the end (live edge)
                    if (duration > 10000) {
                        mpvPlayer.seekTo(duration - 5000)
                    }
                },
                onToggleAutoSkip = { viewModel.toggleAutoSkip() },
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
private fun CommercialSkipButton(
    remainingSeconds: Int,
    onSkip: () -> Unit
) {
    Button(
        onClick = onSkip,
        colors = ButtonDefaults.colors(
            containerColor = OpenFlixColors.Warning
        ),
        modifier = Modifier.height(56.dp)
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "Skip Ad",
                style = MaterialTheme.typography.titleMedium,
                color = Color.Black
            )
            Text(
                text = "${remainingSeconds}s remaining",
                style = MaterialTheme.typography.bodySmall,
                color = Color.Black.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun DVRPlayerOverlay(
    title: String,
    subtitle: String?,
    channelName: String?,
    thumbUrl: String?,
    position: Long,
    duration: Long,
    commercials: List<Commercial>,
    isPlaying: Boolean,
    isLiveRecording: Boolean,
    autoSkipEnabled: Boolean,
    onPlayPause: () -> Unit,
    onSeek: (Long) -> Unit,
    onJumpToLive: () -> Unit,
    onToggleAutoSkip: () -> Unit,
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

                // Thumbnail
                if (thumbUrl != null) {
                    AsyncImage(
                        model = thumbUrl,
                        contentDescription = null,
                        modifier = Modifier
                            .height(80.dp)
                            .aspectRatio(16f / 9f)
                            .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small)
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                }

                // Title & info
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = title,
                            style = MaterialTheme.typography.headlineMedium,
                            color = Color.White,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f, fill = false)
                        )
                        if (isLiveRecording) {
                            Spacer(modifier = Modifier.width(12.dp))
                            Box(
                                modifier = Modifier
                                    .background(OpenFlixColors.Error, MaterialTheme.shapes.extraSmall)
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Text("REC", style = MaterialTheme.typography.labelMedium, color = Color.White)
                            }
                        }
                    }
                    if (subtitle != null) {
                        Text(
                            text = subtitle,
                            style = MaterialTheme.typography.bodyLarge,
                            color = OpenFlixColors.TextSecondary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                    if (channelName != null) {
                        Text(
                            text = channelName,
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.TextTertiary,
                            maxLines = 1
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
                // Commercial info and auto-skip toggle
                if (commercials.isNotEmpty()) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(bottom = 8.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "${commercials.size} commercial break${if (commercials.size > 1) "s" else ""} detected",
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.Warning
                        )

                        Button(
                            onClick = onToggleAutoSkip,
                            colors = ButtonDefaults.colors(
                                containerColor = if (autoSkipEnabled) OpenFlixColors.Success else OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
                            ),
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp)
                        ) {
                            Text(
                                text = if (autoSkipEnabled) "Auto-Skip ON" else "Auto-Skip OFF",
                                style = MaterialTheme.typography.labelMedium
                            )
                        }
                    }
                }

                // Progress bar with commercial markers
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = formatTime(position),
                        style = MaterialTheme.typography.bodyMedium,
                        color = Color.White
                    )

                    ProgressBarWithCommercials(
                        modifier = Modifier
                            .weight(1f)
                            .padding(horizontal = 16.dp)
                            .height(6.dp),
                        position = position,
                        duration = duration,
                        commercials = commercials,
                        isLiveRecording = isLiveRecording
                    )

                    Text(
                        text = if (isLiveRecording) "LIVE" else formatTime(duration),
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (isLiveRecording) OpenFlixColors.Error else Color.White
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

                    Spacer(modifier = Modifier.width(16.dp))

                    // Play/Pause
                    Button(
                        onClick = onPlayPause,
                        colors = ButtonDefaults.colors(
                            containerColor = OpenFlixColors.Primary
                        )
                    ) {
                        Text(if (isPlaying) "Pause" else "Play")
                    }

                    Spacer(modifier = Modifier.width(16.dp))

                    // Forward 10s
                    Button(
                        onClick = { onSeek(minOf(duration, position + 10000)) },
                        colors = ButtonDefaults.colors(
                            containerColor = OpenFlixColors.SurfaceVariant.copy(alpha = 0.8f)
                        )
                    ) {
                        Text("+10s")
                    }

                    // Jump to Live button (only for active recordings)
                    if (isLiveRecording) {
                        Spacer(modifier = Modifier.width(24.dp))
                        Button(
                            onClick = onJumpToLive,
                            colors = ButtonDefaults.colors(
                                containerColor = OpenFlixColors.Error
                            )
                        ) {
                            Text("Jump to Live")
                        }
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

/**
 * Progress bar with commercial markers shown as yellow segments.
 */
@Composable
private fun ProgressBarWithCommercials(
    modifier: Modifier = Modifier,
    position: Long,
    duration: Long,
    commercials: List<Commercial>,
    isLiveRecording: Boolean
) {
    androidx.compose.foundation.layout.BoxWithConstraints(modifier = modifier) {
        val totalWidth = maxWidth

        // Background track
        Box(
            modifier = Modifier
                .fillMaxSize()
                .clip(MaterialTheme.shapes.small)
                .background(Color.White.copy(alpha = 0.3f))
        )

        // Commercial markers (yellow segments)
        if (duration > 0) {
            commercials.forEach { commercial ->
                val startFraction = (commercial.start.toFloat() / duration).coerceIn(0f, 1f)
                val endFraction = (commercial.end.toFloat() / duration).coerceIn(0f, 1f)
                val widthFraction = (endFraction - startFraction).coerceIn(0.005f, 1f) // Min width for visibility

                val startX = totalWidth * startFraction
                val segmentWidth = totalWidth * widthFraction

                Box(
                    modifier = Modifier
                        .offset(x = startX)
                        .width(segmentWidth.coerceAtLeast(2.dp))
                        .fillMaxHeight()
                        .background(OpenFlixColors.Warning)
                )
            }
        }

        // Progress indicator (on top)
        val progress = if (duration > 0) position.toFloat() / duration else 0f
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .fillMaxWidth(progress)
                .clip(MaterialTheme.shapes.small)
                .background(
                    if (isLiveRecording) OpenFlixColors.Error else OpenFlixColors.Primary
                )
        )
    }
}
