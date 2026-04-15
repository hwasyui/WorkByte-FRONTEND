// ── lib/providers/job_post_provider.dart ────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/job_post_model.dart';
import '../models/job_role_model.dart';
import '../models/job_payment_model.dart';
import '../services/job_post_service.dart';
import '../services/job_payment_service.dart';

class JobPostProvider extends ChangeNotifier {
  final JobPostService _jobPostService = JobPostService();
  final JobPaymentService _paymentService = JobPaymentService();

  bool _isLoading = false;
  String? _error;
  List<JobPostModel> _jobPosts = [];
  JobPostModel? _currentJobPost;
  List<JobRoleModel> _jobRoles = [];

  // ── Draft state ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _draftJobData;
  List<Map<String, dynamic>> _draftRoles = [];
  JobPaymentDraft? _draftPayment;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<JobPostModel> get jobPosts => _jobPosts;
  JobPostModel? get currentJobPost => _currentJobPost;
  List<JobRoleModel> get jobRoles => _jobRoles;
  Map<String, dynamic>? get draftJobData => _draftJobData;
  List<Map<String, dynamic>> get draftRoles => List.unmodifiable(_draftRoles);
  JobPaymentDraft? get draftPayment => _draftPayment;

  // ── Draft setters ─────────────────────────────────────────────────────────
  void setDraftJobData(Map<String, dynamic> data) {
    _draftJobData = data;
    notifyListeners();
  }

  void setDraftRoles(List<Map<String, dynamic>> roles) {
    _draftRoles = roles;
    notifyListeners();
  }

  void setDraftPayment(JobPaymentDraft draft) {
    _draftPayment = draft;
    notifyListeners();
  }

  void clearDraft() {
    _draftJobData = null;
    _draftRoles = [];
    _draftPayment = null;
    notifyListeners();
  }

  // ── Job Posts ─────────────────────────────────────────────────────────────
  Future<void> fetchAllJobPosts(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _jobPosts = await _jobPostService.getAllJobPosts(token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchClientJobPosts(String token, String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _jobPosts = await _jobPostService.getJobPostsByClient(token, clientId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<JobPostModel?> createJobPost(
    String token,
    Map<String, dynamic> data,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _jobPostService.createJobPost(token, data);
      _currentJobPost = created;
      _jobPosts = [created, ..._jobPosts];
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> fetchMyJobPosts(
    String token,
    String clientId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final posts = await _jobPostService.getJobPostsByClient(token, clientId);
      _jobPosts = posts;
      _isLoading = false;
      notifyListeners();
      return posts.map((p) => p.toMap()).toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateJobPost(
    String token,
    String jobPostId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updated = await _jobPostService.updateJobPost(
        token,
        jobPostId,
        data,
      );
      _currentJobPost = updated;
      _jobPosts = _jobPosts
          .map((j) => j.jobPostId == jobPostId ? updated : j)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteJobPost(String token, String jobPostId) async {
    try {
      await _jobPostService.deleteJobPost(token, jobPostId);
      _jobPosts = _jobPosts.where((j) => j.jobPostId != jobPostId).toList();
      if (_currentJobPost?.jobPostId == jobPostId) _currentJobPost = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Job Roles ─────────────────────────────────────────────────────────────
  Future<void> fetchJobRoles(String token, String jobPostId) async {
    try {
      _jobRoles = await _jobPostService.getJobRoles(token, jobPostId);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<JobRoleModel?> createJobRole(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final created = await _jobPostService.createJobRole(token, data);
      _jobRoles = [..._jobRoles, created];
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteJobRole(String token, String jobRoleId) async {
    try {
      await _jobPostService.deleteJobRole(token, jobRoleId);
      _jobRoles = _jobRoles.where((r) => r.jobRoleId != jobRoleId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Payment + Milestones ──────────────────────────────────────────────────
  Future<JobPaymentModel?> createPaymentWithMilestones({
    required String token,
    required String jobPostId,
    required JobPaymentDraft draft,
  }) async {
    try {
      // 1. Create payment record
      final payment = await _paymentService.createPayment(token, {
        'job_post_id': jobPostId,
        'payment_type': draft.isFullPayment ? 'full' : 'milestone',
        'payment_option': draft.paymentOption,
      });

      // 2. Create each milestone if milestone-based
      if (!draft.isFullPayment && draft.milestones.isNotEmpty) {
        for (final m in draft.milestones) {
          await _paymentService.createMilestone(
            token,
            m.toJson(payment.jobPaymentId),
          );
        }
      }

      return payment;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrent() {
    _currentJobPost = null;
    _jobRoles = [];
    notifyListeners();
  }
}
