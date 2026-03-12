package com.openflix.presentation.components.player

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.VolumeOff
import androidx.compose.material.icons.automirrored.filled.VolumeUp
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.openflix.presentation.theme.OpenFlixColors
import kotlinx.coroutines.delay

/**
 * Unified touch-friendly player controls overlay for tablet/phone.
 * Matches iOS LiveChannelPlayerView / VideoPlayerView design:
 * - Top bar: Close, Channel logo + name + number, Volume
 * - Center: Large circular Skip Back / Play-Pause / Skip Forward
 * - Bottom: LIVE badge + time, action bar (CH-/CH+/Record/Aspect/Audio/Subs/Sleep)
 */
@Composable
fun TabletPlayerControls(
    title: String,
    subtitle: String? = null,
    isPlaying: Boolean,
    position: Long, // millis
    duration: Long, // millis
    isLive: Boolean = false,
    channelName: String? = null,
    channelNumber: String? = null,
    channelLogo: String? = null,
    nowPlayingTitle: String? = null,
    isMuted: Boolean = false,
    isRecording: Boolean = false,
    playbackSpeed: Float = 1.0f,
    onPlayPause: () -> Unit,
    onSeekTo: (Long) -> Unit,
    onSeekRelative: (Int) -> Unit, // seconds
    onBack: () -> Unit,
    onToggleMute: () -> Unit = {},
    // Live TV specific callbacks
    onChannelUp: () -> Unit = {},
    onChannelDown: () -> Unit = {},
    onRecord: () -> Unit = {},
    // Shared player callbacks (used by both Live TV and VOD)
    onCycleAspectRatio: () -> Unit = {},
    onCycleAudioTrack: () -> Unit = {},
    onCycleSubtitleTrack: () -> Unit = {},
    onSleepTimer: () -> Unit = {},
    onCyclePlaybackSpeed: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    var showControls by remember { mutableStateOf(true) }
    var isScrubbing by remember { mutableStateOf(false) }
    var scrubProgress by remember { mutableFloatStateOf(0f) }

    // Auto-hide controls after 5s (unless scrubbing or paused)
    LaunchedEffect(showControls, isPlaying, isScrubbing) {
        if (showControls && isPlaying && !isScrubbing) {
            delay(5000)
            showControls = false
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        // Tap target - covers entire screen
        Box(
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(Unit) {
                    detectTapGestures(
                        onTap = { showControls = !showControls }
                    )
                }
        )

        // Controls overlay
        AnimatedVisibility(
            visible = showControls,
            enter = fadeIn(animationSpec = androidx.compose.animation.core.tween(200)),
            exit = fadeOut(animationSpec = androidx.compose.animation.core.tween(200)),
            modifier = Modifier.fillMaxSize()
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            colors = listOf(
                                Color.Black.copy(alpha = 0.7f),
                                Color.Transparent,
                                Color.Transparent,
                                Color.Black.copy(alpha = 0.7f)
                            )
                        )
                    )
                    .pointerInput(Unit) {
                        detectTapGestures(
                            onTap = { showControls = false }
                        )
                    }
            ) {
                // Top bar
                TopBar(
                    channelName = channelName,
                    channelNumber = channelNumber,
                    channelLogo = channelLogo,
                    isLive = isLive,
                    isMuted = isMuted,
                    onBack = onBack,
                    onToggleMute = onToggleMute,
                    modifier = Modifier
                        .align(Alignment.TopCenter)
                        .fillMaxWidth()
                        .statusBarsPadding()
                        .padding(horizontal = 24.dp, vertical = 16.dp)
                )

                // Center controls
                CenterControls(
                    isPlaying = isPlaying,
                    onPlayPause = onPlayPause,
                    onSeekBack = { onSeekRelative(-10) },
                    onSeekForward = { onSeekRelative(10) },
                    modifier = Modifier.align(Alignment.Center)
                )

                // Bottom section
                Column(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .navigationBarsPadding()
                        .padding(horizontal = 24.dp, vertical = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    if (isLive) {
                        // Live TV bottom: LIVE badge + time row
                        LiveInfoRow(position = position)

                        // Action bar: CH- CH+ Record Aspect Audio Subs Sleep
                        LiveActionBar(
                            isRecording = isRecording,
                            onChannelDown = onChannelDown,
                            onChannelUp = onChannelUp,
                            onRecord = onRecord,
                            onCycleAspectRatio = onCycleAspectRatio,
                            onCycleAudioTrack = onCycleAudioTrack,
                            onCycleSubtitleTrack = onCycleSubtitleTrack,
                            onSleepTimer = onSleepTimer
                        )
                    } else {
                        // VOD bottom: Title + progress scrubber + action bar
                        VODBottomBar(
                            title = title,
                            subtitle = subtitle,
                            position = position,
                            duration = duration,
                            isScrubbing = isScrubbing,
                            scrubProgress = scrubProgress,
                            onScrubStart = { progress ->
                                isScrubbing = true
                                scrubProgress = progress
                            },
                            onScrubChange = { progress ->
                                scrubProgress = progress
                            },
                            onScrubEnd = { progress ->
                                isScrubbing = false
                                if (duration > 0) {
                                    onSeekTo((progress * duration).toLong())
                                }
                            }
                        )

                        // VOD action bar: Speed, Aspect, Audio, Subs, Sleep
                        VODActionBar(
                            playbackSpeed = playbackSpeed,
                            onCyclePlaybackSpeed = onCyclePlaybackSpeed,
                            onCycleAspectRatio = onCycleAspectRatio,
                            onCycleAudioTrack = onCycleAudioTrack,
                            onCycleSubtitleTrack = onCycleSubtitleTrack,
                            onSleepTimer = onSleepTimer
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Top Bar (matches iOS: X button | logo + name + CH # | volume)

@Composable
private fun TopBar(
    channelName: String?,
    channelNumber: String?,
    channelLogo: String?,
    isLive: Boolean,
    isMuted: Boolean,
    onBack: () -> Unit,
    onToggleMute: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Close button (X circle, matching iOS)
        ControlCircleButton(
            icon = Icons.Default.Close,
            contentDescription = "Close",
            size = 44,
            onClick = onBack
        )

        // Center: Channel info (for live TV) or empty
        if (isLive && channelName != null) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Channel logo
                channelLogo?.let { logo ->
                    AsyncImage(
                        model = logo,
                        contentDescription = null,
                        modifier = Modifier
                            .size(28.dp)
                            .clip(RoundedCornerShape(4.dp)),
                        contentScale = ContentScale.Fit
                    )
                }

                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = channelName,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1
                    )
                    channelNumber?.let { num ->
                        Text(
                            text = "CH $num",
                            fontSize = 12.sp,
                            color = Color.White.copy(alpha = 0.6f)
                        )
                    }
                }
            }
        } else {
            Spacer(modifier = Modifier.width(1.dp))
        }

        // Volume button
        ControlCircleButton(
            icon = if (isMuted) Icons.AutoMirrored.Filled.VolumeOff else Icons.AutoMirrored.Filled.VolumeUp,
            contentDescription = if (isMuted) "Unmute" else "Mute",
            size = 40,
            iconColor = if (isMuted) Color.Red else Color.White,
            onClick = onToggleMute
        )
    }
}

// MARK: - Center Controls (iOS-style large circular buttons)

@Composable
private fun CenterControls(
    isPlaying: Boolean,
    onPlayPause: () -> Unit,
    onSeekBack: () -> Unit,
    onSeekForward: () -> Unit,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(64.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Skip back 10s
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(Color.Black.copy(alpha = 0.6f))
                .clickable(onClick = onSeekBack),
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.Replay10,
                contentDescription = "Skip back 10 seconds",
                tint = Color.White,
                modifier = Modifier.size(36.dp)
            )
        }

        // Play/Pause (larger)
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.2f))
                .clickable(onClick = onPlayPause),
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                contentDescription = if (isPlaying) "Pause" else "Play",
                tint = Color.White,
                modifier = Modifier.size(52.dp)
            )
        }

        // Skip forward 10s
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(Color.Black.copy(alpha = 0.6f))
                .clickable(onClick = onSeekForward),
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.Forward10,
                contentDescription = "Skip forward 10 seconds",
                tint = Color.White,
                modifier = Modifier.size(36.dp)
            )
        }
    }
}

