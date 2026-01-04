import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../models/livetv_channel.dart';
import '../providers/media_client_provider.dart';
import '../utils/app_logger.dart';
import 'livetv_player_screen.dart';

/// EPG view modes
enum EPGViewMode { grid, nowNext, mapping }

/// Genre colors for program blocks - more vibrant palette
class EPGGenreColors {
  static Color getColor(String? category) {
    if (category == null || category.isEmpty) return const Color(0xFF374151);
    final g = category.toLowerCase();
    if (g.contains('sport')) return const Color(0xFF10B981); // Emerald
    if (g.contains('news')) return const Color(0xFF3B82F6); // Blue
    if (g.contains('movie') || g.contains('film')) return const Color(0xFF8B5CF6); // Violet
    if (g.contains('series') || g.contains('drama')) return const Color(0xFFF97316); // Orange
    if (g.contains('entertainment')) return const Color(0xFFEC4899); // Pink
    if (g.contains('documentary') || g.contains('doc')) return const Color(0xFF14B8A6); // Teal
    if (g.contains('kids') || g.contains('children')) return const Color(0xFFF472B6); // Pink
    if (g.contains('music')) return const Color(0xFFEF4444); // Red
    if (g.contains('comedy')) return const Color(0xFFFBBF24); // Amber
    return const Color(0xFF6366F1); // Indigo default
  }

