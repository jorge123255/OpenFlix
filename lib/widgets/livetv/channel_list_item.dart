import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/livetv_channel.dart';

/// Compact channel list item for mini guide
class ChannelListItem extends StatelessWidget {
  final LiveTVChannel channel;
  final bool isCurrentChannel;
  final VoidCallback onTap;

  const ChannelListItem({
    super.key,
    required this.channel,
    required this.isCurrentChannel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = channel.nowPlaying;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isCurrentChannel
              ? theme.colorScheme.primary.withOpacity(0.2)
              : null,
          border: Border(
            left: BorderSide(
              color: isCurrentChannel
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 4,
            ),
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Channel logo or number
            _buildChannelIndicator(theme),
            const SizedBox(width: 12),
            // Channel info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel number and name
                  Row(
                    children: [
                      if (channel.number != null) ...[
                        Text(
                          '${channel.number}',
                          style: TextStyle(
                            color: isCurrentChannel
                                ? theme.colorScheme.primary
                                : Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          channel.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: isCurrentChannel
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (now != null) ...[
                    const SizedBox(height: 6),
                    // Current program
                    Text(
                      now.title,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Time and progress
                    Row(
                      children: [
                        Text(
                          '${_formatTime(now.start)} - ${_formatTime(now.end)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: now.progress,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCurrentChannel
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                              ),
                              minHeight: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      'No program information',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelIndicator(ThemeData theme) {
    if (channel.logo != null && channel.logo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Image.network(
            channel.logo!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildChannelNumber(theme);
            },
          ),
        ),
      );
    }

    return _buildChannelNumber(theme);
  }

  Widget _buildChannelNumber(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isCurrentChannel
            ? theme.colorScheme.primary.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          channel.number?.toString() ?? '#',
          style: TextStyle(
            color: isCurrentChannel
                ? theme.colorScheme.primary
                : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time.toLocal());
  }
}
