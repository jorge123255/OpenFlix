import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/media_item.dart';
import '../services/tmdb_service.dart';

/// A widget that shows a trailer preview on hover/focus
class TrailerPreviewOverlay extends StatefulWidget {
  final MediaItem item;
  final Widget child;
  final Duration hoverDelay;
  final bool enabled;

  const TrailerPreviewOverlay({
    super.key,
    required this.item,
    required this.child,
    this.hoverDelay = const Duration(seconds: 2),
    this.enabled = true,
  });

  @override
  State<TrailerPreviewOverlay> createState() => _TrailerPreviewOverlayState();
}

class _TrailerPreviewOverlayState extends State<TrailerPreviewOverlay> {
  bool _isHovering = false;
  bool _showPreview = false;
  TrailerInfo? _trailer;
  Timer? _hoverTimer;
  bool _isLoading = false;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _onHoverStart() {
    if (!widget.enabled) return;

    _isHovering = true;
    _hoverTimer?.cancel();
    _hoverTimer = Timer(widget.hoverDelay, () {
      if (_isHovering && mounted) {
        _loadTrailer();
      }
    });
  }

  void _onHoverEnd() {
    _isHovering = false;
    _hoverTimer?.cancel();
    if (mounted) {
      setState(() {
        _showPreview = false;
      });
    }
  }

  Future<void> _loadTrailer() async {
    if (_isLoading || _trailer != null) {
      if (_trailer != null) {
        setState(() {
          _showPreview = true;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tmdb = await TmdbService.getInstance();
      if (!tmdb.hasApiKey) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final isMovie = widget.item.type.toLowerCase() == 'movie';
      final title = widget.item.grandparentTitle ?? widget.item.title;

      final trailer = await tmdb.getTrailerForTitle(
        title,
        isMovie: isMovie,
        year: widget.item.year,
      );

      if (mounted && _isHovering) {
        setState(() {
          _trailer = trailer;
          _showPreview = trailer != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openTrailer() async {
    if (_trailer == null) return;

    final url = Uri.parse(_trailer!.watchUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _onHoverStart();
          } else {
            _onHoverEnd();
          }
        },
        child: Stack(
          children: [
            widget.child,

            // Trailer preview overlay
            if (_showPreview && _trailer != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _openTrailer,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Trailer thumbnail
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: _trailer!.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    color: Colors.grey[900],
                                    child: const Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.white54,
                                      size: 48,
                                    ),
                                  ),
                                ),
                                // Play button overlay
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Trailer info
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Text(
                                'Watch Trailer',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _trailer!.name,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A button to play trailer
class TrailerButton extends StatefulWidget {
  final MediaItem item;

  const TrailerButton({
    super.key,
    required this.item,
  });

  @override
  State<TrailerButton> createState() => _TrailerButtonState();
}

class _TrailerButtonState extends State<TrailerButton> {
  TrailerInfo? _trailer;
  bool _isLoading = false;
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkForTrailer();
  }

  Future<void> _checkForTrailer() async {
    if (_hasChecked) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tmdb = await TmdbService.getInstance();
      if (!tmdb.hasApiKey) {
        setState(() {
          _isLoading = false;
          _hasChecked = true;
        });
        return;
      }

      final isMovie = widget.item.type.toLowerCase() == 'movie';
      final title = widget.item.grandparentTitle ?? widget.item.title;

      final trailer = await tmdb.getTrailerForTitle(
        title,
        isMovie: isMovie,
        year: widget.item.year,
      );

      if (mounted) {
        setState(() {
          _trailer = trailer;
          _isLoading = false;
          _hasChecked = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChecked = true;
        });
      }
    }
  }

  Future<void> _openTrailer() async {
    if (_trailer == null) return;

    final url = Uri.parse(_trailer!.watchUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_trailer == null) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.play_circle_outline),
      tooltip: 'Watch Trailer',
      onPressed: _openTrailer,
    );
  }
}
