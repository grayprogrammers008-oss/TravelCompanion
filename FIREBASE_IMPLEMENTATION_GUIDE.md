# Firebase Push Notifications - Implementation Continuation Guide

**Status:** ✅ Configuration Complete | 🔄 Implementation Pending
**Assignee:** Nithya
**GitHub Issue:** #10 - Implement Firebase Push Notifications for Trip Updates

---

## ✅ What's Already Done

### Firebase Project Setup (COMPLETED)
- ✅ Firebase project created: `TravelCompanion-Pro`
- ✅ Project ID: `TravelCompanion-Pro`
- ✅ Sender ID: `814061636834`
- ✅ Android app registered: `com.pathio.travel`
- ✅ iOS app registered: `com.pathio.travel`

### Configuration Files (COMMITTED)
- ✅ `android/app/google-services.json` - Android FCM config
- ✅ `ios/Runner/GoogleService-Info.plist` - iOS FCM config
- ✅ `supabase/functions/.secrets/firebase-service-account.json` - Backend service account
- ✅ `.gitignore` updated to protect secrets

---

## 🔄 What Needs to be Done

### Phase 1: Add Dependencies (15 minutes)
### Phase 2: Configure Android Native (20 minutes)
### Phase 3: Configure iOS Native (25 minutes)
### Phase 4: Implement Notification Service (45 minutes)
### Phase 5: Create Notification Center UI (60 minutes)
### Phase 6: Implement Supabase Integration (90 minutes)
### Phase 7: Testing & Verification (30 minutes)

**Total Estimated Time:** 4-5 hours

---

## PHASE 1: Add Dependencies

### Step 1.1: Update `pubspec.yaml`

Add these dependencies:

```yaml
dependencies:
  # Existing dependencies...

  # Firebase
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3

  # Local notifications (for foreground)
  flutter_local_notifications: ^18.0.1

  # Deep linking (for notification tap handling)
  go_router: ^14.6.2  # Already added, ensure this version
```

### Step 1.2: Install Dependencies

```bash
cd /Users/vinothvs/Development/TravelCompanion
flutter pub get
```

### Step 1.3: Verify Installation

```bash
flutter pub deps | grep firebase
```

**Expected Output:**
```
firebase_core 3.6.0
firebase_messaging 15.1.3
```

---

## PHASE 2: Configure Android Native

### Step 2.1: Update `android/build.gradle`

**File:** `android/build.gradle`

Add Google services classpath:

```gradle
buildscript {
    ext.kotlin_version = '1.9.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"

        // ADD THIS LINE:
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

### Step 2.2: Update `android/app/build.gradle`

**File:** `android/app/build.gradle`

Add plugin at the **very bottom** of the file:

```gradle
// ... existing configuration ...

dependencies {
    // ... existing dependencies ...
}

// ADD THIS LINE AT THE BOTTOM:
apply plugin: 'com.google.gms.google-services'
```

### Step 2.3: Update `android/app/src/main/AndroidManifest.xml`

**File:** `android/app/src/main/AndroidManifest.xml`

Add permissions and service inside `<application>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add permissions BEFORE <application> tag -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application
        android:label="Travel Companion"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Existing activity configuration -->
        <activity android:name=".MainActivity" ...>
            <!-- ... -->
        </activity>

        <!-- ADD FIREBASE MESSAGING SERVICE -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- ADD NOTIFICATION METADATA -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/colorPrimary" />
    </application>
