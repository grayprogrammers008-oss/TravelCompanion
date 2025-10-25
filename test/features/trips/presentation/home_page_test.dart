import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/trips/presentation/pages/home_page.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('should render empty state when no trips', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith((ref) => Stream.value(<TripWithMembers>[])),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Wait for async data to load
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No trips yet'), findsOneWidget);
      expect(find.text('Create Your First Trip'), findsOneWidget);
    });

    testWidgets('should render loading state initially', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith(
              (ref) => Stream.fromFuture(
                Future.delayed(
                  const Duration(seconds: 10),
                  () => <TripWithMembers>[],
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Assert - should show loading state
      expect(find.text('Loading your adventures...'), findsOneWidget);
    });

    testWidgets('should render trip cards when trips exist', (WidgetTester tester) async {
      // Arrange
      final testTrip = TripModel(
        id: 'test-trip-1',
        name: 'Bali Adventure',
        destination: 'Bali, Indonesia',
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 37)),
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testMember = TripMemberModel(
        id: 'member-1',
        tripId: 'test-trip-1',
        userId: 'user-1',
        role: 'admin',
        email: 'test@example.com',
        joinedAt: DateTime.now(),
      );

      final tripWithMembers = TripWithMembers(
        trip: testTrip,
        members: [testMember],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith((ref) => Stream.value([tripWithMembers])),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Wait for async data to load
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Bali Adventure'), findsOneWidget);
      expect(find.text('Bali, Indonesia'), findsOneWidget);
      expect(find.text('1 member'), findsOneWidget);
    });

    testWidgets('should show edit and delete buttons on trip cards', (WidgetTester tester) async {
      // Arrange
      final testTrip = TripModel(
        id: 'test-trip-1',
        name: 'Test Trip',
        destination: 'Test Destination',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testMember = TripMemberModel(
        id: 'member-1',
        tripId: 'test-trip-1',
        userId: 'user-1',
        role: 'admin',
        email: 'test@example.com',
        joinedAt: DateTime.now(),
      );

      final tripWithMembers = TripWithMembers(
        trip: testTrip,
        members: [testMember],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith((ref) => Stream.value([tripWithMembers])),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should have edit and delete icons
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('should handle multiple members correctly', (WidgetTester tester) async {
      // Arrange - Create trip with 5 members
      final testTrip = TripModel(
        id: 'test-trip-1',
        name: 'Group Trip',
        destination: 'Tokyo',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final members = List.generate(
        5,
        (index) => TripMemberModel(
          id: 'member-$index',
          tripId: 'test-trip-1',
          userId: 'user-$index',
          role: index == 0 ? 'admin' : 'member',
          email: 'user$index@example.com',
          joinedAt: DateTime.now(),
        ),
      );

      final tripWithMembers = TripWithMembers(
        trip: testTrip,
        members: members,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith((ref) => Stream.value([tripWithMembers])),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('5 members'), findsOneWidget);
      // Should show "+2" for overflow (showing 3 avatars + "+2")
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('should show days left badge for upcoming trips', (WidgetTester tester) async {
      // Arrange
      final testTrip = TripModel(
        id: 'test-trip-1',
        name: 'Upcoming Trip',
        destination: 'Paris',
        startDate: DateTime.now().add(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 20)),
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testMember = TripMemberModel(
        id: 'member-1',
        tripId: 'test-trip-1',
        userId: 'user-1',
        role: 'admin',
        email: 'test@example.com',
        joinedAt: DateTime.now(),
      );

      final tripWithMembers = TripWithMembers(
        trip: testTrip,
        members: [testMember],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith((ref) => Stream.value([tripWithMembers])),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - should show days left badge
      expect(find.textContaining('days left'), findsOneWidget);
    });

    testWidgets('should not crash with rendering errors', (WidgetTester tester) async {
      // This test ensures the Stack widget in member avatars has proper constraints
      final testTrip = TripModel(
        id: 'test-trip-1',
        name: 'Rendering Test',
        destination: 'Test',
        createdBy: 'user-1',
        createdAt: DateTime.now(),
      );

      final members = List.generate(
        3,
        (index) => TripMemberModel(
          id: 'member-$index',
          tripId: 'test-trip-1',
          userId: 'user-$index',
          role: 'member',
          email: 'user$index@example.com',
          joinedAt: DateTime.now(),
        ),
      );

      final tripWithMembers = TripWithMembers(
        trip: testTrip,
        members: members,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith((ref) => Stream.value([tripWithMembers])),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      // Should not throw any rendering exceptions
      await tester.pumpAndSettle();

      // Verify the widget rendered successfully
      expect(find.text('Rendering Test'), findsOneWidget);
      expect(find.text('3 members'), findsOneWidget);
    });
  });
}
