import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/livetv_channel.dart';
import '../mpv/mpv.dart';
import '../services/last_watched_service.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';

/// Docked/mini player widget for the home screen
/// Displays the last watched channel in a compact player at the top of the screen
/// Similar to DirecTV's home screen player that auto-plays last watched content
class DockedPlayer extends StatefulWidget {
  /// Callback when user taps to expand to fullscreen
  final VoidCallback? onExpandToFullscreen;

  /// Callback when user changes the channel
  final void Function(LiveTVChannel)? onChannelChange;

  /// List of available channels for navigation
  final List<LiveTVChannel> channels;

  /// Whether the player should be visible
  final bool isVisible;

  /// Whether to auto-play on mount
  final bool autoPlay;

  /// Height of the docked player
  final double height;

  const DockedPlayer({
    super.key,
    this.onExpandToFullscreen,
    this.onChannelChange,
    this.channels = const [],
    this.isVisible = true,
    this.autoPlay = true,
    this.height = 200,
  });

  @override
  State<DockedPlayer> createState() => DockedPlayerState();
}

class DockedPlayerState extends State<DockedPlayer> with WidgetsBindingObserver {
  Player? _player;
  bool _isPlayerInitialized = false;
  LiveTVChannel? _currentChannel;
  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(true);
  StreamSubscription<bool>? _bufferingSubscription;
  String? _errorMessage;
  bool _isMuted = false;
  bool _showControls = false;
  Timer? _controlsTimer;
  final FocusNode _focusNode = FocusNode(debugLabel: 'DockedPlayer');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.autoPlay) {
      _loadLastWatchedChannel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bufferingSubscription?.cancel();
    _controlsTimer?.cancel();
    _player?.dispose();
    _isBuffering.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _player?.pause();
    } else if (state == AppLifecycleState.resumed && _currentChannel != null) {
      _player?.play();
    }
  }

  Future<void> _loadLastWatchedChannel() async {
    try {
      final lastWatchedService = await LastWatchedService.getInstance();
      final lastChannel = lastWatchedService.getLastWatchedChannel();

      if (lastChannel != null && mounted) {
        setState(() {
          _currentChannel = lastChannel;
        });
        await _initializePlayer();
        await _playChannel(lastChannel);
      }
    } catch (e) {
      appLogger.e('Failed to load last watched channel', error: e);
    }
  }

  Future<void> _initializePlayer() async {
    if (_isPlayerInitialized) return;

    try {
      final settingsService = await SettingsService.getInstance();
      final bufferSizeMB = settingsService.getBufferSize();
      final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
      final enableHardwareDecoding = settingsService.getEnableHardwareDecoding();

      _player = Player();

      // Configure player for live streaming (lower latency for docked player)
      await _player!.setProperty('demuxer-max-bytes', bufferSizeBytes.toString());
      await _player!.setProperty('hwdec', enableHardwareDecoding ? 'auto-safe' : 'no');
      await _player!.setProperty('cache', 'yes');
      await _player!.setProperty('cache-secs', '10');
      await _player!.setProperty('demuxer-readahead-secs', '10');
      await _player!.setProperty(
        'stream-lavf-o',
        'reconnect=1,reconnect_streamed=1,reconnect_delay_max=2',
      );

      // Start muted for docked player (user can unmute)
      await _player!.setVolume(0);

      _bufferingSubscription = _player!.streams.buffering.listen((buffering) {
        _isBuffering.value = buffering;
      });

      setState(() {
        _isPlayerInitialized = true;
        _isMuted = true;
      });
    } catch (e) {
      appLogger.e('Failed to initialize docked player', error: e);
      setState(() {
        _errorMessage = 'Failed to initialize player';
      });
    }
  }

  Future<void> _playChannel(LiveTVChannel channel) async {
    if (_player == null) return;

    try {
      setState(() {
        _currentChannel = channel;
        _errorMessage = null;
      });

      await _player!.open(Media(channel.streamUrl));

      // Update last watched service
      final lastWatchedService = await LastWatchedService.getInstance();
      await lastWatchedService.setLastWatchedChannel(channel);

      widget.onChannelChange?.call(channel);
    } catch (e) {
      appLogger.e('Failed to play channel: ${channel.name}', error: e);
      setState(() {
        _errorMessage = 'Failed to play ${channel.name}';
      });
    }
  }

  /// Play a specific channel
  Future<void> playChannel(LiveTVChannel channel) async {
    if (!_isPlayerInitialized) {
      await _initializePlayer();
    }
    await _playChannel(channel);
  }

  /// Stop playback
  void stop() {
    _player?.stop();
    setState(() {
      _currentChannel = null;
    });
  }

  /// Toggle mute
  void toggleMute() async {
    if (_player == null) return;

    final settingsService = await SettingsService.getInstance();
    final savedVolume = settingsService.getVolume();

    if (_isMuted) {
      await _player!.setVolume(savedVolume);
    } else {
      await _player!.setVolume(0);
    }

    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Enter to expand to fullscreen
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      widget.onExpandToFullscreen?.call();
      return KeyEventResult.handled;
    }

    // M or Space to toggle mute
    if (event.logicalKey == LogicalKeyboardKey.keyM ||
        event.logicalKey == LogicalKeyboardKey.space) {
      toggleMute();
      _showControlsTemporarily();
      return KeyEventResult.handled;
    }

    // Show controls on any other key
    _showControlsTemporarily();

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible || _currentChannel == null) {
      return const SizedBox.shrink();
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          _showControlsTemporarily();
          _focusNode.requestFocus();
        },
        onDoubleTap: widget.onExpandToFullscreen,
        child: MouseRegion(
          onEnter: (_) => _showControlsTemporarily(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video player
                if (_isPlayerInitialized && _player != null)
                  Video(player: _player!)
                else
                  Container(color: Colors.black),

                // Buffering indicator
                ValueListenableBuilder<bool>(
                  valueListenable: _isBuffering,
                  builder: (context, isBuffering, child) {
                    if (!isBuffering) return const SizedBox.shrink();
                    return Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    );
                  },
                ),

                // Error message
                if (_errorMessage != null)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Gradient overlay for controls
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // "LIVE" badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Mute indicator
                if (_isMuted)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.volume_off,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),

                // Bottom info bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.7,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Channel logo
                          if (_currentChannel?.logo != null)
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: _currentChannel!.logo!,
                                fit: BoxFit.contain,
                                errorWidget: (context, url, error) => Icon(
                                  Icons.tv,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          // Channel info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentChannel?.name ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_currentChannel?.nowPlaying != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentChannel!.nowPlaying!.title,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Expand button
                          if (_showControls)
                            IconButton(
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                              ),
                              onPressed: widget.onExpandToFullscreen,
                              tooltip: 'Watch fullscreen',
                            ),
                          // Mute button
                          if (_showControls)
                            IconButton(
                              icon: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                              ),
                              onPressed: toggleMute,
                              tooltip: _isMuted ? 'Unmute' : 'Mute',
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Focus indicator
                if (_focusNode.hasFocus)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        ),
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
}
