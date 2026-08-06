import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/models/admin_review_moderation_model.dart';
import 'package:workbyte_app/providers/admin_provider.dart';
import 'package:workbyte_app/screens/admin/pages/review_moderation_detail_dialog.dart';

class _FakeAdminProvider extends AdminProvider {
  Map<String, dynamic> payload = {};

  @override
  Future<ReviewModerationDetail?> fetchReviewModerationDetail(String reviewId) =>
      Future.value(
        ReviewModerationDetail.fromJson(payload, isClientReview: false),
      );

  @override
  Future<ReviewModerationDetail?> fetchClientReviewModerationDetail(
    String reviewId,
  ) =>
      Future.value(
        ReviewModerationDetail.fromJson(payload, isClientReview: true),
      );
}

Map<String, dynamic> _basePayload({
  Map<String, dynamic>? review,
  Map<String, dynamic>? ratings,
  Map<String, dynamic>? components,
  Map<String, dynamic>? blendWeights,
  Map<String, dynamic>? telemetry,
  Map<String, dynamic>? subjectLifetimeScores,
  Map<String, dynamic>? recordGaps,
  bool analysisUnavailable = false,
}) {
  return {
    'review': review ??
        {
          'id': 'r1',
          'status': 'held',
          'overall_comment': 'Went silent for two weeks.',
          'authenticity_score': 0.42,
        },
    'ratings': ratings ??
        {
          'categories': [
            {'category': 'responsiveness', 'score': 5.0},
            {'category': 'professionalism', 'score': 4.0},
          ],
          'average': 4.5,
          'count': 2,
        },
    'components': components,
    'blend_weights':
        blendWeights ?? {'llm': 0.8, 'authenticity_model': 0.0, 'answer_groundedness': 0.2},
    'telemetry': telemetry ?? const {},
    'subject_lifetime_scores': subjectLifetimeScores,
    'record_gaps': recordGaps,
    'reviewer': {'name': 'Dina R.', 'email': 'dina@example.com'},
    'dm_thread': const [],
    'hold_level': 'flagged',
    'analysis_unavailable': analysisUnavailable,
  };
}

/// The payload still carries `authenticity_model`; the UI must ignore it.
Map<String, dynamic> _components({
  double? llmAuthenticity = 0.31,
  bool llmFake = false,
  bool disagreementFake = false,
  bool mismatch = false,
}) {
  return {
    'llm': {
      'authenticity_score': llmAuthenticity,
      'is_flagged_fake': llmFake,
      'answer_groundedness': 0.66,
    },
    'authenticity_model': {
      'fake_probability': 0.08,
      'fake_probability_calibrated': 0.11,
      'is_likely_fake': true,
      'threshold': 0.75,
      'model_used': 'authenticity_v3',
      'advisory_only': true,
    },
    'disagreements': {'fake': disagreementFake, 'mismatch': mismatch},
  };
}

