import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../client/media_client.dart';
import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../screens/media_detail_screen.dart';
import '../utils/provider_extensions.dart';
import '../i18n/strings.g.dart';
import 'hub_navigation_controller.dart';
import 'focus/focus_indicator.dart';

/// "Your Next Watch" personalized recommendation section
/// Shows curated picks based on user's viewing history with a premium look
class YourNextWatchSection extends StatefulWidget {
  final List<MediaItem> items;
  final String? userName;
  final VoidCallback? onSeeAll;
  final int navigationOrder;

  const YourNextWatchSection({
    super.key,
    required this.items,
    this.userName,
    this.onSeeAll,
    this.navigationOrder = 1000,
  });

  @override
  State<YourNextWatchSection> createState() => _YourNextWatchSectionState();
}

class _YourNextWatchSectionState extends State<YourNextWatchSection> {
  late final FocusNode _headerFocusNode;
  bool _headerIsFocused = false;
  HubNavigationController? _controller;
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  static const String _hubId = 'your_next_watch';

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode();
    _headerFocusNode.addListener(_handleHeaderFocusChange);
    _createItemFocusNodes();
  }

  void _createItemFocusNodes() {
    final itemCount = widget.items.length.clamp(0, 10);
    _itemFocusNodes = List.generate(
      itemCount,
      (index) => FocusNode(debugLabel: 'NextWatch_$index'),
    );
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
          itemCount: widget.items.length.clamp(0, 10),
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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _unregisterFromController();
    _headerFocusNode.removeListener(_handleHeaderFocusChange);
    _headerFocusNode.dispose();
    _pageController.dispose();
    for (final node in _itemFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleHeaderFocusChange() {
    if (_headerIsFocused != _headerFocusNode.hasFocus) {
      setState(() {
        _headerIsFocused = _headerFocusNode.hasFocus;
      });
    }
  }

  KeyEventResult _handleHeaderKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && widget.onSeeAll != null) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.select) {
        widget.onSeeAll!();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onItemTap(MediaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(metadata: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;
    final displayItems = widget.items.take(10).toList();

    return FocusTraversalGroup(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isTV ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with personalized greeting
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTV ? 24 : 16,
                0,
                isTV ? 24 : 16,
                isTV ? 16 : 12,
              ),
              child: Focus(
                focusNode: _headerFocusNode,
                onKeyEvent: _handleHeaderKeyEvent,
                canRequestFocus: widget.onSeeAll != null,
                child: FocusIndicator(
                  isFocused: _headerIsFocused && widget.onSeeAll != null,
                  borderRadius: 12,
                  child: InkWell(
                    onTap: widget.onSeeAll,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTV ? 16 : 12,
                        vertical: isTV ? 12 : 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.secondary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Animated icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: isTV ? 28 : 24,
                            ),
                          ),
                          SizedBox(width: isTV ? 16 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.discover.yourNextWatch,
                                  style: TextStyle(
                                    fontSize: isTV ? 22 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.userName != null)
                                  Text(
                                    t.discover.pickedForYou(
                                        name: widget.userName!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.onSeeAll != null)
                            Icon(
                              Icons.chevron_right,
                              size: isTV ? 28 : 24,
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Page indicator dots
            if (displayItems.length > 1)
              Padding(
                padding: EdgeInsets.only(
                  left: isTV ? 24 : 16,
                  bottom: isTV ? 12 : 8,
                ),
                child: Row(
                  children: List.generate(
                    displayItems.length.clamp(0, 5),
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 6),
                      width: _currentPage == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

            // Carousel of recommendation cards
            SizedBox(
              height: isTV ? 320 : 260,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                itemCount: displayItems.length,
                itemBuilder: (context, index) {
                  final item = displayItems[index];
                  return _NextWatchCard(
                    item: item,
                    isTV: isTV,
                    focusNode: _itemFocusNodes.length > index
                        ? _itemFocusNodes[index]
                        : null,
                    onTap: () => _onItemTap(item),
                    isActive: _currentPage == index,
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

class _NextWatchCard extends StatefulWidget {
  final MediaItem item;
  final bool isTV;
  final FocusNode? focusNode;
  final VoidCallback onTap;
  final bool isActive;

  const _NextWatchCard({
    required this.item,
    required this.isTV,
    this.focusNode,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_NextWatchCard> createState() => _NextWatchCardState();
}

class _NextWatchCardState extends State<_NextWatchCard> {
  bool _isFocused = false;

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
      return context
          .getClientForServer(multiServerProvider.onlineServerIds.first);
    }

    return context.getClientForServer(serverId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighlighted = _isFocused || widget.isActive;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.isTV ? 8 : 6),
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (focused) {
          setState(() => _isFocused = focused);
        },
        child: FocusIndicator(
          isFocused: _isFocused,
          borderRadius: 16,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.identity()
                ..scale(isHighlighted ? 1.0 : 0.95),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isHighlighted
                        ? theme.colorScheme.primary.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: isHighlighted ? 20 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image (art or thumb)
                    _buildBackgroundImage(context),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                            Colors.black.withValues(alpha: 0.9),
                          ],
                          stops: const [0.3, 0.6, 1.0],
                        ),
                      ),
                    ),

                    // Content overlay
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            widget.item.title,
                            style: TextStyle(
                              fontSize: widget.isTV ? 24 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Metadata row
                          Row(
                            children: [
                              if (widget.item.year != null) ...[
                                Text(
                                  widget.item.year.toString(),
                                  style: TextStyle(
                                    fontSize: widget.isTV ? 14 : 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                _buildDot(),
                              ],
                              if (widget.item.contentRating != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white54),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.item.contentRating!,
                                    style: TextStyle(
                                      fontSize: widget.isTV ? 12 : 10,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                _buildDot(),
                              ],
                              if (widget.item.rating != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: widget.isTV ? 16 : 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(widget.item.rating! * 10).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: widget.isTV ? 14 : 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // Summary/tagline
                          if (widget.item.summary != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.item.summary!,
                              style: TextStyle(
                                fontSize: widget.isTV ? 14 : 12,
                                color: Colors.white60,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Play button hint
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: widget.isTV ? 20 : 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  t.common.playNow,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: widget.isTV ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Type badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTypeLabel(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.isTV ? 12 : 10,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildBackgroundImage(BuildContext context) {
    final theme = Theme.of(context);
    // Prefer art (backdrop) for landscape cards, fall back to thumb
    final imageUrl = widget.item.art ?? widget.item.thumb;

    if (imageUrl == null) {
      return Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.movie, size: 64, color: Colors.white24),
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
            child: const Icon(Icons.movie, size: 64, color: Colors.white24),
          ),
        );
      },
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: Colors.white54,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (widget.item.type) {
      case 'movie':
        return 'MOVIE';
      case 'show':
        return 'TV SHOW';
      case 'episode':
        return 'EPISODE';
      case 'season':
        return 'SEASON';
      default:
        return widget.item.type.toUpperCase();
    }
  }
}
