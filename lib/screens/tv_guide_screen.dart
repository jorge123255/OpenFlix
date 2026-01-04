import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/livetv_channel.dart';
import '../providers/media_client_provider.dart';
import '../utils/app_logger.dart';
import 'livetv_player_screen.dart';

/// TV Guide screen - traditional EPG grid layout
class TVGuideScreen extends StatefulWidget {
  const TVGuideScreen({super.key});

  @override
  State<TVGuideScreen> createState() => _TVGuideScreenState();
}

class _TVGuideScreenState extends State<TVGuideScreen> {
  // Data
  LiveTVGuideData? _guideData;
  List<LiveTVChannel> _channels = [];
  bool _isLoading = true;
  String? _error;

  // Time navigation
  late DateTime _currentTime;
  late DateTime _guideStartTime;
  late DateTime _guideEndTime;

  // Selection
  int _selectedChannelIndex = 0;
  int _selectedProgramIndex = 0;
  LiveTVProgram? _selectedProgram;

  // Scroll controllers
  final ScrollController _channelScrollController = ScrollController();
  final ScrollController _programScrollController = ScrollController();
  final ScrollController _timeHeaderScrollController = ScrollController();

  // Constants
  static const double channelColumnWidth = 200.0;
  static const double channelRowHeight = 60.0;
  static const double timeSlotWidth = 150.0; // Per 30 minutes
  static const double timeHeaderHeight = 40.0;
  static const int hoursToShow = 6;

  // Filter
  String _selectedProvider = 'All Providers';
  List<String> _providers = ['All Providers'];

  // Focus
  final FocusNode _gridFocusNode = FocusNode();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _calculateTimeRange();
    _loadGuideData();

    // Sync scroll controllers
    _programScrollController.addListener(_syncTimeHeaderScroll);

    // Auto-refresh every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _currentTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    _channelScrollController.dispose();
    _programScrollController.dispose();
    _timeHeaderScrollController.dispose();
    _gridFocusNode.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _calculateTimeRange() {
    // Start at the beginning of the current half-hour
    final minutes = _currentTime.minute;
    final roundedMinutes = (minutes ~/ 30) * 30;
    _guideStartTime = DateTime(
      _currentTime.year,
      _currentTime.month,
      _currentTime.day,
      _currentTime.hour,
      roundedMinutes,
    );
    _guideEndTime = _guideStartTime.add(Duration(hours: hoursToShow));
  }

  void _syncTimeHeaderScroll() {
    if (_timeHeaderScrollController.hasClients) {
      _timeHeaderScrollController.jumpTo(_programScrollController.offset);
    }
  }

  Future<void> _loadGuideData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = context.read<MediaClientProvider>().client;
      if (client == null) {
        setState(() {
          _error = 'Not connected to server';
          _isLoading = false;
        });
        return;
      }

      // Load guide data
      final guideData = await client.getLiveTVGuide(
        start: _guideStartTime,
        end: _guideEndTime,
      );

