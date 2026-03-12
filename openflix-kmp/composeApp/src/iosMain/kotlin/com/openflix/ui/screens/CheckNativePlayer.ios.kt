package com.openflix.ui.screens

import com.openflix.ui.player.NativeVideoPlayer

actual fun checkNativePlayerDismissed(): Boolean = NativeVideoPlayer.checkIfDismissed()
