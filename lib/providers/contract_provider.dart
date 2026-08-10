import 'package:flutter/foundation.dart';
import '../models/contract_milestone_model.dart';
import '../models/contract_model.dart';
import '../services/contract_service.dart';

class ContractProvider extends ChangeNotifier {
  final _service = ContractService();

  List<ContractModel> _contracts = [];
  ContractModel? _currentContract;
  String? _error;
  bool _isLoading = false;

  /// Milestone schedules keyed by contract id. Cached per contract rather than
  /// held as a single "current" list because the workspace and the payment
  /// section both read it, and they are rebuilt independently.
  final Map<String, List<ContractMilestoneModel>> _milestones = {};

  List<ContractModel> get contracts => _contracts;
  ContractModel? get currentContract => _currentContract;
  String? get error => _error;
  bool get isLoading => _isLoading;

  /// The last loaded schedule for [contractId], or an empty list if it has not
  /// been fetched yet.
  List<ContractMilestoneModel> milestonesFor(String contractId) =>
      _milestones[contractId] ?? const [];

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

  /// Loads the milestone schedule for [contractId]. Returns an empty list on
  /// failure rather than throwing — the schedule decorates the contract screens
  /// and should never be the reason they fail to render.
  Future<List<ContractMilestoneModel>> fetchMilestones(
    String token,
    String contractId,
  ) async {
    try {
      final milestones = await _service.getContractMilestones(
        token,
        contractId,
      );
      _milestones[contractId] = milestones;
      notifyListeners();
      return milestones;
    } catch (e) {
      debugPrint('Failed to fetch milestones for $contractId: $e');
      return _milestones[contractId] ?? const [];
    }
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

  Future<ContractModel?> fetchContractByProposal(
    String token,
    String proposalId,
  ) async {
    try {
      return await _service.getContractByProposal(token, proposalId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  /// Rethrows [ContractServiceException] so callers can act on the status —
  /// a 409 means the bid is already contracted and should be opened instead.
  Future<ContractModel> createContract(
    String token,
    Map<String, dynamic> data,
  ) async {
    try {
      final contract = await _service.createContract(token, data);
      _currentContract = contract;
      _contracts.add(contract);
      _error = null;
      notifyListeners();
      return contract;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<ContractModel?> sendContract(
    String token,
    String contractId, {
    String? notificationMessage,
    bool saveMessageAsTemplate = false,
  }) async {
    try {
      final updated = await _service.sendContract(
        token,
        contractId,
        notificationMessage: notificationMessage,
        saveMessageAsTemplate: saveMessageAsTemplate,
      );
      if (_currentContract?.contractId == contractId) {
        _currentContract = updated;
      }
      _contracts = _contracts
          .map((c) => c.contractId == contractId ? updated : c)
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

  Future<bool> cancelContract(
    String token,
    String contractId, {
    String? reason,
  }) async {
    try {
      final updated = await _service.cancelContract(
        token,
        contractId,
        reason: reason,
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

  Future<bool> raiseDispute(
    String token,
    String contractId,
    String reason,
  ) async {
    try {
      final updated = await _service.raiseDispute(token, contractId, reason);
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

  int get totalContractsCount => _contracts.length;

  int completedContractsCountForFreelancer(String freelancerId) {
    return _contracts.where((c) {
      return c.freelancerId == freelancerId &&
          c.status.toLowerCase() == 'completed';
    }).length;
  }

  List<ContractModel> completedContractsForFreelancer(String freelancerId) {
    return _contracts.where((c) {
      return c.freelancerId == freelancerId &&
          c.status.toLowerCase() == 'completed';
    }).toList();
  }
}
