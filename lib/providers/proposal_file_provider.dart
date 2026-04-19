import 'package:flutter/material.dart';
import '../../models/proposal_file_model.dart';
import '../../services/proposal_file_service.dart';

class ProposalFileProvider extends ChangeNotifier {
  final _service = ProposalFileService();

  // proposalId → list of files
  final Map<String, List<ProposalFileModel>> _filesByProposal = {};
  final Map<String, bool> _loading = {};

  List<ProposalFileModel> filesForProposal(String proposalId) =>
      _filesByProposal[proposalId] ?? [];

  bool isLoading(String proposalId) => _loading[proposalId] ?? false;

  /// Fetch files for a single proposal — caches result
  Future<void> fetchFilesForProposal(String token, String proposalId) async {
    if (_loading[proposalId] == true) return;

    _loading[proposalId] = true;
    notifyListeners();

    try {
      final files = await _service.getFilesByProposalId(token, proposalId);
      _filesByProposal[proposalId] = files;
    } catch (e) {
      debugPrint('ProposalFileProvider: error fetching files: $e');
      _filesByProposal[proposalId] = [];
    } finally {
      _loading[proposalId] = false;
      notifyListeners();
    }
  }

  /// Fetch files for multiple proposals in parallel (used by job detail)
  Future<void> fetchFilesForProposals(
    String token,
    List<String> proposalIds,
  ) async {
    await Future.wait(
      proposalIds.map((id) => fetchFilesForProposal(token, id)),
    );
  }

  /// Clear cache for a proposal (call after delete/re-upload)
  void clearProposal(String proposalId) {
    _filesByProposal.remove(proposalId);
    _loading.remove(proposalId);
    notifyListeners();
  }
}
