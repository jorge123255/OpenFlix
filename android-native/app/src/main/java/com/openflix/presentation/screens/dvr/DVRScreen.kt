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
import com.openflix.domain.model.*
import com.openflix.presentation.theme.OpenFlixColors

enum class DVRTab(val title: String) {
    RECORDINGS("Recordings"),
    SCHEDULED("Scheduled"),
    SERIES("Series")
}

@Composable
fun DVRScreen(
    onRecordingClick: (recordingId: String, mode: String) -> Unit,
    viewModel: DVRViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedTab by remember { mutableStateOf(DVRTab.RECORDINGS) }

    // State for dialogs
    var showWatchDialog by remember { mutableStateOf(false) }
    var selectedRecording by remember { mutableStateOf<Recording?>(null) }
    var showConflictDialog by remember { mutableStateOf(false) }
    var showSortMenu by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadRecordings()
        viewModel.loadSeriesRules()
        viewModel.loadConflicts()
        viewModel.loadDiskUsage()
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

        Spacer(modifier = Modifier.height(8.dp))

        // Stats summary row
        DVRStatsSummary(
            recordings = uiState.recordings,
            diskUsage = uiState.diskUsage,
            recordingStats = uiState.recordingStats
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Conflict banner
        if (uiState.conflicts?.hasConflicts == true) {
            ConflictBanner(
                conflictCount = uiState.conflicts!!.totalCount,
                onClick = { showConflictDialog = true }
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        // Tabs with recording count
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            DVRTab.entries.forEach { tab ->
                val count = when (tab) {
                    DVRTab.RECORDINGS -> {
                        val active = uiState.recordings.count { it.status == RecordingStatus.RECORDING }
                        val completed = uiState.recordings.count { it.status == RecordingStatus.COMPLETED }
                        val failed = uiState.recordings.count { it.status == RecordingStatus.FAILED }
                        active + completed + failed
                    }
                    DVRTab.SCHEDULED -> uiState.recordings.count { it.status == RecordingStatus.SCHEDULED || it.status == RecordingStatus.PENDING }
                    DVRTab.SERIES -> uiState.seriesRules.size
                }
                val hasActive = tab == DVRTab.RECORDINGS && uiState.recordings.any { it.status == RecordingStatus.RECORDING }

                Button(
                    onClick = { selectedTab = tab },
                    colors = if (selectedTab == tab) {
                        ButtonDefaults.colors(
                            containerColor = if (hasActive) OpenFlixColors.Error else OpenFlixColors.Primary
                        )
                    } else {
                        ButtonDefaults.colors(containerColor = OpenFlixColors.SurfaceVariant)
                    }
                ) {
                    if (hasActive) {
                        PulsingDot()
                        Spacer(modifier = Modifier.width(6.dp))
                    }
                    Text("${tab.title} ($count)")
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Search bar and sort/selection controls (only for Recordings tab)
        if (selectedTab == DVRTab.RECORDINGS) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Search field
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small)
                        .padding(horizontal = 12.dp, vertical = 8.dp)
                ) {
                    if (uiState.searchQuery.isEmpty()) {
                        Text(
                            text = "Search recordings...",
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.TextTertiary
                        )
                    }
                    // The actual TextField would go here but TV uses D-pad, so search is via viewModel
                    Text(
                        text = uiState.searchQuery,
                        style = MaterialTheme.typography.bodyMedium,
                        color = OpenFlixColors.OnSurface
                    )
                }

                // Sort button
                Button(
                    onClick = { showSortMenu = !showSortMenu },
                    colors = ButtonDefaults.colors(containerColor = OpenFlixColors.SurfaceVariant)
                ) {
                    Text(
                        text = when (uiState.sortOrder) {
                            DVRSortOrder.DATE_DESC -> "Newest"
                            DVRSortOrder.DATE_ASC -> "Oldest"
                            DVRSortOrder.TITLE_ASC -> "A-Z"
                            DVRSortOrder.TITLE_DESC -> "Z-A"
                            DVRSortOrder.SIZE_DESC -> "Largest"
                        }
                    )
                }

                // View mode toggle
                Button(
                    onClick = {
                        viewModel.updateViewMode(
                            if (uiState.viewMode == DVRViewMode.LIST) DVRViewMode.GROUPED else DVRViewMode.LIST
                        )
                    },
                    colors = ButtonDefaults.colors(containerColor = OpenFlixColors.SurfaceVariant)
                ) {
                    Text(if (uiState.viewMode == DVRViewMode.LIST) "List" else "Grouped")
                }

                // Selection mode toggle
                Button(
                    onClick = { viewModel.toggleSelectionMode() },
                    colors = ButtonDefaults.colors(
                        containerColor = if (uiState.selectionMode) OpenFlixColors.Primary else OpenFlixColors.SurfaceVariant
                    )
                ) {
                    Text(if (uiState.selectionMode) "Cancel" else "Select")
                }
            }

            // Sort dropdown
            if (showSortMenu) {
                Row(
                    modifier = Modifier.padding(top = 4.dp),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    DVRSortOrder.entries.forEach { order ->
                        Button(
                            onClick = {
                                viewModel.updateSortOrder(order)
                                showSortMenu = false
                            },
                            colors = ButtonDefaults.colors(
                                containerColor = if (uiState.sortOrder == order) OpenFlixColors.Primary else OpenFlixColors.SurfaceVariant
                            )
                        ) {
                            Text(
                                text = when (order) {
                                    DVRSortOrder.DATE_DESC -> "Newest First"
                                    DVRSortOrder.DATE_ASC -> "Oldest First"
                                    DVRSortOrder.TITLE_ASC -> "Title A-Z"
                                    DVRSortOrder.TITLE_DESC -> "Title Z-A"
                                    DVRSortOrder.SIZE_DESC -> "Largest First"
                                },
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    }
                }
            }

            // Bulk delete action bar
            if (uiState.selectionMode && uiState.selectedIds.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(OpenFlixColors.Error.copy(alpha = 0.15f), MaterialTheme.shapes.small)
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "${uiState.selectedIds.size} selected",
                        style = MaterialTheme.typography.bodyMedium,
                        color = OpenFlixColors.OnSurface
                    )
                    Button(
                        onClick = { viewModel.deleteSelected() },
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error)
                    ) {
                        Text("Delete ${uiState.selectedIds.size}")
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
        }

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
                when (selectedTab) {
                    DVRTab.RECORDINGS -> RecordingsTabContent(
                        uiState = uiState,
                        viewModel = viewModel,
                        onRecordingClick = { recording ->
                            if (recording.status == RecordingStatus.RECORDING) {
                                selectedRecording = recording
                                showWatchDialog = true
                            } else {
                                onRecordingClick(recording.id, "default")
                            }
                        }
                    )
                    DVRTab.SCHEDULED -> ScheduledTabContent(
                        recordings = uiState.recordings.filter {
                            it.status == RecordingStatus.SCHEDULED || it.status == RecordingStatus.PENDING
                        },
                        onDelete = { viewModel.deleteRecording(it) }
                    )
                    DVRTab.SERIES -> SeriesTabContent(
                        seriesRules = uiState.seriesRules,
                        onToggle = { id, enabled -> viewModel.toggleSeriesRule(id, enabled) },
                        onDelete = { viewModel.deleteSeriesRule(it) }
                    )
                }
            }
        }
    }
}

