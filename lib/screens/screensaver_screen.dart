import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../utils/provider_extensions.dart';

/// Screensaver screen showing artwork slideshow with Ken Burns effect
class ScreensaverScreen extends StatefulWidget {
  final List<MediaItem> items;

  const ScreensaverScreen({
    super.key,
    required this.items,
  });

  @override
  State<ScreensaverScreen> createState() => _ScreensaverScreenState();
}

class _ScreensaverScreenState extends State<ScreensaverScreen>
    with TickerProviderStateMixin {
  late List<MediaItem> _shuffledItems;
  int _currentIndex = 0;
  int _nextIndex = 1;
  Timer? _slideTimer;

  late AnimationController _fadeController;
  late AnimationController _kenBurnsController;
  late Animation<double> _fadeAnimation;

  // Ken Burns animation values
  double _currentScale = 1.0;
  double _currentOffsetX = 0.0;
  double _currentOffsetY = 0.0;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Shuffle items for random order
    _shuffledItems = List.from(widget.items)..shuffle();

    // Fade controller for crossfade between images
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Ken Burns controller for pan/zoom effect
    _kenBurnsController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _generateKenBurnsValues();
    _startSlideshow();

    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _generateKenBurnsValues() {
    // Generate random Ken Burns parameters for current slide
    _currentScale = 1.0 + _random.nextDouble() * 0.15; // 1.0 to 1.15
    _currentOffsetX = (_random.nextDouble() - 0.5) * 50; // -25 to 25
    _currentOffsetY = (_random.nextDouble() - 0.5) * 30; // -15 to 15
  }

  void _startSlideshow() {
    _kenBurnsController.forward();

    _slideTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _advanceSlide();
    });
  }

  void _advanceSlide() {
    if (!mounted) return;

    _fadeController.forward().then((_) {
      if (!mounted) return;

      setState(() {
        _currentIndex = _nextIndex;
        _nextIndex = (_nextIndex + 1) % _shuffledItems.length;
        _generateKenBurnsValues();
      });

      _fadeController.reset();
      _kenBurnsController
        ..reset()
        ..forward();
    });
  }

  void _dismiss() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _fadeController.dispose();
    _kenBurnsController.dispose();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  String? _getArtUrl(MediaItem item) {
    try {
      final multiServerProvider = Provider.of<MultiServerProvider>(
        context,
        listen: false,
      );
      if (multiServerProvider.hasConnectedServers) {
        final client = context.getClientForServer(
          item.serverId ?? multiServerProvider.onlineServerIds.first,
        );
        // Prefer art (fanart), fallback to thumb
        if (item.art != null) {
          return client.getThumbnailUrl(item.art!);
        }
        if (item.thumb != null) {
          return client.getThumbnailUrl(item.thumb!);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_shuffledItems.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final currentItem = _shuffledItems[_currentIndex];
    final nextItem = _shuffledItems[_nextIndex];
    final currentArtUrl = _getArtUrl(currentItem);
    final nextArtUrl = _getArtUrl(nextItem);

    return GestureDetector(
      onTap: _dismiss,
      onPanDown: (_) => _dismiss(),
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            _dismiss();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Current image with Ken Burns animation
              AnimatedBuilder(
                animation: _kenBurnsController,
                builder: (context, child) {
                  final progress = _kenBurnsController.value;
                  final scale = 1.0 + (_currentScale - 1.0) * progress;
                  final offsetX = _currentOffsetX * progress;
                  final offsetY = _currentOffsetY * progress;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.translationValues(offsetX, offsetY, 0)
                      ..multiply(Matrix4.diagonal3Values(scale, scale, 1)),
                    child: child,
                  );
                },
                child: currentArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: currentArtUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorWidget: (_, __, ___) =>
                            Container(color: Colors.black),
                      )
                    : Container(color: Colors.black),
              ),

              // Next image fading in
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  );
                },
                child: nextArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: nextArtUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorWidget: (_, __, ___) =>
                            Container(color: Colors.black),
                      )
                    : Container(color: Colors.black),
              ),

              // Gradient vignette
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),

              // Title overlay at bottom
              Positioned(
                left: 48,
                right: 48,
                bottom: 64,
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    // Show current item when fade is less than 0.5, next item otherwise
                    final item = _fadeAnimation.value < 0.5 ? currentItem : nextItem;
                    return Opacity(
                      opacity: _fadeAnimation.value < 0.5
                          ? 1.0 - (_fadeAnimation.value * 2)
                          : (_fadeAnimation.value - 0.5) * 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.grandparentTitle ?? item.title,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.type.toLowerCase() == 'episode') ...[
                            const SizedBox(height: 8),
                            Text(
                              'S${item.parentIndex} · E${item.index} · ${item.title}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 18,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black.withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else if (item.year != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${item.year}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 18,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black.withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Clock in top right
              Positioned(
                top: 48,
                right: 48,
                child: StreamBuilder(
                  stream: Stream.periodic(const Duration(seconds: 1)),
                  builder: (context, snapshot) {
                    final now = DateTime.now();
                    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
                    final displayHour = hour == 0 ? 12 : hour;
                    final minute = now.minute.toString().padLeft(2, '0');
                    final period = now.hour >= 12 ? 'PM' : 'AM';

                    return Text(
                      '$displayHour:$minute $period',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Hint text
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap anywhere to exit',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manages screensaver idle timeout
class ScreensaverManager {
  Timer? _idleTimer;
  final Duration idleTimeout;
  final VoidCallback onIdleTimeout;

  ScreensaverManager({
    this.idleTimeout = const Duration(minutes: 5),
    required this.onIdleTimeout,
  });

  void resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, onIdleTimeout);
  }

  void stopIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void dispose() {
    stopIdleTimer();
  }
}