</manifest>
```

### Step 2.4: Verify Android Configuration

```bash
cd android
./gradlew clean
./gradlew build
```

**Expected:** Build succeeds without errors.

---

## PHASE 3: Configure iOS Native

### Step 3.1: Update `ios/Podfile`

**File:** `ios/Podfile`

Ensure minimum iOS version is 13.0+:

```ruby
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'
```

### Step 3.2: Install Firebase Pods

```bash
cd ios
pod install
cd ..
```

### Step 3.3: Add Notification Capabilities in Xcode

**Manual Steps (Must be done in Xcode):**

1. Open `ios/Runner.xcworkspace` (NOT .xcodeproj!)
2. Select `Runner` project in left sidebar
3. Select `Runner` target
4. Click `Signing & Capabilities` tab
5. Click `+ Capability` button
6. Add **"Push Notifications"**
7. Add **"Background Modes"**
   - Check ✅ "Background fetch"
   - Check ✅ "Remote notifications"

### Step 3.4: Update `ios/Runner/Info.plist`

**File:** `ios/Runner/Info.plist`

Add Firebase initialization flag:

```xml
<dict>
    <!-- Existing keys -->

    <!-- ADD THIS -->
    <key>FirebaseAppDelegateProxyEnabled</key>
    <false/>
</dict>
```

### Step 3.5: Update `ios/Runner/AppDelegate.swift`

**File:** `ios/Runner/AppDelegate.swift`

Replace entire file with:

```swift
import UIKit
import Flutter
import FirebaseCore
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase
    FirebaseApp.configure()

    // Request notification permissions
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }

    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

### Step 3.6: Verify iOS Configuration

```bash
cd ios
xcodebuild clean
xcodebuild build -workspace Runner.xcworkspace -scheme Runner
```

**Expected:** Build succeeds without errors.

---

## PHASE 4: Implement Notification Service

### Step 4.1: Create Notification Service File

**File:** `lib/core/services/notification_service.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Store notification in local database for notification center
  await NotificationService.storeNotification(message);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  // Stream for listening to notification taps
  static Stream<RemoteMessage> get onMessageTap => _messageStreamController.stream;

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('Notification permission denied');
      return;
    }

    // Initialize local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Get and store FCM token
    String? token = await _fcm.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveFCMToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');

    // Store in database
    await storeNotification(message);

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle notification tap
  static void _handleMessageTap(RemoteMessage message) {
    print('Notification tapped: ${message.data}');
    _messageStreamController.add(message);
  }

  /// Handle local notification tap
  static void _onNotificationTap(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Parse payload and navigate
  }

  /// Show local notification for foreground messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );
  }

  /// Store notification in database
  static Future<void> storeNotification(RemoteMessage message) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('notifications').insert({
        'user_id': user.id,
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error storing notification: $e');
    }
  }

  /// Save FCM token to user profile
  static Future<void> _saveFCMToken(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('profiles').update({
        'fcm_token': token,
        'fcm_token_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      print('FCM token saved: $token');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Clear FCM token on logout
  static Future<void> clearToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('profiles').update({
        'fcm_token': null,
        'fcm_token_updated_at': null,
      }).eq('id', user.id);

      await _fcm.deleteToken();
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }
}

// Provider for notification stream
final notificationStreamProvider = StreamProvider<RemoteMessage>((ref) {
  return NotificationService.onMessageTap;
});
```

### Step 4.2: Initialize in `main.dart`

**File:** `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase (already exists)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize Notifications
  await NotificationService.initialize();

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}
```

---

## PHASE 5: Create Notification Center UI

### Step 5.1: Create Database Schema

Run this SQL in Supabase SQL Editor:

```sql
-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id
  ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at
  ON notifications(created_at DESC);

-- Add RLS policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  USING (auth.uid() = user_id);

-- Add fcm_token to profiles table
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT,
  ADD COLUMN IF NOT EXISTS fcm_token_updated_at TIMESTAMPTZ;

-- Add index for FCM token lookups
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token
  ON profiles(fcm_token) WHERE fcm_token IS NOT NULL;
```

### Step 5.2: Create Notification Model

**File:** `lib/features/notifications/domain/entities/notification.dart`

```dart
import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, title, body, data, read, createdAt];

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### Step 5.3: Create Notification Data Source

**File:** `lib/features/notifications/data/datasources/notification_remote_datasource.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification.dart';

class NotificationRemoteDataSource {
  final SupabaseClient _client;

  NotificationRemoteDataSource(this._client);

