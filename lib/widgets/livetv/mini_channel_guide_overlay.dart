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
        color: Colors.black54,
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
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.view_list,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
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
                                  ),
                                ),
                                Text(
                                  widget.favoritesFilterActive
                                      ? '${displayChannels.length} favorites'
                                      : '${displayChannels.length} channels',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Favorites filter toggle
                          IconButton(
                            onPressed: widget.onToggleFavoritesFilter,
                            icon: Icon(
                              widget.favoritesFilterActive
                                  ? Icons.star
                                  : Icons.star_outline,
                              color: widget.favoritesFilterActive
                                  ? Colors.amber
                                  : Colors.white70,
                            ),
                            tooltip: widget.favoritesFilterActive
                                ? 'Show All Channels (F)'
                                : 'Show Favorites Only (F)',
                          ),
                          IconButton(
                            onPressed: _close,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            tooltip: 'Close (Esc)',
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
                              padding: EdgeInsets.zero,
                              itemCount: displayChannels.length,
                              itemBuilder: (context, index) {
                                final channel = displayChannels[index];
                                final isCurrentChannel =
                                    channel.id == widget.currentChannel.id;

                                return ChannelListItem(
                                  channel: channel,
                                  isCurrentChannel: isCurrentChannel,
                                  onTap: () => _selectChannel(channel),
                                );
                              },
                            ),
                    ),
                    // Footer hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to select • Swipe down to close',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
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
