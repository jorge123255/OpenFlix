package com.openflix.ui.screens

import com.openflix.ui.player.NativeLiveTVPlayer

actual fun checkLiveTVPlayerDismissed(): Boolean = NativeLiveTVPlayer.checkIfDismissed()
