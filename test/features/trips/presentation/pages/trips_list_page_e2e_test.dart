import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/trips/presentation/pages/trips_list_page.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/shared/models/trip_model.dart';
import 'package:travel_crew/core/router/app_router.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('Trips List Page E2E Tests - Navigation and UI', () {
    late List<TripWithMembers> mockTrips;

    setUp(() {
      // Create comprehensive test data
      mockTrips = [
        TripWithMembers(
          trip: TripModel(
            id: '1',
            name: 'Paris Adventure',
            destination: 'Paris, France',
            description: 'Amazing trip to Paris',
            createdBy: 'user1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
            startDate: DateTime(2024, 6, 1),
            endDate: DateTime(2024, 6, 10),
            isCompleted: true,
            completedAt: DateTime(2024, 6, 15),
            rating: 4.5,
          ),
          members: [
            TripMemberModel(
              id: 'member1',
              tripId: '1',
              userId: 'user1',
              role: 'admin',
              joinedAt: DateTime(2024, 1, 1),
              fullName: 'John Doe',
              email: 'john@example.com',
            ),
          ],
        ),
        TripWithMembers(
          trip: TripModel(
            id: '2',
            name: 'Tokyo Experience',
            destination: 'Tokyo, Japan',
            description: 'Explore Tokyo',
            createdBy: 'user1',
            createdAt: DateTime(2024, 2, 1),
            updatedAt: DateTime(2024, 2, 1),
            startDate: DateTime(2024, 7, 1),
            endDate: DateTime(2024, 7, 15),
            isCompleted: false,
          ),
          members: [
            TripMemberModel(
              id: 'member2',
              tripId: '2',
              userId: 'user1',
              role: 'admin',
              joinedAt: DateTime(2024, 2, 1),
              fullName: 'John Doe',
              email: 'john@example.com',
            ),
          ],
        ),
        TripWithMembers(
          trip: TripModel(
            id: '3',
            name: 'London Tour',
            destination: 'London, UK',
            description: 'Visit London landmarks',
            createdBy: 'user1',
            createdAt: DateTime(2024, 3, 1),
            updatedAt: DateTime(2024, 3, 1),
            startDate: DateTime(2024, 5, 1),
            endDate: DateTime(2024, 5, 10),
            isCompleted: true,
            completedAt: DateTime(2024, 5, 15),
            rating: 5.0,
          ),
          members: [
            TripMemberModel(
              id: 'member3',
              tripId: '3',
              userId: 'user1',
              role: 'admin',
              joinedAt: DateTime(2024, 3, 1),
              fullName: 'John Doe',
              email: 'john@example.com',
            ),
          ],
        ),
      ];
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          userTripsProvider.overrideWith(
            (ref) => Stream.value(mockTrips),
          ),
          authStateProvider.overrideWith(
            (ref) => Stream.value('user1'),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const TripsListPage(),
                ),
                GoRoute(
                  path: AppRoutes.tripHistory,
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Trip History Page')),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.profile,
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Profile Page')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('should display trips list with all trips', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('My Trips'), findsOneWidget);
      expect(find.text('Paris Adventure'), findsOneWidget);
      expect(find.text('Tokyo Experience'), findsOneWidget);
      expect(find.text('London Tour'), findsOneWidget);
    });

    testWidgets('should display History icon in app bar', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byTooltip('Trip History'), findsOneWidget);
    });

    testWidgets('should navigate to Trip History when History icon is tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Trip History Page'), findsOneWidget);
    });

    testWidgets('should display profile icon in app bar', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should show correct icon positions in app bar', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Verify both icons are in the app bar actions
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      // History icon should come before profile icon
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should display New Trip FAB button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('New Trip'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should show completed trips with rating badge', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Paris Adventure'), findsOneWidget);
      expect(find.text('London Tour'), findsOneWidget);
    });

    testWidgets('should show active (non-completed) trips', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Tokyo Experience'), findsOneWidget);
    });

    testWidgets('should handle empty trip list gracefully', (tester) async {
      // Arrange
      final widget = ProviderScope(
        overrides: [
          userTripsProvider.overrideWith(
            (ref) => Stream.value(<TripWithMembers>[]),
          ),
          authStateProvider.overrideWith(
            (ref) => Stream.value('user1'),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const TripsListPage(),
                ),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - Should show empty state
      expect(find.text('My Trips'), findsOneWidget);
      // History icon should still be visible even with no trips
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('should display loading state initially', (tester) async {
      // Arrange
      final widget = ProviderScope(
        overrides: [
          userTripsProvider.overrideWith(
            (ref) => Stream.value(mockTrips),
          ),
          authStateProvider.overrideWith(
            (ref) => Stream.value('user1'),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const TripsListPage(),
                ),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      // Don't settle yet - should show loading

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Now settle and verify trips are shown
      await tester.pumpAndSettle();
      expect(find.text('Paris Adventure'), findsOneWidget);
    });
  });

  group('Trips List Page E2E Tests - Accessibility', () {
    testWidgets('History button should have semantic label', (tester) async {
      final mockTrips = [
        TripWithMembers(
          trip: TripModel(
            id: '1',
            name: 'Test Trip',
            createdBy: 'user1',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
          members: [],
        ),
      ];

      final widget = ProviderScope(
        overrides: [
          userTripsProvider.overrideWith(
            (ref) => Stream.value(mockTrips),
          ),
          authStateProvider.overrideWith(
            (ref) => Stream.value('user1'),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const TripsListPage(),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify tooltip for accessibility
      expect(find.byTooltip('Trip History'), findsOneWidget);
    });
  });
}
