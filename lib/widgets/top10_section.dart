import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hub.dart';
import '../screens/hub_detail_screen.dart';
import 'media_card.dart';
import 'horizontal_scroll_with_arrows.dart';
import 'hub_navigation_controller.dart';
import 'focus/focus_indicator.dart';

/// Netflix-style Top 10 section with large numbered rankings
/// Displays content with big numbers overlaid on the left edge of posters
class Top10Section extends StatefulWidget {
  final Hub hub;
  final void Function(String)? onRefresh;

  /// Order for navigation (lower = higher on screen). Default is 1000 for dynamic hubs.
  final int navigationOrder;

  const Top10Section({
    super.key,
    required this.hub,
    this.onRefresh,
    this.navigationOrder = 1000,
  });

  @override
  State<Top10Section> createState() => _Top10SectionState();
}

class _Top10SectionState extends State<Top10Section> {
  late final FocusNode _headerFocusNode;
  bool _headerIsFocused = false;
  HubNavigationController? _controller;

  /// Focus nodes for each item in the hub
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;
  int? _registeredItemCount;
  int? _registeredOrder;

  String get _hubId => 'top10_${widget.hub.hubIdentifier ?? widget.hub.title}';

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode();
    _headerFocusNode.addListener(_handleHeaderFocusChange);
    _createItemFocusNodes();
  }

  void _createItemFocusNodes() {
    // Limit to 10 items for Top 10
    final itemCount = widget.hub.items.length.clamp(0, 10);
    _itemFocusNodes = List.generate(
      itemCount,
      (index) => FocusNode(debugLabel: 'Top10Item_${_hubId}_$index'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerWithController();
  }

  @override
  void didUpdateWidget(Top10Section oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If items changed, recreate focus nodes
    final newCount = widget.hub.items.length.clamp(0, 10);
    if (newCount != _itemFocusNodes.length) {
      _disposeItemFocusNodes();
      _createItemFocusNodes();
    }
    _registerWithController();
  }

  void _unregisterFromController() {
    if (_controller != null && _registeredHubId != null) {
      _controller!.unregister(_registeredHubId!);
    }
    _registeredHubId = null;
    _registeredItemCount = null;
    _registeredOrder = null;
  }

  void _registerWithController() {
    final controller = HubNavigationScope.maybeOf(context);
    final hubId = _hubId;
    final itemCount = widget.hub.items.length.clamp(0, 10);
    final order = widget.navigationOrder;

    if (controller != _controller) {
      _unregisterFromController();
      _controller = controller;
    }

    if (controller == null) return;

    // Only register/update if something changed
    if (_registeredHubId != hubId ||
        _registeredItemCount != itemCount ||
        _registeredOrder != order) {
      _unregisterFromController();
      controller.register(
        HubSectionRegistration(
          hubId: hubId,
          itemCount: itemCount,
          focusItem: _focusItem,
          order: order,
        ),
      );
      _registeredHubId = hubId;
      _registeredItemCount = itemCount;
      _registeredOrder = order;
    }
  }

  void _focusItem(int index) {
    if (index < 0 || index >= _itemFocusNodes.length) return;
    _itemFocusNodes[index].requestFocus();
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

  @override
  Widget build(BuildContext context) {
    // Limit items to 10
    final items = widget.hub.items.take(10).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hub header with trophy icon for Top 10
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isTV = screenWidth > 1000;
              return Padding(
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
                            Icon(Icons.emoji_events, size: isTV ? 28 : 24, color: Colors.amber),
                            SizedBox(width: isTV ? 12 : 8),
                            Text(
                              widget.hub.title,
                              style: isTV
                                  ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      )
                                  : Theme.of(context).textTheme.titleLarge,
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
              );
            },
          ),

          // Top 10 items (horizontal scroll with large numbers)
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isTV = MediaQuery.of(context).size.width > 1200 &&
                  MediaQuery.of(context).size.height < MediaQuery.of(context).size.width;

              // Wider cards for Top 10 to accommodate the number
              final cardWidth = isTV
                  ? (screenWidth > 1600 ? 280.0 : 260.0)
                  : screenWidth > 1600
                      ? 260.0
                      : screenWidth > 1200
                          ? 240.0
                          : screenWidth > 800
                              ? 220.0
                              : 200.0;

              // Number takes up about 60px on the left
              final numberWidth = isTV ? 70.0 : 60.0;
              final posterWidth = cardWidth - numberWidth - 8; // -8 for spacing
              final posterHeight = posterWidth * 1.5;

              // Container height includes poster + text space + focus indicator headroom
              final containerHeight = posterHeight + 46 + 15;

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
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _Top10Card(
                              rank: index + 1,
                              item: item,
                              cardWidth: cardWidth,
                              numberWidth: numberWidth,
                              posterWidth: posterWidth,
                              posterHeight: posterHeight,
                              onRefresh: widget.onRefresh,
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

/// Individual Top 10 card with large ranking number
class _Top10Card extends StatelessWidget {
  final int rank;
  final dynamic item;
  final double cardWidth;
  final double numberWidth;
  final double posterWidth;
  final double posterHeight;
  final void Function(String)? onRefresh;
  final FocusNode? focusNode;
  final String hubId;
  final int itemIndex;

  const _Top10Card({
    required this.rank,
    required this.item,
    required this.cardWidth,
    required this.numberWidth,
    required this.posterWidth,
    required this.posterHeight,
    this.onRefresh,
    this.focusNode,
    required this.hubId,
    required this.itemIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: cardWidth,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Large ranking number
          SizedBox(
            width: numberWidth,
            height: posterHeight,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                // Number with outline effect
                _RankingNumber(
                  rank: rank,
                  height: posterHeight * 0.85,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          // Poster card (slightly overlapping the number)
          Transform.translate(
            offset: const Offset(-15, 0), // Overlap into number area
            child: MediaCard(
              key: Key('${item.ratingKey}_top10'),
              item: item,
              width: posterWidth + 16, // +16 for internal padding
              height: posterHeight,
              onRefresh: onRefresh,
              forceGridMode: true,
              focusNode: focusNode,
              hubId: hubId,
              itemIndex: itemIndex,
            ),
          ),
        ],
      ),
    );
  }
}

/// Large Netflix-style ranking number with outline
class _RankingNumber extends StatelessWidget {
  final int rank;
  final double height;
  final bool isDark;

  const _RankingNumber({
    required this.rank,
    required this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Adjust font size based on single vs double digit
    final fontSize = rank < 10 ? height * 0.9 : height * 0.7;

    // Colors for the number
    final fillColor = isDark
        ? Colors.grey.shade900
        : Colors.grey.shade100;
    final strokeColor = isDark
        ? Colors.grey.shade600
        : Colors.grey.shade400;

    return SizedBox(
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.centerRight,
        child: Stack(
          children: [
            // Stroke (outline) - multiple offset copies for bold effect
            ..._buildStrokeText(rank.toString(), fontSize, strokeColor),
            // Fill
            Text(
              rank.toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: fillColor,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStrokeText(String text, double fontSize, Color strokeColor) {
    const offsets = [
      Offset(-3, -3),
      Offset(3, -3),
      Offset(-3, 3),
      Offset(3, 3),
      Offset(-3, 0),
      Offset(3, 0),
      Offset(0, -3),
      Offset(0, 3),
    ];

    return offsets.map((offset) {
      return Transform.translate(
        offset: offset,
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: strokeColor,
            height: 1.0,
          ),
        ),
      );
    }).toList();
  }
}
