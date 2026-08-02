
class RedFlagSubject {
  final String subjectType;
  final String? subjectId;
  final String? name;
  final String? email;
  final String? userId;

  const RedFlagSubject({
    this.subjectType = 'freelancer',
    this.subjectId,
    this.name,
    this.email,
    this.userId,
  });

  factory RedFlagSubject.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RedFlagSubject();
    return RedFlagSubject(
      subjectType: json['subject_type'] as String? ?? 'freelancer',
      subjectId: json['subject_id']?.toString(),
      name: json['name'] as String?,
      email: json['email'] as String?,
      userId: json['user_id']?.toString(),
    );
  }

  bool get isClient => subjectType == 'client';
}

class ScoreHistoryPoint {
  final double? score;
  final String? snapshotReason;
  final DateTime? recordedAt;

  const ScoreHistoryPoint({this.score, this.snapshotReason, this.recordedAt});

  factory ScoreHistoryPoint.fromJson(Map<String, dynamic> json) =>
      ScoreHistoryPoint(
        score: (json['score'] as num?)?.toDouble(),
        snapshotReason: json['snapshot_reason'] as String?,
        recordedAt: json['recorded_at'] != null
            ? DateTime.tryParse(json['recorded_at'].toString())
            : null,
      );
}

class ScoreDrop {
  final double? from;
  final double? to;
  final double? delta;
  final DateTime? fromRecordedAt;
  final DateTime? toRecordedAt;

  const ScoreDrop({
    this.from,
    this.to,
    this.delta,
    this.fromRecordedAt,
    this.toRecordedAt,
  });

  factory ScoreDrop.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScoreDrop();
    return ScoreDrop(
      from: (json['from'] as num?)?.toDouble(),
      to: (json['to'] as num?)?.toDouble(),
      delta: (json['delta'] as num?)?.toDouble(),
      fromRecordedAt: json['from_recorded_at'] != null
          ? DateTime.tryParse(json['from_recorded_at'].toString())
          : null,
      toRecordedAt: json['to_recorded_at'] != null
          ? DateTime.tryParse(json['to_recorded_at'].toString())
          : null,
    );
  }
}

class RedFlagDetail {
  final Map<String, dynamic> alert;
  final RedFlagSubject subject;

  final Map<String, double>? currentComponents;
  final List<ScoreHistoryPoint> scoreHistory;
  final ScoreDrop drop;
  final List<Map<String, dynamic>> recentReviews;
  final List<Map<String, dynamic>> heldReviewsInWindow;
  final int heldReviewCount;
  final List<Map<String, dynamic>> overriddenReviewsInWindow;
  final int overriddenReviewCount;
  final List<Map<String, dynamic>> otherOpenAlerts;

  const RedFlagDetail({
    this.alert = const {},
    this.subject = const RedFlagSubject(),
    this.currentComponents,
    this.scoreHistory = const [],
    this.drop = const ScoreDrop(),
    this.recentReviews = const [],
    this.heldReviewsInWindow = const [],
    this.heldReviewCount = 0,
    this.overriddenReviewsInWindow = const [],
    this.overriddenReviewCount = 0,
    this.otherOpenAlerts = const [],
  });

  factory RedFlagDetail.fromJson(Map<String, dynamic> json) {
    Map<String, double>? parseComponents(dynamic raw) {
      if (raw is! Map) return null;
      final out = <String, double>{};
      raw.forEach((k, v) {
        if (v is num) out[k.toString()] = v.toDouble();
      });
      return out.isEmpty ? null : out;
    }

    List<Map<String, dynamic>> mapList(dynamic raw) => raw is List
        ? raw.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];

    return RedFlagDetail(
      alert: (json['alert'] as Map<String, dynamic>?) ?? const {},
      subject: RedFlagSubject.fromJson(json['subject'] as Map<String, dynamic>?),
      currentComponents: parseComponents(json['current_components']),
      scoreHistory: (json['score_history'] as List<dynamic>?)
              ?.map((e) => ScoreHistoryPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      drop: ScoreDrop.fromJson(json['drop'] as Map<String, dynamic>?),
      recentReviews: mapList(json['recent_reviews']),
      heldReviewsInWindow: mapList(json['held_reviews_in_window']),
      heldReviewCount: (json['held_review_count'] as num?)?.toInt() ??
          mapList(json['held_reviews_in_window']).length,
      overriddenReviewsInWindow: mapList(json['overridden_reviews_in_window']),
      overriddenReviewCount: (json['overridden_review_count'] as num?)?.toInt() ??
          mapList(json['overridden_reviews_in_window']).length,
      otherOpenAlerts: mapList(json['other_open_alerts']),
    );
  }

  String get alertId => alert['id']?.toString() ?? '';

  String get alertType => alert['alert_type'] as String? ?? '';

  String get message => alert['message'] as String? ?? '';

  bool get isResolved => alert['is_resolved'] == true;

  String? get resolutionNote => alert['resolution_note'] as String?;
}
