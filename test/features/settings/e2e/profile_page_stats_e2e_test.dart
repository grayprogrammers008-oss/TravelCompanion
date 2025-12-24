import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_crew/features/settings/presentation/pages/profile_page.dart';
import 'package:travel_crew/features/trips/presentation/providers/trip_providers.dart';
import 'package:travel_crew/features/trips/domain/usecases/get_user_stats_usecase.dart';
import 'package:travel_crew/features/auth/presentation/providers/auth_providers.dart';
import 'package:travel_crew/features/auth/domain/entities/user_entity.dart';
import 'package:travel_crew/features/expenses/presentation/providers/expense_providers.dart';
import 'package:travel_crew/core/theme/app_theme.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';

void main() {
  group('Profile Page E2E Tests - User Travel Stats', () {
    late UserTravelStats mockStats;
    late UserEntity mockUser;
    late ExpenseSummary mockExpenseSummary;

    setUp(() {
      mockStats = const UserTravelStats(
        totalTrips: 5,
        totalExpenses: 25,
        totalSpent: 15000.0,
        uniqueCrewMembers: 8,
      );
      mockUser = UserEntity(
        id: 'test-user-id',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      mockExpenseSummary = ExpenseSummary(
        totalPersonal: 5000.0,
        totalTrip: 10000.0,
        totalAll: 15000.0,
        personalCount: 10,
        tripCount: 15,
        categoryBreakdown: {'Food': 5000, 'Transport': 10000},
        thisMonthSpending: 3000.0,
        lastMonthSpending: 2500.0,
      );
    });

    Widget createTestWidget({UserTravelStats? stats, UserEntity? user}) {
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) async => user ?? mockUser,
          ),
          userStatsProvider.overrideWith(
            (ref) => Stream.value(stats ?? mockStats),
          ),
          expenseSummaryProvider.overrideWith(
            (ref) async => mockExpenseSummary,
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
      // Arrange - Use a completer to control when data is returned
      final userCompleter = Completer<UserEntity>();

      final widget = ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => userCompleter.future,
          ),
          userStatsProvider.overrideWith(
            (ref) => Stream.value(mockStats),
          ),
          expenseSummaryProvider.overrideWith(
            (ref) async => mockExpenseSummary,
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

      // Act - pump widget but don't settle
      await tester.pumpWidget(widget);
      await tester.pump(); // One frame to build

      // Assert - loading text should be present while waiting
      // ProfilePage uses AppLoadingIndicator which shows "Loading profile..." text
      expect(find.textContaining('Loading'), findsAtLeastNWidgets(1));

      // Complete the future and settle
      userCompleter.complete(mockUser);
      await tester.pumpAndSettle();

      // Now verify data is shown
      expect(find.text('5'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display zero stats when user has no data', (tester) async {
      // Arrange
      final emptyStats = UserTravelStats.empty();

      // Act
      await tester.pumpWidget(createTestWidget(stats: emptyStats));
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

      // Act
      await tester.pumpWidget(createTestWidget(stats: largeStats));
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

      // Act
      await tester.pumpWidget(createTestWidget(stats: decimalStats));
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
          currentUserProvider.overrideWith(
            (ref) async => mockUser,
          ),
          userStatsProvider.overrideWith(
            (ref) => statsController.stream,
          ),
          expenseSummaryProvider.overrideWith(
            (ref) async => mockExpenseSummary,
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
          currentUserProvider.overrideWith(
            (ref) async => mockUser,
          ),
          userStatsProvider.overrideWith(
            (ref) => Stream.error(Exception('Failed to load stats')),
          ),
          expenseSummaryProvider.overrideWith(
            (ref) async => mockExpenseSummary,
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
