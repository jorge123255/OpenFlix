package com.openflix.data.local

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import timber.log.Timber
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Manages all app preferences using DataStore.
 * Replaces SharedPreferences with type-safe, async storage.
 */
@Singleton
class PreferencesManager @Inject constructor(
    private val dataStore: DataStore<Preferences>
) {

    // === Authentication ===
    val authToken: Flow<String?> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.AUTH_TOKEN] }

    val serverUrl: Flow<String?> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SERVER_URL] }

    val currentUserId: Flow<String?> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.CURRENT_USER_ID] }

    val currentProfileId: Flow<String?> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.CURRENT_PROFILE_ID] }

    val isLocalAccessMode: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.LOCAL_ACCESS_MODE] ?: false }

    // === Appearance ===
    val theme: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.THEME] ?: "system" }

    val accentColor: Flow<Long> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.ACCENT_COLOR] ?: 0xFF6366F1 } // Default indigo

    val language: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.LANGUAGE] ?: "en" }

    val libraryDensity: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.LIBRARY_DENSITY] ?: "normal" }

    val useSeasonPosters: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.USE_SEASON_POSTERS] ?: true }

    val showHeroSection: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SHOW_HERO_SECTION] ?: true }

    // === Video Playback ===
    val hardwareDecoding: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.HARDWARE_DECODING] ?: true }

    val bufferSize: Flow<Int> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.BUFFER_SIZE] ?: 64 }

    val smallSkipDuration: Flow<Int> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SMALL_SKIP_DURATION] ?: 10 }

    val largeSkipDuration: Flow<Int> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.LARGE_SKIP_DURATION] ?: 30 }

    val autoSkipIntro: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.AUTO_SKIP_INTRO] ?: false }

    val autoSkipCredits: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.AUTO_SKIP_CREDITS] ?: false }

    val autoSkipDelay: Flow<Int> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.AUTO_SKIP_DELAY] ?: 5 }

    val rememberTrackSelections: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.REMEMBER_TRACK_SELECTIONS] ?: true }

    val defaultPlaybackSpeed: Flow<Float> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.DEFAULT_PLAYBACK_SPEED] ?: 1.0f }

    val defaultSleepTimer: Flow<Int> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.DEFAULT_SLEEP_TIMER] ?: 0 }

    // === Video Quality ===
    val videoQuality: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.VIDEO_QUALITY] ?: "auto" }  // auto, high, fast

    val sharpening: Flow<Float> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SHARPENING] ?: 0.3f }

    val debandEnabled: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.DEBAND_ENABLED] ?: true }

    val audioUpmix: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.AUDIO_UPMIX] ?: true }  // Upmix stereo to 5.1

    // === Subtitles ===
    val subtitleFontSize: Flow<Int> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SUBTITLE_FONT_SIZE] ?: 24 }

    val subtitleTextColor: Flow<Long> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SUBTITLE_TEXT_COLOR] ?: 0xFFFFFFFF }

    val subtitleBorderSize: Flow<Int> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SUBTITLE_BORDER_SIZE] ?: 2 }

    val subtitleBorderColor: Flow<Long> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SUBTITLE_BORDER_COLOR] ?: 0xFF000000 }

    val subtitleBackgroundColor: Flow<Long> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SUBTITLE_BG_COLOR] ?: 0x80000000 }

    val subtitleBackgroundOpacity: Flow<Float> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SUBTITLE_BG_OPACITY] ?: 0.5f }

    // === Shuffle Play ===
    val shuffleUnwatchedOnly: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SHUFFLE_UNWATCHED_ONLY] ?: false }

    val loopShuffleQueue: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.LOOP_SHUFFLE_QUEUE] ?: false }

    // === Parental Controls ===
    val parentalControlsEnabled: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.PARENTAL_CONTROLS_ENABLED] ?: false }

    val parentalPin: Flow<String?> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.PARENTAL_PIN] }

    val maxMovieRating: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.MAX_MOVIE_RATING] ?: "R" }

    val maxTVRating: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.MAX_TV_RATING] ?: "TV-MA" }

    val kidsMode: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.KIDS_MODE] ?: false }

    // === TMDB ===
    val tmdbApiKey: Flow<String?> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.TMDB_API_KEY] }

    // === Advanced ===
    val debugLogging: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.DEBUG_LOGGING] ?: false }

    val screensaverEnabled: Flow<Boolean> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SCREENSAVER_ENABLED] ?: true }

    val screensaverIdleTime: Flow<Int> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.SCREENSAVER_IDLE_TIME] ?: 5 }

    // === Setters ===

    suspend fun setAuthToken(token: String?) {
        dataStore.edit { prefs ->
            if (token != null) {
                prefs[PreferencesKeys.AUTH_TOKEN] = token
            } else {
                prefs.remove(PreferencesKeys.AUTH_TOKEN)
            }
        }
    }

    suspend fun setServerUrl(url: String?) {
        dataStore.edit { prefs ->
            if (url != null) {
                prefs[PreferencesKeys.SERVER_URL] = url
            } else {
                prefs.remove(PreferencesKeys.SERVER_URL)
            }
        }
    }

    suspend fun setCurrentUserId(userId: String?) {
        dataStore.edit { prefs ->
            if (userId != null) {
                prefs[PreferencesKeys.CURRENT_USER_ID] = userId
            } else {
                prefs.remove(PreferencesKeys.CURRENT_USER_ID)
            }
        }
    }

    suspend fun setCurrentProfileId(profileId: String?) {
        dataStore.edit { prefs ->
            if (profileId != null) {
                prefs[PreferencesKeys.CURRENT_PROFILE_ID] = profileId
            } else {
                prefs.remove(PreferencesKeys.CURRENT_PROFILE_ID)
            }
        }
    }

    suspend fun setLocalAccessMode(enabled: Boolean) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.LOCAL_ACCESS_MODE] = enabled
        }
    }

    suspend fun setTheme(theme: String) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.THEME] = theme
        }
    }

    suspend fun setLanguage(language: String) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.LANGUAGE] = language
        }
    }

    suspend fun setAccentColor(color: Long) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.ACCENT_COLOR] = color
        }
    }

    suspend fun setLibraryDensity(density: String) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.LIBRARY_DENSITY] = density
        }
    }

    suspend fun setHardwareDecoding(enabled: Boolean) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.HARDWARE_DECODING] = enabled
        }
    }

    suspend fun setBufferSize(size: Int) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.BUFFER_SIZE] = size
        }
    }

    suspend fun setSmallSkipDuration(seconds: Int) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.SMALL_SKIP_DURATION] = seconds
        }
    }

    suspend fun setLargeSkipDuration(seconds: Int) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.LARGE_SKIP_DURATION] = seconds
        }
    }

    suspend fun setAutoSkipIntro(enabled: Boolean) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.AUTO_SKIP_INTRO] = enabled
        }
    }

    suspend fun setAutoSkipCredits(enabled: Boolean) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.AUTO_SKIP_CREDITS] = enabled
        }
    }

    suspend fun setSubtitleFontSize(size: Int) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.SUBTITLE_FONT_SIZE] = size
        }
    }

    suspend fun setParentalControlsEnabled(enabled: Boolean) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.PARENTAL_CONTROLS_ENABLED] = enabled
        }
    }

    suspend fun setParentalPin(pin: String?) {
        dataStore.edit { prefs ->
            if (pin != null) {
                prefs[PreferencesKeys.PARENTAL_PIN] = pin
            } else {
                prefs.remove(PreferencesKeys.PARENTAL_PIN)
            }
        }
    }

    suspend fun setDebugLogging(enabled: Boolean) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.DEBUG_LOGGING] = enabled
        }
    }

    suspend fun setVideoQuality(quality: String) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.VIDEO_QUALITY] = quality
        }
    }

    suspend fun setSharpening(value: Float) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.SHARPENING] = value.coerceIn(0f, 1f)
        }
    }

    suspend fun setDebandEnabled(enabled: Boolean) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.DEBAND_ENABLED] = enabled
        }
    }

    suspend fun setAudioUpmix(enabled: Boolean) {
        dataStore.edit { prefs ->
            prefs[PreferencesKeys.AUDIO_UPMIX] = enabled
        }
    }

    suspend fun setTmdbApiKey(key: String?) {
        dataStore.edit { prefs ->
            if (key != null) {
                prefs[PreferencesKeys.TMDB_API_KEY] = key
            } else {
                prefs.remove(PreferencesKeys.TMDB_API_KEY)
            }
        }
    }

    suspend fun clearAll() {
        dataStore.edit { prefs ->
            prefs.clear()
        }
    }

    private fun handleError(e: Throwable) {
        if (e is IOException) {
            Timber.e(e, "Error reading preferences")
        } else {
            throw e
        }
    }

    private object PreferencesKeys {
        // Auth
        val AUTH_TOKEN = stringPreferencesKey("auth_token")
        val SERVER_URL = stringPreferencesKey("server_url")
        val CURRENT_USER_ID = stringPreferencesKey("current_user_id")
        val CURRENT_PROFILE_ID = stringPreferencesKey("current_profile_id")
        val LOCAL_ACCESS_MODE = booleanPreferencesKey("local_access_mode")

        // Appearance
        val THEME = stringPreferencesKey("theme")
        val ACCENT_COLOR = longPreferencesKey("accent_color")
        val LANGUAGE = stringPreferencesKey("language")
        val LIBRARY_DENSITY = stringPreferencesKey("library_density")
        val USE_SEASON_POSTERS = booleanPreferencesKey("use_season_posters")
        val SHOW_HERO_SECTION = booleanPreferencesKey("show_hero_section")

        // Video Playback
        val HARDWARE_DECODING = booleanPreferencesKey("hardware_decoding")
        val BUFFER_SIZE = intPreferencesKey("buffer_size")
        val SMALL_SKIP_DURATION = intPreferencesKey("small_skip_duration")
        val LARGE_SKIP_DURATION = intPreferencesKey("large_skip_duration")
        val AUTO_SKIP_INTRO = booleanPreferencesKey("auto_skip_intro")
        val AUTO_SKIP_CREDITS = booleanPreferencesKey("auto_skip_credits")
        val AUTO_SKIP_DELAY = intPreferencesKey("auto_skip_delay")
        val REMEMBER_TRACK_SELECTIONS = booleanPreferencesKey("remember_track_selections")
        val DEFAULT_PLAYBACK_SPEED = floatPreferencesKey("default_playback_speed")
        val DEFAULT_SLEEP_TIMER = intPreferencesKey("default_sleep_timer")

        // Video Quality
        val VIDEO_QUALITY = stringPreferencesKey("video_quality")
        val SHARPENING = floatPreferencesKey("sharpening")
        val DEBAND_ENABLED = booleanPreferencesKey("deband_enabled")
        val AUDIO_UPMIX = booleanPreferencesKey("audio_upmix")

        // Subtitles
        val SUBTITLE_FONT_SIZE = intPreferencesKey("subtitle_font_size")
        val SUBTITLE_TEXT_COLOR = longPreferencesKey("subtitle_text_color")
        val SUBTITLE_BORDER_SIZE = intPreferencesKey("subtitle_border_size")
        val SUBTITLE_BORDER_COLOR = longPreferencesKey("subtitle_border_color")
        val SUBTITLE_BG_COLOR = longPreferencesKey("subtitle_bg_color")
        val SUBTITLE_BG_OPACITY = floatPreferencesKey("subtitle_bg_opacity")

        // Shuffle
        val SHUFFLE_UNWATCHED_ONLY = booleanPreferencesKey("shuffle_unwatched_only")
        val LOOP_SHUFFLE_QUEUE = booleanPreferencesKey("loop_shuffle_queue")

        // Parental
        val PARENTAL_CONTROLS_ENABLED = booleanPreferencesKey("parental_controls_enabled")
        val PARENTAL_PIN = stringPreferencesKey("parental_pin")
        val MAX_MOVIE_RATING = stringPreferencesKey("max_movie_rating")
        val MAX_TV_RATING = stringPreferencesKey("max_tv_rating")
        val KIDS_MODE = booleanPreferencesKey("kids_mode")

        // Advanced
        val DEBUG_LOGGING = booleanPreferencesKey("debug_logging")
        val SCREENSAVER_ENABLED = booleanPreferencesKey("screensaver_enabled")
        val SCREENSAVER_IDLE_TIME = intPreferencesKey("screensaver_idle_time")

        // TMDB
        val TMDB_API_KEY = stringPreferencesKey("tmdb_api_key")

        // Live TV
        val FAVORITE_CHANNEL_IDS = stringPreferencesKey("favorite_channel_ids")

        // Remote Button Mappings
        val BUTTON_RED = stringPreferencesKey("button_red")
        val BUTTON_GREEN = stringPreferencesKey("button_green")
        val BUTTON_YELLOW = stringPreferencesKey("button_yellow")
        val BUTTON_BLUE = stringPreferencesKey("button_blue")
        val BUTTON_MENU = stringPreferencesKey("button_menu")
        val BUTTON_INFO = stringPreferencesKey("button_info")
        val BUTTON_RECORD = stringPreferencesKey("button_record")
    }

    // === Live TV Favorites ===
    val favoriteChannelIds: Flow<Set<String>> = dataStore.data
        .catch { e -> handleError(e) }
        .map { prefs ->
            prefs[PreferencesKeys.FAVORITE_CHANNEL_IDS]
                ?.split(",")
                ?.filter { it.isNotBlank() }
                ?.toSet()
                ?: emptySet()
        }

    suspend fun toggleFavoriteChannel(channelId: String) {
        dataStore.edit { prefs ->
            val current = prefs[PreferencesKeys.FAVORITE_CHANNEL_IDS]
                ?.split(",")
                ?.filter { it.isNotBlank() }
                ?.toMutableSet()
                ?: mutableSetOf()

            if (channelId in current) {
                current.remove(channelId)
            } else {
                current.add(channelId)
            }

            prefs[PreferencesKeys.FAVORITE_CHANNEL_IDS] = current.joinToString(",")
        }
    }

    suspend fun isChannelFavorite(channelId: String): Boolean {
        return dataStore.data.first()[PreferencesKeys.FAVORITE_CHANNEL_IDS]
            ?.split(",")
            ?.contains(channelId)
            ?: false
    }

    // === Remote Button Mappings ===
    val buttonRed: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.BUTTON_RED] ?: "record" }

    val buttonGreen: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.BUTTON_GREEN] ?: "subtitles" }

    val buttonYellow: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.BUTTON_YELLOW] ?: "audio" }

    val buttonBlue: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.BUTTON_BLUE] ?: "guide" }

    val buttonMenu: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.BUTTON_MENU] ?: "settings" }

    val buttonInfo: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.BUTTON_INFO] ?: "info" }

    val buttonRecord: Flow<String> = dataStore.data
        .catch { e -> handleError(e) }
        .map { it[PreferencesKeys.BUTTON_RECORD] ?: "record" }

    suspend fun setButtonMapping(button: String, action: String) {
        dataStore.edit { prefs ->
            val key = when (button) {
                "red" -> PreferencesKeys.BUTTON_RED
                "green" -> PreferencesKeys.BUTTON_GREEN
                "yellow" -> PreferencesKeys.BUTTON_YELLOW
                "blue" -> PreferencesKeys.BUTTON_BLUE
                "menu" -> PreferencesKeys.BUTTON_MENU
                "info" -> PreferencesKeys.BUTTON_INFO
                "record" -> PreferencesKeys.BUTTON_RECORD
                else -> return@edit
            }
            prefs[key] = action
        }
    }

    suspend fun getButtonMapping(button: String): String {
        val prefs = dataStore.data.first()
        return when (button) {
            "red" -> prefs[PreferencesKeys.BUTTON_RED] ?: "record"
            "green" -> prefs[PreferencesKeys.BUTTON_GREEN] ?: "subtitles"
            "yellow" -> prefs[PreferencesKeys.BUTTON_YELLOW] ?: "audio"
            "blue" -> prefs[PreferencesKeys.BUTTON_BLUE] ?: "guide"
            "menu" -> prefs[PreferencesKeys.BUTTON_MENU] ?: "settings"
            "info" -> prefs[PreferencesKeys.BUTTON_INFO] ?: "info"
            "record" -> prefs[PreferencesKeys.BUTTON_RECORD] ?: "record"
            else -> "none"
        }
    }

    suspend fun resetButtonMappings() {
        dataStore.edit { prefs ->
            prefs.remove(PreferencesKeys.BUTTON_RED)
            prefs.remove(PreferencesKeys.BUTTON_GREEN)
            prefs.remove(PreferencesKeys.BUTTON_YELLOW)
            prefs.remove(PreferencesKeys.BUTTON_BLUE)
            prefs.remove(PreferencesKeys.BUTTON_MENU)
            prefs.remove(PreferencesKeys.BUTTON_INFO)
            prefs.remove(PreferencesKeys.BUTTON_RECORD)
        }
    }
}
