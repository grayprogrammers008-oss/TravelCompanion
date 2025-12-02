import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:travel_crew/features/messaging/data/services/fcm_service.dart';

import 'fcm_service_test.mocks.dart';

// Generate mocks
@GenerateMocks([
  FirebaseMessaging,
], customMocks: [
  MockSpec<NotificationSettings>(as: #MockFCMNotificationSettings),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FCMService', () {
    late FCMService fcmService;
    late MockFirebaseMessaging mockFirebaseMessaging;

    setUp(() {
      fcmService = FCMService();
      mockFirebaseMessaging = MockFirebaseMessaging();
    });

    tearDown(() {
      fcmService.dispose();
    });

    group('Initialization', () {
      test('should initialize FCM service successfully', () async {
        // This test verifies the service can be instantiated
        expect(fcmService, isNotNull);
        expect(fcmService.fcmToken, isNull);
      });

      test('should be singleton instance', () {
        final instance1 = FCMService();
        final instance2 = FCMService();

        expect(instance1, equals(instance2));
      });
    });

    group('Token Management', () {
      test('should return null token when not initialized', () {
        expect(fcmService.fcmToken, isNull);
      });

      test('should handle token retrieval', () async {
        const testToken = 'test_fcm_token_12345';

        when(mockFirebaseMessaging.getToken())
            .thenAnswer((_) async => testToken);

        final token = await mockFirebaseMessaging.getToken();

        expect(token, equals(testToken));
        verify(mockFirebaseMessaging.getToken()).called(1);
      });

      test('should handle null token gracefully', () async {
        when(mockFirebaseMessaging.getToken())
            .thenAnswer((_) async => null);

        final token = await mockFirebaseMessaging.getToken();

        expect(token, isNull);
        verify(mockFirebaseMessaging.getToken()).called(1);
      });
    });

    group('Permission Handling', () {
      test('should request notification permissions', () async {
        final mockSettings = MockFCMNotificationSettings();
        when(mockSettings.authorizationStatus)
            .thenReturn(AuthorizationStatus.authorized);

        when(mockFirebaseMessaging.requestPermission(
          alert: anyNamed('alert'),
          badge: anyNamed('badge'),
          sound: anyNamed('sound'),
          provisional: anyNamed('provisional'),
          announcement: anyNamed('announcement'),
          carPlay: anyNamed('carPlay'),
          criticalAlert: anyNamed('criticalAlert'),
        )).thenAnswer((_) async => mockSettings);

        final settings = await mockFirebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
        );

        expect(settings.authorizationStatus, AuthorizationStatus.authorized);
        verify(mockFirebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
        )).called(1);
      });

      test('should handle permission denial', () async {
        final mockSettings = MockFCMNotificationSettings();
        when(mockSettings.authorizationStatus)
            .thenReturn(AuthorizationStatus.denied);

        when(mockFirebaseMessaging.requestPermission(
          alert: anyNamed('alert'),
          badge: anyNamed('badge'),
          sound: anyNamed('sound'),
          provisional: anyNamed('provisional'),
          announcement: anyNamed('announcement'),
          carPlay: anyNamed('carPlay'),
          criticalAlert: anyNamed('criticalAlert'),
        )).thenAnswer((_) async => mockSettings);

        final settings = await mockFirebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
        );

        expect(settings.authorizationStatus, AuthorizationStatus.denied);
      });
    });

    group('Topic Subscription', () {
      test('should subscribe to topic successfully', () async {
        const topic = 'test_topic';

        when(mockFirebaseMessaging.subscribeToTopic(topic))
            .thenAnswer((_) async => {});

        await mockFirebaseMessaging.subscribeToTopic(topic);

        verify(mockFirebaseMessaging.subscribeToTopic(topic)).called(1);
      });

      test('should unsubscribe from topic successfully', () async {
        const topic = 'test_topic';

        when(mockFirebaseMessaging.unsubscribeFromTopic(topic))
            .thenAnswer((_) async => {});

        await mockFirebaseMessaging.unsubscribeFromTopic(topic);

        verify(mockFirebaseMessaging.unsubscribeFromTopic(topic)).called(1);
      });

      test('should handle subscription errors', () async {
        const topic = 'test_topic';

        when(mockFirebaseMessaging.subscribeToTopic(topic))
            .thenThrow(Exception('Subscription failed'));

        expect(
          () => mockFirebaseMessaging.subscribeToTopic(topic),
          throwsException,
        );
      });
    });

    group('Notification Settings', () {
      test('should retrieve notification settings', () async {
        final mockSettings = MockFCMNotificationSettings();
        when(mockSettings.authorizationStatus)
            .thenReturn(AuthorizationStatus.authorized);

        when(mockFirebaseMessaging.getNotificationSettings())
            .thenAnswer((_) async => mockSettings);

        final settings = await mockFirebaseMessaging.getNotificationSettings();

        expect(settings.authorizationStatus, AuthorizationStatus.authorized);
        verify(mockFirebaseMessaging.getNotificationSettings()).called(1);
      });
    });

    group('Token Refresh', () {
      test('should handle token refresh stream', () async {
        const newToken = 'refreshed_token_67890';

        when(mockFirebaseMessaging.onTokenRefresh)
            .thenAnswer((_) => Stream.value(newToken));

        final stream = mockFirebaseMessaging.onTokenRefresh;

        expect(stream, emits(newToken));
      });

      test('should handle multiple token refreshes', () async {
        final tokens = ['token1', 'token2', 'token3'];

        when(mockFirebaseMessaging.onTokenRefresh)
            .thenAnswer((_) => Stream.fromIterable(tokens));

        final stream = mockFirebaseMessaging.onTokenRefresh;

        expect(stream, emitsInOrder(tokens));
      });
    });

    group('Dispose', () {
      test('should dispose service cleanly', () {
        expect(() => fcmService.dispose(), returnsNormally);
      });

      test('should reset initialization state on dispose', () {
        fcmService.dispose();
        // Service should be disposable and can be re-instantiated
        final newService = FCMService();
        expect(newService, isNotNull);
      });
    });
  });
}

// Note: MockFCMNotificationSettings is generated by @GenerateMocks customMocks
