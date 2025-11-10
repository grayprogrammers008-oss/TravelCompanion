# Firebase Push Notifications for Trip Updates

## Overview

This document describes the implementation of Firebase Cloud Messaging (FCM) push notifications for trip-related events in the TravelCompanion app.

## Features

✅ **Trip Update Notifications**
- Trip created
- Trip updated (with specific field indication)
- Trip deleted
- Member added to trip
- Member removed from trip

✅ **Message Notifications** (existing)
- New messages
- Message reactions
- Message replies

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (Client)                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────┐         ┌────────────────────┐      │
│  │  FCM Service       │         │  Trip Repository   │      │
│  │  - Get FCM token   │         │  - CRUD operations │      │
│  │  - Handle messages │         │  - Notify updates  │      │
│  └────────────────────┘         └────────────────────┘      │
│           │                              │                   │
└───────────┼──────────────────────────────┼───────────────────┘
            │                              │
            ▼                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Backend                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────────┐         ┌────────────────────┐      │
│  │  Database          │         │  Edge Function     │      │
│  │  - trips table     │────────▶│  send-trip-        │      │
│  │  - trip_members    │ trigger │  notification      │      │
│  │  - user_fcm_tokens │         └────────────────────┘      │
│  └────────────────────┘                  │                   │
│                                          │                   │
└──────────────────────────────────────────┼───────────────────┘
                                           │
                                           ▼
                                   ┌──────────────┐
                                   │   Firebase   │
                                   │     FCM      │
                                   └──────────────┘
                                           │
                                           ▼
                                   [Push Notification]
                                   to User Devices
```

## Implementation Details

### 1. Client-Side (Flutter)

#### FCM Service
Location: `lib/features/messaging/data/services/fcm_service.dart`

**Responsibilities:**
- Initialize Firebase Messaging
- Request notification permissions
- Get and refresh FCM tokens
- Handle foreground and background messages
- Display local notifications

#### Trip Notification Service
Location: `lib/features/trips/data/services/trip_notification_service.dart`

**Responsibilities:**
- Send trip event notifications via Supabase Edge Function
- Handle different notification types (create, update, delete, member changes)

#### Notification Payload
Location: `lib/features/messaging/domain/entities/notification_payload.dart`

**Supported Notification Types:**
```dart
- 'trip_created'    // New trip created
- 'trip_updated'    // Trip details updated
- 'trip_deleted'    // Trip deleted
- 'member_added'    // New member joined
- 'member_removed'  // Member left/removed
- 'new_message'     // New chat message
- 'message_reaction'// Message reaction
- 'message_reply'   // Message reply
```

### 2. Server-Side (Supabase)

#### Database Tables

**user_fcm_tokens**
```sql
CREATE TABLE user_fcm_tokens (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id),
    fcm_token TEXT NOT NULL,
    device_id TEXT,
    device_type TEXT, -- 'ios', 'android', 'web'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    last_used_at TIMESTAMP
);
```

#### Database Functions

**register_fcm_token(token, device_id, device_type)**
- Registers or updates FCM token for the current user
- Deactivates old tokens for the same device
- Returns token ID

**unregister_fcm_token(device_id)**
- Deactivates FCM token for specified device
- Returns success boolean

#### Database Triggers

**trigger_notify_trip_updated**
- Fires on `trips` table UPDATE
- Detects which field was changed
- Logs notification event

**trigger_notify_member_added**
- Fires on `trip_members` table INSERT
- Logs when a new member joins a trip

#### Edge Function

**send-trip-notification**
Location: `supabase/functions/send-trip-notification/index.ts`

**Process:**
1. Receive trip event data
2. Fetch trip members (excluding the user who triggered the event)
3. Get FCM tokens for eligible users
4. Generate notification title and body
5. Send FCM notifications to all tokens
6. Return success/failure statistics

**Request Body:**
```typescript
{
  trip_id: string,
  payload: NotificationPayload,
  exclude_user_id?: string  // Don't notify this user
}
```

**Response:**
```typescript
{
  success: boolean,
  sent: number,      // Successfully sent
  failed: number,    // Failed to send
  total: number      // Total attempted
}
```

## Setup Instructions

### 1. Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing
   - Add Android and iOS apps

2. **Get Server Key**
   - Go to Project Settings > Cloud Messaging
   - Copy the **Server key** (Legacy)
   - This will be used in Supabase Edge Function

3. **Download Config Files**
   - **Android**: Download `google-services.json` → Place in `android/app/`
   - **iOS**: Download `GoogleService-Info.plist` → Place in `ios/Runner/`

### 2. Supabase Setup

1. **Run Migration**
   ```bash
   supabase db push
   # Or apply manually:
   psql -U postgres -d your_database -f supabase/migrations/20250127_trip_notifications.sql
   ```

2. **Deploy Edge Function**
   ```bash
   supabase functions deploy send-trip-notification
   ```

3. **Set Environment Variables**
   ```bash
   supabase secrets set FCM_SERVER_KEY=your_firebase_server_key
   ```

### 3. App Configuration

1. **Initialize Firebase** (already done in `main.dart`)
   ```dart
   await Firebase.initializeApp();
   ```

2. **Initialize FCM Service** (already done in `notification_provider.dart`)
   ```dart
   final fcmService = ref.read(fcmServiceProvider);
   await fcmService.initialize();
   ```

3. **Register FCM Token**
   ```dart
   // This should be called after successful login
   final fcmToken = await FirebaseMessaging.instance.getToken();
   final deviceId = await getDeviceId(); // Use device_info_plus package

   await supabase.rpc('register_fcm_token', params: {
     'p_fcm_token': fcmToken,
     'p_device_id': deviceId,
     'p_device_type': Platform.isIOS ? 'ios' : 'android',
   });
   ```

## Usage Examples

### Send Trip Update Notification

The notifications are automatically sent by database triggers, but you can also manually trigger them:

```dart
// When a trip is updated
final tripNotificationService = ref.read(tripNotificationServiceProvider);

