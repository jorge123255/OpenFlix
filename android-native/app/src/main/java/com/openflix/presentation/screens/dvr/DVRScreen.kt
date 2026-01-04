package com.openflix.presentation.screens.dvr

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Recording
import com.openflix.domain.model.RecordingStatus
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun DVRScreen(
    onRecordingClick: (String) -> Unit,
    viewModel: DVRViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedTab by remember { mutableStateOf(DVRTab.RECORDINGS) }

    LaunchedEffect(Unit) {
        viewModel.loadRecordings()
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

        // Tabs
        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
            DVRTab.entries.forEach { tab ->
                Button(
                    onClick = { selectedTab = tab },
                    colors = if (selectedTab == tab) {
                        ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)
                    } else {
                        ButtonDefaults.colors(containerColor = OpenFlixColors.SurfaceVariant)
                    }
                ) {
                    Text(tab.title)
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
                    DVRTab.RECORDINGS -> uiState.recordings.filter { it.status == RecordingStatus.COMPLETED }
                    DVRTab.SCHEDULED -> uiState.recordings.filter { it.status == RecordingStatus.PENDING }
                    DVRTab.SERIES -> uiState.recordings.filter { it.seriesId != null }
                        .distinctBy { it.seriesId }
                }

                if (items.isEmpty()) {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "No ${selectedTab.title.lowercase()} found",
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                } else {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(items) { recording ->
                            RecordingListItem(
                                recording = recording,
                                onClick = { onRecordingClick(recording.id) },
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
private fun RecordingListItem(
    recording: Recording,
    onClick: () -> Unit,
    onDelete: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) {
                    Modifier.border(
                        BorderStroke(2.dp, OpenFlixColors.Primary),
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
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Thumbnail
            AsyncImage(
                model = recording.thumb,
                contentDescription = recording.title,
                modifier = Modifier
                    .size(120.dp, 68.dp)
                    .background(OpenFlixColors.SurfaceVariant, MaterialTheme.shapes.small),
                contentScale = ContentScale.Crop
            )

            Spacer(modifier = Modifier.width(16.dp))

            // Info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = recording.displayTitle,
                        style = MaterialTheme.typography.titleMedium,
                        color = OpenFlixColors.OnSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    if (recording.status == RecordingStatus.RECORDING) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .background(OpenFlixColors.Recording, MaterialTheme.shapes.extraSmall)
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text("REC", style = MaterialTheme.typography.labelSmall, color = OpenFlixColors.OnPrimary)
                        }
                    }
                }

                recording.episodeInfo?.let { info ->
                    Text(
                        text = info,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary
                    )
                }

                recording.channelName?.let { channel ->
                    Text(
                        text = channel,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextTertiary
                    )
                }

                // Progress bar if watching
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

            // File size
            Text(
                text = recording.fileSizeDisplay,
                style = MaterialTheme.typography.bodySmall,
                color = OpenFlixColors.TextTertiary
            )
        }
    }
}

enum class DVRTab(val title: String) {
    RECORDINGS("Recordings"),
    SCHEDULED("Scheduled"),
    SERIES("Series")
}
