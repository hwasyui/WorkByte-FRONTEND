import 'package:flutter/material.dart';
import '../models/skill_model.dart';
import '../services/skill_service.dart';

class SkillProvider extends ChangeNotifier {
  final SkillService _service = SkillService();

  List<SkillModel> _skills = [];
  List<SkillModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<SkillModel> get skills => _skills;
  List<SkillModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllSkills(String token) async {
    if (_skills.isNotEmpty) {
      if (_searchResults.isEmpty) {
        _searchResults = List.from(_skills);
        notifyListeners();
      }
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _skills = await _service.getAllSkills(token);
      _searchResults = List.from(_skills);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchSkills(String token, String term) async {
    if (term.trim().isEmpty) {
      _searchResults = List.from(_skills);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _service.searchSkills(token, term.trim());
    } catch (e) {
      _searchResults = _skills
          .where((s) => s.skillName.toLowerCase().contains(term.toLowerCase()))
          .toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
