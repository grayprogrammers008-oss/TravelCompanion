import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/features/admin/domain/entities/user_status.dart';

void main() {
  group('UserStatus', () {
    test('enum values have correct underlying strings', () {
      expect(UserStatus.active.value, 'active');
      expect(UserStatus.suspended.value, 'suspended');
      expect(UserStatus.deleted.value, 'deleted');
    });

    test('displayName returns human readable labels', () {
      expect(UserStatus.active.displayName, 'Active');
      expect(UserStatus.suspended.displayName, 'Suspended');
      expect(UserStatus.deleted.displayName, 'Deleted');
    });

    test('colorHex returns expected color codes', () {
      expect(UserStatus.active.colorHex, '#22C55E');
      expect(UserStatus.suspended.colorHex, '#F59E0B');
      expect(UserStatus.deleted.colorHex, '#EF4444');
    });

    group('canPerformActions', () {
      test('only active users can perform actions', () {
        expect(UserStatus.active.canPerformActions, true);
        expect(UserStatus.suspended.canPerformActions, false);
        expect(UserStatus.deleted.canPerformActions, false);
      });
    });

    group('fromString', () {
      test('parses known status strings', () {
        expect(UserStatus.fromString('active'), UserStatus.active);
        expect(UserStatus.fromString('suspended'), UserStatus.suspended);
        expect(UserStatus.fromString('deleted'), UserStatus.deleted);
      });

      test('defaults to active for unknown strings', () {
        expect(UserStatus.fromString(''), UserStatus.active);
        expect(UserStatus.fromString('unknown'), UserStatus.active);
        expect(UserStatus.fromString('ACTIVE'), UserStatus.active); // case sensitive
      });
    });

    test('values list contains exactly three statuses', () {
      expect(UserStatus.values.length, 3);
    });
  });
}
