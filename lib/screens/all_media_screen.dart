import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/library.dart';
import '../models/media_item.dart';
import '../widgets/media_card.dart';
import '../widgets/desktop_app_bar.dart';
import '../utils/app_logger.dart';
import '../utils/keyboard_utils.dart';
import '../utils/provider_extensions.dart';
import '../i18n/strings.g.dart';

/// Screen to browse all media items in a library with pagination
class AllMediaScreen extends StatefulWidget {
  final List<Library> libraries;
  final String title;
  final String mediaType; // 'movie' or 'show'

  const AllMediaScreen({
    super.key,
    required this.libraries,
    required this.title,
    required this.mediaType,
  });

  @override
  State<AllMediaScreen> createState() => _AllMediaScreenState();
}

class _AllMediaScreenState extends State<AllMediaScreen> {
  List<MediaItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 0;
  bool _hasMoreItems = true;
  static const int _pageSize = 100;
  CancelToken? _cancelToken;

  // Sorting
  String _sortField = 'titleSort';
  bool _sortDescending = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreItems();
    }
  }

  /// Handle back key press
  KeyEventResult _handleBackKey(FocusNode node, KeyEvent event) {
    if (isBackKeyEvent(event)) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _loadContent() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _items = [];
      _currentPage = 0;
      _hasMoreItems = true;
    });

    try {
      final allItems = <MediaItem>[];

      for (final library in widget.libraries) {
        final serverId = library.serverId;
        if (serverId == null) continue;

        try {
          final client = context.getClientForServer(serverId);
          final items = await client.getLibraryContent(
            library.key,
            size: _pageSize,
            start: 0,
            filters: {
              'sort': '$_sortField:${_sortDescending ? 'desc' : 'asc'}',
              if (_searchQuery.isNotEmpty) 'title': _searchQuery,
            },
          );
          allItems.addAll(items);
        } catch (e) {
          appLogger.e('Failed to load from library ${library.title}', error: e);
        }
      }

      // Sort combined results
      allItems.sort((a, b) {
        int result;
        switch (_sortField) {
          case 'titleSort':
            result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
            break;
          case 'addedAt':
            result = (a.addedAt ?? 0).compareTo(b.addedAt ?? 0);
            break;
          case 'year':
            result = (a.year ?? 0).compareTo(b.year ?? 0);
            break;
          case 'rating':
            result = (a.rating ?? 0).compareTo(b.rating ?? 0);
            break;
          default:
            result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
        return _sortDescending ? -result : result;
      });

      setState(() {
        _items = allItems;
        _isLoading = false;
        _hasMoreItems = allItems.length >= _pageSize;
      });

      appLogger.d('Loaded ${allItems.length} ${widget.mediaType} items');
    } catch (e) {
      appLogger.e('Failed to load content', error: e);
      setState(() {
        _errorMessage = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMoreItems) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    final start = _currentPage * _pageSize;

    try {
      final newItems = <MediaItem>[];

      for (final library in widget.libraries) {
        final serverId = library.serverId;
        if (serverId == null) continue;

        try {
          final client = context.getClientForServer(serverId);
          final items = await client.getLibraryContent(
            library.key,
            size: _pageSize,
            start: start,
            filters: {
              'sort': '$_sortField:${_sortDescending ? 'desc' : 'asc'}',
              if (_searchQuery.isNotEmpty) 'title': _searchQuery,
            },
          );
          newItems.addAll(items);
        } catch (e) {
          appLogger.e('Failed to load more from library ${library.title}', error: e);
        }
      }

      setState(() {
        _items.addAll(newItems);
        _isLoadingMore = false;
        _hasMoreItems = newItems.length >= _pageSize;
      });
    } catch (e) {
      appLogger.e('Failed to load more items', error: e);
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onSortChanged(String field, bool descending) {
    setState(() {
      _sortField = field;
      _sortDescending = descending;
    });
    _loadContent();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadContent();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: Text(t.libraries.sortByTitle),
              trailing: _sortField == 'titleSort'
                  ? Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward)
                  : null,
              selected: _sortField == 'titleSort',
              onTap: () {
                Navigator.pop(context);
                _onSortChanged('titleSort', _sortField == 'titleSort' ? !_sortDescending : false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(t.libraries.sortByDateAdded),
              trailing: _sortField == 'addedAt'
                  ? Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward)
                  : null,
              selected: _sortField == 'addedAt',
              onTap: () {
                Navigator.pop(context);
                _onSortChanged('addedAt', _sortField == 'addedAt' ? !_sortDescending : true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: Text(t.libraries.sortByYear),
              trailing: _sortField == 'year'
                  ? Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward)
                  : null,
              selected: _sortField == 'year',
              onTap: () {
                Navigator.pop(context);
                _onSortChanged('year', _sortField == 'year' ? !_sortDescending : true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: Text(t.libraries.sortByRating),
              trailing: _sortField == 'rating'
                  ? Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward)
                  : null,
              selected: _sortField == 'rating',
              onTap: () {
                Navigator.pop(context);
                _onSortChanged('rating', _sortField == 'rating' ? !_sortDescending : true);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 160).floor().clamp(2, 8);

    return Scaffold(
      body: SafeArea(
        child: Focus(
          onKeyEvent: _handleBackKey,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              DesktopSliverAppBar(
                title: Text(widget.title),
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                scrolledUnderElevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: _showSortOptions,
                    tooltip: t.libraries.sort,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadContent,
                  ),
                ],
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: t.search.hint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    onSubmitted: _onSearch,
                    onChanged: (value) {
                      // Debounced search
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchController.text == value) {
                          _onSearch(value);
                        }
                      });
                    },
                  ),
                ),
              ),
              // Results count
              if (!_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      '${_items.length}${_hasMoreItems ? '+' : ''} ${widget.mediaType == 'movie' ? t.navigation.movies : t.navigation.tvShows}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  ),
                ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadContent,
                          child: Text(t.common.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_isLoading && _errorMessage == null && _items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.mediaType == 'movie' ? Icons.movie_outlined : Icons.tv_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(t.discover.noContentAvailable),
                      ],
                    ),
                  ),
                ),
              if (!_isLoading && _errorMessage == null && _items.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _items[index];
                        return MediaCard(item: item);
                      },
                      childCount: _items.length,
                    ),
                  ),
                ),
              // Loading indicator for infinite scroll
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
