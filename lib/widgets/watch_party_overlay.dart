import 'dart:async';
import 'package:flutter/material.dart';
import '../i18n/strings.g.dart';
import '../services/watch_party_service.dart';

/// Overlay widget for Watch Party during video playback
class WatchPartyOverlay extends StatefulWidget {
  final bool visible;
  final bool isHost;
  final VoidCallback? onLeave;

  const WatchPartyOverlay({
    super.key,
    this.visible = true,
    this.isHost = false,
    this.onLeave,
  });

  @override
  State<WatchPartyOverlay> createState() => _WatchPartyOverlayState();
}

class _WatchPartyOverlayState extends State<WatchPartyOverlay> {
  final WatchPartyService _service = WatchPartyService.instance;
  final TextEditingController _chatController = TextEditingController();
  final List<WatchPartyChatMessage> _messages = [];
  final List<_FloatingReaction> _reactions = [];
  StreamSubscription<WatchPartyChatMessage>? _chatSub;
  StreamSubscription<WatchPartyReaction>? _reactionSub;
  StreamSubscription<WatchPartyEvent>? _eventSub;
  bool _showChat = false;
  bool _showParticipants = false;

  @override
  void initState() {
    super.initState();
    _chatSub = _service.chatStream.listen(_onChatMessage);
    _reactionSub = _service.reactionStream.listen(_onReaction);
    _eventSub = _service.eventStream.listen(_onEvent);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatSub?.cancel();
    _reactionSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  void _onChatMessage(WatchPartyChatMessage message) {
    setState(() {
      _messages.add(message);
      if (_messages.length > 50) {
        _messages.removeAt(0);
      }
    });
  }

  void _onReaction(WatchPartyReaction reaction) {
    setState(() {
      _reactions.add(_FloatingReaction(
        emoji: reaction.emoji,
        from: reaction.from,
        createdAt: DateTime.now(),
      ));
    });

    // Remove after animation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _reactions.removeWhere(
            (r) => DateTime.now().difference(r.createdAt).inSeconds >= 3,
          );
        });
      }
    });
  }

  void _onEvent(WatchPartyEvent event) {
    if (event is PartyClosedEvent) {
      _showSnackBar('Watch Party ended: ${event.reason}');
      widget.onLeave?.call();
    } else if (event is ParticipantJoinedEvent) {
      _showSnackBar('${event.participant.userName} joined');
    } else if (event is ParticipantLeftEvent) {
      _showSnackBar('${event.userName} left');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isNotEmpty) {
      _service.sendChat(text);
      _chatController.clear();
    }
  }

  void _sendReaction(String emoji) {
    _service.sendReaction(emoji);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Stack(
      children: [
        // Floating reactions
        ..._reactions.map((r) => _buildFloatingReaction(r)),

        // Party info badge (top-left)
        Positioned(
          top: 16,
          left: 16,
          child: _buildPartyBadge(),
        ),

        // Participants panel (top-right)
        if (_showParticipants)
          Positioned(
            top: 16,
            right: 16,
            child: _buildParticipantsPanel(),
          ),

        // Quick reactions (bottom-right)
        Positioned(
          bottom: 100,
          right: 16,
          child: _buildReactionBar(),
        ),

        // Chat panel (bottom-left)
        Positioned(
          bottom: 16,
          left: 16,
          right: 200,
          child: _showChat ? _buildChatPanel() : _buildChatPreview(),
        ),
      ],
    );
  }

  Widget _buildPartyBadge() {
    final party = _service.currentParty;
    final participantCount = _service.participants.length;

    return GestureDetector(
      onTap: () => setState(() => _showParticipants = !_showParticipants),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              party?.name ?? 'Watch Party',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$participantCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showParticipants
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsPanel() {
    return Container(
      width: 200,
      constraints: const BoxConstraints(maxHeight: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Participants',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showParticipants = false),
                child: const Icon(Icons.close, color: Colors.grey, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._service.participants.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: p.isHost ? Colors.purple : Colors.grey,
                      child: Text(
                        p.userName.isNotEmpty ? p.userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          if (p.isHost)
                            const Text(
                              'Host',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(color: Colors.grey),
          if (widget.isHost)
            _buildActionButton(
              'End Party',
              Icons.close,
              Colors.red,
              widget.onLeave,
            )
          else
            _buildActionButton(
              'Leave Party',
              Icons.exit_to_app,
              Colors.orange,
              widget.onLeave,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionBar() {
    const reactions = ['👍', '❤️', '😂', '😮', '👏', '🔥'];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((emoji) {
          return GestureDetector(
            onTap: () => _sendReaction(emoji),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatPreview() {
    return GestureDetector(
      onTap: () => setState(() => _showChat = true),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble, color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Chat',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            if (_messages.isNotEmpty)
              Text(
                '${_messages.last.from}: ${_messages.last.text}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              const Text(
                'Tap to open chat',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Chat',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showChat = false),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${message.from}: ',
                          style: const TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendChat,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingReaction(_FloatingReaction reaction) {
    final age = DateTime.now().difference(reaction.createdAt);
    final progress = age.inMilliseconds / 3000; // 3 second animation

    return Positioned(
      right: 80 + (50 * progress),
      bottom: 120 + (200 * progress),
      child: Opacity(
        opacity: 1 - progress,
        child: Transform.scale(
          scale: 1 + (0.5 * progress),
          child: Text(
            reaction.emoji,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
    );
  }
}

class _FloatingReaction {
  final String emoji;
  final String from;
  final DateTime createdAt;

  _FloatingReaction({
    required this.emoji,
    required this.from,
    required this.createdAt,
  });
}

/// Dialog to create or join a watch party
class WatchPartyDialog extends StatefulWidget {
  final String mediaKey;
  final String mediaTitle;
  final String mediaType;

  const WatchPartyDialog({
    super.key,
    required this.mediaKey,
    required this.mediaTitle,
    required this.mediaType,
  });

  @override
  State<WatchPartyDialog> createState() => _WatchPartyDialogState();
}

class _WatchPartyDialogState extends State<WatchPartyDialog> {
  final _codeController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createParty() async {
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final party = await WatchPartyService.instance.createParty(
        mediaKey: widget.mediaKey,
        mediaTitle: widget.mediaTitle,
        mediaType: widget.mediaType,
      );

      if (party != null && mounted) {
        Navigator.of(context).pop({'action': 'created', 'party': party});
      } else {
        setState(() => _error = 'Failed to create party');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _joinParty() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a party code');
      return;
    }

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final success = await WatchPartyService.instance.joinParty(code);
      if (success && mounted) {
        Navigator.of(context).pop({'action': 'joined', 'code': code});
      } else {
        setState(() => _error = 'Failed to join party');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups, color: Colors.purple, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Watch Party',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mediaTitle,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // Create party button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createParty,
                icon: _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Start Watch Party'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider(color: Colors.grey)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),

            // Join party section
            TextField(
              controller: _codeController,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Enter party code',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isJoining ? null : _joinParty,
                icon: _isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: const Text('Join Party'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to show watch party code sharing dialog
Future<void> showWatchPartyCodeDialog(
  BuildContext context,
  WatchParty party,
) async {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups, color: Colors.purple, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Share this code',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple),
              ),
              child: Text(
                party.id,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Friends can join using this code',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: Text(t.watchParty.gotIt),
            ),
          ],
        ),
      ),
    ),
  );
}
