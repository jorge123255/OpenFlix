import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/media_item.dart';

/// Service for managing a local watchlist of media items
class WatchlistService extends ChangeNotifier {
  static const String _watchlistKey = 'watchlist_items';
  static WatchlistService? _instance;

  final SharedPreferences _prefs;
  List<WatchlistItem> _items = [];

  WatchlistService._(this._prefs) {
    _loadItems();
  }

  static Future<WatchlistService> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = WatchlistService._(prefs);
    }
    return _instance!;
  }

  List<WatchlistItem> get items => List.unmodifiable(_items);

  /// Get items filtered by type
  List<WatchlistItem> getItemsByType(WatchlistItemType type) {
    return _items.where((item) => item.type == type).toList();
  }

  /// Check if an item is in the watchlist
  bool isInWatchlist(String ratingKey, String serverId) {
    return _items.any(
      (item) => item.ratingKey == ratingKey && item.serverId == serverId,
    );
  }

  /// Add an item to the watchlist
  Future<void> addToWatchlist(MediaItem mediaItem) async {
    if (isInWatchlist(mediaItem.ratingKey, mediaItem.serverId ?? '')) {
      return; // Already in watchlist
    }

    final type = _getItemType(mediaItem);
    final item = WatchlistItem(
      ratingKey: mediaItem.ratingKey,
      serverId: mediaItem.serverId ?? '',
      title: mediaItem.title,
      type: type,
      thumbUrl: mediaItem.thumb,
      artUrl: mediaItem.art,
      year: mediaItem.year,
      duration: mediaItem.duration,
      grandparentTitle: mediaItem.grandparentTitle,
      parentIndex: mediaItem.parentIndex,
      index: mediaItem.index,
      addedAt: DateTime.now(),
      mediaItemJson: jsonEncode(mediaItem.toJson()),
    );

    _items.insert(0, item); // Add to beginning
    await _saveItems();
    notifyListeners();
  }

  /// Remove an item from the watchlist
  Future<void> removeFromWatchlist(String ratingKey, String serverId) async {
    _items.removeWhere(
      (item) => item.ratingKey == ratingKey && item.serverId == serverId,
    );
    await _saveItems();
    notifyListeners();
  }

  /// Toggle watchlist status for an item
  Future<bool> toggleWatchlist(MediaItem mediaItem) async {
    final inWatchlist = isInWatchlist(mediaItem.ratingKey, mediaItem.serverId ?? '');
    if (inWatchlist) {
      await removeFromWatchlist(mediaItem.ratingKey, mediaItem.serverId ?? '');
      return false;
    } else {
      await addToWatchlist(mediaItem);
      return true;
    }
  }

  /// Clear all watchlist items
  Future<void> clearWatchlist() async {
    _items.clear();
    await _saveItems();
    notifyListeners();
  }

  WatchlistItemType _getItemType(MediaItem item) {
    switch (item.type?.toLowerCase()) {
      case 'movie':
        return WatchlistItemType.movie;
      case 'show':
        return WatchlistItemType.show;
      case 'episode':
        return WatchlistItemType.episode;
      default:
        return WatchlistItemType.movie;
    }
  }

  void _loadItems() {
    final jsonString = _prefs.getString(_watchlistKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _items = jsonList
            .map((json) => WatchlistItem.fromJson(json))
            .toList();
      } catch (e) {
        _items = [];
      }
    }
  }

  Future<void> _saveItems() async {
    final jsonList = _items.map((item) => item.toJson()).toList();
    await _prefs.setString(_watchlistKey, jsonEncode(jsonList));
  }
}

enum WatchlistItemType { movie, show, episode }

class WatchlistItem {
  final String ratingKey;
  final String serverId;
  final String title;
  final WatchlistItemType type;
  final String? thumbUrl;
  final String? artUrl;
  final int? year;
  final int? duration;
  final String? grandparentTitle;
  final int? parentIndex;
  final int? index;
  final DateTime addedAt;
  final String? mediaItemJson;

  WatchlistItem({
    required this.ratingKey,
    required this.serverId,
    required this.title,
    required this.type,
    this.thumbUrl,
    this.artUrl,
    this.year,
    this.duration,
    this.grandparentTitle,
    this.parentIndex,
    this.index,
    required this.addedAt,
    this.mediaItemJson,
  });

  /// Get the display subtitle (e.g., "S1 · E5" for episodes)
  String? get subtitle {
    if (type == WatchlistItemType.episode && parentIndex != null && index != null) {
      return 'S$parentIndex · E$index';
    }
    if (year != null) {
      return year.toString();
    }
    return null;
  }

  /// Get display title (show name for episodes, otherwise title)
  String get displayTitle {
    if (type == WatchlistItemType.episode && grandparentTitle != null) {
      return grandparentTitle!;
    }
    return title;
  }

  /// Reconstruct the MediaItem from stored JSON
  MediaItem? getMediaItem() {
    if (mediaItemJson == null) return null;
    try {
      return MediaItem.fromJson(jsonDecode(mediaItemJson!));
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'ratingKey': ratingKey,
    'serverId': serverId,
    'title': title,
    'type': type.name,
    'thumbUrl': thumbUrl,
    'artUrl': artUrl,
    'year': year,
    'duration': duration,
    'grandparentTitle': grandparentTitle,
    'parentIndex': parentIndex,
    'index': index,
    'addedAt': addedAt.toIso8601String(),
    'mediaItemJson': mediaItemJson,
  };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
    ratingKey: json['ratingKey'],
    serverId: json['serverId'],
    title: json['title'],
    type: WatchlistItemType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => WatchlistItemType.movie,
    ),
    thumbUrl: json['thumbUrl'],
    artUrl: json['artUrl'],
    year: json['year'],
    duration: json['duration'],
    grandparentTitle: json['grandparentTitle'],
    parentIndex: json['parentIndex'],
    index: json['index'],
    addedAt: DateTime.parse(json['addedAt']),
    mediaItemJson: json['mediaItemJson'],
  );
}
