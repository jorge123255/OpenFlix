package com.openflix.presentation.screens.settings

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import com.openflix.domain.model.NetworkType
import com.openflix.domain.model.RemoteStreamingQuality
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun RemoteStreamingSettingsScreen(
    onBack: () -> Unit,
    viewModel: RemoteStreamingSettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var showQualityPicker by remember { mutableStateOf(false) }

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
                text = "Remote Streaming",
                style = MaterialTheme.typography.displaySmall,
                color = OpenFlixColors.OnSurface
            )

            Spacer(modifier = Modifier.weight(1f))

            // Refresh button
            Surface(
                onClick = { viewModel.refreshStatus() },
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.Surface,
                    focusedContainerColor = OpenFlixColors.FocusBackground
                )
            ) {
                Icon(
                    imageVector = Icons.Default.Refresh,
                    contentDescription = "Refresh",
                    tint = if (uiState.isRefreshing) OpenFlixColors.TextTertiary else OpenFlixColors.OnSurface,
                    modifier = Modifier.padding(8.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Loading...",
                    style = MaterialTheme.typography.bodyLarge,
                    color = OpenFlixColors.TextSecondary
                )
            }
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Connection Status Section
                item {
                    SectionHeader("Connection Status")
                }

                item {
                    ConnectionStatusCard(
                        networkType = uiState.networkType,
                        isRemote = uiState.isRemote,
                        serverUrl = uiState.connectionInfo?.serverUrl
                    )
                }

                // Quality Settings Section
                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    SectionHeader("Quality Settings")
                }

                item {
                    QualitySettingsItem(
                        currentQuality = uiState.preferredQuality,
                        onClick = { showQualityPicker = true }
                    )
                }

                item {
                    Text(
                        text = "When streaming remotely, video will be transcoded to the selected quality to optimize bandwidth usage.",
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextTertiary,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }

                // Tailscale Admin Section (only shown if user can manage)
                if (uiState.canManageTailscale) {
                    item {
                        Spacer(modifier = Modifier.height(16.dp))
                        SectionHeader("Tailscale VPN")
                    }

                    item {
                        TailscaleStatusCard(
                            isEnabled = uiState.isTailscaleEnabled,
                            isConnected = uiState.isConnected,
                            backendState = uiState.backendState,
                            tailscaleIp = uiState.tailscaleIp,
                            hostname = uiState.tailscaleHostname
                        )
                    }

                    item {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            if (uiState.isTailscaleEnabled) {
                                Button(
                                    onClick = { viewModel.disableRemoteAccess() },
                                    colors = ButtonDefaults.colors(
                                        containerColor = OpenFlixColors.Error
                                    ),
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text(if (uiState.isDisabling) "Disabling..." else "Disable Tailscale")
                                }
                            } else {
                                Button(
                                    onClick = { viewModel.enableRemoteAccess() },
                                    colors = ButtonDefaults.colors(
                                        containerColor = OpenFlixColors.Primary
                                    ),
                                    modifier = Modifier.weight(1f)
                                ) {
                                    Text(if (uiState.isEnabling) "Enabling..." else "Enable Tailscale")
                                }
                            }

                            Button(
                                onClick = { viewModel.checkHealth() },
                                colors = ButtonDefaults.colors(
                                    containerColor = OpenFlixColors.Surface
                                ),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text("Check Health")
                            }
                        }
                    }

                    // Health status if available
                    uiState.tailscaleHealth?.let { health ->
                        item {
                            HealthStatusCard(health = health)
                        }
                    }
                }

                // Quality Presets Info
                item {
                    Spacer(modifier = Modifier.height(16.dp))
                    SectionHeader("Quality Presets")
                }

                items(RemoteStreamingQuality.entries.filter { it != RemoteStreamingQuality.AUTO }) { quality ->
                    QualityPresetInfo(quality = quality)
                }

                item {
                    Spacer(modifier = Modifier.height(48.dp))
                }
            }
        }
    }

    // Quality Picker Dialog
    if (showQualityPicker) {
        QualityPickerDialog(
            currentQuality = uiState.preferredQuality,
            onQualitySelected = {
                viewModel.setPreferredQuality(it)
                showQualityPicker = false
            },
            onDismiss = { showQualityPicker = false }
        )
    }

    // Error Dialog
    uiState.error?.let { error ->
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { androidx.compose.material3.Text("Error") },
            text = { androidx.compose.material3.Text(error) },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    androidx.compose.material3.Text("OK")
                }
            }
        )
    }

    // Login URL Dialog
    uiState.loginUrl?.let { url ->
        AlertDialog(
            onDismissRequest = { viewModel.clearLoginUrl() },
            title = { androidx.compose.material3.Text("Tailscale Login Required") },
            text = {
                Column {
                    androidx.compose.material3.Text("Please visit the following URL to authenticate Tailscale:")
                    Spacer(modifier = Modifier.height(8.dp))
                    androidx.compose.material3.Text(
                        text = url,
                        color = OpenFlixColors.Primary
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = { viewModel.clearLoginUrl() }) {
                    androidx.compose.material3.Text("Done")
                }
            }
        )
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
private fun ConnectionStatusCard(
    networkType: NetworkType,
    isRemote: Boolean,
    serverUrl: String?
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(OpenFlixColors.Surface, MaterialTheme.shapes.medium)
            .padding(16.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = when (networkType) {
                        NetworkType.WIFI -> Icons.Default.Wifi
                        NetworkType.ETHERNET -> Icons.Default.SettingsEthernet
                        NetworkType.CELLULAR -> Icons.Default.SignalCellular4Bar
                        NetworkType.VPN -> Icons.Default.VpnKey
                        else -> Icons.Default.SignalWifiOff
                    },
                    contentDescription = null,
                    tint = if (isRemote) OpenFlixColors.Warning else OpenFlixColors.Success,
                    modifier = Modifier.size(32.dp)
                )

                Spacer(modifier = Modifier.width(16.dp))

                Column {
                    Text(
                        text = if (isRemote) "Remote Connection" else "Local Connection",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = OpenFlixColors.OnSurface
                    )
                    Text(
                        text = networkType.displayName,
                        style = MaterialTheme.typography.bodyMedium,
                        color = OpenFlixColors.TextSecondary
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                // Connection indicator
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .border(
                            2.dp,
                            if (isRemote) OpenFlixColors.Warning else OpenFlixColors.Success,
                            RoundedCornerShape(50)
                        )
                )
            }

            serverUrl?.let {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Connected to: $it",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextTertiary
                )
            }
        }
    }
}

