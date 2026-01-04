import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../client/media_client.dart';
import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../screens/media_detail_screen.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart' show navigateToVideoPlayer;
import '../i18n/strings.g.dart';
import 'hub_navigation_controller.dart';
import 'focus/focus_indicator.dart';

/// Enhanced Continue Watching section with swipe-to-remove and better progress display
class ContinueWatchingSection extends StatefulWidget {
  final List<MediaItem> items;
  final void Function(String)? onRefresh;
  final VoidCallback? onRemoveItem;
  final int navigationOrder;

  const ContinueWatchingSection({
    super.key,
    required this.items,
    this.onRefresh,
    this.onRemoveItem,
    this.navigationOrder = 1000,
  });

  @override
  State<ContinueWatchingSection> createState() => _ContinueWatchingSectionState();
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection> {
  late final FocusNode _headerFocusNode;
  HubNavigationController? _controller;
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;

  static const String _hubId = 'continue_watching';

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode();
    _createItemFocusNodes();
  }

  void _createItemFocusNodes() {
    _itemFocusNodes = List.generate(
      widget.items.length,
      (index) => FocusNode(debugLabel: 'ContinueWatch_$index'),
    );
  }

  @override
  void didUpdateWidget(ContinueWatchingSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      // Dispose old nodes
      for (final node in _itemFocusNodes) {
        node.dispose();
      }
      _createItemFocusNodes();
      _registerWithController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerWithController();
  }

