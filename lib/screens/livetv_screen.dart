import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/livetv_channel.dart';
import '../providers/plex_client_provider.dart';
import '../utils/app_logger.dart';
import 'dvr_screen.dart';
import 'livetv_player_screen.dart';

/// Live TV screen showing channel list and EPG guide
class LiveTVScreen extends StatefulWidget {
  const LiveTVScreen({super.key});

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  List<LiveTVChannel> _channels = [];
  bool _isLoading = true;
  String? _error;
  String _selectedGroup = 'All';
  List<String> _groups = ['All'];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadChannels();
    // Refresh what's on now every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadChannels(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChannels({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final client = context.read<PlexClientProvider>().client;
      if (client == null) {
        setState(() {
          _error = 'Not connected to server';
          _isLoading = false;
        });
        return;
      }

      // Get channels with current/next program info
      final channels = await client.getLiveTVWhatsOnNow();

      // Extract unique groups
      final groupSet = <String>{'All'};
      for (final channel in channels) {
        if (channel.group != null && channel.group!.isNotEmpty) {
          groupSet.add(channel.group!);
        }
      }

      setState(() {
        _channels = channels;
        _groups = groupSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      appLogger.e('Failed to load channels', error: e);
      if (!silent) {
        setState(() {
          _error = 'Failed to load channels: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<LiveTVChannel> get _filteredChannels {
    if (_selectedGroup == 'All') {
      return _channels;
    }
    return _channels.where((c) => c.group == _selectedGroup).toList();
  }

  void _playChannel(LiveTVChannel channel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveTVPlayerScreen(
          channel: channel,
          channels: _filteredChannels,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live TV'),
        actions: [
          if (_groups.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filter by group',
              onSelected: (group) {
                setState(() {
                  _selectedGroup = group;
                });
              },
              itemBuilder: (context) => _groups
                  .map((g) => PopupMenuItem(
                        value: g,
                        child: Row(
                          children: [
                            if (g == _selectedGroup)
                              const Icon(Icons.check, size: 18)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text(g),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          IconButton(
            icon: const Icon(Icons.fiber_manual_record),
            tooltip: 'DVR',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DVRScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadChannels(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Future<void> _scheduleRecording(LiveTVChannel channel) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ScheduleRecordingDialog(
        channel: channel,
        program: channel.nowPlaying,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording scheduled'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadChannels,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No channels available',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Add an M3U source in server settings',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    final filteredChannels = _filteredChannels;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredChannels.length,
      itemBuilder: (context, index) {
        final channel = filteredChannels[index];
        return _ChannelListTile(
          channel: channel,
          onTap: () => _playChannel(channel),
          onRecord: () => _scheduleRecording(channel),
        );
      },
    );
  }
}

class _ChannelListTile extends StatelessWidget {
  final LiveTVChannel channel;
  final VoidCallback onTap;
  final VoidCallback onRecord;

  const _ChannelListTile({
    required this.channel,
    required this.onTap,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = channel.nowPlaying;
    final next = channel.nextProgram;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Channel logo or number
              _buildChannelLogo(context),
              const SizedBox(width: 12),
              // Channel info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel name
                    Text(
                      channel.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (now != null) ...[
                      const SizedBox(height: 4),
                      // Current program
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LIVE',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              now.title,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Progress bar
                      LinearProgressIndicator(
                        value: now.progress,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 4),
                      // Time info
                      Text(
                        '${_formatTime(now.start)} - ${_formatTime(now.end)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (next != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Next: ${next.title}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Record and Play buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fiber_manual_record),
                    iconSize: 28,
                    color: Colors.red,
                    tooltip: 'Record',
                    onPressed: onRecord,
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled),
                    iconSize: 40,
                    color: theme.colorScheme.primary,
                    onPressed: onTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelLogo(BuildContext context) {
    final theme = Theme.of(context);

    if (channel.logo != null && channel.logo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          channel.number?.toString() ?? '#',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
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
