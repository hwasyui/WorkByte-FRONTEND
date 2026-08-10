import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';
import '../models/review_model.dart';
import '../models/client_review_model.dart';
import '../core/utils/text_format.dart';

class TrustScoreCard extends StatelessWidget {
  final TrustScore trustScore;

  final bool isOwnProfile;

  const TrustScoreCard({
    super.key,
    required this.trustScore,
    this.isOwnProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    final score = trustScore.overallScore;

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
          Text(
            'Trust Score',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
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
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            '/100',
                            style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Based on ${trustScore.totalReviews} review${trustScore.totalReviews == 1 ? '' : 's'}, delivery record & communication',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
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
                ? 'Not measured yet - complete a contract with a deadline'
                : null,
          ),
          ScoreBar(
            label: 'Revision Efficiency',
            icon: Icons.schedule_outlined,
            value: trustScore.revisionRateScore,
            nullLabel: isOwnProfile
                ? 'Not measured yet - no revisions recorded'
                : null,
          ),
          ScoreBar(
            label: 'Responsiveness',
            icon: Icons.chat_bubble_outline,
            value: trustScore.responsivenessScore,
            nullLabel: isOwnProfile
                ? 'Not measured yet - respond to messages during an active contract'
                : null,
          ),
          ScoreBar(
            label: 'Communication',
            icon: Icons.sentiment_satisfied_outlined,
            value: trustScore.communicationSentiment,
            nullLabel: isOwnProfile
                ? 'Not measured yet - needs written feedback from a client'
                : null,
          ),
        ],
      ),
    );
  }
}

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
          Text(
            'Trust Score',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
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
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                            ),
                          ),
                          Text(
                            '/100',
                            style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Based on ${trustScore.totalReviewsReceived} review${trustScore.totalReviewsReceived == 1 ? '' : 's'} from freelancers',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
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
                ? 'Not measured yet - respond to messages during an active contract'
                : null,
          ),
          ScoreBar(
            label: 'Communication',
            icon: Icons.sentiment_satisfied_outlined,
            value: trustScore.communicationSentiment,
            nullLabel: isOwnProfile
                ? 'Not measured yet - needs written feedback from a freelancer'
                : null,
          ),
          ScoreBar(
            label: 'Dispute-Free Rate',
            icon: Icons.gavel_outlined,
            value: trustScore.disputeFairnessScore,
            nullLabel: isOwnProfile
                ? 'Not measured yet - no completed contracts with disputes'
                : null,
          ),
        ],
      ),
    );
  }
}

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
              Text(
                'AI Summary',
                style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class SentimentDistributionCard extends StatelessWidget {
  final SentimentDistribution distribution;
  final String confidence;

  const SentimentDistributionCard({
    super.key,
    required this.distribution,
    required this.confidence,
  });

  static const Color _positiveColor = Color(0xFF059669);
  static const Color _neutralColor = Color(0xFF9CA3AF);
  static const Color _negativeColor = Color(0xFFDC2626);
  static const Color _unclassifiedColor = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    final d = distribution;
    if (d.total == 0) return const SizedBox.shrink();

    final showPercent = confidence != 'new';

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
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              // A Spacer gives up before the title does, so the title has to be
              // the flexible one or the pair overflows at large text scales.
              Expanded(
                child: Text(
                  'Review Sentiment',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${d.total} review${d.total == 1 ? '' : 's'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SentimentBar(
            label: 'Positive',
            icon: Icons.sentiment_satisfied_alt_rounded,
            count: d.positive,
            total: d.total,
            color: _positiveColor,
            showPercent: showPercent,
          ),
          _SentimentBar(
            label: 'Neutral',
            icon: Icons.sentiment_neutral_rounded,
            count: d.neutral,
            total: d.total,
            color: _neutralColor,
            showPercent: showPercent,
          ),
          _SentimentBar(
            label: 'Negative',
            icon: Icons.sentiment_dissatisfied_rounded,
            count: d.negative,
            total: d.total,
            color: _negativeColor,
            showPercent: showPercent,
          ),
          if (d.unclassified > 0)
            _SentimentBar(
              label: 'Unclassified',
              icon: Icons.help_outline_rounded,
              count: d.unclassified,
              total: d.total,
              color: _unclassifiedColor,
              showPercent: showPercent,
            ),
          if (!showPercent)
            Text(
              'Too few reviews to show percentages yet',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _SentimentBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final int total;
  final Color color;
  final bool showPercent;

  const _SentimentBar({
    required this.label,
    required this.icon,
    required this.count,
    required this.total,
    required this.color,
    required this.showPercent,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    final isEmpty = count == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isEmpty ? Colors.grey.shade400 : color),
          const SizedBox(width: 8),
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isEmpty ? Colors.grey[400] : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 7,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(
              showPercent ? '${(fraction * 100).round()}% · $count' : '$count',
              textAlign: TextAlign.right,
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isEmpty ? Colors.grey[400] : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final double? value;

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
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            child: v == null
                ? Text(
                    nullLabel ?? 'Not enough data yet',
                    style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
    // Star averages run 1-5, so a zero here means "no published reviews yet"
    // (a null display average coerced to 0.0), not a genuine zero-star score.
    final hasRating = rating > 0;

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
              child: hasRating
                  ? Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      Icons.star_border_rounded,
                      size: 28,
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and badge are both intrinsically sized, and the badge
                // grows with the review count ("Established · 128 reviews"),
                // so a Row overflows on any phone. A Wrap drops the badge onto
                // its own line instead of clipping it.
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Average Rating',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (confidence != null)
                      ConfidenceBadge(
                        confidence: confidence!,
                        totalReviews: totalReviews,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (hasRating) ...[
                  StarRow(rating: rating),
                  const SizedBox(height: 6),
                  Text(
                    'Based on $totalReviews review${totalReviews == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                ] else
                  Text(
                    'No rating yet',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
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
          Text(
            'Rating Breakdown',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold),
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
                      style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
      return toTitleCase(category);
  }
}
