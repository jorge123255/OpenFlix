import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../services/settings_service.dart';
import '../utils/content_rating_filter.dart';
import '../utils/video_player_navigation.dart';

/// Channel Surfing Mode - plays random content continuously like TV
class ChannelSurfingScreen extends StatefulWidget {
  const ChannelSurfingScreen({super.key});

  @override
  State<ChannelSurfingScreen> createState() => _ChannelSurfingScreenState();
}

class _ChannelSurfingScreenState extends State<ChannelSurfingScreen> {
  List<MediaItem> _allContent = [];
  bool _isLoading = true;
  String? _error;
  final Random _random = Random();
  SettingsService? _settingsService;
  bool _isKidsMode = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  Future<void> _initSettings() async {
    _settingsService = await SettingsService.getInstance();
    _isKidsMode = _settingsService?.getKidsModeEnabled() ?? false;
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );

      if (!multiServerProvider.hasConnectedServers) {
        throw Exception(t.channelSurfing.noServers);
      }

      // Collect all playable content from libraries
      final allItems = <MediaItem>[];

      for (final serverId in multiServerProvider.onlineServerIds) {
        final client = multiServerProvider.getClientForServer(serverId);
        if (client == null) continue;

        // Get all libraries
        final libraries = await client.getLibraries();

        for (final library in libraries) {
          // Only include movie and show libraries
          if (library.type != 'movie' && library.type != 'show') continue;

          // Get library content
          final content = await client.getLibraryContent(library.key);

          // Filter by content rating if parental controls or kids mode enabled
          for (final item in content) {
            final isMovie = library.type == 'movie';
            final isAllowed = _settingsService != null
                ? await isContentAllowed(item.contentRating, isMovie, _settingsService!)
                : true;

            if (isAllowed) {
              allItems.add(item);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _allContent = allItems;
          _isLoading = false;
        });

        // Start surfing immediately
        if (_allContent.isNotEmpty) {
          _playRandomContent();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playRandomContent() async {
    if (_allContent.isEmpty) return;

    // Pick a random item
    final randomIndex = _random.nextInt(_allContent.length);
    var item = _allContent[randomIndex];

    // If it's a show, get a random episode
    if (item.type.toLowerCase() == 'show') {
      try {
        final multiServerProvider = Provider.of<MultiServerProvider>(
          context,
          listen: false,
        );
        final client = multiServerProvider.getClientForServer(item.serverId ?? '');
        if (client != null) {
          // Get seasons
          final seasons = await client.getChildren(item.ratingKey);
          if (seasons.isNotEmpty) {
            // Pick random season
            final randomSeason = seasons[_random.nextInt(seasons.length)];
            // Get episodes
            final episodes = await client.getChildren(randomSeason.ratingKey);
            if (episodes.isNotEmpty) {
              // Pick random episode
              item = episodes[_random.nextInt(episodes.length)];
            }
          }
        }
      } catch (e) {
        // If we can't get episodes, just skip this item
        _playRandomContent();
        return;
      }
    }

    if (!mounted) return;

    // Navigate to video player
    final result = await navigateToVideoPlayer(
      context,
      metadata: item,
    );

    // When player exits, play next random content (unless user pressed back)
    if (mounted && result == true) {
      // User watched or skipped - continue surfing
      _playRandomContent();
    } else if (mounted) {
      // User pressed back - exit channel surfing
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.goBack) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: _isLoading ? null : _playRandomContent,
          child: Center(
            child: _isLoading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 24),
                      Text(
                        t.channelSurfing.loading,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  )
                : _error != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.channelSurfing.failedToLoad,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadContent,
                            child: Text(t.channelSurfing.retry),
                          ),
                        ],
                      )
                    : _allContent.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.tv_off,
                                color: Colors.white,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t.channelSurfing.noContent,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isKidsMode ? Icons.child_care : Icons.shuffle,
                                color: _isKidsMode ? Colors.pink : Colors.white,
                                size: 80,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _isKidsMode ? t.channelSurfing.kidsMode : t.channelSurfing.title,
                                style: TextStyle(
                                  color: _isKidsMode ? Colors.pink : Colors.white.withValues(alpha: 0.9),
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.channelSurfing.itemsAvailable(count: _allContent.length.toString()),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _playRandomContent,
                                icon: const Icon(Icons.play_arrow),
                                label: Text(t.channelSurfing.startSurfing),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t.channelSurfing.pressBackToExit,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
          ),
        ),
      ),
    );
  }
}

/// Shows a bottom sheet to start channel surfing
Future<void> showChannelSurfingSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shuffle, size: 48),
          const SizedBox(height: 16),
          Text(
            t.channelSurfing.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            t.channelSurfing.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChannelSurfingScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(t.channelSurfing.startSurfing),
            ),
          ),
        ],
      ),
    ),
  );
}
