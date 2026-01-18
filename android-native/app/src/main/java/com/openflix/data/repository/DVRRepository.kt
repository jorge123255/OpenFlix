package com.openflix.data.repository

import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.dto.*
import com.openflix.domain.model.*
import kotlinx.coroutines.flow.first
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for DVR operations.
 */
@Singleton
class DVRRepository @Inject constructor(
    private val api: OpenFlixApi,
    private val preferencesManager: PreferencesManager
) {

    suspend fun getRecordings(): Result<List<Recording>> {
        return try {
            val response = api.getDVRRecordings()
            if (response.isSuccessful && response.body() != null) {
                val recordings = response.body()!!.recordings.map { it.toDomain() }
                Result.success(recordings)
            } else {
                Result.failure(Exception("Failed to get recordings"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting recordings")
            Result.failure(e)
        }
    }

    suspend fun getScheduledRecordings(): Result<List<ScheduledRecording>> {
        return try {
            val response = api.getScheduledRecordings()
            if (response.isSuccessful && response.body() != null) {
                val scheduled = response.body()!!.scheduled?.map { it.toDomain() } ?: emptyList()
                Result.success(scheduled)
            } else {
                Result.failure(Exception("Failed to get scheduled recordings"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting scheduled recordings")
            Result.failure(e)
        }
    }

    suspend fun scheduleRecording(
        channelId: String,
        programId: String?,
        startTime: Long?,
        endTime: Long?,
        type: String = "single",
        seriesId: String? = null,
        startOffset: Int? = null,
        endOffset: Int? = null
    ): Result<Recording> {
        return try {
            val request = RecordRequest(
                channelId = channelId,
                programId = programId,
                startTime = startTime,
                endTime = endTime,
                type = type,
                seriesId = seriesId,
                startOffset = startOffset,
                endOffset = endOffset
            )
            val response = api.scheduleRecording(request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to schedule recording"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error scheduling recording")
            Result.failure(e)
        }
    }

    suspend fun deleteRecording(recordingId: String): Result<Unit> {
        return try {
            val response = api.deleteRecording(recordingId)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to delete recording"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error deleting recording: $recordingId")
            Result.failure(e)
        }
    }

    suspend fun getRecordingStreamUrl(recordingId: String): Result<String> {
        return try {
            // The server streams the file directly at /dvr/stream/{id}
            // We construct the URL directly from the server URL
            val serverUrl = preferencesManager.serverUrl.first()
            val authToken = preferencesManager.authToken.first()

            if (serverUrl.isNullOrBlank()) {
                Result.failure(Exception("Server URL not configured"))
            } else {
                val baseUrl = serverUrl.trimEnd('/')
                // Include auth token as query param for the video player
                // Server accepts X-Plex-Token as query parameter
                val streamUrl = if (!authToken.isNullOrBlank()) {
                    "$baseUrl/dvr/stream/$recordingId?X-Plex-Token=$authToken"
                } else {
                    "$baseUrl/dvr/stream/$recordingId"
                }
                Timber.d("Constructed recording stream URL: $streamUrl")
                Result.success(streamUrl)
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting recording stream URL: $recordingId")
            Result.failure(e)
        }
    }

    suspend fun getConflicts(): Result<ConflictsData> {
        return try {
            val response = api.getRecordingConflicts()
            if (response.isSuccessful && response.body() != null) {
                val data = response.body()!!
                val conflicts = data.conflicts.map { group ->
                    ConflictGroup(
                        recordings = group.recordings.map { it.toDomain() }
                    )
                }
                Result.success(ConflictsData(
                    conflicts = conflicts,
                    hasConflicts = data.hasConflicts,
                    totalCount = data.totalCount
                ))
            } else {
                Result.failure(Exception("Failed to get recording conflicts"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting recording conflicts")
            Result.failure(e)
        }
    }

    suspend fun resolveConflict(keepId: Long, cancelId: Long): Result<Unit> {
        return try {
            val request = ResolveConflictRequest(
                keepRecordingId = keepId,
                cancelRecordingId = cancelId
            )
            val response = api.resolveConflict(request)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to resolve conflict"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error resolving conflict")
            Result.failure(e)
        }
    }

    suspend fun getRecordingStats(): Result<RecordingStatsData> {
        return try {
            val response = api.getRecordingStats()
            if (response.isSuccessful && response.body() != null) {
                val data = response.body()!!
                Result.success(RecordingStatsData(
                    stats = data.stats.map { it.toDomain() },
                    activeCount = data.activeCount
                ))
            } else {
                Result.failure(Exception("Failed to get recording stats"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting recording stats")
            Result.failure(e)
        }
    }

    // Conversion extensions
    private fun RecordingDto.toDomain() = Recording(
        id = id.toString(),
        title = title,
        subtitle = subtitle,
        description = description,
        summary = summary,
        thumb = thumb,
        art = art,
        channelId = channelId?.toString(),
        channelName = channelName,
        channelLogo = channelLogo,
        startTime = parseIsoTime(startTime),
        endTime = parseIsoTime(endTime),
        duration = duration,
        filePath = filePath,
        fileSize = fileSize,
        status = RecordingStatus.fromString(status),
        seasonNumber = seasonNumber,
        episodeNumber = episodeNumber,
        seriesId = seriesId,
        programId = programId?.toString(),
        viewOffset = viewOffset,
        commercials = commercials?.map { Commercial(it.start, it.end) } ?: emptyList(),
        genres = genres,
        contentRating = contentRating,
        year = year,
        rating = rating,
        isMovie = isMovie ?: false
    )

    private fun parseIsoTime(isoTime: String?): Long {
        if (isoTime.isNullOrBlank()) return 0L
        return try {
            java.time.Instant.parse(isoTime).toEpochMilli()
        } catch (e: Exception) {
            Timber.w(e, "Failed to parse ISO time: $isoTime")
            0L
        }
    }

    private fun ScheduledRecordingDto.toDomain() = ScheduledRecording(
        id = id,
        title = title,
        channelId = channelId,
        channelName = channelName,
        startTime = startTime,
        endTime = endTime,
        type = type,
        seriesId = seriesId,
        programId = programId,
        status = status
    )

    private fun RecordingStatsDto.toDomain() = RecordingStats(
        id = id,
        title = title,
        fileSize = fileSize,
        fileSizeFormatted = fileSizeFormatted,
        elapsedSeconds = elapsedSeconds,
        elapsedFormatted = elapsedFormatted,
        totalSeconds = totalSeconds,
        remainingSeconds = remainingSeconds,
        progressPercent = progressPercent,
        bitrate = bitrate,
        isHealthy = isHealthy,
        isFailed = isFailed,
        failureReason = failureReason
    )
}
