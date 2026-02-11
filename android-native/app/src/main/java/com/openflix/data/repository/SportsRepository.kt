package com.openflix.data.repository

import com.openflix.data.remote.api.OpenFlixApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import timber.log.Timber
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Live game data from ESPN
 */
data class LiveGame(
    val id: String,
    val sport: String,
    val league: String,
    val status: String,
    val homeTeam: Team,
    val awayTeam: Team,
    val homeScore: Int,
    val awayScore: Int,
    val period: String,
    val clock: String,
    val isClose: Boolean,
    val isRedZone: Boolean,
    val possession: String?,
    val broadcastInfo: String?
) {
    val isLive: Boolean get() = status == "live"
    val displayScore: String get() = "${awayTeam.code} $awayScore - $homeScore ${homeTeam.code}"
    val shortDisplay: String get() = "${awayTeam.code} $awayScore-$homeScore ${homeTeam.code}"
}

data class Team(
    val code: String,
    val name: String,
    val fullName: String?,
    val logo: String?,
    val record: String?,
    val rank: Int?,
    val conference: String?
)

data class OverlayData(
    val games: List<LiveGame>,
    val lastUpdated: Long?,
    val favoriteCount: Int
)

@Singleton
class SportsRepository @Inject constructor(
    private val api: OpenFlixApi
) {
    private val _games = MutableStateFlow<List<LiveGame>>(emptyList())
    val games: StateFlow<List<LiveGame>> = _games.asStateFlow()

    private val _favoriteTeams = MutableStateFlow<List<String>>(emptyList())
    val favoriteTeams: StateFlow<List<String>> = _favoriteTeams.asStateFlow()

    suspend fun fetchScores(sport: String = "all"): Result<List<LiveGame>> {
        return try {
            val response = api.getSportsScores(sport)
            if (response.isSuccessful) {
                val body = response.body()
                val games = body?.get("games") as? List<*>
                // Parse games from response
                val parsedGames = parseGames(games)
                _games.value = parsedGames
                Result.success(parsedGames)
            } else {
                Result.failure(Exception("Failed to fetch scores"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching sports scores")
            Result.failure(e)
        }
    }

    suspend fun fetchOverlay(maxGames: Int = 5): Result<OverlayData> {
        return try {
            val response = api.getSportsOverlay(maxGames)
            if (response.isSuccessful) {
                val body = response.body()
                val overlay = body?.get("overlay") as? Map<*, *>
                val games = parseGames(overlay?.get("games") as? List<*>)
                val data = OverlayData(
                    games = games,
                    lastUpdated = (overlay?.get("last_updated") as? Number)?.toLong(),
                    favoriteCount = (overlay?.get("favorite_count") as? Number)?.toInt() ?: 0
                )
                _games.value = games
                Result.success(data)
            } else {
                Result.failure(Exception("Failed to fetch overlay"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error fetching sports overlay")
            Result.failure(e)
        }
    }

    suspend fun setFavorites(teams: List<String>): Result<Unit> {
        return try {
            val response = api.setSportsFavorites(mapOf("teams" to teams))
            if (response.isSuccessful) {
                _favoriteTeams.value = teams
                Result.success(Unit)
            } else {
                Result.failure(Exception("Failed to set favorites"))
            }
        } catch (e: Exception) {
            Timber.e(e, "Error setting favorites")
            Result.failure(e)
        }
    }

    private fun parseGames(gamesData: List<*>?): List<LiveGame> {
        if (gamesData == null) return emptyList()

        return gamesData.mapNotNull { item ->
            val map = item as? Map<*, *> ?: return@mapNotNull null
            val homeTeamMap = map["home_team"] as? Map<*, *>
            val awayTeamMap = map["away_team"] as? Map<*, *>

            if (homeTeamMap == null || awayTeamMap == null) return@mapNotNull null

            LiveGame(
                id = map["id"] as? String ?: "",
                sport = map["sport"] as? String ?: "",
                league = map["league"] as? String ?: "",
                status = map["status"] as? String ?: "",
                homeTeam = parseTeam(homeTeamMap),
                awayTeam = parseTeam(awayTeamMap),
                homeScore = (map["home_score"] as? Number)?.toInt() ?: 0,
                awayScore = (map["away_score"] as? Number)?.toInt() ?: 0,
                period = map["period"] as? String ?: "",
                clock = map["clock"] as? String ?: "",
                isClose = map["is_close"] as? Boolean ?: false,
                isRedZone = map["is_red_zone"] as? Boolean ?: false,
                possession = map["possession"] as? String,
                broadcastInfo = map["broadcast_info"] as? String
            )
        }
    }

    private fun parseTeam(map: Map<*, *>): Team {
        return Team(
            code = map["code"] as? String ?: "",
            name = map["name"] as? String ?: "",
            fullName = map["full_name"] as? String,
            logo = map["logo"] as? String,
            record = map["record"] as? String,
            rank = (map["rank"] as? Number)?.toInt(),
            conference = map["conference"] as? String
        )
    }
}
