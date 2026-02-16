package com.openflix.data.repository

import com.openflix.data.local.PreferencesManager
import com.openflix.data.remote.api.OpenFlixApi
import com.openflix.data.remote.dto.*
import com.openflix.domain.model.ArchiveChannelStatus
import com.openflix.domain.model.ArchiveProgram
import com.openflix.domain.model.ArchiveStatus
import com.openflix.domain.model.ArchivedProgramsInfo
import com.openflix.domain.model.CatchUpInfo
import com.openflix.domain.model.CatchUpProgram
import com.openflix.domain.model.Channel
import com.openflix.domain.model.ChannelGroup
import com.openflix.domain.model.ChannelGroupMember
import com.openflix.domain.model.ChannelWithPrograms
import com.openflix.domain.model.DuplicateGroup
import com.openflix.domain.model.EPGChannel
import com.openflix.domain.model.EPGData
import com.openflix.domain.model.OnLaterChannel
import com.openflix.domain.model.OnLaterItem
import com.openflix.domain.model.OnLaterProgram
import com.openflix.domain.model.OnLaterStats
import com.openflix.domain.model.Program
import com.openflix.domain.model.SportsTeam
import com.openflix.domain.model.StartOverInfo
import com.openflix.domain.model.TeamPass
import com.openflix.domain.model.TeamPassStats
import kotlinx.coroutines.flow.first
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Repository for Live TV operations.
 */
