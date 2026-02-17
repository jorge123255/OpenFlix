package com.openflix.presentation.components.livetv

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.tv.material3.ClickableSurfaceDefaults
import androidx.tv.material3.Surface as TvSurface
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import java.text.SimpleDateFormat
import java.util.*

// Tivimate-style colors
private object PlayerColors {
    val Background = Color(0xFF0A0A0F)
    val Surface = Color(0xFF1A1A24)
    val SurfaceLight = Color(0xFF2A2A38)
    val Accent = Color(0xFF00D9FF)  // Cyan accent
    val AccentGold = Color(0xFFFFB800)
    val AccentRed = Color(0xFFFF3B5C)
    val AccentGreen = Color(0xFF10B981)
    val AccentPurple = Color(0xFF8B5CF6)  // For Start Over
    val AccentBlue = Color(0xFF3B82F6)
    val TextPrimary = Color.White
    val TextSecondary = Color(0xFFB0B0C0)
    val TextMuted = Color(0xFF707088)
}

/**
 * Tivimate-style player controls overlay for Live TV
 */
@Composable
fun LiveTVPlayerControls(
    channel: Channel,
    allChannels: List<Channel>,
    isFavorite: Boolean,
    isMuted: Boolean,
    isRecording: Boolean = false,
    isLive: Boolean = true,
    isPaused: Boolean = false,
    timeShiftOffset: String = "",
    isStartOverAvailable: Boolean = false,
    instantSwitchReady: Boolean = false,
    preBufferedChannelIds: Set<String> = emptySet(),
    modifier: Modifier = Modifier,
    onShowEPG: () -> Unit = {},
    onShowMultiview: () -> Unit = {},
    onShowMiniGuide: () -> Unit = {},
    onShowInfo: () -> Unit = {},
    onToggleFavorite: () -> Unit = {},
    onToggleMute: () -> Unit = {},
    onShowAudioTracks: () -> Unit = {},
    onShowSubtitles: () -> Unit = {},
    onQuickRecord: () -> Unit = {},
    onChannelSelected: (Channel) -> Unit = {},
    onTogglePause: () -> Unit = {},
    onSeekBack: () -> Unit = {},
    onSeekForward: () -> Unit = {},
    onGoLive: () -> Unit = {},
    onStartOver: () -> Unit = {},
    onCatchup: () -> Unit = {}
) {
    val nowPlaying = channel.nowPlaying
    val upNext = channel.upNext

    val pauseFocusRequester = remember { FocusRequester() }

    LaunchedEffect(Unit) {
        pauseFocusRequester.requestFocus()
    }

    Box(modifier = modifier.fillMaxSize()) {
        // Bottom gradient overlay
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .fillMaxHeight(0.5f)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            Color.Black.copy(alpha = 0.7f),
                            Color.Black.copy(alpha = 0.95f)
                        )
                    )
                )
        )

        // Main content
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(horizontal = 32.dp, vertical = 24.dp)
        ) {
            // Channel info row
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Channel logo
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .background(PlayerColors.Surface),
                    contentAlignment = Alignment.Center
                ) {
                    if (channel.logoUrl != null) {
                        AsyncImage(
                            model = channel.logoUrl,
                            contentDescription = null,
                            modifier = Modifier
                                .size(48.dp)
                                .clip(RoundedCornerShape(6.dp)),
                            contentScale = ContentScale.Fit
                        )
                    } else {
                        Text(
                            text = channel.number ?: channel.name.take(2),
                            color = Color.White,
                            fontSize = 18.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Spacer(modifier = Modifier.width(16.dp))

                // Channel name and program
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        channel.number?.let {
                            Text(
                                text = it,
                                color = PlayerColors.Accent,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                        }
                        Text(
                            text = channel.name,
                            color = Color.White,
                            fontSize = 16.sp,
                            fontWeight = FontWeight.SemiBold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    if (nowPlaying != null) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = nowPlaying.title,
                            color = Color.White,
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        // Progress bar
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
                            Text(
                                text = timeFormat.format(Date(nowPlaying.startTime * 1000)),
                                color = PlayerColors.TextSecondary,
                                fontSize = 12.sp
                            )

                            @Suppress("DEPRECATION")
                            LinearProgressIndicator(
                                progress = nowPlaying.progress,
                                modifier = Modifier
                                    .weight(1f)
                                    .height(3.dp)
                                    .padding(horizontal = 12.dp)
                                    .clip(RoundedCornerShape(2.dp)),
                                color = PlayerColors.Accent,
                                trackColor = PlayerColors.SurfaceLight
                            )

                            Text(
                                text = timeFormat.format(Date(nowPlaying.endTime * 1000)),
                                color = PlayerColors.TextSecondary,
                                fontSize = 12.sp
                            )
                        }
                    }
                }

                // Status badges row
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Live badge
                    if (isLive) {
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(PlayerColors.AccentRed)
                                .padding(horizontal = 10.dp, vertical = 4.dp)
                        ) {
                            Text(
                                text = "LIVE",
                                color = Color.White,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }

                    // Instant switch indicator
                    if (instantSwitchReady && preBufferedChannelIds.isNotEmpty()) {
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(PlayerColors.AccentGreen)
                                .padding(horizontal = 10.dp, vertical = 4.dp)
                        ) {
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    Icons.Default.FlashOn,
                                    contentDescription = "Instant Switch Ready",
                                    tint = Color.White,
                                    modifier = Modifier.size(12.dp)
                                )
                                Text(
                                    text = "INSTANT",
                                    color = Color.White,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }

                if (!isLive) {
                    TvSurface(
                        onClick = onGoLive,
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(4.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = PlayerColors.AccentGold,
                            focusedContainerColor = PlayerColors.AccentGold.copy(alpha = 0.8f)
                        )
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                        ) {
                            Icon(
                                Icons.Default.FastForward,
                                contentDescription = null,
                                tint = Color.Black,
                                modifier = Modifier.size(14.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "GO LIVE",
                                color = Color.Black,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Playback controls row (center)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Seek back
                PlaybackButton(
                    icon = Icons.Default.Replay10,
                    onClick = onSeekBack
                )

                Spacer(modifier = Modifier.width(24.dp))

                // Play/Pause (large)
                PlaybackButton(
                    icon = if (isPaused) Icons.Default.PlayArrow else Icons.Default.Pause,
                    isLarge = true,
                    focusRequester = pauseFocusRequester,
                    onClick = onTogglePause
                )

                Spacer(modifier = Modifier.width(24.dp))

                // Seek forward
                PlaybackButton(
                    icon = Icons.Default.Forward10,
                    onClick = onSeekForward
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Action buttons row (Tivimate-style pills)
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                ActionPill(
                    icon = Icons.Default.Info,
                    label = "Info",
                    shortcut = "I",
                    onClick = onShowInfo
                )

                ActionPill(
                    icon = if (isFavorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                    label = "Favorite",
                    shortcut = "F",
                    tint = if (isFavorite) PlayerColors.AccentRed else PlayerColors.TextSecondary,
                    onClick = onToggleFavorite
                )

                ActionPill(
                    icon = Icons.Default.FiberManualRecord,
                    label = "Record",
                    shortcut = "R",
                    tint = if (isRecording) PlayerColors.AccentRed else PlayerColors.TextSecondary,
                    onClick = onQuickRecord
                )

                // Start Over button - only show when available
                if (isStartOverAvailable) {
                    ActionPill(
                        icon = Icons.Default.Replay,
                        label = "Start Over",
                        shortcut = "S",
                        tint = PlayerColors.AccentPurple,
                        onClick = onStartOver
                    )
                }

                ActionPill(
                    icon = Icons.Default.Audiotrack,
                    label = "Audio",
                    shortcut = "A",
                    onClick = onShowAudioTracks
                )

                ActionPill(
                    icon = Icons.Default.ClosedCaption,
                    label = "Subs",
                    shortcut = "C",
                    onClick = onShowSubtitles
                )

                ActionPill(
                    icon = if (isMuted) Icons.Default.VolumeOff else Icons.Default.VolumeUp,
                    label = if (isMuted) "Unmute" else "Mute",
                    shortcut = "M",
                    onClick = onToggleMute
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Bottom quick access buttons
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                QuickAccessPill(
                    icon = Icons.Default.GridView,
                    label = "Guide",
                    color = PlayerColors.AccentPurple,
                    onClick = onShowEPG
                )

                Spacer(modifier = Modifier.width(12.dp))

                QuickAccessPill(
                    icon = Icons.Default.ViewModule,
                    label = "Multiview",
                    color = PlayerColors.AccentGreen,
                    onClick = onShowMultiview
                )

                Spacer(modifier = Modifier.width(12.dp))

                QuickAccessPill(
                    icon = Icons.Default.List,
                    label = "Channels",
                    color = PlayerColors.AccentBlue,
                    onClick = onShowMiniGuide
                )

                Spacer(modifier = Modifier.width(12.dp))

                QuickAccessPill(
                    icon = Icons.Default.History,
                    label = "Catch Up",
                    color = PlayerColors.AccentGold,
                    onClick = onCatchup
                )
            }
        }
    }
}

@Composable
private fun PlaybackButton(
    icon: ImageVector,
    isLarge: Boolean = false,
    focusRequester: FocusRequester? = null,
    onClick: () -> Unit
) {
    val size = if (isLarge) 64.dp else 48.dp
    val iconSize = if (isLarge) 32.dp else 24.dp

    TvSurface(
        onClick = onClick,
        modifier = Modifier
            .size(size)
            .then(if (focusRequester != null) Modifier.focusRequester(focusRequester) else Modifier),
        shape = ClickableSurfaceDefaults.shape(CircleShape),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isLarge) PlayerColors.Accent.copy(alpha = 0.2f) else PlayerColors.Surface,
            focusedContainerColor = if (isLarge) PlayerColors.Accent.copy(alpha = 0.4f) else PlayerColors.SurfaceLight
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = androidx.tv.material3.Border(
                border = BorderStroke(2.dp, PlayerColors.Accent),
                shape = CircleShape
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.1f)
    ) {
        Box(contentAlignment = Alignment.Center, modifier = Modifier.fillMaxSize()) {
            Icon(
                icon,
                contentDescription = null,
                tint = if (isLarge) PlayerColors.Accent else Color.White,
                modifier = Modifier.size(iconSize)
            )
        }
    }
}

@Composable
private fun ActionPill(
    icon: ImageVector,
    label: String,
    shortcut: String = "",
    tint: Color = PlayerColors.TextSecondary,
    onClick: () -> Unit
) {
    TvSurface(
        onClick = onClick,
        modifier = Modifier.padding(horizontal = 4.dp),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(20.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = PlayerColors.Surface.copy(alpha = 0.6f),
            focusedContainerColor = PlayerColors.Accent.copy(alpha = 0.3f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = androidx.tv.material3.Border(
                border = BorderStroke(2.dp, PlayerColors.Accent),
                shape = RoundedCornerShape(20.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp)
        ) {
            Icon(
                icon,
                contentDescription = label,
                tint = tint,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = label,
                color = PlayerColors.TextPrimary,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium
            )
            if (shortcut.isNotEmpty()) {
                Spacer(modifier = Modifier.width(6.dp))
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(4.dp))
                        .background(PlayerColors.TextMuted.copy(alpha = 0.3f))
                        .padding(horizontal = 5.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = shortcut,
                        color = PlayerColors.TextMuted,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
private fun QuickAccessPill(
    icon: ImageVector,
    label: String,
    color: Color,
    onClick: () -> Unit
) {
    TvSurface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(24.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = color.copy(alpha = 0.2f),
            focusedContainerColor = color.copy(alpha = 0.4f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = androidx.tv.material3.Border(
                border = BorderStroke(2.dp, color),
                shape = RoundedCornerShape(24.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.05f)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)
        ) {
            Icon(
                icon,
                contentDescription = label,
                tint = color,
                modifier = Modifier.size(20.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = label,
                color = Color.White,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

// Helper function for channel color
private fun getChannelColor(channelName: String): Color {
    val hash = channelName.hashCode()
    return when (hash % 6) {
        0 -> PlayerColors.AccentRed
        1 -> PlayerColors.AccentBlue
        2 -> PlayerColors.AccentGreen
        3 -> PlayerColors.AccentPurple
        4 -> PlayerColors.AccentGold
        else -> PlayerColors.Accent
    }
}
