import 'package:flutter/material.dart';

import '../services/livetv_aspect_ratio_manager.dart';

/// Button to cycle through aspect ratio modes in Live TV
class LiveTVAspectRatioButton extends StatelessWidget {
  final AspectRatioMode currentMode;
  final VoidCallback onPressed;

  const LiveTVAspectRatioButton({
    super.key,
    required this.currentMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        _getIconForMode(currentMode),
        color: Colors.white70,
        size: 28,
      ),
      tooltip: 'Aspect Ratio: ${currentMode.displayName} (Z)',
    );
  }

  IconData _getIconForMode(AspectRatioMode mode) {
    switch (mode) {
      case AspectRatioMode.auto:
        return Icons.crop_original;
      case AspectRatioMode.fill:
        return Icons.crop_free;
      case AspectRatioMode.stretch:
        return Icons.aspect_ratio;
      case AspectRatioMode.ratio16x9:
        return Icons.crop_16_9;
      case AspectRatioMode.ratio4x3:
        return Icons.crop_5_4; // Closest to 4:3
    }
  }
}
