import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sports_scores_service.dart';

/// Overlay widget to display live sports scores during video playback
class SportsScoresOverlay extends StatefulWidget {
  final bool visible;
  final bool compact; // Show only the most important game
  final VoidCallback? onDismiss;

  const SportsScoresOverlay({
    super.key,
    this.visible = true,
    this.compact = true,
    this.onDismiss,
  });

  @override
  State<SportsScoresOverlay> createState() => _SportsScoresOverlayState();
}

class _SportsScoresOverlayState extends State<SportsScoresOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  StreamSubscription<List<SportsGame>>? _scoresSubscription;
  List<SportsGame> _games = [];
  int _currentGameIndex = 0;
  Timer? _rotateTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Subscribe to scores
    _scoresSubscription = SportsScoresService.instance.scoresStream.listen((games) {
      setState(() {
        _games = games.where((g) => g.isLive).toList();
      });
    });

    // Start polling
    SportsScoresService.instance.startPolling();

    // Rotate between games every 10 seconds
    _rotateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_games.length > 1) {
        setState(() {
          _currentGameIndex = (_currentGameIndex + 1) % _games.length;
        });
      }
    });

    if (widget.visible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(SportsScoresOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scoresSubscription?.cancel();
    _rotateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_games.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.compact
              ? _buildCompactScoreCard(_games[_currentGameIndex % _games.length])
              : _buildExpandedScoreCard(),
        ),
      ),
    );
  }

  Widget _buildCompactScoreCard(SportsGame game) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: game.isLive ? Colors.red : Colors.grey,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Live indicator
            if (game.isLive)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            // Teams and score
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTeamScore(game.awayTeam, game.awayScore, game.awayScore > game.homeScore),
                const SizedBox(height: 2),
                _buildTeamScore(game.homeTeam, game.homeScore, game.homeScore > game.awayScore),
              ],
            ),
            const SizedBox(width: 12),
            // Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  game.league,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  game.statusDisplay,
                  style: TextStyle(
                    color: game.isLive ? Colors.white : Colors.grey,
                    fontSize: 11,
                    fontWeight: game.isLive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            // Close button
            if (widget.onDismiss != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScore(String team, int score, bool isWinning) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            team,
            style: TextStyle(
              color: isWinning ? Colors.white : Colors.grey[400],
              fontSize: 13,
              fontWeight: isWinning ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          score.toString(),
          style: TextStyle(
            color: isWinning ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedScoreCard() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Scores',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onDismiss != null)
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ..._games.take(3).map((game) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildGameRow(game),
          )),
        ],
      ),
    );
  }

  Widget _buildGameRow(SportsGame game) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: game.isLive
            ? Border.all(color: Colors.red.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          if (game.isLive)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      game.awayTeam,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      game.awayScore.toString(),
                      style: TextStyle(
                        color: game.awayScore > game.homeScore
                            ? Colors.white
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      game.homeTeam,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      game.homeScore.toString(),
                      style: TextStyle(
                        color: game.homeScore > game.awayScore
                            ? Colors.white
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            game.statusDisplay,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// A minimal ticker-style scores display for the bottom of the screen
class SportsScoresTicker extends StatefulWidget {
  final bool visible;

  const SportsScoresTicker({super.key, this.visible = true});

  @override
  State<SportsScoresTicker> createState() => _SportsScoresTickerState();
}

class _SportsScoresTickerState extends State<SportsScoresTicker> {
  StreamSubscription<List<SportsGame>>? _scoresSubscription;
  List<SportsGame> _games = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scoresSubscription = SportsScoresService.instance.scoresStream.listen((games) {
      setState(() {
        _games = games.where((g) => g.isLive).toList();
      });
    });

    // Auto-scroll the ticker
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentScroll + 1);
        }
      }
    });
  }

  @override
  void dispose() {
    _scoresSubscription?.cancel();
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || _games.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 32,
      color: Colors.black.withValues(alpha: 0.8),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _games.length * 10, // Repeat for continuous scroll
        itemBuilder: (context, index) {
          final game = _games[index % _games.length];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (game.isLive)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  '${game.league}: ${game.awayTeam} ${game.awayScore} - ${game.homeScore} ${game.homeTeam}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  game.statusDisplay,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
