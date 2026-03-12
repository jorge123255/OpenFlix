package com.openflix.presentation.screens.dvr

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.*
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun DVRScreen(
    onRecordingClick: (recordingId: String, mode: String) -> Unit,
    viewModel: DVRViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // State for dialogs
    var showWatchDialog by remember { mutableStateOf(false) }
    var selectedRecording by remember { mutableStateOf<Recording?>(null) }
    var showConflictDialog by remember { mutableStateOf(false) }

    // Track expanded channel groups
    val expandedChannels = remember { mutableStateMapOf<String, Boolean>() }
    var failedExpanded by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadRecordings()
        viewModel.loadSeriesRules()
        viewModel.loadConflicts()
        viewModel.loadDiskUsage()
    }

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
            },
            onStopRecording = {
                viewModel.stopRecording(selectedRecording!!.id)
                showWatchDialog = false
                selectedRecording = null
            }
        )
    }

    // Conflict Resolution Dialog
    if (showConflictDialog && uiState.conflicts?.hasConflicts == true) {
        ConflictResolutionDialog(
            conflicts = uiState.conflicts!!,
            onResolve = { keepId, cancelId ->
                viewModel.resolveConflict(keepId, cancelId)
            },
            onDismiss = { showConflictDialog = false }
        )
    }

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
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 24.dp),
                verticalArrangement = Arrangement.spacedBy(20.dp),
                contentPadding = PaddingValues(vertical = 24.dp)
            ) {
                // ============ Storage Meter ============
                item {
                    StorageMeter(
                        usedBytes = uiState.totalStorageBytes,
                        totalBytes = uiState.diskUsage?.totalBytes ?: (100L * 1024 * 1024 * 1024),
                        recordingCount = uiState.totalRecordingCount,
                        diskUsage = uiState.diskUsage
                    )
                }

                // ============ Conflict Banner ============
                if (uiState.conflicts?.hasConflicts == true) {
                    item {
                        ConflictBanner(
                            conflictCount = uiState.conflicts!!.totalCount,
                            onClick = { showConflictDialog = true }
                        )
                    }
                }

                // ============ Recording Now ============
                if (uiState.recordingNow.isNotEmpty()) {
                    item {
                        SectionHeader(
                            title = "Recording Now",
                            leadingContent = { PulsingDot(size = 10.dp) }
                        )
                    }
                    item {
                        LazyRow(
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            contentPadding = PaddingValues(end = 24.dp)
                        ) {
                            items(uiState.recordingNow) { recording ->
                                RecordingNowCard(
                                    recording = recording,
                                    liveStats = viewModel.getStatsForRecording(recording.id),
                                    onClick = {
                                        selectedRecording = recording
                                        showWatchDialog = true
                                    }
                                )
                            }
                        }
                    }
                }

                // ============ Continue Watching ============
                if (uiState.continueWatching.isNotEmpty()) {
                    item {
                        SectionHeader(title = "Continue Watching")
                    }
                    item {
                        LazyRow(
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            contentPadding = PaddingValues(end = 24.dp)
                        ) {
                            items(uiState.continueWatching) { recording ->
                                ContinueWatchingCard(
                                    recording = recording,
                                    onClick = { onRecordingClick(recording.id, "resume") }
                                )
                            }
                        }
                    }
                }

                // ============ Just Recorded ============
                if (uiState.justRecorded.isNotEmpty()) {
                    item {
                        SectionHeader(title = "Just Recorded")
                    }
                    item {
                        LazyRow(
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            contentPadding = PaddingValues(end = 24.dp)
                        ) {
                            items(uiState.justRecorded) { recording ->
                                LandscapeRecordingCard(
                                    recording = recording,
                                    onClick = { onRecordingClick(recording.id, "default") }
                                )
                            }
                        }
                    }
                }

                // ============ All Recordings (by Channel) ============
                if (uiState.allByChannel.isNotEmpty()) {
                    item {
                        SectionHeader(title = "All Recordings")
                    }

                    uiState.allByChannel.forEach { (channelName, recordings) ->
                        val isExpanded = expandedChannels[channelName] ?: false

                        item(key = "channel_header_$channelName") {
                            ChannelGroupHeader(
                                channelName = channelName,
                                channelLogo = recordings.firstOrNull()?.channelLogo,
                                count = recordings.size,
                                isExpanded = isExpanded,
                                onClick = {
                                    expandedChannels[channelName] = !isExpanded
                                }
                            )
                        }

                        if (isExpanded) {
                            items(
                                items = recordings.sortedByDescending { it.startTime },
                                key = { "recording_${it.id}" }
                            ) { recording ->
                                CompactRecordingRow(
                                    recording = recording,
                                    onClick = { onRecordingClick(recording.id, "default") },
                                    onDelete = { viewModel.deleteRecording(recording.id) }
                                )
                            }
                        }
                    }
                }

                // ============ Scheduled ============
                if (uiState.scheduled.isNotEmpty()) {
                    item {
                        SectionHeader(title = "Scheduled")
                    }
                    item {
                        LazyRow(
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            contentPadding = PaddingValues(end = 24.dp)
                        ) {
                            items(uiState.scheduled) { recording ->
                                ScheduledCard(
                                    recording = recording,
                                    onDelete = { viewModel.deleteRecording(recording.id) }
                                )
                            }
                        }
                    }
                }

                // ============ Series Rules ============
                if (uiState.seriesRules.isNotEmpty()) {
                    item {
                        SectionHeader(title = "Series Rules")
                    }
                    items(uiState.seriesRules) { rule ->
                        SeriesRuleRow(
                            rule = rule,
                            onToggle = { enabled -> viewModel.toggleSeriesRule(rule.id, enabled) },
                            onDelete = { viewModel.deleteSeriesRule(rule.id) }
                        )
                    }
                }

                // ============ Failed ============
                if (uiState.failed.isNotEmpty()) {
                    item {
                        FailedSectionHeader(
                            count = uiState.failed.size,
                            isExpanded = failedExpanded,
                            onClick = { failedExpanded = !failedExpanded }
                        )
                    }

                    if (failedExpanded) {
                        items(uiState.failed) { recording ->
                            FailedRecordingRow(
                                recording = recording,
                                onDelete = { viewModel.deleteRecording(recording.id) }
                            )
                        }
                    }
                }

                // Empty state if nothing at all
                if (uiState.recordings.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(200.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No recordings. Schedule a recording from the TV Guide.",
                                color = OpenFlixColors.TextSecondary
                            )
                        }
                    }
                }
            }
        }
    }
}

