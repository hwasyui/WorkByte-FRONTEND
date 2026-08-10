import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';

class ReviewSubmittedScreen extends StatefulWidget {
  final String reviewId;
  final String freelancerName;

  const ReviewSubmittedScreen({
    super.key,
    required this.reviewId,
    required this.freelancerName,
  });

  @override
  State<ReviewSubmittedScreen> createState() => _ReviewSubmittedScreenState();
}

class _ReviewSubmittedScreenState extends State<ReviewSubmittedScreen> {
  static const _maxAttempts = 15;
  static const _pollInterval = Duration(seconds: 4);

  String _status = 'pending';
  Timer? _timer;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted || _status != 'pending' || _attempts >= _maxAttempts) {
      _timer?.cancel();
      return;
    }
    _attempts++;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final review = await context.read<ReviewProvider>().fetchReviewById(
      token: token,
      reviewId: widget.reviewId,
    );

    if (!mounted) return;
    if (review != null && review.status != _status) {
      setState(() => _status = review.status);
    }
    if (_status != 'pending' || _attempts >= _maxAttempts) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  _StatusCopy get _copy {
    switch (_status) {
      case 'published':
        return _StatusCopy(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.primary,
          title: 'Review Submitted!',
          subtitle: "Live on ${widget.freelancerName}'s profile.",
        );
      case 'flagged':
        return _StatusCopy(
          icon: Icons.flag_rounded,
          iconColor: Colors.amber.shade700,
          title: 'Review Received',
          subtitle: 'Held for manual review.',
        );
      case 'suppressed':
        return _StatusCopy(
          icon: Icons.block_rounded,
          iconColor: Colors.grey,
          title: 'Review Not Published',
          subtitle: "Didn't pass our checks and won't be published.",
        );
      case 'pending':
      default:
        return _StatusCopy(
          icon: Icons.hourglass_top_rounded,
          iconColor: AppColors.primary,
          title: 'Review Submitted!',
          subtitle: 'Checking your review - usually under a minute.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    final isPending = _status == 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: copy.iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: isPending
                      ? const Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(copy.icon, color: copy.iconColor, size: 56),
                ),
              ),
              const SizedBox(height: 28),

              Text(copy.title, style: AppText.h1, textAlign: TextAlign.center),
              const SizedBox(height: 12),

              Text(
                copy.subtitle,
                style: AppText.body.copyWith(
                  color: Colors.grey[600],
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (isPending)
                const _InfoCard(
                  icon: Icons.auto_awesome,
                  title: 'AI Verification',
                  body:
                      'Our system checks reviews for authenticity before publishing.',
                ),
              if (_status == 'published') ...[
                _InfoCard(
                  icon: Icons.speed_outlined,
                  title: 'Trust Score Update',
                  body:
                      "${widget.freelancerName.split(' ').first}'s trust score has been recalculated.",
                ),
              ],

              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Back to Home',
                    style: AppText.bodySemiBold.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'View My Contracts',
                  style: AppText.body.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCopy {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _StatusCopy({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.captionSemiBold),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppText.caption.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