      if (guideData != null) {
        // Extract providers/groups
        final providerSet = <String>{'All Providers'};
        for (final channel in guideData.channels) {
          if (channel.group != null && channel.group!.isNotEmpty) {
            providerSet.add(channel.group!);
          }
        }

        setState(() {
          _guideData = guideData;
          _channels = guideData.channels;
          _providers = providerSet.toList()..sort();
          _isLoading = false;
          _updateSelectedProgram();
        });
      }
    } catch (e) {
      appLogger.e('Failed to load guide data', error: e);
      setState(() {
        _error = 'Failed to load guide: $e';
        _isLoading = false;
      });
    }
  }

  List<LiveTVChannel> get _filteredChannels {
    if (_selectedProvider == 'All Providers') {
      return _channels;
    }
    return _channels.where((c) => c.group == _selectedProvider).toList();
  }

  void _navigateTime(int direction) {
    setState(() {
      _guideStartTime = _guideStartTime.add(Duration(hours: direction * 2));
      _guideEndTime = _guideEndTime.add(Duration(hours: direction * 2));
    });
    _loadGuideData();
  }

  void _goToNow() {
    _currentTime = DateTime.now();
    _calculateTimeRange();
    _loadGuideData();
    // Scroll to current time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  void _scrollToCurrentTime() {
    if (!_programScrollController.hasClients) return;

    final minutesSinceStart = _currentTime.difference(_guideStartTime).inMinutes;
    final scrollOffset = (minutesSinceStart / 30) * timeSlotWidth;

    _programScrollController.animateTo(
      scrollOffset.clamp(0, _programScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateSelectedProgram() {
    final channels = _filteredChannels;
    if (channels.isEmpty || _guideData == null) {
      _selectedProgram = null;
      return;
    }

    final channel = channels[_selectedChannelIndex.clamp(0, channels.length - 1)];
    final programs = _guideData!.programs[channel.channelId] ?? [];

    if (programs.isEmpty) {
      _selectedProgram = null;
      return;
    }

    _selectedProgram = programs[_selectedProgramIndex.clamp(0, programs.length - 1)];
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final channels = _filteredChannels;
    if (channels.isEmpty) return;

    setState(() {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if (_selectedChannelIndex > 0) {
            _selectedChannelIndex--;
            _selectedProgramIndex = 0;
            _ensureChannelVisible();
          }
          break;
        case LogicalKeyboardKey.arrowDown:
          if (_selectedChannelIndex < channels.length - 1) {
            _selectedChannelIndex++;
            _selectedProgramIndex = 0;
            _ensureChannelVisible();
          }
          break;
        case LogicalKeyboardKey.arrowLeft:
          final channel = channels[_selectedChannelIndex];
          final programs = _guideData?.programs[channel.channelId] ?? [];
          if (_selectedProgramIndex > 0) {
            _selectedProgramIndex--;
          }
          break;
        case LogicalKeyboardKey.arrowRight:
          final channel = channels[_selectedChannelIndex];
          final programs = _guideData?.programs[channel.channelId] ?? [];
          if (_selectedProgramIndex < programs.length - 1) {
            _selectedProgramIndex++;
          }
          break;
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.select:
          _showProgramDetails();
          break;
        case LogicalKeyboardKey.gameButtonA:
          _showProgramDetails();
          break;
        case LogicalKeyboardKey.gameButtonX:
          _recordProgram();
          break;
      }
      _updateSelectedProgram();
    });
  }

  void _ensureChannelVisible() {
    if (!_channelScrollController.hasClients) return;

    final targetOffset = _selectedChannelIndex * channelRowHeight;
    final viewportHeight = _channelScrollController.position.viewportDimension;
    final currentOffset = _channelScrollController.offset;

    if (targetOffset < currentOffset) {
      _channelScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else if (targetOffset + channelRowHeight > currentOffset + viewportHeight) {
      _channelScrollController.animateTo(
        targetOffset + channelRowHeight - viewportHeight,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showProgramDetails() {
    if (_selectedProgram == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ProgramDetailsSheet(
        program: _selectedProgram!,
        channel: _filteredChannels[_selectedChannelIndex],
        onRecord: () => _recordProgram(),
        onRecordSeries: () => _recordSeries(),
        onWatch: () => _watchChannel(),
      ),
    );
  }

  void _recordProgram() {
    if (_selectedProgram == null) return;
    _scheduleRecording(_selectedProgram!, false);
  }

  void _recordSeries() {
    if (_selectedProgram == null) return;
    _scheduleRecording(_selectedProgram!, true);
  }

  Future<void> _scheduleRecording(LiveTVProgram program, bool seriesRecord) async {
    final client = context.read<MediaClientProvider>().client;
    if (client == null) return;

    try {
      final channel = _filteredChannels[_selectedChannelIndex];
      await client.createDVRRecording(
        channelId: channel.id,
        programId: program.id,
        seriesRecord: seriesRecord,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(seriesRecord
                ? 'Series recording scheduled for "${program.title}"'
                : 'Recording scheduled for "${program.title}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _watchChannel() {
    if (_filteredChannels.isEmpty) return;
    final channel = _filteredChannels[_selectedChannelIndex];

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
      backgroundColor: const Color(0xFF0D1117),
      body: KeyboardListener(
        focusNode: _gridFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Time header
            _buildTimeHeader(),
            // Main content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _buildGuideGrid(),
            ),
            // Program info bar at bottom
            if (_selectedProgram != null) _buildProgramInfoBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          // Title
          const Text(
            'TV Guide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Provider dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8B5CF6)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedProvider,
                dropdownColor: const Color(0xFF21262D),
                style: const TextStyle(color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8B5CF6)),
                items: _providers.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedProvider = value;
                      _selectedChannelIndex = 0;
                      _selectedProgramIndex = 0;
                      _updateSelectedProgram();
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Time navigation
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_left, color: Colors.white),
            ),
            onPressed: () => _navigateTime(-1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF21262D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('h:mm a').format(_currentTime),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF21262D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white),
            ),
            onPressed: () => _navigateTime(1),
          ),
          const SizedBox(width: 8),
          // Refresh button
          TextButton.icon(
            onPressed: _loadGuideData,
            icon: const Icon(Icons.refresh, color: Colors.white70),
            label: const Text('Refresh', style: TextStyle(color: Colors.white70)),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF21262D),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeHeader() {
    final timeSlots = _generateTimeSlots();

    return Container(
      height: timeHeaderHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Empty space for channel column
          SizedBox(width: channelColumnWidth),
          // Scrollable time slots
          Expanded(
            child: SingleChildScrollView(
              controller: _timeHeaderScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: timeSlots.map((time) {
                  final isHour = time.minute == 0;
                  return Container(
                    width: timeSlotWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: isHour
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Text(
                      isHour
                          ? DateFormat('h a').format(time)
                          : ':${time.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isHour ? Colors.white : Colors.white60,
                        fontSize: isHour ? 14 : 12,
                        fontWeight: isHour ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _generateTimeSlots() {
    final slots = <DateTime>[];
    var current = _guideStartTime;
    while (current.isBefore(_guideEndTime)) {
      slots.add(current);
      current = current.add(const Duration(minutes: 30));
    }
    return slots;
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadGuideData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideGrid() {
    final channels = _filteredChannels;
    if (channels.isEmpty) {
      return const Center(
        child: Text(
          'No channels available',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return Row(
      children: [
        // Channel list (fixed)
        SizedBox(
          width: channelColumnWidth,
          child: _buildChannelList(channels),
        ),
        // Program grid (scrollable)
        Expanded(
          child: _buildProgramGrid(channels),
        ),
      ],
    );
  }

  Widget _buildChannelList(List<LiveTVChannel> channels) {
    return ListView.builder(
      controller: _channelScrollController,
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isSelected = index == _selectedChannelIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedChannelIndex = index;
              _selectedProgramIndex = 0;
              _updateSelectedProgram();
            });
          },
          child: Container(
            height: channelRowHeight,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                left: isSelected
                    ? const BorderSide(color: Color(0xFF8B5CF6), width: 3)
                    : BorderSide.none,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Channel logo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: channel.logo != null
                      ? CachedNetworkImage(
                          imageUrl: channel.logo!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.tv, color: Colors.grey),
                        )
                      : const Icon(Icons.tv, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                // Channel info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${channel.number ?? '-'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        channel.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgramGrid(List<LiveTVChannel> channels) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Sync vertical scroll between channel list and program grid
        if (notification is ScrollUpdateNotification) {
          if (_channelScrollController.hasClients) {
            _channelScrollController.jumpTo(notification.metrics.pixels);
          }
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _programScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _calculateTotalWidth(),
          child: Stack(
            children: [
              // Program rows
              ListView.builder(
                itemCount: channels.length,
                itemBuilder: (context, channelIndex) {
                  final channel = channels[channelIndex];
                  final programs = _guideData?.programs[channel.channelId] ?? [];
                  final isChannelSelected = channelIndex == _selectedChannelIndex;

                  return SizedBox(
                    height: channelRowHeight,
                    child: Stack(
                      children: [
                        // Background
                        Container(
                          decoration: BoxDecoration(
                            color: isChannelSelected
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                        ),
                        // Programs
                        ...programs.asMap().entries.map((entry) {
                          final programIndex = entry.key;
                          final program = entry.value;
                          return _buildProgramBlock(
                            program,
                            channelIndex,
                            programIndex,
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
              // Current time indicator
              _buildCurrentTimeIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalWidth() {
    final totalMinutes = _guideEndTime.difference(_guideStartTime).inMinutes;
    return (totalMinutes / 30) * timeSlotWidth;
  }

  Widget _buildProgramBlock(
    LiveTVProgram program,
    int channelIndex,
    int programIndex,
  ) {
    // Calculate position and width
    final startOffset = program.start.difference(_guideStartTime).inMinutes;
    final endOffset = program.end.difference(_guideStartTime).inMinutes;

    // Clamp to visible range
    final visibleStart = startOffset.clamp(0, _guideEndTime.difference(_guideStartTime).inMinutes);
    final visibleEnd = endOffset.clamp(0, _guideEndTime.difference(_guideStartTime).inMinutes);

    if (visibleEnd <= visibleStart) return const SizedBox.shrink();

    final left = (visibleStart / 30) * timeSlotWidth;
    final width = ((visibleEnd - visibleStart) / 30) * timeSlotWidth;

    final isSelected = channelIndex == _selectedChannelIndex &&
        programIndex == _selectedProgramIndex;
    final isLive = program.isLive;

    // Genre-based color
    final baseColor = _getGenreColor(program.category);

    return Positioned(
      left: left + 1,
      top: 2,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedChannelIndex = channelIndex;
            _selectedProgramIndex = programIndex;
            _updateSelectedProgram();
          });
        },
        onDoubleTap: _showProgramDetails,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: width - 2,
          height: channelRowHeight - 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [
                      const Color(0xFF8B5CF6),
                      const Color(0xFF6366F1),
                    ]
                  : [
                      baseColor.withValues(alpha: 0.8),
                      baseColor.withValues(alpha: 0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : isLive
                      ? const Color(0xFFEF4444)
                      : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      program.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (width > 100) ...[
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('h:mm').format(program.start)} - ${DateFormat('h:mm a').format(program.end)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getGenreColor(String? category) {
    if (category == null) return const Color(0xFF374151);

    final cat = category.toLowerCase();
    if (cat.contains('sport')) return const Color(0xFF10B981);
    if (cat.contains('movie') || cat.contains('film')) return const Color(0xFFF59E0B);
    if (cat.contains('news')) return const Color(0xFF3B82F6);
    if (cat.contains('kid') || cat.contains('child')) return const Color(0xFFEC4899);
    if (cat.contains('documentary') || cat.contains('doc')) return const Color(0xFF8B5CF6);
    if (cat.contains('music')) return const Color(0xFFEF4444);
    if (cat.contains('comedy')) return const Color(0xFFF97316);
    if (cat.contains('drama')) return const Color(0xFF6366F1);
    if (cat.contains('series')) return const Color(0xFF14B8A6);

    return const Color(0xFF374151);
  }

  Widget _buildCurrentTimeIndicator() {
    final minutesSinceStart = _currentTime.difference(_guideStartTime).inMinutes;
    if (minutesSinceStart < 0 || minutesSinceStart > hoursToShow * 60) {
      return const SizedBox.shrink();
    }

    final left = (minutesSinceStart / 30) * timeSlotWidth;

    return Positioned(
      left: left,
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramInfoBar() {
    final program = _selectedProgram!;
    final channel = _filteredChannels[_selectedChannelIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF161B22),
            const Color(0xFF0D1117),
          ],
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Program info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      program.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF21262D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${DateFormat('h:mm').format(program.start)} - ${DateFormat('h:mm a').format(program.end)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (program.category != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getGenreColor(program.category).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          program.category!,
                          style: TextStyle(
                            color: _getGenreColor(program.category),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (program.episodeNum != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          program.episodeNum!,
                          style: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (program.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    program.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              _buildActionButton(
                icon: Icons.play_arrow_rounded,
                label: 'Watch',
                color: const Color(0xFF10B981),
                onPressed: _watchChannel,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.fiber_manual_record,
                label: 'Record',
                color: const Color(0xFFEF4444),
                onPressed: _recordProgram,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.repeat_rounded,
                label: 'Series',
                color: const Color(0xFF8B5CF6),
                onPressed: _recordSeries,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.info_outline,
                label: 'Info',
                color: const Color(0xFF3B82F6),
                onPressed: _showProgramDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: color)),
      style: TextButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Program details bottom sheet
class _ProgramDetailsSheet extends StatelessWidget {
  final LiveTVProgram program;
  final LiveTVChannel channel;
  final VoidCallback onRecord;
  final VoidCallback onRecordSeries;
  final VoidCallback onWatch;

  const _ProgramDetailsSheet({
    required this.program,
    required this.channel,
    required this.onRecord,
    required this.onRecordSeries,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and channel
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Program artwork placeholder
                    Container(
                      width: 120,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF21262D),
                        borderRadius: BorderRadius.circular(8),
                        image: program.icon != null
                            ? DecorationImage(
                                image: NetworkImage(program.icon!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: program.icon == null
                          ? const Center(
                              child: Icon(Icons.tv, color: Colors.white30, size: 40),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            channel.name,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF21262D),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${DateFormat('E, MMM d').format(program.start)} • ${DateFormat('h:mm').format(program.start)} - ${DateFormat('h:mm a').format(program.end)}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF21262D),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${program.durationMinutes} min',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Category and episode info
                if (program.category != null || program.episodeNum != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (program.category != null)
                        _buildTag(program.category!, const Color(0xFF10B981)),
                      if (program.episodeNum != null)
                        _buildTag(program.episodeNum!, const Color(0xFF8B5CF6)),
                    ],
                  ),
                // Description
                if (program.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    program.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onWatch();
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Watch Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onRecord();
                        },
                        icon: const Icon(Icons.fiber_manual_record, size: 16),
                        label: const Text('Record'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onRecordSeries();
                        },
                        icon: const Icon(Icons.repeat_rounded),
                        label: const Text('Record Series'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
