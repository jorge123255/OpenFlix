import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../models/livetv_channel.dart';
import '../mpv/mpv.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';

/// Multi-view Live TV screen showing 2-4 channels simultaneously
/// TiviMate-style split screen view
class LiveTVMultiviewScreen extends StatefulWidget {
  final List<LiveTVChannel> initialChannels;
  final List<LiveTVChannel> allChannels;

  const LiveTVMultiviewScreen({
    super.key,
    required this.initialChannels,
    required this.allChannels,
  });

  @override
  State<LiveTVMultiviewScreen> createState() => _LiveTVMultiviewScreenState();
}

class _LiveTVMultiviewScreenState extends State<LiveTVMultiviewScreen> {
  final List<_MultiviewSlot> _slots = [];
  int _focusedSlotIndex = 0;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  MultiviewLayout _layout = MultiviewLayout.twoByOne;

  @override
  void initState() {
    super.initState();
    _initializeSlots();
    _startHideControlsTimer();

    // Force landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    for (final slot in _slots) {
      slot.dispose();
    }
    // Restore orientation
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _initializeSlots() {
    // Initialize slots based on initial channels (up to 4)
    final channelCount = widget.initialChannels.length.clamp(1, 4);
    for (int i = 0; i < channelCount; i++) {
      _slots.add(_MultiviewSlot(
        channel: widget.initialChannels[i],
        onReady: () => setState(() {}),
      ));
    }

    // Determine initial layout based on channel count
    switch (channelCount) {
      case 1:
        _layout = MultiviewLayout.single;
        break;
      case 2:
        _layout = MultiviewLayout.twoByOne;
        break;
      case 3:
        _layout = MultiviewLayout.threeGrid;
        break;
      case 4:
        _layout = MultiviewLayout.twoByTwo;
        break;
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsAndResetTimer() {
    setState(() {
      _showControls = true;
    });
    _startHideControlsTimer();
  }

  void _handleTap() {
    _showControlsAndResetTimer();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    _showControlsAndResetTimer();

    final key = event.logicalKey;

    // Arrow keys to navigate between slots
    if (key == LogicalKeyboardKey.arrowLeft) {
      setState(() {
        _focusedSlotIndex = (_focusedSlotIndex - 1).clamp(0, _slots.length - 1);
      });
    } else if (key == LogicalKeyboardKey.arrowRight) {
      setState(() {
        _focusedSlotIndex = (_focusedSlotIndex + 1).clamp(0, _slots.length - 1);
      });
    } else if (key == LogicalKeyboardKey.arrowUp) {
      // Change channel in focused slot
      _changeChannelInSlot(_focusedSlotIndex, -1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _changeChannelInSlot(_focusedSlotIndex, 1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select) {
      // Make focused slot full screen
      _makeSlotFullScreen(_focusedSlotIndex);
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      Navigator.of(context).pop();
    } else if (key == LogicalKeyboardKey.keyL) {
      // Cycle layout
      _cycleLayout();
    } else if (key == LogicalKeyboardKey.keyA) {
      // Add a slot
      _addSlot();
    } else if (key == LogicalKeyboardKey.keyR) {
      // Remove focused slot
      _removeSlot(_focusedSlotIndex);
    } else if (key == LogicalKeyboardKey.keyM) {
      // Toggle mute on focused slot
      _slots[_focusedSlotIndex].toggleMute();
      setState(() {});
    }
  }

  void _changeChannelInSlot(int slotIndex, int direction) {
    if (slotIndex >= _slots.length) return;

    final currentChannel = _slots[slotIndex].channel;
    final currentIndex = widget.allChannels.indexWhere(
      (c) => c.id == currentChannel.id,
    );

    int newIndex = currentIndex + direction;
    if (newIndex < 0) newIndex = widget.allChannels.length - 1;
    if (newIndex >= widget.allChannels.length) newIndex = 0;

    final newChannel = widget.allChannels[newIndex];
    _slots[slotIndex].changeChannel(newChannel);
    setState(() {});
  }

  void _makeSlotFullScreen(int slotIndex) {
    if (slotIndex >= _slots.length) return;
    // Navigate to single channel player
    Navigator.of(context).pop(_slots[slotIndex].channel);
  }

  void _cycleLayout() {
    setState(() {
      final layouts = MultiviewLayout.values;
      final currentIndex = layouts.indexOf(_layout);
      _layout = layouts[(currentIndex + 1) % layouts.length];
    });
  }

  void _addSlot() {
    if (_slots.length >= 4) return;

    // Find a channel not already in a slot
    LiveTVChannel? newChannel;
    for (final channel in widget.allChannels) {
      final isInSlot = _slots.any((s) => s.channel.id == channel.id);
      if (!isInSlot) {
        newChannel = channel;
        break;
      }
    }

    if (newChannel != null) {
      setState(() {
        _slots.add(_MultiviewSlot(
          channel: newChannel!,
          onReady: () => setState(() {}),
        ));
        // Update layout
        if (_slots.length == 2) _layout = MultiviewLayout.twoByOne;
        if (_slots.length == 3) _layout = MultiviewLayout.threeGrid;
        if (_slots.length == 4) _layout = MultiviewLayout.twoByTwo;
      });
    }
  }

  void _removeSlot(int slotIndex) {
    if (_slots.length <= 1) return;
    if (slotIndex >= _slots.length) return;

    setState(() {
      _slots[slotIndex].dispose();
      _slots.removeAt(slotIndex);
      _focusedSlotIndex = _focusedSlotIndex.clamp(0, _slots.length - 1);
      // Update layout
      if (_slots.length == 1) _layout = MultiviewLayout.single;
      if (_slots.length == 2) _layout = MultiviewLayout.twoByOne;
      if (_slots.length == 3) _layout = MultiviewLayout.threeGrid;
    });
  }

  void _swapChannel(int slotIndex) async {
    if (slotIndex >= _slots.length) return;

    final selected = await showDialog<LiveTVChannel>(
      context: context,
      builder: (context) => _ChannelPickerDialog(
        channels: widget.allChannels,
        currentChannel: _slots[slotIndex].channel,
      ),
    );

    if (selected != null && mounted) {
      _slots[slotIndex].changeChannel(selected);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _handleTap,
          child: Stack(
            children: [
              // Multi-view grid
              _buildMultiviewGrid(),
              // Controls overlay
              if (_showControls) _buildControlsOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiviewGrid() {
    switch (_layout) {
      case MultiviewLayout.single:
        return _buildSlot(0);
      case MultiviewLayout.twoByOne:
        return Row(
          children: [
            Expanded(child: _buildSlot(0)),
            if (_slots.length > 1) Expanded(child: _buildSlot(1)),
          ],
        );
      case MultiviewLayout.oneByTwo:
        return Column(
          children: [
            Expanded(child: _buildSlot(0)),
            if (_slots.length > 1) Expanded(child: _buildSlot(1)),
          ],
        );
      case MultiviewLayout.threeGrid:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildSlot(0)),
                  if (_slots.length > 1) Expanded(child: _buildSlot(1)),
                ],
              ),
            ),
            if (_slots.length > 2)
              Expanded(
                child: _buildSlot(2),
              ),
          ],
        );
      case MultiviewLayout.twoByTwo:
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildSlot(0)),
                  if (_slots.length > 1) Expanded(child: _buildSlot(1)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  if (_slots.length > 2) Expanded(child: _buildSlot(2)),
                  if (_slots.length > 3) Expanded(child: _buildSlot(3)),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildSlot(int index) {
    if (index >= _slots.length) {
      return Container(color: Colors.black);
    }

    final slot = _slots[index];
    final isFocused = index == _focusedSlotIndex && _showControls;

    return GestureDetector(
      onTap: () {
        setState(() {
          _focusedSlotIndex = index;
        });
        _showControlsAndResetTimer();
      },
      onDoubleTap: () => _makeSlotFullScreen(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isFocused ? Colors.blue : Colors.grey.shade800,
            width: isFocused ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Video
            if (slot.player != null && slot.isReady)
              Video(
                player: slot.player!,
                fit: BoxFit.contain,
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            // Channel info overlay
            if (_showControls)
              Positioned(
                left: 8,
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (slot.channel.logo != null)
                        Image.network(
                          slot.channel.logo!,
                          width: 32,
                          height: 32,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slot.channel.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (slot.channel.nowPlaying != null)
                              Text(
                                slot.channel.nowPlaying!.title,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (slot.isMuted)
                        const Icon(Icons.volume_off, color: Colors.red, size: 20),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              Text(
                t.multiview.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Layout button
              IconButton(
                onPressed: _cycleLayout,
                icon: const Icon(Icons.grid_view, color: Colors.white),
                tooltip: t.multiview.changeLayout,
              ),
              // Add slot button
              if (_slots.length < 4)
                IconButton(
                  onPressed: _addSlot,
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: t.multiview.addChannel,
                ),
              // Remove slot button
              if (_slots.length > 1)
                IconButton(
                  onPressed: () => _removeSlot(_focusedSlotIndex),
                  icon: const Icon(Icons.remove, color: Colors.white),
                  tooltip: t.multiview.removeChannel,
                ),
              // Swap channel button
              IconButton(
                onPressed: () => _swapChannel(_focusedSlotIndex),
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                tooltip: t.multiview.swapChannel,
              ),
              // Mute button
              IconButton(
                onPressed: () {
                  _slots[_focusedSlotIndex].toggleMute();
                  setState(() {});
                },
                icon: Icon(
                  _slots[_focusedSlotIndex].isMuted
                      ? Icons.volume_off
                      : Icons.volume_up,
                  color: Colors.white,
                ),
                tooltip: t.multiview.toggleMute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum MultiviewLayout {
  single,
  twoByOne, // Side by side
  oneByTwo, // Stacked
  threeGrid, // 2 top, 1 bottom
  twoByTwo, // 2x2 grid
}

/// A single slot in the multi-view grid
class _MultiviewSlot {
  LiveTVChannel channel;
  Player? player;
  bool isReady = false;
  bool isMuted = true; // Muted by default in multi-view
  final VoidCallback onReady;
  StreamSubscription<bool>? _bufferingSubscription;

  _MultiviewSlot({
    required this.channel,
    required this.onReady,
  }) {
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final settingsService = await SettingsService.getInstance();
      final enableHardwareDecoding = settingsService.getEnableHardwareDecoding();

      player = Player();
      await player!.setProperty('hwdec', enableHardwareDecoding ? 'auto-safe' : 'no');
      await player!.setProperty('cache', 'yes');
      await player!.setProperty('cache-secs', '10');
      await player!.setProperty('demuxer-readahead-secs', '10');
      await player!.setProperty(
        'stream-lavf-o',
        'reconnect=1,reconnect_streamed=1,reconnect_delay_max=2',
      );

      // Start muted
      await player!.setVolume(0);

      _bufferingSubscription = player!.streams.buffering.listen((buffering) {
        if (!buffering && !isReady) {
          isReady = true;
          onReady();
        }
      });

      await _playChannel();
    } catch (e) {
      appLogger.e('Failed to initialize multiview slot', error: e);
    }
  }

  Future<void> _playChannel() async {
    if (player == null) return;

    try {
      isReady = false;
      final url = channel.streamUrl;
      if (url.isEmpty) return;

      await player!.open(Media(url));
    } catch (e) {
      appLogger.e('Failed to play channel in multiview', error: e);
    }
  }

  void changeChannel(LiveTVChannel newChannel) {
    channel = newChannel;
    _playChannel();
  }

  void toggleMute() {
    isMuted = !isMuted;
    player?.setVolume(isMuted ? 0 : 100);
  }

  void dispose() {
    _bufferingSubscription?.cancel();
    player?.dispose();
  }
}

/// Dialog to pick a channel for a slot
class _ChannelPickerDialog extends StatefulWidget {
  final List<LiveTVChannel> channels;
  final LiveTVChannel currentChannel;

  const _ChannelPickerDialog({
    required this.channels,
    required this.currentChannel,
  });

  @override
  State<_ChannelPickerDialog> createState() => _ChannelPickerDialogState();
}

class _ChannelPickerDialogState extends State<_ChannelPickerDialog> {
  String _searchQuery = '';

  List<LiveTVChannel> get _filteredChannels {
    if (_searchQuery.isEmpty) return widget.channels;
    final query = _searchQuery.toLowerCase();
    return widget.channels.where((c) {
      return c.name.toLowerCase().contains(query) ||
          (c.number?.toString().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              t.multiview.selectChannel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: t.multiview.searchChannels,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredChannels.length,
                itemBuilder: (context, index) {
                  final channel = _filteredChannels[index];
                  final isSelected = channel.id == widget.currentChannel.id;
                  return ListTile(
                    leading: channel.logo != null
                        ? Image.network(
                            channel.logo!,
                            width: 40,
                            height: 40,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.tv),
                          )
                        : const Icon(Icons.tv),
                    title: Text(channel.name),
                    subtitle: channel.number != null
                        ? Text(t.multiview.channelNumber(number: channel.number.toString()))
                        : null,
                    selected: isSelected,
                    onTap: () => Navigator.pop(context, channel),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.multiview.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
