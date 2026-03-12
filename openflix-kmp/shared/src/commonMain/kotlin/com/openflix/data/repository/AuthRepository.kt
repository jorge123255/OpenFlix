package com.openflix.data.repository

import com.openflix.data.dto.AuthResponse
import com.openflix.data.network.OpenFlixApi
import com.openflix.domain.model.Profile
import com.openflix.domain.model.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class AuthRepository(private val api: OpenFlixApi) {
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()

    private val _currentProfile = MutableStateFlow<Profile?>(null)
    val currentProfile: StateFlow<Profile?> = _currentProfile.asStateFlow()

    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private var token: String? = null

    suspend fun login(username: String, password: String): AuthResponse {
        val response = api.login(username, password)
        token = response.token
        api.setToken(response.token)
        _currentUser.value = response.user.toDomain()
        _isAuthenticated.value = true
        return response
    }

    suspend fun logout() {
        try { api.logout() } catch (_: Exception) {}
        token = null
        api.setToken(null)
        _currentUser.value = null
        _currentProfile.value = null
        _isAuthenticated.value = false
    }

    suspend fun getUser(): User {
        val dto = api.getUser()
        val user = dto.toDomain()
        _currentUser.value = user
        return user
    }

    suspend fun getProfiles(): List<Profile> {
        return api.getProfiles().map { it.toDomain() }
    }

    suspend fun switchProfile(uuid: String, pin: String? = null): Boolean {
        val response = api.switchProfile(uuid, pin)
        val newToken = response.authToken ?: response.token
        if (newToken != null) {
            token = newToken
            api.setToken(newToken)
        }
        return response.success ?: (newToken != null)
    }

    fun restoreSession(serverUrl: String, savedToken: String) {
        api.configure(serverUrl, savedToken)
        token = savedToken
        _isAuthenticated.value = true
    }
}
