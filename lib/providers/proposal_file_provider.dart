import 'package:flutter/material.dart';
import '../../models/proposal_file_model.dart';
import '../../services/proposal_file_service.dart';

class ProposalFileProvider extends ChangeNotifier {
  final _service = ProposalFileService();

  final Map<String, List<ProposalFileModel>> _filesByProposal = {};
  final Map<String, bool> _loading = {};

  List<ProposalFileModel> filesForProposal(String proposalId) =>
      _filesByProposal[proposalId] ?? [];

  bool isLoading(String proposalId) => _loading[proposalId] ?? false;

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

  Future<void> fetchFilesForProposals(
    String token,
    List<String> proposalIds,
  ) async {
    await Future.wait(
      proposalIds.map((id) => fetchFilesForProposal(token, id)),
    );
  }

  void clearProposal(String proposalId) {
    _filesByProposal.remove(proposalId);
    _loading.remove(proposalId);
    notifyListeners();
  }
}
