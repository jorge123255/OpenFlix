package com.openflix.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.openflix.domain.model.Recording
import com.openflix.domain.model.RecordingStatus
import com.openflix.domain.model.WatchlistItem
import com.openflix.ui.theme.OpenFlixColors
import com.openflix.ui.viewmodel.LibraryViewModel
import org.koin.compose.viewmodel.koinViewModel

private enum class LibrarySection(val label: String) {
    RECORDINGS("Recordings"),
    SCHEDULED("Scheduled"),
    WATCHLIST("Watchlist")
}

@Composable
fun LibraryScreen(
    onMediaClick: (String) -> Unit = {},
    viewModel: LibraryViewModel = koinViewModel()
) {
    var selectedSection by remember { mutableStateOf(LibrarySection.RECORDINGS) }
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadRecordings()
        viewModel.loadWatchlist()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background)
    ) {
        // Section filter chips — extra left padding for hamburger button
        LazyRow(
            contentPadding = PaddingValues(start = 56.dp, end = 16.dp, top = 12.dp, bottom = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            items(LibrarySection.entries) { section ->
                FilterChip(
                    label = section.label,
                    isSelected = selectedSection == section,
                    onClick = { selectedSection = section }
                )
            }
        }

        when (selectedSection) {
            LibrarySection.RECORDINGS -> RecordingsContent(
                recordings = uiState.recordings.filter {
                    it.status == RecordingStatus.COMPLETED || it.status == RecordingStatus.RECORDING
                },
                isLoading = uiState.isLoading,
                onRecordingClick = { onMediaClick(it.toString()) }
            )
            LibrarySection.SCHEDULED -> ScheduledContent(
                recordings = uiState.recordings.filter {
                    it.status == RecordingStatus.SCHEDULED
                },
                isLoading = uiState.isLoading,
                onCancel = { viewModel.deleteRecording(it) }
            )
            LibrarySection.WATCHLIST -> WatchlistContent(
                items = uiState.watchlist,
                onMediaClick = onMediaClick
            )
        }
    }
}

@Composable
private fun FilterChip(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(if (isSelected) OpenFlixColors.Primary else OpenFlixColors.SurfaceVariant)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Text(
            text = label,
            fontSize = 14.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
            color = if (isSelected) OpenFlixColors.OnPrimary else OpenFlixColors.TextSecondary
        )
    }
}

@Composable
private fun RecordingsContent(
    recordings: List<Recording>,
    isLoading: Boolean,
    onRecordingClick: (Int) -> Unit
) {
    when {
        isLoading -> LoadingScreen("Loading recordings...")
        recordings.isEmpty() -> EmptyState(
            icon = Icons.AutoMirrored.Filled.List,
            title = "No Recordings",
            subtitle = "Recorded content will appear here"
        )
        else -> {
            LazyColumn(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(recordings) { recording ->
                    RecordingCard(
                        recording = recording,
                        onClick = { onRecordingClick(recording.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun RecordingCard(
    recording: Recording,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(OpenFlixColors.SurfaceElevated)
            .clickable(onClick = onClick)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Thumbnail
        Box(
            modifier = Modifier
                .size(120.dp, 68.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(OpenFlixColors.Surface)
        ) {
            val imageUrl = recording.art ?: recording.thumb
            if (imageUrl != null) {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = recording.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            }
            if (recording.status == RecordingStatus.RECORDING) {
                Box(
                    modifier = Modifier
                        .align(Alignment.TopStart)
                        .padding(4.dp)
                        .background(OpenFlixColors.LiveIndicator, RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text("REC", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
                }
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = recording.title,
                color = OpenFlixColors.TextPrimary,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            recording.channelName?.let { channel ->
                Text(text = channel, color = OpenFlixColors.TextSecondary, fontSize = 13.sp)
            }
        }
    }
}

@Composable
private fun ScheduledContent(
    recordings: List<Recording>,
    isLoading: Boolean,
    onCancel: (Int) -> Unit
) {
    when {
        isLoading -> LoadingScreen("Loading scheduled...")
        recordings.isEmpty() -> EmptyState(
            icon = Icons.Default.DateRange,
            title = "No Scheduled Recordings",
            subtitle = "Recordings you schedule will appear here"
        )
        else -> {
            LazyColumn(
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                item {
                    Text(
                        text = "${recordings.size} upcoming",
                        color = OpenFlixColors.TextTertiary,
                        fontSize = 13.sp
                    )
                }
                items(recordings) { recording ->
                    ScheduledRecordingCard(
                        recording = recording,
                        onCancel = { onCancel(recording.id) }
                    )
                }
            }
        }
    }
}

@Composable
private fun ScheduledRecordingCard(
    recording: Recording,
    onCancel: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(OpenFlixColors.SurfaceElevated)
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Thumbnail
        Box(
            modifier = Modifier
                .size(120.dp, 68.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(OpenFlixColors.Surface)
        ) {
            val imageUrl = recording.art ?: recording.thumb
            if (imageUrl != null) {
                AsyncImage(
                    model = imageUrl,
                    contentDescription = recording.title,
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
            }
            Box(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(4.dp)
                    .background(OpenFlixColors.Primary, RoundedCornerShape(4.dp))
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text("SCHEDULED", color = Color.White, fontSize = 9.sp, fontWeight = FontWeight.Bold)
            }
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = recording.title,
                color = OpenFlixColors.TextPrimary,
                fontSize = 15.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            recording.channelName?.let { channel ->
                Text(text = channel, color = OpenFlixColors.TextSecondary, fontSize = 13.sp)
            }
        }

        // Cancel button
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(OpenFlixColors.Error.copy(alpha = 0.15f))
                .clickable(onClick = onCancel),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Close,
                contentDescription = "Cancel recording",
                tint = OpenFlixColors.Error,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}

@Composable
private fun WatchlistContent(
    items: List<WatchlistItem>,
    onMediaClick: (String) -> Unit
) {
    if (items.isEmpty()) {
        EmptyState(
            icon = Icons.AutoMirrored.Filled.List,
            title = "Your Watchlist is Empty",
            subtitle = "Items you add to your watchlist will appear here"
        )
    } else {
        LazyColumn(
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(items) { item ->
                val media = item.media
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(OpenFlixColors.SurfaceElevated)
                        .clickable { media?.let { onMediaClick(it.key) } }
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(100.dp, 56.dp)
                            .clip(RoundedCornerShape(8.dp))
                            .background(OpenFlixColors.Surface)
                    ) {
                        val thumb = media?.thumb
                        if (thumb != null) {
                            AsyncImage(
                                model = thumb,
                                contentDescription = media.title,
                                modifier = Modifier.fillMaxSize(),
                                contentScale = ContentScale.Crop
                            )
                        }
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = media?.title ?: "Unknown",
                            color = OpenFlixColors.TextPrimary,
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Medium,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                        Text(
                            text = media?.type?.displayName ?: "",
                            color = OpenFlixColors.TextTertiary,
                            fontSize = 12.sp
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun EmptyState(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = OpenFlixColors.TextTertiary,
                modifier = Modifier.size(48.dp)
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(text = title, color = OpenFlixColors.TextSecondary, fontSize = 16.sp, fontWeight = FontWeight.Medium)
            Spacer(modifier = Modifier.height(4.dp))
            Text(text = subtitle, color = OpenFlixColors.TextTertiary, fontSize = 13.sp)
        }
    }
}