await tripNotificationService.notifyTripUpdated(
  tripId: tripId,
  tripName: tripName,
  updatedBy: currentUserId,
  updaterName: currentUserName,
  updatedField: 'destination', // Optional: specific field that was updated
);
```

### Send Member Added Notification

```dart
await tripNotificationService.notifyMemberAdded(
  tripId: tripId,
  tripName: tripName,
  memberId: newMemberId,
  memberName: newMemberName,
);
```

### Handle Notification Tap

```dart
// In notification_provider.dart
void _handleNotificationTapped(Map<String, dynamic> data) {
  final payload = NotificationPayload.fromJson(data);

  // Navigate based on notification type
  switch (payload.type) {
    case 'trip_updated':
    case 'trip_created':
      // Navigate to trip details
      router.push('/trips/${payload.tripId}');
      break;
    case 'member_added':
      // Navigate to trip members page
      router.push('/trips/${payload.tripId}/members');
      break;
    case 'new_message':
      // Navigate to messages
      router.push('/trips/${payload.tripId}/messages');
      break;
  }
}
```

## Testing

### 1. Test FCM Token Registration

```dart
void testFCMRegistration() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $fcmToken');

  // Check if token is saved in Supabase
  final result = await supabase
    .from('user_fcm_tokens')
    .select()
    .eq('user_id', currentUserId)
    .eq('is_active', true);

  print('Saved tokens: $result');
}
```

### 2. Test Trip Update Notification

```dart
void testTripUpdateNotification() async {
  // Update a trip
  await tripRepository.updateTrip(
    tripId: 'test-trip-id',
    name: 'Updated Trip Name',
  );

  // Check edge function logs in Supabase dashboard
  // Check if notification was received on other devices
}
```

### 3. Manual Edge Function Test

```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/send-trip-notification \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "trip_id": "test-trip-id",
    "payload": {
      "type": "trip_updated",
      "trip_id": "test-trip-id",
      "trip_name": "Test Trip",
      "sender_id": "user-id",
      "sender_name": "Test User",
      "updated_field": "name"
    }
  }'
```

## Notification Channels (Android)

The app creates notification channels for better organization:

```dart
// In fcm_service.dart
const channel = AndroidNotificationChannel(
  'trip_updates',      // ID
  'Trip Updates',      // Name
  description: 'Notifications for trip updates',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);
```

## Permissions

### iOS (Info.plist)
```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

## Troubleshooting

### Notifications Not Received

1. **Check FCM Token**
   - Verify token is registered in `user_fcm_tokens` table
   - Check `is_active = true`

2. **Check Edge Function Logs**
   ```bash
   supabase functions logs send-trip-notification
   ```

3. **Verify Firebase Server Key**
   - Ensure FCM_SERVER_KEY is set correctly
   - Test with Firebase Console > Cloud Messaging > Send test message

4. **Check Permissions**
   - iOS: Settings > [App Name] > Notifications
   - Android: Settings > Apps > [App Name] > Notifications

### Edge Function Fails

1. **Check Environment Variables**
   ```bash
   supabase secrets list
   ```

2. **Verify Database Access**
   - Ensure service role key is set
   - Check RLS policies on user_fcm_tokens table

3. **Test Edge Function Locally**
   ```bash
   supabase functions serve send-trip-notification
   ```

## Performance Considerations

1. **Token Cleanup**
   - Periodically remove inactive tokens (>90 days)
   - Deactivate tokens on logout

2. **Batch Notifications**
   - Edge function sends to all members in parallel
   - Uses Promise.allSettled for error handling

3. **Database Indexes**
   - Index on `user_id` for fast lookups
   - Index on `is_active` for filtering

## Security

1. **RLS Policies**
   - Users can only manage their own FCM tokens
   - Edge function uses service role key for broader access

2. **Token Privacy**
   - FCM tokens are not exposed to other users
   - Only stored server-side

3. **Notification Privacy**
   - Exclude the user who triggered the event
   - Only send to trip members

## Future Enhancements

- [ ] Notification preferences (per-trip mute, notification types)
- [ ] Push notification analytics and delivery tracking
- [ ] Rich notifications with images and actions
- [ ] Notification grouping by trip
- [ ] Silent notifications for data sync
- [ ] Multi-language notification support

## Related Files

- `lib/features/messaging/data/services/fcm_service.dart`
- `lib/features/messaging/domain/entities/notification_payload.dart`
- `lib/features/messaging/presentation/providers/notification_provider.dart`
- `lib/features/trips/data/services/trip_notification_service.dart`
- `lib/features/trips/presentation/providers/trip_notification_provider.dart`
- `supabase/functions/send-trip-notification/index.ts`
- `supabase/migrations/20250127_trip_notifications.sql`

## Support

For issues or questions:
1. Check Firebase Console logs
2. Check Supabase Edge Function logs
3. Review RLS policies and permissions
4. Test with Firebase Console test messages

---

**Last Updated:** January 27, 2025
**Status:** ✅ Implemented and Ready for Testing
