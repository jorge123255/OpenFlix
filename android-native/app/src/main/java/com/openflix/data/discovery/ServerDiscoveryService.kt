package com.openflix.data.discovery

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONObject
import timber.log.Timber
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.SocketTimeoutException
import java.net.URL
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Service for discovering OpenFlix servers on the local network.
 * Uses UDP broadcast/multicast for auto-discovery (like Plex GDM).
 * Also probes known addresses via HTTP for emulator compatibility.
 */
@Singleton
class ServerDiscoveryService @Inject constructor() {

    companion object {
        const val DISCOVERY_PORT = 32412  // Port to send discovery requests
        const val BROADCAST_PORT = 32414  // Port to listen for server broadcasts
        const val DISCOVERY_MAGIC = "OPENFLIX_DISCOVER"
        const val RESPONSE_MAGIC = "OPENFLIX_SERVER"
        const val DISCOVERY_TIMEOUT = 3000  // 3 seconds
        const val BROADCAST_LISTEN_TIMEOUT = 5000  // 5 seconds
        const val HTTP_TIMEOUT = 2000  // 2 seconds for HTTP probes

        // Known addresses to probe (for emulator and common setups)
        val PROBE_ADDRESSES = listOf(
            "192.168.1.180",   // OpenFlix server (primary)
            "10.0.2.2",        // Android emulator host
            "192.168.1.185",   // Fallback
            "192.168.1.1",     // Common router/server
            "192.168.1.100",   // Common server address
            "localhost",
            "127.0.0.1"
        )

        const val DEFAULT_PORT = 32400
    }

    private val _discoveredServers = MutableStateFlow<List<DiscoveredServer>>(emptyList())
    val discoveredServers: StateFlow<List<DiscoveredServer>> = _discoveredServers.asStateFlow()

    private val _isDiscovering = MutableStateFlow(false)
    val isDiscovering: StateFlow<Boolean> = _isDiscovering.asStateFlow()

    private var discoveryJob: Job? = null
    private var broadcastListenerJob: Job? = null

    /**
     * Start discovering servers on the local network.
     * Uses both UDP broadcast and HTTP probing for maximum compatibility.
     */
    suspend fun discoverServers(): List<DiscoveredServer> = withContext(Dispatchers.IO) {
        if (_isDiscovering.value) {
            return@withContext _discoveredServers.value
        }

        _isDiscovering.value = true
        val servers = mutableListOf<DiscoveredServer>()

        // Try UDP broadcast first
        try {
            val socket = DatagramSocket()
            socket.broadcast = true
            socket.soTimeout = DISCOVERY_TIMEOUT

            val broadcastAddress = InetAddress.getByName("255.255.255.255")
            val message = DISCOVERY_MAGIC.toByteArray()
            val packet = DatagramPacket(
                message,
                message.size,
                broadcastAddress,
                DISCOVERY_PORT
            )

            Timber.d("Sending discovery broadcast...")
            socket.send(packet)

            val buffer = ByteArray(4096)
            val receivePacket = DatagramPacket(buffer, buffer.size)

            val startTime = System.currentTimeMillis()
            while (System.currentTimeMillis() - startTime < DISCOVERY_TIMEOUT) {
                try {
                    socket.receive(receivePacket)
                    val response = String(buffer, 0, receivePacket.length)

                    parseServerResponse(response, receivePacket.address.hostAddress)?.let { server ->
                        if (servers.none { it.machineId == server.machineId }) {
                            servers.add(server)
                            Timber.d("Discovered server via UDP: ${server.name} at ${server.host}:${server.port}")
                        }
                    }
                } catch (e: SocketTimeoutException) {
                    break
                }
            }

            socket.close()
        } catch (e: Exception) {
            Timber.e(e, "UDP discovery failed")
        }

        // Also probe known addresses via HTTP (for emulator compatibility)
        Timber.d("Probing known addresses via HTTP...")
        val probeJobs = PROBE_ADDRESSES.map { address ->
            async {
                probeServerHttp(address, DEFAULT_PORT)
            }
        }

        probeJobs.awaitAll().filterNotNull().forEach { server ->
            if (servers.none { it.machineId == server.machineId || it.host == server.host }) {
                servers.add(server)
                Timber.d("Discovered server via HTTP: ${server.name} at ${server.host}:${server.port}")
            }
        }

        _discoveredServers.value = servers
        _isDiscovering.value = false
        servers
    }

