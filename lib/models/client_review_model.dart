// Freelancer-reviews-client models - symmetric counterpart to review_model.dart.

// ── ClientReviewRating ────────────────────────────────────────────────────────

class ClientReviewRating {
  final String id;
  final String clientReviewId;
  final String category;
  final double score;

  const ClientReviewRating({
    required this.id,
    required this.clientReviewId,
    required this.category,
    required this.score,
  });

  factory ClientReviewRating.fromJson(Map<String, dynamic> json) =>
      ClientReviewRating(
        id: json['id'] as String? ?? '',
        clientReviewId: json['client_review_id'] as String? ?? '',
        category: json['category'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {'category': category, 'score': score};
}

// ── ClientReviewWrittenContent ────────────────────────────────────────────────

class ClientReviewWrittenContent {
  final String id;
  final String clientReviewId;
  final String? aiQuestion;
  final String? freelancerAnswer;
  final String? overallComment;

  const ClientReviewWrittenContent({
    required this.id,
    required this.clientReviewId,
    this.aiQuestion,
    this.freelancerAnswer,
    this.overallComment,
  });

  factory ClientReviewWrittenContent.fromJson(Map<String, dynamic> json) =>
      ClientReviewWrittenContent(
        id: json['id'] as String? ?? '',
        clientReviewId: json['client_review_id'] as String? ?? '',
        aiQuestion: json['ai_question'] as String?,
        freelancerAnswer: json['freelancer_answer'] as String?,
        overallComment: json['overall_comment'] as String?,
      );
}

// ── ClientReviewAiAnalysis ────────────────────────────────────────────────────

class ClientReviewAiAnalysis {
  final String id;
  final String clientReviewId;
  final double sentimentScore;
  final String sentimentLabel;
  final bool sentimentMismatch;
  final double? mismatchSeverity;
  final double authenticityScore;
  final bool isFlaggedFake;
  final bool isFlaggedCoerced;
  final List<String> flagReasons;
  final bool overallPass;

  const ClientReviewAiAnalysis({
    required this.id,
    required this.clientReviewId,
    required this.sentimentScore,
    required this.sentimentLabel,
    required this.sentimentMismatch,
    this.mismatchSeverity,
    required this.authenticityScore,
    required this.isFlaggedFake,
    required this.isFlaggedCoerced,
    required this.flagReasons,
    required this.overallPass,
  });

  factory ClientReviewAiAnalysis.fromJson(Map<String, dynamic> json) =>
      ClientReviewAiAnalysis(
        id: json['id'] as String? ?? '',
        clientReviewId: json['client_review_id'] as String? ?? '',
        sentimentScore: (json['sentiment_score'] as num?)?.toDouble() ?? 0.0,
        sentimentLabel: json['sentiment_label'] as String? ?? 'neutral',
        sentimentMismatch: json['sentiment_mismatch'] as bool? ?? false,
        mismatchSeverity: (json['mismatch_severity'] as num?)?.toDouble(),
        authenticityScore:
            (json['authenticity_score'] as num?)?.toDouble() ?? 1.0,
        isFlaggedFake: json['is_flagged_fake'] as bool? ?? false,
        isFlaggedCoerced: json['is_flagged_coerced'] as bool? ?? false,
        flagReasons:
            (json['flag_reasons'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        overallPass: json['overall_pass'] as bool? ?? true,
      );
}

// ── ClientReview ──────────────────────────────────────────────────────────────

class ClientReview {
  final String id;
  final String contractId;
  final String reviewerId; // freelancer's user_id
  final String clientId; // client's user_id (being reviewed)
  final String status;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? publishedAt;

  final List<ClientReviewRating> ratings;
  final ClientReviewWrittenContent? writtenContent;
  final ClientReviewAiAnalysis? aiAnalysis;

  const ClientReview({
    required this.id,
    required this.contractId,
    required this.reviewerId,
    required this.clientId,
    required this.status,
    required this.isAnonymous,
    this.createdAt,
    this.publishedAt,
    this.ratings = const [],
    this.writtenContent,
    this.aiAnalysis,
  });

  factory ClientReview.fromJson(Map<String, dynamic> json) {
    return ClientReview(
      id: json['id'] as String? ?? '',
      contractId: json['contract_id'] as String? ?? '',
      reviewerId: json['reviewer_id'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
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
              ?.map(
                (e) => ClientReviewRating.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      writtenContent: json['written_content'] != null
          ? ClientReviewWrittenContent.fromJson(
              json['written_content'] as Map<String, dynamic>,
            )
          : null,
      aiAnalysis: json['ai_analysis'] != null
          ? ClientReviewAiAnalysis.fromJson(
              json['ai_analysis'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

// ── ClientTrustScore ───────────────────────────────────────────────────────────

class ClientTrustScore {
  final String clientId;
  final double trustScore;
  final double? weightedReviewAvgReceived;
  final double? responsivenessScore;
  final double? communicationSentiment;
  final double? authenticityConfidence;
  final double? consistencyScore;
  final double? disputeFairnessScore;
  final int totalReviewsReceived;

  const ClientTrustScore({
    required this.clientId,
    required this.trustScore,
    this.weightedReviewAvgReceived,
    this.responsivenessScore,
    this.communicationSentiment,
    this.authenticityConfidence,
    this.consistencyScore,
    this.disputeFairnessScore,
    required this.totalReviewsReceived,
  });

  factory ClientTrustScore.fromJson(Map<String, dynamic> json) =>
      ClientTrustScore(
        clientId: json['client_id'] as String? ?? '',
        trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0.0,
        weightedReviewAvgReceived:
            (json['weighted_review_avg_received'] as num?)?.toDouble(),
        responsivenessScore: (json['responsiveness_score'] as num?)
            ?.toDouble(),
        communicationSentiment: (json['communication_sentiment'] as num?)
            ?.toDouble(),
        authenticityConfidence: (json['authenticity_confidence'] as num?)
            ?.toDouble(),
        consistencyScore: (json['consistency_score'] as num?)?.toDouble(),
        disputeFairnessScore: (json['dispute_fairness_score'] as num?)
            ?.toDouble(),
        totalReviewsReceived:
            (json['total_reviews_received'] as num?)?.toInt() ?? 0,
      );

  double get responsivenessDisplay => (responsivenessScore ?? 0) * 100;
  double get communicationDisplay => (communicationSentiment ?? 0) * 100;
  double get authenticityDisplay => (authenticityConfidence ?? 0) * 100;
  double get consistencyDisplay => (consistencyScore ?? 0) * 100;
  double get disputeFairnessDisplay => (disputeFairnessScore ?? 0) * 100;
}

// ── SubmitClientReviewRequest ──────────────────────────────────────────────────

class SubmitClientReviewRequest {
  final List<ClientReviewRatingInput> ratings;
  final String freelancerAnswer;
  final String overallComment;

  const SubmitClientReviewRequest({
    required this.ratings,
    required this.freelancerAnswer,
    required this.overallComment,
  });

  Map<String, dynamic> toJson() => {
    'ratings': ratings.map((r) => r.toJson()).toList(),
    'freelancer_answer': freelancerAnswer,
    'overall_comment': overallComment,
  };
}

class ClientReviewRatingInput {
  final String category;
  final double score;

  const ClientReviewRatingInput({required this.category, required this.score});

  Map<String, dynamic> toJson() => {'category': category, 'score': score};
}
