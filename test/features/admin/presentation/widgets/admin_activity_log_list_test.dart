import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/admin/data/models/admin_activity_log_model.dart';
import 'package:pathio/features/admin/domain/entities/admin_action_type.dart';
import 'package:pathio/features/admin/domain/entities/admin_activity_log.dart';
import 'package:pathio/features/admin/presentation/providers/admin_providers.dart';
import 'package:pathio/features/admin/presentation/widgets/admin_activity_log_list.dart';

AdminActivityLogModel _log({
  String id = 'l1',
  AdminActionType type = AdminActionType.userCreated,
  Map<String, dynamic>? metadata,
  String? ipAddress,
  String description = 'Action description',
}) =>
    AdminActivityLogModel(
      id: id,
      adminId: 'admin-1',
      actionType: type,
      description: description,
      metadata: metadata ?? const {},
      ipAddress: ipAddress,
      createdAt: DateTime(2024, 6, 1),
    );

Widget _wrap({
  required Future<List<AdminActivityLog>> Function() future,
}) {
  return ProviderScope(
    overrides: [
      adminActivityLogsProvider.overrideWith((ref, params) => future()),
    ],
    child: const MaterialApp(
      home: Scaffold(body: AdminActivityLogList()),
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

  group('AdminActivityLogList', () {
    testWidgets('renders loading state', (tester) async {
      useTallViewport(tester);
      final completer = Completer<List<AdminActivityLog>>();
      await tester.pumpWidget(_wrap(future: () => completer.future));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(<AdminActivityLog>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state when no logs', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => <AdminActivityLog>[]));
      await tester.pumpAndSettle();

      expect(find.text('No activity logs'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('renders error state with retry button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async {
        throw Exception('boom');
      }));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load activity logs'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button is tappable', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async {
        throw Exception('boom');
      }));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
    });

    testWidgets('renders single log card with description and date',
        (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _log(description: 'Created new user'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('User Created'), findsOneWidget);
      expect(find.text('Created new user'), findsOneWidget);
    });

    testWidgets('renders multiple log entries', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _log(id: '1', type: AdminActionType.userCreated),
          _log(id: '2', type: AdminActionType.userSuspended),
          _log(id: '3', type: AdminActionType.roleChanged),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('User Created'), findsOneWidget);
      expect(find.text('User Suspended'), findsOneWidget);
      expect(find.text('Role Changed'), findsOneWidget);
    });

    testWidgets('renders metadata block when present', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _log(metadata: const {'reason': 'spam', 'duration': '7d'}),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('reason'), findsOneWidget);
      expect(find.textContaining('spam'), findsOneWidget);
      expect(find.textContaining('duration'), findsOneWidget);
    });

    testWidgets('renders IP address when present', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _log(ipAddress: '192.168.1.1'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('192.168.1.1'), findsOneWidget);
      expect(find.byIcon(Icons.computer), findsOneWidget);
    });

    testWidgets('does not render metadata block when empty', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _log(metadata: const {}),
        ],
      ));
      await tester.pumpAndSettle();

      // No metadata key/value rendered
      expect(find.textContaining(': '), findsNothing);
    });
  });
}
