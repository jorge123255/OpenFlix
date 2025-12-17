import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/client_config.dart';
import '../models/dvr.dart';
import '../models/livetv_channel.dart';
import '../models/file_info.dart';
import '../models/filter.dart';
import '../models/hub.dart';
import '../models/library.dart';
import '../models/media_info.dart';
import '../models/media_version.dart';
import '../models/media_item.dart';
import '../models/playlist.dart';
import '../models/sort.dart';
import '../models/video_playback_data.dart';
import '../models/play_queue_response.dart';
import '../network/endpoint_failover_interceptor.dart';
import '../utils/app_logger.dart';
import '../utils/log_redaction_manager.dart';

/// Result of testing a connection, including success status and latency
class ConnectionTestResult {
  final bool success;
  final int latencyMs;

  ConnectionTestResult({required this.success, required this.latencyMs});
}

class MediaClient {
  ClientConfig config;
  late final Dio _dio;
  final EndpointFailoverManager? _endpointManager;
  final Future<void> Function(String newBaseUrl)? _onEndpointChanged;

  /// Server identifier - all MediaItem items created by this client are tagged with this
  final String serverId;

  /// Server name - all MediaItem items created by this client are tagged with this
  final String? serverName;

  /// Custom response decoder that handles malformed UTF-8 gracefully
  static String _lenientUtf8Decoder(
    List<int> responseBytes,
    RequestOptions options,
    ResponseBody responseBody,
  ) {
    return utf8.decode(responseBytes, allowMalformed: true);
  }

