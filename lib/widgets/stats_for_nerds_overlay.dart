import 'dart:async';

import 'package:flutter/material.dart';

import '../mpv/mpv.dart';
import '../utils/mpv_stats_formatter.dart';

/// Stats overlay showing technical playback information
/// Similar to YouTube's "Stats for nerds" feature
class StatsForNerdsOverlay extends StatefulWidget {
  final Player player;
  final String? streamUrl;

  const StatsForNerdsOverlay({
    super.key,
    required this.player,
    this.streamUrl,
  });

  @override
  State<StatsForNerdsOverlay> createState() => _StatsForNerdsOverlayState();
}

class _StatsForNerdsOverlayState extends State<StatsForNerdsOverlay> {
  Timer? _updateTimer;
  String _videoCodec = 'N/A';
  String _audioCodec = 'N/A';
  String _resolution = 'N/A';
  String _fps = 'N/A';
  String _bufferHealth = 'N/A';
  String _droppedFrames = 'N/A';
  String _decoderInfo = 'N/A';
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _updateStats();
    // Update stats every 1.5 seconds
    _updateTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted) {
        _updateStats();
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateStats() async {
    // Don't update if widget is no longer mounted
    if (!mounted) return;

    try {
      // Get audio track info
      final tracks = widget.player.state.tracks;
      final audioTrack = tracks.audio.isNotEmpty
          ? tracks.audio.first
          : AudioTrack(
              id: '0',
              title: '',
              codec: '',
            );

      // Get properties from MPV (with timeout to avoid blocking)
      String? hwdec;
      String? videoCodec;
      int? droppedFrameDecoder;
      int? droppedFrameOutput;
      double? containerFps;
      int? videoWidth;
      int? videoHeight;

      try {
        hwdec = await widget.player.getProperty('hwdec-current');
      } catch (e) {
        hwdec = 'auto';
      }

      try {
        videoCodec = await widget.player.getProperty('video-codec');
      } catch (e) {
        videoCodec = null;
      }

      try {
        final decoderDropStr = await widget.player.getProperty('decoder-frame-drop-count');
        droppedFrameDecoder = decoderDropStr != null ? int.tryParse(decoderDropStr) : null;
      } catch (e) {
        droppedFrameDecoder = 0;
      }

      try {
        final frameDropStr = await widget.player.getProperty('frame-drop-count');
        droppedFrameOutput = frameDropStr != null ? int.tryParse(frameDropStr) : null;
      } catch (e) {
        droppedFrameOutput = 0;
      }

      try {
        final fpsStr = await widget.player.getProperty('container-fps');
        containerFps = fpsStr != null ? double.tryParse(fpsStr) : null;
      } catch (e) {
        containerFps = null;
      }

      try {
        final widthStr = await widget.player.getProperty('width');
        videoWidth = widthStr != null ? int.tryParse(widthStr) : null;
      } catch (e) {
        videoWidth = null;
      }

      try {
        final heightStr = await widget.player.getProperty('height');
        videoHeight = heightStr != null ? int.tryParse(heightStr) : null;
      } catch (e) {
        videoHeight = null;
      }

      if (mounted) {
        setState(() {
          _videoCodec = formatCodec(videoCodec);
          _audioCodec = formatAudioCodec(audioTrack.codec);
          _resolution = formatResolution(videoWidth, videoHeight);
          _fps = formatFramerate(containerFps);
          _decoderInfo = hwdec != null && hwdec != 'no' ? 'HW ($hwdec)' : 'SW';

          final totalDropped = (droppedFrameDecoder ?? 0) + (droppedFrameOutput ?? 0);
          _droppedFrames = formatDroppedFrames(totalDropped, null);

          // Buffer health - use cache status
          try {
            final cacheUsed = widget.player.state.buffer;
            if (cacheUsed.inSeconds > 0) {
              _bufferHealth = '${cacheUsed.inSeconds.toDouble().toStringAsFixed(1)}s';
            } else {
              _bufferHealth = 'Live';
            }
          } catch (e) {
            _bufferHealth = 'N/A';
          }

          _isBuffering = widget.player.state.buffering;
        });
      }
    } catch (e) {
      // Silently fail - stats overlay is non-critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Text(
                  'Stats for Nerds',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isBuffering) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.yellow[700]!,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 8),
            // Stats rows
            _buildStatRow('Video', _videoCodec),
            _buildStatRow('Audio', _audioCodec),
            _buildStatRow('Resolution', _resolution),
            _buildStatRow('Framerate', _fps),
            _buildStatRow('Decoder', _decoderInfo),
            _buildStatRow('Buffer', _bufferHealth),
            _buildStatRow('Dropped', _droppedFrames),
            if (widget.streamUrl != null) ...[
              const SizedBox(height: 4),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 4),
              _buildStatRow('Stream', _shortenUrl(widget.streamUrl!), mono: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: mono ? 'monospace' : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final path = uri.path;

      // Show host and truncated path
      if (path.length > 30) {
        return '$host/...${path.substring(path.length - 20)}';
      }
      return '$host$path';
    } catch (e) {
      // Fallback to simple truncation
      if (url.length > 40) {
        return '...${url.substring(url.length - 37)}';
      }
      return url;
    }
  }
}
