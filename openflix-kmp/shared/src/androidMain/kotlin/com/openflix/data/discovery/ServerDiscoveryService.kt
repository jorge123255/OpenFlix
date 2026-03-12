package com.openflix.data.discovery

import android.annotation.SuppressLint
import android.content.Context
import android.net.wifi.WifiManager
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface

private const val TAG = "ServerDiscovery"

actual class ServerDiscoveryService {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    companion object {
        @SuppressLint("StaticFieldLeak")
        private var appContext: Context? = null

        fun init(context: Context) {
            appContext = context.applicationContext
        }
    }

    actual suspend fun discoverServers(timeoutMs: Long): List<DiscoveredServer> {
        return withContext(Dispatchers.IO) {
            val servers = mutableListOf<DiscoveredServer>()
            val seenIds = mutableSetOf<String>()

            // Acquire multicast lock (required on many Android TV devices for UDP broadcast)
            val ctx = appContext
            val wifiManager = ctx?.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            val multicastLock = wifiManager?.createMulticastLock("openflix_discovery")
            try {
                multicastLock?.setReferenceCounted(false)
                multicastLock?.acquire()
                Log.d(TAG, "Multicast lock acquired: ${multicastLock?.isHeld}")
            } catch (e: Exception) {
                Log.w(TAG, "Failed to acquire multicast lock: ${e.message}")
            }

            try {
                // Phase 1: Send discovery broadcast
                val socket = DatagramSocket().apply {
                    broadcast = true
                    soTimeout = timeoutMs.toInt()
                }

                val message = "OPENFLIX_DISCOVER".toByteArray()

                // Send to global broadcast address
                try {
                    val broadcastAddr = InetAddress.getByName("255.255.255.255")
                    socket.send(DatagramPacket(message, message.size, broadcastAddr, 32412))
                    Log.d(TAG, "Sent discovery to 255.255.255.255:32412")
                } catch (e: Exception) {
                    Log.w(TAG, "Global broadcast failed: ${e.message}")
                }

                // Also send to subnet-specific broadcast addresses (more reliable on Android TV)
                try {
                    for (iface in NetworkInterface.getNetworkInterfaces().toList()) {
                        if (iface.isLoopback || !iface.isUp) continue
                        for (ifAddr in iface.interfaceAddresses) {
                            val broadcast = ifAddr.broadcast ?: continue
                            try {
                                socket.send(DatagramPacket(message, message.size, broadcast, 32412))
                                Log.d(TAG, "Sent discovery to ${broadcast.hostAddress}:32412")
                            } catch (_: Exception) {}
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Subnet broadcast failed: ${e.message}")
                }

                // Phase 2: Listen for responses
                val buffer = ByteArray(4096)
                val startTime = System.currentTimeMillis()

                while (System.currentTimeMillis() - startTime < timeoutMs) {
                    try {
                        val receivePacket = DatagramPacket(buffer, buffer.size)
                        socket.receive(receivePacket)

                        val responseStr = String(receivePacket.data, 0, receivePacket.length)
                        Log.d(TAG, "Response from ${receivePacket.address.hostAddress}: ${responseStr.take(200)}")

                        val server = parseResponse(responseStr, receivePacket.address.hostAddress ?: "")
                        if (server != null && seenIds.add(server.machineId.ifEmpty { server.host })) {
                            servers.add(server)
                            Log.d(TAG, "Found server: ${server.name} at ${server.url}")
                        }
                    } catch (_: java.net.SocketTimeoutException) {
                        break
                    } catch (e: Exception) {
                        Log.w(TAG, "Receive error: ${e.message}")
                        break
                    }
                }

                socket.close()

                // Phase 3: Passive listen on 32414 if no responses
                if (servers.isEmpty()) {
                    Log.d(TAG, "No broadcast responses, trying passive listen on 32414...")
                    try {
                        val listenSocket = DatagramSocket(null).apply {
                            reuseAddress = true
                            bind(InetSocketAddress(32414))
                            soTimeout = timeoutMs.toInt().coerceAtMost(2000)
                        }

                        val listenBuffer = ByteArray(4096)
                        val listenPacket = DatagramPacket(listenBuffer, listenBuffer.size)

                        try {
                            listenSocket.receive(listenPacket)
                            val responseStr = String(listenPacket.data, 0, listenPacket.length)
                            Log.d(TAG, "Passive response: ${responseStr.take(200)}")
                            val server = parseResponse(responseStr, listenPacket.address.hostAddress ?: "")
                            if (server != null) {
                                servers.add(server)
                                Log.d(TAG, "Found server (passive): ${server.name} at ${server.url}")
                            }
                        } catch (_: java.net.SocketTimeoutException) {
                            Log.d(TAG, "Passive listen timed out")
                        } catch (e: Exception) {
                            Log.w(TAG, "Passive listen error: ${e.message}")
                        }

                        listenSocket.close()
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to bind port 32414: ${e.message}")
                    }
                }

                Log.d(TAG, "Discovery complete: ${servers.size} server(s) found")
            } catch (e: Exception) {
                Log.e(TAG, "Discovery failed", e)
            } finally {
                try {
                    if (multicastLock?.isHeld == true) {
                        multicastLock.release()
                    }
                } catch (_: Exception) {}
            }

            servers
        }
    }

    private fun parseResponse(response: String, fallbackHost: String): DiscoveredServer? {
        return try {
            val parsed = json.decodeFromString<DiscoveryResponse>(response)
            if (parsed.magic == "OPENFLIX_SERVER" && parsed.server != null) {
                val server = parsed.server
                // Server may report "0.0.0.0" as host — use the actual packet source IP instead
                if (server.host.isEmpty() || server.host == "0.0.0.0" || server.host == "127.0.0.1") {
                    server.copy(host = fallbackHost)
                } else server
            } else null
        } catch (e: Exception) {
            Log.w(TAG, "Parse error: ${e.message}")
            null
        }
    }
}
