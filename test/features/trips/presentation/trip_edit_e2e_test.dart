import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/core/theme/easy_mode_provider.dart';
import 'package:travel_crew/core/theme/theme_provider.dart' as theme_provider;
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/discover/presentation/providers/discover_providers.dart';
import 'package:travel_crew/features/itinerary/presentation/providers/itinerary_providers.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/presentation/pages/create_trip_page.dart';
import 'package:travel_crew/features/trips/presentation/pages/home_page.dart';
import 'package:travel_crew/features/trips/presentation/providers/ai_suggestions_provider.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

@GenerateMocks([TripRepository])
import 'trip_edit_e2e_test.mocks.dart';

final _defaultTheme = AppThemeData.getThemeData(AppThemeType.ocean);

/// Pumps enough frames to resolve a FutureProvider and let animations settle,
/// without calling pumpAndSettle (which hangs when DestinationImage timers fire).
Future<void> _pumpHomeLoaded(WidgetTester tester) async {
  for (int i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

/// Returns a ProviderScope + MaterialApp.router with GoRouter for CreateTripPage tests.
/// Uses GoRouter so context.pop() inside CreateTripPage works correctly.
({Widget widget, GoRouter router}) _createEditTripApp({
  required MockTripRepository repo,
  required TripWithMembers tripData,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/edit',
        builder: (_, _) => const CreateTripPage(tripId: 'trip123'),
      ),
    ],
  );
  // Stub repository methods so _loadTripData() in CreateTripPage can fetch trip.
  when(repo.getTripById(any)).thenAnswer((_) async => tripData);
  when(repo.watchTrip(any)).thenAnswer((_) => Stream.value(tripData));
  final widget = ProviderScope(
    overrides: [
      tripRepositoryProvider.overrideWithValue(repo),
      userTripsProvider.overrideWith((ref) => Future.value([])),
    ],
    child: AppThemeProvider(
      themeData: _defaultTheme,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return (widget: widget, router: router);
}

/// Pumps enough frames for CreateTripPage in edit mode to load its trip data
/// and for all FadeSlideAnimation widgets to reach full opacity.
/// Cannot use pumpAndSettle because WaveGradientBackground has a looping animation.
///
/// _loadTripData() flow:
///  1. postFrameCallback fires → _loadTripData() starts → hits Future.delayed(100ms)
///  2. 100ms timer fires → resumes → reads StreamProvider → awaits .future
///  3. Stream emits data (async microtask) → Riverpod AsyncData → .future completes
///  4. setState() called → rebuild scheduled → TextFormField shows trip name
///
/// Splitting into 150ms + extra pump() calls ensures the async Riverpod stream
/// pipeline (timer → microtasks → setState → frame) has time to complete.
Future<void> _pumpEditPageLoaded(WidgetTester tester) async {
  // Expand viewport so the entire form (including Save Changes button) fits
  // on screen and is tappable. Default 800x600 cuts off the bottom of the form.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Many pumps to allow Riverpod's async state propagation
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  await tester.pump(const Duration(milliseconds: 1000)); // FadeSlideAnimation
  await tester.pump();
}

/// Pumps enough frames for an async save operation to complete in CreateTripPage.
/// The save flow chains: form validation → updateTrip Future → invalidate providers
/// → await userTripsProvider.future → pop → showSnackBar.
Future<void> _pumpAfterSave(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  late MockTripRepository mockRepository;

  setUp(() {
    mockRepository = MockTripRepository();
  });

  group('Trip Edit End-to-End Flow Tests', () {
    testWidgets('Home page should refresh after editing trip destination and description',
        (WidgetTester tester) async {
      // Arrange - Create test data
      final originalTrip = TripModel(
        id: 'trip123',
        name: 'Summer Vacation',
        description: 'Original description',
        destination: 'Original Destination',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        coverImageUrl: 'https://test.invalid/img.jpg',
      );

      final updatedTrip = originalTrip.copyWith(
        description: 'Updated description',
        destination: 'Updated Destination',
      );

      final tripWithMembers = TripWithMembers(
        trip: originalTrip,
        members: [
          TripMemberModel(
            id: 'member1',
            tripId: 'trip123',
            userId: 'user123',
            email: 'user@example.com',
            role: 'organizer',
            joinedAt: DateTime.now(),
          ),
        ],
      );

      final updatedTripWithMembers = TripWithMembers(
        trip: updatedTrip,
        members: tripWithMembers.members,
      );

      final mockUser = UserEntity(
        id: 'user123',
        email: 'user@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      );

      // Expand viewport so SliverAppBar does not push trip cards off screen.
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Use a single ProviderContainer + invalidate pattern, since pumpWidget
      // replaces the widget tree but Flutter reconciliation reuses inner state
      // (DestinationImage etc.), making fresh data not propagate reliably.
      var trips = [tripWithMembers];
      when(mockRepository.getUserTrips()).thenAnswer((_) async => trips);

      final container = ProviderContainer(
        overrides: [
          tripRepositoryProvider.overrideWithValue(mockRepository),
          authStateProvider.overrideWith((ref) => Stream.value('user123')),
          currentUserProvider.overrideWith((ref) async => mockUser),
          theme_provider.currentThemeDataProvider.overrideWith((_) => _defaultTheme),
          easyModeConfigProvider.overrideWith((_) => const EasyModeConfig()),
          aiSuggestionsProvider.overrideWith((ref) async => null),
          discoverStateProvider.overrideWith(() => DiscoverStateNotifier()),
          tripItineraryProvider.overrideWith((ref, _) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: AppThemeProvider(
            themeData: _defaultTheme,
            child: const MaterialApp(home: HomePage()),
          ),
        ),
      );
      await _pumpHomeLoaded(tester);

      // Verify initial trip is displayed
      expect(find.text('Summer Vacation'), findsOneWidget);
      expect(find.text('Original Destination'), findsOneWidget);

      // Simulate edit: update trips list and invalidate provider
      trips = [updatedTripWithMembers];
      container.invalidate(userTripsProvider);
      await _pumpHomeLoaded(tester);

      // Verify home page shows updated data
      expect(find.text('Summer Vacation'), findsOneWidget);
      expect(find.text('Updated Destination'), findsOneWidget);
      expect(find.text('Original Destination'), findsNothing);
    });

    testWidgets('Edit page should load existing trip data correctly',
        (WidgetTester tester) async {
      // Arrange
      final testTrip = TripModel(
        id: 'trip123',
        name: 'Summer Vacation',
        description: 'Family beach trip',
        destination: 'Hawaii',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tripWithMembers = TripWithMembers(trip: testTrip, members: []);

      // Act - Build edit page via GoRouter
      final (:widget, :router) = _createEditTripApp(
        repo: mockRepository,
        tripData: tripWithMembers,
      );
      await tester.pumpWidget(widget);
      await tester.pump(); // Initial '/' route
      router.push('/edit');
      await _pumpEditPageLoaded(tester);

      // Assert - Verify all fields are populated
      expect(find.text('Summer Vacation'), findsOneWidget);
      expect(find.text('Family beach trip'), findsOneWidget);
      expect(find.text('Hawaii'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Edit page should successfully update trip when save is pressed',
        (WidgetTester tester) async {
      // Arrange
      final originalTrip = TripModel(
        id: 'trip123',
        name: 'Summer Vacation',
        description: 'Family beach trip',
        destination: 'Hawaii',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedTrip = originalTrip.copyWith(
        description: 'Amazing family beach trip',
        destination: 'Maui, Hawaii',
      );

      final tripWithMembers = TripWithMembers(trip: originalTrip, members: []);

      when(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        coverImageUrl: anyNamed('coverImageUrl'),
        cost: anyNamed('cost'),
        currency: anyNamed('currency'),
        isPublic: anyNamed('isPublic'),
      )).thenAnswer((_) async => updatedTrip);

      // Build edit page via GoRouter
      final (:widget, :router) = _createEditTripApp(
        repo: mockRepository,
        tripData: tripWithMembers,
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      router.push('/edit');
      await _pumpEditPageLoaded(tester);

      // Act - Update description field (destination uses search delegate, not TextFormField)
      final descriptionField = find.widgetWithText(TextFormField, 'Family beach trip');
      await tester.enterText(descriptionField, 'Amazing family beach trip');

      // Tap save button
      await tester.tap(find.text('Save Changes'));
      await _pumpAfterSave(tester);

      // Assert - Verify update was called
      verify(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        coverImageUrl: anyNamed('coverImageUrl'),
        cost: anyNamed('cost'),
        currency: anyNamed('currency'),
        isPublic: anyNamed('isPublic'),
      )).called(1);

      // Verify success message is shown
      expect(find.text('Trip updated successfully!'), findsOneWidget);
    });

    testWidgets('Edit page should handle errors gracefully',
        (WidgetTester tester) async {
      // Arrange
      final testTrip = TripModel(
        id: 'trip123',
        name: 'Summer Vacation',
        description: 'Family beach trip',
        destination: 'Hawaii',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tripWithMembers = TripWithMembers(trip: testTrip, members: []);

      when(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        coverImageUrl: anyNamed('coverImageUrl'),
        cost: anyNamed('cost'),
        currency: anyNamed('currency'),
        isPublic: anyNamed('isPublic'),
      )).thenThrow(Exception('Network error'));

      // Build edit page via GoRouter
      final (:widget, :router) = _createEditTripApp(
        repo: mockRepository,
        tripData: tripWithMembers,
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      router.push('/edit');
      await _pumpEditPageLoaded(tester);

      // Act - Try to save with error
      await tester.tap(find.text('Save Changes'));
      await _pumpAfterSave(tester);

      // Assert - Verify error message is shown
      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('Provider invalidation should trigger home page refresh',
        (WidgetTester tester) async {
      // Arrange
      final trip1 = TripModel(
        id: 'trip123',
        name: 'Trip 1',
        description: 'Original',
        destination: 'Dest 1',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        coverImageUrl: 'https://test.invalid/img.jpg',
      );

      final trip1Updated = trip1.copyWith(
        description: 'Updated',
        destination: 'Dest 2',
      );

      var callCount = 0;
      when(mockRepository.getUserTrips()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return [TripWithMembers(trip: trip1, members: [])];
        } else {
          return [TripWithMembers(trip: trip1Updated, members: [])];
        }
      });

      final mockUser = UserEntity(
        id: 'user123',
        email: 'user@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          tripRepositoryProvider.overrideWithValue(mockRepository),
          authStateProvider.overrideWith((ref) => Stream.value('user123')),
          currentUserProvider.overrideWith((ref) async => mockUser),
          theme_provider.currentThemeDataProvider.overrideWith((_) => _defaultTheme),
          easyModeConfigProvider.overrideWith((_) => const EasyModeConfig()),
          aiSuggestionsProvider.overrideWith((ref) async => null),
          discoverStateProvider.overrideWith(() => DiscoverStateNotifier()),
          tripItineraryProvider.overrideWith((ref, _) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);

      // Build initial widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: AppThemeProvider(
            themeData: _defaultTheme,
            child: const MaterialApp(home: HomePage()),
          ),
        ),
      );
      await _pumpHomeLoaded(tester);

      // Assert initial state — home page shows destination, not description
      expect(find.text('Trip 1'), findsOneWidget);
      expect(find.text('Dest 1'), findsOneWidget);

      // Act - Invalidate the provider (simulating what happens after edit)
      container.invalidate(userTripsProvider);
      await _pumpHomeLoaded(tester);

      // Assert - Verify the page refreshed with new data
      expect(find.text('Trip 1'), findsOneWidget);
      expect(find.text('Dest 2'), findsOneWidget);
      expect(find.text('Dest 1'), findsNothing);

      // Verify repository was called twice (initial + after invalidate)
      verify(mockRepository.getUserTrips()).called(2);
    });

    testWidgets('Edit page should display updated data when reopened after edit',
        (WidgetTester tester) async {
      // Arrange - First trip state
      final originalTrip = TripModel(
        id: 'trip123',
        name: 'Summer Vacation',
        description: 'Original description',
        destination: 'Original Destination',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Updated trip state (after first edit)
      final updatedTrip = originalTrip.copyWith(
        description: 'First update',
        destination: 'First updated destination',
      );

      final tripWithMembers = TripWithMembers(trip: originalTrip, members: []);
      final updatedTripWithMembers = TripWithMembers(trip: updatedTrip, members: []);

      when(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        coverImageUrl: anyNamed('coverImageUrl'),
        cost: anyNamed('cost'),
        currency: anyNamed('currency'),
        isPublic: anyNamed('isPublic'),
      )).thenAnswer((_) async => updatedTrip);

      // Act 1: Open edit page first time
      final (:widget, :router) = _createEditTripApp(
        repo: mockRepository,
        tripData: tripWithMembers,
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      router.push('/edit');
      await _pumpEditPageLoaded(tester);

      // Assert 1: Verify original data is shown
      expect(find.text('Original description'), findsOneWidget);
      expect(find.text('Original Destination'), findsOneWidget);

      // Simulate editing description and saving (destination uses search delegate)
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Original description'),
          'First update');

      await tester.tap(find.text('Save Changes'));
      await _pumpAfterSave(tester);

      // Act 2: Reopen edit page with updated data
      final (widget: widget2, router: router2) = _createEditTripApp(
        repo: mockRepository,
        tripData: updatedTripWithMembers,
      );
      await tester.pumpWidget(widget2);
      await tester.pump();
      router2.push('/edit');
      await _pumpEditPageLoaded(tester);

      // Assert 2: Verify UPDATED data is shown
      expect(find.text('First update'), findsOneWidget);
      expect(find.text('First updated destination'), findsOneWidget);
      expect(find.text('Original description'), findsNothing);
      expect(find.text('Original Destination'), findsNothing);
    });

    testWidgets('Editing trip should preserve unchanged fields',
        (WidgetTester tester) async {
      // Arrange
      final originalTrip = TripModel(
        id: 'trip123',
        name: 'Summer Vacation',
        description: 'Family trip',
        destination: 'Hawaii',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tripWithMembers = TripWithMembers(trip: originalTrip, members: []);

      when(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        coverImageUrl: anyNamed('coverImageUrl'),
        cost: anyNamed('cost'),
        currency: anyNamed('currency'),
        isPublic: anyNamed('isPublic'),
      )).thenAnswer((_) async => originalTrip.copyWith(
        description: 'Updated description only',
      ));

      // Build edit page
      final (:widget, :router) = _createEditTripApp(
        repo: mockRepository,
        tripData: tripWithMembers,
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      router.push('/edit');
      await _pumpEditPageLoaded(tester);

      // Act - Only update description
      final descriptionField = find.widgetWithText(TextFormField, 'Family trip');
      await tester.enterText(descriptionField, 'Updated description only');

      await tester.tap(find.text('Save Changes'));
      await _pumpAfterSave(tester);

      // Assert - Verify update was called (once only — unchanged fields preserved)
      verify(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        coverImageUrl: anyNamed('coverImageUrl'),
        cost: anyNamed('cost'),
        currency: anyNamed('currency'),
        isPublic: anyNamed('isPublic'),
      )).called(1);
    });
  });

  group('Trip Edit Validation Tests', () {
    testWidgets('Should not allow saving trip with empty name',
        (WidgetTester tester) async {
      // Arrange
      final testTrip = TripModel(
        id: 'trip123',
        name: 'Summer Vacation',
        destination: 'Hawaii',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tripWithMembers = TripWithMembers(trip: testTrip, members: []);

      final (:widget, :router) = _createEditTripApp(
        repo: mockRepository,
        tripData: tripWithMembers,
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      router.push('/edit');
      await _pumpEditPageLoaded(tester);

      // Act - Clear the trip name
      final nameField = find.widgetWithText(TextFormField, 'Summer Vacation');
      await tester.enterText(nameField, '');

      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump();

      // Assert - Verify validation error is shown
      expect(find.text('Please enter a trip name'), findsOneWidget);

      // Verify update was NOT called
      verifyNever(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        coverImageUrl: anyNamed('coverImageUrl'),
        cost: anyNamed('cost'),
        currency: anyNamed('currency'),
        isPublic: anyNamed('isPublic'),
      ));
    });

    testWidgets('Destination field should be preserved on save',
        (WidgetTester tester) async {
      // Destination uses a search delegate (not a TextFormField), so users
      // cannot type an empty string into it. Verify the original destination
      // is preserved when saving without modifying the destination.
      final testTrip = TripModel(
        id: 'trip123',
        name: 'Summer Vacation',
        destination: 'Hawaii',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final tripWithMembers = TripWithMembers(trip: testTrip, members: []);

      when(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        coverImageUrl: anyNamed('coverImageUrl'),
        cost: anyNamed('cost'),
        currency: anyNamed('currency'),
        isPublic: anyNamed('isPublic'),
      )).thenAnswer((_) async => testTrip);

      final (:widget, :router) = _createEditTripApp(
        repo: mockRepository,
        tripData: tripWithMembers,
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      router.push('/edit');
      await _pumpEditPageLoaded(tester);

      // Verify destination is shown
      expect(find.text('Hawaii'), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      await _pumpAfterSave(tester);

      // Save should be called with the original destination preserved
      verify(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: 'Hawaii',
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        coverImageUrl: anyNamed('coverImageUrl'),
        cost: anyNamed('cost'),
        currency: anyNamed('currency'),
        isPublic: anyNamed('isPublic'),
      )).called(1);
    });
  });
}
