import 'dart:ui';
import 'package:flutter/material.dart';

import '../../models/livetv_channel.dart';
import 'channel_list_item.dart';

/// Mini channel guide overlay that slides up from bottom
/// Shows a quick scrollable list of channels with current programs
class MiniChannelGuideOverlay extends StatefulWidget {
  final List<LiveTVChannel> channels;
  final LiveTVChannel currentChannel;
  final bool favoritesFilterActive;
  final Function(LiveTVChannel) onChannelSelected;
  final VoidCallback onClose;
  final VoidCallback onToggleFavoritesFilter;

  const MiniChannelGuideOverlay({
    super.key,
    required this.channels,
    required this.currentChannel,
    this.favoritesFilterActive = false,
    required this.onChannelSelected,
    required this.onClose,
    required this.onToggleFavoritesFilter,
  });

  @override
  State<MiniChannelGuideOverlay> createState() =>
      _MiniChannelGuideOverlayState();
}

class _MiniChannelGuideOverlayState extends State<MiniChannelGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  // Vibrant accent colors
  static const _accentColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFF14B8A6), // Teal
    Color(0xFFEF4444), // Red
  ];

  Color _getChannelColor(String name) {
    return _accentColors[name.hashCode.abs() % _accentColors.length];
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Auto-scroll to current channel after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentChannel();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentChannel() {
    // Filter channels if favorites filter is active
    final displayChannels = widget.favoritesFilterActive
        ? widget.channels.where((c) => c.isFavorite).toList()
        : widget.channels;

    final currentIndex = displayChannels.indexWhere(
      (c) => c.id == widget.currentChannel.id,
    );

    if (currentIndex >= 0 && _scrollController.hasClients) {
      // Calculate scroll position to center the current channel
      const itemHeight = 96.0; // Approximate height of channel list item
      final scrollPosition = (currentIndex * itemHeight) -
          (MediaQuery.of(context).size.height * 0.35);

      _scrollController.animateTo(
        scrollPosition.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _close() async {
    await _animationController.reverse();
    widget.onClose();
  }

  void _selectChannel(LiveTVChannel channel) {
    widget.onChannelSelected(channel);
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final overlayHeight = size.height * 0.7;

    // Filter channels if favorites filter is active
    final displayChannels = widget.favoritesFilterActive
        ? widget.channels.where((c) => c.isFavorite).toList()
        : widget.channels;

    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping the guide
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  height: overlayHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1F2937),
                        Color(0xFF111827),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: -5,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.live_tv_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Channel Guide',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: widget.favoritesFilterActive
                                              ? Colors.amber.withValues(alpha: 0.2)
                                              : Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          widget.favoritesFilterActive
                                              ? '${displayChannels.length} favorites'
                                              : '${displayChannels.length} channels',
                                          style: TextStyle(
                                            color: widget.favoritesFilterActive
                                                ? Colors.amber
                                                : Colors.white.withValues(alpha: 0.6),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Favorites filter toggle
                            _buildHeaderButton(
                              icon: widget.favoritesFilterActive
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              isActive: widget.favoritesFilterActive,
                              activeColor: Colors.amber,
                              onTap: widget.onToggleFavoritesFilter,
                            ),
                            const SizedBox(width: 8),
                            _buildHeaderButton(
                              icon: Icons.close_rounded,
                              onTap: _close,
                            ),
                          ],
                        ),
                      ),
                      // Channel list
                      Expanded(
                        child: displayChannels.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: displayChannels.length,
                                itemBuilder: (context, index) {
                                  final channel = displayChannels[index];
                                  final isCurrentChannel =
                                      channel.id == widget.currentChannel.id;

                                  return ChannelListItem(
                                    channel: channel,
                                    isCurrentChannel: isCurrentChannel,
                                    accentColor: _getChannelColor(channel.name),
                                    onTap: () => _selectChannel(channel),
                                  );
                                },
                              ),
                      ),
                      // Footer hint
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                            ],
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tap to select',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swipe_down_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Swipe to close',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: isActive && activeColor != null
                ? LinearGradient(
                    colors: [
                      activeColor.withValues(alpha: 0.3),
                      activeColor.withValues(alpha: 0.15),
                    ],
                  )
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive && activeColor != null
                  ? activeColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: isActive && activeColor != null
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isActive && activeColor != null
                ? activeColor
                : Colors.white.withValues(alpha: 0.7),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.favoritesFilterActive ? Icons.star_outline : Icons.tv_off,
            size: 64,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            widget.favoritesFilterActive
                ? 'No favorite channels'
                : 'No channels available',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
            ),
          ),
          if (widget.favoritesFilterActive) ...[
            const SizedBox(height: 8),
            Text(
              'Press F to show all channels',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
