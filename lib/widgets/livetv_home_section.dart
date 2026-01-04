import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/livetv_channel.dart';
import '../screens/epg_guide_screen.dart';
import '../screens/livetv_player_screen.dart';
import '../i18n/strings.g.dart';
import 'content_badge.dart';
import 'focus/focus_indicator.dart';
import 'hub_navigation_controller.dart';
import 'horizontal_scroll_with_arrows.dart';

/// A home screen section showing "What's On Now" for Live TV
/// Includes a Channel Guide card and currently playing channel cards
class LiveTVHomeSection extends StatefulWidget {
  final List<LiveTVChannel> channels;
  final VoidCallback? onNavigateToLiveTV;
  final int navigationOrder;

  const LiveTVHomeSection({
    super.key,
    required this.channels,
    this.onNavigateToLiveTV,
    this.navigationOrder = 50,
  });

  @override
  State<LiveTVHomeSection> createState() => _LiveTVHomeSectionState();
}

class _LiveTVHomeSectionState extends State<LiveTVHomeSection> {
  late final FocusNode _headerFocusNode;
  bool _headerIsFocused = false;
  HubNavigationController? _controller;
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;

  static const String _hubId = 'livetv_whats_on_now';

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode();
    _headerFocusNode.addListener(_handleHeaderFocusChange);
    _createItemFocusNodes();
  }

  void _createItemFocusNodes() {
    // +1 for the Channel Guide card
    _itemFocusNodes = List.generate(
      widget.channels.length + 1,
      (index) => FocusNode(debugLabel: 'LiveTVItem_$index'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerWithController();
  }

  @override
  void didUpdateWidget(LiveTVHomeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channels.length != oldWidget.channels.length) {
      _disposeItemFocusNodes();
      _createItemFocusNodes();
    }
    _registerWithController();
  }

  void _registerWithController() {
    final controller = HubNavigationScope.maybeOf(context);
    if (controller != _controller) {
      _unregisterFromController();
      _controller = controller;
    }

    if (controller == null) return;

    if (_registeredHubId == null) {
      controller.register(
        HubSectionRegistration(
          hubId: _hubId,
          itemCount: widget.channels.length + 1,
          focusItem: _focusItem,
          order: widget.navigationOrder,
        ),
      );
      _registeredHubId = _hubId;
    }
  }

  void _unregisterFromController() {
    if (_controller != null && _registeredHubId != null) {
      _controller!.unregister(_registeredHubId!);
    }
    _registeredHubId = null;
  }

  void _focusItem(int index) {
    if (index >= 0 && index < _itemFocusNodes.length) {
      _itemFocusNodes[index].requestFocus();
    }
  }

  void _disposeItemFocusNodes() {
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    _itemFocusNodes = [];
  }

  @override
  void dispose() {
    _unregisterFromController();
    _headerFocusNode.removeListener(_handleHeaderFocusChange);
    _headerFocusNode.dispose();
    _disposeItemFocusNodes();
    super.dispose();
  }

  void _handleHeaderFocusChange() {
    if (_headerIsFocused != _headerFocusNode.hasFocus) {
      setState(() {
        _headerIsFocused = _headerFocusNode.hasFocus;
      });
    }
  }

  void _navigateToLiveTV() {
    widget.onNavigateToLiveTV?.call();
  }

  void _navigateToEPG() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EPGGuideScreen()),
    );
  }

  void _playChannel(LiveTVChannel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTVPlayerScreen(
          channel: channel,
          channels: widget.channels,
        ),
      ),
    );
  }

  KeyEventResult _handleHeaderKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        _navigateToLiveTV();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.fromLTRB(16, isTV ? 28 : 24, 16, isTV ? 12 : 8),
            child: Focus(
              focusNode: _headerFocusNode,
              onKeyEvent: _handleHeaderKeyEvent,
              child: FocusIndicator(
                isFocused: _headerIsFocused,
                borderRadius: 8,
                child: InkWell(
                  onTap: _navigateToLiveTV,
                  borderRadius: BorderRadius.circular(8),
                  focusColor: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTV ? 12 : 8,
                      vertical: isTV ? 8 : 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.live_tv, size: isTV ? 28 : 24),
                        SizedBox(width: isTV ? 12 : 8),
                        Text(
                          t.discover.whatsOnNow,
                          style: isTV
                              ? theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )
                              : theme.textTheme.titleLarge,
                        ),
                        SizedBox(width: isTV ? 8 : 4),
                        Icon(Icons.chevron_right, size: isTV ? 28 : 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Horizontal scroll with Channel Guide card + channel cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = isTV ? 280.0 : 240.0;
              final cardHeight = isTV ? 160.0 : 140.0;

              return SizedBox(
                height: cardHeight + 20, // Extra for focus indicator
                child: ClipRect(
                  clipBehavior: Clip.none,
                  child: HorizontalScrollWithArrows(
                    builder: (scrollController) => FocusTraversalGroup(
                      child: ListView.builder(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        itemCount: widget.channels.length + 1, // +1 for guide card
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Channel Guide card
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _ChannelGuideCard(
                                width: cardWidth,
                                height: cardHeight,
                                focusNode: _itemFocusNodes.isNotEmpty
                                    ? _itemFocusNodes[0]
                                    : null,
                                onTap: _navigateToEPG,
                              ),
                            );
                          }

                          final channel = widget.channels[index - 1];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _LiveChannelCard(
                              channel: channel,
                              width: cardWidth,
                              height: cardHeight,
                              focusNode: _itemFocusNodes.length > index
                                  ? _itemFocusNodes[index]
                                  : null,
                              onTap: () => _playChannel(channel),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Channel Guide quick-access card
class _ChannelGuideCard extends StatefulWidget {
  final double width;
  final double height;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const _ChannelGuideCard({
    required this.width,
    required this.height,
    this.focusNode,
    this.onTap,
  });

  @override
  State<_ChannelGuideCard> createState() => _ChannelGuideCardState();
}

class _ChannelGuideCardState extends State<_ChannelGuideCard> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        widget.onTap?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: FocusIndicator(
        isFocused: _isFocused,
        borderRadius: 16,
        child: AnimatedScale(
          scale: _isFocused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6366F1), // Indigo
                    const Color(0xFF8B5CF6), // Purple
                    const Color(0xFFA855F7), // Violet
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: _isFocused ? 0.5 : 0.3),
                    blurRadius: _isFocused ? 24 : 16,
                    offset: const Offset(0, 8),
                    spreadRadius: _isFocused ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Grid pattern background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridPatternPainter(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.discover.channelGuide,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View all channels',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
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
    );
  }
}

/// Custom painter for grid pattern background
class _GridPatternPainter extends CustomPainter {
  final Color color;

  _GridPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const spacing = 24.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Live channel card showing current program
class _LiveChannelCard extends StatefulWidget {
  final LiveTVChannel channel;
  final double width;
  final double height;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  const _LiveChannelCard({
    required this.channel,
    required this.width,
    required this.height,
    this.focusNode,
    this.onTap,
  });

  @override
  State<_LiveChannelCard> createState() => _LiveChannelCardState();
}

class _LiveChannelCardState extends State<_LiveChannelCard> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        widget.onTap?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  String _formatTimeRemaining(LiveTVProgram program) {
    final remaining = program.end.difference(DateTime.now()).inMinutes;
    return t.discover.minutesLeft(minutes: remaining.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channel = widget.channel;
    final nowPlaying = channel.nowPlaying;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isFocused ? 0.5 : 0.3),
                  blurRadius: _isFocused ? 20 : 12,
                  offset: const Offset(0, 6),
                  spreadRadius: _isFocused ? 2 : 0,
                ),
                if (_isFocused)
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
              ],
              border: Border.all(
                color: _isFocused
                    ? theme.colorScheme.primary
                    : Colors.white.withValues(alpha: 0.1),
                width: _isFocused ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Background image (channel logo or program icon)
                if (nowPlaying?.icon != null || channel.logo != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: nowPlaying?.icon ?? channel.logo!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  )
                else
                  // Placeholder background when no image
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.surfaceContainerHighest,
                            theme.colorScheme.surfaceContainerHigh,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.live_tv_rounded,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),

                // Enhanced gradient overlay with multiple stops
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.3, 0.6, 1.0],
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),

                // LIVE badge with glow
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const LiveBadge(),
                  ),
                ),

                // Channel number badge
                if (channel.number != null)
                  Positioned(
                    top: 40,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${channel.number}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                // Channel logo (small) with shadow
                if (channel.logo != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: CachedNetworkImage(
                        imageUrl: channel.logo!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),

                // Content at bottom
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Channel name with icon
                      Row(
                        children: [
                          Icon(
                            Icons.tv_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              channel.name,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Program title or placeholder
                      if (nowPlaying != null)
                        Text(
                          nowPlaying.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        // Improved "No program info" placeholder
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t.discover.noEpgData,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (nowPlaying != null) ...[
                        const SizedBox(height: 8),

                        // Progress bar with glow effect
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: nowPlaying.progress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Time remaining with icon
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeRemaining(nowPlaying),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
