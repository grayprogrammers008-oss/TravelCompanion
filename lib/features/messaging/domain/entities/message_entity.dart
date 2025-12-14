import 'package:equatable/equatable.dart';

/// Message type enumeration
enum MessageType {
  text,
  image,
  document,
  location,
  expenseLink,
}

/// Message entity - Domain layer representation
class MessageEntity extends Equatable {
  final String id;
  final String tripId;
  final String senderId;
  final String? message;
  final MessageType messageType;
  final String? replyToId;
  final String? attachmentUrl;
  final List<MessageReaction> reactions;
  final List<String> readBy;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data (not stored in database, fetched via joins)
  final String? senderName;
  final String? senderAvatarUrl;

  const MessageEntity({
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

  /// Check if message is read by a specific user
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  /// Check if user has reacted with a specific emoji
  bool hasReaction(String userId, String emoji) {
    return reactions.any((r) => r.userId == userId && r.emoji == emoji);
  }

  /// Get reaction count for a specific emoji
  int getReactionCount(String emoji) {
    return reactions.where((r) => r.emoji == emoji).length;
  }

  /// Get all unique emojis used in reactions
  Set<String> getUniqueEmojis() {
    return reactions.map((r) => r.emoji).toSet();
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        senderId,
        message,
        messageType,
        replyToId,
        attachmentUrl,
        reactions,
        readBy,
        isDeleted,
        createdAt,
        updatedAt,
        senderName,
        senderAvatarUrl,
      ];

  /// Copy with method for immutable updates
  MessageEntity copyWith({
    String? id,
    String? tripId,
    String? senderId,
    String? message,
    MessageType? messageType,
    String? replyToId,
    String? attachmentUrl,
    List<MessageReaction>? reactions,
    List<String>? readBy,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      replyToId: replyToId ?? this.replyToId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }
}

/// Message reaction entity
class MessageReaction extends Equatable {
  final String emoji;
  final String userId;
  final DateTime createdAt;

  const MessageReaction({
    required this.emoji,
    required this.userId,
    required this.createdAt,
  });

  @override
  List<Object> get props => [emoji, userId, createdAt];

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Message sync status for offline queue
enum MessageSyncStatus {
  pending, // Queued, not sent
  syncing, // Currently uploading
  synced, // Successfully sent
  failed, // Failed after retries
}

/// Transmission method for offline P2P
enum TransmissionMethod {
  internet, // Via Supabase
  bluetooth, // Via Bluetooth LE
  wifiDirect, // Via WiFi Direct
  relay, // Via mesh network relay
}

/// Queued message entity for offline sync
class QueuedMessageEntity extends Equatable {
  final String id;
  final String tripId;
  final String senderId;
  final Map<String, dynamic> messageData;
  final TransmissionMethod transmissionMethod;
  final List<String> relayPath;
  final MessageSyncStatus syncStatus;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  final DateTime createdAt;

  const QueuedMessageEntity({
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

  @override
  List<Object?> get props => [
        id,
        tripId,
        senderId,
        messageData,
        transmissionMethod,
        relayPath,
        syncStatus,
        retryCount,
        lastAttemptAt,
        errorMessage,
        createdAt,
      ];

  /// Copy with method
  QueuedMessageEntity copyWith({
    String? id,
    String? tripId,
    String? senderId,
    Map<String, dynamic>? messageData,
    TransmissionMethod? transmissionMethod,
    List<String>? relayPath,
    MessageSyncStatus? syncStatus,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return QueuedMessageEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      senderId: senderId ?? this.senderId,
      messageData: messageData ?? this.messageData,
      transmissionMethod: transmissionMethod ?? this.transmissionMethod,
      relayPath: relayPath ?? this.relayPath,
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
