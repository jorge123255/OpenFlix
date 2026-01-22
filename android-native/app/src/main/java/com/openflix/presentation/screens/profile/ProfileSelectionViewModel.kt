package com.openflix.presentation.screens.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.repository.PinRequiredException
import com.openflix.data.repository.ProfileRepository
import com.openflix.domain.model.Profile
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class ProfileSelectionViewModel @Inject constructor(
    private val profileRepository: ProfileRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ProfileSelectionUiState())
    val uiState: StateFlow<ProfileSelectionUiState> = _uiState.asStateFlow()

    init {
        loadProfiles()
    }

    fun loadProfiles() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            profileRepository.getProfiles().fold(
                onSuccess = { profiles ->
                    Timber.d("Loaded ${profiles.size} profiles")
                    _uiState.update { it.copy(
                        isLoading = false,
                        profiles = profiles,
                        error = null
                    )}
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load profiles")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load profiles"
                    )}
                }
            )
        }
    }

    fun selectProfile(profile: Profile) {
        if (profile.hasPassword) {
            // Show PIN dialog
            _uiState.update { it.copy(
                selectedProfile = profile,
                showPinDialog = true,
                pinError = null
            )}
        } else {
            // Switch directly
            switchToProfile(profile)
        }
    }

    fun enterPin(pin: String) {
        val profile = _uiState.value.selectedProfile ?: return
        _uiState.update { it.copy(isEnteringPin = true, pinError = null) }

        viewModelScope.launch {
            profileRepository.switchProfile(profile.uuid, pin).fold(
                onSuccess = { token ->
                    Timber.d("Successfully switched to profile: ${profile.name}")
                    _uiState.update { it.copy(
                        isEnteringPin = false,
                        showPinDialog = false,
                        selectedProfile = null,
                        switchedSuccessfully = true
                    )}
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to switch profile")
                    _uiState.update { it.copy(
                        isEnteringPin = false,
                        pinError = if (e is PinRequiredException) "Incorrect PIN" else e.message
                    )}
                }
            )
        }
    }

    fun dismissPinDialog() {
        _uiState.update { it.copy(
            showPinDialog = false,
            selectedProfile = null,
            pinError = null
        )}
    }

    fun clearSwitchFlag() {
        _uiState.update { it.copy(switchedSuccessfully = false) }
    }

    private fun switchToProfile(profile: Profile) {
        _uiState.update { it.copy(isSwitching = true) }

        viewModelScope.launch {
            profileRepository.switchProfile(profile.uuid).fold(
                onSuccess = { token ->
                    Timber.d("Successfully switched to profile: ${profile.name}")
                    _uiState.update { it.copy(
                        isSwitching = false,
                        switchedSuccessfully = true
                    )}
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to switch profile")
                    if (e is PinRequiredException) {
                        // Show PIN dialog
                        _uiState.update { it.copy(
                            isSwitching = false,
                            selectedProfile = profile,
                            showPinDialog = true
                        )}
                    } else {
                        _uiState.update { it.copy(
                            isSwitching = false,
                            error = e.message ?: "Failed to switch profile"
                        )}
                    }
                }
            )
        }
    }
}

data class ProfileSelectionUiState(
    val isLoading: Boolean = false,
    val profiles: List<Profile> = emptyList(),
    val selectedProfile: Profile? = null,
    val showPinDialog: Boolean = false,
    val pinError: String? = null,
    val isEnteringPin: Boolean = false,
    val isSwitching: Boolean = false,
    val switchedSuccessfully: Boolean = false,
    val error: String? = null
)
