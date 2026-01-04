import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import '../models/livetv_channel.dart';
import '../mpv/mpv.dart';
import '../providers/media_client_provider.dart';
import '../services/catchup_service.dart';
import '../services/channel_history_service.dart';
import '../services/tuner_sharing_service.dart';
import '../services/livetv_aspect_ratio_manager.dart';
import '../services/pip_service.dart';
import '../services/settings_service.dart';
import '../services/sleep_timer_service.dart';
import '../services/last_watched_service.dart';
import '../widgets/catchup_tv_sheet.dart';
import '../utils/app_logger.dart';
import 'dvr_screen.dart';
import 'epg_guide_screen.dart';
import '../widgets/channel_history_panel.dart';
import '../widgets/livetv_volume_overlay.dart';
import '../widgets/livetv/channel_preview_overlay.dart';
import '../widgets/livetv/livetv_player_controls.dart';
import '../widgets/livetv/mini_channel_guide_overlay.dart';
import '../widgets/livetv/program_details_sheet.dart';
import '../widgets/stats_for_nerds_overlay.dart';
import '../widgets/video_controls/sheets/audio_track_sheet.dart';
import '../widgets/video_controls/sheets/base_video_control_sheet.dart';
import '../widgets/video_controls/sheets/subtitle_track_sheet.dart';
import '../widgets/video_controls/widgets/sleep_timer_content.dart';

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

class _LiveTVPlayerScreenState extends State<LiveTVPlayerScreen> with WidgetsBindingObserver {
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

  // Channel preview overlay
  bool _showChannelPreview = false;
  LiveTVChannel? _previewChannel;
  int _previewCountdown = 2;
  Timer? _previewCountdownTimer;

  // Sleep timer service
  final SleepTimerService _sleepTimer = SleepTimerService();

  // Channel history service
  final ChannelHistoryService _channelHistory = ChannelHistoryService();

  // Channel history panel visibility
  bool _showHistoryPanel = false;

  // Volume control
  bool _showVolumeOverlay = false;
  Timer? _volumeOverlayTimer;
  double _currentVolume = 100.0;
  bool _isMuted = false;
  StreamSubscription<double>? _volumeSubscription;

  // Aspect ratio control
  LiveTVAspectRatioManager? _aspectRatioManager;
  AspectRatioMode _currentAspectMode = AspectRatioMode.auto;

  // Mini channel guide
  bool _showMiniGuide = false;

  // Quick record
  bool _isRecordingScheduled = false;
  bool _isSchedulingRecording = false;

  // Stats overlay
  bool _showStatsOverlay = false;

  // Favorites filter
  bool _favoritesFilterActive = false;

  // Catch-up TV
  bool _startOverAvailable = false;
  bool _catchUpAvailable = false;
  StartOverInfo? _startOverInfo;

  // Favorite toggle
  bool _isTogglingFavorite = false;

  // Picture-in-Picture
  final PipService _pipService = PipService();
  bool _isPipMode = false;

  // Tuner sharing
  TunerSharingService? _tunerSharingService;
  bool _isSharedStream = false;
  int _viewerCount = 1;
  String _sessionId = '';

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _currentChannelIndex = widget.channels.indexWhere(
      (c) => c.id == widget.channel.id,
    );
    if (_currentChannelIndex < 0) _currentChannelIndex = 0;

    // Generate unique session ID for tuner sharing
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${_currentChannel.id}';

    _initializePlayer();
    _startOverlayTimer();
    _initializeTunerSharing();

    // Initialize channel history
    _channelHistory.initialize();

    // Load stats overlay preference
    _loadStatsOverlayPreference();

    // Check catch-up availability
    _checkCatchUpAvailability();

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
    _previewCountdownTimer?.cancel();
    _volumeOverlayTimer?.cancel();
    _bufferingSubscription?.cancel();
    _errorSubscription?.cancel();
    _volumeSubscription?.cancel();
    _tunerSharingService?.leaveChannel();
    _tunerSharingService?.dispose();
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
      await _player!.setProperty('cache-secs', '20');
      await _player!.setProperty('demuxer-readahead-secs', '20');
      await _player!.setProperty(
        'stream-lavf-o',
        'reconnect=1,reconnect_streamed=1,reconnect_delay_max=2',
      );

