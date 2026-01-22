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
 * Repository for media-related operations.
 */
@Singleton
class MediaRepository @Inject constructor(
    private val api: OpenFlixApi,
    private val preferencesManager: PreferencesManager
) {

    // Cache the server URL for building image URLs
    private suspend fun getServerBaseUrl(): String {
        return preferencesManager.serverUrl.first() ?: "http://127.0.0.1:32400"
    }

    // Build full URL for relative paths
    private fun buildFullUrl(baseUrl: String, path: String?): String? {
        if (path == null) return null
        // If already absolute URL, return as-is
        if (path.startsWith("http://") || path.startsWith("https://")) {
            return path
        }
        // Build full URL from relative path
        return baseUrl.trimEnd('/') + path
    }

    /**
     * Get home content - returns library sections as hubs with items
     */
    suspend fun getHomeHubs(): Result<List<Hub>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getLibraries()
            if (response.isSuccessful && response.body() != null) {
                val sections = response.body()!!.mediaContainer?.directories ?: emptyList()

                // Load hubs for each section using the hubs endpoint (includes content ratings)
                val hubs = sections.flatMap { section ->
                    try {
                        val hubsResponse = api.getLibraryHubs(section.key)
                        if (hubsResponse.isSuccessful && hubsResponse.body() != null) {
                            hubsResponse.body()!!.mediaContainer?.hubs?.map { hubDto ->
                                Hub(
                                    id = hubDto.hubIdentifier ?: hubDto.key ?: section.key,
                                    key = hubDto.key ?: "/library/sections/${section.key}/all",
                                    hubKey = hubDto.hubIdentifier ?: section.key,
                                    type = hubDto.type ?: section.type,
                                    hubType = hubDto.type ?: section.type,
                                    title = hubDto.title.ifEmpty { section.title },
                                    style = hubDto.style ?: "shelf",
                                    promoted = hubDto.promoted ?: false,
                                    size = hubDto.size ?: 0,
                                    more = hubDto.more ?: false,
                                    items = hubDto.metadata?.map { it.toDomain(baseUrl) } ?: emptyList(),
                                    context = hubDto.context
                                )
                            } ?: emptyList()
                        } else {
                            Timber.w("Failed to load hubs for section ${section.key}")
                            emptyList()
                        }
                    } catch (e: Exception) {
                        Timber.e(e, "Error loading hubs for section ${section.key}")
                        emptyList()
                    }
                }

                Timber.d("Loaded ${hubs.size} library sections with items")
                Result.success(hubs)
            } else {
                Result.failure(Exception("Failed to get libraries"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting home content")
            Result.failure(e)
        }
    }

    /**
     * Get streaming service hubs (Netflix, Disney+, HBO Max, etc.)
     */
    suspend fun getStreamingServiceHubs(): Result<List<Hub>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getAllStreamingServices()
            if (response.isSuccessful && response.body() != null) {
                val hubs = response.body()!!.mediaContainer?.hubs?.map { hubDto: com.openflix.data.remote.dto.StreamingHubDto ->
                    Hub(
                        id = hubDto.hubIdentifier ?: hubDto.key ?: "",
                        key = hubDto.key ?: "",
                        hubKey = hubDto.hubIdentifier ?: "",
                        type = hubDto.type ?: "movie",
                        hubType = hubDto.type,
                        title = hubDto.title,
                        style = hubDto.style ?: "shelf",
                        promoted = hubDto.promoted ?: false,
                        size = hubDto.size ?: 0,
                        more = hubDto.more ?: false,
                        items = hubDto.metadata?.map { it.toDomain(baseUrl) } ?: emptyList(),
                        context = hubDto.context
                    )
                } ?: emptyList()

                Timber.d("Loaded ${hubs.size} streaming service hubs")
                Result.success(hubs)
            } else {
                Timber.w("Failed to get streaming services: ${response.code()}")
                Result.success(emptyList()) // Return empty list instead of failure
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting streaming services")
            Result.success(emptyList()) // Return empty list on error
        }
    }

    /**
     * Get a specific library section as a hub with all items
     */
    suspend fun getHub(hubId: String): Result<Hub> {
        return try {
            val baseUrl = getServerBaseUrl()
            // First get the library section info
            val libResponse = api.getLibraries()
            val section = libResponse.body()?.mediaContainer?.directories?.find { it.key == hubId }

            // Then get the media items
            val response = api.getAllLibraryMedia(libraryId = hubId)
            if (response.isSuccessful && response.body() != null) {
                val container = response.body()!!.mediaContainer
                val items = container?.metadata?.map { it.toDomain(baseUrl) } ?: emptyList()

                Result.success(Hub(
                    id = hubId,
                    key = "/library/sections/$hubId/all",
                    hubKey = hubId,
                    type = section?.type ?: "unknown",
                    hubType = section?.type,
                    title = section?.title ?: "Library",
                    style = "shelf",
                    promoted = false,
                    size = container?.totalSize ?: items.size,
                    more = false,
                    items = items
                ))
            } else {
                Result.failure(Exception("Failed to get hub"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting hub: $hubId")
            Result.failure(e)
        }
    }

    /**
     * Get paginated items from a library section
     */
    suspend fun getHubItems(hubId: String, start: Int = 0, size: Int = 50): Result<List<MediaItem>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getAllLibraryMedia(libraryId = hubId, start = start, size = size)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.mediaContainer?.metadata?.map { it.toDomain(baseUrl) } ?: emptyList()
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get hub items"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting hub items: $hubId")
            Result.failure(e)
        }
    }

    suspend fun getLibraries(): Result<List<Library>> {
        return try {
            val response = api.getLibraries()
            if (response.isSuccessful && response.body() != null) {
                val sections = response.body()!!.mediaContainer?.directories ?: emptyList()
                val libraries = sections.map { section ->
                    Library(
                        id = section.key,
                        key = section.key,
                        title = section.title,
                        type = section.type,
                        thumb = null,
                        art = null,
                        itemCount = section.count
                    )
                }
                Result.success(libraries)
            } else {
                Result.failure(Exception("Failed to get libraries"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting libraries")
            Result.failure(e)
        }
    }

    /**
     * Get library section as a list of hubs (for now, just returns the library content as a single hub)
     */
    suspend fun getLibraryHubs(libraryId: String): Result<List<Hub>> {
        return try {
            val hubResult = getHub(libraryId)
            hubResult.fold(
                onSuccess = { hub -> Result.success(listOf(hub)) },
                onFailure = { e -> Result.failure(e) }
            )
        } catch (e: Exception) {
            Timber.e(e, "Error getting library hubs: $libraryId")
            Result.failure(e)
        }
    }

    suspend fun getAllLibraryMedia(
        libraryId: String,
        sort: String? = null
    ): Result<List<MediaItem>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getAllLibraryMedia(libraryId = libraryId, sort = sort)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.mediaContainer?.metadata?.map { it.toDomain(baseUrl) } ?: emptyList()
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get library media"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting library media: $libraryId")
            Result.failure(e)
        }
    }

    suspend fun getMediaItem(mediaId: String): Result<MediaItem> {
        return try {
            val baseUrl = getServerBaseUrl()
            // Use Plex-compatible library/metadata endpoint
            val response = api.getMetadata(mediaId)
            if (response.isSuccessful && response.body() != null) {
                val metadata = response.body()!!.mediaContainer?.metadata?.firstOrNull()
                if (metadata != null) {
                    Result.success(metadata.toDomain(baseUrl))
                } else {
                    Result.failure(Exception("No metadata found"))
                }
            } else {
                Result.failure(Exception("Failed to get media item"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting media item: $mediaId")
            Result.failure(e)
        }
    }

    suspend fun getMediaChildren(mediaId: String): Result<List<MediaItem>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getMediaChildren(mediaId)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain(baseUrl) }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get media children"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting media children: $mediaId")
            Result.failure(e)
        }
    }

    suspend fun getRelatedMedia(mediaId: String): Result<List<MediaItem>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getRelatedMedia(mediaId)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain(baseUrl) }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get related media"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting related media: $mediaId")
            Result.failure(e)
        }
    }

    suspend fun getShowSeasons(showId: String): Result<List<Season>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getMetadataChildren(showId)
            if (response.isSuccessful && response.body() != null) {
                val metadata = response.body()!!.mediaContainer?.metadata ?: emptyList()
                val seasons = metadata
                    .filter { it.type == "season" }
                    .map { it.toSeason(baseUrl) }
                    .sortedBy { it.index }
                Timber.d("Loaded ${seasons.size} seasons for show $showId")
                Result.success(seasons)
            } else {
                Timber.w("Failed to get show seasons: ${response.code()}")
                Result.failure(Exception("Failed to get show seasons"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting show seasons: $showId")
            Result.failure(e)
        }
    }

    suspend fun getSeasonEpisodes(seasonId: String): Result<List<Episode>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.getMetadataChildren(seasonId)
            if (response.isSuccessful && response.body() != null) {
                val metadata = response.body()!!.mediaContainer?.metadata ?: emptyList()
                val episodes = metadata
                    .filter { it.type == "episode" }
                    .map { it.toEpisode(baseUrl) }
                    .sortedBy { it.index }
                Timber.d("Loaded ${episodes.size} episodes for season $seasonId")
                Result.success(episodes)
            } else {
                Timber.w("Failed to get season episodes: ${response.code()}")
                Result.failure(Exception("Failed to get season episodes"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting season episodes: $seasonId")
            Result.failure(e)
        }
    }

    suspend fun search(query: String): Result<List<MediaItem>> {
        return try {
            val baseUrl = getServerBaseUrl()
            val response = api.globalSearch(query)
            if (response.isSuccessful && response.body() != null) {
                // Flatten all hubs' metadata into a single list
                val items = response.body()!!.mediaContainer?.hubs
                    ?.flatMap { hub -> hub.metadata?.map { it.toDomain(baseUrl) } ?: emptyList() }
                    ?: emptyList()
                Timber.d("Search returned ${items.size} results for: $query")
                Result.success(items)
            } else {
                Result.failure(Exception("Search failed"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error searching: $query")
            Result.failure(e)
        }
    }

    /**
     * Update playback progress using timeline API with retry support
     */
    suspend fun updateProgress(mediaId: String, timeMs: Long, durationMs: Long? = null, state: String = "playing"): Result<Unit> {
        return retryWithBackoff(maxRetries = 3) {
            val response = api.updateTimeline(
                ratingKey = mediaId,
                time = timeMs,
                duration = durationMs,
                state = state
            )
            if (response.isSuccessful) {
                Timber.d("Progress updated: mediaId=$mediaId, time=$timeMs, state=$state")
                Result.success(Unit)
            } else {
                Timber.w("Failed to update progress: ${response.code()}")
                Result.failure(Exception("Failed to update progress: ${response.code()}"))
            }
        }
    }

    /**
     * Mark content as watched (scrobble)
     */
    suspend fun markAsWatched(mediaId: String): Result<Unit> {
        return retryWithBackoff(maxRetries = 3) {
            val response = api.scrobble(mediaId)
            if (response.isSuccessful) {
                Timber.d("Marked as watched: $mediaId")
                Result.success(Unit)
            } else {
                Timber.w("Failed to mark as watched: ${response.code()}")
                Result.failure(Exception("Failed to mark as watched: ${response.code()}"))
            }
        }
    }

    /**
     * Mark content as unwatched (unscrobble)
     */
    suspend fun markAsUnwatched(mediaId: String): Result<Unit> {
        return retryWithBackoff(maxRetries = 3) {
            val response = api.unscrobble(mediaId)
            if (response.isSuccessful) {
                Timber.d("Marked as unwatched: $mediaId")
                Result.success(Unit)
            } else {
                Timber.w("Failed to mark as unwatched: ${response.code()}")
                Result.failure(Exception("Failed to mark as unwatched: ${response.code()}"))
            }
        }
    }

    /**
     * Retry helper with exponential backoff
     */
    private suspend fun <T> retryWithBackoff(
        maxRetries: Int = 3,
        initialDelayMs: Long = 1000,
        maxDelayMs: Long = 10000,
        factor: Double = 2.0,
        block: suspend () -> Result<T>
    ): Result<T> {
        var currentDelay = initialDelayMs
        repeat(maxRetries) { attempt ->
            val result = try {
                block()
            } catch (e: Exception) {
                Timber.w(e, "Attempt ${attempt + 1}/$maxRetries failed")
                Result.failure(e)
            }

            if (result.isSuccess) {
                return result
            }

            if (attempt < maxRetries - 1) {
                Timber.d("Retrying in ${currentDelay}ms (attempt ${attempt + 2}/$maxRetries)")
                kotlinx.coroutines.delay(currentDelay)
                currentDelay = (currentDelay * factor).toLong().coerceAtMost(maxDelayMs)
            }
        }
        return Result.failure(Exception("Failed after $maxRetries attempts"))
    }

    suspend fun getPlaybackUrl(mediaId: String): Result<String> {
        return try {
            val baseUrl = getServerBaseUrl()
            Timber.d("getPlaybackUrl: baseUrl=$baseUrl, mediaId=$mediaId")
            // Get metadata which contains the media file info
            val response = api.getMetadata(mediaId)
            Timber.d("getPlaybackUrl: response code=${response.code()}, isSuccessful=${response.isSuccessful}")
            if (response.isSuccessful && response.body() != null) {
                val metadata = response.body()!!.mediaContainer?.metadata?.firstOrNull()
                Timber.d("getPlaybackUrl: metadata title=${metadata?.title}, media count=${metadata?.media?.size}")
                // Get the first part's key for playback
                val partKey = metadata?.media?.firstOrNull()?.part?.firstOrNull()?.key
                Timber.d("getPlaybackUrl: partKey=$partKey")
                if (partKey != null) {
                    val playbackUrl = baseUrl.trimEnd('/') + partKey
                    Timber.d("Playback URL: $playbackUrl")
                    Result.success(playbackUrl)
                } else {
                    Timber.e("No playback file found - media=${metadata?.media}, parts=${metadata?.media?.firstOrNull()?.part}")
                    Result.failure(Exception("No playback file found"))
                }
            } else {
                Timber.e("Failed to get playback URL - response: ${response.errorBody()?.string()}")
                Result.failure(Exception("Failed to get playback URL"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting playback URL: $mediaId")
            Result.failure(e)
        }
    }

    // Extension functions to convert DTOs to domain models
    private fun MediaItemDto.toDomain(baseUrl: String) = MediaItem(
        id = id,  // Uses computed property that returns ratingKey as string
        key = key,
        ratingKey = ratingKey?.toString(),
        type = MediaType.fromString(type),
        title = title,
        originalTitle = originalTitle,
        tagline = tagline,
        summary = summary,
        thumb = buildFullUrl(baseUrl, thumb),
        art = buildFullUrl(baseUrl, art),
        banner = buildFullUrl(baseUrl, banner),
        year = year,
        duration = duration,
        viewOffset = viewOffset,
        viewCount = viewCount,
        addedAt = addedAt,
        contentRating = contentRating,
        rating = rating,
        audienceRating = audienceRating,
        studio = studio,
        genres = genres?.map { it.tag } ?: emptyList(),
        directors = directors?.map { it.tag } ?: emptyList(),
        writers = writers?.map { it.tag } ?: emptyList(),
        cast = roles?.map { CastMember(name = it.tag, role = it.role, thumb = buildFullUrl(baseUrl, it.thumb)) } ?: emptyList(),
        librarySectionId = librarySectionId?.toString(),
        librarySectionTitle = librarySectionTitle,
        parentRatingKey = parentRatingKey?.toString(),
        parentTitle = parentTitle,
        grandparentRatingKey = grandparentRatingKey?.toString(),
        grandparentTitle = grandparentTitle,
        grandparentThumb = buildFullUrl(baseUrl, grandparentThumb),
        grandparentArt = buildFullUrl(baseUrl, grandparentArt),
        index = index,
        parentIndex = parentIndex,
        leafCount = leafCount,
        viewedLeafCount = viewedLeafCount,
        childCount = childCount
    )


    private fun SeasonDto.toDomain() = Season(
        id = id,
        ratingKey = ratingKey,
        title = title,
        index = index,
        thumb = thumb,
        leafCount = leafCount,
        viewedLeafCount = viewedLeafCount,
        parentRatingKey = parentRatingKey
    )

    private fun EpisodeDto.toDomain() = Episode(
        id = id,
        ratingKey = ratingKey,
        title = title,
        index = index,
        parentIndex = parentIndex,
        summary = summary,
        thumb = thumb,
        duration = duration,
        viewOffset = viewOffset,
        originallyAvailableAt = originallyAvailableAt,
        parentRatingKey = parentRatingKey,
        grandparentRatingKey = grandparentRatingKey
    )

    // Convert MediaItemDto to Season (for use with /library/metadata/{id}/children)
    private fun MediaItemDto.toSeason(baseUrl: String) = Season(
        id = id,
        ratingKey = ratingKey?.toString(),
        title = title.ifEmpty { "Season ${index ?: 0}" },
        index = index ?: 0,
        thumb = buildFullUrl(baseUrl, thumb),
        leafCount = leafCount,
        viewedLeafCount = viewedLeafCount,
        parentRatingKey = parentRatingKey?.toString()
    )

    // Convert MediaItemDto to Episode (for use with /library/metadata/{id}/children)
    private fun MediaItemDto.toEpisode(baseUrl: String) = Episode(
        id = id,
        ratingKey = ratingKey?.toString(),
        title = title,
        index = index ?: 0,
        parentIndex = parentIndex,
        summary = summary,
        thumb = buildFullUrl(baseUrl, thumb),
        duration = duration,
        viewOffset = viewOffset,
        originallyAvailableAt = originallyAvailableAt,
        parentRatingKey = parentRatingKey?.toString(),
        grandparentRatingKey = grandparentRatingKey?.toString()
    )
}
