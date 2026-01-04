import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';

/// Service for managing shared tuner sessions
class TunerSharingService {
  final String baseUrl;
  final String token;

  String? _currentSessionId;
  int? _currentChannelId;
  Timer? _heartbeatTimer;

  TunerSharingService({
    required this.baseUrl,
    required this.token,
  });

  /// Join a channel, potentially sharing a tuner with other viewers
  Future<JoinResult> joinChannel({
    required int channelId,
    required String sessionId,
    String deviceName = 'OpenFlix Client',
    String deviceType = 'tv',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/livetv/tuner/join'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'channelId': channelId,
          'sessionId': sessionId,
          'deviceName': deviceName,
          'deviceType': deviceType,
        }),
      );

      if (response.statusCode == 200) {
        final result = JoinResult.fromJson(json.decode(response.body));

        if (result.success) {
          _currentSessionId = sessionId;
          _currentChannelId = channelId;
          _startHeartbeat();

          appLogger.d(
            'Joined channel $channelId (shared: ${result.isShared}, viewers: ${result.viewerCount})',
          );
        }

        return result;
      } else {
        return JoinResult(
          success: false,
          error: 'Failed to join channel: ${response.statusCode}',
        );
      }
    } catch (e) {
      appLogger.e('Failed to join channel', error: e);
      return JoinResult(success: false, error: e.toString());
    }
  }

  /// Leave the current channel
  Future<void> leaveChannel() async {
    if (_currentSessionId == null || _currentChannelId == null) return;

    _stopHeartbeat();

    try {
      await http.post(
        Uri.parse('$baseUrl/livetv/tuner/leave'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'channelId': _currentChannelId,
          'sessionId': _currentSessionId,
        }),
      );

      appLogger.d('Left channel $_currentChannelId');
    } catch (e) {
      appLogger.e('Failed to leave channel', error: e);
    } finally {
      _currentSessionId = null;
      _currentChannelId = null;
    }
  }

  /// Get the current tuner status
  Future<TunerStatus?> getTunerStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/livetv/tuner/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return TunerStatus.fromJson(json.decode(response.body));
      }
    } catch (e) {
      appLogger.e('Failed to get tuner status', error: e);
    }
    return null;
  }

  /// Get viewers for a specific channel
  Future<List<Viewer>> getChannelViewers(int channelId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/livetv/tuner/viewers/$channelId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final viewers = data['viewers'] as List? ?? [];
        return viewers.map((v) => Viewer.fromJson(v)).toList();
      }
    } catch (e) {
      appLogger.e('Failed to get channel viewers', error: e);
    }
    return [];
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendHeartbeat() async {
    if (_currentSessionId == null || _currentChannelId == null) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/livetv/tuner/heartbeat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'channelId': _currentChannelId,
          'sessionId': _currentSessionId,
        }),
      );
    } catch (e) {
      appLogger.d('Heartbeat failed', error: e);
    }
  }

  void dispose() {
    _stopHeartbeat();
  }
}

/// Result of joining a channel
class JoinResult {
  final bool success;
  final String? streamUrl;
  final bool isShared;
  final int viewerCount;
  final bool tunerUsed;
  final String? error;

  JoinResult({
    required this.success,
    this.streamUrl,
    this.isShared = false,
    this.viewerCount = 0,
    this.tunerUsed = false,
    this.error,
  });

  factory JoinResult.fromJson(Map<String, dynamic> json) {
    return JoinResult(
      success: json['success'] ?? false,
      streamUrl: json['streamUrl'],
      isShared: json['isShared'] ?? false,
      viewerCount: json['viewerCount'] ?? 0,
      tunerUsed: json['tunerUsed'] ?? false,
      error: json['error'],
    );
  }
}

/// Current tuner status
class TunerStatus {
  final int activeTuners;
  final int maxTuners;
  final int tunersAvailable;
  final List<SessionInfo> sessions;
  final bool sharingEnabled;

  TunerStatus({
    required this.activeTuners,
    required this.maxTuners,
    required this.tunersAvailable,
    required this.sessions,
    required this.sharingEnabled,
  });

  factory TunerStatus.fromJson(Map<String, dynamic> json) {
    final sessionsList = json['sessions'] as List? ?? [];
    return TunerStatus(
      activeTuners: json['activeTuners'] ?? 0,
      maxTuners: json['maxTuners'] ?? 0,
      tunersAvailable: json['tunersAvailable'] ?? -1,
      sessions: sessionsList.map((s) => SessionInfo.fromJson(s)).toList(),
      sharingEnabled: json['sharingEnabled'] ?? false,
    );
  }

  bool get hasAvailableTuners => tunersAvailable != 0;
  bool get isUnlimited => maxTuners == 0;
}

/// Info about an active tuner session
class SessionInfo {
  final int channelId;
  final String channelName;
  final int viewerCount;
  final DateTime startTime;
  final int durationSeconds;

  SessionInfo({
    required this.channelId,
    required this.channelName,
    required this.viewerCount,
    required this.startTime,
    required this.durationSeconds,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      channelId: json['channelId'] ?? 0,
      channelName: json['channelName'] ?? '',
      viewerCount: json['viewerCount'] ?? 0,
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      durationSeconds: json['duration'] ?? 0,
    );
  }

  Duration get duration => Duration(seconds: durationSeconds);

  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

/// A viewer in a tuner session
class Viewer {
  final int userId;
  final String sessionId;
  final String deviceName;
  final String deviceType;
  final DateTime joinedAt;
  final bool isPrimary;

  Viewer({
    required this.userId,
    required this.sessionId,
    required this.deviceName,
    required this.deviceType,
    required this.joinedAt,
    required this.isPrimary,
  });

  factory Viewer.fromJson(Map<String, dynamic> json) {
    return Viewer(
      userId: json['userId'] ?? 0,
      sessionId: json['sessionId'] ?? '',
      deviceName: json['deviceName'] ?? 'Unknown Device',
      deviceType: json['deviceType'] ?? 'unknown',
      joinedAt: DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
      isPrimary: json['isPrimary'] ?? false,
    );
  }
}
