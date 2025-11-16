import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/settings/presentation/pages/profile_page.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_stats_usecase.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';

void main() {
  group('Profile Page E2E Tests - User Travel Stats', () {
    late UserTravelStats mockStats;

    setUp(() {
      mockStats = const UserTravelStats(
        totalTrips: 5,
        totalExpenses: 25,
        totalSpent: 15000.0,
        uniqueCrewMembers: 8,
      );
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          userStatsProvider.overrideWith(
            (ref) => Stream.value(mockStats),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfilePage(),
          ),
        ),
      );
    }

    testWidgets('should display user stats section', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Your Travel Stats'), findsOneWidget);
    });

    testWidgets('should display total trips count', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('5'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display total expenses count', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('should display total spent amount', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('₹15000'), findsOneWidget);
    });

    testWidgets('should display unique crew members count', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Crew Members'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('should display all stat icons', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.luggage), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      // Arrange
      final widget = ProviderScope(
        overrides: [
          userStatsProvider.overrideWith(
            (ref) => Stream.value(mockStats),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfilePage(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      // Don't settle - should show loading

      // Assert - loading indicator should be present
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

      // Now settle to verify stats are shown
      await tester.pumpAndSettle();
      expect(find.text('5'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display zero stats when user has no data', (tester) async {
      // Arrange
      final emptyStats = UserTravelStats.empty();
      final widget = ProviderScope(
        overrides: [
          userStatsProvider.overrideWith(
            (ref) => Stream.value(emptyStats),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfilePage(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('0'), findsAtLeastNWidgets(1));
      expect(find.text('₹0'), findsOneWidget);
    });

    testWidgets('should handle large numbers correctly', (tester) async {
      // Arrange
      final largeStats = const UserTravelStats(
        totalTrips: 100,
        totalExpenses: 500,
        totalSpent: 1000000.0,
        uniqueCrewMembers: 50,
      );

      final widget = ProviderScope(
        overrides: [
          userStatsProvider.overrideWith(
            (ref) => Stream.value(largeStats),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfilePage(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('100'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('₹1000000'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('should format decimal amounts correctly', (tester) async {
      // Arrange
      final decimalStats = const UserTravelStats(
        totalTrips: 3,
        totalExpenses: 12,
        totalSpent: 1234.56,
        uniqueCrewMembers: 5,
      );

      final widget = ProviderScope(
        overrides: [
          userStatsProvider.overrideWith(
            (ref) => Stream.value(decimalStats),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfilePage(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - should round to nearest integer
      expect(find.text('₹1235'), findsOneWidget);
    });

    testWidgets('should display stats in a grid layout', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - verify layout structure
      expect(find.byType(Row), findsAtLeastNWidgets(2)); // Two rows of stats
      expect(find.text('Your Travel Stats'), findsOneWidget);
    });

    testWidgets('should update stats when data changes', (tester) async {
      // Arrange
      final initialStats = const UserTravelStats(
        totalTrips: 1,
        totalExpenses: 5,
        totalSpent: 1000.0,
        uniqueCrewMembers: 2,
      );

      final updatedStats = const UserTravelStats(
        totalTrips: 2,
        totalExpenses: 10,
        totalSpent: 2500.0,
        uniqueCrewMembers: 3,
      );

      final statsController = StreamController<UserTravelStats>();

      final widget = ProviderScope(
        overrides: [
          userStatsProvider.overrideWith(
            (ref) => statsController.stream,
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfilePage(),
          ),
        ),
      );

      // Act - pump initial widget
      await tester.pumpWidget(widget);

      // Emit initial stats
      statsController.add(initialStats);
      await tester.pumpAndSettle();

      // Assert initial state
      expect(find.text('1'), findsAtLeastNWidgets(1));
      expect(find.text('₹1000'), findsOneWidget);

      // Emit updated stats
      statsController.add(updatedStats);
      await tester.pumpAndSettle();

      // Assert updated state
      expect(find.text('2'), findsAtLeastNWidgets(1));
      expect(find.text('10'), findsOneWidget);
      expect(find.text('₹2500'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Cleanup
      await statsController.close();
    });

    testWidgets('should handle error state gracefully', (tester) async {
      // Arrange
      final widget = ProviderScope(
        overrides: [
          userStatsProvider.overrideWith(
            (ref) => Stream.error(Exception('Failed to load stats')),
          ),
        ],
        child: AppThemeProvider(
          themeData: AppThemeData.getThemeData(AppThemeType.ocean),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProfilePage(),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert - should show zero stats on error
      expect(find.text('Your Travel Stats'), findsOneWidget);
      expect(find.text('0'), findsAtLeastNWidgets(1));
      expect(find.text('₹0'), findsOneWidget);
    });

    testWidgets('should have proper accessibility for stats section', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - verify all text elements are present for screen readers
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('Crew Members'), findsOneWidget);
      expect(find.text('5'), findsAtLeastNWidgets(1));
      expect(find.text('25'), findsOneWidget);
      expect(find.text('₹15000'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });
  });
}
