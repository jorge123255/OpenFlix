import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../services/voice_control_service.dart';

/// A floating action button for voice control
class VoiceControlButton extends StatefulWidget {
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final void Function(int seconds)? onForward;
  final void Function(int seconds)? onRewind;
  final VoidCallback? onVolumeUp;
  final VoidCallback? onVolumeDown;
  final VoidCallback? onMute;
  final VoidCallback? onFullscreen;
  final VoidCallback? onSubtitles;
  final void Function(String query)? onSearch;
  final VoidCallback? onHome;
  final VoidCallback? onBack;

  const VoiceControlButton({
    super.key,
    this.onPlay,
    this.onPause,
    this.onNext,
    this.onPrevious,
    this.onForward,
    this.onRewind,
    this.onVolumeUp,
    this.onVolumeDown,
    this.onMute,
    this.onFullscreen,
    this.onSubtitles,
    this.onSearch,
    this.onHome,
    this.onBack,
  });

  @override
  State<VoiceControlButton> createState() => _VoiceControlButtonState();
}

class _VoiceControlButtonState extends State<VoiceControlButton>
    with SingleTickerProviderStateMixin {
  VoiceControlService? _voiceService;
  StreamSubscription<VoiceCommandResult>? _commandSubscription;
  bool _isInitializing = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    final service = await VoiceControlService.getInstance();
    if (mounted) {
      setState(() {
        _voiceService = service;
        _isInitializing = false;
      });

      _commandSubscription = service.commandStream.listen(_handleCommand);
    }
  }

  void _handleCommand(VoiceCommandResult result) {
    switch (result.command) {
      case VoiceCommand.play:
        widget.onPlay?.call();
        break;
      case VoiceCommand.pause:
        widget.onPause?.call();
        break;
      case VoiceCommand.next:
        widget.onNext?.call();
        break;
      case VoiceCommand.previous:
        widget.onPrevious?.call();
        break;
      case VoiceCommand.forward:
        widget.onForward?.call(result.value ?? 10);
        break;
      case VoiceCommand.rewind:
        widget.onRewind?.call(result.value ?? 10);
        break;
      case VoiceCommand.volumeUp:
        widget.onVolumeUp?.call();
        break;
      case VoiceCommand.volumeDown:
        widget.onVolumeDown?.call();
        break;
      case VoiceCommand.mute:
      case VoiceCommand.unmute:
        widget.onMute?.call();
        break;
      case VoiceCommand.fullscreen:
        widget.onFullscreen?.call();
        break;
      case VoiceCommand.subtitles:
        widget.onSubtitles?.call();
        break;
      case VoiceCommand.search:
        if (result.query != null) {
          widget.onSearch?.call(result.query!);
        }
        break;
      case VoiceCommand.home:
        widget.onHome?.call();
        break;
      case VoiceCommand.back:
      case VoiceCommand.stop:
        widget.onBack?.call();
        break;
      case VoiceCommand.unknown:
        // Show feedback that command wasn't recognized
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.voice.commandNotRecognized(command: _voiceService?.lastWords ?? '')),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        break;
    }
  }

  @override
  void dispose() {
    _commandSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_voiceService == null || !_voiceService!.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.voice.notAvailable),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_voiceService!.isListening) {
      await _voiceService!.stopListening();
      _pulseController.stop();
      _pulseController.reset();
    } else {
      await _voiceService!.startListening();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const SizedBox.shrink();
    }

    if (_voiceService == null || !_voiceService!.isAvailable) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _voiceService!,
      builder: (context, _) {
        final isListening = _voiceService!.isListening;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show recognized text while listening
            if (isListening && _voiceService!.lastWords.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _voiceService!.lastWords,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ScaleTransition(
              scale: isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: FloatingActionButton(
                onPressed: _toggleListening,
                backgroundColor: isListening
                    ? theme.colorScheme.error
                    : theme.colorScheme.primaryContainer,
                foregroundColor: isListening
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onPrimaryContainer,
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A compact voice control button for app bars
class VoiceControlIconButton extends StatefulWidget {
  final void Function(VoiceCommandResult)? onCommand;

  const VoiceControlIconButton({
    super.key,
    this.onCommand,
  });

  @override
  State<VoiceControlIconButton> createState() => _VoiceControlIconButtonState();
}

class _VoiceControlIconButtonState extends State<VoiceControlIconButton> {
  VoiceControlService? _voiceService;
  StreamSubscription<VoiceCommandResult>? _commandSubscription;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    final service = await VoiceControlService.getInstance();
    if (mounted) {
      setState(() {
        _voiceService = service;
        _isInitializing = false;
      });

      _commandSubscription = service.commandStream.listen((result) {
        widget.onCommand?.call(result);
      });
    }
  }

  @override
  void dispose() {
    _commandSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_voiceService == null || !_voiceService!.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.voice.notAvailable),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_voiceService!.isListening) {
      await _voiceService!.stopListening();
    } else {
      await _voiceService!.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const SizedBox.shrink();
    }

    if (_voiceService == null || !_voiceService!.isAvailable) {
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: _voiceService!,
      builder: (context, _) {
        final isListening = _voiceService!.isListening;

        return IconButton(
          icon: Icon(
            isListening ? Icons.mic : Icons.mic_none,
            color: isListening ? Theme.of(context).colorScheme.error : null,
          ),
          tooltip: isListening ? 'Stop listening' : 'Voice control',
          onPressed: _toggleListening,
        );
      },
    );
  }
}

/// Bottom sheet for voice control with visual feedback
Future<void> showVoiceControlSheet(
  BuildContext context, {
  void Function(VoiceCommandResult)? onCommand,
}) async {
  await showModalBottomSheet(
    context: context,
    builder: (context) => _VoiceControlSheet(onCommand: onCommand),
    isScrollControlled: true,
  );
}

class _VoiceControlSheet extends StatefulWidget {
  final void Function(VoiceCommandResult)? onCommand;

  const _VoiceControlSheet({this.onCommand});

  @override
  State<_VoiceControlSheet> createState() => _VoiceControlSheetState();
}

class _VoiceControlSheetState extends State<_VoiceControlSheet>
    with SingleTickerProviderStateMixin {
  VoiceControlService? _voiceService;
  StreamSubscription<VoiceCommandResult>? _commandSubscription;
  bool _isInitializing = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    final service = await VoiceControlService.getInstance();
    if (mounted) {
      setState(() {
        _voiceService = service;
        _isInitializing = false;
      });

      _commandSubscription = service.commandStream.listen((result) {
        widget.onCommand?.call(result);
        if (result.command != VoiceCommand.unknown && mounted) {
          Navigator.pop(context);
        }
      });

      // Start listening immediately
      await service.startListening();
    }
  }

  @override
  void dispose() {
    _commandSubscription?.cancel();
    _pulseController.dispose();
    _voiceService?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isInitializing) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_voiceService == null || !_voiceService!.isAvailable) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_off,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Voice control is not available',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _voiceService!,
      builder: (context, _) {
        final isListening = _voiceService!.isListening;
        final lastWords = _voiceService!.lastWords;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Microphone icon with pulse animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 100 + (_pulseController.value * 20),
                    height: 100 + (_pulseController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isListening
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary)
                          .withValues(alpha: 0.2 - (_pulseController.value * 0.1)),
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        child: Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          size: 40,
                          color: isListening
                              ? theme.colorScheme.onError
                              : theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Status text
              Text(
                isListening ? 'Listening...' : 'Tap to speak',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),

              // Recognized text
              if (lastWords.isNotEmpty)
                Text(
                  '"$lastWords"',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 16),

              // Example commands
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  'Play',
                  'Pause',
                  'Search for...',
                  'Next',
                  'Skip 30 seconds',
                ]
                    .map((cmd) => Chip(
                          label: Text(cmd, style: theme.textTheme.bodySmall),
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ))
                    .toList(),
              ),

              const SizedBox(height: 24),

              // Cancel button
              TextButton(
                onPressed: () {
                  _voiceService?.cancelListening();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }
}
