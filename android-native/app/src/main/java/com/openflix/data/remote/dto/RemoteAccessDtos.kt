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
