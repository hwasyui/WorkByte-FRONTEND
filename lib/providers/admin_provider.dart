import 'package:flutter/material.dart';
import '../models/admin_review_moderation_model.dart';
import '../models/admin_red_flag_detail_model.dart';
import '../services/admin_service.dart';
import '../services/admin_session_guard.dart';

enum AdminPage {
  overview,
  users,
  jobs,
  reports,
  ai,
  closed,
  appeals,
  disputes,
  payments,
}

class AdminProvider extends ChangeNotifier {
  AdminProvider() {
    AdminSessionGuard.registerRefresh(_refreshOrRetryOnce);
    AdminSessionGuard.register(() {
      handleSessionExpired();
    });
  }

  Future<String?>? _refreshInFlight;

  Future<String?> _refreshOrRetryOnce() {
    return _refreshInFlight ??= _attemptRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  /// Public entry point for pages that need to force a token refresh outside
  /// the AdminSessionGuard flow - e.g. a 401 while opening a file. Reuses the
  /// same in-flight guard as the session-guard path so the two never race
  /// each other into duplicate refresh calls.
  Future<String?> tryRefresh() => _refreshOrRetryOnce();

  String? _isoDate(DateTime? d) => d == null
      ? null
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<String?> _attemptRefresh() async {
    try {
      final newToken = await AdminService.refreshAccessToken();
      if (newToken != null) {
        _token = newToken;
        notifyListeners();
      }
      return newToken;
    } catch (e) {
      debugPrint('Admin silent token refresh failed: $e');
      return null;
    }
  }

  String? _token;
  bool _sessionExpired = false;
  bool _isLoading = false;
  bool _isRestoring = false;
  bool _isTableLoading = false;
  String? _error;
  AdminPage _currentPage = AdminPage.overview;

  int _totalFreelancers = 0;
  int _totalClients = 0;
  int _totalJobs = 0;

  List<Map<String, dynamic>> _recentFreelancers = [];
  List<Map<String, dynamic>> _recentClients = [];
  List<Map<String, dynamic>> _recentJobs = [];

  List<Map<String, dynamic>> _tableFreelancers = [];
  List<Map<String, dynamic>> _tableClients = [];
  List<Map<String, dynamic>> _tableJobs = [];

  Map<String, dynamic> _freelancerPagination = {};
  Map<String, dynamic> _clientPagination = {};
  Map<String, dynamic> _jobPagination = {};

  Map<String, dynamic> _dashboardStats = {};
  List<Map<String, dynamic>> _reports = [];
  int _pendingReports = 0;
  String _reportsStatusFilter = 'all';
  String _reportsTypeFilter = 'all';

  List<Map<String, dynamic>> _scamFlags = [];
  List<Map<String, dynamic>> _reviewRedFlags = [];
  List<Map<String, dynamic>> _flaggedReviews = [];
  List<Map<String, dynamic>> _flaggedClientReviews = [];
  bool _isRedFlagsLoading = false;
  bool _isFlaggedReviewsLoading = false;
  bool _isFlaggedClientReviewsLoading = false;
  Map<String, dynamic> _reviewRedFlagsPagination = {};
  Map<String, dynamic> _flaggedReviewsPagination = {};
  Map<String, dynamic> _flaggedClientReviewsPagination = {};
  String _reviewRedFlagsResolvedFilter = 'all';
  String _reviewRedFlagsSortBy = 'triggered_at';
  String _flaggedReviewStatusFilter = 'flagged';
  String _flaggedClientReviewStatusFilter = 'flagged';
  String _flaggedReviewSortBy = 'created_at';
  String _flaggedClientReviewSortBy = 'created_at';
  DateTimeRange? _reviewRedFlagsDateRange;
  DateTimeRange? _flaggedReviewsDateRange;
  DateTimeRange? _flaggedClientReviewsDateRange;
  int _openReviewRedFlags = 0;
  int _pendingFlaggedReviews = 0;
  int _pendingFlaggedClientReviews = 0;
  List<Map<String, dynamic>> _moderationItems = [];
  List<Map<String, dynamic>> _closedJobs = [];
  List<Map<String, dynamic>> _closedAccounts = [];
  bool _isAiLoading = false;
  bool _isClosedLoading = false;
  String _scamStatusFilter = 'all';
  String _moderationStatusFilter = 'all';
  DateTimeRange? _scamDateRange;
  DateTimeRange? _moderationDateRange;
  String _closedJobReasonFilter = 'all';
  String _closedAccountRoleFilter = 'all';
  String _closedAccountReasonFilter = 'all';
  Map<String, dynamic> _closedJobPagination = {};
  Map<String, dynamic> _closedAccountPagination = {};

  List<Map<String, dynamic>> _appeals = [];
  bool _isAppealsLoading = false;
  String _appealsStatusFilter = 'all';
  DateTimeRange? _appealsDateRange;
  Map<String, dynamic> _appealsPagination = {};

  List<Map<String, dynamic>> _disputedContracts = [];
  bool _isDisputesLoading = false;
  DateTimeRange? _disputesDateRange;
  Map<String, dynamic> _disputesPagination = {};

  Map<String, dynamic> _paymentsOverview = {};
  bool _isPaymentsOverviewLoading = false;
  List<Map<String, dynamic>> _pendingPayments = [];
  bool _isPendingPaymentsLoading = false;
  Map<String, dynamic> _paymentsPagination = {};
  DateTimeRange? _paymentsDateRange;

  List<Map<String, dynamic>> _contractsCommissionList = [];
  bool _isContractsCommissionLoading = false;
  Map<String, dynamic> _contractsCommissionPagination = {};

  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
  bool get isTableLoading => _isTableLoading;
  String? get error => _error;
  AdminPage get currentPage => _currentPage;
  bool get isAuthenticated => _token != null;
  bool get sessionExpired => _sessionExpired;

  int get totalFreelancers => _totalFreelancers;
  int get totalClients => _totalClients;
  int get totalUsers => _totalFreelancers + _totalClients;
  int get totalJobs => _totalJobs;

  List<Map<String, dynamic>> get recentFreelancers => _recentFreelancers;
  List<Map<String, dynamic>> get recentClients => _recentClients;
  List<Map<String, dynamic>> get recentJobs => _recentJobs;

  List<Map<String, dynamic>> get tableFreelancers => _tableFreelancers;
  List<Map<String, dynamic>> get tableClients => _tableClients;
  List<Map<String, dynamic>> get tableJobs => _tableJobs;

  Map<String, dynamic> get freelancerPagination => _freelancerPagination;
  Map<String, dynamic> get clientPagination => _clientPagination;
  Map<String, dynamic> get jobPagination => _jobPagination;

  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<Map<String, dynamic>> growthSeriesFor(String source) =>
      ((_dashboardStats['series'] as Map?)?[source] as List?)
          ?.cast<Map<String, dynamic>>() ??
      const [];
  List<Map<String, dynamic>> get reports => _reports;
  int get pendingReports => _pendingReports;
  String get reportsStatusFilter => _reportsStatusFilter;
  String get reportsTypeFilter => _reportsTypeFilter;

  List<Map<String, dynamic>> get scamFlags => _scamFlags;
  List<Map<String, dynamic>> get reviewRedFlags => _reviewRedFlags;
  List<Map<String, dynamic>> get flaggedReviews => _flaggedReviews;
  List<Map<String, dynamic>> get flaggedClientReviews => _flaggedClientReviews;
  bool get isRedFlagsLoading => _isRedFlagsLoading;
  bool get isFlaggedReviewsLoading => _isFlaggedReviewsLoading;
  bool get isFlaggedClientReviewsLoading => _isFlaggedClientReviewsLoading;
  Map<String, dynamic> get reviewRedFlagsPagination =>
      _reviewRedFlagsPagination;
  Map<String, dynamic> get flaggedReviewsPagination =>
      _flaggedReviewsPagination;
  Map<String, dynamic> get flaggedClientReviewsPagination =>
      _flaggedClientReviewsPagination;
  String get reviewRedFlagsResolvedFilter => _reviewRedFlagsResolvedFilter;
  String get reviewRedFlagsSortBy => _reviewRedFlagsSortBy;
  String get flaggedReviewStatusFilter => _flaggedReviewStatusFilter;
  String get flaggedClientReviewStatusFilter =>
      _flaggedClientReviewStatusFilter;
  String get flaggedReviewSortBy => _flaggedReviewSortBy;
  String get flaggedClientReviewSortBy => _flaggedClientReviewSortBy;
  DateTimeRange? get reviewRedFlagsDateRange => _reviewRedFlagsDateRange;
  DateTimeRange? get flaggedReviewsDateRange => _flaggedReviewsDateRange;
  DateTimeRange? get flaggedClientReviewsDateRange =>
      _flaggedClientReviewsDateRange;
  List<Map<String, dynamic>> get moderationItems => _moderationItems;
  List<Map<String, dynamic>> get closedJobs => _closedJobs;
  List<Map<String, dynamic>> get closedAccounts => _closedAccounts;
  bool get isAiLoading => _isAiLoading;
  bool get isClosedLoading => _isClosedLoading;
  String get scamStatusFilter => _scamStatusFilter;
  String get moderationStatusFilter => _moderationStatusFilter;
  DateTimeRange? get scamDateRange => _scamDateRange;
  DateTimeRange? get moderationDateRange => _moderationDateRange;
  String get closedJobReasonFilter => _closedJobReasonFilter;
  String get closedAccountRoleFilter => _closedAccountRoleFilter;
  String get closedAccountReasonFilter => _closedAccountReasonFilter;
  Map<String, dynamic> get closedJobPagination => _closedJobPagination;
  Map<String, dynamic> get closedAccountPagination => _closedAccountPagination;

  List<Map<String, dynamic>> get appeals => _appeals;
  bool get isAppealsLoading => _isAppealsLoading;
  String get appealsStatusFilter => _appealsStatusFilter;
  DateTimeRange? get appealsDateRange => _appealsDateRange;
  Map<String, dynamic> get appealsPagination => _appealsPagination;

  List<Map<String, dynamic>> get disputedContracts => _disputedContracts;
  bool get isDisputesLoading => _isDisputesLoading;
  DateTimeRange? get disputesDateRange => _disputesDateRange;
  Map<String, dynamic> get disputesPagination => _disputesPagination;
  int get pendingDisputesCount =>
      (_disputesPagination['total'] as num?)?.toInt() ??
      _disputedContracts.length;

  Map<String, dynamic> get paymentsOverview => _paymentsOverview;
  bool get isPaymentsOverviewLoading => _isPaymentsOverviewLoading;
  List<Map<String, dynamic>> get pendingPayments => _pendingPayments;
  bool get isPendingPaymentsLoading => _isPendingPaymentsLoading;
  Map<String, dynamic> get paymentsPagination => _paymentsPagination;
  List<Map<String, dynamic>> get contractsCommissionList =>
      _contractsCommissionList;
  bool get isContractsCommissionLoading => _isContractsCommissionLoading;
  Map<String, dynamic> get contractsCommissionPagination =>
      _contractsCommissionPagination;
  DateTimeRange? get paymentsDateRange => _paymentsDateRange;
  int get pendingPaymentsCount =>
      (_paymentsPagination['total'] as num?)?.toInt() ??
      _pendingPayments.length;
  int get pendingAppeals =>
      (_appealsPagination['pending_count'] as num?)?.toInt() ??
      _appeals.where((a) => a['status'] == 'pending').length;
  int get pendingScamFlags =>
      (_dashboardStats['pending_scam_flags'] as num?)?.toInt() ?? 0;
  int get pendingModerationItems =>
      (_dashboardStats['pending_moderation_items'] as num?)?.toInt() ?? 0;

  int get openReviewRedFlags => _openReviewRedFlags;
  int get pendingFlaggedReviews => _pendingFlaggedReviews;
  int get pendingFlaggedClientReviews => _pendingFlaggedClientReviews;
  int get pendingReviewIntegrity =>
      _openReviewRedFlags +
      _pendingFlaggedReviews +
      _pendingFlaggedClientReviews;
  int get pendingAiWork =>
      pendingScamFlags + pendingModerationItems + pendingReviewIntegrity;

  void setPage(AdminPage page) {
    _currentPage = page;
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    _isRestoring = true;
    notifyListeners();

    try {
      final savedToken = await AdminService.getSavedToken();
      if (savedToken == null) {
        _isRestoring = false;
        notifyListeners();
        return false;
      }

      var activeToken = savedToken;
      var isValid = await AdminService.verifyAdminToken(activeToken);
      if (!isValid) {
        final refreshed = await AdminService.refreshAccessToken();
        if (refreshed != null) {
          activeToken = refreshed;
          isValid = await AdminService.verifyAdminToken(activeToken);
        }
      }
      if (!isValid) {
        await AdminService.clearToken();
        await AdminService.clearRefreshToken();
        _isRestoring = false;
        notifyListeners();
        return false;
      }

      _token = activeToken;
      _isRestoring = false;
      notifyListeners();
      loadOverviewData();
      return true;
    } catch (_) {
      await AdminService.clearToken();
      await AdminService.clearRefreshToken();
      _isRestoring = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _token = await AdminService.login(email, password);
      await AdminService.saveToken(_token!);
      await loadOverviewData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _token = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDashboardStats() async {
    if (_token == null) return;
    try {
      _dashboardStats = await AdminService.getDashboardStats(
        _token!,
        granularity: 'month',
      );
      _pendingReports =
          (_dashboardStats['pending_reports'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('AdminProvider.loadDashboardStats error: $e');
    }
    notifyListeners();
    loadReviewIntegrityQueueCounts();
  }

  Future<void> loadReviewIntegrityQueueCounts() async {
    if (_token == null) return;
    Future<int> total(Future<Map<String, dynamic>> request) async {
      final data = await request;
      final pagination = data['pagination'];
      return pagination is Map
          ? (pagination['total'] as num?)?.toInt() ?? 0
          : 0;
    }

    try {
      final counts = await Future.wait([
        total(
          AdminService.getReviewRedFlags(
            _token!,
            isResolved: false,
            pageSize: 1,
          ),
        ),
        total(
          AdminService.getFlaggedReviews(
            _token!,
            status: 'flagged',
            pageSize: 1,
          ),
        ),
        total(
          AdminService.getFlaggedClientReviews(
            _token!,
            status: 'flagged',
            pageSize: 1,
          ),
        ),
      ]);
      _openReviewRedFlags = counts[0];
      _pendingFlaggedReviews = counts[1];
      _pendingFlaggedClientReviews = counts[2];
      notifyListeners();
    } catch (e) {
      debugPrint('AdminProvider.loadReviewIntegrityQueueCounts error: $e');
    }
  }

  Future<void> loadReports({
    String? status,
    String? reportedType,
    String? startDate,
    String? endDate,
  }) async {
    if (_token == null) return;
    if (status != null) _reportsStatusFilter = status;
    if (reportedType != null) _reportsTypeFilter = reportedType;
    _isTableLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getReports(
        _token!,
        status: _reportsStatusFilter,
        reportedType: _reportsTypeFilter,
        startDate: startDate,
        endDate: endDate,
      );
      _reports = List<Map<String, dynamic>>.from(data['items'] ?? []);
    } catch (e) {
      debugPrint('AdminProvider.loadReports error: $e');
    }
    _isTableLoading = false;
    notifyListeners();
  }

  Future<bool> actionReport(String reportId, String action) async {
    if (_token == null) return false;
    try {
      final success = await AdminService.actionReport(
        _token!,
        reportId: reportId,
        action: action,
      );
      if (success) {
        await Future.wait([loadReports(), loadDashboardStats()]);
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadOverviewData() async {
    if (_token == null) return;

    try {
      final results = await Future.wait([
        AdminService.getFreelancers(_token!, page: 1, pageSize: 5),
        AdminService.getClients(_token!, page: 1, pageSize: 5),
        AdminService.getJobPosts(_token!, page: 1, pageSize: 5),
        AdminService.getAppeals(_token!, status: 'pending', pageSize: 50),
        AdminService.getDisputedContracts(_token!, page: 1, pageSize: 30),
        AdminService.getPaymentsOverview(_token!, currency: 'USD'),
      ]);

      final freelancerResult = results[0];
      final clientResult = results[1];
      final jobResult = results[2];
      final appealsResult = results[3];
      final disputesResult = results[4];
      _paymentsOverview = results[5];

      _recentFreelancers = List<Map<String, dynamic>>.from(
        freelancerResult['items'] ?? [],
      );
      _recentClients = List<Map<String, dynamic>>.from(
        clientResult['items'] ?? [],
      );
      _recentJobs = List<Map<String, dynamic>>.from(jobResult['items'] ?? []);

      _freelancerPagination = Map<String, dynamic>.from(
        freelancerResult['pagination'] ?? {},
      );
      _clientPagination = Map<String, dynamic>.from(
        clientResult['pagination'] ?? {},
      );
      _jobPagination = Map<String, dynamic>.from(jobResult['pagination'] ?? {});

      _totalFreelancers =
          (_freelancerPagination['total'] as num?)?.toInt() ??
          _recentFreelancers.length;
      _totalClients =
          (_clientPagination['total'] as num?)?.toInt() ??
          _recentClients.length;
      _totalJobs =
          (_jobPagination['total'] as num?)?.toInt() ?? _recentJobs.length;

      final pendingItems = List<Map<String, dynamic>>.from(
        appealsResult['items'] ?? [],
      );
      if (pendingItems.isNotEmpty) {
        if (_appeals.isEmpty) _appeals = pendingItems;
      }

      if (_disputedContracts.isEmpty) {
        _disputedContracts = List<Map<String, dynamic>>.from(
          disputesResult['items'] ?? [],
        );
        _disputesPagination = Map<String, dynamic>.from(
          disputesResult['pagination'] ?? {},
        );
      }
    } catch (e) {
      debugPrint('AdminProvider.loadOverviewData error: $e');
    }
    notifyListeners();
    loadDashboardStats();
  }

  Future<void> loadFreelancersPage(
    int page, {
    String? search,
    String? createdFrom,
    String? createdTo,
  }) async {
    debugPrint(
      '[DEBUG] loadFreelancersPage page=$page search=$search createdFrom=$createdFrom createdTo=$createdTo',
    );
    if (_token == null) return;
    _isTableLoading = true;
    notifyListeners();
    try {
      Map<String, dynamic> data;
      if (search != null && search.trim().isNotEmpty) {
        final raw = await AdminService.getAdminUsers(
          _token!,
          role: 'freelancer',
          isBanned: false,
          search: search,
          createdFrom: createdFrom,
          createdTo: createdTo,
          page: page,
          pageSize: 20,
        );
        final rawItems = List<Map<String, dynamic>>.from(raw['items'] ?? []);
        data = {
          'items': rawItems.map((u) {
            final m = Map<String, dynamic>.from(u);
            m['full_name'] =
                (u['freelancer_name'] as String?)?.isNotEmpty == true
                ? u['freelancer_name']
                : u['full_name'] ?? '';
            return m;
          }).toList(),
          'pagination': raw['pagination'] ?? {},
        };
      } else {
        data = await AdminService.getFreelancers(
          _token!,
          page: page,
          pageSize: 20,
          createdFrom: createdFrom,
          createdTo: createdTo,
        );
      }
      _tableFreelancers = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _freelancerPagination = Map<String, dynamic>.from(
        data['pagination'] ?? {},
      );
      _totalFreelancers =
          (_freelancerPagination['total'] as num?)?.toInt() ??
          _tableFreelancers.length;
    } catch (e) {
      debugPrint('AdminProvider.loadFreelancersPage error: $e');
    }
    _isTableLoading = false;
    notifyListeners();
  }

  Future<void> loadClientsPage(
    int page, {
    String? search,
    String? createdFrom,
    String? createdTo,
  }) async {
    if (_token == null) return;
    _isTableLoading = true;
    notifyListeners();
    try {
      Map<String, dynamic> data;
      if (search != null && search.trim().isNotEmpty) {
        final raw = await AdminService.getAdminUsers(
          _token!,
          role: 'client',
          isBanned: false,
          search: search,
          createdFrom: createdFrom,
          createdTo: createdTo,
          page: page,
          pageSize: 20,
        );
        final rawItems = List<Map<String, dynamic>>.from(raw['items'] ?? []);
        data = {
          'items': rawItems.map((u) {
            final m = Map<String, dynamic>.from(u);
            m['full_name'] = (u['client_name'] as String?)?.isNotEmpty == true
                ? u['client_name']
                : u['full_name'] ?? '';
            return m;
          }).toList(),
          'pagination': raw['pagination'] ?? {},
        };
      } else {
        data = await AdminService.getClients(
          _token!,
          page: page,
          pageSize: 20,
          createdFrom: createdFrom,
          createdTo: createdTo,
        );
      }
      _tableClients = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _clientPagination = Map<String, dynamic>.from(data['pagination'] ?? {});
      _totalClients =
          (_clientPagination['total'] as num?)?.toInt() ?? _tableClients.length;
    } catch (e) {
      debugPrint('AdminProvider.loadClientsPage error: $e');
    }
    _isTableLoading = false;
    notifyListeners();
  }

  Future<void> loadJobsPage(
    int page, {
    String? status,
    String? search,
    String? createdFrom,
    String? createdTo,
  }) async {
    if (_token == null) return;
    _isTableLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getAdminJobs(
        _token!,
        status: status,
        page: page,
        pageSize: 20,
        search: search,
        createdFrom: createdFrom,
        createdTo: createdTo,
      );
      _tableJobs = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _jobPagination = Map<String, dynamic>.from(data['pagination'] ?? {});
      _totalJobs =
          (_jobPagination['total'] as num?)?.toInt() ?? _tableJobs.length;
    } catch (e) {
      debugPrint('AdminProvider.loadJobsPage error: $e');
    }
    _isTableLoading = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> loadClientJobsList(String clientId) async {
    if (_token == null) return [];
    try {
      final data = await AdminService.getAdminJobs(
        _token!,
        clientId: clientId,
        pageSize: 100,
        sortBy: 'created_at',
        sortDir: 'desc',
      );
      return List<Map<String, dynamic>>.from(data['items'] ?? []);
    } catch (e) {
      debugPrint('AdminProvider.loadClientJobsList error: $e');
      return [];
    }
  }

  Future<void> loadClosedJobs({
    String? closureReason,
    String? search,
    String? closedFrom,
    String? closedTo,
    int page = 1,
  }) async {
    if (_token == null) return;
    if (closureReason != null) _closedJobReasonFilter = closureReason;
    _isClosedLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getAdminJobs(
        _token!,
        status: 'closed',
        closureReason: _closedJobReasonFilter == 'all'
            ? null
            : _closedJobReasonFilter,
        search: search,
        closedFrom: closedFrom,
        closedTo: closedTo,
        sortBy: 'closed_at',
        sortDir: 'desc',
        page: page,
        pageSize: 20,
      );
      _closedJobs = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _closedJobPagination = Map<String, dynamic>.from(
        data['pagination'] ?? {},
      );
    } catch (e) {
      debugPrint('AdminProvider.loadClosedJobs error: $e');
    }
    _isClosedLoading = false;
    notifyListeners();
  }

  Future<void> loadClosedAccounts({
    String? role,
    String? banReason,
    String? search,
    String? bannedFrom,
    String? bannedTo,
    int page = 1,
  }) async {
    if (_token == null) return;
    if (role != null) _closedAccountRoleFilter = role;
    if (banReason != null) _closedAccountReasonFilter = banReason;
    _isClosedLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getAdminUsers(
        _token!,
        isBanned: true,
        role: _closedAccountRoleFilter == 'all'
            ? null
            : _closedAccountRoleFilter,
        banReason: _closedAccountReasonFilter == 'all'
            ? null
            : _closedAccountReasonFilter,
        search: search,
        bannedFrom: bannedFrom,
        bannedTo: bannedTo,
        sortBy: 'report_banned_at',
        sortDir: 'desc',
        page: page,
        pageSize: 20,
      );
      _closedAccounts = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _closedAccountPagination = Map<String, dynamic>.from(
        data['pagination'] ?? {},
      );
    } catch (e) {
      debugPrint('AdminProvider.loadClosedAccounts error: $e');
    }
    _isClosedLoading = false;
    notifyListeners();
  }

  Future<void> loadScamFlags({String? status}) async {
    if (_token == null) return;
    if (status != null) _scamStatusFilter = status;
    _isAiLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getScamFlags(
        _token!,
        status: _scamStatusFilter,
        startDate: _isoDate(_scamDateRange?.start),
        endDate: _isoDate(_scamDateRange?.end),
      );
      _scamFlags = List<Map<String, dynamic>>.from(data['items'] ?? []);
    } catch (e) {
      debugPrint('AdminProvider.loadScamFlags error: $e');
    }
    _isAiLoading = false;
    notifyListeners();
  }

  void setScamDateRange(DateTimeRange? range) {
    _scamDateRange = range;
    loadScamFlags();
  }

  Future<bool> actionScamFlag(String flagId, String action) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.actionScamFlag(
        _token!,
        flagId: flagId,
        action: action,
      );
      if (ok) await Future.wait([loadScamFlags(), loadDashboardStats()]);
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadReviewRedFlags({String? resolvedFilter, int? page}) async {
    if (_token == null) return;
    if (resolvedFilter != null) _reviewRedFlagsResolvedFilter = resolvedFilter;
    _isRedFlagsLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getReviewRedFlags(
        _token!,
        isResolved: _reviewRedFlagsResolvedFilter == 'all'
            ? null
            : _reviewRedFlagsResolvedFilter == 'resolved',
        sortBy: _reviewRedFlagsSortBy,
        startDate: _isoDate(_reviewRedFlagsDateRange?.start),
        endDate: _isoDate(_reviewRedFlagsDateRange?.end),
        page: page ?? 1,
      );
      _reviewRedFlags = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _reviewRedFlagsPagination = Map<String, dynamic>.from(
        data['pagination'] ?? {},
      );
    } catch (e) {
      debugPrint('AdminProvider.loadReviewRedFlags error: $e');
    }
    _isRedFlagsLoading = false;
    notifyListeners();
  }

  void setReviewRedFlagsSort(String sortBy) {
    _reviewRedFlagsSortBy = sortBy;
    loadReviewRedFlags();
  }

  void setReviewRedFlagsDateRange(DateTimeRange? range) {
    _reviewRedFlagsDateRange = range;
    loadReviewRedFlags();
  }

  Future<AdminActionOutcome> resolveReviewRedFlag(
    String alertId, {
    required String reason,
  }) async {
    if (_token == null) {
      return const AdminActionOutcome(
        success: false,
        errorMessage: 'No session',
      );
    }
    final outcome = await AdminService.resolveReviewRedFlag(
      _token!,
      alertId,
      reason: reason,
    );
    if (outcome.success) {
      await loadReviewRedFlags();
      await loadReviewIntegrityQueueCounts();
    }
    return outcome;
  }

  Future<void> loadFlaggedReviews({String? status, int? page}) async {
    if (_token == null) return;
    if (status != null) _flaggedReviewStatusFilter = status;
    _isFlaggedReviewsLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getFlaggedReviews(
        _token!,
        status: _flaggedReviewStatusFilter,
        sortBy: _flaggedReviewSortBy,
        startDate: _isoDate(_flaggedReviewsDateRange?.start),
        endDate: _isoDate(_flaggedReviewsDateRange?.end),
        page: page ?? 1,
      );
      _flaggedReviews = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _flaggedReviewsPagination = Map<String, dynamic>.from(
        data['pagination'] ?? {},
      );
    } catch (e) {
      debugPrint('AdminProvider.loadFlaggedReviews error: $e');
    }
    _isFlaggedReviewsLoading = false;
    notifyListeners();
  }

  void setFlaggedReviewSort(String sortBy) {
    _flaggedReviewSortBy = sortBy;
    loadFlaggedReviews();
  }

  void setFlaggedReviewsDateRange(DateTimeRange? range) {
    _flaggedReviewsDateRange = range;
    loadFlaggedReviews();
  }

  Future<AdminActionOutcome> overridePublishReview(
    String reviewId, {
    required String reason,
  }) async {
    if (_token == null) {
      return const AdminActionOutcome(
        success: false,
        errorMessage: 'No session',
      );
    }
    final outcome = await AdminService.overridePublishReview(
      _token!,
      reviewId,
      reason: reason,
    );
    if (outcome.success) {
      await loadFlaggedReviews();
      await loadReviewIntegrityQueueCounts();
    }
    return outcome;
  }

  Future<AdminActionOutcome> upholdReview(
    String reviewId, {
    required String reason,
  }) async {
    if (_token == null) {
      return const AdminActionOutcome(
        success: false,
        errorMessage: 'No session',
      );
    }
    final outcome = await AdminService.upholdReview(
      _token!,
      reviewId,
      reason: reason,
    );
    if (outcome.success) {
      await loadFlaggedReviews();
      await loadReviewIntegrityQueueCounts();
    }
    return outcome;
  }

  Future<void> loadFlaggedClientReviews({String? status, int? page}) async {
    if (_token == null) return;
    if (status != null) _flaggedClientReviewStatusFilter = status;
    _isFlaggedClientReviewsLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getFlaggedClientReviews(
        _token!,
        status: _flaggedClientReviewStatusFilter,
        sortBy: _flaggedClientReviewSortBy,
        startDate: _isoDate(_flaggedClientReviewsDateRange?.start),
        endDate: _isoDate(_flaggedClientReviewsDateRange?.end),
        page: page ?? 1,
      );
      _flaggedClientReviews = List<Map<String, dynamic>>.from(
        data['items'] ?? [],
      );
      _flaggedClientReviewsPagination = Map<String, dynamic>.from(
        data['pagination'] ?? {},
      );
    } catch (e) {
      debugPrint('AdminProvider.loadFlaggedClientReviews error: $e');
    }
    _isFlaggedClientReviewsLoading = false;
    notifyListeners();
  }

  void setFlaggedClientReviewSort(String sortBy) {
    _flaggedClientReviewSortBy = sortBy;
    loadFlaggedClientReviews();
  }

  void setFlaggedClientReviewsDateRange(DateTimeRange? range) {
    _flaggedClientReviewsDateRange = range;
    loadFlaggedClientReviews();
  }

  Future<AdminActionOutcome> overridePublishClientReview(
    String clientReviewId, {
    required String reason,
  }) async {
    if (_token == null) {
      return const AdminActionOutcome(
        success: false,
        errorMessage: 'No session',
      );
    }
    final outcome = await AdminService.overridePublishClientReview(
      _token!,
      clientReviewId,
      reason: reason,
    );
    if (outcome.success) {
      await loadFlaggedClientReviews();
      await loadReviewIntegrityQueueCounts();
    }
    return outcome;
  }

  Future<AdminActionOutcome> upholdClientReview(
    String clientReviewId, {
    required String reason,
  }) async {
    if (_token == null) {
      return const AdminActionOutcome(
        success: false,
        errorMessage: 'No session',
      );
    }
    final outcome = await AdminService.upholdClientReview(
      _token!,
      clientReviewId,
      reason: reason,
    );
    if (outcome.success) {
      await loadFlaggedClientReviews();
      await loadReviewIntegrityQueueCounts();
    }
    return outcome;
  }

  Future<ReviewModerationDetail?> fetchReviewModerationDetail(String reviewId) {
    if (_token == null) return Future.value(null);
    return AdminService.getReviewModerationDetail(_token!, reviewId);
  }

  Future<ReviewModerationDetail?> fetchClientReviewModerationDetail(
    String reviewId,
  ) {
    if (_token == null) return Future.value(null);
    return AdminService.getClientReviewModerationDetail(_token!, reviewId);
  }

  Future<RedFlagDetail?> fetchRedFlagDetail(String alertId) {
    if (_token == null) return Future.value(null);
    return AdminService.getRedFlagDetail(_token!, alertId);
  }

  Future<void> loadModerationItems({String? status}) async {
    if (_token == null) return;
    if (status != null) _moderationStatusFilter = status;
    _isAiLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getModerationItems(
        _token!,
        status: _moderationStatusFilter,
        startDate: _isoDate(_moderationDateRange?.start),
        endDate: _isoDate(_moderationDateRange?.end),
      );
      _moderationItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
    } catch (e) {
      debugPrint('AdminProvider.loadModerationItems error: $e');
    }
    _isAiLoading = false;
    notifyListeners();
  }

