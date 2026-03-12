package com.openflix.domain.model

data class M3USource(
    val id: Int,
    val name: String,
    val url: String,
    val epgUrl: String? = null,
    val enabled: Boolean = true,
    val lastFetched: Long? = null,
    val importVod: Boolean = false,
    val importSeries: Boolean = false,
    val vodLibraryId: Int? = null,
    val seriesLibraryId: Int? = null,
    val channelCount: Int = 0
)

data class XtreamSource(
    val id: Int,
    val name: String,
    val serverUrl: String,
    val username: String,
    val enabled: Boolean = true,
    val importLive: Boolean = true,
    val importVod: Boolean = false,
    val importSeries: Boolean = false,
    val vodLibraryId: Int? = null,
    val seriesLibraryId: Int? = null,
    val channelCount: Int = 0,
    val vodCount: Int = 0,
    val seriesCount: Int = 0,
    val lastFetched: Long? = null,
    val expirationDate: Long? = null,
    val createdAt: Long? = null
) {
    val isExpired: Boolean get() {
        val exp = expirationDate ?: return false
        return exp < currentTimeMs()
    }
}

data class EPGSource(
    val id: Int,
    val name: String,
    val url: String,
    val type: EPGSourceType,
    val enabled: Boolean = true,
    val lastFetched: Long? = null,
    val channelCount: Int = 0,
    val programCount: Int = 0
)

enum class EPGSourceType(val value: String) {
    XMLTV("xmltv"),
    GRACENOTE("gracenote");

    val displayName: String get() = when (this) {
        XMLTV -> "XMLTV"
        GRACENOTE -> "Gracenote"
    }

    companion object {
        fun fromValue(value: String): EPGSourceType =
            entries.firstOrNull { it.value == value } ?: XMLTV
    }
}

data class ServerCapabilities(
    val liveTV: Boolean = false,
    val dvr: Boolean = false,
    val transcoding: Boolean = false,
    val offlineDownloads: Boolean = false,
    val multiUser: Boolean = false,
    val watchParty: Boolean = false,
    val epgSources: List<String> = emptyList()
)

data class ServerInfo(
    val name: String,
    val version: String,
    val platform: String,
    val machineIdentifier: String,
    val isOwner: Boolean = false,
    val transcoderActive: Boolean = false
)
