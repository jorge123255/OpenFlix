package com.openflix.presentation.screens.settings

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import com.openflix.presentation.components.AccentColorPickerDialog
import com.openflix.presentation.components.AccentColors
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onNavigateToSubtitleStyling: () -> Unit,
    onNavigateToChannelLogoEditor: () -> Unit,
    onNavigateToRemoteMapping: () -> Unit,
    onNavigateToRemoteStreaming: () -> Unit,
    onNavigateToAbout: () -> Unit,
    onNavigateToLogs: () -> Unit,
    onNavigateToSources: () -> Unit,
    onSignOut: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showColorPicker by remember { mutableStateOf(false) }

    // Accent Color Picker Dialog
    if (showColorPicker) {
        AccentColorPickerDialog(
            currentColor = uiState.accentColor,
            onColorSelected = { viewModel.setAccentColor(it) },
            onDismiss = { showColorPicker = false }
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
            Button(onClick = onBack) {
                Text("Back")
            }

            Spacer(modifier = Modifier.width(24.dp))

            Text(
                text = "Settings",
                style = MaterialTheme.typography.displaySmall,
                color = OpenFlixColors.OnSurface
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Appearance Section
            item {
                SettingsSectionHeader("Appearance")
            }

            item {
                SettingsItem(
                    title = "Theme",
                    subtitle = uiState.theme.replaceFirstChar { it.uppercase() },
                    onClick = { /* Show theme picker */ }
                )
            }

            item {
                AccentColorSettingsItem(
                    currentColor = uiState.accentColor,
                    onClick = { showColorPicker = true }
                )
            }

            item {
                SettingsItem(
                    title = "Language",
                    subtitle = getLanguageName(uiState.language),
                    onClick = { /* Show language picker */ }
                )
            }

            item {
                SettingsItem(
                    title = "Library Density",
                    subtitle = uiState.libraryDensity.replaceFirstChar { it.uppercase() },
                    onClick = { /* Show density picker */ }
                )
            }

            // Live TV Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SettingsSectionHeader("Live TV")
            }

            item {
                SettingsItem(
                    title = "Manage Sources",
                    subtitle = "Add and configure Xtream and M3U sources",
                    onClick = onNavigateToSources
                )
            }

            item {
                SettingsItem(
                    title = "Channel Logo Editor",
                    subtitle = "Customize channel logos",
                    onClick = onNavigateToChannelLogoEditor
                )
            }

            item {
                SettingsItem(
                    title = "Remote Button Mapping",
                    subtitle = "Customize remote control actions",
                    onClick = onNavigateToRemoteMapping
                )
            }

            item {
                SettingsToggle(
                    title = "Instant Channel Switch",
                    subtitle = if (uiState.instantSwitchEnabled)
                        "Pre-buffers nearby channels (${uiState.cachedStreamCount} cached)"
                    else
                        "Pre-buffer channels for instant switching",
                    checked = uiState.instantSwitchEnabled,
                    onCheckedChange = viewModel::setInstantSwitchEnabled
                )
            }

            // Remote Streaming Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SettingsSectionHeader("Remote Access")
            }

            item {
                SettingsItem(
                    title = "Remote Streaming",
                    subtitle = "Stream from anywhere via Tailscale",
                    onClick = onNavigateToRemoteStreaming
                )
            }

            // Video Playback Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SettingsSectionHeader("Video Playback")
            }

            item {
                SettingsToggle(
                    title = "Hardware Decoding",
                    subtitle = "Use hardware acceleration for video",
                    checked = uiState.hardwareDecoding,
                    onCheckedChange = viewModel::setHardwareDecoding
                )
            }

            item {
                SettingsItem(
                    title = "Buffer Size",
                    subtitle = "${uiState.bufferSize} MB",
                    onClick = { /* Show buffer size picker */ }
                )
            }

            item {
                SettingsItem(
                    title = "Small Skip Duration",
                    subtitle = "${uiState.smallSkipDuration} seconds",
                    onClick = { /* Show picker */ }
                )
            }

            item {
                SettingsItem(
                    title = "Large Skip Duration",
                    subtitle = "${uiState.largeSkipDuration} seconds",
                    onClick = { /* Show picker */ }
                )
            }

            item {
                SettingsToggle(
                    title = "Auto Skip Intro",
                    subtitle = "Automatically skip intro sequences",
                    checked = uiState.autoSkipIntro,
                    onCheckedChange = viewModel::setAutoSkipIntro
                )
            }

            item {
                SettingsToggle(
                    title = "Auto Skip Credits",
                    subtitle = "Automatically skip to next episode",
                    checked = uiState.autoSkipCredits,
                    onCheckedChange = viewModel::setAutoSkipCredits
                )
            }

            // Video Quality Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SettingsSectionHeader("Video Quality")
            }

            item {
                SettingsItem(
                    title = "Upscaling Quality",
                    subtitle = when (uiState.videoQuality) {
                        "high" -> "High (ewa_lanczossharp) - Best quality"
                        "fast" -> "Fast (bilinear) - Smooth playback"
                        else -> "Auto - Based on device"
                    },
                    onClick = {
                        // Cycle through options: auto -> high -> fast -> auto
                        val nextQuality = when (uiState.videoQuality) {
                            "auto" -> "high"
                            "high" -> "fast"
                            else -> "auto"
                        }
                        viewModel.setVideoQuality(nextQuality)
                    }
                )
            }

            item {
                SettingsItem(
                    title = "Sharpening",
                    subtitle = "${(uiState.sharpening * 100).toInt()}%",
                    onClick = {
                        // Cycle through: 0%, 10%, 20%, 30%, 50%
                        val nextValue = when {
                            uiState.sharpening < 0.1f -> 0.1f
                            uiState.sharpening < 0.2f -> 0.2f
                            uiState.sharpening < 0.3f -> 0.3f
                            uiState.sharpening < 0.5f -> 0.5f
                            else -> 0f
                        }
                        viewModel.setSharpening(nextValue)
                    }
                )
            }

            item {
                SettingsToggle(
                    title = "Deband Filter",
                    subtitle = "Remove color banding artifacts",
                    checked = uiState.debandEnabled,
                    onCheckedChange = viewModel::setDebandEnabled
                )
            }

            item {
                SettingsToggle(
                    title = "5.1 Audio Upmix",
                    subtitle = "Upscale stereo to 5.1 surround",
                    checked = uiState.audioUpmix,
                    onCheckedChange = viewModel::setAudioUpmix
                )
            }

            // Subtitles Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SettingsSectionHeader("Subtitles")
            }

            item {
                SettingsItem(
                    title = "Subtitle Styling",
                    subtitle = "Customize subtitle appearance",
                    onClick = onNavigateToSubtitleStyling
                )
            }

            // Parental Controls Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SettingsSectionHeader("Parental Controls")
            }

            item {
                SettingsToggle(
                    title = "Enable Parental Controls",
                    subtitle = "Restrict content based on ratings",
                    checked = uiState.parentalControlsEnabled,
                    onCheckedChange = viewModel::setParentalControlsEnabled
                )
            }

            // Advanced Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SettingsSectionHeader("Advanced")
            }

            item {
                SettingsToggle(
                    title = "Debug Logging",
                    subtitle = "Enable detailed logging for troubleshooting",
                    checked = uiState.debugLogging,
                    onCheckedChange = viewModel::setDebugLogging
                )
            }

            item {
                SettingsItem(
                    title = "Send Logs to Server",
                    subtitle = "Upload logs for troubleshooting",
                    onClick = { /* Send logs */ }
                )
            }

            item {
                SettingsItem(
                    title = "View Logs",
                    subtitle = "View debug logs",
                    onClick = onNavigateToLogs
                )
            }

            // About Section
            item {
                Spacer(modifier = Modifier.height(16.dp))
                SettingsSectionHeader("About")
            }

            item {
                SettingsItem(
                    title = "About OpenFlix",
                    subtitle = "Version 1.0.0",
                    onClick = onNavigateToAbout
                )
            }

            // Sign Out
            item {
                Spacer(modifier = Modifier.height(24.dp))
                Button(
                    onClick = onSignOut,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.colors(
                        containerColor = OpenFlixColors.Error
                    )
                ) {
                    Text("Sign Out")
                }
            }

            item {
                Spacer(modifier = Modifier.height(48.dp))
            }
        }
    }
}

