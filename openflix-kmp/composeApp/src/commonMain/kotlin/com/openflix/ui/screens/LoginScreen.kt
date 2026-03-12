package com.openflix.ui.screens

import androidx.compose.animation.*
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.openflix.data.discovery.ServerDiscoveryService
import com.openflix.data.local.AppSettings
import com.openflix.data.network.OpenFlixApi
import com.openflix.data.repository.AuthRepository
import com.openflix.ui.theme.OpenFlixColors
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.koin.compose.koinInject

private enum class LoginPhase {
    SPLASH_VIDEO,     // Full-screen intro video (every cold launch)
    SPLASH,           // Netflix-style animation + discovery + auto-connect
    MANUAL_ENTRY,     // Manual server URL entry (only if discovery fails)
    LOGIN_FORM,       // Username/password (only if server needs auth)
}

@Composable
fun LoginScreen(
    onLoginSuccess: () -> Unit
) {
    val api = koinInject<OpenFlixApi>()
    val authRepository = koinInject<AuthRepository>()
    val appSettings = koinInject<AppSettings>()
    val scope = rememberCoroutineScope()

    var phase by remember { mutableStateOf(LoginPhase.SPLASH_VIDEO) }
    var serverUrl by remember { mutableStateOf("") }
    var savedUrl by remember { mutableStateOf(appSettings.getServerUrl()) }
    var username by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var statusText by remember { mutableStateOf("Discovering servers...") }

    // Background connection result (runs during splash video)
    var bgConnected by remember { mutableStateOf(false) }
    var bgNeedsAuth by remember { mutableStateOf(false) }
    var bgConnectionDone by remember { mutableStateOf(false) }
    var bgFoundServerUrl by remember { mutableStateOf("") }

    // Try to connect to a server URL, returns true if should exit the LaunchedEffect
    suspend fun tryConnect(url: String, source: String): Boolean {
        try {
            api.configure(url, null)
            println("LOGIN: [$source] API configured, testing connection...")
            val connected = api.testConnection()
            println("LOGIN: [$source] testConnection() = $connected")
            if (!connected) throw Exception("Server not reachable")

            // Save on successful connection
            appSettings.saveServerUrl(url)
            savedUrl = url

            statusText = "Connected!"
            println("LOGIN: [$source] Connected! Calling onLoginSuccess()")
            onLoginSuccess()
            return true
        } catch (e: com.openflix.data.network.NetworkError.Unauthorized) {
            // Server needs auth
            println("LOGIN: [$source] Server needs auth, showing login form")
            serverUrl = url
            appSettings.saveServerUrl(url)
            savedUrl = url
            phase = LoginPhase.LOGIN_FORM
            return true
        } catch (e: Exception) {
            println("LOGIN: [$source] Connection failed: ${e::class.simpleName}: ${e.message}")
            return false
        }
    }

    // Start connection attempt in background immediately (runs during video)
    LaunchedEffect(Unit) {
        // 1. Try saved server URL first
        val saved = appSettings.getServerUrl()
        if (saved != null) {
            println("LOGIN: [bg] Found saved URL: $saved")
            bgFoundServerUrl = saved
            try {
                api.configure(saved, null)
                val connected = api.testConnection()
                if (connected) {
                    appSettings.saveServerUrl(saved)
                    savedUrl = saved
                    bgConnected = true
                    bgConnectionDone = true
                    println("LOGIN: [bg] Connected to saved URL")
                    return@LaunchedEffect
                }
            } catch (e: com.openflix.data.network.NetworkError.Unauthorized) {
                bgFoundServerUrl = saved
                appSettings.saveServerUrl(saved)
                savedUrl = saved
                bgNeedsAuth = true
                bgConnectionDone = true
                println("LOGIN: [bg] Saved URL needs auth")
                return@LaunchedEffect
            } catch (e: Exception) {
                println("LOGIN: [bg] Saved URL failed: ${e.message}")
            }
        }

        // 2. Run network discovery
        val discoveryService = ServerDiscoveryService()
        try {
            val servers = discoveryService.discoverServers(3000)
                .filter { it.host.isNotEmpty() && it.host != "0.0.0.0" && it.host != "127.0.0.1" }
            println("LOGIN: [bg] Discovery returned ${servers.size} servers")
            if (servers.isNotEmpty()) {
                val server = servers.first()
                bgFoundServerUrl = server.url
                try {
                    api.configure(server.url, null)
                    val connected = api.testConnection()
                    if (connected) {
                        appSettings.saveServerUrl(server.url)
                        savedUrl = server.url
                        bgConnected = true
                        bgConnectionDone = true
                        println("LOGIN: [bg] Connected via discovery")
                        return@LaunchedEffect
                    }
                } catch (e: com.openflix.data.network.NetworkError.Unauthorized) {
                    bgFoundServerUrl = server.url
                    appSettings.saveServerUrl(server.url)
                    savedUrl = server.url
                    bgNeedsAuth = true
                    bgConnectionDone = true
                    return@LaunchedEffect
                } catch (_: Exception) {}
            }
        } catch (e: Exception) {
            println("LOGIN: [bg] Discovery exception: ${e.message}")
        }
        bgConnectionDone = true
    }

    // Handle transition after splash video ends
    fun onSplashVideoFinished() {
        if (bgConnected) {
            onLoginSuccess()
        } else if (bgNeedsAuth) {
            serverUrl = bgFoundServerUrl
            phase = LoginPhase.LOGIN_FORM
        } else if (bgConnectionDone) {
            // Connection attempt finished but failed — go to manual entry
            phase = LoginPhase.MANUAL_ENTRY
        } else {
            // Connection still running — show brief splash animation while waiting
            phase = LoginPhase.SPLASH
        }
    }

    // If we're in SPLASH phase and background connection finishes, transition
    LaunchedEffect(phase, bgConnectionDone, bgConnected, bgNeedsAuth) {
        if (phase == LoginPhase.SPLASH && bgConnectionDone) {
            delay(300) // Brief pause for visual smoothness
            if (bgConnected) {
                onLoginSuccess()
            } else if (bgNeedsAuth) {
                serverUrl = bgFoundServerUrl
                phase = LoginPhase.LOGIN_FORM
            } else {
                phase = LoginPhase.MANUAL_ENTRY
            }
        }
    }

    Box(modifier = Modifier.fillMaxSize().background(Color.Black)) {
        AnimatedContent(
            targetState = phase,
            transitionSpec = {
                fadeIn(tween(400)) togetherWith fadeOut(tween(300))
            },
            label = "loginPhase"
        ) { currentPhase ->
            when (currentPhase) {
                LoginPhase.SPLASH_VIDEO -> {
                    SplashVideoScreen(
                        onFinished = { onSplashVideoFinished() }
                    )
                }

                LoginPhase.SPLASH -> {
                    SplashScreen(statusText = statusText)
                }

                LoginPhase.MANUAL_ENTRY -> {
                    ManualEntryScreen(
                        serverUrl = serverUrl,
                        onServerUrlChange = { serverUrl = it },
                        savedUrl = savedUrl,
                        onForgetSaved = {
                            appSettings.clearServerUrl()
                            appSettings.clearAuthToken()
                            savedUrl = null
                            serverUrl = ""
                        },
                        error = error,
                        isLoading = isLoading,
                        onConnect = {
                            scope.launch {
                                isLoading = true
                                error = null
                                try {
                                    api.configure(serverUrl.trim(), null)
                                    api.testConnection().also { if (!it) throw Exception("Server not reachable") }
                                    // Save on successful connection
                                    appSettings.saveServerUrl(serverUrl.trim())
                                    savedUrl = serverUrl.trim()
                                    onLoginSuccess()
                                } catch (e: com.openflix.data.network.NetworkError.Unauthorized) {
                                    appSettings.saveServerUrl(serverUrl.trim())
                                    savedUrl = serverUrl.trim()
                                    phase = LoginPhase.LOGIN_FORM
                                } catch (e: Exception) {
                                    error = "${e::class.simpleName}: ${e.message}"
                                }
                                isLoading = false
                            }
                        }
                    )
                }

                LoginPhase.LOGIN_FORM -> {
                    LoginFormScreen(
                        serverUrl = serverUrl,
                        username = username,
                        password = password,
                        onUsernameChange = { username = it },
                        onPasswordChange = { password = it },
                        error = error,
                        isLoading = isLoading,
                        onLogin = {
                            scope.launch {
                                isLoading = true
                                error = null
                                try {
                                    api.configure(serverUrl.trim(), null)
                                    authRepository.login(username.trim(), password.trim())
                                    onLoginSuccess()
                                } catch (e: Exception) {
                                    error = e.message ?: "Login failed"
                                }
                                isLoading = false
                            }
                        },
                        onBack = { phase = LoginPhase.MANUAL_ENTRY }
                    )
                }

            }
        }
    }
}

