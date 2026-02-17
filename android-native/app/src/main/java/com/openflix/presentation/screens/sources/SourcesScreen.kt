package com.openflix.presentation.screens.sources

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import com.openflix.domain.model.M3USource
import com.openflix.domain.model.XtreamSource
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun SourcesScreen(
    onBack: () -> Unit,
    onAddXtreamSource: () -> Unit,
    onAddM3USource: () -> Unit,
    onEditXtreamSource: (Int) -> Unit,
    onEditM3USource: (Int) -> Unit,
    viewModel: SourcesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Handle success message
    LaunchedEffect(uiState.successMessage) {
        if (uiState.successMessage != null) {
            // Auto-clear after showing
            kotlinx.coroutines.delay(3000)
            viewModel.clearSuccessMessage()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Button(onClick = onBack) {
                Text("Back")
            }

            Spacer(modifier = Modifier.width(24.dp))

            Text(
                text = "Manage Sources",
                style = MaterialTheme.typography.displaySmall,
                color = OpenFlixColors.OnSurface
            )

            Spacer(modifier = Modifier.weight(1f))

            // Add buttons
            Button(
                onClick = onAddXtreamSource,
                colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)
            ) {
                Text("Add Xtream")
            }

            Spacer(modifier = Modifier.width(12.dp))

            Button(
                onClick = onAddM3USource,
                colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Secondary)
            ) {
                Text("Add M3U")
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Status messages
        uiState.error?.let { error ->
            Surface(
                modifier = Modifier.fillMaxWidth(),
                colors = NonInteractiveSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.Error.copy(alpha = 0.2f)
                ),
                shape = MaterialTheme.shapes.medium
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = error,
                        color = OpenFlixColors.Error,
                        modifier = Modifier.weight(1f)
                    )
                    Button(onClick = { viewModel.clearError() }) {
                        Text("Dismiss")
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }

        uiState.successMessage?.let { message ->
            Surface(
                modifier = Modifier.fillMaxWidth(),
                colors = NonInteractiveSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.Success.copy(alpha = 0.2f)
                ),
                shape = MaterialTheme.shapes.medium
            ) {
                Text(
                    text = message,
                    color = OpenFlixColors.Success,
                    modifier = Modifier.padding(16.dp)
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Loading indicator
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                Text("Loading sources...", color = OpenFlixColors.TextSecondary)
            }
            Spacer(modifier = Modifier.height(16.dp))
        }

        // Sources list
        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Xtream Sources Section
            if (uiState.xtreamSources.isNotEmpty()) {
                item {
                    SectionHeader("Xtream Sources")
                }

                items(uiState.xtreamSources) { source ->
                    XtreamSourceCard(
                        source = source,
                        isRefreshing = uiState.isRefreshing,
                        isTesting = uiState.isTesting,
                        isImporting = uiState.isImporting,
                        onEdit = { onEditXtreamSource(source.id) },
                        onRefresh = { viewModel.refreshXtreamSource(source.id) },
                        onTest = { viewModel.testXtreamSource(source.id) },
                        onDelete = { viewModel.deleteXtreamSource(source.id) },
                        onImportVOD = { viewModel.importXtreamVOD(source.id) },
                        onImportSeries = { viewModel.importXtreamSeries(source.id) }
                    )
                }
            }

            // M3U Sources Section
            if (uiState.m3uSources.isNotEmpty()) {
                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    SectionHeader("M3U Sources")
                }

                items(uiState.m3uSources) { source ->
                    M3USourceCard(
                        source = source,
                        isRefreshing = uiState.isRefreshing,
                        isImporting = uiState.isImporting,
                        onEdit = { onEditM3USource(source.id) },
                        onRefresh = { viewModel.refreshM3USource(source.id) },
                        onDelete = { viewModel.deleteM3USource(source.id) },
                        onImportVOD = { viewModel.importM3UVOD(source.id) },
                        onImportSeries = { viewModel.importM3USeries(source.id) }
                    )
                }
            }

            // Empty state
            if (uiState.xtreamSources.isEmpty() && uiState.m3uSources.isEmpty() && !uiState.isLoading) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(64.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "No sources configured",
                                style = MaterialTheme.typography.headlineMedium,
                                color = OpenFlixColors.TextSecondary
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "Add an Xtream or M3U source to get started",
                                style = MaterialTheme.typography.bodyLarge,
                                color = OpenFlixColors.TextTertiary
                            )
                        }
                    }
                }
            }

            item {
                Spacer(modifier = Modifier.height(48.dp))
            }
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleLarge,
        color = OpenFlixColors.Primary,
        modifier = Modifier.padding(vertical = 8.dp)
    )
}

