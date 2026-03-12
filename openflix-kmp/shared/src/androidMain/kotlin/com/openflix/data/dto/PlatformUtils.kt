package com.openflix.data.dto

import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.util.UUID

internal actual fun parseIso8601(value: String): Long? {
    return try {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        format.parse(value)?.time
    } catch (_: Exception) {
        try {
            val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssXXX", Locale.US)
            format.parse(value)?.time
        } catch (_: Exception) {
            null
        }
    }
}

internal actual fun generateUuid(): String = UUID.randomUUID().toString()
