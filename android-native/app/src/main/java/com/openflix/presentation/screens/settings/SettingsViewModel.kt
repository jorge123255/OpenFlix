package com.openflix.presentation.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.SettingsRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        collectSettings()
    }

    private fun collectSettings() {
        viewModelScope.launch {
            combine(
                settingsRepository.theme,
                settingsRepository.language,
                settingsRepository.libraryDensity,
                settingsRepository.hardwareDecoding,
                settingsRepository.bufferSize,
                settingsRepository.smallSkipDuration,
                settingsRepository.largeSkipDuration,
                settingsRepository.autoSkipIntro,
                settingsRepository.autoSkipCredits
            ) { values ->
                SettingsUiState(
                    theme = values[0] as String,
                    language = values[1] as String,
                    libraryDensity = values[2] as String,
                    hardwareDecoding = values[3] as Boolean,
                    bufferSize = values[4] as Int,
                    smallSkipDuration = values[5] as Int,
                    largeSkipDuration = values[6] as Int,
                    autoSkipIntro = values[7] as Boolean,
                    autoSkipCredits = values[8] as Boolean
                )
            }.collect { state ->
                _uiState.value = state
            }
        }

        // Collect remaining settings separately due to combine limit
        viewModelScope.launch {
            combine(
                settingsRepository.parentalControlsEnabled,
                settingsRepository.debugLogging,
                settingsRepository.accentColor
            ) { parentalEnabled, debugLogging, accentColor ->
                _uiState.update {
                    it.copy(
                        parentalControlsEnabled = parentalEnabled,
                        debugLogging = debugLogging,
                        accentColor = accentColor
                    )
                }
            }.collect()
        }

        // Collect video quality settings
        viewModelScope.launch {
            combine(
                settingsRepository.videoQuality,
                settingsRepository.sharpening,
                settingsRepository.debandEnabled,
                settingsRepository.audioUpmix
            ) { quality, sharpening, deband, upmix ->
                _uiState.update {
                    it.copy(
                        videoQuality = quality,
                        sharpening = sharpening,
                        debandEnabled = deband,
                        audioUpmix = upmix
                    )
                }
            }.collect()
        }
    }

    fun setTheme(theme: String) {
        viewModelScope.launch {
            settingsRepository.setTheme(theme)
        }
    }

    fun setLanguage(language: String) {
        viewModelScope.launch {
            settingsRepository.setLanguage(language)
        }
    }

    fun setLibraryDensity(density: String) {
        viewModelScope.launch {
            settingsRepository.setLibraryDensity(density)
        }
    }

    fun setHardwareDecoding(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setHardwareDecoding(enabled)
        }
    }

    fun setBufferSize(size: Int) {
        viewModelScope.launch {
            settingsRepository.setBufferSize(size)
        }
    }

    fun setSmallSkipDuration(seconds: Int) {
        viewModelScope.launch {
            settingsRepository.setSmallSkipDuration(seconds)
        }
    }

    fun setLargeSkipDuration(seconds: Int) {
        viewModelScope.launch {
            settingsRepository.setLargeSkipDuration(seconds)
        }
    }

    fun setAutoSkipIntro(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setAutoSkipIntro(enabled)
        }
    }

    fun setAutoSkipCredits(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setAutoSkipCredits(enabled)
        }
    }

    fun setParentalControlsEnabled(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setParentalControlsEnabled(enabled)
        }
    }

    fun setDebugLogging(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setDebugLogging(enabled)
        }
    }

    fun setVideoQuality(quality: String) {
        viewModelScope.launch {
            settingsRepository.setVideoQuality(quality)
        }
    }

    fun setSharpening(value: Float) {
        viewModelScope.launch {
            settingsRepository.setSharpening(value)
        }
    }

    fun setDebandEnabled(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setDebandEnabled(enabled)
        }
    }

    fun setAudioUpmix(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setAudioUpmix(enabled)
        }
    }

    fun setAccentColor(color: Long) {
        viewModelScope.launch {
            settingsRepository.setAccentColor(color)
        }
    }
}

data class SettingsUiState(
    val theme: String = "system",
    val accentColor: Long = 0xFF6366F1,
    val language: String = "en",
    val libraryDensity: String = "normal",
    val hardwareDecoding: Boolean = true,
    val bufferSize: Int = 64,
    val smallSkipDuration: Int = 10,
    val largeSkipDuration: Int = 30,
    val autoSkipIntro: Boolean = false,
    val autoSkipCredits: Boolean = false,
    val parentalControlsEnabled: Boolean = false,
    val debugLogging: Boolean = false,
    // Video Quality
    val videoQuality: String = "auto",
    val sharpening: Float = 0.3f,
    val debandEnabled: Boolean = true,
    val audioUpmix: Boolean = true
)
