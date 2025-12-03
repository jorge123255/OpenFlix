import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/livetv_channel.dart';
import '../mpv/mpv.dart';
import '../providers/plex_client_provider.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';

/// Live TV player screen with channel surfing support
class LiveTVPlayerScreen extends StatefulWidget {
  final LiveTVChannel channel;
  final List<LiveTVChannel> channels;

  const LiveTVPlayerScreen({
    super.key,
    required this.channel,
    required this.channels,
  });

  @override
  State<LiveTVPlayerScreen> createState() => _LiveTVPlayerScreenState();
}

class _LiveTVPlayerScreenState extends State<LiveTVPlayerScreen> {
  Player? _player;
  bool _isPlayerInitialized = false;
  late LiveTVChannel _currentChannel;
  int _currentChannelIndex = 0;
  bool _showOverlay = true;
  Timer? _overlayTimer;
  Timer? _programRefreshTimer;
  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(true);
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<String>? _errorSubscription;

  // Channel number input for direct channel selection
  String _channelNumberInput = '';
  Timer? _channelInputTimer;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _currentChannelIndex = widget.channels.indexWhere(
      (c) => c.id == widget.channel.id,
    );
    if (_currentChannelIndex < 0) _currentChannelIndex = 0;

    _initializePlayer();
    _startOverlayTimer();

