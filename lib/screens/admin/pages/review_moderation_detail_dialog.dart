import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/admin_colors.dart';
import '../../../models/admin_review_moderation_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/admin_action_button.dart';
import '../../../widgets/admin/admin_dialog.dart';
import '../../../widgets/admin/admin_loading.dart';
import '../../../widgets/admin/admin_reason_dialog.dart';
import '../../../widgets/admin/admin_score_row.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/review_rating_helpers.dart';

Future<void> showReviewModerationDialog(
  BuildContext context, {
  required String id,
  required bool isClientReview,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => AdminDetailDialogShell(
      child: _ReviewModerationDetailView(id: id, isClientReview: isClientReview),
    ),
  );
}

class _ReviewModerationDetailView extends StatefulWidget {
  final String id;
  final bool isClientReview;

  const _ReviewModerationDetailView({
    required this.id,
    required this.isClientReview,
  });

  @override
  State<_ReviewModerationDetailView> createState() =>
      _ReviewModerationDetailViewState();
}

class _ReviewModerationDetailViewState
    extends State<_ReviewModerationDetailView> {
  late Future<ReviewModerationDetail?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ReviewModerationDetail?> _load() {
    final admin = context.read<AdminProvider>();
    return widget.isClientReview
        ? admin.fetchClientReviewModerationDetail(widget.id)
        : admin.fetchReviewModerationDetail(widget.id);
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReviewModerationDetail?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 320,
            child: Center(child: AdminLoadingIndicator()),
          );
        }
        final detail = snap.data;
        if (detail == null) {
          return _ErrorBody(onRetry: _reload);
        }
        return _LoadedBody(
          detail: detail,
          isClientReview: widget.isClientReview,
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AdminColors.muted),
          const SizedBox(height: 12),
          Text(
            'Could not load this review',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AdminColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'It may have been actioned by another admin, or the request failed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.muted),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close',
                    style: GoogleFonts.poppins(color: AdminColors.muted)),
              ),
              const SizedBox(width: 8),
              AdminActionButton(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                color: AdminColors.primary,
                onPressed: onRetry,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final ReviewModerationDetail detail;
  final bool isClientReview;

  const _LoadedBody({required this.detail, required this.isClientReview});

  String get _subjectName => detail.reviewer.name ?? 'Review';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          title: _subjectName,
          holdLevel: detail.holdLevel,
          isClientReview: isClientReview,
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: [
              if (detail.analysisUnavailable) const _AnalysisUnavailableBanner(),
              _ContradictionPane(detail: detail),
              const _SectionDivider(),
              _QuestionAnswerPane(detail: detail),
              const _SectionDivider(),
              _ContractRecordStrip(detail: detail),
              const _SectionDivider(),
              _ComponentVerdicts(detail: detail),
              const _SectionDivider(),
              _FlagReasons(detail: detail),
              const _SectionDivider(),
              _ReviewerContext(detail: detail),
              const _SectionDivider(),
              _DmThread(detail: detail),
            ],
          ),
        ),
        _ActionsBar(detail: detail, isClientReview: isClientReview),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String holdLevel;
  final bool isClientReview;

  const _Header({
    required this.title,
    required this.holdLevel,
    required this.isClientReview,
  });

  @override
  Widget build(BuildContext context) {
    final suppressed = holdLevel == 'suppressed';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Pill(
                      label: isClientReview ? 'CLIENT REVIEW' : 'FREELANCER REVIEW',
                      color: isClientReview
                          ? AdminColors.purple
                          : AdminColors.primary,
                    ),
                    const SizedBox(width: 6),
                    _Pill(
                      label: suppressed ? 'SUPPRESSED' : 'FLAGGED',
                      color: suppressed ? AdminColors.red : AdminColors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.ink,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AdminColors.muted,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _AnalysisUnavailableBanner extends StatelessWidget {
  const _AnalysisUnavailableBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.amberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.amberBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: AdminColors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI analysis was unavailable',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.body,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The review pipeline could not reach the models and failed closed. '
                  'No model scored this review — this is an infrastructure failure, '
                  'not a verdict on the review.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AdminColors.body,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContradictionPane extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _ContradictionPane({required this.detail});

  String? get _sentimentLabel =>
      detail.components?.sentimentModel?.label ??
      detail.review['sentiment'] as String?;

  @override
  Widget build(BuildContext context) {
    final ratings = detail.ratings;
    final sentiment = _sentimentLabel;
    final comment = detail.overallComment ?? '';
    final negativeSentiment = sentiment != null &&
        sentiment.toLowerCase().contains('negativ');
    final highStars = (ratings.average ?? 0) >= 4.0;
    final contradiction = negativeSentiment && highStars;

    return _Section(
      title: 'The contradiction',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 440;
          final ratingCol = _RatingsColumn(ratings: ratings);
          final textCol = _ReviewTextColumn(
            comment: comment,
            sentiment: sentiment,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contradiction)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminColors.redBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.priority_high_rounded,
                          size: 16, color: AdminColors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'High star ratings paired with negative sentiment — '
                          'the ratings and the written review disagree.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AdminColors.red,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (narrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [ratingCol, const SizedBox(height: 16), textCol],
                )
              else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ratingCol),
                      Container(
                        width: 1,
                        color: AdminColors.border,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Expanded(child: textCol),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RatingsColumn extends StatelessWidget {
  final ModerationRatings ratings;
  const _RatingsColumn({required this.ratings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              (ratings.average ?? 0).toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AdminColors.ink,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '/ 5  ·  ${ratings.count} ratings',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AdminColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...ratings.categories.map((c) => _CategoryStars(entry: c)),
      ],
    );
  }
}

class _CategoryStars extends StatelessWidget {
  final ModerationRatingEntry entry;
  const _CategoryStars({required this.entry});

  @override
  Widget build(BuildContext context) {
    final score = entry.score ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(ratingIcon(entry.category), size: 14, color: AdminColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ratingLabel(entry.category),
              style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.body),
            ),
          ),
          Row(
            children: List.generate(5, (i) {
              final filled = i < score.round();
              return Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 15,
                color: filled ? AdminColors.amber : AdminColors.border,
              );
            }),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 22,
            child: Text(
              score.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AdminColors.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTextColumn extends StatelessWidget {
  final String comment;
  final String? sentiment;
  const _ReviewTextColumn({required this.comment, required this.sentiment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Written review',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AdminColors.faint,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            if (sentiment != null) _SentimentChip(label: sentiment!),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          comment.isEmpty ? 'No written comment.' : comment,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: comment.isEmpty ? AdminColors.faint : AdminColors.body,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SentimentChip extends StatelessWidget {
  final String label;
  const _SentimentChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    Color color = AdminColors.muted;
    if (lower.contains('negativ')) color = AdminColors.red;
    if (lower.contains('positiv')) color = AdminColors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sentiment_neutral_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionAnswerPane extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _QuestionAnswerPane({required this.detail});

  @override
  Widget build(BuildContext context) {
    final question = detail.aiQuestion;
    final answer = detail.answer;
    final groundedness = detail.components?.llm?.answerGroundedness;
    if (question == null || question.isEmpty || answer == null || answer.isEmpty) {
      return _Section(
        title: 'Question & answer',
        child: Text(
          'No AI question/answer pair recorded for this review.',
          style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
        ),
      );
    }
    return _Section(
      title: 'Question & answer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QaBlock(label: 'AI asked', text: question, color: AdminColors.primary),
          const SizedBox(height: 10),
          _QaBlock(label: 'Reviewer answered', text: answer, color: AdminColors.body),
          const SizedBox(height: 12),
          MeasuredScoreBar(
            label: 'Answer groundedness',
            value: groundedness,
            note: 'how well the answer is supported',
          ),
        ],
      ),
    );
  }
}

class _QaBlock extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _QaBlock({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AdminColors.faint,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AdminColors.body,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractRecordStrip extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _ContractRecordStrip({required this.detail});

  @override
  Widget build(BuildContext context) {
    final source = detail.isClientReview
        ? (detail.subjectLifetimeScores ?? const {})
        : detail.telemetry;

    double? num2(String k) => (source[k] as num?)?.toDouble();
    final onTime = num2('on_time_score');
    final revisionRate = num2('revision_rate_score');
    final responsiveness = num2('responsiveness_score');
    final revisionCount = (source['revision_count'] as num?)?.toInt();
    final onTimeMeasurable = detail.isClientReview
        ? onTime != null
        : (detail.telemetry['on_time_measurable'] == true);

    return _Section(
      title: detail.isClientReview
          ? 'Client lifetime record'
          : 'Objective contract record',
      subtitle: 'Measured platform data — check it against the model verdicts.',
      child: Column(
        children: [
          MeasuredScoreBar(
            label: 'On-time delivery',
            value: onTime,
            isMeasured: onTimeMeasurable && onTime != null,
          ),
          MeasuredScoreBar(
            label: 'Revision rate',
            value: revisionRate,
            isMeasured: revisionRate != null,
            note: revisionCount != null ? '$revisionCount revisions' : null,
          ),
          MeasuredScoreBar(
            label: 'Responsiveness',
            value: responsiveness,
            isMeasured: responsiveness != null,
          ),
        ],
      ),
    );
  }
}

class _ComponentVerdicts extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _ComponentVerdicts({required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.analysisUnavailable) {
      return _Section(
        title: 'Per-model verdicts',
        child: Text(
          'No model verdicts exist — analysis was unavailable (see banner above).',
          style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
        ),
      );
    }

    final c = detail.components;
    if (c == null) {
      return _Section(
        title: 'Per-model verdicts',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MeasuredScoreBar(
              label: 'Blended authenticity (stored)',
              value: detail.storedAuthenticityScore,
            ),
            const SizedBox(height: 8),
            Text(
              'The per-model breakdown is unavailable for this review — it was '
              'analysed before per-model judgments were logged.',
              style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
            ),
          ],
        ),
      );
    }

    return _Section(
      title: 'Per-model verdicts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.disagreements.any) _DisagreementBanner(d: c.disagreements),
          if (c.llm != null) _LlmCard(v: c.llm!),
          if (c.sentimentModel != null) _SentimentCard(v: c.sentimentModel!),
          if (c.authenticityModel != null) _AuthenticityCard(v: c.authenticityModel!),
          if (c.disagreementModel != null) _DisagreementCard(v: c.disagreementModel!),
          _BlendReconciliation(detail: detail),
        ],
      ),
    );
  }
}

