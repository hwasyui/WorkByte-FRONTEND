import 'package:flutter/foundation.dart';
import '../models/contract_model.dart';
import '../services/contract_service.dart';

class ContractProvider extends ChangeNotifier {
  final _service = ContractService();

  List<ContractModel> _contracts = [];
  ContractModel? _currentContract;
  String? _error;
  bool _isLoading = false;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<ContractModel> get contracts => _contracts;
  ContractModel? get currentContract => _currentContract;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // ── Fetch all contracts ───────────────────────────────────────────────────

  Future<void> fetchAllContracts(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _contracts = await _service.getAllContracts(token);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Fetch contracts for client ────────────────────────────────────────────

  Future<void> fetchContractsByClient(String token, String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _contracts = await _service.getContractsByClient(token, clientId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Fetch contracts for freelancer ────────────────────────────────────────

  Future<void> fetchContractsByFreelancer(
    String token,
    String freelancerId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _contracts = await _service.getContractsByFreelancer(token, freelancerId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Fetch single contract ─────────────────────────────────────────────────

  Future<void> fetchContractById(String token, String contractId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentContract = await _service.getContractById(token, contractId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Fetch generation data ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchGenerationData(
    String token,
    String contractId,
  ) async {
    try {
      return await _service.getContractGenerationData(token, contractId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // ── Fetch PDF URL ─────────────────────────────────────────────────────────

  Future<String> fetchPdfUrl(String token, String contractId) async {
    try {
      return await _service.getContractPdfUrl(token, contractId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // ── Create contract ───────────────────────────────────────────────────────

  Future<ContractModel?> createContract(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final contract = await _service.createContract(token, data);
      _currentContract = contract;
      _contracts.add(contract);
      notifyListeners();
      return contract;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Generate contract PDF ─────────────────────────────────────────────────

  Future<bool> generateContractPdf(
    String token,
    String contractId,
    Map<String, dynamic> generationData,
  ) async {
    try {
      final updated = await _service.generateContractPdf(
        token,
        contractId,
        generationData,
      );
      if (_currentContract?.contractId == contractId) {
        _currentContract = updated;
      }
      _contracts = _contracts
          .map((c) => c.contractId == contractId ? updated : c)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Update contract status (accept, reject, etc.) ─────────────────────────

  Future<bool> updateContract(
    String token,
    String contractId,
    Map<String, dynamic> data,
  ) async {
    try {
      final updated = await _service.updateContract(token, contractId, data);
      if (_currentContract?.contractId == contractId) {
        _currentContract = updated;
      }
      _contracts = _contracts
          .map((c) => c.contractId == contractId ? updated : c)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateContractStatus(
    String token,
    String contractId,
    String status,
  ) async {
    try {
      final updated = await _service.updateContract(token, contractId, {
        'status': status,
      });
      if (_currentContract?.contractId == contractId) {
        _currentContract = updated;
      }
      _contracts = _contracts
          .map((c) => c.contractId == contractId ? updated : c)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Accept contract ───────────────────────────────────────────────────────

  Future<bool> acceptContract(String token, String contractId) async {
    return updateContractStatus(token, contractId, 'accepted');
  }

  // ── Reject contract ───────────────────────────────────────────────────────

  Future<bool> rejectContract(String token, String contractId) async {
    return updateContractStatus(token, contractId, 'rejected');
  }

  // ── Clear error ───────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Clear current contract ────────────────────────────────────────────────

  void clearCurrentContract() {
    _currentContract = null;
    notifyListeners();
  }
}
