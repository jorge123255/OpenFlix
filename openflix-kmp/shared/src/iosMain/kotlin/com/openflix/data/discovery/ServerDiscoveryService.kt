package com.openflix.data.discovery

import kotlinx.cinterop.*
import kotlinx.coroutines.*
import kotlinx.serialization.json.Json
import platform.Foundation.*
import platform.darwin.NSObject
import platform.posix.*
import kotlin.coroutines.resume

@OptIn(kotlinx.cinterop.BetaInteropApi::class)
actual class ServerDiscoveryService {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    actual suspend fun discoverServers(timeoutMs: Long): List<DiscoveredServer> {
        // Try Bonjour/mDNS first (the Apple-native way)
        val bonjourServers = discoverViaBonjour(timeoutMs)
        if (bonjourServers.isNotEmpty()) return bonjourServers

        // Fallback: try UDP broadcast
        return discoverViaUDP(timeoutMs = 2000)
    }

    private suspend fun discoverViaBonjour(timeoutMs: Long): List<DiscoveredServer> {
        return withTimeoutOrNull(timeoutMs) {
            suspendCancellableCoroutine { continuation ->
                val servers = mutableListOf<DiscoveredServer>()
                var resumed = false

                val delegate = BonjourBrowserDelegate(
                    onServiceFound = { service ->
                        // Resolve the service to get host/port
                        val resolveDelegate = BonjourResolveDelegate(
                            onResolved = { host, port, txtRecords ->
                                if (host.isNotEmpty() && host != "0.0.0.0") {
                                    val version = txtRecords["version"] ?: ""
                                    val machineId = txtRecords["machineId"] ?: ""
                                    val server = DiscoveredServer(
                                        name = service.name,
                                        host = host,
                                        port = port,
                                        protocol = "http",
                                        version = version,
                                        machineId = machineId
                                    )
                                    servers.add(server)
                                    if (!resumed) {
                                        resumed = true
                                        continuation.resume(servers)
                                    }
                                }
                            },
                            onFailed = { /* ignore resolve failures */ }
                        )
                        service.delegate = resolveDelegate
                        service.resolveWithTimeout(5.0)
                    },
                    onStopped = {
                        if (!resumed) {
                            resumed = true
                            continuation.resume(servers)
                        }
                    }
                )

                val browser = NSNetServiceBrowser()
                browser.delegate = delegate
                browser.searchForServicesOfType("_openflix._tcp.", inDomain = "local.")

                continuation.invokeOnCancellation {
                    browser.stop()
                }
            }
        } ?: emptyList()
    }

    // Fallback UDP discovery
    @OptIn(ExperimentalForeignApi::class)
    private suspend fun discoverViaUDP(timeoutMs: Long): List<DiscoveredServer> {
        return withContext(Dispatchers.IO) {
            val servers = mutableListOf<DiscoveredServer>()

            try {
                val sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
                if (sock < 0) return@withContext servers

                memScoped {
                    val broadcastEnable = alloc<IntVar>()
                    broadcastEnable.value = 1
                    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, broadcastEnable.ptr, sizeOf<IntVar>().toUInt())

                    val tv = alloc<timeval>()
                    tv.tv_sec = (timeoutMs / 1000)
                    tv.tv_usec = ((timeoutMs % 1000) * 1000).toInt()
                    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, tv.ptr, sizeOf<timeval>().toUInt())

                    val destAddr = alloc<sockaddr_in>()
                    destAddr.sin_family = AF_INET.toUByte()
                    destAddr.sin_port = hostToNetworkShort(32412u)
                    destAddr.sin_addr.s_addr = parseIpAddress("255.255.255.255")

                    val message = "OPENFLIX_DISCOVER"
                    sendto(sock, message.cstr, message.length.toULong(), 0, destAddr.ptr.reinterpret(), sizeOf<sockaddr_in>().toUInt())

                    val buffer = ByteArray(4096)
                    val fromAddr = alloc<sockaddr_in>()
                    val fromLen = alloc<UIntVar>()
                    fromLen.value = sizeOf<sockaddr_in>().toUInt()

                    buffer.usePinned { pinned ->
                        val received = recvfrom(sock, pinned.addressOf(0), buffer.size.toULong(), 0, fromAddr.ptr.reinterpret(), fromLen.ptr)
                        if (received > 0) {
                            val responseStr = buffer.decodeToString(0, received.toInt())
                            val server = parseResponse(responseStr)
                            if (server != null) servers.add(server)
                        }
                    }
                }

                close(sock)
            } catch (_: Exception) { }

            servers
        }
    }

    private fun hostToNetworkShort(value: UShort): UShort {
        val v = value.toInt()
        return (((v and 0xFF) shl 8) or ((v shr 8) and 0xFF)).toUShort()
    }

    private fun parseIpAddress(ip: String): UInt {
        val parts = ip.split(".")
        if (parts.size != 4) return 0u
        return parts[0].toUInt() or
                (parts[1].toUInt() shl 8) or
                (parts[2].toUInt() shl 16) or
                (parts[3].toUInt() shl 24)
    }

    private fun parseResponse(response: String): DiscoveredServer? {
        return try {
            val parsed = json.decodeFromString<DiscoveryResponse>(response)
            if (parsed.magic == "OPENFLIX_SERVER" && parsed.server != null) parsed.server else null
        } catch (_: Exception) { null }
    }
}

// NSNetServiceBrowser delegate
private class BonjourBrowserDelegate(
    private val onServiceFound: (NSNetService) -> Unit,
    private val onStopped: () -> Unit
) : NSObject(), NSNetServiceBrowserDelegateProtocol {

    override fun netServiceBrowser(browser: NSNetServiceBrowser, didFindService: NSNetService, moreComing: Boolean) {
        onServiceFound(didFindService)
    }

    override fun netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch: Map<Any?, *>) {
        onStopped()
    }

    override fun netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        onStopped()
    }
}

// NSNetService resolve delegate
private class BonjourResolveDelegate(
    private val onResolved: (host: String, port: Int, txtRecords: Map<String, String>) -> Unit,
    private val onFailed: () -> Unit
) : NSObject(), NSNetServiceDelegateProtocol {

    override fun netServiceDidResolveAddress(sender: NSNetService) {
        val host = sender.hostName ?: ""
        val port = sender.port.toInt()

        // Parse TXT record data
        val txtRecords = mutableMapOf<String, String>()
        val txtData = sender.TXTRecordData()
        if (txtData != null) {
            val dict = NSNetService.dictionaryFromTXTRecordData(txtData)
            for ((key, value) in dict) {
                val keyStr = key as? String ?: continue
                val valueData = value as? NSData ?: continue
                val valueStr = NSString.create(data = valueData, encoding = NSUTF8StringEncoding) as? String ?: ""
                txtRecords[keyStr] = valueStr
            }
        }

        onResolved(host, port, txtRecords)
    }

    override fun netService(sender: NSNetService, didNotResolve: Map<Any?, *>) {
        onFailed()
    }
}
