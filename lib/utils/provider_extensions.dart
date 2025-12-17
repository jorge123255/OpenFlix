import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/media_client.dart';
import '../i18n/strings.g.dart';
import '../models/library.dart';
import '../models/user_profile.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/media_client_provider.dart';
import '../providers/user_profile_provider.dart';
import 'app_logger.dart';

extension ProviderExtensions on BuildContext {
  MediaClientProvider get plexClient =>
      Provider.of<MediaClientProvider>(this, listen: false);

  UserProfileProvider get userProfile =>
      Provider.of<UserProfileProvider>(this, listen: false);

  MediaClientProvider watchMediaClient() =>
      Provider.of<MediaClientProvider>(this, listen: true);

  UserProfileProvider watchUserProfile() =>
      Provider.of<UserProfileProvider>(this, listen: true);

  HiddenLibrariesProvider get hiddenLibraries =>
      Provider.of<HiddenLibrariesProvider>(this, listen: false);

  HiddenLibrariesProvider watchHiddenLibraries() =>
      Provider.of<HiddenLibrariesProvider>(this, listen: true);

  // Direct profile settings access (nullable)
  UserProfile? get profileSettings => userProfile.profileSettings;

  /// Get MediaClient for a specific server ID
  /// Throws an exception if no client is available for the given serverId
  MediaClient getClientForServer(String serverId) {
    final multiServerProvider = Provider.of<MultiServerProvider>(
      this,
      listen: false,
    );

    final serverClient = multiServerProvider.getClientForServer(serverId);

    if (serverClient == null) {
      appLogger.e('No client found for server $serverId');
      throw Exception(t.errors.noClientAvailable);
    }

    return serverClient;
  }

  /// Get MediaClient for a library
  /// Throws an exception if no client is available
  MediaClient getClientForLibrary(Library library) {
    // If library doesn't have a serverId, fall back to first available server
    if (library.serverId == null) {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        this,
        listen: false,
      );
      if (!multiServerProvider.hasConnectedServers) {
        throw Exception(t.errors.noClientAvailable);
      }
      return getClientForServer(multiServerProvider.onlineServerIds.first);
    }
    return getClientForServer(library.serverId!);
  }
}
