import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/review_card.dart';
import '../../widgets/review_rating_helpers.dart';
import '../../widgets/trust_score_card.dart';

/// Public reviews + trust score screen for a freelancer, reached from the
/// discovery/people-list flow (PeopleProfileScreen). Previously there was no
/// way for a client to read a freelancer's reviews before hiring - the only
/// place written reviews displayed was the freelancer's own self-view profile.
class FreelancerReviewsScreen extends StatefulWidget {
  final String freelancerId;
  final String freelancerName;

  const FreelancerReviewsScreen({
    super.key,
    required this.freelancerId,
    required this.freelancerName,
  });

  @override
  State<FreelancerReviewsScreen> createState() =>
      _FreelancerReviewsScreenState();
}

class _FreelancerReviewsScreenState extends State<FreelancerReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final reviewProvider = context.read<ReviewProvider>();
    await Future.wait([
      reviewProvider.loadFreelancerReviews(
        token: token,
        freelancerId: widget.freelancerId,
      ),
      reviewProvider.loadTrustScore(
        token: token,
        freelancerId: widget.freelancerId,
      ),
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
        title: Text('Reviews for ${widget.freelancerName}'),
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, reviewProvider, _) {
          final isLoading =
              reviewProvider.reviewsState == ReviewLoadState.loading ||
              reviewProvider.trustState == ReviewLoadState.loading;

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final reviews = reviewProvider.reviews;
          final trustScore = reviewProvider.trustScore;
          final double averageRating =
              trustScore?.displayStarAvg ?? trustScore?.weightedReviewAvg ?? 0.0;
          final int totalReviews = trustScore?.totalReviews ?? reviews.length;
          final categoryAverages = buildCategoryAverages(reviews);

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
                  if (totalReviews > 0) ...[
                    RatingSummaryCard(
                      averageRating: averageRating,
                      totalReviews: totalReviews,
                    ),
                    const SizedBox(height: 16),
                    CategoryRatingsCard(categoryAverages: categoryAverages),
                    const SizedBox(height: 16),
                    SentimentDistributionBar(
                      counts: buildSentimentDistribution(reviews),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (trustScore != null) ...[
                    TrustScoreCard(trustScore: trustScore),
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
                    ...reviews.map((r) => ReviewCard(review: r)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
