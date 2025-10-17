/// Entity representing a trip invitation
///
/// Contains all information about an invite including the invite code,
/// status, inviter details, and expiration.
class InviteEntity {
  final String id;
  final String tripId;
  final String invitedBy;
  final String email;
  final String? phoneNumber;
  final String status; // 'pending', 'accepted', 'rejected'
  final String inviteCode;
  final DateTime createdAt;
  final DateTime expiresAt;

  // Extended fields (from joins)
  final String? inviterName;
  final String? inviterEmail;
  final String? tripName;
  final String? tripDestination;

  const InviteEntity({
    required this.id,
    required this.tripId,
    required this.invitedBy,
    required this.email,
    this.phoneNumber,
    required this.status,
    required this.inviteCode,
    required this.createdAt,
    required this.expiresAt,
    this.inviterName,
    this.inviterEmail,
    this.tripName,
    this.tripDestination,
  });

  /// Check if the invite has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if the invite is still pending
  bool get isPending => status == 'pending' && !isExpired;

  /// Check if the invite has been accepted
  bool get isAccepted => status == 'accepted';

  /// Check if the invite has been rejected
  bool get isRejected => status == 'rejected';

  /// Get a user-friendly status message
  String get statusMessage {
    if (isExpired) return 'Expired';
    if (isAccepted) return 'Accepted';
    if (isRejected) return 'Rejected';
    if (isPending) return 'Pending';
    return 'Unknown';
  }

  /// Get time until expiration
  Duration get timeUntilExpiration => expiresAt.difference(DateTime.now());

  /// Get formatted time remaining
  String get timeRemainingFormatted {
    if (isExpired) return 'Expired';

    final duration = timeUntilExpiration;

    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} left';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} left';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} left';
    } else {
      return 'Expiring soon';
    }
  }

  InviteEntity copyWith({
    String? id,
    String? tripId,
    String? invitedBy,
    String? email,
    String? phoneNumber,
    String? status,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? inviterName,
    String? inviterEmail,
    String? tripName,
    String? tripDestination,
  }) {
    return InviteEntity(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      invitedBy: invitedBy ?? this.invitedBy,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      inviterName: inviterName ?? this.inviterName,
      inviterEmail: inviterEmail ?? this.inviterEmail,
      tripName: tripName ?? this.tripName,
      tripDestination: tripDestination ?? this.tripDestination,
    );
  }
}
