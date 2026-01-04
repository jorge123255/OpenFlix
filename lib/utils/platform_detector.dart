import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for platform detection
class PlatformDetector {
  static const MethodChannel _channel = MethodChannel('com.openflix/platform');

  /// Cached TV detection result
  static bool? _isAndroidTV;

  /// Initialize TV detection - call this early in app startup
  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      try {
        _isAndroidTV = await _channel.invokeMethod<bool>('isAndroidTV') ?? false;
      } catch (e) {
        // If the method channel isn't implemented, fall back to heuristic
        _isAndroidTV = false;
      }
    } else {
      _isAndroidTV = false;
    }
  }

  /// Detects if running on a mobile platform (iOS or Android)
  /// Uses Theme for consistent platform detection across the app
  static bool isMobile(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  }

  /// Detects if running on a desktop platform (Windows, macOS, or Linux)
  static bool isDesktop(BuildContext context) {
    return !isMobile(context);
  }

  /// Detects if the device is likely a tablet based on screen size
  /// Uses diagonal screen size to determine if device is a tablet
  static bool isTablet(BuildContext context) {
    final data = MediaQuery.of(context);
    final size = data.size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    final devicePixelRatio = data.devicePixelRatio;

    // Convert diagonal from logical pixels to inches (assuming 160 DPI as baseline)
    final diagonalInches = diagonal / (devicePixelRatio * 160 / 2.54);

    // Consider devices with diagonal >= 7 inches as tablets
    return diagonalInches >= 7.0;
  }

  /// Detects if the device is a phone (mobile but not tablet)
  static bool isPhone(BuildContext context) {
    return isMobile(context) && !isTablet(context);
  }

  /// Detects if running on Android TV
  /// Must call initialize() first during app startup
  static bool isAndroidTV() {
    return _isAndroidTV ?? false;
  }

  /// Detects if the device is a TV-like experience
  /// This includes Android TV and large screen devices without touch
  /// Uses both native detection and screen-based heuristics
  static bool isTV(BuildContext context) {
    // Check native Android TV detection first
    if (_isAndroidTV == true) {
      return true;
    }

    // Fallback: large screen Android without touch capabilities
    // This helps catch TV boxes that might not report as Android TV
    if (Platform.isAndroid) {
      final data = MediaQuery.of(context);
      final size = data.size;
      final shortestSide = size.shortestSide;

      // Large screen (TV-like) and landscape orientation
      // TVs typically have shortest side >= 540dp and are always landscape
      if (shortestSide >= 540 && size.width > size.height) {
        // Additional heuristic: TVs tend to have lower pixel density
        if (data.devicePixelRatio <= 2.0) {
          return true;
        }
      }
    }

    return false;
  }

  /// Returns true if the app should use "10-foot UI" optimizations
  /// This includes TVs and desktop when controlled by keyboard/remote
  static bool shouldUseLargeFocusIndicators(BuildContext context) {
    return isTV(context) || isDesktop(context);
  }
}