// ============ Storage Meter ============

@Composable
private fun StorageMeter(
    usedBytes: Long,
    totalBytes: Long,
    recordingCount: Int,
    diskUsage: DiskUsage?
) {
    val usagePercent = if (totalBytes > 0) (usedBytes.toFloat() / totalBytes.toFloat()).coerceIn(0f, 1f) else 0f
    val barColor = when {
        usagePercent > 0.9f -> OpenFlixColors.Error
        usagePercent > 0.7f -> OpenFlixColors.Warning
        else -> OpenFlixColors.Success
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(OpenFlixColors.SurfaceVariant, RoundedCornerShape(12.dp))
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Progress bar
        Column(modifier = Modifier.weight(1f)) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(OpenFlixColors.ProgressBackground)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(usagePercent)
                        .fillMaxHeight()
                        .clip(RoundedCornerShape(4.dp))
                        .background(barColor)
                )
            }
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = "${formatBytes(usedBytes)} used" +
                    if (diskUsage != null) " of ${diskUsage.totalBytesFormatted}" else "",
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextSecondary
            )
        }

        // Recording count
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = "$recordingCount",
                style = MaterialTheme.typography.titleLarge,
                color = barColor,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "recordings",
                style = MaterialTheme.typography.labelSmall,
                color = OpenFlixColors.TextTertiary
            )
        }
    }
}

// ============ Section Headers ============

