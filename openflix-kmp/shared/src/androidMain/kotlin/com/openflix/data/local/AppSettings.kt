package com.openflix.data.local

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences

actual class AppSettings {
    private val prefs: SharedPreferences?
        get() = appContext?.getSharedPreferences("openflix_settings", Context.MODE_PRIVATE)

    actual fun saveServerUrl(url: String) {
        prefs?.edit()?.putString(KEY_SERVER_URL, url)?.apply()
    }

    actual fun getServerUrl(): String? = prefs?.getString(KEY_SERVER_URL, null)

    actual fun clearServerUrl() {
        prefs?.edit()?.remove(KEY_SERVER_URL)?.apply()
    }

    actual fun saveAuthToken(token: String) {
        prefs?.edit()?.putString(KEY_AUTH_TOKEN, token)?.apply()
    }

    actual fun getAuthToken(): String? = prefs?.getString(KEY_AUTH_TOKEN, null)

    actual fun clearAuthToken() {
        prefs?.edit()?.remove(KEY_AUTH_TOKEN)?.apply()
    }

    actual fun clearAll() {
        prefs?.edit()?.clear()?.apply()
    }

    actual companion object {
        @SuppressLint("StaticFieldLeak")
        private var appContext: Context? = null

        private const val KEY_SERVER_URL = "server_url"
        private const val KEY_AUTH_TOKEN = "auth_token"

        actual fun init(context: Any) {
            appContext = (context as Context).applicationContext
        }
    }
}
