import 'dart:async';
import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

/// Response from login/register endpoints
class AuthResponse {
  final String token;
  final UserInfo user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['authToken'] as String,
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Profile information for profile selection (Disney+ style)
class ProfileInfo {
  final int id;
  final String uuid;
  final String name;
  final String? avatarUrl;
  final int avatarIndex; // Index for default character avatars
  final bool isKidsProfile;
  final bool isAdmin;

  ProfileInfo({
    required this.id,
    required this.uuid,
    required this.name,
    this.avatarUrl,
    this.avatarIndex = 0,
    this.isKidsProfile = false,
    this.isAdmin = false,
  });

  factory ProfileInfo.fromJson(Map<String, dynamic> json) {
    return ProfileInfo(
      id: json['id'] as int,
      uuid: json['uuid'] as String? ?? '',
      name: json['title'] as String? ?? json['name'] as String? ?? json['username'] as String? ?? 'User',
      avatarUrl: json['thumb'] as String?,
      avatarIndex: json['avatarIndex'] as int? ?? 0,
      isKidsProfile: json['kidsProfile'] as bool? ?? false,
      isAdmin: json['admin'] as bool? ?? false,
    );
  }
}

/// User information returned from auth endpoints
class UserInfo {
  final int id;
  final String uuid;
  final String username;
  final String email;
  final String displayName;
  final String? thumb;
  final bool isAdmin;

  UserInfo({
    required this.id,
    required this.uuid,
    required this.username,
    required this.email,
    required this.displayName,
    this.thumb,
    required this.isAdmin,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['title'] as String? ?? json['username'] as String,
      thumb: json['thumb'] as String?,
      isAdmin: json['admin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'username': username,
      'email': email,
      'title': displayName,
      'thumb': thumb,
      'admin': isAdmin,
    };
  }
}

/// Service for OpenFlix authentication
class OpenFlixAuthService {
  final Dio _dio;
  final String _serverUrl;

  OpenFlixAuthService._(this._dio, this._serverUrl);

  /// Create a new OpenFlixAuthService for a given server URL
  static OpenFlixAuthService create(String serverUrl) {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    // Ensure server URL doesn't have trailing slash
    final normalizedUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return OpenFlixAuthService._(dio, normalizedUrl);
  }

  String get serverUrl => _serverUrl;

  /// Test if the server is reachable and is an OpenFlix server
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('$_serverUrl/identity');
      // Check if it's an OpenFlix server (has MediaContainer with machineIdentifier)
      final data = response.data;
      if (data is Map && data['MediaContainer'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      appLogger.w('Server connection test failed', error: e);
      return false;
    }
  }