// ============ Stats Summary ============

@Composable
private fun DVRStatsSummary(
    recordings: List<Recording>,
    diskUsage: DiskUsage?,
    recordingStats: RecordingStatsData?
) {
    val totalRecordings = recordings.count { it.status == RecordingStatus.COMPLETED }
    val activeCount = recordingStats?.activeCount ?: recordings.count { it.status == RecordingStatus.RECORDING }
    val totalSize = recordings.sumOf { it.fileSize ?: 0L }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small)
            .padding(12.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        StatItem(label = "Recordings", value = "$totalRecordings", color = OpenFlixColors.OnSurface)
        StatItem(
            label = "Active",
            value = "$activeCount",
            color = if (activeCount > 0) OpenFlixColors.Error else OpenFlixColors.TextSecondary
        )
        StatItem(
            label = "Storage",
            value = diskUsage?.usedByDVRFormatted ?: formatBytes(totalSize),
            color = if (diskUsage?.isLow == true) OpenFlixColors.Warning else OpenFlixColors.OnSurface
        )
        if (diskUsage != null) {
            StatItem(
                label = "Free",
                value = diskUsage.freeBytesFormatted,
                color = when {
                    diskUsage.isCritical -> OpenFlixColors.Error
                    diskUsage.isLow -> OpenFlixColors.Warning
                    else -> OpenFlixColors.Success
                }
            )
        }
    }
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

// ============ Recordings Tab ============

