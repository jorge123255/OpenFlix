package com.openflix

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import timber.log.Timber

/**
 * Receives boot completed broadcasts to restart background services.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Timber.d("Boot completed, starting background services")
                // TODO: Start background services for DVR, sync, etc.
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Timber.d("App updated, restarting services")
                // TODO: Restart services after app update
            }
        }
    }
}
