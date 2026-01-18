package com.openflix.presentation.screens.dvr

import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Recording
import com.openflix.domain.model.RecordingStats
import com.openflix.domain.model.RecordingStatus
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun DVRScreen(
    onRecordingClick: (recordingId: String, mode: String) -> Unit,
    viewModel: DVRViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedTab by remember { mutableStateOf(DVRTab.RECORDINGS) }

    // State for watch options dialog
    var showWatchDialog by remember { mutableStateOf(false) }
    var selectedRecording by remember { mutableStateOf<Recording?>(null) }

    LaunchedEffect(Unit) {
        viewModel.loadRecordings()
    }

    // Clean up polling when leaving screen
    DisposableEffect(Unit) {
        onDispose {
            viewModel.stopStatsPolling()
        }
    }

    // Watch Options Dialog for active recordings
    if (showWatchDialog && selectedRecording != null) {
        WatchOptionsDialog(
            recording = selectedRecording!!,
            onDismiss = {
                showWatchDialog = false
                selectedRecording = null
            },
            onWatchFromStart = {
                showWatchDialog = false
                onRecordingClick(selectedRecording!!.id, "start")
                selectedRecording = null
            },
            onWatchLive = {
                showWatchDialog = false
                onRecordingClick(selectedRecording!!.id, "live")
                selectedRecording = null
            }
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        // Header
        Text(
            text = "DVR",
            style = MaterialTheme.typography.displaySmall,
            color = OpenFlixColors.OnSurface
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Tabs with recording count
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            DVRTab.entries.forEach { tab ->
                val count = when (tab) {
                    DVRTab.RECORDING -> uiState.recordings.count { it.status == RecordingStatus.RECORDING }
                    DVRTab.RECORDINGS -> uiState.recordings.count { it.status == RecordingStatus.COMPLETED }
                    DVRTab.SCHEDULED -> uiState.recordings.count { it.status == RecordingStatus.SCHEDULED || it.status == RecordingStatus.PENDING }
                    DVRTab.FAILED -> uiState.recordings.count { it.status == RecordingStatus.FAILED || it.status == RecordingStatus.CANCELLED }
                }

                Button(
                    onClick = { selectedTab = tab },
                    colors = if (selectedTab == tab) {
                        ButtonDefaults.colors(
                            containerColor = if (tab == DVRTab.RECORDING) OpenFlixColors.Error else OpenFlixColors.Primary
                        )
                    } else {
                        ButtonDefaults.colors(containerColor = OpenFlixColors.SurfaceVariant)
                    }
                ) {
                    if (tab == DVRTab.RECORDING && count > 0) {
                        // Pulsing dot for active recordings
                        PulsingDot()
                        Spacer(modifier = Modifier.width(6.dp))
                    }
                    Text("${tab.title} ($count)")
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Content
        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text("Loading recordings...", color = OpenFlixColors.TextSecondary)
                }
            }
            uiState.error != null -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(uiState.error!!, color = OpenFlixColors.Error)
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = viewModel::loadRecordings) {
                            Text("Retry")
                        }
                    }
                }
            }
            else -> {
                val items = when (selectedTab) {
                    DVRTab.RECORDING -> uiState.recordings.filter { it.status == RecordingStatus.RECORDING }
                    DVRTab.RECORDINGS -> uiState.recordings.filter { it.status == RecordingStatus.COMPLETED }
                    DVRTab.SCHEDULED -> uiState.recordings.filter { it.status == RecordingStatus.SCHEDULED || it.status == RecordingStatus.PENDING }
                    DVRTab.FAILED -> uiState.recordings.filter { it.status == RecordingStatus.FAILED || it.status == RecordingStatus.CANCELLED }
                }

                if (items.isEmpty()) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = when (selectedTab) {
                                DVRTab.RECORDING -> "No active recordings"
                                DVRTab.RECORDINGS -> "No completed recordings"
                                DVRTab.SCHEDULED -> "No scheduled recordings"
                                DVRTab.FAILED -> "No failed recordings"
                            },
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                } else {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(items) { recording ->
                            val stats = viewModel.getStatsForRecording(recording.id)
                            val isActiveRecording = recording.status == RecordingStatus.RECORDING && stats?.isFailed != true
                            RecordingListItem(
                                recording = recording,
                                liveStats = stats,
                                onClick = {
                                    if (isActiveRecording) {
                                        // Show dialog for active recordings
                                        selectedRecording = recording
                                        showWatchDialog = true
                                    } else {
                                        // Go directly to player for completed recordings
                                        onRecordingClick(recording.id, "default")
                                    }
                                },
                                onDelete = { viewModel.deleteRecording(recording.id) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun WatchOptionsDialog(
    recording: Recording,
    onDismiss: () -> Unit,
    onWatchFromStart: () -> Unit,
    onWatchLive: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Box(
            modifier = Modifier
                .width(400.dp)
                .wrapContentHeight()
                .background(OpenFlixColors.Surface, MaterialTheme.shapes.large)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Recording indicator
                Row(
                    modifier = Modifier
                        .background(OpenFlixColors.Error, MaterialTheme.shapes.small)
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    PulsingDot()
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Recording in Progress",
                        style = MaterialTheme.typography.labelLarge,
                        color = Color.White
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Title
                Text(
                    text = recording.displayTitle,
                    style = MaterialTheme.typography.titleLarge,
                    color = OpenFlixColors.OnSurface,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                recording.episodeInfo?.let { info ->
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = info,
                        style = MaterialTheme.typography.bodyMedium,
                        color = OpenFlixColors.TextSecondary
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                Text(
                    text = "How would you like to watch?",
                    style = MaterialTheme.typography.bodyLarge,
                    color = OpenFlixColors.TextSecondary
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Watch from Start button
                Button(
                    onClick = onWatchFromStart,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ) {
                        Text(
                            text = "Watch from Start",
                            style = MaterialTheme.typography.titleMedium
                        )
                        Text(
                            text = "Start from the beginning",
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.OnPrimary.copy(alpha = 0.8f)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Watch Live button
                Button(
                    onClick = onWatchLive,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error)
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ) {
                        Text(
                            text = "Watch Live",
                            style = MaterialTheme.typography.titleMedium
                        )
                        Text(
                            text = "Jump to live broadcast",
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.OnPrimary.copy(alpha = 0.8f)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Cancel button
                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Cancel")
                }
            }
        }
    }
}

@Composable
private fun PulsingDot() {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0.3f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "alpha"
    )

    Box(
        modifier = Modifier
            .size(8.dp)
            .clip(CircleShape)
            .background(OpenFlixColors.Error.copy(alpha = alpha))
    )
}

@Composable
private fun RecordingListItem(
    recording: Recording,
    liveStats: RecordingStats?,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val isRecording = recording.status == RecordingStatus.RECORDING
    val isFailed = liveStats?.isFailed == true

    // Determine best image to show - prefer poster-style images
    val posterImage = recording.posterUrl
    val backdropImage = recording.backdropUrl

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) {
                    Modifier.border(
                        BorderStroke(2.dp, if (isFailed) OpenFlixColors.Error else OpenFlixColors.Primary),
                        MaterialTheme.shapes.medium
                    )
                } else {
                    Modifier
                }
            ),
        shape = ClickableSurfaceDefaults.shape(MaterialTheme.shapes.medium),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Column {
            // Live progress bar for active recordings
            if (isRecording && liveStats != null) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(3.dp)
                        .background(OpenFlixColors.SurfaceVariant)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(if (isFailed) 1f else liveStats.progressFloat)
                            .fillMaxHeight()
                            .background(if (isFailed) OpenFlixColors.Error else OpenFlixColors.Success)
                    )
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.Top
            ) {
                // Poster Image - use movie poster style for movies, landscape for TV
                Box(
                    modifier = Modifier
                        .then(
                            if (recording.isMovie) {
                                Modifier.size(90.dp, 135.dp)  // 2:3 poster ratio
                            } else {
                                Modifier.size(160.dp, 90.dp)  // 16:9 landscape ratio
                            }
                        )
                        .clip(MaterialTheme.shapes.small)
                        .background(OpenFlixColors.SurfaceVariant)
                ) {
                    AsyncImage(
                        model = if (recording.isMovie) posterImage else (backdropImage ?: posterImage),
                        contentDescription = recording.title,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )

                    // Channel logo overlay in corner
                    if (recording.channelLogo != null && !recording.isMovie) {
                        Box(
                            modifier = Modifier
                                .align(Alignment.BottomEnd)
                                .padding(4.dp)
                                .size(32.dp)
                                .background(Color.Black.copy(alpha = 0.7f), MaterialTheme.shapes.extraSmall)
                                .padding(4.dp)
                        ) {
                            AsyncImage(
                                model = recording.channelLogo,
                                contentDescription = recording.channelName,
                                modifier = Modifier.fillMaxSize(),
                                contentScale = ContentScale.Fit
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.width(16.dp))

                // Info
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = recording.displayTitle,
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.OnSurface,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            modifier = Modifier.weight(1f, fill = false)
                        )

                        if (isRecording) {
                            Spacer(modifier = Modifier.width(8.dp))
                            if (isFailed) {
                                Box(
                                    modifier = Modifier
                                        .background(OpenFlixColors.Error, MaterialTheme.shapes.extraSmall)
                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                ) {
                                    Text("FAILED", style = MaterialTheme.typography.labelSmall, color = OpenFlixColors.OnPrimary)
                                }
                            } else {
                                Row(
                                    modifier = Modifier
                                        .background(OpenFlixColors.Error, MaterialTheme.shapes.extraSmall)
                                        .padding(horizontal = 6.dp, vertical = 2.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    PulsingDot()
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("REC", style = MaterialTheme.typography.labelSmall, color = OpenFlixColors.OnPrimary)
                                }
                            }
                        }
                    }

                    // Metadata badges row (year, content rating, rating)
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Year
                        recording.year?.let { year ->
                            Text(
                                text = year.toString(),
                                style = MaterialTheme.typography.bodySmall,
                                color = OpenFlixColors.TextSecondary
                            )
                        }

                        // Content rating badge
                        recording.contentRating?.let { contentRating ->
                            if (contentRating.isNotBlank()) {
                                Box(
                                    modifier = Modifier
                                        .border(1.dp, OpenFlixColors.TextTertiary, MaterialTheme.shapes.extraSmall)
                                        .padding(horizontal = 4.dp, vertical = 1.dp)
                                ) {
                                    Text(
                                        text = contentRating,
                                        style = MaterialTheme.typography.labelSmall,
                                        color = OpenFlixColors.TextSecondary
                                    )
                                }
                            }
                        }

                        // TMDB rating
                        recording.rating?.let { rating ->
                            if (rating > 0) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(2.dp)
                                ) {
                                    Text(
                                        text = "★",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Color(0xFFFFD700)  // Gold star
                                    )
                                    Text(
                                        text = String.format("%.1f", rating),
                                        style = MaterialTheme.typography.bodySmall,
                                        color = OpenFlixColors.TextSecondary
                                    )
                                }
                            }
                        }

                        // Movie badge
                        if (recording.isMovie) {
                            Box(
                                modifier = Modifier
                                    .background(OpenFlixColors.Primary.copy(alpha = 0.2f), MaterialTheme.shapes.extraSmall)
                                    .padding(horizontal = 4.dp, vertical = 1.dp)
                            ) {
                                Text(
                                    text = "MOVIE",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = OpenFlixColors.Primary
                                )
                            }
                        }
                    }

                    recording.episodeInfo?.let { info ->
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = info,
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextSecondary
                        )
                    }

                    // Genres
                    recording.genres?.let { genres ->
                        if (genres.isNotBlank()) {
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = genres,
                                style = MaterialTheme.typography.bodySmall,
                                color = OpenFlixColors.TextTertiary,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }

                    // Channel name (if no channel logo shown)
                    if (recording.channelLogo == null || recording.isMovie) {
                        recording.channelName?.let { channel ->
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = channel,
                                style = MaterialTheme.typography.bodySmall,
                                color = OpenFlixColors.TextTertiary
                            )
                        }
                    }

                    // Summary/description
                    val summaryText = recording.summary ?: recording.description
                    if (!summaryText.isNullOrBlank() && !isRecording) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = summaryText,
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextTertiary,
                            maxLines = 2,
                            overflow = TextOverflow.Ellipsis
                        )
                    }

                    // Live recording stats panel
                    if (isRecording && liveStats != null) {
                        Spacer(modifier = Modifier.height(12.dp))

                        if (isFailed) {
                            // Failed recording message
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(
                                        OpenFlixColors.Error.copy(alpha = 0.15f),
                                        MaterialTheme.shapes.small
                                    )
                                    .border(
                                        1.dp,
                                        OpenFlixColors.Error.copy(alpha = 0.3f),
                                        MaterialTheme.shapes.small
                                    )
                                    .padding(12.dp)
                            ) {
                                Column {
                                    Text(
                                        text = "Recording Failed",
                                        style = MaterialTheme.typography.labelLarge,
                                        color = OpenFlixColors.Error
                                    )
                                    liveStats.failureReason?.let { reason ->
                                        Spacer(modifier = Modifier.height(4.dp))
                                        Text(
                                            text = reason,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = OpenFlixColors.TextSecondary
                                        )
                                    }
                                }
                            }
                        } else {
                            // Active recording stats
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(
                                        OpenFlixColors.SurfaceVariant,
                                        MaterialTheme.shapes.small
                                    )
                                    .border(
                                        1.dp,
                                        OpenFlixColors.Success.copy(alpha = 0.3f),
                                        MaterialTheme.shapes.small
                                    )
                                    .padding(12.dp)
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    // File Size
                                    StatItem(
                                        label = "File Size",
                                        value = liveStats.fileSizeFormatted,
                                        color = OpenFlixColors.Success
                                    )

                                    // Elapsed Time
                                    StatItem(
                                        label = "Elapsed",
                                        value = liveStats.elapsedFormatted,
                                        color = OpenFlixColors.Success
                                    )

                                    // Progress
                                    StatItem(
                                        label = "Progress",
                                        value = "${liveStats.progressPercent.toInt()}%",
                                        color = OpenFlixColors.Success
                                    )

                                    // Bitrate (if available)
                                    if (liveStats.bitrate != null) {
                                        StatItem(
                                            label = "Bitrate",
                                            value = liveStats.bitrate,
                                            color = OpenFlixColors.Success
                                        )
                                    }

                                    // Health indicator
                                    StatItem(
                                        label = "Health",
                                        value = if (liveStats.isHealthy) "Good" else "Slow",
                                        color = if (liveStats.isHealthy) OpenFlixColors.Success else OpenFlixColors.Warning
                                    )
                                }
                            }
                        }
                    } else {
                        // Watch progress bar for completed recordings
                        if (recording.watchProgress > 0f && recording.watchProgress < 1f) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(4.dp)
                                    .background(OpenFlixColors.ProgressBackground, MaterialTheme.shapes.extraSmall)
                            ) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth(recording.watchProgress)
                                        .fillMaxHeight()
                                        .background(OpenFlixColors.ProgressFill, MaterialTheme.shapes.extraSmall)
                                )
                            }
                        }
                    }
                }

                // File size for non-recording items
                if (!isRecording) {
                    Text(
                        text = recording.fileSizeDisplay,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextTertiary
                    )
                }
            }
        }
    }
}

@Composable
private fun StatItem(
    label: String,
    value: String,
    color: Color
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleSmall,
            color = color
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = OpenFlixColors.TextTertiary
        )
    }
}

enum class DVRTab(val title: String) {
    RECORDING("Recording"),
    RECORDINGS("Completed"),
    SCHEDULED("Scheduled"),
    FAILED("Failed")
}
