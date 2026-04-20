import 'package:flutter/foundation.dart';
import '../models/contract_model.dart';
import '../services/contract_service.dart';

class ContractProvider extends ChangeNotifier {
  final _service = ContractService();

  List<ContractModel> _contracts = [];
  ContractModel? _currentContract;
  String? _error;
  bool _isLoading = false;

  List<ContractModel> get contracts => _contracts;
  ContractModel? get currentContract => _currentContract;
  String? get error => _error;
  bool get isLoading => _isLoading;

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

  Future<String> fetchPdfUrl(String token, String contractId) async {
    try {
      return await _service.getContractPdfUrl(token, contractId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

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

  Future<bool> acceptContract(String token, String contractId) async {
    return updateContractStatus(token, contractId, 'accepted');
  }

  Future<bool> rejectContract(String token, String contractId) async {
    return updateContractStatus(token, contractId, 'rejected');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentContract() {
    _currentContract = null;
    notifyListeners();
  }
}
