import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/livetv_channel.dart';
import '../video_controls/sheets/base_video_control_sheet.dart';

/// Bottom sheet showing detailed information about the current program
class ProgramDetailsSheet extends StatelessWidget {
  final LiveTVChannel channel;
  final VoidCallback? onRecord;

  const ProgramDetailsSheet({
    super.key,
    required this.channel,
    this.onRecord,
  });

  static Future<void> show(
    BuildContext context, {
    required LiveTVChannel channel,
    VoidCallback? onRecord,
    VoidCallback? onOpen,
    VoidCallback? onClose,
  }) {
    return BaseVideoControlSheet.showSheet(
      context: context,
      builder: (context) => ProgramDetailsSheet(
        channel: channel,
        onRecord: onRecord,
      ),
      onOpen: onOpen,
      onClose: onClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final program = channel.nowPlaying;
    final theme = Theme.of(context);

    return BaseVideoControlSheet(
      title: 'Program Details',
      icon: Icons.info_outline,
      child: program == null
          ? _buildNoProgram(context)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Program thumbnail/poster
                  if (program.icon != null && program.icon!.isNotEmpty)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          program.icon!,
                          width: 200,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage();
                          },
                        ),
                      ),
                    )
                  else
                    Center(child: _buildPlaceholderImage()),

                  const SizedBox(height: 20),

                  // Program title
                  Text(
                    program.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Channel and time info
                  Row(
                    children: [
                      Icon(
                        Icons.tv,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        channel.name,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatTime(program.start)} - ${_formatTime(program.end)}',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Time remaining
                  if (program.isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.live_tv,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_getRemainingMinutes(program)} min remaining',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Episode number if available
                  if (program.episodeNum != null &&
                      program.episodeNum!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.movie,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Episode: ${program.episodeNum}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Category if available
                  if (program.category != null &&
                      program.category!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Category: ${program.category}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (program.description != null &&
                      program.description!.isNotEmpty) ...[
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      program.description!,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Record button
                  if (onRecord != null)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: onRecord,
                        icon: const Icon(Icons.fiber_manual_record),
                        label: const Text('Record This Program'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildNoProgram(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              'No program information available',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Channel: ${channel.name}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.tv,
        size: 48,
        color: Colors.grey[600],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time.toLocal());
  }

  int _getRemainingMinutes(LiveTVProgram program) {
    final now = DateTime.now();
    final remaining = program.end.difference(now);
    return remaining.inMinutes;
  }
}
