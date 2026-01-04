import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../models/livetv_channel.dart';
import '../providers/media_client_provider.dart';
import '../services/gracenote_epg_service.dart';
import '../utils/app_logger.dart';
import '../utils/desktop_window_padding.dart';
import '../widgets/focus/focus_indicator.dart';
import 'dvr_screen.dart';
import 'livetv_player_screen.dart';

class LiveTVGuideScreen extends StatefulWidget {
  const LiveTVGuideScreen({super.key});

  @override
  State<LiveTVGuideScreen> createState() => _LiveTVGuideScreenState();
}

class _LiveTVGuideScreenState extends State<LiveTVGuideScreen> {
  LiveTVGuideData? _guide;
  bool _isLoading = true;
  String? _error;

  String _selectedGroup = 'All';
  List<String> _groups = ['All'];

  Timer? _refreshTimer;

  late final ScrollController _horizontalController;
  late final ScrollController _channelsVerticalController;
  late final ScrollController _gridVerticalController;
  bool _isSyncingVerticalScroll = false;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _channelsVerticalController = ScrollController();
    _gridVerticalController = ScrollController();
    _channelsVerticalController.addListener(_syncChannelsToGrid);
    _gridVerticalController.addListener(_syncGridToChannels);
    _loadGuide();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadGuide(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _channelsVerticalController.removeListener(_syncChannelsToGrid);
    _gridVerticalController.removeListener(_syncGridToChannels);
    _horizontalController.dispose();
    _channelsVerticalController.dispose();
    _gridVerticalController.dispose();
    super.dispose();
  }

  void _syncChannelsToGrid() {
    if (_isSyncingVerticalScroll) return;
    if (!_channelsVerticalController.hasClients || !_gridVerticalController.hasClients) {
      return;
    }
    _isSyncingVerticalScroll = true;
    final target = _channelsVerticalController.offset;
    final clamped = target.clamp(
      _gridVerticalController.position.minScrollExtent,
      _gridVerticalController.position.maxScrollExtent,
    );
    _gridVerticalController.jumpTo(clamped);
    _isSyncingVerticalScroll = false;
  }

  void _syncGridToChannels() {
    if (_isSyncingVerticalScroll) return;
    if (!_channelsVerticalController.hasClients || !_gridVerticalController.hasClients) {
      return;
    }
    _isSyncingVerticalScroll = true;
    final target = _gridVerticalController.offset;
    final clamped = target.clamp(
      _channelsVerticalController.position.minScrollExtent,
      _channelsVerticalController.position.maxScrollExtent,
    );
    _channelsVerticalController.jumpTo(clamped);
    _isSyncingVerticalScroll = false;
  }

  DateTime _defaultStart() {
    final now = DateTime.now();
    final minutes = now.minute;
    final snappedMinutes = minutes < 30 ? 0 : 30;
    return DateTime(now.year, now.month, now.day, now.hour, snappedMinutes);
  }

