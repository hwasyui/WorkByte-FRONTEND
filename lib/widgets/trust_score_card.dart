import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../models/review_model.dart';
import '../models/client_review_model.dart';

/// Trust score card - every sub-score shown here is a named, weighted input
/// to the backend's calculate_trust_score, not just a decorative breakdown.
/// See ai_related/review_analysis/review_ai_functions.py on the backend.
class TrustScoreCard extends StatelessWidget {
  final TrustScore trustScore;

  /// When true (the subject viewing their own profile), null components show
  /// actionable copy on how to earn that signal instead of a generic message.
  final bool isOwnProfile;

  const TrustScoreCard({
    super.key,
    required this.trustScore,
    this.isOwnProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    final score = trustScore.overallScore;
    final rankPct = trustScore.categoryRankPct;
    final category = trustScore.category?.replaceAll('_', ' ') ?? '';

    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = AppColors.primary;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.amber.shade700;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red.shade400;
      scoreLabel = 'Needs Work';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ConfidenceBadge(
                confidence: trustScore.confidence,
                totalReviews: trustScore.totalReviews,
              ),
              if (rankPct != null && category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Top ${(100 - rankPct).toStringAsFixed(0)}% in $category',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(scoreColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            score.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Based on ${trustScore.totalReviews} review${trustScore.totalReviews == 1 ? '' : 's'}, delivery record & communication',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ScoreBar(
            label: 'On-Time Delivery',
            icon: Icons.event_available_outlined,
            value: trustScore.onTimeScore,
            nullLabel: isOwnProfile
                ? 'Not measured yet — complete a contract with a deadline'
                : null,
          ),
          ScoreBar(
            label: 'Revision Efficiency',
            icon: Icons.schedule_outlined,
            value: trustScore.revisionRateScore,
            nullLabel: isOwnProfile
                ? 'Not measured yet — no revisions recorded'
                : null,
          ),
          ScoreBar(
            label: 'Responsiveness',
            icon: Icons.chat_bubble_outline,
            value: trustScore.responsivenessScore,
            nullLabel: isOwnProfile
                ? 'Not measured yet — respond to messages during an active contract'
                : null,
          ),
          ScoreBar(
            label: 'Communication',
            icon: Icons.sentiment_satisfied_outlined,
            value: trustScore.communicationSentiment,
            nullLabel: isOwnProfile
                ? 'Not measured yet — needs written feedback from a client'
                : null,
          ),
        ],
      ),
    );
  }
}

/// Client-side counterpart to [TrustScoreCard] for [ClientTrustScore] - clients
/// have no on-time/revision-rate signals and dispute_fairness_score is only
/// surfaced when it's actually below perfect (otherwise it's noise on every
/// profile, since nearly every client scores 1.0 or has no disputes at all).
class ClientTrustScoreCard extends StatelessWidget {
  final ClientTrustScore trustScore;
  final bool isOwnProfile;

  const ClientTrustScoreCard({
    super.key,
    required this.trustScore,
    this.isOwnProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    final score = trustScore.trustScore;
    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = AppColors.primary;
      scoreLabel = 'Excellent';
    } else if (score >= 60) {
      scoreColor = Colors.amber.shade700;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red.shade400;
      scoreLabel = 'Needs Work';
    }

    final dispute = trustScore.disputeFairnessScore;
    final showDispute = dispute != null && dispute < 1.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConfidenceBadge(
            confidence: trustScore.confidence,
            totalReviews: trustScore.totalReviewsReceived,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(scoreColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            score.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Based on ${trustScore.totalReviewsReceived} review${trustScore.totalReviewsReceived == 1 ? '' : 's'} from freelancers',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ScoreBar(
            label: 'Responsiveness',
            icon: Icons.bolt_outlined,
            value: trustScore.responsivenessScore,
            nullLabel: isOwnProfile
                ? 'Not measured yet — respond to messages during an active contract'
                : null,
          ),
          ScoreBar(
            label: 'Communication',
            icon: Icons.sentiment_satisfied_outlined,
            value: trustScore.communicationSentiment,
            nullLabel: isOwnProfile
                ? 'Not measured yet — needs written feedback from a freelancer'
                : null,
          ),
          if (showDispute)
            ScoreBar(
              label: 'Dispute-Free Rate',
              icon: Icons.gavel_outlined,
              value: dispute,
            ),
        ],
      ),
    );
  }
}

/// AI-generated blurb summarising a freelancer/client's review history -
/// backed by ai_review_summary on freelancer_trust_scores / client_trust_score
/// (see generate_freelancer_review_summary / generate_client_review_summary
/// on the backend). Styled distinctly (gradient + sparkle) from the plain
/// white cards around it to read as generated content, not a raw stat.
class AiReviewSummaryCard extends StatelessWidget {
  final String? summary;

  const AiReviewSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final text = summary?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.55),
            AppColors.primary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Summary',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textDark.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill making the sample size behind a score visible at a glance -
/// "new" (0-2 reviews) is called out explicitly rather than shown as a bare
/// number, since a single 5-star review shouldn't read as an established
/// track record.
class ConfidenceBadge extends StatelessWidget {
  final String confidence;
  final int totalReviews;