@Composable
private fun SectionHeader(
    title: String,
    leadingContent: @Composable (() -> Unit)? = null
) {
    Row(
        modifier = Modifier.padding(top = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        leadingContent?.invoke()
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            color = OpenFlixColors.OnSurface,
            fontWeight = FontWeight.SemiBold
        )
    }
}

// ============ Recording Now Card ============

@Composable
private fun RecordingNowCard(
    recording: Recording,
    liveStats: RecordingStats?,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(280.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) Modifier.border(BorderStroke(2.dp, OpenFlixColors.Error), RoundedCornerShape(12.dp))
                else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Column {
            // Thumbnail
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(158.dp)
                    .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
                    .background(OpenFlixColors.SurfaceVariant)
            ) {
                AsyncImage(
                    model = recording.backdropUrl ?: recording.posterUrl,
                    contentDescription = recording.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )

                // REC badge
                Row(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(8.dp)
                        .background(OpenFlixColors.Error, RoundedCornerShape(4.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    PulsingDot(size = 6.dp)
                    Text("REC", style = MaterialTheme.typography.labelSmall, color = Color.White, fontWeight = FontWeight.Bold)
                }

                // Progress bar at bottom of image
                if (liveStats != null) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .fillMaxWidth()
                            .height(3.dp)
                            .background(OpenFlixColors.ProgressBackground)
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(liveStats.progressFloat)
                                .fillMaxHeight()
                                .background(OpenFlixColors.Error)
                        )
                    }
                }
            }

            // Title
            Column(modifier = Modifier.padding(12.dp)) {
                Text(
                    text = recording.displayTitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.OnSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    fontWeight = FontWeight.Medium
                )
                recording.channelName?.let { channel ->
                    Text(
                        text = channel,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextTertiary,
                        maxLines = 1
                    )
                }
            }
        }
    }
}

// ============ Continue Watching Card ============

@Composable
private fun ContinueWatchingCard(
    recording: Recording,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(280.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) Modifier.border(BorderStroke(2.dp, OpenFlixColors.Primary), RoundedCornerShape(12.dp))
                else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Column {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(158.dp)
                    .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
                    .background(OpenFlixColors.SurfaceVariant)
            ) {
                AsyncImage(
                    model = recording.backdropUrl ?: recording.posterUrl,
                    contentDescription = recording.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )

                // Purple progress bar at bottom
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth()
                        .height(4.dp)
                        .background(OpenFlixColors.ProgressBackground)
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(recording.watchProgress)
                            .fillMaxHeight()
                            .background(OpenFlixColors.Primary)
                    )
                }
            }

            Column(modifier = Modifier.padding(12.dp)) {
                Text(
                    text = recording.displayTitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.OnSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    fontWeight = FontWeight.Medium
                )
                recording.episodeInfo?.let { ep ->
                    Text(
                        text = ep,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary,
                        maxLines = 1
                    )
                }
            }
        }
    }
}

// ============ Landscape Recording Card (Just Recorded) ============

@Composable
private fun LandscapeRecordingCard(
    recording: Recording,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(280.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) Modifier.border(BorderStroke(2.dp, OpenFlixColors.Primary), RoundedCornerShape(12.dp))
                else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Column {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(158.dp)
                    .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
                    .background(OpenFlixColors.SurfaceVariant)
            ) {
                AsyncImage(
                    model = recording.backdropUrl ?: recording.posterUrl,
                    contentDescription = recording.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )

                // Channel logo overlay
                recording.channelLogo?.let { logo ->
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .padding(8.dp)
                            .size(32.dp)
                            .background(Color.Black.copy(alpha = 0.7f), RoundedCornerShape(4.dp))
                            .padding(4.dp)
                    ) {
                        AsyncImage(
                            model = logo,
                            contentDescription = recording.channelName,
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Fit
                        )
                    }
                }
            }

            Column(modifier = Modifier.padding(12.dp)) {
                Text(
                    text = recording.displayTitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.OnSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    fontWeight = FontWeight.Medium
                )
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    recording.episodeInfo?.let { ep ->
                        Text(ep, style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextSecondary)
                    }
                    Text(recording.fileSizeDisplay, style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextTertiary)
                }
            }
        }
    }
}

