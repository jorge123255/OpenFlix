package com.openflix.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Source management DTOs for M3U and Xtream sources
 */

// === M3U Source DTOs ===

data class M3USourceDto(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("url") val url: String,
    @SerializedName("epgUrl") val epgUrl: String?,
    @SerializedName("enabled") val enabled: Boolean,
    @SerializedName("lastFetched") val lastFetched: String?,
    @SerializedName("importVod") val importVod: Boolean,
    @SerializedName("importSeries") val importSeries: Boolean,
    @SerializedName("vodLibraryId") val vodLibraryId: Int?,
    @SerializedName("seriesLibraryId") val seriesLibraryId: Int?,
    @SerializedName("createdAt") val createdAt: String?
) {
    // Computed channel count from response
    var channelCount: Int = 0
    var vodCount: Int = 0
    var seriesCount: Int = 0
}

data class M3USourcesResponse(
    @SerializedName("sources") val sources: List<M3USourceDto>
)

data class CreateM3USourceRequest(
    @SerializedName("name") val name: String,
    @SerializedName("url") val url: String,
    @SerializedName("epgUrl") val epgUrl: String? = null
)

data class UpdateM3USourceRequest(
    @SerializedName("name") val name: String? = null,
    @SerializedName("url") val url: String? = null,
    @SerializedName("epgUrl") val epgUrl: String? = null,
    @SerializedName("enabled") val enabled: Boolean? = null,
    @SerializedName("importVod") val importVod: Boolean? = null,
    @SerializedName("importSeries") val importSeries: Boolean? = null,
    @SerializedName("vodLibraryId") val vodLibraryId: Int? = null,
    @SerializedName("seriesLibraryId") val seriesLibraryId: Int? = null
)

// === Xtream Source DTOs ===

data class XtreamSourceDto(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("serverUrl") val serverUrl: String,
    @SerializedName("username") val username: String,
    // Password is omitted from responses for security
    @SerializedName("enabled") val enabled: Boolean,
    @SerializedName("importLive") val importLive: Boolean,
    @SerializedName("importVod") val importVod: Boolean,
    @SerializedName("importSeries") val importSeries: Boolean,
    @SerializedName("vodLibraryId") val vodLibraryId: Int?,
    @SerializedName("seriesLibraryId") val seriesLibraryId: Int?,
    @SerializedName("channelCount") val channelCount: Int,
    @SerializedName("vodCount") val vodCount: Int,
    @SerializedName("seriesCount") val seriesCount: Int,
    @SerializedName("lastFetched") val lastFetched: String?,
    @SerializedName("expirationDate") val expirationDate: String?,
    @SerializedName("createdAt") val createdAt: String?
)

data class XtreamSourcesResponse(
    @SerializedName("sources") val sources: List<XtreamSourceDto>
)

data class CreateXtreamSourceRequest(
    @SerializedName("name") val name: String,
    @SerializedName("serverUrl") val serverUrl: String,
    @SerializedName("username") val username: String,
    @SerializedName("password") val password: String,
    @SerializedName("importLive") val importLive: Boolean = true,
    @SerializedName("importVod") val importVod: Boolean = false,
    @SerializedName("importSeries") val importSeries: Boolean = false,
    @SerializedName("vodLibraryId") val vodLibraryId: Int? = null,
    @SerializedName("seriesLibraryId") val seriesLibraryId: Int? = null
)

data class UpdateXtreamSourceRequest(
    @SerializedName("name") val name: String? = null,
    @SerializedName("serverUrl") val serverUrl: String? = null,
    @SerializedName("username") val username: String? = null,
    @SerializedName("password") val password: String? = null,
    @SerializedName("enabled") val enabled: Boolean? = null,
    @SerializedName("importLive") val importLive: Boolean? = null,
    @SerializedName("importVod") val importVod: Boolean? = null,
    @SerializedName("importSeries") val importSeries: Boolean? = null,
    @SerializedName("vodLibraryId") val vodLibraryId: Int? = null,
    @SerializedName("seriesLibraryId") val seriesLibraryId: Int? = null
)

// === Common DTOs ===

data class TestSourceResponse(
    @SerializedName("success") val success: Boolean,
    @SerializedName("message") val message: String?,
    @SerializedName("serverInfo") val serverInfo: XtreamServerInfo?
)

data class XtreamServerInfo(
    @SerializedName("url") val url: String?,
    @SerializedName("port") val port: String?,
    @SerializedName("https_port") val httpsPort: String?,
    @SerializedName("server_protocol") val serverProtocol: String?,
    @SerializedName("timezone") val timezone: String?,
    @SerializedName("active_cons") val activeConnections: String?,
    @SerializedName("max_connections") val maxConnections: String?,
    @SerializedName("exp_date") val expirationDate: String?,
    @SerializedName("created_at") val createdAt: String?,
    @SerializedName("is_trial") val isTrial: String?,
    @SerializedName("username") val username: String?,
    @SerializedName("status") val status: String?
)

data class ImportResultDto(
    @SerializedName("added") val added: Int,
    @SerializedName("updated") val updated: Int,
    @SerializedName("skipped") val skipped: Int,
    @SerializedName("errors") val errors: Int,
    @SerializedName("total") val total: Int,
    @SerializedName("duration") val duration: String?
)

data class ImportStatusDto(
    @SerializedName("status") val status: String,
    @SerializedName("message") val message: String
)
