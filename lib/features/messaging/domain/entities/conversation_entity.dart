import 'package:equatable/equatable.dart';

/// Conversation entity - Domain layer representation of a group chat
class ConversationEntity extends Equatable {
  final String id;
  final String tripId;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String createdBy;
  final bool isDirectMessage;
  final bool isDefaultGroup; // True for auto-created "All Members" group
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed fields
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderName;
  final int unreadCount;
  final int memberCount;

  // DM-specific fields (other member's info for display)
  final String? dmOtherMemberName;
  final String? dmOtherMemberAvatar;

  // Members list
  final List<ConversationMemberEntity> members;

  const ConversationEntity({
    required this.id,
    required this.tripId,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.createdBy,
    this.isDirectMessage = false,
    this.isDefaultGroup = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageText,
    this.lastMessageAt,
    this.lastMessageSenderName,
    this.unreadCount = 0,
    this.memberCount = 0,
    this.dmOtherMemberName,
    this.dmOtherMemberAvatar,
    this.members = const [],
  });

  /// Get display name for the conversation
  /// For direct messages, shows the other person's name
  String getDisplayName(String currentUserId) {
    if (isDirectMessage) {
      // First try to use the pre-fetched DM member name from SQL function
      if (dmOtherMemberName != null && dmOtherMemberName!.isNotEmpty) {
        return dmOtherMemberName!;
      }
      // Fall back to searching members list
      if (members.isNotEmpty) {
        final otherMember = members.firstWhere(
          (m) => m.userId != currentUserId,
          orElse: () => members.first,
        );
        return otherMember.userName ?? name;
      }
    }
    return name;
  }

  /// Check if user is admin of this conversation
  bool isUserAdmin(String userId) {
    return members.any((m) => m.userId == userId && m.isAdmin);
  }

  /// Check if user is member of this conversation
  bool isMember(String userId) {
    return members.any((m) => m.userId == userId);
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        name,
        description,
        avatarUrl,
        createdBy,
        isDirectMessage,
        isDefaultGroup,
        createdAt,
        updatedAt,
        lastMessageText,
        lastMessageAt,
        lastMessageSenderName,
        unreadCount,
        memberCount,
        dmOtherMemberName,
        dmOtherMemberAvatar,
        members,
      ];

  ConversationEntity copyWith({
    String? id,
    String? tripId,
    String? name,
    String? description,
    String? avatarUrl,
    String? createdBy,
    bool? isDirectMessage,
    bool? isDefaultGroup,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessageText,
    DateTime? lastMessageAt,
    String? lastMessageSenderName,
    int? unreadCount,
    int? memberCount,
    String? dmOtherMemberName,
    String? dmOtherMemberAvatar,
    List<ConversationMemberEntity>? members,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdBy: createdBy ?? this.createdBy,
      isDirectMessage: isDirectMessage ?? this.isDirectMessage,
      isDefaultGroup: isDefaultGroup ?? this.isDefaultGroup,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderName: lastMessageSenderName ?? this.lastMessageSenderName,
      unreadCount: unreadCount ?? this.unreadCount,
      memberCount: memberCount ?? this.memberCount,
      dmOtherMemberName: dmOtherMemberName ?? this.dmOtherMemberName,
      dmOtherMemberAvatar: dmOtherMemberAvatar ?? this.dmOtherMemberAvatar,
      members: members ?? this.members,
    );
  }
}

/// Conversation member entity - Domain layer representation of a member
class ConversationMemberEntity extends Equatable {
  final String id;
  final String conversationId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final bool isMuted;
  final DateTime? lastReadAt;

  // Profile data
  final String? userName;
  final String? userAvatarUrl;
  final String? userEmail;

  const ConversationMemberEntity({
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
  bool get isMember => role == 'member';

  @override
  List<Object?> get props => [
        id,
        conversationId,
        userId,
        role,
        joinedAt,
        isMuted,
        lastReadAt,
        userName,
        userAvatarUrl,
        userEmail,
      ];

  ConversationMemberEntity copyWith({
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
    return ConversationMemberEntity(
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
}
