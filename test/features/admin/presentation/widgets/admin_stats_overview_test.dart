import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/admin/data/models/admin_dashboard_stats_model.dart';
import 'package:pathio/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:pathio/features/admin/presentation/providers/admin_providers.dart';
import 'package:pathio/features/admin/presentation/widgets/admin_stats_overview.dart';

const _sampleStats = AdminDashboardStatsModel(
  totalUsers: 100,
  activeUsers: 80,
  suspendedUsers: 5,
  adminsCount: 3,
  newUsersToday: 2,
  newUsersWeek: 10,
  newUsersMonth: 30,
  totalTrips: 50,
  totalMessages: 500,
  activeUsersToday: 25,
);

Widget _data(AdminDashboardStats stats) {
  return ProviderScope(
    overrides: [
      adminDashboardStatsProvider.overrideWith((ref) async => stats),
    ],
    child: const MaterialApp(
      home: Scaffold(body: AdminStatsOverview()),
    ),
  );
}

Widget _error(Object error) {
  return ProviderScope(
    overrides: [
      adminDashboardStatsProvider.overrideWith((ref) async {
        throw error;
      }),
    ],
    child: const MaterialApp(
      home: Scaffold(body: AdminStatsOverview()),
    ),
  );
}

Widget _loadingWith(Completer<AdminDashboardStats> completer) {
  return ProviderScope(
    overrides: [
      adminDashboardStatsProvider.overrideWith((ref) => completer.future),
    ],
    child: const MaterialApp(
      home: Scaffold(body: AdminStatsOverview()),
    ),
  );
}

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('AdminStatsOverview', () {
    testWidgets('renders loading state', (tester) async {
      useTallViewport(tester);
      final completer = Completer<AdminDashboardStats>();
      await tester.pumpWidget(_loadingWith(completer));
      // Initial frame: provider in loading state.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Resolve completer to allow proper teardown without pending timers.
      completer.complete(_sampleStats);
      await tester.pumpAndSettle();
    });

    testWidgets('renders error state with retry button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_error(Exception('boom')));
      // Future-based provider: pump to allow microtask completion.
      await tester.pumpAndSettle();

      expect(find.text('Failed to load statistics'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button is tappable', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_error(Exception('boom')));
      await tester.pumpAndSettle();

      final retry = find.text('Retry');
      expect(retry, findsOneWidget);
      await tester.tap(retry);
      await tester.pumpAndSettle();
    });

    testWidgets('renders data with all stat categories', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_data(_sampleStats));
      await tester.pumpAndSettle();

      // Headers
      expect(find.text('Dashboard Overview'), findsOneWidget);
      expect(find.text('User Statistics'), findsOneWidget);
      expect(find.text('User Growth'), findsOneWidget);
      expect(find.text('Platform Activity'), findsOneWidget);
      expect(find.text('Engagement Metrics'), findsOneWidget);

      // Stat values
      expect(find.text('100'), findsOneWidget); // totalUsers
      expect(find.text('80'), findsOneWidget); // activeUsers
      expect(find.text('5'), findsOneWidget); // suspendedUsers
      expect(find.text('3'), findsOneWidget); // admins
      expect(find.text('2'), findsOneWidget); // newUsersToday
      expect(find.text('10'), findsOneWidget); // newUsersWeek
      expect(find.text('30'), findsOneWidget); // newUsersMonth
      expect(find.text('50'), findsOneWidget); // totalTrips
      expect(find.text('500'), findsOneWidget); // totalMessages
      expect(find.text('25'), findsOneWidget); // activeUsersToday
    });

    testWidgets('renders percentage card formatted', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_data(_sampleStats));
      await tester.pumpAndSettle();

      // activeUserPercentage = 80/100 * 100 = 80.0 -> "80.0%"
      expect(find.text('80.0%'), findsOneWidget);
    });

    testWidgets('renders engagement averages', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_data(_sampleStats));
      await tester.pumpAndSettle();

      // averageTripsPerUser = 50/100 = 0.50
      expect(find.text('0.50'), findsOneWidget);
      // averageMessagesPerUser = 500/100 = 5.00
      expect(find.text('5.00'), findsOneWidget);
    });

    testWidgets('renders zero values gracefully', (tester) async {
      useTallViewport(tester);
      const empty = AdminDashboardStatsModel(
        totalUsers: 0,
        activeUsers: 0,
        suspendedUsers: 0,
        adminsCount: 0,
        newUsersToday: 0,
        newUsersWeek: 0,
        newUsersMonth: 0,
        totalTrips: 0,
        totalMessages: 0,
        activeUsersToday: 0,
      );
      await tester.pumpWidget(_data(empty));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsAtLeastNWidgets(8));
      expect(find.text('0.0%'), findsOneWidget);
    });
  });
}
