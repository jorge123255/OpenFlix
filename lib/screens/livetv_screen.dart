import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../models/livetv_channel.dart';
import '../providers/media_client_provider.dart';
import '../utils/app_logger.dart';
import '../widgets/content_badge.dart';
import '../widgets/focus/focus_indicator.dart';
import 'dvr_screen.dart';
import 'onlater_screen.dart';
import 'tv_guide_screen.dart';
import 'livetv_multiview_screen.dart';
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
  bool _showFavoritesOnly = false;
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
      final client = context.read<MediaClientProvider>().client;
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
    var filtered = _channels;

    // Filter by group
    if (_selectedGroup != 'All') {
      filtered = filtered.where((c) => c.group == _selectedGroup).toList();
    }

    // Filter by favorites
    if (_showFavoritesOnly) {
      filtered = filtered.where((c) => c.isFavorite).toList();
    }

    return filtered;
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

  Future<void> _toggleFavorite(LiveTVChannel channel) async {
    try {
      final client = context.read<MediaClientProvider>().client;
      if (client == null) return;

      final updatedChannel = await client.toggleChannelFavorite(channel.id);
      if (updatedChannel != null && mounted) {
        setState(() {
          // Update the channel in the list
          final index = _channels.indexWhere((c) => c.id == channel.id);
          if (index >= 0) {
            _channels[index] = updatedChannel;
          }
        });
      }
    } catch (e) {
      appLogger.e('Failed to toggle favorite', error: e);
    }
  }

  void _launchMultiview() {
    if (_filteredChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.liveTV.noChannels)),
      );
      return;
    }

    // Start with first 2 channels for multi-view
    final initialChannels = _filteredChannels.take(2).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveTVMultiviewScreen(
          initialChannels: initialChannels,
          allChannels: _filteredChannels,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.liveTV.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.liveTV.refresh,
            onPressed: () => _loadChannels(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action bar
          _QuickActionBar(
            isTV: isTV,
            onGuide: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TVGuideScreen()),
            ),
            onDVR: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const DVRScreen()),
            ),
            onOnLater: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const OnLaterScreen()),
            ),
            onMultiview: _launchMultiview,
          ),

          // Category chips
          if (_groups.length > 1 || _showFavoritesOnly)
            _CategoryChips(
              groups: _groups,
              selectedGroup: _selectedGroup,
              showFavoritesOnly: _showFavoritesOnly,
              onGroupSelected: (group) {
                setState(() {
                  _selectedGroup = group;
                });
              },
              onFavoritesToggled: () {
                setState(() {
                  _showFavoritesOnly = !_showFavoritesOnly;
                });
              },
            ),

          // Channel count
          if (!_isLoading && _error == null && _channels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    t.liveTV.channelCount(count: _filteredChannels.length.toString()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Channel list
          Expanded(child: _buildBody()),
        ],
      ),
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
        SnackBar(
          content: Text(t.dvr.recordingScheduled),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

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
              label: Text(t.common.retry),
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
            Icon(Icons.live_tv, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              t.liveTV.noChannels,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.liveTV.addM3USource,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
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
        return _ChannelCard(
          channel: channel,
          onTap: () => _playChannel(channel),
          onRecord: () => _scheduleRecording(channel),
          onFavorite: () => _toggleFavorite(channel),
        );
      },
    );
  }
}

/// Quick action bar with Guide, DVR, On Later, Multiview buttons
class _QuickActionBar extends StatelessWidget {
  final bool isTV;
  final VoidCallback onGuide;
  final VoidCallback onDVR;
  final VoidCallback onOnLater;
  final VoidCallback onMultiview;

