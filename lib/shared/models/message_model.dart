import '../../features/messaging/domain/entities/message_entity.dart';

/// Message Model - Data layer representation
/// Handles JSON serialization for Supabase and local storage
class MessageModel {
  final String id;
  final String tripId;
  final String senderId;
  final String? message;
  final String messageType;
  final String? replyToId;
  final String? attachmentUrl;
  final List<Map<String, dynamic>> reactions;
  final List<String> readBy;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields (from profiles table)
  final String? senderName;
  final String? senderAvatarUrl;

  const MessageModel({
    required this.id,
    required this.tripId,
    required this.senderId,
    this.message,
    required this.messageType,
    this.replyToId,
    this.attachmentUrl,
    this.reactions = const [],
    this.readBy = const [],
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  /// Convert to JSON for database storage (excludes joined fields)
  Map<String, dynamic> toDatabaseJson() {
    final json = <String, dynamic>{
      'id': id,
      'trip_id': tripId,
      'sender_id': senderId,
      'message': message,
      'message_type': messageType,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    // Only include optional fields when non-null to avoid schema cache errors
    if (replyToId != null) json['reply_to_id'] = replyToId;
    if (attachmentUrl != null) json['attachment_url'] = attachmentUrl;
    if (reactions.isNotEmpty) json['reactions'] = reactions;
    if (readBy.isNotEmpty) json['read_by'] = readBy;
    return json;
  }

  /// Convert to JSON (includes all fields for serialization)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'sender_id': senderId,
      'message': message,
      'message_type': messageType,
      'reply_to_id': replyToId,
      'attachment_url': attachmentUrl,
      'reactions': reactions,
      'read_by': readBy,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
    };
  }

  /// Create from JSON (from Supabase response)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String?,
      messageType: json['message_type'] as String,
      replyToId: json['reply_to_id'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      reactions: json['reactions'] is List
              ? (json['reactions'] as List<dynamic>)
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList()
              : [],
      readBy: (json['read_by'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      senderName: json['sender_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
    );
  }

  /// Convert to domain entity
  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      tripId: tripId,
      senderId: senderId,
      message: message,
      messageType: _parseMessageType(messageType),
      replyToId: replyToId,
      attachmentUrl: attachmentUrl,
      reactions: reactions
          .map((r) => MessageReaction.fromJson(r))
          .toList(),
      readBy: readBy,
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
    );
  }

  /// Create from domain entity
  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      tripId: entity.tripId,
      senderId: entity.senderId,
      message: entity.message,
      messageType: _messageTypeToString(entity.messageType),
      replyToId: entity.replyToId,
      attachmentUrl: entity.attachmentUrl,
      reactions: entity.reactions.map((r) => r.toJson()).toList(),
      readBy: entity.readBy,
      isDeleted: entity.isDeleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      senderName: entity.senderName,
      senderAvatarUrl: entity.senderAvatarUrl,
    );
  }

  /// Parse message type from string
  static MessageType _parseMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'document':
        return MessageType.document;
      case 'location':
        return MessageType.location;
      case 'expense_link':
        return MessageType.expenseLink;
      default:
        return MessageType.text;
    }
  }

  /// Convert message type to string
  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.document:
        return 'document';
      case MessageType.location:
        return 'location';
      case MessageType.expenseLink:
        return 'expense_link';
    }
  }
}

/// Queued Message Model - For offline sync
class QueuedMessageModel {
  final String id;
  final String tripId;
  final String senderId;
  final Map<String, dynamic> messageData;
  final String transmissionMethod;
  final List<String> relayPath;
  final String syncStatus;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  final DateTime createdAt;

  const QueuedMessageModel({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.messageData,
    required this.transmissionMethod,
    this.relayPath = const [],
    required this.syncStatus,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.errorMessage,
    required this.createdAt,
  });

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'sender_id': senderId,
      'message_data': messageData,
      'transmission_method': transmissionMethod,
      'relay_path': relayPath,
      'sync_status': syncStatus,
      'retry_count': retryCount,
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory QueuedMessageModel.fromJson(Map<String, dynamic> json) {
    return QueuedMessageModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      senderId: json['sender_id'] as String,
      messageData: Map<String, dynamic>.from(json['message_data'] as Map),
      transmissionMethod: json['transmission_method'] as String,
      relayPath: (json['relay_path'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      syncStatus: json['sync_status'] as String,
      retryCount: json['retry_count'] as int? ?? 0,
      lastAttemptAt: json['last_attempt_at'] != null
          ? DateTime.parse(json['last_attempt_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to domain entity
  QueuedMessageEntity toEntity() {
    return QueuedMessageEntity(
      id: id,
      tripId: tripId,
      senderId: senderId,
      messageData: messageData,
      transmissionMethod: _parseTransmissionMethod(transmissionMethod),
      relayPath: relayPath,
      syncStatus: _parseSyncStatus(syncStatus),
      retryCount: retryCount,
      lastAttemptAt: lastAttemptAt,
      errorMessage: errorMessage,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory QueuedMessageModel.fromEntity(QueuedMessageEntity entity) {
    return QueuedMessageModel(
      id: entity.id,
      tripId: entity.tripId,
      senderId: entity.senderId,
      messageData: entity.messageData,
      transmissionMethod: _transmissionMethodToString(entity.transmissionMethod),
      relayPath: entity.relayPath,
      syncStatus: _syncStatusToString(entity.syncStatus),
      retryCount: entity.retryCount,
      lastAttemptAt: entity.lastAttemptAt,
      errorMessage: entity.errorMessage,
      createdAt: entity.createdAt,
    );
  }

  /// Parse transmission method from string
  static TransmissionMethod _parseTransmissionMethod(String method) {
    switch (method) {
      case 'internet':
        return TransmissionMethod.internet;
      case 'bluetooth':
        return TransmissionMethod.bluetooth;
      case 'wifi_direct':
        return TransmissionMethod.wifiDirect;
      case 'relay':
        return TransmissionMethod.relay;
      default:
        return TransmissionMethod.internet;
    }
  }

  /// Convert transmission method to string
  static String _transmissionMethodToString(TransmissionMethod method) {
    switch (method) {
      case TransmissionMethod.internet:
        return 'internet';
      case TransmissionMethod.bluetooth:
        return 'bluetooth';
      case TransmissionMethod.wifiDirect:
        return 'wifi_direct';
      case TransmissionMethod.relay:
        return 'relay';
    }
  }

  /// Parse sync status from string
  static MessageSyncStatus _parseSyncStatus(String status) {
    switch (status) {
      case 'pending':
        return MessageSyncStatus.pending;
      case 'syncing':
        return MessageSyncStatus.syncing;
      case 'synced':
        return MessageSyncStatus.synced;
      case 'failed':
        return MessageSyncStatus.failed;
      default:
        return MessageSyncStatus.pending;
    }
  }

  /// Convert sync status to string
  static String _syncStatusToString(MessageSyncStatus status) {
    switch (status) {
      case MessageSyncStatus.pending:
        return 'pending';
      case MessageSyncStatus.syncing:
        return 'syncing';
      case MessageSyncStatus.synced:
        return 'synced';
      case MessageSyncStatus.failed:
        return 'failed';
    }
  }
}
