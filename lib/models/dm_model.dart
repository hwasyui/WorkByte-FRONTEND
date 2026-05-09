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
  final String filename;
  final String fileUrl;
  final String fileType;
  final String mimeType;
  final int? fileSizeBytes;
  final double? durationSeconds;
  final DateTime? createdAt;

  const DMAttachmentModel({
    required this.attachmentId,
    required this.dmMessageId,
    required this.filename,
    required this.fileUrl,
    required this.fileType,
    required this.mimeType,
    this.fileSizeBytes,
    this.durationSeconds,
    this.createdAt,
  });

  factory DMAttachmentModel.fromJson(Map<String, dynamic> json) {
    return DMAttachmentModel(
      attachmentId:
          json['attachmentid'] as String? ??
          json['attachment_id'] as String? ??
          '',
      dmMessageId:
          json['dmmessageid'] as String? ??
          json['dm_message_id'] as String? ??
          '',
      filename: json['filename'] as String? ?? '',
      fileUrl: json['fileurl'] as String? ?? json['file_url'] as String? ?? '',
      fileType:
          json['filetype'] as String? ?? json['file_type'] as String? ?? '',
      mimeType:
          json['mimetype'] as String? ?? json['mime_type'] as String? ?? '',
      fileSizeBytes:
          json['filesizebytes'] as int? ?? json['file_size_bytes'] as int?,
      durationSeconds:
          (json['durationseconds'] ?? json['duration_seconds']) is num
          ? ((json['durationseconds'] ?? json['duration_seconds']) as num)
                .toDouble()
          : null,
      createdAt: _parseDate(json['createdat'] ?? json['created_at']),
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
      dmMessageId:
          json['dmmessageid'] as String? ??
          json['dm_message_id'] as String? ??
          '',
      threadId:
          json['threadid'] as String? ?? json['thread_id'] as String? ?? '',
      senderId:
          json['senderid'] as String? ?? json['sender_id'] as String? ?? '',
      messageText:
          json['messagetext'] as String? ??
          json['message_text'] as String? ??
          '',
      metadata: _parseMap(json['metadata']),
      isRead: json['isread'] as bool? ?? json['is_read'] as bool? ?? false,
      readAt: _parseDate(json['readat'] ?? json['read_at']),
      sentAt: _parseDate(json['sentat'] ?? json['sent_at']),
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
      userId: json['userid'] as String? ?? json['user_id'] as String? ?? '',
      fullName: json['fullname'] as String? ?? json['full_name'] as String?,
      profilePictureUrl:
          json['profilepictureurl'] as String? ??
          json['profile_picture_url'] as String?,
      role: json['role'] as String?,
      freelancerId:
          json['freelancerid'] as String? ?? json['freelancer_id'] as String?,
      clientId: json['clientid'] as String? ?? json['client_id'] as String?,
    );
  }
}

class DMJobPostPreview {
  final String jobPostId;
  final String? jobTitle;

  const DMJobPostPreview({required this.jobPostId, this.jobTitle});

  factory DMJobPostPreview.fromJson(Map<String, dynamic> json) {
    return DMJobPostPreview(
      jobPostId:
          json['jobpostid'] as String? ?? json['job_post_id'] as String? ?? '',
      jobTitle: json['jobtitle'] as String? ?? json['job_title'] as String?,
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
      messageText:
          json['messagetext'] as String? ?? json['message_text'] as String?,
      sentAt: _parseDate(json['sentat'] ?? json['sent_at']),
      senderId: json['senderid'] as String? ?? json['sender_id'] as String?,
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
      threadId:
          json['threadid'] as String? ?? json['thread_id'] as String? ?? '',
      status: json['status'] as String? ?? 'request',
      initiatorId:
          json['initiatorid'] as String? ??
          json['initiator_id'] as String? ??
          '',
      contractId:
          json['contractid'] as String? ?? json['contract_id'] as String?,
      otherUser: json['otheruser'] != null
          ? DMUserPreview.fromJson(
              Map<String, dynamic>.from(json['otheruser'] as Map),
            )
          : json['other_user'] != null
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
      lastMessage: json['lastmessage'] != null
          ? DMLastMessagePreview.fromJson(
              Map<String, dynamic>.from(json['lastmessage'] as Map),
            )
          : json['last_message'] != null
          ? DMLastMessagePreview.fromJson(
              Map<String, dynamic>.from(json['last_message'] as Map),
            )
          : null,
      unreadCount:
          json['unreadcount'] as int? ?? json['unread_count'] as int? ?? 0,
      createdAt: _parseDate(json['createdat'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedat'] ?? json['updated_at']),
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
      firstMessage: json['firstmessage'] != null
          ? DMMessageModel.fromJson(
              Map<String, dynamic>.from(json['firstmessage'] as Map),
            )
          : json['first_message'] != null
          ? DMMessageModel.fromJson(
              Map<String, dynamic>.from(json['first_message'] as Map),
            )
          : null,
      alreadyExists:
          json['alreadyexists'] as bool? ??
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
      hasMore: json['hasmore'] as bool? ?? json['has_more'] as bool? ?? false,
      nextCursor:
          json['nextcursor'] as String? ?? json['next_cursor'] as String?,
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
      pendingRequestCount:
          json['pendingrequestscount'] as int? ??
          json['pending_requests_count'] as int? ??
          0,
    );
  }
}
