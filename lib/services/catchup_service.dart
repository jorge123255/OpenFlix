import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Represents a program available for catch-up viewing
class CatchUpProgram {
  final int channelId;
  final String programId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // seconds
  final String? description;
  final String? thumb;
  final bool available;

  CatchUpProgram({
    required this.channelId,
    required this.programId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.description,
    this.thumb,
    required this.available,
  });

  factory CatchUpProgram.fromJson(Map<String, dynamic> json) {
    return CatchUpProgram(
      channelId: json['channelId'] ?? 0,
      programId: json['programId'] ?? '',
      title: json['title'] ?? 'Unknown',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: json['duration'] ?? 0,
      description: json['description'],
      thumb: json['thumb'],
      available: json['available'] ?? false,
    );
  }

  /// Returns formatted duration string (e.g., "1h 30m")
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Returns formatted time range (e.g., "8:00 PM - 9:30 PM")
  String get timeRange {
    String formatTime(DateTime dt) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    }
    return '${formatTime(startTime)} - ${formatTime(endTime)}';
  }
}

/// Information about start-over capability for current program
class StartOverInfo {
  final bool available;
  final String? programTitle;
  final DateTime? programStart;
  final int? offsetSeconds;
  final String? streamUrl;

  StartOverInfo({
    required this.available,
    this.programTitle,
    this.programStart,
    this.offsetSeconds,
    this.streamUrl,
  });

  factory StartOverInfo.fromJson(Map<String, dynamic> json) {
    return StartOverInfo(
      available: json['available'] ?? false,
      programTitle: json['programTitle'],
      programStart: json['programStart'] != null
          ? DateTime.parse(json['programStart'])
          : null,
      offsetSeconds: json['offsetSeconds'],
      streamUrl: json['streamUrl'],
    );
  }
}

/// Service for managing catch-up TV and time-shift features
class CatchUpService {
  static CatchUpService? _instance;
  static CatchUpService get instance {
    _instance ??= CatchUpService._();
    return _instance!;
  }

  CatchUpService._();

  StorageService? _storage;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<StorageService> get _storageService async {
    _storage ??= await StorageService.getInstance();
    return _storage!;
  }

  /// Get the base URL for API calls
  Future<String?> get _baseUrl async {
    final storage = await _storageService;
    return storage.getServerUrl();
  }

  Future<String?> get _token async {
    final storage = await _storageService;
    return storage.getToken();
  }

  /// Get list of programs available for catch-up on a channel
  Future<List<CatchUpProgram>> getCatchUpPrograms(int channelId) async {
    try {
      final baseUrl = await _baseUrl;
      final token = await _token;

      if (baseUrl == null || token == null) {
        debugPrint('CatchUpService: Not connected to server');
        return [];
      }

      final response = await _dio.get(
        '$baseUrl/livetv/channels/$channelId/catchup',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final programs = (data['programs'] as List<dynamic>?)
            ?.map((p) => CatchUpProgram.fromJson(p as Map<String, dynamic>))
            .toList();
        return programs ?? [];
      } else {
        debugPrint('CatchUpService: Failed to fetch programs: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('CatchUpService: Error fetching catch-up programs: $e');
      return [];
    }
  }

  /// Get start-over info for current program on a channel
  Future<StartOverInfo?> getStartOverInfo(int channelId) async {
    try {
      final baseUrl = await _baseUrl;
      final token = await _token;

      if (baseUrl == null || token == null) {
        debugPrint('CatchUpService: Not connected to server');
        return null;
      }

      final response = await _dio.get(
        '$baseUrl/livetv/channels/$channelId/startover',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return StartOverInfo.fromJson(data);
      } else {
        debugPrint('CatchUpService: Failed to fetch start-over info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('CatchUpService: Error fetching start-over info: $e');
      return null;
    }
  }

  /// Get time-shifted stream URL for a channel
  Future<String?> getTimeShiftUrl(int channelId, int offsetSeconds) async {
    try {
      final baseUrl = await _baseUrl;
      final token = await _token;

      if (baseUrl == null || token == null) {
        return null;
      }

      // The server returns a playlist URL
      return '$baseUrl/livetv/timeshift/$channelId/stream.m3u8?start=${offsetSeconds ~/ 6}&token=$token';
    } catch (e) {
      debugPrint('CatchUpService: Error getting time-shift URL: $e');
      return null;
    }
  }

  /// Check if a channel supports catch-up
  Future<bool> isChannelCatchUpEnabled(int channelId) async {
    // For now, assume all channels support catch-up if server is available
    // This could be enhanced to check channel-specific settings
    final baseUrl = await _baseUrl;
    return baseUrl != null;
  }
}
