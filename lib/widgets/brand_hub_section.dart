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

/// Brand/Studio hub section with themed header styling
/// Used for collections like "Marvel", "Disney", "Pixar", "DC", etc.
class BrandHubSection extends StatefulWidget {
  final Hub hub;
  final BrandInfo brandInfo;
  final void Function(String)? onRefresh;
  final int navigationOrder;

  const BrandHubSection({
    super.key,
    required this.hub,
    required this.brandInfo,
    this.onRefresh,
    this.navigationOrder = 1000,
  });

  @override
  State<BrandHubSection> createState() => _BrandHubSectionState();
}

/// Information about a brand/studio for styling
class BrandInfo {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData icon;
  final String? logoUrl;

  const BrandInfo({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    this.logoUrl,
  });

  /// Get brand info from hub title/identifier
  static BrandInfo? fromHub(Hub hub) {
    final title = hub.title.toLowerCase();
    final id = hub.hubIdentifier?.toLowerCase() ?? '';

    // Marvel
    if (title.contains('marvel') || id.contains('marvel')) {
      return const BrandInfo(
        name: 'MARVEL',
        primaryColor: Color(0xFFED1D24), // Marvel red
        secondaryColor: Color(0xFF1A1A1A),
        icon: Icons.flash_on,
      );
    }

    // DC
    if (title.contains('dc ') ||
        title.contains('dc comics') ||
        id.contains('dc')) {
      return const BrandInfo(
        name: 'DC',
        primaryColor: Color(0xFF0476F2), // DC blue
        secondaryColor: Color(0xFF1A1A1A),
        icon: Icons.shield,
      );
    }

    // Disney
    if (title.contains('disney') || id.contains('disney')) {
      return const BrandInfo(
        name: 'Disney',
        primaryColor: Color(0xFF113CCF), // Disney blue
        secondaryColor: Color(0xFF0B1E5C),
        icon: Icons.castle,
      );
    }

    // Pixar
    if (title.contains('pixar') || id.contains('pixar')) {
      return const BrandInfo(
        name: 'PIXAR',
        primaryColor: Color(0xFF00A8E1), // Pixar blue
        secondaryColor: Color(0xFF1A1A1A),
        icon: Icons.animation,
      );
    }

    // Star Wars
    if (title.contains('star wars') || id.contains('starwars')) {
      return const BrandInfo(
        name: 'STAR WARS',
        primaryColor: Color(0xFFFFE81F), // Star Wars yellow
        secondaryColor: Color(0xFF1A1A1A),
        icon: Icons.stars,
      );
    }

    // DreamWorks
    if (title.contains('dreamworks') || id.contains('dreamworks')) {
      return const BrandInfo(
        name: 'DreamWorks',
        primaryColor: Color(0xFF00A4E4), // DreamWorks blue
        secondaryColor: Color(0xFF1A4D6B),
        icon: Icons.cloud,
      );
    }

    // Studio Ghibli
    if (title.contains('ghibli') || id.contains('ghibli')) {
      return const BrandInfo(
        name: 'Studio Ghibli',
        primaryColor: Color(0xFF3B7A57), // Ghibli green
        secondaryColor: Color(0xFF1A3D2B),
        icon: Icons.eco,
      );
    }

    // Warner Bros
    if (title.contains('warner') || id.contains('warner')) {
      return const BrandInfo(
        name: 'Warner Bros.',
        primaryColor: Color(0xFF004B87), // WB blue
        secondaryColor: Color(0xFF002244),
        icon: Icons.movie,
      );
    }

    // Universal
    if (title.contains('universal') || id.contains('universal')) {
      return const BrandInfo(
        name: 'Universal',
        primaryColor: Color(0xFFFFFFFF),
        secondaryColor: Color(0xFF1A1A1A),
        icon: Icons.public,
      );
    }

    // National Geographic
    if (title.contains('national geographic') || title.contains('nat geo')) {
      return const BrandInfo(
        name: 'National Geographic',
        primaryColor: Color(0xFFFFCC00), // NatGeo yellow
        secondaryColor: Color(0xFF1A1A1A),
        icon: Icons.explore,
      );
    }

    // HBO
    if (title.contains('hbo') || id.contains('hbo')) {
      return const BrandInfo(
        name: 'HBO',
        primaryColor: Color(0xFF000000),
        secondaryColor: Color(0xFF5822B4),
        icon: Icons.tv,
      );
    }

    // Netflix Originals
    if (title.contains('netflix') || id.contains('netflix')) {
      return const BrandInfo(
        name: 'Netflix',
        primaryColor: Color(0xFFE50914), // Netflix red
        secondaryColor: Color(0xFF1A1A1A),
        icon: Icons.play_arrow,
      );
    }

    // A24
    if (title.contains('a24') || id.contains('a24')) {
      return const BrandInfo(
        name: 'A24',
        primaryColor: Color(0xFF000000),
        secondaryColor: Color(0xFF333333),
        icon: Icons.auto_awesome,
      );
    }

    // Lionsgate
    if (title.contains('lionsgate') || id.contains('lionsgate')) {
      return const BrandInfo(
        name: 'Lionsgate',
        primaryColor: Color(0xFFE8490A), // Lionsgate orange
        secondaryColor: Color(0xFF1A1A1A),
        icon: Icons.local_movies,
      );
    }

    return null;
  }
}

