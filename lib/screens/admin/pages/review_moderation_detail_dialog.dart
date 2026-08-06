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
import '../../../core/utils/text_format.dart';
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
          onRuled: _reload,
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

  /// Re-fetches the detail so a ruling that leaves the dialog open shows up.
  final Future<void> Function() onRuled;

  const _LoadedBody({
    required this.detail,
    required this.isClientReview,
    required this.onRuled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          title: detail.subjectName ?? 'Review',
          reviewerName: detail.reviewer.name,
          holdLevel: detail.holdLevel,
          isClientReview: isClientReview,
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: [
              // Above everything else and inside the scroll view: a ruling
              // quotes its reason in full, so it has no bounded height and
              // cannot live in the fixed action bar without pushing it past
              // the dialog.
              if (detail.adminRulings.isNotEmpty)
                _RulingHistoryBanner(rulings: detail.adminRulings),
              if (detail.analysisUnavailable) const _AnalysisUnavailableBanner(),
              _ContradictionPane(detail: detail),
              const _SectionDivider(),
              _QuestionAnswerPane(detail: detail),
              const _SectionDivider(),
              _ContractRecordStrip(detail: detail),
              const _SectionDivider(),
              _RecordGapsPane(detail: detail),
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
        _ActionsBar(
          detail: detail,
          isClientReview: isClientReview,
          onRuled: onRuled,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? reviewerName;
  final String holdLevel;
  final bool isClientReview;

  const _Header({
    required this.title,
    required this.reviewerName,
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
                if (reviewerName != null)
                  Text(
                    'reviewed by $reviewerName',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AdminColors.muted,
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
            toTitleCase(label),
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

  static const String _baseSubtitle =
      'Measured platform data — check it against the model verdicts.';

  String get _subtitle {
    if (detail.isClientReview && detail.hasPersistedTrustScore == false) {
      return '$_baseSubtitle\n'
          'Measured now; this client has no published review yet.';
    }
    return _baseSubtitle;
  }

  /// This contract, for the freelancer being reviewed.
  Widget _freelancerRows() {
    final source = detail.telemetry;
    double? num2(String k) => (source[k] as num?)?.toDouble();
    final onTime = num2('on_time_score');
    final revisionRate = num2('revision_rate_score');
    final responsiveness = num2('responsiveness_score');
    final revisionCount = (source['revision_count'] as num?)?.toInt();
    final onTimeMeasurable = source['on_time_measurable'] == true;

    return Column(
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
    );
  }

  /// Lifetime, for the client being reviewed. No on-time row: a client has no
  /// delivery deadline, so it is not an unmeasured value — there is nothing to
  /// measure.
  Widget _clientRows() {
    final responsiveness = detail.lifetimeScore('responsiveness_score');
    final requirementChurn = detail.lifetimeScore('revision_rate_score');
    final disputeFairness = detail.lifetimeScore('dispute_fairness_score');

    return Column(
      children: [
        MeasuredScoreBar(
          label: 'Responsiveness',
          value: responsiveness,
          isMeasured: responsiveness != null,
          note: 'DM reply gaps, all contracts',
        ),
        MeasuredScoreBar(
          label: 'Requirement churn',
          value: requirementChurn,
          isMeasured: requirementChurn != null,
          note: 'scope stability — low means the brief kept moving',
        ),
        MeasuredScoreBar(
          label: 'Dispute fairness',
          value: disputeFairness,
          isMeasured: disputeFairness != null,
          note: '1 − disputed / closed contracts',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: detail.isClientReview
          ? 'Client lifetime record'
          : 'Objective contract record',
      subtitle: _subtitle,
      child: detail.isClientReview ? _clientRows() : _freelancerRows(),
    );
  }
}

class _RecordGapsPane extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _RecordGapsPane({required this.detail});

  /// Categories with no objective counterpart are simply not compared. On
  /// client reviews `communication` is also dropped when `responsiveness` is
  /// present — both map to the same measurement.
  String? get _notComparedNote {
    final compared = detail.recordGaps.perDimension.keys.toSet();
    final skipped = detail.ratings.categories
        .map((c) => c.category)
        .where((c) => c.isNotEmpty && !compared.contains(c))
        .toList();
    if (skipped.isEmpty) return null;
    final names = skipped.map(ratingLabel).join(', ');
    final base = 'Not compared: $names. These have no objective counterpart, '
        'which is normal.';
    final foldedIntoResponsiveness = detail.isClientReview &&
        skipped.contains('communication') &&
        compared.contains('responsiveness');
    if (!foldedIntoResponsiveness) return base;
    return '$base Communication maps to the same measurement as '
        'responsiveness — counting both would double-count it.';
  }

  @override
  Widget build(BuildContext context) {
    final gaps = detail.recordGaps;

    return _Section(
      title: 'Claimed vs. record',
      subtitle: 'What the stars claim, next to what the platform measured.',
      child: gaps.nothingComparable
          ? const _NothingComparableNote()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _GapSummaryTile(
                        label: 'INFLATION',
                        value: gaps.inflation,
                        color: AdminColors.red,
                        background: AdminColors.redBg,
                        icon: Icons.trending_up_rounded,
                        hint: 'review flatters the record',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GapSummaryTile(
                        label: 'DEFLATION',
                        value: gaps.deflation,
                        color: AdminColors.cyan,
                        background: AdminColors.cyanBg,
                        icon: Icons.trending_down_rounded,
                        hint: 'review is harsher than the record',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${gaps.dimensionsCompared} '
                  '${gaps.dimensionsCompared == 1 ? 'category' : 'categories'} '
                  'compared',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AdminColors.faint,
                  ),
                ),
                const SizedBox(height: 8),
                ...gaps.perDimension.entries.map(
                  (e) => _GapBar(category: e.key, dimension: e.value),
                ),
                if (detail.isClientReview) ...[
                  const SizedBox(height: 8),
                  _GapFootnote(
                    icon: Icons.history_rounded,
                    text: "This record is the client's lifetime average, not "
                        'this contract. A client who is responsive in general '
                        'but went quiet on this one job will make an accurate '
                        'complaint look like deflation.',
                  ),
                ],
                if (_notComparedNote != null) ...[
                  const SizedBox(height: 6),
                  _GapFootnote(
                    icon: Icons.info_outline_rounded,
                    text: _notComparedNote!,
                  ),
                ],
              ],
            ),
    );
  }
}

class _NothingComparableNote extends StatelessWidget {
  const _NothingComparableNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.remove_circle_outline_rounded,
                  size: 14, color: AdminColors.muted),
              const SizedBox(width: 6),
              Text(
                'Nothing comparable',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.body,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'No rated category on this review had an objective counterpart to '
            'measure against, so there is no evidence either way. This is not '
            'the same as the review agreeing with the record.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AdminColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GapSummaryTile extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  final Color background;
  final IconData icon;
  final String hint;

  const _GapSummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
    required this.icon,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final measured = value != null;
    final magnitude = (value ?? 0).abs();
    final active = measured && magnitude > 0.0005;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? background : AdminColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? color.withOpacity(0.3) : AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 13, color: active ? color : AdminColors.faint),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: active ? color : AdminColors.faint,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            measured ? magnitude.toStringAsFixed(2) : 'No evidence',
            style: GoogleFonts.poppins(
              fontSize: measured ? 20 : 13,
              fontWeight: FontWeight.w700,
              color: active ? color : AdminColors.muted,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            measured ? hint : 'nothing measurable to compare',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AdminColors.muted,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _GapBar extends StatelessWidget {
  final String category;
  final RecordGapDimension dimension;

  const _GapBar({required this.category, required this.dimension});

  @override
  Widget build(BuildContext context) {
    final gap = dimension.gap;
    final inflated = dimension.isInflation;
    final deflated = dimension.isDeflation;
    final color = inflated
        ? AdminColors.red
        : deflated
            ? AdminColors.cyan
            : AdminColors.green;
    final verdict = inflated
        ? 'flatters the record'
        : deflated
            ? 'harsher than the record'
            : 'matches the record';
    final magnitude = (gap ?? 0).abs().clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ratingIcon(category), size: 13, color: AdminColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ratingLabel(category),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AdminColors.body,
                  ),
                ),
              ),
              if (gap != null)
                Text(
                  '${inflated ? '+' : deflated ? '−' : ''}'
                  '${magnitude.toStringAsFixed(2)}  $verdict',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                )
              else
                Text(
                  'no gap recorded',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AdminColors.faint,
                  ),
                ),
            ],
          ),
          if (gap != null) ...[
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, constraints) {
                final half = constraints.maxWidth / 2;
                final width = magnitude * half;
                return SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AdminColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Positioned(
                        left: inflated ? half : half - width,
                        width: width < 2 ? 2 : width,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        left: half - 1,
                        top: -2,
                        bottom: -2,
                        child: Container(width: 2, color: AdminColors.ink),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'claimed ${_fmt(dimension.claimed)}  ·  '
            'record ${_fmt(dimension.actual)}',
            style: GoogleFonts.poppins(fontSize: 10, color: AdminColors.faint),
          ),
        ],
      ),
    );
  }

  String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(2);
}

