import 'dart:convert';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  if (str.isEmpty) return null;
  try {
    return DateTime.parse(str);
  } catch (_) {
    return null;
  }
}

Map<String, dynamic>? _parseMap(dynamic value) {
  if (value == null) return null;

  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);

  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  return null;
}

class DMAttachmentModel {
  final String attachmentId;
  final String dmMessageId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final String mimeType;
  final int? fileSizeBytes;
  final double? durationSeconds;
  final DateTime? createdAt;

  const DMAttachmentModel({
    required this.attachmentId,
    required this.dmMessageId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.mimeType,
    this.fileSizeBytes,
    this.durationSeconds,
    this.createdAt,
  });

  factory DMAttachmentModel.localFile({
    required String tempId,
    required String fileName,
    required String filePath,
    String fileType = 'document',
    String mimeType = 'application/octet-stream',
    int? fileSizeBytes,
  }) {
    return DMAttachmentModel(
      attachmentId: 'local_$tempId',
      dmMessageId: tempId,
      fileName: fileName,
      fileUrl: filePath,
      fileType: fileType,
      mimeType: mimeType,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: null,
      createdAt: DateTime.now(),
    );
  }

  factory DMAttachmentModel.fromJson(Map<String, dynamic> json) {
    return DMAttachmentModel(
      attachmentId: json['attachment_id'] as String? ?? '',
      dmMessageId: json['dm_message_id'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      fileType: json['file_type'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      fileSizeBytes: json['file_size_bytes'] as int?,
      durationSeconds: (json['duration_seconds']) is num
          ? ((json['duration_seconds']) as num).toDouble()
          : null,
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class DMMessageModel {
  final String dmMessageId;
  final String threadId;
  final String senderId;
  final String messageText;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? sentAt;
  final String status;
  final List<DMAttachmentModel> attachments;

  const DMMessageModel({
    required this.dmMessageId,
    required this.threadId,
    required this.senderId,
    required this.messageText,
    this.metadata,
    required this.isRead,
    this.readAt,
    this.sentAt,
    required this.status,
    required this.attachments,
  });

  factory DMMessageModel.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    return DMMessageModel(
      dmMessageId: json['dm_message_id'] as String? ?? '',
      threadId: json['thread_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      messageText: json['message_text'] as String? ?? '',
      metadata: _parseMap(json['metadata']),
      isRead: json['is_read'] as bool? ?? false,
      readAt: _parseDate(json['read_at']),
      sentAt: _parseDate(json['sent_at']),
      status: json['status'] as String? ?? 'sent',
      attachments: rawAttachments is List
          ? rawAttachments
                .map(
                  (e) => DMAttachmentModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
          : const [],
    );
  }

  bool get hasAttachments => attachments.isNotEmpty;
  bool get isSystemEvent {
    final type = metadata?['type']?.toString().toLowerCase();
    const systemTypes = {
      'system',
      'thread_started',
      'request_sent',
      'request_accepted',
      'request_declined',
      'job_context',
      'status_change',
    };
    return type != null && systemTypes.contains(type);
  }

  bool get isSending => status == 'sending';
  bool get isFailed => status == 'failed' || status == 'blocked';

  String? get failureReason {
    final value = metadata?['failure_reason'] ?? metadata?['reason'];
    return value?.toString();
  }

  DMMessageModel copyWith({
    String? dmMessageId,
    String? threadId,
    String? senderId,
    String? messageText,
    Map<String, dynamic>? metadata,
    bool? isRead,
    DateTime? readAt,
    DateTime? sentAt,
    String? status,
    List<DMAttachmentModel>? attachments,
  }) {
    return DMMessageModel(
      dmMessageId: dmMessageId ?? this.dmMessageId,
      threadId: threadId ?? this.threadId,
      senderId: senderId ?? this.senderId,
      messageText: messageText ?? this.messageText,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
    );
  }

  factory DMMessageModel.localSending({
    required String tempId,
    required String threadId,
    required String senderId,
    required String messageText,
    List<DMAttachmentModel> attachments = const [],
  }) {
    return DMMessageModel(
      dmMessageId: tempId,
      threadId: threadId,
      senderId: senderId,
      messageText: messageText,
      metadata: {'is_local': true},
      isRead: false,
      readAt: null,
      sentAt: DateTime.now(),
      status: 'sending',
      attachments: attachments,
    );
  }
}

class DMUserPreview {
  final String userId;
  final String? fullName;
  final String? profilePictureUrl;
  final String? role;
  final String? freelancerId;
  final String? clientId;

  const DMUserPreview({
    required this.userId,
    this.fullName,
    this.profilePictureUrl,
    this.role,
    this.freelancerId,
    this.clientId,
  });

  factory DMUserPreview.fromJson(Map<String, dynamic> json) {
    return DMUserPreview(
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      role: json['role'] as String?,
      freelancerId: json['freelancer_id'] as String?,
      clientId: json['client_id'] as String?,
    );
  }
}

class DMJobPostPreview {
  final String jobPostId;
  final String? jobTitle;

  const DMJobPostPreview({required this.jobPostId, this.jobTitle});

  factory DMJobPostPreview.fromJson(Map<String, dynamic> json) {
    return DMJobPostPreview(
      jobPostId: json['job_post_id'] as String? ?? '',
      jobTitle: json['job_title'] as String?,
    );
  }
}

class DMLastMessagePreview {
  final String? messageText;
  final DateTime? sentAt;
  final String? senderId;

  const DMLastMessagePreview({this.messageText, this.sentAt, this.senderId});

  factory DMLastMessagePreview.fromJson(Map<String, dynamic> json) {
    return DMLastMessagePreview(
      messageText: json['message_text'] as String?,
      sentAt: _parseDate(json['sent_at']),
      senderId: json['sender_id'] as String?,
    );
  }
}

class DMThreadModel {
  final String threadId;
  final String status;
  final String initiatorId;
  final String? contractId;
  final DMUserPreview? otherUser;
  final DMJobPostPreview? jobPost;
  final DMLastMessagePreview? lastMessage;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DMThreadModel({
    required this.threadId,
    required this.status,
    required this.initiatorId,
    this.contractId,
    this.otherUser,
    this.jobPost,
    this.lastMessage,
    required this.unreadCount,
    this.createdAt,
    this.updatedAt,
  });

  factory DMThreadModel.fromJson(Map<String, dynamic> json) {
    return DMThreadModel(
      threadId: json['thread_id'] as String? ?? '',
      status: json['status'] as String? ?? 'request',
      initiatorId: json['initiator_id'] as String? ?? '',
      contractId: json['contract_id'] as String?,
      otherUser: json['other_user'] != null
          ? DMUserPreview.fromJson(
              Map<String, dynamic>.from(json['other_user'] as Map),
            )
          : null,
      jobPost: json['jobpost'] != null
          ? DMJobPostPreview.fromJson(
              Map<String, dynamic>.from(json['jobpost'] as Map),
            )
          : json['job_post'] != null
          ? DMJobPostPreview.fromJson(
              Map<String, dynamic>.from(json['job_post'] as Map),
            )
          : null,
      lastMessage: json['last_message'] != null
          ? DMLastMessagePreview.fromJson(
              Map<String, dynamic>.from(json['last_message'] as Map),
            )
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class DMThreadStartResult {
  final DMThreadModel thread;
  final DMMessageModel? firstMessage;
  final bool alreadyExists;

  const DMThreadStartResult({
    required this.thread,
    this.firstMessage,
    required this.alreadyExists,
  });

  factory DMThreadStartResult.fromJson(Map<String, dynamic> json) {
    return DMThreadStartResult(
      thread: DMThreadModel.fromJson(
        Map<String, dynamic>.from(json['thread'] as Map),
      ),
      firstMessage: json['first_message'] != null
          ? DMMessageModel.fromJson(
              Map<String, dynamic>.from(json['first_message'] as Map),
            )
          : null,
      alreadyExists:
          json['already_exists'] as bool? ??
          json['already_exists'] as bool? ??
          false,
    );
  }
}

class DMMessagePage {
  final List<DMMessageModel> messages;
  final bool hasMore;
  final String? nextCursor;

  const DMMessagePage({
    required this.messages,
    required this.hasMore,
    this.nextCursor,
  });

  factory DMMessagePage.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'] as List? ?? const [];
    return DMMessagePage(
      messages: raw
          .map(
            (e) => DMMessageModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      hasMore: json['has_more'] as bool? ?? false,
      nextCursor: json['next_cursor'] as String?,
    );
  }
}

class DMThreadListResult {
  final List<DMThreadModel> threads;
  final int pendingRequestCount;

  const DMThreadListResult({
    required this.threads,
    required this.pendingRequestCount,
  });

  factory DMThreadListResult.fromJson(Map<String, dynamic> json) {
    final raw = json['threads'] as List? ?? const [];
    return DMThreadListResult(
      threads: raw
          .map(
            (e) => DMThreadModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      pendingRequestCount: json['pending_requests_count'] as int? ?? 0,
    );
  }
}