@Composable
private fun RecordingsTabContent(
    uiState: DVRUiState,
    viewModel: DVRViewModel,
    onRecordingClick: (Recording) -> Unit
) {
    val items = if (uiState.viewMode == DVRViewMode.GROUPED) {
        // Show grouped view
        null
    } else {
        uiState.filteredRecordings.filter {
            it.status == RecordingStatus.COMPLETED ||
            it.status == RecordingStatus.RECORDING ||
            it.status == RecordingStatus.FAILED ||
            it.status == RecordingStatus.CANCELLED
        }
    }

    if (uiState.viewMode == DVRViewMode.GROUPED) {
        val groups = uiState.groupedRecordings
        if (groups.isEmpty()) {
            EmptyState("No completed recordings")
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                groups.forEach { (title, recordings) ->
                    item {
                        SeriesGroupHeader(
                            title = title,
                            episodeCount = recordings.size,
                            totalSize = recordings.sumOf { it.fileSize ?: 0L },
                            newestDate = recordings.maxByOrNull { it.startTime }?.startTime ?: 0L
                        )
                    }
                    items(recordings) { recording ->
                        RecordingListItem(
                            recording = recording,
                            liveStats = null,
                            isSelected = recording.id in uiState.selectedIds,
                            selectionMode = uiState.selectionMode,
                            onClick = {
                                if (uiState.selectionMode) {
                                    viewModel.toggleSelection(recording.id)
                                } else {
                                    onRecordingClick(recording)
                                }
                            },
                            onDelete = { viewModel.deleteRecording(recording.id) }
                        )
                    }
                }
            }
        }
    } else {
        if (items.isNullOrEmpty()) {
            EmptyState("No recordings")
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                items(items) { recording ->
                    val stats = viewModel.getStatsForRecording(recording.id)
                    RecordingListItem(
                        recording = recording,
                        liveStats = stats,
                        isSelected = recording.id in uiState.selectedIds,
                        selectionMode = uiState.selectionMode,
                        onClick = {
                            if (uiState.selectionMode) {
                                viewModel.toggleSelection(recording.id)
                            } else {
                                onRecordingClick(recording)
                            }
                        },
                        onDelete = { viewModel.deleteRecording(recording.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun SeriesGroupHeader(
    title: String,
    episodeCount: Int,
    totalSize: Long,
    newestDate: Long
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "$title ($episodeCount episodes)",
            style = MaterialTheme.typography.titleSmall,
            color = OpenFlixColors.OnSurface
        )
        Text(
            text = formatBytes(totalSize),
            style = MaterialTheme.typography.bodySmall,
            color = OpenFlixColors.TextTertiary
        )
    }
}

// ============ Scheduled Tab ============

@Composable
private fun ScheduledTabContent(
    recordings: List<Recording>,
    onDelete: (String) -> Unit
) {
    if (recordings.isEmpty()) {
        EmptyState("No scheduled recordings")
    } else {
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(recordings) { recording ->
                RecordingListItem(
                    recording = recording,
                    liveStats = null,
                    isSelected = false,
                    selectionMode = false,
                    onClick = { },
                    onDelete = { onDelete(recording.id) }
                )
            }
        }
    }
}

// ============ Series Rules Tab ============

@Composable
private fun SeriesTabContent(
    seriesRules: List<SeriesRule>,
    onToggle: (Long, Boolean) -> Unit,
    onDelete: (Long) -> Unit
) {
    if (seriesRules.isEmpty()) {
        EmptyState("No series rules. Record a series from the EPG guide to create one.")
    } else {
        LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            items(seriesRules) { rule ->
                SeriesRuleRow(
                    rule = rule,
                    onToggle = { enabled -> onToggle(rule.id, enabled) },
                    onDelete = { onDelete(rule.id) }
                )
            }
        }
    }
}

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
                if (isFocused) {
                    Modifier.border(BorderStroke(2.dp, OpenFlixColors.Primary), MaterialTheme.shapes.medium)
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
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Enable/disable indicator
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
                    rule.keywords?.let { kw ->
                        if (kw.isNotBlank()) {
                            Text("Keywords: $kw", style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextSecondary)
                        }
                    }
                }
            }

            // Toggle button
            Button(
                onClick = { onToggle(!rule.enabled) },
                colors = ButtonDefaults.colors(
                    containerColor = if (rule.enabled) OpenFlixColors.Success else OpenFlixColors.SurfaceVariant
                )
            ) {
                Text(if (rule.enabled) "Enabled" else "Disabled")
            }

            Spacer(modifier = Modifier.width(8.dp))

            // Delete button
            Button(
                onClick = onDelete,
                colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error)
            ) {
                Text("Delete")
            }
        }
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
                .background(OpenFlixColors.Surface, MaterialTheme.shapes.large)
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
                                .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small)
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

