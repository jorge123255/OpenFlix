package com.openflix.data.remote.api

import com.openflix.data.local.PreferencesManager
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.Interceptor
import okhttp3.Response
import timber.log.Timber

/**
 * OkHttp interceptor that:
 * 1. Rewrites the base URL to use the configured server
 * 2. Adds authentication headers to all requests
 */
class AuthInterceptor(
    private val preferencesManager: PreferencesManager
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()

        // Get current server URL and auth token
        val (serverUrl, token) = runBlocking {
            Pair(
                preferencesManager.serverUrl.first(),
                preferencesManager.authToken.first()
            )
        }

        // Build new request with proper server URL
        var requestBuilder = originalRequest.newBuilder()
            .header("Accept", "application/json")

        // Rewrite URL if server is configured
        if (!serverUrl.isNullOrBlank()) {
            val serverBaseUrl = serverUrl.toHttpUrlOrNull()
            if (serverBaseUrl != null) {
                val newUrl = originalRequest.url.newBuilder()
                    .scheme(serverBaseUrl.scheme)
                    .host(serverBaseUrl.host)
                    .port(serverBaseUrl.port)
                    .build()

                requestBuilder = requestBuilder.url(newUrl)
                Timber.d("Rewriting URL: ${originalRequest.url} -> $newUrl")
            }
        }

        // Add auth token if available
        if (!token.isNullOrBlank()) {
            requestBuilder = requestBuilder.header("Authorization", "Bearer $token")
        }

        return chain.proceed(requestBuilder.build())
    }
}
