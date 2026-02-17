package com.openflix.data.remote.api

import com.openflix.data.remote.dto.*
import retrofit2.Response
import retrofit2.http.*

/**
 * TMDB API interface for fetching movie/TV metadata and trailers.
 * Base URL: https://api.themoviedb.org/3/
 */
interface TmdbApi {

    @GET("movie/{id}/videos")
    suspend fun getMovieVideos(
        @Path("id") movieId: Int,
        @Query("api_key") apiKey: String
    ): Response<TmdbVideosResponse>

    @GET("movie/{id}")
    suspend fun getMovieDetails(
        @Path("id") movieId: Int,
        @Query("api_key") apiKey: String,
        @Query("append_to_response") appendTo: String = "credits"
    ): Response<TmdbMovieDetailsDto>

    @GET("search/movie")
    suspend fun searchMovie(
        @Query("api_key") apiKey: String,
        @Query("query") query: String,
        @Query("year") year: Int? = null
    ): Response<TmdbSearchResponse>

    @GET("tv/{id}/videos")
    suspend fun getTVVideos(
        @Path("id") tvId: Int,
        @Query("api_key") apiKey: String
    ): Response<TmdbVideosResponse>

    @GET("tv/{id}")
    suspend fun getTVDetails(
        @Path("id") tvId: Int,
        @Query("api_key") apiKey: String,
        @Query("append_to_response") appendTo: String = "credits"
    ): Response<TmdbTVDetailsDto>

    @GET("search/tv")
    suspend fun searchTV(
        @Query("api_key") apiKey: String,
        @Query("query") query: String,
        @Query("first_air_date_year") year: Int? = null
    ): Response<TmdbTVSearchResponse>
}
