import 'package:flutter/material.dart';
import '../client/media_client.dart';
import '../models/library.dart';
import '../utils/provider_extensions.dart';

/// Mixin providing common functionality for library tab screens
/// Provides server-specific client resolution for multi-server support
mixin LibraryTabStateMixin<T extends StatefulWidget> on State<T> {
  /// The library being displayed
  Library get library;

  /// Get the correct MediaClient for this library's server
  /// Throws an exception if no client is available
  MediaClient getClientForLibrary() => context.getClientForLibrary(library);
}
