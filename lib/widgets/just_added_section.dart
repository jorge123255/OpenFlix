import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/media_item.dart';
import 'media_card.dart';
import 'horizontal_scroll_with_arrows.dart';
import 'hub_navigation_controller.dart';
import 'focus/focus_indicator.dart';
import '../i18n/strings.g.dart';

/// "Just Added" section showing recently added content
/// Displays new content with a fresh, eye-catching design
class JustAddedSection extends StatefulWidget {
  final List<MediaItem> items;
  final void Function(String)? onRefresh;
  final VoidCallback? onSeeAll;
  final int navigationOrder;

  const JustAddedSection({
    super.key,
    required this.items,
    this.onRefresh,
    this.onSeeAll,
    this.navigationOrder = 150,
  });

  @override
  State<JustAddedSection> createState() => _JustAddedSectionState();
}

class _JustAddedSectionState extends State<JustAddedSection> {
  late final FocusNode _headerFocusNode;
  bool _headerIsFocused = false;
  HubNavigationController? _controller;
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;

  static const String _hubId = 'just_added';

  @override
  void initState() {
    super.initState();
    _headerFocusNode = FocusNode();
    _headerFocusNode.addListener(_handleHeaderFocusChange);
    _createItemFocusNodes();
  }

  void _createItemFocusNodes() {
    _itemFocusNodes = List.generate(
      widget.items.length,
      (index) => FocusNode(debugLabel: 'JustAdded_$index'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerWithController();
  }

  @override
  void didUpdateWidget(JustAddedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
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

  KeyEventResult _handleHeaderKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && widget.onSeeAll != null) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        widget.onSeeAll?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header with sparkle icon
          Padding(
            padding: EdgeInsets.fromLTRB(16, isTV ? 28 : 24, 16, isTV ? 12 : 8),
            child: Focus(
              focusNode: _headerFocusNode,
              onKeyEvent: _handleHeaderKeyEvent,
              canRequestFocus: widget.onSeeAll != null,
              child: FocusIndicator(
                isFocused: _headerIsFocused && widget.onSeeAll != null,
                borderRadius: 8,
                child: InkWell(
                  onTap: widget.onSeeAll,
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
                        Icon(
                          Icons.auto_awesome,
                          size: isTV ? 28 : 24,
                          color: Colors.amber,
                        ),
                        SizedBox(width: isTV ? 12 : 8),
                        Text(
                          t.discover.recentlyAdded,
                          style: isTV
                              ? theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )
                              : theme.textTheme.titleLarge,
                        ),
                        if (widget.onSeeAll != null) ...[
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

          // Horizontal scrolling items
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = isTV ? 180.0 : 140.0;
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
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final item = widget.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: MediaCard(
                              key: Key('${item.ratingKey}_just_added'),
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
