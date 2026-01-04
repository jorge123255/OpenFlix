import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../providers/multi_server_provider.dart';
import '../utils/provider_extensions.dart';

/// Ambient Mode background widget - shows slow-moving artwork
/// Use this as a background layer on screens for a cinematic feel
class AmbientBackground extends StatefulWidget {
  final List<MediaItem>? items;
  final Duration transitionDuration;
  final Duration displayDuration;
  final double opacity;
  final bool showGradientOverlay;
  final Widget child;

  const AmbientBackground({
    super.key,
    this.items,
    this.transitionDuration = const Duration(seconds: 3),
    this.displayDuration = const Duration(seconds: 12),
    this.opacity = 0.15,
    this.showGradientOverlay = true,
    required this.child,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with TickerProviderStateMixin {
  List<MediaItem> _items = [];
  int _currentIndex = 0;
  Timer? _slideTimer;
  final Random _random = Random();

  late AnimationController _fadeController;
  late AnimationController _panController;
  late Animation<double> _fadeAnimation;

  // Pan animation values
  Offset _currentPanStart = Offset.zero;
  Offset _currentPanEnd = Offset.zero;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: widget.transitionDuration,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _panController = AnimationController(
      duration: widget.displayDuration,
      vsync: this,
    );

    if (widget.items != null && widget.items!.isNotEmpty) {
      _items = List.from(widget.items!)..shuffle();
      _startSlideshow();
    }
  }

  @override
  void didUpdateWidget(AmbientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      if (widget.items != null && widget.items!.isNotEmpty) {
        _items = List.from(widget.items!)..shuffle();
        if (_slideTimer == null) {
          _startSlideshow();
        }
      }
    }
  }

  void _generatePanValues() {
    // Generate subtle pan movement
    final startX = (_random.nextDouble() - 0.5) * 0.1;
    final startY = (_random.nextDouble() - 0.5) * 0.05;
    final endX = (_random.nextDouble() - 0.5) * 0.1;
    final endY = (_random.nextDouble() - 0.5) * 0.05;

    _currentPanStart = Offset(startX, startY);
    _currentPanEnd = Offset(endX, endY);
  }

  void _startSlideshow() {
    if (_items.isEmpty) return;

    _generatePanValues();
    _panController.forward();

    _slideTimer = Timer.periodic(widget.displayDuration, (timer) {
      _advanceSlide();
    });
  }

  void _advanceSlide() {
    if (!mounted || _items.isEmpty) return;

    _fadeController.forward().then((_) {
      if (!mounted) return;

      setState(() {
        _currentIndex = (_currentIndex + 1) % _items.length;
        _generatePanValues();
      });

      _fadeController.reset();
      _panController
        ..reset()
        ..forward();
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _fadeController.dispose();
    _panController.dispose();
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
        // Prefer art (fanart) for ambient mode
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background artwork
        if (_items.isNotEmpty) ...[
          // Current image with pan animation
          AnimatedBuilder(
            animation: _panController,
            builder: (context, child) {
              final progress = _panController.value;
              final pan = Offset.lerp(
                _currentPanStart,
                _currentPanEnd,
                progress,
              )!;

              return Transform.translate(
                offset: Offset(
                  pan.dx * MediaQuery.of(context).size.width,
                  pan.dy * MediaQuery.of(context).size.height,
                ),
                child: Transform.scale(
                  scale: 1.1 + (progress * 0.05), // Subtle zoom
                  child: child,
                ),
              );
            },
            child: Opacity(
              opacity: widget.opacity,
              child: _buildImage(_items[_currentIndex]),
            ),
          ),

          // Next image fading in
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              if (_fadeAnimation.value == 0) return const SizedBox.shrink();
              return Opacity(
                opacity: _fadeAnimation.value * widget.opacity,
                child: child,
              );
            },
            child: _buildImage(
              _items[(_currentIndex + 1) % _items.length],
            ),
          ),
        ],

        // Gradient overlay for readability
        if (widget.showGradientOverlay)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3),
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

        // Child content
        widget.child,
      ],
    );
  }

  Widget _buildImage(MediaItem item) {
    final url = _getArtUrl(item);
    if (url == null) return const SizedBox.shrink();

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

/// A simpler ambient gradient that pulses slowly
class AmbientGradient extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final Duration cycleDuration;

  const AmbientGradient({
    super.key,
    required this.child,
    this.colors,
    this.cycleDuration = const Duration(seconds: 10),
  });

  @override
  State<AmbientGradient> createState() => _AmbientGradientState();
}

class _AmbientGradientState extends State<AmbientGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.cycleDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColors = [
      theme.colorScheme.primary.withValues(alpha: 0.1),
      theme.colorScheme.secondary.withValues(alpha: 0.1),
      theme.colorScheme.tertiary.withValues(alpha: 0.1),
    ];
    final colors = widget.colors ?? defaultColors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final rotatedColors = [
          ...colors.sublist((progress * colors.length).floor() % colors.length),
          ...colors.sublist(0, (progress * colors.length).floor() % colors.length),
        ];

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: rotatedColors.take(3).toList(),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
