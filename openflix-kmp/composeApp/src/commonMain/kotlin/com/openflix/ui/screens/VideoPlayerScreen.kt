package com.openflix.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.openflix.ui.player.VideoSurface
import com.openflix.ui.util.platformUsesNativePlayer
import com.openflix.ui.viewmodel.PlayerViewModel
import kotlinx.coroutines.delay
import org.koin.compose.viewmodel.koinViewModel

private val AccentPurple = Color(0xFF6138F5)

@Composable
fun VideoPlayerScreen(
    mediaKey: String = "",
    isRecording: Boolean = false,
    onBack: () -> Unit = {},
    viewModel: PlayerViewModel = koinViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val isPlaying by viewModel.player.isPlaying.collectAsState()
    val isBuffering by viewModel.player.isBuffering.collectAsState()
    val position by viewModel.player.position.collectAsState()
    val duration by viewModel.player.duration.collectAsState()

    LaunchedEffect(mediaKey) {
        if (mediaKey.isNotEmpty()) {
            if (isRecording) {
                viewModel.loadRecording(mediaKey)
            } else {
                viewModel.loadMedia(mediaKey)
            }
        }
    }

    // On iOS, the native player handles everything.
    // Wait for it to be dismissed, then navigate back.
    if (platformUsesNativePlayer) {
        LaunchedEffect(Unit) {
            // Wait for the native player to be dismissed by the user
            while (true) {
                delay(500)
                if (checkNativePlayerDismissed()) {
                    onBack()
                    break
                }
            }
        }

        // Just show black while the native player is on top
        Box(modifier = Modifier.fillMaxSize().background(Color.Black))
        return
    }

    DisposableEffect(Unit) {
        onDispose {
            viewModel.saveProgress()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() }
            ) { viewModel.toggleOverlay() }
    ) {
        // Video surface
        VideoSurface(
            player = viewModel.player,
            modifier = Modifier.fillMaxSize()
        )

        // Loading indicator
        if (uiState.isLoading || isBuffering) {
            CircularProgressIndicator(
                color = Color.White,
                modifier = Modifier
                    .size(48.dp)
                    .align(Alignment.Center),
                strokeWidth = 3.dp
            )
        }

        // Error overlay
        uiState.error?.let { error ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black.copy(alpha = 0.9f)),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Warning,
                        contentDescription = null,
                        tint = Color(0xFFFFD700),
                        modifier = Modifier.size(48.dp)
                    )
                    Text(error, color = Color.White, fontSize = 16.sp)
                    Button(
                        onClick = onBack,
                        colors = ButtonDefaults.buttonColors(containerColor = Color.White.copy(alpha = 0.2f))
                    ) {
                        Text("Close", color = Color.White)
                    }
                }
            }
        }

        // Controls overlay
        AnimatedVisibility(
            visible = uiState.showOverlay && uiState.error == null,
            enter = fadeIn(),
            exit = fadeOut()
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Black.copy(alpha = 0.8f),
                                Color.Transparent,
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.8f)
                            )
                        )
                    )
            ) {
                // Top bar
                VODTopBar(
                    title = uiState.title,
                    subtitle = uiState.subtitle,
                    playbackSpeed = uiState.playbackSpeed,
                    isRecording = isRecording,
                    onClose = {
                        viewModel.saveProgress()
                        onBack()
                    },
                    onCycleSpeed = { viewModel.cycleSpeed() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .statusBarsPadding()
                        .padding(horizontal = 20.dp, vertical = 12.dp)
                        .align(Alignment.TopCenter)
                )

                // Center controls - large circular buttons
                VODCenterControls(
                    isPlaying = isPlaying,
                    onSkipBack = { viewModel.skipBack() },
                    onPlayPause = { viewModel.togglePlayPause() },
                    onSkipForward = { viewModel.skipForward() },
                    modifier = Modifier.align(Alignment.Center)
                )

                // Bottom bar with progress
                VODBottomBar(
                    title = uiState.title,
                    subtitle = uiState.subtitle,
                    position = position,
                    duration = duration,
                    onSeek = { viewModel.seekTo(it) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .align(Alignment.BottomCenter)
                        .navigationBarsPadding()
                        .padding(horizontal = 20.dp, vertical = 16.dp)
                )
            }
        }
    }
}

