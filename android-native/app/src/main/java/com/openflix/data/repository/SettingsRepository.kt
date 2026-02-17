package com.openflix.data.repository

import com.openflix.data.local.PreferencesManager
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for app settings operations.
 */
@Singleton
class SettingsRepository @Inject constructor(
    private val preferencesManager: PreferencesManager
) {

    // === Appearance ===
    val theme: Flow<String> = preferencesManager.theme
    val accentColor: Flow<Long> = preferencesManager.accentColor
    val language: Flow<String> = preferencesManager.language
    val libraryDensity: Flow<String> = preferencesManager.libraryDensity
    val useSeasonPosters: Flow<Boolean> = preferencesManager.useSeasonPosters
    val showHeroSection: Flow<Boolean> = preferencesManager.showHeroSection

    // === Video Playback ===
    val hardwareDecoding: Flow<Boolean> = preferencesManager.hardwareDecoding
    val bufferSize: Flow<Int> = preferencesManager.bufferSize
    val smallSkipDuration: Flow<Int> = preferencesManager.smallSkipDuration
    val largeSkipDuration: Flow<Int> = preferencesManager.largeSkipDuration
    val autoSkipIntro: Flow<Boolean> = preferencesManager.autoSkipIntro
    val autoSkipCredits: Flow<Boolean> = preferencesManager.autoSkipCredits
    val autoSkipDelay: Flow<Int> = preferencesManager.autoSkipDelay
    val rememberTrackSelections: Flow<Boolean> = preferencesManager.rememberTrackSelections
    val defaultPlaybackSpeed: Flow<Float> = preferencesManager.defaultPlaybackSpeed
    val defaultSleepTimer: Flow<Int> = preferencesManager.defaultSleepTimer

    // === Video Quality ===
    val videoQuality: Flow<String> = preferencesManager.videoQuality
    val sharpening: Flow<Float> = preferencesManager.sharpening
    val debandEnabled: Flow<Boolean> = preferencesManager.debandEnabled
    val audioUpmix: Flow<Boolean> = preferencesManager.audioUpmix

    // === Subtitles ===
    val subtitleFontSize: Flow<Int> = preferencesManager.subtitleFontSize
    val subtitleTextColor: Flow<Long> = preferencesManager.subtitleTextColor
    val subtitleBorderSize: Flow<Int> = preferencesManager.subtitleBorderSize
    val subtitleBorderColor: Flow<Long> = preferencesManager.subtitleBorderColor
    val subtitleBackgroundColor: Flow<Long> = preferencesManager.subtitleBackgroundColor
    val subtitleBackgroundOpacity: Flow<Float> = preferencesManager.subtitleBackgroundOpacity

    // === Shuffle ===
    val shuffleUnwatchedOnly: Flow<Boolean> = preferencesManager.shuffleUnwatchedOnly
    val loopShuffleQueue: Flow<Boolean> = preferencesManager.loopShuffleQueue

    // === Parental Controls ===
    val parentalControlsEnabled: Flow<Boolean> = preferencesManager.parentalControlsEnabled
    val parentalPin: Flow<String?> = preferencesManager.parentalPin
    val maxMovieRating: Flow<String> = preferencesManager.maxMovieRating
    val maxTVRating: Flow<String> = preferencesManager.maxTVRating
    val kidsMode: Flow<Boolean> = preferencesManager.kidsMode

    // === Advanced ===
    val debugLogging: Flow<Boolean> = preferencesManager.debugLogging
    val screensaverEnabled: Flow<Boolean> = preferencesManager.screensaverEnabled
    val screensaverIdleTime: Flow<Int> = preferencesManager.screensaverIdleTime

    // === Setters ===

    suspend fun setTheme(theme: String) = preferencesManager.setTheme(theme)
    suspend fun setAccentColor(color: Long) = preferencesManager.setAccentColor(color)
    suspend fun setLanguage(language: String) = preferencesManager.setLanguage(language)
    suspend fun setLibraryDensity(density: String) = preferencesManager.setLibraryDensity(density)
    suspend fun setHardwareDecoding(enabled: Boolean) = preferencesManager.setHardwareDecoding(enabled)
    suspend fun setBufferSize(size: Int) = preferencesManager.setBufferSize(size)
    suspend fun setSmallSkipDuration(seconds: Int) = preferencesManager.setSmallSkipDuration(seconds)
    suspend fun setLargeSkipDuration(seconds: Int) = preferencesManager.setLargeSkipDuration(seconds)
    suspend fun setAutoSkipIntro(enabled: Boolean) = preferencesManager.setAutoSkipIntro(enabled)
    suspend fun setAutoSkipCredits(enabled: Boolean) = preferencesManager.setAutoSkipCredits(enabled)
    suspend fun setSubtitleFontSize(size: Int) = preferencesManager.setSubtitleFontSize(size)
    suspend fun setParentalControlsEnabled(enabled: Boolean) = preferencesManager.setParentalControlsEnabled(enabled)
    suspend fun setParentalPin(pin: String?) = preferencesManager.setParentalPin(pin)
    suspend fun setDebugLogging(enabled: Boolean) = preferencesManager.setDebugLogging(enabled)
    suspend fun setVideoQuality(quality: String) = preferencesManager.setVideoQuality(quality)
    suspend fun setSharpening(value: Float) = preferencesManager.setSharpening(value)
    suspend fun setDebandEnabled(enabled: Boolean) = preferencesManager.setDebandEnabled(enabled)
    suspend fun setAudioUpmix(enabled: Boolean) = preferencesManager.setAudioUpmix(enabled)
}
