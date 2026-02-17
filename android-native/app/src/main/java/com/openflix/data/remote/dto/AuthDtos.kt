package com.openflix.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Authentication-related DTOs
 */

data class RegisterRequest(
    @SerializedName("username") val username: String,
    @SerializedName("password") val password: String,
    @SerializedName("email") val email: String? = null
)

data class LoginRequest(
    @SerializedName("username") val username: String,
    @SerializedName("password") val password: String
)

data class AuthResponse(
    @SerializedName("token") val token: String,
    @SerializedName("user") val user: UserDto,
    @SerializedName("expires_at") val expiresAt: Long? = null
)

data class UserDto(
    @SerializedName("id") val id: Int,
    @SerializedName("uuid") val uuid: String,
    @SerializedName("username") val username: String,
    @SerializedName("email") val email: String?,
    @SerializedName("is_admin") val isAdmin: Boolean,
    @SerializedName("avatar") val avatar: String?,
    @SerializedName("created_at") val createdAt: String?,
    @SerializedName("updated_at") val updatedAt: String?
)

data class UpdateUserRequest(
    @SerializedName("username") val username: String? = null,
    @SerializedName("email") val email: String? = null,
    @SerializedName("avatar") val avatar: String? = null
)

data class ChangePasswordRequest(
    @SerializedName("current_password") val currentPassword: String,
    @SerializedName("new_password") val newPassword: String
)

/**
 * Home users response - list of profiles/users available
 */
data class HomeUsersResponse(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("users") val users: List<HomeUserDto>
)

data class HomeUserDto(
    @SerializedName("id") val id: Int,
    @SerializedName("uuid") val uuid: String,
    @SerializedName("title") val title: String,
    @SerializedName("username") val username: String?,
    @SerializedName("thumb") val thumb: String?,
    @SerializedName("hasPassword") val hasPassword: Boolean,
    @SerializedName("restricted") val restricted: Boolean,
    @SerializedName("admin") val admin: Boolean,
    @SerializedName("guest") val guest: Boolean,
    @SerializedName("protected") val protected: Boolean
)

data class SwitchUserResponse(
    @SerializedName("authToken") val authToken: String
)
