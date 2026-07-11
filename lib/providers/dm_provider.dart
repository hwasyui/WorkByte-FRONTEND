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
    required String senderId,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final tempMessage = DMMessageModel.localSending(
      tempId: tempId,
      threadId: threadId,
      senderId: senderId,
      messageText: messageText,
    );

    final current = _messagesByThread[threadId] ?? <DMMessageModel>[];
    _messagesByThread[threadId] = [...current, tempMessage];
    notifyListeners();

    try {
      final realMessage = await _service.sendMessage(
        token: token,
        threadId: threadId,
        messageText: messageText,
      );

      _replaceMessage(threadId, tempId, realMessage);
      _updateThreadPreview(threadId, realMessage);
      notifyListeners();

      return realMessage;
    } catch (e) {
      final labels = e is DMFailureException ? e.detectedLabels : const <String>[];
      final failedMessage = tempMessage.copyWith(
        status: 'failed',
        metadata: {
          'failure_reason': e.toString().replaceFirst('Exception: ', ''),
          if (labels.isNotEmpty) 'detected_labels': labels,
        },
      );

      _replaceMessage(threadId, tempId, failedMessage);
      notifyListeners();

      return failedMessage;
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

  Future<DMMessageModel> sendFileMessage({
    required String token,
    required String threadId,
    required String filePath,
    required String fileName,
    required String senderId,
    String? messageText,
    int? fileSizeBytes,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final tempAttachment = DMAttachmentModel.localFile(
      tempId: tempId,
      fileName: fileName,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
    );

    final tempMessage = DMMessageModel.localSending(
      tempId: tempId,
      threadId: threadId,
      senderId: senderId,
      messageText: messageText?.trim() ?? '',
      attachments: [tempAttachment],
    );

    final current = _messagesByThread[threadId] ?? <DMMessageModel>[];
    _messagesByThread[threadId] = [...current, tempMessage];
    notifyListeners();

    try {
      final realMessage = await _service.sendFileMessage(
        token: token,
        threadId: threadId,
        filePath: filePath,
        fileName: fileName,
        messageText: messageText,
      );

      _replaceMessage(threadId, tempId, realMessage);
      _updateThreadPreview(threadId, realMessage);
      notifyListeners();

      return realMessage;
    } catch (e) {
      final labels = e is DMFailureException ? e.detectedLabels : const <String>[];
      final failedMessage = tempMessage.copyWith(
        status: 'failed',
        metadata: {
          'failure_reason': e.toString().replaceFirst('Exception: ', ''),
          if (labels.isNotEmpty) 'detected_labels': labels,
        },
      );

      _replaceMessage(threadId, tempId, failedMessage);
      notifyListeners();

      return failedMessage;
    }
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

  void _replaceMessage(
    String threadId,
    String oldMessageId,
    DMMessageModel newMessage,
  ) {
    final current = _messagesByThread[threadId] ?? <DMMessageModel>[];

    _messagesByThread[threadId] = current.map((message) {
      if (message.dmMessageId == oldMessageId) {
        return newMessage;
      }
      return message;
    }).toList();
  }

  void _updateThreadPreview(String threadId, DMMessageModel msg) {
    final threadIndex = _threads.indexWhere((t) => t.threadId == threadId);
    if (threadIndex < 0) return;

    final old = _threads[threadIndex];

    final previewText = msg.messageText.trim().isNotEmpty
        ? msg.messageText.trim()
        : msg.attachments.isNotEmpty
        ? '📎 ${msg.attachments.first.fileName}'
        : '';

    _threads[threadIndex] = DMThreadModel(
      threadId: old.threadId,
      status: old.status,
      initiatorId: old.initiatorId,
      contractId: old.contractId,
      otherUser: old.otherUser,
      jobPost: old.jobPost,
      unreadCount: old.unreadCount,
      createdAt: old.createdAt,
      updatedAt: msg.sentAt ?? DateTime.now(),
      lastMessage: DMLastMessagePreview(
        messageText: previewText,
        sentAt: msg.sentAt,
        senderId: msg.senderId,
      ),
    );
  }
}