  Stream<List<AppNotification>> watchNotifications() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map(_fromJson).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client
        .from('notifications')
        .delete()
        .eq('id', notificationId);
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .eq('read', false)
        .count();

    return response.count;
  }

  AppNotification _fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      read: json['read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
```

### Step 5.4: Create Notification Provider

**File:** `lib/features/notifications/presentation/providers/notification_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../domain/entities/notification.dart';

final notificationDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(Supabase.instance.client);
});

final notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final dataSource = ref.watch(notificationDataSourceProvider);
  return dataSource.watchNotifications();
});

final unreadCountProvider = StreamProvider<int>((ref) async* {
  final dataSource = ref.watch(notificationDataSourceProvider);

  // Initial count
  yield await dataSource.getUnreadCount();

  // Watch for changes
  await for (final notifications in dataSource.watchNotifications()) {
    yield notifications.where((n) => !n.read).length;
  }
});
```

### Step 5.5: Create Notification Center Page

**File:** `lib/features/notifications/presentation/pages/notification_center_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../providers/notification_providers.dart';
import '../../domain/entities/notification.dart';

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.when(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.read);
              if (!hasUnread) return const SizedBox.shrink();

              return TextButton(
                onPressed: () async {
                  final dataSource = ref.read(notificationDataSourceProvider);
                  await dataSource.markAllAsRead();
                },
                child: const Text('Mark all read'),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
        loading: () => const Center(
          child: AppLoadingIndicator(message: 'Loading notifications...'),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingMd),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final dataSource = ref.read(notificationDataSourceProvider);
        await dataSource.deleteNotification(notification.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.read
              ? Theme.of(context).colorScheme.surfaceVariant
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            _getIconForType(notification.data['type'] as String?),
            color: notification.read
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
        onTap: () async {
          // Mark as read
          if (!notification.read) {
            final dataSource = ref.read(notificationDataSourceProvider);
            await dataSource.markAsRead(notification.id);
          }

          // Navigate based on type
          _handleNotificationTap(context, notification);
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'trip_invite':
        return Icons.card_travel;
      case 'expense_added':
        return Icons.receipt_long;
      case 'itinerary_updated':
        return Icons.event;
      case 'checklist_assigned':
        return Icons.check_box;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    final type = notification.data['type'] as String?;
    final id = notification.data['id'] as String?;

    if (id == null) return;

    switch (type) {
      case 'trip_invite':
        context.go('/trips/$id');
        break;
      case 'expense_added':
        context.go('/trips/$id/expenses');
        break;
      case 'itinerary_updated':
        context.go('/trips/$id/itinerary');
        break;
      case 'checklist_assigned':
        context.go('/trips/$id/checklists');
        break;
    }
  }
}
```

### Step 5.6: Add to Router

**File:** `lib/core/router/app_router.dart`

Add notification route:

```dart
GoRoute(
  path: '/notifications',
  name: 'notifications',
  builder: (context, state) => const NotificationCenterPage(),
),
```

### Step 5.7: Add Notification Badge to AppBar

Update home page AppBar to show unread count:

```dart
AppBar(
  actions: [
    // Add notification bell
    Consumer(
      builder: (context, ref, _) {
        final unreadCount = ref.watch(unreadCountProvider);

        return unreadCount.when(
          data: (count) => Badge(
            label: count > 0 ? Text('$count') : null,
            isLabelVisible: count > 0,
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => context.go('/notifications'),
            ),
          ),
          loading: () => IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.go('/notifications'),
          ),
          error: (_, __) => IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => context.go('/notifications'),
          ),
        );
      },
    ),
  ],
)
```

---

## PHASE 6: Implement Supabase Edge Function

### Step 6.1: Create Edge Function

```bash
cd supabase/functions
supabase functions new send-notification
```

### Step 6.2: Implement Function

**File:** `supabase/functions/send-notification/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"
import { ServiceAccount, getMessaging } from "npm:firebase-admin/messaging"
import { initializeApp } from "npm:firebase-admin/app"

