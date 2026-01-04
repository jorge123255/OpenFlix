import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/catchup_service.dart';
import '../client/media_client.dart';
import '../models/livetv_channel.dart';
import '../i18n/strings.g.dart';

/// Screen showing all catchup recordings organized by channel
class CatchupScreen extends StatefulWidget {
  final VoidCallback? onBackToNav;

  const CatchupScreen({super.key, this.onBackToNav});

  @override
  State<CatchupScreen> createState() => _CatchupScreenState();
}

class _CatchupScreenState extends State<CatchupScreen> {
  final CatchUpService _catchupService = CatchUpService.instance;

  List<LiveTVChannel> _channels = [];
  Map<int, List<CatchUpProgram>> _programsByChannel = {};
  int? _selectedChannelId;
  bool _isLoading = true;
  String? _error;

  // Accent colors for visual variety
  static const _accentColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFFEF4444), // Red
  ];

  Color _getChannelColor(String name) {
    return _accentColors[name.hashCode.abs() % _accentColors.length];
  }

  @override
  void initState() {
    super.initState();
    // Schedule the load after the first frame when context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load channels from MediaClient
      final client = context.read<MediaClient>();
      final channels = await client.getLiveTVWhatsOnNow();

      if (mounted) {
        setState(() {
          _channels = channels;
          _isLoading = false;
          if (channels.isNotEmpty && _selectedChannelId == null) {
            _selectedChannelId = channels.first.id;
            _loadChannelPrograms(channels.first.id);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load channels';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadChannelPrograms(int channelId) async {
    if (_programsByChannel.containsKey(channelId)) return;

    try {
      final programs = await _catchupService.getCatchUpPrograms(channelId);
      if (mounted) {
        setState(() {
          _programsByChannel[channelId] = programs;
        });
      }
    } catch (e) {
      debugPrint('Failed to load programs for channel $channelId: $e');
    }
  }

  void _selectChannel(int channelId) {
    setState(() {
      _selectedChannelId = channelId;
    });
    _loadChannelPrograms(channelId);
  }

  Future<void> _playProgram(CatchUpProgram program) async {
    try {
      final offsetSeconds = DateTime.now().difference(program.startTime).inSeconds;
      final url = await _catchupService.getTimeShiftUrl(program.channelId, offsetSeconds);

      if (url != null && mounted) {
        // Navigate to player with timeshift URL
        Navigator.of(context).pushNamed(
          '/livetv/player',
          arguments: {
            'channelId': program.channelId,
            'timeshiftUrl': url,
            'programTitle': program.title,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play: $e')),
        );
      }
    }
  }

  void _deleteProgram(CatchUpProgram program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        title: const Text('Delete Recording?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${program.title}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete API call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recording deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          // Check if we should go back to nav
          widget.onBackToNav?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF111827),
        body: Row(
          children: [
            // Channel sidebar
            _buildChannelSidebar(),
            // Main content
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
        ),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.replay_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Catchup TV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Watch previously aired programs',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Channel list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.grey[600], size: 48),
                            const SizedBox(height: 16),
                            Text(_error!, style: TextStyle(color: Colors.grey[400])),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _channels.length,
                        itemBuilder: (context, index) {
                          final channel = _channels[index];
                          final isSelected = channel.id == _selectedChannelId;
                          final accentColor = _getChannelColor(channel.name);
                          final programCount = _programsByChannel[channel.id]?.length ?? 0;

                          return _ChannelListItem(
                            channel: channel,
                            isSelected: isSelected,
                            accentColor: accentColor,
                            programCount: programCount,
                            onTap: () => _selectChannel(channel.id),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedChannelId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off_rounded, color: Colors.grey[600], size: 64),
            const SizedBox(height: 16),
            Text(
              'Select a channel to view recordings',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final programs = _programsByChannel[_selectedChannelId] ?? [];
    final selectedChannel = _channels.firstWhere(
      (c) => c.id == _selectedChannelId,
      orElse: () => _channels.first,
    );
    final accentColor = _getChannelColor(selectedChannel.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Channel header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // Channel number badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  '${selectedChannel.number ?? "#"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedChannel.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${programs.length} recordings available',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: () {
                  _programsByChannel.remove(_selectedChannelId);
                  _loadChannelPrograms(_selectedChannelId!);
                },
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        // Divider
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        // Programs grid
        Expanded(
          child: programs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, color: Colors.grey[600], size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No catchup recordings',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Programs will appear here as they air',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return _ProgramCard(
                      program: program,
                      accentColor: accentColor,
                      onPlay: () => _playProgram(program),
                      onDelete: () => _deleteProgram(program),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ChannelListItem extends StatefulWidget {
  final LiveTVChannel channel;
  final bool isSelected;
  final Color accentColor;
  final int programCount;
  final VoidCallback onTap;

  const _ChannelListItem({
    required this.channel,
    required this.isSelected,
    required this.accentColor,
    required this.programCount,
    required this.onTap,
  });

  @override
  State<_ChannelListItem> createState() => _ChannelListItemState();
}

class _ChannelListItemState extends State<_ChannelListItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isFocused || widget.isSelected;

    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isHighlighted
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      widget.accentColor.withValues(alpha: _isFocused ? 0.35 : 0.25),
                      widget.accentColor.withValues(alpha: _isFocused ? 0.15 : 0.08),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? widget.accentColor.withValues(alpha: _isFocused ? 0.6 : 0.4)
                  : Colors.transparent,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Channel number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: isHighlighted
                      ? LinearGradient(
                          colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.7)],
                        )
                      : null,
                  color: isHighlighted ? null : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${widget.channel.number ?? "#"}',
                    style: TextStyle(
                      color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Channel info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.channel.name,
                      style: TextStyle(
                        color: isHighlighted ? Colors.white : Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.programCount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${widget.programCount} recordings',
                        style: TextStyle(
                          color: widget.accentColor.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow
              if (isHighlighted)
                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.accentColor,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgramCard extends StatefulWidget {
  final CatchUpProgram program;
  final Color accentColor;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _ProgramCard({
    required this.program,
    required this.accentColor,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            widget.onPlay();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            widget.onDelete();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isFocused
                  ? [widget.accentColor.withValues(alpha: 0.3), widget.accentColor.withValues(alpha: 0.15)]
                  : [const Color(0xFF1F2937), const Color(0xFF111827)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused
                  ? widget.accentColor.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.program.title,
                      style: TextStyle(
                        color: _isFocused ? Colors.white : Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Time info
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: widget.accentColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.program.timeRange,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Duration
                    Row(
                      children: [
                        Icon(
                          Icons.timelapse_rounded,
                          size: 14,
                          color: widget.accentColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.program.formattedDuration,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        // Availability badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.program.available
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.program.available ? 'Available' : 'Expired',
                            style: TextStyle(
                              color: widget.program.available ? Colors.green : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play button overlay when focused
              if (_isFocused && widget.program.available)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                  ),
                ),
              // Delete button
              if (_isFocused)
                Positioned(
                  top: 12,
                  right: widget.program.available ? 52 : 12,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
