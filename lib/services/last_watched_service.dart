import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/livetv_channel.dart';
import '../utils/app_logger.dart';

/// Service for tracking the user's last watched channel
/// Used for the docked player on home screen and startup behavior
class LastWatchedService {
  static const String _lastWatchedChannelKey = 'last_watched_channel';
  static const String _lastWatchedTimestampKey = 'last_watched_timestamp';
  static const String _watchHistoryKey = 'watch_history';
  static const String _startupBehaviorKey = 'startup_behavior';
  static const int _maxHistoryItems = 10;

  static LastWatchedService? _instance;
  late SharedPreferences _prefs;

  // Cached last watched channel for quick access
  LiveTVChannel? _cachedLastChannel;
  DateTime? _cachedTimestamp;

  // Stream controller for notifying listeners of changes
  final _lastWatchedController = StreamController<LiveTVChannel?>.broadcast();
  Stream<LiveTVChannel?> get lastWatchedStream => _lastWatchedController.stream;

  LastWatchedService._();

  static Future<LastWatchedService> getInstance() async {
    if (_instance == null) {
      _instance = LastWatchedService._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCachedChannel();
  }

  Future<void> _loadCachedChannel() async {
    try {
      final channelJson = _prefs.getString(_lastWatchedChannelKey);
      if (channelJson != null && channelJson.isNotEmpty) {
        final data = jsonDecode(channelJson) as Map<String, dynamic>;
        _cachedLastChannel = LiveTVChannel.fromJson(data);

        final timestampStr = _prefs.getString(_lastWatchedTimestampKey);
        if (timestampStr != null) {
          _cachedTimestamp = DateTime.tryParse(timestampStr);
        }

        appLogger.d('Loaded last watched channel: ${_cachedLastChannel?.name}');
      }
    } catch (e) {
      appLogger.e('Failed to load last watched channel', error: e);
    }
  }

  /// Get the last watched channel
  LiveTVChannel? getLastWatchedChannel() {
    return _cachedLastChannel;
  }

  /// Get the timestamp when the channel was last watched
  DateTime? getLastWatchedTimestamp() {
    return _cachedTimestamp;
  }

  /// Check if there's a recently watched channel (within the last 24 hours)
  bool hasRecentlyWatchedChannel() {
    if (_cachedLastChannel == null || _cachedTimestamp == null) {
      return false;
    }
    final hoursSinceLastWatch = DateTime.now().difference(_cachedTimestamp!).inHours;
    return hoursSinceLastWatch < 24;
  }

  /// Set the last watched channel
  Future<void> setLastWatchedChannel(LiveTVChannel channel) async {
    try {
      _cachedLastChannel = channel;
      _cachedTimestamp = DateTime.now();

      final channelJson = jsonEncode(channel.toJson());
      await _prefs.setString(_lastWatchedChannelKey, channelJson);
      await _prefs.setString(
        _lastWatchedTimestampKey,
        _cachedTimestamp!.toIso8601String(),
      );

      // Add to watch history
      await _addToWatchHistory(channel);

      // Notify listeners
      _lastWatchedController.add(channel);

      appLogger.d('Saved last watched channel: ${channel.name}');
    } catch (e) {
      appLogger.e('Failed to save last watched channel', error: e);
    }
  }

  /// Get the watch history (most recent first)
  Future<List<LiveTVChannel>> getWatchHistory() async {
    try {
      final historyJson = _prefs.getString(_watchHistoryKey);
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final List<dynamic> historyList = jsonDecode(historyJson);
      return historyList
          .map((json) => LiveTVChannel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      appLogger.e('Failed to load watch history', error: e);
      return [];
    }
  }

  Future<void> _addToWatchHistory(LiveTVChannel channel) async {
    try {
      final history = await getWatchHistory();

      // Remove existing entry for this channel (to avoid duplicates)
      history.removeWhere((c) => c.id == channel.id);

      // Add to front of list
      history.insert(0, channel);

      // Trim to max items
      while (history.length > _maxHistoryItems) {
        history.removeLast();
      }

      // Save
      final historyJson = jsonEncode(history.map((c) => c.toJson()).toList());
      await _prefs.setString(_watchHistoryKey, historyJson);
    } catch (e) {
      appLogger.e('Failed to add to watch history', error: e);
    }
  }

  /// Clear the last watched channel
  Future<void> clearLastWatched() async {
    _cachedLastChannel = null;
    _cachedTimestamp = null;
    await _prefs.remove(_lastWatchedChannelKey);
    await _prefs.remove(_lastWatchedTimestampKey);
    _lastWatchedController.add(null);
  }

  /// Clear all watch history
  Future<void> clearWatchHistory() async {
    await _prefs.remove(_watchHistoryKey);
  }

  // Startup behavior settings

  /// Startup behavior options
  static const String startupBehaviorHome = 'home';
  static const String startupBehaviorLastChannel = 'last_channel';

  /// Get the startup behavior preference
  String getStartupBehavior() {
    return _prefs.getString(_startupBehaviorKey) ?? startupBehaviorHome;
  }

  /// Set the startup behavior preference
  Future<void> setStartupBehavior(String behavior) async {
    await _prefs.setString(_startupBehaviorKey, behavior);
  }

  /// Check if app should start on last watched channel
  bool shouldStartOnLastChannel() {
    return getStartupBehavior() == startupBehaviorLastChannel &&
           hasRecentlyWatchedChannel();
  }

  void dispose() {
    _lastWatchedController.close();
  }
}
