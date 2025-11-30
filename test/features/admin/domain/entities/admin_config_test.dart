import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/domain/entities/admin_config.dart';

void main() {
  group('AdminConfigModel', () {
    group('constructor', () {
      test('should create instance with required fields', () {
        const config = AdminConfigModel(
          id: 'config-1',
          key: 'max_trip_members',
          value: '10',
          category: 'trips',
          valueType: 'number',
        );

        expect(config.id, 'config-1');
        expect(config.key, 'max_trip_members');
        expect(config.value, '10');
        expect(config.category, 'trips');
        expect(config.valueType, 'number');
        expect(config.isEditable, true);
        expect(config.description, isNull);
        expect(config.updatedAt, isNull);
        expect(config.updatedBy, isNull);
      });

      test('should create instance with all fields', () {
        final now = DateTime.now();
        final config = AdminConfigModel(
          id: 'config-1',
          key: 'max_trip_members',
          value: '10',
          category: 'trips',
          valueType: 'number',
          description: 'Maximum members per trip',
          isEditable: false,
          updatedAt: now,
          updatedBy: 'admin-user',
        );

        expect(config.description, 'Maximum members per trip');
        expect(config.isEditable, false);
        expect(config.updatedAt, now);
        expect(config.updatedBy, 'admin-user');
      });
    });

    group('fromJson', () {
      test('should parse valid JSON with all fields', () {
        final json = {
          'id': 'config-1',
          'key': 'enable_notifications',
          'value': 'true',
          'description': 'Enable push notifications',
          'category': 'notifications',
          'value_type': 'boolean',
          'is_editable': true,
          'updated_at': '2024-01-15T10:30:00.000Z',
          'updated_by': 'admin-123',
        };

        final config = AdminConfigModel.fromJson(json);

        expect(config.id, 'config-1');
        expect(config.key, 'enable_notifications');
        expect(config.value, 'true');
        expect(config.description, 'Enable push notifications');
        expect(config.category, 'notifications');
        expect(config.valueType, 'boolean');
        expect(config.isEditable, true);
        expect(config.updatedAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
        expect(config.updatedBy, 'admin-123');
      });

      test('should handle null value by converting to empty string', () {
        final json = {
          'id': 'config-1',
          'key': 'test_key',
          'value': null,
          'category': 'general',
          'value_type': 'string',
        };

        final config = AdminConfigModel.fromJson(json);
        expect(config.value, '');
      });

      test('should use default category when missing', () {
        final json = {
          'id': 'config-1',
          'key': 'test_key',
          'value': 'test',
        };

        final config = AdminConfigModel.fromJson(json);
        expect(config.category, 'general');
      });

      test('should use default value_type when missing', () {
        final json = {
          'id': 'config-1',
          'key': 'test_key',
          'value': 'test',
          'category': 'general',
        };

        final config = AdminConfigModel.fromJson(json);
        expect(config.valueType, 'string');
      });

      test('should use default is_editable when missing', () {
        final json = {
          'id': 'config-1',
          'key': 'test_key',
          'value': 'test',
          'category': 'general',
          'value_type': 'string',
        };

        final config = AdminConfigModel.fromJson(json);
        expect(config.isEditable, true);
      });

      test('should handle null updated_at', () {
        final json = {
          'id': 'config-1',
          'key': 'test_key',
          'value': 'test',
          'category': 'general',
          'value_type': 'string',
          'updated_at': null,
        };

        final config = AdminConfigModel.fromJson(json);
        expect(config.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should convert to JSON with all fields', () {
        final now = DateTime(2024, 1, 15, 10, 30);
        final config = AdminConfigModel(
          id: 'config-1',
          key: 'max_budget',
          value: '100000',
          description: 'Maximum trip budget',
          category: 'expenses',
          valueType: 'number',
          isEditable: true,
          updatedAt: now,
          updatedBy: 'admin-user',
        );

        final json = config.toJson();

        expect(json['id'], 'config-1');
        expect(json['key'], 'max_budget');
        expect(json['value'], '100000');
        expect(json['description'], 'Maximum trip budget');
        expect(json['category'], 'expenses');
        expect(json['value_type'], 'number');
        expect(json['is_editable'], true);
        expect(json['updated_at'], now.toIso8601String());
        expect(json['updated_by'], 'admin-user');
      });

      test('should handle null optional fields', () {
        const config = AdminConfigModel(
          id: 'config-1',
          key: 'test_key',
          value: 'test',
          category: 'general',
          valueType: 'string',
        );

        final json = config.toJson();

        expect(json['description'], isNull);
        expect(json['updated_at'], isNull);
        expect(json['updated_by'], isNull);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        const original = AdminConfigModel(
          id: 'config-1',
          key: 'test_key',
          value: 'original',
          category: 'general',
          valueType: 'string',
        );

        final copied = original.copyWith(
          value: 'updated',
          description: 'New description',
        );

        expect(copied.id, 'config-1');
        expect(copied.key, 'test_key');
        expect(copied.value, 'updated');
        expect(copied.description, 'New description');
        expect(copied.category, 'general');
        expect(copied.valueType, 'string');
      });

      test('should keep original values when not specified', () {
        final original = AdminConfigModel(
          id: 'config-1',
          key: 'test_key',
          value: 'original',
          description: 'Original description',
          category: 'general',
          valueType: 'string',
          isEditable: false,
          updatedAt: DateTime(2024, 1, 15),
          updatedBy: 'admin',
        );

        final copied = original.copyWith();

        expect(copied.id, original.id);
        expect(copied.key, original.key);
        expect(copied.value, original.value);
        expect(copied.description, original.description);
        expect(copied.category, original.category);
        expect(copied.valueType, original.valueType);
        expect(copied.isEditable, original.isEditable);
        expect(copied.updatedAt, original.updatedAt);
        expect(copied.updatedBy, original.updatedBy);
      });
    });

    group('boolValue', () {
      test('should return true for "true" string', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'enabled',
          value: 'true',
          category: 'general',
          valueType: 'boolean',
        );
        expect(config.boolValue, true);
      });

      test('should return true for "TRUE" string (case insensitive)', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'enabled',
          value: 'TRUE',
          category: 'general',
          valueType: 'boolean',
        );
        expect(config.boolValue, true);
      });

      test('should return false for "false" string', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'enabled',
          value: 'false',
          category: 'general',
          valueType: 'boolean',
        );
        expect(config.boolValue, false);
      });

      test('should return false for non-boolean strings', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'enabled',
          value: 'yes',
          category: 'general',
          valueType: 'boolean',
        );
        expect(config.boolValue, false);
      });
    });

    group('numValue', () {
      test('should parse integer string', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'count',
          value: '42',
          category: 'general',
          valueType: 'number',
        );
        expect(config.numValue, 42.0);
      });

      test('should parse decimal string', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'rate',
          value: '3.14159',
          category: 'general',
          valueType: 'number',
        );
        expect(config.numValue, 3.14159);
      });

      test('should return null for non-numeric string', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'count',
          value: 'not a number',
          category: 'general',
          valueType: 'number',
        );
        expect(config.numValue, isNull);
      });

      test('should return null for empty string', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'count',
          value: '',
          category: 'general',
          valueType: 'number',
        );
        expect(config.numValue, isNull);
      });
    });

    group('intValue', () {
      test('should parse integer string', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'count',
          value: '100',
          category: 'general',
          valueType: 'number',
        );
        expect(config.intValue, 100);
      });

      test('should return null for decimal string', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'rate',
          value: '3.14',
          category: 'general',
          valueType: 'number',
        );
        expect(config.intValue, isNull);
      });

      test('should return null for non-numeric string', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'count',
          value: 'invalid',
          category: 'general',
          valueType: 'number',
        );
        expect(config.intValue, isNull);
      });
    });

    group('displayName', () {
      test('should convert snake_case to Title Case', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'max_trip_members',
          value: '10',
          category: 'trips',
          valueType: 'number',
        );
        expect(config.displayName, 'Max Trip Members');
      });

      test('should handle single word', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'timeout',
          value: '30',
          category: 'general',
          valueType: 'number',
        );
        expect(config.displayName, 'Timeout');
      });

      test('should handle empty key', () {
        const config = AdminConfigModel(
          id: '1',
          key: '',
          value: 'value',
          category: 'general',
          valueType: 'string',
        );
        expect(config.displayName, '');
      });

      test('should handle consecutive underscores', () {
        const config = AdminConfigModel(
          id: '1',
          key: 'test__double',
          value: 'value',
          category: 'general',
          valueType: 'string',
        );
        expect(config.displayName, 'Test  Double');
      });
    });
  });

  group('ConfigCategory', () {
    test('should have correct values', () {
      expect(ConfigCategory.general.value, 'general');
      expect(ConfigCategory.general.displayName, 'General');

      expect(ConfigCategory.trips.value, 'trips');
      expect(ConfigCategory.trips.displayName, 'Trips');

      expect(ConfigCategory.expenses.value, 'expenses');
      expect(ConfigCategory.expenses.displayName, 'Expenses');

      expect(ConfigCategory.users.value, 'users');
      expect(ConfigCategory.users.displayName, 'Users');

      expect(ConfigCategory.notifications.value, 'notifications');
      expect(ConfigCategory.notifications.displayName, 'Notifications');

      expect(ConfigCategory.security.value, 'security');
      expect(ConfigCategory.security.displayName, 'Security');

      expect(ConfigCategory.features.value, 'features');
      expect(ConfigCategory.features.displayName, 'Feature Flags');
    });

    group('fromString', () {
      test('should return correct category for valid string', () {
        expect(ConfigCategory.fromString('general'), ConfigCategory.general);
        expect(ConfigCategory.fromString('trips'), ConfigCategory.trips);
        expect(ConfigCategory.fromString('expenses'), ConfigCategory.expenses);
        expect(ConfigCategory.fromString('users'), ConfigCategory.users);
        expect(
            ConfigCategory.fromString('notifications'), ConfigCategory.notifications);
        expect(ConfigCategory.fromString('security'), ConfigCategory.security);
        expect(ConfigCategory.fromString('features'), ConfigCategory.features);
      });

      test('should return general for invalid string', () {
        expect(ConfigCategory.fromString('invalid'), ConfigCategory.general);
        expect(ConfigCategory.fromString(''), ConfigCategory.general);
        expect(ConfigCategory.fromString('unknown'), ConfigCategory.general);
      });
    });
  });

  group('ConfigListParams', () {
    group('constructor', () {
      test('should create with default values', () {
        const params = ConfigListParams();
        expect(params.category, isNull);
        expect(params.search, isNull);
      });

      test('should create with specified values', () {
        const params = ConfigListParams(
          category: 'trips',
          search: 'max',
        );
        expect(params.category, 'trips');
        expect(params.search, 'max');
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        const params1 = ConfigListParams(category: 'trips', search: 'test');
        const params2 = ConfigListParams(category: 'trips', search: 'test');
        expect(params1, equals(params2));
      });

      test('should not be equal when different values', () {
        const params1 = ConfigListParams(category: 'trips', search: 'test');
        const params2 = ConfigListParams(category: 'users', search: 'test');
        expect(params1, isNot(equals(params2)));
      });

      test('should handle null values in equality', () {
        const params1 = ConfigListParams(category: null, search: null);
        const params2 = ConfigListParams(category: null, search: null);
        expect(params1, equals(params2));
      });

      test('should be identical to itself', () {
        const params = ConfigListParams(category: 'trips');
        expect(params == params, true);
      });
    });

    group('hashCode', () {
      test('should have same hashCode for equal objects', () {
        const params1 = ConfigListParams(category: 'trips', search: 'test');
        const params2 = ConfigListParams(category: 'trips', search: 'test');
        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('should generally have different hashCode for different objects', () {
        const params1 = ConfigListParams(category: 'trips', search: 'test');
        const params2 = ConfigListParams(category: 'users', search: 'other');
        // Note: hashCode collision is possible but unlikely
        expect(params1.hashCode, isNot(equals(params2.hashCode)));
      });
    });
  });
}
