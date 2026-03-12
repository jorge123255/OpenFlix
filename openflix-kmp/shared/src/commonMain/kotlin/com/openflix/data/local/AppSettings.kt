package com.openflix.data.local

/**
 * Platform-specific persistent settings storage.
 * Android: SharedPreferences, iOS: NSUserDefaults.
 */
expect class AppSettings() {
    fun saveServerUrl(url: String)
    fun getServerUrl(): String?
    fun clearServerUrl()

    fun saveAuthToken(token: String)
    fun getAuthToken(): String?
    fun clearAuthToken()

    fun clearAll()

    companion object {
        /** Android-only: call from Application.onCreate() with app context */
        fun init(context: Any)
    }
}