  Future<void> _testGracenote() async {
    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Testing Gracenote EPG...'),
                ],
              ),
            ),
          ),
        ),
      );

      final epgService = GracenoteEPGService();
      final channels = await epgService.getTVListings(
        affiliateId: 'orbebb',
        hours: 3,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Gracenote EPG Test'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Success! Got ${channels.length} channels'),
                const SizedBox(height: 16),
                if (channels.isNotEmpty) ...[
                  const Text('Sample channels:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...channels.take(5).map((ch) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${ch.channelNo} - ${ch.callSign}'),
                            if (ch.events.isNotEmpty)
                              Text(
                                '  Now: ${ch.events.first.program.title}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog if open

      // Show error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Gracenote Test Failed'),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadGuide({bool silent = false}) async {
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

      final start = _defaultStart();
      final end = start.add(const Duration(hours: 24));

      final guide = await client.getLiveTVGuide(start: start, end: end);
      if (guide == null) {
        setState(() {
          _error = 'Failed to load guide';
          _isLoading = false;
        });
        return;
      }

      final groupSet = <String>{'All'};
      for (final ch in guide.channels) {
        if (ch.group != null && ch.group!.isNotEmpty) {
          groupSet.add(ch.group!);
        }
      }

      setState(() {
        _guide = guide;
        _groups = groupSet.toList()..sort();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      appLogger.e('Failed to load Live TV guide', error: e, stackTrace: stackTrace);
      if (!silent) {
        setState(() {
          _error = 'Failed to load guide: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<LiveTVChannel> get _filteredChannels {
    final guide = _guide;
    if (guide == null) return [];
    if (_selectedGroup == 'All') return guide.channels;
    return guide.channels.where((c) => c.group == _selectedGroup).toList();
  }

  List<LiveTVProgram> _programsForChannel(LiveTVChannel channel) {
    final guide = _guide;
    if (guide == null) return const [];
    return guide.programs[channel.channelId] ?? const [];
  }

  void _tuneChannel(LiveTVChannel channel) {
    final channels = _filteredChannels;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveTVPlayerScreen(
          channel: channel,
          channels: channels,
        ),
      ),
    );
  }

  Future<void> _recordProgram(LiveTVChannel channel, LiveTVProgram program) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ScheduleRecordingDialog(
        channel: channel,
        program: program,
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

  Future<void> _showProgramDetails(LiveTVChannel channel, LiveTVProgram program) async {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '${channel.name} • ${timeFormat.format(program.start.toLocal())} - ${timeFormat.format(program.end.toLocal())}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (program.description != null && program.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(program.description!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _tuneChannel(channel);
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(t.liveTV.tune),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _recordProgram(channel, program);
                        },
                        icon: const Icon(Icons.fiber_manual_record),
                        label: Text(t.epg.record),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final start = _guide?.startTime ?? _defaultStart();

    return Scaffold(
      appBar: AppBar(
        title: DesktopTitleBarPadding(
          child: Text('Guide • ${dateFormat.format(start.toLocal())}'),
        ),
        actions: DesktopAppBarHelper.buildAdjustedActions([
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
                  .map(
                    (g) => PopupMenuItem(
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
                    ),
                  )
                  .toList(),
            ),
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Test Gracenote EPG',
            onPressed: _testGracenote,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadGuide(),
          ),
        ]),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _testGracenote,
        tooltip: 'Test Gracenote EPG',
        child: const Icon(Icons.science),
      ),
    );
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
              onPressed: _loadGuide,
              icon: const Icon(Icons.refresh),
              label: Text(t.liveTV.retry),
            ),
          ],
        ),
      );
    }

    final guide = _guide;
    if (guide == null || guide.channels.isEmpty) {
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
          ],
        ),
      );
    }

    final channels = _filteredChannels;
    final start = guide.startTime;
    final end = guide.endTime;

    const channelColumnWidth = 280.0;
    const timeHeaderHeight = 52.0;
    const rowHeight = 78.0;
    const pxPerMinute = 3.0;
    const tickMinutes = 30;

    final totalMinutes = end.difference(start).inMinutes;
    final gridWidth = totalMinutes * pxPerMinute;

    return Column(
      children: [
        SizedBox(
          height: timeHeaderHeight,
          child: Row(
            children: [
              const SizedBox(width: channelColumnWidth),
              Expanded(
                child: Scrollbar(
                  controller: _horizontalController,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: gridWidth,
                      height: timeHeaderHeight,
                      child: _TimeHeader(
                        start: start,
                        end: end,
                        pxPerMinute: pxPerMinute,
                        tickMinutes: tickMinutes,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: channelColumnWidth,
                child: ListView.builder(
                  controller: _channelsVerticalController,
                  itemExtent: rowHeight,
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    return _ChannelCell(
                      channel: channel,
                      onTune: () => _tuneChannel(channel),
                    );
                  },
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _horizontalController,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: gridWidth,
                      child: ListView.builder(
                        controller: _gridVerticalController,
                        itemExtent: rowHeight,
                        itemCount: channels.length,
                        itemBuilder: (context, index) {
                          final channel = channels[index];
                          final programs = _programsForChannel(channel);
                          return _ProgramRow(
                            channel: channel,
                            programs: programs,
                            start: start,
                            end: end,
                            rowHeight: rowHeight,
                            pxPerMinute: pxPerMinute,
                            onProgramSelected: (program) =>
                                _showProgramDetails(channel, program),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeHeader extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final double pxPerMinute;
  final int tickMinutes;

  const _TimeHeader({
    required this.start,
    required this.end,
    required this.pxPerMinute,
    required this.tickMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();
    final tickWidth = tickMinutes * pxPerMinute;
    final tickCount = end.difference(start).inMinutes ~/ tickMinutes;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: List.generate(tickCount + 1, (i) {
          final t = start.add(Duration(minutes: i * tickMinutes));
          return SizedBox(
            width: tickWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  timeFormat.format(t.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChannelCell extends StatelessWidget {
  final LiveTVChannel channel;
  final VoidCallback onTune;

  const _ChannelCell({required this.channel, required this.onTune});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTune,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            _ChannelBadge(channel: channel),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramRow extends StatelessWidget {
  final LiveTVChannel channel;
  final List<LiveTVProgram> programs;
  final DateTime start;
  final DateTime end;
  final double rowHeight;
  final double pxPerMinute;
  final void Function(LiveTVProgram program) onProgramSelected;

  const _ProgramRow({
    required this.channel,
    required this.programs,
    required this.start,
    required this.end,
    required this.rowHeight,
    required this.pxPerMinute,
    required this.onProgramSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final totalMinutes = end.difference(start).inMinutes;
    final rowWidth = totalMinutes * pxPerMinute;
    final nowOffset = now.isBefore(start)
        ? 0.0
        : now.isAfter(end)
            ? rowWidth
            : now.difference(start).inMinutes * pxPerMinute;

    final visiblePrograms = programs.where((p) {
      return p.end.isAfter(start) && p.start.isBefore(end);
    }).toList();

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
        ),
      ),
      child: Stack(
        children: [
          for (final p in visiblePrograms)
            _PositionedProgram(
              program: p,
              windowStart: start,
              windowEnd: end,
              pxPerMinute: pxPerMinute,
              rowHeight: rowHeight,
              onPressed: () => onProgramSelected(p),
            ),
          IgnorePointer(
            child: Positioned(
              left: nowOffset,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionedProgram extends StatelessWidget {
  final LiveTVProgram program;
  final DateTime windowStart;
  final DateTime windowEnd;
  final double pxPerMinute;
  final double rowHeight;
  final VoidCallback onPressed;

  const _PositionedProgram({
    required this.program,
    required this.windowStart,
    required this.windowEnd,
    required this.pxPerMinute,
    required this.rowHeight,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();

    final effectiveStart = program.start.isBefore(windowStart) ? windowStart : program.start;
    final effectiveEnd = program.end.isAfter(windowEnd) ? windowEnd : program.end;

    final left = effectiveStart.difference(windowStart).inMinutes * pxPerMinute;
    final width = effectiveEnd.difference(effectiveStart).inMinutes * pxPerMinute;

    final isLive = program.isLive;
    final bg = isLive
        ? theme.colorScheme.primary.withValues(alpha: 0.22)
        : theme.colorScheme.surfaceContainerHighest;

    return Positioned(
      left: left,
      top: 8,
      bottom: 8,
      width: width < 60 ? 60 : width,
      child: FocusableWrapper(
        debugLabel: 'EPG_${program.channelId}_${program.id}',
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.gameButtonA) {
              onPressed();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        builder: (context, isFocused) => FocusIndicator(
          isFocused: isFocused,
          borderRadius: 10,
          child: InkWell(
            onTap: onPressed,
            focusColor: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    program.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${timeFormat.format(program.start.toLocal())} - ${timeFormat.format(program.end.toLocal())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelBadge extends StatelessWidget {
  final LiveTVChannel channel;

  const _ChannelBadge({required this.channel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (channel.logo != null && channel.logo!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Image.network(
            channel.logo!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildNumber(theme);
            },
          ),
        ),
      );
    }

    return _buildNumber(theme);
  }

  Widget _buildNumber(ThemeData theme) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        channel.number?.toString() ?? '#',
        style: TextStyle(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
