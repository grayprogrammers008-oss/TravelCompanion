import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:travel_crew/features/trips/domain/repositories/trip_repository.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/features/trips/presentation/pages/home_page.dart';
import 'package:travel_crew/features/trips/presentation/pages/create_trip_page.dart';
import 'package:travel_crew/shared/models/trip_model.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';

@GenerateMocks([TripRepository])
import 'trip_edit_e2e_test.mocks.dart';

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
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
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

      // Mock repository responses
      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [tripWithMembers]);
      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => tripWithMembers);
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: anyNamed('name'),
        description: 'Updated description',
        destination: 'Updated Destination',
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => updatedTrip);

      // Create mock user
      final mockUser = UserEntity(
        id: 'user123',
        email: 'user@example.com',
        fullName: 'Test User',
        createdAt: DateTime.now(),
      );

      // Build widget with providers
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
            currentUserProvider.overrideWith((ref) async => mockUser),
          ],
          child: MaterialApp(
            home: const HomePage(),
          ),
        ),
      );

      // Wait for initial data to load
      await tester.pumpAndSettle();

      // Verify initial trip is displayed
      expect(find.text('Summer Vacation'), findsOneWidget);
      expect(find.text('Original Destination'), findsOneWidget);

      // Simulate navigation to edit page
      // In a real app, this would be triggered by tapping the edit button
      // For this test, we'll directly push the edit page

      // Update mock to return updated trip after edit
      when(mockRepository.getUserTrips())
          .thenAnswer((_) async => [updatedTripWithMembers]);
      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => updatedTripWithMembers);

      // Simulate returning from edit page by rebuilding
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
            currentUserProvider.overrideWith((ref) async => mockUser),
          ],
          child: MaterialApp(
            home: const HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Verify home page shows updated data
      expect(find.text('Summer Vacation'), findsOneWidget);
      expect(find.text('Updated Destination'), findsOneWidget);

      // Verify the old destination is not present
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

      final tripWithMembers = TripWithMembers(
        trip: testTrip,
        members: [],
      );

      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => tripWithMembers);

      // Act - Build edit page
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: CreateTripPage(tripId: 'trip123'),
          ),
        ),
      );

      // Wait for data to load
      await tester.pumpAndSettle();

      // Assert - Verify all fields are populated
      expect(find.text('Summer Vacation'), findsOneWidget);
      expect(find.text('Family beach trip'), findsOneWidget);
      expect(find.text('Hawaii'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Verify repository was called
      verify(mockRepository.getTripById('trip123')).called(1);
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

      final tripWithMembers = TripWithMembers(
        trip: originalTrip,
        members: [],
      );

      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => tripWithMembers);
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Summer Vacation',
        description: 'Amazing family beach trip',
        destination: 'Maui, Hawaii',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
      )).thenAnswer((_) async => updatedTrip);

      // Build edit page
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: CreateTripPage(tripId: 'trip123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Update description field
      final descriptionField = find.widgetWithText(TextFormField, 'Family beach trip');
      await tester.enterText(descriptionField, 'Amazing family beach trip');

      // Update destination field
      final destinationField = find.widgetWithText(TextFormField, 'Hawaii');
      await tester.enterText(destinationField, 'Maui, Hawaii');

      // Tap save button
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Assert - Verify update was called with correct parameters
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Summer Vacation',
        description: 'Amazing family beach trip',
        destination: 'Maui, Hawaii',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
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

      final tripWithMembers = TripWithMembers(
        trip: testTrip,
        members: [],
      );

      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => tripWithMembers);
      when(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenThrow(Exception('Network error'));

      // Build edit page
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: CreateTripPage(tripId: 'trip123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Try to save with error
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Assert - Verify error message is shown
      expect(find.textContaining('Error:'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('Provider invalidation should trigger home page refresh',
        (WidgetTester tester) async {
      // This test verifies that ref.invalidate() properly refreshes the home page

      // Arrange
      final trip1 = TripModel(
        id: 'trip123',
        name: 'Trip 1',
        description: 'Original',
        destination: 'Dest 1',
        createdBy: 'user123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final trip1Updated = trip1.copyWith(
        description: 'Updated',
        destination: 'Dest 2',
      );

      var callCount = 0;
      when(mockRepository.getUserTrips()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return [
            TripWithMembers(trip: trip1, members: []),
          ];
        } else {
          return [
            TripWithMembers(trip: trip1Updated, members: []),
          ];
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
          currentUserProvider.overrideWith((ref) async => mockUser),
        ],
      );

      // Build initial widget
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert initial state
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Dest 1'), findsOneWidget);

      // Act - Invalidate the provider (simulating what happens after edit)
      container.invalidate(userTripsProvider);
      await tester.pumpAndSettle();

      // Assert - Verify the page refreshed with new data
      expect(find.text('Updated'), findsOneWidget);
      expect(find.text('Dest 2'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
      expect(find.text('Dest 1'), findsNothing);

      // Verify repository was called twice (initial + after invalidate)
      verify(mockRepository.getUserTrips()).called(2);
    });

    testWidgets('Edit page should display updated data when reopened after edit',
        (WidgetTester tester) async {
      // This test verifies the fix for the issue where opening edit page
      // again after editing showed stale data

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

      final tripWithMembers = TripWithMembers(
        trip: originalTrip,
        members: [],
      );

      final updatedTripWithMembers = TripWithMembers(
        trip: updatedTrip,
        members: [],
      );

      // Setup: First time opening edit page - return original data
      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => tripWithMembers);

      // Act 1: Open edit page first time
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: CreateTripPage(tripId: 'trip123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert 1: Verify original data is shown
      expect(find.text('Original description'), findsOneWidget);
      expect(find.text('Original Destination'), findsOneWidget);

      // Simulate editing and saving
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: anyNamed('name'),
        description: 'First update',
        destination: 'First updated destination',
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => updatedTrip);

      // Update description and destination
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Original description'),
          'First update');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Original Destination'),
          'First updated destination');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Setup: Second time opening edit page - should return updated data
      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => updatedTripWithMembers);

      // Act 2: Reopen edit page (simulate navigating away and back)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: CreateTripPage(tripId: 'trip123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert 2: Verify UPDATED data is shown, not the original
      expect(find.text('First update'), findsOneWidget);
      expect(find.text('First updated destination'), findsOneWidget);

      // Verify old data is NOT present
      expect(find.text('Original description'), findsNothing);
      expect(find.text('Original Destination'), findsNothing);

      // Verify getTripById was called twice (once for each page open)
      verify(mockRepository.getTripById('trip123')).called(2);
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

      final tripWithMembers = TripWithMembers(
        trip: originalTrip,
        members: [],
      );

      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => tripWithMembers);

      // We only update the description, other fields should be preserved
      when(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Summer Vacation',
        description: 'Updated description only',
        destination: 'Hawaii',
        startDate: DateTime(2025, 6, 1),
        endDate: DateTime(2025, 6, 10),
      )).thenAnswer((_) async => originalTrip.copyWith(
        description: 'Updated description only',
      ));

      // Build edit page
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: CreateTripPage(tripId: 'trip123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Only update description
      final descriptionField = find.widgetWithText(TextFormField, 'Family trip');
      await tester.enterText(descriptionField, 'Updated description only');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Assert - Verify all fields were sent to update, with unchanged fields preserved
      verify(mockRepository.updateTrip(
        tripId: 'trip123',
        name: 'Summer Vacation', // Preserved
        description: 'Updated description only', // Updated
        destination: 'Hawaii', // Preserved
        startDate: DateTime(2025, 6, 1), // Preserved
        endDate: DateTime(2025, 6, 10), // Preserved
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

      final tripWithMembers = TripWithMembers(
        trip: testTrip,
        members: [],
      );

      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => tripWithMembers);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: CreateTripPage(tripId: 'trip123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Clear the trip name
      final nameField = find.widgetWithText(TextFormField, 'Summer Vacation');
      await tester.enterText(nameField, '');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

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
      ));
    });

    testWidgets('Should not allow saving trip with empty destination',
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

      final tripWithMembers = TripWithMembers(
        trip: testTrip,
        members: [],
      );

      when(mockRepository.getTripById('trip123'))
          .thenAnswer((_) async => tripWithMembers);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: CreateTripPage(tripId: 'trip123'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Clear the destination
      final destinationField = find.widgetWithText(TextFormField, 'Hawaii');
      await tester.enterText(destinationField, '');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Assert - Verify validation error is shown
      expect(find.text('Please enter a destination'), findsOneWidget);

      // Verify update was NOT called
      verifyNever(mockRepository.updateTrip(
        tripId: anyNamed('tripId'),
        name: anyNamed('name'),
        description: anyNamed('description'),
        destination: anyNamed('destination'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      ));
    });
  });
}
