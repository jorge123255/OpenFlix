package com.openflix.util

import android.app.UiModeManager
import android.content.Context
import android.content.res.Configuration
import androidx.compose.runtime.compositionLocalOf

enum class DeviceType {
    TV,
    TABLET,
    PHONE;

    val isTV: Boolean get() = this == TV
    val isTabletOrPhone: Boolean get() = this == TABLET || this == PHONE
}

val LocalDeviceType = compositionLocalOf { DeviceType.TV }

fun detectDeviceType(context: Context): DeviceType {
    val uiModeManager = context.getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
    if (uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION) {
        return DeviceType.TV
    }

    val config = context.resources.configuration
    val smallestWidthDp = config.smallestScreenWidthDp
    return if (smallestWidthDp >= 600) DeviceType.TABLET else DeviceType.PHONE
}
