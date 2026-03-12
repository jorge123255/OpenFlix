package com.openflix.ui

import androidx.compose.ui.window.ComposeUIViewController
import com.openflix.di.initKoin
import com.openflix.ui.di.playerModule
import com.openflix.ui.di.viewModelModule

fun MainViewController() = ComposeUIViewController(
    configure = {
        initKoin(extraModules = listOf(viewModelModule, playerModule))
    }
) {
    App()
}