// MARK: - Live TV Info Row (LIVE badge + time)

@Composable
private fun LiveInfoRow(
    position: Long // millis
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        // LIVE badge (red dot + text)
        Row(
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(OpenFlixColors.LiveIndicator)
            )
            Text(
                text = "LIVE",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = OpenFlixColors.LiveIndicator
            )
        }

        // Time display
        Text(
            text = formatTime(position),
            fontSize = 14.sp,
            color = Color.White.copy(alpha = 0.7f)
        )
    }
}

// MARK: - Live TV Action Bar (CH-/CH+/Record/Aspect/Audio/Subs/Sleep)

@Composable
private fun LiveActionBar(
    isRecording: Boolean,
    onChannelDown: () -> Unit,
    onChannelUp: () -> Unit,
    onRecord: () -> Unit,
    onCycleAspectRatio: () -> Unit,
    onCycleAudioTrack: () -> Unit,
    onCycleSubtitleTrack: () -> Unit,
    onSleepTimer: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically
    ) {
        ActionBarButton(
            icon = Icons.Default.KeyboardArrowDown,
            label = "CH-",
            onClick = onChannelDown
        )
        ActionBarButton(
            icon = Icons.Default.KeyboardArrowUp,
            label = "CH+",
            onClick = onChannelUp
        )
        ActionBarButton(
            icon = Icons.Default.FiberManualRecord,
            label = "Record",
            iconColor = if (isRecording) OpenFlixColors.LiveIndicator else Color.White,
            onClick = onRecord
        )
        ActionBarButton(
            icon = Icons.Default.AspectRatio,
            label = "Aspect",
            onClick = onCycleAspectRatio
        )
        ActionBarButton(
            icon = Icons.Default.Equalizer,
            label = "Audio",
            onClick = onCycleAudioTrack
        )
        ActionBarButton(
            icon = Icons.Default.Subtitles,
            label = "Subs",
            onClick = onCycleSubtitleTrack
        )
        ActionBarButton(
            icon = Icons.Default.Bedtime,
            label = "Sleep",
            onClick = onSleepTimer
        )
    }
}

