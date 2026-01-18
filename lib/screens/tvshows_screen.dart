import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../utils/video_player_navigation.dart';
import 'main_screen.dart';
import 'all_media_screen.dart';

/// TV Shows screen showing only TV show content
class TVShowsScreen extends StatefulWidget {
  const TVShowsScreen({super.key});

  @override
  State<TVShowsScreen> createState() => TVShowsScreenState();
}

class TVShowsScreenState extends State<TVShowsScreen>
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
  List<MediaItem> _continueWatching = [];
  List<Hub> _showHubs = [];
  List<Library> _showLibraries = [];
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

      final newContinueWatching = <MediaItem>[];
      for (final serverId in multiServerProvider.onlineServerIds) {
        try {
          final serverClient = context.getClientForServer(serverId);
          final onDeckItems = await serverClient.getOnDeck();
          final showOnDeck = onDeckItems.where(
            (item) => item.type == 'episode',
          );
          newContinueWatching.addAll(showOnDeck);
        } catch (e) {
          appLogger.e('Failed to refresh on deck for server $serverId', error: e);
        }
      }

      if (mounted) {
        setState(() {
          _continueWatching = newContinueWatching.take(20).toList();
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

    // Update in continue watching
    final watchingIndex = _continueWatching.indexWhere(
      (item) => item.ratingKey == ratingKey,
    );
    if (watchingIndex != -1) {
      _continueWatching[watchingIndex] = updatedMetadata;
    }

    // Update in hub items
    for (final hub in _showHubs) {
      final hubIndex = hub.items.indexWhere(
        (item) => item.ratingKey == ratingKey,
      );
      if (hubIndex != -1) {
        hub.items[hubIndex] = updatedMetadata;
      }
    }
  }

  Future<void> _loadContent() async {
    appLogger.d('Loading TV shows content');
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

      // Get all libraries and filter for shows
      final allLibraries =
          await multiServerProvider.aggregationService.getLibrariesFromAllServers();
      _showLibraries = allLibraries.where((lib) => lib.type == 'show').toList();

      if (_showLibraries.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No TV show libraries found';
        });
        return;
      }

      // Get hubs filtered for show libraries
      final allHubs =
          await multiServerProvider.aggregationService.getHubsFromAllServers();

      // Filter hubs to only include those from show libraries
      _showHubs = allHubs.where((hub) {
        // Filter out continue watching type hubs (we'll handle separately)
        final hubId = hub.hubIdentifier?.toLowerCase() ?? '';
        if (hubId.contains('ondeck') || hubId.contains('continue')) {
          return false;
        }
        // Check if hub items are shows or episodes
        if (hub.items.isNotEmpty) {
          final type = hub.items.first.type;
          return type == 'show' || type == 'episode' || type == 'season';
        }
        return false;
      }).toList();

      // Get recently added shows and continue watching from all show libraries
      _recentlyAdded = [];
      _continueWatching = [];

      for (final library in _showLibraries) {
        final serverId = library.serverId;
        if (serverId == null) continue;

        try {
          final serverClient = context.getClientForServer(serverId);

          // Get recently added shows
          final recentItems = await serverClient.getLibraryContent(
            library.key,
            size: 20,
            filters: {'sort': 'addedAt:desc'},
          );
          _recentlyAdded.addAll(recentItems);

          // Get on deck (continue watching) episodes
          final onDeckItems = await serverClient.getOnDeck();
          final showOnDeck = onDeckItems.where(
            (item) => item.type == 'episode',
          );
          _continueWatching.addAll(showOnDeck);
        } catch (e) {
          appLogger.e('Failed to load from library ${library.title}', error: e);
        }
      }

      // Sort by addedAt
      _recentlyAdded.sort((a, b) => (b.addedAt ?? 0).compareTo(a.addedAt ?? 0));
      _recentlyAdded = _recentlyAdded.take(20).toList();

      // Extract genres
      _availableGenres = _extractGenresFromHubs(_showHubs);

      setState(() {
        _isLoading = false;
      });

      appLogger.d(
        'TV Shows loaded: ${_recentlyAdded.length} recent, ${_showHubs.length} hubs',
      );
    } catch (e) {
      appLogger.e('Failed to load TV shows content', error: e);
      setState(() {
        _errorMessage = 'Failed to load TV shows: $e';
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
      if (title.contains('crime')) genres.add('Crime');
      if (title.contains('thriller')) genres.add('Thriller');
      if (title.contains('sci-fi') || title.contains('science fiction')) {
        genres.add('Sci-Fi');
      }
      if (title.contains('reality')) genres.add('Reality');
      if (title.contains('documentary')) genres.add('Documentary');
      if (title.contains('animation') || title.contains('animated')) {
        genres.add('Animation');
      }
      if (title.contains('family')) genres.add('Family');
      if (title.contains('kids')) genres.add('Kids');
    }
    return genres.toList()..sort();
  }

  IconData _getHubIcon(String title) {
    final titleLower = title.toLowerCase();
    if (titleLower.contains('action')) return Icons.flash_on;
    if (titleLower.contains('comedy')) return Icons.mood;
    if (titleLower.contains('drama')) return Icons.theater_comedy;
    if (titleLower.contains('crime')) return Icons.gavel;
    if (titleLower.contains('thriller')) return Icons.warning_amber;
    if (titleLower.contains('sci-fi') || titleLower.contains('science')) {
      return Icons.rocket_launch;
    }
    if (titleLower.contains('reality')) return Icons.videocam;
    if (titleLower.contains('documentary')) return Icons.movie_filter;
    if (titleLower.contains('animation')) return Icons.animation;
    if (titleLower.contains('family')) return Icons.family_restroom;
    if (titleLower.contains('kids')) return Icons.child_care;
    if (titleLower.contains('recently')) return Icons.schedule;
    if (titleLower.contains('popular')) return Icons.trending_up;
    if (titleLower.contains('recommended')) return Icons.recommend;
    return Icons.tv;
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
                  title: Text(t.navigation.tvShows),
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
                  if (_showLibraries.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildBrowseAllSection(),
                    ),
                  // Continue Watching Episodes
                  if (_continueWatching.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildContinueWatchingSection(),
                    ),
                  // Recently Added Shows
                  if (_recentlyAdded.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildSection(
                        title: t.discover.recentlyAdded,
                        items: _recentlyAdded,
                        icon: Icons.new_releases,
                      ),
                    ),
                  // Show Hubs (genre collections, etc.)
                  ..._showHubs.asMap().entries.map((entry) {
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
          // Navigate to all shows screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllMediaScreen(
                libraries: _showLibraries,
                title: t.navigation.tvShows,
                mediaType: 'show',
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
                theme.colorScheme.secondaryContainer,
                theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withValues(alpha: 0.2),
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
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tv_outlined,
                  color: theme.colorScheme.onSecondary,
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
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.navigation.tvShows,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSecondaryContainer,
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

  Widget _buildContinueWatchingSection() {
    if (_continueWatching.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline, size: 20),
              const SizedBox(width: 8),
              Text(
                t.discover.continueWatching,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _continueWatching.length,
            itemBuilder: (context, index) {
              final item = _continueWatching[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 160,
                  child: _buildEpisodeCard(item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeCard(MediaItem episode) {
    // Get the client for this episode's server
    final serverClient = episode.serverId != null
        ? context.getClientForServer(episode.serverId!)
        : client;

    // Show episode thumbnail with show info
    return GestureDetector(
      onTap: () => navigateToVideoPlayer(context, metadata: episode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Episode thumbnail with progress bar
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (episode.thumb != null)
                    CachedNetworkImage(
                      imageUrl: serverClient.getThumbnailUrl(episode.thumb),
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.tv, color: Colors.white54),
                      ),
                    ),
                  // Progress bar
                  if (episode.viewOffset != null && episode.duration != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: episode.viewOffset! / episode.duration!,
                        backgroundColor: Colors.black54,
                        valueColor: const AlwaysStoppedAnimation(Colors.red),
                        minHeight: 3,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Show title
          Text(
            episode.grandparentTitle ?? episode.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Episode info
          Text(
            episode.parentIndex != null && episode.index != null
                ? 'S${episode.parentIndex} E${episode.index}'
                : episode.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
                  child: MediaCard(
                    item: item,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
