import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'storage_service.dart';

/// Represents a watch party session
class WatchParty {
  final String id;
  final String name;
  final String hostName;
  final String mediaKey;
  final String mediaTitle;
  final String mediaType;
  final DateTime createdAt;
  final List<WatchPartyParticipant> participants;
  final PlaybackState state;

  WatchParty({
    required this.id,
    required this.name,
    required this.hostName,
    required this.mediaKey,
    required this.mediaTitle,
    required this.mediaType,
    required this.createdAt,
    required this.participants,
    required this.state,
  });

  factory WatchParty.fromJson(Map<String, dynamic> json) {
    return WatchParty(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      hostName: json['hostName'] ?? '',
      mediaKey: json['mediaKey'] ?? '',
      mediaTitle: json['mediaTitle'] ?? '',
      mediaType: json['mediaType'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => WatchPartyParticipant.fromJson(p))
              .toList() ??
          [],
      state: json['state'] != null
          ? PlaybackState.fromJson(json['state'])
          : PlaybackState.initial(),
    );
  }
}

/// Represents a participant in a watch party
class WatchPartyParticipant {
  final String id;
  final String userName;
  final bool isHost;
  final DateTime joinedAt;

  WatchPartyParticipant({
    required this.id,
    required this.userName,
    required this.isHost,
    required this.joinedAt,
  });

  factory WatchPartyParticipant.fromJson(Map<String, dynamic> json) {
    return WatchPartyParticipant(
      id: json['id'] ?? '',
      userName: json['userName'] ?? 'Guest',
      isHost: json['isHost'] ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
    );
  }
}

/// Represents synchronized playback state
class PlaybackState {
  final bool playing;
  final double position; // seconds
  final double speed;
  final int updatedAt; // Unix timestamp
  final String updatedBy;

  PlaybackState({
    required this.playing,
    required this.position,
    required this.speed,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory PlaybackState.initial() {
    return PlaybackState(
      playing: false,
      position: 0,
      speed: 1.0,
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      updatedBy: '',
    );
  }

  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    return PlaybackState(
      playing: json['playing'] ?? false,
      position: (json['position'] ?? 0).toDouble(),
      speed: (json['speed'] ?? 1.0).toDouble(),
      updatedAt: json['updatedAt'] ?? 0,
      updatedBy: json['updatedBy'] ?? '',
    );
  }
}

/// Chat message in a watch party
class WatchPartyChatMessage {
  final String text;
  final String from;
  final DateTime sentAt;

  WatchPartyChatMessage({
    required this.text,
    required this.from,
    required this.sentAt,
  });

  factory WatchPartyChatMessage.fromJson(Map<String, dynamic> json) {
    return WatchPartyChatMessage(
      text: json['text'] ?? '',
      from: json['from'] ?? 'Unknown',
      sentAt: json['sentAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['sentAt'] * 1000)
          : DateTime.now(),
    );
  }
}

/// Reaction in a watch party
class WatchPartyReaction {
  final String emoji;
  final String from;

  WatchPartyReaction({required this.emoji, required this.from});

  factory WatchPartyReaction.fromJson(Map<String, dynamic> json) {
    return WatchPartyReaction(
      emoji: json['emoji'] ?? '👍',
      from: json['from'] ?? 'Unknown',
    );
  }
}

/// Service for managing watch party connections
class WatchPartyService extends ChangeNotifier {
  static WatchPartyService? _instance;
  static WatchPartyService get instance {
    _instance ??= WatchPartyService._();
    return _instance!;
  }

  WatchPartyService._();

  WebSocketChannel? _channel;
  WatchParty? _currentParty;
  bool _isHost = false;
  bool _isConnected = false;
  String? _participantId;

  final _stateController = StreamController<PlaybackState>.broadcast();
  final _chatController = StreamController<WatchPartyChatMessage>.broadcast();
  final _reactionController = StreamController<WatchPartyReaction>.broadcast();
  final _participantController =
      StreamController<List<WatchPartyParticipant>>.broadcast();
  final _eventController = StreamController<WatchPartyEvent>.broadcast();

  Stream<PlaybackState> get stateStream => _stateController.stream;
  Stream<WatchPartyChatMessage> get chatStream => _chatController.stream;
  Stream<WatchPartyReaction> get reactionStream => _reactionController.stream;
  Stream<List<WatchPartyParticipant>> get participantStream =>
      _participantController.stream;
  Stream<WatchPartyEvent> get eventStream => _eventController.stream;

  WatchParty? get currentParty => _currentParty;
  bool get isHost => _isHost;
  bool get isConnected => _isConnected;
  String? get participantId => _participantId;

  List<WatchPartyParticipant> _participants = [];
  List<WatchPartyParticipant> get participants => _participants;

  StorageService? _storage;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<StorageService> get _storageService async {
    _storage ??= await StorageService.getInstance();
    return _storage!;
  }