  void setModerationDateRange(DateTimeRange? range) {
    _moderationDateRange = range;
    loadModerationItems();
  }

  Future<bool> actionModerationItem(String moderationId, String action) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.actionModerationItem(
        _token!,
        moderationId: moderationId,
        action: action,
      );
      if (ok) await Future.wait([loadModerationItems(), loadDashboardStats()]);
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> adminCloseJob(String jobPostId, {String? reason}) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.closeJob(
        _token!,
        jobPostId,
        reason: reason,
      );
      if (ok) {
        await Future.wait([
          loadScamFlags(),
          loadModerationItems(),
          loadDashboardStats(),
        ]);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> loadFreelancerFullProfile(
    String freelancerId,
  ) async {
    if (_token == null) return null;
    return AdminService.getFreelancerFullProfile(_token!, freelancerId);
  }

  Future<bool> adminCloseAccount(String userId, {String? reason}) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.closeAccount(
        _token!,
        userId,
        reason: reason,
      );
      if (ok) {
        await Future.wait([loadModerationItems(), loadDashboardStats()]);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadAppeals({String? status, int page = 1}) async {
    if (_token == null) return;
    if (status != null) _appealsStatusFilter = status;
    _isAppealsLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getAppeals(
        _token!,
        status: _appealsStatusFilter,
        startDate: _isoDate(_appealsDateRange?.start),
        endDate: _isoDate(_appealsDateRange?.end),
        page: page,
        pageSize: 30,
      );
      _appeals = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _appealsPagination = Map<String, dynamic>.from(data['pagination'] ?? {});
    } catch (e) {
      debugPrint('AdminProvider.loadAppeals error: $e');
    }
    _isAppealsLoading = false;
    notifyListeners();
  }

  void setAppealsDateRange(DateTimeRange? range) {
    _appealsDateRange = range;
    loadAppeals();
  }

  Future<bool> resolveAppeal(
    String appealId,
    String action, {
    String? adminNote,
  }) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.resolveAppeal(
        _token!,
        appealId: appealId,
        action: action,
        adminNote: adminNote,
      );
      if (ok) await loadAppeals();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadDisputedContracts({String? search, int page = 1}) async {
    if (_token == null) return;
    _isDisputesLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getDisputedContracts(
        _token!,
        search: search,
        startDate: _isoDate(_disputesDateRange?.start),
        endDate: _isoDate(_disputesDateRange?.end),
        page: page,
        pageSize: 30,
      );
      _disputedContracts = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _disputesPagination = Map<String, dynamic>.from(data['pagination'] ?? {});
    } catch (e) {
      debugPrint('AdminProvider.loadDisputedContracts error: $e');
    }
    _isDisputesLoading = false;
    notifyListeners();
  }

