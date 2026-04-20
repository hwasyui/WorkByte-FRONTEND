import 'package:flutter/material.dart';

import '../models/contract_message_model.dart';
import '../services/contract_message_service.dart';

class ContractMessageProvider extends ChangeNotifier {
  final ContractMessageService _service = ContractMessageService();

  List<ContractMessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ContractMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMessages({
    required String token,
    required String contractId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _service.getMessagesByContract(token, contractId);
      _messages.sort(
        (a, b) =>
            (a.sentAt ?? DateTime(1970)).compareTo(b.sentAt ?? DateTime(1970)),
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ContractMessageModel?> sendMessage({
    required String token,
    required String contractId,
    required String messageText,
  }) async {
    try {
      final sent = await _service.sendMessage(
        token: token,
        contractId: contractId,
        messageText: messageText,
      );

      _messages = [..._messages, sent];
      _messages.sort(
        (a, b) =>
            (a.sentAt ?? DateTime(1970)).compareTo(b.sentAt ?? DateTime(1970)),
      );

      notifyListeners();
      return sent;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> markMessagesAsRead({
    required String token,
    required String contractId,
  }) async {
    try {
      await _service.markMessagesAsRead(token: token, contractId: contractId);
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
    _messages = [];
    _error = null;
    notifyListeners();
  }
}