  const ConfidenceBadge({
    super.key,
    required this.confidence,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (confidence) {
      case 'new':
        label = 'New';
        color = Colors.blueGrey;
        break;
      case 'building':
        label = 'Building · $totalReviews review${totalReviews == 1 ? '' : 's'}';
        color = Colors.amber.shade700;
        break;
      case 'established':
      default:
        label =
            'Established · $totalReviews review${totalReviews == 1 ? '' : 's'}';
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Profile-level sentiment mix from a trust score's `sentiment_distribution`.
/// Below the "new" confidence threshold (0-2 reviews) a proportional bar would
/// misrepresent a tiny sample as a verdict (e.g. "50% negative" from one bad
/// review out of two) - raw counts are shown instead, and nothing at all when
/// there are no reviews yet.
class SentimentDistributionCard extends StatelessWidget {
  final SentimentDistribution distribution;
  final String confidence;

  const SentimentDistributionCard({
    super.key,
    required this.distribution,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final d = distribution;
    if (d.total == 0) return const SizedBox.shrink();

    final showChart = confidence != 'new';

    Widget segment(int count, Color color) {
      if (count == 0) return const SizedBox.shrink();
      return Expanded(flex: count, child: Container(height: 8, color: color));
    }

    String pct(int count) => '${(count / d.total * 100).round()}%';

    final legends = <Widget>[
      if (d.positive > 0)
        _legend(
          showChart ? '${pct(d.positive)} positive' : '${d.positive} positive',
          const Color(0xFF059669),
        ),
      if (d.neutral > 0)
        _legend(
          showChart ? '${pct(d.neutral)} neutral' : '${d.neutral} neutral',
          const Color(0xFF9CA3AF),
        ),
      if (d.negative > 0)
        _legend(
          showChart ? '${pct(d.negative)} negative' : '${d.negative} negative',
          const Color(0xFFDC2626),
        ),
      if (d.unclassified > 0)
        _legend(
          showChart
              ? '${pct(d.unclassified)} unclassified'
              : '${d.unclassified} unclassified',
          const Color(0xFFD1D5DB),
        ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Sentiment',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (showChart) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    segment(d.positive, const Color(0xFF059669)),
                    segment(d.neutral, const Color(0xFF9CA3AF)),
                    segment(d.negative, const Color(0xFFDC2626)),
                    segment(d.unclassified, const Color(0xFFD1D5DB)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(spacing: 14, runSpacing: 6, children: legends),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class ScoreBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double? value;

  /// Shown in place of the bar when [value] is null. Nulls are always
  /// meaningful ("not enough data"), never coerced to a 0%-filled bar.
  final String? nullLabel;

  const ScoreBar({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    this.nullLabel,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey[500]),
          const SizedBox(width: 6),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            child: v == null
                ? Text(
                    nullLabel ?? 'Not enough data yet',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: v.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
          ),
          if (v != null) ...[
            const SizedBox(width: 6),
            Text(
              '${(v.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  final double rating;

  const StarRow({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        IconData icon;

        if (rating >= starValue) {
          icon = Icons.star_rounded;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }

        return Icon(icon, size: 18, color: Colors.amber.shade700);
      }),
    );
  }
}

class RatingSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;

  /// Optional — when supplied, a [ConfidenceBadge] is shown next to the
  /// title so the headline rating never appears without its sample size.
  final String? confidence;

  const RatingSummaryCard({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final rating = averageRating.clamp(0.0, 5.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Average Rating',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (confidence != null) ...[
                      const SizedBox(width: 8),
                      ConfidenceBadge(
                        confidence: confidence!,
                        totalReviews: totalReviews,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                StarRow(rating: rating),
                const SizedBox(height: 6),
                Text(
                  'Based on $totalReviews review${totalReviews == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryRatingsCard extends StatelessWidget {
  final Map<String, double> categoryAverages;

  const CategoryRatingsCard({super.key, required this.categoryAverages});

  @override
  Widget build(BuildContext context) {
    if (categoryAverages.isEmpty) return const SizedBox.shrink();

    final orderedKeys = [
      'communication',
      'quality',
      'professionalism',
      'value_for_money',
      'timeliness',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Breakdown',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...orderedKeys.where(categoryAverages.containsKey).map((key) {
            final value = categoryAverages[key]!.clamp(0.0, 5.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(ratingIconFor(key), size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: Text(
                      ratingLabelFor(key),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value / 5.0,
                        minHeight: 7,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Re-exported under local names to avoid a circular naming clash with
// review_rating_helpers.dart's top-level ratingIcon/ratingLabel when both
// are imported into the same file.
IconData ratingIconFor(String category) {
  switch (category) {
    case 'communication':
      return Icons.chat_bubble_outline;
    case 'quality':
      return Icons.workspace_premium_outlined;
    case 'professionalism':
      return Icons.badge_outlined;
    case 'value_for_money':
      return Icons.payments_outlined;
    case 'timeliness':
      return Icons.schedule_outlined;
    default:
      return Icons.star_outline;
  }
}

String ratingLabelFor(String category) {
  switch (category) {
    case 'communication':
      return 'Communication';
    case 'quality':
      return 'Quality';
    case 'professionalism':
      return 'Professionalism';
    case 'value_for_money':
      return 'Value for money';
    case 'timeliness':
      return 'Timeliness';
    default:
      return category.replaceAll('_', ' ');
  }
}
