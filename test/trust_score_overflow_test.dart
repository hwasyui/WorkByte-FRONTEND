import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workbyte_app/models/client_review_model.dart';
import 'package:workbyte_app/models/review_model.dart';
import 'package:workbyte_app/widgets/review_card.dart';
import 'package:workbyte_app/widgets/section_header.dart';
import 'package:workbyte_app/widgets/trust_score_card.dart';

/// The review & trust score cards are built from fixed-width label columns and
/// unflexible header rows, which is exactly the shape that produces a
/// RenderFlex overflow on a narrow phone or at a large text scale. These tests
/// render them at the sizes users actually have.
void main() {
  /// Narrowest phone we care about; the widest of the group is a small tablet.
  const narrow = Size(320, 900);
  const typical = Size(360, 900);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = typical,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  TrustScore freelancerScore({
    double? onTime = 0.9,
    double? revision = 0.8,
    double? responsiveness = 0.75,
    double? communication = 0.85,
  }) => TrustScore(
    freelancerId: 'f1',
    overallScore: 82,
    onTimeScore: onTime,
    revisionRateScore: revision,
    responsivenessScore: responsiveness,
    communicationSentiment: communication,
    totalReviews: 12,
    confidence: 'established',
    displayStarAvg: 4.6,
    sentimentDistribution: const SentimentDistribution(
      positive: 8,
      neutral: 3,
      negative: 1,
      unclassified: 2,
      total: 14,
    ),
  );

  group('RatingSummaryCard', () {
    testWidgets('header fits on a 360pt phone with an established badge', (
      tester,
    ) async {
      await pump(
        tester,
        const RatingSummaryCard(
          averageRating: 4.6,
          totalReviews: 128,
          confidence: 'established',
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('header fits on a 320pt phone', (tester) async {
      await pump(
        tester,
        const RatingSummaryCard(
          averageRating: 4.6,
          totalReviews: 128,
          confidence: 'established',
        ),
        size: narrow,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('header fits at 1.5x text scale', (tester) async {
      await pump(
        tester,
        const RatingSummaryCard(
          averageRating: 4.6,
          totalReviews: 128,
          confidence: 'established',
        ),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('no-rating state still fits', (tester) async {
      await pump(
        tester,
        const RatingSummaryCard(
          averageRating: 0.0,
          totalReviews: 0,
          confidence: 'new',
        ),
        size: narrow,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('TrustScoreCard', () {
    testWidgets('fits on a 320pt phone', (tester) async {
      await pump(
        tester,
        TrustScoreCard(trustScore: freelancerScore()),
        size: narrow,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at 1.5x text scale with null-score hints', (
      tester,
    ) async {
      await pump(
        tester,
        TrustScoreCard(
          trustScore: freelancerScore(
            onTime: null,
            revision: null,
            responsiveness: null,
            communication: null,
          ),
          isOwnProfile: true,
        ),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ClientTrustScoreCard', () {
    ClientTrustScore clientScore() => ClientTrustScore(
      clientId: 'c1',
      trustScore: 71,
      responsivenessScore: 0.8,
      communicationSentiment: 0.6,
      disputeFairnessScore: 0.9,
      totalReviewsReceived: 9,
      confidence: 'building',
      displayStarAvg: 4.1,
      sentimentDistribution: const SentimentDistribution(
        positive: 5,
        neutral: 2,
        negative: 2,
        unclassified: 0,
        total: 9,
      ),
    );

    testWidgets('fits on a 320pt phone', (tester) async {
      await pump(
        tester,
        ClientTrustScoreCard(trustScore: clientScore()),
        size: narrow,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at 1.5x text scale', (tester) async {
      await pump(
        tester,
        ClientTrustScoreCard(trustScore: clientScore(), isOwnProfile: true),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SentimentDistributionCard', () {
    testWidgets('fits on a 320pt phone', (tester) async {
      await pump(
        tester,
        const SentimentDistributionCard(
          distribution: SentimentDistribution(
            positive: 88,
            neutral: 33,
            negative: 11,
            unclassified: 22,
            total: 154,
          ),
          confidence: 'established',
        ),
        size: narrow,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at 1.5x text scale', (tester) async {
      await pump(
        tester,
        const SentimentDistributionCard(
          distribution: SentimentDistribution(
            positive: 88,
            neutral: 33,
            negative: 11,
            unclassified: 22,
            total: 154,
          ),
          confidence: 'established',
        ),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ReviewCard', () {
    Review review() => Review(
      id: 'r1',
      contractId: 'ct1',
      reviewerId: 'rev1',
      freelancerId: 'f1',
      inferredCategory: 'general',
      isAnonymous: false,
      status: 'published',
      publishedAt: DateTime(2026, 1, 1),
      sentiment: 'positive',
      ratings: const [
        ReviewRating(
          id: 'rr1',
          reviewId: 'r1',
          category: 'communication',
          score: 4.5,
        ),
        ReviewRating(id: 'rr2', reviewId: 'r1', category: 'quality', score: 5.0),
      ],
      writtenContent: const ReviewWrittenContent(
        id: 'wc1',
        reviewId: 'r1',
        overallComment: 'Great to work with.',
      ),
    );

    testWidgets('a very long reviewer name does not overflow the header', (
      tester,
    ) async {
      await pump(
        tester,
        ReviewCard(
          review: review(),
          reviewerName:
              'Bartholomew Fitzgerald-Montgomery III of the Northern Reaches',
        ),
        size: narrow,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long reviewer name fits at 1.5x text scale', (tester) async {
      await pump(
        tester,
        ReviewCard(
          review: review(),
          reviewerName: 'Bartholomew Fitzgerald-Montgomery III',
        ),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SectionHeader', () {
    testWidgets('a long title does not overflow the "View all" action', (
      tester,
    ) async {
      await pump(
        tester,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SectionHeader(
            title: 'Recommended Jobs Matched To Your Skills',
            onViewAll: null,
          ),
        ),
        size: narrow,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at 1.5x text scale', (tester) async {
      await pump(
        tester,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SectionHeader(title: 'Recommended Jobs', onViewAll: null),
        ),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryRatingsCard', () {
    const averages = {
      'communication': 4.5,
      'quality': 4.8,
      'professionalism': 4.2,
      'value_for_money': 3.9,
      'timeliness': 4.7,
    };

    testWidgets('fits on a 320pt phone', (tester) async {
      await pump(
        tester,
        const CategoryRatingsCard(categoryAverages: averages),
        size: narrow,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('fits at 1.5x text scale', (tester) async {
      await pump(
        tester,
        const CategoryRatingsCard(categoryAverages: averages),
        textScale: 1.5,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
