import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../utils/video_player_navigation.dart';
import '../screens/media_detail_screen.dart';
import '../i18n/strings.g.dart';

/// Netflix-style "Surprise Me" / Random Picker button with slot-machine animation
class RandomPickerButton extends StatelessWidget {
  final VoidCallback? onTap;

  const RandomPickerButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRandomPicker(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.casino, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                t.discover.surpriseMe,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRandomPicker(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RandomPickerDialog(),
    );
  }
}

/// Full-screen random picker dialog with slot-machine animation
class RandomPickerDialog extends StatefulWidget {
  const RandomPickerDialog({super.key});

  @override
  State<RandomPickerDialog> createState() => _RandomPickerDialogState();
}

class _RandomPickerDialogState extends State<RandomPickerDialog>
    with TickerProviderStateMixin {
  List<MediaItem> _allMovies = [];
  bool _isLoading = true;
  bool _isSpinning = false;
  MediaItem? _selectedMovie;
  final Random _random = Random();

  late AnimationController _spinController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  int _currentDisplayIndex = 0;
  Timer? _spinTimer;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _loadMovies();
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _spinController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );

      if (!multiServerProvider.hasConnectedServers) {
        throw Exception('No servers available');
      }

      final allMovies = <MediaItem>[];

      for (final serverId in multiServerProvider.onlineServerIds) {
        final client = multiServerProvider.getClientForServer(serverId);
        if (client == null) continue;

        final libraries = await client.getLibraries();

        for (final library in libraries) {
          // Only include movie libraries
          if (library.type != 'movie') continue;

          final content = await client.getLibraryContent(library.key);
          allMovies.addAll(content);
        }
      }

      if (mounted) {
        setState(() {
          _allMovies = allMovies;
          _isLoading = false;
        });

        // Auto-start the spin
        if (_allMovies.isNotEmpty) {
          _startSpin();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startSpin() {
    if (_allMovies.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _selectedMovie = null;
    });

    // Spin animation - starts fast, slows down over 3 seconds
    int spinCount = 0;
    const totalSpins = 30;
    int delay = 50;

    void doSpin() {
      if (spinCount >= totalSpins || !mounted) {
        _finishSpin();
        return;
      }

      setState(() {
        _currentDisplayIndex = _random.nextInt(_allMovies.length);
      });

      spinCount++;
      // Slow down progressively
      delay = (50 + (spinCount * 10)).clamp(50, 400);

      _spinTimer = Timer(Duration(milliseconds: delay), doSpin);
    }

    doSpin();
  }

  void _finishSpin() {
    if (!mounted) return;

    // Pick final random movie
    final finalIndex = _random.nextInt(_allMovies.length);

    setState(() {
      _currentDisplayIndex = finalIndex;
      _selectedMovie = _allMovies[finalIndex];
      _isSpinning = false;
    });

    // Play bounce animation
    _bounceController.forward(from: 0);
  }

  void _playMovie() {
    if (_selectedMovie == null) return;

    Navigator.of(context).pop();

    navigateToVideoPlayer(
      context,
      metadata: _selectedMovie!,
    );
  }

  void _viewDetails() {
    if (_selectedMovie == null) return;

    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(metadata: _selectedMovie!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.goBack) {
              Navigator.of(context).pop();
              return KeyEventResult.handled;
            }
            if (!_isSpinning && _selectedMovie != null) {
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select) {
                _playMovie();
                return KeyEventResult.handled;
              }
            }
            if (event.logicalKey == LogicalKeyboardKey.space) {
              if (!_isSpinning && _allMovies.isNotEmpty) {
                _startSpin();
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.casino, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      t.discover.randomPicker,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(t.discover.loadingMovies),
                            ],
                          ),
                        )
                      : _allMovies.isEmpty
                          ? Center(
                              child: Text(
                                t.discover.noMoviesFound,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Movie poster display area
                                ScaleTransition(
                                  scale: _selectedMovie != null
                                      ? _bounceAnimation
                                      : const AlwaysStoppedAnimation(1.0),
                                  child: Container(
                                    width: 200,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _isSpinning
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.5)
                                              : Colors.black
                                                  .withValues(alpha: 0.3),
                                          blurRadius: _isSpinning ? 20 : 10,
                                          spreadRadius: _isSpinning ? 3 : 1,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildMoviePoster(),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Movie title
                                if (_selectedMovie != null && !_isSpinning)
                                  Text(
                                    _selectedMovie!.displayTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else if (_isSpinning)
                                  Text(
                                    t.discover.spinning,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),

                                const SizedBox(height: 24),

                                // Action buttons
                                if (_selectedMovie != null && !_isSpinning)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Play button
                                      ElevatedButton.icon(
                                        onPressed: _playMovie,
                                        icon: const Icon(Icons.play_arrow),
                                        label: Text(t.common.play),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Details button
                                      OutlinedButton.icon(
                                        onPressed: _viewDetails,
                                        icon: const Icon(Icons.info_outline),
                                        label: Text(t.common.details),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 16),

                                // Spin again button
                                if (!_isSpinning)
                                  TextButton.icon(
                                    onPressed: _startSpin,
                                    icon: const Icon(Icons.refresh),
                                    label: Text(t.discover.spinAgain),
                                  ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoviePoster() {
    if (_allMovies.isEmpty) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.movie, size: 48, color: Colors.white54),
        ),
      );
    }

    final movie = _allMovies[_currentDisplayIndex];
    final posterUrl = movie.posterThumb();

    if (posterUrl == null) {
      return Container(
        color: Colors.grey[800],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.movie, size: 48, color: Colors.white54),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  movie.displayTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );
      final client = multiServerProvider.getClientForServer(
        movie.serverId ?? multiServerProvider.onlineServerIds.first,
      );

      if (client == null) {
        return Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(Icons.movie, size: 48, color: Colors.white54),
          ),
        );
      }

      return CachedNetworkImage(
        imageUrl: client.getThumbnailUrl(posterUrl),
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[800],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(Icons.movie, size: 48, color: Colors.white54),
          ),
        ),
      );
    } catch (e) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.movie, size: 48, color: Colors.white54),
        ),
      );
    }
  }
}