    /**
     * Probe a specific address via HTTP to check if an OpenFlix server is running.
     */
    private fun probeServerHttp(host: String, port: Int): DiscoveredServer? {
        return try {
            val url = URL("http://$host:$port/identity")
            val connection = url.openConnection() as HttpURLConnection
            connection.connectTimeout = HTTP_TIMEOUT
            connection.readTimeout = HTTP_TIMEOUT
            connection.requestMethod = "GET"

            if (connection.responseCode == 200) {
                val response = connection.inputStream.bufferedReader().readText()
                connection.disconnect()
                parseIdentityResponse(response, host, port)
            } else {
                connection.disconnect()
                null
            }
        } catch (e: Exception) {
            // Server not reachable at this address
            null
        }
    }

    /**
     * Parse the /identity endpoint response.
     * Format: {"MediaContainer":{"machineIdentifier":"...","version":"1.0.0"}}
     */
    private fun parseIdentityResponse(response: String, host: String, port: Int): DiscoveredServer? {
        return try {
            val json = JSONObject(response)
            // Handle Plex-compatible MediaContainer format
            val container = json.optJSONObject("MediaContainer") ?: json

            DiscoveredServer(
                name = container.optString("friendlyName",
                    container.optString("name", "OpenFlix Server")),
                version = container.optString("version", "unknown"),
                machineId = container.optString("machineIdentifier", host),
                host = host,
                port = port,
                protocol = "http",
                localAddresses = listOf(host)
            )
        } catch (e: Exception) {
            // If we got a 200 but couldn't parse, still return a basic server
            DiscoveredServer(
                name = "OpenFlix Server",
                version = "unknown",
                machineId = host,
                host = host,
                port = port,
                protocol = "http",
                localAddresses = listOf(host)
            )
        }
    }

    /**
     * Start listening for server broadcast announcements.
     * Servers periodically broadcast their presence.
     */
    fun startBroadcastListener() {
        if (broadcastListenerJob?.isActive == true) return

        broadcastListenerJob = CoroutineScope(Dispatchers.IO).launch {
            try {
                val socket = DatagramSocket(BROADCAST_PORT)
                socket.broadcast = true
                socket.soTimeout = BROADCAST_LISTEN_TIMEOUT

                Timber.d("Started broadcast listener on port $BROADCAST_PORT")

                while (isActive) {
                    try {
                        val buffer = ByteArray(4096)
                        val packet = DatagramPacket(buffer, buffer.size)
                        socket.receive(packet)

                        val response = String(buffer, 0, packet.length)
                        parseServerResponse(response, packet.address.hostAddress)?.let { server ->
                            // Update discovered servers list
                            val currentServers = _discoveredServers.value.toMutableList()
                            val existingIndex = currentServers.indexOfFirst { it.machineId == server.machineId }
                            if (existingIndex >= 0) {
                                currentServers[existingIndex] = server
                            } else {
                                currentServers.add(server)
                                Timber.d("New server broadcast received: ${server.name}")
                            }
                            _discoveredServers.value = currentServers
                        }
                    } catch (e: SocketTimeoutException) {
                        // Continue listening
                    }
                }

                socket.close()
            } catch (e: Exception) {
                Timber.e(e, "Error in broadcast listener")
            }
        }
    }

    /**
     * Stop listening for broadcast announcements.
     */
    fun stopBroadcastListener() {
        broadcastListenerJob?.cancel()
        broadcastListenerJob = null
    }

    /**
     * Parse a server response JSON.
     */
    private fun parseServerResponse(response: String, fallbackIp: String?): DiscoveredServer? {
        return try {
            val json = JSONObject(response)
            val magic = json.optString("magic")

            if (magic != RESPONSE_MAGIC) return null

            val serverJson = json.getJSONObject("server")

            // Get best address - prefer local addresses
            val localAddresses = mutableListOf<String>()
            val addressesArray = serverJson.optJSONArray("localAddresses")
            if (addressesArray != null) {
                for (i in 0 until addressesArray.length()) {
                    localAddresses.add(addressesArray.getString(i))
                }
            }

            // Use the first local address, or fall back to the packet source
            val host = localAddresses.firstOrNull() ?: fallbackIp ?: return null

            DiscoveredServer(
                name = serverJson.getString("name"),
                version = serverJson.getString("version"),
                machineId = serverJson.getString("machineId"),
                host = host,
                port = serverJson.getInt("port"),
                protocol = serverJson.optString("protocol", "http"),
                localAddresses = localAddresses
            )
        } catch (e: Exception) {
            Timber.e(e, "Failed to parse server response: $response")
            null
        }
    }

    /**
     * Clear discovered servers.
     */
    fun clearServers() {
        _discoveredServers.value = emptyList()
    }
}

/**
 * Represents a discovered OpenFlix server.
 */
data class DiscoveredServer(
    val name: String,
    val version: String,
    val machineId: String,
    val host: String,
    val port: Int,
    val protocol: String = "http",
    val localAddresses: List<String> = emptyList()
) {
    /**
     * Get the full server URL.
     */
    val url: String
        get() = "$protocol://$host:$port"
}
