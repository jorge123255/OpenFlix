import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

/// Represents a channel history entry with timestamp and watch duration
class ChannelHistoryEntry {
  final int channelId;
  final DateTime timestamp;
  final Duration watchDuration;

  ChannelHistoryEntry({
    required this.channelId,
    required this.timestamp,
    this.watchDuration = Duration.zero,
  });

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'timestamp': timestamp.toIso8601String(),
      'watchDuration': watchDuration.inSeconds,
    };
  }

  factory ChannelHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ChannelHistoryEntry(
      channelId: json['channelId'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      watchDuration: Duration(seconds: json['watchDuration'] as int? ?? 0),
    );
  }

  ChannelHistoryEntry copyWith({
    int? channelId,
    DateTime? timestamp,
    Duration? watchDuration,
  }) {
    return ChannelHistoryEntry(
      channelId: channelId ?? this.channelId,
      timestamp: timestamp ?? this.timestamp,
      watchDuration: watchDuration ?? this.watchDuration,
    );
  }
}

/// Service to manage Live TV channel history for quick navigation
/// Tracks recently watched channels and supports "previous channel" functionality
class ChannelHistoryService {
  static final ChannelHistoryService _instance =
      ChannelHistoryService._internal();
  factory ChannelHistoryService() => _instance;
  ChannelHistoryService._internal();

  static const String _storageKey = 'livetv_channel_history';
  static const int _maxHistorySize = 10;

  /// List of channel history entries in chronological order (most recent last)
  final List<ChannelHistoryEntry> _history = [];

  /// Whether the service has been initialized
  bool _isInitialized = false;

  /// Current channel start time for watch duration tracking
  DateTime? _currentChannelStartTime;

  /// Initialize the service by loading saved history
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadHistory();
      _isInitialized = true;
      appLogger.d('Channel history loaded: $_history');
    } catch (e) {
      appLogger.e('Failed to load channel history', error: e);
    }
  }

  /// Add a channel to the history
  /// This is called when the user switches to a channel
  void addChannel(int channelId) {
    // Calculate watch duration for previous channel
    if (_currentChannelStartTime != null && _history.isNotEmpty) {
      final watchDuration = DateTime.now().difference(_currentChannelStartTime!);
      final lastEntry = _history.last;
      // Update the last entry with watch duration
      _history[_history.length - 1] = lastEntry.copyWith(
        watchDuration: watchDuration,
      );
    }

    // Remove existing entries for this channel to avoid duplicates
    _history.removeWhere((entry) => entry.channelId == channelId);

    // Add new entry to the end of the list (most recent)
    final newEntry = ChannelHistoryEntry(
      channelId: channelId,
      timestamp: DateTime.now(),
    );
    _history.add(newEntry);

    // Start tracking watch time for this channel
    _currentChannelStartTime = DateTime.now();

    // Trim history if it exceeds max size
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }

    // Save to persistent storage
    _saveHistory();

    appLogger.d('Channel added to history: $channelId, total entries: ${_history.length}');
  }

  /// Get the previous channel ID for "last channel" functionality
  /// Returns null if there's no previous channel
  int? getPreviousChannel(int currentChannelId) {
    // If history is empty or only has one item, no previous channel
    if (_history.length <= 1) return null;

    // Find current channel in history
    final currentIndex = _history.indexWhere(
      (entry) => entry.channelId == currentChannelId,
    );
    if (currentIndex < 0) {
      // Current channel not in history, return the last one
      return _history.last.channelId;
    }

    // If we're at the beginning, no previous channel
    if (currentIndex == 0) return null;

    // Return the channel before the current one
    return _history[currentIndex - 1].channelId;
  }

  /// Get the channel history for display
  /// Returns list in reverse chronological order (most recent first)
  List<ChannelHistoryEntry> getHistory() {
    return _history.reversed.toList();
  }

  /// Remove a channel entry from history
  void removeEntry(int channelId) {
    _history.removeWhere((entry) => entry.channelId == channelId);
    _saveHistory();
    appLogger.d('Channel removed from history: $channelId');
  }

  /// Clear all channel history
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
    appLogger.d('Channel history cleared');
  }

  /// Load history from SharedPreferences
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);

      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _history.clear();
        _history.addAll(
          decoded.map((e) => ChannelHistoryEntry.fromJson(e as Map<String, dynamic>)),
        );
      }
    } catch (e) {
      appLogger.e('Failed to load channel history', error: e);
    }
  }

  /// Save history to SharedPreferences
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(
        _history.map((entry) => entry.toJson()).toList(),
      );
      await prefs.setString(_storageKey, historyJson);
    } catch (e) {
      appLogger.e('Failed to save channel history', error: e);
    }
  }

  /// Reset the service (for testing)
  void reset() {
    _history.clear();
    _isInitialized = false;
  }
}