Widget _host(AdminProvider provider, {required bool isClientReview}) {
  return ChangeNotifierProvider<AdminProvider>.value(
    value: provider,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showReviewModerationDialog(
              context,
              id: 'r1',
              isClientReview: isClientReview,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  _FakeAdminProvider provider, {
  required bool isClientReview,
}) async {
  // Tall so the dialog's ListView builds every section, and narrow enough that
  // the contradiction pane takes its stacked layout — its wide layout has a
  // pre-existing 4.5px overflow that is outside the scope of these tests.
  tester.view.physicalSize = const Size(420, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(provider, isClientReview: isClientReview));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _FakeAdminProvider provider;
  setUp(() => provider = _FakeAdminProvider());

  group('model parsing', () {
    test('a null authenticity_score parses instead of throwing', () {
      final detail = ReviewModerationDetail.fromJson(
        _basePayload(
          review: {'id': 'r1', 'authenticity_score': null},
          components: _components(llmAuthenticity: null),
        ),
        isClientReview: false,
      );

      expect(detail.storedAuthenticityScore, isNull);
      expect(detail.components?.llm?.authenticityScore, isNull);
    });

    test('record_gaps parses per-dimension entries', () {
      final gaps = RecordGaps.fromJson({
        'inflation': 0.6,
        'deflation': 0.0,
        'dimensions_compared': 2,
        'per_dimension': {
          'responsiveness': {'claimed': 1.0, 'actual': 0.4, 'gap': 0.6},
        },
      });

      expect(gaps.inflation, 0.6);
      expect(gaps.dimensionsCompared, 2);
      expect(gaps.perDimension['responsiveness']!.gap, 0.6);
      expect(gaps.perDimension['responsiveness']!.isInflation, isTrue);
      expect(gaps.nothingComparable, isFalse);
    });

    test('null inflation and deflation means nothing comparable', () {
      final gaps = RecordGaps.fromJson({
        'inflation': null,
        'deflation': null,
        'dimensions_compared': 0,
        'per_dimension': const {},
      });

      expect(gaps.nothingComparable, isTrue);
    });

    test('a missing record_gaps key yields an empty, non-null RecordGaps', () {
      final detail = ReviewModerationDetail.fromJson(
        _basePayload(),
        isClientReview: false,
      );

      expect(detail.recordGaps.nothingComparable, isTrue);
    });

    test('the authenticity classifier block is not parsed at all', () {
      final detail = ReviewModerationDetail.fromJson(
        _basePayload(components: _components()),
        isClientReview: false,
      );

      expect(detail.components, isNotNull);
      expect(detail.components?.llm, isNotNull);
      expect(
        detail.blendWeights.llm,
        0.8,
        reason: 'the surviving weights still parse',
      );
    });
  });

  group('client lifetime record', () {
    testWidgets('drops the on-time row and labels churn, not revision rate',
        (tester) async {
      provider.payload = _basePayload(
        subjectLifetimeScores: {
          'responsiveness_score': 0.4,
          'revision_rate_score': 0.55,
          'dispute_fairness_score': 0.9,
          'has_persisted_trust_score': true,
        },
      );
      await _open(tester, provider, isClientReview: true);

      expect(find.text('Client lifetime record'), findsOneWidget);
      expect(find.text('On-time delivery'), findsNothing);
      expect(find.text('Revision rate'), findsNothing);
      expect(
        find.textContaining('Requirement churn', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Dispute fairness', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('renders unmeasured lifetime fields as Not measured',
        (tester) async {
      provider.payload = _basePayload(
        subjectLifetimeScores: {
          'responsiveness_score': null,
          'revision_rate_score': null,
          'dispute_fairness_score': 0.9,
          'has_persisted_trust_score': true,
        },
      );
      await _open(tester, provider, isClientReview: true);

      expect(find.text('Not measured'), findsNWidgets(2));
    });

    testWidgets('notes when the client has no published review yet',
        (tester) async {
      provider.payload = _basePayload(
        subjectLifetimeScores: {
          'responsiveness_score': 0.4,
          'has_persisted_trust_score': false,
        },
      );
      await _open(tester, provider, isClientReview: true);

      expect(
        find.textContaining('no published review yet'),
        findsOneWidget,
      );
    });

    testWidgets('freelancer reviews keep the on-time row', (tester) async {
      provider.payload = _basePayload(
        telemetry: {
          'on_time_score': 0.9,
          'on_time_measurable': true,
          'revision_rate_score': 0.7,
          'responsiveness_score': 0.5,
        },
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Objective contract record'), findsOneWidget);
      expect(
        find.textContaining('On-time delivery', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Revision rate', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('record gaps', () {
    testWidgets('shows direction, magnitude and the claimed/actual pair',
        (tester) async {
      provider.payload = _basePayload(
        recordGaps: {
          'inflation': 0.6,
          'deflation': 0.0,
          'dimensions_compared': 2,
          'per_dimension': {
            'responsiveness': {'claimed': 1.0, 'actual': 0.4, 'gap': 0.6},
          },
        },
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Claimed vs. record'), findsOneWidget);
      expect(find.text('INFLATION'), findsOneWidget);
      expect(find.text('DEFLATION'), findsOneWidget);
      expect(find.text('0.60'), findsOneWidget);
      expect(find.textContaining('flatters the record'), findsWidgets);
      expect(find.textContaining('claimed 1.00'), findsOneWidget);
      expect(find.text('2 categories compared'), findsOneWidget);
    });

    testWidgets('marks a harsher-than-record gap as deflation', (tester) async {
      provider.payload = _basePayload(
        recordGaps: {
          'inflation': 0.0,
          'deflation': 0.5,
          'dimensions_compared': 1,
          'per_dimension': {
            'responsiveness': {'claimed': 0.0, 'actual': 0.5, 'gap': -0.5},
          },
        },
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.textContaining('harsher than the record'), findsWidgets);
      expect(find.text('1 category compared'), findsOneWidget);
    });

    testWidgets('says nothing comparable rather than showing a zero',
        (tester) async {
      provider.payload = _basePayload(
        recordGaps: {
          'inflation': null,
          'deflation': null,
          'dimensions_compared': 0,
          'per_dimension': const {},
        },
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Nothing comparable'), findsOneWidget);
      expect(find.textContaining('no evidence either way'), findsOneWidget);
    });

    testWidgets('explains uncompared categories and the lifetime caveat',
        (tester) async {
      provider.payload = _basePayload(
        ratings: {
          'categories': [
            {'category': 'responsiveness', 'score': 5.0},
            {'category': 'communication', 'score': 5.0},
            {'category': 'professionalism', 'score': 5.0},
          ],
          'average': 5.0,
          'count': 3,
        },
        subjectLifetimeScores: {'responsiveness_score': 0.4},
        recordGaps: {
          'inflation': 0.6,
          'deflation': 0.0,
          'dimensions_compared': 1,
          'per_dimension': {
            'responsiveness': {'claimed': 1.0, 'actual': 0.4, 'gap': 0.6},
          },
        },
      );
      await _open(tester, provider, isClientReview: true);

      expect(find.textContaining('Not compared: Communication'), findsOneWidget);
      expect(find.textContaining('double-count'), findsOneWidget);
      expect(find.textContaining('lifetime average'), findsOneWidget);
    });
  });

  group('authenticity score', () {
    testWidgets('renders a null score as not scored, never as an empty bar',
        (tester) async {
      provider.payload = _basePayload(
        review: {'id': 'r1', 'authenticity_score': null},
        components: _components(llmAuthenticity: null),
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Not scored'), findsOneWidget);
      expect(
        find.textContaining('not the same as scoring badly'),
        findsOneWidget,
      );
    });

    testWidgets('names the outage when analysis was unavailable',
        (tester) async {
      provider.payload = _basePayload(
        review: {'id': 'r1', 'authenticity_score': null},
        analysisUnavailable: true,
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Not scored — analysis unavailable'), findsOneWidget);
    });

    testWidgets('trusts analysis_unavailable over a stale stored score',
        (tester) async {
      provider.payload = _basePayload(
        review: {'id': 'r1', 'authenticity_score': 0.499},
        analysisUnavailable: true,
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Not scored — analysis unavailable'), findsOneWidget);
      expect(find.text('0.499'), findsNothing);
    });
  });

  group('authenticity classifier is absent', () {
    testWidgets('never appears, even when the payload still carries it',
        (tester) async {
      provider.payload = _basePayload(
        components: _components(disagreementFake: true),
      );
      await _open(tester, provider, isClientReview: false);

      for (final forbidden in [
        'classifier',
        'Authenticity classifier',
        'Authenticity model',
        'Fake probability',
        'authenticity_v3',
        'Advisory',
        'advisory',
        'retired',
        'uncalibrated',
        'Above threshold — likely fake',
      ]) {
        expect(
          find.textContaining(forbidden),
          findsNothing,
          reason: 'the classifier must not be mentioned: "$forbidden"',
        );
      }
    });

    testWidgets('a fake disagreement with the hidden model raises no banner',
        (tester) async {
      provider.payload = _basePayload(
        components: _components(disagreementFake: true),
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.textContaining('models disagree'), findsNothing);
    });

    testWidgets('a sentiment mismatch still raises its banner', (tester) async {
      provider.payload = _basePayload(components: _components(mismatch: true));
      await _open(tester, provider, isClientReview: false);

      expect(
        find.textContaining('disagree on whether the star ratings match'),
        findsOneWidget,
      );
    });
  });

  group('blend weights', () {
    testWidgets('marks groundedness as skipped when the question was not answered',
        (tester) async {
      provider.payload = _basePayload(
        components: _components(),
        blendWeights: {
          'llm': 1.0,
          'authenticity_model': 0.0,
          'answer_groundedness': 0.0,
        },
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.text('skipped'), findsOneWidget);
      expect(
        find.textContaining('skipped the targeted question'),
        findsOneWidget,
      );
    });
  });

  group('fake flag', () {
    testWidgets('renders the LLM fake path with the banner and the chip',
        (tester) async {
      provider.payload = _basePayload(
        components: _components(llmFake: true),
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Flagged fake by the LLM judge'), findsOneWidget);
      expect(
        find.textContaining('read this review as inauthentic'),
        findsOneWidget,
      );
      expect(find.text('Flagged fake'), findsOneWidget);
    });

    testWidgets('stays quiet when the LLM did not flag the review',
        (tester) async {
      provider.payload = _basePayload(
        components: _components(llmFake: false, disagreementFake: true),
      );
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Flagged fake by the LLM judge'), findsNothing);
      expect(find.text('Flagged fake'), findsNothing);
    });
  });

  group('ruled state', () {
    testWidgets('an empty ruling list leaves the queue action bar alone',
        (tester) async {
      provider.payload = _basePayload()..['admin_rulings'] = const [];
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Uphold hold'), findsOneWidget);
      expect(find.text('Publish anyway'), findsOneWidget);
      expect(find.text('Already ruled on'), findsNothing);
    });

    testWidgets('a ruling on file replaces uphold with the history banner',
        (tester) async {
      provider.payload = _basePayload()
        ..['hold_level'] = 'suppressed'
        ..['admin_rulings'] = [
          {
            'action': 'uphold',
            'admin_user_id': 'a1',
            'admin_email': 'mod@workbyte.test',
            'reason': 'Reviewer admitted the client asked for five stars.',
            'prior_status': 'flagged',
            'logged_at': DateTime.now()
                .toUtc()
                .subtract(const Duration(hours: 3))
                .toIso8601String(),
          },
        ];
      await _open(tester, provider, isClientReview: false);

      expect(find.text('Already ruled on'), findsOneWidget);
      expect(
        find.textContaining('Hold upheld · mod@workbyte.test · 3h ago'),
        findsOneWidget,
      );
      expect(
        find.text('“Reviewer admitted the client asked for five stars.”'),
        findsOneWidget,
      );
      // A second uphold would only file a duplicate label; publishing stays as
      // the appeal path out of a suppressed review.
      expect(find.text('Uphold hold'), findsNothing);
      expect(find.text('Confirm suppression'), findsNothing);
      expect(find.text('Publish anyway'), findsOneWidget);
    });

    testWidgets('a long reason scrolls with the content instead of overflowing',
        (tester) async {
      provider.payload = _basePayload()
        ..['admin_rulings'] = [
          {
            'action': 'uphold',
            'admin_email': 'mod@workbyte.test',
            // Quoted in full and unbounded in height — in the fixed action bar
            // this pushed the dialog past the viewport.
            'reason': 'The reviewer confirmed over DM that the client offered '
                'a bonus in exchange for five stars, which matches the '
                'coercion flag, and the record shows two revisions the review '
                'never mentions. Suppression stands. ' * 4,
            'prior_status': 'flagged',
            'logged_at': DateTime.now().toUtc().toIso8601String(),
          },
        ];

      // A real dialog viewport, not the tall one _open uses to force every
      // section to build.
      tester.view.physicalSize = const Size(420, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(provider, isClientReview: false));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Still reachable, and the action bar below it is still on screen.
      expect(find.text('Already ruled on'), findsOneWidget);
      expect(find.text('Publish anyway'), findsOneWidget);
    });

    testWidgets('an uphold of an already-suppressed review reads as agreement',
        (tester) async {
      provider.payload = _basePayload()
        ..['hold_level'] = 'suppressed'
        ..['admin_rulings'] = [
          {
            'action': 'uphold',
            'admin_email': null,
            'reason': 'Pipeline call was right, nothing to change.',
            'prior_status': 'suppressed',
            'logged_at': DateTime.now().toUtc().toIso8601String(),
          },
        ];
      await _open(tester, provider, isClientReview: false);

      // Not "Hold upheld": nothing was upheld, the suppression was confirmed.
      // And a null email falls back rather than printing "null".
      expect(
        find.textContaining('Suppression confirmed · admin · just now'),
        findsOneWidget,
      );
    });
  });
}
