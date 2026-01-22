package com.openflix.presentation.screens.profile

import androidx.compose.animation.core.*
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Star
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.foundation.lazy.grid.TvGridCells
import androidx.tv.foundation.lazy.grid.TvLazyVerticalGrid
import androidx.tv.foundation.lazy.grid.items
import androidx.tv.material3.*
import coil.compose.AsyncImage
import com.openflix.domain.model.Profile
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun ProfileSelectionScreen(
    onProfileSelected: () -> Unit,
    viewModel: ProfileSelectionViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    // Handle successful switch
    LaunchedEffect(uiState.switchedSuccessfully) {
        if (uiState.switchedSuccessfully) {
            viewModel.clearSwitchFlag()
            onProfileSelected()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF0A0A0A),
                        Color(0xFF1A1A2E)
                    )
                )
            )
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(80.dp))

            // Title
            Text(
                text = "Who's Watching?",
                style = MaterialTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(48.dp))

            // Content
            when {
                uiState.isLoading -> {
                    LoadingState()
                }
                uiState.error != null && uiState.profiles.isEmpty() -> {
                    ErrorState(
                        message = uiState.error!!,
                        onRetry = { viewModel.loadProfiles() }
                    )
                }
                uiState.profiles.isEmpty() -> {
                    EmptyState()
                }
                else -> {
                    ProfilesGrid(
                        profiles = uiState.profiles,
                        onProfileClick = { viewModel.selectProfile(it) },
                        isSwitching = uiState.isSwitching
                    )
                }
            }
        }

        // PIN Dialog
        if (uiState.showPinDialog && uiState.selectedProfile != null) {
            PinDialog(
                profile = uiState.selectedProfile!!,
                error = uiState.pinError,
                isLoading = uiState.isEnteringPin,
                onPinEntered = { viewModel.enterPin(it) },
                onDismiss = { viewModel.dismissPinDialog() }
            )
        }
    }
}

@Composable
private fun LoadingState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                repeat(3) { index ->
                    val infiniteTransition = rememberInfiniteTransition(label = "loading")
                    val alpha by infiniteTransition.animateFloat(
                        initialValue = 0.3f,
                        targetValue = 1f,
                        animationSpec = infiniteRepeatable(
                            animation = tween(600, delayMillis = index * 200),
                            repeatMode = RepeatMode.Reverse
                        ),
                        label = "dot_$index"
                    )
                    Box(
                        modifier = Modifier
                            .size(12.dp)
                            .background(
                                OpenFlixColors.Primary.copy(alpha = alpha),
                                RoundedCornerShape(6.dp)
                            )
                    )
                }
            }
            Text(
                text = "Loading profiles...",
                style = MaterialTheme.typography.bodyLarge,
                color = Color.White.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun ErrorState(
    message: String,
    onRetry: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = message,
                style = MaterialTheme.typography.bodyLarge,
                color = Color.Red.copy(alpha = 0.8f)
            )
            Surface(
                onClick = onRetry,
                shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                colors = ClickableSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.Primary,
                    focusedContainerColor = OpenFlixColors.Primary.copy(alpha = 0.8f)
                )
            ) {
                Text(
                    text = "Retry",
                    style = MaterialTheme.typography.labelLarge,
                    color = Color.White,
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp)
                )
            }
        }
    }
}

