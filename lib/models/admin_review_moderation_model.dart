
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
  final double? score;
  final String? modelUsed;

  const SentimentModelVerdict({this.label, this.score, this.modelUsed});

  factory SentimentModelVerdict.fromJson(Map<String, dynamic> json) =>
      SentimentModelVerdict(
        label: json['label'] as String?,
        score: (json['score'] as num?)?.toDouble(),
        modelUsed: json['model_used'] as String?,
      );

  bool get isFallbackModel => modelUsed?.startsWith('sbert_') ?? false;
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

/// Only the sentiment mismatch survives here: the fake disagreement compared
/// the LLM against the authenticity classifier, which the admin no longer sees.
class Disagreements {
  final bool mismatch;

  const Disagreements({this.mismatch = false});

  factory Disagreements.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Disagreements();
    return Disagreements(mismatch: json['mismatch'] == true);
  }

  bool get any => mismatch;
}

class ModerationComponents {
  final LlmVerdict? llm;
  final SentimentModelVerdict? sentimentModel;
  final DisagreementModelVerdict? disagreementModel;
  final Disagreements disagreements;

  const ModerationComponents({
    this.llm,
    this.sentimentModel,
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
      disagreementModel: sub('disagreement_model') != null
          ? DisagreementModelVerdict.fromJson(sub('disagreement_model')!)
          : null,
      disagreements: Disagreements.fromJson(sub('disagreements')),
    );
  }
}

/// The payload still carries an `authenticity_model` weight; it is always 0 and
/// is deliberately not parsed, because that model is not shown to admins.
class BlendWeights {
  final double? llm;
  final double? answerGroundedness;

  const BlendWeights({this.llm, this.answerGroundedness});

  factory BlendWeights.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BlendWeights();
    return BlendWeights(
      llm: (json['llm'] as num?)?.toDouble(),
      answerGroundedness: (json['answer_groundedness'] as num?)?.toDouble(),
    );
  }

  bool get hasAll => llm != null && answerGroundedness != null;

  /// 0 for this review only: answering the targeted question is optional, and
  /// this reviewer skipped it.
  bool get groundednessDropped => answerGroundedness == 0;
}

/// One rating category's star claim measured against the objective record.
/// `claimed` is the star rating normalised to 0–1; `actual` is the measured
/// score; `gap` is claimed − actual, so positive means the review flatters the
/// record and negative means it is harsher than the record.
class RecordGapDimension {
  final double? claimed;
  final double? actual;
  final double? gap;

  const RecordGapDimension({this.claimed, this.actual, this.gap});

  factory RecordGapDimension.fromJson(Map<String, dynamic> json) =>
      RecordGapDimension(
        claimed: (json['claimed'] as num?)?.toDouble(),
        actual: (json['actual'] as num?)?.toDouble(),
        gap: (json['gap'] as num?)?.toDouble(),
      );

  bool get isInflation => (gap ?? 0) > 0.0005;
  bool get isDeflation => (gap ?? 0) < -0.0005;
}

class RecordGaps {
  /// Weighted mean of the positive gaps. Null means nothing was comparable -
  /// no evidence either way, NOT a perfectly consistent review.
  final double? inflation;

  /// Weighted mean of the negative gaps, same null semantics as [inflation].
  final double? deflation;

  final int dimensionsCompared;
  final Map<String, RecordGapDimension> perDimension;

  const RecordGaps({
    this.inflation,
    this.deflation,
    this.dimensionsCompared = 0,
    this.perDimension = const {},
  });

