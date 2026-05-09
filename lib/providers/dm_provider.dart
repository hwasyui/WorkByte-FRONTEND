import 'package:flutter/material.dart';
import '../models/dm_model.dart';
import '../services/dm_service.dart';

class DMProvider extends ChangeNotifier {
  final DMService _service = DMService();

  List<DMThreadModel> _threads = [];
  List<DMThreadModel> _requests = [];
  final Map<String, List<DMMessageModel>> _messagesByThread = {};
  final Map<String, String?> _nextCursorByThread = {};

  bool _isLoadingThreads = false;
  bool _isLoadingRequests = false;
  bool _isSending = false;
  int _pendingRequestCount = 0;

  List<DMThreadModel> get threads => _threads;
  List<DMThreadModel> get requests => _requests;
  bool get isLoadingThreads => _isLoadingThreads;
  bool get isLoadingRequests => _isLoadingRequests;
  bool get isSending => _isSending;
  int get pendingRequestCount => _pendingRequestCount;

  List<DMMessageModel> messagesFor(String threadId) =>
      _messagesByThread[threadId] ?? const [];

  String? nextCursorFor(String threadId) => _nextCursorByThread[threadId];

  Future<void> fetchThreads(String token, {String? status}) async {
    _isLoadingThreads = true;
    notifyListeners();

    try {
      final result = await _service.getThreads(token, status: status);
      _threads = result.threads;
      _pendingRequestCount = result.pendingRequestCount;
    } finally {
      _isLoadingThreads = false;
      notifyListeners();
    }
  }

  Future<void> fetchRequests(String token) async {
    _isLoadingRequests = true;
    notifyListeners();

    try {
      _requests = await _service.getRequests(token);
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  Future<DMThreadStartResult> startThread({
    required String token,
    required String participantId,
    String? jobPostId,
    String? messageText,
  }) async {
    final result = await _service.startThread(
      token: token,
      participantId: participantId,
      jobPostId: jobPostId,
      messageText: messageText,
    );

    final existingIndex = _threads.indexWhere(
      (t) => t.threadId == result.thread.threadId,
    );
    if (existingIndex >= 0) {
      _threads[existingIndex] = result.thread;
    } else {
      _threads.insert(0, result.thread);
    }

    if (result.firstMessage != null) {
      _messagesByThread[result.thread.threadId] = [result.firstMessage!];
    }

    notifyListeners();
    return result;
  }

  Future<DMThreadModel> fetchThread(String token, String threadId) async {
    final thread = await _service.getThread(token, threadId);

    final index = _threads.indexWhere((t) => t.threadId == thread.threadId);
    if (index >= 0) {
      _threads[index] = thread;
    } else {
      _threads.insert(0, thread);
    }

    notifyListeners();
    return thread;
  }

  Future<void> fetchMessages(
    String token,
    String threadId, {
    int limit = 50,
    bool refresh = false,
  }) async {
    final page = await _service.getMessages(token, threadId, limit: limit);

    _messagesByThread[threadId] = page.messages;
    _nextCursorByThread[threadId] = page.nextCursor;
    notifyListeners();
  }

  Future<void> fetchOlderMessages(
    String token,
    String threadId, {
    int limit = 50,
  }) async {
    final before = _nextCursorByThread[threadId];
    if (before == null || before.isEmpty) return;

    final page = await _service.getMessages(
      token,
      threadId,
      limit: limit,
      before: before,
    );

    final current = _messagesByThread[threadId] ?? <DMMessageModel>[];
    _messagesByThread[threadId] = [...page.messages, ...current];
    _nextCursorByThread[threadId] = page.nextCursor;
    notifyListeners();
  }

  Future<DMMessageModel> sendMessage({
    required String token,
    required String threadId,
    required String messageText,
  }) async {
    _isSending = true;
    notifyListeners();

    try {
      final msg = await _service.sendMessage(
        token: token,
        threadId: threadId,
        messageText: messageText,
      );

      final current = _messagesByThread[threadId] ?? <DMMessageModel>[];
      _messagesByThread[threadId] = [...current, msg];

      final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
      if (threadIndex >= 0) {
        final old = _threads[threadIndex];
        _threads[threadIndex] = DMThreadModel(
          threadId: old.threadId,
          status: old.status,
          initiatorId: old.initiatorId,
          otherUser: old.otherUser,
          jobPost: old.jobPost,
          unreadCount: old.unreadCount,
          createdAt: old.createdAt,
          updatedAt: msg.sentAt ?? DateTime.now(),
          lastMessage: DMLastMessagePreview(
            messageText: msg.messageText,
            sentAt: msg.sentAt,
            senderId: msg.senderId,
          ),
        );
      }

      notifyListeners();
      return msg;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> markThreadAsRead({
    required String token,
    required String threadId,
  }) async {
    await _service.markThreadAsRead(token: token, threadId: threadId);

    final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
    if (threadIndex >= 0) {
      final old = _threads[threadIndex];
      _threads[threadIndex] = DMThreadModel(
        threadId: old.threadId,
        status: old.status,
        initiatorId: old.initiatorId,
        otherUser: old.otherUser,
        jobPost: old.jobPost,
        lastMessage: old.lastMessage,
        unreadCount: 0,
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
      );
    }

    final reqIndex = _requests.indexWhere((t) => t.threadId == threadId);
    if (reqIndex >= 0) {
      final old = _requests[reqIndex];
      _requests[reqIndex] = DMThreadModel(
        threadId: old.threadId,
        status: old.status,
        initiatorId: old.initiatorId,
        otherUser: old.otherUser,
        jobPost: old.jobPost,
        lastMessage: old.lastMessage,
        unreadCount: 0,
        createdAt: old.createdAt,
        updatedAt: old.updatedAt,
      );
    }

    notifyListeners();
  }

  Future<DMThreadModel> acceptThread({
    required String token,
    required String threadId,
  }) async {
    final updated = await _service.acceptThread(token, threadId);

    final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
    if (threadIndex >= 0) {
      _threads[threadIndex] = updated;
    }

    _requests.removeWhere((t) => t.threadId == threadId);
    _pendingRequestCount = (_pendingRequestCount - 1).clamp(0, 1 << 30);
    notifyListeners();
    return updated;
  }

  Future<DMThreadModel> declineThread({
    required String token,
    required String threadId,
  }) async {
    final updated = await _service.declineThread(token, threadId);

    final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
    if (threadIndex >= 0) {
      _threads[threadIndex] = updated;
    }

    _requests.removeWhere((t) => t.threadId == threadId);
    _pendingRequestCount = (_pendingRequestCount - 1).clamp(0, 1 << 30);
    notifyListeners();
    return updated;
  }

  void insertIncomingMessage(String threadId, DMMessageModel message) {
    final current = _messagesByThread[threadId] ?? <DMMessageModel>[];
    if (current.any((m) => m.dmMessageId == message.dmMessageId)) return;

    _messagesByThread[threadId] = [...current, message];
    notifyListeners();
  }

  void clearThreadMessages(String threadId) {
    _messagesByThread.remove(threadId);
    _nextCursorByThread.remove(threadId);
    notifyListeners();
  }

  void reset() {
    _threads = [];
    _requests = [];
    _messagesByThread.clear();
    _nextCursorByThread.clear();
    _pendingRequestCount = 0;
    _isLoadingThreads = false;
    _isLoadingRequests = false;
    _isSending = false;
    notifyListeners();
  }
}