@Composable
private fun EmptyState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Person,
                contentDescription = null,
                tint = Color.White.copy(alpha = 0.3f),
                modifier = Modifier.size(80.dp)
            )
            Text(
                text = "No profiles found",
                style = MaterialTheme.typography.headlineSmall,
                color = Color.White.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun ProfilesGrid(
    profiles: List<Profile>,
    onProfileClick: (Profile) -> Unit,
    isSwitching: Boolean
) {
    TvLazyVerticalGrid(
        columns = TvGridCells.Adaptive(minSize = 160.dp),
        contentPadding = PaddingValues(horizontal = 80.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.spacedBy(24.dp),
        verticalArrangement = Arrangement.spacedBy(24.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        items(profiles, key = { it.uuid }) { profile ->
            ProfileCard(
                profile = profile,
                onClick = { if (!isSwitching) onProfileClick(profile) },
                isLoading = isSwitching
            )
        }
    }
}

@Composable
private fun ProfileCard(
    profile: Profile,
    onClick: () -> Unit,
    isLoading: Boolean
) {
    var isFocused by remember { mutableStateOf(false) }

    Surface(
        onClick = onClick,
        modifier = Modifier
            .width(160.dp)
            .onFocusChanged { isFocused = it.isFocused },
        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(16.dp)),
        colors = ClickableSurfaceDefaults.colors(
            containerColor = Color.Transparent,
            focusedContainerColor = Color.Transparent
        ),
        border = ClickableSurfaceDefaults.border(
            focusedBorder = Border(
                border = BorderStroke(3.dp, OpenFlixColors.Primary),
                shape = RoundedCornerShape(16.dp)
            )
        ),
        scale = ClickableSurfaceDefaults.scale(focusedScale = 1.1f)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Avatar
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .clip(CircleShape)
                    .then(
                        if (profile.thumb != null) Modifier.background(Color.Transparent)
                        else Modifier.background(
                            Brush.linearGradient(
                                colors = listOf(
                                    getProfileColor(profile.uuid),
                                    getProfileColor(profile.uuid).copy(alpha = 0.7f)
                                )
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (profile.thumb != null) {
                    AsyncImage(
                        model = profile.thumb,
                        contentDescription = profile.name,
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Text(
                        text = profile.name.take(1).uppercase(),
                        style = MaterialTheme.typography.displayMedium,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }

                // Lock indicator
                if (profile.hasPassword) {
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomEnd)
                            .size(32.dp)
                            .background(Color.Black.copy(alpha = 0.7f), CircleShape)
                            .padding(6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Lock,
                            contentDescription = "PIN Protected",
                            tint = Color.White,
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                }
            }

            // Name
            Text(
                text = profile.name,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = if (isFocused) FontWeight.Bold else FontWeight.Medium,
                color = if (isFocused) Color.White else Color.White.copy(alpha = 0.8f),
                textAlign = TextAlign.Center,
                maxLines = 1
            )

            // Badges
            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                if (profile.isAdmin) {
                    Icon(
                        imageVector = Icons.Filled.Star,
                        contentDescription = "Admin",
                        tint = Color(0xFFFFD700),
                        modifier = Modifier.size(16.dp)
                    )
                }
                if (profile.isRestricted) {
                    Icon(
                        imageVector = Icons.Filled.Shield,
                        contentDescription = "Restricted",
                        tint = OpenFlixColors.Primary,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun PinDialog(
    profile: Profile,
    error: String?,
    isLoading: Boolean,
    onPinEntered: (String) -> Unit,
    onDismiss: () -> Unit
) {
    var pin by remember { mutableStateOf("") }

    Dialog(onDismissRequest = onDismiss) {
        Surface(
            onClick = {},
            modifier = Modifier.width(320.dp),
            shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(16.dp)),
            colors = ClickableSurfaceDefaults.colors(
                containerColor = Color(0xFF1A1A2E),
                focusedContainerColor = Color(0xFF1A1A2E)
            )
        ) {
            Column(
                modifier = Modifier.padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Profile avatar
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(
                            if (profile.thumb != null) Color.Transparent
                            else getProfileColor(profile.uuid)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    if (profile.thumb != null) {
                        AsyncImage(
                            model = profile.thumb,
                            contentDescription = profile.name,
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                    } else {
                        Text(
                            text = profile.name.take(1).uppercase(),
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }

                Text(
                    text = "Enter PIN for ${profile.name}",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White
                )

                // PIN input
                androidx.compose.material3.OutlinedTextField(
                    value = pin,
                    onValueChange = { if (it.length <= 4) pin = it },
                    modifier = Modifier.fillMaxWidth(),
                    label = { Text("PIN") },
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                    singleLine = true,
                    isError = error != null,
                    supportingText = error?.let { { Text(it, color = Color.Red) } }
                )

                // Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Surface(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = Color.White.copy(alpha = 0.1f),
                            focusedContainerColor = Color.White.copy(alpha = 0.2f)
                        )
                    ) {
                        Text(
                            text = "Cancel",
                            style = MaterialTheme.typography.labelLarge,
                            color = Color.White,
                            modifier = Modifier.padding(vertical = 12.dp),
                            textAlign = TextAlign.Center
                        )
                    }

                    Surface(
                        onClick = { if (pin.isNotEmpty()) onPinEntered(pin) },
                        modifier = Modifier.weight(1f),
                        shape = ClickableSurfaceDefaults.shape(RoundedCornerShape(8.dp)),
                        colors = ClickableSurfaceDefaults.colors(
                            containerColor = OpenFlixColors.Primary,
                            focusedContainerColor = OpenFlixColors.Primary.copy(alpha = 0.8f)
                        )
                    ) {
                        if (isLoading) {
                            Row(
                                modifier = Modifier.padding(vertical = 12.dp),
                                horizontalArrangement = Arrangement.Center
                            ) {
                                repeat(3) { index ->
                                    val infiniteTransition = rememberInfiniteTransition(label = "pin_loading")
                                    val alpha by infiniteTransition.animateFloat(
                                        initialValue = 0.3f,
                                        targetValue = 1f,
                                        animationSpec = infiniteRepeatable(
                                            animation = tween(400, delayMillis = index * 100),
                                            repeatMode = RepeatMode.Reverse
                                        ),
                                        label = "pin_dot_$index"
                                    )
                                    Box(
                                        modifier = Modifier
                                            .padding(horizontal = 2.dp)
                                            .size(8.dp)
                                            .background(
                                                Color.White.copy(alpha = alpha),
                                                CircleShape
                                            )
                                    )
                                }
                            }
                        } else {
                            Text(
                                text = "Enter",
                                style = MaterialTheme.typography.labelLarge,
                                color = Color.White,
                                modifier = Modifier.padding(vertical = 12.dp),
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }
            }
        }
    }
}

/**
 * Generate a consistent color for a profile based on UUID
 */
private fun getProfileColor(uuid: String): Color {
    val colors = listOf(
        Color(0xFF6366F1), // Indigo
        Color(0xFF8B5CF6), // Purple
        Color(0xFFEC4899), // Pink
        Color(0xFFEF4444), // Red
        Color(0xFFF97316), // Orange
        Color(0xFFEAB308), // Yellow
        Color(0xFF22C55E), // Green
        Color(0xFF14B8A6), // Teal
        Color(0xFF06B6D4), // Cyan
        Color(0xFF3B82F6)  // Blue
    )
    val index = uuid.hashCode().let { if (it < 0) -it else it } % colors.size
    return colors[index]
}
