import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/hub.dart';
import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../screens/hub_detail_screen.dart';
import '../utils/provider_extensions.dart';
import 'media_card.dart';
import 'horizontal_scroll_with_arrows.dart';
import 'hub_navigation_controller.dart';
import 'focus/focus_indicator.dart';

/// Information about a "Because you watched" hub
class BecauseYouWatchedInfo {
  final String sourceTitle;
  final String? sourceThumb;
  final String? sourceRatingKey;

  const BecauseYouWatchedInfo({
    required this.sourceTitle,
    this.sourceThumb,
    this.sourceRatingKey,
  });

  /// Extract "Because you watched X" info from hub
  static BecauseYouWatchedInfo? fromHub(Hub hub) {
    final title = hub.title.toLowerCase();

    // Match patterns like "Because you watched Stranger Things"
    // or "More like Stranger Things"
    // or "Similar to Stranger Things"
    if (title.startsWith('because you watched ')) {
      final sourceTitle = hub.title.substring('Because you watched '.length);
      return BecauseYouWatchedInfo(sourceTitle: sourceTitle);
    }

    if (title.startsWith('more like ')) {
      final sourceTitle = hub.title.substring('More like '.length);
      return BecauseYouWatchedInfo(sourceTitle: sourceTitle);
    }

    if (title.startsWith('similar to ')) {
      final sourceTitle = hub.title.substring('Similar to '.length);
      return BecauseYouWatchedInfo(sourceTitle: sourceTitle);
    }

    if (title.contains('because you watched')) {
      // Try to extract the title after "because you watched"
      final match = RegExp(
        r'because you watched (.+)',
        caseSensitive: false,
      ).firstMatch(hub.title);
      if (match != null) {
        return BecauseYouWatchedInfo(sourceTitle: match.group(1)!);
      }
    }

    return null;
  }
}

/// "Because You Watched X" section with special styling
class BecauseYouWatchedSection extends StatefulWidget {
  final Hub hub;
  final BecauseYouWatchedInfo info;
  final void Function(String)? onRefresh;
  final int navigationOrder;

  const BecauseYouWatchedSection({
    super.key,
    required this.hub,
    required this.info,
    this.onRefresh,
    this.navigationOrder = 1000,
  });

  @override
  State<BecauseYouWatchedSection> createState() =>
      _BecauseYouWatchedSectionState();
}

class _BecauseYouWatchedSectionState extends State<BecauseYouWatchedSection> {
  late final FocusNode _headerFocusNode;
  bool _headerIsFocused = false;
  HubNavigationController? _controller;
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;

  String get _hubId =>
      'because_watched_${widget.hub.hubIdentifier ?? widget.hub.title}';

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode();
    _headerFocusNode.addListener(_handleHeaderFocusChange);
    _createItemFocusNodes();
  }

  void _createItemFocusNodes() {
    _itemFocusNodes = List.generate(
      widget.hub.items.length,
      (index) => FocusNode(debugLabel: 'BecauseWatchedItem_${_hubId}_$index'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerWithController();
  }

  @override
  void didUpdateWidget(BecauseYouWatchedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hub.items.length != oldWidget.hub.items.length) {
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
          itemCount: widget.hub.items.length,
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
          event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        _navigateToHubDetail();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  String? _getSourceThumbUrl() {
    // Try to find the source item in the hub's items or use the first item's parent
    // For now, we'll use the first recommendation's grandparent thumb if available
    if (widget.hub.items.isNotEmpty) {
      final firstItem = widget.hub.items.first;
      // Get the thumbnail URL from the media client
      try {
        final multiServerProvider = Provider.of<MultiServerProvider>(
          context,
          listen: false,
        );
        if (multiServerProvider.hasConnectedServers) {
          final client = context.getClientForServer(
            firstItem.serverId ?? multiServerProvider.onlineServerIds.first,
          );
          // Use the first item's art as a fallback for the "source" visual
          if (firstItem.art != null) {
            return client.getThumbnailUrl(firstItem.art!);
          }
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hub.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with source reference
          Padding(
            padding: EdgeInsets.fromLTRB(16, isTV ? 28 : 24, 16, isTV ? 12 : 8),
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
                  focusColor: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTV ? 12 : 8,
                      vertical: isTV ? 8 : 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "Because you watched" icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.history,
                            size: isTV ? 24 : 20,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        SizedBox(width: isTV ? 12 : 8),
                        // Title with source reference
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Because you watched',
                                style: TextStyle(
                                  fontSize: isTV ? 14 : 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                widget.info.sourceTitle,
                                style: TextStyle(
                                  fontSize: isTV ? 20 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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

          // Recommendation items
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = isTV ? 160.0 : 130.0;
              final cardHeight = cardWidth * 1.5;
              final containerHeight = cardHeight + 60;

              return SizedBox(
                height: containerHeight,
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
                        itemCount: widget.hub.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.hub.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: MediaCard(
                              key: Key('${item.ratingKey}_because_watched'),
                              item: item,
                              width: cardWidth,
                              height: cardHeight,
                              onRefresh: widget.onRefresh,
                              forceGridMode: true,
                              focusNode: _itemFocusNodes.length > index
                                  ? _itemFocusNodes[index]
                                  : null,
                              hubId: _hubId,
                              itemIndex: index,
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