@Composable
private fun ManualEntryScreen(
    serverUrl: String,
    onServerUrlChange: (String) -> Unit,
    savedUrl: String?,
    onForgetSaved: () -> Unit,
    error: String?,
    isLoading: Boolean,
    onConnect: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = 400.dp)
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Connect to Server",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = OpenFlixColors.TextPrimary
            )

            Text(
                text = "Enter your OpenFlix server address",
                fontSize = 14.sp,
                color = OpenFlixColors.TextTertiary,
                textAlign = TextAlign.Center
            )

            // Show saved server with forget option
            if (savedUrl != null) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(OpenFlixColors.SurfaceElevated)
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Saved server",
                            fontSize = 11.sp,
                            color = OpenFlixColors.TextTertiary
                        )
                        Text(
                            text = savedUrl,
                            fontSize = 14.sp,
                            color = OpenFlixColors.TextPrimary
                        )
                    }
                    Text(
                        text = "Forget",
                        fontSize = 13.sp,
                        color = OpenFlixColors.Error,
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .clickable(onClick = onForgetSaved)
                            .padding(horizontal = 12.dp, vertical = 6.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            InputField(
                value = serverUrl,
                onValueChange = onServerUrlChange,
                placeholder = "http://192.168.1.100:32400"
            )

            error?.let {
                Text(text = it, color = OpenFlixColors.Error, fontSize = 14.sp, textAlign = TextAlign.Center)
            }

            PrimaryButton(
                text = if (isLoading) "Connecting..." else "Connect",
                isLoading = isLoading,
                onClick = onConnect
            )
        }
    }
}