  const _QuickActionBar({
    required this.isTV,
    required this.onGuide,
    required this.onDVR,
    required this.onOnLater,
    required this.onMultiview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isTV ? 16 : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.grid_view_rounded,
              label: t.liveTV.guide,
              color: theme.colorScheme.primary,
              onTap: onGuide,
              isTV: isTV,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.fiber_manual_record,
              label: t.liveTV.dvr,
              color: Colors.red,
              onTap: onDVR,
              isTV: isTV,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.schedule,
              label: 'On Later',
              color: Colors.orange,
              onTap: onOnLater,
              isTV: isTV,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.view_comfy_rounded,
              label: t.liveTV.multiview,
              color: theme.colorScheme.tertiary,
              onTap: onMultiview,
              isTV: isTV,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isTV;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isTV,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isFocused
                  ? [
                      widget.color.withValues(alpha: 0.4),
                      widget.color.withValues(alpha: 0.2),
                    ]
                  : [
                      widget.color.withValues(alpha: 0.2),
                      widget.color.withValues(alpha: 0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isFocused
                  ? widget.color
                  : widget.color.withValues(alpha: 0.3),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: widget.isTV ? 20 : 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: widget.isTV ? 28 : 24,
                      ),
                    ),
                    SizedBox(height: widget.isTV ? 10 : 6),
                    Text(
                      widget.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrolling category/group chips
class _CategoryChips extends StatelessWidget {
  final List<String> groups;
  final String selectedGroup;
  final bool showFavoritesOnly;
  final ValueChanged<String> onGroupSelected;
  final VoidCallback onFavoritesToggled;

  const _CategoryChips({
    required this.groups,
    required this.selectedGroup,
    required this.showFavoritesOnly,
    required this.onGroupSelected,
    required this.onFavoritesToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // Favorites chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: showFavoritesOnly,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showFavoritesOnly ? Icons.star : Icons.star_border,
                    size: 18,
                    color: showFavoritesOnly
                        ? theme.colorScheme.onSecondaryContainer
                        : Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(t.liveTV.favorites),
                ],
              ),
              onSelected: (_) => onFavoritesToggled(),
            ),
          ),
          // Group chips
          ...groups.map((group) {
            final isSelected = group == selectedGroup && !showFavoritesOnly;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                selected: isSelected,
                label: Text(group == 'All' ? t.liveTV.allChannels : group),
                onSelected: (_) => onGroupSelected(group),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Enhanced channel card with program thumbnail and better layout
class _ChannelCard extends StatelessWidget {
  final LiveTVChannel channel;
  final VoidCallback onTap;
  final VoidCallback onRecord;
  final VoidCallback onFavorite;

  const _ChannelCard({
    required this.channel,
    required this.onTap,
    required this.onRecord,
    required this.onFavorite,
  });

  // Generate a color based on channel name for visual variety
  Color _getChannelColor() {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFEF4444), // Red
      const Color(0xFFF97316), // Orange
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF14B8A6), // Teal
      const Color(0xFF0EA5E9), // Sky
      const Color(0xFF3B82F6), // Blue
    ];
    return colors[channel.name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = channel.nowPlaying;
    final next = channel.nextProgram;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;
    final channelColor = _getChannelColor();

    return FocusableWrapper(
      debugLabel: 'LiveTVChannel_${channel.id}',
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA) {
            onTap();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.gameButtonX) {
            onRecord();
            return KeyEventResult.handled;
          }
          if (key == LogicalKeyboardKey.gameButtonY) {
            onFavorite();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      builder: (context, isFocused) => AnimatedScale(
        scale: isFocused ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isTV ? 8 : 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isFocused
                    ? channelColor.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: isFocused ? 24 : 12,
                offset: const Offset(0, 4),
                spreadRadius: isFocused ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    channelColor.withValues(alpha: 0.15),
                    theme.colorScheme.surface,
                  ],
                ),
                border: Border.all(
                  color: isFocused
                      ? channelColor
                      : Colors.white.withValues(alpha: 0.08),
                  width: isFocused ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                focusColor: Colors.transparent,
                child: SizedBox(
                  height: isTV ? 150 : 130,
                  child: Row(
                    children: [
                      // Program thumbnail or channel logo
                      _buildThumbnail(context, isTV, isFocused, channelColor),

                      // Channel info
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(isTV ? 16 : 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Channel name row
                              Row(
                                children: [
                                  // Channel logo
                                  if (channel.logo != null)
                                    Container(
                                      width: 36,
                                      height: 36,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: CachedNetworkImage(
                                        imageUrl: channel.logo!,
                                        fit: BoxFit.contain,
                                        errorWidget: (_, __, ___) =>
                                            const SizedBox(),
                                      ),
                                    ),
                                  // Channel name
                                  Expanded(
                                    child: Text(
                                      channel.name,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Favorite star
                                  if (channel.isFavorite)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.amber
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Current program
                              if (now != null) ...[
                                Text(
                                  now.title,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                // Progress bar
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: now.progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        gradient: LinearGradient(
                                          colors: [
                                            channelColor,
                                            channelColor.withValues(alpha: 0.7),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: channelColor
                                                .withValues(alpha: 0.5),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Time info and next program
                                Row(
                                  children: [
                                    // LIVE badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFDC2626),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red
                                                .withValues(alpha: 0.5),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      t.liveTV.endsAt(time: _formatTime(now.end)),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    if (next != null) ...[
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.skip_next_rounded,
                                              size: 14,
                                              color: Colors.white.withValues(alpha: 0.5),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              next.title,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: Colors.white.withValues(alpha: 0.5),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ] else ...[
                                const Spacer(),
                                // Improved "No program" placeholder
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 18,
                                        color: Colors.white.withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        t.liveTV.noProgram,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Action buttons
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTV ? 12 : 8,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ExcludeFocus(
                              child: _ActionIconButton(
                                icon: channel.isFavorite
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: isTV ? 28 : 24,
                                color: channel.isFavorite
                                    ? Colors.amber
                                    : Colors.white.withValues(alpha: 0.5),
                                hasGlow: channel.isFavorite,
                                glowColor: Colors.amber,
                                tooltip: t.liveTV.favorites,
                                onPressed: onFavorite,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ExcludeFocus(
                              child: _ActionIconButton(
                                icon: Icons.fiber_manual_record_rounded,
                                size: isTV ? 24 : 20,
                                color: Colors.red,
                                hasGlow: true,
                                glowColor: Colors.red,
                                tooltip: t.liveTV.scheduleRecording,
                                onPressed: onRecord,
                              ),
                            ),
                          ],
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

  Widget _buildThumbnail(
      BuildContext context, bool isTV, bool isFocused, Color channelColor) {
    final theme = Theme.of(context);
    final now = channel.nowPlaying;
    final width = isTV ? 220.0 : 180.0;

    // Use program icon if available, otherwise channel logo
    final imageUrl = now?.icon ?? channel.logo;

    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            channelColor.withValues(alpha: 0.3),
            channelColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  _buildFallbackThumbnail(theme, channelColor),
            )
          else
            _buildFallbackThumbnail(theme, channelColor),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

          // Right edge blend
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    channelColor.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
          ),

          // Play button
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isFocused ? 16 : 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: isFocused ? 0.8 : 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFocused ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: isFocused
                    ? [
                        BoxShadow(
                          color: channelColor.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: isTV ? (isFocused ? 44 : 38) : (isFocused ? 36 : 30),
              ),
            ),
          ),

          // Channel number badge
          if (channel.number != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      channelColor,
                      channelColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: channelColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${channel.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail(ThemeData theme, Color channelColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            channelColor.withValues(alpha: 0.4),
            channelColor.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: channel.logo != null
            ? Padding(
                padding: const EdgeInsets.all(28),
                child: CachedNetworkImage(
                  imageUrl: channel.logo!,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.live_tv_rounded,
                    size: 52,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              )
            : Icon(
                Icons.live_tv_rounded,
                size: 52,
                color: Colors.white.withValues(alpha: 0.6),
              ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time.toLocal());
  }
}

/// Stylized action icon button with optional glow effect
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final bool hasGlow;
  final Color? glowColor;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.tooltip,
    required this.onPressed,
    this.hasGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: hasGlow
                  ? [
                      BoxShadow(
                        color: (glowColor ?? color).withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: size,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
