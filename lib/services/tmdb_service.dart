import 'package:dio/dio.dart';
import '../utils/app_logger.dart';
import 'settings_service.dart';

/// TMDB API service for fetching trailers and additional metadata
class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static TmdbService? _instance;

  String? _apiKey;
  final Dio _dio = Dio();

  TmdbService._();

  static Future<TmdbService> getInstance() async {
    if (_instance == null) {
      _instance = TmdbService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    final settings = await SettingsService.getInstance();
    _apiKey = settings.getTmdbApiKey();
  }

  /// Refresh API key from settings
  Future<void> refreshApiKey() async {
    final settings = await SettingsService.getInstance();
    _apiKey = settings.getTmdbApiKey();
  }

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// Search for a movie by title and year
  Future<int?> searchMovie(String title, {int? year}) async {
    if (!hasApiKey) return null;

    try {
      final response = await _dio.get(
        '$_baseUrl/search/movie',
        queryParameters: {
          'api_key': _apiKey,
          'query': title,
          if (year != null) 'year': year,
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results.first['id'] as int?;
        }
      }
    } catch (e) {
      appLogger.w('TMDB movie search failed', error: e);
    }
    return null;
  }

  /// Search for a TV show by title
  Future<int?> searchTvShow(String title, {int? year}) async {
    if (!hasApiKey) return null;

    try {
      final response = await _dio.get(
        '$_baseUrl/search/tv',
        queryParameters: {
          'api_key': _apiKey,
          'query': title,
          if (year != null) 'first_air_date_year': year,
        },
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results.first['id'] as int?;
        }
      }
    } catch (e) {
      appLogger.w('TMDB TV search failed', error: e);
    }
    return null;
  }

  /// Get trailers for a movie
  Future<List<TrailerInfo>> getMovieTrailers(int movieId) async {
    if (!hasApiKey) return [];

    try {
      final response = await _dio.get(
        '$_baseUrl/movie/$movieId/videos',
        queryParameters: {'api_key': _apiKey},
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null) {
          return results
              .where((v) =>
                  v['site'] == 'YouTube' &&
                  (v['type'] == 'Trailer' || v['type'] == 'Teaser'))
              .map((v) => TrailerInfo.fromJson(v as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      appLogger.w('TMDB movie trailers failed', error: e);
    }
    return [];
  }

  /// Get trailers for a TV show
  Future<List<TrailerInfo>> getTvTrailers(int tvId) async {
    if (!hasApiKey) return [];

    try {
      final response = await _dio.get(
        '$_baseUrl/tv/$tvId/videos',
        queryParameters: {'api_key': _apiKey},
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null) {
          return results
              .where((v) =>
                  v['site'] == 'YouTube' &&
                  (v['type'] == 'Trailer' || v['type'] == 'Teaser'))
              .map((v) => TrailerInfo.fromJson(v as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      appLogger.w('TMDB TV trailers failed', error: e);
    }
    return [];
  }

  /// Get trailer for content by title
  Future<TrailerInfo?> getTrailerForTitle(
    String title, {
    bool isMovie = true,
    int? year,
  }) async {
    if (!hasApiKey) return null;

    try {
      final id = isMovie
          ? await searchMovie(title, year: year)
          : await searchTvShow(title, year: year);

      if (id == null) return null;

      final trailers = isMovie
          ? await getMovieTrailers(id)
          : await getTvTrailers(id);

      if (trailers.isNotEmpty) {
        // Prefer official trailers
        final official = trailers.where((t) => t.official).toList();
        return official.isNotEmpty ? official.first : trailers.first;
      }
    } catch (e) {
      appLogger.w('Failed to get trailer for $title', error: e);
    }
    return null;
  }

  /// Get full movie details including cast, ratings, and genres
  Future<TmdbMovieDetails?> getMovieDetails(int movieId) async {
    if (!hasApiKey) return null;

    try {
      final response = await _dio.get(
        '$_baseUrl/movie/$movieId',
        queryParameters: {
          'api_key': _apiKey,
          'append_to_response': 'credits,release_dates,external_ids',
        },
      );

      if (response.statusCode == 200) {
        return TmdbMovieDetails.fromJson(response.data);
      }
    } catch (e) {
      appLogger.w('TMDB movie details failed', error: e);
    }
    return null;
  }

  /// Get full TV show details including cast, ratings, and genres
  Future<TmdbTvDetails?> getTvDetails(int tvId) async {
    if (!hasApiKey) return null;

    try {
      final response = await _dio.get(
        '$_baseUrl/tv/$tvId',
        queryParameters: {
          'api_key': _apiKey,
          'append_to_response': 'credits,content_ratings,external_ids',
        },
      );

      if (response.statusCode == 200) {
        return TmdbTvDetails.fromJson(response.data);
      }
    } catch (e) {
      appLogger.w('TMDB TV details failed', error: e);
    }
    return null;
  }

  /// Get enriched metadata for content by title
  Future<TmdbEnrichedMetadata?> getEnrichedMetadata(
    String title, {
    bool isMovie = true,
    int? year,
  }) async {
    if (!hasApiKey) return null;

    try {
      final id = isMovie
          ? await searchMovie(title, year: year)
          : await searchTvShow(title, year: year);

      if (id == null) return null;

      if (isMovie) {
        final details = await getMovieDetails(id);
        final trailers = await getMovieTrailers(id);
        if (details != null) {
          return TmdbEnrichedMetadata(
            id: id,
            imdbId: details.imdbId,
            title: details.title,
            overview: details.overview,
            genres: details.genres,
            cast: details.cast.take(10).toList(),
            crew: details.crew.take(5).toList(),
            rating: details.contentRating,
            posterPath: details.posterPath,
            backdropPath: details.backdropPath,
            releaseDate: details.releaseDate,
            runtime: details.runtime,
            voteAverage: details.voteAverage,
            trailers: trailers,
          );
        }
      } else {
        final details = await getTvDetails(id);
        final trailers = await getTvTrailers(id);
        if (details != null) {
          return TmdbEnrichedMetadata(
            id: id,
            imdbId: details.imdbId,
            title: details.name,
            overview: details.overview,
            genres: details.genres,
            cast: details.cast.take(10).toList(),
            crew: details.crew.take(5).toList(),
            rating: details.contentRating,
            posterPath: details.posterPath,
            backdropPath: details.backdropPath,
            releaseDate: details.firstAirDate,
            runtime: details.episodeRunTime.isNotEmpty ? details.episodeRunTime.first : null,
            voteAverage: details.voteAverage,
            trailers: trailers,
          );
        }
      }
    } catch (e) {
      appLogger.w('Failed to get enriched metadata for $title', error: e);
    }
    return null;
  }
}

/// Information about a trailer
class TrailerInfo {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;
  final bool official;

  TrailerInfo({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    required this.official,
  });

  factory TrailerInfo.fromJson(Map<String, dynamic> json) {
    return TrailerInfo(
      id: json['id']?.toString() ?? '',
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      site: json['site'] ?? '',
      type: json['type'] ?? '',
      official: json['official'] ?? false,
    );
  }

  /// Get YouTube thumbnail URL
  String get thumbnailUrl => 'https://img.youtube.com/vi/$key/hqdefault.jpg';

  /// Get YouTube embed URL
  String get embedUrl => 'https://www.youtube.com/embed/$key?autoplay=1';

  /// Get YouTube watch URL
  String get watchUrl => 'https://www.youtube.com/watch?v=$key';
}

/// Movie details from TMDB
class TmdbMovieDetails {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final int? runtime;
  final double? voteAverage;
  final String? imdbId;
  final List<String> genres;
  final List<TmdbCastMember> cast;
  final List<TmdbCrewMember> crew;
  final String? contentRating;

  TmdbMovieDetails({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.runtime,
    this.voteAverage,
    this.imdbId,
    this.genres = const [],
    this.cast = const [],
    this.crew = const [],
    this.contentRating,
  });

  factory TmdbMovieDetails.fromJson(Map<String, dynamic> json) {
    // Extract genres
    final genreList = (json['genres'] as List?)
        ?.map((g) => g['name'] as String)
        .toList() ?? [];

    // Extract cast
    final credits = json['credits'] as Map<String, dynamic>?;
    final castList = (credits?['cast'] as List?)
        ?.map((c) => TmdbCastMember.fromJson(c))
        .toList() ?? [];
    final crewList = (credits?['crew'] as List?)
        ?.map((c) => TmdbCrewMember.fromJson(c))
        .toList() ?? [];

    // Extract US content rating
    String? rating;
    final releaseDates = json['release_dates'] as Map<String, dynamic>?;
    if (releaseDates != null) {
      final results = releaseDates['results'] as List?;
      if (results != null) {
        for (final region in results) {
          if (region['iso_3166_1'] == 'US') {
            final releases = region['release_dates'] as List?;
            if (releases != null && releases.isNotEmpty) {
              rating = releases.first['certification'] as String?;
              break;
            }
          }
        }
      }
    }

    // Extract IMDB ID
    final externalIds = json['external_ids'] as Map<String, dynamic>?;
    final imdbId = externalIds?['imdb_id'] as String?;

    return TmdbMovieDetails(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'],
      runtime: json['runtime'],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      imdbId: imdbId,
      genres: genreList,
      cast: castList,
      crew: crewList,
      contentRating: rating,
    );
  }

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : null;
}

/// TV show details from TMDB
class TmdbTvDetails {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? firstAirDate;
  final List<int> episodeRunTime;
  final double? voteAverage;
  final String? imdbId;
  final List<String> genres;
  final List<TmdbCastMember> cast;
  final List<TmdbCrewMember> crew;
  final String? contentRating;

  TmdbTvDetails({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.firstAirDate,
    this.episodeRunTime = const [],
    this.voteAverage,
    this.imdbId,
    this.genres = const [],
    this.cast = const [],
    this.crew = const [],
    this.contentRating,
  });

  factory TmdbTvDetails.fromJson(Map<String, dynamic> json) {
    // Extract genres
    final genreList = (json['genres'] as List?)
        ?.map((g) => g['name'] as String)
        .toList() ?? [];

    // Extract cast
    final credits = json['credits'] as Map<String, dynamic>?;
    final castList = (credits?['cast'] as List?)
        ?.map((c) => TmdbCastMember.fromJson(c))
        .toList() ?? [];
    final crewList = (credits?['crew'] as List?)
        ?.map((c) => TmdbCrewMember.fromJson(c))
        .toList() ?? [];

    // Extract US content rating
    String? rating;
    final contentRatings = json['content_ratings'] as Map<String, dynamic>?;
    if (contentRatings != null) {
      final results = contentRatings['results'] as List?;
      if (results != null) {
        for (final region in results) {
          if (region['iso_3166_1'] == 'US') {
            rating = region['rating'] as String?;
            break;
          }
        }
      }
    }

    // Extract IMDB ID
    final externalIds = json['external_ids'] as Map<String, dynamic>?;
    final imdbId = externalIds?['imdb_id'] as String?;

    return TmdbTvDetails(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      firstAirDate: json['first_air_date'],
      episodeRunTime: (json['episode_run_time'] as List?)
          ?.map((e) => e as int)
          .toList() ?? [],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      imdbId: imdbId,
      genres: genreList,
      cast: castList,
      crew: crewList,
      contentRating: rating,
    );
  }

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : null;
}

/// Cast member from TMDB credits
class TmdbCastMember {
  final int id;
  final String name;
  final String? character;
  final String? profilePath;

  TmdbCastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
  });

  factory TmdbCastMember.fromJson(Map<String, dynamic> json) {
    return TmdbCastMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      character: json['character'],
      profilePath: json['profile_path'],
    );
  }

  String? get profileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : null;
}

/// Crew member from TMDB credits
class TmdbCrewMember {
  final int id;
  final String name;
  final String? job;
  final String? department;
  final String? profilePath;

  TmdbCrewMember({
    required this.id,
    required this.name,
    this.job,
    this.department,
    this.profilePath,
  });

  factory TmdbCrewMember.fromJson(Map<String, dynamic> json) {
    return TmdbCrewMember(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      job: json['job'],
      department: json['department'],
      profilePath: json['profile_path'],
    );
  }

  String? get profileUrl => profilePath != null
      ? 'https://image.tmdb.org/t/p/w185$profilePath'
      : null;
}

/// Enriched metadata combining TMDB data
class TmdbEnrichedMetadata {
  final int id;
  final String? imdbId;
  final String title;
  final String? overview;
  final List<String> genres;
  final List<TmdbCastMember> cast;
  final List<TmdbCrewMember> crew;
  final String? rating;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final int? runtime;
  final double? voteAverage;
  final List<TrailerInfo> trailers;

  TmdbEnrichedMetadata({
    required this.id,
    this.imdbId,
    required this.title,
    this.overview,
    this.genres = const [],
    this.cast = const [],
    this.crew = const [],
    this.rating,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.runtime,
    this.voteAverage,
    this.trailers = const [],
  });

  String? get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w500$posterPath'
      : null;

  String? get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/original$backdropPath'
      : null;

  TrailerInfo? get mainTrailer => trailers.isNotEmpty ? trailers.first : null;

  String get genresString => genres.join(', ');

  String get castString => cast.map((c) => c.name).join(', ');

  String? get director {
    final directors = crew.where((c) => c.job == 'Director');
    return directors.isNotEmpty ? directors.first.name : null;
  }

  int? get releaseYear {
    if (releaseDate == null) return null;
    final parts = releaseDate!.split('-');
    if (parts.isNotEmpty) {
      return int.tryParse(parts.first);
    }
    return null;
  }
}
