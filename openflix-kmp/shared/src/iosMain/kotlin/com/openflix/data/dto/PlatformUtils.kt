package com.openflix.data.dto

import platform.Foundation.NSISO8601DateFormatter
import platform.Foundation.NSUUID
import platform.Foundation.timeIntervalSince1970

internal actual fun parseIso8601(value: String): Long? {
    val formatter = NSISO8601DateFormatter()
    val date = formatter.dateFromString(value) ?: return null
    return (date.timeIntervalSince1970 * 1000).toLong()
}

internal actual fun generateUuid(): String = NSUUID().UUIDString()
