import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travel_crew/features/emergency/presentation/providers/emergency_providers.dart';
import 'package:travel_crew/features/emergency/presentation/widgets/location_sharing_widget.dart';
import 'package:travel_crew/shared/models/location_share_model.dart';

// Mock classes
class MockEmergencyController extends Mock implements EmergencyController {}

void main() {
  group('LocationSharingWidget', () {
    late MockEmergencyController mockController;

    setUp(() {
      mockController = MockEmergencyController();
    });

    Widget createWidgetUnderTest({
      required AsyncValue<LocationShareModel?> locationShareValue,
    }) {
      return ProviderScope(
        overrides: [
          activeLocationShareProvider.overrideWith(
            (ref) => Future.value(locationShareValue.value),
          ),
          emergencyControllerProvider.overrideWith(() => mockController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: LocationSharingWidget(),
          ),
        ),
      );
    }

    group('Loading State', () {
      testWidgets('displays loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: const AsyncValue.loading(),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading location sharing status...'), findsOneWidget);
      });
    });

    group('Error State', () {
      testWidgets('displays error message when error occurs', (tester) async {
        const errorMessage = 'Failed to load location share';

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeLocationShareProvider.overrideWith(
                (ref) => throw Exception(errorMessage),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: LocationSharingWidget(),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Error Loading Location Share'), findsOneWidget);
        expect(find.textContaining(errorMessage), findsOneWidget);
      });
    });

    group('No Active Share State', () {
      testWidgets('displays no active share message when null', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: const AsyncValue.data(null),
          ),
        );

        expect(find.byIcon(Icons.location_off), findsOneWidget);
        expect(find.text('Not Sharing Location'), findsOneWidget);
        expect(
          find.text('You are not currently sharing your location with anyone.'),
          findsOneWidget,
        );
      });
    });

    group('Active Share State', () {
      late LocationShareModel mockLocationShare;

      setUp(() {
        mockLocationShare = LocationShareModel(
          id: 'test-id',
          userId: 'user-123',
          tripId: 'trip-456',
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 10.5,
          speed: 5.5, // ~20 km/h
          status: LocationShareStatus.active,
          startedAt: DateTime.now().subtract(const Duration(hours: 1)),
          lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          sharedWithContactIds: ['contact-1', 'contact-2', 'contact-3'],
          message: 'Emergency location sharing activated',
        );
      });

      testWidgets('displays active share details correctly', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(mockLocationShare),
          ),
        );

        // Check header
        expect(find.text('Sharing Location'), findsOneWidget);
        expect(find.text('Your real-time location is being shared'), findsOneWidget);

        // Check location details
        expect(find.text('Location Details'), findsOneWidget);
        expect(find.textContaining('40.712800'), findsOneWidget);
        expect(find.textContaining('-74.006000'), findsOneWidget);

        // Check accuracy
        expect(find.textContaining('±10.5m'), findsOneWidget);

        // Check speed (converted to km/h)
        expect(find.textContaining('19.8 km/h'), findsOneWidget);

        // Check sharing details
        expect(find.text('Sharing With'), findsOneWidget);
        expect(find.text('3 people'), findsOneWidget);

        // Check message
        expect(find.text('Emergency location sharing activated'), findsOneWidget);

        // Check stop button
        expect(find.text('Stop Sharing Location'), findsOneWidget);
      });

      testWidgets('displays last update time correctly', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(mockLocationShare),
          ),
        );

        expect(find.textContaining('5 minutes ago'), findsOneWidget);
      });

      testWidgets('handles location share without optional fields', (tester) async {
        final minimalShare = LocationShareModel(
          id: 'test-id',
          userId: 'user-123',
          latitude: 40.7128,
          longitude: -74.0060,
          status: LocationShareStatus.active,
          startedAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
          sharedWithContactIds: ['contact-1'],
        );

        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(minimalShare),
          ),
        );

        // Should not show accuracy if null
        expect(find.textContaining('±'), findsNothing);

        // Should not show speed if null or 0
        expect(find.textContaining('km/h'), findsNothing);

        // Should not show message if null
        expect(find.textContaining('message'), findsNothing, skip: true);
      });

      testWidgets('shows stop sharing dialog when button is tapped', (tester) async {
        when(() => mockController.stopLocationSharing(any()))
            .thenAnswer((_) async => {});

        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(mockLocationShare),
          ),
        );

        // Tap stop button
        await tester.tap(find.text('Stop Sharing Location'));
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(find.text('Stop Sharing Location'), findsNWidgets(2)); // Button + Dialog
        expect(
          find.text('Are you sure you want to stop sharing your location?'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Stop Sharing'), findsOneWidget);
      });

      testWidgets('calls stop location sharing when confirmed', (tester) async {
        when(() => mockController.stopLocationSharing(mockLocationShare.id))
            .thenAnswer((_) async => {});

        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(mockLocationShare),
          ),
        );

        // Tap stop button
        await tester.tap(find.text('Stop Sharing Location'));
        await tester.pumpAndSettle();

        // Confirm in dialog
        await tester.tap(find.text('Stop Sharing'));
        await tester.pumpAndSettle();

        // Verify controller method was called
        verify(() => mockController.stopLocationSharing(mockLocationShare.id))
            .called(1);
      });

      testWidgets('does not call stop location sharing when cancelled', (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(mockLocationShare),
          ),
        );

        // Tap stop button
        await tester.tap(find.text('Stop Sharing Location'));
        await tester.pumpAndSettle();

        // Cancel in dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify controller method was NOT called
        verifyNever(() => mockController.stopLocationSharing(any()));
      });

      testWidgets('shows success snackbar when stop succeeds', (tester) async {
        when(() => mockController.stopLocationSharing(mockLocationShare.id))
            .thenAnswer((_) async => {});

        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(mockLocationShare),
          ),
        );

        // Tap stop button and confirm
        await tester.tap(find.text('Stop Sharing Location'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Stop Sharing'));
        await tester.pumpAndSettle();

        // Should show success message
        expect(find.text('Location sharing stopped successfully'), findsOneWidget);
      });

      testWidgets('shows error snackbar when stop fails', (tester) async {
        when(() => mockController.stopLocationSharing(mockLocationShare.id))
            .thenThrow(Exception('Network error'));

        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(mockLocationShare),
          ),
        );

        // Tap stop button and confirm
        await tester.tap(find.text('Stop Sharing Location'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Stop Sharing'));
        await tester.pumpAndSettle();

        // Should show error message
        expect(find.textContaining('Failed to stop sharing'), findsOneWidget);
      });
    });

    group('Time Formatting', () {
      testWidgets('formats seconds correctly', (tester) async {
        final share = LocationShareModel(
          id: 'test-id',
          userId: 'user-123',
          latitude: 40.7128,
          longitude: -74.0060,
          status: LocationShareStatus.active,
          startedAt: DateTime.now(),
          lastUpdatedAt: DateTime.now().subtract(const Duration(seconds: 30)),
          sharedWithContactIds: ['contact-1'],
        );

        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(share),
          ),
        );

        expect(find.textContaining('30 seconds ago'), findsOneWidget);
      });

      testWidgets('formats minutes correctly', (tester) async {
        final share = LocationShareModel(
          id: 'test-id',
          userId: 'user-123',
          latitude: 40.7128,
          longitude: -74.0060,
          status: LocationShareStatus.active,
          startedAt: DateTime.now(),
          lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
          sharedWithContactIds: ['contact-1'],
        );

        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(share),
          ),
        );

        expect(find.textContaining('15 minutes ago'), findsOneWidget);
      });

      testWidgets('formats hours correctly', (tester) async {
        final share = LocationShareModel(
          id: 'test-id',
          userId: 'user-123',
          latitude: 40.7128,
          longitude: -74.0060,
          status: LocationShareStatus.active,
          startedAt: DateTime.now(),
          lastUpdatedAt: DateTime.now().subtract(const Duration(hours: 3)),
          sharedWithContactIds: ['contact-1'],
        );

        await tester.pumpWidget(
          createWidgetUnderTest(
            locationShareValue: AsyncValue.data(share),
          ),
        );

        expect(find.textContaining('3 hours ago'), findsOneWidget);
      });
    });
  });
}
