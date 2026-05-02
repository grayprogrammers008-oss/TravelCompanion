import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/emergency_alert_model.dart';

void main() {
  group('EmergencyAlertModel', () {
    final createdAt = DateTime(2024, 1, 15, 10, 0);
    final acknowledgedAt = DateTime(2024, 1, 15, 10, 5);
    final resolvedAt = DateTime(2024, 1, 15, 11, 0);

    group('constructor', () {
      test('should create with required fields', () {
        final alert = EmergencyAlertModel(
          id: 'a-1',
          userId: 'u-1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.active,
          createdAt: createdAt,
          notifiedContactIds: const [],
        );

        expect(alert.id, 'a-1');
        expect(alert.type, EmergencyAlertType.sos);
        expect(alert.status, EmergencyAlertStatus.active);
        expect(alert.tripId, isNull);
        expect(alert.message, isNull);
        expect(alert.latitude, isNull);
        expect(alert.notifiedContactIds, isEmpty);
      });

      test('should create with all fields', () {
        final alert = EmergencyAlertModel(
          id: 'a-1',
          userId: 'u-1',
          tripId: 't-1',
          type: EmergencyAlertType.medical,
          status: EmergencyAlertStatus.acknowledged,
          message: 'Need help',
          latitude: 12.97,
          longitude: 77.59,
          locationName: 'Bangalore',
          createdAt: createdAt,
          acknowledgedAt: acknowledgedAt,
          resolvedAt: resolvedAt,
          acknowledgedBy: 'c-1',
          notifiedContactIds: const ['c-1', 'c-2'],
          metadata: const {'severity': 'high'},
        );

        expect(alert.tripId, 't-1');
        expect(alert.message, 'Need help');
        expect(alert.locationName, 'Bangalore');
        expect(alert.acknowledgedBy, 'c-1');
        expect(alert.metadata, {'severity': 'high'});
      });
    });

    group('fromJson', () {
      test('should parse JSON with all fields', () {
        final json = {
          'id': 'a-1',
          'user_id': 'u-1',
          'trip_id': 't-1',
          'type': 'medical',
          'status': 'acknowledged',
          'message': 'Need help',
          'latitude': 12.97,
          'longitude': 77.59,
          'location_name': 'Bangalore',
          'created_at': createdAt.toIso8601String(),
          'acknowledged_at': acknowledgedAt.toIso8601String(),
          'resolved_at': resolvedAt.toIso8601String(),
          'acknowledged_by': 'c-1',
          'notified_contact_ids': ['c-1', 'c-2'],
          'metadata': {'severity': 'high'},
        };

        final alert = EmergencyAlertModel.fromJson(json);

        expect(alert.type, EmergencyAlertType.medical);
        expect(alert.status, EmergencyAlertStatus.acknowledged);
        expect(alert.notifiedContactIds, ['c-1', 'c-2']);
        expect(alert.metadata, {'severity': 'high'});
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'a-1',
          'user_id': 'u-1',
          'type': 'sos',
          'status': 'active',
          'created_at': createdAt.toIso8601String(),
        };

        final alert = EmergencyAlertModel.fromJson(json);

        expect(alert.tripId, isNull);
        expect(alert.latitude, isNull);
        expect(alert.metadata, isNull);
        expect(alert.notifiedContactIds, isEmpty);
      });

      test('should default to custom type on unknown', () {
        final json = {
          'id': 'a-1',
          'user_id': 'u-1',
          'type': 'unknown',
          'status': 'unknown_status',
          'created_at': createdAt.toIso8601String(),
        };

        final alert = EmergencyAlertModel.fromJson(json);

        expect(alert.type, EmergencyAlertType.custom);
        expect(alert.status, EmergencyAlertStatus.active);
      });

      test('should parse integer latitude as double', () {
        final json = {
          'id': 'a-1',
          'user_id': 'u-1',
          'type': 'sos',
          'status': 'active',
          'latitude': 12,
          'longitude': 77,
          'created_at': createdAt.toIso8601String(),
        };

        final alert = EmergencyAlertModel.fromJson(json);

        expect(alert.latitude, 12.0);
        expect(alert.longitude, 77.0);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final alert = EmergencyAlertModel(
          id: 'a-1',
          userId: 'u-1',
          type: EmergencyAlertType.help,
          status: EmergencyAlertStatus.resolved,
          createdAt: createdAt,
          notifiedContactIds: const ['c-1'],
        );

        final json = alert.toJson();

        expect(json['id'], 'a-1');
        expect(json['type'], 'help');
        expect(json['status'], 'resolved');
        expect(json['notified_contact_ids'], ['c-1']);
      });

      test('round-trips fromJson + toJson', () {
        final original = EmergencyAlertModel(
          id: 'a-1',
          userId: 'u-1',
          tripId: 't-1',
          type: EmergencyAlertType.safety,
          status: EmergencyAlertStatus.active,
          message: 'check-in',
          latitude: 12.97,
          longitude: 77.59,
          locationName: 'Bangalore',
          createdAt: createdAt,
          notifiedContactIds: const ['c-1'],
        );

        final reconstructed = EmergencyAlertModel.fromJson(original.toJson());

        expect(reconstructed, equals(original));
      });
    });

    group('copyWith', () {
      test('should override specified fields', () {
        final original = EmergencyAlertModel(
          id: 'a-1',
          userId: 'u-1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.active,
          createdAt: createdAt,
          notifiedContactIds: const [],
        );

        final copied = original.copyWith(
          status: EmergencyAlertStatus.resolved,
          resolvedAt: resolvedAt,
        );

        expect(copied.status, EmergencyAlertStatus.resolved);
        expect(copied.resolvedAt, resolvedAt);
        expect(copied.id, 'a-1');
        expect(copied.type, EmergencyAlertType.sos);
      });

      test('should preserve values when nothing overridden', () {
        final original = EmergencyAlertModel(
          id: 'a-1',
          userId: 'u-1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.active,
          createdAt: createdAt,
          notifiedContactIds: const ['c-1'],
        );

        final copied = original.copyWith();
        expect(copied, equals(original));
      });
    });

    group('computed properties', () {
      test('isActive returns true when status is active', () {
        final alert = EmergencyAlertModel(
          id: 'a-1',
          userId: 'u-1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.active,
          createdAt: createdAt,
          notifiedContactIds: const [],
        );
        expect(alert.isActive, true);
        expect(alert.copyWith(status: EmergencyAlertStatus.resolved).isActive,
            false);
      });

      test('hasLocation returns true when both lat/lon present', () {
        final withLoc = EmergencyAlertModel(
          id: 'a-1',
          userId: 'u-1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.active,
          latitude: 12.97,
          longitude: 77.59,
          createdAt: createdAt,
          notifiedContactIds: const [],
        );
        final withoutLoc = withLoc.copyWith();
        final cleared = EmergencyAlertModel(
          id: 'a-2',
          userId: 'u-1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.active,
          createdAt: createdAt,
          notifiedContactIds: const [],
        );

        expect(withLoc.hasLocation, true);
        expect(withoutLoc.hasLocation, true);
        expect(cleared.hasLocation, false);
      });

      test('durationSinceCreated returns positive duration', () {
        final alert = EmergencyAlertModel(
          id: 'a-1',
          userId: 'u-1',
          type: EmergencyAlertType.sos,
          status: EmergencyAlertStatus.active,
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          notifiedContactIds: const [],
        );
        expect(alert.durationSinceCreated.inMinutes, greaterThanOrEqualTo(9));
      });
    });
  });
}
