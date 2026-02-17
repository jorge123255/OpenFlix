package com.openflix.presentation.screens.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.local.PreferencesManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class RemoteMappingViewModel @Inject constructor(
    private val preferencesManager: PreferencesManager
) : ViewModel() {

    private val _uiState = MutableStateFlow(RemoteMappingUiState())
    val uiState: StateFlow<RemoteMappingUiState> = _uiState.asStateFlow()

    init {
        collectMappings()
    }

    private fun collectMappings() {
        viewModelScope.launch {
            combine(
                preferencesManager.buttonRed,
                preferencesManager.buttonGreen,
                preferencesManager.buttonYellow,
                preferencesManager.buttonBlue,
                preferencesManager.buttonMenu,
                preferencesManager.buttonInfo,
                preferencesManager.buttonRecord
            ) { values ->
                RemoteMappingUiState(
                    buttonRed = values[0],
                    buttonGreen = values[1],
                    buttonYellow = values[2],
                    buttonBlue = values[3],
                    buttonMenu = values[4],
                    buttonInfo = values[5],
                    buttonRecord = values[6]
                )
            }.collect { state ->
                _uiState.value = state
            }
        }
    }

    fun setButtonMapping(button: String, action: String) {
        viewModelScope.launch {
            preferencesManager.setButtonMapping(button, action)
        }
    }

    fun resetToDefaults() {
        viewModelScope.launch {
            preferencesManager.resetButtonMappings()
        }
    }

    fun showActionPicker(button: RemoteButton) {
        _uiState.update { it.copy(selectedButton = button, showActionPicker = true) }
    }

    fun dismissActionPicker() {
        _uiState.update { it.copy(selectedButton = null, showActionPicker = false) }
    }

    fun selectAction(action: String) {
        val button = _uiState.value.selectedButton ?: return
        setButtonMapping(button.key, action)
        dismissActionPicker()
    }
}

data class RemoteMappingUiState(
    val buttonRed: String = "record",
    val buttonGreen: String = "subtitles",
    val buttonYellow: String = "audio",
    val buttonBlue: String = "guide",
    val buttonMenu: String = "settings",
    val buttonInfo: String = "info",
    val buttonRecord: String = "record",
    val selectedButton: RemoteButton? = null,
    val showActionPicker: Boolean = false
)

enum class RemoteButton(
    val key: String,
    val displayName: String,
    val color: Long? = null
) {
    RED("red", "Red Button", 0xFFE53935),
    GREEN("green", "Green Button", 0xFF43A047),
    YELLOW("yellow", "Yellow Button", 0xFFFDD835),
    BLUE("blue", "Blue Button", 0xFF1E88E5),
    MENU("menu", "Menu Button"),
    INFO("info", "Info Button"),
    RECORD("record", "Record Button", 0xFFE53935)
}

enum class RemoteAction(
    val key: String,
    val displayName: String,
    val description: String
) {
    GUIDE("guide", "EPG Guide", "Open the electronic program guide"),
    RECORD("record", "Record", "Start recording current program"),
    INFO("info", "Show Info", "Display program information"),
    FAVORITES("favorites", "Favorites", "Show favorite channels"),
    CHANNELS("channels", "Channel List", "Open channel list"),
    SUBTITLES("subtitles", "Subtitles", "Toggle subtitles menu"),
    AUDIO("audio", "Audio Track", "Switch audio track"),
    SETTINGS("settings", "Settings", "Open settings"),
    SLEEP("sleep", "Sleep Timer", "Set sleep timer"),
    ASPECT("aspect", "Aspect Ratio", "Cycle aspect ratio"),
    PREVIOUS("previous", "Previous Channel", "Go to previous channel"),
    NONE("none", "None", "No action")
}
