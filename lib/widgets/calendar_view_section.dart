import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/media_item.dart';
import 'media_card.dart';
import 'hub_navigation_controller.dart';
import '../i18n/strings.g.dart';

/// Calendar View Section - Shows content organized by date
/// Similar to streaming app "Coming Soon" or "New Releases" calendars
class CalendarViewSection extends StatefulWidget {
  final List<MediaItem> items;
  final String title;
  final IconData icon;
  final int navigationOrder;
  final VoidCallback? onSeeAll;

  const CalendarViewSection({
    super.key,
    required this.items,
    this.title = 'Calendar',
    this.icon = Icons.calendar_month,
    this.navigationOrder = 500,
    this.onSeeAll,
  });

  @override
  State<CalendarViewSection> createState() => _CalendarViewSectionState();
}

class _CalendarViewSectionState extends State<CalendarViewSection> {
  late DateTime _selectedDate;
  late ScrollController _dateScrollController;
  late ScrollController _contentScrollController;
  final List<DateTime> _dates = [];
  Map<String, List<MediaItem>> _itemsByDate = {};
  HubNavigationController? _controller;
  String? _registeredHubId;
  final List<FocusNode> _dateFocusNodes = [];
  final List<FocusNode> _itemFocusNodes = [];
  int _focusedDateIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateScrollController = ScrollController();
    _contentScrollController = ScrollController();
    _buildDatesAndGroupItems();
  }

  void _buildDatesAndGroupItems() {
    // Build list of dates from today going back 30 days and forward 7 days
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final endDate = now.add(const Duration(days: 7));

    _dates.clear();
    for (var date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      _dates.add(DateTime(date.year, date.month, date.day));
    }

    // Create focus nodes for dates
    for (var node in _dateFocusNodes) {
      node.dispose();
    }
    _dateFocusNodes.clear();
    for (var i = 0; i < _dates.length; i++) {
      _dateFocusNodes.add(FocusNode(debugLabel: 'CalendarDate_$i'));
    }

    // Find index of today and set it as initial selection
    final todayIndex = _dates.indexWhere((d) =>
        d.year == now.year && d.month == now.month && d.day == now.day);
    if (todayIndex != -1) {
      _focusedDateIndex = todayIndex;
      _selectedDate = _dates[todayIndex];
    }

    // Group items by date
    _itemsByDate = {};
    for (final item in widget.items) {
      final addedAt = item.addedAt;
      if (addedAt != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(addedAt * 1000);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        _itemsByDate.putIfAbsent(dateKey, () => []);
        _itemsByDate[dateKey]!.add(item);
      }
    }

    // Create focus nodes for current date's items
    _updateItemFocusNodes();
  }

  void _updateItemFocusNodes() {
    for (var node in _itemFocusNodes) {
      node.dispose();
    }
    _itemFocusNodes.clear();

    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final items = _itemsByDate[dateKey] ?? [];
    for (var i = 0; i < items.length; i++) {
      _itemFocusNodes.add(FocusNode(debugLabel: 'CalendarItem_$i'));
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
      if (_controller != null && _registeredHubId != null) {
        _controller!.unregister(_registeredHubId!);
      }
      _controller = controller;
    }

    final hubId = '_calendar_';
    if (_controller != null && hubId != _registeredHubId) {
      _controller!.register(
        HubSectionRegistration(
          hubId: hubId,
          itemCount: _dates.length,
          focusItem: (index) {
            if (index < _dateFocusNodes.length) {
              _dateFocusNodes[index].requestFocus();
            }
          },
          order: widget.navigationOrder,
        ),
      );
      _registeredHubId = hubId;
    }
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _contentScrollController.dispose();
    for (var node in _dateFocusNodes) {
      node.dispose();
    }
    for (var node in _itemFocusNodes) {
      node.dispose();
    }
    if (_controller != null && _registeredHubId != null) {
      _controller!.unregister(_registeredHubId!);
    }
    super.dispose();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _updateItemFocusNodes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedItems = _itemsByDate[dateKey] ?? [];
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(widget.icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (widget.onSeeAll != null)
                TextButton(
                  onPressed: widget.onSeeAll,
                  child: Text(t.common.seeAll),
                ),
            ],
          ),
        ),

        // Calendar strip
        SizedBox(
          height: 80,
          child: ListView.builder(
            controller: _dateScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _dates.length,
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final dateNow = DateTime.now();
              final isDateToday = date.year == dateNow.year &&
                  date.month == dateNow.month &&
                  date.day == dateNow.day;
              final hasContent = _itemsByDate
                      .containsKey(DateFormat('yyyy-MM-dd').format(date)) &&
                  _itemsByDate[DateFormat('yyyy-MM-dd').format(date)]!
                      .isNotEmpty;

              return _CalendarDateCard(
                date: date,
                isSelected: isSelected,
                isToday: isDateToday,
                hasContent: hasContent,
                focusNode: _dateFocusNodes[index],
                onTap: () => _selectDate(date),
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    setState(() {
                      _focusedDateIndex = index;
                    });
                    // Auto-scroll to keep focused date visible
                    _scrollToDate(index);
                  }
                },
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Selected date header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                isToday
                    ? t.discover.today
                    : DateFormat('EEEE, MMMM d').format(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedItems.length} ${selectedItems.length == 1 ? t.discover.item : t.discover.items}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Content for selected date
        if (selectedItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.discover.noContentOnDate,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              controller: _contentScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: selectedItems.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: 130,
                    child: MediaCard(
                      item: selectedItems[index],
                      forceGridMode: true,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _scrollToDate(int index) {
    if (!_dateScrollController.hasClients) return;
    final itemWidth = 60.0; // Approximate width of date card
    final screenWidth = MediaQuery.of(context).size.width;
    final targetOffset =
        (index * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    _dateScrollController.animateTo(
      targetOffset.clamp(0, _dateScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

/// Individual date card in the calendar strip
class _CalendarDateCard extends StatefulWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasContent;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final ValueChanged<bool> onFocusChange;

  const _CalendarDateCard({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasContent,
    required this.focusNode,
    required this.onTap,
    required this.onFocusChange,
  });

  @override
  State<_CalendarDateCard> createState() => _CalendarDateCardState();
}

class _CalendarDateCardState extends State<_CalendarDateCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat('E').format(widget.date).toUpperCase();
    final dayNumber = widget.date.day.toString();

    final isHighlighted = widget.isSelected || _isFocused;

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        widget.onFocusChange(hasFocus);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select) {
            widget.onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Theme.of(context).colorScheme.primary
                : widget.isToday
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.3)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? Colors.white
                  : widget.isToday && !isHighlighted
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
              width: _isFocused ? 3 : 2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dayNumber,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isHighlighted
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (widget.hasContent) ...[
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHighlighted
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
