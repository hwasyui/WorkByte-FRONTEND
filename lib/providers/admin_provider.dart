import 'package:flutter/material.dart';
import '../services/admin_service.dart';

enum AdminPage { overview, users, jobs, reports, ai, closed, appeals, disputes }

class AdminProvider extends ChangeNotifier {
  String? _token;
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
  bool _isReviewIntegrityLoading = false;
  String _flaggedReviewStatusFilter = 'all';
  String _flaggedClientReviewStatusFilter = 'all';
  List<Map<String, dynamic>> _moderationItems = [];
  List<Map<String, dynamic>> _closedJobs = [];
  List<Map<String, dynamic>> _closedAccounts = [];
  bool _isAiLoading = false;
  bool _isClosedLoading = false;
  String _scamStatusFilter = 'all';
  // Harmful-text audit trail is read-only history. Filter by whether an admin has
  // reviewed a row yet: 'all' | 'unreviewed' | 'reviewed'.
  String _moderationReviewedFilter = 'all';
  String _moderationTypeFilter = 'all';
  String _closedJobReasonFilter = 'all';
  String _closedAccountRoleFilter = 'all';
  String _closedAccountReasonFilter = 'all';
  Map<String, dynamic> _closedJobPagination = {};
  Map<String, dynamic> _closedAccountPagination = {};

  List<Map<String, dynamic>> _appeals = [];
  bool _isAppealsLoading = false;
  String _appealsStatusFilter = 'all';
  Map<String, dynamic> _appealsPagination = {};

  List<Map<String, dynamic>> _disputedContracts = [];
  bool _isDisputesLoading = false;
  Map<String, dynamic> _disputesPagination = {};

  // Getters
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
  bool get isTableLoading => _isTableLoading;
  String? get error => _error;
  AdminPage get currentPage => _currentPage;
  bool get isAuthenticated => _token != null;

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
  List<Map<String, dynamic>> get reports => _reports;
  int get pendingReports => _pendingReports;
  String get reportsStatusFilter => _reportsStatusFilter;
  String get reportsTypeFilter => _reportsTypeFilter;

  List<Map<String, dynamic>> get scamFlags => _scamFlags;
  List<Map<String, dynamic>> get reviewRedFlags => _reviewRedFlags;
  List<Map<String, dynamic>> get flaggedReviews => _flaggedReviews;
  List<Map<String, dynamic>> get flaggedClientReviews => _flaggedClientReviews;
  bool get isReviewIntegrityLoading => _isReviewIntegrityLoading;
  String get flaggedReviewStatusFilter => _flaggedReviewStatusFilter;
  String get flaggedClientReviewStatusFilter => _flaggedClientReviewStatusFilter;
  List<Map<String, dynamic>> get moderationItems => _moderationItems;
  List<Map<String, dynamic>> get closedJobs => _closedJobs;
  List<Map<String, dynamic>> get closedAccounts => _closedAccounts;
  bool get isAiLoading => _isAiLoading;
  bool get isClosedLoading => _isClosedLoading;
  String get scamStatusFilter => _scamStatusFilter;
  String get moderationReviewedFilter => _moderationReviewedFilter;
  String get moderationTypeFilter => _moderationTypeFilter;
  String get closedJobReasonFilter => _closedJobReasonFilter;
  String get closedAccountRoleFilter => _closedAccountRoleFilter;
  String get closedAccountReasonFilter => _closedAccountReasonFilter;
  Map<String, dynamic> get closedJobPagination => _closedJobPagination;
  Map<String, dynamic> get closedAccountPagination => _closedAccountPagination;

  List<Map<String, dynamic>> get appeals => _appeals;
  bool get isAppealsLoading => _isAppealsLoading;
  String get appealsStatusFilter => _appealsStatusFilter;
  Map<String, dynamic> get appealsPagination => _appealsPagination;

  List<Map<String, dynamic>> get disputedContracts => _disputedContracts;
  bool get isDisputesLoading => _isDisputesLoading;
  Map<String, dynamic> get disputesPagination => _disputesPagination;
  int get pendingDisputesCount =>
      (_disputesPagination['total'] as num?)?.toInt() ??
      _disputedContracts.length;
  int get pendingAppeals =>
      (_appealsPagination['pending_count'] as num?)?.toInt() ??
      _appeals.where((a) => a['status'] == 'pending').length;
  int get pendingScamFlags =>
      (_dashboardStats['pending_scam_flags'] as num?)?.toInt() ?? 0;
  // Harmful-text audit trail rows an admin hasn't looked at yet (not an action queue).
  int get unreviewedModerationItems =>
      (_dashboardStats['unreviewed_moderation_items'] as num?)?.toInt() ?? 0;

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

