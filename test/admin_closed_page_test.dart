import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workbyte_app/providers/admin_provider.dart';
import 'package:workbyte_app/screens/admin/pages/admin_closed_page.dart';

// ---------------------------------------------------------------------------
// Fake provider — overrides all async/getter members so no HTTP calls are made
// ---------------------------------------------------------------------------

class _FakeAdminProvider extends AdminProvider {
  List<Map<String, dynamic>> _fakeClosedJobs = [];
  List<Map<String, dynamic>> _fakeClosedAccounts = [];
  Map<String, dynamic> _fakeClosedJobPagination = {};
  Map<String, dynamic> _fakeClosedAccountPagination = {};
  bool _fakeIsClosedLoading = false;
  String _fakeClosedJobReasonFilter = 'all';
  String _fakeClosedAccountRoleFilter = 'all';
  String _fakeClosedAccountReasonFilter = 'all';

  int loadClosedJobsCalls = 0;
  int loadClosedAccountsCalls = 0;
  String? lastClosedJobsReason;
  String? lastClosedAccountsRole;
  String? lastClosedAccountsReason;

  void setupClosedJobs(
    List<Map<String, dynamic>> jobs, {
    Map<String, dynamic>? pagination,
  }) {
    _fakeClosedJobs = jobs;
    if (pagination != null) _fakeClosedJobPagination = pagination;
    notifyListeners();
  }

  void setupClosedAccounts(
    List<Map<String, dynamic>> accounts, {
    Map<String, dynamic>? pagination,
  }) {
    _fakeClosedAccounts = accounts;
    if (pagination != null) _fakeClosedAccountPagination = pagination;
    notifyListeners();
  }

  void setLoading(bool value) {
    _fakeIsClosedLoading = value;
    notifyListeners();
  }

  @override
  List<Map<String, dynamic>> get closedJobs => _fakeClosedJobs;

  @override
  List<Map<String, dynamic>> get closedAccounts => _fakeClosedAccounts;

  @override
  Map<String, dynamic> get closedJobPagination => _fakeClosedJobPagination;

  @override
  Map<String, dynamic> get closedAccountPagination =>
      _fakeClosedAccountPagination;

  @override
  bool get isClosedLoading => _fakeIsClosedLoading;

  @override
  String get closedJobReasonFilter => _fakeClosedJobReasonFilter;

  @override
  String get closedAccountRoleFilter => _fakeClosedAccountRoleFilter;

  @override
  String get closedAccountReasonFilter => _fakeClosedAccountReasonFilter;

  @override
  Future<void> loadClosedJobs({
    String? closureReason,
    String? search,
    int page = 1,
  }) async {
    loadClosedJobsCalls++;
    lastClosedJobsReason = closureReason;
    if (closureReason != null) {
      _fakeClosedJobReasonFilter = closureReason;
      notifyListeners();
    }
  }

