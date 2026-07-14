import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../models/review_model.dart';
import 'review_rating_helpers.dart';

/// A published review with rating chips, comment text, skill tags, and an
/// AI sentiment/authenticity badge when the review carries ai_analysis
/// (requires the freelancer-reviews endpoint to include it - see
/// ReviewFunctions.get_reviews_by_freelancer_id on the backend).
class ReviewCard extends StatelessWidget {
  final Review review;
  final String? reviewerName;
  final String? reviewerAvatarUrl;

  const ReviewCard({
    super.key,
    required this.review,
    this.reviewerName,
    this.reviewerAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = review.isAnonymous
        ? 'Anonymous Client'
        : (reviewerName ?? 'Client');
    final avg = review.ratings.isEmpty
        ? 0.0
        : review.ratings.map((r) => r.score).reduce((a, b) => a + b) /
              review.ratings.length;
    final comment = review.writtenContent?.overallComment ?? '';
    final tags = review.skillTags.take(3).map((t) => t.skillTag).toList();
    final publishedAt = review.publishedAt;

    String timeAgo = '';
    if (publishedAt != null) {
      final diff = DateTime.now().difference(publishedAt);
      if (diff.inDays >= 365) {
        timeAgo = '${(diff.inDays / 365).floor()}y ago';
      } else if (diff.inDays >= 30) {
        timeAgo = '${(diff.inDays / 30).floor()}mo ago';
      } else if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d ago';
      } else {
        timeAgo = 'Today';
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage:
                    (!review.isAnonymous &&
                        reviewerAvatarUrl != null &&
                        reviewerAvatarUrl!.startsWith('http'))
                    ? NetworkImage(reviewerAvatarUrl!)
                    : null,
                child:
                    (!review.isAnonymous &&
                        reviewerAvatarUrl != null &&
                        reviewerAvatarUrl!.startsWith('http'))
                    ? null
                    : Text(
                        review.isAnonymous
                            ? '?'
                            : displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 3),
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (review.aiAnalysis != null) ...[
            const SizedBox(height: 10),
            SentimentBadge(analysis: review.aiAnalysis!),
          ],
          if (review.ratings.isNotEmpty) ...[
            const SizedBox(height: 12),
            ReviewRatingsWrap(ratings: review.ratings),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            ExpandableReviewText(text: comment, primaryColor: AppColors.primary),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small positive/neutral/negative pill backed by the review_ml sentiment
/// classifier's output (ReviewAiAnalysis.sentimentLabel).
class SentimentBadge extends StatelessWidget {
  final ReviewAiAnalysis analysis;

  const SentimentBadge({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String label;

    switch (analysis.sentimentLabel) {
      case 'positive':
        color = const Color(0xFF059669);
        icon = Icons.sentiment_satisfied_alt_rounded;
        label = 'Positive';
        break;
      case 'negative':
        color = const Color(0xFFDC2626);
        icon = Icons.sentiment_dissatisfied_rounded;
        label = 'Negative';
        break;
      default:
        color = const Color(0xFF6B7280);
        icon = Icons.sentiment_neutral_rounded;
        label = 'Neutral';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (analysis.overallPass) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                const Text(
                  'AI-verified',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ReviewRatingsWrap extends StatelessWidget {
  final List<ReviewRating> ratings;

  const ReviewRatingsWrap({super.key, required this.ratings});

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ratings.map((rating) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ratingIcon(rating.category),
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                ratingLabel(rating.category),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                rating.score.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ExpandableReviewText extends StatefulWidget {
  final String text;
  final Color primaryColor;

  const ExpandableReviewText({
    super.key,
    required this.text,
    required this.primaryColor,
  });

  @override
  State<ExpandableReviewText> createState() => _ExpandableReviewTextState();
}

class _ExpandableReviewTextState extends State<ExpandableReviewText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.trim().length > 140;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            height: 1.45,
          ),
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (isLong) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Read less' : 'Read more',
              style: TextStyle(
                color: widget.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// "82% positive · 12% neutral · 6% negative" horizontal bar for a
/// freelancer's public reviews screen, built client-side from the AI
/// sentiment label already attached to each review.
class SentimentDistributionBar extends StatelessWidget {
  final Map<String, int> counts;

  const SentimentDistributionBar({super.key, required this.counts});

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final positive = counts['positive'] ?? 0;
    final neutral = counts['neutral'] ?? 0;
    final negative = counts['negative'] ?? 0;

    Widget segment(int count, Color color) {
      if (count == 0) return const SizedBox.shrink();
      return Expanded(
        flex: count,
        child: Container(height: 8, color: color),
      );
    }

    String pct(int count) => '${(count / total * 100).round()}%';

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
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                segment(positive, const Color(0xFF059669)),
                segment(neutral, const Color(0xFF9CA3AF)),
                segment(negative, const Color(0xFFDC2626)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legend('${pct(positive)} positive', const Color(0xFF059669)),
              _legend('${pct(neutral)} neutral', const Color(0xFF9CA3AF)),
              _legend('${pct(negative)} negative', const Color(0xFFDC2626)),
            ],
          ),
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
