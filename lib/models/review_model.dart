// ── ReviewRating ──────────────────────────────────────────────────────────────

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

// ── ReviewWrittenContent ──────────────────────────────────────────────────────

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

// ── ReviewSkillTag ────────────────────────────────────────────────────────────

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

// ── ReviewAiAnalysis ──────────────────────────────────────────────────────────

class ReviewAiAnalysis {
  final String id;
  final String reviewId;
  final double sentimentScore;
  final String sentimentLabel;
  final bool sentimentMismatch;
  final double authenticityScore;
  final bool isFlaggedFake;
  final bool isFlaggedCoerced;
  final List<String> flagReasons;
  final double biasScore;
  final Map<String, dynamic> biasFlags;
  final bool overallPass;

  const ReviewAiAnalysis({
    required this.id,
    required this.reviewId,
    required this.sentimentScore,
    required this.sentimentLabel,
    required this.sentimentMismatch,
    required this.authenticityScore,
    required this.isFlaggedFake,
    required this.isFlaggedCoerced,
    required this.flagReasons,
    required this.biasScore,
    required this.biasFlags,
    required this.overallPass,
  });

  factory ReviewAiAnalysis.fromJson(Map<String, dynamic> json) =>
      ReviewAiAnalysis(
        id: json['id'] as String? ?? '',
        reviewId: json['review_id'] as String? ?? '',
        sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0.0,
        sentimentLabel: json['sentiment_label'] as String? ?? 'neutral',
        sentimentMismatch: json['sentiment_mismatch'] as bool? ?? false,
        authenticityScore:
            (json['authenticity_score'] as num?)?.toDouble() ?? 1.0,
        isFlaggedFake: json['is_flagged_fake'] as bool? ?? false,
        isFlaggedCoerced: json['is_flagged_coerced'] as bool? ?? false,
        flagReasons:
            (json['flag_reasons'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        biasScore: (json['bias_score'] as num?)?.toDouble() ?? 0.0,
        biasFlags: json['bias_flags'] as Map<String, dynamic>? ?? {},
        overallPass: json['overall_pass'] as bool? ?? true,
      );
}

// ── Review (matches ReviewResponse) ──────────────────────────────────────────

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
  final ReviewAiAnalysis? aiAnalysis;
  final List<String> suggestedSkillTags;

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
    this.aiAnalysis,
    this.suggestedSkillTags = const [],
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
      aiAnalysis: json['ai_analysis'] != null
          ? ReviewAiAnalysis.fromJson(
              json['ai_analysis'] as Map<String, dynamic>,
            )
          : null,
      suggestedSkillTags:
          (json['suggested_skill_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

// ── TrustScore (matches TrustScoreResponse) ───────────────────────────────────

class TrustScore {
  final String freelancerId;
  final double overallScore;
  final double? weightedReviewAvg;
  final double? workQualityScore;
  final double? revisionRateScore;
  final double? responsivenessScore;
  final double? communicationSentiment;
  final int totalReviews;
  final String? category;
  final double? categoryRankPct;
  final DateTime? lastUpdated;

  const TrustScore({
    required this.freelancerId,
    required this.overallScore,
    this.weightedReviewAvg,
    this.workQualityScore,
    this.revisionRateScore,
    this.responsivenessScore,
    this.communicationSentiment,
    required this.totalReviews,
    this.category,
    this.categoryRankPct,
    this.lastUpdated,
  });

  factory TrustScore.fromJson(Map<String, dynamic> json) => TrustScore(
    freelancerId: json['freelancer_id'] as String? ?? '',
    overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
    weightedReviewAvg: (json['weighted_review_avg'] as num?)?.toDouble(),
    workQualityScore: (json['work_quality_score'] as num?)?.toDouble(),
    revisionRateScore: (json['revision_rate_score'] as num?)?.toDouble(),
    responsivenessScore: (json['responsiveness_score'] as num?)?.toDouble(),
    communicationSentiment: (json['communication_sentiment'] as num?)
        ?.toDouble(),
    totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
    category: json['category'] as String?,
    categoryRankPct: (json['category_rank_pct'] as num?)?.toDouble(),
    lastUpdated: json['last_updated'] != null
        ? DateTime.tryParse(json['last_updated'] as String)
        : null,
  );

  /// Converts 0–1 component scores to 0–100 for display.
  double get workQualityDisplay => (workQualityScore ?? 0) * 100;
  double get revisionRateDisplay => (revisionRateScore ?? 0) * 100;
  double get responsivenessDisplay => (responsivenessScore ?? 0) * 100;
  double get communicationDisplay => (communicationSentiment ?? 0) * 100;

  /// e.g. "Top 6%" string from category_rank_pct (percentile from bottom).
  /// Backend returns what % of freelancers score BELOW this freelancer.
  String get rankLabel {
    if (categoryRankPct == null) return '';
    final topPct = (100 - categoryRankPct!).round();
    return 'Top $topPct%';
  }
}

// ── RedFlagAlert (matches RedFlagAlertResponse) ───────────────────────────────

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

// ── SubmitReviewRequest ───────────────────────────────────────────────────────

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