class _DisagreementBanner extends StatelessWidget {
  final Disagreements d;
  const _DisagreementBanner({required this.d});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (d.fake) 'authenticity',
      if (d.mismatch) 'sentiment mismatch',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.redBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.red.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.compare_arrows_rounded,
              size: 18, color: AdminColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'The LLM and the classifier disagree on ${parts.join(' and ')}. '
              'This is the call you are adjudicating.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.red,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;
  const _VerdictCard({
    required this.title,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.ink,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _LlmCard extends StatelessWidget {
  final LlmVerdict v;
  const _LlmCard({required this.v});

  @override
  Widget build(BuildContext context) {
    return _VerdictCard(
      title: 'LLM judge',
      children: [
        MeasuredScoreBar(label: 'Authenticity', value: v.authenticityScore),
        MeasuredScoreBar(
          label: 'Answer groundedness',
          value: v.answerGroundedness,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (v.isFlaggedFake) const _FlagChip(label: 'Flagged fake'),
            if (v.isFlaggedCoerced) const _FlagChip(label: 'Flagged coerced'),
            if (v.sentimentMismatch)
              const _FlagChip(label: 'Sentiment mismatch'),
          ],
        ),
      ],
    );
  }
}

class _SentimentCard extends StatelessWidget {
  final SentimentModelVerdict v;
  const _SentimentCard({required this.v});

  @override
  Widget build(BuildContext context) {
    return _VerdictCard(
      title: 'Sentiment model',
      trailing: ModelVerdictChip(modelUsed: v.modelUsed),
      children: [
        Row(
          children: [
            Text(
              v.label ?? 'unknown',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminColors.body,
              ),
            ),
            const Spacer(),
            if (v.score != null)
              Text(
                'score ${v.score!.toStringAsFixed(2)} (−1..1)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AdminColors.muted,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AuthenticityCard extends StatelessWidget {
  final AuthenticityModelVerdict v;
  const _AuthenticityCard({required this.v});

  @override
  Widget build(BuildContext context) {
    return _VerdictCard(
      title: 'Authenticity classifier',
      trailing: ModelVerdictChip(modelUsed: v.modelUsed),
      children: [
        MeasuredScoreBar(
          label: 'Fake probability',
          note: 'length-adjusted',
          value: v.fakeProbabilityCalibrated,
          threshold: v.threshold,
          higherIsWorse: true,
        ),
        const SizedBox(height: 2),
        Text(
          v.fakeProbability != null
              ? 'Raw (uncalibrated): ${v.fakeProbability!.toStringAsFixed(3)}'
              : 'Raw (uncalibrated): not measured',
          style: GoogleFonts.poppins(fontSize: 10, color: AdminColors.faint),
        ),
        if (v.isLikelyFake) ...[
          const SizedBox(height: 8),
          const _FlagChip(label: 'Above threshold — likely fake'),
        ],
      ],
    );
  }
}

class _DisagreementCard extends StatelessWidget {
  final DisagreementModelVerdict v;
  const _DisagreementCard({required this.v});

  @override
  Widget build(BuildContext context) {
    return _VerdictCard(
      title: 'Disagreement model',
      trailing: ModelVerdictChip(modelUsed: v.modelUsed),
      children: [
        MeasuredScoreBar(
          label: 'Disagreement probability',
          value: v.disagreementProbability,
          threshold: v.threshold,
          higherIsWorse: true,
        ),
        if (v.isMismatched) ...[
          const SizedBox(height: 8),
          const _FlagChip(label: 'Above threshold — mismatched'),
        ],
      ],
    );
  }
}

class _BlendReconciliation extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _BlendReconciliation({required this.detail});

  @override
  Widget build(BuildContext context) {
    final w = detail.blendWeights;
    final c = detail.components;
    final llmScore = c?.llm?.authenticityScore;
    final calibrated = c?.authenticityModel?.fakeProbabilityCalibrated;
    final grounded = c?.llm?.answerGroundedness;

    if (!w.hasAll ||
        llmScore == null ||
        calibrated == null ||
        grounded == null) {
      return const SizedBox.shrink();
    }
    final authTerm = 1 - calibrated;
    final blended =
        w.llm! * llmScore + w.authenticityModel! * authTerm + w.answerGroundedness! * grounded;

    String f(double d) {
      var s = d.toStringAsFixed(3);
      if (s.contains('.')) {
        s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
      return s;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.primaryBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Blended authenticity',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AdminColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${f(w.llm!)}×${f(llmScore)} + ${f(w.authenticityModel!)}×(1−${f(calibrated)}) '
            '+ ${f(w.answerGroundedness!)}×${f(grounded)} = ${blended.toStringAsFixed(3)}',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: AdminColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  final String label;
  const _FlagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AdminColors.redBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AdminColors.red,
        ),
      ),
    );
  }
}

class _FlagReasons extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _FlagReasons({required this.detail});

  List<_AttributedReason> _reasons() {
    final out = <_AttributedReason>[];
    final raw = detail.review['flag_reasons'];
    if (raw is List) {
      for (final r in raw) {
        if (r is Map) {
          out.add(_AttributedReason(
            source: r['source']?.toString() ?? 'system',
            text: r['reason']?.toString() ?? r['text']?.toString() ?? '',
          ));
        } else {
          out.add(_AttributedReason(source: 'system', text: r.toString()));
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final reasons = _reasons();
    if (reasons.isEmpty) {
      return _Section(
        title: 'Flag reasons',
        child: Text(
          'No individual flag reasons recorded.',
          style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
        ),
      );
    }
    return _Section(
      title: 'Flag reasons',
      child: Column(
        children: reasons
            .map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r.source,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.text,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AdminColors.body,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _AttributedReason {
  final String source;
  final String text;
  const _AttributedReason({required this.source, required this.text});
}

class _ReviewerContext extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _ReviewerContext({required this.detail});

  @override
  Widget build(BuildContext context) {
    final r = detail.reviewer;
    final prior = r.priorReviewsWritten;
    return _Section(
      title: 'Reviewer context',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name ?? 'Unknown reviewer',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.ink,
                      ),
                    ),
                    if (r.email != null)
                      Text(
                        r.email!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AdminColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              if (r.trustScore != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      r.trustScore!.toStringAsFixed(2),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.primary,
                      ),
                    ),
                    Text(
                      'trust score',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AdminColors.faint,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${prior.total} prior reviews written · ${prior.held} held · '
            '${prior.published} published',
            style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.body),
          ),
          if (prior.total <= 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Only one review — not enough history to show a coercion or '
                'retaliation pattern.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AdminColors.faint,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DmThread extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _DmThread({required this.detail});

  @override
  Widget build(BuildContext context) {
    final messages = detail.dmThread;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(
          'DM thread (${messages.length})',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AdminColors.ink,
          ),
        ),
        subtitle: Text(
          'The LLM cites this — verify its claims here',
          style: GoogleFonts.poppins(fontSize: 11, color: AdminColors.faint),
        ),
        children: messages.isEmpty
            ? [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No linked conversation.',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AdminColors.faint),
                  ),
                ),
              ]
            : messages
                .map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.senderId ?? 'unknown',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AdminColors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.messageText ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AdminColors.body,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
      ),
    );
  }
}

class _ActionsBar extends StatelessWidget {
  final ReviewModerationDetail detail;
  final bool isClientReview;

  const _ActionsBar({required this.detail, required this.isClientReview});

  Future<void> _publish(BuildContext context) async {
    final admin = context.read<AdminProvider>();
    final id = detail.id;
    final outcome = await showAdminReasonDialog(
      context,
      title: 'Publish this review anyway?',
      submitLabel: 'Publish',
      accentColor: AdminColors.green,
      icon: Icons.public_rounded,
      warningText: 'This publishes the review immediately — it becomes visible '
          'to both parties and cannot be un-published.',
      onSubmit: (reason) => isClientReview
          ? admin.overridePublishClientReview(id, reason: reason)
          : admin.overridePublishReview(id, reason: reason),
    );
    if (outcome != null && outcome.success && context.mounted) {
      Navigator.pop(context);
      AppToast.success('Review published.');
    }
  }

  Future<void> _uphold(BuildContext context) async {
    final admin = context.read<AdminProvider>();
    final id = detail.id;
    final outcome = await showAdminReasonDialog(
      context,
      title: 'Uphold this hold?',
      submitLabel: 'Uphold hold',
      accentColor: AdminColors.red,
      icon: Icons.gpp_maybe_rounded,
      onSubmit: (reason) => isClientReview
          ? admin.upholdClientReview(id, reason: reason)
          : admin.upholdReview(id, reason: reason),
    );
    if (outcome != null && outcome.success && context.mounted) {
      Navigator.pop(context);
      AppToast.success('Hold upheld — review suppressed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AdminActionButton(
              label: 'Uphold hold',
              icon: Icons.gpp_maybe_rounded,
              color: AdminColors.red,
              style: AdminActionStyle.outlined,
              onPressed: () => _uphold(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AdminActionButton(
              label: 'Publish anyway',
              icon: Icons.public_rounded,
              color: AdminColors.green,
              onPressed: () => _publish(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Section({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AdminColors.ink,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.poppins(fontSize: 11, color: AdminColors.faint),
          ),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Divider(height: 1, color: AdminColors.border),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
