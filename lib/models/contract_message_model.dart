import 'dart:convert';

class ContractMessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String? contractId;
  final String messageText;
  final String messageType;
  final String? eventType;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? sentAt;

  const ContractMessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    this.contractId,
    required this.messageText,
    required this.messageType,
    this.eventType,
    this.metadata,
    required this.isRead,
    this.readAt,
    this.sentAt,
  });

  factory ContractMessageModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.isEmpty) return null;
      try {
        return DateTime.parse(str);
      } catch (_) {
        return null;
      }
    }

    return ContractMessageModel(
      messageId: json['message_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      receiverId: json['receiver_id'] as String? ?? '',
      contractId: json['contract_id'] as String?,
      messageText: json['message_text'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'user',
      eventType: json['event_type'] as String?,
      metadata: _parseMetadata(json['metadata']),
      isRead: json['is_read'] as bool? ?? false,
      readAt: parseDate(json['read_at']),
      sentAt: parseDate(json['sent_at']),
    );
  }

  static Map<String, dynamic>? _parseMetadata(dynamic value) {
    if (value == null) return null;

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  ContractMessageModel copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? contractId,
    String? messageText,
    String? messageType,
    String? eventType,
    Map<String, dynamic>? metadata,
    bool? isRead,
    DateTime? readAt,
    DateTime? sentAt,
  }) {
    return ContractMessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      contractId: contractId ?? this.contractId,
      messageText: messageText ?? this.messageText,
      messageType: messageType ?? this.messageType,
      eventType: eventType ?? this.eventType,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  bool get isSystemMessage => messageType == 'system';

  Map<String, dynamic> toJson() => {
    'message_id': messageId,
    'sender_id': senderId,
    'receiver_id': receiverId,
    if (contractId != null) 'contract_id': contractId,
    'message_text': messageText,
    'message_type': messageType,
    if (eventType != null) 'event_type': eventType,
    if (metadata != null) 'metadata': metadata,
    'is_read': isRead,
    if (readAt != null) 'read_at': readAt?.toIso8601String(),
    if (sentAt != null) 'sent_at': sentAt?.toIso8601String(),
  };
}
