package com.openflix.presentation.screens.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.discovery.DiscoveredServer
import com.openflix.data.discovery.ServerDiscoveryService
import com.openflix.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val discoveryService: ServerDiscoveryService,
    private val api: com.openflix.data.remote.api.OpenFlixApi
) : ViewModel() {

    val isAuthenticated: StateFlow<Boolean> = authRepository.isAuthenticated
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    private val _uiState = MutableStateFlow(AuthUiState())
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    // Discovered servers from the discovery service
    val discoveredServers: StateFlow<List<DiscoveredServer>> = discoveryService.discoveredServers
    val isDiscovering: StateFlow<Boolean> = discoveryService.isDiscovering

    init {
        // Start listening for server broadcasts and do initial discovery
        discoveryService.startBroadcastListener()
        discoverServersAndAutoConnect()
    }

    /**
     * Discover servers and auto-connect if on local network
     */
    private fun discoverServersAndAutoConnect() {
        viewModelScope.launch {
            try {
                val servers = discoveryService.discoverServers()
                if (servers.isNotEmpty()) {
                    Timber.d("Found ${servers.size} server(s) - auto-connecting to first one")
                    // Auto-connect to first discovered server (we're on local network)
                    val server = servers.first()
                    autoConnectToServer(server)
                }
            } catch (e: Exception) {
                Timber.e(e, "Server discovery failed")
            }
        }
    }

    /**
     * Auto-connect to a local server without requiring login
     */
    private fun autoConnectToServer(server: DiscoveredServer) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, serverUrl = server.url) }

            try {
                // Set the server URL and enable local access mode
                authRepository.setServerUrl(server.url)
                authRepository.setLocalAccessMode(true)

                Timber.d("Auto-connected to local server: ${server.name} at ${server.url}")
                _uiState.update { it.copy(
                    isLoading = false,
                    isServerConnected = true,
                    autoConnected = true
                )}
            } catch (e: Exception) {
                Timber.e(e, "Failed to auto-connect")
                _uiState.update { it.copy(
                    isLoading = false,
                    error = "Failed to connect: ${e.message}"
                )}
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        discoveryService.stopBroadcastListener()
    }

    /**
     * Trigger server discovery
     */
    fun discoverServers() {
        viewModelScope.launch {
            try {
                val servers = discoveryService.discoverServers()
                if (servers.isNotEmpty()) {
                    Timber.d("Found ${servers.size} server(s) on the network")
                }
            } catch (e: Exception) {
                Timber.e(e, "Server discovery failed")
            }
        }
    }

    /**
     * Select a discovered server
     */
    fun selectServer(server: DiscoveredServer) {
        _uiState.update { it.copy(serverUrl = server.url, error = null) }
        connectToServer()
    }

    fun updateServerUrl(url: String) {
        _uiState.update { it.copy(serverUrl = url, error = null) }
    }

    fun updateUsername(username: String) {
        _uiState.update { it.copy(username = username, error = null) }
    }

    fun updatePassword(password: String) {
        _uiState.update { it.copy(password = password, error = null) }
    }

    fun updateEmail(email: String) {
        _uiState.update { it.copy(email = email, error = null) }
    }

    fun toggleRegisterMode() {
        _uiState.update { it.copy(isRegisterMode = !it.isRegisterMode, error = null) }
    }

    fun connectToServer() {
        val serverUrl = _uiState.value.serverUrl.trim()
        if (serverUrl.isBlank()) {
            _uiState.update { it.copy(error = "Please enter a server URL") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            try {
                // Normalize URL
                val normalizedUrl = if (!serverUrl.startsWith("http")) {
                    "http://$serverUrl"
                } else {
                    serverUrl
                }

                // Save server URL first so AuthInterceptor can use it
                authRepository.setServerUrl(normalizedUrl)

                // Validate the server is reachable
                try {
                    val healthResponse = api.healthCheck()
                    if (!healthResponse.isSuccessful) {
                        Timber.w("Server health check returned ${healthResponse.code()}")
                    }
                } catch (e: Exception) {
                    Timber.e(e, "Server health check failed for $normalizedUrl")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = "Cannot reach server at $normalizedUrl - check the address and try again"
                    )}
                    return@launch
                }

                _uiState.update { it.copy(
                    isLoading = false,
                    isServerConnected = true,
                    serverUrl = normalizedUrl
                )}
                Timber.d("Connected to server: $normalizedUrl")
            } catch (e: Exception) {
                Timber.e(e, "Failed to connect to server")
                _uiState.update { it.copy(
                    isLoading = false,
                    error = "Failed to connect to server: ${e.message}"
                )}
            }
        }
    }

    fun login() {
        val username = _uiState.value.username.trim()
        val password = _uiState.value.password

        if (username.isBlank() || password.isBlank()) {
            _uiState.update { it.copy(error = "Please enter username and password") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = authRepository.login(username, password)

            result.fold(
                onSuccess = { user ->
                    Timber.d("Login successful: ${user.username}")
                    _uiState.update { it.copy(isLoading = false) }
                },
                onFailure = { error ->
                    Timber.e(error, "Login failed")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = error.message ?: "Login failed"
                    )}
                }
            )
        }
    }

    fun register() {
        val username = _uiState.value.username.trim()
        val password = _uiState.value.password
        val email = _uiState.value.email.trim().takeIf { it.isNotBlank() }

        if (username.isBlank() || password.isBlank()) {
            _uiState.update { it.copy(error = "Please enter username and password") }
            return
        }

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            val result = authRepository.register(username, password, email)

            result.fold(
                onSuccess = { user ->
                    Timber.d("Registration successful: ${user.username}")
                    _uiState.update { it.copy(isLoading = false) }
                },
                onFailure = { error ->
                    Timber.e(error, "Registration failed")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = error.message ?: "Registration failed"
                    )}
                }
            )
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}

data class AuthUiState(
    val serverUrl: String = "",
    val username: String = "",
    val password: String = "",
    val email: String = "",
    val isLoading: Boolean = false,
    val isServerConnected: Boolean = false,
    val isRegisterMode: Boolean = false,
    val error: String? = null,
    val showServerPicker: Boolean = true,  // Show server picker initially
    val autoConnected: Boolean = false     // True when auto-connected to local server
)
