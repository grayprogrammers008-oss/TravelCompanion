import 'package:flutter_test/flutter_test.dart';
import 'package:pathio/features/admin/data/models/admin_dashboard_stats_model.dart';
import 'package:pathio/features/admin/domain/entities/admin_dashboard_stats.dart';

void main() {
  group('AdminDashboardStatsModel', () {
    final tJson = {
      'total_users': 100,
      'active_users': 80,
      'suspended_users': 5,
      'admins_count': 3,
      'new_users_today': 4,
      'new_users_week': 20,
      'new_users_month': 60,
      'total_trips': 50,
      'total_messages': 500,
      'active_users_today': 30,
    };

    const tModel = AdminDashboardStatsModel(
      totalUsers: 100,
      activeUsers: 80,
      suspendedUsers: 5,
      adminsCount: 3,
      newUsersToday: 4,
      newUsersWeek: 20,
      newUsersMonth: 60,
      totalTrips: 50,
      totalMessages: 500,
      activeUsersToday: 30,
    );

    group('fromJson', () {
      test('parses all fields from JSON', () {
        final result = AdminDashboardStatsModel.fromJson(tJson);
        expect(result.totalUsers, 100);
        expect(result.activeUsers, 80);
        expect(result.suspendedUsers, 5);
        expect(result.adminsCount, 3);
        expect(result.newUsersToday, 4);
        expect(result.newUsersWeek, 20);
        expect(result.newUsersMonth, 60);
        expect(result.totalTrips, 50);
        expect(result.totalMessages, 500);
        expect(result.activeUsersToday, 30);
      });

      test('uses 0 defaults for missing fields', () {
        final result = AdminDashboardStatsModel.fromJson(<String, dynamic>{});
        expect(result.totalUsers, 0);
        expect(result.activeUsers, 0);
        expect(result.suspendedUsers, 0);
        expect(result.adminsCount, 0);
        expect(result.newUsersToday, 0);
        expect(result.newUsersWeek, 0);
        expect(result.newUsersMonth, 0);
        expect(result.totalTrips, 0);
        expect(result.totalMessages, 0);
        expect(result.activeUsersToday, 0);
      });

      test('handles explicit null values with 0', () {
        final json = <String, dynamic>{
          'total_users': null,
          'active_users': null,
          'admins_count': null,
        };
        final result = AdminDashboardStatsModel.fromJson(json);
        expect(result.totalUsers, 0);
        expect(result.activeUsers, 0);
        expect(result.adminsCount, 0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final result = tModel.toJson();
        expect(result['total_users'], 100);
        expect(result['active_users'], 80);
        expect(result['suspended_users'], 5);
        expect(result['admins_count'], 3);
        expect(result['new_users_today'], 4);
        expect(result['new_users_week'], 20);
        expect(result['new_users_month'], 60);
        expect(result['total_trips'], 50);
        expect(result['total_messages'], 500);
        expect(result['active_users_today'], 30);
      });
    });

    group('toEntity', () {
      test('returns AdminDashboardStats with same values', () {
        final entity = tModel.toEntity();
        expect(entity, isA<AdminDashboardStats>());
        expect(entity.totalUsers, 100);
        expect(entity.activeUsers, 80);
        expect(entity.totalTrips, 50);
      });

      test('entity has same numeric values as original model', () {
        final entity = tModel.toEntity();
        expect(entity.totalUsers, tModel.totalUsers);
        expect(entity.activeUsers, tModel.activeUsers);
        expect(entity.suspendedUsers, tModel.suspendedUsers);
        expect(entity.adminsCount, tModel.adminsCount);
        expect(entity.totalTrips, tModel.totalTrips);
        expect(entity.totalMessages, tModel.totalMessages);
      });
    });

    group('fromEntity', () {
      test('creates model from entity', () {
        const entity = AdminDashboardStats(
          totalUsers: 5,
          activeUsers: 4,
          suspendedUsers: 1,
          adminsCount: 1,
          newUsersToday: 0,
          newUsersWeek: 0,
          newUsersMonth: 0,
          totalTrips: 2,
          totalMessages: 10,
          activeUsersToday: 1,
        );
        final model = AdminDashboardStatsModel.fromEntity(entity);
        expect(model, isA<AdminDashboardStatsModel>());
        expect(model.totalUsers, 5);
        expect(model.totalMessages, 10);
      });
    });

    group('round trip', () {
      test('JSON round trip preserves values', () {
        final json = tModel.toJson();
        final restored = AdminDashboardStatsModel.fromJson(json);
        expect(restored.totalUsers, tModel.totalUsers);
        expect(restored.activeUsers, tModel.activeUsers);
        expect(restored.suspendedUsers, tModel.suspendedUsers);
        expect(restored.adminsCount, tModel.adminsCount);
        expect(restored.totalTrips, tModel.totalTrips);
        expect(restored.totalMessages, tModel.totalMessages);
        expect(restored.activeUsersToday, tModel.activeUsersToday);
      });

      test('entity round trip preserves values', () {
        final entity = tModel.toEntity();
        final restored = AdminDashboardStatsModel.fromEntity(entity);
        expect(restored.totalUsers, tModel.totalUsers);
        expect(restored.activeUsers, tModel.activeUsers);
        expect(restored.totalTrips, tModel.totalTrips);
      });
    });
  });
}
