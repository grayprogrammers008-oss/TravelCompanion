// Trip permission utilities
//
// Provides centralized permission checking for trip-related operations.
// Only trip creators (owners) and admins can edit/delete trip content.
// Regular members have read-only access.

import '../../shared/models/trip_model.dart';

/// Permission levels for trip members
enum TripPermissionLevel {
  /// Full control - trip creator/owner
  owner,

  /// Admin privileges - can edit content but not delete trip
  admin,

  /// Read-only access - can view and add expenses only
  member,

  /// No access
  none,
}

/// Centralized trip permission checker
class TripPermissions {
  /// Check if the user can edit trip details (name, dates, budget, etc.)
  /// Note: Completed trips cannot be edited (view-only mode)
  static bool canEditTrip({
    required String? currentUserId,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return false;

    // Completed trips are view-only
    if (tripWithMembers.trip.isCompleted) return false;

    // Only owner can edit trip details
    return tripWithMembers.trip.createdBy == currentUserId;
  }

  /// Check if the user can delete the trip
  static bool canDeleteTrip({
    required String? currentUserId,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return false;

    // Only owner can delete trip
    return tripWithMembers.trip.createdBy == currentUserId;
  }

  /// Check if the user can edit itinerary (add/edit/delete/reorder items)
  /// Note: Completed trips cannot be edited (view-only mode)
  static bool canEditItinerary({
    required String? currentUserId,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return false;

    // Completed trips are view-only
    if (tripWithMembers.trip.isCompleted) return false;

    // Owner can always edit
    if (tripWithMembers.trip.createdBy == currentUserId) return true;

    // Admins can edit
    return _isAdmin(currentUserId, tripWithMembers);
  }

  /// Check if the user can edit checklists (add/edit/delete checklists and items)
  /// Note: Completed trips cannot be edited (view-only mode)
  static bool canEditChecklists({
    required String? currentUserId,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return false;

    // Completed trips are view-only
    if (tripWithMembers.trip.isCompleted) return false;

    // Owner can always edit
    if (tripWithMembers.trip.createdBy == currentUserId) return true;

    // Admins can edit
    return _isAdmin(currentUserId, tripWithMembers);
  }

  /// Check if the user can add expenses
  /// Note: All members can add their own expenses
  static bool canAddExpenses({
    required String? currentUserId,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return false;

    // All members can add expenses
    return _isMember(currentUserId, tripWithMembers);
  }

  /// Check if the user can edit/delete a specific expense
  /// Users can only edit/delete their own expenses, unless they are owner/admin
  static bool canEditExpense({
    required String? currentUserId,
    required String expenseCreatedBy,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return false;

    // User can edit their own expense
    if (expenseCreatedBy == currentUserId) return true;

    // Owner can edit any expense
    if (tripWithMembers.trip.createdBy == currentUserId) return true;

    // Admins can edit any expense
    return _isAdmin(currentUserId, tripWithMembers);
  }

  /// Check if the user can manage members (add/remove)
  /// Note: Completed trips cannot be edited (view-only mode)
  static bool canManageMembers({
    required String? currentUserId,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return false;

    // Completed trips are view-only
    if (tripWithMembers.trip.isCompleted) return false;

    // Owner can always manage members
    if (tripWithMembers.trip.createdBy == currentUserId) return true;

    // Admins can manage members
    return _isAdmin(currentUserId, tripWithMembers);
  }

  /// Check if the user can mark the trip as completed
  static bool canCompletTrip({
    required String? currentUserId,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return false;

    // Only owner can complete trip
    return tripWithMembers.trip.createdBy == currentUserId;
  }

  /// Check if the user can edit rating/review (allowed even for completed trips)
  /// This is a post-trip reflection activity
  static bool canEditRating({
    required String? currentUserId,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return false;

    // Only owner can rate/review the trip (even after completion)
    return tripWithMembers.trip.createdBy == currentUserId;
  }

  /// Get the permission level for a user in a trip
  static TripPermissionLevel getPermissionLevel({
    required String? currentUserId,
    required TripWithMembers tripWithMembers,
  }) {
    if (currentUserId == null) return TripPermissionLevel.none;

    // Check if owner
    if (tripWithMembers.trip.createdBy == currentUserId) {
      return TripPermissionLevel.owner;
    }

    // Check member role
    final member = tripWithMembers.members.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => TripMemberModel(
        id: '',
        tripId: tripWithMembers.trip.id,
        userId: '',
        role: '',
      ),
    );

    if (member.userId.isEmpty) {
      return TripPermissionLevel.none;
    }

    if (member.role == 'admin') {
      return TripPermissionLevel.admin;
    }

    return TripPermissionLevel.member;
  }

  /// Check if user is a trip admin (not owner, but has admin role)
  static bool _isAdmin(String userId, TripWithMembers tripWithMembers) {
    return tripWithMembers.members.any(
      (m) => m.userId == userId && m.role == 'admin',
    );
  }

  /// Check if user is a member of the trip (any role)
  static bool _isMember(String userId, TripWithMembers tripWithMembers) {
    return tripWithMembers.members.any((m) => m.userId == userId);
  }
}
