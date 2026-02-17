package com.openflix.data.repository

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.domain.model.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for managing remote access and network connectivity.
 * Handles Tailscale integration and automatic network type detection.
 */
@Singleton
class RemoteAccessRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val api: OpenFlixApi,
    private val preferencesManager: PreferencesManager
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val _networkType = MutableStateFlow(NetworkType.UNKNOWN)
    val networkType: StateFlow<NetworkType> = _networkType.asStateFlow()

    private val _connectionInfo = MutableStateFlow<ConnectionInfo?>(null)
    val connectionInfo: StateFlow<ConnectionInfo?> = _connectionInfo.asStateFlow()

    private val _remoteAccessStatus = MutableStateFlow<RemoteAccessStatus?>(null)
    val remoteAccessStatus: StateFlow<RemoteAccessStatus?> = _remoteAccessStatus.asStateFlow()

    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    init {
        startNetworkMonitoring()
    }

    /**
     * Monitor network connectivity changes.
     */
    private fun startNetworkMonitoring() {
        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                updateNetworkType()
            }

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) {
                updateNetworkType()
            }

            override fun onLost(network: Network) {
                _networkType.value = NetworkType.UNKNOWN
            }
        }

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        try {
            connectivityManager.registerNetworkCallback(request, networkCallback)
        } catch (e: Exception) {
            Timber.w(e, "Failed to register network callback")
        }

        // Initial check
        updateNetworkType()
    }

    private fun updateNetworkType() {
        val activeNetwork = connectivityManager.activeNetwork
        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)

        _networkType.value = when {
            capabilities == null -> NetworkType.UNKNOWN
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> NetworkType.VPN
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> NetworkType.ETHERNET
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> NetworkType.WIFI
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> NetworkType.CELLULAR
            else -> NetworkType.UNKNOWN
        }

        Timber.d("Network type updated: ${_networkType.value}")

        // Refresh connection info when network changes
        scope.launch {
            refreshConnectionInfo()
        }
    }

    /**
     * Get current network type as a flow.
     */
    fun observeNetworkType(): Flow<NetworkType> = callbackFlow {
        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                trySend(getCurrentNetworkType())
            }

            override fun onCapabilitiesChanged(
                network: Network,
                networkCapabilities: NetworkCapabilities
            ) {
                trySend(getCurrentNetworkType())
            }

            override fun onLost(network: Network) {
                trySend(NetworkType.UNKNOWN)
            }
        }

        val request = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        try {
            connectivityManager.registerNetworkCallback(request, networkCallback)
            trySend(getCurrentNetworkType())
        } catch (e: Exception) {
            Timber.w(e, "Failed to register network callback")
        }

        awaitClose {
            try {
                connectivityManager.unregisterNetworkCallback(networkCallback)
            } catch (e: Exception) {
                Timber.w(e, "Failed to unregister network callback")
            }
        }
    }

    private fun getCurrentNetworkType(): NetworkType {
        val activeNetwork = connectivityManager.activeNetwork
        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)

        return when {
            capabilities == null -> NetworkType.UNKNOWN
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> NetworkType.VPN
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> NetworkType.ETHERNET
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> NetworkType.WIFI
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> NetworkType.CELLULAR
            else -> NetworkType.UNKNOWN
        }
    }

    /**
     * Refresh connection info from server.
     */
    suspend fun refreshConnectionInfo(): Result<ConnectionInfo> {
        return try {
            val response = api.getConnectionInfo()
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                val info = ConnectionInfo(
                    serverUrl = dto.serverUrl,
                    networkType = NetworkType.valueOf(dto.networkType.uppercase()),
                    isRemote = dto.isRemote,
                    suggestedQuality = RemoteStreamingQuality.fromString(dto.suggestedQuality),
                    tailscaleAvailable = dto.tailscaleAvailable ?: false
                )
                _connectionInfo.value = info
                Result.success(info)
            } else {
                Result.failure(Exception("Failed to get connection info: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching connection info")
            Result.failure(e)
        }
    }

    /**
     * Get remote access status (admin only).
     */
    suspend fun getRemoteAccessStatus(): Result<RemoteAccessStatus> {
        return try {
            val response = api.getRemoteAccessStatus()
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                val status = RemoteAccessStatus(
                    enabled = dto.enabled,
                    connected = dto.connected,
                    method = dto.method ?: "tailscale",
                    tailscaleIp = dto.tailscaleIp,
                    tailscaleHostname = dto.tailscaleHostname,
                    magicDnsName = dto.magicDnsName,
                    backendState = dto.backendState,
                    loginUrl = dto.loginUrl,
                    lastSeen = dto.lastSeen,
                    error = dto.error
                )
                _remoteAccessStatus.value = status
                Result.success(status)
            } else {
                Result.failure(Exception("Failed to get remote access status: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching remote access status")
            Result.failure(e)
        }
    }

    /**
     * Enable remote access (admin only).
     */
    suspend fun enableRemoteAccess(): Result<RemoteAccessStatus> {
        return try {
            val response = api.enableRemoteAccess()
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                val status = RemoteAccessStatus(
                    enabled = dto.enabled,
                    connected = dto.connected,
                    method = dto.method ?: "tailscale",
                    tailscaleIp = dto.tailscaleIp,
                    tailscaleHostname = dto.tailscaleHostname,
                    magicDnsName = dto.magicDnsName,
                    backendState = dto.backendState,
                    loginUrl = dto.loginUrl,
                    lastSeen = dto.lastSeen,
                    error = dto.error
                )
                _remoteAccessStatus.value = status
                Result.success(status)
            } else {
                Result.failure(Exception("Failed to enable remote access: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error enabling remote access")
            Result.failure(e)
        }
    }

    /**
     * Disable remote access (admin only).
     */
    suspend fun disableRemoteAccess(): Result<RemoteAccessStatus> {
        return try {
            val response = api.disableRemoteAccess()
            if (response.isSuccessful) {
                // Disable returns Unit, create disabled status
                val status = RemoteAccessStatus(
                    enabled = false,
                    connected = false,
                    method = "tailscale",
                    tailscaleIp = null,
                    tailscaleHostname = null,
                    magicDnsName = null,
                    backendState = null,
                    loginUrl = null,
                    lastSeen = null,
                    error = null
                )
                _remoteAccessStatus.value = status
                Result.success(status)
            } else {
                Result.failure(Exception("Failed to disable remote access: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error disabling remote access")
            Result.failure(e)
        }
    }

    /**
     * Get health check status (admin only).
     */
    suspend fun getHealth(): Result<TailscaleHealth> {
        return try {
            val response = api.getRemoteAccessHealth()
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                Result.success(
                    TailscaleHealth(
                        healthy = dto.healthy,
                        checks = dto.checks ?: emptyMap(),
                        warnings = dto.warnings ?: emptyList()
                    )
                )
            } else {
                Result.failure(Exception("Failed to get health: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching health")
            Result.failure(e)
        }
    }

    /**
     * Get install info for Tailscale setup (admin only).
     */
    suspend fun getInstallInfo(): Result<TailscaleInstallInfo> {
        return try {
            val response = api.getRemoteAccessInstallInfo()
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                Result.success(
                    TailscaleInstallInfo(
                        isInstalled = dto.isInstalled,
                        currentVersion = dto.currentVersion,
                        installCommand = dto.installCommand ?: "curl -fsSL https://tailscale.com/install.sh | sh",
                        configureCommand = dto.configureCommand ?: "tailscale up --hostname=openflix",
                        docUrl = dto.docUrl ?: "https://tailscale.com/kb/1017/install"
                    )
                )
            } else {
                Result.failure(Exception("Failed to get install info: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching install info")
            Result.failure(e)
        }
    }

    /**
     * Get login URL for Tailscale authentication.
     */
    suspend fun getLoginUrl(): Result<String?> {
        return try {
            val response = api.getRemoteAccessLoginUrl()
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.url)
            } else {
                Result.failure(Exception("Failed to get login URL: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching login URL")
            Result.failure(e)
        }
    }

    /**
     * Get preferred remote streaming quality from preferences.
     */
    fun getPreferredRemoteQuality(): Flow<RemoteStreamingQuality> {
        return preferencesManager.remoteStreamingQuality.map { qualityString ->
            RemoteStreamingQuality.fromString(qualityString)
        }
    }

    /**
     * Set preferred remote streaming quality.
     */
    suspend fun setPreferredRemoteQuality(quality: RemoteStreamingQuality) {
        preferencesManager.setRemoteStreamingQuality(quality.name)
    }

    /**
     * Determine if currently on a remote connection.
     */
    suspend fun isRemoteConnection(): Boolean {
        return connectionInfo.value?.isRemote ?: run {
            refreshConnectionInfo()
            connectionInfo.value?.isRemote ?: false
        }
    }

    /**
     * Get recommended quality based on current network.
     */
    fun getRecommendedQuality(): RemoteStreamingQuality {
        return RemoteStreamingQuality.suggestedFor(_networkType.value)
    }
}
