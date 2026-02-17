package com.openflix.presentation.screens.sources

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun AddXtreamSourceScreen(
    onBack: () -> Unit,
    onSuccess: () -> Unit,
    editSourceId: Int? = null,
    viewModel: SourcesViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Form state
    var name by remember { mutableStateOf("") }
    var serverUrl by remember { mutableStateOf("") }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var importLive by remember { mutableStateOf(true) }
    var importVod by remember { mutableStateOf(false) }
    var importSeries by remember { mutableStateOf(false) }
    var showPassword by remember { mutableStateOf(false) }

    // Load existing source for editing
    LaunchedEffect(editSourceId) {
        if (editSourceId != null) {
            val source = uiState.xtreamSources.find { it.id == editSourceId }
            source?.let {
                name = it.name
                serverUrl = it.serverUrl
                username = it.username
                importLive = it.importLive
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
    val title = if (isEditing) "Edit Xtream Source" else "Add Xtream Source"

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

        // Test result display
        uiState.testResult?.let { result ->
            Surface(
                modifier = Modifier.fillMaxWidth(),
                colors = NonInteractiveSurfaceDefaults.colors(
                    containerColor = if (result.success) OpenFlixColors.Success.copy(alpha = 0.2f)
                    else OpenFlixColors.Error.copy(alpha = 0.2f)
                ),
                shape = MaterialTheme.shapes.medium
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = if (result.success) "Connection Successful" else "Connection Failed",
                        style = MaterialTheme.typography.titleMedium,
                        color = if (result.success) OpenFlixColors.Success else OpenFlixColors.Error
                    )
                    if (result.success) {
                        result.expirationDate?.let {
                            Text(
                                text = "Expiration: $it",
                                color = OpenFlixColors.TextSecondary
                            )
                        }
                        result.maxConnections?.let {
                            Text(
                                text = "Max Connections: $it",
                                color = OpenFlixColors.TextSecondary
                            )
                        }
                    } else {
                        Text(
                            text = result.message,
                            color = OpenFlixColors.TextSecondary
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
        }

        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Name field
            item {
                FormTextField(
                    label = "Name",
                    value = name,
                    onValueChange = { name = it },
                    placeholder = "My Xtream Source"
                )
            }

            // Server URL field
            item {
                FormTextField(
                    label = "Server URL",
                    value = serverUrl,
                    onValueChange = { serverUrl = it },
                    placeholder = "http://example.com:8080"
                )
            }

            // Username field
            item {
                FormTextField(
                    label = "Username",
                    value = username,
                    onValueChange = { username = it },
                    placeholder = "username"
                )
            }

            // Password field
            item {
                FormTextField(
                    label = "Password",
                    value = password,
                    onValueChange = { password = it },
                    placeholder = if (isEditing) "(unchanged)" else "password",
                    isPassword = !showPassword,
                    trailingContent = {
                        Button(
                            onClick = { showPassword = !showPassword },
                            colors = ButtonDefaults.colors(
                                containerColor = OpenFlixColors.Surface
                            )
                        ) {
                            Text(if (showPassword) "Hide" else "Show")
                        }
                    }
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
                FormToggle(
                    label = "Import Live TV Channels",
                    subtitle = "Sync live TV channels from this source",
                    checked = importLive,
                    onCheckedChange = { importLive = it }
                )
            }

            item {
                FormToggle(
                    label = "Import VOD (Movies)",
                    subtitle = "Import video-on-demand content to your library",
                    checked = importVod,
                    onCheckedChange = { importVod = it }
                )
            }

            item {
                FormToggle(
                    label = "Import Series",
                    subtitle = "Import TV series to your library",
                    checked = importSeries,
                    onCheckedChange = { importSeries = it }
                )
            }

            // Action buttons
            item {
                Spacer(modifier = Modifier.height(16.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Test button (only for editing existing sources)
                    if (isEditing) {
                        Button(
                            onClick = { viewModel.testXtreamSource(editSourceId!!) },
                            enabled = !uiState.isTesting,
                            colors = ButtonDefaults.colors(containerColor = OpenFlixColors.Info)
                        ) {
                            Text(if (uiState.isTesting) "Testing..." else "Test Connection")
                        }
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    // Save button
                    Button(
                        onClick = {
                            if (isEditing) {
                                viewModel.updateXtreamSource(
                                    id = editSourceId!!,
                                    name = name.ifBlank { null },
                                    serverUrl = serverUrl.ifBlank { null },
                                    username = username.ifBlank { null },
                                    password = password.ifBlank { null },
                                    importLive = importLive,
                                    importVod = importVod,
                                    importSeries = importSeries
                                )
                            } else {
                                viewModel.createXtreamSource(
                                    name = name,
                                    serverUrl = serverUrl,
                                    username = username,
                                    password = password,
                                    importLive = importLive,
                                    importVod = importVod,
                                    importSeries = importSeries
                                )
                            }
                        },
                        enabled = !uiState.isLoading && name.isNotBlank() &&
                                serverUrl.isNotBlank() && username.isNotBlank() &&
                                (isEditing || password.isNotBlank()),
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
private fun FormTextField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String = "",
    isPassword: Boolean = false,
    trailingContent: @Composable (() -> Unit)? = null
) {
    var isFocused by remember { mutableStateOf(false) }

    Column {
        Text(
            text = label,
            style = MaterialTheme.typography.labelLarge,
            color = OpenFlixColors.OnSurface,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Surface(
                modifier = Modifier
                    .weight(1f)
                    .onFocusChanged { isFocused = it.isFocused }
                    .then(
                        if (isFocused) {
                            Modifier.border(
                                BorderStroke(2.dp, OpenFlixColors.Primary),
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
                    visualTransformation = if (isPassword) PasswordVisualTransformation()
                    else VisualTransformation.None,
                    keyboardOptions = if (isPassword) KeyboardOptions(keyboardType = KeyboardType.Password)
                    else KeyboardOptions.Default,
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

            trailingContent?.let {
                Spacer(modifier = Modifier.width(8.dp))
                it()
            }
        }
    }
}

@Composable
private fun FormToggle(
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