@Composable
private fun QualitySettingsItem(
    currentQuality: RemoteStreamingQuality,
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
                } else Modifier
            ),
        shape = ClickableSurfaceDefaults.shape(MaterialTheme.shapes.medium),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = OpenFlixColors.Surface,
            focusedContainerColor = OpenFlixColors.FocusBackground
        )
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
                    text = "Remote Streaming Quality",
                    style = MaterialTheme.typography.bodyLarge,
                    color = OpenFlixColors.OnSurface
                )
                Text(
                    text = currentQuality.displayName,
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
private fun TailscaleStatusCard(
    isEnabled: Boolean,
    isConnected: Boolean,
    backendState: String,
    tailscaleIp: String?,
    hostname: String?
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(OpenFlixColors.Surface, MaterialTheme.shapes.medium)
            .padding(16.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.VpnKey,
                    contentDescription = null,
                    tint = when {
                        isConnected -> OpenFlixColors.Success
                        isEnabled -> OpenFlixColors.Warning
                        else -> OpenFlixColors.TextTertiary
                    },
                    modifier = Modifier.size(32.dp)
                )

                Spacer(modifier = Modifier.width(16.dp))

                Column {
                    Text(
                        text = "Tailscale",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = OpenFlixColors.OnSurface
                    )
                    Text(
                        text = backendState,
                        style = MaterialTheme.typography.bodyMedium,
                        color = when (backendState) {
                            "Running" -> OpenFlixColors.Success
                            "NeedsLogin" -> OpenFlixColors.Warning
                            "Stopped" -> OpenFlixColors.TextTertiary
                            else -> OpenFlixColors.TextSecondary
                        }
                    )
                }
            }

            if (isConnected && (tailscaleIp != null || hostname != null)) {
                Spacer(modifier = Modifier.height(8.dp))
                tailscaleIp?.let {
                    Text(
                        text = "IP: $it",
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary
                    )
                }
                hostname?.let {
                    Text(
                        text = "Hostname: $it",
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.TextSecondary
                    )
                }
            }
        }
    }
}

@Composable
private fun HealthStatusCard(health: com.openflix.domain.model.TailscaleHealth) {
    val bgColor = if (health.healthy) OpenFlixColors.Surface else OpenFlixColors.Error.copy(alpha = 0.2f)
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(bgColor, MaterialTheme.shapes.medium)
            .padding(16.dp)
    ) {
        Column {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = if (health.healthy) Icons.Default.CheckCircle else Icons.Default.Warning,
                    contentDescription = null,
                    tint = if (health.healthy) OpenFlixColors.Success else OpenFlixColors.Error
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (health.healthy) "All systems healthy" else "Issues detected",
                    style = MaterialTheme.typography.titleMedium,
                    color = OpenFlixColors.OnSurface
                )
            }

            if (health.warnings.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                health.warnings.forEach { warning ->
                    Text(
                        text = "• $warning",
                        style = MaterialTheme.typography.bodySmall,
                        color = OpenFlixColors.Warning
                    )
                }
            }
        }
    }
}

@Composable
private fun QualityPresetInfo(quality: RemoteStreamingQuality) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = quality.displayName,
            style = MaterialTheme.typography.bodyMedium,
            color = OpenFlixColors.OnSurface
        )
        Text(
            text = if (quality.maxBitrate == Int.MAX_VALUE) "Full quality" else "≤${quality.maxBitrate / 1000} Mbps",
            style = MaterialTheme.typography.bodyMedium,
            color = OpenFlixColors.TextSecondary
        )
    }
}

@Composable
private fun QualityPickerDialog(
    currentQuality: RemoteStreamingQuality,
    onQualitySelected: (RemoteStreamingQuality) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { androidx.compose.material3.Text("Select Quality") },
        text = {
            Column {
                RemoteStreamingQuality.entries.forEach { quality ->
                    var isFocused by remember { mutableStateOf(false) }
                    val isSelected = quality == currentQuality

                    Surface(
                        onClick = { onQualitySelected(quality) },
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp)
                            .onFocusChanged { isFocused = it.isFocused },
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = if (isSelected) OpenFlixColors.Primary.copy(alpha = 0.2f) else Color.Transparent,
                            focusedContainerColor = OpenFlixColors.FocusBackground
                        ),
                        border = ClickableSurfaceDefaults.border(
                            focusedBorder = Border(
                                border = BorderStroke(2.dp, OpenFlixColors.Primary),
                                shape = RoundedCornerShape(8.dp)
                            )
                        )
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = quality.displayName,
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = OpenFlixColors.OnSurface
                                )
                            }
                            if (isSelected) {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = "Selected",
                                    tint = OpenFlixColors.Primary
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                androidx.compose.material3.Text("Cancel")
            }
        }
    )
}