// ============ All Recordings - Channel Group Header ============

@Composable
private fun ChannelGroupHeader(
    channelName: String,
    channelLogo: String?,
    count: Int,
    isExpanded: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) Modifier.border(BorderStroke(2.dp, OpenFlixColors.Primary), RoundedCornerShape(8.dp))
                else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Channel logo
            if (channelLogo != null) {
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(RoundedCornerShape(6.dp))
                        .background(Color.Black.copy(alpha = 0.5f))
                        .padding(4.dp)
                ) {
                    AsyncImage(
                        model = channelLogo,
                        contentDescription = channelName,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Fit
                    )
                }
            }

            Text(
                text = channelName,
                style = MaterialTheme.typography.titleSmall,
                color = OpenFlixColors.OnSurface,
                modifier = Modifier.weight(1f)
            )

            Text(
                text = "$count recording${if (count != 1) "s" else ""}",
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextTertiary
            )

            Text(
                text = if (isExpanded) "▲" else "▼",
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextTertiary
            )
        }
    }
}

// ============ Compact Recording Row (inside channel groups) ============

@Composable
private fun CompactRecordingRow(
    recording: Recording,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = 16.dp) // indent under channel header
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) Modifier.border(BorderStroke(2.dp, OpenFlixColors.Primary), RoundedCornerShape(8.dp))
                else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.SurfaceVariant,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Small thumbnail
            Box(
                modifier = Modifier
                    .size(80.dp, 45.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(OpenFlixColors.Surface)
            ) {
                AsyncImage(
                    model = recording.backdropUrl ?: recording.posterUrl,
                    contentDescription = recording.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )

                // Progress bar if partially watched
                if (recording.watchProgress > 0f && recording.watchProgress < 1f) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .fillMaxWidth()
                            .height(3.dp)
                            .background(OpenFlixColors.ProgressBackground)
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(recording.watchProgress)
                                .fillMaxHeight()
                                .background(OpenFlixColors.Primary)
                        )
                    }
                }
            }

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = recording.displayTitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.OnSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    recording.episodeInfo?.let { ep ->
                        Text(ep, style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextSecondary)
                    }
                    Text(
                        text = formatDuration(recording.duration),
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextTertiary
                    )
                }
            }

            Text(
                text = recording.fileSizeDisplay,
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextTertiary
            )
        }
    }
}

// ============ Scheduled Card ============

@Composable
private fun ScheduledCard(
    recording: Recording,
    onDelete: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = { },
        modifier = Modifier
            .width(280.dp)
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) Modifier.border(BorderStroke(2.dp, OpenFlixColors.Primary), RoundedCornerShape(12.dp))
                else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.02f)
    ) {
        Column {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(158.dp)
                    .clip(RoundedCornerShape(topStart = 12.dp, topEnd = 12.dp))
                    .background(OpenFlixColors.SurfaceVariant)
            ) {
                AsyncImage(
                    model = recording.backdropUrl ?: recording.posterUrl,
                    contentDescription = recording.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )

                // Clock badge
                Box(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(8.dp)
                        .background(OpenFlixColors.Primary, RoundedCornerShape(4.dp))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text("SCHEDULED", style = MaterialTheme.typography.labelSmall, color = Color.White, fontWeight = FontWeight.Bold)
                }
            }

            Column(modifier = Modifier.padding(12.dp)) {
                Text(
                    text = recording.displayTitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.OnSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = formatScheduledTime(recording.startTime),
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextSecondary
                )
                recording.channelName?.let { channel ->
                    Text(
                        text = channel,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextTertiary
                    )
                }
            }
        }
    }
}

// ============ Failed Section ============

