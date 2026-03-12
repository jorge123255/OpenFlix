package com.openflix.presentation.screens.livetv

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.local.LastWatchedService
import com.openflix.data.local.PreferencesManager
import com.openflix.data.repository.DVRRepository
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelGroup
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.presentation.components.livetv.LiveTVCategory
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

@HiltViewModel
class XfinityLiveTVViewModel @Inject constructor(
    private val repository: LiveTVRepository,
    private val dvrRepository: DVRRepository,
    private val preferencesManager: PreferencesManager,
    private val lastWatchedService: LastWatchedService
) : ViewModel() {

    private val _uiState = MutableStateFlow(XfinityLiveTVUiState())
    val uiState: StateFlow<XfinityLiveTVUiState> = _uiState.asStateFlow()

    val favoriteChannelIds: StateFlow<Set<String>> = preferencesManager.favoriteChannelIds
        .stateIn(viewModelScope, SharingStarted.Eagerly, emptySet())

    init {
        loadData()
    }

    private fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            // Calculate time window: now to +3 hours
            val now = System.currentTimeMillis() / 1000
            val endTime = now + (3 * 60 * 60)

            val guideResult = repository.getGuide(now, endTime)
            val groupsResult = repository.getChannelGroups()

            guideResult.fold(
                onSuccess = { guide ->
                    // Build channel-to-group mapping
                    val channelToGroup = mutableMapOf<String, Int>()
                    groupsResult.getOrNull()?.filter { it.enabled }?.forEach { group ->
                        group.members.forEach { member ->
                            channelToGroup[member.channelId.toString()] = group.id
                        }
                    }

                    _uiState.update { it.copy(
                        guide = guide,
                        isLoading = false,
                        channelGroups = groupsResult.getOrNull() ?: emptyList(),
                        channelToGroupMap = channelToGroup,
                        guideStartTime = now,
                        guideEndTime = endTime
                    )}
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to load guide")
                    _uiState.update { it.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load guide"
                    )}
                }
            )
        }
    }

    fun refresh() = loadData()

    fun filterChannels(
        category: LiveTVCategory,
        favoriteIds: Set<String>
    ): List<ChannelWithPrograms> {
        val guide = _uiState.value.guide
        return when (category) {
            LiveTVCategory.ALL -> guide.filterNot { it.channel.hidden }
            LiveTVCategory.FAVORITES -> guide.filter { it.channel.id in favoriteIds || it.channel.favorite }
            LiveTVCategory.SPORTS -> guide.filter { channelMatchesCategory(it, "sports") }
            LiveTVCategory.NEWS -> guide.filter { channelMatchesCategory(it, "news") }
            LiveTVCategory.MOVIES -> guide.filter { channelMatchesCategory(it, "movie") }
            LiveTVCategory.KIDS -> guide.filter { channelMatchesCategory(it, "kids") }
        }
    }

    private fun channelMatchesCategory(cwp: ChannelWithPrograms, category: String): Boolean {
        val ch = cwp.channel
        // Check channel category/group
        if (ch.category?.contains(category, ignoreCase = true) == true) return true
        if (ch.group?.contains(category, ignoreCase = true) == true) return true
        // Check if current program matches
        val now = cwp.programs.find { it.isAiring }
        if (now != null) {
            when (category) {
                "sports" -> if (now.isSports) return true
                "movie" -> if (now.isMovie) return true
                "kids" -> if (now.isKids) return true
                "news" -> if (now.genres.any { it.contains("news", ignoreCase = true) }) return true
            }
        }
        return false
    }

    fun toggleFavorite(channelId: String) {
        viewModelScope.launch {
            preferencesManager.toggleFavoriteChannel(channelId)
        }
    }

    suspend fun getStreamUrlForChannel(channel: Channel): Result<String> {
        val groupId = _uiState.value.channelToGroupMap[channel.id]
        return if (groupId != null) {
            repository.getChannelGroupStreamUrl(groupId)
        } else {
            channel.streamUrl?.let { Result.success(it) }
                ?: Result.failure(Exception("No stream URL"))
        }
    }

    fun scheduleRecording(channelId: String, program: Program, recordSeries: Boolean = false) {
        viewModelScope.launch {
            _uiState.update { it.copy(isSchedulingRecording = true, recordingError = null) }

            val result = dvrRepository.scheduleRecording(
                channelId = channelId,
                programId = program.programId ?: program.id,
                startTime = program.startTime,
                endTime = program.endTime,
                type = if (recordSeries) "series" else "single",
                seriesId = if (recordSeries) program.seriesId else null
            )

            result.fold(
                onSuccess = { recording ->
                    Timber.d("Scheduled recording: ${recording.title}")
                    _uiState.update { it.copy(
                        isSchedulingRecording = false,
                        recordingSuccess = "Recording scheduled: ${program.title}"
                    )}
                    delay(3000)
                    _uiState.update { it.copy(recordingSuccess = null) }
                },
                onFailure = { e ->
                    Timber.e(e, "Failed to schedule recording")
                    _uiState.update { it.copy(
                        isSchedulingRecording = false,
                        recordingError = e.message ?: "Failed to schedule recording"
                    )}
                }
            )
        }
    }

    fun clearRecordingError() {
        _uiState.update { it.copy(recordingError = null) }
    }
}

data class XfinityLiveTVUiState(
    val guide: List<ChannelWithPrograms> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val guideStartTime: Long = 0,
    val guideEndTime: Long = 0,
    val channelGroups: List<ChannelGroup> = emptyList(),
    val channelToGroupMap: Map<String, Int> = emptyMap(),
    val isSchedulingRecording: Boolean = false,
    val recordingSuccess: String? = null,
    val recordingError: String? = null
)
