package com.openflix

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import timber.log.Timber

/**
 * Main Application class for OpenFlix.
 * Initializes Hilt dependency injection and global app configuration.
 */
@HiltAndroidApp
class OpenFlixApp : Application() {

    override fun onCreate() {
        super.onCreate()

        // Initialize Timber for logging
        if (BuildConfig.DEBUG) {
            Timber.plant(Timber.DebugTree())
        } else {
            Timber.plant(ReleaseTree())
        }

        Timber.d("OpenFlix Application started")
    }

    /**
     * Custom Timber tree for release builds that filters out debug/verbose logs
     */
    private class ReleaseTree : Timber.Tree() {
        override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
            // In release, only log warnings and errors
            if (priority >= android.util.Log.WARN) {
                android.util.Log.println(priority, tag ?: "OpenFlix", message)
            }
        }
    }
}
