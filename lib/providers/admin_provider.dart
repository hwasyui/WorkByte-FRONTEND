import 'package:flutter/material.dart';
import '../services/admin_service.dart';

enum AdminPage { overview, users, jobs }

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

  Future<void> loadOverviewData() async {
    if (_token == null) return;

    try {
      final results = await Future.wait([
        AdminService.getFreelancers(_token!, page: 1, pageSize: 5),
        AdminService.getClients(_token!, page: 1, pageSize: 5),
        AdminService.getJobPosts(_token!, page: 1, pageSize: 5),
      ]);

      final freelancerResult = results[0];
      final clientResult = results[1];
      final jobResult = results[2];

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
    } catch (e) {
      debugPrint('AdminProvider.loadOverviewData error: $e');
    }
    notifyListeners();
  }

  Future<void> loadFreelancersPage(int page) async {
    if (_token == null) return;
    _isTableLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getFreelancers(
        _token!,
        page: page,
        pageSize: 20,
      );
      _tableFreelancers = List<Map<String, dynamic>>.from(
        data['items'] ?? [],
      );
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

  Future<void> loadClientsPage(int page) async {
    if (_token == null) return;
    _isTableLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getClients(
        _token!,
        page: page,
        pageSize: 20,
      );
      _tableClients = List<Map<String, dynamic>>.from(data['items'] ?? []);
      _clientPagination = Map<String, dynamic>.from(
        data['pagination'] ?? {},
      );
      _totalClients =
          (_clientPagination['total'] as num?)?.toInt() ??
          _tableClients.length;
    } catch (e) {
      debugPrint('AdminProvider.loadClientsPage error: $e');
    }
    _isTableLoading = false;
    notifyListeners();
  }

  Future<void> loadJobsPage(int page) async {
    if (_token == null) return;
    _isTableLoading = true;
    notifyListeners();
    try {
      final data = await AdminService.getJobPosts(
        _token!,
        page: page,
        pageSize: 20,
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
    _error = null;
    notifyListeners();
  }
}
