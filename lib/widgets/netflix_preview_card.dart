import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/media_item.dart';
import '../providers/media_client_provider.dart';
import '../services/tmdb_service.dart';
import '../services/video_preview_service.dart';

/// Netflix-style expanded preview card that appears on focus
class NetflixPreviewCard extends StatefulWidget {
  final MediaItem item;
  final Offset position;
  final Size cardSize;
  final VoidCallback onClose;
  final VoidCallback onPlay;
  final VoidCallback onDetails;

  const NetflixPreviewCard({
    super.key,
    required this.item,
    required this.position,
    required this.cardSize,
    required this.onClose,
    required this.onPlay,
    required this.onDetails,
  });

  @override
  State<NetflixPreviewCard> createState() => _NetflixPreviewCardState();
}

class _NetflixPreviewCardState extends State<NetflixPreviewCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  TrailerInfo? _trailer;
  bool _isLoadingTrailer = false;
  bool _showVideo = false;
  bool _isMuted = true;
  Timer? _unmuteTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _loadTrailer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _unmuteTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrailer() async {
    final previewService = VideoPreviewService.instance;
    final cached = previewService.getCachedTrailer(widget.item.globalKey);

    if (cached != null) {
      setState(() {
        _trailer = cached;
        _showVideo = true;
      });
      _startUnmuteTimer();
      return;
    }

    setState(() => _isLoadingTrailer = true);

    final trailer = await previewService.fetchTrailer(widget.item);

    if (mounted) {
      setState(() {
        _trailer = trailer;
        _isLoadingTrailer = false;
        _showVideo = trailer != null;
      });

      if (trailer != null) {
        _startUnmuteTimer();
      }
    }
  }

  void _startUnmuteTimer() {
    _unmuteTimer?.cancel();
    _unmuteTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isMuted = false);
      }
    });
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
    final screenSize = MediaQuery.of(context).size;
    final expandedWidth = widget.cardSize.width * 1.5;
    final expandedHeight = widget.cardSize.height * 1.4;

    // Calculate position to keep card on screen
    double left = widget.position.dx - (expandedWidth - widget.cardSize.width) / 2;
    double top = widget.position.dy - (expandedHeight - widget.cardSize.height) / 2;

    // Clamp to screen bounds
    left = left.clamp(16.0, screenSize.width - expandedWidth - 16);
    top = top.clamp(16.0, screenSize.height - expandedHeight - 16);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: top,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Material(
                color: Colors.transparent,
                child: MouseRegion(
                  onExit: (_) => _closeWithAnimation(),
                  child: GestureDetector(
                    onTap: widget.onDetails,
                    child: Container(
                      width: expandedWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Video/Image preview
                          _buildPreviewArea(expandedWidth),
                          // Info section
                          _buildInfoSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewArea(double width) {
    final height = width * 0.56; // 16:9 aspect ratio

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            _buildBackgroundImage(),

            // Video overlay (if trailer available)
            if (_showVideo && _trailer != null) _buildVideoOverlay(),

            // Loading indicator
            if (_isLoadingTrailer)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // Gradient overlay for text visibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.grey[900]!,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Mute button (if video playing)
            if (_showVideo && _trailer != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => setState(() => _isMuted = !_isMuted),
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final client = context.read<MediaClientProvider>().client;
    final imageUrl = widget.item.art ?? widget.item.grandparentArt ?? widget.item.thumb;

    if (imageUrl == null || client == null) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.movie, color: Colors.white54, size: 48),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: client.getThumbnailUrl(imageUrl),
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.movie, color: Colors.white54, size: 48),
        ),
      ),
    );
  }

  Widget _buildVideoOverlay() {
    // YouTube thumbnail with play button
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: _trailer!.thumbnailUrl,
          fit: BoxFit.cover,
        ),
        // Play trailer button
        Center(
          child: GestureDetector(
            onTap: _openTrailer,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        // "Watch Trailer" label
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Text(
            'Watch Trailer',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row
          Row(
            children: [
              // Play button
              ElevatedButton.icon(
                onPressed: widget.onPlay,
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Play'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              // Add to list button
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  side: BorderSide(color: Colors.grey[600]!),
                ),
                tooltip: 'Add to My List',
              ),
              const SizedBox(width: 4),
              // Like button
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.thumb_up_outlined, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  side: BorderSide(color: Colors.grey[600]!),
                ),
                tooltip: 'Like',
              ),
              const Spacer(),
              // More info button
              IconButton(
                onPressed: widget.onDetails,
                icon: const Icon(Icons.expand_more, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  side: BorderSide(color: Colors.grey[600]!),
                ),
                tooltip: 'More Info',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Metadata row
          Row(
            children: [
              // Match percentage (placeholder)
              Text(
                '98% Match',
                style: TextStyle(
                  color: Colors.green[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              // Year
              if (widget.item.year != null)
                Text(
                  '${widget.item.year}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              const SizedBox(width: 8),
              // Content rating
              if (widget.item.contentRating != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[600]!),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    widget.item.contentRating!,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ),
              const SizedBox(width: 8),
              // Duration
              if (widget.item.duration != null)
                Text(
                  _formatDuration(widget.item.duration!),
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Genre tags
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildGenreChip(widget.item.type == 'movie' ? 'Movie' : 'TV Show'),
              if (widget.item.studio != null) _buildGenreChip(widget.item.studio!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final minutes = milliseconds ~/ 60000;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  Future<void> _closeWithAnimation() async {
    await _animationController.reverse();
    widget.onClose();
  }
}

/// Mixin for preview overlay functionality
mixin NetflixPreviewOverlayMixin {
  /// Schedule showing a preview card after delay
  void schedulePreview({
    required MediaItem item,
    required Offset position,
    required Size cardSize,
    required VoidCallback onPlay,
    required VoidCallback onDetails,
    Duration delay = const Duration(milliseconds: 800),
  });

  /// Cancel scheduled preview
  void cancelPreview();
}

/// Overlay manager to show Netflix preview cards
class NetflixPreviewOverlay extends StatefulWidget {
  final Widget child;

  const NetflixPreviewOverlay({
    super.key,
    required this.child,
  });

  static NetflixPreviewOverlayMixin? of(BuildContext context) {
    return context.findAncestorStateOfType<_NetflixPreviewOverlayState>();
  }

  @override
  State<NetflixPreviewOverlay> createState() => _NetflixPreviewOverlayState();
}

class _NetflixPreviewOverlayState extends State<NetflixPreviewOverlay>
    with NetflixPreviewOverlayMixin {
  OverlayEntry? _overlayEntry;
  Timer? _showTimer;

  /// Schedule showing a preview card after delay
  @override
  void schedulePreview({
    required MediaItem item,
    required Offset position,
    required Size cardSize,
    required VoidCallback onPlay,
    required VoidCallback onDetails,
    Duration delay = const Duration(milliseconds: 800),
  }) {
    cancelPreview();

    _showTimer = Timer(delay, () {
      _showPreview(
        item: item,
        position: position,
        cardSize: cardSize,
        onPlay: onPlay,
        onDetails: onDetails,
      );
    });
  }

  /// Cancel scheduled preview
  @override
  void cancelPreview() {
    _showTimer?.cancel();
    _showTimer = null;
    _hidePreview();
  }

  void _showPreview({
    required MediaItem item,
    required Offset position,
    required Size cardSize,
    required VoidCallback onPlay,
    required VoidCallback onDetails,
  }) {
    _hidePreview();

    _overlayEntry = OverlayEntry(
      builder: (context) => NetflixPreviewCard(
        item: item,
        position: position,
        cardSize: cardSize,
        onClose: _hidePreview,
        onPlay: () {
          _hidePreview();
          onPlay();
        },
        onDetails: () {
          _hidePreview();
          onDetails();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hidePreview() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
