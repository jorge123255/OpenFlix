package com.openflix

import android.app.Application
import com.openflix.data.discovery.ServerDiscoveryService
import com.openflix.data.local.AppSettings
import com.openflix.di.initKoin
import com.openflix.ui.di.playerModule
import com.openflix.ui.di.viewModelModule
import org.koin.android.ext.koin.androidContext

class OpenFlixApp : Application() {
    override fun onCreate() {
        super.onCreate()
        ServerDiscoveryService.init(this)
        AppSettings.init(this)
        initKoin(extraModules = listOf(viewModelModule, playerModule)) {
            androidContext(this@OpenFlixApp)
        }
    }
}
