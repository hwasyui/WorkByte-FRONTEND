import 'package:flutter/material.dart';
import '../models/proposal_model.dart';
import '../services/proposal_service.dart';

class ProposalProvider extends ChangeNotifier {
  final ProposalService _service = ProposalService();

  List<ProposalModel> _proposals = [];
  bool _isLoading = false;
  String? _error;

  List<ProposalModel> get proposals => _proposals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Fetch proposals for a job post (raw, no enrichment) ──────────────────
  Future<void> fetchProposalsByJob({
    required String token,
    required String jobPostId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _proposals = await _service.getProposalsByJobPost(token, jobPostId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Fetch proposals submitted by a freelancer ─────────────────────────────
  Future<void> fetchProposalsByFreelancer({
    required String token,
    required String freelancerId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _proposals = await _service.getProposalsByFreelancer(token, freelancerId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Accept a bid ──────────────────────────────────────────────────────────
  Future<bool> acceptProposal({
    required String token,
    required String proposalId,
  }) async {
    try {
      final updated = await _service.updateProposalStatus(
        token,
        proposalId,
        'accepted',
      );
      _proposals = _proposals
          .map(
            (p) => p.proposalId == proposalId
                ? p.copyWith(status: updated.status)
                : p,
          )
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Reject a bid ──────────────────────────────────────────────────────────
  Future<bool> rejectProposal({
    required String token,
    required String proposalId,
  }) async {
    try {
      final updated = await _service.updateProposalStatus(
        token,
        proposalId,
        'rejected',
      );
      _proposals = _proposals
          .map(
            (p) => p.proposalId == proposalId
                ? p.copyWith(status: updated.status)
                : p,
          )
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Submit a new proposal (freelancer side) ───────────────────────────────
  Future<ProposalModel?> createProposal({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final created = await _service.createProposal(token, data);
      _proposals = [created, ..._proposals];
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Delete a proposal ─────────────────────────────────────────────────────
  Future<bool> deleteProposal({
    required String token,
    required String proposalId,
  }) async {
    try {
      await _service.deleteProposal(token, proposalId);
      _proposals = _proposals.where((p) => p.proposalId != proposalId).toList();
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

  void clear() {
    _proposals = [];
    _error = null;
    notifyListeners();
  }
}