@Composable
private fun LoginFormScreen(
    serverUrl: String,
    username: String,
    password: String,
    onUsernameChange: (String) -> Unit,
    onPasswordChange: (String) -> Unit,
    error: String?,
    isLoading: Boolean,
    onLogin: () -> Unit,
    onBack: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(OpenFlixColors.Background),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = 400.dp)
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Sign In",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = OpenFlixColors.TextPrimary
            )

            // Connected server pill
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(999.dp))
                    .background(OpenFlixColors.Primary.copy(alpha = 0.15f))
                    .padding(horizontal = 16.dp, vertical = 6.dp)
            ) {
                Text(
                    text = serverUrl,
                    fontSize = 12.sp,
                    color = OpenFlixColors.Primary
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            InputField(value = username, onValueChange = onUsernameChange, placeholder = "Username")
            InputField(value = password, onValueChange = onPasswordChange, placeholder = "Password", isPassword = true)

            error?.let {
                Text(text = it, color = OpenFlixColors.Error, fontSize = 14.sp, textAlign = TextAlign.Center)
            }

            PrimaryButton(
                text = if (isLoading) "Signing in..." else "Sign In",
                isLoading = isLoading,
                onClick = onLogin
            )

            Text(
                text = "Change server",
                color = OpenFlixColors.TextTertiary,
                fontSize = 14.sp,
                modifier = Modifier.clickable(onClick = onBack)
            )
        }
    }
}

@Composable
private fun InputField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    isPassword: Boolean = false
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(OpenFlixColors.SurfaceElevated)
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        if (value.isEmpty()) {
            Text(text = placeholder, color = OpenFlixColors.TextTertiary, fontSize = 15.sp)
        }
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            singleLine = true,
            textStyle = TextStyle(color = OpenFlixColors.TextPrimary, fontSize = 15.sp),
            cursorBrush = SolidColor(OpenFlixColors.Primary),
            visualTransformation = if (isPassword) PasswordVisualTransformation() else VisualTransformation.None,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun PrimaryButton(
    text: String,
    isLoading: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(48.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(if (isLoading) OpenFlixColors.PrimaryDark else OpenFlixColors.Primary)
            .clickable(enabled = !isLoading, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                color = OpenFlixColors.OnPrimary,
                modifier = Modifier.size(24.dp),
                strokeWidth = 2.dp
            )
        } else {
            Text(text = text, color = OpenFlixColors.OnPrimary, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
        }
    }
}
