import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../client/media_client.dart';
import '../models/hub.dart';
import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../screens/hub_detail_screen.dart';
import '../screens/media_detail_screen.dart';
import '../utils/provider_extensions.dart';
import 'hub_navigation_controller.dart';
import 'focus/focus_indicator.dart';

/// Get the MediaClient for a media item based on its serverId
MediaClient _getClientForItem(BuildContext context, MediaItem item) {
  final serverId = item.serverId;

  // If serverId is null, fall back to first available server
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

/// A featured collection section with larger cards and themed styling
/// Used for special collections like "Award Winners", "Seasonal Picks", etc.
class FeaturedCollectionSection extends StatefulWidget {
  final Hub hub;
  final Color? accentColor;
  final IconData? icon;
  final void Function(String)? onRefresh;
  final int navigationOrder;

  const FeaturedCollectionSection({
    super.key,
    required this.hub,
    this.accentColor,
    this.icon,
    this.onRefresh,
    this.navigationOrder = 1000,
  });

  @override
  State<FeaturedCollectionSection> createState() => _FeaturedCollectionSectionState();
}

class _FeaturedCollectionSectionState extends State<FeaturedCollectionSection> {
  late final FocusNode _headerFocusNode;
  bool _headerIsFocused = false;
  HubNavigationController? _controller;
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;

  String get _hubId => 'featured_${widget.hub.hubIdentifier ?? widget.hub.title}';

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode();
    _headerFocusNode.addListener(_handleHeaderFocusChange);
    _createItemFocusNodes();
  }

  void _createItemFocusNodes() {
    final itemCount = widget.hub.items.length.clamp(0, 6); // Max 6 featured items
    _itemFocusNodes = List.generate(
      itemCount,
      (index) => FocusNode(debugLabel: 'FeaturedItem_${_hubId}_$index'),
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

    final hubId = _hubId;
    if (_registeredHubId != hubId) {
      _unregisterFromController();
      controller.register(
        HubSectionRegistration(
          hubId: hubId,
          itemCount: widget.hub.items.length.clamp(0, 6),
          focusItem: _focusItem,
          order: widget.navigationOrder,
        ),
      );
      _registeredHubId = hubId;
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
    _headerFocusNode.removeListener(_handleHeaderFocusChange);
    _headerFocusNode.dispose();
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

  void _navigateToHubDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HubDetailScreen(hub: widget.hub)),
    );
  }

  KeyEventResult _handleHeaderKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && widget.hub.more) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.select) {
        _navigateToHubDetail();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onItemTap(MediaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(
          metadata: item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.hub.items.take(6).toList(); // Max 6 items
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final accentColor = widget.accentColor ?? theme.colorScheme.primary;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    return FocusTraversalGroup(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isTV ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with accent styling
            Padding(
              padding: EdgeInsets.fromLTRB(isTV ? 24 : 16, 0, isTV ? 24 : 16, isTV ? 12 : 8),
              child: Focus(
                focusNode: _headerFocusNode,
                onKeyEvent: _handleHeaderKeyEvent,
                canRequestFocus: widget.hub.more,
                child: FocusIndicator(
                  isFocused: _headerIsFocused && widget.hub.more,
                  borderRadius: 8,
                  child: InkWell(
                    onTap: widget.hub.more ? _navigateToHubDetail : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTV ? 12 : 8,
                        vertical: isTV ? 8 : 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.icon ?? Icons.auto_awesome,
                              color: accentColor,
                              size: isTV ? 24 : 20,
                            ),
                          ),
                          SizedBox(width: isTV ? 12 : 8),
                          Text(
                            widget.hub.title,
                            style: isTV
                                ? theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )
                                : theme.textTheme.titleLarge,
                          ),
                          if (widget.hub.more) ...[
                            SizedBox(width: isTV ? 8 : 4),
                            Icon(Icons.chevron_right, size: isTV ? 28 : 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Featured items in a horizontal grid
            SizedBox(
              height: isTV ? 280 : 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isTV ? 20 : 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _FeaturedCard(
                    item: item,
                    accentColor: accentColor,
                    isTV: isTV,
                    focusNode: _itemFocusNodes.length > index
                        ? _itemFocusNodes[index]
                        : null,
                    onTap: () => _onItemTap(item),
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

class _FeaturedCard extends StatefulWidget {
  final MediaItem item;
  final Color accentColor;
  final bool isTV;
  final FocusNode? focusNode;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.item,
    required this.accentColor,
    required this.isTV,
    this.focusNode,
    required this.onTap,
  });

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = widget.isTV ? 200.0 : 160.0;
    final cardHeight = widget.isTV ? 260.0 : 200.0;
    final posterHeight = cardHeight - 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (focused) {
          setState(() => _isFocused = focused);
        },
        child: FocusIndicator(
          isFocused: _isFocused,
          borderRadius: 12,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: cardWidth,
              transform: Matrix4.identity()..scale(_isFocused ? 1.05 : 1.0),
              transformAlignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster with gradient overlay
                  Container(
                    height: posterHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: _isFocused ? 0.4 : 0.2),
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
                          // Poster image
                          widget.item.thumb != null
                              ? Builder(
                                  builder: (context) {
                                    final client = _getClientForItem(context, widget.item);
                                    return CachedNetworkImage(
                                      imageUrl: client.getThumbnailUrl(widget.item.thumb!),
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
                                )
                              : Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.movie, size: 48),
                                ),
                          // Gradient overlay at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Rating badge
                          if (widget.item.rating != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(widget.item.rating!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${(widget.item.rating! * 10).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    widget.item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Year
                  if (widget.item.year != null)
                    Text(
                      widget.item.year.toString(),
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

  Color _getRatingColor(double rating) {
    final percent = rating * 10;
    if (percent >= 75) return Colors.green.shade700;
    if (percent >= 60) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}
