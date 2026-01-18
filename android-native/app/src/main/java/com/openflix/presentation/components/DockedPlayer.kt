package com.openflix.presentation.components

import android.view.SurfaceView
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.*
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.player.LiveTVPlayer
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay
import timber.log.Timber

/**
 * DirecTV-style docked player for the home screen.
 * Auto-plays the last watched channel in a compact preview.
 * Similar to DirecTV's home screen that shows live TV in corner.
 */
@Composable
fun DockedPlayer(
    channel: Channel?,
    liveTVPlayer: LiveTVPlayer,
    isVisible: Boolean = true,
    onExpandToFullscreen: () -> Unit,
    onChannelChange: (Channel) -> Unit = {},
    modifier: Modifier = Modifier
) {
    if (!isVisible || channel == null || channel.streamUrl == null) {
        return
    }

    var isFocused by remember { mutableStateOf(false) }
    var showControls by remember { mutableStateOf(false) }
    val focusRequester = remember { FocusRequester() }

    // Auto-hide controls after 3 seconds
    LaunchedEffect(showControls) {
        if (showControls) {
            delay(3000)
            showControls = false
        }
    }

    // Player states
    val isPlaying by liveTVPlayer.isPlaying.collectAsState()
    val isBuffering by liveTVPlayer.isBuffering.collectAsState()
    val isMuted by liveTVPlayer.isMuted.collectAsState()
    val error by liveTVPlayer.error.collectAsState()

    // Initialize and play on mount
    LaunchedEffect(channel.streamUrl) {
        Timber.d("DockedPlayer: Starting playback of ${channel.name}")
        liveTVPlayer.initialize()
        liveTVPlayer.setMuted(true) // Start muted
        liveTVPlayer.play(channel.streamUrl!!)
    }

    // Focus border animation
    val borderAlpha by animateFloatAsState(
        targetValue = if (isFocused) 1f else 0f,
        label = "borderAlpha"
    )

    Surface(
        onClick = {
            showControls = !showControls
        },
        modifier = modifier
            .fillMaxWidth()
            .height(200.dp)
            .focusRequester(focusRequester)
            .onFocusChanged {
                isFocused = it.isFocused
                if (it.isFocused) showControls = true
            }
            .onPreviewKeyEvent { event ->
                if (event.type == KeyEventType.KeyDown) {
                    when (event.key) {
                        Key.Enter, Key.DirectionCenter -> {
                            onExpandToFullscreen()
                            true
                        }
                        Key.M, Key.VolumeMute -> {
                            liveTVPlayer.toggleMute()
                            showControls = true
                            true
                        }
                        Key.Spacebar -> {
                            liveTVPlayer.togglePlayPause()
                            showControls = true
                            true
                        }
                        else -> false
                    }
                } else false
            },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(16.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = Color.Black,
            focusedContainerColor = Color.Black
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(3.dp, OpenFlixColors.Primary),
                shape = RoundedCornerShape(16.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            // Video Surface
            AndroidView(
                factory = { context ->
                    SurfaceView(context).also { surface ->
                        liveTVPlayer.setSurfaceView(surface)
                    }
                },
                modifier = Modifier.fillMaxSize(),
                onRelease = {
                    // Don't release the player, just detach surface
                    liveTVPlayer.setSurfaceView(null)
                }
            )

            // Buffering indicator
            if (isBuffering) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.5f)),
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(OpenFlixColors.Primary.copy(alpha = 0.3f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Box(
                            modifier = Modifier
                                .size(24.dp)
                                .clip(CircleShape)
                                .background(OpenFlixColors.Primary)
                        )
                    }
                }
            }

            // Error overlay
            if (error != null) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.8f)),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Error,
                            contentDescription = null,
                            tint = OpenFlixColors.Error,
                            modifier = Modifier.size(32.dp)
                        )
                        Text(
                            text = "Unable to play",
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.TextPrimary
                        )
                    }
                }
            }

            // Gradient overlays
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Black.copy(alpha = 0.6f),
                                Color.Transparent,
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.8f)
                            ),
                            startY = 0f,
                            endY = Float.POSITIVE_INFINITY
                        )
                    )
            )

            // LIVE Badge
            Box(
                modifier = Modifier
                    .padding(12.dp)
                    .align(Alignment.TopStart)
                    .background(Color.Red, RoundedCornerShape(4.dp))
                    .padding(horizontal = 8.dp, vertical = 4.dp)
            ) {
                Text(
                    text = "LIVE",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    letterSpacing = 1.sp
                )
            }

            // Mute indicator
            if (isMuted) {
                Box(
                    modifier = Modifier
                        .padding(12.dp)
                        .align(Alignment.TopEnd)
                        .background(Color.Black.copy(alpha = 0.6f), CircleShape)
                        .padding(6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.VolumeOff,
                        contentDescription = "Muted",
                        tint = Color.White,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            // Bottom info bar
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomCenter)
                    .padding(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Channel logo
                channel.logoUrl?.let { logoUrl ->
                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(Color.White)
                            .padding(4.dp)
                    ) {
                        AsyncImage(
                            model = logoUrl,
                            contentDescription = channel.name,
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Fit
                        )
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                }

                // Channel info
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = channel.displayName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    channel.nowPlaying?.let { program ->
                        Text(
                            text = program.title,
                            style = MaterialTheme.typography.bodySmall,
                            color = Color.White.copy(alpha = 0.8f),
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }

                // Control buttons (visible on focus)
                AnimatedVisibility(
                    visible = showControls || isFocused,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        // Mute button
                        IconButton(
                            onClick = { liveTVPlayer.toggleMute() }
                        ) {
                            Icon(
                                imageVector = if (isMuted) Icons.Filled.VolumeOff else Icons.Filled.VolumeUp,
                                contentDescription = if (isMuted) "Unmute" else "Mute",
                                tint = Color.White
                            )
                        }
                        // Fullscreen button
                        IconButton(
                            onClick = onExpandToFullscreen
                        ) {
                            Icon(
                                imageVector = Icons.Filled.Fullscreen,
                                contentDescription = "Fullscreen",
                                tint = Color.White
                            )
                        }
                    }
                }
            }

            // Now playing progress bar
            channel.nowPlaying?.let { program ->
                val progress = program.progress
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(3.dp)
                        .align(Alignment.BottomCenter)
                        .background(Color.White.copy(alpha = 0.3f))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxHeight()
                            .fillMaxWidth(progress)
                            .background(OpenFlixColors.Primary)
                    )
                }
            }
        }
    }
}