// ============ Watch Options Dialog ============

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
private fun EmptyState(message: String) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(text = message, color = OpenFlixColors.TextSecondary)
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
    isSelected: Boolean,
    selectionMode: Boolean,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val isRecording = recording.status == RecordingStatus.RECORDING
    val isFailed = liveStats?.isFailed == true

    val posterImage = recording.posterUrl
    val backdropImage = recording.backdropUrl

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isSelected) {
                    Modifier.border(BorderStroke(2.dp, OpenFlixColors.Primary), MaterialTheme.shapes.medium)
                } else if (isFocused) {
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
            containerColor = if (isSelected) OpenFlixColors.Primary.copy(alpha = 0.1f) else OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Column {
            // Live progress bar
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
                // Selection checkbox
                if (selectionMode) {
                    Box(
                        modifier = Modifier
                            .size(24.dp)
                            .clip(MaterialTheme.shapes.extraSmall)
                            .background(
                                if (isSelected) OpenFlixColors.Primary else OpenFlixColors.SurfaceVariant
                            )
                            .border(1.dp, OpenFlixColors.TextTertiary, MaterialTheme.shapes.extraSmall),
                        contentAlignment = Alignment.Center
                    ) {
                        if (isSelected) {
                            Text("✓", color = Color.White, style = MaterialTheme.typography.labelSmall)
                        }
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                }

                // Poster Image
                Box(
                    modifier = Modifier
                        .then(
                            if (recording.isMovie) {
                                Modifier.size(90.dp, 135.dp)
                            } else {
                                Modifier.size(160.dp, 90.dp)
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

                    // Metadata badges
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        recording.year?.let { year ->
                            Text(year.toString(), style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextSecondary)
                        }
                        recording.contentRating?.let { cr ->
                            if (cr.isNotBlank()) {
                                Box(
                                    modifier = Modifier
                                        .border(1.dp, OpenFlixColors.TextTertiary, MaterialTheme.shapes.extraSmall)
                                        .padding(horizontal = 4.dp, vertical = 1.dp)
                                ) {
                                    Text(cr, style = MaterialTheme.typography.labelSmall, color = OpenFlixColors.TextSecondary)
                                }
                            }
                        }
                        recording.rating?.let { rating ->
                            if (rating > 0) {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                                    Text("★", style = MaterialTheme.typography.labelSmall, color = Color(0xFFFFD700))
                                    Text(String.format("%.1f", rating), style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextSecondary)
                                }
                            }
                        }
                        if (recording.isMovie) {
                            Box(
                                modifier = Modifier
                                    .background(OpenFlixColors.Primary.copy(alpha = 0.2f), MaterialTheme.shapes.extraSmall)
                                    .padding(horizontal = 4.dp, vertical = 1.dp)
                            ) {
                                Text("MOVIE", style = MaterialTheme.typography.labelSmall, color = OpenFlixColors.Primary)
                            }
                        }
                    }

                    recording.episodeInfo?.let { info ->
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(info, style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextSecondary)
                    }

                    recording.genres?.let { genres ->
                        if (genres.isNotBlank()) {
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(genres, style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextTertiary, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        }
                    }

                    if (recording.channelLogo == null || recording.isMovie) {
                        recording.channelName?.let { channel ->
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(channel, style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextTertiary)
                        }
                    }

                    val summaryText = recording.summary ?: recording.description
                    if (!summaryText.isNullOrBlank() && !isRecording) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(summaryText, style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextTertiary, maxLines = 2, overflow = TextOverflow.Ellipsis)
                    }

                    // Live recording stats
                    if (isRecording && liveStats != null) {
                        Spacer(modifier = Modifier.height(12.dp))
                        if (isFailed) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(OpenFlixColors.Error.copy(alpha = 0.15f), MaterialTheme.shapes.small)
                                    .border(1.dp, OpenFlixColors.Error.copy(alpha = 0.3f), MaterialTheme.shapes.small)
                                    .padding(12.dp)
                            ) {
                                Column {
                                    Text("Recording Failed", style = MaterialTheme.typography.labelLarge, color = OpenFlixColors.Error)
                                    liveStats.failureReason?.let { reason ->
                                        Spacer(modifier = Modifier.height(4.dp))
                                        Text(reason, style = MaterialTheme.typography.bodySmall, color = OpenFlixColors.TextSecondary)
                                    }
                                }
                            }
                        } else {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small)
                                    .border(1.dp, OpenFlixColors.Success.copy(alpha = 0.3f), MaterialTheme.shapes.small)
                                    .padding(12.dp)
                            ) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    StatItem(label = "File Size", value = liveStats.fileSizeFormatted, color = OpenFlixColors.Success)
                                    StatItem(label = "Elapsed", value = liveStats.elapsedFormatted, color = OpenFlixColors.Success)
                                    StatItem(label = "Progress", value = "${liveStats.progressPercent.toInt()}%", color = OpenFlixColors.Success)
                                    if (liveStats.bitrate != null) {
                                        StatItem(label = "Bitrate", value = liveStats.bitrate, color = OpenFlixColors.Success)
                                    }
                                    StatItem(
                                        label = "Health",
                                        value = if (liveStats.isHealthy) "Good" else "Slow",
                                        color = if (liveStats.isHealthy) OpenFlixColors.Success else OpenFlixColors.Warning
                                    )
                                }
                            }
                        }
                    } else {
                        // Watch progress bar
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