  @override
  Future<void> loadClosedAccounts({
    String? role,
    String? banReason,
    String? search,
    int page = 1,
  }) async {
    loadClosedAccountsCalls++;
    lastClosedAccountsRole = role;
    lastClosedAccountsReason = banReason;
    if (role != null) {
      _fakeClosedAccountRoleFilter = role;
      notifyListeners();
    }
    if (banReason != null) {
      _fakeClosedAccountReasonFilter = banReason;
      notifyListeners();
    }
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildTestWidget(_FakeAdminProvider provider) {
  return MaterialApp(
    home: ChangeNotifierProvider<AdminProvider>.value(
      value: provider,
      child: const Scaffold(body: AdminClosedPage()),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AdminClosedPage', () {
    late _FakeAdminProvider provider;

    setUp(() => provider = _FakeAdminProvider());
    tearDown(() => provider.dispose());

    // ── Page structure ──────────────────────────────────────────────────────

    testWidgets('renders page header with title and subtitle', (tester) async {
      await tester.pumpWidget(_buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Closed Items'), findsOneWidget);
      expect(find.text('Closed jobs and restricted accounts'), findsOneWidget);
    });

    testWidgets('renders Closed Jobs and Restricted Accounts tabs',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('Closed Jobs'), findsOneWidget);
      expect(find.text('Restricted Accounts'), findsOneWidget);
    });

    testWidgets('calls loadClosedJobs and loadClosedAccounts on init',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(provider.loadClosedJobsCalls, greaterThan(0));
      expect(provider.loadClosedAccountsCalls, greaterThan(0));
    });

    // ── Closed Jobs tab ─────────────────────────────────────────────────────

    group('Closed Jobs tab', () {
      testWidgets('shows loading indicator when loading and list is empty',
          (tester) async {
        provider.setLoading(true);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows empty state when no closed jobs', (tester) async {
        provider.setupClosedJobs([]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('No closed jobs found'), findsOneWidget);
      });

      testWidgets('shows job card with title, client email, badge, and note',
          (tester) async {
        provider.setupClosedJobs([
          {
            'job_title': 'Frontend Developer',
            'client_email': 'client@test.com',
            'closure_reason': 'scam',
            'closure_note': 'Detected as fraudulent posting',
            'closed_at': '2024-01-15T10:00:00',
          },
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Frontend Developer'), findsOneWidget);
        expect(find.text('client@test.com'), findsOneWidget);
        expect(find.text('Detected as fraudulent posting'), findsOneWidget);
        expect(find.text('15/1/2024'), findsOneWidget);
      });

      testWidgets('job badge formats closure_reason with Title Case',
          (tester) async {
        provider.setupClosedJobs([
          {
            'job_title': 'UX Designer',
            'client_email': 'c@test.com',
            'closure_reason': 'content_violation',
            'closed_at': null,
          },
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Content Violation'), findsWidgets);
      });

      testWidgets('job card falls back to client_name when client_email absent',
          (tester) async {
        provider.setupClosedJobs([
          {
            'job_title': 'Backend Dev',
            'client_name': 'John Client',
            'closure_reason': 'admin_override',
            'closed_at': null,
          },
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('John Client'), findsOneWidget);
      });

      testWidgets('job card shows dash for null closed_at date', (tester) async {
        provider.setupClosedJobs([
          {
            'job_title': 'Mobile Dev',
            'closure_reason': 'scam',
            'closed_at': null,
          },
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('-'), findsWidgets);
      });

      testWidgets('filter section shows correct total count', (tester) async {
        provider.setupClosedJobs(
          [
            {'job_title': 'A', 'closure_reason': 'scam'},
            {'job_title': 'B', 'closure_reason': 'scam'},
          ],
          pagination: {'total': 42, 'total_pages': 3},
        );
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('42 closed'), findsOneWidget);
      });

      testWidgets('renders all five reason filter chips', (tester) async {
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Content Violation'), findsWidgets);
        expect(find.text('Community Reports'), findsWidgets);
        expect(find.text('Admin Override'), findsWidgets);
      });

      testWidgets('tapping Scam chip calls loadClosedJobs with scam reason',
          (tester) async {
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        final callsBefore = provider.loadClosedJobsCalls;
        await tester.tap(find.text('Scam').first);
        await tester.pumpAndSettle();

        expect(provider.loadClosedJobsCalls, greaterThan(callsBefore));
        expect(provider.lastClosedJobsReason, 'scam');
      });

      testWidgets('tapping Community Reports chip passes community_reports',
          (tester) async {
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Community Reports').first);
        await tester.pumpAndSettle();

        expect(provider.lastClosedJobsReason, 'community_reports');
      });

      testWidgets('pagination widget is hidden when totalPages <= 1',
          (tester) async {
        provider.setupClosedJobs(
          [{'job_title': 'Job', 'closure_reason': 'scam'}],
          pagination: {'total': 1, 'total_pages': 1},
        );
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Page 1 of 1'), findsNothing);
      });

      testWidgets('pagination widget shows when totalPages > 1', (tester) async {
        provider.setupClosedJobs(
          [{'job_title': 'Job', 'closure_reason': 'scam'}],
          pagination: {'total': 40, 'total_pages': 2},
        );
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        expect(find.text('Page 1 of 2'), findsOneWidget);
      });

      testWidgets('pagination previous button is disabled on first page',
          (tester) async {
        provider.setupClosedJobs(
          [{'job_title': 'Job', 'closure_reason': 'scam'}],
          pagination: {'total': 40, 'total_pages': 2},
        );
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();

        final prevButton = tester.widget<IconButton>(
          find.byIcon(Icons.chevron_left_rounded),
        );
        expect(prevButton.onPressed, isNull);
      });
    });

    // ── Restricted Accounts tab ─────────────────────────────────────────────

    group('Restricted Accounts tab', () {
      Future<void> switchToAccountsTab(WidgetTester tester) async {
        await tester.tap(find.text('Restricted Accounts'));
        await tester.pumpAndSettle();
      }

      testWidgets('shows empty state when no restricted accounts',
          (tester) async {
        provider.setupClosedAccounts([]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        expect(find.text('No restricted accounts found'), findsOneWidget);
      });

      testWidgets('shows account card with name, email, badge, and message',
          (tester) async {
        provider.setupClosedAccounts([
          {
            'freelancer_name': 'Alice Freelancer',
            'email': 'alice@test.com',
            'role': 'freelancer',
            'ban_reason': 'community_reports',
            'ban_message': 'Multiple violations reported by users.',
            'report_banned_at': '2024-02-10T09:00:00',
          },
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        expect(find.text('Alice Freelancer'), findsOneWidget);
        expect(find.text('Multiple violations reported by users.'), findsOneWidget);
        expect(find.text('10/2/2024'), findsOneWidget);
      });

      testWidgets('account card prefers freelancer_name over client_name',
          (tester) async {
        provider.setupClosedAccounts([
          {
            'freelancer_name': 'Bob Freelancer',
            'client_name': 'Bob Client',
            'email': 'bob@test.com',
            'role': 'freelancer',
            'ban_reason': 'admin_override',
          },
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        expect(find.text('Bob Freelancer'), findsOneWidget);
        expect(find.text('Bob Client'), findsNothing);
      });

      testWidgets('account card falls back to client_name when freelancer_name empty',
          (tester) async {
        provider.setupClosedAccounts([
          {
            'freelancer_name': '',
            'client_name': 'Carol Client',
            'email': 'carol@test.com',
            'role': 'client',
            'ban_reason': 'admin_override',
          },
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        expect(find.text('Carol Client'), findsOneWidget);
      });

      testWidgets('account card uses email when both name fields are empty',
          (tester) async {
        provider.setupClosedAccounts([
          {
            'freelancer_name': '',
            'client_name': '',
            'email': 'anon@test.com',
            'role': 'client',
            'ban_reason': 'admin_override',
          },
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        expect(find.text('anon@test.com'), findsOneWidget);
      });

      testWidgets('filter section shows correct restricted count', (tester) async {
        provider.setupClosedAccounts(
          [
            {
              'email': 'u@t.com',
              'role': 'freelancer',
              'ban_reason': 'admin_override',
            },
          ],
          pagination: {'total': 12, 'total_pages': 1},
        );
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        expect(find.text('12 restricted'), findsOneWidget);
      });

      testWidgets('renders role filter chips (Freelancer, Client, Admin)',
          (tester) async {
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        expect(find.text('Freelancer'), findsOneWidget);
        expect(find.text('Client'), findsOneWidget);
        expect(find.text('Admin'), findsOneWidget);
      });

      testWidgets('renders reason filter chips for accounts', (tester) async {
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        expect(find.text('Admin Override'), findsOneWidget);
      });

      testWidgets('tapping Freelancer chip calls loadClosedAccounts with role',
          (tester) async {
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        final callsBefore = provider.loadClosedAccountsCalls;
        await tester.tap(find.text('Freelancer'));
        await tester.pumpAndSettle();

        expect(provider.loadClosedAccountsCalls, greaterThan(callsBefore));
        expect(provider.lastClosedAccountsRole, 'freelancer');
      });

      testWidgets('tapping Client chip calls loadClosedAccounts with client role',
          (tester) async {
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        await tester.tap(find.text('Client'));
        await tester.pumpAndSettle();

        expect(provider.lastClosedAccountsRole, 'client');
      });

      testWidgets(
          'tapping Admin Override reason chip calls loadClosedAccounts with banReason',
          (tester) async {
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        final callsBefore = provider.loadClosedAccountsCalls;
        await tester.tap(find.text('Admin Override'));
        await tester.pumpAndSettle();

        expect(provider.loadClosedAccountsCalls, greaterThan(callsBefore));
        expect(provider.lastClosedAccountsReason, 'admin_override');
      });

      testWidgets('account badge formats ban_reason with Title Case',
          (tester) async {
        provider.setupClosedAccounts([
          {
            'freelancer_name': 'Test User',
            'email': 'test@test.com',
            'role': 'freelancer',
            'ban_reason': 'community_reports',
          },
        ]);
        await tester.pumpWidget(_buildTestWidget(provider));
        await tester.pumpAndSettle();
        await switchToAccountsTab(tester);

        expect(find.text('Community Reports'), findsWidgets);
      });
    });
  });
}
