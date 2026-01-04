import 'package:flutter/material.dart';
import '../i18n/strings.g.dart';

/// Check if content was added within a certain number of days
/// [addedAt] is a Unix timestamp in seconds
bool isNewContent(int? addedAt, {int withinDays = 14}) {
  if (addedAt == null) return false;
  final addedDate = DateTime.fromMillisecondsSinceEpoch(addedAt * 1000);
  final now = DateTime.now();
  final difference = now.difference(addedDate);
  return difference.inDays <= withinDays;
}

/// Type of content badge to display
enum BadgeType {
  /// "NEW" badge for recently added content
  newContent,
  /// "LIVE" badge for live content
  live,
}

/// A badge widget for displaying content status (NEW, LIVE)
class ContentBadge extends StatefulWidget {
  final BadgeType type;

  /// Whether to show a pulse animation (for LIVE badges)
  final bool animate;

  const ContentBadge({
    super.key,
    required this.type,
    this.animate = true,
  });

  @override
  State<ContentBadge> createState() => _ContentBadgeState();
}

class _ContentBadgeState extends State<ContentBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.type == BadgeType.live && widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.type == BadgeType.live;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLive ? Colors.red : const Color(0xFF6366F1), // Red for LIVE, Indigo for NEW
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: (isLive ? Colors.red : const Color(0xFF6366F1)).withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            isLive ? t.common.live : t.common.newLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (isLive && widget.animate) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: child,
          );
        },
        child: badge,
      );
    }

    return badge;
  }
}

/// Convenience widget for a LIVE badge
class LiveBadge extends StatelessWidget {
  /// Whether to show a pulse animation
  final bool animate;

  const LiveBadge({super.key, this.animate = true});

  @override
  Widget build(BuildContext context) {
    return ContentBadge(type: BadgeType.live, animate: animate);
  }
}

/// Convenience widget for a NEW badge
class NewBadge extends StatelessWidget {
  const NewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const ContentBadge(type: BadgeType.newContent);
  }
}
