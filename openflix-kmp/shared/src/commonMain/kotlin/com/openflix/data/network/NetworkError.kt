package com.openflix.data.network

sealed class NetworkError : Exception() {
    data object InvalidURL : NetworkError()
    data object NoData : NetworkError()
    data class DecodingError(val reason: Throwable) : NetworkError()
    data class ServerError(val code: Int, val body: String?) : NetworkError()
    data object Unauthorized : NetworkError()
    data object NotFound : NetworkError()
    data object RateLimited : NetworkError()
    data object NetworkUnavailable : NetworkError()
    data object Timeout : NetworkError()
    data class Unknown(val reason: Throwable) : NetworkError()

    override val message: String get() = when (this) {
        is InvalidURL -> "Invalid server URL"
        is NoData -> "No data received from server"
        is DecodingError -> "Failed to parse response: ${reason.message}"
        is ServerError -> body ?: "Server error (code: $code)"
        is Unauthorized -> "Authentication required"
        is NotFound -> "Resource not found"
        is RateLimited -> "Too many requests. Please wait and try again."
        is NetworkUnavailable -> "Network unavailable"
        is Timeout -> "Request timed out"
        is Unknown -> reason.message ?: "Unknown error"
    }

    val isAuthError: Boolean get() = this is Unauthorized
}