class _GapFootnote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _GapFootnote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: AdminColors.faint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AdminColors.faint,
              height: 1.4,
            ),
          ),
        ),
      ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthenticityScoreRow(
              label: 'Blended authenticity (stored)',
              value: detail.storedAuthenticityScore,
              analysisUnavailable: true,
            ),
            const SizedBox(height: 8),
            Text(
              'No model verdicts exist — analysis was unavailable (see banner above).',
              style: GoogleFonts.poppins(fontSize: 12, color: AdminColors.faint),
            ),
          ],
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
            _AuthenticityScoreRow(
              label: 'Blended authenticity (stored)',
              value: detail.storedAuthenticityScore,
              analysisUnavailable: detail.analysisUnavailable,
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
          if (c.llm?.isFlaggedFake == true) const _FakeFlagBanner(),
          if (c.disagreements.any) const _DisagreementBanner(),
          if (c.llm != null)
            _LlmCard(
              v: c.llm!,
              analysisUnavailable: detail.analysisUnavailable,
            ),
          if (c.sentimentModel != null) _SentimentCard(v: c.sentimentModel!),
          if (c.disagreementModel != null) _DisagreementCard(v: c.disagreementModel!),
          _BlendReconciliation(detail: detail),
        ],
      ),
    );
  }
}