// MARK: - VOD Action Bar (Speed/Aspect/Audio/Subs/Sleep)

@Composable
private fun VODActionBar(
    playbackSpeed: Float,
    onCyclePlaybackSpeed: () -> Unit,
    onCycleAspectRatio: () -> Unit,
    onCycleAudioTrack: () -> Unit,
    onCycleSubtitleTrack: () -> Unit,
    onSleepTimer: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically
    ) {
        ActionBarButton(
            icon = Icons.Default.Speed,
            label = if (playbackSpeed == 1.0f) "Speed" else "${playbackSpeed}x",
            onClick = onCyclePlaybackSpeed
        )
        ActionBarButton(
            icon = Icons.Default.AspectRatio,
            label = "Aspect",
            onClick = onCycleAspectRatio
        )
        ActionBarButton(
            icon = Icons.Default.Equalizer,
            label = "Audio",
            onClick = onCycleAudioTrack
        )
        ActionBarButton(
            icon = Icons.Default.Subtitles,
            label = "Subs",
            onClick = onCycleSubtitleTrack
        )
        ActionBarButton(
            icon = Icons.Default.Bedtime,
            label = "Sleep",
            onClick = onSleepTimer
        )
    }
}

@Composable
private fun ActionBarButton(
    icon: ImageVector,
    label: String,
    iconColor: Color = Color.White,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 6.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = iconColor,
            modifier = Modifier.size(24.dp)
        )
        Text(
            text = label,
            fontSize = 10.sp,
            color = Color.White.copy(alpha = 0.7f),
            textAlign = TextAlign.Center
        )
    }
}

// MARK: - VOD Bottom Bar (title + progress scrubber)

