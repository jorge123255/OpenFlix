import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hub.dart';
import '../screens/hub_detail_screen.dart';
import 'media_card.dart';
import 'horizontal_scroll_with_arrows.dart';
import 'hub_navigation_controller.dart';
import 'focus/focus_indicator.dart';

/// Mood information with styling
class MoodInfo {
  final String name;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final String? emoji;

  const MoodInfo({
    required this.name,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.emoji,
  });

  /// Detect mood from hub title
  static MoodInfo? fromHub(Hub hub) {
    final title = hub.title.toLowerCase();
    final id = hub.hubIdentifier?.toLowerCase() ?? '';

    // Feel-Good / Happy
    if (title.contains('feel good') ||
        title.contains('feel-good') ||
        title.contains('uplifting') ||
        title.contains('heartwarming') ||
        id.contains('feelgood')) {
      return const MoodInfo(
        name: 'Feel-Good',
        icon: Icons.sentiment_very_satisfied,
        primaryColor: Color(0xFFFFC107),
        secondaryColor: Color(0xFFFFE082),
        emoji: '😊',
      );
    }

    // Thrilling / Edge of Seat
    if (title.contains('edge of') ||
        title.contains('suspense') ||
        title.contains('nail-biting') ||
        title.contains('nail biting') ||
        title.contains('intense')) {
      return const MoodInfo(
        name: 'Edge of Your Seat',
        icon: Icons.bolt,
        primaryColor: Color(0xFFE53935),
        secondaryColor: Color(0xFFFF8A80),
        emoji: '😱',
      );
    }

    // Relaxing / Chill
    if (title.contains('relax') ||
        title.contains('chill') ||
        title.contains('lazy') ||
        title.contains('cozy') ||
        title.contains('comfort')) {
      return const MoodInfo(
        name: 'Relaxing',
        icon: Icons.spa,
        primaryColor: Color(0xFF26A69A),
        secondaryColor: Color(0xFF80CBC4),
        emoji: '😌',
      );
    }

    // Romantic / Date Night
    if (title.contains('romance') ||
        title.contains('romantic') ||
        title.contains('date night') ||
        title.contains('love')) {
      return const MoodInfo(
        name: 'Date Night',
        icon: Icons.favorite,
        primaryColor: Color(0xFFE91E63),
        secondaryColor: Color(0xFFF48FB1),
        emoji: '💕',
      );
    }

    // Family
    if (title.contains('family') ||
        title.contains('kids') ||
        title.contains('all ages')) {
      return const MoodInfo(
        name: 'Family Time',
        icon: Icons.family_restroom,
        primaryColor: Color(0xFF7E57C2),
        secondaryColor: Color(0xFFB39DDB),
        emoji: '👨‍👩‍👧‍👦',
      );
    }

    // Action-Packed
    if (title.contains('action packed') ||
        title.contains('action-packed') ||
        title.contains('adrenaline') ||
        title.contains('explosive')) {
      return const MoodInfo(
        name: 'Action-Packed',
        icon: Icons.local_fire_department,
        primaryColor: Color(0xFFFF5722),
        secondaryColor: Color(0xFFFFAB91),
        emoji: '💥',
      );
    }

    // Mind-Bending
    if (title.contains('mind-bending') ||
        title.contains('mind bending') ||
        title.contains('thought provoking') ||
        title.contains('thought-provoking') ||
        title.contains('cerebral') ||
        title.contains('philosophical')) {
      return const MoodInfo(
        name: 'Mind-Bending',
        icon: Icons.psychology,
        primaryColor: Color(0xFF3F51B5),
        secondaryColor: Color(0xFF9FA8DA),
        emoji: '🧠',
      );
    }

    // Laugh Out Loud
    if (title.contains('laugh') ||
        title.contains('hilarious') ||
        title.contains('funny') ||
        title.contains('comedy night')) {
      return const MoodInfo(
        name: 'Laugh Out Loud',
        icon: Icons.mood,
        primaryColor: Color(0xFFFF9800),
        secondaryColor: Color(0xFFFFCC80),
        emoji: '😂',
      );
    }

    // Scary / Horror Night
    if (title.contains('scary') ||
        title.contains('spooky') ||
        title.contains('horror night') ||
        title.contains('creepy')) {
      return const MoodInfo(
        name: 'Scary Night',
        icon: Icons.nightlight,
        primaryColor: Color(0xFF424242),
        secondaryColor: Color(0xFF757575),
        emoji: '👻',
      );
    }

    // Inspiring
    if (title.contains('inspiring') ||
        title.contains('inspirational') ||
        title.contains('motivat')) {
      return const MoodInfo(
        name: 'Inspiring',
        icon: Icons.star,
        primaryColor: Color(0xFF00BCD4),
        secondaryColor: Color(0xFF80DEEA),
        emoji: '✨',
      );
    }

    return null;
  }
}

/// Mood-based collection section with special styling
class MoodCollectionSection extends StatefulWidget {
  final Hub hub;
  final MoodInfo mood;
  final void Function(String)? onRefresh;
  final int navigationOrder;

  const MoodCollectionSection({
    super.key,
    required this.hub,
    required this.mood,
    this.onRefresh,
    this.navigationOrder = 1000,
  });

  @override
  State<MoodCollectionSection> createState() => _MoodCollectionSectionState();
}

class _MoodCollectionSectionState extends State<MoodCollectionSection> {
  late final FocusNode _headerFocusNode;
  bool _headerIsFocused = false;
  HubNavigationController? _controller;
  List<FocusNode> _itemFocusNodes = [];
  String? _registeredHubId;

  String get _hubId => 'mood_${widget.hub.hubIdentifier ?? widget.hub.title}';

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
      (index) => FocusNode(debugLabel: 'MoodItem_${_hubId}_$index'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registerWithController();
  }

  @override
  void didUpdateWidget(MoodCollectionSection oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    if (widget.hub.items.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    return FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mood header with gradient background
          Padding(
            padding: EdgeInsets.fromLTRB(16, isTV ? 28 : 24, 16, isTV ? 12 : 8),
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
                  focusColor: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTV ? 16 : 12,
                      vertical: isTV ? 12 : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.mood.primaryColor.withValues(alpha: 0.2),
                          widget.mood.secondaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.mood.primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mood emoji or icon
                        if (widget.mood.emoji != null)
                          Text(
                            widget.mood.emoji!,
                            style: TextStyle(fontSize: isTV ? 28 : 24),
                          )
                        else
                          Icon(
                            widget.mood.icon,
                            size: isTV ? 28 : 24,
                            color: widget.mood.primaryColor,
                          ),
                        SizedBox(width: isTV ? 12 : 8),
                        // Title
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.hub.title,
                              style: TextStyle(
                                fontSize: isTV ? 20 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${widget.hub.items.length} titles',
                              style: TextStyle(
                                fontSize: isTV ? 14 : 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
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

          // Items
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
                              key: Key('${item.ratingKey}_mood'),
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