  static Color getColorLight(String? category) {
    return getColor(category).withValues(alpha: 0.3);
  }
}

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
  final ScrollController _sidebarScrollController = ScrollController();
  Timer? _timeUpdateTimer;
  Timer? _autoRefreshTimer;

  // Grid configuration - adaptive based on screen size
  // These are now calculated in _getAdaptiveDimensions() based on screen width
  static const int hoursToShow = 6;

  // Cached adaptive dimensions (set in build method)
  late double _sidebarWidth;
  late double _channelColumnWidth;
  late double _timeSlotWidth;
  late double _channelRowHeight;
  late double _timeHeaderHeight;
  late double _programDetailHeight;

  /// Calculate adaptive dimensions based on screen size
  void _calculateAdaptiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Base scale factor - 1.0 at 1920px, scale down/up for other sizes
    final widthScale = (screenWidth / 1920.0).clamp(0.6, 1.5);
    final heightScale = (screenHeight / 1080.0).clamp(0.6, 1.5);

    _sidebarWidth = (220.0 * widthScale).clamp(160.0, 280.0);
    _channelColumnWidth = (180.0 * widthScale).clamp(120.0, 220.0);
    _timeSlotWidth = (150.0 * widthScale).clamp(100.0, 200.0);
    _channelRowHeight = (72.0 * heightScale).clamp(56.0, 90.0);
    _timeHeaderHeight = (50.0 * heightScale).clamp(40.0, 60.0);
    _programDetailHeight = (180.0 * heightScale).clamp(120.0, 220.0);
  }

  // Getters that use the old static-like names for compatibility
  double get sidebarWidth => _sidebarWidth;
  double get channelColumnWidth => _channelColumnWidth;
  double get timeSlotWidth => _timeSlotWidth;
  double get channelRowHeight => _channelRowHeight;
  double get timeHeaderHeight => _timeHeaderHeight;
  double get programDetailHeight => _programDetailHeight;

  // TV navigation state
  int _focusedChannelIndex = 0;
  int _focusedProgramIndex = 0;
  late FocusNode _gridFocusNode;

  // Filter state
  EPGViewMode _viewMode = EPGViewMode.grid;
  String _selectedCategory = 'All';
  bool _showFavoritesOnly = false;
  List<String> _categories = ['All'];

  // Sidebar state
  bool _sidebarExpanded = true;
  String? _expandedGroup;

  @override
  void initState() {
    super.initState();
    _gridFocusNode = FocusNode(debugLabel: 'EPGGrid');
    _loadGuideData();

    // Update current time every minute
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });

    // Auto-refresh guide data every 30 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _loadGuideData();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
      _gridFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timeUpdateTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _sidebarScrollController.dispose();
    _gridFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_guideData == null) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final channels = _filteredChannels;
    if (channels.isEmpty) return KeyEventResult.ignored;

    final currentChannel = channels[_focusedChannelIndex];
    final programs = _guideData!.programs[currentChannel.channelId] ?? [];
    final programCount = programs.isNotEmpty ? programs.length : 1;

    if (key == LogicalKeyboardKey.arrowUp && _focusedChannelIndex > 0) {
      setState(() {
        _focusedChannelIndex--;
        _focusedProgramIndex = 0;
      });
      _scrollToFocusedChannel();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown && _focusedChannelIndex < channels.length - 1) {
      setState(() {
        _focusedChannelIndex++;
        _focusedProgramIndex = 0;
      });
      _scrollToFocusedChannel();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft && _focusedProgramIndex > 0) {
      setState(() => _focusedProgramIndex--);
      _scrollToFocusedProgram();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight && _focusedProgramIndex < programCount - 1) {
      setState(() => _focusedProgramIndex++);
      _scrollToFocusedProgram();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA) {
      _playChannel(channels[_focusedChannelIndex]);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyN) {
      _scrollToCurrentTime();
      return KeyEventResult.handled;
    }

    // Toggle sidebar with Tab or gamepad Y
    if (key == LogicalKeyboardKey.tab || key == LogicalKeyboardKey.gameButtonY) {
      setState(() => _sidebarExpanded = !_sidebarExpanded);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _scrollToFocusedChannel() {
    final offset = _focusedChannelIndex * channelRowHeight;
    final viewportHeight = MediaQuery.of(context).size.height - timeHeaderHeight - programDetailHeight - 100;
    final targetOffset = offset - (viewportHeight / 2) + (channelRowHeight / 2);

    _verticalScrollController.animateTo(
      targetOffset.clamp(0.0, _verticalScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToFocusedProgram() {
    if (_guideData == null) return;
    final channels = _filteredChannels;
    if (_focusedChannelIndex >= channels.length) return;

    final currentChannel = channels[_focusedChannelIndex];
    final programs = _guideData!.programs[currentChannel.channelId] ?? [];
    if (_focusedProgramIndex >= programs.length) return;

    final program = programs[_focusedProgramIndex];
    final start = _guideData!.startTime;
    final pixelsPerMinute = timeSlotWidth / 30;
    final minutesFromStart = program.start.difference(start).inMinutes;
    final offset = minutesFromStart * pixelsPerMinute;

    _horizontalScrollController.animateTo(
      offset.clamp(0.0, _horizontalScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadGuideData() async {
    final client = context.read<MediaClientProvider>().client;
    if (client == null) return;

    setState(() => _isLoading = true);

    try {
      final start = DateTime.now().subtract(const Duration(hours: 1));
      final end = start.add(Duration(hours: hoursToShow + 1));

      final data = await client.getLiveTVGuide(start: start, end: end);

      if (mounted && data != null) {
        final categorySet = <String>{'All'};
        for (final channel in data.channels) {
          if (channel.group != null && channel.group!.isNotEmpty) {
            categorySet.add(channel.group!);
          }
        }

        setState(() {
          _guideData = data;
          _categories = categorySet.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      appLogger.e('Failed to load EPG guide', error: e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LiveTVChannel> get _filteredChannels {
    if (_guideData == null) return [];
    var channels = _guideData!.channels;

    if (_showFavoritesOnly) {
      channels = channels.where((c) => c.isFavorite).toList();
    }

    if (_selectedCategory != 'All') {
      channels = channels.where((c) => c.group == _selectedCategory).toList();
    }

    return channels;
  }

  LiveTVProgram? get _focusedProgram {
    if (_guideData == null) return null;
    final channels = _filteredChannels;
    if (_focusedChannelIndex >= channels.length) return null;
    final channel = channels[_focusedChannelIndex];
    final programs = _guideData!.programs[channel.channelId] ?? [];
    if (_focusedProgramIndex >= programs.length) return null;
    return programs[_focusedProgramIndex];
  }

  LiveTVChannel? get _focusedChannel {
    final channels = _filteredChannels;
    if (_focusedChannelIndex >= channels.length) return null;
    return channels[_focusedChannelIndex];
  }

  void _scrollToCurrentTime() {
    if (_guideData == null) return;

    final now = DateTime.now();
    final start = _guideData!.startTime;
    final minutesSinceStart = now.difference(start).inMinutes;
    final pixelsPerMinute = timeSlotWidth / 30;
    final scrollOffset = minutesSinceStart * pixelsPerMinute - 200;

    if (scrollOffset > 0) {
      _horizontalScrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
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
    // Calculate adaptive dimensions based on screen size
    _calculateAdaptiveDimensions(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _gridFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _guideData == null || _guideData!.channels.isEmpty
                ? _buildEmptyState()
                : _buildMainContent(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.tv_off, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(t.epg.noPrograms, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          const SizedBox(height: 8),
          Text(t.liveTV.addM3USource, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      children: [
        // Left sidebar
        if (_sidebarExpanded) _buildSidebar(),
        // Main content
        Expanded(
          child: Column(
            children: [
              // Program details panel at top
              _buildProgramDetailsPanel(),
              // Grid, Now/Next, or Mapping view
              Expanded(
                child: _viewMode == EPGViewMode.grid
                    ? _buildGridView()
                    : _viewMode == EPGViewMode.nowNext
                        ? _buildNowNextView()
                        : _buildMappingView(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F2937),
            const Color(0xFF111827),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with logo/title
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.live_tv_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Guide',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Navigation items
          Expanded(
            child: ListView(
              controller: _sidebarScrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                // Search
                _buildSidebarItem(Icons.search_rounded, t.screens.search, onTap: () {}),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // All Channels
                _buildSidebarItem(
                  Icons.tv_rounded,
                  t.liveTV.allChannels,
                  selected: _selectedCategory == 'All' && !_showFavoritesOnly,
                  accentColor: const Color(0xFF3B82F6),
                  onTap: () => setState(() {
                    _selectedCategory = 'All';
                    _showFavoritesOnly = false;
                    _focusedChannelIndex = 0;
                  }),
                ),
                // Favorites
                _buildSidebarItem(
                  Icons.star_rounded,
                  t.liveTV.favorites,
                  selected: _showFavoritesOnly,
                  accentColor: Colors.amber,
                  onTap: () => setState(() {
                    _showFavoritesOnly = !_showFavoritesOnly;
                    _focusedChannelIndex = 0;
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Groups/Categories
                ..._categories.where((c) => c != 'All').map((category) {
                  final isExpanded = _expandedGroup == category;
                  final isSelected = _selectedCategory == category && !_showFavoritesOnly;
                  return _buildSidebarItem(
                    isExpanded ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
                    category,
                    selected: isSelected,
                    accentColor: _getCategoryColor(category),
                    onTap: () => setState(() {
                      _selectedCategory = category;
                      _showFavoritesOnly = false;
                      _focusedChannelIndex = 0;
                      _expandedGroup = isExpanded ? null : category;
                    }),
                  );
                }),
              ],
            ),
          ),
          // Bottom actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1F2937).withValues(alpha: 0.8),
                  const Color(0xFF111827),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomAction(
                      Icons.grid_view_rounded,
                      'Grid',
                      () => setState(() => _viewMode = EPGViewMode.grid),
                      isActive: _viewMode == EPGViewMode.grid,
                      activeColor: const Color(0xFF3B82F6),
                    ),
                    _buildBottomAction(
                      Icons.view_list_rounded,
                      'List',
                      () => setState(() => _viewMode = EPGViewMode.nowNext),
                      isActive: _viewMode == EPGViewMode.nowNext,
                      activeColor: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomAction(
                      Icons.link_rounded,
                      'Mapping',
                      () => setState(() => _viewMode = EPGViewMode.mapping),
                      isActive: _viewMode == EPGViewMode.mapping,
                      activeColor: const Color(0xFF10B981),
                    ),
                    _buildBottomAction(
                      Icons.schedule_rounded,
                      'Now',
                      _scrollToCurrentTime,
                      activeColor: const Color(0xFFF97316),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomAction(
                      Icons.refresh_rounded,
                      'Refresh',
                      _loadGuideData,
                      activeColor: const Color(0xFF14B8A6),
                    ),
                    _buildBottomAction(
                      Icons.auto_fix_high_rounded,
                      'Auto',
                      _autoDetectChannels,
                      activeColor: const Color(0xFFEC4899),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFF97316), // Orange
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFEF4444), // Red
      const Color(0xFF6366F1), // Indigo
    ];
    return colors[category.hashCode.abs() % colors.length];
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap, {bool isActive = false, Color? activeColor}) {
    final color = activeColor ?? const Color(0xFF3B82F6);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.4),
                          color.withValues(alpha: 0.2),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.15),
                          color.withValues(alpha: 0.05),
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? color.withValues(alpha: 0.5) : color.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isActive ? 0.3 : 0.1),
                    blurRadius: isActive ? 12 : 6,
                    spreadRadius: isActive ? 1 : -2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive ? color : color.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? color : Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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

  Widget _buildSidebarItem(IconData icon, String label, {bool selected = false, Color? accentColor, VoidCallback? onTap}) {
    final color = accentColor ?? const Color(0xFF3B82F6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(color: color.withValues(alpha: 0.5), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? color : Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramDetailsPanel() {
    final program = _focusedProgram;
    final channel = _focusedChannel;
    final categoryColor = EPGGenreColors.getColor(program?.category);

    return Container(
      height: programDetailHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            categoryColor.withValues(alpha: 0.2),
            const Color(0xFF111827),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Program thumbnail/channel logo
          Container(
            width: 220,
            height: programDetailHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  categoryColor.withValues(alpha: 0.4),
                  categoryColor.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (program?.icon != null)
                  Image.network(
                    program!.icon!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildChannelPreview(channel, categoryColor),
                  )
                else
                  _buildChannelPreview(channel, categoryColor),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF111827).withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Program info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: program == null
                  ? _buildNoProgram()
                  : _buildProgramInfo(program, channel, categoryColor),
            ),
          ),
          // Current time and date
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    DateFormat('EEE, MMM d').format(DateTime.now()),
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('h:mm a').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                // Favorite button
                if (channel != null)
                  Container(
                    decoration: BoxDecoration(
                      color: channel.isFavorite
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: channel.isFavorite
                          ? [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: IconButton(
                      icon: Icon(
                        channel.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: channel.isFavorite ? Colors.amber : Colors.white.withValues(alpha: 0.5),
                      ),
                      onPressed: () {
                        // TODO: Toggle favorite
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelPreview(LiveTVChannel? channel, Color accentColor) {
    if (channel == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor.withValues(alpha: 0.3), accentColor.withValues(alpha: 0.1)],
          ),
        ),
      );
    }
    return Center(
      child: channel.logo != null
          ? Container(
              padding: const EdgeInsets.all(20),
              child: Image.network(
                channel.logo!,
                fit: BoxFit.contain,
                width: 100,
                errorBuilder: (_, __, ___) => _buildChannelNumber(channel),
              ),
            )
          : _buildChannelNumber(channel),
    );
  }

  Widget _buildChannelNumber(LiveTVChannel channel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${channel.number}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNoProgram() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tv_off_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No program information',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'EPG data not available for this channel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramInfo(LiveTVProgram program, LiveTVChannel? channel, Color categoryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          program.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // Time and duration with progress
        Row(
          children: [
            Icon(Icons.schedule_rounded, color: Colors.white.withValues(alpha: 0.5), size: 16),
            const SizedBox(width: 6),
            Text(
              '${DateFormat('h:mm').format(program.start)} - ${DateFormat('h:mm a').format(program.end)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: program.progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [categoryColor, categoryColor.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${program.durationMinutes} min',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Channel and category badges
        Row(
          children: [
            if (channel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${channel.number}',
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      channel.name,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 10),
            if (program.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  program.category!.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            if (program.isLive) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(8),
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
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        // Description
        if (program.description != null && program.description!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              program.description!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGridView() {
    final channels = _filteredChannels;
    if (channels.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tv_off_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text(
                t.liveTV.noChannelsMatchFilter,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final start = _guideData!.startTime;
    final end = _guideData!.endTime;
    final totalMinutes = end.difference(start).inMinutes;
    final timeSlots = (totalMinutes / 30).ceil();
    final totalWidth = timeSlots * timeSlotWidth;

    return Column(
      children: [
        // Time header with current time indicator
        _buildTimeHeader(timeSlots, start, totalWidth),
        // Channel rows with programs
        Expanded(
          child: Row(
            children: [
              // Fixed channel column
              SizedBox(
                width: channelColumnWidth,
                child: ListView.builder(
                  controller: _verticalScrollController,
                  itemCount: channels.length,
                  itemBuilder: (context, index) => _buildChannelCell(channels[index], index),
                ),
              ),
              // Scrollable program grid
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth,
                    child: Stack(
                      children: [
                        // Background grid lines
                        _buildGridLines(timeSlots, channels.length),
                        // Program rows
                        ListView.builder(
                          controller: _verticalScrollController,
                          itemCount: channels.length,
                          itemBuilder: (context, index) => _buildProgramRow(channels[index], index, start),
                        ),
                        // Current time indicator line
                        _buildCurrentTimeIndicator(start),
                      ],
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

  Widget _buildGridLines(int timeSlots, int channelCount) {
    return CustomPaint(
      size: Size(timeSlots * timeSlotWidth, channelCount * channelRowHeight),
      painter: _GridLinesPainter(
        timeSlotWidth: timeSlotWidth,
        channelRowHeight: channelRowHeight,
        timeSlots: timeSlots,
        channelCount: channelCount,
      ),
    );
  }

  Widget _buildTimeHeader(int timeSlots, DateTime start, double totalWidth) {
    return Container(
      height: timeHeaderHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F2937),
            const Color(0xFF111827),
          ],
        ),
      ),
      child: Row(
        children: [
          // Corner cell
          Container(
            width: channelColumnWidth,
            height: timeHeaderHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ],
              ),
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  DateFormat('EEE, MMM d').format(DateTime.now()),
                  style: const TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          // Time slots
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalWidth,
                child: Stack(
                  children: [
                    Row(
                      children: List.generate(timeSlots, (index) {
                        final slotTime = start.add(Duration(minutes: index * 30));
                        final isHour = slotTime.minute == 0;
                        return Container(
                          width: timeSlotWidth,
                          height: timeHeaderHeight,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: isHour
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                DateFormat('h:mm a').format(slotTime),
                                style: TextStyle(
                                  color: isHour
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                  fontWeight: isHour ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    // Current time marker in header
                    _buildCurrentTimeMarker(start),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeMarker(DateTime start) {
    final now = DateTime.now();
    final minutesSinceStart = now.difference(start).inMinutes;
    if (minutesSinceStart < 0) return const SizedBox.shrink();

    final pixelsPerMinute = timeSlotWidth / 30;
    final leftOffset = minutesSinceStart * pixelsPerMinute;

    return Positioned(
      left: leftOffset - 6,
      top: 0,
      bottom: 0,
      child: Container(
        width: 12,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 2,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(DateTime start) {
    final now = DateTime.now();
    final minutesSinceStart = now.difference(start).inMinutes;
    if (minutesSinceStart < 0) return const SizedBox.shrink();

    final pixelsPerMinute = timeSlotWidth / 30;
    final leftOffset = minutesSinceStart * pixelsPerMinute;

    return Positioned(
      left: leftOffset,
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCell(LiveTVChannel channel, int index) {
    final isFocused = index == _focusedChannelIndex;
    final accentColor = _getCategoryColor(channel.group ?? channel.name);

    return GestureDetector(
      onTap: () {
        setState(() => _focusedChannelIndex = index);
        _playChannel(channel);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: channelRowHeight,
        decoration: BoxDecoration(
          gradient: isFocused
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isFocused ? null : const Color(0xFF111827),
          border: Border(
            right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            left: BorderSide(
              color: isFocused ? accentColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            // Channel number badge
            Container(
              width: 32,
              height: 24,
              decoration: BoxDecoration(
                color: isFocused ? accentColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${channel.number}',
                  style: TextStyle(
                    color: isFocused ? accentColor : Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Channel logo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: channel.logo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        channel.logo!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.tv_rounded, color: Colors.grey[400], size: 20),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.tv_rounded, color: Colors.grey[400], size: 20),
                    ),
            ),
            const SizedBox(width: 10),
            // Channel name
            Expanded(
              child: Text(
                channel.name,
                style: TextStyle(
                  color: isFocused ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramRow(LiveTVChannel channel, int channelIndex, DateTime start) {
    final programs = _guideData!.programs[channel.channelId] ?? [];
    final isFocusedChannel = channelIndex == _focusedChannelIndex;
    final pixelsPerMinute = timeSlotWidth / 30;
    final accentColor = _getCategoryColor(channel.group ?? channel.name);

    // Calculate total grid width
    final end = _guideData!.endTime;
    final totalMinutes = end.difference(start).inMinutes;
    final totalWidth = totalMinutes * pixelsPerMinute;

    return Container(
      height: channelRowHeight,
      decoration: BoxDecoration(
        gradient: isFocusedChannel
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  accentColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              )
            : null,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Stack(
        children: [
          // Show placeholder if no programs
          if (programs.isEmpty)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        accentColor.withValues(alpha: isFocusedChannel ? 0.2 : 0.08),
                        accentColor.withValues(alpha: isFocusedChannel ? 0.1 : 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFocusedChannel
                          ? accentColor.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No program data',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Program blocks
          ...programs.asMap().entries.map((entry) {
            final programIndex = entry.key;
            final program = entry.value;
            final minutesFromStart = program.start.difference(start).inMinutes;
            final durationMinutes = program.durationMinutes;
            final leftOffset = minutesFromStart * pixelsPerMinute;
            final width = durationMinutes * pixelsPerMinute;
            final isFocused = isFocusedChannel && programIndex == _focusedProgramIndex;

            return Positioned(
              left: leftOffset,
              top: 3,
              child: _buildProgramBlock(channel, program, width, isFocused, isFocusedChannel),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgramBlock(LiveTVChannel channel, LiveTVProgram program, double width, bool isFocused, bool isFocusedChannel) {
    final isLive = program.isLive;
    final categoryColor = EPGGenreColors.getColor(program.category);

    return GestureDetector(
      onTap: () => _playChannel(channel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width - 3,
        height: channelRowHeight - 6,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          gradient: isFocused
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [categoryColor, categoryColor.withValues(alpha: 0.8)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isFocusedChannel
                      ? [categoryColor.withValues(alpha: 0.6), categoryColor.withValues(alpha: 0.4)]
                      : [const Color(0xFF1F2937), const Color(0xFF111827)],
                ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocused
                ? Colors.white
                : isFocusedChannel
                    ? categoryColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
            width: isFocused ? 2 : 1,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Progress overlay for live programs
            if (isLive)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: (width - 3) * program.progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(8),
                      bottomLeft: const Radius.circular(8),
                      topRight: Radius.circular(program.progress > 0.95 ? 8 : 0),
                      bottomRight: Radius.circular(program.progress > 0.95 ? 8 : 0),
                    ),
                  ),
                ),
              ),
            // Program info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Time (small)
                  Text(
                    DateFormat('h:mm a').format(program.start),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Title
                  Text(
                    program.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: isFocused || isFocusedChannel ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Live indicator
            if (isLive)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                      SizedBox(width: 3),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Category indicator (left edge)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowNextView() {
    final channels = _filteredChannels;

    return ListView.builder(
      controller: _verticalScrollController,
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final programs = _guideData!.programs[channel.channelId] ?? [];
        final isFocused = index == _focusedChannelIndex;

        final now = DateTime.now();
        LiveTVProgram? currentProgram;
        LiveTVProgram? nextProgram;

        for (final program in programs) {
          if (program.start.isBefore(now) && program.end.isAfter(now)) {
            currentProgram = program;
          } else if (currentProgram != null && program.start.isAfter(now)) {
            nextProgram = program;
            break;
          }
        }

        return GestureDetector(
          onTap: () => _playChannel(channel),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isFocused ? Colors.indigo[800] : Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFocused ? Colors.indigo[400]! : Colors.grey[800]!,
                width: isFocused ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Channel number and logo
                  SizedBox(
                    width: 60,
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: channel.logo != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(channel.logo!, fit: BoxFit.contain),
                                )
                              : Center(
                                  child: Text(
                                    'TV',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${channel.number}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Channel name and programs
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          channel.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (currentProgram != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                child: Text(t.epg.now.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(currentProgram.title, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                        if (nextProgram != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(4)),
                                child: Text(DateFormat('h:mm').format(nextProgram.start), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(nextProgram.title, style: TextStyle(color: Colors.grey[400], fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (channel.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _autoDetectChannels() async {
    final client = context.read<MediaClientProvider>().client;
    if (client == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF10B981)),
            const SizedBox(width: 20),
            Text(
              'Auto-detecting EPG mappings...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );

    try {
      await client.autoDetectChannels();
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        await _loadGuideData(); // Reload with new mappings
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EPG auto-detection completed'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-detection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMappingView() {
    final channels = _filteredChannels;

    // Calculate mapping stats
    final mappedCount = channels.where((c) => c.hasMappedEpg).length;
    final unmappedCount = channels.length - mappedCount;
    final autoDetectedCount = channels.where((c) => c.autoDetected).length;

    return Column(
      children: [
        // Stats header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.2),
                const Color(0xFF3B82F6).withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Row(
            children: [
              _buildStatCard('Total', channels.length.toString(), const Color(0xFF6366F1)),
              const SizedBox(width: 12),
              _buildStatCard('Mapped', mappedCount.toString(), const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _buildStatCard('No EPG', unmappedCount.toString(), const Color(0xFFEF4444)),
              const SizedBox(width: 12),
              _buildStatCard('Auto', autoDetectedCount.toString(), const Color(0xFF8B5CF6)),
            ],
          ),
        ),
        // Channel list
        Expanded(
          child: ListView.builder(
            controller: _verticalScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              final hasProgramData = _guideData?.programs[channel.channelId]?.isNotEmpty ?? false;
              final isFocused = index == _focusedChannelIndex;

              return GestureDetector(
                onTap: () {
                  setState(() => _focusedChannelIndex = index);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: isFocused
                          ? [
                              const Color(0xFF10B981).withValues(alpha: 0.3),
                              const Color(0xFF10B981).withValues(alpha: 0.1),
                            ]
                          : [
                              const Color(0xFF1F2937),
                              const Color(0xFF111827),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0xFF10B981)
                          : Colors.white.withValues(alpha: 0.1),
                      width: isFocused ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Channel number
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${channel.number ?? '-'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Channel logo
                        Container(
                          width: 50,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: channel.logo != null
                              ? Image.network(
                                  channel.logo!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.tv,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                )
                              : const Icon(Icons.tv, color: Colors.grey, size: 20),
                        ),
                        const SizedBox(width: 12),
                        // Channel info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                channel.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (channel.tvgId != null && channel.tvgId!.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'TVG: ${channel.tvgId}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (channel.epgCallSign != null && channel.epgCallSign!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        channel.epgCallSign!,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Mapping status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: hasProgramData
                                    ? const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          const Color(0xFFEF4444).withValues(alpha: 0.8),
                                          const Color(0xFFDC2626).withValues(alpha: 0.8),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasProgramData ? Icons.check_circle : Icons.warning_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hasProgramData ? 'EPG OK' : 'No EPG',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (channel.autoDetected && channel.matchConfidence > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${(channel.matchConfidence * 100).toInt()}% match',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for EPG grid lines
class _GridLinesPainter extends CustomPainter {
  final double timeSlotWidth;
  final double channelRowHeight;
  final int timeSlots;
  final int channelCount;

  _GridLinesPainter({
    required this.timeSlotWidth,
    required this.channelRowHeight,
    required this.timeSlots,
    required this.channelCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    final hourPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    // Draw vertical lines (time slot boundaries)
    for (int i = 0; i <= timeSlots; i++) {
      final x = i * timeSlotWidth;
      final isHour = i % 2 == 0; // Every 2 slots = 1 hour
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isHour ? hourPaint : paint,
      );
    }

    // Draw horizontal lines (channel boundaries)
    for (int i = 0; i <= channelCount; i++) {
      final y = i * channelRowHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridLinesPainter oldDelegate) {
    return oldDelegate.timeSlots != timeSlots ||
        oldDelegate.channelCount != channelCount;
  }
}
