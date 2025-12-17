import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Service for managing Picture-in-Picture mode
/// Desktop: Resizes window to small always-on-top floating window
/// Mobile: Platform-specific PiP implementations (future)
class PipService {
  static const String _keyPipPositionX = 'pip_position_x';
  static const String _keyPipPositionY = 'pip_position_y';
  static const String _keyPipWidth = 'pip_width';
  static const String _keyPipHeight = 'pip_height';

  // PiP window constraints
  static const double minWidth = 320;
  static const double minHeight = 180;
  static const double maxWidth = 640;
  static const double maxHeight = 360;
  static const double defaultWidth = 480;
  static const double defaultHeight = 270;

  bool _isPipMode = false;
  Size? _normalSize;
  Offset? _normalPosition;

  bool get isPipMode => _isPipMode;
  bool get isSupported => _isDesktop || kIsWeb;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// Enter Picture-in-Picture mode
  Future<bool> enterPip() async {
    if (!isSupported || _isPipMode) return false;

    try {
      if (_isDesktop) {
        return await _enterDesktopPip();
      }
      // Mobile PiP would be implemented here
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Exit Picture-in-Picture mode
  Future<bool> exitPip() async {
    if (!_isPipMode) return false;

    try {
      if (_isDesktop) {
        return await _exitDesktopPip();
      }
      // Mobile PiP would be implemented here
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Toggle Picture-in-Picture mode
  Future<bool> togglePip() async {
    return _isPipMode ? await exitPip() : await enterPip();
  }

  Future<bool> _enterDesktopPip() async {
    // Save current window state
    _normalSize = await windowManager.getSize();
    _normalPosition = await windowManager.getPosition();

    // Load saved PiP position and size
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble(_keyPipPositionX);
    final savedY = prefs.getDouble(_keyPipPositionY);
    final savedWidth = prefs.getDouble(_keyPipWidth) ?? defaultWidth;
    final savedHeight = prefs.getDouble(_keyPipHeight) ?? defaultHeight;

    // Set minimum size
    await windowManager.setMinimumSize(Size(minWidth, minHeight));
    await windowManager.setMaximumSize(Size(maxWidth, maxHeight));

    // Resize window
    await windowManager.setSize(Size(savedWidth, savedHeight));

    // Position window (or use saved position)
    if (savedX != null && savedY != null) {
      await windowManager.setPosition(Offset(savedX, savedY));
    } else {
      // Default: bottom-right corner with padding
      final screenSize = await windowManager.getSize();
      await windowManager.setPosition(
        Offset(
          screenSize.width - savedWidth - 20,
          screenSize.height - savedHeight - 20,
        ),
      );
    }

    // Make window always on top
    await windowManager.setAlwaysOnTop(true);

    // Enable title bar for dragging
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);

    _isPipMode = true;
    return true;
  }

  Future<bool> _exitDesktopPip() async {
    // Save current PiP position and size
    final currentSize = await windowManager.getSize();
    final currentPosition = await windowManager.getPosition();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPipPositionX, currentPosition.dx);
    await prefs.setDouble(_keyPipPositionY, currentPosition.dy);
    await prefs.setDouble(_keyPipWidth, currentSize.width);
    await prefs.setDouble(_keyPipHeight, currentSize.height);

    // Restore normal window state
    await windowManager.setAlwaysOnTop(false);

    // Remove size constraints
    await windowManager.setMinimumSize(Size(800, 600));
    await windowManager.setMaximumSize(Size.infinite);

    // Restore previous size and position
    if (_normalSize != null) {
      await windowManager.setSize(_normalSize!);
    }
    if (_normalPosition != null) {
      await windowManager.setPosition(_normalPosition!);
    }

    _isPipMode = false;
    _normalSize = null;
    _normalPosition = null;
    return true;
  }

  /// Save current PiP window position
  Future<void> savePipPosition() async {
    if (!_isPipMode || !_isDesktop) return;

    final position = await windowManager.getPosition();
    final size = await windowManager.getSize();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPipPositionX, position.dx);
    await prefs.setDouble(_keyPipPositionY, position.dy);
    await prefs.setDouble(_keyPipWidth, size.width);
    await prefs.setDouble(_keyPipHeight, size.height);
  }
}
