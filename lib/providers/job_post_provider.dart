import 'package:flutter/material.dart';
import '../models/job_post_model.dart';
import '../models/job_role_model.dart';
import '../models/job_role_skill_model.dart';
import '../models/job_file_model.dart';
import '../services/job_post_service.dart';

class JobPostProvider extends ChangeNotifier {
  final JobPostService _jobPostService = JobPostService();

  bool _isLoading = false;
  String? _error;
  List<JobPostModel> _jobPosts = [];
  JobPostModel? _currentJobPost;
  List<JobRoleModel> _jobRoles = [];

  // ── Per-role skills cache: jobRoleId → List<JobRoleSkillModel>
  final Map<String, List<JobRoleSkillModel>> _roleSkillsCache = {};

  // ── Job files cache: jobPostId → List<JobFileModel>
  final Map<String, List<JobFileModel>> _jobFilesCache = {};

  // ── Draft state ───────────────────────────────────────────────────────────
  Map<String, dynamic>? _draftJobData;
  List<Map<String, dynamic>> _draftRoles = [];

  // skill IDs per role index: { roleIndex → [skill_id, ...] }
  Map<int, List<String>> _draftRoleSkills = {};

  // skill display names per role index: { roleIndex → [skill_name, ...] }
  Map<int, List<String>> _draftRoleSkillNames = {};

  // full skill metadata per role index:
  // { roleIndex → { skill_id → { skill_name, is_required, importance_level } } }
  Map<int, Map<String, Map<String, dynamic>>> _draftRoleSkillMeta = {};

  // files to attach: list of { file_name, file_url, file_type, file_size }
  List<Map<String, dynamic>> _draftFiles = [];

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<JobPostModel> get jobPosts => _jobPosts;
  JobPostModel? get currentJobPost => _currentJobPost;
  List<JobRoleModel> get jobRoles => _jobRoles;
  Map<String, dynamic>? get draftJobData => _draftJobData;
  List<Map<String, dynamic>> get draftRoles => List.unmodifiable(_draftRoles);
  Map<int, List<String>> get draftRoleSkills =>
      Map.unmodifiable(_draftRoleSkills);
  Map<int, List<String>> get draftRoleSkillNames =>
      Map.unmodifiable(_draftRoleSkillNames);
  Map<int, Map<String, Map<String, dynamic>>> get draftRoleSkillMeta =>
      Map.unmodifiable(_draftRoleSkillMeta);
  List<Map<String, dynamic>> get draftFiles => List.unmodifiable(_draftFiles);

  List<JobRoleSkillModel> skillsForRole(String jobRoleId) =>
      _roleSkillsCache[jobRoleId] ?? [];

  List<JobFileModel> filesForJob(String jobPostId) =>
      _jobFilesCache[jobPostId] ?? [];

  // ── Draft setters ─────────────────────────────────────────────────────────
  void setDraftJobData(Map<String, dynamic> data) {
    _draftJobData = data;
    notifyListeners();
  }

  void setDraftRoles(List<Map<String, dynamic>> roles) {
    _draftRoles = roles;
    notifyListeners();
  }

  void setDraftRoleSkills(
    int roleIndex,
    List<String> skillIds, {
    List<String> skillNames = const [],
  }) {
    _draftRoleSkills[roleIndex] = skillIds;
    _draftRoleSkillNames[roleIndex] = skillNames;
    notifyListeners();
  }

  void setDraftRoleSkillMeta(
    int roleIndex,
    Map<String, Map<String, dynamic>> meta,
  ) {
    _draftRoleSkillMeta[roleIndex] = meta;
    notifyListeners();
  }

  void setDraftFiles(List<Map<String, dynamic>> files) {
    _draftFiles = files;
    notifyListeners();
  }

  void clearDraft() {
    _draftJobData = null;
    _draftRoles = [];
    _draftRoleSkills = {};
    _draftRoleSkillNames = {};
    _draftRoleSkillMeta = {};
    _draftFiles = [];
    notifyListeners();
  }

  // ── Job Posts ─────────────────────────────────────────────────────────────
  Future<void> fetchAllJobPosts(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _jobPosts = await _jobPostService.getAllJobPosts(token, pageSize: 100);
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
      _jobFilesCache.remove(jobPostId);
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
      _roleSkillsCache.remove(jobRoleId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Job Role Skills ───────────────────────────────────────────────────────
  Future<void> fetchRoleSkills(String token, String jobRoleId) async {
    try {
      final skills = await _jobPostService.getJobRoleSkills(token, jobRoleId);
      _roleSkillsCache[jobRoleId] = skills;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<JobRoleSkillModel?> createRoleSkill(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final created = await _jobPostService.createJobRoleSkill(token, data);
      final roleId = created.jobRoleId;
      _roleSkillsCache[roleId] = [...skillsForRole(roleId), created];
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteRoleSkill(
    String token,
    String jobRoleSkillId,
    String jobRoleId,
  ) async {
    try {
      await _jobPostService.deleteJobRoleSkill(token, jobRoleSkillId);
      _roleSkillsCache[jobRoleId] = skillsForRole(
        jobRoleId,
      ).where((s) => s.jobRoleSkillId != jobRoleSkillId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Job Files ─────────────────────────────────────────────────────────────
  Future<void> fetchJobFiles(String token, String jobPostId) async {
    try {
      final files = await _jobPostService.getJobFiles(token, jobPostId);
      _jobFilesCache[jobPostId] = files;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<JobFileModel?> createJobFile(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final created = await _jobPostService.createJobFile(token, data);
      final postId = created.jobPostId;
      _jobFilesCache[postId] = [...filesForJob(postId), created];
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteJobFile(
    String token,
    String jobFileId,
    String jobPostId,
  ) async {
    try {
      await _jobPostService.deleteJobFile(token, jobFileId);
      _jobFilesCache[jobPostId] = filesForJob(
        jobPostId,
      ).where((f) => f.jobFileId != jobFileId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
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
