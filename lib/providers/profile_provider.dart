import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client_model.dart';
import '../models/freelancer_model.dart';
import '../models/education_model.dart';
import '../models/experience_model.dart';
import '../models/freelancer_skill_model.dart';
import '../models/portfolio_model.dart';
import '../services/profile_service.dart';
import '../services/portfolio_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();
  final PortfolioService _portfolioService = PortfolioService();

  bool _isLoading = false;
  String? _error;
  ClientModel? _clientProfile;
  FreelancerModel? _freelancerProfile;

  // Separate lists for freelancer data (no longer nested in FreelancerModel)
  List<EducationModel> _educations = const [];
  List<ExperienceModel> _experiences = const [];
  List<FreelancerSkillModel> _skills = const [];
  List<PortfolioModel> _portfolios = const [];

  String? _userType;

  // ─── Getters ──────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get error => _error;
  ClientModel? get clientProfile => _clientProfile;
  FreelancerModel? get freelancerProfile => _freelancerProfile;
  String? get userType => _userType;

  bool get hasProfile => _clientProfile != null || _freelancerProfile != null;
  bool get isClient => _userType == 'client';
  bool get isFreelancer => _userType == 'freelancer';

  // Convenience getters for external lists
  List<EducationModel> get educations => _educations;
  List<ExperienceModel> get experiences => _experiences;
  List<FreelancerSkillModel> get skills => _skills;
  List<PortfolioModel> get portfolios => _portfolios;

  // Keep this the same from the service perspective
  bool get isProfileComplete {
    if (isClient) {
      final c = _clientProfile;
      if (c == null) return false;
      return (c.fullName?.isNotEmpty ?? false) && (c.bio?.isNotEmpty ?? false);
    }
    if (isFreelancer) {
      final f = _freelancerProfile;
      if (f == null) return false;
      return f.fullName.isNotEmpty &&
          (f.bio?.isNotEmpty ?? false) &&
          (f.cvFileUrl?.isNotEmpty ?? false) &&
          educations.isNotEmpty &&
          experiences.isNotEmpty &&
          skills.isNotEmpty;
    }
    return false;
  }

  List<String> get missingProfileFields {
    if (isClient) {
      final c = _clientProfile;
      if (c == null) return ['Profile not loaded'];
      return [
        if (c.fullName?.isEmpty ?? true) 'Full name',
        if (c.bio?.isEmpty ?? true) 'Bio',
      ];
    }
    if (isFreelancer) {
      final f = _freelancerProfile;
      if (f == null) return ['Profile not loaded'];
      return [
        if (f.fullName.isEmpty) 'Full name',
        if (f.bio?.isEmpty ?? true) 'Bio',
        if (f.cvFileUrl?.isEmpty ?? true) 'CV',
        if (educations.isEmpty) 'Education',
        if (experiences.isEmpty) 'Work experience',
        if (skills.isEmpty) 'Skills',
      ];
    }
    return [];
  }

  bool get isOnboardingComplete {
    if (isClient) {
      final c = _clientProfile;
      if (c == null) return false;
      return (c.fullName?.trim().isNotEmpty ?? false) &&
          (c.bio?.trim().isNotEmpty ?? false);
    }

    if (isFreelancer) {
      final f = _freelancerProfile;
      if (f == null) return false;
      return f.fullName.trim().isNotEmpty &&
          (f.bio?.trim().isNotEmpty ?? false) &&
          _skills.isNotEmpty &&
          _experiences.isNotEmpty &&
          _educations.isNotEmpty;
    }

    return false;
  }

  List<String> get missingOnboardingFields {
    if (isClient) {
      final c = _clientProfile;
      if (c == null) return ['Profile not loaded'];
      return [
        if (c.fullName?.trim().isEmpty ?? true) 'Full name',
        if (c.bio?.trim().isEmpty ?? true) 'Bio',
      ];
    }

    if (isFreelancer) {
      final f = _freelancerProfile;
      if (f == null) return ['Profile not loaded'];
      return [
        if (f.fullName.trim().isEmpty) 'Full name',
        if (f.bio?.trim().isEmpty ?? true) 'Bio',
        if (_skills.isEmpty) 'Skills',
        if (_experiences.isEmpty) 'Work experience',
        if (_educations.isEmpty) 'Education',
      ];
    }

    return [];
  }

  String get displayName {
    if (isClient) return _clientProfile?.displayName ?? 'User';
    return _freelancerProfile?.displayName ?? 'User';
  }

  String? get profilePictureUrl {
    if (isClient) return _clientProfile?.profilePictureUrl;
    if (isFreelancer) return _freelancerProfile?.profilePictureUrl;
    return null;
  }

  // Getters for both profiles (used in account switcher)
  String get freelancerDisplayName =>
      _freelancerProfile?.displayName ?? 'Freelancer Account';
  String get clientDisplayName =>
      _clientProfile?.displayName ?? 'Company Account';
  String? get freelancerProfilePictureUrl =>
      _freelancerProfile?.profilePictureUrl;
  String? get clientProfilePictureUrl => _clientProfile?.profilePictureUrl;

  String? get bio {
    if (isClient) return _clientProfile?.bio;
    if (isFreelancer) return _freelancerProfile?.bio;
    return null;
  }

  String get jobTitle {
    if (isClient) return _clientProfile?.jobTitle ?? '-';
    if (isFreelancer) return _freelancerProfile?.jobTitle ?? '-';
    return '-';
  }

  // ─── Fetch ────────────────────────────────────────────────────────────────

  Future<bool> fetchProfile({
    required String token,
    required String userId,
    required String userType,
  }) async {
    _isLoading = true;
    _error = null;
    _userType = userType;
    notifyListeners();

    try {
      if (userType == 'client') {
        _clientProfile = await _service.fetchClientProfile(token, userId);
        _educations = [];
        _experiences = [];
        _skills = [];
      } else {
        _freelancerProfile = await _service.fetchFreelancerProfile(
          token,
          userId,
        );
        await refreshFreelancerDetails(token);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reload education, experience, skills, and portfolios from the services.
  /// Call after adding/deleting any of these items.
  Future<void> refreshFreelancerDetails(String token) async {
    final id = _freelancerProfile?.freelancerId;
    if (id == null) return;

    final results = await Future.wait([
      _service.getEducations(token, id),
      _service.getWorkExperiences(token, id),
      _service.getFreelancerSkills(token, id),
      _portfolioService.getPortfolios(token),
    ]);

    _educations = results[0] as List<EducationModel>;
    _experiences = results[1] as List<ExperienceModel>;
    _skills = results[2] as List<FreelancerSkillModel>;
    _portfolios = results[3] as List<PortfolioModel>;
    notifyListeners();
  }

  /// Directly fetch a single client by ID.
  Future<ClientModel?> fetchClientById({
    required String token,
    required String clientId,
  }) async {
    return await _service.fetchClientById(token, clientId);
  }

  /// Directly fetch a single freelancer by ID.
  Future<FreelancerModel?> fetchFreelancerById({
    required String token,
    required String freelancerId,
  }) async {
    return await _service.fetchFreelancerById(token, freelancerId);
  }

  // ─── Update profile ───────────────────────────────────────────────────────

  Future<bool> updateProfile({
    required String token,
    required String identifier,
    required Map<String, dynamic> fields,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (isClient) {
        _clientProfile = await _service.updateClientProfile(
          token,
          identifier,
          fields,
        );
      } else {
        _freelancerProfile = await _service.updateFreelancerProfile(
          token,
          identifier,
          fields,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on Object catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Profile picture ──────────────────────────────────────────────────────

  Future<bool> uploadProfilePicture({
    required String token,
    required String identifier,
    required File imageFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _clearImageCache();
      if (isClient) {
        _clientProfile = await _service.uploadClientProfilePicture(
          token,
          identifier,
          imageFile,
        );
      } else {
        _freelancerProfile = await _service.uploadFreelancerProfilePicture(
          token,
          identifier,
          imageFile,
        );
      }
      _clearImageCache();
      _isLoading = false;
      notifyListeners();
      return true;
    } on Object catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProfilePicture({
    required String token,
    required String identifier,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _clearImageCache();
      if (isClient) {
        _clientProfile = await _service.deleteClientProfilePicture(
          token,
          identifier,
        );
      } else {
        _freelancerProfile = await _service.deleteFreelancerProfilePicture(
          token,
          identifier,
        );
      }
      _clearImageCache();
      _isLoading = false;
      notifyListeners();
      return true;
    } on Object catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Education ────────────────────────────────────────────────────────────

  Future<bool> addEducation({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final ok = await _service.createEducation(token, data);
    if (ok) {
      await refreshFreelancerDetails(token);
    }
    return ok;
  }

  Future<bool> removeEducation({
    required String token,
    required String educationId,
  }) async {
    final ok = await _service.deleteEducation(token, educationId);
    if (ok) {
      _educations = _educations
          .where((e) => e.educationId != educationId)
          .toList();
      notifyListeners();
    }
    return ok;
  }

  // ─── Work experience ──────────────────────────────────────────────────────

  Future<bool> addWorkExperience({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final ok = await _service.createWorkExperience(token, data);
    if (ok) {
      await refreshFreelancerDetails(token);
    }
    return ok;
  }

  Future<bool> removeWorkExperience({
    required String token,
    required String workExperienceId,
  }) async {
    final ok = await _service.deleteWorkExperience(token, workExperienceId);
    if (ok) {
      _experiences = _experiences
          .where((e) => e.workExperienceId != workExperienceId)
          .toList();
      notifyListeners();
    }
    return ok;
  }

  // ─── Skills ───────────────────────────────────────────────────────────────

  Future<bool> addFreelancerSkill({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    final ok = await _service.addFreelancerSkill(token, data);
    if (ok) {
      await refreshFreelancerDetails(token);
    }
    return ok;
  }

  Future<bool> removeFreelancerSkill({
    required String token,
    required String freelancerSkillId,
  }) async {
    final ok = await _service.deleteFreelancerSkill(token, freelancerSkillId);
    if (ok) {
      _skills = _skills
          .where((s) => s.freelancerSkillId != freelancerSkillId)
          .toList();
      notifyListeners();
    }
    return ok;
  }

  // ─── Portfolio ──────────────────────────────────────────────────

  Future<bool> addPortfolio({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final item = await _portfolioService.createPortfolio(token, data);
      _portfolios = [item, ..._portfolios];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> removePortfolio({
    required String token,
    required String portfolioId,
  }) async {
    try {
      await _portfolioService.deletePortfolio(token, portfolioId);
      _portfolios = _portfolios
          .where((p) => p.portfolioId != portfolioId)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Keep this as‑is, these are just pass‑through to services
  Future<List<Map<String, dynamic>>> getAllSkills(String token) =>
      _service.getAllSkills(token);

  Future<List<Map<String, dynamic>>> searchSkills(String token, String term) =>
      _service.searchSkills(token, term);

  Future<Map<String, dynamic>?> createSkill(
    String token,
    Map<String, dynamic> data,
  ) => _service.createSkill(token, data);

  // ─── Upload CV ──────────────────────────────────────────────────

  Future<bool> uploadCV({required String token, required File file}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.uploadCV(token: token, file: file);

      final data = result['data'] as Map<String, dynamic>?;
      final fileUrl = data?['file_url']?.toString();

      if (fileUrl != null && fileUrl.isNotEmpty) {
        _freelancerProfile = _freelancerProfile?.copyWith(cvFileUrl: fileUrl);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Local state helpers ──────────────────────────────────────────────────

  void updateJobTitle(String jobTitle) {
    if (isClient) {
      _clientProfile = _clientProfile?.copyWith(jobTitle: jobTitle);
    } else {
      _freelancerProfile = _freelancerProfile?.copyWith(jobTitle: jobTitle);
    }
    notifyListeners();
  }

  void updateProfilePictureUrl(String url) {
    _clearImageCache();
    if (isClient) {
      _clientProfile = _clientProfile?.copyWith(profilePictureUrl: url);
    } else {
      _freelancerProfile = _freelancerProfile?.copyWith(profilePictureUrl: url);
    }
    notifyListeners();
  }

  void clearProfilePicture() {
    _clearImageCache();
    if (isClient) {
      _clientProfile = _clientProfile?.copyWith(profilePictureUrl: null);
    } else {
      _freelancerProfile = _freelancerProfile?.copyWith(
        profilePictureUrl: null,
      );
    }
    notifyListeners();
  }

  void forceRefreshProfilePicture() {
    _clearImageCache();
    notifyListeners();
  }

  Future<bool> switchRole({
    required String token,
    required String userId,
    required String newRole,
  }) async {
    if (_userType == newRole) return true;
    return await fetchProfile(token: token, userId: userId, userType: newRole);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _clientProfile = null;
    _freelancerProfile = null;
    _userType = null;
    _error = null;
    _educations = const [];
    _experiences = const [];
    _skills = const [];
    notifyListeners(); // resets both profiles on logout
  }

  void _clearImageCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }
}
