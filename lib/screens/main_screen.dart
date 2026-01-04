import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../client/media_client.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/keyboard_utils.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../main.dart';
import '../mixins/refreshable.dart';
import '../providers/multi_server_provider.dart';
import '../providers/server_state_provider.dart';
import '../providers/hidden_libraries_provider.dart';
import '../providers/playback_state_provider.dart';
import '../services/plex_auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/netflix_preview_card.dart';
import 'catchup_screen.dart';
import 'discover_screen.dart';
import 'libraries_screen.dart';
import 'livetv_screen.dart';
import 'movies_screen.dart';
import 'tvshows_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// InheritedWidget that provides back navigation functionality to child screens
class BackNavigationScope extends InheritedWidget {
  final VoidCallback focusBottomNav;

  const BackNavigationScope({
    super.key,
    required this.focusBottomNav,
    required super.child,
  });

  static BackNavigationScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BackNavigationScope>();
  }

  static BackNavigationScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<BackNavigationScope>();
  }

  @override
  bool updateShouldNotify(BackNavigationScope oldWidget) {
    return focusBottomNav != oldWidget.focusBottomNav;
  }
}

class MainScreen extends StatefulWidget {
  final MediaClient client;

  const MainScreen({super.key, required this.client});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with RouteAware {
  int _currentIndex = 0;
  bool _isSidebarExpanded = false;

  late final List<Widget> _screens;
  final GlobalKey<State<DiscoverScreen>> _discoverKey = GlobalKey();
  final GlobalKey<State<MoviesScreen>> _moviesKey = GlobalKey();
  final GlobalKey<State<TVShowsScreen>> _tvShowsKey = GlobalKey();
  final GlobalKey<State<LibrariesScreen>> _librariesKey = GlobalKey();
  final GlobalKey<State<LiveTVScreen>> _liveTVKey = GlobalKey();
  final GlobalKey<State<CatchupScreen>> _catchupKey = GlobalKey();
  final GlobalKey<State<SearchScreen>> _searchKey = GlobalKey();
  final GlobalKey<State<SettingsScreen>> _settingsKey = GlobalKey();

  /// Focus scope node for the bottom navigation bar
  /// Using FocusScopeNode so requestFocus() focuses the first child
  late final FocusScopeNode _bottomNavFocusScopeNode;

  /// Focus scope node for the main content area
  late final FocusScopeNode _contentFocusScopeNode;

  @override
  void initState() {
    super.initState();
    _bottomNavFocusScopeNode = FocusScopeNode(debugLabel: 'BottomNavigation');
    _contentFocusScopeNode = FocusScopeNode(debugLabel: 'MainContent');

    _screens = [
      DiscoverScreen(
        key: _discoverKey,
        onBecameVisible: _onDiscoverBecameVisible,
      ),
      MoviesScreen(key: _moviesKey),
      TVShowsScreen(key: _tvShowsKey),
      LibrariesScreen(key: _librariesKey),
      LiveTVScreen(key: _liveTVKey),
      CatchupScreen(key: _catchupKey, onBackToNav: _focusBottomNav),
      SearchScreen(key: _searchKey),
      SettingsScreen(key: _settingsKey),
    ];

    // Set up data invalidation callback for profile switching
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize UserProfileProvider to ensure it's ready after sign-in
      final userProfileProvider = context.userProfile;
      await userProfileProvider.initialize();

      // Set up data invalidation callback for profile switching
      userProfileProvider.setDataInvalidationCallback(_invalidateAllScreens);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _bottomNavFocusScopeNode.dispose();
    _contentFocusScopeNode.dispose();
    super.dispose();
  }

  /// Focus the bottom navigation bar (called by child screens on back press)
  void _focusBottomNav() {
    // Request focus on the scope, then navigate to the currently selected tab
    _bottomNavFocusScopeNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Move to first item, then advance to current index
      _bottomNavFocusScopeNode.nextFocus();
      for (int i = 0; i < _currentIndex; i++) {
        _bottomNavFocusScopeNode.nextFocus();
      }
    });
  }

  /// Focus the content area (called when back is pressed in navbar)
  void _focusContent() {
    _contentFocusScopeNode.requestFocus();
  }

  /// Handle back key in navbar - focus content area
  KeyEventResult _handleNavBarBackKey(FocusNode node, KeyEvent event) {
    if (isBackKeyEvent(event)) {
      _focusContent();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void didPush() {
    // Called when this route has been pushed (initial navigation)
    if (_currentIndex == 0) {
      _onDiscoverBecameVisible();
    }
  }

  @override
  void didPopNext() {
    // Called when returning to this route from a child route (e.g., from video player)
    if (_currentIndex == 0) {
      _onDiscoverBecameVisible();
    }
  }

  void _onDiscoverBecameVisible() {
    appLogger.d('Navigated to home');
    // Refresh content when returning to discover page
    final discoverState = _discoverKey.currentState;
    if (discoverState != null && discoverState is Refreshable) {
      (discoverState as Refreshable).refresh();
    }
  }

  /// Invalidate all cached data across all screens when profile is switched
  /// Receives the list of servers with new profile tokens for reconnection
  Future<void> _invalidateAllScreens(List<PlexServer> servers) async {
    appLogger.d(
      'Invalidating all screen data due to profile switch with ${servers.length} servers',
    );

    // Get all providers
    final multiServerProvider = context.read<MultiServerProvider>();
    final serverStateProvider = context.read<ServerStateProvider>();
    final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
    final playbackStateProvider = context.read<PlaybackStateProvider>();

    // Reconnect to all servers with new profile tokens
    if (servers.isNotEmpty) {
      final storage = await StorageService.getInstance();
      final clientId = storage.getClientIdentifier();

      final connectedCount = await multiServerProvider.reconnectWithServers(
        servers,
        clientIdentifier: clientId,
      );
      appLogger.d(
        'Reconnected to $connectedCount/${servers.length} servers after profile switch',
      );
    }

    // Reset other provider states
    serverStateProvider.reset();
    hiddenLibrariesProvider.refresh();
    playbackStateProvider.clearShuffle();

    appLogger.d('Cleared all provider states for profile switch');

    // Full refresh discover screen (reload all content for new profile)
    final discoverState = _discoverKey.currentState;
    if (discoverState != null) {
      (discoverState as dynamic).fullRefresh();
    }

    // Full refresh libraries screen (clear filters and reload for new profile)
    final librariesState = _librariesKey.currentState;
    if (librariesState != null) {
      (librariesState as dynamic).fullRefresh();
    }

    // Full refresh search screen (clear search for new profile)
    final searchState = _searchKey.currentState;
    if (searchState != null) {
      (searchState as dynamic).fullRefresh();
    }
  }

  /// Public method to switch tabs programmatically
  void switchToTab(int index) {
    _selectTab(index);
  }

  void _selectTab(int index) {
    // Check if selection came from keyboard/d-pad (bottom nav has focus)
    final isKeyboardNavigation = _bottomNavFocusScopeNode.hasFocus;

    setState(() {
      _currentIndex = index;
    });
    // Notify discover screen when it becomes visible via tab switch
    if (index == 0) {
      _onDiscoverBecameVisible();
      // Focus hero when selecting Home tab via keyboard/d-pad
      if (isKeyboardNavigation) {
        final discoverState = _discoverKey.currentState;
        if (discoverState != null) {
          (discoverState as dynamic).focusHero();
        }
      }
    }
    // Focus first content item when selecting Libraries tab via keyboard/d-pad
    if (index == 1 && isKeyboardNavigation) {
      final librariesState = _librariesKey.currentState;
      if (librariesState != null) {
        (librariesState as dynamic).focusFirstContentItem();
      }
    }
    // Focus search input when selecting Search tab (for both click/tap and keyboard)
    if (index == 3) {
      final searchState = _searchKey.currentState;
      if (searchState != null) {
        (searchState as dynamic).focusSearchInput();
      }
    }
    // Move focus to the content area when selecting a tab via keyboard
    if (isKeyboardNavigation) {
      _contentFocusScopeNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTV = PlatformDetector.isTV(context) || PlatformDetector.isDesktop(context);

    return Shortcuts(
      shortcuts: {
        // Number keys 1-8 for quick tab switching
        const SingleActivator(LogicalKeyboardKey.digit1): _TabIntent(0),
        const SingleActivator(LogicalKeyboardKey.digit2): _TabIntent(1),
        const SingleActivator(LogicalKeyboardKey.digit3): _TabIntent(2),
        const SingleActivator(LogicalKeyboardKey.digit4): _TabIntent(3),
        const SingleActivator(LogicalKeyboardKey.digit5): _TabIntent(4),
        const SingleActivator(LogicalKeyboardKey.digit6): _TabIntent(5),
        const SingleActivator(LogicalKeyboardKey.digit7): _TabIntent(6),
        const SingleActivator(LogicalKeyboardKey.digit8): _TabIntent(7),
      },
      child: Actions(
        actions: {
          _TabIntent: CallbackAction<_TabIntent>(
            onInvoke: (intent) {
              _selectTab(intent.tabIndex);
              return null;
            },
          ),
        },
        child: Scaffold(
          body: BackNavigationScope(
            focusBottomNav: _focusBottomNav,
            child: isTV ? _buildTVLayout() : _buildMobileLayout(),
          ),
          bottomNavigationBar: isTV
              ? null
              : FocusScope(
                  node: _bottomNavFocusScopeNode,
                  onKeyEvent: _handleNavBarBackKey,
                  child: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _selectTab,
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home),
                        label: t.navigation.home,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.movie_outlined),
                        selectedIcon: const Icon(Icons.movie),
                        label: t.navigation.movies,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.tv_outlined),
                        selectedIcon: const Icon(Icons.tv),
                        label: t.navigation.tvShows,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.live_tv_outlined),
                        selectedIcon: const Icon(Icons.live_tv),
                        label: t.navigation.livetv,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.search),
                        selectedIcon: const Icon(Icons.search),
                        label: t.navigation.search,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Build mobile layout with bottom navigation
  Widget _buildMobileLayout() {
    return NetflixPreviewOverlay(
      child: FocusScope(
        node: _contentFocusScopeNode,
        child: FocusTraversalGroup(
          child: IndexedStack(index: _currentIndex, children: _screens),
        ),
      ),
    );
  }

  /// Build TV layout with left navigation rail
  Widget _buildTVLayout() {
    return NetflixPreviewOverlay(
      child: Row(
        children: [
          // Left navigation rail with auto-hide
          FocusScope(
            node: _bottomNavFocusScopeNode,
            onKeyEvent: _handleNavBarBackKey,
            child: _TVNavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _selectTab,
              onExpandChange: (expanded) {
                if (expanded != _isSidebarExpanded) {
                  setState(() => _isSidebarExpanded = expanded);
                }
              },
              isExpanded: _isSidebarExpanded,
            ),
          ),
          // Main content area
          Expanded(
            child: FocusScope(
              node: _contentFocusScopeNode,
              child: FocusTraversalGroup(
                child: IndexedStack(index: _currentIndex, children: _screens),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// TV-optimized navigation rail with focus support
class _TVNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<bool>? onExpandChange;
  final bool isExpanded;

  const _TVNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onExpandChange,
    this.isExpanded = false,
  });

  @override
  State<_TVNavigationRail> createState() => _TVNavigationRailState();
}

class _TVNavigationRailState extends State<_TVNavigationRail> {
  final Set<int> _focusedItems = {};

  // Vibrant accent colors for each nav item
  static const _navColors = [
    Color(0xFFF97316), // Orange - Home
    Color(0xFFEF4444), // Red - Movies
    Color(0xFF8B5CF6), // Violet - TV Shows
    Color(0xFF10B981), // Emerald - Libraries
    Color(0xFF3B82F6), // Blue - Live TV
    Color(0xFFF59E0B), // Amber - Catchup
    Color(0xFF06B6D4), // Cyan - Search
    Color(0xFF6366F1), // Indigo - Settings
  ];

  void _onItemFocusChange(int index, bool hasFocus) {
    if (hasFocus) {
      _focusedItems.add(index);
    } else {
      _focusedItems.remove(index);
    }
    // Notify parent about expansion state
    final shouldExpand = _focusedItems.isNotEmpty;
    widget.onExpandChange?.call(shouldExpand);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _NavItem(Icons.home_rounded, Icons.home_rounded, t.navigation.home),
      _NavItem(Icons.movie_rounded, Icons.movie_rounded, t.navigation.movies),
      _NavItem(Icons.tv_rounded, Icons.tv_rounded, t.navigation.tvShows),
      _NavItem(Icons.video_library_rounded, Icons.video_library_rounded, t.navigation.libraries),
      _NavItem(Icons.live_tv_rounded, Icons.live_tv_rounded, t.navigation.livetv),
      _NavItem(Icons.replay_rounded, Icons.replay_rounded, 'Catchup'),
      _NavItem(Icons.search_rounded, Icons.search_rounded, t.navigation.search),
      _NavItem(Icons.settings_rounded, Icons.settings_rounded, t.navigation.settings),
    ];

    final isExpanded = widget.isExpanded;

    return FocusTraversalGroup(
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: isExpanded ? 200 : 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F2937).withValues(alpha: isExpanded ? 1.0 : 0.95),
            const Color(0xFF111827),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: isExpanded
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo/brand with gradient glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: isExpanded ? 0.4 : 0.2),
                  blurRadius: isExpanded ? 24 : 16,
                  spreadRadius: isExpanded ? 0 : -4,
                ),
              ],
            ),
            child: Image.asset(
              'assets/openflix.png',
              width: isExpanded ? 48 : 40,
              height: isExpanded ? 48 : 40,
            ),
          ),
          const SizedBox(height: 32),
          // Divider - only show when expanded
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isExpanded ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Navigation items
          Expanded(
            child: ListView.builder(
              itemCount: destinations.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final item = destinations[index];
                final isSelected = index == widget.selectedIndex;

                return _TVNavItem(
                  icon: isSelected ? item.selectedIcon : item.icon,
                  label: item.label,
                  isSelected: isSelected,
                  isExpanded: isExpanded,
                  accentColor: _navColors[index],
                  onTap: () => widget.onDestinationSelected(index),
                  onFocusChange: (hasFocus) => _onItemFocusChange(index, hasFocus),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItem(this.icon, this.selectedIcon, this.label);
}

/// Individual navigation item with TV focus support
class _TVNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final Color accentColor;
  final VoidCallback onTap;
  final ValueChanged<bool> onFocusChange;

  const _TVNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.accentColor,
    required this.onTap,
    required this.onFocusChange,
  });

  @override
  State<_TVNavItem> createState() => _TVNavItemState();
}

class _TVNavItemState extends State<_TVNavItem> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isFocused || widget.isSelected;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
        widget.onFocusChange(hasFocus);
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
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 14 : 0,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            gradient: isHighlighted
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      widget.accentColor.withValues(alpha: _isFocused ? 0.35 : 0.25),
                      widget.accentColor.withValues(alpha: _isFocused ? 0.15 : 0.08),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHighlighted
                  ? widget.accentColor.withValues(alpha: _isFocused ? 0.6 : 0.4)
                  : Colors.transparent,
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: _isFocused ? 0.35 : 0.2),
                      blurRadius: _isFocused ? 16 : 10,
                      spreadRadius: _isFocused ? 1 : -2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              // Icon with colored background when highlighted
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isHighlighted
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.accentColor,
                            widget.accentColor.withValues(alpha: 0.7),
                          ],
                        )
                      : null,
                  color: isHighlighted ? null : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: isHighlighted
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                      color: isHighlighted
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                      letterSpacing: isHighlighted ? 0.3 : 0,
                    ),
                    overflow: TextOverflow.ellipsis,
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

/// Intent for switching tabs via keyboard shortcuts
class _TabIntent extends Intent {
  final int tabIndex;
  const _TabIntent(this.tabIndex);
}
