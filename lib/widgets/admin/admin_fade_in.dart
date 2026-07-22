import 'package:flutter/material.dart';

/// Staggered fade + slide-up entrance for list items. Wrap each item in a
/// `ListView.separated`/`ListView.builder` with `AdminFadeIn(index: i, child: ...)`
/// to get a lightweight "items arriving" feel on first load, purely via
/// implicit animation (no extra package, no change to underlying data flow).
class AdminFadeIn extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration stagger;
  final Duration duration;

  const AdminFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.stagger = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  Widget build(BuildContext context) {
    // Cap the delay so long lists don't leave late items invisible for ages.
    final delayMs = (index * stagger.inMilliseconds).clamp(0, 300);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: delayMs),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) {
        // Hold at 0 during the per-item delay window, then animate in.
        final localT = duration.inMilliseconds == 0
            ? 1.0
            : (((t * (duration.inMilliseconds + delayMs)) - delayMs) / duration.inMilliseconds)
                .clamp(0.0, 1.0);
        return Opacity(
          opacity: localT,
          child: Transform.translate(offset: Offset(0, 12 * (1 - localT)), child: c),
        );
      },
      child: child,
    );
  }
}

/// Subtle hover lift for web/desktop cards — no-op on touch devices since
/// hover events simply never fire there.
class AdminHoverLift extends StatefulWidget {
  final Widget child;
  final double lift;
  const AdminHoverLift({super.key, required this.child, this.lift = 3});

  @override
  State<AdminHoverLift> createState() => _AdminHoverLiftState();
}

class _AdminHoverLiftState extends State<AdminHoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -widget.lift : 0, 0),
        child: widget.child,
      ),
    );
  }
}
