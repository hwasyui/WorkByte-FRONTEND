import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/providers/admin_provider.dart';
import 'package:workbyte_app/screens/admin/pages/admin_appeals_page.dart';

// ---------------------------------------------------------------------------
// Fake provider — no HTTP calls
// ---------------------------------------------------------------------------

class _FakeAdminProvider extends AdminProvider {
  List<Map<String, dynamic>> _fakeAppeals = [];
  bool _fakeIsAppealsLoading = false;
  bool _fakeResolveResult = true;

  int resolveAppealCalls = 0;
  String? lastResolvedId;
  String? lastResolvedAction;
  String? lastAdminNote;

  void setupAppeals(List<Map<String, dynamic>> appeals) {
    _fakeAppeals = List.from(appeals);
    notifyListeners();
  }

  void setLoading(bool value) {
    _fakeIsAppealsLoading = value;
    notifyListeners();
  }

  void setResolveResult(bool value) => _fakeResolveResult = value;

  @override
  List<Map<String, dynamic>> get appeals => _fakeAppeals;

  @override
  bool get isAppealsLoading => _fakeIsAppealsLoading;

  @override
  Future<void> loadAppeals({String? status, int page = 1}) async {}

  @override
  Future<bool> resolveAppeal(
    String appealId,
    String action, {
    String? adminNote,
  }) async {
    resolveAppealCalls++;
    lastResolvedId = appealId;
    lastResolvedAction = action;
    lastAdminNote = adminNote;
    return _fakeResolveResult;
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildTestWidget(_FakeAdminProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider<AdminProvider>.value(
      value: provider,
      child: const Scaffold(body: AdminAppealsPage()),
    ),
  );
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _pendingJobAppeal = <String, dynamic>{
  'appeal_id': 'appeal-job-1',
  'status': 'pending',
  'target_type': 'job',
  'user_name': 'Alice User',
  'user_email': 'alice@test.com',
  'message': 'Please reconsider my job post.',
  'job_title': 'Flutter Developer',
  'created_at': '2024-04-01T10:00:00',
  'actioned_at': null,
  'admin_note': null,
  'appeal_attempt': 1,
};

const _pendingAccountAppeal = <String, dynamic>{
  'appeal_id': 'appeal-acc-2',
  'status': 'pending',
  'target_type': 'user',
  'user_name': 'Bob User',
  'user_email': 'bob@test.com',
  'message': 'I did not violate any rules.',
  'job_title': null,
  'created_at': '2024-04-02T12:00:00',
  'actioned_at': null,
  'admin_note': null,
  'appeal_attempt': 2,
};

const _approvedAppeal = <String, dynamic>{
  'appeal_id': 'appeal-job-3',
  'status': 'approved',
  'target_type': 'job',
  'user_name': 'Carol User',
  'user_email': 'carol@test.com',
  'message': 'My job post is completely legitimate.',
  'job_title': 'Backend Engineer',
  'created_at': '2024-03-15T08:00:00',
  'actioned_at': '2024-03-16T09:00:00',
  'admin_note': 'Verified and approved.',
  'appeal_attempt': 1,
};

const _rejectedAppeal = <String, dynamic>{
  'appeal_id': 'appeal-acc-4',
  'status': 'rejected',
  'target_type': 'user',
  'user_name': 'Dave User',
  'user_email': 'dave@test.com',
  'message': 'Please unban me.',
  'job_title': null,
  'created_at': '2024-03-10T07:00:00',
  'actioned_at': '2024-03-11T10:00:00',
  'admin_note': 'Violation confirmed, ban upheld.',
  'appeal_attempt': 2,
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AdminAppealsPage', () {
    late _FakeAdminProvider provider;

    setUp(() => provider = _FakeAdminProvider());
    tearDown(() => provider.dispose());

    // ── Page structure ──────────────────────────────────────────────────────

    testWidgets('renders Pending and Resolved tabs', (tester) async {
      await tester.pumpWidget(_buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pending'), findsOneWidget);
      expect(find.textContaining('Resolved'), findsOneWidget);
    });

    testWidgets('shows loading indicator when isAppealsLoading is true',
        (tester) async {
      provider.setLoading(true);
      await tester.pumpWidget(_buildTestWidget(provider));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tab labels show correct counts from appeals data',
        (tester) async {
      provider.setupAppeals([_pendingJobAppeal, _pendingAccountAppeal]);
      await tester.pumpWidget(_buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Pending (2)'), findsOneWidget);
      expect(find.text('Resolved (0)'), findsOneWidget);
    });

    testWidgets('tab counts update when both pending and resolved exist',
        (tester) async {
      provider.setupAppeals([
        _pendingJobAppeal,
        _approvedAppeal,
        _rejectedAppeal,
      ]);
      await tester.pumpWidget(_buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Pending (1)'), findsOneWidget);
      expect(find.text('Resolved (2)'), findsOneWidget);
    });

    // ── Pending tab ─────────────────────────────────────────────────────────

    group('Pending tab', () {
      testWidgets('shows empty state when there are no pending appeals',
          (tester) async {
        provider.setupAppeals([_approvedAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('No pending appeals'), findsOneWidget);
      });

      testWidgets('shows appeal card for a pending job appeal', (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Alice User'), findsOneWidget);
        expect(find.text('Please reconsider my job post.'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
      });

      testWidgets('shows Job subtitle with title for job appeal', (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Job: Flutter Developer'), findsOneWidget);
      });

      testWidgets('shows Account Appeal subtitle for account appeal',
          (tester) async {
        provider.setupAppeals([_pendingAccountAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Account Appeal'), findsOneWidget);
      });

      testWidgets('shows correct attempt counter on card', (tester) async {
        provider.setupAppeals([_pendingAccountAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Attempt 2/2'), findsOneWidget);
      });

      testWidgets('shows Approve and Reject action buttons for pending appeals',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Approve'), findsOneWidget);
        expect(find.text('Reject'), findsOneWidget);
      });

      testWidgets('shows submitted date on pending appeal card', (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.textContaining('Submitted'), findsOneWidget);
        expect(find.textContaining('Apr 1, 2024'), findsOneWidget);
      });
    });

    // ── Resolved tab ────────────────────────────────────────────────────────

    group('Resolved tab', () {
      testWidgets('shows empty state when there are no resolved appeals',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Resolved (0)'));
        await tester.pumpAndSettle();

        expect(find.text('No resolved appeals'), findsOneWidget);
      });

      testWidgets('shows approved appeal card with admin note', (tester) async {
        provider.setupAppeals([_approvedAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Resolved (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Carol User'), findsOneWidget);
        expect(find.text('Approved'), findsOneWidget);
        expect(find.text('Verified and approved.'), findsOneWidget);
      });

      testWidgets('shows resolved date on appeal card', (tester) async {
        provider.setupAppeals([_approvedAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Resolved (1)'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Resolved Mar 16, 2024'), findsOneWidget);
      });

      testWidgets('no Approve or Reject buttons on resolved appeal cards',
          (tester) async {
        provider.setupAppeals([_approvedAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Resolved (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Approve'), findsNothing);
        expect(find.text('Reject'), findsNothing);
      });

      testWidgets('shows rejected appeal with Rejected status and admin note',
          (tester) async {
        provider.setupAppeals([_rejectedAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Resolved (1)'));
        await tester.pumpAndSettle();

        expect(find.text('Dave User'), findsOneWidget);
        expect(find.text('Rejected'), findsOneWidget);
        expect(find.text('Violation confirmed, ban upheld.'), findsOneWidget);
      });

      testWidgets('correctly separates multiple pending and resolved appeals',
          (tester) async {
        provider.setupAppeals([
          _pendingJobAppeal,
          _pendingAccountAppeal,
          _approvedAppeal,
          _rejectedAppeal,
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        // Pending tab is active — pending appeals visible
        expect(find.text('Alice User'), findsOneWidget);
        expect(find.text('Bob User'), findsOneWidget);
        expect(find.text('Carol User'), findsNothing);
        expect(find.text('Dave User'), findsNothing);
      });
    });

    // ── Resolve dialog ──────────────────────────────────────────────────────

    group('Approve/Reject dialog', () {
      testWidgets('approve dialog title and job-restore text for job appeal',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        expect(find.text('Approve Appeal?'), findsOneWidget);
        expect(
          find.text('Approving will reopen the job post.'),
          findsOneWidget,
        );
      });

      testWidgets('approve dialog shows account-restore text for account appeal',
          (tester) async {
        provider.setupAppeals([_pendingAccountAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        expect(
          find.text("Approving will restore Bob User's account."),
          findsOneWidget,
        );
      });

      testWidgets('reject dialog title and closed-job text for job appeal',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();

        expect(find.text('Reject Appeal?'), findsOneWidget);
        expect(
          find.text('Rejecting will keep the job post closed.'),
          findsOneWidget,
        );
      });

      testWidgets('reject dialog shows closed-account text for account appeal',
          (tester) async {
        provider.setupAppeals([_pendingAccountAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();

        expect(
          find.text("Rejecting will keep Bob User's account closed."),
          findsOneWidget,
        );
      });

      testWidgets('dialog shows Cancel button and confirm button', (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        expect(find.text('Cancel'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Approve'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('tapping Cancel dismisses dialog without calling resolveAppeal',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(provider.resolveAppealCalls, 0);
        expect(find.byType(AlertDialog), findsNothing);
      });

      testWidgets(
          'confirming Approve calls resolveAppeal with appeal ID and approve',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Approve'),
          ),
        );
        await tester.pumpAndSettle();

        expect(provider.resolveAppealCalls, 1);
        expect(provider.lastResolvedId, 'appeal-job-1');
        expect(provider.lastResolvedAction, 'approve');
      });

      testWidgets(
          'confirming Reject calls resolveAppeal with appeal ID and reject',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Reject'),
          ),
        );
        await tester.pumpAndSettle();

        expect(provider.resolveAppealCalls, 1);
        expect(provider.lastResolvedId, 'appeal-job-1');
        expect(provider.lastResolvedAction, 'reject');
      });

      testWidgets('successful approve shows green success snackbar',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        provider.setResolveResult(true);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Approve'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Appeal approved successfully'), findsOneWidget);
      });

      testWidgets('successful reject shows snackbar with rejected message',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        provider.setResolveResult(true);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Reject'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Appeal rejected successfully'), findsOneWidget);
      });

      testWidgets('failed resolve shows error snackbar', (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        provider.setResolveResult(false);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Approve'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Failed to process appeal'), findsOneWidget);
      });

      testWidgets('admin note entered in dialog is passed to resolveAppeal',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField),
          'Looks good, approving.',
        );

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Approve'),
          ),
        );
        await tester.pumpAndSettle();

        expect(provider.lastAdminNote, 'Looks good, approving.');
      });

      testWidgets('empty admin note field results in null adminNote',
          (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        // Leave note field empty and confirm
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Approve'),
          ),
        );
        await tester.pumpAndSettle();

        expect(provider.lastAdminNote, isNull);
      });

      testWidgets('whitespace-only admin note is treated as null', (tester) async {
        provider.setupAppeals([_pendingJobAppeal]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '   ');

        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Approve'),
          ),
        );
        await tester.pumpAndSettle();

        expect(provider.lastAdminNote, isNull);
      });
    });
  });
}
