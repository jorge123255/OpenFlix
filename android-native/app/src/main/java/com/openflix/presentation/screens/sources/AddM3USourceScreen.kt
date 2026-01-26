package com.openflix.presentation.screens.sources

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun AddM3USourceScreen(
    onBack: () -> Unit,
    onSuccess: () -> Unit,
    editSourceId: Int? = null,
    viewModel: SourcesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Form state
    var name by remember { mutableStateOf("") }
    var url by remember { mutableStateOf("") }
    var epgUrl by remember { mutableStateOf("") }
    var importVod by remember { mutableStateOf(false) }
    var importSeries by remember { mutableStateOf(false) }

    // Load existing source for editing
    LaunchedEffect(editSourceId) {
        if (editSourceId != null) {
            val source = uiState.m3uSources.find { it.id == editSourceId }
            source?.let {
                name = it.name
                url = it.url
                epgUrl = it.epgUrl ?: ""
                importVod = it.importVod
                importSeries = it.importSeries
            }
        }
    }

    // Handle success - navigate back
    LaunchedEffect(uiState.successMessage) {
        if (uiState.successMessage?.contains("created") == true ||
            uiState.successMessage?.contains("updated") == true) {
            onSuccess()
        }
    }

    val isEditing = editSourceId != null
    val title = if (isEditing) "Edit M3U Source" else "Add M3U Source"

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
                Text("Cancel")
            }

            Spacer(modifier = Modifier.width(24.dp))

            Text(
                text = title,
                style = MaterialTheme.typography.displaySmall,
                color = OpenFlixColors.OnSurface
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        // Error display
        uiState.error?.let { error ->
            Surface(
                modifier = Modifier.fillMaxWidth(),
                colors = NonInteractiveSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.Error.copy(alpha = 0.2f)
                ),
                shape = MaterialTheme.shapes.medium
            ) {
                Text(
                    text = error,
                    color = OpenFlixColors.Error,
                    modifier = Modifier.padding(16.dp)
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
        }

        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Name field
            item {
                M3UFormTextField(
                    label = "Name",
                    value = name,
                    onValueChange = { name = it },
                    placeholder = "My M3U Source"
                )
            }

            // M3U URL field
            item {
                M3UFormTextField(
                    label = "M3U URL",
                    value = url,
                    onValueChange = { url = it },
                    placeholder = "http://example.com/playlist.m3u"
                )
            }

            // EPG URL field (optional)
            item {
                M3UFormTextField(
                    label = "EPG URL (Optional)",
                    value = epgUrl,
                    onValueChange = { epgUrl = it },
                    placeholder = "http://example.com/epg.xml"
                )
            }

            // Import options section
            item {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Import Options",
                    style = MaterialTheme.typography.titleMedium,
                    color = OpenFlixColors.Primary
                )
            }

            item {
                M3UFormToggle(
                    label = "Import VOD (Movies)",
                    subtitle = "Import video-on-demand content from VOD groups",
                    checked = importVod,
                    onCheckedChange = { importVod = it }
                )
            }

            item {
                M3UFormToggle(
                    label = "Import Series",
                    subtitle = "Import TV series content from series groups",
                    checked = importSeries,
                    onCheckedChange = { importSeries = it }
                )
            }

            // Help text
            item {
                Surface(
                    modifier = Modifier.fillMaxWidth(),
                    colors = NonInteractiveSurfaceDefaults.colors(
                        containerColor = OpenFlixColors.Info.copy(alpha = 0.1f)
                    ),
                    shape = MaterialTheme.shapes.medium
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "About M3U Sources",
                            style = MaterialTheme.typography.titleSmall,
                            color = OpenFlixColors.Info
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "M3U playlists can contain live TV channels, movies (VOD), and TV series. " +
                                    "The system automatically detects content type based on group names and stream properties.",
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextSecondary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Live TV channels are always imported. Enable VOD/Series import to add that content to your library.",
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                }
            }

            // Action buttons
            item {
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    // Save button
                    Button(
                        onClick = {
                            if (isEditing) {
                                viewModel.updateM3USource(
                                    id = editSourceId!!,
                                    name = name.ifBlank { null },
                                    url = url.ifBlank { null },
                                    epgUrl = epgUrl.ifBlank { null },
                                    importVod = importVod,
                                    importSeries = importSeries
                                )
                            } else {
                                viewModel.createM3USource(
                                    name = name,
                                    url = url,
                                    epgUrl = epgUrl.ifBlank { null }
                                )
                            }
                        },
                        enabled = !uiState.isLoading && name.isNotBlank() && url.isNotBlank(),
                        colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Primary)
                    ) {
                        Text(
                            if (uiState.isLoading) "Saving..."
                            else if (isEditing) "Update Source"
                            else "Add Source"
                        )
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
private fun M3UFormTextField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String = ""
) {
    var isFocused by remember { mutableStateOf(false) }

    Column {
        Text(
            text = label,
            style = MaterialTheme.typography.labelLarge,
            color = OpenFlixColors.OnSurface,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        Surface(
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
                        Modifier.border(
                            BorderStroke(1.dp, OpenFlixColors.TextTertiary.copy(alpha = 0.3f)),
                            MaterialTheme.shapes.medium
                        )
                    }
                ),
            colors = NonInteractiveSurfaceDefaults.colors(
                containerColor = OpenFlixColors.Surface
            ),
            shape = MaterialTheme.shapes.medium
        ) {
            androidx.compose.foundation.text.BasicTextField(
                value = value,
                onValueChange = onValueChange,
                textStyle = MaterialTheme.typography.bodyLarge.copy(
                    color = OpenFlixColors.OnSurface
                ),
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                decorationBox = { innerTextField ->
                    Box {
                        if (value.isEmpty()) {
                            Text(
                                text = placeholder,
                                style = MaterialTheme.typography.bodyLarge,
                                color = OpenFlixColors.TextTertiary
                            )
                        }
                        innerTextField()
                    }
                }
            )
        }
    }
}

@Composable
private fun M3UFormToggle(
    label: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = { onCheckedChange(!checked) },
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
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = label,
                    style = MaterialTheme.typography.bodyLarge,
                    color = OpenFlixColors.OnSurface
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.TextSecondary
                )
            }

            Switch(
                checked = checked,
                onCheckedChange = onCheckedChange
            )
        }
    }
}
