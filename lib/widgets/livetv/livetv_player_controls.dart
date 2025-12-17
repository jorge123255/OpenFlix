import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/livetv_channel.dart';
import '../../services/livetv_aspect_ratio_manager.dart';
import '../../services/pip_service.dart';
import '../../services/sleep_timer_service.dart';
import '../livetv_aspect_ratio_button.dart';
import 'quick_record_button.dart';

/// Unified overlay controls for Live TV player
/// Displays channel info, current/next program, and control buttons
class LiveTVPlayerControls extends StatelessWidget {
  final LiveTVChannel channel;
  final SleepTimerService sleepTimer;
  final bool isRecordingScheduled;
  final bool isSchedulingRecording;
  final AspectRatioMode currentAspectMode;
  final PipService pipService;
  final bool isPipMode;

  // Callbacks
  final VoidCallback onShowProgramDetails;
  final VoidCallback onQuickRecord;
  final VoidCallback onShowAudioTrackSheet;
  final VoidCallback onShowSubtitleTrackSheet;
  final VoidCallback onCycleAspectRatio;
  final VoidCallback onSwitchToPreviousChannel;
  final VoidCallback onToggleHistoryPanel;
  final VoidCallback onShowSleepTimer;
  final VoidCallback onTogglePip;

  const LiveTVPlayerControls({
    super.key,
    required this.channel,
    required this.sleepTimer,
    required this.isRecordingScheduled,
    required this.isSchedulingRecording,
    required this.currentAspectMode,
    required this.pipService,
    required this.isPipMode,
    required this.onShowProgramDetails,
    required this.onQuickRecord,
    required this.onShowAudioTrackSheet,
    required this.onShowSubtitleTrackSheet,
    required this.onCycleAspectRatio,
    required this.onSwitchToPreviousChannel,
    required this.onToggleHistoryPanel,
    required this.onShowSleepTimer,
    required this.onTogglePip,
  });

  @override
  Widget build(BuildContext context) {
    final now = channel.nowPlaying;
    final next = channel.nextProgram;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(230),
              Colors.black.withAlpha(150),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel info row
              Row(
                children: [
                  // Channel logo/number
                  if (channel.logo != null && channel.logo!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        channel.logo!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildChannelNumber();
                        },
                      ),
                    )
                  else
                    _buildChannelNumber(),
                  const SizedBox(width: 16),
                  // Channel name and program info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (channel.number != null)
                              Text(
                                '${channel.number}  ',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                channel.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (now != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            now.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_formatTime(now.start)} - ${_formatTime(now.end)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: now.progress,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                        if (next != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Next: ${next.title} (${_formatTime(next.start)})',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Control buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Program info button
                  IconButton(
                    onPressed: onShowProgramDetails,
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 28,
                    ),
                    tooltip: 'Program Details (I)',
                  ),
                  const SizedBox(width: 8),
                  // Quick record button
                  QuickRecordButton(
                    isScheduled: isRecordingScheduled,
                    isLoading: isSchedulingRecording,
                    onPressed: onQuickRecord,
                  ),
                  const SizedBox(width: 8),
                  // Audio track button
                  IconButton(
                    onPressed: onShowAudioTrackSheet,
                    icon: const Icon(
                      Icons.audiotrack,
                      color: Colors.white70,
                      size: 28,
                    ),
                    tooltip: 'Audio Tracks (A)',
                  ),
                  const SizedBox(width: 8),
                  // Subtitle button
                  IconButton(
                    onPressed: onShowSubtitleTrackSheet,
                    icon: const Icon(
                      Icons.subtitles,
                      color: Colors.white70,
                      size: 28,
                    ),
                    tooltip: 'Subtitles (S)',
                  ),
                  const SizedBox(width: 8),
                  // Aspect ratio button
                  LiveTVAspectRatioButton(
                    currentMode: currentAspectMode,
                    onPressed: onCycleAspectRatio,
                  ),
                  const SizedBox(width: 8),
                  // Previous channel button
                  IconButton(
                    onPressed: onSwitchToPreviousChannel,
                    icon: const Icon(
                      Icons.skip_previous,
                      color: Colors.white70,
                      size: 28,
                    ),
                    tooltip: 'Previous Channel (Backspace)',
                  ),
                  const SizedBox(width: 8),
                  // Channel history button
                  IconButton(
                    onPressed: onToggleHistoryPanel,
                    icon: const Icon(
                      Icons.history,
                      color: Colors.white70,
                      size: 28,
                    ),
                    tooltip: 'Channel History (H)',
                  ),
                  const SizedBox(width: 8),
                  // Sleep timer button
                  ListenableBuilder(
                    listenable: sleepTimer,
                    builder: (context, _) {
                      final isActive = sleepTimer.isActive;
                      final remaining = sleepTimer.remainingTime;
                      return IconButton(
                        onPressed: onShowSleepTimer,
                        icon: Icon(
                          isActive ? Icons.bedtime : Icons.bedtime_outlined,
                          color: isActive ? Colors.blue : Colors.white70,
                          size: 28,
                        ),
                        tooltip: isActive && remaining != null
                            ? 'Sleep Timer: ${remaining.inMinutes}m remaining'
                            : 'Sleep Timer (T)',
                      );
                    },
                  ),
                  // Picture-in-Picture button (desktop only)
                  if (pipService.isSupported) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onTogglePip,
                      icon: Icon(
                        isPipMode
                            ? Icons.picture_in_picture_alt
                            : Icons.picture_in_picture_alt_outlined,
                        color: isPipMode ? Colors.green : Colors.white70,
                        size: 28,
                      ),
                      tooltip: isPipMode
                          ? 'Exit Picture-in-Picture (P)'
                          : 'Picture-in-Picture (P)',
                    ),
                  ],
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 8),
              // Navigation hints
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHintButton(Icons.keyboard_arrow_up, 'Channel Up'),
                  const SizedBox(width: 24),
                  _buildHintButton(Icons.keyboard_arrow_down, 'Channel Down'),
                  const SizedBox(width: 24),
                  _buildHintButton(Icons.dialpad, 'Enter Number'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelNumber() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          channel.number?.toString() ?? '#',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildHintButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time.toLocal());
  }
}
