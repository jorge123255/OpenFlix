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
            // Use provided offsets, or fall back to user's padding preferences
            val prePadding = startOffset ?: preferencesManager.dvrPrePadding.first()
            val postPadding = endOffset ?: preferencesManager.dvrPostPadding.first()

            val request = RecordRequest(
                channelId = channelId,
                programId = programId,
                startTime = startTime,
                endTime = endTime,
                type = type,
                seriesId = seriesId,
                startOffset = prePadding,
                endOffset = postPadding
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

    suspend fun updateRecordingProgress(recordingId: String, positionMs: Long): Result<Unit> {
        return try {
            val request = UpdateRecordingProgressRequest(viewOffset = positionMs)
            val response = api.updateRecordingProgress(recordingId, request)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to update progress"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating recording progress")
            Result.failure(e)
        }
    }

    suspend fun recordFromProgram(
        channelId: Int,
        programId: Int,
        seriesRecord: Boolean = false
    ): Result<RecordFromProgramResponse> {
        return try {
            val request = RecordFromProgramRequest(
                channelId = channelId,
                programId = programId,
                seriesRecord = seriesRecord
            )
            val response = api.recordFromProgram(request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!)
            } else {
                Result.failure(Exception("Failed to schedule recording from program"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error recording from program")
            Result.failure(e)
        }
    }

    // Series Rules
    suspend fun getSeriesRules(): Result<List<SeriesRule>> {
        return try {
            val response = api.getSeriesRules()
            if (response.isSuccessful && response.body() != null) {
                val rules = response.body()!!.rules.map { it.toDomain() }
                Result.success(rules)
            } else {
                Result.failure(Exception("Failed to get series rules"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting series rules")
            Result.failure(e)
        }
    }

    suspend fun createSeriesRule(
        title: String,
        channelId: Long? = null,
        keywords: String? = null,
        keepCount: Int = 0,
        prePadding: Int = 0,
        postPadding: Int = 0
    ): Result<SeriesRule> {
        return try {
            val request = CreateSeriesRuleRequest(
                title = title,
                channelId = channelId,
                keywords = keywords,
                keepCount = keepCount,
                prePadding = prePadding,
                postPadding = postPadding
            )
            val response = api.createSeriesRule(request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to create series rule"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error creating series rule")
            Result.failure(e)
        }
    }

    suspend fun updateSeriesRule(
        ruleId: Long,
        enabled: Boolean? = null,
        title: String? = null,
        keepCount: Int? = null,
        prePadding: Int? = null,
        postPadding: Int? = null
    ): Result<SeriesRule> {
        return try {
            val request = UpdateSeriesRuleRequest(
                title = title,
                keepCount = keepCount,
                prePadding = prePadding,
                postPadding = postPadding,
                enabled = enabled
            )
            val response = api.updateSeriesRule(ruleId, request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to update series rule"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating series rule")
            Result.failure(e)
        }
    }

    suspend fun deleteSeriesRule(ruleId: Long): Result<Unit> {
        return try {
            val response = api.deleteSeriesRule(ruleId)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to delete series rule"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error deleting series rule")
            Result.failure(e)
        }
    }

    // Disk Usage
    suspend fun getDiskUsage(): Result<DiskUsage> {
        return try {
            val response = api.getDiskUsage()
            if (response.isSuccessful && response.body() != null) {
                val data = response.body()!!
                Result.success(DiskUsage(
                    totalBytes = data.totalBytes,
                    freeBytes = data.freeBytes,
                    usedByDVR = data.usedByDVR,
                    isLow = data.isLow,
                    isCritical = data.isCritical,
                    quotaGB = data.quotaGB,
                    lowSpaceGB = data.lowSpaceGB
                ))
            } else {
                Result.failure(Exception("Failed to get disk usage"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting disk usage")
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

    private fun SeriesRuleDto.toDomain() = SeriesRule(
        id = id,
        title = title,
        channelId = channelId,
        keywords = keywords,
        timeSlot = timeSlot,
        daysOfWeek = daysOfWeek,
        keepCount = keepCount,
        prePadding = prePadding,
        postPadding = postPadding,
        enabled = enabled
    )
}
