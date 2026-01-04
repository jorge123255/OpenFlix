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
        return preferencesManager.serverUrl.first() ?: "http://192.168.1.185:32400"
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

                // Load items for each section
                val hubs = sections.mapNotNull { section ->
                    try {
                        val mediaResponse = api.getAllLibraryMedia(
                            libraryId = section.key,
                            start = 0,
                            size = 12  // Load first 12 items for home display
                        )
                        if (mediaResponse.isSuccessful && mediaResponse.body() != null) {
                            val items = mediaResponse.body()!!.mediaContainer?.metadata?.map { it.toDomain(baseUrl) } ?: emptyList()
                            Hub(
                                id = section.key,
                                key = "/library/sections/${section.key}/all",
                                hubKey = section.key,
                                type = section.type,
                                hubType = section.type,
                                title = section.title,
                                style = "shelf",
                                promoted = sections.indexOf(section) == 0,  // First section is promoted
                                size = section.count ?: 0,
                                more = (section.count ?: 0) > 12,
                                items = items
                            )
                        } else {
                            Timber.w("Failed to load items for section ${section.key}")
                            null
                        }
                    } catch (e: Exception) {
                        Timber.e(e, "Error loading items for section ${section.key}")
                        null
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
            val response = api.getShowSeasons(showId)
            if (response.isSuccessful && response.body() != null) {
                val seasons = response.body()!!.map { it.toDomain() }
                Result.success(seasons)
            } else {
                Result.failure(Exception("Failed to get show seasons"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting show seasons: $showId")
            Result.failure(e)
        }
    }

    suspend fun getSeasonEpisodes(seasonId: String): Result<List<Episode>> {
        return try {
            val response = api.getSeasonEpisodes(seasonId)
            if (response.isSuccessful && response.body() != null) {
                val episodes = response.body()!!.map { it.toDomain() }
                Result.success(episodes)
            } else {
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
                val items = response.body()!!.results.map { it.toDomain(baseUrl) }
                Result.success(items)
            } else {
                Result.failure(Exception("Search failed"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error searching: $query")
            Result.failure(e)
        }
    }

    suspend fun updateProgress(mediaId: String, timeMs: Long, durationMs: Long? = null): Result<Unit> {
        return try {
            api.updateProgress(
                ProgressUpdateRequest(
                    key = mediaId,
                    time = timeMs,
                    duration = durationMs,
                    state = "playing"
                )
            )
            Result.success(Unit)
        } catch (e: Exception) {
            Timber.e(e, "Error updating progress: $mediaId")
            Result.failure(e)
        }
    }

    suspend fun getPlaybackUrl(mediaId: String): Result<String> {
        return try {
            val baseUrl = getServerBaseUrl()
            // Get metadata which contains the media file info
            val response = api.getMetadata(mediaId)
            if (response.isSuccessful && response.body() != null) {
                val metadata = response.body()!!.mediaContainer?.metadata?.firstOrNull()
                // Get the first part's key for playback
                val partKey = metadata?.media?.firstOrNull()?.part?.firstOrNull()?.key
                if (partKey != null) {
                    val playbackUrl = baseUrl.trimEnd('/') + partKey
                    Timber.d("Playback URL: $playbackUrl")
                    Result.success(playbackUrl)
                } else {
                    Result.failure(Exception("No playback file found"))
                }
            } else {
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
}
