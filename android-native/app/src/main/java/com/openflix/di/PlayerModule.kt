package com.openflix.di

import android.content.Context
import com.openflix.data.repository.SettingsRepository
import com.openflix.player.LiveTVPlayer
import com.openflix.player.MpvPlayer
import com.openflix.player.PlayerController
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object PlayerModule {

    @Provides
    @Singleton
    fun provideMpvPlayer(
        @ApplicationContext context: Context,
        settingsRepository: SettingsRepository
    ): MpvPlayer {
        return MpvPlayer(context, settingsRepository)
    }

    @Provides
    @Singleton
    fun providePlayerController(mpvPlayer: MpvPlayer): PlayerController {
        return PlayerController(mpvPlayer)
    }

    @Provides
    @Singleton
    fun provideLiveTVPlayer(
        @ApplicationContext context: Context
    ): LiveTVPlayer {
        return LiveTVPlayer(context)
    }
}