  factory RecordGaps.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RecordGaps();
    final raw = json['per_dimension'];
    final dimensions = <String, RecordGapDimension>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          dimensions[key.toString()] = RecordGapDimension.fromJson(value);
        }
      });
    }
    return RecordGaps(
      inflation: (json['inflation'] as num?)?.toDouble(),
      deflation: (json['deflation'] as num?)?.toDouble(),
      dimensionsCompared: (json['dimensions_compared'] as num?)?.toInt() ?? 0,
      perDimension: dimensions,
    );
  }

  /// Nothing could be lined up against the record. Distinct from "the review
  /// agrees with the record" - there is simply no evidence either way.
  bool get nothingComparable =>
      dimensionsCompared <= 0 ||
      perDimension.isEmpty ||
      (inflation == null && deflation == null);
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
    // The reviewer block is spread straight from the freelancer/client row, so
    // the name arrives as `full_name`; `name` is only a defensive fallback.
    final name = (json['full_name'] ?? json['name']) as String?;
    return ModerationReviewer(
      name: (name?.trim().isEmpty ?? true) ? null : name!.trim(),
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

/// One admin decision already recorded against this review, oldest first in
/// [ReviewModerationDetail.adminRulings].
///
/// This comes from an append-only log file that is gitignored, so an empty
/// list means "no ruling on file" - NOT "definitely never ruled on". It is
/// display-only history; nothing destructive may be gated on it.
class AdminRuling {
  /// 'uphold' or 'override_publish'.
  final String action;

  /// Null when the log entry predates email capture - fall back to "admin".
  final String? adminEmail;

  /// Always present and at least 10 characters; the backend requires it.
  final String reason;

  /// The review's status at the moment of the ruling: 'flagged', 'suppressed',
  /// or null on older entries.
  final String? priorStatus;

  final DateTime? loggedAt;

  const AdminRuling({
    this.action = '',
    this.adminEmail,
    this.reason = '',
    this.priorStatus,
    this.loggedAt,
  });

  factory AdminRuling.fromJson(Map<String, dynamic> json) => AdminRuling(
        action: json['action'] as String? ?? '',
        adminEmail: json['admin_email'] as String?,
        reason: json['reason'] as String? ?? '',
        priorStatus: json['prior_status'] as String?,
        loggedAt: json['logged_at'] != null
            ? DateTime.tryParse(json['logged_at'].toString())
            : null,
      );

  bool get isUphold => action == 'uphold';

  /// uphold on an already-suppressed review changed no status; the value was
  /// the recorded agreement with the pipeline
  bool get confirmedExistingSuppression =>
      isUphold && priorStatus == 'suppressed';
}

class ReviewModerationDetail {
  final Map<String, dynamic> review;
  final ModerationRatings ratings;

  final ModerationComponents? components;
  final BlendWeights blendWeights;

  final Map<String, dynamic> telemetry;

  final Map<String, dynamic>? subjectLifetimeScores;
  final RecordGaps recordGaps;
  final ModerationReviewer reviewer;
  final List<DmThreadMessage> dmThread;

  /// Oldest first. Only the detail endpoints send this - the flagged list
  /// endpoint does not, so queue cards cannot branch on it.
  final List<AdminRuling> adminRulings;

  final String holdLevel;
  final bool analysisUnavailable;
  final bool isClientReview;

  const ReviewModerationDetail({
    this.review = const {},
    this.ratings = const ModerationRatings(),
    this.components,
    this.blendWeights = const BlendWeights(),
    this.telemetry = const {},
    this.subjectLifetimeScores,
    this.recordGaps = const RecordGaps(),
    this.reviewer = const ModerationReviewer(),
    this.dmThread = const [],
    this.adminRulings = const [],
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
      recordGaps:
          RecordGaps.fromJson(json['record_gaps'] as Map<String, dynamic>?),
      reviewer:
          ModerationReviewer.fromJson(json['reviewer'] as Map<String, dynamic>?),
      dmThread: (json['dm_thread'] as List<dynamic>?)
              ?.map((e) => DmThreadMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      adminRulings: (json['admin_rulings'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(AdminRuling.fromJson)
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

  String? get answer =>
      (review['client_answer'] ?? review['freelancer_answer']) as String?;

  String? get overallComment => review['overall_comment'] as String?;

  /// Who the review is about - the freelancer for a freelancer review, the
  /// client for a client review. Not the reviewer; that is [reviewer].
  String? get subjectName =>
      (review['freelancer_name'] ?? review['client_name']) as String?;

  /// Nullable: the backend now stores NULL when the LLM was unreachable rather
  /// than a misleading mid-range score. Null is "not scored", never a bad score.
  double? get storedAuthenticityScore =>
      (review['authenticity_score'] as num?)?.toDouble();

  Map<String, dynamic> get _lifetime => subjectLifetimeScores ?? const {};

  double? lifetimeScore(String key) => (_lifetime[key] as num?)?.toDouble();

  /// False means the subject has no published review yet, so the lifetime
  /// figures were measured live. Null when the backend did not send the flag
  /// (older payload) - say nothing rather than guess.
  bool? get hasPersistedTrustScore {
    final v = _lifetime['has_persisted_trust_score'];
    return v is bool ? v : null;
  }
}
