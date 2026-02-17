package com.openflix.domain.model

/**
 * Remote access status from server (Tailscale integration).
 */
data class RemoteAccessStatus(
    val enabled: Boolean,
    val connected: Boolean,
    val method: String = "tailscale", // tailscale, cloudflare, manual
    val tailscaleIp: String? = null,
    val tailscaleHostname: String? = null,
    val magicDnsName: String? = null,
    val backendState: String? = null, // Running, Stopped, NeedsLogin, etc.
    val loginUrl: String? = null,
    val lastSeen: Long? = null,
    val error: String? = null
)

/**
 * Connection info for determining best URL to use.
 */
data class ConnectionInfo(
    val serverUrl: String,
    val networkType: NetworkType,
    val isRemote: Boolean,
    val suggestedQuality: RemoteStreamingQuality,
    val tailscaleAvailable: Boolean = false
)

/**
 * Network connection type.
 */
enum class NetworkType {
    WIFI,
    ETHERNET,
    CELLULAR,
    VPN,
    UNKNOWN;

    val isMetered: Boolean
        get() = this == CELLULAR

    val displayName: String
        get() = when (this) {
            WIFI -> "Wi-Fi"
            ETHERNET -> "Ethernet"
            CELLULAR -> "Cellular"
            VPN -> "VPN"
            UNKNOWN -> "Unknown"
        }
}

/**
 * Quality presets for remote streaming.
 */
enum class RemoteStreamingQuality(
    val displayName: String,
    val maxBitrate: Int, // kbps
    val maxResolution: String
) {
    ORIGINAL("Original", Int.MAX_VALUE, "original"),
    QUALITY_1080P("1080p (8 Mbps)", 8000, "1080"),
    QUALITY_720P("720p (4 Mbps)", 4000, "720"),
    QUALITY_480P("480p (2 Mbps)", 2000, "480"),
    QUALITY_360P("360p (1 Mbps)", 1000, "360"),
    AUTO("Auto (Adaptive)", 0, "auto");

    companion object {
        fun fromString(value: String): RemoteStreamingQuality {
            return entries.find { it.name == value || it.maxResolution == value }
                ?: AUTO
        }

        fun suggestedFor(networkType: NetworkType): RemoteStreamingQuality {
            return when (networkType) {
                NetworkType.WIFI, NetworkType.ETHERNET -> ORIGINAL
                NetworkType.VPN -> QUALITY_720P
                NetworkType.CELLULAR -> QUALITY_480P
                NetworkType.UNKNOWN -> AUTO
            }
        }
    }
}

/**
 * Server connection state for UI.
 */
data class ServerConnection(
    val isConnected: Boolean,
    val isLocal: Boolean,
    val activeUrl: String,
    val networkType: NetworkType,
    val streamingQuality: RemoteStreamingQuality,
    val tailscaleStatus: TailscaleStatus? = null
)

/**
 * Tailscale-specific status for admin UI.
 */
data class TailscaleStatus(
    val backendState: String,
    val selfNodeIp: String?,
    val hostname: String?,
    val magicDnsName: String?,
    val loginUrl: String? = null,
    val version: String? = null
)

/**
 * Tailscale health check response.
 */
data class TailscaleHealth(
    val healthy: Boolean,
    val checks: Map<String, Boolean> = emptyMap(),
    val warnings: List<String> = emptyList()
)

/**
 * Install info for setting up Tailscale.
 */
data class TailscaleInstallInfo(
    val isInstalled: Boolean,
    val currentVersion: String? = null,
    val installCommand: String,
    val configureCommand: String,
    val docUrl: String
)