@Composable
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleLarge,
        color = OpenFlixColors.Primary,
        modifier = Modifier.padding(vertical = 8.dp)
    )
}

@Composable
private fun SettingsItem(
    title: String,
    subtitle: String,
    onClick: () -> Unit
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
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge,
                    color = OpenFlixColors.OnSurface
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.TextSecondary
                )
            }

            Text(
                text = "›",
                style = MaterialTheme.typography.headlineMedium,
                color = OpenFlixColors.TextTertiary
            )
        }
    }
}

@Composable
private fun SettingsToggle(
    title: String,
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
                    text = title,
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

private fun getLanguageName(code: String): String {
    return when (code) {
        "en" -> "English"
        "de" -> "Deutsch"
        "it" -> "Italiano"
        "nl" -> "Nederlands"
        "sv" -> "Svenska"
        "zh" -> "中文"
        else -> code
    }
}

@Composable
private fun AccentColorSettingsItem(
    currentColor: Long,
    onClick: () -> Unit
) {
    var isFocused by remember { mutableStateOf(false) }
    val colorName = AccentColors.colors.find { it.first == currentColor }?.second ?: "Custom"

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
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Accent Color",
                    style = MaterialTheme.typography.bodyLarge,
                    color = OpenFlixColors.OnSurface
                )
                Text(
                    text = colorName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = OpenFlixColors.TextSecondary
                )
            }

            // Color preview circle
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(Color(currentColor))
                    .border(2.dp, Color.White.copy(alpha = 0.3f), CircleShape)
            )
        }
    }
}
