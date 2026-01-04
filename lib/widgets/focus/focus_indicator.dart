import 'dart:io';
import 'package:flutter/material.dart';
import '../../utils/platform_detector.dart';

/// A reusable focus indicator widget that wraps a child with visual feedback
/// when focused. Provides consistent focus appearance across the app for
/// keyboard/d-pad/controller navigation.
///
/// Automatically adjusts appearance for TV mode with larger, more prominent
/// focus indicators suitable for the 10-foot viewing experience.
class FocusIndicator extends StatelessWidget {
  final Widget child;
  final bool isFocused;
  final Color? borderColor;
  final double? borderWidth;
  final double borderRadius;
  final double? scale;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showGlow;

  const FocusIndicator({
    super.key,
    required this.child,
    required this.isFocused,
    this.borderColor,
    this.borderWidth,
    this.borderRadius = 8.0,
    this.scale,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeOutCubic,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isTV = PlatformDetector.shouldUseLargeFocusIndicators(context);
    final effectiveBorderColor =
        borderColor ?? Theme.of(context).colorScheme.primary;

    // TV mode uses larger, more prominent indicators for 10-foot viewing
    final effectiveBorderWidth = borderWidth ?? (isTV ? 4.0 : 3.0);
    final effectiveScale = scale ?? (isTV ? 1.06 : 1.02);

    // On Android, use simpler effects for better performance
    // BoxShadow with blur is expensive on Android GPU
    final useSimpleEffects = Platform.isAndroid;

    // Use AnimatedScale for the scale effect (doesn't affect layout)
    // and a positioned border overlay that also doesn't affect layout
    return AnimatedScale(
      scale: isFocused ? effectiveScale : 1.0,
      duration: useSimpleEffects ? const Duration(milliseconds: 100) : animationDuration,
      curve: animationCurve,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          // Border overlay - doesn't affect layout
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: useSimpleEffects ? const Duration(milliseconds: 100) : animationDuration,
                curve: animationCurve,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isFocused
                        ? effectiveBorderColor
                        : Colors.transparent,
                    width: effectiveBorderWidth,
                  ),
                  // Skip glow effects on Android for performance
                  // BoxShadow with blur is expensive on Android GPU
                  boxShadow: isFocused && showGlow && !useSimpleEffects
                      ? [
                          if (isTV) ...[
                            // Outer glow for TV (desktop only)
                            BoxShadow(
                              color: effectiveBorderColor.withValues(alpha: 0.5),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                            // Inner bright border
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ] else
                            // Subtle glow for desktop/mobile
                            BoxShadow(
                              color: effectiveBorderColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrapper widget that manages its own FocusNode and provides focus state
/// to its builder. Use this for items that need focus handling with
/// automatic FocusNode lifecycle management.
class FocusableWrapper extends StatefulWidget {
  final Widget Function(BuildContext context, bool isFocused) builder;
  final FocusNode? focusNode;
  final bool autofocus;
  final VoidCallback? onFocused;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  final void Function(BuildContext context)? onScrollIntoView;
  final String? debugLabel;

  const FocusableWrapper({
    super.key,
    required this.builder,
    this.focusNode,
    this.autofocus = false,
    this.onFocused,
    this.onKeyEvent,
    this.onScrollIntoView,
    this.debugLabel,
  });

  @override
  State<FocusableWrapper> createState() => _FocusableWrapperState();
}

class _FocusableWrapperState extends State<FocusableWrapper> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode(debugLabel: widget.debugLabel);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    // Only dispose if we created the node
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (_isFocused != hasFocus) {
      setState(() {
        _isFocused = hasFocus;
      });
      if (hasFocus) {
        widget.onFocused?.call();
        // Use custom scroll behavior if provided, otherwise default
        if (widget.onScrollIntoView != null) {
          widget.onScrollIntoView!(context);
        } else {
          // Use faster scroll on Android for better responsiveness
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: Duration(milliseconds: Platform.isAndroid ? 100 : 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    return widget.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: widget.builder(context, _isFocused),
    );
  }
}
