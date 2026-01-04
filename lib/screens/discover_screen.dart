import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../client/media_client.dart';
import '../models/media_item.dart';
import '../models/hub.dart';
import '../models/livetv_channel.dart';
import '../providers/multi_server_provider.dart';
import '../providers/server_state_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/hub_section.dart';
import '../widgets/hub_navigation_controller.dart';
import '../widgets/livetv_home_section.dart';
import '../widgets/top10_section.dart';
import '../widgets/featured_collection_section.dart';
import '../widgets/brand_hub_section.dart';
import '../widgets/your_next_watch_section.dart';
import '../widgets/continue_watching_section.dart';
import '../widgets/just_added_section.dart';
import '../widgets/mood_collection_section.dart';
import '../widgets/because_you_watched_section.dart';
import '../widgets/random_picker_button.dart';
import '../widgets/calendar_view_section.dart';
import 'profile_switch_screen.dart';
import 'profile_selection_screen.dart';
import '../services/storage_service.dart';
import '../providers/user_profile_provider.dart';
import '../providers/settings_provider.dart';
import '../mixins/refreshable.dart';
import '../i18n/strings.g.dart';
import '../mixins/item_updatable.dart';
import '../utils/app_logger.dart';
import '../utils/keyboard_utils.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../utils/content_rating_formatter.dart';
import 'auth_screen.dart';
import 'main_screen.dart';
import 'screensaver_screen.dart';
import 'channel_surfing_screen.dart';
import 'downloads_screen.dart';
import 'watchlist_screen.dart';
import 'virtual_channels_screen.dart';
import '../services/settings_service.dart';
import '../services/profile_storage_service.dart';
import '../widgets/voice_control_button.dart';
import '../services/voice_control_service.dart';
import '../services/last_watched_service.dart';
import '../widgets/docked_player.dart';
import 'livetv_player_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final VoidCallback? onBecameVisible;

  const DiscoverScreen({super.key, this.onBecameVisible});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with Refreshable, ItemUpdatable, SingleTickerProviderStateMixin {
  static const Duration _heroAutoScrollDuration = Duration(seconds: 8);

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

  List<MediaItem> _onDeck = [];
  List<Hub> _hubs = [];
  List<LiveTVChannel> _liveChannels = [];
  List<MediaItem> _nextWatchItems = [];
  List<MediaItem> _recentlyAdded = [];
  bool _isLoading = true;
  bool _isInitialLoad = true;
  String? _errorMessage;
  Timer? _liveTVRefreshTimer;
  final PageController _heroController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentHeroIndex = 0;
  Timer? _autoScrollTimer;
  late AnimationController _indicatorAnimationController;
  bool _isAutoScrollPaused = false;
  final HubNavigationController _hubNavigationController =
      HubNavigationController();
  late final FocusNode _heroFocusNode;
  bool _heroIsFocused = false;

  // Category filter for TV-friendly navigation
  String _selectedCategory = 'all';
  static const List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'All', 'icon': Icons.grid_view},
    {'id': 'movies', 'label': 'Movies', 'icon': Icons.movie},
    {'id': 'shows', 'label': 'TV Shows', 'icon': Icons.tv},
    {'id': 'live', 'label': 'Live TV', 'icon': Icons.live_tv},
  ];

  // Genre filter
  String? _selectedGenre;
  List<String> _availableGenres = [];

  // Screensaver idle timer
  Timer? _screensaverIdleTimer;
  bool _screensaverEnabled = true;
  int _screensaverIdleMinutes = 5;

  // Docked player
  final GlobalKey<DockedPlayerState> _dockedPlayerKey = GlobalKey();
  bool _dockedPlayerEnabled = true;
  LiveTVChannel? _lastWatchedChannel;

  // Common genre icons mapping
  static const Map<String, IconData> _genreIcons = {
    'action': Icons.flash_on,
    'adventure': Icons.explore,
    'animation': Icons.animation,
    'comedy': Icons.mood,
    'crime': Icons.gavel,
    'documentary': Icons.videocam,
    'drama': Icons.theater_comedy,
    'family': Icons.family_restroom,
    'fantasy': Icons.auto_fix_high,
    'history': Icons.history_edu,
    'horror': Icons.nights_stay,
    'music': Icons.music_note,
    'mystery': Icons.search,
    'romance': Icons.favorite,
    'science fiction': Icons.rocket_launch,
    'sci-fi': Icons.rocket_launch,
    'thriller': Icons.warning_amber,
    'war': Icons.military_tech,
    'western': Icons.landscape,
    'kids': Icons.child_care,
    'reality': Icons.tv,
    'talk show': Icons.mic,
    'news': Icons.newspaper,
    'sport': Icons.sports,
    'sports': Icons.sports,
  };

  /// Get the correct MediaClient for an item's server
  MediaClient _getClientForItem(MediaItem? item) {
    // Items should always have a serverId, but if not, fall back to first available server
    final serverId = item?.serverId;
    if (serverId == null) {
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
    return context.getClientForServer(serverId);
  }

  @override
  void initState() {
    super.initState();
    _indicatorAnimationController = AnimationController(
      vsync: this,
      duration: _heroAutoScrollDuration,
    );
    _heroFocusNode = FocusNode(debugLabel: 'HeroSection');
    _heroFocusNode.addListener(_handleHeroFocusChange);
    _loadContent();
    _startAutoScroll();
    _loadScreensaverSettings();
    _loadDockedPlayerSettings();
  }

  Future<void> _loadDockedPlayerSettings() async {
    final settings = await SettingsService.getInstance();
    final lastWatchedService = await LastWatchedService.getInstance();

    if (mounted) {
      setState(() {
        _dockedPlayerEnabled = settings.getDockedPlayerEnabled();
        _lastWatchedChannel = lastWatchedService.getLastWatchedChannel();
      });
    }
  }

  Future<void> _loadScreensaverSettings() async {
    final settings = await SettingsService.getInstance();
    if (mounted) {
      setState(() {
        _screensaverEnabled = settings.getScreensaverEnabled();
        _screensaverIdleMinutes = settings.getScreensaverIdleMinutes();
      });
      _resetScreensaverTimer();
    }
  }

  void _resetScreensaverTimer() {
    _screensaverIdleTimer?.cancel();
    if (!_screensaverEnabled || _screensaverIdleMinutes <= 0) return;

    _screensaverIdleTimer = Timer(
      Duration(minutes: _screensaverIdleMinutes),
      _launchScreensaver,
    );
  }

  void _launchScreensaver() {
    if (!mounted) return;

    // Collect all items for the screensaver slideshow
    final items = <MediaItem>[];
    items.addAll(_onDeck);
    items.addAll(_recentlyAdded);
    for (final hub in _hubs) {
      items.addAll(hub.items.take(10)); // Take up to 10 from each hub
    }

    // Need at least a few items for a good slideshow
    if (items.length < 3) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ScreensaverScreen(items: items),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    ).then((_) {
      // Reset timer when returning from screensaver
      _resetScreensaverTimer();
    });
  }

  /// Navigate to the live TV player for a channel
  void _navigateToLiveTVPlayer(LiveTVChannel channel) {
    // Stop the docked player before navigating
    _dockedPlayerKey.currentState?.stop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTVPlayerScreen(
          channel: channel,
          channels: _liveChannels.isNotEmpty ? _liveChannels : [channel],
        ),
      ),
    ).then((_) {
      // Reload docked player settings when returning
      _loadDockedPlayerSettings();
    });
  }

  void _handleHeroFocusChange() {
    if (_heroIsFocused != _heroFocusNode.hasFocus) {
      setState(() {
        _heroIsFocused = _heroFocusNode.hasFocus;
      });
      if (_heroFocusNode.hasFocus) {
        // Scroll to the very top when hero is focused
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
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

  KeyEventResult _handleHeroKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // Enter/Space to play current hero item
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.select ||
          event.logicalKey == LogicalKeyboardKey.gameButtonA) {
        if (_onDeck.isNotEmpty && _currentHeroIndex < _onDeck.length) {
          navigateToVideoPlayer(context, metadata: _onDeck[_currentHeroIndex]);
          return KeyEventResult.handled;
        }
      }

      // Left arrow to go to previous hero item
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_onDeck.isNotEmpty && _currentHeroIndex > 0) {
          _heroController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return KeyEventResult.handled;
        }
      }

      // Right arrow to go to next hero item
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_onDeck.isNotEmpty && _currentHeroIndex < _onDeck.length - 1) {
          _heroController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return KeyEventResult.handled;
        }
      }

      // Down arrow to navigate to first hub section
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        // Try to navigate to the first hub section
        if (_hubNavigationController.navigateToAdjacentHub('_hero_', 1)) {
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _liveTVRefreshTimer?.cancel();
    _screensaverIdleTimer?.cancel();
    _heroController.dispose();
    _scrollController.dispose();
    _indicatorAnimationController.dispose();
    _hubNavigationController.dispose();
    _heroFocusNode.removeListener(_handleHeroFocusChange);
    _heroFocusNode.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (_isAutoScrollPaused) return;

    _indicatorAnimationController.forward(from: 0.0);
    _autoScrollTimer = Timer.periodic(_heroAutoScrollDuration, (timer) {
      if (_onDeck.isEmpty ||
          !_heroController.hasClients ||
          _isAutoScrollPaused) {
        return;
      }

      // Validate current index is within bounds before calculating next page
      if (_currentHeroIndex >= _onDeck.length) {
        _currentHeroIndex = 0;
      }

      final nextPage = (_currentHeroIndex + 1) % _onDeck.length;
      _heroController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      // Wait for page transition to complete before resetting progress
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isAutoScrollPaused) {
          _indicatorAnimationController.forward(from: 0.0);
        }
      });
    });
  }

  void _resetAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _startAutoScroll();
  }

  void _pauseAutoScroll() {
    setState(() {
      _isAutoScrollPaused = true;
    });
    _autoScrollTimer?.cancel();
    _indicatorAnimationController.stop();
  }

  void _resumeAutoScroll() {
    setState(() {
      _isAutoScrollPaused = false;
    });
    _startAutoScroll();
  }

  // Helper method to calculate visible dot range (max 5 dots)
  ({int start, int end}) _getVisibleDotRange() {
    final totalDots = _onDeck.length;
    if (totalDots <= 5) {
      return (start: 0, end: totalDots - 1);
    }

    // Center the active dot when possible
    final center = _currentHeroIndex;
    int start = (center - 2).clamp(0, totalDots - 5);
    int end = start + 4; // 5 dots total (0-4 inclusive)

    return (start: start, end: end);
  }

  // Helper method to determine dot size based on position
  double _getDotSize(int dotIndex, int start, int end) {
    final totalDots = _onDeck.length;

    // If we have 5 or fewer dots, all are full size (8px)
    if (totalDots <= 5) {
      return 8.0;
    }

    // First and last visible dots are smaller if there are more items beyond them
    final isFirstVisible = dotIndex == start && start > 0;
    final isLastVisible = dotIndex == end && end < totalDots - 1;

    if (isFirstVisible || isLastVisible) {
      return 5.0; // Smaller edge dots
    }

    return 8.0; // Normal size
  }

  Future<void> _loadContent() async {
    appLogger.d('Loading discover content from all servers');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      appLogger.d('Fetching onDeck and hubs from all Plex servers');
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );

      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }

      // Fetch on deck and hubs from all servers in parallel for optimal performance
      final results = await Future.wait([
        multiServerProvider.aggregationService.getOnDeckFromAllServers(
          limit: 20,
        ),
        multiServerProvider.aggregationService.getHubsFromAllServers(),
      ]);

      final onDeck = results[0] as List<MediaItem>;
      final allHubs = results[1] as List<Hub>;

      // Filter out duplicate hubs that we already fetch separately
      final filteredHubs = allHubs.where((hub) {
        final hubId = hub.hubIdentifier?.toLowerCase() ?? '';
        final title = hub.title.toLowerCase();
        // Skip "Continue Watching" and "On Deck" hubs (we handle these separately)
        return !hubId.contains('ondeck') &&
            !hubId.contains('continue') &&
            !title.contains('continue watching') &&
            !title.contains('on deck');
      }).toList();

      appLogger.d(
        'Received ${onDeck.length} on deck items and ${filteredHubs.length} hubs from all servers',
      );
      setState(() {
        _onDeck = onDeck;
        _hubs = filteredHubs;
        _nextWatchItems = _extractNextWatchItems(filteredHubs);
        _availableGenres = _extractGenresFromHubs(filteredHubs);
        _isLoading = false;

        // Reset hero index to avoid sync issues
        _currentHeroIndex = 0;
      });

      // Fetch live TV and recently added separately (non-blocking)
      _fetchLiveTV();
      _fetchRecentlyAdded();
      _startLiveTVRefresh();

      // Sync PageController to first page after data loads
      if (_heroController.hasClients && onDeck.isNotEmpty) {
        _heroController.jumpToPage(0);
      }

      // Focus the hero on initial load
      if (_isInitialLoad && onDeck.isNotEmpty) {
        _isInitialLoad = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _heroFocusNode.requestFocus();
          }
        });
      }

      appLogger.d('Discover content loaded successfully');
    } catch (e) {
      appLogger.e('Failed to load discover content', error: e);
      setState(() {
        _errorMessage = 'Failed to load content: $e';
        _isLoading = false;
      });
    }
  }

  /// Refresh only the Continue Watching section in the background
  /// This is called when returning to the home screen to avoid blocking UI
  Future<void> _refreshContinueWatching() async {
    appLogger.d('Refreshing Continue Watching in background from all servers');

    try {
      final multiServerProvider = context.read<MultiServerProvider>();
      if (!multiServerProvider.hasConnectedServers) {
        appLogger.w('No servers available for background refresh');
        return;
      }

      final onDeck = await multiServerProvider.aggregationService
          .getOnDeckFromAllServers(limit: 20);

      if (mounted) {
        setState(() {
          _onDeck = onDeck;
          // Reset hero index if needed
          if (_currentHeroIndex >= onDeck.length) {
            _currentHeroIndex = 0;
            if (_heroController.hasClients && onDeck.isNotEmpty) {
              _heroController.jumpToPage(0);
            }
          }
        });
        appLogger.d('Continue Watching refreshed successfully');
      }
    } catch (e) {
      appLogger.w('Failed to refresh Continue Watching', error: e);
      // Silently fail - don't show error to user for background refresh
    }
  }

  /// Fetch live TV channels for "What's On Now" section
  Future<void> _fetchLiveTV() async {
    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );

      if (!multiServerProvider.hasConnectedServers) {
        return;
      }

      // Fetch from first available server (Live TV is typically on one server)
      final client = context.getClientForServer(
        multiServerProvider.onlineServerIds.first,
      );

      final channels = await client.getLiveTVWhatsOnNow();

      if (mounted) {
        setState(() {
          // Limit to top 5 channels for home screen section
          _liveChannels = channels.take(5).toList();
        });
        appLogger.d('Fetched ${_liveChannels.length} live TV channels for home screen');
      }
    } catch (e) {
      appLogger.w('Failed to fetch live TV for home', error: e);
      // Silently fail - live TV section is optional
    }
  }

  /// Fetch recently added content for "Just Added" section
  Future<void> _fetchRecentlyAdded() async {
    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );

      if (!multiServerProvider.hasConnectedServers) {
        return;
      }

      // Fetch from first available server
      final client = context.getClientForServer(
        multiServerProvider.onlineServerIds.first,
      );

      final items = await client.getRecentlyAdded(limit: 20);

      if (mounted) {
        setState(() {
          _recentlyAdded = items;
        });
        appLogger.d('Fetched ${_recentlyAdded.length} recently added items');
      }
    } catch (e) {
      appLogger.w('Failed to fetch recently added', error: e);
      // Silently fail - section is optional
    }
  }

  /// Start periodic refresh of live TV data (every 60 seconds)
  void _startLiveTVRefresh() {
    _liveTVRefreshTimer?.cancel();
    _liveTVRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchLiveTV();
    });
  }

  // Public method to refresh content (for normal navigation)
  @override
  void refresh() {
    appLogger.d('DiscoverScreen.refresh() called');
    // Only refresh Continue Watching in background, not full screen reload
    _refreshContinueWatching();
  }

  // Public method to fully reload all content (for profile switches)
  void fullRefresh() {
    appLogger.d('DiscoverScreen.fullRefresh() called - reloading all content');
    // Reload all content including On Deck and content hubs
    _loadContent();
  }

  /// Focus the hero section (for keyboard navigation)
  void focusHero() {
    if (_onDeck.isNotEmpty) {
      _heroFocusNode.requestFocus();
    }
  }

  /// Check if hub should be displayed as Top 10 style (trending/popular content)
  bool _isTrendingHub(Hub hub) {
    final id = hub.hubIdentifier?.toLowerCase() ?? '';
    final title = hub.title.toLowerCase();
    return id.contains('trending') ||
        id.contains('popular') ||
        title.contains('top 10') ||
        title.contains('top ten') ||
        title.contains('trending') ||
        title.contains('most popular') ||
        (title.contains('top ') && title.contains('in'));
  }

  /// Check if hub should be displayed as a featured collection
  bool _isFeaturedHub(Hub hub) {
    final id = hub.hubIdentifier?.toLowerCase() ?? '';
    final title = hub.title.toLowerCase();
    return id.contains('recommended') ||
        id.contains('featured') ||
        id.contains('picks') ||
        id.contains('award') ||
        id.contains('best') ||
        title.contains('recommended') ||
        title.contains('picks for you') ||
        title.contains('award') ||
        title.contains('editor') ||
        title.contains('staff picks') ||
        title.contains('top rated');
  }

  /// Get accent color for featured hub based on its type
  Color? _getFeaturedHubColor(Hub hub) {
    final title = hub.title.toLowerCase();
    if (title.contains('award') || title.contains('best')) {
      return Colors.amber;
    }
    if (title.contains('recommended') || title.contains('picks')) {
      return Colors.deepPurple;
    }
    if (title.contains('top rated')) {
      return Colors.green;
    }
    return null;
  }

  /// Get icon for featured hub based on its type
  IconData _getFeaturedHubIcon(Hub hub) {
    final title = hub.title.toLowerCase();
    if (title.contains('award') || title.contains('best')) {
      return Icons.emoji_events;
    }
    if (title.contains('recommended') || title.contains('picks')) {
      return Icons.thumb_up;
    }
    if (title.contains('top rated')) {
      return Icons.star;
    }
    return Icons.auto_awesome;
  }

  /// Build the appropriate hub section widget based on hub type
  Widget _buildHubSection(Hub hub, int index) {
    // Check for brand/studio hubs first (Marvel, Disney, Pixar, etc.)
    final brandInfo = BrandInfo.fromHub(hub);
    if (brandInfo != null) {
      return BrandHubSection(
        hub: hub,
        brandInfo: brandInfo,
        onRefresh: updateItem,
        navigationOrder: 3 + index,
      );
    }

    // Check for trending hubs (Top 10 style)
    if (_isTrendingHub(hub)) {
      return Top10Section(
        hub: hub,
        onRefresh: updateItem,
        navigationOrder: 3 + index,
      );
    }

    // Check for featured collections (Award Winners, Staff Picks, etc.)
    if (_isFeaturedHub(hub)) {
      return FeaturedCollectionSection(
        hub: hub,
        accentColor: _getFeaturedHubColor(hub),
        icon: _getFeaturedHubIcon(hub),
        onRefresh: updateItem,
        navigationOrder: 3 + index,
      );
    }

    // Check for mood-based collections (Feel-Good, Date Night, etc.)
    final moodInfo = MoodInfo.fromHub(hub);
    if (moodInfo != null) {
      return MoodCollectionSection(
        hub: hub,
        mood: moodInfo,
        onRefresh: updateItem,
        navigationOrder: 3 + index,
      );
    }

    // Check for "Because you watched X" recommendations
    final becauseInfo = BecauseYouWatchedInfo.fromHub(hub);
    if (becauseInfo != null) {
      return BecauseYouWatchedSection(
        hub: hub,
        info: becauseInfo,
        onRefresh: updateItem,
        navigationOrder: 3 + index,
      );
    }

    // Default to regular hub section
    return HubSection(
      hub: hub,
      icon: _getHubIcon(hub.title),
      onRefresh: updateItem,
      navigationOrder: 3 + index,
    );
  }

  /// Get icon for hub based on its title
  IconData _getHubIcon(String title) {
    final lowerTitle = title.toLowerCase();

    // Trending/Popular content
    if (lowerTitle.contains('trending')) {
      return Icons.trending_up;
    }
    if (lowerTitle.contains('popular') || lowerTitle.contains('imdb')) {
      return Icons.whatshot;
    }

    // Seasonal/Time-based
    if (lowerTitle.contains('seasonal')) {
      return Icons.calendar_month;
    }
    if (lowerTitle.contains('newly') || lowerTitle.contains('new release')) {
      return Icons.new_releases;
    }
    if (lowerTitle.contains('recently released') ||
        lowerTitle.contains('recent')) {
      return Icons.schedule;
    }

    // Top/Rated content
    if (lowerTitle.contains('top rated') ||
        lowerTitle.contains('highest rated')) {
      return Icons.star;
    }
    if (lowerTitle.contains('top ')) {
      return Icons.military_tech;
    }

    // Genre-specific
    if (lowerTitle.contains('thriller')) {
      return Icons.warning_amber_rounded;
    }
    if (lowerTitle.contains('comedy') || lowerTitle.contains('comedier')) {
      return Icons.mood;
    }
    if (lowerTitle.contains('action')) {
      return Icons.flash_on;
    }
    if (lowerTitle.contains('drama')) {
      return Icons.theater_comedy;
    }
    if (lowerTitle.contains('fantasy')) {
      return Icons.auto_fix_high;
    }
    if (lowerTitle.contains('science') || lowerTitle.contains('sci-fi')) {
      return Icons.rocket_launch;
    }
    if (lowerTitle.contains('horror') || lowerTitle.contains('skräck')) {
      return Icons.nights_stay;
    }
    if (lowerTitle.contains('romance') || lowerTitle.contains('romantic')) {
      return Icons.favorite_border;
    }
    if (lowerTitle.contains('adventure') || lowerTitle.contains('äventyr')) {
      return Icons.explore;
    }

    // Watchlist/Playlists
    if (lowerTitle.contains('playlist') || lowerTitle.contains('watchlist')) {
      return Icons.playlist_play;
    }
    if (lowerTitle.contains('unwatched') || lowerTitle.contains('unplayed')) {
      return Icons.visibility_off;
    }
    if (lowerTitle.contains('watched') || lowerTitle.contains('played')) {
      return Icons.visibility;
    }

    // Network/Studio
    if (lowerTitle.contains('network') || lowerTitle.contains('more from')) {
      return Icons.tv;
    }

    // Actor/Director
    if (lowerTitle.contains('actor') || lowerTitle.contains('director')) {
      return Icons.person;
    }

    // Year-based (80s, 90s, etc.)
    if (lowerTitle.contains('80') ||
        lowerTitle.contains('90') ||
        lowerTitle.contains('00')) {
      return Icons.history;
    }

    // Rediscover/Start Watching
    if (lowerTitle.contains('rediscover') ||
        lowerTitle.contains('start watching')) {
      return Icons.play_arrow;
    }

    // Default icon for other hubs
    return Icons.auto_awesome;
  }

  /// Extract "Your Next Watch" items from recommendation hubs
  /// Prioritizes hubs that are personalized recommendations
  List<MediaItem> _extractNextWatchItems(List<Hub> hubs) {
    final items = <MediaItem>[];
    final seenKeys = <String>{};

    // Priority order for recommendation hubs
    final priorityPatterns = [
      'recommended',
      'for you',
      'picks for',
      'based on',
      'because you',
      'similar to',
      'you might like',
      'top rated',
      'popular',
    ];

    // Sort hubs by priority
    final sortedHubs = List<Hub>.from(hubs);
    sortedHubs.sort((a, b) {
      final aTitle = a.title.toLowerCase();
      final bTitle = b.title.toLowerCase();
      final aId = a.hubIdentifier?.toLowerCase() ?? '';
      final bId = b.hubIdentifier?.toLowerCase() ?? '';

      int getPriority(String title, String id) {
        for (int i = 0; i < priorityPatterns.length; i++) {
          if (title.contains(priorityPatterns[i]) ||
              id.contains(priorityPatterns[i])) {
            return i;
          }
        }
        return priorityPatterns.length;
      }

      return getPriority(aTitle, aId).compareTo(getPriority(bTitle, bId));
    });

    // Collect items from sorted hubs (max 10 unique items)
    for (final hub in sortedHubs) {
      for (final item in hub.items) {
        if (items.length >= 10) break;
        if (!seenKeys.contains(item.ratingKey)) {
          // Skip items that are in continue watching
          final isInOnDeck = _onDeck.any((d) => d.ratingKey == item.ratingKey);
          if (!isInOnDeck) {
            items.add(item);
            seenKeys.add(item.ratingKey);
          }
        }
      }
      if (items.length >= 10) break;
    }

    return items;
  }

  /// Extract available genres from hub titles
  /// Looks for patterns like "Top in Thrillers", "Action Movies", "Comedy Films"
  List<String> _extractGenresFromHubs(List<Hub> hubs) {
    final genreSet = <String>{};

    // Known genre keywords to look for in hub titles
    final knownGenres = [
      'Action',
      'Adventure',
      'Animation',
      'Anime',
      'Comedy',
      'Crime',
      'Documentary',
      'Drama',
      'Family',
      'Fantasy',
      'History',
      'Horror',
      'Kids',
      'Music',
      'Musical',
      'Mystery',
      'Romance',
      'Sci-Fi',
      'Science Fiction',
      'Thriller',
      'Thrillers',
      'War',
      'Western',
    ];

    for (final hub in hubs) {
      final title = hub.title;
      for (final genre in knownGenres) {
        if (title.toLowerCase().contains(genre.toLowerCase())) {
          // Normalize some genres
          if (genre == 'Thrillers') {
            genreSet.add('Thriller');
          } else if (genre == 'Science Fiction') {
            genreSet.add('Sci-Fi');
          } else {
            genreSet.add(genre);
          }
        }
      }
    }

    // Sort alphabetically
    final genres = genreSet.toList()..sort();
    return genres;
  }

  /// Get icon for a genre
  IconData _getGenreIcon(String genre) {
    final lowerGenre = genre.toLowerCase();
    return _genreIcons[lowerGenre] ?? Icons.category;
  }

  /// Filter hubs based on selected genre (by hub title)
  List<Hub> _getFilteredHubs() {
    if (_selectedGenre == null) return _hubs;

    final selectedLower = _selectedGenre!.toLowerCase();

    return _hubs.where((hub) {
      final titleLower = hub.title.toLowerCase();
      // Match the genre in the hub title
      return titleLower.contains(selectedLower) ||
          (selectedLower == 'sci-fi' && titleLower.contains('science fiction')) ||
          (selectedLower == 'thriller' && titleLower.contains('thrillers'));
    }).toList();
  }

  @override
  void updateItemInLists(String ratingKey, MediaItem updatedMetadata) {
    // Check and update in _onDeck list
    final onDeckIndex = _onDeck.indexWhere(
      (item) => item.ratingKey == ratingKey,
    );
    if (onDeckIndex != -1) {
      _onDeck[onDeckIndex] = updatedMetadata;
    }

    // Check and update in hub items
    for (final hub in _hubs) {
      final itemIndex = hub.items.indexWhere(
        (item) => item.ratingKey == ratingKey,
      );
      if (itemIndex != -1) {
        hub.items[itemIndex] = updatedMetadata;
      }
    }
  }

  Future<void> _handleSwitchLocalProfile() async {
    final storage = await StorageService.getInstance();
    final serverUrl = storage.getServerUrl();

    if (serverUrl != null && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ProfileSelectionScreen(
            serverUrl: serverUrl,
            serverName: Uri.tryParse(serverUrl)?.host,
          ),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.common.logout),
        content: Text(t.messages.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.common.logout),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Use comprehensive logout through UserProfileProvider
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );
      final plexClientProvider = context.plexClient;
      final multiServerProvider = context.read<MultiServerProvider>();
      final serverStateProvider = context.read<ServerStateProvider>();
      final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
      final playbackStateProvider = context.read<PlaybackStateProvider>();

      // Clear all user data and provider states
      await userProfileProvider.logout();
      plexClientProvider.clearClient();
      multiServerProvider.clearAllConnections();
      serverStateProvider.reset();
      await hiddenLibrariesProvider.refresh();
      playbackStateProvider.clearShuffle();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  void _handleSwitchProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSwitchScreen()),
    );
  }

  void _handleVoiceCommand(VoiceCommandResult result) {
    switch (result.command) {
      case VoiceCommand.search:
        if (result.query != null) {
          // Navigate to search tab and perform search
          final mainScreenState = context.findAncestorStateOfType<MainScreenState>();
          mainScreenState?.switchToTab(3); // Search tab index
          // TODO: Pass query to search screen
        }
        break;
      case VoiceCommand.home:
        // Already on home, scroll to top
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        break;
      case VoiceCommand.play:
        // Start channel surfing as a "play something" action
        showChannelSurfingSheet(context);
        break;
      default:
        // Show feedback for unhandled commands on this screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice command: ${result.command.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetScreensaverTimer(),
      onPointerMove: (_) => _resetScreensaverTimer(),
      child: Scaffold(
        body: SafeArea(
          child: Focus(
            onKeyEvent: (node, event) {
              _resetScreensaverTimer();
              return _handleBackKey(node, event);
            },
            child: HubNavigationScope(
            controller: _hubNavigationController,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                DesktopSliverAppBar(
                  title: Text(t.discover.title),
                  floating: true,
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  actions: [
                    // Voice Control Button
                    VoiceControlIconButton(
                      onCommand: (result) => _handleVoiceCommand(result),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadContent,
                    ),
                    Consumer<UserProfileProvider>(
                      builder: (context, userProvider, child) {
                        return PopupMenuButton<String>(
                          icon: userProvider.currentUser?.thumb != null
                              ? UserAvatarWidget(
                                  user: userProvider.currentUser!,
                                  size: 32,
                                  showIndicators: false,
                                )
                              : const Icon(Icons.account_circle, size: 32),
                          onSelected: (value) {
                            if (value == 'switch_local_profile') {
                              _handleSwitchLocalProfile();
                            } else if (value == 'switch_profile') {
                              _handleSwitchProfile(context);
                            } else if (value == 'logout') {
                              _handleLogout();
                            } else if (value == 'channel_surfing') {
                              showChannelSurfingSheet(context);
                            } else if (value == 'downloads') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DownloadsScreen(),
                                ),
                              );
                            } else if (value == 'watchlist') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WatchlistScreen(),
                                ),
                              );
                            } else if (value == 'virtual_channels') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VirtualChannelsScreen(),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            // Channel Surfing
                            PopupMenuItem(
                              value: 'channel_surfing',
                              child: Row(
                                children: [
                                  const Icon(Icons.shuffle),
                                  const SizedBox(width: 8),
                                  const Text('Channel Surfing'),
                                ],
                              ),
                            ),
                            // Downloads
                            PopupMenuItem(
                              value: 'downloads',
                              child: Row(
                                children: [
                                  const Icon(Icons.download_for_offline),
                                  const SizedBox(width: 8),
                                  const Text('Downloads'),
                                ],
                              ),
                            ),
                            // Watchlist
                            PopupMenuItem(
                              value: 'watchlist',
                              child: Row(
                                children: [
                                  const Icon(Icons.bookmark),
                                  const SizedBox(width: 8),
                                  Text(t.watchlist.title),
                                ],
                              ),
                            ),
                            // Virtual Channels
                            PopupMenuItem(
                              value: 'virtual_channels',
                              child: Row(
                                children: [
                                  const Icon(Icons.playlist_play),
                                  const SizedBox(width: 8),
                                  Text(t.virtualChannels.title),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            // Switch Local Profile (always available)
                            PopupMenuItem(
                              value: 'switch_local_profile',
                              child: Row(
                                children: [
                                  const Icon(Icons.swap_horiz),
                                  const SizedBox(width: 8),
                                  Text(t.settings.switchProfile),
                                ],
                              ),
                            ),
                            // Only show Switch Plex User if multiple users available
                            if (userProvider.hasMultipleUsers)
                              PopupMenuItem(
                                value: 'switch_profile',
                                child: Row(
                                  children: [
                                    const Icon(Icons.people),
                                    const SizedBox(width: 8),
                                    Text(t.discover.switchProfile),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout),
                                  SizedBox(width: 8),
                                  Text(t.discover.logout),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                // Personalized Greeting Header
                SliverToBoxAdapter(
                  child: _buildPersonalizedHeader(),
                ),
                // Category Filter Chips for TV-friendly browsing
                SliverToBoxAdapter(
                  child: _buildCategoryFilterChips(),
                ),
                // Genre Filter Chips (only show when genres are available)
                if (_availableGenres.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildGenreFilterChips(),
                  ),
                // Docked Player (last watched channel mini-player)
                if (_dockedPlayerEnabled && _lastWatchedChannel != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: DockedPlayer(
                        key: _dockedPlayerKey,
                        channels: _liveChannels,
                        isVisible: true,
                        autoPlay: true,
                        height: 180,
                        onExpandToFullscreen: () => _navigateToLiveTVPlayer(_lastWatchedChannel!),
                        onChannelChange: (channel) {
                          setState(() {
                            _lastWatchedChannel = channel;
                          });
                        },
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
                  // Hero Section (Continue Watching)
                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      if (_onDeck.isNotEmpty &&
                          settingsProvider.showHeroSection) {
                        return _buildHeroSection();
                      }
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    },
                  ),

                  // "What's On Now" Live TV Section
                  if (_liveChannels.isNotEmpty)
                    SliverToBoxAdapter(
                      child: LiveTVHomeSection(
                        channels: _liveChannels,
                        navigationOrder: 1,
                      ),
                    ),

                  // "Your Next Watch" Personalized Recommendations
                  if (_nextWatchItems.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Consumer<UserProfileProvider>(
                        builder: (context, userProvider, _) {
                          final userName = userProvider.currentUser?.displayName;
                          return YourNextWatchSection(
                            items: _nextWatchItems,
                            userName: userName,
                            navigationOrder: 2,
                          );
                        },
                      ),
                    ),

                  // On Deck / Continue Watching (Enhanced)
                  if (_onDeck.isNotEmpty)
                    SliverToBoxAdapter(
                      child: ContinueWatchingSection(
                        items: _onDeck,
                        onRefresh: updateItem,
                        onRemoveItem: _refreshContinueWatching,
                        navigationOrder: 3, // After hero, live TV, and next watch
                      ),
                    ),

                  // Just Added Section
                  if (_recentlyAdded.isNotEmpty)
                    SliverToBoxAdapter(
                      child: JustAddedSection(
                        items: _recentlyAdded,
                        onRefresh: updateItem,
                        navigationOrder: 4,
                      ),
                    ),

                  // Calendar View Section (shows content by date)
                  if (_recentlyAdded.isNotEmpty)
                    SliverToBoxAdapter(
                      child: CalendarViewSection(
                        items: _recentlyAdded,
                        title: t.discover.calendar,
                        icon: Icons.calendar_month,
                        navigationOrder: 5,
                      ),
                    ),

                  // Recommendation Hubs (filtered by genre if selected)
                  Builder(
                    builder: (context) {
                      final filteredHubs = _getFilteredHubs();
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _buildHubSection(filteredHubs[i], i + 1),
                          childCount: filteredHubs.length,
                        ),
                      );
                    },
                  ),

                  if (_onDeck.isEmpty && _hubs.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(t.discover.noContentAvailable),
                            SizedBox(height: 8),
                            Text(
                              t.discover.addMediaToLibraries,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHeroSection() {
    // Register hero section with navigation controller
    // This allows pressing up from first hub to return to hero
    _hubNavigationController.register(
      HubSectionRegistration(
        hubId: '_hero_',
        itemCount: 1,
        focusItem: (_) => _heroFocusNode.requestFocus(),
        order: 0, // Hero is first
      ),
    );

    return SliverToBoxAdapter(
      child: Focus(
        focusNode: _heroFocusNode,
        onKeyEvent: _handleHeroKeyEvent,
        child: SizedBox(
          height: 500,
          child: Stack(
            children: [
              PageView.builder(
                controller: _heroController,
                itemCount: _onDeck.length,
                onPageChanged: (index) {
                  // Validate index is within bounds before updating
                  if (index >= 0 && index < _onDeck.length) {
                    setState(() {
                      _currentHeroIndex = index;
                    });
                    _resetAutoScrollTimer();
                  }
                },
                itemBuilder: (context, index) {
                  return _buildHeroItem(_onDeck[index]);
                },
              ),
              // Page indicators with animated progress and pause/play button
              Positioned(
                bottom: 16,
                left: -26,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pause/Play button
                    GestureDetector(
                      onTap: () {
                        if (_isAutoScrollPaused) {
                          _resumeAutoScroll();
                        } else {
                          _pauseAutoScroll();
                        }
                      },
                      child: Icon(
                        _isAutoScrollPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 18,
                        semanticLabel:
                            '${_isAutoScrollPaused ? t.discover.play : t.discover.pause} auto-scroll',
                      ),
                    ),
                    // Spacer to separate indicators from button
                    const SizedBox(width: 8),
                    // Page indicators (limited to 5 dots)
                    ...() {
                      final range = _getVisibleDotRange();
                      return List.generate(range.end - range.start + 1, (i) {
                        final index = range.start + i;
                        final isActive = _currentHeroIndex == index;
                        final dotSize = _getDotSize(
                          index,
                          range.start,
                          range.end,
                        );

                        if (isActive) {
                          // Animated progress indicator for active page
                          return AnimatedBuilder(
                            animation: _indicatorAnimationController,
                            builder: (context, child) {
                              // Fill width animates based on dot size
                              final maxWidth =
                                  dotSize *
                                  3; // 24px for normal, 15px for small
                              final fillWidth =
                                  dotSize +
                                  ((maxWidth - dotSize) *
                                      _indicatorAnimationController.value);
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: maxWidth,
                                height: dotSize,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(
                                    dotSize / 2,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: fillWidth,
                                    height: dotSize,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        dotSize / 2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          // Static indicator for inactive pages
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(dotSize / 2),
                            ),
                          );
                        }
                      });
                    }(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build personalized greeting header (Netflix-style "For [Username]")
  Widget _buildPersonalizedHeader() {
    final userProvider = Provider.of<UserProfileProvider>(context);
    final currentUser = userProvider.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    // Get greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = t.discover.goodMorning;
    } else if (hour < 17) {
      greeting = t.discover.goodAfternoon;
    } else {
      greeting = t.discover.goodEvening;
    }

    // Use FutureBuilder to get local profile name
    return FutureBuilder<ProfileStorageService>(
      future: ProfileStorageService.getInstance(),
      builder: (context, snapshot) {
        String userName;
        if (snapshot.hasData) {
          final activeProfile = snapshot.data?.getActiveProfile();
          userName = activeProfile?.name ?? currentUser?.displayName ?? t.discover.defaultUser;
        } else {
          userName = currentUser?.displayName ?? t.discover.defaultUser;
        }

        return Padding(
      padding: EdgeInsets.fromLTRB(
        isTV ? 24 : 16,
        isTV ? 16 : 12,
        isTV ? 24 : 16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: TextStyle(
              fontSize: isTV ? 18 : 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            userName,
            style: TextStyle(
              fontSize: isTV ? 28 : 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  /// Build category filter chips for TV-friendly navigation
  Widget _buildCategoryFilterChips() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    return Container(
      height: isTV ? 72 : 56,
      padding: EdgeInsets.symmetric(vertical: isTV ? 12 : 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTV ? 24 : 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['id'];
          return Padding(
            padding: EdgeInsets.only(right: index < _categories.length - 1 ? (isTV ? 16 : 8) : 0),
            child: _CategoryChip(
              label: category['label'] as String,
              icon: category['icon'] as IconData,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'] as String;
                });
              },
            ),
          );
        },
      ),
    );
  }

  /// Build genre filter chips
  Widget _buildGenreFilterChips() {
    if (_availableGenres.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;
    final theme = Theme.of(context);

    return Container(
      height: isTV ? 56 : 44,
      padding: EdgeInsets.only(bottom: isTV ? 8 : 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isTV ? 24 : 16),
        itemCount: _availableGenres.length + 1, // +1 for "All Genres" chip
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All Genres" chip
            final isSelected = _selectedGenre == null;
            return Padding(
              padding: EdgeInsets.only(right: isTV ? 12 : 8),
              child: _GenreChip(
                genre: 'All Genres',
                icon: Icons.grid_view,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedGenre = null;
                  });
                },
              ),
            );
          }

          final genre = _availableGenres[index - 1];
          final isSelected = _selectedGenre == genre;
          return Padding(
            padding: EdgeInsets.only(right: index < _availableGenres.length ? (isTV ? 12 : 8) : 0),
            child: _GenreChip(
              genre: genre,
              icon: _getGenreIcon(genre),
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedGenre = isSelected ? null : genre;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroItem(MediaItem heroItem) {
    final isEpisode = heroItem.type.toLowerCase() == 'episode';
    final showName = heroItem.grandparentTitle ?? heroItem.title;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;

    // Determine content type label for chip
    final contentTypeLabel = heroItem.type.toLowerCase() == 'movie'
        ? t.discover.movie
        : t.discover.tvShow;

    // Build semantic label for hero item
    final heroLabel = isEpisode
        ? "${heroItem.grandparentTitle}, ${heroItem.title}"
        : heroItem.title;

    return Semantics(
      label: heroLabel,
      button: true,
      hint: t.accessibility.tapToPlay,
      child: GestureDetector(
        onTap: () {
          appLogger.d('Navigating to VideoPlayerScreen for: ${heroItem.title}');
          navigateToVideoPlayer(context, metadata: heroItem);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image with fade/zoom animation and parallax
                if (heroItem.art != null || heroItem.grandparentArt != null)
                  AnimatedBuilder(
                    animation: _scrollController,
                    builder: (context, child) {
                      final scrollOffset = _scrollController.hasClients
                          ? _scrollController.offset
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(0, scrollOffset * 0.3),
                        child: child,
                      );
                    },
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 1.0 + (0.1 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Builder(
                        builder: (context) {
                          final client = _getClientForItem(heroItem);
                          return CachedNetworkImage(
                            imageUrl: client.getThumbnailUrl(
                              heroItem.art ?? heroItem.grandparentArt,
                            ),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),

                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Content with responsive alignment
                Positioned(
                  bottom: isLargeScreen ? 80 : 50,
                  left: 0,
                  right: isLargeScreen ? 200 : 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 40 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: isLargeScreen
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show logo or name/title
                        if (heroItem.clearLogo != null)
                          SizedBox(
                            height: 120,
                            width: 400,
                            child: Builder(
                              builder: (context) {
                                final client = _getClientForItem(heroItem);
                                return CachedNetworkImage(
                                  imageUrl: client.getThumbnailUrl(
                                    heroItem.clearLogo,
                                  ),
                                  filterQuality: FilterQuality.medium,
                                  fit: BoxFit.contain,
                                  alignment: isLargeScreen
                                      ? Alignment.bottomLeft
                                      : Alignment.bottomCenter,
                                  placeholder: (context, url) => Align(
                                    alignment: isLargeScreen
                                        ? Alignment.centerLeft
                                        : Alignment.center,
                                    child: Text(
                                      showName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.5,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: isLargeScreen
                                          ? TextAlign.left
                                          : TextAlign.center,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    // Fallback to text if logo fails to load
                                    return Align(
                                      alignment: isLargeScreen
                                          ? Alignment.centerLeft
                                          : Alignment.center,
                                      child: Text(
                                        showName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: isLargeScreen
                                            ? TextAlign.left
                                            : TextAlign.center,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        else
                          Text(
                            showName,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isLargeScreen
                                ? TextAlign.left
                                : TextAlign.center,
                          ),

                        // Metadata as dot-separated text with content type
                        if (heroItem.year != null ||
                            heroItem.contentRating != null ||
                            heroItem.rating != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            [
                              contentTypeLabel,
                              if (heroItem.rating != null)
                                '★ ${heroItem.rating!.toStringAsFixed(1)}',
                              if (heroItem.contentRating != null)
                                formatContentRating(heroItem.contentRating!),
                              if (heroItem.year != null)
                                heroItem.year.toString(),
                            ].join(' • '),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: isLargeScreen
                                ? TextAlign.left
                                : TextAlign.center,
                          ),
                        ],

                        // On small screens: show buttons before summary
                        if (!isLargeScreen) ...[
                          const SizedBox(height: 20),
                          _buildHeroActionButtons(heroItem),
                        ],

                        // Summary with episode info (Apple TV style)
                        if (heroItem.summary != null) ...[
                          const SizedBox(height: 12),
                          RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isLargeScreen
                                ? TextAlign.left
                                : TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              children: [
                                if (isEpisode &&
                                    heroItem.parentIndex != null &&
                                    heroItem.index != null)
                                  TextSpan(
                                    text:
                                        'S${heroItem.parentIndex}, E${heroItem.index}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                TextSpan(
                                  text: heroItem.summary?.isNotEmpty == true
                                      ? heroItem.summary!
                                      : 'No description available',
                                ),
                              ],
                            ),
                          ),
                        ],

                        // On large screens: show buttons after summary
                        if (isLargeScreen) ...[
                          const SizedBox(height: 20),
                          _buildHeroActionButtons(heroItem),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build hero action buttons (Play + Info) like Hulu/Netflix
  Widget _buildHeroActionButtons(MediaItem heroItem) {
    final hasProgress =
        heroItem.viewOffset != null &&
        heroItem.duration != null &&
        heroItem.viewOffset! > 0 &&
        heroItem.duration! > 0;

    final minutesLeft = hasProgress
        ? ((heroItem.duration! - heroItem.viewOffset!) / 60000).round()
        : 0;

    final progress = hasProgress
        ? heroItem.viewOffset! / heroItem.duration!
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play button
        _HeroActionButton(
          icon: Icons.play_arrow,
          label: hasProgress ? '$minutesLeft min left' : t.discover.play,
          isPrimary: true,
          progress: hasProgress ? progress : null,
          onTap: () {
            appLogger.d('Playing: ${heroItem.title}');
            navigateToVideoPlayer(context, metadata: heroItem);
          },
        ),
        const SizedBox(width: 12),
        // Info/Details button
        _HeroActionButton(
          icon: Icons.info_outline,
          label: 'Details',
          isPrimary: false,
          onTap: () {
            _navigateToMediaDetail(heroItem);
          },
        ),
        const SizedBox(width: 12),
        // Surprise Me button
        _HeroActionButton(
          icon: Icons.casino,
          label: t.discover.surpriseMe,
          isPrimary: false,
          onTap: _showRandomPicker,
        ),
      ],
    );
  }

  void _showRandomPicker() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RandomPickerDialog(),
    );
  }

  void _navigateToMediaDetail(MediaItem item) {
    // Navigate to media detail screen
    Navigator.pushNamed(
      context,
      '/media/${item.ratingKey}',
      arguments: {'item': item, 'serverId': item.serverId},
    );
  }
}

/// TV-friendly hero action button with focus support
class _HeroActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final double? progress;
  final VoidCallback onTap;

  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    this.progress,
    required this.onTap,
  });

  @override
  State<_HeroActionButton> createState() => _HeroActionButtonState();
}

class _HeroActionButtonState extends State<_HeroActionButton> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary
        ? (_isFocused ? Colors.white : Colors.white.withValues(alpha: 0.95))
        : (_isFocused ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2));

    final textColor = widget.isPrimary ? Colors.black : Colors.white;
    final iconColor = widget.isPrimary ? Colors.black : Colors.white;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space) {
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          transform: _isFocused
              ? Matrix4.diagonal3Values(1.05, 1.05, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: _isFocused
                ? Border.all(color: Colors.white, width: 3)
                : null,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 24, color: iconColor),
              const SizedBox(width: 8),
              if (widget.progress != null) ...[
                // Progress bar for continue watching
                Container(
                  width: 40,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: widget.progress!,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TV-friendly category filter chip with focus support
class _CategoryChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    final selectedBg = theme.colorScheme.primary;
    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    final selectedFg = theme.colorScheme.onPrimary;
    final unselectedFg = isDark ? Colors.white70 : Colors.black87;

    // Larger sizes for TV mode
    final horizontalPadding = isTV ? 24.0 : 16.0;
    final verticalPadding = isTV ? 14.0 : 10.0;
    final iconSize = isTV ? 24.0 : 18.0;
    final fontSize = isTV ? 18.0 : 14.0;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space) {
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
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
          transform: _isFocused
              ? Matrix4.diagonal3Values(isTV ? 1.1 : 1.08, isTV ? 1.1 : 1.08, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(isTV ? 28 : 24),
            border: _isFocused
                ? Border.all(color: Colors.white, width: isTV ? 3 : 2)
                : widget.isSelected
                    ? null
                    : Border.all(color: Colors.white24, width: 1),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: isTV ? 0.4 : 0.3),
                      blurRadius: isTV ? 16 : 8,
                      spreadRadius: isTV ? 2 : 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: iconSize,
                color: widget.isSelected ? selectedFg : unselectedFg,
              ),
              SizedBox(width: isTV ? 12 : 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected ? selectedFg : unselectedFg,
                  fontSize: fontSize,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TV-friendly genre filter chip with focus support
class _GenreChip extends StatefulWidget {
  final String genre;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenreChip({
    required this.genre,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GenreChip> createState() => _GenreChipState();
}

class _GenreChipState extends State<_GenreChip> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTV = screenWidth > 1000;

    // Genre chips use a slightly different color scheme
    final selectedBg = theme.colorScheme.secondary;
    final unselectedBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);

    final selectedFg = theme.colorScheme.onSecondary;
    final unselectedFg = isDark ? Colors.white60 : Colors.black54;

    final horizontalPadding = isTV ? 20.0 : 14.0;
    final verticalPadding = isTV ? 12.0 : 8.0;
    final iconSize = isTV ? 20.0 : 16.0;
    final fontSize = isTV ? 15.0 : 12.0;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space) {
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
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          transform: _isFocused
              ? Matrix4.diagonal3Values(isTV ? 1.08 : 1.05, isTV ? 1.08 : 1.05, 1.0)
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isSelected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(isTV ? 20 : 16),
            border: _isFocused
                ? Border.all(color: theme.colorScheme.secondary, width: isTV ? 2 : 1.5)
                : widget.isSelected
                    ? null
                    : Border.all(color: Colors.white12, width: 1),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                      blurRadius: isTV ? 12 : 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: iconSize,
                color: widget.isSelected ? selectedFg : unselectedFg,
              ),
              SizedBox(width: isTV ? 8 : 6),
              Text(
                widget.genre,
                style: TextStyle(
                  color: widget.isSelected ? selectedFg : unselectedFg,
                  fontSize: fontSize,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
