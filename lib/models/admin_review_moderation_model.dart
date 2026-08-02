// Admin review-moderation detail models.
//
// These back the review-moderation detail dialog. Every numeric field is parsed
// as `num?.toDouble()` and left null when absent — a null score means "never
// measured" and must never be shown as 0. Deeply-nested verdicts are each
// independently nullable because a review can be analysed before judgment
// logging existed (components == null) or fail closed on an AI outage
// (analysis_unavailable == true), and both must be distinguishable from a
// low-but-real score.

// Per-category rating (star) entry inside the moderation payload.
class ModerationRatingEntry {
  final String category;
  final double? score;

  const ModerationRatingEntry({required this.category, this.score});

  factory ModerationRatingEntry.fromJson(Map<String, dynamic> json) =>
      ModerationRatingEntry(
        category: json['category'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble(),
      );
}

class ModerationRatings {
  final List<ModerationRatingEntry> categories;
  final double? average;
  final int count;

  const ModerationRatings({
    this.categories = const [],
    this.average,
    this.count = 0,
  });

  factory ModerationRatings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ModerationRatings();
    return ModerationRatings(
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) =>
                  ModerationRatingEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      average: (json['average'] as num?)?.toDouble(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LlmVerdict {
  final double? authenticityScore;
  final bool isFlaggedFake;
  final bool isFlaggedCoerced;
  final bool sentimentMismatch;
  final double? answerGroundedness;

  const LlmVerdict({
    this.authenticityScore,
    this.isFlaggedFake = false,
    this.isFlaggedCoerced = false,
    this.sentimentMismatch = false,
    this.answerGroundedness,
  });

  factory LlmVerdict.fromJson(Map<String, dynamic> json) => LlmVerdict(
        authenticityScore: (json['authenticity_score'] as num?)?.toDouble(),
        isFlaggedFake: json['is_flagged_fake'] == true,
        isFlaggedCoerced: json['is_flagged_coerced'] == true,
        sentimentMismatch: json['sentiment_mismatch'] == true,
        answerGroundedness: (json['answer_groundedness'] as num?)?.toDouble(),
      );
}

class SentimentModelVerdict {
  final String? label;
  final double? score; // -1..1
  final String? modelUsed;

  const SentimentModelVerdict({this.label, this.score, this.modelUsed});

  factory SentimentModelVerdict.fromJson(Map<String, dynamic> json) =>
      SentimentModelVerdict(
        label: json['label'] as String?,
        score: (json['score'] as num?)?.toDouble(),
        modelUsed: json['model_used'] as String?,
      );

  /// True when a weaker fallback (sbert_*) answered instead of the primary.
  bool get isFallbackModel => modelUsed?.startsWith('sbert_') ?? false;
}

class AuthenticityModelVerdict {
  final double? fakeProbability;
  final double? fakeProbabilityCalibrated;
  final bool isLikelyFake;
  final double? threshold;
  final String? modelUsed;

  const AuthenticityModelVerdict({
    this.fakeProbability,
    this.fakeProbabilityCalibrated,
    this.isLikelyFake = false,
    this.threshold,
    this.modelUsed,
  });

  factory AuthenticityModelVerdict.fromJson(Map<String, dynamic> json) =>
      AuthenticityModelVerdict(
        fakeProbability: (json['fake_probability'] as num?)?.toDouble(),
        fakeProbabilityCalibrated:
            (json['fake_probability_calibrated'] as num?)?.toDouble(),
        isLikelyFake: json['is_likely_fake'] == true,
        threshold: (json['threshold'] as num?)?.toDouble(),
        modelUsed: json['model_used'] as String?,
      );
}

class DisagreementModelVerdict {
  final double? disagreementProbability;
  final bool isMismatched;
  final double? threshold;
  final String? modelUsed;

  const DisagreementModelVerdict({
    this.disagreementProbability,
    this.isMismatched = false,
    this.threshold,
    this.modelUsed,
  });

  factory DisagreementModelVerdict.fromJson(Map<String, dynamic> json) =>
      DisagreementModelVerdict(
        disagreementProbability:
            (json['disagreement_probability'] as num?)?.toDouble(),
        isMismatched: json['is_mismatched'] == true,
        threshold: (json['threshold'] as num?)?.toDouble(),
        modelUsed: json['model_used'] as String?,
      );

  bool get isFallbackModel => modelUsed?.startsWith('sbert_') ?? false;
}

class Disagreements {
  final bool fake;
  final bool mismatch;

  const Disagreements({this.fake = false, this.mismatch = false});

  factory Disagreements.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Disagreements();
    return Disagreements(
      fake: json['fake'] == true,
      mismatch: json['mismatch'] == true,
    );
  }

  bool get any => fake || mismatch;
}

class ModerationComponents {
  final LlmVerdict? llm;
  final SentimentModelVerdict? sentimentModel;
  final AuthenticityModelVerdict? authenticityModel;
  final DisagreementModelVerdict? disagreementModel;
  final Disagreements disagreements;

  const ModerationComponents({
    this.llm,
    this.sentimentModel,
    this.authenticityModel,
    this.disagreementModel,
    this.disagreements = const Disagreements(),
  });

  factory ModerationComponents.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? sub(String key) {
      final v = json[key];
      return v is Map<String, dynamic> ? v : null;
    }

    return ModerationComponents(
      llm: sub('llm') != null ? LlmVerdict.fromJson(sub('llm')!) : null,
      sentimentModel: sub('sentiment_model') != null
          ? SentimentModelVerdict.fromJson(sub('sentiment_model')!)
          : null,
      authenticityModel: sub('authenticity_model') != null
          ? AuthenticityModelVerdict.fromJson(sub('authenticity_model')!)
          : null,
      disagreementModel: sub('disagreement_model') != null
          ? DisagreementModelVerdict.fromJson(sub('disagreement_model')!)
          : null,
      disagreements: Disagreements.fromJson(sub('disagreements')),
    );
  }
}

class BlendWeights {
  final double? llm;
  final double? authenticityModel;
  final double? answerGroundedness;

