package com.openflix.ui.util

import androidx.compose.runtime.Composable

@Composable
actual fun PlatformBackHandler(enabled: Boolean, onBack: () -> Unit) {
    // iOS doesn't have a hardware Back button — no-op
}
