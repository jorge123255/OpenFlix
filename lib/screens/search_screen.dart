import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../i18n/strings.g.dart';
import 'main_screen.dart';
import '../mixins/refreshable.dart';
import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';
import '../utils/grid_cross_axis_extent.dart';
import '../utils/keyboard_utils.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/focus/focus_indicator.dart';
import '../widgets/media_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with Refreshable {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode(debugLabel: 'SearchInput');
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  late final Debounce _searchDebounce;
  String _lastSearchedQuery = '';

  // Search improvements
  List<String> _recentSearches = [];
  String _selectedCategory = 'all';
  static const _maxRecentSearches = 10;
  static const List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All', 'icon': Icons.apps},
    {'id': 'movie', 'label': 'Movies', 'icon': Icons.movie},
    {'id': 'show', 'label': 'TV Shows', 'icon': Icons.tv},
    {'id': 'artist', 'label': 'Music', 'icon': Icons.music_note},
  ];

  // Voice search
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _searchDebounce = debounce(
      _performSearch,
      const Duration(milliseconds: 500),
    );
    _searchController.addListener(_onSearchChanged);
    _loadRecentSearches();
    _initSpeech();
    // Focus the search input when the screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _initSpeech() async {
    // Only initialize on mobile platforms
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _speech = stt.SpeechToText();
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          appLogger.e('Speech recognition error: $error');
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatus: (status) {
          appLogger.d('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      appLogger.e('Failed to initialize speech: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _searchController.text = result.recognizedWords;
          _performSearch(result.recognizedWords);
          setState(() => _isListening = false);
        } else {
          // Show interim results
          _searchController.text = result.recognizedWords;
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _loadRecentSearches() async {
    final settings = await SettingsService.getInstance();
    final searches = settings.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = searches;
      });
    }
  }

  Future<void> _addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final trimmed = query.trim();
    // Remove if already exists, then add at the start
    _recentSearches.remove(trimmed);
    _recentSearches.insert(0, trimmed);
    // Keep only max items
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
    }

    final settings = await SettingsService.getInstance();
    await settings.setRecentSearches(_recentSearches);
  }

  Future<void> _removeRecentSearch(String query) async {
    setState(() {
      _recentSearches.remove(query);
    });
    final settings = await SettingsService.getInstance();
    await settings.setRecentSearches(_recentSearches);
  }

  Future<void> _clearRecentSearches() async {
    setState(() {
      _recentSearches.clear();
    });
    final settings = await SettingsService.getInstance();
    await settings.setRecentSearches([]);
  }

  void _selectRecentSearch(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  List<MediaItem> get _filteredResults {
    if (_selectedCategory == 'all') return _searchResults;
    return _searchResults.where((item) {
      final type = item.type.toLowerCase();
      return type == _selectedCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchDebounce.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;

    if (query.trim().isEmpty) {
      _searchDebounce.cancel();
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isSearching = false;
        _lastSearchedQuery = '';
      });
      return;
    }

    // Only search if the query has actually changed
    if (query.trim() == _lastSearchedQuery.trim()) {
      return;
    }

    _searchDebounce([query]);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );

      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }

      // Search across all connected servers
      final results = await multiServerProvider.aggregationService
          .searchAcrossServers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _lastSearchedQuery = query.trim();
        });
        // Save to recent searches
        await _addRecentSearch(query.trim());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.errors.searchFailed(error: e))),
        );
      }
    }
  }

  @override
  void refresh() {
    // Re-run the current search if there is one
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Focus the search input field
  void focusSearchInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  // Public method to fully reload all content (for profile switches)
  void fullRefresh() {
    appLogger.d(
      'SearchScreen.fullRefresh() called - clearing search and reloading',
    );
    // Clear search results and search text for new profile
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _isSearching = false;
      _hasSearched = false;
      _lastSearchedQuery = '';
    });
  }

  void updateItem(String ratingKey) {
    // Trigger a refresh of the search to get updated metadata
    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  /// Handle back key press - focus bottom navigation
  KeyEventResult _handleBackKey(FocusNode node, KeyEvent event) {
    if (isBackKeyEvent(event)) {
      BackNavigationScope.of(context)?.focusBottomNav();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Focus(
          onKeyEvent: _handleBackKey,
          child: CustomScrollView(
            slivers: [
              DesktopSliverAppBar(
                title: Text(t.screens.search),
                floating: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            hintText: t.search.hint,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      // State update handled by listener
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      // Voice search button (mobile only)
                      if (_speechAvailable) ...[
                        const SizedBox(width: 8),
                        _VoiceSearchButton(
                          isListening: _isListening,
                          onPressed: _isListening ? _stopListening : _startListening,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Category filter chips (show when there are results)
              if (_hasSearched && _searchResults.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildCategoryFilters(),
                ),
              if (_isSearching)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!_hasSearched)
                // Show recent searches or empty state
                _recentSearches.isNotEmpty
                    ? SliverToBoxAdapter(child: _buildRecentSearches())
                    : SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t.search.searchYourMedia,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.search.enterTitleActorOrKeyword,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      )
              else if (_searchResults.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.messages.noResultsFound,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t.search.tryDifferentTerm,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Consumer<SettingsProvider>(
                  builder: (context, settingsProvider, child) {
                    final results = _filteredResults;
                    if (results.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No ${_selectedCategory == "all" ? "" : _categories.firstWhere((c) => c["id"] == _selectedCategory)["label"]} results found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }
                    if (settingsProvider.viewMode == ViewMode.list) {
                      return SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = results[index];
                            return MediaCard(
                              key: Key(item.ratingKey),
                              item: item,
                              onRefresh: updateItem,
                            );
                          }, childCount: results.length),
                        ),
                      );
                    } else {
                      return SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent:
                                    getMaxCrossAxisExtentWithPadding(
                                      context,
                                      settingsProvider.libraryDensity,
                                      32,
                                    ),
                                childAspectRatio: 2 / 3.3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = results[index];
                            return MediaCard(
                              key: Key(item.ratingKey),
                              item: item,
                              onRefresh: updateItem,
                            );
                          }, childCount: results.length),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category['id'];
            // Count items for this category
            final count = category['id'] == 'all'
                ? _searchResults.length
                : _searchResults
                    .where((item) =>
                        item.type.toLowerCase() == category['id'])
                    .length;

            if (count == 0 && category['id'] != 'all') {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 6),
                    Text('${category['label']} ($count)'),
                  ],
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category['id'] as String;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t.search.recentSearches,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: Text(t.search.clear),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) {
              return InputChip(
                label: Text(search),
                onPressed: () => _selectRecentSearch(search),
                onDeleted: () => _removeRecentSearch(search),
                deleteIcon: const Icon(Icons.close, size: 16),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Animated voice search button
class _VoiceSearchButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const _VoiceSearchButton({
    required this.isListening,
    required this.onPressed,
  });

  @override
  State<_VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<_VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(_VoiceSearchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: FocusIndicator(
        isFocused: _isFocused,
        borderRadius: 28,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isListening ? _scaleAnimation.value : 1.0,
              child: child,
            );
          },
          child: Material(
            color: widget.isListening
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: Icon(
                  widget.isListening ? Icons.mic : Icons.mic_none,
                  color: widget.isListening
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
