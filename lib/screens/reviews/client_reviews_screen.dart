import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/client_review_provider.dart';
import '../../models/client_review_model.dart';
import '../../widgets/review_rating_helpers.dart';
import '../../widgets/trust_score_card.dart' show ScoreBar, StarRow;

/// Public reviews + trust score screen for a client, reached from the
/// discovery/people-list flow. Symmetric counterpart to
/// FreelancerReviewsScreen, backed by ClientReviewProvider/ClientReview types
/// instead of the freelancer-side widgets (which are typed to Review/TrustScore).
class ClientReviewsScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientReviewsScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientReviewsScreen> createState() => _ClientReviewsScreenState();
}

class _ClientReviewsScreenState extends State<ClientReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<ClientReviewProvider>();
    await Future.wait([
      provider.loadClientReviews(token: token, clientId: widget.clientId),
      provider.loadTrustScore(token: token, clientId: widget.clientId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Reviews for ${widget.clientName}'),
      ),
      body: Consumer<ClientReviewProvider>(
        builder: (context, provider, _) {
          final isLoading =
              provider.reviewsState == ClientReviewLoadState.loading ||
              provider.trustState == ClientReviewLoadState.loading;

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final reviews = provider.reviews;
          final trustScore = provider.trustScore;
          final totalReviews =
              trustScore?.totalReviewsReceived ?? reviews.length;

          if (totalReviews == 0 && reviews.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rate_review, color: Colors.grey[400], size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (trustScore != null) ...[
                    _buildRatingSummary(trustScore, totalReviews),
                    const SizedBox(height: 16),
                    _buildTrustScoreCard(trustScore, totalReviews),
                    const SizedBox(height: 16),
                  ],
                  if (reviews.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Reviews',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$totalReviews total',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...reviews.map(_buildReviewCard),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingSummary(ClientTrustScore trustScore, int totalReviews) {
    final rating = (trustScore.weightedReviewAvgReceived ?? 0.0).clamp(
      0.0,
      5.0,
    );
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
                const Text(
                  'Average Rating',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                StarRow(rating: rating),
                const SizedBox(height: 6),
                Text(
                  'Based on $totalReviews review${totalReviews == 1 ? '' : 's'} from freelancers',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustScoreCard(ClientTrustScore trustScore, int totalReviews) {
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
                      'Based on $totalReviews review${totalReviews == 1 ? '' : 's'} from freelancers',
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
          ),
          ScoreBar(
            label: 'Dispute-Free Rate',
            icon: Icons.gavel_outlined,
            value: trustScore.disputeFairnessScore,
          ),
          ScoreBar(
            label: 'Communication',
            icon: Icons.sentiment_satisfied_outlined,
            value: trustScore.communicationSentiment,
          ),
          ScoreBar(
            label: 'Review Authenticity',
            icon: Icons.verified_outlined,
            value: trustScore.authenticityConfidence,
          ),
          ScoreBar(
            label: 'Rating Consistency',
            icon: Icons.balance_outlined,
            value: trustScore.consistencyScore,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ClientReview review) {
    final avg = review.ratings.isEmpty
        ? 0.0
        : review.ratings.map((r) => r.score).reduce((a, b) => a + b) /
              review.ratings.length;
    final comment = review.writtenContent?.overallComment ?? '';

    String timeAgo = '';
    final publishedAt = review.publishedAt;
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
                child: Text(
                  review.isAnonymous ? '?' : 'F',
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
                      review.isAnonymous ? 'Anonymous Freelancer' : 'Freelancer',
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
          if (review.ratings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.ratings.map((rating) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
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
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
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
            ),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
