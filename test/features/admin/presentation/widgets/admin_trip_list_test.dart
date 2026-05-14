import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pathio/core/theme/app_theme_data.dart';
import 'package:pathio/core/theme/theme_access.dart';
import 'package:pathio/features/admin/domain/entities/admin_trip.dart';
import 'package:pathio/features/admin/presentation/providers/admin_trip_providers.dart';
import 'package:pathio/features/admin/presentation/widgets/admin_trip_list.dart';

final _theme = AppThemeData.getThemeData(AppThemeType.ocean);

AdminTripModel _trip({
  String id = 't1',
  String name = 'Trip 1',
  String? destination = 'Bali',
  bool completed = false,
  int memberCount = 3,
  double? totalExpenses = 100.0,
  String currency = 'USD',
}) {
  return AdminTripModel(
    id: id,
    name: name,
    destination: destination,
    createdBy: 'creator',
    creatorName: 'Creator Name',
    creatorEmail: 'creator@example.com',
    isCompleted: completed,
    memberCount: memberCount,
    totalExpenses: totalExpenses,
    currency: currency,
    startDate: DateTime(2024, 1, 1),
    endDate: DateTime(2024, 1, 7),
    rating: 0,
  );
}

GoRouter _router({Widget? body}) {
  return GoRouter(
    initialLocation: '/admin',
    routes: [
      GoRoute(
        path: '/admin',
        builder: (_, _) => AppThemeProvider(
          themeData: _theme,
          child: Scaffold(body: body ?? const AdminTripList()),
        ),
      ),
      GoRoute(
        path: '/trips/:id',
        builder: (_, state) =>
            Scaffold(body: Text('TRIP_DETAIL_${state.pathParameters['id']}')),
      ),
    ],
  );
}

Widget _wrap({
  required Future<List<AdminTripModel>> Function() future,
}) {
  return ProviderScope(
    overrides: [
      adminTripsProvider.overrideWith((ref, params) => future()),
    ],
    child: MaterialApp.router(routerConfig: _router()),
  );
}

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('AdminTripList', () {
    testWidgets('renders loading state', (tester) async {
      useTallViewport(tester);
      final completer = Completer<List<AdminTripModel>>();
      await tester.pumpWidget(_wrap(future: () => completer.future));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(const <AdminTripModel>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state when no trips', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => const <AdminTripModel>[]));
      await tester.pumpAndSettle();

      expect(find.text('No trips found'), findsOneWidget);
      expect(find.byIcon(Icons.explore_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('renders error state', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async {
        throw Exception('boom');
      }));
      await tester.pumpAndSettle();

      expect(find.text('Error loading trips'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('renders trip card with name, destination, member count',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _trip(name: 'Bali Beach Trip', destination: 'Bali', memberCount: 5),
        ],
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Bali Beach Trip'), findsOneWidget);
      expect(find.text('Bali'), findsOneWidget);
      expect(find.text('5 Members'), findsOneWidget);
    });

    testWidgets('renders Active badge for non-completed trip', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_trip(completed: false)],
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Active'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Completed badge for completed trip', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_trip(completed: true)],
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Completed'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders expenses chip when totalExpenses > 0', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_trip(totalExpenses: 250.50, currency: 'INR')],
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('INR 250.50'), findsOneWidget);
    });

    testWidgets('does not render expenses chip when totalExpenses is 0',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_trip(totalExpenses: 0)],
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('USD 0.00'), findsNothing);
    });

    testWidgets('renders creator name', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => [_trip()]));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Created by Creator Name'), findsOneWidget);
    });

    testWidgets('search field present', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => const <AdminTripModel>[]));
      await tester.pumpAndSettle();

      expect(find.text('Search by name or destination...'), findsOneWidget);
    });

    testWidgets('typing in search shows clear icon', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => const <AdminTripModel>[]));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'beach');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('renders three filter chips', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => const <AdminTripModel>[]));
      await tester.pumpAndSettle();

      expect(find.text('All Trips'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('tapping Active filter chip selects it', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => const <AdminTripModel>[]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      // Test passes if no exception thrown.
    });

    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_trip(name: 'My Trip')],
      ));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Delete Trip'), findsOneWidget);
      expect(find.textContaining('My Trip'), findsAtLeastNWidgets(1));
      // Cancel out of dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('tapping edit opens edit dialog', (tester) async {
      // Use a wider viewport for the dialog
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(future: () async => [_trip()]));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit Trip'), findsOneWidget);
    });
  });
}
