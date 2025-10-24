import 'package:equatable/equatable.dart';

/// Notification Payload
/// Represents the data structure for message notifications
class NotificationPayload extends Equatable {
  final String type; // 'new_message', 'message_reaction', 'message_reply'
  final String tripId;
  final String tripName;
  final String messageId;
  final String? senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? messageText;
  final String? reactionEmoji;

  const NotificationPayload({
    required this.type,
    required this.tripId,
    required this.tripName,
    required this.messageId,
    this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    this.messageText,
    this.reactionEmoji,
  });

  /// Create from JSON (FCM data payload)
  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type'] as String? ?? 'new_message',
      tripId: json['trip_id'] as String? ?? json['tripId'] as String,
      tripName: json['trip_name'] as String? ?? json['tripName'] as String,
      messageId: json['message_id'] as String? ?? json['messageId'] as String,
      senderId: json['sender_id'] as String? ?? json['senderId'] as String?,
      senderName: json['sender_name'] as String? ?? json['senderName'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String? ?? json['senderAvatarUrl'] as String?,
      messageText: json['message_text'] as String? ?? json['messageText'] as String?,
      reactionEmoji: json['reaction_emoji'] as String? ?? json['reactionEmoji'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'trip_id': tripId,
      'trip_name': tripName,
      'message_id': messageId,
      if (senderId != null) 'sender_id': senderId,
      if (senderName != null) 'sender_name': senderName,
      if (senderAvatarUrl != null) 'sender_avatar_url': senderAvatarUrl,
      if (messageText != null) 'message_text': messageText,
      if (reactionEmoji != null) 'reaction_emoji': reactionEmoji,
    };
  }

  /// Get notification title based on type
  String getTitle() {
    switch (type) {
      case 'new_message':
        return senderName ?? 'New Message';
      case 'message_reaction':
        return '$senderName reacted to your message';
      case 'message_reply':
        return '$senderName replied to your message';
      default:
        return tripName;
    }
  }

  /// Get notification body based on type
  String getBody() {
    switch (type) {
      case 'new_message':
        return messageText ?? 'You have a new message in $tripName';
      case 'message_reaction':
        return reactionEmoji ?? '❤️';
      case 'message_reply':
        return messageText ?? 'Replied to your message';
      default:
        return messageText ?? '';
    }
  }

  @override
  List<Object?> get props => [
        type,
        tripId,
        tripName,
        messageId,
        senderId,
        senderName,
        senderAvatarUrl,
        messageText,
        reactionEmoji,
      ];
}
