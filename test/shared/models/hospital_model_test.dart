import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/shared/models/hospital_model.dart';

void main() {
  group('HospitalType', () {
    test('displayName returns expected strings', () {
      expect(HospitalType.general.displayName, 'General Hospital');
      expect(HospitalType.specialized.displayName, 'Specialized Hospital');
      expect(HospitalType.emergency.displayName, 'Emergency Hospital');
      expect(HospitalType.traumaCenter.displayName, 'Trauma Center');
      expect(HospitalType.urgentCare.displayName, 'Urgent Care');
    });

    test('fromString parses known values', () {
      expect(HospitalType.fromString('general'), HospitalType.general);
      expect(HospitalType.fromString('specialized'), HospitalType.specialized);
      expect(HospitalType.fromString('emergency'), HospitalType.emergency);
      expect(HospitalType.fromString('trauma_center'), HospitalType.traumaCenter);
      expect(HospitalType.fromString('urgent_care'), HospitalType.urgentCare);
      expect(HospitalType.fromString('UNKNOWN'), HospitalType.general);
    });

    test('toJson returns expected snake_case strings', () {
      expect(HospitalType.general.toJson(), 'general');
      expect(HospitalType.traumaCenter.toJson(), 'trauma_center');
      expect(HospitalType.urgentCare.toJson(), 'urgent_care');
    });
  });

  group('TraumaLevel', () {
    test('displayName returns Roman numeral labels', () {
      expect(TraumaLevel.levelOne.displayName, 'Level I');
      expect(TraumaLevel.levelThree.displayName, 'Level III');
      expect(TraumaLevel.levelFive.displayName, 'Level V');
    });

    test('fromString parses Roman numerals', () {
      expect(TraumaLevel.fromString('I'), TraumaLevel.levelOne);
      expect(TraumaLevel.fromString('ii'), TraumaLevel.levelTwo);
      expect(TraumaLevel.fromString('V'), TraumaLevel.levelFive);
      expect(TraumaLevel.fromString(null), isNull);
      expect(TraumaLevel.fromString('XYZ'), isNull);
    });

    test('toJson returns Roman numerals', () {
      expect(TraumaLevel.levelOne.toJson(), 'I');
      expect(TraumaLevel.levelTwo.toJson(), 'II');
      expect(TraumaLevel.levelFive.toJson(), 'V');
    });
  });

  group('HospitalModel', () {
    final createdAt = DateTime(2024, 1, 15, 10, 0);
    final updatedAt = DateTime(2024, 1, 16, 12, 0);

    HospitalModel buildSample({double? distance}) {
      return HospitalModel(
        id: 'h-1',
        name: 'City Hospital',
        address: '123 Main St',
        city: 'Bangalore',
        state: 'KA',
        country: 'India',
        postalCode: '560001',
        latitude: 12.97,
        longitude: 77.59,
        phoneNumber: '+919999',
        emergencyPhone: '108',
        type: HospitalType.general,
        capacity: 200,
        hasEmergencyRoom: true,
        hasTraumaCenter: true,
        traumaLevel: TraumaLevel.levelOne,
        acceptsAmbulance: true,
        is24_7: true,
        services: const ['cardiology'],
        specialties: const ['heart'],
        rating: 4.5,
        totalReviews: 100,
        isActive: true,
        isVerified: true,
        createdAt: createdAt,
        updatedAt: updatedAt,
        distanceKm: distance,
      );
    }

    group('constructor', () {
      test('should create with required fields and apply defaults', () {
        final hospital = HospitalModel(
          id: 'h-1',
          name: 'X',
          address: 'A',
          city: 'C',
          state: 'S',
          latitude: 0,
          longitude: 0,
          type: HospitalType.general,
          createdAt: createdAt,
        );

        expect(hospital.country, 'USA');
        expect(hospital.hasEmergencyRoom, true);
        expect(hospital.hasTraumaCenter, false);
        expect(hospital.acceptsAmbulance, true);
        expect(hospital.is24_7, true);
        expect(hospital.services, isEmpty);
        expect(hospital.totalReviews, 0);
        expect(hospital.isActive, true);
        expect(hospital.isVerified, false);
      });

      test('should create with all fields', () {
        final hospital = buildSample(distance: 2.5);
        expect(hospital.id, 'h-1');
        expect(hospital.distanceKm, 2.5);
        expect(hospital.traumaLevel, TraumaLevel.levelOne);
      });
    });

    group('fromJson', () {
      test('should parse minimal JSON with defaults', () {
        final json = <String, dynamic>{
          'id': 'h-1',
          'name': 'City',
        };

        final hospital = HospitalModel.fromJson(json);

        expect(hospital.id, 'h-1');
        expect(hospital.name, 'City');
        expect(hospital.address, 'Unknown Address');
        expect(hospital.country, 'India');
        expect(hospital.latitude, 0.0);
        expect(hospital.type, HospitalType.general);
      });

      test('should map alternate DB column names', () {
        final json = {
          'id': 'h-1',
          'name': 'X',
          'phone': '111',
          'has_emergency': true,
          'has_ambulance': false,
          'is_operational': false,
          'verified': true,
          'pincode': '560001',
          'hospital_type': 'emergency',
          'total_beds': 50,
        };

        final hospital = HospitalModel.fromJson(json);

        expect(hospital.phoneNumber, '111');
        expect(hospital.hasEmergencyRoom, true);
        expect(hospital.acceptsAmbulance, false);
        expect(hospital.isActive, false);
        expect(hospital.isVerified, true);
        expect(hospital.postalCode, '560001');
        expect(hospital.type, HospitalType.emergency);
        expect(hospital.capacity, 50);
      });

      test('should parse trauma_level integer values', () {
        final json = {
          'id': 'h-1',
          'name': 'X',
          'trauma_level': 1,
        };

        final hospital = HospitalModel.fromJson(json);
        expect(hospital.traumaLevel, TraumaLevel.levelOne);
        // hasTraumaCenter inferred from trauma_level being non-null
        expect(hospital.hasTraumaCenter, true);
      });

      test('should parse string boolean values', () {
        final json = {
          'id': 'h-1',
          'name': 'X',
          'has_emergency_room': 'true',
          'is_active': '1',
          'is_verified': 'false',
        };

        final hospital = HospitalModel.fromJson(json);
        expect(hospital.hasEmergencyRoom, true);
        expect(hospital.isActive, true);
        expect(hospital.isVerified, false);
      });
    });

    group('toJson', () {
      test('should convert to JSON', () {
        final hospital = buildSample();
        final json = hospital.toJson();

        expect(json['id'], 'h-1');
        expect(json['type'], 'general');
        expect(json['trauma_level'], 'I');
        expect(json['country'], 'India');
        expect(json['is_24_7'], true);
        expect(json.containsKey('distance_km'), false);
      });

      test('should include distance_km when set', () {
        final hospital = buildSample(distance: 1.5);
        final json = hospital.toJson();
        expect(json['distance_km'], 1.5);
      });
    });

    group('copyWith', () {
      test('should override specified fields', () {
        final original = buildSample();
        final copied = original.copyWith(
          name: 'New Hospital',
          rating: 3.0,
        );

        expect(copied.name, 'New Hospital');
        expect(copied.rating, 3.0);
        expect(copied.id, 'h-1');
      });

      test('should preserve values when nothing overridden', () {
        final original = buildSample();
        final copied = original.copyWith();
        expect(copied, equals(original));
      });
    });

    group('computed properties', () {
      test('distanceText formats meters when < 1km', () {
        final hospital = buildSample(distance: 0.5);
        expect(hospital.distanceText, '500 m');
      });

      test('distanceText formats km when >= 1km', () {
        final hospital = buildSample(distance: 2.4);
        expect(hospital.distanceText, '2.4 km');
      });

      test('distanceText is empty when distance is null', () {
        final hospital = buildSample();
        expect(hospital.distanceText, '');
      });

      test('isSuitableForEmergency true when active+emergency room+24/7', () {
        final hospital = buildSample();
        expect(hospital.isSuitableForEmergency, true);

        final notSuitable = hospital.copyWith(isActive: false);
        expect(notSuitable.isSuitableForEmergency, false);
      });

      test('emergencyPriorityScore awards bonuses for trauma & 24/7', () {
        final hospital = buildSample(distance: 1);
        final score = hospital.emergencyPriorityScore;
        // Distance bonus: (50-1)*2 = 98
        // Trauma center: 30, Level I: 20
        // 24/7: 20
        // Rating 4.5*4 = 18
        // Verified: 10
        // Total = 196
        expect(score, greaterThan(150));
      });

      test('emergencyPriorityScore is 0 when no qualifying factors', () {
        final hospital = HospitalModel(
          id: 'h-1',
          name: 'X',
          address: 'A',
          city: 'C',
          state: 'S',
          latitude: 0,
          longitude: 0,
          type: HospitalType.general,
          hasTraumaCenter: false,
          is24_7: false,
          isVerified: false,
          createdAt: createdAt,
        );
        expect(hospital.emergencyPriorityScore, 0.0);
      });

      test('fullAddress joins non-empty parts with commas', () {
        final hospital = buildSample();
        expect(hospital.fullAddress,
            '123 Main St, Bangalore, KA, 560001, India');
      });
    });

    group('equality', () {
      test('should be equal when same values', () {
        final h1 = buildSample();
        final h2 = buildSample();
        expect(h1, equals(h2));
        expect(h1.hashCode, equals(h2.hashCode));
      });

      test('should not be equal when different id', () {
        final h1 = buildSample();
        final h2 = h1.copyWith(id: 'h-2');
        expect(h1, isNot(equals(h2)));
      });
    });
  });
}