@Composable
private fun VODTopBar(
    title: String,
    subtitle: String,
    playbackSpeed: Float,
    isRecording: Boolean,
    onClose: () -> Unit,
    onCycleSpeed: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Close button - circular
        IconButton(
            onClick = onClose,
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(Color.Black.copy(alpha = 0.6f))
        ) {
            Icon(
                imageVector = if (isRecording) Icons.Default.ArrowBack else Icons.Default.Close,
                contentDescription = "Close",
                tint = Color.White,
                modifier = Modifier.size(20.dp)
            )
        }

        // Speed button - circular
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(Color.Black.copy(alpha = 0.4f))
                .clickable(onClick = onCycleSpeed),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "${playbackSpeed}x",
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }

        Spacer(modifier = Modifier.weight(1f))
    }
}

@Composable
private fun VODCenterControls(
    isPlaying: Boolean,
    onSkipBack: () -> Unit,
    onPlayPause: () -> Unit,
    onSkipForward: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(60.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Skip back 10s - circular
        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(Color.Black.copy(alpha = 0.6f))
                .clickable(onClick = onSkipBack),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector = Icons.Default.Refresh,
                    contentDescription = "Skip back 10 seconds",
                    tint = Color.White,
                    modifier = Modifier.size(22.dp)
                )
                Text("10", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.White)
            }
        }

        // Play/Pause - large circular
        Box(
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.2f))
                .clickable(onClick = onPlayPause),
            contentAlignment = Alignment.Center
        ) {
            if (isPlaying) {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(modifier = Modifier.width(9.dp).height(40.dp).background(Color.White))
                    Box(modifier = Modifier.width(9.dp).height(40.dp).background(Color.White))
                }
            } else {
                Icon(
                    imageVector = Icons.Default.PlayArrow,
                    contentDescription = "Play",
                    tint = Color.White,
                    modifier = Modifier.size(52.dp)
                )
            }
        }

        // Skip forward 10s - circular
        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(Color.Black.copy(alpha = 0.6f))
                .clickable(onClick = onSkipForward),
            contentAlignment = Alignment.Center
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector = Icons.Default.Refresh,
                    contentDescription = "Skip forward 10 seconds",
                    tint = Color.White,
                    modifier = Modifier.size(22.dp)
                )
                Text("10", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.White)
            }
        }
    }
}

@Composable
private fun VODBottomBar(
    title: String,
    subtitle: String,
    position: Long,
    duration: Long,
    onSeek: (Long) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Title section
        if (title.isNotEmpty()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(modifier = Modifier.weight(1f)) {
                    if (subtitle.isNotEmpty()) {
                        Text(
                            text = subtitle,
                            fontSize = 13.sp,
                            color = Color.White.copy(alpha = 0.7f)
                        )
                    }
                    Text(
                        text = title,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }

        // Progress bar with slider
        if (duration > 0) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                // Slider
                Slider(
                    value = position.toFloat(),
                    onValueChange = { onSeek(it.toLong()) },
                    valueRange = 0f..duration.toFloat(),
                    colors = SliderDefaults.colors(
                        thumbColor = Color.White,
                        activeTrackColor = Color.White,
                        inactiveTrackColor = Color.White.copy(alpha = 0.3f)
                    ),
                    modifier = Modifier.fillMaxWidth()
                )

                // Time labels
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = formatDuration(position),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color.White
                    )
                    Text(
                        text = "-${formatDuration(duration - position)}",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color.White
                    )
                }
            }
        }

        // Quick actions row
        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Info button
            TextButton(
                onClick = { },
                colors = ButtonDefaults.textButtonColors(contentColor = Color.White)
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .clip(RoundedCornerShape(8.dp))
                        .background(Color.Black.copy(alpha = 0.3f))
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Info,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                        tint = Color.White
                    )
                    Text("Info", fontSize = 13.sp, color = Color.White)
                }
            }
        }
    }
}

private fun formatDuration(ms: Long): String {
    val totalSeconds = (ms / 1000).coerceAtLeast(0)
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60
    return if (hours > 0) {
        "${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}"
    } else {
        "${minutes}:${seconds.toString().padStart(2, '0')}"
    }
}
