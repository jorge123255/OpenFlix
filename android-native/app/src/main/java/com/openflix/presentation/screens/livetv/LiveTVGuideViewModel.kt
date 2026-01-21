package com.openflix.presentation.screens.livetv

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.openflix.data.local.LastWatchedService
import com.openflix.data.repository.DVRRepository
import com.openflix.data.repository.LiveTVRepository
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelGroup
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.Program
import com.openflix.domain.model.Recording
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import timber.log.Timber
import javax.inject.Inject

/**
 * ViewModel for the EPG Guide screen.
 * Manages guide data loading, time navigation, and DVR scheduling.
 */
@HiltViewModel
class LiveTVGuideViewModel @Inject constructor(
    private val repository: LiveTVRepository,
    private val dvrRepository: DVRRepository,
    private val lastWatchedService: LastWatchedService
) : ViewModel() {

    private val _uiState = MutableStateFlow(LiveTVGuideUiState())
    val uiState: StateFlow<LiveTVGuideUiState> = _uiState.asStateFlow()

    private val _recentChannelIds = MutableStateFlow<List<String>>(emptyList())
    val recentChannelIds: StateFlow<List<String>> = _recentChannelIds.asStateFlow()

    init {
        loadRecentChannels()
    }

    private fun loadRecentChannels() {
        _recentChannelIds.value = lastWatchedService.getRecentChannelIds()
    }

    /**
     * Track a channel as recently watched
     */
    fun trackChannelWatch(channel: Channel) {
        lastWatchedService.setLastWatchedChannel(channel)
        loadRecentChannels() // Refresh the list
    }

    private var baseStartTime: Long = 0
    private var baseEndTime: Long = 0

    fun loadGuide(startTime: Long, endTime: Long) {
        baseStartTime = startTime
        baseEndTime = endTime

        viewModelScope.launch {
            _uiState.update { it.copy(
                isLoading = true,
                error = null,
                visibleStartTime = startTime,
                visibleEndTime = endTime
            )}

            // Load guide and channel groups in parallel
            val guideResult = repository.getGuide(startTime, endTime)
            val groupsResult = repository.getChannelGroups()

            guideResult.fold(
                onSuccess = { guide ->
                    Timber.d("Loaded ${guide.size} channels with programs")

                    // Build channel to group mapping
                    val channelToGroup = mutableMapOf<String, Int>()
                    groupsResult.getOrNull()?.filter { it.enabled }?.forEach { group ->
                        group.members.forEach { member ->
                            // Map each channel in the group to the group's ID
                            channelToGroup[member.channelId.toString()] = group.id
                        }
                    }

                    Timber.d("Loaded ${groupsResult.getOrNull()?.size ?: 0} channel groups, mapped ${channelToGroup.size} channels")

                    _uiState.update { it.copy(
                        guide = guide,
                        isLoading = false,
                        channelGroups = groupsResult.getOrNull() ?: emptyList(),
                        channelToGroupMap = channelToGroup
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

    /**
     * Get the stream URL for a channel, using channel group failover if available.
     * Returns Result with the stream URL to use.
     */
    suspend fun getStreamUrlForChannel(channel: Channel): Result<String> {
        val groupId = _uiState.value.channelToGroupMap[channel.id]

        return if (groupId != null) {
            // Channel is in a group - use group stream endpoint for failover
            Timber.d("Channel ${channel.name} is in group $groupId, using group stream")
            repository.getChannelGroupStreamUrl(groupId)
        } else {
            // No group - use direct channel stream
            channel.streamUrl?.let { Result.success(it) }
                ?: Result.failure(Exception("No stream URL available for channel"))
        }
    }

    /**
     * Check if a channel is part of a failover group
     */
    fun isChannelInGroup(channelId: String): Boolean {
        return _uiState.value.channelToGroupMap.containsKey(channelId)
    }

    /**
     * Shift the visible time window by the specified number of minutes.
     * Positive values shift forward, negative values shift backward.
     */
    fun shiftTime(minutes: Int) {
        val shiftSeconds = minutes * 60L
        val newStartTime = _uiState.value.visibleStartTime + shiftSeconds
        val newEndTime = _uiState.value.visibleEndTime + shiftSeconds

        // Don't allow going too far in the past (more than 12 hours)
        val now = System.currentTimeMillis() / 1000
        val minStartTime = now - (12 * 60 * 60)
        if (newStartTime < minStartTime) return

        // Don't allow going too far in the future (more than 7 days)
        val maxEndTime = now + (7 * 24 * 60 * 60)
        if (newEndTime > maxEndTime) return

        // Reload guide with new time range
        loadGuide(newStartTime, newEndTime)
    }

    fun loadMoreChannels() {
        val currentCount = _uiState.value.displayedCount
        val totalCount = _uiState.value.guide.size
        if (currentCount < totalCount) {
            _uiState.update { it.copy(displayedCount = minOf(currentCount + 50, totalCount)) }
        }
    }

    fun getDisplayedGuide(): List<ChannelWithPrograms> {
        return _uiState.value.guide.take(_uiState.value.displayedCount)
    }

    /**
     * Schedule a recording for a program.
     * @param channelId The channel ID
     * @param program The program to record
     * @param recordSeries If true, set up series recording
     */
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
                    // Clear success message after delay
                    kotlinx.coroutines.delay(3000)
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

data class LiveTVGuideUiState(
    val guide: List<ChannelWithPrograms> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val visibleStartTime: Long = 0,
    val visibleEndTime: Long = 0,
    val displayedCount: Int = 50,  // Only show first N channels initially
    val isSchedulingRecording: Boolean = false,
    val recordingSuccess: String? = null,
    val recordingError: String? = null,
    val channelGroups: List<ChannelGroup> = emptyList(),
    val channelToGroupMap: Map<String, Int> = emptyMap()  // channelId -> groupId
)
