import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

/// Shared loading state for the job post flow screens (Job Detail, Roles,
/// Attachments). Shown in place of the screen's content while its draft
/// data (step progress, saved roles, saved files) is being fetched, so the
/// screen never flashes stale/default content before swapping to the real
/// data a moment later.
class PostJobLoadingView extends StatelessWidget {
  final String label;

  const PostJobLoadingView({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
