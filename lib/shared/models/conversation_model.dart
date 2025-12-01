/// Conversation model - Represents a group chat conversation
class ConversationModel {
  final String id;
  final String tripId;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String createdBy;
  final bool isDirectMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed fields from database functions
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderName;
  final int unreadCount;
  final int memberCount;

  // Members (loaded separately or via join)
  final List<ConversationMemberModel> members;

  const ConversationModel({
    required this.id,
    required this.tripId,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.createdBy,
    this.isDirectMessage = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageSenderName,
    this.unreadCount = 0,
    this.memberCount = 0,
    this.members = const [],
  });

  ConversationModel copyWith({
    String? id,
    String? tripId,
    String? name,
    String? description,
    String? avatarUrl,
    String? createdBy,
    bool? isDirectMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessageText,
    DateTime? lastMessageAt,
    String? lastMessageSenderName,
    int? unreadCount,
    int? memberCount,
    List<ConversationMemberModel>? members,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdBy: createdBy ?? this.createdBy,
      isDirectMessage: isDirectMessage ?? this.isDirectMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderName: lastMessageSenderName ?? this.lastMessageSenderName,
      unreadCount: unreadCount ?? this.unreadCount,
      memberCount: memberCount ?? this.memberCount,
      members: members ?? this.members,
    );
  }

  /// Convert to JSON for database insert (excludes computed fields)
  Map<String, dynamic> toInsertJson() {
    return {
      'trip_id': tripId,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'created_by': createdBy,
      'is_direct_message': isDirectMessage,
    };
  }

  /// Convert to full JSON (includes all fields)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'created_by': createdBy,
      'is_direct_message': isDirectMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_text': lastMessageText,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_sender_name': lastMessageSenderName,
      'unread_count': unreadCount,
      'member_count': memberCount,
    };
  }

  /// Create from JSON (database response)
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      tripId: json['trip_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdBy: json['created_by'] as String,
      isDirectMessage: json['is_direct_message'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageText: json['last_message_text'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageSenderName: json['last_message_sender_name'] as String?,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => ConversationMemberModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, name: $name, tripId: $tripId, memberCount: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Conversation member model - Represents a member in a conversation
class ConversationMemberModel {
  final String id;
  final String conversationId;
  final String userId;
  final String role; // 'admin' or 'member'
  final DateTime joinedAt;
  final bool isMuted;
  final DateTime? lastReadAt;

  // Joined profile data
  final String? userName;
  final String? userAvatarUrl;
  final String? userEmail;

  const ConversationMemberModel({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.isMuted = false,
    this.lastReadAt,
    this.userName,
    this.userAvatarUrl,
    this.userEmail,
  });

  bool get isAdmin => role == 'admin';

  ConversationMemberModel copyWith({
    String? id,
    String? conversationId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    bool? isMuted,
    DateTime? lastReadAt,
    String? userName,
    String? userAvatarUrl,
    String? userEmail,
  }) {
    return ConversationMemberModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isMuted: isMuted ?? this.isMuted,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  /// Convert to JSON for database insert
  Map<String, dynamic> toInsertJson() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
    };
  }

  /// Convert to full JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'is_muted': isMuted,
      'last_read_at': lastReadAt?.toIso8601String(),
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'user_email': userEmail,
    };
  }

  /// Create from JSON (database response)
  factory ConversationMemberModel.fromJson(Map<String, dynamic> json) {
    return ConversationMemberModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isMuted: json['is_muted'] as bool? ?? false,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
      userName: json['user_name'] as String? ??
          json['profiles']?['full_name'] as String? ??
          json['full_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String? ??
          json['profiles']?['avatar_url'] as String? ??
          json['avatar_url'] as String?,
      userEmail: json['user_email'] as String? ??
          json['profiles']?['email'] as String? ??
          json['email'] as String?,
    );
  }

  @override
  String toString() {
    return 'ConversationMemberModel(id: $id, userId: $userId, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationMemberModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Parameters for creating a conversation
class CreateConversationParams {
  final String tripId;
  final String name;
  final String? description;
  final List<String> memberUserIds;
  final bool isDirectMessage;

  const CreateConversationParams({
    required this.tripId,
    required this.name,
    this.description,
    required this.memberUserIds,
    this.isDirectMessage = false,
  });
}
