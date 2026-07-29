// ReviewRating

class ReviewRating {
  final String id;
  final String reviewId;
  final String category;
  final double score;

  const ReviewRating({
    required this.id,
    required this.reviewId,
    required this.category,
    required this.score,
  });

  factory ReviewRating.fromJson(Map<String, dynamic> json) => ReviewRating(
    id: json['id'] as String? ?? '',
    reviewId: json['review_id'] as String? ?? '',
    category: json['category'] as String? ?? '',
    score: (json['score'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {'category': category, 'score': score};
}

// ReviewWrittenContent

class ReviewWrittenContent {
  final String id;
  final String reviewId;
  final String? aiQuestion;
  final String? clientAnswer;
  final String? overallComment;

  const ReviewWrittenContent({
    required this.id,
    required this.reviewId,
    this.aiQuestion,
    this.clientAnswer,
    this.overallComment,
  });

  factory ReviewWrittenContent.fromJson(Map<String, dynamic> json) =>
      ReviewWrittenContent(
        id: json['id'] as String? ?? '',
        reviewId: json['review_id'] as String? ?? '',
        aiQuestion: json['ai_question'] as String?,
        clientAnswer: json['client_answer'] as String?,
        overallComment: json['overall_comment'] as String?,
      );
}

// ReviewSkillTag

class ReviewSkillTag {
  final String id;
  final String reviewId;
  final String skillTag;
  final bool isAiSuggested;

  const ReviewSkillTag({
    required this.id,
    required this.reviewId,
    required this.skillTag,
    required this.isAiSuggested,
  });

  factory ReviewSkillTag.fromJson(Map<String, dynamic> json) => ReviewSkillTag(
    id: json['id'] as String? ?? '',
    reviewId: json['review_id'] as String? ?? '',
    skillTag: json['skill_tag'] as String? ?? '',
    isAiSuggested: json['is_ai_suggested'] as bool? ?? false,
  );
}

// Review (matches ReviewResponse)

class Review {
  final String id;
  final String contractId;
  final String reviewerId;
  final String freelancerId;
  final String inferredCategory;
  final String status;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? publishedAt;

  // DetailResponse extras
  final List<ReviewRating> ratings;
  final ReviewWrittenContent? writtenContent;
  final List<ReviewSkillTag> skillTags;
  final List<String> suggestedSkillTags;

  /// "positive" | "neutral" | "negative" | null. Null means no sentiment
  /// analysis exists for this review (AI outage at submit time, or an older
  /// row) — distinct from a measured "neutral", so it must never be defaulted.
  final String? sentiment;

  const Review({
    required this.id,
    required this.contractId,
    required this.reviewerId,
    required this.freelancerId,
    required this.inferredCategory,
    required this.status,
    required this.isAnonymous,
    this.createdAt,
    this.publishedAt,
    this.ratings = const [],
    this.writtenContent,
    this.skillTags = const [],
    this.suggestedSkillTags = const [],
    this.sentiment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      contractId: json['contract_id'] as String? ?? '',
      reviewerId: json['reviewer_id'] as String? ?? '',
      freelancerId: json['freelancer_id'] as String? ?? '',
      inferredCategory: json['inferred_category'] as String? ?? 'general',
      status: json['status'] as String? ?? 'pending',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      ratings:
          (json['ratings'] as List<dynamic>?)
              ?.map((e) => ReviewRating.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      writtenContent: json['written_content'] != null
          ? ReviewWrittenContent.fromJson(
              json['written_content'] as Map<String, dynamic>,
            )
          : null,
      skillTags:
          (json['skill_tags'] as List<dynamic>?)
              ?.map((e) => ReviewSkillTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestedSkillTags:
          (json['suggested_skill_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sentiment: json['sentiment'] as String?,
    );
  }
}

// SentimentDistribution (matches SentimentDistributionResponse)
//
// Shared between the freelancer and client trust-score responses - counts
// cover published reviews only, and the four categories always sum to total.

class SentimentDistribution {
  final int positive;
  final int neutral;
  final int negative;
  final int unclassified;
  final int total;

  const SentimentDistribution({
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.unclassified,
    required this.total,
  });

  /// Handles both the full trust-score shape and the "no reviews yet" shape
  /// (where sentiment_distribution is still present, every count just 0).
  factory SentimentDistribution.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SentimentDistribution(
        positive: 0,
        neutral: 0,
        negative: 0,
        unclassified: 0,
        total: 0,
      );
    }
    return SentimentDistribution(
      positive: (json['positive'] as num?)?.toInt() ?? 0,
      neutral: (json['neutral'] as num?)?.toInt() ?? 0,
      negative: (json['negative'] as num?)?.toInt() ?? 0,
      unclassified: (json['unclassified'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

// TrustScore (matches TrustScoreResponse)

class TrustScore {
  final String freelancerId;
  final double overallScore;
  final double? displayStarAvg;
  final double? onTimeScore;
  final double? revisionRateScore;
  final double? responsivenessScore;
  final double? communicationSentiment;
  final String confidence;
  final int totalReviews;
  final String? category;
  final double? categoryRankPct;
  final DateTime? lastUpdated;
  final String? aiReviewSummary;
  final String? message;
  final SentimentDistribution sentimentDistribution;

  const TrustScore({
    required this.freelancerId,
    required this.overallScore,
    this.displayStarAvg,
    this.onTimeScore,
    this.revisionRateScore,
    this.responsivenessScore,
    this.communicationSentiment,
    required this.confidence,
    required this.totalReviews,
    this.category,
    this.categoryRankPct,
    this.lastUpdated,
    this.aiReviewSummary,
    this.message,
    required this.sentimentDistribution,
  });

  factory TrustScore.fromJson(Map<String, dynamic> json) => TrustScore(
    freelancerId: json['freelancer_id'] as String? ?? '',
    overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
    displayStarAvg: (json['display_star_avg'] as num?)?.toDouble(),
    onTimeScore: (json['on_time_score'] as num?)?.toDouble(),
    revisionRateScore: (json['revision_rate_score'] as num?)?.toDouble(),
    responsivenessScore: (json['responsiveness_score'] as num?)?.toDouble(),
    communicationSentiment: (json['communication_sentiment'] as num?)
        ?.toDouble(),
    confidence: json['confidence'] as String? ?? 'new',
    totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
    category: json['category'] as String?,
    categoryRankPct: (json['category_rank_pct'] as num?)?.toDouble(),
    lastUpdated: json['last_updated'] != null
        ? DateTime.tryParse(json['last_updated'] as String)
        : null,
    aiReviewSummary: json['ai_review_summary'] as String?,
    message: json['message'] as String?,
    sentimentDistribution: SentimentDistribution.fromJson(
      json['sentiment_distribution'] as Map<String, dynamic>?,
    ),
  );

  /// e.g. "Top 6%" string from category_rank_pct (percentile from bottom).
  /// Backend returns what % of freelancers score BELOW this freelancer.
  String get rankLabel {
    if (categoryRankPct == null) return '';
    final topPct = (100 - categoryRankPct!).round();
    return 'Top $topPct%';
  }
}

// RedFlagAlert (matches RedFlagAlertResponse)

class RedFlagAlert {
  final String id;
  final String freelancerId;
  final String alertType;
  final String severity;
  final String message;
  final bool isResolved;
  final DateTime? triggeredAt;

  const RedFlagAlert({
    required this.id,
    required this.freelancerId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.isResolved,
    this.triggeredAt,
  });

  factory RedFlagAlert.fromJson(Map<String, dynamic> json) => RedFlagAlert(
    id: json['id'] as String? ?? '',
    freelancerId: json['freelancer_id'] as String? ?? '',
    alertType: json['alert_type'] as String? ?? '',
    severity: json['severity'] as String? ?? 'low',
    message: json['message'] as String? ?? '',
    isResolved: json['is_resolved'] as bool? ?? false,
    triggeredAt: json['triggered_at'] != null
        ? DateTime.tryParse(json['triggered_at'] as String)
        : null,
  );
}

// SubmitReviewRequest

class SubmitReviewRequest {
  final List<ReviewRatingInput> ratings;
  final String clientAnswer;
  final String overallComment;
  final List<String> extraSkillTags;

  const SubmitReviewRequest({
    required this.ratings,
    required this.clientAnswer,
    required this.overallComment,
    this.extraSkillTags = const [],
  });

  Map<String, dynamic> toJson() => {
    'ratings': ratings.map((r) => r.toJson()).toList(),
    'client_answer': clientAnswer,
    'overall_comment': overallComment,
    'extra_skill_tags': extraSkillTags,
  };
}

class ReviewRatingInput {
  final String category;
  final double score;

  const ReviewRatingInput({required this.category, required this.score});

  Map<String, dynamic> toJson() => {'category': category, 'score': score};
}
