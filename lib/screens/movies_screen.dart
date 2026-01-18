import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../client/media_client.dart';
import '../models/media_item.dart';
import '../models/hub.dart';
import '../models/library.dart';
import '../providers/multi_server_provider.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/hub_section.dart';
import '../widgets/hub_navigation_controller.dart';
import '../widgets/media_card.dart';
import '../mixins/refreshable.dart';
import '../mixins/item_updatable.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/keyboard_utils.dart';
import '../utils/provider_extensions.dart';
import 'main_screen.dart';
import 'all_media_screen.dart';

/// Movies screen showing only movie content
class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => MoviesScreenState();
}

class MoviesScreenState extends State<MoviesScreen>
    with Refreshable, ItemUpdatable {
  @override
  MediaClient get client {
    final multiServerProvider = Provider.of<MultiServerProvider>(
      context,
      listen: false,
    );
    if (!multiServerProvider.hasConnectedServers) {
      throw Exception('No servers available');
    }
    return context.getClientForServer(
      multiServerProvider.onlineServerIds.first,
    );
  }

  List<MediaItem> _recentlyAdded = [];
  List<MediaItem> _recentlyWatched = [];
  List<Hub> _movieHubs = [];
  List<Library> _movieLibraries = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  final HubNavigationController _hubNavigationController =
      HubNavigationController();

  // Genre filter
  String? _selectedGenre;
  List<String> _availableGenres = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hubNavigationController.dispose();
    super.dispose();
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
  void refresh() {
    // Light refresh - just refresh continue watching
    _refreshContinueWatching();
  }

  /// Public method for full refresh
  void fullRefresh() {
    _loadContent();
  }

  Future<void> _refreshContinueWatching() async {
    if (!mounted) return;

    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );
      if (!multiServerProvider.hasConnectedServers) return;

      final newRecentlyWatched = <MediaItem>[];
      for (final serverId in multiServerProvider.onlineServerIds) {
        try {
          final serverClient = context.getClientForServer(serverId);
          final onDeckItems = await serverClient.getOnDeck();
          final movieOnDeck = onDeckItems.where((item) => item.type == 'movie');
          newRecentlyWatched.addAll(movieOnDeck);
        } catch (e) {
          appLogger.e('Failed to refresh on deck for server $serverId', error: e);
        }
      }

      if (mounted) {
        setState(() {
          _recentlyWatched = newRecentlyWatched.take(20).toList();
        });
      }
    } catch (e) {
      appLogger.e('Failed to refresh continue watching', error: e);
    }
  }

  @override
  void updateItemInLists(String ratingKey, MediaItem updatedMetadata) {
    // Update in recently added
    final recentIndex = _recentlyAdded.indexWhere(
      (item) => item.ratingKey == ratingKey,
    );
    if (recentIndex != -1) {
      _recentlyAdded[recentIndex] = updatedMetadata;
    }

    // Update in recently watched
    final watchedIndex = _recentlyWatched.indexWhere(
      (item) => item.ratingKey == ratingKey,
    );
    if (watchedIndex != -1) {
      _recentlyWatched[watchedIndex] = updatedMetadata;
    }

    // Update in hub items
    for (final hub in _movieHubs) {
      final hubIndex = hub.items.indexWhere(
        (item) => item.ratingKey == ratingKey,
      );
      if (hubIndex != -1) {
        hub.items[hubIndex] = updatedMetadata;
      }
    }
  }

  Future<void> _loadContent() async {
    appLogger.d('Loading movies content');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );

      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }

      // Get all libraries and filter for movies
      final allLibraries =
          await multiServerProvider.aggregationService.getLibrariesFromAllServers();
      _movieLibraries = allLibraries.where((lib) => lib.type == 'movie').toList();

      if (_movieLibraries.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No movie libraries found';
        });
        return;
      }

      // Get hubs filtered for movie libraries
      final allHubs =
          await multiServerProvider.aggregationService.getHubsFromAllServers();

      // Filter hubs to only include those from movie libraries
      _movieHubs = allHubs.where((hub) {
        // Filter out continue watching type hubs (we'll handle separately)
        final hubId = hub.hubIdentifier?.toLowerCase() ?? '';
        if (hubId.contains('ondeck') || hubId.contains('continue')) {
          return false;
        }
        // Check if hub items are movies
        if (hub.items.isNotEmpty) {
          return hub.items.first.type == 'movie';
        }
        return false;
      }).toList();

      // Get recently added movies from all movie libraries
      _recentlyAdded = [];
      _recentlyWatched = [];

      for (final library in _movieLibraries) {
        final serverId = library.serverId;
        if (serverId == null) continue;

        try {
          final serverClient = context.getClientForServer(serverId);

          // Get recently added (using size parameter for limit)
          final recentItems = await serverClient.getLibraryContent(
            library.key,
            size: 20,
            filters: {'sort': 'addedAt:desc'},
          );
          _recentlyAdded.addAll(recentItems);

          // Get recently watched (on deck)
          final onDeckItems = await serverClient.getOnDeck();
          final movieOnDeck = onDeckItems.where((item) => item.type == 'movie');
          _recentlyWatched.addAll(movieOnDeck);
        } catch (e) {
          appLogger.e('Failed to load from library ${library.title}', error: e);
        }
      }

      // Sort by addedAt
      _recentlyAdded.sort((a, b) => (b.addedAt ?? 0).compareTo(a.addedAt ?? 0));
      _recentlyAdded = _recentlyAdded.take(20).toList();

      // Extract genres
      _availableGenres = _extractGenresFromHubs(_movieHubs);

      setState(() {
        _isLoading = false;
      });

      appLogger.d(
        'Movies loaded: ${_recentlyAdded.length} recent, ${_movieHubs.length} hubs',
      );
    } catch (e) {
      appLogger.e('Failed to load movies content', error: e);
      setState(() {
        _errorMessage = 'Failed to load movies: $e';
        _isLoading = false;
      });
    }
  }

  List<String> _extractGenresFromHubs(List<Hub> hubs) {
    final genres = <String>{};
    for (final hub in hubs) {
      final title = hub.title.toLowerCase();
      // Common genre keywords
      if (title.contains('action')) genres.add('Action');
      if (title.contains('comedy')) genres.add('Comedy');
      if (title.contains('drama')) genres.add('Drama');
      if (title.contains('horror')) genres.add('Horror');
      if (title.contains('thriller')) genres.add('Thriller');
      if (title.contains('sci-fi') || title.contains('science fiction')) {
        genres.add('Sci-Fi');
      }
      if (title.contains('romance')) genres.add('Romance');
      if (title.contains('documentary')) genres.add('Documentary');
      if (title.contains('animation') || title.contains('animated')) {
        genres.add('Animation');
      }
      if (title.contains('family')) genres.add('Family');
    }
    return genres.toList()..sort();
  }

  IconData _getHubIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('action')) return Icons.flash_on;
    if (titleLower.contains('comedy')) return Icons.mood;
    if (titleLower.contains('drama')) return Icons.theater_comedy;
    if (titleLower.contains('horror')) return Icons.nights_stay;
    if (titleLower.contains('thriller')) return Icons.warning_amber;
    if (titleLower.contains('sci-fi') || titleLower.contains('science')) {
      return Icons.rocket_launch;
    }
    if (titleLower.contains('romance')) return Icons.favorite;
    if (titleLower.contains('documentary')) return Icons.videocam;
    if (titleLower.contains('animation')) return Icons.animation;
    if (titleLower.contains('family')) return Icons.family_restroom;
    if (titleLower.contains('recently')) return Icons.schedule;
    if (titleLower.contains('popular')) return Icons.trending_up;
    if (titleLower.contains('recommended')) return Icons.recommend;
    return Icons.movie;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Focus(
          onKeyEvent: _handleBackKey,
          child: HubNavigationScope(
            controller: _hubNavigationController,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                DesktopSliverAppBar(
                  title: Text(t.navigation.movies),
                  floating: true,
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadContent,
                    ),
                  ],
                ),
                // Genre Filter Chips
                if (_availableGenres.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildGenreFilterChips(),
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
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
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
                if (!_isLoading && _errorMessage == null) ...[
                  // Browse All Section
                  if (_movieLibraries.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildBrowseAllSection(),
                    ),
                  // Continue Watching Movies
                  if (_recentlyWatched.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: t.discover.continueWatching,
                        items: _recentlyWatched,
                        icon: Icons.play_circle_outline,
                      ),
                    ),
                  // Recently Added Movies
                  if (_recentlyAdded.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: t.discover.recentlyAdded,
                        items: _recentlyAdded,
                        icon: Icons.new_releases,
                      ),
                    ),
                  // Movie Hubs (genre collections, etc.)
                  ..._movieHubs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final hub = entry.value;
                    // Filter by genre if selected
                    if (_selectedGenre != null) {
                      final hubTitle = hub.title.toLowerCase();
                      if (!hubTitle.contains(_selectedGenre!.toLowerCase())) {
                        return const SliverToBoxAdapter(child: SizedBox.shrink());
                      }
                    }
                    return SliverToBoxAdapter(
                      child: HubSection(
                        key: ValueKey(hub.title),
                        hub: hub,
                        icon: _getHubIcon(hub.title),
                        onRefresh: updateItem,
                        navigationOrder: index + 2,
                      ),
                    );
                  }),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrowseAllSection() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        onTap: () {
          // Navigate to all movies screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllMediaScreen(
                libraries: _movieLibraries,
                title: t.navigation.movies,
                mediaType: 'movie',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.movie_outlined,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.libraries.browseAll,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.navigation.movies,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _selectedGenre == null,
              onSelected: (selected) {
                setState(() {
                  _selectedGenre = null;
                });
              },
            ),
            const SizedBox(width: 8),
            ..._availableGenres.map((genre) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(genre),
                  selected: _selectedGenre == genre,
                  onSelected: (selected) {
                    setState(() {
                      _selectedGenre = selected ? genre : null;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<MediaItem> items,
    required IconData icon,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 130,
                  child: MediaCard(item: item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
