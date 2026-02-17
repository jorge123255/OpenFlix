package com.openflix.data.repository

import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.dto.*
import com.openflix.domain.model.ImportResult
import com.openflix.domain.model.M3USource
import com.openflix.domain.model.XtreamSource
import com.openflix.domain.model.XtreamTestResult
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for managing Live TV sources (M3U and Xtream).
 */
@Singleton
class SourceRepository @Inject constructor(
    private val api: OpenFlixApi
) {

    // === M3U Sources ===

    suspend fun getM3USources(): Result<List<M3USource>> {
        return try {
            val response = api.getM3USources()
            if (response.isSuccessful && response.body() != null) {
                val sources = response.body()!!.sources.map { it.toDomain() }
                Result.success(sources)
            } else {
                Result.failure(Exception("Failed to get M3U sources: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting M3U sources")
            Result.failure(e)
        }
    }

    suspend fun createM3USource(name: String, url: String, epgUrl: String? = null): Result<M3USource> {
        return try {
            val request = CreateM3USourceRequest(name, url, epgUrl)
            val response = api.createM3USource(request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                val error = response.errorBody()?.string() ?: "Failed to create M3U source"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error creating M3U source")
            Result.failure(e)
        }
    }

    suspend fun updateM3USource(
        id: Int,
        name: String? = null,
        url: String? = null,
        epgUrl: String? = null,
        enabled: Boolean? = null,
        importVod: Boolean? = null,
        importSeries: Boolean? = null,
        vodLibraryId: Int? = null,
        seriesLibraryId: Int? = null
    ): Result<M3USource> {
        return try {
            val request = UpdateM3USourceRequest(
                name = name,
                url = url,
                epgUrl = epgUrl,
                enabled = enabled,
                importVod = importVod,
                importSeries = importSeries,
                vodLibraryId = vodLibraryId,
                seriesLibraryId = seriesLibraryId
            )
            val response = api.updateM3USource(id, request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                val error = response.errorBody()?.string() ?: "Failed to update M3U source"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating M3U source")
            Result.failure(e)
        }
    }

    suspend fun deleteM3USource(id: Int): Result<Unit> {
        return try {
            val response = api.deleteM3USource(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to delete M3U source: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error deleting M3U source")
            Result.failure(e)
        }
    }

    suspend fun refreshM3USource(id: Int): Result<Unit> {
        return try {
            val response = api.refreshM3USource(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to refresh M3U source: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error refreshing M3U source")
            Result.failure(e)
        }
    }

    suspend fun importM3UVOD(id: Int): Result<ImportResult> {
        return try {
            val response = api.importM3UVOD(id)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                val error = response.errorBody()?.string() ?: "Failed to import VOD"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error importing M3U VOD")
            Result.failure(e)
        }
    }

    suspend fun importM3USeries(id: Int): Result<String> {
        return try {
            val response = api.importM3USeries(id)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.message)
            } else {
                val error = response.errorBody()?.string() ?: "Failed to import series"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error importing M3U series")
            Result.failure(e)
        }
    }

    // === Xtream Sources ===

    suspend fun getXtreamSources(): Result<List<XtreamSource>> {
        return try {
            val response = api.getXtreamSources()
            if (response.isSuccessful && response.body() != null) {
                val sources = response.body()!!.sources.map { it.toDomain() }
                Result.success(sources)
            } else {
                Result.failure(Exception("Failed to get Xtream sources: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting Xtream sources")
            Result.failure(e)
        }
    }

    suspend fun getXtreamSource(id: Int): Result<XtreamSource> {
        return try {
            val response = api.getXtreamSource(id)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to get Xtream source: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting Xtream source")
            Result.failure(e)
        }
    }

    suspend fun createXtreamSource(
        name: String,
        serverUrl: String,
        username: String,
        password: String,
        importLive: Boolean = true,
        importVod: Boolean = false,
        importSeries: Boolean = false,
        vodLibraryId: Int? = null,
        seriesLibraryId: Int? = null
    ): Result<XtreamSource> {
        return try {
            val request = CreateXtreamSourceRequest(
                name = name,
                serverUrl = serverUrl,
                username = username,
                password = password,
                importLive = importLive,
                importVod = importVod,
                importSeries = importSeries,
                vodLibraryId = vodLibraryId,
                seriesLibraryId = seriesLibraryId
            )
            val response = api.createXtreamSource(request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                val error = response.errorBody()?.string() ?: "Failed to create Xtream source"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error creating Xtream source")
            Result.failure(e)
        }
    }

    suspend fun updateXtreamSource(
        id: Int,
        name: String? = null,
        serverUrl: String? = null,
        username: String? = null,
        password: String? = null,
        enabled: Boolean? = null,
        importLive: Boolean? = null,
        importVod: Boolean? = null,
        importSeries: Boolean? = null,
        vodLibraryId: Int? = null,
        seriesLibraryId: Int? = null
    ): Result<XtreamSource> {
        return try {
            val request = UpdateXtreamSourceRequest(
                name = name,
                serverUrl = serverUrl,
                username = username,
                password = password,
                enabled = enabled,
                importLive = importLive,
                importVod = importVod,
                importSeries = importSeries,
                vodLibraryId = vodLibraryId,
                seriesLibraryId = seriesLibraryId
            )
            val response = api.updateXtreamSource(id, request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                val error = response.errorBody()?.string() ?: "Failed to update Xtream source"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating Xtream source")
            Result.failure(e)
        }
    }

    suspend fun deleteXtreamSource(id: Int): Result<Unit> {
        return try {
            val response = api.deleteXtreamSource(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to delete Xtream source: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error deleting Xtream source")
            Result.failure(e)
        }
    }

    suspend fun testXtreamSource(id: Int): Result<XtreamTestResult> {
        return try {
            val response = api.testXtreamSource(id)
            if (response.isSuccessful && response.body() != null) {
                val testResponse = response.body()!!
                Result.success(
                    XtreamTestResult(
                        success = testResponse.success,
                        message = testResponse.message ?: "",
                        expirationDate = testResponse.serverInfo?.expirationDate,
                        maxConnections = testResponse.serverInfo?.maxConnections,
                        activeConnections = testResponse.serverInfo?.activeConnections
                    )
                )
            } else {
                val error = response.errorBody()?.string() ?: "Failed to test Xtream source"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error testing Xtream source")
            Result.failure(e)
        }
    }

    suspend fun refreshXtreamSource(id: Int): Result<Unit> {
        return try {
            val response = api.refreshXtreamSource(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to refresh Xtream source: ${response.code()}"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error refreshing Xtream source")
            Result.failure(e)
        }
    }

    suspend fun importXtreamVOD(id: Int): Result<ImportResult> {
        return try {
            val response = api.importXtreamVOD(id)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                val error = response.errorBody()?.string() ?: "Failed to import Xtream VOD"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error importing Xtream VOD")
            Result.failure(e)
        }
    }

    suspend fun importXtreamSeries(id: Int): Result<ImportResult> {
        return try {
            val response = api.importXtreamSeries(id)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                val error = response.errorBody()?.string() ?: "Failed to import Xtream series"
                Result.failure(Exception(error))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error importing Xtream series")
            Result.failure(e)
        }
    }
}

// === Extension functions for DTO to domain mapping ===

private fun M3USourceDto.toDomain() = M3USource(
    id = id,
    name = name,
    url = url,
    epgUrl = epgUrl,
    enabled = enabled,
    lastFetched = lastFetched,
    importVod = importVod,
    importSeries = importSeries,
    vodLibraryId = vodLibraryId,
    seriesLibraryId = seriesLibraryId,
    channelCount = channelCount,
    vodCount = vodCount,
    seriesCount = seriesCount
)

private fun XtreamSourceDto.toDomain() = XtreamSource(
    id = id,
    name = name,
    serverUrl = serverUrl,
    username = username,
    enabled = enabled,
    importLive = importLive,
    importVod = importVod,
    importSeries = importSeries,
    vodLibraryId = vodLibraryId,
    seriesLibraryId = seriesLibraryId,
    channelCount = channelCount,
    vodCount = vodCount,
    seriesCount = seriesCount,
    lastFetched = lastFetched,
    expirationDate = expirationDate
)

private fun ImportResultDto.toDomain() = ImportResult(
    added = added,
    updated = updated,
    skipped = skipped,
    errors = errors,
    total = total,
    duration = duration
)
