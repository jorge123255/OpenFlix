import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/livetv_channel.dart';
import '../providers/media_client_provider.dart';
import '../utils/app_logger.dart';
import 'livetv_player_screen.dart';

class EPGGuideScreen extends StatefulWidget {
  const EPGGuideScreen({super.key});

  @override
  State<EPGGuideScreen> createState() => _EPGGuideScreenState();
}

class _EPGGuideScreenState extends State<EPGGuideScreen> {
  LiveTVGuideData? _guideData;
  bool _isLoading = true;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  Timer? _timeUpdateTimer;
  Timer? _autoRefreshTimer;

  // Grid configuration
  static const double channelColumnWidth = 200.0;
  static const double timeSlotWidth = 120.0; // Width per 30 minutes
  static const double channelRowHeight = 80.0;
  static const double timeHeaderHeight = 60.0;
  static const int hoursToShow = 6; // Show 6 hours at a time

  @override
  void initState() {
    super.initState();
    _loadGuideData();

    // Update current time every minute
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          // Force rebuild to update time-dependent widgets
        });
      }
    });

    // Auto-refresh guide data every 30 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _loadGuideData();
    });

    // Scroll to current time after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGuideData() async {
    final client = context.read<MediaClientProvider>().client;
    if (client == null) return;

    setState(() => _isLoading = true);

    try {
      // Load guide data for current time + hoursToShow
      final start = DateTime.now().subtract(const Duration(hours: 1));
      final end = start.add(Duration(hours: hoursToShow + 1));

      final data = await client.getLiveTVGuide(
        start: start,
        end: end,
      );

      if (mounted) {
        setState(() {
          _guideData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      appLogger.e('Failed to load EPG guide', error: e);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToCurrentTime() {
    if (_guideData == null) return;

    final now = DateTime.now();
    final start = _guideData!.startTime;
    final minutesSinceStart = now.difference(start).inMinutes;
    final pixelsPerMinute = timeSlotWidth / 30; // 30 minutes per slot
    final scrollOffset = minutesSinceStart * pixelsPerMinute - 200;

    if (scrollOffset > 0) {
      _horizontalScrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildTimeHeader() {
    if (_guideData == null) return const SizedBox.shrink();

    final start = _guideData!.startTime;
    final end = _guideData!.endTime;
    final totalMinutes = end.difference(start).inMinutes;
    final timeSlots = (totalMinutes / 30).ceil();

    return Container(
      height: timeHeaderHeight,
      color: Colors.grey[900],
      child: Row(
        children: [
          // Fixed channel header
          Container(
            width: channelColumnWidth,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              border: Border(
                right: BorderSide(color: Colors.grey[700]!),
                bottom: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: const Center(
              child: Text(
                'Channels',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          // Scrollable time slots
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(timeSlots, (index) {
                  final slotTime = start.add(Duration(minutes: index * 30));
                  final isCurrentSlot = _isTimeInSlot(DateTime.now(), slotTime);

                  return Container(
                    width: timeSlotWidth,
                    decoration: BoxDecoration(
                      color: isCurrentSlot ? Colors.indigo[900] : Colors.grey[850],
                      border: Border(
                        right: BorderSide(color: Colors.grey[700]!),
                        bottom: BorderSide(color: Colors.grey[700]!),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(slotTime),
                          style: TextStyle(
                            color: isCurrentSlot ? Colors.white : Colors.grey[400],
                            fontWeight: isCurrentSlot ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('EEE, MMM d').format(slotTime),
                          style: TextStyle(
                            color: isCurrentSlot ? Colors.grey[300] : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isTimeInSlot(DateTime time, DateTime slotStart) {
    final slotEnd = slotStart.add(const Duration(minutes: 30));
    return time.isAfter(slotStart) && time.isBefore(slotEnd);
  }

  Widget _buildChannelRow(LiveTVChannel channel) {
    final programs = _guideData?.programs[channel.channelId] ?? [];
    final start = _guideData!.startTime;
    final pixelsPerMinute = timeSlotWidth / 30;

    return Container(
      height: channelRowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          // Channel info (fixed column)
          Container(
            width: channelColumnWidth,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                right: BorderSide(color: Colors.grey[700]!),
              ),
            ),
            child: Row(
              children: [
                // Channel logo or number
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: channel.logo != null && channel.logo!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            channel.logo!,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                '${channel.number}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            '${channel.number}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Channel name
                Expanded(
                  child: Text(
                    channel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Programs (scrollable)
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Stack(
                children: [
                  // Program blocks
                  ...programs.map((program) {
                    final minutesFromStart = program.start.difference(start).inMinutes;
                    final durationMinutes = program.durationMinutes;
                    final leftOffset = minutesFromStart * pixelsPerMinute;
                    final width = durationMinutes * pixelsPerMinute;

                    return Positioned(
                      left: leftOffset,
                      top: 4,
                      child: _buildProgramBlock(channel, program, width),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramBlock(LiveTVChannel channel, LiveTVProgram program, double width) {
    final isLive = program.isLive;
    final progress = program.progress;

    return GestureDetector(
      onTap: () => _playChannel(channel),
      child: Container(
        width: width,
        height: channelRowHeight - 8,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          color: isLive ? Colors.indigo[700] : Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isLive ? Colors.indigo[400]! : Colors.grey[700]!,
            width: isLive ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Progress indicator for live programs
            if (isLive && progress > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[300]!),
                  minHeight: 3,
                ),
              ),
            // Program info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('h:mm a').format(program.start),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: Text(
                      program.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playChannel(LiveTVChannel channel) {
    final allChannels = _guideData?.channels ?? [];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LiveTVPlayerScreen(
          channel: channel,
          channels: allChannels,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('TV Guide'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: _scrollToCurrentTime,
            tooltip: 'Go to Now',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGuideData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _guideData == null || _guideData!.channels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tv_off, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'No EPG data available',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add an EPG source in Live TV settings',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Time header
                    _buildTimeHeader(),
                    // Channel rows
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        child: Column(
                          children: _guideData!.channels
                              .map((channel) => _buildChannelRow(channel))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
