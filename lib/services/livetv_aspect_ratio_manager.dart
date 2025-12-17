import '../mpv/mpv.dart';
import '../utils/app_logger.dart';

/// Aspect ratio modes for Live TV playback
enum AspectRatioMode {
  auto, // Default - maintain aspect ratio with letterboxing
  fill, // Fill screen - crop to fill
  stretch, // Stretch to fill (distort)
  ratio16x9, // Force 16:9
  ratio4x3, // Force 4:3
}

/// Extension to get display names for aspect ratio modes
extension AspectRatioModeExtension on AspectRatioMode {
  String get displayName {
    switch (this) {
      case AspectRatioMode.auto:
        return 'Auto';
      case AspectRatioMode.fill:
        return 'Fill Screen';
      case AspectRatioMode.stretch:
        return 'Stretch';
      case AspectRatioMode.ratio16x9:
        return '16:9';
      case AspectRatioMode.ratio4x3:
        return '4:3';
    }
  }

  String get shortName {
    switch (this) {
      case AspectRatioMode.auto:
        return 'Auto';
      case AspectRatioMode.fill:
        return 'Fill';
      case AspectRatioMode.stretch:
        return 'Stretch';
      case AspectRatioMode.ratio16x9:
        return '16:9';
      case AspectRatioMode.ratio4x3:
        return '4:3';
    }
  }
}

/// Manages aspect ratio modes for Live TV playback
class LiveTVAspectRatioManager {
  final Player player;
  AspectRatioMode _currentMode = AspectRatioMode.auto;

  LiveTVAspectRatioManager(this.player);

  /// Get the current aspect ratio mode
  AspectRatioMode get currentMode => _currentMode;

  /// Set the aspect ratio mode
  Future<void> setMode(AspectRatioMode mode) async {
    _currentMode = mode;
    await _applyMode(mode);
    appLogger.d('Aspect ratio mode set to: ${mode.displayName}');
  }

  /// Cycle to the next aspect ratio mode
  Future<AspectRatioMode> cycleMode() async {
    final currentIndex = AspectRatioMode.values.indexOf(_currentMode);
    final nextIndex = (currentIndex + 1) % AspectRatioMode.values.length;
    final nextMode = AspectRatioMode.values[nextIndex];
    await setMode(nextMode);
    return nextMode;
  }

  /// Apply the aspect ratio mode to the player
  Future<void> _applyMode(AspectRatioMode mode) async {
    try {
      switch (mode) {
        case AspectRatioMode.auto:
          // Reset to default behavior
          await player.setProperty('video-aspect-override', '-1');
          await player.setProperty('video-unscaled', 'no');
          await player.setProperty('panscan', '0.0');
          break;

        case AspectRatioMode.fill:
          // Fill screen by using panscan (zoom to fill)
          await player.setProperty('video-aspect-override', '-1');
          await player.setProperty('video-unscaled', 'no');
          await player.setProperty('panscan', '1.0');
          break;

        case AspectRatioMode.stretch:
          // Stretch to fill (may distort)
          await player.setProperty('video-aspect-override', '-1');
          await player.setProperty('video-unscaled', 'yes');
          await player.setProperty('panscan', '0.0');
          break;

        case AspectRatioMode.ratio16x9:
          // Force 16:9 aspect ratio
          await player.setProperty('video-aspect-override', '16:9');
          await player.setProperty('video-unscaled', 'no');
          await player.setProperty('panscan', '0.0');
          break;

        case AspectRatioMode.ratio4x3:
          // Force 4:3 aspect ratio
          await player.setProperty('video-aspect-override', '4:3');
          await player.setProperty('video-unscaled', 'no');
          await player.setProperty('panscan', '0.0');
          break;
      }
    } catch (e) {
      appLogger.e('Failed to apply aspect ratio mode', error: e);
    }
  }

  /// Reset to auto mode
  Future<void> reset() async {
    await setMode(AspectRatioMode.auto);
  }
}
