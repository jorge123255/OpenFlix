package com.openflix.data.repository

import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.dto.*
import com.openflix.domain.model.*
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
            val response = api.getRecordingStreamUrl(recordingId)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.url)
            } else {
                Result.failure(Exception("Failed to get recording stream URL"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting recording stream URL: $recordingId")
            Result.failure(e)
        }
    }

    // Conversion extensions
    private fun RecordingDto.toDomain() = Recording(
        id = id,
        title = title,
        subtitle = subtitle,
        description = description,
        thumb = thumb,
        art = art,
        channelId = channelId,
        channelName = channelName,
        startTime = startTime,
        endTime = endTime,
        duration = duration,
        filePath = filePath,
        fileSize = fileSize,
        status = RecordingStatus.fromString(status),
        seasonNumber = seasonNumber,
        episodeNumber = episodeNumber,
        seriesId = seriesId,
        programId = programId,
        viewOffset = viewOffset,
        commercials = commercials?.map { Commercial(it.start, it.end) } ?: emptyList()
    )

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
}
