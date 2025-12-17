import 'package:flutter/material.dart';

/// Quick record button for Live TV overlay
/// Shows 3 states: default (outline), scheduled (filled), loading
class QuickRecordButton extends StatelessWidget {
  final bool isScheduled;
  final bool isLoading;
  final VoidCallback onPressed;

  const QuickRecordButton({
    super.key,
    required this.isScheduled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(10),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        isScheduled ? Icons.fiber_manual_record : Icons.fiber_manual_record_outlined,
        color: isScheduled ? Colors.red : Colors.white70,
        size: 28,
      ),
      tooltip: isScheduled
          ? 'Recording Scheduled (Click to view)'
          : 'Quick Record (R)',
      style: isScheduled
          ? IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.2),
              side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5),
            )
          : null,
    );
  }
}