class _BrandHubSectionState extends State<BrandHubSection> {
  late final FocusNode _headerFocusNode;
  bool _headerIsFocused = false;
  HubNavigationController? _controller;
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;

  String get _hubId => 'brand_${widget.hub.hubIdentifier ?? widget.hub.title}';

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode();
    _headerFocusNode.addListener(_handleHeaderFocusChange);
    _createItemFocusNodes();
  }

  void _createItemFocusNodes() {
    final itemCount = widget.hub.items.length.clamp(0, 10);
    _itemFocusNodes = List.generate(
      itemCount,
      (index) => FocusNode(debugLabel: 'BrandItem_${_hubId}_$index'),
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
          itemCount: widget.hub.items.length.clamp(0, 10),
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
        builder: (context) => MediaDetailScreen(metadata: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.hub.items.take(10).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;
    final brand = widget.brandInfo;

    return FocusTraversalGroup(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isTV ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Branded header with gradient background
            Container(
              margin: EdgeInsets.symmetric(horizontal: isTV ? 24 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    brand.primaryColor.withValues(alpha: 0.3),
                    brand.secondaryColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: brand.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Focus(
                focusNode: _headerFocusNode,
                onKeyEvent: _handleHeaderKeyEvent,
                canRequestFocus: widget.hub.more,
                child: FocusIndicator(
                  isFocused: _headerIsFocused && widget.hub.more,
                  borderRadius: 12,
                  child: InkWell(
                    onTap: widget.hub.more ? _navigateToHubDetail : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTV ? 20 : 16,
                        vertical: isTV ? 16 : 12,
                      ),
                      child: Row(
                        children: [
                          // Brand icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: brand.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: brand.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              brand.icon,
                              color: brand.primaryColor.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                              size: isTV ? 28 : 24,
                            ),
                          ),
                          SizedBox(width: isTV ? 16 : 12),
                          // Brand name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  brand.name,
                                  style: TextStyle(
                                    fontSize: isTV ? 24 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: brand.primaryColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                if (widget.hub.title.toLowerCase() !=
                                    brand.name.toLowerCase())
                                  Text(
                                    widget.hub.title,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.hub.more)
                            Icon(
                              Icons.chevron_right,
                              color: brand.primaryColor,
                              size: isTV ? 28 : 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: isTV ? 16 : 12),

            // Items with brand-colored accent
            SizedBox(
              height: isTV ? 240 : 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isTV ? 20 : 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _BrandCard(
                    item: item,
                    brandColor: brand.primaryColor,
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

class _BrandCard extends StatefulWidget {
  final MediaItem item;
  final Color brandColor;
  final bool isTV;
  final FocusNode? focusNode;
  final VoidCallback onTap;

  const _BrandCard({
    required this.item,
    required this.brandColor,
    required this.isTV,
    this.focusNode,
    required this.onTap,
  });

  @override
  State<_BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<_BrandCard> {
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
    final cardWidth = widget.isTV ? 140.0 : 120.0;
    final cardHeight = widget.isTV ? 220.0 : 180.0;
    final posterHeight = cardHeight - 50;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (focused) {
          setState(() => _isFocused = focused);
        },
        child: FocusIndicator(
          isFocused: _isFocused,
          borderRadius: 10,
          borderColor: widget.brandColor,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: cardWidth,
              transform: Matrix4.identity()..scale(_isFocused ? 1.08 : 1.0),
              transformAlignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster with brand-colored border on focus
                  Container(
                    height: posterHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: _isFocused
                          ? Border.all(color: widget.brandColor, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: _isFocused
                              ? widget.brandColor.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.3),
                          blurRadius: _isFocused ? 16 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: widget.item.thumb != null
                          ? Builder(
                              builder: (context) {
                                final client =
                                    _getClientForItem(context, widget.item);
                                return CachedNetworkImage(
                                  imageUrl:
                                      client.getThumbnailUrl(widget.item.thumb!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color:
                                        theme.colorScheme.surfaceContainerHighest,
                                    child: const Center(
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color:
                                        theme.colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.movie, size: 40),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.movie, size: 40),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    widget.item.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Year
                  if (widget.item.year != null)
                    Text(
                      widget.item.year.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
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
