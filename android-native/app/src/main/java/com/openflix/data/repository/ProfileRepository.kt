package com.openflix.data.repository

import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.dto.HomeUserDto
import com.openflix.domain.model.Profile
import kotlinx.coroutines.flow.first
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for profile/user operations.
 */
@Singleton
class ProfileRepository @Inject constructor(
    private val api: OpenFlixApi,
    private val preferencesManager: PreferencesManager
) {

    private suspend fun getServerBaseUrl(): String {
        return preferencesManager.serverUrl.first() ?: "http://127.0.0.1:32400"
    }

    private fun buildFullUrl(baseUrl: String, path: String?): String? {
        if (path == null) return null
        if (path.startsWith("http://") || path.startsWith("https://")) {
            return path
        }
        return baseUrl.trimEnd('/') + path
    }

    /**
     * Get all available profiles/users
     */
    suspend fun getProfiles(): Result<List<Profile>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getHomeUsers()
            if (response.isSuccessful && response.body() != null) {
                val profiles = response.body()!!.users.map { it.toDomain(baseUrl) }
                Timber.d("Loaded ${profiles.size} profiles")
                Result.success(profiles)
            } else {
                Timber.w("Failed to get profiles: ${response.code()}")
                Result.failure(Exception("Failed to get profiles: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting profiles")
            Result.failure(e)
        }
    }

    /**
     * Switch to a different profile
     */
    suspend fun switchProfile(userUuid: String, pin: String? = null): Result<String> {
        return try {
            val response = api.switchUser(userUuid, pin)
            if (response.isSuccessful && response.body() != null) {
                val token = response.body()!!.authToken
                Timber.d("Switched to profile: $userUuid")

                // Store the new token
                preferencesManager.setAuthToken(token)

                Result.success(token)
            } else if (response.code() == 401) {
                Timber.w("PIN required for profile switch")
                Result.failure(PinRequiredException())
            } else {
                Timber.w("Failed to switch profile: ${response.code()}")
                Result.failure(Exception("Failed to switch profile: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error switching profile: $userUuid")
            Result.failure(e)
        }
    }

    /**
     * Get current profile from token/session
     */
    suspend fun getCurrentProfile(): Result<Profile?> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getCurrentUser()
            if (response.isSuccessful && response.body() != null) {
                val user = response.body()!!
                val profile = Profile(
                    id = user.id,
                    uuid = user.uuid,
                    name = user.username,
                    thumb = buildFullUrl(baseUrl, user.avatar),
                    isAdmin = user.isAdmin,
                    hasPassword = false,
                    isRestricted = false,
                    isGuest = false
                )
                Result.success(profile)
            } else {
                Result.success(null)
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting current profile")
            Result.failure(e)
        }
    }

    private fun HomeUserDto.toDomain(baseUrl: String) = Profile(
        id = id,
        uuid = uuid,
        name = title,
        thumb = buildFullUrl(baseUrl, thumb),
        isAdmin = admin,
        hasPassword = hasPassword,
        isRestricted = restricted,
        isGuest = guest
    )
}

/**
 * Exception thrown when a PIN is required for profile switch
 */
class PinRequiredException : Exception("PIN required")
