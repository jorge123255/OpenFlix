package com.openflix.data.dto

import com.openflix.domain.model.Profile
import com.openflix.domain.model.ServerCapabilities
import com.openflix.domain.model.ServerInfo
import com.openflix.domain.model.User
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class AuthResponse(
    val token: String,
    val user: UserDTO,
    val expiresAt: Int? = null
)

@Serializable
data class UserDTO(
    val id: Int,
    val uuid: String? = null,
    val username: String,
    val email: String? = null,
    val title: String? = null,
    val thumb: String? = null,
    val admin: Boolean? = null,
    val createdAt: String? = null,
    val updatedAt: String? = null
) {
    fun toDomain() = User(
        id = id,
        uuid = uuid,
        username = username,
        email = email,
        displayName = title,
        avatar = thumb,
        isAdmin = admin ?: false
    )
}

@Serializable
data class ProfileDTO(
    val id: Int,
    val uuid: String,
    val name: String,
    val avatar: String? = null,
    val thumb: String? = null,
    val isKid: Boolean? = null,
    val hasPassword: Boolean? = null,
    val restricted: Boolean? = null,
    val admin: Boolean? = null,
    val guest: Boolean? = null,
    val protected: Boolean? = null
) {
    fun toDomain() = Profile(
        id = id,
        uuid = uuid,
        name = name,
        avatar = avatar ?: thumb,
        isKid = isKid ?: false,
        isProtected = protected ?: hasPassword ?: false,
        isAdmin = admin ?: false,
        isGuest = guest ?: false,
        isRestricted = restricted ?: false
    )
}

@Serializable
data class HomeUsersResponse(
    val id: Int? = null,
    val name: String? = null,
    val users: List<HomeUserDTO> = emptyList()
)

@Serializable
data class HomeUserDTO(
    val id: Int? = null,
    val uuid: String,
    val title: String,
    val username: String? = null,
    val thumb: String? = null,
    val hasPassword: Boolean? = null,
    val restricted: Boolean? = null,
    val admin: Boolean? = null,
    val guest: Boolean? = null,
    val protected: Boolean? = null
) {
    fun toDomain() = Profile(
        id = 0,
        uuid = uuid,
        name = title,
        avatar = thumb,
        isKid = false,
        isProtected = protected ?: false,
        isAdmin = admin ?: false,
        isGuest = guest ?: false,
        isRestricted = restricted ?: false
    )
}

@Serializable
data class SwitchProfileResponse(
    val authToken: String? = null,
    val token: String? = null,
    val success: Boolean? = null,
    val message: String? = null
)

@Serializable
data class ServerInfoDTO(
    val name: String? = null,
    val version: String? = null,
    val platform: String? = null,
    val machineIdentifier: String? = null,
    val owner: Boolean? = null,
    @SerialName("transcoder_active") val transcoderActive: Boolean? = null
) {
    fun toDomain() = ServerInfo(
        name = name ?: "OpenFlix Server",
        version = version ?: "Unknown",
        platform = platform ?: "Unknown",
        machineIdentifier = machineIdentifier ?: "",
        isOwner = owner ?: false,
        transcoderActive = transcoderActive ?: false
    )
}

@Serializable
data class ServerCapabilitiesDTO(
    @SerialName("live_tv") val liveTV: Boolean? = null,
    val dvr: Boolean? = null,
    val transcoding: Boolean? = null,
    @SerialName("offline_downloads") val offlineDownloads: Boolean? = null,
    @SerialName("multi_user") val multiUser: Boolean? = null,
    @SerialName("watch_party") val watchParty: Boolean? = null,
    @SerialName("epg_sources") val epgSources: List<String>? = null
) {
    fun toDomain() = ServerCapabilities(
        liveTV = liveTV ?: false,
        dvr = dvr ?: false,
        transcoding = transcoding ?: false,
        offlineDownloads = offlineDownloads ?: false,
        multiUser = multiUser ?: false,
        watchParty = watchParty ?: false,
        epgSources = epgSources ?: emptyList()
    )
}