  /// Login with username and password
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '$_serverUrl/auth/login',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException('Invalid username or password');
      }
      throw AuthException('Login failed: ${e.message}');
    } catch (e) {
      throw AuthException('Login failed: $e');
    }
  }

  /// Register a new user
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _dio.post(
        '$_serverUrl/auth/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          if (displayName != null) 'displayName': displayName,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw AuthException('Username or email already exists');
      }
      throw AuthException('Registration failed: ${e.message}');
    } catch (e) {
      throw AuthException('Registration failed: $e');
    }
  }

  /// Get list of profiles for local network access (no auth required)
  /// Returns null if the server doesn't support local profile access
  Future<List<ProfileInfo>?> getLocalProfiles() async {
    try {
      final response = await _dio.get(
        '$_serverUrl/auth/profiles',
        options: Options(
          headers: {'Accept': 'application/json'},
        ),
      );

      final data = response.data;
      if (data is Map && data['profiles'] != null) {
        final profiles = (data['profiles'] as List)
            .map((p) => ProfileInfo.fromJson(p as Map<String, dynamic>))
            .toList();
        return profiles;
      }
      return null;
    } catch (e) {
      appLogger.w('Failed to get local profiles', error: e);
      return null;
    }
  }

  /// Login as a profile for local network access (no password required)
  /// Returns null if the server doesn't support local profile login
  Future<AuthResponse?> loginAsProfile(int profileId) async {
    try {
      final response = await _dio.post(
        '$_serverUrl/auth/profile-login',
        data: {'profileId': profileId},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      appLogger.w('Profile login failed', error: e);
      return null;
    }
  }

  /// Verify if a token is valid
  Future<bool> verifyToken(String token) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/users/account',
        options: Options(
          headers: {
            'X-Plex-Token': token,
            'Accept': 'application/json',
          },
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get current user info
  Future<UserInfo> getCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '$_serverUrl/users/account',
        options: Options(
          headers: {
            'X-Plex-Token': token,
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['MediaContainer'] != null) {
        final container = data['MediaContainer'] as Map<String, dynamic>;
        return UserInfo(
          id: container['id'] as int? ?? 0,
          uuid: container['uuid'] as String? ?? '',
          username: container['username'] as String? ?? '',
          email: container['email'] as String? ?? '',
          displayName: container['title'] as String? ?? container['username'] as String? ?? '',
          thumb: container['thumb'] as String?,
          isAdmin: container['admin'] as bool? ?? false,
        );
      }
      throw AuthException('Invalid response format');
    } catch (e) {
      throw AuthException('Failed to get user info: $e');
    }
  }
}

/// Server settings response
class ServerSettings {
  final String? tmdbApiKey;
  final String? tvdbApiKey;
  final String? metadataLang;
  final int? scanInterval;

  ServerSettings({
    this.tmdbApiKey,
    this.tvdbApiKey,
    this.metadataLang,
    this.scanInterval,
  });

  factory ServerSettings.fromJson(Map<String, dynamic> json) {
    return ServerSettings(
      tmdbApiKey: json['tmdb_api_key'] as String?,
      tvdbApiKey: json['tvdb_api_key'] as String?,
      metadataLang: json['metadata_lang'] as String?,
      scanInterval: json['scan_interval'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tmdbApiKey != null) 'tmdb_api_key': tmdbApiKey,
      if (tvdbApiKey != null) 'tvdb_api_key': tvdbApiKey,
      if (metadataLang != null) 'metadata_lang': metadataLang,
      if (scanInterval != null) 'scan_interval': scanInterval,
    };
  }
}

/// Service for OpenFlix admin operations
class OpenFlixAdminService {
  final Dio _dio;
  final String _serverUrl;
  final String _token;

  OpenFlixAdminService._(this._dio, this._serverUrl, this._token);

  /// Create a new OpenFlixAdminService for a given server URL and auth token
  static OpenFlixAdminService create(String serverUrl, String token) {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    // Ensure server URL doesn't have trailing slash
    final normalizedUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    return OpenFlixAdminService._(dio, normalizedUrl, token);
  }

  /// Get current server settings
  Future<ServerSettings> getSettings() async {
    try {
      final response = await _dio.get(
        '$_serverUrl/admin/settings',
        options: Options(
          headers: {
            'X-Plex-Token': _token,
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return ServerSettings.fromJson(
        data['settings'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw AdminException('Failed to get settings: $e');
    }
  }

  /// Update server settings
  Future<ServerSettings> updateSettings(ServerSettings settings) async {
    try {
      final response = await _dio.put(
        '$_serverUrl/admin/settings',
        data: settings.toJson(),
        options: Options(
          headers: {
            'X-Plex-Token': _token,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return ServerSettings.fromJson(
        data['settings'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw AdminException('Admin access required');
      }
      throw AdminException('Failed to update settings: ${e.message}');
    } catch (e) {
      throw AdminException('Failed to update settings: $e');
    }
  }
}

/// Exception for admin operation errors
class AdminException implements Exception {
  final String message;

  AdminException(this.message);

  @override
  String toString() => message;
}

/// Exception for authentication errors
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