      final isValid = await AdminService.verifyAdminToken(savedToken);
      if (!isValid) {
        await AdminService.clearToken();
        _isRestoring = false;
        notifyListeners();
        return false;
      }

      _token = savedToken;
      _isRestoring = false;
      notifyListeners();
      loadOverviewData();
      return true;
    } catch (_) {
      await AdminService.clearToken();
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
      _dashboardStats = await AdminService.getDashboardStats(_token!);
      _pendingReports =
          (_dashboardStats['pending_reports'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('AdminProvider.loadDashboardStats error: $e');
    }
    notifyListeners();
  }

  Future<void> loadReports({String? status, String? reportedType}) async {
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
      ]);

      final freelancerResult = results[0];
      final clientResult = results[1];
      final jobResult = results[2];
      final appealsResult = results[3];
      final disputesResult = results[4];

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

      // Pre-populate pending appeals for the sidebar badge
      final pendingItems = List<Map<String, dynamic>>.from(
        appealsResult['items'] ?? [],
      );
      if (pendingItems.isNotEmpty) {
        // Merge into _appeals without overwriting if appeals page already loaded
        if (_appeals.isEmpty) _appeals = pendingItems;
      }

      // Pre-populate disputed contracts for the sidebar badge
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

  Future<void> loadFreelancersPage(int page, {String? search}) async {
    if (_token == null) return;
    _isTableLoading = true;
    notifyListeners();
    try {
      Map<String, dynamic> data;
      if (search != null && search.trim().isNotEmpty) {
        // /admin/users supports search; /freelancers/browse/all does not
        final raw = await AdminService.getAdminUsers(
          _token!,
          role: 'freelancer',
          isBanned: false,
          search: search,
          page: page,
          pageSize: 20,
        );
        final rawItems = List<Map<String, dynamic>>.from(raw['items'] ?? []);
        data = {
          'items': rawItems.map((u) {
            final m = Map<String, dynamic>.from(u);
            // /admin/users returns freelancer_name instead of full_name
            m['full_name'] = (u['freelancer_name'] as String?)?.isNotEmpty == true
                ? u['freelancer_name']
                : u['full_name'] ?? '';
            return m;
          }).toList(),
          'pagination': raw['pagination'] ?? {},
        };
      } else {
        data = await AdminService.getFreelancers(_token!, page: page, pageSize: 20);
      }
      _tableFreelancers = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _freelancerPagination = Map<String, dynamic>.from(data['pagination'] ?? {});
      _totalFreelancers =
          (_freelancerPagination['total'] as num?)?.toInt() ??
          _tableFreelancers.length;
    } catch (e) {
      debugPrint('AdminProvider.loadFreelancersPage error: $e');
    }
    _isTableLoading = false;
    notifyListeners();
  }

  Future<void> loadClientsPage(int page, {String? search}) async {
    if (_token == null) return;
    _isTableLoading = true;
    notifyListeners();
    try {
      Map<String, dynamic> data;
      if (search != null && search.trim().isNotEmpty) {
        // /admin/users supports search; /clients/browse/all does not
        final raw = await AdminService.getAdminUsers(
          _token!,
          role: 'client',
          isBanned: false,
          search: search,
          page: page,
          pageSize: 20,
        );
        final rawItems = List<Map<String, dynamic>>.from(raw['items'] ?? []);
        data = {
          'items': rawItems.map((u) {
            final m = Map<String, dynamic>.from(u);
            // /admin/users returns client_name instead of full_name
            m['full_name'] = (u['client_name'] as String?)?.isNotEmpty == true
                ? u['client_name']
                : u['full_name'] ?? '';
            return m;
          }).toList(),
          'pagination': raw['pagination'] ?? {},
        };
      } else {
        data = await AdminService.getClients(_token!, page: page, pageSize: 20);
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

  Future<void> loadJobsPage(int page, {String? status, String? search}) async {
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
      );
      _scamFlags = List<Map<String, dynamic>>.from(data['items'] ?? []);
    } catch (e) {
      debugPrint('AdminProvider.loadScamFlags error: $e');
    }
    _isAiLoading = false;
    notifyListeners();
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

  Future<void> loadReviewRedFlags({bool? isResolved}) async {
    if (_token == null) return;
    _isReviewIntegrityLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getReviewRedFlags(
        _token!,
        isResolved: isResolved,
      );
      _reviewRedFlags = List<Map<String, dynamic>>.from(data['items'] ?? []);
    } catch (e) {
      debugPrint('AdminProvider.loadReviewRedFlags error: $e');
    }
    _isReviewIntegrityLoading = false;
    notifyListeners();
  }

  Future<bool> resolveReviewRedFlag(String alertId) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.resolveReviewRedFlag(_token!, alertId);
      if (ok) await loadReviewRedFlags();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadFlaggedReviews({String? status}) async {
    if (_token == null) return;
    if (status != null) _flaggedReviewStatusFilter = status;
    _isReviewIntegrityLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getFlaggedReviews(
        _token!,
        status: _flaggedReviewStatusFilter,
      );
      _flaggedReviews = List<Map<String, dynamic>>.from(data['items'] ?? []);
    } catch (e) {
      debugPrint('AdminProvider.loadFlaggedReviews error: $e');
    }
    _isReviewIntegrityLoading = false;
    notifyListeners();
  }

  Future<bool> overridePublishReview(String reviewId) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.overridePublishReview(_token!, reviewId);
      if (ok) await loadFlaggedReviews();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadFlaggedClientReviews({String? status}) async {
    if (_token == null) return;
    if (status != null) _flaggedClientReviewStatusFilter = status;
    _isReviewIntegrityLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getFlaggedClientReviews(
        _token!,
        status: _flaggedClientReviewStatusFilter,
      );
      _flaggedClientReviews = List<Map<String, dynamic>>.from(
        data['items'] ?? [],
      );
    } catch (e) {
      debugPrint('AdminProvider.loadFlaggedClientReviews error: $e');
    }
    _isReviewIntegrityLoading = false;
    notifyListeners();
  }

  Future<bool> overridePublishClientReview(String clientReviewId) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.overridePublishClientReview(
        _token!,
        clientReviewId,
      );
      if (ok) await loadFlaggedClientReviews();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadModerationItems({
    String? reviewed,
    String? contentType,
  }) async {
    if (_token == null) return;
    if (reviewed != null) _moderationReviewedFilter = reviewed;
    if (contentType != null) _moderationTypeFilter = contentType;
    _isAiLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getModerationItems(
        _token!,
        reviewed: _moderationReviewedFilter == 'all'
            ? null
            : _moderationReviewedFilter == 'reviewed',
        contentType: _moderationTypeFilter,
      );
      _moderationItems = List<Map<String, dynamic>>.from(data['items'] ?? []);
    } catch (e) {
      debugPrint('AdminProvider.loadModerationItems error: $e');
    }
    _isAiLoading = false;
    notifyListeners();
  }

  /// Mark an audit-trail entry as reviewed (bookkeeping only, no side effects on
  /// the underlying content). Optional [note] is stored with the row.
  Future<bool> reviewModerationItem(String moderationId, {String? note}) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.reviewModerationItem(
        _token!,
        moderationId: moderationId,
        adminNote: note,
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
      final ok = await AdminService.closeJob(_token!, jobPostId, reason: reason);
      if (ok) {
        await Future.wait([loadScamFlags(), loadModerationItems(), loadDashboardStats()]);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> loadFreelancerFullProfile(String freelancerId) async {
    if (_token == null) return null;
    return AdminService.getFreelancerFullProfile(_token!, freelancerId);
  }

  Future<bool> adminCloseAccount(String userId, {String? reason}) async {
    if (_token == null) return false;
    try {
      final ok = await AdminService.closeAccount(_token!, userId, reason: reason);
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

  Future<bool> resolveAppeal(String appealId, String action, {String? adminNote}) async {
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

  Future<Map<String, dynamic>?> getClientAutoapproveHistory(
    String clientId,
  ) async {
    if (_token == null) return null;
    return AdminService.getClientAutoapproveHistory(_token!, clientId);
  }

  void initWithToken(String token) {
    _token = token;
    _currentPage = AdminPage.overview;
    notifyListeners();
    loadOverviewData();
  }

  Future<void> logout() async {
    await AdminService.clearToken();
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
    _flaggedReviews = [];
    _flaggedReviewStatusFilter = 'all';
    _flaggedClientReviews = [];
    _flaggedClientReviewStatusFilter = 'all';
    _moderationItems = [];
    _closedJobs = [];
    _closedAccounts = [];
    _scamStatusFilter = 'all';
    _moderationReviewedFilter = 'all';
    _moderationTypeFilter = 'all';
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
    _isAiLoading = false;
    _isClosedLoading = false;
    _error = null;
    notifyListeners();
  }
}
