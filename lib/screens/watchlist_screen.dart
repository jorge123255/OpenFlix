import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../providers/multi_server_provider.dart';
import '../services/watchlist_service.dart';
import '../utils/provider_extensions.dart';
import '../i18n/strings.g.dart';
import 'media_detail_screen.dart';

/// Screen for viewing and managing the user's watchlist
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  WatchlistService? _watchlistService;
  bool _isLoading = true;
  WatchlistItemType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadWatchlistService();
  }

  Future<void> _loadWatchlistService() async {
    final service = await WatchlistService.getInstance();
    if (mounted) {
      setState(() {
        _watchlistService = service;
        _isLoading = false;
      });
    }
  }

  List<WatchlistItem> get _filteredItems {
    if (_selectedFilter == null) {
      return _watchlistService?.items ?? [];
    }
    return _watchlistService?.getItemsByType(_selectedFilter!) ?? [];
  }

  Future<void> _navigateToItem(WatchlistItem item) async {
    final mediaItem = item.getMediaItem();
    if (mediaItem == null) return;

    // Check if the server is available
    final multiServerProvider = Provider.of<MultiServerProvider>(
      context,
      listen: false,
    );
    if (!multiServerProvider.hasConnectedServers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.errors.noClientAvailable)),
      );
      return;
    }

    // Navigate to media detail
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(metadata: mediaItem),
      ),
    );
  }

  Future<void> _confirmRemoveItem(WatchlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.watchlist.removeTitle),
        content: Text(t.watchlist.removeConfirm(title: item.displayTitle)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.common.remove),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _watchlistService?.removeFromWatchlist(item.ratingKey, item.serverId);
      setState(() {});
    }
  }

  Future<void> _confirmClearAll() async {
    final itemCount = _watchlistService?.items.length ?? 0;
    if (itemCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.watchlist.clearAllTitle),
        content: Text(t.watchlist.clearAllConfirm(count: itemCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.watchlist.clearAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _watchlistService?.clearWatchlist();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _filteredItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.watchlist.title),
        actions: [
          if ((items.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: t.watchlist.clearAll,
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(isDark),
          // Content
          Expanded(
            child: items.isEmpty
                ? _buildEmptyState()
                : _buildItemsList(items, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: t.watchlist.all,
              isSelected: _selectedFilter == null,
              onSelected: () => setState(() => _selectedFilter = null),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: t.watchlist.movies,
              isSelected: _selectedFilter == WatchlistItemType.movie,
              onSelected: () => setState(() => _selectedFilter = WatchlistItemType.movie),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: t.watchlist.shows,
              isSelected: _selectedFilter == WatchlistItemType.show,
              onSelected: () => setState(() => _selectedFilter = WatchlistItemType.show),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: t.watchlist.episodes,
              isSelected: _selectedFilter == WatchlistItemType.episode,
              onSelected: () => setState(() => _selectedFilter = WatchlistItemType.episode),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : (isDark ? Colors.white70 : Colors.black87),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter != null
                ? t.watchlist.noItemsFiltered
                : t.watchlist.empty,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (_selectedFilter == null) ...[
            const SizedBox(height: 8),
            Text(
              t.watchlist.emptyHint,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList(List<WatchlistItem> items, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _WatchlistItemTile(
          item: item,
          isDark: isDark,
          onTap: () => _navigateToItem(item),
          onRemove: () => _confirmRemoveItem(item),
        );
      },
    );
  }
}

class _WatchlistItemTile extends StatelessWidget {
  final WatchlistItem item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _WatchlistItemTile({
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onRemove,
  });

  String get _typeIcon {
    switch (item.type) {
      case WatchlistItemType.movie:
        return '🎬';
      case WatchlistItemType.show:
        return '📺';
      case WatchlistItemType.episode:
        return '📝';
    }
  }

  @override
  Widget build(BuildContext context) {
    final multiServer = Provider.of<MultiServerProvider>(context, listen: false);
    String? thumbUrl;
    if (item.thumbUrl != null && multiServer.hasConnectedServers) {
      try {
        final client = context.getClientForServer(item.serverId);
        thumbUrl = client.getThumbnailUrl(item.thumbUrl!);
      } catch (e) {
        thumbUrl = null;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 120,
                  child: thumbUrl != null
                      ? CachedNetworkImage(
                          imageUrl: thumbUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.movie, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_typeIcon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.displayTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.type == WatchlistItemType.episode) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatAddedDate(item.addedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                icon: const Icon(Icons.bookmark_remove),
                color: Colors.red[400],
                tooltip: t.watchlist.remove,
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAddedDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return t.watchlist.addedToday;
    } else if (diff.inDays == 1) {
      return t.watchlist.addedYesterday;
    } else if (diff.inDays < 7) {
      return t.watchlist.addedDaysAgo(days: diff.inDays);
    } else {
      return t.watchlist.addedOn(
        date: '${date.day}/${date.month}/${date.year}',
      );
    }
  }
}