  void setDisputesDateRange(DateTimeRange? range) {
    _disputesDateRange = range;
    loadDisputedContracts();
  }

  Future<void> loadPaymentsOverview({String currency = 'USD'}) async {
    if (_token == null) return;
    _isPaymentsOverviewLoading = true;
    notifyListeners();
    try {
      _paymentsOverview = await AdminService.getPaymentsOverview(
        _token!,
        currency: currency,
        startDate: _isoDate(_paymentsDateRange?.start),
        endDate: _isoDate(_paymentsDateRange?.end),
      );
    } catch (e) {
      debugPrint('AdminProvider.loadPaymentsOverview error: $e');
    }
    _isPaymentsOverviewLoading = false;
    notifyListeners();
  }

  Future<void> loadPendingPayments({int page = 1}) async {
    if (_token == null) return;
    _isPendingPaymentsLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getPendingPayments(
        _token!,
        page: page,
        pageSize: 20,
        startDate: _isoDate(_paymentsDateRange?.start),
        endDate: _isoDate(_paymentsDateRange?.end),
      );
      _pendingPayments = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _paymentsPagination = Map<String, dynamic>.from(data['pagination'] ?? {});
    } catch (e) {
      debugPrint('AdminProvider.loadPendingPayments error: $e');
    }
    _isPendingPaymentsLoading = false;
    notifyListeners();
  }

  void setPaymentsDateRange(DateTimeRange? range) {
    _paymentsDateRange = range;
    loadPaymentsOverview();
    loadPendingPayments();
    loadContractsCommissionList();
  }

  Future<void> loadContractsCommissionList({
    int page = 1,
    String? search,
    String? status,
  }) async {
    if (_token == null) return;
    _isContractsCommissionLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getContractsCommissionList(
        _token!,
        page: page,
        pageSize: 20,
        search: search,
        status: status,
        startDate: _isoDate(_paymentsDateRange?.start),
        endDate: _isoDate(_paymentsDateRange?.end),
      );
      _contractsCommissionList = List<Map<String, dynamic>>.from(
        data['items'] ?? [],
      );
      _contractsCommissionPagination = Map<String, dynamic>.from(
        data['pagination'] ?? {},
      );
    } catch (e) {
      debugPrint('AdminProvider.loadContractsCommissionList error: $e');
    }
    _isContractsCommissionLoading = false;
    notifyListeners();
  }

  Future<AdminActionOutcome> verifyPayment(String proofId) async {
    if (_token == null) {
      return const AdminActionOutcome(
        success: false,
        errorMessage: 'No session',
      );
    }
    final outcome = await AdminService.verifyPayment(_token!, proofId);
    if (outcome.success) {
      await Future.wait([loadPendingPayments(), loadPaymentsOverview()]);
    }
    return outcome;
  }

  Future<AdminActionOutcome> rejectPayment(
    String proofId,
    String reason,
  ) async {
    if (_token == null) {
      return const AdminActionOutcome(
        success: false,
        errorMessage: 'No session',
      );
    }
    final outcome = await AdminService.rejectPayment(_token!, proofId, reason);
    if (outcome.success) {
      await Future.wait([loadPendingPayments(), loadPaymentsOverview()]);
    }
    return outcome;
  }

  Future<AdminActionOutcome> overridePaymentCompletion(
    String contractId,
    String reason,
  ) async {
    if (_token == null) {
      return const AdminActionOutcome(
        success: false,
        errorMessage: 'No session',
      );
    }
    final outcome = await AdminService.overridePaymentCompletion(
      _token!,
      contractId,
      reason,
    );
    if (outcome.success) {
      await Future.wait([loadPendingPayments(), loadPaymentsOverview()]);
    }
    return outcome;
  }

  Future<bool> arbitrateDispute(
    String contractId, {
    required String outcome,
    String? note,
    String? newDeadline,
  }) async {
    if (_token == null) return false;
    try {
      final updated = await AdminService.arbitrateDispute(
        _token!,
        contractId: contractId,
        outcome: outcome,
        note: note,
        newDeadline: newDeadline,
      );
      if (updated != null) {
        await Future.wait([loadDisputedContracts(), loadDashboardStats()]);
      }
      return updated != null;
    } catch (_) {
      return false;
    }
  }

  void initWithToken(String token) {
    _token = token;
    _currentPage = AdminPage.overview;
    notifyListeners();
    loadOverviewData();
  }

  Future<void> handleSessionExpired() async {
    await logout();
    _sessionExpired = true;
    notifyListeners();
  }

  void clearSessionExpired() {
    _sessionExpired = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await AdminService.clearToken();
    await AdminService.clearRefreshToken();
    _token = null;
    _currentPage = AdminPage.overview;
    _totalFreelancers = 0;
    _totalClients = 0;
    _totalJobs = 0;
    _recentFreelancers = [];
    _recentClients = [];
    _recentJobs = [];
    _tableFreelancers = [];
    _tableClients = [];
    _tableJobs = [];
    _freelancerPagination = {};
    _clientPagination = {};
    _jobPagination = {};
    _dashboardStats = {};
    _reports = [];
    _pendingReports = 0;
    _reportsStatusFilter = 'all';
    _reportsTypeFilter = 'all';
    _scamFlags = [];
    _reviewRedFlags = [];
    _reviewRedFlagsPagination = {};
    _reviewRedFlagsResolvedFilter = 'all';
    _reviewRedFlagsSortBy = 'triggered_at';
    _flaggedReviews = [];
    _flaggedReviewStatusFilter = 'flagged';
    _flaggedReviewSortBy = 'created_at';
    _flaggedReviewsPagination = {};
    _flaggedClientReviews = [];
    _flaggedClientReviewStatusFilter = 'flagged';
    _flaggedClientReviewSortBy = 'created_at';
    _flaggedClientReviewsPagination = {};
    _isRedFlagsLoading = false;
    _isFlaggedReviewsLoading = false;
    _isFlaggedClientReviewsLoading = false;
    _openReviewRedFlags = 0;
    _pendingFlaggedReviews = 0;
    _pendingFlaggedClientReviews = 0;
    _moderationItems = [];
    _closedJobs = [];
    _closedAccounts = [];
    _scamStatusFilter = 'all';
    _moderationStatusFilter = 'all';
    _closedJobReasonFilter = 'all';
    _closedAccountRoleFilter = 'all';
    _closedAccountReasonFilter = 'all';
    _closedJobPagination = {};
    _closedAccountPagination = {};
    _appeals = [];
    _isAppealsLoading = false;
    _appealsStatusFilter = 'all';
    _appealsPagination = {};
    _disputedContracts = [];
    _isDisputesLoading = false;
    _disputesPagination = {};
    _paymentsOverview = {};
    _isPaymentsOverviewLoading = false;
    _pendingPayments = [];
    _isPendingPaymentsLoading = false;
    _paymentsPagination = {};
    _paymentsDateRange = null;
    _contractsCommissionList = [];
    _isContractsCommissionLoading = false;
    _contractsCommissionPagination = {};
    _isAiLoading = false;
    _isClosedLoading = false;
    _error = null;
    notifyListeners();
  }
}
