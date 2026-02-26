package com.openflix.data.discovery

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class DiscoveredServer(
    val name: String = "OpenFlix Server",
    val version: String = "",
    @SerialName("machineId") val machineId: String = "",
    val host: String = "",
    val port: Int = 32400,
    val protocol: String = "http",
    val localAddresses: List<String> = emptyList()
) {
    val url: String get() = "$protocol://$host:$port"
    val displayUrl: String get() = "$host:$port"
}

@Serializable
data class DiscoveryResponse(
    val magic: String = "",
    val server: DiscoveredServer? = null
)

/**
 * Platform-specific server discovery via UDP broadcast.
 * Sends "OPENFLIX_DISCOVER" to 255.255.255.255:32412 and
 * listens for "OPENFLIX_SERVER" responses.
 */
expect class ServerDiscoveryService() {
    /**
     * Discover servers on the local network.
     * Returns list of discovered servers within the timeout period.
     * @param timeoutMs How long to listen for responses (default 3000ms)
     */
    suspend fun discoverServers(timeoutMs: Long = 3000): List<DiscoveredServer>
}
