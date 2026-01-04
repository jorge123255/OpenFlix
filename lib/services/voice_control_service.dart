import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../utils/app_logger.dart';

/// Voice command types that can be recognized
enum VoiceCommand {
  play,
  pause,
  stop,
  next,
  previous,
  forward,
  rewind,
  search,
  home,
  back,
  volumeUp,
  volumeDown,
  mute,
  unmute,
  fullscreen,
  subtitles,
  unknown,
}

/// Result of a voice command
class VoiceCommandResult {
  final VoiceCommand command;
  final String? query; // For search commands
  final int? value; // For numeric values (e.g., skip 30 seconds)
  final double confidence;

  VoiceCommandResult({
    required this.command,
    this.query,
    this.value,
    this.confidence = 1.0,
  });
}

/// Service for voice control functionality
class VoiceControlService extends ChangeNotifier {
  static VoiceControlService? _instance;

  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  String _currentLocale = 'en_US';
  List<LocaleName> _availableLocales = [];

  final StreamController<VoiceCommandResult> _commandController =
      StreamController<VoiceCommandResult>.broadcast();

  VoiceControlService._();

  static Future<VoiceControlService> getInstance() async {
    if (_instance == null) {
      _instance = VoiceControlService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );

      if (_isAvailable) {
        _availableLocales = await _speech.locales();
        // Try to find the system locale
        final systemLocale = await _speech.systemLocale();
        if (systemLocale != null) {
          _currentLocale = systemLocale.localeId;
        }
      }

      appLogger.i('Voice control initialized: available=$_isAvailable');
    } catch (e) {
      appLogger.e('Failed to initialize voice control', error: e);
      _isAvailable = false;
    }
  }

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get currentLocale => _currentLocale;
  List<LocaleName> get availableLocales => _availableLocales;
  Stream<VoiceCommandResult> get commandStream => _commandController.stream;

  /// Start listening for voice commands
  Future<void> startListening({
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isAvailable || _isListening) return;

    _isListening = true;
    _lastWords = '';
    notifyListeners();

    await _speech.listen(
      onResult: _onResult,
      listenFor: listenFor ?? const Duration(seconds: 30),
      pauseFor: pauseFor ?? const Duration(seconds: 3),
      localeId: _currentLocale,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
    _lastWords = '';
    notifyListeners();
  }

  void _onStatus(String status) {
    appLogger.d('Voice control status: $status');
    if (status == 'notListening' || status == 'done') {
      _isListening = false;
      notifyListeners();
    }
  }

  void _onError(dynamic error) {
    appLogger.e('Voice control error', error: error);
    _isListening = false;
    notifyListeners();
  }

  void _onResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    notifyListeners();

    if (result.finalResult) {
      final command = _parseCommand(_lastWords);
      _commandController.add(command);
      appLogger.i('Voice command: ${command.command} (query: ${command.query})');
    }
  }

  /// Parse spoken words into a voice command
  VoiceCommandResult _parseCommand(String words) {
    final lowerWords = words.toLowerCase().trim();

    // Play/Pause commands
    if (_matchesAny(lowerWords, ['play', 'resume', 'start'])) {
      return VoiceCommandResult(command: VoiceCommand.play);
    }
    if (_matchesAny(lowerWords, ['pause', 'stop playing'])) {
      return VoiceCommandResult(command: VoiceCommand.pause);
    }
    if (_matchesAny(lowerWords, ['stop', 'exit', 'close'])) {
      return VoiceCommandResult(command: VoiceCommand.stop);
    }

    // Navigation commands
    if (_matchesAny(lowerWords, ['next', 'skip', 'next episode'])) {
      return VoiceCommandResult(command: VoiceCommand.next);
    }
    if (_matchesAny(lowerWords, ['previous', 'back', 'go back', 'previous episode'])) {
      return VoiceCommandResult(command: VoiceCommand.previous);
    }
    if (_matchesAny(lowerWords, ['home', 'go home', 'main menu'])) {
      return VoiceCommandResult(command: VoiceCommand.home);
    }

    // Seek commands
    if (lowerWords.contains('forward') || lowerWords.contains('skip ahead')) {
      final seconds = _extractNumber(lowerWords) ?? 10;
      return VoiceCommandResult(
        command: VoiceCommand.forward,
        value: seconds,
      );
    }
    if (lowerWords.contains('rewind') || lowerWords.contains('go back')) {
      final seconds = _extractNumber(lowerWords) ?? 10;
      return VoiceCommandResult(
        command: VoiceCommand.rewind,
        value: seconds,
      );
    }

    // Volume commands
    if (_matchesAny(lowerWords, ['volume up', 'louder', 'turn up'])) {
      return VoiceCommandResult(command: VoiceCommand.volumeUp);
    }
    if (_matchesAny(lowerWords, ['volume down', 'quieter', 'turn down'])) {
      return VoiceCommandResult(command: VoiceCommand.volumeDown);
    }
    if (_matchesAny(lowerWords, ['mute', 'silence'])) {
      return VoiceCommandResult(command: VoiceCommand.mute);
    }
    if (_matchesAny(lowerWords, ['unmute', 'sound on'])) {
      return VoiceCommandResult(command: VoiceCommand.unmute);
    }

    // UI commands
    if (_matchesAny(lowerWords, ['fullscreen', 'full screen', 'maximize'])) {
      return VoiceCommandResult(command: VoiceCommand.fullscreen);
    }
    if (_matchesAny(lowerWords, ['subtitles', 'captions', 'closed captions'])) {
      return VoiceCommandResult(command: VoiceCommand.subtitles);
    }

    // Search commands
    if (lowerWords.startsWith('search for ')) {
      final query = lowerWords.substring('search for '.length).trim();
      return VoiceCommandResult(
        command: VoiceCommand.search,
        query: query,
      );
    }
    if (lowerWords.startsWith('find ')) {
      final query = lowerWords.substring('find '.length).trim();
      return VoiceCommandResult(
        command: VoiceCommand.search,
        query: query,
      );
    }
    if (lowerWords.startsWith('search ')) {
      final query = lowerWords.substring('search '.length).trim();
      return VoiceCommandResult(
        command: VoiceCommand.search,
        query: query,
      );
    }
    if (lowerWords.startsWith('play ')) {
      // "Play The Office" -> search for it
      final query = lowerWords.substring('play '.length).trim();
      return VoiceCommandResult(
        command: VoiceCommand.search,
        query: query,
      );
    }

    return VoiceCommandResult(command: VoiceCommand.unknown);
  }

  bool _matchesAny(String input, List<String> patterns) {
    for (final pattern in patterns) {
      if (input == pattern || input.startsWith('$pattern ') || input.endsWith(' $pattern')) {
        return true;
      }
    }
    return false;
  }

  int? _extractNumber(String text) {
    final numberPattern = RegExp(r'\d+');
    final match = numberPattern.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(0)!);
    }

    // Handle word numbers
    final wordNumbers = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'fifteen': 15, 'twenty': 20, 'thirty': 30, 'forty': 40,
      'fifty': 50, 'sixty': 60,
    };

    for (final entry in wordNumbers.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Set the locale for speech recognition
  void setLocale(String localeId) {
    _currentLocale = localeId;
  }

  @override
  void dispose() {
    _commandController.close();
    _speech.stop();
    super.dispose();
  }
}
