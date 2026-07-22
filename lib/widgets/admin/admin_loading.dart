import 'package:flutter/material.dart';
import '../../core/constants/admin_colors.dart';

/// Branded spinner — thin wrapper so every page pulls the same color instead
/// of re-typing `CircularProgressIndicator(color: Color(0xFF...))`.
class AdminLoadingIndicator extends StatelessWidget {
  final Color color;
  const AdminLoadingIndicator({super.key, this.color = AdminColors.primary});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(color: color, strokeWidth: 3),
      ),
    );
  }
}

/// Shimmering skeleton block, used to build list/card loading placeholders
/// without a bare spinner. Pure implicit-animation, no extra dependency.
class AdminSkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const AdminSkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<AdminSkeletonBox> createState() => _AdminSkeletonBoxState();
}

class _AdminSkeletonBoxState extends State<AdminSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.0 + t * 3, 0),
              end: Alignment(0.0 + t * 3, 0),
              colors: const [
                Color(0xFFEDEEF2),
                Color(0xFFF7F7F9),
                Color(0xFFEDEEF2),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ready-made skeleton row that mimics a card in a list, for use as the
/// loading state of a `ListView` while data is fetched.
class AdminSkeletonCard extends StatelessWidget {
  const AdminSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminSkeletonBox(height: 20, width: 72, borderRadius: BorderRadius.circular(20)),
              const Spacer(),
              AdminSkeletonBox(height: 20, width: 60, borderRadius: BorderRadius.circular(20)),
            ],
          ),
          const SizedBox(height: 14),
          const AdminSkeletonBox(height: 14, width: 180),
          const SizedBox(height: 8),
          const AdminSkeletonBox(height: 12, width: 120),
        ],
      ),
    );
  }
}

class AdminSkeletonList extends StatelessWidget {
  final int count;
  const AdminSkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const AdminSkeletonCard(),
    );
  }
}