  /// Create a new watch party
  Future<WatchParty?> createParty({
    required String mediaKey,
    required String mediaTitle,
    required String mediaType,
    String? name,
  }) async {
    final storage = await _storageService;
    final serverUrl = storage.getServerUrl();
    final token = storage.getToken();

    if (serverUrl == null || token == null) {
      throw Exception('Not connected to server');
    }

    try {
      final response = await _dio.post(
        '$serverUrl/watchparty',
        data: {
          'name': name ?? 'Watch Party',
          'mediaKey': mediaKey,
          'mediaTitle': mediaTitle,
          'mediaType': mediaType,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data != null && response.data['party'] != null) {
        _currentParty = WatchParty.fromJson(response.data['party']);
        _isHost = true;
        notifyListeners();
        return _currentParty;
      }
    } catch (e) {
      debugPrint('Failed to create watch party: $e');
    }
    return null;
  }

  /// Join an existing watch party via WebSocket
  Future<bool> joinParty(String partyId) async {
    final storage = await _storageService;
    final serverUrl = storage.getServerUrl();
    final token = storage.getToken();

    if (serverUrl == null || token == null) {
      throw Exception('Not connected to server');
    }

    try {
      // Convert HTTP URL to WebSocket URL
      final wsUrl = serverUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      final uri = Uri.parse('$wsUrl/watchparty/$partyId/ws?token=$token');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to join watch party: $e');
      return false;
    }
  }

  /// Leave the current watch party
  void leaveParty() {
    _channel?.sink.close();
    _channel = null;
    _currentParty = null;
    _isHost = false;
    _isConnected = false;
    _participants = [];
    _participantId = null;
    notifyListeners();
  }

  /// Send play command (host only)
  void sendPlay() {
    if (!_isHost) return;
    _sendMessage({'type': 'play'});
  }

  /// Send pause command (host only)
  void sendPause() {
    if (!_isHost) return;
    _sendMessage({'type': 'pause'});
  }

  /// Send seek command (host only)
  void sendSeek(double position) {
    if (!_isHost) return;
    _sendMessage({
      'type': 'seek',
      'payload': {'position': position},
    });
  }

  /// Request current state sync
  void requestSync() {
    _sendMessage({'type': 'sync_request'});
  }

  /// Send a chat message
  void sendChat(String text) {
    _sendMessage({
      'type': 'chat',
      'payload': {'text': text},
    });
  }

  /// Send a reaction emoji
  void sendReaction(String emoji) {
    _sendMessage({
      'type': 'reaction',
      'payload': {'emoji': emoji},
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String?;
      final payload = message['payload'];

      switch (type) {
        case 'state_sync':
        case 'state_update':
          if (payload != null) {
            final state = PlaybackState.fromJson(payload as Map<String, dynamic>);
            _stateController.add(state);
            _eventController.add(WatchPartyEvent.stateUpdate(state));
          }
          break;

        case 'participant_joined':
          if (payload != null) {
            final participant =
                WatchPartyParticipant.fromJson(payload as Map<String, dynamic>);
            _participants.add(participant);
            _participantController.add(_participants);
            _eventController.add(WatchPartyEvent.participantJoined(participant));
          }
          break;

        case 'participant_left':
          if (payload != null) {
            final id = payload['id'] as String?;
            _participants.removeWhere((p) => p.id == id);
            _participantController.add(_participants);
            _eventController.add(WatchPartyEvent.participantLeft(
              payload['userName'] as String? ?? 'Someone',
            ));
          }
          break;

        case 'chat':
          if (payload != null) {
            final chat =
                WatchPartyChatMessage.fromJson(payload as Map<String, dynamic>);
            _chatController.add(chat);
          }
          break;

        case 'reaction':
          if (payload != null) {
            final reaction =
                WatchPartyReaction.fromJson(payload as Map<String, dynamic>);
            _reactionController.add(reaction);
          }
          break;

        case 'party_closed':
          _eventController.add(WatchPartyEvent.partyClosed(
            payload?['reason'] as String? ?? 'Party ended',
          ));
          leaveParty();
          break;
      }
    } catch (e) {
      debugPrint('Error handling watch party message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('Watch party WebSocket error: $error');
    _isConnected = false;
    notifyListeners();
  }

  void _handleDone() {
    debugPrint('Watch party WebSocket closed');
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _stateController.close();
    _chatController.close();
    _reactionController.close();
    _participantController.close();
    _eventController.close();
    super.dispose();
  }
}

/// Events that occur in a watch party
abstract class WatchPartyEvent {
  factory WatchPartyEvent.stateUpdate(PlaybackState state) = StateUpdateEvent;
  factory WatchPartyEvent.participantJoined(WatchPartyParticipant participant) =
      ParticipantJoinedEvent;
  factory WatchPartyEvent.participantLeft(String userName) =
      ParticipantLeftEvent;
  factory WatchPartyEvent.partyClosed(String reason) = PartyClosedEvent;
}

class StateUpdateEvent implements WatchPartyEvent {
  final PlaybackState state;
  StateUpdateEvent(this.state);
}

class ParticipantJoinedEvent implements WatchPartyEvent {
  final WatchPartyParticipant participant;
  ParticipantJoinedEvent(this.participant);
}

class ParticipantLeftEvent implements WatchPartyEvent {
  final String userName;
  ParticipantLeftEvent(this.userName);
}

class PartyClosedEvent implements WatchPartyEvent {
  final String reason;
  PartyClosedEvent(this.reason);
}
