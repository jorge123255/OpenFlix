package com.openflix.ui.di

import com.openflix.ui.player.PlatformPlayer
import org.koin.android.ext.koin.androidContext
import org.koin.dsl.module

actual val playerModule = module {
    factory { PlatformPlayer(androidContext()) }
}