@Composable
private fun FailedSectionHeader(
    count: Int,
    isExpanded: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) Modifier.border(BorderStroke(2.dp, OpenFlixColors.Error), RoundedCornerShape(8.dp))
                else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Error.copy(alpha = 0.1f),
            focusedContainerColor = OpenFlixColors.Error.copy(alpha = 0.2f)
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text("Failed", style = MaterialTheme.typography.titleSmall, color = OpenFlixColors.Error)
            Text(
                text = "($count)",
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.Error.copy(alpha = 0.7f)
            )
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = if (isExpanded) "▲" else "▼",
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.Error.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun FailedRecordingRow(
    recording: Recording,
    onDelete: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = { },
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) Modifier.border(BorderStroke(2.dp, OpenFlixColors.Error), RoundedCornerShape(8.dp))
                else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.SurfaceVariant,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = recording.displayTitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.OnSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                recording.channelName?.let { channel ->
                    Text(channel, style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextTertiary)
                }
                Text(
                    text = "Status: ${recording.status.name.lowercase()}",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.Error
                )
            }

            Button(
                onClick = onDelete,
                colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error)
            ) {
                Text("Delete")
            }
        }
    }
}

// ============ Series Rule Row ============

@Composable
private fun SeriesRuleRow(
    rule: SeriesRule,
    onToggle: (Boolean) -> Unit,
    onDelete: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = { onToggle(!rule.enabled) },
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) Modifier.border(BorderStroke(2.dp, OpenFlixColors.Primary), RoundedCornerShape(8.dp))
                else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .clip(CircleShape)
                    .background(if (rule.enabled) OpenFlixColors.Success else OpenFlixColors.TextTertiary)
            )

            Spacer(modifier = Modifier.width(12.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = rule.title,
                    style = MaterialTheme.typography.titleMedium,
                    color = if (rule.enabled) OpenFlixColors.OnSurface else OpenFlixColors.TextTertiary
                )
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    if (rule.keepCount > 0) {
                        Text("Keep ${rule.keepCount}", style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextSecondary)
                    }
                    if (rule.prePadding > 0 || rule.postPadding > 0) {
                        Text(
                            "Padding: ${rule.prePadding}m / ${rule.postPadding}m",
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                }
            }

            Button(
                onClick = { onToggle(!rule.enabled) },
                colors = ButtonDefaults.colors(
                    containerColor = if (rule.enabled) OpenFlixColors.Success else OpenFlixColors.SurfaceVariant
                )
            ) {
                Text(if (rule.enabled) "Enabled" else "Disabled")
            }

            Spacer(modifier = Modifier.width(8.dp))

            Button(
                onClick = onDelete,
                colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error)
            ) {
                Text("Delete")
            }
        }
    }
}

// ============ Conflict Banner ============

@Composable
private fun ConflictBanner(
    conflictCount: Int,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Warning.copy(alpha = 0.2f))
    ) {
        Text(
            text = "$conflictCount recording conflict${if (conflictCount > 1) "s" else ""} detected - tap to resolve",
            color = OpenFlixColors.Warning,
            style = MaterialTheme.typography.bodyMedium
        )
    }
}

// ============ Conflict Resolution Dialog ============

@Composable
private fun ConflictResolutionDialog(
    conflicts: ConflictsData,
    onResolve: (keepId: Long, cancelId: Long) -> Unit,
    onDismiss: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Box(
            modifier = Modifier
                .width(500.dp)
                .wrapContentHeight()
                .background(OpenFlixColors.Surface, RoundedCornerShape(16.dp))
        ) {
            Column(modifier = Modifier.padding(24.dp)) {
                Text(
                    text = "Recording Conflicts",
                    style = MaterialTheme.typography.titleLarge,
                    color = OpenFlixColors.OnSurface
                )

                Spacer(modifier = Modifier.height(16.dp))

                Text(
                    text = "The following recordings overlap. Choose which to keep:",
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.TextSecondary
                )

                Spacer(modifier = Modifier.height(16.dp))

                conflicts.conflicts.forEach { group ->
                    if (group.recordings.size >= 2) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(OpenFlixColors.SurfaceVariant, RoundedCornerShape(8.dp))
                                .padding(12.dp)
                        ) {
                            group.recordings.forEach { recording ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            text = recording.title,
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = OpenFlixColors.OnSurface
                                        )
                                        Text(
                                            text = recording.channelName ?: "",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = OpenFlixColors.TextSecondary
                                        )
                                    }
                                    Button(
                                        onClick = {
                                            val otherId = group.recordings
                                                .first { it.id != recording.id }.id.toLongOrNull()
                                            val keepId = recording.id.toLongOrNull()
                                            if (keepId != null && otherId != null) {
                                                onResolve(keepId, otherId)
                                            }
                                        },
                                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)
                                    ) {
                                        Text("Keep")
                                    }
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                OutlinedButton(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text("Close")
                }
            }
        }
    }
}

