import 'package:flutter/material.dart';

import '../models/livetv_channel.dart';
import '../services/channel_history_service.dart';

/// Format a duration as "time ago" string
String _formatTimeAgo(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inSeconds < 60) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return '$minutes min${minutes > 1 ? 's' : ''} ago';
  } else if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '$hours hr${hours > 1 ? 's' : ''} ago';
  } else if (difference.inDays < 7) {
    final days = difference.inDays;
    return '$days day${days > 1 ? 's' : ''} ago';
  } else {
    final weeks = difference.inDays ~/ 7;
    return '$weeks week${weeks > 1 ? 's' : ''} ago';
  }
}

/// Panel showing recent channel history
/// Allows quick switching to recently watched channels
class ChannelHistoryPanel extends StatelessWidget {
  final List<LiveTVChannel> channels;
  final ChannelHistoryService channelHistory;
  final Function(LiveTVChannel) onChannelSelected;
  final VoidCallback onClose;

  const ChannelHistoryPanel({
    super.key,
    required this.channels,
    required this.channelHistory,
    required this.onChannelSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final history = channelHistory.getHistory();
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping the panel
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              offset: Offset.zero,
              curve: Curves.easeOut,
              child: Container(
                width: size.width > 600 ? 400 : size.width * 0.8,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Channel History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),
                      // History list
                      Expanded(
                        child: history.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: history.length,
                                itemBuilder: (context, index) {
                                  final entry = history[index];
                                  final channel = channels.firstWhere(
                                    (c) => c.id == entry.channelId,
                                    orElse: () => LiveTVChannel(
                                      id: entry.channelId,
                                      channelId: 'unknown',
                                      name: 'Unknown Channel',
                                      streamUrl: '',
                                    ),
                                  );

                                  return _ChannelHistoryTile(
                                    channel: channel,
                                    entry: entry,
                                    onTap: () {
                                      onChannelSelected(channel);
                                      onClose();
                                    },
                                    onRemove: () {
                                      channelHistory.removeEntry(entry.channelId);
                                      // Trigger rebuild by calling setState in parent
                                      (context as Element).markNeedsBuild();
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No channel history',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Channels you watch will appear here',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelHistoryTile extends StatelessWidget {
  final LiveTVChannel channel;
  final ChannelHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ChannelHistoryTile({
    required this.channel,
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = _formatTimeAgo(entry.timestamp);

    return InkWell(
      onTap: onTap,
      onLongPress: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Channel logo or number
            _buildChannelLogo(theme),
            const SizedBox(width: 12),
            // Channel info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel name
                  Text(
                    channel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Time info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                      if (entry.watchDuration.inSeconds > 0) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.play_circle_outline,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(entry.watchDuration),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close,
                color: Colors.grey[600],
                size: 20,
              ),
              tooltip: 'Remove from history',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelLogo(ThemeData theme) {
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
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          channel.number?.toString() ?? '#',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
