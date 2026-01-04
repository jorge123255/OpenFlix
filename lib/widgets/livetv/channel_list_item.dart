import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/livetv_channel.dart';

/// Compact channel list item for mini guide
class ChannelListItem extends StatelessWidget {
  final LiveTVChannel channel;
  final bool isCurrentChannel;
  final VoidCallback onTap;
  final Color? accentColor;

  const ChannelListItem({
    super.key,
    required this.channel,
    required this.isCurrentChannel,
    required this.onTap,
    this.accentColor,
  });

  Color get _channelColor => accentColor ?? const Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final now = channel.nowPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isCurrentChannel
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _channelColor.withValues(alpha: 0.25),
                        _channelColor.withValues(alpha: 0.1),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrentChannel
                    ? _channelColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.05),
                width: isCurrentChannel ? 1.5 : 1,
              ),
              boxShadow: isCurrentChannel
                  ? [
                      BoxShadow(
                        color: _channelColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Channel logo or number
                _buildChannelIndicator(),
                const SizedBox(width: 14),
                // Channel info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Channel number and name
                      Row(
                        children: [
                          // Channel number badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCurrentChannel
                                  ? _channelColor.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${channel.number ?? "#"}',
                              style: TextStyle(
                                color: isCurrentChannel
                                    ? _channelColor
                                    : Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              channel.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: isCurrentChannel
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Live indicator if current
                          if (isCurrentChannel)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                                  SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (now != null) ...[
                        const SizedBox(height: 8),
                        // Current program
                        Text(
                          now.title,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Time and progress
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatTime(now.start)} - ${_formatTime(now.end)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: now.progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _channelColor,
                                          _channelColor.withValues(alpha: 0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: isCurrentChannel
                                          ? [
                                              BoxShadow(
                                                color: _channelColor.withValues(alpha: 0.5),
                                                blurRadius: 6,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(now.progress * 100).toInt()}%',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'No program information',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelIndicator() {
    if (channel.logo != null && channel.logo!.isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            channel.logo!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildChannelNumber();
            },
          ),
        ),
      );
    }

    return _buildChannelNumber();
  }

  Widget _buildChannelNumber() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: isCurrentChannel
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _channelColor.withValues(alpha: 0.4),
                  _channelColor.withValues(alpha: 0.2),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentChannel
              ? _channelColor.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: isCurrentChannel
            ? [
                BoxShadow(
                  color: _channelColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          channel.number?.toString() ?? '#',
          style: TextStyle(
            color: isCurrentChannel
                ? _channelColor
                : Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time.toLocal());
  }
}