    // Refresh current program info every minute
    _programRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshCurrentProgram();
    });
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _programRefreshTimer?.cancel();
    _channelInputTimer?.cancel();
    _bufferingSubscription?.cancel();
    _errorSubscription?.cancel();
    _player?.dispose();
    _isBuffering.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      final settingsService = await SettingsService.getInstance();
      final bufferSizeMB = settingsService.getBufferSize();
      final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
      final enableHardwareDecoding = settingsService.getEnableHardwareDecoding();

      // Create player
      _player = Player();

      // Configure player for live streaming
      await _player!.setProperty('demuxer-max-bytes', bufferSizeBytes.toString());
      await _player!.setProperty('hwdec', enableHardwareDecoding ? 'auto-safe' : 'no');
      await _player!.setProperty('cache', 'yes');
      await _player!.setProperty('cache-secs', '10');

      _bufferingSubscription = _player!.streams.buffering.listen((buffering) {
        _isBuffering.value = buffering;
      });

      _errorSubscription = _player!.streams.error.listen((error) {
        appLogger.e('Player error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playback error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      setState(() {
        _isPlayerInitialized = true;
      });

      // Start playing the current channel
      await _playChannel(_currentChannel);
    } catch (e) {
      appLogger.e('Failed to initialize player', error: e);
    }
  }

  Future<void> _playChannel(LiveTVChannel channel) async {
    if (_player == null) return;

    _isBuffering.value = true;

    try {
      final client = context.read<PlexClientProvider>().client;
      if (client == null) return;

      final streamUrl = client.getLiveTVStreamUrl(channel);
      appLogger.d('Playing Live TV: ${channel.name} - $streamUrl');

      await _player!.open(Media(streamUrl));
      await _player!.play();

      setState(() {
        _currentChannel = channel;
      });

      // Show overlay when changing channels
      _showOverlayTemporarily();
    } catch (e) {
      appLogger.e('Failed to play channel', error: e);
    }
  }

  void _channelUp() {
    if (widget.channels.isEmpty) return;
    _currentChannelIndex = (_currentChannelIndex - 1 + widget.channels.length) %
        widget.channels.length;
    _playChannel(widget.channels[_currentChannelIndex]);
  }

  void _channelDown() {
    if (widget.channels.isEmpty) return;
    _currentChannelIndex = (_currentChannelIndex + 1) % widget.channels.length;
    _playChannel(widget.channels[_currentChannelIndex]);
  }

  void _onNumberPressed(int number) {
    _channelNumberInput += number.toString();
    _channelInputTimer?.cancel();

    // Auto-select after 2 seconds of no input
    _channelInputTimer = Timer(const Duration(seconds: 2), () {
      _selectChannelByNumber();
    });

    setState(() {});
  }

  void _selectChannelByNumber() {
    if (_channelNumberInput.isEmpty) return;

    final number = int.tryParse(_channelNumberInput);
    if (number != null) {
      // Find channel with this number
      final channelIndex = widget.channels.indexWhere(
        (c) => c.number == number,
      );
      if (channelIndex >= 0) {
        _currentChannelIndex = channelIndex;
        _playChannel(widget.channels[channelIndex]);
      }
    }

    _channelNumberInput = '';
    setState(() {});
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showOverlay = false;
        });
      }
    });
  }

  void _showOverlayTemporarily() {
    setState(() {
      _showOverlay = true;
    });
    _startOverlayTimer();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
    if (_showOverlay) {
      _startOverlayTimer();
    }
  }

  Future<void> _refreshCurrentProgram() async {
    try {
      final client = context.read<PlexClientProvider>().client;
      if (client == null) return;

      final channels = await client.getLiveTVWhatsOnNow();
      final updated = channels.firstWhere(
        (c) => c.id == _currentChannel.id,
        orElse: () => _currentChannel,
      );

      if (mounted) {
        setState(() {
          _currentChannel = updated;
        });
      }
    } catch (e) {
      appLogger.d('Failed to refresh program info', error: e);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Number keys for channel input
    if (key.keyId >= LogicalKeyboardKey.digit0.keyId &&
        key.keyId <= LogicalKeyboardKey.digit9.keyId) {
      final number = key.keyId - LogicalKeyboardKey.digit0.keyId;
      _onNumberPressed(number);
      return KeyEventResult.handled;
    }

    // Numpad keys
    if (key.keyId >= LogicalKeyboardKey.numpad0.keyId &&
        key.keyId <= LogicalKeyboardKey.numpad9.keyId) {
      final number = key.keyId - LogicalKeyboardKey.numpad0.keyId;
      _onNumberPressed(number);
      return KeyEventResult.handled;
    }

    // Channel up/down
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.pageUp) {
      _channelUp();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.pageDown) {
      _channelDown();
      return KeyEventResult.handled;
    }

    // Toggle overlay
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select) {
      _toggleOverlay();
      return KeyEventResult.handled;
    }

    // Exit
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: _toggleOverlay,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -200) {
                _channelDown();
              } else if (details.primaryVelocity! > 200) {
                _channelUp();
              }
            }
          },
          child: Stack(
            children: [
              // Video player
              if (_isPlayerInitialized && _player != null)
                Center(
                  child: Video(
                    player: _player!,
                    fit: BoxFit.contain,
                  ),
                ),

              // Buffering indicator
              ValueListenableBuilder<bool>(
                valueListenable: _isBuffering,
                builder: (context, isBuffering, child) {
                  if (isBuffering) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Channel info overlay
              if (_showOverlay) _buildOverlay(),

              // Channel number input display
              if (_channelNumberInput.isNotEmpty)
                Positioned(
                  top: 40,
                  right: 40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _channelNumberInput,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
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

  Widget _buildOverlay() {
    final theme = Theme.of(context);
    final now = _currentChannel.nowPlaying;
    final next = _currentChannel.nextProgram;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(230),
              Colors.black.withAlpha(150),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Channel info row
              Row(
                children: [
                  // Channel logo/number
                  if (_currentChannel.logo != null &&
                      _currentChannel.logo!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _currentChannel.logo!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildChannelNumber();
                        },
                      ),
                    )
                  else
                    _buildChannelNumber(),
                  const SizedBox(width: 16),
                  // Channel name and program info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_currentChannel.number != null)
                              Text(
                                '${_currentChannel.number}  ',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                _currentChannel.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (now != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            now.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_formatTime(now.start)} - ${_formatTime(now.end)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: now.progress,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ],
                        if (next != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Next: ${next.title} (${_formatTime(next.start)})',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Navigation hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHintButton(Icons.keyboard_arrow_up, 'Channel Up'),
                  const SizedBox(width: 24),
                  _buildHintButton(Icons.keyboard_arrow_down, 'Channel Down'),
                  const SizedBox(width: 24),
                  _buildHintButton(Icons.dialpad, 'Enter Number'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelNumber() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          _currentChannel.number?.toString() ?? '#',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildHintButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time.toLocal());
  }
}
