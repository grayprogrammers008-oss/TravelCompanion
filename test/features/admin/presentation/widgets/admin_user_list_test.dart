import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_crew/core/theme/app_theme_data.dart';
import 'package:travel_crew/core/theme/theme_access.dart';
import 'package:travel_crew/features/admin/data/models/admin_user_model.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_user.dart';
import 'package:travel_crew/features/admin/domain/entities/user_role.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';
import 'package:travel_crew/features/admin/presentation/providers/admin_providers.dart';
import 'package:travel_crew/features/admin/presentation/widgets/admin_user_list.dart';

final _theme = AppThemeData.getThemeData(AppThemeType.ocean);

AdminUserModel _user(
  String id, {
  String? fullName,
  UserRole role = UserRole.user,
  UserStatus status = UserStatus.active,
  int trips = 0,
  int messages = 0,
}) {
  return AdminUserModel(
    id: id,
    email: '$id@example.com',
    fullName: fullName ?? 'User $id',
    role: role,
    status: status,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    loginCount: 1,
    tripsCount: trips,
    messagesCount: messages,
    expensesCount: 0,
    totalExpenses: 0,
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
          child: Scaffold(body: body ?? const AdminUserList()),
        ),
      ),
      GoRoute(
        path: '/settings/admin/users/:id',
        builder: (_, state) => Scaffold(
          body: Text('USER_DETAIL_${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
}

Widget _wrap({
  required Future<List<AdminUser>> Function() future,
  Widget? body,
}) {
  return ProviderScope(
    overrides: [
      adminUsersProvider.overrideWith((ref, params) => future()),
    ],
    child: MaterialApp.router(routerConfig: _router(body: body)),
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

  group('AdminUserList', () {
    testWidgets('renders loading state', (tester) async {
      useTallViewport(tester);
      final completer = Completer<List<AdminUser>>();
      await tester.pumpWidget(_wrap(future: () => completer.future));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(const <AdminUser>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state when no users', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => const <AdminUser>[]));
      await tester.pumpAndSettle();

      expect(find.text('No users found'), findsOneWidget);
      expect(find.text('Try adjusting your filters'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('renders error state with retry button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async {
        throw Exception('boom');
      }));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load users'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders user list with name, email, role badge', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _user('a', fullName: 'Alice Adams', role: UserRole.admin),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice Adams'), findsOneWidget);
      expect(find.text('a@example.com'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('renders multiple users', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [
          _user('a', fullName: 'Alice', role: UserRole.user),
          _user('b', fullName: 'Bob', role: UserRole.superAdmin),
          _user('c', fullName: 'Carol', status: UserStatus.suspended),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
      expect(find.text('Super Admin'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);
    });

    testWidgets('renders trip and message counts on user card', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_user('a', trips: 7, messages: 12)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('search field is present', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => const <AdminUser>[]));
      await tester.pumpAndSettle();

      expect(find.text('Search by name or email...'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('typing in search shows clear button', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => const <AdminUser>[]));
      await tester.pumpAndSettle();

      final field = find.byType(TextField).first;
      await tester.enterText(field, 'alice');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Clear icon appears
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('role and status dropdowns render', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(future: () async => const <AdminUser>[]));
      await tester.pumpAndSettle();

      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      // Default selected text on empty dropdowns
      expect(find.text('All Roles'), findsOneWidget);
      expect(find.text('All Status'), findsOneWidget);
    });

    testWidgets('tapping user card navigates to detail route', (tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(_wrap(
        future: () async => [_user('xyz', fullName: 'XYZ User')],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('XYZ User'));
      await tester.pumpAndSettle();

      expect(find.text('USER_DETAIL_xyz'), findsOneWidget);
    });
  });
}
