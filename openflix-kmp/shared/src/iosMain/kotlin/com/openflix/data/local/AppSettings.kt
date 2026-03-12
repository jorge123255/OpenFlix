package com.openflix.data.local

import platform.Foundation.NSUserDefaults

actual class AppSettings {
    private val defaults = NSUserDefaults.standardUserDefaults

    actual fun saveServerUrl(url: String) {
        defaults.setObject(url, forKey = KEY_SERVER_URL)
    }

    actual fun getServerUrl(): String? = defaults.stringForKey(KEY_SERVER_URL)

    actual fun clearServerUrl() {
        defaults.removeObjectForKey(KEY_SERVER_URL)
    }

    actual fun saveAuthToken(token: String) {
        defaults.setObject(token, forKey = KEY_AUTH_TOKEN)
    }

    actual fun getAuthToken(): String? = defaults.stringForKey(KEY_AUTH_TOKEN)

    actual fun clearAuthToken() {
        defaults.removeObjectForKey(KEY_AUTH_TOKEN)
    }

    actual fun clearAll() {
        defaults.removeObjectForKey(KEY_SERVER_URL)
        defaults.removeObjectForKey(KEY_AUTH_TOKEN)
    }

    actual companion object {
        private const val KEY_SERVER_URL = "openflix_server_url"
        private const val KEY_AUTH_TOKEN = "openflix_auth_token"

        actual fun init(context: Any) {
            // No-op on iOS — NSUserDefaults doesn't need context
        }
    }
}