  MediaClient(
    this.config, {
    required this.serverId,
    this.serverName,
    List<String>? prioritizedEndpoints,
    Future<void> Function(String newBaseUrl)? onEndpointChanged,
  }) : _endpointManager =
           (prioritizedEndpoints != null && prioritizedEndpoints.isNotEmpty)
           ? EndpointFailoverManager(prioritizedEndpoints)
           : null,
       _onEndpointChanged = onEndpointChanged {
    LogRedactionManager.registerServerUrl(config.baseUrl);
    LogRedactionManager.registerToken(config.token);

    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        headers: config.headers,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 120),
        validateStatus: (status) => status != null && status < 500,
        responseType: ResponseType.json,
        contentType: 'application/json; charset=utf-8',
        responseDecoder: _lenientUtf8Decoder,
      ),
    );

    // Ensure token is attached for every request (header + query param fallback).
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = config.token;
          if (token != null && token.isNotEmpty) {
            options.headers['X-Plex-Token'] ??= token;
            options.queryParameters['X-Plex-Token'] ??= token;
          }
          handler.next(options);
        },
      ),
    );

    // Add interceptor for logging (optional, can be disabled in production)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );

    if (_endpointManager != null) {
      _dio.interceptors.add(
        EndpointFailoverInterceptor(
          dio: _dio,
          endpointManager: _endpointManager,
          onEndpointSwitch: _handleEndpointSwitch,
        ),
      );
    }
  }

  /// Update the token used by this client
  void updateToken(String newToken) {
    // Update both the Dio headers and the config to ensure consistency
    _dio.options.headers['X-Plex-Token'] = newToken;
    config = config.copyWith(token: newToken);
    LogRedactionManager.registerToken(newToken);
    appLogger.d('MediaClient token updated (headers and config)');
  }

  /// Update endpoint priority list and optionally hop to the new best endpoint.
  Future<void> updateEndpointPreferences(
    List<String> prioritizedEndpoints, {
    bool switchToFirst = false,
  }) async {
    if (_endpointManager == null || prioritizedEndpoints.isEmpty) {
      return;
    }

    final targetBaseUrl = switchToFirst
        ? prioritizedEndpoints.first
        : config.baseUrl;
    _endpointManager.reset(prioritizedEndpoints, currentBaseUrl: targetBaseUrl);

    if (switchToFirst && targetBaseUrl != config.baseUrl) {
      await _handleEndpointSwitch(targetBaseUrl);
    }
  }

  /// Test connection to server
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (e) {
      return false;
    }
  }

  /// Test connection to a specific URL with token and measure latency
  static Future<ConnectionTestResult> testConnectionWithLatency(
    String baseUrl,
    String token, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: timeout,
          receiveTimeout: timeout,
          validateStatus: (status) => status != null && status < 500,
          responseType: ResponseType.json,
          contentType: 'application/json; charset=utf-8',
        ),
      );

      final response = await dio.get(
        '/',
        options: Options(headers: {'X-Plex-Token': token}),
      );

      stopwatch.stop();
      final success = response.statusCode == 200 || response.statusCode == 401;

      return ConnectionTestResult(
        success: success,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult(
        success: false,
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Test connection multiple times and return average latency
  static Future<ConnectionTestResult> testConnectionWithAverageLatency(
    String baseUrl,
    String token, {
    int attempts = 3,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final results = <ConnectionTestResult>[];

    for (int i = 0; i < attempts; i++) {
      final result = await testConnectionWithLatency(
        baseUrl,
        token,
        timeout: timeout,
      );

      // If any attempt fails, return failed result immediately
      if (!result.success) {
        return ConnectionTestResult(
          success: false,
          latencyMs: result.latencyMs,
        );
      }

      results.add(result);
    }

    // Calculate average latency from successful attempts
    final avgLatency =
        results.fold<int>(0, (sum, result) => sum + result.latencyMs) ~/
        results.length;

    return ConnectionTestResult(success: true, latencyMs: avgLatency);
  }

  // ============================================================================
  // API Response Parsing Helpers
  // ============================================================================

  /// Extract MediaContainer from API response
  Map<String, dynamic>? _getMediaContainer(Response response) {
    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      return response.data['MediaContainer'];
    }
    return null;
  }

  /// Extract list of MediaItem from response
  /// Automatically tags all items with this client's serverId and serverName
  List<MediaItem> _extractMetadataList(Response response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return (container['Metadata'] as List)
          .map(
            (json) => MediaItem.fromJson(
              json,
            ).copyWith(serverId: serverId, serverName: serverName),
          )
          .toList();
    }
    return [];
  }

  /// Extract first metadata JSON from response (returns raw Map or null)
  Map<String, dynamic>? _getFirstMetadataJson(Response response) {
    final container = _getMediaContainer(response);
    if (container != null &&
        container['Metadata'] != null &&
        (container['Metadata'] as List).isNotEmpty) {
      return container['Metadata'][0] as Map<String, dynamic>;
    }
    return null;
  }

  /// Extract single MediaItem from response (returns first item or null)
  /// Automatically tags the item with this client's serverId and serverName
  MediaItem? _extractSingleMetadata(Response response) {
    final metadataJson = _getFirstMetadataJson(response);
    return metadataJson != null
        ? MediaItem.fromJson(
            metadataJson,
          ).copyWith(serverId: serverId, serverName: serverName)
        : null;
  }

  /// Generic helper to extract and map Directory list from response
  List<T> _extractDirectoryList<T>(
    Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final container = _getMediaContainer(response);
    if (container != null && container['Directory'] != null) {
      return (container['Directory'] as List)
          .map((json) => fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Extract Library list from response with auto-tagging
  List<Library> _extractLibraryList(Response response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Directory'] != null) {
      return (container['Directory'] as List)
          .map(
            (json) => Library.fromJson(
              json as Map<String, dynamic>,
            ).copyWith(serverId: serverId, serverName: serverName),
          )
          .toList();
    }
    return [];
  }

  /// Extract Playlist list from response with auto-tagging
  List<Playlist> _extractPlaylistList(Response response) {
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return (container['Metadata'] as List)
          .map(
            (json) => Playlist.fromJson(
              json as Map<String, dynamic>,
            ).copyWith(serverId: serverId, serverName: serverName),
          )
          .toList();
    }
    return [];
  }

  // ============================================================================
  // API Methods
  // ============================================================================

  /// Get server identity
  Future<Map<String, dynamic>> getServerIdentity() async {
    final response = await _dio.get('/identity');
    return response.data;
  }

  /// Get library sections
  /// Returns libraries automatically tagged with this client's serverId and serverName
  Future<List<Library>> getLibraries() async {
    final response = await _dio.get('/library/sections');
    return _extractLibraryList(response);
  }

  /// Get library content by section ID
  Future<List<MediaItem>> getLibraryContent(
    String sectionId, {
    int? start,
    int? size,
    Map<String, String>? filters,
    CancelToken? cancelToken,
  }) async {
    final queryParams = <String, dynamic>{};
    if (start != null) queryParams['X-Plex-Container-Start'] = start;
    if (size != null) queryParams['X-Plex-Container-Size'] = size;

    // Add filter parameters
    if (filters != null) {
      queryParams.addAll(filters);
    }

    final response = await _dio.get(
      '/library/sections/$sectionId/all',
      queryParameters: queryParams,
      cancelToken: cancelToken,
    );

    return _extractMetadataList(response);
  }

  /// Get metadata by rating key
  Future<MediaItem?> getMetadata(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    return _extractSingleMetadata(response);
  }

  /// Get the server's machine identifier
  Future<String?> getMachineIdentifier() async {
    try {
      final response = await _dio.get('/');
      final container = _getMediaContainer(response);
      if (container == null) return null;
      return container['machineIdentifier'] as String?;
    } catch (e) {
      appLogger.e('Failed to get machine identifier', error: e);
      return null;
    }
  }

  /// Build a proper metadata URI for adding to playlists
  /// Returns URI in format: server://{machineId}/com.plexapp.plugins.library/library/metadata/{ratingKey}
  Future<String> buildMetadataUri(String ratingKey) async {
    // Use cached machine identifier from config if available
    final machineId = config.machineIdentifier ?? await getMachineIdentifier();
    if (machineId == null) {
      throw Exception('Could not get server machine identifier');
    }
    return 'server://$machineId/com.plexapp.plugins.library/library/metadata/$ratingKey';
  }

  /// Get metadata by rating key with images (includes clearLogo and OnDeck)
  Future<Map<String, dynamic>> getMetadataWithImagesAndOnDeck(
    String ratingKey,
  ) async {
    final response = await _dio.get(
      '/library/metadata/$ratingKey',
      queryParameters: {'includeOnDeck': 1},
    );

    MediaItem? metadata;
    MediaItem? onDeckEpisode;

    final metadataJson = _getFirstMetadataJson(response);

    // Log the parsed metadata JSON
    if (metadataJson != null) {
      metadata = MediaItem.fromJsonWithImages(
        metadataJson,
      ).copyWith(serverId: serverId, serverName: serverName);

      // Check if OnDeck is nested inside Metadata
      if (metadataJson.containsKey('OnDeck') &&
          metadataJson['OnDeck'] != null) {
        final onDeckData = metadataJson['OnDeck'];

        // OnDeck can be either a Map with 'Metadata' key or direct metadata
        if (onDeckData is Map && onDeckData.containsKey('Metadata')) {
          final onDeckMetadata = onDeckData['Metadata'];
          if (onDeckMetadata != null) {
            onDeckEpisode = MediaItem.fromJson(
              onDeckMetadata,
            ).copyWith(serverId: serverId, serverName: serverName);
          }
        }
      }
    }

    return {'metadata': metadata, 'onDeckEpisode': onDeckEpisode};
  }

  /// Get metadata by rating key with images (includes clearLogo)
  Future<MediaItem?> getMetadataWithImages(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);
    return metadataJson != null
        ? MediaItem.fromJsonWithImages(
            metadataJson,
          ).copyWith(serverId: serverId, serverName: serverName)
        : null;
  }

  /// Set per-media language preferences (audio and subtitle)
  /// For TV shows, use grandparentRatingKey to set preference for the entire series
  /// For movies, use the movie's ratingKey
  Future<bool> setMetadataPreferences(
    String ratingKey, {
    String? audioLanguage,
    String? subtitleLanguage,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (audioLanguage != null) {
        queryParams['audioLanguage'] = audioLanguage;
      }
      if (subtitleLanguage != null) {
        queryParams['subtitleLanguage'] = subtitleLanguage;
      }

      // If no preferences to set, return early
      if (queryParams.isEmpty) {
        return true;
      }

      final response = await _dio.put(
        '/library/metadata/$ratingKey/prefs',
        queryParameters: queryParams,
      );

      return response.statusCode == 200;
    } catch (e) {
      appLogger.e('Failed to set metadata preferences', error: e);
      return false;
    }
  }

  /// Select specific audio and subtitle streams for playback
  /// This updates which streams are "selected" in the media metadata
  /// Uses the part ID from media info for accurate stream selection
  Future<bool> selectStreams(
    int partId, {
    int? audioStreamID,
    int? subtitleStreamID,
    bool allParts = true,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (audioStreamID != null) {
        queryParams['audioStreamID'] = audioStreamID;
      }
      if (subtitleStreamID != null) {
        queryParams['subtitleStreamID'] = subtitleStreamID;
      }
      if (allParts) {
        // If no streams to select, return early
        if (queryParams.isEmpty) {
          return true;
        }

        // Use PUT request on /library/parts/{partId}
        final response = await _dio.put(
          '/library/parts/$partId',
          queryParameters: queryParams,
        );

        return response.statusCode == 200;
      }
      // Si allParts est false, retourner true ou false explicitement (selon la logique souhaitée)
      // Ici, on retourne true par défaut si rien n'est fait
      return true;
    } catch (e) {
      appLogger.e('Failed to select streams', error: e);
      return false;
    }
  }

  /// Search across all libraries using the hub search endpoint
  /// Only returns movies and shows, filtering out seasons and episodes
  Future<List<MediaItem>> search(String query, {int limit = 10}) async {
    final response = await _dio.get(
      '/hubs/search',
      queryParameters: {
        'query': query,
        'limit': limit,
        'includeCollections': 1,
      },
    );

    final results = <MediaItem>[];

    if (response.data is Map && response.data.containsKey('MediaContainer')) {
      final container = response.data['MediaContainer'];
      if (container['Hub'] != null) {
        // Each hub contains results of a specific type (movies, shows, etc.)
        for (final hub in container['Hub'] as List) {
          final hubType = hub['type'] as String?;

          // Only include movie and show hubs
          if (hubType != 'movie' && hubType != 'show') {
            continue;
          }

          // Hubs can contain either Metadata (for movies) or Directory (for shows)
          if (hub['Metadata'] != null) {
            for (final json in hub['Metadata'] as List) {
              try {
                results.add(
                  MediaItem.fromJson(
                    json,
                  ).copyWith(serverId: serverId, serverName: serverName),
                );
              } catch (e) {
                // Skip items that fail to parse
                appLogger.w('Failed to parse search result', error: e);
                appLogger.d('Problematic JSON: $json');
              }
            }
          }
          if (hub['Directory'] != null) {
            for (final json in hub['Directory'] as List) {
              try {
                results.add(
                  MediaItem.fromJson(
                    json,
                  ).copyWith(serverId: serverId, serverName: serverName),
                );
              } catch (e) {
                // Skip items that fail to parse
                appLogger.w('Failed to parse search result', error: e);
                appLogger.d('Problematic JSON: $json');
              }
            }
          }
        }
      }
    }

    return results;
  }

  /// Get recently added media (filtered to video content only)
  Future<List<MediaItem>> getRecentlyAdded({int limit = 50}) async {
    final response = await _dio.get(
      '/library/recentlyAdded',
      queryParameters: {'X-Plex-Container-Size': limit, 'includeGuids': 1},
    );
    final allItems = _extractMetadataList(response);

    // Filter out music content (artists, albums, tracks)
    return allItems.where((item) {
      final type = item.type.toLowerCase();
      return type != 'artist' && type != 'album' && type != 'track';
    }).toList();
  }

  /// Get on deck items (continue watching, filtered to video content only)
  Future<List<MediaItem>> getOnDeck() async {
    final response = await _dio.get('/library/onDeck');
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      final allItems = (container['Metadata'] as List)
          .map(
            (json) => MediaItem.fromJsonWithImages(
              json,
            ).copyWith(serverId: serverId, serverName: serverName),
          )
          .toList();

      // Filter out music content (artists, albums, tracks)
      return allItems.where((item) {
        final type = item.type.toLowerCase();
        return type != 'artist' && type != 'album' && type != 'track';
      }).toList();
    }
    return [];
  }

  /// Get children of a metadata item (e.g., seasons for a show, episodes for a season)
  Future<List<MediaItem>> getChildren(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey/children');
    return _extractMetadataList(response);
  }

  /// Get all unwatched episodes for a TV show across all seasons
  Future<List<MediaItem>> getAllUnwatchedEpisodes(
    String showRatingKey,
  ) async {
    final allEpisodes = <MediaItem>[];

    // Get all seasons for the show
    final seasons = await getChildren(showRatingKey);

    // Get episodes from each season
    for (final season in seasons) {
      if (season.type == 'season') {
        final episodes = await getChildren(season.ratingKey);

        // Filter for unwatched episodes
        final unwatchedEpisodes = episodes
            .where((ep) => ep.type == 'episode' && (ep.viewCount ?? 0) == 0)
            .toList();

        allEpisodes.addAll(unwatchedEpisodes);
      }
    }

    return allEpisodes;
  }

  /// Get all unwatched episodes in a specific season
  Future<List<MediaItem>> getUnwatchedEpisodesInSeason(
    String seasonRatingKey,
  ) async {
    final episodes = await getChildren(seasonRatingKey);

    // Filter for unwatched episodes
    return episodes
        .where((ep) => ep.type == 'episode' && (ep.viewCount ?? 0) == 0)
        .toList();
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String? thumbPath) {
    if (thumbPath == null || thumbPath.isEmpty) return '';

    // If it's already a full URL (external image like TMDB), return as-is
    if (thumbPath.startsWith('http://') || thumbPath.startsWith('https://')) {
      return thumbPath;
    }

    // Remove leading slash if present
    final path = thumbPath.startsWith('/') ? thumbPath.substring(1) : thumbPath;

    // Check if path already has query parameters
    final separator = path.contains('?') ? '&' : '?';

    return '${config.baseUrl}/$path${separator}X-Plex-Token=${config.token}';
  }

  String _appendToken(String url) {
    final token = config.token;
    if (token == null || token.isEmpty) return url;
    if (url.toLowerCase().contains('x-plex-token=')) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}X-Plex-Token=$token';
  }

  /// Get video URL for direct playback
  /// [mediaIndex] specifies which Media item to use (defaults to 0 - first version)
  Future<String?> getVideoUrl(String ratingKey, {int mediaIndex = 0}) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final mediaList = metadataJson['Media'] as List;

      // Ensure the requested index is valid
      if (mediaIndex < 0 || mediaIndex >= mediaList.length) {
        mediaIndex = 0;
      }

      final media = mediaList[mediaIndex];
      if (media['Part'] != null && (media['Part'] as List).isNotEmpty) {
        final part = media['Part'][0];
        final partKey = part['key'] as String?;

        if (partKey != null) {
          // Return direct play URL
          return _appendToken('${config.baseUrl}$partKey');
        }
      }
    }

    return null;
  }

  /// Get chapters for a media item
  Future<List<Chapter>> getChapters(String ratingKey) async {
    final response = await _dio.get(
      '/library/metadata/$ratingKey',
      queryParameters: {'includeChapters': 1},
    );

    final metadataJson = _getFirstMetadataJson(response);
    if (metadataJson != null && metadataJson['Chapter'] != null) {
      final chapterList = metadataJson['Chapter'] as List<dynamic>;
      return chapterList.map((chapter) {
        return Chapter(
          id: chapter['id'] as int,
          index: chapter['index'] as int?,
          startTimeOffset: chapter['startTimeOffset'] as int?,
          endTimeOffset: chapter['endTimeOffset'] as int?,
          title: chapter['tag'] as String?,
          thumb: chapter['thumb'] as String?,
        );
      }).toList();
    }

    return [];
  }

  Future<List<Marker>> getMarkers(String ratingKey) async {
    final response = await _dio.get(
      '/library/metadata/$ratingKey',
      queryParameters: {'includeMarkers': 1},
    );

    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null && metadataJson['Marker'] != null) {
      final markerList = metadataJson['Marker'] as List;
      return markerList.map((marker) {
        return Marker(
          id: marker['id'] as int,
          type: marker['type'] as String,
          startTimeOffset: marker['startTimeOffset'] as int,
          endTimeOffset: marker['endTimeOffset'] as int,
        );
      }).toList();
    }

    return [];
  }

  /// Get detailed media info including chapters and tracks
  /// [mediaIndex] specifies which Media item to use (defaults to 0 - first version)
  Future<MediaInfo?> getMediaInfo(
    String ratingKey, {
    int mediaIndex = 0,
  }) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final mediaList = metadataJson['Media'] as List;

      // Ensure the requested index is valid
      if (mediaIndex < 0 || mediaIndex >= mediaList.length) {
        mediaIndex = 0;
      }

      final media = mediaList[mediaIndex];
      if (media['Part'] != null && (media['Part'] as List).isNotEmpty) {
        final part = media['Part'][0];
        final partKey = part['key'] as String?;

        if (partKey != null) {
          // Parse streams (audio and subtitle tracks)
          final streams = part['Stream'] as List<dynamic>? ?? [];
          final audioTracks = <MediaAudioTrack>[];
          final subtitleTracks = <MediaSubtitleTrack>[];

          for (var stream in streams) {
            final streamType = stream['streamType'] as int?;

            if (streamType == 2) {
              // Audio track
              audioTracks.add(
                MediaAudioTrack(
                  id: stream['id'] as int,
                  index: stream['index'] as int?,
                  codec: stream['codec'] as String?,
                  language: stream['language'] as String?,
                  languageCode: stream['languageCode'] as String?,
                  title: stream['title'] as String?,
                  displayTitle: stream['displayTitle'] as String?,
                  channels: stream['channels'] as int?,
                  selected: stream['selected'] == 1,
                ),
              );
            } else if (streamType == 3) {
              // Subtitle track
              subtitleTracks.add(
                MediaSubtitleTrack(
                  id: stream['id'] as int,
                  index: stream['index'] as int?,
                  codec: stream['codec'] as String?,
                  language: stream['language'] as String?,
                  languageCode: stream['languageCode'] as String?,
                  title: stream['title'] as String?,
                  displayTitle: stream['displayTitle'] as String?,
                  selected: stream['selected'] == 1,
                  forced: stream['forced'] == 1,
                  key: stream['key'] as String?,
                ),
              );
            }
          }

          // Parse chapters
          final chapters = <Chapter>[];
          if (metadataJson['Chapter'] != null) {
            final chapterList = metadataJson['Chapter'] as List<dynamic>;
            for (var chapter in chapterList) {
              chapters.add(
                Chapter(
                  id: chapter['id'] as int,
                  index: chapter['index'] as int?,
                  startTimeOffset: chapter['startTimeOffset'] as int?,
                  endTimeOffset: chapter['endTimeOffset'] as int?,
                  title: chapter['title'] as String?,
                  thumb: chapter['thumb'] as String?,
                ),
              );
            }
          }

          return MediaInfo(
            videoUrl: _appendToken('${config.baseUrl}$partKey'),
            audioTracks: audioTracks,
            subtitleTracks: subtitleTracks,
            chapters: chapters,
          );
        }
      }
    }

    return null;
  }

  /// Get all available media versions for a media item
  /// Returns a list of MediaVersion objects representing different quality/format options
  Future<List<MediaVersion>> getMediaVersions(String ratingKey) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final mediaList = metadataJson['Media'] as List;
      return mediaList
          .map(
            (media) => MediaVersion.fromJson(media as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  /// Get consolidated video playback data (URL, media info, and versions) in a single API call
  /// This method combines the functionality of getVideoUrl(), getMediaInfo(), and getMediaVersions()
  /// to reduce redundant API calls during video playback initialization.
  Future<VideoPlaybackData> getVideoPlaybackData(
    String ratingKey, {
    int mediaIndex = 0,
  }) async {
    final response = await _dio.get('/library/metadata/$ratingKey');
    final metadataJson = _getFirstMetadataJson(response);

    String? videoUrl;
    MediaInfo? mediaInfo;
    List<MediaVersion> availableVersions = [];

    if (metadataJson != null &&
        metadataJson['Media'] != null &&
        (metadataJson['Media'] as List).isNotEmpty) {
      final mediaList = metadataJson['Media'] as List;

      // Parse available media versions first
      availableVersions = mediaList
          .map(
            (media) => MediaVersion.fromJson(media as Map<String, dynamic>),
          )
          .toList();

      // Ensure the requested index is valid
      if (mediaIndex < 0 || mediaIndex >= mediaList.length) {
        mediaIndex = 0;
      }

      final media = mediaList[mediaIndex];
      if (media['Part'] != null && (media['Part'] as List).isNotEmpty) {
        final part = media['Part'][0];
        final partKey = part['key'] as String?;

        if (partKey != null) {
          // Get video URL
          videoUrl = _appendToken('${config.baseUrl}$partKey');

          // Parse streams (audio and subtitle tracks) for media info
          final streams = part['Stream'] as List<dynamic>? ?? [];
          final audioTracks = <MediaAudioTrack>[];
          final subtitleTracks = <MediaSubtitleTrack>[];

          for (var stream in streams) {
            final streamType = stream['streamType'] as int?;

            if (streamType == 2) {
              // Audio track
              audioTracks.add(
                MediaAudioTrack(
                  id: stream['id'] as int,
                  index: stream['index'] as int?,
                  codec: stream['codec'] as String?,
                  language: stream['language'] as String?,
                  languageCode: stream['languageCode'] as String?,
                  title: stream['title'] as String?,
                  displayTitle: stream['displayTitle'] as String?,
                  channels: stream['channels'] as int?,
                  selected: stream['selected'] == 1,
                ),
              );
            } else if (streamType == 3) {
              // Subtitle track
              subtitleTracks.add(
                MediaSubtitleTrack(
                  id: stream['id'] as int,
                  index: stream['index'] as int?,
                  codec: stream['codec'] as String?,
                  language: stream['language'] as String?,
                  languageCode: stream['languageCode'] as String?,
                  title: stream['title'] as String?,
                  displayTitle: stream['displayTitle'] as String?,
                  selected: stream['selected'] == 1,
                  forced: stream['forced'] == 1,
                  key: stream['key'] as String?,
                ),
              );
            }
          }

          // Parse chapters
          final chapters = <Chapter>[];
          if (metadataJson['Chapter'] != null) {
            final chapterList = metadataJson['Chapter'] as List<dynamic>;
            for (var chapter in chapterList) {
              chapters.add(
                Chapter(
                  id: chapter['id'] as int,
                  index: chapter['index'] as int?,
                  startTimeOffset: chapter['startTimeOffset'] as int?,
                  endTimeOffset: chapter['endTimeOffset'] as int?,
                  title: chapter['title'] as String?,
                  thumb: chapter['thumb'] as String?,
                ),
              );
            }
          }

          // Create media info
          mediaInfo = MediaInfo(
            videoUrl: videoUrl,
            audioTracks: audioTracks,
            subtitleTracks: subtitleTracks,
            chapters: chapters,
            partId: part['id'] as int?,
          );
        }
      }
    }

    return VideoPlaybackData(
      videoUrl: videoUrl,
      mediaInfo: mediaInfo,
      availableVersions: availableVersions,
    );
  }

  /// Get file information for a media item
  Future<FileInfo?> getFileInfo(String ratingKey) async {
    try {
      final response = await _dio.get('/library/metadata/$ratingKey');
      final metadataJson = _getFirstMetadataJson(response);

      if (metadataJson != null &&
          metadataJson['Media'] != null &&
          (metadataJson['Media'] as List).isNotEmpty) {
        final media = metadataJson['Media'][0];
        final part = media['Part'] != null && (media['Part'] as List).isNotEmpty
            ? media['Part'][0]
            : null;

        // Extract video stream details
        final streams = part?['Stream'] as List<dynamic>? ?? [];
        Map<String, dynamic>? videoStream;
        Map<String, dynamic>? audioStream;

        for (var stream in streams) {
          final streamType = stream['streamType'] as int?;
          if (streamType == 1 && videoStream == null) {
            videoStream = stream;
          } else if (streamType == 2 && audioStream == null) {
            audioStream = stream;
          }
        }

        return FileInfo(
          // Media level properties
          container: media['container'] as String?,
          videoCodec: media['videoCodec'] as String?,
          videoResolution: media['videoResolution'] as String?,
          videoFrameRate: media['videoFrameRate'] as String?,
          videoProfile: media['videoProfile'] as String?,
          width: media['width'] as int?,
          height: media['height'] as int?,
          aspectRatio: (media['aspectRatio'] as num?)?.toDouble(),
          bitrate: media['bitrate'] as int?,
          duration: media['duration'] as int?,
          audioCodec: media['audioCodec'] as String?,
          audioProfile: media['audioProfile'] as String?,
          audioChannels: media['audioChannels'] as int?,
          optimizedForStreaming: media['optimizedForStreaming'] as bool?,
          has64bitOffsets: media['has64bitOffsets'] as bool?,
          // Part level properties (file)
          filePath: part?['file'] as String?,
          fileSize: part?['size'] as int?,
          // Video stream details
          colorSpace: videoStream?['colorSpace'] as String?,
          colorRange: videoStream?['colorRange'] as String?,
          colorPrimaries: videoStream?['colorPrimaries'] as String?,
          colorTrc: videoStream?['colorTrc'] as String?,
          chromaSubsampling: videoStream?['chromaSubsampling'] as String?,
          frameRate: (videoStream?['frameRate'] as num?)?.toDouble(),
          bitDepth: videoStream?['bitDepth'] as int?,
          // Audio stream details
          audioChannelLayout: audioStream?['audioChannelLayout'] as String?,
        );
      }

      return null;
    } catch (e) {
      appLogger.e('Failed to get file info: $e');
      return null;
    }
  }

  /// Mark media as watched
  Future<void> markAsWatched(String ratingKey) async {
    await _dio.get(
      '/:/scrobble',
      queryParameters: {
        'key': ratingKey,
        'identifier': 'com.plexapp.plugins.library',
      },
    );
  }

  /// Mark media as unwatched
  Future<void> markAsUnwatched(String ratingKey) async {
    await _dio.get(
      '/:/unscrobble',
      queryParameters: {
        'key': ratingKey,
        'identifier': 'com.plexapp.plugins.library',
      },
    );
  }

  /// Update playback progress
  Future<void> updateProgress(
    String ratingKey, {
    required int time,
    required String state, // 'playing', 'paused', 'stopped', 'buffering'
    int? duration,
  }) async {
    await _dio.post(
      '/:/timeline',
      queryParameters: {
        'ratingKey': ratingKey,
        'key': '/library/metadata/$ratingKey',
        'time': time,
        'state': state,
        if (duration != null) 'duration': duration,
      },
    );
  }

  /// Remove item from Continue Watching (On Deck) without affecting watch status or progress
  /// This uses the same endpoint Plex Web uses to hide items from Continue Watching
  Future<void> removeFromOnDeck(String ratingKey) async {
    await _dio.put(
      '/actions/removeFromContinueWatching',
      queryParameters: {'ratingKey': ratingKey},
    );
  }

  /// Get server preferences
  Future<Map<String, dynamic>> getServerPreferences() async {
    final response = await _dio.get('/:/prefs');
    return response.data;
  }

  /// Get sessions (currently playing)
  Future<List<dynamic>> getSessions() async {
    final response = await _dio.get('/status/sessions');
    final container = _getMediaContainer(response);
    if (container != null && container['Metadata'] != null) {
      return container['Metadata'] as List;
    }
    return [];
  }

  /// Get available filters for a library section
  Future<List<Filter>> getLibraryFilters(String sectionId) async {
    final response = await _dio.get('/library/sections/$sectionId/filters');
    return _extractDirectoryList(response, Filter.fromJson);
  }

  /// Get filter values (e.g., list of genres, years, etc.)
  Future<List<FilterValue>> getFilterValues(String filterKey) async {
    final response = await _dio.get(filterKey);
    return _extractDirectoryList(response, FilterValue.fromJson);
  }

  /// Get available sort options for a library section
  Future<List<Sort>> getLibrarySorts(String sectionId) async {
    try {
      // Use the dedicated sorts endpoint
      final response = await _dio.get('/library/sections/$sectionId/sorts');

      // Parse the Directory array (not Sort array) per the API spec
      final sorts = _extractDirectoryList(response, Sort.fromJson);

      if (sorts.isNotEmpty) {
        return sorts;
      }

      // Fallback: return common sort options if API doesn't provide them
      return _getFallbackSorts(sectionId);
    } catch (e) {
      appLogger.e('Failed to get library sorts: $e');
      // Return fallback sort options on error
      return _getFallbackSorts(sectionId);
    }
  }

  Future<List<Sort>> _getFallbackSorts(String sectionId) async {
    try {
      // Get library type to determine which sorts to include
      final librariesResponse = await _dio.get('/library/sections');
      final libraries = _extractDirectoryList(
        librariesResponse,
        Library.fromJson,
      );
      final library = libraries.firstWhere(
        (lib) => lib.key == sectionId,
        orElse: () => libraries.first,
      );

      final fallbackSorts = <Sort>[
        Sort(key: 'titleSort', title: 'Title', defaultDirection: 'asc'),
        Sort(
          key: 'addedAt',
          descKey: 'addedAt:desc',
          title: 'Date Added',
          defaultDirection: 'desc',
        ),
      ];

      // Add "Latest Episode Air Date" only for TV show libraries
      if (library.type.toLowerCase() == 'show') {
        fallbackSorts.add(
          Sort(
            key: 'episode.originallyAvailableAt',
            descKey: 'episode.originallyAvailableAt:desc',
            title: 'Latest Episode Air Date',
            defaultDirection: 'desc',
          ),
        );
      }

      fallbackSorts.addAll([
        Sort(
          key: 'originallyAvailableAt',
          descKey: 'originallyAvailableAt:desc',
          title: 'Release Date',
          defaultDirection: 'desc',
        ),
        Sort(
          key: 'rating',
          descKey: 'rating:desc',
          title: 'Rating',
          defaultDirection: 'desc',
        ),
      ]);

      return fallbackSorts;
    } catch (e) {
      appLogger.e('Failed to get fallback sorts: $e');
      // Return minimal fallback options
      return [
        Sort(key: 'titleSort', title: 'Title', defaultDirection: 'asc'),
        Sort(
          key: 'addedAt',
          descKey: 'addedAt:desc',
          title: 'Date Added',
          defaultDirection: 'desc',
        ),
      ];
    }
  }

  /// Get library hubs (recommendations for a specific library section)
  /// Returns a list of recommendation hubs like "Trending Movies", "Top in Genre", etc.
  Future<List<Hub>> getLibraryHubs(
    String sectionId, {
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/hubs/sections/$sectionId',
        queryParameters: {'count': limit, 'includeGuids': 1},
      );

      final container = _getMediaContainer(response);
      if (container != null && container['Hub'] != null) {
        final hubs = <Hub>[];
        for (final hubJson in container['Hub'] as List) {
          try {
            final hub = Hub.fromJson(hubJson);
            // Only include hubs that have items and are movie/show content
            if (hub.items.isNotEmpty) {
              // Filter out non-video content types and tag with server info
              final videoItems = hub.items
                  .where((item) {
                    final type = item.type.toLowerCase();
                    return type == 'movie' || type == 'show';
                  })
                  .map(
                    (item) => item.copyWith(
                      serverId: serverId,
                      serverName: serverName,
                    ),
                  )
                  .toList();

              if (videoItems.isNotEmpty) {
                hubs.add(
                  Hub(
                    hubKey: hub.hubKey,
                    title: hub.title,
                    type: hub.type,
                    hubIdentifier: hub.hubIdentifier,
                    size: hub.size,
                    more: hub.more,
                    items: videoItems,
                    serverId: serverId,
                    serverName: serverName,
                  ),
                );
              }
            }
          } catch (e) {
            appLogger.w('Failed to parse hub', error: e);
          }
        }
        return hubs;
      }
    } catch (e) {
      appLogger.e('Failed to get library hubs: $e');
    }
    return [];
  }

  /// Get full content from a hub using its hub key
  /// Returns the complete list of metadata items in the hub
  Future<List<MediaItem>> getHubContent(String hubKey) async {
    try {
      final response = await _dio.get(hubKey);
      final allItems = _extractMetadataList(response);

      // Filter out non-video content types
      return allItems.where((item) {
        final type = item.type.toLowerCase();
        return type == 'movie' || type == 'show';
      }).toList();
    } catch (e) {
      appLogger.e('Failed to get hub content: $e');
      return [];
    }
  }

  /// Get playlist content by playlist ID
  /// Returns the list of metadata items in the playlist
  Future<List<MediaItem>> getPlaylist(String playlistId) async {
    try {
      final response = await _dio.get('/playlists/$playlistId/items');
      return _extractMetadataList(response);
    } catch (e) {
      appLogger.e('Failed to get playlist: $e');
      return [];
    }
  }

  /// Get all playlists
  /// Filters by playlistType=video by default
  /// Set smart to true/false to filter smart playlists, or null for all
  Future<List<Playlist>> getPlaylists({
    String playlistType = 'video',
    bool? smart,
  }) async {
    try {
      final queryParams = <String, dynamic>{'playlistType': playlistType};
      if (smart != null) {
        queryParams['smart'] = smart ? '1' : '0';
      }

      final response = await _dio.get(
        '/playlists',
        queryParameters: queryParams,
      );

      return _extractPlaylistList(response);
    } catch (e) {
      appLogger.e('Failed to get playlists: $e');
      return [];
    }
  }

  /// Get playlist metadata by playlist ID
  /// Returns the playlist details (not the items)
  Future<Playlist?> getPlaylistMetadata(String playlistId) async {
    try {
      final response = await _dio.get('/playlists/$playlistId');
      final container = _getMediaContainer(response);

      if (container == null || container['Metadata'] == null) {
        return null;
      }

      final List<dynamic> metadata = container['Metadata'] as List;

      if (metadata.isEmpty) {
        return null;
      }

      return Playlist.fromJson(metadata.first as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to get playlist metadata: $e');
      return null;
    }
  }

  /// Create a new playlist
  /// [title] - Name of the playlist
  /// [uri] - Optional comma-separated list of item URIs to add (e.g., "server://uuid/com.plexapp.plugins.library/library/metadata/1234")
  /// [playQueueId] - Optional play queue ID to create playlist from
  Future<Playlist?> createPlaylist({
    required String title,
    String? uri,
    int? playQueueId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': 'video',
        'title': title,
        'smart': '0',
      };

      if (uri != null) {
        queryParams['uri'] = uri;
      }
      if (playQueueId != null) {
        queryParams['playQueueID'] = playQueueId.toString();
      }

      final response = await _dio.post(
        '/playlists',
        queryParameters: queryParams,
      );
      final container = _getMediaContainer(response);

      if (container == null || container['Metadata'] == null) {
        return null;
      }

      final List<dynamic> metadata = container['Metadata'] as List;

      if (metadata.isEmpty) {
        return null;
      }

      return Playlist.fromJson(metadata.first as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to create playlist: $e');
      return null;
    }
  }

  /// Delete a playlist
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      await _dio.delete('/playlists/$playlistId');
      return true;
    } catch (e) {
      appLogger.e('Failed to delete playlist: $e');
      return false;
    }
  }

  /// Add items to a playlist
  /// [playlistId] - The playlist to add items to
  /// [uri] - Comma-separated list of item URIs to add
  Future<bool> addToPlaylist({
    required String playlistId,
    required String uri,
  }) async {
    try {
      appLogger.d(
        'Adding to playlist $playlistId with URI: ${uri.substring(0, uri.length > 100 ? 100 : uri.length)}${uri.length > 100 ? "..." : ""}',
      );
      final response = await _dio.put(
        '/playlists/$playlistId/items',
        queryParameters: {'uri': uri},
      );
      appLogger.d('Add to playlist response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      appLogger.e('Failed to add to playlist', error: e);
      return false;
    }
  }

  /// Remove an item from a playlist
  /// [playlistId] - The playlist to remove from
  /// [playlistItemId] - The playlist item ID to remove (from the item's playlistItemID field)
  Future<bool> removeFromPlaylist({
    required String playlistId,
    required String playlistItemId,
  }) async {
    try {
      await _dio.delete('/playlists/$playlistId/items/$playlistItemId');
      return true;
    } catch (e) {
      appLogger.e('Failed to remove from playlist: $e');
      return false;
    }
  }

  /// Move a playlist item to a new position
  /// Only works with non-smart playlists
  /// [playlistId] - The playlist rating key
  /// [playlistItemId] - The playlist item ID to move
  /// [afterPlaylistItemId] - Move the item after this playlist item ID (0 = move to top)
  Future<bool> movePlaylistItem({
    required String playlistId,
    required int playlistItemId,
    required int afterPlaylistItemId,
  }) async {
    try {
      appLogger.d(
        'Moving playlist item $playlistItemId after $afterPlaylistItemId in playlist $playlistId',
      );
      await _dio.put(
        '/playlists/$playlistId/items/$playlistItemId/move',
        queryParameters: {'after': afterPlaylistItemId},
      );
      appLogger.d('Successfully moved playlist item');
      return true;
    } catch (e) {
      appLogger.e('Failed to move playlist item', error: e);
      return false;
    }
  }

  /// Clear all items from a playlist
  Future<bool> clearPlaylist(String playlistId) async {
    try {
      await _dio.delete('/playlists/$playlistId/items');
      return true;
    } catch (e) {
      appLogger.e('Failed to clear playlist: $e');
      return false;
    }
  }

  /// Update playlist metadata (e.g., title, summary)
  /// Uses the same metadata editing mechanism as other items
  Future<bool> updatePlaylist({
    required String playlistId,
    String? title,
    String? summary,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': 'playlist',
        'id': playlistId,
      };

      if (title != null) {
        queryParams['title.value'] = title;
        queryParams['title.locked'] = '1';
      }
      if (summary != null) {
        queryParams['summary.value'] = summary;
        queryParams['summary.locked'] = '1';
      }

      await _dio.put(
        '/library/metadata/$playlistId',
        queryParameters: queryParams,
      );
      return true;
    } catch (e) {
      appLogger.e('Failed to update playlist: $e');
      return false;
    }
  }

  // ============================================================================
  // Collection Methods
  // ============================================================================

  /// Get all collections for a library section
  /// Returns collections as MediaItem objects with type="collection"
  Future<List<MediaItem>> getLibraryCollections(String sectionId) async {
    try {
      final response = await _dio.get(
        '/library/sections/$sectionId/collections',
        queryParameters: {'includeGuids': 1},
      );
      final allItems = _extractMetadataList(response);

      // Collections should have type="collection"
      return allItems.where((item) {
        return item.type.toLowerCase() == 'collection';
      }).toList();
    } catch (e) {
      appLogger.e('Failed to get library collections: $e');
      return [];
    }
  }

  /// Get items in a collection
  /// Returns the list of metadata items in the collection
  Future<List<MediaItem>> getCollectionItems(String collectionId) async {
    try {
      final response = await _dio.get(
        '/library/collections/$collectionId/children',
      );
      return _extractMetadataList(response);
    } catch (e) {
      appLogger.e('Failed to get collection items: $e');
      return [];
    }
  }

  /// Delete a collection
  /// Deletes a library collection from the server
  Future<bool> deleteCollection(String sectionId, String collectionId) async {
    try {
      appLogger.d(
        'Deleting collection: sectionId=$sectionId, collectionId=$collectionId',
      );
      final response = await _dio.delete('/library/collections/$collectionId');
      appLogger.d('Delete collection response: ${response.statusCode}');
      return true;
    } catch (e) {
      appLogger.e('Failed to delete collection', error: e);
      return false;
    }
  }

  /// Create a new collection
  /// Creates a new collection and optionally adds items to it
  /// Returns the created collection ID or null if failed
  Future<String?> createCollection({
    required String sectionId,
    required String title,
    required String uri,
    int? type,
  }) async {
    try {
      appLogger.d(
        'Creating collection: sectionId=$sectionId, title=$title, type=$type',
      );
      final response = await _dio.post(
        '/library/collections',
        queryParameters: {
          if (type != null) 'type': type,
          'title': title,
          'smart': 0,
          'sectionId': sectionId,
          'uri': uri,
        },
      );
      appLogger.d('Create collection response: ${response.statusCode}');

      // Extract the collection ID from the response
      // The response should contain the created collection metadata
      if (response.data != null && response.data['MediaContainer'] != null) {
        final metadata = response.data['MediaContainer']['Metadata'];
        if (metadata != null && metadata.isNotEmpty) {
          final collectionId = metadata[0]['ratingKey']?.toString();
          appLogger.d('Created collection with ID: $collectionId');
          return collectionId;
        }
      }

      return null;
    } catch (e) {
      appLogger.e('Failed to create collection', error: e);
      return null;
    }
  }

  /// Add items to an existing collection
  /// Adds one or more items (specified by URI) to an existing collection
  Future<bool> addToCollection({
    required String collectionId,
    required String uri,
  }) async {
    try {
      appLogger.d('Adding items to collection: collectionId=$collectionId');
      final response = await _dio.put(
        '/library/collections/$collectionId/items',
        queryParameters: {'uri': uri},
      );
      appLogger.d('Add to collection response: ${response.statusCode}');
      return true;
    } catch (e) {
      appLogger.e('Failed to add items to collection', error: e);
      return false;
    }
  }

  /// Remove an item from a collection
  /// Removes a single item from an existing collection
  Future<bool> removeFromCollection({
    required String collectionId,
    required String itemId,
  }) async {
    try {
      appLogger.d(
        'Removing item from collection: collectionId=$collectionId, itemId=$itemId',
      );
      final response = await _dio.delete(
        '/library/collections/$collectionId/items/$itemId',
      );
      appLogger.d('Remove from collection response: ${response.statusCode}');
      return true;
    } catch (e) {
      appLogger.e('Failed to remove item from collection', error: e);
      return false;
    }
  }

  // ============================================================================
  // Play Queue Methods
  // ============================================================================

  /// Create a new play queue
  /// Either uri or playlistID must be specified
  Future<PlayQueueResponse?> createPlayQueue({
    String? uri,
    int? playlistID,
    required String type,
    String? key,
    int shuffle = 0,
    int repeat = 0,
    int continuous = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': type,
        'shuffle': shuffle,
        'repeat': repeat,
        'continuous': continuous,
      };

      if (uri != null) {
        queryParams['uri'] = uri;
      }
      if (playlistID != null) {
        queryParams['playlistID'] = playlistID;
      }
      if (key != null) {
        queryParams['key'] = key;
      }

      final response = await _dio.post(
        '/playQueues',
        queryParameters: queryParams,
      );

      return PlayQueueResponse.fromJson(
        response.data,
        serverId: serverId,
        serverName: serverName,
      );
    } catch (e) {
      appLogger.e('Failed to create play queue', error: e);
      return null;
    }
  }

  /// Get a play queue with optional windowing
  /// Can request a window of items around a specific item
  Future<PlayQueueResponse?> getPlayQueue(
    int playQueueId, {
    String? center,
    int window = 50,
    int includeBefore = 1,
    int includeAfter = 1,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'window': window,
        'includeBefore': includeBefore,
        'includeAfter': includeAfter,
      };

      if (center != null) {
        queryParams['center'] = center;
      }

      final response = await _dio.get(
        '/playQueues/$playQueueId',
        queryParameters: queryParams,
      );

      return PlayQueueResponse.fromJson(
        response.data,
        serverId: serverId,
        serverName: serverName,
      );
    } catch (e) {
      appLogger.e('Failed to get play queue: $e');
      return null;
    }
  }

  /// Shuffle a play queue
  /// The currently selected item is maintained
  Future<PlayQueueResponse?> shufflePlayQueue(int playQueueId) async {
    try {
      final response = await _dio.put('/playQueues/$playQueueId/shuffle');
      return PlayQueueResponse.fromJson(response.data);
    } catch (e) {
      appLogger.e('Failed to shuffle play queue: $e');
      return null;
    }
  }

  /// Clear all items from a play queue
  Future<bool> clearPlayQueue(int playQueueId) async {
    try {
      await _dio.delete('/playQueues/$playQueueId/items');
      return true;
    } catch (e) {
      appLogger.e('Failed to clear play queue: $e');
      return false;
    }
  }

  /// Create a play queue for a TV show (all episodes)
  ///
  /// This is a convenience method that creates a play queue from a show's URI.
  /// Perfect for sequential or shuffle playback of an entire series.
  ///
  /// Parameters:
  /// - [showRatingKey]: The rating key of the show
  /// - [shuffle]: Whether to shuffle the episodes (0 = off, 1 = on)
  /// - [startingEpisodeKey]: Optional rating key of episode to start from
  ///
  /// Returns a PlayQueueResponse with all episodes from the show
  Future<PlayQueueResponse?> createShowPlayQueue({
    required String showRatingKey,
    int shuffle = 0,
    String? startingEpisodeKey,
  }) async {
    try {
      // Get machine identifier for building the URI
      final machineId =
          config.machineIdentifier ?? await getMachineIdentifier();
      if (machineId == null) {
        throw Exception('Could not get server machine identifier');
      }

      // Build the URI for the show's episodes
      final uri =
          'server://$machineId/com.plexapp.plugins.library/library/metadata/$showRatingKey/children';

      // Create the play queue with optional starting episode
      return await createPlayQueue(
        uri: uri,
        type: 'video',
        shuffle: shuffle,
        key: startingEpisodeKey != null
            ? '/library/metadata/$startingEpisodeKey'
            : null,
      );
    } catch (e) {
      appLogger.e('Failed to create show play queue', error: e);
      return null;
    }
  }

  /// Extract both Metadata and Directory entries from response
  /// Folders can come back as either type
  /// Automatically tags all items with this client's serverId and serverName
  List<MediaItem> _extractMetadataAndDirectories(Response response) {
    final List<MediaItem> items = [];
    final container = _getMediaContainer(response);

    if (container != null) {
      // Extract Metadata entries - try full parsing first
      if (container['Metadata'] != null) {
        for (final json in container['Metadata'] as List) {
          try {
            // Try to parse with full MediaItem.fromJson first
            items.add(
              MediaItem.fromJson(
                json,
              ).copyWith(serverId: serverId, serverName: serverName),
            );
          } catch (e) {
            // If full parsing fails, use minimal safe parsing
            appLogger.d('Using minimal parsing for metadata item: $e');
            try {
              items.add(
                MediaItem(
                  ratingKey: json['key'] ?? json['ratingKey'] ?? '',
                  key: json['key'] ?? '',
                  type: json['type'] ?? 'folder',
                  title: json['title'] ?? 'Untitled',
                  thumb: json['thumb'],
                  art: json['art'],
                  year: json['year'],
                  serverId: serverId,
                  serverName: serverName,
                ),
              );
            } catch (e2) {
              appLogger.e('Failed to parse metadata item: $e2');
            }
          }
        }
      }

      // Extract Directory entries (folders)
      if (container['Directory'] != null) {
        for (final json in container['Directory'] as List) {
          try {
            // Try to parse as MediaItem first
            items.add(
              MediaItem.fromJson(
                json,
              ).copyWith(serverId: serverId, serverName: serverName),
            );
          } catch (e) {
            // If that fails, use minimal folder representation
            try {
              items.add(
                MediaItem(
                  ratingKey: json['key'] ?? json['ratingKey'] ?? '',
                  key: json['key'] ?? '',
                  type: json['type'] ?? 'folder',
                  title: json['title'] ?? 'Untitled',
                  thumb: json['thumb'],
                  art: json['art'],
                  serverId: serverId,
                  serverName: serverName,
                ),
              );
            } catch (e2) {
              appLogger.e('Failed to parse directory item: $e2');
            }
          }
        }
      }
    }

    return items;
  }

  /// Get root folders for a library section
  /// Returns the top-level folder structure for filesystem-based browsing
  Future<List<MediaItem>> getLibraryFolders(String sectionId) async {
    try {
      final response = await _dio.get(
        '/library/sections/$sectionId/folder',
        queryParameters: {'includeCollections': 0},
      );
      return _extractMetadataAndDirectories(response);
    } catch (e) {
      appLogger.e('Failed to get library folders: $e');
      return [];
    }
  }

  /// Get children of a specific folder
  /// Returns files and subfolders within the given folder
  Future<List<MediaItem>> getFolderChildren(String folderKey) async {
    try {
      final response = await _dio.get(folderKey);
      return _extractMetadataAndDirectories(response);
    } catch (e) {
      appLogger.e('Failed to get folder children: $e');
      return [];
    }
  }

  /// Get library-specific playlists
  /// Filters playlists by checking if they contain items from the specified library
  /// This is a client-side filter since the API doesn't support sectionId for playlists
  Future<List<Playlist>> getLibraryPlaylists({
    required String sectionId,
    String playlistType = 'video',
  }) async {
    // For now, return all video playlists
    // Future enhancement: filter by checking playlist items' library
    return getPlaylists(playlistType: playlistType);
  }

  // ============================================================================
  // Library Management Methods
  // ============================================================================

  /// Scan/refresh a library section to detect new files
  Future<void> scanLibrary(String sectionId) async {
    await _dio.get('/library/sections/$sectionId/refresh');
  }

  /// Refresh metadata for a library section
  Future<void> refreshLibraryMetadata(String sectionId) async {
    await _dio.get('/library/sections/$sectionId/refresh?force=1');
  }

  /// Empty trash for a library section
  Future<void> emptyLibraryTrash(String sectionId) async {
    await _dio.put('/library/sections/$sectionId/emptyTrash');
  }

  /// Analyze library section
  Future<void> analyzeLibrary(String sectionId) async {
    await _dio.get('/library/sections/$sectionId/analyze');
  }

  Future<void> _handleEndpointSwitch(String newBaseUrl) async {
    if (config.baseUrl == newBaseUrl) {
      return;
    }

    appLogger.i('Applying Plex endpoint switch', error: newBaseUrl);
    _dio.options.baseUrl = newBaseUrl;
    config = config.copyWith(baseUrl: newBaseUrl);
    LogRedactionManager.registerServerUrl(newBaseUrl);

    if (_onEndpointChanged != null) {
      await _onEndpointChanged(newBaseUrl);
    }
  }

  // ============================================================================
  // Live TV Methods
  // ============================================================================

  /// Get all Live TV channels
  Future<List<LiveTVChannel>> getLiveTVChannels() async {
    try {
      final response = await _dio.get('/livetv/channels');
      // Server returns {"channels": [...]}
      if (response.data is Map && response.data['channels'] is List) {
        return (response.data['channels'] as List)
            .map((json) => LiveTVChannel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      // Fallback for direct list response
      if (response.data is List) {
        return (response.data as List)
            .map((json) => LiveTVChannel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      appLogger.e('Failed to get Live TV channels', error: e);
      return [];
    }
  }

  /// Get a specific Live TV channel by ID
  Future<LiveTVChannel?> getLiveTVChannel(int channelId) async {
    try {
      final response = await _dio.get('/livetv/channels/$channelId');
      return LiveTVChannel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to get Live TV channel', error: e);
      return null;
    }
  }

  /// Get EPG guide data for a time range
  /// [start] and [end] are ISO 8601 datetime strings
  /// [channelIds] is an optional list of channel IDs to filter by
  Future<LiveTVGuideData?> getLiveTVGuide({
    DateTime? start,
    DateTime? end,
    List<String>? channelIds,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (start != null) queryParams['start'] = start.toIso8601String();
      if (end != null) queryParams['end'] = end.toIso8601String();
      if (channelIds != null && channelIds.isNotEmpty) {
        queryParams['channelIds'] = channelIds.join(',');
      }

      final response = await _dio.get(
        '/livetv/guide',
        queryParameters: queryParams,
      );
      return LiveTVGuideData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to get Live TV guide', error: e);
      return null;
    }
  }

  /// Get what's currently playing on all channels
  Future<List<LiveTVChannel>> getLiveTVWhatsOnNow() async {
    try {
      final response = await _dio.get('/livetv/now');
      // Server returns {"channels": [...]}
      if (response.data is Map && response.data['channels'] is List) {
        return (response.data['channels'] as List)
            .map((json) => LiveTVChannel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      // Fallback for direct list response
      if (response.data is List) {
        return (response.data as List)
            .map((json) => LiveTVChannel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      appLogger.e('Failed to get what\'s on now', error: e);
      return [];
    }
  }

  /// Get Live TV sources (M3U playlists)
  Future<List<LiveTVSource>> getLiveTVSources() async {
    try {
      final response = await _dio.get('/livetv/sources');
      // Server returns {"sources": [...]}
      if (response.data is Map && response.data['sources'] is List) {
        return (response.data['sources'] as List)
            .map((json) => LiveTVSource.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      // Fallback for direct list response
      if (response.data is List) {
        return (response.data as List)
            .map((json) => LiveTVSource.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      appLogger.e('Failed to get Live TV sources', error: e);
      return [];
    }
  }

  /// Add a new Live TV source (M3U playlist)
  Future<LiveTVSource?> addLiveTVSource({
    required String name,
    required String url,
    String? epgUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/livetv/sources',
        data: {
          'name': name,
          'url': url,
          if (epgUrl != null) 'epgUrl': epgUrl,
        },
      );
      return LiveTVSource.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to add Live TV source', error: e);
      return null;
    }
  }

  /// Refresh a Live TV source (re-fetch M3U playlist)
  Future<bool> refreshLiveTVSource(int sourceId) async {
    try {
      await _dio.post('/livetv/sources/$sourceId/refresh');
      return true;
    } catch (e) {
      appLogger.e('Failed to refresh Live TV source', error: e);
      return false;
    }
  }

  /// Delete a Live TV source
  Future<bool> deleteLiveTVSource(int sourceId) async {
    try {
      await _dio.delete('/livetv/sources/$sourceId');
      return true;
    } catch (e) {
      appLogger.e('Failed to delete Live TV source', error: e);
      return false;
    }
  }

  /// Get the stream URL for a Live TV channel
  /// This builds a URL that can be used directly for playback
  String getLiveTVStreamUrl(LiveTVChannel channel) {
    // Some IPTV playlists use the VLC-style pipe header syntax:
    //   url|Header=Value&Header2=Value2
    // Token/baseUrl must be applied to the URL portion only.
    final raw = channel.streamUrl;
    final pipeIndex = raw.indexOf('|');
    final urlPart = pipeIndex >= 0 ? raw.substring(0, pipeIndex) : raw;
    final headersPart = pipeIndex >= 0 ? raw.substring(pipeIndex + 1) : null;

    // The server proxies the stream, so we use the channel's streamUrl.
    // If it's a relative URL, prefix with base URL and token.
    final resolvedUrl = urlPart.startsWith('http')
        ? urlPart
        : _appendToken('${config.baseUrl}$urlPart');

    if (headersPart != null && headersPart.isNotEmpty) {
      return '$resolvedUrl|$headersPart';
    }
    return resolvedUrl;
  }

  /// Toggle the favorite status of a Live TV channel
  Future<LiveTVChannel?> toggleChannelFavorite(int channelId) async {
    try {
      final response = await _dio.post('/livetv/channels/$channelId/favorite');
      if (response.data != null) {
        return LiveTVChannel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      appLogger.e('Failed to toggle channel favorite', error: e);
      return null;
    }
  }

  // ========== DVR Methods ==========

  /// Get all DVR recordings for the current user
  Future<List<DVRRecording>> getDVRRecordings({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        '/dvr/recordings',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data as Map<String, dynamic>;
      final recordings = data['recordings'] as List<dynamic>? ?? [];
      return recordings
          .map((json) => DVRRecording.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      appLogger.e('Failed to get DVR recordings', error: e);
      return [];
    }
  }

  /// Get a specific DVR recording
  Future<DVRRecording?> getDVRRecording(int recordingId) async {
    try {
      final response = await _dio.get('/dvr/recordings/$recordingId');
      return DVRRecording.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to get DVR recording', error: e);
      return null;
    }
  }

  /// Schedule a new DVR recording
  Future<DVRRecording?> scheduleRecording({
    required int channelId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    int? programId,
    String? description,
  }) async {
    try {
      final response = await _dio.post('/dvr/recordings', data: {
        'channelId': channelId,
        'title': title,
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
        if (programId != null) 'programId': programId,
        if (description != null) 'description': description,
      });
      return DVRRecording.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to schedule recording', error: e);
      return null;
    }
  }

  /// Delete a DVR recording
  Future<bool> deleteDVRRecording(int recordingId) async {
    try {
      await _dio.delete('/dvr/recordings/$recordingId');
      return true;
    } catch (e) {
      appLogger.e('Failed to delete DVR recording', error: e);
      return false;
    }
  }

  /// Get all series recording rules
  Future<List<DVRSeriesRule>> getSeriesRules() async {
    try {
      final response = await _dio.get('/dvr/rules');
      final data = response.data as Map<String, dynamic>;
      final rules = data['rules'] as List<dynamic>? ?? [];
      return rules
          .map((json) => DVRSeriesRule.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      appLogger.e('Failed to get series rules', error: e);
      return [];
    }
  }

  /// Create a new series recording rule
  Future<DVRSeriesRule?> createSeriesRule({
    required String title,
    int? channelId,
    String? keywords,
    String? timeSlot,
    String? daysOfWeek,
    int keepCount = 0,
    int prePadding = 0,
    int postPadding = 0,
  }) async {
    try {
      final response = await _dio.post('/dvr/rules', data: {
        'title': title,
        if (channelId != null) 'channelId': channelId,
        if (keywords != null) 'keywords': keywords,
        if (timeSlot != null) 'timeSlot': timeSlot,
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        'keepCount': keepCount,
        'prePadding': prePadding,
        'postPadding': postPadding,
      });
      return DVRSeriesRule.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to create series rule', error: e);
      return null;
    }
  }

  /// Update a series recording rule
  Future<DVRSeriesRule?> updateSeriesRule(
    int ruleId, {
    String? title,
    int? channelId,
    String? keywords,
    String? timeSlot,
    String? daysOfWeek,
    int? keepCount,
    int? prePadding,
    int? postPadding,
    bool? enabled,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (channelId != null) data['channelId'] = channelId;
      if (keywords != null) data['keywords'] = keywords;
      if (timeSlot != null) data['timeSlot'] = timeSlot;
      if (daysOfWeek != null) data['daysOfWeek'] = daysOfWeek;
      if (keepCount != null) data['keepCount'] = keepCount;
      if (prePadding != null) data['prePadding'] = prePadding;
      if (postPadding != null) data['postPadding'] = postPadding;
      if (enabled != null) data['enabled'] = enabled;

      final response = await _dio.put('/dvr/rules/$ruleId', data: data);
      return DVRSeriesRule.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to update series rule', error: e);
      return null;
    }
  }

  /// Delete a series recording rule
  Future<bool> deleteSeriesRule(int ruleId) async {
    try {
      await _dio.delete('/dvr/rules/$ruleId');
      return true;
    } catch (e) {
      appLogger.e('Failed to delete series rule', error: e);
      return false;
    }
  }

  // ========== Commercial Detection Methods ==========

  /// Get commercial detection status
  Future<bool> isCommercialDetectionEnabled() async {
    try {
      final response = await _dio.get('/dvr/commercials/status');
      final data = response.data as Map<String, dynamic>;
      return data['enabled'] as bool? ?? false;
    } catch (e) {
      appLogger.e('Failed to get commercial detection status', error: e);
      return false;
    }
  }

  /// Get commercial segments for a recording
  Future<CommercialSegmentsResponse?> getCommercialSegments(int recordingId) async {
    try {
      final response = await _dio.get('/dvr/recordings/$recordingId/commercials');
      return CommercialSegmentsResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      appLogger.e('Failed to get commercial segments', error: e);
      return null;
    }
  }

  /// Trigger commercial detection on a recording
  Future<bool> rerunCommercialDetection(int recordingId) async {
    try {
      await _dio.post('/dvr/recordings/$recordingId/commercials/detect');
      return true;
    } catch (e) {
      appLogger.e('Failed to rerun commercial detection', error: e);
      return false;
    }
  }
}
