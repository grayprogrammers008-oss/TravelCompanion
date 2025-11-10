import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../messaging/domain/entities/notification_payload.dart';

/// Trip Notification Service
/// Handles sending push notifications for trip-related events
class TripNotificationService {
  final SupabaseClient _supabase;

  TripNotificationService(this._supabase);

  /// Send notification when a trip is created
  Future<void> notifyTripCreated({
    required String tripId,
    required String tripName,
    required String creatorId,
    required String creatorName,
  }) async {
    try {
      debugPrint('📤 [TripNotification] Sending trip created notification');

      final payload = NotificationPayload(
        type: 'trip_created',
        tripId: tripId,
        tripName: tripName,
        senderId: creatorId,
        senderName: creatorName,
      );

      await _sendNotification(
        tripId: tripId,
        payload: payload,
        excludeUserId: creatorId, // Don't notify the creator
      );

      debugPrint('✅ [TripNotification] Trip created notification sent');
    } catch (e) {
      debugPrint('❌ [TripNotification] Failed to send trip created notification: $e');
    }
  }

  /// Send notification when a trip is updated
  Future<void> notifyTripUpdated({
    required String tripId,
    required String tripName,
    required String updatedBy,
    required String updaterName,
    String? updatedField,
  }) async {
    try {
      debugPrint('📤 [TripNotification] Sending trip updated notification');

      final payload = NotificationPayload(
        type: 'trip_updated',
        tripId: tripId,
        tripName: tripName,
        senderId: updatedBy,
        senderName: updaterName,
        updatedField: updatedField,
      );

      await _sendNotification(
        tripId: tripId,
        payload: payload,
        excludeUserId: updatedBy, // Don't notify the updater
      );

      debugPrint('✅ [TripNotification] Trip updated notification sent');
    } catch (e) {
      debugPrint('❌ [TripNotification] Failed to send trip updated notification: $e');
    }
  }

  /// Send notification when a trip is deleted
  Future<void> notifyTripDeleted({
    required String tripId,
    required String tripName,
    required String deletedBy,
    required String deleterName,
  }) async {
    try {
      debugPrint('📤 [TripNotification] Sending trip deleted notification');

      final payload = NotificationPayload(
        type: 'trip_deleted',
        tripId: tripId,
        tripName: tripName,
        senderId: deletedBy,
        senderName: deleterName,
      );

      await _sendNotification(
        tripId: tripId,
        payload: payload,
        excludeUserId: deletedBy, // Don't notify the deleter
      );

      debugPrint('✅ [TripNotification] Trip deleted notification sent');
    } catch (e) {
      debugPrint('❌ [TripNotification] Failed to send trip deleted notification: $e');
    }
  }

  /// Send notification when a member is added to a trip
  Future<void> notifyMemberAdded({
    required String tripId,
    required String tripName,
    required String memberId,
    required String memberName,
  }) async {
    try {
      debugPrint('📤 [TripNotification] Sending member added notification');

      final payload = NotificationPayload(
        type: 'member_added',
        tripId: tripId,
        tripName: tripName,
        memberName: memberName,
      );

      await _sendNotification(
        tripId: tripId,
        payload: payload,
        excludeUserId: memberId, // Don't notify the new member
      );

      debugPrint('✅ [TripNotification] Member added notification sent');
    } catch (e) {
      debugPrint('❌ [TripNotification] Failed to send member added notification: $e');
    }
  }

  /// Send notification when a member is removed from a trip
  Future<void> notifyMemberRemoved({
    required String tripId,
    required String tripName,
    required String memberId,
    required String memberName,
  }) async {
    try {
      debugPrint('📤 [TripNotification] Sending member removed notification');

      final payload = NotificationPayload(
        type: 'member_removed',
        tripId: tripId,
        tripName: tripName,
        memberName: memberName,
      );

      await _sendNotification(
        tripId: tripId,
        payload: payload,
        excludeUserId: memberId, // Don't notify the removed member
      );

      debugPrint('✅ [TripNotification] Member removed notification sent');
    } catch (e) {
      debugPrint('❌ [TripNotification] Failed to send member removed notification: $e');
    }
  }

  /// Internal method to send notification via Supabase Edge Function
  Future<void> _sendNotification({
    required String tripId,
    required NotificationPayload payload,
    String? excludeUserId,
  }) async {
    try {
      // Call Supabase Edge Function to send push notification
      // The edge function will:
      // 1. Get all trip members
      // 2. Get their FCM tokens
      // 3. Send push notification via FCM
      final response = await _supabase.functions.invoke(
        'send-trip-notification',
        body: {
          'trip_id': tripId,
          'payload': payload.toJson(),
          'exclude_user_id': excludeUserId,
        },
      );

      if (response.status != 200) {
        throw Exception('Edge function returned status ${response.status}');
      }

      debugPrint('   ✅ Notification sent via edge function');
    } catch (e) {
      debugPrint('   ❌ Failed to send notification via edge function: $e');
      rethrow;
    }
  }
}
