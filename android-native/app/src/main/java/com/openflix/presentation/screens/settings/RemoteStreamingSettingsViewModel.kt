package com.openflix.presentation.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.RemoteAccessRepository
import com.openflix.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class RemoteStreamingSettingsViewModel @Inject constructor(
    private val remoteAccessRepository: RemoteAccessRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(RemoteStreamingUiState())
    val uiState: StateFlow<RemoteStreamingUiState> = _uiState.asStateFlow()

    init {
        loadInitialState()
        observeNetworkChanges()
    }

    private fun loadInitialState() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }

            // Load preferred quality
            remoteAccessRepository.getPreferredRemoteQuality().first().let { quality ->
                _uiState.update { it.copy(preferredQuality = quality) }
            }

            // Refresh connection info
            remoteAccessRepository.refreshConnectionInfo().fold(
                onSuccess = { info ->
                    _uiState.update { state ->
                        state.copy(
                            connectionInfo = info,
                            isRemote = info.isRemote
                        )
                    }
                },
                onFailure = { error ->
                    Timber.w(error, "Failed to get connection info")
                }
            )

            // Load remote access status (if admin)
            loadRemoteAccessStatus()

            _uiState.update { it.copy(isLoading = false) }
        }
    }

    private fun observeNetworkChanges() {
        viewModelScope.launch {
            remoteAccessRepository.networkType.collect { networkType ->
                _uiState.update { it.copy(networkType = networkType) }
            }
        }

        viewModelScope.launch {
            remoteAccessRepository.connectionInfo.collect { info ->
                info?.let {
                    _uiState.update { state ->
                        state.copy(
                            connectionInfo = info,
                            isRemote = info.isRemote
                        )
                    }
                }
            }
        }
    }

    private suspend fun loadRemoteAccessStatus() {
        remoteAccessRepository.getRemoteAccessStatus().fold(
            onSuccess = { status ->
                _uiState.update { it.copy(remoteAccessStatus = status) }
            },
            onFailure = { error ->
                // May not be admin, which is fine
                Timber.d("Could not load remote access status: ${error.message}")
            }
        )
    }

    fun setPreferredQuality(quality: RemoteStreamingQuality) {
        viewModelScope.launch {
            remoteAccessRepository.setPreferredRemoteQuality(quality)
            _uiState.update { it.copy(preferredQuality = quality) }
        }
    }

    fun enableRemoteAccess() {
        viewModelScope.launch {
            _uiState.update { it.copy(isEnabling = true, error = null) }

            remoteAccessRepository.enableRemoteAccess().fold(
                onSuccess = { status ->
                    _uiState.update {
                        it.copy(
                            remoteAccessStatus = status,
                            isEnabling = false,
                            loginUrl = status.loginUrl
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            isEnabling = false,
                            error = error.message ?: "Failed to enable remote access"
                        )
                    }
                }
            )
        }
    }

    fun disableRemoteAccess() {
        viewModelScope.launch {
            _uiState.update { it.copy(isDisabling = true, error = null) }

            remoteAccessRepository.disableRemoteAccess().fold(
                onSuccess = { status ->
                    _uiState.update {
                        it.copy(
                            remoteAccessStatus = status,
                            isDisabling = false
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            isDisabling = false,
                            error = error.message ?: "Failed to disable remote access"
                        )
                    }
                }
            )
        }
    }

    fun refreshStatus() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true) }

            remoteAccessRepository.refreshConnectionInfo()
            loadRemoteAccessStatus()

            _uiState.update { it.copy(isRefreshing = false) }
        }
    }

    fun checkHealth() {
        viewModelScope.launch {
            remoteAccessRepository.getHealth().fold(
                onSuccess = { health ->
                    _uiState.update { it.copy(tailscaleHealth = health) }
                },
                onFailure = { error ->
                    Timber.w(error, "Health check failed")
                }
            )
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun clearLoginUrl() {
        _uiState.update { it.copy(loginUrl = null) }
    }
}

data class RemoteStreamingUiState(
    val isLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val isEnabling: Boolean = false,
    val isDisabling: Boolean = false,
    val networkType: NetworkType = NetworkType.UNKNOWN,
    val connectionInfo: ConnectionInfo? = null,
    val remoteAccessStatus: RemoteAccessStatus? = null,
    val preferredQuality: RemoteStreamingQuality = RemoteStreamingQuality.AUTO,
    val isRemote: Boolean = false,
    val tailscaleHealth: TailscaleHealth? = null,
    val loginUrl: String? = null,
    val error: String? = null
) {
    val isConnected: Boolean
        get() = remoteAccessStatus?.connected ?: false

    val isTailscaleEnabled: Boolean
        get() = remoteAccessStatus?.enabled ?: false

    val tailscaleIp: String?
        get() = remoteAccessStatus?.tailscaleIp

    val tailscaleHostname: String?
        get() = remoteAccessStatus?.tailscaleHostname ?: remoteAccessStatus?.magicDnsName

    val backendState: String
        get() = remoteAccessStatus?.backendState ?: "Unknown"

    val canManageTailscale: Boolean
        get() = remoteAccessStatus != null
}
