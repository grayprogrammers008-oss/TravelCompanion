import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/data/models/admin_activity_log_model.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_activity_log.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_action_type.dart';

void main() {
  group('AdminActivityLogModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30);

    group('constructor', () {
      test('should create instance with required fields', () {
        final log = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userCreated,
          description: 'Created user account',
          metadata: {},
          createdAt: testDate,
        );

        expect(log.id, 'log-1');
        expect(log.adminId, 'admin-1');
        expect(log.actionType, AdminActionType.userCreated);
        expect(log.description, 'Created user account');
        expect(log.metadata, isEmpty);
        expect(log.createdAt, testDate);
        expect(log.targetUserId, isNull);
        expect(log.ipAddress, isNull);
        expect(log.userAgent, isNull);
      });

      test('should create instance with all fields', () {
        final metadata = {'old_role': 'user', 'new_role': 'admin'};

        final log = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.roleChanged,
          targetUserId: 'user-123',
          description: 'Changed user role from user to admin',
          metadata: metadata,
          ipAddress: '192.168.1.1',
          userAgent: 'Mozilla/5.0',
          createdAt: testDate,
        );

        expect(log.targetUserId, 'user-123');
        expect(log.ipAddress, '192.168.1.1');
        expect(log.userAgent, 'Mozilla/5.0');
        expect(log.metadata['old_role'], 'user');
        expect(log.metadata['new_role'], 'admin');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'log-1',
          'admin_id': 'admin-1',
          'action_type': 'user_created',
          'target_user_id': 'user-123',
          'description': 'Created user account',
          'metadata': {'email': 'test@example.com'},
          'ip_address': '192.168.1.1',
          'user_agent': 'Mozilla/5.0',
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final log = AdminActivityLogModel.fromJson(json);

        expect(log.id, 'log-1');
        expect(log.adminId, 'admin-1');
        expect(log.actionType, AdminActionType.userCreated);
        expect(log.targetUserId, 'user-123');
        expect(log.description, 'Created user account');
        expect(log.metadata['email'], 'test@example.com');
        expect(log.ipAddress, '192.168.1.1');
        expect(log.userAgent, 'Mozilla/5.0');
      });

      test('should parse all action types', () {
        final actionTypes = [
          'user_created',
          'user_updated',
          'user_suspended',
          'user_activated',
          'user_deleted',
          'role_changed',
          'password_reset',
          'profile_updated',
        ];

        for (final actionType in actionTypes) {
          final json = {
            'id': 'log-1',
            'admin_id': 'admin-1',
            'action_type': actionType,
            'description': 'Test action',
            'metadata': {},
            'created_at': '2024-01-15T10:30:00.000Z',
          };

          final log = AdminActivityLogModel.fromJson(json);
          expect(log.actionType.value, actionType);
        }
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'log-1',
          'admin_id': 'admin-1',
          'action_type': 'user_created',
          'description': 'Test action',
          'metadata': null,
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final log = AdminActivityLogModel.fromJson(json);

        expect(log.targetUserId, isNull);
        expect(log.ipAddress, isNull);
        expect(log.userAgent, isNull);
        expect(log.metadata, isEmpty);
      });

      test('should default to userUpdated for unknown action type', () {
        final json = {
          'id': 'log-1',
          'admin_id': 'admin-1',
          'action_type': 'unknown_action',
          'description': 'Test action',
          'metadata': {},
          'created_at': '2024-01-15T10:30:00.000Z',
        };

        final log = AdminActivityLogModel.fromJson(json);
        expect(log.actionType, AdminActionType.userUpdated);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final log = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.roleChanged,
          targetUserId: 'user-123',
          description: 'Changed user role',
          metadata: {'old_role': 'user', 'new_role': 'admin'},
          ipAddress: '192.168.1.1',
          userAgent: 'Mozilla/5.0',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
        );

        final json = log.toJson();

        expect(json['id'], 'log-1');
        expect(json['admin_id'], 'admin-1');
        expect(json['action_type'], 'role_changed');
        expect(json['target_user_id'], 'user-123');
        expect(json['description'], 'Changed user role');
        expect(json['metadata']['old_role'], 'user');
        expect(json['ip_address'], '192.168.1.1');
        expect(json['user_agent'], 'Mozilla/5.0');
        expect(json['created_at'], '2024-01-15T10:30:00.000Z');
      });

      test('should handle null optional fields', () {
        final log = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userCreated,
          description: 'Test action',
          metadata: {},
          createdAt: testDate,
        );

        final json = log.toJson();

        expect(json['target_user_id'], isNull);
        expect(json['ip_address'], isNull);
        expect(json['user_agent'], isNull);
      });
    });

    group('toEntity', () {
      test('should convert model to entity', () {
        final model = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userSuspended,
          targetUserId: 'user-123',
          description: 'Suspended user account',
          metadata: {'reason': 'Policy violation'},
          ipAddress: '192.168.1.1',
          userAgent: 'Mozilla/5.0',
          createdAt: testDate,
        );

        final entity = model.toEntity();

        expect(entity, isA<AdminActivityLog>());
        expect(entity.id, model.id);
        expect(entity.adminId, model.adminId);
        expect(entity.actionType, model.actionType);
        expect(entity.targetUserId, model.targetUserId);
        expect(entity.description, model.description);
        expect(entity.metadata['reason'], 'Policy violation');
        expect(entity.ipAddress, model.ipAddress);
        expect(entity.userAgent, model.userAgent);
        expect(entity.createdAt, model.createdAt);
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = AdminActivityLog(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userActivated,
          targetUserId: 'user-123',
          description: 'Activated user account',
          metadata: {'previous_status': 'suspended'},
          ipAddress: '192.168.1.1',
          userAgent: 'Chrome/120.0',
          createdAt: testDate,
        );

        final model = AdminActivityLogModel.fromEntity(entity);

        expect(model.id, entity.id);
        expect(model.adminId, entity.adminId);
        expect(model.actionType, entity.actionType);
        expect(model.targetUserId, entity.targetUserId);
        expect(model.description, entity.description);
        expect(model.metadata['previous_status'], 'suspended');
        expect(model.ipAddress, entity.ipAddress);
        expect(model.userAgent, entity.userAgent);
        expect(model.createdAt, entity.createdAt);
      });
    });

    group('round-trip serialization', () {
      test('should preserve all data through JSON round-trip', () {
        final original = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.roleChanged,
          targetUserId: 'user-123',
          description: 'Changed role',
          metadata: {'old': 'user', 'new': 'admin'},
          ipAddress: '10.0.0.1',
          userAgent: 'Safari/17.0',
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
        );

        final json = original.toJson();
        final restored = AdminActivityLogModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.adminId, original.adminId);
        expect(restored.actionType, original.actionType);
        expect(restored.targetUserId, original.targetUserId);
        expect(restored.description, original.description);
        expect(restored.metadata['old'], original.metadata['old']);
        expect(restored.ipAddress, original.ipAddress);
        expect(restored.userAgent, original.userAgent);
      });

      test('should preserve all data through entity round-trip', () {
        final original = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userDeleted,
          targetUserId: 'user-123',
          description: 'Deleted user',
          metadata: {'reason': 'User request'},
          ipAddress: '172.16.0.1',
          userAgent: 'Firefox/120.0',
          createdAt: testDate,
        );

        final entity = original.toEntity();
        final restored = AdminActivityLogModel.fromEntity(entity);

        expect(restored.id, original.id);
        expect(restored.adminId, original.adminId);
        expect(restored.actionType, original.actionType);
        expect(restored.targetUserId, original.targetUserId);
        expect(restored.description, original.description);
        expect(restored.metadata['reason'], original.metadata['reason']);
        expect(restored.ipAddress, original.ipAddress);
        expect(restored.userAgent, original.userAgent);
        expect(restored.createdAt, original.createdAt);
      });
    });

    group('edge cases', () {
      test('should handle empty metadata', () {
        final log = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userCreated,
          description: 'Created user',
          metadata: {},
          createdAt: testDate,
        );

        final json = log.toJson();
        final restored = AdminActivityLogModel.fromJson(json);

        expect(restored.metadata, isEmpty);
      });

      test('should handle complex metadata', () {
        final metadata = {
          'old_values': {
            'email': 'old@example.com',
            'name': 'Old Name',
          },
          'new_values': {
            'email': 'new@example.com',
            'name': 'New Name',
          },
          'changed_fields': ['email', 'name'],
        };

        final log = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userUpdated,
          description: 'Updated user profile',
          metadata: metadata,
          createdAt: testDate,
        );

        final json = log.toJson();
        final restored = AdminActivityLogModel.fromJson(json);

        expect(restored.metadata['old_values']['email'], 'old@example.com');
        expect(restored.metadata['new_values']['email'], 'new@example.com');
      });

      test('should handle special characters in description', () {
        final log = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userCreated,
          description: 'Created user with email: test@example.com & name: "John Doe"',
          metadata: {},
          createdAt: testDate,
        );

        final json = log.toJson();
        final restored = AdminActivityLogModel.fromJson(json);

        expect(restored.description, contains('&'));
        expect(restored.description, contains('"John Doe"'));
      });

      test('should handle IPv6 address', () {
        final log = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userCreated,
          description: 'Test',
          metadata: {},
          ipAddress: '2001:0db8:85a3:0000:0000:8a2e:0370:7334',
          createdAt: testDate,
        );

        final json = log.toJson();
        final restored = AdminActivityLogModel.fromJson(json);

        expect(restored.ipAddress, '2001:0db8:85a3:0000:0000:8a2e:0370:7334');
      });

      test('should handle long user agent string', () {
        final longUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0';

        final log = AdminActivityLogModel(
          id: 'log-1',
          adminId: 'admin-1',
          actionType: AdminActionType.userCreated,
          description: 'Test',
          metadata: {},
          userAgent: longUserAgent,
          createdAt: testDate,
        );

        final json = log.toJson();
        final restored = AdminActivityLogModel.fromJson(json);

        expect(restored.userAgent, longUserAgent);
      });
    });
  });

  group('AdminActionType', () {
    group('fromString', () {
      test('should parse all valid action types', () {
        expect(AdminActionType.fromString('user_created'), AdminActionType.userCreated);
        expect(AdminActionType.fromString('user_updated'), AdminActionType.userUpdated);
        expect(AdminActionType.fromString('user_suspended'), AdminActionType.userSuspended);
        expect(AdminActionType.fromString('user_activated'), AdminActionType.userActivated);
        expect(AdminActionType.fromString('user_deleted'), AdminActionType.userDeleted);
        expect(AdminActionType.fromString('role_changed'), AdminActionType.roleChanged);
        expect(AdminActionType.fromString('password_reset'), AdminActionType.passwordReset);
        expect(AdminActionType.fromString('profile_updated'), AdminActionType.profileUpdated);
      });

      test('should return userUpdated for unknown values', () {
        expect(AdminActionType.fromString('unknown'), AdminActionType.userUpdated);
        expect(AdminActionType.fromString(''), AdminActionType.userUpdated);
        expect(AdminActionType.fromString('INVALID'), AdminActionType.userUpdated);
      });
    });

    group('value', () {
      test('should return correct string values', () {
        expect(AdminActionType.userCreated.value, 'user_created');
        expect(AdminActionType.userUpdated.value, 'user_updated');
        expect(AdminActionType.userSuspended.value, 'user_suspended');
        expect(AdminActionType.userActivated.value, 'user_activated');
        expect(AdminActionType.userDeleted.value, 'user_deleted');
        expect(AdminActionType.roleChanged.value, 'role_changed');
        expect(AdminActionType.passwordReset.value, 'password_reset');
        expect(AdminActionType.profileUpdated.value, 'profile_updated');
      });
    });

    group('displayName', () {
      test('should return correct display names', () {
        expect(AdminActionType.userCreated.displayName, 'User Created');
        expect(AdminActionType.userUpdated.displayName, 'User Updated');
        expect(AdminActionType.userSuspended.displayName, 'User Suspended');
        expect(AdminActionType.userActivated.displayName, 'User Activated');
        expect(AdminActionType.userDeleted.displayName, 'User Deleted');
        expect(AdminActionType.roleChanged.displayName, 'Role Changed');
        expect(AdminActionType.passwordReset.displayName, 'Password Reset');
        expect(AdminActionType.profileUpdated.displayName, 'Profile Updated');
      });
    });

    group('icon', () {
      test('should return correct icons for each action type', () {
        expect(AdminActionType.userCreated.icon, '➕');
        expect(AdminActionType.userUpdated.icon, '✏️');
        expect(AdminActionType.userSuspended.icon, '⏸️');
        expect(AdminActionType.userActivated.icon, '▶️');
        expect(AdminActionType.userDeleted.icon, '🗑️');
        expect(AdminActionType.roleChanged.icon, '👤');
        expect(AdminActionType.passwordReset.icon, '🔑');
        expect(AdminActionType.profileUpdated.icon, '📝');
      });
    });
  });
}
