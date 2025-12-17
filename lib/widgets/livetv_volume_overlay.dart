import 'package:flutter/material.dart';

/// Volume overlay for Live TV player
/// Shows volume level with auto-hide after inactivity
class LiveTVVolumeOverlay extends StatelessWidget {
  final double volume; // 0.0 to 100.0
  final bool isMuted;

  const LiveTVVolumeOverlay({
    super.key,
    required this.volume,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayVolume = isMuted ? 0.0 : volume;
    final volumePercent = displayVolume.round();

    return Center(
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Volume icon and percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getVolumeIcon(displayVolume),
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  '$volumePercent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Vertical volume bar
            SizedBox(
              height: 200,
              width: 40,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Background bar
                  Container(
                    width: 8,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Filled bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 8,
                    height: (displayVolume / 100) * 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          _getVolumeColor(displayVolume),
                          _getVolumeColor(displayVolume).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Volume markers
                  ...List.generate(5, (index) {
                    final markerPosition = (index / 4) * 200;
                    return Positioned(
                      bottom: markerPosition,
                      right: 12,
                      child: Container(
                        width: 12,
                        height: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    );
                  }),
                ],
              ),
            ),
            if (isMuted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'MUTED',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getVolumeIcon(double volume) {
    if (volume == 0 || isMuted) {
      return Icons.volume_mute;
    } else if (volume < 30) {
      return Icons.volume_down;
    } else {
      return Icons.volume_up;
    }
  }

  Color _getVolumeColor(double volume) {
    if (volume == 0 || isMuted) {
      return Colors.grey;
    } else if (volume < 30) {
      return Colors.blue;
    } else if (volume < 70) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }
}