@Composable
private fun XtreamSourceCard(
    source: XtreamSource,
    isRefreshing: Boolean,
    isTesting: Boolean,
    isImporting: Boolean,
    onEdit: () -> Unit,
    onRefresh: () -> Unit,
    onTest: () -> Unit,
    onDelete: () -> Unit,
    onImportVOD: () -> Unit,
    onImportSeries: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    var showDeleteConfirm by remember { mutableStateOf(false) }

    Surface(
        onClick = onEdit,
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
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = source.name,
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.OnSurface
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        StatusBadge(enabled = source.enabled)
                    }
                    Text(
                        text = source.serverUrl,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary
                    )
                    Text(
                        text = "User: ${source.username}",
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextTertiary
                    )
                }

                // Expiration badge
                source.expirationDate?.let { exp ->
                    Surface(
                        colors = NonInteractiveSurfaceDefaults.colors(
                            containerColor = OpenFlixColors.Warning.copy(alpha = 0.2f)
                        ),
                        shape = MaterialTheme.shapes.small
                    ) {
                        Text(
                            text = "Exp: $exp",
                            style = MaterialTheme.typography.labelSmall,
                            color = OpenFlixColors.Warning,
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Stats row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                StatItem(label = "Channels", value = source.channelCount.toString())
                StatItem(label = "VOD", value = source.vodCount.toString())
                StatItem(label = "Series", value = source.seriesCount.toString())
                source.lastFetched?.let {
                    StatItem(label = "Last Sync", value = formatTimestamp(it))
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Action buttons row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onTest,
                    enabled = !isTesting,
                    colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Info)
                ) {
                    Text(if (isTesting) "Testing..." else "Test")
                }

                Button(
                    onClick = onRefresh,
                    enabled = !isRefreshing,
                    colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Secondary)
                ) {
                    Text(if (isRefreshing) "Refreshing..." else "Refresh")
                }

                if (source.importVod) {
                    Button(
                        onClick = onImportVOD,
                        enabled = !isImporting,
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)
                    ) {
                        Text(if (isImporting) "Importing..." else "Import VOD")
                    }
                }

                if (source.importSeries) {
                    Button(
                        onClick = onImportSeries,
                        enabled = !isImporting,
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)
                    ) {
                        Text(if (isImporting) "Importing..." else "Import Series")
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                if (showDeleteConfirm) {
                    Button(
                        onClick = {
                            onDelete()
                            showDeleteConfirm = false
                        },
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error)
                    ) {
                        Text("Confirm Delete")
                    }
                    Button(
                        onClick = { showDeleteConfirm = false }
                    ) {
                        Text("Cancel")
                    }
                } else {
                    Button(
                        onClick = { showDeleteConfirm = true },
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error.copy(alpha = 0.7f))
                    ) {
                        Text("Delete")
                    }
                }
            }
        }
    }
}

@Composable
private fun M3USourceCard(
    source: M3USource,
    isRefreshing: Boolean,
    isImporting: Boolean,
    onEdit: () -> Unit,
    onRefresh: () -> Unit,
    onDelete: () -> Unit,
    onImportVOD: () -> Unit,
    onImportSeries: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    var showDeleteConfirm by remember { mutableStateOf(false) }

    Surface(
        onClick = onEdit,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) {
                    Modifier.border(
                        BorderStroke(2.dp, OpenFlixColors.Secondary),
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
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            // Header row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = source.name,
                            style = MaterialTheme.typography.titleMedium,
                            color = OpenFlixColors.OnSurface
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        StatusBadge(enabled = source.enabled)
                    }
                    Text(
                        text = source.url,
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary,
                        maxLines = 1
                    )
                    source.epgUrl?.let { epg ->
                        Text(
                            text = "EPG: $epg",
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextTertiary,
                            maxLines = 1
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Stats row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                StatItem(label = "Channels", value = source.channelCount.toString())
                StatItem(label = "VOD", value = source.vodCount.toString())
                StatItem(label = "Series", value = source.seriesCount.toString())
                source.lastFetched?.let {
                    StatItem(label = "Last Sync", value = formatTimestamp(it))
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Action buttons row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onRefresh,
                    enabled = !isRefreshing,
                    colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Secondary)
                ) {
                    Text(if (isRefreshing) "Refreshing..." else "Refresh")
                }

                if (source.importVod) {
                    Button(
                        onClick = onImportVOD,
                        enabled = !isImporting,
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)
                    ) {
                        Text(if (isImporting) "Importing..." else "Import VOD")
                    }
                }

                if (source.importSeries) {
                    Button(
                        onClick = onImportSeries,
                        enabled = !isImporting,
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)
                    ) {
                        Text(if (isImporting) "Importing..." else "Import Series")
                    }
                }

                Spacer(modifier = Modifier.weight(1f))

                if (showDeleteConfirm) {
                    Button(
                        onClick = {
                            onDelete()
                            showDeleteConfirm = false
                        },
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error)
                    ) {
                        Text("Confirm Delete")
                    }
                    Button(
                        onClick = { showDeleteConfirm = false }
                    ) {
                        Text("Cancel")
                    }
                } else {
                    Button(
                        onClick = { showDeleteConfirm = true },
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Error.copy(alpha = 0.7f))
                    ) {
                        Text("Delete")
                    }
                }
            }
        }
    }
}

@Composable
private fun StatusBadge(enabled: Boolean) {
    Surface(
        colors = NonInteractiveSurfaceDefaults.colors(
            containerColor = if (enabled) OpenFlixColors.Success.copy(alpha = 0.2f)
            else OpenFlixColors.Error.copy(alpha = 0.2f)
        ),
        shape = MaterialTheme.shapes.small
    ) {
        Text(
            text = if (enabled) "Enabled" else "Disabled",
            style = MaterialTheme.typography.labelSmall,
            color = if (enabled) OpenFlixColors.Success else OpenFlixColors.Error,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
        )
    }
}

@Composable
private fun StatItem(label: String, value: String) {
    Column {
        Text(
            text = value,
            style = MaterialTheme.typography.titleSmall,
            color = OpenFlixColors.OnSurface
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = OpenFlixColors.TextTertiary
        )
    }
}

private fun formatTimestamp(timestamp: String): String {
    // Simple format - just show date part if it's an ISO timestamp
    return timestamp.substringBefore("T").ifEmpty { timestamp }
}
