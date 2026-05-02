import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/emergency_number_model.dart';

void main() {
  group('EmergencyServiceType', () {
    test('displayName returns expected strings', () {
      expect(EmergencyServiceType.police.displayName, 'Police');
      expect(EmergencyServiceType.fire.displayName, 'Fire');
      expect(EmergencyServiceType.ambulance.displayName, 'Ambulance');
      expect(EmergencyServiceType.emergency.displayName, 'Emergency');
      expect(EmergencyServiceType.disaster.displayName, 'Disaster Management');
      expect(EmergencyServiceType.helpline.displayName, 'Helpline');
      expect(EmergencyServiceType.other.displayName, 'Other');
    });
  });

  group('EmergencyNumberModel', () {
    EmergencyNumberModel buildSample() {
      return const EmergencyNumberModel(
        id: 'n-1',
        serviceName: 'Police',
        serviceType: EmergencyServiceType.police,
        phoneNumber: '100',
        alternateNumber: '112',
        country: 'IN',
        state: 'KA',
        city: 'Bangalore',
        description: 'Police helpline',
        isTollFree: true,
        is24x7: true,
        languages: ['en', 'kn'],
        icon: 'shield',
        color: '#FF0000',
        displayOrder: 1,
        isActive: true,
      );
    }

    group('constructor', () {
      test('should create with required fields only', () {
        const number = EmergencyNumberModel(
          id: 'n-1',
          serviceName: 'Police',
          serviceType: EmergencyServiceType.police,
          phoneNumber: '100',
          country: 'IN',
          isTollFree: false,
          is24x7: true,
          languages: ['en'],
          displayOrder: 0,
          isActive: true,
        );

        expect(number.id, 'n-1');
        expect(number.alternateNumber, isNull);
        expect(number.state, isNull);
        expect(number.city, isNull);
      });

      test('should create with all fields', () {
        final number = buildSample();

        expect(number.alternateNumber, '112');
        expect(number.languages.length, 2);
        expect(number.color, '#FF0000');
      });
    });

    group('fromJson', () {
      test('should parse complete JSON', () {
        final json = {
          'id': 'n-1',
          'service_name': 'Police',
          'service_type': 'police',
          'phone_number': '100',
          'alternate_number': '112',
          'country': 'IN',
          'state': 'KA',
          'city': 'Bangalore',
          'description': 'Police helpline',
          'is_toll_free': true,
          'is_24_7': true,
          'languages': ['en', 'kn'],
          'icon': 'shield',
          'color': '#FF0000',
          'display_order': 1,
          'is_active': true,
        };

        final number = EmergencyNumberModel.fromJson(json);

        expect(number.serviceType, EmergencyServiceType.police);
        expect(number.languages, ['en', 'kn']);
      });

      test('should default missing fields', () {
        final json = {
          'id': 'n-1',
          'service_name': 'Help',
          'service_type': 'unknown',
          'phone_number': '999',
          'country': 'IN',
        };

        final number = EmergencyNumberModel.fromJson(json);

        expect(number.serviceType, EmergencyServiceType.other);
        expect(number.isTollFree, false);
        expect(number.is24x7, true);
        expect(number.languages, isEmpty);
        expect(number.displayOrder, 0);
        expect(number.isActive, true);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final number = buildSample();
        final json = number.toJson();

        expect(json['id'], 'n-1');
        expect(json['service_type'], 'police');
        expect(json['is_toll_free'], true);
        expect(json['is_24_7'], true);
        expect(json['languages'], ['en', 'kn']);
        expect(json['display_order'], 1);
      });

      test('round-trips preserves data', () {
        final original = buildSample();
        final reconstructed =
            EmergencyNumberModel.fromJson(original.toJson());

        expect(reconstructed, equals(original));
      });
    });

    group('copyWith', () {
      test('should override specified fields', () {
        final original = buildSample();
        final copied = original.copyWith(
          phoneNumber: '101',
          isActive: false,
        );

        expect(copied.phoneNumber, '101');
        expect(copied.isActive, false);
        expect(copied.serviceName, 'Police');
      });

      test('should preserve values when nothing overridden', () {
        final original = buildSample();
        final copied = original.copyWith();
        expect(copied, equals(original));
      });
    });

    group('computed properties', () {
      test('primaryNumber returns phoneNumber', () {
        final number = buildSample();
        expect(number.primaryNumber, '100');
      });

      test('hasAlternateNumber is true when present and non-empty', () {
        final number = buildSample();
        expect(number.hasAlternateNumber, true);

        final noAlt = number.copyWith(alternateNumber: '');
        // copyWith does not allow null, but empty string indicates absence
        expect(noAlt.hasAlternateNumber, false);
      });

      test('displayIcon returns default when null', () {
        const number = EmergencyNumberModel(
          id: 'n-1',
          serviceName: 'X',
          serviceType: EmergencyServiceType.other,
          phoneNumber: '1',
          country: 'IN',
          isTollFree: false,
          is24x7: false,
          languages: [],
          displayOrder: 0,
          isActive: true,
        );

        expect(number.displayIcon, 'phone');
        expect(number.displayColor, '#000000');
      });

      test('displayIcon and displayColor return set values', () {
        final number = buildSample();
        expect(number.displayIcon, 'shield');
        expect(number.displayColor, '#FF0000');
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final n1 = buildSample();
        final n2 = buildSample();
        expect(n1, equals(n2));
        expect(n1.hashCode, equals(n2.hashCode));
      });

      test('should not be equal when different id', () {
        final n1 = buildSample();
        final n2 = n1.copyWith(id: 'n-2');
        expect(n1, isNot(equals(n2)));
      });
    });
  });
}
