package com.openflix.presentation.screens.auth

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.tv.material3.*
import com.openflix.data.discovery.DiscoveredServer
import com.openflix.presentation.components.FocusableTextField
import com.openflix.presentation.theme.OpenFlixColors

@Composable
fun AuthScreen(
    onAuthSuccess: () -> Unit,
    viewModel: AuthViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val isAuthenticated by viewModel.isAuthenticated.collectAsState()
    val discoveredServers by viewModel.discoveredServers.collectAsState()
    val isDiscovering by viewModel.isDiscovering.collectAsState()

    val serverUrlFocusRequester = remember { FocusRequester() }
    val usernameFocusRequester = remember { FocusRequester() }
    val passwordFocusRequester = remember { FocusRequester() }

    // Responsive padding based on screen size
    val configuration = LocalConfiguration.current
    val screenHeight = configuration.screenHeightDp
    val isSmallScreen = screenHeight < 600
    val outerPadding = if (isSmallScreen) 16.dp else 32.dp

    // Navigate on successful auth
    LaunchedEffect(isAuthenticated) {
        if (isAuthenticated) {
            onAuthSuccess()
        }
    }

    // Request initial focus
    LaunchedEffect(uiState.isServerConnected) {
        if (uiState.isServerConnected) {
            usernameFocusRequester.requestFocus()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        OpenFlixColors.Background,
                        OpenFlixColors.PrimaryDark.copy(alpha = 0.3f),
                        OpenFlixColors.Background
                    )
                )
            )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(outerPadding),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Logo/Title
            Text(
                text = "OpenFlix",
                style = MaterialTheme.typography.displayLarge,
                color = OpenFlixColors.Primary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Your Personal Streaming Experience",
                style = MaterialTheme.typography.bodyLarge,
                color = OpenFlixColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(48.dp))

            // Auth Card
            Surface(
                modifier = Modifier.widthIn(max = 600.dp),
                shape = MaterialTheme.shapes.large,
                colors = NonInteractiveSurfaceDefaults.colors(
                    containerColor = OpenFlixColors.Surface.copy(alpha = 0.95f)
                )
            ) {
                Column(
                    modifier = Modifier.padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    if (!uiState.isServerConnected) {
                        // Server Connection
                        Text(
                            text = "Connect to Server",
                            style = MaterialTheme.typography.headlineMedium,
                            color = OpenFlixColors.OnSurface
                        )

                        Spacer(modifier = Modifier.height(24.dp))

                        // Show discovered servers
                        if (discoveredServers.isNotEmpty()) {
                            Text(
                                text = "Servers Found on Network",
                                style = MaterialTheme.typography.titleMedium,
                                color = OpenFlixColors.TextSecondary,
                                modifier = Modifier.fillMaxWidth()
                            )

                            Spacer(modifier = Modifier.height(12.dp))

                            LazyColumn(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .heightIn(max = 200.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                items(discoveredServers) { server ->
                                    DiscoveredServerItem(
                                        server = server,
                                        onClick = { viewModel.selectServer(server) }
                                    )
                                }
                            }

                            Spacer(modifier = Modifier.height(16.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(1.dp)
                                        .background(OpenFlixColors.SurfaceVariant)
                                )
                                Text(
                                    text = "  or enter manually  ",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = OpenFlixColors.TextTertiary
                                )
                                Box(
                                    modifier = Modifier
                                        .weight(1f)
                                        .height(1.dp)
                                        .background(OpenFlixColors.SurfaceVariant)
                                )
                            }

                            Spacer(modifier = Modifier.height(16.dp))
                        } else if (isDiscovering) {
                            Text(
                                text = "Searching for servers...",
                                style = MaterialTheme.typography.bodyMedium,
                                color = OpenFlixColors.TextSecondary
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                        } else {
                            Text(
                                text = "No servers found automatically",
                                style = MaterialTheme.typography.bodyMedium,
                                color = OpenFlixColors.TextTertiary
                            )

                            Spacer(modifier = Modifier.height(8.dp))

                            Button(
                                onClick = viewModel::discoverServers,
                                colors = ButtonDefaults.colors(
                                    containerColor = OpenFlixColors.SurfaceVariant
                                )
                            ) {
                                Text("Scan Again")
                            }

                            Spacer(modifier = Modifier.height(16.dp))
                        }

                        FocusableTextField(
                            value = uiState.serverUrl,
                            onValueChange = viewModel::updateServerUrl,
                            label = "Server URL",
                            placeholder = "e.g., 192.168.1.100:32400",
                            modifier = Modifier
                                .fillMaxWidth()
                                .focusRequester(serverUrlFocusRequester),
                            singleLine = true,
                            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                                imeAction = androidx.compose.ui.text.input.ImeAction.Done
                            ),
                            keyboardActions = androidx.compose.foundation.text.KeyboardActions(
                                onDone = { viewModel.connectToServer() }
                            )
                        )

                        Spacer(modifier = Modifier.height(24.dp))

                        Button(
                            onClick = viewModel::connectToServer,
                            modifier = Modifier.fillMaxWidth(),
                            enabled = !uiState.isLoading && uiState.serverUrl.isNotBlank()
                        ) {
                            Text(
                                text = if (uiState.isLoading) "Connecting..." else "Connect",
                                style = MaterialTheme.typography.labelLarge
                            )
                        }
                    } else {
                        // Login/Register
                        Text(
                            text = if (uiState.isRegisterMode) "Create Account" else "Sign In",
                            style = MaterialTheme.typography.headlineMedium,
                            color = OpenFlixColors.OnSurface
                        )

                        Spacer(modifier = Modifier.height(8.dp))

                        Text(
                            text = "Connected to: ${uiState.serverUrl}",
                            style = MaterialTheme.typography.bodySmall,
                            color = OpenFlixColors.TextSecondary
                        )

                        Spacer(modifier = Modifier.height(24.dp))

                        FocusableTextField(
                            value = uiState.username,
                            onValueChange = viewModel::updateUsername,
                            label = "Username",
                            modifier = Modifier
                                .fillMaxWidth()
                                .focusRequester(usernameFocusRequester),
                            singleLine = true,
                            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                                imeAction = androidx.compose.ui.text.input.ImeAction.Next
                            ),
                            keyboardActions = androidx.compose.foundation.text.KeyboardActions(
                                onNext = { passwordFocusRequester.requestFocus() }
                            )
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        FocusableTextField(
                            value = uiState.password,
                            onValueChange = viewModel::updatePassword,
                            label = "Password",
                            modifier = Modifier
                                .fillMaxWidth()
                                .focusRequester(passwordFocusRequester),
                            singleLine = true,
                            visualTransformation = PasswordVisualTransformation(),
                            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                                imeAction = androidx.compose.ui.text.input.ImeAction.Done
                            ),
                            keyboardActions = androidx.compose.foundation.text.KeyboardActions(
                                onDone = {
                                    if (!uiState.isRegisterMode) {
                                        viewModel.login()
                                    }
                                }
                            )
                        )

                        if (uiState.isRegisterMode) {
                            Spacer(modifier = Modifier.height(16.dp))

                            FocusableTextField(
                                value = uiState.email,
                                onValueChange = viewModel::updateEmail,
                                label = "Email (optional)",
                                modifier = Modifier.fillMaxWidth(),
                                singleLine = true
                            )
                        }

                        Spacer(modifier = Modifier.height(24.dp))

                        Button(
                            onClick = {
                                if (uiState.isRegisterMode) {
                                    viewModel.register()
                                } else {
                                    viewModel.login()
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            enabled = !uiState.isLoading
                        ) {
                            Text(
                                text = when {
                                    uiState.isLoading -> "Please wait..."
                                    uiState.isRegisterMode -> "Create Account"
                                    else -> "Sign In"
                                },
                                style = MaterialTheme.typography.labelLarge
                            )
                        }

                        Spacer(modifier = Modifier.height(16.dp))

                        // Toggle register/login
                        Button(
                            onClick = viewModel::toggleRegisterMode,
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.colors(
                                containerColor = OpenFlixColors.SurfaceVariant
                            )
                        ) {
                            Text(
                                text = if (uiState.isRegisterMode) {
                                    "Already have an account? Sign In"
                                } else {
                                    "New user? Create Account"
                                },
                                style = MaterialTheme.typography.labelMedium
                            )
                        }
                    }

                    // Error message
                    if (uiState.error != null) {
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = uiState.error!!,
                            style = MaterialTheme.typography.bodyMedium,
                            color = OpenFlixColors.Error,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    }
}

/**
 * Server item in the discovered servers list
 */
@Composable
private fun DiscoveredServerItem(
    server: DiscoveredServer,
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
            containerColor = OpenFlixColors.SurfaceVariant,
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
            // Server icon
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .background(OpenFlixColors.Primary.copy(alpha = 0.2f), MaterialTheme.shapes.small),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "📺",
                    style = MaterialTheme.typography.headlineSmall
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = server.name,
                    style = MaterialTheme.typography.titleMedium,
                    color = OpenFlixColors.OnSurface
                )
                Text(
                    text = "${server.host}:${server.port}",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextSecondary
                )
                Text(
                    text = "v${server.version}",
                    style = MaterialTheme.typography.bodySmall,
                    color = OpenFlixColors.TextTertiary
                )
            }

            // Connect indicator
            Text(
                text = "→",
                style = MaterialTheme.typography.headlineMedium,
                color = if (isFocused) OpenFlixColors.Primary else OpenFlixColors.TextTertiary
            )
        }
    }
}
