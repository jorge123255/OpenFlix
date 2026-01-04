import 'package:flutter/material.dart';

import '../mpv/mpv.dart';
import '../models/media_item.dart';
import '../screens/video_player_screen.dart';
import '../services/settings_service.dart';

/// Navigates to the VideoPlayerScreen with instant transitions to prevent white flash.
///
/// This utility function provides a consistent way to navigate to the video player
/// across the app, using PageRouteBuilder with zero-duration transitions to eliminate
/// the white flash that occurs with MaterialPageRoute.
///
/// Parameters:
/// - [context]: The build context for navigation
/// - [metadata]: The media item for the content to play
/// - [preferredAudioTrack]: Optional audio track to select on playback start
/// - [preferredSubtitleTrack]: Optional subtitle track to select on playback start
/// - [preferredPlaybackRate]: Optional playback speed to set on playback start
/// - [selectedMediaIndex]: Optional media version index to use; if not provided,
///   loads the saved preference for the series/movie. Defaults to 0 if no preference exists.
/// - [usePushReplacement]: If true, replaces current route instead of pushing;
///   useful for episode-to-episode navigation. Defaults to false.
/// - [offlinePath]: Optional local file path for offline playback.
///
/// Returns a Future that completes with a boolean indicating whether the content
/// was watched, or null if navigation was cancelled.
Future<bool?> navigateToVideoPlayer(
  BuildContext context, {
  required MediaItem metadata,
  AudioTrack? preferredAudioTrack,
  SubtitleTrack? preferredSubtitleTrack,
  double? preferredPlaybackRate,
  int? selectedMediaIndex,
  bool usePushReplacement = false,
  String? offlinePath,
}) async {
  // Extract navigator before any async operations
  final navigator = Navigator.of(context);

  // Load saved media version preference if not explicitly provided
  int mediaIndex = selectedMediaIndex ?? 0;
  if (selectedMediaIndex == null) {
    try {
      final settingsService = await SettingsService.getInstance();
      final seriesKey = metadata.grandparentRatingKey ?? metadata.ratingKey;
      final savedPreference = settingsService.getMediaVersionPreference(
        seriesKey,
      );
      if (savedPreference != null) {
        mediaIndex = savedPreference;
      }
    } catch (e) {
      // Ignore errors loading preference, use default
    }
  }

  final route = PageRouteBuilder<bool>(
    pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
      metadata: metadata,
      preferredAudioTrack: preferredAudioTrack,
      preferredSubtitleTrack: preferredSubtitleTrack,
      preferredPlaybackRate: preferredPlaybackRate,
      selectedMediaIndex: mediaIndex,
      offlinePath: offlinePath,
    ),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  if (usePushReplacement) {
    return navigator.pushReplacement<bool, bool>(route);
  } else {
    return navigator.push<bool>(route);
  }
}
