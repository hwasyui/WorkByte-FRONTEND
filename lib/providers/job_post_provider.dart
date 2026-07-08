import 'dart:io';
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

  String? _categoryFilter;

  final Map<String, List<JobRoleSkillModel>> _roleSkillsCache = {};
  final Map<String, List<JobFileModel>> _jobFilesCache = {};

  Map<String, dynamic>? _draftJobData;
  List<Map<String, dynamic>> _draftRoles = [];
  Map<int, List<String>> _draftRoleSkills = {};
  Map<int, List<String>> _draftRoleSkillNames = {};
  Map<int, Map<String, dynamic>> _draftRoleSkillMeta = {};
  List<Map<String, dynamic>> _draftFiles = [];

  bool _isDraftSaving = false;
  DateTime? _lastDraftSavedAt;

  List<JobPostModel> _draftJobPosts = [];

  List<JobFileModel> filesForJob(String jobPostId) =>
      _jobFilesCache[jobPostId] ?? [];

  bool get isLoading => _isLoading;
  bool get isDraftSaving => _isDraftSaving;
  DateTime? get lastDraftSavedAt => _lastDraftSavedAt;
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
  Map<int, Map<String, dynamic>> get draftRoleSkillMeta =>
      Map.unmodifiable(_draftRoleSkillMeta);
  List<Map<String, dynamic>> get draftFiles => List.unmodifiable(_draftFiles);
  List<JobPostModel> get draftJobPosts => List.unmodifiable(_draftJobPosts);

  List<JobRoleSkillModel> skillsForRole(String jobRoleId) =>
      _roleSkillsCache[jobRoleId] ?? [];

  String? get currentProjectCategory => _currentJobPost?.projectCategory;
  String? get categoryFilter => _categoryFilter;

  List<JobPostModel> get filteredJobPosts {
    if (_categoryFilter == null || _categoryFilter!.isEmpty) return _jobPosts;
    return _jobPosts
        .where((p) => p.projectCategory == _categoryFilter)
        .toList();
  }

  List<String> get availableCategories =>
      _jobPosts
          .map((p) => p.projectCategory ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setDraftJobData(Map data, {bool notify = true}) {
    _draftJobData = {...?_draftJobData, ...data.cast<String, dynamic>()};
    if (notify) notifyListeners();
  }

  void setDraftRoles(List<Map<String, dynamic>> roles) {
    _draftRoles = roles;
    notifyListeners();
  }

  void setDraftRoleSkills(
    int roleIndex,
    List skillIds, {
    List skillNames = const [],
  }) {
    _draftRoleSkills[roleIndex] = skillIds.map((e) => e.toString()).toList();
    _draftRoleSkillNames[roleIndex] = skillNames
        .map((e) => e.toString())
        .toList();
    notifyListeners();
  }

  void setDraftRoleSkillMeta(int roleIndex, Map meta) {
    _draftRoleSkillMeta[roleIndex] = meta.cast<String, dynamic>();
    notifyListeners();
  }

  void setDraftFiles(List<Map<String, dynamic>> files) {
    _draftFiles = files;
    notifyListeners();
  }

  String? get currentDraftJobPostId => _currentJobPost?.jobPostId;
  bool get hasPersistedDraft =>
      _currentJobPost != null && (_currentJobPost?.status == 'draft');

  Map<String, dynamic> _normalizeDraftPayload(Map source) {
    final payload = Map<String, dynamic>.from(source.cast<String, dynamic>());

    final durationValue = payload['estimated_duration_value'];
    final durationUnit = (payload['estimated_duration_unit'] ?? 'days')
        .toString()
        .toLowerCase();

    int? parsedDurationValue;
    if (durationValue is int) {
      parsedDurationValue = durationValue;
    } else if (durationValue is String) {
      parsedDurationValue = int.tryParse(durationValue);
    } else if (durationValue is num) {
      parsedDurationValue = durationValue.toInt();
    }

    if (parsedDurationValue != null && parsedDurationValue > 0) {
      payload['estimated_duration'] = '$parsedDurationValue $durationUnit';
      switch (durationUnit) {
        case 'week':
        case 'weeks':
          payload['working_days'] = parsedDurationValue * 7;
          break;
        case 'month':
        case 'months':
          payload['working_days'] = parsedDurationValue * 30;
          break;
        default:
          payload['working_days'] = parsedDurationValue;
      }
    }

    payload.remove('estimated_duration_value');
    payload.remove('estimated_duration_unit');
    payload['project_type'] = (payload['project_type'] ?? 'individual')
        .toString();
    payload['status'] = 'draft';
    return payload;
  }

  Future<JobPostModel?> saveDraftJob(String token) async {
    if (_draftJobData == null || _draftJobData!.isEmpty) {
      _error = 'No draft data to save';
      notifyListeners();
      return null;
    }

    _isDraftSaving = true;
    _error = null;
    notifyListeners();

    try {
      _draftJobData = {
        ...?_draftJobData,
        'project_type': (_draftJobData?['project_type'] ?? 'individual')
            .toString(),
      };

      final payload = _normalizeDraftPayload(_draftJobData!);
      JobPostModel? saved;
      final existingId = _currentJobPost?.jobPostId;

      if (existingId == null || existingId.isEmpty) {
        saved = await _jobPostService.createJobPost(token, payload);
        if (saved != null) {
          _jobPosts = [
            saved,
            ..._jobPosts.where((j) => j.jobPostId != saved!.jobPostId),
          ];
        }
      } else {
        saved = await _jobPostService.updateJobPost(token, existingId, payload);
        if (saved != null) {
          _jobPosts = _jobPosts
              .map((j) => j.jobPostId == existingId ? saved! : j)
              .toList();
        }
      }

      _currentJobPost = saved;
      _draftJobData = {
        ...?_draftJobData,
        if (saved?.jobPostId != null) 'job_post_id': saved!.jobPostId,
        if (payload['estimated_duration'] != null)
          'estimated_duration': payload['estimated_duration'],
        if (payload['working_days'] != null)
          'working_days': payload['working_days'],
        'project_type': payload['project_type'],
        'status': 'draft',
      };
      _lastDraftSavedAt = DateTime.now();
      await loadDraftJobs(
        token,
        _currentJobPost?.clientId ?? '',
        notify: false,
      );
      return saved;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isDraftSaving = false;
      notifyListeners();
    }
  }

  Future<void> loadDraftJobs(
    String token,
    String clientId, {
    bool notify = true,
  }) async {
    try {
      final posts = await _jobPostService.getJobPostsByClient(token, clientId);

      _jobPosts = posts;

      _draftJobPosts =
          posts.where((p) => (p.status).toLowerCase() == 'draft').toList()
            ..sort((a, b) {
              final aTime = DateTime.tryParse(a.updatedAt ?? a.createdAt ?? '');
              final bTime = DateTime.tryParse(b.updatedAt ?? b.createdAt ?? '');

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              return bTime.compareTo(aTime);
            });

      if (notify) notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      if (notify) notifyListeners();
    }
  }

  Future<void> setCurrentDraftById(String draftId) async {
    try {
      _currentJobPost = _draftJobPosts.firstWhere(
        (p) => p.jobPostId == draftId,
      );
    } catch (_) {
      try {
        _currentJobPost = _jobPosts.firstWhere((p) => p.jobPostId == draftId);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> loadDraftJobById(
    String token,
    String clientId,
    String draftId,
  ) async {
    try {
      await loadDraftJobs(token, clientId, notify: false);

      await setCurrentDraftById(draftId);

      if (_currentJobPost != null) {
        _draftJobData = {
          'job_post_id': _currentJobPost!.jobPostId,
          'job_title': _currentJobPost!.jobTitle,
          'job_description': _currentJobPost!.jobDescription,
          'project_type': _currentJobPost!.projectType,
          'estimated_duration': _currentJobPost!.estimatedDuration,
          'working_days': _currentJobPost!.workingDays,
          'experience_level': _currentJobPost!.experienceLevel,
          'deadline': _currentJobPost!.deadline,
          'status': 'draft',
        };
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> deleteDraftJob(String token, String jobPostId) async {
    final deleted = await deleteJobPost(token, jobPostId);
    if (deleted) {
      _draftJobPosts = _draftJobPosts
          .where((j) => j.jobPostId != jobPostId)
          .toList();
      if (_currentJobPost?.jobPostId == jobPostId) {
        clearDraft();
      } else {
        notifyListeners();
      }
    }
    return deleted;
  }

  void clearDraft() {
    _draftJobData = null;
    _draftRoles = [];
    _draftRoleSkills = {};
    _draftRoleSkillNames = {};
    _draftRoleSkillMeta = {};
    _draftFiles = [];
    _lastDraftSavedAt = null;
    if (_currentJobPost?.status == 'draft') {
      _currentJobPost = null;
    }
    notifyListeners();
  }

  Future<void> fetchAllJobPosts(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _jobPosts = await _jobPostService.getAllJobPosts(token, pageSize: 100);
      _draftJobPosts = _jobPosts
          .where((p) => (p.status ?? '').toLowerCase() == 'draft')
          .toList();
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
      _draftJobPosts = _jobPosts
          .where((p) => (p.status ?? '').toLowerCase() == 'draft')
          .toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchJobPostsByCategory(String token, String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _jobPosts = await _jobPostService.getAllJobPosts(
        token,
        pageSize: 100,
        category: category,
      );
      _draftJobPosts = _jobPosts
          .where((p) => (p.status ?? '').toLowerCase() == 'draft')
          .toList();
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
      _draftJobPosts = _jobPosts
          .where((p) => (p.status ?? '').toLowerCase() == 'draft')
          .toList();
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

  Future<JobPostModel?> updateJobPost({
    required String token,
    required String jobPostId,
    required Map<String, dynamic> data,
  }) async {
    _error = null;
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
      _draftJobPosts = _jobPosts
          .where((p) => (p.status ?? '').toLowerCase() == 'draft')
          .toList();
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteJobPost(String token, String jobPostId) async {
    try {
      await _jobPostService.deleteJobPost(token, jobPostId);
      _jobPosts = _jobPosts.where((j) => j.jobPostId != jobPostId).toList();
      _draftJobPosts = _draftJobPosts
          .where((j) => j.jobPostId != jobPostId)
          .toList();
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

  Future<JobRoleModel?> updateJobRole({
    required String token,
    required String jobRoleId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final updated = await _jobPostService.updateJobRole(
        token,
        jobRoleId,
        data,
      );
      _jobRoles = _jobRoles
          .map((r) => r.jobRoleId == jobRoleId ? updated : r)
          .toList();
      _error = null;
      notifyListeners();
      return updated;
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

  Future<bool> uploadJobFiles(
    String token,
    String jobPostId,
    List<File> files,
  ) async {
    try {
      final createdFiles = await _jobPostService.uploadJobFiles(
        token: token,
        jobPostId: jobPostId,
        files: files,
      );
      _jobFilesCache[jobPostId] = [...filesForJob(jobPostId), ...createdFiles];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Upload a single file immediately for per-file autosave on the Files step.
  /// Reuses the existing multipart upload, but returns the created model
  /// directly so the UI can track status per-file.
  Future<JobFileModel?> uploadSingleJobFile(
    String token,
    String jobPostId,
    File file,
  ) async {
    try {
      final created = await _jobPostService.uploadJobFiles(
        token: token,
        jobPostId: jobPostId,
        files: [file],
      );
      if (created.isEmpty) return null;
      final uploaded = created.first;
      _jobFilesCache[jobPostId] = [...filesForJob(jobPostId), uploaded];
      notifyListeners();
      return uploaded;
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