// Initialize Firebase Admin
const serviceAccount: ServiceAccount = JSON.parse(
  Deno.readTextFileSync("../.secrets/firebase-service-account.json")
)

const firebaseApp = initializeApp({
  credential: serviceAccount,
})

const messaging = getMessaging(firebaseApp)

interface NotificationRequest {
  user_ids: string[]
  title: string
  body: string
  data?: Record<string, string>
  type: 'trip_invite' | 'expense_added' | 'itinerary_updated' | 'checklist_assigned'
}

serve(async (req) => {
  try {
    // Verify request method
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Parse request body
    const payload: NotificationRequest = await req.json()
    const { user_ids, title, body, data, type } = payload

    // Validate inputs
    if (!user_ids || user_ids.length === 0) {
      return new Response(
        JSON.stringify({ error: 'user_ids required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!title || !body || !type) {
      return new Response(
        JSON.stringify({ error: 'title, body, and type required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Fetch FCM tokens for users
    const { data: profiles, error: profileError } = await supabaseClient
      .from('profiles')
      .select('fcm_token')
      .in('id', user_ids)
      .not('fcm_token', 'is', null)

    if (profileError) {
      throw profileError
    }

    const tokens = profiles
      .map(p => p.fcm_token)
      .filter(t => t !== null) as string[]

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: 'No FCM tokens found', sent: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Send notifications
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        type,
        ...data,
      },
      tokens,
    }

    const response = await messaging.sendMulticast(message)

    console.log(`Sent ${response.successCount} notifications`)
    console.log(`Failed ${response.failureCount} notifications`)

    // Store notifications in database
    const notifications = user_ids.map(user_id => ({
      user_id,
      title,
      body,
      data: { type, ...data },
      read: false,
    }))

    const { error: insertError } = await supabaseClient
      .from('notifications')
      .insert(notifications)

    if (insertError) {
      console.error('Error storing notifications:', insertError)
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent: response.successCount,
        failed: response.failureCount,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
```

### Step 6.3: Deploy Function

```bash
supabase functions deploy send-notification
```

### Step 6.4: Create Database Triggers

Run this SQL in Supabase SQL Editor:

```sql
-- Function to send trip invite notification
CREATE OR REPLACE FUNCTION notify_trip_invite()
RETURNS TRIGGER AS $$
DECLARE
  trip_name TEXT;
  inviter_name TEXT;
BEGIN
  -- Get trip name
  SELECT name INTO trip_name
  FROM trips
  WHERE id = NEW.trip_id;

  -- Get inviter name
  SELECT full_name INTO inviter_name
  FROM profiles
  WHERE id = NEW.invited_by;

  -- Call Edge Function
  PERFORM net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/send-notification',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := jsonb_build_object(
      'user_ids', ARRAY[NEW.user_id],
      'title', 'Trip Invitation',
      'body', inviter_name || ' invited you to ' || trip_name,
      'type', 'trip_invite',
      'data', jsonb_build_object('id', NEW.trip_id::text)
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for trip invites
CREATE TRIGGER trigger_trip_invite_notification
  AFTER INSERT ON trip_members
  FOR EACH ROW
  WHEN (NEW.status = 'pending')
  EXECUTE FUNCTION notify_trip_invite();

-- Function to send expense notification
CREATE OR REPLACE FUNCTION notify_expense_added()
RETURNS TRIGGER AS $$
DECLARE
  trip_name TEXT;
  payer_name TEXT;
  member_ids UUID[];
BEGIN
  -- Get trip name
  SELECT name INTO trip_name
  FROM trips
  WHERE id = NEW.trip_id;

  -- Get payer name
  SELECT full_name INTO payer_name
  FROM profiles
  WHERE id = NEW.paid_by;

  -- Get all trip member IDs except payer
  SELECT ARRAY_AGG(user_id) INTO member_ids
  FROM trip_members
  WHERE trip_id = NEW.trip_id
    AND user_id != NEW.paid_by
    AND status = 'accepted';

  -- Call Edge Function
  IF member_ids IS NOT NULL AND array_length(member_ids, 1) > 0 THEN
    PERFORM net.http_post(
      url := current_setting('app.settings.supabase_url') || '/functions/v1/send-notification',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object(
        'user_ids', member_ids,
        'title', 'New Expense',
        'body', payer_name || ' added an expense in ' || trip_name,
        'type', 'expense_added',
        'data', jsonb_build_object('id', NEW.trip_id::text)
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for expenses
CREATE TRIGGER trigger_expense_notification
  AFTER INSERT ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION notify_expense_added();
```

---

## PHASE 7: Testing

### Step 7.1: Test Permissions

```dart
// In app, trigger notification permission request
await NotificationService.initialize();
```

**Expected:** Permission dialog appears on iOS and Android

### Step 7.2: Test Token Storage

```sql
-- Check if FCM token is stored
SELECT id, full_name, fcm_token
FROM profiles
WHERE fcm_token IS NOT NULL;
```

**Expected:** Your user's FCM token appears

### Step 7.3: Test Manual Notification

Use Firebase Console to send test notification:

1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter title and body
4. Click "Send test message"
5. Enter your FCM token
6. Click "Test"

**Expected:** Notification appears on device

### Step 7.4: Test Trip Invite Flow

1. Create new trip
2. Invite another user
3. Check invited user's device

**Expected:** Notification appears and is stored in notification center

### Step 7.5: Test Notification Center

1. Open app
2. Navigate to /notifications
3. Verify notifications list appears
4. Tap notification
5. Verify navigation to correct screen

**Expected:** All flows work correctly

---

## Troubleshooting

### iOS: Notifications Not Appearing

**Check:**
1. Capabilities added in Xcode (Push Notifications + Background Modes)
2. GoogleService-Info.plist in Runner folder
3. APNs key uploaded to Firebase
4. Device not in Do Not Disturb mode

### Android: Notifications Not Appearing

**Check:**
1. google-services.json in android/app/
2. Google services plugin applied
3. POST_NOTIFICATIONS permission granted
4. Notification channels configured

### FCM Token Not Saving

**Check:**
1. User is logged in
2. profiles table has fcm_token column
3. RLS policies allow UPDATE on profiles
4. No Supabase errors in logs

### Edge Function Failing

**Check:**
1. Service account JSON in .secrets/
2. Function deployed: `supabase functions list`
3. Environment variables set
4. Function logs: `supabase functions logs send-notification`

---

## Next Steps After Implementation

1. **Add more notification types**
   - Itinerary updates
   - Checklist assignments
   - Trip reminders

2. **Implement notification settings**
   - Allow users to customize which notifications they receive
   - Add notification preferences to profile

3. **Add notification sounds**
   - Custom notification sounds for different types
   - Sound picker in settings

4. **Implement notification scheduling**
   - Trip start reminders (24 hours before)
   - Expense settlement reminders
   - Checklist due date reminders

---

## Verification Checklist

Before marking Issue #10 as complete:

- [ ] Firebase initialized in main.dart
- [ ] Permissions requested on app start
- [ ] FCM token saved to database
- [ ] Foreground notifications working
- [ ] Background notifications working
- [ ] Notification center UI functional
- [ ] Notification tap navigation working
- [ ] Mark as read functionality working
- [ ] Delete notification working
- [ ] Unread count badge showing
- [ ] Edge function deployed
- [ ] Database triggers created
- [ ] Trip invite notifications sending
- [ ] Expense notifications sending
- [ ] All tests passing
- [ ] Documentation updated

---

## Estimated Timeline

- **Phase 1:** 15 minutes
- **Phase 2:** 20 minutes
- **Phase 3:** 25 minutes
- **Phase 4:** 45 minutes
- **Phase 5:** 60 minutes
- **Phase 6:** 90 minutes
- **Phase 7:** 30 minutes

**Total:** 4-5 hours

---

**Good luck with the implementation! 🚀**

If you encounter any issues, check the troubleshooting section or refer to the official documentation:
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
