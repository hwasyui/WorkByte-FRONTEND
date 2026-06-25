import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/contract_submission_model.dart';
import '../services/contract_submission_service.dart';

class ContractSubmissionProvider extends ChangeNotifier {
  final ContractSubmissionService _service = ContractSubmissionService();

  List<ContractSubmissionModel> _submissions = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;

  List<ContractSubmissionModel> get submissions => _submissions;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get errorMessage => _errorMessage;
  bool get hasSubmissions => _submissions.isNotEmpty;

  ContractSubmissionModel? get latestSubmission =>
      _submissions.isEmpty ? null : _submissions.first;

  Future<void> fetchSubmissions({
    required String token,
    required String contractId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _submissions = await _service.getSubmissionsByContract(token, contractId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSubmission({
    required String token,
    required String contractId,
    required List<File> files,
    String? note,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createSubmission(
        token: token,
        contractId: contractId,
        files: files,
        note: note,
      );

      _submissions = await _service.getSubmissionsByContract(token, contractId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> requestRevisionForLatestSubmission({
    required String token,
    required String contractId,
    String? note, // ← add this
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.requestRevisionForLatestSubmission(
        token: token,
        contractId: contractId,
        note: note, // ← pass through
      );

      _submissions = await _service.getSubmissionsByContract(token, contractId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> approveLatestSubmission({
    required String token,
    required String contractId,
  }) async {
    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.approveLatestSubmission(
        token: token,
        contractId: contractId,
      );

      _submissions = await _service.getSubmissionsByContract(token, contractId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _submissions = [];
    _isLoading = false;
    _isUploading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
