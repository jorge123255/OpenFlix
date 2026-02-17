package com.openflix.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * DTO for remote access status response.
 */
data class RemoteAccessStatusDto(
    @SerializedName("enabled") val enabled: Boolean,
    @SerializedName("connected") val connected: Boolean,
    @SerializedName("method") val method: String?,
    @SerializedName("tailscale_ip") val tailscaleIp: String?,
    @SerializedName("tailscale_hostname") val tailscaleHostname: String?,
    @SerializedName("magic_dns_name") val magicDnsName: String?,
    @SerializedName("backend_state") val backendState: String?,
    @SerializedName("login_url") val loginUrl: String?,
    @SerializedName("last_seen") val lastSeen: Long?,
    @SerializedName("error") val error: String?
)

/**
 * DTO for connection info response.
 */
data class ConnectionInfoDto(
    @SerializedName("server_url") val serverUrl: String,
    @SerializedName("network_type") val networkType: String,
    @SerializedName("is_remote") val isRemote: Boolean,
    @SerializedName("suggested_quality") val suggestedQuality: String,
    @SerializedName("tailscale_available") val tailscaleAvailable: Boolean?
)

/**
 * DTO for enable/disable response.
 */
data class RemoteAccessActionResponse(
    @SerializedName("success") val success: Boolean,
    @SerializedName("message") val message: String?,
    @SerializedName("login_url") val loginUrl: String?,
    @SerializedName("status") val status: RemoteAccessStatusDto?
)

/**
 * DTO for health check response.
 */
data class RemoteAccessHealthDto(
    @SerializedName("healthy") val healthy: Boolean,
    @SerializedName("checks") val checks: Map<String, Boolean>?,
    @SerializedName("warnings") val warnings: List<String>?
)

/**
 * DTO for install info response.
 */
data class TailscaleInstallInfoDto(
    @SerializedName("is_installed") val isInstalled: Boolean,
    @SerializedName("current_version") val currentVersion: String?,
    @SerializedName("install_command") val installCommand: String?,
    @SerializedName("configure_command") val configureCommand: String?,
    @SerializedName("doc_url") val docUrl: String?
)

/**
 * DTO for login URL response.
 */
data class TailscaleLoginUrlDto(
    @SerializedName("url") val url: String?,
    @SerializedName("expires_at") val expiresAt: Long?
)

// === Instant Switch DTOs ===

/**
 * DTO for instant switch status response.
 */
data class InstantSwitchStatusDto(
    @SerializedName("success") val success: Boolean,
    @SerializedName("data") val data: InstantSwitchDataDto?
)

data class InstantSwitchDataDto(
    @SerializedName("enabled") val enabled: Boolean,
    @SerializedName("active_channel") val activeChannel: String?,
    @SerializedName("cached_streams") val cachedStreams: Int,
    @SerializedName("total_memory_mb") val totalMemoryMB: Int,
    @SerializedName("recent_channels") val recentChannels: List<String>?
)

/**
 * Request to enable/disable instant switch.
 */
data class InstantSwitchEnabledRequest(
    @SerializedName("enabled") val enabled: Boolean
)

/**
 * Response for enable/disable instant switch.
 */
data class InstantSwitchEnabledResponse(
    @SerializedName("success") val success: Boolean,
    @SerializedName("enabled") val enabled: Boolean,
    @SerializedName("message") val message: String?
)

/**
 * DTO for cached streams response.
 */
data class CachedStreamsDto(
    @SerializedName("success") val success: Boolean,
    @SerializedName("cached") val cached: List<CachedStreamDto>?,
    @SerializedName("count") val count: Int
)

data class CachedStreamDto(
    @SerializedName("channel_id") val channelId: String,
    @SerializedName("buffered_bytes") val bufferedBytes: Int,
    @SerializedName("buffered_duration") val bufferedDuration: Double,
    @SerializedName("is_live") val isLive: Boolean,
    @SerializedName("last_access") val lastAccess: String?
)

/**
 * Request to set instant switch favorites.
 */
data class InstantSwitchFavoritesRequest(
    @SerializedName("favorites") val favorites: List<String>
)

// Type aliases for API compatibility
typealias RemoteAccessInstallInfoDto = TailscaleInstallInfoDto
typealias RemoteAccessLoginUrlDto = TailscaleLoginUrlDto

/**
 * DTO for remote streaming quality response.
 */
data class RemoteStreamingQualityDto(
    @SerializedName("quality") val quality: String,
    @SerializedName("available_qualities") val availableQualities: List<String>?
)

/**
 * Request to set remote streaming quality.
 */
data class SetStreamingQualityRequest(
    @SerializedName("quality") val quality: String
)