// ============ Watch Options Dialog (with Stop Recording) ============

@Composable
private fun WatchOptionsDialog(
    recording: Recording,
    onDismiss: () -> Unit,
    onWatchFromStart: () -> Unit,
    onWatchLive: () -> Unit,
    onStopRecording: () -> Unit
) {
    Dialog(onDismissRequest = onDismiss) {
        Box(
            modifier = Modifier
                .width(400.dp)
                .wrapContentHeight()
                .background(OpenFlixColors.Surface, RoundedCornerShape(16.dp))
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    modifier = Modifier
                        .background(OpenFlixColors.Error, RoundedCornerShape(6.dp))
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

                Text(
                    text = recording.displayTitle,
                    style = MaterialTheme.typography.titleLarge,
                    color = OpenFlixColors.OnSurface,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                recording.episodeInfo?.let { info ->
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(text = info, style = MaterialTheme.typography.bodyMedium, color = OpenFlixColors.TextSecondary)
                }

                Spacer(modifier = Modifier.height(24.dp))
                Text("How would you like to watch?", style = MaterialTheme.typography.bodyLarge, color = OpenFlixColors.TextSecondary)
                Spacer(modifier = Modifier.height(20.dp))

                Button(onClick = onWatchFromStart, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(vertical = 8.dp)) {
                        Text("Watch from Start", style = MaterialTheme.typography.titleMedium)
                        Text("Start from the beginning", style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.OnPrimary.copy(alpha = 0.8f))
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                Button(onClick = onWatchLive, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error)) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(vertical = 8.dp)) {
                        Text("Watch Live", style = MaterialTheme.typography.titleMedium)
                        Text("Jump to live broadcast", style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.OnPrimary.copy(alpha = 0.8f))
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
                Button(onClick = onStopRecording, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Warning)) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(vertical = 8.dp)) {
                        Text("Stop Recording", style = MaterialTheme.typography.titleMedium, color = Color.White)
                        Text("End the recording now", style = MaterialTheme.typography.bodySmall, color = Color.White.copy(alpha = 0.8f))
                    }
                }
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) {
                    Text("Cancel")
                }
            }
        }
    }
}

// ============ Shared Components ============

@Composable
private fun PulsingDot(size: androidx.compose.ui.unit.Dp = 8.dp) {
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
            .size(size)
            .clip(CircleShape)
            .background(OpenFlixColors.Error.copy(alpha = alpha))
    )
}

private fun formatBytes(bytes: Long): String {
    if (bytes <= 0) return "0 B"
    val units = arrayOf("B", "KB", "MB", "GB", "TB")
    var value = bytes.toDouble()
    var unitIndex = 0
    while (value >= 1024 && unitIndex < units.size - 1) {
        value /= 1024
        unitIndex++
    }
    return "%.1f %s".format(value, units[unitIndex])
}

private fun formatDuration(durationMs: Long?): String {
    if (durationMs == null || durationMs <= 0) return ""
    val totalSeconds = durationMs / 1000
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    return if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
}

private fun formatScheduledTime(startTimeMs: Long): String {
    if (startTimeMs <= 0) return ""
    return try {
        val instant = java.time.Instant.ofEpochMilli(startTimeMs)
        val zdt = instant.atZone(java.time.ZoneId.systemDefault())
        val formatter = java.time.format.DateTimeFormatter.ofPattern("EEE, MMM d 'at' h:mm a")
        zdt.format(formatter)
    } catch (e: Exception) {
        ""
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
