package com.openflix.domain.model

/**
 * User and profile domain models
 */

data class User(
    val id: Int,
    val uuid: String,
    val username: String,
    val email: String?,
    val isAdmin: Boolean,
    val avatar: String?
)

data class Profile(
    val id: Int,
    val uuid: String,
    val name: String,
    val thumb: String?,
    val isAdmin: Boolean = false,
    val hasPassword: Boolean = false,
    val isRestricted: Boolean = false,
    val isGuest: Boolean = false,
    val isKid: Boolean = false
)

data class ServerInfo(
    val name: String?,
    val version: String?,
    val platform: String?,
    val machineIdentifier: String?,
    val isOwner: Boolean
)

data class ServerCapabilities(
    val liveTV: Boolean,
    val dvr: Boolean,
    val transcoding: Boolean,
    val offlineDownloads: Boolean,
    val multiUser: Boolean,
    val watchParty: Boolean,
    val epgSources: List<String>
)

data class WatchStats(
    val totalWatchTime: Long,  // minutes
    val moviesWatched: Int,
    val episodesWatched: Int,
    val topGenres: List<GenreStat>,
    val weeklyActivity: List<DayActivity>
)

data class GenreStat(
    val genre: String,
    val count: Int,
    val percentage: Float
)

data class DayActivity(
    val day: String,  // "Mon", "Tue", etc.
    val watchTime: Long  // minutes
)

data class WatchlistItem(
    val mediaId: String,
    val title: String,
    val thumb: String?,
    val type: MediaType,
    val addedAt: Long
)

data class DownloadItem(
    val id: String,
    val mediaId: String,
    val title: String,
    val thumb: String?,
    val type: MediaType,
    val status: DownloadStatus,
    val progress: Float,  // 0.0 to 1.0
    val fileSize: Long?,
    val downloadedSize: Long?,
    val filePath: String?
)

enum class DownloadStatus {
    PENDING,
    DOWNLOADING,
    PAUSED,
    COMPLETED,
    FAILED
}
