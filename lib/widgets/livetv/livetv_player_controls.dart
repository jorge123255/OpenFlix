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
  final List<LiveTVChannel> allChannels;
  final SleepTimerService sleepTimer;
  final bool isRecordingScheduled;
  final bool isSchedulingRecording;
  final AspectRatioMode currentAspectMode;
  final PipService pipService;
  final bool isPipMode;

  // Vibrant accent colors for channel cards
  static const _accentColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFFEF4444), // Red
    Color(0xFFFBBF24), // Amber
    Color(0xFF06B6D4), // Cyan
  ];

  Color _getChannelColor(String name) {
    return _accentColors[name.hashCode.abs() % _accentColors.length];
  }

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
  final VoidCallback onToggleFavorite;
  final VoidCallback onShowEPG;
  final VoidCallback? onStartOver;
  final VoidCallback? onShowCatchUp;
  final void Function(LiveTVChannel) onSwitchToChannel;
  final bool isTogglingFavorite;
  final bool showChannelStrip;
  final bool startOverAvailable;
  final bool catchUpAvailable;

  const LiveTVPlayerControls({
    super.key,
    required this.channel,
    required this.allChannels,
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
    required this.onToggleFavorite,
    required this.onShowEPG,
    required this.onSwitchToChannel,
    this.onStartOver,
    this.onShowCatchUp,
    this.isTogglingFavorite = false,
    this.showChannelStrip = true,
    this.startOverAvailable = false,
    this.catchUpAvailable = false,
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
                  // Start Over button (catch-up)
                  if (startOverAvailable && onStartOver != null) ...[
                    IconButton(
                      onPressed: onStartOver,
                      icon: const Icon(
                        Icons.restart_alt,
                        color: Colors.blue,
                        size: 28,
                      ),
                      tooltip: 'Start Over',
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Catch-up TV button
                  if (catchUpAvailable && onShowCatchUp != null) ...[
                    IconButton(
                      onPressed: onShowCatchUp,
                      icon: const Icon(
                        Icons.history,
                        color: Colors.blue,
                        size: 28,
                      ),
                      tooltip: 'Catch-up TV',
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Quick record button
                  QuickRecordButton(
                    isScheduled: isRecordingScheduled,
                    isLoading: isSchedulingRecording,
                    onPressed: onQuickRecord,
                  ),
                  const SizedBox(width: 8),
                  // Favorite button
                  IconButton(
                    onPressed: isTogglingFavorite ? null : onToggleFavorite,
                    icon: isTogglingFavorite
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          )
                        : Icon(
                            channel.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: channel.isFavorite
                                ? Colors.red
                                : Colors.white70,
                            size: 28,
                          ),
                    tooltip: channel.isFavorite
                        ? 'Remove from Favorites (F)'
                        : 'Add to Favorites (F)',
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
              // Channel strip (TiviMate style)
              if (showChannelStrip && allChannels.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildChannelStrip(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelStrip() {
    // Find current channel index
    final currentIndex = allChannels.indexWhere((c) => c.id == channel.id);

    return SizedBox(
      height: 100,
      child: Row(
        children: [
          // TV Guide button
          _buildQuickAccessButton(
            icon: Icons.grid_view_rounded,
            label: 'TV Guide',
            onTap: onShowEPG,
            accentColor: const Color(0xFF8B5CF6), // Violet
          ),
          const SizedBox(width: 8),
          // History button
          _buildQuickAccessButton(
            icon: Icons.history_rounded,
            label: 'History',
            onTap: onToggleHistoryPanel,
            accentColor: const Color(0xFF10B981), // Emerald
          ),
          const SizedBox(width: 8),
          // Catchup button
          if (catchUpAvailable && onShowCatchUp != null)
            _buildQuickAccessButton(
              icon: Icons.replay_rounded,
              label: 'Catchup',
              onTap: onShowCatchUp!,
              accentColor: const Color(0xFF3B82F6), // Blue
            ),
          const SizedBox(width: 12),
          // Separator
          Container(
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 12),
          // Channel cards
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allChannels.length,
              controller: ScrollController(
                initialScrollOffset: currentIndex > 0
                    ? (currentIndex - 1) * 160.0
                    : 0,
              ),
              itemBuilder: (context, index) {
                final ch = allChannels[index];
                final isCurrent = ch.id == channel.id;
                return _buildChannelCard(ch, isCurrent);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final color = accentColor ?? const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(LiveTVChannel ch, bool isCurrent) {
    final program = ch.nowPlaying;
    final accentColor = _getChannelColor(ch.name);

    return GestureDetector(
      onTap: isCurrent ? null : () => onSwitchToChannel(ch),
      child: Container(
        width: 150,
        height: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCurrent
                ? [accentColor, accentColor.withValues(alpha: 0.7)]
                : [
                    accentColor.withValues(alpha: 0.2),
                    accentColor.withValues(alpha: 0.08),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.8)
                : accentColor.withValues(alpha: 0.4),
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Current channel play indicator
            if (isCurrent)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel number and name row
                  Row(
                    children: [
                      // Channel number badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Colors.white.withValues(alpha: 0.25)
                              : accentColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${ch.number ?? "#"}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Channel name
                      Expanded(
                        child: Text(
                          ch.name,
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Current program
                  if (program != null) ...[
                    Text(
                      program.title,
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: program.progress,
                        backgroundColor: isCurrent
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCurrent ? Colors.white : accentColor,
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'No program info',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
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

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time.toLocal());
  }
}
