package com.openflix.data.repository

import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.dto.MarkCommercialRequest
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Commercial break data
 */
data class CommercialBreak(
    val startTime: Double,
    val endTime: Double,
    val duration: Double,
    val confidence: Double,
    val skipped: Boolean,
    val userMarked: Boolean
)

/**
 * Commercial detection data for a recording
 */
data class CommercialData(
    val recordingId: String,
    val duration: Double,
    val commercials: List<CommercialBreak>,
    val method: String,
    val confidence: Double,
    val userCorrected: Boolean
)

/**
 * Skip check response
 */
data class SkipCheckResult(
    val shouldSkip: Boolean,
    val skipTo: Double,
    val position: Double
)

@Singleton
class CommercialSkipRepository @Inject constructor(
    private val api: OpenFlixApi
) {
    // Cache commercial data per recording
    private val commercialDataCache = mutableMapOf<String, CommercialData>()

    suspend fun getCommercials(recordingId: String): Result<CommercialData?> {
        // Check cache first
        commercialDataCache[recordingId]?.let {
            return Result.success(it)
        }

        return try {
            val response = api.getCommercials(recordingId)
            if (response.isSuccessful) {
                val body = response.body()
                val commercials = body?.commercials?.map { dto ->
                    CommercialBreak(
                        startTime = dto.startMs / 1000.0,
                        endTime = dto.endMs / 1000.0,
                        duration = (dto.endMs - dto.startMs) / 1000.0,
                        confidence = dto.confidence ?: 1.0,
                        skipped = false,
                        userMarked = dto.source == "manual"
                    )
                } ?: emptyList()
                val totalDuration = commercials.sumOf { it.duration }
                val avgConfidence = commercials.map { it.confidence }.average().takeIf { !it.isNaN() } ?: 0.0
                val data = CommercialData(
                    recordingId = recordingId,
                    duration = totalDuration,
                    commercials = commercials,
                    method = body?.detectionStatus ?: "unknown",
                    confidence = avgConfidence,
                    userCorrected = commercials.any { it.userMarked }
                )
                commercialDataCache[recordingId] = data
                Result.success(data)
            } else {
                Result.failure(Exception("Failed to get commercials"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting commercials")
            Result.failure(e)
        }
    }

    suspend fun checkPosition(recordingId: String, position: Double): Result<SkipCheckResult> {
        // First check local cache
        commercialDataCache[recordingId]?.let { data ->
            for (commercial in data.commercials) {
                if (position >= commercial.startTime && position < commercial.endTime) {
                    if (commercial.confidence >= 0.8) {
                        return Result.success(SkipCheckResult(
                            shouldSkip = true,
                            skipTo = commercial.endTime,
                            position = position
                        ))
                    }
                }
            }
        }

        // Check server
        return try {
            val positionMs = (position * 1000).toLong()
            val response = api.checkCommercialPosition(recordingId, positionMs)
            if (response.isSuccessful) {
                val body = response.body()
                val result = SkipCheckResult(
                    shouldSkip = body?.inCommercial ?: false,
                    skipTo = (body?.skipToMs ?: 0L) / 1000.0,
                    position = position
                )
                Result.success(result)
            } else {
                Result.success(SkipCheckResult(false, 0.0, position))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error checking commercial position")
            Result.success(SkipCheckResult(false, 0.0, position))
        }
    }

    suspend fun triggerDetection(recordingId: String): Result<Unit> {
        return try {
            val response = api.detectCommercials(recordingId)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to trigger detection"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error triggering commercial detection")
            Result.failure(e)
        }
    }

    suspend fun markAsCommercial(recordingId: String, start: Double, end: Double): Result<Unit> {
        return try {
            val startMs = (start * 1000).toLong()
            val endMs = (end * 1000).toLong()
            val response = api.markCommercial(recordingId, MarkCommercialRequest(startMs, endMs))
            if (response.isSuccessful) {
                // Invalidate cache
                commercialDataCache.remove(recordingId)
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to mark commercial"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error marking commercial")
            Result.failure(e)
        }
    }

    suspend fun unmarkCommercial(mediaId: String, commercialId: String): Result<Unit> {
        return try {
            val response = api.unmarkCommercial(mediaId, commercialId)
            if (response.isSuccessful) {
                // Invalidate cache
                commercialDataCache.remove(mediaId)
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to unmark commercial"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error unmarking commercial")
            Result.failure(e)
        }
    }

    private fun parseCommercialData(map: Map<*, *>?): CommercialData? {
        if (map == null) return null

        val commercialsData = map["commercials"] as? List<*> ?: emptyList<Any>()
        val commercials = commercialsData.mapNotNull { item ->
            val commMap = item as? Map<*, *> ?: return@mapNotNull null
            CommercialBreak(
                startTime = (commMap["start_time"] as? Number)?.toDouble() ?: 0.0,
                endTime = (commMap["end_time"] as? Number)?.toDouble() ?: 0.0,
                duration = (commMap["duration"] as? Number)?.toDouble() ?: 0.0,
                confidence = (commMap["confidence"] as? Number)?.toDouble() ?: 0.0,
                skipped = commMap["skipped"] as? Boolean ?: false,
                userMarked = commMap["user_marked"] as? Boolean ?: false
            )
        }

        return CommercialData(
            recordingId = map["recording_id"] as? String ?: "",
            duration = (map["duration"] as? Number)?.toDouble() ?: 0.0,
            commercials = commercials,
            method = map["method"] as? String ?: "",
            confidence = (map["confidence"] as? Number)?.toDouble() ?: 0.0,
            userCorrected = map["user_corrected"] as? Boolean ?: false
        )
    }
}
