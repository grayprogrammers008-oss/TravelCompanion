import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_action_type.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_activity_log.dart';

void main() {
  group('AdminActivityLog entity', () {
    final fixedDate = DateTime(2024, 1, 15, 10, 30);

    AdminActivityLog buildLog({
      DateTime? createdAt,
      Map<String, dynamic>? metadata,
      AdminActionType actionType = AdminActionType.userCreated,
    }) {
      return AdminActivityLog(
        id: 'log-1',
        adminId: 'admin-1',
        actionType: actionType,
        targetUserId: 'user-1',
        description: 'Some action',
        metadata: metadata ?? {'key': 'value'},
        ipAddress: '127.0.0.1',
        userAgent: 'TestAgent',
        createdAt: createdAt ?? fixedDate,
      );
    }

    group('formattedDate', () {
      test('returns "Just now" for very recent activity', () {
        final log = buildLog(createdAt: DateTime.now());
        expect(log.formattedDate, 'Just now');
      });

      test('returns minutes ago for activity within an hour', () {
        final log = buildLog(
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(log.formattedDate, '5m ago');
      });

      test('returns hours ago for activity within a day', () {
        final log = buildLog(
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        );
        expect(log.formattedDate, '3h ago');
      });

      test('returns days ago for activity within a week', () {
        final log = buildLog(
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        );
        expect(log.formattedDate, '4d ago');
      });

      test('returns absolute date for activity older than a week', () {
        final log = buildLog(createdAt: DateTime(2023, 6, 15));
        expect(log.formattedDate, '15/6/2023');
      });
    });

    group('getMetadata', () {
      test('returns typed value for existing key', () {
        final log = buildLog(metadata: {
          'count': 42,
          'name': 'Tester',
          'active': true,
        });
        expect(log.getMetadata<int>('count'), 42);
        expect(log.getMetadata<String>('name'), 'Tester');
        expect(log.getMetadata<bool>('active'), true);
      });

      test('returns null when key absent', () {
        final log = buildLog(metadata: {'a': 1});
        expect(log.getMetadata<int>('missing'), isNull);
      });
    });

    group('copyWith', () {
      test('returns identical entity when no fields provided', () {
        final original = buildLog();
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('updates only specified fields', () {
        final original = buildLog();
        final copy = original.copyWith(
          description: 'Updated',
          actionType: AdminActionType.userSuspended,
        );
        expect(copy.description, 'Updated');
        expect(copy.actionType, AdminActionType.userSuspended);
        expect(copy.id, original.id);
        expect(copy.adminId, original.adminId);
      });

      test('updates metadata reference', () {
        final original = buildLog(metadata: {'a': 1});
        final copy = original.copyWith(metadata: {'b': 2});
        expect(copy.metadata, {'b': 2});
      });
    });

    group('equality (Equatable)', () {
      test('two logs with same fields are equal', () {
        final a = buildLog();
        final b = buildLog();
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('logs with different ids not equal', () {
        final a = buildLog();
        final b = a.copyWith(id: 'other');
        expect(a, isNot(equals(b)));
      });

      test('props include all fields', () {
        final log = buildLog();
        expect(log.props.length, 9);
      });
    });
  });
}