/// The LLM judge's fake verdict is the whole flag, so this path fires on its
/// own.
class _FakeFlagBanner extends StatelessWidget {
  const _FakeFlagBanner();

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.gpp_bad_rounded, size: 18, color: AdminColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flagged fake by the LLM judge',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The judge read this review as inauthentic. Check it against '
                  'the objective record and the DM thread before you decide.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AdminColors.red,
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

class _DisagreementBanner extends StatelessWidget {
  const _DisagreementBanner();

  @override
  Widget build(BuildContext context) {
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
              'The models disagree on whether the star ratings match the '
              'written review. This is the call you are adjudicating.',
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

/// A blended/LLM authenticity score that may legitimately be absent. Null is
/// "not scored", which is not the same as a bad score, so it never renders as
/// a zero-width bar.
class _AuthenticityScoreRow extends StatelessWidget {
  final String label;
  final double? value;
  final bool analysisUnavailable;

  const _AuthenticityScoreRow({
    required this.label,
    required this.value,
    required this.analysisUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    // An outage wins over whatever is stored: reviews analysed before the
    // backend switched to NULL kept a misleading mid-range score, and that
    // number was never a verdict.
    if (value != null && !analysisUnavailable) {
      return MeasuredScoreBar(label: label, value: value);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AdminColors.body,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminColors.amberBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AdminColors.amberBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded,
                        size: 11, color: AdminColors.amber),
                    const SizedBox(width: 4),
                    Text(
                      analysisUnavailable
                          ? 'Not scored — analysis unavailable'
                          : 'Not scored',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            analysisUnavailable
                ? 'The LLM could not be reached, so nothing was stored. Read '
                    'this as an outage, not as a low score.'
                : 'No score was stored for this review — nothing was recorded, '
                    'which is not the same as scoring badly.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AdminColors.faint,
              height: 1.4,
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
  final bool analysisUnavailable;
  const _LlmCard({required this.v, required this.analysisUnavailable});

  @override
  Widget build(BuildContext context) {
    return _VerdictCard(
      title: 'LLM judge',
      children: [
        _AuthenticityScoreRow(
          label: 'Authenticity',
          value: v.authenticityScore,
          analysisUnavailable: analysisUnavailable,
        ),
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
              toTitleCase(v.label, fallback: 'Unknown'),
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

class _BlendTerm {
  final String label;
  final double weight;
  final double? value;

  /// Rendered in place of the weight when it is 0 — a dropped term, not a term
  /// that happens to contribute nothing.
  final String zeroNote;

  /// The `weight×value` fragment of the arithmetic, null when the value is
  /// missing.
  final String? expression;

  const _BlendTerm({
    required this.label,
    required this.weight,
    required this.value,
    required this.zeroNote,
    required this.expression,
  });

  bool get isLive => weight != 0;
}

class _BlendReconciliation extends StatelessWidget {
  final ReviewModerationDetail detail;
  const _BlendReconciliation({required this.detail});

  static String _f(double d) {
    var s = d.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final w = detail.blendWeights;
    if (!w.hasAll) return const SizedBox.shrink();

    final c = detail.components;
    final llmScore = c?.llm?.authenticityScore;
    final grounded = c?.llm?.answerGroundedness;

    final terms = <_BlendTerm>[
      _BlendTerm(
        label: 'LLM judge',
        weight: w.llm!,
        value: llmScore,
        zeroNote: 'dropped',
        expression:
            llmScore == null ? null : '${_f(w.llm!)}×${_f(llmScore)}',
      ),
      _BlendTerm(
        label: 'Answer groundedness',
        weight: w.answerGroundedness!,
        value: grounded,
        zeroNote: 'skipped',
        expression:
            grounded == null ? null : '${_f(w.answerGroundedness!)}×${_f(grounded)}',
      ),
    ];

    final live = terms.where((t) => t.isLive).toList();
    final computable = live.isNotEmpty && live.every((t) => t.value != null);
    final blended = computable
        ? live.fold<double>(0, (sum, t) => sum + t.weight * t.value!)
        : null;

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
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: terms.map((t) => _WeightChip(term: t)).toList(),
          ),
          const SizedBox(height: 8),
          if (blended != null)
            Text(
              '${live.map((t) => t.expression).join(' + ')} = '
              '${blended.toStringAsFixed(3)}',
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: AdminColors.body,
              ),
            )
          else
            Text(
              'Not every weighted component was stored for this review, so the '
              'arithmetic cannot be reproduced here.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AdminColors.muted,
                height: 1.4,
              ),
            ),
          if (w.groundednessDropped) ...[
            const SizedBox(height: 4),
            Text(
              'The reviewer skipped the targeted question, so groundedness '
              'carries no weight here and the LLM judge carries all of it.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AdminColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeightChip extends StatelessWidget {
  final _BlendTerm term;
  const _WeightChip({required this.term});

  @override
  Widget build(BuildContext context) {
    final live = term.isLive;
    final color = live ? AdminColors.primary : AdminColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: live ? Colors.white : AdminColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: live ? AdminColors.primary.withOpacity(0.25) : AdminColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            term.label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: live ? AdminColors.body : AdminColors.muted,
              decoration: live ? null : TextDecoration.lineThrough,
              decorationColor: AdminColors.muted,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            live
                ? _BlendReconciliation._f(term.weight)
                : term.zeroNote,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
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
                          toTitleCase(r.source),
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
                      'trust score / 100',
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
                              m.senderId ?? 'Unknown',
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
  final Future<void> Function() onRuled;

  const _ActionsBar({
    required this.detail,
    required this.isClientReview,
    required this.onRuled,
  });

  /// Already suppressed by the pipeline: upholding records agreement with it
  /// rather than changing the review's status.
  bool get _alreadySuppressed => detail.holdLevel == 'suppressed';

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
      title: _alreadySuppressed
          ? 'Confirm this suppression?'
          : 'Uphold this hold?',
      submitLabel: _alreadySuppressed ? 'Confirm suppression' : 'Uphold hold',
      accentColor: AdminColors.red,
      icon: Icons.gpp_maybe_rounded,
      warningText: _alreadySuppressed
          ? 'The review is already suppressed and stays that way. This records '
              'your agreement with the pipeline for the audit trail; nothing '
              'changes for either party.'
          : 'This suppresses the review permanently. It will not be published, '
              'and the reviewer was already told it was held.',
      onSubmit: (reason) => isClientReview
          ? admin.upholdClientReview(id, reason: reason)
          : admin.upholdReview(id, reason: reason),
    );
    if (outcome == null || !outcome.success || !context.mounted) return;
    if (_alreadySuppressed) {
      // Nothing moved — the review was suppressed before and still is — so the
      // dialog stays open and reloads to show the ruling that was just filed.
      AppToast.success('Ruling recorded.');
      await onRuled();
    } else {
      Navigator.pop(context);
      AppToast.success('Hold upheld — review suppressed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rulings = detail.adminRulings;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AdminColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // A second uphold would only file a duplicate label for the same
              // case, so it goes once anything is on record. Publishing stays:
              // override_publish still accepts a suppressed review server-side
              // and is the only appeal path out of this dialog.
              if (rulings.isEmpty) ...[
                Expanded(
                  child: AdminActionButton(
                    label: _alreadySuppressed
                        ? 'Confirm suppression'
                        : 'Uphold hold',
                    icon: Icons.gpp_maybe_rounded,
                    color: AdminColors.red,
                    style: AdminActionStyle.outlined,
                    onPressed: () => _uphold(context),
                  ),
                ),
                const SizedBox(width: 10),
              ],
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
        ],
      ),
    );
  }
}

/// The rulings already on file for this review, oldest first.
///
/// The log this comes from is gitignored, so its absence proves nothing and
/// this banner is history only — it never blocks the publish path below it.
class _RulingHistoryBanner extends StatelessWidget {
  final List<AdminRuling> rulings;

  const _RulingHistoryBanner({required this.rulings});

  String _label(AdminRuling r) {
    if (r.confirmedExistingSuppression) return 'Suppression confirmed';
    return r.isUphold ? 'Hold upheld' : 'Published anyway';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AdminColors.amberBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.amberBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 14, color: AdminColors.amber),
              const SizedBox(width: 6),
              Text(
                rulings.length == 1
                    ? 'Already ruled on'
                    : 'Already ruled on (${rulings.length})',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.amber,
                ),
              ),
            ],
          ),
          for (final r in rulings) ...[
            const SizedBox(height: 8),
            Text(
              '${_label(r)} · ${r.adminEmail ?? 'admin'}'
              '${r.loggedAt != null ? ' · ${_ruledAgo(r.loggedAt!)}' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            // Quoted in full: the reason is the whole record of why, and a
            // truncated one is worse than none for an audit trail.
            Text(
              '“${r.reason}”',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AdminColors.body,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _ruledAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
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
