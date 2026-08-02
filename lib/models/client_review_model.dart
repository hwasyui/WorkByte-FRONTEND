
import 'review_model.dart' show SentimentDistribution;

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

class ClientReview {
  final String id;
  final String contractId;
  final String reviewerId;
  final String clientId;
  final String status;
  final bool isAnonymous;
  final DateTime? createdAt;
  final DateTime? publishedAt;

  final List<ClientReviewRating> ratings;
  final ClientReviewWrittenContent? writtenContent;

  final String? sentiment;

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
    this.sentiment,
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
      sentiment: json['sentiment'] as String?,
    );
  }
}

class ClientTrustScore {
  final String clientId;
  final double trustScore;
  final double? weightedReviewAvgReceived;
  final double? responsivenessScore;
  final double? communicationSentiment;
  final double? disputeFairnessScore;
  final String confidence;
  final int totalReviewsReceived;
  final String? aiReviewSummary;
  final String? message;
  final SentimentDistribution sentimentDistribution;

  const ClientTrustScore({
    required this.clientId,
    required this.trustScore,
    this.weightedReviewAvgReceived,
    this.responsivenessScore,
    this.communicationSentiment,
    this.disputeFairnessScore,
    required this.confidence,
    required this.totalReviewsReceived,
    this.aiReviewSummary,
    this.message,
    required this.sentimentDistribution,
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
        disputeFairnessScore: (json['dispute_fairness_score'] as num?)
            ?.toDouble(),
        confidence: json['confidence'] as String? ?? 'new',
        totalReviewsReceived:
            (json['total_reviews_received'] as num?)?.toInt() ?? 0,
        aiReviewSummary: json['ai_review_summary'] as String?,
        message: json['message'] as String?,
        sentimentDistribution: SentimentDistribution.fromJson(
          json['sentiment_distribution'] as Map<String, dynamic>?,
        ),
      );
}

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
