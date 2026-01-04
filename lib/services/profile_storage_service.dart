import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local profile model
class LocalProfile {
  final String id;
  final String name;
  final int avatarId;
  final bool isKidsProfile;
  final bool autoplay;
  final DateTime createdAt;

  LocalProfile({
    required this.id,
    required this.name,
    required this.avatarId,
    this.isKidsProfile = false,
    this.autoplay = true,
    required this.createdAt,
  });

  factory LocalProfile.fromJson(Map<String, dynamic> json) {
    return LocalProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarId: json['avatarId'] as int? ?? 0,
      isKidsProfile: json['isKidsProfile'] as bool? ?? false,
      autoplay: json['autoplay'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarId': avatarId,
      'isKidsProfile': isKidsProfile,
      'autoplay': autoplay,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  LocalProfile copyWith({
    String? name,
    int? avatarId,
    bool? isKidsProfile,
    bool? autoplay,
  }) {
    return LocalProfile(
      id: id,
      name: name ?? this.name,
      avatarId: avatarId ?? this.avatarId,
      isKidsProfile: isKidsProfile ?? this.isKidsProfile,
      autoplay: autoplay ?? this.autoplay,
      createdAt: createdAt,
    );
  }
}

/// Service for managing local profiles
class ProfileStorageService {
  static const _profilesKey = 'local_profiles';
  static const _activeProfileKey = 'active_profile_id';
  static ProfileStorageService? _instance;

  final SharedPreferences _prefs;

  ProfileStorageService._(this._prefs);

  /// Get the singleton instance
  static Future<ProfileStorageService> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = ProfileStorageService._(prefs);
    }
    return _instance!;
  }

  /// Get all profiles
  List<LocalProfile> getProfiles() {
    final String? profilesJson = _prefs.getString(_profilesKey);
    if (profilesJson == null || profilesJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> profilesList = jsonDecode(profilesJson) as List;
      return profilesList
          .map((p) => LocalProfile.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Create a new profile
  Future<LocalProfile> createProfile({
    required String name,
    required int avatarId,
    bool isKidsProfile = false,
    bool autoplay = true,
  }) async {
    final profiles = getProfiles();

    final profile = LocalProfile(
      id: const Uuid().v4(),
      name: name,
      avatarId: avatarId,
      isKidsProfile: isKidsProfile,
      autoplay: autoplay,
      createdAt: DateTime.now(),
    );

    profiles.add(profile);
    await _saveProfiles(profiles);

    return profile;
  }

  /// Update an existing profile
  Future<LocalProfile?> updateProfile(
    String id, {
    String? name,
    int? avatarId,
    bool? isKidsProfile,
    bool? autoplay,
  }) async {
    final profiles = getProfiles();
    final index = profiles.indexWhere((p) => p.id == id);

    if (index == -1) return null;

    final updatedProfile = profiles[index].copyWith(
      name: name,
      avatarId: avatarId,
      isKidsProfile: isKidsProfile,
      autoplay: autoplay,
    );

    profiles[index] = updatedProfile;
    await _saveProfiles(profiles);

    return updatedProfile;
  }

  /// Delete a profile
  Future<bool> deleteProfile(String id) async {
    final profiles = getProfiles();
    final initialLength = profiles.length;
    profiles.removeWhere((p) => p.id == id);

    if (profiles.length < initialLength) {
      await _saveProfiles(profiles);

      // Clear active profile if it was deleted
      if (getActiveProfileId() == id) {
        await clearActiveProfile();
      }
      return true;
    }
    return false;
  }

  /// Get profile by ID
  LocalProfile? getProfile(String id) {
    final profiles = getProfiles();
    try {
      return profiles.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Set the active profile
  Future<void> setActiveProfile(String profileId) async {
    await _prefs.setString(_activeProfileKey, profileId);
  }

  /// Get the active profile ID
  String? getActiveProfileId() {
    return _prefs.getString(_activeProfileKey);
  }

  /// Get the active profile
  LocalProfile? getActiveProfile() {
    final activeId = getActiveProfileId();
    if (activeId == null) return null;
    return getProfile(activeId);
  }

  /// Clear the active profile
  Future<void> clearActiveProfile() async {
    await _prefs.remove(_activeProfileKey);
  }

  /// Check if any profiles exist
  bool hasProfiles() {
    return getProfiles().isNotEmpty;
  }

  /// Save profiles to storage
  Future<void> _saveProfiles(List<LocalProfile> profiles) async {
    final jsonList = profiles.map((p) => p.toJson()).toList();
    await _prefs.setString(_profilesKey, jsonEncode(jsonList));
  }

  /// Create default profiles if none exist
  Future<void> createDefaultProfilesIfNeeded() async {
    if (hasProfiles()) return;

    await createProfile(name: 'User', avatarId: 0);
  }
}
