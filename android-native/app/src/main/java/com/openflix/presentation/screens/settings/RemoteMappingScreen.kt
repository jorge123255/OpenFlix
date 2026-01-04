package com.openflix.presentation.screens.settings

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun RemoteMappingScreen(
    onBack: () -> Unit,
    viewModel: RemoteMappingViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Action picker dialog
    if (uiState.showActionPicker && uiState.selectedButton != null) {
        ActionPickerDialog(
            button = uiState.selectedButton!!,
            currentAction = getButtonAction(uiState, uiState.selectedButton!!),
            onActionSelected = viewModel::selectAction,
            onDismiss = viewModel::dismissActionPicker
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
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                androidx.tv.material3.Button(onClick = onBack) {
                    androidx.tv.material3.Text("Back")
                }

                Spacer(modifier = Modifier.width(24.dp))

                Text(
                    text = "Remote Button Mapping",
                    style = MaterialTheme.typography.displaySmall,
                    color = OpenFlixColors.OnSurface
                )
            }

            // Reset to defaults button
            androidx.tv.material3.Button(
                onClick = viewModel::resetToDefaults,
                colors = androidx.tv.material3.ButtonDefaults.colors(
                    containerColor = OpenFlixColors.Surface
                )
            ) {
                Icon(
                    Icons.Default.Refresh,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                    tint = Color.White
                )
                Spacer(modifier = Modifier.width(8.dp))
                androidx.tv.material3.Text("Reset")
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Customize what each button does on your remote control",
            color = Color.Gray,
            fontSize = 14.sp
        )

        Spacer(modifier = Modifier.height(24.dp))

        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(8.dp),
            modifier = Modifier.fillMaxSize()
        ) {
            // Color buttons section
            item {
                SectionHeader("Color Buttons")
            }

            items(listOf(RemoteButton.RED, RemoteButton.GREEN, RemoteButton.YELLOW, RemoteButton.BLUE)) { button ->
                ButtonMappingItem(
                    button = button,
                    currentAction = getButtonAction(uiState, button),
                    onClick = { viewModel.showActionPicker(button) }
                )
            }

            // Other buttons section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SectionHeader("Other Buttons")
            }

            items(listOf(RemoteButton.MENU, RemoteButton.INFO, RemoteButton.RECORD)) { button ->
                ButtonMappingItem(
                    button = button,
                    currentAction = getButtonAction(uiState, button),
                    onClick = { viewModel.showActionPicker(button) }
                )
            }

            item {
                Spacer(modifier = Modifier.height(24.dp))
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
private fun ButtonMappingItem(
    button: RemoteButton,
    currentAction: String,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val actionInfo = RemoteAction.entries.find { it.key == currentAction }

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
            // Button color indicator
            if (button.color != null) {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(Color(button.color))
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(Color.DarkGray),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = button.displayName.first().toString(),
                        color = Color.White,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Button info
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = button.displayName,
                    color = Color.White,
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = actionInfo?.displayName ?: "Not set",
                    color = Color.Gray,
                    fontSize = 14.sp
                )
            }

            // Arrow
            Text(
                text = ">",
                color = if (isFocused) OpenFlixColors.Primary else Color.Gray,
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
private fun ActionPickerDialog(
    button: RemoteButton,
    currentAction: String,
    onActionSelected: (String) -> Unit,
    onDismiss: () -> Unit
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
                modifier = Modifier.padding(24.dp)
            ) {
                // Header
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (button.color != null) {
                        Box(
                            modifier = Modifier
                                .size(24.dp)
                                .clip(CircleShape)
                                .background(Color(button.color))
                        )
                        Spacer(modifier = Modifier.width(12.dp))
                    }
                    Text(
                        text = "Configure ${button.displayName}",
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = "Select an action for this button",
                    color = Color.Gray,
                    fontSize = 14.sp
                )

                Spacer(modifier = Modifier.height(24.dp))

                // Action list
                LazyColumn(
                    modifier = Modifier.heightIn(max = 400.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(RemoteAction.entries.toList()) { action ->
                        ActionItem(
                            action = action,
                            isSelected = action.key == currentAction,
                            onClick = { onActionSelected(action.key) }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Cancel button
                TextButton(
                    onClick = onDismiss,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                ) {
                    Text("Cancel", color = Color.Gray)
                }
            }
        }
    }
}

@Composable
private fun ActionItem(
    action: RemoteAction,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .onFocusChanged { isFocused = it.isFocused },
        shape = RoundedCornerShape(8.dp),
        color = when {
            isSelected -> OpenFlixColors.Primary.copy(alpha = 0.2f)
            isFocused -> OpenFlixColors.FocusBackground
            else -> Color.Transparent
        },
        border = if (isSelected) BorderStroke(1.dp, OpenFlixColors.Primary) else null
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = action.displayName,
                    color = if (isSelected) OpenFlixColors.Primary else Color.White,
                    fontSize = 16.sp,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                )
                Text(
                    text = action.description,
                    color = Color.Gray,
                    fontSize = 12.sp
                )
            }

            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Selected",
                    tint = OpenFlixColors.Primary,
                    modifier = Modifier.size(24.dp)
                )
            }
        }
    }
}

private fun getButtonAction(state: RemoteMappingUiState, button: RemoteButton): String {
    return when (button) {
        RemoteButton.RED -> state.buttonRed
        RemoteButton.GREEN -> state.buttonGreen
        RemoteButton.YELLOW -> state.buttonYellow
        RemoteButton.BLUE -> state.buttonBlue
        RemoteButton.MENU -> state.buttonMenu
        RemoteButton.INFO -> state.buttonInfo
        RemoteButton.RECORD -> state.buttonRecord
    }
}
