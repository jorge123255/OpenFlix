package com.openflix.presentation.screens.livetv

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.openflix.domain.model.Channel
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun ChannelLogoEditorScreen(
    onBack: () -> Unit,
    viewModel: ChannelLogoEditorViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Channel editor dialog
    if (uiState.showEditor && uiState.selectedChannel != null) {
        ChannelEditorDialog(
            channel = uiState.selectedChannel!!,
            editName = uiState.editName,
            editNumber = uiState.editNumber,
            editLogoUrl = uiState.editLogoUrl,
            editGroup = uiState.editGroup,
            onNameChange = viewModel::setEditName,
            onNumberChange = viewModel::setEditNumber,
            onLogoUrlChange = viewModel::setEditLogoUrl,
            onGroupChange = viewModel::setEditGroup,
            onSave = viewModel::saveChannel,
            onReset = viewModel::resetFields,
            onDismiss = viewModel::dismissEditor,
            isSaving = uiState.isSaving
        )
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
            androidx.tv.material3.Button(onClick = onBack) {
                androidx.tv.material3.Text("Back")
            }

            Spacer(modifier = Modifier.width(24.dp))

            Text(
                text = "Channel Editor",
                style = MaterialTheme.typography.displaySmall,
                color = OpenFlixColors.OnSurface
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Search bar
        SearchBar(
            query = uiState.searchQuery,
            onQueryChange = viewModel::searchChannels,
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Channel list
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(color = OpenFlixColors.Primary)
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxSize()
            ) {
                items(uiState.filteredChannels, key = { it.id }) { channel ->
                    ChannelLogoItem(
                        channel = channel,
                        onClick = { viewModel.selectChannel(channel) }
                    )
                }
            }
        }
    }

    // Error snackbar
    if (uiState.error != null) {
        Snackbar(
            modifier = Modifier.padding(16.dp),
            action = {
                TextButton(onClick = viewModel::clearError) {
                    Text("Dismiss", color = Color.White)
                }
            }
        ) {
            Text(uiState.error ?: "An error occurred")
        }
    }
}

@Composable
private fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val keyboardController = LocalSoftwareKeyboardController.current

    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = modifier,
        placeholder = { Text("Search channels...", color = Color.Gray) },
        leadingIcon = {
            Icon(Icons.Default.Search, contentDescription = null, tint = Color.Gray)
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(Icons.Default.Clear, contentDescription = "Clear", tint = Color.Gray)
                }
            }
        },
        singleLine = true,
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = OpenFlixColors.Primary,
            unfocusedBorderColor = Color.Gray.copy(alpha = 0.5f),
            focusedTextColor = Color.White,
            unfocusedTextColor = Color.White
        ),
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        keyboardActions = KeyboardActions(onSearch = { keyboardController?.hide() })
    )
}

