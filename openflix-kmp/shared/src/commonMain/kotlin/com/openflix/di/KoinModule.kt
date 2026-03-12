package com.openflix.di

import com.openflix.data.local.AppSettings
import com.openflix.data.network.OpenFlixApi
import com.openflix.data.repository.*
import org.koin.core.KoinApplication
import org.koin.core.context.startKoin
import org.koin.core.module.Module
import org.koin.dsl.module

val sharedModule = module {
    // Local storage
    single { AppSettings() }

    // Network
    single { OpenFlixApi() }

    // Repositories
    single { AuthRepository(get()) }
    single { LiveTVRepository(get()) }
    single { MediaRepository(get()) }
    single { DVRRepository(get()) }
    single { WatchlistRepository(get()) }
}

fun initKoin(extraModules: List<Module> = emptyList(), appConfig: KoinApplication.() -> Unit = {}) {
    startKoin {
        appConfig()
        modules(sharedModule + extraModules)
    }
}
