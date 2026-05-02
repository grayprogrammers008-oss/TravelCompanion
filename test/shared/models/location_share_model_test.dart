import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/location_share_model.dart';

void main() {
  group('LocationShareModel', () {
    final startedAt = DateTime(2024, 1, 15, 10, 0);
    final lastUpdatedAt = DateTime(2024, 1, 15, 10, 5);
    final expiresAt = DateTime(2024, 1, 15, 12, 0);

    group('constructor', () {
      test('should create instance with required fields', () {
        final share = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          latitude: 12.97,
          longitude: 77.59,
          status: LocationShareStatus.active,
          startedAt: startedAt,
          lastUpdatedAt: lastUpdatedAt,
          sharedWithContactIds: const [],
        );

        expect(share.id, 's-1');
        expect(share.userId, 'u-1');
        expect(share.latitude, 12.97);
        expect(share.longitude, 77.59);
        expect(share.status, LocationShareStatus.active);
        expect(share.tripId, isNull);
        expect(share.accuracy, isNull);
        expect(share.expiresAt, isNull);
        expect(share.sharedWithContactIds, isEmpty);
      });

      test('should create instance with all fields', () {
        final share = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          tripId: 't-1',
          latitude: 12.97,
          longitude: 77.59,
          accuracy: 5.0,
          altitude: 920.0,
          speed: 1.2,
          heading: 90.0,
          status: LocationShareStatus.paused,
          startedAt: startedAt,
          expiresAt: expiresAt,
          lastUpdatedAt: lastUpdatedAt,
          sharedWithContactIds: const ['c-1', 'c-2'],
          message: 'Safe',
        );

        expect(share.tripId, 't-1');
        expect(share.accuracy, 5.0);
        expect(share.altitude, 920.0);
        expect(share.speed, 1.2);
        expect(share.heading, 90.0);
        expect(share.expiresAt, expiresAt);
        expect(share.message, 'Safe');
        expect(share.sharedWithContactIds.length, 2);
      });
    });

    group('fromJson', () {
      test('should parse JSON with all fields', () {
        final json = {
          'id': 's-1',
          'user_id': 'u-1',
          'trip_id': 't-1',
          'latitude': 12.97,
          'longitude': 77.59,
          'accuracy': 5,
          'altitude': 920.5,
          'speed': 1.2,
          'heading': 90,
          'status': 'active',
          'started_at': startedAt.toIso8601String(),
          'expires_at': expiresAt.toIso8601String(),
          'last_updated_at': lastUpdatedAt.toIso8601String(),
          'shared_with_contact_ids': ['c-1', 'c-2'],
          'message': 'Safe',
        };

        final share = LocationShareModel.fromJson(json);

        expect(share.id, 's-1');
        expect(share.accuracy, 5.0);
        expect(share.heading, 90.0);
        expect(share.status, LocationShareStatus.active);
        expect(share.sharedWithContactIds, ['c-1', 'c-2']);
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 's-1',
          'user_id': 'u-1',
          'latitude': 12.97,
          'longitude': 77.59,
          'status': 'stopped',
          'started_at': startedAt.toIso8601String(),
          'last_updated_at': lastUpdatedAt.toIso8601String(),
        };

        final share = LocationShareModel.fromJson(json);

        expect(share.tripId, isNull);
        expect(share.accuracy, isNull);
        expect(share.altitude, isNull);
        expect(share.expiresAt, isNull);
        expect(share.sharedWithContactIds, isEmpty);
        expect(share.message, isNull);
      });

      test('should default status to stopped on unknown value', () {
        final json = {
          'id': 's-1',
          'user_id': 'u-1',
          'latitude': 0.0,
          'longitude': 0.0,
          'status': 'unknown_value',
          'started_at': startedAt.toIso8601String(),
          'last_updated_at': lastUpdatedAt.toIso8601String(),
        };

        final share = LocationShareModel.fromJson(json);
        expect(share.status, LocationShareStatus.stopped);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final share = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          latitude: 12.97,
          longitude: 77.59,
          status: LocationShareStatus.expired,
          startedAt: startedAt,
          lastUpdatedAt: lastUpdatedAt,
          sharedWithContactIds: const ['c-1'],
        );

        final json = share.toJson();

        expect(json['id'], 's-1');
        expect(json['status'], 'expired');
        expect(json['shared_with_contact_ids'], ['c-1']);
        expect(json['expires_at'], isNull);
      });

      test('round-trips fromJson + toJson', () {
        final original = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          tripId: 't-1',
          latitude: 12.97,
          longitude: 77.59,
          accuracy: 5.0,
          status: LocationShareStatus.active,
          startedAt: startedAt,
          expiresAt: expiresAt,
          lastUpdatedAt: lastUpdatedAt,
          sharedWithContactIds: const ['c-1'],
          message: 'Safe',
        );

        final reconstructed = LocationShareModel.fromJson(original.toJson());

        expect(reconstructed, equals(original));
      });
    });

    group('copyWith', () {
      test('should override specified fields', () {
        final original = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          latitude: 12.97,
          longitude: 77.59,
          status: LocationShareStatus.active,
          startedAt: startedAt,
          lastUpdatedAt: lastUpdatedAt,
          sharedWithContactIds: const [],
        );

        final copied = original.copyWith(
          status: LocationShareStatus.stopped,
          message: 'Done',
        );

        expect(copied.status, LocationShareStatus.stopped);
        expect(copied.message, 'Done');
        expect(copied.id, 's-1');
      });

      test('should preserve values when nothing overridden', () {
        final original = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          latitude: 12.97,
          longitude: 77.59,
          status: LocationShareStatus.active,
          startedAt: startedAt,
          lastUpdatedAt: lastUpdatedAt,
          sharedWithContactIds: const ['c-1'],
        );

        final copied = original.copyWith();
        expect(copied, equals(original));
      });
    });

    group('computed properties', () {
      test('isActive returns true only when status is active', () {
        final active = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          latitude: 0,
          longitude: 0,
          status: LocationShareStatus.active,
          startedAt: startedAt,
          lastUpdatedAt: lastUpdatedAt,
          sharedWithContactIds: const [],
        );
        final stopped = active.copyWith(status: LocationShareStatus.stopped);

        expect(active.isActive, true);
        expect(stopped.isActive, false);
      });

      test('isExpired is false when expiresAt is null', () {
        final share = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          latitude: 0,
          longitude: 0,
          status: LocationShareStatus.active,
          startedAt: startedAt,
          lastUpdatedAt: lastUpdatedAt,
          sharedWithContactIds: const [],
        );
        expect(share.isExpired, false);
      });

      test('isExpired is true when expiresAt is in the past', () {
        final share = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          latitude: 0,
          longitude: 0,
          status: LocationShareStatus.active,
          startedAt: startedAt,
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
          lastUpdatedAt: lastUpdatedAt,
          sharedWithContactIds: const [],
        );
        expect(share.isExpired, true);
      });

      test('timeSinceLastUpdate returns positive duration', () {
        final share = LocationShareModel(
          id: 's-1',
          userId: 'u-1',
          latitude: 0,
          longitude: 0,
          status: LocationShareStatus.active,
          startedAt: startedAt,
          lastUpdatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          sharedWithContactIds: const [],
        );
        expect(share.timeSinceLastUpdate.inMinutes, greaterThanOrEqualTo(4));
      });
    });
  });
}
