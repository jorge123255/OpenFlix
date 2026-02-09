package com.openflix.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * TMDB API response DTOs
 */

data class TmdbVideosResponse(
    @SerializedName("id") val id: Int,
    @SerializedName("results") val results: List<TmdbVideoDto>
)

data class TmdbVideoDto(
    @SerializedName("id") val id: String,
    @SerializedName("key") val key: String,  // YouTube video ID
    @SerializedName("name") val name: String,
    @SerializedName("site") val site: String,
    @SerializedName("type") val type: String,  // Trailer, Teaser, Featurette, etc.
    @SerializedName("official") val official: Boolean?,
    @SerializedName("published_at") val publishedAt: String?,
    @SerializedName("iso_639_1") val language: String?
)

data class TmdbMovieDetailsDto(
    @SerializedName("id") val id: Int,
    @SerializedName("title") val title: String?,
    @SerializedName("overview") val overview: String?,
    @SerializedName("backdrop_path") val backdropPath: String?,
    @SerializedName("poster_path") val posterPath: String?,
    @SerializedName("genres") val genres: List<TmdbGenreDto>?,
    @SerializedName("credits") val credits: TmdbCreditsDto?,
    @SerializedName("release_date") val releaseDate: String?,
    @SerializedName("runtime") val runtime: Int?,
    @SerializedName("vote_average") val voteAverage: Double?
)

data class TmdbTVDetailsDto(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String?,
    @SerializedName("overview") val overview: String?,
    @SerializedName("backdrop_path") val backdropPath: String?,
    @SerializedName("poster_path") val posterPath: String?,
    @SerializedName("genres") val genres: List<TmdbGenreDto>?,
    @SerializedName("credits") val credits: TmdbCreditsDto?,
    @SerializedName("first_air_date") val firstAirDate: String?,
    @SerializedName("number_of_seasons") val numberOfSeasons: Int?,
    @SerializedName("vote_average") val voteAverage: Double?
)

data class TmdbGenreDto(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String
)

data class TmdbCreditsDto(
    @SerializedName("cast") val cast: List<TmdbCastDto>?,
    @SerializedName("crew") val crew: List<TmdbCrewDto>?
)

data class TmdbCastDto(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("character") val character: String?,
    @SerializedName("profile_path") val profilePath: String?,
    @SerializedName("order") val order: Int?
)

data class TmdbCrewDto(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String,
    @SerializedName("job") val job: String?,
    @SerializedName("department") val department: String?,
    @SerializedName("profile_path") val profilePath: String?
)

data class TmdbSearchResponse(
    @SerializedName("page") val page: Int,
    @SerializedName("results") val results: List<TmdbSearchResultDto>,
    @SerializedName("total_results") val totalResults: Int,
    @SerializedName("total_pages") val totalPages: Int
)

data class TmdbSearchResultDto(
    @SerializedName("id") val id: Int,
    @SerializedName("title") val title: String?,
    @SerializedName("original_title") val originalTitle: String?,
    @SerializedName("overview") val overview: String?,
    @SerializedName("backdrop_path") val backdropPath: String?,
    @SerializedName("poster_path") val posterPath: String?,
    @SerializedName("release_date") val releaseDate: String?,
    @SerializedName("vote_average") val voteAverage: Double?
)

data class TmdbTVSearchResponse(
    @SerializedName("page") val page: Int,
    @SerializedName("results") val results: List<TmdbTVSearchResultDto>,
    @SerializedName("total_results") val totalResults: Int,
    @SerializedName("total_pages") val totalPages: Int
)

data class TmdbTVSearchResultDto(
    @SerializedName("id") val id: Int,
    @SerializedName("name") val name: String?,
    @SerializedName("original_name") val originalName: String?,
    @SerializedName("overview") val overview: String?,
    @SerializedName("backdrop_path") val backdropPath: String?,
    @SerializedName("poster_path") val posterPath: String?,
    @SerializedName("first_air_date") val firstAirDate: String?,
    @SerializedName("vote_average") val voteAverage: Double?
)

/**
 * Server settings DTO for fetching TMDB API key from server
 */
data class ServerSettingsResponse(
    @SerializedName("settings") val settings: ServerSettingsDto?
)

data class ServerSettingsDto(
    @SerializedName("tmdbApiKey") val tmdbApiKey: String?
)
