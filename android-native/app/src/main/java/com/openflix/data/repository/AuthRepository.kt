package com.openflix.data.repository

import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.dto.AuthResponse
import com.openflix.data.remote.dto.LoginRequest
import com.openflix.data.remote.dto.RegisterRequest
import com.openflix.data.remote.dto.UserDto
import com.openflix.domain.model.User
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for authentication operations.
 */
@Singleton
class AuthRepository @Inject constructor(
    private val api: OpenFlixApi,
    private val preferencesManager: PreferencesManager
) {

    // Authenticated if we have a token OR we're in local access mode
    val isAuthenticated: Flow<Boolean> = kotlinx.coroutines.flow.combine(
        preferencesManager.authToken,
        preferencesManager.isLocalAccessMode
    ) { token, localAccess ->
        !token.isNullOrBlank() || localAccess
    }

    val currentUser: Flow<String?> = preferencesManager.currentUserId

    val isLocalAccess: Flow<Boolean> = preferencesManager.isLocalAccessMode

    suspend fun login(username: String, password: String): Result<User> {
        return try {
            val response = api.login(LoginRequest(username, password))

            if (response.isSuccessful && response.body() != null) {
                val authResponse = response.body()!!
                if (authResponse.token.isBlank()) {
                    Timber.e("Login response missing auth token")
                    return Result.failure(Exception("Server returned empty auth token"))
                }
                saveAuthData(authResponse)
                Timber.d("Login successful for user: $username")
                Result.success(authResponse.user.toDomain())
            } else {
                val errorMsg = response.errorBody()?.string() ?: "Login failed"
                Timber.e("Login failed: $errorMsg")
                Result.failure(Exception(errorMsg))
            }
        } catch (e: Exception) {
            Timber.e(e, "Login error")
            Result.failure(e)
        }
    }

    suspend fun register(username: String, password: String, email: String?): Result<User> {
        return try {
            val response = api.register(RegisterRequest(username, password, email))

            if (response.isSuccessful && response.body() != null) {
                val authResponse = response.body()!!
                saveAuthData(authResponse)
                Timber.d("Registration successful for user: $username")
                Result.success(authResponse.user.toDomain())
            } else {
                val errorMsg = response.errorBody()?.string() ?: "Registration failed"
                Timber.e("Registration failed: $errorMsg")
                Result.failure(Exception(errorMsg))
            }
        } catch (e: Exception) {
            Timber.e(e, "Registration error")
            Result.failure(e)
        }
    }

    suspend fun logout(): Result<Unit> {
        return try {
            api.logout()
            clearAuthData()
            Timber.d("Logout successful")
            Result.success(Unit)
        } catch (e: Exception) {
            Timber.e(e, "Logout error")
            // Still clear local data even if server call fails
            clearAuthData()
            Result.failure(e)
        }
    }

    suspend fun getCurrentUser(): Result<User> {
        return try {
            val response = api.getCurrentUser()

            if (response.isSuccessful && response.body() != null) {
                val user = response.body()!!.toDomain()
                Result.success(user)
            } else {
                Result.failure(Exception("Failed to get current user"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Get current user error")
            Result.failure(e)
        }
    }

    suspend fun setServerUrl(url: String) {
        preferencesManager.setServerUrl(url)
    }

    suspend fun getServerUrl(): String? {
        return preferencesManager.serverUrl.first()
    }

    suspend fun getAuthToken(): String? {
        return preferencesManager.authToken.first()
    }

    /**
     * Enable local access mode (no login required on home network)
     */
    suspend fun setLocalAccessMode(enabled: Boolean) {
        preferencesManager.setLocalAccessMode(enabled)
        Timber.d("Local access mode: $enabled")
    }

    private suspend fun saveAuthData(authResponse: AuthResponse) {
        preferencesManager.setAuthToken(authResponse.token)
        preferencesManager.setCurrentUserId(authResponse.user.uuid)
    }

    private suspend fun clearAuthData() {
        preferencesManager.setAuthToken(null)
        preferencesManager.setCurrentUserId(null)
        preferencesManager.setCurrentProfileId(null)
    }

    private fun UserDto.toDomain(): User = User(
        id = id,
        uuid = uuid,
        username = username,
        email = email,
        isAdmin = isAdmin,
        avatar = avatar
    )
}
