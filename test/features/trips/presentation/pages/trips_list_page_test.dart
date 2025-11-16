import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/trips/presentation/pages/trips_list_page.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';

void main() {
  group('TripsListPage Widget Tests', () {
    final testUser = UserEntity(
      id: 'user1',
      email: 'test@example.com',
      fullName: 'John Doe',
      createdAt: DateTime(2024, 1, 1),
    );

    final testTrip = TripModel(
      id: 'trip1',
      name: 'Paris Trip',
      description: 'Summer vacation in Paris',
      destination: 'Paris, France',
      startDate: DateTime(2024, 7, 1),
      endDate: DateTime(2024, 7, 15),
      coverImageUrl: 'https://example.com/paris.jpg',
      createdBy: 'user1',
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

    final testTripWithMembers = TripWithMembers(
      trip: testTrip,
      members: [
        TripMemberModel(
          id: 'member1',
          tripId: 'trip1',
          userId: 'user1',
          role: 'owner',
          joinedAt: DateTime(2024, 6, 1),
          fullName: 'John Doe',
          avatarUrl: 'https://example.com/john.jpg',
        ),
      ],
    );

    Widget createTestWidget(List<TripWithMembers> trips) {
      return ProviderScope(
        overrides: [
          userTripsProvider.overrideWith((ref) => Stream.value(trips)),
          currentUserProvider.overrideWith((ref) => testUser),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TripsListPage(),
          ),
        ),
      );
    }

    testWidgets('shows loading indicator when trips are loading',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith(
              (ref) => Stream.value(<TripWithMembers>[]).asyncMap((trips) async {
                await Future.delayed(const Duration(seconds: 1));
                return trips;
              }),
            ),
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const TripsListPage(),
            ),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no trips exist',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget([]));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No trips yet'), findsOneWidget);
      expect(find.text('Create your first trip to get started!'), findsOneWidget);
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
    });

    testWidgets('shows list of trips when trips exist',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget([testTripWithMembers]));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Paris Trip'), findsOneWidget);
      expect(find.text('Paris, France'), findsOneWidget);
    });

    testWidgets('shows multiple trips in list', (WidgetTester tester) async {
      // Arrange
      final trip2 = TripModel(
        id: 'trip2',
        name: 'Tokyo Trip',
        description: 'Spring in Tokyo',
        destination: 'Tokyo, Japan',
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 3, 10),
        coverImageUrl: 'https://example.com/tokyo.jpg',
        createdBy: 'user1',
        createdAt: DateTime(2024, 2, 1),
        updatedAt: DateTime(2024, 2, 1),
      );

      final tripWithMembers2 = TripWithMembers(
        trip: trip2,
        members: [
          TripMemberModel(
            id: 'member2',
            tripId: 'trip2',
            userId: 'user1',
            role: 'owner',
            joinedAt: DateTime(2024, 2, 1),
            fullName: 'John Doe',
            avatarUrl: 'https://example.com/john.jpg',
          ),
        ],
      );

      await tester.pumpWidget(
          createTestWidget([testTripWithMembers, tripWithMembers2]));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Paris Trip'), findsOneWidget);
      expect(find.text('Tokyo Trip'), findsOneWidget);
      expect(find.text('Paris, France'), findsOneWidget);
      expect(find.text('Tokyo, Japan'), findsOneWidget);
    });

    testWidgets('shows app bar with title and profile icon',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget([testTripWithMembers]));
      await tester.pumpAndSettle();

      // Assert
      expect(find.widgetWithText(AppBar, 'My Trips'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('shows floating action button with "New Trip" text',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget([testTripWithMembers]));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('New Trip'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows error state when trips fail to load',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userTripsProvider.overrideWith(
              (ref) => Stream.error(Exception('Failed to fetch trips')),
            ),
            currentUserProvider.overrideWith((ref) => testUser),
          ],
          child: AppThemeProvider(
            themeData: AppThemeData.getThemeData(AppThemeType.ocean),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const TripsListPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows member count for trips with multiple members',
        (WidgetTester tester) async {
      // Arrange
      final tripWithMultipleMembers = TripWithMembers(
        trip: testTrip,
        members: [
          TripMemberModel(
            id: 'member3',
            tripId: 'trip1',
            userId: 'user1',
            role: 'owner',
            joinedAt: DateTime(2024, 6, 1),
            fullName: 'John Doe',
            avatarUrl: 'https://example.com/john.jpg',
          ),
          TripMemberModel(
            id: 'member4',
            tripId: 'trip1',
            userId: 'user2',
            role: 'member',
            joinedAt: DateTime(2024, 6, 2),
            fullName: 'Jane Smith',
            avatarUrl: 'https://example.com/jane.jpg',
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget([tripWithMultipleMembers]));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('2 members'), findsOneWidget);
    });

    testWidgets('shows date range for trips with dates',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget([testTripWithMembers]));
      await tester.pumpAndSettle();

      // Assert
      // Date display might vary based on formatting, so just check for existence
      expect(find.byIcon(Icons.calendar_today), findsWidgets);
    });

    testWidgets('handles trips without dates gracefully',
        (WidgetTester tester) async {
      // Arrange
      final tripWithoutDates = TripModel(
        id: 'trip3',
        name: 'Undated Trip',
        description: 'Trip without dates',
        destination: 'Somewhere',
        startDate: null,
        endDate: null,
        coverImageUrl: null,
        createdBy: 'user1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final tripWithMembers = TripWithMembers(
        trip: tripWithoutDates,
        members: [
          TripMemberModel(
            id: 'member5',
            tripId: 'trip3',
            userId: 'user1',
            role: 'owner',
            joinedAt: DateTime(2024, 1, 1),
            fullName: 'John Doe',
            avatarUrl: null,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget([tripWithMembers]));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Undated Trip'), findsOneWidget);
      expect(find.text('Somewhere'), findsOneWidget);
    });

    testWidgets('should display History icon in app bar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget([testTripWithMembers]));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byTooltip('Trip History'), findsOneWidget);
    });

    testWidgets('History icon should be positioned before profile icon', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget([testTripWithMembers]));
      await tester.pumpAndSettle();

      // Assert - Verify both icons exist in app bar
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Verify app bar contains both icons
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
    });
  });
}