  void _registerWithController() {
    final controller = HubNavigationScope.maybeOf(context);
    if (controller != _controller) {
      _unregisterFromController();
      _controller = controller;
    }
    if (controller == null) return;

    if (_registeredHubId != _hubId) {
      _unregisterFromController();
      controller.register(
        HubSectionRegistration(
          hubId: _hubId,
          itemCount: widget.items.length,
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
    if (index < 0 || index >= _itemFocusNodes.length) return;
    _itemFocusNodes[index].requestFocus();
  }

  @override
  void dispose() {
    _unregisterFromController();
    _headerFocusNode.dispose();
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _removeFromContinueWatching(MediaItem item) async {
    try {
      final client = _getClientForItem(context, item);

      // Use the removeFromOnDeck method to hide from Continue Watching
      await client.removeFromOnDeck(item.ratingKey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.messages.removedFromContinueWatching),
          ),
        );
        widget.onRemoveItem?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.errors.failedToRemove(error: e.toString()))),
        );
      }
    }
  }

  MediaClient _getClientForItem(BuildContext context, MediaItem item) {
    final serverId = item.serverId;
    if (serverId == null) {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );
      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }
      return context.getClientForServer(multiServerProvider.onlineServerIds.first);
    }
    return context.getClientForServer(serverId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    return FocusTraversalGroup(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isTV ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTV ? 24 : 16,
                0,
                isTV ? 24 : 16,
                isTV ? 12 : 8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: theme.colorScheme.primary,
                    size: isTV ? 28 : 24,
                  ),
                  SizedBox(width: isTV ? 12 : 8),
                  Text(
                    t.discover.continueWatching,
                    style: isTV
                        ? theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                        : theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${widget.items.length} ${widget.items.length == 1 ? "item" : "items"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Items list
            SizedBox(
              height: isTV ? 200 : 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isTV ? 20 : 12),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _ContinueWatchingCard(
                    item: item,
                    isTV: isTV,
                    focusNode: _itemFocusNodes.length > index
                        ? _itemFocusNodes[index]
                        : null,
                    onRemove: () => _removeFromContinueWatching(item),
                    onRefresh: widget.onRefresh,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueWatchingCard extends StatefulWidget {
  final MediaItem item;
  final bool isTV;
  final FocusNode? focusNode;
  final VoidCallback onRemove;
  final void Function(String)? onRefresh;

  const _ContinueWatchingCard({
    required this.item,
    required this.isTV,
    this.focusNode,
    required this.onRemove,
    this.onRefresh,
  });

  @override
  State<_ContinueWatchingCard> createState() => _ContinueWatchingCardState();
}

class _ContinueWatchingCardState extends State<_ContinueWatchingCard> {
  bool _isFocused = false;
  bool _isHovered = false;

  MediaClient _getClientForItem(BuildContext context, MediaItem item) {
    final serverId = item.serverId;
    if (serverId == null) {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );
      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }
      return context.getClientForServer(multiServerProvider.onlineServerIds.first);
    }
    return context.getClientForServer(serverId);
  }

  String _formatTimeRemaining() {
    if (widget.item.duration == null || widget.item.viewOffset == null) {
      return '';
    }

    final remaining = widget.item.duration! - widget.item.viewOffset!;
    final minutes = (remaining / 60000).round();

    if (minutes < 1) return 'Less than 1 min left';
    if (minutes < 60) return '$minutes min left';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours hr left';
    return '$hours hr $mins min left';
  }

  double _getProgress() {
    if (widget.item.duration == null ||
        widget.item.viewOffset == null ||
        widget.item.duration == 0) {
      return 0;
    }
    return widget.item.viewOffset! / widget.item.duration!;
  }

  void _playItem() async {
    final result = await navigateToVideoPlayer(
      context,
      metadata: widget.item,
    );
    if (result == true) {
      widget.onRefresh?.call(widget.item.ratingKey);
    }
  }

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(metadata: widget.item),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.select) {
        _playItem();
        return KeyEventResult.handled;
      }
      // Delete key to remove
      if (event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        widget.onRemove();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = widget.isTV ? 280.0 : 220.0;
    final cardHeight = widget.isTV ? 180.0 : 140.0;
    final progress = _getProgress();
    final showRemoveButton = _isFocused || _isHovered;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Focus(
          focusNode: widget.focusNode,
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          onKeyEvent: _handleKeyEvent,
          child: FocusIndicator(
            isFocused: _isFocused,
            borderRadius: 12,
            child: GestureDetector(
              onTap: _playItem,
              onLongPress: _openDetails,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: cardWidth,
                height: cardHeight,
                transform: Matrix4.identity()..scale(_isFocused ? 1.05 : 1.0),
                transformAlignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _isFocused
                          ? theme.colorScheme.primary.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: _isFocused ? 16 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image (prefer art/backdrop for wide cards)
                      _buildBackgroundImage(context),

                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.95),
                            ],
                            stops: const [0.3, 0.7, 1.0],
                          ),
                        ),
                      ),

                      // Content
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              widget.item.title,
                              style: TextStyle(
                                fontSize: widget.isTV ? 16 : 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Episode info for TV shows
                            if (widget.item.type == 'episode') ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.item.grandparentTitle ?? '',
                                style: TextStyle(
                                  fontSize: widget.isTV ? 13 : 11,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'S${widget.item.parentIndex ?? 0} E${widget.item.index ?? 0}',
                                style: TextStyle(
                                  fontSize: widget.isTV ? 12 : 10,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            // Progress bar with time remaining
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.white24,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.primary,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimeRemaining(),
                                  style: TextStyle(
                                    fontSize: widget.isTV ? 11 : 9,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Play icon overlay
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: widget.isTV ? 24 : 20,
                          ),
                        ),
                      ),

                      // Remove button (shows on hover/focus)
                      if (showRemoveButton)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: widget.onRemove,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: widget.isTV ? 20 : 16,
                              ),
                            ),
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

  Widget _buildBackgroundImage(BuildContext context) {
    final theme = Theme.of(context);
    // Prefer art (backdrop) for landscape cards
    final imageUrl = widget.item.art ?? widget.item.thumb;

    if (imageUrl == null) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.movie,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Builder(
      builder: (context) {
        final client = _getClientForItem(context, widget.item);
        return CachedNetworkImage(
          imageUrl: client.getThumbnailUrl(imageUrl),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.movie, size: 48),
          ),
        );
      },
    );
  }
}
