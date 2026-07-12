import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../models/review_model.dart';

/// Mirrors the backend's _REVIEW_LABEL_NAMES map (review_routes.py /
/// client_review_routes.py) so the raw ML labels in
/// ReviewServiceException.detectedLabels display the same human wording
/// the backend already puts in its error message.
String moderationLabel(String raw) {
  switch (raw) {
    case 'toxic':
    case 'toxicity':
      return 'Toxicity';
    case 'obscene':
      return 'Obscenity';
    case 'threat':
      return 'Threats';
    case 'insult':
      return 'Insults';
    case 'identity_hate':
      return 'Identity-based hate speech';
    default:
      return raw.replaceAll('_', ' ');
  }
}

/// Shown instead of a plain error snackbar when a review submission is
/// rejected by the harmful-content gate (_reject_review_text_if_harmful /
/// _reject_client_review_text_if_harmful) - the flagged categories are
/// surfaced as chips so the client/freelancer knows exactly what to revise,
/// rather than reading a raw "submitReview failed (400): ..." string.
Future<void> showReviewFlaggedDialog(
  BuildContext context, {
  required List<String> rawLabels,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gpp_bad_rounded,
                color: Colors.red.shade400,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Review Not Submitted',
              style: AppText.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Our automatic safety check flagged language in your review before it reached anyone. Please revise it and try again.',
              style: AppText.body.copyWith(color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (rawLabels.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: rawLabels.map((raw) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      moderationLabel(raw),
                      style: AppText.captionSemiBold.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Edit Review',
                  style: AppText.bodySemiBold.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String ratingLabel(String category) {
  switch (category) {
    case 'communication':
      return 'Communication';
    case 'quality':
      return 'Quality';
    case 'professionalism':
      return 'Professionalism';
    case 'value_for_money':
      return 'Value for money';
    case 'clarity_of_requirements':
      return 'Clarity of Requirements';
    case 'responsiveness':
      return 'Responsiveness';
    default:
      return category.replaceAll('_', ' ');
  }
}

IconData ratingIcon(String category) {
  switch (category) {
    case 'communication':
      return Icons.chat_bubble_outline;
    case 'quality':
      return Icons.workspace_premium_outlined;
    case 'professionalism':
      return Icons.badge_outlined;
    case 'value_for_money':
      return Icons.payments_outlined;
    case 'clarity_of_requirements':
      return Icons.fact_check_outlined;
    case 'responsiveness':
      return Icons.bolt_outlined;
    default:
      return Icons.star_outline;
  }
}

Map<String, double> buildCategoryAverages(List<Review> reviews) {
  final totals = <String, double>{};
  final counts = <String, int>{};

  for (final review in reviews) {
    for (final rating in review.ratings) {
      totals[rating.category] = (totals[rating.category] ?? 0) + rating.score;
      counts[rating.category] = (counts[rating.category] ?? 0) + 1;
    }
  }

  return totals.map((key, total) {
    final count = counts[key] ?? 1;
    return MapEntry(key, total / count);
  });
}

/// {positive: n, neutral: n, negative: n} across reviews that carry AI
/// sentiment analysis (older reviews fetched before this field existed
/// won't have it, so counts only reflect reviews with aiAnalysis present).
Map<String, int> buildSentimentDistribution(List<Review> reviews) {
  final counts = {'positive': 0, 'neutral': 0, 'negative': 0};
  for (final review in reviews) {
    final label = review.aiAnalysis?.sentimentLabel;
    if (label != null && counts.containsKey(label)) {
      counts[label] = counts[label]! + 1;
    }
  }
  return counts;
}
