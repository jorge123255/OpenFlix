import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/dvr.dart';
import '../mpv/mpv.dart';
import '../providers/media_client_provider.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';

/// DVR recording player with commercial skip support
class DVRPlayerScreen extends StatefulWidget {
  final DVRRecording recording;

  const DVRPlayerScreen({
    super.key,
    required this.recording,
  });

  @override
  State<DVRPlayerScreen> createState() => _DVRPlayerScreenState();
}

class _DVRPlayerScreenState extends State<DVRPlayerScreen> {
  Player? _player;
  bool _isPlayerInitialized = false;
  bool _showControls = true;
  Timer? _controlsTimer;

  // Playback state
  final ValueNotifier<Duration> _position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> _duration = ValueNotifier(Duration.zero);
  final ValueNotifier<bool> _isBuffering = ValueNotifier(true);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);

  // Commercial skip state
  CommercialSegmentsResponse? _commercials;
  bool _autoSkipCommercials = true;
  CommercialSegment? _currentCommercial;
  bool _showSkipButton = false;

  // Subscriptions
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _loadCommercialSegments();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _bufferingSubscription?.cancel();
    _errorSubscription?.cancel();
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _player?.dispose();
    _position.dispose();
    _duration.dispose();
    _isBuffering.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      final settingsService = await SettingsService.getInstance();
      final bufferSizeMB = settingsService.getBufferSize();
      final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
      final enableHardwareDecoding = settingsService.getEnableHardwareDecoding();

      _player = Player();

      await _player!.setProperty('demuxer-max-bytes', bufferSizeBytes.toString());
      await _player!.setProperty('hwdec', enableHardwareDecoding ? 'auto-safe' : 'no');

      _bufferingSubscription = _player!.streams.buffering.listen((buffering) {
        _isBuffering.value = buffering;
      });

      _playingSubscription = _player!.streams.playing.listen((playing) {
        _isPlaying.value = playing;
      });

      _positionSubscription = _player!.streams.position.listen((pos) {
        _position.value = pos;
        _checkCommercialPosition(pos.inMilliseconds / 1000.0);
      });

      _durationSubscription = _player!.streams.duration.listen((dur) {
        _duration.value = dur;
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

      // Get the stream URL for the recording
      final client = context.read<MediaClientProvider>().client;
      if (client != null && widget.recording.filePath != null) {
        // Construct the streaming URL for the recording file
        final base = '${client.config.baseUrl}/dvr/stream/${widget.recording.id}';
        final separator = base.contains('?') ? '&' : '?';
        final streamUrl = '${base}${separator}X-Plex-Token=${client.config.token}';
        appLogger.d('Playing DVR recording: ${widget.recording.title} - $streamUrl');

        final headers = <String, String>{
          'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20',
          ...client.config.headers,
        };
        await _player!.open(Media(streamUrl, headers: headers));
        await _player!.play();
      }
    } catch (e) {
      appLogger.e('Failed to initialize player', error: e);
    }
  }

  Future<void> _loadCommercialSegments() async {
    try {
      final client = context.read<MediaClientProvider>().client;
      if (client == null) return;

      final commercials = await client.getCommercialSegments(widget.recording.id);
      if (mounted && commercials != null) {
        setState(() {
          _commercials = commercials;
        });

        if (commercials.segments.isNotEmpty) {
          appLogger.d('Loaded ${commercials.segments.length} commercial segments '
              '(${commercials.commercialTimeText} total)');
        }
      }
    } catch (e) {
      appLogger.d('Failed to load commercial segments', error: e);
    }
  }

  void _checkCommercialPosition(double positionSeconds) {
    if (_commercials == null) return;

    final commercial = _commercials!.getCommercialAtPosition(positionSeconds);

    if (commercial != null && _currentCommercial?.id != commercial.id) {
      _currentCommercial = commercial;

      if (_autoSkipCommercials) {
        // Auto-skip to end of commercial
        _skipToPosition(commercial.endTime);
      } else {
        // Show skip button
        setState(() {
          _showSkipButton = true;
        });
      }
    } else if (commercial == null && _currentCommercial != null) {
      _currentCommercial = null;
      setState(() {
        _showSkipButton = false;
      });
    }
  }

  void _skipToPosition(double seconds) {
    if (_player == null) return;
    _player!.seek(Duration(milliseconds: (seconds * 1000).round()));
    setState(() {
      _showSkipButton = false;
    });
  }

  void _skipCommercial() {
    if (_currentCommercial != null) {
      _skipToPosition(_currentCommercial!.endTime);
    }
  }

  void _togglePlayPause() {
    if (_player == null) return;
    if (_isPlaying.value) {
      _player!.pause();
    } else {
      _player!.play();
    }
  }

  void _seekRelative(int seconds) {
    if (_player == null) return;
    final newPos = _position.value + Duration(seconds: seconds);
    if (newPos.isNegative) {
      _player!.seek(Duration.zero);
    } else if (newPos > _duration.value) {
      _player!.seek(_duration.value);
    } else {
      _player!.seek(newPos);
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isPlaying.value) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startControlsTimer();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Play/Pause
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlayPause();
      _showControlsTemporarily();
      return KeyEventResult.handled;
    }

    // Seek
    if (key == LogicalKeyboardKey.arrowLeft) {
      _seekRelative(-10);
      _showControlsTemporarily();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      _seekRelative(10);
      _showControlsTemporarily();
      return KeyEventResult.handled;
    }

    // Skip commercial
    if (key == LogicalKeyboardKey.keyS && _showSkipButton) {
      _skipCommercial();
      return KeyEventResult.handled;
    }

    // Toggle auto-skip
    if (key == LogicalKeyboardKey.keyA) {
      setState(() {
        _autoSkipCommercials = !_autoSkipCommercials;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_autoSkipCommercials
              ? 'Auto-skip commercials enabled'
              : 'Auto-skip commercials disabled'),
          duration: const Duration(seconds: 2),
        ),
      );
      return KeyEventResult.handled;
    }

    // Toggle controls
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select) {
      _toggleControls();
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
      backgroundColor: Platform.isMacOS ? Colors.transparent : Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: _toggleControls,
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

              // Skip commercial button
              if (_showSkipButton && !_autoSkipCommercials)
                Positioned(
                  right: 24,
                  bottom: 120,
                  child: ElevatedButton.icon(
                    onPressed: _skipCommercial,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip Commercial'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

              // Commercial indicator
              if (_currentCommercial != null)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'COMMERCIAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              // Controls overlay
              if (_showControls) _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with title and back button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recording.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat.yMMMd().add_jm().format(
                            widget.recording.startTime.toLocal(),
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Auto-skip toggle
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _autoSkipCommercials = !_autoSkipCommercials;
                      });
                    },
                    icon: Icon(
                      _autoSkipCommercials ? Icons.skip_next : Icons.skip_next_outlined,
                      color: _autoSkipCommercials ? Colors.red : Colors.white54,
                    ),
                    label: Text(
                      'Auto-skip',
                      style: TextStyle(
                        color: _autoSkipCommercials ? Colors.red : Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progress bar with commercial markers
                  _buildProgressBar(),
                  const SizedBox(height: 16),

                  // Playback controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                        onPressed: () => _seekRelative(-10),
                      ),
                      const SizedBox(width: 24),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isPlaying,
                        builder: (context, isPlaying, child) {
                          return IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                            onPressed: _togglePlayPause,
                          );
                        },
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                        onPressed: () => _seekRelative(10),
                      ),
                    ],
                  ),

                  // Commercial info
                  if (_commercials != null && _commercials!.segments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_commercials!.totalCommercials} commercials detected (${_commercials!.commercialTimeText})',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ValueListenableBuilder<Duration>(
      valueListenable: _duration,
      builder: (context, duration, child) {
        return ValueListenableBuilder<Duration>(
          valueListenable: _position,
          builder: (context, position, child) {
            final totalSeconds = duration.inSeconds.toDouble();
            final currentSeconds = position.inSeconds.toDouble();
            final progress = totalSeconds > 0 ? currentSeconds / totalSeconds : 0.0;

            return Column(
              children: [
                // Progress bar with commercial markers
                SizedBox(
                  height: 24,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // Background
                          Positioned.fill(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Commercial markers
                          if (_commercials != null && totalSeconds > 0)
                            ..._commercials!.segments.map((segment) {
                              final startFraction = segment.startTime / totalSeconds;
                              final widthFraction = segment.duration / totalSeconds;
                              return Positioned(
                                left: constraints.maxWidth * startFraction,
                                width: constraints.maxWidth * widthFraction,
                                top: 8,
                                bottom: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),

                          // Progress
                          Positioned(
                            left: 0,
                            top: 10,
                            bottom: 10,
                            width: constraints.maxWidth * progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Seek gesture
                          Positioned.fill(
                            child: GestureDetector(
                              onTapDown: (details) {
                                if (_player != null && totalSeconds > 0) {
                                  final fraction = details.localPosition.dx / constraints.maxWidth;
                                  final seekSeconds = fraction * totalSeconds;
                                  _player!.seek(Duration(seconds: seekSeconds.round()));
                                }
                              },
                              onHorizontalDragUpdate: (details) {
                                if (_player != null && totalSeconds > 0) {
                                  final fraction = details.localPosition.dx / constraints.maxWidth;
                                  final seekSeconds = fraction.clamp(0.0, 1.0) * totalSeconds;
                                  _player!.seek(Duration(seconds: seekSeconds.round()));
                                }
                              },
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Time labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