  const BlendWeights({this.llm, this.authenticityModel, this.answerGroundedness});

  factory BlendWeights.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BlendWeights();
    return BlendWeights(
      llm: (json['llm'] as num?)?.toDouble(),
      authenticityModel: (json['authenticity_model'] as num?)?.toDouble(),
      answerGroundedness: (json['answer_groundedness'] as num?)?.toDouble(),
    );
  }

  bool get hasAll =>
      llm != null && authenticityModel != null && answerGroundedness != null;
}

class PriorReviewsWritten {
  final int total;
  final int held;
  final int published;

  const PriorReviewsWritten({
    this.total = 0,
    this.held = 0,
    this.published = 0,
  });

  factory PriorReviewsWritten.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PriorReviewsWritten();
    return PriorReviewsWritten(
      total: (json['total'] as num?)?.toInt() ?? 0,
      held: (json['held'] as num?)?.toInt() ?? 0,
      published: (json['published'] as num?)?.toInt() ?? 0,
    );
  }
}

class ModerationReviewer {
  final String? name;
  final String? email;
  final double? trustScore;
  final PriorReviewsWritten priorReviewsWritten;

  const ModerationReviewer({
    this.name,
    this.email,
    this.trustScore,
    this.priorReviewsWritten = const PriorReviewsWritten(),
  });

  factory ModerationReviewer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ModerationReviewer();
    return ModerationReviewer(
      name: json['name'] as String?,
      email: json['email'] as String?,
      trustScore: (json['trust_score'] as num?)?.toDouble(),
      priorReviewsWritten: PriorReviewsWritten.fromJson(
        json['prior_reviews_written'] as Map<String, dynamic>?,
      ),
    );
  }
}

class DmThreadMessage {
  final String? senderId;
  final String? messageText;
  final DateTime? sentAt;

  const DmThreadMessage({this.senderId, this.messageText, this.sentAt});

  factory DmThreadMessage.fromJson(Map<String, dynamic> json) => DmThreadMessage(
        senderId: json['sender_id']?.toString(),
        messageText: json['message_text'] as String?,
        sentAt: json['sent_at'] != null
            ? DateTime.tryParse(json['sent_at'].toString())
            : null,
      );
}

class ReviewModerationDetail {
  /// Raw review record — kept as a map because the stored blended-score keys
  /// and the answer field name (client_answer vs freelancer_answer) differ
  /// between the two review types. Read via [answer]/[storedAuthenticityScore].
  final Map<String, dynamic> review;
  final ModerationRatings ratings;

  /// Null when [analysisUnavailable] or when the review predates judgment
  /// logging. Distinct from a real low score.
  final ModerationComponents? components;
  final BlendWeights blendWeights;

  /// Freelancer reviews: on_time/revision/responsiveness scores + contract
  /// dates. Client reviews: engagement context only (use
  /// [subjectLifetimeScores] for the objective strip instead).
  final Map<String, dynamic> telemetry;

  /// Client reviews only — the client's lifetime aggregate trust components.
  final Map<String, dynamic>? subjectLifetimeScores;
  final ModerationReviewer reviewer;
  final List<DmThreadMessage> dmThread;
  final String holdLevel; // "flagged" | "suppressed"
  final bool analysisUnavailable;
  final bool isClientReview;

  const ReviewModerationDetail({
    this.review = const {},
    this.ratings = const ModerationRatings(),
    this.components,
    this.blendWeights = const BlendWeights(),
    this.telemetry = const {},
    this.subjectLifetimeScores,
    this.reviewer = const ModerationReviewer(),
    this.dmThread = const [],
    this.holdLevel = 'flagged',
    this.analysisUnavailable = false,
    this.isClientReview = false,
  });

  factory ReviewModerationDetail.fromJson(
    Map<String, dynamic> json, {
    required bool isClientReview,
  }) {
    final rawComponents = json['components'];
    return ReviewModerationDetail(
      review: (json['review'] as Map<String, dynamic>?) ?? const {},
      ratings:
          ModerationRatings.fromJson(json['ratings'] as Map<String, dynamic>?),
      components: rawComponents is Map<String, dynamic>
          ? ModerationComponents.fromJson(rawComponents)
          : null,
      blendWeights:
          BlendWeights.fromJson(json['blend_weights'] as Map<String, dynamic>?),
      telemetry: (json['telemetry'] as Map<String, dynamic>?) ?? const {},
      subjectLifetimeScores:
          json['subject_lifetime_scores'] as Map<String, dynamic>?,
      reviewer:
          ModerationReviewer.fromJson(json['reviewer'] as Map<String, dynamic>?),
      dmThread: (json['dm_thread'] as List<dynamic>?)
              ?.map((e) => DmThreadMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      holdLevel: json['hold_level'] as String? ?? 'flagged',
      analysisUnavailable: json['analysis_unavailable'] == true,
      isClientReview: isClientReview,
    );
  }

  String get id => review['id']?.toString() ?? '';

  String? get status => review['status'] as String?;

  String? get aiQuestion => review['ai_question'] as String?;

  /// The answer the reviewer gave to [aiQuestion] — the field name differs by
  /// review type.
  String? get answer =>
      (review['client_answer'] ?? review['freelancer_answer']) as String?;

  String? get overallComment => review['overall_comment'] as String?;

  /// Stored blended authenticity score on the review row (used as the fallback
  /// display when [components] is null).
  double? get storedAuthenticityScore =>
      (review['authenticity_score'] as num?)?.toDouble();
}