@Singleton
class LiveTVRepository @Inject constructor(
    private val api: OpenFlixApi,
    private val preferencesManager: PreferencesManager
) {

    suspend fun getChannels(): Result<List<Channel>> {
        return try {
            val response = api.getLiveTVChannels()
            if (response.isSuccessful && response.body() != null) {
                val channels = response.body()!!.channels.map { it.toDomain() }
                Result.success(channels)
            } else {
                Result.failure(Exception("Failed to get channels"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting channels")
            Result.failure(e)
        }
    }

    suspend fun getGuide(startTime: Long? = null, endTime: Long? = null): Result<List<ChannelWithPrograms>> {
        return try {
            val response = api.getLiveTVGuide(startTime, endTime)
            if (response.isSuccessful && response.body() != null) {
                val guideResponse = response.body()!!
                val programsByChannel = guideResponse.programs ?: emptyMap()

                Timber.d("Guide: ${guideResponse.channels.size} channels, ${programsByChannel.size} program keys")
                if (programsByChannel.isNotEmpty()) {
                    Timber.d("Program keys sample: ${programsByChannel.keys.take(5)}")
                    // Log first program's timestamps
                    val firstProgs = programsByChannel.values.first()
                    if (firstProgs.isNotEmpty()) {
                        val prog = firstProgs.first()
                        Timber.d("First program: ${prog.title}, startIso=${prog.startIso}, startTime=${prog.startTime}")
                    }
                }
                if (guideResponse.channels.isNotEmpty()) {
                    val firstCh = guideResponse.channels.first()
                    Timber.d("First channel: id=${firstCh.id}, channelId=${firstCh.uuid}, name=${firstCh.name}")
                }

                // Combine channels with their programs from the separate map
                // Programs are keyed by channelId (EPG ID like "gracenote-DITV803-10367")
                val guide = guideResponse.channels.map { channelDto ->
                    // Try channelId first (EPG ID), then uuid (tvgId), then database id
                    var programs = channelDto.channelId?.let { programsByChannel[it] }?.map { it.toDomain() } ?: emptyList()

                    if (programs.isEmpty()) {
                        val fallbackId = channelDto.uuid ?: channelDto.id
                        programs = programsByChannel[fallbackId]?.map { it.toDomain() } ?: emptyList()
                    }

                    // Last resort: try database id as string
                    if (programs.isEmpty()) {
                        programs = programsByChannel[channelDto.id]?.map { it.toDomain() } ?: emptyList()
                    }

                    // Debug: log first few channels with program matching
                    if (channelDto.name.contains("CBS") || channelDto.name.contains("NBC")) {
                        Timber.d("Channel ${channelDto.name}: uuid=${channelDto.uuid}, found ${programs.size} programs")
                        if (programs.isNotEmpty()) {
                            val p = programs.first()
                            Timber.d("  First program: ${p.title}, start=${p.startTime}, end=${p.endTime}")
                        }
                    }

                    ChannelWithPrograms(
                        channel = channelDto.toDomain(),
                        programs = programs
                    )
                }

                val withPrograms = guide.count { it.programs.isNotEmpty() }
                Timber.d("Loaded ${guide.size} channels, $withPrograms have programs")

                Result.success(guide)
            } else {
                Result.failure(Exception("Failed to get guide"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting guide")
            Result.failure(e)
        }
    }

    suspend fun getEPG(
        channelIds: List<String>? = null,
        startTime: Long? = null,
        endTime: Long? = null
    ): Result<EPGData> {
        return try {
            val channelIdsStr = channelIds?.joinToString(",")
            val response = api.getEPG(channelIdsStr, startTime, endTime)
            if (response.isSuccessful && response.body() != null) {
                val epgResponse = response.body()!!
                val epgData = EPGData(
                    channels = epgResponse.channels.map { it.toDomain() },
                    startTime = epgResponse.startTime,
                    endTime = epgResponse.endTime
                )
                Result.success(epgData)
            } else {
                Result.failure(Exception("Failed to get EPG"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting EPG")
            Result.failure(e)
        }
    }

    suspend fun getChannelStreamUrl(channelId: String): Result<String> {
        return try {
            val response = api.getChannelStreamUrl(channelId)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.url)
            } else {
                Result.failure(Exception("Failed to get channel stream URL"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting channel stream URL: $channelId")
            Result.failure(e)
        }
    }

    suspend fun updateChannelLogo(channelId: String, logoUrl: String): Result<Channel> {
        return try {
            val request = UpdateChannelRequest(logo = logoUrl)
            val response = api.updateChannel(channelId, request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to update channel logo"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating channel logo: $channelId")
            Result.failure(e)
        }
    }

    suspend fun updateChannel(channelId: String, request: UpdateChannelRequest): Result<Channel> {
        return try {
            val response = api.updateChannel(channelId, request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to update channel"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating channel: $channelId")
            Result.failure(e)
        }
    }

    // ============ Time-Shift / Catch-Up TV ============

    suspend fun getCatchUpPrograms(channelId: String): Result<CatchUpInfo> {
        return try {
            val response = api.getCatchUpPrograms(channelId)
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                val programs = dto.programs.map { it.toDomain() }
                Result.success(
                    CatchUpInfo(
                        programs = programs,
                        bufferStart = parseIsoToUnix(dto.bufferStart),
                        bufferDuration = dto.bufferDuration,
                        isBuffering = dto.isBuffering
                    )
                )
            } else {
                Result.failure(Exception("Failed to get catch-up programs"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting catch-up programs for channel: $channelId")
            Result.failure(e)
        }
    }

    suspend fun getStartOverInfo(channelId: String): Result<StartOverInfo> {
        return try {
            val response = api.getStartOverInfo(channelId)
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                Result.success(dto.toDomain())
            } else {
                Result.failure(Exception("Failed to get start over info"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting start over info for channel: $channelId")
            Result.failure(e)
        }
    }

    suspend fun getTimeshiftStreamUrl(channelId: String, offsetSeconds: Int? = null): Result<String> {
        return try {
            // The timeshift stream URL is just a constructed URL
            val baseUrl = preferencesManager.serverUrl.first()
                ?: return Result.failure(Exception("No server URL"))
            val url = buildString {
                append(baseUrl.trimEnd('/'))
                append("/api/livetv/timeshift/$channelId/stream.m3u8")
                if (offsetSeconds != null) {
                    append("?start=$offsetSeconds")
                }
            }
            Result.success(url)
        } catch (e: Exception) {
            Timber.e(e, "Error building timeshift URL for channel: $channelId")
            Result.failure(e)
        }
    }

    suspend fun startTimeshiftBuffer(channelId: String): Result<Boolean> {
        return try {
            val response = api.startTimeshiftBuffer(channelId)
            if (response.isSuccessful) {
                Timber.d("Started timeshift buffer for channel: $channelId")
                Result.success(true)
            } else {
                Result.failure(Exception("Failed to start timeshift buffer"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error starting timeshift buffer for channel: $channelId")
            Result.failure(e)
        }
    }

    suspend fun stopTimeshiftBuffer(channelId: String): Result<Boolean> {
        return try {
            val response = api.stopTimeshiftBuffer(channelId)
            if (response.isSuccessful) {
                Timber.d("Stopped timeshift buffer for channel: $channelId")
                Result.success(true)
            } else {
                Result.failure(Exception("Failed to stop timeshift buffer"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error stopping timeshift buffer for channel: $channelId")
            Result.failure(e)
        }
    }

    // ============ Archive / Catch-up ============

    suspend fun getArchivedPrograms(channelId: String, limit: Int? = null): Result<ArchivedProgramsInfo> {
        return try {
            val response = api.getArchivedPrograms(channelId, limit)
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                Result.success(
                    ArchivedProgramsInfo(
                        programs = dto.programs.map { it.toDomain() },
                        isArchiving = dto.isArchiving,
                        archiveStart = parseIsoToUnix(dto.archiveStart),
                        retentionDays = dto.retentionDays
                    )
                )
            } else {
                Result.failure(Exception("Failed to get archived programs"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting archived programs for channel: $channelId")
            Result.failure(e)
        }
    }

    suspend fun enableChannelArchive(channelId: String, days: Int = 7): Result<Boolean> {
        return try {
            val response = api.enableChannelArchive(channelId, EnableArchiveRequest(days))
            if (response.isSuccessful) {
                Timber.d("Enabled archive for channel: $channelId, retention: $days days")
                Result.success(true)
            } else {
                Result.failure(Exception("Failed to enable channel archive"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error enabling archive for channel: $channelId")
            Result.failure(e)
        }
    }

    suspend fun disableChannelArchive(channelId: String): Result<Boolean> {
        return try {
            val response = api.disableChannelArchive(channelId)
            if (response.isSuccessful) {
                Timber.d("Disabled archive for channel: $channelId")
                Result.success(true)
            } else {
                Result.failure(Exception("Failed to disable channel archive"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error disabling archive for channel: $channelId")
            Result.failure(e)
        }
    }

    suspend fun getArchiveStatus(): Result<ArchiveStatus> {
        return try {
            val response = api.getArchiveStatus()
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                Result.success(
                    ArchiveStatus(
                        channels = dto.channels.map {
                            ArchiveChannelStatus(
                                channelId = it.channelId,
                                channelName = it.channelName,
                                isArchiving = it.isArchiving,
                                archiveStart = parseIsoToUnix(it.archiveStart),
                                retentionDays = it.retentionDays,
                                programCount = it.programCount
                            )
                        },
                        totalChannels = dto.totalChannels,
                        activeRecording = dto.activeRecording
                    )
                )
            } else {
                Result.failure(Exception("Failed to get archive status"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting archive status")
            Result.failure(e)
        }
    }

    suspend fun getArchiveStreamUrl(archiveProgramId: Int): Result<String> {
        return try {
            val baseUrl = preferencesManager.serverUrl.first()
                ?: return Result.failure(Exception("No server URL"))
            val url = "${baseUrl.trimEnd('/')}/api/livetv/archive/$archiveProgramId/stream.m3u8"
            Result.success(url)
        } catch (e: Exception) {
            Timber.e(e, "Error building archive stream URL")
            Result.failure(e)
        }
    }

    private fun ArchiveProgramDto.toDomain() = ArchiveProgram(
        id = id,
        channelId = channelId,
        programId = programId,
        title = title,
        description = description,
        startTime = parseIsoToUnix(startTime) ?: 0,
        endTime = parseIsoToUnix(endTime) ?: 0,
        duration = duration,
        icon = icon,
        category = category,
        status = status,
        expiresAt = parseIsoToUnix(expiresAt) ?: 0
    )

    private fun parseIsoToUnix(iso: String?): Long? {
        if (iso.isNullOrBlank()) return null
        return try {
            java.time.Instant.parse(iso).epochSecond
        } catch (e: Exception) {
            null
        }
    }

    private fun CatchUpProgramDto.toDomain() = CatchUpProgram(
        id = id,
        programId = programId,
        channelId = channelId,
        title = title,
        startTime = parseIsoToUnix(startTime) ?: 0L,
        endTime = parseIsoToUnix(endTime) ?: 0L,
        duration = duration,
        description = description,
        thumb = thumb,
        available = available
    )

    private fun StartOverInfoDto.toDomain() = StartOverInfo(
        available = available,
        streamUrl = streamUrl,
        programTitle = program?.title,
        programSubtitle = program?.subtitle,
        programThumb = program?.thumb,
        secondsIntoProgram = secondsIntoProgram ?: 0L,
        isBuffering = isBuffering
    )

    // Conversion extensions
    private fun ChannelDto.toDomain() = Channel(
        id = id,
        uuid = uuid,
        number = number?.toString(),  // Server sends int, convert to String
        name = name,
        title = title,
        callsign = callsign,
        logo = logo,
        thumb = thumb,
        art = art,
        source = source,
        sourceName = sourceName,  // Provider name from M3U source
        hd = hd ?: false,
        favorite = favorite ?: false,
        hidden = hidden,  // Now computed property from DTO (enabled == false)
        group = group,
        category = category,
        streamUrl = streamUrl,
        nowPlaying = nowPlaying?.toDomain(),
        upNext = upNext?.toDomain(),
        archiveEnabled = archiveEnabled ?: false,
        archiveDays = archiveDays ?: 7
    )

    private fun ProgramDto.toDomain() = Program(
        id = id,
        title = title,
        subtitle = subtitle,
        description = description,
        startTime = startTime,
        endTime = endTime,
        duration = duration,
        thumb = thumb,
        art = art,
        rating = rating,
        genres = genres ?: emptyList(),
        episodeTitle = episodeTitle,
        seasonNumber = seasonNumber,
        episodeNumber = episodeNumber,
        originalAirDate = originalAirDate,
        isNew = isNew ?: false,
        isLive = isLive ?: false,
        isPremiere = isPremiere ?: false,
        isFinale = isFinale ?: false,
        isRepeat = isRepeat ?: false,
        isMovie = isMovie ?: false,
        isSports = isSports ?: false,
        isKids = isKids ?: false,
        hasRecording = hasRecording ?: false,
        recordingId = recordingId,
        seriesId = seriesId,
        programId = programId,
        gracenoteId = gracenoteId
    )

    private fun ChannelWithProgramsDto.toDomain() = ChannelWithPrograms(
        channel = channel.toDomain(),
        programs = programs.map { it.toDomain() }
    )

    private fun EPGChannelDto.toDomain() = EPGChannel(
        id = id,
        name = name,
        number = number,
        logo = logo,
        programs = programs?.map { it.toDomain() } ?: emptyList()
    )

    // ============ On Later ============

    suspend fun getOnLaterStats(): Result<OnLaterStats> {
        return try {
            val response = api.getOnLaterStats()
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                Result.success(OnLaterStats(
                    movies = dto.movies,
                    sports = dto.sports,
                    kids = dto.kids,
                    news = dto.news,
                    premieres = dto.premieres
                ))
            } else {
                Result.failure(Exception("Failed to get On Later stats"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting On Later stats")
            Result.failure(e)
        }
    }

    suspend fun getOnLaterTonight(): Result<List<OnLaterItem>> {
        return try {
            val response = api.getOnLaterTonight()
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain() }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get tonight's programs"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting tonight's programs")
            Result.failure(e)
        }
    }

    suspend fun getOnLaterMovies(hours: Int? = null): Result<List<OnLaterItem>> {
        return try {
            val response = api.getOnLaterMovies(hours)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain() }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get upcoming movies"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting upcoming movies")
            Result.failure(e)
        }
    }

    suspend fun getOnLaterSports(hours: Int? = null, league: String? = null, team: String? = null): Result<List<OnLaterItem>> {
        return try {
            val response = api.getOnLaterSports(hours, league, team)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain() }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get upcoming sports"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting upcoming sports")
            Result.failure(e)
        }
    }

    suspend fun getOnLaterKids(hours: Int? = null): Result<List<OnLaterItem>> {
        return try {
            val response = api.getOnLaterKids(hours)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain() }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get kids programs"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting kids programs")
            Result.failure(e)
        }
    }

    suspend fun getOnLaterNews(hours: Int? = null): Result<List<OnLaterItem>> {
        return try {
            val response = api.getOnLaterNews(hours)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain() }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get news programs"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting news programs")
            Result.failure(e)
        }
    }

    suspend fun getOnLaterPremieres(hours: Int? = null): Result<List<OnLaterItem>> {
        return try {
            val response = api.getOnLaterPremieres(hours)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain() }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get premieres"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting premieres")
            Result.failure(e)
        }
    }

    suspend fun getOnLaterWeek(category: String? = null): Result<List<OnLaterItem>> {
        return try {
            val response = api.getOnLaterWeek(category)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain() }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to get week's programs"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting week's programs")
            Result.failure(e)
        }
    }

    suspend fun searchOnLater(query: String): Result<List<OnLaterItem>> {
        return try {
            val response = api.searchOnLater(query)
            if (response.isSuccessful && response.body() != null) {
                val items = response.body()!!.items.map { it.toDomain() }
                Result.success(items)
            } else {
                Result.failure(Exception("Failed to search On Later"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error searching On Later: $query")
            Result.failure(e)
        }
    }

    suspend fun getOnLaterLeagues(): Result<List<String>> {
        return try {
            val response = api.getOnLaterLeagues()
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.leagues)
            } else {
                Result.failure(Exception("Failed to get leagues"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting leagues")
            Result.failure(e)
        }
    }

    private fun OnLaterItemDto.toDomain() = OnLaterItem(
        program = program.toDomain(),
        channel = channel?.toDomain(),
        hasRecording = hasRecording,
        recordingId = recordingId
    )

    private fun OnLaterProgramDto.toDomain() = OnLaterProgram(
        id = id,
        channelId = channelId,
        title = title,
        subtitle = subtitle,
        description = description,
        start = parseIsoToUnix(start) ?: 0L,
        end = parseIsoToUnix(end) ?: 0L,
        icon = icon,
        art = art,
        category = category,
        isMovie = isMovie,
        isSports = isSports,
        isKids = isKids,
        isNews = isNews,
        isPremiere = isPremiere,
        isNew = isNew,
        isLive = isLive,
        teams = teams,
        league = league,
        rating = rating
    )

    private fun OnLaterChannelDto.toDomain() = OnLaterChannel(
        id = id,
        name = name,
        logo = logo,
        number = number
    )

    // ============ Team Pass ============

    suspend fun getTeamPasses(): Result<List<TeamPass>> {
        return try {
            val response = api.getTeamPasses()
            if (response.isSuccessful && response.body() != null) {
                val passes = response.body()!!.teamPasses.map { it.toDomain() }
                Result.success(passes)
            } else {
                Result.failure(Exception("Failed to get team passes"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting team passes")
            Result.failure(e)
        }
    }

    suspend fun getTeamPassStats(): Result<TeamPassStats> {
        return try {
            val response = api.getTeamPassStats()
            if (response.isSuccessful && response.body() != null) {
                val dto = response.body()!!
                Result.success(TeamPassStats(
                    totalPasses = dto.totalPasses,
                    activePasses = dto.activePasses,
                    upcomingGames = dto.upcomingGames,
                    scheduledRecordings = dto.scheduledRecordings
                ))
            } else {
                Result.failure(Exception("Failed to get team pass stats"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting team pass stats")
            Result.failure(e)
        }
    }

    suspend fun getTeamPassUpcoming(id: Long): Result<List<OnLaterItem>> {
        return try {
            val response = api.getTeamPassUpcoming(id)
            if (response.isSuccessful && response.body() != null) {
                val games = response.body()!!.games?.map { it.toDomain() } ?: emptyList()
                Result.success(games)
            } else {
                Result.failure(Exception("Failed to get upcoming games"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting upcoming games for team pass: $id")
            Result.failure(e)
        }
    }

    suspend fun createTeamPass(
        teamName: String,
        league: String,
        prePadding: Int = 5,
        postPadding: Int = 60,
        keepCount: Int = 0
    ): Result<TeamPass> {
        return try {
            val request = TeamPassRequest(
                teamName = teamName,
                league = league,
                prePadding = prePadding,
                postPadding = postPadding,
                keepCount = keepCount
            )
            val response = api.createTeamPass(request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to create team pass"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error creating team pass")
            Result.failure(e)
        }
    }

    suspend fun updateTeamPass(
        id: Long,
        teamName: String,
        league: String,
        prePadding: Int,
        postPadding: Int,
        keepCount: Int,
        enabled: Boolean
    ): Result<TeamPass> {
        return try {
            val request = TeamPassRequest(
                teamName = teamName,
                league = league,
                prePadding = prePadding,
                postPadding = postPadding,
                keepCount = keepCount,
                enabled = enabled
            )
            val response = api.updateTeamPass(id, request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to update team pass"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating team pass: $id")
            Result.failure(e)
        }
    }

    suspend fun deleteTeamPass(id: Long): Result<Unit> {
        return try {
            val response = api.deleteTeamPass(id)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to delete team pass"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error deleting team pass: $id")
            Result.failure(e)
        }
    }

    suspend fun toggleTeamPass(id: Long): Result<TeamPass> {
        return try {
            val response = api.toggleTeamPass(id)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to toggle team pass"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error toggling team pass: $id")
            Result.failure(e)
        }
    }

    suspend fun getSportsLeagues(): Result<List<String>> {
        return try {
            val response = api.getSportsLeagues()
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.leagues)
            } else {
                Result.failure(Exception("Failed to get sports leagues"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting sports leagues")
            Result.failure(e)
        }
    }

    suspend fun getLeagueTeams(league: String): Result<List<SportsTeam>> {
        return try {
            val response = api.getLeagueTeams(league)
            if (response.isSuccessful && response.body() != null) {
                val teams = response.body()!!.teams.map { it.toDomain() }
                Result.success(teams)
            } else {
                Result.failure(Exception("Failed to get teams for league"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting teams for league: $league")
            Result.failure(e)
        }
    }

    suspend fun searchSportsTeams(query: String): Result<List<SportsTeam>> {
        return try {
            val response = api.searchSportsTeams(query)
            if (response.isSuccessful && response.body() != null) {
                val teams = response.body()!!.teams.map { it.toDomain() }
                Result.success(teams)
            } else {
                Result.failure(Exception("Failed to search teams"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error searching teams: $query")
            Result.failure(e)
        }
    }

    private fun TeamPassDto.toDomain() = TeamPass(
        id = id,
        userId = userId,
        teamName = teamName,
        teamAliases = teamAliases,
        league = league,
        channelIds = channelIds,
        prePadding = prePadding,
        postPadding = postPadding,
        keepCount = keepCount,
        priority = priority,
        enabled = enabled,
        upcomingCount = upcomingCount,
        logoUrl = logoUrl
    )

    private fun SportsTeamDto.toDomain() = SportsTeam(
        name = name,
        city = city,
        nickname = nickname,
        league = league,
        aliases = aliases ?: emptyList(),
        logoUrl = logoUrl
    )

    // ============ Channel Groups (Failover) ============

    suspend fun getChannelGroups(): Result<List<ChannelGroup>> {
        return try {
            val response = api.getChannelGroups()
            if (response.isSuccessful && response.body() != null) {
                val groups = response.body()!!.groups.map { it.toDomain() }
                Result.success(groups)
            } else {
                Result.failure(Exception("Failed to get channel groups"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting channel groups")
            Result.failure(e)
        }
    }

    suspend fun createChannelGroup(
        name: String,
        displayNumber: Int,
        logo: String? = null,
        channelId: String? = null
    ): Result<ChannelGroup> {
        return try {
            val request = CreateChannelGroupRequest(
                name = name,
                displayNumber = displayNumber,
                logo = logo,
                channelId = channelId
            )
            val response = api.createChannelGroup(request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to create channel group"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error creating channel group")
            Result.failure(e)
        }
    }

    suspend fun updateChannelGroup(
        groupId: Int,
        name: String? = null,
        displayNumber: Int? = null,
        logo: String? = null,
        channelId: String? = null,
        enabled: Boolean? = null
    ): Result<ChannelGroup> {
        return try {
            val request = UpdateChannelGroupRequest(
                name = name,
                displayNumber = displayNumber,
                logo = logo,
                channelId = channelId,
                enabled = enabled
            )
            val response = api.updateChannelGroup(groupId, request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to update channel group"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating channel group: $groupId")
            Result.failure(e)
        }
    }

    suspend fun deleteChannelGroup(groupId: Int): Result<Unit> {
        return try {
            val response = api.deleteChannelGroup(groupId)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to delete channel group"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error deleting channel group: $groupId")
            Result.failure(e)
        }
    }

    suspend fun addChannelToGroup(groupId: Int, channelId: Int, priority: Int = 0): Result<ChannelGroupMember> {
        return try {
            val request = AddGroupMemberRequest(channelId = channelId, priority = priority)
            val response = api.addChannelToGroup(groupId, request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to add channel to group"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error adding channel $channelId to group $groupId")
            Result.failure(e)
        }
    }

    suspend fun updateGroupMemberPriority(groupId: Int, channelId: Int, priority: Int): Result<ChannelGroupMember> {
        return try {
            val request = UpdateGroupMemberPriorityRequest(priority = priority)
            val response = api.updateGroupMemberPriority(groupId, channelId, request)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.toDomain())
            } else {
                Result.failure(Exception("Failed to update member priority"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error updating priority for channel $channelId in group $groupId")
            Result.failure(e)
        }
    }

    suspend fun removeChannelFromGroup(groupId: Int, channelId: Int): Result<Unit> {
        return try {
            val response = api.removeChannelFromGroup(groupId, channelId)
            if (response.isSuccessful) {
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to remove channel from group"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error removing channel $channelId from group $groupId")
            Result.failure(e)
        }
    }

    suspend fun autoDetectDuplicates(): Result<List<DuplicateGroup>> {
        return try {
            val response = api.autoDetectDuplicates()
            if (response.isSuccessful && response.body() != null) {
                val duplicates = response.body()!!.groups.map { dto ->
                    DuplicateGroup(
                        name = dto.name,
                        channels = dto.channels.map { it.toDomain() }
                    )
                }
                Result.success(duplicates)
            } else {
                Result.failure(Exception("Failed to auto-detect duplicates"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error auto-detecting duplicates")
            Result.failure(e)
        }
    }

    suspend fun getChannelGroupStreamUrl(groupId: Int): Result<String> {
        return try {
            val response = api.getChannelGroupStreamUrl(groupId)
            if (response.isSuccessful && response.body() != null) {
                Result.success(response.body()!!.url)
            } else {
                Result.failure(Exception("Failed to get channel group stream URL"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error getting channel group stream URL: $groupId")
            Result.failure(e)
        }
    }

    private fun ChannelGroupDto.toDomain() = ChannelGroup(
        id = id,
        name = name,
        displayNumber = displayNumber,
        logo = logo,
        channelId = channelId,
        enabled = enabled,
        members = members?.map { it.toDomain() } ?: emptyList(),
        createdAt = parseIsoToUnix(createdAt),
        updatedAt = parseIsoToUnix(updatedAt)
    )

    private fun ChannelGroupMemberDto.toDomain() = ChannelGroupMember(
        id = id,
        channelGroupId = channelGroupId,
        channelId = channelId,
        priority = priority,
        createdAt = parseIsoToUnix(createdAt),
        channel = channel?.toDomain()
    )

    private fun ChannelGroupChannelDto.toDomain() = Channel(
        id = id.toString(),
        uuid = null,
        number = null,
        name = name,
        title = null,
        callsign = null,
        logo = logo,
        thumb = null,
        art = null,
        source = null,
        sourceName = sourceName,
        hd = false,
        favorite = false,
        hidden = false,
        group = null,
        category = null,
        streamUrl = streamUrl,
        nowPlaying = null,
        upNext = null,
        archiveEnabled = false,
        archiveDays = 7
    )
}