      // Configure video upscaling for better quality on large screens
      final videoUpscaler = settingsService.getVideoUpscaler();
      await _player!.setProperty('scale', videoUpscaler);
      await _player!.setProperty('cscale', videoUpscaler);
      await _player!.setProperty('dscale', 'mitchell'); // Good downscaler

      // Ensure audio is enabled by default
      await _player!.setProperty('aid', 'auto');
      await _player!.setProperty('audio-channels', 'auto');

      _bufferingSubscription = _player!.streams.buffering.listen((buffering) {
        _isBuffering.value = buffering;
      });

      _errorSubscription = _player!.streams.error.listen((error) {
        appLogger.e('Player error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.liveTV.playbackError(error: error)),
              backgroundColor: Colors.red,
            ),
          );
        }
      });

      _volumeSubscription = _player!.streams.volume.listen((volume) {
        if (mounted) {
          setState(() {
            _currentVolume = volume;
          });
        }
      });

      // Load saved volume from settings
      final savedVolume = settingsService.getVolume();
      await _player!.setVolume(savedVolume);

      // Initialize aspect ratio manager
      _aspectRatioManager = LiveTVAspectRatioManager(_player!);

      setState(() {
        _isPlayerInitialized = true;
      });

      // Start playing the current channel
      await _playChannel(_currentChannel);
    } catch (e) {
      appLogger.e('Failed to initialize player', error: e);
    }
  }

  /// Initialize tuner sharing service for stream sharing
  Future<void> _initializeTunerSharing() async {
    try {
      final client = context.read<MediaClientProvider>().client;
      if (client == null) return;

      _tunerSharingService = TunerSharingService(
        baseUrl: client.config.baseUrl,
        token: client.config.headers['Authorization']?.replaceFirst('Bearer ', '') ?? '',
      );

      // Join the channel
      await _joinTunerSession();
    } catch (e) {
      appLogger.d('Tuner sharing not available: $e');
    }
  }

  /// Join tuner session for current channel
  Future<void> _joinTunerSession() async {
    if (_tunerSharingService == null) return;

    try {
      final result = await _tunerSharingService!.joinChannel(
        channelId: _currentChannel.id,
        sessionId: _sessionId,
        deviceName: Platform.operatingSystem,
        deviceType: Platform.isAndroid || Platform.isIOS ? 'mobile' : 'desktop',
      );

      if (result.success && mounted) {
        setState(() {
          _isSharedStream = result.isShared;
          _viewerCount = result.viewerCount;
        });

        if (result.isShared) {
          appLogger.d('Joined shared tuner session with ${result.viewerCount} viewers');
        }
      }
    } catch (e) {
      appLogger.d('Failed to join tuner session: $e');
    }
  }

  /// Leave current tuner session and join new one for channel switch
  Future<void> _switchTunerSession(LiveTVChannel newChannel) async {
    if (_tunerSharingService == null) return;

    try {
      await _tunerSharingService!.leaveChannel();

      // Update session ID for new channel
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${newChannel.id}';

      final result = await _tunerSharingService!.joinChannel(
        channelId: newChannel.id,
        sessionId: _sessionId,
        deviceName: Platform.operatingSystem,
        deviceType: Platform.isAndroid || Platform.isIOS ? 'mobile' : 'desktop',
      );

      if (result.success && mounted) {
        setState(() {
          _isSharedStream = result.isShared;
          _viewerCount = result.viewerCount;
        });
      }
    } catch (e) {
      appLogger.d('Failed to switch tuner session: $e');
    }
  }

  bool _hasHeader(Map<String, String> headers, String headerNameLower) {
    for (final key in headers.keys) {
      if (key.toLowerCase() == headerNameLower) return true;
    }
    return false;
  }

  ({String url, Map<String, String> headers}) _parseM3uPipeHeaders(
    String input,
  ) {
    final pipeIndex = input.indexOf('|');
    if (pipeIndex < 0) {
      return (url: input, headers: <String, String>{});
    }

    final url = input.substring(0, pipeIndex);
    final headerPart = input.substring(pipeIndex + 1);
    final headers = <String, String>{};

    for (final segment in headerPart.split('&')) {
      if (segment.trim().isEmpty) continue;
      final eqIndex = segment.indexOf('=');
      if (eqIndex <= 0) continue;
      final rawKey = segment.substring(0, eqIndex);
      final rawValue = segment.substring(eqIndex + 1);
      final key = Uri.decodeComponent(rawKey).trim();
      final value = Uri.decodeComponent(rawValue).trim();
      if (key.isEmpty || value.isEmpty) continue;
      headers[key] = value;
    }

    return (url: url, headers: headers);
  }

  Future<void> _playChannel(LiveTVChannel channel) async {
    if (_player == null) return;

    _isBuffering.value = true;

    try {
      final client = context.read<MediaClientProvider>().client;
      if (client == null) return;

      final streamUrl = client.getLiveTVStreamUrl(channel);
      appLogger.d('Playing Live TV: ${channel.name} - $streamUrl');

      final parsed = _parseM3uPipeHeaders(streamUrl);

      // Many IPTV providers require a specific User-Agent (VLC works by default).
      // Also include auth headers only for server-hosted URLs.
      final headers = <String, String>{
        ...parsed.headers,
      };
      if (!_hasHeader(headers, 'user-agent')) {
        headers['User-Agent'] = 'VLC/3.0.20 LibVLC/3.0.20';
      }
      if (parsed.url.startsWith(client.config.baseUrl)) {
        headers.addAll(client.config.headers);
      }

      await _player!.open(Media(parsed.url, headers: headers));

      // Explicitly enable audio track (fixes issue where audio doesn't play)
      await _player!.setProperty('aid', 'auto');

      await _player!.play();

      setState(() {
        _currentChannel = channel;
      });

      // Switch tuner session for the new channel
      await _switchTunerSession(channel);

      // Add to channel history
      _channelHistory.addChannel(channel.id);

      // Save as last watched channel for docked player
      _saveLastWatchedChannel(channel);

      // Show overlay when changing channels
      _showOverlayTemporarily();
    } catch (e) {
      appLogger.e('Failed to play channel', error: e);
    }
  }

  void _channelUp() {
    if (widget.channels.isEmpty) return;

    if (_favoritesFilterActive) {
      // Find previous favorite channel
      final nextIndex = _findPreviousFavoriteChannel(_currentChannelIndex);
      if (nextIndex != -1) {
        _currentChannelIndex = nextIndex;
        _playChannel(widget.channels[_currentChannelIndex]);
      }
    } else {
      _currentChannelIndex = (_currentChannelIndex - 1 + widget.channels.length) %
          widget.channels.length;
      _playChannel(widget.channels[_currentChannelIndex]);
    }
  }

  void _channelDown() {
    if (widget.channels.isEmpty) return;

    if (_favoritesFilterActive) {
      // Find next favorite channel
      final nextIndex = _findNextFavoriteChannel(_currentChannelIndex);
      if (nextIndex != -1) {
        _currentChannelIndex = nextIndex;
        _playChannel(widget.channels[_currentChannelIndex]);
      }
    } else {
      _currentChannelIndex = (_currentChannelIndex + 1) % widget.channels.length;
      _playChannel(widget.channels[_currentChannelIndex]);
    }
  }

  int _findNextFavoriteChannel(int currentIndex) {
    final count = widget.channels.length;
    for (int i = 1; i < count; i++) {
      final index = (currentIndex + i) % count;
      if (widget.channels[index].isFavorite) {
        return index;
      }
    }
    return -1; // No favorite channels found
  }

  int _findPreviousFavoriteChannel(int currentIndex) {
    final count = widget.channels.length;
    for (int i = 1; i < count; i++) {
      final index = (currentIndex - i + count) % count;
      if (widget.channels[index].isFavorite) {
        return index;
      }
    }
    return -1; // No favorite channels found
  }

  void _onNumberPressed(int number) {
    _channelNumberInput += number.toString();
    _channelInputTimer?.cancel();
    _previewCountdownTimer?.cancel();

    // Try to find channel with the current input
    final inputNumber = int.tryParse(_channelNumberInput);
    if (inputNumber != null) {
      final channelIndex = widget.channels.indexWhere(
        (c) => c.number == inputNumber,
      );

      if (channelIndex >= 0) {
        // Found a matching channel - show preview and start countdown
        setState(() {
          _previewChannel = widget.channels[channelIndex];
          _showChannelPreview = true;
          _previewCountdown = 2;
        });

        // Start countdown timer
        _startPreviewCountdown();
      } else {
        // No matching channel yet - hide preview
        setState(() {
          _showChannelPreview = false;
          _previewChannel = null;
        });
      }
    }
  }

  void _startPreviewCountdown() {
    _previewCountdownTimer?.cancel();
    _previewCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_previewCountdown > 0) {
        setState(() {
          _previewCountdown--;
        });
      } else {
        timer.cancel();
        _selectChannelByNumber();
      }
    });
  }

  void _tuneToPreviewChannel() {
    _previewCountdownTimer?.cancel();
    _selectChannelByNumber();
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
    _previewCountdownTimer?.cancel();
    setState(() {
      _showChannelPreview = false;
      _previewChannel = null;
    });
  }

  void _switchToPreviousChannel() {
    final previousChannelId = _channelHistory.getPreviousChannel(_currentChannel.id);
    if (previousChannelId == null) {
      // No previous channel available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.liveTV.noPreviousChannel),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    // Find the channel by ID
    final channelIndex = widget.channels.indexWhere(
      (c) => c.id == previousChannelId,
    );

    if (channelIndex >= 0) {
      _currentChannelIndex = channelIndex;
      final previousChannel = widget.channels[channelIndex];
      _playChannel(previousChannel);

      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.liveTV.switchedTo(channel: previousChannel.name)),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    }
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

  /// Save the last watched channel for the docked player feature
  Future<void> _saveLastWatchedChannel(LiveTVChannel channel) async {
    try {
      final lastWatchedService = await LastWatchedService.getInstance();
      await lastWatchedService.setLastWatchedChannel(channel);
    } catch (e) {
      appLogger.e('Failed to save last watched channel', error: e);
    }
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
      final client = context.read<MediaClientProvider>().client;
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

    // Enter key - tune to preview channel if showing, otherwise toggle overlay
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.select) {
      if (_showChannelPreview) {
        _tuneToPreviewChannel();
      } else {
        _toggleOverlay();
      }
      return KeyEventResult.handled;
    }

    // Toggle overlay (space only)
    if (key == LogicalKeyboardKey.space) {
      _toggleOverlay();
      return KeyEventResult.handled;
    }

    // Volume control
    if (key == LogicalKeyboardKey.arrowUp && !_showOverlay) {
      _adjustVolume(5);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown && !_showOverlay) {
      _adjustVolume(-5);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add) {
      _adjustVolume(5);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus) {
      _adjustVolume(-5);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyM) {
      _toggleMute();
      return KeyEventResult.handled;
    }

    // Audio track selection
    if (key == LogicalKeyboardKey.keyA) {
      _showAudioTrackSheet();
      return KeyEventResult.handled;
    }

    // Subtitle selection
    if (key == LogicalKeyboardKey.keyS) {
      _showSubtitleTrackSheet();
      return KeyEventResult.handled;
    }

    // Aspect ratio
    if (key == LogicalKeyboardKey.keyZ) {
      _cycleAspectRatio();
      return KeyEventResult.handled;
    }

    // Stats overlay (Shift+I) - check before regular I
    if (key == LogicalKeyboardKey.keyI && HardwareKeyboard.instance.isShiftPressed) {
      _toggleStatsOverlay();
      return KeyEventResult.handled;
    }

    // Program details
    if (key == LogicalKeyboardKey.keyI) {
      _showProgramDetails();
      return KeyEventResult.handled;
    }

    // Quick record
    if (key == LogicalKeyboardKey.keyR) {
      _quickRecord();
      return KeyEventResult.handled;
    }

    // Sleep timer
    if (key == LogicalKeyboardKey.keyT) {
      _showSleepTimer();
      return KeyEventResult.handled;
    }

    // Mini channel guide
    if (key == LogicalKeyboardKey.keyG) {
      _toggleMiniGuide();
      return KeyEventResult.handled;
    }

    // Channel history
    if (key == LogicalKeyboardKey.keyH) {
      _toggleHistoryPanel();
      return KeyEventResult.handled;
    }

    // Favorites filter
    if (key == LogicalKeyboardKey.keyF) {
      _toggleFavoritesFilter();
      return KeyEventResult.handled;
    }

    // Picture-in-Picture
    if (key == LogicalKeyboardKey.keyP) {
      _togglePip();
      return KeyEventResult.handled;
    }

    // Previous channel
    if (key == LogicalKeyboardKey.backspace) {
      _switchToPreviousChannel();
      return KeyEventResult.handled;
    }

    // Android TV: D-pad left/right when overlay is visible
    if (_showOverlay && key == LogicalKeyboardKey.arrowLeft) {
      _switchToPreviousChannel();
      return KeyEventResult.handled;
    }

    if (_showOverlay && key == LogicalKeyboardKey.arrowRight) {
      _showProgramDetails();
      return KeyEventResult.handled;
    }

    // Android TV: Menu button = Mini guide
    if (key == LogicalKeyboardKey.contextMenu) {
      _toggleMiniGuide();
      return KeyEventResult.handled;
    }

    // Android TV: Media buttons
    if (key == LogicalKeyboardKey.mediaPlayPause) {
      _toggleOverlay();
      return KeyEventResult.handled;
    }

    // Exit
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack) {
      // Close overlays if open, otherwise exit
      if (_showMiniGuide) {
        _toggleMiniGuide();
        return KeyEventResult.handled;
      }
      if (_showHistoryPanel) {
        _toggleHistoryPanel();
        return KeyEventResult.handled;
      }
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _toggleHistoryPanel() {
    setState(() {
      _showHistoryPanel = !_showHistoryPanel;
    });
  }

  void _toggleMiniGuide() {
    setState(() {
      _showMiniGuide = !_showMiniGuide;
    });
  }

  Future<void> _loadStatsOverlayPreference() async {
    final settingsService = await SettingsService.getInstance();
    setState(() {
      _showStatsOverlay = settingsService.getStatsOverlayEnabled();
    });
  }

  Future<void> _toggleStatsOverlay() async {
    final settingsService = await SettingsService.getInstance();
    setState(() {
      _showStatsOverlay = !_showStatsOverlay;
    });
    await settingsService.setStatsOverlayEnabled(_showStatsOverlay);
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _favoritesFilterActive = !_favoritesFilterActive;
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _favoritesFilterActive
              ? 'Showing favorites only'
              : 'Showing all channels',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Check if catch-up features are available for the current channel
  Future<void> _checkCatchUpAvailability() async {
    try {
      final catchUpService = CatchUpService.instance;
      final channelId = _currentChannel.id;

      // Check start-over availability
      final startOverInfo = await catchUpService.getStartOverInfo(channelId);

      if (mounted) {
        setState(() {
          _startOverInfo = startOverInfo;
          _startOverAvailable = startOverInfo?.available ?? false;
          // Catch-up is available if server supports it
          _catchUpAvailable = true; // Assume available, will fail gracefully if not
        });
      }
    } catch (e) {
      appLogger.d('Catch-up not available: $e');
      if (mounted) {
        setState(() {
          _startOverAvailable = false;
          _catchUpAvailable = false;
        });
      }
    }
  }

  /// Handle Start Over - restart current program from beginning
  Future<void> _handleStartOver() async {
    if (_startOverInfo == null || !_startOverAvailable) return;

    try {
      final catchUpService = CatchUpService.instance;
      final channelId = _currentChannel.id;

      // Get the time-shift URL
      final offsetSeconds = _startOverInfo!.offsetSeconds ?? 0;
      final timeshiftUrl = await catchUpService.getTimeShiftUrl(channelId, offsetSeconds);

      if (timeshiftUrl != null && _player != null) {
        // Switch to the time-shifted stream
        await _player!.open(Media(timeshiftUrl));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.liveTV.startingFromBeginning),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      appLogger.e('Failed to start over: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.liveTV.failedToStartOver(error: e.toString())),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Show catch-up TV sheet with available programs
  Future<void> _showCatchUpSheet() async {
    final channelId = _currentChannel.id;

    final selectedProgram = await showCatchUpTVSheet(
      context,
      channelId: channelId,
      channelName: _currentChannel.name,
    );

    if (selectedProgram != null && mounted) {
      try {
        final catchUpService = CatchUpService.instance;

        // Calculate offset from program start to now
        final offsetSeconds = DateTime.now().difference(selectedProgram.startTime).inSeconds;
        final timeshiftUrl = await catchUpService.getTimeShiftUrl(channelId, offsetSeconds);

        if (timeshiftUrl != null && _player != null) {
          await _player!.open(Media(timeshiftUrl));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.liveTV.playingProgram(title: selectedProgram.title)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        appLogger.e('Failed to play catch-up program: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.liveTV.failedToPlayProgram(error: e.toString())),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      final client = context.read<MediaClientProvider>().client;
      if (client == null) return;

      final updatedChannel = await client.toggleChannelFavorite(
        _currentChannel.id,
      );

      if (updatedChannel != null && mounted) {
        setState(() {
          _currentChannel = updatedChannel;
          // Update in the channels list too
          final index = widget.channels.indexWhere(
            (c) => c.id == _currentChannel.id,
          );
          if (index >= 0) {
            widget.channels[index] = updatedChannel;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedChannel.isFavorite
                  ? t.liveTV.addedToFavorites
                  : t.liveTV.removedFromFavorites,
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      appLogger.e('Failed to toggle favorite', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.liveTV.failedToUpdateFavorite(error: e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  void _showEPG() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EPGGuideScreen(),
      ),
    );
  }

  void _switchToChannel(LiveTVChannel channel) {
    final channelIndex = widget.channels.indexWhere((c) => c.id == channel.id);
    if (channelIndex >= 0) {
      _currentChannelIndex = channelIndex;
      _playChannel(channel);
      // Check catch-up availability for new channel
      _checkCatchUpAvailability();
    }
  }

  Future<void> _togglePip() async {
    if (!_pipService.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.liveTV.pipNotSupported),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final success = await _pipService.togglePip();
    if (success && mounted) {
      setState(() {
        _isPipMode = _pipService.isPipMode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPipMode
                ? t.liveTV.enteredPipMode
                : t.liveTV.exitedPipMode,
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _adjustVolume(double delta) async {
    if (_player == null) return;

    final newVolume = (_currentVolume + delta).clamp(0.0, 100.0);
    await _player!.setVolume(newVolume);

    // If adjusting volume while muted, unmute
    if (_isMuted && delta != 0) {
      await _toggleMute();
    }

    // Save volume to settings
    final settingsService = await SettingsService.getInstance();
    await settingsService.setVolume(newVolume);

    // Show volume overlay
    _showVolumeOverlayTemporarily();
  }

  Future<void> _toggleMute() async {
    if (_player == null) return;

    final newMuteState = !_isMuted;
    await _player!.setProperty('mute', newMuteState ? 'yes' : 'no');

    setState(() {
      _isMuted = newMuteState;
    });

    // Show volume overlay
    _showVolumeOverlayTemporarily();
  }

  void _showVolumeOverlayTemporarily() {
    setState(() {
      _showVolumeOverlay = true;
    });

    _volumeOverlayTimer?.cancel();
    _volumeOverlayTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showVolumeOverlay = false;
        });
      }
    });
  }

  Future<void> _cycleAspectRatio() async {
    if (_aspectRatioManager == null) return;

    final newMode = await _aspectRatioManager!.cycleMode();
    setState(() {
      _currentAspectMode = newMode;
    });

    // Show toast notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.liveTV.aspectRatioChanged(mode: newMode.displayName)),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _showAudioTrackSheet() {
    if (_player == null) return;

    AudioTrackSheet.show(
      context,
      _player!,
      onOpen: () {
        // Pause overlay auto-hide while sheet is open
        _overlayTimer?.cancel();
      },
      onClose: () {
        // Resume overlay auto-hide when sheet closes
        if (_showOverlay) {
          _startOverlayTimer();
        }
      },
    );
  }

  void _showSubtitleTrackSheet() {
    if (_player == null) return;

    SubtitleTrackSheet.show(
      context,
      _player!,
      onOpen: () {
        // Pause overlay auto-hide while sheet is open
        _overlayTimer?.cancel();
      },
      onClose: () {
        // Resume overlay auto-hide when sheet closes
        if (_showOverlay) {
          _startOverlayTimer();
        }
      },
    );
  }

  void _showProgramDetails() {
    ProgramDetailsSheet.show(
      context,
      channel: _currentChannel,
      onRecord: () {
        Navigator.of(context).pop(); // Close details sheet
        _scheduleRecording();
      },
      onOpen: () {
        // Pause overlay auto-hide while sheet is open
        _overlayTimer?.cancel();
      },
      onClose: () {
        // Resume overlay auto-hide when sheet closes
        if (_showOverlay) {
          _startOverlayTimer();
        }
      },
    );
  }

  Future<void> _quickRecord() async {
    setState(() => _isSchedulingRecording = true);

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => ScheduleRecordingDialog(
          channel: _currentChannel,
          program: _currentChannel.nowPlaying,
        ),
      );

      if (mounted) {
        setState(() {
          _isSchedulingRecording = false;
          _isRecordingScheduled = result == true;
        });

        if (result == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.dvr.recordingScheduled),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSchedulingRecording = false);
      }
    }
  }

  Future<void> _scheduleRecording() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ScheduleRecordingDialog(
        channel: _currentChannel,
        program: _currentChannel.nowPlaying,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.dvr.recordingScheduled),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSleepTimer() {
    BaseVideoControlSheet.showSheet(
      context: context,
      builder: (context) => BaseVideoControlSheet(
        title: 'Sleep Timer',
        icon: Icons.bedtime,
        child: SleepTimerContent(
          player: _player!,
          sleepTimer: _sleepTimer,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
      onOpen: () {
        // Pause overlay auto-hide while sheet is open
        _overlayTimer?.cancel();
      },
      onClose: () {
        // Resume overlay auto-hide when sheet closes
        if (_showOverlay) {
          _startOverlayTimer();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On Android, the video is rendered on a native SurfaceView behind Flutter.
      // We need the background to be transparent so the video shows through.
      // On macOS, we also need transparency for the Metal layer.
      // On other platforms (Windows, Linux), video is rendered via native windows.
      backgroundColor: (Platform.isAndroid || Platform.isMacOS) ? Colors.transparent : Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          onTap: _toggleOverlay,
          onLongPress: _showProgramDetails,
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              // Swipe up to open mini guide
              if (details.primaryVelocity! < -500 && !_showMiniGuide) {
                _toggleMiniGuide();
              }
              // Swipe down for channel navigation (when guide not showing)
              else if (details.primaryVelocity! > 200 && !_showMiniGuide) {
                _channelUp();
              }
              // Swipe up for channel navigation (when guide not showing)
              else if (details.primaryVelocity! < -200 && !_showMiniGuide) {
                _channelDown();
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

              // Tuner sharing indicator
              if (_isSharedStream && _viewerCount > 1)
                Positioned(
                  top: 16,
                  left: 16,
                  child: AnimatedOpacity(
                    opacity: _showOverlay ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_viewerCount watching',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Channel info overlay
              if (_showOverlay)
                LiveTVPlayerControls(
                  channel: _currentChannel,
                  allChannels: widget.channels,
                  sleepTimer: _sleepTimer,
                  isRecordingScheduled: _isRecordingScheduled,
                  isSchedulingRecording: _isSchedulingRecording,
                  currentAspectMode: _currentAspectMode,
                  pipService: _pipService,
                  isPipMode: _isPipMode,
                  onShowProgramDetails: _showProgramDetails,
                  onQuickRecord: _quickRecord,
                  onShowAudioTrackSheet: _showAudioTrackSheet,
                  onShowSubtitleTrackSheet: _showSubtitleTrackSheet,
                  onCycleAspectRatio: _cycleAspectRatio,
                  onSwitchToPreviousChannel: _switchToPreviousChannel,
                  onToggleHistoryPanel: _toggleHistoryPanel,
                  onShowSleepTimer: _showSleepTimer,
                  onTogglePip: _togglePip,
                  onToggleFavorite: _toggleFavorite,
                  isTogglingFavorite: _isTogglingFavorite,
                  onShowEPG: _showEPG,
                  onSwitchToChannel: _switchToChannel,
                  startOverAvailable: _startOverAvailable,
                  catchUpAvailable: _catchUpAvailable,
                  onStartOver: _startOverAvailable ? _handleStartOver : null,
                  onShowCatchUp: _catchUpAvailable ? _showCatchUpSheet : null,
                ),

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

              // Volume overlay
              if (_showVolumeOverlay)
                LiveTVVolumeOverlay(
                  volume: _currentVolume,
                  isMuted: _isMuted,
                ),

              // Channel history panel
              if (_showHistoryPanel)
                ChannelHistoryPanel(
                  channels: widget.channels,
                  channelHistory: _channelHistory,
                  onChannelSelected: (channel) {
                    final channelIndex = widget.channels.indexWhere(
                      (c) => c.id == channel.id,
                    );
                    if (channelIndex >= 0) {
                      _currentChannelIndex = channelIndex;
                      _playChannel(channel);
                    }
                  },
                  onClose: _toggleHistoryPanel,
                ),

              // Mini channel guide
              if (_showMiniGuide)
                MiniChannelGuideOverlay(
                  channels: widget.channels,
                  currentChannel: _currentChannel,
                  favoritesFilterActive: _favoritesFilterActive,
                  onChannelSelected: (channel) {
                    final channelIndex = widget.channels.indexWhere(
                      (c) => c.id == channel.id,
                    );
                    if (channelIndex >= 0) {
                      _currentChannelIndex = channelIndex;
                      _playChannel(channel);
                    }
                  },
                  onClose: _toggleMiniGuide,
                  onToggleFavoritesFilter: _toggleFavoritesFilter,
                ),
              // Stats for nerds overlay
              if (_showStatsOverlay && _player != null)
                StatsForNerdsOverlay(
                  player: _player!,
                  streamUrl: _currentChannel.streamUrl,
                ),
              // Channel preview overlay
              if (_showChannelPreview && _previewChannel != null)
                ChannelPreviewOverlay(
                  channel: _previewChannel!,
                  countdown: _previewCountdown,
                  onTuneNow: _tuneToPreviewChannel,
                ),
            ],
          ),
        ),
      ),
    );
  }

}
