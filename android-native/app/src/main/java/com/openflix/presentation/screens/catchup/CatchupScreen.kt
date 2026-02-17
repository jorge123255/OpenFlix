package com.openflix.presentation.screens.catchup

import androidx.compose.animation.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.ArchiveProgram
import com.openflix.domain.model.Channel
import com.openflix.presentation.theme.OpenFlixColors
import java.text.SimpleDateFormat
import java.util.*

// Theme colors for Catchup screen
private object CatchupTheme {
    val Background = Color(0xFF0D0D0D)
    val Surface = Color(0xFF1A1A1A)
    val SurfaceElevated = Color(0xFF242424)
    val Accent = Color(0xFF8B5CF6)  // Purple for catch-up
    val AccentGlow = Color(0xFFA78BFA)
    val TextPrimary = Color.White
    val TextSecondary = Color(0xFFB0B0B0)
    val TextMuted = Color(0xFF666666)
    val Divider = Color(0xFF2A2A2A)
}

/**
 * Catch-up TV Screen - Browse and watch archived programs from channels that support catch-up.
 */
@Composable
fun CatchupScreen(
    onBack: () -> Unit,
    onPlayProgram: (channelId: String, startTime: Long) -> Unit,
    viewModel: CatchupViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val filteredPrograms = remember(uiState.archivedPrograms, uiState.selectedDayOffset) {
        viewModel.getFilteredPrograms()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CatchupTheme.Background)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Header
            CatchupHeader(onBack = onBack)

            if (uiState.isLoading) {
                // Loading state
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        // Simple loading dot animation
                        Text(
                            text = "● ● ●",
                            color = CatchupTheme.Accent,
                            fontSize = 24.sp
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Loading catch-up channels...",
                            color = CatchupTheme.TextSecondary
                        )
                    }
                }
            } else if (uiState.error != null) {
                // Error state
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            Icons.Default.Error,
                            contentDescription = null,
                            tint = Color.Red,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = uiState.error!!,
                            color = CatchupTheme.TextSecondary
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.refresh() }) {
                            Text("Retry")
                        }
                    }
                }
            } else if (!uiState.hasChannels) {
                // No channels with catch-up
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(32.dp)
                    ) {
                        Icon(
                            Icons.Default.History,
                            contentDescription = null,
                            tint = CatchupTheme.TextMuted,
                            modifier = Modifier.size(64.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "No Catch-up Channels",
                            style = MaterialTheme.typography.headlineSmall,
                            color = CatchupTheme.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "No channels have catch-up TV enabled. Contact your TV provider or enable timeshift recording in server settings.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = CatchupTheme.TextSecondary,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            } else {
                // Main content
                Row(modifier = Modifier.fillMaxSize()) {
                    // Left sidebar - Channel list
                    ChannelSidebar(
                        channels = uiState.channels,
                        selectedChannel = uiState.selectedChannel,
                        onChannelSelect = { viewModel.selectChannel(it) },
                        modifier = Modifier
                            .width(280.dp)
                            .fillMaxHeight()
                    )

                    // Divider
                    Box(
                        modifier = Modifier
                            .width(1.dp)
                            .fillMaxHeight()
                            .background(CatchupTheme.Divider)
                    )

                    // Right content - Programs list
                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .fillMaxHeight()
                    ) {
                        // Day filter tabs
                        DayFilterTabs(
                            dayOptions = uiState.dayOptions,
                            selectedDayOffset = uiState.selectedDayOffset,
                            onDaySelect = { viewModel.filterByDate(it) }
                        )

                        // Programs list
                        if (uiState.isLoadingPrograms) {
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(
                                    text = "● ● ●",
                                    color = CatchupTheme.Accent,
                                    fontSize = 24.sp
                                )
                            }
                        } else if (filteredPrograms.isEmpty()) {
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Icon(
                                        Icons.Default.VideoLibrary,
                                        contentDescription = null,
                                        tint = CatchupTheme.TextMuted,
                                        modifier = Modifier.size(48.dp)
                                    )
                                    Spacer(modifier = Modifier.height(16.dp))
                                    Text(
                                        text = "No programs available",
                                        style = MaterialTheme.typography.titleMedium,
                                        color = CatchupTheme.TextSecondary
                                    )
                                    Text(
                                        text = "Try selecting a different day",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = CatchupTheme.TextMuted
                                    )
                                }
                            }
                        } else {
                            ProgramsList(
                                programs = filteredPrograms,
                                channel = uiState.selectedChannel,
                                onProgramClick = { program ->
                                    uiState.selectedChannel?.let { channel ->
                                        onPlayProgram(channel.id, program.startTime)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CatchupHeader(onBack: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        CatchupTheme.Background,
                        CatchupTheme.Background.copy(alpha = 0.95f)
                    )
                )
            )
            .padding(horizontal = 24.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Back button
        Surface(
            onClick = onBack,
            shape = ClickableSurfaceDefaults.shape(CircleShape),
            colors = ClickableSurfaceDefaults.colors(
                containerColor = CatchupTheme.Surface,
                focusedContainerColor = CatchupTheme.Accent.copy(alpha = 0.3f)
            ),
            border = ClickableSurfaceDefaults.border(
                focusedBorder = Border(
                    border = BorderStroke(2.dp, CatchupTheme.Accent),
                    shape = CircleShape
                )
            )
        ) {
            Icon(
                Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint = CatchupTheme.TextPrimary,
                modifier = Modifier.padding(12.dp)
            )
        }

        Spacer(modifier = Modifier.width(20.dp))

        // Title with badge
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .background(CatchupTheme.Accent, RoundedCornerShape(6.dp))
                    .padding(horizontal = 12.dp, vertical = 6.dp)
            ) {
                Text(
                    text = "CATCH-UP TV",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            Text(
                text = "Watch past programs",
                style = MaterialTheme.typography.bodyLarge,
                color = CatchupTheme.TextSecondary
            )
        }
    }
}

@Composable
private fun ChannelSidebar(
    channels: List<Channel>,
    selectedChannel: Channel?,
    onChannelSelect: (Channel) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.background(CatchupTheme.Surface.copy(alpha = 0.5f))) {
        // Header
        Text(
            text = "CHANNELS",
            style = MaterialTheme.typography.labelMedium,
            fontWeight = FontWeight.Bold,
            color = CatchupTheme.TextMuted,
            letterSpacing = 1.sp,
            modifier = Modifier.padding(16.dp)
        )

        // Channel list
        LazyColumn(
            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            items(channels, key = { it.id }) { channel ->
                ChannelListItem(
                    channel = channel,
                    isSelected = channel.id == selectedChannel?.id,
                    onClick = { onChannelSelect(channel) }
                )
            }
        }
    }
}

@Composable
private fun ChannelListItem(
    channel: Channel,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(10.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isSelected) CatchupTheme.Accent.copy(alpha = 0.2f) else Color.Transparent,
            focusedContainerColor = CatchupTheme.Accent.copy(alpha = 0.3f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, CatchupTheme.Accent),
                shape = RoundedCornerShape(10.dp)
            ),
            border = if (isSelected) Border(
                border = BorderStroke(1.dp, CatchupTheme.Accent.copy(alpha = 0.5f)),
                shape = RoundedCornerShape(10.dp)
            ) else Border.None
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Channel logo
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(CatchupTheme.SurfaceElevated),
                contentAlignment = Alignment.Center
            ) {
                if (channel.logoUrl != null) {
                    AsyncImage(
                        model = channel.logoUrl,
                        contentDescription = channel.name,
                        modifier = Modifier.size(32.dp),
                        contentScale = ContentScale.Fit
                    )
                } else {
                    Text(
                        text = channel.name.take(2).uppercase(),
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = CatchupTheme.Accent
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                // Channel number and name
                Row(verticalAlignment = Alignment.CenterVertically) {
                    channel.number?.let { number ->
                        Text(
                            text = number,
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = FontWeight.Bold,
                            color = if (isSelected || isFocused) CatchupTheme.Accent else CatchupTheme.TextPrimary
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                }
                Text(
                    text = channel.name,
                    style = MaterialTheme.typography.bodyMedium,
                    color = CatchupTheme.TextSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                // Archive days badge
                Text(
                    text = "${channel.archiveDays} days available",
                    style = MaterialTheme.typography.bodySmall,
                    color = CatchupTheme.TextMuted,
                    fontSize = 11.sp
                )
            }

            // Selection indicator
            if (isSelected) {
                Icon(
                    Icons.Default.ChevronRight,
                    contentDescription = null,
                    tint = CatchupTheme.Accent,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

@Composable
private fun DayFilterTabs(
    dayOptions: List<DayOption>,
    selectedDayOffset: Int,
    onDaySelect: (Int) -> Unit
) {
    LazyRow(
        modifier = Modifier
            .fillMaxWidth()
            .background(CatchupTheme.Surface.copy(alpha = 0.3f))
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        contentPadding = PaddingValues(horizontal = 16.dp)
    ) {
        items(dayOptions) { option ->
            DayTab(
                label = option.label,
                isSelected = option.offset == selectedDayOffset,
                onClick = { onDaySelect(option.offset) }
            )
        }
    }
}

@Composable
private fun DayTab(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = if (isSelected) CatchupTheme.Accent else CatchupTheme.Surface,
            focusedContainerColor = if (isSelected) CatchupTheme.AccentGlow else CatchupTheme.Accent.copy(alpha = 0.3f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, CatchupTheme.Accent),
                shape = RoundedCornerShape(8.dp)
            )
        )
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelLarge,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal,
            color = if (isSelected) Color.White else CatchupTheme.TextSecondary,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)
        )
    }
}

@Composable
private fun ProgramsList(
    programs: List<ArchiveProgram>,
    channel: Channel?,
    onProgramClick: (ArchiveProgram) -> Unit
) {
    LazyColumn(
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(programs, key = { it.id }) { program ->
            ProgramCard(
                program = program,
                channelLogo = channel?.logoUrl,
                onClick = { onProgramClick(program) }
            )
        }
    }
}

@Composable
private fun ProgramCard(
    program: ArchiveProgram,
    channelLogo: String?,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val timeFormat = remember { SimpleDateFormat("h:mm a", Locale.getDefault()) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = CatchupTheme.Surface,
            focusedContainerColor = CatchupTheme.Accent.copy(alpha = 0.2f)
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(2.dp, CatchupTheme.Accent),
                shape = RoundedCornerShape(12.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f),
        glow = ClickableSurfaceDefaults.glow(
            focusedGlow = Glow(
                elevationColor = CatchupTheme.Accent.copy(alpha = 0.3f),
                elevation = 8.dp
            )
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Program thumbnail or icon
            Box(
                modifier = Modifier
                    .size(80.dp, 60.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(CatchupTheme.SurfaceElevated),
                contentAlignment = Alignment.Center
            ) {
                if (program.icon != null) {
                    AsyncImage(
                        model = program.icon,
                        contentDescription = program.title,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } else if (channelLogo != null) {
                    AsyncImage(
                        model = channelLogo,
                        contentDescription = null,
                        modifier = Modifier
                            .size(40.dp)
                            .padding(8.dp),
                        contentScale = ContentScale.Fit
                    )
                } else {
                    Icon(
                        Icons.Default.PlayCircle,
                        contentDescription = null,
                        tint = CatchupTheme.Accent,
                        modifier = Modifier.size(32.dp)
                    )
                }

                // Catch-up badge
                Box(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(4.dp)
                        .background(CatchupTheme.Accent, RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = "CATCH-UP",
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        fontSize = 8.sp
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Program info
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = program.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isFocused) CatchupTheme.Accent else CatchupTheme.TextPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                program.description?.let { desc ->
                    Text(
                        text = desc,
                        style = MaterialTheme.typography.bodySmall,
                        color = CatchupTheme.TextSecondary,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(top = 4.dp)
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Time and duration
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Schedule,
                        contentDescription = null,
                        tint = CatchupTheme.TextMuted,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = timeFormat.format(Date(program.startTime * 1000)),
                        style = MaterialTheme.typography.bodySmall,
                        color = CatchupTheme.TextMuted
                    )

                    Spacer(modifier = Modifier.width(16.dp))

                    Icon(
                        Icons.Default.Timer,
                        contentDescription = null,
                        tint = CatchupTheme.TextMuted,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${program.durationMinutes} min",
                        style = MaterialTheme.typography.bodySmall,
                        color = CatchupTheme.TextMuted
                    )

                    // Expiry warning
                    if (program.hoursUntilExpiry < 24) {
                        Spacer(modifier = Modifier.width(16.dp))
                        Box(
                            modifier = Modifier
                                .background(Color(0xFFEF4444).copy(alpha = 0.2f), RoundedCornerShape(4.dp))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "Expires in ${program.hoursUntilExpiry}h",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color(0xFFEF4444),
                                fontSize = 10.sp
                            )
                        }
                    }
                }
            }

            // Play button
            Spacer(modifier = Modifier.width(16.dp))
            AnimatedVisibility(visible = isFocused) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .background(CatchupTheme.Accent, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.PlayArrow,
                        contentDescription = "Play",
                        tint = Color.White,
                        modifier = Modifier.size(28.dp)
                    )
                }
            }
        }
    }
}
