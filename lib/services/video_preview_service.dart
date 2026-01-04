import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/media_item.dart';
import 'tmdb_service.dart';

/// Service to manage video preview state and caching
class VideoPreviewService extends ChangeNotifier {
  static VideoPreviewService? _instance;

  final Map<String, TrailerInfo?> _trailerCache = {};
  final Map<String, bool> _loadingState = {};

  // Current preview state
  MediaItem? _currentPreviewItem;
  bool _isPreviewActive = false;
  bool _isMuted = true;
  Timer? _unmuteTimer;

  VideoPreviewService._();

  static VideoPreviewService get instance {
    _instance ??= VideoPreviewService._();
    return _instance!;
  }

  MediaItem? get currentPreviewItem => _currentPreviewItem;
  bool get isPreviewActive => _isPreviewActive;
  bool get isMuted => _isMuted;

  /// Get cached trailer info for an item
  TrailerInfo? getCachedTrailer(String itemKey) => _trailerCache[itemKey];

  /// Check if trailer is loading for an item
  bool isLoading(String itemKey) => _loadingState[itemKey] ?? false;

  /// Pre-fetch trailer info for an item
  Future<TrailerInfo?> fetchTrailer(MediaItem item) async {
    final key = item.globalKey;

    // Return cached result
    if (_trailerCache.containsKey(key)) {
      return _trailerCache[key];
    }

    // Already loading
    if (_loadingState[key] == true) {
      return null;
    }

    _loadingState[key] = true;
    notifyListeners();

    try {
      final tmdb = await TmdbService.getInstance();
      if (!tmdb.hasApiKey) {
        _loadingState[key] = false;
        _trailerCache[key] = null;
        return null;
      }

      final isMovie = item.type.toLowerCase() == 'movie';
      final title = item.grandparentTitle ?? item.title;

      final trailer = await tmdb.getTrailerForTitle(
        title,
        isMovie: isMovie,
        year: item.year,
      );

      _trailerCache[key] = trailer;
      _loadingState[key] = false;
      notifyListeners();

      return trailer;
    } catch (e) {
      _loadingState[key] = false;
      _trailerCache[key] = null;
      notifyListeners();
      return null;
    }
  }

  /// Start preview for an item
  void startPreview(MediaItem item) {
    _currentPreviewItem = item;
    _isPreviewActive = true;
    _isMuted = true;

    // Auto-unmute after 3 seconds
    _unmuteTimer?.cancel();
    _unmuteTimer = Timer(const Duration(seconds: 3), () {
      if (_isPreviewActive) {
        _isMuted = false;
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Stop current preview
  void stopPreview() {
    _currentPreviewItem = null;
    _isPreviewActive = false;
    _isMuted = true;
    _unmuteTimer?.cancel();
    notifyListeners();
  }

  /// Toggle mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  /// Pre-fetch trailers for a list of items
  Future<void> prefetchTrailers(List<MediaItem> items) async {
    for (final item in items.take(10)) {
      // Only prefetch for movies and shows, not episodes
      if (item.type == 'movie' || item.type == 'show') {
        // Don't await - fire and forget
        fetchTrailer(item);
      }
    }
  }

  /// Clear cache
  void clearCache() {
    _trailerCache.clear();
    _loadingState.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _unmuteTimer?.cancel();
    super.dispose();
  }
}