@Composable
private fun VODBottomBar(
    title: String,
    subtitle: String?,
    position: Long,
    duration: Long,
    isScrubbing: Boolean,
    scrubProgress: Float,
    onScrubStart: (Float) -> Unit,
    onScrubChange: (Float) -> Unit,
    onScrubEnd: (Float) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        // Title section
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    fontSize = 14.sp,
                    color = Color.White.copy(alpha = 0.7f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
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

        // Progress bar with scrubber
        if (duration > 0) {
            ProgressScrubber(
                position = position,
                duration = duration,
                isScrubbing = isScrubbing,
                scrubProgress = scrubProgress,
                onScrubStart = onScrubStart,
                onScrubChange = onScrubChange,
                onScrubEnd = onScrubEnd
            )
        }
    }
}

// MARK: - Progress Scrubber (drag-to-seek, matching iOS)

@Composable
private fun ProgressScrubber(
    position: Long,
    duration: Long,
    isScrubbing: Boolean,
    scrubProgress: Float,
    onScrubStart: (Float) -> Unit,
    onScrubChange: (Float) -> Unit,
    onScrubEnd: (Float) -> Unit
) {
    val progress = if (duration > 0) (position.toFloat() / duration).coerceIn(0f, 1f) else 0f
    val displayProgress = if (isScrubbing) scrubProgress else progress
    val displayPosition = if (isScrubbing) (scrubProgress * duration).toLong() else position

    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Current time
        Text(
            text = formatTime(displayPosition),
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = Color.White,
            modifier = Modifier.width(56.dp)
        )

        // Progress bar with drag
        var barSize by remember { mutableStateOf(IntSize.Zero) }

        Box(
            modifier = Modifier
                .weight(1f)
                .height(44.dp)
                .onSizeChanged { barSize = it }
                .pointerInput(Unit) {
                    detectDragGestures(
                        onDragStart = { offset ->
                            val fraction = (offset.x / size.width).coerceIn(0f, 1f)
                            onScrubStart(fraction)
                        },
                        onDrag = { change, _ ->
                            val fraction = (change.position.x / size.width).coerceIn(0f, 1f)
                            onScrubChange(fraction)
                        },
                        onDragEnd = {
                            onScrubEnd(scrubProgress)
                        },
                        onDragCancel = {
                            onScrubEnd(scrubProgress)
                        }
                    )
                }
                .pointerInput(Unit) {
                    detectTapGestures { offset ->
                        val fraction = (offset.x / size.width).coerceIn(0f, 1f)
                        onScrubEnd(fraction)
                    }
                },
            contentAlignment = Alignment.CenterStart
        ) {
            // Track background
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(if (isScrubbing) 6.dp else 4.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(Color.White.copy(alpha = 0.3f))
            )

            // Progress fill
            Box(
                modifier = Modifier
                    .fillMaxWidth(displayProgress)
                    .height(if (isScrubbing) 6.dp else 4.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(Color.White)
            )

            // Scrubber dot
            if (barSize.width > 0) {
                val density = LocalDensity.current
                val dotSize = if (isScrubbing) 20.dp else 14.dp
                val dotSizePx = with(density) { dotSize.toPx() }
                val offsetX = displayProgress * barSize.width - dotSizePx / 2

                Box(
                    modifier = Modifier
                        .offset(x = with(density) { offsetX.toDp() })
                        .size(dotSize)
                        .clip(CircleShape)
                        .background(Color.White)
                )
            }
        }

        // Remaining time
        val remaining = if (duration > 0) duration - displayPosition else 0L
        Text(
            text = "-${formatTime(remaining)}",
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = Color.White,
            modifier = Modifier.width(64.dp)
        )
    }
}

// MARK: - Helper Composables

@Composable
private fun ControlCircleButton(
    icon: ImageVector,
    contentDescription: String,
    size: Int,
    iconColor: Color = Color.White,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .size(size.dp)
            .clip(CircleShape)
            .background(Color.Black.copy(alpha = 0.6f))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = iconColor,
            modifier = Modifier.size((size * 0.5f).dp)
        )
    }
}

// MARK: - Time Formatting

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