@Composable
private fun ChannelLogoItem(
    channel: Channel,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    androidx.tv.material3.Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused }
            .then(
                if (isFocused) {
                    Modifier.border(
                        BorderStroke(2.dp, OpenFlixColors.Primary),
                        RoundedCornerShape(12.dp)
                    )
                } else {
                    Modifier
                }
            ),
        shape = androidx.tv.material3.ClickableSurfaceDefaults.shape(RoundedCornerShape(12.dp)),
        colors = androidx.tv.material3.ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        ),
        scale = androidx.tv.material3.ClickableSurfaceDefaults.scale(focusedScale = 1f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Channel logo
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(RoundedCornerShape(8.dp))
                    .background(Color.DarkGray),
                contentAlignment = Alignment.Center
            ) {
                if (!channel.logoUrl.isNullOrBlank()) {
                    AsyncImage(
                        model = channel.logoUrl,
                        contentDescription = channel.name,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Fit
                    )
                } else {
                    Text(
                        text = channel.name.take(2).uppercase(),
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Channel info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (!channel.number.isNullOrBlank()) {
                        Text(
                            text = channel.number!!,
                            color = OpenFlixColors.Primary,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                    Text(
                        text = channel.name,
                        color = Color.White,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))

                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (!channel.callsign.isNullOrBlank()) {
                        Text(
                            text = channel.callsign!!,
                            color = Color.Gray,
                            fontSize = 12.sp
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                    }
                    if (!channel.group.isNullOrBlank()) {
                        Text(
                            text = channel.group!!,
                            color = Color.Gray,
                            fontSize = 12.sp
                        )
                    }
                }
            }

            // Edit icon
            Icon(
                imageVector = Icons.Default.Edit,
                contentDescription = "Edit logo",
                tint = if (isFocused) OpenFlixColors.Primary else Color.Gray,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}

@Composable
private fun ChannelEditorDialog(
    channel: Channel,
    editName: String,
    editNumber: String,
    editLogoUrl: String,
    editGroup: String,
    onNameChange: (String) -> Unit,
    onNumberChange: (String) -> Unit,
    onLogoUrlChange: (String) -> Unit,
    onGroupChange: (String) -> Unit,
    onSave: () -> Unit,
    onReset: () -> Unit,
    onDismiss: () -> Unit,
    isSaving: Boolean
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            color = Color(0xFF1a1a2e)
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Edit Channel",
                    color = Color.White,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Logo preview
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.DarkGray),
                    contentAlignment = Alignment.Center
                ) {
                    if (editLogoUrl.isNotBlank()) {
                        AsyncImage(
                            model = editLogoUrl,
                            contentDescription = "Logo preview",
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Fit
                        )
                    } else {
                        Text(
                            text = editName.take(2).uppercase(),
                            color = Color.White,
                            fontSize = 24.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }

                Spacer(modifier = Modifier.height(20.dp))

                // Channel Number input
                OutlinedTextField(
                    value = editNumber,
                    onValueChange = { value ->
                        // Only allow digits
                        if (value.isEmpty() || value.all { it.isDigit() }) {
                            onNumberChange(value)
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Channel Number") },
                    placeholder = { Text("e.g., 5", color = Color.Gray) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = OpenFlixColors.Primary,
                        unfocusedBorderColor = Color.Gray.copy(alpha = 0.5f),
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedLabelColor = OpenFlixColors.Primary,
                        unfocusedLabelColor = Color.Gray
                    )
                )

                Spacer(modifier = Modifier.height(12.dp))

                // Channel Name input
                OutlinedTextField(
                    value = editName,
                    onValueChange = onNameChange,
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Channel Name") },
                    placeholder = { Text("e.g., ESPN", color = Color.Gray) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = OpenFlixColors.Primary,
                        unfocusedBorderColor = Color.Gray.copy(alpha = 0.5f),
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedLabelColor = OpenFlixColors.Primary,
                        unfocusedLabelColor = Color.Gray
                    )
                )

                Spacer(modifier = Modifier.height(12.dp))

                // Group input
                OutlinedTextField(
                    value = editGroup,
                    onValueChange = onGroupChange,
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Group") },
                    placeholder = { Text("e.g., Sports", color = Color.Gray) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = OpenFlixColors.Primary,
                        unfocusedBorderColor = Color.Gray.copy(alpha = 0.5f),
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedLabelColor = OpenFlixColors.Primary,
                        unfocusedLabelColor = Color.Gray
                    )
                )

                Spacer(modifier = Modifier.height(12.dp))

                // Logo URL input
                OutlinedTextField(
                    value = editLogoUrl,
                    onValueChange = onLogoUrlChange,
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("Logo URL") },
                    placeholder = { Text("https://...", color = Color.Gray) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = OpenFlixColors.Primary,
                        unfocusedBorderColor = Color.Gray.copy(alpha = 0.5f),
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedLabelColor = OpenFlixColors.Primary,
                        unfocusedLabelColor = Color.Gray
                    )
                )

                Spacer(modifier = Modifier.height(20.dp))

                // Action buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Reset button
                    OutlinedButton(
                        onClick = onReset,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = Color.Gray
                        ),
                        border = BorderStroke(1.dp, Color.Gray)
                    ) {
                        Icon(
                            Icons.Default.Refresh,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Reset")
                    }

                    // Save button
                    Button(
                        onClick = onSave,
                        modifier = Modifier.weight(1f),
                        enabled = !isSaving,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = OpenFlixColors.Primary
                        )
                    ) {
                        if (isSaving) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(18.dp),
                                color = Color.White,
                                strokeWidth = 2.dp
                            )
                        } else {
                            Icon(
                                Icons.Default.Check,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                        }
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Save")
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                // Cancel button
                TextButton(onClick = onDismiss) {
                    Text("Cancel", color = Color.Gray)
                }
            }
        }
    }
}
