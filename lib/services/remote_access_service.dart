import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';

/// Service for managing remote access through Tailscale
class RemoteAccessService {
  final String baseUrl;
  final String token;

  RemoteAccessService({
    required this.baseUrl,
    required this.token,
  });

  /// Get the current remote access status
  Future<RemoteAccessStatus?> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/system/remote-access/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return RemoteAccessStatus.fromJson(json.decode(response.body));
      }
    } catch (e) {
      appLogger.e('Failed to get remote access status', error: e);
    }
    return null;
  }

  /// Enable remote access
  Future<RemoteAccessStatus?> enable({String? authKey}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/system/remote-access/enable'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          if (authKey != null) 'authKey': authKey,
        }),
      );

      if (response.statusCode == 200) {
        return RemoteAccessStatus.fromJson(json.decode(response.body));
      }
    } catch (e) {
      appLogger.e('Failed to enable remote access', error: e);
    }
    return null;
  }

  /// Disable remote access
  Future<RemoteAccessStatus?> disable() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/system/remote-access/disable'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return RemoteAccessStatus.fromJson(json.decode(response.body));
      }
    } catch (e) {
      appLogger.e('Failed to disable remote access', error: e);
    }
    return null;
  }

  /// Get connection info for the current client
  Future<ConnectionInfo?> getConnectionInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/system/remote-access/connection'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return ConnectionInfo.fromJson(json.decode(response.body));
      }
    } catch (e) {
      appLogger.e('Failed to get connection info', error: e);
    }
    return null;
  }

  /// Get health check information
  Future<Map<String, dynamic>?> getHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/system/remote-access/health'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      appLogger.e('Failed to get remote access health', error: e);
    }
    return null;
  }

  /// Get installation instructions for Tailscale
  Future<Map<String, String>?> getInstallInstructions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/system/remote-access/install'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return Map<String, String>.from(json.decode(response.body));
      }
    } catch (e) {
      appLogger.e('Failed to get install instructions', error: e);
    }
    return null;
  }

  /// Test if a URL is reachable
  Future<bool> testConnection(String url) async {
    try {
      final response = await http.get(
        Uri.parse('$url/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Remote access status
class RemoteAccessStatus {
  final bool enabled;
  final String status; // connected, disconnected, connecting, error, not_installed, needs_login
  final String? tailscaleIp;
  final String? tailscaleUrl;
  final String? hostname;
  final String? localIp;
  final String? externalUrl;
  final String? error;
  final DateTime lastChecked;

  RemoteAccessStatus({
    required this.enabled,
    required this.status,
    this.tailscaleIp,
    this.tailscaleUrl,
    this.hostname,
    this.localIp,
    this.externalUrl,
    this.error,
    required this.lastChecked,
  });

  factory RemoteAccessStatus.fromJson(Map<String, dynamic> json) {
    return RemoteAccessStatus(
      enabled: json['enabled'] ?? false,
      status: json['status'] ?? 'unknown',
      tailscaleIp: json['tailscaleIp'],
      tailscaleUrl: json['tailscaleUrl'],
      hostname: json['hostname'],
      localIp: json['localIp'],
      externalUrl: json['externalUrl'],
      error: json['error'],
      lastChecked: DateTime.tryParse(json['lastChecked'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isConnected => status == 'connected';
  bool get isInstalled => status != 'not_installed';
  bool get needsLogin => status == 'needs_login';

  String get statusText {
    switch (status) {
      case 'connected':
        return 'Connected';
      case 'disconnected':
        return 'Disconnected';
      case 'connecting':
        return 'Connecting...';
      case 'not_installed':
        return 'Tailscale Not Installed';
      case 'needs_login':
        return 'Login Required';
      case 'error':
        return 'Error';
      default:
        return status;
    }
  }

  String get bestUrl => tailscaleUrl ?? externalUrl ?? localIp ?? '';
}

/// Connection info for the client
class ConnectionInfo {
  final List<String> localUrls;
  final String? tailscaleUrl;
  final String recommendedUrl;
  final bool isRemote;

  ConnectionInfo({
    required this.localUrls,
    this.tailscaleUrl,
    required this.recommendedUrl,
    required this.isRemote,
  });

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) {
    return ConnectionInfo(
      localUrls: List<String>.from(json['localUrls'] ?? []),
      tailscaleUrl: json['tailscaleUrl'],
      recommendedUrl: json['recommendedUrl'] ?? '',
      isRemote: json['isRemote'] ?? false,
    );
  }
}
